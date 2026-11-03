import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

/// Google AdMob wrapper (spec sections 6, 11-13, 16, 18). Nothing here runs for under-13 players or Plus subscribers:
/// `AdGate.mayLoadAnyAd` is checked first, consent appears only right before the first ad request, and every ad
/// request carries a G content rating. Ad unit ids come from Info.plist (xcconfig), test ids by default.
@Observable
@MainActor
final class AdsService {
    enum Unit: String { case banner = "AdMobBannerUnitID", interstitial = "AdMobInterstitialUnitID", rewarded = "AdMobRewardedUnitID" }

    private(set) var started = false
    private(set) var canRequestAds = false
    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    private var delegateKeepAlive: FullScreenDelegate?

    static func unitID(_ unit: Unit, bundle: Bundle = .main) -> String {
        (bundle.object(forInfoDictionaryKey: unit.rawValue) as? String) ?? ""
    }

    /// Call only when `AdGate.mayLoadAnyAd` is true. Shows the consent form on first use, then starts the SDK.
    func prepare(ageBand: AgeBand?) async {
        guard !started else { return }
        let config = MobileAds.shared.requestConfiguration
        config.maxAdContentRating = .general                                   // G for everyone
        config.ageRestrictedTreatment = ageBand == .thirteenPlus ? .teen : .unspecified
        await requestConsent()
        if canRequestAds {
            await requestTrackingIfNeeded()
            MobileAds.shared.start(completionHandler: nil)
            started = true
        }
    }

    private func requestConsent() async {
        let params = RequestParameters()
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: params)
            if let vc = Self.rootViewController() {
                try await ConsentForm.loadAndPresentIfRequired(from: vc)
            }
        } catch { /* consent failures never block play; ads simply stay off */ }
        canRequestAds = ConsentInformation.shared.canRequestAds
    }

    private func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// Regions that require a way to revisit consent choices show the Settings row.
    var privacyOptionsRequired: Bool { ConsentInformation.shared.privacyOptionsRequirementStatus == .required }

    func presentPrivacyOptions() async {
        guard let vc = Self.rootViewController() else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: vc)
    }

    // MARK: Interstitial

    func preloadInterstitial() async {
        guard started, interstitial == nil else { return }
        interstitial = try? await InterstitialAd.load(with: Self.unitID(.interstitial), request: Request())
    }

    /// Returns true if an ad was shown and closed. A failed or missing ad never blocks play.
    func showInterstitial() async -> Bool {
        guard started else { return false }
        if interstitial == nil { await preloadInterstitial() }
        guard let ad = interstitial, let vc = Self.rootViewController() else { return false }
        interstitial = nil
        let closed = await present { delegate in ad.fullScreenContentDelegate = delegate; ad.present(from: vc) }
        Task { await preloadInterstitial() }
        return closed
    }

    // MARK: Rewarded (player-initiated, optional)

    func preloadRewarded() async {
        guard started, rewarded == nil else { return }
        rewarded = try? await RewardedAd.load(with: Self.unitID(.rewarded), request: Request())
    }

    /// Returns true only if the player earned the reward.
    func showRewarded() async -> Bool {
        guard started else { return false }
        if rewarded == nil { await preloadRewarded() }
        guard let ad = rewarded, let vc = Self.rootViewController() else { return false }
        rewarded = nil
        var earned = false
        _ = await present { delegate in
            ad.fullScreenContentDelegate = delegate
            ad.present(from: vc) { earned = true }
        }
        Task { await preloadRewarded() }
        return earned
    }

    // MARK: Plumbing

    private func present(_ show: (FullScreenDelegate) -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            let delegate = FullScreenDelegate { shown in continuation.resume(returning: shown) }
            delegateKeepAlive = delegate
            show(delegate)
        }
    }

    static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.rootViewController?.topmost
    }
}

private final class FullScreenDelegate: NSObject, FullScreenContentDelegate {
    private var onFinish: ((Bool) -> Void)?
    private var didShow = false
    init(onFinish: @escaping (Bool) -> Void) { self.onFinish = onFinish }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) { didShow = true }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { finish() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { didShow = false; finish() }
    private func finish() { onFinish?(didShow); onFinish = nil }
}

private extension UIViewController {
    var topmost: UIViewController { presentedViewController?.topmost ?? self }
}

/// Banner for Home and Garden only (never beside the letter keys). Adaptive width, G rating, hidden for subscribers.
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let width = UIScreen.main.bounds.width - 40
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        banner.adUnitID = AdsService.unitID(.banner)
        banner.rootViewController = AdsService.rootViewController()
        banner.load(Request())
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

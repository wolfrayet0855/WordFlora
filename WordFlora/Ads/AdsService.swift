import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency

/// Google AdMob wrapper (spec sections 6, 11-13, 16, 18; docs/pm/admob-full-spec.md). Nothing here runs for under-13
/// players, an unknown age or Plus: every entry takes the `AdTreatment` from `AdPolicy` and does nothing for `.none`.
/// Consent appears only right before the first allowed ad request, the tracking prompt is for adults only, 13 to 17
/// are tagged under the age of consent and get non-personalised teen ads, and every request carries a G rating.
/// Unit ids come from Info.plist (xcconfig) through the same-format fallback chain (`AdUnit.id`).
@Observable
@MainActor
final class AdsService {
    typealias Unit = AdUnit

    /// The steps `prepare` takes for a treatment, in order (pure; the service follows it and tests read it).
    enum PrepareStep: Equatable {
        case configure(AdTreatment)            // requestConfiguration: teen or unspecified, G rating
        case consent(underAgeOfConsent: Bool)  // UMP update, then the form if required
        case tracking                          // ATT, adults only
        case start
    }

    static func plan(for t: AdTreatment) -> [PrepareStep] {
        switch t {
        case .none: return []
        case .teen: return [.configure(.teen), .consent(underAgeOfConsent: true), .start]
        case .adult: return [.configure(.adult), .consent(underAgeOfConsent: false), .tracking, .start]
        }
    }

    private(set) var started = false
    /// UI tests switch the SDK off while keeping every ad rule live, so screens that depend on those rules can be checked.
    var offline = false
    private var preparing = false
    private var loadingInterstitial = false
    private var loadingRewarded: Set<AdUnit> = []
    private(set) var canRequestAds = false
    private var interstitial: InterstitialAd?
    private var rewarded: [AdUnit: RewardedAd] = [:]
    private var delegateKeepAlive: FullScreenDelegate?
    /// Set by `releaseAll()` (treatment became `.none`: Plus, or an age answer under 13): nothing loads or shows
    /// until a later `prepare` with an allowed treatment.
    private(set) var suspended = false
    /// A rewarded ad failed to load in this ad visit: rewarded rows hide (AdPolicy `.noFill`) until the next visit.
    private(set) var rewardedLoadFailed = false

    // MARK: Spies (unit tests; cheap counters, no ids)

    /// Every call into `prepare` / `startIfConsentAlreadyResolved` that got past the treatment check.
    private(set) var prepareCount = 0
    private(set) var consentRequestCount = 0
    private(set) var consentFormCount = 0
    private(set) var trackingRequestCount = 0
    /// The treatment and steps of the latest `prepare` (also recorded when offline, so tests see the plan).
    private(set) var lastTreatment: AdTreatment?
    private(set) var lastPlan: [PrepareStep] = []
    private(set) var releaseCount = 0

    static func unitID(_ unit: AdUnit, bundle: Bundle = .main) -> String { unitID(unit, info: bundle.infoDictionary ?? [:]) }
    static func unitID(_ unit: AdUnit, info: [String: Any]) -> String { AdUnit.id(unit, info: info) }

    /// Call only with the treatment `AdPolicy.decide` returned. Shows the consent form on first use, then starts the SDK.
    /// `isStillAllowed` is re-checked after every await, so a subscription or age change mid-setup stops everything.
    func prepare(treatment: AdTreatment, isStillAllowed: () -> Bool) async {
        guard treatment != .none, isStillAllowed() else { return }
        prepareCount += 1
        lastTreatment = treatment
        lastPlan = Self.plan(for: treatment)
        suspended = false
        #if DEBUG
        if fake { started = true; return }
        #endif
        guard !offline else { return }
        if started { Self.configure(treatment); return }        // a started SDK follows a changed treatment (teen/adult)
        guard !preparing else { return }
        preparing = true
        defer { preparing = false }
        for step in lastPlan {
            switch step {
            case .configure(let t): Self.configure(t)
            case .consent(let underAge):
                await requestConsent(underAgeOfConsent: underAge)
                guard canRequestAds, isStillAllowed() else { return }
            case .tracking:
                await requestTrackingIfNeeded()
                guard isStillAllowed() else { return }
            case .start:
                guard isStillAllowed() else { return }
                MobileAds.shared.start(completionHandler: nil)
                started = true
                Task { await preloadInterstitial(); await preloadRewarded(.rewarded) }
            }
        }
    }

    /// For app open and native (G4b; ruling H1): starts the SDK only when consent is already resolved and, for adults,
    /// the tracking answer is known. Never presents the consent form or the tracking prompt.
    @discardableResult
    func startIfConsentAlreadyResolved(treatment: AdTreatment, isStillAllowed: () -> Bool) -> Bool {
        guard treatment != .none, isStillAllowed() else { return false }
        prepareCount += 1
        lastTreatment = treatment
        if started { return true }
        guard !offline else { return false }
        #if DEBUG
        if fake { started = true; return true }
        #endif
        guard Self.consentResolved(), treatment == .teen || Self.trackingResolved(),
              ConsentInformation.shared.canRequestAds else { return false }
        Self.configure(treatment)
        MobileAds.shared.start(completionHandler: nil)
        started = true
        canRequestAds = true
        return true
    }

    static func consentResolved() -> Bool {
        let s = ConsentInformation.shared.consentStatus
        return s == .obtained || s == .notRequired
    }

    static func trackingResolved() -> Bool { ATTrackingManager.trackingAuthorizationStatus != .notDetermined }

    private static func configure(_ t: AdTreatment) {
        let config = MobileAds.shared.requestConfiguration
        config.maxAdContentRating = .general                                   // G for everyone
        config.ageRestrictedTreatment = t == .teen ? .teen : .unspecified
    }

    private func requestConsent(underAgeOfConsent: Bool) async {
        consentRequestCount += 1
        let params = RequestParameters()
        params.isTaggedForUnderAgeOfConsent = underAgeOfConsent              // 13 to 17 (ruling H2), set before the update
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: params)
            if let vc = Self.rootViewController() {
                consentFormCount += 1
                try await ConsentForm.loadAndPresentIfRequired(from: vc)
            }
        } catch { /* consent failures never block play; ads simply stay off */ }
        canRequestAds = ConsentInformation.shared.canRequestAds
    }

    private func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        trackingRequestCount += 1
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// Regions that require a way to revisit consent choices show the Settings row.
    var privacyOptionsRequired: Bool { ConsentInformation.shared.privacyOptionsRequirementStatus == .required }

    func presentPrivacyOptions() async {
        guard let vc = Self.rootViewController() else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: vc)
    }

    /// Ruling H5: the treatment became `.none` (Plus went live, or the age answer is under 13): drop every loaded ad
    /// and stop preloading. Banners leave the screen through `showBanner`; a started SDK stays idle.
    func releaseAll() {
        releaseCount += 1
        interstitial = nil
        rewarded = [:]
        suspended = true
    }

    /// A new ad visit (cold launch or back after a long break) forgets the failed-load flag.
    func beginVisit() { rewardedLoadFailed = false }

    // MARK: Interstitial

    func preloadInterstitial() async {
        guard started, !suspended, interstitial == nil, !loadingInterstitial else { return }
        #if DEBUG
        if fake { return }
        #endif
        loadingInterstitial = true
        defer { loadingInterstitial = false }
        interstitial = try? await InterstitialAd.load(with: Self.unitID(.interstitial), request: Request())
    }

    /// Returns true if an ad was shown and closed. Only an ad that is already loaded is shown: a missing or slow ad
    /// never makes the player wait, it simply loads for next time. `isStillAllowed` is checked right before presenting.
    func showInterstitial(isStillAllowed: () -> Bool = { true }) async -> Bool {
        guard started, !suspended, isStillAllowed() else { return false }
        #if DEBUG
        if fake { return await fakePresent(reward: false).shown }
        #endif
        guard let ad = interstitial else { Task { await preloadInterstitial() }; return false }
        guard let vc = Self.presentationAnchor() else { return false }          // a sheet that is not ours is up
        interstitial = nil
        let closed = await present { delegate in ad.fullScreenContentDelegate = delegate; ad.present(from: vc) }
        Task { await preloadInterstitial() }
        return closed
    }

    // MARK: Rewarded (player-initiated, optional; R1 water, R2 hint, R3 wake)

    func preloadRewarded(_ unit: AdUnit) async {
        guard started, !suspended, rewarded[unit] == nil, !loadingRewarded.contains(unit) else { return }
        #if DEBUG
        if fake { return }
        #endif
        loadingRewarded.insert(unit)
        defer { loadingRewarded.remove(unit) }
        do {
            rewarded[unit] = try await RewardedAd.load(with: Self.unitID(unit), request: Request())
        } catch {
            rewardedLoadFailed = true                                            // hide the rows for this visit
        }
    }

    struct RewardedOutcome: Equatable {
        var shown = false
        var earned = false
    }

    /// `shown`: a full-screen ad appeared (counted in the budgets). `earned`: the player finished it (the reward).
    func showRewarded(_ perk: RewardedPerk = .water, isStillAllowed: () -> Bool = { true }) async -> RewardedOutcome {
        guard started, !suspended, isStillAllowed() else { return RewardedOutcome() }
        // Only R3's video starts from one of our own sheets (the wake sheet); every other ad refuses any sheet.
        let overOwnSheet = perk == .wake
        #if DEBUG
        if fake {
            let r = await fakePresent(reward: !fakeWithholdsReward, allowOwnSheet: overOwnSheet)
            return RewardedOutcome(shown: r.shown, earned: r.earned)
        }
        #endif
        let unit = AdUnit.rewarded(perk)
        if rewarded[unit] == nil { await preloadRewarded(unit) }
        guard isStillAllowed(), !suspended, let ad = rewarded[unit],
              let vc = Self.presentationAnchor(allowOwnSheet: overOwnSheet) else { return RewardedOutcome() }
        rewarded[unit] = nil
        var earned = false
        let shown = await present { delegate in
            ad.fullScreenContentDelegate = delegate
            ad.present(from: vc) { earned = true }
        }
        Task { await preloadRewarded(unit) }                                     // the same perk's unit, ready next time
        return RewardedOutcome(shown: shown, earned: earned)
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
        keyWindowRoot()?.topmost
    }

    private static func keyWindowRoot() -> UIViewController? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.rootViewController
    }

    /// Where a full-screen ad may be presented, or nil when it must not be (Plus flow review, `AdBlock.sheetUp`):
    /// the app is not active (a StoreKit purchase, the tracking prompt or a system sheet is up), or any controller is
    /// presented at all (the consent form, the offer code sheet, manage subscriptions, the grown-up question...).
    /// `allowOwnSheet` is true only for R3, whose video starts from our own wake sheet: then our own SwiftUI sheets
    /// are allowed and anything else still refuses. `topmost` alone would put the ad on top of any sheet.
    static func presentationAnchor(allowOwnSheet: Bool = false) -> UIViewController? {
        guard UIApplication.shared.applicationState == .active, let root = keyWindowRoot() else { return nil }
        return anchor(from: root, allowOwnSheet: allowOwnSheet)
    }

    /// Pure walk of the presented chain (tests pass plain controllers).
    static func anchor(from root: UIViewController, allowOwnSheet: Bool = false) -> UIViewController? {
        var top = root
        while let next = top.presentedViewController {
            guard allowOwnSheet, isOwnSheet(next), !next.isBeingDismissed else { return nil }
            top = next
        }
        return top
    }

    /// Our own SwiftUI sheets are hosting controllers (the wake sheet, for R3); anything else is someone else's sheet.
    static func isOwnSheet(_ vc: UIViewController) -> Bool {
        #if DEBUG
        if vc is FakeAdHost { return false }
        #endif
        return String(describing: type(of: vc)).contains("HostingController")
    }

    /// The Debug fake presenter is on (always false in Release, where the fake does not exist).
    var isFake: Bool {
        #if DEBUG
        return fake
        #else
        return false
        #endif
    }

    /// True when an interstitial could be presented right now. The model leaves `AdInputs.sheetUp` false and relies on
    /// this check right before presenting (the stronger, later check); `sheetUp` is exercised by the policy tests.
    static var canPresentFullScreen: Bool { presentationAnchor() != nil }

    // MARK: Fake presenter (UI tests, Debug only; ruling H6: compiled out of Release)

    #if DEBUG
    /// `-uitest-ads-fake`: a plain full-screen "TEST AD" view instead of Google's SDK; closes on tap; grants the reward
    /// unless `-uitest-ads-fake-withhold`. The SDK never starts in this mode.
    var fake = false
    var fakeWithholdsReward = false

    /// One-off live probe for the collapsible test id (g4a brief 3.1 [verify]), Debug only. Loads one banner with
    /// `["collapsible": "bottom"]` on the Debug (test) collapsible id and reports whether it loaded and was collapsible.
    static func debugProbeCollapsibleTestID(in root: UIViewController) async -> (loaded: Bool, collapsible: Bool)? {
        let id = unitID(.bannerGardenCollapsible)
        guard id.contains(AdUnit.googleTestPublisher) else { return nil }        // never a real id
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general
        _ = await MobileAds.shared.start()
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: root.view.bounds.width))
        banner.adUnitID = id
        banner.rootViewController = root
        root.view.addSubview(banner)
        let probe = CollapsibleProbe(); banner.delegate = probe
        let request = Request()
        let extras = Extras(); extras.additionalParameters = ["collapsible": "bottom"]
        request.register(extras)
        banner.load(request)
        for _ in 0..<60 where probe.result == nil { try? await Task.sleep(nanoseconds: 500_000_000) }
        banner.removeFromSuperview()
        return probe.result
    }

    private final class CollapsibleProbe: NSObject, BannerViewDelegate {
        var result: (loaded: Bool, collapsible: Bool)?
        func bannerViewDidReceiveAd(_ bannerView: BannerView) { result = (true, bannerView.isCollapsible) }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) { result = (false, false) }
    }

    private func fakePresent(reward: Bool, allowOwnSheet: Bool = false) async -> (shown: Bool, earned: Bool) {
        guard let vc = Self.presentationAnchor(allowOwnSheet: allowOwnSheet) else { return (false, false) }
        return await withCheckedContinuation { continuation in
            let host = FakeAdHost { continuation.resume(returning: (true, reward)) }
            host.modalPresentationStyle = .fullScreen
            vc.present(host, animated: false)
        }
    }
    #endif
}

#if DEBUG
/// The fake full-screen ad for UI tests: a plain view reading "TEST AD"; one tap anywhere closes it.
final class FakeAdHost: UIViewController {
    private let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let label = UILabel()
        label.text = "TEST AD"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor), label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
        ])
        view.accessibilityIdentifier = "fakeAd"
        view.isAccessibilityElement = true
        view.accessibilityLabel = "TEST AD"
        view.accessibilityTraits = .button
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    }

    @objc private func close() {
        let done = onClose
        dismiss(animated: false) { done() }
    }
}
#endif

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

/// Banner for Home and Garden only (never beside the letter keys). Anchored adaptive width, G rating, hidden for
/// subscribers. B4: the created banner reports its real height through `height`, so the slot never clips the ad.
struct AdBannerView: UIViewRepresentable {
    var unit: AdUnit = .banner
    var height: Binding<CGFloat>? = nil

    /// The banner's width: the key window less the 20 pt side margins.
    static var width: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return (scene?.keyWindow?.bounds.width ?? scene?.screen.bounds.width ?? 390) - 40
    }

    /// The anchored adaptive height for this width, known before any ad loads (Google computes it from the width
    /// alone), so Home and Garden reserve a slot that never clips the ad and never jumps when it arrives.
    static var slotHeight: CGFloat { currentOrientationAnchoredAdaptiveBanner(width: width).size.height }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: Self.width))
        banner.adUnitID = AdsService.unitID(unit)
        banner.rootViewController = AdsService.rootViewController()
        let h = banner.adSize.size.height
        if let height { DispatchQueue.main.async { height.wrappedValue = h } }
        banner.load(Request())
        return banner
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

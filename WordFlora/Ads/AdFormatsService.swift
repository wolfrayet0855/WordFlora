import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform
import AppTrackingTransparency
import UserNotifications

/// G4b: the app-open ad (with the return cue), the native Shed card and the collapsible Garden banner's visit state.
/// The SDK is only ever started through `AdsService.startIfConsentAlreadyResolved` (ruling H1) by the model, after
/// `AdPolicy.decide`; nothing here checks age or Plus itself, and nothing here asks for consent or tracking.
@Observable
@MainActor
final class AdFormatsService {
    enum Cue: Equatable { case hidden, showing, presenting }

    /// The return cue over the app (drawn by `AppOpenCueHost`).
    private(set) var cue: Cue = .hidden
    /// Skip was tapped: the load is cancelled and nothing is recorded.
    private(set) var skipped = false
    /// A check for the cue is running (one per activation).
    var appOpenInFlight = false

    /// H3: how long a cold launch or resume waits for a link, widget, notification or shortcut to land before deciding.
    var linkSettle: TimeInterval = 0.35
    /// Tests: a shorter load budget than `AdCaps.appOpenLoadBudget`.
    var budgetOverride: TimeInterval?
    /// Tests: consent answers instead of the consent SDK and the tracking status.
    var consentOverride: AdConsentSnapshot?
    /// Tests: whether a sheet is up instead of walking the presented controllers.
    var sheetOverride: Bool?
    /// Tests and `-uitest-voiceover`: VoiceOver or Switch Control is on.
    var assistiveOverride: Bool?
    /// Tests: what presenting does instead of the SDK (true = shown).
    var presentOverride: (() async -> Bool)?

    // MARK: Spies (unit tests; cheap counters, no ids)

    private(set) var cueShownCount = 0
    private(set) var appOpenLoadCount = 0
    private(set) var appOpenPresentCount = 0
    private(set) var appOpenReleaseCount = 0
    private(set) var nativeLoadCount = 0
    private(set) var nativeReleaseCount = 0

    // MARK: App open

    private var appOpenAd: AppOpenAd?
    private var appOpenWanted = false
    private var fakeAppOpenReady = false
    private var keepAlive: FormatsFullScreenDelegate?
    #if DEBUG
    /// `-uitest-appopen-never`: the fake app-open ad never arrives (the cue waits for its budget or Skip).
    var fakeAppOpenNeverArrives = false
    #endif

    var appOpenReady: Bool { appOpenAd != nil || fakeAppOpenReady }

    func showCue() {
        skipped = false
        cue = .showing
        cueShownCount += 1
    }

    /// The player tapped "Skip to my garden".
    func skip() {
        guard cue == .showing else { return }
        skipped = true
        releaseAppOpen()
        cue = .hidden
    }

    /// The cue fades to the screen the player left (the host animates the change).
    func liftCue() { cue = .hidden }

    /// Starts one app-open load (never preloaded at background time: app-open ads expire 4 h after the request).
    /// Returns at once; `appOpenReady` turns true when the ad arrives while still wanted.
    func startAppOpenLoad(ads: AdsService) {
        guard ads.started, !ads.suspended else { return }
        appOpenLoadCount += 1
        appOpenWanted = true
        #if DEBUG
        if ads.isFake {
            guard !fakeAppOpenNeverArrives else { return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                if self.appOpenWanted { self.fakeAppOpenReady = true }
            }
            return
        }
        #endif
        guard !ads.offline else { return }
        let id = AdsService.unitID(.appOpen)
        guard !id.isEmpty else { return }                                    // an empty id switches the format off
        Task { @MainActor in
            let ad = try? await AppOpenAd.load(with: id, request: Request())
            if self.appOpenWanted, !ads.suspended { self.appOpenAd = ad }
        }
    }

    /// Drops a pending load or a loaded ad (budget passed, Skip, Plus went live, the age answer changed: H5).
    func releaseAppOpen() {
        if appOpenWanted || appOpenAd != nil || fakeAppOpenReady { appOpenReleaseCount += 1 }
        appOpenWanted = false
        appOpenAd = nil
        fakeAppOpenReady = false
    }

    /// Presents the loaded ad over the cue. `onShown` runs as the ad appears (the model records it there).
    /// True when it was shown; the cue stays up underneath until the caller lifts it.
    func presentAppOpen(onShown: @escaping () -> Void) async -> Bool {
        cue = .presenting
        appOpenPresentCount += 1
        defer { appOpenWanted = false }
        if let presentOverride {
            appOpenAd = nil
            fakeAppOpenReady = false
            let shown = await presentOverride()
            if shown { onShown() }
            return shown
        }
        guard let vc = AdsService.presentationAnchor() else { releaseAppOpen(); return false }
        #if DEBUG
        if fakeAppOpenReady {
            fakeAppOpenReady = false
            onShown()
            return await withCheckedContinuation { continuation in
                let host = FakeAdHost { continuation.resume(returning: true) }
                host.modalPresentationStyle = .fullScreen
                vc.present(host, animated: false)
            }
        }
        #endif
        guard let ad = appOpenAd else { return false }
        appOpenAd = nil
        return await withCheckedContinuation { continuation in
            let delegate = FormatsFullScreenDelegate(onShown: onShown) { shown in continuation.resume(returning: shown) }
            keepAlive = delegate
            ad.fullScreenContentDelegate = delegate
            ad.present(from: vc)
        }
    }

    // MARK: Native

    /// The cached native ad (real) and when it loaded.
    private(set) var nativeAd: NativeAd?
    private(set) var nativeSlot: NativeAdSlot?
    private(set) var nativeLoading = false
    private var nativeLoader: AdLoader?
    private var nativeDelegate: NativeLoaderDelegate?
    /// The ad visit (its start time) in which a video ad was dropped for Calm or Reduce Motion: no retry this visit.
    var videoDroppedVisit: Date?
    #if DEBUG
    /// `-uitest-ads-fake`: the fake asset set shown by the same card (never registered with Google).
    private(set) var fakeNative: NativeAdContent?
    /// `-uitest-native-video`: the fake ad is a video ad.
    var fakeNativeVideo = false
    #endif

    /// What the card draws: the real ad's assets, or the Debug fake.
    var nativeContent: NativeAdContent? {
        #if DEBUG
        if let fakeNative { return fakeNative }
        #endif
        return nativeAd.map(NativeAdContent.init(ad:))
    }

    /// Loads one native ad. Returns when it loaded or failed (true = loaded).
    func loadNative(ads: AdsService, now: Date) async -> Bool {
        guard ads.started, !ads.suspended, !nativeLoading else { return false }
        nativeLoadCount += 1
        #if DEBUG
        if ads.isFake {
            fakeNative = NativeAdContent.fake(video: fakeNativeVideo)
            nativeSlot = NativeAdSlot(loadedAt: now, hasVideo: fakeNativeVideo)
            return true
        }
        #endif
        guard !ads.offline else { return false }
        let id = AdsService.unitID(.native)
        guard !id.isEmpty else { return false }                              // an empty id switches the format off
        nativeLoading = true
        defer { nativeLoading = false }
        let choices = NativeAdViewAdOptions()
        choices.preferredAdChoicesPosition = .topRightCorner
        let video = VideoOptions()
        video.shouldStartMuted = true
        let loader = AdLoader(adUnitID: id, rootViewController: AdsService.rootViewController(),
                              adTypes: [.native], options: [choices, video])
        let ad: NativeAd? = await withCheckedContinuation { continuation in
            let delegate = NativeLoaderDelegate { ad in continuation.resume(returning: ad) }
            nativeDelegate = delegate
            nativeLoader = loader
            loader.delegate = delegate
            loader.load(Request())
        }
        nativeLoader = nil
        nativeDelegate = nil
        guard let ad, !ads.suspended else { return false }
        nativeAd = ad
        nativeSlot = NativeAdSlot(loadedAt: now, hasVideo: ad.mediaContent.hasVideoContent)
        return true
    }

    /// Drops the cached native ad (30 min passed, a video in Calm or Reduce Motion, or the treatment became none).
    func releaseNative() {
        if nativeSlot != nil { nativeReleaseCount += 1 }
        nativeAd = nil
        nativeSlot = nil
        #if DEBUG
        fakeNative = nil
        #endif
    }

    // MARK: Collapsible Garden banner

    /// The ad visit (its start time) whose Garden banner already made its one collapsible request.
    var collapsibleRequestedVisit: Date?

    // MARK: Live probes

    /// VoiceOver or Switch Control is on (the collapsible overlay is hard to dismiss with them).
    var assistiveTechOn: Bool {
        assistiveOverride ?? (UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning)
    }

    /// Any presented controller, or the app is not active (a purchase sheet, the consent form, the tracking prompt).
    var sheetUp: Bool { sheetOverride ?? !AdsService.canPresentFullScreen }

    /// The consent answers as they stand. Reads the consent SDK only for 13 and over without Plus (never for `.none`).
    func consentSnapshot(for t: AdTreatment, ads: AdsService) -> AdConsentSnapshot {
        guard t != .none else { return AdConsentSnapshot() }
        if let consentOverride { return consentOverride }
        #if DEBUG
        if ads.isFake { return AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: true) }
        #endif
        guard !ads.offline else { return AdConsentSnapshot() }
        return AdConsentSnapshot(consentResolved: AdsService.consentResolved(),
                                 canRequestAds: ConsentInformation.shared.canRequestAds,
                                 trackingResolved: AdsService.trackingResolved())
    }
}

/// Opened from a link, the widget, a notification, an App Shortcut or Siri this activation (no return cue then).
@MainActor
enum AdLinkLaunch {
    static var pending = false
    static func mark() { pending = true }
    /// Only taps on our reminders are reported; foreground presentation is unchanged (no `willPresent`).
    static let notificationDelegate = AdLinkNotificationDelegate()
}

final class AdLinkNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in AdLinkLaunch.mark() }
        completionHandler()
    }
}

/// The assets the Shed card draws, from a real native ad or the Debug fake (which is never registered with Google).
struct NativeAdContent {
    var advertiser: String
    var headline: String
    var body: String
    var callToAction: String
    var store: String
    var starRating: Double?
    var icon: UIImage?
    var hasVideo: Bool
    /// The real ad, registered with the card's `NativeAdView`; nil for the fake.
    var ad: NativeAd?

    init(ad: NativeAd) {
        advertiser = ad.advertiser ?? ""
        headline = ad.headline ?? ""
        body = ad.body ?? ""
        callToAction = ad.callToAction ?? ""
        store = ad.store ?? ""
        starRating = ad.starRating?.doubleValue
        icon = ad.icon?.image
        hasVideo = ad.mediaContent.hasVideoContent
        self.ad = ad
    }

    #if DEBUG
    private init(fakeVideo: Bool) {
        advertiser = "Test advertiser"
        headline = "A test headline that is long enough to wrap onto a second line"
        body = "A test body line for the sponsored card. It wraps at every text size and is never cut short."
        callToAction = "Open"
        store = "App Store"
        starRating = 4.5
        icon = UIImage(systemName: "leaf.circle.fill")
        hasVideo = fakeVideo
        ad = nil
    }

    static func fake(video: Bool) -> NativeAdContent { NativeAdContent(fakeVideo: video) }
    #endif
}

private final class NativeLoaderDelegate: NSObject, NativeAdLoaderDelegate {
    private var done: ((NativeAd?) -> Void)?
    init(done: @escaping (NativeAd?) -> Void) { self.done = done }
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) { finish(nativeAd) }
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) { finish(nil) }
    private func finish(_ ad: NativeAd?) { done?(ad); done = nil }
}

private final class FormatsFullScreenDelegate: NSObject, FullScreenContentDelegate {
    private var onShown: (() -> Void)?
    private var onFinish: ((Bool) -> Void)?
    private var didShow = false
    init(onShown: @escaping () -> Void, onFinish: @escaping (Bool) -> Void) { self.onShown = onShown; self.onFinish = onFinish }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        didShow = true
        onShown?(); onShown = nil
    }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { finish() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { finish() }
    private func finish() { onFinish?(didShow); onFinish = nil }
}

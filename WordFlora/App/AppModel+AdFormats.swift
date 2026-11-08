import SwiftUI

/// What one return check did (unit tests read it; the app ignores it).
enum AppOpenOutcome: Equatable { case notTried, noCue(AdBlock), skipped, lifted, shown }

/// G4b wiring (docs/pm/g4b-builder-brief.md): the return cue and app-open ad, the native Shed card and the collapsible
/// Garden banner. Every decision goes through `AdPolicy.decide` (with `AdFormatRules` for what decide cannot see), so
/// under 13, an unknown age and Plus never get a cue, a card or a collapsible request, and the SDK never starts for
/// them. App open and native start the SDK only through `startIfConsentAlreadyResolved` (H1): no consent form and no
/// tracking prompt ever comes from them.
extension AppModel {
    // MARK: Consent answers (H1)

    /// Fills `consentResolved` and `attResolved` from the consent SDK and the tracking status (teens: always resolved
    /// tracking, they are never asked). Nothing is read for `.none`.
    func refreshAdConsent() {
        let t = adTreatment
        let r = AdConsentRules.resolved(t, adFormats.consentSnapshot(for: t, ads: ads))
        adSession.consentResolved = r.consent
        adSession.attResolved = r.att
    }

    // MARK: Scene lifecycle

    /// The scene became active (a cold launch or a resume). The return check runs once per activation.
    func adFormatsSceneActive(route: @escaping () -> GameRoute?) {
        adFormatsTreatmentCheck()
        guard !adFormats.appOpenInFlight else { return }
        Task { await showAppOpenIfEligible(route: route) }
    }

    /// The scene went to the background: the link flag ends with this activation, the treatment the store confirmed is
    /// cached for the next cold launch (H4), and a cue that is still waiting lifts with its load released.
    func adFormatsSceneBackground() {
        AdLinkLaunch.pending = false
        adSession.launchedFromLink = false
        cacheAdTreatment()
        if adFormats.cue == .showing { adFormats.releaseAppOpen(); adFormats.liftCue() }
    }

    /// A link, the widget, a notification or an App Shortcut opened the app (no return cue this activation).
    func noteAdLinkLaunch() {
        AdLinkLaunch.mark()
        adSession.launchedFromLink = true
    }

    /// H4: the treatment is cached only once the store has answered.
    func cacheAdTreatment() {
        guard entitlements.hasLoaded else { return }
        var l = adLedger
        guard l.lastTreatment != adTreatment else { return }
        l.lastTreatment = adTreatment
        adLedger = l
    }

    /// H5: the treatment is none (Plus went live, an under-13 answer): drop the app-open load and the native ad.
    func adFormatsTreatmentCheck() {
        guard adTreatment == .none else { return }
        adFormats.releaseAppOpen()
        adFormats.releaseNative()
        if adFormats.cue == .showing { adFormats.liftCue() }
    }

    // MARK: App open (spec 1.2)

    /// What is on screen for the return check.
    func appOpenScreen(route: GameRoute?) -> AppOpenScreen {
        var s = AppOpenScreen()
        s.onboarding = !onboarding.isComplete
        s.tutorial = game.isTutorial
        switch route {
        case .game?, .butterfly?, .plus?, .seasons?: s.blockedRoute = true
        default: break
        }
        s.sheetUp = adFormats.sheetUp
        s.badgeMoment = shownBadge != nil
        return s
    }

    /// The return check: after a short wait for a link to land (H3), raise the cue if every rule allows, wait for the
    /// store if this is a cold launch on a cached treatment (H4), start the SDK only if consent is already settled (H1),
    /// load one app-open ad and present it over the cue if it arrives within the budget. Skip, a link, a new sheet,
    /// Plus or the budget lifts the cue and records nothing; only a presented ad is recorded.
    @discardableResult
    func showAppOpenIfEligible(route: @escaping () -> GameRoute? = { nil }) async -> AppOpenOutcome {
        let f = adFormats
        guard adsEnabled, !f.appOpenInFlight, f.cue == .hidden else { return .notTried }
        f.appOpenInFlight = true
        defer { f.appOpenInFlight = false }
        if f.linkSettle > 0 { try? await Task.sleep(nanoseconds: UInt64(f.linkSettle * 1_000_000_000)) }
        cacheAdTreatment()
        refreshAdConsent()
        if AdLinkLaunch.pending { adSession.launchedFromLink = true }
        var caps = AdCaps.current
        if let b = f.budgetOverride { caps.appOpenLoadBudget = b }
        let start = AppOpenFlow.start(adInputs(), cachedTreatment: adLedger.lastTreatment, screen: appOpenScreen(route: route()), caps: caps)
        guard case .cue = start else {
            if case .none(let b) = start { return .noCue(b) }
            return .notTried
        }
        f.showCue()
        let clock = ContinuousClock(), began = clock.now
        func elapsed() -> TimeInterval {
            let d = clock.now - began
            return Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
        }
        func stillWanted() -> Bool { f.cue == .showing && !f.skipped && !AdLinkLaunch.pending && elapsed() < caps.appOpenLoadBudget }
        func lift() -> AppOpenOutcome { f.releaseAppOpen(); f.liftCue(); return .lifted }

        // H4: a cold launch raised the cue on the cached treatment; nothing loads until the store answers.
        while !entitlements.hasLoaded && stillWanted() { try? await Task.sleep(nanoseconds: 50_000_000) }
        if f.skipped { return .skipped }
        guard stillWanted() else { return lift() }
        cacheAdTreatment()
        refreshAdConsent()
        guard case .cue(let t, false) = AppOpenFlow.start(adInputs(), cachedTreatment: nil, screen: appOpenScreen(route: route()), caps: caps)
        else { return lift() }                                                   // Plus, an under-13 answer, a sheet

        guard ads.startIfConsentAlreadyResolved(treatment: t, isStillAllowed: { self.mayStillLoadAds }) else { return lift() }
        f.startAppOpenLoad(ads: ads)
        while !f.appOpenReady && stillWanted() && mayStillLoadAds { try? await Task.sleep(nanoseconds: 50_000_000) }
        if f.skipped { return .skipped }
        guard f.appOpenReady, mayStillLoadAds, !AdLinkLaunch.pending,
              AppOpenFlow.mayPresent(adInputs(), screen: appOpenScreen(route: route()), cueUp: f.cue == .showing,
                                     skipped: f.skipped, elapsed: elapsed(), caps: caps)
        else { return lift() }
        let shown = await f.presentAppOpen { self.recordFullScreen(kind: .appOpen) }
        f.liftCue()
        return shown ? .shown : .lifted
    }

    // MARK: Native Shed card (spec 1.4)

    /// On Shed appear: reuse a cached ad for 30 min, else load one if every rule allows (from the second visit, consent
    /// already settled, at most one load a minute and six a day). A video ad in Calm or Reduce Motion is dropped unshown
    /// and not retried this ad visit.
    @discardableResult
    func loadNativeIfEligible(reduceMotion: Bool = false) async -> NativeAdRules.Step {
        let f = adFormats
        guard adsEnabled else { return .nothing(.notApplicable, dropCached: false) }
        adFormatsTreatmentCheck()
        refreshAdConsent()
        var i = adInputs()
        i.reduceMotion = i.reduceMotion || reduceMotion
        let step = NativeAdRules.onShedAppear(i, cached: f.nativeSlot, videoDroppedThisVisit: f.videoDroppedVisit == adSession.startedAt,
                                              loading: f.nativeLoading)
        switch step {
        case .show:
            return step
        case .nothing(_, let drop):
            if drop { f.releaseNative() }
            return step
        case .load(let t):
            f.releaseNative()
            guard ads.startIfConsentAlreadyResolved(treatment: t, isStillAllowed: { self.mayStillLoadAds }) else {
                return .nothing(.consentPending, dropCached: false)
            }
            var l = adLedger
            l.nativeLoads += 1
            l.lastNativeLoadAt = now()
            adLedger = l
            guard await f.loadNative(ads: ads, now: now()), let slot = f.nativeSlot else { return step }
            if !NativeAdRules.mayDisplay(hasVideo: slot.hasVideo, calm: settings.calmMode, reduceMotion: i.reduceMotion) {
                f.releaseNative()
                f.videoDroppedVisit = adSession.startedAt
                return .nothing(.calm, dropCached: true)
            }
            if !mayStillLoadAds { f.releaseNative() }
            return step
        }
    }

    /// The Shed's "SPONSORED" section shows now (a pure read; under 13, an unknown age and Plus: never, not even the header).
    func shedShowsSponsored(reduceMotion: Bool) -> Bool {
        guard adsEnabled, adFormats.nativeContent != nil else { return false }
        var i = adInputs()
        i.reduceMotion = i.reduceMotion || reduceMotion
        return NativeAdRules.shows(i, slot: adFormats.nativeSlot)
    }

    // MARK: Collapsible Garden banner (spec 1.3)

    /// True when this Garden banner should be requested with the collapsible extras: the Garden banner is eligible, the
    /// third visit or later, once per ad visit and twice a day, not in Calm or Quiet Garden, and never with VoiceOver,
    /// Switch Control or an accessibility text size (those players get the ordinary banner). Marks the request made.
    func requestCollapsibleIfEligible(accessibilityTextSize: Bool) -> Bool {
        guard adsEnabled else { return false }
        var i = adInputs()
        i.voiceOverOrSwitchControl = adFormats.assistiveTechOn
        i.accessibilityTextSize = accessibilityTextSize
        let requested = adFormats.collapsibleRequestedVisit == adSession.startedAt
        guard CollapsibleRules.wantsCollapsible(i, requestedThisVisit: requested) else { return false }
        adFormats.collapsibleRequestedVisit = adSession.startedAt
        return true
    }

    /// The Garden banner received an ad; counted only when it really is collapsible.
    func noteGardenBannerReceived(isCollapsible: Bool) {
        guard isCollapsible else { return }
        var s = adSession
        var l = adLedger
        CollapsibleRules.record(isCollapsible: true, session: &s, ledger: &l)
        adSession = s
        adLedger = l
    }
}

#if DEBUG
/// UI test fixtures for the G4b formats (Debug only, compiled out of Release with the fake presenter: ruling H6).
enum AdFormatsUITestFixtures {
    @MainActor
    static func apply(args: [String], to model: AppModel) {
        if args.contains("-uitest-appopen-never") { model.adFormats.fakeAppOpenNeverArrives = true }
        if args.contains("-uitest-native-video") { model.adFormats.fakeNativeVideo = true }
        if args.contains("-uitest-voiceover") { model.adFormats.assistiveOverride = true }
        if args.contains("-uitest-link-launch") { model.noteAdLinkLaunch() }
        if args.contains("-uitest-appopen-away") {
            // A cold launch five hours after the last background (the cue's own rules still apply).
            var l = model.adLedger
            l.lastBackgroundAt = model.nowDate.addingTimeInterval(-5 * 3600)
            model.adLedger = l
        }
    }
}
#endif

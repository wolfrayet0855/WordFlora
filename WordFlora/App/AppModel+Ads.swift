import Foundation

/// AdPolicy wiring (docs/pm/admob-full-spec.md 1.0): `adInputs()` builds the inputs in one place, and the banner,
/// the interstitial note and calls, and the rewarded perks all go through `AdPolicy.decide` / `AdPolicy.path`.
extension AppModel {
    /// Plus, under 13 and an unknown age: `.none` (no SDK start, no consent form, no tracking prompt, no ad).
    var adTreatment: AdTreatment {
        AdPolicy.treatment(ageBand: settings.ageBand, hasPlus: entitlements.state.hasRemoveAds)
    }

    /// The device-local ledger, rolled to today (a new day starts its counts fresh; far-future times read as now).
    var adLedger: AdLedger {
        get { AdLedger.decode(settings.adLedgerJSON).rolled(to: now()) }
        set { settings.adLedgerJSON = newValue.json }
    }

    /// Every input `AdPolicy` reads, built from the model in one place. `sheetUp` stays false here: the service checks
    /// the presented controllers again right before any full-screen ad (`AdsService.presentationAnchor`).
    func adInputs() -> AdInputs {
        let t = now()
        var i = AdInputs(ageBand: settings.ageBand, now: t)
        i.hasPlus = entitlements.state.hasRemoveAds
        i.entitlementsLoaded = entitlements.hasLoaded
        i.quietGarden = settings.quietGarden
        i.calm = settings.calmMode
        // A counted session means onboarding finished on an earlier launch (sessions count only after onboarding).
        i.onboardingComplete = settings.onboardingComplete || onboarding.isComplete || settings.completedSessions > 0
        i.completedSessions = settings.completedSessions
        i.isNight = AdGate.isNight(t) && !uiTestDaytime
        i.roundInProgress = game.phase == .playing
        i.aroundDailyBloom = game.isDaily
        i.lastRoundWasLoss = game.lastRoundWasLoss
        i.pendingCeremony = pendingCeremony != nil
        i.reduceMotion = settings.reduceMotionOverride
        i.onPaywall = adOnPaywall
        i.appOpenUnitSet = !AdsService.unitID(.appOpen).isEmpty
        i.nativeUnitSet = !AdsService.unitID(.native).isEmpty
        var s = adSession
        s.quietVisit = quietVisit
        s.rewardedLoadFailed = s.rewardedLoadFailed || ads.rewardedLoadFailed
        i.session = s
        let ledger = adLedger
        i.ledger = ledger
        let p = profile, cal = Calendar.current
        var synced = SyncedAdCounters(lastAdAt: p?.lastAdAt)
        if let day = p?.adsDay, cal.isDate(day, inSameDayAs: t) { synced.adsToday = p?.adsToday ?? 0 }
        if let day = p?.rewardedDay, cal.isDate(day, inSameDayAs: t) { synced.rewardedToday = p?.rewardedToday ?? 0 }
        i.synced = synced
        i.interstitial = adContext(choice: nil)
        i.perk = PerkContext(water: p?.water ?? 0, whisperBanked: ledger.whisperBanked,
                             wakeDreamsInARow: settings.wakeDreamsInARow, shortAdNoteShowing: false)
        return i
    }

    func decide(_ format: AdFormat) -> AdDecision {
        guard adsEnabled else { return .no(.notApplicable) }
        return AdPolicy.decide(format, adInputs())
    }

    /// How a perk is offered right now. R2 reads the resting card's short-ad note itself, so the two ad prompts never
    /// stack; after a rewarded ad the note is worked out again from the new gap.
    func perkPath(_ perk: RewardedPerk) -> PerkPath {
        var i = adInputs()
        if perk == .hint { i.perk.shortAdNoteShowing = adWouldPlayOnOneMore }
        if !adsEnabled && AdPolicy.treatment(ageBand: i.ageBand, hasPlus: i.hasPlus) != .none { return .hidden }
        return AdPolicy.path(perk, i)
    }

    /// The tracking prompt: adults without Plus only (the service follows `AdsService.plan`).
    var mayAskTracking: Bool { AdPolicy.mayAskTracking(ageBand: settings.ageBand, hasPlus: entitlements.state.hasRemoveAds) }

    /// Ruling H5: when the treatment becomes `.none` (Plus went live, or the age answer is now under 13), every cached
    /// ad is released and preloading stops. Called when entitlements change and when the age answer changes.
    func adTreatmentChanged() {
        let t = adTreatment
        defer { lastAdTreatment = t }
        if t == .none, lastAdTreatment != AdTreatment.none { ads.releaseAll() }
    }

    // MARK: Ad visits (spec 0.4)

    /// Scene went to the background: remember when, and whether a word was in progress (G4b's app open reads both).
    func noteAdBackground() {
        let t = now()
        adSession.lastBackgroundAt = t
        adSession.roundWasInProgressAtBackground = game.phase == .playing
        var l = adLedger
        l.lastBackgroundAt = t
        adLedger = l
    }

    /// Scene became active: after `AdCaps.sessionBreak` (30 min) in the background a new ad visit starts with fresh
    /// in-memory counters (consent answers carry over; a quiet visit does not, as with a new launch it is per visit).
    func noteAdActive() {
        adTreatmentChanged()
        let t = now()
        guard let away = adSession.lastBackgroundAt, t.timeIntervalSince(away) >= AdCaps.current.sessionBreak else { return }
        var s = AdSessionState(startedAt: t)
        s.lastBackgroundAt = away
        s.roundWasInProgressAtBackground = adSession.roundWasInProgressAtBackground
        s.consentResolved = adSession.consentResolved
        s.attResolved = adSession.attResolved
        adSession = s
        ads.beginVisit()
    }

    // MARK: R2 whisper and R3 gentle wake

    /// A whisper is banked for the next garden word (not the Daily Bloom, not the tutorial).
    var whisperBanked: Bool { adLedger.whisperBanked }

    /// The whisper was used by the help ladder.
    func spendWhisper() {
        var l = adLedger
        guard l.whisperBanked else { return }
        l.whisperBanked = false
        adLedger = l
    }

    /// R3: wakes the seed exactly like a "woke" result (petals return, the love clock restarts), with no sticker,
    /// badge progress, water, shed points or soil. The perk itself is counted by `watchRewarded(.wake)`.
    func gentleWake(_ plant: PlantCollectible) {
        settings.lastWakeResult = .woke
        settings.wakeDreamsInARow = 0
        wake(plant)
        play(.wake)
    }
}

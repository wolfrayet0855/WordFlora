import XCTest
@testable import WordFlora

/// G4b pure rules (docs/pm/g4b-builder-brief.md section 6, items 1 to 4, 6 and 7): the app-open rows, the return cue
/// (screens, H4 cached treatment, the present check), the collapsible rows, the native rows, the consent answers, and
/// the never-for-under-13, unknown age and Plus table and seeded fuzz through the G4b callers.
final class AdFormatsPolicyTests: XCTestCase {
    static let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!
    static let bands: [AgeBand?] = [nil, .under13, .thirteenPlus, .eighteenPlus]

    /// Every input at its most permissive value (as in AdPolicyTests).
    static func permissive(_ band: AgeBand?, hasPlus: Bool = false, now: Date = noon) -> AdInputs {
        var i = AdInputs(ageBand: band, now: now)
        i.hasPlus = hasPlus
        i.completedSessions = 10
        i.session = AdSessionState(startedAt: now.addingTimeInterval(-3600))
        i.session.consentResolved = true
        i.session.attResolved = true
        i.session.lastBackgroundAt = now.addingTimeInterval(-5 * 3600)
        i.ledger = AdLedger(day: AdLedger.dayKey(now))
        i.perk = PerkContext(water: 0, whisperBanked: false, wakeDreamsInARow: 1, shortAdNoteShowing: false)
        var c = AdGate.Context(now: now)
        c.roundsSinceAd = 3
        c.completedSessions = 10
        c.isUnderThirteen = AdPolicy.isYoungOrUnknown(band)
        c.hasRemoveAds = hasPlus
        i.interstitial = c
        return i
    }

    private let caps = AdCaps()
    private func appOpen(_ i: AdInputs) -> AdDecision { AdPolicy.decide(.appOpen, i, caps: caps) }
    private func start(_ i: AdInputs, cached: AdTreatment? = nil, screen: AppOpenScreen = AppOpenScreen()) -> AppOpenFlow.Start {
        AppOpenFlow.start(i, cachedTreatment: cached, screen: screen, caps: caps)
    }

    // MARK: 1. App-open rows

    func testAppOpenFromTheThirdVisit() {
        for n in 0...2 {
            var i = Self.permissive(.eighteenPlus); i.completedSessions = n
            XCTAssertEqual(appOpen(i), .no(.grace), "visit \(n)")
        }
        var i = Self.permissive(.eighteenPlus); i.completedSessions = 3
        XCTAssertEqual(appOpen(i), .yes(.adult))
    }

    func testAppOpenNeedsFourHoursAway() {
        var i = Self.permissive(.eighteenPlus)
        i.session.lastBackgroundAt = Self.noon.addingTimeInterval(-(4 * 3600 - 60))
        XCTAssertEqual(appOpen(i), .no(.background), "3 h 59 min")
        i.session.lastBackgroundAt = Self.noon.addingTimeInterval(-4 * 3600)
        XCTAssertEqual(appOpen(i), .yes(.adult), "4 h")
        // A cold launch has no in-memory background time: it reads the ledger's.
        i.session.lastBackgroundAt = nil
        i.ledger.lastBackgroundAt = Self.noon.addingTimeInterval(-5 * 3600)
        XCTAssertEqual(appOpen(i), .yes(.adult))
        i.ledger.lastBackgroundAt = nil
        XCTAssertEqual(appOpen(i), .no(.background), "never backgrounded: no return ad")
    }

    func testAppOpenNeverOverAWordNorAfterALink() {
        var r = Self.permissive(.eighteenPlus); r.session.roundWasInProgressAtBackground = true
        XCTAssertEqual(appOpen(r), .no(.puzzle))
        var p = Self.permissive(.eighteenPlus); p.roundInProgress = true
        XCTAssertEqual(appOpen(p), .no(.puzzle))
        var l = Self.permissive(.eighteenPlus); l.session.launchedFromLink = true
        XCTAssertEqual(appOpen(l), .no(.link))
    }

    func testAppOpenNeedsConsentSettledAndTeensNeverWaitForTracking() {
        var c = Self.permissive(.eighteenPlus); c.session.consentResolved = false
        XCTAssertEqual(appOpen(c), .no(.consentPending))
        var a = Self.permissive(.eighteenPlus); a.session.attResolved = false
        XCTAssertEqual(appOpen(a), .no(.consentPending), "adult, tracking not determined")
        // Teens are never asked about tracking, so their answer is always resolved.
        let snapshot = AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: false)
        let teen = AdConsentRules.resolved(.teen, snapshot)
        XCTAssertTrue(teen.att)
        var t = Self.permissive(.thirteenPlus); t.session.consentResolved = teen.consent; t.session.attResolved = teen.att
        XCTAssertEqual(appOpen(t), .yes(.teen))
        let adult = AdConsentRules.resolved(.adult, snapshot)
        XCTAssertFalse(adult.att)
    }

    func testAppOpenNeverInCalmQuietAtNightOrWithACeremony() {
        let cases: [(AdBlock, (inout AdInputs) -> Void)] = [
            (.calm, { $0.calm = true }), (.quiet, { $0.quietGarden = true }), (.night, { $0.isNight = true }),
            (.ceremony, { $0.pendingCeremony = true }), (.onboarding, { $0.onboardingComplete = false }),
            (.notLoaded, { $0.entitlementsLoaded = false }), (.paywall, { $0.onPaywall = true }), (.sheetUp, { $0.sheetUp = true }),
            (.quiet, { $0.session.quietVisit = true }),
        ]
        for (block, change) in cases {
            var i = Self.permissive(.eighteenPlus); change(&i)
            XCTAssertEqual(appOpen(i), .no(block), "\(block)")
        }
    }

    func testAppOpenOnceADayThirtyMinutesAfterAnyFullScreenAdAndWithinTheBudgets() {
        var d = Self.permissive(.eighteenPlus); d.ledger.appOpen = 1
        XCTAssertEqual(appOpen(d), .no(.formatCap), "second of the day")
        var g = Self.permissive(.eighteenPlus); g.synced.lastAdAt = Self.noon.addingTimeInterval(-29 * 60)
        XCTAssertEqual(appOpen(g), .no(.gap), "29 min")
        g.synced.lastAdAt = Self.noon.addingTimeInterval(-30 * 60)
        XCTAssertEqual(appOpen(g), .yes(.adult), "30 min")
        var p = Self.permissive(.eighteenPlus); p.synced.adsToday = 6
        XCTAssertEqual(appOpen(p), .no(.dayCap), "pushed 6 a day")
        var s = Self.permissive(.eighteenPlus); s.session.pushedShown = 2
        XCTAssertEqual(appOpen(s), .no(.sessionCap), "pushed 2 a visit")
        var f = Self.permissive(.eighteenPlus); f.ledger.fullScreen = 8
        XCTAssertEqual(appOpen(f), .no(.dayCap), "full-screen 8 a day")
        var v = Self.permissive(.eighteenPlus); v.session.fullScreenShown = 4
        XCTAssertEqual(appOpen(v), .no(.sessionCap), "full-screen 4 a visit")
        var u = Self.permissive(.eighteenPlus); u.appOpenUnitSet = false
        XCTAssertEqual(appOpen(u), .no(.notApplicable), "an empty unit id switches it off")
    }

    // MARK: The return cue

    func testTheCueNeverCoversOnboardingThePuzzleASheetOrABadgeMoment() {
        let i = Self.permissive(.eighteenPlus)
        XCTAssertEqual(start(i), .cue(.adult, awaitingEntitlements: false))
        let screens: [(AdBlock, AppOpenScreen)] = [
            (.onboarding, AppOpenScreen(onboarding: true)), (.puzzle, AppOpenScreen(tutorial: true)),
            (.puzzle, AppOpenScreen(blockedRoute: true)), (.sheetUp, AppOpenScreen(sheetUp: true)),
            (.ceremony, AppOpenScreen(badgeMoment: true)),
        ]
        for (block, screen) in screens { XCTAssertEqual(start(i, screen: screen), .none(block), "\(screen)") }
    }

    /// H4: before the store answers, only a cached ad treatment raises the cue; the ad waits for the store.
    func testAColdLaunchRaisesTheCueOnlyFromACachedAdTreatment() {
        var i = Self.permissive(.thirteenPlus); i.entitlementsLoaded = false
        XCTAssertEqual(start(i, cached: .teen), .cue(.teen, awaitingEntitlements: true))
        XCTAssertEqual(start(i, cached: AdTreatment.none), .none(.notLoaded), "cached none (Plus last time): no cue")
        XCTAssertEqual(start(i, cached: nil), .none(.notLoaded), "never cached: no cue")
        var young = Self.permissive(.under13); young.entitlementsLoaded = false
        XCTAssertEqual(start(young, cached: .adult), .none(.ageOrPlus), "an under-13 answer wins over any cache")
        // The present check needs the store's answer and the live rules.
        XCTAssertFalse(AppOpenFlow.mayPresent(i, screen: AppOpenScreen(), cueUp: true, skipped: false, elapsed: 1, caps: caps))
        var plus = Self.permissive(.thirteenPlus, hasPlus: true)
        XCTAssertFalse(AppOpenFlow.mayPresent(plus, screen: AppOpenScreen(), cueUp: true, skipped: false, elapsed: 1, caps: caps),
                       "the store came back Plus: no ad")
        plus.hasPlus = false
        XCTAssertTrue(AppOpenFlow.mayPresent(plus, screen: AppOpenScreen(), cueUp: true, skipped: false, elapsed: 1, caps: caps))
    }

    func testTheAdIsPresentedOnlyWhileTheCueIsUpWithinTheBudget() {
        let i = Self.permissive(.eighteenPlus)
        func may(cueUp: Bool = true, skipped: Bool = false, elapsed: TimeInterval = 1, screen: AppOpenScreen = AppOpenScreen()) -> Bool {
            AppOpenFlow.mayPresent(i, screen: screen, cueUp: cueUp, skipped: skipped, elapsed: elapsed, caps: caps)
        }
        XCTAssertTrue(may())
        XCTAssertTrue(may(elapsed: 2.5))
        XCTAssertFalse(may(elapsed: 2.51), "after 2.5 s the cue lifts and nothing is shown")
        XCTAssertFalse(may(skipped: true))
        XCTAssertFalse(may(cueUp: false))
        XCTAssertFalse(may(screen: AppOpenScreen(sheetUp: true)))
        XCTAssertEqual(caps.appOpenLoadBudget, 2.5)
    }

    func testConsentAnswersForEachTreatment() {
        let all = AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: true)
        XCTAssertTrue(AdConsentRules.resolved(.none, all) == (false, false), "none reads nothing")
        XCTAssertTrue(AdConsentRules.resolved(.adult, all) == (true, true))
        let declined = AdConsentSnapshot(consentResolved: true, canRequestAds: false, trackingResolved: true)
        XCTAssertFalse(AdConsentRules.resolved(.adult, declined).consent, "consent given but ads may not be requested")
        XCTAssertFalse(AdConsentRules.resolved(.teen, AdConsentSnapshot()).consent)
        XCTAssertTrue(AdConsentRules.resolved(.teen, AdConsentSnapshot()).att)
    }

    // MARK: 2. Collapsible rows

    func testCollapsibleFromTheThirdVisitOncePerVisitTwiceADay() {
        var i = Self.permissive(.eighteenPlus); i.completedSessions = 2
        XCTAssertFalse(CollapsibleRules.wantsCollapsible(i, requestedThisVisit: false, caps: caps), "visit 2")
        i.completedSessions = 3
        XCTAssertTrue(CollapsibleRules.wantsCollapsible(i, requestedThisVisit: false, caps: caps), "visit 3")
        XCTAssertFalse(CollapsibleRules.wantsCollapsible(i, requestedThisVisit: true, caps: caps), "one request a visit")
        var s = i; s.session.collapsibleShown = 1
        XCTAssertFalse(CollapsibleRules.wantsCollapsible(s, requestedThisVisit: false, caps: caps), "second in the visit")
        var d = i; d.ledger.collapsible = 2
        XCTAssertFalse(CollapsibleRules.wantsCollapsible(d, requestedThisVisit: false, caps: caps), "third in the day")
    }

    func testCollapsibleNeverInCalmQuietOrWithAssistiveTechButThePlainBannerStays() {
        let cases: [(String, (inout AdInputs) -> Void)] = [
            ("calm", { $0.calm = true }), ("quiet", { $0.quietGarden = true }),
            ("voiceover", { $0.voiceOverOrSwitchControl = true }), ("ax size", { $0.accessibilityTextSize = true }),
        ]
        for (name, change) in cases {
            var i = Self.permissive(.eighteenPlus); change(&i)
            XCTAssertFalse(CollapsibleRules.wantsCollapsible(i, requestedThisVisit: false, caps: caps), name)
            XCTAssertEqual(AdPolicy.decide(.banner(.garden), i, caps: caps), .yes(.adult), "\(name): the plain banner still shows")
        }
    }

    func testCollapsibleIsCountedOnlyWhenTheAdIsCollapsible() {
        var s = AdSessionState(), l = AdLedger()
        CollapsibleRules.record(isCollapsible: false, session: &s, ledger: &l)
        XCTAssertEqual(s.collapsibleShown, 0); XCTAssertEqual(l.collapsible, 0)
        CollapsibleRules.record(isCollapsible: true, session: &s, ledger: &l)
        XCTAssertEqual(s.collapsibleShown, 1); XCTAssertEqual(l.collapsible, 1)
        XCTAssertTrue(CollapsibleRules.swapNow(requestedCollapsible: true, isCollapsible: false), "a plain ad from the collapsible unit swaps at once")
        XCTAssertFalse(CollapsibleRules.swapNow(requestedCollapsible: true, isCollapsible: true))
        XCTAssertFalse(CollapsibleRules.swapNow(requestedCollapsible: false, isCollapsible: false))
    }

    // MARK: 3. Native rows

    private func shed(_ i: AdInputs, cached: NativeAdSlot? = nil, dropped: Bool = false, loading: Bool = false) -> NativeAdRules.Step {
        NativeAdRules.onShedAppear(i, cached: cached, videoDroppedThisVisit: dropped, loading: loading, caps: caps)
    }

    func testNativeNeedsConsentAndTheSecondVisit() {
        var c = Self.permissive(.eighteenPlus); c.session.consentResolved = false
        XCTAssertEqual(shed(c), .nothing(.consentPending, dropCached: false))
        var v = Self.permissive(.thirteenPlus); v.completedSessions = 1
        XCTAssertEqual(shed(v), .nothing(.grace, dropCached: false))
        v.completedSessions = 2
        XCTAssertEqual(shed(v), .load(.teen))
        var u = Self.permissive(.eighteenPlus); u.nativeUnitSet = false
        XCTAssertEqual(shed(u), .nothing(.notApplicable, dropCached: false), "an empty unit id switches it off")
        var q = Self.permissive(.eighteenPlus); q.quietGarden = true
        XCTAssertEqual(shed(q), .load(.adult), "Quiet Garden keeps the static card")
    }

    func testNativeLoadsOnceAMinuteAndSixADay() {
        var g = Self.permissive(.eighteenPlus); g.ledger.lastNativeLoadAt = Self.noon.addingTimeInterval(-59)
        XCTAssertEqual(shed(g), .nothing(.gap, dropCached: false))
        g.ledger.lastNativeLoadAt = Self.noon.addingTimeInterval(-60)
        XCTAssertEqual(shed(g), .load(.adult))
        var d = Self.permissive(.eighteenPlus); d.ledger.nativeLoads = 5
        XCTAssertEqual(shed(d), .load(.adult))
        d.ledger.nativeLoads = 6
        XCTAssertEqual(shed(d), .nothing(.formatCap, dropCached: false))
        XCTAssertEqual(shed(Self.permissive(.eighteenPlus), loading: true), .nothing(.notApplicable, dropCached: false), "one load at a time")
    }

    func testANativeAdIsReusedForThirtyMinutesThenDropped() {
        var i = Self.permissive(.eighteenPlus); i.ledger.nativeLoads = 6       // the load cap never hides a cached ad
        let slot = NativeAdSlot(loadedAt: Self.noon.addingTimeInterval(-29 * 60), hasVideo: false)
        XCTAssertEqual(shed(i, cached: slot), .show)
        XCTAssertTrue(NativeAdRules.shows(i, slot: slot, caps: caps))
        let old = NativeAdSlot(loadedAt: Self.noon.addingTimeInterval(-30 * 60), hasVideo: false)
        XCTAssertFalse(NativeAdRules.isFresh(old, now: Self.noon, caps: caps))
        XCTAssertFalse(NativeAdRules.shows(i, slot: old, caps: caps))
        XCTAssertEqual(shed(i, cached: old), .nothing(.formatCap, dropCached: true), "stale and the day's loads used: dropped")
        XCTAssertEqual(shed(Self.permissive(.eighteenPlus), cached: old), .load(.adult), "stale: a fresh one loads")
        XCTAssertEqual(caps.nativeReuse, 1800)
    }

    func testCalmOrReduceMotionNeverShowsAVideoAdAndDoesNotRetry() {
        let video = NativeAdSlot(loadedAt: Self.noon.addingTimeInterval(-60), hasVideo: true)
        let image = NativeAdSlot(loadedAt: Self.noon.addingTimeInterval(-60), hasVideo: false)
        for change in [{ (i: inout AdInputs) in i.calm = true }, { (i: inout AdInputs) in i.reduceMotion = true }] {
            var i = Self.permissive(.eighteenPlus); change(&i)
            XCTAssertEqual(shed(i, cached: video), .nothing(.calm, dropCached: true))
            XCTAssertFalse(NativeAdRules.shows(i, slot: video, caps: caps))
            XCTAssertEqual(shed(i, cached: image), .show, "image ads stay")
            XCTAssertEqual(shed(i, dropped: true), .nothing(.calm, dropCached: false), "not retried this visit")
        }
        XCTAssertEqual(shed(Self.permissive(.eighteenPlus), cached: video), .show, "video is fine outside Calm and Reduce Motion")
        XCTAssertTrue(NativeAdRules.mayDisplay(hasVideo: true, calm: false, reduceMotion: false))
    }

    func testNativeNeverOnThePaywallOrInAQuietVisit() {
        let slot = NativeAdSlot(loadedAt: Self.noon, hasVideo: false)
        var p = Self.permissive(.eighteenPlus); p.onPaywall = true
        XCTAssertFalse(NativeAdRules.shows(p, slot: slot, caps: caps))
        var q = Self.permissive(.eighteenPlus); q.session.quietVisit = true
        XCTAssertFalse(NativeAdRules.shows(q, slot: slot, caps: caps))
        XCTAssertFalse(NativeAdRules.shows(Self.permissive(.eighteenPlus), slot: nil, caps: caps), "no ad: no section")
    }

    // MARK: 4. Never for under 13, unknown age, or Plus (table and seeded fuzz through the G4b callers)

    private static var blocked: [(AgeBand?, Bool)] {
        var b: [(AgeBand?, Bool)] = [(nil, false), (.under13, false)]
        for band in bands { b.append((band, true)) }
        return b
    }

    func testNeverForUnderThirteenUnknownOrPlusThroughTheCue_TheShedAndTheGardenBanner() {
        let slot = NativeAdSlot(loadedAt: Self.noon, hasVideo: false)
        for (band, plus) in Self.blocked {
            let label = "\(String(describing: band)) plus \(plus)"
            let i = Self.permissive(band, hasPlus: plus)
            for f in [AdFormat.appOpen, .collapsible, .native] { XCTAssertEqual(AdPolicy.decide(f, i, caps: caps), .no(.ageOrPlus), "\(f) \(label)") }
            for cached in [AdTreatment?.none, .some(.none), .teen, .adult] {
                if case .cue = start(i, cached: cached) { XCTFail("cue for \(label)") }
            }
            XCTAssertEqual(shed(i, cached: slot), .nothing(.ageOrPlus, dropCached: true), label)
            XCTAssertFalse(NativeAdRules.shows(i, slot: slot, caps: caps), label)
            XCTAssertFalse(CollapsibleRules.wantsCollapsible(i, requestedThisVisit: false, caps: caps), label)
            XCTAssertFalse(AppOpenFlow.mayPresent(i, screen: AppOpenScreen(), cueUp: true, skipped: false, elapsed: 0, caps: caps), label)
            XCTAssertTrue(AdConsentRules.resolved(AdPolicy.treatment(ageBand: band, hasPlus: plus), AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: true)) == (false, false))
        }
    }

    func testSeededFuzzNeverRaisesACueLoadsACardOrRequestsACollapsibleForUnderThirteenUnknownOrPlus() {
        let seed: UInt64 = 0x0064_4B5A_FE20_2611
        var rng = SplitMix64(seed: seed)
        var checked = 0
        for k in 0..<3_000 {
            let group = k / 1_000
            let band: AgeBand? = group == 0 ? nil : (group == 1 ? .under13 : Self.bands[Int(rng.next() % 4)])
            let plus = group == 2
            let i = AdPolicyTests.randomInputs(band: band, hasPlus: plus, rng: &rng)
            let c = k % 2 == 0 ? AdCaps() : AdPolicyTests.randomCaps(&rng)
            let options: [AdTreatment?] = [nil, .some(.none), .teen, .adult]
            let cached = options[Int(rng.next() % 4)]
            let screen = AppOpenScreen(onboarding: rng.next() & 1 == 1, tutorial: rng.next() & 1 == 1, blockedRoute: rng.next() & 1 == 1,
                                       sheetUp: rng.next() & 1 == 1, badgeMoment: rng.next() & 1 == 1)
            let slot: NativeAdSlot? = rng.next() & 1 == 1 ? nil : NativeAdSlot(loadedAt: i.now.addingTimeInterval(-Double(rng.next() % 3600)), hasVideo: rng.next() & 1 == 1)
            if case .cue = AppOpenFlow.start(i, cachedTreatment: cached, screen: screen, caps: c) {
                XCTFail("seed \(String(seed, radix: 16)) case \(k): cue"); return
            }
            if AppOpenFlow.mayPresent(i, screen: screen, cueUp: true, skipped: false, elapsed: 0, caps: c) {
                XCTFail("seed \(String(seed, radix: 16)) case \(k): present"); return
            }
            switch NativeAdRules.onShedAppear(i, cached: slot, videoDroppedThisVisit: rng.next() & 1 == 1, loading: rng.next() & 1 == 1, caps: c) {
            case .show, .load: XCTFail("seed \(String(seed, radix: 16)) case \(k): native"); return
            case .nothing: break
            }
            if NativeAdRules.shows(i, slot: slot, caps: c) || CollapsibleRules.wantsCollapsible(i, requestedThisVisit: rng.next() & 1 == 1, caps: c) {
                XCTFail("seed \(String(seed, radix: 16)) case \(k): shed or collapsible"); return
            }
            checked += 1
        }
        XCTAssertEqual(checked, 3_000)
    }

    func testPermissiveTeensAndAdultsGetEveryG4bFormat() {
        for (band, t) in [(AgeBand.thirteenPlus, AdTreatment.teen), (.eighteenPlus, .adult)] {
            let i = Self.permissive(band)
            XCTAssertEqual(start(i), .cue(t, awaitingEntitlements: false))
            XCTAssertEqual(shed(i), .load(t))
            XCTAssertTrue(CollapsibleRules.wantsCollapsible(i, requestedThisVisit: false, caps: caps))
        }
    }

    // MARK: 7. Ledger

    func testTheCachedTreatmentRoundTripsSurvivesANewDayAndReadsEmptyWhenCorrupt() {
        var l = AdLedger(day: AdLedger.dayKey(Self.noon))
        XCTAssertNil(l.lastTreatment)
        for t in [AdTreatment.none, .teen, .adult] {
            l.lastTreatment = t
            XCTAssertEqual(AdLedger.decode(l.json).lastTreatment, t)
        }
        l.lastTreatment = .teen
        l.appOpen = 1; l.collapsible = 2; l.nativeLoads = 3
        let next = l.rolled(to: Self.noon.addingTimeInterval(86_400))
        XCTAssertEqual([next.appOpen, next.collapsible, next.nativeLoads], [0, 0, 0], "the new counts start fresh each day")
        XCTAssertEqual(next.lastTreatment, .teen, "the cached treatment stays")
        XCTAssertNil(AdLedger.decode("{broken").lastTreatment)
        XCTAssertNil(AdLedger.decode(#"{"day":20261108,"cachedTreatment":"maybe"}"#).lastTreatment, "an unknown value is no cache")
        l.lastTreatment = nil
        XCTAssertEqual(l.cachedTreatment, "")
    }

    // MARK: Copy and Debug overrides

    func testEveryCueCardAndCaptionLineIsCalm() {
        XCTAssertEqual(AdFormatCopy.all.count, 15)
        for line in AdFormatCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertTrue(AdFormatCopy.Native.groupLabel(headline: "Seeds").hasPrefix("Advertisement."))
        XCTAssertEqual(AdFormatCopy.Native.header.uppercased(), "SPONSORED")
        XCTAssertTrue(AdFormatCopy.Cue.voiceOver.hasPrefix(AdFormatCopy.Cue.title))
    }

    func testTheLoadBudgetCanBeStretchedInDebugOnly() {
        #if DEBUG
        XCTAssertEqual(AdCaps.debugOverrides(arguments: ["-adcaps", "appOpenLoadBudget=30"]).appOpenLoadBudget, 30)
        #endif
        XCTAssertEqual(AdCaps().appOpenLoadBudget, 2.5)
    }
}

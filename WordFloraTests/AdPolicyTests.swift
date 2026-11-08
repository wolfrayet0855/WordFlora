import XCTest
@testable import WordFlora

/// AdPolicy: the age-band table, never for under 13 / unknown / Plus (table and seeded fuzz), per-band yes, the
/// budgets and gaps (ruled numbers), the rewarded perks, the Plus-flow guards and the ledger (g4a brief section 6.4).
final class AdPolicyTests: XCTestCase {
    static let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!
    static let bands: [AgeBand?] = [nil, .under13, .thirteenPlus, .eighteenPlus]
    static let formats: [AdFormat] = [
        .banner(.home), .banner(.garden), .collapsible, .interstitial(.oneMore), .interstitial(.playSoonAfterEnough),
        .appOpen, .native, .rewarded(.water), .rewarded(.hint), .rewarded(.wake),
    ]
    /// The formats G4a ships (app open, collapsible and native callers are G4b; their rules are still tested here).
    static let g4aFormats: [AdFormat] = [.banner(.home), .banner(.garden), .interstitial(.oneMore), .interstitial(.playSoonAfterEnough),
                                         .rewarded(.water), .rewarded(.hint), .rewarded(.wake)]

    /// Every input at its most permissive value: whatever the band allows, these inputs allow.
    static func permissive(_ band: AgeBand?, hasPlus: Bool = false, now: Date = noon) -> AdInputs {
        var i = AdInputs(ageBand: band, now: now)
        i.hasPlus = hasPlus
        i.entitlementsLoaded = true
        i.onboardingComplete = true
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

    private func decide(_ f: AdFormat, _ i: AdInputs, caps: AdCaps = AdCaps()) -> AdDecision { AdPolicy.decide(f, i, caps: caps) }

    // MARK: 1. Treatment table

    func testTreatmentTable() {
        let expected: [(AgeBand?, Bool, AdTreatment)] = [
            (nil, false, .none), (.under13, false, .none), (.thirteenPlus, false, .teen), (.eighteenPlus, false, .adult),
            (nil, true, .none), (.under13, true, .none), (.thirteenPlus, true, .none), (.eighteenPlus, true, .none),
        ]
        for (band, plus, t) in expected {
            XCTAssertEqual(AdPolicy.treatment(ageBand: band, hasPlus: plus), t, "\(String(describing: band)) plus \(plus)")
            XCTAssertEqual(AdGate.mayLoadAnyAd(ageBand: band, hasPlus: plus), t != .none)
        }
    }

    func testTheGrownUpQuestionAndTheAdRuleAgreeOnWhoIsYoung() {
        for band in Self.bands {
            XCTAssertEqual(AdPolicy.isYoungOrUnknown(band), ParentalGate.isRequired(ageBand: band), "\(String(describing: band))")
            XCTAssertEqual(AdPolicy.treatment(ageBand: band, hasPlus: false) == .none, ParentalGate.isRequired(ageBand: band))
        }
    }

    // MARK: 2. Never for under 13, unknown age, or Plus

    func testNeverForUnderThirteenUnknownOrPlusWithEveryOtherInputPermissive() {
        var blocked: [(AgeBand?, Bool)] = [(nil, false), (.under13, false)]
        for band in Self.bands { blocked.append((band, true)) }
        for (band, plus) in blocked {
            let i = Self.permissive(band, hasPlus: plus)
            for f in Self.formats {
                XCTAssertEqual(decide(f, i), .no(.ageOrPlus), "\(f) \(String(describing: band)) plus \(plus)")
            }
            for perk in RewardedPerk.allCases {
                XCTAssertEqual(AdPolicy.path(perk, i, caps: AdCaps()), .free, "\(perk) is free for \(String(describing: band)) plus \(plus)")
            }
            XCTAssertFalse(AdPolicy.mayAskTracking(ageBand: band, hasPlus: plus))
        }
    }

    // MARK: 3. Seeded fuzz

    static func randomInputs(band: AgeBand?, hasPlus: Bool, rng: inout SplitMix64) -> AdInputs {
        func b() -> Bool { rng.next() & 1 == 1 }
        func n(_ m: UInt64) -> Int { Int(rng.next() % m) }
        let now = noon.addingTimeInterval(Double(n(400 * 86_400)) - 200 * 86_400)
        func d() -> Date? { b() ? nil : now.addingTimeInterval(Double(n(4 * 86_400)) - 2 * 86_400) }
        var i = AdInputs(ageBand: band, now: now)
        i.hasPlus = hasPlus
        i.entitlementsLoaded = b(); i.quietGarden = b(); i.calm = b(); i.onboardingComplete = b()
        i.completedSessions = n(20); i.isNight = b(); i.roundInProgress = b(); i.aroundDailyBloom = b()
        i.lastRoundWasLoss = b(); i.pendingCeremony = b(); i.reduceMotion = b(); i.voiceOverOrSwitchControl = b()
        i.accessibilityTextSize = b(); i.onPaywall = b(); i.sheetUp = b(); i.appOpenUnitSet = b(); i.nativeUnitSet = b()
        i.session = AdSessionState(startedAt: now, fullScreenShown: n(6), pushedShown: n(4), rewardedShown: n(4),
                                   collapsibleShown: n(2), lastBackgroundAt: d(), roundWasInProgressAtBackground: b(),
                                   launchedFromLink: b(), quietVisit: b(), consentResolved: b(), attResolved: b(), rewardedLoadFailed: b())
        var l = AdLedger(day: b() ? AdLedger.dayKey(now) : n(30_000_000), lastFullScreenAt: d(), lastAppOpenAt: d(),
                         lastNativeLoadAt: d(), lastBackgroundAt: d(), whisperBanked: b())
        l.appOpen = n(3); l.collapsible = n(3); l.nativeLoads = n(8); l.fullScreen = n(10)
        l.adWater = n(4); l.adHint = n(3); l.adWake = n(2); l.freeWater = n(4); l.freeHint = n(3); l.freeWake = n(2)
        i.ledger = l
        i.synced = SyncedAdCounters(lastAdAt: d(), adsToday: n(8), rewardedToday: n(7))
        var c = AdGate.Context(now: now)
        c.roundsSinceAd = n(6); c.isUnderThirteen = b(); c.hasRemoveAds = b(); c.midRound = b(); c.aroundDailyBloom = b()
        c.lastRoundWasLoss = b(); c.completedSessions = n(6); c.wordLevelUps = n(3); c.lastAdAt = d(); c.adsToday = n(8)
        c.lastPeakAt = d(); c.isNight = b()
        i.interstitial = c
        i.perk = PerkContext(water: n(3), whisperBanked: b(), wakeDreamsInARow: n(3), shortAdNoteShowing: b())
        return i
    }

    func testSeededFuzzNeverGivesAnAdToUnderThirteenUnknownOrPlus() {
        let seed: UInt64 = 0x00AD_5AFE_2026_1108
        var rng = SplitMix64(seed: seed)
        let groups: [(String, (inout SplitMix64) -> (AgeBand?, Bool))] = [
            ("unknown", { _ in (nil, false) }),
            ("under13", { _ in (.under13, false) }),
            ("plus", { r in (AdPolicyTests.bands[Int(r.next() % 4)], true) }),
        ]
        var checked = 0
        for (name, pick) in groups {
            for k in 0..<1_000 {
                let (band, plus) = pick(&rng)
                let i = Self.randomInputs(band: band, hasPlus: plus, rng: &rng)
                let caps = k % 2 == 0 ? AdCaps() : Self.randomCaps(&rng)
                for f in Self.formats {
                    let d = AdPolicy.decide(f, i, caps: caps)
                    checked += 1
                    if d != .no(.ageOrPlus) {
                        XCTFail("seed \(String(seed, radix: 16)) group \(name) case \(k) format \(f): \(d)")
                        return
                    }
                }
                for perk in RewardedPerk.allCases {
                    let p = AdPolicy.path(perk, i, caps: caps)
                    if p != .free && p != .hidden {
                        XCTFail("seed \(String(seed, radix: 16)) group \(name) case \(k) perk \(perk): \(p)")
                        return
                    }
                }
                XCTAssertFalse(AdPolicy.mayAskTracking(ageBand: band, hasPlus: plus))
            }
        }
        XCTAssertEqual(checked, 3 * 1_000 * Self.formats.count)
    }

    static func randomCaps(_ rng: inout SplitMix64) -> AdCaps {
        var c = AdCaps()
        func n(_ m: UInt64) -> Int { Int(rng.next() % m) }
        c.pushedPerDay = n(100); c.pushedPerSession = n(100); c.fullScreenPerDay = n(100); c.fullScreenPerSession = n(100)
        c.gapToPushed = 0; c.gapToRewarded = 0; c.gapToAppOpen = 0; c.appOpenMinSessions = 0; c.appOpenMinBackground = 0
        c.appOpenPerDay = 100; c.collapsibleMinSessions = 0; c.collapsiblePerDay = 100; c.collapsiblePerSession = 100
        c.nativeMinSessions = 0; c.nativeLoadsPerDay = 100; c.nativeLoadGap = 0
        c.rewardedPerDay = 100; c.rewardedPerSession = 100; c.waterPerDay = 100; c.hintPerDay = 100; c.wakePerDay = 100
        return c
    }

    // MARK: 4. Per-band yes

    func testPermissiveInputsGiveTeenAndAdultOnEveryFormat() {
        for (band, t) in [(AgeBand.thirteenPlus, AdTreatment.teen), (.eighteenPlus, .adult)] {
            let i = Self.permissive(band)
            for f in Self.formats {
                XCTAssertEqual(decide(f, i), .yes(t), "\(f) \(band)")
            }
            for perk in RewardedPerk.allCases { XCTAssertEqual(AdPolicy.path(perk, i, caps: AdCaps()), .ad(t)) }
        }
        XCTAssertTrue(AdPolicy.mayAskTracking(ageBand: .eighteenPlus, hasPlus: false))
        XCTAssertFalse(AdPolicy.mayAskTracking(ageBand: .thirteenPlus, hasPlus: false))
        XCTAssertFalse(AdPolicy.mayAskTracking(ageBand: .eighteenPlus, hasPlus: true))
    }

    func testCommonCalmGuaranteesBlockEveryFormat() {
        let base = Self.permissive(.eighteenPlus)
        let cases: [(AdBlock, (inout AdInputs) -> Void)] = [
            (.notLoaded, { $0.entitlementsLoaded = false }),
            (.onboarding, { $0.onboardingComplete = false }),
            (.paywall, { $0.onPaywall = true }),
            (.quiet, { $0.session.quietVisit = true }),
        ]
        for (block, change) in cases {
            var i = base; change(&i)
            for f in Self.formats { XCTAssertEqual(decide(f, i), .no(block), "\(f) \(block)") }
        }
        // A word in progress blocks every full-screen format; banners and the Shed card are never on that screen.
        var p = base; p.roundInProgress = true
        for f in Self.formats { XCTAssertEqual(decide(f, p), f.isFullScreen ? .no(.puzzle) : .yes(.adult), "\(f) puzzle") }
        // A pending ceremony blocks everything but the plain banner, which keeps today's rules (spec 1.5).
        var c = base; c.pendingCeremony = true
        for f in Self.formats {
            let banner = f == .banner(.home) || f == .banner(.garden)
            XCTAssertEqual(decide(f, c), banner ? .yes(.adult) : .no(.ceremony), "\(f) ceremony")
        }
    }

    // MARK: Plus flow guards (docs/pm/plus-flow-fable-review.md)

    func testNoAdOfAnyKindOnThePlusOrSeasonsPage() {
        var i = Self.permissive(.eighteenPlus); i.onPaywall = true
        for f in Self.formats { XCTAssertEqual(decide(f, i), .no(.paywall), "\(f)") }
        XCTAssertEqual(decide(.interstitial(.oneMore), i), .no(.paywall))
    }

    func testNoFullScreenAdOverASheetButTheBannerStays() {
        var i = Self.permissive(.eighteenPlus); i.sheetUp = true
        for f in [AdFormat.interstitial(.oneMore), .interstitial(.playSoonAfterEnough), .appOpen,
                  .rewarded(.water), .rewarded(.hint), .rewarded(.wake)] {
            XCTAssertEqual(decide(f, i), .no(.sheetUp), "\(f)")
        }
        XCTAssertEqual(decide(.banner(.home), i), .yes(.adult))
        XCTAssertEqual(decide(.native, i), .yes(.adult))
    }

    // MARK: 5. Budgets and gaps (ruled 11-07)

    func testTheRuledNumbers() {
        let c = AdCaps()
        XCTAssertEqual(c.pushedPerDay, 6); XCTAssertEqual(c.pushedPerSession, 2)
        XCTAssertEqual(c.fullScreenPerDay, 8); XCTAssertEqual(c.fullScreenPerSession, 4)
        XCTAssertEqual(c.gapToPushed, 600); XCTAssertEqual(c.gapToRewarded, 30); XCTAssertEqual(c.gapToAppOpen, 1800)
        XCTAssertEqual(c.rewardedPerDay, 5); XCTAssertEqual(c.rewardedPerSession, 3)
        XCTAssertEqual([c.waterPerDay, c.hintPerDay, c.wakePerDay], [3, 2, 1])
        XCTAssertEqual(AdGate.Context(now: Self.noon).peakWindowSeconds, 5)
    }

    func testPushedAdsShareSixADay() {
        for f in [AdFormat.interstitial(.oneMore), .appOpen] {
            var i = Self.permissive(.eighteenPlus); i.synced.adsToday = 5
            XCTAssertEqual(decide(f, i), .yes(.adult), "\(f)")
            i.synced.adsToday = 6
            XCTAssertEqual(decide(f, i), .no(.dayCap), "\(f)")
        }
    }

    func testTwoPushedAdsPerVisit() {
        for f in [AdFormat.interstitial(.oneMore), .appOpen] {
            var i = Self.permissive(.eighteenPlus); i.session.pushedShown = 1
            XCTAssertEqual(decide(f, i), .yes(.adult))
            i.session.pushedShown = 2
            XCTAssertEqual(decide(f, i), .no(.sessionCap), "\(f)")
        }
        var r = Self.permissive(.eighteenPlus); r.session.pushedShown = 2
        XCTAssertEqual(decide(.rewarded(.water), r), .yes(.adult), "rewarded is the player's tap, not pushed")
    }

    func testFullScreenEightADayAndFourPerVisit() {
        var i = Self.permissive(.eighteenPlus); i.ledger.fullScreen = 7
        XCTAssertEqual(decide(.rewarded(.water), i), .yes(.adult))
        i.ledger.fullScreen = 8
        XCTAssertEqual(decide(.rewarded(.water), i), .no(.dayCap))
        XCTAssertEqual(decide(.interstitial(.oneMore), i), .no(.dayCap))
        // The synced counts are a floor (a reinstall keeps them): 5 pushed + 3 rewarded = 8.
        var s = Self.permissive(.eighteenPlus); s.synced.adsToday = 5; s.synced.rewardedToday = 3
        XCTAssertEqual(decide(.rewarded(.water), s), .no(.dayCap))
        var v = Self.permissive(.eighteenPlus); v.session.fullScreenShown = 3
        XCTAssertEqual(decide(.rewarded(.water), v), .yes(.adult))
        v.session.fullScreenShown = 4
        XCTAssertEqual(decide(.rewarded(.water), v), .no(.sessionCap))
    }

    func testGapsSixHundredThirtyAndEighteenHundredSeconds() {
        let now = Self.noon
        var i = Self.permissive(.eighteenPlus)
        i.synced.lastAdAt = now.addingTimeInterval(-599)
        XCTAssertEqual(decide(.interstitial(.oneMore), i), .no(.gap))
        i.synced.lastAdAt = now.addingTimeInterval(-600)
        XCTAssertEqual(decide(.interstitial(.oneMore), i), .yes(.adult))

        var r = Self.permissive(.eighteenPlus)
        r.ledger.lastFullScreenAt = now.addingTimeInterval(-29)
        XCTAssertEqual(decide(.rewarded(.water), r), .no(.gap))
        r.ledger.lastFullScreenAt = now.addingTimeInterval(-30)
        XCTAssertEqual(decide(.rewarded(.water), r), .yes(.adult))

        var a = Self.permissive(.eighteenPlus)
        a.ledger.lastFullScreenAt = now.addingTimeInterval(-1799)
        XCTAssertEqual(decide(.appOpen, a), .no(.gap))
        a.ledger.lastFullScreenAt = now.addingTimeInterval(-1800)
        XCTAssertEqual(decide(.appOpen, a), .yes(.adult))
    }

    func testABackwardsClockMeansTheGapIsNotMetAndNeverLocksOut() {
        let now = Self.noon
        var r = Self.permissive(.eighteenPlus)
        r.ledger.lastFullScreenAt = now.addingTimeInterval(60)            // a minute "in the future"
        XCTAssertEqual(decide(.rewarded(.water), r), .no(.gap))
        r.ledger.lastFullScreenAt = now.addingTimeInterval(3 * 86_400)    // days ahead: read as now
        XCTAssertEqual(decide(.rewarded(.water), r), .no(.gap))
        XCTAssertTrue(AdPolicy.gapMet(since: now.addingTimeInterval(3 * 86_400), now: now.addingTimeInterval(30), gap: 30) == false)
        // The ledger rewrites a timestamp more than a day ahead to now, so the gap runs from now.
        let fixed = r.ledger.rolled(to: now)
        XCTAssertEqual(fixed.lastFullScreenAt, now)
        r.ledger = fixed; r.now = now.addingTimeInterval(30)
        r.interstitial.now = r.now
        XCTAssertEqual(decide(.rewarded(.water), r), .yes(.adult))
        var p = Self.permissive(.eighteenPlus); p.synced.lastAdAt = now.addingTimeInterval(120)
        XCTAssertEqual(decide(.interstitial(.oneMore), p), .no(.gap))
    }

    /// Ruling H7: Plus, under 13 and an unknown age read only the per-perk day cap.
    func testFreePathsAreNeverBlockedByVisitOrFullScreenBudgets() {
        for (band, plus) in [(AgeBand?.none, false), (.under13, false), (.eighteenPlus, true), (.thirteenPlus, true)] {
            var i = Self.permissive(band, hasPlus: plus)
            i.session.fullScreenShown = 99; i.session.pushedShown = 99; i.session.rewardedShown = 99
            i.session.rewardedLoadFailed = true
            i.synced = SyncedAdCounters(lastAdAt: Self.noon, adsToday: 99, rewardedToday: 99)
            i.ledger.fullScreen = 99; i.ledger.lastFullScreenAt = Self.noon
            for perk in RewardedPerk.allCases { XCTAssertEqual(AdPolicy.path(perk, i, caps: AdCaps()), .free, "\(perk)") }
            i.ledger.freeWater = 3; i.ledger.freeHint = 2; i.ledger.freeWake = 1
            for perk in RewardedPerk.allCases { XCTAssertEqual(AdPolicy.path(perk, i, caps: AdCaps()), .hidden, "\(perk) day cap") }
        }
    }

    // MARK: 6. Rewarded perks

    func testPerPerkCapsThreeTwoOneForAdAndFreeTogether() {
        for (perk, cap) in [(RewardedPerk.water, 3), (.hint, 2), (.wake, 1)] {
            var i = Self.permissive(.eighteenPlus)
            for k in 0..<cap {
                XCTAssertEqual(AdPolicy.path(perk, i, caps: AdCaps()), .ad(.adult), "\(perk) use \(k + 1)")
                i.ledger.recordPerk(perk, viaAd: k % 2 == 0)
            }
            XCTAssertEqual(decide(.rewarded(perk), i), .no(.formatCap), "\(perk)")
            XCTAssertEqual(AdPolicy.path(perk, i, caps: AdCaps()), .hidden)
        }
    }

    func testRewardedFiveADayAndThreePerVisit() {
        var i = Self.permissive(.eighteenPlus); i.synced.rewardedToday = 4
        XCTAssertEqual(decide(.rewarded(.water), i), .yes(.adult))
        i.synced.rewardedToday = 5
        XCTAssertEqual(decide(.rewarded(.water), i), .no(.dayCap))
        var s = Self.permissive(.eighteenPlus); s.session.rewardedShown = 3
        XCTAssertEqual(decide(.rewarded(.hint), s), .no(.sessionCap))
    }

    func testRewardedNeverInTheFirstSessionNorInQuietGardenAsAnAd() {
        var i = Self.permissive(.eighteenPlus); i.completedSessions = 0
        for perk in RewardedPerk.allCases { XCTAssertEqual(decide(.rewarded(perk), i), .no(.firstSession)) }
        var q = Self.permissive(.thirteenPlus); q.quietGarden = true
        for perk in RewardedPerk.allCases { XCTAssertEqual(decide(.rewarded(perk), q), .no(.quiet)) }
    }

    func testAFailedLoadHidesTheVideoRowForTheVisit() {
        var i = Self.permissive(.eighteenPlus); i.session.rewardedLoadFailed = true
        XCTAssertEqual(decide(.rewarded(.water), i), .no(.noFill))
        XCTAssertEqual(AdPolicy.path(.water, i, caps: AdCaps()), .hidden)
    }

    func testR1NeedsAnEmptyCan() {
        for (band, plus) in [(AgeBand.eighteenPlus, false), (.under13, false), (.eighteenPlus, true)] {
            var i = Self.permissive(band, hasPlus: plus); i.perk.water = 1
            XCTAssertEqual(AdPolicy.path(.water, i, caps: AdCaps()), .hidden)
            i.perk.water = 0; i.quietGarden = true
            XCTAssertEqual(AdPolicy.path(.water, i, caps: AdCaps()), .hidden, "Quiet Garden never uses drops")
        }
    }

    func testR2HiddenAfterALossOnTheDailyWhenBankedUnderTheShortAdNoteAndInQuietGardenForEveryone() {
        let hides: [(String, (inout AdInputs) -> Void)] = [
            ("loss", { $0.lastRoundWasLoss = true }),
            ("daily", { $0.aroundDailyBloom = true }),
            ("banked", { $0.perk.whisperBanked = true }),
            ("short ad note", { $0.perk.shortAdNoteShowing = true }),
            ("quiet garden", { $0.quietGarden = true }),
        ]
        for (band, plus) in [(AgeBand?.some(.eighteenPlus), false), (.thirteenPlus, false), (.eighteenPlus, true), (.under13, false), (nil, false)] {
            XCTAssertNotEqual(AdPolicy.path(.hint, Self.permissive(band, hasPlus: plus), caps: AdCaps()), .hidden)
            for (name, change) in hides {
                var i = Self.permissive(band, hasPlus: plus); change(&i)
                XCTAssertEqual(AdPolicy.path(.hint, i, caps: AdCaps()), .hidden, "\(name) \(String(describing: band)) plus \(plus)")
            }
        }
    }

    func testR3NeedsOneStillDreamingTry() {
        for (band, plus) in [(AgeBand.eighteenPlus, false), (.under13, false), (.thirteenPlus, true)] {
            var i = Self.permissive(band, hasPlus: plus); i.perk.wakeDreamsInARow = 0
            XCTAssertEqual(AdPolicy.path(.wake, i, caps: AdCaps()), .hidden)
            i.perk.wakeDreamsInARow = 1
            XCTAssertNotEqual(AdPolicy.path(.wake, i, caps: AdCaps()), .hidden)
        }
    }

    // MARK: HelpLadder whisper (R2)

    func testTheWhisperRungComesAfterTheOtherThreeAndRevealsTheMostFrequentConsonant() {
        // BANANAS: hint2, vowel A, first letter B, then the whisper: N (twice) before S (once).
        let word = "BANANAS"
        XCTAssertEqual(HelpLadder.nextRung(used: [], word: word, guessed: [], hint2: "x", whisper: true)?.rung, .hint2)
        XCTAssertEqual(HelpLadder.nextRung(used: [.hint2], word: word, guessed: [], hint2: "x", whisper: true)?.rung, .vowel)
        XCTAssertEqual(HelpLadder.nextRung(used: [.hint2, .vowel], word: word, guessed: ["A"], hint2: "x", whisper: true)?.rung, .firstLetter)
        let w = HelpLadder.nextRung(used: [.hint2, .vowel, .firstLetter], word: word, guessed: ["A", "B"], hint2: "x", whisper: true)
        XCTAssertEqual(w?.rung, .whisper)
        XCTAssertEqual(w?.step, .reveal("N"))
        XCTAssertNil(HelpLadder.next(used: [.hint2, .vowel, .firstLetter], word: word, guessed: ["A", "B"], hint2: "x"),
                     "no whisper banked (or the Daily Bloom): the ladder ends after three rungs")
    }

    func testTheWhisperNeverRevealsTheLastLetter() {
        // Only S is left: revealing it would solve the word, so the whisper waits.
        XCTAssertNil(HelpLadder.next(used: [.hint2, .vowel, .firstLetter], word: "BANANAS", guessed: ["A", "B", "N"], hint2: "x", whisper: true))
        // Ties go to the consonant that comes first in the word.
        XCTAssertEqual(HelpLadder.whisperLetter(letters: "CRISP", unrevealed: ["C", "R", "S", "P"]), "C")
        XCTAssertNil(HelpLadder.whisperLetter(letters: "AEIOU", unrevealed: ["A", "E"]))
    }

    // MARK: 8. Ledger

    func testANewDayStartsTheCountsFreshButKeepsTheWhisperAndTimes() {
        var l = AdLedger(day: AdLedger.dayKey(Self.noon), lastFullScreenAt: Self.noon, whisperBanked: true)
        l.fullScreen = 5; l.adWater = 2; l.freeHint = 1; l.appOpen = 1; l.nativeLoads = 3
        XCTAssertEqual(l.rolled(to: Self.noon.addingTimeInterval(60)), l, "same day: unchanged")
        let next = l.rolled(to: Self.noon.addingTimeInterval(86_400))
        XCTAssertEqual(next.day, AdLedger.dayKey(Self.noon.addingTimeInterval(86_400)))
        XCTAssertEqual([next.fullScreen, next.adWater, next.freeHint, next.appOpen, next.nativeLoads], [0, 0, 0, 0, 0])
        XCTAssertTrue(next.whisperBanked)
        XCTAssertEqual(next.lastFullScreenAt, Self.noon)
    }

    func testTheLedgerRoundTripsThroughJSON() {
        var l = AdLedger(day: 20261108, lastFullScreenAt: Self.noon, lastAppOpenAt: Self.noon.addingTimeInterval(-60),
                         lastNativeLoadAt: nil, lastBackgroundAt: Self.noon.addingTimeInterval(-7200), whisperBanked: true)
        l.appOpen = 1; l.collapsible = 2; l.nativeLoads = 3; l.fullScreen = 4
        l.adWater = 1; l.adHint = 2; l.adWake = 1; l.freeWater = 3; l.freeHint = 1; l.freeWake = 1
        XCTAssertEqual(AdLedger.decode(l.json), l)
    }

    func testACorruptOrMissingLedgerReadsAsEmpty() {
        XCTAssertEqual(AdLedger.decode(""), AdLedger())
        XCTAssertEqual(AdLedger.decode("{not json"), AdLedger())
        XCTAssertEqual(AdLedger.decode("[1,2,3]"), AdLedger())
        // A ledger from another version with missing keys still reads; what is there is kept.
        let partial = AdLedger.decode(#"{"day":20261108,"adWater":2,"futureKey":true}"#)
        XCTAssertEqual(partial.day, 20261108)
        XCTAssertEqual(partial.adWater, 2)
        XCTAssertEqual(partial.fullScreen, 0)
    }

    // MARK: Copy

    func testEveryPerkLineIsGentleAndVideoRowsSayVideo() {
        XCTAssertEqual(AdPerkCopy.all.count, 16)
        for line in AdPerkCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        for title in [AdPerkCopy.Water.adTitle, AdPerkCopy.Hint.adTitle, AdPerkCopy.Wake.adTitle] {
            XCTAssertTrue(title.lowercased().contains("video"), title)
        }
        for free in [AdPerkCopy.Water.freeTitle, AdPerkCopy.Hint.freeTitle, AdPerkCopy.Hint.subtitle, AdPerkCopy.Hint.banked,
                     AdPerkCopy.Wake.freeTitle, AdPerkCopy.Wake.freeSubtitle] {
            XCTAssertFalse(free.lowercased().contains("plus"), "free rows never mention Plus: \(free)")
            XCTAssertFalse(free.lowercased().contains("video") || free.lowercased().contains(" ad"), free)
        }
        // The spec's first wording would fail the linter; these are the replacements.
        XCTAssertFalse(CopySafety.check("Your watering can is empty.").isEmpty)
        XCTAssertFalse(CopySafety.check("A whisper is waiting for your next garden word").isEmpty)
    }

    // MARK: Debug overrides (compiled out of Release)

    func testDebugCapOverrides() {
        #if DEBUG
        let c = AdCaps.debugOverrides(arguments: ["-adcaps", "gapToPushed=5, appOpenMinSessions=0,nope=3,waterPerDay=x"])
        XCTAssertEqual(c.gapToPushed, 5); XCTAssertEqual(c.appOpenMinSessions, 0); XCTAssertEqual(c.waterPerDay, 3)
        let fast = AdCaps.debugOverrides(arguments: ["-uitest-adcaps-fast"])
        XCTAssertLessThanOrEqual(fast.gapToPushed, 5); XCTAssertEqual(fast.pushedPerDay, 6, "caps still bite")
        XCTAssertEqual(AdCaps.debugOverrides(arguments: []), AdCaps())
        #endif
    }
}

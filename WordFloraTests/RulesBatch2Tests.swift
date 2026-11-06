import XCTest
@testable import WordFlora

final class RulesBatch2Tests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)

    // MARK: AdGate
    func ctx(_ edit: (inout AdGate.Context) -> Void = { _ in }) -> AdGate.Context {
        var c = AdGate.Context(now: t0)
        c.roundsSinceAd = 3; c.choice = .oneMore; c.completedSessions = 3
        edit(&c); return c
    }

    func testShowsAfterThirdRoundWhenPlayerChoosesOneMore() { XCTAssertTrue(AdGate.shouldShowInterstitial(ctx())) }
    func testNotBeforeThirdRound() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.roundsSinceAd = 2 })) }
    func testNeverWhenThatsEnough() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.choice = .thatsEnough })) }
    func testNeverBeforeThePlayerChooses() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.choice = nil })) }
    func testNeverForUnderThirteen() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.isUnderThirteen = true })) }
    func testNeverForSubscribers() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.hasRemoveAds = true })) }
    func testNeverMidRound() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.midRound = true })) }
    func testNeverAroundTheDailyBloom() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.aroundDailyBloom = true })) }
    func testNeverDirectlyAfterALoss() { XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.lastRoundWasLoss = true })) }

    func testGracePeriodNeedsThreeSessionsOrAFirstLevelUp() {
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.completedSessions = 2 }))
        XCTAssertTrue(AdGate.shouldShowInterstitial(ctx { $0.completedSessions = 1; $0.wordLevelUps = 1 }))
    }

    func testNeverInTheFirstSessionEvenAfterALevelUp() {
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.completedSessions = 0; $0.wordLevelUps = 1 }))
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.completedSessions = 0; $0.wordLevelUps = 4 }))
    }

    func testMinimumGapAndDailyCap() {
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.lastAdAt = t0.addingTimeInterval(-170) }))
        XCTAssertTrue(AdGate.shouldShowInterstitial(ctx { $0.lastAdAt = t0.addingTimeInterval(-181) }))
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.adsToday = 6 }))
        XCTAssertTrue(AdGate.shouldShowInterstitial(ctx { $0.adsToday = 5 }))
    }

    func testNoAdInsideTheCelebrationWindowAfterAPeakIsDismissed() {
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.lastPeakAt = t0.addingTimeInterval(-4) }))
        XCTAssertTrue(AdGate.shouldShowInterstitial(ctx { $0.lastPeakAt = t0.addingTimeInterval(-6) }))
    }

    func testRemoteFrequencyIsHonoured() {
        XCTAssertFalse(AdGate.shouldShowInterstitial(ctx { $0.frequency = 5; $0.roundsSinceAd = 4 }))
        XCTAssertTrue(AdGate.shouldShowInterstitial(ctx { $0.frequency = 5; $0.roundsSinceAd = 5 }))
    }

    func testUnderThirteenAndSubscribersLoadNoAdsAtAll() {
        XCTAssertFalse(AdGate.mayLoadAnyAd(isUnderThirteen: true, hasRemoveAds: false))
        XCTAssertFalse(AdGate.mayLoadAnyAd(isUnderThirteen: false, hasRemoveAds: true))
        XCTAssertTrue(AdGate.mayLoadAnyAd(isUnderThirteen: false, hasRemoveAds: false))
    }

    func testConsentPromptsOnlyRightBeforeAnAdRequest() {
        XCTAssertFalse(AdGate.mayAskConsent(adRequestImminent: false, isUnderThirteen: false, hasRemoveAds: false))
        XCTAssertTrue(AdGate.mayAskConsent(adRequestImminent: true, isUnderThirteen: false, hasRemoveAds: false))
        XCTAssertFalse(AdGate.mayAskConsent(adRequestImminent: true, isUnderThirteen: true, hasRemoveAds: false))
    }

    /// The App Tracking Transparency prompt is for adults only: 13 to 17 already get non-personalised ads,
    /// and under 13 or an unknown age never load an ad at all.
    func testTrackingPromptOnlyForAdults() {
        XCTAssertTrue(AdGate.mayAskTracking(ageBand: .eighteenPlus))
        XCTAssertFalse(AdGate.mayAskTracking(ageBand: .thirteenPlus))
        XCTAssertFalse(AdGate.mayAskTracking(ageBand: .under13))
        XCTAssertFalse(AdGate.mayAskTracking(ageBand: nil))
    }

    // MARK: FeatureUnlockPolicy
    func testSessionOneShowsOnlyPlayGardenAndDaily() {
        let s = UnlockStats()
        XCTAssertEqual(Set(Feature.allCases.filter { FeatureUnlockPolicy.isUnlocked($0, stats: s, showEverything: false) }),
                       [.play, .garden, .dailyBloom])
    }

    func testUnlockTriggers() {
        var s = UnlockStats()
        s.plantsEarned = 3; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.sun, stats: s, showEverything: false))
        XCTAssertFalse(FeatureUnlockPolicy.isUnlocked(.soil, stats: s, showEverything: false))
        s.plantsEarned = 5; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.soil, stats: s, showEverything: false))
        s.sawTwoPetalsLeft = true; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.rose, stats: s, showEverything: false))
        XCTAssertFalse(FeatureUnlockPolicy.isUnlocked(.butterfly, stats: s, showEverything: false))
        s.gardenDays = 3; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.butterfly, stats: s, showEverything: false))
        s.gardenDays = 1; s.wordLevelUps = 1; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.butterfly, stats: s, showEverything: false))
        XCTAssertFalse(FeatureUnlockPolicy.isUnlocked(.shed, stats: s, showEverything: false))
        s.wordLevelUps = 2; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.shed, stats: s, showEverything: false))
        XCTAssertFalse(FeatureUnlockPolicy.isUnlocked(.badges, stats: s, showEverything: false))
        s.badgesEarned = 1; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.badges, stats: s, showEverything: false))
        XCTAssertFalse(FeatureUnlockPolicy.isUnlocked(.glowLantern, stats: s, showEverything: false))
        s.butterflyPlays = 1; XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(.glowLantern, stats: s, showEverything: false))
    }

    func testShowEverythingUnlocksAll() {
        for f in Feature.allCases { XCTAssertTrue(FeatureUnlockPolicy.isUnlocked(f, stats: UnlockStats(), showEverything: true)) }
    }

    func testGardenLevelsUnlockMisterThenShearsThenLamp() {
        XCTAssertEqual(FeatureUnlockPolicy.gardenTools(completedGardenLevels: 0), [])
        XCTAssertEqual(FeatureUnlockPolicy.gardenTools(completedGardenLevels: 2), [.mister, .shears])
        XCTAssertEqual(FeatureUnlockPolicy.gardenTools(completedGardenLevels: 9), [.mister, .shears, .lamp])
    }

    func testEachUnlockAnnouncesExactlyOnce() {
        var s = UnlockStats(); var seen = Set<Feature>()
        var announced = [Feature]()
        s.plantsEarned = 3
        for f in FeatureUnlockPolicy.newlyUnlocked(stats: s, alreadySeen: &seen, showEverything: false) { announced.append(f) }
        for f in FeatureUnlockPolicy.newlyUnlocked(stats: s, alreadySeen: &seen, showEverything: false) { announced.append(f) }
        XCTAssertEqual(announced, [.sun])
    }

    // MARK: AssistTuner
    private func rounds(won: Int, helped: Int = 0, total: Int = 10) -> [RoundOutcome] {
        (0..<total).map { RoundOutcome(won: $0 < won, helpUsed: $0 < helped) }
    }

    func testTunerRaisesDifficultyForDominantPlayers() {
        XCTAssertEqual(AssistTuner.next(current: 1, history: rounds(won: 10), roundsSinceChange: 5, locked: false), 2)
    }
    func testTunerLowersDifficultyForStrugglingPlayers() {
        XCTAssertEqual(AssistTuner.next(current: 1, history: rounds(won: 4), roundsSinceChange: 5, locked: false), 0)
    }
    func testTunerNeedsTenRoundsAndFiveSinceLastChange() {
        XCTAssertEqual(AssistTuner.next(current: 1, history: rounds(won: 9, total: 9), roundsSinceChange: 9, locked: false), 1)
        XCTAssertEqual(AssistTuner.next(current: 1, history: rounds(won: 10), roundsSinceChange: 4, locked: false), 1)
    }
    func testTunerIsBoundedAndRespectsLock() {
        XCTAssertEqual(AssistTuner.next(current: 2, history: rounds(won: 10), roundsSinceChange: 9, locked: false), 2)
        XCTAssertEqual(AssistTuner.next(current: 0, history: rounds(won: 0), roundsSinceChange: 9, locked: false), 0)
        XCTAssertEqual(AssistTuner.next(current: 1, history: rounds(won: 10), roundsSinceChange: 9, locked: true), 1)
    }
    func testHelpedWinsDoNotCountAsDominance() {
        XCTAssertEqual(AssistTuner.next(current: 1, history: rounds(won: 10, helped: 5), roundsSinceChange: 9, locked: false), 1)
    }
    func testPulseComesEarlierForGentleAndUnderThirteenDefaultsGentle() {
        XCTAssertEqual(AssistTuner.pulseAfterWrongGuesses(level: 0), 2)
        XCTAssertEqual(AssistTuner.pulseAfterWrongGuesses(level: 1), 3)
        XCTAssertEqual(AssistTuner.defaultLevel(isUnderThirteen: true), 0)
        XCTAssertEqual(AssistTuner.defaultLevel(isUnderThirteen: false), 1)
    }
    func testBandHalfSelection() {
        XCTAssertEqual(AssistTuner.bandHalf(level: 0), .lower)
        XCTAssertEqual(AssistTuner.bandHalf(level: 1), .whole)
        XCTAssertEqual(AssistTuner.bandHalf(level: 2), .upper)
    }

    // MARK: OnboardingFlow
    func testFlowStartsAtIntroAndAgeHasNoDefault() {
        let f = OnboardingFlow()
        XCTAssertEqual(f.step, .intro)
        XCTAssertNil(f.selectedAgeBand)
    }

    func testHappyPathOrder() {
        var f = OnboardingFlow()
        f.introFinished(); XCTAssertEqual(f.step, .age)
        f.selectAge(.thirteenPlus); XCTAssertEqual(f.step, .guide)
        f.guideFinished(); XCTAssertEqual(f.step, .tutorialWord)
        f.tutorialSolved(); XCTAssertEqual(f.step, .plantEarned)
        f.plantEarnedDismissed(); XCTAssertEqual(f.step, .gardenTip)
        f.tipCompleted(); XCTAssertEqual(f.step, .home)
        XCTAssertTrue(f.isComplete)
    }

    func testAgeScreenCannotBeSkippedWithoutASelection() {
        var f = OnboardingFlow(); f.introFinished()
        f.tutorialSolved()   // out of order, ignored
        XCTAssertEqual(f.step, .age)
    }

    func testSkipJumpsHomeAndStaysComplete() {
        var f = OnboardingFlow(); f.introFinished(); f.selectAge(.under13)
        f.skip()
        XCTAssertTrue(f.isComplete); XCTAssertEqual(f.step, .home)
    }

    func testNoPromptsBeforeAdsEligibleAndNoPaywallInSessionOne() {
        var f = OnboardingFlow()
        XCTAssertFalse(f.mayShowPaywall); XCTAssertFalse(f.mayRequestPermissions)
        f.introFinished(); f.selectAge(.eighteenPlus); f.guideFinished(); f.tutorialSolved(); f.plantEarnedDismissed(); f.tipCompleted()
        XCTAssertFalse(f.mayShowPaywall)          // still session one
        f.startNextSession()
        XCTAssertTrue(f.mayShowPaywall)
    }

    func testUnderThirteenFlagsComeFromTheAgeAnswer() {
        var f = OnboardingFlow(); f.introFinished(); f.selectAge(.under13)
        XCTAssertTrue(f.isUnderThirteen)
    }

    func testRestoredFlowFromSavedStateSkipsAhead() {
        let f = OnboardingFlow(restoredComplete: true, ageBand: .thirteenPlus)
        XCTAssertTrue(f.isComplete); XCTAssertEqual(f.step, .home)
    }
}

/// Garden Path level map: copy safety and the per-level state table (design-preview/level-map/README.md).
final class LevelMapTests: XCTestCase {
    /// 50 plants, 10 per level. `found[i]` plants of level i+1 are earned; `bloom[i]` of those are at stage 4.
    private func garden(found: [Int], bloom: [Int] = [0, 0, 0, 0, 0]) -> [PlantProgress] {
        (1...5).flatMap { level in
            (0..<10).map { i in
                PlantProgress(level: level, earned: i < found[level - 1], stage: i < bloom[level - 1] ? 4 : (i < found[level - 1] ? 1 : 0))
            }
        }
    }

    func testEveryStringPassesCopySafetyAndNeverSaysLock() {
        var all = LevelMapCopy.allStrings
        let mid = LevelMapCopy.stops(plants: garden(found: [10, 4, 0, 0, 0], bloom: [7, 0, 0, 0, 0]), currentLevel: 2)
        let done = LevelMapCopy.stops(plants: garden(found: [10, 10, 10, 10, 10], bloom: [10, 10, 10, 6, 2]), currentLevel: 5)
        let new = LevelMapCopy.stops(plants: garden(found: [0, 0, 0, 0, 0]), currentLevel: 1)
        for s in mid + done + new { all += s.rows + [s.accessibilityLabel] + [s.allFoundLine, s.fullBloomLine, s.nextStep].compactMap { $0 } }
        XCTAssertGreaterThan(all.count, 100)
        for t in all {
            XCTAssertEqual(CopySafety.check(t), [], t)
            XCTAssertFalse(t.lowercased().contains("lock"), t)
        }
        for word in ["left", "only", "last", "miss", "waiting", "lost", "empty"] {
            XCTAssertFalse(CopySafety.check("x \(word) x").isEmpty, "CopySafety still bans \(word)")
        }
    }

    func testNewGardenLevelOneIsCurrentAndTheRestAreComingSoon() {
        let stops = LevelMapCopy.stops(plants: garden(found: [0, 0, 0, 0, 0]), currentLevel: 1)
        XCTAssertEqual(stops.map(\.level), [1, 2, 3, 4, 5])
        XCTAssertEqual(stops.map(\.name), ["Seedling", "Sprout", "Bloom", "Grove", "Ancient"])
        XCTAssertEqual(stops.map(\.isCurrent), [true, false, false, false, false])
        XCTAssertEqual(stops.map(\.isSoon), [false, true, true, true, true])
        let one = stops[0]
        XCTAssertEqual(one.rows, ["Find your first plant!"])
        XCTAssertEqual(one.nextStep, "Find 10 plants to open Level 2.")
        XCTAssertNil(one.allFoundLine); XCTAssertNil(one.fullBloomLine)
        XCTAssertEqual(one.accessibilityLabel, "Level 1, Seedling. Garden friends. You are here. Find your first plant! Find 10 plants to open Level 2.")
        XCTAssertEqual(stops[2].rows, [])
        XCTAssertNil(stops[2].nextStep)
        XCTAssertEqual(stops[2].accessibilityLabel,
                       "Level 3, Bloom. Strange and wild plants. Coming soon in your garden. Opens when Level 2 has 10 plants.")
        XCTAssertEqual(LevelMapCopy.subLine(totalFound: 0), "Every 10 plants opens a new level.")
        XCTAssertEqual(stops.map(\.heroImage), ["plant_daisy", "plant_lotus", "plant_venus_flytrap", "plant_giant_water_lily", "plant_wollemi_pine"])
    }

    func testMidGardenWithFourteenFound() {
        let plants = garden(found: [10, 4, 0, 0, 0], bloom: [7, 0, 0, 0, 0])
        XCTAssertEqual(ProgressionPolicy.wordLevel(plants: plants, economy: Economy()), 2)
        let stops = LevelMapCopy.stops(plants: plants, currentLevel: 2)
        XCTAssertEqual(stops.map(\.found).reduce(0, +), 14)
        XCTAssertEqual(LevelMapCopy.subLine(totalFound: 14), "14 plants found. Every 10 plants opens a new level.")
        let one = stops[0], two = stops[1]
        XCTAssertFalse(one.isCurrent); XCTAssertTrue(one.isOpen)
        XCTAssertEqual(one.rows, ["10 of 10 plants found", "7 of 10 in full bloom"])
        XCTAssertEqual(one.allFoundLine, "All 10 found! Level 2 is open.")
        XCTAssertNil(one.nextStep); XCTAssertFalse(one.fullBloom)
        XCTAssertTrue(two.isCurrent)
        XCTAssertEqual(two.rows, ["4 of 10 plants found", "0 of 10 in full bloom"])
        XCTAssertEqual(two.nextStep, "Find 6 more to open Level 3.")
        XCTAssertEqual(two.accessibilityLabel,
                       "Level 2, Sprout. Plants from far away. You are here. 4 of 10 plants found. 0 of 10 in full bloom. Find 6 more to open Level 3.")
        XCTAssertEqual(stops.map(\.isSoon), [false, false, true, true, true])
    }

    func testAllFoundLevelFiveIsCurrentAndEveryLevelIsOpen() {
        let plants = garden(found: [10, 10, 10, 10, 10], bloom: [10, 10, 10, 6, 2])
        XCTAssertEqual(ProgressionPolicy.wordLevel(plants: plants, economy: Economy()), 5)
        let stops = LevelMapCopy.stops(plants: plants, currentLevel: 5)
        XCTAssertEqual(stops.map(\.isSoon), [false, false, false, false, false])
        XCTAssertEqual(stops.map(\.fullBloom), [true, true, true, false, false])
        XCTAssertEqual(stops[0].fullBloomLine, "Full bloom garden!")
        XCTAssertEqual(stops[3].allFoundLine, "All 10 found! Level 5 is open.")
        let five = stops[4]
        XCTAssertTrue(five.isCurrent)
        XCTAssertEqual(five.allFoundLine, "All 10 found! Every level is open.")
        XCTAssertNil(five.nextStep)
        XCTAssertEqual(LevelMapCopy.subLine(totalFound: 50), "All 50 plants found! Grow them all to full bloom.")
        XCTAssertTrue(stops[0].accessibilityLabel.hasSuffix("All 10 found! Level 2 is open. Full bloom garden!"))
    }

    func testLevelFiveNextStepNeverPointsPastTheLastLevel() {
        XCTAssertEqual(LevelMapCopy.nextStep(level: 5, found: 0), "Find 10 plants for Level 5.")
        XCTAssertEqual(LevelMapCopy.nextStep(level: 5, found: 3), "Find 7 more for Level 5.")
        XCTAssertEqual(LevelMapCopy.nextStep(level: 4, found: 9), "Find 1 more to open Level 5.")
        XCTAssertEqual(LevelMapCopy.stops(plants: [], currentLevel: 9).last?.isCurrent, true)
    }
}

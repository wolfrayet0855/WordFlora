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
        XCTAssertTrue(AdGate.shouldShowInterstitial(ctx { $0.completedSessions = 0; $0.wordLevelUps = 1 }))
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
        f.selectAge(.thirteenPlus); XCTAssertEqual(f.step, .tutorialWord)
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
        f.introFinished(); f.selectAge(.eighteenPlus); f.tutorialSolved(); f.plantEarnedDismissed(); f.tipCompleted()
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

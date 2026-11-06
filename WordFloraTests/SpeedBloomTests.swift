import XCTest
import SwiftData
@testable import WordFlora

/// Speed bloom: the pure rule (time per word, cap, Extra time, Help pause, the ring relaxing, gating) and how the round
/// and the badge shelf use it.
final class SpeedBloomRuleTests: XCTestCase {
    private let on = SpeedBloom.Prefs(optedIn: true, extraTime: false, ageBand: .thirteenPlus, calmMode: false, quietGarden: false)

    // MARK: seconds per word
    func testTwelveSecondsPlusFourPerLetter() {
        XCTAssertEqual(SpeedBloom.seconds(letters: 0, extraTime: false), 12)
        XCTAssertEqual(SpeedBloom.seconds(letters: 1, extraTime: false), 16)
        XCTAssertEqual(SpeedBloom.seconds(letters: 5, extraTime: false), 32)
        XCTAssertEqual(SpeedBloom.seconds(letters: 10, extraTime: false), 52)
    }

    func testOnlyLettersCount() {
        XCTAssertEqual(SpeedBloom.letterCount("SEA HOLLY"), 8)
        XCTAssertEqual(SpeedBloom.letterCount("FORGET-ME-NOT"), 11)
        XCTAssertEqual(SpeedBloom.seconds(for: "SEA HOLLY", extraTime: false), 44)
    }

    func testCappedAtNinetySeconds() {
        XCTAssertEqual(SpeedBloom.seconds(letters: 19, extraTime: false), 88)
        XCTAssertEqual(SpeedBloom.seconds(letters: 20, extraTime: false), 90)
        XCTAssertEqual(SpeedBloom.seconds(letters: 40, extraTime: false), 90)
        XCTAssertEqual(SpeedBloom.seconds(letters: -3, extraTime: false), 12)
    }

    func testExtraTimeIsHalfAsLongAgainEvenAtTheCap() {
        XCTAssertEqual(SpeedBloom.seconds(letters: 5, extraTime: true), 48)
        XCTAssertEqual(SpeedBloom.seconds(letters: 40, extraTime: true), 135)
        for n in 0...30 { XCTAssertGreaterThan(SpeedBloom.seconds(letters: n, extraTime: true), SpeedBloom.seconds(letters: n, extraTime: false)) }
    }

    // MARK: gating
    func testOfferedOnlyToThirteenPlusWithCalmAndQuietGardenOff() {
        XCTAssertFalse(SpeedBloom.isOffered(ageBand: nil, calmMode: false, quietGarden: false), "unknown age counts as young")
        XCTAssertFalse(SpeedBloom.isOffered(ageBand: .under13, calmMode: false, quietGarden: false))
        XCTAssertTrue(SpeedBloom.isOffered(ageBand: .thirteenPlus, calmMode: false, quietGarden: false))
        XCTAssertTrue(SpeedBloom.isOffered(ageBand: .eighteenPlus, calmMode: false, quietGarden: false))
        XCTAssertFalse(SpeedBloom.isOffered(ageBand: .eighteenPlus, calmMode: true, quietGarden: false))
        XCTAssertFalse(SpeedBloom.isOffered(ageBand: .eighteenPlus, calmMode: false, quietGarden: true))
    }

    func testDefaultIsOff() {
        XCTAssertFalse(SpeedBloom.Prefs.off.optedIn)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-speed-\(UUID().uuidString)")!)
        settings.applyAgeDefaults(.eighteenPlus)
        XCTAssertFalse(settings.speedBloomOn)
        XCTAssertFalse(settings.speedBloomExtraTime)
        XCTAssertFalse(SpeedBloom.applies(settings.speedBloomPrefs, wordLevel: 5))
    }

    func testSettingsArePersistedOnTheDevice() {
        let suite = UserDefaults(suiteName: "wf-speed-\(UUID().uuidString)")!
        let a = AppSettings(defaults: suite)
        a.speedBloomOn = true; a.speedBloomExtraTime = true
        let b = AppSettings(defaults: suite)
        XCTAssertTrue(b.speedBloomOn); XCTAssertTrue(b.speedBloomExtraTime)
    }

    func testAppliesOnlyToLevelsFourAndFiveInRegularRounds() {
        for level in 1...3 { XCTAssertFalse(SpeedBloom.applies(on, wordLevel: level), "\(level)") }
        XCTAssertTrue(SpeedBloom.applies(on, wordLevel: 4))
        XCTAssertTrue(SpeedBloom.applies(on, wordLevel: 5))
        XCTAssertFalse(SpeedBloom.applies(on, wordLevel: 5, isDaily: true))
        XCTAssertFalse(SpeedBloom.applies(on, wordLevel: 5, isTutorial: true))
    }

    func testCalmQuietGardenAgeOrTheToggleTurnItOff() {
        var p = on; p.optedIn = false
        XCTAssertFalse(SpeedBloom.applies(p, wordLevel: 5))
        p = on; p.calmMode = true
        XCTAssertFalse(SpeedBloom.applies(p, wordLevel: 5), "Calm turns it off even when opted in")
        p = on; p.quietGarden = true
        XCTAssertFalse(SpeedBloom.applies(p, wordLevel: 5), "Quiet Garden turns it off even when opted in")
        p = on; p.ageBand = .under13
        XCTAssertFalse(SpeedBloom.applies(p, wordLevel: 5))
        p = on; p.ageBand = nil
        XCTAssertFalse(SpeedBloom.applies(p, wordLevel: 5))
    }

    func testBadgeShowsOnlyWhenOnOrAlreadyEarned() {
        XCTAssertTrue(SpeedBloom.showsBadge(on, earnedAnyTier: false))
        XCTAssertFalse(SpeedBloom.showsBadge(.off, earnedAnyTier: false), "the shelf never nudges toward the toggle")
        var young = on; young.ageBand = .under13
        XCTAssertFalse(SpeedBloom.showsBadge(young, earnedAnyTier: false))
        XCTAssertTrue(SpeedBloom.showsBadge(.off, earnedAnyTier: true), "nothing earned is hidden away")
    }

    // MARK: the ring
    func testTheRingFillsAndRelaxesToNormalPaceWhenItCloses() {
        var r = SpeedBloomRing(budget: 32)
        XCTAssertEqual(r.fill, 0)
        XCTAssertFalse(r.advance(by: 16))
        XCTAssertEqual(r.fill ?? -1, 0.5, accuracy: 0.0001)
        XCTAssertTrue(r.advance(by: 20), "this step closes the ring")
        XCTAssertEqual(r.outcome, .relaxed)
        XCTAssertNil(r.fill, "the ring fades away")
        XCTAssertFalse(r.advance(by: 5), "closes only once")
        XCTAssertFalse(r.wordSolved(), "a word solved after the ring closed is a normal win")
        XCTAssertEqual(r.outcome, .relaxed)
    }

    func testSolvingBeforeItClosesIsAQuickBloom() {
        var r = SpeedBloomRing(budget: 32)
        r.advance(by: 31.9)
        XCTAssertTrue(r.wordSolved())
        XCTAssertEqual(r.outcome, .bloomedInTime)
        XCTAssertFalse(r.advance(by: 10), "nothing moves after the word is solved")
        XCTAssertFalse(r.wordSolved(), "counted once")
    }

    func testHelpPausesTheRingAndAPauseNeverStacks() {
        var r = SpeedBloomRing(budget: 30)
        r.advance(by: 5)
        r.helpTapped()
        r.advance(by: 6)
        XCTAssertEqual(r.elapsed, 5, "paused")
        r.helpTapped()                     // restarts the 10 s pause, does not add to it
        r.advance(by: 12)
        XCTAssertEqual(r.elapsed, 7, accuracy: 0.0001)
        r.advance(by: 3)
        XCTAssertEqual(r.elapsed, 10, accuracy: 0.0001)
    }

    func testARestingRoundEndsTheRingWithNoQuickBloom() {
        var r = SpeedBloomRing(budget: 30)
        r.advance(by: 3)
        r.roundRested()
        XCTAssertEqual(r.outcome, .ended)
        XCTAssertFalse(r.wordSolved())
    }

    func testZeroOrNegativeStepsAreIgnored() {
        var r = SpeedBloomRing(budget: 30)
        r.advance(by: 0); r.advance(by: -4)
        XCTAssertEqual(r.elapsed, 0)
    }

    // MARK: copy
    func testCopyIsGentleAndNeverNamesTheClock() {
        for line in SpeedBloomCopy.all {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertEqual(SpeedBloomCopy.pressureWords(in: line), [], line)
        }
        let badge = ((try? BadgeCatalog.load()) ?? []).first { $0.id == SpeedBloom.badgeId }
        XCTAssertNotNil(badge)
        for line in [badge?.title ?? "", badge?.blurb ?? ""] {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertEqual(SpeedBloomCopy.pressureWords(in: line), [], line)
        }
    }

    func testTheAvoidListCatchesClockWords() {
        XCTAssertEqual(SpeedBloomCopy.pressureWords(in: "Beat the timer!"), ["timer", "beat the"])
        XCTAssertEqual(SpeedBloomCopy.pressureWords(in: "Time's up"), ["time's up"])
        XCTAssertEqual(SpeedBloomCopy.pressureWords(in: "Take your time"), [])
    }

    func testQuickBloomIsANormalThreeTierBadgeWithArt() throws {
        let d = try XCTUnwrap(try BadgeCatalog.load().first { $0.id == SpeedBloom.badgeId })
        XCTAssertEqual(d.counter, BadgeCounter.quickBlooms.rawValue)
        XCTAssertEqual(d.thresholds.count, 3)
        XCTAssertFalse(BadgeCounter.quickBlooms.isHighWater)
        for tier in 1...3 { XCTAssertNotNil(UIImage(named: "badge_quick_bloom_t\(tier)"), "t\(tier)") }
    }
}

/// The round and the app with Speed bloom on.
@MainActor
final class SpeedBloomGameTests: XCTestCase {
    private var container: ModelContainer!
    private let on = SpeedBloom.Prefs(optedIn: true, extraTime: false, ageBand: .eighteenPlus, calmMode: false, quietGarden: false)

    override func setUp() async throws {
        container = try SharedContainer.make(inMemory: true)
    }

    private func entry(_ word: String, level: Int) -> WordEntry {
        WordEntry(id: "s-\(word)-\(level)", word: word, display: word.capitalized, hint: "a hint", hint2: "a second clue", fact: "a fact",
                  level: level, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: false,
                  source: "t", license: "t", reviewedBy: "t")
    }

    private func makeVM(prefs: SpeedBloom.Prefs) -> GameViewModel {
        let vm = GameViewModel(modelContext: container.mainContext,
                               bank: WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1)),
                               seed: 3)
        vm.soundEnabled = false
        vm.seedPlantsIfNeeded()
        vm.speedBloomPrefs = { prefs }
        return vm
    }

    private func guess(_ vm: GameViewModel, _ letters: String) { for c in letters { vm.guessInput = String(c); vm.submitGuess() } }

    func testALevelFourWordGetsTheRingAndALevelThreeWordDoesNot() {
        let vm = makeVM(prefs: on)
        vm.start(entry: entry("LOTUS", level: 3))
        XCTAssertNil(vm.speedRing)
        vm.start(entry: entry("LOTUS", level: 4))
        XCTAssertEqual(vm.speedRing?.budget, 32)
        var extra = on; extra.extraTime = true
        vm.speedBloomPrefs = { extra }
        vm.start(entry: entry("LOTUS", level: 5))
        XCTAssertEqual(vm.speedRing?.budget, 48)
    }

    func testOffByDefaultAndInCalm() {
        var calm = on; calm.calmMode = true
        for prefs in [SpeedBloom.Prefs.off, calm] {
            let vm = makeVM(prefs: prefs)
            vm.start(entry: entry("LOTUS", level: 5))
            XCTAssertNil(vm.speedRing)
        }
    }

    func testRunningOutTurnsToNormalPaceWithTheSameRewardAndNoPetalCost() {
        let vm = makeVM(prefs: on)
        vm.start(entry: entry("LOTUS", level: 4))
        let water = vm.playerProfile?.water ?? 0
        vm.advanceSpeedRing(by: 40)
        XCTAssertEqual(vm.speedRing?.outcome, .relaxed)
        XCTAssertEqual(vm.phase, .playing, "the round goes on")
        XCTAssertEqual(vm.petalsRemaining, 8, "no petal cost")
        guess(vm, "LOTUS")
        XCTAssertEqual(vm.phase, .won)
        XCTAssertFalse(vm.quickBloom)
        XCTAssertEqual((vm.playerProfile?.water ?? 0) - water, 2, "the same water as any clean win")
    }

    func testSolvingInTimeIsAQuickBloom() {
        let vm = makeVM(prefs: on)
        vm.start(entry: entry("LOTUS", level: 4))
        vm.advanceSpeedRing(by: 10)
        guess(vm, "LOTUS")
        XCTAssertTrue(vm.quickBloom)
        vm.start(entry: entry("LOTUS", level: 4))
        XCTAssertFalse(vm.quickBloom, "reset for each round")
    }

    func testHelpPausesTheRing() {
        let vm = makeVM(prefs: on)
        vm.start(entry: entry("LOTUS", level: 4))
        vm.advanceSpeedRing(by: 2)
        vm.useHelp()
        vm.advanceSpeedRing(by: 8)
        XCTAssertEqual(vm.speedRing?.elapsed, 2)
    }

    func testTheRingHoldsStillWhileTheRoundIsNotBeingPlayed() {
        let vm = makeVM(prefs: on)
        vm.start(entry: entry("LOTUS", level: 4))
        guess(vm, "ZXQJKVWY")                               // eight misses: the round rests
        XCTAssertNotEqual(vm.phase, .playing)
        let before = vm.speedRing
        vm.advanceSpeedRing(by: 50)
        XCTAssertEqual(vm.speedRing, before)
    }

    // MARK: app

    private func makeApp(prefs: SpeedBloom.Prefs) -> AppModel {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-speed-\(UUID().uuidString)")!)
        if let a = prefs.ageBand { settings.applyAgeDefaults(a) }
        settings.calmMode = prefs.calmMode; settings.quietGarden = prefs.quietGarden
        settings.speedBloomOn = prefs.optedIn; settings.speedBloomExtraTime = prefs.extraTime
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, notifications: ReminderTests.FakeCenter())
    }

    func testTheAppPassesItsSettingsToTheRound() {
        let app = makeApp(prefs: on)
        app.game.start(entry: entry("LOTUS", level: 5))
        XCTAssertNotNil(app.game.speedRing)
        app.settings.speedBloomOn = false
        app.game.start(entry: entry("LOTUS", level: 5))
        XCTAssertNil(app.game.speedRing, "the toggle is the off-switch")
    }

    func testAQuickBloomCountsTowardTheBadge() {
        let app = makeApp(prefs: on)
        app.game.start(entry: entry("LOTUS", level: 4))
        guess(app.game, "LOTUS")
        let unlocks = app.roundFinished()
        XCTAssertEqual(app.badges.progress(of: .quickBlooms), 1)
        XCTAssertTrue(unlocks.contains { $0.badgeId == SpeedBloom.badgeId && $0.tier == 1 })
    }

    func testARelaxedRoundCountsNoQuickBloom() {
        let app = makeApp(prefs: on)
        app.game.start(entry: entry("LOTUS", level: 4))
        app.game.advanceSpeedRing(by: 100)
        guess(app.game, "LOTUS")
        app.roundFinished()
        XCTAssertEqual(app.badges.progress(of: .quickBlooms), 0)
    }
}

import XCTest
@testable import WordFlora

final class WakeRuleTests: XCTestCase {
    func testNoWakesYetSuggestsButterflies() {
        XCTAssertEqual(WakeRule.suggestion(last: nil, lastResult: nil), .butterflies)
    }
    func testAWordWinSuggestsTheWordPuzzle() {
        XCTAssertEqual(WakeRule.suggestion(last: .wordPuzzle, lastResult: .woke), .wordPuzzle)
        XCTAssertEqual(WakeRule.suggestion(last: .butterflies, lastResult: .woke), .butterflies)
    }
    func testStillDreamingSuggestsButterflies() {
        XCTAssertEqual(WakeRule.suggestion(last: .wordPuzzle, lastResult: .stillDreaming), .butterflies)
        XCTAssertEqual(WakeRule.suggestion(last: .butterflies, lastResult: .stillDreaming), .butterflies)
    }
    func testSuggestedTileComesFirstAndBothAlwaysShow() {
        XCTAssertEqual(WakeRule.ordered(suggested: .wordPuzzle), [.wordPuzzle, .butterflies])
        XCTAssertEqual(WakeRule.ordered(suggested: .butterflies), [.butterflies, .wordPuzzle])
    }
    func testTwoDreamsInARowMakeTheNextTryEasier() {
        XCTAssertFalse(WakeRule.isEasier(dreamsInARow: 1))
        XCTAssertTrue(WakeRule.isEasier(dreamsInARow: 2))
        XCTAssertEqual(WakeRule.butterflyGoal(dreamsInARow: 0), 3)
        XCTAssertEqual(WakeRule.butterflyGoal(dreamsInARow: 2), 2)
    }
    func testButterfliesWakeAtTheGentleGoal() {
        XCTAssertFalse(WakeRule.butterfliesWoke(caught: 2, goal: 3))
        XCTAssertTrue(WakeRule.butterfliesWoke(caught: 3, goal: 3))
        XCTAssertTrue(WakeRule.butterfliesWoke(caught: 9, goal: 3))
    }
    func testTheGentleGoalIsReachableInARealGame() {
        // A player who taps each visitor as it rests (Reduce Motion) easily meets the goal well within the game.
        var g = ButterflyGameModel(pool: ["cabbagewhite"], floweringPlants: 0, reduceMotion: true, seed: 7)
        var t = 0.0
        while !g.isFinished && g.caught.count < WakeRule.butterflyGoal(dreamsInARow: 0) {
            g.tick(0.1); t += 0.1
            if let v = g.visitors.first { g.catchAt(x: v.x, y: v.y) }
        }
        XCTAssertGreaterThanOrEqual(g.caught.count, 3)
        XCTAssertLessThan(t, ButterflyGameModel.duration / 2)
    }
    func testEveryNewStringIsGentleAndSafe() {
        for name in ["Daisy", "Rose"] {
            for line in WakeCopy.all(name: name) {
                XCTAssertEqual(CopySafety.check(line), [], line)
                XCTAssertFalse(line.localizedCaseInsensitiveContains("maybe later"), line)
                XCTAssertFalse(line.isEmpty)
            }
        }
        XCTAssertTrue(WakeCopy.all(name: "Daisy").contains("Still dreaming. Try again anytime, it is free."))
    }
}

final class WakePuzzleTests: XCTestCase {
    let names = ["Dandelion", "Daisy", "Clover", "Marigold", "Sunflower", "Tulip", "Rose", "Poppy", "Fern", "Orchid",
                 "Lavender", "Saguaro Cactus", "Lady's Slipper Orchid", "Jasmine", "Bamboo", "Hibiscus"]

    func testCandidatesAreSingleWordPlantNamesOfAGoodLength() {
        let c = WakePuzzle.candidates(from: names)
        XCTAssertTrue(c.contains("DANDELION")); XCTAssertTrue(c.contains("CLOVER"))
        XCTAssertFalse(c.contains("FERN"))          // too short to be a puzzle
        XCTAssertFalse(c.contains { $0.contains(" ") || $0.contains("'") })
    }
    func testSamePlantAndDayGiveTheSamePuzzleAndOtherDaysDiffer() {
        let a = WakePuzzle.make(plantId: "daisy", day: 100, names: names)
        let b = WakePuzzle.make(plantId: "daisy", day: 100, names: names)
        XCTAssertNotNil(a); XCTAssertEqual(a, b)
        let week = Set((100..<107).compactMap { WakePuzzle.make(plantId: "daisy", day: $0, names: names) })
        XCTAssertGreaterThan(week.count, 1)
    }
    func testTheAnswerIsAPlantNameAndNeverThePlantBeingWoken() {
        for day in 0..<60 {
            let p = WakePuzzle.make(plantId: "daisy", day: day, names: names)!
            XCTAssertTrue(WakePuzzle.candidates(from: names).contains(p.answer))
            XCTAssertNotEqual(p.answer, "DAISY")
        }
    }
    func testBothVariantsAppearAndAreWellFormed() {
        var seen = Set<WakePuzzle.Variant>()
        for day in 0..<60 {
            let p = WakePuzzle.make(plantId: "rose", day: day, names: names)!
            seen.insert(p.variant)
            XCTAssertEqual(p.slots.count, p.answer.count)
            // tiles plus the given letters make up the answer exactly
            let given = p.slots.compactMap { $0 }
            XCTAssertEqual((given + p.tiles).sorted(), Array(p.answer).sorted())
            for (i, ch) in p.slots.enumerated() { if let ch { XCTAssertEqual(ch, Array(p.answer)[i]) } }
            switch p.variant {
            case .anagram:
                XCTAssertTrue(p.slots.allSatisfy { $0 == nil })
                XCTAssertNotEqual(String(p.tiles), p.answer)       // never shown already solved
            case .missingVowels:
                XCTAssertTrue(p.tiles.allSatisfy { "AEIOU".contains($0) })
                XCTAssertTrue(p.slots.compactMap { $0 }.allSatisfy { !"AEIOU".contains($0) })
            }
        }
        XCTAssertEqual(seen, [.anagram, .missingVowels])
    }
    func testHintsNeverLeakTheAnswer() {
        for day in 0..<60 {
            let p = WakePuzzle.make(plantId: "tulip", day: day, names: names)!
            XCTAssertFalse(p.hint.uppercased().contains(p.answer), p.hint)
            XCTAssertEqual(CopySafety.check(p.hint), [])
            XCTAssertEqual(CopySafety.check(p.intro), [])
        }
    }
    func testValidationAcceptsAnyPlantNameThatFitsTheLetters() {
        let p = WakePuzzle(variant: .anagram, answer: "ROSE", slots: [nil, nil, nil, nil], tiles: Array("SORE"), hint: "", intro: "")
        XCTAssertTrue(p.isCorrect("rose", validNames: ["Rose", "Daisy"]))
        XCTAssertFalse(p.isCorrect("SORE", validNames: ["Rose", "Daisy"]))       // a real word, but not a plant
        XCTAssertTrue(p.isCorrect("EROS", validNames: ["Rose", "Eros"]))         // another plant with the same letters fits too
        XCTAssertFalse(p.isCorrect("DAISY", validNames: ["Rose", "Daisy"]))      // a plant, but not these letters
        let v = WakePuzzle(variant: .missingVowels, answer: "ROSE", slots: ["R", nil, "S", nil], tiles: ["O", "E"], hint: "", intro: "")
        XCTAssertFalse(v.isCorrect("EROS", validNames: ["Rose", "Eros"]))        // must keep the given letters in place
        XCTAssertTrue(v.isCorrect("ROSE", validNames: ["Rose"]))
    }
    func testEasierPuzzleGivesTheFirstLetter() {
        let p = WakePuzzle.make(plantId: "rose", day: 3, names: names, easier: true)!
        XCTAssertEqual(p.slots.first!, p.answer.first)
    }
    func testNoPuzzleWhenThereAreNoUsableNames() {
        XCTAssertNil(WakePuzzle.make(plantId: "rose", day: 1, names: ["Fern", "Rose"]))
    }
}

final class WakePuzzleBoardTests: XCTestCase {
    let rose = WakePuzzle(variant: .anagram, answer: "ROSE", slots: [nil, nil, nil, nil], tiles: Array("SORE"), hint: "", intro: "")

    func testTappingLettersFillsTheSlotsInOrderAndASlotTapGivesItBack() {
        var b = WakePuzzleBoard(puzzle: rose)
        b.tapTile(1); b.tapTile(0)        // O, S
        XCTAssertEqual(b.letters, ["O", "S", nil, nil])
        b.tapTile(1)                       // already used: nothing happens
        XCTAssertEqual(b.letters, ["O", "S", nil, nil])
        b.tapSlot(0)
        XCTAssertEqual(b.letters, [nil, "S", nil, nil])
        XCTAssertFalse(b.isUsed(1))
        b.tapTile(2)                       // R goes into the first empty slot
        XCTAssertEqual(b.letters, ["R", "S", nil, nil])
    }
    func testAWrongWordIsFreeToRetry() {
        var b = WakePuzzleBoard(puzzle: rose)
        for i in [0, 1, 2, 3] { b.tapTile(i) }          // S O R E
        XCTAssertEqual(b.guess, "SORE")
        XCTAssertFalse(b.isSolved(validNames: ["Rose"]))
        b.clear()
        XCTAssertEqual(b.letters, [nil, nil, nil, nil])
        for i in [2, 1, 0, 3] { b.tapTile(i) }          // R O S E
        XCTAssertTrue(b.isSolved(validNames: ["Rose"]))
    }
    func testGivenLettersCannotBeRemoved() {
        let v = WakePuzzle(variant: .missingVowels, answer: "ROSE", slots: ["R", nil, "S", nil], tiles: ["E", "O"], hint: "", intro: "")
        var b = WakePuzzleBoard(puzzle: v)
        b.tapSlot(0)
        XCTAssertEqual(b.letters, ["R", nil, "S", nil])
        b.tapTile(1); b.tapTile(0)
        XCTAssertEqual(b.guess, "ROSE")
    }
    func testPeekIsFreeAfterThirtySecondsAndPlacesACorrectLetter() {
        var b = WakePuzzleBoard(puzzle: rose)
        XCTAssertFalse(b.canPeek(at: 29))
        XCTAssertFalse(b.peek(at: 29))
        b.tapTile(0)                                    // S in slot 0 (wrong)
        XCTAssertTrue(b.canPeek(at: 30))
        XCTAssertTrue(b.peek(at: 30))
        XCTAssertEqual(b.letters[0], "R")               // the first wrong or empty slot gets its right letter, locked
        b.tapSlot(0)
        XCTAssertEqual(b.letters[0], "R")
        XCTAssertFalse(b.canPeek(at: 45))               // the next peek comes another 30 s later
        XCTAssertTrue(b.canPeek(at: 60))
    }
    func testPeekNeverFinishesThePuzzleForThePlayer() {
        var b = WakePuzzleBoard(puzzle: rose)
        var t = 30.0
        while b.peek(at: t) { t += 30 }
        XCTAssertEqual(b.letters.compactMap { $0 }.count, 3)
        XCTAssertFalse(b.isSolved(validNames: ["Rose"]))
    }
}

@MainActor
final class WakeInAppTests: XCTestCase {
    func makeApp(now: @escaping () -> Date, calm: Bool = false) throws -> AppModel {
        let suite = UserDefaults(suiteName: "wf-wake-\(UUID().uuidString)")!
        let s = AppSettings(defaults: suite); s.calmMode = calm
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: try SharedContainer.make(inMemory: true), settings: s, bank: bank, now: now, notifications: ReminderTests.FakeCenter())
    }

    func testWinningAWakeChallengeWakesTheSeedAndRemembersTheChallenge() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = app.plants().first!; p.earnedCount = 1; app.love(p)
        clock = clock.addingTimeInterval(6 * 86_400)
        XCTAssertTrue(app.loveState(p).isSeed)
        XCTAssertEqual(app.wakeSuggestion, .butterflies)

        app.finishWake(p, challenge: .wordPuzzle, woke: false)
        XCTAssertTrue(app.loveState(p).isSeed)                 // still dreaming changes nothing else
        XCTAssertEqual(app.settings.lastWakeResult, .stillDreaming)
        XCTAssertEqual(app.wakeSuggestion, .butterflies)

        app.finishWake(p, challenge: .wordPuzzle, woke: true)
        XCTAssertFalse(app.loveState(p).isSeed)
        XCTAssertEqual(app.loveState(p).petalsLeft, LoveEngine.maxPetals)
        XCTAssertEqual(p.lastLovedAt, clock)
        XCTAssertEqual(app.settings.lastWakeChallenge, .wordPuzzle)
        XCTAssertEqual(app.wakeSuggestion, .wordPuzzle)
        XCTAssertEqual(app.settings.wakeDreamsInARow, 0)
    }
    func testTheWakeCountSaysFriendsBecauseEveryVisitorCounts() {
        XCTAssertEqual(WakeCopy.caughtSoFar(2, goal: 3), "2 of 3 friends")
        XCTAssertFalse(WakeCopy.butterflyIntro(goal: 3).contains("butterflies"))
    }

    /// Wake-game hellos go to the album and badges through the same path as the main game, but pay no shed points or
    /// water and never use up one of the day's rewarded plays.
    func testWakeCatchesCreditTheAlbumAndBadgesButNotPoints() throws {
        let clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = try XCTUnwrap(app.profile)
        let pointsBefore = p.shedPoints, waterBefore = p.water, soilBefore = p.soil
        var g = app.startButterflyGame(seed: 4, reduceMotion: true, wake: true)
        var caught = 0, t = 0.0
        while caught < 3 && t < 30 { g.tick(0.1); t += 0.1; if let v = g.visitors.first, g.catchAt(x: v.x, y: v.y) != nil { caught += 1 } }
        XCTAssertEqual(caught, 3)
        let summary = app.finishButterflyGame(g, wake: true)
        XCTAssertEqual(summary.shedPoints, 0); XCTAssertEqual(summary.water, 0); XCTAssertEqual(summary.scoops, 0)
        XCTAssertEqual(p.shedPoints, pointsBefore); XCTAssertEqual(p.water, waterBefore); XCTAssertEqual(p.soil, soilBefore)
        XCTAssertEqual(g.caught.reduce(0) { $0 + (app.album.count(of: $1) > 0 ? 1 : 0) }, 3)
        XCTAssertEqual(Set(g.caught).map { app.album.count(of: $0) }.reduce(0, +), 3)
        XCTAssertEqual(app.badges.progress(of: .visitorSpecies), Set(g.caught).count)
        XCTAssertEqual(app.butterflyPlaysToday, 0, "a wake game never uses a rewarded play")
        XCTAssertEqual(Set(summary.newFriendIds), Set(g.caught), "first hellos are new friends")
    }

    func testCalmModeGivesTheGentleGameButNeverInTheWakeGame() throws {
        let clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }, calm: true)
        XCTAssertTrue(app.startButterflyGame().calm)
        XCTAssertFalse(app.startButterflyGame(wake: true).calm)
        app.settings.calmMode = false
        XCTAssertFalse(app.startButterflyGame().calm)
    }

    func testTwoDreamsInARowMakeTheNextTryEasier() throws {
        let clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = app.plants().first!
        XCTAssertFalse(app.wakeIsEasier)
        app.finishWake(p, challenge: .butterflies, woke: false)
        app.finishWake(p, challenge: .butterflies, woke: false)
        XCTAssertTrue(app.wakeIsEasier)
        XCTAssertEqual(app.wakeButterflyGoal, 2)
    }
    func testWakeSettingsPersist() throws {
        let suite = UserDefaults(suiteName: "wf-wake-persist-\(UUID().uuidString)")!
        let s = AppSettings(defaults: suite)
        s.lastWakeChallenge = .wordPuzzle; s.lastWakeResult = .woke; s.wakeDreamsInARow = 1
        let again = AppSettings(defaults: suite)
        XCTAssertEqual(again.lastWakeChallenge, .wordPuzzle); XCTAssertEqual(again.lastWakeResult, .woke); XCTAssertEqual(again.wakeDreamsInARow, 1)
    }
    func testTheAppGivesAPuzzleForASeed() throws {
        let clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = app.plants().first { $0.plantId == "daisy" }!
        let puzzle = try XCTUnwrap(app.wakePuzzle(for: p))
        XCTAssertEqual(app.wakePuzzle(for: p), puzzle)
        XCTAssertNotEqual(puzzle.answer, "DAISY")
        var b = WakePuzzleBoard(puzzle: puzzle)
        for ch in puzzle.answer.enumerated() where puzzle.slots[ch.offset] == nil {
            let idx = puzzle.tiles.indices.first { puzzle.tiles[$0] == ch.element && !b.isUsed($0) }!
            b.tapTile(idx)
        }
        XCTAssertTrue(b.isSolved(validNames: app.plants().map(\.name)))
    }
    func testCalmModeNeverMakesASeed() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }, calm: true)
        let p = app.plants().first!; p.earnedCount = 1; app.love(p)
        clock = clock.addingTimeInterval(30 * 86_400)
        XCTAssertFalse(app.loveState(p).isSeed)
        XCTAssertFalse(app.showsWakeCard(p))
    }
    func testASeedShowsTheWakeCard() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = app.plants().first!; p.earnedCount = 1; app.love(p)
        XCTAssertFalse(app.showsWakeCard(p))
        clock = clock.addingTimeInterval(6 * 86_400)
        XCTAssertTrue(app.showsWakeCard(p))
    }
}

final class PetalReturnTests: XCTestCase {
    func testPetalsReturnAThirdOfASecondApartWithinTheCap() {
        let d = PetalReturn.delays(count: 5, reduceMotion: false)
        XCTAssertEqual(d, [0, 0.3, 0.6, 0.9, 1.2].map { $0 }, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(PetalReturn.delays(count: 20, reduceMotion: false).last!, PetalReturn.maxTotal)
    }
    func testReduceMotionShowsThemAllAtOnce() {
        XCTAssertEqual(PetalReturn.delays(count: 5, reduceMotion: true), [0, 0, 0, 0, 0])
    }
}

private func XCTAssertEqual(_ a: [Double], _ b: [Double], accuracy: Double, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(a.count, b.count, file: file, line: line)
    for (x, y) in zip(a, b) { XCTAssertEqual(x, y, accuracy: accuracy, file: file, line: line) }
}

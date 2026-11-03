import XCTest
@testable import WordFlora

final class CoreRulesTests: XCTestCase {
    let eco = Economy.default

    // MARK: RoseMeter
    func testRoseArrivesAfterEightCompletedRounds() {
        var m = RoseMeter()
        for i in 1...7 { XCTAssertFalse(m.recordRound(id: "r\(i)", economy: eco)) }
        XCTAssertTrue(m.recordRound(id: "r8", economy: eco))
        XCTAssertEqual(m.stock, 1)
        XCTAssertEqual(m.progress, 0)
    }

    func testRoseMeterIsIdempotentPerRoundId() {
        var m = RoseMeter()
        _ = m.recordRound(id: "r1", economy: eco)
        _ = m.recordRound(id: "r1", economy: eco)
        XCTAssertEqual(m.progress, 1)
    }

    func testRoseMeterPausesAtCap() {
        var m = RoseMeter(progress: 3, stock: 3, lastRoundId: nil)
        XCTAssertFalse(m.recordRound(id: "x", economy: eco))
        XCTAssertEqual(m.progress, 3)
        XCTAssertEqual(m.stock, 3)
        XCTAssertTrue(m.isFull)
    }

    func testMilestoneGrantRespectsCapAndConsumeWorks() {
        var m = RoseMeter(progress: 0, stock: 2, lastRoundId: nil)
        m.grant(economy: eco); m.grant(economy: eco)
        XCTAssertEqual(m.stock, 3)
        XCTAssertTrue(m.consume())
        XCTAssertEqual(m.stock, 2)
        var empty = RoseMeter()
        XCTAssertFalse(empty.consume())
    }

    // MARK: StreakEngine
    private var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func day(_ n: Int, cal: Calendar? = nil) -> Date {
        let c = cal ?? utc
        return c.date(byAdding: .day, value: n, to: c.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 12))!)!
    }

    func testFirstPlayStartsGardenDaysAndStreak() {
        var s = StreakState()
        _ = s.recordPlay(on: day(0), calendar: utc, economy: eco)
        XCTAssertEqual(s.gardenDays, 1); XCTAssertEqual(s.streak, 1)
    }

    func testSecondPlaySameDayChangesNothing() {
        var s = StreakState()
        _ = s.recordPlay(on: day(0), calendar: utc, economy: eco)
        _ = s.recordPlay(on: day(0).addingTimeInterval(3600), calendar: utc, economy: eco)
        XCTAssertEqual(s.gardenDays, 1); XCTAssertEqual(s.streak, 1)
    }

    func testConsecutiveDaysGrowStreak() {
        var s = StreakState()
        for i in 0..<4 { _ = s.recordPlay(on: day(i), calendar: utc, economy: eco) }
        XCTAssertEqual(s.streak, 4); XCTAssertEqual(s.gardenDays, 4)
    }

    func testOneMissedDayUsesGraceBeforeFreeze() {
        var s = StreakState(); s.freezes = 1
        _ = s.recordPlay(on: day(0), calendar: utc, economy: eco)
        let e = s.recordPlay(on: day(2), calendar: utc, economy: eco)
        XCTAssertTrue(e.usedGrace); XCTAssertFalse(e.usedFreeze)
        XCTAssertEqual(s.streak, 2); XCTAssertEqual(s.freezes, 1)
    }

    func testSecondMissedDayWithinWindowUsesFreeze() {
        var s = StreakState(); s.freezes = 1
        _ = s.recordPlay(on: day(0), calendar: utc, economy: eco)
        _ = s.recordPlay(on: day(2), calendar: utc, economy: eco)   // grace
        let e = s.recordPlay(on: day(4), calendar: utc, economy: eco) // freeze
        XCTAssertTrue(e.usedFreeze)
        XCTAssertEqual(s.freezes, 0); XCTAssertEqual(s.streak, 3)
    }

    func testGapWithoutCoverRestsStreakButKeepsGardenDaysAndBest() {
        var s = StreakState()
        for i in 0..<3 { _ = s.recordPlay(on: day(i), calendar: utc, economy: eco) }
        _ = s.recordPlay(on: day(10), calendar: utc, economy: eco)
        XCTAssertEqual(s.streak, 1)
        XCTAssertEqual(s.bestStreak, 3)
        XCTAssertEqual(s.gardenDays, 4)
    }

    func testFreezeEarnedAtFiveAndFourteenAndCapped() {
        var s = StreakState()
        for i in 0..<5 { _ = s.recordPlay(on: day(i), calendar: utc, economy: eco) }
        XCTAssertEqual(s.freezes, 1)
        for i in 5..<14 { _ = s.recordPlay(on: day(i), calendar: utc, economy: eco) }
        XCTAssertEqual(s.freezes, 2)
        for i in 14..<28 { _ = s.recordPlay(on: day(i), calendar: utc, economy: eco) }
        XCTAssertEqual(s.freezes, 2) // cap
    }

    func testRoseMilestonesAtSevenThirtyAndHundred() {
        var s = StreakState(); var milestones = [Int]()
        for i in 0..<100 {
            let e = s.recordPlay(on: day(i), calendar: utc, economy: eco)
            if e.milestoneRose { milestones.append(s.streak) }
        }
        XCTAssertEqual(milestones, [7, 30, 100])
    }

    func testStreakAdvancesAcrossDSTBoundary() {
        var ny = Calendar(identifier: .gregorian); ny.timeZone = TimeZone(identifier: "America/New_York")!
        var s = StreakState()
        for i in 0..<4 { _ = s.recordPlay(on: day(i + 5, cal: ny), calendar: ny, economy: eco) } // Mar 6-9 (spring forward Mar 8)
        XCTAssertEqual(s.streak, 4)
    }

    // MARK: ProgressionPolicy
    private func plants(earned: Int, stage: Int, level: Int = 1) -> [PlantProgress] {
        (0..<10).map { PlantProgress(level: level, earned: $0 < earned, stage: stage) }
    }

    func testTenUniquePlantsAdvanceWordLevelEvenAtStageZero() {
        let p = plants(earned: 10, stage: 0)
        XCTAssertEqual(ProgressionPolicy.wordLevel(plants: p, economy: eco), 2)
    }

    func testNineUniquePlantsDoNotAdvance() {
        XCTAssertEqual(ProgressionPolicy.wordLevel(plants: plants(earned: 9, stage: 4), economy: eco), 1)
    }

    func testWordLevelCapsAtFive() {
        let all = (1...5).flatMap { plants(earned: 10, stage: 4, level: $0) }
        XCTAssertEqual(ProgressionPolicy.wordLevel(plants: all, economy: eco), 5)
    }

    func testGardenLevelCompleteNeedsAllTenAtStageFour() {
        XCTAssertTrue(ProgressionPolicy.gardenLevelComplete(1, plants: plants(earned: 10, stage: 4)))
        XCTAssertFalse(ProgressionPolicy.gardenLevelComplete(1, plants: plants(earned: 10, stage: 3)))
        XCTAssertFalse(ProgressionPolicy.gardenLevelComplete(1, plants: plants(earned: 9, stage: 4)))
    }

    func testSelectableLevelsAreUpToWordLevel() {
        XCTAssertEqual(ProgressionPolicy.selectableLevels(wordLevel: 3), [1, 2, 3])
    }

    // MARK: HelpLadder
    func testLadderOrderHintVowelFirstLetter() {
        let word = "SUNFLOWER"
        XCTAssertEqual(HelpLadder.next(used: [], word: word, guessed: [], hint2: "second clue"), .hint2("second clue"))
        if case .reveal(let ch)? = HelpLadder.next(used: [.hint2], word: word, guessed: [], hint2: "x") {
            XCTAssertTrue("AEIOU".contains(ch))
        } else { XCTFail("expected vowel reveal") }
        XCTAssertEqual(HelpLadder.next(used: [.hint2, .vowel], word: word, guessed: [], hint2: "x"), .reveal("S"))
    }

    func testLadderSkipsMissingHint2() {
        guard case .reveal? = HelpLadder.next(used: [], word: "ROSE", guessed: [], hint2: nil) else {
            return XCTFail("expected a reveal when there is no hint2")
        }
    }

    func testVowelRevealPicksMostFrequentUnrevealedVowel() {
        XCTAssertEqual(HelpLadder.next(used: [.hint2], word: "EVERGREEN", guessed: [], hint2: "x"), .reveal("E"))
    }

    func testLadderFallsThroughToFirstLetterWhenNoVowelIsLeft() {
        XCTAssertEqual(HelpLadder.next(used: [.hint2], word: "BANANA", guessed: ["A"], hint2: "x"), .reveal("B"))
    }

    func testLadderNeverRevealsTheLastUnrevealedLetter() {
        XCTAssertNil(HelpLadder.next(used: [], word: "ROSE", guessed: ["R", "O", "S"], hint2: nil))
        XCTAssertNil(HelpLadder.next(used: [], word: "ROSE", guessed: ["R", "S", "E"], hint2: nil))
    }

    func testLadderEndsAfterAllRungsUsed() {
        XCTAssertNil(HelpLadder.next(used: [.hint2, .vowel, .firstLetter], word: "SUNFLOWER", guessed: [], hint2: "x"))
    }

    // MARK: WordDifficulty
    func testDifficultyOrdersRareLetterWordsAboveCommonOnes() {
        XCTAssertGreaterThan(WordDifficulty.expectedMisses("JAZZ"), WordDifficulty.expectedMisses("TOMATO"))
        XCTAssertGreaterThan(WordDifficulty.expectedMisses("TOMATO"), WordDifficulty.expectedMisses("TEE"))
    }

    func testDifficultyGoldenValues() {
        XCTAssertEqual(WordDifficulty.expectedMisses("TEE"), 0)
        XCTAssertEqual(WordDifficulty.expectedMisses("JAZZ"), 23)
        XCTAssertEqual(WordDifficulty.expectedMisses("TOMATO"), 10)
    }

    func testDifficultyIgnoresSpacesAndIsDeterministic() {
        XCTAssertEqual(WordDifficulty.expectedMisses("VENUS FLYTRAP"), WordDifficulty.expectedMisses("VENUSFLYTRAP"))
    }

    // MARK: CopySafety
    func testCopySafetyFlagsBannedWordsCaseInsensitively() {
        for bad in ["Your plant is dying", "Streak broken", "The flower is Dead", "You LOST", "Hurry, last chance", "Don't forget", "You're so smart", "Only 3 left", "I miss you", "Better than your friends"] {
            XCTAssertFalse(CopySafety.check(bad).isEmpty, bad)
        }
    }

    func testCopySafetyAllowsFriendlyCopy() {
        for good in ["This one's resting. Here's the word: CACTUS.", "Nice thinking!", "Your fern perks right up with a drink.", "Streak resting - your best was 12", "Blast of colour", "Lastly, enjoy"] {
            XCTAssertEqual(CopySafety.check(good), [], good)
        }
    }

    // MARK: shipped content passes the copy linter
    func testShippedPlantFactsPassCopySafety() throws {
        for p in try PlantCatalog.load() { XCTAssertEqual(CopySafety.check(p.botanicalFact), [], "\(p.name): \(p.botanicalFact)") }
    }

    func testShippedWordBankTextPassesCopySafety() throws {
        for e in try WordBank.load().entries {
            for text in [e.hint, e.hint2, e.fact].compactMap({ $0 }) {
                XCTAssertEqual(CopySafety.check(text), [], "\(e.id): \(text)")
            }
        }
    }

    func testVisitorFactsPassCopySafety() {
        for v in VisitorCatalog.all { if let f = v.fact { XCTAssertEqual(CopySafety.check(f), [], "\(v.id): \(f)") } }
    }

    // MARK: under-13 break suggestion (spec section 18, P12)
    func testBreakIsSuggestedAfterTwentyMinutesForYoungPlayersOnly() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        XCTAssertFalse(BreakPolicy.shouldSuggest(isUnderThirteen: true, sittingStart: start, now: start.addingTimeInterval(19 * 60), lastSuggestedAt: nil))
        XCTAssertTrue(BreakPolicy.shouldSuggest(isUnderThirteen: true, sittingStart: start, now: start.addingTimeInterval(20 * 60), lastSuggestedAt: nil))
        XCTAssertFalse(BreakPolicy.shouldSuggest(isUnderThirteen: false, sittingStart: start, now: start.addingTimeInterval(60 * 60), lastSuggestedAt: nil))
    }

    func testBreakSuggestionsAreSpacedAndNeverNag() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let first = start.addingTimeInterval(20 * 60)
        XCTAssertFalse(BreakPolicy.shouldSuggest(isUnderThirteen: true, sittingStart: start, now: first.addingTimeInterval(5 * 60), lastSuggestedAt: first))
        XCTAssertTrue(BreakPolicy.shouldSuggest(isUnderThirteen: true, sittingStart: start, now: first.addingTimeInterval(20 * 60), lastSuggestedAt: first))
    }

    func testBreakCopyIsKindAndPassesTheLinter() {
        XCTAssertEqual(CopySafety.check(BreakPolicy.message), [])
        XCTAssertTrue(BreakPolicy.message.lowercased().contains("window") || BreakPolicy.message.lowercased().contains("sky"))
    }
}


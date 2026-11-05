import XCTest
import SwiftData
@testable import WordFlora

// The endgame rules (docs/pm/endgame-and-events-spec.md section 2; test plan items 10 and 11).

final class EndgameTests: XCTestCase {
    let eco = Economy.default

    func garden(found: Int = 50, stage: Int = 4) -> [PlantProgress] {
        (0..<50).map { i in PlantProgress(level: i / 10 + 1, earned: i < found, stage: i < found ? stage : 0) }
    }

    func testAllFoundReadsEarnedPlantsNotStages() {
        XCTAssertTrue(EndgamePolicy.allFound(garden(found: 50, stage: 0)), "found is found, at any stage")
        XCTAssertFalse(EndgamePolicy.allFound(garden(found: 49)))
        XCTAssertFalse(EndgamePolicy.allFound([]))
        XCTAssertFalse(EndgamePolicy.allFound(Array(garden().prefix(10))), "a part of the catalog is not every plant")
    }

    func testAllFullBloomNeedsEveryLevelGrownOnTheEarnedStage() {
        XCTAssertTrue(EndgamePolicy.allFullBloom(garden()))
        XCTAssertFalse(EndgamePolicy.allFullBloom(garden(stage: 3)))
        var g = garden(); g[17].stage = 3
        XCTAssertFalse(EndgamePolicy.allFullBloom(g))
        XCTAssertEqual(EndgamePolicy.allFullBloom(g), (1...5).allSatisfy { ProgressionPolicy.gardenLevelComplete($0, plants: g) })
    }

    func testTheCeremonyAndTheGoldCrownShowOnce() {
        XCTAssertTrue(EndgamePolicy.shouldShowCeremony(allFound: true, seenAt: nil))
        XCTAssertFalse(EndgamePolicy.shouldShowCeremony(allFound: true, seenAt: .now))
        XCTAssertFalse(EndgamePolicy.shouldShowCeremony(allFound: false, seenAt: nil))
        XCTAssertTrue(EndgamePolicy.shouldShowGoldCrown(allFullBloom: true, seenAt: nil))
        XCTAssertFalse(EndgamePolicy.shouldShowGoldCrown(allFullBloom: true, seenAt: .now))
        XCTAssertFalse(EndgamePolicy.shouldShowGoldCrown(allFullBloom: false, seenAt: nil))
    }

    func testGoldenDaysAddAtMostOneADay() {
        var state = (days: 0, key: 0)
        for (care, expected) in [(100, 1), (100, 1), (101, 2), (101, 2), (99, 2), (105, 3)] {
            state = EndgamePolicy.goldenDays(current: state.days, lastKey: state.key, careKey: care)
            XCTAssertEqual(state.days, expected, "care on \(care)")
        }
        XCTAssertEqual(state.key, 105)
        XCTAssertEqual(EndgamePolicy.goldenDays(current: 3, lastKey: 105, careKey: 104).key, 105, "a clock moved back counts nothing")
    }

    func testAPlantTurnsGoldenOnItsSeventhDay() {
        var days = 0, key = 0
        for d in [10, 12, 13, 20, 21, 30] {
            (days, key) = EndgamePolicy.goldenDays(current: days, lastKey: key, careKey: d)
            XCTAssertFalse(EndgamePolicy.isGolden(days: days, economy: eco))
        }
        XCTAssertEqual(EndgamePolicy.daysToGolden(days: days, economy: eco), 1)
        (days, key) = EndgamePolicy.goldenDays(current: days, lastKey: key, careKey: 31)
        XCTAssertTrue(EndgamePolicy.isGolden(days: days, economy: eco))
        XCTAssertEqual(EndgamePolicy.daysToGolden(days: days, economy: eco), 0)
        XCTAssertEqual(eco.goldenDaysNeeded, 7)
    }

    func testOnlyTendingAFullBloomPlantInAFinishedGardenCounts() {
        XCTAssertTrue(EndgamePolicy.countsTowardGolden(allFound: true, stage: 4, isTending: true))
        XCTAssertFalse(EndgamePolicy.countsTowardGolden(allFound: true, stage: 4, isTending: false), "a hello does not count")
        XCTAssertFalse(EndgamePolicy.countsTowardGolden(allFound: true, stage: 3, isTending: true))
        XCTAssertFalse(EndgamePolicy.countsTowardGolden(allFound: false, stage: 4, isTending: true))
    }

    func testBloomRanksFollowTheThresholds() {
        XCTAssertEqual(eco.bloomRankThresholds, [1, 10, 30, 75, 150, 300])
        let expect: [(Int, BloomRank)] = [(0, .unranked), (1, .seedling), (9, .seedling), (10, .sprout), (29, .sprout), (30, .bud),
                                          (75, .bloom), (149, .bloom), (150, .fullBloom), (299, .fullBloom), (300, .evergreen), (5_000, .evergreen)]
        for (n, rank) in expect { XCTAssertEqual(EndgamePolicy.bloomRank(dailyBloomsDone: n), rank, "\(n)") }
        XCTAssertEqual(BloomRank.allCases.dropFirst().map(\.name), ["Seedling", "Sprout", "Bud", "Bloom", "Full bloom", "Evergreen"])
        XCTAssertEqual(EndgamePolicy.bloomsToNextRank(dailyBloomsDone: 12), 18)
        XCTAssertNil(EndgamePolicy.bloomsToNextRank(dailyBloomsDone: 300))
        XCTAssertEqual(EndgamePolicy.bloomsToNextRank(dailyBloomsDone: 0), 1)
    }

    func testTheEconomyKeepsItsExistingValues() {
        // Weather and the endgame only add numbers; these pins guard the neighbours they were added next to.
        XCTAssertEqual(eco.stageThresholds, [0.06, 0.22, 0.50, 1.0]); XCTAssertEqual(eco.levelBaseCost, 200)
        XCTAssertEqual(eco.levelCostMultipliers, [1.0, 1.1, 1.2, 1.3, 1.4]); XCTAssertEqual(eco.waterBankCap, 40)
        XCTAssertEqual(eco.plantsPerLevel, 10); XCTAssertEqual(eco.maxPetals, 8); XCTAssertEqual(eco.wordsPerPlant, 3)
        XCTAssertEqual(eco.trickleCap, 5); XCTAssertEqual(eco.thirstyHours, 48)
        XCTAssertEqual(eco.weatherFirstWeekDays, 7); XCTAssertEqual(eco.weatherBlockDays, 14); XCTAssertEqual(eco.weatherEventWindow, 7)
        XCTAssertEqual(eco.weatherBlockChance, 0.75); XCTAssertEqual(eco.weatherBagBig, 3); XCTAssertEqual(eco.weatherBagGentle, 7)
        XCTAssertEqual(eco.weatherAffectedCap, 0.4); XCTAssertEqual(eco.weatherLingerDays, 3); XCTAssertEqual(eco.weatherMinPlants, 5)
        XCTAssertEqual(eco.weatherMinTends, 2); XCTAssertEqual(eco.weatherPuzzlesPerDay, 3); XCTAssertEqual(eco.weatherPuzzleDays, 4)
        XCTAssertEqual(eco.calmLingerDays, 1); XCTAssertEqual(eco.weatherAwardGardenDays, 7); XCTAssertEqual(eco.weatherClockSlackDays, 1)
        XCTAssertEqual(eco.weatherPuzzleWords, 1); XCTAssertEqual(eco.weatherAlgoVersion, 1); XCTAssertEqual(eco.weatherAlgoCutoverDay, 0)
        XCTAssertEqual(eco.wildMaxPlants, 4); XCTAssertEqual(eco.wildMaxPlantsSheltered, 2); XCTAssertEqual(eco.wildLingerDays, 4)
        XCTAssertEqual(eco.wildSetback, 1); XCTAssertEqual(eco.stormMinLetters, 7); XCTAssertEqual(eco.stormMaxLetters, 14)
        XCTAssertEqual(eco.stormDecoys, 1)
    }
}

@MainActor
final class EndgameStoreTests: XCTestCase {
    func testTheCrownIsComputedFromTheStoreAndGoldenDaysStartAtZero() throws {
        let container = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: container.mainContext)
        let plants = try container.mainContext.fetch(FetchDescriptor<PlantCollectible>())
        func progress() -> [PlantProgress] { plants.map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) } }
        XCTAssertFalse(EndgamePolicy.allFound(progress()))
        for p in plants { p.earnedCount = 1 }
        XCTAssertTrue(EndgamePolicy.allFound(progress()))
        XCTAssertFalse(EndgamePolicy.allFullBloom(progress()))
        for p in plants { p.stage = 4 }
        XCTAssertTrue(EndgamePolicy.allFullBloom(progress()))
        XCTAssertTrue(plants.allSatisfy { $0.goldenDays == 0 && !EndgamePolicy.isGolden(days: $0.goldenDays) })
    }
}

final class EndgameCopyTests: XCTestCase {
    func testEveryEndgameLineIsSafeAndGentle() {
        for name in ["Daisy", "Venus Flytrap"] {
            let lines = EndgameCopy.all(name: name)
            XCTAssertGreaterThan(lines.count, 12)
            for line in lines {
                XCTAssertFalse(line.isEmpty)
                XCTAssertEqual(CopySafety.check(line), [], line)
                XCTAssertEqual(WeatherCopyTests.avoided(line), [], line)
                XCTAssertLessThanOrEqual(line.count, 90, line)
            }
        }
        for rank in BloomRank.allCases.dropFirst() { XCTAssertTrue(EndgameCopy.all(name: "Daisy").contains(rank.name)) }
    }

    func testEndgameLinesReadAtAboutGradeThree() {
        let sentences = EndgameCopy.all(name: "Daisy").filter { $0.hasSuffix(".") || $0.hasSuffix("!") }
        XCTAssertGreaterThan(sentences.count, 6)
        let grade = ReadingLevel.grade(sentences.joined(separator: " "))
        XCTAssertLessThanOrEqual(grade, 3.9, "endgame copy reads at grade \(grade)")
    }

    func testDaysFromGoldenReadsNaturally() {
        XCTAssertEqual(EndgameCopy.daysFromGolden(name: "Daisy", days: 3), "Daisy is 3 days from golden.")
        XCTAssertEqual(EndgameCopy.daysFromGolden(name: "Daisy", days: 1), "Daisy is 1 day from golden.")
    }
}

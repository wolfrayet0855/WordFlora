import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class GameViewModelTests: XCTestCase {
    var container: ModelContainer!
    var now = Date(timeIntervalSince1970: 1_780_000_000)
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    // MARK: fixtures
    func entry(_ id: String, _ word: String, level: Int = 1, kind: WordEntry.Kind = .vocab,
               plantId: String? = nil, hint2: String? = nil) -> WordEntry {
        WordEntry(id: id, word: word, display: word.capitalized, hint: "a hint", hint2: hint2, fact: "a fact",
                  level: level, kind: kind, plantId: plantId, tags: [], minAge: 6,
                  dailyEligible: true, source: "original", license: "proprietary", reviewedBy: "t")
    }
    func bank(_ entries: [WordEntry]) -> WordBank {
        WordBank(schemaVersion: 1, bankVersion: "t", entries: entries, daily: DailyConfig(epoch: "2026-01-01", seed: 9))
    }
    func makeVM(_ entries: [WordEntry]? = nil) throws -> GameViewModel {
        let vm = GameViewModel(modelContext: container.mainContext,
                               bank: bank(entries ?? [entry("a", "LOTUS"), entry("b", "SEED"), entry("c", "LEAF")]),
                               now: { [unowned self] in self.now }, calendar: cal, seed: 1)
        vm.soundEnabled = false
        vm.seedPlantsIfNeeded()
        return vm
    }
    func guess(_ vm: GameViewModel, _ letters: String) {
        for ch in letters { vm.guessInput = String(ch); vm.submitGuess() }
    }
    func plants() throws -> [PlantCollectible] { try container.mainContext.fetch(FetchDescriptor<PlantCollectible>()) }

    override func setUp() async throws {
        container = try ModelContainer(
            for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }

    // MARK: basics
    func testInitialPetalsEight() throws { XCTAssertEqual(try makeVM().petalsRemaining, 8) }

    func testWrongGuessDecrementsAndCorrectKeeps() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS"))
        guess(vm, "Z"); XCTAssertEqual(vm.petalsRemaining, 7)
        guess(vm, "L"); XCTAssertEqual(vm.petalsRemaining, 7)
    }

    func testDuplicateAndNonLetterGuessesIgnored() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS"))
        guess(vm, "ZZ7!"); XCTAssertEqual(vm.petalsRemaining, 7)
    }

    func testSpacesArePrerevealedAndNotGuessable() throws {
        let vm = try makeVM()
        vm.start(entry: entry("v", "VENUS FLYTRAP", level: 3, kind: .hero, plantId: "venus_flytrap"))
        guess(vm, "VENUSFLYTRAP")
        XCTAssertEqual(vm.phase, .won)
    }

    func testPetalAccessibilityLabel() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS")); guess(vm, "Z")
        XCTAssertEqual(vm.petalsAccessibilityLabel, "7 of 8 petals left")
    }

    // MARK: win and awards
    func testWinAwardsAnUnownedPlantOfTheLevelAndWater() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS"))
        guess(vm, "LOTUS")
        XCTAssertEqual(vm.phase, .won)
        let owned = try plants().filter { $0.earnedCount > 0 }
        XCTAssertEqual(owned.count, 1)
        XCTAssertEqual(owned.first?.level, 1)
        XCTAssertTrue(vm.earnedPlantIsNew)
        XCTAssertGreaterThanOrEqual(vm.playerProfile?.water ?? 0, 1)
    }

    func testHeroEntryAwardsItsOwnPlant() throws {
        let vm = try makeVM(); vm.start(entry: entry("r", "ROSE", kind: .hero, plantId: "rose"))
        guess(vm, "ROSE")
        XCTAssertEqual(vm.earnedPlantName, "Rose")
        XCTAssertEqual(try plants().first { $0.plantId == "rose" }?.earnedCount, 1)
    }

    func testHeroForAlreadyOwnedPlantFallsBackToAnotherUnowned() throws {
        let vm = try makeVM()
        try plants().first { $0.plantId == "rose" }?.earnedCount = 1
        vm.start(entry: entry("r", "ROSE", kind: .hero, plantId: "rose")); guess(vm, "ROSE")
        XCTAssertNotEqual(vm.earnedPlantName, "Rose")
        XCTAssertTrue(vm.earnedPlantIsNew)
    }

    func testDuplicatesOnlyWhenLevelSetIsComplete() throws {
        let vm = try makeVM()
        for p in try plants() where p.level == 1 { p.earnedCount = 1 }
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "LOTUS")
        XCTAssertFalse(vm.earnedPlantIsNew)
        XCTAssertEqual(try plants().filter { $0.level == 1 }.map(\.earnedCount).reduce(0, +), 11)
    }

    func testTenthUniquePlantAdvancesWordLevel() throws {
        let vm = try makeVM()
        let l1 = try plants().filter { $0.level == 1 }
        for p in l1.prefix(9) { p.earnedCount = 1 }
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "LOTUS")
        XCTAssertEqual(vm.playerProfile?.currentLevel, 2)
        XCTAssertTrue(vm.leveledUp)
    }

    func testNinthUniquePlantDoesNotAdvance() throws {
        let vm = try makeVM()
        for p in try plants().filter({ $0.level == 1 }).prefix(8) { p.earnedCount = 1 }
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "LOTUS")
        XCTAssertEqual(vm.playerProfile?.currentLevel, 1)
        XCTAssertFalse(vm.leveledUp)
    }

    // MARK: resting (loss)
    func testZeroPetalsWithoutRoseRestsAndRevealsAnswer() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS"))
        guess(vm, "ABCDEFGH")
        XCTAssertEqual(vm.phase, .rested)
        XCTAssertEqual(vm.revealedAnswer, "LOTUS")
        XCTAssertEqual(vm.playerProfile?.water, 0)
        let records = try container.mainContext.fetch(FetchDescriptor<GameRecord>())
        XCTAssertEqual(records.count, 1); XCTAssertFalse(records[0].won)
    }

    func testRoseIsOfferedBeforeTheRevealAndWakesWithFourPetals() throws {
        let vm = try makeVM(); vm.playerProfile?.roseOfJerichoCount = 1
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "ABCDEFGH")
        XCTAssertEqual(vm.phase, .restingOffer)
        XCTAssertNil(vm.revealedAnswer)
        vm.wakeUp()
        XCTAssertEqual(vm.phase, .playing)
        XCTAssertEqual(vm.petalsRemaining, 4)
        XCTAssertEqual(vm.playerProfile?.roseOfJerichoCount, 0)
    }

    func testOnlyOneReviveAllowedPerRound() throws {
        let vm = try makeVM(); vm.playerProfile?.roseOfJerichoCount = 2
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "ABCDEFGH"); vm.wakeUp()
        guess(vm, "IJKM")  // four more misses
        XCTAssertEqual(vm.phase, .rested)
        XCTAssertEqual(vm.playerProfile?.roseOfJerichoCount, 1)
    }

    func testDecliningTheRoseFinishesTheRound() throws {
        let vm = try makeVM(); vm.playerProfile?.roseOfJerichoCount = 1
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "ABCDEFGH"); vm.declineWake()
        XCTAssertEqual(vm.phase, .rested); XCTAssertEqual(vm.revealedAnswer, "LOTUS")
        XCTAssertEqual(vm.playerProfile?.roseOfJerichoCount, 1)
    }

    func testWakeUpNoOpWhenNotOffered() throws {
        let vm = try makeVM(); vm.playerProfile?.roseOfJerichoCount = 1
        vm.start(entry: entry("a", "LOTUS")); vm.wakeUp()
        XCTAssertEqual(vm.playerProfile?.roseOfJerichoCount, 1)
    }

    // MARK: rose meter, streak, ads counter, session beat
    func testRoseArrivesAfterEightCompletedRoundsWinOrLose() throws {
        let vm = try makeVM()
        for i in 0..<8 {
            vm.start(entry: entry("e\(i)", "LOTUS"))
            if i % 2 == 0 { guess(vm, "LOTUS") } else { guess(vm, "ABCDEFGH") }
        }
        XCTAssertEqual(vm.playerProfile?.roseOfJerichoCount, 1)
        XCTAssertTrue(vm.roseDropped || vm.playerProfile?.roseSeedProgress == 0)
    }

    func testRoundCountersAndGardenDays() throws {
        let vm = try makeVM()
        vm.start(entry: entry("a", "LOTUS")); guess(vm, "LOTUS")
        XCTAssertEqual(vm.playerProfile?.roundsSinceAd, 1)
        XCTAssertEqual(vm.playerProfile?.gamesPlayed, 1)
        XCTAssertEqual(vm.playerProfile?.gardenDays, 1)
        now = cal.date(byAdding: .day, value: 1, to: now)!
        vm.start(entry: entry("b", "SEED")); guess(vm, "SEED")
        XCTAssertEqual(vm.playerProfile?.gardenDays, 2)
        XCTAssertEqual(vm.playerProfile?.streak, 2)
    }

    func testSessionBeatAfterEveryThirdRegularRound() throws {
        let vm = try makeVM(); var beats = [Bool]()
        for i in 0..<6 { vm.start(entry: entry("e\(i)", "LOTUS")); guess(vm, "LOTUS"); beats.append(vm.sessionBeat) }
        XCTAssertEqual(beats, [false, false, true, false, false, true])
    }

    func testSeenIdsRecordedAndRoundsStartedFromProvider() throws {
        let vm = try makeVM()
        vm.startRound()
        let first = vm.currentEntry?.id
        XCTAssertNotNil(first)
        guess(vm, "ZXQJKVWY")   // letters in none of the fixture words, so the round really ends
        XCTAssertEqual(vm.phase, .rested)
        XCTAssertTrue(vm.playerProfile?.seenIds.contains(first!) ?? false)
        vm.startRound()
        XCTAssertNotEqual(vm.currentEntry?.id, first)
    }

    // MARK: help
    func testHelpLadderRevealsWithoutSolvingTheWord() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS", hint2: "second clue"))
        vm.useHelp(); XCTAssertEqual(vm.extraHint, "second clue"); XCTAssertEqual(vm.helpersUsed, 1)
        vm.useHelp(); vm.useHelp(); vm.useHelp()
        XCTAssertNotEqual(vm.phase, .won)
        XCTAssertTrue(vm.guessedLetters.count < Set("LOTUS").count)
    }

    func testHelpDoesNotCostPetals() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS")); vm.useHelp(); vm.useHelp()
        XCTAssertEqual(vm.petalsRemaining, 8)
    }

    func testWinAfterHelpStillPaysAtLeastOneWater() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS")); vm.useHelp(); vm.useHelp(); vm.useHelp()
        guess(vm, "LOTUS")
        XCTAssertEqual(vm.phase, .won)
        XCTAssertGreaterThanOrEqual(vm.playerProfile?.water ?? 0, 1)
    }

    // MARK: daily
    func testDailyRoundUsesDailyBloomAndDoesNotCountForAdCadence() throws {
        let vm = try makeVM()
        vm.startDaily()
        XCTAssertTrue(vm.isDaily)
        let expected = DailyBloom(bank: bank([entry("a", "LOTUS"), entry("b", "SEED"), entry("c", "LEAF")]), calendar: cal).wordId(for: now)
        XCTAssertEqual(vm.currentEntry?.id, expected)
        guess(vm, vm.currentEntry!.word.filter { $0.isLetter }.description)
        XCTAssertEqual(vm.phase, .won)
        XCTAssertEqual(vm.playerProfile?.roundsSinceAd, 0)
        let rec = try container.mainContext.fetch(FetchDescriptor<GameRecord>()).first
        XCTAssertEqual(rec?.isDaily, true)
    }
}

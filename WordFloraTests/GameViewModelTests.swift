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
    func makeVM(_ entries: [WordEntry]? = nil, economy: Economy = .default) throws -> GameViewModel {
        let vm = GameViewModel(modelContext: container.mainContext,
                               bank: bank(entries ?? [entry("a", "LOTUS"), entry("b", "SEED"), entry("c", "LEAF")]),
                               economy: economy, now: { [unowned self] in self.now }, calendar: cal, seed: 1)
        vm.soundEnabled = false
        vm.seedPlantsIfNeeded()
        return vm
    }
    func guess(_ vm: GameViewModel, _ letters: String) {
        for ch in letters { vm.guessInput = String(ch); vm.submitGuess() }
    }
    func plants() throws -> [PlantCollectible] { try container.mainContext.fetch(FetchDescriptor<PlantCollectible>()) }
    func ownedCount() throws -> Int { try plants().filter { $0.earnedCount > 0 }.count }
    /// One win of the fixture word LOTUS.
    func win(_ vm: GameViewModel, _ id: String = "a") { vm.start(entry: entry(id, "LOTUS")); guess(vm, "LOTUS") }
    /// A garden that already has its first plant (daisy), so wins count toward the next one.
    func giveFirstPlant() throws { try plants().first { $0.plantId == "daisy" }?.earnedCount = 1 }

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

    func testHeroForAlreadyOwnedPlantCountsTowardTheNextPlant() throws {
        let vm = try makeVM()
        try plants().first { $0.plantId == "rose" }?.earnedCount = 1
        vm.start(entry: entry("r", "ROSE", kind: .hero, plantId: "rose")); guess(vm, "ROSE")
        XCTAssertNil(vm.earnedPlantName)
        XCTAssertFalse(vm.earnedPlantIsNew)
        XCTAssertTrue(vm.progressMade)
        XCTAssertEqual(vm.wordsTowardPlant, 1)
        XCTAssertEqual(try ownedCount(), 1)
    }

    func testDuplicatesOnlyWhenLevelSetIsComplete() throws {
        // Every plant found, so the word level is the top one and its set is complete. (A complete level 1 set alone
        // is not a real state: the win that finishes it moves the player to level 2, where new plants wait.)
        let vm = try makeVM()
        for p in try plants() { p.earnedCount = 1 }
        let total = try plants().count
        win(vm); win(vm, "b")
        XCTAssertEqual(try plants().map(\.earnedCount).reduce(0, +), total, "no plant on words 1 and 2")
        win(vm, "c")
        XCTAssertNotNil(vm.earnedPlantName)
        XCTAssertFalse(vm.earnedPlantIsNew)
        XCTAssertEqual(try plants().map(\.earnedCount).reduce(0, +), total + 1)
    }

    func testTenthUniquePlantAdvancesWordLevel() throws {
        let vm = try makeVM()
        let l1 = try plants().filter { $0.level == 1 }
        for p in l1.prefix(9) { p.earnedCount = 1 }
        win(vm); win(vm, "b")
        XCTAssertEqual(vm.playerProfile?.currentLevel, 1)
        XCTAssertFalse(vm.leveledUp)
        win(vm, "c")
        XCTAssertEqual(vm.playerProfile?.currentLevel, 2)
        XCTAssertTrue(vm.leveledUp)
        XCTAssertTrue(vm.earnedPlantIsNew)
    }

    func testNinthUniquePlantDoesNotAdvance() throws {
        let vm = try makeVM()
        for p in try plants().filter({ $0.level == 1 }).prefix(8) { p.earnedCount = 1 }
        win(vm); win(vm, "b"); win(vm, "c")
        XCTAssertTrue(vm.earnedPlantIsNew)
        XCTAssertEqual(try plants().filter { $0.level == 1 && $0.earnedCount > 0 }.count, 9)
        XCTAssertEqual(vm.playerProfile?.currentLevel, 1)
        XCTAssertFalse(vm.leveledUp)
    }

    func testALevelTakesThirtyWordsAfterItsFirstPlant() throws {
        let vm = try makeVM()
        win(vm)                                               // the very first plant arrives on the first word
        XCTAssertEqual(try ownedCount(), 1)
        var words = 1
        while vm.playerProfile?.currentLevel == 1 && words < 100 { win(vm, "w\(words)"); words += 1 }
        XCTAssertEqual(vm.playerProfile?.currentLevel, 2)
        XCTAssertEqual(words, 1 + 9 * 3, "first plant at once, then 3 words for each of the other 9")
        XCTAssertTrue(vm.leveledUp)
    }

    // MARK: words toward the next plant (owner decision 2026-11-04)
    func testTheVeryFirstPlantArrivesOnTheFirstWin() throws {
        let vm = try makeVM()
        win(vm)
        XCTAssertNotNil(vm.earnedPlantName)
        XCTAssertTrue(vm.earnedPlantIsNew)
        XCTAssertFalse(vm.progressMade)
        XCTAssertEqual(vm.wordsTowardPlant, 0)
        XCTAssertEqual(vm.playerProfile?.soil, 2)
    }

    func testAfterTheFirstPlantAWinMovesTowardTheNextPlant() throws {
        let vm = try makeVM(); try giveFirstPlant()
        let soil = vm.playerProfile?.soil ?? 0
        win(vm)
        XCTAssertEqual(vm.phase, .won)
        XCTAssertNil(vm.earnedPlantName)
        XCTAssertFalse(vm.earnedPlantIsNew)
        XCTAssertTrue(vm.progressMade)
        XCTAssertEqual(vm.wordsTowardPlant, 1)
        XCTAssertEqual(vm.wordsPerPlant, 3)
        XCTAssertEqual(vm.playerProfile?.wordsTowardPlant, 1)
        XCTAssertEqual(try ownedCount(), 1)
        XCTAssertEqual(vm.playerProfile?.soil, soil, "soil comes with a new plant")
        XCTAssertGreaterThanOrEqual(vm.playerProfile?.water ?? 0, 1, "water is unchanged: every win pays")
        let rec = try container.mainContext.fetch(FetchDescriptor<GameRecord>()).first
        XCTAssertNil(rec?.plantEarned)
    }

    func testEveryThirdWordBringsTheNextPlant() throws {
        let vm = try makeVM(); try giveFirstPlant()
        win(vm); win(vm, "b")
        XCTAssertEqual(vm.wordsTowardPlant, 2)
        XCTAssertEqual(try ownedCount(), 1)
        let soil = vm.playerProfile?.soil ?? 0
        win(vm, "c")
        XCTAssertNotNil(vm.earnedPlantName)
        XCTAssertTrue(vm.earnedPlantIsNew)
        XCTAssertFalse(vm.progressMade)
        XCTAssertEqual(vm.wordsTowardPlant, 0, "progress starts again after a plant arrives")
        XCTAssertEqual(try ownedCount(), 2)
        XCTAssertEqual(vm.playerProfile?.soil, soil + 2)
        win(vm, "d")
        XCTAssertNil(vm.earnedPlantName, "the round after an arrival starts the next count")
        XCTAssertEqual(vm.wordsTowardPlant, 1)
    }

    func testAHeroWordForAnUnfoundPlantArrivesRightAwayAndKeepsProgress() throws {
        let vm = try makeVM(); try giveFirstPlant()
        win(vm)
        XCTAssertEqual(vm.wordsTowardPlant, 1)
        vm.start(entry: entry("r", "ROSE", kind: .hero, plantId: "rose")); guess(vm, "ROSE")
        XCTAssertEqual(vm.earnedPlantName, "Rose")
        XCTAssertTrue(vm.earnedPlantIsNew)
        XCTAssertFalse(vm.progressMade)
        XCTAssertEqual(vm.wordsTowardPlant, 1, "a hero plant does not change the count")
    }

    func testLossesNeverLowerProgressAndNothingIsTakenAway() throws {
        let vm = try makeVM(); try giveFirstPlant()
        win(vm); win(vm, "b")
        vm.start(entry: entry("x", "LOTUS")); guess(vm, "ABCDEFGH")
        XCTAssertEqual(vm.phase, .rested)
        XCTAssertFalse(vm.progressMade)
        XCTAssertEqual(vm.wordsTowardPlant, 2)
        XCTAssertEqual(try ownedCount(), 1)
        win(vm, "c")
        XCTAssertNotNil(vm.earnedPlantName)
    }

    func testADailyBloomWinCountsAsOneWord() throws {
        let vm = try makeVM(); try giveFirstPlant()
        vm.startDaily()
        guess(vm, String(vm.currentEntry!.word.filter { $0.isLetter }))
        XCTAssertEqual(vm.phase, .won)
        XCTAssertNil(vm.earnedPlantName)
        XCTAssertEqual(vm.wordsTowardPlant, 1)
    }

    func testWordsPerPlantIsTunable() throws {
        var econ = Economy.default; econ.wordsPerPlant = 1
        let vm = try makeVM(economy: econ); try giveFirstPlant()
        win(vm)
        XCTAssertNotNil(vm.earnedPlantName)
        XCTAssertEqual(vm.wordsTowardPlant, 0)
        XCTAssertEqual(Economy.default.wordsPerPlant, 3)
    }

    func testAStoredCountAtOrAboveTheTargetBringsAPlantOnTheNextWin() throws {
        let vm = try makeVM(); try giveFirstPlant()
        vm.playerProfile?.wordsTowardPlant = 5        // e.g. after the target is tuned down
        win(vm)
        XCTAssertNotNil(vm.earnedPlantName)
        XCTAssertEqual(vm.wordsTowardPlant, 0)
    }

    func testProgressCopyIsWarmAndSafe() {
        XCTAssertEqual(PlantProgressCopy.winTitle, "Great word!")
        XCTAssertEqual(PlantProgressCopy.winLine(toward: 2, per: 3), "2 of 3 words to your next plant.")
        XCTAssertEqual(PlantProgressCopy.homeLine(toward: 2, per: 3), "2 of 3 words to your next plant")
        XCTAssertEqual(PlantProgressCopy.homeLine(toward: 0, per: 3), "0 of 3 words to your next plant")
        let all = [PlantProgressCopy.winTitle] + (0...3).flatMap { [PlantProgressCopy.winLine(toward: $0, per: 3), PlantProgressCopy.homeLine(toward: $0, per: 3)] }
        for line in all { XCTAssertEqual(CopySafety.check(line), [], line) }
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

    // MARK: wrong streak (drives the Help pulse)
    func testWrongStreakCountsConsecutiveMissesAndResetsOnAHit() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS"))
        guess(vm, "ZX"); XCTAssertEqual(vm.wrongStreak, 2)
        guess(vm, "L"); XCTAssertEqual(vm.wrongStreak, 0)
        guess(vm, "Q"); XCTAssertEqual(vm.wrongStreak, 1)
        vm.start(entry: entry("b", "SEED")); XCTAssertEqual(vm.wrongStreak, 0)
    }

    func testLettersStateForTheKeyboard() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS"))
        guess(vm, "LZ")
        XCTAssertEqual(vm.keyState(for: "L"), .correct)
        XCTAssertEqual(vm.keyState(for: "Z"), .wrong)
        XCTAssertEqual(vm.keyState(for: "A"), .unused)
    }

    func testCanUseHelpUntilTheLadderIsExhausted() throws {
        let vm = try makeVM(); vm.start(entry: entry("a", "LOTUS", hint2: "clue"))
        XCTAssertTrue(vm.canUseHelp)
        vm.useHelp(); vm.useHelp(); vm.useHelp()
        XCTAssertFalse(vm.canUseHelp)
        vm.start(entry: entry("b", "SEED")); guess(vm, "ZXQJKVWY")
        XCTAssertFalse(vm.canUseHelp)      // round over
    }

    func testRegularRoundStillStartsWhenTheOnlyWordIsTodaysDaily() throws {
        let vm = try makeVM([entry("only", "LOTUS")])
        vm.startRound()
        XCTAssertEqual(vm.phase, .playing)
        XCTAssertEqual(vm.currentEntry?.id, "only")
    }

    func testRegularRoundAvoidsTodaysDailyWhenThereIsAChoice() throws {
        let words = [entry("a", "LOTUS"), entry("b", "SEED"), entry("c", "LEAF")]
        let vm = try makeVM(words)
        let daily = DailyBloom(bank: bank(words), calendar: cal).wordId(for: now)
        for _ in 0..<20 { vm.startRound(); XCTAssertNotEqual(vm.currentEntry?.id, daily) }
    }

    // MARK: tutorial word (first session)
    func testTutorialWordCanNeverBeLost() throws {
        let vm = try makeVM(); vm.startTutorial(entry: entry("t", "SEED"))
        XCTAssertTrue(vm.isTutorial)
        guess(vm, "ZXQJKVWYUPMN")
        XCTAssertEqual(vm.petalsRemaining, 1)
        XCTAssertEqual(vm.phase, .playing)
        guess(vm, "SED")
        XCTAssertEqual(vm.phase, .won)
    }

    func testTutorialWinDoesNotCountTowardTheAdCounterOrSessionBeat() throws {
        let vm = try makeVM(); vm.startTutorial(entry: entry("t", "SEED")); guess(vm, "SED")
        XCTAssertEqual(vm.playerProfile?.roundsSinceAd, 0)
        XCTAssertFalse(vm.sessionBeat)
        XCTAssertNotNil(vm.earnedPlantName)       // it still earns the first plant
    }

    func testTutorialFlagClearsOnTheNextRegularRound() throws {
        let vm = try makeVM(); vm.startTutorial(entry: entry("t", "SEED"))
        vm.start(entry: entry("a", "LOTUS"))
        XCTAssertFalse(vm.isTutorial)
    }
}


@MainActor
final class RoseHintTests: XCTestCase {
    func testRestedCardExplainsHowToEarnARoseWhenNoneIsHeld() throws {
        let container = try ModelContainer(for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let e = WordEntry(id: "a", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                          tags: [], minAge: 6, dailyEligible: true, source: "o", license: "p", reviewedBy: "t")
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [e], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let vm = GameViewModel(modelContext: container.mainContext, bank: bank, seed: 1)
        vm.soundEnabled = false; vm.seedPlantsIfNeeded()
        let line = vm.roseHint
        XCTAssertNotNil(line)
        XCTAssertTrue(line!.contains("Rose of Jericho"))
        XCTAssertEqual(CopySafety.check(line!), [], line!)
        vm.playerProfile?.roseOfJerichoCount = 1
        XCTAssertNil(vm.roseHint)               // nothing to explain once one is held
    }
}

import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class GameViewModelTests: XCTestCase {
    var sut: GameViewModel!
    var container: ModelContainer!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
            configurations: config
        )
        sut = GameViewModel(modelContext: container.mainContext)
        sut.seedPlantsIfNeeded()
    }

    override func tearDown() async throws { sut = nil; container = nil }

    func testInitialPetalsEight() {
        XCTAssertEqual(sut.petalsRemaining, 8)
    }

    func testWrongGuessDecrementsPetals() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.guessInput = "Z"
        sut.submitGuess()
        XCTAssertEqual(sut.petalsRemaining, 7)
    }

    func testCorrectGuessKeepsPetals() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.guessInput = "L"
        sut.submitGuess()
        XCTAssertEqual(sut.petalsRemaining, 8)
    }

    func testDuplicateGuessIgnored() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.guessInput = "Z"
        sut.submitGuess()
        sut.guessInput = "Z"
        sut.submitGuess()
        XCTAssertEqual(sut.petalsRemaining, 7) // only decremented once
    }

    func testWordCompleteOnAllLettersGuessed() {
        sut.startGame(word: "LOTUS", question: "Hint")
        for ch in "LOTUS" {
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertTrue(sut.isWordComplete)
        XCTAssertEqual(sut.phase, .won)
    }

    func testZeroPetalsSetsDead() {
        sut.startGame(word: "LOTUS", question: "Hint")
        for ch in "ABCDEFGH" {
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertEqual(sut.phase, .dead)
    }

    func testRoseOfJerichoRestoresFourPetals() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.playerProfile?.roseOfJerichoCount = 1
        for ch in "ABCDEFGH" {   // 8 wrong guesses drive the real .dead transition
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertEqual(sut.phase, .dead)
        sut.useRoseOfJericho()
        XCTAssertEqual(sut.petalsRemaining, 4)
        XCTAssertEqual(sut.playerProfile?.roseOfJerichoCount, 0)
        XCTAssertEqual(sut.phase, .playing)
    }

    func testRoseOfJerichoNoOpWhenNotDead() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.playerProfile?.roseOfJerichoCount = 1
        sut.useRoseOfJericho() // phase is .playing, not .dead
        XCTAssertEqual(sut.playerProfile?.roseOfJerichoCount, 1) // unchanged
    }

    func testLevelAdvancesAfterFivePlantsEarned() {
        sut.playerProfile?.plantsEarnedThisLevel = 4
        sut.playerProfile?.currentLevel = 1
        // Award a 5th plant by calling the internal helper through a win
        sut.startGame(word: "LOTUS", question: "Hint")
        for ch in "LOTUS" {
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertEqual(sut.playerProfile?.currentLevel, 2)
        XCTAssertEqual(sut.playerProfile?.plantsEarnedThisLevel, 0)
    }
}

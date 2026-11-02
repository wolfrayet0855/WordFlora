import XCTest
@testable import WordFlora

final class TriviaServiceTests: XCTestCase {

    func testWordBankLoadsEasyWords() throws {
        let words = try WordBankService.words(for: .easy)
        XCTAssertFalse(words.isEmpty)
    }

    func testWordBankWordsAreAllSingleWords() throws {
        for difficulty in [Difficulty.easy, .medium, .hard] {
            let words = try WordBankService.words(for: difficulty)
            for entry in words {
                XCTAssertFalse(entry.word.contains(" "),
                    "\(entry.word) contains a space in \(difficulty) word bank")
            }
        }
    }

    func testIsValidAnswerRejectsSingleSpacedPhrase() {
        XCTAssertFalse(TriviaService.isValidAnswer("Carbon Dioxide"))
    }

    func testIsValidAnswerRejectsTooLongWord() {
        XCTAssertFalse(TriviaService.isValidAnswer("Abcdefghijklmnopqrs")) // 19 chars
    }

    func testIsValidAnswerAcceptsShortSingleWord() {
        XCTAssertTrue(TriviaService.isValidAnswer("Photosynthesis")) // 14 chars
    }
}

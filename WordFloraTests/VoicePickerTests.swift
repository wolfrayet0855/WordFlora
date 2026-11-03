import XCTest
@testable import WordFlora

final class VoicePickerTests: XCTestCase {
    typealias C = VoicePicker.Candidate
    func c(_ name: String, _ lang: String = "en-US", _ q: VoicePicker.Quality = .standard, novelty: Bool = false, personal: Bool = false) -> C {
        C(id: name, name: name, language: lang, quality: q, isNovelty: novelty, isPersonal: personal)
    }

    func testPrefersHigherQualityOverNiceNames() {
        let best = VoicePicker.best(from: [c("Samantha"), c("Zoe"), c("Evan", "en-US", .enhanced)], language: "en-US")
        XCTAssertEqual(best?.name, "Evan")
    }
    func testPremiumBeatsEnhancedBeatsStandard() {
        let best = VoicePicker.best(from: [c("A", "en-US", .standard), c("B", "en-US", .premium), c("C", "en-US", .enhanced)], language: "en-US")
        XCTAssertEqual(best?.name, "B")
    }
    func testSkipsNoveltyAndPersonalVoices() {
        let best = VoicePicker.best(from: [c("Zarvox", "en-US", .premium, novelty: true), c("Mine", "en-US", .premium, personal: true), c("Samantha")], language: "en-US")
        XCTAssertEqual(best?.name, "Samantha")
    }
    func testExactRegionBeatsSameLanguageOtherRegion() {
        let best = VoicePicker.best(from: [c("Karen", "en-AU"), c("Samantha", "en-US")], language: "en-US")
        XCTAssertEqual(best?.name, "Samantha")
    }
    func testOtherLanguagesAreNeverChosen() {
        XCTAssertNil(VoicePicker.best(from: [c("Thomas", "fr-FR", .premium)], language: "en-US"))
    }
    func testFriendlyNamesBreakTiesOnly() {
        let best = VoicePicker.best(from: [c("Fred"), c("Ava"), c("Samantha")], language: "en-US")
        XCTAssertEqual(best?.name, "Samantha")
    }

    func testScriptSplitsIntoSentencesWithClosingPunctuation() {
        XCTAssertEqual(ReadAloud.sentences(hint: "A pond flower", extra: "It floats!", simpler: nil), ["A pond flower.", "It floats!"])
        XCTAssertEqual(ReadAloud.sentences(hint: "One. Two?", extra: nil, simpler: " "), ["One.", "Two?"])
    }
}

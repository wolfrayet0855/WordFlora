import XCTest
@testable import WordFlora

final class ReadAloudTests: XCTestCase {
    func testScriptReadsTheClueThenAnyExtras() {
        XCTAssertEqual(ReadAloud.script(hint: "A pond flower.", extra: nil, simpler: nil), "A pond flower.")
        XCTAssertEqual(ReadAloud.script(hint: "A pond flower.", extra: "It floats.", simpler: "Grows in water."),
                       "A pond flower. It floats. Grows in water.")
    }
    func testScriptNeverReadsTheWordItself() {
        // The script is built only from clue text, never from the answer.
        let s = ReadAloud.script(hint: "A calm clue.", extra: "Another.", simpler: nil)
        XCTAssertFalse(s.contains("LOTUS"))
    }
    func testBlankPartsAreSkipped() {
        XCTAssertEqual(ReadAloud.script(hint: "One.", extra: "  ", simpler: ""), "One.")
    }
    func testNotOfferedWhileVoiceOverIsRunning() {
        XCTAssertFalse(ReadAloud.shouldOffer(voiceOverRunning: true))
        XCTAssertTrue(ReadAloud.shouldOffer(voiceOverRunning: false))
    }
}

import XCTest
@testable import WordFlora

final class ShareTests: XCTestCase {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    let day = Date(timeIntervalSince1970: 1_780_000_000)      // 2026-05-28

    func testDailyShareShowsPetalsAndNeverTheWord() {
        let t = DailyShare.text(date: day, calendar: cal, solved: true, petalsRemaining: 5, maxPetals: 8, helpers: 0, word: "LOTUS")
        XCTAssertTrue(t.contains("Daily Bloom")); XCTAssertTrue(t.contains("5/8"))
        XCTAssertFalse(t.uppercased().contains("LOTUS"))
        XCTAssertEqual(t.filter { $0 == "🌸" }.count, 5); XCTAssertEqual(t.filter { $0 == "⚪" }.count, 3)
    }

    func testHelpersAreShownAsSeedlingsAndOmittedWhenNone() {
        let none = DailyShare.text(date: day, calendar: cal, solved: true, petalsRemaining: 8, maxPetals: 8, helpers: 0, word: "ROSE")
        XCTAssertFalse(none.contains("🌱"))
        let two = DailyShare.text(date: day, calendar: cal, solved: true, petalsRemaining: 8, maxPetals: 8, helpers: 2, word: "ROSE")
        XCTAssertTrue(two.contains("🌱 2 helpers"))
        XCTAssertTrue(DailyShare.text(date: day, calendar: cal, solved: true, petalsRemaining: 8, maxPetals: 8, helpers: 1, word: "ROSE").contains("🌱 1 helper"))
    }

    func testRestingRoundsAreSharedKindly() {
        let t = DailyShare.text(date: day, calendar: cal, solved: false, petalsRemaining: 0, maxPetals: 8, helpers: 0, word: "LOTUS")
        XCTAssertTrue(t.contains("resting")); XCTAssertEqual(CopySafety.check(t), [], t)
        XCTAssertFalse(t.contains("0/8"))
    }

    func testShareCopyAlwaysPassesTheLinter() {
        for solved in [true, false] { for p in 0...8 {
            let t = DailyShare.text(date: day, calendar: cal, solved: solved, petalsRemaining: p, maxPetals: 8, helpers: p % 3, word: "FERN")
            XCTAssertEqual(CopySafety.check(t), [], t)
        } }
    }

    func testDateIsInTheSharedHeaderInAStableFormat() {
        let t = DailyShare.text(date: day, calendar: cal, solved: true, petalsRemaining: 8, maxPetals: 8, helpers: 0, word: "FERN")
        XCTAssertTrue(t.hasPrefix("WordFlora Daily Bloom · May 28"), t)
    }

    func testPlantShareCaptionNamesThePlantAndStaysKind() {
        let c = PlantShare.caption(plantName: "Venus Flytrap", nickname: "")
        XCTAssertTrue(c.contains("Venus Flytrap")); XCTAssertEqual(CopySafety.check(c), [], c)
        XCTAssertTrue(PlantShare.caption(plantName: "Rose", nickname: "Rosie").contains("Rosie"))
    }
}

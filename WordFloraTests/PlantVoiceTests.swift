import XCTest
@testable import WordFlora

final class PlantVoiceTests: XCTestCase {
    func testEveryPlantHasAStableTraitAndTraitsAreSpread() {
        XCTAssertEqual(PlantVoice.trait(for: "rose"), PlantVoice.trait(for: "rose"))
        let ids = ["rose", "tulip", "daisy", "lotus", "orchid", "baobab", "lavender", "marigold", "clover", "jasmine", "dandelion", "sunflower"]
        XCTAssertEqual(Set(ids.map { PlantVoice.trait(for: $0) }).count, PlantVoice.Trait.allCases.count)
    }
    func testEveryLineIsSpecificWarmAndCopySafe() {
        for t in PlantVoice.Trait.allCases { for e in PlantVoice.Event.allCases {
            let lines = PlantVoice.lines(trait: t, event: e)
            XCTAssertGreaterThanOrEqual(lines.count, 2)
            for l in lines { XCTAssertEqual(CopySafety.check(l), [], l); XCTAssertLessThanOrEqual(l.count, 60, l) }
        } }
    }
    func testLinesAreAlwaysPositiveAndNeverGuiltOrAbsence() {
        let banned = ["miss", "lonely", "waiting", "forgot", "neglect", "thirsty", "dying", "sad"]
        for t in PlantVoice.Trait.allCases { for e in PlantVoice.Event.allCases { for l in PlantVoice.lines(trait: t, event: e) {
            for b in banned { XCTAssertFalse(l.lowercased().contains(b), l) }
        } } }
    }
    func testLineChoiceIsDeterministicPerDayButVariesAcrossDays() {
        let a = PlantVoice.line(plantId: "rose", event: .water, daySeed: 100)
        XCTAssertEqual(a, PlantVoice.line(plantId: "rose", event: .water, daySeed: 100))
        let many = Set((0..<30).map { PlantVoice.line(plantId: "rose", event: .water, daySeed: $0) })
        XCTAssertGreaterThan(many.count, 1)
    }
}

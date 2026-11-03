import XCTest
@testable import WordFlora

final class CapacityTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    func plant(absorbed: Int, day: Date?) -> PlantCollectible {
        let p = PlantCollectible(name: "Rose", botanicalName: "r", botanicalFact: "f", level: 1, imageName: "plant_rose")
        p.absorbedToday = absorbed; p.absorbDay = day; return p
    }

    func testFreshPlantHasRoom() {
        XCTAssertEqual(TendingEngine.capacityState(plant(absorbed: 0, day: t0), now: t0, calendar: cal, economy: .default), .room)
    }
    func testNearlyFullAtSixOrMore() {
        XCTAssertEqual(TendingEngine.capacityState(plant(absorbed: 5, day: t0), now: t0, calendar: cal, economy: .default), .room)
        XCTAssertEqual(TendingEngine.capacityState(plant(absorbed: 6, day: t0), now: t0, calendar: cal, economy: .default), .nearly)
    }
    func testPlentyAtTheCap() {
        XCTAssertEqual(TendingEngine.capacityState(plant(absorbed: 10, day: t0), now: t0, calendar: cal, economy: .default), .plenty)
    }
    func testNewDayStartsFresh() {
        let yesterday = t0.addingTimeInterval(-86_400)
        XCTAssertEqual(TendingEngine.capacityState(plant(absorbed: 10, day: yesterday), now: t0, calendar: cal, economy: .default), .room)
    }
    func testFillFractionNeverExceedsOneAndNeverShowsNumbers() {
        XCTAssertEqual(TendingEngine.capacityFill(plant(absorbed: 5, day: t0), now: t0, calendar: cal, economy: .default), 0.5, accuracy: 0.001)
        XCTAssertEqual(TendingEngine.capacityFill(plant(absorbed: 99, day: t0), now: t0, calendar: cal, economy: .default), 1.0, accuracy: 0.001)
    }
    func testCopyIsPositiveAndSafeForEveryState() {
        for s in [TendingEngine.Capacity.room, .nearly, .plenty] {
            let line = TendingEngine.capacityLine(s, name: "Rose")
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertFalse(line.contains("0"))
        }
    }
}

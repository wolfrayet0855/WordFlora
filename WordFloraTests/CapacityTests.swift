import XCTest
@testable import WordFlora

/// The soft "today" summary under the actions: how many of the three daily cares (two drinks, soil, sun) are done.
final class CapacityTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    func plant(waters: Int = 0, fed: Bool = false, sunny: Bool = false, day: Date? = nil) -> PlantCollectible {
        let p = PlantCollectible(name: "Rose", botanicalName: "r", botanicalFact: "f", level: 1, imageName: "plant_rose")
        let d = day ?? t0
        p.waterToday = waters; p.waterDay = cal.startOfDay(for: d)
        if fed { p.lastFedAt = d }
        if sunny { p.lastSunnyAt = d }
        return p
    }
    func state(_ p: PlantCollectible) -> TendingEngine.Capacity { TendingEngine.capacityState(p, now: t0, calendar: cal, economy: .default) }

    func testFreshPlantHasRoom() {
        XCTAssertEqual(state(plant()), .room)
        XCTAssertEqual(state(plant(waters: 1, sunny: true)), .room)
    }
    func testNearlyWhenTwoCaresAreDone() {
        XCTAssertEqual(state(plant(waters: 2, sunny: true)), .nearly)
        XCTAssertEqual(state(plant(fed: true, sunny: true)), .nearly)
    }
    func testPlentyWhenEveryCareIsDone() {
        XCTAssertEqual(state(plant(waters: 2, fed: true, sunny: true)), .plenty)
    }
    func testNewDayStartsFresh() {
        XCTAssertEqual(state(plant(waters: 2, fed: true, sunny: true, day: t0.addingTimeInterval(-86_400))), .room)
    }
    func testFillFractionCountsEachCare() {
        XCTAssertEqual(TendingEngine.capacityFill(plant(waters: 1), now: t0, calendar: cal, economy: .default), 1.0 / 6, accuracy: 0.001)
        XCTAssertEqual(TendingEngine.capacityFill(plant(waters: 9, fed: true, sunny: true), now: t0, calendar: cal, economy: .default), 1.0, accuracy: 0.001)
    }
    func testCopyIsPositiveAndSafeForEveryState() {
        for s in TendingEngine.Capacity.allCases {
            let line = TendingEngine.capacityLine(s, name: "Rose")
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertFalse(line.contains("0"))
            XCTAssertFalse(line.lowercased().contains("sunshine"), "the summary is about every care, not sun")
        }
    }
}

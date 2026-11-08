import XCTest
@testable import WordFlora

/// Per-plant faded bloom nudges (docs/pm/faded-bloom-offsets.md, tests 1 to 9).
final class FadedBloomOffsetTests: XCTestCase {
    private let eps = 0.001

    func testTheTableHasFifteenRealPlants() throws {
        XCTAssertEqual(FadedBloom.spotFix.count, 15)
        let ids = Set(try PlantCatalog.load().map(\.plantId))
        for key in FadedBloom.spotFix.keys {
            XCTAssertTrue(ids.contains(key), "\(key) is not a plant id in the catalog")
            XCTAssertFalse(key.hasPrefix("plant_"), "\(key): keys are plant ids, not asset names")
        }
    }

    func testEveryNudgeIsInRange() {
        for (id, f) in FadedBloom.spotFix {
            XCTAssertTrue((0...0.4).contains(f.dy), "\(id) dy \(f.dy)")
            XCTAssertTrue((-0.2...0.2).contains(f.dx), "\(id) dx \(f.dx)")
            XCTAssertTrue(f.xk > 0 && f.xk <= 1, "\(id) xk \(f.xk)")
        }
    }

    func testEveryAdjustedSpotStaysInsideTheBox() {
        for id in FadedBloom.spotFix.keys {
            for s in FadedBloom.spots {
                let a = FadedBloom.adjusted(s, plantId: id)
                XCTAssertTrue((0.1...0.9).contains(a.x), "\(id) x \(a.x)")
                XCTAssertTrue((0.1...0.9).contains(a.y), "\(id) y \(a.y)")
            }
        }
    }

    func testAPlantNotInTheTableKeepsTheBaseSpot() {
        for id in ["clover", "rose", "not_a_plant", "plant_lithops"] {
            for s in FadedBloom.spots {
                let a = FadedBloom.adjusted(s, plantId: id)
                XCTAssertEqual(a.x, s.x, "\(id)")
                XCTAssertEqual(a.y, s.y, "\(id)")
            }
        }
    }

    func testLithopsMovesDownAndIn() {
        let a = FadedBloom.adjusted((0.40, 0.26), plantId: "lithops")
        XCTAssertEqual(a.x, 0.46, accuracy: eps)
        XCTAssertEqual(a.y, 0.54, accuracy: eps)
    }

    func testDandelionMovesSideways() {
        let a = FadedBloom.adjusted((0.60, 0.24), plantId: "dandelion")
        XCTAssertEqual(a.x, 0.50, accuracy: eps)
        XCTAssertEqual(a.y, 0.29, accuracy: eps)
        let b = FadedBloom.adjusted((0.40, 0.26), plantId: "dandelion")
        XCTAssertEqual(b.x, 0.30, accuracy: eps)
        XCTAssertEqual(b.y, 0.31, accuracy: eps)
    }

    func testNarrowPlantsPullTowardTheCentre() {
        for s in FadedBloom.spots {
            let a = FadedBloom.adjusted(s, plantId: "silversword")
            XCTAssertEqual(a.x, 0.5, accuracy: 0.03)
            XCTAssertEqual(a.y, s.y, accuracy: 1e-12)
        }
    }

    func testTheClampHolds() {
        let table = ["low": FadedBloom.SpotFix(dy: 0.9, dx: 0, xk: 1), "left": FadedBloom.SpotFix(dy: 0, dx: -1, xk: 1)]
        XCTAssertEqual(FadedBloom.adjusted((0.5, 0.26), plantId: "low", table: table).y, 0.9)
        XCTAssertEqual(FadedBloom.adjusted((0.5, 0.26), plantId: "left", table: table).x, 0.1)
        XCTAssertEqual(FadedBloom.clampToBox(-3), 0.1)
        XCTAssertEqual(FadedBloom.clampToBox(3), 0.9)
    }

    /// The seeded pick is the same formula as before the nudges (which of the five spots a day gets never moves).
    func testTheSeededPickIsUnchanged() {
        var rng = SplitMix64(seed: 0x5EED_F00D)
        let ids = Array(FadedBloom.spotFix.keys) + ["clover", "rose", "daisy"]
        for _ in 0..<200 {
            let seed = Int64(bitPattern: rng.next())
            let id = ids[Int(rng.next() % UInt64(ids.count))]
            let day = Int(rng.next() % 40_000)
            let before = Int((FadedBloom.mixed(seed: seed, plantId: id, day: day) >> 16) % 5)
            XCTAssertEqual(FadedBloom.spotIndex(seed: seed, plantId: id, day: day), before)
            let base = FadedBloom.spot(seed: seed, plantId: id, day: day)
            XCTAssertEqual(base.x, FadedBloom.spots[before].x)
            XCTAssertEqual(base.y, FadedBloom.spots[before].y)
            let placed = FadedBloom.placedSpot(seed: seed, plantId: id, day: day)
            let expected = FadedBloom.adjusted(base, plantId: id)
            XCTAssertEqual(placed.x, expected.x)
            XCTAssertEqual(placed.y, expected.y)
        }
    }
}

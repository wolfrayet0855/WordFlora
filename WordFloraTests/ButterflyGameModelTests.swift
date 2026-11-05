import XCTest
@testable import WordFlora

final class ButterflyGameModelTests: XCTestCase {
    let dayPool = VisitorSpawner.pool(evening: false, lantern: false)

    func make(seed: UInt64 = 3, pool: [String]? = nil, flowers: Int = 4, reduceMotion: Bool = false) -> ButterflyGameModel {
        ButterflyGameModel(pool: pool ?? dayPool, floweringPlants: flowers, reduceMotion: reduceMotion, seed: seed)
    }
    func run(_ m: inout ButterflyGameModel, seconds: Double, step: Double = 0.1) {
        var t = 0.0
        while t < seconds { m.tick(step); t += step }
    }

    func testStartsEmptyAndFinishesAfterThirtyFiveSeconds() {
        var m = make()
        XCTAssertFalse(m.isFinished); XCTAssertTrue(m.visitors.isEmpty)
        run(&m, seconds: 34.5); XCTAssertFalse(m.isFinished)
        run(&m, seconds: 1.0); XCTAssertTrue(m.isFinished)
    }

    func testVisitorsSpawnUpToTheCapAndNoFurther() {
        var m = make(flowers: 0)               // cap of 2
        var peak = 0
        for _ in 0..<300 { m.tick(0.1); peak = max(peak, m.visitors.count) }
        XCTAssertGreaterThan(peak, 0); XCTAssertLessThanOrEqual(peak, VisitorSpawner.maxVisitors(floweringPlants: 0))
    }

    func testSameSeedGivesTheSameGame() {
        var a = make(seed: 9), b = make(seed: 9)
        run(&a, seconds: 10); run(&b, seconds: 10)
        XCTAssertEqual(a.visitors.map(\.speciesId), b.visitors.map(\.speciesId))
        XCTAssertEqual(a.visitors.map(\.x), b.visitors.map(\.x))
    }

    func testSpeciesAlwaysComeFromThePool() {
        var m = make(pool: ["firefly", "luna"])
        for _ in 0..<300 { m.tick(0.1); for v in m.visitors { XCTAssertTrue(["firefly", "luna"].contains(v.speciesId)) } }
    }

    func testFlyingVisitorsMoveAndRestingOnesStayPut() {
        var fly = make(); run(&fly, seconds: 3)
        let before = fly.visitors.map(\.x); fly.tick(0.5)
        XCTAssertNotEqual(before, fly.visitors.prefix(before.count).map(\.x))

        var rest = make(reduceMotion: true); run(&rest, seconds: 3)
        let xs = rest.visitors.map(\.x), ys = rest.visitors.map(\.y)
        rest.tick(0.1)
        XCTAssertEqual(xs, rest.visitors.prefix(xs.count).map(\.x)); XCTAssertEqual(ys, rest.visitors.prefix(ys.count).map(\.y))
    }

    func testCatchingWithinTheRadiusRemovesTheVisitorAndRecordsIt() {
        var m = make()
        m.visitors = [ButterflyGameModel.Visitor(id: 1, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        XCTAssertEqual(m.catchAt(x: 0.55, y: 0.5), "monarch")
        XCTAssertTrue(m.visitors.isEmpty); XCTAssertEqual(m.caught, ["monarch"])
    }

    func testMissesAreFreeAndNeverPunished() {
        var m = make()
        m.visitors = [ButterflyGameModel.Visitor(id: 1, speciesId: "monarch", x: 0.1, y: 0.1, vx: 0, vy: 0, born: 0, resting: false)]
        XCTAssertNil(m.catchAt(x: 0.9, y: 0.9)); XCTAssertNil(m.catchAt(x: 0.9, y: 0.9))
        XCTAssertEqual(m.visitors.count, 1); XCTAssertTrue(m.caught.isEmpty); XCTAssertFalse(m.isFinished)
    }

    func testCatchTakesTheNearestVisitor() {
        var m = make()
        m.visitors = [
            ButterflyGameModel.Visitor(id: 1, speciesId: "honeybee", x: 0.50, y: 0.5, vx: 0, vy: 0, born: 0, resting: false),
            ButterflyGameModel.Visitor(id: 2, speciesId: "ladybug", x: 0.54, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        XCTAssertEqual(m.catchAt(x: 0.545, y: 0.5), "ladybug")
    }

    func testNothingCanBeCaughtAfterTheGameEnds() {
        var m = make(); run(&m, seconds: 36)
        m.visitors = [ButterflyGameModel.Visitor(id: 9, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        XCTAssertNil(m.catchAt(x: 0.5, y: 0.5))
    }

    func testVisitorsThatFlyOffScreenAreRemoved() {
        var m = make()
        // id 99 cannot collide with ids the game hands out to newly spawned visitors
        m.visitors = [ButterflyGameModel.Visitor(id: 99, speciesId: "monarch", x: 1.05, y: 0.5, vx: 0.5, vy: 0, born: 0, resting: false)]
        m.tick(0.5)
        XCTAssertFalse(m.visitors.contains { $0.id == 99 })
    }

    func testRestingVisitorsStayHalfAMinuteLessThanTheGameButAreReplaced() {
        var m = make(reduceMotion: true)
        run(&m, seconds: 20)
        XCTAssertGreaterThan(m.visitors.count, 0)
        XCTAssertTrue(m.visitors.allSatisfy { $0.resting })
    }

    // MARK: calm mode (no time bar, slower visitors, ends after 5 hellos or Done)
    func testCalmGameHasNoTimeLimit() {
        var m = ButterflyGameModel(pool: dayPool, floweringPlants: 4, reduceMotion: false, seed: 3, calm: true)
        run(&m, seconds: ButterflyGameModel.duration + 30)
        XCTAssertFalse(m.isFinished)
        XCTAssertFalse(m.showsTimeBar)
        XCTAssertTrue(make().showsTimeBar)
    }

    func testCalmGameEndsAfterFiveCatches() {
        var m = ButterflyGameModel(pool: dayPool, floweringPlants: 4, reduceMotion: true, seed: 3, calm: true)
        var caught = 0
        var t = 0.0
        while caught < 5 && t < 200 {
            m.tick(0.1); t += 0.1
            if let v = m.visitors.first, m.catchAt(x: v.x, y: v.y, radius: 0.01) != nil { caught += 1 }
        }
        XCTAssertEqual(caught, 5)
        XCTAssertTrue(m.isFinished)
        XCTAssertEqual(ButterflyGameModel.calmCatchGoal, 5)
    }

    func testDoneEndsTheGameAtOnceAndKeepsTheCatches() {
        var m = ButterflyGameModel(pool: dayPool, floweringPlants: 4, reduceMotion: true, seed: 3, calm: true)
        run(&m, seconds: 1)
        let v = m.visitors[0]; m.catchAt(x: v.x, y: v.y)
        m.finishNow()
        XCTAssertTrue(m.isFinished)
        XCTAssertEqual(m.caught.count, 1)
        XCTAssertNil(m.catchAt(x: 0.5, y: 0.5, radius: 1))
    }

    func testCalmVisitorsDriftAtAboutSixtyPercentSpeed() {
        var normal = make(seed: 9), calm = ButterflyGameModel(pool: dayPool, floweringPlants: 4, reduceMotion: false, seed: 9, calm: true)
        run(&normal, seconds: 0.5); run(&calm, seconds: 0.5)
        let a = normal.visitors[0].vx, b = calm.visitors[0].vx
        XCTAssertEqual(b / a, 0.6, accuracy: 0.001)
    }
}

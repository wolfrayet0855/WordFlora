import XCTest
import SwiftData
@testable import WordFlora

/// The butterfly net, Quick wings and Gentle Net (gate G2b; docs/pm/butterfly-net-spec.md section 8 and
/// docs/pm/badge-mechanics-art.md section 2): pace table, hit maths, the net's lag and rest point, visitor moves,
/// gentle hellos, the badge's counter, the copy, and a seeded sweeping-player simulation.
@MainActor
final class ButterflyNetTests: XCTestCase {
    let dayPool = VisitorSpawner.pool(evening: false, lantern: false)
    var clock = Date(timeIntervalSince1970: 1_780_000_000)

    func make(_ pace: ButterflyPace, seed: UInt64 = 3, flowers: Int = 8, reduceMotion: Bool = false) -> ButterflyGameModel {
        ButterflyGameModel(pool: dayPool, floweringPlants: flowers, reduceMotion: reduceMotion, seed: seed, pace: pace)
    }

    func makeApp(age: AgeBand? = .eighteenPlus, quiet: Bool = false, calm: Bool = false, easier: Bool = false) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-net-\(UUID().uuidString)")!)
        settings.ageBand = age; settings.quietGarden = quiet; settings.calmMode = calm; settings.easierButterflies = easier
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: { [unowned self] in self.clock },
                        notifications: ReminderTests.FakeCenter())
    }

    // MARK: Pace table (section 1)

    func testPaceTableFirstMatchWins() {
        typealias C = ButterflyPace.Context
        XCTAssertEqual(ButterflyPace.resolve(C(ageBand: .under13)), .gentle)
        XCTAssertEqual(ButterflyPace.resolve(C(ageBand: nil)), .gentle, "unknown age is treated as young")
        XCTAssertEqual(ButterflyPace.resolve(C(ageBand: .thirteenPlus)), .quickWings)
        XCTAssertEqual(ButterflyPace.resolve(C(ageBand: .eighteenPlus)), .quickWings)
        XCTAssertEqual(ButterflyPace.resolve(C(ageBand: .thirteenPlus, easierButterflies: true)), .gentle)
        for age in [AgeBand.under13, .thirteenPlus, .eighteenPlus, nil] {
            XCTAssertEqual(ButterflyPace.resolve(C(calmMode: true, ageBand: age)), .calm)
            XCTAssertEqual(ButterflyPace.resolve(C(wake: true, ageBand: age)), .gentle)
            XCTAssertEqual(ButterflyPace.resolve(C(calmMode: true, wake: true, ageBand: age)), .gentle, "a wake game keeps its tuning")
            XCTAssertEqual(ButterflyPace.resolve(C(reduceMotion: true, ageBand: age)), .gentle)
            XCTAssertEqual(ButterflyPace.resolve(C(voiceOver: true, ageBand: age)), .gentle)
            XCTAssertEqual(ButterflyPace.resolve(C(switchControl: true, ageBand: age)), .gentle)
        }
    }

    func testUnderThirteenNeverGetsQuickWingsInAnyCombination() {
        for calm in [false, true] { for wake in [false, true] { for rm in [false, true] { for easier in [false, true] {
            for age in [AgeBand.under13, nil] {
                let p = ButterflyPace.resolve(.init(calmMode: calm, wake: wake, reduceMotion: rm, ageBand: age, easierButterflies: easier))
                XCTAssertNotEqual(p, .quickWings)
            }
        } } } }
        XCTAssertFalse(ButterflyPace.offersEasierSwitch(ageBand: .under13, calmMode: false))
        XCTAssertFalse(ButterflyPace.offersEasierSwitch(ageBand: nil, calmMode: false))
        XCTAssertFalse(ButterflyPace.offersEasierSwitch(ageBand: .thirteenPlus, calmMode: true))
        XCTAssertTrue(ButterflyPace.offersEasierSwitch(ageBand: .thirteenPlus, calmMode: false))
        XCTAssertTrue(ButterflyPace.offersEasierSwitch(ageBand: .eighteenPlus, calmMode: false))
    }

    func testTheAppStartsEachAgeAtItsPace() throws {
        XCTAssertEqual(try makeApp(age: .eighteenPlus).startButterflyGame(seed: 1).pace, .quickWings)
        XCTAssertEqual(try makeApp(age: .thirteenPlus).startButterflyGame(seed: 1).pace, .quickWings)
        XCTAssertEqual(try makeApp(age: .under13).startButterflyGame(seed: 1).pace, .gentle)
        XCTAssertEqual(try makeApp(age: nil).startButterflyGame(seed: 1).pace, .gentle)
        XCTAssertEqual(try makeApp(age: .thirteenPlus, easier: true).startButterflyGame(seed: 1).pace, .gentle)
        XCTAssertEqual(try makeApp(age: .thirteenPlus, calm: true).startButterflyGame(seed: 1).pace, .calm)
        let app = try makeApp(age: .eighteenPlus)
        XCTAssertEqual(app.startButterflyGame(seed: 1, wake: true).pace, .gentle)
        XCTAssertEqual(app.startButterflyGame(seed: 1, reduceMotion: true).pace, .gentle)
        XCTAssertEqual(app.startButterflyGame(seed: 1, voiceOver: true).pace, .gentle)
        XCTAssertEqual(app.startButterflyGame(seed: 1, switchControl: true).pace, .gentle)
    }

    // MARK: Quick wings constants

    func testQuickWingsNumbers() {
        XCTAssertEqual(ButterflyPace.quickWings.speedFactor, 1.3)
        XCTAssertEqual(ButterflyPace.quickWings.roundSeconds, 45)
        XCTAssertEqual(ButterflyPace.quickWings.perchSeconds, 2)
        XCTAssertEqual(ButterflyPace.quickWings.spawnGap, 1.0)
        XCTAssertEqual(ButterflyPace.quickWings.helloPause, 0.25)
        XCTAssertEqual(ButterflyPace.quickWings.hoopGrace, 0)
        XCTAssertTrue(ButterflyPace.quickWings.turns)
        XCTAssertEqual(ButterflyGameModel.tellSeconds, 0.4)
        XCTAssertEqual((1...3).map { ButterflyPace.quickWings.netRadius(tier: $0) }, [40, 56, 72], "radius in points: 80 to 144 pt across")
        XCTAssertEqual(ButterflyPace.quickWings.netRadius(tier: 0), 40)
        XCTAssertEqual(ButterflyPace.quickWings.netRadius(tier: 9), 72)
    }

    func testGentleAndCalmKeepTodaysNumbers() {
        XCTAssertEqual((1...3).map { ButterflyPace.gentle.netRadius(tier: $0) }, [48, 64, 80])
        XCTAssertEqual((1...3).map { ButterflyPace.calm.netRadius(tier: $0) }, [48, 64, 80])
        XCTAssertEqual(ButterflyPace.gentle.roundSeconds, 35); XCTAssertEqual(ButterflyPace.gentle.speedFactor, 1)
        XCTAssertEqual(ButterflyPace.gentle.spawnGap, 1.2); XCTAssertEqual(ButterflyPace.gentle.perchSeconds, 3)
        XCTAssertEqual(ButterflyPace.gentle.helloPause, 0); XCTAssertEqual(ButterflyPace.gentle.hoopGrace, 6)
        XCTAssertFalse(ButterflyPace.gentle.turns); XCTAssertFalse(ButterflyPace.calm.turns)
        XCTAssertEqual(ButterflyPace.calm.roundSeconds, .infinity); XCTAssertEqual(ButterflyPace.calm.speedFactor, 0.6)
        XCTAssertEqual(ButterflyPace.calm.perchSeconds, 5, "3 s at 60% speed")
        XCTAssertEqual(ToolEngine.netCatchRadius(tier: 2), 64)
    }

    func testRoundLengths() {
        var g = make(.gentle); for _ in 0..<349 { g.tick(0.1) }; XCTAssertFalse(g.isFinished)
        for _ in 0..<3 { g.tick(0.1) }; XCTAssertTrue(g.isFinished)
        var q = make(.quickWings); for _ in 0..<440 { q.tick(0.1) }; XCTAssertFalse(q.isFinished, "Quick wings is longer, never shorter")
        for _ in 0..<12 { q.tick(0.1) }; XCTAssertTrue(q.isFinished)
        var c = make(.calm); for _ in 0..<900 { c.tick(0.1) }; XCTAssertFalse(c.isFinished)
        var short = ButterflyGameModel(pool: dayPool, floweringPlants: 4, reduceMotion: false, seed: 1, pace: .quickWings, roundSeconds: 6)
        for _ in 0..<61 { short.tick(0.1) }; XCTAssertTrue(short.isFinished)
    }

    func testVisitorSpeedsByPace() {
        func speeds(_ pace: ButterflyPace) -> [Double] {
            var out = [Double]()
            for seed in UInt64(1)...40 {
                var m = make(pace, seed: seed)
                for _ in 0..<40 { m.tick(0.1); out += m.visitors.filter { $0.phase == .flying }.map { abs($0.vx) } }
            }
            return out
        }
        let q = speeds(.quickWings), g = speeds(.gentle), c = speeds(.calm)
        XCTAssertTrue(q.allSatisfy { $0 >= 0.078 - 1e-9 && $0 <= 0.182 + 1e-9 })
        XCTAssertTrue(g.allSatisfy { $0 >= 0.06 - 1e-9 && $0 <= 0.14 + 1e-9 })
        XCTAssertTrue(c.allSatisfy { $0 >= 0.036 - 1e-9 && $0 <= 0.084 + 1e-9 })
        XCTAssertGreaterThan(q.max()!, 0.14, "some Quick wings visitors are quicker than any gentle one")
    }

    // MARK: Hit geometry (section 2)

    func testInsideOnTheRimAndOutside() {
        let c = CGPoint(x: 100, y: 100)
        XCTAssertTrue(NetGeometry.segmentHit(CGPoint(x: 110, y: 100), from: c, to: c, radius: 40))
        XCTAssertTrue(NetGeometry.segmentHit(CGPoint(x: 140, y: 100), from: c, to: c, radius: 40), "inclusive at the rim")
        XCTAssertFalse(NetGeometry.segmentHit(CGPoint(x: 140.5, y: 100), from: c, to: c, radius: 40))
    }

    func testQuickWingsHoopIsATrueCircleInPoints() {
        let hoop = CGPoint(x: 195, y: 300)
        XCTAssertTrue(NetGeometry.quickHit(visitor: CGPoint(x: 195, y: 360), from: hoop, to: hoop, radius: 64))
        XCTAssertFalse(NetGeometry.quickHit(visitor: CGPoint(x: 195, y: 370), from: hoop, to: hoop, radius: 64))
        // Through the model on a 390 x 700 scene: 60 pt straight below says hello, 70 pt does not.
        for (dy, hit) in [(60.0, true), (70.0, false)] {
            var m = make(.quickWings)
            m.visitors = [.init(id: 90, speciesId: "monarch", x: 195.0 / 390, y: (300 + dy) / 700, vx: 0, vy: 0, born: 0, resting: false)]
            XCTAssertEqual(!m.catchSwept(from: hoop, to: hoop, finger: hoop, scene: CGSize(width: 390, height: 700), radius: 64).isEmpty, hit)
        }
    }

    func testASweptCapsuleCannotJumpOverAVisitor() {
        XCTAssertTrue(NetGeometry.segmentHit(CGPoint(x: 150, y: 40), from: CGPoint(x: 0, y: 0), to: CGPoint(x: 300, y: 0), radius: 48))
        var m = make(.quickWings)
        m.visitors = [.init(id: 90, speciesId: "ladybug", x: 150.0 / 390, y: 140.0 / 700, vx: 0, vy: 0, born: 0, resting: false)]
        let hellos = m.catchSwept(from: CGPoint(x: 0, y: 100), to: CGPoint(x: 300, y: 100), finger: nil, scene: CGSize(width: 390, height: 700), radius: 48)
        XCTAssertEqual(hellos.map(\.speciesId), ["ladybug"], "no sample was near it; the sweep still says hello")
    }

    func testTouchDownIsAScoopAndLiftTestsNothing() {
        var net = ButterflyNet(restPoint: CGPoint(x: 300, y: 500))
        let s = net.touchDown(at: CGPoint(x: 80, y: 120))
        XCTAssertEqual(s.from, s.to, "no sweep from the rest point")
        XCTAssertEqual(net.position, CGPoint(x: 80, y: 120))
        net.lift()
        XCTAssertFalse(net.isDown)
        for _ in 0..<20 { XCTAssertNil(net.step(1.0 / 30, reduceMotion: false), "nothing is tested on the way home") }
        XCTAssertLessThan(hypot(net.position.x - 300, net.position.y - 500), 2, "home within about 0.3 s, plus a little")
    }

    /// Every point today's game accepts, the gentle rule accepts (1,000 seeded positions on three screen sizes).
    func testGentleIsNeverHarderThanToday() {
        var rng = SplitMix64(seed: 77)
        func u() -> Double { Double(rng.next() % 100_000) / 100_000 }
        let scenes = [CGSize(width: 320, height: 470), CGSize(width: 393, height: 715), CGSize(width: 820, height: 1050)]
        var accepted = 0
        for scene in scenes { for tier in 1...3 { for _ in 0..<1000 {
            let f = CGPoint(x: u() * scene.width, y: u() * scene.height)
            let v = CGPoint(x: f.x + (u() - 0.5) * 240, y: f.y + (u() - 0.5) * 240)
            let r = ButterflyPace.gentle.netRadius(tier: tier)
            guard NetGeometry.legacyDistance(visitor: v, finger: f, scene: scene, tierRadius: r) != nil else { continue }
            accepted += 1
            // The hoop can lag anywhere; the finger alone must be enough.
            let hoop = CGPoint(x: u() * scene.width, y: u() * scene.height)
            XCTAssertTrue(NetGeometry.gentleHit(visitor: v, finger: f, from: hoop, to: hoop, scene: scene, radius: r))
        } } }
        XCTAssertGreaterThan(accepted, 500)
    }

    func testTheGentleModelSaysHelloWhereverTodaysCatchDid() {
        for seed in UInt64(1)...60 {
            var a = make(.gentle, seed: seed)
            for _ in 0..<30 { a.tick(0.1) }
            guard let v = a.visitors.first else { continue }
            let scene = CGSize(width: 393, height: 715)
            let finger = CGPoint(x: (v.x + 0.07) * scene.width, y: v.y * scene.height)
            var legacy = a, net = a
            let old = legacy.catchAt(x: finger.x / scene.width, y: finger.y / scene.height, radius: max(0.08, 48 / scene.width))
            let far = CGPoint(x: -500, y: -500)
            let new = net.catchSwept(from: far, to: far, finger: finger, scene: scene, radius: 48)
            if let old { XCTAssertTrue(new.map(\.speciesId).contains(old), "seed \(seed)") }
        }
    }

    // MARK: The net's lag and rest point

    func testTheHoopFollowsWithASoftLagAndNoneUnderReduceMotion() {
        var net = ButterflyNet(restPoint: CGPoint(x: 300, y: 500))
        // A quick 120 pt move of the finger (the time constant is 0.06 s: 3.6% is left after 0.2 s).
        net.touchDown(at: CGPoint(x: 100, y: 100)); net.drag(to: CGPoint(x: 220, y: 100))
        net.step(1.0 / 30, reduceMotion: false)
        XCTAssertGreaterThan(hypot(net.position.x - 220, net.position.y - 100), 20, "it trails the finger")
        for _ in 0..<5 { net.step(1.0 / 30, reduceMotion: false) }
        XCTAssertLessThan(hypot(net.position.x - 220, net.position.y - 100), 5, "within 5 pt in 0.2 s")
        var still = ButterflyNet(restPoint: CGPoint(x: 300, y: 500))
        still.touchDown(at: CGPoint(x: 100, y: 100)); still.drag(to: CGPoint(x: 260, y: 220))
        still.step(1.0 / 30, reduceMotion: true)
        XCTAssertEqual(still.position, CGPoint(x: 260, y: 220))
    }

    func testTheRestingNetSitsClearAboveThePill() {
        for scene in [CGSize(width: 320, height: 470), CGSize(width: 393, height: 715), CGSize(width: 820, height: 1050)] {
            for r in [40.0, 48, 64, 72, 80] {
                let pillTop = Double(scene.height) - 176
                let rest = ButterflyNet.restPoint(scene: scene, radius: r, pillTop: pillTop, lastLift: nil)
                XCTAssertLessThanOrEqual(Double(rest.y) + r, pillTop - 24 + 1e-9, "\(scene) r \(r)")
                XCTAssertGreaterThanOrEqual(Double(rest.x) - r, 20, "never in the back-swipe edge")
                XCTAssertGreaterThan(Double(rest.x), Double(scene.width) / 2, "bottom right by default")
                let lifted = ButterflyNet.restPoint(scene: scene, radius: r, pillTop: pillTop, lastLift: CGPoint(x: 0, y: 0))
                XCTAssertGreaterThanOrEqual(Double(lifted.x) - r, 20)
                XCTAssertLessThanOrEqual(Double(lifted.y) + r, pillTop - 24 + 1e-9)
            }
        }
        let rest = ButterflyNet.restPoint(scene: CGSize(width: 393, height: 715), radius: 48, pillTop: 540, lastLift: CGPoint(x: 120, y: 480))
        XCTAssertEqual(rest.x, 120, "it follows the last lift")
        XCTAssertEqual(ButterflyNet.pillClearance, 24); XCTAssertEqual(ButterflyNet.restingOpacity, 0.85)
    }

    func testHandlePointsToTheNearerBottomCorner() {
        XCTAssertTrue(ButterflyNet.handlePointsRight(hoopX: 300, sceneWidth: 390))
        XCTAssertFalse(ButterflyNet.handlePointsRight(hoopX: 90, sceneWidth: 390))
        XCTAssertEqual(ButterflyNet.flowerSpots(count: 1, sceneWidth: 400), [0.5])
        XCTAssertEqual(ButterflyNet.flowerSpots(count: 0, sceneWidth: 400), [])
    }

    // MARK: Moves: turns, perches

    /// Every visitor's life, tick by tick, over many seeds.
    private func lives(_ pace: ButterflyPace, seeds: ClosedRange<UInt64>, seconds: Double = 45, dt: Double = 1.0 / 30,
                       check: (ButterflyGameModel) -> Void = { _ in }) -> [Int: [(t: Double, v: ButterflyGameModel.Visitor)]] {
        var all = [Int: [(Double, ButterflyGameModel.Visitor)]]()
        for seed in seeds {
            var m = make(pace, seed: seed)
            m.setScene(size: CGSize(width: 393, height: 715), perchSpots: ButterflyNet.flowerSpots(count: 4, sceneWidth: 393), perchY: 0.9)
            var t = 0.0
            while t < seconds && !m.isFinished {
                m.tick(dt); t += dt
                check(m)
                for v in m.visitors { all[Int(seed) * 1000 + v.id, default: []].append((m.elapsed, v)) }
            }
        }
        return all
    }

    func testATurnAlwaysHasItsTellAndHappensOnceAwayFromTheEdges() {
        var turns = 0
        for (_, life) in lives(.quickWings, seeds: 1...40) {
            let phases = life.map(\.v.phase)
            let tells = zip(phases, phases.dropFirst()).filter { $0.0 != .tell && $0.1 == .tell }.count
            let swerves = zip(phases, phases.dropFirst()).filter { $0.0 != .swerve && $0.1 == .swerve }.count
            XCTAssertLessThanOrEqual(tells, 1, "one turn at most"); XCTAssertLessThanOrEqual(swerves, 1)
            let landed = phases.contains(.landing)
            XCTAssertFalse(landed && tells > 0, "one move per visitor: a perch or a turn, never both")
            if let ti = phases.firstIndex(of: .tell) {
                turns += 1
                XCTAssertGreaterThanOrEqual(life[ti].v.x, 0.1); XCTAssertLessThanOrEqual(life[ti].v.x, 0.9)
                if let si = phases.firstIndex(of: .swerve) {
                    XCTAssertGreaterThanOrEqual(life[si].t - life[ti].t, 0.4 - 1e-6, "the 0.4 s tell comes first")
                    XCTAssertTrue(life[ti].v.showsIdle, "wings flared during the tell")
                    XCTAssertEqual(abs(life[ti].v.vx), abs(life[si].v.vx), "a swerve, never a reversal")
                    XCTAssertEqual(life[ti].v.vx.sign, life[si].v.vx.sign)
                }
            }
        }
        XCTAssertGreaterThan(turns, 20)
    }

    func testNoTurnsInTheGentleOrCalmGame() {
        for pace in [ButterflyPace.gentle, .calm] {
            for (_, life) in lives(pace, seeds: 1...25, seconds: 35) {
                XCTAssertFalse(life.contains { $0.v.phase == .tell || $0.v.phase == .swerve }, "\(pace)")
            }
        }
    }

    func testNeverTwoRestingVisitorsAtOnce() {
        for pace in [ButterflyPace.gentle, .quickWings, .calm] {
            for dt in [1.0 / 30, 0.1] {
                _ = lives(pace, seeds: 1...30, seconds: 40, dt: dt) { m in
                    XCTAssertLessThanOrEqual(m.visitors.filter { $0.phase == .landing || $0.phase == .perched }.count, 1, "\(pace)")
                }
            }
        }
    }

    func testPerchLengthsByPaceAndTheyFlyOn() {
        for (pace, seconds) in [(ButterflyPace.gentle, 3.0), (.quickWings, 2.0), (.calm, 5.0)] {
            var rests = [Double]()
            for (_, life) in lives(pace, seeds: 1...30, seconds: 60) {
                let perched = life.filter { $0.v.phase == .perched }
                // Only rests that ended inside the round, with the visitor seen flying again.
                guard let first = perched.first, let last = perched.last, life.last!.v.phase == .flying else { continue }
                rests.append(last.t - first.t)
                XCTAssertTrue(first.v.resting)
                XCTAssertTrue(life.drop(while: { $0.v.phase != .takeoff }).contains { $0.v.phase == .flying }, "it flies on")
            }
            XCTAssertFalse(rests.isEmpty, "\(pace)")
            for r in rests { XCTAssertEqual(r, seconds, accuracy: 0.1, "\(pace)") }
        }
    }

    func testAboutOneInThreeVisitorsDrawsALanding() {
        var perch = 0, total = 0
        for seed in UInt64(1)...420 {
            var m = make(.gentle, seed: seed, flowers: 12)
            var seen = Set<Int>()
            for _ in 0..<120 {
                m.tick(0.1)
                for v in m.visitors where seen.insert(v.id).inserted {
                    total += 1
                    if case .perch = v.move { perch += 1 }
                }
            }
        }
        XCTAssertGreaterThan(total, 3000)
        XCTAssertEqual(Double(perch) / Double(total), 1.0 / 3.0, accuracy: 0.03)
    }

    func testLandedVisitorsRestOnAFlower() {
        let spots = ButterflyNet.flowerSpots(count: 4, sceneWidth: 393)
        var landed = 0
        for (_, life) in lives(.gentle, seeds: 1...20, seconds: 35) {
            if let p = life.first(where: { $0.v.phase == .perched }) {
                landed += 1
                XCTAssertTrue(spots.contains { abs($0 - p.v.x) < 1e-9 }, "on a flower")
                XCTAssertEqual(p.v.y, 0.9, accuracy: 1e-9)
            }
        }
        XCTAssertGreaterThan(landed, 5)
    }

    func testSameSeedSameGameInEveryPace() {
        for pace in ButterflyPace.allCases {
            var a = make(pace, seed: 11), b = make(pace, seed: 11)
            for _ in 0..<200 { a.tick(0.05); b.tick(0.05) }
            XCTAssertEqual(a.visitors, b.visitors, "\(pace)")
        }
    }

    func testGentleGameKeepsTodaysVisitorsForASeed() {
        // The new draws come after today's: species, sides, heights and speeds of the first visitor match a Calm round.
        var g = make(.gentle, seed: 9), c = make(.calm, seed: 9)
        g.tick(0.5); c.tick(0.5)
        XCTAssertEqual(g.visitors[0].speciesId, c.visitors[0].speciesId)
        XCTAssertEqual(c.visitors[0].vx / g.visitors[0].vx, 0.6, accuracy: 1e-9)
        XCTAssertEqual(g.visitors[0].move, c.visitors[0].move)
    }

    func testReduceMotionSpawnsAreUnchangedInEveryPace() {
        let reference = { (pace: ButterflyPace) -> [ButterflyGameModel.Visitor] in
            var m = self.make(pace, seed: 5, reduceMotion: true)
            for _ in 0..<60 { m.tick(0.1) }
            return m.visitors
        }
        let gentle = reference(.gentle)
        XCTAssertFalse(gentle.isEmpty)
        XCTAssertTrue(gentle.allSatisfy { $0.resting && $0.landedUntil == nil && $0.move == .straight })
        XCTAssertEqual(reference(.calm), gentle)
        // Quick wings never plays under Reduce Motion (the pace rule), and even if it did each spawn lands in the same
        // place; only its shorter spawn gap brings one more visitor sooner.
        let quick = reference(.quickWings)
        XCTAssertEqual(Array(quick.prefix(gentle.count)).map(\.x), gentle.map(\.x))
        XCTAssertEqual(Array(quick.prefix(gentle.count)).map(\.y), gentle.map(\.y))
        XCTAssertEqual(ButterflyPace.resolve(.init(reduceMotion: true, ageBand: .eighteenPlus)), .gentle)
        var m = make(.gentle, seed: 5, reduceMotion: true)
        m.tick(0.5); let id = m.visitors[0].id
        for _ in 0..<79 { m.tick(0.1) }
        XCTAssertTrue(m.visitors.contains { $0.id == id }, "still there before 8 s")
        for _ in 0..<5 { m.tick(0.1) }
        XCTAssertFalse(m.visitors.contains { $0.id == id })
    }

    // MARK: Hellos

    private func visitor(_ id: Int, _ species: String, x: Double, y: Double, resting: Bool = false) -> ButterflyGameModel.Visitor {
        var v = ButterflyGameModel.Visitor(id: id, speciesId: species, x: x, y: y, vx: 0, vy: 0, born: 0, resting: resting)
        if resting { v.phase = .perched; v.landedUntil = 99 }
        return v
    }

    func testARestingHelloIsGentleAndAFlyingOneIsNot() {
        var m = make(.gentle)
        m.visitors = [visitor(90, "monarch", x: 0.2, y: 0.5, resting: true), visitor(91, "ladybug", x: 0.8, y: 0.5)]
        let scene = CGSize(width: 400, height: 700)
        let a = m.catchSwept(from: CGPoint(x: 80, y: 350), to: CGPoint(x: 80, y: 350), finger: nil, scene: scene, radius: 48)
        let b = m.catchSwept(from: CGPoint(x: 320, y: 350), to: CGPoint(x: 320, y: 350), finger: nil, scene: scene, radius: 48)
        XCTAssertEqual(a.map(\.gentle), [true]); XCTAssertEqual(b.map(\.gentle), [false])
        XCTAssertEqual(m.caught, ["monarch", "ladybug"], "both count for First Catch and the album")
        XCTAssertEqual(m.caughtGently, ["monarch"])
    }

    func testReduceMotionHellosAreAllGentleAndCalmOnlyWhenResting() {
        var rm = make(.gentle, reduceMotion: true)
        for _ in 0..<40 { rm.tick(0.1) }
        while let v = rm.visitors.first { rm.catchAt(x: v.x, y: v.y, radius: 0.01) }
        XCTAssertFalse(rm.caught.isEmpty); XCTAssertEqual(rm.caughtGently, rm.caught)

        var calm = make(.calm)
        calm.visitors = [visitor(90, "monarch", x: 0.5, y: 0.5)]
        XCTAssertNotNil(calm.sayHello(toVisitor: 90))
        XCTAssertEqual(calm.caughtGently, [], "Calm only slows visitors: a flying hello is not gentle")
        calm.visitors = [visitor(91, "monarch", x: 0.5, y: 0.5, resting: true)]
        XCTAssertEqual(calm.sayHello(toVisitor: 91)?.gentle, true)
    }

    func testGentleSweepGreetsEveryoneQuickWingsOneThenAPause() {
        let scene = CGSize(width: 400, height: 700), p = CGPoint(x: 200, y: 350)
        var g = make(.gentle)
        g.visitors = [visitor(90, "monarch", x: 0.5, y: 0.5), visitor(91, "ladybug", x: 0.55, y: 0.5)]
        XCTAssertEqual(g.catchSwept(from: p, to: p, finger: p, scene: scene, radius: 48).count, 2)

        var q = make(.quickWings)
        q.visitors = [visitor(90, "monarch", x: 0.5, y: 0.5), visitor(91, "ladybug", x: 0.56, y: 0.5)]
        XCTAssertEqual(q.catchSwept(from: p, to: p, finger: p, scene: scene, radius: 40).map(\.speciesId), ["monarch"], "the nearest one")
        XCTAssertEqual(q.catchSwept(from: CGPoint(x: 224, y: 350), to: CGPoint(x: 224, y: 350), finger: nil, scene: scene, radius: 40), [],
                       "the net lifts for 0.25 s")
        q.tick(0.26)
        q.visitors = q.visitors.filter { $0.id == 91 }.map { var v = $0; v.x = 0.56; v.y = 0.5; return v }
        XCTAssertEqual(q.catchSwept(from: CGPoint(x: 224, y: 350), to: CGPoint(x: 224, y: 350), finger: nil, scene: scene, radius: 40).count, 1)
    }

    func testQuickWingsHasNoGraceAndNoFingerArea() {
        let scene = CGSize(width: 400, height: 700), hoop = CGPoint(x: 200, y: 350)
        var q = make(.quickWings), g = make(.gentle)
        let v = visitor(90, "monarch", x: (200 + 44) / 400.0, y: 0.5)          // 44 pt: outside 40, inside 40 + 6
        q.visitors = [v]; g.visitors = [v]
        XCTAssertEqual(q.catchSwept(from: hoop, to: hoop, finger: hoop, scene: scene, radius: 40), [])
        XCTAssertEqual(g.catchSwept(from: hoop, to: hoop, finger: nil, scene: scene, radius: 40).count, 1)
    }

    func testNothingSaysHelloAfterTheRoundEnds() {
        var q = make(.quickWings)
        for _ in 0..<460 { q.tick(0.1) }
        q.visitors = [visitor(90, "monarch", x: 0.5, y: 0.5)]
        let p = CGPoint(x: 200, y: 350)
        XCTAssertEqual(q.catchSwept(from: p, to: p, finger: p, scene: CGSize(width: 400, height: 700), radius: 72), [])
        XCTAssertNil(q.sayHello(toVisitor: 90))
    }

    // MARK: Rewards and the Gentle Net badge

    func testRewardsAreTheSameInEveryPace() {
        let catches = ["monarch", "ladybug", "morpho"]
        var r1 = SplitMix64(seed: 4), r2 = SplitMix64(seed: 4)
        XCTAssertEqual(ButterflyRewards.summary(catches: catches, playsToday: 0, using: &r1),
                       ButterflyRewards.summary(catches: catches, playsToday: 0, using: &r2))
        for pace in ButterflyPace.allCases {
            var m = make(pace)
            m.visitors = [visitor(90, "monarch", x: 0.5, y: 0.5)]
            m.sayHello(toVisitor: 90)
            XCTAssertEqual(m.caught, ["monarch"], "\(pace)")
        }
    }

    func testGentleHellosCountForTheGentleNetBadge() throws {
        let app = try makeApp()
        var g = app.startButterflyGame(seed: 5)
        g.visitors = [visitor(90, "monarch", x: 0.3, y: 0.5, resting: true), visitor(91, "ladybug", x: 0.7, y: 0.5)]
        g.sayHello(toVisitor: 90); g.sayHello(toVisitor: 91)
        let s = app.finishButterflyGame(g)
        XCTAssertEqual(s.gentleHellos, 1)
        XCTAssertEqual(app.badges.progress(of: .gentleHellos), 1)
        XCTAssertEqual(app.badges.progress(of: .catches), 2, "both count for First Catch")
        XCTAssertEqual(app.badges.tier(of: "gentle_net"), 0, "one play no longer earns Gentle Net")
        XCTAssertFalse(app.pendingBadges.map(\.badgeId).contains("gentle_net"))
        app.updateBadges(announce: false) { state, _, t in state.record(.gentleHellos, amount: 8, now: t) }
        var g2 = app.startButterflyGame(seed: 6, wake: true)
        g2.visitors = [visitor(92, "honeybee", x: 0.5, y: 0.5, resting: true)]
        g2.sayHello(toVisitor: 92)
        app.finishButterflyGame(g2, wake: true)
        XCTAssertEqual(app.badges.progress(of: .gentleHellos), 10, "wake games count too")
        XCTAssertEqual(app.badges.tier(of: "gentle_net"), 1, "ten gentle hellos earn bronze")
    }

    func testQuietGardenKeepsTheGentleHelloButNoCount() throws {
        let app = try makeApp(quiet: true)
        var g = app.startButterflyGame(seed: 5)
        g.visitors = [visitor(90, "monarch", x: 0.3, y: 0.5, resting: true)]
        XCTAssertEqual(g.sayHello(toVisitor: 90)?.gentle, true, "the play still happens")
        let s = app.finishButterflyGame(g)
        XCTAssertEqual(s.gentleHellos, 0, "no summary line")
        XCTAssertEqual(app.badges.progress(of: .gentleHellos), 0)
    }

    func testTheCatalogueMovesGentleNetToGentleHellos() throws {
        let def = try XCTUnwrap(try BadgeCatalog.load().first { $0.id == "gentle_net" })
        XCTAssertEqual(def.counter, BadgeCounter.gentleHellos.rawValue)
        XCTAssertEqual(def.thresholds, [10, 40, 100])
        XCTAssertEqual(def.blurb, GentleNetCopy.blurb)
        XCTAssertFalse(BadgeCounter.gentleHellos.isHighWater)
        XCTAssertTrue(BadgeCounter.retired.contains(.butterflyPlays))
    }

    func testEarnedGentleNetTiersStayAfterTheMove() {
        let defs = (try? BadgeCatalog.load()) ?? []
        var old = BadgeState(defs: defs)
        // A garden that earned bronze the old way (one play) keeps it: the unlock date stays.
        var legacy = BadgeState(defs: defs.map { $0.id == "gentle_net" ? BadgeDef(id: $0.id, family: $0.family, counter: "butterflyPlays", thresholds: [1, 10, 30]) : $0 })
        legacy.record(.butterflyPlays, now: clock)
        old = BadgeState(json: legacy.json, defs: defs)
        XCTAssertEqual(old.tier(of: "gentle_net"), 1)
        old.record(.butterflyPlays, now: clock)
        XCTAssertEqual(old.tier(of: "gentle_net"), 1, "progress never goes down")
    }

    // MARK: Copy

    func testTheNewCopyIsKindAndHasNoPressureWords() {
        let lines = GentleNetCopy.all + [VisitorsCopy.quickWings, VisitorsCopy.playBlurbQuick, VisitorsCopy.easierToggle,
                                         VisitorsCopy.easierFootnote, VisitorsCopy.flyingLabel("Monarch"), VisitorsCopy.netHint,
                                         VisitorsCopy.swingAction, VisitorsCopy.sceneLabel]
        let alsoAvoid = ["save", "rescue", "danger", "warning", "alert", "locked", "timer", "countdown", "caught", "capture", "jar"]
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertEqual(SpeedBloomCopy.pressureWords(in: line), [], line)
            for w in alsoAvoid { XCTAssertFalse(line.lowercased().contains(w), "\(line) has \(w)") }
        }
        for line in VisitorsCopy.all + GentleNetCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertTrue(VisitorsCopy.all.contains(VisitorsCopy.quickWings))
        for line in [VisitorsCopy.quickWings, VisitorsCopy.playBlurbQuick, VisitorsCopy.easierFootnote] {
            XCTAssertFalse(line.contains { $0.isNumber }, "no digits, so Quiet Garden needs no variant: \(line)")
        }
        XCTAssertEqual(GentleNetCopy.summary(1), "1 gentle hello"); XCTAssertEqual(GentleNetCopy.summary(3), "3 gentle hellos")
        XCTAssertEqual(GentleNetCopy.restingLabel(name: "Monarch"), "Monarch, resting on a flower")
    }

    // MARK: Tuning guard: a scripted sweeping player

    /// A player who sweeps the net left and right across the sky. Quick wings should feel a little harder, never empty.
    func testSweepingPlayerSimulation() {
        let scene = CGSize(width: 393, height: 715)
        func play(_ pace: ButterflyPace, seed: UInt64) -> Int {
            var m = make(pace, seed: seed, flowers: 6)
            m.setScene(size: scene, perchSpots: ButterflyNet.flowerSpots(count: 6, sceneWidth: 393), perchY: 0.9)
            var net = ButterflyNet(restPoint: CGPoint(x: 300, y: 450))
            let dt = 1.0 / 30
            var t = 0.0
            let r = pace.netRadius(tier: 1)
            while t < 35 && !m.isFinished {
                m.tick(dt); t += dt
                // A slow figure: 2.5 s across, the height drifting over the sky.
                let phase = (t / 2.5).truncatingRemainder(dividingBy: 2)
                let x = (phase < 1 ? phase : 2 - phase) * 353 + 20
                let y = 120 + (sin(t * 0.7) + 1) * 0.5 * 420
                let f = CGPoint(x: x, y: y)
                if !net.isDown { _ = net.touchDown(at: f) } else { net.drag(to: f) }
                if let s = net.step(dt, reduceMotion: false) {
                    _ = m.catchSwept(from: s.from, to: s.to, finger: pace == .quickWings ? nil : f, scene: scene, radius: r)
                }
            }
            return m.caught.count
        }
        var gentle = 0, quick = 0, quickEmpty = 0
        for seed in UInt64(1)...200 {
            gentle += play(.gentle, seed: seed)
            let q = play(.quickWings, seed: seed)
            quick += q
            if q == 0 { quickEmpty += 1 }
        }
        let fewer = 1 - Double(quick) / Double(gentle)
        print("Butterfly tuning: gentle \(Double(gentle) / 200) per round, Quick wings \(Double(quick) / 200) per 35 s, \(Int(fewer * 100))% fewer, \(quickEmpty) empty rounds")
        XCTAssertLessThan(quick, gentle, "Quick wings is a little harder")
        XCTAssertLessThanOrEqual(quickEmpty, 2, "at least one hello in 99% of rounds")
    }
}

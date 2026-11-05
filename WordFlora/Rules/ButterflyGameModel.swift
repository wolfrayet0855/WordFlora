import Foundation

/// The butterfly-catching mini-game (spec section 14): about 35 seconds, no lives, no losses, misses are free.
/// In Calm mode there is no clock: visitors drift at 60% speed and the round ends after 5 hellos or a tap on Done.
/// Positions are normalised (0...1) so the model is independent of screen size. With Reduce Motion, visitors rest on
/// flowers and are simply tapped instead of chased.
struct ButterflyGameModel {
    struct Visitor: Identifiable, Equatable {
        var id: Int
        var speciesId: String
        var x: Double, y: Double
        var vx: Double, vy: Double
        var born: Double
        var resting: Bool
    }

    static let duration = 35.0
    static let restingLifetime = 8.0
    /// Calm mode: no clock; the round ends after this many hellos, or when the player taps Done.
    static let calmCatchGoal = 5
    static let calmSpeed = 0.6

    var visitors: [Visitor] = []
    private(set) var caught: [String] = []
    private(set) var elapsed = 0.0

    private let pool: [String]
    private let maxVisitors: Int
    private let reduceMotion: Bool
    let calm: Bool
    private var endedEarly = false
    private var rng: SplitMix64
    private var nextSpawnAt = 0.4
    private var nextId = 1

    /// Exposed for tests: the simultaneous-visitor cap this game was created with.
    var maxVisitorsForTests: Int { maxVisitors }

    var isFinished: Bool {
        if endedEarly { return true }
        return calm ? caught.count >= Self.calmCatchGoal : elapsed >= Self.duration
    }
    var timeLeft: Double { calm ? .infinity : max(0, Self.duration - elapsed) }
    var showsTimeBar: Bool { !calm }

    init(pool: [String], floweringPlants: Int, reduceMotion: Bool, seed: UInt64, calm: Bool = false) {
        self.calm = calm
        self.pool = pool
        self.maxVisitors = VisitorSpawner.maxVisitors(floweringPlants: floweringPlants)
        self.reduceMotion = reduceMotion
        self.rng = SplitMix64(seed: seed)
    }

    private mutating func unit() -> Double { Double(rng.next() % 10_000) / 10_000 }

    mutating func tick(_ dt: Double) {
        guard !isFinished, dt > 0 else { return }
        elapsed += dt

        while elapsed >= nextSpawnAt && visitors.count < maxVisitors {
            spawn(); nextSpawnAt += 1.2
        }
        if visitors.count >= maxVisitors { nextSpawnAt = max(nextSpawnAt, elapsed + 0.3) }

        for i in visitors.indices where !visitors[i].resting {
            visitors[i].x += visitors[i].vx * dt
            visitors[i].y += (visitors[i].vy + sin((elapsed + Double(visitors[i].id)) * 2.2) * 0.04) * dt * (calm ? Self.calmSpeed : 1)
            visitors[i].y = min(0.85, max(0.1, visitors[i].y))
        }
        visitors.removeAll { v in
            v.resting ? elapsed - v.born > Self.restingLifetime : (v.x < -0.12 || v.x > 1.12)
        }
    }

    private mutating func spawn() {
        guard let species = VisitorSpawner.next(pool: pool, using: &rng) else { return }
        defer { nextId += 1 }
        if reduceMotion {
            visitors.append(Visitor(id: nextId, speciesId: species, x: 0.15 + unit() * 0.7, y: 0.2 + unit() * 0.55, vx: 0, vy: 0, born: elapsed, resting: true))
        } else {
            let fromLeft = unit() < 0.5
            let speed = (0.06 + unit() * 0.08) * (calm ? Self.calmSpeed : 1)
            visitors.append(Visitor(id: nextId, speciesId: species, x: fromLeft ? -0.05 : 1.05, y: 0.15 + unit() * 0.6,
                                    vx: fromLeft ? speed : -speed, vy: (unit() - 0.5) * 0.04, born: elapsed, resting: false))
        }
    }

    /// The player tapped Done: the round ends now and every hello so far counts.
    mutating func finishNow() { endedEarly = true }

    /// Catches the nearest visitor within `radius`. A miss costs nothing.
    @discardableResult
    mutating func catchAt(x: Double, y: Double, radius: Double = 0.1) -> String? {
        guard !isFinished else { return nil }
        var best: (index: Int, distance: Double)?
        for (i, v) in visitors.enumerated() {
            let d = hypot(v.x - x, v.y - y)
            if d <= radius, best == nil || d < best!.distance { best = (i, d) }
        }
        guard let hit = best else { return nil }
        let species = visitors[hit.index].speciesId
        visitors.remove(at: hit.index)
        caught.append(species)
        return species
    }
}

import Foundation

/// The butterfly-catching mini-game (spec section 14): about 35 seconds, no lives, no losses, misses are free.
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

    var visitors: [Visitor] = []
    private(set) var caught: [String] = []
    private(set) var elapsed = 0.0

    private let pool: [String]
    private let maxVisitors: Int
    private let reduceMotion: Bool
    private var rng: SplitMix64
    private var nextSpawnAt = 0.4
    private var nextId = 1

    /// Exposed for tests: the simultaneous-visitor cap this game was created with.
    var maxVisitorsForTests: Int { maxVisitors }

    var isFinished: Bool { elapsed >= Self.duration }
    var timeLeft: Double { max(0, Self.duration - elapsed) }

    init(pool: [String], floweringPlants: Int, reduceMotion: Bool, seed: UInt64) {
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
            visitors[i].y += (visitors[i].vy + sin((elapsed + Double(visitors[i].id)) * 2.2) * 0.04) * dt
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
            let speed = 0.06 + unit() * 0.08
            visitors.append(Visitor(id: nextId, speciesId: species, x: fromLeft ? -0.05 : 1.05, y: 0.15 + unit() * 0.6,
                                    vx: fromLeft ? speed : -speed, vy: (unit() - 0.5) * 0.04, born: elapsed, resting: false))
        }
    }

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

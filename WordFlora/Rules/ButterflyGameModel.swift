import Foundation
import CoreGraphics

/// The butterfly-catching mini-game (spec section 14): no lives, no losses, misses are free.
/// The pace (`ButterflyPace`, docs/pm/butterfly-net-spec.md) sets the round: 35 s gentle, 45 s Quick wings (13 and up),
/// and in Calm mode no clock: visitors drift at 60% speed and the round ends after 5 hellos or a tap on Done.
/// Positions are normalised (0...1) so the model is independent of screen size; the net's hit test gets the scene size.
/// With Reduce Motion, visitors rest on flowers and are simply tapped instead of chased.
///
/// Gentle Net (docs/pm/badge-mechanics-art.md section 2): a flying visitor may land on a flower once (1 in 3, seeded)
/// and rest there; only one visitor rests at a time. A hello to a resting visitor is a gentle hello.
struct ButterflyGameModel {
    /// A visitor's one move, drawn from the seed when it arrives. Never more than one.
    enum Move: Equatable {
        case straight
        /// Lands on the nearest flower when it reaches `atX` (if no other visitor is resting then; else it flies on).
        case perch(atX: Double)
        /// Quick wings only: at `atX` it shows its flared idle frame at half speed for 0.4 s (the tell), then swerves
        /// 30 to 40 degrees up or down for 0.8 s and levels out. Never a reversal, never near an edge.
        case turn(atX: Double, up: Bool, degrees: Double)
    }

    enum Phase: Equatable { case flying, tell, swerve, landing, perched, takeoff }

    struct Visitor: Identifiable, Equatable {
        var id: Int
        var speciesId: String
        var x: Double, y: Double
        var vx: Double, vy: Double
        var born: Double
        var resting: Bool
        var move: Move = .straight
        var phase: Phase = .flying
        var phaseAt = 0.0
        /// When a landed visitor flies on (nil for Reduce Motion's resting visitors and for flying ones).
        var landedUntil: Double?
        var fromX = 0.0, fromY = 0.0, toX = 0.0, toY = 0.0
        var swerveVY = 0.0

        /// Wings flared (the idle art): resting, landing, or the turn's tell.
        var showsIdle: Bool { resting || phase == .tell || phase == .landing || phase == .perched }
    }

    /// One hello: who, whether it was a gentle one (the visitor was resting), and where (normalised).
    struct Hello: Equatable {
        var speciesId: String
        var gentle: Bool
        var x: Double, y: Double
    }

    /// The gentle round's length (kept for older callers); each round's own length is `roundSeconds`.
    static let duration = 35.0
    static let restingLifetime = 8.0
    /// Calm mode: no clock; the round ends after this many hellos, or when the player taps Done.
    static let calmCatchGoal = 5
    static let calmSpeed = 0.6
    /// Gentle Net: the chance a flying visitor lands once.
    static let landChance = 1.0 / 3.0
    /// Quick wings: the chance a visitor that does not land swerves once.
    static let turnChance = 0.5
    static let tellSeconds = 0.4
    static let swerveSeconds = 0.8
    static let landingSeconds = 0.6
    static let takeoffSeconds = 0.4
    /// Moves start at least this far from either edge (in widths).
    static let edgeKeepOut = 0.1
    /// Where landed visitors sit when the scene has not said where its flowers are.
    static let defaultPerchY = 0.86

    var visitors: [Visitor] = []
    private(set) var caught: [String] = []
    /// Hellos to resting visitors (Gentle Net), also in `caught`.
    private(set) var caughtGently: [String] = []
    private(set) var elapsed = 0.0
    /// Quick wings: the net is lifted after a hello until this time.
    private(set) var helloReadyAt = 0.0

    let pace: ButterflyPace
    let roundSeconds: Double
    private let pool: [String]
    private let maxVisitors: Int
    private let reduceMotion: Bool
    private var endedEarly = false
    private var rng: SplitMix64
    private var nextSpawnAt = 0.4
    private var nextId = 1
    /// The scene's flowers (fractions of the width) and the height landed visitors sit at; set by the view.
    private(set) var perchSpots: [Double] = []
    private(set) var perchY = defaultPerchY
    /// Width over height of the scene, so a swerve's angle is true on screen.
    private(set) var aspect = 390.0 / 700.0

    var calm: Bool { pace == .calm }

    /// Exposed for tests: the simultaneous-visitor cap this game was created with.
    var maxVisitorsForTests: Int { maxVisitors }

    var isFinished: Bool {
        if endedEarly { return true }
        return calm ? caught.count >= Self.calmCatchGoal : elapsed >= roundSeconds
    }
    var timeLeft: Double { calm ? .infinity : max(0, roundSeconds - elapsed) }
    var showsTimeBar: Bool { !calm }
    /// Only one visitor rests (or is landing) at a time.
    var hasRestingVisitor: Bool { visitors.contains { $0.phase == .landing || $0.phase == .perched } }

    /// `roundSeconds` overrides the pace's round (UI tests use a short round).
    init(pool: [String], floweringPlants: Int, reduceMotion: Bool, seed: UInt64, pace: ButterflyPace, roundSeconds: Double? = nil) {
        self.pace = pace
        self.roundSeconds = roundSeconds ?? pace.roundSeconds
        self.pool = pool
        self.maxVisitors = VisitorSpawner.maxVisitors(floweringPlants: floweringPlants)
        self.reduceMotion = reduceMotion
        self.rng = SplitMix64(seed: seed)
    }

    /// The gentle game, or Calm.
    init(pool: [String], floweringPlants: Int, reduceMotion: Bool, seed: UInt64, calm: Bool = false) {
        self.init(pool: pool, floweringPlants: floweringPlants, reduceMotion: reduceMotion, seed: seed, pace: calm ? .calm : .gentle)
    }

    /// The scene tells the game where its flowers are and its shape (once per round, and on a resize).
    mutating func setScene(size: CGSize, perchSpots: [Double], perchY: Double) {
        if size.width > 0, size.height > 0 { aspect = Double(size.width / size.height) }
        self.perchSpots = perchSpots
        self.perchY = perchY
    }

    private mutating func unit() -> Double { Double(rng.next() % 10_000) / 10_000 }

    mutating func tick(_ dt: Double) {
        guard !isFinished, dt > 0 else { return }
        elapsed += dt

        while elapsed >= nextSpawnAt && visitors.count < maxVisitors {
            spawn(); nextSpawnAt += pace.spawnGap
        }
        if visitors.count >= maxVisitors { nextSpawnAt = max(nextSpawnAt, elapsed + 0.3) }

        for i in visitors.indices where !(visitors[i].resting && visitors[i].landedUntil == nil) {
            advance(i, dt)
        }
        visitors.removeAll { v in
            (v.resting && v.landedUntil == nil) ? elapsed - v.born > Self.restingLifetime : (v.x < -0.12 || v.x > 1.12)
        }
    }

    private func crossed(_ v: Visitor, _ atX: Double) -> Bool { v.vx >= 0 ? v.x >= atX : v.x <= atX }

    private mutating func advance(_ i: Int, _ dt: Double) {
        var v = visitors[i]
        let bob = sin((elapsed + Double(v.id)) * 2.2) * 0.04
        switch v.phase {
        case .flying:
            v.x += v.vx * dt
            v.y += (v.vy + bob) * dt * pace.speedFactor
            v.y = min(0.85, max(0.1, v.y))
            switch v.move {
            case .straight: break
            case .perch(let atX) where crossed(v, atX):
                if hasRestingVisitor {
                    v.move = .straight                  // one at a time: it flies on, with no message
                } else {
                    v.phase = .landing; v.phaseAt = elapsed
                    v.fromX = v.x; v.fromY = v.y
                    v.toX = perchSpots.min(by: { abs($0 - v.x) < abs($1 - v.x) }) ?? min(0.85, max(0.15, v.x))
                    v.toY = perchY
                }
            case .turn(let atX, _, _) where crossed(v, atX):
                v.phase = .tell; v.phaseAt = elapsed
            default: break
            }
        case .tell:
            v.x += v.vx * 0.5 * dt
            if elapsed - v.phaseAt >= Self.tellSeconds, case .turn(_, let up, let degrees) = v.move {
                v.phase = .swerve; v.phaseAt = elapsed
                v.swerveVY = (up ? -1 : 1) * tan(degrees * .pi / 180) * abs(v.vx) * aspect
            }
        case .swerve:
            v.x += v.vx * dt
            v.y = min(0.85, max(0.1, v.y + v.swerveVY * dt))
            if elapsed - v.phaseAt >= Self.swerveSeconds { v.phase = .flying; v.move = .straight }
        case .landing:
            let t = min(1, (elapsed - v.phaseAt) / Self.landingSeconds), e = 1 - (1 - t) * (1 - t)
            v.x = v.fromX + (v.toX - v.fromX) * e
            v.y = v.fromY + (v.toY - v.fromY) * e
            if t >= 1 { v.phase = .perched; v.phaseAt = elapsed; v.resting = true; v.landedUntil = elapsed + pace.perchSeconds }
        case .perched:
            if let until = v.landedUntil, elapsed >= until {
                v.phase = .takeoff; v.phaseAt = elapsed; v.resting = false; v.move = .straight
                v.fromY = v.y
            }
        case .takeoff:
            let t = min(1, (elapsed - v.phaseAt) / Self.takeoffSeconds)
            v.x += v.vx * t * dt
            v.y = v.fromY + (0.78 - v.fromY) * t
            if t >= 1 { v.phase = .flying; v.landedUntil = nil }
        }
        visitors[i] = v
    }

    private mutating func spawn() {
        guard let species = VisitorSpawner.next(pool: pool, using: &rng) else { return }
        defer { nextId += 1 }
        if reduceMotion {
            visitors.append(Visitor(id: nextId, speciesId: species, x: 0.15 + unit() * 0.7, y: 0.2 + unit() * 0.55, vx: 0, vy: 0, born: elapsed, resting: true))
        } else {
            let fromLeft = unit() < 0.5
            let speed = (0.06 + unit() * 0.08) * pace.speedFactor
            var v = Visitor(id: nextId, speciesId: species, x: fromLeft ? -0.05 : 1.05, y: 0.15 + unit() * 0.6,
                            vx: fromLeft ? speed : -speed, vy: (unit() - 0.5) * 0.04, born: elapsed, resting: false)
            // The new draws come after today's, so the same seed still gives the same visitors and paths.
            v.move = drawMove(fromLeft: fromLeft)
            visitors.append(v)
        }
    }

    /// Perch 1 in 3; else, in Quick wings only, a turn 1 in 2; else straight. Positions are along the flight, inside
    /// the edges: a perch between 0.2 and 0.8, a turn between 0.2 and 0.7 (so the swerve ends inside 0.9).
    private mutating func drawMove(fromLeft: Bool) -> Move {
        func along(_ d: Double) -> Double { fromLeft ? d : 1 - d }
        if unit() < Self.landChance { return .perch(atX: along(0.2 + unit() * 0.6)) }
        guard pace.turns, unit() < Self.turnChance else { return .straight }
        let at = along(0.2 + unit() * 0.5)
        return .turn(atX: at, up: unit() < 0.5, degrees: 30 + unit() * 10)
    }

    /// The player tapped Done: the round ends now and every hello so far counts.
    mutating func finishNow() { endedEarly = true }

    /// Catches the nearest visitor within `radius` (normalised units, today's maths). A miss costs nothing.
    /// Used by VoiceOver, Switch Control and the wake game.
    @discardableResult
    mutating func catchAt(x: Double, y: Double, radius: Double = 0.1) -> String? {
        guard !isFinished else { return nil }
        var best: (index: Int, distance: Double)?
        for (i, v) in visitors.enumerated() {
            let d = hypot(v.x - x, v.y - y)
            if d <= radius, best == nil || d < best!.distance { best = (i, d) }
        }
        guard let hit = best else { return nil }
        return sayHello(at: hit.index).speciesId
    }

    /// The last hello was a gentle one (the visitor was resting).
    var lastHelloWasGentle: Bool { lastGentle }
    private var lastGentle = false

    /// VoiceOver: the net swings to this visitor and says hello (no aiming needed).
    @discardableResult
    mutating func sayHello(toVisitor id: Int) -> Hello? {
        guard !isFinished, let i = visitors.firstIndex(where: { $0.id == id }) else { return nil }
        return sayHello(at: i)
    }

    /// The net's sweep from `a` to `b` (scene points; a == b for a tap). Gentle: every visitor inside today's area
    /// around `finger` or the hoop's sweep (radius + 6 pt) says hello. Quick wings: the hoop only, the nearest one, and
    /// then the net lifts for 0.25 s. `radius` is the hoop in points for this pace and tier.
    mutating func catchSwept(from a: CGPoint, to b: CGPoint, finger: CGPoint?, scene: CGSize, radius: Double) -> [Hello] {
        guard !isFinished, scene.width > 0, scene.height > 0 else { return [] }
        if pace.oneHelloPerSweep && elapsed < helloReadyAt { return [] }
        func point(_ v: Visitor) -> CGPoint { CGPoint(x: v.x * Double(scene.width), y: v.y * Double(scene.height)) }
        var hits = [(index: Int, distance: Double)]()
        for (i, v) in visitors.enumerated() {
            let p = point(v)
            let hit = pace == .quickWings
                ? NetGeometry.quickHit(visitor: p, from: a, to: b, radius: radius)
                : NetGeometry.gentleHit(visitor: p, finger: finger, from: a, to: b, scene: scene, radius: radius)
            if hit { hits.append((i, NetGeometry.distance(from: p, toSegment: a, b))) }
        }
        guard !hits.isEmpty else { return [] }
        let chosen = pace.oneHelloPerSweep ? [hits.min { $0.distance < $1.distance }!] : hits
        var hellos = [Hello]()
        for index in chosen.map(\.index).sorted(by: >) { hellos.append(sayHello(at: index)) }
        if pace.oneHelloPerSweep { helloReadyAt = elapsed + pace.helloPause }
        return Array(hellos.reversed())
    }

    private mutating func sayHello(at index: Int) -> Hello {
        let v = visitors.remove(at: index)
        caught.append(v.speciesId)
        if v.resting { caughtGently.append(v.speciesId) }
        lastGentle = v.resting
        return Hello(speciesId: v.speciesId, gentle: v.resting, x: v.x, y: v.y)
    }
}

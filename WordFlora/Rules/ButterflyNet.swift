import Foundation
import CoreGraphics

/// How a butterfly round plays (docs/pm/butterfly-net-spec.md section 1). Decided once, when the round starts.
/// Under 13 (and an unknown age) never gets Quick wings; Calm, the wake game and the assistive settings keep the gentle game.
enum ButterflyPace: String, CaseIterable {
    /// Calm mode: no clock, slower visitors, the round ends after 5 hellos or Done.
    case calm
    /// Today's game, with the net. Under 13, unknown age, wake games, Reduce Motion, VoiceOver, Switch Control, Easier butterflies.
    case gentle
    /// 13 and up: a little quicker visitors that may swerve once, a smaller hoop, a longer round.
    case quickWings

    struct Context: Equatable {
        var calmMode = false
        var wake = false
        var reduceMotion = false
        var voiceOver = false
        var switchControl = false
        var ageBand: AgeBand?
        var easierButterflies = false
    }

    /// First match wins. A wake game keeps its own gentle tuning even in Calm (as it always has).
    static func resolve(_ c: Context) -> ButterflyPace {
        if c.wake { return .gentle }
        if c.calmMode { return .calm }
        if c.reduceMotion || c.voiceOver || c.switchControl { return .gentle }
        guard isQuickWingsAge(c.ageBand) else { return .gentle }
        if c.easierButterflies { return .gentle }
        return .quickWings
    }

    static func isQuickWingsAge(_ band: AgeBand?) -> Bool { band == .thirteenPlus || band == .eighteenPlus }

    /// Settings shows "Easier butterflies" only where Quick wings could apply: 13 and up, with Calm off.
    static func offersEasierSwitch(ageBand: AgeBand?, calmMode: Bool) -> Bool { isQuickWingsAge(ageBand) && !calmMode }

    /// Round length in seconds. Calm has no clock. Quick wings is 10 s longer, never shorter.
    var roundSeconds: Double {
        switch self { case .calm: return .infinity; case .gentle: return 35; case .quickWings: return 45 }
    }
    /// Visitor speed against today's gentle game (0.06 to 0.14 widths a second).
    var speedFactor: Double {
        switch self { case .calm: return 0.6; case .gentle: return 1; case .quickWings: return 1.3 }
    }
    /// Seconds between new visitors (faster visitors cross sooner, so the sky stays as full).
    var spawnGap: Double { self == .quickWings ? 1.0 : 1.2 }
    /// How long a landed visitor rests on its flower (Gentle Net). Calm gets more time: 3 s / 0.6.
    var perchSeconds: Double {
        switch self { case .calm: return 5; case .gentle: return 3; case .quickWings: return 2 }
    }
    /// Only Quick wings visitors may swerve (once, after a 0.4 s tell).
    var turns: Bool { self == .quickWings }
    /// After a hello the Quick wings net lifts for this long before it can say hello again.
    var helloPause: Double { self == .quickWings ? 0.25 : 0 }
    /// Extra points around the hoop that still count (gentle only).
    var hoopGrace: Double { self == .quickWings ? 0 : NetGeometry.gentleGrace }
    /// Gentle: every visitor in the sweep says hello. Quick wings: one per sweep.
    var oneHelloPerSweep: Bool { self == .quickWings }

    /// The hoop radius in points (the drawn hoop is exactly this): 48 / 64 / 80, or 40 / 56 / 72 in Quick wings.
    func netRadius(tier: Int) -> Double { ToolEngine.netCatchRadius(tier: tier, pace: self) }
}

/// Hit tests for the net, in scene points (spec section 2). The hoop is a true circle; a drag is tested as the capsule
/// between the hoop's last two centres, so a quick swipe cannot jump over a visitor.
enum NetGeometry {
    /// Gentle hoops count this many points past the rim.
    static let gentleGrace = 6.0
    /// Today's catch radius floor, in scene-width units (kept verbatim for the gentle game).
    static let legacyFloor = 0.08

    /// Distance from `p` to the segment a-b (a point when a == b).
    static func distance(from p: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> Double {
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        let len2 = dx * dx + dy * dy
        var t = 0.0
        if len2 > 0 { t = min(1, max(0, (Double(p.x - a.x) * dx + Double(p.y - a.y) * dy) / len2)) }
        let cx = Double(a.x) + t * dx, cy = Double(a.y) + t * dy
        return hypot(Double(p.x) - cx, Double(p.y) - cy)
    }

    /// Inclusive at the rim.
    static func segmentHit(_ p: CGPoint, from a: CGPoint, to b: CGPoint, radius: Double) -> Bool {
        distance(from: p, toSegment: a, b) <= radius
    }

    /// Today's catch test, kept verbatim: both points normalised by the scene's width (x) and height (y), the distance
    /// taken in those units, against the tier radius over the width with a 0.08 floor. Returns that distance on a hit.
    /// Do not "clean this up": it is what makes the gentle game never harder than before (spec section 10).
    static func legacyDistance(visitor v: CGPoint, finger f: CGPoint, scene: CGSize, tierRadius: Double) -> Double? {
        guard scene.width > 0, scene.height > 0 else { return nil }
        let radius = max(legacyFloor, tierRadius / Double(scene.width))
        let d = hypot(Double(v.x / scene.width) - Double(f.x / scene.width), Double(v.y / scene.height) - Double(f.y / scene.height))
        return d <= radius ? d : nil
    }

    /// The gentle rule: today's area around the finger OR the hoop's sweep with its grace. Always contains today's area.
    static func gentleHit(visitor v: CGPoint, finger: CGPoint?, from a: CGPoint, to b: CGPoint, scene: CGSize, radius: Double) -> Bool {
        if let finger, legacyDistance(visitor: v, finger: finger, scene: scene, tierRadius: radius) != nil { return true }
        return segmentHit(v, from: a, to: b, radius: radius + gentleGrace)
    }

    /// The Quick wings rule: the hoop only, a true circle in points, no floor (so tiers mean the same on every screen).
    static func quickHit(visitor v: CGPoint, from a: CGPoint, to b: CGPoint, radius: Double) -> Bool {
        segmentHit(v, from: a, to: b, radius: radius)
    }
}

/// The net the player holds (spec section 2), in scene points. Pure: the view feeds it touches and ticks.
struct ButterflyNet: Equatable {
    /// The hoop trails the finger with this time constant (a held net, a few points behind).
    static let lagSeconds = 0.06
    /// After a lift the net glides back to its rest point over about this long.
    static let returnSeconds = 0.3
    /// The resting net's lowest point stays at least this far above the "said hello" pill.
    static let pillClearance = 24.0
    /// Never in the left 20 pt (the back-swipe edge) or under the right edge.
    static let edgeMargin = 20.0
    /// The resting net is drawn a little see-through.
    static let restingOpacity = 0.85

    var position: CGPoint
    var target: CGPoint
    var isDown = false
    var restPoint: CGPoint
    /// Where the finger last lifted; the rest point follows it (thumb reach for either hand).
    var lastLift: CGPoint?

    init(restPoint: CGPoint) {
        self.restPoint = restPoint
        position = restPoint; target = restPoint
    }

    /// Where the net waits: bottom right by default, else where the finger last lifted, kept in the lower half, clear of
    /// the left edge, and with the hoop's bottom at least `pillClearance` above the pill (that wins on a short scene).
    static func restPoint(scene: CGSize, radius: Double, pillTop: Double?, lastLift: CGPoint?) -> CGPoint {
        let w = Double(scene.width), h = Double(scene.height)
        let minX = edgeMargin + radius, maxX = max(minX, w - radius - 12)
        let lowest = (pillTop ?? h * 0.8) - pillClearance - radius
        let highest = min(h / 2, lowest)
        let x = lastLift.map { min(maxX, max(minX, Double($0.x))) } ?? maxX
        let y = lastLift.map { min(lowest, max(highest, Double($0.y))) } ?? lowest
        return CGPoint(x: x, y: y)
    }

    /// Touch down is a scoop: the hoop jumps under the finger (no travel across the sky) and tests that one point.
    @discardableResult
    mutating func touchDown(at p: CGPoint) -> (from: CGPoint, to: CGPoint) {
        isDown = true; position = p; target = p
        return (p, p)
    }

    mutating func drag(to p: CGPoint) { target = p }

    /// Lift: the net goes home. Nothing is tested on the way (no accidental hellos).
    mutating func lift() {
        guard isDown else { return }
        isDown = false
        lastLift = target
    }

    /// One frame. While held, returns the swept segment to test; while resting or gliding home, nil.
    /// Reduce Motion: no lag and no glide (the net is a still frame that jumps with the finger).
    mutating func step(_ dt: Double, reduceMotion: Bool) -> (from: CGPoint, to: CGPoint)? {
        guard dt > 0 else { return nil }
        if isDown {
            let from = position
            position = reduceMotion ? target : Self.ease(position, toward: target, dt: dt, tau: Self.lagSeconds)
            return (from, position)
        }
        position = reduceMotion ? restPoint : Self.ease(position, toward: restPoint, dt: dt, tau: Self.returnSeconds / 3)
        return nil
    }

    var isResting: Bool { !isDown && hypot(Double(position.x - restPoint.x), Double(position.y - restPoint.y)) < 1 }

    private static func ease(_ p: CGPoint, toward t: CGPoint, dt: Double, tau: Double) -> CGPoint {
        let k = 1 - exp(-dt / tau)
        return CGPoint(x: Double(p.x) + Double(t.x - p.x) * k, y: Double(p.y) + Double(t.y - p.y) * k)
    }

    /// The handle points from the hoop toward the nearer bottom corner, so it never covers the visitor being chased.
    static func handlePointsRight(hoopX: Double, sceneWidth: Double) -> Bool { hoopX >= sceneWidth / 2 }

    /// Where the flowers along the garden bed stand (the scene draws up to six, 74 pt tall with -6 pt spacing, centred),
    /// as fractions of the width. Landed visitors rest on the nearest one.
    static func flowerSpots(count: Int, sceneWidth: Double, pitch: Double = 68) -> [Double] {
        guard count > 0, sceneWidth > 0 else { return [] }
        let mid = sceneWidth / 2
        return (0..<count).map { i in (mid + (Double(i) - Double(count - 1) / 2) * pitch) / sceneWidth }
    }
}

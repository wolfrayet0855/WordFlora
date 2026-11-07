import SwiftUI

// The four one-shot tend effects drawn over the plant (design-preview/tending/actions.html, section 3):
// water pour, soil scoop, sun glisten and repot. Each plays once per successful tap, is under 2 seconds, and a new
// tap replaces the one playing (never stacks). Reduce Motion (and Low Power Mode) get a short fade and glow instead.
// Taps pass through the overlay to the plant. Coordinates are the mockup's 220 point plant box, scaled to the plant.

// MARK: Model

enum TendEffect: String, CaseIterable, Equatable {
    case water, soil, sun, repot

    /// Feed plays the soil scoop. Prune has no storyboard (its snip sound and toast are enough).
    init?(_ action: AppModel.TendAction) {
        switch action {
        case .water: self = .water
        case .feed: self = .soil
        case .sun: self = .sun
        case .repot: self = .repot
        case .prune, .mist: return nil          // the mist has its own spray (MistSprayView)
        }
    }

    /// Seconds for the full storyboard, from the mockup.
    var duration: Double {
        switch self {
        case .water: return 1.8
        case .soil: return 1.9
        case .sun: return 1.8
        case .repot: return 1.9
        }
    }

    /// Reduce Motion: a 0.4 s fade in, a short hold, a 0.4 s fade out.
    static let calmDuration = 1.2

    func duration(calm: Bool) -> Double { calm ? Self.calmDuration : duration }

    var sound: SoundEvent {
        switch self {
        case .water: return .water
        case .soil, .repot: return .soil
        case .sun: return .sun
        }
    }

    /// The UI test identifier of the overlay while it plays.
    var identifier: String { "tend-anim-\(rawValue)" }

    /// What VoiceOver hears if it lands on the overlay while it plays.
    var spokenLabel: String {
        switch self {
        case .water: return "Pouring water"
        case .soil: return "Adding fresh soil"
        case .sun: return "The sun comes out"
        case .repot: return "Moving to a new pot"
        }
    }
}

/// The pot a repot plays with, drawn from `PotCatalog` (design-preview/pots/pots.json).
struct TendPot: Equatable, Hashable {
    let pot: Pot

    init(_ pot: Pot) { self.pot = pot }
    /// Empty and unknown ids are plain blue.
    init(id: String) { pot = PotCatalog.pot(id: id) }

    static let plainBlue = TendPot(PotCatalog.plainBlue)
    static var allCases: [TendPot] { PotCatalog.all.map(TendPot.init) }

    var id: String { pot.id }
    var name: String { pot.name }
    var body: Color { PotPainter.color(pot.body) }
    var rim: Color { PotPainter.color(pot.rim) }
    var shade: Color { PotPainter.color(pot.shade) }
}

/// One play of one effect.
struct TendPlay: Equatable {
    let effect: TendEffect
    /// The pot the plant moves into, and the one it leaves (a repot slides one out and the other in).
    var pot: TendPot = .plainBlue
    var from: TendPot = .plainBlue
    let startedAt: Date
    let id: Int
}

/// Holds at most one play. A new tap replaces the current one, so effects never stack.
struct TendSequencer: Equatable {
    private(set) var current: TendPlay?
    private var count = 0

    @discardableResult
    mutating func start(_ effect: TendEffect, pot: TendPot = .plainBlue, from: TendPot = .plainBlue, at date: Date) -> TendPlay {
        count += 1
        let play = TendPlay(effect: effect, pot: pot, from: from, startedAt: date, id: count)
        current = play
        return play
    }

    /// Clears the play once it has ended, unless a newer one replaced it.
    mutating func finish(id: Int) { if current?.id == id { current = nil } }

    /// The play still on screen at `date`, or nil when it has finished.
    func active(at date: Date, calm: Bool, hold: Bool = TendMotion.uiTestHold) -> TendPlay? {
        guard let current else { return nil }
        return date.timeIntervalSince(current.startedAt) < TendMotion.lifetime(current.effect, calm: calm, hold: hold) ? current : nil
    }
}

/// Pure timeline maths for the effects, so tests can check timing without rendering.
enum TendMotion {
    /// UI tests freeze each play at its middle frame for a few seconds (`-uitest-tend-hold`), for a mid-animation shot.
    static let uiTestHold = ProcessInfo.processInfo.arguments.contains("-uitest-tend-hold")
    static let holdSeconds = 4.0

    static func midpoint(_ effect: TendEffect, calm: Bool) -> Double { calm ? 0.6 : effect.duration * 0.55 }

    /// How long the play stays on screen, including a UI test hold.
    static func lifetime(_ effect: TendEffect, calm: Bool, hold: Bool) -> Double {
        effect.duration(calm: calm) + (hold ? holdSeconds : 0)
    }

    /// The storyboard time for `elapsed` real seconds.
    static func localTime(elapsed: Double, effect: TendEffect, calm: Bool, hold: Bool) -> Double {
        let e = max(0, elapsed)
        guard hold else { return e }
        let mid = midpoint(effect, calm: calm)
        if e < mid { return e }
        if e < mid + holdSeconds { return mid }
        return e - holdSeconds
    }

    // MARK: Plant pose

    struct PlantPose: Equatable {
        var scaleX = 1.0
        var scaleY = 1.0
        var rotation = 0.0
        /// Upward lift in plant box points (negative is up).
        var lift = 0.0
        static let rest = PlantPose()
    }

    /// The plant's own motion: a soft drink for water and soil, a flutter for sun, a lift and settle for repot.
    static func plantPose(_ effect: TendEffect, t: Double, calm: Bool) -> PlantPose {
        if calm { return .rest }
        switch effect {
        case .water: return drink(window(t, 1.05, 0.5))
        case .soil: return drink(window(t, 1.45, 0.45))
        case .sun:
            let f = window(t, 0.28, 1.35)
            guard f > 0 && f < 1 else { return .rest }
            let r = track([(0, [0, 1]), (0.14, [3.2, 1.01]), (0.30, [-2.8, 1]), (0.46, [2.2, 1]), (0.62, [-1.5, 1]),
                           (0.78, [0.8, 1]), (1, [0, 1])], f, ease: easeInOut)
            return PlantPose(scaleX: r[1], scaleY: r[1], rotation: r[0])
        case .repot:
            let f = min(max(t / effect.duration, 0), 1)
            let k: [(Double, [Double])] = [(0, [0, 1, 1]), (0.18, [-56, 1, 1]), (0.48, [-56, 1, 1]), (0.62, [0, 1, 1]),
                                           (0.74, [0, 1, 1]), (0.84, [0, 1.03, 0.97]), (1, [0, 1, 1])]
            let eases: [(Double) -> Double] = [easeOut, linear, backOut, easeInOut, easeInOut, easeInOut]
            let r = track(k, f, eases: eases)
            return PlantPose(scaleX: r[1], scaleY: r[2], lift: r[0])
        }
    }

    private static func drink(_ f: Double) -> PlantPose {
        guard f > 0 && f < 1 else { return .rest }
        let r = track([(0, [1, 1]), (0.35, [1.04, 0.97]), (0.7, [0.99, 1.035]), (1, [1, 1])], f, ease: easeInOut)
        return PlantPose(scaleX: r[0], scaleY: r[1])
    }

    // MARK: Helpers

    /// 0 before `start`, 1 after `start + length`, linear between.
    static func window(_ t: Double, _ start: Double, _ length: Double) -> Double { min(max((t - start) / length, 0), 1) }

    static func linear(_ x: Double) -> Double { x }
    static func easeIn(_ x: Double) -> Double { x * x * x }
    static func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    static func easeInOut(_ x: Double) -> Double { x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2 }
    /// Overshoots a little and settles back (the sun's pop, the plant lowering into its pot).
    static func backOut(_ x: Double) -> Double { let c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2) }

    /// Interpolates keyframes; `eases[i]` shapes the segment that starts at key i.
    static func track(_ keys: [(Double, [Double])], _ f: Double, ease: (Double) -> Double = easeInOut, eases: [(Double) -> Double]? = nil) -> [Double] {
        guard let first = keys.first, let last = keys.last else { return [] }
        if f <= first.0 { return first.1 }
        if f >= last.0 { return last.1 }
        for i in 0..<(keys.count - 1) where f >= keys[i].0 && f <= keys[i + 1].0 {
            let a = keys[i], b = keys[i + 1]
            let span = b.0 - a.0
            let local = span > 0 ? (f - a.0) / span : 1
            let e = eases.map { $0[i](local) } ?? ease(local)
            return zip(a.1, b.1).map { $0 + ($1 - $0) * e }
        }
        return last.1
    }
}

// MARK: Plant motion

/// Applies the play's plant pose (drink, flutter, lift) to the plant itself.
struct TendPlantMotion: ViewModifier {
    let play: TendPlay?
    let size: CGFloat
    let calm: Bool

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: play == nil || calm)) { ctx in
            let pose = play.map { p in
                TendMotion.plantPose(p.effect, t: TendMotion.localTime(elapsed: ctx.date.timeIntervalSince(p.startedAt), effect: p.effect,
                                                                      calm: calm, hold: TendMotion.uiTestHold), calm: calm)
            } ?? .rest
            content
                .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: UnitPoint(x: 0.5, y: 0.88))
                .rotationEffect(.degrees(pose.rotation), anchor: UnitPoint(x: 0.5, y: 0.88))
                .offset(y: pose.lift * size / 220)
        }
    }
}

extension View {
    func tendMotion(_ play: TendPlay?, size: CGFloat, calm: Bool) -> some View { modifier(TendPlantMotion(play: play, size: size, calm: calm)) }
}

// MARK: Overlay

/// The effect actors (can, drops, trowel, sun, sparkles, pots) over a plant box of `size` points.
/// Lay it out on the plant's own frame: it draws past its edges and never takes taps.
struct TendAnimationView: View {
    let play: TendPlay?
    let size: CGFloat
    var calm = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Color.clear
            .frame(width: size, height: size)
            .overlay {
                if let play {
                    TimelineView(.animation) { ctx in
                        let t = TendMotion.localTime(elapsed: ctx.date.timeIntervalSince(play.startedAt), effect: play.effect, calm: calm,
                                                     hold: TendMotion.uiTestHold)
                        Canvas { gc, _ in
                            var g = gc
                            g.translateBy(x: size * Self.margin, y: size * Self.margin)
                            g.scaleBy(x: size / 220, y: size / 220)
                            TendScene(play: play, t: t, dark: scheme == .dark).draw(in: g, calm: calm)
                        }
                    }
                    .frame(width: size * (1 + 2 * Self.margin), height: size * (1 + 2 * Self.margin))
                    .id(play.id)
                    .accessibilityElement()
                    .accessibilityLabel(play.effect.spokenLabel)
                    .accessibilityAddTraits(.isImage)
                    .accessibilityIdentifier(play.effect.identifier)
                }
            }
            .allowsHitTesting(false)
    }

    /// The canvas reaches this far past the plant box on every side (the can and sun start outside it).
    static let margin: CGFloat = 0.45

    /// The stage pot in 220 pt plant box points (actions.html and pots/index.html: 140 pt wide, its top 179 points
    /// down the plant box). The plant page draws the plant's pot here and the repot effect slides pots in and out of it.
    static let potRect = CGRect(x: 40, y: 179, width: 140, height: 140 * 100 / 120)
    /// The soil top inside that pot, where the plant's ground shadow is kept.
    static let soilRect = CGRect(x: 70, y: 185, width: 80, height: 20)
    /// The floor shadow under the pot.
    static let floorShadowRect = CGRect(x: 45, y: 285, width: 130, height: 16)
}

// MARK: Drawing

private struct TendScene {
    let play: TendPlay
    let t: Double
    let dark: Bool

    typealias M = TendMotion
    private static let ink = Color(UIColor(hex: 0x3B3B3B))
    private static let soil = Color(UIColor(hex: 0x6B4528))
    private static let soilLight = Color(UIColor(hex: 0x85583A))
    private static let mound = Color(UIColor(hex: 0x7A5238))
    private var dropColor: Color { Color(UIColor(hex: dark ? 0x7DB6EE : 0x4C93D6)) }

    func draw(in g: GraphicsContext, calm: Bool) {
        if calm { drawCalm(g); return }
        switch play.effect {
        case .water: water(g)
        case .soil:
            var m = g; m.translateBy(x: 220, y: 0); m.scaleBy(x: -1, y: 1)   // mirrored: the pile sits clear of the Life panel
            soil(m)
        case .sun: sun(g)
        case .repot: repot(g)
        }
    }

    // MARK: Water: can in from the upper right, tilt, six drops speed up and ripple, soil darkens.

    private func water(_ g: GraphicsContext) {
        let wet = t < 1.33 ? M.window(t, 1.0, 0.33) : 1 - M.window(t, 1.33, 0.47)
        if wet > 0 {
            var w = g; w.opacity = wet
            w.fill(Path(ellipseIn: CGRect(x: 65, y: 178, width: 90, height: 22)), with: .color(Color(red: 40 / 255, green: 60 / 255, blue: 110 / 255).opacity(0.3)))
        }
        for i in 0..<6 {
            let x = 121 + Double(i % 3) * 10 + (i > 2 ? 6 : 0)
            let d = 0.62 + Double(i) * 0.09
            let f = M.window(t, d, 0.46)
            if f > 0 && f < 1 {
                var dg = g
                dg.opacity = f < 0.12 ? f / 0.12 : (f > 0.9 ? (1 - f) / 0.1 : 1)
                let fall = 158 * pow(f, 2.2)
                dg.translateBy(x: x, y: 31 + fall)
                dg.scaleBy(x: 1, y: 0.7 + 0.55 * f)
                dg.fill(Self.dropPath(width: 9, height: 13), with: .color(dropColor))
                dg.fill(Path(ellipseIn: CGRect(x: 4.5, y: 6, width: 2.5, height: 4)), with: .color(.white.opacity(0.5)))
            }
            let r = M.window(t, 1.07 + Double(i) * 0.09, 0.55)
            if r > 0 && r < 1 {
                var rg = g
                let e = M.easeOut(r)
                rg.opacity = 0.95 * (1 - r)
                rg.translateBy(x: x + 4.5, y: 186)
                rg.scaleBy(x: 0.2 + 1.5 * e, y: 0.2 + 1.5 * e)
                let ring = Path(ellipseIn: CGRect(x: -17, y: -6, width: 34, height: 12))
                rg.stroke(ring, with: .color(dropColor.opacity(0.6)), lineWidth: 3.5)
                rg.stroke(ring, with: .color(.white.opacity(0.9)), lineWidth: 2)
            }
        }
        // the can: in 0-0.35 s, tilt 0.35-0.65 s, out 1.45-1.75 s
        var dx = 0.0, dy = 0.0, rot = 0.0, op = 1.0
        if t < 0.35 { let e = M.easeOut(t / 0.35); dx = 70 * (1 - e); dy = -20 * (1 - e); op = e }
        else if t < 0.65 { rot = -30 * M.easeInOut((t - 0.35) / 0.3) }
        else if t < 1.45 { rot = -30 }
        else { let e = M.easeIn(M.window(t, 1.45, 0.3)); dx = 70 * e; dy = -20 * e; rot = -30 + 22 * e; op = 1 - e }
        guard op > 0.01 else { return }
        var c = g
        c.opacity = op
        c.translateBy(x: 140 + 55 + dx, y: -11 + 45 + dy)
        c.rotate(by: .degrees(rot))
        c.translateBy(x: -55, y: -45)
        Self.drawCan(c)
    }

    private static func dropPath(width w: Double, height h: Double) -> Path {
        Path { p in
            p.move(to: CGPoint(x: w / 2, y: 0))
            p.addCurve(to: CGPoint(x: w, y: h * 0.62), control1: CGPoint(x: w * 0.62, y: h * 0.22), control2: CGPoint(x: w, y: h * 0.4))
            p.addArc(center: CGPoint(x: w / 2, y: h * 0.62), radius: w / 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            p.addCurve(to: CGPoint(x: w / 2, y: 0), control1: CGPoint(x: 0, y: h * 0.4), control2: CGPoint(x: w * 0.38, y: h * 0.22))
        }
    }

    private static func drawCan(_ c: GraphicsContext) {
        let green = Color(UIColor(hex: 0x3F7A45)), body = Color(UIColor(hex: 0x5FA05A)), steel = Color(UIColor(hex: 0xC5CED6))
        let handle = Path { p in p.move(to: CGPoint(x: 82, y: 34)); p.addCurve(to: CGPoint(x: 80, y: 66), control1: CGPoint(x: 104, y: 30), control2: CGPoint(x: 104, y: 68)) }
        c.stroke(handle, with: .color(ink), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        c.stroke(handle, with: .color(green), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        let spout = Path { p in p.move(to: CGPoint(x: 30, y: 60)); p.addLine(to: CGPoint(x: 8, y: 22)) }
        c.stroke(spout, with: .color(ink), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        c.stroke(spout, with: .color(green), style: StrokeStyle(lineWidth: 7.5, lineCap: .round))
        var r = c; r.translateBy(x: 6, y: 19); r.rotate(by: .degrees(-62))
        let rose = Path(ellipseIn: CGRect(x: -9, y: -5.5, width: 18, height: 11))
        r.fill(rose, with: .color(steel)); r.stroke(rose, with: .color(ink), lineWidth: 2.2)
        let can = Path(roundedRect: CGRect(x: 26, y: 30, width: 56, height: 50), cornerRadius: 11)
        c.fill(can, with: .color(body)); c.stroke(can, with: .color(ink), lineWidth: 2.4)
        let lid = Path(roundedRect: CGRect(x: 26, y: 30, width: 56, height: 11), cornerRadius: 5.5)
        c.fill(lid, with: .color(steel)); c.stroke(lid, with: .color(ink), lineWidth: 2.2)
        let shine = Path { p in p.move(to: CGPoint(x: 36, y: 50)); p.addLine(to: CGPoint(x: 36, y: 70)) }
        c.stroke(shine, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    // MARK: Soil: the trowel dips into a mound, lifts a heap, arcs over and tips it in; the soil level rises.

    private func soil(_ g: GraphicsContext) {
        let d = play.effect.duration
        let f = min(max(t / d, 0), 1)
        let edge = f < 0.06 ? f / 0.06 : (t > d - 0.15 ? max(0, (d - t) / 0.15) : 1)

        // the soil pile beside the plant, squashing as the trowel takes a scoop
        var pg = g
        pg.opacity = edge
        let squash = M.track([(0, [1, 1]), (0.22, [1, 1]), (0.30, [0.88, 0.72]), (1, [0.88, 0.72])], f)
        pg.translateBy(x: -15, y: 197)
        pg.scaleBy(x: squash[0], y: squash[1])
        pg.translateBy(x: -50, y: -36)
        let pile = Path { p in
            p.move(to: CGPoint(x: 2, y: 36)); p.addCurve(to: CGPoint(x: 50, y: 4), control1: CGPoint(x: 8, y: 14), control2: CGPoint(x: 26, y: 4))
            p.addCurve(to: CGPoint(x: 98, y: 36), control1: CGPoint(x: 74, y: 4), control2: CGPoint(x: 92, y: 14)); p.closeSubpath()
        }
        pg.fill(pile, with: .color(Self.soil)); pg.stroke(pile, with: .color(Self.ink), lineWidth: 2)
        pg.stroke(Path { p in p.move(to: CGPoint(x: 24, y: 22)); p.addCurve(to: CGPoint(x: 70, y: 16), control1: CGPoint(x: 34, y: 12), control2: CGPoint(x: 54, y: 10)) },
                  with: .color(Self.soilLight), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // the soil level rises at the plant's base
        let rise = M.easeOut(M.window(t, 1.45, 0.35))
        if rise > 0 {
            var mg = g; mg.opacity = edge
            mg.translateBy(x: 110, y: 190); mg.scaleBy(x: 0.4 + 0.6 * rise, y: 0.1 + 0.9 * rise)
            mg.fill(Path(roundedRect: CGRect(x: -30, y: -15, width: 60, height: 15), cornerSize: CGSize(width: 26, height: 12)), with: .color(Self.mound))
        }

        // crumbs tip off the blade into the plant's base
        for (i, x) in [101.0, 111, 121, 129, 115].enumerated() {
            let c = M.window(t, 1.42 + Double(i) * 0.07, 0.34)
            guard c > 0 && c < 1 else { continue }
            var cg = g
            cg.opacity = c < 0.12 ? c / 0.12 : (c > 0.85 ? (1 - c) / 0.15 : 1)
            cg.fill(Path(roundedRect: CGRect(x: x, y: 145 + 45 * M.easeIn(c), width: 12, height: 10), cornerRadius: 5), with: .color(Self.soil))
        }

        // the trowel (pivot at the blade's tip), with the heap riding on the blade
        let keys: [(Double, [Double])] = [(0, [-55, 109, 95, 0]), (0.08, [-40, 134, 107, 1]), (0.16, [-13, 177, 128, 1]), (0.26, [-1, 189, 140, 1]),
                                          (0.37, [-3, 155, -6, 1]), (0.53, [75, 132, -26, 1]), (0.63, [147, 158, -8, 1]),
                                          (0.74, [155, 168, 62, 1]), (0.87, [165, 155, 58, 1]), (1, [245, 79, 20, 0])]
        let k = M.track(keys, f)
        guard k[3] > 0.01 else { return }
        var tg = g
        tg.opacity = k[3]
        tg.translateBy(x: k[0], y: k[1]); tg.rotate(by: .degrees(k[2])); tg.scaleBy(x: 0.7, y: 0.7); tg.translateBy(x: -138, y: -25)
        Self.drawTrowel(tg)
        let heap = M.track([(0, [0, 0.3, 0]), (0.24, [0, 0.3, 0]), (0.30, [1, 1, 0]), (0.72, [1, 1, 0]), (0.79, [1, 0.9, 26]), (0.84, [0, 0.5, 34]), (1, [0, 0.5, 34])], f, ease: M.linear)
        if heap[0] > 0.01 {
            var hg = tg
            hg.opacity = heap[0]
            hg.translateBy(x: 92 + heap[2], y: 24); hg.scaleBy(x: heap[1], y: heap[1]); hg.translateBy(x: -92, y: -24)
            let h = Path { p in
                p.move(to: CGPoint(x: 66, y: 24)); p.addCurve(to: CGPoint(x: 98, y: 6), control1: CGPoint(x: 68, y: 8), control2: CGPoint(x: 84, y: 2))
                p.addCurve(to: CGPoint(x: 118, y: 24), control1: CGPoint(x: 112, y: 9), control2: CGPoint(x: 118, y: 18)); p.closeSubpath()
            }
            hg.fill(h, with: .color(Self.soil)); hg.stroke(h, with: .color(Self.ink), lineWidth: 1.6)
            hg.stroke(Path { p in p.move(to: CGPoint(x: 76, y: 14)); p.addCurve(to: CGPoint(x: 106, y: 13), control1: CGPoint(x: 84, y: 9), control2: CGPoint(x: 96, y: 9)) },
                      with: .color(Self.soilLight), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    /// A garden trowel with a leaf-shaped blade (mockup TROWEL).
    static func drawTrowel(_ c: GraphicsContext) {
        let blade = Path { p in
            p.move(to: CGPoint(x: 60, y: 25)); p.addCurve(to: CGPoint(x: 138, y: 25), control1: CGPoint(x: 66, y: 6), control2: CGPoint(x: 100, y: 4))
            p.addCurve(to: CGPoint(x: 60, y: 25), control1: CGPoint(x: 100, y: 46), control2: CGPoint(x: 66, y: 44)); p.closeSubpath()
        }
        c.fill(blade, with: .color(Color(UIColor(hex: 0xC5CED6)))); c.stroke(blade, with: .color(ink), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
        c.stroke(Path { p in p.move(to: CGPoint(x: 66, y: 25)); p.addLine(to: CGPoint(x: 128, y: 25)) }, with: .color(Color(UIColor(hex: 0x8D9AA6))), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        let neck = Path(CGRect(x: 48, y: 21, width: 14, height: 8))
        c.fill(neck, with: .color(Color(UIColor(hex: 0xAEB9C3)))); c.stroke(neck, with: .color(ink), lineWidth: 2.2)
        let ferrule = Path(roundedRect: CGRect(x: 40, y: 13, width: 11, height: 24), cornerRadius: 3)
        c.fill(ferrule, with: .color(Color(UIColor(hex: 0xD5DCE2)))); c.stroke(ferrule, with: .color(ink), lineWidth: 2.2)
        let grip = Path(roundedRect: CGRect(x: 2, y: 16, width: 40, height: 18), cornerRadius: 9)
        c.fill(grip, with: .color(Color(UIColor(hex: 0xB07A4B)))); c.stroke(grip, with: .color(ink), lineWidth: 2.4)
        for x in [12.0, 18, 24] {
            c.stroke(Path { p in p.move(to: CGPoint(x: x, y: 20)); p.addLine(to: CGPoint(x: x, y: 30)) }, with: .color(Color(UIColor(hex: 0x8A5A32))), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    // MARK: Sun: pops in with overshoot, sparkles twinkle on the leaves, then fades.

    private static let sunCenter = CGPoint(x: 226, y: 4)
    private static let sparkles: [(CGFloat, CGFloat, Double)] = [(155, 114, 0.30), (67, 109, 0.38), (108, 31, 0.46), (140, 69, 0.54), (75, 64, 0.62), (185, 159, 0.70)]

    private func sun(_ g: GraphicsContext) {
        let gl = M.track([(0, [0]), (0.25, [1]), (0.7, [0.8]), (1, [0])], t / play.effect.duration)[0]
        if gl > 0 { glow(g, at: Self.sunCenter, radius: 210, opacity: gl) }

        for (x, y, d) in Self.sparkles {
            let f = M.window(t, d, 0.5)
            guard f > 0 && f < 1 else { continue }
            let e = M.easeOut(f)
            let k = M.track([(0, [0, 0.2, 0]), (0.4, [1, 1.2, 40]), (1, [0, 0.5, 90])], e, ease: M.linear)
            var s = g; s.opacity = k[0]
            s.translateBy(x: x, y: y); s.rotate(by: .degrees(k[2])); s.scaleBy(x: 2 * k[1], y: 2 * k[1])
            Self.drawSparkle(s)
        }

        var scale = 1.0, rot = 0.0, op = 1.0
        if t < 0.55 { let f = t / 0.55; scale = M.backOut(f); rot = -40 * (1 - M.easeOut(f)); op = min(1, f * 2) }
        else if t > 1.4 { let e = M.easeIn(M.window(t, 1.4, 0.4)); op = 1 - e; scale = 1 - 0.1 * e }
        guard op > 0.01 else { return }
        var sg = g; sg.opacity = op
        sg.translateBy(x: Self.sunCenter.x, y: Self.sunCenter.y); sg.rotate(by: .degrees(rot)); sg.scaleBy(x: scale * 130 / 120, y: scale * 130 / 120)
        Self.drawSun(sg)
    }

    private func glow(_ g: GraphicsContext, at c: CGPoint, radius: CGFloat, opacity: Double) {
        var gg = g; gg.opacity = opacity
        let warm = Color(red: 1, green: 226 / 255, blue: 120 / 255)
        gg.fill(Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)),
                with: .radialGradient(Gradient(colors: [warm.opacity(0.6), warm.opacity(0)]), center: c, startRadius: 0, endRadius: radius))
    }

    static func drawSparkle(_ s: GraphicsContext) {
        let star = Path { p in
            p.move(to: CGPoint(x: 0, y: -7)); p.addQuadCurve(to: CGPoint(x: 7, y: 0), control: CGPoint(x: 1, y: -1.5))
            p.addQuadCurve(to: CGPoint(x: 0, y: 7), control: CGPoint(x: 1, y: 1.5)); p.addQuadCurve(to: CGPoint(x: -7, y: 0), control: CGPoint(x: -1, y: 1.5))
            p.addQuadCurve(to: CGPoint(x: 0, y: -7), control: CGPoint(x: -1, y: -1.5)); p.closeSubpath()
        }
        s.fill(star, with: .color(Color(UIColor(hex: 0xFFF6C8)))); s.stroke(star, with: .color(Color(UIColor(hex: 0xE8A21A))), lineWidth: 1)
    }

    /// The smiling sun, in a -60...60 box.
    static func drawSun(_ s: GraphicsContext) {
        let ray = Color(UIColor(hex: 0xE8A21A))
        for i in 0..<12 {
            var r = s; r.rotate(by: .degrees(Double(i) * 30))
            r.stroke(Path { p in p.move(to: CGPoint(x: 0, y: -40)); p.addLine(to: CGPoint(x: 0, y: -52)) }, with: .color(ray), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
        let disc = Path(ellipseIn: CGRect(x: -32, y: -32, width: 64, height: 64))
        s.fill(disc, with: .color(Color(UIColor(hex: 0xF6C85A)))); s.stroke(disc, with: .color(ray), lineWidth: 3)
        s.fill(Path(ellipseIn: CGRect(x: -27, y: -28, width: 44, height: 44)), with: .color(Color(UIColor(hex: 0xFFE9A0)).opacity(0.7)))
        let face = Color(UIColor(hex: 0x7A5238))
        s.fill(Path(ellipseIn: CGRect(x: -12.6, y: -4.6, width: 5.2, height: 5.2)), with: .color(face))
        s.fill(Path(ellipseIn: CGRect(x: 7.4, y: -4.6, width: 5.2, height: 5.2)), with: .color(face))
        s.stroke(Path { p in p.move(to: CGPoint(x: -9, y: 8)); p.addQuadCurve(to: CGPoint(x: 9, y: 8), control: CGPoint(x: 0, y: 15)) },
                 with: .color(face), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
    }

    // MARK: Repot: the plant lifts first, the old pot slides out, the new pot slides in, soil falls, a tiny settle.

    private static let potRect = TendAnimationView.potRect

    private func repot(_ g: GraphicsContext) {
        let d = play.effect.duration
        let f = min(max(t / d, 0), 1)

        // root ball under the lifted plant
        let ball = M.track([(0, [0]), (0.09, [0]), (0.16, [1]), (0.48, [1]), (0.56, [0]), (1, [0])], f, ease: M.linear)[0]
        if ball > 0 {
            var bg = g; bg.opacity = ball
            bg.translateBy(x: 55, y: 104)
            let b = Path { p in
                p.move(to: CGPoint(x: 8, y: 6)); p.addCurve(to: CGPoint(x: 55, y: 54), control1: CGPoint(x: 8, y: 40), control2: CGPoint(x: 30, y: 54))
                p.addCurve(to: CGPoint(x: 102, y: 6), control1: CGPoint(x: 80, y: 54), control2: CGPoint(x: 102, y: 40)); p.closeSubpath()
            }
            bg.fill(b, with: .color(Self.soil)); bg.stroke(b, with: .color(Self.ink), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
            bg.stroke(Path { p in p.move(to: CGPoint(x: 26, y: 18)); p.addCurve(to: CGPoint(x: 58, y: 28), control1: CGPoint(x: 36, y: 28), control2: CGPoint(x: 46, y: 30)) },
                      with: .color(Self.soilLight), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }

        // old pot: shows as the plant lifts, then slides out to the left
        let oldIn = M.window(t, 0, 0.15)
        let out = M.track([(0, [0]), (0.3 / d, [0]), (0.8 / d, [1]), (1, [1])], f, ease: { x in pow(x, 2.4) })[0]
        if oldIn > 0 && out < 1 {
            var og = g; og.opacity = oldIn * (1 - out)
            og.translateBy(x: Self.potRect.midX - 300 * out, y: Self.potRect.minY + 24 * out); og.rotate(by: .degrees(-12 * out))
            Self.drawPot(og, pot: play.from, width: Self.potRect.width, rise: 1)
        }

        // the picked pot slides in from the right, its soil rises, it settles, then the scene fades
        let inF = M.easeOut(M.window(t, 0.6, 0.45))
        if inF > 0 {
            var ng = g
            ng.opacity = t > d - 0.2 ? max(0, (d - t) / 0.2) : 1
            let settle = M.track([(0, [1, 1]), (0.4, [1.03, 0.96]), (1, [1, 1])], M.window(t, 1.55, 0.35))
            ng.translateBy(x: Self.potRect.midX + 360 * (1 - inF), y: Self.potRect.maxY)
            ng.scaleBy(x: settle[0], y: settle[1])
            ng.translateBy(x: 0, y: -Self.potRect.height)
            Self.drawPot(ng, pot: play.pot, width: Self.potRect.width, rise: M.easeOut(M.window(t, 1.2, 0.4)))
        }

        for (i, x) in [83.0, 97, 111, 125, 139].enumerated() {
            let c = M.window(t, 1.12 + Double(i) * 0.07, 0.34)
            guard c > 0 && c < 1 else { continue }
            var cg = g
            cg.opacity = c < 0.12 ? c / 0.12 : (c > 0.85 ? (1 - c) / 0.15 : 1)
            cg.fill(Path(roundedRect: CGRect(x: x, y: 114 + 60 * M.easeIn(c), width: 13, height: 11), cornerRadius: 5), with: .color(Self.soil))
        }
    }

    /// A catalog pot drawn from its top centre, `width` wide (the shared 120 by 100 pot box). `rise` grows its soil mound.
    static func drawPot(_ g: GraphicsContext, pot: TendPot, width: CGFloat = 80, rise: Double) {
        var p = g
        p.scaleBy(x: width / 120, y: width / 120)
        p.translateBy(x: -60, y: 0)
        PotPainter.draw(p, pot: pot.pot, soil: true, rise: rise)
    }

    // MARK: Reduce Motion: no travel, a 0.4 s fade to the end look (a badge and a soft glow), then a fade out.

    private func drawCalm(_ g: GraphicsContext) {
        let op = t < 0.4 ? t / 0.4 : (t > 0.8 ? max(0, 1 - (t - 0.8) / 0.4) : 1)
        guard op > 0 else { return }
        var c = g; c.opacity = op
        let badge = CGPoint(x: 196, y: 26)
        switch play.effect {
        case .water:
            c.fill(Path(ellipseIn: CGRect(x: 65, y: 178, width: 90, height: 22)), with: .color(Color(red: 40 / 255, green: 60 / 255, blue: 110 / 255).opacity(0.3)))
            var d = c; d.translateBy(x: badge.x - 18, y: badge.y - 26); d.scaleBy(x: 4, y: 4)
            d.fill(Self.dropPath(width: 9, height: 13), with: .color(dropColor))
        case .soil:
            var m = c; m.translateBy(x: 110, y: 190)
            m.fill(Path(roundedRect: CGRect(x: -30, y: -15, width: 60, height: 15), cornerSize: CGSize(width: 26, height: 12)), with: .color(Self.mound))
            var tr = c; tr.translateBy(x: badge.x - 28, y: badge.y - 10); tr.scaleBy(x: 0.4, y: 0.4)
            Self.drawTrowel(tr)
        case .sun:
            glow(c, at: badge, radius: 200, opacity: 1)
            var s = c; s.translateBy(x: badge.x, y: badge.y); s.scaleBy(x: 0.47, y: 0.47)
            Self.drawSun(s)
        case .repot:
            var p = c; p.translateBy(x: badge.x, y: badge.y - 22); p.scaleBy(x: 0.45, y: 0.45)
            Self.drawPot(p, pot: play.pot, rise: 1)
        }
    }
}

#Preview("Tend effects") {
    struct Demo: View {
        @State private var seq = TendSequencer()
        var body: some View {
            VStack(spacing: 24) {
                Image("plant_daisy").resizable().frame(width: 220, height: 220)
                    .tendMotion(seq.current, size: 220, calm: false)
                    .overlay { TendAnimationView(play: seq.current, size: 220) }
                HStack {
                    ForEach(TendEffect.allCases, id: \.self) { e in Button(e.rawValue) { seq.start(e, at: .now) } }
                }
            }
        }
    }
    return Demo()
}

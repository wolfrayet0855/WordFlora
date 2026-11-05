import SwiftUI
import UIKit

/// Draws PetalKit's petals, five-petal blossoms and leaves (the app's own petal art, FlowerView's PetalShape).
enum PetalArt {
    /// PetalShape re-based so the petal's base sits at (0, 0) and its tip at (0, -54).
    static let petal: Path = {
        var p = Path()
        p.move(to: .zero)
        p.addCurve(to: CGPoint(x: 0, y: -54), control1: CGPoint(x: -19, y: -12), control2: CGPoint(x: -17, y: -44))
        p.addCurve(to: .zero, control1: CGPoint(x: 17, y: -44), control2: CGPoint(x: 19, y: -12))
        p.closeSubpath()
        return p
    }()

    static func leafPath(length len: Double) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addQuadCurve(to: CGPoint(x: len, y: 0), control: CGPoint(x: len * 0.5, y: -len * 0.42))
        p.addQuadCurve(to: .zero, control: CGPoint(x: len * 0.5, y: len * 0.22))
        return p
    }

    /// One petal. `flip` fakes the 3D tumble (never thinner than 35 %, and a touch darker when its back shows);
    /// `midPivot` turns it about its middle (tumbling) instead of its base (in a flower).
    static func drawPetal(_ ctx: GraphicsContext, x: Double, y: Double, angle: Double, len: Double, tint: PetalKit.Tint,
                          alpha: Double, flip: Double = 1, midPivot: Bool = true) {
        guard alpha > 0.01, len > 0.2 else { return }
        var c = ctx
        let s = len / 54
        c.translateBy(x: x, y: y)
        c.rotate(by: .radians(angle))
        c.scaleBy(x: s * max(0.35, abs(flip)), y: s)
        if midPivot { c.translateBy(x: 0, y: 27) }
        c.opacity = ctx.opacity * alpha
        c.fill(petal, with: .color(Color(hex: tint.fill)))
        c.stroke(petal, with: .color(Color(hex: tint.stroke)), lineWidth: 2.2 / s * (len < 14 ? 0.6 : 1))
        if flip < 0 {
            c.opacity = ctx.opacity * alpha * 0.18
            c.fill(petal, with: .color(.black))
        }
    }

    /// The wordmark's five-petal O flower. `open`: 0 is a closed bud, 1 is open; `centre` scales the gold centre.
    static func drawBlossom(_ ctx: GraphicsContext, x: Double, y: Double, r: Double, tint: PetalKit.Tint, alpha: Double,
                            open: Double = 1, rotation: Double = 0, centre: Double = 1) {
        guard alpha > 0.01 else { return }
        let len = r * 0.95, base = r * 0.18 * open
        for k in 0..<5 {
            let a = rotation + (Double(k - 2) * 0.18) + ((Double(k) * 2 * .pi / 5) - Double(k - 2) * 0.18) * open
            drawPetal(ctx, x: x + sin(a) * base, y: y - cos(a) * base, angle: a, len: len * (0.75 + 0.25 * open), tint: tint,
                      alpha: alpha, midPivot: false)
        }
        guard centre > 0 else { return }
        var c = ctx
        c.opacity = ctx.opacity * alpha
        let ro = r * 0.30 * centre, ri = r * 0.18 * centre
        c.fill(Path(ellipseIn: CGRect(x: x - ro, y: y - ro, width: ro * 2, height: ro * 2)), with: .color(Color(hex: PetalKit.centreOuter)))
        c.fill(Path(ellipseIn: CGRect(x: x - ri, y: y - ri, width: ri * 2, height: ri * 2)), with: .color(Color(hex: PetalKit.centreInner)))
    }

    static func drawLeaf(_ ctx: GraphicsContext, x: Double, y: Double, len: Double, angle: Double, colour: UInt32, alpha: Double = 1,
                         centred: Bool = false, flip: Double = 1) {
        guard len > 0.5, alpha > 0.01 else { return }
        var c = ctx
        c.translateBy(x: x, y: y)
        c.rotate(by: .radians(angle))
        c.scaleBy(x: 1, y: max(0.35, abs(flip)))
        if centred { c.translateBy(x: -len / 2, y: 0) }
        c.opacity = ctx.opacity * alpha
        c.fill(leafPath(length: len), with: .color(Color(hex: colour)))
    }

    static func draw(_ p: PetalKit.Particle, _ pose: PetalKit.Pose, in ctx: GraphicsContext) {
        let tint = PetalKit.palette[p.tint % PetalKit.palette.count]
        switch p.kind {
        case .petal:
            drawPetal(ctx, x: pose.x, y: pose.y, angle: pose.angle, len: p.len, tint: tint, alpha: pose.alpha, flip: pose.flip)
        case .blossom:
            drawBlossom(ctx, x: pose.x, y: pose.y, r: p.len, tint: tint, alpha: pose.alpha, rotation: pose.angle * 0.4)
        case .leaf:
            drawLeaf(ctx, x: pose.x, y: pose.y, len: p.len * 1.1, angle: pose.angle, colour: p.tint % 2 == 0 ? PetalKit.leafLight : PetalKit.leafDark,
                     alpha: pose.alpha, centred: true, flip: pose.flip)
        }
    }
}

/// Petal confetti: one `TimelineView(.animation)` + `Canvas`, deterministic per seed, never more than 120 particles.
/// It never takes a tap and VoiceOver skips it. `freezeAt` draws one still frame (UI tests and previews).
struct PetalConfettiView: View {
    let bursts: [PetalKit.Burst]
    var seed: UInt64 = 7
    var freezeAt: Double?
    var onFinish: () -> Void = {}

    @State private var start = Date.now
    @State private var finished = false
    @State private var cache = ParticleCache()

    init(bursts: [PetalKit.Burst], seed: UInt64 = 7, freezeAt: Double? = nil, onFinish: @escaping () -> Void = {}) {
        self.bursts = bursts; self.seed = seed; self.freezeAt = freezeAt; self.onFinish = onFinish
    }

    init(level: CelebrationLevel, origin: PetalKit.Origin, seed: UInt64 = 7, arcRadius: Double = 120, freezeAt: Double? = nil,
         onFinish: @escaping () -> Void = {}) {
        self.init(bursts: [PetalKit.Burst(level: level, origin: origin, arcRadius: arcRadius)], seed: seed, freezeAt: freezeAt, onFinish: onFinish)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: finished || freezeAt != nil)) { timeline in
            let t = freezeAt ?? timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                guard !finished else { return }
                for p in cache.particles(bursts, size: size, seed: seed) {
                    if let pose = PetalKit.pose(p, at: t) { PetalArt.draw(p, pose, in: ctx) }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            guard freezeAt == nil else { return }
            try? await Task.sleep(for: .seconds(PetalKit.duration(of: bursts) + 0.05))
            guard !Task.isCancelled else { return }
            finished = true
            onFinish()
        }
    }

    /// Particles are generated once per canvas size, not every frame.
    final class ParticleCache {
        private var key: (CGSize, UInt64, [PetalKit.Burst])?
        private var value: [PetalKit.Particle] = []

        func particles(_ bursts: [PetalKit.Burst], size: CGSize, seed: UInt64) -> [PetalKit.Particle] {
            if let key, key.0 == size, key.1 == seed, key.2 == bursts { return value }
            value = PetalKit.particles(bursts, in: size, seed: seed)
            key = (size, seed, bursts)
            return value
        }
    }
}

/// A moment's petal celebration across the whole screen, resolved through CelebrationStyle (Reduce Motion, Calm mode,
/// Quiet Garden, Low Power). Put it between the dim and the card so the card's text is never covered.
struct CelebrationBurst: View {
    let requested: [CelebrationLevel]
    var origin: PetalKit.Origin
    var seed: UInt64 = 7
    var onFinish: () -> Void = {}

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        PetalConfettiView(bursts: bursts, seed: seed, onFinish: onFinish)
            .ignoresSafeArea()
    }

    /// Each level once (a level up over a new plant in Calm mode is one calm drift, not two).
    private var bursts: [PetalKit.Burst] {
        var seen = [CelebrationLevel]()
        for level in requested.map({ app.celebrationLevel($0, systemReduceMotion: systemReduceMotion) }) where !seen.contains(level) {
            seen.append(level)
        }
        return seen.map { PetalKit.Burst(level: $0, origin: origin, arcRadius: 150) }
    }
}

/// A small puff that plays each time `trigger` goes up (a plant growing a stage). Size it with a frame around the spot.
struct PetalPuff: View {
    let trigger: Int
    let level: CelebrationLevel
    var arcRadius = 40.0

    var body: some View {
        if trigger > 0 {
            PetalConfettiView(level: level, origin: .unit(CGPoint(x: 0.5, y: 0.5)), seed: UInt64(trigger) &+ 21, arcRadius: arcRadius)
                .id(trigger)
        }
    }
}

/// A correct letter: which letter, and how its tiles celebrate (resolved level).
struct TilePop: Equatable {
    let letter: Character
    let id: Int
    let level: CelebrationLevel
    let at: Date
}

/// The revealed tile's 1.1x pop and marigold wash, as a short explicit timeline that stops on its own.
struct TilePopFrame<Content: View>: View {
    let pop: TilePop?
    @ViewBuilder let content: (_ wash: Double, _ scale: Double) -> Content

    var body: some View {
        if let pop {
            TimelineView(.explicit(stride(from: 0.0, through: 0.85, by: 1.0 / 60).map { pop.at.addingTimeInterval($0) })) { tl in
                let t = tl.date.timeIntervalSince(pop.at)
                content(PetalKit.tileWash(at: t), PetalKit.tileScale(at: t, level: pop.level))
            }
        } else {
            content(0, 1)
        }
    }
}

/// The top safe-area inset of the key window, for bursts drawn across the whole screen.
enum ScreenInsets {
    @MainActor static var top: Double {
        let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        return Double(window?.safeAreaInsets.top ?? 47)
    }
}

#Preview("Confetti") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        PetalConfettiView(level: .large, origin: .fromTop(260), freezeAt: 0.9).ignoresSafeArea()
    }
}

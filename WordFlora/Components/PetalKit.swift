import Foundation
import CoreGraphics

/// How big a celebration is. Callers ask for one; `CelebrationStyle.resolve` picks what actually plays
/// (Reduce Motion, Calm mode, Quiet Garden and Low Power all soften it, but never to nothing).
enum CelebrationLevel: String, CaseIterable, Equatable {
    /// A correct letter: a puff of petals from the revealed tile.
    case small
    /// `small` in Calm mode, Quiet Garden or Low Power: fewer, slower petals, over sooner.
    case smallCalm
    /// Level up, a woken seed, the end of a butterfly game: a fan from the top of the card.
    case medium
    /// A new plant or the Daily Bloom: two side cannons plus a few drifting petals.
    case large
    /// A badge: petals spiral out around the badge art.
    case badge
    /// Calm mode, Quiet Garden or Low Power in place of large and medium: a slow drift from the top, no burst.
    case calm
    /// Reduce Motion, any level: a still arc of petals that fades in and out. Opacity only.
    case reduceMotion
    /// The landing intro (IntroTimeline): petals fall into heaps that grow into a row of flowers.
    case intro

    var particleCount: Int {
        switch self {
        case .small: return 14
        case .smallCalm: return 8
        case .medium: return 40
        case .large: return 96
        case .badge: return 28
        case .calm: return 24
        case .reduceMotion: return 12
        case .intro: return IntroTimeline.petalCount + IntroTimeline.flowerCount
        }
    }

    /// Seconds from the first frame until every particle has faded out.
    var duration: Double {
        switch self {
        case .small: return 0.8
        case .smallCalm: return 0.6
        case .medium: return 1.9
        case .large: return 2.8
        case .badge: return 2.6
        case .calm: return 2.8
        case .reduceMotion: return 1.4
        case .intro: return IntroTimeline.finish
        }
    }
}

/// Petal confetti as pure functions of time (design-preview/celebrate: README, engine.js, confetti.html).
/// Every particle is generated from a seed and posed in closed form, so any frame can be drawn on its own
/// and the whole thing is unit tested without a screen. Drawing lives in PetalConfettiView.
enum PetalKit {
    /// No celebration ever draws more than this many particles at once.
    static let maxParticles = 120

    // MARK: Palette (FlowerView's petals and the logo's flowers; never white, which vanishes on cream)

    struct Tint: Equatable {
        let fill: UInt32
        let stroke: UInt32
    }

    static let palette: [Tint] = [
        Tint(fill: 0xF2788A, stroke: 0xD9566C),   // rose (FlowerView 7-8 petals)
        Tint(fill: 0xF5C858, stroke: 0xE0962A),   // marigold / gold (flower centre, the Word O)
        Tint(fill: 0xE9A36C, stroke: 0xCF8247),   // apricot (FlowerView 5-6)
        Tint(fill: 0xE27D8A, stroke: 0xC95F6E),   // logo rose (the Flora O)
        Tint(fill: 0xC7A9B0, stroke: 0xA98791),   // lilac (FlowerView 3-4)
        Tint(fill: 0x8EA6C4, stroke: 0x6E87A8),   // sky (FlowerView 1-2)
        Tint(fill: 0xC9506C, stroke: 0xA63F58),   // deep logo rose
    ]
    static let centreOuter: UInt32 = 0xE8A838
    static let centreInner: UInt32 = 0xF5C858
    static let stem: UInt32 = 0x4E9A55
    static let leafLight: UInt32 = 0x5FA860
    static let leafDark: UInt32 = 0x3F8A4A
    /// The tile wash for a correct letter.
    static let marigold: UInt32 = 0xF5C858

    /// Every colour a celebration can draw, for the "never white" test.
    static var allColours: [UInt32] {
        palette.flatMap { [$0.fill, $0.stroke] } + [centreOuter, centreInner, stem, leafLight, leafDark, marigold]
    }

    // MARK: Particles

    enum Kind: Equatable { case petal, blossom, leaf }

    enum Motion: Equatable {
        /// Thrown with drag and gravity: v = (vx, vy), drag k, gravity g.
        case burst(vx: Double, vy: Double, k: Double, g: Double)
        /// Falls at a steady speed with a sway.
        case drift(speed: Double)
        /// Spirals out from a centre (the badge), then drifts down.
        case swirl(cx: Double, cy: Double, phi: Double, radius: Double)
        /// Stays put; only its opacity changes (Reduce Motion).
        case still
    }

    struct Particle: Equatable {
        var kind: Kind
        /// Index into `palette` (leaves are always green).
        var tint: Int
        var motion: Motion
        var ox: Double, oy: Double
        var t0: Double, life: Double
        /// Petal length, or a blossom's radius.
        var len: Double
        var a0: Double, spin: Double
        var sway: Double, sw: Double, ph: Double, fw: Double
    }

    struct Pose: Equatable {
        var x: Double, y: Double
        var angle: Double
        /// cos of the tumble phase: the petal is drawn `max(0.35, |flip|)` wide, and darker when it shows its back.
        var flip: Double
        var alpha: Double
        var scaleX: Double { max(0.35, abs(flip)) }
        var showsBack: Bool { flip < 0 }
    }

    /// Where a burst comes from, in the canvas the confetti is drawn in.
    enum Origin: Equatable {
        case point(CGPoint)
        /// Horizontally centred, this many points below the canvas top.
        case fromTop(Double)
        case unit(CGPoint)

        func point(in size: CGSize) -> CGPoint {
            switch self {
            case .point(let p): return p
            case .fromTop(let y): return CGPoint(x: size.width / 2, y: y)
            case .unit(let u): return CGPoint(x: size.width * u.x, y: size.height * u.y)
            }
        }
    }

    struct Burst: Equatable {
        var level: CelebrationLevel
        var origin: Origin
        /// The Reduce Motion arc's radius around the origin (small moments use a tight one).
        var arcRadius: Double = 120
    }

    // MARK: Generation

    private struct RNG {
        var g: SplitMix64
        mutating func next() -> Double { Double(g.next() >> 11) / Double(1 << 53) }
    }

    private struct BurstSpec {
        var n: Int, x: Double, y: Double, dir: Double, spread: Double
        var v: (Double, Double), k: Double, g: Double
        var t0: Double = 0, stagger: Double = 0
        var life: (Double, Double), len: (Double, Double), bloomR: (Double, Double)
        var bloomShare: Double, leafShare: Double = 0, jitter: Double = 0
    }

    private struct DriftSpec {
        var n: Int, width: Double
        var t0: Double, stagger: Double, speed: (Double, Double), life: (Double, Double), len: (Double, Double)
        var bloomShare: Double, leafShare: Double = 0
    }

    private static func lerp(_ a: Double, _ b: Double, _ u: Double) -> Double { a + (b - a) * u }

    /// Every particle for these bursts, oldest first, never more than `maxParticles` in all.
    /// When bursts are layered (level up over a new plant), the earlier bursts keep all of theirs.
    static func particles(_ bursts: [Burst], in size: CGSize, seed: UInt64) -> [Particle] {
        var all = [Particle]()
        for (i, b) in bursts.enumerated() {
            all += particles(b, in: size, seed: seed &+ UInt64(i) &* 0x9E37)
            if all.count >= maxParticles { break }
        }
        return Array(all.prefix(maxParticles))
    }

    static func particles(level: CelebrationLevel, origin: Origin, in size: CGSize, seed: UInt64, arcRadius: Double = 120) -> [Particle] {
        particles([Burst(level: level, origin: origin, arcRadius: arcRadius)], in: size, seed: seed)
    }

    private static func particles(_ b: Burst, in size: CGSize, seed: UInt64) -> [Particle] {
        var r = RNG(g: SplitMix64(seed: seed))
        var out = [Particle]()
        let o = b.origin.point(in: size)
        let W = Double(size.width), H = Double(size.height)
        let deg = Double.pi / 180
        let duration = b.level.duration

        func burst(_ s: BurstSpec) {
            for _ in 0..<s.n {
                let ang = s.dir + (r.next() - 0.5) * s.spread
                let v = lerp(s.v.0, s.v.1, r.next())
                let roll = r.next()
                let kind: Kind = roll < s.bloomShare ? .blossom : (roll < s.bloomShare + s.leafShare ? .leaf : .petal)
                let tint = Int(r.next() * Double(palette.count)) % palette.count
                let ox = s.x + (r.next() - 0.5) * s.jitter
                let t0 = s.t0 + r.next() * s.stagger
                let life = min(lerp(s.life.0, s.life.1, r.next()), duration - t0)
                let len = kind == .blossom ? lerp(s.bloomR.0, s.bloomR.1, r.next()) : lerp(s.len.0, s.len.1, r.next())
                out.append(Particle(kind: kind, tint: tint, motion: .burst(vx: cos(ang) * v, vy: sin(ang) * v, k: s.k, g: s.g),
                                    ox: ox, oy: s.y, t0: t0, life: life, len: len,
                                    a0: r.next() * 2 * .pi, spin: (r.next() - 0.5) * 9,
                                    sway: 6 + r.next() * 14, sw: 3 + r.next() * 3, ph: r.next() * 2 * .pi, fw: 5 + r.next() * 5))
            }
        }

        func drift(_ s: DriftSpec) {
            for _ in 0..<s.n {
                let roll = r.next()
                let kind: Kind = roll < s.bloomShare ? .blossom : (roll < s.bloomShare + s.leafShare ? .leaf : .petal)
                let tint = Int(r.next() * Double(palette.count)) % palette.count
                let ox = 10 + r.next() * max(0, s.width - 20)
                let oy = -20 - r.next() * 40
                let speed = lerp(s.speed.0, s.speed.1, r.next())
                let t0 = s.t0 + r.next() * s.stagger
                let life = min(lerp(s.life.0, s.life.1, r.next()), duration - t0)
                let len = kind == .blossom ? lerp(6, 9, r.next()) : lerp(s.len.0, s.len.1, r.next())
                out.append(Particle(kind: kind, tint: tint, motion: .drift(speed: speed), ox: ox, oy: oy, t0: t0, life: life, len: len,
                                    a0: r.next() * 2 * .pi, spin: (r.next() - 0.5) * 3,
                                    sway: 12 + r.next() * 20, sw: 1.6 + r.next() * 1.4, ph: r.next() * 2 * .pi, fw: 2.5 + r.next() * 2.5))
            }
        }

        switch b.level {
        case .small:
            burst(BurstSpec(n: 14, x: o.x, y: o.y - 10, dir: -90 * deg, spread: 130 * deg, v: (150, 250), k: 4.2, g: 300,
                            life: (0.6, 0.8), len: (9, 12), bloomR: (6, 7), bloomShare: 0.3))
        case .smallCalm:
            burst(BurstSpec(n: 8, x: o.x, y: o.y - 10, dir: -90 * deg, spread: 110 * deg, v: (90, 150), k: 4.2, g: 200,
                            life: (0.45, 0.6), len: (9, 12), bloomR: (6, 7), bloomShare: 0.3))
        case .medium:
            burst(BurstSpec(n: 40, x: o.x, y: o.y, dir: -90 * deg, spread: 150 * deg, v: (240, 470), k: 2.6, g: 230, stagger: 0.08,
                            life: (1.5, 1.9), len: (10, 15), bloomR: (6, 9), bloomShare: 0.25, leafShare: 0.08, jitter: 30))
        case .large:
            for (n, t0) in [(26, 0.0), (14, 0.45)] {     // two soft waves, 80 petals from the cannons
                burst(BurstSpec(n: n, x: -6, y: H * 0.74, dir: -64 * deg, spread: 46 * deg, v: (650, 1000), k: 1.7, g: 210, t0: t0, stagger: 0.15,
                                life: (2.2, 2.8), len: (11, 16), bloomR: (7, 10), bloomShare: 0.22, leafShare: 0.06))
                burst(BurstSpec(n: n, x: W + 6, y: H * 0.74, dir: -116 * deg, spread: 46 * deg, v: (650, 1000), k: 1.7, g: 210, t0: t0 + 0.06, stagger: 0.15,
                                life: (2.2, 2.8), len: (11, 16), bloomR: (7, 10), bloomShare: 0.22, leafShare: 0.06))
            }
            drift(DriftSpec(n: 16, width: W, t0: 0.4, stagger: 0.5, speed: (120, 170), life: (2.0, 2.4), len: (11, 14), bloomShare: 0.5))
        case .calm:
            drift(DriftSpec(n: 24, width: W, t0: 0, stagger: 0.6, speed: (110, 160), life: (2.2, 2.8), len: (11, 15), bloomShare: 0.15, leafShare: 0.1))
        case .badge:
            let n = 28
            for i in 0..<n {
                let bloom = i % 4 == 0
                out.append(Particle(kind: bloom ? .blossom : .petal, tint: i % palette.count,
                                    motion: .swirl(cx: o.x, cy: o.y, phi: Double(i) / Double(n) * 2 * .pi + r.next() * 0.2, radius: 95 + r.next() * 45),
                                    ox: o.x, oy: o.y, t0: 0, life: min(duration, 2.3 + r.next() * 0.3),
                                    len: bloom ? 7 + r.next() * 2 : 11 + r.next() * 4,
                                    a0: 0, spin: 0, sway: 0, sw: 0, ph: r.next() * 2 * .pi, fw: 4 + r.next() * 4))
            }
        case .reduceMotion, .intro:
            // A still arc above the origin. The radius shrinks so the arc never leaves the top of the canvas.
            let R = min(b.arcRadius, max(30, (o.y - 12) / 0.7))
            for i in 0..<12 {
                let phi = -Double.pi / 2 + (Double(i) - 5.5) * 0.24
                let bloom = i % 3 == 1
                out.append(Particle(kind: bloom ? .blossom : .petal, tint: i % palette.count, motion: .still,
                                    ox: o.x + cos(phi) * R, oy: o.y + sin(phi) * R * 0.7, t0: 0, life: CelebrationLevel.reduceMotion.duration,
                                    len: bloom ? 9 : 13, a0: phi + .pi / 2, spin: 0, sway: 0, sw: 0, ph: 0, fw: 0))
            }
        }
        return out
    }

    // MARK: Motion

    /// Where a particle is at time t (seconds since the celebration started), or nil before it starts and after it ends.
    /// It fades out over the last 32 % of its life, so its alpha is 0 at the end.
    static func pose(_ p: Particle, at t: Double) -> Pose? {
        let tt = t - p.t0
        guard tt >= 0, tt <= p.life, p.life > 0 else { return nil }
        let fade = 1 - Ease.inOutCubic(Ease.seg(tt, p.life * 0.68, p.life))
        switch p.motion {
        case let .burst(vx, vy, k, g):
            let e = exp(-k * tt), m = (1 - e) / k
            return Pose(x: p.ox + vx * m + sin(p.sw * tt + p.ph) * p.sway * (1 - e),
                        y: p.oy + vy * m + (g / k) * (tt - m),
                        angle: p.a0 + p.spin * m * 2 + 0.6 * sin(p.sw * tt) * (1 - e),
                        flip: cos(p.fw * tt + p.ph), alpha: fade)
        case let .drift(speed):
            return Pose(x: p.ox + sin(p.sw * tt + p.ph) * p.sway, y: p.oy + speed * tt,
                        angle: p.a0 + p.spin * tt + 0.5 * sin(p.sw * tt),
                        flip: cos(p.fw * tt + p.ph), alpha: fade * Ease.outCubic(Ease.seg(tt, 0, 0.3)))
        case let .swirl(cx, cy, phi0, radius):
            let e = Ease.outCubic(Ease.seg(tt, 0, 1.5))
            let rad = lerp(36, radius, e), phi = phi0 + 2.4 * e
            let fall = max(0, tt - 1.1)
            let flip = fall > 0 ? cos(p.fw * tt + p.ph) : cos(p.fw * tt + p.ph) * 0.35 + 0.65
            return Pose(x: cx + cos(phi) * rad, y: cy + sin(phi) * rad * 0.7 + 40 * fall * fall,
                        angle: phi + .pi, flip: flip, alpha: fade * Ease.outCubic(Ease.seg(tt, 0, 0.2)))
        case .still:
            let a = Ease.outCubic(Ease.seg(tt, 0, 0.3)) * (1 - Ease.inOutCubic(Ease.seg(tt, 0.9, 1.4)))
            return Pose(x: p.ox, y: p.oy, angle: p.a0, flip: 1, alpha: a)
        }
    }

    /// When the last of these bursts has finished.
    static func duration(of bursts: [Burst]) -> Double { bursts.map(\.level.duration).max() ?? 0 }

    // MARK: Correct-letter tile pop

    /// The revealed tile grows 1.1x and settles back (none under Reduce Motion).
    static func tileScale(at t: Double, level: CelebrationLevel) -> Double {
        level == .reduceMotion ? 1 : 1 + 0.1 * sin(.pi * Ease.seg(t, 0, 0.28))
    }

    /// The marigold wash on the revealed tile, fading out by 0.8 s.
    static func tileWash(at t: Double) -> Double { 0.6 * (1 - Ease.seg(t, 0.2, 0.8)) }
}

/// The easing curves the mockup uses.
enum Ease {
    static func clamp(_ x: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(b, max(a, x)) }
    static func seg(_ t: Double, _ a: Double, _ b: Double) -> Double { b == a ? (t >= b ? 1 : 0) : clamp((t - a) / (b - a)) }
    static func outCubic(_ u: Double) -> Double { 1 - pow(1 - u, 3) }
    static func inOutCubic(_ u: Double) -> Double { u < 0.5 ? 4 * u * u * u : 1 - pow(-2 * u + 2, 3) / 2 }
    static func outBack(_ u: Double) -> Double { let c1 = 1.5, c3 = c1 + 1; return 1 + c3 * pow(u - 1, 3) + c1 * pow(u - 1, 2) }
}

// MARK: - Landing intro

/// The landing intro (design-preview/celebrate/intro.html, README section A): 41 petals fall into seven heaps and loose
/// petals, each heap grows a stem and its petals gather into a bud that opens into a five-petal flower. The row sits in
/// the lower third; the wordmark and tagline fade in above it. No petal starts to fall until the wordmark has settled
/// (`wordmarkSettled`), so the mark never dissolves into petals of its own colours, and falling petals pass faintly
/// behind the tagline, never over it (docs/pm/logo-decision.md, item 3). Petals are the logo's rose family and gold.
/// Everything is over by `finish` (3.5 s); then a 0.4 s hand-off. A tap jumps to the final frame.
struct IntroTimeline {
    static let finish = 3.5
    /// The wordmark has faded in and settled into place by here; the first petal starts falling no earlier.
    static let wordmarkSettled = 0.9
    /// The palette entries the intro draws: rose, marigold gold, logo rose and deep logo rose #C9506C (`PetalKit.palette`).
    static let introTints = [0, 1, 3, 6]
    /// How faint a falling petal is while it crosses the text band, so the wordmark and tagline always read.
    static let inBandAlpha = 0.35
    static let handoff = 0.4
    /// Reduce Motion: the wordmark, tagline and bloomed row fade in together over this long, opacity only...
    static let reduceMotionFade = 0.6
    /// ...and the hand-off starts here.
    static let reduceMotionHandoff = 2.0
    static let heaps = 7
    static let petalsPerHeap = 5
    static let loosePetals = 6
    static let petalCount = heaps * petalsPerHeap + loosePetals
    static let flowerCount = heaps

    /// The mockup's frame; positions scale to the real one.
    private static let refWidth = 393.0

    struct Cluster: Equatable {
        var x: Double, h: Double, rad: Double, tint: Int, lean: Double
        /// When the stem starts to grow: just after the heap's last petal lands.
        var bloomStart: Double
    }

    struct Faller: Equatable {
        /// The heap it lands in, or -1 for a loose petal.
        var cluster: Int
        var k: Int
        var tint: Int, len: Double
        var xL: Double, yL: Double, rest: Double
        /// Fall start and duration: it lands at `ts + D`.
        var ts: Double, D: Double
        var y0: Double, drift: Double, swayA: Double, swayW: Double, ph: Double
        var spin0: Double, spin: Double, flipW: Double, ph2: Double
        /// Drawn a little fainter (85 %) the whole way down, like the mockup's petals behind the wordmark.
        var back: Bool
        var lands: Double { ts + D }
    }

    enum Layer: Equatable { case behindText, front }
    enum Pivot: Equatable { case mid, base }

    enum Item: Equatable {
        case petal(layer: Layer, x: Double, y: Double, angle: Double, len: Double, tint: Int, alpha: Double, flip: Double, pivot: Pivot)
        case stem(baseX: Double, ground: Double, topX: Double, topY: Double, lean: Double, height: Double, growth: Double)
        case leaf(x: Double, y: Double, len: Double, angle: Double, colour: UInt32)
        case blossom(x: Double, y: Double, r: Double, tint: Int, open: Double, rotation: Double, centre: Double, alpha: Double)
    }

    let size: CGSize
    let ground: Double
    private(set) var clusters: [Cluster] = []
    private(set) var fallers: [Faller] = []

    init(size: CGSize, seed: UInt64 = 11) {
        self.size = size
        let W = Double(size.width), H = Double(size.height)
        let sx = W / Self.refWidth
        ground = H - 72                                          // the ground line sits above the home indicator
        var g = SplitMix64(seed: seed)
        func r() -> Double { Double(g.next() >> 11) / Double(1 << 53) }

        let heights = [70.0, 50, 80, 58, 76, 48, 66]
        let tints = [6, 1, 3, 0, 6, 1, 3]                        // rose family and gold; neighbours never share a colour
        var starts = [Double]()
        for c in 0..<Self.heaps {
            let rank = Double(abs(c - 3))                         // the row blooms from the middle outwards
            clusters.append(Cluster(x: (34 + Double(c) * (325.0 / 6) + (r() - 0.5) * 10) * sx, h: heights[c], rad: 16 + r() * 4,
                                    tint: tints[c], lean: (r() - 0.5) * 0.12, bloomStart: 0))
            starts.append(Self.wordmarkSettled + rank * 0.08)
        }
        func faller(cluster: Int, k: Int, tint: Int, len: Double, xL: Double, yL: Double, rest: Double, start: Double) -> Faller {
            let D = 0.75 + r() * 0.2
            return Faller(cluster: cluster, k: k, tint: tint, len: len, xL: xL, yL: yL, rest: rest, ts: start, D: D,
                          y0: -30 - r() * 60, drift: (r() - 0.5) * 120 * sx, swayA: 14 + r() * 18, swayW: 5 + r() * 4, ph: r() * 2 * .pi,
                          spin0: r() * 2 * .pi, spin: (r() - 0.5) * 7, flipW: 7 + r() * 6, ph2: r() * 2 * .pi, back: r() < 0.4)
        }
        let heap = [0.0, 2.5, 4.5, 2, 0]
        for (ci, c) in clusters.enumerated() {
            for k in 0..<Self.petalsPerHeap {
                let xL = c.x + Double(k - 2) * 5.5 + (r() - 0.5) * 3
                let yL = ground - heap[k] - r() * 1.5             // a little heap
                let rest = (r() < 0.5 ? -1.0 : 1.0) * (1.25 + r() * 0.45)   // lying on its side, slight tilt
                let start = starts[ci] + r() * 0.15
                fallers.append(faller(cluster: ci, k: k, tint: c.tint, len: 18 + r() * 3, xL: xL, yL: yL, rest: rest, start: start))
            }
        }
        for i in 0..<Self.loosePetals {                            // loose petals between the flowers
            let x = (16 + r() * 361) * sx
            let tint = Self.introTints[min(Int(r() * 4), 3)]
            let len = 12 + r() * 4
            let rest = (r() < 0.5 ? -1.0 : 1.0) * (1.2 + r() * 0.6)
            let start = Self.wordmarkSettled + r() * 0.5
            fallers.append(faller(cluster: -1, k: i, tint: tint, len: len, xL: x, yL: ground + 3 - (i % 4 == 0 ? 3 : 0), rest: rest, start: start))
        }
        for ci in clusters.indices {
            clusters[ci].bloomStart = (fallers.filter { $0.cluster == ci }.map(\.lands).max() ?? 0) + 0.12
        }
    }

    // MARK: Wordmark and tagline

    struct TextPose: Equatable { var opacity: Double, dy: Double, scale: Double }

    /// 0-0.8 s: fade in, rise 14 pt, scale 0.94 to 1; 0.5-0.9 s: settle 18 pt up, before any petal falls.
    static func wordmark(at t: Double, reduceMotion: Bool) -> TextPose {
        if reduceMotion { return TextPose(opacity: Ease.outCubic(Ease.seg(t, 0, reduceMotionFade)), dy: -18, scale: 1) }
        let mIn = Ease.outCubic(Ease.seg(t, 0, 0.8))
        let settle = Ease.inOutCubic(Ease.seg(t, 0.5, wordmarkSettled))
        return TextPose(opacity: mIn, dy: 14 * (1 - mIn) - 18 * settle, scale: 0.94 + 0.06 * mIn)
    }

    /// 0.6-1.2 s: fade in and rise 6 pt.
    static func tagline(at t: Double, reduceMotion: Bool) -> TextPose {
        if reduceMotion { return TextPose(opacity: Ease.outCubic(Ease.seg(t, 0, reduceMotionFade)), dy: 0, scale: 1) }
        let u = Ease.seg(t, 0.6, 1.2)
        return TextPose(opacity: Ease.outCubic(u), dy: 6 * (1 - u), scale: 1)
    }

    // MARK: Petals, stems and flowers

    struct FallPose { var x: Double, y: Double, a: Double, flip: Double, falling: Bool }

    func fallPose(_ p: Faller, at t: Double) -> FallPose? {
        let u = (t - p.ts) / p.D
        if u < 0 { return nil }
        if u < 1 {
            let f = 1 - pow(1 - u, 1.35)
            let end = Ease.inOutCubic(Ease.seg(u, 0.72, 1))
            return FallPose(x: p.xL + p.drift * (1 - f) + p.swayA * sin(p.swayW * u + p.ph) * pow(1 - u, 0.8),
                            y: p.y0 + (p.yL - p.y0) * f,
                            a: (p.spin0 + p.spin * u) + (p.rest - (p.spin0 + p.spin * u)) * end,
                            flip: cos(p.flipW * u + p.ph2) + (1 - cos(p.flipW * u + p.ph2)) * end, falling: true)
        }
        let tau = t - p.lands                                    // settle: a tiny bounce and rock
        return FallPose(x: p.xL, y: p.yL - 2.5 * exp(-10 * tau) * abs(sin(14 * tau)),
                        a: p.rest + 0.22 * exp(-7 * tau) * sin(16 * tau), flip: 1, falling: false)
    }

    struct StemTop { var x: Double, y: Double, growth: Double, height: Double, rotation: Double }

    func stemTop(_ c: Cluster, at t: Double) -> StemTop {
        let g = Ease.outCubic(Ease.seg(t, c.bloomStart, c.bloomStart + 0.5))
        let sway = 0.035 * sin(1.5 * (t - c.bloomStart) + c.x) * Ease.seg(t, c.bloomStart + 0.9, c.bloomStart + 1.5)
        let h = c.h * g
        return StemTop(x: c.x + sin(c.lean + sway) * h, y: ground - cos(c.lean + sway) * h, growth: g, height: h, rotation: c.lean + sway)
    }

    /// How faint a falling petal is: 85 % for the petals marked "back", and `inBandAlpha` while it crosses the text band.
    static func fallingAlpha(back: Bool, y: Double, band: ClosedRange<Double>?) -> Double {
        let base = back ? 0.85 : 1
        guard let band else { return base }
        let margin = 16.0
        let w: Double
        if y < band.lowerBound { w = Ease.seg(y, band.lowerBound - margin, band.lowerBound) }
        else if y > band.upperBound { w = 1 - Ease.seg(y, band.upperBound, band.upperBound + margin) }
        else { w = 1 }
        return base + (inBandAlpha - base) * w
    }

    /// Everything to draw at time t, back to front. Falling petals sit behind the text layer; landed heaps,
    /// stems and flowers (all in the lower third, clear of the text) sit in front of it.
    func items(at t: Double, textBand: ClosedRange<Double>? = nil) -> [Item] {
        var out = [Item]()
        let tops = clusters.map { stemTop($0, at: t) }
        // stems and leaves first (behind their petals)
        for (i, c) in clusters.enumerated() where tops[i].growth > 0 {
            let s = tops[i]
            out.append(.stem(baseX: c.x, ground: ground, topX: s.x, topY: s.y, lean: c.lean, height: s.height, growth: s.growth))
            let l1 = Ease.outCubic(Ease.seg(t, c.bloomStart + 0.22, c.bloomStart + 0.6))
            let l2 = Ease.outCubic(Ease.seg(t, c.bloomStart + 0.3, c.bloomStart + 0.68))
            if l1 > 0 { out.append(.leaf(x: c.x + 1, y: ground - s.height * 0.32, len: 11 * l1, angle: -0.5, colour: PetalKit.leafLight)) }
            if l2 > 0 { out.append(.leaf(x: c.x - 1, y: ground - s.height * 0.5, len: 9 * l2, angle: .pi + 0.55, colour: PetalKit.leafDark)) }
        }
        for p in fallers {
            guard let q = fallPose(p, at: t) else { continue }
            let layer: Layer = q.falling ? .behindText : .front
            let fallAlpha = q.falling ? Self.fallingAlpha(back: p.back, y: q.y, band: textBand) : 1
            if p.cluster < 0 {                                   // loose petals soak into the soil once the row has bloomed
                let soak = 1 - Ease.inOutCubic(Ease.seg(t, 2.8, 3.3))
                if soak > 0 { out.append(.petal(layer: layer, x: q.x, y: q.y, angle: q.a, len: p.len, tint: p.tint, alpha: fallAlpha * soak, flip: q.flip, pivot: .mid)) }
                continue
            }
            let c = clusters[p.cluster], s = tops[p.cluster]
            let gather = Ease.inOutCubic(Ease.seg(t, c.bloomStart + 0.05, c.bloomStart + 0.5))
            if gather <= 0 {
                out.append(.petal(layer: layer, x: q.x, y: q.y, angle: q.a, len: p.len, tint: p.tint, alpha: fallAlpha, flip: q.flip, pivot: .mid))
                continue
            }
            if t >= c.bloomStart + 0.5 { continue }               // the flower takes over below
            // travel from the resting pose up to the rising stem top and become the closed bud
            let bx = q.x - sin(q.a) * p.len / 2, by = q.y + cos(q.a) * p.len / 2
            let budA = s.rotation + Double(p.k - 2) * 0.18, budLen = c.rad * 0.95 * 0.75
            var ra = q.a
            while ra - budA > .pi { ra -= 2 * .pi }
            while budA - ra > .pi { ra += 2 * .pi }
            out.append(.petal(layer: .front, x: bx + (s.x - bx) * gather, y: by + (s.y - by) * gather, angle: ra + (budA - ra) * gather,
                              len: p.len + (budLen - p.len) * gather, tint: p.tint, alpha: 1, flip: 1, pivot: .base))
        }
        for (i, c) in clusters.enumerated() where t >= c.bloomStart + 0.5 {
            let s = tops[i]
            out.append(.blossom(x: s.x, y: s.y, r: c.rad, tint: c.tint, open: Ease.outBack(Ease.seg(t, c.bloomStart + 0.5, c.bloomStart + 0.95)),
                                rotation: s.rotation, centre: Ease.outBack(Ease.seg(t, c.bloomStart + 0.62, c.bloomStart + 0.85)), alpha: 1))
        }
        return out
    }

    /// Reduce Motion: the same row, already bloomed and still (the view fades it in as a whole).
    func bloomedRow() -> [Item] {
        items(at: Self.finish + 10).filter { if case .petal = $0 { return false } else { return true } }
    }

    /// When the last thing moves: the last flower finishes opening, landed petals stop rocking, loose petals soak away.
    var lastMotion: Double {
        let flowers = clusters.map { $0.bloomStart + 0.95 }.max() ?? 0
        let settles = fallers.map { $0.lands + 0.45 }.max() ?? 0         // the landing bounce has died away by then
        return max(flowers, settles, 3.3)
    }
}

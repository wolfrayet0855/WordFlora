import SwiftUI

/// Weather art over (or behind) a plant. Mount one `.back` layer behind the plant and one `.front` layer over it, in
/// the same place as the plant's `size` x `size` box (the app's 220-unit plant box: pot top at 179, soil at 185). The art
/// spills past the box on purpose (sky, puddle) and never takes taps. Decorative: hidden from VoiceOver; the page's
/// words tell the weather. `still` (Reduce Motion) holds one calm frame; `paused` (off screen, inactive, Low Power)
/// freezes the clock. Capped at 30 fps.
struct WeatherOverlay: View {
    let kind: WeatherKind
    var look: WeatherEffect = .full
    var layer: WeatherArt.Layer = .front
    var size: CGFloat = 220
    var still = false
    var paused = false
    @Environment(\.colorScheme) private var scheme

    /// The scene is 361 x 340 units, one unit per plant-box unit: the soil's centre (180, 214) sits on the box's soil
    /// (110, 188), the soil is 40 units either side, the pot rim 70, and the floor (pot bottom) at y 321.
    static let sceneHeight: CGFloat = 340
    static let floorY: CGFloat = 321

    /// Where the scene sits relative to the plant box.
    static func sceneRect(plantSize s: CGFloat) -> CGRect {
        let k = s / 220
        return CGRect(x: (110 - 180) * k, y: (188 - 214) * k, width: 361 * k, height: sceneHeight * k)
    }

    var body: some View {
        let spec = WeatherArt.spec(kind, look: look)
        let r = Self.sceneRect(plantSize: size)
        let p = WeatherPalette(dark: scheme == .dark)
        let elements = spec.elements.filter { WeatherArt.layer($0) == layer }
        Group {
            if elements.isEmpty {
                Color.clear
            } else if still || !Self.moves(elements) {
                Canvas { ctx, sz in draw(ctx, sz, spec, elements, p, t: WeatherArt.stillTime, moving: false) }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused)) { tl in
                    Canvas { ctx, sz in draw(ctx, sz, spec, elements, p, t: tl.date.timeIntervalSinceReferenceDate, moving: true) }
                }
            }
        }
        .frame(width: r.width, height: r.height)
        .offset(x: r.minX, y: r.minY)
        .frame(width: size, height: size, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func moves(_ e: [WeatherArt.Element]) -> Bool {
        !Set(e).isDisjoint(with: [.windStreaks, .blownLeaves, .heatShimmer, .termites, .crumbs, .snowflakes, .hailPellets, .rain, .puddle, .cheer, .clouds, .greyClouds])
    }

    private func draw(_ c: GraphicsContext, _ sz: CGSize, _ s: WeatherArt.Spec, _ els: [WeatherArt.Element], _ p: WeatherPalette, t: Double, moving: Bool) {
        var g = c
        g.scaleBy(x: sz.width / 361, y: sz.height / Self.sceneHeight)
        let n = s.particles, light = s.look == .light
        for e in els {
            switch e {
            case .sun:
                WeatherDraw.sun(g, x: 300, y: 66, r: s.kind == .hotDay ? 28 : 22, color: p.sun)
            case .clouds:
                let drift = moving ? sin(t / 9) * 6 : 0
                WeatherDraw.cloud(g, x: 70 + drift, y: 50, s: 1.1, color: p.cloud, alpha: 0.85)
                WeatherDraw.cloud(g, x: 290 - drift, y: 76, s: 0.9, color: p.cloud, alpha: 0.7)
            case .greyClouds:
                let drift = moving ? sin(t / 10) * 5 : 0
                WeatherDraw.cloud(g, x: 80 + drift, y: 56, s: 1.2, color: p.greyCloud[0], alpha: 0.95)
                WeatherDraw.cloud(g, x: 280 - drift, y: 52, s: 1.1, color: p.greyCloud[1], alpha: 0.95)
                WeatherDraw.cloud(g, x: 180, y: 38, s: 1.2, color: p.greyCloud[2], alpha: 0.9)
            case .windStreaks: windStreaks(g, p, t: t, moving: moving, light: light)
            case .blownLeaves: leaves(g, p, n: n, t: t, moving: moving)
            case .dryCracks: dry(g, p, light: light)
            case .heatShimmer: shimmer(g, n: n, t: t, moving: moving)
            case .termites: termites(g, n: light ? 1 : 2, t: t, moving: moving)
            case .crumbs: crumbs(g, p, n: n, t: t, moving: moving)
            case .frostRim:
                g.stroke(WeatherDraw.ellipse(180, 219, 44, 8), with: .color(.white.opacity(light ? 0.6 : 0.95)),
                         style: StrokeStyle(lineWidth: 3.4, lineCap: .round, dash: [2, 5]))
            case .snowflakes: flakes(g, p, n: n, t: t, moving: moving)
            case .hailPellets: hail(g, p, n: n, t: t, moving: moving)
            case .hailOnSoil:
                for (x, y) in [(124.0, 212.0), (152, 222), (166, 219), (198, 222), (222, 213), (236, 216), (114, 217)].prefix(light ? 3 : 7) {
                    WeatherDraw.pellet(g, x: x, y: y, r: 4.2, palette: p, streak: false)
                }
            case .rain: rain(g, p, n: n, t: t, moving: moving)
            case .puddle: puddle(g, p, t: t, moving: moving, light: light)
            case .cheer: cheer(g, p, t: t, moving: moving)
            case .shelter: if let h = s.helper { WeatherShelterArt.draw(g, h, palette: p) }
            }
        }
    }

    // MARK: Elements

    private func windStreaks(_ g: GraphicsContext, _ p: WeatherPalette, t: Double, moving: Bool, light: Bool) {
        var lines = Path()
        lines.move(to: WeatherDraw.pt(14, 112)); lines.addCurve(to: WeatherDraw.pt(210, 104), control1: WeatherDraw.pt(80, 90), control2: WeatherDraw.pt(130, 132))
        lines.addCurve(to: WeatherDraw.pt(346, 118), control1: WeatherDraw.pt(290, 76), control2: WeatherDraw.pt(300, 100))
        lines.move(to: WeatherDraw.pt(30, 158)); lines.addCurve(to: WeatherDraw.pt(200, 152), control1: WeatherDraw.pt(90, 144), control2: WeatherDraw.pt(140, 170))
        if !light { lines.move(to: WeatherDraw.pt(230, 180)); lines.addCurve(to: WeatherDraw.pt(346, 170), control1: WeatherDraw.pt(270, 170), control2: WeatherDraw.pt(310, 182)) }
        // Moving: long dashes drift along the lines with the wind. Still: the whole soft line, as in the mockup.
        let dash: [CGFloat] = moving ? [90, 60] : []
        g.stroke(lines, with: .color(p.swoosh.opacity(0.9)),
                 style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: dash, dashPhase: moving ? CGFloat(-t * 70) : 0))
    }

    private func leaves(_ g: GraphicsContext, _ p: WeatherPalette, n: Int, t: Double, moving: Bool) {
        let rest: [(Double, Double, Double, Double)] = [(300, 70, -20, 0.9), (250, 138, 10, 0.8), (60, 70, 25, 0.7)]
        for (i, l) in rest.prefix(max(1, n)).enumerated() {
            if moving {
                let x = WeatherDraw.loop(t, speed: 46 + Double(i) * 9, span: 420, phase: WeatherDraw.rnd(i, 3)) - 30
                let y = l.1 + sin(t * 1.3 + Double(i) * 2) * 10
                WeatherDraw.leaf(g, x: x, y: y, angle: l.2 + sin(t * 2 + Double(i)) * 25, s: l.3, trail: p.swoosh, palette: p)
            } else {
                WeatherDraw.leaf(g, x: l.0, y: l.1, angle: l.2, s: l.3, trail: nil, palette: p)
            }
        }
    }

    private func dry(_ g: GraphicsContext, _ p: WeatherPalette, light: Bool) {
        g.fill(WeatherDraw.ellipse(180, 220, 38, 7), with: .color(p.soilDry.opacity(light ? 0.55 : 0.85)))
        var cracks = Path()
        let segs: [[(Double, Double)]] = [[(150, 218), (158, 220), (162, 217)], [(212, 217), (203, 220), (199, 217)],
                                          [(166, 224), (172, 221), (178, 223)], [(186, 224), (192, 221), (200, 223)]]
        for s in segs.prefix(light ? 2 : 4) {
            cracks.move(to: WeatherDraw.pt(s[0].0, s[0].1))
            for q in s.dropFirst() { cracks.addLine(to: WeatherDraw.pt(q.0, q.1)) }
        }
        g.stroke(cracks, with: .color(p.crack), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
    }

    private func shimmer(_ g: GraphicsContext, n: Int, t: Double, moving: Bool) {
        let spots: [(Double, Double, Double)] = [(60, 200, 80), (300, 210, 40), (96, 190, 34)]
        for (i, s) in spots.prefix(n).enumerated() {
            let rise = moving ? WeatherDraw.loop(t, speed: 10, span: 24, phase: Double(i) / 3) : 0
            let wob = moving ? sin(t * 2.2 + Double(i)) * 2 : 0
            var w = Path()
            var y = s.1 - rise
            w.move(to: WeatherDraw.pt(s.0, y))
            while y > s.1 - rise - s.2 {
                w.addCurve(to: WeatherDraw.pt(s.0, y - 20), control1: WeatherDraw.pt(s.0 + 8 + wob, y - 6), control2: WeatherDraw.pt(s.0 - 8 - wob, y - 14))
                y -= 20
            }
            g.stroke(w, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }

    private func termites(_ g: GraphicsContext, n: Int, t: Double, moving: Bool) {
        let bob = moving ? sin(t * 3) * 1.5 : 0, wig = moving ? sin(t * 9) * 1.2 : 0
        WeatherDraw.termite(g, x: 184, y: 170 + bob, s: 1.05, angle: -88, wiggle: wig)
        if n > 1 { WeatherDraw.termite(g, x: 128 + (moving ? sin(t * 0.8) * 4 : 0), y: 207, s: 0.9, angle: 8, wiggle: -wig) }
        var nibbles = Path()
        for (x, y, dx) in [(175.0, 150.0, 5.0), (186, 134, -5), (176, 118, 4)].prefix(n > 1 ? 3 : 1) {
            nibbles.move(to: WeatherDraw.pt(x, y)); nibbles.addLine(to: WeatherDraw.pt(x + dx, y + 1))
        }
        g.stroke(nibbles, with: .color(Color(hex: 0x6B4630)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func crumbs(_ g: GraphicsContext, _ p: WeatherPalette, n: Int, t: Double, moving: Bool) {
        let rest: [(Double, Double, Double)] = [(168, 196, 2.4), (176, 208, 2), (160, 205, 1.8), (196, 188, 2.2), (130, 225, 2), (150, 222, 1.8)]
        for (i, c) in rest.prefix(n).enumerated() {
            let y = moving ? 170 + WeatherDraw.loop(t, speed: 12, span: c.1 - 170, phase: WeatherDraw.rnd(i, 9)) : c.1
            g.fill(WeatherDraw.circle(c.0, y, c.2), with: .color(p.soilDry))
            g.stroke(WeatherDraw.circle(c.0, y, c.2), with: .color(p.crack), lineWidth: 1)
        }
    }

    private func flakes(_ g: GraphicsContext, _ p: WeatherPalette, n: Int, t: Double, moving: Bool) {
        let rest: [(Double, Double, Double)] = [(88, 80, 1.2), (284, 66, 1), (64, 150, 0.9), (300, 130, 1.2), (240, 44, 0.8), (130, 56, 0.9), (150, 160, 0.7), (215, 170, 0.7)]
        for (i, f) in rest.prefix(n).enumerated() {
            let y = moving ? 20 + WeatherDraw.loop(t, speed: 7 + f.2 * 4, span: 190, phase: (f.1 - 20) / 190) : f.1
            let x = f.0 + (moving ? sin(t * 0.7 + Double(i)) * 6 : 0)
            let a = moving ? 0.6 + 0.4 * sin(t * 1.6 + Double(i) * 1.7) : 1
            WeatherDraw.sparkle(g, x: x, y: y, s: f.2, arms: 3, color: p.sparkle, alpha: a)
        }
    }

    private func hail(_ g: GraphicsContext, _ p: WeatherPalette, n: Int, t: Double, moving: Bool) {
        for i in 0..<n {
            let x = WeatherDraw.rnd(i, 5) * 350 + 5
            let y0 = WeatherDraw.rnd(i * 3, 9) * 190 + 6
            let y = moving ? WeatherDraw.loop(t, speed: 60 + WeatherDraw.rnd(i, 2) * 30, span: 215, phase: y0 / 215) : y0
            WeatherDraw.pellet(g, x: x, y: y, r: 3.6 + WeatherDraw.rnd(i, 4) * 2, palette: p, streak: true)
        }
    }

    private func rain(_ g: GraphicsContext, _ p: WeatherPalette, n: Int, t: Double, moving: Bool) {
        var r = Path()
        for i in 0..<n {
            let x = 20 + WeatherDraw.rnd(i, 7) * 330
            let y0 = 10 + WeatherDraw.rnd(i, 8) * 230
            let y = moving ? WeatherDraw.loop(t, speed: 110, span: 310, phase: y0 / 310) : y0
            r.move(to: WeatherDraw.pt(x, y)); r.addLine(to: WeatherDraw.pt(x - 3, y + 12))
        }
        g.stroke(r, with: .color(p.rain.opacity(0.8)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private func puddle(_ g: GraphicsContext, _ p: WeatherPalette, t: Double, moving: Bool, light: Bool) {
        let rx = light ? 110.0 : 150
        let y = Double(Self.floorY) + 4
        g.fill(WeatherDraw.ellipse(180, y, rx, 9), with: .color(p.water))
        g.stroke(WeatherDraw.ellipse(180, y, rx, 9), with: .color(p.waterLine), lineWidth: 2.4)
        let rings: [(Double, Double, Double)] = [(62, 16, 3.5), (300, 14, 3), (140, 8, 2)]
        for (i, ring) in rings.enumerated() where !light || i == 2 {
            let grow = moving ? 0.7 + 0.5 * WeatherDraw.loop(t, speed: 0.4, span: 1, phase: Double(i) / 3) : 1
            let fade = moving ? 1.2 - grow * 0.6 : 1
            g.stroke(WeatherDraw.ellipse(ring.0, y + 1, ring.1 * grow, ring.2 * grow), with: .color(p.waterLine.opacity(fade)),
                     style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
    }

    private func cheer(_ g: GraphicsContext, _ p: WeatherPalette, t: Double, moving: Bool) {
        for (i, s) in [(96.0, 120.0), (270, 150), (60, 170)].enumerated() {
            let a = moving ? 0.55 + 0.45 * sin(t * 1.4 + Double(i) * 2.1) : 1
            WeatherDraw.sparkle(g, x: s.0, y: s.1, s: 0.9, arms: 2, color: p.sparkle, alpha: a)
        }
    }
}

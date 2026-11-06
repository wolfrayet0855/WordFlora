import SwiftUI

/// Canvas drawing for the weather art, in 361 x 340 scene units (shapes from design-preview/events/mock.html): the
/// soil's centre sits at (180, 214), the floor at y 321 (see `WeatherOverlay.sceneRect`).
enum WeatherDraw {
    typealias G = GraphicsContext

    static func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }

    static func circle(_ x: Double, _ y: Double, _ r: Double) -> Path { Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)) }

    static func ellipse(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry))
    }

    /// A friendly sun with 12 short rays.
    static func sun(_ g: G, x: Double, y: Double, r: Double, color: Color) {
        var rays = Path()
        for i in 0..<12 {
            let a = Double(i) * .pi / 6
            rays.move(to: pt(x + cos(a) * (r + 6), y + sin(a) * (r + 6)))
            rays.addLine(to: pt(x + cos(a) * (r + 15), y + sin(a) * (r + 15)))
        }
        g.stroke(rays, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        g.fill(circle(x, y, r), with: .color(color))
    }

    /// A soft rounded cloud, `s` scales the 100 x 44 unit shape centred on (x, y).
    static func cloud(_ g: G, x: Double, y: Double, s: Double, color: Color, alpha: Double) {
        var p = Path()
        p.addPath(circle(x - 22 * s, y + 4 * s, 16 * s))
        p.addPath(circle(x + 2 * s, y - 6 * s, 22 * s))
        p.addPath(circle(x + 26 * s, y + 4 * s, 15 * s))
        p.addRoundedRect(in: CGRect(x: x - 40 * s, y: y + 2 * s, width: 82 * s, height: 18 * s), cornerSize: CGSize(width: 9 * s, height: 9 * s))
        g.fill(p, with: .color(color.opacity(alpha)))
    }

    /// A small leaf blown on the wind, with two short trail lines when it is moving.
    static func leaf(_ g: G, x: Double, y: Double, angle: Double, s: Double, trail: Color?, palette p: WeatherPalette) {
        var c = g
        c.translateBy(x: x, y: y)
        c.rotate(by: .degrees(angle))
        c.scaleBy(x: s, y: s)
        var body = Path()
        body.move(to: pt(-14, 0))
        body.addCurve(to: pt(14, 0), control1: pt(-8, -10), control2: pt(8, -10))
        body.addCurve(to: pt(-14, 0), control1: pt(8, 10), control2: pt(-8, 10))
        c.fill(body, with: .color(p.leaf))
        c.stroke(body, with: .color(p.leafEdge), lineWidth: 1.6)
        var vein = Path(); vein.move(to: pt(-12, 0)); vein.addLine(to: pt(12, 0))
        c.stroke(vein, with: .color(p.leafEdge), lineWidth: 1.4)
        if let trail {
            var t = Path()
            t.move(to: pt(-20, -3)); t.addLine(to: pt(-32, -3))
            t.move(to: pt(-22, 4)); t.addLine(to: pt(-38, 4))
            c.stroke(t, with: .color(trail), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
    }

    /// A cartoon termite: big friendly eyes, round body, no pincers.
    static func termite(_ g: G, x: Double, y: Double, s: Double, angle: Double, wiggle: Double) {
        var c = g
        c.translateBy(x: x, y: y)
        c.rotate(by: .degrees(angle))
        c.scaleBy(x: s, y: s)
        let ink = Color(hex: 0x4A2F18)
        var legs = Path()
        for lx in [-6.0, 0, 6] {
            legs.move(to: pt(lx, -6)); legs.addLine(to: pt(lx - 3 + wiggle, -12))
            legs.move(to: pt(lx, 6)); legs.addLine(to: pt(lx - 3 - wiggle, 12))
        }
        legs.move(to: pt(20, -4)); legs.addQuadCurve(to: pt(28, -10), control: pt(25, -4))
        legs.move(to: pt(20, 4)); legs.addQuadCurve(to: pt(28, 10), control: pt(25, 4))
        c.stroke(legs, with: .color(ink), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        let body = ellipse(0, 0, 13, 7)
        c.fill(body, with: .color(Color(hex: 0xEBC283)))
        c.stroke(body, with: .color(ink), lineWidth: 1.4)
        var bands = Path(); bands.move(to: pt(-5, -6.5)); bands.addLine(to: pt(-5, 6.5)); bands.move(to: pt(3, -6.5)); bands.addLine(to: pt(3, 6.5))
        c.stroke(bands, with: .color(Color(hex: 0xB9854A)), lineWidth: 1.4)
        let head = circle(15, 0, 7)
        c.fill(head, with: .color(Color(hex: 0xD79A55)))
        c.stroke(head, with: .color(ink), lineWidth: 1.4)
        for ey in [-3.0, 3.4] {
            c.fill(circle(17.5, ey, 2.6), with: .color(.white))
            c.stroke(circle(17.5, ey, 2.6), with: .color(ink), lineWidth: 1)
            c.fill(circle(18.2, ey, 1.2), with: .color(Color(hex: 0x2C1A0C)))
        }
    }

    /// A six-armed glint (frost) or a four-armed sparkle (cheer).
    static func sparkle(_ g: G, x: Double, y: Double, s: Double, arms: Int, color: Color, alpha: Double, width: Double = 2.4) {
        var p = Path()
        for i in 0..<arms {
            let a = Double(i) * .pi / Double(arms)
            p.move(to: pt(x - cos(a) * 7 * s, y - sin(a) * 7 * s))
            p.addLine(to: pt(x + cos(a) * 7 * s, y + sin(a) * 7 * s))
        }
        g.stroke(p, with: .color(color.opacity(alpha)), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// A soft round hail pellet with a light top-left.
    static func pellet(_ g: G, x: Double, y: Double, r: Double, palette p: WeatherPalette, streak: Bool) {
        let shape = circle(x, y, r)
        g.fill(shape, with: .radialGradient(Gradient(colors: [p.pellet, Color(hex: 0xCFE0EF)]),
                                            center: pt(x - r * 0.3, y - r * 0.4), startRadius: 0, endRadius: r * 1.6))
        g.stroke(shape, with: .color(p.pelletEdge), lineWidth: 1.2)
        if streak {
            var s = Path(); s.move(to: pt(x - 3, y - r * 1.9 - 3)); s.addLine(to: pt(x - 5, y - r * 1.9 - 8))
            g.stroke(s, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }
    }

    /// A tiny unit hash in 0..<1, so particle places are fixed per index and seed.
    static func rnd(_ i: Int, _ seed: Int) -> Double {
        var x = UInt64(bitPattern: Int64(i &* 7_919 &+ seed &* 104_729)) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9; x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB; x ^= x >> 31
        return Double(x % 10_000) / 10_000
    }

    /// A position that loops through 0..<span at `speed` units a second, offset per particle.
    static func loop(_ t: Double, speed: Double, span: Double, phase: Double) -> Double {
        let v = (t * speed + phase * span).truncatingRemainder(dividingBy: span)
        return v < 0 ? v + span : v
    }
}

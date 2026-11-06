import SwiftUI

// Drawn art for the weather kit: the six Shed helpers, the seven weather stickers and the Weathered badge (tiers 1, 3,
// 7). Flat shapes with a soft ink outline, in the weather palette (design-preview/events tokens, WeatherShelterArt and
// WeatherPalette), drawn in 100 x 100 units and scaled to the frame. Fixed colours, so light and dark draw the same
// picture; only the line ink lightens in dark mode where it sits on a dark surface. Every view here is one image for
// VoiceOver (with the caller's label) or hidden where the row's words already say it.

enum KitInk {
    static let line = Color(hex: 0x2C3E2C)
    static let lineDark = Color(hex: 0xD4EDD4)
    static let soil = Color(hex: 0x7A5238)
    static let wood = Color(hex: 0xB98558)
    static let leaf = Color(hex: 0x6DAF4A)
    static let leafEdge = Color(hex: 0x2E6B2E)
    static let sky = Color(hex: 0x5B9BD5)
    static let skyEdge = Color(hex: 0x2F5F94)
    static let sun = Color(hex: 0xFFC04A)
    static let cream = Color(hex: 0xFFFDF5)
    static let red = Color(hex: 0xE4544A)
    static let yellow = Color(hex: 0xF2B544)
    static let green = Color(hex: 0x6FB36F)
    static let blue = Color(hex: 0x5B8FD6)
    static let orange = Color(hex: 0xF08A3C)
    static let frost = Color(hex: 0x4E86AD)
    static let cloudEdge = Color(hex: 0x7C93AD)
}

private extension GraphicsContext {
    /// Draw in 100 x 100 units centred in `size`.
    func units(_ size: CGSize) -> GraphicsContext {
        var g = self
        let s = min(size.width, size.height) / 100
        g.translateBy(x: (size.width - 100 * s) / 2, y: (size.height - 100 * s) / 2)
        g.scaleBy(x: s, y: s)
        return g
    }

    func fillStroke(_ p: Path, _ fill: Color, _ edge: Color, _ w: Double = 2.4) {
        self.fill(p, with: .color(fill))
        self.stroke(p, with: .color(edge), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
    }

    func line(_ p: Path, _ c: Color, _ w: Double) {
        stroke(p, with: .color(c), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
    }
}

private func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
private func disc(_ x: Double, _ y: Double, _ r: Double) -> Path { Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)) }
private func oval(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double) -> Path {
    Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry))
}

/// A small two-leaf sprout standing on (x, y), `s` scales it.
private func sprout(_ g: GraphicsContext, x: Double, y: Double, s: Double) {
    var stem = Path(); stem.move(to: pt(x, y)); stem.addLine(to: pt(x, y - 16 * s))
    g.line(stem, KitInk.leafEdge, 2.6 * s)
    for side in [-1.0, 1.0] {
        var leaf = Path()
        leaf.move(to: pt(x, y - 12 * s))
        leaf.addQuadCurve(to: pt(x + side * 13 * s, y - 20 * s), control: pt(x + side * 3 * s, y - 24 * s))
        leaf.addQuadCurve(to: pt(x, y - 12 * s), control: pt(x + side * 12 * s, y - 10 * s))
        g.fillStroke(leaf, KitInk.leaf, KitInk.leafEdge, 1.8 * s)
    }
}

/// A soft cloud centred on (x, y).
private func cloud(_ g: GraphicsContext, x: Double, y: Double, s: Double, fill: Color = .white) {
    var p = Path()
    p.addPath(disc(x - 10 * s, y + 2 * s, 8 * s))
    p.addPath(disc(x + 1 * s, y - 4 * s, 11 * s))
    p.addPath(disc(x + 12 * s, y + 2 * s, 7.5 * s))
    p.addRoundedRect(in: CGRect(x: x - 18 * s, y: y + 1 * s, width: 37 * s, height: 9 * s), cornerSize: CGSize(width: 4.5 * s, height: 4.5 * s))
    g.fill(p, with: .color(fill))
    g.stroke(p, with: .color(KitInk.cloudEdge), lineWidth: 2 * s)
    g.fill(p, with: .color(fill))           // the inner lines of the overlapping circles are covered again
}

/// A six-armed frost glint.
private func glint(_ g: GraphicsContext, x: Double, y: Double, r: Double, color: Color, w: Double) {
    var p = Path()
    for i in 0..<3 {
        let a = Double(i) * .pi / 3
        p.move(to: pt(x - cos(a) * r, y - sin(a) * r)); p.addLine(to: pt(x + cos(a) * r, y + sin(a) * r))
    }
    g.line(p, color, w)
}

// MARK: - Helpers

/// The Shed's helper pictures (shade cloth, bug cover, wind net, frost cloth, umbrella, raised bed).
struct HelperArt: View {
    let helper: WeatherHelper
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in HelperArt.draw(helper, ctx.units(size), dark: dark) }
            .accessibilityHidden(true)
    }

    static func draw(_ h: WeatherHelper, _ g: GraphicsContext, dark: Bool) {
        let ink = dark ? KitInk.lineDark : KitInk.line
        switch h {
        case .shadeCloth:
            WeatherDrawSun.draw(g, x: 74, y: 24, r: 10)
            var poles = Path(); poles.move(to: pt(22, 44)); poles.addLine(to: pt(22, 86)); poles.move(to: pt(80, 36)); poles.addLine(to: pt(80, 86))
            g.line(poles, KitInk.soil, 4.5)
            var cloth = Path()
            cloth.move(to: pt(14, 46)); cloth.addLine(to: pt(88, 34)); cloth.addLine(to: pt(88, 50)); cloth.addLine(to: pt(14, 62)); cloth.closeSubpath()
            g.fillStroke(cloth, Color(hex: 0x6B8F71), Color(hex: 0x3E6247), 2.4)
            var weave = Path()
            for x in stride(from: 26.0, through: 78, by: 13) { weave.move(to: pt(x, 44.5 - (x - 14) * 0.16)); weave.addLine(to: pt(x, 60.5 - (x - 14) * 0.16)) }
            g.line(weave, Color(hex: 0x3E6247).opacity(0.6), 1.2)
            sprout(g, x: 51, y: 86, s: 1)
            ground(g, ink)
        case .bugCover, .windNet:
            let frame = h == .bugCover ? Color(hex: 0x5E8F1F) : ink
            sprout(g, x: 50, y: 84, s: 1.1)
            var hoop = Path()
            hoop.move(to: pt(14, 86)); hoop.addCurve(to: pt(50, 22), control1: pt(14, 50), control2: pt(30, 22))
            hoop.addCurve(to: pt(86, 86), control1: pt(70, 22), control2: pt(86, 50))
            var inside = hoop; inside.closeSubpath()
            var c = g
            c.clip(to: inside)
            var mesh = Path()
            for i in stride(from: -60.0, through: 120, by: 13) {
                mesh.move(to: pt(i, 86)); mesh.addLine(to: pt(i + 64, 22))
                mesh.move(to: pt(i + 64, 86)); mesh.addLine(to: pt(i, 22))
            }
            c.line(mesh, frame.opacity(h == .bugCover ? 0.55 : 0.4), 1.3)
            g.line(hoop, frame, 3.2)
            if h == .windNet {
                var gust = Path()
                gust.move(to: pt(4, 40)); gust.addQuadCurve(to: pt(22, 36), control: pt(14, 34))
                gust.move(to: pt(2, 52)); gust.addQuadCurve(to: pt(16, 49), control: pt(10, 47))
                g.line(gust, Color(hex: 0x7FA0BD), 2.6)
                for (x, y) in [(36.0, 44.0), (62, 38), (70, 60)] { g.stroke(disc(x, y, 2.4), with: .color(KitInk.blue), lineWidth: 1.4) }
            } else {
                // A friendly ladybird walking by outside the cover.
                g.fillStroke(oval(84, 30, 7, 6), KitInk.red, KitInk.line, 1.6)
                g.fill(disc(90, 30, 3.2), with: .color(KitInk.line))
                g.fill(disc(82, 28, 1.4), with: .color(KitInk.line)); g.fill(disc(83, 33, 1.4), with: .color(KitInk.line))
            }
            ground(g, ink)
        case .frostCloth:
            sprout(g, x: 50, y: 84, s: 1.1)
            var cloth = Path()
            cloth.move(to: pt(16, 86)); cloth.addCurve(to: pt(50, 28), control1: pt(14, 50), control2: pt(30, 28))
            cloth.addCurve(to: pt(84, 86), control1: pt(70, 28), control2: pt(86, 50))
            cloth.addCurve(to: pt(16, 86), control1: pt(62, 80), control2: pt(38, 92))
            g.fillStroke(cloth, Color(hex: 0xCFE6F5).opacity(0.85), KitInk.frost, 2.4)
            var fold = Path(); fold.move(to: pt(38, 40)); fold.addQuadCurve(to: pt(34, 80), control: pt(30, 60))
            fold.move(to: pt(62, 40)); fold.addQuadCurve(to: pt(66, 80), control: pt(70, 60))
            g.line(fold, KitInk.frost.opacity(0.5), 1.4)
            for (x, y, r) in [(50.0, 18.0, 6.0), (24, 30, 4.5), (78, 28, 5)] { glint(g, x: x, y: y, r: r, color: KitInk.frost, w: 2) }
            ground(g, ink)
        case .umbrella:
            var pole = Path(); pole.move(to: pt(50, 30)); pole.addLine(to: pt(50, 80)); pole.addQuadCurve(to: pt(42, 82), control: pt(50, 88))
            g.line(pole, KitInk.soil, 4)
            var canopy = Path()
            canopy.move(to: pt(10, 50)); canopy.addQuadCurve(to: pt(90, 50), control: pt(50, -6))
            canopy.addQuadCurve(to: pt(70, 50), control: pt(80, 44)); canopy.addQuadCurve(to: pt(50, 50), control: pt(60, 44))
            canopy.addQuadCurve(to: pt(30, 50), control: pt(40, 44)); canopy.addQuadCurve(to: pt(10, 50), control: pt(20, 44))
            canopy.closeSubpath()
            g.fillStroke(canopy, KitInk.sky, KitInk.skyEdge, 2.4)
            var ribs = Path()
            for x in [30.0, 50, 70] { ribs.move(to: pt(50, 23)); ribs.addQuadCurve(to: pt(x, 50), control: pt((x + 50) / 2, 26)) }
            g.line(ribs, KitInk.skyEdge, 1.4)
            for (x, y) in [(24.0, 12.0), (76, 10), (88, 30), (12, 30)] {
                g.fill(disc(x, y, 3.6), with: .color(.white)); g.stroke(disc(x, y, 3.6), with: .color(Color(hex: 0x8FA6BB)), lineWidth: 1.3)
            }
            sprout(g, x: 70, y: 86, s: 0.8)
            ground(g, ink)
        case .raisedBed:
            var puddle = oval(50, 88, 44, 6)
            g.fill(puddle, with: .color(Color(hex: 0x5FA5E6).opacity(0.55)))
            puddle = oval(50, 88, 44, 6)
            g.stroke(puddle, with: .color(Color(hex: 0x4C7396)), lineWidth: 1.4)
            var legs = Path(); legs.move(to: pt(20, 72)); legs.addLine(to: pt(20, 86)); legs.move(to: pt(80, 72)); legs.addLine(to: pt(80, 86))
            g.line(legs, KitInk.soil, 4.5)
            g.fill(oval(50, 56, 32, 5), with: .color(Color(hex: 0x8A5F3C)))
            let box = Path(roundedRect: CGRect(x: 12, y: 56, width: 76, height: 18), cornerRadius: 3)
            g.fillStroke(box, KitInk.wood, KitInk.soil, 2.4)
            var planks = Path(); planks.move(to: pt(14, 65)); planks.addLine(to: pt(86, 65))
            planks.move(to: pt(37, 56)); planks.addLine(to: pt(37, 74)); planks.move(to: pt(63, 56)); planks.addLine(to: pt(63, 74))
            g.line(planks, KitInk.soil.opacity(0.7), 1.4)
            sprout(g, x: 34, y: 56, s: 1)
            sprout(g, x: 64, y: 56, s: 1.15)
        }
    }

    private static func ground(_ g: GraphicsContext, _ ink: Color) {
        var p = Path(); p.move(to: pt(10, 87)); p.addLine(to: pt(90, 87))
        g.line(p, ink.opacity(0.55), 2.2)
    }
}

/// A friendly sun with short rays (helpers and the badge).
enum WeatherDrawSun {
    static func draw(_ g: GraphicsContext, x: Double, y: Double, r: Double) {
        var rays = Path()
        for i in 0..<8 {
            let a = Double(i) * .pi / 4
            rays.move(to: pt(x + cos(a) * (r + 3), y + sin(a) * (r + 3))); rays.addLine(to: pt(x + cos(a) * (r + 7), y + sin(a) * (r + 7)))
        }
        g.line(rays, KitInk.sun, 2.6)
        g.fillStroke(disc(x, y, r), KitInk.sun, Color(hex: 0xD49A1E), 1.6)
    }
}

// MARK: - Stickers

/// The seven weather stickers, each on a cream sticker backing so it reads the same on light and dark pages.
struct StickerArt: View {
    let sticker: WeatherSticker

    var body: some View {
        Canvas { ctx, size in StickerArt.draw(sticker, ctx.units(size)) }
            .accessibilityHidden(true)
    }

    static func draw(_ s: WeatherSticker, _ g: GraphicsContext) {
        g.fill(disc(50, 50, 48), with: .color(KitInk.cream))
        let ink = KitInk.line
        switch s {
        case .rainbow:
            for (i, c) in [KitInk.red, KitInk.yellow, KitInk.green, KitInk.blue].enumerated() {
                var arc = Path()
                let r = 34.0 - Double(i) * 7
                arc.addArc(center: pt(50, 62), radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                g.line(arc, c, 6.5)
            }
            cloud(g, x: 22, y: 64, s: 0.8)
            cloud(g, x: 78, y: 66, s: 0.7)
        case .frogFriend:
            let skin = Color(hex: 0x7BC05A), edge = Color(hex: 0x2E6B2E)
            for x in [34.0, 66] { g.fillStroke(disc(x, 34, 12), skin, edge, 2.2) }
            g.fillStroke(oval(50, 58, 34, 24), skin, edge, 2.4)
            for x in [34.0, 66] { g.fill(disc(x, 34, 7.5), with: .color(.white)); g.fill(disc(x + 1.5, 35, 3.8), with: .color(ink)) }
            var smile = Path(); smile.move(to: pt(34, 60)); smile.addQuadCurve(to: pt(66, 60), control: pt(50, 74))
            g.line(smile, edge, 2.6)
            for x in [27.0, 73] { g.fill(oval(x, 62, 5, 3.2), with: .color(Color(hex: 0xF29C9C).opacity(0.9))) }
        case .ladybird:
            g.fillStroke(disc(50, 30, 11), ink, ink, 1)
            for x in [45.0, 55] { g.fill(disc(x, 27, 2.6), with: .color(.white)) }
            g.fillStroke(oval(50, 58, 30, 28), KitInk.red, ink, 2.6)
            var split = Path(); split.move(to: pt(50, 31)); split.addLine(to: pt(50, 85))
            g.line(split, ink, 2.2)
            for (x, y, r) in [(36.0, 50.0, 5.0), (64, 50, 5), (38, 68, 4.4), (62, 68, 4.4), (50, 40, 3)] where !(x == 50) {
                g.fill(disc(x, y, r), with: .color(ink))
            }
            var feelers = Path(); feelers.move(to: pt(45, 21)); feelers.addQuadCurve(to: pt(38, 12), control: pt(42, 14))
            feelers.move(to: pt(55, 21)); feelers.addQuadCurve(to: pt(62, 12), control: pt(58, 14))
            g.line(feelers, ink, 2)
        case .kite:
            var string = Path(); string.move(to: pt(50, 70)); string.addCurve(to: pt(30, 94), control1: pt(60, 80), control2: pt(22, 82))
            g.line(string, ink.opacity(0.8), 1.6)
            for (x, y) in [(52.0, 80.0), (34, 88)] {
                var bow = Path(); bow.move(to: pt(x - 5, y - 3)); bow.addLine(to: pt(x + 5, y + 3)); bow.addLine(to: pt(x + 5, y - 3)); bow.addLine(to: pt(x - 5, y + 3)); bow.closeSubpath()
                g.fillStroke(bow, KitInk.blue, ink, 1.2)
            }
            let top = pt(50, 10), right = pt(76, 36), bottom = pt(50, 70), left = pt(24, 36), mid = pt(50, 36)
            for (a, b, c) in [(top, right, KitInk.orange), (right, bottom, KitInk.yellow), (bottom, left, KitInk.orange), (left, top, KitInk.yellow)] {
                var q = Path(); q.move(to: mid); q.addLine(to: a); q.addLine(to: b); q.closeSubpath()
                g.fill(q, with: .color(c))
            }
            var kite = Path(); kite.move(to: top); kite.addLine(to: right); kite.addLine(to: bottom); kite.addLine(to: left); kite.closeSubpath()
            g.line(kite, ink, 2.4)
            var cross = Path(); cross.move(to: top); cross.addLine(to: bottom); cross.move(to: left); cross.addLine(to: right)
            g.line(cross, ink.opacity(0.6), 1.4)
        case .snowflake:
            let blue = Color(hex: 0x4F93CF)
            for i in 0..<6 {
                var c = g
                c.translateBy(x: 50, y: 50)
                c.rotate(by: .degrees(Double(i) * 60))
                var arm = Path(); arm.move(to: .zero); arm.addLine(to: pt(0, -36))
                arm.move(to: pt(0, -16)); arm.addLine(to: pt(-9, -25)); arm.move(to: pt(0, -16)); arm.addLine(to: pt(9, -25))
                arm.move(to: pt(0, -27)); arm.addLine(to: pt(-6, -33)); arm.move(to: pt(0, -27)); arm.addLine(to: pt(6, -33))
                c.line(arm, blue, 4.2)
            }
            g.fillStroke(disc(50, 50, 6), .white, blue, 2.4)
        case .sunHat:
            let straw = Color(hex: 0xE8C27A), strawEdge = Color(hex: 0x9A6B2A)
            g.fillStroke(oval(50, 62, 42, 15), straw, strawEdge, 2.4)
            var crown = Path()
            crown.move(to: pt(28, 62)); crown.addCurve(to: pt(72, 62), control1: pt(28, 26), control2: pt(72, 26))
            crown.addQuadCurve(to: pt(28, 62), control: pt(50, 70))
            g.fillStroke(crown, straw, strawEdge, 2.4)
            var band = Path(); band.move(to: pt(29, 54)); band.addQuadCurve(to: pt(71, 54), control: pt(50, 62))
            g.line(band, KitInk.red, 6)
            for k in 0..<5 {
                let a = Double(k) * 2 * .pi / 5
                g.fill(disc(66 + cos(a) * 4.2, 52 + sin(a) * 4.2, 3.4), with: .color(.white))
            }
            g.fill(disc(66, 52, 2.4), with: .color(KitInk.yellow))
        case .puddleBoots:
            g.fillStroke(oval(50, 82, 40, 9), Color(hex: 0x8CC7F0), Color(hex: 0x4C7396), 2)
            for (x, tilt) in [(36.0, -6.0), (64, 6)] {
                var c = g
                c.translateBy(x: x, y: 50); c.rotate(by: .degrees(tilt))
                var boot = Path()
                boot.move(to: pt(-9, -30)); boot.addLine(to: pt(7, -30)); boot.addLine(to: pt(7, 14))
                boot.addQuadCurve(to: pt(19, 22), control: pt(19, 14)); boot.addLine(to: pt(19, 28)); boot.addLine(to: pt(-9, 28)); boot.closeSubpath()
                c.fillStroke(boot, KitInk.yellow, ink, 2.4)
                let sole = Path(roundedRect: CGRect(x: -10, y: 26, width: 30, height: 5), cornerRadius: 2)
                c.fillStroke(sole, KitInk.soil, ink, 1.6)
                var cuff = Path(); cuff.move(to: pt(-9, -24)); cuff.addLine(to: pt(7, -24))
                c.line(cuff, ink.opacity(0.6), 1.6)
            }
            for (x, y) in [(18.0, 72.0), (84, 70)] {
                var drop = Path(); drop.move(to: pt(x, y - 6)); drop.addQuadCurve(to: pt(x, y + 3), control: pt(x + 5, y + 1))
                drop.addQuadCurve(to: pt(x, y - 6), control: pt(x - 5, y + 1))
                g.fill(drop, with: .color(Color(hex: 0x5B9BD5)))
            }
        }
    }
}

// MARK: - Weathered badge

/// The Weathered badge in the badge shelf's frame (twelve-sided medal, cream face, one to three pips): bronze at 1
/// puzzle, silver at 3, gold at 7. The picture grows with the tier: a sprout standing tall under a passing cloud, then
/// with a rainbow, then with the sun out too.
struct WeatheredBadgeArt: View {
    let tier: Int

    var body: some View {
        Canvas { ctx, size in WeatheredBadgeArt.draw(tier: tier, ctx.units(size)) }
            .accessibilityHidden(true)
    }

    static func colours(_ tier: Int) -> (outer: Color, inner: Color) {
        switch tier {
        case 3: return (Color(hex: 0xD49A1E), Color(hex: 0xF5C84C))
        case 2: return (Color(hex: 0x8D9AA6), Color(hex: 0xC5CED6))
        default: return (Color(hex: 0x9A5F2A), Color(hex: 0xC98A4B))
        }
    }

    static func draw(tier rawTier: Int, _ g: GraphicsContext) {
        let tier = min(3, max(1, rawTier))
        let (outer, inner) = colours(tier)
        func medal(_ scale: Double) -> Path {
            var p = Path()
            for i in 0..<12 {
                let a = Double(i) * .pi / 6 - .pi / 2
                let q = pt(50 + cos(a) * 46 * scale, 50 + sin(a) * 46 * scale)
                if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
            }
            p.closeSubpath()
            return p
        }
        g.fill(medal(1), with: .color(outer))
        g.fill(medal(0.92), with: .color(inner))
        g.fillStroke(disc(50, 48, 33), KitInk.cream, outer, 2)

        var face = g
        face.clip(to: disc(50, 48, 32))
        if tier >= 2 {
            for (i, c) in [KitInk.red, KitInk.yellow, KitInk.green, KitInk.blue].enumerated() {
                var arc = Path()
                arc.addArc(center: pt(50, 60), radius: 24 - Double(i) * 4.2, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                face.line(arc, c.opacity(0.9), 3.6)
            }
        }
        if tier >= 3 { WeatherDrawSun.draw(face, x: 68, y: 30, r: 6.5) }
        cloud(face, x: tier >= 3 ? 39 : 50, y: 31, s: 0.75)
        if tier == 1 {
            var rain = Path()
            for x in [42.0, 50, 58] { rain.move(to: pt(x, 41)); rain.addLine(to: pt(x - 1.5, 45)) }
            face.line(rain, KitInk.blue, 2)
        }
        var soil = Path(); soil.addEllipse(in: CGRect(x: 36, y: 66, width: 28, height: 7))
        face.fill(soil, with: .color(KitInk.soil.opacity(0.85)))
        sprout(face, x: 50, y: 69, s: 1.2)

        let xs: [Double] = tier == 1 ? [50] : tier == 2 ? [45, 55] : [40, 50, 60]
        for x in xs { g.fillStroke(disc(x, 91, 3.6), inner, .white, 1.4) }
    }
}

/// A badge's picture: the shelf's image art, or the drawn Weathered badge.
struct BadgeArtView: View {
    let badgeId: String
    let tier: Int
    /// Badges drawn in code rather than shipped as image art.
    static let drawn: Set<String> = ["weathered"]

    var body: some View {
        if Self.drawn.contains(badgeId) {
            WeatheredBadgeArt(tier: tier).aspectRatio(1, contentMode: .fit)
        } else {
            Image("badge_\(badgeId)_t\(max(1, min(3, tier)))").resizable().scaledToFit()
        }
    }
}

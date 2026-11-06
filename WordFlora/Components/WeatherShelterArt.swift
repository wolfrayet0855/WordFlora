import SwiftUI

/// The Shed's weather helpers drawn over a snug plant (mockup `events/snug`), in the 361 x 310 scene units. The helper
/// covers the plant and the weather shows on it (rain beads, frost), so preparing is visible and the plant stays cosy.
enum WeatherShelterArt {
    private static let floor = Double(WeatherOverlay.floorY)

    static func draw(_ g: GraphicsContext, _ h: WeatherArt.Helper, palette p: WeatherPalette) {
        switch h {
        case .windNet: net(g, p, top: 40, inset: 20, mesh: p.net.opacity(0.35), frame: p.net)
        case .bugCover: net(g, p, top: 70, inset: 62, mesh: Color(hex: 0x5E8F1F).opacity(0.45), frame: Color(hex: 0x5E8F1F))
        case .frostCloth: frostCloth(g)
        case .shadeCloth: shadeCloth(g)
        case .umbrella: umbrella(g)
        case .raisedBed: raisedBed(g)
        }
    }

    private static func arch(top: Double, inset: Double) -> Path {
        var a = Path()
        a.move(to: WeatherDraw.pt(inset, floor))
        a.addCurve(to: WeatherDraw.pt(180, top), control1: WeatherDraw.pt(inset, 150), control2: WeatherDraw.pt(80, top))
        a.addCurve(to: WeatherDraw.pt(361 - inset, floor), control1: WeatherDraw.pt(280, top), control2: WeatherDraw.pt(361 - inset, 150))
        return a
    }

    /// A hooped net with a diamond mesh and a few beads of rain caught on it.
    private static func net(_ g: GraphicsContext, _ p: WeatherPalette, top: Double, inset: Double, mesh: Color, frame: Color) {
        let hoop = arch(top: top, inset: inset)
        var inside = hoop; inside.closeSubpath()
        var c = g
        c.clip(to: inside)
        var lattice = Path()
        for i in stride(from: -300.0, through: 400, by: 46) {
            lattice.move(to: WeatherDraw.pt(i, floor)); lattice.addLine(to: WeatherDraw.pt(i + 170, 0))
            lattice.move(to: WeatherDraw.pt(i + 170, floor)); lattice.addLine(to: WeatherDraw.pt(i, 0))
        }
        c.stroke(lattice, with: .color(mesh), lineWidth: 2.4)
        for i in 0..<9 {
            let x = inset + 20 + WeatherDraw.rnd(i, 21) * (321 - 2 * inset - 40), y = top + 30 + WeatherDraw.rnd(i, 22) * (220 - top)
            c.stroke(WeatherDraw.circle(x, y, 3.2), with: .color(p.rain), lineWidth: 1.4)
        }
        g.stroke(hoop, with: .color(frame), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
        var base = Path(); base.move(to: WeatherDraw.pt(inset, floor)); base.addLine(to: WeatherDraw.pt(361 - inset, floor))
        g.stroke(base, with: .color(frame), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
    }

    /// A soft frost cloth draped over a hoop, frost glints resting on top.
    private static func frostCloth(_ g: GraphicsContext) {
        var cloth = arch(top: 50, inset: 40)
        cloth.addCurve(to: WeatherDraw.pt(40, floor), control1: WeatherDraw.pt(240, floor - 10), control2: WeatherDraw.pt(120, floor + 10))
        g.fill(cloth, with: .color(Color(hex: 0xCFE6F5).opacity(0.55)))
        g.stroke(cloth, with: .color(Color(hex: 0x4E86AD)), style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
        for (x, y) in [(150.0, 62.0), (200, 60), (110, 90), (250, 86)] {
            WeatherDraw.sparkle(g, x: x, y: y, s: 0.7, arms: 3, color: .white, alpha: 0.95, width: 2)
        }
    }

    /// A green shade cloth on two poles, its cool shadow over the plant.
    private static func shadeCloth(_ g: GraphicsContext) {
        g.fill(WeatherDraw.ellipse(180, 210, 90, 16), with: .color(Color(hex: 0x3E6247).opacity(0.18)))
        var poles = Path()
        poles.move(to: WeatherDraw.pt(70, 66)); poles.addLine(to: WeatherDraw.pt(70, floor))
        poles.move(to: WeatherDraw.pt(292, 52)); poles.addLine(to: WeatherDraw.pt(292, floor))
        g.stroke(poles, with: .color(Color(hex: 0x7A5238)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        var cloth = Path()
        cloth.move(to: WeatherDraw.pt(50, 72)); cloth.addLine(to: WeatherDraw.pt(312, 40))
        cloth.addLine(to: WeatherDraw.pt(312, 62)); cloth.addLine(to: WeatherDraw.pt(50, 96)); cloth.closeSubpath()
        g.fill(cloth, with: .color(Color(hex: 0x6B8F71).opacity(0.92)))
        g.stroke(cloth, with: .color(Color(hex: 0x3E6247)), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
    }

    /// A big garden umbrella, hail pellets resting on its top.
    private static func umbrella(_ g: GraphicsContext) {
        var pole = Path(); pole.move(to: WeatherDraw.pt(180, 52)); pole.addLine(to: WeatherDraw.pt(180, 96))
        g.stroke(pole, with: .color(Color(hex: 0x7A5238)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        var canopy = Path()
        canopy.move(to: WeatherDraw.pt(48, 100)); canopy.addQuadCurve(to: WeatherDraw.pt(312, 100), control: WeatherDraw.pt(180, -6))
        canopy.addQuadCurve(to: WeatherDraw.pt(48, 100), control: WeatherDraw.pt(180, 84)); canopy.closeSubpath()
        g.fill(canopy, with: .color(Color(hex: 0x5B9BD5)))
        g.stroke(canopy, with: .color(Color(hex: 0x2F5F94)), style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
        var ribs = Path()
        for x in [114.0, 180, 246] { ribs.move(to: WeatherDraw.pt(180, 48)); ribs.addQuadCurve(to: WeatherDraw.pt(x, 92), control: WeatherDraw.pt((x + 180) / 2, 56)) }
        g.stroke(ribs, with: .color(Color(hex: 0x2F5F94)), lineWidth: 1.6)
        let pal = WeatherPalette(dark: false)
        for (x, y) in [(120.0, 64.0), (160, 52), (214, 54), (250, 70)] { WeatherDraw.pellet(g, x: x, y: y, r: 3.8, palette: pal, streak: false) }
    }

    /// A wooden raised bed under the pot, lifting it clear of the puddle.
    private static func raisedBed(_ g: GraphicsContext) {
        let wood = Color(hex: 0xB98558), edge = Color(hex: 0x7A5238)
        var g = g
        g.translateBy(x: 0, y: floor - 297)        // drawn for a floor at 297: the top board hides the pot's foot
        let box = Path(roundedRect: CGRect(x: 70, y: 276, width: 221, height: 22), cornerRadius: 3)
        g.fill(box, with: .color(wood))
        g.stroke(box, with: .color(edge), lineWidth: 2.4)
        var planks = Path(); planks.move(to: WeatherDraw.pt(72, 287)); planks.addLine(to: WeatherDraw.pt(289, 287))
        for x in [140.0, 220] { planks.move(to: WeatherDraw.pt(x, 276)); planks.addLine(to: WeatherDraw.pt(x, 298)) }
        g.stroke(planks, with: .color(edge.opacity(0.7)), lineWidth: 1.6)
        var legs = Path()
        for x in [84.0, 277] { legs.move(to: WeatherDraw.pt(x, 298)); legs.addLine(to: WeatherDraw.pt(x, 308)) }
        g.stroke(legs, with: .color(edge), style: StrokeStyle(lineWidth: 5, lineCap: .round))
    }
}

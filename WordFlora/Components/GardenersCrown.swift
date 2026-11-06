import SwiftUI

/// The Gardener's Crown (design-preview/endgame `crown()`): a ring of leaves with seven small flowers, a flower crown
/// rather than a royal one. `gold` turns the petals gold (every plant in full bloom). Drawn in a 120 x 74 box; the
/// glow sits behind it. Decorative by default; `labelled` reads it as one image.
struct GardenersCrown: View {
    var gold = false
    var glow = true
    var labelled = false

    static func label(gold: Bool) -> String { gold ? "The Gardener's Crown, in gold." : "The Gardener's Crown." }

    private static func bez(_ t: Double, _ a: CGPoint, _ c: CGPoint, _ b: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x, y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }

    var body: some View {
        Canvas { ctx, size in
            var g = ctx
            g.scaleBy(x: size.width / 120, y: size.height / 74)
            if glow {
                g.fill(Path(ellipseIn: CGRect(x: 6, y: 4, width: 108, height: 66)),
                       with: .radialGradient(Gradient(colors: [Color(hex: 0xF6C445).opacity(0.35), .clear]), center: CGPoint(x: 60, y: 40), startRadius: 0, endRadius: 56))
            }
            let a = CGPoint(x: 8, y: 40), b = CGPoint(x: 112, y: 40), f = CGPoint(x: 60, y: 66)
            var back = Path(); back.move(to: a); back.addQuadCurve(to: b, control: CGPoint(x: 60, y: 16))
            g.stroke(back, with: .color(Color(hex: 0x6BA35C).opacity(0.55)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            for i in 0...12 {
                let p = Self.bez(Double(i) / 12, a, f, b)
                var leaf = g
                leaf.translateBy(x: p.x, y: p.y - 2); leaf.rotate(by: .degrees(-40 + Double(i) * 7))
                leaf.fill(Path(ellipseIn: CGRect(x: -7.5, y: -3.8, width: 15, height: 7.6)), with: .color(Color(hex: i % 2 == 1 ? 0x5E9E4E : 0x3F8A4A)))
            }
            var front = Path(); front.move(to: a); front.addQuadCurve(to: b, control: f)
            g.stroke(front, with: .color(Color(hex: 0x3F8A4A)), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
            let cols: [UInt32] = gold ? [0xF2B705, 0xE8A838, 0xF6C445, 0xFFE08A, 0xE8A838, 0xF6C445, 0xF2B705]
                                      : [0xF2788A, 0xE8A838, 0xB89AE0, 0xFFFFFF, 0xE8A838, 0xB89AE0, 0xF2788A]
            for (i, c) in cols.enumerated() {
                let p = Self.bez(0.08 + Double(i) * 0.84 / 6, a, f, b)
                let r = i == 3 ? 8.5 : 6.6, lift = i == 3 ? 7.0 : (abs(3 - i) < 2 ? 3 : 0)
                let edge = c == 0xFFFFFF ? Color(hex: 0xD9CBB0) : Color.black.opacity(0.12)
                for k in 0..<5 {
                    let ang = Double(k) * 72 * .pi / 180
                    let petal = WeatherDraw.circle(p.x + sin(ang) * r * 0.75, p.y - lift - cos(ang) * r * 0.75, r * 0.62)
                    g.fill(petal, with: .color(Color(hex: c)))
                    g.stroke(petal, with: .color(edge), lineWidth: 0.8)
                }
                let centre: UInt32 = gold || c == 0xE8A838 ? 0xB5651D : 0xF6C445
                g.fill(WeatherDraw.circle(p.x, p.y - lift, r * 0.36), with: .color(Color(hex: centre)))
            }
        }
        .aspectRatio(120 / 74, contentMode: .fit)
        .artLabel(labelled ? Self.label(gold: gold) : nil)
    }
}

#Preview("Crown") {
    VStack { GardenersCrown().frame(width: 220); GardenersCrown(gold: true).frame(width: 220) }.padding()
}

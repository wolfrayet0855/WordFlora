import SwiftUI
import UIKit

/// Paints a catalog pot in the shared 120 x 100 pot box (design-preview/pots/pots.json `geometry`): body, light and
/// shade strips, the pattern clipped to the body, then the rim and its shine. A pot to earn is a soft outline:
/// a pale fill, a dashed ink edge on body and rim, no strips or shine, and its pattern in ink at 55%.
enum PotPainter {
    enum Style: Hashable { case full, toEarn }

    static let bodyPath = Path { q in
        q.move(to: CGPoint(x: 18, y: 20)); q.addLine(to: CGPoint(x: 102, y: 20)); q.addLine(to: CGPoint(x: 92, y: 88))
        q.addQuadCurve(to: CGPoint(x: 82, y: 96), control: CGPoint(x: 91, y: 96)); q.addLine(to: CGPoint(x: 38, y: 96))
        q.addQuadCurve(to: CGPoint(x: 28, y: 88), control: CGPoint(x: 29, y: 96)); q.closeSubpath()
    }
    private static let lightStrip = Path { q in
        q.move(to: CGPoint(x: 18, y: 20)); q.addLine(to: CGPoint(x: 34, y: 20)); q.addLine(to: CGPoint(x: 42, y: 96))
        q.addLine(to: CGPoint(x: 38, y: 96)); q.addQuadCurve(to: CGPoint(x: 28, y: 88), control: CGPoint(x: 29, y: 96)); q.closeSubpath()
    }
    private static let shadeStrip = Path { q in
        q.move(to: CGPoint(x: 102, y: 20)); q.addLine(to: CGPoint(x: 88, y: 20)); q.addLine(to: CGPoint(x: 82, y: 96))
        q.addQuadCurve(to: CGPoint(x: 92, y: 88), control: CGPoint(x: 91, y: 96)); q.closeSubpath()
    }
    private static let rimRect = CGRect(x: 10, y: 4, width: 100, height: 18)
    /// The soil top inside the rim (the stage's 80 x 20 soil ellipse at 140 pt).
    static let soilRect = CGRect(x: 26, y: 5, width: 68, height: 17)

    private static let sparkle = Path { q in
        q.move(to: CGPoint(x: 0, y: -7))
        q.addQuadCurve(to: CGPoint(x: 7, y: 0), control: CGPoint(x: 1, y: -1.5))
        q.addQuadCurve(to: CGPoint(x: 0, y: 7), control: CGPoint(x: 1, y: 1.5))
        q.addQuadCurve(to: CGPoint(x: -7, y: 0), control: CGPoint(x: -1, y: 1.5))
        q.addQuadCurve(to: CGPoint(x: 0, y: -7), control: CGPoint(x: -1, y: -1.5))
        q.closeSubpath()
    }
    private static let heart = Path { q in
        q.move(to: CGPoint(x: 0, y: 5))
        q.addCurve(to: CGPoint(x: -3, y: -8), control1: CGPoint(x: -8, y: -1), control2: CGPoint(x: -8, y: -8))
        q.addCurve(to: CGPoint(x: 0, y: -6), control1: CGPoint(x: -1, y: -8), control2: CGPoint(x: 0, y: -6))
        q.addCurve(to: CGPoint(x: 3, y: -8), control1: CGPoint(x: 0, y: -6), control2: CGPoint(x: 1, y: -8))
        q.addCurve(to: CGPoint(x: 0, y: 5), control1: CGPoint(x: 8, y: -8), control2: CGPoint(x: 8, y: -1))
        q.closeSubpath()
    }

    /// The dewdrop, from (0, -9) down to a round bottom of radius 6 centred at (0, 3).
    private static let teardrop = Path { q in
        q.move(to: CGPoint(x: 0, y: -9))
        q.addCurve(to: CGPoint(x: 6, y: 3), control1: CGPoint(x: 4, y: -3), control2: CGPoint(x: 6, y: 0))
        q.addArc(center: CGPoint(x: 0, y: 3), radius: 6, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        q.addCurve(to: CGPoint(x: 0, y: -9), control1: CGPoint(x: -6, y: 0), control2: CGPoint(x: -4, y: -3))
        q.closeSubpath()
    }

    static func color(_ hex: UInt32) -> Color { Color(UIColor(hex: hex)) }
    static func toEarnFill(dark: Bool) -> Color { color(dark ? 0x3A4C3A : 0xE4DFD2) }
    static func toEarnInk(dark: Bool) -> Color { color(dark ? 0x8FA48F : 0x746F5E) }

    static func path(_ shape: PotMark.Shape) -> Path {
        switch shape {
        case let .rect(x, y, w, h):
            return Path(CGRect(x: x, y: y, width: w, height: h))
        case let .capsule(x, y, w, h):
            return Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: w / 2)
        case let .circle(cx, cy, r):
            return Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
        case let .petal(cx, cy, d, rx, ry, deg):
            let t = CGAffineTransform(translationX: cx, y: cy).rotated(by: deg * .pi / 180)
            return Path(ellipseIn: CGRect(x: -rx, y: -d - ry, width: 2 * rx, height: 2 * ry)).applying(t)
        case let .sparkle(cx, cy, s):
            return sparkle.applying(CGAffineTransform(translationX: cx, y: cy).scaledBy(x: s, y: s))
        case let .heart(cx, cy, s):
            return heart.applying(CGAffineTransform(translationX: cx, y: cy).scaledBy(x: s, y: s))
        case let .triangle(x1, y1, x2, y2, x3, y3):
            return Path { q in
                q.move(to: CGPoint(x: x1, y: y1)); q.addLine(to: CGPoint(x: x2, y: y2)); q.addLine(to: CGPoint(x: x3, y: y3)); q.closeSubpath()
            }
        case let .teardrop(cx, cy, s):
            return teardrop.applying(CGAffineTransform(translationX: cx, y: cy).scaledBy(x: s, y: s))
        case let .crescent(cx, cy, r, ox, oy, or):
            return Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
                .subtracting(Path(ellipseIn: CGRect(x: ox - or, y: oy - or, width: 2 * or, height: 2 * or)))
        }
    }

    /// Draws `pot` in pot box units on `g` (already placed and scaled). `soil` adds the soil top; `rise` (0...1) grows
    /// the repot mound on it.
    static func draw(_ g: GraphicsContext, pot: Pot, style: Style = .full, dark: Bool = false, soil: Bool = false, rise: Double = 0) {
        let ghost = style == .toEarn
        let ink = toEarnInk(dark: dark)
        let dash = StrokeStyle(lineWidth: 2, lineJoin: .round, dash: [5, 4])
        g.fill(bodyPath, with: .color(ghost ? toEarnFill(dark: dark) : color(pot.body)))

        var inside = g
        inside.clip(to: bodyPath)
        if !ghost {
            inside.fill(lightStrip, with: .color(.white.opacity(0.14)))
            inside.fill(shadeStrip, with: .color(color(pot.shade).opacity(0.45)))
        }
        let marks = PotCatalog.marks(for: pot.decoration.kind)
        if !marks.isEmpty {
            if ghost { inside.opacity = 0.55 }
            inside.drawLayer { layer in
                for m in marks where !(ghost && m.ghost == .hidden) {
                    var l = layer
                    l.opacity = m.opacity
                    let c = ghost ? (m.ghost == .fill ? toEarnFill(dark: dark) : ink)
                        : color(pot.decoration.colors.indices.contains(m.color) ? pot.decoration.colors[m.color] : pot.rim)
                    l.fill(path(m.shape), with: .color(c))
                }
            }
        }
        if ghost { g.stroke(bodyPath, with: .color(ink), style: dash) }

        let rim = Path(roundedRect: rimRect, cornerRadius: 9)
        g.fill(rim, with: .color(ghost ? toEarnFill(dark: dark) : color(pot.rim)))
        if ghost {
            g.stroke(rim, with: .color(ink), style: dash)
        } else {
            g.fill(Path(roundedRect: CGRect(x: 16, y: 8, width: 88, height: 5), cornerRadius: 2.5), with: .color(.white.opacity(0.35)))
        }

        guard soil else { return }
        let top = Path(ellipseIn: soilRect)
        g.fill(top, with: .color(color(0x85583A)))
        var s = g
        s.clip(to: top)
        s.fill(Path(ellipseIn: soilRect.offsetBy(dx: 0, dy: 2.6)), with: .color(color(0x6B4528)))
        if rise > 0 {
            var m = g
            m.translateBy(x: 60, y: 12); m.scaleBy(x: 0.4 + 0.6 * rise, y: 0.1 + 0.9 * rise)
            m.fill(Path(roundedRect: CGRect(x: -26, y: -10, width: 52, height: 12), cornerSize: CGSize(width: 22, height: 8)), with: .color(color(0x7A5238)))
        }
    }
}

/// A pot at `width` points (height is 100/120 of it), for tiles, cards and the plant page stage.
struct PotArtView: View {
    let pot: Pot
    var style: PotPainter.Style = .full
    var width: CGFloat
    var soil = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { ctx, size in
            var g = ctx
            g.scaleBy(x: size.width / 120, y: size.width / 120)
            PotPainter.draw(g, pot: pot, style: style, dark: scheme == .dark, soil: soil)
        }
        .frame(width: width, height: width * 100 / 120)
        .accessibilityHidden(true)
    }
}

#Preview("Pots") {
    VStack(spacing: 16) {
        ForEach([PotPainter.Style.full, .toEarn], id: \.self) { style in
            HStack(spacing: 6) { ForEach(PotCatalog.all) { PotArtView(pot: $0, style: style, width: 34) } }
        }
        HStack { ForEach(PotCatalog.all.prefix(4)) { PotArtView(pot: $0, width: 88, soil: true) } }
    }
    .padding()
}

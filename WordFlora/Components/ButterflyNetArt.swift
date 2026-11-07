import SwiftUI

/// The butterfly net and the Gentle Net pieces, drawn in SwiftUI so the hoop is exactly the catch radius at every tier
/// and size (docs/pm/butterfly-net-spec.md section 7, with the visual review's fixes; Gentle Net art from
/// design-preview/badge-mechanics: resting-halo.svg, gentle-hello-heart.svg, gentle-hello-pill.svg). All decorative:
/// the net is hidden from VoiceOver, which says hello through each visitor instead.
enum ButterflyNetPalette {
    struct Tier { var rim: Color; var mesh: Color; var grip: Color? }
    /// Wood, silver, gold, from the Shed icons `tool_net_t1..t3`. Silver's rim is the darker `#8D9AA6`, so it shows on
    /// the pale sky (the lighter `#C5CED6` was about 1.4:1).
    static func tier(_ t: Int) -> Tier {
        switch min(3, max(1, t)) {
        case 1: return Tier(rim: Color(hex: 0xC98A4B), mesh: Color(hex: 0x9A5F2A), grip: nil)
        case 2: return Tier(rim: Color(hex: 0x8D9AA6), mesh: Color(hex: 0x8D9AA6), grip: Color(hex: 0x8D9AA6))
        default: return Tier(rim: Color(hex: 0xF5C84C), mesh: Color(hex: 0xD49A1E), grip: Color(hex: 0xD49A1E))
        }
    }
    static let handle = Color(hex: 0xB07A4B)
    static let sparkle = Color(hex: 0xF2B705)
    static let hoopFill = Color(hex: 0xEAF6F3)
    /// Ink outline on the rim and handle in the day sky (all tiers), like the app's stickers.
    static let ink = Color(hex: 0x3B3B3B)
    /// In the evening sky the outline is cream instead, so the rim and handle show on the night and the green bed.
    static let eveningOutline = Color(hex: 0xFAF7F0)
    static let heart = Color(hex: 0xE25B7B)
    static let rose = Color(hex: 0xF2788A), roseStroke = Color(hex: 0xD9566C), roseWash = Color(hex: 0xFFF1F3)
    static let pillText = Color(hex: 0x2C3E2C)
    static let haloFill = Color(hex: 0xF5C858), haloLine = Color(hex: 0xE8A838)

    static let rimWidth: CGFloat = 5
    static let outlineWidth: CGFloat = 1
    static let meshWidth: CGFloat = 1.25
    static let meshOpacity = 0.7
    static let meshPitch: CGFloat = 9
    static let handleWidth: CGFloat = 7
    static let fillOpacity = 0.22
}

/// Draws the net over the whole scene (pass the scene's size). `center` is the hoop centre, `radius` the catch radius in
/// points. `pocket` scales the mesh a little while a visitor sits in it.
struct ButterflyNetCanvas: View {
    var center: CGPoint
    var radius: CGFloat
    var tier: Int
    var evening: Bool
    var handleRight: Bool
    var handleScale: CGFloat = 1.1
    var pocket = false

    var body: some View {
        Canvas { ctx, _ in Self.draw(in: &ctx, center: center, radius: radius, tier: tier, evening: evening,
                                     handleRight: handleRight, handleScale: handleScale, pocket: pocket) }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    static func draw(in ctx: inout GraphicsContext, center c: CGPoint, radius r: CGFloat, tier: Int, evening: Bool,
                     handleRight: Bool, handleScale: CGFloat, pocket: Bool) {
        let P = ButterflyNetPalette.self, look = P.tier(tier)
        let outline = evening ? P.eveningOutline.opacity(0.8) : P.ink.opacity(0.7)
        let hoop = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))

        // Handle: from the rim toward the nearer bottom corner, 45 degrees down.
        let dir = CGVector(dx: handleRight ? 0.7071 : -0.7071, dy: 0.7071)
        let start = CGPoint(x: c.x + dir.dx * r, y: c.y + dir.dy * r)
        let len = r * handleScale
        let end = CGPoint(x: start.x + dir.dx * len, y: start.y + dir.dy * len)
        var handle = Path(); handle.move(to: start); handle.addLine(to: end)
        ctx.stroke(handle, with: .color(outline), style: StrokeStyle(lineWidth: P.handleWidth + 2 * P.outlineWidth, lineCap: .round))
        ctx.stroke(handle, with: .color(P.handle), style: StrokeStyle(lineWidth: P.handleWidth, lineCap: .round))
        if let grip = look.grip {
            let g0 = CGPoint(x: start.x + dir.dx * len * 0.62, y: start.y + dir.dy * len * 0.62)
            var band = Path(); band.move(to: g0); band.addLine(to: end)
            ctx.stroke(band, with: .color(grip), style: StrokeStyle(lineWidth: P.handleWidth, lineCap: .round))
        }

        // Hoop: a pale wash, then the mesh (two line sets at +35 and -55 degrees) clipped to the hoop.
        ctx.fill(hoop, with: .color(P.hoopFill.opacity(P.fillOpacity)))
        var mesh = ctx
        mesh.clip(to: hoop)
        if pocket {
            mesh.translateBy(x: c.x, y: c.y); mesh.scaleBy(x: 1.12, y: 1.12); mesh.translateBy(x: -c.x, y: -c.y)
        }
        for angle in [35.0, -55.0] {
            var lines = Path()
            let a = angle * .pi / 180, ux = CGFloat(cos(a)), uy = CGFloat(sin(a))
            let nx = -uy, ny = ux
            var off = -r * 1.2
            while off <= r * 1.2 {
                let o = CGPoint(x: c.x + nx * off, y: c.y + ny * off)
                lines.move(to: CGPoint(x: o.x - ux * r * 1.3, y: o.y - uy * r * 1.3))
                lines.addLine(to: CGPoint(x: o.x + ux * r * 1.3, y: o.y + uy * r * 1.3))
                off += P.meshPitch
            }
            mesh.stroke(lines, with: .color(look.mesh.opacity(P.meshOpacity)), lineWidth: P.meshWidth)
        }

        // Rim: 5 pt in the tier colour over a 1 pt outline on each side (ink by day, cream in the evening).
        ctx.stroke(hoop, with: .color(outline), lineWidth: P.rimWidth + 2 * P.outlineWidth)
        ctx.stroke(hoop, with: .color(look.rim), lineWidth: P.rimWidth)

        if tier >= 3 {
            let s = CGPoint(x: c.x + r * 0.7071, y: c.y - r * 0.7071), k: CGFloat = 5
            var star = Path()
            star.move(to: CGPoint(x: s.x, y: s.y - k)); star.addLine(to: CGPoint(x: s.x + k * 0.3, y: s.y - k * 0.3))
            star.addLine(to: CGPoint(x: s.x + k, y: s.y)); star.addLine(to: CGPoint(x: s.x + k * 0.3, y: s.y + k * 0.3))
            star.addLine(to: CGPoint(x: s.x, y: s.y + k)); star.addLine(to: CGPoint(x: s.x - k * 0.3, y: s.y + k * 0.3))
            star.addLine(to: CGPoint(x: s.x - k, y: s.y)); star.addLine(to: CGPoint(x: s.x - k * 0.3, y: s.y - k * 0.3))
            star.closeSubpath()
            ctx.fill(star, with: .color(P.sparkle))
        }
    }
}

/// The soft gold halo under a resting visitor (resting-halo.svg, 120 x 60 at a 90 pt visitor).
struct RestingHalo: View {
    var breathing: Bool
    @State private var soft = false

    var body: some View {
        ZStack {
            Ellipse().fill(ButterflyNetPalette.haloFill.opacity(0.22)).frame(width: 108, height: 44)
            Ellipse().stroke(ButterflyNetPalette.haloLine.opacity(0.7), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [2, 6]))
                .frame(width: 88, height: 32)
        }
        .scaleEffect(64.0 / 90.0)
        .opacity(soft ? 0.85 : 1)
        .onAppear {
            guard breathing else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { soft = true }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The Gentle Net heart (gentle-hello-heart.svg, 48 x 48 box).
struct GentleHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let k = min(rect.width, rect.height) / 48
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * k, y: rect.minY + y * k) }
        var path = Path()
        path.move(to: p(24, 41))
        path.addCurve(to: p(5, 16.5), control1: p(10, 31), control2: p(5, 24))
        path.addCurve(to: p(15.2, 6), control1: p(5, 10.5), control2: p(9.6, 6))
        path.addCurve(to: p(24, 11.4), control1: p(19, 6), control2: p(22, 8.2))
        path.addCurve(to: p(32.8, 6), control1: p(26, 8.2), control2: p(29, 6))
        path.addCurve(to: p(43, 16.5), control1: p(38.4, 6), control2: p(43, 10.5))
        path.addCurve(to: p(24, 41), control1: p(43, 24), control2: p(38, 31))
        path.closeSubpath()
        return path
    }
}

/// The heart drawn the way the art has it: rose fill, a darker rose line and one white glint.
struct GentleHeart: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            GentleHeartShape().fill(ButterflyNetPalette.rose)
            GentleHeartShape().stroke(ButterflyNetPalette.roseStroke, style: StrokeStyle(lineWidth: 2.4 * size / 48, lineJoin: .round))
            Ellipse().fill(Color.white.opacity(0.75)).frame(width: 8.4 * size / 48, height: 5.6 * size / 48)
                .rotationEffect(.degrees(-30)).offset(x: (14.5 - 24) * size / 48, y: (15 - 24) * size / 48)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// "Gentle hello!" on a pale rose pill, with a small heart that has a white line so it reads on the pill.
struct GentleHelloPill: View {
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Image(systemName: "heart.fill").font(.system(size: 18)).foregroundStyle(.white)
                Image(systemName: "heart.fill").font(.system(size: 16)).foregroundStyle(ButterflyNetPalette.heart)
            }
            Text(GentleNetCopy.pill).font(Theme.font(.headline, weight: .semibold)).foregroundStyle(ButterflyNetPalette.pillText)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(ButterflyNetPalette.roseWash, in: Capsule())
        .overlay(Capsule().stroke(ButterflyNetPalette.rose, lineWidth: 2))
    }
}

/// The "Quick wings" chip on the Visitors page: dark green on pale green (better than 4.5:1 in light and dark).
struct QuickWingsChip: View {
    private static let text = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xC4E6C8) : UIColor(hex: 0x2F6B3A) })
    private static let fill = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x203A26) : UIColor(hex: 0xE3F1E3) })

    var body: some View {
        Label(VisitorsCopy.quickWings, systemImage: "wind")
            .font(Theme.font(.caption, weight: .bold)).foregroundStyle(Self.text)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Self.fill, in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("visitors.quickWings")
    }
}

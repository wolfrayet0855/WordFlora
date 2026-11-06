import SwiftUI

/// The "standing tall again" picture after a weather puzzle (mockup endgame `mended`): a soft rainbow over a green hill,
/// a few twinkling sparkles and slow petals. Put plants on the hill with `content`. Dark mode gets a dawn sky.
/// Reduce Motion (`still`): no petals, sparkles hold still. Decorative unless `labelled`.
enum ReliefArtCopy {
    static let label = "A rainbow over your garden, standing tall again."
}

struct ReliefArt<Content: View>: View {
    var still = false
    var paused = false
    var labelled = false
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .bottom) {
                LinearGradient(colors: dark ? [Color(hex: 0x3A5873), Color(hex: 0x5A4A5E)] : [Color(hex: 0xDFEDF8), Color(hex: 0xF6E6E4)],
                               startPoint: .top, endPoint: .bottom)
                rainbow(w: w, h: h, dark: dark)
                Ellipse().fill(Color(hex: dark ? 0x305133 : 0xBFDAAF))
                    .frame(width: w * 1.3, height: h * 0.42).offset(y: h * 0.16)
                content().frame(width: w).padding(.bottom, h * 0.14)
                sparkles(w: w, h: h, dark: dark)
            }
            .frame(width: w, height: h)
        }
        .clipped()
        .allowsHitTesting(false)
        .artLabel(labelled ? ReliefArtCopy.label : nil)
    }

    private func rainbow(w: CGFloat, h: CGFloat, dark: Bool) -> some View {
        let bands: [UInt32] = [0xF2A0B0, 0xF6C98A, 0xF6E08A, 0xB5DB9A, 0x9CC8EE, 0xC4B0E8]
        return Canvas { ctx, _ in
            for (i, band) in bands.enumerated() {
                var arc = Path()
                arc.addArc(center: CGPoint(x: w / 2, y: h * 0.72), radius: w * (0.56 - 0.0225 * Double(i)),
                           startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                ctx.stroke(arc, with: .color(Color(hex: band).opacity(dark ? 0.55 : 0.7)), lineWidth: w * 0.022)
            }
        }
        .blur(radius: 1.5)
        .frame(width: w, height: h)
    }

    private func sparkles(w: CGFloat, h: CGFloat, dark: Bool) -> some View {
        let spots: [(Double, Double, Double)] = [(0.19, 0.16, 1), (0.74, 0.12, 0.8), (0.83, 0.24, 0.9), (0.12, 0.42, 0.7), (0.9, 0.5, 0.8), (0.28, 0.4, 0.6)]
        return TimelineView(.animation(minimumInterval: 1.0 / 20, paused: still || paused)) { tl in
            Canvas { ctx, _ in
                let t = tl.date.timeIntervalSinceReferenceDate
                let gold = Color(hex: dark ? 0xF0C060 : 0xE8A838)
                for (i, s) in spots.enumerated() {
                    let a = still ? 1 : 0.55 + 0.45 * sin(t * 1.3 + Double(i) * 1.9)
                    WeatherDraw.sparkle(ctx, x: s.0 * w, y: s.1 * h, s: s.2, arms: 2, color: gold, alpha: a, width: 2.6)
                }
                guard !still else { return }
                for i in 0..<4 {           // slow petals, at most four
                    let y = WeatherDraw.loop(t, speed: h / 9, span: h * 0.8, phase: Double(i) / 4)
                    let x = w * (0.15 + 0.22 * Double(i)) + sin(t * 0.8 + Double(i)) * 14
                    var c = ctx
                    c.translateBy(x: x, y: y); c.rotate(by: .degrees(t * 40 + Double(i) * 70))
                    c.fill(Path(ellipseIn: CGRect(x: -5, y: -3.5, width: 10, height: 7)), with: .color(Color(hex: i % 2 == 0 ? 0xF2A0B0 : 0xE8A838).opacity(0.85)))
                }
            }
        }
    }
}

#Preview("Relief") {
    ReliefArt { WeatherPreviewPlant(imageName: "plant_sunflower", size: 160) }.frame(height: 360)
}

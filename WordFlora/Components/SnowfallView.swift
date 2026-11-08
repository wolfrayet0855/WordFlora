import SwiftUI

/// Frost & Lantern's gentle falling snow, built like `RainCanvas`: one `Canvas` under a 30 fps `TimelineView`, no state,
/// so pausing freezes it. Far and mid flakes are soft dots (one fill per layer); the near flakes are tiny six-arm
/// snowflakes (one stroke). `still` (Reduce Motion, the app's switch, Low Power Mode) draws one calm frame and runs no
/// timeline. Decorative only: hidden from VoiceOver, never takes taps.
struct SnowfallView: View {
    /// Already halved for Calm by the caller (`Snowfall.count`).
    var count: Int
    var calm = false
    var still = false
    var paused = false
    /// Plant page: flakes fade out over the last 24 pt above the ground.
    var groundY: CGFloat? = nil
    /// Plant page: [0] behind the plant, [1, 2] in front.
    var layers: [Int] = [0, 1, 2]

    @Environment(\.colorScheme) private var colorScheme

    /// Frost blue-grey on the light grounds (white is invisible there), snow white in dark mode.
    static func flakeColor(dark: Bool) -> Color { dark ? Color(hex: 0xF4F8FC) : Color(hex: 0x8FA9C4) }

    var body: some View {
        Group {
            if still {
                Canvas { ctx, size in draw(ctx, size, time: WeatherArt.stillTime) }
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused)) { tl in
                    Canvas { ctx, size in draw(ctx, size, time: tl.date.timeIntervalSinceReferenceDate) }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, time: Double) {
        let color = Self.flakeColor(dark: colorScheme == .dark)
        let flakes = Snowfall.flakes(count: count, size: size, time: time, calm: calm, layers: layers,
                                     groundY: groundY.map { Double($0) })
        for L in layers where L >= 0 && L < Snowfall.layers.count {
            let layer = Snowfall.layers[L]
            // One path per layer; only flakes fading near the ground get their own draw call.
            var batch = Path()
            func paint(_ path: Path, _ alpha: Double) {
                let shading = GraphicsContext.Shading.color(color.opacity(alpha))
                if layer.glyph {
                    ctx.stroke(path, with: shading, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                } else {
                    ctx.fill(path, with: shading)
                }
            }
            for f in flakes where f.layer == L {
                let shape = layer.glyph ? Self.glyph(x: f.x, y: f.y, r: f.radius, spin: f.spin)
                    : Path(ellipseIn: CGRect(x: f.x - f.radius, y: f.y - f.radius, width: 2 * f.radius, height: 2 * f.radius))
                if f.alpha < layer.alpha { paint(shape, f.alpha) } else { batch.addPath(shape) }
            }
            if !batch.isEmpty { paint(batch, layer.alpha) }
        }
    }

    /// A six-arm snowflake of radius `r`: each arm carries one small V of twigs, so it stays a flake, not an asterisk.
    static func glyph(x: Double, y: Double, r: Double, spin: Double) -> Path {
        var p = Path()
        for k in 0..<6 {
            let a = spin + Double(k) * .pi / 3
            let tip = CGPoint(x: x + r * cos(a), y: y + r * sin(a))
            p.move(to: CGPoint(x: x, y: y)); p.addLine(to: tip)
            let bx = x + r * 0.55 * cos(a), by = y + r * 0.55 * sin(a), t = r * 0.38
            for side in [-1.0, 1.0] {
                let b = a + side * .pi / 4
                p.move(to: CGPoint(x: bx, y: by)); p.addLine(to: CGPoint(x: bx + t * cos(b), y: by + t * sin(b)))
            }
        }
        return p
    }
}

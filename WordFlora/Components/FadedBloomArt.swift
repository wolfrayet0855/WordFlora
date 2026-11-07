import SwiftUI

/// Pruning Pro art (design-preview/badge-mechanics: faded-bloom.svg, faded-petal.svg, fresh-bud.svg), drawn in SwiftUI
/// from the SVG coordinates. Flat fills with a darker stroke of the same hue, round joins. Decorative: the plant's own
/// VoiceOver label says "ready for a trim".
enum FadedBloomPalette {
    static let petal = Color(hex: 0xD4B08A), petalMid = Color(hex: 0xCBA47C), petalLow = Color(hex: 0xC79E74)
    static let stroke = Color(hex: 0xA9825A), neck = Color(hex: 0x8E9A5A)
    static let centre = Color(hex: 0xB08A3E), centreDot = Color(hex: 0x8A6A2E)
    static let bud = Color(hex: 0xF2788A), budStroke = Color(hex: 0xD9566C)
    static let leafLight = Color(hex: 0x5FA860), leafDark = Color(hex: 0x3F8A4A), stem = Color(hex: 0x4E9A55)
}

/// The faded bloom (100 x 100 box; the bloom centre is at 50, 40). Tan petals, a drooping neck.
struct FadedBloomView: View {
    /// Where the bloom centre sits in the 100 x 100 box, for placing it over a plant.
    static let anchor = UnitPoint(x: 0.5, y: 0.4)

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 100
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            var neck = Path(); neck.move(to: p(50, 96)); neck.addCurve(to: p(56, 52), control1: p(50, 76), control2: p(52, 62))
            ctx.stroke(neck, with: .color(FadedBloomPalette.neck), style: StrokeStyle(lineWidth: 4.5 * k, lineCap: .round))
            var g = ctx
            g.translateBy(x: 50 * k, y: 40 * k); g.rotate(by: .degrees(28)); g.translateBy(x: -50 * k, y: -40 * k)
            let petals: [([CGFloat], Color)] = [
                ([36, 34, 28, 42, 30, 52, 40, 54, 48, 48], FadedBloomPalette.petal),
                ([64, 34, 72, 42, 70, 52, 60, 54, 52, 48], FadedBloomPalette.petal),
                ([44, 26, 50, 16, 56, 20, 60, 26, 56, 36], FadedBloomPalette.petalMid),
                ([40, 46, 38, 60, 46, 64, 52, 60, 52, 48], FadedBloomPalette.petalLow),
                ([56, 50, 64, 58, 60, 66, 52, 64, 50, 50], FadedBloomPalette.petalMid),
            ]
            let line = StrokeStyle(lineWidth: 2 * k, lineCap: .round, lineJoin: .round)
            for (c, fill) in petals {
                var path = Path()
                path.move(to: p(50, 40))
                path.addCurve(to: p(c[4], c[5]), control1: p(c[0], c[1]), control2: p(c[2], c[3]))
                path.addCurve(to: p(50, 40), control1: p(c[6], c[7]), control2: p(c[8], c[9]))
                path.closeSubpath()
                g.fill(path, with: .color(fill)); g.stroke(path, with: .color(FadedBloomPalette.stroke), style: line)
            }
            let centre = Path(ellipseIn: CGRect(x: 43.5 * k, y: 33.5 * k, width: 13 * k, height: 13 * k))
            g.fill(centre, with: .color(FadedBloomPalette.centre))
            g.stroke(centre, with: .color(FadedBloomPalette.centreDot), lineWidth: 1.8 * k)
            g.fill(Path(ellipseIn: CGRect(x: 46.6 * k, y: 37.1 * k, width: 2.8 * k, height: 2.8 * k)), with: .color(FadedBloomPalette.centreDot))
            g.fill(Path(ellipseIn: CGRect(x: 51.3 * k, y: 39.8 * k, width: 2.4 * k, height: 2.4 * k)), with: .color(FadedBloomPalette.centreDot))
        }
        .accessibilityHidden(true)
    }
}

/// One dry petal (40 x 40 box) that drifts down after the snip.
struct FadedPetalView: View {
    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 40
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            ctx.translateBy(x: 20 * k, y: 20 * k); ctx.rotate(by: .degrees(-24)); ctx.translateBy(x: -20 * k, y: -20 * k)
            var petal = Path(); petal.move(to: p(20, 4))
            petal.addCurve(to: p(20, 36), control1: p(30, 10), control2: p(32, 24))
            petal.addCurve(to: p(20, 4), control1: p(8, 24), control2: p(10, 10))
            ctx.fill(petal, with: .color(FadedBloomPalette.petal))
            ctx.stroke(petal, with: .color(FadedBloomPalette.stroke), style: StrokeStyle(lineWidth: 2 * k, lineJoin: .round))
            var vein = Path(); vein.move(to: p(20, 9)); vein.addQuadCurve(to: p(19, 31), control: p(21, 20))
            ctx.stroke(vein, with: .color(FadedBloomPalette.stroke), style: StrokeStyle(lineWidth: 1.2 * k, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

/// The fresh bud (60 x 60 box) where the faded bloom was, on later visits after a tidy trim.
struct FreshBudView: View {
    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 60
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            var stem = Path(); stem.move(to: p(30, 58)); stem.addLine(to: p(30, 34))
            ctx.stroke(stem, with: .color(FadedBloomPalette.stem), style: StrokeStyle(lineWidth: 3.6 * k, lineCap: .round))
            var bud = Path(); bud.move(to: p(30, 12))
            bud.addCurve(to: p(30, 36), control1: p(40, 18), control2: p(40, 30))
            bud.addCurve(to: p(30, 12), control1: p(20, 30), control2: p(20, 18))
            ctx.fill(bud, with: .color(FadedBloomPalette.bud))
            ctx.stroke(bud, with: .color(FadedBloomPalette.budStroke), style: StrokeStyle(lineWidth: 2 * k, lineJoin: .round))
            var sepals = Path()
            sepals.move(to: p(30, 36)); sepals.addCurve(to: p(19, 26), control1: p(22, 36), control2: p(18, 30))
            sepals.addCurve(to: p(30, 36), control1: p(24, 28), control2: p(28, 32))
            sepals.move(to: p(30, 36)); sepals.addCurve(to: p(41, 26), control1: p(38, 36), control2: p(42, 30))
            sepals.addCurve(to: p(30, 36), control1: p(36, 28), control2: p(32, 32))
            ctx.fill(sepals, with: .color(FadedBloomPalette.leafLight))
            ctx.stroke(sepals, with: .color(FadedBloomPalette.leafDark), style: StrokeStyle(lineWidth: 1.6 * k, lineJoin: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: 25 * k, y: 17 * k, width: 4 * k, height: 8 * k)), with: .color(.white.opacity(0.55)))
        }
        .accessibilityHidden(true)
    }
}

/// The cue over the plant art: the faded bloom at its seeded spot while it shows; after the snip it cross-fades away
/// while one dry petal falls (no petal under Reduce Motion, half speed in Calm). The fresh bud on later visits.
struct FadedBloomOverlay: View {
    let size: CGFloat
    let spot: (x: Double, y: Double)
    let showsBloom: Bool
    let showsBud: Bool
    /// Bumped on a tidy trim: the petal falls once.
    let snips: Int
    let reduceMotion: Bool
    let calm: Bool

    @State private var falling = false
    @State private var fall = 0.0          // 0 at the bloom, 1 at the end of the drop

    var body: some View {
        let bloom = size * 0.28
        let at = CGPoint(x: spot.x * size, y: spot.y * size)
        ZStack(alignment: .topLeading) {
            FadedBloomView().frame(width: bloom, height: bloom)
                .offset(x: at.x - bloom * FadedBloomView.anchor.x, y: at.y - bloom * FadedBloomView.anchor.y)
                .opacity(showsBloom ? 1 : 0)
                .animation(.easeInOut(duration: reduceMotion ? 0.3 : 0.25), value: showsBloom)
                .accessibilityIdentifier("plant.fadedBloom")
            if showsBud && !showsBloom {
                FreshBudView().frame(width: size * 0.2, height: size * 0.2)
                    .offset(x: at.x - size * 0.1, y: at.y - size * 0.07)
                    .accessibilityIdentifier("plant.freshBud")
            }
            if !reduceMotion && falling {
                // Falls 120 pt with a small sway and a 70 degree turn, fading over the last part of the drop.
                FadedPetalView().frame(width: size * 0.12, height: size * 0.12)
                    .rotationEffect(.degrees(70 * fall))
                    .offset(x: at.x - size * 0.06 + CGFloat(14 * sin(fall * .pi)), y: at.y + CGFloat(120 * fall))
                    .opacity(fall < 0.8 ? 1 : max(0, (1 - fall) / 0.2))
            }
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: snips) { _, _ in
            guard !reduceMotion else { return }
            let d = calm ? 1.8 : 0.9
            fall = 0; falling = true
            DispatchQueue.main.async { withAnimation(.easeIn(duration: d)) { fall = 1 } }
            DispatchQueue.main.asyncAfter(deadline: .now() + d + 0.05) { falling = false; fall = 0 }
        }
    }
}

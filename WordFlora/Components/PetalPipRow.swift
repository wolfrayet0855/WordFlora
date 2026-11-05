import SwiftUI

/// One FlowerView petal (design-preview/tending/parts/flower.svg), filling its frame. Used for the love pips.
struct PipPetalShape: Shape {
    func path(in r: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + (x - 78) / 44 * r.width, y: r.minY + (y - 16) / 62 * r.height) }
        var p = Path()
        p.move(to: pt(100, 74))
        p.addCurve(to: pt(100, 20), control1: pt(81, 62), control2: pt(83, 30))
        p.addCurve(to: pt(100, 74), control1: pt(117, 30), control2: pt(119, 62))
        p.closeSubpath()
        return p
    }
}

/// The small pink five-petal flower with a gold centre that starts every pip row, so the row reads as "love".
struct LoveFlower: View {
    var size: CGFloat
    var body: some View {
        Canvas { ctx, s in
            let k = s.width / 140
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: (x - 30) * k, y: (y - 18) * k) }
            var petal = Path()
            petal.move(to: pt(100, 74))
            petal.addCurve(to: pt(100, 20), control1: pt(81, 62), control2: pt(83, 30))
            petal.addCurve(to: pt(100, 74), control1: pt(117, 30), control2: pt(119, 62))
            petal.closeSubpath()
            let c = pt(100, 88)
            for i in 0..<5 {
                let t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: CGFloat(i) * 72 * .pi / 180).translatedBy(x: -c.x, y: -c.y)
                let p = petal.applying(t)
                ctx.fill(p, with: .color(LifePalette.petal))
                ctx.stroke(p, with: .color(LifePalette.petalEdge), style: StrokeStyle(lineWidth: 7 * k, lineJoin: .round))
            }
            let disc = Path(ellipseIn: CGRect(x: c.x - 18 * k, y: c.y - 18 * k, width: 36 * k, height: 36 * k))
            ctx.fill(disc, with: .color(LifePalette.gold))
            ctx.stroke(disc, with: .color(LifePalette.goldEdge), lineWidth: 5 * k)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A love flower and five pips, one per day of love. Filled pink = love; a dashed outline with a faint fill = gone for now.
/// When the count drops the pip fades with the falling petal; when it rises the pips come back one at a time, 0.3 s apart.
struct PetalPips: View {
    let count: Int
    var pipWidth: CGFloat = 13
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Int?

    var body: some View {
        let n = shown ?? count
        HStack(spacing: pipWidth * 0.3) {
            LoveFlower(size: pipWidth * 1.4).padding(.trailing, pipWidth * 0.2)
            ForEach(0..<5, id: \.self) { i in
                ZStack {
                    PipPetalShape().fill(LifePalette.ghost.opacity(0.16))
                    PipPetalShape().stroke(LifePalette.ghost, style: StrokeStyle(lineWidth: 1.4, lineJoin: .round, dash: [2.6, 2.1]))
                    PipPetalShape().fill(LifePalette.petal)
                        .overlay(PipPetalShape().stroke(LifePalette.petalEdge, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)))
                        .scaleEffect(i < n ? 1 : (reduceMotion ? 1 : 0.2), anchor: .bottom)
                        .opacity(i < n ? 1 : 0)
                }
                .frame(width: pipWidth, height: pipWidth * 18 / 13)
            }
        }
        .accessibilityHidden(true)
        .onAppear { shown = count }
        .onChange(of: count) { old, new in step(from: shown ?? old, to: new) }
    }

    private func step(from old: Int, to new: Int) {
        if new < old {
            withAnimation(.easeOut(duration: 0.6).delay(reduceMotion ? 0 : 0.7)) { shown = new }
        } else if new > old {
            for (k, v) in ((old + 1)...new).enumerated() {
                let anim: Animation = reduceMotion ? .easeIn(duration: 0.25) : .spring(response: 0.45, dampingFraction: 0.55)
                DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0 : 0.3 + Double(k) * 0.3)) {
                    withAnimation(anim) { shown = max(shown ?? 0, v) }
                }
            }
        }
    }
}

/// The glass pill under the plant. It never takes taps, so a tap anywhere on the plant reaches it.
struct PetalPipRow: View {
    let count: Int
    var large = false

    var body: some View {
        // Standard sizes: the caption under the pill names the row ("3 love petals", design-preview/fact-card), so the
        // pips never read as lives; it sits under the pill so the row stays clear of the open Life panel. At
        // accessibility sizes the Life sheet right below says it already, and the stage has no room for it.
        VStack(spacing: 4) {
            PetalPips(count: count, pipWidth: large ? 17 : 13)
                .padding(.vertical, large ? 7 : 5).padding(.leading, large ? 10 : 8).padding(.trailing, large ? 13 : 11)
                .background(LifePalette.glass, in: Capsule())
                .overlay(Capsule().stroke(LifePalette.line))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                .accessibilityHidden(true)
            if !large {
                Text(LifeStats.pipCaption(pips: count))
                    .font(Theme.font(.footnote, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("love-petal-caption")
            }
        }
        .allowsHitTesting(false)
    }
}

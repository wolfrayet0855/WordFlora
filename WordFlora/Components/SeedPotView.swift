import SwiftUI

/// A plant resting as a seed in its pot (design-preview/tending/parts/seed-pot.svg): the seed breathes slowly
/// and two small z's float. The pot is the plant's own (PotCatalog), drawn in the seed art's 140 point box with
/// its rim at y 64, so the seed sits on its soil. Reduce Motion keeps it still.
struct SeedPotView: View {
    var pot: Pot = PotCatalog.plainBlue
    var width: CGFloat = 170
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var breathe = false

    /// The 120 x 100 pot box sits at (10, 60) in the seed art's 140 point wide box, at the same scale.
    static let potOrigin = CGPoint(x: 10, y: 60)
    static let boxHeight: CGFloat = 164

    var body: some View {
        let k = width / 140
        ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                var g = ctx
                g.scaleBy(x: k, y: k)
                g.fill(Path(ellipseIn: CGRect(x: 22, y: 150, width: 96, height: 12)),
                       with: .color(scheme == .dark ? .black.opacity(0.35) : Color(UIColor(hex: 0x2C3E2C)).opacity(0.16)))
                g.translateBy(x: Self.potOrigin.x, y: Self.potOrigin.y)
                PotPainter.draw(g, pot: pot, dark: scheme == .dark, soil: true)
            }
            Image("seed_pot_seed").resizable().frame(width: width, height: width * 150 / 140)
                .scaleEffect(x: breathe ? 1.04 : 1, y: breathe ? 1.06 : 1, anchor: UnitPoint(x: 0.5, y: 71.0 / 150))
            Text("z").font(.system(size: 16 * k, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                .position(x: 96 * k, y: 37 * k).offset(y: breathe ? -5 : 0).opacity(breathe ? 0.5 : 0.9)
            Text("z").font(.system(size: 12 * k, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                .position(x: 108 * k, y: 22 * k).offset(y: breathe ? 0 : -5).opacity(breathe ? 0.9 : 0.5)
        }
        .frame(width: width, height: width * Self.boxHeight / 140, alignment: .topLeading)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

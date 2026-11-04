import SwiftUI

/// A plant resting as a seed in its pot (design-preview/tending/parts/seed-pot.svg): the seed breathes slowly
/// and two small z's float. Reduce Motion keeps it still.
struct SeedPotView: View {
    var width: CGFloat = 170
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        let k = width / 140
        ZStack(alignment: .topLeading) {
            Image("seed_pot").resizable()
            Image("seed_pot_seed").resizable()
                .scaleEffect(x: breathe ? 1.04 : 1, y: breathe ? 1.06 : 1, anchor: UnitPoint(x: 0.5, y: 71.0 / 150))
            Text("z").font(.system(size: 16 * k, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                .position(x: 96 * k, y: 37 * k).offset(y: breathe ? -5 : 0).opacity(breathe ? 0.5 : 0.9)
            Text("z").font(.system(size: 12 * k, weight: .heavy, design: .rounded)).foregroundStyle(Color.appPrimaryText)
                .position(x: 108 * k, y: 22 * k).offset(y: breathe ? 0 : -5).opacity(breathe ? 0.9 : 0.5)
        }
        .frame(width: width, height: width * 150 / 140)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}

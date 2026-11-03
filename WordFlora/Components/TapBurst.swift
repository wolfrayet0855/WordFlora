import SwiftUI

/// Hearts and sparkles that float out from the centre when a plant is tapped. A pure overlay: it never changes layout
/// or intercepts taps, so the plant stays exactly where it is. With Reduce Motion the burst is a brief fade instead.
struct TapBurst: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Particle: Identifiable {
        let id = UUID(); let symbol: String; let dx: CGFloat; let dy: CGFloat; let size: CGFloat; let delay: Double
    }
    @State private var particles: [(burst: Int, p: Particle)] = []
    @State private var live: Set<UUID> = []

    var body: some View {
        ZStack {
            ForEach(particles, id: \.p.id) { entry in
                let p = entry.p
                Image(systemName: p.symbol)
                    .font(.system(size: p.size))
                    .foregroundStyle(p.symbol == "heart.fill" ? Color.pink : Color.yellow)
                    .offset(x: live.contains(p.id) ? p.dx : 0, y: live.contains(p.id) ? p.dy : 0)
                    .scaleEffect(live.contains(p.id) ? 1 : 0.4)
                    .opacity(live.contains(p.id) ? 0 : 1)
                    .animation(.easeOut(duration: reduceMotion ? 0.5 : 1.0).delay(p.delay), value: live.contains(p.id))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, n in burst(n) }
    }

    private func burst(_ n: Int) {
        let items: [Particle] = (0..<9).map { i in
            let angle = Double(i) / 9 * 2 * .pi + Double.random(in: -0.3...0.3)
            let dist = reduceMotion ? 0.0 : Double.random(in: 70...120)
            return Particle(symbol: i % 3 == 0 ? "sparkle" : "heart.fill", dx: CGFloat(cos(angle) * dist),
                            dy: CGFloat(sin(angle) * dist) - (reduceMotion ? 20 : 30),
                            size: CGFloat.random(in: 14...24), delay: Double(i) * 0.03)
        }
        particles.append(contentsOf: items.map { (n, $0) })
        DispatchQueue.main.async { for p in items { live.insert(p.id) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            let ids = Set(items.map(\.id))
            particles.removeAll { ids.contains($0.p.id) }; live.subtract(ids)
        }
    }
}

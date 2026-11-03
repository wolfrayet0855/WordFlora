import SwiftUI

/// Falling blossoms for celebrations (spec sections 9, 18). Deterministic per seed, capped at 120 particles,
/// tap to skip, and replaced by a quick fade when Reduce Motion is on.
struct FlowerRainView: View {
    var duration: Double = 2.4
    var particleCount: Int = 90
    var seed: UInt64 = 7
    var onFinish: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var finished = false

    private static let colors: [Color] = [Color(hex: 0xF2788A), Color(hex: 0xF5C858), Color(hex: 0xFFFFFF), Color(hex: 0xE9A36C), Color(hex: 0x8EA6C4)]

    private struct Particle { var x: Double; var delay: Double; var speed: Double; var size: Double; var sway: Double; var spin: Double; var color: Int }

    private var particles: [Particle] {
        var rng = SplitMix64(seed: seed)
        func r() -> Double { Double(rng.next() % 10_000) / 10_000 }
        return (0..<min(120, particleCount)).map { _ in
            Particle(x: r(), delay: r() * 0.9, speed: 0.55 + r() * 0.45, size: 8 + r() * 12, sway: 10 + r() * 26, spin: (r() - 0.5) * 6, color: Int(r() * Double(Self.colors.count)) % Self.colors.count)
        }
    }

    var body: some View {
        Group {
            if reduceMotion {
                Color.appAccent.opacity(0.0).overlay(Image(systemName: "sparkles").font(.system(size: 54)).foregroundStyle(Color.appAccent))
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { finish() } }
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSince(start)
                    Canvas { ctx, size in
                        for p in particles {
                            let local = (t - p.delay) / (duration * p.speed)
                            guard local > 0, local < 1 else { continue }
                            let x = p.x * size.width + sin(local * 7 + p.spin) * p.sway
                            let y = -20 + local * (size.height + 60)
                            var path = Path()
                            path.addEllipse(in: CGRect(x: -p.size / 2, y: -p.size, width: p.size, height: p.size * 1.7))
                            var c = ctx
                            c.translateBy(x: x, y: y)
                            c.rotate(by: .radians(local * p.spin * 2))
                            c.opacity = local > 0.85 ? (1 - local) / 0.15 : 1
                            c.fill(path, with: .color(Self.colors[p.color]))
                        }
                    }
                    .onChange(of: t > duration + 1.0) { _, done in if done { finish() } }
                }
            }
        }
        .allowsHitTesting(true)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { start = Date() }
        .accessibilityHidden(true)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}

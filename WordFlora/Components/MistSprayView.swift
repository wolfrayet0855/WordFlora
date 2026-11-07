import SwiftUI

/// Mist Maker's spray over the plant (docs/pm/badge-mechanics-art.md section 4, art in
/// design-preview/badge-mechanics/mist-puffs*.svg and dewy-drops.svg). PetalKit-style particles in the art's 160 x 100
/// frame: the nozzle at (8, 50) on the plant art's leading edge at 45 % of its height, the frame 0.65 of the art's
/// width. Each droplet travels from the nozzle to its place over 0.6 s (ease out, scale 0.3 to 1, a small seeded
/// jitter), the puffs swell 0.6 to 1, all fade 0.6 to 0.9 s; dew beads fade in at 0.5 s, stay 1.2 s, fade 0.4 s.
/// Calm: half the droplets and one puff. Reduce Motion: no particles, the dew cross-fades in over 0.25 s, stays 1.2 s
/// and fades over 0.4 s. Decorative: hidden from VoiceOver (the result line is announced instead). Taps pass through.
struct MistSprayView: View {
    /// Changes on every mist; a new value plays the spray once.
    let trigger: Int
    let size: CGFloat
    var calm = false
    var reduceMotion = false

    @State private var start: Date?

    static let duration = 2.1          // 0.5 s + 1.2 s + 0.4 s of dew
    static let reduceMotionDuration = 1.85
    static let identifier = "tend-anim-mist"

    /// The 24 droplets of mist-puffs.svg (x, y, r; the first 12 filled, the rest white with a rim).
    static let droplets: [(Double, Double, Double)] = [
        (22, 48, 2.4), (34, 44, 2.8), (46, 38, 2.2), (58, 30, 3), (36, 56, 2.2), (52, 62, 2.8), (66, 70, 2.4), (90, 18, 2.6),
        (96, 78, 3), (128, 44, 2.4), (142, 30, 2), (140, 62, 2.6), (28, 52, 2), (44, 50, 2.4), (62, 48, 2.8), (76, 26, 2.2),
        (80, 60, 2.6), (104, 40, 3), (118, 56, 2.2), (104, 88, 2), (150, 48, 2.2), (122, 14, 1.8), (84, 44, 1.8), (132, 80, 2),
    ]
    /// mist-puffs-calm.svg keeps these 12.
    static let calmIndices = [0, 2, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23]
    /// The puffs (centre and radius in the 160 x 100 frame); Calm keeps the first.
    static let puffs: [(Double, Double, Double)] = [(86, 44, 17), (123, 25, 12), (121, 69, 12)]

    static func dropletCount(calm: Bool) -> Int { calm ? calmIndices.count : droplets.count }

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { tl in
            let t = start.map { tl.date.timeIntervalSince($0) } ?? -1
            ZStack(alignment: .topLeading) {
                if t >= 0 && !reduceMotion { spray(t) }
                Image("dewy_drops").resizable().scaledToFit()
                    .frame(width: size * 0.55, height: size * 0.55)
                    .position(x: size * 0.5, y: size * 0.42)
                    .opacity(dewOpacity(t))
            }
            .frame(width: size, height: size)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in start = .now
            let life = reduceMotion ? Self.reduceMotionDuration : Self.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + life + 0.05) { start = nil }
        }
    }

    private func dewOpacity(_ t: Double) -> Double {
        guard t >= 0 else { return 0 }
        if reduceMotion {
            if t < 0.25 { return t / 0.25 }
            if t < 1.45 { return 1 }
            return max(0, 1 - (t - 1.45) / 0.4)
        }
        if t < 0.5 { return 0 }
        if t < 0.75 { return (t - 0.5) / 0.25 }
        if t < 1.7 { return 1 }
        return max(0, 1 - (t - 1.7) / 0.4)
    }

    @ViewBuilder private func spray(_ t: Double) -> some View {
        let w = size * 0.65, k = w / 160
        let origin = CGPoint(x: size * 0.08, y: size * 0.45)
        let travel = min(1, t / 0.6), ease = 1 - pow(1 - travel, 3)
        let fade = t < 0.6 ? 1 : max(0, 1 - (t - 0.6) / 0.3)
        Canvas { ctx, _ in
            let puffs = calm ? Array(Self.puffs.prefix(1)) : Self.puffs
            for p in puffs {
                let r = p.2 * k * (0.6 + 0.4 * ease)
                let c = CGPoint(x: origin.x + (p.0 - 8) * k, y: origin.y + (p.1 - 50) * k)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                         with: .color(Color(hex: 0xE2F1FB).opacity(0.82 * fade)))
            }
            let indices = calm ? Self.calmIndices : Array(Self.droplets.indices)
            for i in indices {
                let d = Self.droplets[i]
                let jitter = Double((i * 37) % 7) - 3
                let x = origin.x + ((d.0 - 8) * ease + jitter * (1 - ease)) * k
                let y = origin.y + ((d.1 - 50) * ease + jitter * (1 - ease)) * k
                let r = d.2 * k * (0.3 + 0.7 * ease)
                let rect = CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)
                if i < 12 {
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0x7CC4F0).opacity(fade)))
                } else {
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(fade)))
                    ctx.stroke(Path(ellipseIn: rect), with: .color(Color(hex: 0x7CC4F0).opacity(fade)), lineWidth: 1.2 * k)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityIdentifier(Self.identifier)
    }
}

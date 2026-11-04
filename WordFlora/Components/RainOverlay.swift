import SwiftUI
import UIKit

/// The whole rain cloud from design-preview/tending/parts/cloud.svg (160 x 90 box, 10 units of padding all round so
/// nothing is cropped), plus a small pale bolt inside its body that glows with a thunder flash.
struct CloudView: View {
    var storm = false
    /// 0...1 share of a thunder flash.
    var glow: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 160
            func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: (x - r) * k, y: (y - r) * k, width: 2 * r * k, height: 2 * r * k)) }
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: x * k, y: y * k, width: w * k, height: h * k), cornerRadius: r * k)
            }
            let fill = storm ? LifePalette.storm : LifePalette.cloud, edge = storm ? LifePalette.stormEdge : LifePalette.cloudEdge
            let outer = [circle(46, 52, 20), circle(76, 38, 26), circle(108, 46, 22), circle(130, 54, 14), rect(40, 46, 90, 22, 11)]
            for p in outer { ctx.fill(p, with: .color(fill)); ctx.stroke(p, with: .color(edge), style: StrokeStyle(lineWidth: 2 * k, lineJoin: .round)) }
            for p in [circle(46, 52, 18.5), circle(76, 38, 24.5), circle(108, 46, 20.5), circle(130, 54, 12.5), rect(42, 48, 86, 19, 9.5)] {
                ctx.fill(p, with: .color(fill))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 58 * k, y: 19 * k, width: 24 * k, height: 10 * k)), with: .color(.white.opacity(0.3)))
            if glow > 0 {
                var bolt = Path()
                let pts: [(CGFloat, CGFloat)] = [(82, 40), (75, 53), (80, 53), (77, 66), (88, 50), (82, 50), (86, 40)]
                bolt.move(to: CGPoint(x: pts[0].0 * k, y: pts[0].1 * k))
                for p in pts.dropFirst() { bolt.addLine(to: CGPoint(x: p.0 * k, y: p.1 * k)) }
                bolt.closeSubpath()
                ctx.fill(bolt, with: .color(Color(hex: 0xFFF3C4).opacity(0.28 * glow / 0.16)))
            }
        }
        .frame(width: 180, height: 101)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Where the rain falls on the plant stage: born under the cloud's real bottom edge (the cloud is centred,
/// 180 pt wide), landing on the ground by the plant.
struct RainGeometry: Equatable {
    var cloudTop: CGFloat
    var groundY: CGFloat
    func x0(width: CGFloat) -> CGFloat { width / 2 - 90 + 26 * 180 / 160 }
    func x1(width: CGFloat) -> CGFloat { width / 2 - 90 + 144 * 180 / 160 }
    var bottom: CGFloat { cloudTop + 66 * 180 / 160 }
}

/// Canvas rain in three depth layers with small splashes. Stateless: every drop's place is worked out from the
/// clock, so pausing (off screen, app inactive, Low Power Mode) simply freezes it. 30 fps cap; never takes taps.
struct RainCanvas: View {
    let drops: Int
    /// Which depth layers to draw: [0] behind the plant, [1, 2] in front.
    let layers: [Int]
    let geometry: RainGeometry
    let paused: Bool

    private struct Layer { let speed, length, width, alpha, share: Double; let band: ClosedRange<Double> }
    // far -> near; length = speed / 30 so streaks join up at 30 fps. Bands are offsets from the ground line.
    private static let depth = [
        Layer(speed: 420, length: 14, width: 0.9, alpha: 0.32, share: 0.45, band: -6...12),
        Layer(speed: 620, length: 21, width: 1.3, alpha: 0.5, share: 0.35, band: 10...30),
        Layer(speed: 860, length: 28, width: 1.9, alpha: 0.62, share: 0.2, band: 26...38),
    ]
    private static let slant = 0.08

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: paused)) { tl in
            Canvas { ctx, size in draw(ctx, width: size.width, time: tl.date.timeIntervalSinceReferenceDate) }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func counts() -> [Int] {
        var used = 0
        return Self.depth.enumerated().map { i, l in
            let c = i < Self.depth.count - 1 ? Int((Double(drops) * l.share).rounded()) : drops - used
            used += c; return c
        }
    }

    private static func hash(_ a: Int, _ b: Int) -> Double {
        var x = UInt64(bitPattern: Int64(a &* 73_856_093 ^ b &* 19_349_663)) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9; x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB; x ^= x >> 31
        return Double(x % 10_000) / 10_000
    }

    private func draw(_ ctx: GraphicsContext, width: CGFloat, time: Double) {
        let g = geometry, n = counts(), gx0 = Double(g.x0(width: width)), gx1 = Double(g.x1(width: width))
        for L in layers where L < Self.depth.count {
            let l = Self.depth[L]
            var streaks = Path(), splashes: [(CGPoint, Double)] = []
            for j in 0..<n[L] {
                let id = L * 1000 + j
                let gy = Double(g.groundY) + l.band.lowerBound + (l.band.upperBound - l.band.lowerBound) * Self.hash(id, 7)
                let startY = Double(g.bottom) - 40 * Self.hash(id, 3)
                let span = gy - startY
                guard span > 10 else { continue }
                let travel = time * l.speed + Self.hash(id, 1) * span
                let cycle = Int(travel / span), y = startY + travel.truncatingRemainder(dividingBy: span)
                let x0 = gx0 + (gx1 - gx0) * Self.hash(id, cycle)
                if y >= Double(g.bottom) {
                    let x = x0 + (y - startY) * Self.slant, top = max(Double(g.bottom), y - l.length)
                    streaks.move(to: CGPoint(x: x, y: y))
                    streaks.addLine(to: CGPoint(x: x - (y - top) * Self.slant, y: top))
                }
                let age = (y - startY) / l.speed          // seconds since the previous drop landed
                if age < 0.4 {
                    let px = gx0 + (gx1 - gx0) * Self.hash(id, cycle - 1) + span * Self.slant
                    splashes.append((CGPoint(x: px, y: gy), age / 0.4))
                }
            }
            ctx.stroke(streaks, with: .color(LifePalette.drop.opacity(l.alpha)), style: StrokeStyle(lineWidth: l.width, lineCap: .round))
            for (p, a) in splashes.prefix(4 + drops / 2) {
                let r = 2 + a * (4 + Double(L) * 3), al = (1 - a) * (0.22 + Double(L) * 0.12)
                ctx.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r * 0.35, width: 2 * r, height: 0.7 * r)),
                           with: .color(LifePalette.drop.opacity(al)), lineWidth: 0.8 + Double(L) * 0.3)
                if a < 0.5 {
                    ctx.fill(Path(CGRect(x: p.x - r * 0.7, y: p.y - a * 10, width: 1.3, height: 1.3)), with: .color(LifePalette.drop.opacity(al)))
                    ctx.fill(Path(CGRect(x: p.x + r * 0.7, y: p.y - a * 8, width: 1.3, height: 1.3)), with: .color(LifePalette.drop.opacity(al)))
                }
            }
        }
    }
}

/// Drives the gentle thunder: the first flash 4 to 6 s after the page opens, then a slow 1.4 s flash every 8 to 15 s
/// (never closer than 8 s). A silent flash gets a soft haptic 0.3 to 0.5 s later. The first flash of a visit (sound on,
/// no roll anywhere in the app for 3 minutes) instead calls `roll` 1.5 to 3 s after it, with the haptic at the same
/// moment so the thump is felt as it is heard; later flashes stay silent. It only runs while `active` (thunder days, on screen, app active, not Reduce Motion,
/// Calm or Quiet Garden). `flash` is the white overlay's opacity.
struct ThunderDriver: View {
    let active: Bool
    let dark: Bool
    let haptics: Bool
    var sound = false
    @Binding var flash: Double
    /// When the last roll played anywhere in the app.
    var lastRoll: () -> Date? = { nil }
    /// Plays the thunder sound; called at most once per visit.
    var roll: () -> Void = {}
    @State private var lastFlash: Date?
    @State private var visit = ThunderGate.Visit()

    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear { visit = ThunderGate.Visit() }       // each appearance of the plant page is a new visit
            .task(id: active) {
                guard active else { flash = 0; return }
                try? await Task.sleep(for: .seconds(ThunderGate.firstFlashDelay(unit: .random(in: 0...1))))   // let the child settle
                while !Task.isCancelled && active {
                    if ThunderGate.canFlash(lastFlash: lastFlash, now: .now) {
                        let rolls = sound && visit.wantsRoll(lastRoll: lastRoll(), now: .now)
                        strike(silent: !rolls)
                        if rolls {                                    // sound follows light, once per visit
                            try? await Task.sleep(for: .seconds(ThunderGate.soundDelay(unit: .random(in: 0...1))))
                            guard !Task.isCancelled && active else { break }
                            roll()
                            visit.markPlayed()
                            if haptics { thump() }
                        }
                    }
                    try? await Task.sleep(for: .seconds(ThunderGate.nextDelay(unit: .random(in: 0...1))))
                }
                flash = 0
            }
    }

    private func thump() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5) }

    private func strike(silent: Bool) {
        lastFlash = .now
        let peak = ThunderGate.peakOpacity(dark: dark)
        withAnimation(.easeIn(duration: ThunderGate.flashDuration * 0.25)) { flash = peak }
        DispatchQueue.main.asyncAfter(deadline: .now() + ThunderGate.flashDuration * 0.25) {
            withAnimation(.easeOut(duration: ThunderGate.flashDuration * 0.75)) { flash = 0 }
        }
        if haptics && silent {
            DispatchQueue.main.asyncAfter(deadline: .now() + ThunderGate.hapticDelay(unit: .random(in: 0...1))) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
            }
        }
    }
}

/// True while Low Power Mode is on, kept up to date.
@Observable
final class LowPowerWatch {
    var isOn = ProcessInfo.processInfo.isLowPowerModeEnabled
    private var token: NSObjectProtocol?
    init() {
        token = NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.isOn = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
    deinit { if let token { NotificationCenter.default.removeObserver(token) } }
}

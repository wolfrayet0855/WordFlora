import CoreGraphics
import Foundation

/// Frost & Lantern's falling snow (docs/pm/frost-lantern-snow-and-plant-review.md, section 2). Pure maths: every
/// flake's place comes from the clock and a hash, so the view holds no state and pausing simply freezes it.
/// Three depth layers: far and mid are soft dots; the near layer (the biggest flakes) is drawn as tiny six-arm
/// snowflakes so the snow reads as snowflakes, not specks.
enum Snowfall {
    struct Layer: Equatable {
        let radius: Double     // dot radius; for the near layer, half the glyph's width
        let speed: Double      // fall, pt a second
        let sway: Double       // side to side, pt either way
        let alpha: Double
        let share: Double
        let glyph: Bool
    }

    /// far -> near. The near layer's 5 or so flakes (22 on the card) are the six-arm glyphs, 6 to 9 pt across.
    static let layers = [
        Layer(radius: 1.4, speed: 14, sway: 4, alpha: 0.55, share: 0.45, glyph: false),
        Layer(radius: 2.0, speed: 20, sway: 6, alpha: 0.75, share: 0.30, glyph: false),
        Layer(radius: 3.75, speed: 27, sway: 8, alpha: 0.90, share: 0.25, glyph: true),
    ]

    /// Calm mode falls a little slower as well as thinner.
    static let calmSpeed = 0.7
    /// The plant page: flakes fade out over this many points above the ground and are not drawn below it.
    static let groundFade: Double = 24
    static let cardCount = 22
    static let stageCount = 18

    struct Flake: Equatable {
        let x: Double
        let y: Double
        let layer: Int
        let radius: Double
        let alpha: Double
        /// The glyph's turn in radians (near layer only).
        let spin: Double
    }

    /// The flake count: Calm halves it, never below one.
    static func count(base: Int, calm: Bool) -> Int { max(1, calm ? base / 2 : base) }

    /// How many flakes each layer gets. The last layer takes the remainder, so the total is always `count`
    /// (the same rounding as `RainCanvas`).
    static func counts(_ count: Int) -> [Int] {
        var used = 0
        return layers.enumerated().map { i, l in
            let c = i < layers.count - 1 ? min(count - used, Int((Double(count) * l.share).rounded())) : count - used
            used += c
            return max(0, c)
        }
    }

    /// Snow shows on the plant stage only in a pack pot, never in Quiet Garden, and never over garden weather or rain
    /// (the weather owns the sky).
    static func showsOnStage(potId: String, quietGarden: Bool, weather: Bool, raining: Bool) -> Bool {
        PotCatalog.packPots.contains { $0.id == potId } && !quietGarden && !weather && !raining
    }

    /// The ground fade: 1 well above the ground, falling to 0 at it; nil below the ground (not drawn).
    static func groundAlpha(y: Double, groundY: Double?) -> Double? {
        guard let g = groundY else { return 1 }
        if y >= g { return nil }
        return min(1, (g - y) / groundFade)
    }

    /// Every flake at `time` in a canvas of `size`. Flakes stay inside x 0...width and y -5...height+5.
    static func flakes(count: Int, size: CGSize, time: Double, calm: Bool = false,
                       layers wanted: [Int] = [0, 1, 2], groundY: Double? = nil) -> [Flake] {
        let w = Double(size.width), h = Double(size.height)
        guard w > 0, h > 0, count > 0 else { return [] }
        let n = counts(count), span = h + 10, pace = calm ? calmSpeed : 1
        var out: [Flake] = []
        for L in wanted where L >= 0 && L < layers.count {
            let l = layers[L]
            for j in 0..<n[L] {
                let id = L * 1000 + j
                let travel = time * l.speed * pace + WeatherDraw.rnd(id, 3) * span
                let cycle = Int(floor(travel / span))
                var y = travel.truncatingRemainder(dividingBy: span)
                if y < 0 { y += span }
                y -= 5
                guard let fade = groundAlpha(y: y, groundY: groundY) else { continue }
                let sway = l.sway * sin(time * 0.6 * pace + WeatherDraw.rnd(id, 5) * 2 * .pi)
                let x = min(w, max(0, w * WeatherDraw.rnd(id, 11 + cycle) + sway))
                let r = l.glyph ? l.radius * (0.8 + 0.4 * WeatherDraw.rnd(id, 7)) : l.radius   // glyphs 6 to 9 pt across
                let spin = l.glyph ? WeatherDraw.rnd(id, 9) * .pi / 3 + time * 0.25 * pace : 0
                out.append(Flake(x: x, y: y, layer: L, radius: r, alpha: l.alpha * fade, spin: spin))
            }
        }
        return out
    }
}

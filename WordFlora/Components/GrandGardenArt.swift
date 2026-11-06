import SwiftUI

/// The Grand Garden panorama (design-preview/endgame direction A): five terraced hills holding 12 + 11 + 10 + 9 + 8
/// plants, the rarest at the back and the first found at the front, each drawn at its earned stage. Layout is pure
/// (tested); `GrandGardenPanorama` paints it in a 393 x 320 design box scaled to the width.
enum GrandGardenArt {
    /// Back row first.
    static let rowCounts = [12, 11, 10, 9, 8]
    static let rowSizes: [CGFloat] = [40, 46, 52, 58, 66]
    /// Each row's baseline, up from the bottom of the 320-tall box.
    static let rowBottoms: [CGFloat] = [226, 180, 132, 84, 30]
    static let designWidth: CGFloat = 393
    static let designHeight: CGFloat = 320

    struct Spot: Equatable {
        /// Index into the plants in the order found (0 = first found).
        var index: Int
        var row: Int
        /// Centre x and baseline (up from the bottom), in points for the given width.
        var x: CGFloat
        var baseline: CGFloat
        /// The full-bloom size in points; scale by `stageScale`.
        var size: CGFloat
    }

    static func label(gold: Bool) -> String {
        gold ? "Your garden with all 50 plants in full bloom." : "Your garden with all 50 plants, some still growing."
    }

    /// Tiny 50%, Sprout 64%, Bud 80%, Full bloom 100% of the row size, so the newest finds look small.
    static func stageScale(_ stage: Int) -> CGFloat {
        switch stage {
        case ...1: return 0.5
        case 2: return 0.64
        case 3: return 0.8
        default: return 1
        }
    }

    /// Spots for `count` plants (up to 50). The front rows fill first, so a smaller garden still sits on the hills.
    static func spots(count: Int, width: CGFloat) -> [Spot] {
        let total = rowCounts.reduce(0, +), s = width / designWidth
        var out: [Spot] = []
        var k = total - 1
        for (r, n) in rowCounts.enumerated() {
            let pad: CGFloat = 10, step = (designWidth - 2 * pad) / CGFloat(n)
            for i in 0..<n {
                let jitter = CGFloat((i * 37 + r * 11) % 9 - 4)
                let x = (pad + CGFloat(i) * step + step / 2 + jitter) * s
                let y = (rowBottoms[r] - rowSizes[r] * 0.08 + ((i + r) % 2 == 1 ? 3 : 0)) * s
                if k < count { out.append(Spot(index: k, row: r, x: x, baseline: y, size: rowSizes[r] * s)) }
                k -= 1
            }
        }
        return out
    }

    static func hills(dark: Bool) -> [UInt32] {
        dark ? [0x263F27, 0x2B482D, 0x305133, 0x355A38, 0x3A633E] : [0xDCEBD2, 0xCDE3C0, 0xBFDAAF, 0xB0D19E, 0xA2C78E]
    }
}

/// One plant in the panorama: its catalog art and earned stage (1 Tiny ... 4 Full bloom).
struct GrandGardenPlant: Equatable {
    var imageName: String
    var stage: Int
}

/// The panorama. `gold` draws every plant at full bloom with a warm glow. `still` (Reduce Motion) stops the sway and
/// the fireflies. One VoiceOver sentence for the whole picture, never 50 plant names.
struct GrandGardenPanorama: View {
    let plants: [GrandGardenPlant]
    var gold = false
    var still = false
    var paused = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, s = w / GrandGardenArt.designWidth, h = GrandGardenArt.designHeight * s
            let dark = scheme == .dark
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: still || paused)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .topLeading) {
                    ForEach(0..<5, id: \.self) { r in
                        Ellipse().fill(Color(hex: GrandGardenArt.hills(dark: dark)[r]))
                            .frame(width: w * 1.28 + CGFloat(r * 12) * s, height: (GrandGardenArt.rowBottoms[r] + GrandGardenArt.rowSizes[r] * 0.18) * s * 2)
                            .position(x: w / 2 + (r % 2 == 0 ? -8 : 8) * s, y: h)
                    }
                    if dark { fireflies(w: w, s: s, t: t) }
                    ForEach(GrandGardenArt.spots(count: plants.count, width: w), id: \.index) { spot in
                        let p = plants[spot.index]
                        let size = spot.size * (gold ? 1 : GrandGardenArt.stageScale(p.stage))
                        Image(p.imageName).resizable().scaledToFit()
                            .frame(width: size, height: size)
                            .shadow(color: Color(hex: 0xF0C060).opacity(gold ? 0.7 : 0), radius: 3)
                            .rotationEffect(.degrees(still ? 0 : 1.4 * sin(t * 2 * .pi / 6 + Double(spot.index) * 0.7)), anchor: UnitPoint(x: 0.5, y: 0.92))
                            .position(x: spot.x, y: h - spot.baseline - size / 2)
                    }
                }
                .frame(width: w, height: h)
            }
        }
        .aspectRatio(GrandGardenArt.designWidth / GrandGardenArt.designHeight, contentMode: .fit)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GrandGardenArt.label(gold: gold))
        .accessibilityAddTraits(.isImage)
    }

    private func fireflies(w: CGFloat, s: CGFloat, t: Double) -> some View {
        Canvas { ctx, _ in
            for (i, f) in [(60.0, 40.0), (150, 24), (300, 90), (220, 60), (30, 110)].enumerated() {
                let a = still ? 0.8 : 0.5 + 0.5 * sin(t * 1.1 + Double(i) * 1.6)
                let x = f.0 * s + (still ? 0 : sin(t * 0.5 + Double(i)) * 6), y = f.1 * s + (still ? 0 : cos(t * 0.4 + Double(i)) * 4)
                ctx.fill(WeatherDraw.circle(x, y, 7), with: .color(Color(hex: 0xF0C060).opacity(0.18 * a)))
                ctx.fill(WeatherDraw.circle(x, y, 2.5), with: .color(Color(hex: 0xF0C060).opacity(a)))
            }
        }
    }
}

#Preview("Grand Garden") {
    let names = ["plant_daisy", "plant_sunflower", "plant_rose", "plant_lotus", "plant_baobab"]
    VStack {
        GardenersCrown().frame(width: 200)
        GrandGardenPanorama(plants: (0..<50).map { GrandGardenPlant(imageName: names[$0 % 5], stage: 1 + $0 % 4) })
    }
    .background(LinearGradient(colors: [Color(hex: 0xDFEDF8), Color(hex: 0xFDE9EE)], startPoint: .top, endPoint: .bottom))
}

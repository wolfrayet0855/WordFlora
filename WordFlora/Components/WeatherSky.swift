import SwiftUI

/// Fixed colours for the weather art, light and dark (design-preview/events/mock.html tokens). Explicit hex values so
/// Canvas drawing and image snapshots resolve the same in both modes.
struct WeatherPalette {
    let dark: Bool

    var surface: UInt32 { dark ? 0x2C3E2C : 0xFFFFFF }
    var text: UInt32 { dark ? 0xD4EDD4 : 0x2C3E2C }
    var swoosh: Color { Color(hex: dark ? 0xD4EDD4 : 0xFFFFFF) }
    var rain: Color { Color(hex: dark ? 0xA9CBEA : 0x4C7396) }
    var soilDry: Color { Color(hex: dark ? 0xD2AE7C : 0xC9A070) }
    var crack: Color { Color(hex: 0x6B4630) }
    var water: Color { dark ? Color(red: 120 / 255, green: 185 / 255, blue: 240 / 255).opacity(0.38)
                            : Color(red: 95 / 255, green: 165 / 255, blue: 230 / 255).opacity(0.42) }
    var waterLine: Color { Color(hex: dark ? 0xCBE6FA : 0xBFE0F7) }
    var pellet: Color { Color(hex: dark ? 0xF2F7FB : 0xFFFFFF) }
    var pelletEdge: Color { Color(hex: 0x8FA6BB) }
    var net: Color { Color(hex: dark ? 0xD4EDD4 : 0x2C3E2C) }
    var sun: Color { Color(hex: 0xFFC04A) }
    var cloud: Color { dark ? Color(hex: 0xC9D3DB) : Color(hex: 0xFFFFFF) }
    var greyCloud: [Color] { dark ? [Color(hex: 0x7F8E9B), Color(hex: 0x6E7D8A), Color(hex: 0x8A98A4)]
                                  : [Color(hex: 0xC5D0DB), Color(hex: 0xB4C2CF), Color(hex: 0xD2DBE4)] }
    var sparkle: Color { Color(hex: 0xFFFFFF) }
    var leaf: Color { Color(hex: 0x6DAF4A) }
    var leafEdge: Color { Color(hex: 0x2E6B2E) }

    /// `a` mixed toward `b` by `t` (0 = a, 1 = b), like CSS color-mix.
    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> Color {
        func ch(_ v: UInt32, _ s: UInt32) -> Double { Double((v >> s) & 0xFF) / 255 }
        func m(_ s: UInt32) -> Double { ch(a, s) * (1 - t) + ch(b, s) * t }
        return Color(red: m(16), green: m(8), blue: m(0))
    }

    /// The kind's sky: its hue at 34% over the surface at the top, 12% at the bottom.
    func sky(_ k: WeatherKind) -> [Color] {
        let ev = WeatherArt.tint(k)
        return [Self.mix(surface, ev, 0.34), Self.mix(surface, ev, 0.12)]
    }
}

/// The soft sky behind a weather scene: one hue per kind, plus the kind's haze (a warm glow for dry and hot days, a
/// cool veil for frost, a grey veil for wind and hail). Purely decorative.
struct WeatherSky: View {
    let kind: WeatherKind
    var look: WeatherEffect = .full
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = WeatherPalette(dark: scheme == .dark)
        ZStack {
            LinearGradient(colors: p.sky(kind), startPoint: .top, endPoint: .bottom)
            haze
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var haze: some View {
        let strength = look == .light || look == .shrugs ? 0.65 : 1.0
        switch kind {
        case .drySpell, .hotDay:
            let glow = kind == .hotDay ? 0.5 : 0.38
            RadialGradient(colors: [Color(red: 1, green: 0.77, blue: 0.31).opacity(glow * strength), .clear],
                           center: UnitPoint(x: 0.85, y: 0.1), startRadius: 0, endRadius: 260)
            Color(red: 1, green: 0.8, blue: 0.5).opacity(0.12 * strength)
        case .frostyNight:
            LinearGradient(colors: [Color(red: 0.82, green: 0.92, blue: 1).opacity(0.18), Color(red: 0.78, green: 0.9, blue: 1).opacity(0.28)],
                           startPoint: .top, endPoint: .bottom)
        case .bigWind, .hailShower:
            LinearGradient(colors: [Color(red: 0.3, green: 0.37, blue: 0.44).opacity(0.1 * strength), Color(red: 0.3, green: 0.37, blue: 0.44).opacity(0.04)],
                           startPoint: .top, endPoint: .bottom)
        case .busyBugs, .bigPuddles:
            Color.clear
        }
    }
}

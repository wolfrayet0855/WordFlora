import SwiftUI
import UIKit

/// Colours for the Life panel, love petals and weather, from design-preview/tending/lifestats.html.
/// Light meter fills are at least 3:1 on white; nothing here is red.
enum LifePalette {
    private static func dyn(_ light: UInt32, _ dark: UInt32, alpha: CGFloat = 1) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: alpha) : UIColor(hex: light, alpha: alpha) })
    }
    static let water = dyn(0x3F86C9, 0x7DB6EE)
    static let sun = dyn(0xB87F00, 0xF6C85A)
    static let leaf = dyn(0x5E8F1F, 0xA8D84A)
    static let leafBright = dyn(0x9BCB3C, 0xA8D84A)
    /// The tend toast's tick: leaf green on the dark slab in light mode, deep green on the pale slab in dark mode
    /// (6.0:1 and 4.1:1; leafBright alone is 1.3:1 on the dark-mode slab).
    static let toastTick = dyn(0x9BCB3C, 0x2E7D32)
    static let leafInk = dyn(0x22331A, 0x1A2E1A)
    static let heart = dyn(0xD9506F, 0xF08AA3)
    static let petal = dyn(0xF2788A, 0xF58A9B)
    static let petalEdge = dyn(0xD9566C, 0xE06B80)
    static let ghost = dyn(0x7C867C, 0xA9B8A9)
    static let cloud = dyn(0xB9C6CE, 0x71818B)
    static let cloudEdge = dyn(0x9FB1BC, 0x5A6972)
    static let storm = dyn(0x9AA9B3, 0x5B6A74)
    static let stormEdge = dyn(0x7D8E99, 0x46535B)
    static let drop = dyn(0x466E96, 0xAAC8E6)
    static let soil = dyn(0x7A5238, 0xA47550)
    static let clay = Color(UIColor(hex: 0xC8734A))
    static let clayRim = Color(UIColor(hex: 0xDD8C63))
    static let glass = Color.appSurface
    static let line = Color.appPrimaryText.opacity(0.14)
    static let track = Color.appPrimaryText.opacity(0.12)
    static let gold = Color(UIColor(hex: 0xF2B632))
    static let goldEdge = Color(UIColor(hex: 0xD48E1B))
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

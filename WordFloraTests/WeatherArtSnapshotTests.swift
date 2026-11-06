import XCTest
import SwiftUI
@testable import WordFlora

/// Renders every weather picture, the relief scene, the crown and the Grand Garden in light and dark, checks each one
/// actually draws, and saves PNGs (to `weather-art/` in the test's temporary folder, path printed) for a visual review
/// against design-preview/events and design-preview/endgame.
@MainActor
final class WeatherArtSnapshotTests: XCTestCase {
    private static let dir: URL = {
        let d = FileManager.default.temporaryDirectory.appendingPathComponent("weather-art", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        print("weather art snapshots: \(d.path)")
        return d
    }()

    private func render<V: View>(_ view: V, _ name: String, dark: Bool, width: CGFloat = 361) throws -> UIImage {
        let r = ImageRenderer(content: view.frame(width: width).environment(\.colorScheme, dark ? .dark : .light)
            .background(Color(hex: dark ? 0x1A2E1A : 0xFAF7F0)))
        r.scale = 2
        let img = try XCTUnwrap(r.uiImage, name)
        try img.pngData()?.write(to: Self.dir.appendingPathComponent("\(name)-\(dark ? "dark" : "light").png"))
        return img
    }

    /// How many distinct colours a coarse sample of the image holds: a blank or one-colour render has very few.
    private func colourCount(_ img: UIImage) -> Int {
        guard let cg = img.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) else { return 0 }
        var seen = Set<UInt32>()
        let bpr = cg.bytesPerRow, bpp = cg.bitsPerPixel / 8
        for y in stride(from: 0, to: cg.height, by: 7) {
            for x in stride(from: 0, to: cg.width, by: 7) {
                let o = y * bpr + x * bpp
                seen.insert(UInt32(p[o] >> 4) << 8 | UInt32(p[o + 1] >> 4) << 4 | UInt32(p[o + 2] >> 4))
            }
        }
        return seen.count
    }

    private func plant(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "plant_fern"
        case .busyBugs: return "plant_rose"
        case .bigWind: return "plant_sunflower"
        case .frostyNight: return "plant_orchid"
        case .hotDay: return "plant_lotus"
        case .hailShower: return "plant_hibiscus"
        case .bigPuddles: return "plant_aloe_vera"
        }
    }

    func testEveryWeatherPictureDrawsInLightAndDark() throws {
        for k in WeatherKind.allCases {
            for look in [WeatherEffect.full, .light, .snug, .shrugs] {
                var bytes: [Data] = []
                for dark in [false, true] {
                    let img = try render(WeatherStage(kind: k, look: look, still: true) { WeatherPreviewPlant(imageName: self.plant(k)) },
                                         "\(k.rawValue)-\(look.rawValue)", dark: dark)
                    XCTAssertGreaterThan(colourCount(img), 12, "\(k) \(look) dark: \(dark) looks blank")
                    bytes.append(img.pngData() ?? Data())
                }
                XCTAssertNotEqual(bytes[0], bytes[1], "\(k) \(look): dark mode should differ")
            }
        }
    }

    func testReliefCrownAndGrandGardenDraw() throws {
        let names = ["plant_daisy", "plant_sunflower", "plant_rose", "plant_lotus", "plant_baobab", "plant_fern", "plant_orchid"]
        let garden = (0..<50).map { GrandGardenPlant(imageName: names[$0 % names.count], stage: 1 + ($0 * 7) % 4) }
        for dark in [false, true] {
            XCTAssertGreaterThan(colourCount(try render(ReliefArt(still: true) {
                HStack(alignment: .bottom) { WeatherPreviewPlant(imageName: "plant_sunflower", size: 150) }
            }.frame(height: 380), "relief", dark: dark, width: 393)), 12)
            XCTAssertGreaterThan(colourCount(try render(GardenersCrown().frame(width: 240), "crown", dark: dark, width: 240)), 6)
            XCTAssertGreaterThan(colourCount(try render(GardenersCrown(gold: true).frame(width: 240), "crown-gold", dark: dark, width: 240)), 6)
            XCTAssertGreaterThan(colourCount(try render(GrandGardenPanorama(plants: garden, still: true), "grand-garden", dark: dark, width: 393)), 12)
            XCTAssertGreaterThan(colourCount(try render(GrandGardenPanorama(plants: garden, gold: true, still: true), "grand-garden-gold", dark: dark, width: 393)), 12)
        }
    }
}

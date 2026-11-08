import CoreGraphics
import Foundation

// The full Frost & Lantern pack (release plan G5): two glasshouse plants, two winter friends and the snowy lantern
// scene. Nothing here is stored: ownership is read from StoreKit every time (`EntitlementService.ownsPack`), and the
// glasshouse plants' care lives in ordinary `PlantCollectible` rows under glasshouse ids (existing fields only).

/// A plant that comes with a season pack. It sits outside the 50-plant ladder: never in `ProgressionPolicy`, the word
/// level, "words toward your next plant", the plant badges, the pot unlocks or the Grand Garden panorama.
struct GlasshousePlant: Equatable, Identifiable {
    /// The `PlantCollectible.plantId` (always `GlasshouseCatalog.idPrefix` + a name, so it never meets a ladder id).
    let id: String
    let name: String
    let botanicalName: String
    /// Checked against two sources (docs/research/frost-lantern-facts-check.md).
    let fact: String
    /// The art (`Assets.xcassets/Glasshouse`, layers in `PlantLayers`, thinning in `PlantThinning.json`).
    let imageName: String
    let packId: String
}

enum GlasshouseCatalog {
    static let idPrefix = "glasshouse_"
    /// Rows sit below the ladder's level 1...5, so a level filter never picks them up either.
    static let level = 0

    static let snowdrop = GlasshousePlant(
        id: idPrefix + "snowdrop", name: "Snowdrop", botanicalName: "Galanthus nivalis",
        fact: "Snowdrops often bloom in January and February.", imageName: "plant_snowdrop", packId: PackCatalog.frostLanternId)
    static let hellebore = GlasshousePlant(
        id: idPrefix + "hellebore", name: "Hellebore", botanicalName: "Helleborus orientalis",
        fact: "Hellebore flowers have petal-like parts called sepals that stay on for weeks.",
        imageName: "plant_hellebore", packId: PackCatalog.frostLanternId)

    static let all: [GlasshousePlant] = [snowdrop, hellebore]

    static func isGlasshouse(_ plantId: String) -> Bool { plantId.hasPrefix(idPrefix) }
    static func plant(id: String) -> GlasshousePlant? { all.first { $0.id == id } }
    static func plants(ofPack packId: String) -> [GlasshousePlant] { all.filter { $0.packId == packId } }

    /// The glasshouse plants that show for these owned packs. A row stays in the store when a pack lapses (nothing
    /// earned is removed), it just is not shown until the pack is back.
    static func shown(ownedPacks: Set<String>) -> [GlasshousePlant] { all.filter { ownedPacks.contains($0.packId) } }

    /// The glasshouse plants that still need a row (owned, no row yet).
    static func missing(ownedPacks: Set<String>, existingIds: Set<String>) -> [GlasshousePlant] {
        shown(ownedPacks: ownedPacks).filter { !existingIds.contains($0.id) }
    }

    /// The ladder rows only: every progression count reads this, never the glasshouse rows.
    static func ladder<T>(_ rows: [T], id: (T) -> String) -> [T] { rows.filter { !isGlasshouse(id($0)) } }
}

extension VisitorCatalog {
    /// The winter friends: they come to the butterfly game only for pack owners, and never count toward the twelve
    /// friends (the album total, `StickerAlbum.species`, the Visitors' book, the friend of the day).
    /// The wren is the Eurasian wren and is "Wren" everywhere.
    static let season: [VisitorSpecies] = [
        VisitorSpecies(id: "robin", name: "Robin", rarity: .uncommon, packId: PackCatalog.frostLanternId,
                       fact: "Robins sing through the winter, not just in spring."),
        VisitorSpecies(id: "wren", name: "Wren", rarity: .uncommon, packId: PackCatalog.frostLanternId,
                       fact: "A wren is tiny, but its song is remarkably loud."),
    ]
    static func isSeason(_ id: String) -> Bool { season.contains { $0.id == id } }
    /// The winter friends that may visit with these packs owned.
    static func seasonPool(ownedPacks: Set<String>) -> [String] {
        season.filter { $0.packId.map(ownedPacks.contains) ?? false }.map(\.id)
    }
}

/// Where the snowy lantern scene shows and how it sits on the screen.
enum FrostLanternScene {
    static let imageName = "frost_lantern_scene"
    /// The art's own box (scene-light.svg / scene-dark.svg).
    static let artSize = CGSize(width: 393, height: 852)
    /// Text above this line of the art sits on the calm sky; below it, on the snow bank, it needs a card or a scrim.
    static let skyLine: CGFloat = 460
    /// The scrim behind text over the scene: `appBackground` at this opacity (5.5:1 on the dark bank; 50 % is the floor).
    static let scrimOpacity = 0.6
    static let snowCount = 16

    /// Home and Garden for owners. Cosmetic, so it shows in Calm and Quiet Garden too.
    static func shows(ownedPacks: Set<String>) -> Bool { ownedPacks.contains(PackCatalog.frostLanternId) }

    /// The snow over the scene: never in Quiet Garden (as on the pack card); Calm halves it (`Snowfall.count`).
    static func snows(quietGarden: Bool) -> Bool { !quietGarden }

    /// Aspect fill anchored to the bottom: the art scales to cover the screen and keeps its snow bank, fence and
    /// lanterns; a taller screen crops nothing at the bottom, a wider one trims the sky and the far sides evenly.
    /// Returns the art's drawn frame in the screen's coordinates.
    static func frame(in screen: CGSize) -> CGRect {
        guard screen.width > 0, screen.height > 0 else { return .zero }
        let scale = max(screen.width / artSize.width, screen.height / artSize.height)
        let w = artSize.width * scale, h = artSize.height * scale
        return CGRect(x: (screen.width - w) / 2, y: screen.height - h, width: w, height: h)
    }

    /// The screen y where the snow bank starts (text below it needs the card or scrim).
    static func skyLineY(in screen: CGSize) -> CGFloat {
        let f = frame(in: screen)
        return f.minY + skyLine * f.height / artSize.height
    }
}

/// Every new kid-visible Frost & Lantern line (G5), checked by CopySafety in tests.
enum FrostLanternCopy {
    static let sceneLabel = "A snowy garden with lanterns"
    static let glasshouseTitle = "Glasshouse"
    static let glasshouseLine = "Winter plants from Frost & Lantern. They grow with care."
    static let glasshouseCardHint = "Grows with care"
    static let seasonFriendsTitle = "Winter friends"
    static let seasonFriendsLine = "From Frost & Lantern."
    static let seasonHintOwned = "Say hello in the game"
    /// Not owned: the soft outline with the same line as the pack pots (no price, no lock).
    static var seasonHintNotOwned: String { PotCatalog.packHint }
    static let packLine = "Three winter pots, a snowy lantern garden, two winter friends and two glasshouse plants. Pay once, no renewals."
    static let badgeLine = "The Lantern Keeper badge is earned by play: grow plants in the Frosted glass pot, or say hello to a winter friend."
    static let badgeBlurb = "Grow plants in the Frosted glass pot or meet winter friends"
    static let holdsPlants = "Two glasshouse plants: Snowdrop and Hellebore"
    static let holdsFriends = "Two winter friends: Robin and Wren"
    static let holdsScene = "A snowy lantern garden behind Home and your garden"

    static func stickerLabel(_ name: String, met: Bool) -> String { met ? "\(name) sticker" : "\(name), not met yet" }

    static var all: [String] {
        [sceneLabel, glasshouseTitle, glasshouseLine, glasshouseCardHint, seasonFriendsTitle, seasonFriendsLine,
         seasonHintOwned, seasonHintNotOwned, packLine, badgeLine, badgeBlurb, holdsPlants, holdsFriends, holdsScene]
            + GlasshouseCatalog.all.flatMap { [$0.name, $0.botanicalName, $0.fact] }
            + VisitorCatalog.season.flatMap { [$0.name, $0.fact ?? "", stickerLabel($0.name, met: true), stickerLabel($0.name, met: false)] }
    }
}

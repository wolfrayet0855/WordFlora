import Foundation

/// The rules behind the badges that are worked out from the garden, the album, the round and the clock. Pure, so
/// each one is unit tested; `AppModel+Badges` feeds the results to `BadgeState`.
enum BadgeFacts {
    /// A found plant and how far it has grown, with its catalogue traits.
    struct Plant: Equatable {
        var level: Int
        var stage: Int
        var traits: Set<String>
        init(level: Int, stage: Int, traits: Set<String>) { self.level = level; self.stage = stage; self.traits = traits }
    }

    /// Rare plants are the far-away ones of levels 4 and 5 (the guide's "Rare plants" peek).
    static let rareFromLevel = 4
    static let desertTraits: Set<String> = ["desert", "cactus", "succulent"]
    static let waterTraits: Set<String> = ["aquatic", "bog"]
    static let treeTraits: Set<String> = ["tree"]
    /// Stage 3 is in flower (the stage the butterfly game counts as flowering); stage 4 is full bloom.
    static let floweringStage = 3
    static let fullBloomStage = 4

    /// The collection counts for the plants found so far.
    static func collection(_ found: [Plant]) -> [BadgeCounter: Int] {
        func count(_ test: (Plant) -> Bool) -> Int { found.filter(test).count }
        return [
            .rarePlants: count { $0.level >= rareFromLevel },
            .desertPlants: count { !$0.traits.isDisjoint(with: desertTraits) },
            .waterPlants: count { !$0.traits.isDisjoint(with: waterTraits) },
            .treePlants: count { !$0.traits.isDisjoint(with: treeTraits) },
            .floweringPlants: count { $0.stage >= floweringStage },
            .fullBlooms: count { $0.stage >= fullBloomStage },
        ]
    }

    /// Stickers in the album (every visitor sticker, repeats too; weather stickers are not visitors) and the rare
    /// visitor species met.
    static func album(_ album: StickerAlbum) -> [BadgeCounter: Int] {
        let visitors = VisitorCatalog.all
        return [
            .stickers: visitors.reduce(0) { $0 + album.count(of: $1.id) },
            .rareSpecies: visitors.filter { $0.rarity == .rare && album.count(of: $0.id) > 0 }.count,
        ]
    }

    static let beeIds: Set<String> = ["honeybee", "bumblebee"]

    /// What one butterfly game adds: every catch, the evening friends among them, and the bees.
    static func catches(_ caught: [String]) -> [BadgeCounter: Int] {
        [
            .catches: caught.count,
            .duskCatches: caught.filter { VisitorCatalog.species($0)?.nightOnly == true }.count,
            .beeCatches: caught.filter { beeIds.contains($0) }.count,
        ]
    }

    /// Tool upgrades bought in the Shed: each tier above the first is one (6 tools x 2 = 12).
    static func shedUpgrades(_ inventory: ToolInventory) -> Int {
        ToolID.allCases.reduce(0) { $0 + max(0, inventory.tier(of: $1) - 1) }
    }

    /// A long word has this many letters or more (spaces do not count).
    static let longWordLetters = 9
    static func isLongWord(_ word: String) -> Bool { word.filter(\.isLetter).count >= longWordLetters }

    /// A steady solve has at most this many wrong letters (a perfect one counts too).
    static let steadyMisses = 2
    static func isSteady(misses: Int) -> Bool { misses <= steadyMisses }

    /// Morning is 5:00 to 11:59 on the device clock.
    static func isMorning(_ date: Date, calendar: Calendar) -> Bool {
        let h = calendar.component(.hour, from: date)
        return h >= 5 && h < 12
    }

    /// A local day number, so "a new day" follows the player's own midnight (and DST).
    static func dayNumber(_ date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(identifier: "UTC")!
        let d = utc.date(from: DateComponents(year: c.year, month: c.month, day: c.day)) ?? date
        return Int((d.timeIntervalSince1970 / 86_400).rounded())
    }
}

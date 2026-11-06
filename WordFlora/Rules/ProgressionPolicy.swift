/// Two tracks (spec section 19, P-01): word level = 10 unique plants earned; garden level = all 10 at stage 4.
struct PlantProgress: Equatable {
    var level: Int
    var earned: Bool
    var stage: Int
}

enum ProgressionPolicy {
    static func wordLevel(plants: [PlantProgress], economy: Economy) -> Int {
        var level = 1
        while level < 5, plants.filter({ $0.level == level && $0.earned }).count >= economy.plantsPerLevel {
            level += 1
        }
        return level
    }

    static func gardenLevelComplete(_ level: Int, plants: [PlantProgress]) -> Bool {
        let inLevel = plants.filter { $0.level == level }
        return inLevel.count == 10 && inLevel.allSatisfy { $0.earned && $0.stage >= 4 }
    }

    static func selectableLevels(wordLevel: Int) -> [Int] { Array(1...max(1, wordLevel)) }
}

/// Words for the "words toward your next plant" lines (win card and Home). Positive only; checked by CopySafety in tests.
enum PlantProgressCopy {
    static let winTitle = "Great word!"
    /// Under the win card title when no plant arrived, e.g. "2 of 3 words to your next plant."
    static func winLine(toward: Int, per: Int) -> String { homeLine(toward: toward, per: per) + "." }
    /// Home, under the Garden Days line, e.g. "2 of 3 words to your next plant".
    static func homeLine(toward: Int, per: Int) -> String { "\(toward) of \(per) words to your next plant" }
}

/// One stop on the Garden Path level map: what the medal draws and what the card says.
struct LevelStop: Equatable {
    var level: Int
    var name: String
    var theme: String
    var heroImage: String
    var found: Int
    var bloom: Int
    /// All 10 plants in the level are in full bloom (`ProgressionPolicy.gardenLevelComplete`).
    var fullBloom: Bool
    var isCurrent: Bool
    /// Not open yet. Shown as "Coming soon in your garden", never with a closed sign.
    var isSoon: Bool
    /// Wild Weather only: full-bloom plants that show a stage lower for now (the bloom ring's dashed "mending" arcs).
    /// Shown, never stored: `bloom` and `fullBloom` keep reading earned stages.
    var mending: Int = 0
    var isOpen: Bool { !isSoon }
    /// The mending line under the counts, when Wild Weather has dipped a plant here.
    var mendingLine: String? { isOpen && mending > 0 ? LevelMapCopy.mendingRow(mending) : nil }
    var allFound: Bool { found >= LevelMapCopy.perLevel }

    /// Rows under the theme line: the two counts, or "Find your first plant!" when nothing is found yet. None on soon levels.
    var rows: [String] {
        guard isOpen else { return [] }
        return found == 0 ? [LevelMapCopy.firstPlant] : [LevelMapCopy.foundRow(found), LevelMapCopy.bloomRow(bloom)]
    }
    /// Green status line ("All 10 found! ..."), when it applies.
    var allFoundLine: String? { isOpen && allFound ? LevelMapCopy.allFoundLine(level: level) : nil }
    /// Gold "Full bloom garden!" line, when it applies.
    var fullBloomLine: String? { isOpen && fullBloom ? LevelMapCopy.fullBloom : nil }
    /// Current level only, while it still has plants to find.
    var nextStep: String? { isCurrent && !allFound ? LevelMapCopy.nextStep(level: level, found: found) : nil }

    /// One VoiceOver label for the stop, repeating the visible card text in order.
    var accessibilityLabel: String {
        var parts = ["\(LevelMapCopy.eyebrow(level)), \(name).", LevelMapCopy.sentence(theme)]
        if isSoon {
            parts += [LevelMapCopy.sentence(LevelMapCopy.soonTag), LevelMapCopy.soonLine(level: level)]
        } else {
            if isCurrent { parts.append(LevelMapCopy.sentence(LevelMapCopy.chip)) }
            parts += rows.map(LevelMapCopy.sentence)
            parts += [mendingLine, allFoundLine, fullBloomLine, nextStep].compactMap { $0 }
        }
        return parts.joined(separator: " ")
    }
}

/// Every word on the Garden Path level map, and the per-level state it shows. Positive only; checked by CopySafety in tests.
/// No padlock icons or wording: levels not open yet are "Coming soon in your garden".
enum LevelMapCopy {
    static let perLevel = 10
    static let levels = 5
    static let back = "Home"
    static let title = "Garden Path"
    static let keyPetal = "Petal = plant found"
    static let keyRing = "Gold ring = full bloom"
    static let keyAccessibility = "Petal means plant found. Gold ring means full bloom."
    static let chip = "You are here"
    static let firstPlant = "Find your first plant!"
    static let fullBloom = "Full bloom garden!"
    static let soonTag = "Coming soon in your garden"
    static let end = "A bench to rest at the end of the path"

    static let names = ["Seedling", "Sprout", "Bloom", "Grove", "Ancient"]
    /// Provisional theme lines from the mockup (owner decision 1).
    static let themes = ["Garden friends", "Plants from far away", "Strange and wild plants", "Rare wonders", "Old, giant and rare"]
    /// Image names of the plant drawn on each level's medal (ids from Plants.json).
    static let heroImages = ["plant_daisy", "plant_lotus", "plant_venus_flytrap", "plant_giant_water_lily", "plant_wollemi_pine"]

    static func subLine(totalFound: Int) -> String {
        switch totalFound {
        case ..<1: return "Every 10 plants opens a new level."
        case 1: return "1 plant found. Every 10 plants opens a new level."
        case (perLevel * levels)...: return "All \(perLevel * levels) plants found! Grow them all to full bloom."
        default: return "\(totalFound) plants found. Every 10 plants opens a new level."
        }
    }

    static func eyebrow(_ level: Int) -> String { "Level \(level)" }
    static func play(_ level: Int) -> String { "Play Level \(level)" }
    static func foundRow(_ n: Int) -> String { "\(n) of \(perLevel) plants found" }
    static func bloomRow(_ n: Int) -> String { "\(n) of \(perLevel) in full bloom" }
    /// Wild Weather's dashed arcs, in words.
    static func mendingRow(_ n: Int) -> String {
        n == 1 ? "1 plant is resting after the weather. Care helps it stand tall." : "\(n) plants are resting after the weather. Care helps them stand tall."
    }
    static func allFoundLine(level: Int) -> String {
        level < levels ? "All 10 found! Level \(level + 1) is open." : "All 10 found! Every level is open."
    }
    static func nextStep(level: Int, found: Int) -> String {
        let more = max(perLevel - found, 0)
        if level < levels {
            return found == 0 ? "Find 10 plants to open Level \(level + 1)." : "Find \(more) more to open Level \(level + 1)."
        }
        return found == 0 ? "Find 10 plants for Level \(level)." : "Find \(more) more for Level \(level)."
    }
    static func soonLine(level: Int) -> String { "Opens when Level \(level - 1) has 10 plants." }

    /// Adds a full stop when a line has no closing punctuation, for VoiceOver labels.
    static func sentence(_ s: String) -> String { s.hasSuffix(".") || s.hasSuffix("!") ? s : s + "." }

    /// The five stops. `currentLevel` is the word level (`app.profile?.currentLevel`): lower levels are open, higher ones are soon.
    /// `mending`: Wild Weather's shown dips per level (`AppModel.levelMending`), capped at the level's bloom count.
    static func stops(plants: [PlantProgress], currentLevel: Int, mending: [Int: Int] = [:]) -> [LevelStop] {
        let current = min(max(currentLevel, 1), levels)
        return (1...levels).map { level in
            let inLevel = plants.filter { $0.level == level }
            let bloom = inLevel.filter { $0.stage >= 4 }.count
            return LevelStop(level: level, name: names[level - 1], theme: themes[level - 1], heroImage: heroImages[level - 1],
                             found: inLevel.filter(\.earned).count,
                             bloom: bloom,
                             fullBloom: ProgressionPolicy.gardenLevelComplete(level, plants: plants),
                             isCurrent: level == current, isSoon: level > current,
                             mending: min(max(0, mending[level] ?? 0), bloom))
        }
    }

    /// Every fixed string and every form a counted string can take, for the copy tests.
    static var allStrings: [String] {
        var all = [back, title, keyPetal, keyRing, keyAccessibility, chip, firstPlant, fullBloom, soonTag, end] + names + themes
        for n in [0, 1, 14, 49, 50] { all.append(subLine(totalFound: n)) }
        for level in 1...levels {
            all += [eyebrow(level), play(level), allFoundLine(level: level), soonLine(level: level)]
            for found in 0...perLevel { all += [foundRow(found), bloomRow(found), nextStep(level: level, found: found)] }
            for n in 1...4 { all.append(mendingRow(n)) }
        }
        return all
    }
}

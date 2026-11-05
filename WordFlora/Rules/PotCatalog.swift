import Foundation

/// One cosmetic pot (design-preview/pots/pots.json, reviewed in design-preview/pots/review.md).
/// Colours are 0xRRGGBB. Every pot has its own pattern, so no two depend on hue alone.
struct Pot: Equatable, Hashable, Identifiable {
    enum Unlock: Equatable, Hashable {
        case free
        /// Plants grown (found plants in the collection) at least this many.
        case plants(Int)
        /// This level finished (all ten of its plants found). The level itself, not a count of levels.
        case level(Int)
        /// Garden Days (different days played, any days) at least this many. Garden Days never go down.
        case gardenDays(Int)
        case plus
    }

    struct Decoration: Equatable, Hashable {
        enum Kind: String, CaseIterable, Hashable {
            case none, rings, drip, flower, stars, hearts, dots, stripes, moon, flowerBand
            case blossoms, pebbles, zigzag, vine, bark, drops
        }
        var kind: Kind
        var colors: [UInt32]
    }

    let id: String
    let name: String
    let body: UInt32
    let rim: UInt32
    let shade: UInt32
    let decoration: Decoration
    let unlock: Unlock
    let hint: String
    let a11y: String
    /// Earlier rules this pot was earned by. A pot is owned when its rule or any of these passes, so moving a goal
    /// earlier never takes a pot away (docs/pm/pot-earning-review.md, section 4).
    var legacy: [Unlock] = []
    /// The name VoiceOver reads, when it should differ from the written one ("Fly-trap" for "Flytrap").
    var spokenName: String? = nil
    var voiceName: String { spokenName ?? name }
}

/// Where a pot stands for this player: worked out from play each time, or recorded as earned before
/// (`PlayerProfile.earnedPotIds`, which only ever grows).
enum PotState: Equatable {
    case owned
    case toEarn(hint: String)
    case plus(hint: String)
}

/// One mark of a pot's pattern in the shared 120 x 100 pot box (the same box as `TendScene.drawPot`).
/// Rects are top-left plus size; circles, petals, sparkles and hearts give their centre. `color` indexes the
/// decoration's colours. Marks are drawn after the light and shade strips, clipped to the body, before the rim.
struct PotMark: Equatable {
    enum Shape: Equatable {
        case rect(x: Double, y: Double, width: Double, height: Double)
        case capsule(x: Double, y: Double, width: Double, height: Double)
        case circle(cx: Double, cy: Double, r: Double)
        /// An ellipse centred `distance` above (cx, cy), then turned clockwise by `degrees` about (cx, cy).
        case petal(cx: Double, cy: Double, distance: Double, rx: Double, ry: Double, degrees: Double)
        /// The four-point sparkle (M0 -7 Q1 -1.5 7 0 ...), scaled.
        case sparkle(cx: Double, cy: Double, scale: Double)
        /// The heart (M0 5 C-8 -1 -8 -8 -3 -8 ...), scaled.
        case heart(cx: Double, cy: Double, scale: Double)
        /// A circle with a second circle cut away (no paint in the body colour).
        case crescent(cx: Double, cy: Double, r: Double, cutX: Double, cutY: Double, cutR: Double)
        case triangle(x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double)
        /// The dewdrop (M0 -9 C4 -3 6 0 6 3 A6 6 0 0 1 -6 3 C-6 0 -4 -3 0 -9 Z), scaled.
        case teardrop(cx: Double, cy: Double, scale: Double)
    }
    /// How a mark looks on a pot to earn: in ink (most marks), in the pale fill (a knock-out detail such as a
    /// flower's centre), or not at all (a tiny sparkle that would only add noise to the outline).
    enum Ghost: Equatable { case ink, fill, hidden }
    var shape: Shape
    var color = 0
    var opacity = 1.0
    var ghost = Ghost.ink
}

/// The sixteen pots (docs/pm/pot-earning-review.md): plain blue to start, twelve earned by play and kept for good
/// (a halfway pot and a capstone in every level, plus Dewdrop for Garden Days), three with WordFlora Plus.
/// A pot already on a plant stays on it, even after Plus ends; choosing a new Plus pot needs Plus.
enum PotCatalog {
    static let plainBlue = Pot(id: "plainBlue", name: "Plain blue", body: 0x5B8FD0, rim: 0x7AA6DE, shade: 0x4677B3,
                               decoration: .init(kind: .none, colors: []), unlock: .free,
                               hint: "Every garden starts with this pot.", a11y: "Plain blue pot")

    private static let plusHint = "Part of WordFlora Plus. A grown-up can find Plus in Settings."

    static let all: [Pot] = [
        plainBlue,
        Pot(id: "terracotta", name: "Terracotta", body: 0xC8734A, rim: 0xDD8C63, shade: 0xA85A36,
            decoration: .init(kind: .rings, colors: [0x7E3F22]), unlock: .plants(1),
            hint: "Grow your first plant to earn this pot.", a11y: "Terracotta pot with two rings"),
        Pot(id: "sageGlaze", name: "Sage glaze", body: 0x8FB08C, rim: 0xB4CCB1, shade: 0x76996F,
            decoration: .init(kind: .drip, colors: [0xE2EFDE]), unlock: .plants(5),
            hint: "Grow 5 plants to earn this pot.", a11y: "Sage green pot with a drippy glaze", legacy: [.plants(10)]),
        Pot(id: "sunflower", name: "Sunflower", body: 0xF2C230, rim: 0xF8D95F, shade: 0xD9A514,
            decoration: .init(kind: .flower, colors: [0xE07F2A, 0x6B4528]), unlock: .level(1),
            hint: "Finish level 1 to earn this pot.", a11y: "Yellow pot with a big flower", legacy: [.level(3)]),
        Pot(id: "mint", name: "Mint", body: 0x7CCFA8, rim: 0xA8E5C8, shade: 0x5BB38A,
            decoration: .init(kind: .dots, colors: [0xFFFFFF]), unlock: .plants(15),
            hint: "Grow 15 plants to earn this pot.", a11y: "Mint green pot with white dots", legacy: [.plants(50)]),
        Pot(id: "blossom", name: "Blossom", body: 0x9A6A9E, rim: 0xBE93C2, shade: 0x7A4F7E,
            decoration: .init(kind: .blossoms, colors: [0xFFE6EE, 0xF2C14E]), unlock: .level(2),
            hint: "Finish level 2 to earn this pot.", a11y: "Plum pot with pink blossoms"),
        Pot(id: "rosePink", name: "Rose pink", body: 0xE8869F, rim: 0xF2A9BC, shade: 0xCC6683,
            decoration: .init(kind: .hearts, colors: [0xFFE9EF]), unlock: .plants(25),
            hint: "Grow 25 plants to earn this pot.", a11y: "Pink pot with hearts"),
        Pot(id: "livingStones", name: "Living stones", body: 0xDDBB8E, rim: 0xECD3AE, shade: 0xB89262,
            decoration: .init(kind: .pebbles, colors: [0x55663A, 0x3B2E22]), unlock: .level(3),
            hint: "Finish level 3 to earn this pot.", a11y: "Sandy pot with little living stones"),
        Pot(id: "flytrap", name: "Flytrap", body: 0x4E8A3A, rim: 0x7BB25C, shade: 0x3A6C2B,
            decoration: .init(kind: .zigzag, colors: [0xF29A8A, 0xFFFFFF]), unlock: .plants(35),
            hint: "Grow 35 plants to earn this pot.", a11y: "Green pot with fly-trap teeth", spokenName: "Fly-trap"),
        Pot(id: "starlight", name: "Starlight", body: 0x2F6670, rim: 0x5A98A2, shade: 0x224C54,
            decoration: .init(kind: .stars, colors: [0xFFE27A, 0xFFFFFF]), unlock: .level(4),
            hint: "Finish level 4 to earn this pot.", a11y: "Deep teal pot with twinkly stars", legacy: [.level(5)]),
        Pot(id: "jadeVine", name: "Jade vine", body: 0xE9EEF0, rim: 0x4FA89A, shade: 0xC4CED2,
            decoration: .init(kind: .vine, colors: [0x3FB8A6, 0x2F6B4A]), unlock: .plants(45),
            hint: "Grow 45 plants to earn this pot.", a11y: "White pot with hanging jade flowers"),
        Pot(id: "rainbowBark", name: "Rainbow bark", body: 0x8A7B63, rim: 0xAA9B80, shade: 0x6E6150,
            decoration: .init(kind: .bark, colors: [0xEE8A3C, 0x8C5BA6, 0x4E8FC4, 0xB5474A]), unlock: .level(5),
            hint: "Finish level 5 to earn this pot.", a11y: "Brown pot with rainbow bark stripes"),
        Pot(id: "dewdrop", name: "Dewdrop", body: 0x9686CC, rim: 0xB9ADE3, shade: 0x7666B0,
            decoration: .init(kind: .drops, colors: [0xE3F2FC, 0xFFFFFF]), unlock: .gardenDays(7),
            hint: "Play on 7 different days to earn this pot. Any days count!", a11y: "Lilac pot with dewdrops"),
        Pot(id: "honeyStripe", name: "Honey stripe", body: 0xE39B2E, rim: 0xF2BC5E, shade: 0xC47F18,
            decoration: .init(kind: .stripes, colors: [0xFFF0C2]), unlock: .plus,
            hint: plusHint, a11y: "Honey pot with up and down stripes"),
        Pot(id: "moonlit", name: "Moonlit", body: 0x3B4A80, rim: 0x7383C4, shade: 0x2A3560,
            decoration: .init(kind: .moon, colors: [0xF6E08A, 0xF6E08A]), unlock: .plus,
            hint: plusHint, a11y: "Night blue pot with a moon and tiny stars"),
        Pot(id: "meadow", name: "Meadow", body: 0xF3E6BF, rim: 0x5E9E45, shade: 0xD6C38E,
            decoration: .init(kind: .flowerBand, colors: [0x6FA552, 0xFFFFFF, 0xF6A6BE, 0xF2B632]), unlock: .plus,
            hint: plusHint, a11y: "Cream pot with a band of grass and tiny flowers"),
    ]

    /// The pick grid and the Shed grid: 4 x 4 at every text size.
    static let gridColumns = 4

    /// Empty (never chosen) and unknown ids are plain blue.
    static func pot(id: String) -> Pot { all.first { $0.id == id } ?? plainBlue }

    // MARK: Unlocks (computed from play, plus the ever-growing record of pots earned before)

    struct Stats: Equatable {
        var plantsGrown = 0
        /// Which levels are finished, so a level pot asks for its own level.
        var finishedLevels: Set<Int> = []
        /// Found plants in each level (1...5), for a level pot's progress ("6 of 10 plants in level 3").
        var plantsInLevel: [Int: Int] = [:]
        /// Different days played (`PlayerProfile.gardenDays`): never goes down, merged by max on sync.
        var gardenDays = 0
        /// Pots recorded as earned (`PlayerProfile.earnedPotIds`). A pot in here stays owned whatever the numbers say.
        var earnedPotIds: Set<String> = []
        var levelsFinished: Int { finishedLevels.count }
    }

    /// Plants grown = found plants; a level is finished when all ten of its plants are found (as the level badge counts).
    static func stats(plants: [PlantProgress], gardenDays: Int = 0, earnedPotIds: [String] = []) -> Stats {
        let finished = (1...5).filter { lvl in
            let inLevel = plants.filter { $0.level == lvl }
            return inLevel.count == 10 && inLevel.allSatisfy(\.earned)
        }
        var perLevel = [Int: Int]()
        for p in plants where p.earned { perLevel[p.level, default: 0] += 1 }
        return Stats(plantsGrown: plants.filter(\.earned).count, finishedLevels: Set(finished), plantsInLevel: perLevel,
                     gardenDays: gardenDays, earnedPotIds: Set(earnedPotIds))
    }

    /// Plants in one level, for that level's progress.
    static let plantsPerLevel = 10

    /// Whether one rule passes on these numbers (Plus is separate: it never comes from play).
    static func passes(_ unlock: Pot.Unlock, _ s: Stats) -> Bool {
        switch unlock {
        case .free: return true
        case .plants(let n): return s.plantsGrown >= n
        case .level(let n): return s.finishedLevels.contains(n)
        case .gardenDays(let n): return s.gardenDays >= n
        case .plus: return false
        }
    }

    /// Earned by play: the pot's rule or one of its earlier rules passes. Plus pots are never earned by play.
    static func earnedByPlay(_ pot: Pot, _ s: Stats) -> Bool {
        pot.unlock != .plus && (passes(pot.unlock, s) || pot.legacy.contains { passes($0, s) })
    }

    static func state(of pot: Pot, stats s: Stats, hasPlus: Bool) -> PotState {
        if pot.unlock == .plus { return hasPlus ? .owned : .plus(hint: pot.hint) }
        return earnedByPlay(pot, s) || s.earnedPotIds.contains(pot.id) ? .owned : .toEarn(hint: pot.hint)
    }

    /// The pot already on the plant can always stay; any other pot must be owned now.
    static func canChoose(_ pot: Pot, currentId: String, stats: Stats, hasPlus: Bool) -> Bool {
        if pot.id == self.pot(id: currentId).id { return true }
        return state(of: pot, stats: stats, hasPlus: hasPlus) == .owned
    }

    /// The earned pots to record for good: `recorded` plus every pot earned by play now (not plain blue, which every
    /// garden has, and never a Plus pot). Sorted, so the stored list is the same on every device.
    static func recordEarned(_ recorded: [String], stats: Stats) -> [String] {
        let now = all.filter { $0.unlock != .free && earnedByPlay($0, stats) }.map(\.id)
        return Set(recorded).union(now).sorted()
    }

    struct Progress: Equatable {
        var now: Int
        var goal: Int
        var fraction: Double { goal > 0 ? min(1, Double(now) / Double(goal)) : 1 }
    }

    /// How far along a pot to earn is; nil for plain blue and Plus pots. A level pot counts that level's plants
    /// (full once the level is finished); Garden Days count up and never down.
    static func progress(_ pot: Pot, stats s: Stats) -> Progress? {
        switch pot.unlock {
        case .plants(let n): return Progress(now: min(s.plantsGrown, n), goal: n)
        case .level(let n):
            let now = s.finishedLevels.contains(n) ? plantsPerLevel : min(s.plantsInLevel[n] ?? 0, plantsPerLevel)
            return Progress(now: now, goal: plantsPerLevel)
        case .gardenDays(let n): return Progress(now: min(s.gardenDays, n), goal: n)
        case .free, .plus: return nil
        }
    }

    // MARK: Copy (pots.json `copy`, with the critic's corrections)

    enum Copy {
        static let earned = "You earned this pot!"
        static let current = "In use"
        static let pickTitle = "Pick a pot"
        static let pickSub = "Changing pots is free."
        static let plusTag = "Plus"
        static let plusKeep = "A pot already on a plant stays on it."
        static let plusSettings = "A grown-up can find Plus in Settings."
        static let progressFirst = "Grow one plant to earn this pot."
        static let yours = "Yours to use"
        static let plusCard = "Part of WordFlora Plus"
        /// The Shed card's Plus line at accessibility sizes, where "WordFlora" would break mid-word on a narrow card.
        static let plusCardShort = "A Plus pot"
        static let shedTitle = "Pots"
        static let shedSub = "Tap a pot to see how to earn it"
        static let shedFooter = "Pots you earn stay yours. " + plusKeep
        static let freshSoil = "Repot with fresh soil"
        /// Shown once, the first time the picker or Shed opens after pots were newly recorded as earned.
        static let newPots = "New pots in your shed!"
        /// VoiceOver hints on pick tiles that are not chosen on tap.
        static let hintToEarn = "Shows how to earn it"
        static let hintPlus = "Shows where to find Plus"
        // The repot sheet v2 (design-preview/repot-sheet/notes.md).
        /// The one line under "Repot Daisy" in the sheet's header.
        static let repotSub = "Pick a pot. Changing pots is free."
        /// The tiny tag on a pot that is new on this opening (cleared with the "New pots" pill).
        static let newTag = "New"
        static let soilTitle = "Soil"
        static let soilSub = "Plants have favorite soils."
        static var all: [String] {
            [earned, current, pickTitle, pickSub, plusTag, plusKeep, plusSettings, progressFirst, yours, plusCard, plusCardShort,
             shedTitle, shedSub, shedFooter, freshSoil, newPots, hintToEarn, hintPlus, repotSub, newTag, soilTitle, soilSub]
        }
    }

    private static let words = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
    private static func word(_ n: Int) -> String { words.indices.contains(n) ? words[n] : "\(n)" }

    /// The short goal on a shed card ("Grow 25 plants", "Finish level 3", "Play on 7 days"); empty for plain blue and Plus pots.
    static func goalLine(_ pot: Pot) -> String {
        switch pot.unlock {
        case .plants(let n): return n == 1 ? "Grow one plant" : "Grow \(n) plants"
        case .level(let n): return "Finish level \(n)"
        case .gardenDays(let n): return "Play on \(n) days"
        case .free, .plus: return ""
        }
    }

    /// The progress under a shed card's bar ("12 of 25 plants grown", "6 of 10 plants in level 3", "3 of 7 garden days").
    static func progressLine(_ pot: Pot, stats: Stats) -> String {
        guard let p = progress(pot, stats: stats) else { return "" }
        switch pot.unlock {
        case .level(let n): return "\(p.now) of \(p.goal) plants in level \(n)"
        case .gardenDays: return "\(p.now) of \(p.goal) garden days"
        default: return "\(p.now) of \(p.goal) plants grown"
        }
    }

    /// The second line of the hint under the pick grid ("Four more plants to go!", "12 of 25 plants grown").
    static func tipLine(_ pot: Pot, stats: Stats) -> String {
        guard let p = progress(pot, stats: stats) else { return "" }
        switch pot.unlock {
        case .level:
            let k = p.goal - p.now
            if k <= 0 { return progressLine(pot, stats: stats) }
            return k == 1 ? "One more plant to go!" : "\(word(k)) more plants to go!"
        default:
            return p.goal == 1 && p.now == 0 ? Copy.progressFirst : progressLine(pot, stats: stats)
        }
    }

    /// The first line of the hint when a Plus pot is tapped.
    static func plusLine(_ pot: Pot) -> String { "\(pot.name) is part of WordFlora Plus." }

    /// The repot button names a new pot; with the pot in use it reads "Repot with fresh soil".
    static func repotTitle(picked: Pot, currentId: String) -> String {
        picked.id == pot(id: currentId).id ? Copy.freshSoil : "Repot into \(picked.name)"
    }

    /// The repot sheet's footer line: "Rose pink pot, fresh loam soil".
    static func summaryLine(pot: Pot, soil: SoilType) -> String { "\(pot.name) pot, fresh \(soil.rawValue) soil" }

    /// The footer hint when a pot that cannot be picked is tapped. To earn: "Finish level 3 to earn Living stones." and
    /// "Four more plants to go!". Plus: "Moonlit is part of WordFlora Plus." and where a grown-up finds Plus.
    static func hintLines(_ pot: Pot, state: PotState, stats: Stats) -> (title: String, detail: String) {
        switch state {
        case .plus: return (plusLine(pot), Copy.plusSettings)
        case .toEarn: return ("\(goalLine(pot)) to earn \(pot.name).", tipLine(pot, stats: stats))
        case .owned: return (Copy.earned, "")
        }
    }

    /// VoiceOver label for a pot tile: "Sage glaze pot, in use", "Starlight pot, not earned yet", "Moonlit pot, Plus".
    /// A pot new on this opening adds ", new" ("Rose pink pot, new").
    static func tileLabel(_ pot: Pot, state: PotState, inUse: Bool, isNew: Bool = false) -> String {
        let name = pot.voiceName
        let base: String
        if inUse { base = "\(name) pot, in use" } else {
            switch state {
            case .owned: base = "\(name) pot"
            case .toEarn: base = "\(name) pot, not earned yet"
            case .plus: base = "\(name) pot, Plus"
            }
        }
        return isNew ? base + ", new" : base
    }

    // MARK: Pattern geometry (pots.json `geometry.decorations`, 120 x 100 box)

    private static let sparkles: [(Double, Double, Double, Int)] = [(38, 46, 1.25, 0), (80, 52, 1.0, 0), (60, 74, 1.4, 0), (88, 76, 0.7, 1), (34, 72, 0.7, 1)]
    private static let dotSpots: [(Double, Double)] = [(34, 36), (56, 34), (78, 36), (96, 40), (44, 52), (66, 52), (86, 56), (38, 70), (58, 72), (78, 74), (50, 88), (70, 88)]
    private static let drips: [(Double, Double)] = [(26, 12), (40, 20), (54, 10), (68, 22), (82, 14), (94, 9)]
    // The six newer patterns (pots.json `proposal.newDecorations`).
    private static let blossomSpots: [(Double, Double, Double)] = [(40, 44, 1), (78, 40, 0.85), (62, 68, 1.15), (36, 76, 0.75), (86, 72, 0.8)]
    private static let stoneDomes: [(Double, Double, Double, Double)] = [(40, 72, 13, 11), (64, 64, 14, 12), (86, 76, 11, 9)]
    private static let sandSpecks: [(Double, Double)] = [(32, 40), (50, 34), (74, 38), (90, 46), (56, 46)]
    private static let barkBars: [(Double, Double, Double, Int)] = [
        (24, 20, 26, 0), (24, 50, 30, 2), (38, 28, 22, 1), (38, 54, 36, 3), (52, 20, 18, 2), (52, 42, 26, 0), (52, 72, 26, 1),
        (66, 24, 30, 3), (66, 58, 40, 2), (80, 20, 22, 1), (80, 46, 28, 0), (80, 78, 22, 3), (94, 30, 28, 2), (94, 62, 38, 1),
    ]
    private static let dropSpots: [(Double, Double, Double)] = [(38, 44, 1.1), (64, 36, 0.9), (86, 54, 1.2), (50, 70, 1.3), (76, 82, 0.9), (34, 66, 0.7)]
    private static let vineAnchors: [(Double, Double)] = [(30, 30), (52, 30), (74, 30), (94, 30), (41, 56), (63, 56), (85, 56)]

    static func marks(for kind: Pot.Decoration.Kind) -> [PotMark] {
        switch kind {
        case .none:
            return []
        case .rings:
            return [PotMark(shape: .rect(x: 18, y: 38, width: 84, height: 7)),
                    PotMark(shape: .rect(x: 18, y: 52, width: 84, height: 7), opacity: 0.7)]
        case .drip:
            return [PotMark(shape: .rect(x: 18, y: 20, width: 84, height: 10))]
                + drips.map { PotMark(shape: .capsule(x: $0.0 - 4, y: 26, width: 8, height: $0.1)) }
        case .flower:
            return (0..<8).map { PotMark(shape: .petal(cx: 60, cy: 58, distance: 10, rx: 4.5, ry: 9, degrees: Double($0) * 45)) }
                + [PotMark(shape: .circle(cx: 60, cy: 58, r: 7), color: 1)]
        case .stars:
            return sparkles.map { PotMark(shape: .sparkle(cx: $0.0, cy: $0.1, scale: $0.2), color: $0.3) }
        case .hearts:
            return [(40.0, 46.0, 1.1), (80, 46, 1.1), (60, 70, 1.5)].map { PotMark(shape: .heart(cx: $0.0, cy: $0.1, scale: $0.2)) }
        case .dots:
            return dotSpots.map { PotMark(shape: .circle(cx: $0.0, cy: $0.1, r: 4.5), opacity: 0.85) }
        case .stripes:
            return [22.0, 42, 62, 82, 102].map { PotMark(shape: .rect(x: $0 - 4.5, y: 20, width: 9, height: 80)) }
        case .moon:
            return [PotMark(shape: .crescent(cx: 56, cy: 56, r: 15, cutX: 63, cutY: 51, cutR: 13)),
                    PotMark(shape: .sparkle(cx: 84, cy: 42, scale: 0.55), color: 1),
                    PotMark(shape: .sparkle(cx: 82, cy: 78, scale: 0.55), color: 1),
                    PotMark(shape: .circle(cx: 36, cy: 40, r: 2), color: 1),
                    PotMark(shape: .circle(cx: 40, cy: 80, r: 2), color: 1)]
        case .flowerBand:
            var out = [PotMark(shape: .rect(x: 18, y: 70, width: 84, height: 30))]
            out += stride(from: 26.0, through: 98, by: 9).map { PotMark(shape: .circle(cx: $0, cy: 70, r: 5)) }
            for (i, x) in [32.0, 48, 64, 80, 94].enumerated() {
                let c = i.isMultiple(of: 2) ? 1 : 2
                for k in 0..<5 {
                    let a = Double(k) * 72 * .pi / 180
                    out.append(PotMark(shape: .circle(cx: x + 3.5 * sin(a), cy: 80 - 3.5 * cos(a), r: 3), color: c))
                }
                out.append(PotMark(shape: .circle(cx: x, cy: 80, r: 2), color: 3))
            }
            return out
        case .blossoms:
            return blossomSpots.flatMap { x, y, k in
                (0..<5).map { i -> PotMark in
                    let a = Double(i) * 72 * .pi / 180
                    return PotMark(shape: .circle(cx: x + 5 * k * sin(a), cy: y - 5 * k * cos(a), r: 4.6 * k))
                } + [PotMark(shape: .circle(cx: x, cy: y, r: 2.4 * k), color: 1, ghost: .fill)]
            }
        case .pebbles:
            return sandSpecks.map { PotMark(shape: .circle(cx: $0.0, cy: $0.1, r: 1.6), color: 1, opacity: 0.6) }
                + stoneDomes.flatMap { x, y, rx, ry in
                    [PotMark(shape: .petal(cx: x, cy: y, distance: 0, rx: rx, ry: ry, degrees: 0)),
                     PotMark(shape: .capsule(x: x - 1.3, y: y - ry, width: 2.6, height: (1.2 * ry * 10).rounded() / 10), color: 1, ghost: .fill)]
                }
        case .zigzag:
            var out = [PotMark(shape: .rect(x: 18, y: 20, width: 84, height: 6))]
            out += stride(from: 24.0, through: 96, by: 12).map { PotMark(shape: .triangle(x1: $0 - 6, y1: 26, x2: $0 + 6, y2: 26, x3: $0, y3: 38)) }
            out.append(PotMark(shape: .rect(x: 18, y: 86, width: 84, height: 14)))
            out += stride(from: 36.0, through: 84, by: 12).map { PotMark(shape: .triangle(x1: $0 - 6, y1: 86, x2: $0 + 6, y2: 86, x3: $0, y3: 74)) }
            out += stride(from: 24.0, through: 96, by: 12).map { PotMark(shape: .circle(cx: $0, cy: 40, r: 2.2), color: 1, ghost: .hidden) }
            return out
        case .vine:
            var out = [PotMark(shape: .rect(x: 18, y: 26, width: 84, height: 4), color: 1)]
            out += [41.0, 63, 85].map { PotMark(shape: .capsule(x: $0 - 1.5, y: 30, width: 3, height: 26), color: 1) }
            out += vineAnchors.flatMap { x, y in
                [155.0, 180, 205].map { PotMark(shape: .petal(cx: x, cy: y, distance: 11, rx: 3.2, ry: 7.5, degrees: $0)) }
            }
            return out
        case .bark:
            return barkBars.map { PotMark(shape: .capsule(x: $0.0 - 4.5, y: $0.1, width: 9, height: $0.2), color: $0.3) }
        case .drops:
            return dropSpots.map { PotMark(shape: .teardrop(cx: $0.0, cy: $0.1, scale: $0.2)) }
                + [(60.0, 54.0), (80, 70)].map { PotMark(shape: .sparkle(cx: $0.0, cy: $0.1, scale: 0.5), color: 1, ghost: .hidden) }
        }
    }
}

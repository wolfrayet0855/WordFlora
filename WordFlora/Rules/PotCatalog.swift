import Foundation

/// One cosmetic pot (design-preview/pots/pots.json, reviewed in design-preview/pots/review.md).
/// Colours are 0xRRGGBB. Every pot has its own pattern, so no two depend on hue alone.
struct Pot: Equatable, Hashable, Identifiable {
    enum Unlock: Equatable, Hashable {
        case free
        /// Plants grown (found plants in the collection) at least this many.
        case plants(Int)
        /// This many levels finished (all ten plants of a level found).
        case level(Int)
        case plus
    }

    struct Decoration: Equatable, Hashable {
        enum Kind: String, CaseIterable, Hashable { case none, rings, drip, flower, stars, hearts, dots, stripes, moon, flowerBand }
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
}

/// Where a pot stands for this player. Nothing here is stored: it is worked out from play each time.
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
    }
    var shape: Shape
    var color = 0
    var opacity = 1.0
}

/// The ten pots: plain blue to start, six earned by play and kept for good, three with WordFlora Plus.
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
            decoration: .init(kind: .drip, colors: [0xE2EFDE]), unlock: .plants(10),
            hint: "Grow 10 plants to earn this pot.", a11y: "Sage green pot with a drippy glaze"),
        Pot(id: "sunflower", name: "Sunflower", body: 0xF2C230, rim: 0xF8D95F, shade: 0xD9A514,
            decoration: .init(kind: .flower, colors: [0xE07F2A, 0x6B4528]), unlock: .level(3),
            hint: "Finish level 3 to earn this pot.", a11y: "Yellow pot with a big flower"),
        Pot(id: "starlight", name: "Starlight", body: 0x2F6670, rim: 0x5A98A2, shade: 0x224C54,
            decoration: .init(kind: .stars, colors: [0xFFE27A, 0xFFFFFF]), unlock: .level(5),
            hint: "Finish level 5 to earn this pot.", a11y: "Deep teal pot with twinkly stars"),
        Pot(id: "rosePink", name: "Rose pink", body: 0xE8869F, rim: 0xF2A9BC, shade: 0xCC6683,
            decoration: .init(kind: .hearts, colors: [0xFFE9EF]), unlock: .plants(25),
            hint: "Grow 25 plants to earn this pot.", a11y: "Pink pot with hearts"),
        Pot(id: "mint", name: "Mint", body: 0x7CCFA8, rim: 0xA8E5C8, shade: 0x5BB38A,
            decoration: .init(kind: .dots, colors: [0xFFFFFF]), unlock: .plants(50),
            hint: "Grow 50 plants to earn this pot.", a11y: "Mint green pot with white dots"),
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

    /// Empty (never chosen) and unknown ids are plain blue.
    static func pot(id: String) -> Pot { all.first { $0.id == id } ?? plainBlue }

    // MARK: Unlocks (computed from play, never stored)

    struct Stats: Equatable { var plantsGrown = 0; var levelsFinished = 0 }

    /// Plants grown = found plants; a level is finished when all ten of its plants are found (as the level badge counts).
    static func stats(plants: [PlantProgress]) -> Stats {
        let finished = (1...5).filter { lvl in
            let inLevel = plants.filter { $0.level == lvl }
            return inLevel.count == 10 && inLevel.allSatisfy(\.earned)
        }.count
        return Stats(plantsGrown: plants.filter(\.earned).count, levelsFinished: finished)
    }

    static func state(of pot: Pot, plantsGrown: Int, levelsFinished: Int, hasPlus: Bool) -> PotState {
        switch pot.unlock {
        case .free: return .owned
        case .plants(let n): return plantsGrown >= n ? .owned : .toEarn(hint: pot.hint)
        case .level(let n): return levelsFinished >= n ? .owned : .toEarn(hint: pot.hint)
        case .plus: return hasPlus ? .owned : .plus(hint: pot.hint)
        }
    }

    /// The pot already on the plant can always stay; any other pot must be owned now.
    static func canChoose(_ pot: Pot, currentId: String, plantsGrown: Int, levelsFinished: Int, hasPlus: Bool) -> Bool {
        if pot.id == self.pot(id: currentId).id { return true }
        return state(of: pot, plantsGrown: plantsGrown, levelsFinished: levelsFinished, hasPlus: hasPlus) == .owned
    }

    struct Progress: Equatable {
        var now: Int
        var goal: Int
        var fraction: Double { goal > 0 ? min(1, Double(now) / Double(goal)) : 1 }
    }

    /// How far along a pot to earn is; nil for plain blue and Plus pots.
    static func progress(_ pot: Pot, plantsGrown: Int, levelsFinished: Int) -> Progress? {
        switch pot.unlock {
        case .plants(let n): return Progress(now: min(plantsGrown, n), goal: n)
        case .level(let n): return Progress(now: min(levelsFinished, n), goal: n)
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
        static let shedTitle = "Pots"
        static let shedSub = "Tap a pot to see how to earn it"
        static let shedFooter = "Pots you earn stay yours. " + plusKeep
        static let freshSoil = "Repot with fresh soil"
        static var all: [String] {
            [earned, current, pickTitle, pickSub, plusTag, plusKeep, plusSettings, progressFirst, yours, plusCard,
             shedTitle, shedSub, shedFooter, freshSoil]
        }
    }

    private static let words = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
    private static func word(_ n: Int) -> String { words.indices.contains(n) ? words[n] : "\(n)" }

    /// The short goal on a shed card ("Grow 25 plants", "Finish level 3"); empty for plain blue and Plus pots.
    static func goalLine(_ pot: Pot) -> String {
        switch pot.unlock {
        case .plants(let n): return n == 1 ? "Grow one plant" : "Grow \(n) plants"
        case .level(let n): return "Finish level \(n)"
        case .free, .plus: return ""
        }
    }

    /// The progress under a shed card's bar ("12 of 25 plants grown", "3 of 5 levels finished").
    static func progressLine(_ pot: Pot, plantsGrown: Int, levelsFinished: Int) -> String {
        guard let p = progress(pot, plantsGrown: plantsGrown, levelsFinished: levelsFinished) else { return "" }
        if case .level = pot.unlock { return "\(p.now) of \(p.goal) levels finished" }
        return "\(p.now) of \(p.goal) plants grown"
    }

    /// The second line of the hint under the pick grid ("You finished level 3. Two more levels to go!").
    static func tipLine(_ pot: Pot, plantsGrown: Int, levelsFinished: Int) -> String {
        guard let p = progress(pot, plantsGrown: plantsGrown, levelsFinished: levelsFinished) else { return "" }
        switch pot.unlock {
        case .level:
            let k = p.goal - p.now
            let toGo = k == 1 ? "One more level to go!" : "\(word(k)) more levels to go!"
            return p.now > 0 ? "You finished level \(p.now). \(toGo)" : toGo
        default:
            return p.goal == 1 && p.now == 0 ? Copy.progressFirst : progressLine(pot, plantsGrown: plantsGrown, levelsFinished: levelsFinished)
        }
    }

    /// The first line of the hint when a Plus pot is tapped.
    static func plusLine(_ pot: Pot) -> String { "\(pot.name) is part of WordFlora Plus." }

    /// The repot button names a new pot; with the pot in use it reads "Repot with fresh soil".
    static func repotTitle(picked: Pot, currentId: String) -> String {
        picked.id == pot(id: currentId).id ? Copy.freshSoil : "Repot into \(picked.name)"
    }

    /// VoiceOver label for a pot tile: "Sage glaze pot, in use", "Starlight pot, not earned yet", "Moonlit pot, Plus".
    static func tileLabel(_ pot: Pot, state: PotState, inUse: Bool) -> String {
        if inUse { return "\(pot.name) pot, in use" }
        switch state {
        case .owned: return "\(pot.name) pot"
        case .toEarn: return "\(pot.name) pot, not earned yet"
        case .plus: return "\(pot.name) pot, Plus"
        }
    }

    // MARK: Pattern geometry (pots.json `geometry.decorations`, 120 x 100 box)

    private static let sparkles: [(Double, Double, Double, Int)] = [(38, 46, 1.25, 0), (80, 52, 1.0, 0), (60, 74, 1.4, 0), (88, 76, 0.7, 1), (34, 72, 0.7, 1)]
    private static let dotSpots: [(Double, Double)] = [(34, 36), (56, 34), (78, 36), (96, 40), (44, 52), (66, 52), (86, 56), (38, 70), (58, 72), (78, 74), (50, 88), (70, 88)]
    private static let drips: [(Double, Double)] = [(26, 12), (40, 20), (54, 10), (68, 22), (82, 14), (94, 9)]

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
        }
    }
}

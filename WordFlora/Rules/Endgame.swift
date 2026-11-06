import Foundation

/// Daily Bloom ranks: a total of Daily Blooms done (the `dailyBloomsDone` badge counter), never a run of days, so a
/// rank only goes up and a day off never lowers it. No leaderboard.
enum BloomRank: Int, CaseIterable, Comparable {
    case unranked, seedling, sprout, bud, bloom, fullBloom, evergreen

    var name: String {
        switch self {
        case .unranked: return ""
        case .seedling: return "Seedling"
        case .sprout: return "Sprout"
        case .bud: return "Bud"
        case .bloom: return "Bloom"
        case .fullBloom: return "Full bloom"
        case .evergreen: return "Evergreen"
        }
    }

    static func < (a: BloomRank, b: BloomRank) -> Bool { a.rawValue < b.rawValue }
}

/// The endgame (docs/pm/endgame-and-events-spec.md section 2). Everything is computed from earned values, like pot
/// unlocks: the Crown is shown, not owned, so it can never be taken away. Only the date a ceremony was seen is stored.
enum EndgamePolicy {
    /// Every plant in the catalog found (`earnedCount > 0`, the "plants grown" count PotCatalog uses), at any stage.
    static func allFound(_ plants: [PlantProgress], economy: Economy = .default) -> Bool {
        plants.count >= economy.plantsPerLevel * 5 && plants.allSatisfy(\.earned)
    }

    /// All five garden levels fully grown, on the earned stage (never a shown stage).
    static func allFullBloom(_ plants: [PlantProgress], economy: Economy = .default) -> Bool {
        plants.count >= economy.plantsPerLevel * 5 && (1...5).allSatisfy { ProgressionPolicy.gardenLevelComplete($0, plants: plants) }
    }

    /// The Grand Garden plays once per player on any device (`crownSeenAt` merges by min).
    static func shouldShowCeremony(allFound: Bool, seenAt: Date?) -> Bool { allFound && seenAt == nil }

    /// The gold crown moment plays once (`goldCrownSeenAt` merges by min).
    static func shouldShowGoldCrown(allFullBloom: Bool, seenAt: Date?) -> Bool { allFullBloom && seenAt == nil }

    /// Golden blooms: tending on a new day key adds one day; the same day (or a clock moved back) adds nothing.
    static func goldenDays(current: Int, lastKey: Int, careKey: Int) -> (days: Int, key: Int) {
        careKey > lastKey ? (max(0, current) + 1, careKey) : (current, lastKey)
    }

    /// Only tending (water, feed, sun or prune; not a hello) a full-bloom plant counts, once every plant is found.
    static func countsTowardGolden(allFound: Bool, stage: Int, isTending: Bool) -> Bool { allFound && stage >= 4 && isTending }

    static func isGolden(days: Int, economy: Economy = .default) -> Bool { days >= economy.goldenDaysNeeded }

    /// For "Daisy is 3 days from golden." (0 once golden).
    static func daysToGolden(days: Int, economy: Economy = .default) -> Int { max(0, economy.goldenDaysNeeded - days) }

    static func bloomRank(dailyBloomsDone: Int, economy: Economy = .default) -> BloomRank {
        let reached = economy.bloomRankThresholds.filter { dailyBloomsDone >= $0 }.count
        return BloomRank(rawValue: min(reached, BloomRank.allCases.count - 1)) ?? .unranked
    }

    /// Daily Blooms still to go to the next rank, or nil at the top rank.
    static func bloomsToNextRank(dailyBloomsDone: Int, economy: Economy = .default) -> Int? {
        economy.bloomRankThresholds.first { $0 > dailyBloomsDone }.map { $0 - max(0, dailyBloomsDone) }
    }

    // MARK: Ceremonies (G-2, G-3)

    enum Ceremony: String, Equatable { case grandGarden, goldCrown }

    /// The ceremony to play now, once each: the Grand Garden first, then the gold crown (never both in one go).
    static func nextCeremony(allFound: Bool, allFullBloom: Bool, crownSeenAt: Date?, goldCrownSeenAt: Date?) -> Ceremony? {
        if shouldShowCeremony(allFound: allFound, seenAt: crownSeenAt) { return .grandGarden }
        if crownSeenAt != nil, shouldShowGoldCrown(allFullBloom: allFullBloom, seenAt: goldCrownSeenAt) { return .goldCrown }
        return nil
    }

    /// The crown on the Home wordmark: computed from earned values every time, so it can never be taken away.
    enum Crown: Equatable { case none, green, gold }
    static func crown(allFound: Bool, allFullBloom: Bool) -> Crown { allFound ? (allFullBloom ? .gold : .green) : .none }

    // MARK: Golden blooms (G-4)

    struct GoldenCandidate: Equatable { var id: String; var name: String; var days: Int; var stage: Int }

    /// Home features one plant a day: the full-bloom plant nearest to golden (ties broken by a per-day order, so the
    /// pick is the same all day on every device). Nil before every plant is found or once every plant is golden.
    static func featuredGolden(_ plants: [GoldenCandidate], allFound: Bool, day: Int, economy: Economy = .default) -> GoldenCandidate? {
        guard allFound else { return nil }
        return plants.filter { $0.stage >= 4 && !isGolden(days: $0.days, economy: economy) }
            .min { a, b in
                (-a.days, WeatherEngine.orderKey(plantId: a.id, day: day), a.id) < (-b.days, WeatherEngine.orderKey(plantId: b.id, day: day), b.id)
            }
    }

    static func allGolden(_ days: [Int], economy: Economy = .default) -> Bool {
        !days.isEmpty && days.allSatisfy { isGolden(days: $0, economy: economy) }
    }

    // MARK: The Grand Garden picture

    /// Five terraced hills, back to front: level 5 at the back (8), then 9, 10, 11 and the first finds at the front (12).
    static let hillSizes = [8, 9, 10, 11, 12]

    /// The plants (sorted by level, then name) dealt onto the hills, back row first.
    static func hills<T>(_ sortedByLevel: [T]) -> [[T]] {
        var rest = Array(sortedByLevel.reversed())
        var rows: [[T]] = []
        for n in hillSizes {
            rows.append(Array(rest.prefix(n).reversed()))
            rest = Array(rest.dropFirst(n))
        }
        if !rest.isEmpty { rows[rows.count - 1] = Array(rest.reversed()) + rows[rows.count - 1] }
        return rows
    }

    /// How big a plant is drawn on the hills at its earned stage: Tiny 42%, Sprout 58%, Bud 78%, Full bloom 100%.
    static func hillScale(stage: Int) -> Double {
        switch stage {
        case ...1: return 0.42
        case 2: return 0.58
        case 3: return 0.78
        default: return 1.0
        }
    }
}

/// Every endgame line the UI will show, grade 2-3 and positive only (checked by CopySafety and the weather avoid list).
enum EndgameCopy {
    static let grandGardenTitle = "Your Grand Garden"
    static let grandGardenLine = "You found every plant in the garden!"
    static let crownTitle = "The Gardener's Crown"
    static let crownLine = "Here is your Gardener's Crown. It is yours to keep."
    static let goldCrownTitle = "A gold crown"
    static let goldCrownLine = "Your whole garden is in full bloom."
    static let goldCrownTurns = "Your crown turns gold!"
    static let whatsNextTitle = "What's next?"
    static let whatsNextGolden = "Care for a plant on 7 days, and it turns golden."
    static let whatsNextRanks = "Each Daily Bloom grows your bloom rank."
    static let whatsNextWeather = "Weather still comes to visit your garden."
    static let replay = "Watch it again"
    static let goldenTitle = "Golden blooms"
    static func goldenLine(name: String) -> String { "\(name) is golden!" }
    static func daysFromGolden(name: String, days: Int) -> String {
        days == 1 ? "\(name) is 1 day from golden." : "\(name) is \(days) days from golden."
    }
    static let allGolden = "Every plant is golden. What a garden!"
    static let rankTitle = "Bloom rank"
    static func rankLine(_ rank: BloomRank) -> String { "Your bloom rank: \(rank.name)" }
    static func rankNext(_ blooms: Int) -> String {
        blooms == 1 ? "1 more Daily Bloom to the next rank." : "\(blooms) more Daily Blooms to the next rank."
    }
    static let topRank = "You reached the top rank. Keep on blooming!"
    static let visitorsBook = "Visitors' book"

    // The Grand Garden ceremony (design-preview/endgame direction A, Revision 1)
    static let crownEarned = "You earned the Gardener's Crown"
    static let everyPlantFound = "Every plant found!"
    static let everyPlantLine = "You found all 50. What a garden! The crown is yours to keep."
    static let seeWhatsNext = "See what grows next"
    static let walkGarden = "Walk my garden"
    static let stillGrowing = "Still growing"
    static let fullBloom = "Full bloom"
    static let gardenPicture = "Your garden with all 50 plants"
    static let crownPicture = "The Gardener's Crown, a ring of leaves and flowers"
    static let goldCrownPicture = "The Gardener's Crown with gold flowers"
    static let lovely = "Lovely"
    static let crownOnWordmark = "You wear the Gardener's Crown"
    static let goldCrownOnWordmark = "You wear the gold Gardener's Crown"

    // What grows next
    static let whatGrowsNext = "What grows next"
    static let keepsGrowing = "Your garden keeps growing."
    static let goldenBlurb = "Care for a plant on 7 different days to make it golden."
    static func goldenProgress(name: String, days: Int, of goal: Int) -> String { "\(name) \(days) of \(goal)" }
    static let ranksBlurb = "Every Daily Bloom you play counts. Ranks go up, never down."
    static func youAre(_ rank: BloomRank) -> String { rank == .unranked ? "Play a Daily Bloom to start." : "You are a \(rank.name)." }
    static let bookBlurb = "A page for every visitor you meet, and your weather stickers."
    static let weatherTitle = "Garden weather"
    static let weatherBlurb = "Some days bring wind or frost. Your plants bounce back with care."
    static let staysWithYou = "Your crown and all your plants stay with you."
    static let backToGarden = "Back to my garden"

    // Golden blooms on Home and the plant page
    static let goldenNote = "Golden days come from water, food, sun or a trim."
    static func goldenPips(days: Int, of goal: Int) -> String { "\(days) of \(goal) golden days" }

    // The Visitors' book
    static let bookFriends = "Garden friends"
    static func bookFriendsCount(_ n: Int, of total: Int) -> String { "\(n) of \(total) friends in your book" }
    static let bookStickers = "Weather stickers"
    static func bookStickersCount(_ n: Int, of total: Int) -> String { "\(n) of \(total) weather stickers" }
    static let bookStickersHint = "Weather puzzles bring the next sticker."
    static let bookNotYet = "Not in your book yet"
    static func bookPage(_ name: String, met: Int) -> String { met == 1 ? "\(name), met once" : "\(name), met \(met) times" }
    static func stickerPage(_ name: String, owned: Bool) -> String { owned ? "\(name) sticker" : "\(name) sticker, not in your book yet" }
    static let rankTitleShort = "Your bloom rank"

    static func all(name: String) -> [String] {
        let ranks = BloomRank.allCases.dropFirst()
        return [grandGardenTitle, grandGardenLine, crownTitle, crownLine, goldCrownTitle, goldCrownLine, goldCrownTurns, whatsNextTitle,
                whatsNextGolden, whatsNextRanks, whatsNextWeather, replay, goldenTitle, goldenLine(name: name),
                daysFromGolden(name: name, days: 3), daysFromGolden(name: name, days: 1), allGolden, rankTitle, rankNext(1), rankNext(18),
                topRank, visitorsBook,
                crownEarned, everyPlantFound, everyPlantLine, seeWhatsNext, walkGarden, stillGrowing, fullBloom, gardenPicture,
                crownPicture, goldCrownPicture, lovely, crownOnWordmark, goldCrownOnWordmark, whatGrowsNext, keepsGrowing, goldenBlurb,
                goldenProgress(name: name, days: 4, of: 7), ranksBlurb, bookBlurb, weatherTitle, weatherBlurb, staysWithYou, backToGarden,
                goldenNote, goldenPips(days: 3, of: 7), bookFriends, bookFriendsCount(4, of: 12), bookStickers, bookStickersCount(2, of: 7),
                bookStickersHint, bookNotYet, bookPage(name, met: 1), bookPage(name, met: 3), stickerPage("Kite", owned: true),
                stickerPage("Kite", owned: false), rankTitleShort]
            + ranks.map(\.name) + ranks.map(rankLine) + BloomRank.allCases.map(youAre)
    }
}

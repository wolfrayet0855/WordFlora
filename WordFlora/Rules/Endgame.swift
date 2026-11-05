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

    static func all(name: String) -> [String] {
        let ranks = BloomRank.allCases.dropFirst()
        return [grandGardenTitle, grandGardenLine, crownTitle, crownLine, goldCrownTitle, goldCrownLine, goldCrownTurns, whatsNextTitle,
                whatsNextGolden, whatsNextRanks, whatsNextWeather, replay, goldenTitle, goldenLine(name: name),
                daysFromGolden(name: name, days: 3), daysFromGolden(name: name, days: 1), allGolden, rankTitle, rankNext(1), rankNext(18),
                topRank, visitorsBook]
            + ranks.map(\.name) + ranks.map(rankLine)
    }
}

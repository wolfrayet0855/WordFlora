import Foundation

/// What a badge counts. Every count lives in `PlayerProfile.badgesJSON` (max-merged by `BadgeState.merged`, carried by
/// `GardenBackup`), so a new counter needs no new stored field.
///
/// Extension point (for example the game's "Quick bloom" badge): add a case here (mark it in `isHighWater` if it is a
/// best-so-far value), add an entry to `Resources/Badges.json` with three ascending thresholds and CopySafety-clean
/// words, ship art `badge_<id>_t1...t3` (or register a drawn view in `BadgeArtView.drawn`), and record it where it
/// happens with `AppModel.recordBadgeStep(.yourCounter)`. Quiet Garden is handled inside `BadgeState.record`.
enum BadgeCounter: String, CaseIterable, Codable {
    case levelSets, plantsOwned, feeds, waterings, repots, prunes, streak
    case perfectBlooms, revives, dailyBloomsDone, visitorSpecies, butterflyPlays
    /// Weather puzzles solved (one step per solve that earned a reward). Accumulates; never goes down.
    case weathered
    /// Speed bloom words solved before the gold ring closed (opt-in, 13+). Accumulates; never goes down.
    case quickBlooms
    /// Pruning Pro: trims made while a faded bloom showed (`FadedBloom`). Accumulates; never goes down.
    case tidyTrims
    /// Gentle Net: hellos to a visitor resting on a flower. Accumulates; never goes down.
    case gentleHellos
    /// Lantern Keeper (Frost & Lantern, earned by play only): marks "grow.<plantId>.<stage>", one per growth stage a
    /// plant reaches while it sits in the Frosted glass pot (G5 adds season visitors). High-water mark count.
    case lanternKeeper
    /// The season's earned pot (Frosted glass): marks "in.<day>" / "out.<day>" for Daily Bloom days (`PackCatalog`).
    /// Feeds a pot, not a badge (`potOnly`).
    case seasonBlooms
    /// Mist Maker: real mists with the Mist button (`ToolEngine.mist`). Accumulates; never goes down.
    case mistSprays

    // Collection: worked out from the garden and the album each time (`BadgeFacts`), kept as best-so-far values.
    case rarePlants, desertPlants, waterPlants, treePlants, floweringPlants, stickers
    // Play
    case wordsSolved, steadySolves, levelReached, longWords, morningDays
    // Tending
    case fullBlooms, mists, suns, soilMatches, tendDays
    // Explorer
    case catches, duskCatches, rareSpecies, storiesRead, factsRead, beeCatches, shedUpgrades, badgeShares

    /// High-water counters only ever go up to the best value seen; the rest accumulate.
    var isHighWater: Bool {
        switch self {
        case .levelSets, .plantsOwned, .streak, .visitorSpecies,
             .rarePlants, .desertPlants, .waterPlants, .treePlants, .floweringPlants, .stickers,
             .levelReached, .fullBlooms, .soilMatches, .rareSpecies, .storiesRead, .factsRead, .shedUpgrades, .badgeShares,
             .lanternKeeper, .seasonBlooms:
            return true
        default: return false
        }
    }

    /// Counters still kept in the JSON (and still counted) that no badge reads any more. Their earned tiers stay: the
    /// badge that moved to a new counter keeps its `unlocked` dates, so its card shows the higher of the two.
    /// `prunes`: Pruning Pro moved to `tidyTrims`. `butterflyPlays`: Gentle Net moved to `gentleHellos`.
    /// `mists` (free drops while the mister was owned, no longer recorded): Mist Maker moved to `mistSprays`.
    static let retired: Set<BadgeCounter> = [.prunes, .butterflyPlays, .mists]
    /// Counters that track a pot's progress rather than a badge (kept in the JSON so they merge and back up).
    static let potOnly: Set<BadgeCounter> = [.seasonBlooms]
}

struct BadgeDef: Codable, Equatable, Identifiable {
    var id: String
    var family: String
    var counter: String
    var thresholds: [Int]
    var title: String?
    var blurb: String?
}

enum BadgeCatalog {
    static let knownCounters = Set(BadgeCounter.allCases.map(\.rawValue))
    enum CatalogError: Error { case fileNotFound }

    static func load(bundle: Bundle = .main) throws -> [BadgeDef] {
        guard let url = bundle.url(forResource: "Badges", withExtension: "json") else { throw CatalogError.fileNotFound }
        return try JSONDecoder().decode([BadgeDef].self, from: Data(contentsOf: url))
    }
}

struct BadgeUnlock: Equatable {
    var badgeId: String
    var tier: Int          // 1 bronze, 2 silver, 3 gold
    var at: Date
}

/// Positive-only badges: progress never decreases and nothing is ever revoked (spec section 14, 18).
struct BadgeState: Equatable {
    let defs: [BadgeDef]
    private(set) var progressByCounter: [String: Int] = [:]
    private(set) var unlocked: [String: Date] = [:]      // key "badgeId#tier"

    private struct Snapshot: Codable { var progress: [String: Int]; var unlocked: [String: Date] }

    init(defs: [BadgeDef]) { self.defs = defs }

    init(json: String, defs: [BadgeDef]) {
        self.defs = defs
        if let d = json.data(using: .utf8), let snap = try? JSONDecoder().decode(Snapshot.self, from: d) {
            progressByCounter = snap.progress; unlocked = snap.unlocked
        }
    }

    var json: String {
        (try? JSONEncoder().encode(Snapshot(progress: progressByCounter, unlocked: unlocked))).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    func progress(of c: BadgeCounter) -> Int { progressByCounter[c.rawValue] ?? 0 }
    func unlockedDate(badge: String, tier: Int) -> Date? { unlocked["\(badge)#\(tier)"] }

    /// Quiet Garden never advances badges, so it cannot become an exploit.
    @discardableResult
    mutating func record(_ counter: BadgeCounter, amount: Int = 1, value: Int? = nil, now: Date, quiet: Bool = false) -> [BadgeUnlock] {
        guard !quiet else { return [] }
        let current = progress(of: counter)
        let updated = counter.isHighWater ? max(current, value ?? (current + amount)) : current + amount
        progressByCounter[counter.rawValue] = updated

        var events = [BadgeUnlock]()
        for def in defs where def.counter == counter.rawValue {
            for (i, threshold) in def.thresholds.enumerated() where updated >= threshold {
                let key = "\(def.id)#\(i + 1)"
                if unlocked[key] == nil {
                    unlocked[key] = now
                    events.append(BadgeUnlock(badgeId: def.id, tier: i + 1, at: now))
                }
            }
        }
        return events
    }

    /// Counts one step for a new day only (days played in the morning, days with tending). `day` is a local day number
    /// (`BadgeFacts.dayNumber`). The last day counted is kept beside the counts under "day.<counter>", so it merges
    /// by max like them: two devices on the same day count it once.
    @discardableResult
    mutating func recordDay(_ counter: BadgeCounter, day: Int, now: Date, quiet: Bool = false) -> [BadgeUnlock] {
        guard !quiet else { return [] }
        let key = "day.\(counter.rawValue)"
        if let last = progressByCounter[key], day <= last { return [] }
        progressByCounter[key] = day
        return record(counter, now: now)
    }

    /// Counts a thing once, however often it happens again (a plant's story read, a badge card shared): the counter is
    /// how many different things are marked. Marks are kept as "mark.<counter>.<item>" beside the counts, so the
    /// max merge is a union and an older app that does not know them keeps them untouched.
    @discardableResult
    mutating func recordMark(_ counter: BadgeCounter, item: String, now: Date, quiet: Bool = false) -> [BadgeUnlock] {
        guard !quiet else { return [] }
        progressByCounter[Self.markKey(counter, item)] = 1
        return record(counter, value: marks(of: counter), now: now)
    }

    func isMarked(_ counter: BadgeCounter, item: String) -> Bool { progressByCounter[Self.markKey(counter, item)] != nil }
    func marks(of counter: BadgeCounter) -> Int { progressByCounter.keys.filter { $0.hasPrefix("mark.\(counter.rawValue).") }.count }
    /// Marks of one kind, by the start of their item ("in." counts the featured-season Daily Bloom days).
    func marks(of counter: BadgeCounter, itemPrefix: String) -> Int {
        progressByCounter.keys.filter { $0.hasPrefix("mark.\(counter.rawValue).\(itemPrefix)") }.count
    }
    private static func markKey(_ c: BadgeCounter, _ item: String) -> String { "mark.\(c.rawValue).\(item)" }

    /// The highest tier earned for a badge (0 when none yet).
    func tier(of badgeId: String) -> Int { (1...3).filter { unlockedDate(badge: badgeId, tier: $0) != nil }.max() ?? 0 }

    /// CloudKit-style merge: max progress, earliest unlock dates.
    func merged(with other: BadgeState) -> BadgeState {
        var m = self
        for (k, v) in other.progressByCounter { m.progressByCounter[k] = max(m.progressByCounter[k] ?? 0, v) }
        for (k, d) in other.unlocked { m.unlocked[k] = min(m.unlocked[k] ?? d, d) }
        return m
    }
}

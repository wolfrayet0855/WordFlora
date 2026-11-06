import Foundation

enum BadgeCounter: String, CaseIterable, Codable {
    case levelSets, plantsOwned, feeds, waterings, repots, prunes, streak
    case perfectBlooms, revives, dailyBloomsDone, visitorSpecies, butterflyPlays
    /// Weather puzzles solved (one step per solve that earned a reward). Accumulates; never goes down.
    case weathered

    /// High-water counters only ever go up to the best value seen; the rest accumulate.
    var isHighWater: Bool {
        switch self { case .levelSets, .plantsOwned, .streak, .visitorSpecies: return true; default: return false }
    }
}

struct BadgeDef: Codable, Equatable {
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

    /// CloudKit-style merge: max progress, earliest unlock dates.
    func merged(with other: BadgeState) -> BadgeState {
        var m = self
        for (k, v) in other.progressByCounter { m.progressByCounter[k] = max(m.progressByCounter[k] ?? 0, v) }
        for (k, d) in other.unlocked { m.unlocked[k] = min(m.unlocked[k] ?? d, d) }
        return m
    }
}

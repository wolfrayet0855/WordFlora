import Foundation

/// Picks the next word for a regular round (spec section 2, anti-repeat rules).
struct WordProvider {
    let bank: WordBank

    func next<G: RandomNumberGenerator>(level: Int, seen: [String], excluding: String?, using rng: inout G) -> WordEntry? {
        let seenSet = Set(seen)
        let recent = Set(seen.suffix(10))
        for lvl in stride(from: level, through: 1, by: -1) {
            let candidates = bank.entries.filter { $0.level == lvl && $0.id != excluding }
            if candidates.isEmpty { continue }
            let unseen = candidates.filter { !seenSet.contains($0.id) }
            if let pick = unseen.randomElement(using: &rng) { return pick }
            var pool = candidates.filter { !recent.contains($0.id) }
            if pool.isEmpty { pool = candidates }
            return pool.randomElement(using: &rng)
        }
        return nil
    }

    func entry(id: String) -> WordEntry? { bank.entries.first { $0.id == id } }
}

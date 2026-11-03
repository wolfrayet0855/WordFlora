/// Progressive unlock of systems (spec section 19, P-07). Nothing is teased while locked.
enum Feature: CaseIterable, Hashable {
    case play, garden, dailyBloom, sun, soil, rose, butterfly, shed, badges, glowLantern

    /// Baseline features exist from the first session and never get an unlock tip.
    var isBaseline: Bool { self == .play || self == .garden || self == .dailyBloom }
}

enum Tool: CaseIterable { case repot, prune, mist, lamp }

struct UnlockStats: Equatable {
    var plantsEarned = 0
    var sawTwoPetalsLeft = false
    var gardenDays = 0
    var wordLevelUps = 0
    var badgesEarned = 0
    var butterflyPlays = 0
}

enum FeatureUnlockPolicy {
    static func isUnlocked(_ f: Feature, stats s: UnlockStats, showEverything: Bool) -> Bool {
        if showEverything { return true }
        switch f {
        case .play, .garden, .dailyBloom: return true
        case .sun: return s.plantsEarned >= 3
        case .soil: return s.plantsEarned >= 5
        case .rose: return s.sawTwoPetalsLeft
        case .butterfly: return s.wordLevelUps >= 1 || s.gardenDays >= 3
        case .shed: return s.wordLevelUps >= 2
        case .badges: return s.badgesEarned >= 1
        case .glowLantern: return s.butterflyPlays >= 1
        }
    }

    /// One tool per garden-level milestone, in a fixed order.
    static func unlockedTools(gardenMilestones n: Int) -> [Tool] {
        Array(Tool.allCases.prefix(max(0, min(n, Tool.allCases.count))))
    }

    /// Features that unlocked since last asked; each is returned exactly once (for one TipKit tip each).
    static func newlyUnlocked(stats: UnlockStats, alreadySeen seen: inout Set<Feature>, showEverything: Bool) -> [Feature] {
        var out = [Feature]()
        for f in Feature.allCases where !f.isBaseline && isUnlocked(f, stats: stats, showEverything: showEverything) {
            if seen.insert(f).inserted { out.append(f) }
        }
        return out
    }
}

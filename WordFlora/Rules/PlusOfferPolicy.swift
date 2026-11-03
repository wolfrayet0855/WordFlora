import Foundation

/// A single, gentle Home card about WordFlora Plus (spec sections 13, 18). Shown only to free players who are
/// not young, only after something nice happened, never near an ad or a rest, and rarely.
enum PlusOfferPolicy {
    enum Milestone: String, CaseIterable, Codable { case firstLevelUp, tenPlants, twentyFivePlants }

    struct Context {
        var now: Date
        var ageBand: AgeBand?
        var hasPlus = false
        var entitlementsLoaded = true
        var quietGarden = false
        var adShownThisSession = false
        var lastRoundWasRest = false
        var currentLevel = 1
        var plantsEarned = 0
        var offered: Set<Milestone> = []
        var lastOfferAt: Date?

        init(now: Date) { self.now = now }
    }

    static let minGap: TimeInterval = 30 * 86_400

    static func reached(currentLevel: Int, plantsEarned: Int) -> [Milestone] {
        var m = [Milestone]()
        if currentLevel >= 2 { m.append(.firstLevelUp) }
        if plantsEarned >= 10 { m.append(.tenPlants) }
        if plantsEarned >= 25 { m.append(.twentyFivePlants) }
        return m
    }

    /// The milestone to celebrate with the card, or nil when it should stay hidden.
    static func milestoneToOffer(_ c: Context) -> Milestone? {
        guard let age = c.ageBand, age != .under13 else { return nil }          // unknown age is treated as young
        guard c.entitlementsLoaded, !c.hasPlus else { return nil }
        guard !c.quietGarden, !c.adShownThisSession, !c.lastRoundWasRest else { return nil }
        if let last = c.lastOfferAt, c.now.timeIntervalSince(last) < minGap { return nil }
        return reached(currentLevel: c.currentLevel, plantsEarned: c.plantsEarned).last { !c.offered.contains($0) }
    }

    /// Truthful: the garden is already kept on the phone; Plus adds syncing across devices.
    enum Copy {
        static let headline = "Keep your garden safe and in sync on all your devices"
        static let detail = "Your garden is already saved on this phone. WordFlora Plus adds iCloud syncing across your devices, with no ads."
        static let button = "Learn more"
    }
}

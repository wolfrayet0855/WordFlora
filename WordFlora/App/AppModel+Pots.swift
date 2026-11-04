import Foundation

/// The pot collection (T-D). Unlocks are computed from play every time (found plants, finished levels, Plus),
/// so nothing new is stored on the profile and nothing earned can be taken away.
extension AppModel {
    var potStats: PotCatalog.Stats {
        PotCatalog.stats(plants: plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) })
    }

    var hasPlusForPots: Bool { entitlements.state.hasPlus }

    func potState(_ pot: Pot, stats: PotCatalog.Stats? = nil) -> PotState {
        let s = stats ?? potStats
        return PotCatalog.state(of: pot, plantsGrown: s.plantsGrown, levelsFinished: s.levelsFinished, hasPlus: hasPlusForPots)
    }

    func canChoose(_ pot: Pot, for plant: PlantCollectible, stats: PotCatalog.Stats? = nil) -> Bool {
        let s = stats ?? potStats
        return PotCatalog.canChoose(pot, currentId: plant.potId, plantsGrown: s.plantsGrown, levelsFinished: s.levelsFinished, hasPlus: hasPlusForPots)
    }

    /// Puts the plant in `pot` (part of a repot; changing pots costs nothing). A Plus pot needs Plus to be chosen,
    /// but the pot already on the plant always stays. A change counts as tending, so iCloud keeps the latest pick.
    @discardableResult
    func choosePot(_ pot: Pot, for plant: PlantCollectible) -> Bool {
        guard canChoose(pot, for: plant) else { return false }
        guard plant.potId != pot.id else { return true }
        plant.potId = pot.id
        plant.lastTendedAt = max(plant.lastTendedAt ?? .distantPast, Date.now)
        try? context.save()
        return true
    }

    /// Found plants sitting in `pot` (an empty choice is plain blue).
    func plantsUsing(_ pot: Pot) -> [PlantCollectible] {
        plants().filter { $0.earnedCount > 0 && PotCatalog.pot(id: $0.potId).id == pot.id }
    }
}

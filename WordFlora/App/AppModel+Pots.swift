import Foundation

/// The pot collection (T-D, docs/pm/pot-earning-review.md). Unlocks are worked out from play (found plants, finished
/// levels, Garden Days, Plus), and every pot earned by play is also recorded in `PlayerProfile.earnedPotIds`, which
/// only ever grows, so a restored older backup or a moved goal never takes a pot away.
extension AppModel {
    var potStats: PotCatalog.Stats {
        PotCatalog.stats(plants: plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) },
                         gardenDays: profile?.gardenDays ?? 0, earnedPotIds: profile?.earnedPotIds ?? [])
    }

    var hasPlusForPots: Bool { entitlements.state.hasPlus }

    func potState(_ pot: Pot, stats: PotCatalog.Stats? = nil) -> PotState {
        PotCatalog.state(of: pot, stats: stats ?? potStats, hasPlus: hasPlusForPots)
    }

    func canChoose(_ pot: Pot, for plant: PlantCollectible, stats: PotCatalog.Stats? = nil) -> Bool {
        PotCatalog.canChoose(pot, currentId: plant.potId, stats: stats ?? potStats, hasPlus: hasPlusForPots)
    }

    /// Adds every pot earned by play now to the stored record (called when the pot picker or the Shed opens).
    /// Returns the newly recorded ids in catalog order (empty when nothing was new), so that one opening can say
    /// "New pots in your shed!" and tag those pots "New". Plus pots are never recorded.
    @discardableResult
    func recordEarnedPots() -> [String] {
        guard let profile else { return [] }
        let before = Set(profile.earnedPotIds)
        let merged = PotCatalog.recordEarned(profile.earnedPotIds, stats: potStats)
        let added = Set(merged).subtracting(before)
        guard !added.isEmpty else { return [] }
        profile.earnedPotIds = merged
        try? context.save()
        return PotCatalog.all.map(\.id).filter(added.contains)
    }

    /// Puts the plant in `pot` (part of a repot; changing pots costs nothing). A Plus pot needs Plus to be chosen,
    /// but the pot already on the plant always stays. The pick is stamped on `potChosenAt` so iCloud keeps the latest one;
    /// it is not tending, so the plant's thirsty look and the widget's hero stay as they were.
    @discardableResult
    func choosePot(_ pot: Pot, for plant: PlantCollectible) -> Bool {
        guard canChoose(pot, for: plant) else { return false }
        guard plant.potId != pot.id else { return true }
        plant.potId = pot.id
        plant.potChosenAt = max(plant.potChosenAt, Date.now)
        try? context.save()
        return true
    }

    /// Found plants sitting in `pot` (an empty choice is plain blue).
    func plantsUsing(_ pot: Pot) -> [PlantCollectible] {
        plants().filter { $0.earnedCount > 0 && PotCatalog.pot(id: $0.potId).id == pot.id }
    }
}

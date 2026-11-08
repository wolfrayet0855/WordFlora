import Foundation

/// The pot collection (T-D, docs/pm/pot-earning-review.md). Unlocks are worked out from play (found plants, finished
/// levels, Garden Days, Plus), and every pot earned by play is also recorded in `PlayerProfile.earnedPotIds`, which
/// only ever grows, so a restored older backup or a moved goal never takes a pot away.
extension AppModel {
    var potStats: PotCatalog.Stats {
        var s = PotCatalog.stats(plants: plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) },
                                 gardenDays: profile?.gardenDays ?? 0, earnedPotIds: profile?.earnedPotIds ?? [])
        s.ownedPacks = entitlements.state.ownedPacks
        s.seasonHalfDays = PackCatalog.seasonHalfDays(featuredDays: badges.marks(of: .seasonBlooms, itemPrefix: "in."),
                                                      otherDays: badges.marks(of: .seasonBlooms, itemPrefix: "out."))
        return s
    }

    // MARK: Seasonal packs (PackCatalog)

    /// The pack pots to show in the pick grid and the Shed: every pot of a live pack (offered or owned), plus a pack
    /// pot already on this plant (it stays, even with the pack gone from the store). Empty while the store has no pack.
    func visiblePackPots(currentId: String? = nil) -> [Pot] {
        PotCatalog.packPots.filter { pot in
            if pot.id == currentId { return true }
            guard let pack = PackCatalog.pack(ofPot: pot.id) else { return false }
            return entitlements.packIsLive(pack.id)
        }
    }

    /// A pack's badge shows on the Badges page while the pack is live or once a tier is earned.
    func showsPackBadge(_ badgeId: String) -> Bool {
        guard let pack = PackCatalog.all.first(where: { $0.badgeId == badgeId }) else { return true }
        return entitlements.packIsLive(pack.id) || badges.tier(of: badgeId) > 0
    }

    /// A Daily Bloom done: one mark toward the season's earned pot while its pack is live (a whole day in season,
    /// half a day otherwise). Quiet Garden counts nothing, like every badge counter.
    func recordSeasonBloom(into state: inout BadgeState, on date: Date, quiet: Bool) -> [BadgeUnlock] {
        var unlocks = [BadgeUnlock]()
        for pack in PackCatalog.all where pack.earnedPotId != nil && entitlements.packIsLive(pack.id) {
            let item = PackCatalog.bloomMarkItem(day: BadgeFacts.dayNumber(date, calendar: .current),
                                                 featured: PackCatalog.isFeatured(pack, on: date))
            unlocks += state.recordMark(.seasonBlooms, item: item, now: date, quiet: quiet)
        }
        return unlocks
    }

    /// Lantern Keeper: a plant in the Frosted glass pot reached a new stage (each plant and stage once).
    static func recordLanternKeeperGrowth(_ plant: PlantCollectible, into state: inout BadgeState, on date: Date, quiet: Bool) -> [BadgeUnlock] {
        guard plant.potId == PotCatalog.frostedGlass.id else { return [] }
        return state.recordMark(.lanternKeeper, item: "grow.\(plant.plantId).\(plant.stage)", now: date, quiet: quiet)
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

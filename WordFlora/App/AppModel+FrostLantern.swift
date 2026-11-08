import Foundation
import SwiftData

/// The full Frost & Lantern pack in the app (G5): the glasshouse plants' rows, the winter friends in the butterfly game
/// and the scene behind Home and Garden. Ownership is read from StoreKit every time; nothing new is stored.
extension AppModel {
    var ownedPacks: Set<String> { entitlements.state.ownedPacks }

    /// The snowy lantern scene shows behind Home and Garden (owners only; also in Calm and Quiet Garden).
    var showsWinterScene: Bool { FrostLanternScene.shows(ownedPacks: ownedPacks) }

    /// The winter friends who may come to this player's butterfly game (none without the pack).
    var seasonFriendPool: [String] { VisitorCatalog.seasonPool(ownedPacks: ownedPacks) }

    /// Any plant row by id, ladder or glasshouse (the plant page).
    func plantRow(_ plantId: String) -> PlantCollectible? { allPlantRows().first { $0.plantId == plantId } }

    /// The glasshouse plants to show, in catalogue order: owned packs only. A row kept from a lapsed pack stays hidden.
    func glasshouseRows(from all: [PlantCollectible]? = nil) -> [PlantCollectible] {
        let shown = GlasshouseCatalog.shown(ownedPacks: ownedPacks)
        let rows = all ?? allPlantRows()
        return shown.compactMap { g in rows.first { $0.plantId == g.id } }
    }

    /// Gives an owner the glasshouse plants that have no row yet: found (so they can be tended), at the first stage,
    /// growing by care only. Uses the existing fields; a second device's row merges by `plantId` (DataReconciler).
    /// Returns the plants added.
    @discardableResult
    func syncGlasshouse() -> [String] {
        let existing = Set(allPlantRows().map(\.plantId))
        let missing = GlasshouseCatalog.missing(ownedPacks: ownedPacks, existingIds: existing)
        guard !missing.isEmpty else { return [] }
        for g in missing {
            let row = PlantCollectible(name: g.name, botanicalName: g.botanicalName, botanicalFact: g.fact,
                                       level: GlasshouseCatalog.level, imageName: g.imageName, plantId: g.id)
            row.earnedCount = 1
            row.lastLovedAt = now()
            context.insert(row)
        }
        try? context.save()
        return missing.map(\.id)
    }

    /// Lantern Keeper: one mark per winter friend met per day ("hello.<id>.<day>"), so the badge grows with play.
    static func recordLanternKeeperHellos(_ caught: [String], into state: inout BadgeState, on date: Date, quiet: Bool,
                                          calendar: Calendar = .current) -> [BadgeUnlock] {
        let day = BadgeFacts.dayNumber(date, calendar: calendar)
        var unlocks = [BadgeUnlock]()
        for id in Set(caught).sorted() where VisitorCatalog.isSeason(id) {
            unlocks += state.recordMark(.lanternKeeper, item: "hello.\(id).\(day)", now: date, quiet: quiet)
        }
        return unlocks
    }
}

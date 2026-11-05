import Foundation
import SwiftData

/// Logic shared by the app and the home-screen widget, so both run exactly the same rules (spec section 4).
enum WidgetActions {
    /// Spec section 18 (P15): the thirsty look never appears in widgets or notifications.
    static let widgetShowsThirstyLook = false

    struct PlantSnapshot: Equatable {
        var plantId: String
        var name: String
        var imageName: String
        var stage: Int
        var thirsty: Bool
        var growthFraction: Double
    }

    struct GardenSnapshot: Equatable {
        var hero: PlantSnapshot?
        var others: [PlantSnapshot]
        var water: Int
    }

    @MainActor
    static func snapshot(context: ModelContext, now: Date, calm: Bool) -> GardenSnapshot {
        let profile = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first
        let earned = ((try? context.fetch(FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.level), SortDescriptor(\.name)]))) ?? [])
            .filter { $0.earnedCount > 0 }
        guard !earned.isEmpty else { return GardenSnapshot(hero: nil, others: [], water: profile?.water ?? 0) }

        let hero: PlantCollectible
        if let pin = profile?.widgetPlantID, let pinned = earned.first(where: { $0.plantId == pin }) {
            hero = pinned
        } else {
            // The plant that has waited longest for a drink (never-tended plants count as freshly watered).
            hero = earned.min { ($0.lastTendedAt ?? .distantFuture) < ($1.lastTendedAt ?? .distantFuture) } ?? earned[0]
        }
        func snap(_ p: PlantCollectible) -> PlantSnapshot {
            let eco = Economy.default
            let cost = eco.levelBaseCost * eco.levelCostMultipliers[max(0, min(4, p.level - 1))]
            return PlantSnapshot(plantId: p.plantId, name: p.nickname.isEmpty ? p.name : p.nickname, imageName: p.imageName, stage: p.stage,
                                 thirsty: TendingEngine.isThirsty(p, now: now, calm: calm), growthFraction: min(1, Double(p.growthPoints) / cost))
        }
        let others = earned.filter { $0.plantId != hero.plantId }.prefix(2).map(snap)
        return GardenSnapshot(hero: snap(hero), others: Array(others), water: profile?.water ?? 0)
    }

    /// The widget's water button. Free drops are credited first, then one drop is spent. Safe to call repeatedly.
    @MainActor
    @discardableResult
    static func water(plantId: String, context: ModelContext, now: Date, calendar: Calendar, quiet: Bool) -> TendResult {
        guard let profile = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first,
              let plant = (try? context.fetch(FetchDescriptor<PlantCollectible>()))?.first(where: { $0.plantId == plantId && $0.earnedCount > 0 })
        else { return .blocked(.noWater) }
        let eco = Economy.default
        ToolEngine.applyTrickle(profile, inventory: ToolInventory(json: profile.toolsJSON), now: now, economy: eco)
        let result = TendingEngine.water(plant, profile: profile, now: now, calendar: calendar, economy: eco, quiet: quiet)
        try? context.save()
        return result
    }

    /// One calm sentence for Siri and Control Center: waters the garden's hero plant using the very same rules as the widget.
    @MainActor
    static func waterGarden(context: ModelContext, now: Date, calendar: Calendar, quiet: Bool) -> String {
        guard let hero = snapshot(context: context, now: now, calm: true).hero else {
            return "Play a word to find your first plant, then come back to water it."
        }
        let result = water(plantId: hero.plantId, context: context, now: now, calendar: calendar, quiet: quiet)
        if result.applied { return "\(hero.name) had a drink and is growing nicely." }
        switch result.reason {
        case .noWater: return TendCopy.canDry
        case .doneForToday: return TendCopy.done(.water, name: hero.name)
        default: return "Your garden is ready when you are."
        }
    }
}

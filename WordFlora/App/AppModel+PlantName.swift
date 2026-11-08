import Foundation
import WidgetKit

/// Make it yours: naming a plant (existing `PlantCollectible.nickname`) and pinning one to the Home Screen widget
/// (existing `PlayerProfile.widgetPlantID`, which `WidgetActions.snapshot` already prefers). No new stored field.
extension AppModel {
    /// Saves a typed name through `PlantName.clean` ("" goes back to the species name). Returns what was saved.
    @discardableResult
    func rename(_ plant: PlantCollectible, to typed: String) -> String {
        let name = PlantName.clean(typed)
        plant.nickname = name
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return name
    }

    func isOnWidget(_ plant: PlantCollectible) -> Bool { profile?.widgetPlantID == plant.plantId }

    /// Puts this plant on the widget: the pin syncs with the garden and the widget redraws at once.
    func pinToWidget(_ plant: PlantCollectible) {
        guard let profile else { return }
        profile.widgetPlantID = plant.plantId
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Whether a WordFlora widget is on the Home Screen (no permission needed). Unknown counts as yes, so the line
    /// never asks to add a widget that may already be there.
    func hasGardenWidget() async -> Bool {
        guard let widgets = try? await WidgetCenter.shared.currentConfigurations() else { return true }
        return !widgets.isEmpty
    }
}

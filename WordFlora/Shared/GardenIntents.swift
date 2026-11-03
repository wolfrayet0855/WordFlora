import AppIntents
import SwiftData
import WidgetKit

/// Set by the app so Siri and Shortcuts use the app's own store while the app is running (no second container).
@MainActor
enum GardenIntentHost { static var container: ModelContainer? }

/// Water the garden from Siri, Shortcuts or Control Center. Same store and rules as the widget button;
/// no ads or consent screens ever appear inside an intent.
struct WaterGardenIntent: AppIntent {
    static var title: LocalizedStringResource = "Water my garden"
    static var description = IntentDescription("Gives your garden a drink.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = GardenIntentHost.container ?? (try? SharedContainer.make(role: .appExtension)) else {
            return .result(dialog: IntentDialog(stringLiteral: GardenFallback.intentLine))
        }
        let line = WidgetActions.waterGarden(context: container.mainContext, now: .now, calendar: .current, quiet: SharedDefaults.quietGarden)
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: IntentDialog(stringLiteral: line))
    }
}

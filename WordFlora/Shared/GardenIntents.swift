import AppIntents
import SwiftData

/// Water the garden from Siri, Shortcuts or Control Center. Same store and rules as the widget button;
/// no ads or consent screens ever appear inside an intent.
struct WaterGardenIntent: AppIntent {
    static var title: LocalizedStringResource = "Water my garden"
    static var description = IntentDescription("Gives your garden a drink.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = try? SharedContainer.make(createIfMissing: false) else {
            return .result(dialog: "Open WordFlora once to start your garden.")
        }
        let line = WidgetActions.waterGarden(context: container.mainContext, now: .now, calendar: .current, quiet: SharedDefaults.quietGarden)
        return .result(dialog: IntentDialog(stringLiteral: line))
    }
}

/// Opens the app (to Home, where today's Daily Bloom is the main card).
struct OpenGardenIntent: AppIntent {
    static var title: LocalizedStringResource = "Open my garden"
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult { .result() }
}

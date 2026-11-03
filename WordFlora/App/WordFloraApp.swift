import SwiftUI
import SwiftData

@main
struct WordFloraApp: App {
    @State private var app: AppModel
    @State private var router = GameRouter()

    init() {
        let args = CommandLine.arguments
        let uiTesting = args.contains("-uitest")

        let container: ModelContainer
        if uiTesting {
            container = try! SharedContainer.make(inMemory: true)
        } else {
            do { container = try SharedContainer.make() }
            catch {
                // Never crash on a bad store: fall back to an in-memory container so the app still opens.
                container = try! SharedContainer.make(inMemory: true)
            }
        }

        var settings = AppSettings()
        var bank: WordBank? = nil
        if uiTesting {
            // Deterministic launches for UI tests: fresh settings, optional fixed word.
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "beta.WordFlora")
            settings = AppSettings()
            if args.contains("-uitest-onboarded") { settings.onboardingComplete = true; settings.ageBand = .eighteenPlus }
            if let w = args.first(where: { $0.hasPrefix("-uitest-word=") })?.dropFirst("-uitest-word=".count) {
                let entry = WordEntry(id: "ui-\(w)", word: String(w).uppercased(), display: String(w).capitalized, hint: "A test hint", hint2: "Second clue",
                                      fact: "A test fact.", level: 1, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: true,
                                      source: "test", license: "test", reviewedBy: "ui")
                bank = WordBank(schemaVersion: 1, bankVersion: "ui", entries: [entry], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
            }
        }
        let model = AppModel(container: container, settings: settings, bank: bank, storeEnabled: !uiTesting)
        if uiTesting && args.contains("-uitest-gardened") {
            // A garden with one found plant and some supplies, for tending UI tests.
            model.plants().first?.earnedCount = 1
            model.profile?.water = 5; model.profile?.soil = 3
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-plus") {
            model.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        }
        _app = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(router)
                .modelContainer(app.container)
        }
    }
}

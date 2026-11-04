import SwiftUI
import SwiftData
import WidgetKit
import TipKit

@main
struct WordFloraApp: App {
    @State private var app: AppModel
    @State private var router = GameRouter()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let args = CommandLine.arguments
        let uiTesting = args.contains("-uitest")

        let wantsCloud = !uiTesting && SharedDefaults.store.bool(forKey: "cloudSyncEnabled")
        var openedWithCloud = false
        let container: ModelContainer
        var degraded = false
        if uiTesting {
            container = try! SharedContainer.make(inMemory: true)
        } else if wantsCloud, let synced = try? SharedContainer.make(cloudSync: true) {
            container = synced; openedWithCloud = true
        } else if let local = try? SharedContainer.make() {
            container = local          // free players, a lapsed subscription, or no usable iCloud account
        } else {
            // Never crash on a bad store: fall back to an in-memory container so the app still opens.
            container = try! SharedContainer.make(inMemory: true); degraded = true
        }

        var settings = AppSettings()
        var bank: WordBank? = nil
        if uiTesting {
            // Deterministic launches for UI tests: fresh settings, optional fixed word.
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "beta.WordFlora")
            UserDefaults(suiteName: SharedDefaults.groupID)?.removePersistentDomain(forName: SharedDefaults.groupID)
            settings = AppSettings()
            if args.contains("-uitest-onboarded") { settings.onboardingComplete = true; settings.ageBand = .eighteenPlus }
            if let w = args.first(where: { $0.hasPrefix("-uitest-word=") })?.dropFirst("-uitest-word=".count) {
                let entry = WordEntry(id: "ui-\(w)", word: String(w).uppercased(), display: String(w).capitalized, hint: "A test hint", hint2: "Second clue",
                                      fact: "A test fact.", level: 1, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: true,
                                      source: "test", license: "test", reviewedBy: "ui")
                bank = WordBank(schemaVersion: 1, bankVersion: "ui", entries: [entry], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
            }
        }
        let model = AppModel(container: container, settings: settings, bank: bank, storeEnabled: !uiTesting, launchedWithCloud: openedWithCloud, storeDegraded: degraded)
        if uiTesting && args.contains("-uitest-gardened") {
            // A garden with one found plant and some supplies, for tending UI tests.
            model.plants().first?.earnedCount = 1
            model.profile?.water = 5; model.profile?.soil = 3
            try? model.context.save()
        }
        if uiTesting, let id = args.first(where: { $0.hasPrefix("-uitest-plant=") })?.dropFirst("-uitest-plant=".count) {
            // One named plant found, with supplies, for the plant page tests (fact card, tending).
            model.plants().first { $0.plantId == String(id) }?.earnedCount = 1
            model.profile?.water = 5; model.profile?.soil = 3
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-seed") {
            // One found plant that has rested long enough to be a seed, for the wake flow UI test.
            if let p = model.plants().first { p.earnedCount = 1; p.lastLovedAt = Date.now.addingTimeInterval(-6 * 86_400) }
            try? model.context.save()
        }
        if uiTesting, let n = args.first(where: { $0.hasPrefix("-uitest-rain=") }).flatMap({ Double($0.dropFirst("-uitest-rain=".count)) }) {
            // One found plant that has gone n days without love (rain, falling petals; 5 or more is a seed), for the plant page tests.
            if let p = model.plants().first { p.earnedCount = 1; p.lastLovedAt = Date.now.addingTimeInterval(-(n * 86_400 + 3_600)) }
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-plus") {
            model.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        }
        if uiTesting && args.contains("-uitest-everything") { model.settings.showEverything = true; model.syncToolUnlocks() }
        if uiTesting && !args.contains("-uitest-ads") { model.adsEnabled = false }
        if uiTesting { model.plusOfferEnabled = false }
        if !uiTesting { try? Tips.configure([.displayFrequency(.daily)]) }
        _app = State(initialValue: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(router)
                .modelContainer(app.container)
                .onOpenURL { url in if app.onboarding.isComplete { router.open(url) } }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { app.reconcileSyncedData(); app.checkWelcomeBack() }
                    // Keep the home-screen widget in step with what the player just did.
                    if phase == .background || phase == .inactive { WidgetCenter.shared.reloadAllTimelines(); app.refreshReminders() }
                    if phase == .active { app.refreshFreeDrops(); app.updateAmbience(); app.updateSyncFlag() }
                    if phase == .background { SoundPlayer.shared.stopAmbient() }
                }
        }
    }
}

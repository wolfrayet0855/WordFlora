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
                // `-uitest-word-level=N` gives the fixed word a level (Speed bloom applies to levels 4 and 5).
                let wordLevel = args.first(where: { $0.hasPrefix("-uitest-word-level=") }).flatMap { Int($0.dropFirst("-uitest-word-level=".count)) } ?? 1
                let entry = WordEntry(id: "ui-\(w)", word: String(w).uppercased(), display: String(w).capitalized, hint: "A test hint", hint2: "Second clue",
                                      fact: "A test fact.", level: wordLevel, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: true,
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
        if uiTesting && args.contains("-uitest-life-changed") {
            // Every plant "last seen" in another state, so the next plant page visit opens the Life panel by itself.
            for p in model.plants() { p.lifeSeenKey = "earlier"; p.lifeSeenAt = .now }
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-pots") {
            // A pot collection part way up the ladder: levels 1 and 2 finished, 6 plants in level 3, 3 Garden Days.
            var inLevel = [Int: Int]()
            for p in model.plants().sorted(by: { $0.plantId < $1.plantId }) {
                let goal = p.level <= 2 ? 10 : (p.level == 3 ? 6 : 0)
                if inLevel[p.level, default: 0] < goal { p.earnedCount = 1; inLevel[p.level, default: 0] += 1 }
            }
            model.profile?.gardenDays = 3; model.profile?.water = 5; model.profile?.soil = 3
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-allfound") {
            // Every plant found; levels 1-3 all in full bloom, a few more in levels 4 and 5 (the Garden Path "all found" state).
            var bloomed = [Int: Int]()
            for p in model.plants().sorted(by: { $0.plantId < $1.plantId }) {
                p.earnedCount = 1
                let goal = p.level <= 3 ? 10 : (p.level == 4 ? 6 : 2)
                if bloomed[p.level, default: 0] < goal { p.stage = 4; bloomed[p.level, default: 0] += 1 }
            }
            try? model.context.save()
        }
        // Weather helpers, the weather puzzle and the Grand Garden (EndgameUITestFixtures lists the flags).
        if uiTesting { EndgameUITestFixtures.apply(args: args, to: model) }
        if uiTesting && args.contains("-uitest-plus") {
            model.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        }
        // The Plus page with the local StoreKit file's prices, whatever the simulator's store returns.
        if uiTesting && args.contains("-uitest-prices") { model.entitlements.debugPreviewPrices(UITestPrices.local) }
        // Plus Forever owned, alone or beside a subscription that is still renewing (the "charged twice" note).
        if uiTesting && args.contains("-uitest-plus-forever") {
            model.entitlements.debugForce(EntitlementState(activeProductIDs: [PlusPlan.lifetimeID]))
        }
        if uiTesting && args.contains("-uitest-plus-twice") {
            model.entitlements.debugForce(EntitlementState(activeProductIDs: [PlusPlan.lifetimeID, "plus_yearly"]))
        }
        // The grown-ups' Family Sharing note was shown two days ago (so not again this week).
        if uiTesting && args.contains("-uitest-family-note-seen") {
            model.settings.familyNudgeShownAt = Date.now.addingTimeInterval(-2 * 86_400)
        }
        // Plus Forever beside a subscription whose auto-renew is already off (it ends in 20 days): the end-date line.
        if uiTesting && args.contains("-uitest-plus-ending") {
            model.entitlements.debugForce(EntitlementState(activeProductIDs: [PlusPlan.lifetimeID, "plus_yearly"],
                                                           subscriptionRenews: false,
                                                           subscriptionEndsAt: Date.now.addingTimeInterval(20 * 86_400)))
        }
        if uiTesting && args.contains("-uitest-everything") { model.settings.showEverything = true; model.syncToolUnlocks() }
        // Visitors and Shed tests: a few friends in the album, shed points, Calm mode or Quiet Garden.
        if uiTesting && args.contains("-uitest-album") {
            var album = StickerAlbum()
            album.add(["monarch", "monarch", "ladybug", "honeybee"], on: Date.now)
            model.profile?.albumJSON = album.json
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-fieldnotes") {
            // Field Notes: four friends met (monarch twice); three pages already stamped, so stamping the monarch's
            // page earns the bronze badge. The book opens from Visitors.
            var album = StickerAlbum()
            album.add(["monarch", "monarch", "ladybug", "honeybee", "luna"], on: Date.now)
            model.profile?.albumJSON = album.json
            try? model.context.save()
            for id in ["ladybug", "honeybee", "luna"] { model.collectFieldNote(id) }      // three of four: no tier yet
        }
        if uiTesting && args.contains("-uitest-tidytrim") {
            // Pruning Pro: the found plant (`-uitest-plant=`, or the first) in flower, the shears owned, every day a
            // faded bloom day, and four tidy trims already, so the next one earns the bronze badge.
            if let p = model.plants().first(where: { $0.earnedCount > 0 }) ?? model.plants().first {
                p.earnedCount = 1; p.stage = BadgeFacts.floweringStage; p.lastPrunedAt = nil
            }
            var inv = model.inventory; inv.unlock(.shears); model.inventory = inv
            model.profile?.water = 5; model.profile?.soil = 3
            model.fadedBloomTestOverride = true
            model.updateBadges(announce: false) { state, _, t in state.record(.tidyTrims, amount: 4, now: t) }
            try? model.context.save()
        }
        if uiTesting, let n = args.first(where: { $0.hasPrefix("-uitest-points=") }).flatMap({ Int($0.dropFirst("-uitest-points=".count)) }) {
            model.profile?.shedPoints = n
            try? model.context.save()
        }
        if uiTesting && args.contains("-uitest-calm") { model.settings.calmMode = true }
        if uiTesting && args.contains("-uitest-celebrate=badge") {
            // A badge moment on Home that stays until tapped (BadgeMomentHost), for its UI test and audit.
            model.enqueueBadgeMoments([BadgeUnlock(badgeId: "perfect_bloom", tier: 1, at: .now)])
        }
        if uiTesting && args.contains("-uitest-quiet") { model.settings.quietGarden = true }
        // The daily quest card: off in UI tests unless asked for; `-uitest-quest=<kind>` picks today's kind.
        if uiTesting {
            model.questHiddenForUITests = !args.contains { $0.hasPrefix("-uitest-quest") }
            model.questTestOverride = args.first { $0.hasPrefix("-uitest-quest=") }
                .flatMap { QuestKind(rawValue: String($0.dropFirst("-uitest-quest=".count))) }
        }
        // Garden weather tests: an age answer, the daily reminder on (no permission prompt), and a forecast or a weather
        // day in place of the schedule. The gate is opened as if 5 plants and 2 tends had happened; Calm, Quiet Garden
        // and the Garden weather switch still apply.
        if uiTesting, let a = args.first(where: { $0.hasPrefix("-uitest-age=") }).flatMap({ AgeBand(rawValue: String($0.dropFirst("-uitest-age=".count))) }) {
            model.settings.applyAgeDefaults(a)
        }
        // Speed bloom: the toggle on (Extra time with `-uitest-speedbloom-extra`), levels 1-3 found so the word level is 4,
        // and `-uitest-speedbloom-seconds=N` for a short ring. The age, Calm and Quiet Garden flags still gate it.
        if uiTesting && args.contains("-uitest-speedbloom") {
            model.settings.speedBloomOn = true
            model.settings.speedBloomExtraTime = args.contains("-uitest-speedbloom-extra")
            for p in model.plants() where p.level <= 3 { p.earnedCount = 1 }
            model.game.refreshLevel()
            try? model.context.save()
        }
        if uiTesting, let n = args.first(where: { $0.hasPrefix("-uitest-speedbloom-seconds=") }).flatMap({ Double($0.dropFirst("-uitest-speedbloom-seconds=".count)) }) {
            model.game.speedBloomBudgetOverride = n
        }
        if uiTesting && args.contains("-uitest-remind") { model.settings.remindMe = true; model.reminders.restore() }
        let forecastArg = args.first(where: { $0.hasPrefix("-uitest-forecast=") }).flatMap { WeatherKind(rawValue: String($0.dropFirst("-uitest-forecast=".count))) }
        let weatherArg = args.first(where: { $0.hasPrefix("-uitest-weather=") }).flatMap { WeatherKind(rawValue: String($0.dropFirst("-uitest-weather=".count))) }
        if uiTesting && (forecastArg != nil || weatherArg != nil) {
            model.weatherTestOverride = GardenWeather.Override(forecast: forecastArg, event: weatherArg)
            model.profile?.weatherGatedFromDay = model.weatherToday
            try? model.context.save()
        }
        // The in-app Reduce Motion switch and a fixed theme, for the guide's still and dark screenshots.
        if uiTesting && args.contains("-uitest-reduce-motion") { model.settings.reduceMotionOverride = true }
        // Butterfly net: Easier butterflies on, a 6 s round (so a test reaches the summary), a fixed seed, and Gentle Net
        // with nine gentle hellos already (the next earns the bronze badge).
        if uiTesting && args.contains("-uitest-easier-butterflies") { model.settings.easierButterflies = true }
        if uiTesting && args.contains("-uitest-butterfly-short") { model.butterflyRoundOverride = 6 }
        if uiTesting, let n = args.first(where: { $0.hasPrefix("-uitest-butterfly-seed=") }).flatMap({ UInt64($0.dropFirst("-uitest-butterfly-seed=".count)) }) {
            model.butterflySeedOverride = n
        }
        if uiTesting && args.contains("-uitest-gentlenet") {
            model.updateBadges(announce: false) { state, _, t in state.record(.gentleHellos, amount: 9, now: t) }
        }
        if uiTesting && args.contains("-uitest-dark") { model.settings.appearance = .dark }
        if uiTesting, let n = args.first(where: { $0.hasPrefix("-uitest-sessions=") }).flatMap({ Int($0.dropFirst("-uitest-sessions=".count)) }) {
            model.settings.completedSessions = n            // past the first sessions, so the ad rules can say yes
        }
        // `-uitest-ads-offline`: ad rules stay live but the ad SDK never starts (no consent prompt, no real ad).
        if uiTesting && args.contains("-uitest-ads-offline") { model.ads.offline = true }
        if uiTesting && args.contains("-uitest-daytime") { model.uiTestDaytime = true }
        if uiTesting && !args.contains("-uitest-ads") && !args.contains("-uitest-ads-offline") { model.adsEnabled = false }
        if uiTesting { model.plusOfferEnabled = false }
        if uiTesting && args.contains("-uitest-badges") {
            // Badges page tests: a gold, a silver and a bronze badge already earned (no moments).
            model.updateBadges(announce: false) { state, _, t in
                state.record(.waterings, amount: 300, now: t) + state.record(.feeds, amount: 75, now: t) + state.record(.suns, amount: 10, now: t)
            }
        }
        // Badges the fixtures above already earned arrive quietly, as they do for a real garden at launch.
        if uiTesting { model.refreshBadgeFacts(announce: false) }
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
                    if phase == .active { app.refreshFreeDrops(); app.updateAmbience(); app.updateSyncFlag(); app.refreshQuestFromGarden() }
                    if phase == .background { SoundPlayer.shared.stopAmbient() }
                }
        }
    }
}

/// `-uitest-prices`: the prices in `Config/WordFlora.storekit` (StoreKitConfigTests checks they match). UI tests launch
/// the app outside the StoreKit test environment, where the store may return no products or only some.
enum UITestPrices {
    static let local: [PlusChoice: Decimal] = [.yearly: Decimal(string: "12.99")!, .monthly: Decimal(string: "3.99")!,
                                               .lifetime: Decimal(string: "34.99")!]
}
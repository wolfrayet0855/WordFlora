import SwiftUI
import SwiftData

/// Composition root: owns the store, settings, the round view model and first-session flow.
@Observable
@MainActor
final class AppModel {
    let container: ModelContainer
    let settings: AppSettings
    let game: GameViewModel
    let bank: WordBank
    var onboarding: OnboardingFlow
    private(set) var badges = BadgeState(defs: [])
    let entitlements: EntitlementService
    private let now: () -> Date

    var context: ModelContext { container.mainContext }

    init(container: ModelContainer, settings: AppSettings = AppSettings(), bank: WordBank? = nil, now: @escaping () -> Date = { .now }, storeEnabled: Bool = false) {
        self.now = now
        self.entitlements = EntitlementService(startListening: storeEnabled)
        self.container = container
        self.settings = settings
        let loaded = bank ?? (try? WordBank.load()) ?? WordBank(schemaVersion: 1, bankVersion: "empty", entries: [],
                                                            daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        self.bank = loaded
        self.game = GameViewModel(modelContext: container.mainContext, bank: loaded)
        self.onboarding = OnboardingFlow(restoredComplete: settings.onboardingComplete, ageBand: settings.ageBand)
        game.soundEnabled = settings.soundOn
        game.seedPlantsIfNeeded()
        game.refreshLevel()
        if settings.onboardingComplete { settings.completedSessions += 1 }
        let defs = (try? BadgeCatalog.load()) ?? []
        badges = BadgeState(json: game.playerProfile?.badgesJSON ?? "", defs: defs)
        refreshFreeDrops()
    }

    // MARK: Data

    func plants() -> [PlantCollectible] {
        let d = FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.level), SortDescriptor(\.name)])
        return (try? context.fetch(d)) ?? []
    }

    var profile: PlayerProfile? { game.playerProfile }

    var unlockStats: UnlockStats {
        let p = profile
        var s = UnlockStats()
        s.plantsEarned = plants().filter { $0.earnedCount > 0 }.count
        s.gardenDays = p?.gardenDays ?? 0
        s.wordLevelUps = max(0, (p?.currentLevel ?? 1) - 1)
        s.sawTwoPetalsLeft = (p?.roseSeedProgress ?? 0) > 0 || (p?.roseOfJerichoCount ?? 0) > 0 || game.petalsRemaining <= 2
        return s
    }

    func isUnlocked(_ f: Feature) -> Bool {
        FeatureUnlockPolicy.isUnlocked(f, stats: unlockStats, showEverything: settings.showEverything)
    }

    // MARK: Onboarding

    func finishOnboarding() {
        settings.onboardingComplete = true
        onboarding.skip()
    }

    // MARK: Tools and tending

    var inventory: ToolInventory {
        get { ToolInventory(json: profile?.toolsJSON ?? "") }
        set { profile?.toolsJSON = newValue.json; try? context.save() }
    }

    enum TendAction: Equatable { case water, feed, sun, prune, repot(SoilType) }

    struct TendOutcome: Equatable {
        var applied: Bool
        var stageUp = false
        var message: String
    }

    func refreshFreeDrops() {
        guard let p = profile else { return }
        TendingEngine.applyTrickle(p, now: now(), economy: .default)
        try? context.save()
    }

    func tend(_ action: TendAction, plant: PlantCollectible) -> TendOutcome {
        guard let p = profile else { return TendOutcome(applied: false, message: "Something went wrong. Try again.") }
        let quiet = settings.quietGarden
        let date = now(), cal = Calendar.current, eco = Economy.default
        let inv = inventory
        var result = TendResult()
        var repotOutcome: RepotResult.Outcome?

        switch action {
        case .water: result = ToolEngine.waterWithCan([plant], profile: p, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet).first ?? .blocked(.noWater)
        case .feed: result = ToolEngine.addSoil(plant, profile: p, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet)
        case .sun: result = ToolEngine.sunWithLamp(plant, profile: p, inventory: lampOrBasic(inv), now: date, calendar: cal, economy: eco, quiet: quiet)
        case .prune: result = ToolEngine.prune(plant, inventory: inv, now: date, calendar: cal, economy: eco, quiet: quiet)
        case .repot(let soil):
            let r = ToolEngine.repot(plant, to: soil, profile: p, now: date, calendar: cal, economy: eco, quiet: quiet)
            result = r.applied ? TendResult(applied: true, gpGained: r.tend.gpGained, stageUp: r.tend.stageUp) : .blocked(.noSoil)
            repotOutcome = r.outcome
        }

        guard result.applied else { return TendOutcome(applied: false, message: Self.message(for: result.reason, plant: plant)) }

        let counter: BadgeCounter? = { switch action { case .water: return .waterings; case .feed: return .feeds; case .prune: return .prunes; case .repot: return .repots; case .sun: return nil } }()
        if let counter { badges.record(counter, now: date, quiet: quiet); p.badgesJSON = badges.json }
        try? context.save()

        let name = plant.nickname.isEmpty ? plant.name : plant.nickname
        if result.stageUp { return TendOutcome(applied: true, stageUp: true, message: "\(name) grew a little!") }
        if repotOutcome == .happy { return TendOutcome(applied: true, message: "\(name) loves its new pot!") }
        if repotOutcome == .neutral { return TendOutcome(applied: true, message: "Repotted.") }
        return TendOutcome(applied: true, message: quiet ? "Lovely." : "+\(result.gpGained) growth")
    }

    /// The sun tap is free for everyone; owning the lamp only makes it stronger.
    private func lampOrBasic(_ inv: ToolInventory) -> ToolInventory {
        var i = inv; i.unlock(.lamp); return i
    }

    private static func message(for reason: TendResult.Reason?, plant: PlantCollectible) -> String {
        switch reason {
        case .noWater: return "No drops left. Win a word to earn more."
        case .noSoil: return "No soil scoops left. Finding new plants earns more."
        case .fullForToday: return "\(plant.name) has had enough for today. Come back tomorrow!"
        case .alreadyDoneToday: return "\(plant.name) already soaked up the sun today."
        case .notOwned: return "You need the shears first."
        case .cooldown: return "Pruned recently. Give it a couple of days."
        case nil: return "Not right now."
        }
    }
}

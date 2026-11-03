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

    var context: ModelContext { container.mainContext }

    init(container: ModelContainer, settings: AppSettings = AppSettings(), bank: WordBank? = nil) {
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
}

import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if app.onboarding.isComplete { mainStack(router: $router.path) } else { OnboardingView() }
        }
        // The badge moment and the return cue are modal while they show: what they cover is hidden from VoiceOver.
        .accessibilityHidden(app.shownBadge != nil || app.adFormats.cue != .hidden)
        .overlay {
            if let level = Self.uiTestCelebrate {
                // UI tests: one still frame of a burst over the screen, for the accessibility audit.
                PetalConfettiView(level: level, origin: .fromTop(260), seed: 3, freezeAt: level.duration * 0.35)
                    .ignoresSafeArea().accessibilityIdentifier("petalConfetti")
            }
        }
        .overlay { BadgeMomentHost() }
        .safeAreaInset(edge: .top) {
            if app.storeDegraded {
                Text(AppModel.degradedStoreMessage)
                    .font(Theme.font(.footnote, weight: .semibold)).multilineTextAlignment(.center)
                    .padding(10).frame(maxWidth: .infinity).background(Color.appBackground.opacity(0.95))
                    .accessibilityIdentifier("degraded-store-banner")
            }
        }
        .overlay { AppOpenCueHost() }                        // G4b: the return cue covers everything while it is up
        .tint(Color.successText)
    }

    /// `-uitest-celebrate=<level>` (small, medium, large, calm, reduceMotion) draws that burst over the app.
    private static let uiTestCelebrate: CelebrationLevel? = ProcessInfo.processInfo.arguments
        .first { $0.hasPrefix("-uitest-celebrate=") }
        .flatMap { CelebrationLevel(rawValue: String($0.dropFirst("-uitest-celebrate=".count))) }
        .flatMap { $0 == .badge || $0 == .intro ? nil : $0 }

    private func mainStack(router path: Binding<[GameRoute]>) -> some View {
        NavigationStack(path: path) {
            HomeView()
                // The stack's pages need it themselves (GameView does too). The return cue is modal too: what it
                // covers on Home is hidden from VoiceOver while it is up.
                .accessibilityHidden(app.shownBadge != nil || app.adFormats.cue != .hidden)
                .navigationDestination(for: GameRoute.self) { route in
                    switch route {
                    case .garden: GardenView()
                    case .game(let daily, let level): GameView(daily: daily, level: level)
                    case .plant(let id): PlantDetailView(plantId: id)
                    case .butterfly: ButterflyView()
                    case .visitors: VisitorsView()
                    case .shed: ShedView()
                    case .badges: BadgesView()
                    case .plus: PlusView()
                    case .seasons: SeasonsView()
                    case .settings: SettingsView()
                    case .levelMap: LevelMapView()
                    case .visitorsBook: VisitorsBookView()
                    default: ComingSoonView(title: String(describing: route))
                    }
                }
        }
        // No ad of any kind while the Plus or Seasons page is the current screen (Plus flow review, AdBlock.paywall).
        .onChange(of: path.wrappedValue, initial: true) { _, p in app.adOnPaywall = p.last == .plus || p.last == .seasons }
    }
}

/// Temporary placeholder while the remaining screens are built.
struct ComingSoonView: View {
    let title: String
    var body: some View {
        VStack(spacing: 12) {
            FlowerView(petals: 8).frame(height: 140)
            Text("Coming soon").font(Theme.font(.title3, weight: .bold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

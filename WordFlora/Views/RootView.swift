import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        Group {
            if app.onboarding.isComplete { mainStack(router: $router.path) } else { OnboardingView() }
        }
        .tint(Color.appSuccess)
        .preferredColorScheme(app.settings.colorScheme)
    }

    private func mainStack(router path: Binding<[GameRoute]>) -> some View {
        NavigationStack(path: path) {
            HomeView()
                .navigationDestination(for: GameRoute.self) { route in
                    switch route {
                    case .garden: GardenView()
                    case .game(let daily, let level): GameView(daily: daily, level: level)
                    case .plant(let id): PlantDetailView(plantId: id)
                    case .plus: PlusView()
                    case .settings: SettingsView()
                    case .levelMap: LevelMapView()
                    default: ComingSoonView(title: String(describing: route))
                    }
                }
        }
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

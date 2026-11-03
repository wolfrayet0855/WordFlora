import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: GameRoute.self) { route in
                    switch route {
                    case .garden: GardenView()
                    case .game(let daily): GameView(daily: daily)
                    default: ComingSoonView(title: String(describing: route))
                    }
                }
        }
        .tint(Color.appSuccess)
        .preferredColorScheme(app.settings.colorScheme)
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

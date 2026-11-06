import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Query(sort: [SortDescriptor(\PlantCollectible.level), SortDescriptor(\PlantCollectible.name)]) private var plants: [PlantCollectible]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
    private let levelNames = ["Seedling", "Sprout", "Bloom", "Grove", "Ancient"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(plants.filter { $0.earnedCount > 0 }.count) of \(plants.count) plants found")
                    .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                ForEach(1...5, id: \.self) { level in
                    let inLevel = plants.filter { $0.level == level }
                    if !inLevel.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Level \(level) · \(levelNames[level - 1])")
                                .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(inLevel) { plant in
                                    Button { if plant.earnedCount > 0 { router.go(.plant(plant.plantId)) } } label: { PlantCard(plant: plant) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if app.showBanner && app.ads.started { AdBannerView().frame(height: 60).frame(maxWidth: .infinity).background(Color.appBackground) }
        }
        .task { await app.prepareBannerIfAllowed() }
        .onAppear { app.markWeatherSeen() }      // witnessed first: opening the garden on a weather day starts its look
        .navigationTitle("My Garden")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Query(sort: [SortDescriptor(\PlantCollectible.level), SortDescriptor(\PlantCollectible.name)]) private var plants: [PlantCollectible]

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
                            // Two columns in a Grid (not a lazy grid), so both cards in a row share the row's height.
                            Grid(horizontalSpacing: Space.m, verticalSpacing: Space.m) {
                                ForEach(Array(stride(from: 0, to: inLevel.count, by: 2)), id: \.self) { i in
                                    GridRow {
                                        tile(inLevel[i])
                                        if i + 1 < inLevel.count { tile(inLevel[i + 1]) } else { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card)
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

    private func tile(_ plant: PlantCollectible) -> some View {
        Button { if plant.earnedCount > 0 { router.go(.plant(plant.plantId)) } } label: {
            PlantCard(plant: plant, fillsHeight: true)
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: [SortDescriptor(\PlantCollectible.level), SortDescriptor(\PlantCollectible.name)]) private var plants: [PlantCollectible]

    private let levelNames = ["Seedling", "Sprout", "Bloom", "Grove", "Ancient"]
    /// B4: the banner's real anchored adaptive height, reported by the created banner (never a fixed 60 pt).
    @State private var bannerHeight: CGFloat = 50

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                waterCard
                Text("\(plants.filter { $0.earnedCount > 0 }.count) of \(plants.count) plants found")
                    .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                ForEach(1...5, id: \.self) { level in
                    let inLevel = plants.filter { $0.level == level }
                    if !inLevel.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Level \(level) · \(levelNames[level - 1])")
                                .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                            // A Grid (not a lazy grid), so the cards in a row share the row's height. Two columns,
                            // one at the accessibility sizes so every name keeps whole words (GridColumns).
                            let columns = GridColumns.count(.garden, for: typeSize)
                            Grid(horizontalSpacing: GridColumns.spacing(.garden), verticalSpacing: Space.m) {
                                ForEach(Array(GridColumns.rows(inLevel, .garden, for: typeSize).enumerated()), id: \.offset) { _, row in
                                    GridRow {
                                        ForEach(row) { tile($0) }
                                        ForEach(0..<(columns - row.count), id: \.self) { _ in Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
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
            if app.showBanner && app.decide(.banner(.garden)).isYes && app.ads.started {
                AdBannerView(unit: .bannerGarden, height: $bannerHeight)
                    .frame(height: bannerHeight).frame(maxWidth: .infinity).background(Color.appBackground)
            }
        }
        .task { await app.prepareBannerIfAllowed() }
        .onAppear { app.markWeatherSeen() }      // witnessed first: opening the garden on a weather day starts its look
        .navigationTitle("My Garden")
        .navigationBarTitleDisplayMode(.inline)
        .rewardToast($toast)
    }

    @State private var toast: String?
    @State private var watching = false

    /// R1: the can is dry and the perk applies (never in Quiet Garden). A video row for 13 and over without Plus, the
    /// rain barrel (free) for Plus, under 13 and an unknown age; the plant page's water button shares the same cap.
    @ViewBuilder private var waterCard: some View {
        let path = app.perkPath(.water)
        if path != .hidden {
            Card {
                VStack(alignment: .leading, spacing: Space.m) {
                    Text(AdPerkCopy.Water.dryCan)
                        .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    RewardedPromptRow.forPath(path, adTitle: AdPerkCopy.Water.adTitle, freeTitle: AdPerkCopy.Water.freeTitle,
                                              hasPlus: app.entitlements.state.hasPlus, identifier: "garden.waterPerk") {
                        guard !watching else { return }
                        watching = true
                        Task {
                            if await app.watchRewarded(.water) { toast = AdPerkCopy.Water.toast }
                            watching = false
                        }
                    }
                    .disabled(watching)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("garden.waterCard")
        }
    }

    private func tile(_ plant: PlantCollectible) -> some View {
        Button { if plant.earnedCount > 0 { router.go(.plant(plant.plantId)) } } label: {
            PlantCard(plant: plant, fillsHeight: true, fadedBloom: plant.earnedCount > 0 && app.showsFadedBloom(plant))
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: [SortDescriptor(\PlantCollectible.level), SortDescriptor(\PlantCollectible.name)]) private var rows: [PlantCollectible]
    /// The 50 ladder plants; the glasshouse plants (Frost & Lantern) have their own shelf below the levels.
    private var plants: [PlantCollectible] { GlasshouseCatalog.ladder(rows, id: \.plantId) }

    private let levelNames = ["Seedling", "Sprout", "Bloom", "Grove", "Ancient"]
    /// B4: the banner's real anchored adaptive height, reported by the created banner (never a fixed 60 pt).
    @State private var bannerHeight: CGFloat = AdBannerView.slotHeight

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                waterCard
                Text("\(plants.filter { $0.earnedCount > 0 }.count) of \(plants.count) plants found")
                    .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    .sceneScrim()
                ForEach(1...5, id: \.self) { level in
                    let inLevel = plants.filter { $0.level == level }
                    if !inLevel.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Level \(level) · \(levelNames[level - 1])")
                                .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                                .sceneScrim()
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
                GlasshouseSection(rows: app.glasshouseRows(from: rows)) { router.go(.plant($0)) }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card)
        }
        .frostLanternBackground(app.showsWinterScene)
        .safeAreaInset(edge: .bottom) { GardenBannerSlot(height: $bannerHeight) }     // G4b: collapsible first, then plain
        .task { await app.prepareBannerIfAllowed() }
        .onAppear { app.markWeatherSeen(); app.syncGlasshouse() }      // witnessed first: opening the garden on a weather day starts its look
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
                                              hasPlus: app.entitlements.state.hasPlus, identifier: "garden.waterPerk", busy: watching) {
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

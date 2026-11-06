import SwiftUI

/// The Garden Shed (design-preview/shed-visitors/shed-v2, direction B): the shed scene with the points bar,
/// a grid of tool tiles that open a tool sheet, then the pots. Quiet Garden shows no points, prices or upgrades.
struct ShedView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var selected: ShedToolPick?
    @State private var justUpgraded: (tool: ToolID, tier: Int)?

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }

    var body: some View {
        let inv = app.inventory
        let points = app.profile?.shedPoints ?? 0
        let quiet = !ShedPolicy.showsUpgrades(quietGarden: app.settings.quietGarden)
        let columns = typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.flexible(), spacing: 10), GridItem(.flexible())]
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ShedHeader(points: points, quiet: quiet) { router.go(.butterfly) }
                if app.showsWeatherHelpers { ShedWeatherSection().padding(.top, 6) }
                sectionHeader(ShedCopy.toolsTitle, ShedCopy.toolsSubtitle).padding(.top, 6)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ShedTool.order, id: \.self) { tool in
                        ToolTile(tool: tool, tier: inv.tier(of: tool), points: points, quiet: quiet) { selected = ShedToolPick(tool: tool) }
                    }
                }
                ShedPotsSection(stats: app.potStats, hasPlus: app.hasPlusForPots, users: { pot in
                    app.plantsUsing(pot).map { $0.nickname.isEmpty ? $0.name : $0.nickname }
                }, record: { !app.recordEarnedPots().isEmpty })
                .padding(.top, 6)
            }
            .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Garden Shed")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { pick in
            ToolSheet(tool: pick.tool) { tool, tier in justUpgraded = (tool, tier) }.environment(app)
        }
        .overlay {
            if let up = justUpgraded {
                UpgradeCard(tool: up.tool, tier: up.tier, reduceMotion: reduceMotion) { justUpgraded = nil }
            }
        }
        .onAppear { app.syncToolUnlocks(); app.receiveWeatherKitIfDue() }
    }

    private func sectionHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.2).foregroundStyle(Color.secondaryText)
                .accessibilityLabel(title).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

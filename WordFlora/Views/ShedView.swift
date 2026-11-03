import SwiftUI

struct ShedView: View {
    @Environment(AppModel.self) private var app
    @State private var message: String?

    private static let info: [(ToolID, String, String)] = [
        (.can, "Watering can", "Waters your plants. Better cans water more plants at once."),
        (.trowel, "Trowel", "Digs in soil for stronger growth."),
        (.net, "Butterfly net", "For catching garden visitors."),
        (.mister, "Mister", "Finish all of level 1 in your garden to find it."),
        (.shears, "Shears", "Finish level 2 in your garden to find them."),
        (.lamp, "Sun lamp", "Finish level 3 in your garden to find it."),
    ]

    var body: some View {
        let inv = app.inventory
        let points = app.profile?.shedPoints ?? 0
        ScrollView {
            VStack(spacing: 12) {
                if !app.settings.quietGarden {
                    Label("\(points) shed points", systemImage: "star.fill").font(Theme.font(.headline))
                        .foregroundStyle(Color.accentText).frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("\(points) shed points")
                }
                ForEach(Self.info, id: \.0) { tool, name, blurb in card(tool, name, blurb, tier: inv.tier(of: tool), points: points) }
                if let message { Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText) }
            }
            .padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Garden Shed")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { app.syncToolUnlocks() }
    }

    private func card(_ tool: ToolID, _ name: String, _ blurb: String, tier: Int, points: Int) -> some View {
        let owned = tier > 0
        let next = ToolInventory.upgradeCost(toTier: tier + 1)
        return Card {
            HStack(spacing: 14) {
                Image("tool_\(tool.rawValue)_t\(max(1, tier))").resizable().scaledToFit().frame(width: 64, height: 64)
                    .saturation(owned ? 1 : 0).opacity(owned ? 1 : 0.4).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                    if owned {
                        Text("Tier \(tier) of 3").font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                            .fixedSize().padding(.horizontal, 8).padding(.vertical, 2).background(Color.appAccent.opacity(0.25), in: Capsule())
                    }
                    Text(blurb).font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).fixedSize(horizontal: false, vertical: true)
                    if owned, let cost = next {
                        Button { upgrade(tool, name) } label: {
                            Text("Upgrade for \(cost) points").font(Theme.font(.footnote, weight: .semibold))
                                .foregroundStyle(points >= cost ? Color.successText : Color.secondaryText).fixedSize(horizontal: false, vertical: true)
                        }
                        .disabled(points < cost).tapTarget()
                    } else if owned {
                        Text("Fully upgraded").font(Theme.font(.caption, weight: .semibold)).foregroundStyle(Color.successText)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(owned ? "\(name), tier \(tier) of 3" : "\(name), not found yet")
    }

    private func upgrade(_ tool: ToolID, _ name: String) {
        message = app.upgradeTool(tool) ? "\(name) upgraded!" : "Not enough shed points yet."
    }
}

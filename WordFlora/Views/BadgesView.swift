import SwiftUI

struct BadgesView: View {
    @Environment(AppModel.self) private var app

    /// Quick Bloom shows only once Speed bloom is on or the badge is earned, so the shelf never suggests the toggle.
    private var defs: [BadgeDef] {
        let state = app.badges
        return ((try? BadgeCatalog.load()) ?? []).filter { def in
            def.id != SpeedBloom.badgeId
                || SpeedBloom.showsBadge(app.settings.speedBloomPrefs, earnedAnyTier: state.unlockedDate(badge: def.id, tier: 1) != nil)
        }
    }
    var body: some View {
        let all = defs
        ScrollView {
            // Two columns in a Grid (not a lazy grid), so both cards in a row share the row's height and line up.
            Grid(horizontalSpacing: Space.m, verticalSpacing: Space.m) {
                ForEach(Array(stride(from: 0, to: all.count, by: 2)), id: \.self) { i in
                    GridRow {
                        card(all[i])
                        if i + 1 < all.count { card(all[i + 1]) } else { Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
                    }
                }
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card)
            // The bloom rank and the Grand Garden replay sit under the badges, so the badge grid keeps its place.
            EndgameBadgesHeader().padding(.horizontal, Space.gutter).padding(.bottom, Space.section)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card(_ def: BadgeDef) -> some View {
        let state = app.badges
        let counter = BadgeCounter(rawValue: def.counter)
        let progress = counter.map { state.progress(of: $0) } ?? 0
        let tier = (1...3).filter { state.unlockedDate(badge: def.id, tier: $0) != nil }.max() ?? 0
        let nextThreshold = tier < 3 ? def.thresholds[tier] : def.thresholds[2]
        return VStack(spacing: 8) {
            BadgeArtView(badgeId: def.id, tier: max(1, tier)).frame(height: 84)
                .saturation(tier > 0 ? 1 : 0).opacity(tier > 0 ? 1 : 0.35).accessibilityHidden(true)
            Text(def.title ?? def.id).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(def.blurb ?? "").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if !app.settings.quietGarden {
                ProgressView(value: Double(min(progress, nextThreshold)), total: Double(nextThreshold)).tint(Color.successText)
                Text(tier == 3 ? "Gold!" : "\(progress) of \(nextThreshold)").font(Theme.font(.caption, weight: .semibold)).foregroundStyle(Color.secondaryText)
            }
        }
        .padding(Space.m).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(tier > 0 ? Color.appAccent.opacity(0.5) : Color.appPrimaryText.opacity(0.08)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(def.title ?? def.id): \(tier == 0 ? "not earned yet" : ["bronze", "silver", "gold"][tier - 1])")
    }
}

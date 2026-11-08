import SwiftUI

struct BadgesView: View {
    @Environment(AppModel.self) private var app
    @State private var open: BadgeDef?
    @Environment(\.dynamicTypeSize) private var typeSize

    private static let catalog: [BadgeDef] = (try? BadgeCatalog.load()) ?? []
    /// Lantern Keeper (Frost & Lantern) shows while its pack is live or once earned.
    /// The Sharer badge only shows to players who can share (13 and up, age known). Quick Bloom shows only once Speed
    /// bloom is on or the badge is earned, so the shelf never suggests the toggle.
    private var defs: [BadgeDef] {
        let state = app.badges
        return Self.catalog.filter { def in
            (def.counter != BadgeCounter.badgeShares.rawValue || app.canShareBadges)
                && app.showsPackBadge(def.id)       // a season pack's badge only while the pack is live (or once earned)
                && (def.id != SpeedBloom.badgeId
                    || SpeedBloom.showsBadge(app.settings.speedBloomPrefs, earnedAnyTier: state.unlockedDate(badge: def.id, tier: 1) != nil))
        }
    }

    var body: some View {
        let all = defs
        ScrollView {
            // A Grid (not a lazy grid), so the cards in a row share the row's height and line up. Two columns, one at
            // the accessibility sizes so every badge name keeps whole words (GridColumns).
            let columns = GridColumns.count(.badges, for: typeSize)
            Grid(horizontalSpacing: GridColumns.spacing(.badges), verticalSpacing: Space.m) {
                ForEach(Array(GridColumns.rows(all, .badges, for: typeSize).enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(row, id: \.id) { card($0) }
                        ForEach(0..<(columns - row.count), id: \.self) { _ in Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]) }
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
        .onAppear { app.refreshBadgeFacts() }        // quiet catch-up, so the page matches the garden
        .sheet(item: $open) { def in BadgeDetailView(def: def, tier: max(1, app.badges.tier(of: def.id))).environment(app) }
    }

    @ViewBuilder private func card(_ def: BadgeDef) -> some View {
        let tier = app.badges.tier(of: def.id)
        if tier > 0 {
            // An earned badge opens larger, with its share button.
            Button { open = def } label: { cardBody(def, tier: tier) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(def, tier: tier))
                .accessibilityHint(BadgeDetailCopy.openHint)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("badge.\(def.id)")
        } else {
            cardBody(def, tier: tier)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(def, tier: tier))
                .accessibilityIdentifier("badge.\(def.id)")
        }
    }

    private func label(_ def: BadgeDef, tier: Int) -> String {
        "\(def.title ?? def.id): \(tier == 0 ? "not earned yet" : ["bronze", "silver", "gold"][tier - 1])"
    }

    private func cardBody(_ def: BadgeDef, tier: Int) -> some View {
        let counter = BadgeCounter(rawValue: def.counter)
        let progress = counter.map { app.badges.progress(of: $0) } ?? 0
        let nextThreshold = tier < 3 ? def.thresholds[tier] : def.thresholds[2]
        return VStack(spacing: 8) {
            BadgeArtView(badgeId: def.id, tier: max(1, tier)).frame(height: 84)
                .saturation(tier > 0 ? 1 : 0).opacity(tier > 0 ? 1 : 0.35).accessibilityHidden(true)
            Text(def.title ?? def.id).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(def.blurb ?? "").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if !app.settings.quietGarden {
                ProgressView(value: Double(min(progress, nextThreshold)), total: Double(nextThreshold)).tint(Color.successText)
                Text(tier == 3 ? "Gold!" : "\(min(progress, nextThreshold)) of \(nextThreshold)").font(Theme.font(.caption, weight: .semibold)).foregroundStyle(Color.secondaryText)
            }
        }
        .padding(Space.m).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(tier > 0 ? Color.appAccent.opacity(0.5) : Color.appPrimaryText.opacity(0.08)))
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

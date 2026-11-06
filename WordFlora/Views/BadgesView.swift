import SwiftUI

struct BadgesView: View {
    @Environment(AppModel.self) private var app

    private var defs: [BadgeDef] { (try? BadgeCatalog.load()) ?? [] }
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(defs, id: \.id) { def in card(def) }
            }
            .padding(20)
            // The bloom rank and the Grand Garden replay sit under the badges, so the badge grid keeps its place.
            EndgameBadgesHeader().padding(.horizontal, 20).padding(.bottom, 24)
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
            Image("badge_\(def.id)_t\(max(1, tier))").resizable().scaledToFit().frame(height: 84)
                .saturation(tier > 0 ? 1 : 0).opacity(tier > 0 ? 1 : 0.35).accessibilityHidden(true)
            Text(def.title ?? def.id).font(Theme.font(.subheadline, weight: .bold)).foregroundStyle(Color.appPrimaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text(def.blurb ?? "").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if !app.settings.quietGarden {
                ProgressView(value: Double(min(progress, nextThreshold)), total: Double(nextThreshold)).tint(Color.successText)
                Text(tier == 3 ? "Gold!" : "\(progress) of \(nextThreshold)").font(Theme.font(.caption, weight: .semibold)).foregroundStyle(Color.secondaryText)
            }
        }
        .padding(12).frame(maxWidth: .infinity)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(tier > 0 ? Color.appAccent.opacity(0.5) : Color.appPrimaryText.opacity(0.08)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(def.title ?? def.id): \(tier == 0 ? "not earned yet" : ["bronze", "silver", "gold"][tier - 1])")
    }
}

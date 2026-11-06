import SwiftUI

/// Words on the badge page and its detail sheet (checked by CopySafety in the tests).
enum BadgeDetailCopy {
    static let done = "Done"
    static let openHint = "Shows the badge"
    static let goldLine = "You reached gold!"

    /// "Next: Silver at 25".
    static func next(tier: Int, thresholds: [Int]) -> String? {
        guard tier >= 1, tier < 3, thresholds.count == 3 else { return tier >= 3 ? goldLine : nil }
        return "Next: \(BadgeMomentCopy.tierName(tier + 1)) at \(thresholds[tier])"
    }
}

/// An earned badge, larger, with its line and (for players 13 and up) a button that shares a picture of its card.
/// Opened from a badge on the Badges page. Quiet Garden shows no numbers.
struct BadgeDetailView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    let def: BadgeDef
    let tier: Int

    @State private var card: Image?

    private var title: String { def.title ?? def.id }

    var body: some View {
        ScrollView {
            VStack(spacing: Space.m) {
                BadgeArtView(badgeId: def.id, tier: tier)
                    .frame(width: 160, height: 160)
                    .accessibilityHidden(true)
                Text(BadgeShare.name(title: title, tier: tier))
                    .font(Theme.font(.title2, weight: .heavy)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(def.blurb ?? "").font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                if !app.settings.quietGarden, let next = BadgeDetailCopy.next(tier: tier, thresholds: def.thresholds) {
                    Text(next).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: Space.m) {
                    if app.canShareBadges, let card {
                        ShareLink(item: card, message: Text(BadgeShare.caption(title: title, tier: tier)),
                                  preview: SharePreview(BadgeShare.caption(title: title, tier: tier), image: card)) {
                            Label(BadgeShare.button, systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded { app.noteBadgeShared(def.id, tier: tier) })
                        .accessibilityIdentifier("badge.share")
                    }
                    Button(BadgeDetailCopy.done) { dismiss() }.buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("badge.done")
                }
                .padding(.top, Space.s)
            }
            .padding(.horizontal, Space.section).padding(.top, 28).padding(.bottom, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.appBackground.ignoresSafeArea())
        .presentationDetents([.large])          // a medium sheet is drawn smaller than the reader's text size
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("badgeDetail")
        .onAppear {
            app.pauseBadgeMoments(.sheet, true)
            if app.canShareBadges { card = BadgeShareCard(def: def, tier: tier).rendered() }
        }
        .onDisappear { app.pauseBadgeMoments(.sheet, false) }
    }
}

/// The picture a shared badge becomes (4:5): the medal, its name and tier, its line and the WordFlora tagline. A fixed
/// warm palette in both appearances, because it leaves the app as an image. Nothing about the player is on it.
struct BadgeShareCard: View {
    let def: BadgeDef
    let tier: Int

    private let ink = Color(hex: 0x2C3E2C), muted = Color(hex: 0x5A6B5A)

    var body: some View {
        VStack(spacing: 10) {
            Text(BadgeShare.header).font(.system(.caption, design: .rounded, weight: .heavy)).tracking(1.2).foregroundStyle(muted)
            BadgeArtView(badgeId: def.id, tier: tier).frame(width: 170, height: 170).padding(.top, 6)
            Text(def.title ?? def.id).font(.system(.title, design: .rounded, weight: .heavy)).foregroundStyle(ink)
                .multilineTextAlignment(.center)
            Text(BadgeMomentCopy.tierName(tier)).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(muted)
            Text(def.blurb ?? "").font(.system(.callout, design: .rounded)).foregroundStyle(ink).multilineTextAlignment(.center)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Image(systemName: "leaf.circle.fill").foregroundStyle(Color(hex: 0x2E7D32))
                Text("WordFlora · \(BadgeShare.tagline)").font(.system(.caption, design: .rounded, weight: .heavy)).foregroundStyle(muted)
            }
        }
        .padding(24)
        .frame(width: 320, height: 400)
        .background(LinearGradient(colors: [Color(hex: 0xFFF4D6), Color(hex: 0xFAF7F0)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .environment(\.colorScheme, .light)
        .dynamicTypeSize(.large)        // the picture is the same at every text size
    }

    @MainActor
    func rendered() -> Image? {
        let r = ImageRenderer(content: self)
        r.scale = 3
        return r.uiImage.map { Image(uiImage: $0) }
    }
}

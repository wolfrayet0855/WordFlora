import SwiftUI

/// The weekly garden note on Home (WeeklyNote): a soft tinted header (leaf, title, the week's closing line) over the
/// week's tiles (WeeklyNoteCopy.tiles): a big centred number with a small label on a soft tint, the new plants with
/// their own art. Tiles sit in a row, stacked at accessibility sizes. The card holds words only; its actions sit below
/// it (`WeeklyNoteActions`). VoiceOver reads the whole card as one element, then the actions.
struct WeeklyNoteCard: View {
    let summary: WeeklyNote.Summary
    let quiet: Bool
    /// The asset names of the week's new plants' art (`PlantCollectible.imageName`), in `summary.newPlants` order.
    var plantArt: [String] = []

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title) private var artSize: CGFloat = 30

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10))
                                                      : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
            layout {
                ForEach(WeeklyNoteCopy.tiles(summary, quiet: quiet), id: \.kind) { tile($0) }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: shape)
        .clipShape(shape)
        .overlay(shape.stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WeeklyNoteCopy.accessibilityLabel(summary, quiet: quiet))
        .accessibilityIdentifier("weeklyNote.card")
    }

    /// Title and closing line on a soft green-to-rose wash, both in full ink (successText green is 4.4:1 on the light tints).
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            // At accessibility sizes the leaf would take a column of its own beside the words.
            if !typeSize.isAccessibilitySize {
                Image(systemName: "leaf.fill").font(.system(size: iconSize)).foregroundStyle(Color.successText)
                    .frame(width: iconSize * 2, height: iconSize * 2)
                    .background(Color.appSurface.opacity(0.7), in: Circle())
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(WeeklyNoteCopy.title).font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(WeeklyNoteCopy.closing(weekKey: summary.weekKey))
                    .font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color.levelTint1, Color.bloomFill], startPoint: .leading, endPoint: .trailing))
    }

    /// One tile: the plant art (new plants only), the big number (never in Quiet Garden), the label. Full ink on every
    /// tint, so the text stays above 4.5:1 in light and dark.
    private func tile(_ t: WeeklyNoteCopy.Tile) -> some View {
        VStack(spacing: 4) {
            if t.kind == .plants, !plantArt.isEmpty {
                HStack(spacing: -artSize * 0.25) {
                    ForEach(Array(plantArt.prefix(3).enumerated()), id: \.offset) { _, name in
                        Image(name).resizable().scaledToFit().frame(width: artSize, height: artSize)
                    }
                }
                .accessibilityHidden(true)
            }
            if let number = t.number {
                Text(number).font(Theme.font(.title, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            Text(t.label).font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tint(t.kind), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tint(_ kind: WeeklyNoteCopy.Tile.Kind) -> Color {
        switch kind {
        case .words: return .tileGardenFill
        case .plants: return .bloomFill
        case .friends: return .tileVisitorsFill
        }
    }
}

/// The note's two actions, below the card: "Celebrate" (a short flower splash) and, for 13 and up outside Quiet Garden,
/// "Share my week". Side by side; stacked at accessibility sizes.
struct WeeklyNoteActions: View {
    let summary: WeeklyNote.Summary
    let canShare: Bool
    let onCelebrate: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var shareImage: Image?

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            Button(action: onCelebrate) {
                Label(WeeklyNoteCopy.celebrate, systemImage: "sparkles")
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(CelebrateButtonStyle())
            .accessibilityHint(WeeklyNoteCopy.celebrateHint)
            .accessibilityIdentifier("weeklyNote.celebrate")
            if canShare, let shareImage {
                ShareLink(item: shareImage, message: Text(WeeklyNoteCopy.caption),
                          preview: SharePreview(WeeklyNoteCopy.caption, image: shareImage)) {
                    Label(WeeklyNoteCopy.share, systemImage: "square.and.arrow.up")
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint(WeeklyNoteCopy.shareHint)
                .accessibilityIdentifier("weeklyNote.share")
            }
        }
        .onAppear {
            guard canShare, shareImage == nil else { return }
            shareImage = WeekShareCard(rows: WeeklyNoteCopy.rows(summary, quiet: false)).rendered()
        }
    }
}

/// Celebrate: deep green with light text in light mode (5.1:1), light green with dark ink in dark mode, so it reads
/// apart from the amber Play button below it.
struct CelebrateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.body, weight: .bold))
            .foregroundStyle(Color.keyCorrectText)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: Theme.minTap + 8)
            .background(Color.successText, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// The Celebrate splash: the garden's own plant art (`art`, up to three) with petals around it (CelebrationBurst, so
/// Reduce Motion gives the still arc and Calm mode or Quiet Garden the slow drift), one soft haptic, and Done.
struct WeeklyCelebrateView: View {
    /// Plant art asset names: the week's new plants, else a plant from the player's garden (HomeView picks).
    let art: [String]
    let onDone: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            CelebrationBurst(requested: [.large], origin: .fromTop(ScreenInsets.top + 120), seed: 31)
            ScrollView {
                VStack(spacing: 20) {
                    let size: CGFloat = typeSize.isAccessibilitySize ? 96 : 140
                    HStack(alignment: .bottom, spacing: -size * 0.2) {
                        ForEach(Array(art.prefix(3).enumerated()), id: \.offset) { i, name in
                            Image(name).resizable().scaledToFit()
                                .frame(width: i == 1 ? size : size * 0.78, height: i == 1 ? size : size * 0.78)
                                .zIndex(i == 1 ? 1 : 0)
                        }
                    }
                    .accessibilityHidden(true)
                    Text(WeeklyNoteCopy.celebrateTitle)
                        .font(Theme.font(.largeTitle, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(WeeklyNoteCopy.celebrateLine)
                        .font(Theme.font(.title3)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    Button(action: onDone) {
                        Text(WeeklyNoteCopy.celebrateDone).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("weeklyNote.celebrateDone")
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 48)
                .frame(maxWidth: .infinity)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: shown) { _, new in new && app.settings.hapticsOn }
        .onAppear { shown = true }
    }
}

#Preview("Weekly note") {
    VStack(spacing: 12) {
        WeeklyNoteCard(summary: WeeklyNote.Summary(words: 12, dailyBlooms: 2, newPlants: ["Clover", "Daisy"], friends: 3), quiet: false,
                       plantArt: ["plant_clover", "plant_daisy"])
        WeeklyNoteActions(summary: WeeklyNote.Summary(words: 12), canShare: true, onCelebrate: {})
    }
    .padding()
    .background(Color.appBackground)
}

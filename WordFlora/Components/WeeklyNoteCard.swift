import SwiftUI

/// The weekly garden note on Home (WeeklyNote): a soft tinted header (leaf, title, the week's closing line) over the
/// week's rows. The card holds words only; its actions sit below it (`WeeklyNoteActions`). VoiceOver reads the whole
/// card as one element, then the actions.
struct WeeklyNoteCard: View {
    let summary: WeeklyNote.Summary
    let quiet: Bool

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 20

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20, style: .continuous) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 8) {
                ForEach(WeeklyNoteCopy.rows(summary, quiet: quiet), id: \.self) { row in
                    Text(row).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
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

/// The Celebrate splash: a full-screen bloom with petals (CelebrationBurst, so Reduce Motion gives the still arc and
/// Calm mode or Quiet Garden the slow drift), one soft haptic, and Done.
struct WeeklyCelebrateView: View {
    let onDone: () -> Void

    @Environment(AppModel.self) private var app
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            CelebrationBurst(requested: [.large], origin: .fromTop(ScreenInsets.top + 120), seed: 31)
            ScrollView {
                VStack(spacing: 20) {
                    FlowerView(petals: 8, sway: false)
                        .frame(width: 140, height: 168)
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
        WeeklyNoteCard(summary: WeeklyNote.Summary(words: 12, dailyBlooms: 2, newPlants: ["Clover", "Daisy"], friends: 3), quiet: false)
        WeeklyNoteActions(summary: WeeklyNote.Summary(words: 12), canShare: true, onCelebrate: {})
    }
    .padding()
    .background(Color.appBackground)
}

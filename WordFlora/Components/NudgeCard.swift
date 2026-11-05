import SwiftUI

/// "Your garden would love a visit": shown on Home when Play is tapped again soon after "That's enough for now" by a
/// player who gets no ad (AdGate.returnVisit == .nudge). The resting card's Dusk look (scene header, centred title,
/// stacked full-width buttons on a rounded card over a dim). Play anyway is always there, so it never blocks play.
/// No ads, timers, prices or Plus on it. The caller takes Home's own content out of the hierarchy while it shows,
/// so the accessibility audit never measures text under the dim.
struct NudgeCard: View {
    var puzzle: NudgeCardCopy.Puzzle?
    var onVisit: () -> Void
    var onPuzzle: () -> Void
    var onPlay: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            GeometryReader { geo in
                ScrollView {
                    card
                        .background(Color.appBackground, in: shape).clipShape(shape)
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            RestScene(kind: .day)
            VStack(spacing: 12) {
                Text(NudgeCardCopy.title).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(NudgeCardCopy.body).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 10) {
                    Button(NudgeCardCopy.visit, action: onVisit)
                        .buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("nudgeCard.visit")
                    if let puzzle {
                        Button(NudgeCardCopy.puzzle, action: onPuzzle)
                            .buttonStyle(SecondaryButtonStyle())
                            .accessibilityHint(puzzle == .dailyBloom ? NudgeCardCopy.dailyBloomHint : NudgeCardCopy.butterflyHint)
                            .accessibilityIdentifier("nudgeCard.puzzle")
                    }
                    Button(action: onPlay) {
                        Text(NudgeCardCopy.playAnyway)
                            .font(Theme.font(.body, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTap)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(NudgeCardCopy.playAnywayHint)
                    .accessibilityIdentifier("nudgeCard.playAnyway")
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("nudgeCard")
    }
}

#Preview("Nudge card") {
    NudgeCard(puzzle: .dailyBloom, onVisit: {}, onPuzzle: {}, onPlay: {})
        .environment(AppModel(container: try! SharedContainer.make(inMemory: true)))
        .background(Color.appBackground)
}

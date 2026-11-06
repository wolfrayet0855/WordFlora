import SwiftUI

/// Home's daily tiny quest (Rules/DailyQuest.swift): one small thing for today, a count that only goes up, and a soft
/// check mark when it is done. No timer, no streak. Calm mode and Reduce Motion show the check mark still.
struct DailyQuestCard: View {
    let quest: DailyQuest.Quest
    let state: QuestState
    let calm: Bool
    let reduceMotion: Bool

    @ScaledMetric(relativeTo: .headline) private var disc: CGFloat = 36
    @State private var settled = false

    private static let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        let target = max(1, quest.target), n = min(state.progress, target)
        let title = DailyQuestCopy.title(quest)
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle().fill(state.done ? Color.successText.opacity(0.18) : Color.tileGardenFill)
                Image(systemName: state.done ? "checkmark" : "leaf.fill")
                    .font(.system(size: disc * 0.45, weight: .bold))
                    .foregroundStyle(Color.successText)
                    .scaleEffect(state.done && !settled && !calm && !reduceMotion ? 0.6 : 1)
            }
            .frame(width: disc, height: disc)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(DailyQuestCopy.header)
                    .font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(title)
                    .font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(state.done ? (calm ? DailyQuestCopy.doneCalm : DailyQuestCopy.done) : DailyQuestCopy.progress(n, of: target))
                    .font(Theme.font(.footnote)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if !state.done && target > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<target, id: \.self) { i in
                        Circle().fill(i < n ? Color.successText : Color.appPrimaryText.opacity(0.15)).frame(width: 8, height: 8)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(Color.appSurface, in: Self.shape)
        .overlay(Self.shape.stroke(Color.successText.opacity(0.3)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DailyQuestCopy.header): \(title)")
        .accessibilityValue(state.done ? DailyQuestCopy.a11yDone : DailyQuestCopy.progress(n, of: target))
        .accessibilityIdentifier("home.quest")
        .onAppear {
            guard state.done, !settled else { return }
            if calm || reduceMotion { settled = true } else { withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) { settled = true } }
        }
    }
}

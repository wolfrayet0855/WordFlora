import SwiftUI

/// The Family Sharing note (FamilyShareNudge decides who sees which).
/// 13 and up: "Already have Plus on a family phone? Restore purchases." in Settings > WordFlora Plus and on the Plus
/// screen; the button is the usual Restore.
/// Under 13 and unknown age: the grown-ups' note, only in Settings' "For grown-ups" section, on at most one day a
/// week; its button asks the grown-up question before the Plus page opens.
struct FamilyShareNudgeRow: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    var placement: FamilyShareNudge.Placement = .settings
    @State private var busy = false
    @State private var gate: ParentalGate.Challenge?

    private var audience: FamilyShareNudge.Audience {
        FamilyShareNudge.audience(ageBand: app.settings.ageBand, hasPlus: app.entitlements.state.hasPlus,
                                  quietGarden: app.settings.quietGarden, placement: placement,
                                  lastGrownUpShownAt: app.settings.familyNudgeShownAt, now: .now)
    }

    var body: some View {
        switch audience {
        case .none: EmptyView()
        case .player:
            // One fixed layout: a ViewThatFits that swapped from a row to a stack as the text grew was judged
            // "Dynamic Type partially unsupported" by the accessibility audit on the Plus screen.
            VStack(alignment: .leading, spacing: 2) { line(FamilyShareNudge.Copy.line); restoreButton }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("familyShare.nudge")
        case .grownUp:
            VStack(alignment: .leading, spacing: 2) { line(FamilyShareNudge.Copy.grownUpLine); grownUpButton }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("familyShare.grownUps")
                .onAppear(perform: noteShown)
                .sheet(item: $gate) { challenge in
                    ParentalGateSheet(challenge: challenge, onPass: { gate = nil; router.go(.plus) }, onCancel: { gate = nil })
                }
        }
    }

    /// Records the day the grown-ups' note appeared (once per day), which starts its seven-day gap.
    private func noteShown() {
        let now = Date.now
        if let last = app.settings.familyNudgeShownAt, Calendar.current.isDate(last, inSameDayAs: now) { return }
        app.settings.familyNudgeShownAt = now
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var restoreButton: some View {
        Button {
            busy = true
            Task { await app.entitlements.restore(); app.updateSyncFlag(); busy = false }
        } label: {
            Text(FamilyShareNudge.Copy.button).font(Theme.font(.footnote, weight: .semibold)).underline()
                .frame(minHeight: Theme.minTap)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.accentText)
        .disabled(busy)
        .accessibilityIdentifier("familyShare.restore")
    }

    /// Every tap asks the grown-up question first (this note only shows where `ParentalGate.isRequired`).
    private var grownUpButton: some View {
        Button {
            gate = ParentalGate.challenge(seed: UInt64(Date().timeIntervalSince1970))
        } label: {
            Text(FamilyShareNudge.Copy.grownUpButton).font(Theme.font(.footnote, weight: .semibold)).underline()
                .frame(minHeight: Theme.minTap)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Color.accentText)
        .accessibilityIdentifier("familyShare.grownUpsButton")
    }
}

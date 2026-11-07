import SwiftUI

/// "Already have Plus on a family phone? Restore purchases." for grown-ups without Plus (FamilyShareNudge decides).
/// Used in Settings > WordFlora Plus and on the Plus screen; the button is the usual Restore.
struct FamilyShareNudgeRow: View {
    @Environment(AppModel.self) private var app
    @State private var busy = false

    var body: some View {
        if FamilyShareNudge.isShown(ageBand: app.settings.ageBand, hasPlus: app.entitlements.state.hasPlus,
                                    quietGarden: app.settings.quietGarden) {
            // One fixed layout: a ViewThatFits that swapped from a row to a stack as the text grew was judged
            // "Dynamic Type partially unsupported" by the accessibility audit on the Plus screen.
            VStack(alignment: .leading, spacing: 2) { line; button }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("familyShare.nudge")
        }
    }

    private var line: some View {
        Text(FamilyShareNudge.Copy.line)
            .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var button: some View {
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
}

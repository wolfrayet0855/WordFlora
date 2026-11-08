import SwiftUI

/// The shared row for the rewarded perks R1, R2, R3 (mockup design-preview/admob/rewarded-prompt.svg). A video row
/// says "video" in its title and shows the play-rectangle icon; a free row (Plus, under 13, unknown age) shows a leaf,
/// and Plus alone gets the "Included with Plus" caption. Text styles only, wraps at every size, no line limit.
struct RewardedPromptRow: View {
    let title: String
    var subtitle: String? = nil
    let isVideo: Bool
    var caption: String? = nil
    let identifier: String
    /// A video is loading after the tap: a spinner stands in for the icon (the row is disabled by its host).
    var busy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Space.m) {
                Group {
                    if busy {
                        ProgressView()
                    } else {
                        Image(systemName: isVideo ? "play.rectangle.fill" : "leaf.fill")
                            .font(Theme.font(.title3))
                            .foregroundStyle(Color.successText)
                    }
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(title)
                        .font(Theme.font(.body, weight: .semibold))
                        .foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.font(.subheadline))
                            .foregroundStyle(Color.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let caption {
                        Text(caption)
                            .font(Theme.font(.footnote, weight: .semibold))
                            .foregroundStyle(Color.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(Space.card)
            .frame(maxWidth: .infinity, minHeight: Theme.minTap + 8, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Color.appPrimaryText.opacity(0.12)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identifier)
    }

    /// The row for a perk path, or nothing when the perk is hidden.
    @ViewBuilder
    static func forPath(_ path: PerkPath, adTitle: String, freeTitle: String, adSubtitle: String? = nil, freeSubtitle: String? = nil,
                        hasPlus: Bool, identifier: String, busy: Bool = false, action: @escaping () -> Void) -> some View {
        switch path {
        case .hidden:
            EmptyView()
        case .ad:
            RewardedPromptRow(title: adTitle, subtitle: adSubtitle, isVideo: true, identifier: identifier, busy: busy, action: action)
        case .free:
            RewardedPromptRow(title: freeTitle, subtitle: freeSubtitle, isVideo: false,
                              caption: hasPlus ? AdPerkCopy.plusCaption : nil, identifier: identifier, action: action)
        }
    }
}

/// The calm reward toast (mockup design-preview/admob/reward-toast.svg): fades in, rests 2.5 s, fades out (opacity only,
/// so Reduce Motion needs no variant). VoiceOver hears it once.
struct RewardToastModifier: ViewModifier {
    @Binding var message: String?
    /// False when the screen that follows says the same thing itself (the wake success view), so VoiceOver hears it once.
    var announce = true

    /// 2.5 s; UI test audits (`-uitest-toast-hold`, Debug only) keep it up for a minute so it can be audited.
    static var restNanoseconds: UInt64 {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uitest-toast-hold") { return 60_000_000_000 }
        #endif
        return 2_500_000_000
    }

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let message {
                Text(message)
                    .font(Theme.font(.callout, weight: .semibold))
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.card).padding(.vertical, Space.m)
                    .background(Color.appSurface, in: Capsule())
                    .overlay(Capsule().stroke(Color.appPrimaryText.opacity(0.12)))
                    .padding(.horizontal, Space.gutter).padding(.top, Space.s)
                    .transition(.opacity)
                    .accessibilityIdentifier("rewardToast")
                    .task(id: message) {
                        if announce { AccessibilityNotification.Announcement(message).post() }
                        try? await Task.sleep(nanoseconds: Self.restNanoseconds)
                        withAnimation(.easeOut(duration: 0.3)) { self.message = nil }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: message)
    }
}

extension View {
    func rewardToast(_ message: Binding<String?>, announce: Bool = true) -> some View {
        modifier(RewardToastModifier(message: message, announce: announce))
    }
}

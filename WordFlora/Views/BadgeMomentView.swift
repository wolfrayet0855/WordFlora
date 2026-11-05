import SwiftUI

/// Words for the badge moment (checked by CopySafety in the tests).
enum BadgeMomentCopy {
    static let tiers = ["Bronze", "Silver", "Gold"]
    static let earned = "Badge earned"

    static func tierName(_ tier: Int) -> String { tiers[max(0, min(2, tier - 1))] }

    /// "Gold Daily Bloomer".
    static func title(_ unlock: BadgeUnlock, defs: [BadgeDef]) -> String {
        "\(tierName(unlock.tier)) \(defs.first { $0.id == unlock.badgeId }?.title ?? "Badge")"
    }
}

/// Sits over the whole app (RootView) and shows each earned badge in turn, after the moment's own celebration
/// and never while a celebration card or a sheet holds them (AppModel.pauseBadgeMoments).
struct BadgeMomentHost: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var defs: [BadgeDef] = (try? BadgeCatalog.load()) ?? []

    /// UI tests (`-uitest-celebrate=badge`) keep the moment up until it is tapped, for the accessibility audit.
    static let uiTestHold = ProcessInfo.processInfo.arguments.contains("-uitest-celebrate=badge")

    private struct Gate: Equatable { var pending: BadgeUnlock?; var paused: Bool; var shown: BadgeUnlock? }

    var body: some View {
        ZStack {
            if let shown = app.shownBadge {
                BadgeMomentView(unlock: shown, title: BadgeMomentCopy.title(shown, defs: defs),
                                level: app.celebrationLevel(.badge, systemReduceMotion: systemReduceMotion),
                                pops: CelebrationStyle.badgePops(settings: app.settings, systemReduceMotion: systemReduceMotion),
                                hold: Self.uiTestHold) {
                    withAnimation(.easeOut(duration: 0.25)) { app.dismissBadgeMoment() }
                }
                .id("\(shown.badgeId)#\(shown.tier)")
                .transition(.opacity)
            }
        }
        .task(id: Gate(pending: app.pendingBadge, paused: app.badgeMomentsPaused, shown: app.shownBadge)) {
            guard app.shownBadge == nil, app.pendingBadge != nil, !app.badgeMomentsPaused else { return }
            let delay = app.badgeMomentDelay
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { _ = app.presentNextBadge() }
        }
    }
}

/// The badge moment (design-preview/celebrate, confetti "badge"): the badge art pops in (scale 0.3 to 1, ease-out back)
/// inside a soft halo while petals spiral out around it, and its name sits on a scrim above the petals. A tap on the badge
/// closes it, otherwise it goes after 2.6 s; taps elsewhere reach the screen behind, so the next word never loses a
/// letter to it. No haptic. Calm and Quiet: the pop stays, the petals become a still arc.
/// Reduce Motion: the badge only fades in, with the still arc.
struct BadgeMomentView: View {
    let unlock: BadgeUnlock
    let title: String
    let level: CelebrationLevel
    let pops: Bool
    var hold = false
    let onDismiss: () -> Void

    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.42)
            ZStack(alignment: .top) {
                Color.black.opacity(0.62).allowsHitTesting(false)
                RadialGradient(colors: [Color(hex: 0xFFE896).opacity(0.55), Color(hex: 0xFFE896).opacity(0)], center: .center,
                               startRadius: 0, endRadius: 130)
                    .frame(width: 260, height: 260)
                    .position(centre)
                    .opacity(shown ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: shown)
                    .allowsHitTesting(false)
                PetalConfettiView(level: level, origin: .point(centre), seed: UInt64(unlock.tier) &+ 13, arcRadius: 110,
                                  freezeAt: hold ? 0.9 : nil)      // UI tests hold one frame of the spiral
                VStack(spacing: 18) {
                    Image("badge_\(unlock.badgeId)_t\(max(1, min(3, unlock.tier)))")
                        .resizable().scaledToFit()
                        .frame(width: 150, height: 150)
                        .scaleEffect(pops ? (shown ? 1 : 0.3) : 1)
                        .rotationEffect(.degrees(pops && !shown ? -12 : 0))
                        .opacity(shown ? 1 : 0)
                        .animation(pops ? .timingCurve(0.34, 1.56, 0.64, 1, duration: 0.45).delay(0.05) : .easeOut(duration: 0.3), value: shown)
                        .accessibilityHidden(true)
                    VStack(spacing: 4) {
                        Text(title).font(Theme.font(.title2, weight: .heavy))
                        Text(BadgeMomentCopy.earned).font(Theme.font(.subheadline, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color(hex: 0x142014).opacity(0.94), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 24)
                    .opacity(shown ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: shown)
                }
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }
                .padding(.top, max(0, centre.y - 75))
                .frame(maxWidth: .infinity)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(BadgeMomentCopy.earned)")
        .accessibilityAddTraits([.isModal, .isButton])
        .accessibilityAction { onDismiss() }
        .accessibilityIdentifier("badgeMoment")
        .onAppear { shown = true; AccessibilityNotification.Announcement("\(BadgeMomentCopy.earned): \(title)").post() }
        .task {
            guard !hold else { return }
            try? await Task.sleep(for: .seconds(UIAccessibility.isVoiceOverRunning ? 6 : CelebrationLevel.badge.duration))
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }
}

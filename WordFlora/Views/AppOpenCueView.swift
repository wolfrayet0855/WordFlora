import SwiftUI

/// The return cue over the whole app while an app-open ad loads (mockup design-preview/admob/app-open-cue.svg). It
/// covers the app's content from the first frame, fades in and out (opacity only, so Reduce Motion needs no other
/// variant) and is modal for VoiceOver.
struct AppOpenCueHost: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            if app.adFormats.cue != .hidden {
                AppOpenCueView { app.adFormats.skip() }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: app.adFormats.cue == .hidden)
        .onChange(of: app.adTreatment) { _, _ in app.adFormatsTreatmentCheck() }
    }
}

/// Full screen on the app background: a still pot and sprout, "Welcome back" / "to your garden", the "Ad" chip and
/// "A short ad, then your garden", three still dots, and a full-width "Skip to my garden" button (52 pt at least).
/// One layout at every text size: the column scrolls at the largest sizes, so nothing is clipped and Skip is always
/// reachable. Text styles only, no line limit.
struct AppOpenCueView: View {
    let skip: () -> Void

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: Space.section) {
                    Spacer(minLength: Space.section)
                    CuePotArt()
                        .frame(width: 120, height: 150)
                        .accessibilityHidden(true)
                    VStack(spacing: Space.m) {
                        VStack(spacing: Space.xs) {
                            Text(AdFormatCopy.Cue.title)
                                .font(Theme.font(.title, weight: .heavy))
                                .foregroundStyle(Color.appPrimaryText)
                            Text(AdFormatCopy.Cue.line)
                                .font(Theme.font(.title3))
                                .foregroundStyle(Color.secondaryText)
                        }
                        adLine
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(AdFormatCopy.Cue.voiceOver)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("appOpenCue.text")
                    HStack(spacing: Space.s) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().fill(Color.appPrimaryText.opacity(0.35)).frame(width: 8, height: 8)
                        }
                    }
                    .accessibilityHidden(true)
                    Spacer(minLength: Space.section)
                    Button(action: skip) {
                        Text(AdFormatCopy.Cue.skip)
                            .font(Theme.font(.body, weight: .bold))
                            .foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, Space.card).padding(.vertical, Space.m)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(0.3), lineWidth: 1.5))
                            .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("appOpenCue.skip")
                }
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, Space.section)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .contentShape(Rectangle())                         // nothing under the cue can be touched
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("appOpenCue")
    }

    /// The "Ad" chip beside its line; the line wraps beside the chip at large sizes.
    private var adLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s) {
            Text(AdFormatCopy.Cue.chip)
                .font(Theme.font(.footnote, weight: .heavy))
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .frame(minWidth: 20, minHeight: 20)
                .background(Color.appPrimaryText, in: RoundedRectangle(cornerRadius: 5))
            Text(AdFormatCopy.Cue.adLine)
                .font(Theme.font(.subheadline))
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The still pot and sprout (no motion).
private struct CuePotArt: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in
            let sx = size.width / 120, sy = size.height / 150
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
            // pot (from the mockup, shifted to a 120 x 150 box)
            var pot = Path()
            pot.move(to: p(20, 80)); pot.addLine(to: p(100, 80)); pot.addLine(to: p(90, 150)); pot.addLine(to: p(30, 150)); pot.closeSubpath()
            ctx.fill(pot, with: .color(Color(hex: dark ? 0x9C5E38 : 0xC97B4A)))
            ctx.fill(Path(roundedRect: CGRect(x: 13 * sx, y: 70 * sy, width: 94 * sx, height: 16 * sy), cornerRadius: 5 * sx),
                     with: .color(Color(hex: dark ? 0x86502F : 0xB5683A)))
            var stem = Path()
            stem.move(to: p(60, 70)); stem.addLine(to: p(60, 10))
            ctx.stroke(stem, with: .color(Color(hex: dark ? 0x66BB6A : 0x4CAF50)), style: StrokeStyle(lineWidth: 5 * sx, lineCap: .round))
            var left = Path()
            left.move(to: p(60, 30)); left.addCurve(to: p(22, -10 + 20), control1: p(30, 24), control2: p(20, 0 + 10))
            left.addCurve(to: p(60, 30), control1: p(44, 10), control2: p(60, 18))
            ctx.fill(left, with: .color(Color(hex: dark ? 0x66BB6A : 0x4CAF50)))
            var right = Path()
            right.move(to: p(60, 18)); right.addCurve(to: p(96, -20 + 20), control1: p(88, 12), control2: p(98, -10 + 10))
            right.addCurve(to: p(60, 18), control1: p(74, 0), control2: p(60, 4))
            ctx.fill(right, with: .color(Color(hex: dark ? 0x81C784 : 0x66BB6A)))
        }
    }
}

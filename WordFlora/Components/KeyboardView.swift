import SwiftUI

/// One key width for all three rows, as on the system keyboard: ten keys and nine gaps fill the top row, and the two
/// shorter rows are centred under it, so they stagger by half a key and a key and a half (puzzle-experience-review V5).
enum KeyboardLayout {
    static let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    static let gap: CGFloat = 5
    static let rowGap: CGFloat = 8
    /// A key's height at the default text size. Keys are width-bound (ten to a row), so only the height grows with the
    /// text size, and only up to `maxKeyHeight`: three rows of 64 pt and two gaps keep the puzzle on one screen at AX5.
    static let keyHeight: CGFloat = 50
    static let maxKeyHeight: CGFloat = 64
    /// The check or cross under a used key's letter grows with the text size up to 14 pt.
    static let maxMarkSize: CGFloat = 14
    /// The letter stops growing at this size; above it the key's Large Content Viewer shows the letter instead.
    static let letterSizeCap = DynamicTypeSize.accessibility2

    /// The key height for a scaled `keyHeight` (from `@ScaledMetric`): never below the base, never above the cap.
    static func keyHeight(scaled: CGFloat) -> CGFloat { min(max(scaled, keyHeight), maxKeyHeight) }
    /// The mark's point size for a scaled `PuzzleInk.usedGlyphSize`.
    static func markSize(scaled: CGFloat) -> CGFloat { min(max(scaled, PuzzleInk.usedGlyphSize), maxMarkSize) }
    /// The strip under the letter that holds the mark, 2 pt clear above and below it. Every key keeps it, used or not,
    /// so the letter never moves when its state changes and the mark can never sit on the letter.
    static func markStrip(mark: CGFloat) -> CGFloat { mark + 4 }
    /// The keyboard's height for a key height: three rows and two row gaps.
    static func height(keyHeight: CGFloat) -> CGFloat {
        CGFloat(rows.count) * keyHeight + CGFloat(rows.count - 1) * rowGap
    }
    /// Before the keyboard has been measured: a 375 pt phone on the 12 pt margin.
    static let fallbackWidth: CGFloat = 351

    static func keyWidth(available width: CGFloat) -> CGFloat {
        let room = width.isFinite && width > 0 ? width : fallbackWidth
        let longest = CGFloat(rows.map(\.count).max() ?? 10)
        return max(1, ((room - (longest - 1) * gap) / longest).rounded(.down))
    }

    static func rowWidth(_ row: String, keyWidth: CGFloat) -> CGFloat {
        CGFloat(row.count) * keyWidth + CGFloat(max(0, row.count - 1)) * gap
    }
}

struct KeyboardView: View {
    let state: (Character) -> GameViewModel.KeyState
    let onTap: (Character) -> Void
    var enabled = true

    @Environment(\.colorScheme) private var colorScheme
    @State private var width: CGFloat = 0
    @ScaledMetric(relativeTo: .title3) private var scaledKeyHeight: CGFloat = KeyboardLayout.keyHeight
    @ScaledMetric(relativeTo: .caption2) private var scaledMark: CGFloat = PuzzleInk.usedGlyphSize
    /// UI tests only: lays an untappable box over each letter and mark, so a test can read their frames (the key's
    /// own parts merge into one button for VoiceOver). Never on in the audited runs.
    private static let uiTestProbes = ProcessInfo.processInfo.arguments.contains("-uitest-key-probes")

    var body: some View {
        let keyWidth = KeyboardLayout.keyWidth(available: width)
        VStack(spacing: KeyboardLayout.rowGap) {
            ForEach(KeyboardLayout.rows, id: \.self) { row in
                HStack(spacing: KeyboardLayout.gap) {
                    ForEach(Array(row), id: \.self) { ch in key(ch, width: keyWidth) }
                }
            }
        }
        // minWidth 0: the measured width is the room offered, never the keys' own width.
        .frame(minWidth: 0, maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .overlayPreferenceValue(KeyPartFrames.self) { parts in
            if Self.uiTestProbes {
                GeometryReader { proxy in
                    ForEach(parts.keys.sorted(), id: \.self) { id in
                        let r = parts[id].map { proxy[$0] } ?? .zero
                        Color.clear.frame(width: r.width, height: r.height)
                            .accessibilityElement()
                            .accessibilityIdentifier(id).accessibilityLabel(id)
                            .position(x: r.midX, y: r.midY)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func key(_ ch: Character, width: CGFloat) -> some View {
        let s = state(ch)
        let shape = RoundedRectangle(cornerRadius: 9)
        let mark = KeyboardLayout.markSize(scaled: scaledMark)
        let letter = String(ch)
        return Button { onTap(ch) } label: {
            // One layout at every size: the letter in the upper box, the mark in a strip of its own below it, so the
            // two can never overlap (Apple's stacked layout for glyphs beside text at large sizes).
            VStack(spacing: 0) {
                Text(letter).font(Theme.font(.title3, weight: .bold))
                    .dynamicTypeSize(...KeyboardLayout.letterSizeCap)
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .anchorPreference(key: KeyPartFrames.self, value: .bounds) { Self.uiTestProbes ? ["key.\(letter).letter": $0] : [:] }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Colour is never the only signal: used keys carry a check or a cross too.
                Group {
                    switch s {
                    case .correct: Image(systemName: "checkmark")
                    case .wrong: Image(systemName: "xmark")
                    case .unused: Color.clear.frame(width: mark, height: mark)
                    }
                }
                .font(.system(size: mark, weight: .black))
                .anchorPreference(key: KeyPartFrames.self, value: .bounds) {
                    Self.uiTestProbes && s != .unused ? ["key.\(letter).mark": $0] : [:]
                }
                .frame(height: KeyboardLayout.markStrip(mark: mark))
                .accessibilityHidden(true)
            }
            .foregroundStyle(foreground(s))
            .frame(width: width, height: KeyboardLayout.keyHeight(scaled: scaledKeyHeight))
            .background(background(s), in: shape)
            .overlay(shape.stroke(Color.appPrimaryText.opacity(s == .unused ? 0.14 : 0)))
            // A 1 pt lip under an unused key, as on the iOS keyboard, so keys stand off the cream.
            .shadow(color: s == .unused ? Color.appPrimaryText.opacity(PuzzleInk.keyLip) : .clear, radius: 0, x: 0, y: 1)
        }
        .buttonStyle(KeyPressStyle())
        .disabled(!enabled || s != .unused)
        // The label stays the letter alone (so Voice Control's "Tap R" works); the state is the value.
        .accessibilityLabel(letter)
        .accessibilityValue(Self.stateValue(s))
        // The letter stops growing at AX2 and the key cannot grow wider: a long press shows it large.
        .accessibilityShowsLargeContentViewer {
            switch s {
            case .unused: Text(letter)
            case .correct: Label(letter, systemImage: "checkmark")
            case .wrong: Label(letter, systemImage: "xmark")
            }
        }
    }

    /// What VoiceOver reads after the letter: "in the word", "not in the word", or nothing for an unused key.
    static func stateValue(_ s: GameViewModel.KeyState) -> String {
        switch s {
        case .unused: return ""
        case .correct: return "in the word"
        case .wrong: return "not in the word"
        }
    }

    private func background(_ s: GameViewModel.KeyState) -> Color {
        switch s {
        case .unused: return .appSurface
        case .correct: return .successText
        case .wrong: return Color.appDanger.opacity(PuzzleInk.wrongKeyFill(dark: colorScheme == .dark))
        }
    }
    private func foreground(_ s: GameViewModel.KeyState) -> Color {
        switch s {
        case .unused: return .appPrimaryText
        // White on the light green; a dark letter on the dark mode's lighter green (7.2:1).
        case .correct: return .keyCorrectText
        case .wrong: return Color.appPrimaryText.opacity(PuzzleInk.wrongKeyText)
        }
    }
}

/// UI tests only: the letter's and the mark's bounds per key, by probe id.
private struct KeyPartFrames: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // A light wash under the finger, so the tap shows even before the key changes.
            .overlay(RoundedRectangle(cornerRadius: 9).fill(Color.appPrimaryText.opacity(configuration.isPressed ? PuzzleInk.keyPressed : 0)))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

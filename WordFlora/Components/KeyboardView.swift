import SwiftUI

/// One key width for all three rows, as on the system keyboard: ten keys and nine gaps fill the top row, and the two
/// shorter rows are centred under it, so they stagger by half a key and a key and a half (puzzle-experience-review V5).
enum KeyboardLayout {
    static let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    static let gap: CGFloat = 5
    static let rowGap: CGFloat = 8
    static let keyHeight: CGFloat = 50
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
    }

    private func key(_ ch: Character, width: CGFloat) -> some View {
        let s = state(ch)
        let shape = RoundedRectangle(cornerRadius: 9)
        return Button { onTap(ch) } label: {
            ZStack(alignment: .topTrailing) {
                // The letter grows with the text size up to what the key can hold, then shrinks to fit (keys keep their size).
                Text(String(ch)).font(Theme.font(.title3, weight: .bold)).lineLimit(1).minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Colour is never the only signal: used keys carry a glyph too.
                if s == .correct { Image(systemName: "checkmark").font(.system(size: PuzzleInk.usedGlyphSize, weight: .black)).padding(3) }
                if s == .wrong { Image(systemName: "xmark").font(.system(size: PuzzleInk.usedGlyphSize, weight: .black)).padding(3) }
            }
            .foregroundStyle(foreground(s))
            .frame(width: width, height: KeyboardLayout.keyHeight)
            .background(background(s), in: shape)
            .overlay(shape.stroke(Color.appPrimaryText.opacity(s == .unused ? 0.14 : 0)))
            // A 1 pt lip under an unused key, as on the iOS keyboard, so keys stand off the cream.
            .shadow(color: s == .unused ? Color.appPrimaryText.opacity(PuzzleInk.keyLip) : .clear, radius: 0, x: 0, y: 1)
        }
        .buttonStyle(KeyPressStyle())
        .disabled(!enabled || s != .unused)
        .accessibilityLabel(String(ch) + (s == .correct ? ", in the word" : s == .wrong ? ", not in the word" : ""))
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

struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // A light wash under the finger, so the tap shows even before the key changes.
            .overlay(RoundedRectangle(cornerRadius: 9).fill(Color.appPrimaryText.opacity(configuration.isPressed ? PuzzleInk.keyPressed : 0)))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

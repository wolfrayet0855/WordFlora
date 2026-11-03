import SwiftUI

struct KeyboardView: View {
    let state: (Character) -> GameViewModel.KeyState
    let onTap: (Character) -> Void
    var enabled = true

    private let rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(Array(row), id: \.self) { ch in key(ch) }
                }
            }
        }
    }

    private func key(_ ch: Character) -> some View {
        let s = state(ch)
        return Button { onTap(ch) } label: {
            ZStack(alignment: .topTrailing) {
                Text(String(ch)).font(Theme.font(.title3, weight: .bold)).frame(maxWidth: .infinity, maxHeight: .infinity)
                // Colour is never the only signal: used keys carry a glyph too.
                if s == .correct { Image(systemName: "checkmark").font(.system(size: 9, weight: .black)).padding(3) }
                if s == .wrong { Image(systemName: "xmark").font(.system(size: 9, weight: .black)).padding(3) }
            }
            .foregroundStyle(foreground(s))
            .frame(minWidth: 28, maxWidth: 40, minHeight: 48, maxHeight: 52)
            .background(background(s), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.appPrimaryText.opacity(s == .unused ? 0.14 : 0)))
        }
        .buttonStyle(KeyPressStyle())
        .disabled(!enabled || s != .unused)
        .accessibilityLabel(String(ch) + (s == .correct ? ", in the word" : s == .wrong ? ", not in the word" : ""))
    }

    private func background(_ s: GameViewModel.KeyState) -> Color {
        switch s { case .unused: return .appSurface; case .correct: return Color.appSuccess.opacity(0.85); case .wrong: return Color.appDanger.opacity(0.22) }
    }
    private func foreground(_ s: GameViewModel.KeyState) -> Color {
        switch s { case .unused: return .appPrimaryText; case .correct: return .white; case .wrong: return Color.appPrimaryText.opacity(0.45) }
    }
}

struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

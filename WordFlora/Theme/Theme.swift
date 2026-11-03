import SwiftUI

enum Theme {
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
    static let cornerRadius: CGFloat = 18
    static let cardRadius: CGFloat = 16
    static let minTap: CGFloat = 44
}

struct WordmarkView: View {
    var style: Font.TextStyle = .largeTitle
    var body: some View {
        (Text("Word").foregroundColor(.appPrimaryText) + Text("Flora").foregroundColor(.wordmarkFlora))
            .font(Theme.font(style, weight: .heavy))
            .accessibilityLabel("WordFlora")
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.title3, weight: .bold))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.appAccent, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(.body, weight: .semibold))
            .foregroundStyle(Color.appPrimaryText)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: Theme.minTap + 8)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Color.appPrimaryText.opacity(0.12)))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(0.08)))
    }
}

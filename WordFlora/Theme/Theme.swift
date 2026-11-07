import SwiftUI

extension Color {
    /// Secondary text that still meets 4.5:1 on both backgrounds (the plain 0.6-0.7 opacities did not).
    static let secondaryText = Color.appPrimaryText.opacity(0.88)
}

/// The puzzle screen's ink levels, in one place so the contrast tests measure exactly what is drawn
/// (docs/pm/puzzle-experience-review.md V3, V4, V10). Opacities apply to the named colour assets.
enum PuzzleInk {
    /// An unrevealed tile's 2 pt outline: appPrimaryText at 55% is at least 3:1 on the cream and on the tile.
    static let blankOutline = 0.55
    /// A tried letter that is not in the word: the letter at 70% (about 4:1) over a pink fill of appDanger.
    static let wrongKeyText = 0.70
    /// The pink under a wrong key: a clearer rose in dark mode, where 22% read as muddy brown.
    static func wrongKeyFill(dark: Bool) -> Double { dark ? 0.30 : 0.22 }
    /// The check and cross on a used key (points, black weight).
    static let usedGlyphSize: CGFloat = 11
    /// An unused key's 1 pt lip (appPrimaryText) so it stands off the cream, and the wash while a key is pressed.
    static let keyLip = 0.22
    static let keyPressed = 0.08
    /// Speed bloom ring: the gold arc and its faint track, separate from the gold flower centre in light mode.
    static func ringFill(dark: Bool) -> UInt32 { dark ? 0xE8A838 : 0xB7791F }
    static func ringTrack(dark: Bool) -> (hex: UInt32, opacity: Double) { dark ? (0xF5C858, 0.28) : (0xB7791F, 0.35) }
    /// The ring's line on screen, in points, whatever the flower's size.
    static let ringLine: CGFloat = 5
}

enum Theme {
    static func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
    static let cornerRadius: CGFloat = 18
    static let cardRadius: CGFloat = 16
    static let minTap: CGFloat = 44
}

extension View {
    /// Guarantees a 44x44 point hit area (Apple's minimum) without changing how the content looks.
    func tapTarget() -> some View { frame(minWidth: Theme.minTap, minHeight: Theme.minTap).contentShape(Rectangle()) }
}

/// The WordFlora wordmark: vector artwork with a flower in each O (design-preview/logo/final).
/// Light and dark come from the asset's appearances; Increase Contrast swaps in the mono art,
/// tinted with the primary text colour so it reads in both modes. Below 130 pt the solo art
/// (flower only in Flora's O) is used, as the artwork notes ask.
struct WordmarkView: View {
    var style: Font.TextStyle = .largeTitle
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .title) private var titleWidth: CGFloat = 172
    @ScaledMetric(relativeTo: .largeTitle) private var largeWidth: CGFloat = 262

    private var base: CGFloat { style == .largeTitle ? 262 : 172 }
    /// Grows with Dynamic Type, capped at 1.6x so the Home header keeps room for its controls.
    private var width: CGFloat { min(style == .largeTitle ? largeWidth : titleWidth, base * 1.6) }

    var body: some View {
        art
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.appPrimaryText)   // only tints the template (mono) art
            .frame(maxWidth: width)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("WordFlora")
            .accessibilityAddTraits([.isHeader, .isImage])
    }

    private var art: Image {
        if contrast == .increased {
            return Image("WordmarkMono").renderingMode(.template)
        }
        return Image(width < 130 ? "WordmarkSolo" : "Wordmark").renderingMode(.original)
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
            .padding(Space.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.appPrimaryText.opacity(0.08)))
    }
}

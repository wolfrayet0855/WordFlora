import CoreGraphics

/// One spacing scale for the whole app, on a 4 point base (docs/pm/spacing-audit.md).
/// Screens use `gutter` at their sides; boxes and cards use `card` on all four inner sides so content never sits on an
/// edge and the space above and below matches the space at the sides.
enum Space {
    /// 4: hairline gaps inside a control (icon to label).
    static let xs: CGFloat = 4
    /// 8: title to body text, buttons to the safe area.
    static let s: CGFloat = 8
    /// 12: between stacked rows or buttons, dots to buttons.
    static let m: CGFloat = 12
    /// 16: inner padding of every card and box, on all four sides.
    static let card: CGFloat = 16
    /// 16: a screen's side margin. Boxes, buttons, the wordmark and Skip all line up on it.
    static let gutter: CGFloat = 16
    /// 24: between a box and the heading below it, and between sections.
    static let section: CGFloat = 24
}

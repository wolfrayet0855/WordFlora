import CoreGraphics
import SwiftUI

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

/// How many columns a card grid has at a text size, so every word keeps a whole line (owner rule: every word fits at
/// every text size; no capped type, no shrinking, no ViewThatFits). Chosen from the size category alone, so it is the
/// same on every run and TextFitLayoutTests can measure the longest word against the cell the view really draws.
/// The views and the test share `textWidth`, so a change to a grid's padding is measured too.
enum GridColumns {
    enum Grid: CaseIterable {
        /// My Garden plant cards (`PlantCard`).
        case garden
        /// The Badges shelf.
        case badges
        /// The Shed's pot cards.
        case shedPots
        /// The repot sheet's pot tiles.
        case repotTiles
        /// The repot sheet's soil chips.
        case soilChips
        /// The Visitors' book weather stickers.
        case stickers
    }

    static func count(_ grid: Grid, for size: DynamicTypeSize) -> Int {
        switch grid {
        case .garden, .badges:
            return size.isAccessibilitySize ? 1 : 2
        case .shedPots, .repotTiles:
            return size.isAccessibilitySize ? 1 : (size > .large ? 2 : 4)
        case .soilChips:
            // "Compost" beside its dot does not fit a quarter of the row even at the default size.
            return size >= .accessibility3 ? 1 : 2
        case .stickers:
            return size >= .accessibility4 ? 1 : (size.isAccessibilitySize ? 2 : (size >= .xLarge ? 3 : 4))
        }
    }

    /// The gap between two cells in a row.
    static func spacing(_ grid: Grid) -> CGFloat {
        switch grid {
        case .garden, .badges, .stickers: return Space.m
        case .shedPots: return 6
        case .repotTiles, .soilChips: return 8
        }
    }

    /// One column at the accessibility sizes: a pot card or tile is a row, the pot beside its words.
    static func isRow(_ grid: Grid, for size: DynamicTypeSize) -> Bool {
        (grid == .shedPots || grid == .repotTiles) && count(grid, for: size) == 1
    }

    // A pot row's pieces (one column): side padding, the pot art's width and the gap to the words.
    static let rowPadding: CGFloat = 12
    static func rowArt(_ grid: Grid) -> CGFloat { grid == .shedPots ? 60 : 48 }
    static let rowGap: CGFloat = 12
    /// Room kept at a row's trailing edge for the check badge in its corner, so the words never run under it.
    static let rowBadge: CGFloat = 20
    /// A cell's side padding when it is not a row.
    static func cellPadding(_ grid: Grid) -> CGFloat {
        switch grid {
        case .garden, .badges: return Space.m
        case .shedPots, .repotTiles: return 4
        case .soilChips: return 6
        case .stickers: return 0
        }
    }
    /// The soil chip's dot and its gap to the word.
    static let soilDot: CGFloat = 10
    static let soilDotGap: CGFloat = 6

    /// The width the words in one cell get on a screen `screen` points wide (the grid sits inside the screen gutters).
    static func textWidth(_ grid: Grid, screen: CGFloat, size: DynamicTypeSize) -> CGFloat {
        let columns = CGFloat(count(grid, for: size))
        let cell = (screen - 2 * Space.gutter - spacing(grid) * (columns - 1)) / columns
        if isRow(grid, for: size) { return cell - 2 * rowPadding - rowBadge - rowArt(grid) - rowGap }
        let beside = grid == .soilChips ? soilDot + soilDotGap : 0
        return cell - 2 * cellPadding(grid) - beside
    }

    /// Splits items into rows of this grid's column count (for an eager `Grid`, whose rows share one height).
    static func rows<T>(_ items: [T], _ grid: Grid, for size: DynamicTypeSize) -> [[T]] {
        let n = count(grid, for: size)
        return stride(from: 0, to: items.count, by: n).map { Array(items[$0..<min($0 + n, items.count)]) }
    }
}

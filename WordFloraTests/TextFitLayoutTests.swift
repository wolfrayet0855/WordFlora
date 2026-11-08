import XCTest
import SwiftUI
import UIKit
@testable import WordFlora

/// Owner rule: every word fits at every text size (no capped type, no shrinking, no ViewThatFits). For each screen of
/// the text-fit pass, the longest word of every line is measured in the view's own text style, weight and design at
/// every Dynamic Type size from xSmall to AX5, against the width the view gives it on 375, 393 and 402 pt wide
/// iPhones. Grids use the same column helper and paddings the views use (`GridColumns.textWidth`), so a padding change
/// is measured too. Same method as TendRowLayoutTests (docs/pm/textfit-builder-brief.md, section 8).
final class TextFitLayoutTests: XCTestCase {
    private let screens: [CGFloat] = [375, 393, 402]
    private let sizes: [(UIContentSizeCategory, DynamicTypeSize)] = [
        (.extraSmall, .xSmall), (.small, .small), (.medium, .medium), (.large, .large),
        (.extraLarge, .xLarge), (.extraExtraLarge, .xxLarge), (.extraExtraExtraLarge, .xxxLarge),
        (.accessibilityMedium, .accessibility1), (.accessibilityLarge, .accessibility2),
        (.accessibilityExtraLarge, .accessibility3), (.accessibilityExtraExtraLarge, .accessibility4),
        (.accessibilityExtraExtraExtraLarge, .accessibility5),
    ]

    private func uiStyle(_ s: Font.TextStyle) -> UIFont.TextStyle {
        switch s {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }

    private func font(_ style: Font.TextStyle, _ weight: UIFont.Weight, _ size: UIContentSizeCategory,
                      design: UIFontDescriptor.SystemDesign = .rounded, italic: Bool = false) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: uiStyle(style), compatibleWith: UITraitCollection(preferredContentSizeCategory: size))
        var d = UIFont.systemFont(ofSize: base.pointSize, weight: weight).fontDescriptor
        d = d.withDesign(design) ?? d
        if italic { d = d.withSymbolicTraits(d.symbolicTraits.union(.traitItalic)) ?? d }
        return UIFont(descriptor: d, size: base.pointSize)
    }

    private func widestWord(_ lines: [String], _ f: UIFont) -> (String, CGFloat) {
        let words = Set(lines.flatMap { $0.split(separator: " ").map(String.init) })
        return words.map { ($0, ceil(($0 as NSString).size(withAttributes: [.font: f]).width)) }.max { $0.1 < $1.1 } ?? ("", 0)
    }

    /// Fails with the word, the size and the screen when the longest word is wider than `room`.
    private func check(_ what: String, _ lines: [String], style: Font.TextStyle, weight: UIFont.Weight = .regular,
                       design: UIFontDescriptor.SystemDesign = .rounded, italic: Bool = false,
                       styleAt: ((DynamicTypeSize) -> Font.TextStyle)? = nil,
                       room: (CGFloat, DynamicTypeSize) -> CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        for screen in screens {
            for (cat, dts) in sizes {
                let f = font(styleAt?(dts) ?? style, weight, cat, design: design, italic: italic)
                let w = widestWord(lines, f), r = room(screen, dts)
                XCTAssertLessThanOrEqual(w.1, r, "\(what), \(Int(screen)) pt, \(dts): '\(w.0)' needs \(w.1) of \(r)", file: file, line: line)
            }
        }
    }

    private func grid(_ g: GridColumns.Grid) -> (CGFloat, DynamicTypeSize) -> CGFloat {
        { GridColumns.textWidth(g, screen: $0, size: $1) }
    }

    // MARK: The column rules

    func testTheColumnRules() {
        for g in [GridColumns.Grid.garden, .badges] {
            XCTAssertEqual(GridColumns.count(g, for: .large), 2)
            XCTAssertEqual(GridColumns.count(g, for: .xxxLarge), 2)
            XCTAssertEqual(GridColumns.count(g, for: .accessibility1), 1)
        }
        for g in [GridColumns.Grid.shedPots, .repotTiles] {
            XCTAssertEqual(GridColumns.count(g, for: .large), 4, "4 x 4 at the default size")
            XCTAssertEqual(GridColumns.count(g, for: .xLarge), 2)
            XCTAssertEqual(GridColumns.count(g, for: .xxxLarge), 2)
            XCTAssertEqual(GridColumns.count(g, for: .accessibility1), 1)
            XCTAssertTrue(GridColumns.isRow(g, for: .accessibility5))
            XCTAssertFalse(GridColumns.isRow(g, for: .xxxLarge))
        }
        XCTAssertEqual(GridColumns.count(.soilChips, for: .large), 2)
        XCTAssertEqual(GridColumns.count(.soilChips, for: .accessibility2), 2)
        XCTAssertEqual(GridColumns.count(.soilChips, for: .accessibility3), 1)
        XCTAssertEqual(GridColumns.count(.stickers, for: .large), 4)
        XCTAssertEqual(GridColumns.count(.stickers, for: .xLarge), 3)
        XCTAssertEqual(GridColumns.count(.stickers, for: .accessibility3), 2)
        XCTAssertEqual(GridColumns.count(.stickers, for: .accessibility4), 1)
        XCTAssertEqual(GridColumns.rows(Array(1...7), .stickers, for: .xLarge), [[1, 2, 3], [4, 5, 6], [7]])
    }

    // MARK: Grids

    func testGardenCardNamesAndBotanicalNames() throws {
        let plants = try PlantCatalog.load()
        XCTAssertTrue(plants.contains { $0.name == "Passionflower" } && plants.contains { $0.name == "Snapdragon" })
        check("garden name", plants.map(\.name) + ["Not found yet"], style: .subheadline, weight: .bold, room: grid(.garden))
        check("garden botanical", plants.map(\.botanicalName), style: .caption, italic: true,
              styleAt: PlantCard.botanicalStyle, room: grid(.garden))
    }

    func testBadgeNamesAndBlurbs() throws {
        let defs = try BadgeCatalog.load()
        check("badge title", defs.compactMap(\.title), style: .subheadline, weight: .bold, room: grid(.badges))
        check("badge blurb", defs.compactMap(\.blurb), style: .caption, room: grid(.badges))
    }

    func testShedPotCards() throws {
        let pots = PotCatalog.all + PotCatalog.packPots
        for name in ["Snowflake indigo", "Rainbow bark", "Terracotta"] { XCTAssertTrue(pots.contains { $0.name == name }, name) }
        check("shed pot name", pots.map(\.name), style: .footnote, weight: .heavy, room: grid(.shedPots))
        let plantNames = try PlantCatalog.load().map(\.name)
        let goals = pots.map(PotCatalog.goalLine).filter { !$0.isEmpty }
        // The card's use line: "In use" alone four a row and one a row (a plant's name does not fit there), the name
        // two a row.
        for screen in screens {
            for (cat, dts) in sizes {
                let named = ShedPotsSection.namesUser(dts)
                let lines = [PotCatalog.Copy.yours, "In use by 12 plants", dts.isAccessibilitySize ? PotCatalog.Copy.plusCardShort : PotCatalog.Copy.plusCard,
                             PackCatalog.Copy.seasonsTitle] + goals + (named ? plantNames.map { "In use by \($0)" } : [PotCatalog.Copy.current])
                let w = widestWord(lines, font(.caption, .bold, cat)), r = GridColumns.textWidth(.shedPots, screen: screen, size: dts)
                XCTAssertLessThanOrEqual(w.1, r, "shed card line, \(Int(screen)) pt, \(dts): '\(w.0)' needs \(w.1) of \(r)")
            }
        }
        check("shed progress", ["12 of 25 plants grown", "10 of 10 plants in level 3", "7 of 7 garden days", "5 of 5 Daily Bloom days"],
              style: .caption2, weight: .bold, room: grid(.shedPots))
    }

    func testRepotTilesGoalLinesAndSoilChips() {
        let pots = PotCatalog.all + PotCatalog.packPots
        check("repot tile name", pots.map(\.name), style: .caption, weight: .heavy, room: grid(.repotTiles))
        check("repot goal", pots.map(PotCatalog.goalLine).filter { !$0.isEmpty }, style: .caption2, weight: .bold, room: grid(.repotTiles))
        // The In use and Plus pills: the word, a small icon (about one em) and 3 + 2 x 7 pt of padding.
        for screen in screens {
            for (cat, dts) in sizes {
                let f = font(.caption2, .heavy, cat)
                let w = widestWord([PotCatalog.Copy.current, PotCatalog.Copy.plusTag], f)
                XCTAssertLessThanOrEqual(w.1 + f.pointSize + 17, GridColumns.textWidth(.repotTiles, screen: screen, size: dts),
                                         "pill, \(Int(screen)) pt, \(dts): '\(w.0)'")
            }
        }
        check("soil chip", SoilType.allCases.map { $0.rawValue.capitalized }, style: .subheadline, weight: .bold, room: grid(.soilChips))
    }

    func testVisitorsBookStickerNames() {
        let names = WeatherSticker.allCases.map(\.name)
        for name in ["Snowflake", "Ladybird", "Rainbow"] { XCTAssertTrue(names.contains(name), name) }
        check("sticker", names, style: .footnote, weight: .semibold, room: grid(.stickers))
    }

    // MARK: Visitors

    private var visitorNames: [String] {
        let names = VisitorCatalog.all.map(\.name)
        for name in ["Hummingbird", "Swallowtail", "Bumblebee"] { XCTAssertTrue(names.contains(name), name) }
        return names
    }

    /// The play card: a Card (16 pt padding) in the page gutters; the 60 pt monarch and a 14 pt gap beside the words
    /// below the accessibility sizes, above them at AX. The switch (51 pt and the system's 8 pt gap, rounded to 64)
    /// sits beside its label below AX, under it at AX.
    func testVisitorsPlayCard() {
        let column: (CGFloat, DynamicTypeSize) -> CGFloat = { screen, size in
            screen - 2 * Space.gutter - 2 * Space.card - (size.isAccessibilitySize ? 0 : 60 + 14)
        }
        check("friend of the day", visitorNames.map(VisitorsCopy.friendOfTheDay), style: .subheadline, weight: .semibold, room: column)
        check("play title", [VisitorsCopy.playTitle], style: .title3, weight: .bold, room: column)
        check("easier label", [VisitorsCopy.easierToggle], style: .subheadline, weight: .semibold,
              room: { column($0, $1) - ($1.isAccessibilitySize ? 0 : 64) })
        check("easier note", [VisitorsCopy.easierFootnote], style: .footnote, room: column)
    }

    func testFieldNotesNameAndDetailSheetTitle() {
        check("field notes name", visitorNames, style: .title3, weight: .bold, styleAt: FieldNotesPage.nameStyle,
              room: { s, d in s - 2 * Space.gutter - FieldNotesPage.leading(d) - FieldNotesPage.trailing(d) })
        check("detail title", visitorNames, style: .title, weight: .bold, styleAt: VisitorDetailSheet.titleStyle,
              room: { s, d in s - 2 * VisitorDetailSheet.sidePadding(d) })
    }

    // MARK: Plant page and found cards

    func testNameStoryCardNames() throws {
        let names = try PlantCatalog.load().map(\.name)
        check("name story", names, style: .largeTitle, weight: .bold, design: .serif, styleAt: NameStoryCard.nameStyle,
              room: { s, _ in s - 2 * Space.gutter - 2 * NameStoryCard.sidePadding })
    }

    /// A found plant's card on the win, weather and first-word screens: inside a dimmed card (24 pt outside, 20 pt
    /// inside), 220 pt wide below AX and the full width at AX.
    func testFoundPlantCard() throws {
        let names = try PlantCatalog.load().map(\.name)
        check("found card", names, style: .subheadline, weight: .bold,
              styleAt: { PlantCard.nameStyle($0, compact: false, standalone: true) },
              room: { s, d in min(PlantCard.foundWidth(d), s - 2 * GameView.cardMargin(d) - 2 * 20) - 2 * Space.m })
    }

    // MARK: Plus

    /// The grown-up question sheet: the sheet sits about 16 pt in from each edge on iOS 26, then its own padding.
    func testGrownUpSheetTitle() {
        let room: (CGFloat, DynamicTypeSize) -> CGFloat = { s, d in s - 2 * 16 - 2 * ParentalGateSheet.padding(d) }
        check("gate title", [ParentalGate.Copy.title], style: .title2, weight: .bold, styleAt: ParentalGateSheet.titleStyle, room: room)
        check("gate prompt", [ParentalGate.Copy.prompt], style: .callout, room: room)
        // At AX the question is two set lines; each line must fit whole (the widest: "19 × 9?").
        for screen in screens {
            for (cat, dts) in sizes where dts.isAccessibilitySize {
                let f = font(.title, .heavy, cat)
                for line in ["What is", "19 × 9?"] {
                    let w = ceil((line as NSString).size(withAttributes: [.font: f]).width)
                    XCTAssertLessThanOrEqual(w, room(screen, dts), "gate question line '\(line)', \(Int(screen)) pt, \(dts)")
                }
            }
        }
    }

    /// A plan card: the card (16 pt padding) in the page gutters, the choice circle (about one body em) and a 10 pt gap.
    func testPlusCardPricesAndTitles() {
        let prices = [PaywallCopy.priceLine("$12.99", choice: .yearly), PaywallCopy.priceLine("$3.99", choice: .monthly),
                      PaywallCopy.priceLine("$34.99", choice: .lifetime)]
        XCTAssertEqual(prices.first, "$12.99 a year")
        for screen in screens {
            for (cat, dts) in sizes {
                let circle = font(.body, .regular, cat).pointSize * 1.25
                let room = screen - 2 * Space.gutter - 2 * Space.card - 10 - circle
                for (lines, style) in [(prices, Font.TextStyle.headline), (["Yearly", "Monthly", PlusPlan.lifetimeName], .headline)] {
                    let w = widestWord(lines, font(style, .semibold, cat))
                    XCTAssertLessThanOrEqual(w.1, room, "plus card, \(Int(screen)) pt, \(dts): '\(w.0)' needs \(w.1) of \(room)")
                }
                let w = widestWord([PaywallCopy.lifetimeLine, "About $1.08 a month · save 73%", "3 days free to start"], font(.caption, .regular, cat))
                XCTAssertLessThanOrEqual(w.1, room, "plus card line, \(Int(screen)) pt, \(dts): '\(w.0)'")
            }
        }
        check("plus title", [PlusPlan.groupName], style: .largeTitle, weight: .bold, room: { s, _ in s - 2 * Space.gutter })
        check("plus footer", ["Terms of Use", "Privacy Policy", "Manage subscription", PaywallCopy.redeem, PaywallCopy.restore],
              style: .footnote, room: { s, d in d.isAccessibilitySize ? s - 2 * Space.gutter : (s - 2 * Space.gutter - 8) / 2 })
        // The button: 16 pt card-wide style, 12 pt padding each side.
        check("plus button", [PaywallCopy.trialCTA, "Subscribe", "Buy Plus Forever", PaywallCopy.loadingPrices],
              style: .title3, weight: .bold, room: { s, _ in s - 2 * Space.gutter - 24 })
    }
}

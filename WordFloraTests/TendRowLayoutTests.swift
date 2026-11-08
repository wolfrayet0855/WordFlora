import XCTest
import SwiftUI
import UIKit
@testable import WordFlora

/// The plant page's tend buttons: every word on every button (titles and captions in the ready, done, supply and seed
/// states) fits its tile on one line, so nothing breaks mid-word ("Trimme / d"), at every text size from xSmall to
/// AX XXXL on 375, 393 and 402 pt wide iPhones (docs/pm/toolbar-fit-review.md; lead ruling 2026-11-07).
final class TendRowLayoutTests: XCTestCase {
    private let screens: [CGFloat] = [375, 393, 402]

    private func font(_ style: UIFont.TextStyle, _ weight: UIFont.Weight, _ size: UIContentSizeCategory) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style, compatibleWith: UITraitCollection(preferredContentSizeCategory: size))
        let weighted = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
        return weighted.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: base.pointSize) } ?? weighted
    }

    private func widestWord(_ lines: [String], _ f: UIFont) -> (String, CGFloat) {
        let words = Set(lines.flatMap { $0.split(separator: " ").map(String.init) })
        return words.map { ($0, ceil(($0 as NSString).size(withAttributes: [.font: f]).width)) }.max { $0.1 < $1.1 } ?? ("", 0)
    }

    /// Every title a button can show: ready and supply (the action), done, seed.
    private var titles: [String] {
        TendKind.allCases.map(\.title) + [AppModel.doneLabels.water, AppModel.doneLabels.feed, AppModel.doneLabels.sun,
                                         TendKind.trimmed, MistMakerCopy.doneLabel, TendKind.wakeFirst, AppModel.wakeFirstLabel]
    }
    /// Every caption: ready, supply, done ("More tomorrow", "Trim in 2 days") and seed ("Tap the seed").
    private var captions: [String] {
        TendKind.allCases.flatMap { [$0.readyCaption, $0.supplyCaption] } + [TendKind.trimLater, TendKind.moreTomorrow, TendKind.wakeCaption]
    }

    func testTheLayoutRule() {
        for size in [DynamicTypeSize.xSmall, .large, .xLarge, .xxxLarge] {
            XCTAssertEqual(TendRowLayout.columns(buttons: 6, typeSize: size), 3, "six: 3 + 3 at \(size)")
            XCTAssertEqual(TendRowLayout.columns(buttons: 5, typeSize: size), 3, "five: 3 + 2 at \(size)")
        }
        XCTAssertEqual(TendRowLayout.columns(buttons: 4, typeSize: .large), 4, "four: one row up to Large")
        XCTAssertEqual(TendRowLayout.columns(buttons: 4, typeSize: .xLarge), 2, "then 2 + 2")
        for size in [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5] {
            XCTAssertEqual(TendRowLayout.columns(buttons: 6, typeSize: size), 1, "one full-width tile each at \(size)")
        }
        XCTAssertEqual(TendKind.trimmed, "Trim")
    }

    /// Below the accessibility sizes: the pinned rows.
    func testEveryWordFitsItsTileBelowTheAccessibilitySizes() {
        let sizes: [(UIContentSizeCategory, DynamicTypeSize)] = [
            (.extraSmall, .xSmall), (.small, .small), (.medium, .medium), (.large, .large),
            (.extraLarge, .xLarge), (.extraExtraLarge, .xxLarge), (.extraExtraExtraLarge, .xxxLarge),
        ]
        for screen in screens {
            let content = screen - 2 * Space.gutter
            for buttons in [4, 5, 6] {
                for (cat, dts) in sizes {
                    let cols = TendRowLayout.columns(buttons: buttons, typeSize: dts)
                    let gap = TendRowLayout.spacing(columns: cols)
                    let room = (content - gap * CGFloat(cols - 1)) / CGFloat(cols) - 2 * TendRowLayout.tilePadding
                    let t = widestWord(titles, font(.footnote, .heavy, cat)), c = widestWord(captions, font(.caption2, .bold, cat))
                    let at = "\(Int(screen)) pt, \(buttons) buttons, \(dts)"
                    XCTAssertLessThanOrEqual(t.1, room, "\(at): '\(t.0)' needs \(t.1) of \(room)")
                    XCTAssertLessThanOrEqual(c.1, room, "\(at): '\(c.0)' needs \(c.1) of \(room)")
                }
            }
        }
    }

    /// Accessibility sizes AX1 to AX5: one full-width tile per button, icon (40 + 8) beside the words, 10 pt padding.
    func testEveryWordFitsTheFullWidthTilesAtEveryAccessibilitySize() {
        let cats: [UIContentSizeCategory] = [.accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
                                             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge]
        for screen in screens {
            let room = screen - 2 * Space.gutter - 2 * 10 - 48 - 10
            for cat in cats {
                let t = widestWord(titles, font(.body, .heavy, cat)), c = widestWord(captions, font(.footnote, .bold, cat))
                XCTAssertLessThanOrEqual(t.1, room, "\(Int(screen)) pt \(cat.rawValue): '\(t.0)' needs \(t.1) of \(room)")
                XCTAssertLessThanOrEqual(c.1, room, "\(Int(screen)) pt \(cat.rawValue): '\(c.0)' needs \(c.1) of \(room)")
            }
        }
    }
}

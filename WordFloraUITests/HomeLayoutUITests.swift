import XCTest

/// Home v2 layout: Explore labels never wrap at regular text sizes, and accessibility sizes switch to one column.
/// `-uitest-layout` makes Home report, per label, its rendered height divided by the height of one line.
final class HomeLayoutUITests: XCTestCase {
    var app: XCUIApplication!
    private let tiles = ["Garden", "Levels", "Shed", "Visitors", "Badges"]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(size: String? = nil, everything: Bool = false) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-layout"]
            + (everything ? ["-uitest-gardened", "-uitest-everything"] : [])
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
    }

    private func tile(_ name: String) -> XCUIElement { app.buttons["tile-\(name)"] }

    private func assertOneLine(_ context: String, file: StaticString = #filePath, line: UInt = #line) {
        for name in tiles {
            let t = tile(name)
            XCTAssertTrue(t.waitForExistence(timeout: 3), "\(context): \(name) tile", file: file, line: line)
            XCTAssertEqual(t.value as? String, "lines:1", "\(context): \(name) label wraps", file: file, line: line)
        }
        let report = app.staticTexts["home-layout-report"]
        XCTAssertTrue(report.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertEqual(report.label, "Play=1;Daily Bloom=1", "\(context): Play or Daily Bloom wraps", file: file, line: line)
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    func testLabelsStayOnOneLineAtDefaultSizeWithLockedTiles() {
        launch()
        assertOneLine("default, locked")
        XCTAssertFalse(tile("Levels").isEnabled)
        XCTAssertTrue(tile("Garden").isEnabled)
        shot("home-v2-locked")
    }

    func testDefaultSizeIsATwoColumnGridWithAFullWidthBadgesTile() {
        launch(everything: true)
        assertOneLine("default, open")
        let garden = tile("Garden").frame, levels = tile("Levels").frame, shed = tile("Shed").frame, badges = tile("Badges").frame
        XCTAssertEqual(garden.minY, levels.minY, accuracy: 1, "Garden and Levels share a row")
        XCTAssertGreaterThan(levels.minX, garden.maxX)
        XCTAssertGreaterThan(shed.minY, garden.maxY - 1)
        XCTAssertEqual(garden.height, levels.height, accuracy: 1, "tiles in a row have equal height")
        XCTAssertEqual(badges.minX, garden.minX, accuracy: 1)
        XCTAssertEqual(badges.maxX, levels.maxX, accuracy: 1, "Badges spans both columns")
        shot("home-v2-open")
    }

    func testLabelsStayOnOneLineAtExtraExtraExtraLarge() {
        launch(size: "UICTContentSizeCategoryXXXL")
        assertOneLine("xxxLarge, locked")
        app.terminate()
        launch(size: "UICTContentSizeCategoryXXXL", everything: true)
        assertOneLine("xxxLarge, open")
        XCTAssertEqual(tile("Garden").frame.minY, tile("Levels").frame.minY, accuracy: 1, "still two columns below accessibility sizes")
    }

    func testAccessibilitySizesUseOneColumnOfEqualRows() {
        launch(size: "UICTContentSizeCategoryAccessibilityL", everything: true)
        let frames = tiles.map { tile($0).frame }
        for (i, f) in frames.enumerated() {
            XCTAssertEqual(f.minX, frames[0].minX, accuracy: 1, "\(tiles[i]) is in the single column")
            XCTAssertEqual(f.width, frames[0].width, accuracy: 1, "\(tiles[i]) is full width")
            XCTAssertEqual(f.height, frames[0].height, accuracy: 1, "\(tiles[i]) has the same height")
            if i > 0 { XCTAssertGreaterThan(f.minY, frames[i - 1].maxY - 1, "\(tiles[i]) sits below \(tiles[i - 1])") }
        }
        for _ in 0..<3 where !tile("Badges").isHittable { app.swipeUp() }
        shot("home-v2-large")
    }
}

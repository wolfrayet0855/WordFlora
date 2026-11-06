import XCTest

/// The full Badges page (36 designed badges and Weathered) and an earned badge's sheet with its share button, with
/// Apple's accessibility audit at the default size and at an accessibility size. `-uitest-badges` earns Green Thumb
/// gold, Good Feeder silver and Sun Seeker bronze.
final class BadgesUITests: XCTestCase {
    var app: XCUIApplication!
    static let axSize = "UICTContentSizeCategoryAccessibilityXL"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private func launch(_ extra: [String] = [], size: String? = nil) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-badges"] + extra
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Apple's audit. Contrast and Dynamic Type are judged only for elements fully inside the visible scroll area (text
    /// under the bar's iOS 26 edge fade or cut by the bottom edge is measured against what covers it); each element
    /// passed over is printed.
    private func audit(_ name: String) {
        var findings = [String]()
        let scroll = app.scrollViews.firstMatch
        let bar = app.navigationBars.firstMatch
        let top = bar.exists ? bar.frame.maxY + 64 : 0
        let visible: CGRect? = scroll.exists
            ? CGRect(x: scroll.frame.minX, y: max(scroll.frame.minY, top), width: scroll.frame.width, height: scroll.frame.maxY - max(scroll.frame.minY, top))
            : nil
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                if [.contrast, .dynamicType].contains(issue.auditType), let v = visible {
                    guard let e = issue.element else { return true }
                    if !v.contains(e.frame) { print("\(name): not judged at the scroll edge: '\(e.label)' \(e.frame)"); return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func openBadges() {
        let tile = app.buttons["tile-Badges"]
        XCTAssertTrue(tile.waitForExistence(timeout: 8))
        tile.tap()
        XCTAssertTrue(element("badge.green_thumb").waitForExistence(timeout: 5))
    }

    private func openGreenThumb() {
        let badge = app.buttons["badge.green_thumb"]
        for _ in 0..<12 where !badge.isHittable { app.swipeUp() }
        badge.tap()
        XCTAssertTrue(element("badgeDetail").waitForExistence(timeout: 5))
    }

    func testEveryBadgeIsOnThePageAndTheGridKeepsTwoColumns() {
        launch()
        openBadges()
        for id in ["plant_collector", "rare_finds", "sticker_book", "word_whiz", "morning_garden", "weathered", "first_bloom",
                   "steady_gardener", "first_butterfly", "field_notes", "shed_keeper", "sharer"] {
            XCTAssertTrue(element("badge.\(id)").exists, id)
        }
        // Two columns of equal width, rows lined up (the spacing pass).
        let a = element("badge.plant_collector").frame, b = element("badge.level_sets").frame
        XCTAssertEqual(a.minY, b.minY, accuracy: 1); XCTAssertEqual(a.width, b.width, accuracy: 1); XCTAssertLessThan(a.maxX, b.minX)
        XCTAssertTrue(element("badge.green_thumb").label.hasSuffix("gold"), element("badge.green_thumb").label)
        XCTAssertTrue(element("badge.rare_finds").label.hasSuffix("not earned yet"))
        shot("badges-default")
        audit("badges-default")
    }

    func testAnEarnedBadgeOpensWithItsShareButtonAndPassesTheAudit() {
        launch()
        openBadges()
        openGreenThumb()
        XCTAssertTrue(app.staticTexts["Gold Green Thumb badge"].exists)
        XCTAssertTrue(element("badge.share").waitForExistence(timeout: 5), "13 and up can share")
        shot("badge-detail")
        audit("badge-detail")
        app.buttons["badge.done"].tap()
        XCTAssertFalse(element("badgeDetail").waitForExistence(timeout: 2))
        XCTAssertTrue(element("badge.green_thumb").exists)
    }

    func testUnderThirteenSeesNoShareButtonAndNoSharerBadge() {
        launch(["-uitest-age=under13"])
        openBadges()
        XCTAssertFalse(element("badge.sharer").exists, "sharing is hidden, so its badge is too")
        openGreenThumb()
        XCTAssertFalse(element("badge.share").waitForExistence(timeout: 2))
        shot("badge-detail-under13")
    }

    func testTheBadgesPageAndDetailAtAnAccessibilitySizeInDarkMode() {
        XCUIDevice.shared.appearance = .dark
        launch(size: Self.axSize)
        openBadges()
        sleep(1)
        shot("badges-ax-dark")
        audit("badges-ax-dark")
        openGreenThumb()
        sleep(1)
        shot("badge-detail-ax-dark")
        audit("badge-detail-ax-dark")
    }
}

import XCTest

/// Engagement quick wins (docs/pm/engagement-quick-wins.md): share age-gate parity (C), make it yours (B) and the
/// weekly garden note (A).
final class EngagementUITests: XCTestCase {
    var app: XCUIApplication!
    static let axXXXL = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        XCUIDevice.shared.appearance = .light
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.appearance = .light
    }

    private func launch(_ extra: [String]) {
        app.launchArguments = ["-uitest", "-uitest-onboarded"] + extra
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func tapLetters(_ letters: String) {
        for ch in letters { app.buttons[String(ch)].tap() }
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func audit(_ name: String) {
        var findings = [String]()
        shot("audit-\(name)")
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    /// Plays LOTUS (the only word in the UI test bank) to the win card.
    private func winAPlant(_ extra: [String] = []) {
        launch(["-uitest-word=LOTUS"] + extra)
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        tapLetters("LOTUS")
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6))
    }

    private func winTheDaily(_ extra: [String] = []) {
        launch(["-uitest-word=LOTUS", "-uitest-everything"] + extra)
        let daily = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Daily Bloom")).firstMatch
        XCTAssertTrue(daily.waitForExistence(timeout: 5))
        daily.tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        tapLetters("LOTUS")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 6))
    }

    // MARK: C. Share age-gate parity

    func testUnderThirteenWinCardHasNoShareButton() {
        winAPlant(["-uitest-age=under13"])
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Share this plant"].exists, "sharing leaves the app: hidden under 13")
        shot("c-win-under13")
    }

    func testAdultWinCardStillShares() {
        winAPlant()
        XCTAssertTrue(app.buttons["Share this plant"].waitForExistence(timeout: 3))
    }

    func testUnderThirteenDailyBloomHasNoShareButton() {
        winTheDaily(["-uitest-age=under13"])
        XCTAssertFalse(app.buttons["Share your Daily Bloom"].exists, "sharing leaves the app: hidden under 13")
    }

    func testAdultDailyBloomStillShares() {
        winTheDaily()
        XCTAssertTrue(app.buttons["Share your Daily Bloom"].waitForExistence(timeout: 3))
    }
}

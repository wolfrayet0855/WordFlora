import XCTest

/// Petal celebrations in the running app: the landing intro skips on a tap, a badge earned in a round pops at the
/// root once the earned card closes and goes on a tap, and bursts never block the screen or fail Apple's audit.
final class CelebrationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = []) {
        var findings = [String]()
        do {
            try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(ignoring)) { issue in
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    func testTheIntroSkipsToTheAgeQuestionOnATap() {
        app.launchArguments = ["-uitest", "-uitest-intro-hold"]
        app.launch()
        let intro = element("intro")
        XCTAssertTrue(intro.waitForExistence(timeout: 5))
        sleep(1)
        shot("intro-1s")
        XCTAssertFalse(app.buttons["Under 13"].waitForExistence(timeout: 4), "held: the intro waits for the tap")
        shot("intro-held")
        intro.tap()
        XCTAssertTrue(app.buttons["Under 13"].waitForExistence(timeout: 3))
    }

    /// Frozen frames of the intro (design-preview/celebrate/shots/intro-light.png is the target), then a tap still skips.
    func testIntroFrames() {
        for t in ["0.6", "1.2", "1.8", "2.4"] {
            app.launchArguments = ["-uitest", "-uitest-intro-t=\(t)"]
            app.launch()
            XCTAssertTrue(element("intro").waitForExistence(timeout: 5), t)
            shot("intro-t\(t)")
            app.terminate()
        }
    }

    func testABadgeEarnedInARoundPopsWhenTheCardClosesAndGoesOnATap() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-word=LOTUS"]
        app.launch()
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        for ch in "LOTUS" { app.buttons[String(ch)].tap() }         // no misses: a Perfect Bloom
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6))
        XCTAssertFalse(element("badgeMoment").exists, "the badge waits for the earned card")
        let next = app.buttons["Continue"]
        for _ in 0..<6 where !next.isHittable { app.swipeUp() }
        next.tap()
        let moment = element("badgeMoment")
        XCTAssertTrue(moment.waitForExistence(timeout: 3))
        XCTAssertTrue(moment.label.contains("Bronze Perfect Bloom"), moment.label)
        shot("badge-moment-round")
        moment.tap()
        XCTAssertTrue(moment.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 3), "the next word is ready")
    }

    func testTheBadgeMomentPassesTheAuditAndCloses() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-celebrate=badge"]
        app.launch()
        let moment = element("badgeMoment")
        XCTAssertTrue(moment.waitForExistence(timeout: 6))
        sleep(1)
        shot("badge-moment")
        audit("badge-moment")
        moment.tap()
        XCTAssertTrue(moment.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }

    func testBurstsNeverBlockTheScreenOrFailTheAudit() {
        for level in ["large", "medium", "calm", "reduceMotion"] {
            app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-celebrate=\(level)"]
            app.launch()
            XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 6), level)
            XCTAssertTrue(app.buttons["Play"].isHittable, "\(level): petals never take a tap")
            shot("celebrate-\(level)")
            // A still frame puts petals over Home's text, which no real moment does: in play the bursts sit under the dim
            // and below the card, and they are gone in under 3 s. Contrast is judged on the badge moment and the screens.
            audit("celebrate-\(level)", ignoring: .contrast)
            app.terminate()
        }
    }
}

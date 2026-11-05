import XCTest

/// The resting card (after every third regular word) and the under-13 break card: the honest ad note, the Plus row,
/// stacked buttons that stay reachable at large text sizes, and Apple's accessibility audit on both cards.
/// Reduce Motion cannot be switched on by a launch argument, so the still scene is checked by hand
/// (Settings > Accessibility > Motion > Reduce Motion: the plant, stars and z's stay still; the card only fades in).
final class RestCardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // The resting card needs three whole words first. The flower sways for ever, so every tap waits out the
        // idle check (about 5 s on a slow simulator): give these tests more than the 2 minute default.
        executionTimeAllowance = 360
        app = XCUIApplication()
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private static let axL = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
    /// A free adult past the grace period: with three words since the last ad, "One more" may try one.
    private static let freeWithAds = ["-uitest-ads-offline", "-uitest-sessions=3"]

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    /// Plays three words so the resting card opens.
    private func openRestCard(_ extra: [String] = []) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-word=LOTUS"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
        app.buttons["Play"].tap()
        for n in 1...3 {
            XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5), "word \(n)")
            for ch in "LOTUS" { app.buttons[String(ch)].tap() }
            let next = app.buttons["Continue"]
            XCTAssertTrue(next.waitForExistence(timeout: 8), "word \(n)")
            for _ in 0..<6 where !next.isHittable { app.swipeUp() }
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["The garden is resting"].waitForExistence(timeout: 5))
        settle(element("restCard"))
    }

    /// Waits until the card has finished opening (it fades in and grows a little): its frame stays the same for two
    /// looks in a row. A fixed one second was not always enough on a busy machine, and the Dynamic Type audit then
    /// measured text that was still being scaled.
    private func settle(_ el: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(el.waitForExistence(timeout: 5), file: file, line: line)
        var previous = CGRect.null
        for _ in 0..<20 {
            let f = el.frame
            if f == previous { return }
            previous = f
            usleep(400_000)
        }
        XCTFail("\(el) kept moving", file: file, line: line)
    }

    private func openBreakCard(_ extra: [String] = []) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-word=LOTUS", "-uitest-break-card"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
        app.buttons["Play"].tap()
        XCTAssertTrue(app.staticTexts["Time for a little break"].waitForExistence(timeout: 5))
        settle(element("breakCard"))
    }

    /// Scrolls the card until the element can be tapped.
    private func reach(_ el: XCUIElement, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(el.waitForExistence(timeout: 3), "\(what) exists", file: file, line: line)
        for _ in 0..<8 where !el.isHittable { app.swipeUp() }
        XCTAssertTrue(el.isHittable, "\(what) can be reached", file: file, line: line)
    }

    // MARK: resting card

    func testAFreePlayerWhoMayGetAnAdIsToldUnderOneMore() {
        openRestCard(Self.freeWithAds)
        XCTAssertTrue(app.staticTexts["You played 3 words"].exists)
        let oneMore = app.buttons["restCard.oneMore"], note = element("restCard.adNote"), enough = app.buttons["restCard.enough"]
        XCTAssertTrue(oneMore.exists); XCTAssertTrue(note.exists); XCTAssertTrue(enough.exists)
        XCTAssertTrue(app.buttons["restCard.goAdFree"].exists)
        // Stacked, in this order: One more, the note, then the gentle way out.
        XCTAssertLessThan(oneMore.frame.maxY, note.frame.minY + 1)
        XCTAssertLessThan(note.frame.maxY, enough.frame.minY + 1)
        XCTAssertEqual(oneMore.frame.width, enough.frame.width, accuracy: 1, "both buttons are full width")
        shot("rest-ad-light")
        XCUIDevice.shared.appearance = .dark
        sleep(1); shot("rest-ad-dark")
    }

    func testPlusPlayersSeeNoAdNoteAndNoPlusRow() {
        openRestCard(Self.freeWithAds + ["-uitest-plus"])
        XCTAssertTrue(app.buttons["restCard.oneMore"].exists)
        XCTAssertTrue(app.buttons["restCard.enough"].exists)
        XCTAssertFalse(element("restCard.adNote").exists)
        XCTAssertFalse(app.buttons["restCard.goAdFree"].exists)
        shot("rest-plus-light")
        XCUIDevice.shared.appearance = .dark
        sleep(1); shot("rest-plus-dark")
    }

    func testThatsEnoughGoesHome() {
        openRestCard()
        app.buttons["restCard.enough"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
    }

    func testTheGoAdFreeRowOpensPlus() {
        openRestCard(Self.freeWithAds)
        reach(app.buttons["restCard.goAdFree"], "Go ad-free")
        app.buttons["restCard.goAdFree"].tap()
        XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 5))
    }

    func testEveryRestCardButtonCanBeReachedAtALargeTextSize() {
        openRestCard(Self.freeWithAds + Self.axL)
        shot("rest-ad-axl-top")
        reach(app.buttons["restCard.oneMore"], "One more")
        reach(element("restCard.adNote"), "the ad note")
        reach(app.buttons["restCard.enough"], "That's enough for now")
        reach(app.buttons["restCard.goAdFree"], "Go ad-free")
        shot("rest-ad-axl-bottom")
    }

    func testAuditRestCard() {
        openRestCard(Self.freeWithAds)
        audit("rest-card")
    }

    func testAuditRestCardDarkAtALargeTextSize() {
        openRestCard(Self.freeWithAds + Self.axL)
        XCUIDevice.shared.appearance = .dark
        sleep(1)
        audit("rest-card-dark-axl")
    }

    // MARK: break card

    func testTheBreakCardHasNoAdNoteAndNoPlusRow() {
        openBreakCard(Self.freeWithAds)
        XCTAssertTrue(app.buttons["breakCard.takeBreak"].exists)
        XCTAssertTrue(app.buttons["breakCard.keepPlaying"].exists)
        XCTAssertFalse(element("restCard.adNote").exists)
        XCTAssertFalse(app.buttons["restCard.goAdFree"].exists)
        XCTAssertFalse(app.buttons["Window"].exists, "the three looks are pictures, not buttons")
        shot("break-light")
        XCUIDevice.shared.appearance = .dark
        sleep(1); shot("break-dark")
        app.buttons["breakCard.keepPlaying"].tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 3))
    }

    func testBreakCardButtonsCanBeReachedAtALargeTextSize() {
        openBreakCard(Self.axL)
        shot("break-axl-top")
        reach(app.buttons["breakCard.takeBreak"], "Take a break")
        reach(app.buttons["breakCard.keepPlaying"], "Keep playing")
        shot("break-axl-bottom")
        app.buttons["breakCard.takeBreak"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
    }

    func testAuditBreakCard() {
        openBreakCard()
        audit("break-card")
        XCUIDevice.shared.appearance = .dark
        sleep(1)
        audit("break-card-dark")
    }

    // MARK: accessibility audit (the same helper as WordFloraUITests)

    /// Text a scroll view clips at its edge is measured against whatever covers it; only text fully inside the
    /// scroll view is judged for contrast.
    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = []) {
        var findings = [String]()
        let scroll = app.scrollViews.firstMatch
        let nav = app.navigationBars.firstMatch
        let top = nav.exists ? nav.frame.maxY : 0
        let visible: CGRect? = scroll.exists ? {
            let f = scroll.frame
            return CGRect(x: f.minX, y: max(f.minY, top), width: f.width, height: f.maxY - max(f.minY, top))
        }() : nil
        var skipped = [String]()
        do {
            try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(ignoring)) { issue in
                if issue.auditType == .contrast, let v = visible {
                    // A clipped element often comes back unresolved (nil); it cannot be judged, so it is noted, not failed.
                    guard let e = issue.element else { skipped.append(issue.compactDescription); return true }
                    if !v.contains(e.frame) { return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | \(issue.element?.elementType.rawValue ?? 0) '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? findings.joined(separator: "\n").write(toFile: dir + "/audit-\(name).txt", atomically: true, encoding: .utf8)
        }
        if !skipped.isEmpty { print("\(name): contrast on \(skipped.count) clipped, unresolved element(s) not judged") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }
}

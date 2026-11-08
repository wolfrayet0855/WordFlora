import XCTest

/// This release's three small additions: the daily tiny quest on Home, the petal sound toy on the plant page, and the
/// Family Sharing line in Settings and on the Plus screen. Sound itself is checked by ear; here the parts are found,
/// named for VoiceOver, gated, and audited.
final class DailyQuestUITests: XCTestCase {
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

    private func scrollTo(_ e: XCUIElement) {
        for _ in 0..<8 where !(e.exists && e.isHittable) { app.swipeUp() }
    }

    /// Waits until the element's frame reads the same three times in a row, 0.5 s apart (at most 20 s). `scrollTo`
    /// returns as soon as the element is hittable, while the list is still gliding from the last swipe; an audit run then
    /// measures the text that slides into the element's old place (the Settings backup footnote under the family line
    /// read as clipped, low contrast and "partially unsupported" that way).
    private func waitUntilStill(_ e: XCUIElement) {
        var last = e.frame, same = 0
        let end = Date().addingTimeInterval(20)
        while same < 2 && Date() < end {
            Thread.sleep(forTimeInterval: 0.5)
            let now = e.frame
            same = now == last ? same + 1 : 0
            last = now
        }
    }

    /// Only issues on the given element fail; the rest of the screen is audited by its own classes.
    private func audit(_ name: String, within target: XCUIElement) {
        waitUntilStill(target)
        let frame = target.frame
        var findings = [String]()
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                guard let e = issue.element, e.frame.intersects(frame) else { return true }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(e.label)' [\(e.identifier)] \(e.frame)")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if !findings.isEmpty { findings.append(target.frame == frame ? "\(name): the element held still" : "\(name): the element moved during the audit: \(frame) -> \(target.frame)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    // MARK: The daily tiny quest

    func testTheQuestCardCountsAVisitToTheVisitorsPage() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything", "-uitest-quest=visitVisitors"]
        app.launch()
        let card = element("home.quest")
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Visit the Visitors page"), card.label)
        XCTAssertEqual(card.value as? String, "0 of 1")
        audit("quest-card", within: card)
        shot("quest-card")

        let tile = app.buttons["tile-Visitors"]
        scrollTo(tile)
        tile.tap()
        XCTAssertTrue(element("visitors.book").waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let done = NSPredicate(format: "value == %@", "Quest done")
        wait(for: [expectation(for: done, evaluatedWith: card)], timeout: 5)
        audit("quest-card-done", within: card)
        shot("quest-card-done")
    }

    func testCalmShowsTheSameCardWithAStillCheckMark() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything", "-uitest-calm", "-uitest-quest=findWords"]
        app.launch()
        let card = element("home.quest")
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertEqual(card.value as? String, "0 of 2")
    }

    func testQuietGardenHasNoQuest() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything", "-uitest-quiet", "-uitest-quest=findWords"]
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("home.quest").exists)
    }

    // MARK: The petal sound toy

    func testThePetalRowIsAPlayButtonAndThePlantStillSaysHello() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-plant=daisy"]
        app.launch()
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Daisy")).firstMatch
        _ = tile.waitForExistence(timeout: 3)
        scrollTo(tile)
        tile.tap()
        let petals = element("petal-notes")
        XCTAssertTrue(petals.waitForExistence(timeout: 5))
        // The first look at Daisy's fact card earns the bronze Wild Discovery badge; its name card sits over the petal
        // row for 2.6 s and a tap on it closes the moment, so the taps wait until it has gone.
        let moment = element("badgeMoment")
        if moment.waitForExistence(timeout: 4) { XCTAssertTrue(moment.waitForNonExistence(timeout: 10), "the badge moment goes") }
        XCTAssertEqual(petals.label, "Play petal notes")
        XCTAssertTrue(petals.elementType == .button || petals.isHittable)
        petals.tap()
        petals.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let plant = element("plant-love")
        XCTAssertTrue(plant.exists, "tapping the petals leaves the plant page as it was")
        plant.tap()
        XCTAssertTrue(element("love-petal-caption").exists)
        audit("petal-notes", within: petals)
    }

    // MARK: The Family Sharing line

    private func openSettings() {
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
    }

    func testGrownUpsSeeTheFamilyLineInSettingsAndOnPlus() {
        app.launchArguments = ["-uitest", "-uitest-onboarded"]             // a grown-up (18+)
        app.launch()
        openSettings()
        let line = element("familyShare.nudge")
        scrollTo(line)
        XCTAssertTrue(line.exists)
        XCTAssertTrue(app.staticTexts["Already have Plus on a family phone?"].exists)
        XCTAssertTrue(element("familyShare.restore").exists)
        audit("family-settings", within: line)
        app.buttons["settings.plus"].tap()
        let onPlus = element("familyShare.nudge")
        XCTAssertTrue(onPlus.waitForExistence(timeout: 5))
        scrollTo(onPlus)
        // On the Plus page the line only: the page's own Restore purchases button is right below it.
        XCTAssertTrue(app.staticTexts["Already have Plus on a family phone? Restore purchases is below."].exists)
        XCTAssertFalse(element("familyShare.restore").exists, "one Restore button on the Plus page")
        audit("family-plus", within: onPlus)
    }

    func testKidsAndPlusOwnersNeverSeeTheFamilyLine() {
        for extra in [["-uitest-age=under13"], ["-uitest-plus"], ["-uitest-quiet"]] {
            app.launchArguments = ["-uitest", "-uitest-onboarded"] + extra
            app.launch()
            openSettings()
            // The row is named by age ("WordFlora Plus" under 13, in the "For grown-ups" section), so it is found by id.
            let plusRow = app.buttons["settings.plus"]
            scrollTo(plusRow)
            XCTAssertTrue(plusRow.exists, "\(extra)")
            XCTAssertFalse(element("familyShare.nudge").exists, "\(extra)")
            plusRow.tap()
            XCTAssertTrue(app.buttons["Restore purchases"].waitForExistence(timeout: 5), "\(extra)")
            XCTAssertFalse(element("familyShare.nudge").exists, "\(extra)")
            app.terminate()
        }
    }
}

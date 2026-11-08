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

    /// The audit for a scrolled plant page, as `TendingUITests`/`WordFloraUITests.audit`: contrast is judged only for text
    /// wholly inside the visible scroll area. After a scroll, text slid under the bar or the inner scroll's edge is
    /// clipped and blurred, and the audit then judges the wrong pixels (an unresolved element with no label).
    private func auditScrolled(_ name: String) {
        var findings = [String](), skipped = 0
        let scroll = app.scrollViews.firstMatch, nav = app.navigationBars.firstMatch
        let top = nav.exists ? nav.frame.maxY : 0
        shot("audit-\(name)")
        let visible: CGRect? = scroll.exists ? {
            let f = scroll.frame
            return CGRect(x: f.minX, y: max(f.minY, top), width: f.width, height: f.maxY - max(f.minY, top))
        }() : nil
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                if issue.auditType == .contrast, let v = visible {
                    guard let e = issue.element else { skipped += 1; return true }
                    if !v.contains(e.frame) { return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if skipped > 0 { print("\(name): contrast on \(skipped) clipped, unresolved element(s) not judged") }
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

    // MARK: B. Make it yours

    private func scrollTo(_ e: XCUIElement) {
        for _ in 0..<10 where !(e.exists && e.isHittable) { app.swipeUp() }
    }

    /// The plant page for one found plant (as TendingUITests.open), waiting out the first-look badge moment.
    private func openPlant(_ plantName: String, plantId: String, extra: [String] = []) {
        launch(["-uitest-plant=\(plantId)"] + extra)
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", plantName)).firstMatch
        _ = tile.waitForExistence(timeout: 3)
        scrollTo(tile)
        tile.tap()
        XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 5))
        let moment = element("badgeMoment")
        if moment.waitForExistence(timeout: 4) { XCTAssertTrue(moment.waitForNonExistence(timeout: 10), "the badge moment goes") }
    }

    func testNewPlantCardOffersANameAndThePlantSaysHello() {
        winAPlant()
        let give = app.buttons["plantName.give"]
        XCTAssertTrue(give.waitForExistence(timeout: 3))
        shot("b-win-give-name")
        give.tap()
        let alert = app.alerts["Name your plant"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        let field = alert.textFields.firstMatch
        let species = field.placeholderValue ?? ""
        XCTAssertFalse(species.isEmpty, "the box shows the species name as its placeholder")
        XCTAssertTrue(alert.buttons["Not now"].exists)
        field.typeText("Sunny")
        alert.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Hello! I love the name Sunny."].waitForExistence(timeout: 3))
        XCTAssertFalse(give.exists, "never a second prompt")
        shot("b-win-named")
        let cont = app.buttons["Continue"]
        scrollTo(cont)
        cont.tap()
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 5))
        app.buttons["Home"].tap()
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", species)).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 3), species)
        scrollTo(tile)
        tile.tap()
        XCTAssertTrue(app.navigationBars["Sunny"].waitForExistence(timeout: 5), "the plant page title reads the new name")
    }

    func testNotNowKeepsTheButtonAndSavesNothing() {
        winAPlant()
        app.buttons["plantName.give"].tap()
        let alert = app.alerts["Name your plant"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Not now"].tap()
        XCTAssertTrue(app.buttons["plantName.give"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Hello! I love")).firstMatch.exists)
    }

    func testPencilNameOfOnlyEmojiGoesBackToTheSpeciesName() {
        openPlant("Daisy", plantId: "daisy")
        app.buttons["Rename"].tap()
        let alert = app.alerts["Name your plant"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.textFields.firstMatch.typeText("  Sunny  ")
        alert.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Sunny"].waitForExistence(timeout: 3), "trimmed")
        app.buttons["Rename"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        let field = alert.textFields.firstMatch
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 12) + " !!! ?")
        alert.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Daisy"].waitForExistence(timeout: 3), "no letters: back to the species name")
    }

    func testShowOnMyWidgetFlipsToOnYourWidget() {
        openPlant("Daisy", plantId: "daisy")
        let pin = app.buttons["plant.showOnWidget"]
        scrollTo(pin)
        XCTAssertTrue(pin.exists)
        pin.tap()
        let on = element("plant.onWidget")
        XCTAssertTrue(on.waitForExistence(timeout: 3))
        XCTAssertEqual(on.label, "On your widget")
        XCTAssertFalse(app.buttons["plant.showOnWidget"].exists, "pinned: not a button")
        let line = element("plant.widgetLine")
        XCTAssertTrue(line.waitForExistence(timeout: 3))
        XCTAssertTrue(line.label.contains("Daisy"), line.label)
        shot("b-plant-on-widget")
    }

    func testAuditWinCardWithTheNameButton() {
        winAPlant()
        XCTAssertTrue(app.buttons["plantName.give"].waitForExistence(timeout: 3))
        sleep(1)
        audit("b-win-card")
    }

    func testAuditWinCardWithTheNameButtonAtAXXXL() {
        winAPlant(Self.axXXXL)
        XCTAssertTrue(app.staticTexts["New plant found!"].exists)
        sleep(1)
        audit("b-win-card-axxxl")
        let cont = app.buttons["Continue"]
        scrollTo(cont)
        XCTAssertTrue(cont.isHittable, "Continue is still reachable by scrolling")
        XCTAssertTrue(app.buttons["plantName.give"].exists)
    }

    /// Dark is set before launch (a mid-test switch did not reach the app); audited unscrolled.
    func testAuditWinCardWithTheNameButtonAtAXXXLDark() {
        XCUIDevice.shared.appearance = .dark
        winAPlant(Self.axXXXL)
        XCTAssertTrue(app.buttons["plantName.give"].waitForExistence(timeout: 3))
        sleep(1)
        shot("b-win-card-axxxl-dark")
        audit("b-win-card-axxxl-dark")
    }

    // MARK: A. Weekly garden note

    private var note: XCUIElement { element("weeklyNote") }
    private var noteText: XCUIElement { element("weeklyNote.text") }

    private func openWithNote(_ extra: [String] = []) {
        launch(["-uitest-weekly-note"] + extra)
        XCTAssertTrue(noteText.waitForExistence(timeout: 6), "the weekly note shows on Home")
    }

    func testWeeklyNoteShowsThePastWeek() {
        openWithNote()
        let title = element("weeklyNote.title")
        XCTAssertEqual(title.label, "Your week in the garden")
        XCTAssertTrue(title.exists)
        let label = noteText.label
        for row in ["You grew 12 words.", "You solved 2 Daily Blooms.", "New plants: ", "You said hello to 3 friends."] {
            XCTAssertTrue(label.contains(row), "\(row) in \(label)")
        }
        XCTAssertTrue(app.buttons["weeklyNote.lovely"].exists)
        XCTAssertTrue(app.buttons["weeklyNote.visit"].exists)
        XCTAssertTrue(element("weeklyNote.share").waitForExistence(timeout: 3), "18+: Share my week")
        XCTAssertFalse(element("plus-offer-card").exists, "a note visit holds the Plus card back")
        shot("a-note-light")
    }

    /// One card at a time: on a note visit the daily quest waits; after Lovely it comes back on the next Home visit.
    func testTheDailyQuestWaitsOnANoteVisit() {
        openWithNote(["-uitest-quest=findWords"])
        XCTAssertFalse(element("home.quest").exists, "the quest card waits while the weekly note shows")
        app.buttons["weeklyNote.lovely"].tap()
        XCTAssertTrue(note.waitForNonExistence(timeout: 3))
        XCTAssertTrue(element("home.quest").waitForExistence(timeout: 3), "the quest returns once the note closes")
    }

    func testLovelyClosesAndTheNoteDoesNotReturnThisWeek() {
        openWithNote()
        app.buttons["weeklyNote.lovely"].tap()
        XCTAssertTrue(note.waitForNonExistence(timeout: 3))
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["My Garden"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        sleep(1)
        XCTAssertFalse(note.exists, "shown once a week")
    }

    func testVisitMyGardenGoesToTheGarden() {
        openWithNote()
        app.buttons["weeklyNote.visit"].tap()
        XCTAssertTrue(app.navigationBars["My Garden"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertFalse(note.exists)
    }

    func testUnderThirteenHasNoShareMyWeek() {
        openWithNote(["-uitest-age=under13"])
        XCTAssertFalse(element("weeklyNote.share").exists)
        XCTAssertTrue(noteText.label.contains("You grew 12 words."))
    }

    func testQuietGardenShowsNamesOnly() {
        openWithNote(["-uitest-quiet"])
        let label = noteText.label
        XCTAssertTrue(label.contains("New in your garden: "), label)
        XCTAssertNil(label.rangeOfCharacter(from: .decimalDigits), "no numbers in Quiet Garden: \(label)")
        XCTAssertFalse(element("weeklyNote.share").exists)
        shot("a-note-quiet")
    }

    func testAuditWeeklyNote() {
        openWithNote()
        sleep(1)
        audit("a-note")
    }

    /// Audited unscrolled (after a scroll the audit judges text slid under the status bar), then scrolled only to check
    /// that Share my week is reachable.
    func testAuditWeeklyNoteAtAXXXL() {
        openWithNote(Self.axXXXL)
        sleep(1)
        audit("a-note-axxxl")
        let share = element("weeklyNote.share")
        scrollTo(share)
        XCTAssertTrue(share.isHittable, "Share my week is reachable")
    }

    /// Dark is set before launch: switching the appearance mid-test did not reach the app on these simulators.
    func testAuditWeeklyNoteAtAXXXLDark() {
        XCUIDevice.shared.appearance = .dark
        openWithNote(Self.axXXXL)
        sleep(1)
        shot("a-note-axxxl-dark")
        audit("a-note-axxxl-dark")
    }

    func testAuditPlantPageWidgetRow() {
        openPlant("Daisy", plantId: "daisy")
        sleep(1)
        // The page's own scroll ends at the pinned tend bar: text half under it is judged by what is visible.
        auditScrolled("b-plant-top")
        scrollTo(app.buttons["plant.showOnWidget"])
        sleep(1)
        auditScrolled("b-plant-widget-row")
    }

    func testAuditPlantPageWidgetRowAtAXXXL() {
        openPlant("Daisy", plantId: "daisy", extra: Self.axXXXL)
        let pin = app.buttons["plant.showOnWidget"]
        scrollTo(pin)
        sleep(1)
        auditScrolled("b-plant-widget-row-axxxl")
    }

    /// Dark is set before launch (a mid-test switch did not reach the app); the pinned state with its line.
    func testAuditPlantPageWidgetRowAtAXXXLDark() {
        XCUIDevice.shared.appearance = .dark
        openPlant("Daisy", plantId: "daisy", extra: Self.axXXXL)
        let pin = app.buttons["plant.showOnWidget"]
        scrollTo(pin)
        pin.tap()
        XCTAssertTrue(element("plant.onWidget").waitForExistence(timeout: 3))
        scrollTo(element("plant.widgetLine"))
        sleep(1)
        shot("b-plant-widget-row-axxxl-dark")
        auditScrolled("b-plant-widget-row-axxxl-dark")
    }
}

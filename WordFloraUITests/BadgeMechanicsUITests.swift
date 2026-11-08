import XCTest

/// Field Notes and Pruning Pro on screen (gate G1): the notebook page and its "I read it!" stamp, the faded bloom cue and
/// its tidy trim, each badge moment, and Apple's accessibility audit at AX XXXL in dark mode.
/// Fixtures: `-uitest-fieldnotes` and `-uitest-tidytrim` in WordFloraApp.
final class BadgeMechanicsUITests: XCTestCase {
    var app: XCUIApplication!
    static let axXXXL = "UICTContentSizeCategoryAccessibilityXXXL"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private func launch(_ extra: [String], size: String? = nil, dark: Bool = false) {
        if dark { XCUIDevice.shared.appearance = .dark }
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything"] + extra
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func scrollTo(_ e: XCUIElement, up: Bool = false) {
        for _ in 0..<14 where !(e.exists && e.isHittable) { up ? app.swipeDown() : app.swipeUp() }
    }

    private func letTheBadgeMomentPass() {
        let moment = element("badgeMoment")
        if moment.waitForExistence(timeout: 4) { XCTAssertTrue(moment.waitForNonExistence(timeout: 10), "the badge moment goes") }
    }

    /// Apple's audit, every finding collected. Contrast and Dynamic Type are judged only for elements fully inside the
    /// visible scroll area (text cut by a scroll edge is measured against what covers it), as in EndgameUITests; the
    /// Dynamic Type and clipped-text checks run on their own after the rest, since they grow the text and reflow the page.
    private func audit(_ name: String) {
        auditOnce(name, types: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped]))
        auditOnce(name + "-textClipped", types: .textClipped)
        auditOnce(name + "-dynamicType", types: .dynamicType)
    }

    private func auditOnce(_ name: String, types: XCUIAccessibilityAuditType) {
        var findings = [String]()
        let scroll = app.scrollViews.firstMatch
        let bar = app.navigationBars.firstMatch
        let top = bar.exists ? bar.frame.maxY + 64 : 0
        let visible: CGRect? = scroll.exists
            ? CGRect(x: scroll.frame.minX, y: max(scroll.frame.minY, top), width: scroll.frame.width, height: scroll.frame.maxY - max(scroll.frame.minY, top))
            : nil
        do {
            try app.performAccessibilityAudit(for: types) { issue in
                if [.contrast, .dynamicType].contains(issue.auditType), let v = visible {
                    guard let e = issue.element else { print("\(name): unresolved \(issue.compactDescription), not judged"); return true }
                    if !v.contains(e.frame) { print("\(name): outside the visible area, not judged: '\(e.label)'"); return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func openBook() {
        app.buttons["tile-Visitors"].tap()
        let book = app.buttons["visitors.book"]
        XCTAssertTrue(book.waitForExistence(timeout: 5))
        scrollTo(book)
        book.tap()
        XCTAssertTrue(element("book.page.monarch").waitForExistence(timeout: 5))
    }

    // MARK: Field Notes

    /// Opening the book never stamps a page; "I read it!" does, once, with the Page added line and then the bronze moment.
    func testIReadItStampsThePageAndEarnsFieldNotes() {
        launch(["-uitest-fieldnotes"])
        openBook()
        XCTAssertEqual(element("book.notebookCount").label, "My field notes: 3 pages of 12", "opening the book marks nothing")
        let page = element("book.page.monarch")
        XCTAssertTrue(page.label.hasPrefix("Monarch. Met on "), page.label)
        XCTAssertFalse(page.label.contains("Leaf stamp"))
        XCTAssertTrue(element("book.stamped.ladybug").exists, "pages stamped before keep their stamp")
        XCTAssertTrue(app.buttons["book.listen.monarch"].exists)
        let readIt = app.buttons["book.readIt.monarch"]
        scrollTo(readIt)
        shot("fieldnotes-page")
        readIt.tap()
        // The Page added line comes first; the badge moment follows it (it stays 2.6 s, so it is checked at once).
        XCTAssertTrue(element("book.toast").waitForExistence(timeout: 3))
        XCTAssertEqual(element("book.toast").label, "Page added to your notebook.")
        let moment = element("badgeMoment")
        XCTAssertTrue(moment.waitForExistence(timeout: 6), "four pages earn the bronze Field Notes badge")
        XCTAssertTrue(moment.label.contains("Field Notes"), moment.label)
        shot("fieldnotes-badge-moment")
        letTheBadgeMomentPass()
        XCTAssertTrue(element("book.stamped.monarch").waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["book.readIt.monarch"].exists, "a stamped page cannot be stamped again")
        XCTAssertTrue(element("book.stamp.monarch").exists)
        XCTAssertTrue(element("book.page.monarch").label.hasSuffix("Leaf stamp."), element("book.page.monarch").label)
        shot("fieldnotes-stamped")
        scrollTo(element("book.notebookCount"), up: true)
        XCTAssertEqual(element("book.notebookCount").label, "My field notes: 4 pages of 12")
    }

    func testQuietGardenHidesIReadItAndTheCount() {
        launch(["-uitest-fieldnotes", "-uitest-quiet"])
        openBook()
        XCTAssertFalse(element("book.notebookCount").exists)
        XCTAssertFalse(app.buttons["book.readIt.monarch"].exists)
        XCTAssertTrue(app.buttons["book.listen.monarch"].exists, "Listen still works")
        XCTAssertFalse(element("book.stamped.ladybug").exists, "no Stamped state in Quiet Garden")
    }

    func testAuditTheNotebookAtAXXXLInDark() {
        launch(["-uitest-fieldnotes"], size: Self.axXXXL, dark: true)
        openBook()
        let readIt = app.buttons["book.readIt.monarch"]
        scrollTo(readIt)
        shot("fieldnotes-ax5-dark")
        audit("fieldnotes-ax5-dark")
        readIt.tap()
        XCTAssertTrue(element("book.stamped.monarch").waitForExistence(timeout: 3))
        letTheBadgeMomentPass()
        sleep(2)                                   // the Page added line has gone
        scrollTo(element("book.stamp.monarch"))
        shot("fieldnotes-ax5-dark-stamped")
        audit("fieldnotes-ax5-dark-stamped")
    }

    // MARK: Pruning Pro

    private func openPlant(_ extra: [String] = [], size: String? = nil, dark: Bool = false) {
        launch(["-uitest-plant=clover", "-uitest-tidytrim"] + extra, size: size, dark: dark)
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        XCTAssertTrue(tile.label.hasSuffix("ready for a trim"), "the garden card carries the cue: \(tile.label)")
        for _ in 0..<10 where !tile.isHittable { app.swipeUp() }
        tile.tap()
        XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 5))
        letTheBadgeMomentPass()                    // the first look at the fact card earns Wild Discovery
    }

    func testAFadedBloomCueThenATidyTrimEarnsPruningPro() {
        openPlant()
        let cue = element("plant.tidyCue")
        XCTAssertTrue(cue.waitForExistence(timeout: 3))
        XCTAssertEqual(cue.label, "A faded flower is ready for a snip.")
        XCTAssertTrue(element("plant-love").label.hasSuffix(", ready for a trim"), element("plant-love").label)
        let prune = app.buttons["tend-prune"]
        XCTAssertTrue(prune.exists)
        shot("tidytrim-cue")
        prune.tap()
        let toast = element("tend-toast")
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
        XCTAssertTrue(toast.label.contains("Snip! A tidy trim. Snipping faded flowers helps new ones grow."), toast.label)
        // The moment follows the line and stays 2.6 s, so it is checked at once.
        let moment = element("badgeMoment")
        XCTAssertTrue(moment.waitForExistence(timeout: 6), "a fifth tidy trim earns the bronze Pruning Pro badge")
        XCTAssertTrue(moment.label.contains("Pruning Pro"), moment.label)
        shot("tidytrim-badge-moment")
        letTheBadgeMomentPass()
        XCTAssertFalse(cue.exists, "the trim starts the shears' rest, so the cue goes")
        XCTAssertFalse(element("plant-love").label.contains("ready for a trim"))
        shot("tidytrim-snipped")
    }

    // MARK: Mist Maker (G3, `-uitest-mist`: the mister owned, nine mists already)

    private func openFern(size: String? = nil, dark: Bool = false) {
        if dark { XCUIDevice.shared.appearance = .dark }
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-plant=fern", "-uitest-mist"]
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Fern'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        for _ in 0..<10 where !tile.isHittable { app.swipeUp() }
        tile.tap()
        XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 5))
        letTheBadgeMomentPass()
    }

    func testMistAFernEarnsMistMakerAndIsMistyToday() {
        openFern()
        let mist = app.buttons["tend-mist"]
        XCTAssertTrue(mist.exists, "the Mist button shows with the mister")
        XCTAssertEqual(mist.label, "Mist Fern")
        let prune = app.buttons["tend-prune"], repot = app.buttons["tend-repot"]
        if prune.exists { XCTAssertLessThan(prune.frame.minX, mist.frame.minX, "Mist sits after Prune") }
        XCTAssertLessThan(mist.frame.minX, repot.frame.minX, "and before Repot")
        XCTAssertTrue(element("mist-tip").exists, "the tip shows the first time")
        XCTAssertEqual(element("mist-tip").label, "Some plants love a little mist on their leaves.")
        mist.tap()
        let toast = element("tend-toast")
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
        XCTAssertTrue(toast.label.contains("Fern loves misty air!") || toast.label.contains("grew a little"), toast.label)
        let moment = element("badgeMoment")
        XCTAssertTrue(moment.waitForExistence(timeout: 6), "a tenth mist earns the bronze Mist Maker badge")
        XCTAssertTrue(moment.label.contains("Mist Maker"), moment.label)
        shot("mist-badge-moment")
        letTheBadgeMomentPass()
        XCTAssertEqual(mist.label, "Fern is misty today")
        mist.tap()
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
        XCTAssertTrue(toast.label.contains("Fern is fresh and misty today. More mist tomorrow!"), toast.label)
        shot("mist-done")
    }

    /// AX XXXL dark: the tend buttons are full-width tiles in the page (TendRowLayout); Mist passes the audit.
    func testAuditTheMistButtonAtAXXXLInDark() {
        openFern(size: Self.axXXXL, dark: true)
        let mist = app.buttons["tend-mist"]
        // Big tiles: scroll gently until the whole Mist tile sits inside the scroll area (a full swipe can jump past it).
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<12 where !(mist.isHittable && mist.frame.minY >= scroll.frame.minY && mist.frame.maxY <= scroll.frame.maxY) {
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            let step: CGFloat = mist.frame.minY < scroll.frame.minY ? 160 : -160
            start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: step)))
            sleep(1)
        }
        XCTAssertTrue(mist.isHittable)
        XCTAssertGreaterThanOrEqual(mist.frame.height, 44)
        let screen = app.windows.firstMatch.frame
        XCTAssertLessThanOrEqual(mist.frame.maxX, screen.maxX)
        shot("mist-ax5-dark")
        audit("mist-ax5-dark")
        mist.tap()
        sleep(3)
        audit("mist-ax5-dark-done")
    }

    func testAuditTheMistButtonAtAccessibilityLLight() {
        openFern(size: "UICTContentSizeCategoryAccessibilityL")
        let mist = app.buttons["tend-mist"]
        scrollTo(mist)
        XCTAssertTrue(mist.isHittable)
        shot("mist-axl-light")
        audit("mist-axl-light")
    }

    func testAuditTheTidyTrimCueAtAXXXLInDark() {
        openPlant(size: Self.axXXXL, dark: true)
        let cue = element("plant.tidyCue")
        scrollTo(cue)
        XCTAssertTrue(cue.exists)
        shot("tidytrim-ax5-dark")
        audit("tidytrim-ax5-dark")
    }
}

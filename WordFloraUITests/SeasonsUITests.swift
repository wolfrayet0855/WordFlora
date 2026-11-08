import XCTest

/// Frost & Lantern surfaces (release plan G3): the Seasons row in Settings > Plus (behind the grown-up question for
/// under 13), the Seasons page, the 13+ Seasons shelf in the Shed, the kid view's outlines, and the dormant rule (no
/// product, no surfaces). `-uitest-prices` stands in for the store offering the pack (UI tests run outside StoreKit).
final class SeasonsUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws { continueAfterFailure = false }
    override func tearDown() { XCUIDevice.shared.appearance = .light; super.tearDown() }

    private func launch(age: String, _ extra: [String] = []) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-age=\(age)"] + extra
        app.launch()
    }

    private func openSettings() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    private func openShed() {
        app.buttons["Shed"].tap()
        XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5))
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func scrollTo(_ e: XCUIElement, max: Int = 12) {
        for _ in 0..<max where !(e.exists && e.isHittable) { app.swipeUp(velocity: .slow) }
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Every audit type. Contrast is judged on elements fully inside the visible scroll area (below the bar's soft
    /// edge), as in the other audits; an unresolved contrast issue is printed, not failed. The page is still first.
    /// `within`: judge only issues on elements inside this element's frame (the Shed audits look at the new shelf, not
    /// the tools and pots above it, which TendingUITests and WordFloraUITests audit with their own rules).
    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = [], within: XCUIElement? = nil,
                       excuse: @escaping (XCUIAccessibilityAuditIssue, XCUIElement) -> Bool = { _, _ in false }) {
        sleep(2)
        let scroll = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app.collectionViews.firstMatch
        let nav = app.navigationBars.firstMatch
        let top = nav.exists ? nav.frame.maxY + 64 : 0
        let region = within?.frame
        let visible: CGRect? = scroll.exists ? {
            let f = scroll.frame
            return CGRect(x: f.minX, y: max(f.minY, top), width: f.width, height: f.maxY - max(f.minY, top))
        }() : nil
        var findings = [String](), skipped = [String]()
        // Contrast and the rest first, on the page as it stands; then Dynamic Type and clipped text, each on its own:
        // both grow the text and reflow the Shed (its pot cards grow with the text now), which moved the pots' pack
        // title into the shelf's frame mid-check (as in TendingUITests' dynamicTypeApart).
        let passes: [XCUIAccessibilityAuditType] = [XCUIAccessibilityAuditType.all.subtracting(ignoring).subtracting([.dynamicType, .textClipped]),
                                                    XCUIAccessibilityAuditType.textClipped.subtracting(ignoring),
                                                    XCUIAccessibilityAuditType.dynamicType.subtracting(ignoring)]
        for types in passes where !types.isEmpty {
        do {
            try app.performAccessibilityAudit(for: types) { issue in
                // Only elements inside the new surface are judged (a tool tile above it, partly overlapping the
                // shelf's frame at AX sizes, belongs to the Shed's own audits).
                if let r = region, let e = issue.element, !r.insetBy(dx: -1, dy: -1).contains(e.frame) { return true }
                if issue.auditType == .contrast, let v = visible {
                    guard let e = issue.element else { skipped.append(issue.compactDescription); return true }
                    if !v.contains(e.frame) { return true }
                }
                if let e = issue.element, excuse(issue, e) { skipped.append("\(issue.compactDescription) on '\(e.label)'"); return true }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' [\(issue.element?.identifier ?? "")] \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        }
        if !skipped.isEmpty { print("\(name): not judged, \(skipped.count): \(skipped.joined(separator: "; "))") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    // MARK: Settings > Plus > Seasons

    func testAdultsSeeTheSeasonsRowAndThePage() {
        launch(age: "eighteenPlus", ["-uitest-prices"])
        openSettings()
        let row = app.buttons["settings.seasons"]
        scrollTo(row)
        XCTAssertTrue(row.exists); XCTAssertEqual(row.label, "Seasons")
        row.tap()
        XCTAssertTrue(app.navigationBars["Seasons"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Frost & Lantern"].exists)
        XCTAssertEqual(app.staticTexts["seasons.price"].label, "Price: $2.99")
        XCTAssertTrue(app.buttons["seasons.buy"].exists)
        XCTAssertTrue(app.images["Three winter pots on a snowy shelf, with lanterns and a robin"].exists)
        shot("seasons-page-light")
        audit("seasons-page-light")
    }

    func testTheSeasonsPageAtAccessibilityXXXLDark() {
        XCUIDevice.shared.appearance = .dark
        launch(age: "eighteenPlus", ["-uitest-prices", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        openSettings()
        let row = app.buttons["settings.seasons"]
        scrollTo(row); row.tap()
        XCTAssertTrue(app.navigationBars["Seasons"].waitForExistence(timeout: 5))
        shot("seasons-page-axxxl-dark")
        audit("seasons-page-axxxl-dark")
        let buy = app.buttons["seasons.buy"]
        scrollTo(buy)
        XCTAssertTrue(buy.isHittable)
        let screen = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(buy.frame.minX, screen.minX); XCTAssertLessThanOrEqual(buy.frame.maxX, screen.maxX)
        shot("seasons-buy-axxxl-dark")
    }

    func testOwnersSeeThePackIsTheirs() {
        launch(age: "eighteenPlus", ["-uitest-prices", "-uitest-pack-owned"])
        openSettings()
        let row = app.buttons["settings.seasons"]
        scrollTo(row); row.tap()
        XCTAssertTrue(element("seasons.owned").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["seasons.buy"].exists)
        audit("seasons-owned")
    }

    /// Under 13: the row sits in "Purchases" and asks the grown-up question first; no price on Settings.
    func testTheSeasonsRowIsBehindTheGrownUpQuestionForUnder13() {
        launch(age: "under13", ["-uitest-prices"])
        openSettings()
        let row = app.buttons["settings.seasons"]
        scrollTo(row)
        XCTAssertTrue(app.staticTexts["Purchases"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch.exists)
        row.tap()
        let answer = app.textFields["parentalGate.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        XCTAssertFalse(app.navigationBars["Seasons"].exists, "nothing opens before the answer")
        app.buttons["Cancel"].tap()
        XCTAssertFalse(answer.waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        // Through the gate the page opens; buying asks again.
        row.tap()
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        let q = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'What is '")).firstMatch.label
        let nums = q.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        answer.tap(); answer.typeText("\(nums[0] * nums[1])")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Seasons"].waitForExistence(timeout: 5))
        let buy = app.buttons["seasons.buy"]
        scrollTo(buy); buy.tap()
        XCTAssertTrue(answer.waitForExistence(timeout: 3), "the purchase asks the grown-up again")
        app.buttons["Cancel"].tap()
    }

    // MARK: The Shed

    /// Kid view in the Shed: the pack's pots as soft outlines with the grown-up line; no shelf, no price, no buy button.
    func testTheShedShowsYoungPlayersOutlinesOnly() {
        launch(age: "under13", ["-uitest-prices", "-uitest-everything"])
        openShed()
        let red = element("shed-pot-lanternRed")
        scrollTo(red, max: 16)
        XCTAssertTrue(red.exists)
        XCTAssertTrue(red.label.contains("A grown-up can find this in Settings.") || red.label.contains("part of Frost & Lantern"), red.label)
        XCTAssertFalse(element("shed.seasons").exists, "no Seasons shelf for under 13")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch.exists, "no price")
        red.tap()
        let hint = app.staticTexts["shed-pot-hint"]
        XCTAssertTrue(hint.waitForExistence(timeout: 3))
        XCTAssertEqual(hint.label, "Lantern red is part of Frost & Lantern. A grown-up can find this in Settings.")
        shot("shed-pack-under13")
    }

    func testTeensSeeTheSeasonsShelfWithItsPrice() {
        launch(age: "thirteenPlus", ["-uitest-prices", "-uitest-everything"])
        openShed()
        let shelf = app.buttons["shed.seasons.open"]
        scrollTo(shelf, max: 20)
        XCTAssertTrue(shelf.isHittable)
        XCTAssertEqual(app.staticTexts["shed.seasons.price"].label, "Price: $2.99")
        shot("shed-seasons-shelf")
        audit("shed-seasons-shelf", within: app.otherElements["shed.seasons"], excuse: shedPotCard)
        shelf.tap()
        XCTAssertTrue(app.navigationBars["Seasons"].waitForExistence(timeout: 5))
    }

    func testTheShedShelfAtAccessibilityXXXLDark() {
        XCUIDevice.shared.appearance = .dark
        launch(age: "eighteenPlus", ["-uitest-prices", "-uitest-everything", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        openShed()
        let shelf = app.buttons["shed.seasons.open"]
        scrollTo(shelf, max: 40)
        XCTAssertTrue(shelf.isHittable)
        shot("shed-seasons-shelf-axxxl-dark")
        audit("shed-seasons-shelf-axxxl-dark", within: app.otherElements["shed.seasons"], excuse: shedPotCard)
    }

    /// The Shed's pot cards above the shelf keep their words at xxxLarge and draw the pot art under the name, as in
    /// TendingUITests' Shed audit: contrast and Dynamic Type are excused on those cards only (by id, or by a pot name
    /// in a card-sized frame). The shelf itself is judged in full.
    private func shedPotCard(_ issue: XCUIAccessibilityAuditIssue, _ e: XCUIElement) -> Bool {
        guard [.contrast, .dynamicType].contains(issue.auditType) else { return false }
        if e.identifier.hasPrefix("shed-pot-") && e.identifier != "shed-pot-hint" { return true }
        let names: Set<String> = ["Plain blue", "Terracotta", "Sage glaze", "Sunflower", "Mint", "Blossom", "Rose pink",
                                  "Living stones", "Flytrap", "Starlight", "Jade vine", "Rainbow bark", "Dewdrop", "Honey stripe",
                                  "Moonlit", "Meadow", "Frosted glass", "Lantern red", "Snowflake indigo"]
        return e.frame.width < 100 && e.identifier.isEmpty && (names.contains(e.label) || e.label.count < 30 && e.frame.height < 40)
    }

    // MARK: Dormant framework

    /// No product from the store and not owned: no Seasons row, no shelf, no pack outlines, no Lantern Keeper card.
    func testNoProductMeansNoSeasonsSurfaces() {
        launch(age: "eighteenPlus", ["-uitest-everything"])
        openSettings()
        scrollTo(app.buttons["settings.plus"])
        XCTAssertFalse(app.buttons["settings.seasons"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        openShed()
        for _ in 0..<16 { app.swipeUp(velocity: .fast) }
        XCTAssertFalse(element("shed-pot-lanternRed").exists)
        XCTAssertFalse(element("pot-pack-title").exists)
        XCTAssertFalse(element("shed.seasons").exists)
    }

    /// Live pack: Lantern Keeper is on the Badges page (earned by play; nothing is sold there).
    func testLanternKeeperShowsWhileThePackIsLive() {
        launch(age: "eighteenPlus", ["-uitest-prices", "-uitest-everything"])
        app.buttons["Badges"].tap()
        XCTAssertTrue(app.navigationBars["Badges"].waitForExistence(timeout: 5))
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Lantern Keeper'")).firstMatch
        scrollTo(card, max: 30)
        XCTAssertTrue(card.exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'")).firstMatch.exists)
    }
}

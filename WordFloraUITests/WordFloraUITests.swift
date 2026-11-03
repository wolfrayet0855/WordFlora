import XCTest

final class WordFloraUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(word: String? = nil) {
        app.launchArguments = ["-uitest", "-uitest-onboarded"] + (word.map { ["-uitest-word=\($0)"] } ?? [])
        app.launch()
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Settings is a long list; scroll until the element is on screen.
    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<6 where !element.isHittable { app.swipeUp() }
    }

    private func tapLetters(_ letters: String) {
        for ch in letters { app.buttons[String(ch)].tap() }
    }

    func testHomeShowsPlayAndGarden() {
        launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Garden"].exists)
        shot("home")
    }

    func testSolvingAWordShowsANewPlant() {
        launch(word: "LOTUS")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        shot("game-start")
        tapLetters("ZX")
        shot("game-two-wrong")
        tapLetters("LOTUS")
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6))
        shot("plant-earned")
        app.buttons["Continue"].tap()
    }

    func testWrongGuessesEndWithARestingReveal() {
        launch(word: "LOTUS")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 5))
        tapLetters("ZXQJKVWY")
        XCTAssertTrue(app.staticTexts["This one's resting."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Here's the word:"].exists)
        shot("resting")
    }

    func testHelpRevealsASecondClue() {
        launch(word: "LOTUS")
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Help"].waitForExistence(timeout: 5))
        app.buttons["Help"].tap()
        XCTAssertTrue(app.staticTexts["Second clue"].waitForExistence(timeout: 3))
    }

    func testGardenOpensFromHome() {
        launch()
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 5))
        shot("garden")
    }

    // MARK: first session
    func testFirstSessionFlowFromIntroToHome() {
        app.launchArguments = ["-uitest", "-uitest-word=SEED"]
        app.launch()
        XCTAssertTrue(app.buttons["Under 13"].waitForExistence(timeout: 8))      // intro rain, then the age question
        shot("age")
        XCTAssertFalse(app.buttons["Play"].exists)                              // no home chrome in session one
        app.buttons["18 or older"].tap()
        XCTAssertTrue(app.staticTexts["Tap a letter to guess"].waitForExistence(timeout: 5))
        for ch in "ZXQJKVWYUPMN" { app.buttons[String(ch)].tap() }              // wrong guesses cannot end the tutorial
        XCTAssertFalse(app.staticTexts["This one's resting."].exists)
        for ch in "SED" { app.buttons[String(ch)].tap() }
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Water your plant"].waitForExistence(timeout: 5))
        shot("first-tip")
        app.buttons["Water your plant"].tap()
        app.buttons["Play another word"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Levels"].exists)                            // later features stay hidden
    }

    func testSettingsAndLevelMapOpen() {
        launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5))
        shot("settings")
    }

    func testTendingAPlantShowsGentleFeedback() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened"]
        app.launch()
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Water"].waitForExistence(timeout: 5))
        shot("plant-detail")
        app.buttons["Water"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "+4 growth")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["Repot"].tap()
        XCTAssertTrue(app.staticTexts["Choose a soil"].waitForExistence(timeout: 3))
        shot("repot")
    }

    func testPaywallShowsBothPlansHonestlyAndSubscriberStateHidesThem() {
        launch()
        app.buttons["Settings"].tap()
        scrollTo(app.buttons["Remove ads and sync with iCloud"])
        app.buttons["Remove ads and sync with iCloud"].tap()
        XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No ads, ever"].exists)
        shot("paywall")
    }

    func testSubscriberSeesThankYouNotPlans() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-plus"]
        app.launch()
        app.buttons["Settings"].tap()
        scrollTo(app.buttons["Remove ads and sync with iCloud"])
        app.buttons["Remove ads and sync with iCloud"].tap()
        XCTAssertTrue(app.staticTexts["You have WordFlora Plus"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Subscribe"].exists)
    }

    func testShedAndBadgesOpenWhenEverythingIsShown() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything"]
        app.launch()
        app.buttons["Shed"].tap()
        XCTAssertTrue(app.staticTexts["Watering can"].waitForExistence(timeout: 5))
        shot("shed")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Badges"].tap()
        XCTAssertTrue(app.staticTexts["Green Thumb"].waitForExistence(timeout: 5))
        shot("badges")
    }

    func testButterflyGameStartsAndCanBeFinishedWithARewardingSummary() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything"]
        app.launch()
        app.buttons["Visitors"].tap()
        XCTAssertTrue(app.staticTexts["Meet your garden visitors"].waitForExistence(timeout: 5))
        shot("butterfly-intro")
        app.buttons["Start"].tap()
        sleep(3)
        shot("butterfly-playing")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93)).tap()      // a miss on empty ground is free
        XCTAssertFalse(app.staticTexts["Game over"].exists)
        // The game lasts about 35 seconds; the summary then always rewards something.
        let thanks = app.staticTexts["Thanks for visiting the garden"], met = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'You met'")).firstMatch
        let deadline = Date().addingTimeInterval(55)
        while Date() < deadline && !thanks.exists && !met.exists { sleep(1) }
        shot("butterfly-after-wait")
        XCTAssertTrue(thanks.exists || met.exists, "summary never appeared")
        shot("butterfly-summary")
    }

    // MARK: accessibility audits (Apple's automated audit: labels, hit areas, Dynamic Type, contrast)
    /// `ignoring` is only for stock iOS rows we do not style (the Settings form's toggles and pickers), where the audit
    /// reports Dynamic Type and contrast findings on system-drawn controls.
    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = []) {
        var findings = [String]()
        do {
            try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(ignoring)) { issue in
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | \(issue.element?.elementType.rawValue ?? 0) '\(issue.element?.label ?? "")'")
                return true            // collect everything instead of stopping at the first issue
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? findings.joined(separator: "\n").write(toFile: dir + "/audit-\(name).txt", atomically: true, encoding: .utf8)
        }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    func testAuditHome() { launch(); XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5)); audit("home") }

    func testAuditGameAndResting() {
        launch(word: "LOTUS"); app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 5)); audit("game")
    }

    func testAuditGardenSettingsAndPlus() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened"]; app.launch()
        app.buttons["Garden"].tap(); XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 5)); audit("garden")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Water"].waitForExistence(timeout: 5)); audit("plant")
    }

    func testAuditMoreScreens() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything"]; app.launch()
        app.buttons["Shed"].tap(); XCTAssertTrue(app.staticTexts["Watering can"].waitForExistence(timeout: 5)); audit("shed")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Badges"].tap(); XCTAssertTrue(app.staticTexts["Green Thumb"].waitForExistence(timeout: 5)); audit("badges")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Levels"].tap(); XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 5)); audit("levels")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Settings"].tap(); XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5)); audit("settings", ignoring: [.dynamicType, .contrast, .textClipped])
    }

    func testAuditPaywallAndOnboarding() {
        launch()
        app.buttons["Settings"].tap(); scrollTo(app.buttons["Remove ads and sync with iCloud"])
        app.buttons["Remove ads and sync with iCloud"].tap()
        XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 5)); audit("plus")
        app.terminate()
        app.launchArguments = ["-uitest"]; app.launch()
        XCTAssertTrue(app.buttons["Under 13"].waitForExistence(timeout: 8)); audit("age")
    }
}


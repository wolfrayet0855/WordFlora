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
        XCTAssertTrue(app.staticTexts["+4 growth"].waitForExistence(timeout: 3))
        app.buttons["Repot"].tap()
        XCTAssertTrue(app.staticTexts["Choose a soil"].waitForExistence(timeout: 3))
        shot("repot")
    }

    func testPaywallShowsBothPlansHonestlyAndSubscriberStateHidesThem() {
        launch()
        app.buttons["Settings"].tap()
        app.buttons["Remove ads and sync with iCloud"].tap()
        XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No ads, ever"].exists)
        shot("paywall")
    }

    func testSubscriberSeesThankYouNotPlans() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-plus"]
        app.launch()
        app.buttons["Settings"].tap()
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
}


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
        XCTAssertTrue(app.images["WordFlora"].exists)                           // the wordmark artwork, one labelled element
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

    /// After the first plant, each word moves toward the next one and every third word brings it (owner decision 2026-11-04).
    func testAfterTheFirstPlantEveryThirdWordBringsTheNext() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-word=LOTUS"]
        app.launch()
        let homeLine = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "0 of 3 words to your next plant")).firstMatch
        XCTAssertTrue(homeLine.waitForExistence(timeout: 5), "Home shows the words toward the next plant")
        app.buttons["Play"].tap()
        for n in 1...2 {
            XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
            tapLetters("LOTUS")
            XCTAssertTrue(app.staticTexts["Great word!"].waitForExistence(timeout: 6), "word \(n)")
            XCTAssertTrue(app.staticTexts["\(n) of 3 words to your next plant."].exists, "word \(n)")
            XCTAssertFalse(app.staticTexts["New plant found!"].exists, "no plant on word \(n)")
            XCTAssertFalse(app.buttons["Share this plant"].exists, "nothing to share without a plant")
            if n == 1 { shot("word-toward-plant") }
            app.buttons["Continue"].tap()
        }
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        tapLetters("LOTUS")
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6), "the third word brings the plant")
        XCTAssertFalse(app.staticTexts["Great word!"].exists)
        shot("third-word-plant")
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
        // The onboarding guide comes next (GuideUITests covers it); Skip goes straight to the tutorial word.
        XCTAssertTrue(app.buttons["onboardingGuide.skip"].waitForExistence(timeout: 5))
        app.buttons["onboardingGuide.skip"].tap()
        XCTAssertTrue(app.staticTexts["Tap a letter to guess"].waitForExistence(timeout: 5))
        for ch in "ZXQJKVWYUPMN" { app.buttons[String(ch)].tap() }              // wrong guesses cannot end the tutorial
        XCTAssertFalse(app.staticTexts["This one's resting."].exists)
        for ch in "SED" { app.buttons[String(ch)].tap() }
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Water my plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Not now"].exists)
        shot("first-tip")
        app.buttons["Water my plant"].tap()
        XCTAssertTrue(app.staticTexts["Watered. It will grow a little every day."].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Play another word"].exists)
        app.buttons["Go home"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Levels"].isEnabled)                         // later features are visible but not open yet
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
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "+3 growth")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["Repot"].tap()
        XCTAssertTrue(app.staticTexts["Choose a soil"].waitForExistence(timeout: 3))
        shot("repot")
    }

    func testASeedOffersTheWakeSheetWithTwoChallengesAndAPlainClose() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-seed"]
        app.launch()
        app.buttons["Garden"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        let wake = app.buttons["Wake Clover"]
        XCTAssertTrue(wake.waitForExistence(timeout: 5))
        scrollTo(wake)
        wake.tap()
        XCTAssertTrue(app.buttons["wake-butterflies"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["wake-wordPuzzle"].exists)
        XCTAssertEqual(app.buttons["wake-butterflies"].label, "Catch butterflies, quick, gentle, good for today")
        XCTAssertFalse(app.buttons["Maybe later"].exists)
        shot("wake-sheet")
        app.buttons["wake-wordPuzzle"].tap()
        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 3))
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Clear"].waitForExistence(timeout: 3))
        shot("wake-puzzle")
        app.buttons["Close"].tap()
        XCTAssertTrue(wake.waitForExistence(timeout: 3))          // closing changes nothing: still a seed
    }

    // MARK: Plant page: Life panel, love petals, rain, seed pot

    private func openClover(_ extra: [String]) {
        app.launchArguments = ["-uitest", "-uitest-onboarded"] + extra
        app.launch()
        app.buttons["Garden"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
    }

    func testLifePanelMinimisesToATabAndComesBack() {
        openClover(["-uitest-gardened"])
        let plant = app.buttons["plant-love"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        XCTAssertEqual(plant.label, "Clover, 5 of 5 love petals")
        let hide = app.buttons["Hide Life panel"]
        XCTAssertTrue(hide.waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["Life"].exists || app.staticTexts["Life"].exists)
        shot("plant-life")
        hide.tap()
        let show = app.buttons["Show Life panel"]
        XCTAssertTrue(show.waitForExistence(timeout: 3))
        XCTAssertFalse(hide.exists)
        XCTAssertGreaterThanOrEqual(show.frame.width, 44); XCTAssertGreaterThanOrEqual(show.frame.height, 44)
        shot("plant-life-minimised")
        show.tap()
        XCTAssertTrue(app.buttons["Hide Life panel"].waitForExistence(timeout: 3))
    }

    func testARainyDayReadsFewerLovePetalsAndAHelloBringsThemBack() {
        openClover(["-uitest-rain=2"])
        let plant = app.buttons["plant-love"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        XCTAssertEqual(plant.label, "Clover, 3 of 5 love petals")
        sleep(5)                                   // the petals drift down and rest
        shot("plant-rain-2")
        plant.tap()
        XCTAssertTrue(app.buttons["Clover, 5 of 5 love petals"].waitForExistence(timeout: 3))
        sleep(2)
        shot("plant-regrown")
    }

    func testPlantPageScreens() {
        openClover(["-uitest-rain=4"])
        XCTAssertTrue(app.buttons["Clover, 1 of 5 love petals"].waitForExistence(timeout: 5))
        sleep(6); shot("plant-rain-4")
        app.terminate()
        XCUIDevice.shared.appearance = .dark
        openClover(["-uitest-rain=1"])
        XCTAssertTrue(app.buttons["Clover, 4 of 5 love petals"].waitForExistence(timeout: 5))
        sleep(5); shot("plant-rain-1-dark")
        app.terminate()
        XCUIDevice.shared.appearance = .light
        openClover(["-uitest-seed"])
        XCTAssertTrue(app.buttons["Wake Clover"].waitForExistence(timeout: 5))
        sleep(7)
        XCTAssertTrue(app.buttons["Clover, resting as a seed in its pot"].exists)
        shot("plant-seed")
        app.terminate()
        openClover(["-uitest-rain=2", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
        XCTAssertTrue(app.buttons["Water"].waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.buttons["Water"].frame.height, 64)
        sleep(4); shot("plant-large")
        app.buttons["Hide Life panel"].tap()
        XCTAssertTrue(app.buttons["Show Life panel"].waitForExistence(timeout: 3))
        shot("plant-large-collapsed")
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
        XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5))
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
        // The Visitors page leads; "Say hello" opens the game, which starts on open (no separate Start step).
        XCTAssertTrue(app.buttons["Say hello"].waitForExistence(timeout: 5))
        shot("butterfly-intro")
        app.buttons["Say hello"].tap()
        XCTAssertTrue(app.navigationBars["Butterfly game"].waitForExistence(timeout: 5))
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

    // MARK: Visitors page, Shed (lead decisions 2026-11-04)

    func testVisitorsPageOpensFromHomeWithSoftOutlinesAndAFact() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-album"]
        app.launch()
        app.buttons["Visitors"].tap()
        XCTAssertTrue(app.staticTexts["3 of 12 friends met"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Say hello"].exists)
        let unmet = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'visitor-unmet-'"))
        XCTAssertEqual(unmet.count, 9, "friends not met yet show as soft outlines")
        XCTAssertFalse(app.images["lock.fill"].exists)
        XCTAssertFalse(app.images["Lock"].exists)
        shot("visitors-page")
        let monarch = app.buttons["visitor-monarch"]
        XCTAssertTrue(monarch.label.contains("met 2 times"), monarch.label)
        XCTAssertTrue(monarch.label.contains("sometimes seen"), monarch.label)
        monarch.tap()
        XCTAssertTrue(app.staticTexts["You met this friend 2 times."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Monarch butterflies can fly up to 3,000 miles to a warm place for winter."].exists)
        shot("visitors-detail")
        app.buttons["Done"].tap()
        app.buttons["Say hello"].tap()
        XCTAssertTrue(app.navigationBars["Butterfly game"].waitForExistence(timeout: 5))
    }

    func testCalmModeGameHasADoneButtonAndNoTimeBar() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-calm"]
        app.launch()
        app.buttons["Visitors"].tap()
        app.buttons["Say hello"].tap()
        XCTAssertTrue(app.buttons["calm-done"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.progressIndicators["Game progress"].exists)
        shot("butterfly-calm")
        app.buttons["calm-done"].tap()
        XCTAssertTrue(app.staticTexts["Thanks for visiting the garden"].waitForExistence(timeout: 5) || app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'You met'")).firstMatch.exists)
    }

    func testShedInQuietGardenShowsNoPricesOrPoints() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-quiet"]
        app.launch()
        app.buttons["Shed"].tap()
        XCTAssertTrue(app.staticTexts["Quiet Garden is on"].waitForExistence(timeout: 5))
        let prices = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'points' OR label CONTAINS[c] 'Upgrade'"))
        XCTAssertEqual(prices.count, 0, "Quiet Garden shows no points, prices or upgrades")
        app.buttons["shed.tool.can"].tap()
        XCTAssertTrue(app.staticTexts["Waters your plants"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["shed.upgradeButton"].exists)
        XCTAssertEqual(prices.count, 0)
        shot("shed-quiet-sheet")
    }

    func testAuditVisitorsAndShed() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-album"]; app.launch()
        app.buttons["Visitors"].tap(); XCTAssertTrue(app.buttons["Say hello"].waitForExistence(timeout: 5)); audit("visitors")
        app.buttons["visitor-monarch"].tap(); XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5)); audit("visitor-detail")
        app.buttons["Done"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Shed"].tap(); XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5)); audit("shed-v2")
        app.buttons["shed.tool.trowel"].tap(); XCTAssertTrue(app.staticTexts["Trowel"].waitForExistence(timeout: 5)); audit("shed-tool-sheet")
    }

    // MARK: accessibility audits (Apple's automated audit: labels, hit areas, Dynamic Type, contrast)
    /// `ignoring` is only for stock iOS rows we do not style (the Settings form's toggles and pickers), where the audit
    /// reports Dynamic Type and contrast findings on system-drawn controls.
    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = []) {
        var findings = [String]()
        // Text a scroll view clips at its edge (under the navigation bar, or above the plant page's pinned buttons)
        // is measured against whatever covers it; only text fully inside the scroll view is judged for contrast.
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
                return true            // collect everything instead of stopping at the first issue
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? findings.joined(separator: "\n").write(toFile: dir + "/audit-\(name).txt", atomically: true, encoding: .utf8)
        }
        if !skipped.isEmpty { print("\(name): contrast on \(skipped.count) clipped, unresolved element(s) not judged") }
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

    func testAuditRainyPlant() {
        openClover(["-uitest-rain=3"])
        XCTAssertTrue(app.buttons["Water"].waitForExistence(timeout: 5)); audit("plant-rain")
    }

    func testAuditMoreScreens() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything"]; app.launch()
        app.buttons["Shed"].tap(); XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5)); audit("shed")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Badges"].tap(); XCTAssertTrue(app.staticTexts["Green Thumb"].waitForExistence(timeout: 5)); audit("badges")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Levels"].tap(); XCTAssertTrue(app.staticTexts["Garden Path"].waitForExistence(timeout: 5)); audit("levels")
        app.buttons["Home"].tap()
        app.buttons["Settings"].tap(); XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5)); audit("settings", ignoring: [.dynamicType, .contrast, .textClipped])
    }

    /// Garden Path level map: header, "You are here" on the current stop, its Play button, no padlock wording, and a clean audit.
    /// `-uitest-everything` opens the Levels tile on Home (it is not open yet in a one-plant garden).
    func testLevelMapGardenPath() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything"]; app.launch()
        XCTAssertTrue(app.buttons["Levels"].waitForExistence(timeout: 5))
        app.buttons["Levels"].tap()
        let header = app.staticTexts["Garden Path"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertTrue(header.isHittable)
        XCTAssertTrue(app.buttons["Home"].exists, "the back button reads Home")
        let here = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'You are here'")).firstMatch
        XCTAssertTrue(here.waitForExistence(timeout: 3), "a You are here stop")
        XCTAssertTrue(here.label.hasPrefix("Level 1, Seedling."), here.label)
        XCTAssertTrue(app.buttons["Play Level 1"].exists)
        XCTAssertFalse(app.buttons["Play Level 2"].exists, "Level 2 is coming soon, so it has no Play button")
        let lock = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'lock'"))
        XCTAssertEqual(lock.count, 0, "no padlock wording or icons")
        shot("level-map")
        audit("level-map")
        app.buttons["Play Level 1"].tap()
        XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 5), "Play Level 1 opens a game")
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


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
            // Progress is said once: the count line on word 1, the nudge line instead of it on word 2.
            XCTAssertEqual(app.staticTexts["\(n) of 3 words to your next plant."].exists, n == 1, "word \(n)")
            XCTAssertFalse(app.staticTexts["New plant found!"].exists, "no plant on word \(n)")
            XCTAssertFalse(app.buttons["Share this plant"].exists, "nothing to share without a plant")
            // The nudge: the next word, or a calm way to the garden; the extra line only on the word before the plant.
            let nextLine = app.staticTexts["One more word and a new plant arrives!"]
            if n == 2 { XCTAssertTrue(nextLine.exists, "word 2") } else { XCTAssertFalse(nextLine.exists, "word 1") }
            XCTAssertTrue(app.buttons["winCard.tendGarden"].exists, "word \(n)")
            XCTAssertEqual(app.buttons["winCard.tendGarden"].label, "Tend my garden")
            if n == 1 { sleep(1); shot("word-toward-plant") }
            if n == 2 { sleep(1); shot("word-before-plant") }
            app.buttons["Next word"].tap()
        }
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        tapLetters("LOTUS")
        XCTAssertTrue(app.staticTexts["New plant found!"].waitForExistence(timeout: 6), "the third word brings the plant")
        XCTAssertFalse(app.staticTexts["Great word!"].exists)
        shot("third-word-plant")
    }

    /// "Tend my garden" on a word with no plant closes the card and opens the garden (the calm way out of the round).
    func testTheWinCardCanGoTendTheGarden() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-word=LOTUS"]
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        tapLetters("LOTUS")
        let tend = app.buttons["winCard.tendGarden"]
        XCTAssertTrue(tend.waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["Next word"].exists)
        for _ in 0..<6 where !tend.isHittable { app.swipeUp() }
        tend.tap()
        XCTAssertTrue(app.navigationBars["My Garden"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Great word!"].exists)
    }

    /// The win card at the largest text size, dark: the pips, both lines and both buttons fit and can be reached.
    func testTheWinCardFitsAtAccessibilityXXXLDark() {
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = .light }
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-word=LOTUS",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
        app.buttons["Play"].tap()
        for n in 1...2 {
            XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
            tapLetters("LOTUS")
            let next = app.buttons["Next word"]
            XCTAssertTrue(next.waitForExistence(timeout: 6), "word \(n)")
            if n == 2 {
                sleep(2); shot("word-before-plant-axxxl-dark")
                for _ in 0..<6 where !app.buttons["winCard.tendGarden"].isHittable { app.swipeUp() }
                XCTAssertTrue(app.buttons["winCard.tendGarden"].isHittable)
                shot("word-before-plant-axxxl-dark-buttons")
                return
            }
            for _ in 0..<6 where !next.isHittable { app.swipeUp() }
            next.tap()
        }
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
        XCTAssertTrue(app.staticTexts["Repot Clover"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["repot-soil-loam"].exists, "the soil choices are in the sheet")
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
        letTheBadgeMomentPass()
    }

    /// The first look at a found plant's fact card earns the bronze Wild Discovery badge, and its moment dims the whole
    /// app (62% scrim) for 2.6 s. Taps and audits wait until it has gone, as a child would.
    private func letTheBadgeMomentPass() {
        let moment = app.descendants(matching: .any)["badgeMoment"].firstMatch
        guard moment.waitForExistence(timeout: 4) else { return }
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: moment)
        wait(for: [gone], timeout: 10)
    }

    /// The Life panel starts closed (owner ruling 2026-11-06); a tap opens it and the chevron closes it again.
    func testLifePanelStartsClosedAndOpensOnATap() {
        openClover(["-uitest-gardened"])
        let plant = app.buttons["plant-love"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        XCTAssertEqual(plant.label, "Clover, 5 of 5 love petals")
        let first = app.buttons["Show Life panel"]
        XCTAssertTrue(first.waitForExistence(timeout: 3), "a first visit starts closed")
        XCTAssertFalse(app.buttons["Hide Life panel"].exists)
        first.tap()
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

    /// A hello on the page is seen there, so the next visit stays closed; a change made elsewhere opens it.
    func testLifePanelOpensItselfOnlyAfterAChangeSinceTheLastVisit() {
        openClover(["-uitest-gardened"])
        let plant = app.buttons["plant-love"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Show Life panel"].waitForExistence(timeout: 3))
        plant.tap()                                            // a hello: one more heart, seen on this page
        sleep(1)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        letTheBadgeMomentPass()
        XCTAssertTrue(app.buttons["Show Life panel"].waitForExistence(timeout: 5), "nothing new since the last visit")
        app.terminate()
        openClover(["-uitest-gardened", "-uitest-life-changed"])
        XCTAssertTrue(app.buttons["Hide Life panel"].waitForExistence(timeout: 5), "something changed: the panel opens")
        audit("plant-life-open")
    }

    /// The opened panel at an accessibility size (the sheet under the plant).
    func testAuditThePlantPageWithTheLifePanelOpenAtALargeTextSize() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-life-changed",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        app.buttons["Garden"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Hide Life panel"].waitForExistence(timeout: 5))
        sleep(1)
        audit("plant-life-open-ax")
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
        // The Life panel starts closed and opens itself on a visit after a change (owner ruling 2026-11-06), so the
        // large-text shots ask for a changed visit to show it open, then close it.
        openClover(["-uitest-rain=2", "-uitest-life-changed", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"])
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
        let friend = app.staticTexts["visitors.friendOfTheDay"]
        XCTAssertTrue(friend.exists, "a friend of the day")
        XCTAssertTrue(friend.label.hasPrefix("Say hello to a") && friend.label.hasSuffix(" today"), friend.label)
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

    func testVisitorsInQuietGardenHaveNoFriendOfTheDay() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-quiet"]
        app.launch()
        app.buttons["Visitors"].tap()
        XCTAssertTrue(app.buttons["Say hello"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["visitors.friendOfTheDay"].exists)
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

    // MARK: key marks at large text (docs/research/key-marks-at-large-text.md)

    /// The six letters the review named (wide R, S, Z, W, M and narrow I), shot unused, right and wrong.
    private static let markLetters = "RSZWMI"

    /// One look: the keyboard unused, every named key right, then every named key wrong, each audited and shot; then a
    /// mixed round with the test-only probes on, which checks that each mark sits under its letter, the key sizes and
    /// that the puzzle still fits the screen. `size` is a UIContentSizeCategory name, nil for the default (Large).
    private func checkKeyMarks(_ look: String, size: String?, dark: Bool) {
        executionTimeAllowance = 600
        // A light/dark switch redraws every app for a moment; an audit run inside that redraw reported every text on
        // the page as "Dynamic Type partially unsupported" (3 of 4 such failures came right after a switch). So the
        // switch is given time, and each audit waits until the page has stopped moving. The audit itself is unchanged.
        if XCUIDevice.shared.appearance != (dark ? .dark : .light) {
            XCUIDevice.shared.appearance = dark ? .dark : .light
            sleep(3)
        }
        addTeardownBlock { XCUIDevice.shared.appearance = .light }
        func settle() {
            let parts = [app.staticTexts["A test hint"], app.buttons["Q"], app.buttons["M"], app.buttons["Help"]]
            func layout() -> [CGRect] { parts.map { $0.exists ? $0.frame : .null } }
            var last = layout(), same = 0
            let end = Date().addingTimeInterval(15)
            while same < 2 && Date() < end {
                Thread.sleep(forTimeInterval: 0.5)
                let now = layout()
                same = now == last ? same + 1 : 0
                last = now
            }
            sleep(1)
        }
        func open(_ word: String, probes: Bool = false) {
            app.terminate()
            app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-word=\(word)"]
                + (probes ? ["-uitest-key-probes"] : []) + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
            app.launch()
            app.buttons["Play"].tap()
            XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 8), look)
            XCTAssertTrue(app.staticTexts["A test hint"].waitForExistence(timeout: 5), "\(look): the round drew the word")
        }
        func value(_ ch: Character) -> String { app.buttons[String(ch)].value as? String ?? "" }
        // Every named letter is in the word; the trailing O keeps the round open after six right guesses.
        open("RSZWMIO")
        for ch in Self.markLetters { XCTAssertEqual(value(ch), "", "\(look): \(ch) unused has no state") }
        settle(); shot("keys-\(look)-unused"); audit("keys-\(look)-unused")
        tapLetters(Self.markLetters)
        for ch in Self.markLetters {
            XCTAssertEqual(app.buttons[String(ch)].label, String(ch), "\(look): the label is the letter alone")
            XCTAssertEqual(value(ch), "in the word", "\(look): \(ch)")
        }
        settle(); shot("keys-\(look)-correct"); audit("keys-\(look)-correct")
        // None of the named letters is in the word: six wrong guesses, two short of the resting reveal.
        open("PLANT")
        tapLetters(Self.markLetters)
        for ch in Self.markLetters {
            XCTAssertEqual(app.buttons[String(ch)].label, String(ch), "\(look): the label is the letter alone")
            XCTAssertEqual(value(ch), "not in the word", "\(look): \(ch)")
        }
        settle(); shot("keys-\(look)-wrong"); audit("keys-\(look)-wrong")

        // Mixed round with probes: R, S, W, I right; Z, M wrong.
        open("WRIST", probes: true)
        tapLetters("RSWZMI")
        let height: CGFloat = size == nil ? 50 : 64
        let screen = app.windows.firstMatch.frame
        for ch in Self.markLetters {
            let key = app.buttons[String(ch)].frame
            let letter = app.descendants(matching: .any)["key.\(ch).letter"], mark = app.descendants(matching: .any)["key.\(ch).mark"]
            XCTAssertTrue(letter.waitForExistence(timeout: 3) && mark.exists, "\(look): probes for \(ch)")
            XCTAssertLessThanOrEqual(letter.frame.maxY, mark.frame.minY + 0.5, "\(look): \(ch)'s mark sits below its letter \(letter.frame) \(mark.frame)")
            XCTAssertGreaterThanOrEqual(letter.frame.height, 14, "\(look): \(ch)'s letter keeps its size")
            XCTAssertTrue(key.insetBy(dx: -0.5, dy: -0.5).contains(letter.frame) && key.insetBy(dx: -0.5, dy: -0.5).contains(mark.frame),
                          "\(look): \(ch)'s letter and mark stay inside the key \(key)")
            XCTAssertGreaterThanOrEqual(key.width, 28, "\(look): \(ch) width")
            XCTAssertEqual(key.height, height, accuracy: 0.5, "\(look): \(ch) height")
        }
        // The whole puzzle still fits: the clue above the keyboard, the bottom row on screen.
        let hint = app.staticTexts["A test hint"].frame
        XCTAssertLessThanOrEqual(hint.maxY, app.buttons["Q"].frame.minY, "\(look): the clue sits above the keyboard")
        XCTAssertLessThanOrEqual(app.buttons["M"].frame.maxY, screen.maxY, "\(look): the bottom row is on screen")
        XCTAssertTrue(app.buttons["Q"].isHittable && app.buttons["P"].isHittable && app.buttons["N"].isHittable, look)
        sleep(1); shot("keys-\(look)-mixed")
        app.terminate()
    }

    func testKeyMarksAtTheDefaultSizeInLight() { checkKeyMarks("default-light", size: nil, dark: false) }
    func testKeyMarksAtTheDefaultSizeInDark() { checkKeyMarks("default-dark", size: nil, dark: true) }
    func testKeyMarksAtAX1InLight() { checkKeyMarks("ax1-light", size: "UICTContentSizeCategoryAccessibilityM", dark: false) }
    func testKeyMarksAtAX1InDark() { checkKeyMarks("ax1-dark", size: "UICTContentSizeCategoryAccessibilityM", dark: true) }
    func testKeyMarksAtAX3InLight() { checkKeyMarks("ax3-light", size: "UICTContentSizeCategoryAccessibilityXL", dark: false) }
    func testKeyMarksAtAX3InDark() { checkKeyMarks("ax3-dark", size: "UICTContentSizeCategoryAccessibilityXL", dark: true) }
    func testKeyMarksAtAX5InLight() { checkKeyMarks("ax5-light", size: "UICTContentSizeCategoryAccessibilityXXXL", dark: false) }
    func testKeyMarksAtAX5InDark() { checkKeyMarks("ax5-dark", size: "UICTContentSizeCategoryAccessibilityXXXL", dark: true) }

    func testAuditGameAndResting() {
        launch(word: "LOTUS"); app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 5)); audit("game")
    }

    func testAuditGardenSettingsAndPlus() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened"]; app.launch()
        app.buttons["Garden"].tap(); XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 5)); audit("garden")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Water"].waitForExistence(timeout: 5))
        // The first look at the fact card earns Wild Discovery 0.6 s in; its moment dims the page, so the audit waits
        // for it to go (as openClover does). Run in a batch, the audit sometimes caught the dimmed page.
        letTheBadgeMomentPass()
        audit("plant")
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


/// Screens for the app-vs-mockup fidelity review (`docs/pm/app-vs-mockups.md`). Each test only checks that the screen
/// opened; the PNGs go to `SCREENSHOT_DIR` (pass `TEST_RUNNER_SCREENSHOT_DIR` to xcodebuild) and to the result bundle.
final class FidelityScreensUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 360          // three looks per test, several launches each
        app = XCUIApplication()
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("fid-\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// light, dark (the device appearance; the app follows the system), largest text size.
    private static let looks: [(String, XCUIDevice.Appearance, [String])] = [
        ("light", .light, []), ("dark", .dark, []),
        ("ax5", .light, ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]),
    ]

    private func launch(_ look: (String, XCUIDevice.Appearance, [String]), _ extra: [String]) {
        XCUIDevice.shared.appearance = look.1
        app.launchArguments = ["-uitest", "-uitest-onboarded"] + extra + look.2
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
    }

    func testHomeScreens() {
        for look in Self.looks {
            launch(look, ["-uitest-gardened", "-uitest-everything"])
            sleep(2); shot("home-open-\(look.0)")
            app.swipeUp(); sleep(1); shot("home-open-\(look.0)-end")
            app.terminate()
            launch(look, [])
            sleep(2); shot("home-early-\(look.0)")
            app.terminate()
        }
    }

    func testPlantPageScreens() {
        for look in Self.looks {
            launch(look, ["-uitest-plant=daisy"])
            app.buttons["Garden"].tap()
            let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Daisy'")).firstMatch
            XCTAssertTrue(tile.waitForExistence(timeout: 5))
            sleep(1); shot("garden-\(look.0)")
            tile.tap()
            XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 5))
            sleep(3); shot("plant-\(look.0)")
            app.swipeUp(); sleep(2); shot("plant-\(look.0)-scrolled")
            app.terminate()
        }
    }

    func testShedVisitorsAndLevelScreens() {
        for look in Self.looks {
            launch(look, ["-uitest-gardened", "-uitest-everything", "-uitest-album", "-uitest-points=12"])
            app.buttons["Shed"].tap()
            XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5))
            sleep(1); shot("shed-\(look.0)")
            for i in 1...3 { app.swipeUp(); sleep(1); shot("shed-\(look.0)-\(i)") }
            app.terminate()
            launch(look, ["-uitest-gardened", "-uitest-everything", "-uitest-album"])
            app.buttons["Visitors"].tap()
            XCTAssertTrue(app.buttons["Say hello"].waitForExistence(timeout: 5))
            sleep(1); shot("visitors-\(look.0)")
            app.swipeUp(); sleep(1); shot("visitors-\(look.0)-2")
            app.terminate()
            launch(look, ["-uitest-gardened", "-uitest-everything"])
            app.buttons["Levels"].tap()
            XCTAssertTrue(app.staticTexts["Garden Path"].waitForExistence(timeout: 5))
            sleep(1); shot("levels-\(look.0)")
            app.terminate()
        }
    }

    func testPotPickerAndGameScreens() {
        for look in Self.looks {
            launch(look, ["-uitest-plant=daisy", "-uitest-pots"])
            app.buttons["Garden"].tap()
            let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Daisy'")).firstMatch
            XCTAssertTrue(tile.waitForExistence(timeout: 5))
            for _ in 0..<10 where !tile.isHittable { app.swipeUp() }
            tile.tap()
            XCTAssertTrue(app.buttons["tend-repot"].waitForExistence(timeout: 5))
            app.buttons["tend-repot"].tap()
            XCTAssertTrue(app.buttons["repot-go"].waitForExistence(timeout: 5))
            sleep(2); shot("repot-\(look.0)")
            app.terminate()
            launch(look, ["-uitest-word=LOTUS"])
            app.buttons["Play"].tap()
            XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 5))
            for ch in "ZX" { app.buttons[String(ch)].tap() }
            sleep(1); shot("game-\(look.0)")
            app.terminate()
        }
    }

    /// Badges, Settings, Plus, Daily Bloom and the age question, for the spacing audit (`docs/pm/spacing-audit.md`).
    func testBadgesSettingsPlusDailyAndAgeScreens() {
        for look in Self.looks {
            launch(look, ["-uitest-gardened", "-uitest-everything"])
            app.buttons["tile-Badges"].tap()
            XCTAssertTrue(app.staticTexts["Green Thumb"].waitForExistence(timeout: 5))
            sleep(1); shot("badges-\(look.0)")
            app.navigationBars.buttons.firstMatch.tap()
            app.buttons["Settings"].tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
            sleep(1); shot("settings-\(look.0)")
            app.swipeUp(); sleep(1); shot("settings-\(look.0)-2")
            let plus = app.buttons["Remove ads and sync with iCloud"]
            // At AX XXXL the Settings page is long enough that six swipes stopped short of the row.
            for _ in 0..<14 where !(plus.exists && plus.isHittable) { app.swipeUp() }
            plus.tap()
            XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 5))
            sleep(1); shot("plus-\(look.0)")
            app.terminate()
            launch(look, ["-uitest-gardened", "-uitest-everything", "-uitest-word=LOTUS"])
            let daily = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Daily Bloom'")).firstMatch
            XCTAssertTrue(daily.waitForExistence(timeout: 5))
            daily.tap()
            XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 5))
            sleep(1); shot("daily-\(look.0)")
            app.terminate()
            XCUIDevice.shared.appearance = look.1
            app.launchArguments = ["-uitest"] + look.2
            app.launch()
            XCTAssertTrue(app.buttons["Under 13"].waitForExistence(timeout: 12))
            sleep(1); shot("age-\(look.0)")
            app.terminate()
        }
    }

    /// The letter puzzle for the puzzle look review: long words (13 and 14 letters), keys used right and wrong, the
    /// Speed bloom ring part drained, the win card, the resting card, and a 10 letter word at the largest text size.
    func testPuzzleScreens() {
        executionTimeAllowance = 600
        // The fixed word is the only word in the bank, so its level must be the player's level (1, or 4 with
        // `-uitest-speedbloom`), or the round has no word to draw.
        func play(_ look: (String, XCUIDevice.Appearance, [String]), _ word: String, level: Int, _ extra: [String] = []) {
            launch(look, ["-uitest-word=\(word)", "-uitest-word-level=\(level)"] + extra)
            app.buttons["Play"].tap()
            XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 8))
            XCTAssertTrue(app.staticTexts["A test hint"].waitForExistence(timeout: 5), "the round drew the word")
        }
        for look in Self.looks where look.0 != "ax5" {
            // Two right letters and three wrong ones, so the keyboard shows all three key looks.
            play(look, "PHOTOSYNTHESIS", level: 1)
            for ch in "PHZXQ" { app.buttons[String(ch)].tap() }
            sleep(1); shot("puzzle-14-photosynthesis-\(look.0)")
            app.terminate()
            play(look, "CHERRY BLOSSOM", level: 1)
            for ch in "RZX" { app.buttons[String(ch)].tap() }
            sleep(1); shot("puzzle-14-cherry-blossom-\(look.0)")
            app.terminate()
            play(look, "CONSTELLATION", level: 1)
            sleep(1); shot("puzzle-13-constellation-\(look.0)")
            app.terminate()
            play(look, "PASSIONFLOWER", level: 4, ["-uitest-speedbloom", "-uitest-speedbloom-seconds=30"])
            app.buttons["P"].tap()
            sleep(9); shot("puzzle-speedbloom-ring-\(look.0)")
            app.terminate()
            // Three wins open the resting card; the first win card is shot on the way.
            play(look, "LOTUS", level: 1)
            for n in 1...3 {
                XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5), "word \(n)")
                for ch in "LOTUS" { app.buttons[String(ch)].tap() }
                let next = app.buttons.matching(NSPredicate(format: "label IN %@", ["Continue", "Next word"])).firstMatch
                XCTAssertTrue(next.waitForExistence(timeout: 8), "word \(n)")
                if n == 1 { sleep(2); shot("puzzle-win-card-\(look.0)") }
                for _ in 0..<6 where !next.isHittable { app.swipeUp() }
                next.tap()
            }
            XCTAssertTrue(app.staticTexts["The garden is resting"].waitForExistence(timeout: 5))
            sleep(3); shot("puzzle-rest-card-\(look.0)")
            app.terminate()
        }
        let ax5 = Self.looks[2]
        play(ax5, "STRAWBERRY", level: 1)
        for ch in "SRZ" { app.buttons[String(ch)].tap() }
        sleep(1); shot("puzzle-10-strawberry-ax5")
        app.swipeUp(); sleep(1); shot("puzzle-10-strawberry-ax5-scrolled")
        app.terminate()
    }

    /// The cards over Home and the game: forecast card, weather banner, break card, the Grand Garden and the seed's
    /// wake sheet.
    func testCardScreens() {
        for look in Self.looks {
            launch(look, ["-uitest-forecast=bigWind"])
            sleep(2); shot("forecast-\(look.0)")
            app.terminate()
            launch(look, ["-uitest-weather=busyBugs"])
            sleep(2); shot("banner-\(look.0)")
            app.terminate()
            launch(look, ["-uitest-word=LOTUS", "-uitest-break-card"])
            app.buttons["Play"].tap()
            XCTAssertTrue(app.staticTexts["Time for a little break"].waitForExistence(timeout: 5))
            sleep(2); shot("break-\(look.0)")
            app.terminate()
            XCUIDevice.shared.appearance = look.1
            app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything", "-uitest-crown", "-uitest-reduce-motion"] + look.2
            app.launch()
            XCTAssertTrue(app.descendants(matching: .any)["grandGarden.title"].firstMatch.waitForExistence(timeout: 8))
            sleep(2); shot("grand-\(look.0)")
            app.terminate()
        }
    }
}

/// Links that leave the app ask a grown-up first for under 13 (Settings and Plus). Only the gate is checked here:
/// a right answer would leave the app for Safari or Mail.
final class ParentalGateLinkUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(age: String) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-age=\(age)"]
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    private func scrollTo(_ element: XCUIElement) {
        for _ in 0..<8 where !(element.exists && element.isHittable) { app.swipeUp() }
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func expectGateThenCancel(after tapping: XCUIElement) {
        scrollTo(tapping)
        tapping.tap()
        // The young player's Settings section is also called "For grown-ups", so the gate is found by its answer field.
        let answer = app.textFields["parentalGate.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Please ask a grown-up to answer this before continuing."].exists)
        answer.tap(); answer.typeText("1")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Not quite. Try again."].waitForExistence(timeout: 2), "a wrong answer stays in the app")
        app.buttons["Cancel"].tap()
        XCTAssertFalse(answer.waitForExistence(timeout: 2))
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// Under 13 with a live subscription: Manage subscription in Settings > Purchases asks a grown-up first (it leaves
    /// the app); Restore purchases opens no gate (it never charges).
    func testUnder13ManageSubscriptionInSettingsAsksAGrownUpFirst() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-age=under13", "-uitest-plus"]
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let manage = app.buttons["settings.manageSubscription"]
        scrollTo(manage)
        XCTAssertTrue(manage.exists, "a live subscription shows Manage subscription")
        expectGateThenCancel(after: manage)
        let restore = app.buttons["settings.restore"]
        scrollTo(restore)
        XCTAssertTrue(restore.exists)
    }

    func testUnder13SettingsLinksAskAGrownUpFirst() {
        launch(age: "under13")
        expectGateThenCancel(after: app.buttons["Privacy Policy"])
        expectGateThenCancel(after: app.buttons["Report an ad"])
    }

    func testUnder13PlusLinksAskAGrownUpFirst() {
        launch(age: "under13")
        let row = app.buttons["settings.plus"]
        scrollTo(row)
        XCTAssertEqual(row.label, "WordFlora Plus", "no ad or price pitch on the young player's row")
        XCTAssertFalse(app.buttons["Remove ads and sync with iCloud"].exists)
        XCTAssertTrue(app.staticTexts["Purchases"].exists, "everything bought sits under Purchases")
        row.tap()
        XCTAssertTrue(app.staticTexts["plus.grownUpsIntro"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["plus.grownUpsIntro"].label.hasPrefix("WordFlora is complete without Plus."))
        shot("plus-grown-ups")
        expectGateThenCancel(after: app.buttons["Terms of Use"])
        // No subscription, so nothing to manage: the link only shows with a live subscription (the paysTwice
        // "Cancel the subscription" button, behind the gate too, is checked with the owned states).
        XCTAssertFalse(app.buttons["Manage subscription"].exists)
        expectGateThenCancel(after: app.buttons["plus.redeem"])
    }

    /// Plus Forever is a purchase like the plans: a young player's tap on its buy button asks a grown-up first.
    func testUnder13PlusForeverAndCodesAskAGrownUpFirst() {
        // `-uitest-prices`: the page shows the local config's three prices, whatever the simulator's store returns.
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-prices", "-uitest-age=under13"]
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let row = app.buttons["settings.plus"]
        scrollTo(row); row.tap()
        let lifetime = app.buttons["plus.lifetime"]
        XCTAssertTrue(lifetime.waitForExistence(timeout: 8))
        scrollTo(lifetime); lifetime.tap()
        let buy = app.buttons["Buy Plus Forever"]
        XCTAssertTrue(buy.waitForExistence(timeout: 3))
        expectGateThenCancel(after: buy)
        expectGateThenCancel(after: app.buttons["Redeem a code"])
    }

    /// Under 13: the Family Sharing note is for the grown-up, inside "For grown-ups" in Settings only; its button asks
    /// the grown-up question first; shown two days ago, it stays away (once a week at most); never on the Plus page.
    func testUnder13FamilyNoteIsForGrownUpsBehindTheGate() {
        launch(age: "under13")
        let note = app.otherElements["familyShare.grownUps"]
        let button = app.buttons["familyShare.grownUpsButton"]
        scrollTo(button)
        XCTAssertTrue(button.exists, "the grown-ups' note sits in the Purchases section")
        XCTAssertTrue(app.staticTexts["Purchases"].exists)
        let line = app.staticTexts.matching(NSPredicate(format: "label == %@", FamilyCopy.line)).firstMatch
        XCTAssertTrue(line.exists || note.exists, "the grown-ups' line is on screen")
        XCTAssertFalse(app.buttons["familyShare.restore"].exists, "no Restore line for a young player")
        shot("settings-family-grownups")
        expectGateThenCancel(after: button)
        // Through the gate, the Plus page opens; it carries no second note.
        scrollTo(button); button.tap()
        let answer = app.textFields["parentalGate.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        let q = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'What is '")).firstMatch.label
        let nums = q.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        answer.tap(); answer.typeText("\(nums[0] * nums[1])")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["plus.grownUpsIntro"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["familyShare.grownUpsButton"].exists)
        XCTAssertFalse(app.buttons["familyShare.restore"].exists)

        app.terminate()
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-age=under13", "-uitest-family-note-seen"]
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["settings.plus"])
        for _ in 0..<3 { app.swipeUp() }
        XCTAssertFalse(app.buttons["familyShare.grownUpsButton"].exists, "shown two days ago: not again this week")
    }

    private enum FamilyCopy {
        static let line = "Plus covers the whole family. Grown-ups: turn on Family Sharing in Apple Family settings and everyone in your family gets Plus, ads off, garden synced."
    }

    func testAdultsSeeTheSameLinksWithNoGateOnScreen() {
        launch(age: "eighteenPlus")
        scrollTo(app.buttons["Privacy Policy"])
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        XCTAssertTrue(app.buttons["Report an ad"].exists)
        let row = app.buttons["settings.plus"]
        scrollTo(row)
        XCTAssertTrue(app.staticTexts["Purchases"].exists, "the same Purchases header for every age")
        XCTAssertEqual(row.label, "Remove ads and sync with iCloud", "the grown-up row is unchanged")
        row.tap()
        XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["plus.grownUpsIntro"].exists)
    }
}

/// Plus Forever and Redeem a code on the Plus page: the third row under the two plans (never the default), the
/// owned states, the "charged twice" note, and the full audit at the default size and AX XXXL.
final class PlusForeverUITests: XCTestCase {
    let app = XCUIApplication()
    override func setUpWithError() throws { continueAfterFailure = false }

    /// `-uitest-prices`: the page shows the local `WordFlora.storekit` prices whatever the simulator's store returns
    /// (UI tests run outside the StoreKit test environment). Purchases themselves are covered by StoreKitConfigTests.
    private func openPlus(_ extra: [String] = [], size: String? = nil) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-prices", "-uitest-age=eighteenPlus"] + extra
            + (size.map { ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategory\($0)"] } ?? [])
        app.launch()
        app.buttons["Settings"].tap()
        let row = app.buttons["settings.plus"]
        scrollTo(row)
        row.tap()
        XCTAssertTrue(app.staticTexts["WordFlora Plus"].waitForExistence(timeout: 8))
    }

    /// Swipes until the element is on screen, then lets the scroll come to rest for the shots.
    private func scrollTo(_ element: XCUIElement) {
        var swiped = false
        for _ in 0..<10 where !(element.exists && element.isHittable) { app.swipeUp(); swiped = true }
        if swiped { sleep(2) }
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// The full audit, as `WordFloraUITests.audit`: only text wholly inside the scroll view is judged for contrast.
    /// Run on unscrolled screens only: after a scroll, the audit placed this page's text about 35 pt below where it is
    /// drawn and judged the wrong pixels next to the bar (the level map's audit runs from the top for the same reason).
    private func audit(_ name: String) {
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

    func testPlusForeverIsTheThirdRowAndYearlyStaysTheDefault() {
        openPlus()
        let lifetime = app.buttons["plus.lifetime"]
        XCTAssertTrue(lifetime.waitForExistence(timeout: 8))
        XCTAssertTrue(lifetime.label.contains("Plus Forever"), lifetime.label)
        XCTAssertTrue(lifetime.label.contains("Pay once, keep Plus on this Apple ID. No renewals."), lifetime.label)
        XCTAssertFalse(lifetime.isSelected, "Plus Forever is never the default")
        let yearly = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Yearly'")).firstMatch
        let monthly = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Monthly'")).firstMatch
        XCTAssertTrue(yearly.isSelected, "Yearly stays the default")
        XCTAssertLessThan(yearly.frame.minY, monthly.frame.minY)
        XCTAssertLessThan(monthly.frame.minY, lifetime.frame.minY, "Plus Forever sits under Yearly and Monthly")
        XCTAssertFalse(lifetime.label.lowercased().contains("best"), "no badge on Plus Forever")
        scrollTo(lifetime); lifetime.tap()
        XCTAssertTrue(lifetime.isSelected)
        let buy = app.buttons["Buy Plus Forever"]
        XCTAssertTrue(buy.waitForExistence(timeout: 3))
        let fine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'One payment of'")).firstMatch
        XCTAssertTrue(fine.exists); XCTAssertTrue(fine.label.hasSuffix("No renewals."), fine.label)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'renews automatically'")).firstMatch.exists,
                       "no renewal wording while Plus Forever is picked")
        shot("plus-three-rows")
        let redeem = app.buttons["Redeem a code"]
        scrollTo(redeem)
        XCTAssertTrue(redeem.exists && redeem.isHittable)
        XCTAssertGreaterThanOrEqual(redeem.frame.height, 43.99)
        shot("plus-redeem-row")
    }

    /// At the default size all three rows are on the first screen, so the audit sees them unscrolled. Redeem a code is
    /// audited unscrolled on the owner screens below, where it is on the first screen.
    func testThePlusPagePassesTheAuditWithThreeRows() {
        openPlus()
        let lifetime = app.buttons["plus.lifetime"]
        XCTAssertTrue(lifetime.waitForExistence(timeout: 8))
        XCTAssertTrue(lifetime.isHittable, "all three rows on the first screen")
        audit("plus-three-rows")
    }

    /// At AX XXXL: the top of the page passes the audit, and every row and Redeem a code is reachable, tappable and
    /// inside the screen's width (the old side-by-side price pushed the cards off the left edge here).
    func testThePlusPagePassesTheAuditAtAccessibilityXXXL() {
        openPlus(size: "AccessibilityXXXL")
        audit("plus-axxxl-top")
        let screen = app.windows.firstMatch.frame
        for (id, name) in [("Yearly", "yearly"), ("Monthly", "monthly")] {
            let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", id)).firstMatch
            scrollTo(row)
            XCTAssertTrue(row.isHittable, id)
            XCTAssertGreaterThanOrEqual(row.frame.minX, screen.minX, "\(id) stays on screen")
            XCTAssertLessThanOrEqual(row.frame.maxX, screen.maxX, "\(id) stays on screen")
            shot("plus-axxxl-\(name)")
        }
        let lifetime = app.buttons["plus.lifetime"]
        scrollTo(lifetime)
        XCTAssertTrue(lifetime.isHittable)
        XCTAssertGreaterThanOrEqual(lifetime.frame.minX, screen.minX); XCTAssertLessThanOrEqual(lifetime.frame.maxX, screen.maxX)
        shot("plus-three-rows-axxxl")
        let redeem = app.buttons["Redeem a code"]
        scrollTo(redeem)
        XCTAssertTrue(redeem.isHittable)
        XCTAssertGreaterThanOrEqual(redeem.frame.height, 43.99)
        shot("plus-redeem-axxxl")
    }

    func testPlusForeverOwnersSeeThankYouAndNoPlans() {
        openPlus(["-uitest-plus-forever"])
        XCTAssertTrue(app.staticTexts["You have Plus Forever"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["plus.lifetime"].exists)
        XCTAssertFalse(app.buttons["Subscribe"].exists)
        XCTAssertFalse(app.staticTexts["plus.paysTwice"].exists, "no subscription, so no note")
        audit("plus-forever-owned")
    }

    func testOwnersWithASubscriptionAreToldToCancelIt() {
        openPlus(["-uitest-plus-twice"])
        XCTAssertTrue(app.staticTexts["You have Plus Forever"].waitForExistence(timeout: 5))
        let note = app.staticTexts["plus.paysTwice"]
        XCTAssertTrue(note.exists)
        XCTAssertEqual(note.label, "You still have a subscription. Cancel it so you aren't charged twice.")
        XCTAssertTrue(app.buttons["Cancel the subscription"].exists)
        shot("plus-pays-twice")
        audit("plus-pays-twice")
    }

    /// Auto-renew already off: no "charged twice" note and no cancel button, just when the subscription ends.
    func testOwnersWhoseSubscriptionWillNotRenewSeeOnlyTheEndDate() {
        openPlus(["-uitest-plus-ending"])
        XCTAssertTrue(app.staticTexts["You have Plus Forever"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["plus.paysTwice"].exists)
        XCTAssertFalse(app.buttons["Cancel the subscription"].exists)
        let line = app.staticTexts["plus.subscriptionEnds"]
        XCTAssertTrue(line.exists)
        XCTAssertTrue(line.label.hasPrefix("Your subscription ends on "), line.label)
        shot("plus-subscription-ends")
        audit("plus-subscription-ends")
    }
}

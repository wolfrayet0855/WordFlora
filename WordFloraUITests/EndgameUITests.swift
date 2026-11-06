import XCTest

/// Weather helpers (E-7), the weather puzzle (E-8) and the Grand Garden (G-2 to G-5), with Apple's accessibility audit
/// on each screen at the default size and at an accessibility size. Fixtures: `EndgameUITestFixtures` in the app.
final class EndgameUITests: XCTestCase {
    var app: XCUIApplication!
    static let axSize = "UICTContentSizeCategoryAccessibilityXL"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private func launch(_ extra: [String], size: String? = nil) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything"] + extra
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Apple's audit, collecting every finding (as GuideUITests does). Contrast and Dynamic Type are judged only for
    /// elements fully inside the visible scroll area: text cut by a scroll edge is measured against what covers it, and
    /// a card half below the fold reads as "partially unsupported". Each element passed over this way is printed.
    /// `excuse`: findings passed over on purpose; each is printed.
    private func audit(_ name: String, excuse: @escaping (XCUIAccessibilityAuditIssue) -> Bool = { _ in false }) {
        var findings = [String]()
        let scroll = app.scrollViews.firstMatch
        // Text scrolled up under the navigation bar, or under iOS 26's soft scroll-edge fade just below it, is measured
        // against the bar and the fade, so the visible area starts 64 pt below the bar (text whose top sat 44 pt below
        // it still read as faded).
        let bar = app.navigationBars.firstMatch
        let top = bar.exists ? bar.frame.maxY + 64 : 0
        let visible: CGRect? = scroll.exists
            ? CGRect(x: scroll.frame.minX, y: max(scroll.frame.minY, top), width: scroll.frame.width, height: scroll.frame.maxY - max(scroll.frame.minY, top))
            : nil
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                if excuse(issue) { print("\(name): excused: \(issue.compactDescription) '\(issue.element?.label ?? "")'"); return true }
                if [.contrast, .dynamicType].contains(issue.auditType), let v = visible {
                    guard let e = issue.element else { return true }
                    if !v.contains(e.frame) { print("\(name): not judged at the scroll edge: '\(e.label)' \(e.frame)"); return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func openShed() {
        let shed = app.buttons["tile-Shed"]
        XCTAssertTrue(shed.waitForExistence(timeout: 8))
        shed.tap()
    }

    private func scrollTo(_ e: XCUIElement) {
        for _ in 0..<12 where !(e.exists && e.isHittable) { app.swipeUp() }
    }

    // MARK: Weather helpers

    func testTheShedSetsOutTomorrowsHelperForFree() {
        launch(["-uitest-weather-tomorrow=bigWind"])
        openShed()
        XCTAssertTrue(element("shed.weatherChip").waitForExistence(timeout: 5))
        XCTAssertTrue(element("shed.weatherChip").label.contains("Tomorrow"))
        let setOut = app.buttons["helper.windNet.setOut"]
        XCTAssertTrue(setOut.exists)
        XCTAssertFalse(app.buttons["helper.shadeCloth.setOut"].exists, "only the fitting helper has Set out")
        audit("shed-helpers")
        shot("shed-helpers")
        setOut.tap()
        XCTAssertTrue(element("helper.windNet.out").waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["helper.windNet.setOut"].exists)
        shot("shed-helpers-out")
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'plus' OR label CONTAINS[c] 'price'")).firstMatch.exists)
    }

    func testTheShedHelpersAtAnAccessibilitySize() {
        launch(["-uitest-weather-tomorrow=bigWind"], size: Self.axSize)
        openShed()
        XCTAssertTrue(element("shed.weatherChip").waitForExistence(timeout: 5))
        audit("shed-helpers-ax")
        shot("shed-helpers-ax")
    }

    func testCalmModeShowsNoHelpers() {
        launch(["-uitest-weather-tomorrow=bigWind", "-uitest-calm"])
        openShed()
        XCTAssertTrue(app.navigationBars["Garden Shed"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("shed.weatherChip").exists)
        XCTAssertFalse(app.buttons["helper.windNet.setOut"].exists)
    }

    // MARK: Weather puzzle

    private func openPuzzle(_ extra: [String] = [], size: String? = nil) {
        launch(["-uitest-weather-today=bigWind", "-uitest-weather-rewarded"] + extra, size: size)
        openShed()
        let entry = app.buttons["shed.weatherPuzzle"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        scrollTo(entry)
        entry.tap()
        XCTAssertTrue(element("weatherPuzzle.title").waitForExistence(timeout: 5))
    }

    func testThePuzzleNamesItsRewardAndSkipIsAsBigAsStart() {
        openPuzzle()
        XCTAssertTrue(element("weatherPuzzle.reward").label.contains("Rainbow sticker"))
        let start = app.buttons["weatherPuzzle.start"], skip = app.buttons["weatherPuzzle.skip"]
        XCTAssertEqual(start.frame.height, skip.frame.height, accuracy: 1, "Start and Skip are the same size")
        XCTAssertTrue(app.buttons["weatherPuzzle.harder"].exists, "a harder one is offered (opt-in)")
        audit("weather-puzzle-intro")
        shot("weather-puzzle-intro")
        skip.tap()
        XCTAssertTrue(app.navigationBars["Garden Shed"].waitForExistence(timeout: 5), "skipping costs nothing and closes")
    }

    func testTheHarderPuzzleHasAFreePeekAndADailyCap() {
        openPuzzle()
        app.buttons["weatherPuzzle.harder"].tap()
        app.buttons["weatherPuzzle.start"].tap()
        let peek = app.buttons["weatherPuzzle.peek"]
        XCTAssertTrue(peek.waitForExistence(timeout: 5))
        XCTAssertTrue(peek.isEnabled, "the first peek is free at once")
        audit("weather-puzzle-board")
        shot("weather-puzzle-board")
        peek.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ENDSWITH 'peeked'")).firstMatch.waitForExistence(timeout: 3))
        // The first puzzle counted once; two more fresh ones, then "That is plenty for today."
        app.buttons["weatherPuzzle.new"].tap()
        app.buttons["weatherPuzzle.new"].tap()
        app.buttons["weatherPuzzle.new"].tap()
        XCTAssertTrue(element("weatherPuzzle.plenty").waitForExistence(timeout: 5))
        audit("weather-puzzle-plenty")
    }

    func testThePuzzleAtAnAccessibilitySize() {
        openPuzzle(size: Self.axSize)
        audit("weather-puzzle-intro-ax")
        shot("weather-puzzle-intro-ax")
        scrollTo(app.buttons["weatherPuzzle.start"])
        app.buttons["weatherPuzzle.start"].tap()
        XCTAssertTrue(app.buttons["weatherPuzzle.new"].waitForExistence(timeout: 5))
        audit("weather-puzzle-board-ax")
    }

    /// The storm tier's last rung (critic note): "Picture clue after 2 peeks" from the start, ready after the second
    /// peek (the first is free at once, the second 30 s later), then the plant's picture with its clue in words.
    func testTheHarderPuzzlesPictureClueIsReadyAfterTwoPeeks() {
        openPuzzle()
        app.buttons["weatherPuzzle.harder"].tap()
        app.buttons["weatherPuzzle.start"].tap()
        let peek = app.buttons["weatherPuzzle.peek"], clue = app.buttons["weatherPuzzle.pictureClue"]
        XCTAssertTrue(peek.waitForExistence(timeout: 5))
        scrollTo(clue)
        XCTAssertTrue(clue.exists)
        XCTAssertEqual(clue.label, "Picture clue after 2 peeks")
        XCTAssertFalse(clue.isEnabled)
        peek.tap()
        XCTAssertFalse(clue.isEnabled, "one peek is not enough yet")
        let ready = NSPredicate(format: "isEnabled == true")
        expectation(for: ready, evaluatedWith: peek)
        waitForExpectations(timeout: 40)               // the next free peek, 30 s after the first
        peek.tap()
        XCTAssertTrue(clue.isEnabled)
        XCTAssertEqual(clue.label, "Picture clue")
        clue.tap()
        let card = element("weatherPuzzle.pictureClueCard")
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        XCTAssertTrue(card.label.hasPrefix("Picture clue. "), card.label)
        XCTAssertGreaterThan(card.label.count, "Picture clue. ".count + 10, "the picture has its words")
        scrollTo(card)
        audit("weather-puzzle-picture-clue")
        shot("weather-puzzle-picture-clue")
    }

    /// Plays the gentle puzzle to the end, reading its spots and letters and matching them to a catalog plant name.
    private func solveTheGentlePuzzle() {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("WordFlora/Resources/Plants.json")
        let names = ((try? JSONSerialization.jsonObject(with: Data(contentsOf: url))) as? [[String: Any]] ?? [])
            .compactMap { ($0["name"] as? String)?.uppercased().filter { $0.isLetter && $0.isASCII } }
        XCTAssertFalse(names.isEmpty, "the catalog is readable from the test")
        XCTAssertTrue(app.buttons["weatherPuzzle.tile.0"].waitForExistence(timeout: 5))
        let spots = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Spot '")).allElementsBoundByIndex.map(\.label)
        let given: [Character?] = spots.map { l in
            let tail = l.components(separatedBy: ", ").dropFirst().first ?? "open"
            return tail == "open" ? nil : tail.first
        }
        var tiles: [Character] = []
        while app.buttons["weatherPuzzle.tile.\(tiles.count)"].exists {
            tiles.append(app.buttons["weatherPuzzle.tile.\(tiles.count)"].label.last ?? " ")
        }
        let answer = names.first { n in
            guard n.count == given.count else { return false }
            let open = zip(n, given).filter { $0.1 == nil }.map(\.0)
            return zip(n, given).allSatisfy { $0.1 == nil || $0.1 == $0.0 } && open.sorted() == tiles.sorted()
        }
        guard let answer else { return XCTFail("no plant fits \(spots) / \(tiles)") }
        var used = Set<Int>()
        for (ch, g) in zip(answer, given) where g == nil {
            guard let i = tiles.indices.first(where: { tiles[$0] == ch && !used.contains($0) }) else { return XCTFail("no tile \(ch)") }
            used.insert(i)
            let tile = app.buttons["weatherPuzzle.tile.\(i)"]
            scrollTo(tile)
            tile.tap()
        }
    }

    /// A plant that comes with the puzzle's bonus word gets the same "New plant found!" moment as a won word.
    func testAPlantFromThePuzzleWordGetsTheNewPlantMoment() {
        openPuzzle(["-uitest-weather-plantready"])
        XCTAssertTrue(element("weatherPuzzle.reward").label.contains("a word toward your next plant"))
        app.buttons["weatherPuzzle.start"].tap()
        solveTheGentlePuzzle()
        let title = element("weatherPuzzle.plantFound")
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "New plant found!")
        sleep(4)                                    // the petal burst has drifted off
        audit("weather-puzzle-plant-found")
        shot("weather-puzzle-plant-found")
        let next = app.buttons["weatherPuzzle.plantFound.continue"]
        scrollTo(next)
        next.tap()
        XCTAssertTrue(element("weatherPuzzle.solved").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label ENDSWITH 'came to your garden!'")).firstMatch.exists)
    }

    // MARK: Grand Garden

    func testTheGrandGardenPlaysOnceThenWhatGrowsNext() {
        launch(["-uitest-crown"])
        XCTAssertTrue(element("grandGarden.title").waitForExistence(timeout: 8))
        XCTAssertTrue(element("grandGarden.hills").exists)
        audit("grand-garden")
        shot("grand-garden")
        app.buttons["grandGarden.next"].tap()
        XCTAssertTrue(element("whatsNext.title").waitForExistence(timeout: 5))
        audit("whats-next")
        shot("whats-next")
        let done = app.buttons["whatsNext.done"]
        scrollTo(done)
        done.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("home.crown").exists, "the crown rests on the wordmark")
        XCTAssertFalse(element("grandGarden.title").exists)
        shot("home-crown")
        // Back to Home again: it does not play twice.
        app.buttons["tile-Badges"].tap()
        XCTAssertTrue(element("badges.replayGrandGarden").waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("grandGarden.title").waitForExistence(timeout: 2))
    }

    func testTheGrandGardenAtAnAccessibilitySizeInDark() {
        XCUIDevice.shared.appearance = .dark
        launch(["-uitest-crown", "-uitest-dark", "-uitest-reduce-motion"], size: Self.axSize)
        XCTAssertTrue(element("grandGarden.title").waitForExistence(timeout: 8))
        sleep(2)                                // the full-screen cover has finished sliding in
        audit("grand-garden-ax-dark")
        shot("grand-garden-ax-dark")
        let next = app.buttons["grandGarden.next"]
        scrollTo(next)
        next.tap()
        XCTAssertTrue(element("whatsNext.title").waitForExistence(timeout: 5))
        audit("whats-next-ax-dark")
    }

    func testTheGoldCrownMoment() {
        launch(["-uitest-goldcrown", "-uitest-reduce-motion"])     // still art (petals are checked in the Grand Garden test)
        XCTAssertTrue(element("goldCrown.title").waitForExistence(timeout: 8))
        audit("gold-crown")
        shot("gold-crown")
        let done = app.buttons["goldCrown.done"]
        scrollTo(done)
        done.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
    }

    func testGoldenBloomsRanksReplayAndTheVisitorsBook() {
        launch(["-uitest-golden", "-uitest-album"])
        let golden = element("home.golden")
        XCTAssertTrue(golden.waitForExistence(timeout: 8))
        XCTAssertTrue(golden.label.contains("Daisy is 3 days from golden."), golden.label)
        audit("home-golden")
        shot("home-golden")
        app.buttons["tile-Badges"].tap()
        XCTAssertTrue(element("badges.bloomRank").waitForExistence(timeout: 5))
        // The rank and replay cards sit at the end of the page: scroll to the very end and let it settle, so the badge
        // grid above does not reflow under the audit (the pattern found for the Shed audit).
        for _ in 0..<8 { app.swipeUp() }
        sleep(2)
        // The badge grid above is the existing Badges page (audited on its own in WordFloraUITests.testAuditMoreScreens);
        // after a long scroll its lazy cards reflow under the Dynamic Type check, so here only Dynamic Type on grid
        // cards is passed over. The rank and replay cards are judged in full.
        // The grid ends above the Grand Garden card, whose top is just above its replay button.
        let gridBottom = app.buttons["badges.replayGrandGarden"].frame.minY - 40
        audit("badges-rank", excuse: { issue in
            guard issue.auditType == .dynamicType, let e = issue.element else { return false }
            return e.frame.maxY <= gridBottom
        })
        app.buttons["badges.replayGrandGarden"].tap()
        XCTAssertTrue(element("grandGarden.title").waitForExistence(timeout: 5))
        app.buttons["grandGarden.walk"].tap()
        XCTAssertTrue(element("badges.bloomRank").waitForExistence(timeout: 5), "a replay closes back to Badges")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["tile-Visitors"].tap()
        let book = app.buttons["visitors.book"]
        XCTAssertTrue(book.waitForExistence(timeout: 5))
        scrollTo(book)
        book.tap()
        XCTAssertTrue(element("book.page.monarch").waitForExistence(timeout: 5))
        audit("visitors-book")
        shot("visitors-book")
    }

    /// G-3: a level whose plants are all in full bloom gets a bloom wave along its path, then a still garland. The art
    /// is decorative (hidden from VoiceOver; the card says "Full bloom garden!"), so this checks the page around it.
    func testTheLevelMapBloomsAlongFullBloomLevels() {
        launch(["-uitest-golden"])
        let levels = app.buttons["tile-Levels"]
        XCTAssertTrue(levels.waitForExistence(timeout: 8))
        levels.tap()
        XCTAssertTrue(app.staticTexts["Garden Path"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Full bloom garden!"].waitForExistence(timeout: 3))
        shot("level-map-bloom-wave-playing")
        sleep(3)                                    // the wave has opened and holds still
        shot("level-map-bloom-garland")
        audit("level-map-bloom-garland")
    }

    func testTheLevelMapGarlandIsStillWithReduceMotionInDark() {
        XCUIDevice.shared.appearance = .dark
        launch(["-uitest-golden", "-uitest-reduce-motion", "-uitest-dark"])
        let levels = app.buttons["tile-Levels"]
        XCTAssertTrue(levels.waitForExistence(timeout: 8))
        levels.tap()
        XCTAssertTrue(app.staticTexts["Full bloom garden!"].waitForExistence(timeout: 5))
        sleep(1)
        shot("level-map-bloom-garland-still-dark")
        audit("level-map-bloom-garland-dark")
    }

    func testTheGoldenPlantPage() {
        launch(["-uitest-golden"])
        XCTAssertTrue(element("home.golden").waitForExistence(timeout: 8))
        element("home.golden").tap()
        let line = element("plant.golden")
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertEqual(line.label, "Daisy is 3 days from golden.")
        shot("plant-golden-progress")
    }
}

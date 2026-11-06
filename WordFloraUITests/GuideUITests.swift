import XCTest

/// The first-run onboarding guide (design-preview/onboarding-guide): after the age question, eight pages with Skip on
/// each, Next to the tutorial word, a replay from Settings, and Apple's accessibility audit at default and large text.
final class GuideUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }
    private var skip: XCUIElement { app.buttons["onboardingGuide.skip"] }
    private var next: XCUIElement { app.buttons["onboardingGuide.next"] }
    private var back: XCUIElement { app.buttons["onboardingGuide.back"] }
    private var dots: XCUIElement { element("onboardingGuide.page") }
    private var pageValue: String { dots.value as? String ?? "" }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// A first launch, through the intro and the age question, to page 1 of the guide.
    private func openGuide(_ extra: [String] = [], age: String = "18 or older") {
        app.launchArguments = ["-uitest", "-uitest-word=SEED"] + extra
        app.launch()
        XCTAssertTrue(app.buttons[age].waitForExistence(timeout: 12))                  // after the petal intro
        app.buttons[age].tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5), "the guide follows the age question")
        XCTAssertEqual(pageValue, "Page 1 of 8")
    }

    private func goTo(page: Int) {
        while pageValue != "Page \(page) of 8" {
            next.tap()
            _ = dots.waitForExistence(timeout: 2)
        }
    }

    private func assertTutorialWord(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts["Tap a letter to guess"].waitForExistence(timeout: 6), "the tutorial word", file: file, line: line)
        XCTAssertFalse(app.buttons["Play"].exists, file: file, line: line)
        XCTAssertFalse(next.exists, file: file, line: line)
    }

    // MARK: The first age tap

    /// A fast player taps an age the moment it appears, while the age question is still fading in from the intro.
    /// One tap, no second try: it must count.
    /// `-uitest-handoff=4` stretches the 0.4 s cross-fade so the tap surely lands inside it.
    func testTheFirstAgeTapCountsWhileTheQuestionFadesIn() {
        app.launchArguments = ["-uitest", "-uitest-word=SEED", "-uitest-handoff=4"]
        app.launch()
        let age = app.buttons["18 or older"]
        XCTAssertTrue(age.waitForExistence(timeout: 12))
        age.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 2), "the first age tap leads to the guide")
    }

    /// The same after tapping the intro to skip it: the skip tap is not carried over and the next tap picks the age.
    func testTheFirstAgeTapCountsRightAfterSkippingTheIntro() {
        app.launchArguments = ["-uitest", "-uitest-word=SEED", "-uitest-intro-hold", "-uitest-handoff=4"]
        app.launch()
        let intro = element("intro")
        XCTAssertTrue(intro.waitForExistence(timeout: 6))
        intro.tap()
        let age = app.buttons["Under 13"]
        XCTAssertTrue(age.waitForExistence(timeout: 3))
        age.tap()
        XCTAssertTrue(app.buttons["Yes, keep it quiet"].waitForExistence(timeout: 2), "the first age tap opens the quiet offer")
    }

    // MARK: First run

    func testGuideShowsAfterTheAgeQuestionAndNextReachesTheFirstWord() {
        openGuide()
        XCTAssertTrue(skip.exists)
        XCTAssertEqual(skip.label, "Skip")
        XCTAssertFalse(back.exists, "no Back on page 1")
        XCTAssertTrue(app.staticTexts["Guess the word"].exists)
        XCTAssertFalse(app.buttons["Play"].exists, "no home chrome in the first session")

        // Swiping pages works too.
        element("onboardingGuide.art").swipeLeft()
        XCTAssertTrue(app.staticTexts["Three words, one plant"].waitForExistence(timeout: 3))
        XCTAssertEqual(pageValue, "Page 2 of 8")
        element("onboardingGuide.art").swipeRight()
        XCTAssertTrue(app.staticTexts["Guess the word"].waitForExistence(timeout: 3))

        let titles = ["Three words, one plant", "Help your plant grow", "Hearts and hellos", "Your garden and friends",
                      "One word for everyone", "Five levels to explore", "Coming soon in your garden"]
        for (i, title) in titles.enumerated() {
            next.tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3), title)
            XCTAssertEqual(pageValue, "Page \(i + 2) of 8")
            XCTAssertTrue(back.exists)
        }
        XCTAssertFalse(skip.exists, "Skip steps aside on the last page")
        XCTAssertEqual(next.label, "Start playing")
        let shop = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS '$' OR label CONTAINS[c] 'plus' OR label CONTAINS[c] 'lock'"))
        XCTAssertEqual(shop.count, 0, "no prices, Plus or locks in the guide")
        back.tap()
        XCTAssertEqual(pageValue, "Page 7 of 8")
        next.tap()
        next.tap()
        assertTutorialWord()
    }

    private func skipWorks(onPage page: Int) {
        openGuide()
        goTo(page: page)
        XCTAssertTrue(skip.isHittable)
        skip.tap()
        assertTutorialWord()
    }

    func testSkipOnPageOneGoesToTheFirstWord() { skipWorks(onPage: 1) }
    func testSkipOnPageFourGoesToTheFirstWord() { skipWorks(onPage: 4) }
    func testSkipOnPageSevenGoesToTheFirstWord() { skipWorks(onPage: 7) }

    /// A young player who keeps the garden quiet: the guide's page 4 says the plant keeps all it grows (no rain talk).
    func testQuietGardenChangesThePageAboutHearts() {
        app.launchArguments = ["-uitest", "-uitest-word=SEED"]
        app.launch()
        XCTAssertTrue(app.buttons["Under 13"].waitForExistence(timeout: 12))
        app.buttons["Under 13"].tap()
        XCTAssertTrue(app.buttons["Yes, keep it quiet"].waitForExistence(timeout: 4))
        app.buttons["Yes, keep it quiet"].tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        goTo(page: 4)
        XCTAssertTrue(app.staticTexts["Your plant keeps all it grows, always."].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'rainy'")).firstMatch.exists)
        shot("guide-p4-quiet")
    }

    // MARK: Replay from Settings

    func testShowTheGuideAgainFromSettings() {
        app.launchArguments = ["-uitest", "-uitest-onboarded"]
        app.launch()
        app.buttons["Settings"].tap()
        let row = app.buttons["settings.showGuide"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertEqual(row.label, "Show the guide again")
        row.tap()
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        XCTAssertEqual(skip.label, "Close")
        XCTAssertEqual(pageValue, "Page 1 of 8")
        shot("guide-replay-p1")
        skip.tap()
        XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5), "Close goes back to Settings")
        XCTAssertFalse(next.exists)

        row.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        goTo(page: 8)
        XCTAssertEqual(next.label, "Done")
        shot("guide-replay-p8")
        next.tap()
        XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5), "Done goes back to Settings")
    }

    // MARK: Accessibility audits

    /// Apple's audit, collecting every finding. Text a scroll view clips at its edge is measured against whatever covers
    /// it, so only text fully inside the page's scroll view is judged for contrast (as in WordFloraUITests).
    private func audit(_ name: String) {
        var findings = [String]()
        let scroll = app.scrollViews.firstMatch
        let visible: CGRect? = scroll.exists ? scroll.frame : nil
        var skipped = [String]()
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                if issue.auditType == .contrast, let v = visible {
                    guard let e = issue.element else { skipped.append(issue.compactDescription); return true }
                    if !v.contains(e.frame) { return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | \(issue.element?.elementType.rawValue ?? 0) '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if !skipped.isEmpty { print("\(name): contrast on \(skipped.count) clipped, unresolved element(s) not judged") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func auditPages(_ pages: ClosedRange<Int>, prefix: String) {
        goTo(page: pages.lowerBound)
        for p in pages {
            goTo(page: p)
            sleep(1)
            audit("\(prefix)-p\(p)")
        }
    }

    func testAuditGuidePagesOneToFour() { openGuide(["-uitest-reduce-motion"]); auditPages(1...4, prefix: "guide") }
    func testAuditGuidePagesFiveToEight() { openGuide(["-uitest-reduce-motion"]); auditPages(5...8, prefix: "guide") }

    private static let axText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    func testAuditGuideAtAccessibilityTextPagesOneToFour() { openGuide(Self.axText + ["-uitest-reduce-motion"]); auditPages(1...4, prefix: "guide-ax") }
    func testAuditGuideAtAccessibilityTextPagesFiveToEight() { openGuide(Self.axText + ["-uitest-reduce-motion"]); auditPages(5...8, prefix: "guide-ax") }

    /// At the largest text the buttons stack, the page scrolls, and nothing is cut off.
    func testAccessibilityTextStacksTheButtonsAndScrolls() {
        openGuide(Self.axText)
        next.tap()
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(back.frame.minY, next.frame.maxY - 1, "Back sits under Next at accessibility sizes")
        XCTAssertEqual(back.frame.width, next.frame.width, accuracy: 1)
        let lastLine = app.staticTexts["After that, every 3 words brings a new plant."]
        for _ in 0..<4 where !lastLine.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(lastLine.isHittable, "the page scrolls to its last line")
    }

    // MARK: Screenshots (compared by eye with design-preview/onboarding-guide/shots)

    private func shootAll(_ prefix: String, _ extra: [String]) {
        openGuide(extra)
        for p in 1...8 {
            goTo(page: p)
            sleep(1)
            shot("\(prefix)-p\(p)")
        }
    }

    func testScreenshotsLight() { shootAll("guide-light", []) }
    func testScreenshotsDark() { shootAll("guide-dark", ["-uitest-dark"]) }
    func testScreenshotsReduceMotion() { shootAll("guide-rm", ["-uitest-reduce-motion"]) }
    func testScreenshotsAccessibilityText() { shootAll("guide-ax", Self.axText) }
}

/// The Quiet Garden offer after "Under 13" (design-preview/quiet-garden): a full screen in place of the age question,
/// both choices work, Back returns, and Apple's audit passes at default and accessibility text sizes, light and dark.
final class QuietGardenOfferUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private var yes: XCUIElement { app.buttons["quietOffer.yes"] }
    private var no: XCUIElement { app.buttons["quietOffer.no"] }
    private var next: XCUIElement { app.buttons["onboardingGuide.next"] }
    private static let axText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func openOffer(_ extra: [String] = []) {
        app.launchArguments = ["-uitest", "-uitest-word=SEED"] + extra
        app.launch()
        let under13 = app.buttons["Under 13"]
        XCTAssertTrue(under13.waitForExistence(timeout: 12))
        // These tests are about the offer, not the first tap during the intro's cross-fade (GuideUITests covers that),
        // so wait for the question to settle before tapping.
        expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: under13)
        waitForExpectations(timeout: 6)
        sleep(1)
        under13.tap()
        XCTAssertTrue(yes.waitForExistence(timeout: 6), "Under 13 opens the Quiet Garden offer")
    }

    func testUnder13OpensTheOfferInPlaceOfTheAgeQuestion() {
        openOffer()
        XCTAssertTrue(app.staticTexts["Would you like a quiet garden?"].exists)
        XCTAssertTrue(app.staticTexts["No points or counting. Just tending."].exists)
        XCTAssertTrue(app.staticTexts["You still guess words and grow plants."].exists)
        XCTAssertTrue(app.descendants(matching: .any)["quietOffer.note"].exists)
        XCTAssertEqual(yes.label, "Yes, keep it quiet")
        XCTAssertEqual(no.label, "No thanks, show everything")
        XCTAssertFalse(app.buttons["18 or older"].exists, "the age question leaves while the offer shows")
        XCTAssertFalse(app.sheets.firstMatch.exists, "no system dialog")
        XCTAssertGreaterThanOrEqual(yes.frame.height, 44)
        XCTAssertGreaterThanOrEqual(no.frame.height, 44)
        XCTAssertEqual(yes.frame.width, no.frame.width, accuracy: 1, "two choices of the same size")
        XCTAssertEqual(yes.frame.height, no.frame.height, accuracy: 1)
        XCTAssertTrue(yes.isHittable && no.isHittable)
    }

    func testYesKeepsItQuietAndGoesOnToTheGuide() {
        openOffer()
        yes.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5), "the guide follows")
        XCTAssertEqual(app.descendants(matching: .any)["onboardingGuide.page"].value as? String, "Page 1 of 8")
        XCTAssertFalse(yes.exists)
    }

    func testNoThanksGoesOnToTheGuide() {
        openOffer()
        no.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5), "the guide follows")
        XCTAssertFalse(no.exists)
    }

    func testBackReturnsToTheAgeQuestion() {
        openOffer()
        app.buttons["quietOffer.back"].tap()
        XCTAssertTrue(app.buttons["18 or older"].waitForExistence(timeout: 3))
        XCTAssertFalse(yes.exists)
        app.buttons["Under 13"].tap()
        XCTAssertTrue(yes.waitForExistence(timeout: 3), "the offer opens again")
    }

    /// At the largest text everything wraps (nothing cut off) and the page scrolls to the note.
    func testAccessibilityTextWrapsAndScrolls() {
        openOffer(Self.axText)
        let note = app.descendants(matching: .any)["quietOffer.note"]
        for _ in 0..<6 where !note.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(note.isHittable, "the page scrolls to its note")
        XCTAssertTrue(no.isHittable)
        XCTAssertEqual(yes.frame.width, no.frame.width, accuracy: 1)
        XCTAssertGreaterThanOrEqual(no.frame.height, 44)
        no.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
    }

    // MARK: Accessibility audits

    /// Apple's audit, collecting every finding. Only text fully inside the scroll view is judged for contrast (text a
    /// scroll view clips at its edge is measured against whatever covers it), as in GuideUITests.
    private func audit(_ name: String) {
        var findings = [String]()
        let scroll = app.scrollViews.firstMatch
        let visible: CGRect? = scroll.exists ? scroll.frame : nil
        do {
            try app.performAccessibilityAudit(for: .all) { issue in
                if issue.auditType == .contrast, let v = visible {
                    guard let e = issue.element else { return true }
                    if !v.contains(e.frame) { return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    func testAuditAtDefaultSize() { openOffer(["-uitest-reduce-motion"]); sleep(1); audit("quiet-offer") }
    func testAuditInDark() { openOffer(["-uitest-reduce-motion", "-uitest-dark"]); sleep(1); audit("quiet-offer-dark") }
    func testAuditAtAccessibilitySize() {
        openOffer(Self.axText + ["-uitest-reduce-motion"])
        sleep(1)
        audit("quiet-offer-ax-top")
        app.scrollViews.firstMatch.swipeUp(); app.scrollViews.firstMatch.swipeUp()
        sleep(1)
        audit("quiet-offer-ax-bottom")
    }

    // MARK: Screenshots (compared by eye with design-preview/quiet-garden/shots; run with TEST_RUNNER_SCREENSHOT_DIR=<dir>)

    func testScreenshots() {
        for (name, extra) in [("quiet-offer-light", []), ("quiet-offer-dark", ["-uitest-dark"]),
                              ("quiet-offer-rm", ["-uitest-reduce-motion"]), ("quiet-offer-ax", Self.axText)] {
            openOffer(extra)
            sleep(1)
            shot(name)
            if name == "quiet-offer-ax" { app.scrollViews.firstMatch.swipeUp(); sleep(1); shot("quiet-offer-ax-bottom") }
            app.terminate()
        }
    }
}

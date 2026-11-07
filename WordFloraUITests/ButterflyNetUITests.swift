import XCTest

/// The butterfly net, Quick wings and Gentle Net in the running app (gate G2b, docs/pm/butterfly-net-spec.md section 8):
/// who sees Easier butterflies and the Quick wings chip, which pace the scene plays, a short round to the summary, a
/// gentle hello under Reduce Motion that earns the Gentle Net badge, and Apple's accessibility audit in light and dark,
/// at the default size and AX XXXL. Flags: `-uitest-easier-butterflies`, `-uitest-butterfly-short`,
/// `-uitest-butterfly-seed=`, `-uitest-gentlenet` (nine gentle hellos already).
final class ButterflyNetUITests: XCTestCase {
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
        XCUIDevice.shared.appearance = dark ? .dark : .light
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything", "-uitest-daytime",
                               "-uitest-butterfly-seed=7"] + extra + (dark ? ["-uitest-dark"] : [])
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

    /// Badge moments dim the app: wait until none is showing (one may follow another), and return the badges they named.
    @discardableResult
    private func letBadgeMomentsPass() -> [String] {
        var seen = [String]()
        let moment = element("badgeMoment")
        while moment.waitForExistence(timeout: 4) {
            seen.append(moment.label)
            XCTAssertTrue(moment.waitForNonExistence(timeout: 12), "the badge moment goes")
        }
        return seen
    }

    /// Apple's audit, every finding collected. Contrast and Dynamic Type are judged only for elements fully inside the
    /// visible scroll area (as in BadgeMechanicsUITests); the Dynamic Type and clipped-text checks run on their own after
    /// the rest, since they grow the text and reflow the page.
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

    private func openSettings() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5))
    }

    private func openVisitors() {
        app.buttons["Visitors"].tap()
        XCTAssertTrue(app.buttons["Say hello"].waitForExistence(timeout: 5))
    }

    private func openGame() {
        openVisitors()
        app.buttons["Say hello"].tap()
        XCTAssertTrue(app.navigationBars["Butterfly game"].waitForExistence(timeout: 5))
    }

    private var summary: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'You met' OR label == 'Thanks for visiting the garden'")).firstMatch
    }

    // MARK: Who sees what

    func testEasierButterfliesIsOfferedToThirteenPlusOnly() {
        launch(["-uitest-age=thirteenPlus"])
        openSettings()
        let toggle = app.switches["settings.easierButterflies"]
        scrollTo(toggle)
        XCTAssertTrue(toggle.exists)
        XCTAssertEqual(toggle.value as? String, "0", "off by default: Quick wings plays")
        XCTAssertTrue(element("settings.easierButterfliesNote").exists)
        shot("net-settings-13plus")
        app.terminate()
        for args in [["-uitest-age=thirteenPlus", "-uitest-calm"], ["-uitest-age=under13"]] {
            launch(args)
            openSettings()
            for _ in 0..<4 { app.swipeUp() }
            XCTAssertFalse(app.switches["settings.easierButterflies"].exists, "\(args)")
            XCTAssertFalse(element("settings.easierButterfliesNote").exists, "\(args)")
            app.terminate()
        }
    }

    func testTheQuickWingsChipShowsForThirteenPlusOnly() {
        launch(["-uitest-age=thirteenPlus"])
        openVisitors()
        XCTAssertTrue(element("visitors.quickWings").exists)
        XCTAssertTrue(app.staticTexts["Follow the visitors with your net. They flit and turn. Every visit is a good one."].exists)
        shot("net-visitors-quickwings")
        app.terminate()
        for args in [["-uitest-age=under13"], ["-uitest-age=thirteenPlus", "-uitest-easier-butterflies"], ["-uitest-age=eighteenPlus", "-uitest-reduce-motion"]] {
            launch(args)
            openVisitors()
            XCTAssertFalse(element("visitors.quickWings").exists, "\(args)")
            app.terminate()
        }
    }

    func testTheSceneSaysWhichPaceItPlays() {
        let cases: [([String], String)] = [
            (["-uitest-age=eighteenPlus"], "butterfly.scene.quickWings"),
            (["-uitest-age=thirteenPlus", "-uitest-easier-butterflies"], "butterfly.scene.gentle"),
            (["-uitest-age=under13"], "butterfly.scene.calm"),
            (["-uitest-age=eighteenPlus", "-uitest-reduce-motion"], "butterfly.scene.gentle"),
        ]
        for (args, id) in cases {
            launch(args)
            openGame()
            XCTAssertTrue(element(id).waitForExistence(timeout: 5), "\(args) plays \(id)")
            app.terminate()
        }
    }

    // MARK: Rounds

    func testAQuickWingsShortRoundReachesTheSummaryWithRewards() {
        launch(["-uitest-age=thirteenPlus", "-uitest-butterfly-short"])
        openGame()
        XCTAssertTrue(element("butterfly.scene.quickWings").exists)
        XCTAssertTrue(app.progressIndicators["Game progress"].exists)
        sleep(2)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.35)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.45)))
        shot("net-quickwings-playing")
        XCTAssertTrue(summary.waitForExistence(timeout: 15), "the summary appears")
        XCTAssertTrue(element("butterfly.summary.rewards").exists, "every rewarded play pays something")
        shot("net-quickwings-summary")
    }

    func testQuietGardenSummaryShowsNoRewardsRow() {
        launch(["-uitest-age=thirteenPlus", "-uitest-butterfly-short", "-uitest-quiet"])
        openGame()
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        XCTAssertFalse(element("butterfly.summary.rewards").exists)
        XCTAssertFalse(element("butterfly.summary.gentle").exists)
    }

    /// Reduce Motion: every visitor rests, so a hello there is a gentle one. VoiceOver-style activation needs no aiming.
    /// Nine gentle hellos already, so this one earns the bronze Gentle Net badge after the summary.
    func testAGentleHelloUnderReduceMotionEarnsGentleNet() {
        launch(["-uitest-age=thirteenPlus", "-uitest-reduce-motion", "-uitest-butterfly-short", "-uitest-gentlenet"])
        openGame()
        XCTAssertTrue(element("butterfly.scene.gentle").exists, "Reduce Motion keeps the gentle game")
        let resting = app.buttons.matching(NSPredicate(format: "label ENDSWITH ', resting on a flower'")).firstMatch
        XCTAssertTrue(resting.waitForExistence(timeout: 5))
        shot("net-reduce-motion-resting")
        resting.tap()
        XCTAssertTrue(app.staticTexts["1 said hello"].waitForExistence(timeout: 3))
        shot("net-gentle-hello")
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        XCTAssertEqual(element("butterfly.summary.gentle").label, "1 gentle hello")
        shot("net-gentle-summary")
        // The first friend met also earns Visitor Friend and First Catch; the moments come one after another.
        XCTAssertTrue(element("badgeMoment").waitForExistence(timeout: 8))
        shot("net-gentle-badge-moment")
        let moments = letBadgeMomentsPass()
        XCTAssertTrue(moments.contains { $0.contains("Gentle Net") }, "ten gentle hellos earn the bronze Gentle Net badge: \(moments)")
    }

    // MARK: Accessibility audits

    func testAuditSettingsPlay() {
        for (size, dark) in [(nil, false), (Self.axXXXL, true), (Self.axXXXL, false)] as [(String?, Bool)] {
            launch(["-uitest-age=thirteenPlus"], size: size, dark: dark)
            openSettings()
            let note = element("settings.easierButterfliesNote")
            scrollTo(note)
            sleep(1)
            let name = "net-settings\(size == nil ? "" : "-ax5")\(dark ? "-dark" : "")"
            shot(name)
            audit(name)
            app.terminate()
        }
    }

    func testAuditTheVisitorsCard() {
        for (size, dark) in [(nil, false), (nil, true), (Self.axXXXL, true), (Self.axXXXL, false)] as [(String?, Bool)] {
            launch(["-uitest-age=thirteenPlus"], size: size, dark: dark)
            openVisitors()
            let chip = element("visitors.quickWings")
            scrollTo(chip)
            XCTAssertTrue(chip.exists)
            let name = "net-visitors\(size == nil ? "" : "-ax5")\(dark ? "-dark" : "")"
            shot(name)
            audit(name)
            app.terminate()
        }
    }

    /// The game itself, held still with Reduce Motion so the audit sees one frame.
    func testAuditTheGameScene() {
        for (size, dark) in [(nil, false), (Self.axXXXL, true)] as [(String?, Bool)] {
            launch(["-uitest-age=thirteenPlus", "-uitest-reduce-motion"], size: size, dark: dark)
            openGame()
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ENDSWITH ', resting on a flower'")).firstMatch.waitForExistence(timeout: 5))
            sleep(5)                                   // the one-time tip has gone
            let name = "net-game\(size == nil ? "" : "-ax5")\(dark ? "-dark" : "")"
            shot(name)
            audit(name)
            app.terminate()
        }
    }

    func testAuditTheSummaryWithAGentleHello() {
        launch(["-uitest-age=thirteenPlus", "-uitest-reduce-motion", "-uitest-butterfly-short"], size: Self.axXXXL, dark: true)
        openGame()
        let resting = app.buttons.matching(NSPredicate(format: "label ENDSWITH ', resting on a flower'")).firstMatch
        XCTAssertTrue(resting.waitForExistence(timeout: 5))
        resting.tap()
        XCTAssertTrue(summary.waitForExistence(timeout: 15))
        letBadgeMomentsPass()
        sleep(1)
        shot("net-summary-ax5-dark")
        audit("net-summary-ax5-dark")
    }

    /// Screenshots of the net art (day and evening are clock-driven; these are day, light and dark app appearance).
    func testNetScreenshots() {
        for dark in [false, true] {
            launch(["-uitest-age=eighteenPlus"], dark: dark)
            openGame()
            sleep(3)
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4))
            start.press(forDuration: 1.5, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.42)))
            shot("net-held-\(dark ? "dark" : "light")")
            sleep(1)
            shot("net-resting-\(dark ? "dark" : "light")")
            app.terminate()
        }
    }
}

import XCTest

/// Speed bloom in the running app: who sees the Settings toggle, the round turning to "Take your time" when the gold
/// ring closes (with nothing taken away), the badge shelf, and Apple's accessibility audit of the game with it on.
final class SpeedBloomUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = []) {
        var findings = [String]()
        do {
            try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(ignoring)) { issue in
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    /// A level 4 word with Speed bloom on (`-uitest-onboarded` answers 18+).
    private func launchGame(_ extra: [String] = [], word: String = "LOTUS") {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-word=\(word)", "-uitest-word-level=4", "-uitest-speedbloom"] + extra
        app.launch()
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 8))
    }

    private func openSettings(_ args: [String]) {
        app.launchArguments = ["-uitest", "-uitest-onboarded"] + args
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Haptics"].waitForExistence(timeout: 5))
    }

    // MARK: Settings

    func testTheToggleIsOfferedToGrownUpsOffByDefaultAndExtraTimeAppearsOnceItIsOn() {
        openSettings([])
        let toggle = app.switches["settings.speedBloom"]
        XCTAssertTrue(toggle.exists)
        XCTAssertEqual(toggle.value as? String, "0", "off by default")
        XCTAssertFalse(app.switches["settings.speedBloomExtraTime"].exists)
        XCTAssertTrue(element("settings.speedBloomNote").exists)
        shot("speedbloom-settings-off")
        toggle.switches.firstMatch.tap()
        XCTAssertTrue(app.switches["settings.speedBloomExtraTime"].waitForExistence(timeout: 3))
        shot("speedbloom-settings-on")
    }

    func testTheToggleIsOfferedToThirteenPlus() {
        openSettings(["-uitest-age=thirteenPlus"])
        XCTAssertTrue(app.switches["settings.speedBloom"].exists)
    }

    func testTheToggleIsHiddenUnderThirteenInCalmAndInQuietGarden() {
        for args in [["-uitest-age=under13"], ["-uitest-calm"], ["-uitest-quiet"]] {
            openSettings(args)
            XCTAssertFalse(app.switches["settings.speedBloom"].exists, "\(args)")
            XCTAssertFalse(element("settings.speedBloomNote").exists, "\(args)")
            app.terminate()
        }
    }

    // MARK: The round

    func testWhenTheRingClosesTheWordCarriesOnWithNothingTakenAway() {
        launchGame(["-uitest-speedbloom-seconds=2"])
        XCTAssertTrue(element("speedBloom.takeYourTime").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Take your time"].exists || element("speedBloom.takeYourTime").label == "Take your time")
        XCTAssertTrue(element("8 of 8 petals on the flower").exists, "no petal cost")
        XCTAssertTrue(app.buttons["L"].isEnabled, "the round goes on")
        shot("speedbloom-take-your-time")
        for ch in "LOTUS" { app.buttons[String(ch)].tap() }
        // The win card's button is "Next word" since polish pass 2 ("Continue" on the Daily Bloom and the tutorial).
        let next = app.buttons.matching(NSPredicate(format: "label IN %@", ["Continue", "Next word"])).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 6))
    }

    func testTheRingHoldsWhileHelpIsUsed() {
        launchGame(["-uitest-speedbloom-seconds=3"])
        app.buttons["Help"].tap()
        sleep(5)                                              // within the 10 s Help pause
        XCTAssertFalse(element("speedBloom.takeYourTime").exists)
        XCTAssertTrue(element("speedBloom.takeYourTime").waitForExistence(timeout: 15))
    }

    func testNoRingForUnderThirteenInCalmOrBelowLevelFour() {
        let cases: [[String]] = [["-uitest-age=under13"], ["-uitest-calm"], ["-uitest-quiet"]]
        for extra in cases {
            launchGame(extra + ["-uitest-speedbloom-seconds=1"])
            sleep(3)
            XCTAssertFalse(element("speedBloom.takeYourTime").exists, "\(extra)")
            app.terminate()
        }
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-word=LOTUS", "-uitest-speedbloom", "-uitest-speedbloom-seconds=1"]
        app.launch()
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["Z"].waitForExistence(timeout: 8))
        sleep(3)
        XCTAssertFalse(element("speedBloom.takeYourTime").exists, "a level 1 word has no ring")
    }

    // MARK: Badge shelf

    func testQuickBloomIsOnTheShelfOnlyWhenSpeedBloomIsOn() {
        let quick = NSPredicate(format: "label BEGINSWITH 'Quick Bloom'")
        for (args, shown) in [(["-uitest-speedbloom"], true), ([String](), false)] {
            app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened", "-uitest-everything"] + args
            app.launch()
            app.buttons["Badges"].tap()
            XCTAssertTrue(app.staticTexts["Green Thumb"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.descendants(matching: .any).matching(quick).firstMatch.exists, shown, "\(args)")
            if shown { shot("speedbloom-badges") }
            app.terminate()
        }
    }

    // MARK: Accessibility audits

    func testAuditTheGameWithSpeedBloomOn() {
        launchGame()
        audit("speedbloom-game")
        shot("speedbloom-game")
    }

    func testAuditTheGameWithSpeedBloomOnAtAnAccessibilitySize() {
        launchGame(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        audit("speedbloom-game-ax")
        shot("speedbloom-game-ax")
    }

    func testAuditTakeYourTimeAtDefaultAndAccessibilitySizes() {
        for extra in [[String](), ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]] {
            launchGame(extra + ["-uitest-speedbloom-seconds=1"])
            XCTAssertTrue(element("speedBloom.takeYourTime").waitForExistence(timeout: 10))
            audit("speedbloom-relaxed\(extra.isEmpty ? "" : "-ax")")
            shot("speedbloom-relaxed\(extra.isEmpty ? "" : "-ax")")
            app.terminate()
        }
    }
}

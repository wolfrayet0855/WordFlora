import XCTest

/// The text-fit and polish pass (docs/pm/textfit-builder-brief.md, sections 8 and 9): screenshots of every touched
/// screen at xxxLarge and AX XXXL (light and dark where it matters), and Apple's accessibility audit at AX XXXL in light
/// and dark with no waivers for clipped or truncated text. Shots are named `<screen>-<width>-<size>-<scheme>` and are
/// written to SCREENSHOT_DIR when it is set (TEST_RUNNER_SCREENSHOT_DIR), and attached to the result either way.
/// The word widths themselves are measured in TextFitLayoutTests.
final class TextFitScreensUITests: XCTestCase {
    var app: XCUIApplication!
    static let ax5 = "UICTContentSizeCategoryAccessibilityXXXL"
    static let xxxl = "UICTContentSizeCategoryXXXL"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        executionTimeAllowance = 400
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func launch(_ extra: [String], size: String? = nil, dark: Bool = false) {
        XCUIDevice.shared.appearance = dark ? .dark : .light
        app.launchArguments = ["-uitest", "-uitest-onboarded"] + extra + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
    }

    private func sizeName(_ size: String?) -> String { size == Self.ax5 ? "ax5" : size == Self.xxxl ? "xxxl" : "default" }

    private func shot(_ screen: String, _ size: String?, dark: Bool, _ suffix: String = "") {
        let width = Int(app.windows.firstMatch.frame.width)
        let name = "\(screen)\(suffix)-\(width)-\(sizeName(size))-\(dark ? "dark" : "light")"
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Every audit type. Contrast is judged only on elements fully inside the visible scroll area (text scrolled under
    /// the navigation bar's fade is measured against the fade); a contrast issue with no element is noted, not failed.
    /// Clipped text and Dynamic Type run apart, after the rest, as in TendingUITests (both grow the text and reflow).
    private func audit(_ name: String) {
        auditOnce(name, types: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped]))
        auditOnce(name + "-textClipped", types: .textClipped)
        auditOnce(name + "-dynamicType", types: .dynamicType)
    }

    private func auditOnce(_ name: String, types: XCUIAccessibilityAuditType) {
        var findings = [String](), skipped = [String]()
        let scroll = app.scrollViews.firstMatch, nav = app.navigationBars.firstMatch
        let top = nav.exists ? nav.frame.maxY + 64 : 0
        let visible: CGRect? = scroll.exists ? {
            let f = scroll.frame
            return CGRect(x: f.minX, y: max(f.minY, top), width: f.width, height: f.maxY - max(f.minY, top))
        }() : nil
        do {
            try app.performAccessibilityAudit(for: types) { issue in
                if issue.auditType == .contrast {
                    guard let e = issue.element else { skipped.append(issue.compactDescription); return true }
                    if let v = visible, !v.contains(e.frame) { return true }
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' [\(issue.element?.identifier ?? "")] \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if !skipped.isEmpty { print("\(name): not judged, \(skipped.count) issue(s): \(skipped.joined(separator: "; "))") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func scrollTo(_ e: XCUIElement, max: Int = 30) {
        for _ in 0..<max where !(e.exists && e.isHittable) { app.swipeUp(); usleep(400_000) }
    }

    /// A Home tile by its name, scrolled into view first (at large text the tiles sit below the fold).
    private func tapHome(_ name: String) {
        let tile = app.buttons["tile-\(name)"]
        XCTAssertTrue(tile.waitForExistence(timeout: 8), name)
        scrollTo(tile)
        tile.tap()
    }

    /// With every plant found the Grand Garden and "What grows next" play once at launch; step through them.
    private func passGrandGarden() {
        guard element("grandGarden.title").waitForExistence(timeout: 6) else { return }
        let next = app.buttons["grandGarden.next"]
        scrollTo(next); next.tap()
        let done = app.buttons["whatsNext.done"]
        if done.waitForExistence(timeout: 5) { scrollTo(done); done.tap() }
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
    }

    private func openVisitors() {
        tapHome("Visitors")
        let hello = app.buttons["Say hello"]
        XCTAssertTrue(hello.waitForExistence(timeout: 5))
    }

    private func openSettings() {
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 8))
        app.buttons["Settings"].tap()
    }

    private func openPlus() {
        openSettings()
        let row = app.buttons["settings.plus"]
        scrollTo(row)
        row.tap()
        XCTAssertTrue(app.navigationBars["Plus"].waitForExistence(timeout: 5))
    }

    // MARK: Plus page (plus-page-review screenshots 1, 3)

    func testPlusPageAtDefaultAndAX5() {
        for size in [nil, Self.ax5] {
            for dark in [false, true] {
                launch(["-uitest-prices"], size: size, dark: dark)
                openPlus()
                XCTAssertTrue(app.buttons["plus.lifetime"].waitForExistence(timeout: 5))
                sleep(1); shot("plus", size, dark: dark, "-top")
                let width = app.windows.firstMatch.frame.width
                for e in app.staticTexts.allElementsBoundByIndex where e.exists && !e.frame.isEmpty {
                    XCTAssertLessThanOrEqual(e.frame.maxX, width + 0.5, "no sideways overflow: '\(e.label)'")
                }
                XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'a year'")).firstMatch.exists, "the price in words")
                if size == Self.ax5 { audit("plus-ax5-\(dark ? "dark" : "light")") }
                scrollTo(app.buttons["Privacy Policy"])
                sleep(1); shot("plus", size, dark: dark, "-bottom")
                app.terminate()
            }
        }
    }

    func testPlusPageMonthlyAndPlusForeverSelected() {
        launch(["-uitest-prices"])
        openPlus()
        let monthly = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Monthly'")).firstMatch
        XCTAssertTrue(monthly.waitForExistence(timeout: 5))
        monthly.tap()
        XCTAssertTrue(monthly.isSelected)
        scrollTo(element("plus.finePrint"), max: 4)
        XCTAssertTrue(element("plus.finePrint").label.contains("per month"))
        sleep(1); shot("plus", nil, dark: false, "-monthly")
        app.buttons["plus.lifetime"].tap()
        XCTAssertTrue(app.buttons["Buy Plus Forever"].waitForExistence(timeout: 2))
        sleep(1); shot("plus", nil, dark: false, "-forever")
    }

    // MARK: Loading, failed and owned states (screenshots 4 and 5)

    func testPlusLoadingAndFailedStates() {
        launch(["-uitest-store-slow"], size: Self.ax5)
        openPlus()
        XCTAssertTrue(element("plus.loading").waitForExistence(timeout: 5), "a spinner while the prices load")
        XCTAssertFalse(app.buttons["Subscribe"].exists, "no button that does nothing")
        XCTAssertFalse(element("plus.finePrint").exists, "no fine print without a price")
        sleep(1); shot("plus", Self.ax5, dark: false, "-loading")
        audit("plus-loading-ax5")
        app.terminate()
        // The store answers with an error: the failed state with Try again.
        launch(["-uitest-store-fail"], size: Self.ax5)
        openPlus()
        XCTAssertTrue(app.buttons["plus.tryAgain"].waitForExistence(timeout: 20), "the failed state")
        sleep(1); shot("plus", Self.ax5, dark: false, "-failed")
        audit("plus-failed-ax5")
    }

    func testPlusOwnedStates() {
        for (name, arg) in [("subscriber", "-uitest-plus"), ("forever", "-uitest-plus-forever"), ("twice", "-uitest-plus-twice")] {
            launch([arg])
            openPlus()
            XCTAssertFalse(app.buttons["Subscribe"].exists, name)
            sleep(1); shot("plus", nil, dark: false, "-owned-\(name)")
            app.terminate()
        }
    }

    /// Settings once Plus is on ("WordFlora Plus is on · Yearly") and the iCloud row in each state
    /// (docs/pm/plus-flow-fable-review.md N3, N4); the Plus page's plan line.
    func testSettingsPlusRowAndICloudStates() {
        for (name, extra) in [("free", [String]()), ("starts", ["-uitest-plus"]), ("on", ["-uitest-plus", "-uitest-cloud=on"]),
                              ("signin", ["-uitest-plus", "-uitest-cloud=signin"]), ("unavailable", ["-uitest-plus", "-uitest-cloud=unavailable"])] {
            launch(extra)
            openSettings()
            let row = app.buttons["settings.plus"], cloud = element("settings.cloudSync")
            scrollTo(cloud)
            XCTAssertTrue(cloud.exists, name)
            if name == "free" {
                XCTAssertTrue(cloud.label.contains("needs Plus"), cloud.label)
            } else {
                XCTAssertTrue(row.label.contains("WordFlora Plus is on"), row.label)
                XCTAssertTrue(row.label.contains("Yearly"), row.label)
            }
            switch name {
            case "starts": XCTAssertTrue(cloud.label.contains("starts next time"), cloud.label)
            case "on": XCTAssertTrue(cloud.label.contains("iCloud sync is on"), cloud.label)
            case "signin": XCTAssertTrue(cloud.label.contains("sign-in"), cloud.label)
            case "unavailable": XCTAssertTrue(cloud.label.contains("isn't available"), cloud.label)
            default: break
            }
            XCTAssertTrue(app.buttons["settings.restore"].exists, "the one Restore purchases is here")
            sleep(1); shot("settings-plus", nil, dark: false, "-\(name)")
            if name == "starts" {
                row.tap()
                XCTAssertTrue(element("plus.planLine").waitForExistence(timeout: 5))
                XCTAssertEqual(element("plus.planLine").label, "Yearly plan")
                sleep(1); shot("plus", nil, dark: false, "-subscribed-planline")
            }
            app.terminate()
        }
    }

    // MARK: The grown-up question (screenshot 2)

    func testTheGrownUpSheetKeepsContinueAndCancelReachable() {
        for size in [nil, Self.ax5] {
            for dark in [false, true] {
                launch(["-uitest-prices", "-uitest-age=under13"], size: size, dark: dark)
                openPlus()
                let buy = app.buttons.matching(NSPredicate(format: "label == 'Subscribe' OR label BEGINSWITH 'Start 3'")).firstMatch
                scrollTo(buy)
                buy.tap()
                let answer = app.textFields["parentalGate.answer"]
                XCTAssertTrue(answer.waitForExistence(timeout: 5))
                if size == Self.ax5 { audit("gate-ax5-\(dark ? "dark" : "light")") }
                answer.tap()                                     // the number pad comes up
                answer.typeText("1")
                sleep(1); shot("gate", size, dark: dark, "-keyboard")
                let cont = app.buttons["Continue"], cancel = app.buttons["Cancel"]
                for _ in 0..<8 where !(cancel.isHittable) { app.scrollViews.firstMatch.swipeUp(); usleep(400_000) }
                XCTAssertTrue(cont.exists && cancel.isHittable, "Continue and Cancel stay reachable")
                cont.tap()
                XCTAssertTrue(element("parentalGate.wrong").waitForExistence(timeout: 2))
                sleep(1); shot("gate", size, dark: dark, "-wrong")
                app.terminate()
            }
        }
    }

    // MARK: Grids

    func testGardenAndBadges() {
        for size in [Self.xxxl, Self.ax5] {
            for dark in size == Self.ax5 ? [false, true] : [false] {
                launch(["-uitest-allfound", "-uitest-everything"], size: size, dark: dark)
                passGrandGarden()                                // every plant found: the Grand Garden plays first
                tapHome("Garden")
                let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Passionflower'")).firstMatch
                XCTAssertTrue(app.navigationBars["My Garden"].waitForExistence(timeout: 5))
                sleep(1); shot("garden", size, dark: dark)
                if size == Self.ax5 { audit("garden-ax5-\(dark ? "dark" : "light")") }
                scrollTo(tile, max: 60)
                sleep(1); shot("garden", size, dark: dark, "-passionflower")
                app.navigationBars.buttons.firstMatch.tap()
                let badges = app.buttons["tile-Badges"]
                scrollTo(badges)
                badges.tap()
                XCTAssertTrue(element("badge.plant_collector").waitForExistence(timeout: 5))
                sleep(1); shot("badges", size, dark: dark)
                if size == Self.ax5 { audit("badges-ax5-\(dark ? "dark" : "light")") }
                app.terminate()
            }
        }
    }

    func testShedPotsToolsAndRepotSheet() {
        for size in [Self.xxxl, Self.ax5] {
            launch(["-uitest-gardened", "-uitest-everything", "-uitest-prices"], size: size)
            tapHome("Shed")
            XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5))
            sleep(1); shot("shed-tools", size, dark: false)
            app.buttons["shed.tool.can"].tap()
            sleep(1); shot("shed-tool-sheet", size, dark: false)
            app.swipeDown(velocity: .fast); sleep(1)
            let indigo = app.buttons["shed-pot-snowflakeIndigo"].firstMatch
            scrollTo(app.buttons["shed-pot-plainBlue"].firstMatch)
            app.swipeUp(); sleep(1); shot("shed-pots", size, dark: false)
            scrollTo(indigo, max: 40)
            sleep(1); shot("shed-pots", size, dark: false, "-pack")
            app.terminate()
            launch(["-uitest-plant=daisy", "-uitest-pots", "-uitest-prices"], size: size)
            tapHome("Garden")
            let daisy = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Daisy'")).firstMatch
            scrollTo(daisy)
            daisy.tap()
            let repot = app.buttons["tend-repot"]
            XCTAssertTrue(repot.waitForExistence(timeout: 8))
            scrollTo(repot)
            repot.tap()
            XCTAssertTrue(app.buttons["repot-go"].waitForExistence(timeout: 5))
            let close = app.buttons["pot-new-close"]
            if close.waitForExistence(timeout: 1) { close.tap(); sleep(1) }
            sleep(1); shot("repot", size, dark: false, "-tiles")
            let compost = app.buttons["repot-soil-compost"]
            for _ in 0..<40 where !(compost.isHittable && compost.frame.maxY < app.buttons["repot-go"].frame.minY - 40) {
                app.scrollViews.firstMatch.swipeUp(velocity: .slow); usleep(400_000)
            }
            sleep(1); shot("repot", size, dark: false, "-soil")
            app.terminate()
        }
    }

    // MARK: Visitors

    func testVisitorsPageBookFieldNotesAndDetail() {
        for size in [Self.xxxl, Self.ax5] {
            for dark in size == Self.ax5 ? [false, true] : [false] {
                launch(["-uitest-album-all", "-uitest-everything"], size: size, dark: dark)
                openVisitors()
                sleep(1); shot("visitors", size, dark: dark)
                if size == Self.ax5 { audit("visitors-ax5-\(dark ? "dark" : "light")") }
                let humming = app.buttons["visitor-hummingbird"]
                scrollTo(humming, max: 40)
                sleep(1); shot("visitors", size, dark: dark, "-album")
                humming.tap()
                XCTAssertTrue(app.staticTexts["Hummingbird"].waitForExistence(timeout: 3))
                sleep(1); shot("visitor-detail-hummingbird", size, dark: dark)
                if size == Self.ax5 { audit("visitor-detail-ax5-\(dark ? "dark" : "light")") }
                app.buttons["Done"].firstMatch.tap(); sleep(1)
                for _ in 0..<40 where !app.buttons["visitors.book"].isHittable { app.swipeDown(); usleep(300_000) }
                app.buttons["visitors.book"].tap()
                let page = element("book.page.hummingbird")
                XCTAssertTrue(element("book.page.monarch").waitForExistence(timeout: 5))
                sleep(1); shot("visitors-book", size, dark: dark)
                if size == Self.ax5 { audit("visitors-book-ax5-\(dark ? "dark" : "light")") }
                scrollTo(page, max: 60)
                sleep(1); shot("field-notes-hummingbird", size, dark: dark)
                let sticker = element("book.sticker.weather.5")
                scrollTo(sticker, max: 80)
                sleep(1); shot("visitors-book", size, dark: dark, "-stickers")
                app.terminate()
            }
        }
    }

    /// The game's title on the evening sky in light mode (run in the evening; the bar is navy with a white title).
    func testButterflyGameTitle() {
        for size in [nil, Self.ax5] {
            launch(["-uitest-album", "-uitest-everything"], size: size)
            openVisitors()
            scrollTo(app.buttons["Say hello"])
            app.buttons["Say hello"].tap()
            XCTAssertTrue(app.navigationBars["Butterfly game"].waitForExistence(timeout: 5))
            sleep(2); shot("butterfly-game", size, dark: false)
            app.terminate()
        }
    }

    // MARK: Grand garden, Guide, Quiet Garden, rest and break cards

    func testGrandGardenCrownLabel() {
        for dark in [false, true] {
            launch(["-uitest-crown", "-uitest-reduce-motion"], size: Self.ax5, dark: dark)
            XCTAssertTrue(element("grandGarden.title").waitForExistence(timeout: 8))
            sleep(1); shot("grand-garden", Self.ax5, dark: dark)
            audit("grand-garden-ax5-\(dark ? "dark" : "light")")
            app.terminate()
        }
    }

    func testGuidePagesFadeInsteadOfClipping() {
        for size in [Self.xxxl, Self.ax5] {
            app.launchArguments = ["-uitest", "-uitest-word=SEED", "-UIPreferredContentSizeCategoryName", size]
            app.launch()
            let adult = app.buttons["18 or older"]
            XCTAssertTrue(adult.waitForExistence(timeout: 12))
            adult.tap()
            XCTAssertTrue(app.buttons["onboardingGuide.next"].waitForExistence(timeout: 5))
            sleep(1); shot("guide", size, dark: false, "-p1")
            app.buttons["onboardingGuide.next"].tap(); app.buttons["onboardingGuide.next"].tap()
            sleep(1); shot("guide", size, dark: false, "-p3")
            if size == Self.ax5 { audit("guide-ax5") }
            app.terminate()
        }
    }

    func testQuietGardenPlantPage() {
        for size in [Self.xxxl, Self.ax5] {
            launch(["-uitest-plant=daisy", "-uitest-quiet", "-uitest-everything"], size: size)
            tapHome("Garden")
            let daisy = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Daisy'")).firstMatch
            scrollTo(daisy)
            daisy.tap()
            XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 8))
            app.buttons["tend-water"].tap(); sleep(4)       // "More tomorrow" on Water
            let prune = app.buttons["tend-prune"]
            scrollTo(prune)
            sleep(1); shot("quiet-plant", size, dark: false)
            if size == Self.ax5 { audit("quiet-plant-ax5") }
            app.terminate()
        }
    }

    func testBreakCardAtAX5() {
        launch(["-uitest-word=LOTUS", "-uitest-break-card"], size: Self.ax5)
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
        app.buttons["Play"].tap()
        XCTAssertTrue(app.staticTexts["Time for a little break"].waitForExistence(timeout: 5))
        sleep(2); shot("break-card", Self.ax5, dark: false)
        app.swipeUp(); sleep(1); shot("break-card", Self.ax5, dark: false, "-scrolled")
    }
}

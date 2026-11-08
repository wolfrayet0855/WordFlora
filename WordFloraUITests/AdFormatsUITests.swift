import XCTest

/// Rewarded perks with the Debug fake presenter (`-uitest-ads-fake`: a plain "TEST AD" screen, closes on tap; the SDK
/// never starts). R1 on the Garden, R3 on the wake sheet; R2 on the resting card is in RestCardUITests once the card
/// row lands. Free rows for under 13 and Plus; nothing in Quiet Garden.
final class AdFormatsUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() { continueAfterFailure = false }

    private func launch(_ extra: [String]) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-sessions=3", "-uitest-ads-fake", "-uitest-daytime"] + extra
        app.launch()
    }

    private func openGarden() {
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 8))
    }

    private var waterRow: XCUIElement { app.buttons["garden.waterPerk"] }

    func testAnAdultWithADryCanWatchesAVideoForTwoDrops() {
        launch(["-uitest-dry"])
        openGarden()
        XCTAssertTrue(app.staticTexts["Your watering can is dry."].waitForExistence(timeout: 5))
        XCTAssertTrue(waterRow.exists)
        XCTAssertTrue(waterRow.label.contains("Watch a short video for 2 drops"), waterRow.label)
        waterRow.tap()
        let ad = app.descendants(matching: .any)["fakeAd"]
        XCTAssertTrue(ad.waitForExistence(timeout: 5), "the TEST AD screen")
        ad.tap()
        XCTAssertTrue(app.staticTexts["2 drops are in your can"].waitForExistence(timeout: 5))
        XCTAssertFalse(waterRow.waitForExistence(timeout: 2), "the can is no longer dry")
    }

    func testUnderThirteenGetsTheRainBarrelWithNoVideo() {
        launch(["-uitest-dry", "-uitest-age=under13"])
        openGarden()
        XCTAssertTrue(waterRow.waitForExistence(timeout: 5))
        XCTAssertTrue(waterRow.label.contains("Fill from the rain barrel"), waterRow.label)
        XCTAssertFalse(waterRow.label.contains("video"))
        XCTAssertFalse(waterRow.label.contains("Plus"), "free rows never mention Plus to a child")
        waterRow.tap()
        XCTAssertFalse(app.descendants(matching: .any)["fakeAd"].waitForExistence(timeout: 2), "no ad for under 13")
        XCTAssertTrue(app.staticTexts["2 drops are in your can"].waitForExistence(timeout: 5))
    }

    func testPlusGetsTheFreeRowIncludedWithPlus() {
        launch(["-uitest-dry", "-uitest-plus"])
        openGarden()
        XCTAssertTrue(waterRow.waitForExistence(timeout: 5))
        XCTAssertTrue(waterRow.label.contains("Fill from the rain barrel"), waterRow.label)
        XCTAssertTrue(waterRow.label.contains("Included with Plus"), waterRow.label)
    }

    func testQuietGardenHasNoWaterRow() {
        launch(["-uitest-dry", "-uitest-quiet"])
        openGarden()
        XCTAssertFalse(app.descendants(matching: .any)["garden.waterCard"].waitForExistence(timeout: 3))
        XCTAssertFalse(waterRow.exists)
    }

    private func openWakeSheet() {
        app.buttons["Garden"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Clover'")).firstMatch.tap()
        let wake = app.buttons["Wake Clover"]
        XCTAssertTrue(wake.waitForExistence(timeout: 8))
        for _ in 0..<6 where !wake.isHittable { app.swipeUp() }
        wake.tap()
        XCTAssertTrue(app.buttons["wake-butterflies"].waitForExistence(timeout: 5))
    }

    func testTheGentleWakeRowAppearsOnlyAfterOneStillDreamingTry() {
        launch(["-uitest-seed"])
        openWakeSheet()
        XCTAssertFalse(app.buttons["wake.gentle"].exists, "no third row before a first try")
        app.terminate()
        launch(["-uitest-seed", "-uitest-wake-dreamed"])
        openWakeSheet()
        let row = app.buttons["wake.gentle"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Wake with a short video"), row.label)
        XCTAssertTrue(row.label.contains("The two challenges stay free"), row.label)
        row.tap()
        let ad = app.descendants(matching: .any)["fakeAd"]
        XCTAssertTrue(ad.waitForExistence(timeout: 5))
        ad.tap()
        XCTAssertTrue(app.staticTexts["Clover is awake"].waitForExistence(timeout: 5))
    }

    // MARK: Audits (light and dark, default and the largest accessibility size)

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    private static let axXXXL = UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
    private static let large = UIContentSizeCategory.large.rawValue

    /// Every audit type, the same way as TextFitScreensUITests: contrast and clipped text are judged only for elements
    /// fully inside the visible scroll area (the audit does not scroll); Dynamic Type and clipped text run apart.
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
                if issue.auditType == .textClipped, let e = issue.element, let v = visible, !v.insetBy(dx: -1, dy: -1).contains(e.frame) {
                    skipped.append("\(issue.compactDescription) on '\(e.label)' (partly out of view)"); return true
                }
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' [\(issue.element?.identifier ?? "")] \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        if !skipped.isEmpty { print("\(name): not judged, \(skipped.count) issue(s): \(skipped.joined(separator: "; "))") }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func launchForAudit(_ extra: [String], size: String, dark: Bool) {
        XCUIDevice.shared.appearance = dark ? .dark : .light
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-sessions=3", "-uitest-ads-fake", "-uitest-toast-hold",
                               "-UIPreferredContentSizeCategoryName", size] + extra
        app.launch()
    }

    /// Garden with the R1 video row, then its toast after the fake ad.
    private func auditGarden(size: String, dark: Bool) {
        launchForAudit(["-uitest-dry"], size: size, dark: dark)
        openGarden()
        XCTAssertTrue(waterRow.waitForExistence(timeout: 5))
        for _ in 0..<4 where !waterRow.isHittable { app.swipeDown() }
        let tag = "garden-\(dark ? "dark" : "light")-\(size == Self.large ? "default" : "axxxl")"
        audit(tag)
        waterRow.tap()
        let ad = app.descendants(matching: .any)["fakeAd"]
        XCTAssertTrue(ad.waitForExistence(timeout: 5)); ad.tap()
        XCTAssertTrue(app.descendants(matching: .any)["rewardToast"].firstMatch.waitForExistence(timeout: 5))
        audit(tag + "-toast")
    }

    /// The wake sheet with the R3 row, then its toast.
    private func auditWake(size: String, dark: Bool) {
        launchForAudit(["-uitest-seed", "-uitest-wake-dreamed"], size: size, dark: dark)
        openWakeSheet()
        let row = app.buttons["wake.gentle"]
        for _ in 0..<6 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let tag = "wake-\(dark ? "dark" : "light")-\(size == Self.large ? "default" : "axxxl")"
        audit(tag)
        row.tap()
        let ad = app.descendants(matching: .any)["fakeAd"]
        XCTAssertTrue(ad.waitForExistence(timeout: 5)); ad.tap()
        XCTAssertTrue(app.descendants(matching: .any)["rewardToast"].firstMatch.waitForExistence(timeout: 5))
        audit(tag + "-toast")
    }

    func testAuditGardenLightDefault() { auditGarden(size: Self.large, dark: false) }
    func testAuditGardenDarkDefault() { auditGarden(size: Self.large, dark: true) }
    func testAuditGardenLightAXXXL() { auditGarden(size: Self.axXXXL, dark: false) }
    func testAuditGardenDarkAXXXL() { auditGarden(size: Self.axXXXL, dark: true) }
    func testAuditWakeLightDefault() { auditWake(size: Self.large, dark: false) }
    func testAuditWakeDarkDefault() { auditWake(size: Self.large, dark: true) }
    func testAuditWakeLightAXXXL() { auditWake(size: Self.axXXXL, dark: false) }
    func testAuditWakeDarkAXXXL() { auditWake(size: Self.axXXXL, dark: true) }
}

/// Faded bloom placement check (docs/pm/faded-bloom-offsets.md): the cue forced on for lithops and aloe vera (nudged)
/// and clover (unchanged). Shots go to SCREENSHOT_DIR (and the result bundle) for a look by eye.
final class FadedBloomShotUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() { continueAfterFailure = false }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func check(_ id: String, _ name: String) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-everything", "-uitest-plant=\(id)", "-uitest-tidytrim"]
        app.launch()
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 8))
        for _ in 0..<12 where !tile.isHittable { app.swipeUp() }
        tile.tap()
        XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 8))
        let moment = app.descendants(matching: .any)["badgeMoment"].firstMatch
        if moment.waitForExistence(timeout: 4) { _ = moment.waitForNonExistence(timeout: 10) }
        XCTAssertTrue(app.descendants(matching: .any)["plant.tidyCue"].firstMatch.waitForExistence(timeout: 5), "the cue shows")
        shot("faded-bloom-\(id)")
        app.terminate()
    }

    func testFadedBloomOnLithopsAloeVeraAndClover() {
        check("lithops", "Lithops")
        check("aloe_vera", "Aloe Vera")
        check("clover", "Clover")
    }
}

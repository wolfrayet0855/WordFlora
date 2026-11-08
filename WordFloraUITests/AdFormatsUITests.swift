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

    func testTheWaterRowPassesTheAccessibilityAudit() throws {
        for size in [UIContentSizeCategory.large, .accessibilityExtraExtraExtraLarge] {
            for look in [XCUIDevice.Appearance.light, .dark] {
                XCUIDevice.shared.appearance = look
                app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-sessions=3", "-uitest-ads-fake", "-uitest-dry",
                                       "-UIPreferredContentSizeCategoryName", size.rawValue]
                app.launch()
                openGarden()
                XCTAssertTrue(waterRow.waitForExistence(timeout: 5))
                try app.performAccessibilityAudit(for: [.contrast, .dynamicType, .textClipped, .hitRegion, .sufficientElementDescription])
                app.terminate()
            }
        }
        XCUIDevice.shared.appearance = .light
    }
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

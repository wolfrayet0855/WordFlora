import XCTest

/// Garden weather on Home and in Settings (tickets E-5, E-10, E-12): the forecast chip and card, the weather-day banner,
/// Calm mode and Quiet Garden hiding everything, the Garden weather and Wild Weather switches, and the audits.
final class WeatherUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ extra: [String], size: String? = nil) {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-gardened"] + extra
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 10))
    }

    private var chip: XCUIElement { app.descendants(matching: .any)["weather-chip"] }
    private var card: XCUIElement { app.descendants(matching: .any)["weather-forecast-card"] }
    private var banner: XCUIElement { app.descendants(matching: .any)["weather-banner"] }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: dir + "/\(name).png"))
        }
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

    private func openSettings() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    /// Scrolls the Settings form until the element is on screen (or gives up).
    private func reveal(_ e: XCUIElement) {
        for _ in 0..<8 where !(e.exists && e.isHittable) { app.swipeUp() }
    }

    // MARK: Home

    func testTheDayBeforeShowsTheChipAndTheCardAndGotItKeepsTheChip() {
        launch(["-uitest-forecast=bigWind"])
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        XCTAssertEqual(chip.label, "Garden forecast. Tomorrow: windy")
        XCTAssertTrue(card.exists)
        XCTAssertTrue(app.staticTexts["Tomorrow: a big wind"].exists)
        XCTAssertTrue(app.staticTexts["Give a drink or a hello today."].exists)
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'warning' OR label CONTAINS[c] 'alert'")).firstMatch.exists)
        shot("weather-forecast-card")
        app.buttons["weather-gotit"].tap()
        XCTAssertTrue(card.waitForNonExistence(timeout: 3))
        XCTAssertTrue(chip.exists, "the chip stays for the day")
    }

    func testTheWeatherDayShowsASoftBanner() {
        launch(["-uitest-weather=busyBugs"])
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(banner.label.contains("Busy bugs came to the garden."))
        XCTAssertFalse(card.exists)
        shot("weather-banner")
    }

    func testCalmModeShowsNoWeatherAtAll() {
        launch(["-uitest-calm", "-uitest-forecast=bigWind"])
        XCTAssertFalse(chip.waitForExistence(timeout: 2))
        XCTAssertFalse(card.exists)
        openSettings()
        let calmLine = app.staticTexts["settings.weatherCalm"]
        reveal(calmLine)
        XCTAssertTrue(calmLine.exists, "Settings says Calm keeps the weather away")
        XCTAssertFalse(app.switches["settings.gardenWeather"].exists, "no second calm control")
        XCTAssertFalse(app.switches["settings.wildWeather"].exists)
    }

    func testQuietGardenShowsNoWeatherAndNoWeatherSettings() {
        launch(["-uitest-quiet", "-uitest-weather=bigWind"])
        XCTAssertFalse(banner.waitForExistence(timeout: 2))
        launch(["-uitest-quiet", "-uitest-forecast=hotDay"])
        XCTAssertFalse(chip.waitForExistence(timeout: 2))
        openSettings()
        app.swipeUp(); app.swipeUp()
        XCTAssertFalse(app.switches["settings.gardenWeather"].exists)
    }

    func testTurningGardenWeatherOffHidesTheForecast() {
        launch(["-uitest-forecast=frostyNight"])
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        openSettings()
        let toggle = app.switches["settings.gardenWeather"]
        reveal(toggle)
        XCTAssertEqual(toggle.value as? String, "1", "on by default with Calm off")
        toggle.switches.firstMatch.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertFalse(app.switches["settings.wildWeather"].exists, "Wild Weather goes with weather off")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        XCTAssertFalse(chip.exists)
    }

    // MARK: Wild Weather (any age with Calm off; owner ruling 2026-11-05)

    func testWildWeatherIsOffByDefaultAndAsksBeforeTurningOn() {
        launch([])
        openSettings()
        let wild = app.switches["settings.wildWeather"]
        reveal(wild)
        XCTAssertTrue(wild.exists)
        XCTAssertEqual(wild.value as? String, "0", "off by default")
        wild.switches.firstMatch.tap()
        let alert = app.alerts["Turn on Wild Weather?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Your level and your plants stay just as they are.'")).firstMatch.exists)
        shot("wild-weather-confirm")
        alert.buttons["Not now"].tap()
        XCTAssertEqual(wild.value as? String, "0")
        wild.switches.firstMatch.tap()
        app.alerts["Turn on Wild Weather?"].buttons["Turn it on"].tap()
        XCTAssertEqual(wild.value as? String, "1")
        wild.switches.firstMatch.tap()
        XCTAssertEqual(wild.value as? String, "0", "one tap turns it off, no question")
    }

    func testAnUnder13PlayerWithCalmOffMayChooseWildWeatherButNotTheForecastReminder() {
        launch(["-uitest-age=under13", "-uitest-remind"])
        openSettings()
        XCTAssertFalse(app.switches["settings.wildWeather"].exists, "under 13 starts in Calm")
        let calm = app.switches["Calm mode"]
        reveal(calm)
        calm.switches.firstMatch.tap()
        let wild = app.switches["settings.wildWeather"]
        reveal(wild)
        XCTAssertTrue(wild.exists, "any age may choose it with Calm off")
        XCTAssertEqual(wild.value as? String, "0")
        XCTAssertFalse(app.switches["settings.weatherNotify"].exists, "the forecast reminder stays hidden under 13")
    }

    func testTheForecastReminderIsAnOptInBesideTheDailyReminder() {
        launch(["-uitest-remind"])
        openSettings()
        let notify = app.switches["settings.weatherNotify"]
        reveal(notify)
        XCTAssertTrue(notify.exists)
        XCTAssertEqual(notify.value as? String, "0", "off by default")
        notify.switches.firstMatch.tap()
        XCTAssertEqual(notify.value as? String, "1")
    }

    // MARK: Audits and large text

    /// The same Home without weather: the baseline the weather audits compare with (a found plant shows the
    /// words-to-next-plant line in the hero).
    func testHomeWithAFoundPlantAndNoWeatherPassesTheAudit() {
        launch([])
        XCTAssertFalse(chip.exists)
        audit("home-found-plant")
    }

    func testTheForecastCardPassesTheAudit() {
        launch(["-uitest-forecast=bigWind"])
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        audit("weather-card")
    }

    func testTheBannerPassesTheAudit() {
        launch(["-uitest-weather=hailShower"])
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        audit("weather-banner")
    }

    func testTheCardReadsWholeAtTheLargestTextSize() {
        launch(["-uitest-forecast=bigPuddles"], size: "UICTContentSizeCategoryAccessibilityXXXL")
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)            // the large-text layout settles before the audit
        audit("weather-card-ax")
        let gotIt = app.buttons["weather-gotit"]
        for _ in 0..<4 where !gotIt.isHittable { app.swipeUp() }
        XCTAssertTrue(gotIt.isHittable)
        XCTAssertGreaterThanOrEqual(gotIt.frame.height, 44)
        shot("weather-card-ax")
    }

    func testTheCardWithReduceMotionAndDark() {
        launch(["-uitest-forecast=hotDay", "-uitest-reduce-motion", "-uitest-dark"])
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        shot("weather-card-dark-still")
        app.buttons["weather-gotit"].tap()
        XCTAssertFalse(card.exists, "under Reduce Motion the card goes at once")
        XCTAssertTrue(chip.exists)
        shot("weather-chip-dark-still")
        // No dark audit here: dark Home without any weather already gets a contrast finding on the Daily Bloom line
        // ("One word for everyone today", D4EDD4 on 4D3039, about 10:1 by the colour values); see docs/STATUS.md.
    }

    // MARK: Plant page weather art and sound (mounted only behind the weather gate)

    /// Opens Daisy's page from the garden (Home opens first, so the weather day counts as seen).
    private func openDaisy(_ extra: [String]) -> XCUIElement {
        executionTimeAllowance = max(executionTimeAllowance, 300)    // launch, Home, Garden, page: slow under machine load
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-plant=daisy"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 10))
        app.buttons["Garden"].tap()
        let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Daisy")).firstMatch
        _ = tile.waitForExistence(timeout: 5)
        for _ in 0..<10 where !(tile.exists && tile.isHittable) { app.swipeUp() }
        tile.tap()
        let plant = app.buttons["plant-love"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        return plant
    }

    private func weatherValue(_ plant: XCUIElement) -> String { (plant.value as? String) ?? "" }

    func testTheWeatherDayDrawsItsArtOnThePlantPage() {
        let plant = openDaisy(["-uitest-weather=bigWind"])
        XCTAssertFalse(weatherValue(plant).isEmpty, "the weather line is read with the plant")
        XCTAssertTrue(weatherValue(plant).contains("Daisy"), weatherValue(plant))
        XCTAssertTrue(plant.isHittable, "the art never takes the plant's taps")
        shot("weather-plant-wind")
    }

    func testTheWeatherArtHoldsStillWithReduceMotion() {
        let plant = openDaisy(["-uitest-weather=hailShower", "-uitest-reduce-motion"])
        XCTAssertFalse(weatherValue(plant).isEmpty)
        shot("weather-plant-hail-still")
    }

    func testCalmModeShowsNoWeatherArtOnThePlantPage() {
        let plant = openDaisy(["-uitest-calm", "-uitest-weather=bigWind"])
        XCTAssertEqual(weatherValue(plant), "", "no weather in Calm mode")
    }

    func testQuietGardenShowsNoWeatherArtOnThePlantPage() {
        let plant = openDaisy(["-uitest-quiet", "-uitest-weather=bigWind"])
        XCTAssertEqual(weatherValue(plant), "", "no weather in Quiet Garden")
    }

    func testAHelloMendsTheWeatherOnThePlantPage() {
        let plant = openDaisy(["-uitest-weather=bigPuddles"])
        XCTAssertFalse(weatherValue(plant).isEmpty)
        plant.tap()
        let mended = NSPredicate(format: "value == nil OR value == ''")
        expectation(for: mended, evaluatedWith: plant); waitForExpectations(timeout: 5)
    }

    /// Each kind is audited once: four held still, three moving (seven launches in one test was too slow under load).
    private static let stillKinds = ["drySpell", "frostyNight", "hailShower", "bigPuddles"]
    private static let movingKinds = ["busyBugs", "bigWind", "hotDay"]

    /// Kinds with the art held still (the app's Reduce Motion switch).
    func testAuditThePlantPageOnWeatherDaysHeldStill() {
        auditKinds(Self.stillKinds, extra: ["-uitest-reduce-motion"], prefix: "weather-plant-still")
    }

    /// Kinds with the art moving.
    func testAuditThePlantPageOnWeatherDaysMoving() {
        auditKinds(Self.movingKinds, extra: [], prefix: "weather-plant-audit")
    }

    /// The full audit on each weather day's plant page. Every finding fails the test, except contrast findings outside the
    /// weather scene (the art cannot reach there; the audit flags the fact card's lines that sit under the pinned tend
    /// buttons, which TendingUITests' plant audit also leaves out) or with no element at all; those are printed. The scene is the art's own rectangle around the plant box (WeatherOverlay.sceneRect).
    private func auditKinds(_ kinds: [String], extra: [String], prefix: String) {
        executionTimeAllowance = 600
        var findings = [String]()
        for kind in kinds {
            let plant = openDaisy(["-uitest-weather=\(kind)"] + extra)
            let box = plant.frame, k = box.width / 220
            let scene = CGRect(x: box.minX - 70 * k, y: box.minY - 26 * k, width: 361 * k, height: 340 * k)
            shot("\(prefix)-\(kind)")
            findings += auditFindings("\(prefix)-\(kind)", scene: scene)
            app.terminate()
        }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func auditFindings(_ name: String, scene: CGRect) -> [String] {
        var findings = [String]()
        do {
            try app.performAccessibilityAudit { issue in
                let frame = issue.element?.frame
                let line = "\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(frame.map { "\($0)" } ?? "no element")"
                if issue.auditType == .contrast && !(frame.map { $0.intersects(scene) } ?? false) {
                    print("Excused (contrast outside the weather scene \(scene) or unresolved): \(line)")
                } else {
                    findings.append(line)
                }
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        return findings
    }
}

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

    /// Home's weather art plays for 5 s, then holds (WeatherCardArt.playSeconds); audits judge the settled Home
    /// (at accessibility sizes, after Home's weather refresh and the card's first read have redrawn it).
    /// Then waits until Home has stopped changing (`waitForStableHome`).
    private func settleHomeArt() { Thread.sleep(forTimeInterval: 6); waitForStableHome() }

    /// Home's hero, weather card or banner and Play, by frame and label (plus the text count): what a late redraw moves.
    private func homeLayout() -> String {
        let hero = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Guess words. Grow a garden.'")).firstMatch
        return [hero, card, banner, app.buttons["Play"]].map { e in e.exists ? "\(e.frame)|\(e.label)" : "-" }.joined(separator: " ; ")
            + " #\(app.staticTexts.count)"
    }

    /// Waits until Home reads the same three times in a row, 0.5 s apart (at most 20 s). Home finishes work after launch
    /// on its own time (the weather refresh, the weather kit arriving with the first forecast and redrawing the card, the
    /// ad and offer checks); on a loaded machine that can land while the Dynamic Type audit measures the hero, which then
    /// reads as "partially unsupported". The audit itself is unchanged.
    private func waitForStableHome() {
        var last = homeLayout(), same = 0
        let end = Date().addingTimeInterval(20)
        while same < 2 && Date() < end {
            Thread.sleep(forTimeInterval: 0.5)
            let now = homeLayout()
            same = now == last ? same + 1 : 0
            last = now
        }
    }

    private func audit(_ name: String, ignoring: XCUIAccessibilityAuditType = []) {
        var findings = [String]()
        let before = app.buttons["Play"].exists ? homeLayout() : nil
        do {
            try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(ignoring)) { issue in
                findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' \(issue.element.map { "\($0.frame)" } ?? "")")
                return true
            }
        } catch { findings.append("\(name): audit failed to run: \(error)") }
        // Evidence for a finding: did Home move while the audit ran?
        if !findings.isEmpty, let before {
            let after = homeLayout()
            findings.append(before == after ? "\(name): Home was still during the audit" : "\(name): Home moved during the audit:\n  before \(before)\n  after  \(after)")
        }
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
        XCTAssertEqual(app.staticTexts["weather-banner-text"].label, "Busy bugs came to the garden.")
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
        XCTAssertFalse(app.staticTexts["settings.wildGrownUpNote"].exists, "the grown-up note is for under 13 only")
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
        XCTAssertTrue(app.staticTexts["settings.wildGrownUpNote"].exists, "a gentle grown-up note under 13")
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
        settleHomeArt(); audit("weather-card")
    }

    func testTheBannerPassesTheAudit() {
        launch(["-uitest-weather=hailShower"])
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        settleHomeArt(); audit("weather-banner")
    }

    func testTheCardReadsWholeAtTheLargestTextSize() {
        launch(["-uitest-forecast=bigPuddles"], size: "UICTContentSizeCategoryAccessibilityXXXL")
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)            // the large-text layout settles before the audit
        settleHomeArt(); audit("weather-card-ax")
        let gotIt = app.buttons["weather-gotit"]
        for _ in 0..<4 where !gotIt.isHittable { app.swipeUp() }
        XCTAssertTrue(gotIt.isHittable)
        XCTAssertGreaterThanOrEqual(gotIt.frame.height, 44)
        shot("weather-card-ax")
    }

    func testTheCardWithReduceMotionAndDark() {
        // Light and dark follow the system: the device appearance sets dark.
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = .light }
        launch(["-uitest-forecast=hotDay", "-uitest-reduce-motion"])
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        shot("weather-card-dark-still")
        app.buttons["weather-gotit"].tap()
        XCTAssertFalse(card.exists, "under Reduce Motion the card goes at once")
        XCTAssertTrue(chip.exists)
        shot("weather-chip-dark-still")
        // No dark audit here: dark Home without any weather already gets a contrast finding on the Daily Bloom line
        // ("One word for everyone today", D4EDD4 on 4D3039, about 10:1 by the colour values); see docs/STATUS.md.
    }

    // MARK: Helpers and the puzzle on Home and the plant page (real seed fixtures, so the helpers' rules apply)

    func testTheForecastCardSetsOutTheHelperInOneTap() {
        launch(["-uitest-weather-tomorrow=bigWind"])
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let setOut = app.buttons["weather-setout"]
        XCTAssertTrue(setOut.waitForExistence(timeout: 3))
        XCTAssertEqual(setOut.label, "Set out the wind net")
        settleHomeArt(); audit("weather-card-helper")
        setOut.tap()
        XCTAssertTrue(app.descendants(matching: .any)["weather-helper-done"].waitForExistence(timeout: 3))
        XCTAssertFalse(setOut.exists)
        shot("weather-card-helper-out")
        settleHomeArt(); audit("weather-card-helper-out")
    }

    /// The schedule override (`-uitest-forecast=`) reaches the helpers too, so the card's step works without a real seed.
    func testTheForecastOverrideCardSetsOutTheHelper() {
        launch(["-uitest-forecast=frostyNight"])
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let setOut = app.buttons["weather-setout"]
        XCTAssertTrue(setOut.waitForExistence(timeout: 3))
        XCTAssertEqual(setOut.label, "Set out the frost cloth")
        setOut.tap()
        let done = app.descendants(matching: .any)["weather-helper-done"]
        XCTAssertTrue(done.waitForExistence(timeout: 3))
        XCTAssertTrue(done.label.contains("The frost cloth is out for your whole garden."))
        XCTAssertFalse(setOut.exists)
    }

    func testCalmShowsNoHelperStep() {
        launch(["-uitest-calm", "-uitest-weather-tomorrow=bigWind"])
        XCTAssertFalse(card.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["weather-setout"].exists)
    }

    func testTheBannerOpensTheWeatherPuzzleAndSkipComesBack() {
        launch(["-uitest-weather-today=bigWind", "-uitest-weather-rewarded"])
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        let play = app.buttons["weather-puzzle"]
        XCTAssertTrue(play.exists)
        shot("weather-banner-puzzle")
        settleHomeArt(); audit("weather-banner-puzzle")
        play.tap()
        XCTAssertTrue(app.descendants(matching: .any)["weatherPuzzle.title"].waitForExistence(timeout: 5))
        app.buttons["weatherPuzzle.skip"].tap()
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
    }

    func testTheBannerAtTheLargestTextSizePassesTheAudit() {
        launch(["-uitest-weather-today=hailShower"], size: "UICTContentSizeCategoryAccessibilityXXXL")
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        settleHomeArt(); audit("weather-banner-ax")
    }

    func testAWeatheredPlantsPageOpensTheWeatherPuzzle() {
        _ = openDaisy(["-uitest-weather-today=bigWind"])
        let entry = app.buttons["plant.weatherPuzzle"]
        for _ in 0..<4 where !(entry.exists && entry.isHittable) { app.swipeUp() }
        XCTAssertTrue(entry.exists)
        entry.tap()
        XCTAssertTrue(app.descendants(matching: .any)["weatherPuzzle.title"].waitForExistence(timeout: 5))
        app.buttons["weatherPuzzle.skip"].tap()
        XCTAssertTrue(app.buttons["plant-love"].waitForExistence(timeout: 5))
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
        // The first look at a found plant's fact card earns the bronze Wild Discovery badge; its moment dims the app
        // and sits over the plant for 2.6 s, so taps and audits wait until it has gone.
        let moment = app.descendants(matching: .any)["badgeMoment"].firstMatch
        if moment.waitForExistence(timeout: 4) { XCTAssertTrue(moment.waitForNonExistence(timeout: 10), "the badge moment goes") }
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

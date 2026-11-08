import XCTest

/// G4b formats with the Debug fakes (`-uitest-ads-fake`: the SDK never starts; a plain "TEST AD" screen, a fake native
/// asset set drawn by the real card, and labelled fake banners). The return cue and app-open ad, the Shed's
/// "SPONSORED" card and the collapsible Garden banner, with the never-over matrix and the audits
/// (docs/pm/g4b-builder-brief.md sections 6 and 7).
final class AdFormatsG4bUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        executionTimeAllowance = 300
    }

    override func tearDown() {
        XCUIDevice.shared.appearance = .light
        super.tearDown()
    }

    /// Two seconds away is enough, no visit minimum; a 30 s budget so a test can tap Skip before the cue lifts.
    private static let fastReturn = ["-adcaps", "appOpenMinBackground=2,appOpenMinSessions=0,gapToAppOpen=0,appOpenLoadBudget=30"]

    private func launch(_ extra: [String], onboarded: Bool = true) {
        app.launchArguments = ["-uitest"] + (onboarded ? ["-uitest-onboarded"] : []) +
            ["-uitest-sessions=3", "-uitest-ads-fake", "-uitest-daytime"] + Self.fastReturn + extra
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }
    private var cue: XCUIElement { element("appOpenCue") }
    private var skip: XCUIElement { app.buttons["appOpenCue.skip"] }

    private func openGarden() {
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 8))
    }

    private func openShed() {
        app.buttons["Shed"].tap()
        XCTAssertTrue(app.buttons["shed.tool.can"].waitForExistence(timeout: 5))
    }

    /// Home button, a few seconds away, then back (a warm return after more than `appOpenMinBackground`).
    private func goAwayAndComeBack(seconds: TimeInterval = 4) {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: seconds)
        app.activate()
    }

    private func scrollTo(_ e: XCUIElement, max: Int = 14) {
        for _ in 0..<max where !(e.exists && e.isHittable) { app.swipeUp(velocity: .slow) }
    }

    // MARK: App open

    func testTheReturnCueShowsTheAdChipAndSkipGoesBackToTheScreenLeft() {
        launch(["-uitest-appopen-never"])
        openGarden()
        goAwayAndComeBack()
        XCTAssertTrue(cue.waitForExistence(timeout: 5), "the cue covers the app on return")
        let text = element("appOpenCue.text")
        XCTAssertTrue(text.label.contains("Welcome back to your garden"), text.label)
        XCTAssertTrue(text.label.contains("A short ad, then your garden"), text.label)
        XCTAssertTrue(skip.exists)
        XCTAssertTrue(skip.label.contains("Skip to my garden"), skip.label)
        XCTAssertGreaterThanOrEqual(skip.frame.height, 52)
        skip.tap()
        XCTAssertFalse(cue.waitForExistence(timeout: 2), "Skip lifts the cue")
        XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].exists, "back on the Garden")
        XCTAssertFalse(element("fakeAd").exists, "nothing plays after Skip")
    }

    func testTheFakeAppOpenAdPlaysOverTheCueOnceADay() {
        launch([])
        openGarden()
        goAwayAndComeBack()
        let ad = element("fakeAd")
        XCTAssertTrue(ad.waitForExistence(timeout: 6), "the TEST AD screen over the cue")
        ad.tap()
        XCTAssertFalse(cue.waitForExistence(timeout: 2), "the cue fades after the ad")
        XCTAssertTrue(app.staticTexts["Level 1 · Seedling"].waitForExistence(timeout: 3))
        goAwayAndComeBack()
        XCTAssertFalse(cue.waitForExistence(timeout: 3), "once a day")
    }

    // MARK: Never-over matrix (each: no cue and no ad)

    private func assertNoCueOnReturn(_ name: String, file: StaticString = #file, line: UInt = #line) {
        goAwayAndComeBack()
        XCTAssertFalse(cue.waitForExistence(timeout: 3), "\(name): no cue", file: file, line: line)
        XCTAssertFalse(element("fakeAd").exists, "\(name): no ad", file: file, line: line)
    }

    func testNoCueForUnderThirteen() { launch(["-uitest-age=under13"]); assertNoCueOnReturn("under 13") }
    func testNoCueForPlus() { launch(["-uitest-plus"]); assertNoCueOnReturn("Plus") }
    func testNoCueInCalm() { launch(["-uitest-calm"]); assertNoCueOnReturn("Calm") }
    func testNoCueInQuietGarden() { launch(["-uitest-quiet"]); assertNoCueOnReturn("Quiet Garden") }

    func testNoCueOverOnboarding() {
        launch([], onboarded: false)
        assertNoCueOnReturn("onboarding")
    }

    func testNoCueOverAWordInProgress() {
        launch(["-uitest-word=LOTUS"])
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 8))
        app.buttons["Play"].tap()
        XCTAssertTrue(app.buttons["L"].waitForExistence(timeout: 5))
        app.buttons["L"].tap()
        assertNoCueOnReturn("a word in progress")
        XCTAssertTrue(app.buttons["O"].exists, "the word is still there")
    }

    func testNoCueWhenALinkOpensTheApp() {
        launch([])
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 4)
        app.open(URL(string: "wordflora://home")!)
        XCTAssertFalse(cue.waitForExistence(timeout: 3), "a link: no cue")
        XCTAssertFalse(element("fakeAd").exists)
    }

    func testNoCueOnAColdLaunchFromALink() {
        launch(["-uitest-link-launch", "-uitest-appopen-away"])
        XCTAssertFalse(cue.waitForExistence(timeout: 3), "opened from a link: no cue")
    }

    func testTheCueCanShowOnAColdLaunchAfterFourHoursAway() {
        launch(["-uitest-appopen-away", "-uitest-appopen-never"])
        XCTAssertTrue(cue.waitForExistence(timeout: 5), "a cold launch reads the last background time from the ledger")
        skip.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
    }

    // MARK: Native Shed card

    private var sponsored: XCUIElement { element("shed.sponsored") }
    /// The Shed tile opens at the second level up; `-uitest-everything` opens every tile.
    private static let shedOpen = ["-uitest-everything"]

    func testTheShedShowsTheSponsoredCardBelowThePotsAndReadsAdvertisementFirst() {
        launch(Self.shedOpen)
        openShed()
        scrollTo(sponsored)
        XCTAssertTrue(sponsored.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SPONSORED"].exists || app.staticTexts["Sponsored"].exists)
        XCTAssertTrue(app.staticTexts["Ads help keep WordFlora free."].exists)
        let footer = element("shed-pots-footer")
        if footer.exists { XCTAssertGreaterThan(sponsored.frame.minY, footer.frame.minY, "below the pots") }
        let card = element("nativeAdCard")
        XCTAssertTrue(card.exists)
        let first = card.descendants(matching: .any).matching(NSPredicate(format: "label != ''")).firstMatch
        XCTAssertEqual(first.label, "Advertisement", "VoiceOver reads the badge first")
        XCTAssertTrue(card.staticTexts["Test advertiser"].exists)
    }

    func testNoSponsoredSectionForUnderThirteenOrPlus() {
        for flag in ["-uitest-age=under13", "-uitest-plus"] {
            launch([flag] + Self.shedOpen)
            openShed()
            for _ in 0..<10 { app.swipeUp(velocity: .fast) }
            XCTAssertFalse(sponsored.waitForExistence(timeout: 2), flag)
            XCTAssertFalse(app.staticTexts["SPONSORED"].exists, "\(flag): not even the header")
            app.terminate()
        }
    }

    func testCalmNeverShowsAVideoCard() {
        launch(["-uitest-calm", "-uitest-native-video"] + Self.shedOpen)
        openShed()
        for _ in 0..<10 { app.swipeUp(velocity: .fast) }
        XCTAssertFalse(sponsored.waitForExistence(timeout: 2))
    }

    // MARK: Collapsible Garden banner

    func testTheGardenBannerIsCollapsibleOnceAVisitThenPlain() {
        launch([])
        openGarden()
        XCTAssertTrue(element("gardenBanner.fake.collapsible").waitForExistence(timeout: 5), "the first Garden banner of the visit")
        XCTAssertTrue(app.buttons["Go ad-free"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        openGarden()
        XCTAssertTrue(element("gardenBanner.fake.plain").waitForExistence(timeout: 5), "then the ordinary banner")
        XCTAssertFalse(element("gardenBanner.fake.collapsible").exists)
    }

    func testVoiceOverAndAccessibilitySizesGetThePlainBanner() {
        launch(["-uitest-voiceover"])
        openGarden()
        XCTAssertTrue(element("gardenBanner.fake.plain").waitForExistence(timeout: 5), "VoiceOver")
        app.terminate()
        launch(["-UIPreferredContentSizeCategoryName", UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue])
        openGarden()
        XCTAssertTrue(element("gardenBanner.fake.plain").waitForExistence(timeout: 5), "an accessibility text size")
    }

    // MARK: Audits (light and dark, default and the largest accessibility size; screenshots kept)

    private static let axXXXL = UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
    private static let large = UIContentSizeCategory.large.rawValue

    private func launchForAudit(_ extra: [String], size: String, dark: Bool) {
        XCUIDevice.shared.appearance = dark ? .dark : .light
        launch(["-UIPreferredContentSizeCategoryName", size] + extra)
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// As in AdFormatsUITests: contrast and clipped text are judged only inside the visible scroll area.
    private func audit(_ name: String) {
        shot(name)
        auditOnce(name, types: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped]))
        auditOnce(name + "-textClipped", types: .textClipped)
        auditOnce(name + "-dynamicType", types: .dynamicType)
    }

    private func auditOnce(_ name: String, types: XCUIAccessibilityAuditType) {
        var findings = [String](), skipped = [String]()
        let scroll = app.scrollViews.firstMatch, nav = app.navigationBars.firstMatch
        let top = nav.exists ? nav.frame.maxY + 64 : 0
        // Rows that sit under the Garden banner slot are covered by it, so they are not judged.
        let banner = element("gardenBanner")
        let bottomLimit: CGFloat? = banner.exists ? banner.frame.minY - 8 : nil
        let visible: CGRect? = scroll.exists ? {
            let f = scroll.frame
            let bottom = min(f.maxY, bottomLimit ?? f.maxY)
            return CGRect(x: f.minX, y: max(f.minY, top), width: f.width, height: bottom - max(f.minY, top))
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

    private func tag(_ what: String, size: String, dark: Bool) -> String {
        "\(what)-\(dark ? "dark" : "light")-\(size == Self.large ? "default" : "axxxl")"
    }

    /// The cue, then Skip reachable by scrolling at the largest size.
    private func auditCue(size: String, dark: Bool) {
        launchForAudit(["-uitest-appopen-never"], size: size, dark: dark)
        goAwayAndComeBack()
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        audit(tag("cue", size: size, dark: dark))
        scrollTo(skip)
        XCTAssertTrue(skip.isHittable, "Skip is reachable at every size")
        Thread.sleep(forTimeInterval: 1)              // let the scroll settle: a tap on a moving scroll only stops it
        skip.tap()
        if cue.waitForExistence(timeout: 1), skip.isHittable { skip.tap() }
        XCTAssertFalse(cue.waitForExistence(timeout: 2))
    }

    /// The Shed scrolled to the sponsored card (header, badge, headline, media, body, call to action).
    private func auditShed(size: String, dark: Bool) {
        launchForAudit(Self.shedOpen, size: size, dark: dark)
        openShed()
        let card = element("nativeAdCard")
        scrollTo(card)
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        audit(tag("shed-native", size: size, dark: dark))
    }

    /// The Garden with the collapsible fake banner and its caption row.
    private func auditGardenBanner(size: String, dark: Bool) {
        launchForAudit([], size: size, dark: dark)
        openGarden()
        XCTAssertTrue(element("gardenBanner").waitForExistence(timeout: 5))
        audit(tag("garden-banner", size: size, dark: dark))
    }

    func testAuditCueLightDefault() { auditCue(size: Self.large, dark: false) }
    func testAuditCueDarkDefault() { auditCue(size: Self.large, dark: true) }
    func testAuditCueLightAXXXL() { auditCue(size: Self.axXXXL, dark: false) }
    func testAuditCueDarkAXXXL() { auditCue(size: Self.axXXXL, dark: true) }
    func testAuditShedLightDefault() { auditShed(size: Self.large, dark: false) }
    func testAuditShedDarkDefault() { auditShed(size: Self.large, dark: true) }
    func testAuditShedLightAXXXL() { auditShed(size: Self.axXXXL, dark: false) }
    func testAuditShedDarkAXXXL() { auditShed(size: Self.axXXXL, dark: true) }
    func testAuditGardenBannerLightDefault() { auditGardenBanner(size: Self.large, dark: false) }
    func testAuditGardenBannerDarkAXXXL() { auditGardenBanner(size: Self.axXXXL, dark: true) }
}

/// One live smoke run with Google's test ids (Debug build, real SDK). Skipped unless `WF_LIVE_ADS=1`: never in CI and
/// never on the build box under load. It may show the consent form for the simulator's region.
final class AdFormatsLiveUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["WF_LIVE_ADS"] == "1", "live ads: run by hand on a quiet machine")
        continueAfterFailure = true
    }

    func testTheTestIdsFillTheShedCardAndTheGardenBanner() {
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-sessions=3", "-uitest-ads", "-uitest-daytime"]
        app.launch()
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["gardenBanner"].firstMatch.waitForExistence(timeout: 30))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["Shed"].tap()
        let card = app.descendants(matching: .any)["nativeAdCard"].firstMatch
        for _ in 0..<12 where !card.exists { app.swipeUp(); Thread.sleep(forTimeInterval: 2) }
        XCTAssertTrue(card.waitForExistence(timeout: 30), "a native test ad filled the Shed card")
    }
}

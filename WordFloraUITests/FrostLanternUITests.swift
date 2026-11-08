import XCTest

/// The full Frost & Lantern pack (release plan G5) with `-uitest-pack-owned`: the snowy scene behind Home and Garden
/// (audited light and dark at AX XXXL), the glasshouse plants' shelf and plant page at stages 0 and 4, and the
/// album's winter friends. Without the pack, none of it shows.
final class FrostLanternUITests: XCTestCase {
    let app = XCUIApplication()
    static let axxxl = "UICTContentSizeCategoryAccessibilityXXXL"

    override func setUpWithError() throws { continueAfterFailure = false }
    override func tearDown() { XCUIDevice.shared.appearance = .light; super.tearDown() }

    private func launch(_ extra: [String] = [], owned: Bool = true, size: String? = nil, dark: Bool = false) {
        XCUIDevice.shared.appearance = dark ? .dark : .light
        app.launchArguments = ["-uitest", "-uitest-onboarded", "-uitest-age=eighteenPlus", "-uitest-plant=clover"]
            + (owned ? ["-uitest-pack-owned"] : []) + extra
            + (size.map { ["-UIPreferredContentSizeCategoryName", $0] } ?? [])
        app.launch()
    }

    private func element(_ id: String) -> XCUIElement { app.descendants(matching: .any)[id].firstMatch }

    private func scrollTo(_ e: XCUIElement, max: Int = 16) {
        for _ in 0..<max where !(e.exists && e.isHittable) { app.swipeUp(velocity: .slow) }
    }

    private func shot(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.png"); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    /// Every audit type; contrast judged on elements fully inside the visible scroll area, as in the other audits.
    private func audit(_ name: String) {
        sleep(2)
        let scroll = app.scrollViews.firstMatch
        let nav = app.navigationBars.firstMatch
        let top = nav.exists ? nav.frame.maxY + 64 : 0
        let visible: CGRect? = scroll.exists ? {
            let f = scroll.frame
            return CGRect(x: f.minX, y: max(f.minY, top), width: f.width, height: f.maxY - max(f.minY, top))
        }() : nil
        var findings = [String]()
        let passes: [XCUIAccessibilityAuditType] = [XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped]),
                                                    .textClipped, .dynamicType]
        for types in passes {
            do {
                try app.performAccessibilityAudit(for: types) { issue in
                    if issue.auditType == .contrast, let v = visible {
                        guard let e = issue.element, v.contains(e.frame) else { return true }
                    }
                    findings.append("\(name): \(issue.auditType.rawValue) - \(issue.compactDescription) | '\(issue.element?.label ?? "")' [\(issue.element?.identifier ?? "")]")
                    return true
                }
            } catch { findings.append("\(name): audit failed to run: \(error)") }
        }
        XCTAssertTrue(findings.isEmpty, findings.joined(separator: "\n"))
    }

    private func openGarden() {
        app.buttons["Garden"].tap()
        XCTAssertTrue(app.navigationBars["My Garden"].waitForExistence(timeout: 5))
    }

    // MARK: Scene

    func testOwnersSeeTheSceneOnHomeAndGarden() {
        launch()
        XCTAssertTrue(app.buttons["Garden"].waitForExistence(timeout: 5))     // the scene is hidden from VoiceOver: checked by shot
        shot("g5-home-light")
        openGarden()
        shot("g5-garden-light")
    }

    func testSceneAuditsLightAndDarkAtAXXXL() {
        for dark in [false, true] {
            launch(size: Self.axxxl, dark: dark)
            XCTAssertTrue(app.buttons["Garden"].waitForExistence(timeout: 5))
            audit("g5-home-\(dark ? "dark" : "light")-axxxl")
            shot("g5-home-\(dark ? "dark" : "light")-axxxl")
            openGarden()
            audit("g5-garden-\(dark ? "dark" : "light")-axxxl")
            app.terminate()
        }
    }

    func testWithoutThePackNothingShows() {
        launch(owned: false)
        openGarden()
        XCTAssertFalse(element("garden.glasshouse").exists)
    }

    // MARK: Glasshouse plants

    private func openGlasshouse(_ id: String) {
        // Back from a plant page lands on My Garden, not Home: open it from Home only when it is not already showing.
        if !app.navigationBars["My Garden"].exists { openGarden() }
        let tile = element("glasshouse.\(id)")
        scrollTo(tile)
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()
        XCTAssertTrue(app.buttons["tend-water"].waitForExistence(timeout: 5))
    }

    func testGlasshousePlantPagesAtStageZeroAndFour() {
        for grown in [false, true] {
            for dark in [false, true] {
                launch(grown ? ["-uitest-glasshouse-grown"] : [], dark: dark)
                for id in ["glasshouse_snowdrop", "glasshouse_hellebore"] {
                    openGlasshouse(id)
                    shot("g5-\(id)-stage\(grown ? 4 : 0)-\(dark ? "dark" : "light")")
                    app.navigationBars.buttons.firstMatch.tap()
                }
                app.terminate()
            }
        }
    }

    func testGlasshousePlantPageAudit() {
        launch(size: Self.axxxl, dark: true)
        openGlasshouse("glasshouse_hellebore")
        audit("g5-hellebore-page-axxxl-dark")
    }

    // MARK: Album

    func testAlbumShowsTheWinterFriends() {
        for dark in [false, true] {
            launch(["-uitest-winter-friends"], size: Self.axxxl, dark: dark)
            app.buttons["Visitors"].tap()
            // At AX XXXL the twelve cards take one column, so the winter friends sit far below the fold.
            let robin = element("visitor-robin")
            scrollTo(robin, max: 45)
            XCTAssertTrue(robin.waitForExistence(timeout: 5))
            XCTAssertTrue(element("visitor-unmet-wren").exists)
            shot("g5-album-\(dark ? "dark" : "light")")
            audit("g5-album-axxxl-\(dark ? "dark" : "light")")
            app.terminate()
        }
    }
}

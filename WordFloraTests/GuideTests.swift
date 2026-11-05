import XCTest
import SwiftData
import JavaScriptCore
@testable import WordFlora

/// The first-run onboarding guide (design-preview/onboarding-guide/README.md): where it sits in the first session,
/// the pager rules, its copy (one source, mirrored from copy.js and checked by CopySafety), its motion and quiet
/// variants, and the synced "guide seen" flag.
final class GuideFlowTests: XCTestCase {
    func testTheGuideComesAfterTheAgeQuestionAndBeforeTheTutorialWord() {
        var f = OnboardingFlow()
        f.introFinished()
        f.selectAge(.under13)
        XCTAssertEqual(f.step, .guide)
        XCTAssertFalse(f.isComplete)
        f.guideFinished()
        XCTAssertEqual(f.step, .tutorialWord)
    }

    func testGuideFinishedIsIgnoredAnywhereElse() {
        var f = OnboardingFlow()
        f.guideFinished(); XCTAssertEqual(f.step, .intro)
        f.introFinished(); f.guideFinished(); XCTAssertEqual(f.step, .age)
        f.selectAge(.eighteenPlus); f.guideFinished(); f.guideFinished()
        XCTAssertEqual(f.step, .tutorialWord, "a second finish never jumps past the tutorial word")
    }

    func testAGuideAlreadySeenOnAnotherDeviceGoesStraightToTheFirstWord() {
        var f = OnboardingFlow()
        f.introFinished()
        f.selectAge(.thirteenPlus, guideSeen: true)
        XCTAssertEqual(f.step, .tutorialWord)
    }

    func testNoPaywallOrPromptsWhileTheGuideShows() {
        var f = OnboardingFlow(); f.introFinished(); f.selectAge(.eighteenPlus)
        XCTAssertEqual(f.step, .guide)
        XCTAssertFalse(f.mayShowPaywall)
        XCTAssertFalse(f.mayRequestPermissions)
    }
}

final class GuidePagerTests: XCTestCase {
    func testStartsOnTheFirstPageWithSkipAndNoBack() {
        let p = GuidePager(mode: .firstRun)
        XCTAssertEqual(p.count, 8)
        XCTAssertEqual(p.page, 0)
        XCTAssertFalse(p.showsBack)
        XCTAssertTrue(p.showsSkip)
        XCTAssertEqual(p.skipLabel, "Skip")
        XCTAssertEqual(p.skipHint, "Goes straight to your first word")
        XCTAssertEqual(p.nextLabel, "Next")
        XCTAssertTrue(p.nextShowsChevron)
        XCTAssertEqual(p.dotsValue, "Page 1 of 8")
    }

    func testNextWalksEveryPageThenFinishes() {
        var p = GuidePager(mode: .firstRun)
        for i in 1..<8 {
            XCTAssertFalse(p.next(), "page \(i) is not the end")
            XCTAssertEqual(p.page, i)
        }
        XCTAssertTrue(p.isLast)
        XCTAssertFalse(p.showsSkip, "Skip hides on the last page, where Start playing does the same")
        XCTAssertEqual(p.nextLabel, "Start playing")
        XCTAssertFalse(p.nextShowsChevron)
        XCTAssertTrue(p.showsBack)
        XCTAssertEqual(p.dotsValue, "Page 8 of 8")
        XCTAssertTrue(p.next(), "Next on the last page finishes the guide")
        XCTAssertEqual(p.page, 7, "finishing does not move past the last page")
    }

    func testBackAndGoStayInRange() {
        var p = GuidePager(mode: .firstRun)
        p.back(); XCTAssertEqual(p.page, 0)
        p.go(to: 5); XCTAssertEqual(p.page, 5)
        p.back(); XCTAssertEqual(p.page, 4)
        p.go(to: 99); XCTAssertEqual(p.page, 7)
        p.go(to: -3); XCTAssertEqual(p.page, 0)
    }

    func testReplayFromSettingsReadsCloseAndDone() {
        var p = GuidePager(mode: .replay)
        XCTAssertEqual(p.skipLabel, "Close")
        XCTAssertEqual(p.skipHint, "Back to Settings")
        p.go(to: 7)
        XCTAssertEqual(p.nextLabel, "Done")
    }
}

final class GuideCopyTests: XCTestCase {
    /// CopySafety's list plus the words the guide brief bans (no locks, losing, Plus, ads or prices inside the guide).
    static let extraBanned = ["locked", "lock", "unlock", "unlocks", "lose", "loses", "plus", "ad", "ads", "price", "buy", "subscription"]

    func testEightPagesInTheSpecOrder() {
        XCTAssertEqual(GuideCopy.pages.map(\.id), ["guess", "plants", "tend", "love", "garden", "daily", "levels", "peeks"])
    }

    func testEveryStringIsGentleAndHasNoShopWords() {
        XCTAssertGreaterThan(GuideCopy.allStrings.count, 60)
        for s in GuideCopy.allStrings {
            XCTAssertEqual(CopySafety.check(s), [], s)
            for w in Self.extraBanned {
                XCTAssertNil(s.range(of: "\\b\(w)\\b", options: [.regularExpression, .caseInsensitive]), "\(w) in: \(s)")
            }
            XCTAssertFalse(s.contains("$"), s)
        }
    }

    func testShortTitlesAndAtMostTwoLines() {
        for p in GuideCopy.pages {
            XCTAssertLessThanOrEqual(p.title.split(separator: " ").count, 5, p.title)
            XCTAssertLessThanOrEqual(p.lines.count, 2, p.id)
            XCTAssertLessThanOrEqual(p.linesQuiet?.count ?? 0, 2, p.id)
            XCTAssertFalse(p.art.isEmpty, p.id)
        }
    }

    func testGradeTwoToThreeReading() {
        let text = GuideCopy.pages.flatMap { [$0.title] + $0.lines }.joined(separator: " ")
        let words = text.split(separator: " ")
        let sentences = text.split(whereSeparator: { ".!?".contains($0) }).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        XCTAssertLessThanOrEqual(Double(words.count) / Double(sentences), 12)
        let long = Set(words.map { $0.filter(\.isLetter) }.filter { $0.count >= 9 }.map { $0.lowercased() })
        XCTAssertTrue(long.isSubset(of: ["challenge", "butterflies"]), "long words: \(long)")
    }

    func testOnlyTheLovePageHasAQuietVariant() {
        let love = GuideCopy.page("love")
        XCTAssertEqual(love.lines(quiet: true)[1], "Your plant keeps all it grows, always.")
        XCTAssertTrue(love.lines(quiet: false)[1].contains("naps as a seed"))
        for p in GuideCopy.pages where p.id != "love" {
            XCTAssertNil(p.linesQuiet, p.id)
            XCTAssertEqual(p.lines(quiet: true), p.lines(quiet: false))
        }
    }

    func testNumbersAndNamesComeFromTheGame() {
        let economy = Economy()
        XCTAssertEqual(GuideCopy.page("plants").lines[1], "After that, every \(economy.wordsPerPlant) words brings a new plant.")
        XCTAssertTrue(GuideCopy.page("levels").lines[0].hasPrefix("Find \(economy.plantsPerLevel) plants"))
        XCTAssertTrue(GuideCopy.page("levels").lines[1].contains("all \(economy.plantsPerLevel)"))
        XCTAssertEqual(GuideCopy.Art.levelNames, LevelMapCopy.names, "level 3 reads Bloom, as in the app")
        XCTAssertEqual(GuideCopy.Art.stageNames, LifeStats.stageNames)
        XCTAssertTrue(GuideCopy.page("levels").art.contains(LevelMapCopy.names.joined(separator: ", ").replacingOccurrences(of: ", Ancient", with: " and Ancient")))
        XCTAssertFalse(GuideCopy.allStrings.contains { $0.contains("Wildwood") })
    }

    func testSettingsRowAndFootnote() {
        XCTAssertEqual(GuideCopy.UI.settingsRow, "Show the guide again")
        XCTAssertEqual(GuideCopy.UI.settingsFoot, "A quick tour of how to play and grow your garden.")
        XCTAssertEqual(GuideCopy.UI.dots(3, 8), "Page 3 of 8")
    }

    /// copy.js is the single copy source for the mockup; the Swift copy must say the same thing, word for word.
    /// The one deliberate difference: the app's level 3 is "Bloom" (the mockup drew "Wildwood").
    func testMirrorsTheMockupCopyFile() throws {
        // The test bundle carries a copy of design-preview/onboarding-guide/copy.js (Copy Bundle Resources).
        let bundled = Bundle(for: GuideCopyTests.self).url(forResource: "copy", withExtension: "js")
        let url = try XCTUnwrap(bundled, "copy.js is bundled with the tests")
        let source = try String(contentsOf: url, encoding: .utf8)
        let js = JSContext()!
        js.evaluateScript(source)
        let copy = try XCTUnwrap(js.evaluateScript("JSON.stringify(GUIDE_COPY)")?.toString())
        struct JSPage: Decodable { var id: String; var title: String; var lines: [String]; var linesQuiet: [String]?; var art: String }
        struct JSCopy: Decodable { var ui: [String: String]; var pages: [JSPage]; var artText: [String] }
        let c = try JSONDecoder().decode(JSCopy.self, from: Data(copy.utf8))
        let fix = { (s: String) in s.replacingOccurrences(of: "Wildwood", with: "Bloom") }

        let ui = GuideCopy.UI.self
        XCTAssertEqual(c.ui["skip"], ui.skip); XCTAssertEqual(c.ui["close"], ui.close); XCTAssertEqual(c.ui["back"], ui.back)
        XCTAssertEqual(c.ui["next"], ui.next); XCTAssertEqual(c.ui["start"], ui.start); XCTAssertEqual(c.ui["done"], ui.done)
        XCTAssertEqual(c.ui["dots"]?.replacingOccurrences(of: "{n}", with: "2").replacingOccurrences(of: "{total}", with: "8"), ui.dots(2, 8))
        XCTAssertEqual(c.ui["settingsRow"], ui.settingsRow); XCTAssertEqual(c.ui["settingsFoot"], ui.settingsFoot)
        XCTAssertEqual(c.ui["skipHint"], ui.skipHint); XCTAssertEqual(c.ui["closeHint"], ui.closeHint); XCTAssertEqual(c.ui["dotsLabel"], ui.dotsLabel)

        XCTAssertEqual(c.pages.count, GuideCopy.pages.count)
        for (j, s) in zip(c.pages, GuideCopy.pages) {
            XCTAssertEqual(j.id, s.id); XCTAssertEqual(j.title, s.title); XCTAssertEqual(j.lines, s.lines, j.id)
            XCTAssertEqual(j.linesQuiet, s.linesQuiet, j.id); XCTAssertEqual(fix(j.art), s.art, j.id)
        }
        let swiftArt = Set(GuideCopy.Art.all)
        for word in c.artText.map(fix) {
            XCTAssertTrue(swiftArt.contains { $0 == word || $0.contains(word) }, "art text \(word) is drawn somewhere")
        }
    }
}

final class GuideLookTests: XCTestCase {
    func testMotionStopsForReduceMotionFromEitherPlaceAndForCalm() {
        XCTAssertFalse(GuideLook.still(systemReduceMotion: false, reduceMotionOverride: false, calm: false))
        XCTAssertTrue(GuideLook.still(systemReduceMotion: true, reduceMotionOverride: false, calm: false))
        XCTAssertTrue(GuideLook.still(systemReduceMotion: false, reduceMotionOverride: true, calm: false))
        XCTAssertTrue(GuideLook.still(systemReduceMotion: false, reduceMotionOverride: false, calm: true))
    }

    func testQuietCopyForQuietGardenOrCalm() {
        XCTAssertFalse(GuideLook.quietCopy(calm: false, quiet: false))
        XCTAssertTrue(GuideLook.quietCopy(calm: true, quiet: false))
        XCTAssertTrue(GuideLook.quietCopy(calm: false, quiet: true))
    }

    func testPointsChipHidesInQuietGardenOnly() {
        XCTAssertTrue(GuideLook.showsPoints(quiet: false))
        XCTAssertFalse(GuideLook.showsPoints(quiet: true))
    }
}

@MainActor
final class GuideSeenStoreTests: XCTestCase {
    var container: ModelContainer!
    var ctx: ModelContext { container.mainContext }
    let defs = (try? BadgeCatalog.load()) ?? []

    override func setUp() async throws {
        container = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: ctx)
        ctx.insert(PlayerProfile()); try ctx.save()
    }

    func profile(_ c: ModelContext? = nil) -> PlayerProfile { try! (c ?? ctx).fetch(FetchDescriptor<PlayerProfile>()).first! }

    func testANewProfileHasNotSeenTheGuide() {
        XCTAssertFalse(PlayerProfile().guideSeen)
    }

    func testSeenWinsWhenTwoProfilesMerge() {
        for (a, b) in [(true, false), (false, true), (true, true), (false, false)] {
            let k = PlayerProfile(), o = PlayerProfile()
            k.guideSeen = a; o.guideSeen = b
            DataReconciler.merge(o, into: k, defs: defs)
            XCTAssertEqual(k.guideSeen, a || b, "\(a) + \(b)")
        }
    }

    func testBackupCarriesItAndOldBackupsReadAsUnseen() throws {
        profile().guideSeen = true; try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"guideSeen\" : true"))

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertTrue(profile(fresh.mainContext).guideSeen)

        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var prof = json["profile"] as! [String: Any]; prof.removeValue(forKey: "guideSeen"); json["profile"] = prof
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success(let decoded) = GardenBackup.decode(old) else { return XCTFail("old backup should read") }
        XCTAssertNil(decoded.profile.guideSeen)

        // An old backup (or one saved before the guide was seen) never clears it.
        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail("old backup should restore") }
        XCTAssertTrue(profile().guideSeen)
        let unseen = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: unseen.mainContext)
        guard case .success = GardenBackup.restore(old, into: unseen.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertFalse(profile(unseen.mainContext).guideSeen, "an old backup reads as unseen")
    }

    func testFinishingTheGuideRecordsItAndMovesOnWithoutTouchingProgress() throws {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "guide-\(UUID().uuidString)")!)
        let app = AppModel(container: container, settings: settings, notifications: ReminderTests.FakeCenter())
        let before = (profile().gamesPlayed, profile().water, profile().soil, app.plants().filter { $0.earnedCount > 0 }.count)
        app.onboarding.introFinished(); app.onboarding.selectAge(.eighteenPlus)
        XCTAssertEqual(app.onboarding.step, .guide)
        app.finishGuide()
        XCTAssertEqual(app.onboarding.step, .tutorialWord)
        XCTAssertTrue(profile().guideSeen)
        XCTAssertEqual(before.0, profile().gamesPlayed); XCTAssertEqual(before.1, profile().water); XCTAssertEqual(before.2, profile().soil)
        XCTAssertEqual(before.3, app.plants().filter { $0.earnedCount > 0 }.count)
        XCTAssertFalse(app.settings.onboardingComplete, "the first session goes on to the tutorial word")
    }

    func testReplayingFromSettingsLeavesTheFlowAlone() throws {
        let settings = AppSettings(defaults: UserDefaults(suiteName: "guide-\(UUID().uuidString)")!)
        settings.onboardingComplete = true
        let app = AppModel(container: container, settings: settings, notifications: ReminderTests.FakeCenter())
        XCTAssertTrue(app.onboarding.isComplete)
        app.finishGuide()
        XCTAssertTrue(app.onboarding.isComplete)
        XCTAssertTrue(profile().guideSeen)
    }
}

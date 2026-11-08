import XCTest
import SwiftData
@testable import WordFlora

/// Make it yours (docs/pm/engagement-quick-wins.md, task B): the name rule, rename and the widget pin.
@MainActor
final class PlantNameTests: XCTestCase {
    func makeApp() throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let suite = UserDefaults(suiteName: "wf-tests-\(UUID().uuidString)")!
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: AppSettings(defaults: suite), bank: bank, notifications: ReminderTests.FakeCenter())
    }

    // MARK: The name rule

    func testTrimsSpacesAndNewLines() {
        XCTAssertEqual(PlantName.clean("  Sunny \n"), "Sunny")
        XCTAssertEqual(PlantName.clean("\tMr Leaf  "), "Mr Leaf")
    }

    func testKeepsAtMostSixteenCharacters() {
        XCTAssertEqual(PlantName.clean("Abcdefghijklmnopqrstuvwxyz"), "Abcdefghijklmnop")
        XCTAssertEqual(PlantName.clean("Abcdefghijklmnop").count, 16)
    }

    func testSixteenCharactersNeverSplitAnEmojiOrAnAccent() {
        let family = "👨‍👩‍👧"
        let name = "Rosie" + String(repeating: family, count: 15)        // 20 characters
        let cleaned = PlantName.clean(name)
        XCTAssertEqual(cleaned.count, 16)
        XCTAssertEqual(cleaned, "Rosie" + String(repeating: family, count: 11))
        XCTAssertEqual(PlantName.clean("Éléonore Hélène Zoë"), "Éléonore Hélène")
        // A combining accent stays with its letter.
        let combining = String(repeating: "e\u{0301}", count: 20)
        XCTAssertEqual(PlantName.clean(combining), String(repeating: "e\u{0301}", count: 16))
    }

    func testCutAtSixteenTrimsTheTrailingSpace() {
        XCTAssertEqual(PlantName.clean("Fifteen letters ok"), "Fifteen letters")
    }

    func testNoLetterOrDigitGoesBackToTheSpeciesName() {
        for typed in ["", "   ", "\n\n", "🌸", "🌸🌼🌻", "!!!", "... --", "👨‍👩‍👧 ✨"] {
            XCTAssertEqual(PlantName.clean(typed), "", "'\(typed)'")
        }
        XCTAssertEqual(PlantName.clean("🌸 Pip"), "🌸 Pip", "an emoji beside letters is kept")
        XCTAssertEqual(PlantName.clean("R2"), "R2")
        XCTAssertEqual(PlantName.clean("7"), "7")
    }

    func testMarksOnlyNamesClear() {
        XCTAssertEqual(PlantName.clean("\u{0301}\u{0302}\u{0303}"), "", "combining marks with no base")
        XCTAssertEqual(PlantName.clean(" \u{20DD}\u{20DD} "), "", "enclosing marks only")
        XCTAssertEqual(PlantName.clean("\u{0345}\u{0345}"), "", "a mark that Unicode calls alphabetic is still not a base")
    }

    func testStackedMarksAreCutBackToTwoPerCharacter() {
        let zalgo = "Z" + String(repeating: "\u{0336}", count: 30) + "ed"
        let cleaned = PlantName.clean(zalgo)
        XCTAssertEqual(cleaned, "Z\u{0336}\u{0336}ed")
        XCTAssertEqual(cleaned.unicodeScalars.count, 5)
        XCTAssertEqual(PlantName.clean("Việt"), "Việt", "a real two-mark accent stays")
        XCTAssertEqual(PlantName.clean("❤️ Pip"), "❤️ Pip", "an emoji's variation selector stays")
    }

    func testBidiControlsAreRemoved() {
        XCTAssertEqual(PlantName.clean("\u{202E}Sunny\u{202C}"), "Sunny")
        XCTAssertEqual(PlantName.clean("Su\u{2066}nny\u{2069}\u{200F}"), "Sunny")
        XCTAssertEqual(PlantName.clean("\u{202E}\u{2067}\u{200E}"), "", "controls only")
    }

    func testNamesFromSyncOrABackupPassTheSameRule() throws {
        let app = try makeApp()
        let plants = app.plants()
        plants[0].nickname = "\u{202E}Rosie\u{202C}"
        plants[1].nickname = "\u{0301}\u{0301}"
        plants[2].nickname = "Pip"
        app.reconcileSyncedData()
        XCTAssertEqual(plants[0].nickname, "Rosie")
        XCTAssertEqual(plants[1].nickname, "")
        XCTAssertEqual(plants[2].nickname, "Pip")
    }

    func testDisplayNameFallsBackToTheSpecies() {
        XCTAssertEqual(PlantName.display(nickname: "", species: "Daisy"), "Daisy")
        XCTAssertEqual(PlantName.display(nickname: "Sunny", species: "Daisy"), "Sunny")
    }

    // MARK: Rename and pin through the app

    func testRenameSavesTheCleanNameAndAnEmptyNameClearsIt() throws {
        let app = try makeApp()
        let plant = app.plants().first!; plant.earnedCount = 1
        XCTAssertEqual(app.rename(plant, to: "  Sunny  "), "Sunny")
        XCTAssertEqual(app.plants().first { $0.plantId == plant.plantId }?.nickname, "Sunny", "the pencil opens on the saved name")
        XCTAssertEqual(app.rename(plant, to: "🌼🌼"), "")
        XCTAssertEqual(plant.nickname, "")
    }

    func testPinPutsThePlantOnTheWidget() throws {
        let app = try makeApp()
        let plants = app.plants(); plants[0].earnedCount = 1; plants[1].earnedCount = 1
        XCTAssertFalse(app.isOnWidget(plants[1]))
        app.pinToWidget(plants[1])
        XCTAssertEqual(app.profile?.widgetPlantID, plants[1].plantId)
        XCTAssertTrue(app.isOnWidget(plants[1])); XCTAssertFalse(app.isOnWidget(plants[0]))
        XCTAssertEqual(WidgetActions.snapshot(context: app.context, now: .now, calm: false).hero?.plantId, plants[1].plantId)
    }

    func testThePinnedPlantShowsByItsNameOnTheWidget() throws {
        let app = try makeApp()
        let plant = app.plants()[2]; plant.earnedCount = 1
        app.rename(plant, to: "Sunny"); app.pinToWidget(plant)
        XCTAssertEqual(WidgetActions.snapshot(context: app.context, now: .now, calm: false).hero?.name, "Sunny")
    }

    func testAMissingPinnedPlantFallsBackToTheDefaultPick() throws {
        let app = try makeApp()
        let plant = app.plants()[0]; plant.earnedCount = 1
        app.profile?.widgetPlantID = "not-a-plant"
        XCTAssertEqual(WidgetActions.snapshot(context: app.context, now: .now, calm: false).hero?.plantId, plant.plantId)
    }

    func testThePinSurvivesAMergeWithACopyThatHasNone() throws {
        let container = try SharedContainer.make(inMemory: true)
        let ctx = container.mainContext
        let a = PlayerProfile(); a.gamesPlayed = 1; a.widgetPlantID = "tulip"
        let b = PlayerProfile(); b.gamesPlayed = 9                          // the keeper, with no pin
        ctx.insert(a); ctx.insert(b); try ctx.save()
        DataReconciler.reconcile(context: ctx, badgeDefs: (try? BadgeCatalog.load()) ?? [])
        let merged = try ctx.fetch(FetchDescriptor<PlayerProfile>())
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].widgetPlantID, "tulip")
    }

    // MARK: Copy

    func testAllCopyPassesTheLinterWithLongAndShortNames() {
        for name in ["Pip", "Sunny", "Abcdefghijklmnop", "Éléonore Hélène", "🌸 Pip"] {
            for line in PlantNameCopy.all(name: name) {
                XCTAssertEqual(CopySafety.check(line), [], line)
            }
        }
        XCTAssertEqual(PlantNameCopy.saved("Sunny"), "Hello! I love the name Sunny.")
    }
}

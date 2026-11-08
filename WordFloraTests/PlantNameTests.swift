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

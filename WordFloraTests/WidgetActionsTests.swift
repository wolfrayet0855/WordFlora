import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class WidgetActionsTests: XCTestCase {
    var container: ModelContainer!
    var ctx: ModelContext { container.mainContext }
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    override func setUp() async throws {
        container = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: ctx)
        let p = PlayerProfile(); p.water = 3; p.lastTrickleAt = t0; ctx.insert(p)
        try ctx.save()
    }
    func plants(_ ids: [String]) -> [PlantCollectible] {
        ids.map { id in let p = try! ctx.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == id }!; p.earnedCount = 1; return p }
    }
    var profile: PlayerProfile { try! ctx.fetch(FetchDescriptor<PlayerProfile>()).first! }

    // MARK: hero choice
    func testNoEarnedPlantMeansNoHero() {
        XCTAssertNil(WidgetActions.snapshot(context: ctx, now: t0, calm: false).hero)
    }

    func testPinnedPlantWinsWhenOwned() {
        _ = plants(["rose", "tulip"]); profile.widgetPlantID = "tulip"
        XCTAssertEqual(WidgetActions.snapshot(context: ctx, now: t0, calm: false).hero?.plantId, "tulip")
    }

    func testUnownedPinFallsBackToTheThirstiestPlant() {
        let ps = plants(["rose", "tulip", "daisy"])
        ps[0].lastTendedAt = t0; ps[1].lastTendedAt = t0.addingTimeInterval(-90_000); ps[2].lastTendedAt = t0.addingTimeInterval(-3_600)
        profile.widgetPlantID = "baobab"                       // not owned
        XCTAssertEqual(WidgetActions.snapshot(context: ctx, now: t0, calm: false).hero?.plantId, "tulip")
    }

    func testSnapshotListsUpToTwoOtherPlantsAndTheDropCount() {
        _ = plants(["rose", "tulip", "daisy", "fern"]); profile.widgetPlantID = "rose"
        let s = WidgetActions.snapshot(context: ctx, now: t0, calm: false)
        XCTAssertEqual(s.others.count, 2); XCTAssertFalse(s.others.contains { $0.plantId == "rose" })
        XCTAssertEqual(s.water, 3)
    }

    func testThirstyLookFollowsTheEngineAndCalmModeHidesIt() {
        let ps = plants(["rose"]); ps[0].lastTendedAt = t0.addingTimeInterval(-49 * 3600)
        XCTAssertTrue(WidgetActions.snapshot(context: ctx, now: t0, calm: false).hero?.thirsty == true)
        XCTAssertTrue(WidgetActions.snapshot(context: ctx, now: t0, calm: true).hero?.thirsty == false)
    }

    // MARK: water button
    func testWaterButtonSpendsADropAndGrowsThePlant() {
        let ps = plants(["rose"])
        let r = WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: false)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(profile.water, 2); XCTAssertEqual(ps[0].growthPoints, 4)
    }

    func testWaterButtonIsGentleWhenOutOfDropsOrUnknown() {
        _ = plants(["rose"]); profile.water = 0
        XCTAssertEqual(WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: false).reason, .noWater)
        XCTAssertFalse(WidgetActions.water(plantId: "nope", context: ctx, now: t0, calendar: cal, quiet: false).applied)
    }

    func testFreeDropsArriveBeforeWatering() {
        _ = plants(["rose"]); profile.water = 0
        let later = t0.addingTimeInterval(9 * 3600)
        let r = WidgetActions.water(plantId: "rose", context: ctx, now: later, calendar: cal, quiet: false)
        XCTAssertTrue(r.applied)                                       // two free drops came in, one was spent
        XCTAssertEqual(profile.water, 1)
    }

    func testQuietGardenWateringSpendsNothingAndStillGrowsThePlant() {
        let ps = plants(["rose"]); profile.water = 0
        let r = WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: true)
        XCTAssertTrue(r.applied); XCTAssertEqual(ps[0].growthPoints, 4); XCTAssertEqual(profile.water, 0)
    }

    func testWidgetNeverShowsTheThirstyLook() {
        let ps = plants(["rose"]); ps[0].lastTendedAt = t0.addingTimeInterval(-100 * 3600)
        XCTAssertFalse(WidgetActions.snapshot(context: ctx, now: t0, calm: true).hero?.thirsty ?? true)
        XCTAssertTrue(WidgetActions.widgetShowsThirstyLook == false)
    }

    func testWateringTwiceInARowIsSafeAndRespectsTheDailyCap() {
        let ps = plants(["rose"]); profile.water = 9
        for _ in 0..<5 { _ = WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: false) }
        XCTAssertEqual(ps[0].growthPoints, 10)
        XCTAssertEqual(profile.water, 6)                              // only three drops were actually spent
    }

    // MARK: deep links
    func testWidgetLinksOpenTheRightScreens() {
        let r = GameRouter()
        r.open(URL(string: "wordflora://plant/rose")!)
        XCTAssertEqual(r.path, [.garden, .plant("rose")])
        r.open(URL(string: "wordflora://play")!)
        XCTAssertEqual(r.path, [.game(daily: false, level: nil)])
        r.open(URL(string: "https://example.com/plant/rose")!)           // other schemes are ignored
        XCTAssertEqual(r.path, [.game(daily: false, level: nil)])
        r.open(URL(string: "wordflora://unknown")!)
        XCTAssertTrue(r.path.isEmpty)                                    // unknown links just land on Home
    }
}


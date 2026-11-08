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
        XCTAssertEqual(profile.water, 2); XCTAssertEqual(ps[0].growthPoints, 3)
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
        XCTAssertTrue(r.applied); XCTAssertEqual(ps[0].growthPoints, 3); XCTAssertEqual(profile.water, 0)
    }

    func testWidgetNeverShowsTheThirstyLook() {
        let ps = plants(["rose"]); ps[0].lastTendedAt = t0.addingTimeInterval(-100 * 3600)
        XCTAssertFalse(WidgetActions.snapshot(context: ctx, now: t0, calm: true).hero?.thirsty ?? true)
        XCTAssertTrue(WidgetActions.widgetShowsThirstyLook == false)
    }

    func testWateringManyTimesIsSafeAndRespectsTheTwoDrinksADay() {
        let ps = plants(["rose"]); profile.water = 9
        for _ in 0..<5 { _ = WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: false) }
        XCTAssertEqual(ps[0].growthPoints, 6)
        XCTAssertEqual(profile.water, 7)                              // only two drops were actually spent
    }

    // MARK: hello (the widget's Say hello button)
    func testAHelloFromTheWidgetIsLoveLikeATapHello() {
        let ps = plants(["rose"]); ps[0].lastLovedAt = t0.addingTimeInterval(-30 * 3600)
        XCTAssertTrue(WidgetActions.hello(plantId: "rose", context: ctx, now: t0, exempt: false))
        XCTAssertEqual(ps[0].lastLovedAt, t0)
        XCTAssertEqual(LoveEngine.state(lastLoved: ps[0].lastLovedAt, now: t0, exempt: false).petalsLeft, LoveEngine.maxPetals)
        XCTAssertTrue(WidgetActions.hello(plantId: "rose", context: ctx, now: t0, exempt: false), "safe to repeat")
    }

    func testAWidgetHelloNeverWakesASeedAndNeedsAFoundPlant() {
        let ps = plants(["rose"]); let long = t0.addingTimeInterval(-30 * 86_400); ps[0].lastLovedAt = long
        XCTAssertFalse(WidgetActions.hello(plantId: "rose", context: ctx, now: t0, exempt: false), "a seed wakes in the app")
        XCTAssertEqual(ps[0].lastLovedAt, long)
        XCTAssertTrue(WidgetActions.hello(plantId: "rose", context: ctx, now: t0, exempt: true), "exempt players never have seeds")
        XCTAssertFalse(WidgetActions.hello(plantId: "tulip", context: ctx, now: t0, exempt: false), "not found yet")
    }

    func testTheWidgetReadsTheSameLoveExemptionAsTheApp() {
        let d = UserDefaults(suiteName: "wf-widget-love-\(UUID().uuidString)")!
        d.set("eighteenPlus", forKey: "ageBand")
        XCTAssertFalse(SharedDefaults.loveExempt(in: d))
        d.set(true, forKey: "calmMode"); XCTAssertTrue(SharedDefaults.loveExempt(in: d))
        d.set(false, forKey: "calmMode"); d.set(true, forKey: "quietGarden"); XCTAssertTrue(SharedDefaults.loveExempt(in: d))
        d.set(false, forKey: "quietGarden"); d.set("under13", forKey: "ageBand"); XCTAssertTrue(SharedDefaults.loveExempt(in: d))
        d.set("thirteenPlus", forKey: "ageBand"); XCTAssertFalse(SharedDefaults.loveExempt(in: d))
    }

    // MARK: buttons that answer (computed state, never stored)
    func testWaterStateFlipsAfterTwoWidgetDrinks() {
        _ = plants(["rose"]); profile.widgetPlantID = "rose"
        var h = WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).hero!
        XCTAssertFalse(h.wateredToday); XCTAssertFalse(h.waterDone)
        WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: false)
        h = WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).hero!
        XCTAssertTrue(h.wateredToday); XCTAssertFalse(h.waterDone, "one drink: the button still works")
        WidgetActions.water(plantId: "rose", context: ctx, now: t0, calendar: cal, quiet: false)
        h = WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).hero!
        XCTAssertTrue(h.waterDone, "two drinks: Watered today")
        XCTAssertFalse(WidgetActions.snapshot(context: ctx, now: t0.addingTimeInterval(86_400), calm: true, calendar: cal).hero!.waterDone,
                       "a new day, a new drink")
    }

    func testHelloStateFlipsAfterAWidgetHello() {
        let ps = plants(["rose"]); ps[0].lastLovedAt = t0.addingTimeInterval(-30 * 3600)
        XCTAssertFalse(WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).hero!.saidHelloToday)
        WidgetActions.hello(plantId: "rose", context: ctx, now: t0, exempt: false)
        XCTAssertTrue(WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).hero!.saidHelloToday)
    }

    func testASeedLinksToThePlantOnlyWhenNotExempt() {
        let ps = plants(["rose"]); ps[0].lastLovedAt = t0.addingTimeInterval(-30 * 86_400)
        XCTAssertTrue(WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal, exempt: false).hero!.isSeed)
        XCTAssertFalse(WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal, exempt: true).hero!.isSeed,
                       "under 13, Calm and Quiet Garden never have seeds")
    }

    // MARK: trickle freshness
    func testShownDropCountIncludesFreeDropsThatAreDueWithoutWriting() {
        _ = plants(["rose"]); profile.water = 0
        let s = WidgetActions.snapshot(context: ctx, now: t0.addingTimeInterval(9 * 3600), calm: true, calendar: cal)
        XCTAssertEqual(s.water, 2)                                        // two 4 h drops are in the can
        XCTAssertEqual(profile.water, 0, "the snapshot never writes")
        XCTAssertEqual(profile.lastTrickleAt, t0)
    }

    func testProjectedWaterMatchesApplyTrickle() {
        let eco = Economy.default
        for (start, hours) in [(0, 3.0), (0, 4.5), (1, 13.0), (eco.trickleCap - 1, 30.0), (eco.trickleCap + 2, 10.0)] {
            let p = PlayerProfile(); p.water = start; p.lastTrickleAt = t0
            let now = t0.addingTimeInterval(hours * 3600)
            let projected = TendingEngine.projectedWater(p, now: now, economy: eco)
            TendingEngine.applyTrickle(p, now: now, economy: eco)
            XCTAssertEqual(projected, p.water, "start \(start), \(hours) h")
        }
    }

    func testNextTrickleIsTheNextDropAndNilWhenFull() {
        let eco = Economy.default
        let p = PlayerProfile(); p.water = 0; p.lastTrickleAt = t0
        XCTAssertEqual(TendingEngine.nextTrickle(p, now: t0.addingTimeInterval(3600), economy: eco), t0.addingTimeInterval(eco.trickleHours * 3600))
        XCTAssertEqual(TendingEngine.nextTrickle(p, now: t0.addingTimeInterval(eco.trickleHours * 3600 + 60), economy: eco),
                       t0.addingTimeInterval(2 * eco.trickleHours * 3600))
        p.water = eco.trickleCap
        XCTAssertNil(TendingEngine.nextTrickle(p, now: t0, economy: eco))
        _ = plants(["rose"]); profile.water = 0
        XCTAssertNotNil(WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).nextTrickle)
    }

    // MARK: the plant answers (medium line)
    func testLinePicksWeatherThenHelloThenWaterThenDefault() {
        var s = WidgetActions.sample.hero!; s.voiceSeed = 7
        XCTAssertEqual(WidgetActions.line(for: s, weather: nil), WidgetCopy.defaultLine)
        s.wateredToday = true
        XCTAssertEqual(WidgetActions.line(for: s, weather: nil), PlantVoice.line(plantId: "rose", event: .water, daySeed: 7))
        s.saidHelloToday = true
        XCTAssertEqual(WidgetActions.line(for: s, weather: nil), PlantVoice.helloLine(plantId: "rose", daySeed: 7, tap: 0))
        XCTAssertEqual(WidgetActions.line(for: s, weather: "Tomorrow: windy"), "Tomorrow: windy")
        XCTAssertEqual(WidgetActions.line(for: s, weather: nil), WidgetActions.line(for: s, weather: nil), "stable for the day")
    }

    func testTheWidgetLineUsesTheAppsOwnSeed() {
        let ps = plants(["rose"]); ps[0].lastLovedAt = t0
        let h = WidgetActions.snapshot(context: ctx, now: t0, calm: true, calendar: cal).hero!
        XCTAssertEqual(h.voiceSeed, Int(t0.timeIntervalSince1970 / 86_400) &+ ps[0].earnedCount)   // AppModel.helloLine's seed
    }

    // MARK: gallery, empty state, copy
    func testGalleryShowsTheSampleOnlyInAPreviewWithNoPlant() {
        let none = WidgetActions.GardenSnapshot(hero: nil, others: [], water: 0)
        XCTAssertTrue(WidgetActions.galleryShowsSample(isPreview: true, snapshot: none))
        XCTAssertFalse(WidgetActions.galleryShowsSample(isPreview: false, snapshot: none))
        XCTAssertFalse(WidgetActions.galleryShowsSample(isPreview: true, snapshot: WidgetActions.sample))
        XCTAssertNotNil(WidgetActions.sample.hero)
    }

    func testEmptyWidgetIsCalmWhenTheStoreIsNotReady() {
        XCTAssertEqual(WidgetCopy.emptyLine(unavailable: true), GardenFallback.widgetLine)
        XCTAssertEqual(WidgetCopy.emptyLine(unavailable: false), WidgetCopy.firstPlant)
        let r = GameRouter()
        r.open(WidgetCopy.emptyURL(unavailable: true)); XCTAssertTrue(r.path.isEmpty, "opens the app on Home")
        r.open(WidgetCopy.emptyURL(unavailable: false)); XCTAssertEqual(r.path, [.game(daily: false, level: nil)])
    }

    func testEveryWidgetWordPassesCopySafety() {
        for line in WidgetCopy.all() { XCTAssertEqual(CopySafety.check(line), [], line) }
        for trait in PlantVoice.Trait.allCases {
            for line in PlantVoice.lines(trait: trait, event: .water) + PlantVoice.lines(trait: trait, event: .hello) {
                XCTAssertEqual(CopySafety.check(line), [], line)
            }
        }
        XCTAssertEqual(WidgetCopy.inline(name: "Daisy", chip: nil), "Daisy: growing nicely")
        XCTAssertEqual(WidgetCopy.inline(name: "Daisy", chip: "Tomorrow: windy"), "Daisy: Tomorrow: windy")
        XCTAssertEqual(WidgetCopy.waterLabel(name: "Daisy", water: 1, quiet: false), "Water Daisy. 1 drop in your can")
        XCTAssertEqual(WidgetCopy.percent(0.404), "40 percent")
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


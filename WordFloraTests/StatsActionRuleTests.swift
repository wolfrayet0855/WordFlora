import XCTest
import SwiftData
@testable import WordFlora

/// THE RULE (docs/pm/2026-11-04-plan.md, section b): every action has its own daily allowance per plant, no action blocks
/// another, and a meter shows only its own action's state, so a low meter always means its button works.
@MainActor
final class StatsActionRuleTests: XCTestCase {
    let utc: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
    let eco = Economy.default
    /// Noon UTC, so a few hours of play stay inside one day.
    var noon: Date { utc.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))! }

    func plant(level: Int = 1, id: String = "rose") -> PlantCollectible {
        PlantCollectible(name: id.capitalized, botanicalName: "x", botanicalFact: "f", level: level, imageName: "plant_\(id)")
    }
    func profile(water: Int = 99, soil: Int = 99) -> PlayerProfile {
        let p = PlayerProfile(); p.water = water; p.soil = soil; p.lastTrickleAt = noon; return p
    }
    func water(_ p: PlantCollectible, _ pr: PlayerProfile, _ d: Date, cal: Calendar? = nil, quiet: Bool = false) -> TendResult {
        TendingEngine.water(p, profile: pr, now: d, calendar: cal ?? utc, economy: eco, quiet: quiet)
    }
    func feed(_ p: PlantCollectible, _ pr: PlayerProfile, _ d: Date, cal: Calendar? = nil, quiet: Bool = false) -> TendResult {
        TendingEngine.addSoil(p, profile: pr, now: d, calendar: cal ?? utc, economy: eco, quiet: quiet)
    }
    func sun(_ p: PlantCollectible, _ pr: PlayerProfile, _ d: Date, cal: Calendar? = nil, quiet: Bool = false) -> TendResult {
        TendingEngine.sun(p, profile: pr, now: d, calendar: cal ?? utc, economy: eco, quiet: quiet)
    }
    func meters(_ p: PlantCollectible, _ d: Date, cal: Calendar? = nil, exempt: Bool = false) -> LifeStats.Snapshot {
        LifeStats.snapshot(LifeStats.Inputs(plant: p, now: d, calendar: cal ?? utc, exempt: exempt))
    }

    // MARK: No action blocks another

    func testFeedNoLongerBlocksWaterOrSun() {
        let p = plant(), pr = profile()
        XCTAssertTrue(feed(p, pr, noon).applied)
        XCTAssertTrue(water(p, pr, noon.addingTimeInterval(60)).applied)
        XCTAssertTrue(water(p, pr, noon.addingTimeInterval(120)).applied)
        XCTAssertTrue(sun(p, pr, noon.addingTimeInterval(180)).applied)
    }

    func testSunThenWaterTwiceWorksAndAThirdWaterIsDoneForToday() {
        let p = plant(), pr = profile(water: 5)
        XCTAssertTrue(sun(p, pr, noon).applied)
        XCTAssertTrue(water(p, pr, noon).applied)
        XCTAssertEqual(meters(p, noon).water.word, "Good")
        XCTAssertTrue(water(p, pr, noon).applied)
        XCTAssertEqual(meters(p, noon).water.word, "Full")
        let third = water(p, pr, noon)
        XCTAssertFalse(third.applied); XCTAssertEqual(third.reason, .doneForToday)
        XCTAssertEqual(pr.water, 3, "a drink that is not taken costs no drop")
    }

    func testSunIsOnceADayEvenInQuietGarden() {
        let p = plant(), pr = profile()
        XCTAssertTrue(sun(p, pr, noon).applied)
        XCTAssertEqual(sun(p, pr, noon.addingTimeInterval(60)).reason, .doneForToday)
        let q = plant()
        XCTAssertTrue(sun(q, pr, noon, quiet: true).applied)
        XCTAssertEqual(sun(q, pr, noon, quiet: true).reason, .doneForToday)
    }

    func testFeedIsOnceADay() {
        let p = plant(), pr = profile(soil: 5)
        XCTAssertTrue(feed(p, pr, noon).applied)
        let again = feed(p, pr, noon.addingTimeInterval(60))
        XCTAssertEqual(again.reason, .doneForToday); XCTAssertEqual(pr.soil, 4, "a scoop that is not used is not spent")
    }

    func testANewDayResetsEveryAllowance() {
        let p = plant(), pr = profile()
        _ = feed(p, pr, noon); _ = sun(p, pr, noon); _ = water(p, pr, noon); _ = water(p, pr, noon)
        let tomorrow = utc.startOfDay(for: noon).addingTimeInterval(86_400 + 60)
        XCTAssertEqual(meters(p, tomorrow).water.word, "Ready for a drink")
        XCTAssertEqual(meters(p, tomorrow).sunshine.word, "Ready for sun")
        XCTAssertTrue(water(p, pr, tomorrow).applied); XCTAssertTrue(sun(p, pr, tomorrow).applied); XCTAssertTrue(feed(p, pr, tomorrow).applied)
    }

    func testMidnightAndDaylightSavingResetsFollowTheLocalCalendar() {
        var ny = Calendar(identifier: .gregorian); ny.timeZone = TimeZone(identifier: "America/New_York")!
        // 2026-03-08 springs forward and 2026-11-01 falls back: one 23-hour and one 25-hour day.
        for (y, m, d) in [(2026, 3, 8), (2026, 11, 1)] {
            let day = ny.date(from: DateComponents(year: y, month: m, day: d, hour: 0, minute: 30))!
            let late = ny.date(from: DateComponents(year: y, month: m, day: d, hour: 23, minute: 30))!
            let next = ny.date(from: DateComponents(year: y, month: m, day: d + 1, hour: 0, minute: 5))!
            let p = plant(), pr = profile()
            XCTAssertTrue(water(p, pr, day, cal: ny).applied)
            XCTAssertTrue(water(p, pr, late, cal: ny).applied)
            XCTAssertEqual(water(p, pr, late, cal: ny).reason, .doneForToday)
            XCTAssertTrue(TendingEngine.isDone(.water, plant: p, now: late, calendar: ny, economy: eco))
            XCTAssertFalse(TendingEngine.isDone(.water, plant: p, now: next, calendar: ny, economy: eco))
            XCTAssertTrue(water(p, pr, next, cal: ny).applied, "just after local midnight is a new day")
        }
    }

    // MARK: Meters say only their own action's state

    func testMetersShowTheirOwnAction() {
        let p = plant(), pr = profile()
        XCTAssertEqual(meters(p, noon).water.word, "Ready for a drink")
        XCTAssertEqual(meters(p, noon).water.fill, LifeStats.readyFill, accuracy: 0.001)
        _ = feed(p, pr, noon)
        XCTAssertEqual(meters(p, noon).water.word, "Ready for a drink", "feeding never fills the water meter")
        XCTAssertEqual(meters(p, noon).sunshine.word, "Ready for sun")
        _ = water(p, pr, noon)
        XCTAssertEqual(meters(p, noon).water.fill, 0.75, accuracy: 0.001)
        _ = water(p, pr, noon)
        XCTAssertEqual(meters(p, noon).water.fill, 1.0, accuracy: 0.001)
        XCTAssertTrue(meters(p, noon).water.done)
        _ = sun(p, pr, noon)
        XCTAssertEqual(meters(p, noon).sunshine.word, "Bright"); XCTAssertTrue(meters(p, noon).sunshine.done)
    }

    func testRainNeverChangesTheSunMeter() {
        let p = plant(), pr = profile()
        p.lastLovedAt = noon.addingTimeInterval(-30 * 3600)                    // a rainy day
        XCTAssertGreaterThan(meters(p, noon).rainDay, 0)
        XCTAssertEqual(meters(p, noon).sunshine.word, "Ready for sun")
        _ = sun(p, pr, noon)
        p.lastLovedAt = noon.addingTimeInterval(-30 * 3600)
        XCTAssertEqual(meters(p, noon).sunshine.word, "Bright")
    }

    /// Hearts: a hello, a drink, sun, soil, and a finishing touch (the second drink or a prune). Every player can fill
    /// all five on one day with the free actions alone.
    func testEveryPlayerCanFillAllFiveHeartsWithoutTools() {
        let p = plant(), pr = profile()
        p.lastLovedAt = noon
        XCTAssertEqual(meters(p, noon).hearts, 1)
        _ = water(p, pr, noon); XCTAssertEqual(meters(p, noon).hearts, 2)
        _ = water(p, pr, noon); XCTAssertEqual(meters(p, noon).hearts, 3, "the second drink is the finishing touch")
        _ = feed(p, pr, noon); _ = sun(p, pr, noon)
        XCTAssertEqual(meters(p, noon).hearts, 5); XCTAssertEqual(meters(p, noon).loveLine, "Loved")
        XCTAssertEqual(ToolEngine.prune(p, inventory: ToolInventory(), now: noon, calendar: utc, economy: eco).reason, .notOwned)
    }

    func testAPruneCanBeTheFinishingTouchInsteadOfTheSecondDrink() {
        let p = plant(), pr = profile()
        p.lastLovedAt = noon
        _ = water(p, pr, noon); _ = feed(p, pr, noon); _ = sun(p, pr, noon)
        XCTAssertEqual(meters(p, noon).hearts, 4)
        var inv = ToolInventory(); inv.unlock(.shears)
        XCTAssertTrue(ToolEngine.prune(p, inventory: inv, now: noon, calendar: utc, economy: eco).applied)
        XCTAssertEqual(meters(p, noon).hearts, 5)
        _ = water(p, pr, noon); XCTAssertEqual(meters(p, noon).hearts, 5, "both touches still make five")
    }

    func testHeartsStartAgainEachDay() {
        let p = plant(), pr = profile()
        p.lastLovedAt = noon
        _ = water(p, pr, noon); _ = water(p, pr, noon); _ = feed(p, pr, noon); _ = sun(p, pr, noon)
        let tomorrow = utc.startOfDay(for: noon).addingTimeInterval(86_400 + 3600)
        p.lastLovedAt = tomorrow
        XCTAssertEqual(meters(p, tomorrow).hearts, 1, "yesterday's care does not count")
    }

    /// Property: across many random days of play, before every tap the meter (and the button state) predicts exactly
    /// whether the tap will work. Supplies are kept full so the only thing that can block is today's allowance.
    func testMetersAndButtonsNeverContradictOverManyActionSequences() {
        var rng = SeededRNG(seed: 7)
        for quiet in [false, true] {
            for _ in 0..<60 {
                let p = plant(level: Int.random(in: 1...5, using: &rng)), pr = profile()
                var t = noon.addingTimeInterval(-11 * 3600)
                for _ in 0..<40 {
                    t = t.addingTimeInterval(Double(Int.random(in: 0...5, using: &rng)) * 3600)
                    let snap = meters(p, t, exempt: quiet)
                    let action = TendingEngine.Care.allCases.randomElement(using: &rng)!
                    let done = TendingEngine.isDone(action, plant: p, now: t, calendar: utc, economy: eco)
                    switch action {
                    case .water: XCTAssertEqual(snap.water.done, done); XCTAssertEqual(snap.water.word == "Full", done)
                    case .sun: XCTAssertEqual(snap.sunshine.done, done); XCTAssertEqual(snap.sunshine.word == "Bright", done)
                    case .feed: break
                    }
                    let before = p.growthPoints
                    let r: TendResult = {
                        switch action {
                        case .water: return water(p, pr, t, quiet: quiet)
                        case .feed: return feed(p, pr, t, quiet: quiet)
                        case .sun: return sun(p, pr, t, quiet: quiet)
                        }
                    }()
                    XCTAssertEqual(r.applied, !done, "\(action) at \(t): meter said done=\(done)")
                    if r.applied { XCTAssertGreaterThan(p.growthPoints, before, "a working button visibly does something") }
                    else { XCTAssertEqual(r.reason, .doneForToday) }
                    pr.water = 99; pr.soil = 99
                }
            }
        }
    }

    // MARK: Pacing (decisions-research.md: two waters, base 200, boosted full bloom about 13 to 18 days)

    func daysToFullBloom(level: Int, feedDaily: Bool) -> Int {
        let p = plant(level: level), pr = profile()
        var day = 0
        while p.stage < 4 && day < 200 {
            let t = noon.addingTimeInterval(Double(day) * 86_400)
            if feedDaily { _ = feed(p, pr, t) }
            _ = water(p, pr, t); _ = water(p, pr, t); _ = water(p, pr, t)       // the third is politely declined
            _ = sun(p, pr, t)
            day += 1
            pr.water = 99; pr.soil = 99
        }
        return day
    }

    func testEconomyNumbersMatchTheOwnerDecisions() {
        XCTAssertEqual(eco.waterPerDay, 2); XCTAssertEqual(eco.waterGrowth, 3); XCTAssertEqual(eco.soilGrowth, 4)
        XCTAssertEqual(eco.sunGrowth, 2); XCTAssertEqual(eco.levelBaseCost, 200)
    }

    func testABusyGardenerReachesFullBloomInAboutTwoToThreeWeeks() {
        let l1 = daysToFullBloom(level: 1, feedDaily: true), l5 = daysToFullBloom(level: 5, feedDaily: true)
        XCTAssertTrue((13...18).contains(l1), "L1 boosted took \(l1) days")
        XCTAssertTrue((13...18).contains(l5), "L5 boosted took \(l5) days")
        XCTAssertLessThan(l1, l5)
        let unboosted = daysToFullBloom(level: 1, feedDaily: false)
        XCTAssertTrue((17...25).contains(unboosted), "L1 unboosted took \(unboosted) days")
    }

    func testOneDaysGrowthStaysBounded() {
        let p = plant(), pr = profile()
        var inv = ToolInventory(); inv.unlock(.shears); inv.unlock(.lamp)
        var pts = 9_999
        for tool in [ToolID.can, .trowel, .shears, .lamp] { _ = inv.upgrade(tool, shedPoints: &pts); _ = inv.upgrade(tool, shedPoints: &pts) }
        for _ in 0..<20 {
            _ = ToolEngine.waterWithCan([p], profile: pr, inventory: inv, now: noon, calendar: utc, economy: eco)
            _ = ToolEngine.addSoil(p, profile: pr, inventory: inv, now: noon, calendar: utc, economy: eco)
            _ = ToolEngine.sunWithLamp(p, profile: pr, inventory: inv, now: noon, calendar: utc, economy: eco)
            _ = ToolEngine.prune(p, inventory: inv, now: noon, calendar: utc, economy: eco)
            _ = ToolEngine.repot(p, to: SoilType.preferred(forPlantId: p.plantId), profile: pr, now: noon, calendar: utc, economy: eco)
        }
        XCTAssertLessThanOrEqual(p.growthPoints, 32, "water 10 + soil 6 + lamp 4 + prune 8 + happy repot 4 at most")
        let q = plant()
        for _ in 0..<20 {
            _ = ToolEngine.prune(q, inventory: ToolInventory(), now: noon, calendar: utc, economy: eco, quiet: true)
            _ = ToolEngine.repot(q, to: SoilType.preferred(forPlantId: q.plantId), profile: pr, now: noon, calendar: utc, economy: eco, quiet: true)
        }
        XCTAssertLessThanOrEqual(q.growthPoints, 8, "Quiet Garden is free but still paced: one prune and one happy repot a day")
    }

    // MARK: Sync and backup keep the best of each

    func testMergeKeepsTheLaterDaysWateringsAndTheLatestFeed() {
        let today = utc.startOfDay(for: noon), yesterday = today.addingTimeInterval(-86_400)
        let k = plant(), o = plant()
        k.waterDay = yesterday; k.waterToday = 2; k.lastFedAt = yesterday
        o.waterDay = today; o.waterToday = 1; o.lastFedAt = noon
        DataReconciler.merge(o, into: k)
        XCTAssertEqual(k.waterDay, today); XCTAssertEqual(k.waterToday, 1); XCTAssertEqual(k.lastFedAt, noon)

        let a = plant(), b = plant()
        a.waterDay = today; a.waterToday = 2
        b.waterDay = today; b.waterToday = 1; b.lastFedAt = nil
        a.lastFedAt = yesterday
        DataReconciler.merge(b, into: a)
        XCTAssertEqual(a.waterDay, today); XCTAssertEqual(a.waterToday, 2, "same day: the most waterings win"); XCTAssertEqual(a.lastFedAt, yesterday)
    }

    func testBackupCarriesTheDailyAllowances() throws {
        let container = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: container.mainContext)
        let ctx = container.mainContext
        ctx.insert(PlayerProfile())
        let rose = try ctx.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "rose" }!
        rose.earnedCount = 1; rose.waterDay = utc.startOfDay(for: noon); rose.waterToday = 2; rose.lastFedAt = noon
        try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: noon).encoded()

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: []) else { return XCTFail("restore failed") }
        let r = try fresh.mainContext.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "rose" }!
        XCTAssertEqual(r.waterToday, 2); XCTAssertEqual(r.waterDay, utc.startOfDay(for: noon)); XCTAssertEqual(r.lastFedAt, noon)
    }

    // MARK: The app and widget follow the same rule

    func makeApp(quiet: Bool = false, now: @escaping () -> Date) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-rule-\(UUID().uuidString)")!)
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: now, notifications: ReminderTests.FakeCenter())
    }
    var localNoon: Date { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))! }

    func testAppActionStatesMatchTheTapsAndExplainWhy() throws {
        let t = localNoon
        let app = try makeApp(now: { t })
        let plant = app.plants().first!; plant.earnedCount = 1; plant.nickname = "Pip"
        app.profile?.water = 9; app.profile?.soil = 3
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .ready)
        XCTAssertTrue(app.tend(.feed, plant: plant).applied)
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .ready, "feeding never blocks water")
        XCTAssertEqual(app.actionState(.feed, plant: plant).status, .done)
        XCTAssertEqual(app.actionState(.feed, plant: plant).label, "Fed today")
        XCTAssertEqual(app.tend(.feed, plant: plant).message, "Pip is well fed today. More soil tomorrow.")
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .ready, "one drink is good, two is full")
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        let w = app.actionState(.water, plant: plant)
        XCTAssertEqual(w.status, .done)
        XCTAssertEqual(w.line, "Pip has had all the water it needs today. Sun or a hello would be nice.")
        XCTAssertEqual(app.tend(.water, plant: plant).message, w.line)
        XCTAssertTrue(app.tend(.sun, plant: plant).applied)
        XCTAssertEqual(app.tend(.sun, plant: plant).message, "Pip soaked up the sun today. More sun tomorrow!")
        XCTAssertEqual(app.profile?.water, 7)
    }

    func testOutOfSuppliesIsANeedNotADoneState() throws {
        let t = localNoon
        let app = try makeApp(now: { t })
        let plant = app.plants().first!; plant.earnedCount = 1
        app.profile?.water = 0; app.profile?.soil = 0
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .needsSupply)
        XCTAssertEqual(app.actionState(.water, plant: plant).line, "Your can is dry. Win a word to fill it.")
        XCTAssertEqual(app.tend(.water, plant: plant).message, "Your can is dry. Win a word to fill it.")
        XCTAssertEqual(app.actionState(.feed, plant: plant).status, .needsSupply)
        XCTAssertEqual(app.tend(.feed, plant: plant).message, "Out of soil scoops. Find a new plant to get more.")
        XCTAssertEqual(app.actionState(.sun, plant: plant).status, .ready, "sun is always free")
    }

    func testQuietGardenFollowsTheSameAllowances() throws {
        let t = localNoon
        let app = try makeApp(quiet: true, now: { t })
        let plant = app.plants().first!; plant.earnedCount = 1
        app.profile?.water = 0; app.profile?.soil = 0
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .ready)
        XCTAssertTrue(app.tend(.water, plant: plant).applied); XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertFalse(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(app.actionState(.water, plant: plant).status, .done)
        XCTAssertTrue(app.tend(.feed, plant: plant).applied); XCTAssertFalse(app.tend(.feed, plant: plant).applied)
        XCTAssertEqual(plant.growthPoints, 3 + 3 + 4)
        XCTAssertFalse(app.tend(.water, plant: plant).message.contains("+"), "Quiet Garden hides numbers")
    }

    func testWidgetAndSiriWaterFollowTheSameRule() throws {
        let container = try SharedContainer.make(inMemory: true)
        let ctx = container.mainContext
        try PlantCatalog.seedIfNeeded(context: ctx)
        let pr = PlayerProfile(); pr.water = 9; pr.lastTrickleAt = noon; ctx.insert(pr)
        let rose = try ctx.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "rose" }!
        rose.earnedCount = 1; try ctx.save()
        XCTAssertTrue(WidgetActions.water(plantId: "rose", context: ctx, now: noon, calendar: utc, quiet: false).applied)
        XCTAssertTrue(WidgetActions.water(plantId: "rose", context: ctx, now: noon, calendar: utc, quiet: false).applied)
        XCTAssertEqual(WidgetActions.water(plantId: "rose", context: ctx, now: noon, calendar: utc, quiet: false).reason, .doneForToday)
        XCTAssertEqual(WidgetActions.waterGarden(context: ctx, now: noon, calendar: utc, quiet: false),
                       "Rose has had all the water it needs today. Sun or a hello would be nice.")
        XCTAssertEqual(pr.water, 7)
        pr.water = 0
        let tomorrow = noon.addingTimeInterval(86_400)
        pr.lastTrickleAt = tomorrow
        XCTAssertEqual(WidgetActions.waterGarden(context: ctx, now: tomorrow, calendar: utc, quiet: false), "Your can is dry. Win a word to fill it.")
    }

    // MARK: Copy

    func testEmptyAndLeftAreBanned() {
        XCTAssertFalse(CopySafety.check("No drops left").isEmpty)
        XCTAssertFalse(CopySafety.check("Your can is empty").isEmpty)
    }

    func testEveryRuleLineIsGentleAndUsesTheNickname() {
        let lines = AppModel.ruleLines(name: "Pip") + TendingEngine.Capacity.allCases.map { TendingEngine.capacityLine($0, name: "Pip") }
            + LifeStats.allCopy(name: "Pip")
        let banned = ["miss", "only", "last", "waiting", "lost", "dead", "empty", "left", "beat", "forget"]
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for w in banned { XCTAssertNil(line.range(of: "\\b\(w)\\b", options: [.regularExpression, .caseInsensitive]), "\(w) in \(line)") }
            XCTAssertFalse(line.localizedCaseInsensitiveContains("sunshine today"), "the old capacity line named sun by mistake: \(line)")
        }
        for care in TendingEngine.Care.allCases { XCTAssertTrue(TendCopy.done(care, name: "Pip").hasPrefix("Pip "), "done lines use the nickname") }
    }
}

/// Small deterministic generator so the property test is repeatable.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

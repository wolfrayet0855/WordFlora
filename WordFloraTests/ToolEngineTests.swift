import XCTest
@testable import WordFlora

final class ToolEngineTests: XCTestCase {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    let eco = Economy.default

    func plant(_ id: String = "rose", level: Int = 1) -> PlantCollectible {
        PlantCollectible(name: id.capitalized, botanicalName: "x", botanicalFact: "f", level: level, imageName: "plant_\(id)")
    }
    func profile(water: Int = 9, soil: Int = 9, shed: Int = 0) -> PlayerProfile {
        let p = PlayerProfile(); p.water = water; p.soil = soil; p.shedPoints = shed; return p
    }

    // MARK: inventory
    func testStartsWithCanAndTrowelOnly() {
        let inv = ToolInventory()
        XCTAssertEqual(inv.tier(of: .can), 1); XCTAssertEqual(inv.tier(of: .trowel), 1)
        for t in [ToolID.shears, .mister, .lamp, .net] { XCTAssertEqual(inv.tier(of: t), 0) }
    }

    func testUnlockGivesTierOneOnceAndNeverDowngrades() {
        var inv = ToolInventory(); inv.unlock(.shears)
        XCTAssertEqual(inv.tier(of: .shears), 1)
        var pts = 500; XCTAssertTrue(inv.upgrade(.shears, shedPoints: &pts))
        inv.unlock(.shears)
        XCTAssertEqual(inv.tier(of: .shears), 2)
    }

    func testUpgradeCostsThirtyThenOneTwenty() {
        var inv = ToolInventory(); var pts = 29
        XCTAssertFalse(inv.upgrade(.can, shedPoints: &pts)); XCTAssertEqual(pts, 29)
        pts = 30; XCTAssertTrue(inv.upgrade(.can, shedPoints: &pts)); XCTAssertEqual(pts, 0); XCTAssertEqual(inv.tier(of: .can), 2)
        pts = 119; XCTAssertFalse(inv.upgrade(.can, shedPoints: &pts))
        pts = 120; XCTAssertTrue(inv.upgrade(.can, shedPoints: &pts)); XCTAssertEqual(inv.tier(of: .can), 3)
        pts = 999; XCTAssertFalse(inv.upgrade(.can, shedPoints: &pts))      // max tier
    }

    func testCannotUpgradeAToolYouDoNotOwn() {
        var inv = ToolInventory(); var pts = 999
        XCTAssertFalse(inv.upgrade(.net, shedPoints: &pts)); XCTAssertEqual(pts, 999)
    }

    func testInventoryRoundTripsThroughJSON() {
        var inv = ToolInventory(); inv.unlock(.mister); var pts = 100; _ = inv.upgrade(.can, shedPoints: &pts)
        XCTAssertEqual(ToolInventory(json: inv.json), inv)
        XCTAssertEqual(ToolInventory(json: ""), ToolInventory())
        XCTAssertEqual(ToolInventory(json: "{not json"), ToolInventory())
    }

    // MARK: watering can
    func testBetterCansWaterMorePlantsPerUseAndSpendOneDropEach() {
        let plants = [plant("a"), plant("b"), plant("c"), plant("d")]
        var inv = ToolInventory(); let pr = profile(water: 9)
        XCTAssertEqual(ToolEngine.waterWithCan(plants, profile: pr, inventory: inv, now: t0, calendar: cal, economy: eco).count, 1)
        var pts = 500; _ = inv.upgrade(.can, shedPoints: &pts); _ = inv.upgrade(.can, shedPoints: &pts)
        let results = ToolEngine.waterWithCan(plants, profile: pr, inventory: inv, now: t0.addingTimeInterval(86_400), calendar: cal, economy: eco)
        XCTAssertEqual(results.filter(\.applied).count, 3)
        XCTAssertEqual(pr.water, 9 - 1 - 3)
    }

    func testCanStopsWhenDropsRunOut() {
        let plants = [plant("a"), plant("b"), plant("c")]
        var inv = ToolInventory(); var pts = 500; _ = inv.upgrade(.can, shedPoints: &pts); _ = inv.upgrade(.can, shedPoints: &pts)
        let pr = profile(water: 2)
        let r = ToolEngine.waterWithCan(plants, profile: pr, inventory: inv, now: t0, calendar: cal, economy: eco)
        XCTAssertEqual(r.filter(\.applied).count, 2); XCTAssertEqual(pr.water, 0)
    }

    // MARK: trowel and lamp
    func testTrowelTierScalesSoilGrowth() {
        let p = plant(), pr = profile(soil: 3)
        var inv = ToolInventory(); var pts = 500; _ = inv.upgrade(.trowel, shedPoints: &pts)
        let r = ToolEngine.addSoil(p, profile: pr, inventory: inv, now: t0, calendar: cal, economy: eco)
        XCTAssertEqual(r.gpGained, 5)                  // 4 x 1.25 = 5
    }

    func testLampTierRaisesSunGrowth() {
        var inv = ToolInventory(); inv.unlock(.lamp); var pts = 500
        _ = inv.upgrade(.lamp, shedPoints: &pts); _ = inv.upgrade(.lamp, shedPoints: &pts)
        let p = plant()
        XCTAssertEqual(ToolEngine.sunWithLamp(p, profile: profile(), inventory: inv, now: t0, calendar: cal, economy: eco).gpGained, 4)
    }

    func testUnownedLampDoesNothing() {
        let r = ToolEngine.sunWithLamp(plant(), profile: profile(), inventory: ToolInventory(), now: t0, calendar: cal, economy: eco)
        XCTAssertEqual(r.reason, .notOwned)
    }

    // MARK: pruning
    func testPruneGrowthByTierAndTwoDayCooldown() {
        var inv = ToolInventory(); inv.unlock(.shears)
        let p = plant()
        XCTAssertEqual(ToolEngine.prune(p, inventory: inv, now: t0, calendar: cal, economy: eco).gpGained, 4)
        XCTAssertEqual(ToolEngine.prune(p, inventory: inv, now: t0.addingTimeInterval(86_400), calendar: cal, economy: eco).reason, .cooldown)
        XCTAssertTrue(ToolEngine.prune(p, inventory: inv, now: t0.addingTimeInterval(2 * 86_400), calendar: cal, economy: eco).applied)
    }

    func testPruneNeedsShears() {
        XCTAssertEqual(ToolEngine.prune(plant(), inventory: ToolInventory(), now: t0, calendar: cal, economy: eco).reason, .notOwned)
    }

    // MARK: repot
    func testPreferredSoilIsDeterministicAndVaried() {
        let ids = ["rose", "tulip", "fern", "bamboo", "aloe_vera", "baobab", "lithops", "sundew", "jade_vine", "daisy"]
        let soils = ids.map { SoilType.preferred(forPlantId: $0) }
        XCTAssertEqual(soils, ids.map { SoilType.preferred(forPlantId: $0) })
        XCTAssertGreaterThan(Set(soils).count, 1)
    }

    func testRepotMatchIsHappyAndMismatchIsNeutralNeverHarmful() {
        let p = plant("rose"); let pr = profile(soil: 5)
        let good = SoilType.preferred(forPlantId: "rose")
        let bad = SoilType.allCases.first { $0 != good }!
        let r1 = ToolEngine.repot(p, to: bad, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertEqual(r1.outcome, .neutral); XCTAssertNil(p.soilBoostUntil)
        let before = p.growthPoints, stage = p.stage
        let r2 = ToolEngine.repot(p, to: good, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertEqual(r2.outcome, .happy); XCTAssertNotNil(p.soilBoostUntil)
        XCTAssertGreaterThanOrEqual(p.growthPoints, before); XCTAssertGreaterThanOrEqual(p.stage, stage)
        XCTAssertEqual(pr.soil, 3); XCTAssertEqual(p.soilType, good.rawValue)
    }

    func testRepotWithoutScoopsDoesNothing() {
        let r = ToolEngine.repot(plant(), to: .loam, profile: profile(soil: 0), now: t0, calendar: cal, economy: eco)
        XCTAssertFalse(r.applied)
    }

    // MARK: quiet garden
    func testQuietGardenIgnoresCostsAndOwnershipButGrowthStaysPaced() {
        let p = plant(), pr = profile(water: 0, soil: 0)
        XCTAssertTrue(ToolEngine.prune(p, inventory: ToolInventory(), now: t0, calendar: cal, economy: eco, quiet: true).applied)   // no shears needed
        XCTAssertEqual(ToolEngine.prune(p, inventory: ToolInventory(), now: t0, calendar: cal, economy: eco, quiet: true).reason, .cooldown)   // pruning still rests
        XCTAssertTrue(ToolEngine.repot(p, to: .peaty, profile: pr, now: t0, calendar: cal, economy: eco, quiet: true).applied)
        XCTAssertEqual(pr.soil, 0)
        XCTAssertEqual(p.growthPoints, 4)
    }

    func testHappyRepotGrowsOnceADay() {
        let p = plant("rose"); let pr = profile(soil: 5)
        let good = SoilType.preferred(forPlantId: "rose")
        XCTAssertEqual(ToolEngine.repot(p, to: good, profile: pr, now: t0, calendar: cal, economy: eco).tend.gpGained, 4)
        let again = ToolEngine.repot(p, to: good, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertTrue(again.applied); XCTAssertEqual(again.outcome, .happy); XCTAssertEqual(again.tend.gpGained, 0)
        XCTAssertEqual(p.growthPoints, 4)
        XCTAssertEqual(ToolEngine.repot(p, to: good, profile: pr, now: t0.addingTimeInterval(86_400), calendar: cal, economy: eco).tend.gpGained, 4)
    }
    // MARK: price truth (Shed text reads these numbers; 6 tools x (30 + 120) = 900 points to fill the Shed)
    func testUpgradePricesAreThirtyAndOneTwentyAndTheWholeShedIsNineHundred() {
        XCTAssertEqual(ToolInventory.upgradeCost(toTier: 2), 30)
        XCTAssertEqual(ToolInventory.upgradeCost(toTier: 3), 120)
        XCTAssertNil(ToolInventory.upgradeCost(toTier: 4))
        XCTAssertEqual(ToolInventory.totalUpgradeCostForAllTools, 900)
    }

    // MARK: net
    func testNetCatchCircleGrowsByTier() {
        XCTAssertEqual(ToolEngine.netCatchRadius(tier: 1), 48)
        XCTAssertEqual(ToolEngine.netCatchRadius(tier: 2), 64)
        XCTAssertEqual(ToolEngine.netCatchRadius(tier: 3), 80)
        XCTAssertEqual(ToolEngine.netCatchRadius(tier: 0), 48)        // before the net is found, the small circle
        XCTAssertEqual(ToolEngine.netCatchRadius(tier: 9), 80)
    }

    func testABiggerNetCatchesAVisitorASmallNetCannotReach() {
        var g = ButterflyGameModel(pool: ["monarch"], floweringPlants: 4, reduceMotion: true, seed: 1)
        g.tick(0.5)
        let v = try! XCTUnwrap(g.visitors.first)
        let width = 400.0, offset = 56.0 / width          // 56 pt away: outside 48, inside 64
        var small = g, big = g
        XCTAssertNil(small.catchAt(x: v.x + offset, y: v.y, radius: ToolEngine.netCatchRadius(tier: 1) / width))
        XCTAssertEqual(big.catchAt(x: v.x + offset, y: v.y, radius: ToolEngine.netCatchRadius(tier: 2) / width), "monarch")
    }

    // MARK: mister
    func testMisterSpeedsTheFreeDropsByTier() {
        XCTAssertEqual(ToolEngine.trickleHours(forMister: 1), 4); XCTAssertEqual(ToolEngine.trickleCap(forMister: 1), 5)
        XCTAssertEqual(ToolEngine.trickleHours(forMister: 2), 3); XCTAssertEqual(ToolEngine.trickleCap(forMister: 2), 6)
        XCTAssertEqual(ToolEngine.trickleHours(forMister: 3), 2); XCTAssertEqual(ToolEngine.trickleCap(forMister: 3), 7)
        // No mister yet: the plain free drops from Economy.
        XCTAssertEqual(ToolEngine.trickleHours(forMister: 0), eco.trickleHours); XCTAssertEqual(ToolEngine.trickleCap(forMister: 0), eco.trickleCap)
        XCTAssertEqual(ToolEngine.trickleHours(forMister: 1), eco.trickleHours); XCTAssertEqual(ToolEngine.trickleCap(forMister: 1), eco.trickleCap)
    }

    func testTrickleWithATierThreeMisterGivesADropEveryTwoHoursUpToSeven() {
        let p = profile(water: 0); p.lastTrickleAt = t0
        var inv = ToolInventory(); inv.unlock(.mister); var pts = 150
        XCTAssertTrue(inv.upgrade(.mister, shedPoints: &pts)); XCTAssertTrue(inv.upgrade(.mister, shedPoints: &pts))
        ToolEngine.applyTrickle(p, inventory: inv, now: t0.addingTimeInterval(5 * 3600), economy: eco)
        XCTAssertEqual(p.water, 2)
        ToolEngine.applyTrickle(p, inventory: inv, now: t0.addingTimeInterval(100 * 3600), economy: eco)
        XCTAssertEqual(p.water, 7)
    }

    func testTrickleWithoutAMisterIsUnchanged() {
        let p = profile(water: 0); p.lastTrickleAt = t0
        ToolEngine.applyTrickle(p, inventory: ToolInventory(), now: t0.addingTimeInterval(9 * 3600), economy: eco)
        XCTAssertEqual(p.water, 2)
        ToolEngine.applyTrickle(p, inventory: ToolInventory(), now: t0.addingTimeInterval(100 * 3600), economy: eco)
        XCTAssertEqual(p.water, 5)
    }

    func testMisterNeverChangesTheDailyDrinksOrTheBankCap() {
        var inv = ToolInventory(); inv.unlock(.mister); var pts = 150
        _ = inv.upgrade(.mister, shedPoints: &pts); _ = inv.upgrade(.mister, shedPoints: &pts)
        let tuned = ToolEngine.trickleEconomy(eco, inventory: inv)
        XCTAssertEqual(tuned.waterPerDay, eco.waterPerDay)
        XCTAssertEqual(tuned.waterBankCap, eco.waterBankCap)
        XCTAssertEqual(tuned.waterGrowth, eco.waterGrowth)
    }

    func testShedToolLinesSayWhatEachTierDoes() {
        XCTAssertEqual(ShedCopy.effect(.mister, tier: 1), "A free drop every 4 hours")
        XCTAssertEqual(ShedCopy.effect(.mister, tier: 2), "A free drop every 3 hours")
        XCTAssertEqual(ShedCopy.effect(.mister, tier: 3), "A free drop every 2 hours")
        XCTAssertEqual(ShedCopy.effect(.net, tier: 1), "Small catch circle")
        XCTAssertEqual(ShedCopy.effect(.net, tier: 3), "Biggest catch circle")
        XCTAssertEqual(ShedCopy.effect(.can, tier: 1), "Waters 1 plant per tap")
        XCTAssertEqual(ShedCopy.effect(.can, tier: 2), "Waters 2 plants per tap")
        XCTAssertEqual(ShedCopy.upgradedLine(.trowel, tier: 2), "Now: bigger soil boost.")
    }

    func testFoundToolsDropTheFindItLine() {
        XCTAssertEqual(ShedCopy.blurb(.mister, owned: false), "Find at garden level 1")
        XCTAssertEqual(ShedCopy.blurb(.shears, owned: false), "Find at garden level 2")
        for tool in ToolID.allCases { XCTAssertFalse(ShedCopy.blurb(tool, owned: true).contains("Find"), "\(tool)") }
    }

    func testToolTileLabelsSayTheTierAndEffect() {
        XCTAssertEqual(ShedCopy.tileLabel(.net, tier: 2, quiet: false, ready: true), "Butterfly net. Tier 2 of 3. Bigger catch circle. Upgrade ready.")
        XCTAssertEqual(ShedCopy.tileLabel(.shears, tier: 0, quiet: false, ready: false), "Shears. Find at garden level 2.")
        XCTAssertFalse(ShedCopy.tileLabel(.can, tier: 2, quiet: true, ready: false).contains("Tier"), "Quiet Garden shows no tiers or numbers")
    }

    func testQuietGardenHidesUpgradesAndPrices() {
        XCTAssertFalse(ShedPolicy.showsUpgrades(quietGarden: true))
        XCTAssertTrue(ShedPolicy.showsUpgrades(quietGarden: false))
    }

    func testHowFarLineCountsThePointsToGo() {
        XCTAssertEqual(ShedCopy.toGo(have: 16, cost: 30), "14 more to go")
        XCTAssertEqual(ShedCopy.toGo(have: 29, cost: 30), "1 more to go")
        XCTAssertEqual(ShedCopy.toGo(have: 44, cost: 30), "You have enough points!")
        XCTAssertEqual(ShedCopy.progress(have: 44, cost: 120), "44 of 120 points")
        XCTAssertEqual(ShedCopy.upgradeButton(cost: 30), "Upgrade for 30 shed points")
    }

    func testShedCopyIsGentle() {
        for line in ShedCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
    }
}

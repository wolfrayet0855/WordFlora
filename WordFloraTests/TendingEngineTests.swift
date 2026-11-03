import XCTest
@testable import WordFlora

final class TendingEngineTests: XCTestCase {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    let eco = Economy.default

    func plant(level: Int = 1) -> PlantCollectible {
        PlantCollectible(name: "Rose", botanicalName: "Rosa", botanicalFact: "f", level: level, imageName: "plant_rose")
    }
    func profile(water: Int = 5, soil: Int = 3) -> PlayerProfile {
        let p = PlayerProfile(); p.water = water; p.soil = soil; p.lastTrickleAt = t0; return p
    }
    func later(_ hours: Double, from d: Date? = nil) -> Date { (d ?? t0).addingTimeInterval(hours * 3600) }

    // MARK: water
    func testWaterConsumesOneDropAndAddsGrowth() {
        let p = plant(), pr = profile(water: 3)
        let r = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(pr.water, 2); XCTAssertEqual(p.growthPoints, 4)
        XCTAssertEqual(p.hydration, 1.0); XCTAssertEqual(p.lastTendedAt, t0)
    }

    func testWaterWithNoDropsDoesNothing() {
        let p = plant(), pr = profile(water: 0)
        let r = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertFalse(r.applied); XCTAssertEqual(r.reason, .noWater); XCTAssertEqual(p.growthPoints, 0)
    }

    func testDailyAbsorbCapPerPlantAndNoDropSpentWhenFull() {
        let p = plant(), pr = profile(water: 5)
        for _ in 0..<5 { _ = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco) }
        XCTAssertEqual(p.growthPoints, 10)          // 4 + 4 + 2 (capped)
        XCTAssertEqual(pr.water, 2)                 // only 3 drops were spent
        let r = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertEqual(r.reason, .fullForToday)
    }

    func testAbsorbCapResetsNextDay() {
        let p = plant(), pr = profile(water: 5)
        for _ in 0..<3 { _ = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco) }
        let next = later(24)
        let r = TendingEngine.water(p, profile: pr, now: next, calendar: cal, economy: eco)
        XCTAssertTrue(r.applied); XCTAssertEqual(p.growthPoints, 14)
    }

    // MARK: soil
    func testSoilSpendsAScoopAndRaisesRichness() {
        let p = plant(), pr = profile(soil: 2)
        let r = TendingEngine.addSoil(p, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(pr.soil, 1)
        XCTAssertEqual(p.growthPoints, 10)          // 12 capped by the daily absorb limit
        XCTAssertGreaterThan(p.soilRichness, 0)
        XCTAssertNotNil(p.soilBoostUntil)
    }

    func testSoilBoostMultipliesWaterForThreeDays() {
        let p = plant(), pr = profile(water: 5, soil: 1)
        _ = TendingEngine.addSoil(p, profile: pr, now: t0, calendar: cal, economy: eco)
        let day2 = later(24)
        _ = TendingEngine.water(p, profile: pr, now: day2, calendar: cal, economy: eco)
        XCTAssertEqual(p.growthPoints, 10 + 6)       // 4 x 1.5
        let day5 = later(24 * 4)
        let before = p.growthPoints
        _ = TendingEngine.water(p, profile: pr, now: day5, calendar: cal, economy: eco)
        XCTAssertEqual(p.growthPoints, before + 4)   // boost expired
    }

    func testSoilWithNoScoopsDoesNothing() {
        let p = plant(), pr = profile(soil: 0)
        XCTAssertEqual(TendingEngine.addSoil(p, profile: pr, now: t0, calendar: cal, economy: eco).reason, .noSoil)
    }

    // MARK: sun
    func testSunIsFreeAndOncePerDay() {
        let p = plant(), pr = profile()
        XCTAssertTrue(TendingEngine.sun(p, profile: pr, now: t0, calendar: cal, economy: eco).applied)
        XCTAssertEqual(p.growthPoints, 2)
        XCTAssertEqual(TendingEngine.sun(p, profile: pr, now: later(1), calendar: cal, economy: eco).reason, .alreadyDoneToday)
        XCTAssertTrue(TendingEngine.sun(p, profile: pr, now: later(25), calendar: cal, economy: eco).applied)
    }

    // MARK: stages
    func testStageThresholdsLevelOne() {
        XCTAssertEqual(TendingEngine.stage(forGrowth: 0, level: 1), 0)
        XCTAssertEqual(TendingEngine.stage(forGrowth: 10, level: 1), 0)   // 6% of 180 = 10.8
        XCTAssertEqual(TendingEngine.stage(forGrowth: 11, level: 1), 1)
        XCTAssertEqual(TendingEngine.stage(forGrowth: 40, level: 1), 2)   // 22% = 39.6
        XCTAssertEqual(TendingEngine.stage(forGrowth: 90, level: 1), 3)
        XCTAssertEqual(TendingEngine.stage(forGrowth: 180, level: 1), 4)
    }

    func testHigherLevelsCostMore() {
        XCTAssertEqual(TendingEngine.stage(forGrowth: 180, level: 5), 3)  // level 5 needs 252
        XCTAssertEqual(TendingEngine.stage(forGrowth: 252, level: 5), 4)
    }

    func testStageUpIsReportedAndNeverRegresses() {
        let p = plant(), pr = profile()
        p.growthPoints = 8
        let r = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco)
        XCTAssertTrue(r.stageUp); XCTAssertEqual(p.stage, 1)
        p.stage = 3; p.growthPoints = 0
        _ = TendingEngine.water(p, profile: pr, now: later(24), calendar: cal, economy: eco)
        XCTAssertEqual(p.stage, 3)
    }

    // MARK: thirsty look
    func testThirstyAfterFortyEightHoursAndClearedByWater() {
        let p = plant(), pr = profile()
        p.lastTendedAt = t0
        XCTAssertFalse(TendingEngine.isThirsty(p, now: later(47.9), calm: false))
        XCTAssertTrue(TendingEngine.isThirsty(p, now: later(48), calm: false))
        _ = TendingEngine.water(p, profile: pr, now: later(60), calendar: cal, economy: eco)
        XCTAssertFalse(TendingEngine.isThirsty(p, now: later(61), calm: false))
    }

    func testCalmModeNeverShowsThirstyAndNeverTendedPlantIsNotThirsty() {
        let p = plant(); p.lastTendedAt = t0
        XCTAssertFalse(TendingEngine.isThirsty(p, now: later(500), calm: true))
        XCTAssertFalse(TendingEngine.isThirsty(plant(), now: later(500), calm: false))
    }

    func testBeingThirstyNeverReducesStageOrGrowth() {
        let p = plant(); p.stage = 2; p.growthPoints = 50; p.lastTendedAt = t0
        _ = TendingEngine.isThirsty(p, now: later(1000), calm: false)
        XCTAssertEqual(p.stage, 2); XCTAssertEqual(p.growthPoints, 50)
    }

    // MARK: free trickle
    func testTrickleGivesOneDropPerFourHoursUpToFive() {
        let pr = profile(water: 0)
        TendingEngine.applyTrickle(pr, now: later(3.9), economy: eco)
        XCTAssertEqual(pr.water, 0)
        TendingEngine.applyTrickle(pr, now: later(9), economy: eco)
        XCTAssertEqual(pr.water, 2)
        XCTAssertEqual(pr.lastTrickleAt, later(8))                       // remainder preserved
        TendingEngine.applyTrickle(pr, now: later(100), economy: eco)
        XCTAssertEqual(pr.water, 5)
    }

    func testTrickleDoesNotStackAboveFiveAndRestartsClock() {
        let pr = profile(water: 12)
        TendingEngine.applyTrickle(pr, now: later(40), economy: eco)
        XCTAssertEqual(pr.water, 12)
        XCTAssertEqual(pr.lastTrickleAt, later(40))
    }

    // MARK: quiet garden
    func testQuietGardenSpendsAndEarnsNothing() {
        let p = plant(), pr = profile(water: 0, soil: 0)
        let r = TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco, quiet: true)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(pr.water, 0); XCTAssertEqual(p.growthPoints, 0)
        XCTAssertTrue(TendingEngine.addSoil(p, profile: pr, now: t0, calendar: cal, economy: eco, quiet: true).applied)
        XCTAssertEqual(pr.soil, 0)
        for _ in 0..<10 { XCTAssertTrue(TendingEngine.water(p, profile: pr, now: t0, calendar: cal, economy: eco, quiet: true).applied) }
    }
}

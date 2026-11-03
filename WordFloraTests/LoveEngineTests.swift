import XCTest
@testable import WordFlora

final class LoveEngineTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    func hours(_ h: Double) -> Date { t0.addingTimeInterval(h * 3600) }

    func testFreshlyLovedPlantHasAllPetalsAndNoRain() {
        let s = LoveEngine.state(lastLoved: t0, now: hours(1), exempt: false)
        XCTAssertEqual(s.petalsLeft, 5); XCTAssertFalse(s.raining); XCTAssertFalse(s.isSeed)
    }
    func testAfterADayWithoutLoveItRainsAndAPetalFalls() {
        let s = LoveEngine.state(lastLoved: t0, now: hours(24), exempt: false)
        XCTAssertEqual(s.petalsLeft, 4); XCTAssertTrue(s.raining)
    }
    func testEachFurtherDayLosesAnotherPetal() {
        XCTAssertEqual(LoveEngine.state(lastLoved: t0, now: hours(48), exempt: false).petalsLeft, 3)
        XCTAssertEqual(LoveEngine.state(lastLoved: t0, now: hours(96), exempt: false).petalsLeft, 1)
    }
    func testAllPetalsLostMeansASeedInAPot() {
        let s = LoveEngine.state(lastLoved: t0, now: hours(120), exempt: false)
        XCTAssertEqual(s.petalsLeft, 0); XCTAssertTrue(s.isSeed)
        XCTAssertTrue(LoveEngine.state(lastLoved: t0, now: hours(24 * 40), exempt: false).isSeed)
    }
    func testQuietGardenAndCalmModeAreExempt() {
        let s = LoveEngine.state(lastLoved: t0, now: hours(24 * 30), exempt: true)
        XCTAssertEqual(s.petalsLeft, 5); XCTAssertFalse(s.raining); XCTAssertFalse(s.isSeed)
    }
    func testNeverLovedOrClockGoingBackwardsIsHarmless() {
        XCTAssertEqual(LoveEngine.state(lastLoved: nil, now: t0, exempt: false).petalsLeft, 5)
        XCTAssertEqual(LoveEngine.state(lastLoved: hours(10), now: t0, exempt: false).petalsLeft, 5)
    }
    func testCopyIsGentleAndSafe() {
        for line in [LoveEngine.rainLine(name: "Rose"), LoveEngine.seedLine(name: "Rose"), LoveEngine.wakeLine(name: "Rose")] {
            XCTAssertEqual(CopySafety.check(line), [], line)
        }
    }
}

@MainActor
final class LoveInAppTests: XCTestCase {
    func makeApp(now: @escaping () -> Date, quiet: Bool = false) throws -> AppModel {
        let suite = UserDefaults(suiteName: "wf-love-\(UUID().uuidString)")!
        let s = AppSettings(defaults: suite); s.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: try SharedContainer.make(inMemory: true), settings: s, bank: bank, now: now, notifications: ReminderTests.FakeCenter())
    }
    func testLoveStampsThePlantAndTendingCountsAsLove() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = app.plants().first!; p.earnedCount = 1; app.profile?.water = 3
        app.love(p)
        XCTAssertEqual(p.lastLovedAt, clock)
        clock = clock.addingTimeInterval(3600)
        _ = app.tend(.water, plant: p)
        XCTAssertEqual(p.lastLovedAt, clock)
    }
    func testASeedMustBeWokenBeforeItCanBeTended() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        let p = app.plants().first!; p.earnedCount = 1; app.profile?.water = 3
        app.love(p)
        clock = clock.addingTimeInterval(6 * 86_400)
        XCTAssertTrue(app.loveState(p).isSeed)
        let r = app.tend(.water, plant: p)
        XCTAssertFalse(r.applied); XCTAssertEqual(app.profile?.water, 3)
        app.wake(p)
        XCTAssertFalse(app.loveState(p).isSeed)
        XCTAssertTrue(app.tend(.water, plant: p).applied)
        XCTAssertEqual(p.earnedCount, 1)            // nothing earned is ever lost
    }
    func testQuietGardenNeverRainsOrWilts() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }, quiet: true)
        let p = app.plants().first!; p.earnedCount = 1; app.love(p)
        clock = clock.addingTimeInterval(30 * 86_400)
        XCTAssertFalse(app.loveState(p).isSeed); XCTAssertEqual(app.loveState(p).petalsLeft, 5)
    }
}

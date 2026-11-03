import XCTest
@testable import WordFlora

@MainActor
final class WelcomeBackTests: XCTestCase {
    let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    func days(_ n: Int) -> Date { t0.addingTimeInterval(Double(n) * 86_400) }

    func testShowsAfterThreeOrMoreDaysAway() {
        XCTAssertFalse(WelcomeBack.shouldShow(lastOpened: t0, now: days(2), calendar: cal))
        XCTAssertTrue(WelcomeBack.shouldShow(lastOpened: t0, now: days(3), calendar: cal))
        XCTAssertTrue(WelcomeBack.shouldShow(lastOpened: t0, now: days(40), calendar: cal))
    }
    func testNeverOnAFirstLaunchOrAClockGoingBackwards() {
        XCTAssertFalse(WelcomeBack.shouldShow(lastOpened: nil, now: t0, calendar: cal))
        XCTAssertFalse(WelcomeBack.shouldShow(lastOpened: days(10), now: t0, calendar: cal))
    }
    func testCopyIsCalmAndSafe() {
        for line in WelcomeBack.lines { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertFalse(WelcomeBack.lines.isEmpty)
    }
    func testAppShowsTheCardOnceAfterAbsenceThenRemembersTheVisit() throws {
        let suite = UserDefaults(suiteName: "wf-wb-\(UUID().uuidString)")!
        func launch(at d: Date) throws -> AppModel {
            let s = AppSettings(defaults: suite); s.onboardingComplete = true
            let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
            return AppModel(container: try SharedContainer.make(inMemory: true), settings: s, bank: bank, now: { d }, notifications: ReminderTests.FakeCenter())
        }
        XCTAssertFalse(try launch(at: t0).showWelcomeBack)            // first launch
        XCTAssertFalse(try launch(at: days(1)).showWelcomeBack)
        let back = try launch(at: days(6))
        XCTAssertTrue(back.showWelcomeBack)
        back.dismissWelcomeBack(); XCTAssertFalse(back.showWelcomeBack)
        XCTAssertFalse(try launch(at: days(7)).showWelcomeBack)       // the earlier visit was recorded
    }
}

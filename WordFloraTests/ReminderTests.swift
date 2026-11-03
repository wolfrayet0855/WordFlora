import XCTest
@testable import WordFlora

@MainActor
final class ReminderTests: XCTestCase {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour, minute: minute))!
    }

    // MARK: policy
    func testSchedulesAtThePreferredTimeForTheNextFewDays() {
        let d = ReminderPolicy.nextDates(now: at(10, 9), calendar: cal, hour: 17, minute: 30, lastOpened: at(10, 8))
        XCTAssertEqual(d, [at(10, 17, 30), at(11, 17, 30), at(12, 17, 30)])
    }

    func testStartsTomorrowWhenTodaysTimeHasPassed() {
        let d = ReminderPolicy.nextDates(now: at(10, 18), calendar: cal, hour: 17, minute: 30, lastOpened: at(10, 17, 45))
        XCTAssertEqual(d.first, at(11, 17, 30))
    }

    func testNeverSchedulesBeyondThreeDaysWithoutAVisit() {
        let d = ReminderPolicy.nextDates(now: at(12, 9), calendar: cal, hour: 17, minute: 0, lastOpened: at(10, 9))
        XCTAssertEqual(d, [at(12, 17), at(13, 17)])                 // days 2 and 3 since the last visit; nothing later
        XCTAssertEqual(ReminderPolicy.nextDates(now: at(14, 9), calendar: cal, hour: 17, minute: 0, lastOpened: at(10, 9)), [])
    }

    func testQuietHoursAreRespected() {
        XCTAssertEqual(ReminderPolicy.nextDates(now: at(10, 9), calendar: cal, hour: 22, minute: 0, lastOpened: at(10, 8)), [])
        XCTAssertEqual(ReminderPolicy.nextDates(now: at(10, 5), calendar: cal, hour: 7, minute: 30, lastOpened: at(10, 4)), [])
        XCTAssertFalse(ReminderPolicy.nextDates(now: at(10, 5), calendar: cal, hour: 8, minute: 0, lastOpened: at(10, 4)).isEmpty)
    }

    func testAtMostOnePerDayAndAlwaysInTheFuture() {
        let now = at(10, 9)
        let d = ReminderPolicy.nextDates(now: now, calendar: cal, hour: 17, minute: 0, lastOpened: at(10, 8))
        XCTAssertEqual(Set(d.map { cal.startOfDay(for: $0) }).count, d.count)
        XCTAssertTrue(d.allSatisfy { $0 > now })
    }

    func testWorksAcrossDaylightSavingChange() {
        var ny = Calendar(identifier: .gregorian); ny.timeZone = TimeZone(identifier: "America/New_York")!
        let now = ny.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 9))!        // spring forward is Mar 8
        let d = ReminderPolicy.nextDates(now: now, calendar: ny, hour: 17, minute: 0, lastOpened: now)
        XCTAssertEqual(d.map { ny.component(.hour, from: $0) }, [17, 17, 17])
        XCTAssertEqual(d.map { ny.component(.minute, from: $0) }, [0, 0, 0])
    }

    // MARK: copy
    func testAllReminderCopyIsKindAndPassesTheLinter() {
        for kind in ReminderCopy.Kind.allCases {
            for i in 0..<ReminderCopy.variants(for: kind) {
                let m = ReminderCopy.message(kind: kind, variant: i)
                for text in [m.title, m.body] {
                    XCTAssertEqual(CopySafety.check(text), [], text)
                    XCTAssertFalse(text.lowercased().contains("streak")); XCTAssertFalse(text.contains("!!"))
                }
            }
        }
    }

    func testOneBudgetPicksTheDailyBloomWhenItIsStillOpen() {
        XCTAssertEqual(ReminderCopy.kind(dailyBloomDoneToday: false), .dailyBloom)
        XCTAssertEqual(ReminderCopy.kind(dailyBloomDoneToday: true), .tend)
    }

    // MARK: scheduler with a fake notification centre
    final class FakeCenter: NotificationCenterProviding {
        var allow = true; var asked = 0; var scheduled: [(id: String, title: String, body: String, date: Date)] = []; var cleared = 0
        func requestAuthorization() async -> Bool { asked += 1; return allow }
        func schedule(id: String, title: String, body: String, at date: Date) { scheduled.append((id, title, body, date)) }
        func removeAllPending() { cleared += 1; scheduled.removeAll() }
    }

    func testTurningRemindersOnAsksForPermissionOnlyThen() async {
        let fake = FakeCenter()
        let s = ReminderScheduler(center: fake, calendar: cal)
        XCTAssertEqual(fake.asked, 0)
        let ok = await s.enable(now: at(10, 9), hour: 17, minute: 0, lastOpened: at(10, 8), dailyBloomDoneToday: false)
        XCTAssertTrue(ok); XCTAssertEqual(fake.asked, 1); XCTAssertEqual(fake.scheduled.count, 3)
    }

    func testDeniedPermissionSchedulesNothing() async {
        let fake = FakeCenter(); fake.allow = false
        let ok = await ReminderScheduler(center: fake, calendar: cal).enable(now: at(10, 9), hour: 17, minute: 0, lastOpened: at(10, 8), dailyBloomDoneToday: false)
        XCTAssertFalse(ok); XCTAssertTrue(fake.scheduled.isEmpty)
    }

    func testDisablingAndRefreshingKeepThePlanTidy() async {
        let fake = FakeCenter()
        let s = ReminderScheduler(center: fake, calendar: cal)
        _ = await s.enable(now: at(10, 9), hour: 17, minute: 0, lastOpened: at(10, 8), dailyBloomDoneToday: false)
        s.refresh(now: at(11, 9), hour: 17, minute: 0, lastOpened: at(11, 8), dailyBloomDoneToday: true)
        XCTAssertEqual(fake.scheduled.count, 3)                       // rebuilt from the new visit, never doubled
        s.disable()
        XCTAssertTrue(fake.scheduled.isEmpty)
    }
}

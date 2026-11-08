import XCTest
import SwiftData
@testable import WordFlora

/// The weekly garden note (docs/pm/engagement-quick-wins.md, task A).
@MainActor
final class WeeklyNoteTests: XCTestCase {
    let london = TimeZone(identifier: "Europe/London")!
    var cal: Calendar { WeeklyNote.calendar(timeZone: london) }

    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0, tz: TimeZone? = nil) -> Date {
        var c = WeeklyNote.calendar(timeZone: tz ?? london)
        c.timeZone = tz ?? london
        return c.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    /// Monday 2026-11-09, noon: the past week is Mon 2 Nov to Sun 8 Nov.
    var monday: Date { date(2026, 11, 9) }

    func context(now: Date? = nil, created: Date? = nil, seen: Int = 0, other: Bool = false, nudge: Bool = false,
                 quiet: Bool = false, onboarded: Bool = true) -> WeeklyNote.Context {
        let n = now ?? monday
        return WeeklyNote.Context(now: n, calendar: cal, onboarded: onboarded,
                                  gardenCreatedAt: created ?? cal.date(byAdding: .day, value: -30, to: n)!,
                                  seenWeek: seen, otherCardShowing: other, nudgeShowing: nudge, quietGarden: quiet)
    }

    func win(_ d: Date, daily: Bool = false, plant: String? = nil) -> WeeklyNote.Round {
        WeeklyNote.Round(date: d, won: true, isDaily: daily, plantEarned: plant)
    }

    // MARK: Week key

    func testWeekKeyTurnsOverAtMondayMidnight() {
        let sunday = date(2026, 11, 8, 23, 59)
        let mondayMidnight = date(2026, 11, 9, 0, 0)
        XCTAssertNotEqual(WeeklyNote.weekKey(sunday, calendar: cal), WeeklyNote.weekKey(mondayMidnight, calendar: cal))
        XCTAssertEqual(WeeklyNote.weekKey(mondayMidnight, calendar: cal) - WeeklyNote.weekKey(sunday, calendar: cal), 7)
        XCTAssertEqual(WeeklyNote.weekKey(date(2026, 11, 15, 23, 59), calendar: cal), WeeklyNote.weekKey(mondayMidnight, calendar: cal))
    }

    func testADaylightSavingWeekIsAWholeWeek() {
        // UK clocks went back on Sunday 25 Oct 2026: that week has 169 hours.
        let after = date(2026, 10, 26, 9)
        let week = WeeklyNote.pastWeek(after, calendar: cal)
        XCTAssertEqual(week.lowerBound, date(2026, 10, 19, 0, 0))
        XCTAssertEqual(week.upperBound, date(2026, 10, 26, 0, 0))
        XCTAssertEqual(week.upperBound.timeIntervalSince(week.lowerBound), 7 * 86_400 + 3_600)
        XCTAssertEqual(WeeklyNote.weekKey(date(2026, 10, 25, 23, 30), calendar: cal),
                       WeeklyNote.weekKey(date(2026, 10, 19, 0, 30), calendar: cal), "the same week across the change")
    }

    /// New Year 2026/27: Mon 28 Dec 2026 starts a week that ends in 2027 (ISO week 53); Mon 4 Jan 2027 starts the next.
    func testWeekKeyAcrossNewYear() {
        let dec28 = WeeklyNote.weekKey(date(2026, 12, 28, 0, 0), calendar: cal)
        for d in [date(2026, 12, 31, 23, 59), date(2027, 1, 1, 0, 0), date(2027, 1, 3, 23, 59)] {
            XCTAssertEqual(WeeklyNote.weekKey(d, calendar: cal), dec28, "\(d) is in the week of Mon 28 Dec")
        }
        let jan4 = WeeklyNote.weekKey(date(2027, 1, 4, 0, 0), calendar: cal)
        XCTAssertEqual(jan4 - dec28, 7)
        XCTAssertEqual(WeeklyNote.weekKey(date(2027, 1, 5), calendar: cal), jan4)
        let past = WeeklyNote.pastWeek(date(2027, 1, 5), calendar: cal)
        XCTAssertEqual(past.lowerBound, date(2026, 12, 28, 0, 0))
        XCTAssertEqual(past.upperBound, date(2027, 1, 4, 0, 0))
        // A win on New Year's Day counts in the week shown on Mon 4 Jan.
        let s = WeeklyNote.summary(rounds: [win(date(2027, 1, 1, 0, 30)), win(date(2026, 12, 27, 23, 0))], friendsSeenAt: [:],
                                   now: date(2027, 1, 4, 9), calendar: cal)
        XCTAssertEqual(s.words, 1)
    }

    /// The New Year week on summer time (Sydney) keys the same as in London, and a spring-forward week (London,
    /// 29 Mar 2026, 167 hours) is still one whole week.
    func testWeekKeyAcrossYearEndAndSpringForward() {
        let sydney = TimeZone(identifier: "Australia/Sydney")!
        let syd = WeeklyNote.calendar(timeZone: sydney)
        XCTAssertEqual(WeeklyNote.weekKey(date(2027, 1, 3, 23, 59, tz: sydney), calendar: syd),
                       WeeklyNote.weekKey(date(2026, 12, 28, 0, 1, tz: sydney), calendar: syd))
        XCTAssertEqual(WeeklyNote.weekKey(date(2027, 1, 1, 12, tz: sydney), calendar: syd),
                       WeeklyNote.weekKey(date(2027, 1, 1, 12), calendar: cal), "the same local week key in Sydney and London")
        let week = WeeklyNote.pastWeek(date(2026, 3, 30, 9), calendar: cal)
        XCTAssertEqual(week.lowerBound, date(2026, 3, 23, 0, 0))
        XCTAssertEqual(week.upperBound.timeIntervalSince(week.lowerBound), 7 * 86_400 - 3_600)
        XCTAssertEqual(WeeklyNote.weekKey(date(2026, 3, 29, 23, 0), calendar: cal),
                       WeeklyNote.weekKey(date(2026, 3, 23, 0, 30), calendar: cal))
    }

    func testATimeZoneChangeKeepsTheSameLocalWeek() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let ny = TimeZone(identifier: "America/New_York")!
        let inTokyo = WeeklyNote.weekKey(date(2026, 11, 11, 12, tz: tokyo), calendar: WeeklyNote.calendar(timeZone: tokyo))
        let inNY = WeeklyNote.weekKey(date(2026, 11, 11, 12, tz: ny), calendar: WeeklyNote.calendar(timeZone: ny))
        XCTAssertEqual(inTokyo, inNY, "Wednesday is in the same local week wherever the player is")
        XCTAssertEqual(inTokyo, WeeklyNote.weekKey(monday, calendar: cal))
    }

    // MARK: When it shows

    func testGardenSixDaysOldWaitsSevenShows() {
        let s = WeeklyNote.Summary(words: 3, weekKey: 1)
        XCTAssertFalse(WeeklyNote.shouldShow(context(created: date(2026, 11, 3, 18)), summary: s), "6 days")
        XCTAssertTrue(WeeklyNote.shouldShow(context(created: date(2026, 11, 2, 18)), summary: s), "7 days")
    }

    func testNotBeforeOnboardingIsDone() {
        XCTAssertFalse(WeeklyNote.shouldShow(context(onboarded: false), summary: WeeklyNote.Summary(words: 3)))
    }

    func testAnEmptyWeekShowsNoCard() {
        let s = WeeklyNote.summary(rounds: [], friendsSeenAt: [:], now: monday, calendar: cal)
        XCTAssertFalse(s.hasAnything)
        XCTAssertFalse(WeeklyNote.shouldShow(context(), summary: s))
        // A lost round is not a positive item.
        let lost = WeeklyNote.summary(rounds: [WeeklyNote.Round(date: date(2026, 11, 4), won: false, isDaily: false)],
                                      friendsSeenAt: [:], now: monday, calendar: cal)
        XCTAssertFalse(WeeklyNote.shouldShow(context(), summary: lost))
    }

    func testTheSeenWeekStopsASecondShow() {
        let s = WeeklyNote.Summary(words: 3)
        let key = WeeklyNote.weekKey(monday, calendar: cal)
        XCTAssertFalse(WeeklyNote.shouldShow(context(seen: key), summary: s))
        XCTAssertTrue(WeeklyNote.shouldShow(context(seen: key - 7), summary: s))
        XCTAssertFalse(WeeklyNote.shouldShow(context(now: date(2026, 11, 13), seen: key), summary: s), "later the same week")
    }

    func testAWeatherCardOrTheNudgeDefersIt() {
        let s = WeeklyNote.Summary(words: 3)
        XCTAssertFalse(WeeklyNote.shouldShow(context(other: true), summary: s))
        XCTAssertFalse(WeeklyNote.shouldShow(context(nudge: true), summary: s))
        XCTAssertTrue(WeeklyNote.shouldShow(context(now: date(2026, 11, 10)), summary: s), "a later visit that week")
    }

    // MARK: Summary

    func testSummaryCountsThePastWeekOnly() {
        let rounds = [
            win(date(2026, 11, 1, 23, 59)),                                 // the week before
            win(date(2026, 11, 2, 0, 0)), win(date(2026, 11, 4), daily: true), win(date(2026, 11, 8, 23, 59), daily: true),
            WeeklyNote.Round(date: date(2026, 11, 5), won: false, isDaily: true),
            win(date(2026, 11, 9, 0, 0)),                                   // this week
        ]
        let s = WeeklyNote.summary(rounds: rounds, friendsSeenAt: [:], now: monday, calendar: cal)
        XCTAssertEqual(s.words, 3); XCTAssertEqual(s.dailyBlooms, 2)
        XCTAssertEqual(s.weekKey, WeeklyNote.weekKey(monday, calendar: cal))
    }

    func testNewPlantsAreFirstArrivalsInOrderBySpeciesName() {
        let rounds = [
            win(date(2026, 10, 20), plant: "Rose"),                         // found before
            win(date(2026, 11, 5), plant: "Rose"),                          // a hero word again: not new
            win(date(2026, 11, 6), plant: "Clover"), win(date(2026, 11, 3), plant: "Daisy"),
            win(date(2026, 11, 10), plant: "Fern"),                         // this week
        ]
        let s = WeeklyNote.summary(rounds: rounds, friendsSeenAt: [:], now: monday, calendar: cal)
        XCTAssertEqual(s.newPlants, ["Daisy", "Clover"])
    }

    func testFriendsCountVisitorsMetInThePastWeekButNotWeatherStickers() {
        let seen: [String: Date] = ["monarch": date(2026, 11, 3), "ladybug": date(2026, 11, 7), "luna": date(2026, 10, 30),
                                    "honeybee": date(2026, 11, 9, 8), WeatherSticker.rainbow.id: date(2026, 11, 4)]
        let s = WeeklyNote.summary(rounds: [], friendsSeenAt: seen, now: monday, calendar: cal)
        XCTAssertEqual(s.friends, 2)
        XCTAssertTrue(WeeklyNote.shouldShow(context(), summary: s), "friends alone are something to say")
    }

    // MARK: Copy

    func testRowsHideZeroesAndUseSingularAndPlural() {
        XCTAssertEqual(WeeklyNoteCopy.rows(WeeklyNote.Summary(words: 1, dailyBlooms: 1, newPlants: ["Daisy"], friends: 1), quiet: false),
                       ["You grew 1 word.", "You solved 1 Daily Bloom.", "New plant: Daisy.", "You said hello to 1 friend."])
        XCTAssertEqual(WeeklyNoteCopy.rows(WeeklyNote.Summary(words: 12, dailyBlooms: 4, newPlants: ["Daisy", "Clover"], friends: 3), quiet: false),
                       ["You grew 12 words.", "You solved 4 Daily Blooms.", "New plants: Daisy and Clover.", "You said hello to 3 friends."])
        XCTAssertEqual(WeeklyNoteCopy.rows(WeeklyNote.Summary(words: 5), quiet: false), ["You grew 5 words."])
    }

    func testPlantListsSayAndMoreAfterThree() {
        XCTAssertEqual(WeeklyNoteCopy.plants(["Daisy", "Clover", "Fern"]), "New plants: Daisy, Clover and Fern.")
        XCTAssertEqual(WeeklyNoteCopy.plants(["Daisy", "Clover", "Fern", "Rose", "Mint"]), "New plants: Daisy, Clover, Fern and 2 more.")
        XCTAssertEqual(WeeklyNoteCopy.plants(["Daisy", "Clover", "Fern", "Rose"]), "New plants: Daisy, Clover, Fern and 1 more.")
    }

    func testQuietGardenShowsNamesOnlyAndNoCardWithoutPlants() {
        let s = WeeklyNote.Summary(words: 12, dailyBlooms: 4, newPlants: ["Daisy", "Clover"], friends: 3)
        XCTAssertEqual(WeeklyNoteCopy.rows(s, quiet: true), ["New in your garden: Daisy and Clover."])
        for line in WeeklyNoteCopy.rows(s, quiet: true) { XCTAssertNil(line.rangeOfCharacter(from: .decimalDigits), line) }
        XCTAssertTrue(WeeklyNote.shouldShow(context(quiet: true), summary: s))
        let noPlants = WeeklyNote.Summary(words: 12, friends: 3)
        XCTAssertFalse(WeeklyNote.shouldShow(context(quiet: true), summary: noPlants))
        XCTAssertEqual(WeeklyNoteCopy.rows(noPlants, quiet: true), [])
    }

    func testClosingLineChangesByWeek() {
        let k = WeeklyNote.weekKey(monday, calendar: cal)
        let lines = (0..<3).map { WeeklyNoteCopy.closing(weekKey: k + 7 * $0) }
        XCTAssertEqual(Set(lines).count, 3)
        XCTAssertEqual(WeeklyNoteCopy.closing(weekKey: k), WeeklyNoteCopy.closing(weekKey: k + 21))
    }

    func testVoiceOverLabelReadsTitleThenRows() {
        let s = WeeklyNote.Summary(words: 12, newPlants: ["Daisy", "Clover"], friends: 3)
        XCTAssertTrue(WeeklyNoteCopy.accessibilityLabel(s, quiet: false)
            .hasPrefix("Your week in the garden. You grew 12 words. New plants: Daisy and Clover. You said hello to 3 friends."))
    }

    func testTilesHideZeroesAndUseSingularAndPlural() {
        let all = WeeklyNoteCopy.tiles(WeeklyNote.Summary(words: 12, dailyBlooms: 2, newPlants: ["Daisy", "Clover"], friends: 3), quiet: false)
        XCTAssertEqual(all.map(\.kind), [.words, .plants, .friends], "Daily Blooms count in the words")
        XCTAssertEqual(all.map(\.number), ["12", "2", "3"])
        XCTAssertEqual(all.map(\.label), ["words grown", "new plants", "friends said hello"])
        let one = WeeklyNoteCopy.tiles(WeeklyNote.Summary(words: 1, newPlants: ["Daisy"], friends: 1), quiet: false)
        XCTAssertEqual(one.map(\.label), ["word grown", "new plant", "friend said hello"])
        XCTAssertEqual(WeeklyNoteCopy.tiles(WeeklyNote.Summary(words: 5), quiet: false).map(\.kind), [.words])
        XCTAssertEqual(WeeklyNoteCopy.tiles(WeeklyNote.Summary(friends: 2), quiet: false).map(\.kind), [.friends])
    }

    func testSplashPlantSizesFollowTheCount() {
        XCTAssertEqual(WeeklyCelebrateView.artSide(index: 0, count: 1, size: 140), 140, "one plant at full size")
        XCTAssertEqual(WeeklyCelebrateView.artSide(index: 0, count: 2, size: 140), WeeklyCelebrateView.artSide(index: 1, count: 2, size: 140))
        XCTAssertEqual(WeeklyCelebrateView.artSide(index: 1, count: 3, size: 140), 140, "three: the middle one large")
        XCTAssertLessThan(WeeklyCelebrateView.artSide(index: 0, count: 3, size: 140), 140)
        XCTAssertEqual(WeeklyCelebrateView.artSide(index: 0, count: 3, size: 140), WeeklyCelebrateView.artSide(index: 2, count: 3, size: 140))
    }

    func testQuietGardenTileHasNamesAndNoNumber() {
        let s = WeeklyNote.Summary(words: 9, newPlants: ["Daisy", "Clover"], friends: 4)
        let tiles = WeeklyNoteCopy.tiles(s, quiet: true)
        XCTAssertEqual(tiles.count, 1)
        XCTAssertNil(tiles[0].number)
        XCTAssertEqual(tiles[0].label, "New in your garden: Daisy and Clover")
        let label = WeeklyNoteCopy.accessibilityLabel(s, quiet: true)
        XCTAssertNil(label.rangeOfCharacter(from: .decimalDigits), label)
        XCTAssertEqual(WeeklyNoteCopy.tiles(WeeklyNote.Summary(words: 9), quiet: true), [])
    }

    func testShareAllowedPerAgeBandAndNeverInQuietGarden() {
        let table: [(AgeBand?, Bool)] = [(nil, false), (.under13, false), (.thirteenPlus, true), (.eighteenPlus, true)]
        for (band, allowed) in table {
            XCTAssertEqual(WeeklyNote.shareAllowed(ageBand: band, quietGarden: false), allowed, "\(String(describing: band))")
            XCTAssertFalse(WeeklyNote.shareAllowed(ageBand: band, quietGarden: true))
        }
    }

    func testEveryStringPassesCopySafety() {
        let names = ["Daisy", "Lady's Slipper Orchid", "Rainbow Eucalyptus", "Monkey Puzzle Tree", "Dragon Blood Tree", "Giant Water Lily"]
        var lines = [WeeklyNoteCopy.title, WeeklyNoteCopy.celebrate, WeeklyNoteCopy.celebrateHint, WeeklyNoteCopy.celebrateTitle,
                     WeeklyNoteCopy.celebrateLine, WeeklyNoteCopy.celebrateDone, WeeklyNoteCopy.share, WeeklyNoteCopy.shareHint,
                     WeeklyNoteCopy.caption, WeeklyNoteCopy.shareHeader, WeeklyNoteCopy.tagline] + WeeklyNoteCopy.closings
        lines.append(WeeklyNoteCopy.quietPlantsLabel)
        for n in 0...99 {
            lines += [WeeklyNoteCopy.words(n), WeeklyNoteCopy.daily(n), WeeklyNoteCopy.friends(n),
                      WeeklyNoteCopy.wordsLabel(n), WeeklyNoteCopy.plantsLabel(n), WeeklyNoteCopy.friendsLabel(n)]
        }
        for k in 1...names.count - 1 { lines += [WeeklyNoteCopy.plants(Array(names.prefix(k))), WeeklyNoteCopy.quietPlants(Array(names.prefix(k)))] }
        for line in lines { XCTAssertEqual(CopySafety.check(line), [], line) }
    }

    // MARK: Through the app

    func makeApp(now: Date) throws -> (AppModel, UserDefaults) {
        let container = try SharedContainer.make(inMemory: true)
        let suite = UserDefaults(suiteName: "wf-tests-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: suite)
        settings.onboardingComplete = true
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: { now }, notifications: ReminderTests.FakeCenter())
        return (app, suite)
    }

    func testTheAppShowsTheNoteOnceAndRemembersTheWeek() throws {
        let now = Date.now
        let (app, suite) = try makeApp(now: now)
        let c = WeeklyNote.calendar()
        let week = WeeklyNote.pastWeek(now, calendar: c)
        app.profile?.createdAt = c.date(byAdding: .day, value: -20, to: now)!
        let midWeek = c.date(byAdding: .day, value: 2, to: week.lowerBound)!
        app.context.insert(GameRecord(wordGuessed: "ROSE", triviaQuestion: "", won: true, petalsRemaining: 5, plantEarned: "Rose", level: 1, date: midWeek))
        try app.context.save()

        XCTAssertNil(app.dueWeeklyNote(otherCardShowing: true), "the weather card holds it")
        let note = try XCTUnwrap(app.dueWeeklyNote(otherCardShowing: false))
        XCTAssertEqual(note.words, 1); XCTAssertEqual(note.newPlants, ["Rose"])
        XCTAssertEqual(app.settings.weeklyNoteSeenWeek, 0, "not used up until the card has been on screen")
        XCTAssertNotNil(app.dueWeeklyNote(otherCardShowing: false), "a launch onto a plant leaves it for the next Home visit")
        app.markWeeklyNoteSeen(note.weekKey)
        XCTAssertNil(app.dueWeeklyNote(otherCardShowing: false), "once a week")
        XCTAssertEqual(AppSettings(defaults: suite).weeklyNoteSeenWeek, WeeklyNote.weekKey(now, calendar: c), "kept across launches")
    }

    func testNoNoteForAYoungGarden() throws {
        let now = Date.now
        let (app, _) = try makeApp(now: now)
        let c = WeeklyNote.calendar()
        app.context.insert(GameRecord(wordGuessed: "ROSE", triviaQuestion: "", won: true, petalsRemaining: 5, plantEarned: nil, level: 1,
                                      date: c.date(byAdding: .day, value: 1, to: WeeklyNote.pastWeek(now, calendar: c).lowerBound)!))
        app.profile?.createdAt = c.date(byAdding: .day, value: -3, to: now)!
        XCTAssertNil(app.dueWeeklyNote(otherCardShowing: false))
        XCTAssertEqual(app.settings.weeklyNoteSeenWeek, 0, "nothing shown, nothing recorded")
    }
}

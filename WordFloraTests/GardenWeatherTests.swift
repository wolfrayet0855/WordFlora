import XCTest
import SwiftData
@testable import WordFlora

// Garden weather outside the plant page: the setting and its defaults, the Home chip, forecast card and event banner,
// the widget line, the forecast reminder sharing the one daily slot, Wild Weather's opt-in, and the app wiring
// (docs/pm/endgame-and-events-spec.md sections 3.2, 3.4, 3.8, 4.2, 4.5; tickets E-5, E-10, E-12).

/// A date at `hour` on weather day `day` in the current time zone (the same calendar `WeatherDay.key` uses).
func weatherDate(day: Int, hour: Int = 9) -> Date {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = .current
    let epoch = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    let d = cal.date(byAdding: .day, value: day, to: epoch)!
    return cal.date(bySettingHour: hour, minute: 0, second: 0, of: d)!
}

/// A seed and start day with a known event, found from the engine itself.
struct KnownWeather {
    let seed: Int64 = 424_242
    let startDay = 300
    let event: (day: Int, kind: WeatherKind)
    init() { event = WeatherEngine.events(from: 300, through: 600, seed: 424_242, startDay: 300).first! }
}

// MARK: The setting and its defaults

final class GardenWeatherSettingTests: XCTestCase {
    func fresh() -> AppSettings { AppSettings(defaults: UserDefaults(suiteName: "wf-gw-\(UUID().uuidString)")!) }

    /// Owner, 2026-11-05: the one Calm toggle decides. Calm on = weather off and hidden; Calm off = weather at any age.
    /// Under 13 starts in Calm, so weather starts off for them.
    func testOnByDefaultWhenCalmIsOffAndOffInCalm() {
        XCTAssertTrue(GardenWeather.defaultOn(calmMode: false))
        XCTAssertFalse(GardenWeather.defaultOn(calmMode: true))

        let adult = fresh(); adult.applyAgeDefaults(.eighteenPlus)
        XCTAssertTrue(adult.gardenWeather)
        let teen = fresh(); teen.applyAgeDefaults(.thirteenPlus)
        XCTAssertTrue(teen.gardenWeather)
        let young = fresh(); young.applyAgeDefaults(.under13)
        XCTAssertFalse(young.gardenWeather, "under 13 starts in Calm")
        young.calmMode = false
        XCTAssertTrue(young.gardenWeather, "Calm off: weather at any age")
        let calmAdult = fresh(); calmAdult.applyAgeDefaults(.eighteenPlus); calmAdult.calmMode = true
        XCTAssertFalse(calmAdult.gardenWeather, "Calm mode turns weather off")
        calmAdult.gardenWeather = true
        XCTAssertFalse(calmAdult.gardenWeather, "no second calm control: Calm wins over a stored choice")
    }

    func testTurningWeatherOffIsKept() {
        let suite = UserDefaults(suiteName: "wf-gw-\(UUID().uuidString)")!
        let s = AppSettings(defaults: suite); s.applyAgeDefaults(.eighteenPlus)
        s.gardenWeather = false
        XCTAssertFalse(s.gardenWeather)
        XCTAssertFalse(AppSettings(defaults: suite).gardenWeather, "stored, so it holds on the next launch")
        XCTAssertFalse(SharedDefaults.gardenWeather(in: suite), "the widget reads the same answer")
    }

    func testTheWidgetReadsTheSameDefaultAsTheApp() {
        for band in [AgeBand.under13, .thirteenPlus, .eighteenPlus] {
            for calm in [false, true] {
                let suite = UserDefaults(suiteName: "wf-gw-\(UUID().uuidString)")!
                let s = AppSettings(defaults: suite); s.applyAgeDefaults(band); s.calmMode = calm
                XCTAssertEqual(SharedDefaults.gardenWeather(in: suite), s.gardenWeather, "\(band) calm \(calm)")
            }
        }
    }

    func testTheForecastReminderIsOffByDefault() {
        let s = fresh(); s.applyAgeDefaults(.eighteenPlus)
        XCTAssertFalse(s.weatherNotify)
    }
}

// MARK: Home, widget and reminder rules (pure)

final class GardenWeatherHomeTests: XCTestCase {
    let known = KnownWeather()

    func ctx(day: Int, found: Int = 6, tends: Int = 3, quiet: Bool = false, calm: Bool = false, on: Bool = true,
             highWater: Int = 0, gatedFromDay: Int = 0) -> GardenWeather.Context {
        GardenWeather.Context(today: day, seed: known.seed, startDay: known.startDay, found: found, tends: tends,
                              quietGarden: quiet, calmMode: calm, weatherOn: on, highWater: highWater, gatedFromDay: gatedFromDay)
    }

    var forecastDay: Int { known.event.day - 1 }
    var kind: WeatherKind { known.event.kind }
    /// A day after the start with no weather and no forecast.
    var quietDay: Int {
        (known.startDay...known.startDay + 400).first {
            WeatherEngine.event(day: $0, seed: known.seed, startDay: known.startDay) == nil
                && WeatherEngine.forecast(day: $0, seed: known.seed, startDay: known.startDay) == nil
        }!
    }

    func testTheDayBeforeShowsTheChipAndTheForecastCard() {
        let h = GardenWeather.home(ctx(day: forecastDay), cardDismissedDay: 0)
        XCTAssertEqual(h.chip, WeatherCopy.forecastChip(kind))
        XCTAssertEqual(h.card, kind)
        XCTAssertNil(h.banner)
        XCTAssertTrue(h.quietsOffers, "no Plus offer or ad beside a forecast")
    }

    func testTheEventDayShowsASoftBannerAndNoForecast() {
        let h = GardenWeather.home(ctx(day: known.event.day), cardDismissedDay: 0)
        XCTAssertEqual(h.banner, kind)
        XCTAssertNil(h.card)
        XCTAssertNil(h.chip)
    }

    func testAnOrdinaryDayShowsNothing() {
        let quiet = quietDay
        XCTAssertEqual(GardenWeather.home(ctx(day: quiet), cardDismissedDay: 0), GardenWeather.Home())
        XCTAssertFalse(GardenWeather.Home().quietsOffers)
    }

    func testGotItHidesTheCardForTheDayButTheChipStays() {
        let h = GardenWeather.home(ctx(day: forecastDay), cardDismissedDay: forecastDay)
        XCTAssertNil(h.card)
        XCTAssertEqual(h.chip, WeatherCopy.forecastChip(kind))
        XCTAssertEqual(GardenWeather.home(ctx(day: forecastDay), cardDismissedDay: forecastDay - 20).card, kind, "an old dismissal does not count")
    }

    func testQuietGardenCalmWeatherOffAndTheGateHideEverything() {
        for c in [ctx(day: forecastDay, quiet: true), ctx(day: forecastDay, calm: true), ctx(day: forecastDay, on: false), ctx(day: forecastDay, found: 4),
                  ctx(day: forecastDay, tends: 1), ctx(day: forecastDay, highWater: forecastDay + 5)] {
            XCTAssertEqual(GardenWeather.home(c, cardDismissedDay: 0), GardenWeather.Home())
            XCTAssertNil(GardenWeather.widgetLine(c))
            XCTAssertNil(GardenWeather.reminderForecast(on: weatherDate(day: forecastDay, hour: 17), c, optedIn: true, notifyAllowed: true))
        }
        XCTAssertEqual(GardenWeather.home(ctx(day: known.event.day, quiet: true), cardDismissedDay: 0), GardenWeather.Home())
        XCTAssertEqual(GardenWeather.home(ctx(day: known.event.day, calm: true), cardDismissedDay: 0), GardenWeather.Home())
    }

    func testOnceTheGateOpenedItStaysOpenAfterAReconcile() {
        XCTAssertEqual(GardenWeather.home(ctx(day: forecastDay, found: 0, tends: 0, gatedFromDay: forecastDay - 9), cardDismissedDay: 0).card, kind)
    }

    func testATestOverrideReplacesTheSchedule() {
        let h = GardenWeather.home(ctx(day: quietDay), cardDismissedDay: 0, override: .init(forecast: .hailShower))
        XCTAssertEqual(h.card, .hailShower)
        XCTAssertEqual(GardenWeather.home(ctx(day: quietDay, quiet: true), cardDismissedDay: 0, override: .init(event: .bigWind)), GardenWeather.Home(),
                       "Quiet Garden still wins over a test override")
    }

    // MARK: Widget

    func testTheWidgetLineIsTheForecastInPlainWords() {
        XCTAssertEqual(GardenWeather.widgetLine(ctx(day: forecastDay)), WeatherCopy.widgetLine(kind))
        XCTAssertEqual(GardenWeather.widgetChip(ctx(day: forecastDay)), WeatherCopy.forecastChip(kind))
        XCTAssertNil(GardenWeather.widgetLine(ctx(day: forecastDay, calm: true)), "Calm hides weather")
        XCTAssertNil(GardenWeather.widgetLine(ctx(day: known.event.day)))
    }

    func testTheWidgetGateUsesTheStoredGateDayBecauseItHasNoBadgeCounts() {
        let p = PlayerProfile()
        p.weatherSeed = known.seed; p.weatherStartDay = known.startDay; p.weatherGatedFromDay = forecastDay - 3
        let c = GardenWeather.widgetContext(profile: p, today: forecastDay, quietGarden: false, calmMode: false, weatherOn: true)
        XCTAssertEqual(GardenWeather.widgetLine(c), WeatherCopy.widgetLine(kind))
        p.weatherGatedFromDay = 0
        XCTAssertNil(GardenWeather.widgetLine(GardenWeather.widgetContext(profile: p, today: forecastDay, quietGarden: false, calmMode: false, weatherOn: true)))
    }

    // MARK: Reminder

    func testTheReminderOnAForecastDayCarriesTheForecast() {
        let c = ctx(day: forecastDay)
        XCTAssertEqual(GardenWeather.reminderForecast(on: weatherDate(day: forecastDay, hour: 17), c, optedIn: true, notifyAllowed: true), kind)
        XCTAssertNil(GardenWeather.reminderForecast(on: weatherDate(day: forecastDay, hour: 17), c, optedIn: false, notifyAllowed: true))
        XCTAssertNil(GardenWeather.reminderForecast(on: weatherDate(day: forecastDay, hour: 17), c, optedIn: true, notifyAllowed: false))
        XCTAssertNil(GardenWeather.reminderForecast(on: weatherDate(day: known.event.day, hour: 17), c, optedIn: true, notifyAllowed: true))
        // A reminder planned today for the forecast day two days out still finds it.
        XCTAssertEqual(GardenWeather.reminderForecast(on: weatherDate(day: forecastDay, hour: 17), ctx(day: forecastDay - 2), optedIn: true, notifyAllowed: true), kind)
    }

    func testTheForecastReminderIsNeverForUnder13UnknownAgeCalmOrQuiet() {
        XCTAssertTrue(GardenWeather.notifyAllowed(ageBand: .eighteenPlus, calmMode: false, quietGarden: false, weatherOn: true))
        XCTAssertTrue(GardenWeather.notifyAllowed(ageBand: .thirteenPlus, calmMode: false, quietGarden: false, weatherOn: true))
        XCTAssertFalse(GardenWeather.notifyAllowed(ageBand: .under13, calmMode: false, quietGarden: false, weatherOn: true))
        XCTAssertFalse(GardenWeather.notifyAllowed(ageBand: nil, calmMode: false, quietGarden: false, weatherOn: true))
        XCTAssertFalse(GardenWeather.notifyAllowed(ageBand: .eighteenPlus, calmMode: true, quietGarden: false, weatherOn: true))
        XCTAssertFalse(GardenWeather.notifyAllowed(ageBand: .eighteenPlus, calmMode: false, quietGarden: true, weatherOn: true))
        XCTAssertFalse(GardenWeather.notifyAllowed(ageBand: .eighteenPlus, calmMode: false, quietGarden: false, weatherOn: false))
    }

    // MARK: Witnessed first

    func testSeenIsStoredOnceOnOrAfterTheEventDayAndNeverMovedLater() {
        let first = weatherDate(day: known.event.day, hour: 8)
        XCTAssertEqual(GardenWeather.seenAt(current: nil, now: first, latestEventDay: known.event.day), first)
        XCTAssertEqual(GardenWeather.seenAt(current: first, now: first.addingTimeInterval(3600), latestEventDay: known.event.day), first,
                       "a later look must not undo care given after the first look")
        let stale = weatherDate(day: known.event.day - 30)
        XCTAssertEqual(GardenWeather.seenAt(current: stale, now: first, latestEventDay: known.event.day), first, "a look at an older event does not count")
        XCTAssertEqual(GardenWeather.seenAt(current: stale, now: first, latestEventDay: nil), stale)
    }
}

// MARK: The reminder slot

@MainActor
final class WeatherReminderTests: XCTestCase {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = .current; return c }

    func testAForecastReplacesThatDaysReminderAndAddsNoRequest() async {
        let fake = ReminderTests.FakeCenter()
        let s = ReminderScheduler(center: fake, calendar: cal)
        let now = weatherDate(day: 400, hour: 9)
        _ = await s.enable(now: now, hour: 17, minute: 0, lastOpened: now, dailyBloomDoneToday: false,
                           forecast: { WeatherDay.key($0) == 401 ? .bigWind : nil })
        XCTAssertEqual(fake.scheduled.count, 3, "still one a day, at most three")
        XCTAssertEqual(Set(fake.scheduled.map(\.id)).count, 3)
        XCTAssertEqual(fake.scheduled[1].title, WeatherCopy.notificationTitle(.bigWind))
        XCTAssertEqual(fake.scheduled[1].body, WeatherUICopy.notificationBody)
        XCTAssertTrue(fake.scheduled[1].title.lowercased().contains("garden"), "can never read as a real weather alert")
        XCTAssertEqual(fake.scheduled[0].title, ReminderCopy.message(kind: .dailyBloom, variant: 0).title)
        XCTAssertEqual(fake.scheduled[1].date, weatherDate(day: 401, hour: 17), "same time and quiet hours as the daily reminder")
    }

    func testNoForecastLeavesTheReminderAsItWas() async {
        let fake = ReminderTests.FakeCenter()
        let s = ReminderScheduler(center: fake, calendar: cal)
        let now = weatherDate(day: 400, hour: 9)
        _ = await s.enable(now: now, hour: 17, minute: 0, lastOpened: now, dailyBloomDoneToday: true)
        XCTAssertEqual(fake.scheduled.map(\.title), [ReminderCopy.message(kind: .tend, variant: 0).title,
                                                    ReminderCopy.message(kind: .dailyBloom, variant: 1).title,
                                                    ReminderCopy.message(kind: .dailyBloom, variant: 2).title])
    }
}

// MARK: App wiring

@MainActor
final class GardenWeatherAppTests: XCTestCase {
    final class Clock { var date: Date; init(_ d: Date) { date = d } }

    func makeApp(clock: Clock, age: AgeBand = .eighteenPlus, calm: Bool? = nil, quiet: Bool = false, remind: Bool = false,
                 center: ReminderTests.FakeCenter = ReminderTests.FakeCenter()) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-gwa-\(UUID().uuidString)")!)
        settings.applyAgeDefaults(age)
        if let calm { settings.calmMode = calm }
        settings.quietGarden = quiet
        settings.onboardingComplete = true
        settings.remindMe = remind
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: { clock.date }, notifications: center)
    }

    func gardened(_ app: AppModel, known: KnownWeather, gatedFrom: Int) {
        let p = app.profile!
        p.weatherSeed = known.seed; p.weatherStartDay = known.startDay; p.weatherGatedFromDay = gatedFrom
        try? app.context.save()
    }

    func testLaunchGivesTheGardenItsOwnSeedAndAStartAWeekAfterItBegan() throws {
        let clock = Clock(weatherDate(day: 320))
        let app = try makeApp(clock: clock)
        let p = try XCTUnwrap(app.profile)
        XCTAssertNotEqual(p.weatherSeed, 0)
        XCTAssertEqual(p.weatherStartDay, WeatherDay.key(p.createdAt) + Economy.default.weatherFirstWeekDays)
        let seed = p.weatherSeed
        app.refreshWeather()
        XCTAssertEqual(p.weatherSeed, seed, "a seed already set is kept")
        let other = try makeApp(clock: clock)
        XCTAssertNotEqual(other.profile?.weatherSeed, seed, "every player has their own")
    }

    func testRefreshKeepsTheClockHighWaterAndRecordsTheGateDay() throws {
        let clock = Clock(weatherDate(day: 330))
        let app = try makeApp(clock: clock)
        XCTAssertEqual(app.profile?.weatherHighWaterDay, 330)
        XCTAssertEqual(app.profile?.weatherGatedFromDay, 0, "a new garden is not gated in yet")
        let plants = app.plants()
        for p in plants.prefix(5) { p.earnedCount = 1 }
        app.profile?.water = 5
        _ = app.tend(.water, plant: plants[0]); _ = app.tend(.water, plant: plants[1])
        app.refreshWeather()
        XCTAssertEqual(app.profile?.weatherGatedFromDay, 330)
        clock.date = weatherDate(day: 320)        // the clock went back
        app.refreshWeather()
        XCTAssertEqual(app.profile?.weatherHighWaterDay, 330, "never lowered")
        XCTAssertEqual(app.profile?.weatherGatedFromDay, 330)
    }

    func testHomeShowsTheForecastAndGotItHidesTheCardForTheDay() throws {
        let known = KnownWeather()
        let clock = Clock(weatherDate(day: known.event.day - 1))
        let app = try makeApp(clock: clock)
        gardened(app, known: known, gatedFrom: known.startDay)
        XCTAssertEqual(app.homeWeather.card, known.event.kind)
        XCTAssertEqual(app.homeWeather.chip, WeatherCopy.forecastChip(known.event.kind))
        app.dismissForecastCard()
        XCTAssertNil(app.homeWeather.card)
        XCTAssertNotNil(app.homeWeather.chip)
        clock.date = weatherDate(day: known.event.day)
        XCTAssertEqual(app.homeWeather.banner, known.event.kind)
    }

    func testWeatherOffQuietGardenAndTheYoungDefaultShowNothing() throws {
        let known = KnownWeather()
        let clock = Clock(weatherDate(day: known.event.day - 1))
        for app in [try makeApp(clock: clock, quiet: true), try makeApp(clock: clock, age: .under13)] {
            gardened(app, known: known, gatedFrom: known.startDay)
            XCTAssertEqual(app.homeWeather, GardenWeather.Home())
        }
        let off = try makeApp(clock: clock); gardened(off, known: known, gatedFrom: known.startDay)
        off.settings.gardenWeather = false
        XCTAssertEqual(off.homeWeather, GardenWeather.Home())
    }

    func testTheEventIsMarkedSeenWhenHomeOpensOnTheDay() throws {
        let known = KnownWeather()
        let clock = Clock(weatherDate(day: known.event.day - 1))
        let app = try makeApp(clock: clock)
        gardened(app, known: known, gatedFrom: known.startDay)
        app.markWeatherSeen()
        XCTAssertNil(app.profile?.weatherSeenAt, "the day before is a forecast, not the weather")
        clock.date = weatherDate(day: known.event.day, hour: 10)
        app.markWeatherSeen()
        XCTAssertEqual(app.profile?.weatherSeenAt, clock.date)
        let seen = clock.date
        clock.date = weatherDate(day: known.event.day + 1, hour: 10)
        app.markWeatherSeen()
        XCTAssertEqual(app.profile?.weatherSeenAt, seen, "kept, so care given after the first look still mends")
    }

    func testNothingIsMarkedSeenWhileWeatherIsHidden() throws {
        let known = KnownWeather()
        let clock = Clock(weatherDate(day: known.event.day, hour: 10))
        let app = try makeApp(clock: clock, quiet: true)
        gardened(app, known: known, gatedFrom: known.startDay)
        app.markWeatherSeen()
        XCTAssertNil(app.profile?.weatherSeenAt)
    }

    func testWeatherNeverChangesTheWordLevelOrAnyStoredStage() throws {
        let known = KnownWeather()
        let clock = Clock(weatherDate(day: known.event.day, hour: 10))
        let app = try makeApp(clock: clock)
        let plants = app.plants()
        for p in plants.prefix(12) { p.earnedCount = 1; p.stage = 3 }
        gardened(app, known: known, gatedFrom: known.startDay)
        app.game.refreshLevel()
        let level = app.profile?.currentLevel, stages = plants.map(\.stage), growth = plants.map(\.growthPoints)
        app.setWildWeather(true)
        app.refreshWeather(); app.markWeatherSeen(); app.reconcileSyncedData()
        XCTAssertEqual(app.profile?.currentLevel, level)
        XCTAssertEqual(app.plants().map(\.stage), stages)
        XCTAssertEqual(app.plants().map(\.growthPoints), growth)
    }

    // MARK: Wild Weather (E-12)

    func testWildWeatherIsAnOptInWithCalmOff() throws {
        let clock = Clock(weatherDate(day: 330))
        let adult = try makeApp(clock: clock)
        XCTAssertTrue(adult.wildWeatherAvailable)
        XCTAssertFalse(adult.wildWeatherOn, "off by default")
        adult.setWildWeather(true)
        XCTAssertTrue(adult.wildWeatherOn)
        XCTAssertTrue(adult.profile?.wildWeather == true)
        adult.setWildWeather(false)
        XCTAssertFalse(adult.wildWeatherOn, "one tap turns it off at once")

        let teen = try makeApp(clock: clock, age: .thirteenPlus)
        XCTAssertTrue(teen.wildWeatherAvailable)
    }

    /// Owner ruling 2026-11-05: any age may opt in. Under 13 starts in Calm (which hides it) with weather off, so it
    /// takes Calm off, weather on and the toggle: never on by default, never prompted.
    func testAYoungPlayerMayOptInOnceCalmIsOffAndWeatherIsOn() throws {
        let clock = Clock(weatherDate(day: 330))
        let young = try makeApp(clock: clock, age: .under13)
        XCTAssertFalse(young.wildWeatherAvailable, "the young default (Calm, weather off) hides it")
        XCTAssertFalse(young.wildWeatherOn)
        young.settings.calmMode = false
        XCTAssertTrue(young.wildWeatherAvailable)
        XCTAssertFalse(young.wildWeatherOn, "still off until chosen")
        young.setWildWeather(true)
        XCTAssertTrue(young.wildWeatherOn)
        young.settings.calmMode = true
        XCTAssertFalse(young.wildWeatherOn, "Calm hides it again at once")
    }

    func testTurningWildWeatherOnIsRefusedWhileItIsHidden() throws {
        let clock = Clock(weatherDate(day: 330))
        let calm = try makeApp(clock: clock, calm: true)
        calm.setWildWeather(true)
        XCTAssertFalse(calm.profile?.wildWeather ?? true)
    }

    func testWildWeatherIsHiddenInCalmQuietGardenAndWithWeatherOff() throws {
        let clock = Clock(weatherDate(day: 330))
        let calm = try makeApp(clock: clock, calm: true)
        XCTAssertFalse(calm.wildWeatherAvailable)
        let quiet = try makeApp(clock: clock, quiet: true)
        XCTAssertFalse(quiet.wildWeatherAvailable)
        let off = try makeApp(clock: clock); off.settings.gardenWeather = false
        XCTAssertFalse(off.wildWeatherAvailable)
        off.profile?.wildWeather = true
        XCTAssertFalse(off.wildWeatherOn)
    }

    // MARK: The level ring's dashed segment (E-12)

    func testWildWeatherDashesTheBloomRingButEarnedBloomAndTheLevelStay() throws {
        let seed: Int64 = 424_242, start = 300
        let big = try XCTUnwrap(WeatherEngine.events(from: start, through: 3000, seed: seed, startDay: start).first { $0.kind.isBig })
        let clock = Clock(weatherDate(day: big.day, hour: 10))
        let app = try makeApp(clock: clock)
        let p = try XCTUnwrap(app.profile)
        p.weatherSeed = seed; p.weatherStartDay = start; p.weatherGatedFromDay = start
        let traits = Dictionary(try PlantCatalog.load().map { ($0.plantId, $0.traitSet) }, uniquingKeysWith: { a, _ in a })
        // Every plant found and in full bloom, loved an hour before the look (so no love rain and no mend).
        for plant in app.plants() { plant.earnedCount = 1; plant.stage = 4; plant.lastLovedAt = clock.date.addingTimeInterval(-3600) }
        try app.context.save()
        let fullIds = app.plants().filter { WeatherEngine.effect(big.kind, traits: traits[$0.plantId] ?? []) == .full }.map(\.plantId)
        XCTAssertFalse(fullIds.isEmpty)
        app.markWeatherSeen()

        XCTAssertEqual(app.levelMending(), [:], "off until opted in: Variant 1 is looks only")
        app.setWildWeather(true)
        let mending = app.levelMending()
        let total = mending.values.reduce(0, +)
        XCTAssertGreaterThan(total, 0)
        XCTAssertLessThanOrEqual(total, Economy.default.wildMaxPlants)

        let progress = app.plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) }
        let stops = LevelMapCopy.stops(plants: progress, currentLevel: 5, mending: mending)
        XCTAssertEqual(stops.map(\.mending).reduce(0, +), total)
        XCTAssertTrue(stops.allSatisfy { $0.bloom == 10 && $0.fullBloom }, "earned bloom and completion never read the dip")
        XCTAssertNotNil(stops.first { $0.mending > 0 }?.mendingLine)
        XCTAssertTrue(app.plants().allSatisfy { $0.stage == 4 }, "the stored stage never changes")

        // The "changed since last visit" key: set while the plant shows weather, empty when it does not.
        let dipped = try XCTUnwrap(app.plants().first { app.weatherLooks()[$0.plantId]?.setback == 1 })
        let key = app.weatherChangeKey(for: dipped)
        XCTAssertTrue(key.hasPrefix("\(big.day):\(big.kind.rawValue):"), key)
        XCTAssertEqual(app.weatherChangeKey(for: dipped), key, "stable within one state")
        app.setWildWeather(false)
        XCTAssertNotEqual(app.weatherChangeKey(for: dipped), key, "a change of state changes the key")
        app.setWildWeather(true)

        // Care today stands it tall tomorrow; and Calm hides it at once.
        clock.date = weatherDate(day: big.day + 4, hour: 10)
        XCTAssertEqual(app.levelMending(), [:], "mends by itself within 4 days")
        clock.date = weatherDate(day: big.day, hour: 11)
        app.settings.calmMode = true
        XCTAssertEqual(app.levelMending(), [:])
    }

    // MARK: Forecast reminder (E-10)

    func testTheForecastReminderSharesTheDailySlotWhenOptedIn() throws {
        let known = KnownWeather()
        let center = ReminderTests.FakeCenter()
        let clock = Clock(weatherDate(day: known.event.day - 1, hour: 9))
        let app = try makeApp(clock: clock, remind: true, center: center)
        gardened(app, known: known, gatedFrom: known.startDay)
        app.settings.reminderHour = 17
        app.refreshReminders()
        XCTAssertEqual(center.scheduled.count, 3)
        XCTAssertFalse(center.scheduled.contains { $0.title == WeatherCopy.notificationTitle(known.event.kind) }, "off until opted in")
        XCTAssertTrue(app.weatherNotifyAvailable)
        app.settings.weatherNotify = true
        app.refreshReminders()
        XCTAssertEqual(center.scheduled.count, 3, "no extra request")
        XCTAssertEqual(center.scheduled.first?.title, WeatherCopy.notificationTitle(known.event.kind))
    }

    func testTheForecastReminderIsHiddenUnder13() throws {
        let known = KnownWeather()
        let center = ReminderTests.FakeCenter()
        let clock = Clock(weatherDate(day: known.event.day - 1, hour: 9))
        let app = try makeApp(clock: clock, age: .under13, calm: false, remind: true, center: center)
        gardened(app, known: known, gatedFrom: known.startDay)
        app.settings.weatherNotify = true          // even if set somehow
        XCTAssertFalse(app.weatherNotifyAvailable)
        app.refreshReminders()
        XCTAssertFalse(center.scheduled.contains { $0.title.hasPrefix("Garden forecast") })
    }
}

// MARK: Copy

final class WeatherUICopyTests: XCTestCase {
    static let avoid = ["save", "rescue", "danger", "destroy", "warning", "alert", "too late", "countdown", "hurry", "lose", "drop"]

    func testEveryNewLinePassesCopySafetyAndTheWeatherAvoidList() {
        let lines = WeatherUICopy.all
        XCTAssertGreaterThan(lines.count, 15)
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for word in Self.avoid {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in: \(line)")
            }
            XCTAssertFalse(line.contains("!!"), line)
        }
    }

    func testWildWeatherIsExplainedPlainlyAndSaysTheLevelStays() {
        XCTAssertFalse(WeatherUICopy.wildFootnote.contains("13"), "any age may choose it (owner ruling 2026-11-05)")
        XCTAssertTrue(WeatherUICopy.wildFootnote.lowercased().contains("off"), "says one tap turns it off")
        XCTAssertTrue(WeatherUICopy.wildConfirmMessage.contains("level"))
        XCTAssertTrue(WeatherUICopy.wildConfirmMessage.contains("4 days"))
    }

    func testUnder13SeeAGrownUpNoteBesideWildWeather() {
        XCTAssertEqual(WeatherUICopy.wildGrownUpNote, "Ask a grown-up if you like.")
        XCTAssertTrue(WeatherUICopy.all.contains(WeatherUICopy.wildGrownUpNote))
        XCTAssertTrue(WeatherUICopy.showsWildGrownUpNote(ageBand: .under13))
        XCTAssertFalse(WeatherUICopy.showsWildGrownUpNote(ageBand: .thirteenPlus))
        XCTAssertFalse(WeatherUICopy.showsWildGrownUpNote(ageBand: .eighteenPlus))
        XCTAssertFalse(WeatherUICopy.showsWildGrownUpNote(ageBand: nil))
    }
}

// MARK: The plant page's weather art and sound (mounted only behind the weather gate)

@MainActor
final class PlantWeatherMountTests: XCTestCase {
    final class Clock { var date: Date; init(_ d: Date) { date = d } }

    func makeApp(clock: Clock, calm: Bool = false, quiet: Bool = false, weatherOn: Bool = true) throws -> (AppModel, PlantCollectible) {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-pwm-\(UUID().uuidString)")!)
        settings.applyAgeDefaults(.eighteenPlus)
        settings.onboardingComplete = true
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: { clock.date },
                           notifications: ReminderTests.FakeCenter())
        let plant = try XCTUnwrap(app.plants().first)
        plant.earnedCount = 1
        plant.lastLovedAt = clock.date.addingTimeInterval(-3_600)     // loved an hour ago: no love rain
        app.weatherTestOverride = GardenWeather.Override(forecast: nil, event: .bigWind)
        app.profile?.weatherGatedFromDay = app.weatherToday
        try? app.context.save()
        app.markWeatherSeen()                                         // Home was opened on the weather day
        settings.calmMode = calm
        settings.quietGarden = quiet
        settings.gardenWeather = weatherOn
        return (app, plant)
    }

    func testAWeatherDayMountsTheArtWithTheKindItsLookAndAPageLine() throws {
        let clock = Clock(weatherDate(day: 330, hour: 10))
        let (app, plant) = try makeApp(clock: clock)
        let scene = try XCTUnwrap(app.plantWeather(plant))
        XCTAssertEqual(scene.kind, .bigWind)
        XCTAssertFalse(scene.line.isEmpty, "VoiceOver hears the weather in words")
        XCTAssertTrue(WeatherSoundGate.allows(.windBed, app.weatherSoundContext(systemReduceMotion: false)))
    }

    func testCalmModeShowsNoWeatherArtAndPlaysNoWeatherSound() throws {
        let clock = Clock(weatherDate(day: 330, hour: 10))
        let (app, plant) = try makeApp(clock: clock, calm: true)
        XCTAssertNil(app.plantWeather(plant))
        let ctx = app.weatherSoundContext(systemReduceMotion: false)
        for s in WeatherSound.allCases { XCTAssertFalse(WeatherSoundGate.allows(s, ctx), "\(s) in Calm") }
    }

    func testQuietGardenShowsNoWeatherArtAndPlaysNoWeatherSound() throws {
        let clock = Clock(weatherDate(day: 330, hour: 10))
        let (app, plant) = try makeApp(clock: clock, quiet: true)
        XCTAssertNil(app.plantWeather(plant))
        let ctx = app.weatherSoundContext(systemReduceMotion: false)
        for s in WeatherSound.allCases { XCTAssertFalse(WeatherSoundGate.allows(s, ctx), "\(s) in Quiet Garden") }
    }

    func testGardenWeatherOffShowsNoWeatherArt() throws {
        let clock = Clock(weatherDate(day: 330, hour: 10))
        let (app, plant) = try makeApp(clock: clock, weatherOn: false)
        XCTAssertNil(app.plantWeather(plant))
    }

    func testAHelloMendsTheLookSoTheArtGoes() throws {
        let clock = Clock(weatherDate(day: 330, hour: 10))
        let (app, plant) = try makeApp(clock: clock)
        XCTAssertNotNil(app.plantWeather(plant))
        clock.date = clock.date.addingTimeInterval(60)
        app.love(plant)
        XCTAssertNil(app.plantWeather(plant), "care after the first look mends at once (the relief chime's moment)")
    }
}

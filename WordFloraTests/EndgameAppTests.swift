import XCTest
import SwiftData
@testable import WordFlora

/// The weather helpers, the weather puzzle and the Grand Garden through the app model (in-memory store, fixed clock).
@MainActor
final class EndgameAppTests: XCTestCase {
    /// Noon, 5 November 2026, local time.
    let noon: Date = {
        var c = DateComponents(); c.year = 2026; c.month = 11; c.day = 5; c.hour = 12
        return Calendar(identifier: .gregorian).date(from: c)!
    }()
    var clock: Date = .now

    func makeApp(calm: Bool = false, quiet: Bool = false, age: AgeBand? = .eighteenPlus) throws -> AppModel {
        clock = noon
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-endgame-\(UUID().uuidString)")!)
        settings.ageBand = age
        settings.calmMode = calm
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: { [unowned self] in self.clock },
                        notifications: ReminderTests.FakeCenter())
    }

    /// Six found plants, the gate opened and a seed whose event falls `offset` days from today.
    @discardableResult
    func weather(_ app: AppModel, eventIn offset: Int, kind: WeatherKind? = nil, gardenDays: Int = 3) -> WeatherKind {
        let today = WeatherDay.key(clock)
        let f = WeatherFixture.seed(eventOn: today + offset, kind: kind)
        for p in app.plants().prefix(6) { p.earnedCount = 1; p.stage = 2 }
        app.profile?.weatherSeed = f.seed; app.profile?.weatherStartDay = f.startDay
        app.profile?.weatherGatedFromDay = today; app.profile?.weatherHighWaterDay = today
        app.profile?.gardenDays = gardenDays
        return f.kind
    }

    // MARK: Helpers (E-7)

    func testTheKitArrivesWithTheFirstForecastAndHelpersSetOutForFree() throws {
        let app = try makeApp()
        let kind = weather(app, eventIn: 1)
        XCTAssertFalse(app.showsWeatherHelpers, "no kit yet")
        XCTAssertTrue(app.receiveWeatherKitIfDue())
        XCTAssertFalse(app.receiveWeatherKitIfDue(), "once")
        XCTAssertTrue(app.showsWeatherHelpers)
        let helper = WeatherHelper.helper(for: kind)
        XCTAssertEqual(app.helperState(helper), .canSetOut)
        let before = (app.profile!.water, app.profile!.soil, app.profile!.shedPoints)
        XCTAssertTrue(app.setOutHelper())
        XCTAssertEqual(app.helperState(helper), .setOut)
        XCTAssertFalse(app.setOutHelper(), "a second tap changes nothing")
        XCTAssertEqual(before.0, app.profile!.water); XCTAssertEqual(before.1, app.profile!.soil); XCTAssertEqual(before.2, app.profile!.shedPoints)
        clock = clock.addingTimeInterval(86_400)
        XCTAssertTrue(app.weatherSheltered, "the event's plants stay snug")
    }

    func testCalmAndQuietGardenHideHelpersAndThePuzzle() throws {
        for (calm, quiet) in [(true, false), (false, true)] {
            let app = try makeApp(calm: calm, quiet: quiet)
            weather(app, eventIn: 0)
            app.profile?.weatherKitAt = .now
            XCTAssertFalse(app.receiveWeatherKitIfDue())
            XCTAssertFalse(app.showsWeatherHelpers)
            XCTAssertFalse(app.weatherPuzzleOpen)
            XCTAssertNil(app.currentWeatherPuzzle(tier: .gentle))
            XCTAssertNil(app.solveWeatherPuzzle())
        }
    }

    func testNoSeedMeansNoWeather() throws {
        let app = try makeApp()
        for p in app.plants().prefix(6) { p.earnedCount = 1 }
        app.profile?.weatherGatedFromDay = 1
        XCTAssertNil(app.weatherNow.event); XCTAssertNil(app.weatherNow.forecast)
        XCTAssertFalse(app.receiveWeatherKitIfDue())
        XCTAssertFalse(app.weatherPuzzleOpen)
    }

    // MARK: Puzzle (E-8)

    func testThePuzzleCountsFreshPuzzlesAndStopsAtThree() throws {
        let app = try makeApp()
        weather(app, eventIn: 0)
        XCTAssertTrue(app.weatherPuzzleOpen)
        let first = app.currentWeatherPuzzle(tier: .storm)
        XCTAssertNotNil(first)
        XCTAssertEqual(app.currentWeatherPuzzle(tier: .storm), first, "reopening shows the same puzzle")
        XCTAssertEqual(app.profile?.weatherPuzzleCount, 1)
        XCTAssertNotNil(app.newWeatherPuzzle(tier: .storm))
        XCTAssertNotNil(app.newWeatherPuzzle(tier: .storm))
        XCTAssertNil(app.newWeatherPuzzle(tier: .storm), "that is plenty for today")
        XCTAssertFalse(app.weatherPuzzleMayStartFresh)
        XCTAssertNotNil(app.currentWeatherPuzzle(tier: .storm), "the current one can still be finished")
    }

    func testASolveMendsTheGardenAndGivesTheNamedReward() throws {
        let app = try makeApp()
        weather(app, eventIn: 0)
        app.profile?.wordsTowardPlant = 0
        let level = app.profile?.currentLevel
        let reward = app.weatherPuzzleReward
        XCTAssertEqual(reward.sticker, .rainbow); XCTAssertTrue(reward.word)
        let solve = try XCTUnwrap(app.solveWeatherPuzzle())
        XCTAssertEqual(solve.reward, reward)
        XCTAssertEqual(app.profile?.weatherRescuedDays, [app.weatherNow.eventDay])
        XCTAssertEqual(app.album.count(of: "weather.1"), 1)
        XCTAssertEqual(app.profile?.wordsTowardPlant, 1)
        XCTAssertEqual(app.badges.progress(of: .weathered), 1)
        XCTAssertEqual(app.pendingBadge?.badgeId, "weathered")
        XCTAssertFalse(app.weatherPuzzleOpen, "solved")
        XCTAssertNil(app.solveWeatherPuzzle(), "a second solve gives nothing more")
        XCTAssertGreaterThanOrEqual(app.profile?.currentLevel ?? 0, level ?? 0, "word level never drops")
    }

    func testTheThirdWordBringsAPlant() throws {
        let app = try makeApp()
        weather(app, eventIn: 0)
        app.profile?.wordsTowardPlant = 2
        let found = app.plants().filter { $0.earnedCount > 0 }.count
        let solve = try XCTUnwrap(app.solveWeatherPuzzle())
        XCTAssertNotNil(solve.plantArrived)
        XCTAssertEqual(app.plants().filter { $0.earnedCount > 0 }.count, found + 1)
        XCTAssertEqual(app.profile?.wordsTowardPlant, 0)
    }

    func testTheAntiFarmCapHoldsTheBonusButStillMends() throws {
        let app = try makeApp()
        weather(app, eventIn: 0, gardenDays: 6)
        app.profile?.weatherRescuedDays = [1]           // one reward already, 6 Garden Days: not yet 7 per reward
        XCTAssertTrue(app.weatherPuzzleReward.isEmpty)
        let solve = try XCTUnwrap(app.solveWeatherPuzzle())
        XCTAssertTrue(solve.reward.isEmpty)
        XCTAssertTrue(app.profile!.weatherRescuedDays.contains(app.weatherNow.eventDay), "the garden still mends")
        XCTAssertEqual(app.badges.progress(of: .weathered), 0)
        XCTAssertEqual(app.album.count(of: "weather.1"), 0)
    }

    func testAPuzzleVisitShowsNoPlusCardOrAds() throws {
        let app = try makeApp()
        XCTAssertFalse(app.quietVisit)
        app.markQuietVisit()
        XCTAssertFalse(app.adWouldPlayOnOneMore)
        XCTAssertFalse(app.showBanner)
        app.checkPlusOffer()
        XCTAssertNil(app.plusOffer)
    }

    // MARK: Grand Garden (G-2 to G-5)

    func findAll(_ app: AppModel, bloom: Bool) {
        for p in app.plants() { p.earnedCount = 1; p.stage = bloom ? 4 : 2 }
        app.game.refreshLevel()
    }

    func testTheCeremonyPlaysOnceThenTheGoldCrown() throws {
        let app = try makeApp()
        XCTAssertNil(app.pendingCeremony)
        XCTAssertEqual(app.crown, EndgamePolicy.Crown.none)
        findAll(app, bloom: true)
        XCTAssertEqual(app.crown, .gold)
        XCTAssertEqual(app.pendingCeremony, .grandGarden)
        app.markCeremonySeen(.grandGarden)
        XCTAssertNotNil(app.profile?.crownSeenAt)
        XCTAssertTrue(app.quietVisit, "no Plus card or ads in the ceremony's visit")
        XCTAssertEqual(app.pendingCeremony, .goldCrown)
        app.markCeremonySeen(.goldCrown)
        XCTAssertNil(app.pendingCeremony)
    }

    func testTendingAFullBloomPlantEarnsAGoldenDayOnceADay() throws {
        let app = try makeApp()
        findAll(app, bloom: true)
        let plant = app.plants().first!
        app.profile?.water = 10; app.profile?.soil = 10
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(plant.goldenDays, 1)
        XCTAssertTrue(app.tend(.feed, plant: plant).applied)
        XCTAssertEqual(plant.goldenDays, 1, "at most one a day")
        app.love(plant)
        XCTAssertEqual(plant.goldenDays, 1, "a hello does not count")
        for _ in 0..<5 {
            clock = clock.addingTimeInterval(86_400)
            _ = app.tend(.sun, plant: plant)
        }
        XCTAssertEqual(plant.goldenDays, 6)
        clock = clock.addingTimeInterval(86_400)
        let r = app.tend(.sun, plant: plant)
        XCTAssertEqual(plant.goldenDays, 7)
        XCTAssertTrue(app.isGolden(plant))
        XCTAssertEqual(r.message, EndgameCopy.goldenLine(name: plant.name))
    }

    func testNoGoldenDaysBeforeEveryPlantIsFound() throws {
        let app = try makeApp()
        let plant = app.plants().first!
        plant.earnedCount = 1; plant.stage = 4
        app.profile?.water = 3
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(plant.goldenDays, 0)
        XCTAssertNil(app.featuredGolden)
    }

    func testHomeFeaturesThePlantNearestGolden() throws {
        let app = try makeApp()
        findAll(app, bloom: true)
        let daisy = try XCTUnwrap(app.plants().first { $0.plantId == "daisy" })
        daisy.goldenDays = 5
        XCTAssertEqual(app.featuredGolden?.id, "daisy")
        for p in app.plants() { p.goldenDays = 7 }
        XCTAssertNil(app.featuredGolden)
        XCTAssertTrue(app.everyPlantGolden)
    }

    func testAtAFullCollectionThePuzzleGivesAGoldenDayInsteadOfAWord() throws {
        let app = try makeApp()
        findAll(app, bloom: true)
        let today = WeatherDay.key(clock)
        let f = WeatherFixture.seed(eventOn: today)
        app.profile?.weatherSeed = f.seed; app.profile?.weatherStartDay = f.startDay
        app.profile?.weatherGatedFromDay = today; app.profile?.gardenDays = 3
        let words = app.profile?.wordsTowardPlant
        let solve = try XCTUnwrap(app.solveWeatherPuzzle())
        XCTAssertTrue(solve.reward.goldenDay); XCTAssertFalse(solve.reward.word)
        XCTAssertNotNil(solve.goldenPlant)
        XCTAssertEqual(app.plants().map(\.goldenDays).reduce(0, +), 1)
        XCTAssertEqual(app.profile?.wordsTowardPlant, words)
    }

    func testBloomRankReadsTheDailyBloomCounter() throws {
        let app = try makeApp()
        XCTAssertEqual(app.bloomRank, .unranked)
        // Badge progress comes from the stored badges; ten Daily Blooms make a Sprout.
        var b = BadgeState(defs: (try? BadgeCatalog.load()) ?? [])
        for _ in 0..<10 { b.record(.dailyBloomsDone, now: .now) }
        app.profile?.badgesJSON = b.json
        app.reconcileSyncedData()
        XCTAssertEqual(app.bloomRank, .sprout)
        XCTAssertEqual(app.bloomsToNextRank, 20)
    }

    func testWeatherStickersNeverCountAsVisitorSpecies() throws {
        let app = try makeApp()
        weather(app, eventIn: 0)
        _ = app.solveWeatherPuzzle()
        XCTAssertEqual(app.album.species, 0)
    }
}

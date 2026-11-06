import Foundation

// Weather helpers (E-7) and the weather puzzle (E-8) on the app model. Everything reads the weather from the pure
// engine (`GardenWeatherNow.compute`, built on `WeatherEngine`); nothing here creates the seed or the start day.
//
// INTEGRATION (builder A, see docs/STATUS.md "Weather helpers, puzzle and the Grand Garden"):
// - `gardenWeatherSettingOn` returns the default (`!calmMode`) until the device-local "Garden weather" setting lands;
//   point it at `settings.gardenWeather` then.
// - The launch wiring (seed and start day, `weatherHighWaterDay`, `weatherGatedFromDay`, `weatherSeenAt`) stays with
//   builder A. With no seed, `weatherNow` reports no weather and every helper and puzzle hides.
// - The forecast card may call `setOutHelper()` and `receiveWeatherKitIfDue()`; the event banner and the plant page open
//   the puzzle with `WeatherPuzzleSheet` when `weatherPuzzleOpen` is true. The plant page's `WeatherLook.Input.sheltered`
//   is `weatherSheltered`.
extension AppModel {
    /// HOOK (builder A): the device-local Garden weather setting. Defaults to on unless Calm mode (spec 4.5).
    var gardenWeatherSettingOn: Bool { WeatherEngine.defaultWeatherOn(calmMode: settings.calmMode) }

    // Today's day key for weather is `weatherToday` (AppModel+Weather.swift).

    /// The weather now, from the stored fields and settings through the pure engine. Writes nothing.
    var weatherNow: GardenWeatherNow {
        guard let p = profile else { return .none }
        let found = plants().filter { $0.earnedCount > 0 }.count
        let tends = badges.progress(of: .waterings) + badges.progress(of: .feeds)
        let wild = WeatherLook.wildActive(optedIn: p.wildWeather, ageBand: settings.ageBand, calmMode: settings.calmMode,
                                          quietGarden: settings.quietGarden)
        return GardenWeatherNow.compute(seed: p.weatherSeed, startDay: p.weatherStartDay, today: weatherToday,
                                        highWater: p.weatherHighWaterDay, gatedFromDay: p.weatherGatedFromDay, found: found, tends: tends,
                                        quietGarden: settings.quietGarden, weatherOn: gardenWeatherSettingOn, calm: settings.calmMode,
                                        wild: wild)
    }

    // MARK: Weather helpers (E-7)

    /// The kit arrives once, with the first forecast the player can see (never in Calm or Quiet Garden). Returns true
    /// when it arrived just now, so a card can say "A weather kit for you, from the Shed."
    @discardableResult
    func receiveWeatherKitIfDue() -> Bool {
        guard let p = profile, ShelterPolicy.kitDue(kitAt: p.weatherKitAt, weather: weatherNow) else { return false }
        p.weatherKitAt = now()
        try? context.save()
        return true
    }

    /// The Shed shows its helpers once the kit has arrived and weather mechanics show.
    var showsWeatherHelpers: Bool { ShelterPolicy.showsHelpers(kitAt: profile?.weatherKitAt, weather: weatherNow) }

    func helperState(_ helper: WeatherHelper) -> ShelterPolicy.HelperState {
        ShelterPolicy.state(helper, weather: weatherNow, shelterDay: profile?.weatherShelterDay ?? 0)
    }

    /// One tap sets out the helper for the coming weather. Free, never used up, and nothing else changes.
    @discardableResult
    func setOutHelper() -> Bool {
        guard let p = profile else { return false }
        let day = ShelterPolicy.setOut(weather: weatherNow, shelterDay: p.weatherShelterDay)
        guard day != p.weatherShelterDay else { return false }
        p.weatherShelterDay = day
        try? context.save()
        return true
    }

    /// The latest event's plants stay snug (feeds `WeatherLook.Input.sheltered`).
    var weatherSheltered: Bool {
        ShelterPolicy.isSheltered(shelterDay: profile?.weatherShelterDay ?? 0, eventDay: weatherNow.eventDay)
    }

    // MARK: Weather puzzle (E-8)

    /// The puzzle is offered from the event day through the 3 days after, unless solved, in Calm or in Quiet Garden.
    var weatherPuzzleOpen: Bool {
        WeatherPuzzlePolicy.isOpen(weather: weatherNow, rescuedDays: profile?.weatherRescuedDays ?? [])
    }

    private var allPlantsFound: Bool {
        EndgamePolicy.allFound(plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) })
    }

    /// What a solve would give, named before play.
    var weatherPuzzleReward: WeatherPuzzlePolicy.Reward {
        guard let p = profile else { return .none }
        return WeatherPuzzlePolicy.reward(album: album, rescuedCount: p.weatherRescuedDays.count, gardenDays: p.gardenDays,
                                          allFound: allPlantsFound)
    }

    var weatherPuzzleOffersHarder: Bool { WeatherPuzzlePolicy.offersHarder(calm: settings.calmMode, wild: weatherNow.wild) }

    /// Names the puzzle draws from: found plants when there are enough for the tier, else the whole catalog.
    func weatherPuzzleNames(tier: WeatherPuzzleTier) -> [String] {
        let all = plants()
        let found = all.filter { $0.earnedCount > 0 }.map(\.name)
        return WakePuzzle.candidates(from: found, tier: tier).count >= 3 ? found : all.map(\.name)
    }

    /// Fresh puzzles still allowed today (the cap is 3; it never locks the garden, which mends by care and time).
    var weatherPuzzleMayStartFresh: Bool {
        guard let p = profile else { return false }
        return WeatherPuzzlePolicy.mayStartFresh(puzzleDay: p.weatherPuzzleDay, puzzleCount: p.weatherPuzzleCount, today: weatherToday)
    }

    /// Today's current puzzle. The first open of the day counts as one fresh puzzle; reopening shows the same one.
    func currentWeatherPuzzle(tier: WeatherPuzzleTier) -> WakePuzzle? {
        guard let p = profile, weatherPuzzleOpen else { return nil }
        let today = weatherToday
        if WeatherPuzzlePolicy.startedToday(puzzleDay: p.weatherPuzzleDay, puzzleCount: p.weatherPuzzleCount, today: today) == 0 {
            let pair = WeatherPuzzlePolicy.afterStart(puzzleDay: p.weatherPuzzleDay, puzzleCount: p.weatherPuzzleCount, today: today)
            p.weatherPuzzleDay = pair.day; p.weatherPuzzleCount = pair.count
            try? context.save()
        }
        let attempt = WeatherPuzzlePolicy.attempt(puzzleDay: p.weatherPuzzleDay, puzzleCount: p.weatherPuzzleCount, today: today)
        return WakePuzzle.weather(tier: tier, eventDay: weatherNow.eventDay, attempt: attempt, names: weatherPuzzleNames(tier: tier))
    }

    /// "New puzzle": a different puzzle for the same event, at most 3 fresh ones a day. Nil once today's are used.
    func newWeatherPuzzle(tier: WeatherPuzzleTier) -> WakePuzzle? {
        guard let p = profile, weatherPuzzleOpen, weatherPuzzleMayStartFresh else { return nil }
        let today = weatherToday
        let pair = WeatherPuzzlePolicy.afterStart(puzzleDay: p.weatherPuzzleDay, puzzleCount: p.weatherPuzzleCount, today: today)
        p.weatherPuzzleDay = pair.day; p.weatherPuzzleCount = pair.count
        try? context.save()
        return WakePuzzle.weather(tier: tier, eventDay: weatherNow.eventDay, attempt: pair.count - 1, names: weatherPuzzleNames(tier: tier))
    }

    struct WeatherSolve: Equatable {
        var reward: WeatherPuzzlePolicy.Reward
        /// A plant that arrived with the bonus word.
        var plantArrived: String?
        /// The plant that had a golden day (full collection).
        var goldenPlant: String?
        /// Weathered badge progress after the solve.
        var weathered: Int
    }

    /// Records a solve: the event's whole garden mends (its day joins `weatherRescuedDays`), then the named bonus. A
    /// second solve of the same event gives nothing more.
    @discardableResult
    func solveWeatherPuzzle() -> WeatherSolve? {
        guard let p = profile, weatherPuzzleOpen else { return nil }
        let w = weatherNow, t = now()
        let reward = weatherPuzzleReward
        p.weatherRescuedDays = WeatherPuzzlePolicy.rescued(p.weatherRescuedDays, adding: w.eventDay)
        var solve = WeatherSolve(reward: reward, plantArrived: nil, goldenPlant: nil, weathered: badges.progress(of: .weathered))
        if let s = reward.sticker {
            var a = album
            a.add([s.id], on: t)
            p.albumJSON = a.json
        }
        if reward.word { solve.plantArrived = game.grantBonusWord() }
        if reward.goldenDay, let plant = goldenDayPlant() {
            let g = EndgamePolicy.goldenDays(current: plant.goldenDays, lastKey: plant.goldenDayKey, careKey: w.today)
            plant.goldenDays = g.days; plant.goldenDayKey = g.key
            solve.goldenPlant = plant.nickname.isEmpty ? plant.name : plant.nickname
        }
        if reward.badgeStep {
            recordBadgeStep(.weathered, after: 1.2)
            solve.weathered = badges.progress(of: .weathered)
        }
        try? context.save()
        play(.wake)
        return solve
    }

    /// The plant that takes the golden day: the featured one (nearest to golden), if it has not had one today.
    private func goldenDayPlant() -> PlantCollectible? {
        let all = plants()
        let featured = EndgamePolicy.featuredGolden(all.map(\.goldenCandidate), allFound: true, day: weatherToday)
        return all.first { $0.plantId == featured?.id }
    }
}

extension PlantCollectible {
    var goldenCandidate: EndgamePolicy.GoldenCandidate {
        EndgamePolicy.GoldenCandidate(id: plantId, name: nickname.isEmpty ? name : nickname, days: goldenDays, stage: stage)
    }
}

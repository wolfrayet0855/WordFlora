import Foundation

// Garden weather app wiring (docs/pm/endgame-and-events-spec.md sections 3.2-3.4, 3.6, 3.8, 4.2; tickets E-5, E-10,
// E-12). Weather never writes a stage, growth, level or anything earned: it only keeps its own bookkeeping fields.

extension GardenWeather {
    /// The forecast reminder: opt-in, never under 13 or for an unknown age (spec 3.8, decision 6), never in Calm or
    /// Quiet Garden, and only with weather on.
    static func notifyAllowed(ageBand: AgeBand?, calmMode: Bool, quietGarden: Bool, weatherOn: Bool) -> Bool {
        !ParentalGate.isRequired(ageBand: ageBand) && !calmMode && !quietGarden && weatherOn
    }

    /// The latest event still within its linger (for "witnessed first", `weatherSeenAt`).
    static func latestEventDay(_ c: Context, wild: Bool, override: Override? = nil) -> Int? {
        guard isShown(c) else { return nil }
        if let override { return override.event != nil ? c.today : nil }
        let linger = WeatherLook.linger(wild: wild, calm: false, economy: c.economy)
        return WeatherEngine.latestEvent(onOrBefore: c.today, within: linger, seed: c.seed, startDay: c.startDay, economy: c.economy)?.day
    }
}

extension AppModel {
    var weatherToday: Int { WeatherDay.key(nowDate) }

    var weatherContext: GardenWeather.Context {
        let p = profile
        let found = plants().filter { $0.earnedCount > 0 }.count
        let tends = badges.progress(of: .waterings) + badges.progress(of: .feeds)
        return GardenWeather.Context(today: weatherToday, seed: p?.weatherSeed ?? 0, startDay: p?.weatherStartDay ?? 0,
                                     found: found, tends: tends, quietGarden: settings.quietGarden, calmMode: settings.calmMode,
                                     weatherOn: settings.gardenWeather, highWater: p?.weatherHighWaterDay ?? 0,
                                     gatedFromDay: p?.weatherGatedFromDay ?? 0)
    }

    /// Run at launch, on coming to the front and when Home appears: gives a new garden its own seed (never from a device
    /// or user id), keeps the clock high-water mark, and records the first day the gate opened.
    func refreshWeather() {
        guard let p = profile else { return }
        var changed = false
        if p.weatherSeed == 0 || p.weatherStartDay == 0 {
            let pair = WeatherEngine.newSeed(createdAt: p.createdAt)
            p.weatherSeed = pair.seed; p.weatherStartDay = pair.startDay; changed = true
        }
        let today = weatherToday
        let high = WeatherEngine.highWater(current: p.weatherHighWaterDay, today: today)
        if high != p.weatherHighWaterDay { p.weatherHighWaterDay = high; changed = true }
        if p.weatherGatedFromDay == 0 {
            let c = weatherContext
            let gated = WeatherEngine.isGated(found: c.found, tends: c.tends, quietGarden: c.quietGarden, weatherOn: c.weatherOn,
                                              today: today, highWater: c.highWater)
            let day = WeatherEngine.gatedFromDay(current: 0, gatedNow: gated && !settings.calmMode, today: today)
            if day != 0 { p.weatherGatedFromDay = day; changed = true }
        }
        if changed { try? context.save() }
    }

    /// The Home chip, forecast card and event banner for today.
    var homeWeather: GardenWeather.Home {
        GardenWeather.home(weatherContext, cardDismissedDay: settings.weatherCardDismissedDay, override: weatherTestOverride)
    }

    /// "Got it": hides the card for today. The chip stays, and nothing else changes.
    func dismissForecastCard() { settings.weatherCardDismissedDay = weatherToday }

    /// Witnessed first: Home or the garden opened on or after an event day starts its look (spec 3.6).
    func markWeatherSeen() {
        guard let p = profile else { return }
        let day = GardenWeather.latestEventDay(weatherContext, wild: wildWeatherOn, override: weatherTestOverride)
        let seen = GardenWeather.seenAt(current: p.weatherSeenAt, now: nowDate, latestEventDay: day)
        if seen != p.weatherSeenAt { p.weatherSeenAt = seen; try? context.save() }
    }

    // MARK: Wild Weather (E-12; owner ruling 2026-11-05: any age, Calm and Quiet Garden hide it)

    /// The toggle shows only with Calm off, Quiet Garden off and Garden weather on.
    var wildWeatherAvailable: Bool {
        settings.gardenWeather
            && WeatherLook.wildAvailable(ageBand: settings.ageBand, calmMode: settings.calmMode, quietGarden: settings.quietGarden)
    }

    /// In effect only when chosen and still available; turning on Calm or weather off stops it at once.
    var wildWeatherOn: Bool { wildWeatherAvailable && (profile?.wildWeather ?? false) }

    /// The player's own choice, after the confirmation card. Off always works; on only where it is available.
    func setWildWeather(_ on: Bool) {
        guard let p = profile, !on || wildWeatherAvailable else { return }
        p.wildWeather = on
        try? context.save()
    }

    // MARK: Each plant's weather look (computed, never stored)

    /// Weather inputs for every found plant, for the plant page (LifeStats `weather`) and the level map. Empty when weather
    /// is hidden (Calm, Quiet Garden, weather off, the gate) or no event is within reach.
    func weatherInputs() -> [String: WeatherLook.Input] {
        guard let p = profile else { return [:] }
        let c = weatherContext
        guard GardenWeather.isShown(c) else { return [:] }
        let wild = wildWeatherOn
        let found_: (kind: WeatherKind, day: Int)?
        if let o = weatherTestOverride {
            found_ = o.event.map { (kind: $0, day: c.today) }
        } else {
            found_ = WeatherEngine.latestEvent(onOrBefore: c.today, within: WeatherLook.linger(wild: wild, calm: false, economy: c.economy),
                                               seed: c.seed, startDay: c.startDay, economy: c.economy)
        }
        guard let ev = found_ else { return [:] }
        let found = plants().filter { $0.earnedCount > 0 }
        let traits = Self.plantTraits
        let pairs = found.map { (id: $0.plantId, traits: traits[$0.plantId] ?? []) }
        let effects = WeatherEngine.affected(ev.kind, plants: pairs, day: ev.day, cap: c.economy.weatherAffectedCap)
        let ranks = WeatherEngine.fullRanks(ev.kind, plants: pairs, day: ev.day, cap: c.economy.weatherAffectedCap)
        var out: [String: WeatherLook.Input] = [:]
        for plant in found {
            let love = loveState(plant)
            out[plant.plantId] = WeatherLook.Input(
                kind: ev.kind, eventDay: ev.day, today: c.today, effect: effects[plant.plantId] ?? .light,
                lastCareAt: WeatherLook.careAt(lastTendedAt: plant.lastTendedAt, lastLovedAt: plant.lastLovedAt),
                seenAt: p.weatherSeenAt, sheltered: p.weatherShelterDay == ev.day, rescued: p.weatherRescuedDays.contains(ev.day),
                wild: wild, stage: plant.stage, rank: ranks[plant.plantId] ?? Int.max, calm: false, isSeed: love.isSeed,
                loveRaining: love.raining, name: plant.nickname.isEmpty ? plant.name : plant.nickname)
        }
        return out
    }

    func weatherLooks() -> [String: WeatherLook.Output] {
        weatherInputs().mapValues(WeatherLook.compute).filter { !$0.value.isEmpty }
    }

    /// A small, stable key for this plant's weather state ("" = no weather), for a "changed since last visit" check
    /// (the Life panel can store the key it last showed and open itself when it differs). Changes when an event's look
    /// starts, mends, shelters, dips or passes; the same on every launch within one state.
    func weatherChangeKey(for plant: PlantCollectible) -> String {
        guard let input = weatherInputs()[plant.plantId] else { return "" }
        let out = WeatherLook.compute(input)
        guard !out.isEmpty, let kind = input.kind else { return "" }
        return "\(input.eventDay):\(kind.rawValue):\(out.look?.rawValue ?? "-"):\(out.setback):\(out.mending ? 1 : 0)"
    }

    /// Wild Weather's level ring: per level, how many full-bloom plants show a stage lower for now (the dashed
    /// "mending" segment). Earned values, the word level and garden-level completion never read this.
    func levelMending() -> [Int: Int] {
        let looks = weatherLooks()
        guard !looks.isEmpty else { return [:] }
        var out: [Int: Int] = [:]
        for plant in plants() where plant.stage >= 4 {
            if let l = looks[plant.plantId], l.setback > 0 { out[plant.level, default: 0] += 1 }
        }
        return out
    }

    private static let plantTraits: [String: Set<String>] = {
        Dictionary(((try? PlantCatalog.load()) ?? []).map { ($0.plantId, $0.traitSet) }, uniquingKeysWith: { a, _ in a })
    }()

    // MARK: Forecast reminder (E-10)

    var weatherNotifyAvailable: Bool {
        settings.remindMe && GardenWeather.notifyAllowed(ageBand: settings.ageBand, calmMode: settings.calmMode,
                                                         quietGarden: settings.quietGarden, weatherOn: settings.gardenWeather)
    }

    /// What a reminder on `date` should say about the weather (nil: the ordinary reminder).
    var reminderForecast: (Date) -> WeatherKind? {
        let c = weatherContext, opted = settings.weatherNotify, allowed = weatherNotifyAvailable
        return { GardenWeather.reminderForecast(on: $0, c, optedIn: opted, notifyAllowed: allowed) }
    }
}

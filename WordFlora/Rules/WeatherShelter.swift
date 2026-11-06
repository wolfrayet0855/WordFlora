import Foundation

// Weather helpers (docs/pm/endgame-and-events-spec.md section 3.7, ticket E-7). All six arrive together as a free
// weather kit with the first forecast the player can see; they are never sold, never used up and never locked. Setting
// one out changes the picture (a snug garden), never a number, and leaving them in the Shed costs nothing.

/// The weather right now for one player, from the pure engine and the profile's fields. Builder A's launch wiring
/// (seed, high-water day, gated-from day, the Garden weather setting) feeds it; this type only reads.
struct GardenWeatherNow: Equatable {
    /// Today's day key.
    var today: Int
    /// Weather may show today (Quiet Garden off, the setting on, the clock sane, enough plants and tends).
    var gated: Bool
    /// Calm mode: looks only. No helpers, no puzzle prompt, no to-do list for a young child.
    var calm: Bool
    /// Wild Weather is active (13+ opt-in, Calm off).
    var wild: Bool
    /// Tomorrow's weather, shown today as the forecast. Nil when not gated.
    var forecast: WeatherKind?
    /// The latest event within the puzzle window (the event day and the 3 days after). Nil when not gated.
    var event: WeatherKind?
    /// That event's day key (0 when there is none).
    var eventDay: Int

    /// Helpers and the puzzle show only when weather shows and Calm is off.
    var showsMechanics: Bool { gated && !calm }

    static let none = GardenWeatherNow(today: 0, gated: false, calm: false, wild: false, forecast: nil, event: nil, eventDay: 0)

    /// Everything from the stored fields and settings; never writes.
    static func compute(seed: Int64, startDay: Int, today: Int, highWater: Int, gatedFromDay: Int, found: Int, tends: Int,
                        quietGarden: Bool, weatherOn: Bool, calm: Bool, wild: Bool,
                        economy: Economy = .default) -> GardenWeatherNow {
        let gated = WeatherEngine.isGated(found: found, tends: tends, quietGarden: quietGarden, weatherOn: weatherOn, today: today,
                                          highWater: highWater, gatedFromDay: gatedFromDay, economy: economy)
        guard gated, seed != 0, startDay != 0 else {
            return GardenWeatherNow(today: today, gated: gated && seed != 0 && startDay != 0, calm: calm, wild: false,
                                    forecast: nil, event: nil, eventDay: 0)
        }
        let forecast = WeatherEngine.forecast(day: today, seed: seed, startDay: startDay, economy: economy)
        let latest = WeatherEngine.latestEvent(onOrBefore: today, within: max(1, economy.weatherPuzzleDays), seed: seed,
                                               startDay: startDay, economy: economy)
        return GardenWeatherNow(today: today, gated: true, calm: calm, wild: wild && !calm, forecast: forecast,
                                event: latest?.kind, eventDay: latest?.day ?? 0)
    }
}

/// The six helpers. Each one shelters from one or two kinds.
enum WeatherHelper: String, CaseIterable, Identifiable {
    case shadeCloth, bugCover, windNet, frostCloth, umbrella, raisedBed

    var id: String { rawValue }

    var kinds: [WeatherKind] {
        switch self {
        case .shadeCloth: return [.drySpell, .hotDay]
        case .bugCover: return [.busyBugs]
        case .windNet: return [.bigWind]
        case .frostCloth: return [.frostyNight]
        case .umbrella: return [.hailShower]
        case .raisedBed: return [.bigPuddles]
        }
    }

    static func helper(for kind: WeatherKind) -> WeatherHelper {
        allCases.first { $0.kinds.contains(kind) } ?? .shadeCloth
    }

    /// An SF Symbol used until the drawn helper art lands.
    var symbol: String {
        switch self {
        case .shadeCloth: return "sun.haze"
        case .bugCover: return "ladybug"
        case .windNet: return "wind"
        case .frostCloth: return "snowflake"
        case .umbrella: return "umbrella"
        case .raisedBed: return "leaf"
        }
    }
}

enum ShelterPolicy {
    /// What a helper's row shows in the Shed.
    enum HelperState: Equatable {
        /// In the kit, nothing to do.
        case ready
        /// This helper fits tomorrow's (or today's) weather and can be set out with one tap.
        case canSetOut
        /// Set out for the coming weather.
        case setOut
    }

    /// The weather a set-out now would cover: tomorrow's forecast first (the day before), else today's event.
    static func coverable(_ w: GardenWeatherNow) -> (kind: WeatherKind, day: Int)? {
        guard w.showsMechanics else { return nil }
        if let f = w.forecast { return (f, w.today + 1) }
        if let e = w.event, w.eventDay == w.today { return (e, w.today) }
        return nil
    }

    static func state(_ helper: WeatherHelper, weather w: GardenWeatherNow, shelterDay: Int) -> HelperState {
        guard let c = coverable(w), WeatherHelper.helper(for: c.kind) == helper else { return .ready }
        return shelterDay == c.day ? .setOut : .canSetOut
    }

    /// The new `weatherShelterDay` after one tap on Set out. It never goes down (merge: max), and nothing is spent.
    static func setOut(weather w: GardenWeatherNow, shelterDay: Int) -> Int {
        guard let c = coverable(w) else { return shelterDay }
        return max(shelterDay, c.day)
    }

    /// True when the helpers were set out for this event, so its plants stay snug.
    static func isSheltered(shelterDay: Int, eventDay: Int) -> Bool { eventDay != 0 && shelterDay == eventDay }

    /// The Shed shows the helpers once the kit has arrived and weather mechanics show (never in Calm or Quiet Garden).
    static func showsHelpers(kitAt: Date?, weather w: GardenWeatherNow) -> Bool { kitAt != nil && w.showsMechanics }

    /// The kit arrives with the first forecast the player can see, and never in Calm (looks only).
    static func kitDue(kitAt: Date?, weather w: GardenWeatherNow) -> Bool {
        WeatherEngine.kitArrives(forecastToday: w.forecast != nil, gated: w.showsMechanics, kitAt: kitAt)
    }
}

/// Every Shed helper line, grade 2-3 and positive only (CopySafety plus the weather avoid list in tests).
enum ShelterCopy {
    static let sectionTitle = "Weather helpers"
    static let sectionLine = "A weather kit for you, from the Shed. Set out the helper for tomorrow's weather."
    static let sectionLineNoForecast = "Your weather kit is here. When a weather day comes, set out its helper."
    static let ready = "Ready"
    static let setOut = "Set out"
    static let isOut = "Out"

    static func name(_ h: WeatherHelper) -> String {
        switch h {
        case .shadeCloth: return "Shade cloth"
        case .bugCover: return "Bug cover"
        case .windNet: return "Wind net"
        case .frostCloth: return "Frost cloth"
        case .umbrella: return "Garden umbrella"
        case .raisedBed: return "Raised bed"
        }
    }

    static func blurb(_ h: WeatherHelper) -> String {
        switch h {
        case .shadeCloth: return "For a dry spell or a hot day."
        case .bugCover: return "For busy bugs. No sprays."
        case .windNet: return "For a big wind."
        case .frostCloth: return "For a frosty night."
        case .umbrella: return "For a hail shower."
        case .raisedBed: return "For big puddles."
        }
    }

    static func chip(_ k: WeatherKind, today: Bool) -> String {
        today ? "Today: \(WeatherCopy.name(k).lowercased())" : "Tomorrow: \(WeatherCopy.name(k).lowercased())"
    }

    /// VoiceOver for one row: "Wind net. For a big wind. Set out." / "... Ready."
    static func rowLabel(_ h: WeatherHelper, state: ShelterPolicy.HelperState) -> String {
        let s: String
        switch state {
        case .ready: s = ready
        case .canSetOut: s = "Ready to set out"
        case .setOut: s = "Set out for the weather"
        }
        return "\(name(h)). \(blurb(h)) \(s)."
    }

    static let setOutHint = "Sets it out for the weather. It costs nothing."

    /// The forecast card's step: "Set out the wind net", then "The wind net is out for your whole garden."
    static func cardStep(_ h: WeatherHelper) -> String { "Set out the \(name(h).lowercased())" }
    static func cardDone(_ h: WeatherHelper) -> String { "The \(name(h).lowercased()) is out for your whole garden." }

    static func all() -> [String] {
        WeatherHelper.allCases.flatMap { h in
            [name(h), blurb(h), rowLabel(h, state: .ready), rowLabel(h, state: .canSetOut), rowLabel(h, state: .setOut), cardStep(h), cardDone(h)]
        } + WeatherKind.allCases.flatMap { [chip($0, today: true), chip($0, today: false)] }
          + [sectionTitle, sectionLine, sectionLineNoForecast, ready, setOut, isOut, setOutHint]
    }
}

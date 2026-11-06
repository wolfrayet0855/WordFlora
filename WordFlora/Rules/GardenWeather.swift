import Foundation

/// What garden weather shows outside the plant page: the Home chip, forecast card and event banner, the widget line and
/// the forecast reminder (docs/pm/endgame-and-events-spec.md sections 3.4, 3.8, 4.5; tickets E-5, E-10). Pure, and in
/// the widget target too, so the widget draws the same forecast from the shared store with no background task.
///
/// Owner, 2026-11-05: the one Calm toggle decides. Calm on = weather hidden and off; Calm off = weather at any age.
/// Quiet Garden hides it too. Weather never touches a stored value; it is a look and a heads-up only.
enum GardenWeather {
    struct Context: Equatable {
        var today: Int
        var seed: Int64
        var startDay: Int
        /// Plants found and tending actions so far (the gate); ignored once `gatedFromDay` is set.
        var found: Int
        var tends: Int
        var quietGarden: Bool
        var calmMode: Bool
        /// The Garden weather setting (already false in Calm).
        var weatherOn: Bool
        var highWater: Int
        var gatedFromDay: Int
        var economy: Economy = .default
    }

    /// UI tests (`-uitest-forecast=`, `-uitest-weather=`) replace the schedule; every gate still applies.
    struct Override: Equatable {
        var forecast: WeatherKind?
        var event: WeatherKind?
        init(forecast: WeatherKind? = nil, event: WeatherKind? = nil) { self.forecast = forecast; self.event = event }
    }

    struct Home: Equatable {
        /// "Tomorrow: windy" beside the Garden Days line.
        var chip: String?
        var chipKind: WeatherKind?
        /// The forecast card (the day before, until "Got it").
        var card: WeatherKind?
        /// The soft event-day banner.
        var banner: WeatherKind?

        /// No Plus offer and no ad in a visit that shows a forecast or the weather (spec section 8).
        var quietsOffers: Bool { card != nil || banner != nil }
    }

    /// The Garden weather setting's default: on unless Calm mode is on.
    static func defaultOn(calmMode: Bool) -> Bool { WeatherEngine.defaultWeatherOn(calmMode: calmMode) }

    static func isShown(_ c: Context) -> Bool {
        guard !c.calmMode else { return false }
        return WeatherEngine.isGated(found: c.found, tends: c.tends, quietGarden: c.quietGarden, weatherOn: c.weatherOn,
                                     today: c.today, highWater: c.highWater, gatedFromDay: c.gatedFromDay, economy: c.economy)
    }

    static func forecast(_ c: Context, override: Override? = nil) -> WeatherKind? {
        guard isShown(c) else { return nil }
        if let override { return override.forecast }
        return WeatherEngine.forecast(day: c.today, seed: c.seed, startDay: c.startDay, economy: c.economy)
    }

    static func event(_ c: Context, override: Override? = nil) -> WeatherKind? {
        guard isShown(c) else { return nil }
        if let override { return override.event }
        return WeatherEngine.event(day: c.today, seed: c.seed, startDay: c.startDay, economy: c.economy)
    }

    static func home(_ c: Context, cardDismissedDay: Int, override: Override? = nil) -> Home {
        var h = Home()
        if let k = forecast(c, override: override) {
            h.chip = WeatherCopy.forecastChip(k); h.chipKind = k
            if cardDismissedDay != c.today { h.card = k }
        }
        if let k = event(c, override: override) { h.banner = k }
        return h
    }

    // MARK: Widget

    /// The widget has no badge counts, so it relies on the stored gate day (set by the app the first day the gate opens).
    static func widgetContext(profile p: PlayerProfile, today: Int, quietGarden: Bool, calmMode: Bool, weatherOn: Bool) -> Context {
        Context(today: today, seed: p.weatherSeed, startDay: p.weatherStartDay, found: 0, tends: 0, quietGarden: quietGarden,
                calmMode: calmMode, weatherOn: weatherOn, highWater: p.weatherHighWaterDay, gatedFromDay: p.weatherGatedFromDay)
    }

    /// "Tomorrow: a big wind. Your garden is ready." on the medium and Lock Screen widgets.
    static func widgetLine(_ c: Context) -> String? { forecast(c).map(WeatherCopy.widgetLine) }
    /// "Tomorrow: windy" on the small widget.
    static func widgetChip(_ c: Context) -> String? { forecast(c).map(WeatherCopy.forecastChip) }

    // MARK: Reminder (shares the one daily slot)

    /// The weather a reminder at `date` should mention: the forecast for that day. The gate is judged as of today.
    static func reminderForecast(on date: Date, _ c: Context, optedIn: Bool, notifyAllowed: Bool,
                                 timeZone: TimeZone = .current) -> WeatherKind? {
        guard optedIn, notifyAllowed, isShown(c) else { return nil }
        return WeatherEngine.forecast(day: WeatherDay.key(date, timeZone: timeZone), seed: c.seed, startDay: c.startDay, economy: c.economy)
    }

    // MARK: Witnessed first

    /// The value to store in `weatherSeenAt`: set on the first look on or after the latest event day, then kept, so care
    /// given after that first look keeps counting as a mend.
    static func seenAt(current: Date?, now: Date, latestEventDay: Int?, timeZone: TimeZone = .current) -> Date? {
        guard let day = latestEventDay, !WeatherEngine.seenCounts(current, eventDay: day, timeZone: timeZone) else { return current }
        return now
    }
}

/// The new weather lines for Home, Settings, the widget and the reminder. Grade 2-3, calm, positive only; checked by
/// CopySafety and the weather avoid list in tests.
enum WeatherUICopy {
    // Settings
    static let sectionTitle = "Garden weather"
    static let toggle = "Garden weather"
    static let footnote = "Now and then, weather visits your garden. Plants look a little different for a few days, and care helps them perk up. Your plants and your level stay just as they are."
    static let calmFootnote = "Calm mode keeps the weather away. Turn Calm mode off to have weather in your garden."
    static let wildToggle = "Wild Weather"
    static let wildFootnote = "A bigger challenge, if you like. A big storm can make up to 4 plants look one step smaller for a few days. You can turn it off at any time."
    static let wildConfirmTitle = "Turn on Wild Weather?"
    static let wildConfirmMessage = "A big storm can make up to 4 plants look one step smaller. Care, a weather puzzle or time brings them back within 4 days. Your level and your plants stay just as they are."
    /// Shown under the Wild Weather switch for under-13 players only (any age may still choose it).
    static let wildGrownUpNote = "Ask a grown-up if you like."
    static let wildConfirm = "Turn it on"
    static let wildCancel = "Not now"
    static let notifyToggle = "Tell me about garden weather"
    static let notifyFootnote = "The day before weather comes, your daily reminder tells you. No extra reminders."

    // Home
    static let cardLine = WeatherCopy.forecastStepCare
    static let cardReady = WeatherCopy.gardenReady
    static let gotIt = WeatherCopy.forecastGotIt
    static let gotItHint = "Hides this card for today."
    static let bannerLine = "Care helps your plants perk up."
    static func chipLabel(_ chip: String) -> String { "Garden forecast. \(chip)" }

    // Reminder
    static let notificationBody = "Give a drink or a hello today. Your garden is ready."

    static var all: [String] {
        [sectionTitle, toggle, footnote, calmFootnote, wildToggle, wildFootnote, wildGrownUpNote, wildConfirmTitle, wildConfirmMessage, wildConfirm,
         wildCancel, notifyToggle, notifyFootnote, cardLine, cardReady, gotIt, gotItHint, bannerLine, notificationBody]
            + WeatherKind.allCases.flatMap { k in
                [chipLabel(WeatherCopy.forecastChip(k)), WeatherCopy.forecastTitle(k), WeatherCopy.eventLine(k),
                 WeatherCopy.widgetLine(k), WeatherCopy.notificationTitle(k)]
            }
    }
}

import Foundation

/// What one plant shows for the garden's weather (docs/pm/endgame-and-events-spec.md sections 3.6, 4 and 6), computed at
/// display time and never written back.
/// - Variant 1, "Weather, not loss" (everyone with Garden weather on): only the look changes. Care after the player has
///   seen the weather mends a plant at once; otherwise the look fades after `weatherLingerDays` (Calm: `calmLingerDays`).
/// - Variant 2, "Wild Weather" (opt-in at any age, Calm and Quiet Garden off): on big events up to `wildMaxPlants` full-effect
///   plants (half that when sheltered) also show one stage lower. Care stands a plant tall the next day, the puzzle
///   restores all at once, and everything mends by itself after `wildLingerDays`. The stored stage never changes.
enum WeatherLook {
    struct Input: Equatable {
        /// The latest event's kind, or nil when there is none in reach.
        var kind: WeatherKind?
        /// The event's day key.
        var eventDay: Int
        /// Today's day key.
        var today: Int
        /// This plant's effect from `WeatherEngine.affected` (the 40% cap already applied).
        var effect: WeatherEffect
        /// The plant's latest care: `max(lastTendedAt, lastLovedAt)`, see `careAt`.
        var lastCareAt: Date?
        /// `PlayerProfile.weatherSeenAt`: the look starts only once the garden has been seen on or after the event day.
        var seenAt: Date?
        /// The helpers were set out for this event (`weatherShelterDay == eventDay`).
        var sheltered: Bool
        /// This event's puzzle is solved (`weatherRescuedDays` holds the event day).
        var rescued: Bool
        /// Wild Weather is on (see `wildActive`).
        var wild: Bool
        /// The stored stage, read only.
        var stage: Int
        /// The plant's index among the capped full-effect plants (`WeatherEngine.fullRanks`); any large number when none.
        var rank: Int
        /// Calm mode: the look lasts one day and Wild Weather never applies.
        var calm = false
        /// A resting seed (0 love petals) shows no weather.
        var isSeed = false
        /// Love rain wins: while it rains for want of a hello, the weather look waits.
        var loveRaining = false
        /// The plant's name, for its line.
        var name = ""
        var timeZone: TimeZone = .current
        var economy: Economy = .default

        var lastCareDay: Int? { lastCareAt.map { WeatherDay.key($0, timeZone: timeZone) } }
    }

    struct Output: Equatable {
        /// The look to draw, or nil for none.
        var look: WeatherEffect?
        /// Wild Weather only: how far the shown stage dips (0 or 1). Never stored.
        var setback: Int
        /// The stage to draw: `stage - setback`, never below 1 when a setback applies.
        var shownStage: Int
        /// The plant page line (empty when there is nothing to show).
        var line: String
        /// Wild Weather: cared for today, standing tall tomorrow (the level ring's dashed "mending" segment).
        var mending = false

        var isEmpty: Bool { look == nil && setback == 0 && !mending }
    }

    /// The mend signal: any tending or a hello.
    static func careAt(lastTendedAt: Date?, lastLovedAt: Date?) -> Date? { [lastTendedAt, lastLovedAt].compactMap { $0 }.max() }

    /// How many days an event's look lasts, counting the event day.
    static func linger(wild: Bool, calm: Bool, economy: Economy = .default) -> Int {
        if calm { return economy.calmLingerDays }
        return wild ? economy.wildLingerDays : economy.weatherLingerDays
    }

    static func compute(_ i: Input) -> Output {
        let stage = min(max(i.stage, 0), 4)
        let nothing = Output(look: nil, setback: 0, shownStage: stage, line: "")
        guard let kind = i.kind, !i.isSeed, !i.loveRaining, !i.rescued else { return nothing }
        let wild = i.wild && !i.calm
        // Presence rule: only from the event day to the end of its linger.
        let age = i.today - i.eventDay
        guard age >= 0, age < linger(wild: wild, calm: i.calm, economy: i.economy) else { return nothing }
        // Witnessed first: nothing until the garden has been seen on or after the event day.
        guard let seen = i.seenAt else { return nothing }
        let seenDay = WeatherDay.key(seen, timeZone: i.timeZone)
        guard seenDay >= i.eventDay, seenDay <= i.today else { return nothing }
        // Care after seeing it mends: at once in Variant 1, the next day in Wild Weather.
        var mending = false
        if let care = i.lastCareAt, care > seen {
            guard wild, let careDay = i.lastCareDay, i.today <= careDay else { return nothing }
            mending = true
        }

        if i.effect == .shrugs {
            return Output(look: .shrugs, setback: 0, shownStage: stage, line: WeatherCopy.shrugLine(name: i.name, kind))
        }
        let limit = i.sheltered ? i.economy.wildMaxPlantsSheltered : i.economy.wildMaxPlants
        let dips = wild && kind.isBig && i.effect == .full && (0..<limit).contains(i.rank) && stage >= 2
        let setback = dips ? min(max(0, i.economy.wildSetback), stage - 1) : 0
        if setback > 0 {
            let line = mending ? WeatherCopy.mendingLine(name: i.name) : WeatherCopy.wildLine(name: i.name, kind)
            return Output(look: .full, setback: setback, shownStage: stage - setback, line: line, mending: mending)
        }
        if i.sheltered || i.effect == .snug {
            return Output(look: .snug, setback: 0, shownStage: stage, line: WeatherCopy.snugLine(name: i.name, kind))
        }
        let line = mending ? WeatherCopy.mendingLine(name: i.name) : WeatherCopy.plantLine(name: i.name, kind)
        return Output(look: i.effect, setback: 0, shownStage: stage, line: line, mending: mending)
    }

    // MARK: Who may have Wild Weather (spec 4.2; owner ruling 2026-11-05 replaces the 13+ gate)

    /// Any age may opt in, with Calm off and Quiet Garden off (the one Calm toggle decides; under 13 starts in Calm).
    /// `ageBand` is kept so callers stay unchanged; it no longer gates anything.
    static func wildAvailable(ageBand: AgeBand?, calmMode: Bool, quietGarden: Bool) -> Bool {
        !calmMode && !quietGarden
    }

    /// Wild Weather applies only when the player opted in and still may have it (Calm or Quiet Garden hide it at once).
    static func wildActive(optedIn: Bool, ageBand: AgeBand?, calmMode: Bool, quietGarden: Bool) -> Bool {
        optedIn && wildAvailable(ageBand: ageBand, calmMode: calmMode, quietGarden: quietGarden)
    }
}

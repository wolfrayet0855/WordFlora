import Foundation

/// The plant page's Life panel: soft meters, a stage path, today's hearts and the love petals, all read from data the
/// plant already keeps. THE RULE (2026-11-04): each meter shows only its own action's allowance for today, read through
/// the same `TendingEngine` helpers the actions use, so a meter that is not full always means its button works, and a
/// full meter means that action is done for today. Meters never reach empty, never use red and never show numbers.
enum LifeStats {
    struct Inputs {
        var lastSunnyAt: Date?
        var lastLovedAt: Date?
        var lastFedAt: Date?
        var lastPrunedAt: Date?
        var soilRichness: Double
        var stage: Int
        var waterToday: Int
        var waterDay: Date?
        var now: Date
        var calendar: Calendar
        /// Quiet Garden or Calm mode: no rain, no falling petals, no seed.
        var exempt: Bool
        var economy: Economy = .default
        /// Today's garden weather for this plant, when there is any. It only adds `Snapshot.weather`: the meters,
        /// hearts and stored stage never change because of weather.
        var weather: WeatherLook.Input? = nil
    }

    struct Meter: Equatable {
        var name: String
        var word: String
        /// 0...1, never below `floor`.
        var fill: Double
        /// This meter's action is done for today (its button shows the done state).
        var done = false
        var accessibilityLabel: String { "\(name), \(word.lowercased())" }
    }

    struct Weather: Equatable { var drops: Int; var thunder: Bool }

    struct Snapshot: Equatable {
        var water: Meter
        var sunshine: Meter
        var happiness: Meter
        var stage: Int
        var hearts: Int
        var loveLine: String
        var pips: Int
        var isSeed: Bool
        /// Days without love while it rains (0 when dry, exempt or resting as a seed).
        var rainDay: Int
        /// The weather look and any shown-stage dip, computed only (nil when there is nothing to show).
        var weather: WeatherLook.Output? = nil

        /// Wild Weather's shown-stage dip: the stage the page draws (display only; `stage` stays the stored one).
        var shownStage: Int { dipped ? max(0, min(4, weather?.shownStage ?? stage)) : stage }
        var dipped: Bool { (weather?.setback ?? 0) > 0 }

        var stageLabel: String {
            "Growing, \(LifeStats.stageNames[shownStage].lowercased()) stage" + (dipped ? ". \(LifeStats.mendingNote)" : "")
        }
        var heartsLabel: String { "Energy, \(hearts) of 5 hearts. \(loveLine)" }
    }

    static let floor = 0.3
    /// The fill a meter shows when its action is ready and not yet done today. Today's share of the allowance fills the
    /// rest, so water reads 0.5 / 0.75 / 1.0 for 0 / 1 / 2 drinks. Shorter bars fail the accessibility contrast audit.
    static let readyFill = 0.5
    static let stageNames = ["Tiny", "Sprout", "Bud", "Bloom", "Full bloom"]

    // MARK: Copy (every visible or spoken line on the panel lives here so the copy test can read it all)

    static let title = "Life"
    /// Under the stage path while Wild Weather shows a plant one stage smaller.
    static let mendingNote = "Resting after the weather. Care helps it stand tall."
    static let hideLabel = "Hide Life panel"
    static let showLabel = "Show Life panel"
    static let keyLine = "Love keeps its petals."
    static let growingTitle = "Growing"
    static let energyTitle = "Energy"
    static let meterNames = (water: "Water", sunshine: "Sunshine", happiness: "Happiness")
    static let waterWords = ["Full", "Good", "Ready for a drink"]
    static let sunWords = ["Bright", "Ready for sun"]
    static let happyWords = ["Happy", "Cosy"]
    static let restWord = "Resting"
    static let loveLines = ["Full of energy", "Lots of energy", "Hellos help", "Ready for a hello", "Ready for you"]
    static let gentleRain = "Gentle rain"
    static let rainAndThunder = "Rain and soft thunder"

    static func plantLabel(name: String, pips: Int) -> String { "\(name), \(pips) of 5 love petals" }
    /// Beside the love petal row: "3 love petals".
    static func pipCaption(pips: Int) -> String { pips == 1 ? "1 love petal" : "\(pips) love petals" }
    static func seedLabel(name: String) -> String { "\(name), resting as a seed in its pot" }
    static func keyLabel(pips: Int) -> String { "\(pips) of 5 love petals. \(keyLine)" }
    static func hint(name: String) -> String { "Tap \(name) to give love" }
    static func rainAnnouncement(name: String) -> String { "A rainy day for \(name)." }
    static func badge(thunder: Bool) -> String { thunder ? rainAndThunder : gentleRain }
    static func stageWord(_ stage: Int, seed: Bool) -> String {
        let s = stageNames[min(max(stage, 0), 4)]
        return seed ? "\(s) kept safe" : "\(s) stage"
    }

    static func allCopy(name: String) -> [String] {
        [title, hideLabel, showLabel, keyLine, growingTitle, energyTitle, meterNames.water, meterNames.sunshine, meterNames.happiness,
         restWord, gentleRain, rainAndThunder, plantLabel(name: name, pips: 3), seedLabel(name: name), keyLabel(pips: 2), hint(name: name),
         rainAnnouncement(name: name)]
            + waterWords + sunWords + happyWords + loveLines + stageNames
            + (0...4).flatMap { [stageWord($0, seed: true), stageWord($0, seed: false)] }
    }

    // MARK: Mapping

    static func snapshot(_ i: Inputs) -> Snapshot {
        let love = LoveEngine.state(lastLoved: i.lastLovedAt, now: i.now, exempt: i.exempt)
        let stage = min(max(i.stage, 0), 4)
        let rainDay = love.raining && !love.isSeed ? days(since: i.lastLovedAt, now: i.now) : 0
        if love.isSeed {
            let rest = { (n: String) in Meter(name: n, word: restWord, fill: 0.35) }
            return Snapshot(water: rest(meterNames.water), sunshine: rest(meterNames.sunshine), happiness: rest(meterNames.happiness),
                            stage: stage, hearts: 0, loveLine: loveLines[4], pips: 0, isSeed: true, rainDay: 0)
        }

        let drinks = TendingEngine.todayCount(i.waterToday, day: i.waterDay, now: i.now, calendar: i.calendar)
        let perDay = max(1, i.economy.waterPerDay)
        let water: Meter = {
            let fraction = min(1, Double(drinks) / Double(perDay))
            let word = drinks >= perDay ? waterWords[0] : (drinks > 0 ? waterWords[1] : waterWords[2])
            return Meter(name: meterNames.water, word: word, fill: readyFill + (1 - readyFill) * fraction, done: drinks >= perDay)
        }()

        // Bright only when sunned today. Rain does not change this.
        let sunnedToday = TendingEngine.isToday(i.lastSunnyAt, now: i.now, calendar: i.calendar)
        let sunshine = Meter(name: meterNames.sunshine, word: sunnedToday ? sunWords[0] : sunWords[1],
                             fill: sunnedToday ? 1 : readyFill, done: sunnedToday)

        let happiness: Meter = {
            let score = Double(love.petalsLeft) / 5 * 0.7 + min(max(i.soilRichness, 0), 1) * 0.3
            return Meter(name: meterNames.happiness, word: score >= 0.65 ? happyWords[0] : happyWords[1], fill: 0.35 + 0.55 * score)
        }()

        // Five hearts, all reachable by every player on one day: a hello, a drink, sun, soil, and a finishing touch
        // (the second drink of the day, or a prune). Pruning needs shears and rests two days, so it is never the only way.
        // A repot does not count: no timestamp records an ordinary repot (lastRepotGrowthAt is the happy-match growth only).
        let lovedToday = i.lastLovedAt.map { i.calendar.isDate($0, inSameDayAs: i.now) && $0 <= i.now } ?? false
        let finishingTouch = drinks >= perDay || TendingEngine.isToday(i.lastPrunedAt, now: i.now, calendar: i.calendar)
        let kinds = [drinks > 0, sunnedToday, TendingEngine.isToday(i.lastFedAt, now: i.now, calendar: i.calendar),
                     finishingTouch].filter { $0 }.count
        let hearts = lovedToday ? min(5, 1 + kinds) : 0
        let line: String = {
            switch hearts {
            case 5: return loveLines[0]
            case 3...4: return loveLines[1]
            case 1...2: return loveLines[2]
            default: return loveLines[3]
            }
        }()

        return Snapshot(water: water, sunshine: sunshine, happiness: happiness, stage: stage, hearts: hearts, loveLine: line,
                        pips: love.petalsLeft, isSeed: false, rainDay: rainDay, weather: weatherOutput(i, love: love))
    }

    /// The weather overlay for this plant. Love rain wins and a resting seed shows none; nothing else on the panel changes.
    private static func weatherOutput(_ i: Inputs, love: LoveEngine.State) -> WeatherLook.Output? {
        guard var w = i.weather else { return nil }
        w.loveRaining = w.loveRaining || love.raining
        w.isSeed = w.isSeed || love.isSeed
        w.stage = i.stage
        let out = WeatherLook.compute(w)
        return out.isEmpty ? nil : out
    }

    /// Rain grows a little steadier each day without love; soft thunder joins from day four.
    static func weather(day: Int) -> Weather {
        guard day > 0 else { return Weather(drops: 0, thunder: false) }
        let drops = [12, 20, 32, 42, 50, 56, 60]
        return Weather(drops: drops[min(day, 7) - 1], thunder: day >= 4)
    }

    private static func days(since d: Date?, now: Date) -> Int {
        guard let d, now > d else { return 0 }
        return Int(now.timeIntervalSince(d) / 86_400)
    }
}

/// Gentle thunder: one slow flash at most every 8 seconds, dim (16% white in light, 10% in dark), a soft haptic just after.
enum ThunderGate {
    static let minGap: TimeInterval = 8
    static let flashDuration: TimeInterval = 1.4

    static func canFlash(lastFlash: Date?, now: Date) -> Bool {
        guard let lastFlash else { return true }
        return now.timeIntervalSince(lastFlash) >= minGap
    }
    static func peakOpacity(dark: Bool) -> Double { dark ? 0.10 : 0.16 }
    /// `unit` is a random number in 0...1.
    static func nextDelay(unit: Double) -> TimeInterval { 8 + 7 * min(max(unit, 0), 1) }
    static func hapticDelay(unit: Double) -> TimeInterval { 0.3 + 0.2 * min(max(unit, 0), 1) }

    /// The soft thunder roll plays at this share of the player's level.
    static let soundVolume: Float = 0.35
    /// Sound follows light, from far away: the roll starts 1.5 to 3 s after the flash begins.
    static func soundDelay(unit: Double) -> TimeInterval { 1.5 + 1.5 * min(max(unit, 0), 1) }
    /// The first flash waits 4 to 6 s after the page opens, so the child has settled.
    static func firstFlashDelay(unit: Double) -> TimeInterval { 4 + 2 * min(max(unit, 0), 1) }
    /// At most one roll every 3 minutes across the whole app (hopping between plants must not stack rolls).
    static let rollCooldown: TimeInterval = 180
    /// Only the first flash of a plant-page visit rolls, and only when no roll played in the last 3 minutes.
    static func shouldSound(playedThisVisit: Bool, lastRoll: Date?, now: Date) -> Bool {
        guard !playedThisVisit else { return false }
        guard let lastRoll else { return true }
        return now.timeIntervalSince(lastRoll) >= rollCooldown
    }

    /// One plant-page visit (from the page appearing until it goes away).
    struct Visit {
        private(set) var playedThisVisit = false
        /// Whether a flash now should bring the roll. Asking does not use the visit up.
        func wantsRoll(lastRoll: Date?, now: Date) -> Bool {
            ThunderGate.shouldSound(playedThisVisit: playedThisVisit, lastRoll: lastRoll, now: now)
        }
        /// Call once the roll has actually played.
        mutating func markPlayed() { playedThisVisit = true }
    }
}

/// The petal fall or regrowth to play when the plant page opens or its love changes, so each change plays once.
enum PetalMotion: Equatable {
    case still
    case fall(from: Int, to: Int)
    case regrow(from: Int, to: Int)

    static func next(shown: Int, now: Int) -> PetalMotion {
        let s = min(max(shown, 0), LoveEngine.maxPetals), n = min(max(now, 0), LoveEngine.maxPetals)
        if n < s { return .fall(from: s, to: n) }
        if n > s { return .regrow(from: s, to: n) }
        return .still
    }
}

extension LifeStats.Inputs {
    /// Reads every field the Life panel needs straight from the plant.
    init(plant: PlantCollectible, now: Date, calendar: Calendar, exempt: Bool, economy: Economy = .default) {
        self.init(lastSunnyAt: plant.lastSunnyAt, lastLovedAt: plant.lastLovedAt, lastFedAt: plant.lastFedAt, lastPrunedAt: plant.lastPrunedAt,
                  soilRichness: plant.soilRichness, stage: plant.stage, waterToday: plant.waterToday, waterDay: plant.waterDay,
                  now: now, calendar: calendar, exempt: exempt, economy: economy)
    }
}

/// The Life panel on the plant page starts closed and opens itself on a visit where the plant's weather slot, its
/// hearts or its seed state changed since the last visit (owner ruling 2026-11-06).
enum LifePanelVisit {
    static func key(weather: String, hearts: Int, isSeed: Bool) -> String { "\(weather)|h\(hearts)|\(isSeed ? "seed" : "plant")" }
    /// The first visit (nothing seen yet) starts closed too.
    static func opens(lastSeen: String, current: String) -> Bool { !lastSeen.isEmpty && lastSeen != current }
}

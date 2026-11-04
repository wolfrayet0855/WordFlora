import Foundation

/// The plant page's Life panel: three soft meters, a stage path, today's hearts and the love petals, all read from
/// data the plant already keeps (lastTendedAt, lastSunnyAt, lastLovedAt, soilRichness, stage, absorbedToday).
/// Meters use "has had" words, ease down slowly with time, never reach empty, never use red and never show numbers.
enum LifeStats {
    struct Inputs {
        var lastTendedAt: Date?
        var lastSunnyAt: Date?
        var lastLovedAt: Date?
        var soilRichness: Double
        var stage: Int
        var absorbedToday: Int
        var absorbDay: Date?
        var now: Date
        var calendar: Calendar
        /// Quiet Garden or Calm mode: no rain, no falling petals, no seed.
        var exempt: Bool
        var economy: Economy = .default
    }

    struct Meter: Equatable {
        var name: String
        var word: String
        /// 0...1, never below `floor`.
        var fill: Double
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

        var stageLabel: String { "Growing, \(LifeStats.stageNames[stage].lowercased()) stage" }
        var heartsLabel: String { "Love, \(hearts) of 5 hearts. \(loveLine)" }
    }

    static let floor = 0.3
    static let stageNames = ["Tiny", "Sprout", "Bud", "Bloom", "Full bloom"]

    // MARK: Copy (every visible or spoken line on the panel lives here so the copy test can read it all)

    static let title = "Life"
    static let hideLabel = "Hide Life panel"
    static let showLabel = "Show Life panel"
    static let keyLine = "Love keeps its petals."
    static let growingTitle = "Growing"
    static let loveTitle = "Love"
    static let meterNames = (water: "Water", sunshine: "Sunshine", happiness: "Happiness")
    static let waterWords = ["Full", "Good", "Sipping"]
    static let sunWords = ["Bright", "Warming up", "Cloudy", "Sun is coming"]
    static let happyWords = ["Happy", "Cosy"]
    static let restWord = "Resting"
    static let loveLines = ["Loved", "Feeling loved", "Hellos help", "Ready for a hello", "Ready for you"]
    static let gentleRain = "Gentle rain"
    static let rainAndThunder = "Rain and soft thunder"

    static func plantLabel(name: String, pips: Int) -> String { "\(name), \(pips) of 5 love petals" }
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
        [title, hideLabel, showLabel, keyLine, growingTitle, loveTitle, meterNames.water, meterNames.sunshine, meterNames.happiness,
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

        let water: Meter = {
            let h = hours(since: i.lastTendedAt, now: i.now)
            if h < 24 { return Meter(name: meterNames.water, word: waterWords[0], fill: 0.9) }
            if h < 48 { return Meter(name: meterNames.water, word: waterWords[1], fill: 0.72) }
            return Meter(name: meterNames.water, word: waterWords[2], fill: 0.5)
        }()

        let sunshine: Meter = {
            let h = hours(since: i.lastSunnyAt, now: i.now)
            var level = h < 24 ? 0 : (h < 72 ? 1 : 3)
            if rainDay > 0 { level = max(level, 2) }      // a rainy day is cloudy, never brighter
            let fills = [0.85, 0.65, 0.5, 0.38]
            return Meter(name: meterNames.sunshine, word: sunWords[level], fill: fills[level])
        }()

        let happiness: Meter = {
            let score = Double(love.petalsLeft) / 5 * 0.7 + min(max(i.soilRichness, 0), 1) * 0.3
            return Meter(name: meterNames.happiness, word: score >= 0.65 ? happyWords[0] : happyWords[1], fill: 0.35 + 0.55 * score)
        }()

        let lovedToday = i.lastLovedAt.map { i.calendar.isDate($0, inSameDayAs: i.now) && $0 <= i.now } ?? false
        let absorbed = (i.absorbDay.map { i.calendar.isDate($0, inSameDayAs: i.now) } ?? false) ? i.absorbedToday : 0
        let cap = max(1, i.economy.dailyAbsorbCap)
        let hearts = lovedToday ? min(5, max(1, 1 + Int((Double(absorbed) * 4 / Double(cap)).rounded()))) : 0
        let line: String = {
            switch hearts {
            case 5: return loveLines[0]
            case 3...4: return loveLines[1]
            case 1...2: return loveLines[2]
            default: return loveLines[3]
            }
        }()

        return Snapshot(water: water, sunshine: sunshine, happiness: happiness, stage: stage, hearts: hearts, loveLine: line,
                        pips: love.petalsLeft, isSeed: false, rainDay: rainDay)
    }

    /// Rain grows a little steadier each day without love; soft thunder joins from day four.
    static func weather(day: Int) -> Weather {
        guard day > 0 else { return Weather(drops: 0, thunder: false) }
        let drops = [12, 20, 32, 42, 50, 56, 60]
        return Weather(drops: drops[min(day, 7) - 1], thunder: day >= 4)
    }

    private static func hours(since d: Date?, now: Date) -> Double {
        guard let d else { return .infinity }
        return max(0, now.timeIntervalSince(d) / 3600)
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

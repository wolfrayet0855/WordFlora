import Foundation

/// Test fixtures for the weather helpers, the weather puzzle and the Grand Garden. Each one writes ordinary stored
/// values (a real seed pair, found plants, stages), so the screens run on the real pure rules, not on overrides.
enum WeatherFixture {
    /// A seed and start day whose schedule puts an event on `day` (searching seeds from 1 up, so it is deterministic).
    /// `offset` = 0: the event is today; 1: the event is tomorrow (today shows its forecast).
    static func seed(eventOn day: Int, kind: WeatherKind? = nil) -> (seed: Int64, startDay: Int, kind: WeatherKind) {
        let start = max(1, day - 2)
        for s in Int64(1)...200_000 {
            if let k = WeatherEngine.event(day: day, seed: s, startDay: start), kind == nil || k == kind { return (s, start, k) }
        }
        return (1, start, .bigWind)
    }
}

@MainActor
enum EndgameUITestFixtures {
    /// `-uitest-weather-today[=kind]`: weather came today; `-uitest-weather-tomorrow[=kind]`: tomorrow's forecast shows.
    /// Both give six found plants and enough tends so the gate is open, and the weather kit.
    /// `-uitest-weather-rewarded`: a few Garden Days so the puzzle's reward is not held back by the anti-farm cap.
    /// `-uitest-crown` / `-uitest-goldcrown`: every plant found (and all in full bloom), ceremony not yet seen.
    /// `-uitest-golden`: every plant found and in full bloom, the ceremonies seen, Daisy 4 of 7 golden days, Rose golden.
    static func apply(args: [String], to model: AppModel) {
        let today = WeatherDay.key(.now)
        for (flag, offset) in [("-uitest-weather-today", 0), ("-uitest-weather-tomorrow", 1)] {
            guard let arg = args.first(where: { $0 == flag || $0.hasPrefix(flag + "=") }) else { continue }
            let kind = arg.split(separator: "=").dropFirst().first.flatMap { WeatherKind(rawValue: String($0)) }
            let f = WeatherFixture.seed(eventOn: today + offset, kind: kind)
            var found = 0
            for p in model.plants() where found < 6 { p.earnedCount = 1; p.stage = max(p.stage, 2); found += 1 }
            model.profile?.weatherSeed = f.seed
            model.profile?.weatherStartDay = f.startDay
            model.profile?.weatherGatedFromDay = today
            model.profile?.weatherHighWaterDay = today
            model.profile?.weatherKitAt = .now
            model.profile?.weatherSeenAt = .now
            model.profile?.water = 5; model.profile?.soil = 3
            if args.contains("-uitest-weather-rewarded") { model.profile?.gardenDays = 3 }
            try? model.context.save()
        }
        if args.contains("-uitest-crown") || args.contains("-uitest-goldcrown") || args.contains("-uitest-golden") {
            let gold = !args.contains("-uitest-crown")
            for (i, p) in model.plants().enumerated() {
                p.earnedCount = 1
                p.stage = gold || i % 3 == 0 ? 4 : 1 + i % 3
            }
            if args.contains("-uitest-goldcrown") || args.contains("-uitest-golden") { model.profile?.crownSeenAt = .now }
            if args.contains("-uitest-golden") {
                model.profile?.goldCrownSeenAt = .now
                model.plants().first { $0.plantId == "daisy" }?.goldenDays = 4
                model.plants().first { $0.plantId == "rose" }?.goldenDays = 7
                for p in model.plants() where p.plantId != "daisy" && p.plantId != "rose" { p.goldenDays = 2 }
            }
            model.profile?.water = 5; model.profile?.soil = 3
            try? model.context.save()
            model.game.refreshLevel()
        }
    }
}

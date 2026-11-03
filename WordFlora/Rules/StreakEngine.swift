import Foundation

struct StreakEvents: Equatable {
    var usedGrace = false
    var usedFreeze = false
    var milestoneRose = false
    var freezeEarned = false
}

/// Garden Days never decrease; the streak is secondary and "rests" instead of breaking (spec section 18, P10).
struct StreakState: Equatable {
    var gardenDays = 0
    var streak = 0
    var bestStreak = 0
    var freezes = 0
    var lastPlayedDay: Date?
    var lastGraceDay: Date?

    @discardableResult
    mutating func recordPlay(on date: Date, calendar: Calendar, economy: Economy) -> StreakEvents {
        var events = StreakEvents()
        let today = calendar.startOfDay(for: date)

        guard let last = lastPlayedDay.map({ calendar.startOfDay(for: $0) }) else {
            gardenDays = 1; streak = 1; bestStreak = max(bestStreak, 1); lastPlayedDay = today
            return events
        }
        let gap = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        guard gap >= 1 else { return events }   // same day, or the clock moved backwards

        lastPlayedDay = today
        gardenDays += 1
        var advanced = false

        if gap == 1 {
            streak += 1; advanced = true
        } else {
            var need = gap - 1
            let graceAvailable: Bool
            if let g = lastGraceDay {
                graceAvailable = (calendar.dateComponents([.day], from: calendar.startOfDay(for: g), to: today).day ?? 0) >= economy.graceWindowDays
            } else {
                graceAvailable = true
            }
            if graceAvailable { need -= 1 }
            if need <= freezes {
                if graceAvailable { lastGraceDay = today; events.usedGrace = true }
                if need > 0 { freezes -= need; events.usedFreeze = true }
                streak += 1; advanced = true
            } else {
                streak = 1   // resting; gardenDays and bestStreak are untouched
            }
        }

        bestStreak = max(bestStreak, streak)
        if advanced {
            if earnsFreeze(atStreak: streak, economy: economy), freezes < economy.freezeCap {
                freezes += 1; events.freezeEarned = true
            }
            if economy.roseMilestones.contains(streak) { events.milestoneRose = true }
        }
        return events
    }

    private func earnsFreeze(atStreak n: Int, economy: Economy) -> Bool {
        if economy.freezeEarnDays.contains(n) { return true }
        if let lastEarn = economy.freezeEarnDays.max(), n > lastEarn, (n - lastEarn) % economy.freezeEveryDays == 0 { return true }
        return false
    }
}

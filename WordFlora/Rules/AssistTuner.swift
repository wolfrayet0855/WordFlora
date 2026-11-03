/// Transparent adaptive difficulty (spec section 19, P-04). 0 = Gentle, 1 = Standard, 2 = Tricky.
struct RoundOutcome: Equatable {
    var won: Bool
    var helpUsed: Bool
}

enum AssistTuner {
    enum BandHalf: Equatable { case lower, whole, upper }

    static func next(current: Int, history: [RoundOutcome], roundsSinceChange: Int, locked: Bool) -> Int {
        guard !locked, roundsSinceChange >= 5, history.count >= 10 else { return current }
        let last = history.suffix(10)
        let cleanWins = last.filter { $0.won && !$0.helpUsed }.count
        let wins = last.filter(\.won).count
        if cleanWins >= 9 { return min(2, current + 1) }   // > 85% clean wins
        if wins < 5 { return max(0, current - 1) }          // < 50% wins
        return current
    }

    static func pulseAfterWrongGuesses(level: Int) -> Int { level == 0 ? 2 : 3 }
    static func defaultLevel(isUnderThirteen: Bool) -> Int { isUnderThirteen ? 0 : 1 }

    static func bandHalf(level: Int) -> BandHalf {
        switch level { case 0: return .lower; case 2: return .upper; default: return .whole }
    }
}

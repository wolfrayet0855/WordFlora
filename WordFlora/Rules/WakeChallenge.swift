import Foundation

/// The two ways to wake a seed (design-preview/tending/parts/notes/decision.md). Both are free, untimed in feel and
/// can be tried again any time; a try that does not work out is "still dreaming", never a failure.
enum WakeChallenge: String, CaseIterable, Codable {
    case butterflies, wordPuzzle
}

enum WakeResult: String, Codable {
    case woke, stillDreaming
}

enum WakeRule {
    /// Suggest the challenge the player last woke a seed with; with none yet, or after "still dreaming", butterflies.
    static func suggestion(last: WakeChallenge?, lastResult: WakeResult?) -> WakeChallenge {
        guard let last, lastResult == .woke else { return .butterflies }
        return last
    }

    /// Both tiles always show, the suggested one first. Nothing starts on its own.
    static func ordered(suggested: WakeChallenge) -> [WakeChallenge] {
        [suggested] + WakeChallenge.allCases.filter { $0 != suggested }
    }

    /// After two "still dreaming" tries in a row, the next try is easier.
    static func isEasier(dreamsInARow: Int) -> Bool { dreamsInARow >= 2 }

    /// The gentle butterfly goal: 3 visitors (2 when easier). The game lasts 35 s, so this is reachable at a calm pace.
    static func butterflyGoal(dreamsInARow: Int) -> Int { isEasier(dreamsInARow: dreamsInARow) ? 2 : 3 }

    static func butterfliesWoke(caught: Int, goal: Int) -> Bool { caught >= goal }
}

/// How the petals come back after a wake: one at a time, 0.3 s apart, 2.4 s at most; all at once under Reduce Motion.
enum PetalReturn {
    static let gap = 0.3
    static let maxTotal = 2.4

    static func delays(count: Int, reduceMotion: Bool) -> [Double] {
        guard count > 0 else { return [] }
        if reduceMotion { return Array(repeating: 0, count: count) }
        let step = count > 1 ? min(gap, maxTotal / Double(count - 1)) : gap
        return (0..<count).map { Double($0) * step }
    }
}

/// Every string in the wake flow. Grade 2 reading level, checked by CopySafety in tests.
enum WakeCopy {
    static func seedCard(name: String) -> String { "\(name) is resting in a seed. It is safe and cosy." }
    static func wakeButton(name: String) -> String { "Wake \(name)" }
    static func sheetTitle(name: String) -> String { "Wake \(name)" }
    static let sheetSubtitle = "Pick one you like."
    static let suggestedBadge = "Good for today"
    static let close = "Close"

    static func title(_ c: WakeChallenge) -> String {
        switch c { case .butterflies: return "Catch butterflies"; case .wordPuzzle: return "Word puzzle" }
    }
    static func subtitle(_ c: WakeChallenge) -> String {
        switch c { case .butterflies: return "Tap them as they float by"; case .wordPuzzle: return "Make one word from the letters" }
    }
    static func lengthChip(_ c: WakeChallenge) -> String {
        switch c { case .butterflies: return "Quick"; case .wordPuzzle: return "A little longer" }
    }
    static func feelChip(_ c: WakeChallenge) -> String {
        switch c { case .butterflies: return "Gentle"; case .wordPuzzle: return "Tricky" }
    }
    /// VoiceOver label for a tile, e.g. "Catch butterflies, quick, gentle, good for today".
    static func tileLabel(_ c: WakeChallenge, suggested: Bool) -> String {
        let parts = [title(c), lengthChip(c).lowercased(), feelChip(c).lowercased()] + (suggested ? [suggestedBadge.lowercased()] : [])
        return parts.joined(separator: ", ")
    }

    static func butterflyIntro(goal: Int) -> String { "Say hello to \(goal) garden friends. Take your time." }
    static let puzzleIntroAnagram = "Make a word from the letters. Take your time."
    static let puzzleIntroVowels = "Fill in the blank spots to make a word. Take your time."
    static let start = "Start"
    /// Bees, ladybugs and others count too, so the count says "friends".
    static func caughtSoFar(_ n: Int, goal: Int) -> String { "\(n) of \(goal) friends" }

    static let notQuite = "Not quite. Try again."
    static let peek = "Peek a letter"
    static let peekSoon = "A peek comes soon"
    static let clear = "Clear"
    static func puzzleHint(letters: Int) -> String { "A plant name with \(letters) letters." }

    static func awake(name: String) -> String { "\(name) is awake!" }
    static func awakeAnnouncement(name: String) -> String { "\(name) is awake." }
    static let petalsComing = "Here come the petals."
    static let tapToSeeAll = "Tap to see them all."
    static let done = "Done"

    static func stillDreaming(name: String) -> String { "\(name) is still dreaming." }
    static let tryAgainAnyTime = "You can try again any time. It is free."
    static let stillDreamingShort = "Still dreaming. Try again anytime, it is free."
    static let tryAgain = "Try again"
    static let tryButterflies = "Try the butterflies"

    static func all(name: String) -> [String] {
        var lines = [seedCard(name: name), wakeButton(name: name), sheetTitle(name: name), sheetSubtitle, suggestedBadge, close,
                     butterflyIntro(goal: 3), butterflyIntro(goal: 2), puzzleIntroAnagram, puzzleIntroVowels, start, caughtSoFar(1, goal: 3),
                     notQuite, peek, peekSoon, clear, puzzleHint(letters: 7),
                     awake(name: name), awakeAnnouncement(name: name), petalsComing, tapToSeeAll, done,
                     stillDreaming(name: name), tryAgainAnyTime, stillDreamingShort, tryAgain, tryButterflies]
        for c in WakeChallenge.allCases {
            lines += [title(c), subtitle(c), lengthChip(c), feelChip(c), tileLabel(c, suggested: true), tileLabel(c, suggested: false)]
        }
        return lines
    }
}

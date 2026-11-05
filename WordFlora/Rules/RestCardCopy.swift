import Foundation

/// Words for the resting card (after every third regular round or the Daily Bloom) and the under-13 break card.
/// Positive only, grade 2-3 reading level; every line is checked by CopySafety in RestCardTests.
enum RestCardCopy {
    // Resting card
    static let restTitle = "The garden is resting"
    static let restBody = "Take a breath. Come back whenever you like."
    static let oneMore = "One more"
    static let adNote = "A short ad may play first."
    static let enough = "That's enough for now"
    static let goAdFree = "Go ad-free with WordFlora Plus"
    static let goAdFreeHint = "Opens WordFlora Plus"
    static let dailyDone = "Daily Bloom done"

    /// The reward pill: the Daily Bloom, or the regular words played this sitting.
    static func reward(isDaily: Bool, wordsPlayed n: Int) -> String {
        if isDaily { return dailyDone }
        return n == 1 ? "You played 1 word" : "You played \(n) words"
    }

    // Break card
    static let breakTitle = "Time for a little break"
    static var breakBody: String { BreakPolicy.message }
    static let takeBreak = "Take a break"
    static let keepPlaying = "Keep playing"
    static let looks = ["Window", "Plant", "Sky"]

    /// Every fixed line, for the copy tests.
    static var allLines: [String] {
        [restTitle, restBody, oneMore, adNote, enough, goAdFree, goAdFreeHint, dailyDone,
         breakTitle, breakBody, takeBreak, keepPlaying] + looks
            + [reward(isDaily: false, wordsPlayed: 1), reward(isDaily: false, wordsPlayed: 3), reward(isDaily: true, wordsPlayed: 3)]
    }
}

/// Words for the nudge card: Play tapped again soon after "That's enough for now" by a player who gets no ad
/// (Plus, under 13, Calm mode, Quiet Garden, ads off or not possible right now). Never blocks play, never mentions
/// ads, timers or Plus. Positive only, grade 2-3; checked by CopySafety in ReturnNudgeTests.
enum NudgeCardCopy {
    static let title = "Your garden would love a visit"
    static let body = "Say hello to your plants, or try a fun puzzle."
    static let visit = "Visit my garden"
    static let puzzle = "Try a puzzle"
    static let playAnyway = "Play anyway"
    static let dailyBloomHint = "Opens the Daily Bloom"
    static let butterflyHint = "Opens the butterfly game"
    static let playAnywayHint = "Starts a new word"
    /// Shown under Play on Home when an ad may play on the player's tap (the rest card's honest line).
    static let adNote = RestCardCopy.adNote

    enum Puzzle: Equatable { case dailyBloom, butterfly }

    /// The Daily Bloom until it is done today, then the butterfly game; nothing if neither is open yet.
    static func puzzleTarget(dailyBloomOpen: Bool, dailyDone: Bool, butterflyOpen: Bool) -> Puzzle? {
        if dailyBloomOpen && !dailyDone { return .dailyBloom }
        return butterflyOpen ? .butterfly : nil
    }

    static var allLines: [String] {
        [title, body, visit, puzzle, playAnyway, dailyBloomHint, butterflyHint, playAnywayHint, adNote]
    }
}

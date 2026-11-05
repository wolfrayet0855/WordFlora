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

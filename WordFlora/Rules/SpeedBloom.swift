import Foundation

/// Speed bloom (owner request, approved design 2026-11-06): an opt-in, gentle pace for level 4 and 5 words.
///
/// - Offered only to players who said they are 13 or older (unknown age counts as young), with Calm mode off and
///   Quiet Garden off. Off by default and never prompted: the Settings toggle is the only way in, and the way out.
/// - A word gets 12 s plus 4 s per letter, never more than 90 s; "Extra time" gives half as long again (x1.5).
/// - The flower's petal ring fills with a soft gold arc. No numbers, no ticking sound, no haptic.
/// - A tap on Help pauses the ring for a while. The ring also holds still whenever the round is not being played
///   (a card is open, the app is in the background).
/// - If the ring closes first, the round simply carries on at normal pace ("Take your time"): same reward, no loss,
///   no petal cost. Finishing before it closes counts one Quick Bloom (a badge, nothing else: no ad, Plus or shed points).
enum SpeedBloom {
    static let baseSeconds: TimeInterval = 12
    static let secondsPerLetter: TimeInterval = 4
    static let capSeconds: TimeInterval = 90
    static let extraTimeFactor = 1.5
    /// How long one Help tap holds the ring still (time to read the new clue).
    static let helpPauseSeconds: TimeInterval = 10
    static let levels = 4...5

    /// The device-local switches the rule reads (AppSettings), gathered as each round begins.
    struct Prefs: Equatable {
        var optedIn = false
        var extraTime = false
        var ageBand: AgeBand?
        var calmMode = false
        var quietGarden = false
        static let off = Prefs()
    }

    /// Whether the Settings toggle is shown at all: 13+ (never under 13 or unknown), Calm off, Quiet Garden off.
    static func isOffered(ageBand: AgeBand?, calmMode: Bool, quietGarden: Bool) -> Bool {
        guard let age = ageBand, age != .under13 else { return false }
        return !calmMode && !quietGarden
    }

    static func isOffered(_ p: Prefs) -> Bool { isOffered(ageBand: p.ageBand, calmMode: p.calmMode, quietGarden: p.quietGarden) }

    /// Whether this round gets the gold ring: opted in, still offered, a level 4-5 word, and a regular round.
    static func applies(_ p: Prefs, wordLevel: Int, isDaily: Bool = false, isTutorial: Bool = false) -> Bool {
        p.optedIn && isOffered(p) && levels.contains(wordLevel) && !isDaily && !isTutorial
    }

    /// Letters only: spaces and hyphens in a phrase do not add time.
    static func letterCount(_ word: String) -> Int { word.filter(\.isLetter).count }

    /// 12 s + 4 s per letter, capped at 90 s; Extra time multiplies the capped time by 1.5 (so it always helps).
    static func seconds(letters: Int, extraTime: Bool) -> TimeInterval {
        let base = min(capSeconds, baseSeconds + secondsPerLetter * Double(max(0, letters)))
        return extraTime ? base * extraTimeFactor : base
    }

    static func seconds(for word: String, extraTime: Bool) -> TimeInterval {
        seconds(letters: letterCount(word), extraTime: extraTime)
    }

    /// The Quick Bloom badge sits on the shelf only for players who turned Speed bloom on, or who already earned it,
    /// so the shelf never nudges anyone toward the toggle (and young players never see a badge they cannot reach).
    static func showsBadge(_ p: Prefs, earnedAnyTier: Bool) -> Bool {
        earnedAnyTier || (p.optedIn && isOffered(p))
    }

    static let badgeId = "quick_bloom"
}

/// One round's gold ring. Pure value type: the view feeds it elapsed play time; nothing here reads a clock.
struct SpeedBloomRing: Equatable {
    enum Outcome: Equatable {
        /// The ring is filling.
        case filling
        /// The ring closed first: the round goes on at normal pace, with nothing taken away.
        case relaxed
        /// The word was solved before the ring closed (one Quick Bloom).
        case bloomedInTime
        /// The round ended some other way (it rested) while the ring was still filling.
        case ended
    }

    let budget: TimeInterval
    private(set) var elapsed: TimeInterval = 0
    /// Help-tap pause still to run before the ring moves again.
    private(set) var pauseLeft: TimeInterval = 0
    private(set) var outcome: Outcome = .filling

    init(budget: TimeInterval) { self.budget = max(1, budget) }

    /// 0...1, how much of the ring is gold. Nil once the round has relaxed (the ring fades away).
    var fill: Double? {
        switch outcome {
        case .filling, .bloomedInTime, .ended: return min(1, elapsed / budget)
        case .relaxed: return nil
        }
    }

    var isFilling: Bool { outcome == .filling }

    /// Moves the ring on by `dt` seconds of play. A Help pause soaks up time first. Returns true when this step
    /// closed the ring (the moment the round turns to normal pace).
    @discardableResult
    mutating func advance(by dt: TimeInterval) -> Bool {
        guard outcome == .filling, dt > 0 else { return false }
        let paused = min(pauseLeft, dt)
        pauseLeft -= paused
        elapsed = min(budget, elapsed + (dt - paused))
        if elapsed >= budget { outcome = .relaxed; return true }
        return false
    }

    /// A Help tap holds the ring still for `SpeedBloom.helpPauseSeconds` (a second tap restarts the pause; it never stacks).
    mutating func helpTapped() {
        guard outcome == .filling else { return }
        pauseLeft = SpeedBloom.helpPauseSeconds
    }

    /// The word was solved. Returns true when it was in time (counts one Quick Bloom).
    @discardableResult
    mutating func wordSolved() -> Bool {
        guard outcome == .filling else { return false }
        outcome = .bloomedInTime
        return true
    }

    /// The round rested (no petals) while the ring was filling: no Quick Bloom, nothing else changes.
    mutating func roundRested() {
        if outcome == .filling { outcome = .ended }
    }
}

/// Every Speed bloom string a player can see or hear. Positive only: checked by CopySafety and by `avoid` in tests,
/// so the clock is never named and nothing sounds like pressure.
enum SpeedBloomCopy {
    static let toggle = "Speed bloom"
    static let extraTime = "Extra time"
    static let footnote = "On level 4 and 5 words, a soft gold ring fills around the flower. Finish the word before it closes for a Quick Bloom badge. If it closes, the word carries on at your own pace, with the same reward."
    static let extraTimeHint = "Gives the gold ring half as long again"
    static let takeYourTime = "Take your time"
    static let voiceOverOn = "Speed bloom is on"

    static var all: [String] { [toggle, extraTime, footnote, extraTimeHint, takeYourTime, voiceOverOn] }

    /// Words kept out of Speed bloom copy on top of CopySafety's list (no clock talk, no pressure).
    static let avoid: [String] = [
        "timer", "countdown", "clock", "second", "seconds", "hurry", "rush", "fast", "faster", "quickly",
        "time's up", "time is up", "out of time", "running out", "run out", "too slow", "slow", "late", "fail", "failed",
        "deadline", "race", "beat the",
    ]

    /// The avoid-list words found in `text` (empty = fine).
    static func pressureWords(in text: String) -> [String] {
        avoid.filter { phrase in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: phrase) + "\\b"
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }
}

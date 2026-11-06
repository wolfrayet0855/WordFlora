import Foundation

// The daily tiny quest (owner approved for this release). One small thing to do each day, picked from the player's
// seed and the Gregorian day key (WeatherDay), so every device agrees with no server. Count-up only: no streak, no
// loss, no timers. Finishing it gives one shed point, once a day; Quiet Garden hides it and gives nothing.

enum QuestKind: String, CaseIterable, Codable {
    case waterPlants, helloPlants, longWord, findWords, sunPlant, visitVisitors
}

/// One day's quest progress. Stored on the profile as `questDay`, `questProgress`, `questDone`.
struct QuestState: Equatable {
    var day = 0
    var progress = 0
    var done = false
}

enum DailyQuest {
    struct Quest: Equatable {
        var kind: QuestKind
        var target: Int
    }

    /// What the player can do today, so a quest never asks for something still closed.
    struct Availability: Equatable {
        var plantsFound: Int
        var sunOpen: Bool
        var visitorsOpen: Bool
    }

    /// Things that move a quest along. Plant counts are the day's count of plants (not taps), so tapping the same
    /// plant again never counts twice.
    enum Event: Equatable {
        case watered(plantsToday: Int)
        case greeted(plantsToday: Int)
        case sunned
        case wordFound(letters: Int)
        case visitedVisitors
    }

    static let pointsPerQuest = 1
    static let longWordLetters = 5

    static func target(_ k: QuestKind) -> Int {
        switch k {
        case .waterPlants: return 2
        case .helloPlants: return 3
        case .findWords: return 2
        case .longWord, .sunPlant, .visitVisitors: return 1
        }
    }

    /// The kinds open to the player, in declaration order.
    static func pool(_ a: Availability) -> [QuestKind] {
        guard a.plantsFound > 0 else { return [] }
        return QuestKind.allCases.filter { k in
            switch k {
            case .findWords, .longWord: return true
            case .waterPlants: return a.plantsFound >= target(.waterPlants)
            case .helloPlants: return a.plantsFound >= target(.helloPlants)
            case .sunPlant: return a.sunOpen
            case .visitVisitors: return a.visitorsOpen
            }
        }
    }

    /// Today's quest, or nil before the first plant. The same kind never comes two days in a row.
    static func quest(day: Int, seed: Int64, availability: Availability) -> Quest? {
        let kinds = pool(availability)
        guard !kinds.isEmpty else { return nil }
        let k = kinds[index(day: day, seed: seed, count: kinds.count)]
        return Quest(kind: k, target: target(k))
    }

    /// A walk from the weather epoch (day 0): each day steps 1 to n-1 places on, so no day repeats the one before.
    /// A few thousand hashes at most (one per day since 2026-01-01).
    static func index(day: Int, seed: Int64, count n: Int) -> Int {
        guard n > 1 else { return 0 }
        var i = Int(hash(day: 0, seed: seed) % UInt64(n))
        guard day > 0 else { return i }
        for d in 1...min(day, 200_000) { i = (i + 1 + Int(hash(day: d, seed: seed) % UInt64(n - 1))) % n }
        return i
    }

    private static func hash(day: Int, seed: Int64) -> UInt64 {
        WeatherEngine.mix(UInt64(bitPattern: seed) ^ 0x5155_4553_5400 ^ WeatherEngine.mix(UInt64(bitPattern: Int64(day))))
    }

    /// A stored state from an earlier day reads as a fresh one for today.
    static func current(_ s: QuestState, today: Int) -> QuestState {
        s.day == today ? s : (s.day > today ? s : QuestState(day: today))
    }

    /// One event. Progress only goes up, stops at the target, and a clock set back changes nothing.
    static func step(_ e: Event, quest: Quest, state: QuestState, today: Int) -> QuestState {
        guard state.day <= today else { return state }
        var s = current(state, today: today)
        let target = max(1, quest.target)
        let next: Int
        switch (quest.kind, e) {
        case (.waterPlants, .watered(let n)), (.helloPlants, .greeted(let n)): next = max(s.progress, n)
        case (.sunPlant, .sunned), (.visitVisitors, .visitedVisitors): next = s.progress + 1
        case (.findWords, .wordFound): next = s.progress + 1
        case (.longWord, .wordFound(let letters)) where letters >= longWordLetters: next = s.progress + 1
        default: next = s.progress
        }
        s.progress = min(target, max(s.progress, next))
        if s.progress >= target { s.done = true }
        return s
    }

    /// The shed points this change earns: one, the moment the quest is done, and never in Quiet Garden.
    static func reward(before: QuestState, after: QuestState, quietGarden: Bool) -> Int {
        guard !quietGarden, after.done else { return 0 }
        return before.done && before.day == after.day ? 0 : pointsPerQuest
    }

    /// The card shows after the first session's guide, and never in Quiet Garden.
    static func isShown(quietGarden: Bool, onboardingDone: Bool) -> Bool { !quietGarden && onboardingDone }

    /// Sync and backups: the later day wins; on the same day the larger count, and done stays done.
    static func merged(_ a: QuestState, _ b: QuestState) -> QuestState {
        if a.day != b.day { return a.day > b.day ? a : b }
        return QuestState(day: a.day, progress: max(a.progress, b.progress), done: a.done || b.done)
    }
}

/// Every quest line, grade 2 and kind (checked by CopySafety in tests).
enum DailyQuestCopy {
    static let header = "Today's little quest"

    static func title(_ q: DailyQuest.Quest) -> String {
        switch q.kind {
        case .waterPlants: return "Water \(q.target) plants"
        case .helloPlants: return "Say hello to \(q.target) plants"
        case .longWord: return "Find a word with \(DailyQuest.longWordLetters) letters or more"
        case .findWords: return "Find \(q.target) words"
        case .sunPlant: return "Give a plant some sun"
        case .visitVisitors: return "Visit the Visitors page"
        }
    }

    static func progress(_ n: Int, of target: Int) -> String { "\(n) of \(target)" }
    static let done = "Done! A shed point for you."
    static let doneCalm = "All done. A shed point for you."
    static let a11yDone = "Quest done"

    static func all() -> [String] {
        let quests = QuestKind.allCases.map { title(DailyQuest.Quest(kind: $0, target: DailyQuest.target($0))) }
        return quests + [header, progress(1, of: 2), done, doneCalm, a11yDone]
    }
}

import Foundation

// The weather puzzle (docs/pm/endgame-and-events-spec.md sections 4.1, 4.6 and 5, ticket E-8). One puzzle per event
// mends the whole garden. It is optional, untimed, tries are free, skipping costs nothing, and every bonus is fixed and
// named before play: the next weather sticker, one word toward the next plant and a step on the Weathered badge.

/// The two tiers. Gentle is today's wake puzzle exactly; Storm is longer plant names, no given letter and one decoy.
enum WeatherPuzzleTier: String, Codable, CaseIterable { case gentle, storm }

/// Seven stickers in a fixed order: the n-th solved weather puzzle earns sticker n, whatever the kind, so no sticker
/// waits on a rare kind. Stored in the existing sticker album (`StickerAlbum`, union merge) under `weather.1` ... `weather.7`.
enum WeatherSticker: Int, CaseIterable, Identifiable {
    case rainbow = 1, frogFriend, ladybird, kite, snowflake, sunHat, puddleBoots

    var id: String { "weather.\(rawValue)" }
    static let idPrefix = "weather."
    static func isWeather(_ albumId: String) -> Bool { albumId.hasPrefix(idPrefix) }
    init?(albumId: String) {
        guard Self.isWeather(albumId), let n = Int(albumId.dropFirst(Self.idPrefix.count)) else { return nil }
        self.init(rawValue: n)
    }

    var name: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .frogFriend: return "Frog friend"
        case .ladybird: return "Ladybird"
        case .kite: return "Kite"
        case .snowflake: return "Snowflake"
        case .sunHat: return "Sun hat"
        case .puddleBoots: return "Puddle boots"
        }
    }

    /// Drawn as a picture (never as text, so the accessibility audit sees one image with its label).
    var emoji: String {
        switch self {
        case .rainbow: return "🌈"
        case .frogFriend: return "🐸"
        case .ladybird: return "🐞"
        case .kite: return "🪁"
        case .snowflake: return "❄️"
        case .sunHat: return "👒"
        case .puddleBoots: return "🥾"
        }
    }

    /// The next sticker to earn: the first one not in the album yet. Nil once all seven are there.
    static func next(in album: StickerAlbum) -> WeatherSticker? { allCases.first { album.count(of: $0.id) == 0 } }
    static func owned(in album: StickerAlbum) -> [WeatherSticker] { allCases.filter { album.count(of: $0.id) > 0 } }
}

extension WakePuzzle {
    /// Storm answers: plant names of 7-14 letters, one or two words, letters and one space only (no apostrophes, no
    /// three-word names). Returned upper-cased with the space kept, so the gap can be drawn.
    static func stormCandidates(from names: [String], economy: Economy = .default) -> [String] {
        var seen = Set<String>()
        return names.compactMap { name -> String? in
            let words = name.split(separator: " ", omittingEmptySubsequences: false)
            guard (1...2).contains(words.count), words.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.isLetter && $0.isASCII } }) else { return nil }
            let letters = words.joined().count
            guard (economy.stormMinLetters...economy.stormMaxLetters).contains(letters) else { return nil }
            let w = name.uppercased()
            return seen.insert(w).inserted ? w : nil
        }
    }

    /// The tier-aware candidate list. The gentle tier is exactly `candidates(from:)`.
    static func candidates(from names: [String], tier: WeatherPuzzleTier) -> [String] {
        tier == .gentle ? candidates(from: names) : stormCandidates(from: names)
    }

    /// A seed shared by every device for this event and attempt: stableHash("weather") ^ event day ^ attempt.
    static func weatherSeed(eventDay: Int, attempt: Int) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in "weather".utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h ^ (UInt64(bitPattern: Int64(eventDay)) &* 0x9E3779B97F4A7C15) ^ (UInt64(bitPattern: Int64(attempt)) &* 0xD1B54A32D192ED03)
    }

    /// The weather puzzle for an event. Gentle: today's wake puzzle exactly, keyed to the event and attempt. Storm: a
    /// longer plant name, every slot open, one decoy tile, and two-word names keep their gap.
    static func weather(tier: WeatherPuzzleTier, eventDay: Int, attempt: Int, names: [String], economy: Economy = .default) -> WakePuzzle? {
        switch tier {
        case .gentle:
            return make(plantId: "weather", day: eventDay &* 16 &+ attempt, names: names)
        case .storm:
            let pool = stormCandidates(from: names, economy: economy).sorted()   // order-free, so every device agrees
            guard !pool.isEmpty else { return make(plantId: "weather", day: eventDay &* 16 &+ attempt, names: names) }
            var rng = SplitMix64(seed: weatherSeed(eventDay: eventDay, attempt: attempt))
            let spaced = pool[Int(rng.next() % UInt64(pool.count))]
            var gaps: [Int] = []
            var letters: [Character] = []
            for ch in spaced {
                if ch == " " { gaps.append(letters.count - 1) } else { letters.append(ch) }
            }
            let present = Set(letters)
            let spare = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").filter { !present.contains($0) }
            var tiles = letters
            for _ in 0..<max(0, economy.stormDecoys) where !spare.isEmpty { tiles.append(spare[Int(rng.next() % UInt64(spare.count))]) }
            for i in stride(from: tiles.count - 1, to: 0, by: -1) { tiles.swapAt(i, Int(rng.next() % UInt64(i + 1))) }
            if Array(tiles.prefix(letters.count)) == letters { tiles = Array(tiles.dropFirst()) + [tiles[0]] }   // never shown solved
            return WakePuzzle(variant: .anagram, answer: String(letters), slots: letters.map { _ in nil }, tiles: tiles,
                              hint: WeatherPuzzleCopy.stormHint(letters: letters.count, words: gaps.count + 1),
                              intro: WeatherPuzzleCopy.stormIntro, gaps: gaps)
        }
    }
}

/// Who gets which puzzle, when it may be played, and what it gives.
enum WeatherPuzzlePolicy {
    /// The puzzle is there from the event day through the 3 days after, while weather mechanics show (never in Calm or
    /// Quiet Garden) and the event is not already solved.
    static func isOpen(weather w: GardenWeatherNow, rescuedDays: [Int], economy: Economy = .default) -> Bool {
        guard w.showsMechanics, w.event != nil, w.eventDay != 0 else { return false }
        let age = w.today - w.eventDay
        return age >= 0 && age < economy.weatherPuzzleDays && !rescuedDays.contains(w.eventDay)
    }

    /// Wild Weather always plays the storm tier; otherwise gentle, with an optional "A harder one" chip. Owner decision
    /// (2026-11-05): challenge is opt-in at any age and Calm decides calm, so the chip shows whenever the puzzle does
    /// (the puzzle itself never shows in Calm). Gentle stays the default pick.
    static func tier(wild: Bool, pickedHarder: Bool) -> WeatherPuzzleTier { wild || pickedHarder ? .storm : .gentle }
    static func offersHarder(calm: Bool, wild: Bool) -> Bool { !wild && !calm }

    /// Fresh puzzles started today (the stored pair is `weatherPuzzleDay`/`weatherPuzzleCount`).
    static func startedToday(puzzleDay: Int, puzzleCount: Int, today: Int) -> Int { puzzleDay == today ? max(0, puzzleCount) : 0 }

    /// At most `weatherPuzzlesPerDay` fresh puzzles a day. Not a lock: the garden still mends by care and time.
    static func mayStartFresh(puzzleDay: Int, puzzleCount: Int, today: Int, economy: Economy = .default) -> Bool {
        startedToday(puzzleDay: puzzleDay, puzzleCount: puzzleCount, today: today) < economy.weatherPuzzlesPerDay
    }

    /// The pair after starting one more fresh puzzle today.
    static func afterStart(puzzleDay: Int, puzzleCount: Int, today: Int) -> (day: Int, count: Int) {
        (today, startedToday(puzzleDay: puzzleDay, puzzleCount: puzzleCount, today: today) + 1)
    }

    /// The attempt number that seeds today's current puzzle (0 for the first).
    static func attempt(puzzleDay: Int, puzzleCount: Int, today: Int) -> Int {
        max(0, startedToday(puzzleDay: puzzleDay, puzzleCount: puzzleCount, today: today) - 1)
    }

    struct Reward: Equatable {
        /// The next sticker in the fixed order (nil after all seven).
        var sticker: WeatherSticker?
        /// One word toward the next plant (before every plant is found).
        var word: Bool
        /// Every plant found: one golden day for a weathered plant instead of the word.
        var goldenDay: Bool
        /// A step on the Weathered badge.
        var badgeStep: Bool
        var isEmpty: Bool { sticker == nil && !word && !goldenDay && !badgeStep }
        static let none = Reward(sticker: nil, word: false, goldenDay: false, badgeStep: false)
    }

    /// What a solve gives, fixed before play. The anti-farm cap (one reward per 7 Garden Days) can hold the bonus back;
    /// the garden still mends. Nothing is ever random.
    static func reward(album: StickerAlbum, rescuedCount: Int, gardenDays: Int, allFound: Bool, economy: Economy = .default) -> Reward {
        guard WeatherEngine.mayAward(rescuedCount: rescuedCount, gardenDays: gardenDays, economy: economy) else { return .none }
        return Reward(sticker: WeatherSticker.next(in: album), word: !allFound && economy.weatherPuzzleWords > 0,
                      goldenDay: allFound, badgeStep: true)
    }

    /// The solved days after this solve: union, trimmed like the merge.
    static func rescued(_ days: [Int], adding day: Int) -> [Int] { WeatherEngine.mergedRescuedDays(days, [day]) }

    /// One word toward the next plant: true when it completes the set and a plant arrives.
    static func wordStep(current: Int, economy: Economy = .default) -> (count: Int, plantArrives: Bool) {
        let n = max(0, current) + 1
        return n >= economy.wordsPerPlant ? (0, true) : (n, false)
    }
}

/// Every weather puzzle line, grade 2-3, positive only, no "storm" or "rescue" in kid-facing words.
enum WeatherPuzzleCopy {
    static let title = WeatherCopy.puzzleTitle
    static func intro(_ k: WeatherKind) -> String {
        switch k {
        case .bigWind: return "The big wind bent some tall plants. Solve it to help your garden stand tall."
        case .drySpell: return "The dry spell made some plants droop. Solve it to help your garden perk up."
        case .busyBugs: return "Busy bugs nibbled some leaves. Solve it to help your garden feel fresh."
        case .frostyNight: return "A frosty night chilled some plants. Solve it to warm your garden up."
        case .hotDay: return "The hot day made some plants droop. Solve it to help your garden perk up."
        case .hailShower: return "A hail shower tapped some leaves. Solve it to help your garden stand tall."
        case .bigPuddles: return "Big puddles splashed some plants. Solve it to help your garden dry off."
        }
    }
    static func rewardLine(_ r: WeatherPuzzlePolicy.Reward) -> String {
        switch (r.sticker, r.word, r.goldenDay) {
        case let (s?, true, _): return "Solve it for the \(s.name) sticker and a word toward your next plant."
        case let (s?, _, true): return "Solve it for the \(s.name) sticker and a golden day for a plant."
        case let (s?, _, _): return "Solve it for the \(s.name) sticker."
        case (nil, true, _): return "Solve it for a word toward your next plant."
        case (nil, _, true): return "Solve it for a golden day for a plant."
        default: return "Solve it to help your garden stand tall."
        }
    }
    static let gentle = "Gentle"
    static let gentleSub = "5 to 10 letters"
    static let harder = WeatherCopy.puzzleHarder
    static let harderSub = "Longer names"
    static let start = "Start"
    static let skip = "Skip for now"
    static let skipSub = "Care will help it mend."
    static let newPuzzle = "New puzzle"
    static let plenty = WeatherCopy.puzzlePlenty
    static let notQuite = WeatherCopy.puzzleTryAgain
    static let peek = "Peek a letter"
    static let peekSoon = "A peek comes soon"
    static let clear = "Clear"
    static let takeBack = "Take back"
    static let stormIntro = "Make a plant name from the letters. One letter is extra."
    static func stormHint(letters: Int, words: Int) -> String {
        words > 1 ? "A plant name with \(letters) letters in \(words) words." : "A plant name with \(letters) letters."
    }
    static let solvedTitle = "You solved it!"
    static let solvedLine = "Your whole garden is standing tall."
    static func stickerEarned(_ s: WeatherSticker) -> String { "New sticker: \(s.name)" }
    static let wordEarned = "+1 word toward your next plant"
    static func goldenEarned(name: String) -> String { "\(name) had a golden day" }
    static func plantArrived(name: String) -> String { "\(name) came to your garden!" }
    static func weatheredStep(_ n: Int, of goal: Int) -> String { "Weathered: \(n) of \(goal)" }
    static let weatheredDone = "Weathered: all done!"
    static let done = "Done"
    static let peekedSuffix = "peeked"
    static func slotLabel(_ i: Int, letter: Character?, peeked: Bool) -> String {
        guard let letter else { return "Spot \(i + 1), open" }
        return peeked ? "Spot \(i + 1), \(letter), \(peekedSuffix)" : "Spot \(i + 1), \(letter)"
    }
    static let bannerButton = "Try the weather puzzle"

    static func all(name: String) -> [String] {
        let rewards: [WeatherPuzzlePolicy.Reward] = [
            .init(sticker: .frogFriend, word: true, goldenDay: false, badgeStep: true),
            .init(sticker: .kite, word: false, goldenDay: true, badgeStep: true),
            .init(sticker: .rainbow, word: false, goldenDay: false, badgeStep: true),
            .init(sticker: nil, word: true, goldenDay: false, badgeStep: true),
            .init(sticker: nil, word: false, goldenDay: true, badgeStep: true), .none,
        ]
        return WeatherKind.allCases.map(intro) + rewards.map(rewardLine) + WeatherSticker.allCases.flatMap { [$0.name, stickerEarned($0)] }
            + [title, gentle, gentleSub, harder, harderSub, start, skip, skipSub, newPuzzle, plenty, notQuite, peek, peekSoon, clear,
               takeBack, stormIntro, stormHint(letters: 12, words: 2), stormHint(letters: 8, words: 1), solvedTitle, solvedLine,
               wordEarned, goldenEarned(name: name), plantArrived(name: name), weatheredStep(1, of: 3), weatheredDone, done,
               slotLabel(0, letter: "V", peeked: true), slotLabel(1, letter: nil, peeked: false), bannerButton]
    }
}

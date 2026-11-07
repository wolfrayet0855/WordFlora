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
    /// `meanings` gives the gentle tier the wake puzzle's meaning line; the storm tier keeps its picture clue.
    static func weather(tier: WeatherPuzzleTier, eventDay: Int, attempt: Int, names: [String], economy: Economy = .default,
                        meanings: [String: String] = [:]) -> WakePuzzle? {
        switch tier {
        case .gentle:
            return make(plantId: "weather", day: eventDay &* 16 &+ attempt, names: names, meanings: meanings)
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
    /// Wild Weather's puzzle has two parts: the word, then a short butterfly catch (spec section 5).
    static func needsCatch(wild: Bool) -> Bool { wild }

    /// The catch goal: 3 friends, eased to 2 after two tries that ran out of time (`WakeRule.isEasier`).
    static func catchGoal(misses: Int) -> Int { WakeRule.butterflyGoal(dreamsInARow: misses) }

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

    /// A plant that arrives with the bonus word gets the same moment as a won word's plant (GameView): the big petal
    /// burst, with a level up's burst under it; CelebrationStyle then softens it for Reduce Motion, Calm and Quiet Garden.
    static func celebration(plantArrived: Bool, leveledUp: Bool) -> [CelebrationLevel] {
        guard plantArrived else { return [] }
        return leveledUp ? [.medium, .large] : [.large]
    }

    /// Exactly one sound for a solve: the win's sound when a plant arrives (or a level up), else the gentle wake chime.
    static func solveSound(plantArrived: Bool, leveledUp: Bool) -> SoundEvent {
        plantArrived ? CelebrationStyle.winSound(leveledUp: leveledUp, plantArrived: true) : .wake
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
    /// Wild Weather's part 2 (a short butterfly catch after the word).
    static let catchTitle = "One more part"
    static func catchLine(goal: Int) -> String { "Say hello to \(goal) friends to finish." }
    static let catchAgain = "The friends flew off. Try again!"

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
               slotLabel(0, letter: "V", peeked: true), slotLabel(1, letter: nil, peeked: false), bannerButton,
               catchTitle, catchLine(goal: 3), catchLine(goal: 2), catchAgain]
    }
}

// MARK: - Picture clue (design-preview/endgame critic: the storm tier's last rung, ready after the second peek)

extension WeatherPuzzlePolicy {
    /// The storm tier's last rung: "Picture clue after 2 peeks" until two peeks are used, then "Picture clue". Every
    /// rung is free and there is no time word. The gentle tier has no picture rung (nil).
    enum PictureClueRung: Equatable { case later, ready, shown }
    static let pictureCluePeeks = 2

    static func pictureClue(tier: WeatherPuzzleTier, peeks: Int, shown: Bool) -> PictureClueRung? {
        guard tier == .storm else { return nil }
        if shown { return .shown }
        return peeks >= pictureCluePeeks ? .ready : .later
    }
}

/// The answer's own plant picture plus a clue in words that says what the picture shows (its text equivalent, for
/// VoiceOver and for anyone who reads it). The words never use the plant's name.
struct PictureClue: Equatable {
    let imageName: String
    let text: String

    /// Nil when the answer is not a catalog plant or has no written clue (the rung then stays away).
    static func make(answer: String, catalog: [PlantInfo]) -> PictureClue? {
        guard let plant = catalog.first(where: { WakePuzzle.normalized($0.name) == WakePuzzle.normalized(answer) }),
              let text = looks[plant.plantId] else { return nil }
        return PictureClue(imageName: plant.imageName, text: text)
    }

    /// What each storm answer's picture shows, grade 2-3, without the name.
    static let looks: [String: String] = [
        "dandelion": "A fluffy white seed ball on a thin stem. The leaves have jagged edges.",
        "marigold": "A round flower packed with ruffled orange petals.",
        "sunflower": "A very tall stem with a big yellow face. The middle is brown.",
        "strawberry": "A low plant with small white flowers and red berries dotted with seeds.",
        "lavender": "Thin stems with tiny purple flowers at the top. They smell sweet.",
        "jasmine": "A climbing vine with small white flowers shaped like stars.",
        "snapdragon": "Tall spikes of bright flowers. Each one looks like a little mouth.",
        "saguaro_cactus": "A giant green desert plant with spines. Its arms point up to the sky.",
        "aloe_vera": "Thick, pointy green leaves with soft teeth on the sides.",
        "hibiscus": "A big bright flower with five wide petals and a long stick in the middle.",
        "cherry_blossom": "A tree covered in soft pink flowers in spring.",
        "venus_flytrap": "Green leaves that look like little jaws with spiky edges.",
        "corpse_flower": "One giant spike that rises out of a huge, frilly purple cup.",
        "welwitschia": "Two long, wide leaves that curl and spread out over the sand.",
        "pitcher_plant": "Leaves shaped like tall jugs, each with a little lid on top.",
        "sensitive_plant": "Soft, feathery leaves and fluffy pink puffball flowers.",
        "joshua_tree": "A spiky desert giant with twisty arms and tufts of sharp leaves.",
        "lithops": "Small, plump leaves that look just like little stones.",
        "rafflesia": "A huge red flower with white spots and a deep bowl in the middle.",
        "sago_palm": "Stiff, feathery green fronds that fan out from a short, rough trunk.",
        "ghost_pipe": "A small, waxy white stem that bends over at the top like a hook.",
        "passionflower": "A fancy flower with a ring of thin purple threads, like a crown.",
        "king_protea": "A huge pink flower shaped like a bowl, with pointed petals.",
        "bleeding_heart": "Pink flowers that hang in a row from a curved stem, like tiny lockets.",
        "wollemi_pine": "A tall evergreen with bumpy bark and flat, dark green needles.",
        "jade_vine": "Long hanging bunches of blue-green flowers shaped like claws.",
        "franklin_tree": "White flowers with yellow middles among shiny green leaves.",
        "ghost_orchid": "A white flower with long curly tails. It seems to float with no leaves.",
        "silversword": "A round ball of shiny, pale, pointy leaves, like a spiky globe.",
        "puya_raimondii": "A giant spike covered in tiny flowers, over a ball of spiky leaves.",
    ]
}

extension WeatherPuzzleCopy {
    /// The same words as a won word's new plant (GameView).
    static let plantFoundTitle = "New plant found!"
    static let levelUp = "Level up! New plants to find"
    static let continueOn = "Continue"
    static let pictureClue = "Picture clue"
    static let pictureClueLater = "Picture clue after 2 peeks"
    static let pictureClueHint = "Shows a picture of the plant, with a clue in words."
    /// VoiceOver for the clue card: the picture's text equivalent.
    static func pictureClueLabel(_ text: String) -> String { "Picture clue. \(text)" }
}

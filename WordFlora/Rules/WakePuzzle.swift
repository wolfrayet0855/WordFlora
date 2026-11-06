import Foundation

/// The word puzzle that can wake a seed. It is meant to be hard, but never stressful: no timer, unlimited free tries,
/// and a free "peek a letter" every 30 s. The answer is always a plant name from the catalog, and the same plant on
/// the same day always gets the same puzzle. (A word ladder was left out: it needs a word list the app does not ship.)
struct WakePuzzle: Equatable, Hashable {
    enum Variant: String, Hashable { case anagram, missingVowels }

    let variant: Variant
    /// Upper-case letters only.
    let answer: String
    /// One entry per letter of the answer: a given letter, or nil for a spot the player fills.
    let slots: [Character?]
    /// The letters the player places, shuffled. Together with the given letters they make up the answer exactly.
    let tiles: [Character]
    let hint: String
    let intro: String
    /// Slot indices after which a gap is drawn (two-word storm answers). Empty for the wake puzzle.
    var gaps: [Int] = []

    static let minLetters = 5
    static let maxLetters = 10
    static let peekInterval = 30.0
    private static let vowels: Set<Character> = ["A", "E", "I", "O", "U"]

    static func normalized(_ s: String) -> String { s.uppercased().filter { $0.isLetter && $0.isASCII } }

    /// Single-word plant names (no spaces or apostrophes) of a good puzzle length, upper-cased.
    static func candidates(from names: [String]) -> [String] {
        var seen = Set<String>()
        return names.compactMap { name -> String? in
            guard name.allSatisfy({ $0.isLetter && $0.isASCII }) else { return nil }
            let w = name.uppercased()
            guard (minLetters...maxLetters).contains(w.count), seen.insert(w).inserted else { return nil }
            return w
        }
    }

    /// Days since 2026-01-01 on the player's calendar; the puzzle changes once a day.
    static func day(for date: Date, calendar: Calendar = .current) -> Int {
        let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? .distantPast
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: epoch), to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// A stable string hash (FNV-1a): Swift's `hashValue` changes between launches.
    private static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    private static func shuffle(_ a: [Character], _ rng: inout SplitMix64) -> [Character] {
        var a = a
        guard a.count > 1 else { return a }
        for i in stride(from: a.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            a.swapAt(i, j)
        }
        return a
    }

    /// Builds today's puzzle for the plant being woken. Prefers a name other than that plant's own (which is on screen).
    static func make(plantId: String, day: Int, names: [String], easier: Bool = false) -> WakePuzzle? {
        let all = candidates(from: names)
        let others = all.filter { $0.lowercased() != plantId.lowercased() }
        let pool = others.isEmpty ? all : others
        guard !pool.isEmpty else { return nil }

        var rng = SplitMix64(seed: stableHash(plantId) ^ (UInt64(bitPattern: Int64(day)) &* 0x9E3779B97F4A7C15))
        let answer = pool[Int(rng.next() % UInt64(pool.count))]
        let letters = Array(answer)
        let vowelCount = letters.filter { vowels.contains($0) }.count
        let canHideVowels = vowelCount >= 2 && letters.count - vowelCount >= 2
        let variant: Variant = canHideVowels && rng.next() % 2 == 0 ? .missingVowels : .anagram

        var slots: [Character?] = variant == .missingVowels ? letters.map { vowels.contains($0) ? nil : $0 } : letters.map { _ in nil }
        if easier { slots[0] = letters[0] }
        let open = letters.indices.filter { slots[$0] == nil }.map { letters[$0] }
        var tiles = shuffle(open, &rng)
        if tiles == open && Set(open).count > 1 {      // never show the word already solved
            tiles = Array(tiles.dropFirst()) + [tiles[0]]
        }
        return WakePuzzle(variant: variant, answer: answer, slots: slots, tiles: tiles,
                          hint: WakeCopy.puzzleHint(letters: letters.count),
                          intro: variant == .anagram ? WakeCopy.puzzleIntroAnagram : WakeCopy.puzzleIntroVowels)
    }

    /// Right when the word is a plant name that uses exactly these letters and keeps the given letters in place.
    /// Another plant that fits the same letters counts too.
    func isCorrect(_ guess: String, validNames: [String]) -> Bool {
        let g = Self.normalized(guess)
        guard g.count == answer.count, g.sorted() == answer.sorted() else { return false }
        guard Set(validNames.map(Self.normalized)).contains(g) else { return false }
        for (i, ch) in Array(g).enumerated() { if let given = slots[i], given != ch { return false } }
        return true
    }
}

/// The player's board for one puzzle: tap a letter to place it in the next open spot, tap a spot to take it back.
struct WakePuzzleBoard: Equatable {
    let puzzle: WakePuzzle
    /// Tile index placed in each spot (nil when empty or locked).
    private(set) var placed: [Int?]
    /// Given or peeked letters, which cannot be taken back.
    private(set) var locked: [Character?]
    private(set) var consumed = Set<Int>()
    private var lastPeekAt = 0.0
    private let answer: [Character]

    /// `firstPeekFree`: the weather puzzle's storm tier gives the first peek at once, then one every 30 s.
    init(puzzle: WakePuzzle, firstPeekFree: Bool = false) {
        self.puzzle = puzzle
        if firstPeekFree { lastPeekAt = -WakePuzzle.peekInterval }
        self.placed = Array(repeating: nil, count: puzzle.slots.count)
        self.locked = puzzle.slots
        self.answer = Array(puzzle.answer)
    }

    var letters: [Character?] { placed.indices.map { locked[$0] ?? placed[$0].map { puzzle.tiles[$0] } } }
    func isUsed(_ tile: Int) -> Bool { consumed.contains(tile) || placed.contains(tile) }
    func isLocked(_ slot: Int) -> Bool { locked[slot] != nil }
    var guess: String? { letters.contains(nil) ? nil : String(letters.compactMap { $0 }) }
    func isSolved(validNames: [String]) -> Bool { guess.map { puzzle.isCorrect($0, validNames: validNames) } ?? false }

    mutating func tapTile(_ tile: Int) {
        guard puzzle.tiles.indices.contains(tile), !isUsed(tile),
              let slot = placed.indices.first(where: { locked[$0] == nil && placed[$0] == nil }) else { return }
        placed[slot] = tile
    }

    mutating func tapSlot(_ slot: Int) {
        guard placed.indices.contains(slot), locked[slot] == nil else { return }
        placed[slot] = nil
    }

    mutating func clear() { placed = placed.map { _ in nil } }

    private var openSlots: Int { locked.filter { $0 == nil }.count }

    /// A peek is free once 30 s have passed since the start (or the previous peek). It never fills the final spot.
    func canPeek(at elapsed: Double) -> Bool {
        elapsed - lastPeekAt >= WakePuzzle.peekInterval && openSlots > 1
    }

    /// Locks the right letter into the first spot that is empty or wrong. Returns false when no peek is available.
    @discardableResult
    mutating func peek(at elapsed: Double) -> Bool {
        guard canPeek(at: elapsed),
              let slot = placed.indices.first(where: { locked[$0] == nil && letters[$0] != answer[$0] }) else { return false }
        let ch = answer[slot]
        placed[slot] = nil
        let matching = puzzle.tiles.indices.filter { puzzle.tiles[$0] == ch && !consumed.contains($0) }
        guard let tile = matching.first(where: { !placed.contains($0) }) ?? matching.first else { return false }
        if let other = placed.firstIndex(of: tile) { placed[other] = nil }
        consumed.insert(tile)
        locked[slot] = ch
        lastPeekAt = elapsed
        return true
    }
}

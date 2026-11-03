/// Expected wrong guesses for a fixed letter-frequency guesser (spec section 19, P-02).
/// Used to RANK entries within a level; absolute bands are calibrated against the real bank, not assumed.
enum WordDifficulty {
    static let order = Array("ETAOINSHRDLCUMWFGYPBVKJXQZ")

    static func expectedMisses(_ word: String) -> Int {
        let letters = Set(word.uppercased().filter { $0.isLetter })
        var remaining = letters.count
        var misses = 0
        for ch in order {
            if remaining == 0 { break }
            if letters.contains(ch) { remaining -= 1 } else { misses += 1 }
        }
        return misses
    }
}

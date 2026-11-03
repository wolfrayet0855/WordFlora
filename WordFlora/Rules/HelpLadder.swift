/// Free, player-initiated help (spec section 19, P-04): hint2, then a vowel, then the first letter.
/// Never reveals the last unrevealed letter, so the player always makes the final guess.
enum HelpLadder {
    enum Rung: Hashable { case hint2, vowel, firstLetter }
    enum Step: Equatable { case hint2(String), reveal(Character) }

    static func next(used: Set<Rung>, word: String, guessed: Set<Character>, hint2: String?) -> Step? {
        let letters = word.filter { $0.isLetter }
        let unrevealed = Set(letters).subtracting(guessed)
        let canReveal: (Character) -> Bool = { unrevealed.contains($0) && unrevealed.count >= 2 }

        for rung in [Rung.hint2, .vowel, .firstLetter] where !used.contains(rung) {
            switch rung {
            case .hint2:
                if let h = hint2 { return .hint2(h) }
            case .vowel:
                let vowels = "AEIOU".filter { v in unrevealed.contains(v) }
                let best = vowels.max { a, b in
                    let ca = letters.filter { $0 == a }.count, cb = letters.filter { $0 == b }.count
                    return ca < cb   // max keeps the earliest of equal elements in AEIOU order
                }
                if let v = best, canReveal(v) { return .reveal(v) }
            case .firstLetter:
                if let f = letters.first, canReveal(f) { return .reveal(f) }
            }
        }
        return nil
    }
}

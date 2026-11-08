/// Free, player-initiated help (spec section 19, P-04): hint2, then a vowel, then the first letter.
/// Never reveals the last unrevealed letter, so the player always makes the final guess.
/// R2 (docs/pm/admob-full-spec.md section 2): a banked whisper adds a fourth rung after the other three, which reveals
/// the most frequent unrevealed consonant under the same rule. The caller never passes a whisper on the Daily Bloom or
/// the tutorial word.
enum HelpLadder {
    enum Rung: Hashable { case hint2, vowel, firstLetter, whisper }
    enum Step: Equatable { case hint2(String), reveal(Character) }

    static func next(used: Set<Rung>, word: String, guessed: Set<Character>, hint2: String?, whisper: Bool = false) -> Step? {
        nextRung(used: used, word: word, guessed: guessed, hint2: hint2, whisper: whisper)?.step
    }

    /// The next step and the rung it uses, so the caller marks the right rung as used.
    static func nextRung(used: Set<Rung>, word: String, guessed: Set<Character>, hint2: String?, whisper: Bool = false) -> (rung: Rung, step: Step)? {
        let letters = word.filter { $0.isLetter }
        let unrevealed = Set(letters).subtracting(guessed)
        let canReveal: (Character) -> Bool = { unrevealed.contains($0) && unrevealed.count >= 2 }
        let rungs: [Rung] = whisper ? [.hint2, .vowel, .firstLetter, .whisper] : [.hint2, .vowel, .firstLetter]

        for rung in rungs where !used.contains(rung) {
            switch rung {
            case .hint2:
                if let h = hint2 { return (rung, .hint2(h)) }
            case .vowel:
                let vowels = "AEIOU".filter { v in unrevealed.contains(v) }
                let best = vowels.max { a, b in
                    let ca = letters.filter { $0 == a }.count, cb = letters.filter { $0 == b }.count
                    return ca < cb   // max keeps the earliest of equal elements in AEIOU order
                }
                if let v = best, canReveal(v) { return (rung, .reveal(v)) }
            case .firstLetter:
                if let f = letters.first, canReveal(f) { return (rung, .reveal(f)) }
            case .whisper:
                if let c = whisperLetter(letters: letters, unrevealed: unrevealed), canReveal(c) { return (rung, .reveal(c)) }
            }
        }
        return nil
    }

    /// The most frequent unrevealed consonant; ties go to the one that comes first in the word.
    static func whisperLetter(letters: String, unrevealed: Set<Character>) -> Character? {
        var best: Character?, bestCount = 0
        for ch in letters where unrevealed.contains(ch) && !"AEIOU".contains(ch) {
            let n = letters.filter { $0 == ch }.count
            if n > bestCount { best = ch; bestCount = n }
        }
        return best
    }
}

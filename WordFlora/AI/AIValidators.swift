import Foundation

/// Output checks for any AI-written text shown to players (spec sections 5, 18, 19). Pure and model-free.
enum TextChecks {
    static func hasControlCharacters(_ s: String) -> Bool {
        s.unicodeScalars.contains { $0.value < 32 && $0 != "\n" || $0.value == 127 }
    }
    static func sentenceCount(_ s: String) -> Int {
        s.split(whereSeparator: { ".!?".contains($0) }).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    /// Share of non-space characters that are letters; filters symbol soup.
    static func letterRatio(_ s: String) -> Double {
        let chars = s.filter { !$0.isWhitespace }
        guard !chars.isEmpty else { return 0 }
        return Double(chars.filter { $0.isLetter }.count) / Double(chars.count)
    }
    static func lettersOnly(_ s: String) -> String { String(s.lowercased().filter { $0.isLetter }) }
}

enum HintValidator {
    /// A rephrased clue must not contain the answer, any 4-letter slice of it, or any of its words.
    static func isSafe(_ text: String, answer: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, t.count <= 200,
              !TextChecks.hasControlCharacters(t),
              TextChecks.sentenceCount(t) <= 2,
              TextChecks.letterRatio(t) >= 0.6,
              CopySafety.check(t).isEmpty else { return false }

        let flat = TextChecks.lettersOnly(t)
        let target = TextChecks.lettersOnly(answer)
        guard !target.isEmpty else { return false }
        if target.count < 4 { return !flat.contains(target) }
        let chars = Array(target)
        for i in 0...(chars.count - 4) where flat.contains(String(chars[i..<(i + 4)])) { return false }
        return true
    }
}

enum ExplainValidator {
    private static let ingestion = try! NSRegularExpression(pattern: "\\b(eat|eating|ate|taste|tasting|swallow|drink|brew|chew)\\b", options: .caseInsensitive)

    static func isSafe(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, t.count <= 400,
              !TextChecks.hasControlCharacters(t),
              TextChecks.sentenceCount(t) <= 4,
              TextChecks.letterRatio(t) >= 0.6,
              CopySafety.check(t).isEmpty else { return false }
        // Never encourage tasting or eating plants (kid safety); grown-up caveats are only allowed from vetted bank text.
        let range = NSRange(t.startIndex..., in: t)
        return ingestion.firstMatch(in: t, range: range) == nil
    }
}

/// Keeps "Ask the Gardener" on plants and gardens (spec section 5, P-20).
enum TopicGuard {
    private static let deny = ["address", "phone", "password", "weapon", "president", "movie", "favorite", "email", "where do you live",
                               "kill", "drug", "alcohol", "date me", "boyfriend", "girlfriend", "credit card", "location"]
    private static let allow = ["plant", "tree", "flower", "leaf", "leaves", "seed", "root", "garden", "bee", "butterfl", "petal", "bloom",
                                "soil", "water", "sun", "grow", "fern", "rose", "moss", "pollen", "nectar", "fruit", "forest", "bug",
                                "insect", "bird", "stem", "bud", "grass", "cactus", "orchid", "tulip", "season", "weather", "rain"]

    static func isOnTopic(_ question: String) -> Bool {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty, q.count <= 200 else { return false }
        if deny.contains(where: { q.contains($0) }) { return false }
        return allow.contains { q.contains($0) }
    }
}

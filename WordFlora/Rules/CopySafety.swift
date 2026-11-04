import Foundation

/// Emotional-safety copy linter (spec section 18, P16 + resting wording from section 19).
enum CopySafety {
    static let banned: [String] = [
        // guilt / absence
        "miss", "lonely", "alone", "waiting", "abandon", "neglect", "forgot", "forget",
        // loss / death
        "die", "dies", "died", "dying", "dead", "lost", "empty", "left", "broken", "lose streak", "broken streak", "last chance",
        // urgency
        "hurry", "now or never", "expires", "only", "last",
        // trait praise / comparison
        "smart", "genius", "talented", "best gardener", "better than", "beat",
    ]

    /// Returns the banned words/phrases found (empty = safe).
    static func check(_ text: String) -> [String] {
        banned.filter { phrase in
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: phrase) + "\\b"
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }
}

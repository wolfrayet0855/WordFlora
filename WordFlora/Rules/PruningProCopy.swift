import Foundation

/// Words for Pruning Pro on the plant page (docs/pm/badge-mechanics-art.md, section 3).
/// A faded bloom shows on some days on a flowering plant; a trim that day is a tidy trim. Deadheading is a true
/// gardening fact. Positive only, grade 2-3; every line is checked by CopySafety.
enum PruningProCopy {
    /// Under the plant while the faded bloom shows and the shears are ready.
    static let cue = "A faded flower is ready for a snip."
    /// The feedback line after a tidy trim (replaces the plain trim line for that tap).
    static let tidy = "Snip! A tidy trim."
    /// The fact under it.
    static let fact = "Snipping faded flowers helps new ones grow."
    static let blurb = "Trim plants when they are ready"
    /// On the next visit, once, under the plant where the fresh bud shows.
    static let freshBud = "A fresh bud is growing."

    // Accessibility
    /// Appended to the plant art's VoiceOver label while the faded bloom shows.
    static let cueSuffix = "ready for a trim"
    static func plantLabel(_ base: String) -> String { "\(base), \(cueSuffix)" }
    /// The Prune button's hint while the cue shows (its label stays "Prune").
    static let pruneHint = "Snips the faded flower"

    static var all: [String] {
        [cue, tidy, fact, blurb, freshBud, cueSuffix, plantLabel("Daisy, in flower"), pruneHint]
    }
}

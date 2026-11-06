import Foundation

/// Words for Gentle Net in the butterfly game (docs/pm/badge-mechanics-art.md, section 2).
/// A hello to a visitor while it rests on a flower is a gentle hello. Nothing ever says a visitor went away.
/// Positive only, grade 2-3; every line is checked by CopySafety.
enum GentleNetCopy {
    static let pill = "Gentle hello!"
    static let blurb = "Say hello to a friend resting on a flower"
    /// Shown once, the first time a visitor rests in a game (a small tip under the sky, then never again).
    static let tip = "Some friends rest on a flower. Say a soft hello!"

    /// Round summary line, after "N friends said hello". Not shown when it is 0, and never in Quiet Garden.
    static func summary(_ n: Int) -> String { n == 1 ? "1 gentle hello" : "\(n) gentle hellos" }

    // Accessibility
    /// The resting visitor's label (the flying ones keep their usual label).
    static func restingLabel(name: String) -> String { "\(name), resting on a flower" }
    static let restingHint = "Says a gentle hello"
    /// Read on the caught sticker that has the little heart.
    static let heartLabel = "Gentle hello"
    /// Posted as a VoiceOver announcement when a gentle hello lands (the pill is decorative).
    static func announcement(name: String) -> String { "Gentle hello to \(name)!" }

    static var all: [String] {
        [pill, blurb, tip, summary(1), summary(3), restingLabel(name: "Monarch"), restingHint, heartLabel,
         announcement(name: "Monarch")]
    }
}

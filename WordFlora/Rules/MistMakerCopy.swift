import Foundation

/// Words for the Mist tend button on the plant page (docs/pm/badge-mechanics-art.md, section 4).
/// One mist per plant per day (`PlantCollectible.lastMistedAt`), free, +1 growth or +2 for tropical, epiphyte and
/// shade plants. Positive only, grade 2-3; every line is checked by CopySafety.
enum MistMakerCopy {
    // Button
    static let button = "Mist"
    /// The button once this plant has had its mist today (like "Sunny today").
    static let doneLabel = "Misty today"

    // Lines
    static func done(name: String) -> String { "\(name) is fresh and misty today. More mist tomorrow!" }
    /// After a mist on a tropical, epiphyte or shade plant (the +2 ones).
    static func loves(name: String) -> String { "\(name) loves misty air!" }
    /// After a mist on any other plant.
    static func misted(name: String) -> String { "\(name) has fresh, misty leaves." }
    /// Shown once, the first time the Mist button appears.
    static let tip = "Some plants love a little mist on their leaves."
    /// Shown instead of the button's line when the mister is not in the Shed yet (button hidden in normal play).
    static let needMister = "Find the mister in the Shed to mist leaves."
    static let blurb = "Mist your plants' leaves"

    // Accessibility
    static func buttonLabel(name: String) -> String { "Mist \(name)" }
    static let buttonHint = "Sprays a fine mist on the leaves"
    static func doneButtonLabel(name: String) -> String { "\(name) is misty today" }

    static var all: [String] {
        [button, doneLabel, done(name: "Fern"), loves(name: "Fern"), misted(name: "Daisy"), tip, needMister, blurb,
         buttonLabel(name: "Fern"), buttonHint, doneButtonLabel(name: "Fern")]
    }
}

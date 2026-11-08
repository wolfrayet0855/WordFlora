import Foundation

/// Make it yours (docs/pm/engagement-quick-wins.md, task B): the name a player types for a plant. Stored in the
/// existing `PlantCollectible.nickname` ("" means the species name). Used by "Give it a name" on the win card and the
/// pencil on the plant page. The typed name is the player's own words: no CopySafety on it, and it never leaves the
/// device in a share (share cards and captions use the species name).
enum PlantName {
    static let maxLength = 16

    /// Trims spaces and new lines, keeps at most 16 characters (whole characters, so an emoji or an accent is never
    /// split), and gives "" when nothing is left with a letter or digit (empty, spaces, emoji or punctuation only).
    static func clean(_ typed: String) -> String {
        let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        let hasLetterOrDigit = kept.unicodeScalars.contains { CharacterSet.alphanumerics.contains($0) }
        return hasLetterOrDigit ? kept : ""
    }

    /// The name the app shows: the typed name, or the species name when there is none.
    static func display(nickname: String, species: String) -> String { nickname.isEmpty ? species : nickname }
}

/// Words for naming a plant and pinning it to the widget (swept by CopySafety in PlantNameTests).
enum PlantNameCopy {
    static let giveName = "Give it a name"
    static let giveNameHint = "Opens a box to name your plant."
    static let alertTitle = "Name your plant"
    static let save = "Save"
    static let notNow = "Not now"
    static func saved(_ name: String) -> String { "Hello! I love the name \(name)." }

    static let showOnWidget = "Show on my widget"
    static let showOnWidgetHint = "Puts this plant on your Home Screen widget."
    static let onWidget = "On your widget"
    static func widgetWillShow(_ name: String) -> String { "Your Home Screen widget will show \(name)." }
    static func addWidget(_ name: String) -> String { "Add the WordFlora widget to your Home Screen to see \(name) there." }

    static var fixed: [String] { [giveName, giveNameHint, alertTitle, save, notNow, showOnWidget, showOnWidgetHint, onWidget] }
    static func all(name: String) -> [String] { fixed + [saved(name), widgetWillShow(name), addWidget(name)] }
}

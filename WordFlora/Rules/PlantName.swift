import Foundation

/// Make it yours (docs/pm/engagement-quick-wins.md, task B): the name a player types for a plant. Stored in the
/// existing `PlantCollectible.nickname` ("" means the species name). Used by "Give it a name" on the win card and the
/// pencil on the plant page. The typed name is the player's own words: no CopySafety on it, and it never leaves the
/// device in a share (share cards and captions use the species name).
enum PlantName {
    static let maxLength = 16

    /// Combining marks kept on one base character (enough for any real accent, e.g. Vietnamese "ệ"; stacked "Zalgo" text
    /// is cut back to this).
    static let maxMarksPerCharacter = 2

    /// Removes bidi controls (they can reorder the text around the name), caps combining marks per character, trims
    /// spaces and new lines, keeps at most 16 characters (whole characters, so an emoji or an accent is never split),
    /// and gives "" when no character has a letter or digit as its base (empty, spaces, emoji, punctuation, or marks only).
    static func clean(_ typed: String) -> String {
        var scalars = String.UnicodeScalarView()
        scalars.append(contentsOf: typed.unicodeScalars.filter { !isBidiControl($0) })
        let tamed = String(scalars).map(capMarks).joined()
        let trimmed = tamed.trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = String(trimmed.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        return kept.contains(where: hasLetterOrDigitBase) ? kept : ""
    }

    /// U+061C, U+200E, U+200F, U+202A-U+202E, U+2066-U+2069.
    static func isBidiControl(_ s: Unicode.Scalar) -> Bool {
        switch s.value {
        case 0x061C, 0x200E, 0x200F, 0x202A...0x202E, 0x2066...0x2069: return true
        default: return false
        }
    }

    private static func isMark(_ s: Unicode.Scalar) -> Bool {
        switch s.properties.generalCategory {
        case .nonspacingMark, .spacingMark, .enclosingMark: return true
        default: return false
        }
    }

    /// Keeps the character's non-mark scalars and its first `maxMarksPerCharacter` marks.
    private static func capMarks(_ c: Character) -> String {
        var marks = 0
        var out = String.UnicodeScalarView()
        for s in c.unicodeScalars {
            // Variation selectors (U+FE00-FE0F) are marks by category but part of an emoji's look: always kept.
            if isMark(s) && !(0xFE00...0xFE0F).contains(s.value) { marks += 1; if marks > maxMarksPerCharacter { continue } }
            out.append(s)
        }
        return String(out)
    }

    /// The character starts with a letter or digit that is not itself a mark.
    private static func hasLetterOrDigitBase(_ c: Character) -> Bool {
        guard let base = c.unicodeScalars.first, !isMark(base) else { return false }
        return base.properties.isAlphabetic || base.properties.numericType != nil
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

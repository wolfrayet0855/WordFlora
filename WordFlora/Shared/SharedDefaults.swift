import Foundation

/// Preferences the widget must also read (Calm mode, Quiet Garden). Lives in the App Group, not standard defaults.
enum SharedDefaults {
    static let groupID = "group.beta.WordFlora"
    static var store: UserDefaults { UserDefaults(suiteName: groupID) ?? .standard }
    static var calmMode: Bool { store.bool(forKey: "calmMode") }
    static var quietGarden: Bool { store.bool(forKey: "quietGarden") }
}

import Foundation

/// Preferences the widget must also read (Calm mode, Quiet Garden). Lives in the App Group, not standard defaults.
enum SharedDefaults {
    static let groupID = "group.beta.WordFlora"
    static var store: UserDefaults { UserDefaults(suiteName: groupID) ?? .standard }
    static var calmMode: Bool { store.bool(forKey: "calmMode") }
    static var quietGarden: Bool { store.bool(forKey: "quietGarden") }
    /// Calm mode as the app reads it: a stored answer, else on for under 13 (AppSettings' default).
    static func calmMode(in d: UserDefaults) -> Bool {
        d.object(forKey: "calmMode") == nil ? d.string(forKey: "ageBand") == "under13" : d.bool(forKey: "calmMode")
    }
    /// The Garden weather setting (AppSettings.gardenWeather): off in Calm, else the player's choice, on by default.
    static func gardenWeather(in d: UserDefaults) -> Bool {
        guard !calmMode(in: d) else { return false }
        return d.object(forKey: "gardenWeather") == nil ? true : d.bool(forKey: "gardenWeather")
    }
    static var gardenWeather: Bool { gardenWeather(in: store) }
    /// The love exemption as the app reads it (`AppModel.loveExempt`): Quiet Garden, Calm, or under 13.
    static func loveExempt(in d: UserDefaults) -> Bool {
        d.bool(forKey: "quietGarden") || calmMode(in: d) || d.string(forKey: "ageBand") == "under13"
    }
}

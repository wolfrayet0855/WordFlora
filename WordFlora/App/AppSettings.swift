import SwiftUI

/// Player preferences, stored in UserDefaults (never in the game store). Spec sections 8, 18, 19.
@Observable
final class AppSettings {
    enum Appearance: String, CaseIterable { case system, light, dark }
    enum Difficulty: String, CaseIterable { case auto, gentle, standard, tricky }

    private let defaults: UserDefaults

    var soundOn: Bool { didSet { defaults.set(soundOn, forKey: "soundOn") } }
    var ambienceOn: Bool { didSet { defaults.set(ambienceOn, forKey: "ambienceOn") } }
    var hapticsOn: Bool { didSet { defaults.set(hapticsOn, forKey: "hapticsOn") } }
    var reduceMotionOverride: Bool { didSet { defaults.set(reduceMotionOverride, forKey: "reduceMotionOverride") } }
    var calmMode: Bool { didSet { defaults.set(calmMode, forKey: "calmMode") } }
    var quietGarden: Bool { didSet { defaults.set(quietGarden, forKey: "quietGarden") } }
    var showStreak: Bool { didSet { defaults.set(showStreak, forKey: "showStreak") } }
    var showEverything: Bool { didSet { defaults.set(showEverything, forKey: "showEverything") } }
    var remindMe: Bool { didSet { defaults.set(remindMe, forKey: "remindMe") } }
    var reminderHour: Int { didSet { defaults.set(reminderHour, forKey: "reminderHour") } }
    var reminderMinute: Int { didSet { defaults.set(reminderMinute, forKey: "reminderMinute") } }
    var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    var difficulty: Difficulty { didSet { defaults.set(difficulty.rawValue, forKey: "difficulty") } }
    var assistLevel: Int { didSet { defaults.set(assistLevel, forKey: "assistLevel") } }
    var ageBand: AgeBand? { didSet { defaults.set(ageBand?.rawValue, forKey: "ageBand") } }
    var onboardingComplete: Bool { didSet { defaults.set(onboardingComplete, forKey: "onboardingComplete") } }
    var completedSessions: Int { didSet { defaults.set(completedSessions, forKey: "completedSessions") } }

    var isUnderThirteen: Bool { ageBand == .under13 }
    var colorScheme: ColorScheme? {
        switch appearance { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }

    init(defaults: UserDefaults = SharedDefaults.store) {
        self.defaults = defaults
        func bool(_ k: String, _ d: Bool) -> Bool { defaults.object(forKey: k) == nil ? d : defaults.bool(forKey: k) }
        let age = defaults.string(forKey: "ageBand").flatMap(AgeBand.init(rawValue:))
        soundOn = bool("soundOn", true)
        hapticsOn = bool("hapticsOn", true)
        ambienceOn = bool("ambienceOn", false)     // off by default, offered once
        reduceMotionOverride = bool("reduceMotionOverride", false)
        // Younger players start in the gentlest configuration.
        calmMode = bool("calmMode", age == .under13)
        quietGarden = bool("quietGarden", false)
        showStreak = bool("showStreak", age != .under13)
        showEverything = bool("showEverything", false)
        remindMe = bool("remindMe", false)
        reminderHour = defaults.object(forKey: "reminderHour") == nil ? 17 : defaults.integer(forKey: "reminderHour")
        reminderMinute = defaults.integer(forKey: "reminderMinute")
        appearance = defaults.string(forKey: "appearance").flatMap(Appearance.init(rawValue:)) ?? .system
        difficulty = defaults.string(forKey: "difficulty").flatMap(Difficulty.init(rawValue:)) ?? .auto
        assistLevel = defaults.object(forKey: "assistLevel") == nil ? AssistTuner.defaultLevel(isUnderThirteen: age == .under13) : defaults.integer(forKey: "assistLevel")
        ageBand = age
        onboardingComplete = bool("onboardingComplete", false)
        completedSessions = defaults.integer(forKey: "completedSessions")
    }

    /// Applies the defaults that depend on the age answer (called once, when the player answers).
    func applyAgeDefaults(_ band: AgeBand) {
        ageBand = band
        let young = band == .under13
        calmMode = young
        showStreak = !young
        assistLevel = AssistTuner.defaultLevel(isUnderThirteen: young)
    }
}

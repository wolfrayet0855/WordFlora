import SwiftUI

/// Player preferences, stored in UserDefaults (never in the game store). Spec sections 8, 18, 19.
@Observable
final class AppSettings {
    enum Difficulty: String, CaseIterable { case auto, gentle, standard, tricky }

    private let defaults: UserDefaults

    var soundOn: Bool { didSet { defaults.set(soundOn, forKey: "soundOn") } }
    var ambienceOn: Bool { didSet { defaults.set(ambienceOn, forKey: "ambienceOn") } }
    /// Set when the player is entitled to iCloud sync; read at the NEXT launch to open the synced store.
    var cloudSyncEnabled: Bool { didSet { defaults.set(cloudSyncEnabled, forKey: "cloudSyncEnabled") } }
    var hapticsOn: Bool { didSet { defaults.set(hapticsOn, forKey: "hapticsOn") } }
    var reduceMotionOverride: Bool { didSet { defaults.set(reduceMotionOverride, forKey: "reduceMotionOverride") } }
    var calmMode: Bool { didSet { defaults.set(calmMode, forKey: "calmMode") } }
    var quietGarden: Bool { didSet { defaults.set(quietGarden, forKey: "quietGarden") } }
    var showStreak: Bool { didSet { defaults.set(showStreak, forKey: "showStreak") } }
    var showEverything: Bool { didSet { defaults.set(showEverything, forKey: "showEverything") } }
    var remindMe: Bool { didSet { defaults.set(remindMe, forKey: "remindMe") } }
    var reminderHour: Int { didSet { defaults.set(reminderHour, forKey: "reminderHour") } }
    var reminderMinute: Int { didSet { defaults.set(reminderMinute, forKey: "reminderMinute") } }
    var difficulty: Difficulty { didSet { defaults.set(difficulty.rawValue, forKey: "difficulty") } }
    var assistLevel: Int { didSet { defaults.set(assistLevel, forKey: "assistLevel") } }
    var ageBand: AgeBand? { didSet { defaults.set(ageBand?.rawValue, forKey: "ageBand") } }
    var onboardingComplete: Bool { didSet { defaults.set(onboardingComplete, forKey: "onboardingComplete") } }
    var completedSessions: Int { didSet { defaults.set(completedSessions, forKey: "completedSessions") } }
    var lastOpenedAt: Date? { didSet { defaults.set(lastOpenedAt, forKey: "lastOpenedAt") } }
    /// Milestones the Plus card has already appeared for, and when it last appeared (PlusOfferPolicy).
    var plusOfferMilestones: [String] { didSet { defaults.set(plusOfferMilestones, forKey: "plusOfferMilestones") } }
    var plusOfferLastAt: Date? { didSet { defaults.set(plusOfferLastAt, forKey: "plusOfferLastAt") } }
    /// The most recent wake-the-seed try, which drives the suggested challenge (WakeRule).
    var lastWakeChallenge: WakeChallenge? { didSet { defaults.set(lastWakeChallenge?.rawValue, forKey: "lastWakeChallenge") } }
    var lastWakeResult: WakeResult? { didSet { defaults.set(lastWakeResult?.rawValue, forKey: "lastWakeResult") } }
    var wakeDreamsInARow: Int { didSet { defaults.set(wakeDreamsInARow, forKey: "wakeDreamsInARow") } }
    /// The player's Garden weather choice (nil = never changed). Device-local, like Calm mode.
    var gardenWeatherChoice: Bool? { didSet { defaults.set(gardenWeatherChoice, forKey: "gardenWeather") } }
    /// Opt-in: the daily reminder mentions tomorrow's garden weather (off by default; never under 13).
    var weatherNotify: Bool { didSet { defaults.set(weatherNotify, forKey: "weatherNotify") } }
    /// The weather day key on which "Got it" hid the forecast card.
    var weatherCardDismissedDay: Int { didSet { defaults.set(weatherCardDismissedDay, forKey: "weatherCardDismissedDay") } }

    /// Speed bloom (opt-in, off by default, never prompted; SpeedBloom). Device-local, like Calm mode.
    var speedBloomOn: Bool { didSet { defaults.set(speedBloomOn, forKey: "speedBloomOn") } }
    /// Speed bloom's "Extra time": the gold ring takes half as long again.
    var speedBloomExtraTime: Bool { didSet { defaults.set(speedBloomExtraTime, forKey: "speedBloomExtraTime") } }

    /// Butterfly game, 13 and up: turns Quick wings off and brings back the gentle game. Device-local, like Speed bloom.
    var easierButterflies: Bool { didSet { defaults.set(easierButterflies, forKey: "easierButterflies") } }
    /// Gentle Net's tip ("Some friends rest on a flower") has been shown once on this device.
    var gentleNetTipShown: Bool { didSet { defaults.set(gentleNetTipShown, forKey: "gentleNetTipShown") } }
    /// The day the grown-ups' Family Sharing note last appeared in Settings (under 13 and unknown age, once a week
    /// at most; `FamilyShareNudge`). Device-local.
    var familyNudgeShownAt: Date? { didSet { defaults.set(familyNudgeShownAt, forKey: "familyNudgeShownAt") } }
    /// Mist Maker's tip ("Some plants love a little mist on their leaves.") has been shown once on this device.
    var mistTipShown: Bool { didSet { defaults.set(mistTipShown, forKey: "mistTipShown") } }
    /// The weekly garden note's week (day number of its Monday, `WeeklyNote.weekKey`) once shown. Device-local, never synced.
    var weeklyNoteSeenWeek: Int { didSet { defaults.set(weeklyNoteSeenWeek, forKey: "weeklyNoteSeenWeek") } }
    /// Device-local ad counters (`AdLedger` as JSON, key `adLedger`): per-perk uses, app open, native loads, the
    /// banked whisper. Never synced; the profile's synced day counts stay the backstop.
    var adLedgerJSON: String { didSet { defaults.set(adLedgerJSON, forKey: "adLedger") } }

    /// What the Speed bloom rule reads as each round begins.
    var speedBloomPrefs: SpeedBloom.Prefs {
        SpeedBloom.Prefs(optedIn: speedBloomOn, extraTime: speedBloomExtraTime, ageBand: ageBand, calmMode: calmMode, quietGarden: quietGarden)
    }

    /// Garden weather: off in Calm mode (the one Calm toggle decides, owner 2026-11-05), else the choice, on by default.
    /// The widget reads the same rule (SharedDefaults.gardenWeather).
    var gardenWeather: Bool {
        get { !calmMode && (gardenWeatherChoice ?? GardenWeather.defaultOn(calmMode: false)) }
        set { gardenWeatherChoice = newValue }
    }

    var isUnderThirteen: Bool { ageBand == .under13 }

    init(defaults: UserDefaults = SharedDefaults.store) {
        self.defaults = defaults
        func bool(_ k: String, _ d: Bool) -> Bool { defaults.object(forKey: k) == nil ? d : defaults.bool(forKey: k) }
        let age = defaults.string(forKey: "ageBand").flatMap(AgeBand.init(rawValue:))
        soundOn = bool("soundOn", true)
        hapticsOn = bool("hapticsOn", true)
        cloudSyncEnabled = bool("cloudSyncEnabled", false)
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
        difficulty = defaults.string(forKey: "difficulty").flatMap(Difficulty.init(rawValue:)) ?? .auto
        assistLevel = defaults.object(forKey: "assistLevel") == nil ? AssistTuner.defaultLevel(isUnderThirteen: age == .under13) : defaults.integer(forKey: "assistLevel")
        ageBand = age
        onboardingComplete = bool("onboardingComplete", false)
        completedSessions = defaults.integer(forKey: "completedSessions")
        lastOpenedAt = defaults.object(forKey: "lastOpenedAt") as? Date
        plusOfferMilestones = defaults.stringArray(forKey: "plusOfferMilestones") ?? []
        plusOfferLastAt = defaults.object(forKey: "plusOfferLastAt") as? Date
        lastWakeChallenge = defaults.string(forKey: "lastWakeChallenge").flatMap(WakeChallenge.init(rawValue:))
        lastWakeResult = defaults.string(forKey: "lastWakeResult").flatMap(WakeResult.init(rawValue:))
        wakeDreamsInARow = defaults.integer(forKey: "wakeDreamsInARow")
        gardenWeatherChoice = defaults.object(forKey: "gardenWeather") == nil ? nil : defaults.bool(forKey: "gardenWeather")
        weatherNotify = bool("weatherNotify", false)
        weatherCardDismissedDay = defaults.integer(forKey: "weatherCardDismissedDay")
        speedBloomOn = bool("speedBloomOn", false)
        speedBloomExtraTime = bool("speedBloomExtraTime", false)
        easierButterflies = bool("easierButterflies", false)
        gentleNetTipShown = bool("gentleNetTipShown", false)
        familyNudgeShownAt = defaults.object(forKey: "familyNudgeShownAt") as? Date
        mistTipShown = bool("mistTipShown", false)
        weeklyNoteSeenWeek = defaults.integer(forKey: "weeklyNoteSeenWeek")
        adLedgerJSON = defaults.string(forKey: "adLedger") ?? ""
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

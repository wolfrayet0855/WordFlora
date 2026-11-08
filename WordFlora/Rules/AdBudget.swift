import Foundation

/// Ad caps: compile-time defaults (spec section 3 with the ruled numbers of 2026-11-07). There is no remote config:
/// Release always uses these literals, and changing one is an app update. Debug builds can override them with the
/// launch argument `-adcaps "key=value,..."` or the preset `-uitest-adcaps-fast`; both are compiled out of Release.
struct AdCaps: Equatable {
    // Shared budgets (spec 1.1, ruled 11-07)
    var pushedPerDay = 6                                   // interstitial + app open
    var pushedPerSession = 2
    var fullScreenPerDay = 8                               // interstitial + app open + rewarded
    var fullScreenPerSession = 4
    var gapToPushed: TimeInterval = 600                    // any full-screen ad, then the next pushed one
    var gapToRewarded: TimeInterval = 30
    var gapToAppOpen: TimeInterval = 1800
    // App open (G4b)
    var appOpenPerDay = 1
    var appOpenMinBackground: TimeInterval = 4 * 3600
    var appOpenMinSessions = 3
    var appOpenLoadBudget: TimeInterval = 2.5
    // Collapsible Garden banner (G4b)
    var collapsiblePerSession = 1
    var collapsiblePerDay = 2
    var collapsibleMinSessions = 3
    // Native Shed card (G4b); Google's native ads expire after an hour, 30 min is the safe reuse
    var nativeMinSessions = 2
    var nativeReuse: TimeInterval = 1800
    var nativeLoadGap: TimeInterval = 60
    var nativeLoadsPerDay = 6
    // Rewarded perks
    var rewardedPerDay = 5
    var rewardedPerSession = 3
    var waterPerDay = 3
    var hintPerDay = 2
    var wakePerDay = 1
    var waterReward = 2
    /// Coming back after this long in the background starts a new ad visit.
    var sessionBreak: TimeInterval = 1800
    // The interstitial keeps AdGate.Context's own frequency 3, gap 180 s, 6 a day and the 5 s celebration window.

    func perPerkPerDay(_ perk: RewardedPerk) -> Int {
        switch perk {
        case .water: waterPerDay
        case .hint: hintPerDay
        case .wake: wakePerDay
        }
    }

    /// The caps in force: the literals in Release; Debug applies the launch-argument overrides.
    static var current: AdCaps {
        #if DEBUG
        return debugOverrides(arguments: ProcessInfo.processInfo.arguments)
        #else
        return AdCaps()
        #endif
    }

    #if DEBUG
    /// Debug only. `-uitest-adcaps-fast`: every gap 1 to 5 s and no session minimum (the caps themselves unchanged, so
    /// cap tests still bite). `-adcaps "gapToPushed=5,appOpenMinSessions=0"`: set single values; unknown keys are ignored.
    static func debugOverrides(arguments args: [String]) -> AdCaps {
        var c = AdCaps()
        if args.contains("-uitest-adcaps-fast") {
            c.gapToPushed = 5; c.gapToRewarded = 1; c.gapToAppOpen = 5; c.appOpenMinBackground = 2
            c.nativeLoadGap = 1; c.sessionBreak = 2
            c.appOpenMinSessions = 0; c.collapsibleMinSessions = 0; c.nativeMinSessions = 0
        }
        if let i = args.firstIndex(of: "-adcaps"), i + 1 < args.count {
            for pair in args[i + 1].split(separator: ",") {
                let kv = pair.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard kv.count == 2, let v = Double(kv[1]) else { continue }
                if !c.set(kv[0], v) { print("adcaps: unknown key \(kv[0])") }
            }
        }
        return c
    }

    private mutating func set(_ key: String, _ v: Double) -> Bool {
        let n = Int(v)
        switch key {
        case "pushedPerDay": pushedPerDay = n
        case "pushedPerSession": pushedPerSession = n
        case "fullScreenPerDay": fullScreenPerDay = n
        case "fullScreenPerSession": fullScreenPerSession = n
        case "gapToPushed": gapToPushed = v
        case "gapToRewarded": gapToRewarded = v
        case "gapToAppOpen": gapToAppOpen = v
        case "appOpenPerDay": appOpenPerDay = n
        case "appOpenMinBackground": appOpenMinBackground = v
        case "appOpenMinSessions": appOpenMinSessions = n
        case "appOpenLoadBudget": appOpenLoadBudget = v
        case "collapsiblePerSession": collapsiblePerSession = n
        case "collapsiblePerDay": collapsiblePerDay = n
        case "collapsibleMinSessions": collapsibleMinSessions = n
        case "nativeMinSessions": nativeMinSessions = n
        case "nativeLoadGap": nativeLoadGap = v
        case "nativeLoadsPerDay": nativeLoadsPerDay = n
        case "rewardedPerDay": rewardedPerDay = n
        case "rewardedPerSession": rewardedPerSession = n
        case "waterPerDay": waterPerDay = n
        case "hintPerDay": hintPerDay = n
        case "wakePerDay": wakePerDay = n
        case "sessionBreak": sessionBreak = v
        default: return false
        }
        return true
    }
    #endif
}

/// Device-local ad counters (spec 2.4): a JSON string under `adLedger` in the App Group defaults, read through
/// `AppSettings`. Not SwiftData and not CloudKit, so no stored model field and no CloudKit deploy. A reinstall or a
/// second device resets only this split; the synced day caps on the profile stay the backstop.
struct AdLedger: Codable, Equatable {
    var day = 0                              // yyyymmdd local; every count below resets when it changes
    var appOpen = 0, collapsible = 0, nativeLoads = 0, fullScreen = 0
    var adWater = 0, adHint = 0, adWake = 0
    var freeWater = 0, freeHint = 0, freeWake = 0
    var lastFullScreenAt: Date?, lastAppOpenAt: Date?, lastNativeLoadAt: Date?, lastBackgroundAt: Date?
    /// R2: one whisper banked for the next garden word (stays banked across days; it is one letter, not a currency).
    var whisperBanked = false
    /// H4 (G4b): the ad treatment last confirmed by the store ("none", "teen", "adult"; "" when never confirmed). A cold
    /// launch reads it to raise the return cue before entitlements load; the ad is presented only once they confirm.
    var cachedTreatment = ""

    /// A timestamp more than this far ahead of the clock is reset to now (a clock moved back by more than a day).
    static let clockSlack: TimeInterval = 86_400

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10_000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    /// The ledger as of `now`: day counts start fresh on a new local day (timestamps and the banked whisper stay),
    /// and timestamps far ahead of the clock are pulled back to now.
    func rolled(to now: Date, calendar: Calendar = .current) -> AdLedger {
        var l = self
        let today = Self.dayKey(now, calendar: calendar)
        if l.day != today {
            l = AdLedger(day: today, lastFullScreenAt: lastFullScreenAt, lastAppOpenAt: lastAppOpenAt,
                         lastNativeLoadAt: lastNativeLoadAt, lastBackgroundAt: lastBackgroundAt, whisperBanked: whisperBanked)
            l.cachedTreatment = cachedTreatment
        }
        func fix(_ d: Date?) -> Date? { d.map { $0.timeIntervalSince(now) > Self.clockSlack ? now : $0 } }
        l.lastFullScreenAt = fix(l.lastFullScreenAt)
        l.lastAppOpenAt = fix(l.lastAppOpenAt)
        l.lastNativeLoadAt = fix(l.lastNativeLoadAt)
        l.lastBackgroundAt = fix(l.lastBackgroundAt)
        return l
    }

    /// Records one use of a perk (ad or free).
    mutating func recordPerk(_ perk: RewardedPerk, viaAd: Bool) {
        switch (perk, viaAd) {
        case (.water, true): adWater += 1
        case (.water, false): freeWater += 1
        case (.hint, true): adHint += 1
        case (.hint, false): freeHint += 1
        case (.wake, true): adWake += 1
        case (.wake, false): freeWake += 1
        }
    }

    // MARK: JSON

    init(day: Int = 0, lastFullScreenAt: Date? = nil, lastAppOpenAt: Date? = nil, lastNativeLoadAt: Date? = nil,
         lastBackgroundAt: Date? = nil, whisperBanked: Bool = false) {
        self.day = day
        self.lastFullScreenAt = lastFullScreenAt; self.lastAppOpenAt = lastAppOpenAt
        self.lastNativeLoadAt = lastNativeLoadAt; self.lastBackgroundAt = lastBackgroundAt
        self.whisperBanked = whisperBanked
    }

    private enum CodingKeys: String, CodingKey {
        case day, appOpen, collapsible, nativeLoads, fullScreen, adWater, adHint, adWake, freeWater, freeHint, freeWake
        case lastFullScreenAt, lastAppOpenAt, lastNativeLoadAt, lastBackgroundAt, whisperBanked, cachedTreatment
    }

    /// Every key is optional, so a ledger written by an older or newer version still reads (missing counts are 0).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func int(_ k: CodingKeys) -> Int { (try? c.decodeIfPresent(Int.self, forKey: k)) ?? 0 }
        func date(_ k: CodingKeys) -> Date? { (try? c.decodeIfPresent(Date.self, forKey: k)) ?? nil }
        day = int(.day); appOpen = int(.appOpen); collapsible = int(.collapsible); nativeLoads = int(.nativeLoads)
        fullScreen = int(.fullScreen); adWater = int(.adWater); adHint = int(.adHint); adWake = int(.adWake)
        freeWater = int(.freeWater); freeHint = int(.freeHint); freeWake = int(.freeWake)
        lastFullScreenAt = date(.lastFullScreenAt); lastAppOpenAt = date(.lastAppOpenAt)
        lastNativeLoadAt = date(.lastNativeLoadAt); lastBackgroundAt = date(.lastBackgroundAt)
        whisperBanked = (try? c.decodeIfPresent(Bool.self, forKey: .whisperBanked)) ?? false
        cachedTreatment = (try? c.decodeIfPresent(String.self, forKey: .cachedTreatment)) ?? ""
    }

    /// An empty, missing or corrupt string reads as an empty ledger (never a crash, never a lock-out).
    static func decode(_ json: String) -> AdLedger {
        guard let data = json.data(using: .utf8), !data.isEmpty,
              let l = try? JSONDecoder().decode(AdLedger.self, from: data) else { return AdLedger() }
        return l
    }

    var json: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
}

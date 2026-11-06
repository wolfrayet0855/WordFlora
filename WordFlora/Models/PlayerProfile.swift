import SwiftData
import Foundation

@Model
final class PlayerProfile {
    var currentLevel: Int = 1
    var plantsEarnedThisLevel: Int = 0
    var roseOfJerichoCount: Int = 0
    var gamesPlayed: Int = 0

    // Tending + engagement (spec sections 3, 4, 11-12)
    var water: Int = 0
    var soil: Int = 0
    var lastTrickleAt: Date = Date.now
    var widgetPlantID: String?
    var streak: Int = 0
    var bestStreak: Int = 0
    var streakFreezes: Int = 0
    var lastPlayedDay: Date?
    var seenIds: [String] = []
    /// Pots recorded as earned (PotCatalog.recordEarned). Only ever grows; merged as a set union on sync and restore.
    /// Defaulted, so older stores and CloudKit records read as none recorded.
    var earnedPotIds: [String] = []
    var roundsSinceAd: Int = 0
    var ageBand: String?
    var roseSeedProgress: Int = 0
    /// Correct words toward the next plant (0 ..< Economy.wordsPerPlant). Defaulted, so older stores and CloudKit records read as 0.
    var wordsTowardPlant: Int = 0
    var lastRoundId: String?
    var gardenDays: Int = 0
    var lastGraceDay: Date?
    var shedPoints: Int = 0
    var toolsJSON: String = ""
    var activeToolId: String = "can"
    var badgesJSON: String = ""
    var albumJSON: String = ""
    var butterflyPlaysJSON: String = ""
    var glowLanterns: Int = 0
    var lastAdAt: Date?
    var adsToday: Int = 0
    var adsDay: Date?
    var rewardedToday: Int = 0
    var rewardedDay: Date?

    // Garden weather and the endgame (docs/pm/endgame-and-events-spec.md section 7, added 2026-11-05). All defaulted,
    // no unique constraints and no relationships, so lightweight migration and CloudKit accept them. Merged by
    // DataReconciler with the rule noted on each line; nothing here ever lowers an earned value.
    /// The per-player weather seed (0 = unset). Never derived from a device or user id. Merged with `weatherStartDay` as a pair.
    var weatherSeed: Int64 = 0
    /// The first day key weather may come (a week after the garden began). Pair rule: the smaller nonzero start wins.
    var weatherStartDay: Int = 0
    /// The highest day key the app has computed (clock guard). Merge: max.
    var weatherHighWaterDay: Int = 0
    /// The event day key the weather helpers were set out for. Merge: max.
    var weatherShelterDay: Int = 0
    /// Event day keys whose weather puzzle was solved. Merge: union, trimmed to the latest 30.
    var weatherRescuedDays: [Int] = []
    /// Fresh weather puzzles today (`weatherPuzzleDay` is its day key). Merge: the later day wins; same day, max.
    var weatherPuzzleDay: Int = 0
    var weatherPuzzleCount: Int = 0
    /// Wild Weather opt-in (any age, owner ruling 2026-11-05; Calm and Quiet Garden hide it). Merge: AND, so off wins.
    var wildWeather: Bool = false
    /// The first day key the weather gate opened. Merge: min of nonzero.
    var weatherGatedFromDay: Int = 0
    /// When the garden or Home was first opened on or after the latest event day. Merge: max.
    var weatherSeenAt: Date?
    /// When the free weather kit (all six helpers) arrived. Merge: min of non-nil.
    var weatherKitAt: Date?
    /// When the Grand Garden ceremony and the gold crown moment were seen, so each plays once. Merge: min of non-nil.
    var crownSeenAt: Date?
    var goldCrownSeenAt: Date?

    /// The onboarding guide was seen (finished or skipped) on some device. Defaulted, so older stores and CloudKit
    /// records read as not seen. Merge: OR, so once seen it stays seen.
    var guideSeen: Bool = false

    /// The daily tiny quest (Rules/DailyQuest.swift): its day key, the count so far and whether it is done. Defaulted,
    /// so older stores and CloudKit records read as no quest yet. Merge: the later day wins; same day, max count and OR.
    var questDay: Int = 0
    var questProgress: Int = 0
    var questDone: Bool = false

    var createdAt: Date = Date.now

    init() {}
}

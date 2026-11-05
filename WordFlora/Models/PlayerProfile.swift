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

    var createdAt: Date = Date.now

    init() {}
}

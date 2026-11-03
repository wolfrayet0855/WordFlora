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
    var roundsSinceAd: Int = 0
    var ageBand: String?
    var roseSeedProgress: Int = 0
    var lastRoundId: String?
    var gardenDays: Int = 0
    var lastGraceDay: Date?
    var shedPoints: Int = 0
    var toolsJSON: String = ""
    var activeToolId: String = "can"
    var badgesJSON: String = ""
    var albumJSON: String = ""
    var butterflyPlaysJSON: String = ""
    var lastAdAt: Date?
    var adsToday: Int = 0
    var adsDay: Date?
    var rewardedToday: Int = 0
    var rewardedDay: Date?

    init() {}
}

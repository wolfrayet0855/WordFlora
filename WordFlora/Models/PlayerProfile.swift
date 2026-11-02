import SwiftData

@Model
final class PlayerProfile {
    var currentLevel: Int
    var plantsEarnedThisLevel: Int
    var roseOfJerichoCount: Int
    var gamesPlayed: Int

    init() {
        currentLevel = 1
        plantsEarnedThisLevel = 0
        roseOfJerichoCount = 0
        gamesPlayed = 0
    }
}

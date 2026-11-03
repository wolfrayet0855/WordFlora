import Foundation

/// Tunable numbers (spec sections 16, 18, 19). Eventually loaded from Economy.json / remote config;
/// defaults live here so rules and tests never hard-code them.
struct Economy: Codable, Equatable {
    var roseThreshold = 8          // completed rounds per Rose
    var roseCap = 3
    var plantsPerLevel = 10
    var freezeCap = 2
    var freezeEarnDays = [5, 14]
    var freezeEveryDays = 14       // after the last earn day
    var graceWindowDays = 14
    var roseMilestones = [7, 30, 100]
    var maxPetals = 8

    // Tending (spec section 16)
    var waterGrowth = 4
    var soilGrowth = 12
    var sunGrowth = 2
    var dailyAbsorbCap = 10
    var soilBoostMultiplier = 1.5
    var soilBoostDays = 3
    var soilRichnessStep = 0.34
    var thirstyHours = 48.0
    var trickleHours = 4.0
    var trickleCap = 5
    var waterBankCap = 40
    var stageThresholds = [0.06, 0.22, 0.50, 1.0]
    var levelBaseCost = 180.0
    var levelCostMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4]

    static let `default` = Economy()
}

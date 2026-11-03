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

    static let `default` = Economy()
}

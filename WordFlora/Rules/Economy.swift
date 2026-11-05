import Foundation

/// Tunable numbers (spec sections 16, 18, 19). Eventually loaded from Economy.json / remote config;
/// defaults live here so rules and tests never hard-code them.
struct Economy: Codable, Equatable {
    var roseThreshold = 8          // completed rounds per Rose
    var roseCap = 3
    var plantsPerLevel = 10
    // Owner decision 2026-11-04: after the very first plant, a correct word moves toward the next plant and every
    // `wordsPerPlant`-th word brings it (hero words for an unfound plant still bring theirs at once).
    var wordsPerPlant = 3
    var freezeCap = 2
    var freezeEarnDays = [5, 14]
    var freezeEveryDays = 14       // after the last earn day
    var graceWindowDays = 14
    var roseMilestones = [7, 30, 100]
    var maxPetals = 8

    // Tending (spec section 16; owner decisions 2026-11-04). Each action has its own daily allowance per plant:
    // two drinks, one scoop of soil and one sunny spell a day. No action blocks another, and the allowances keep
    // a day's growth bounded (there is no shared daily cap any more).
    var waterGrowth = 3            // 5 with a soil boost (3 x 1.5, rounded)
    var waterPerDay = 2            // playtest knob: 3 is the other option the owner weighed
    var soilGrowth = 4             // soil is once a day
    var sunGrowth = 2              // sun is once a day
    var soilBoostMultiplier = 1.5
    var soilBoostDays = 3
    var soilRichnessStep = 0.34
    var thirstyHours = 48.0
    var trickleHours = 4.0
    var trickleCap = 5
    var waterBankCap = 40
    var stageThresholds = [0.06, 0.22, 0.50, 1.0]
    var levelBaseCost = 200.0
    var levelCostMultipliers = [1.0, 1.1, 1.2, 1.3, 1.4]

    // Garden weather (docs/pm/endgame-and-events-spec.md section 6.1; owner decisions 2026-11-04). Weather only ever
    // changes a look, or in opt-in Wild Weather a shown stage computed at display time: no stored value goes down.
    var weatherFirstWeekDays = 7
    var weatherBlockDays = 14
    var weatherEventWindow = 7
    var weatherBlockChance = 0.75
    var weatherBagBig = 3
    var weatherBagGentle = 7
    var weatherAffectedCap = 0.4
    var weatherLingerDays = 3
    var weatherMinPlants = 5
    var weatherMinTends = 2
    var weatherPuzzlesPerDay = 3
    var weatherPuzzleDays = 4          // the event day + 3
    var calmLingerDays = 1
    var weatherAwardGardenDays = 7
    var weatherClockSlackDays = 1
    var weatherPuzzleWords = 1
    var weatherAlgoVersion = 1
    /// The day key from which `weatherAlgoVersion` applies. Blocks that start earlier keep the previous version, so an
    /// update never rewrites a forecast already shown.
    var weatherAlgoCutoverDay = 0
    var wildMaxPlants = 4
    var wildMaxPlantsSheltered = 2
    var wildLingerDays = 4
    var wildSetback = 1
    var stormMinLetters = 7
    var stormMaxLetters = 14
    var stormDecoys = 1

    // Endgame (spec section 2)
    var goldenDaysNeeded = 7
    var bloomRankThresholds = [1, 10, 30, 75, 150, 300]

    static let `default` = Economy()
}

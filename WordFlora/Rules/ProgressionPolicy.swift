/// Two tracks (spec section 19, P-01): word level = 10 unique plants earned; garden level = all 10 at stage 4.
struct PlantProgress: Equatable {
    var level: Int
    var earned: Bool
    var stage: Int
}

enum ProgressionPolicy {
    static func wordLevel(plants: [PlantProgress], economy: Economy) -> Int {
        var level = 1
        while level < 5, plants.filter({ $0.level == level && $0.earned }).count >= economy.plantsPerLevel {
            level += 1
        }
        return level
    }

    static func gardenLevelComplete(_ level: Int, plants: [PlantProgress]) -> Bool {
        let inLevel = plants.filter { $0.level == level }
        return inLevel.count == 10 && inLevel.allSatisfy { $0.earned && $0.stage >= 4 }
    }

    static func selectableLevels(wordLevel: Int) -> [Int] { Array(1...max(1, wordLevel)) }
}

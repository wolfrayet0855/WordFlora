import SwiftData

@Model
final class PlantCollectible {
    var name: String
    var botanicalName: String
    var botanicalFact: String
    var level: Int
    var earnedCount: Int
    var imageName: String

    init(name: String, botanicalName: String, botanicalFact: String, level: Int, imageName: String) {
        self.name = name
        self.botanicalName = botanicalName
        self.botanicalFact = botanicalFact
        self.level = level
        self.earnedCount = 0
        self.imageName = imageName
    }
}

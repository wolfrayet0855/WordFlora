import SwiftData
import Foundation

@Model
final class PlantCollectible {
    var plantId: String = ""
    var name: String = ""
    var botanicalName: String = ""
    var botanicalFact: String = ""
    var level: Int = 1
    var earnedCount: Int = 0
    var imageName: String = ""

    // Tending (spec section 4)
    var growthPoints: Int = 0
    var stage: Int = 0                 // 0 seed ... 4 flourishing, forward-only
    var hydration: Double = 1.0
    var soilRichness: Double = 0.0
    var lastTendedAt: Date?
    var lastSunnyAt: Date?
    var absorbedToday: Int = 0
    var absorbDay: Date?
    var soilBoostUntil: Date?

    init(name: String, botanicalName: String, botanicalFact: String,
         level: Int, imageName: String, plantId: String? = nil) {
        self.name = name
        self.botanicalName = botanicalName
        self.botanicalFact = botanicalFact
        self.level = level
        self.imageName = imageName
        self.plantId = plantId ?? (imageName.hasPrefix("plant_") ? String(imageName.dropFirst(6)) : imageName)
    }
}

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
    /// Growth taken in today, all actions together (a record only; it no longer gates anything).
    var absorbedToday: Int = 0
    var absorbDay: Date?
    /// Drinks today, counted against `Economy.waterPerDay`. `waterDay` is the local start of the day they belong to.
    var waterToday: Int = 0
    var waterDay: Date?
    /// The last time soil was added; soil is once a day.
    var lastFedAt: Date?
    /// The last time a happy repot gave growth; that growth is once a day.
    var lastRepotGrowthAt: Date?
    var soilBoostUntil: Date?
    var lastPrunedAt: Date?
    /// The last Mist (Mist Maker): one mist per plant per calendar day. Optional like `lastPrunedAt`, so lightweight
    /// migration and CloudKit both accept it (`CD_lastMistedAt`); merged by max.
    var lastMistedAt: Date?
    var soilType: String = ""
    var nickname: String = ""
    var createdAt: Date = Date.now
    var lastLovedAt: Date?
    /// The love petal count the plant page last animated to, so a petal fall or regrowth plays once per change.
    var lastShownPips: Int = 5
    /// The pot the plant sits in (`PotCatalog` id). Empty means never chosen, drawn as plain blue.
    /// Defaulted, so lightweight migration and CloudKit both accept it.
    var potId: String = ""
    /// When the pot was last chosen, so iCloud keeps the latest pick. Kept apart from `lastTendedAt`, because picking
    /// a pot is not tending (it must not reset the thirsty look or move the widget). Defaulted for migration and CloudKit.
    var potChosenAt: Date = Date.distantPast
    /// Golden blooms (endgame): different days of tending once every plant is found, and the day key last counted.
    /// Merge: the later key wins and the count takes the max, so a count never goes down. Defaulted for migration and CloudKit.
    var goldenDays: Int = 0
    var goldenDayKey: Int = 0
    /// The Life panel's "what you saw last visit" key (weather slot, hearts, seed state; `LifePanelVisit.key`) and
    /// when it was recorded. The panel starts closed and opens on a visit where the key changed. Merge: the later
    /// visit wins and the key travels with its stamp. Defaulted for migration and CloudKit.
    var lifeSeenKey: String = ""
    var lifeSeenAt: Date = Date.distantPast

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

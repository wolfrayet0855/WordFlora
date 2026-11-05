import Foundation
import SwiftData

/// iCloud sync can leave two profiles or two copies of a plant (each device seeds its own before the first
/// sync lands). Merge them by taking the best progress of each field, never summing, so nothing is lost
/// and nothing is double counted.
enum DataReconciler {
    struct Report: Equatable { var profilesMerged = 0; var plantsMerged = 0 }

    @discardableResult
    static func reconcile(context: ModelContext, badgeDefs: [BadgeDef]) -> Report {
        var report = Report()
        let profiles = (try? context.fetch(FetchDescriptor<PlayerProfile>())) ?? []
        if profiles.count > 1 {
            let ordered = profiles.sorted { ($0.gamesPlayed, $1.createdAt) > ($1.gamesPlayed, $0.createdAt) }   // ties go to the oldest record, the same choice on every device
            let keeper = ordered[0]
            for other in ordered.dropFirst() { merge(other, into: keeper, defs: badgeDefs); context.delete(other); report.profilesMerged += 1 }
        }
        let plants = (try? context.fetch(FetchDescriptor<PlantCollectible>())) ?? []
        let groups = Dictionary(grouping: plants, by: \.plantId)
        for (_, group) in groups where group.count > 1 {
            let ordered = group.sorted { ($0.earnedCount, $0.growthPoints, $1.createdAt) > ($1.earnedCount, $1.growthPoints, $0.createdAt) }
            let keeper = ordered[0]
            for other in ordered.dropFirst() { merge(other, into: keeper); context.delete(other); report.plantsMerged += 1 }
        }
        if report.profilesMerged > 0 || report.plantsMerged > 0 { try? context.save() }
        return report
    }

    static func merge(_ o: PlayerProfile, into k: PlayerProfile, defs: [BadgeDef]) {
        k.currentLevel = max(k.currentLevel, o.currentLevel)
        k.plantsEarnedThisLevel = max(k.plantsEarnedThisLevel, o.plantsEarnedThisLevel)
        k.roseOfJerichoCount = max(k.roseOfJerichoCount, o.roseOfJerichoCount)
        k.gamesPlayed = max(k.gamesPlayed, o.gamesPlayed)
        k.water = max(k.water, o.water); k.soil = max(k.soil, o.soil)
        k.streak = max(k.streak, o.streak); k.bestStreak = max(k.bestStreak, o.bestStreak)
        k.streakFreezes = max(k.streakFreezes, o.streakFreezes)
        k.roseSeedProgress = max(k.roseSeedProgress, o.roseSeedProgress)
        k.wordsTowardPlant = max(k.wordsTowardPlant, o.wordsTowardPlant)
        k.gardenDays = max(k.gardenDays, o.gardenDays)
        k.shedPoints = max(k.shedPoints, o.shedPoints)
        k.glowLanterns = max(k.glowLanterns, o.glowLanterns)
        k.lastPlayedDay = [k.lastPlayedDay, o.lastPlayedDay].compactMap { $0 }.max()
        k.lastAdAt = [k.lastAdAt, o.lastAdAt].compactMap { $0 }.max()
        if k.ageBand == nil { k.ageBand = o.ageBand }
        if k.widgetPlantID == nil { k.widgetPlantID = o.widgetPlantID }
        var seen = k.seenIds; for id in o.seenIds where !seen.contains(id) { seen.append(id) }; k.seenIds = seen
        k.badgesJSON = BadgeState(json: k.badgesJSON, defs: defs).merged(with: BadgeState(json: o.badgesJSON, defs: defs)).json
        k.toolsJSON = ToolInventory(json: k.toolsJSON).merged(with: ToolInventory(json: o.toolsJSON)).json
        k.albumJSON = StickerAlbum(json: k.albumJSON).merged(with: StickerAlbum(json: o.albumJSON)).json
    }

    static func merge(_ o: PlantCollectible, into k: PlantCollectible) {
        // The pot: a chosen pot beats none; when both chose one, the later pick wins. Picks made before `potChosenAt`
        // existed carry no stamp, so between two unstamped picks the copy tended later wins (decided before the dates merge).
        // The stamp travels with the winning pot, so both devices settle on the same pot and stamp.
        if !o.potId.isEmpty {
            let oLater = o.potChosenAt != k.potChosenAt
                ? o.potChosenAt > k.potChosenAt
                : (o.lastTendedAt ?? .distantPast) > (k.lastTendedAt ?? .distantPast)
            if k.potId.isEmpty || oLater {
                k.potId = o.potId
                k.potChosenAt = o.potChosenAt
            }
        }
        k.earnedCount = max(k.earnedCount, o.earnedCount)
        k.growthPoints = max(k.growthPoints, o.growthPoints)
        k.stage = max(k.stage, o.stage)
        k.hydration = max(k.hydration, o.hydration); k.soilRichness = max(k.soilRichness, o.soilRichness)
        k.lastTendedAt = [k.lastTendedAt, o.lastTendedAt].compactMap { $0 }.max()
        k.lastSunnyAt = [k.lastSunnyAt, o.lastSunnyAt].compactMap { $0 }.max()
        k.lastPrunedAt = [k.lastPrunedAt, o.lastPrunedAt].compactMap { $0 }.max()
        k.lastLovedAt = [k.lastLovedAt, o.lastLovedAt].compactMap { $0 }.max()
        k.lastShownPips = max(k.lastShownPips, o.lastShownPips)
        k.lastFedAt = [k.lastFedAt, o.lastFedAt].compactMap { $0 }.max()
        k.lastRepotGrowthAt = [k.lastRepotGrowthAt, o.lastRepotGrowthAt].compactMap { $0 }.max()
        // Drinks belong to a day: the later day's count wins, and on the same day the larger count wins.
        switch (k.waterDay, o.waterDay) {
        case (nil, _?): k.waterDay = o.waterDay; k.waterToday = o.waterToday
        case let (kd?, od?) where od > kd: k.waterDay = od; k.waterToday = o.waterToday
        case let (kd?, od?) where od == kd: k.waterToday = max(k.waterToday, o.waterToday)
        default: break
        }
        if k.nickname.isEmpty { k.nickname = o.nickname }
        if k.soilType.isEmpty { k.soilType = o.soilType }
    }
}

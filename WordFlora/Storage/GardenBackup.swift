import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// A free, local copy of the player's garden as a small JSON file. Restoring merges best-of-each with the
/// same rules iCloud reconciliation uses, so a restore never lowers progress and never deletes anything.
/// Holds progress only: no age, no words played, no ad history. The single piece of personal text is a plant nickname.
struct GardenBackup: Codable, Equatable {
    static let currentSchema = 1
    static let kindName = "WordFlora garden backup"

    struct Profile: Codable, Equatable {
        var currentLevel = 1, plantsEarnedThisLevel = 0, roseOfJerichoCount = 0, gamesPlayed = 0
        var water = 0, soil = 0, streak = 0, bestStreak = 0, streakFreezes = 0
        var lastPlayedDay: Date?
        var seenIds: [String] = []
        var roseSeedProgress = 0, gardenDays = 0, shedPoints = 0, glowLanterns = 0
        var widgetPlantID: String?
        var toolsJSON = "", badgesJSON = "", albumJSON = ""
        // Words toward the next plant (added 2026-11-04). Optional, so backups saved before then still read (as 0).
        var wordsTowardPlant: Int?
        // Pots recorded as earned (added 2026-11-04). Optional, so backups saved before then still read (as none).
        var earnedPotIds: [String]?
        // Garden weather and the endgame (added 2026-11-05). All optional, so older backups still read (as unset).
        var weatherSeed: Int64?, weatherStartDay: Int?, weatherHighWaterDay: Int?, weatherShelterDay: Int?
        var weatherRescuedDays: [Int]?
        var weatherPuzzleDay: Int?, weatherPuzzleCount: Int?
        /// Restores only as off: a backup can turn Wild Weather off, never on.
        var wildWeather: Bool?
        var weatherGatedFromDay: Int?
        var weatherSeenAt: Date?, weatherKitAt: Date?, crownSeenAt: Date?, goldCrownSeenAt: Date?
        // The onboarding guide was seen (added 2026-11-05). Optional, so older backups read as not seen; merged by OR.
        var guideSeen: Bool?
        // The daily tiny quest (added 2026-11-06). Optional, so older backups read as no quest; merged best-of-day.
        var questDay: Int?, questProgress: Int?, questDone: Bool?
    }

    struct Plant: Codable, Equatable {
        var plantId: String
        var earnedCount = 0, growthPoints = 0, stage = 0
        var hydration = 1.0, soilRichness = 0.0
        var soilType = "", nickname = ""
        var lastTendedAt: Date?, lastSunnyAt: Date?, lastPrunedAt: Date?, lastLovedAt: Date?
        // Today's allowances (added 2026-11-04). All optional, so backups saved before then still read.
        var waterToday: Int?
        var waterDay: Date?, lastFedAt: Date?, lastRepotGrowthAt: Date?
        // The chosen pot (added 2026-11-04 with the pot collection). Optional, so older backups still read.
        var potId: String?
        // When that pot was chosen (added 2026-11-04). Optional, so older backups still read.
        var potChosenAt: Date?
        // Golden blooms (added 2026-11-05). Optional, so older backups still read (as none).
        var goldenDays: Int?, goldenDayKey: Int?
        // The Life panel's last-seen key and its stamp (added 2026-11-06). Optional, so older backups still read.
        var lifeSeenKey: String?, lifeSeenAt: Date?
    }

    enum ImportError: Error, Equatable {
        case unreadable, unknownVersion
        var message: String {
            switch self {
            case .unreadable: return "We couldn't read that file as a WordFlora garden backup. Nothing in your garden was changed."
            case .unknownVersion: return "That backup comes from a newer version of WordFlora. Please update the app and try again. Nothing in your garden was changed."
            }
        }
    }

    struct RestoreReport: Equatable { var plantsUpdated = 0 }

    enum Copy {
        static let backupTitle = "Back up my garden"
        static let restoreTitle = "Restore from a backup"
        static let footnote = "Save a copy of your garden as a file you keep. Restoring adds back what you had and never lowers anything you've grown since."
        static let backedUp = "Your garden backup is saved."
        static let restored = "Your garden is restored. Everything you'd grown since was kept."
    }

    var schemaVersion = GardenBackup.currentSchema
    var kind = GardenBackup.kindName
    var exportedAt: Date
    var profile: Profile
    var plants: [Plant]
    var gamesRecorded: Int

    // MARK: Export

    static func make(context: ModelContext, now: Date) -> GardenBackup {
        let p = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first
        var snap = Profile()
        if let p {
            snap = Profile(currentLevel: p.currentLevel, plantsEarnedThisLevel: p.plantsEarnedThisLevel, roseOfJerichoCount: p.roseOfJerichoCount,
                           gamesPlayed: p.gamesPlayed, water: p.water, soil: p.soil, streak: p.streak, bestStreak: p.bestStreak,
                           streakFreezes: p.streakFreezes, lastPlayedDay: p.lastPlayedDay, seenIds: p.seenIds, roseSeedProgress: p.roseSeedProgress,
                           gardenDays: p.gardenDays, shedPoints: p.shedPoints, glowLanterns: p.glowLanterns, widgetPlantID: p.widgetPlantID,
                           toolsJSON: p.toolsJSON, badgesJSON: p.badgesJSON, albumJSON: p.albumJSON, wordsTowardPlant: p.wordsTowardPlant)
        }
        if let p {
            snap.earnedPotIds = p.earnedPotIds
            snap.weatherSeed = p.weatherSeed; snap.weatherStartDay = p.weatherStartDay; snap.weatherHighWaterDay = p.weatherHighWaterDay
            snap.weatherShelterDay = p.weatherShelterDay; snap.weatherRescuedDays = p.weatherRescuedDays
            snap.weatherPuzzleDay = p.weatherPuzzleDay; snap.weatherPuzzleCount = p.weatherPuzzleCount; snap.wildWeather = p.wildWeather
            snap.weatherGatedFromDay = p.weatherGatedFromDay; snap.weatherSeenAt = p.weatherSeenAt; snap.weatherKitAt = p.weatherKitAt
            snap.crownSeenAt = p.crownSeenAt; snap.goldCrownSeenAt = p.goldCrownSeenAt
            snap.guideSeen = p.guideSeen
            snap.questDay = p.questDay; snap.questProgress = p.questProgress; snap.questDone = p.questDone
        }
        let plants = ((try? context.fetch(FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.plantId)]))) ?? []).map {
            Plant(plantId: $0.plantId, earnedCount: $0.earnedCount, growthPoints: $0.growthPoints, stage: $0.stage, hydration: $0.hydration,
                  soilRichness: $0.soilRichness, soilType: $0.soilType, nickname: $0.nickname, lastTendedAt: $0.lastTendedAt,
                  lastSunnyAt: $0.lastSunnyAt, lastPrunedAt: $0.lastPrunedAt, lastLovedAt: $0.lastLovedAt,
                  waterToday: $0.waterToday, waterDay: $0.waterDay, lastFedAt: $0.lastFedAt, lastRepotGrowthAt: $0.lastRepotGrowthAt,
                  potId: $0.potId, potChosenAt: $0.potChosenAt == .distantPast ? nil : $0.potChosenAt,
                  goldenDays: $0.goldenDays, goldenDayKey: $0.goldenDayKey,
                  lifeSeenKey: $0.lifeSeenKey.isEmpty ? nil : $0.lifeSeenKey,
                  lifeSeenAt: $0.lifeSeenAt == .distantPast ? nil : $0.lifeSeenAt)
        }
        let games = (try? context.fetchCount(FetchDescriptor<GameRecord>())) ?? 0
        return GardenBackup(exportedAt: now, profile: snap, plants: plants, gamesRecorded: games)
    }

    func encoded() throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try e.encode(self)
    }

    static func filename(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "WordFlora-garden-%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: Import

    static func decode(_ data: Data) -> Result<GardenBackup, ImportError> {
        struct Header: Decodable { var schemaVersion: Int; var kind: String }
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        guard let header = try? d.decode(Header.self, from: data), header.kind == kindName else { return .failure(.unreadable) }
        guard header.schemaVersion == currentSchema else { return .failure(.unknownVersion) }
        guard let backup = try? d.decode(GardenBackup.self, from: data), backup.isPlausible else { return .failure(.unreadable) }
        return .success(backup)
    }

    /// Checked before anything is touched, so a damaged file changes nothing.
    var isPlausible: Bool {
        let p = profile
        let pots = p.earnedPotIds ?? []
        guard pots.count <= 200, pots.allSatisfy({ !$0.isEmpty && $0.count <= 40 }) else { return false }
        let counts = [p.currentLevel, p.plantsEarnedThisLevel, p.roseOfJerichoCount, p.gamesPlayed, p.water, p.soil, p.streak,
                      p.bestStreak, p.streakFreezes, p.roseSeedProgress, p.gardenDays, p.shedPoints, p.glowLanterns, p.wordsTowardPlant ?? 0, gamesRecorded]
        guard counts.allSatisfy({ $0 >= 0 }), (1...100).contains(p.currentLevel) else { return false }
        let weatherCounts = [p.weatherHighWaterDay, p.weatherShelterDay, p.weatherPuzzleDay, p.weatherPuzzleCount, p.weatherGatedFromDay,
                             p.questDay, p.questProgress]
        guard weatherCounts.allSatisfy({ ($0 ?? 0) >= 0 }), (p.weatherRescuedDays ?? []).count <= 200 else { return false }
        return plants.allSatisfy { !$0.plantId.isEmpty && $0.earnedCount >= 0 && $0.growthPoints >= 0 && (0...4).contains($0.stage)
            && $0.hydration.isFinite && $0.soilRichness.isFinite && $0.nickname.count <= 60 && ($0.potId ?? "").count <= 40
            && ($0.goldenDays ?? 0) >= 0 && ($0.goldenDayKey ?? 0) >= 0
            && ($0.lifeSeenKey ?? "").count <= 120 }
    }

    static func restore(_ data: Data, into context: ModelContext, badgeDefs: [BadgeDef]) -> Result<RestoreReport, ImportError> {
        decode(data).map { $0.merge(into: context, badgeDefs: badgeDefs) }
    }

    @discardableResult
    func merge(into context: ModelContext, badgeDefs: [BadgeDef]) -> RestoreReport {
        let keeper: PlayerProfile
        if let existing = (try? context.fetch(FetchDescriptor<PlayerProfile>()))?.first { keeper = existing } else {
            keeper = PlayerProfile(); context.insert(keeper)
        }
        let o = PlayerProfile()          // never inserted: a carrier for the reconciler's merge rules
        o.earnedPotIds = profile.earnedPotIds ?? []
        o.currentLevel = profile.currentLevel; o.plantsEarnedThisLevel = profile.plantsEarnedThisLevel
        o.roseOfJerichoCount = profile.roseOfJerichoCount; o.gamesPlayed = profile.gamesPlayed
        o.water = profile.water; o.soil = profile.soil; o.streak = profile.streak; o.bestStreak = profile.bestStreak
        o.streakFreezes = profile.streakFreezes; o.lastPlayedDay = profile.lastPlayedDay; o.seenIds = profile.seenIds
        o.roseSeedProgress = profile.roseSeedProgress; o.gardenDays = profile.gardenDays; o.shedPoints = profile.shedPoints
        o.glowLanterns = profile.glowLanterns; o.widgetPlantID = profile.widgetPlantID
        o.toolsJSON = profile.toolsJSON; o.badgesJSON = profile.badgesJSON; o.albumJSON = profile.albumJSON
        o.wordsTowardPlant = profile.wordsTowardPlant ?? 0
        o.weatherSeed = profile.weatherSeed ?? 0; o.weatherStartDay = profile.weatherStartDay ?? 0
        o.weatherHighWaterDay = profile.weatherHighWaterDay ?? 0; o.weatherShelterDay = profile.weatherShelterDay ?? 0
        o.weatherRescuedDays = profile.weatherRescuedDays ?? []
        o.weatherPuzzleDay = profile.weatherPuzzleDay ?? 0; o.weatherPuzzleCount = profile.weatherPuzzleCount ?? 0
        // Merged by AND: a backup can only turn Wild Weather off, and one that never knew it leaves the setting alone.
        o.wildWeather = profile.wildWeather ?? keeper.wildWeather
        o.weatherGatedFromDay = profile.weatherGatedFromDay ?? 0
        o.weatherSeenAt = profile.weatherSeenAt; o.weatherKitAt = profile.weatherKitAt
        o.crownSeenAt = profile.crownSeenAt; o.goldCrownSeenAt = profile.goldCrownSeenAt
        o.guideSeen = profile.guideSeen ?? false
        o.questDay = profile.questDay ?? 0; o.questProgress = min(profile.questProgress ?? 0, 10); o.questDone = profile.questDone ?? false
        DataReconciler.merge(o, into: keeper, defs: badgeDefs)

        var report = RestoreReport()
        let existing = Dictionary(((try? context.fetch(FetchDescriptor<PlantCollectible>())) ?? []).map { ($0.plantId, $0) }, uniquingKeysWith: { a, _ in a })
        for s in plants {
            guard let k = existing[s.plantId] else { continue }      // a plant this version of the catalog does not have
            let c = PlantCollectible(name: "", botanicalName: "", botanicalFact: "", level: k.level, imageName: "", plantId: s.plantId)
            c.earnedCount = s.earnedCount; c.growthPoints = s.growthPoints; c.stage = s.stage
            c.hydration = s.hydration; c.soilRichness = s.soilRichness; c.soilType = s.soilType; c.nickname = s.nickname
            c.lastTendedAt = s.lastTendedAt; c.lastSunnyAt = s.lastSunnyAt; c.lastPrunedAt = s.lastPrunedAt; c.lastLovedAt = s.lastLovedAt
            c.waterToday = max(0, s.waterToday ?? 0); c.waterDay = s.waterDay; c.lastFedAt = s.lastFedAt; c.lastRepotGrowthAt = s.lastRepotGrowthAt
            c.potId = s.potId ?? ""; c.potChosenAt = s.potChosenAt ?? .distantPast
            c.goldenDays = max(0, s.goldenDays ?? 0); c.goldenDayKey = max(0, s.goldenDayKey ?? 0)
            c.lifeSeenKey = s.lifeSeenKey ?? ""; c.lifeSeenAt = s.lifeSeenAt ?? .distantPast
            DataReconciler.merge(c, into: k)
            report.plantsUpdated += 1
        }
        try? context.save()
        return report
    }
}

/// Wraps a backup for SwiftUI's file exporter.
struct GardenBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

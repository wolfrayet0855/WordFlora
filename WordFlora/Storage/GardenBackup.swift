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
                           toolsJSON: p.toolsJSON, badgesJSON: p.badgesJSON, albumJSON: p.albumJSON)
        }
        let plants = ((try? context.fetch(FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.plantId)]))) ?? []).map {
            Plant(plantId: $0.plantId, earnedCount: $0.earnedCount, growthPoints: $0.growthPoints, stage: $0.stage, hydration: $0.hydration,
                  soilRichness: $0.soilRichness, soilType: $0.soilType, nickname: $0.nickname, lastTendedAt: $0.lastTendedAt,
                  lastSunnyAt: $0.lastSunnyAt, lastPrunedAt: $0.lastPrunedAt, lastLovedAt: $0.lastLovedAt,
                  waterToday: $0.waterToday, waterDay: $0.waterDay, lastFedAt: $0.lastFedAt, lastRepotGrowthAt: $0.lastRepotGrowthAt)
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
        let counts = [p.currentLevel, p.plantsEarnedThisLevel, p.roseOfJerichoCount, p.gamesPlayed, p.water, p.soil, p.streak,
                      p.bestStreak, p.streakFreezes, p.roseSeedProgress, p.gardenDays, p.shedPoints, p.glowLanterns, gamesRecorded]
        guard counts.allSatisfy({ $0 >= 0 }), (1...100).contains(p.currentLevel) else { return false }
        return plants.allSatisfy { !$0.plantId.isEmpty && $0.earnedCount >= 0 && $0.growthPoints >= 0 && (0...4).contains($0.stage)
            && $0.hydration.isFinite && $0.soilRichness.isFinite && $0.nickname.count <= 60 }
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
        o.currentLevel = profile.currentLevel; o.plantsEarnedThisLevel = profile.plantsEarnedThisLevel
        o.roseOfJerichoCount = profile.roseOfJerichoCount; o.gamesPlayed = profile.gamesPlayed
        o.water = profile.water; o.soil = profile.soil; o.streak = profile.streak; o.bestStreak = profile.bestStreak
        o.streakFreezes = profile.streakFreezes; o.lastPlayedDay = profile.lastPlayedDay; o.seenIds = profile.seenIds
        o.roseSeedProgress = profile.roseSeedProgress; o.gardenDays = profile.gardenDays; o.shedPoints = profile.shedPoints
        o.glowLanterns = profile.glowLanterns; o.widgetPlantID = profile.widgetPlantID
        o.toolsJSON = profile.toolsJSON; o.badgesJSON = profile.badgesJSON; o.albumJSON = profile.albumJSON
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

import Foundation
import SwiftData

/// One SwiftData store shared by the app and the widget through the App Group. CloudKit sync is
/// switched on only for Plus subscribers; everyone else stays strictly local (spec sections 11-13).
enum SharedContainer {
    static let appGroupID = "group.beta.WordFlora"
    static let cloudContainerID = "iCloud.beta.WordFlora"

    static let schema = Schema([PlayerProfile.self, PlantCollectible.self, GameRecord.self])

    static func storeURL(groupContainer: URL?, appSupport: URL) -> URL {
        if let g = groupContainer {
            return g.appendingPathComponent("Library/Application Support/WordFlora.store")
        }
        return appSupport.appendingPathComponent("WordFlora.store")
    }

    /// Explicit .none for everyone else: the default (.automatic) would sync as soon as the entitlement exists.
    static func cloudDatabase(entitled: Bool) -> ModelConfiguration.CloudKitDatabase {
        entitled ? .private(cloudContainerID) : .none
    }

    static func make(inMemory: Bool = false, cloudSync: Bool = false) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        }
        let fm = FileManager.default
        let appSupport = URL.applicationSupportDirectory
        let group = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        let url = storeURL(groupContainer: group, appSupport: appSupport)

        if group != nil {
            // Pre-v2 installs used SwiftData's default store location.
            _ = StoreMigrator.migrateIfNeeded(from: appSupport.appendingPathComponent("default.store"), to: url)
        }
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudDatabase(entitled: cloudSync))
        return try ModelContainer(for: schema, configurations: config)
    }
}

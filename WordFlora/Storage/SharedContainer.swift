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

    /// Where the store lives. If the move into the App Group fails, keep using the old store rather than
    /// silently starting an empty one.
    static func resolveStoreURL(groupContainer: URL?, appSupport: URL) -> (url: URL, usedLegacy: Bool) {
        let url = storeURL(groupContainer: groupContainer, appSupport: appSupport)
        let legacy = appSupport.appendingPathComponent("default.store")
        guard groupContainer != nil else { return (url, false) }
        if case .failed = StoreMigrator.migrateIfNeeded(from: legacy, to: url) { return (legacy, true) }
        return (url, false)
    }

    /// `createIfMissing: false` is for the widget: it must never create a store the app has not made yet.
    static func make(inMemory: Bool = false, cloudSync: Bool = false, createIfMissing: Bool = true, storeURLOverride: URL? = nil) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        }
        let fm = FileManager.default
        let url: URL
        if let o = storeURLOverride { url = o } else {
            let group = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            url = resolveStoreURL(groupContainer: group, appSupport: URL.applicationSupportDirectory).url
        }
        if !createIfMissing && !fm.fileExists(atPath: url.path) { throw CocoaError(.fileNoSuchFile) }
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudDatabase(entitled: cloudSync))
        return try ModelContainer(for: schema, configurations: config)
    }
}

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

    /// SharedDefaults key that means "the store now lives in the App Group". Written by the app only, after the move is verified.
    static let homeKey = "storeHome"

    enum StoreRole { case app, appExtension }
    struct StoreChoice: Equatable { var url: URL; var usedLegacy: Bool }

    /// True when the store opens and holds at least one profile (any store that has been played in does).
    static func storeHasProfile(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path),
              let c = try? ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)) else { return false }
        return ((try? ModelContext(c).fetchCount(FetchDescriptor<PlayerProfile>())) ?? 0) > 0
    }

    private static func removeStore(at url: URL) {
        for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + suffix) }
    }

    /// App only. Moves the store into the App Group once, verifies the copy opens with a profile, then records that in
    /// `defaults`. Any failure keeps the old store in use and tries again next launch. The old store is never deleted.
    static func resolveForApp(groupContainer: URL?, appSupport: URL, defaults: UserDefaults) -> StoreChoice {
        let fm = FileManager.default
        let legacy = appSupport.appendingPathComponent("default.store")
        guard let g = groupContainer else {
            return fm.fileExists(atPath: legacy.path) ? StoreChoice(url: legacy, usedLegacy: true)
                                                      : StoreChoice(url: appSupport.appendingPathComponent("WordFlora.store"), usedLegacy: false)
        }
        let target = storeURL(groupContainer: g, appSupport: appSupport)
        if defaults.string(forKey: homeKey) == "group" { return StoreChoice(url: target, usedLegacy: false) }

        if fm.fileExists(atPath: target.path) {
            if storeHasProfile(at: target) { defaults.set("group", forKey: homeKey); return StoreChoice(url: target, usedLegacy: false) }
            // Unusable or empty and never confirmed: set it aside (never deleted) and move the real data in.
            let stale = URL(fileURLWithPath: target.path + ".stale")
            try? fm.removeItem(at: stale)
            try? fm.moveItem(at: target, to: stale)
            for suffix in ["-wal", "-shm"] { try? fm.removeItem(atPath: target.path + suffix) }
        }
        if fm.fileExists(atPath: legacy.path) {
            if case .migrated = StoreMigrator.migrateIfNeeded(from: legacy, to: target), storeHasProfile(at: target) {
                defaults.set("group", forKey: homeKey)
                return StoreChoice(url: target, usedLegacy: false)
            }
            removeStore(at: target)            // a bad copy must never look like the real store
            return StoreChoice(url: legacy, usedLegacy: true)
        }
        defaults.set("group", forKey: homeKey)       // fresh install
        return StoreChoice(url: target, usedLegacy: false)
    }

    /// Widgets, Siri and Control Center. Never moves or creates anything: unavailable until the app has marked the group store.
    static func resolveForExtension(groupContainer: URL?, defaults: UserDefaults) -> URL? {
        guard let g = groupContainer, defaults.string(forKey: homeKey) == "group" else { return nil }
        return storeURL(groupContainer: g, appSupport: URL.applicationSupportDirectory)
    }

    static func make(inMemory: Bool = false, cloudSync: Bool = false, createIfMissing: Bool = true, storeURLOverride: URL? = nil,
                     role: StoreRole = .app) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        }
        let fm = FileManager.default
        let url: URL
        if let o = storeURLOverride { url = o } else {
            let group = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            switch role {
            case .app: url = resolveForApp(groupContainer: group, appSupport: URL.applicationSupportDirectory, defaults: SharedDefaults.store).url
            case .appExtension:
                guard let u = resolveForExtension(groupContainer: group, defaults: SharedDefaults.store) else { throw CocoaError(.fileNoSuchFile) }
                url = u
            }
        }
        let mustExist = !createIfMissing || role == .appExtension
        if mustExist && !fm.fileExists(atPath: url.path) { throw CocoaError(.fileNoSuchFile) }
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudDatabase(entitled: cloudSync))
        return try ModelContainer(for: schema, configurations: config)
    }
}

/// Calm lines for when the shared garden cannot be read yet. Never mentions errors, loss or absence.
enum GardenFallback {
    static let widgetLine = "Your garden says hello. Open WordFlora to visit."
    static let intentLine = "Let's open WordFlora so your plants can say hello."
}

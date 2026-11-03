import XCTest
import SwiftData
@testable import WordFlora

/// Store location and move rules (reviewed design): only the app moves the store, "done" is a marker written after the copy
/// opens with a profile, widgets and intents never migrate or create stores.
@MainActor
final class StoreResolveTests: XCTestCase {
    var dir: URL!
    var support: URL!
    var group: URL!
    var defaults: UserDefaults!
    let fm = FileManager.default

    override func setUp() async throws {
        dir = fm.temporaryDirectory.appendingPathComponent("wf-store-\(UUID().uuidString)")
        support = dir.appendingPathComponent("support"); group = dir.appendingPathComponent("group")
        try fm.createDirectory(at: support, withIntermediateDirectories: true)
        try fm.createDirectory(at: group, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: "wf-store-\(UUID().uuidString)")!
    }
    override func tearDown() async throws { try? fm.removeItem(at: dir) }

    var legacy: URL { support.appendingPathComponent("default.store") }
    var groupStore: URL { SharedContainer.storeURL(groupContainer: group, appSupport: support) }

    /// A real SwiftData store with `profiles` PlayerProfile rows and the given water value.
    @discardableResult
    func makeStore(at url: URL, profiles: Int, water: Int = 1) throws -> URL {
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let c = try ModelContainer(for: SharedContainer.schema, configurations: ModelConfiguration(schema: SharedContainer.schema, url: url, cloudKitDatabase: .none))
        for _ in 0..<profiles { let p = PlayerProfile(); p.water = water; c.mainContext.insert(p) }
        try c.mainContext.save()
        return url
    }
    func waterIn(_ url: URL) throws -> Int? {
        let c = try ModelContainer(for: SharedContainer.schema, configurations: ModelConfiguration(schema: SharedContainer.schema, url: url, cloudKitDatabase: .none))
        return try c.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first?.water
    }

    func testNilGroupContainerUsesTheLegacyStoreNotAFreshOne() throws {
        try makeStore(at: legacy, profiles: 1)
        let r = SharedContainer.resolveForApp(groupContainer: nil, appSupport: support, defaults: defaults)
        XCTAssertEqual(r.url.lastPathComponent, "default.store"); XCTAssertTrue(r.usedLegacy)
    }

    func testFreshInstallUsesTheGroupStoreAndSetsTheMarker() {
        let r = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertEqual(r.url, groupStore); XCTAssertFalse(r.usedLegacy)
        XCTAssertEqual(defaults.string(forKey: SharedContainer.homeKey), "group")
    }

    func testSuccessfulMoveSetsTheMarkerAndKeepsTheLegacyFile() throws {
        try makeStore(at: legacy, profiles: 1, water: 7)
        let r = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertEqual(r.url, groupStore); XCTAssertFalse(r.usedLegacy)
        XCTAssertEqual(try waterIn(groupStore), 7)
        XCTAssertEqual(defaults.string(forKey: SharedContainer.homeKey), "group")
        XCTAssertTrue(fm.fileExists(atPath: legacy.path))        // never deleted
    }

    func testACopyThatCannotBeOpenedLeavesNoMarkerAndKeepsUsingLegacy() throws {
        try "not a database".write(to: legacy, atomically: true, encoding: .utf8)
        let r = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertEqual(r.url, legacy); XCTAssertTrue(r.usedLegacy)
        XCTAssertNil(defaults.string(forKey: SharedContainer.homeKey))
        XCTAssertEqual(try String(contentsOf: legacy, encoding: .utf8), "not a database")
    }

    func testRetryAfterAFailureCopiesTheLatestLegacyData() throws {
        let blocker = dir.appendingPathComponent("blocked-group")
        try "file".write(to: blocker, atomically: true, encoding: .utf8)             // the move cannot succeed yet
        try makeStore(at: legacy, profiles: 1, water: 2)
        let first = SharedContainer.resolveForApp(groupContainer: blocker, appSupport: support, defaults: defaults)
        XCTAssertTrue(first.usedLegacy); XCTAssertNil(defaults.string(forKey: SharedContainer.homeKey))
        let c = try ModelContainer(for: SharedContainer.schema, configurations: ModelConfiguration(schema: SharedContainer.schema, url: legacy, cloudKitDatabase: .none))
        try c.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first?.water = 9; try c.mainContext.save()
        let second = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertEqual(second.url, groupStore); XCTAssertFalse(second.usedLegacy)
        XCTAssertEqual(try waterIn(groupStore), 9)
    }

    func testStaleSidecarsAtTheNewPathDoNotBlockTheMove() throws {
        try makeStore(at: legacy, profiles: 1, water: 4)
        try fm.createDirectory(at: groupStore.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "junk".write(to: URL(fileURLWithPath: groupStore.path + "-wal"), atomically: true, encoding: .utf8)
        let r = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertEqual(r.url, groupStore); XCTAssertFalse(r.usedLegacy)
        XCTAssertEqual(try waterIn(groupStore), 4)
    }

    func testAnEmptyGroupStoreWithoutAMarkerIsMovedAsideAndLegacyIsMigrated() throws {
        try makeStore(at: groupStore, profiles: 0)
        try makeStore(at: legacy, profiles: 1, water: 6)
        let r = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertFalse(r.usedLegacy)
        XCTAssertEqual(try waterIn(groupStore), 6)
        XCTAssertTrue(fm.fileExists(atPath: groupStore.path + ".stale"))       // set aside, never deleted
    }

    func testAnUnmarkedGroupStoreWithAProfileIsAdoptedNotOverwritten() throws {
        try makeStore(at: groupStore, profiles: 1, water: 11)
        try makeStore(at: legacy, profiles: 1, water: 1)
        let r = SharedContainer.resolveForApp(groupContainer: group, appSupport: support, defaults: defaults)
        XCTAssertEqual(r.url, groupStore); XCTAssertFalse(r.usedLegacy)
        XCTAssertEqual(try waterIn(groupStore), 11)
        XCTAssertEqual(defaults.string(forKey: SharedContainer.homeKey), "group")
    }

    func testExtensionsNeverMigrateOrCreateAnything() throws {
        try makeStore(at: legacy, profiles: 1)
        let before = try fm.contentsOfDirectory(atPath: dir.path).sorted()
        XCTAssertNil(SharedContainer.resolveForExtension(groupContainer: group, defaults: defaults))   // marker unset: unavailable
        XCTAssertFalse(fm.fileExists(atPath: groupStore.path))
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: dir.path).sorted(), before)
    }

    func testExtensionsUseTheGroupStoreOnceTheAppHasMarkedIt() {
        defaults.set("group", forKey: SharedContainer.homeKey)
        XCTAssertEqual(SharedContainer.resolveForExtension(groupContainer: group, defaults: defaults), groupStore)
        XCTAssertNil(SharedContainer.resolveForExtension(groupContainer: nil, defaults: defaults))
    }

    func testFallbackLinesAreCopySafe() {
        for line in [GardenFallback.widgetLine, GardenFallback.intentLine] { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertFalse(CopySafety.check("Your garden is waiting.").isEmpty)       // the rejected wording really is banned
    }
}

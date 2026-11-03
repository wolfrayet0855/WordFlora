import XCTest
import SwiftData
@testable import WordFlora

final class StorageTests: XCTestCase {
    var dir: URL!
    let fm = FileManager.default

    override func setUpWithError() throws {
        dir = fm.temporaryDirectory.appendingPathComponent("wf-storage-\(UUID().uuidString)")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try? fm.removeItem(at: dir) }

    func write(_ name: String, _ text: String, in d: URL? = nil) throws -> URL {
        let url = (d ?? dir).appendingPathComponent(name)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    func read(_ url: URL) throws -> String { try String(contentsOf: url, encoding: .utf8) }

    func testNothingToMigrateWhenOldStoreMissing() {
        let new = dir.appendingPathComponent("group/WordFlora.store")
        XCTAssertEqual(StoreMigrator.migrateIfNeeded(from: dir.appendingPathComponent("old/default.store"), to: new), .notNeeded)
        XCTAssertFalse(fm.fileExists(atPath: new.path))
    }

    func testCopiesStoreAndSidecarFilesAndKeepsTheOriginal() throws {
        let old = try write("old/default.store", "DATA")
        _ = try write("old/default.store-wal", "WAL"); _ = try write("old/default.store-shm", "SHM")
        let new = dir.appendingPathComponent("group/WordFlora.store")
        XCTAssertEqual(StoreMigrator.migrateIfNeeded(from: old, to: new), .migrated)
        XCTAssertEqual(try read(new), "DATA")
        XCTAssertEqual(try read(URL(fileURLWithPath: new.path + "-wal")), "WAL")
        XCTAssertEqual(try read(URL(fileURLWithPath: new.path + "-shm")), "SHM")
        XCTAssertEqual(try read(old), "DATA")                  // original untouched
    }

    func testIsIdempotentAndNeverOverwritesAnExistingNewStore() throws {
        let old = try write("old/default.store", "OLD")
        let new = try write("group/WordFlora.store", "NEWER")
        XCTAssertEqual(StoreMigrator.migrateIfNeeded(from: old, to: new), .notNeeded)
        XCTAssertEqual(try read(new), "NEWER")
        let fresh = dir.appendingPathComponent("group2/WordFlora.store")
        XCTAssertEqual(StoreMigrator.migrateIfNeeded(from: old, to: fresh), .migrated)
        XCTAssertEqual(StoreMigrator.migrateIfNeeded(from: old, to: fresh), .notNeeded)
    }

    func testFailureLeavesOriginalIntactAndNoPartialStore() throws {
        let old = try write("old/default.store", "DATA")
        let blocker = try write("blocker", "i am a file, not a folder")
        let new = blocker.appendingPathComponent("WordFlora.store")      // parent is a file, so the copy cannot succeed
        if case .failed = StoreMigrator.migrateIfNeeded(from: old, to: new) {} else { XCTFail("expected failure") }
        XCTAssertEqual(try read(old), "DATA")
        XCTAssertFalse(fm.fileExists(atPath: new.path))
    }

    func testInterruptedEarlierAttemptIsCleanedUpAndRetried() throws {
        let old = try write("old/default.store", "DATA")
        let new = dir.appendingPathComponent("group/WordFlora.store")
        _ = try write("group/WordFlora.store.migrating", "HALF")           // leftover from a crash
        XCTAssertEqual(StoreMigrator.migrateIfNeeded(from: old, to: new), .migrated)
        XCTAssertEqual(try read(new), "DATA")
        XCTAssertFalse(fm.fileExists(atPath: new.path + ".migrating"))
    }

    func testStoreURLPrefersTheAppGroupAndFallsBackToAppSupport() {
        let group = URL(fileURLWithPath: "/g")
        let support = URL(fileURLWithPath: "/s")
        XCTAssertEqual(SharedContainer.storeURL(groupContainer: group, appSupport: support).path, "/g/Library/Application Support/WordFlora.store")
        XCTAssertEqual(SharedContainer.storeURL(groupContainer: nil, appSupport: support).path, "/s/WordFlora.store")
    }

    @MainActor
    func testInMemoryContainerHoldsAllModelsEndToEnd() throws {
        let container = try SharedContainer.make(inMemory: true)
        let ctx = container.mainContext
        ctx.insert(PlayerProfile())
        ctx.insert(PlantCollectible(name: "Rose", botanicalName: "r", botanicalFact: "f", level: 1, imageName: "plant_rose"))
        ctx.insert(GameRecord(wordGuessed: "ROSE", triviaQuestion: "h", won: true, petalsRemaining: 5, plantEarned: "Rose", level: 1))
        try ctx.save()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<PlayerProfile>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<PlantCollectible>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<GameRecord>()).count, 1)
    }

    func testCloudSyncIsOffUnlessEntitled() {
        // CloudKitDatabase is not Equatable, so compare descriptions: the entitled one must name our container.
        let off = String(describing: SharedContainer.cloudDatabase(entitled: false))
        let on = String(describing: SharedContainer.cloudDatabase(entitled: true))
        XCTAssertNotEqual(off, on)
        XCTAssertFalse(off.contains("iCloud.beta.WordFlora"))
        XCTAssertTrue(on.contains("iCloud.beta.WordFlora"), on)
    }

    /// SwiftData validates the schema against CloudKit's rules (defaults or optionals, no unique constraints) when the
    /// container opens in sync mode, so a successful open proves the models are ready for iCloud.
    @MainActor
    func testSchemaOpensInICloudSyncMode() throws {
        let url = dir.appendingPathComponent("sync-check.store")
        let config = ModelConfiguration(schema: SharedContainer.schema, url: url, cloudKitDatabase: SharedContainer.cloudDatabase(entitled: true))
        XCTAssertNoThrow(try ModelContainer(for: SharedContainer.schema, configurations: config))
    }
}


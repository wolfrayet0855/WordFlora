import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class ReconcileTests: XCTestCase {
    var container: ModelContainer!
    var ctx: ModelContext { container.mainContext }
    let defs = (try? BadgeCatalog.load()) ?? []

    override func setUp() async throws { container = try SharedContainer.make(inMemory: true) }

    func profiles() -> [PlayerProfile] { try! ctx.fetch(FetchDescriptor<PlayerProfile>()) }
    func plants() -> [PlantCollectible] { try! ctx.fetch(FetchDescriptor<PlantCollectible>()) }

    // MARK: profiles
    func testTwoDevicesProfilesMergeIntoOneWithTheBestProgress() {
        let a = PlayerProfile(); a.currentLevel = 2; a.gamesPlayed = 10; a.gardenDays = 4; a.bestStreak = 3; a.water = 5; a.shedPoints = 12; a.roseOfJerichoCount = 1
        a.seenIds = ["x", "y"]
        let b = PlayerProfile(); b.currentLevel = 1; b.gamesPlayed = 30; b.gardenDays = 9; b.bestStreak = 7; b.water = 2; b.shedPoints = 40; b.roseOfJerichoCount = 0
        b.seenIds = ["y", "z"]
        ctx.insert(a); ctx.insert(b); try! ctx.save()
        let report = DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        XCTAssertEqual(profiles().count, 1); XCTAssertEqual(report.profilesMerged, 1)
        let m = profiles()[0]
        XCTAssertEqual(m.currentLevel, 2); XCTAssertEqual(m.gamesPlayed, 30); XCTAssertEqual(m.gardenDays, 9); XCTAssertEqual(m.bestStreak, 7)
        XCTAssertEqual(m.water, 5); XCTAssertEqual(m.shedPoints, 40); XCTAssertEqual(m.roseOfJerichoCount, 1)       // best of each, never summed
        XCTAssertEqual(Set(m.seenIds), ["x", "y", "z"])
    }

    func testBadgesToolsAndAlbumsAreMergedNotOverwritten() {
        var ba = BadgeState(defs: defs); ba.record(.feeds, amount: 30, now: Date(timeIntervalSince1970: 100))
        var bb = BadgeState(defs: defs); bb.record(.waterings, amount: 30, now: Date(timeIntervalSince1970: 200))
        var ta = ToolInventory(); ta.unlock(.lamp)
        var tb = ToolInventory(); var pts = 500; _ = tb.upgrade(.can, shedPoints: &pts)
        var aa = StickerAlbum(); aa.add(["monarch"]); var ab = StickerAlbum(); ab.add(["monarch", "luna"])
        let a = PlayerProfile(); a.gamesPlayed = 1; a.badgesJSON = ba.json; a.toolsJSON = ta.json; a.albumJSON = aa.json
        let b = PlayerProfile(); b.gamesPlayed = 2; b.badgesJSON = bb.json; b.toolsJSON = tb.json; b.albumJSON = ab.json
        ctx.insert(a); ctx.insert(b); try! ctx.save()
        _ = DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        let m = profiles()[0]
        let badges = BadgeState(json: m.badgesJSON, defs: defs)
        XCTAssertEqual(badges.progress(of: .feeds), 30); XCTAssertEqual(badges.progress(of: .waterings), 30)
        let inv = ToolInventory(json: m.toolsJSON)
        XCTAssertEqual(inv.tier(of: .lamp), 1); XCTAssertEqual(inv.tier(of: .can), 2)
        let album = StickerAlbum(json: m.albumJSON)
        XCTAssertEqual(album.count(of: "monarch"), 1); XCTAssertEqual(album.count(of: "luna"), 1)
    }

    // MARK: plants
    func testDuplicatePlantsMergeByPlantIdKeepingTheBestProgress() {
        for _ in 0..<2 { try! PlantCatalog.seedIfNeeded(context: ctx) }
        let extra = PlantCollectible(name: "Rose", botanicalName: "r", botanicalFact: "f", level: 1, imageName: "plant_rose", plantId: "rose")
        extra.earnedCount = 3; extra.growthPoints = 90; extra.stage = 3; extra.nickname = "Rosie"; extra.lastTendedAt = Date(timeIntervalSince1970: 500)
        ctx.insert(extra)
        plants().first { $0.plantId == "rose" && $0 !== extra }?.earnedCount = 1
        try! ctx.save()
        XCTAssertEqual(plants().count, 51)
        let report = DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        XCTAssertEqual(plants().count, 50); XCTAssertEqual(report.plantsMerged, 1)
        let rose = plants().first { $0.plantId == "rose" }!
        XCTAssertEqual(rose.earnedCount, 3); XCTAssertEqual(rose.growthPoints, 90); XCTAssertEqual(rose.stage, 3); XCTAssertEqual(rose.nickname, "Rosie")
    }

    func testShownLovePetalsMergeToTheHigherCountAndDefaultToFive() {
        let a = PlantCollectible(name: "Rose", botanicalName: "r", botanicalFact: "f", level: 1, imageName: "plant_rose", plantId: "rose")
        XCTAssertEqual(a.lastShownPips, 5)
        let b = PlantCollectible(name: "Rose", botanicalName: "r", botanicalFact: "f", level: 1, imageName: "plant_rose", plantId: "rose")
        a.lastShownPips = 2; b.lastShownPips = 4
        DataReconciler.merge(b, into: a)
        XCTAssertEqual(a.lastShownPips, 4)      // at worst a fall plays once more; never a stale regrow
    }

    func testGardenLevelsCanCompleteAgainAfterDuplicatesAreMerged() {
        try! PlantCatalog.seedIfNeeded(context: ctx)
        for p in plants() where p.level == 1 { p.earnedCount = 1; p.stage = 4 }
        for p in plants().filter({ $0.level == 1 }) {                       // the second device seeded its own copies
            let copy = PlantCollectible(name: p.name, botanicalName: p.botanicalName, botanicalFact: p.botanicalFact, level: 1, imageName: p.imageName, plantId: p.plantId)
            ctx.insert(copy)
        }
        try! ctx.save()
        let progress = { self.plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) } }
        XCTAssertFalse(ProgressionPolicy.gardenLevelComplete(1, plants: progress()))     // the broken state the reviewer described
        _ = DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        XCTAssertTrue(ProgressionPolicy.gardenLevelComplete(1, plants: progress()))
    }

    // MARK: safety
    func testReconcileIsIdempotentAndLeavesACleanStoreAlone() {
        try! PlantCatalog.seedIfNeeded(context: ctx); ctx.insert(PlayerProfile()); try! ctx.save()
        let r1 = DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        XCTAssertEqual(r1.profilesMerged, 0); XCTAssertEqual(r1.plantsMerged, 0)
        XCTAssertEqual(plants().count, 50); XCTAssertEqual(profiles().count, 1)
        XCTAssertEqual(DataReconciler.reconcile(context: ctx, badgeDefs: defs).plantsMerged, 0)
    }

    func testReconcileOnAnEmptyStoreDoesNothing() {
        let r = DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        XCTAssertEqual(r.profilesMerged, 0); XCTAssertEqual(r.plantsMerged, 0)
    }

    func testAppModelReloadsItsProfileAndBadgesAfterReconcile() throws {
        let suite = UserDefaults(suiteName: "wf-rec-\(UUID().uuidString)")!
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: AppSettings(defaults: suite), bank: bank, notifications: ReminderTests.FakeCenter())
        let other = PlayerProfile(); other.gamesPlayed = 99; other.shedPoints = 80
        var b = BadgeState(defs: defs); b.record(.feeds, amount: 30, now: .now); other.badgesJSON = b.json
        ctx.insert(other); try ctx.save()
        app.reconcileSyncedData()
        XCTAssertEqual(profiles().count, 1)
        XCTAssertEqual(app.profile?.gamesPlayed, 99)
        XCTAssertEqual(app.badges.progress(of: .feeds), 30)
    }

    // MARK: store location is covered by StoreResolveTests

    func testTheWidgetNeverCreatesAStoreThatDoesNotExist() {
        XCTAssertThrowsError(try SharedContainer.make(createIfMissing: false, storeURLOverride: URL(fileURLWithPath: "/tmp/wf-definitely-missing-\(UUID().uuidString).store")))
    }

    func testDegradedStoreIsReportedNotHidden() throws {
        let suite = UserDefaults(suiteName: "wf-deg-\(UUID().uuidString)")!
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: AppSettings(defaults: suite), bank: bank, notifications: ReminderTests.FakeCenter(), storeDegraded: true)
        XCTAssertTrue(app.storeDegraded)
        XCTAssertTrue(AppModel.degradedStoreMessage.contains("saved garden"))
        XCTAssertEqual(CopySafety.check(AppModel.degradedStoreMessage), [])
    }

    func testTiesPickTheSameKeeperRegardlessOfInsertionOrder() {
        func run(oldFirst: Bool) -> Date {
            let c = try! SharedContainer.make(inMemory: true)
            let old = PlayerProfile(); old.createdAt = Date(timeIntervalSince1970: 100)
            let new = PlayerProfile(); new.createdAt = Date(timeIntervalSince1970: 200)
            for p in (oldFirst ? [old, new] : [new, old]) { c.mainContext.insert(p) }
            try! c.mainContext.save()
            DataReconciler.reconcile(context: c.mainContext, badgeDefs: [])
            return try! c.mainContext.fetch(FetchDescriptor<PlayerProfile>())[0].createdAt
        }
        XCTAssertEqual(run(oldFirst: true), Date(timeIntervalSince1970: 100))
        XCTAssertEqual(run(oldFirst: false), Date(timeIntervalSince1970: 100))
    }
}

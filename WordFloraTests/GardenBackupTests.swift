import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class GardenBackupTests: XCTestCase {
    var container: ModelContainer!
    var ctx: ModelContext { container.mainContext }
    let defs = (try? BadgeCatalog.load()) ?? []

    override func setUp() async throws {
        container = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: ctx)
        ctx.insert(PlayerProfile()); try ctx.save()
    }

    func profile() -> PlayerProfile { try! ctx.fetch(FetchDescriptor<PlayerProfile>()).first! }
    func plant(_ id: String, in c: ModelContext? = nil) -> PlantCollectible {
        try! (c ?? ctx).fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == id }!
    }

    func growSomething() {
        let p = profile()
        p.currentLevel = 3; p.gamesPlayed = 42; p.water = 7; p.soil = 4; p.bestStreak = 9; p.streak = 5; p.gardenDays = 12
        p.shedPoints = 80; p.roseOfJerichoCount = 2; p.seenIds = ["w1", "w2"]; p.ageBand = "eighteenPlus"
        var tools = ToolInventory(); tools.unlock(.lamp); p.toolsJSON = tools.json
        var album = StickerAlbum(); album.add(["monarch"]); p.albumJSON = album.json
        var badges = BadgeState(defs: defs); badges.record(.feeds, amount: 30, now: Date(timeIntervalSince1970: 100)); p.badgesJSON = badges.json
        let rose = plant("rose")
        rose.earnedCount = 3; rose.growthPoints = 90; rose.stage = 3; rose.soilRichness = 0.5; rose.nickname = "Rosie"
        rose.lastTendedAt = Date(timeIntervalSince1970: 1_000); rose.lastLovedAt = Date(timeIntervalSince1970: 2_000)
        ctx.insert(GameRecord(wordGuessed: "SECRET", triviaQuestion: "q", won: true, petalsRemaining: 3, plantEarned: "rose", level: 1))
        try! ctx.save()
    }

    func testRoundTripRestoresProgressIntoAFreshGarden() throws {
        growSomething()
        let data = try GardenBackup.make(context: ctx, now: Date(timeIntervalSince1970: 5_000)).encoded()

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        let result = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs)
        guard case .success = result else { return XCTFail("restore failed") }

        let p = try fresh.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first!
        XCTAssertEqual(p.currentLevel, 3); XCTAssertEqual(p.gamesPlayed, 42); XCTAssertEqual(p.water, 7); XCTAssertEqual(p.bestStreak, 9)
        XCTAssertEqual(p.gardenDays, 12); XCTAssertEqual(p.shedPoints, 80); XCTAssertEqual(Set(p.seenIds), ["w1", "w2"])
        XCTAssertEqual(ToolInventory(json: p.toolsJSON).tier(of: .lamp), 1)
        XCTAssertEqual(StickerAlbum(json: p.albumJSON).count(of: "monarch"), 1)
        XCTAssertEqual(BadgeState(json: p.badgesJSON, defs: defs).progress(of: .feeds), 30)
        let rose = plant("rose", in: fresh.mainContext)
        XCTAssertEqual(rose.earnedCount, 3); XCTAssertEqual(rose.growthPoints, 90); XCTAssertEqual(rose.stage, 3)
        XCTAssertEqual(rose.soilRichness, 0.5); XCTAssertEqual(rose.nickname, "Rosie")
        XCTAssertEqual(rose.lastTendedAt, Date(timeIntervalSince1970: 1_000)); XCTAssertEqual(rose.lastLovedAt, Date(timeIntervalSince1970: 2_000))
    }

    func testBackupIsVersionedAndCountsGames() throws {
        growSomething()
        let b = GardenBackup.make(context: ctx, now: .now)
        XCTAssertEqual(b.schemaVersion, 1)
        XCTAssertEqual(b.gamesRecorded, 1)
        XCTAssertEqual(b.plants.count, 50)
    }

    func testRestoreNeverLowersAnythingAndNeverDeletes() throws {
        growSomething()
        let old = try GardenBackup.make(context: ctx, now: .now).encoded()
        // The player kept growing after the backup.
        let p = profile(); p.currentLevel = 4; p.water = 1; p.gamesPlayed = 60; p.bestStreak = 3
        let rose = plant("rose"); rose.growthPoints = 200; rose.stage = 4; rose.earnedCount = 2; rose.nickname = "Queen"
        try ctx.save()
        let plantCount = try ctx.fetchCount(FetchDescriptor<PlantCollectible>())

        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail() }
        XCTAssertEqual(p.currentLevel, 4); XCTAssertEqual(p.gamesPlayed, 60)          // newer progress kept
        XCTAssertEqual(p.water, 7); XCTAssertEqual(p.bestStreak, 9)                  // better backup values brought back
        XCTAssertEqual(rose.growthPoints, 200); XCTAssertEqual(rose.stage, 4); XCTAssertEqual(rose.earnedCount, 3)
        XCTAssertEqual(rose.nickname, "Queen")
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<PlantCollectible>()), plantCount)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<PlayerProfile>()), 1)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<GameRecord>()), 1)
    }

    func testCorruptFileIsRejectedKindlyAndNothingChanges() throws {
        growSomething()
        let result = GardenBackup.restore(Data("not a garden".utf8), into: ctx, badgeDefs: defs)
        guard case .failure(let e) = result else { return XCTFail("should fail") }
        XCTAssertEqual(e, .unreadable)
        XCTAssertTrue(CopySafety.check(e.message).isEmpty)
        XCTAssertEqual(profile().currentLevel, 3); XCTAssertEqual(plant("rose").growthPoints, 90)
    }

    func testUnknownVersionIsRejectedAndNothingChanges() throws {
        growSomething()
        var b = GardenBackup.make(context: ctx, now: .now)
        b.schemaVersion = 2
        b.profile.currentLevel = 9; b.plants = b.plants.map { var s = $0; s.growthPoints = 999; return s }
        let result = GardenBackup.restore(try b.encoded(), into: ctx, badgeDefs: defs)
        guard case .failure(let e) = result else { return XCTFail("should fail") }
        XCTAssertEqual(e, .unknownVersion)
        XCTAssertTrue(CopySafety.check(e.message).isEmpty)
        XCTAssertEqual(profile().currentLevel, 3); XCTAssertEqual(plant("rose").growthPoints, 90)
    }

    func testImplausibleValuesAreRejected() throws {
        var b = GardenBackup.make(context: ctx, now: .now)
        b.plants[0].stage = 42
        guard case .failure(.unreadable) = GardenBackup.restore(try b.encoded(), into: ctx, badgeDefs: defs) else { return XCTFail() }
    }

    func testNoPersonalDataBeyondNickname() throws {
        growSomething()
        let json = String(data: try GardenBackup.make(context: ctx, now: .now).encoded(), encoding: .utf8)!
        XCTAssertTrue(json.contains("Rosie"))
        for banned in ["ageBand", "eighteenPlus", "SECRET", "wordGuessed", "lastAdAt", "adsToday", "createdAt\":\"20"] {
            XCTAssertFalse(json.contains(banned), "backup should not contain \(banned)")
        }
    }

    func testThePotRoundTripsAndOldBackupsReadAsPlainBlue() throws {
        growSomething()
        plant("rose").potId = "sunflower"; try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"potId\" : \"sunflower\""))

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(plant("rose", in: fresh.mainContext).potId, "sunflower")
        XCTAssertEqual(plant("daisy", in: fresh.mainContext).potId, "")

        // A backup saved before pots existed has no potId key; it still reads and changes no pot.
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["plants"] = (json["plants"] as! [[String: Any]]).map { var p = $0; p.removeValue(forKey: "potId"); return p }
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail("old backup should read") }
        XCTAssertEqual(plant("rose").potId, "sunflower")
    }

    func testWhenThePotWasChosenRoundTripsAndOldBackupsStillRead() throws {
        growSomething()
        let rose = plant("rose"); rose.potId = "sunflower"; rose.potChosenAt = Date(timeIntervalSince1970: 3_000); try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"potChosenAt\""))

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        let other = plant("rose", in: fresh.mainContext)
        other.potId = "mint"; other.potChosenAt = Date(timeIntervalSince1970: 2_000); other.lastTendedAt = Date(timeIntervalSince1970: 9_000)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(plant("rose", in: fresh.mainContext).potId, "sunflower", "the later pick wins, not the later tend")
        XCTAssertEqual(plant("rose", in: fresh.mainContext).potChosenAt, Date(timeIntervalSince1970: 3_000))

        // A backup saved before the stamp existed has no potChosenAt key; it still reads and does not undo a stamped pick.
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["plants"] = (json["plants"] as! [[String: Any]]).map { var p = $0; p.removeValue(forKey: "potChosenAt"); p["potId"] = "mint"; return p }
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success(let decoded) = GardenBackup.decode(old) else { return XCTFail("old backup should read") }
        XCTAssertNil(decoded.plants.first { $0.plantId == "rose" }?.potChosenAt)
        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail("old backup should restore") }
        XCTAssertEqual(plant("rose").potId, "sunflower")
    }

    func testWordsTowardTheNextPlantRoundTripAndOldBackupsReadAsZero() throws {
        growSomething()
        profile().wordsTowardPlant = 2; try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"wordsTowardPlant\" : 2"))

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(try fresh.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first?.wordsTowardPlant, 2)

        // A backup saved before words-per-plant existed has no wordsTowardPlant key; it still reads, as 0.
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var prof = json["profile"] as! [String: Any]; prof.removeValue(forKey: "wordsTowardPlant"); json["profile"] = prof
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success(let decoded) = GardenBackup.decode(old) else { return XCTFail("old backup should read") }
        XCTAssertEqual(decoded.profile.wordsTowardPlant ?? 0, 0)
        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail("old backup should restore") }
        XCTAssertEqual(profile().wordsTowardPlant, 2, "restoring never lowers progress")

        var bad = GardenBackup.make(context: ctx, now: .now); bad.profile.wordsTowardPlant = -1
        XCTAssertFalse(bad.isPlausible)
    }

    func testEarnedPotsRoundTripMergeAsAUnionAndOldBackupsReadAsNone() throws {
        growSomething()
        profile().earnedPotIds = ["mint", "terracotta"]; try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"earnedPotIds\""))

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(try fresh.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first?.earnedPotIds, ["mint", "terracotta"])

        // Restoring into a garden that recorded other pots keeps both sets.
        profile().earnedPotIds = ["dewdrop"]; try ctx.save()
        guard case .success = GardenBackup.restore(data, into: ctx, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(profile().earnedPotIds, ["dewdrop", "mint", "terracotta"], "nothing earned is removed")

        // A backup saved before earned pots were recorded has no earnedPotIds key; it still reads, as none.
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var prof = json["profile"] as! [String: Any]; prof.removeValue(forKey: "earnedPotIds"); json["profile"] = prof
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success(let decoded) = GardenBackup.decode(old) else { return XCTFail("old backup should read") }
        XCTAssertNil(decoded.profile.earnedPotIds)
        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail("old backup should restore") }
        XCTAssertEqual(profile().earnedPotIds, ["dewdrop", "mint", "terracotta"], "an older backup never takes a pot away")

        var bad = GardenBackup.make(context: ctx, now: .now); bad.profile.earnedPotIds = [""]
        XCTAssertFalse(bad.isPlausible)
        bad.profile.earnedPotIds = [String(repeating: "x", count: 41)]
        XCTAssertFalse(bad.isPlausible)
    }

    func testFilenameAndCopy() {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
        let d = cal.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 12))!
        XCTAssertEqual(GardenBackup.filename(for: d, calendar: cal), "WordFlora-garden-2026-03-07")
        for line in [GardenBackup.Copy.backupTitle, GardenBackup.Copy.restoreTitle, GardenBackup.Copy.footnote,
                     GardenBackup.Copy.backedUp, GardenBackup.Copy.restored] {
            XCTAssertTrue(CopySafety.check(line).isEmpty, line)
        }
    }

    func testTheLifePanelsLastSeenKeyRoundTripsAndOldBackupsStillRead() throws {
        growSomething()
        let rose = plant("rose"); rose.lifeSeenKey = "|h2|plant"; rose.lifeSeenAt = Date(timeIntervalSince1970: 5_000); try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: .now).encoded()
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"lifeSeenKey\""))

        let fresh = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: fresh.mainContext)
        let other = plant("rose", in: fresh.mainContext)
        other.lifeSeenKey = "|h0|plant"; other.lifeSeenAt = Date(timeIntervalSince1970: 9_000)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(plant("rose", in: fresh.mainContext).lifeSeenKey, "|h0|plant", "a restore never rolls back a later visit")
        XCTAssertEqual(plant("daisy", in: fresh.mainContext).lifeSeenKey, "")

        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        json["plants"] = (json["plants"] as! [[String: Any]]).map { var p = $0; p.removeValue(forKey: "lifeSeenKey"); p.removeValue(forKey: "lifeSeenAt"); return p }
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success(let decoded) = GardenBackup.decode(old) else { return XCTFail("old backup should read") }
        XCTAssertNil(decoded.plants.first { $0.plantId == "rose" }?.lifeSeenKey)
        guard case .success = GardenBackup.restore(old, into: ctx, badgeDefs: defs) else { return XCTFail("old backup should restore") }
        XCTAssertEqual(plant("rose").lifeSeenKey, "|h2|plant", "an older backup changes no visit")
    }
}

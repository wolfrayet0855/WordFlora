import XCTest
import SwiftData
@testable import WordFlora

/// The full Frost & Lantern pack (release plan G5): glasshouse plants outside the ladder, the winter friends for owners
/// only, the scene rules and the kid copy. No new stored fields: everything here reads existing data.
@MainActor
final class FrostLanternTests: XCTestCase {
    private let owned: Set<String> = [PackCatalog.frostLanternId]

    func makeApp(quiet: Bool = false) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-g5-\(UUID().uuidString)")!)
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, storeEnabled: false)
    }

    private func own(_ app: AppModel) { app.entitlements.debugForce(EntitlementState(activeProductIDs: ["pack_frost_lantern"])) }

    // MARK: Facts and copy

    /// The four checked lines (docs/research/frost-lantern-facts-check.md), word for word.
    func testTheFourCheckedFactsAreUsed() {
        XCTAssertEqual(VisitorCatalog.species("robin")?.fact, "Robins sing through the winter, not just in spring.")
        XCTAssertEqual(VisitorCatalog.species("wren")?.fact, "A wren is tiny, but its song is remarkably loud.")
        XCTAssertEqual(GlasshouseCatalog.snowdrop.fact, "Snowdrops often bloom in January and February.")
        XCTAssertEqual(GlasshouseCatalog.hellebore.fact, "Hellebore flowers have petal-like parts called sepals that stay on for weeks.")
        XCTAssertEqual(VisitorCatalog.species("wren")?.name, "Wren", "never the North American species name")
        XCTAssertEqual(GlasshouseCatalog.snowdrop.botanicalName, "Galanthus nivalis")
    }

    func testFactsAreShortAndGentle() {
        let facts = VisitorCatalog.season.compactMap(\.fact) + GlasshouseCatalog.all.map(\.fact)
        XCTAssertEqual(facts.count, 4)
        for fact in facts {
            let words = fact.split(separator: " ")
            XCTAssertLessThanOrEqual(fact.count, 90, fact)
            XCTAssertLessThanOrEqual(words.count, 16, fact)
            XCTAssertEqual(CopySafety.check(fact), [], fact)
            XCTAssertTrue(fact.hasSuffix("."), fact)
            for banned in ["poison", "toxic", "freeze", "pick", "eat", "taste"] {
                XCTAssertFalse(fact.lowercased().contains(banned), "\(fact): \(banned)")
            }
        }
    }

    func testEveryNewLinePassesCopySafety() {
        for line in FrostLanternCopy.all + PackCatalog.Copy.all {
            XCTAssertFalse(line.isEmpty)
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertFalse(line.contains("$"), "no price in kid copy: \(line)")
        }
        XCTAssertEqual(PackCatalog.frostLantern.line, FrostLanternCopy.packLine)
        XCTAssertEqual(FrostLanternCopy.seasonHintNotOwned, PotCatalog.packHint, "the same soft line as the pack pots")
    }

    // MARK: Glasshouse plants stay outside the ladder

    func testGlasshouseIdsNeverMeetTheLadder() throws {
        let ladder = try PlantCatalog.load()
        XCTAssertEqual(ladder.count, 50)
        for g in GlasshouseCatalog.all {
            XCTAssertTrue(GlasshouseCatalog.isGlasshouse(g.id))
            XCTAssertFalse(ladder.contains { $0.plantId == g.id || $0.imageName == g.imageName || $0.name == g.name }, g.id)
        }
        XCTAssertFalse(ladder.contains { GlasshouseCatalog.isGlasshouse($0.plantId) })
        XCTAssertEqual(GlasshouseCatalog.level, 0, "below every ladder level")
    }

    func testRowsArriveOnlyForOwnersAndOnce() throws {
        let app = try makeApp()
        XCTAssertEqual(app.syncGlasshouse(), [], "not owned: nothing")
        XCTAssertEqual(app.allPlantRows().count, 50)
        own(app)
        XCTAssertEqual(Set(app.syncGlasshouse()), Set(GlasshouseCatalog.all.map(\.id)))
        XCTAssertEqual(app.syncGlasshouse(), [], "a second sync adds nothing")
        XCTAssertEqual(app.allPlantRows().count, 52)
        XCTAssertEqual(app.plants().count, 50, "plants() is the ladder only")
        let rows = app.glasshouseRows()
        XCTAssertEqual(rows.map(\.plantId), GlasshouseCatalog.all.map(\.id))
        for r in rows {
            XCTAssertEqual(r.earnedCount, 1); XCTAssertEqual(r.stage, 0); XCTAssertEqual(r.level, 0)
            XCTAssertNotNil(app.plantRow(r.plantId), "the plant page finds it")
        }
        // Lapsed (refund, family sharing off): the rows stay but are not shown.
        app.entitlements.debugForce(EntitlementState())
        XCTAssertEqual(app.glasshouseRows(), [])
        XCTAssertEqual(app.allPlantRows().count, 52, "nothing earned is removed")
    }

    func testGlasshousePlantsNeverMoveLevelCountsBadgesOrPots() throws {
        let app = try makeApp()
        own(app); app.syncGlasshouse()
        for r in app.glasshouseRows() { r.stage = 4; r.growthPoints = 10_000 }
        try app.context.save()
        app.game.refreshLevel()
        XCTAssertEqual(app.profile?.currentLevel, 1, "the word level ignores them")
        XCTAssertEqual(app.unlockStats.plantsEarned, 0, "no plant found on the ladder")
        XCTAssertFalse(app.allPlantsFoundNow)
        XCTAssertTrue(app.badgePlants.isEmpty, "plant badges ignore them")
        let fresh = try makeApp().potStats
        XCTAssertEqual(app.potStats.plantsGrown, fresh.plantsGrown, "pot unlocks ignore them")
        XCTAssertEqual(app.potStats.plantsInLevel, fresh.plantsInLevel)
        XCTAssertFalse(app.plants().contains { GlasshouseCatalog.isGlasshouse($0.plantId) }, "the panorama draws plants() only")
        // A fact card read on the plant page does not count toward the stories badge.
        app.noteFactCardRead(plantId: GlasshouseCatalog.snowdrop.id)
        XCTAssertFalse(app.badges.isMarked(.storiesRead, item: GlasshouseCatalog.snowdrop.id))
    }

    func testGlasshouseThinningEntriesAreComplete() throws {
        let m = try PlantThinningManifest.load()
        let snow = try XCTUnwrap(m.plants["plant_snowdrop"]), hell = try XCTUnwrap(m.plants["plant_hellebore"])
        XCTAssertEqual(snow.kind, .petals); XCTAssertEqual(hell.kind, .petals)
        XCTAssertEqual(snow.rings.map(\.petals.count), [3, 3, 3])
        XCTAssertEqual(hell.rings.map(\.petals.count), [5, 5, 5])
        XCTAssertEqual(snow.heads.map(\.pivot), [[118, 64], [72, 80], [138, 94]])
        XCTAssertEqual(hell.heads.map(\.pivot), [[102, 74], [60, 104], [144, 100]])
        XCTAssertEqual(snow.heads.map(\.rings), [[0], [1], [2]])
        for p in [snow, hell] {
            XCTAssertEqual(p.layers.first?.kind, .ground)
            XCTAssertTrue(p.isNeverEmpty)
            XCTAssertEqual(p.visiblePetals(pips: 0), [])
            XCTAssertEqual(p.visiblePetals(pips: 5).count, p.petalCount)
            for image in p.imageNames { XCTAssertNotNil(UIImage(named: image), image) }
        }
        for g in GlasshouseCatalog.all { XCTAssertNotNil(UIImage(named: g.imageName), g.imageName) }
    }

    // MARK: Winter friends

    func testWinterFriendsComeOnlyToOwners() {
        XCTAssertEqual(VisitorCatalog.seasonPool(ownedPacks: []), [])
        XCTAssertEqual(VisitorCatalog.seasonPool(ownedPacks: owned), ["robin", "wren"])
        for evening in [false, true] {
            for lantern in [false, true] {
                let plain = VisitorSpawner.pool(evening: evening, lantern: lantern)
                XCTAssertFalse(plain.contains { VisitorCatalog.isSeason($0) })
                let withFriends = VisitorSpawner.pool(evening: evening, lantern: lantern, season: ["robin", "wren"])
                XCTAssertTrue(withFriends.contains("robin") && withFriends.contains("wren"))
            }
        }
        // A seeded spawn from a non-owner's pool never brings a winter friend.
        var rng = SplitMix64(seed: 7)
        let pool = VisitorSpawner.pool(evening: false, lantern: false)
        for _ in 0..<2_000 { XCTAssertFalse(VisitorCatalog.isSeason(VisitorSpawner.next(pool: pool, using: &rng) ?? "")) }
        for d in 0..<200 { XCTAssertFalse(VisitorCatalog.isSeason(VisitorSpawner.friendOfTheDay(seed: 3, day: d).id)) }
    }

    func testTheGameAskedByAnOwnerHasTheFriends() throws {
        let app = try makeApp()
        XCTAssertEqual(app.seasonFriendPool, [])
        own(app)
        XCTAssertEqual(app.seasonFriendPool, ["robin", "wren"])
    }

    func testWinterFriendsNeverPassTheTwelve() {
        var album = StickerAlbum()
        album.add(VisitorCatalog.all.map(\.id) + ["robin", "wren", "robin"], on: .now)
        XCTAssertEqual(album.species, 12)
        XCTAssertTrue(album.isComplete)
        XCTAssertEqual(VisitorCatalog.all.count, 12)
        XCTAssertEqual(BadgeFacts.album(album)[.stickers], 12, "the sticker badge counts the twelve")
        XCTAssertFalse(FieldNotes.canCollect("robin", album: album), "the notebook holds the twelve")
        XCTAssertNotNil(VisitorCatalog.species("robin"), "but the game and album can name them")
    }

    func testLanternKeeperGrowsWithAWinterHelloOncePerFriendPerDay() throws {
        let defs = try BadgeCatalog.load()
        var state = BadgeState(defs: defs)
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
        let day1 = cal.date(from: DateComponents(year: 2026, month: 12, day: 3, hour: 12))!
        let day2 = cal.date(byAdding: .day, value: 1, to: day1)!
        XCTAssertEqual(AppModel.recordLanternKeeperHellos(["monarch"], into: &state, on: day1, quiet: false, calendar: cal), [])
        let first = AppModel.recordLanternKeeperHellos(["robin", "robin", "monarch"], into: &state, on: day1, quiet: false, calendar: cal)
        XCTAssertEqual(first.map(\.badgeId), ["lantern_keeper"])
        XCTAssertEqual(AppModel.recordLanternKeeperHellos(["robin"], into: &state, on: day1, quiet: false, calendar: cal), [], "once a day")
        _ = AppModel.recordLanternKeeperHellos(["robin", "wren"], into: &state, on: day2, quiet: false, calendar: cal)
        XCTAssertEqual(state.marks(of: .lanternKeeper, itemPrefix: "hello."), 3)
    }

    func testAlbumShowsWinterFriendsWhileLiveOrOnceMet() {
        var album = StickerAlbum()
        XCTAssertEqual(SeasonFriendsSection.shownFriends(album: album, live: false), [])
        XCTAssertEqual(SeasonFriendsSection.shownFriends(album: album, live: true).map(\.id), ["robin", "wren"])
        album.add(["wren"])
        XCTAssertEqual(SeasonFriendsSection.shownFriends(album: album, live: false).map(\.id), ["wren"], "a met friend stays")
    }

    // MARK: Scene

    func testSceneShowsForOwnersInEveryMode() {
        XCTAssertFalse(FrostLanternScene.shows(ownedPacks: []))
        XCTAssertTrue(FrostLanternScene.shows(ownedPacks: owned))
        XCTAssertTrue(FrostLanternScene.snows(quietGarden: false))
        XCTAssertFalse(FrostLanternScene.snows(quietGarden: true), "no snow in Quiet Garden; the scene itself stays")
        XCTAssertEqual(Snowfall.count(base: FrostLanternScene.snowCount, calm: true), FrostLanternScene.snowCount / 2)
        XCTAssertGreaterThanOrEqual(FrostLanternScene.scrimOpacity, 0.5, "4.55:1 at 50 %, the floor")
    }

    /// Aspect fill, anchored to the bottom, on the iPhone sizes from the SE to the largest Pro Max.
    func testSceneCoversEveryIPhoneAndKeepsTheSnowBank() {
        for size in [CGSize(width: 375, height: 667), CGSize(width: 390, height: 844), CGSize(width: 393, height: 852),
                     CGSize(width: 402, height: 874), CGSize(width: 430, height: 932), CGSize(width: 440, height: 956)] {
            let f = FrostLanternScene.frame(in: size)
            XCTAssertLessThanOrEqual(f.minX, 0.001, "\(size)"); XCTAssertGreaterThanOrEqual(f.maxX, size.width - 0.001, "\(size)")
            XCTAssertLessThanOrEqual(f.minY, 0.001, "\(size)")
            XCTAssertEqual(f.maxY, size.height, accuracy: 0.001, "the bottom (snow bank, fence) is never cropped")
            XCTAssertEqual(f.width / f.height, 393.0 / 852.0, accuracy: 0.0001, "never stretched")
            let line = FrostLanternScene.skyLineY(in: size)
            XCTAssertGreaterThan(line, size.height * 0.4, "the calm sky holds the top of the screen")
            XCTAssertLessThan(line, size.height)
        }
        XCTAssertEqual(FrostLanternScene.frame(in: .zero), .zero)
    }
}

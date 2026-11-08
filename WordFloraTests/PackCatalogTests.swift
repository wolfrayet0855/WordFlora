import XCTest
import SwiftData
@testable import WordFlora

/// The seasonal pack framework and Frost & Lantern (release plan G3): the pack pots, the season's earned pot,
/// Lantern Keeper, the dormant rule (no product, no surfaces) and the kid copy.
@MainActor
final class PackCatalogTests: XCTestCase {
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))! }
    private let pack = PackCatalog.frostLantern

    func makeApp(quiet: Bool = false) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-pack-\(UUID().uuidString)")!)
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, storeEnabled: false)
    }

    // MARK: Catalogue

    func testTheStarterPackHoldsThreePotsWithTheFixedColours() {
        XCTAssertEqual(pack.productID, "pack_frost_lantern")
        XCTAssertEqual(pack.name, "Frost & Lantern")
        XCTAssertEqual(pack.allPotIds, ["frostedGlass", "lanternRed", "snowflakeIndigo"])
        let glass = PotCatalog.frostedGlass, red = PotCatalog.lanternRed, indigo = PotCatalog.snowflakeIndigo
        XCTAssertEqual(glass.rim, 0x548BAC, "the deepened rim (frost-lantern-art.md)")
        XCTAssertEqual(indigo.body, 0x6A70D0); XCTAssertEqual(indigo.shade, 0x4A4FAE); XCTAssertEqual(indigo.rim, 0x7F86D9)
        XCTAssertEqual(red.body, 0xB5403A); XCTAssertEqual(red.rim, 0xD9665A)
        XCTAssertEqual(glass.unlock, .seasonBlooms(5))
        XCTAssertEqual(red.unlock, .pack(pack.id)); XCTAssertEqual(indigo.unlock, .pack(pack.id))
        XCTAssertEqual(Set(PotCatalog.packPots.map(\.decoration.kind)), [.frost, .lanterns, .snowflakes])
        for pot in PotCatalog.packPots { XCTAssertFalse(PotCatalog.marks(for: pot.decoration.kind).isEmpty, pot.id) }
        // The sixteen-pot ladder is untouched; pack pots are looked up on their own.
        XCTAssertEqual(PotCatalog.all.count, 16)
        XCTAssertTrue(PotCatalog.all.allSatisfy { !PotCatalog.isPackPot($0) })
        for pot in PotCatalog.packPots { XCTAssertEqual(PotCatalog.pot(id: pot.id), pot) }
        XCTAssertEqual(Set(PotCatalog.packPots.map(\.id)).count, 3)
        XCTAssertTrue(Set(PotCatalog.packPots.map(\.id)).isDisjoint(with: PotCatalog.all.map(\.id)))
    }

    func testTheProductIsInTheLocalStoreKitFile() throws {
        let url = Bundle(for: Self.self).url(forResource: "WordFlora", withExtension: "storekit")
            ?? Bundle.main.url(forResource: "WordFlora", withExtension: "storekit")
        let data = try Data(contentsOf: try XCTUnwrap(url))
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let products = try XCTUnwrap(json["products"] as? [[String: Any]])
        let p = try XCTUnwrap(products.first { $0["productID"] as? String == "pack_frost_lantern" })
        XCTAssertEqual(p["type"] as? String, "NonConsumable")
        XCTAssertEqual(p["displayPrice"] as? String, "2.99")
        XCTAssertEqual(p["familyShareable"] as? Bool, true)
        XCTAssertEqual(p["referenceName"] as? String, "Frost & Lantern Pack")
        let loc = try XCTUnwrap((p["localizations"] as? [[String: Any]])?.first)
        XCTAssertEqual(loc["displayName"] as? String, "Frost & Lantern")
        XCTAssertEqual(loc["description"] as? String, "Three winter pots and a badge. Pay once, no renewals.")
        XCTAssertEqual(UITestPrices.packs[pack.id], Decimal(string: "2.99"))
    }

    // MARK: Ownership (StoreKit every time, Plus never includes packs)

    func testPackPotsAreOwnedOnlyWithThePack() {
        var s = PotCatalog.Stats()
        for plus in [false, true] {
            XCTAssertEqual(PotCatalog.state(of: PotCatalog.lanternRed, stats: s, hasPlus: plus), .pack(hint: PotCatalog.packHint),
                           "Plus does not include packs")
            XCTAssertFalse(PotCatalog.canChoose(PotCatalog.lanternRed, currentId: "plainBlue", stats: s, hasPlus: plus))
        }
        s.ownedPacks = [pack.id]
        XCTAssertEqual(PotCatalog.state(of: PotCatalog.snowflakeIndigo, stats: s, hasPlus: false), .owned)
        XCTAssertTrue(PotCatalog.canChoose(PotCatalog.snowflakeIndigo, currentId: "plainBlue", stats: s, hasPlus: false))
        XCTAssertEqual(EntitlementState(activeProductIDs: ["pack_frost_lantern"]).ownedPacks, [pack.id])
        XCTAssertFalse(EntitlementState(activeProductIDs: ["pack_frost_lantern"]).hasPlus, "a pack is not Plus")
        XCTAssertEqual(EntitlementState(activeProductIDs: ["plus_lifetime"]).ownedPacks, [])
        // A refunded pack is not owned (revoked transactions never count).
        let refunded = EntitlementState(entries: [.init(productID: "pack_frost_lantern", revoked: true)], now: .now)
        XCTAssertEqual(refunded.ownedPacks, [])
    }

    /// A pack pot already on a plant stays after the pack is no longer owned (refund, family member leaves).
    func testAPackPotStaysOnItsPlantAfterOwnershipLapses() throws {
        let app = try makeApp()
        let plant = app.plants().first!; plant.earnedCount = 1
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["pack_frost_lantern"]))
        XCTAssertTrue(app.choosePot(PotCatalog.lanternRed, for: plant))
        XCTAssertEqual(plant.potId, "lanternRed")
        app.entitlements.debugForce(EntitlementState())                       // lapsed
        XCTAssertEqual(plant.potId, "lanternRed", "nothing takes it off")
        XCTAssertEqual(PotCatalog.pot(id: plant.potId), PotCatalog.lanternRed, "and it still draws")
        XCTAssertTrue(app.canChoose(PotCatalog.lanternRed, for: plant), "the pot in use can always stay")
        XCTAssertFalse(app.canChoose(PotCatalog.snowflakeIndigo, for: plant), "a new pack pot needs the pack")
        XCTAssertEqual(app.visiblePackPots(currentId: plant.potId).map(\.id), ["lanternRed"],
                       "with no product and no pack, only the pot on this plant shows")
    }

    /// Pack pots never count toward the level, plant or pot badges, "level N finished" or the earned-pot record.
    func testPackPotsNeverCountTowardLevelsPlantsOrPotBadges() throws {
        let app = try makeApp()
        for p in app.plants().prefix(3) { p.earnedCount = 1 }
        let before = (app.potStats.plantsGrown, app.potStats.finishedLevels, app.badgePlants.count, BadgeFacts.collection(app.badgePlants))
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["pack_frost_lantern"]))
        for p in app.plants().prefix(3) { _ = app.choosePot(PotCatalog.snowflakeIndigo, for: p) }
        let after = (app.potStats.plantsGrown, app.potStats.finishedLevels, app.badgePlants.count, BadgeFacts.collection(app.badgePlants))
        XCTAssertEqual(before.0, after.0); XCTAssertEqual(before.1, after.1); XCTAssertEqual(before.2, after.2); XCTAssertEqual(before.3, after.3)
        XCTAssertEqual(app.recordEarnedPots().filter { PotCatalog.isPackPot(PotCatalog.pot(id: $0)) }, [])
        var s = app.potStats; s.seasonHalfDays = 100
        XCTAssertTrue(PotCatalog.recordEarned([], stats: s).allSatisfy { !PotCatalog.isPackPot(PotCatalog.pot(id: $0)) },
                      "pack pots, even the earned one, never enter the earned record")
        var rich = PotCatalog.Stats(plantsGrown: 50, finishedLevels: [1, 2, 3, 4, 5], gardenDays: 400)
        rich.seasonHalfDays = 100
        XCTAssertFalse(PotCatalog.earnedByPlay(PotCatalog.lanternRed, rich), "bought pots are never earned by play")
        XCTAssertFalse(PotCatalog.earnedByPlay(PotCatalog.snowflakeIndigo, rich))
        // Levels and plant counts come from the 50 plants only.
        XCTAssertEqual(PotCatalog.stats(plants: [PlantProgress(level: 1, earned: true, stage: 0)]).plantsGrown, 1)
    }

    // MARK: The season's earned pot (Frosted glass)

    func testSeasonFeaturingIsDecemberToFebruary() {
        XCTAssertTrue(PackCatalog.isFeatured(pack, on: date(2026, 12, 1), calendar: cal))
        XCTAssertTrue(PackCatalog.isFeatured(pack, on: date(2027, 1, 15), calendar: cal))
        XCTAssertTrue(PackCatalog.isFeatured(pack, on: date(2027, 2, 28), calendar: cal))
        XCTAssertFalse(PackCatalog.isFeatured(pack, on: date(2027, 3, 1), calendar: cal))
        XCTAssertFalse(PackCatalog.isFeatured(pack, on: date(2026, 11, 30), calendar: cal))
        XCTAssertFalse(PackCatalog.isFeatured(pack, on: date(2026, 7, 4), calendar: cal))
        XCTAssertEqual(PackCatalog.ordered(on: date(2026, 12, 5), calendar: cal).first, pack)
    }

    /// In season: 5 Daily Bloom days. Out of season: each day counts half, so 10.
    func testEarnedPotPaceInAndOutOfSeason() throws {
        func earned(after featured: Int, _ other: Int) -> Bool {
            var s = PotCatalog.Stats(); s.seasonHalfDays = PackCatalog.seasonHalfDays(featuredDays: featured, otherDays: other)
            return PotCatalog.state(of: PotCatalog.frostedGlass, stats: s, hasPlus: false) == .owned
        }
        XCTAssertFalse(earned(after: 4, 0)); XCTAssertTrue(earned(after: 5, 0))
        XCTAssertFalse(earned(after: 0, 9)); XCTAssertTrue(earned(after: 0, 10))
        XCTAssertTrue(earned(after: 3, 4)); XCTAssertFalse(earned(after: 3, 3)); XCTAssertFalse(earned(after: 0, 0))
        var s = PotCatalog.Stats(); s.seasonHalfDays = 5
        XCTAssertEqual(PotCatalog.progress(PotCatalog.frostedGlass, stats: s), .init(now: 2, goal: 5))
        XCTAssertEqual(PotCatalog.progressLine(PotCatalog.frostedGlass, stats: s), "2 of 5 Daily Bloom days")
        XCTAssertEqual(PotCatalog.goalLine(PotCatalog.frostedGlass), "Daily Bloom on 5 days")
        XCTAssertEqual(PotCatalog.state(of: PotCatalog.frostedGlass, stats: s, hasPlus: true), .toEarn(hint: PotCatalog.frostedGlass.hint),
                       "earned by play only, never by Plus")

        // Through the app: marks per day (one per day however many Daily Blooms), pace by the day's season.
        let app = try makeApp()
        app.entitlements.debugPreviewPackPrices(UITestPrices.packs)           // the pack is live
        app.updateBadges(announce: false) { state, quiet, _ in
            var u = [BadgeUnlock]()
            for d in 1...3 { u += app.recordSeasonBloom(into: &state, on: self.date(2026, 12, d), quiet: quiet) }
            u += app.recordSeasonBloom(into: &state, on: self.date(2026, 12, 3), quiet: quiet)       // same day again
            for d in 1...2 { u += app.recordSeasonBloom(into: &state, on: self.date(2027, 4, d), quiet: quiet) }
            return u
        }
        XCTAssertEqual(app.potStats.seasonHalfDays, 2 * 3 + 2)
        XCTAssertEqual(app.potState(PotCatalog.frostedGlass), .toEarn(hint: PotCatalog.frostedGlass.hint))
        app.updateBadges(announce: false) { state, quiet, _ in
            app.recordSeasonBloom(into: &state, on: self.date(2027, 1, 9), quiet: quiet)
        }
        XCTAssertEqual(app.potState(PotCatalog.frostedGlass), .owned)
    }

    func testNoSeasonBloomsWhileThePackIsDormantOrInQuietGarden() throws {
        let dormant = try makeApp()
        dormant.updateBadges(announce: false) { state, quiet, _ in dormant.recordSeasonBloom(into: &state, on: self.date(2026, 12, 2), quiet: quiet) }
        XCTAssertEqual(dormant.potStats.seasonHalfDays, 0)
        let quiet = try makeApp(quiet: true)
        quiet.entitlements.debugPreviewPackPrices(UITestPrices.packs)
        quiet.updateBadges(announce: false) { state, q, _ in quiet.recordSeasonBloom(into: &state, on: self.date(2026, 12, 2), quiet: q) }
        XCTAssertEqual(quiet.potStats.seasonHalfDays, 0)
    }

    // MARK: Dormant framework: no product, no surfaces

    func testNoProductMeansNoSurfaces() throws {
        let app = try makeApp()
        XCTAssertFalse(app.entitlements.packIsLive(pack.id))
        XCTAssertEqual(app.visiblePackPots(), [])
        XCTAssertFalse(app.showsPackBadge("lantern_keeper"), "no Lantern Keeper card on the Badges page")
        XCTAssertTrue(app.showsPackBadge("first_bloom"), "other badges are untouched")
        for band: AgeBand? in [.eighteenPlus, .thirteenPlus, .under13, nil] {
            XCTAssertFalse(ShedSeasonsShelf.isShown(ageBand: band, quietGarden: false, live: false))
        }
        XCTAssertFalse(PackCatalog.isLive(pack, offered: false, owned: false))
        // Offered: the pots show as outlines; owned with no product (store gone): still shows.
        app.entitlements.debugPreviewPackPrices(UITestPrices.packs)
        XCTAssertEqual(app.visiblePackPots().map(\.id), pack.allPotIds)
        XCTAssertTrue(app.showsPackBadge("lantern_keeper"))
        XCTAssertTrue(PackCatalog.isLive(pack, offered: false, owned: true))
    }

    /// The Shed's Seasons shelf (with a price) is for 13 and up only, never Quiet Garden.
    func testTheShedShelfIsForThirteenAndUp() {
        XCTAssertTrue(ShedSeasonsShelf.isShown(ageBand: .eighteenPlus, quietGarden: false, live: true))
        XCTAssertTrue(ShedSeasonsShelf.isShown(ageBand: .thirteenPlus, quietGarden: false, live: true))
        XCTAssertFalse(ShedSeasonsShelf.isShown(ageBand: .under13, quietGarden: false, live: true))
        XCTAssertFalse(ShedSeasonsShelf.isShown(ageBand: nil, quietGarden: false, live: true))
        XCTAssertFalse(ShedSeasonsShelf.isShown(ageBand: .eighteenPlus, quietGarden: true, live: true))
    }

    // MARK: Lantern Keeper (earned by play only)

    func testLanternKeeperCountsGrowthInTheFrostedGlassPot() throws {
        let app = try makeApp()
        let defs = try BadgeCatalog.load()
        let def = try XCTUnwrap(defs.first { $0.id == "lantern_keeper" })
        XCTAssertEqual(def.counter, "lanternKeeper"); XCTAssertEqual(def.thresholds, [1, 4, 8])
        XCTAssertEqual(def.blurb, "Grow plants in the Frosted glass pot")
        var state = BadgeState(defs: defs)
        let plant = app.plants().first!; plant.earnedCount = 1
        plant.potId = "lanternRed"; plant.stage = 1
        XCTAssertEqual(AppModel.recordLanternKeeperGrowth(plant, into: &state, on: .now, quiet: false), [], "another pot: nothing")
        plant.potId = "frostedGlass"
        let first = AppModel.recordLanternKeeperGrowth(plant, into: &state, on: .now, quiet: false)
        XCTAssertEqual(first.map(\.badgeId), ["lantern_keeper"]); XCTAssertEqual(first.first?.tier, 1)
        XCTAssertEqual(AppModel.recordLanternKeeperGrowth(plant, into: &state, on: .now, quiet: false), [], "the same stage counts once")
        for stage in 2...4 { plant.stage = stage; AppModel.recordLanternKeeperGrowth(plant, into: &state, on: .now, quiet: false) }
        XCTAssertEqual(state.progress(of: .lanternKeeper), 4); XCTAssertEqual(state.tier(of: "lantern_keeper"), 2)
        var quiet = BadgeState(defs: defs)
        XCTAssertEqual(AppModel.recordLanternKeeperGrowth(plant, into: &quiet, on: .now, quiet: true), [])
        XCTAssertEqual(quiet.progress(of: .lanternKeeper), 0, "Quiet Garden counts nothing")
        // Marks merge by union, like every mark.
        var other = BadgeState(defs: defs); plant.stage = 1
        AppModel.recordLanternKeeperGrowth(plant, into: &other, on: .now, quiet: false)
        XCTAssertEqual(state.merged(with: other).marks(of: .lanternKeeper), 4)
    }

    // MARK: Copy

    func testKidCopyIsCalmAndHasNoPriceOrLock() {
        for line in PackCatalog.Copy.all + PotCatalog.Copy.all + PotCatalog.packPots.map(\.hint)
            + PotCatalog.packPots.map(PotCatalog.packLine) + PotCatalog.packPots.map(\.a11y) {
            XCTAssertEqual(CopySafety.check(line), [], line)
        }
        XCTAssertEqual(PotCatalog.packHint, "A grown-up can find this in Settings.")
        // Words a child sees on pots: no price, lock, buy or countdown words.
        let kidLines = PotCatalog.packPots.map(\.hint) + PotCatalog.packPots.map(PotCatalog.packLine)
            + PotCatalog.packPots.map { PotCatalog.tileLabel($0, state: .pack(hint: $0.hint), inUse: false) }
            + [PotCatalog.Copy.hintPack, PackCatalog.Copy.seasonsTitle]
        for line in kidLines {
            for word in ["$", "price", "buy", "lock", "today", "hurry", "left", "sale"] {
                XCTAssertFalse(line.lowercased().contains(word), "\(word) in \(line)")
            }
        }
        XCTAssertEqual(PotCatalog.packLine(PotCatalog.lanternRed), "Lantern red is part of Frost & Lantern.")
        XCTAssertEqual(PotCatalog.hintLines(PotCatalog.lanternRed, state: .pack(hint: PotCatalog.packHint), stats: .init()).detail,
                       "A grown-up can find this in Settings.")
    }
}

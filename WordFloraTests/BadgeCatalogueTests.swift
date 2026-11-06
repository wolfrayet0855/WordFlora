import XCTest
import SwiftData
@testable import WordFlora

/// The full badge catalogue (36 designed badges plus Weathered): their rules, counters, merge, sharing and moments.
@MainActor
final class BadgeCatalogueTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    // MARK: Catalogue

    /// design-preview/brand/v4/badges.html: 36 emblems, with the Round 5 thresholds, plus the Weathered badge.
    static let designed: [String: (counter: String, thresholds: [Int])] = [
        "rare_finds": ("rarePlants", [1, 3, 6]), "desert_dweller": ("desertPlants", [2, 4, 6]),
        "water_lover": ("waterPlants", [1, 2, 3]), "tree_hugger": ("treePlants", [2, 4, 6]),
        "flower_power": ("floweringPlants", [5, 15, 30]), "sticker_book": ("stickers", [10, 30, 60]),
        "word_whiz": ("wordsSolved", [10, 100, 500]), "steady_hands": ("steadySolves", [5, 25, 100]),
        "level_up": ("levelReached", [2, 4, 5]), "long_word": ("longWords", [3, 15, 50]),
        "morning_garden": ("morningDays", [3, 15, 50]), "first_bloom": ("fullBlooms", [1, 5, 20]),
        "mist_maker": ("mists", [10, 40, 100]), "sun_seeker": ("suns", [10, 40, 100]),
        "soil_scientist": ("soilMatches", [3, 10, 30]), "steady_gardener": ("tendDays", [7, 30, 100]),
        "first_butterfly": ("catches", [1, 10, 50]), "dusk_visitor": ("duskCatches", [1, 3, 5]),
        "rare_visitor": ("rareSpecies", [1, 2, 3]), "wild_discovery": ("storiesRead", [1, 5, 15]),
        "field_notes": ("factsRead", [4, 8, 12]), "bee_friend": ("beeCatches", [5, 20, 60]),
        "shed_keeper": ("shedUpgrades", [3, 6, 12]), "sharer": ("badgeShares", [1, 5, 20]),
    ]
    static let builtBefore = ["level_sets", "plant_collector", "feeder", "green_thumb", "master_repotter", "pruning_pro", "streak",
                              "perfect_bloom", "resurrected", "daily_bloom", "visitor_friend", "gentle_net", "weathered"]

    func testTheCatalogueHoldsAllThirtySixDesignedBadgesAndWeathered() throws {
        let defs = try BadgeCatalog.load()
        XCTAssertEqual(defs.count, 37)
        XCTAssertEqual(Set(defs.map(\.id)), Set(Self.designed.keys).union(Self.builtBefore))
        for (id, want) in Self.designed {
            let d = try XCTUnwrap(defs.first { $0.id == id }, id)
            XCTAssertEqual(d.counter, want.counter, id); XCTAssertEqual(d.thresholds, want.thresholds, id)
            XCTAssertTrue(["collection", "play", "tending", "explorer"].contains(d.family), id)
        }
        // One counter per badge, and every counter is used by a badge.
        XCTAssertEqual(Set(defs.map(\.counter)).count, defs.count)
        XCTAssertEqual(Set(defs.map(\.counter)), BadgeCatalog.knownCounters)
    }

    /// Gold is always reachable with what the game holds.
    func testEveryGoldCanBeReached() throws {
        let defs = try BadgeCatalog.load()
        let all = try PlantCatalog.load().map { BadgeFacts.Plant(level: $0.level, stage: 4, traits: $0.traitSet) }
        var reachable = BadgeFacts.collection(all)
        var album = StickerAlbum(); album.add(VisitorCatalog.all.map(\.id))
        reachable.merge(BadgeFacts.album(album)) { a, _ in a }
        reachable[.levelReached] = 5
        reachable[.factsRead] = VisitorCatalog.all.filter { $0.fact != nil }.count
        reachable[.shedUpgrades] = BadgeFacts.shedUpgrades(Self.maxedInventory())
        reachable[.storiesRead] = all.count
        reachable[.soilMatches] = all.count
        reachable[.stickers] = nil          // stickers repeat, so any number can be reached
        for (counter, most) in reachable {
            let d = try XCTUnwrap(defs.first { $0.counter == counter.rawValue }, counter.rawValue)
            XCTAssertLessThanOrEqual(d.thresholds[2], most, d.id)
        }
        XCTAssertEqual(reachable[.rarePlants], 20); XCTAssertEqual(reachable[.desertPlants], 7)
        XCTAssertEqual(reachable[.waterPlants], 6); XCTAssertEqual(reachable[.treePlants], 9)
        XCTAssertEqual(reachable[.shedUpgrades], 12); XCTAssertEqual(reachable[.rareSpecies], 3)
    }

    static func maxedInventory() -> ToolInventory {
        var inv = ToolInventory(); ToolID.allCases.forEach { inv.unlock($0) }
        var points = 10_000
        for tool in ToolID.allCases { _ = inv.upgrade(tool, shedPoints: &points); _ = inv.upgrade(tool, shedPoints: &points) }
        return inv
    }

    func testAllBadgeWordsAreKind() throws {
        let defs = try BadgeCatalog.load()
        var lines = defs.flatMap { [$0.title ?? "", $0.blurb ?? ""] }
        lines += [BadgeShare.button, BadgeShare.header, BadgeShare.tagline, BadgeDetailCopy.done, BadgeDetailCopy.openHint, BadgeDetailCopy.goldLine]
        for d in defs {
            for tier in 1...3 {
                lines += [BadgeShare.caption(title: d.title ?? "", tier: tier), BadgeDetailCopy.next(tier: tier, thresholds: d.thresholds) ?? ""]
            }
        }
        for line in lines { XCTAssertEqual(CopySafety.check(line), [], line) }
        // Nothing reads as shut away: no "locked" anywhere.
        for line in lines { XCTAssertFalse(line.lowercased().contains("lock"), line) }
    }

    func testTheNextLineNamesTheNextTier() {
        XCTAssertEqual(BadgeDetailCopy.next(tier: 1, thresholds: [25, 75, 150]), "Next: Silver at 75")
        XCTAssertEqual(BadgeDetailCopy.next(tier: 2, thresholds: [25, 75, 150]), "Next: Gold at 150")
        XCTAssertEqual(BadgeDetailCopy.next(tier: 3, thresholds: [25, 75, 150]), BadgeDetailCopy.goldLine)
    }

    // MARK: Days and marks

    func testADayCountsOnceAndANewDayCountsAgain() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        XCTAssertEqual(s.recordDay(.morningDays, day: 10, now: t0), [])
        s.recordDay(.morningDays, day: 10, now: t0)
        XCTAssertEqual(s.progress(of: .morningDays), 1)
        s.recordDay(.morningDays, day: 9, now: t0)                 // a clock set back never counts twice
        XCTAssertEqual(s.progress(of: .morningDays), 1)
        s.recordDay(.morningDays, day: 11, now: t0)
        let unlocks = s.recordDay(.morningDays, day: 13, now: t0)
        XCTAssertEqual(s.progress(of: .morningDays), 3)
        XCTAssertEqual(unlocks.map(\.badgeId), ["morning_garden"])
    }

    func testQuietGardenCountsNoDaysAndNoMarks() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        XCTAssertEqual(s.recordDay(.tendDays, day: 3, now: t0, quiet: true), [])
        XCTAssertEqual(s.recordMark(.storiesRead, item: "rose", now: t0, quiet: true), [])
        XCTAssertEqual(s.progress(of: .tendDays), 0); XCTAssertEqual(s.progress(of: .storiesRead), 0)
        XCTAssertFalse(s.isMarked(.storiesRead, item: "rose"))
        // A day missed in Quiet Garden still counts once it is played outside it.
        XCTAssertEqual(s.recordDay(.tendDays, day: 3, now: t0), [])
        XCTAssertEqual(s.progress(of: .tendDays), 1)
    }

    func testAMarkCountsOnceEach() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        XCTAssertEqual(s.recordMark(.storiesRead, item: "rose", now: t0).map(\.badgeId), ["wild_discovery"])
        XCTAssertEqual(s.recordMark(.storiesRead, item: "rose", now: t0), [])
        s.recordMark(.storiesRead, item: "daisy", now: t0)
        XCTAssertEqual(s.progress(of: .storiesRead), 2)
        XCTAssertTrue(s.isMarked(.storiesRead, item: "daisy")); XCTAssertFalse(s.isMarked(.badgeShares, item: "daisy"))
    }

    /// Days and marks ride inside the max merge: marks join up, the later day is kept, nothing goes down.
    func testDaysAndMarksSurviveTheMergeAndJSON() throws {
        let defs = try BadgeCatalog.load()
        var a = BadgeState(defs: defs), b = BadgeState(defs: defs)
        a.recordMark(.storiesRead, item: "rose", now: t0); a.recordDay(.tendDays, day: 5, now: t0)
        b.recordMark(.storiesRead, item: "daisy", now: t0); b.recordDay(.tendDays, day: 7, now: t0)
        var m = BadgeState(json: a.json, defs: defs).merged(with: BadgeState(json: b.json, defs: defs))
        XCTAssertTrue(m.isMarked(.storiesRead, item: "rose")); XCTAssertTrue(m.isMarked(.storiesRead, item: "daisy"))
        XCTAssertEqual(m.marks(of: .storiesRead), 2)
        m.recordMark(.storiesRead, item: "fern", now: t0)
        XCTAssertEqual(m.progress(of: .storiesRead), 3, "the next mark counts the joined set")
        m.recordDay(.tendDays, day: 7, now: t0)
        XCTAssertEqual(m.progress(of: .tendDays), 1, "day 7 was already counted on the other device")
    }

    /// The profile merge (iCloud duplicates) and a garden backup both carry the new counts.
    func testReconcilerAndBackupCarryTheNewCounts() throws {
        let defs = try BadgeCatalog.load()
        var a = BadgeState(defs: defs); a.recordMark(.badgeShares, item: "feeder#1", now: t0); a.record(.suns, amount: 12, now: t0)
        var b = BadgeState(defs: defs); b.recordMark(.badgeShares, item: "streak#2", now: t0); b.record(.suns, amount: 3, now: t0)
        let keep = PlayerProfile(); keep.badgesJSON = a.json
        let other = PlayerProfile(); other.badgesJSON = b.json
        DataReconciler.merge(other, into: keep, defs: defs)
        let merged = BadgeState(json: keep.badgesJSON, defs: defs)
        XCTAssertEqual(merged.progress(of: .suns), 12)
        XCTAssertEqual(merged.marks(of: .badgeShares), 2)
        XCTAssertEqual(merged.tier(of: "sun_seeker"), 1)

        let container = try SharedContainer.make(inMemory: true)
        let ctx = container.mainContext
        ctx.insert(keep); try ctx.save()
        let data = try GardenBackup.make(context: ctx, now: t0).encoded()
        let fresh = try SharedContainer.make(inMemory: true)
        guard case .success = GardenBackup.restore(data, into: fresh.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        let restored = try XCTUnwrap(try fresh.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first)
        XCTAssertEqual(BadgeState(json: restored.badgesJSON, defs: defs).marks(of: .badgeShares), 2)
    }

    /// Badge JSON from before this release still reads, and its counts are kept.
    func testOldBadgeJSONStillReads() throws {
        let s = BadgeState(json: #"{"progress":{"waterings":30},"unlocked":{}}"#, defs: try BadgeCatalog.load())
        XCTAssertEqual(s.progress(of: .waterings), 30); XCTAssertEqual(s.marks(of: .storiesRead), 0)
    }

    // MARK: Facts

    func testCollectionCountsByKind() {
        let found = [BadgeFacts.Plant(level: 2, stage: 4, traits: ["desert", "cactus", "succulent"]),
                     BadgeFacts.Plant(level: 4, stage: 3, traits: ["aquatic", "bigLeaf"]),
                     BadgeFacts.Plant(level: 5, stage: 1, traits: ["hardyTree", "evergreen", "tree"]),
                     BadgeFacts.Plant(level: 3, stage: 2, traits: ["carnivorous", "bog"]),
                     BadgeFacts.Plant(level: 4, stage: 0, traits: ["hardyTree", "evergreen"])]       // a palm, not a tree
        let c = BadgeFacts.collection(found)
        XCTAssertEqual(c[.rarePlants], 3); XCTAssertEqual(c[.desertPlants], 1); XCTAssertEqual(c[.waterPlants], 2)
        XCTAssertEqual(c[.treePlants], 1); XCTAssertEqual(c[.floweringPlants], 2); XCTAssertEqual(c[.fullBlooms], 1)
    }

    func testAlbumAndCatches() {
        var album = StickerAlbum()
        album.add(["monarch", "monarch", "luna", "morpho", "weather.1"])
        let a = BadgeFacts.album(album)
        XCTAssertEqual(a[.stickers], 4, "weather stickers are not visitors"); XCTAssertEqual(a[.rareSpecies], 2)
        let c = BadgeFacts.catches(["honeybee", "bumblebee", "firefly", "luna", "monarch"])
        XCTAssertEqual(c[.catches], 5); XCTAssertEqual(c[.duskCatches], 2); XCTAssertEqual(c[.beeCatches], 2)
    }

    func testWordsMorningsAndTheShed() {
        XCTAssertTrue(BadgeFacts.isLongWord("SUNFLOWER")); XCTAssertFalse(BadgeFacts.isLongWord("MARIGOLD"))
        XCTAssertTrue(BadgeFacts.isLongWord("ALOE VERA X"), "letters, not spaces"); XCTAssertFalse(BadgeFacts.isLongWord("ALOE VERA"))
        XCTAssertTrue(BadgeFacts.isSteady(misses: 0)); XCTAssertTrue(BadgeFacts.isSteady(misses: 2)); XCTAssertFalse(BadgeFacts.isSteady(misses: 3))
        func at(_ h: Int, _ m: Int = 0) -> Date { utc.date(bySettingHour: h, minute: m, second: 0, of: t0)! }
        XCTAssertFalse(BadgeFacts.isMorning(at(4, 59), calendar: utc)); XCTAssertTrue(BadgeFacts.isMorning(at(5), calendar: utc))
        XCTAssertTrue(BadgeFacts.isMorning(at(11, 59), calendar: utc)); XCTAssertFalse(BadgeFacts.isMorning(at(12), calendar: utc))
        XCTAssertEqual(BadgeFacts.dayNumber(at(0, 1), calendar: utc), BadgeFacts.dayNumber(at(23, 59), calendar: utc))
        XCTAssertEqual(BadgeFacts.dayNumber(utc.date(byAdding: .day, value: 1, to: at(8))!, calendar: utc), BadgeFacts.dayNumber(at(8), calendar: utc) + 1)
        var inv = ToolInventory(); XCTAssertEqual(BadgeFacts.shedUpgrades(inv), 0)
        var points = 30; inv.unlock(.lamp); _ = inv.upgrade(.can, shedPoints: &points)
        XCTAssertEqual(BadgeFacts.shedUpgrades(inv), 1)
    }

    /// The local day follows the player's own midnight: 23:30 and 00:30 in Sydney are two days.
    func testTheDayFollowsTheLocalMidnight() {
        var syd = Calendar(identifier: .gregorian); syd.timeZone = TimeZone(identifier: "Australia/Sydney")!
        let late = syd.date(from: DateComponents(year: 2026, month: 4, day: 4, hour: 23, minute: 30))!     // DST ends that night
        let next = syd.date(from: DateComponents(year: 2026, month: 4, day: 5, hour: 0, minute: 30))!
        XCTAssertEqual(BadgeFacts.dayNumber(next, calendar: syd), BadgeFacts.dayNumber(late, calendar: syd) + 1)
    }

    // MARK: Through the app

    var clock = Date(timeIntervalSince1970: 1_780_000_000)

    func makeApp(quiet: Bool = false, calm: Bool = false, age: AgeBand? = .eighteenPlus, hour: Int = 9) throws -> AppModel {
        clock = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-badges-\(UUID().uuidString)")!)
        settings.quietGarden = quiet; settings.calmMode = calm; settings.ageBand = age
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: { [unowned self] in self.clock },
                        notifications: ReminderTests.FakeCenter())
    }

    private func entry(_ word: String) -> WordEntry {
        WordEntry(id: "x-\(word)", word: word, display: word.capitalized, hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                  tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
    }

    private func win(_ app: AppModel, _ word: String, wrong: String = "") {
        app.game.start(entry: entry(word))
        for ch in wrong + word { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.roundFinished()
    }

    func testAWonRoundCountsTheWordSteadyHandsLongWordsAndTheMorning() throws {
        let app = try makeApp(hour: 9)
        win(app, "SUNFLOWER", wrong: "ZQ")
        XCTAssertEqual(app.badges.progress(of: .wordsSolved), 1)
        XCTAssertEqual(app.badges.progress(of: .steadySolves), 1)
        XCTAssertEqual(app.badges.progress(of: .longWords), 1)
        XCTAssertEqual(app.badges.progress(of: .morningDays), 1)
        XCTAssertEqual(app.badges.progress(of: .levelReached), 1)
        win(app, "ROSE", wrong: "ZQJ")
        XCTAssertEqual(app.badges.progress(of: .wordsSolved), 2)
        XCTAssertEqual(app.badges.progress(of: .steadySolves), 1, "three wrong letters is not steady")
        XCTAssertEqual(app.badges.progress(of: .longWords), 1)
        XCTAssertEqual(app.badges.progress(of: .morningDays), 1, "one morning a day")
    }

    func testAnAfternoonRoundIsNotAMorning() throws {
        let app = try makeApp(hour: 15)
        win(app, "ROSE")
        XCTAssertEqual(app.badges.progress(of: .morningDays), 0)
    }

    func testTendingCountsSunSoilMatchesAndDays() throws {
        let app = try makeApp()
        let plant = try XCTUnwrap(app.plants().first); plant.earnedCount = 1
        app.profile?.water = 5; app.profile?.soil = 5
        XCTAssertTrue(app.tend(.sun, plant: plant).applied)
        XCTAssertEqual(app.badges.progress(of: .suns), 1)
        XCTAssertEqual(app.badges.progress(of: .tendDays), 1)
        let good = SoilType.preferred(forPlantId: plant.plantId)
        XCTAssertTrue(app.tend(.repot(good), plant: plant).applied)
        XCTAssertTrue(app.tend(.repot(good), plant: plant).applied)
        XCTAssertEqual(app.badges.progress(of: .soilMatches), 1, "each plant counts once")
        XCTAssertEqual(app.badges.progress(of: .tendDays), 1, "one day")
        clock = clock.addingTimeInterval(86_400)
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(app.badges.progress(of: .tendDays), 2)
    }

    func testAButterflyGameCountsCatchesEveningFriendsBeesAndTheAlbum() throws {
        let app = try makeApp()
        var g = app.startButterflyGame(seed: 5)
        g.visitors = ["honeybee", "luna", "morpho"].enumerated().map { i, id in
            ButterflyGameModel.Visitor(id: 90 + i, speciesId: id, x: 0.2 + Double(i) * 0.3, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)
        }
        for i in 0..<3 { g.catchAt(x: 0.2 + Double(i) * 0.3, y: 0.5) }
        app.finishButterflyGame(g)
        XCTAssertEqual(app.badges.progress(of: .catches), 3)
        XCTAssertEqual(app.badges.progress(of: .duskCatches), 1)
        XCTAssertEqual(app.badges.progress(of: .beeCatches), 1)
        XCTAssertEqual(app.badges.progress(of: .rareSpecies), 2)
        XCTAssertEqual(app.badges.progress(of: .stickers), 3)
        XCTAssertTrue(app.pendingBadges.contains { $0.badgeId == "first_butterfly" })
        XCTAssertTrue(app.pendingBadges.contains { $0.badgeId == "dusk_visitor" })
        XCTAssertTrue(app.pendingBadges.contains { $0.badgeId == "rare_visitor" && $0.tier == 2 })
    }

    func testShedUpgradesAndMisterDrops() throws {
        let app = try makeApp()
        app.profile?.shedPoints = 200
        XCTAssertTrue(app.upgradeTool(.can))
        XCTAssertEqual(app.badges.progress(of: .shedUpgrades), 1)
        // Free drops count for Mist Maker once the mister is in the Shed.
        var inv = app.inventory; inv.unlock(.mister); app.inventory = inv
        app.profile?.water = 0; app.profile?.lastTrickleAt = clock
        clock = clock.addingTimeInterval(3 * 86_400)
        app.refreshFreeDrops()
        let drops = app.profile?.water ?? 0
        XCTAssertGreaterThan(drops, 0)
        XCTAssertEqual(app.badges.progress(of: .mists), drops)
    }

    func testReadingCountsFactCardsAndVisitorFacts() throws {
        let app = try makeApp()
        app.noteFactCardRead(plantId: "rose"); app.noteFactCardRead(plantId: "rose")
        XCTAssertEqual(app.badges.progress(of: .storiesRead), 1)
        XCTAssertEqual(app.pendingBadge?.badgeId, "wild_discovery")
        var album = StickerAlbum(); album.add(["monarch", "ladybug", "honeybee", "luna"]); app.profile?.albumJSON = album.json
        app.noteVisitorFactsRead()
        XCTAssertEqual(app.badges.progress(of: .factsRead), 4)
        XCTAssertEqual(app.badges.tier(of: "field_notes"), 1)
    }

    /// Badges added in an update arrive at launch for what is already done, without a pile of moments.
    func testTheCatchUpIsQuietButCounts() throws {
        let app = try makeApp()
        for p in app.plants() { p.earnedCount = 1; p.stage = 4 }
        app.profile?.currentLevel = 5
        try app.context.save()
        app.refreshBadgeFacts()
        XCTAssertEqual(app.badges.tier(of: "rare_finds"), 3)
        XCTAssertEqual(app.badges.tier(of: "first_bloom"), 3)
        XCTAssertEqual(app.badges.tier(of: "level_up"), 3)
        XCTAssertTrue(app.pendingBadges.isEmpty)
    }

    func testQuietGardenNeverUnlocksAnyOfTheNewBadges() throws {
        let app = try makeApp(quiet: true)
        for p in app.plants() { p.earnedCount = 1; p.stage = 4 }
        app.refreshBadgeFacts()
        win(app, "SUNFLOWER")
        let plant = try XCTUnwrap(app.plants().first)
        _ = app.tend(.sun, plant: plant)
        app.noteFactCardRead(plantId: "rose")
        XCTAssertTrue(app.badges.unlocked.isEmpty)
        XCTAssertTrue(app.pendingBadges.isEmpty)
        for c in BadgeCounter.allCases { XCTAssertEqual(app.badges.progress(of: c), 0, c.rawValue) }
    }

    // MARK: Sharing

    func testSharingIsForThirteenAndUpOnly() throws {
        XCTAssertFalse(BadgeShare.isAllowed(ageBand: nil)); XCTAssertFalse(BadgeShare.isAllowed(ageBand: .under13))
        XCTAssertTrue(BadgeShare.isAllowed(ageBand: .thirteenPlus)); XCTAssertTrue(BadgeShare.isAllowed(ageBand: .eighteenPlus))
        let young = try makeApp(age: .under13)
        XCTAssertFalse(young.canShareBadges)
        young.noteBadgeShared("feeder", tier: 1)
        XCTAssertEqual(young.badges.progress(of: .badgeShares), 0)
        let unknown = try makeApp(age: nil)
        XCTAssertFalse(unknown.canShareBadges)
    }

    func testEachSharedBadgeCardCountsOnce() throws {
        let app = try makeApp()
        app.noteBadgeShared("feeder", tier: 1); app.noteBadgeShared("feeder", tier: 1)
        XCTAssertEqual(app.badges.progress(of: .badgeShares), 1)
        XCTAssertEqual(app.pendingBadge?.badgeId, "sharer")
        app.noteBadgeShared("feeder", tier: 2)
        XCTAssertEqual(app.badges.progress(of: .badgeShares), 2)
    }

    /// The caption is plain: the badge, the tier and the app. Nothing about the player.
    func testTheCaptionCarriesNoPersonalData() {
        XCTAssertEqual(BadgeShare.caption(title: "Plant Collector", tier: 3), "I earned the Gold Plant Collector badge in WordFlora!")
    }

    func testTheShareCardRendersForEveryBadge() throws {
        for d in try BadgeCatalog.load() {
            XCTAssertNotNil(BadgeShareCard(def: d, tier: 3).rendered(), d.id)
        }
    }

    // MARK: Moments

    /// Calm mode halves the badge celebration: the still arc, with at most half the petals of the full moment.
    func testCalmHalvesTheBadgeCelebration() throws {
        let calm = try makeApp(calm: true)
        let level = calm.celebrationLevel(.badge, systemReduceMotion: false)
        XCTAssertLessThanOrEqual(level.particleCount * 2, CelebrationLevel.badge.particleCount)
        XCTAssertLessThanOrEqual(level.duration * 2, CelebrationLevel.badge.duration + 0.2)
        XCTAssertGreaterThan(level.particleCount, 0, "gentle, never nothing")
        let full = try makeApp()
        XCTAssertEqual(full.celebrationLevel(.badge, systemReduceMotion: false), .badge)
    }
}

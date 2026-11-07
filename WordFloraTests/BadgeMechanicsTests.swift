import XCTest
import SwiftData
@testable import WordFlora

/// Field Notes and Pruning Pro (gate G1, docs/pm/badge-mechanics-art.md sections 1 and 3): the pure rules, the app's
/// recording, their copy and the catalogue entries. Also the SKAdNetwork list in Info.plist (B2a).
@MainActor
final class BadgeMechanicsTests: XCTestCase {
    var clock = Date(timeIntervalSince1970: 1_780_000_000)

    func makeApp(quiet: Bool = false) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-mech-\(UUID().uuidString)")!)
        settings.quietGarden = quiet; settings.ageBand = .eighteenPlus
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        return AppModel(container: container, settings: settings, bank: bank, now: { [unowned self] in self.clock },
                        notifications: ReminderTests.FakeCenter())
    }

    private func meet(_ app: AppModel, _ ids: [String]) {
        var album = StickerAlbum(); album.add(ids, on: clock); app.profile?.albumJSON = album.json
    }

    // MARK: Field Notes: pure rules

    func testOnlyMetCatalogueFriendsCanBeCollected() {
        var album = StickerAlbum(); album.add(["monarch", WeatherSticker.ladybird.id, "dragon"])
        XCTAssertTrue(FieldNotes.canCollect("monarch", album: album))
        XCTAssertFalse(FieldNotes.canCollect("ladybug", album: album), "not met yet")
        XCTAssertFalse(FieldNotes.canCollect(WeatherSticker.ladybird.id, album: album), "weather stickers never count")
        XCTAssertFalse(FieldNotes.canCollect("dragon", album: album), "a made-up id is ignored")
        XCTAssertFalse(FieldNotes.canCollect("", album: album))
    }

    func testAFinishCountsOnceAndOnlyForThePageStillBeingRead() {
        var l = FieldNotes.Listening()
        let t1 = l.start("monarch")
        XCTAssertTrue(l.isReading)
        XCTAssertEqual(l.finish(token: t1), "monarch")
        XCTAssertNil(l.finish(token: t1), "a second finish adds nothing")

        let t2 = l.start("ladybug"); l.cancel()
        XCTAssertNil(l.finish(token: t2), "a stopped reading is not read to the end")

        let t3 = l.start("monarch")
        let t4 = l.start("honeybee")                    // Listen on another page: the first one is stale
        XCTAssertNil(l.finish(token: t3))
        XCTAssertEqual(l.finish(token: t4), "honeybee")
    }

    func testQuietGardenHidesIReadItAndTheCountAndVoiceOverHidesListen() {
        XCTAssertEqual(FieldNotes.readItButton(stamped: false, quiet: false), .readIt)
        XCTAssertEqual(FieldNotes.readItButton(stamped: true, quiet: false), .stamped)
        XCTAssertEqual(FieldNotes.readItButton(stamped: false, quiet: true), .hidden)
        XCTAssertEqual(FieldNotes.readItButton(stamped: true, quiet: true), .hidden)
        XCTAssertFalse(FieldNotes.showsPageCount(quiet: true)); XCTAssertTrue(FieldNotes.showsPageCount(quiet: false))
        XCTAssertFalse(FieldNotes.showsListen(voiceOverRunning: true)); XCTAssertTrue(FieldNotes.showsListen(voiceOverRunning: false))
    }

    // MARK: Field Notes: recording

    func testOpeningTheBookNeverMarksAPage() throws {
        let app = try makeApp(); meet(app, ["monarch", "ladybug", "honeybee", "luna"])
        app.refreshBadgeFacts()                         // what launch and the Badges page run
        XCTAssertEqual(app.badges.progress(of: .factsRead), 0)
        XCTAssertFalse(app.isFieldNoteStamped("monarch"))
        XCTAssertEqual(FieldNotes.collected(in: app.badges), 0)
    }

    func testACollectedPageMarksOnceAndFourPagesEarnBronze() throws {
        let app = try makeApp(); meet(app, ["monarch", "ladybug", "honeybee", "luna"])
        XCTAssertTrue(app.collectFieldNote("monarch"))
        XCTAssertFalse(app.collectFieldNote("monarch"), "a stamped page stays stamped and counts once")
        XCTAssertEqual(app.badges.progress(of: .factsRead), 1)
        XCTAssertTrue(app.isFieldNoteStamped("monarch"))
        for id in ["ladybug", "honeybee", "luna"] { XCTAssertTrue(app.collectFieldNote(id)) }
        XCTAssertEqual(app.badges.progress(of: .factsRead), 4)
        XCTAssertEqual(app.badges.tier(of: "field_notes"), 1)
        XCTAssertTrue(app.pendingBadges.contains { $0.badgeId == "field_notes" && $0.tier == 1 })
        XCTAssertEqual(app.badgeMomentDelay, 1.4, accuracy: 0.001, "the moment waits for the Page added line")
        XCTAssertEqual(FieldNotes.collected(in: app.badges), 4)
        XCTAssertTrue(BadgeState(json: app.profile?.badgesJSON ?? "", defs: app.badges.defs).isMarked(.factsRead, item: "luna"), "saved")
    }

    func testAFriendNotMetIsNeverCollected() throws {
        let app = try makeApp(); meet(app, ["monarch"])
        XCTAssertFalse(app.collectFieldNote("ladybug"))
        XCTAssertFalse(app.collectFieldNote("dragon"))
        XCTAssertEqual(app.badges.progress(of: .factsRead), 0)
    }

    func testTheOldBestValueIsKeptWhenThereAreFewerStamps() throws {
        let app = try makeApp(); meet(app, ["monarch"])
        // Before the switch the count was the facts shown when the book was open (a best-so-far value).
        app.updateBadges(announce: false) { state, _, t in state.record(.factsRead, value: 6, now: t) }
        XCTAssertTrue(app.collectFieldNote("monarch"))
        XCTAssertEqual(app.badges.progress(of: .factsRead), 6, "progress never goes down")
        XCTAssertEqual(app.badges.tier(of: "field_notes"), 1)
    }

    func testQuietGardenCollectsNothing() throws {
        let app = try makeApp(quiet: true); meet(app, ["monarch"])
        XCTAssertFalse(app.collectFieldNote("monarch"))
        XCTAssertFalse(app.isFieldNoteStamped("monarch"))
        XCTAssertEqual(app.badges.progress(of: .factsRead), 0)
        XCTAssertTrue(app.pendingBadges.isEmpty)
    }

    // MARK: Pruning Pro: pure rules

    func testTheHashIsFNV1aAndStableAcrossLaunches() {
        XCTAssertEqual(FadedBloom.stableHash(""), 0xcbf29ce484222325)
        XCTAssertEqual(FadedBloom.stableHash("a"), 0xaf63dc4c8601ec8c)
        XCTAssertEqual(FadedBloom.stableHash("rose"), 0xa3b3ec1ff114df66)
        // A fixed expected value: a `hashValue` mistake would change on every launch and fail here.
        XCTAssertEqual(FadedBloom.mixed(seed: 42, plantId: "rose", day: 300), 0x3f11d886ec11b2a0)
        XCTAssertEqual((300..<312).filter { FadedBloom.isCueDay(seed: 42, plantId: "rose", day: $0) }, [303, 304, 307, 310, 311])
    }

    func testTheCueShowsOnAboutOneDayInThree() {
        var hits = 0, total = 0
        for seed in 1...1_000 {
            for day in stride(from: 0, to: 365, by: 1) {
                total += 1
                if FadedBloom.shows(seed: Int64(seed) &* 7_919, plantId: "daisy", day: day, stage: 3, pruneReady: true) { hits += 1 }
            }
        }
        XCTAssertEqual(Double(hits) / Double(total), 1.0 / 3.0, accuracy: 0.01)
    }

    func testNoCueBeforeFloweringOrWhilePruneRests() {
        let day = (0..<40).first { FadedBloom.isCueDay(seed: 9, plantId: "daisy", day: $0) }!
        for stage in 0...2 { XCTAssertFalse(FadedBloom.shows(seed: 9, plantId: "daisy", day: day, stage: stage, pruneReady: true), "stage \(stage)") }
        XCTAssertFalse(FadedBloom.shows(seed: 9, plantId: "daisy", day: day, stage: 4, pruneReady: false))
        XCTAssertTrue(FadedBloom.shows(seed: 9, plantId: "daisy", day: day, stage: 3, pruneReady: true))
        XCTAssertTrue(FadedBloom.shows(seed: 9, plantId: "daisy", day: day, stage: 4, pruneReady: true))
    }

    func testTheFreshBudShowsOnLaterVisitsAfterATidyTrimOnly() {
        let cue = (0..<40).first { FadedBloom.isCueDay(seed: 9, plantId: "daisy", day: $0) }!
        let plain = (0..<40).first { !FadedBloom.isCueDay(seed: 9, plantId: "daisy", day: $0) }!
        XCTAssertTrue(FadedBloom.showsFreshBud(seed: 9, plantId: "daisy", today: cue + 1, prunedDay: cue, stage: 3, resting: true))
        XCTAssertFalse(FadedBloom.showsFreshBud(seed: 9, plantId: "daisy", today: cue, prunedDay: cue, stage: 3, resting: true), "same day shows the snip")
        XCTAssertFalse(FadedBloom.showsFreshBud(seed: 9, plantId: "daisy", today: cue + 3, prunedDay: cue, stage: 3, resting: false))
        XCTAssertFalse(FadedBloom.showsFreshBud(seed: 9, plantId: "daisy", today: plain + 1, prunedDay: plain, stage: 3, resting: true))
        XCTAssertFalse(FadedBloom.showsFreshBud(seed: 9, plantId: "daisy", today: cue + 1, prunedDay: nil, stage: 3, resting: true))
    }

    // MARK: Pruning Pro: recording

    private func floweringPlant(_ app: AppModel, shears: Bool = true) -> PlantCollectible {
        let p = app.plants().first!; p.earnedCount = 1; p.stage = 3; p.lastLovedAt = clock
        if shears { var inv = app.inventory; inv.unlock(.shears); app.inventory = inv }
        return p
    }

    /// A weather seed whose today is (or is not) a cue day for the plant.
    private func setSeed(_ app: AppModel, plantId: String, cue: Bool) {
        let today = WeatherDay.key(clock)
        let seed = (Int64(1)...5_000).first { FadedBloom.isCueDay(seed: $0, plantId: plantId, day: today) == cue }!
        app.profile?.weatherSeed = seed
    }

    func testAPruneWithTheCueIsATidyTrim() throws {
        let app = try makeApp(); let plant = floweringPlant(app)
        setSeed(app, plantId: plant.plantId, cue: true)
        XCTAssertTrue(app.showsFadedBloom(plant))
        let before = plant.growthPoints
        let r = app.tend(.prune, plant: plant)
        XCTAssertTrue(r.applied)
        XCTAssertTrue(r.tidy)
        XCTAssertTrue(r.message.hasPrefix("Snip! A tidy trim. Snipping faded flowers helps new ones grow."), r.message)
        XCTAssertEqual(app.badges.progress(of: .tidyTrims), 1)
        XCTAssertEqual(app.badges.progress(of: .prunes), 1, "every trim still counts as a trim")
        XCTAssertFalse(app.showsFadedBloom(plant), "the trim starts the shears' rest, so the cue goes at once")
        XCTAssertGreaterThan(plant.growthPoints, before)
        // The next visit (tomorrow, still resting) shows the fresh bud.
        clock = clock.addingTimeInterval(86_400)
        XCTAssertTrue(app.showsFreshBud(plant))
    }

    func testAPruneWithNoCueIsAPlainTrimThatGrowsTheSame() throws {
        let tidyApp = try makeApp(); let tp = floweringPlant(tidyApp)
        setSeed(tidyApp, plantId: tp.plantId, cue: true)
        let tb = tp.growthPoints; _ = tidyApp.tend(.prune, plant: tp)

        let app = try makeApp(); let plant = floweringPlant(app)
        setSeed(app, plantId: plant.plantId, cue: false)
        XCTAssertFalse(app.showsFadedBloom(plant))
        let before = plant.growthPoints
        let r = app.tend(.prune, plant: plant)
        XCTAssertTrue(r.applied); XCTAssertFalse(r.tidy)
        XCTAssertFalse(r.message.contains("tidy"), r.message)
        XCTAssertEqual(app.badges.progress(of: .tidyTrims), 0)
        XCTAssertEqual(plant.growthPoints - before, tp.growthPoints - tb, "a tidy trim grows the plant as any trim does")
        clock = clock.addingTimeInterval(86_400)
        XCTAssertFalse(app.showsFreshBud(plant))
    }

    func testNoCueWithoutShearsOrOnSeedlings() throws {
        let app = try makeApp(); let plant = floweringPlant(app, shears: false)
        app.fadedBloomTestOverride = true
        XCTAssertFalse(app.showsFadedBloom(plant), "it never invites a trim that is not possible")
        var inv = app.inventory; inv.unlock(.shears); app.inventory = inv
        XCTAssertTrue(app.showsFadedBloom(plant))
        plant.stage = 2
        XCTAssertFalse(app.showsFadedBloom(plant), "faded bloom only: no shaggy sprig before flowering")
    }

    func testQuietGardenShowsTheCueAndLineButCountsNothing() throws {
        let app = try makeApp(quiet: true); let plant = floweringPlant(app, shears: false)
        app.fadedBloomTestOverride = true
        XCTAssertTrue(app.showsFadedBloom(plant), "Quiet Garden prunes without shears, so the cue shows")
        let r = app.tend(.prune, plant: plant)
        XCTAssertTrue(r.applied); XCTAssertTrue(r.tidy)
        XCTAssertEqual(r.message, PruningProCopy.tidy + " " + PruningProCopy.fact)
        XCTAssertEqual(app.badges.progress(of: .tidyTrims), 0)
        XCTAssertTrue(app.pendingBadges.isEmpty)
    }

    func testFiveTidyTrimsEarnBronzeAndTheMomentWaitsForTheLine() throws {
        let app = try makeApp(); app.fadedBloomTestOverride = true
        let plants = app.plants().prefix(5)
        var inv = app.inventory; inv.unlock(.shears); app.inventory = inv
        for p in plants { p.earnedCount = 1; p.stage = 3; p.lastLovedAt = clock; XCTAssertTrue(app.tend(.prune, plant: p).tidy) }
        XCTAssertEqual(app.badges.progress(of: .tidyTrims), 5)
        XCTAssertEqual(app.badges.tier(of: "pruning_pro"), 1)
        XCTAssertTrue(app.pendingBadges.contains { $0.badgeId == "pruning_pro" })
        XCTAssertGreaterThanOrEqual(app.badgeMomentDelay, 1.2)
    }

    func testOldPruningTiersAreKeptAfterTheSwitch() throws {
        let defs = try BadgeCatalog.load()
        // A garden from before the switch: 30 plain trims had earned bronze and silver on the old 5 / 25 / 75.
        let old = #"{"progress":{"prunes":30},"unlocked":{"pruning_pro#1":0,"pruning_pro#2":0}}"#
        var state = BadgeState(json: old, defs: defs)
        XCTAssertEqual(state.tier(of: "pruning_pro"), 2)
        let first = state.record(.tidyTrims, amount: 5, now: clock)
        XCTAssertTrue(first.isEmpty, "bronze was already earned")
        XCTAssertEqual(state.tier(of: "pruning_pro"), 2, "the card shows the higher of the two")
        XCTAssertEqual(state.unlockedDate(badge: "pruning_pro", tier: 1), Date(timeIntervalSinceReferenceDate: 0), "earned dates stay")
        let gold = state.record(.tidyTrims, amount: 45, now: clock)
        XCTAssertEqual(gold.map(\.tier), [3])
        XCTAssertEqual(state.progress(of: .prunes), 30)
    }

    // MARK: Catalogue and copy

    func testTheCatalogueEntriesMatchTheMechanics() throws {
        let defs = try BadgeCatalog.load()
        let notes = try XCTUnwrap(defs.first { $0.id == "field_notes" })
        XCTAssertEqual(notes.counter, BadgeCounter.factsRead.rawValue); XCTAssertEqual(notes.thresholds, [4, 8, 12])
        XCTAssertEqual(notes.blurb, FieldNotesCopy.blurb)
        let prune = try XCTUnwrap(defs.first { $0.id == "pruning_pro" })
        XCTAssertEqual(prune.counter, BadgeCounter.tidyTrims.rawValue); XCTAssertEqual(prune.thresholds, [5, 20, 50])
        XCTAssertEqual(prune.blurb, PruningProCopy.blurb)
        XCTAssertFalse(BadgeCounter.tidyTrims.isHighWater)
        XCTAssertEqual(VisitorCatalog.all.filter { $0.fact != nil }.count, 12, "gold (12 pages) is reachable")
    }

    func testTheNewCopyIsKind() {
        let lines = FieldNotesCopy.all + PruningProCopy.all
        // Not in CopySafety.banned yet (docs/pm/badge-mechanics-art.md, Tests).
        let alsoAvoid = ["save", "rescue", "danger", "warning", "alert", "locked", "timer", "countdown"]
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for w in alsoAvoid { XCTAssertFalse(line.lowercased().contains(w), "\(line) has \(w)") }
            if !line.contains(". Met on ") { XCTAssertLessThanOrEqual(line.count, 60, line) }
        }
        XCTAssertEqual(FieldNotesCopy.pages(1, of: 12), "1 page of 12")
        XCTAssertEqual(FieldNotesCopy.pages(4, of: 12), "4 pages of 12")
        XCTAssertEqual(PruningProCopy.plantLabel("Daisy, in flower"), "Daisy, in flower, ready for a trim")
    }

    // MARK: B2a: SKAdNetwork ids for AdMob

    func testInfoPlistCarriesGooglesSKAdNetworkList() throws {
        let items = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "SKAdNetworkItems") as? [[String: String]])
        let ids = items.compactMap { $0["SKAdNetworkIdentifier"] }
        XCTAssertEqual(ids.count, items.count, "every entry has an identifier")
        XCTAssertGreaterThanOrEqual(ids.count, 50)
        XCTAssertTrue(ids.contains("cstr6suwn9.skadnetwork"), "Google's own id")
        XCTAssertEqual(Set(ids).count, ids.count, "no repeats")
        for id in ids { XCTAssertTrue(id.hasSuffix(".skadnetwork") && id == id.lowercased(), id) }
    }
}

import XCTest
import SwiftData
@testable import WordFlora

/// A4 Mist Maker (release plan G3, docs/pm/badge-mechanics-art.md section 4): a real Mist action, once per plant per
/// calendar day, free, +1 growth or +2 for tropical, epiphyte and shade plants; the one new stored field `lastMistedAt`.
@MainActor
final class MistMakerTests: XCTestCase {
    private func cal(_ tz: String = "America/New_York") -> Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: tz)!; return c
    }

    final class Clock { var now: Date; init(_ d: Date) { now = d } }

    func makeApp(quiet: Bool = false, clock: Clock? = nil, everything: Bool = false) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-mist-\(UUID().uuidString)")!)
        settings.quietGarden = quiet; settings.showEverything = everything
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let c = clock ?? Clock(.now)
        return AppModel(container: container, settings: settings, bank: bank, now: { c.now })
    }

    private func plant(_ app: AppModel, _ id: String) -> PlantCollectible {
        let p = app.plants().first { $0.plantId == id }!; p.earnedCount = 1; return p
    }

    private func giveMister(_ app: AppModel) { var inv = app.inventory; inv.unlock(.mister); app.inventory = inv }

    // MARK: The rule (ToolEngine.mist)

    func testOncePerPlantPerCalendarDayAcrossDaylightSaving() {
        let c = cal()
        let p = PlantCollectible(name: "Fern", botanicalName: "", botanicalFact: "", level: 1, imageName: "plant_fern", plantId: "fern")
        var inv = ToolInventory(); inv.unlock(.mister)
        // 2026-11-01 is the US fall-back day (25 hours long).
        let before = c.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 0, minute: 30))!
        let lateSameDay = c.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 23, minute: 50))!
        let afterMidnight = c.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 0, minute: 5))!
        XCTAssertTrue(ToolEngine.mist(p, inventory: inv, traits: [], now: before, calendar: c, economy: .default).applied)
        XCTAssertEqual(p.lastMistedAt, before)
        XCTAssertGreaterThan(lateSameDay.timeIntervalSince(before), 24 * 3_600, "more than 24 h, still the same day")
        XCTAssertEqual(ToolEngine.mist(p, inventory: inv, traits: [], now: lateSameDay, calendar: c, economy: .default).reason, .doneForToday)
        XCTAssertTrue(ToolEngine.mist(p, inventory: inv, traits: [], now: afterMidnight, calendar: c, economy: .default).applied,
                      "a new mist after midnight")
        // Spring forward (2026-03-08, 23 hours): late on the day before and just after midnight are different days.
        let q = PlantCollectible(name: "Fern", botanicalName: "", botanicalFact: "", level: 1, imageName: "plant_fern", plantId: "fern")
        let sat = c.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 23, minute: 30))!
        let sun = c.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 0, minute: 10))!
        let sunLate = c.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 23, minute: 59))!
        XCTAssertTrue(ToolEngine.mist(q, inventory: inv, traits: [], now: sat, calendar: c, economy: .default).applied)
        XCTAssertTrue(ToolEngine.mist(q, inventory: inv, traits: [], now: sun, calendar: c, economy: .default).applied)
        XCTAssertFalse(ToolEngine.mist(q, inventory: inv, traits: [], now: sunLate, calendar: c, economy: .default).applied)
    }

    func testTraitBonusForTropicalEpiphyteAndShadePlants() {
        var inv = ToolInventory(); inv.unlock(.mister)
        for (traits, growth) in [([String](), 1), (["meadow"], 1), (["tropical"], 2), (["epiphyte"], 2), (["shade"], 2), (["tropical", "epiphyte"], 2)] {
            let p = PlantCollectible(name: "P", botanicalName: "", botanicalFact: "", level: 1, imageName: "plant_p", plantId: "p")
            let r = ToolEngine.mist(p, inventory: inv, traits: Set(traits), now: .now, calendar: cal(), economy: .default)
            XCTAssertEqual(r.gpGained, growth, "\(traits)"); XCTAssertEqual(p.growthPoints, growth)
            XCTAssertEqual(ToolEngine.mistGrowth(traits: Set(traits)), growth)
        }
    }

    func testNeedsTheMisterOutsideQuietGarden() {
        let p = PlantCollectible(name: "P", botanicalName: "", botanicalFact: "", level: 1, imageName: "plant_p", plantId: "p")
        XCTAssertEqual(ToolEngine.mist(p, inventory: ToolInventory(), traits: [], now: .now, calendar: cal(), economy: .default).reason, .notOwned)
        XCTAssertNil(p.lastMistedAt)
        XCTAssertTrue(ToolEngine.mist(p, inventory: ToolInventory(), traits: [], now: .now, calendar: cal(), economy: .default, quiet: true).applied,
                      "Quiet Garden: mist works on every plant, no tool needed")
    }

    // MARK: Through the app

    func testMistIsFreeGrowsAndCountsMistSprays() throws {
        let app = try makeApp(); let fern = plant(app, "fern"); giveMister(app)
        app.profile?.water = 3; app.profile?.soil = 2
        XCTAssertEqual(app.actionState(.mist, plant: fern).status, .ready)
        let r = app.tend(.mist, plant: fern)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(app.profile?.water, 3); XCTAssertEqual(app.profile?.soil, 2, "no drop or scoop is spent")
        XCTAssertEqual(fern.growthPoints, 2, "a fern is a shade plant: +2")
        XCTAssertEqual(r.message, MistMakerCopy.loves(name: "Fern"))
        XCTAssertEqual(app.badges.progress(of: .mistSprays), 1)
        let done = app.actionState(.mist, plant: fern)
        XCTAssertEqual(done.status, .done); XCTAssertEqual(done.label, MistMakerCopy.doneLabel)
        XCTAssertEqual(done.line, MistMakerCopy.done(name: "Fern"))
        let again = app.tend(.mist, plant: fern)
        XCTAssertFalse(again.applied); XCTAssertEqual(again.message, "Fern is fresh and misty today. More mist tomorrow!")
        let daisy = plant(app, "daisy")
        XCTAssertEqual(app.tend(.mist, plant: daisy).message, MistMakerCopy.misted(name: "Daisy"))
        XCTAssertEqual(daisy.growthPoints, 1)
        XCTAssertEqual(app.badges.progress(of: .mistSprays), 2)
    }

    func testHiddenWithoutTheMisterAndShownWithShowEverythingOrQuietGarden() throws {
        let app = try makeApp(); let fern = plant(app, "fern")
        XCTAssertFalse(app.showsMist)
        XCTAssertEqual(app.actionState(.mist, plant: fern).status, .needsSupply)
        XCTAssertEqual(app.actionState(.mist, plant: fern).line, MistMakerCopy.needMister)
        giveMister(app); XCTAssertTrue(app.showsMist)
        XCTAssertTrue(try makeApp(everything: true).showsMist)
        let quiet = try makeApp(quiet: true)
        XCTAssertTrue(quiet.showsMist)
        XCTAssertEqual(quiet.actionState(.mist, plant: plant(quiet, "fern")).status, .ready)
    }

    func testASeedShowsWakeFirst() throws {
        let app = try makeApp(); let fern = plant(app, "fern"); giveMister(app)
        fern.lastLovedAt = Date.now.addingTimeInterval(-6 * 86_400)
        guard app.loveState(fern).isSeed else { throw XCTSkip("the love rule does not make a seed here") }
        let s = app.actionState(.mist, plant: fern)
        XCTAssertEqual(s.status, .seed); XCTAssertEqual(s.label, AppModel.wakeFirstLabel)
        XCTAssertFalse(app.tend(.mist, plant: fern).applied)
    }

    func testQuietGardenGrowsButCountsNothing() throws {
        let app = try makeApp(quiet: true); let fern = plant(app, "fern")
        let r = app.tend(.mist, plant: fern)
        XCTAssertTrue(r.applied); XCTAssertEqual(fern.growthPoints, 2)
        XCTAssertEqual(app.badges.progress(of: .mistSprays), 0, "no count in Quiet Garden")
        XCTAssertFalse(r.message.contains("growth"), "no numbers in Quiet Garden")
    }

    func testTheOldMistsDropCountIsNoLongerRecorded() throws {
        let clock = Clock(.now)
        let app = try makeApp(clock: clock); giveMister(app)
        app.profile?.water = 0; app.profile?.lastTrickleAt = clock.now
        clock.now = clock.now.addingTimeInterval(12 * 3_600)
        app.refreshFreeDrops()
        XCTAssertGreaterThan(app.profile?.water ?? 0, 0, "the mister's trickle still brings drops")
        XCTAssertEqual(app.badges.progress(of: .mists), 0, "the old drop count is not recorded any more")
    }

    /// The Life panel's "all care done" stays water, feed and sun: a mist never changes it.
    func testLifePlentyIsUnchangedByAMist() throws {
        let app = try makeApp(); let fern = plant(app, "fern"); giveMister(app)
        let c = Calendar.current, now = Date.now
        let before = TendingEngine.capacityFill(fern, now: now, calendar: c, economy: .default)
        _ = app.tend(.mist, plant: fern)
        XCTAssertEqual(TendingEngine.capacityFill(fern, now: now, calendar: c, economy: .default), before)
        XCTAssertEqual(TendingEngine.capacityState(fern, now: now, calendar: c, economy: .default), .room)
    }

    // MARK: Badge and copy

    func testMistMakerCountsMistSpraysAndKeepsEarnedTiers() throws {
        let defs = try BadgeCatalog.load()
        let def = try XCTUnwrap(defs.first { $0.id == "mist_maker" })
        XCTAssertEqual(def.counter, "mistSprays"); XCTAssertEqual(def.thresholds, [10, 40, 100])
        XCTAssertEqual(def.blurb, MistMakerCopy.blurb)
        XCTAssertTrue(BadgeCounter.retired.contains(.mists))
        var s = BadgeState(defs: defs)
        for _ in 0..<9 { s.record(.mistSprays, now: .now) }
        XCTAssertEqual(s.tier(of: "mist_maker"), 0)
        XCTAssertEqual(s.record(.mistSprays, now: .now).map(\.tier), [1])
    }

    func testCopyIsCalm() {
        for line in MistMakerCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        for line in MistMakerCopy.all where !line.hasPrefix("Fern is fresh") { XCTAssertLessThanOrEqual(line.count, 60, line) }
        XCTAssertEqual(MistMakerCopy.buttonLabel(name: "Fern"), "Mist Fern")
        XCTAssertEqual(MistMakerCopy.tip, "Some plants love a little mist on their leaves.")
        XCTAssertEqual(MistSprayView.dropletCount(calm: false), 24); XCTAssertEqual(MistSprayView.dropletCount(calm: true), 12)
    }
}

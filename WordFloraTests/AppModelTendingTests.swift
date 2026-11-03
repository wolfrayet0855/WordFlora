import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class AppModelTendingTests: XCTestCase {
    func makeApp(quiet: Bool = false, now: @escaping () -> Date = { .now }) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let suite = UserDefaults(suiteName: "wf-tests-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: suite)
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: now)
        return app
    }
    func firstPlant(_ app: AppModel) throws -> PlantCollectible {
        let p = app.plants().first!; p.earnedCount = 1; return p
    }

    func testWaterSpendsADropAndGrowsThePlant() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.water = 3
        let r = app.tend(.water, plant: plant)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(app.profile?.water, 2); XCTAssertEqual(plant.growthPoints, 4)
    }

    func testWaterWithNoDropsIsDeclinedWithAFriendlyReason() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.water = 0
        let r = app.tend(.water, plant: plant)
        XCTAssertFalse(r.applied)
        XCTAssertEqual(r.message, "No drops left. Win a word to earn more.")
    }

    func testPruneNeedsShearsAndFeedSpendsAScoop() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.soil = 2
        XCTAssertFalse(app.tend(.prune, plant: plant).applied)                 // no shears yet
        var inv = app.inventory; inv.unlock(.shears); app.inventory = inv
        XCTAssertTrue(app.tend(.prune, plant: plant).applied)                  // 4 growth
        XCTAssertTrue(app.tend(.feed, plant: plant).applied)                   // fills the rest of today's 10
        XCTAssertEqual(app.profile?.soil, 1)
        XCTAssertEqual(plant.growthPoints, 10)
    }

    func testRepotMatchIsHappy() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.soil = 3
        let good = SoilType.preferred(forPlantId: plant.plantId)
        let r = app.tend(.repot(good), plant: plant)
        XCTAssertTrue(r.applied); XCTAssertEqual(r.message, "\(plant.name) loves its new pot!")
    }

    func testInventoryPersistsOnTheProfile() throws {
        let app = try makeApp()
        var inv = app.inventory; inv.unlock(.lamp); app.inventory = inv
        XCTAssertEqual(ToolInventory(json: app.profile?.toolsJSON ?? "").tier(of: .lamp), 1)
    }

    func testQuietGardenSpendsAndEarnsNothing() throws {
        let app = try makeApp(quiet: true); let plant = try firstPlant(app); app.profile?.water = 0; app.profile?.soil = 0
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(plant.growthPoints, 0)
    }

    func testStageUpIsReportedGently() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.water = 3; plant.growthPoints = 8
        let r = app.tend(.water, plant: plant)
        XCTAssertTrue(r.stageUp); XCTAssertEqual(r.message, "\(plant.name) grew a little!")
    }

    func testFreeDropsTrickleInOnStartupAndOnDemand() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock })
        app.profile?.water = 0; app.profile?.lastTrickleAt = clock
        clock = clock.addingTimeInterval(9 * 3600)
        app.refreshFreeDrops()
        XCTAssertEqual(app.profile?.water, 2)
    }

    func testTendingRecordsBadgeProgress() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }); let plant = try firstPlant(app); app.profile?.water = 30
        for _ in 0..<3 { _ = app.tend(.water, plant: plant); clock = clock.addingTimeInterval(86_400) }
        XCTAssertEqual(app.badges.progress(of: .waterings), 3)
        XCTAssertFalse(app.profile?.badgesJSON.isEmpty ?? true)       // persisted
    }

    // MARK: ads accounting
    func testAdContextReflectsTheProfileSettingsAndEntitlements() throws {
        let t = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { t })
        app.profile?.roundsSinceAd = 3; app.profile?.currentLevel = 2
        app.settings.ageBand = .eighteenPlus; app.settings.completedSessions = 3
        let c = app.adContext(choice: .oneMore)
        XCTAssertEqual(c.roundsSinceAd, 3); XCTAssertEqual(c.wordLevelUps, 1); XCTAssertEqual(c.completedSessions, 3)
        XCTAssertEqual(c.choice, .oneMore); XCTAssertFalse(c.isUnderThirteen); XCTAssertFalse(c.hasRemoveAds)
        XCTAssertTrue(AdGate.shouldShowInterstitial(c))
        app.settings.ageBand = .under13
        XCTAssertFalse(AdGate.shouldShowInterstitial(app.adContext(choice: .oneMore)))
        app.settings.ageBand = .eighteenPlus
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_monthly"]))
        XCTAssertFalse(AdGate.shouldShowInterstitial(app.adContext(choice: .oneMore)))
    }

    func testAnUnknownAgeNeverGetsAds() throws {
        let app = try makeApp(); app.settings.ageBand = nil; app.profile?.roundsSinceAd = 9; app.settings.completedSessions = 9
        XCTAssertFalse(AdGate.shouldShowInterstitial(app.adContext(choice: .oneMore)))
    }

    func testRecordingAShownAdResetsTheCounterAndCountsToday() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }); app.profile?.roundsSinceAd = 3
        app.recordAdShown()
        XCTAssertEqual(app.profile?.roundsSinceAd, 0); XCTAssertEqual(app.profile?.adsToday, 1)
        XCTAssertEqual(app.adContext(choice: .oneMore).lastAdAt, clock)
        app.recordAdShown(); XCTAssertEqual(app.profile?.adsToday, 2)
        clock = clock.addingTimeInterval(86_400 + 60)
        XCTAssertEqual(app.adContext(choice: .oneMore).adsToday, 0)               // a new local day starts fresh
    }

    func testPeakDismissalIsRemembered() throws {
        let t = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { t }); app.markPeakDismissed()
        XCTAssertEqual(app.adContext(choice: .oneMore).lastPeakAt, t)
    }

    func testALossBlocksTheNextAdBoundary() throws {
        let app = try makeApp()
        app.game.start(entry: WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                                        tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t"))
        for ch in "ZXQJKVWY" { app.game.guessInput = String(ch); app.game.submitGuess() }
        XCTAssertTrue(app.adContext(choice: .oneMore).lastRoundWasLoss)
    }

    // MARK: rewarded ads (optional, player-initiated)
    func testRewardedOfferRules() throws {
        let app = try makeApp(); app.settings.ageBand = .eighteenPlus
        XCTAssertTrue(app.canOfferRewarded)
        app.settings.ageBand = .under13; XCTAssertFalse(app.canOfferRewarded)
        app.settings.ageBand = .eighteenPlus
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"])); XCTAssertFalse(app.canOfferRewarded)
    }

    func testRewardedGrantsTwoDropsThreeTimesADay() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }); app.settings.ageBand = .eighteenPlus; app.profile?.water = 0
        for _ in 0..<3 { XCTAssertTrue(app.canOfferRewarded); app.grantRewardedDrops() }
        XCTAssertEqual(app.profile?.water, 6)
        XCTAssertFalse(app.canOfferRewarded)
        clock = clock.addingTimeInterval(86_400 + 60)
        XCTAssertTrue(app.canOfferRewarded)
    }

    func testRewardedDropsRespectTheWaterBankCap() throws {
        let app = try makeApp(); app.settings.ageBand = .eighteenPlus; app.profile?.water = 39
        app.grantRewardedDrops()
        XCTAssertEqual(app.profile?.water, 40)
    }
}


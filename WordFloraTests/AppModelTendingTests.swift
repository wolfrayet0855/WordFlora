import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class AppModelTendingTests: XCTestCase {
    func makeApp(quiet: Bool = false, now: @escaping () -> Date = { .now }, center: NotificationCenterProviding = ReminderTests.FakeCenter(), launchedWithCloud: Bool = false) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let suite = UserDefaults(suiteName: "wf-tests-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: suite)
        settings.quietGarden = quiet
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: now, notifications: center, launchedWithCloud: launchedWithCloud)
        return app
    }
    func firstPlant(_ app: AppModel) throws -> PlantCollectible {
        let p = app.plants().first!; p.earnedCount = 1; return p
    }

    func testWaterSpendsADropAndGrowsThePlant() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.water = 3
        let r = app.tend(.water, plant: plant)
        XCTAssertTrue(r.applied)
        XCTAssertEqual(app.profile?.water, 2); XCTAssertEqual(plant.growthPoints, 3)
    }

    func testWaterWithNoDropsIsDeclinedWithAFriendlyReason() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.water = 0
        let r = app.tend(.water, plant: plant)
        XCTAssertFalse(r.applied)
        XCTAssertEqual(r.message, "Your can is dry. Win a word to fill it.")
    }

    func testPruneNeedsShearsAndFeedSpendsAScoop() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.soil = 2
        XCTAssertFalse(app.tend(.prune, plant: plant).applied)                 // no shears yet
        var inv = app.inventory; inv.unlock(.shears); app.inventory = inv
        XCTAssertTrue(app.tend(.prune, plant: plant).applied)                  // 4 growth
        XCTAssertTrue(app.tend(.feed, plant: plant).applied)                   // 4 more; pruning never blocks feeding
        XCTAssertEqual(app.profile?.soil, 1)
        XCTAssertEqual(plant.growthPoints, 8)
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

    /// Quiet Garden hides numbers and removes costs and cooldowns, but plants still grow at the normal daily pace, so the
    /// garden track and the tools it unlocks are never blocked (spec section 18, P11 "never affects main progression").
    func testQuietGardenSpendsNothingButPlantsStillGrow() throws {
        let app = try makeApp(quiet: true); let plant = try firstPlant(app); app.profile?.water = 0; app.profile?.soil = 0
        XCTAssertTrue(app.tend(.water, plant: plant).applied)
        XCTAssertEqual(plant.growthPoints, 3)
        XCTAssertEqual(app.profile?.water, 0)
    }

    func testQuietGardenStillRespectsTheTwoDrinksADay() throws {
        let t = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        let app = try makeApp(quiet: true, now: { t }); let plant = try firstPlant(app)
        for _ in 0..<10 { _ = app.tend(.water, plant: plant) }
        XCTAssertEqual(plant.growthPoints, 6)
    }

    func testStageUpIsReportedGently() throws {
        let app = try makeApp(); let plant = try firstPlant(app); app.profile?.water = 3; plant.growthPoints = 9
        let r = app.tend(.water, plant: plant)
        XCTAssertTrue(r.stageUp); XCTAssertTrue(r.message.hasPrefix("\(plant.name) grew a little!"))
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
        let app = try makeApp(); app.settings.ageBand = .eighteenPlus; app.settings.completedSessions = 1
        XCTAssertTrue(app.canOfferRewarded)
        app.settings.ageBand = .under13; XCTAssertFalse(app.canOfferRewarded)
        app.settings.ageBand = .eighteenPlus
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"])); XCTAssertFalse(app.canOfferRewarded)
    }

    func testRewardedGrantsTwoDropsThreeTimesADay() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }); app.settings.ageBand = .eighteenPlus; app.settings.completedSessions = 1; app.profile?.water = 0
        for _ in 0..<3 { XCTAssertTrue(app.canOfferRewarded); app.grantRewardedDrops() }
        XCTAssertEqual(app.profile?.water, 6)
        XCTAssertFalse(app.canOfferRewarded)
        clock = clock.addingTimeInterval(86_400 + 60)
        XCTAssertTrue(app.canOfferRewarded)
    }

    func testRewardedDropsRespectTheWaterBankCap() throws {
        let app = try makeApp(); app.settings.ageBand = .eighteenPlus; app.settings.completedSessions = 1; app.profile?.water = 39
        app.grantRewardedDrops()
        XCTAssertEqual(app.profile?.water, 40)
    }

    // MARK: tools unlock and upgrade
    func testNetArrivesWithTheButterflyUnlock() throws {
        let app = try makeApp()
        app.syncToolUnlocks()
        XCTAssertEqual(app.inventory.tier(of: .net), 0)
        app.profile?.currentLevel = 2                         // first word level-up unlocks the butterfly game
        app.syncToolUnlocks()
        XCTAssertEqual(app.inventory.tier(of: .net), 1)
    }

    func testGardenLevelsUnlockMisterShearsLamp() throws {
        let app = try makeApp()
        for plant in app.plants() where plant.level == 1 { plant.earnedCount = 1; plant.stage = 4 }
        app.syncToolUnlocks()
        XCTAssertEqual(app.inventory.tier(of: .mister), 1)
        XCTAssertEqual(app.inventory.tier(of: .shears), 0)
        for plant in app.plants() where plant.level == 2 { plant.earnedCount = 1; plant.stage = 4 }
        app.syncToolUnlocks()
        XCTAssertEqual(app.inventory.tier(of: .shears), 1)
    }

    func testSyncingUnlocksNeverTakesAToolAway() throws {
        let app = try makeApp()
        var inv = app.inventory; inv.unlock(.lamp); app.inventory = inv
        app.syncToolUnlocks()
        XCTAssertEqual(app.inventory.tier(of: .lamp), 1)
    }

    func testUpgradeSpendsShedPointsAndReportsWhyNot() throws {
        let app = try makeApp(); app.profile?.shedPoints = 40
        XCTAssertTrue(app.upgradeTool(.can))
        XCTAssertEqual(app.profile?.shedPoints, 10); XCTAssertEqual(app.inventory.tier(of: .can), 2)
        XCTAssertFalse(app.upgradeTool(.can))                    // tier 3 costs 120
        XCTAssertFalse(app.upgradeTool(.net))                    // not owned
        XCTAssertEqual(app.profile?.shedPoints, 10)
    }

    // MARK: badges after rounds
    func testWinningUpdatesCollectionAndPerfectBloomBadges() throws {
        let app = try makeApp()
        let e = WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                          tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
        app.game.start(entry: e)
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
        let unlocks = app.roundFinished()
        XCTAssertEqual(app.badges.progress(of: .plantsOwned), 1)
        XCTAssertEqual(app.badges.progress(of: .perfectBlooms), 1)
        XCTAssertTrue(unlocks.contains { $0.badgeId == "perfect_bloom" && $0.tier == 1 })
        XCTAssertTrue(app.roundFinished().isEmpty)               // asking again never re-awards
    }

    func testARestingRoundDoesNotAwardWinBadges() throws {
        let app = try makeApp()
        let e = WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                          tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
        app.game.start(entry: e)
        for ch in "ZXQJKVWY" { app.game.guessInput = String(ch); app.game.submitGuess() }
        _ = app.roundFinished()
        XCTAssertEqual(app.badges.progress(of: .perfectBlooms), 0)
        XCTAssertEqual(app.badges.progress(of: .plantsOwned), 0)
    }

    func testReviveRecordsItsBadge() throws {
        let app = try makeApp(); app.profile?.roseOfJerichoCount = 1
        let e = WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                          tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
        app.game.start(entry: e)
        for ch in "ZXQJKVWY" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.wakeFlower()
        XCTAssertEqual(app.game.phase, .playing)
        XCTAssertEqual(app.badges.progress(of: .revives), 1)
    }

    func testStreakIsTrackedAsAHighWaterBadgeCounter() throws {
        let app = try makeApp(); app.profile?.streak = 8
        _ = app.roundFinished()
        XCTAssertEqual(app.badges.progress(of: .streak), 0)       // no finished round yet, nothing recorded
        let e = WordEntry(id: "x", word: "LOTUS", display: "Lotus", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                          tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
        app.game.start(entry: e)
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.profile?.streak = 8
        _ = app.roundFinished()
        XCTAssertEqual(app.badges.progress(of: .streak), 8)
    }

    // MARK: butterfly game
    private func localDate(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!
    }

    func testDaytimeGamesNeverSpawnNightSpeciesUnlessALanternIsUsed() throws {
        let app = try makeApp(now: { self.localDate(hour: 11) })
        var g = app.startButterflyGame(seed: 1)
        for _ in 0..<300 { g.tick(0.1); for v in g.visitors { XCTAssertFalse(["firefly", "luna"].contains(v.speciesId)) } }
    }

    func testEveningGamesFeatureNightSpeciesAndStillAllowDayOnes() throws {
        let app = try makeApp(now: { self.localDate(hour: 19) })
        var g = app.startButterflyGame(seed: 1)
        var saw = Set<String>()
        for _ in 0..<2000 { g.tick(0.05); g.visitors.forEach { saw.insert($0.speciesId) }; if g.isFinished { g = app.startButterflyGame(seed: UInt64(saw.count) + 7) } }
        XCTAssertTrue(saw.contains("firefly") || saw.contains("luna"))
        XCTAssertTrue(saw.contains { !["firefly", "luna"].contains($0) })
    }

    func testGlowLanternBringsNightVisitorsAtAnyHourAndIsUsedUp() throws {
        let app = try makeApp(now: { self.localDate(hour: 11) }); app.profile?.glowLanterns = 1
        var g = app.startButterflyGame(seed: 2, useLantern: true)
        XCTAssertEqual(app.profile?.glowLanterns, 0)
        var saw = Set<String>(); for _ in 0..<600 { g.tick(0.05); g.visitors.forEach { saw.insert($0.speciesId) } }
        XCTAssertTrue(saw.contains("firefly") || saw.contains("luna"))
        _ = app.startButterflyGame(seed: 3, useLantern: true)                   // none left, falls back to the normal pool
        XCTAssertEqual(app.profile?.glowLanterns, 0)
    }

    func testFinishingAppliesRewardsRecordsStickersAndBadges() throws {
        let app = try makeApp(now: { self.localDate(hour: 11) }); app.profile?.water = 0; app.profile?.shedPoints = 0
        var g = app.startButterflyGame(seed: 5)
        g.visitors = [ButterflyGameModel.Visitor(id: 90, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        g.catchAt(x: 0.5, y: 0.5)
        let s = app.finishButterflyGame(g)
        XCTAssertEqual(s.water, 1); XCTAssertGreaterThanOrEqual(s.shedPoints, 2)
        XCTAssertEqual(app.profile?.water, 1)
        XCTAssertEqual(StickerAlbum(json: app.profile?.albumJSON ?? "").count(of: "monarch"), 1)
        XCTAssertEqual(app.badges.progress(of: .visitorSpecies), 1)
        XCTAssertEqual(app.badges.progress(of: .butterflyPlays), 1)
    }

    func testOnlyThreeRewardedPlaysADayButStickersAlwaysCount() throws {
        let app = try makeApp(now: { self.localDate(hour: 11) }); app.profile?.water = 0
        func play(_ species: String) -> ButterflyRewards.Summary {
            var g = app.startButterflyGame(seed: 1)
            g.visitors = [ButterflyGameModel.Visitor(id: 90, speciesId: species, x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
            g.catchAt(x: 0.5, y: 0.5)
            return app.finishButterflyGame(g)
        }
        for _ in 0..<3 { XCTAssertEqual(play("honeybee").water, 1) }
        let fourth = play("ladybug")
        XCTAssertEqual(fourth.water, 0); XCTAssertEqual(app.profile?.water, 3)
        XCTAssertEqual(StickerAlbum(json: app.profile?.albumJSON ?? "").count(of: "ladybug"), 1)
    }

    func testQuietGardenKeepsStickersButEarnsNoCurrency() throws {
        let app = try makeApp(quiet: true, now: { self.localDate(hour: 11) }); app.profile?.water = 0
        var g = app.startButterflyGame(seed: 5)
        g.visitors = [ButterflyGameModel.Visitor(id: 90, speciesId: "monarch", x: 0.5, y: 0.5, vx: 0, vy: 0, born: 0, resting: false)]
        g.catchAt(x: 0.5, y: 0.5)
        _ = app.finishButterflyGame(g)
        XCTAssertEqual(app.profile?.water, 0); XCTAssertEqual(app.profile?.shedPoints, 0)
        XCTAssertEqual(StickerAlbum(json: app.profile?.albumJSON ?? "").count(of: "monarch"), 1)
        XCTAssertEqual(app.badges.progress(of: .visitorSpecies), 0)       // quiet mode advances no badge
    }

    func testFloweringPlantsRaiseTheVisitorCap() throws {
        let app = try makeApp()
        let g0 = app.startButterflyGame(seed: 1)
        for p in app.plants().prefix(6) { p.earnedCount = 1; p.stage = 3 }     // only plants the player owns attract visitors
        let g1 = app.startButterflyGame(seed: 1)
        XCTAssertGreaterThan(g1.maxVisitorsForTests, g0.maxVisitorsForTests)
    }

    // MARK: reminders through the app
    func testRemindersTurnOnOnlyWhenPermissionIsGranted() async throws {
        let granted = ReminderTests.FakeCenter()
        let app = try makeApp(center: granted)
        XCTAssertFalse(app.settings.remindMe)
        let ok = await app.enableReminders()
        XCTAssertTrue(ok); XCTAssertTrue(app.settings.remindMe); XCTAssertFalse(granted.scheduled.isEmpty)

        let denied = ReminderTests.FakeCenter(); denied.allow = false
        let app2 = try makeApp(center: denied)
        let ok2 = await app2.enableReminders()
        XCTAssertFalse(ok2); XCTAssertFalse(app2.settings.remindMe); XCTAssertTrue(denied.scheduled.isEmpty)
    }

    func testTurningRemindersOffClearsThePlan() async throws {
        let center = ReminderTests.FakeCenter(); let app = try makeApp(center: center)
        _ = await app.enableReminders()
        app.disableReminders()
        XCTAssertFalse(app.settings.remindMe); XCTAssertTrue(center.scheduled.isEmpty)
    }

    func testRefreshingAfterAVisitReschedulesFromNow() async throws {
        let center = ReminderTests.FakeCenter(); let app = try makeApp(center: center)
        _ = await app.enableReminders()
        let before = center.scheduled.map(\.date)
        app.refreshReminders()
        XCTAssertEqual(center.scheduled.count, before.count)
    }

    // MARK: iCloud sync (Plus)
    func testBecomingASubscriberFlagsSyncAndAsksForARestart() throws {
        let app = try makeApp()
        XCTAssertFalse(app.settings.cloudSyncEnabled); XCTAssertFalse(app.syncNeedsRestart)
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        app.updateSyncFlag()
        XCTAssertTrue(app.settings.cloudSyncEnabled); XCTAssertTrue(app.syncNeedsRestart)
    }

    func testAlreadySyncingSubscriberNeedsNoRestart() throws {
        let app = try makeApp(launchedWithCloud: true)
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_monthly"]))
        app.updateSyncFlag()
        XCTAssertTrue(app.settings.cloudSyncEnabled); XCTAssertFalse(app.syncNeedsRestart)
    }

    func testALapsedSubscriptionStopsSyncingButKeepsEverythingLocal() throws {
        let app = try makeApp(launchedWithCloud: true)
        app.profile?.water = 7
        app.updateSyncFlag()                                           // not entitled any more
        XCTAssertFalse(app.settings.cloudSyncEnabled); XCTAssertTrue(app.syncNeedsRestart)
        XCTAssertEqual(app.profile?.water, 7)                          // nothing is deleted or reset
    }

    func testSyncIsNeverRequestedForFreePlayers() throws {
        let app = try makeApp()
        app.updateSyncFlag()
        XCTAssertFalse(app.settings.cloudSyncEnabled); XCTAssertFalse(app.syncNeedsRestart)
    }

    // MARK: review fixes
    func testRemindersKeepWorkingAfterARelaunch() throws {
        let center = ReminderTests.FakeCenter()
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-relaunch-\(UUID().uuidString)")!)
        settings.remindMe = true                                   // saved by an earlier launch
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, notifications: center)
        app.refreshReminders()
        XCTAssertFalse(center.scheduled.isEmpty, "the plan must be rebuilt without asking for permission again")
        XCTAssertEqual(center.asked, 0)
    }

    func testSyncFlagIsNotTouchedBeforeEntitlementsHaveLoaded() throws {
        let app = try makeApp(launchedWithCloud: true)
        app.settings.cloudSyncEnabled = true
        app.entitlements.debugSetLoaded(false)
        app.updateSyncFlag()
        XCTAssertTrue(app.settings.cloudSyncEnabled)               // a slow StoreKit start must not switch sync off
        XCTAssertFalse(app.syncNeedsRestart)
    }

    func testNoBannerUntilEntitlementsAreKnown() throws {
        let app = try makeApp()
        app.finishOnboarding(); app.settings.ageBand = .eighteenPlus; app.settings.completedSessions = 2
        XCTAssertTrue(app.showBanner)
        app.entitlements.debugSetLoaded(false)
        XCTAssertFalse(app.showBanner)                             // subscribers must never see a banner flash at launch
    }

    func testRewardedAdsNeverOfferedInTheFirstSession() throws {
        let app = try makeApp(); app.settings.ageBand = .eighteenPlus; app.settings.completedSessions = 0
        XCTAssertFalse(app.canOfferRewarded)
    }

    func testDailyBloomCanOnlyBePlayedOncePerDay() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let words = (0..<3).map { i in WordEntry(id: "d\(i)", word: ["SEED", "LEAF", "ROOT"][i], display: "x", hint: "h", hint2: nil, fact: "f", level: 1, kind: .vocab,
                                              plantId: nil, tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t") }
        let container = try SharedContainer.make(inMemory: true)
        let suite = UserDefaults(suiteName: "wf-daily-\(UUID().uuidString)")!
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: words, daily: DailyConfig(epoch: "2026-01-01", seed: 3))
        let app = AppModel(container: container, settings: AppSettings(defaults: suite), bank: bank, now: { clock }, notifications: ReminderTests.FakeCenter())
        app.game.startDaily()
        for ch in app.game.currentWord { app.game.guessInput = String(ch); app.game.submitGuess() }
        XCTAssertEqual(app.game.phase, .won)
        XCTAssertTrue(app.dailyBloomDoneToday)
        let water = app.profile?.water
        app.game.startDaily()
        XCTAssertNotEqual(app.game.phase, .playing)                // already done today: no replay for bonus rewards
        XCTAssertEqual(app.profile?.water, water)
        clock = clock.addingTimeInterval(86_400 + 60)
        XCTAssertFalse(app.dailyBloomDoneToday)
        app.game.startDaily(); XCTAssertEqual(app.game.phase, .playing)
    }

    func testSittingClockStartsAndResetsForBreakSuggestions() throws {
        var clock = Date(timeIntervalSince1970: 1_780_000_000)
        let app = try makeApp(now: { clock }); app.settings.ageBand = .under13
        app.beginSitting()
        clock = clock.addingTimeInterval(21 * 60)
        XCTAssertTrue(app.shouldSuggestBreak)
        app.markBreakSuggested()
        XCTAssertFalse(app.shouldSuggestBreak)
        app.settings.ageBand = .eighteenPlus; clock = clock.addingTimeInterval(3_600)
        XCTAssertFalse(app.shouldSuggestBreak)
    }
}


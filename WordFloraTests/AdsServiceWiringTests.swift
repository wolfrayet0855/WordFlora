import XCTest
import SwiftUI
import SwiftData
@testable import WordFlora

/// B1 (g4a brief section 5) and the service rulings: under 13, an unknown age and Plus never reach `prepare`, the
/// consent form or the tracking prompt from any entry point; 13 to 17 get the teen plan (tagged under the age of
/// consent, never a tracking prompt); cached ads are released when the treatment becomes none (H5); the perk paths
/// and counters through the model. The SDK is offline in every test: no real ad request is ever made.
@MainActor
final class AdsServiceWiringTests: XCTestCase {
    nonisolated private static let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!

    private func makeApp(_ band: AgeBand?, plus: Bool = false, sessions: Int = 9, entries: [WordEntry] = [],
                         now: @escaping () -> Date = { AdsServiceWiringTests.noon }) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-ads-\(UUID().uuidString)")!)
        settings.ageBand = band
        settings.onboardingComplete = true
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: entries, daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: now)
        app.settings.completedSessions = sessions
        app.profile?.roundsSinceAd = 9
        app.profile?.water = 0
        app.settings.wakeDreamsInARow = 1
        app.ads.offline = true                                    // never a real ad in tests
        app.adsEnabled = true
        if plus { app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"])) }
        return app
    }

    /// Every entry point that can lead to an ad.
    private func tapEverything(_ app: AppModel) async {
        await app.adBeforeNextRound()
        app.markRestExit()
        _ = await app.playTappedOnHome()
        await app.prepareBannerIfAllowed()
        _ = await app.watchRewardedAd()
        for perk in RewardedPerk.allCases { _ = await app.watchRewarded(perk) }
        app.ads.startIfConsentAlreadyResolved(treatment: app.adTreatment, isStillAllowed: { app.mayStillLoadAds })
    }

    func testUnderThirteenUnknownAndPlusNeverReachPrepareConsentOrTracking() async throws {
        let cases: [(AgeBand?, Bool)] = [(nil, false), (.under13, false), (.thirteenPlus, true), (.eighteenPlus, true)]
        for (band, plus) in cases {
            let app = try makeApp(band, plus: plus)
            await tapEverything(app)
            let label = "\(String(describing: band)) plus \(plus)"
            XCTAssertEqual(app.ads.prepareCount, 0, label)
            XCTAssertEqual(app.ads.consentRequestCount, 0, label)
            XCTAssertEqual(app.ads.consentFormCount, 0, label)
            XCTAssertEqual(app.ads.trackingRequestCount, 0, label)
            XCTAssertNil(app.ads.lastTreatment, label)
            XCTAssertFalse(app.ads.started, label)
            XCTAssertFalse(app.showBanner, label)
            XCTAssertFalse(app.canOfferRewarded, label)
            XCTAssertFalse(app.adWouldPlayOnOneMore, label)
            XCTAssertFalse(app.mayAskTracking, label)
            XCTAssertNil(app.profile?.lastAdAt, "no ad was counted for \(label)")
        }
    }

    func testTeensGetTheTeenPlanTaggedUnderTheAgeOfConsentAndNeverTheTrackingPrompt() async throws {
        let app = try makeApp(.thirteenPlus)
        XCTAssertTrue(app.showBanner)
        await app.prepareBannerIfAllowed()
        XCTAssertEqual(app.ads.prepareCount, 1)
        XCTAssertEqual(app.ads.lastTreatment, .teen)
        XCTAssertEqual(app.ads.lastPlan, [.configure(.teen), .consent(underAgeOfConsent: true), .start])
        XCTAssertFalse(app.ads.lastPlan.contains(.tracking))
        await tapEverything(app)
        XCTAssertEqual(app.ads.trackingRequestCount, 0)
        XCTAssertFalse(app.mayAskTracking)
    }

    func testAdultsGetConsentThenTracking() async throws {
        let app = try makeApp(.eighteenPlus)
        await app.prepareBannerIfAllowed()
        XCTAssertEqual(app.ads.lastTreatment, .adult)
        XCTAssertEqual(app.ads.lastPlan, [.configure(.adult), .consent(underAgeOfConsent: false), .tracking, .start])
        XCTAssertTrue(app.mayAskTracking)
        XCTAssertEqual(AdsService.plan(for: .none), [])
    }

    func testTheConsentAlreadyResolvedEntryNeverShowsTheForm() throws {
        let app = try makeApp(.eighteenPlus)
        XCTAssertFalse(app.ads.startIfConsentAlreadyResolved(treatment: .adult, isStillAllowed: { true }), "offline: never starts")
        XCTAssertEqual(app.ads.consentFormCount, 0)
        XCTAssertEqual(app.ads.consentRequestCount, 0)
        XCTAssertFalse(app.ads.startIfConsentAlreadyResolved(treatment: .none, isStillAllowed: { true }))
    }

    // MARK: H5

    func testCachedAdsAreReleasedWhenPlusGoesLive() throws {
        let app = try makeApp(.eighteenPlus)
        app.adTreatmentChanged()
        XCTAssertEqual(app.ads.releaseCount, 0)
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        app.updateSyncFlag()
        XCTAssertEqual(app.ads.releaseCount, 1)
        XCTAssertTrue(app.ads.suspended)
        XCTAssertFalse(app.showBanner)
        app.updateSyncFlag()
        XCTAssertEqual(app.ads.releaseCount, 1, "released once per change")
    }

    func testCachedAdsAreReleasedWhenTheAgeAnswerBecomesUnderThirteenAfterStart() async throws {
        let app = try makeApp(.eighteenPlus)
        await app.prepareBannerIfAllowed()
        app.adTreatmentChanged()
        app.settings.ageBand = .under13
        app.noteAdActive()
        XCTAssertEqual(app.ads.releaseCount, 1)
        XCTAssertTrue(app.ads.suspended)
        XCTAssertFalse(app.mayStillLoadAds)
        let shown = await app.ads.showInterstitial(isStillAllowed: { app.mayStillLoadAds })
        XCTAssertFalse(shown)
    }

    // MARK: Sheets (Plus flow review)

    func testOnlyOurOwnSwiftUISheetsMayHaveAnAdOnTop() {
        XCTAssertTrue(AdsService.isOwnSheet(UIHostingController(rootView: Text("wake"))))
        XCTAssertFalse(AdsService.isOwnSheet(UIViewController()))
        XCTAssertFalse(AdsService.isOwnSheet(UINavigationController()))
        let root = UIViewController()
        XCTAssertTrue(AdsService.anchor(from: root) === root, "nothing presented: present from the root")
    }

    func testNoAdOfAnyKindWhileThePlusPageIsUp() throws {
        let app = try makeApp(.eighteenPlus)
        XCTAssertTrue(app.showBanner)
        app.adOnPaywall = true
        XCTAssertFalse(app.showBanner)
        XCTAssertFalse(app.canOfferRewarded)
        XCTAssertEqual(app.decide(.interstitial(.oneMore)), .no(.paywall))
    }

    // MARK: Perks through the model

    func testFreePerksForChildrenAndPlusGrantWithoutAnyAd() async throws {
        for (band, plus) in [(AgeBand.under13, false), (.eighteenPlus, true)] {
            let app = try makeApp(band, plus: plus)
            XCTAssertEqual(app.perkPath(.water), .free)
            let granted = await app.watchRewarded(.water)
            XCTAssertTrue(granted)
            XCTAssertEqual(app.profile?.water, 2)
            XCTAssertEqual(app.adLedger.freeWater, 1)
            XCTAssertEqual(app.ads.prepareCount, 0)
            XCTAssertNil(app.profile?.lastAdAt, "a free perk is not an ad")
            let hint = await app.watchRewarded(.hint)
            XCTAssertTrue(hint)
            XCTAssertTrue(app.whisperBanked)
            XCTAssertEqual(app.perkPath(.hint), .hidden, "a banked whisper shows a line, not a button")
            app.spendWhisper()
            XCTAssertFalse(app.whisperBanked)
        }
    }

    func testTheWaterVideoRowHidesUnderTheDailyCapAndComesBackTomorrow() async throws {
        var clock = Self.noon
        let app = try makeApp(.eighteenPlus, now: { clock })
        for _ in 0..<3 { XCTAssertTrue(app.canOfferRewarded); app.grantRewardedDrops() }
        XCTAssertFalse(app.canOfferRewarded)
        clock = clock.addingTimeInterval(86_400)
        XCTAssertTrue(app.canOfferRewarded)
    }

    func testAFullScreenAdCountsEverywhere() throws {
        let app = try makeApp(.eighteenPlus)
        app.recordFullScreen(kind: .rewarded(.hint))
        XCTAssertEqual(app.profile?.rewardedToday, 1)
        XCTAssertEqual(app.profile?.adsToday, 0, "rewarded is not pushed")
        XCTAssertEqual(app.profile?.lastAdAt, Self.noon)
        XCTAssertEqual(app.adLedger.fullScreen, 1)
        XCTAssertEqual(app.adSession.rewardedShown, 1)
        app.recordFullScreen(kind: .interstitial(.oneMore))
        XCTAssertEqual(app.profile?.adsToday, 1)
        XCTAssertEqual(app.profile?.roundsSinceAd, 0)
        XCTAssertEqual(app.adSession.pushedShown, 1)
        XCTAssertEqual(app.adSession.fullScreenShown, 2)
        // The 600 s gap now holds the next interstitial, so the resting card's note is honest.
        XCTAssertFalse(app.adWouldPlayOnOneMore)
    }

    func testANewAdVisitAfterThirtyMinutesAway() throws {
        var clock = Self.noon
        let app = try makeApp(.eighteenPlus, now: { clock })
        app.recordFullScreen(kind: .interstitial(.oneMore))
        app.noteAdBackground()
        clock = clock.addingTimeInterval(29 * 60)
        app.noteAdActive()
        XCTAssertEqual(app.adSession.pushedShown, 1, "back within 30 min: the same visit")
        app.noteAdBackground()
        clock = clock.addingTimeInterval(31 * 60)
        app.noteAdActive()
        XCTAssertEqual(app.adSession.pushedShown, 0, "a new visit")
        XCTAssertEqual(app.adLedger.fullScreen, 1, "the day counts stay")
    }

    // MARK: R2 whisper in a round

    private func entry(_ word: String) -> WordEntry {
        WordEntry(id: "w-\(word)", word: word, display: word.capitalized, hint: "a hint", hint2: "second clue", fact: "a fact",
                  level: 1, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: true, source: "t", license: "t", reviewedBy: "t")
    }

    func testABankedWhisperIsTheFourthRungAndIsSpentOnce() async throws {
        let app = try makeApp(.under13)
        _ = await app.watchRewarded(.hint)
        XCTAssertTrue(app.whisperBanked)
        app.game.start(entry: entry("BANANAS"))
        XCTAssertTrue(app.game.whisperReady)
        for _ in 0..<3 { app.game.useHelp() }                         // hint2, vowel A, first letter B
        XCTAssertTrue(app.whisperBanked, "the three free rungs come first")
        app.game.useHelp()
        XCTAssertTrue(app.game.guessedLetters.contains("N"), "the most frequent unrevealed consonant")
        XCTAssertFalse(app.whisperBanked)
        XCTAssertFalse(app.game.whisperReady)
    }

    func testNoWhisperOnTheDailyBloom() async throws {
        let app = try makeApp(.under13, entries: [entry("BANANAS")])
        _ = await app.watchRewarded(.hint)
        app.game.startDaily()
        XCTAssertTrue(app.game.isDaily)
        XCTAssertEqual(app.game.phase, .playing)
        XCTAssertFalse(app.game.whisperReady, "the dot is hidden and the rung absent on the Daily Bloom")
        for _ in 0..<6 { app.game.useHelp() }
        XCTAssertTrue(app.whisperBanked, "the whisper stays banked for a garden word")
    }

    // MARK: R3

    func testAGentleWakeGrantsNoStickerBadgeWaterShedPointsOrSoil() throws {
        let app = try makeApp(.eighteenPlus)
        let plant = app.plants().first!
        plant.earnedCount = 1
        plant.lastLovedAt = Self.noon.addingTimeInterval(-90 * 86_400)
        let p = app.profile!
        let before = (p.water, p.soil, p.shedPoints, p.badgesJSON, p.albumJSON)
        app.gentleWake(plant)
        XCTAssertEqual(plant.lastLovedAt, Self.noon)
        XCTAssertEqual(app.settings.wakeDreamsInARow, 0)
        XCTAssertEqual(app.settings.lastWakeResult, .woke)
        XCTAssertEqual(p.water, before.0); XCTAssertEqual(p.soil, before.1); XCTAssertEqual(p.shedPoints, before.2)
        XCTAssertEqual(p.badgesJSON, before.3); XCTAssertEqual(p.albumJSON, before.4)
    }

    // MARK: No stored field

    /// The SwiftData schema's stored attributes equal the G3 list exactly (the one CloudKit deploy already happened).
    func testThePlayerProfileHasNoNewStoredField() throws {
        let g3: Set<String> = [
            "currentLevel", "plantsEarnedThisLevel", "roseOfJerichoCount", "gamesPlayed", "water", "soil", "lastTrickleAt",
            "widgetPlantID", "streak", "bestStreak", "streakFreezes", "lastPlayedDay", "seenIds", "earnedPotIds", "roundsSinceAd",
            "ageBand", "roseSeedProgress", "wordsTowardPlant", "lastRoundId", "gardenDays", "lastGraceDay", "shedPoints",
            "toolsJSON", "activeToolId", "badgesJSON", "albumJSON", "butterflyPlaysJSON", "glowLanterns", "lastAdAt", "adsToday",
            "adsDay", "rewardedToday", "rewardedDay", "weatherSeed", "weatherStartDay", "weatherHighWaterDay", "weatherShelterDay",
            "weatherRescuedDays", "weatherPuzzleDay", "weatherPuzzleCount", "wildWeather", "weatherGatedFromDay", "weatherSeenAt",
            "weatherKitAt", "crownSeenAt", "goldCrownSeenAt", "guideSeen", "questDay", "questProgress", "questDone", "createdAt",
        ]
        let entity = try XCTUnwrap(Schema([PlayerProfile.self]).entitiesByName["PlayerProfile"])
        XCTAssertEqual(Set(entity.attributes.map(\.name)), g3)
        XCTAssertTrue(entity.relationships.isEmpty)
    }

    // MARK: M1: consent declined

    func testAVideoRowHidesForTheVisitWhenTheSDKCannotStart() async throws {
        let app = try makeApp(.eighteenPlus)                    // offline: the SDK never starts, as after a declined consent
        XCTAssertEqual(app.perkPath(.water), .ad(.adult))
        let granted = await app.watchRewarded(.water)
        XCTAssertFalse(granted)
        XCTAssertEqual(app.perkPath(.water), .hidden, "no dead video row")
        XCTAssertFalse(app.canOfferRewarded)
        for (band, plus) in [(AgeBand.under13, false), (.eighteenPlus, true)] {
            let free = try makeApp(band, plus: plus)
            XCTAssertEqual(free.perkPath(.water), .free, "free rows are not on this path")
        }
    }

    // MARK: M2: only R3 may sit over our own sheet

    func testOnlyTheWakeVideoMayBePresentedOverOurOwnSheet() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let root = UIViewController(); window.rootViewController = root; window.makeKeyAndVisible()
        let sheet = UIHostingController(rootView: Text("wake"))
        root.present(sheet, animated: false)
        XCTAssertNil(AdsService.anchor(from: root), "an interstitial or water/hint video refuses any sheet")
        XCTAssertTrue(AdsService.anchor(from: root, allowOwnSheet: true) === sheet, "R3 presents over the wake sheet")
        sheet.dismiss(animated: false)
        let foreign = UIViewController()
        root.present(foreign, animated: false)
        XCTAssertNil(AdsService.anchor(from: root, allowOwnSheet: true), "never over someone else's sheet")
        foreign.dismiss(animated: false)
    }
}

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

    private func makeApp(_ band: AgeBand?, plus: Bool = false, sessions: Int = 9, now: @escaping () -> Date = { AdsServiceWiringTests.noon }) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-ads-\(UUID().uuidString)")!)
        settings.ageBand = band
        settings.onboardingComplete = true
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
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

    func testThePlayerProfileHasNoNewStoredField() throws {
        let names = Set(Mirror(reflecting: PlayerProfile()).children.compactMap(\.label).map { $0.hasPrefix("_") ? String($0.dropFirst()) : $0 })
        for ad in ["lastAdAt", "adsToday", "adsDay", "rewardedToday", "rewardedDay"] { XCTAssertTrue(names.contains(ad), ad) }
        for banned in ["adLedger", "whisperBanked", "appOpenToday", "adWater"] { XCTAssertFalse(names.contains(banned), banned) }
    }
}

import XCTest
import SwiftData
@testable import WordFlora

/// G4b service wiring (brief section 6, items 5 and 6; extends the B1 spy in AdsServiceWiringTests): the real callers
/// `showAppOpenIfEligible`, `loadNativeIfEligible` and `requestCollapsibleIfEligible` never reach the SDK, the consent
/// form or the tracking prompt for an unknown age, under 13 or Plus; teens get `.teen` and never the tracking prompt;
/// app open and native never ask for consent; H4 on a cold launch; and the counts each format records.
/// The SDK is offline or the Debug fake in every test: no real ad request is ever made.
@MainActor
final class AdFormatsWiringTests: XCTestCase {
    nonisolated private static let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!

    private static let settled = AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: true)

    /// A player away for five hours on their tenth visit, consent settled, nothing on screen: every G4b rule says yes
    /// for 13 and over without Plus.
    private func makeApp(_ band: AgeBand?, plus: Bool = false, fake: Bool = false, consent: AdConsentSnapshot = settled,
                         now: @escaping () -> Date = { AdFormatsWiringTests.noon }) throws -> AppModel {
        AdLinkLaunch.pending = false
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-formats-\(UUID().uuidString)")!)
        settings.ageBand = band
        settings.onboardingComplete = true
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: now)
        app.settings.completedSessions = 10
        app.adsEnabled = true
        app.ads.offline = !fake
        #if DEBUG
        app.ads.fake = fake
        #endif
        app.adFormats.linkSettle = 0
        app.adFormats.consentOverride = consent
        app.adFormats.sheetOverride = false
        app.adFormats.assistiveOverride = false
        var l = app.adLedger
        l.lastBackgroundAt = Self.noon.addingTimeInterval(-5 * 3600)
        app.adLedger = l
        if plus { app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"])) }
        return app
    }

    private func assertNeverReachedTheSDK(_ app: AppModel, _ label: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(app.ads.prepareCount, 0, label, file: file, line: line)
        XCTAssertEqual(app.ads.consentRequestCount, 0, label, file: file, line: line)
        XCTAssertEqual(app.ads.consentFormCount, 0, label, file: file, line: line)
        XCTAssertEqual(app.ads.trackingRequestCount, 0, label, file: file, line: line)
        XCTAssertNil(app.ads.lastTreatment, label, file: file, line: line)
        XCTAssertFalse(app.ads.started, label, file: file, line: line)
        XCTAssertEqual(app.adFormats.cueShownCount, 0, label, file: file, line: line)
        XCTAssertEqual(app.adFormats.appOpenLoadCount, 0, label, file: file, line: line)
        XCTAssertEqual(app.adFormats.nativeLoadCount, 0, label, file: file, line: line)
    }

    // MARK: 5. Never for under 13, unknown age, or Plus

    func testUnderThirteenUnknownAndPlusNeverReachTheSDKFromAnyG4bCaller() async throws {
        for (band, plus) in [(AgeBand?.none, false), (.under13, false), (.thirteenPlus, true), (.eighteenPlus, true)] {
            for fake in [false, true] {
                let label = "\(String(describing: band)) plus \(plus) fake \(fake)"
                let app = try makeApp(band, plus: plus, fake: fake)
                let outcome = await app.showAppOpenIfEligible()
                XCTAssertEqual(outcome, .noCue(.ageOrPlus), label)
                _ = await app.loadNativeIfEligible()
                XCTAssertFalse(app.requestCollapsibleIfEligible(accessibilityTextSize: false), label)
                XCTAssertFalse(app.shedShowsSponsored(reduceMotion: false), label)
                app.refreshAdConsent()
                XCTAssertFalse(app.adSession.consentResolved, label)
                XCTAssertEqual(app.adLedger.nativeLoads, 0, label)
                assertNeverReachedTheSDK(app, label)
            }
        }
    }

    func testTeensGetTheTeenTreatmentAndNeverTheTrackingPrompt() async throws {
        let app = try makeApp(.thirteenPlus, consent: AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: false))
        app.refreshAdConsent()
        XCTAssertTrue(app.adSession.attResolved, "teens are never asked, so tracking counts as answered")
        let outcome = await app.showAppOpenIfEligible()
        XCTAssertEqual(outcome, .lifted, "offline: the SDK cannot start, so the cue lifts")
        XCTAssertEqual(app.adFormats.cueShownCount, 1)
        XCTAssertEqual(app.ads.prepareCount, 1)
        XCTAssertEqual(app.ads.lastTreatment, .teen)
        _ = await app.loadNativeIfEligible()
        XCTAssertEqual(app.ads.lastTreatment, .teen)
        XCTAssertEqual(app.ads.trackingRequestCount, 0)
        XCTAssertEqual(app.ads.consentRequestCount, 0)
        XCTAssertEqual(app.ads.consentFormCount, 0)
        XCTAssertEqual(app.adFormats.cue, .hidden)
    }

    /// H1: with consent unsettled, app open and native never show the form; they simply do nothing.
    func testAppOpenAndNativeNeverAskForConsent() async throws {
        let app = try makeApp(.eighteenPlus, consent: AdConsentSnapshot())
        let outcome = await app.showAppOpenIfEligible()
        XCTAssertEqual(outcome, .noCue(.consentPending))
        let step = await app.loadNativeIfEligible()
        XCTAssertEqual(step, .nothing(.consentPending, dropCached: false))
        XCTAssertEqual(app.ads.consentRequestCount, 0)
        XCTAssertEqual(app.ads.consentFormCount, 0)
        XCTAssertEqual(app.ads.trackingRequestCount, 0)
        XCTAssertEqual(app.ads.prepareCount, 0)
        // An adult whose tracking answer is not known yet gets no cue either.
        let att = try makeApp(.eighteenPlus, consent: AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: false))
        let attOutcome = await att.showAppOpenIfEligible()
        XCTAssertEqual(attOutcome, .noCue(.consentPending))
        XCTAssertEqual(att.ads.trackingRequestCount, 0)
    }

    // MARK: 6. H4 on a cold launch

    func testAColdLaunchOnACachedTeenTreatmentLiftsTheCueWhenTheStoreSaysPlus() async throws {
        let app = try makeApp(.thirteenPlus, fake: true)
        var l = app.adLedger; l.lastTreatment = .teen; app.adLedger = l
        app.entitlements.debugSetLoaded(false)
        app.adFormats.budgetOverride = 3
        let check = Task { await app.showAppOpenIfEligible() }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(app.adFormats.cue, .showing, "the cue goes up from the cached treatment")
        XCTAssertEqual(app.adFormats.appOpenLoadCount, 0, "nothing loads before the store answers")
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        let outcome = await check.value
        XCTAssertEqual(outcome, .lifted)
        XCTAssertEqual(app.adFormats.cue, .hidden)
        XCTAssertEqual(app.adFormats.appOpenPresentCount, 0, "a Plus owner never sees an ad")
        XCTAssertEqual(app.adFormats.appOpenLoadCount, 0)
        XCTAssertEqual(app.ads.prepareCount, 0, "the SDK never starts for Plus")
        XCTAssertNil(app.profile?.lastAdAt)
        app.cacheAdTreatment()
        XCTAssertEqual(app.adLedger.lastTreatment, AdTreatment.none, "the next cold launch has no cue")
    }

    func testAColdLaunchWithACachedNoneOrNoCacheHasNoCue() async throws {
        for cached in [AdTreatment?.some(.none), nil] {
            let app = try makeApp(.eighteenPlus, fake: true)
            var l = app.adLedger; l.lastTreatment = cached; app.adLedger = l
            app.entitlements.debugSetLoaded(false)
            let outcome = await app.showAppOpenIfEligible()
            XCTAssertEqual(outcome, .noCue(.notLoaded), "\(String(describing: cached))")
            XCTAssertEqual(app.adFormats.cueShownCount, 0)
        }
    }

    func testAColdLaunchOnACachedTreatmentPresentsOnceTheStoreConfirms() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        var l = app.adLedger; l.lastTreatment = .adult; app.adLedger = l
        app.entitlements.debugSetLoaded(false)
        app.adFormats.presentOverride = { true }
        let check = Task { await app.showAppOpenIfEligible() }
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(app.adFormats.appOpenPresentCount, 0)
        app.entitlements.debugSetLoaded(true)
        let outcome = await check.value
        XCTAssertEqual(outcome, .shown)
        XCTAssertEqual(app.adFormats.appOpenPresentCount, 1)
    }

    // MARK: Recording, Skip, links

    func testAShownAppOpenAdIsRecordedOnceAndTheSecondOfTheDayIsNot() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        app.adFormats.presentOverride = { true }
        let first = await app.showAppOpenIfEligible()
        XCTAssertEqual(first, .shown)
        XCTAssertEqual(app.adLedger.appOpen, 1)
        XCTAssertEqual(app.adLedger.fullScreen, 1)
        XCTAssertEqual(app.adLedger.lastFullScreenAt, Self.noon)
        XCTAssertEqual(app.profile?.adsToday, 1, "app open is a pushed ad")
        XCTAssertEqual(app.profile?.lastAdAt, Self.noon)
        XCTAssertEqual(app.adSession.pushedShown, 1)
        XCTAssertEqual(app.adFormats.cue, .hidden, "the cue fades to the screen the player left")
        let second = await app.showAppOpenIfEligible()
        XCTAssertEqual(second, .noCue(.formatCap))
        XCTAssertEqual(app.adLedger.appOpen, 1)
    }

    func testSkipCancelsTheLoadAndRecordsNothing() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        #if DEBUG
        app.adFormats.fakeAppOpenNeverArrives = true
        #endif
        app.adFormats.budgetOverride = 5
        let check = Task { await app.showAppOpenIfEligible() }
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(app.adFormats.cue, .showing)
        app.adFormats.skip()
        let outcome = await check.value
        XCTAssertEqual(outcome, .skipped)
        XCTAssertEqual(app.adFormats.cue, .hidden)
        XCTAssertEqual(app.adLedger.appOpen, 0)
        XCTAssertNil(app.profile?.lastAdAt)
        XCTAssertEqual(app.adFormats.appOpenPresentCount, 0)
    }

    func testTheBudgetLiftsTheCueWithNothingRecorded() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        #if DEBUG
        app.adFormats.fakeAppOpenNeverArrives = true
        #endif
        app.adFormats.budgetOverride = 0.3
        let outcome = await app.showAppOpenIfEligible()
        XCTAssertEqual(outcome, .lifted)
        XCTAssertEqual(app.adFormats.cue, .hidden)
        XCTAssertEqual(app.adLedger.appOpen, 0)
        XCTAssertGreaterThan(app.adFormats.appOpenReleaseCount, 0, "the pending load is released")
    }

    /// H3: a link, the widget, a notification or a shortcut that lands during the wait means no cue.
    func testALinkLaunchHasNoCue() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        app.adFormats.linkSettle = 0.2
        let check = Task { await app.showAppOpenIfEligible() }
        try await Task.sleep(nanoseconds: 50_000_000)
        AdLinkLaunch.mark()                                    // the URL arrives after the scene became active
        let outcome = await check.value
        XCTAssertEqual(outcome, .noCue(.link))
        XCTAssertEqual(app.adFormats.cueShownCount, 0)
        app.adFormatsSceneBackground()
        XCTAssertFalse(AdLinkLaunch.pending, "the flag ends with the activation")
        XCTAssertFalse(app.adSession.launchedFromLink)
    }

    func testNoCueOverThePuzzleThePlusPageOrASheet() async throws {
        for route in [GameRoute.game(daily: true, level: nil), .butterfly, .plus, .seasons] {
            let app = try makeApp(.eighteenPlus, fake: true)
            let outcome = await app.showAppOpenIfEligible(route: { route })
            XCTAssertNotEqual(outcome, .shown, "\(route)")
            XCTAssertEqual(app.adFormats.cueShownCount, 0, "\(route)")
        }
        let sheet = try makeApp(.eighteenPlus, fake: true)
        sheet.adFormats.sheetOverride = true
        let outcome = await sheet.showAppOpenIfEligible(route: { .garden })
        XCTAssertEqual(outcome, .noCue(.sheetUp))
        for flag in ["calm", "quiet"] {
            let app = try makeApp(.eighteenPlus, fake: true)
            if flag == "calm" { app.settings.calmMode = true } else { app.settings.quietGarden = true }
            let o = await app.showAppOpenIfEligible()
            XCTAssertEqual(app.adFormats.cueShownCount, 0, flag)
            XCTAssertNotEqual(o, .shown, flag)
        }
    }

    func testTheBackgroundCachesTheConfirmedTreatment() throws {
        let app = try makeApp(.eighteenPlus)
        app.adFormatsSceneBackground()
        XCTAssertEqual(app.adLedger.lastTreatment, .adult)
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        app.adFormatsSceneBackground()
        XCTAssertEqual(app.adLedger.lastTreatment, AdTreatment.none)
        let unsure = try makeApp(.eighteenPlus)
        unsure.entitlements.debugSetLoaded(false)
        unsure.adFormatsSceneBackground()
        XCTAssertNil(unsure.adLedger.lastTreatment, "never cached before the store answers")
    }

    // MARK: Native through the model

    func testTheShedCardLoadsOnceIsReusedForThirtyMinutesThenLoadsAgain() async throws {
        var clock = Self.noon
        let app = try makeApp(.eighteenPlus, fake: true, now: { clock })
        let first = await app.loadNativeIfEligible()
        XCTAssertEqual(first, .load(.adult))
        XCTAssertEqual(app.adFormats.nativeLoadCount, 1)
        XCTAssertEqual(app.adLedger.nativeLoads, 1)
        XCTAssertEqual(app.adLedger.lastNativeLoadAt, Self.noon)
        XCTAssertTrue(app.shedShowsSponsored(reduceMotion: false))
        clock = clock.addingTimeInterval(29 * 60)
        let again = await app.loadNativeIfEligible()
        XCTAssertEqual(again, .show)
        XCTAssertEqual(app.adFormats.nativeLoadCount, 1, "reused")
        clock = clock.addingTimeInterval(2 * 60)
        XCTAssertFalse(app.shedShowsSponsored(reduceMotion: false), "30 min old: dropped")
        let third = await app.loadNativeIfEligible()
        XCTAssertEqual(third, .load(.adult))
        XCTAssertEqual(app.adLedger.nativeLoads, 2)
        XCTAssertEqual(app.ads.consentRequestCount, 0)
        XCTAssertEqual(app.ads.trackingRequestCount, 0)
    }

    func testAVideoCardIsDroppedInCalmAndNotRetriedThisVisit() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        #if DEBUG
        app.adFormats.fakeNativeVideo = true
        #endif
        app.settings.calmMode = true
        let step = await app.loadNativeIfEligible()
        XCTAssertEqual(step, .nothing(.calm, dropCached: true))
        XCTAssertFalse(app.shedShowsSponsored(reduceMotion: false))
        let retry = await app.loadNativeIfEligible()
        XCTAssertEqual(retry, .nothing(.calm, dropCached: false))
        XCTAssertEqual(app.adFormats.nativeLoadCount, 1, "not retried this visit")
        let motion = try makeApp(.eighteenPlus, fake: true)
        #if DEBUG
        motion.adFormats.fakeNativeVideo = true
        #endif
        let m = await motion.loadNativeIfEligible(reduceMotion: true)
        XCTAssertEqual(m, .nothing(.calm, dropCached: true))
    }

    /// H5: Plus going live drops the cached card and the section disappears (header too).
    func testPlusGoingLiveReleasesTheCard() async throws {
        let app = try makeApp(.eighteenPlus, fake: true)
        _ = await app.loadNativeIfEligible()
        XCTAssertTrue(app.shedShowsSponsored(reduceMotion: false))
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        XCTAssertFalse(app.shedShowsSponsored(reduceMotion: false))
        app.adFormatsTreatmentCheck()
        XCTAssertEqual(app.adFormats.nativeReleaseCount, 1)
        XCTAssertNil(app.adFormats.nativeContent)
    }

    // MARK: Collapsible through the model

    func testTheCollapsibleRequestIsOncePerVisitCountedOnlyWhenCollapsibleAndTwiceADay() throws {
        var clock = Self.noon
        let app = try makeApp(.eighteenPlus, now: { clock })
        XCTAssertTrue(app.requestCollapsibleIfEligible(accessibilityTextSize: false))
        XCTAssertFalse(app.requestCollapsibleIfEligible(accessibilityTextSize: false), "no second request this visit")
        app.noteGardenBannerReceived(isCollapsible: false)
        XCTAssertEqual(app.adSession.collapsibleShown, 0, "a plain ad is not counted")
        app.noteGardenBannerReceived(isCollapsible: true)
        XCTAssertEqual(app.adSession.collapsibleShown, 1)
        XCTAssertEqual(app.adLedger.collapsible, 1)
        for _ in 0..<2 {
            app.noteAdBackground()
            clock = clock.addingTimeInterval(31 * 60)
            app.noteAdActive()                                      // a new ad visit
            if app.adLedger.collapsible < 2 {
                XCTAssertTrue(app.requestCollapsibleIfEligible(accessibilityTextSize: false))
                app.noteGardenBannerReceived(isCollapsible: true)
            } else {
                XCTAssertFalse(app.requestCollapsibleIfEligible(accessibilityTextSize: false), "third in the day")
            }
        }
        XCTAssertEqual(app.adLedger.collapsible, 2)
        XCTAssertEqual(app.ads.prepareCount, 0, "the collapsible decision never starts the SDK itself")
    }

    func testAssistiveTechAndAccessibilitySizesGetThePlainBanner() throws {
        let ax = try makeApp(.eighteenPlus)
        XCTAssertFalse(ax.requestCollapsibleIfEligible(accessibilityTextSize: true))
        XCTAssertTrue(ax.decide(.banner(.garden)).isYes)
        let vo = try makeApp(.eighteenPlus)
        vo.adFormats.assistiveOverride = true
        XCTAssertFalse(vo.requestCollapsibleIfEligible(accessibilityTextSize: false))
        XCTAssertTrue(vo.decide(.banner(.garden)).isYes)
        let early = try makeApp(.eighteenPlus)
        early.settings.completedSessions = 2
        XCTAssertFalse(early.requestCollapsibleIfEligible(accessibilityTextSize: false))
    }

    // MARK: Consent answers

    func testConsentAnswersAreWiredFromTheConsentSDKAndTheTrackingStatus() throws {
        let adult = try makeApp(.eighteenPlus, consent: AdConsentSnapshot(consentResolved: true, canRequestAds: true, trackingResolved: false))
        adult.refreshAdConsent()
        XCTAssertTrue(adult.adSession.consentResolved)
        XCTAssertFalse(adult.adSession.attResolved)
        adult.adFormats.consentOverride = Self.settled
        adult.refreshAdConsent()
        XCTAssertTrue(adult.adSession.attResolved)
        let young = try makeApp(.under13)
        young.refreshAdConsent()
        XCTAssertFalse(young.adSession.consentResolved)
        XCTAssertEqual(young.adFormats.consentSnapshot(for: young.adTreatment, ads: young.ads), AdConsentSnapshot(),
                       "nothing is read for under 13, even with an override")
    }
}

import XCTest
import SwiftData
@testable import WordFlora

final class PlusOfferPolicyTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    let day: TimeInterval = 86_400

    /// A free adult who just reached their first level-up: the offer is allowed.
    func ready(_ now: Date? = nil) -> PlusOfferPolicy.Context {
        var c = PlusOfferPolicy.Context(now: now ?? t0)
        c.ageBand = .eighteenPlus; c.currentLevel = 2; c.plantsEarned = 3
        return c
    }

    func testFreeAdultAfterFirstLevelUpIsOffered() {
        XCTAssertEqual(PlusOfferPolicy.milestoneToOffer(ready()), .firstLevelUp)
        var teen = ready(); teen.ageBand = .thirteenPlus
        XCTAssertEqual(PlusOfferPolicy.milestoneToOffer(teen), .firstLevelUp)
    }

    func testNeverForUnderThirteenOrUnknownAge() {
        var c = ready(); c.ageBand = .under13
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
        c.ageBand = nil
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
    }

    func testNeverForSubscribersOrBeforeEntitlementsLoad() {
        var c = ready(); c.hasPlus = true
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
        c = ready(); c.entitlementsLoaded = false
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
    }

    func testNeedsAMilestone() {
        var c = ready(); c.currentLevel = 1; c.plantsEarned = 9
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
        c.plantsEarned = 10
        XCTAssertEqual(PlusOfferPolicy.milestoneToOffer(c), .tenPlants)
        c.plantsEarned = 25
        XCTAssertEqual(PlusOfferPolicy.milestoneToOffer(c), .twentyFivePlants)
    }

    func testNeverInTheSameSessionAsAnAd() {
        var c = ready(); c.adShownThisSession = true
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
    }

    func testNeverRightAfterARest() {
        var c = ready(); c.lastRoundWasRest = true
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
    }

    func testNeverInQuietGarden() {
        var c = ready(); c.quietGarden = true
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
    }

    func testAtMostOncePerMilestone() {
        var c = ready(t0.addingTimeInterval(100 * day)); c.offered = [.firstLevelUp]; c.lastOfferAt = t0
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
        c.plantsEarned = 10
        XCTAssertEqual(PlusOfferPolicy.milestoneToOffer(c), .tenPlants)
    }

    func testAtMostOnceEveryThirtyDays() {
        var c = ready(t0.addingTimeInterval(29 * day)); c.plantsEarned = 10; c.offered = [.firstLevelUp]; c.lastOfferAt = t0
        XCTAssertNil(PlusOfferPolicy.milestoneToOffer(c))
        c.now = t0.addingTimeInterval(30 * day)
        XCTAssertEqual(PlusOfferPolicy.milestoneToOffer(c), .tenPlants)
    }

    func testCopyIsCalmAndTruthful() {
        let all = [PlusOfferPolicy.Copy.headline, PlusOfferPolicy.Copy.detail, PlusOfferPolicy.Copy.button]
        for line in all { XCTAssertTrue(CopySafety.check(line).isEmpty, line) }
        XCTAssertEqual(PlusOfferPolicy.Copy.headline, "Keep your garden safe and in sync on all your devices")
        XCTAssertTrue(PlusOfferPolicy.Copy.detail.contains("already saved on this phone"))
        XCTAssertTrue(PlusOfferPolicy.Copy.detail.contains("across your devices"))
    }
}

@MainActor
final class PlusOfferAppTests: XCTestCase {
    func makeApp(suite: UserDefaults, now: @escaping () -> Date) throws -> AppModel {
        let settings = AppSettings(defaults: suite)
        settings.ageBand = .eighteenPlus; settings.onboardingComplete = true
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: try SharedContainer.make(inMemory: true), settings: settings, bank: bank, now: now,
                           notifications: ReminderTests.FakeCenter())
        app.profile?.currentLevel = 2
        return app
    }

    func testOfferShowsOnceAndDismissalIsRemembered() throws {
        let suite = UserDefaults(suiteName: "wf-plus-\(UUID().uuidString)")!
        var clock = Date(timeIntervalSince1970: 1_800_000_000)
        let app = try makeApp(suite: suite, now: { clock })
        app.checkPlusOffer()
        XCTAssertEqual(app.plusOffer, .firstLevelUp)
        app.dismissPlusOffer()
        XCTAssertNil(app.plusOffer)
        app.checkPlusOffer()
        XCTAssertNil(app.plusOffer)

        clock = clock.addingTimeInterval(90 * 86_400)
        let next = try makeApp(suite: suite, now: { clock })     // a later session, same saved settings
        next.checkPlusOffer()
        XCTAssertNil(next.plusOffer)
    }

    func testAnAdThisSessionBlocksTheOffer() throws {
        let suite = UserDefaults(suiteName: "wf-plus-\(UUID().uuidString)")!
        let app = try makeApp(suite: suite, now: { Date(timeIntervalSince1970: 1_800_000_000) })
        app.recordAdShown()
        app.checkPlusOffer()
        XCTAssertNil(app.plusOffer)
    }

    func testSwitchedOffForUITests() throws {
        let suite = UserDefaults(suiteName: "wf-plus-\(UUID().uuidString)")!
        let app = try makeApp(suite: suite, now: { Date(timeIntervalSince1970: 1_800_000_000) })
        app.plusOfferEnabled = false
        app.checkPlusOffer()
        XCTAssertNil(app.plusOffer)
    }
}

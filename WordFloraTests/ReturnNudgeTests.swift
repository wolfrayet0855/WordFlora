import XCTest
import SwiftData
@testable import WordFlora

/// Coming back to play soon after "That's enough for now" (docs/pm/ad-gate-return-nudge.md): within 3 minutes a free
/// adult may see an ad on their own Play tap (every AdGate rule still applies); everyone else gets the gentle nudge card.
final class ReturnNudgeRuleTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    /// Noon in the current time zone on t0's day, so the night rule never interferes unless a test asks for it.
    var noon: Date { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: t0)! }

    /// A free adult past the grace period, three words since the last ad, back `after` seconds after "That's enough".
    func ctx(after seconds: Double = 60, _ edit: (inout AdGate.ReturnContext) -> Void = { _ in }) -> AdGate.ReturnContext {
        var ad = AdGate.Context(now: noon)
        ad.roundsSinceAd = 3; ad.completedSessions = 3
        var r = AdGate.ReturnContext(now: noon, enoughAt: noon.addingTimeInterval(-seconds), ad: ad)
        edit(&r)
        return r
    }

    func visit(_ r: AdGate.ReturnContext) -> AdGate.ReturnVisit { AdGate.returnVisit(r) }

    // MARK: the 3 minute window

    func testTheWindowIsThreeMinutes() { XCTAssertEqual(AdGate.returnWindowSeconds, 180) }

    func testRightAwayAndUpToJustUnderThreeMinutesIsInTheWindow() {
        for s in [0.0, 1, 60, 179, 179.9] { XCTAssertEqual(visit(ctx(after: s)), .adMayPlay, "\(s) s") }
    }

    func testThreeMinutesOrMoreIsAnOrdinaryPlay() {
        for s in [180.0, 181, 600, 86_400] { XCTAssertEqual(visit(ctx(after: s)), .free, "\(s) s") }
    }

    func testWithoutThatsEnoughItIsAnOrdinaryPlay() {
        XCTAssertEqual(visit(ctx { $0.enoughAt = nil }), .free)
    }

    func testAClockThatWentBackIsAnOrdinaryPlay() {
        XCTAssertEqual(visit(ctx(after: -30)), .free)
    }

    func testOutsideTheWindowNobodyIsNudged() {
        XCTAssertEqual(visit(ctx(after: 200) { $0.calmMode = true }), .free)
        XCTAssertEqual(visit(ctx(after: 200) { $0.ad.hasRemoveAds = true }), .free)
    }

    // MARK: who gets the nudge instead of an ad

    func testPlusGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.hasRemoveAds = true }), .nudge) }
    func testUnderThirteenGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.isUnderThirteen = true }), .nudge) }
    func testCalmModeGetsTheNudgeNeverAnAd() { XCTAssertEqual(visit(ctx { $0.calmMode = true }), .nudge) }
    func testQuietGardenGetsTheNudgeNeverAnAd() { XCTAssertEqual(visit(ctx { $0.quietGarden = true }), .nudge) }
    func testAdsUnavailableGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.adsAvailable = false }), .nudge) }
    func testDailyCapReachedGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.adsToday = $0.ad.maxPerDay }), .nudge) }
    func testTooSoonAfterTheLastAdGetsTheNudge() {
        XCTAssertEqual(visit(ctx { $0.ad.lastAdAt = $0.now.addingTimeInterval(-60) }), .nudge)
    }
    func testFewerThanThreeWordsSinceTheLastAdGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.roundsSinceAd = 2 }), .nudge) }
    func testAfterTheDailyBloomGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.aroundDailyBloom = true }), .nudge) }
    func testAfterALossGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.lastRoundWasLoss = true }), .nudge) }
    func testTheFirstSessionGetsTheNudge() {
        XCTAssertEqual(visit(ctx { $0.ad.completedSessions = 0; $0.ad.wordLevelUps = 1 }), .nudge)
    }
    func testTheGracePeriodGetsTheNudge() { XCTAssertEqual(visit(ctx { $0.ad.completedSessions = 2 }), .nudge) }
    func testRightAfterACelebrationGetsTheNudge() {
        XCTAssertEqual(visit(ctx { $0.ad.lastPeakAt = $0.now.addingTimeInterval(-1) }), .nudge)
    }

    func testCalmOrQuietNeverGetAnAdEvenWhenEveryAdRulePasses() {
        for (calm, quiet) in [(true, false), (false, true), (true, true)] {
            XCTAssertEqual(visit(ctx { $0.calmMode = calm; $0.quietGarden = quiet }), .nudge)
        }
    }

    func testEveryCombinationOfTheOffSwitchesGetsTheNudgeInTheWindow() {
        let bools = [false, true]
        for plus in bools { for young in bools { for calm in bools { for quiet in bools { for available in bools {
            let r = ctx {
                $0.ad.hasRemoveAds = plus; $0.ad.isUnderThirteen = young
                $0.calmMode = calm; $0.quietGarden = quiet; $0.adsAvailable = available
            }
            let anyOff = plus || young || calm || quiet || !available
            XCTAssertEqual(visit(r), anyOff ? .nudge : .adMayPlay, "plus \(plus) young \(young) calm \(calm) quiet \(quiet) available \(available)")
        } } } } }
    }

    // MARK: night

    func testNightIsNinePmToEightAm() {
        let cal = Calendar.current
        func at(_ h: Int, _ m: Int = 0) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: t0)! }
        for h in [21, 22, 23, 0, 3, 7] { XCTAssertTrue(AdGate.isNight(at(h)), "\(h):00") }
        XCTAssertTrue(AdGate.isNight(at(7, 59)))
        for h in [8, 12, 15, 20] { XCTAssertFalse(AdGate.isNight(at(h)), "\(h):00") }
        XCTAssertFalse(AdGate.isNight(at(20, 59)))
    }

    func testAReturnAtNightGetsTheNudgeNotAnAd() {
        let late = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: t0)!
        let r = ctx {
            $0.now = late; $0.enoughAt = late.addingTimeInterval(-60); $0.ad.now = late
            $0.ad.isNight = AdGate.isNight(late)
        }
        XCTAssertEqual(visit(r), .nudge)
    }

    /// "One more" on the resting card keeps the same quiet hours as reminders: no interstitial from 9 pm to 8 am.
    func testOneMoreNeverPlaysAnAdAtNight() {
        var c = AdGate.Context(now: noon)
        c.roundsSinceAd = 3; c.completedSessions = 3; c.choice = .oneMore
        XCTAssertTrue(AdGate.shouldShowInterstitial(c), "by day every rule passes")
        c.isNight = true
        XCTAssertFalse(AdGate.shouldShowInterstitial(c), "at night One more never plays an ad")
    }

    // MARK: the existing "One more" rule is unchanged

    func testOneMoreKeepsItsRulesAndIgnoresTheReturnWindow() {
        var c = AdGate.Context(now: noon)
        c.roundsSinceAd = 3; c.completedSessions = 3; c.choice = .oneMore
        XCTAssertTrue(AdGate.shouldShowInterstitial(c))
        c.choice = .thatsEnough
        XCTAssertFalse(AdGate.shouldShowInterstitial(c), "never on the exit itself")
        c.choice = .playSoonAfterEnough
        XCTAssertTrue(AdGate.shouldShowInterstitial(c))
        c.isNight = true
        XCTAssertFalse(AdGate.shouldShowInterstitial(c), "a return at night never plays an ad")
    }
}

/// The app side: the exit is remembered, Home's Play judges the window, and the ad only follows the player's tap.
@MainActor
final class ReturnNudgeAppTests: XCTestCase {
    private func entry(_ id: String, _ word: String) -> WordEntry {
        WordEntry(id: id, word: word, display: word.capitalized, hint: "a hint", hint2: nil, fact: "a fact",
                  level: 1, kind: .vocab, plantId: nil, tags: [], minAge: 6,
                  dailyEligible: true, source: "original", license: "proprietary", reviewedBy: "t")
    }

    private var clock = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!

    /// A free adult past the grace period with three words since the last ad, after a won word.
    private func makeApp(ageBand: AgeBand? = .eighteenPlus) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-nudge-\(UUID().uuidString)")!)
        settings.ageBand = ageBand
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [entry("a", "LOTUS")], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: { [unowned self] in self.clock })
        app.settings.completedSessions = 3
        app.game.start(entry: entry("a", "LOTUS"))
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.profile?.roundsSinceAd = 3
        app.ads.offline = true                          // never a real ad in tests
        return app
    }

    func testNothingChangesWithoutThatsEnough() throws {
        let app = try makeApp()
        XCTAssertEqual(app.returnVisit, .free)
    }

    func testAFreeAdultBackWithinThreeMinutesIsToldAnAdMayPlay() throws {
        let app = try makeApp()
        app.markRestExit()
        clock += 120
        XCTAssertEqual(app.returnVisit, .adMayPlay)
        clock += 61
        XCTAssertEqual(app.returnVisit, .free, "after 3 minutes Play is ordinary again")
    }

    func testTheExitItselfNeverPlaysAnAd() throws {
        let app = try makeApp()
        app.markRestExit()
        XCTAssertNil(app.profile?.lastAdAt)
        XCTAssertEqual(app.profile?.roundsSinceAd, 3, "nothing is counted on the exit")
    }

    func testCalmQuietPlusAndYoungPlayersAreNudged() throws {
        let calm = try makeApp(); calm.settings.calmMode = true
        let quiet = try makeApp(); quiet.settings.quietGarden = true
        let plus = try makeApp(); plus.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        let young = try makeApp(ageBand: .under13)
        let off = try makeApp(); off.adsEnabled = false
        for (name, app) in [("calm", calm), ("quiet", quiet), ("plus", plus), ("under 13", young), ("ads off", off)] {
            app.markRestExit()
            XCTAssertEqual(app.returnVisit, .nudge, name)
        }
    }

    func testTheNudgeIsShownOnceThenPlayIsOrdinary() async throws {
        let app = try makeApp(); app.settings.calmMode = true
        app.markRestExit()
        let start = await app.playTappedOnHome()
        XCTAssertFalse(start, "the nudge card shows instead of starting at once")
        XCTAssertEqual(app.returnVisit, .free, "one nudge per exit")
        let again = await app.playTappedOnHome()
        XCTAssertTrue(again)
    }

    func testAnAdThatCannotPlayBringsTheNudgeNotAWait() async throws {
        let app = try makeApp()                         // ads offline: the ad cannot load
        app.markRestExit()
        XCTAssertEqual(app.returnVisit, .adMayPlay)
        let start = await app.playTappedOnHome()
        XCTAssertFalse(start, "no ad could play, so the nudge card shows")
        XCTAssertNil(app.profile?.lastAdAt, "no ad was counted")
    }

    func testNoAdWithoutTheNoteOnPlay() async throws {
        let app = try makeApp()
        app.markRestExit()
        XCTAssertEqual(app.returnVisit, .adMayPlay)
        let start = await app.playTappedOnHome(adNoteShown: false)
        XCTAssertFalse(start, "no ad without saying so first: the nudge instead")
        XCTAssertNil(app.profile?.lastAdAt)
    }

    func testTheNoteRightAfterTheLastWordHoldsForTheTap() throws {
        let app = try makeApp()
        app.markPeakDismissed()                         // the last word's celebration closed just now
        app.markRestExit()
        XCTAssertEqual(app.returnVisit, .adMayPlay, "judged as of the player's earliest tap, as on the resting card")
    }

    func testOutsideTheWindowPlayStartsAtOnce() async throws {
        let app = try makeApp()
        app.markRestExit()
        clock += 200
        let start = await app.playTappedOnHome()
        XCTAssertTrue(start)
    }

    func testAReturnAfterTheDailyBloomIsNudged() throws {
        let app = try makeApp()
        app.game.startDaily()
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
        app.markRestExit()
        XCTAssertEqual(app.returnVisit, .nudge)
    }

    func testAReturnAtNightIsNudged() throws {
        let app = try makeApp()
        clock = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: clock)!
        app.markRestExit()
        XCTAssertEqual(app.returnVisit, .nudge)
    }

    // MARK: copy

    func testEveryNudgeLineIsGentle() {
        for line in NudgeCardCopy.allLines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertLessThanOrEqual(line.split(separator: " ").count, 12, "short lines: \(line)")
        }
        XCTAssertEqual(NudgeCardCopy.title, "Your garden would love a visit")
        XCTAssertEqual(NudgeCardCopy.visit, "Visit my garden")
        XCTAssertEqual(NudgeCardCopy.puzzle, "Try a puzzle")
        XCTAssertEqual(NudgeCardCopy.playAnyway, "Play anyway")
        XCTAssertEqual(NudgeCardCopy.adNote, RestCardCopy.adNote, "the same honest line as the rest card")
    }

    func testTheNudgeNeverTalksAboutAdsTimersOrPlus() {
        for line in NudgeCardCopy.allLines where line != NudgeCardCopy.adNote {
            for word in ["ad", "ads", "timer", "wait", "minute", "minutes", "plus", "price", "buy"] {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in \(line)")
            }
        }
    }

    func testThePuzzleIsTheDailyBloomUntilItIsDoneThenTheButterflies() {
        XCTAssertEqual(NudgeCardCopy.puzzleTarget(dailyBloomOpen: true, dailyDone: false, butterflyOpen: true), .dailyBloom)
        XCTAssertEqual(NudgeCardCopy.puzzleTarget(dailyBloomOpen: true, dailyDone: true, butterflyOpen: true), .butterfly)
        XCTAssertEqual(NudgeCardCopy.puzzleTarget(dailyBloomOpen: false, dailyDone: false, butterflyOpen: true), .butterfly)
        XCTAssertNil(NudgeCardCopy.puzzleTarget(dailyBloomOpen: true, dailyDone: true, butterflyOpen: false))
        XCTAssertNil(NudgeCardCopy.puzzleTarget(dailyBloomOpen: false, dailyDone: false, butterflyOpen: false))
    }
}

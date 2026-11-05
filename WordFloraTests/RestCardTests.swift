import XCTest
import SwiftData
@testable import WordFlora

/// The resting card and the under-13 break card: reward line, the honest ad note, and copy safety.
@MainActor
final class RestCardTests: XCTestCase {
    private func entry(_ id: String, _ word: String) -> WordEntry {
        WordEntry(id: id, word: word, display: word.capitalized, hint: "a hint", hint2: nil, fact: "a fact",
                  level: 1, kind: .vocab, plantId: nil, tags: [], minAge: 6,
                  dailyEligible: true, source: "original", license: "proprietary", reviewedBy: "t")
    }

    /// A free adult player past the grace period with three rounds since the last ad: every AdGate rule passes.
    /// Noon local time: the night rule (no ad 9 pm to 8 am) never decides these tests unless one asks for it.
    nonisolated private static let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_780_000_000))!

    private func makeApp(ageBand: AgeBand? = .eighteenPlus, sessions: Int = 3, roundsSinceAd: Int = 3,
                         now: @escaping () -> Date = { RestCardTests.noon }) throws -> AppModel {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-rest-\(UUID().uuidString)")!)
        settings.ageBand = ageBand
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [entry("a", "LOTUS")], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, now: now)
        app.settings.completedSessions = sessions
        app.profile?.roundsSinceAd = roundsSinceAd
        return app
    }

    private func win(_ app: AppModel) {
        for ch in "LOTUS" { app.game.guessInput = String(ch); app.game.submitGuess() }
    }

    // MARK: reward line

    func testRewardLineCountsWordsAndSaysOneWordInTheSingular() {
        XCTAssertEqual(RestCardCopy.reward(isDaily: false, wordsPlayed: 1), "You played 1 word")
        XCTAssertEqual(RestCardCopy.reward(isDaily: false, wordsPlayed: 3), "You played 3 words")
        XCTAssertEqual(RestCardCopy.reward(isDaily: false, wordsPlayed: 6), "You played 6 words")
    }

    func testRewardLineAfterTheDailyBloomNamesIt() {
        XCTAssertEqual(RestCardCopy.reward(isDaily: true, wordsPlayed: 0), "Daily Bloom done")
        XCTAssertEqual(RestCardCopy.reward(isDaily: true, wordsPlayed: 4), "Daily Bloom done")
    }

    func testRoundsThisSittingCountsRegularRoundsOnly() throws {
        let app = try makeApp()
        XCTAssertEqual(app.game.roundsThisSitting, 0)
        for _ in 1...3 { app.game.start(entry: entry("a", "LOTUS")); win(app) }
        XCTAssertEqual(app.game.roundsThisSitting, 3)
        XCTAssertTrue(app.game.sessionBeat)
        app.game.startTutorial(entry: entry("a", "LOTUS")); win(app)
        XCTAssertEqual(app.game.roundsThisSitting, 3, "the first-session word is not counted")
    }

    // MARK: ad note

    func testAdNoteShowsWhenEveryAdRuleSaysYes() throws {
        let app = try makeApp()
        app.game.start(entry: entry("a", "LOTUS")); win(app)
        XCTAssertTrue(app.adWouldPlayOnOneMore)
    }

    func testAdNoteJudgesTheTapAfterTheCelebrationNotTheMomentItCloses() throws {
        let app = try makeApp()
        app.game.start(entry: entry("a", "LOTUS")); win(app)
        app.markPeakDismissed()                   // the card opens as the win card is dismissed
        XCTAssertTrue(app.adWouldPlayOnOneMore)
    }

    func testNoAdNoteForPlus() throws {
        let app = try makeApp()
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        app.game.start(entry: entry("a", "LOTUS")); win(app)
        XCTAssertFalse(app.adWouldPlayOnOneMore)
    }

    func testNoAdNoteUnderThirteenOrWithAnUnknownAge() throws {
        for band in [AgeBand.under13, nil] {
            let app = try makeApp(ageBand: band)
            app.game.start(entry: entry("a", "LOTUS")); win(app)
            XCTAssertFalse(app.adWouldPlayOnOneMore, "\(String(describing: band))")
        }
    }

    func testNoAdNoteRightAfterTheDailyBloom() throws {
        let app = try makeApp()
        app.game.startDaily()
        XCTAssertTrue(app.game.isDaily)
        win(app)
        XCTAssertFalse(app.adWouldPlayOnOneMore)
    }

    func testNoAdNoteWhenTheRulesSayNotYet() throws {
        let early = try makeApp(sessions: 1)                        // grace period
        early.game.start(entry: entry("a", "LOTUS")); win(early)
        XCTAssertFalse(early.adWouldPlayOnOneMore)
        let soon = try makeApp(roundsSinceAd: 2)                    // fewer than three rounds since the last ad
        soon.game.start(entry: entry("a", "LOTUS")); win(soon)
        // The win above added one round, so check before it would count.
        soon.profile?.roundsSinceAd = 2
        XCTAssertFalse(soon.adWouldPlayOnOneMore)
    }

    /// The reminders' quiet hours: no interstitial on "One more" from 9 pm to 8 am, so no note either.
    func testNoAdOnOneMoreAtNight() throws {
        let cal = Calendar.current
        for hour in [21, 23, 0, 5, 7] {
            let t = cal.date(bySettingHour: hour, minute: 30, second: 0, of: Self.noon)!
            let app = try makeApp(now: { t })
            app.game.start(entry: entry("a", "LOTUS")); win(app)
            XCTAssertTrue(app.adContext(choice: .oneMore).isNight, "\(hour):30")
            XCTAssertFalse(app.adWouldPlayOnOneMore, "\(hour):30")
        }
        for hour in [8, 13, 20] {
            let t = cal.date(bySettingHour: hour, minute: 30, second: 0, of: Self.noon)!
            let app = try makeApp(now: { t })
            app.game.start(entry: entry("a", "LOTUS")); win(app)
            XCTAssertTrue(app.adWouldPlayOnOneMore, "\(hour):30 is day")
        }
    }

    func testNoAdNoteWhenAdsAreSwitchedOff() throws {
        let app = try makeApp()
        app.adsEnabled = false
        app.game.start(entry: entry("a", "LOTUS")); win(app)
        XCTAssertFalse(app.adWouldPlayOnOneMore)
    }

    // MARK: copy

    func testEveryRestAndBreakCardLineIsGentle() {
        for line in RestCardCopy.allLines {
            XCTAssertEqual(CopySafety.check(line), [], line)
        }
        for n in 0...12 { XCTAssertEqual(CopySafety.check(RestCardCopy.reward(isDaily: false, wordsPlayed: n)), []) }
    }
}

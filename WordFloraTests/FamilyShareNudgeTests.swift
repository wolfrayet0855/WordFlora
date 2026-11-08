import XCTest
@testable import WordFlora

/// The Family Sharing note: the Restore line for 13+ (today's rule), the grown-ups' note for under 13 and unknown
/// age (Settings "For grown-ups" only, at most one day a week), never for Plus owners or in Quiet Garden.
final class FamilyShareNudgeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/New_York")!; return c }

    /// 13 and up see no family line anywhere: the one Restore purchases is in WordFlora Settings (owner, 2026-11-07).
    func testTeensAndAdultsSeeNoFamilyLine() {
        for band: AgeBand in [.thirteenPlus, .eighteenPlus] {
            for placement in [FamilyShareNudge.Placement.settings, .plusPage] {
                XCTAssertEqual(FamilyShareNudge.audience(ageBand: band, hasPlus: false, quietGarden: false, placement: placement,
                                                         lastGrownUpShownAt: nil, now: now, calendar: cal), .none)
            }
        }
    }

    /// One row per age band and situation: who sees which note, where.
    func testAudienceTablePerAgeBand() {
        typealias A = FamilyShareNudge.Audience
        struct Row { var band: AgeBand?; var plus: Bool; var quiet: Bool; var settings: A; var plusPage: A }
        let rows: [Row] = [
            // 13 and up: nothing (the Restore line is retired).
            Row(band: .eighteenPlus, plus: false, quiet: false, settings: .none, plusPage: .none),
            Row(band: .thirteenPlus, plus: false, quiet: false, settings: .none, plusPage: .none),
            Row(band: .eighteenPlus, plus: true, quiet: false, settings: .none, plusPage: .none),
            Row(band: .thirteenPlus, plus: false, quiet: true, settings: .none, plusPage: .none),
            // Under 13 and unknown age: the grown-ups' note, Settings only (the For grown-ups section).
            Row(band: .under13, plus: false, quiet: false, settings: .grownUp, plusPage: .none),
            Row(band: nil, plus: false, quiet: false, settings: .grownUp, plusPage: .none),
            Row(band: .under13, plus: true, quiet: false, settings: .none, plusPage: .none),
            Row(band: nil, plus: true, quiet: false, settings: .none, plusPage: .none),
            Row(band: .under13, plus: false, quiet: true, settings: .none, plusPage: .none),
            Row(band: nil, plus: false, quiet: true, settings: .none, plusPage: .none),
        ]
        for r in rows {
            for (placement, want) in [(FamilyShareNudge.Placement.settings, r.settings), (.plusPage, r.plusPage)] {
                let got = FamilyShareNudge.audience(ageBand: r.band, hasPlus: r.plus, quietGarden: r.quiet, placement: placement,
                                                    lastGrownUpShownAt: nil, now: now, calendar: cal)
                XCTAssertEqual(got, want, "\(String(describing: r.band)) plus \(r.plus) quiet \(r.quiet) \(placement)")
            }
        }
        XCTAssertEqual(ParentalGate.isRequired(ageBand: .under13), true, "the grown-ups' note always sits behind the gate")
        XCTAssertEqual(ParentalGate.isRequired(ageBand: nil), true)
    }

    /// At most one day a week for the grown-ups' note; 13 and up ignore the gap (today's behaviour).
    func testGrownUpNoteAtMostOnceAWeek() {
        let day: TimeInterval = 86_400
        let cases: [(TimeInterval?, Bool)] = [
            (nil, true),                // never shown
            (-60, true),                // earlier the same day: stays while Settings is open
            (-1 * day, false), (-3 * day, false), (-6 * day, false),
            (-7 * day, true), (-30 * day, true),
        ]
        for band: AgeBand? in [.under13, nil] {
            for (ago, shown) in cases {
                let last = ago.map { now.addingTimeInterval($0) }
                let got = FamilyShareNudge.audience(ageBand: band, hasPlus: false, quietGarden: false, placement: .settings,
                                                    lastGrownUpShownAt: last, now: now, calendar: cal)
                XCTAssertEqual(got, shown ? .grownUp : .none, "\(String(describing: band)) shown \(String(describing: ago))")
            }
        }
        for band: AgeBand in [.thirteenPlus, .eighteenPlus] {
            XCTAssertEqual(FamilyShareNudge.audience(ageBand: band, hasPlus: false, quietGarden: false, placement: .settings,
                                                     lastGrownUpShownAt: now.addingTimeInterval(-day), now: now, calendar: cal), .none)
        }
    }

    /// The week is counted in calendar days, so a daylight saving change does not move it.
    func testGrownUpGapAcrossDaylightSaving() {
        // 2026-11-01 is the US fall-back day; shown at 9:00 on Oct 29, due again at 0:30 on Nov 5 (a 7 day gap).
        let shown = cal.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 9))!
        let sixDays = cal.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 23, minute: 30))!
        let sevenDays = cal.date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 0, minute: 30))!
        XCTAssertFalse(FamilyShareNudge.grownUpDue(lastShownAt: shown, now: sixDays, calendar: cal))
        XCTAssertTrue(FamilyShareNudge.grownUpDue(lastShownAt: shown, now: sevenDays, calendar: cal))
    }

    func testCopyIsCalmAndForGrownUps() {
        for line in FamilyShareNudge.Copy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        XCTAssertEqual(FamilyShareNudge.Copy.all, [FamilyShareNudge.Copy.grownUpLine, FamilyShareNudge.Copy.grownUpButton])
        let grownUp = FamilyShareNudge.Copy.grownUpLine + " " + FamilyShareNudge.Copy.grownUpButton
        XCTAssertTrue(FamilyShareNudge.Copy.grownUpLine.contains("Grown-ups:"), "addressed to the grown-up")
        // No pressure or "ask your parents" lines, no countdowns, no prices.
        for word in ["ask your", "parents", "today", "now", "hurry", "$", "free", "!"] {
            XCTAssertFalse(grownUp.lowercased().contains(word), word)
        }
    }
}

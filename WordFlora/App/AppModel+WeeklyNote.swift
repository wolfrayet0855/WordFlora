import Foundation
import SwiftData

/// The weekly garden note (WeeklyNote): read from stored rounds, plants and the album; no model field. The week seen is
/// `AppSettings.weeklyNoteSeenWeek` (device-local UserDefaults).
extension AppModel {
    func weeklyNoteContext(otherCardShowing: Bool, nudgeShowing: Bool = false) -> WeeklyNote.Context {
        let p = profile
        return WeeklyNote.Context(now: now(), calendar: WeeklyNote.calendar(),
                                  onboarded: settings.onboardingComplete || (p?.guideSeen ?? false) || settings.completedSessions > 0,
                                  gardenCreatedAt: p?.createdAt ?? now(), seenWeek: settings.weeklyNoteSeenWeek,
                                  otherCardShowing: otherCardShowing, nudgeShowing: nudgeShowing, quietGarden: settings.quietGarden)
    }

    /// The past week's summary, from the stored rounds and the album.
    func weeklySummary(calendar: Calendar = WeeklyNote.calendar()) -> WeeklyNote.Summary {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>(predicate: #Predicate { $0.won }))) ?? []
        let rounds = records.map { WeeklyNote.Round(date: $0.date, won: $0.won, isDaily: $0.isDaily, plantEarned: $0.plantEarned) }
        return WeeklyNote.summary(rounds: rounds, friendsSeenAt: album.seenAt, now: now(), calendar: calendar)
    }

    /// Called as Home appears. Returns the note to show and records its week at once (shown at most once a week), or nil.
    /// A weather card, weather banner or welcome card holds it for a later Home visit the same week.
    func takeWeeklyNote(otherCardShowing: Bool, nudgeShowing: Bool = false) -> WeeklyNote.Summary? {
        let c = weeklyNoteContext(otherCardShowing: otherCardShowing, nudgeShowing: nudgeShowing)
        guard WeeklyNote.mayShow(c) else { return nil }
        let summary = weeklySummary(calendar: c.calendar)
        guard WeeklyNote.shouldShow(c, summary: summary) else { return nil }
        markWeeklyNoteSeen(summary.weekKey)
        return summary
    }

    func markWeeklyNoteSeen(_ weekKey: Int) { settings.weeklyNoteSeenWeek = weekKey }

    /// "Share my week": 13 and up, never in Quiet Garden.
    var canShareWeek: Bool { WeeklyNote.shareAllowed(ageBand: settings.ageBand, quietGarden: settings.quietGarden) }
}

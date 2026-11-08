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
        let records = (try? context.fetch(FetchDescriptor<GameRecord>(predicate: #Predicate { $0.won == true }))) ?? []
        let rounds = records.map { WeeklyNote.Round(date: $0.date, won: $0.won, isDaily: $0.isDaily, plantEarned: $0.plantEarned) }
        return WeeklyNote.summary(rounds: rounds, friendsSeenAt: album.seenAt, now: now(), calendar: calendar)
    }

    /// Called as Home appears with nothing pushed over it. Returns the note to show, or nil. It is not recorded here:
    /// the card records its week once it has been on screen (`markWeeklyNoteSeen`), so a launch that goes straight on to
    /// a plant (a widget tap) does not use up the week's note. A weather card, weather banner, welcome card or Plus card
    /// holds it for a later Home visit the same week.
    func dueWeeklyNote(otherCardShowing: Bool, nudgeShowing: Bool = false) -> WeeklyNote.Summary? {
        let c = weeklyNoteContext(otherCardShowing: otherCardShowing, nudgeShowing: nudgeShowing)
        guard WeeklyNote.mayShow(c) else { return nil }
        let summary = weeklySummary(calendar: c.calendar)
        return WeeklyNote.shouldShow(c, summary: summary) ? summary : nil
    }

    func markWeeklyNoteSeen(_ weekKey: Int) { settings.weeklyNoteSeenWeek = weekKey }

    /// The art for the note: the week's new plants' own images (in `newPlants` order), and for the Celebrate splash those
    /// or, in a week with no new plant, the player's grown plants (else the daisy). Always the app's plant artwork.
    func weeklyNoteArt(_ summary: WeeklyNote.Summary) -> (plants: [String], celebrate: [String]) {
        let all = plants()
        var byName: [String: String] = [:]
        for p in all where !p.imageName.isEmpty { byName[p.name] = byName[p.name] ?? p.imageName }
        let new = summary.newPlants.compactMap { byName[$0] }
        let grown = all.filter { $0.earnedCount > 0 && !$0.imageName.isEmpty }.map(\.imageName)
        let celebrate = !new.isEmpty ? new : (grown.isEmpty ? ["plant_daisy"] : Array(grown.suffix(3)))
        return (new, Array(celebrate.prefix(3)))
    }

    /// "Share my week": 13 and up, never in Quiet Garden.
    var canShareWeek: Bool { WeeklyNote.shareAllowed(ageBand: settings.ageBand, quietGarden: settings.quietGarden) }
}

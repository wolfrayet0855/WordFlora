import Foundation

/// A calm Family Sharing note, never on Home and never a popup.
/// - 13 and up without Plus: "Already have Plus on a family phone? Restore purchases." in Settings > WordFlora Plus
///   and on the Plus screen (owner approved for this release; unchanged).
/// - Under 13 and unknown age without Plus (owner, 2026-11-07): a note addressed to the grown-up, only inside the
///   "For grown-ups" section of Settings, on at most one day a week, off in Quiet Garden. Its one button asks the
///   grown-up question (`ParentalGate`) before the Plus page opens. No countdown, no pressure line for the child.
/// Plus owners and Quiet Garden see neither.
enum FamilyShareNudge {
    enum Audience: Equatable {
        case none
        /// 13 and up: the Restore line.
        case player
        /// Under 13 and unknown age: the grown-ups' note, behind the grown-up question.
        case grownUp
    }

    /// Where the row sits. The grown-ups' note lives only in the Settings "For grown-ups" section.
    enum Placement: Equatable { case settings, plusPage }

    /// The grown-ups' note shows on at most one day in seven.
    static let grownUpGapDays = 7

    static func audience(ageBand: AgeBand?, hasPlus: Bool, quietGarden: Bool, placement: Placement,
                         lastGrownUpShownAt: Date?, now: Date, calendar: Calendar = .current) -> Audience {
        guard !hasPlus, !quietGarden else { return .none }
        if ageBand == .thirteenPlus || ageBand == .eighteenPlus { return .player }
        guard placement == .settings else { return .none }
        return grownUpDue(lastShownAt: lastGrownUpShownAt, now: now, calendar: calendar) ? .grownUp : .none
    }

    /// Due when never shown, again on the same day it was shown (so it does not vanish while Settings is open), or
    /// once seven days have passed since that day.
    static func grownUpDue(lastShownAt: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        guard let last = lastShownAt else { return true }
        if calendar.isDate(last, inSameDayAs: now) { return true }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day ?? 0
        return days >= grownUpGapDays
    }

    /// The 13 and up Restore line (today's rule).
    static func isShown(ageBand: AgeBand?, hasPlus: Bool, quietGarden: Bool) -> Bool {
        audience(ageBand: ageBand, hasPlus: hasPlus, quietGarden: quietGarden, placement: .plusPage,
                 lastGrownUpShownAt: nil, now: .now) == .player
    }

    enum Copy {
        static let line = "Already have Plus on a family phone?"
        static let button = "Restore purchases"
        /// The grown-ups' note (under 13 and unknown age). Written to the grown-up, never to the child.
        static let grownUpLine = "Plus covers the whole family. Grown-ups: turn on Family Sharing in Apple Family settings and everyone in your family gets Plus, ads off, garden synced."
        static let grownUpButton = "About Plus for families"
        static var all: [String] { [line, button, grownUpLine, grownUpButton] }
    }
}

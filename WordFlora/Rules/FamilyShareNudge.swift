import Foundation

/// A calm Family Sharing note, never on Home and never a popup.
/// - Under 13 and unknown age without Plus (owner, 2026-11-07): a note addressed to the grown-up, only inside the
///   "Purchases" section of Settings, on at most one day a week, off in Quiet Garden. Its one button asks the
///   grown-up question (`ParentalGate`) before the Plus page opens. No countdown, no pressure line for the child.
/// - 13 and up: nothing. The Restore line it used to carry is retired (owner, 2026-11-07: one Restore purchases
///   in the whole app, in WordFlora Settings; docs/pm/plus-flow-fable-review.md N1). The benefits already say "Share it with your family".
/// Plus owners and Quiet Garden see nothing.
enum FamilyShareNudge {
    enum Audience: Equatable {
        case none
        /// Under 13 and unknown age: the grown-ups' note, behind the grown-up question.
        case grownUp
    }

    /// Where the row sits. The grown-ups' note lives only in the Settings "Purchases" section.
    enum Placement: Equatable { case settings, plusPage }

    /// The grown-ups' note shows on at most one day in seven.
    static let grownUpGapDays = 7

    static func audience(ageBand: AgeBand?, hasPlus: Bool, quietGarden: Bool, placement: Placement,
                         lastGrownUpShownAt: Date?, now: Date, calendar: Calendar = .current) -> Audience {
        guard !hasPlus, !quietGarden, ParentalGate.isRequired(ageBand: ageBand), placement == .settings else { return .none }
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

    enum Copy {
        /// The grown-ups' note (under 13 and unknown age). Written to the grown-up, never to the child.
        static let grownUpLine = "Plus covers the whole family. Grown-ups: turn on Family Sharing in Apple Family settings and everyone in your family gets Plus, ads off, garden synced."
        static let grownUpButton = "About Plus for families"
        static var all: [String] { [grownUpLine, grownUpButton] }
    }
}

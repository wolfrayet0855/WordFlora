import Foundation

/// A calm line for grown-ups who may already share Plus through Family Sharing (owner approved for this release).
/// Shown in Settings > WordFlora Plus and on the Plus screen only, never on Home; its button is the usual Restore.
/// Hidden under 13, for an unknown age, for Plus owners and in Quiet Garden, so kids never see it.
enum FamilyShareNudge {
    static func isShown(ageBand: AgeBand?, hasPlus: Bool, quietGarden: Bool) -> Bool {
        guard !hasPlus, !quietGarden, let ageBand else { return false }
        return ageBand == .thirteenPlus || ageBand == .eighteenPlus
    }

    enum Copy {
        static let line = "Already have Plus on a family phone?"
        static let button = "Restore purchases"
        static var all: [String] { [line, button] }
    }
}

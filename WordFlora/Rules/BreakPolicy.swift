import Foundation

/// Gentle break suggestion for young players (spec section 18, P12): after 20 minutes of continuous play, then at most
/// every 20 minutes. Never a countdown, never a lock.
enum BreakPolicy {
    static let interval: TimeInterval = 20 * 60
    static let message = "Time to look at something real: a window, a plant, a sky."

    static func shouldSuggest(isUnderThirteen: Bool, sittingStart: Date, now: Date, lastSuggestedAt: Date?) -> Bool {
        guard isUnderThirteen, now.timeIntervalSince(sittingStart) >= interval else { return false }
        if let last = lastSuggestedAt { return now.timeIntervalSince(last) >= interval }
        return true
    }
}

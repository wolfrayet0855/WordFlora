import Foundation

/// After a few days away the garden says everything is fine. No streak talk, no guilt (spec P-rules).
enum WelcomeBack {
    static let lines = [
        "It rained while you were away, and everything is fine.",
        "Your garden kept growing, slowly and happily.",
        "Welcome back. The flowers saved you a sunny spot."
    ]
    static func shouldShow(lastOpened: Date?, now: Date, calendar: Calendar) -> Bool {
        guard let last = lastOpened else { return false }
        let a = calendar.startOfDay(for: last), b = calendar.startOfDay(for: now)
        return (calendar.dateComponents([.day], from: a, to: b).day ?? 0) >= 3
    }
}

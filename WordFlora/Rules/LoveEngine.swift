import Foundation

/// Owner ruling (2026-11-03): a plant that gets no love for a day starts to lose petals in a gentle rain, one more each
/// day; with no petals left it shows as a seed in a pot. Nothing earned is ever removed: stage, growth and the collection
/// stay, and a seed wakes with a challenge. Quiet Garden and Calm mode are exempt. Love = a tap hello or any tending.
enum LoveEngine {
    static let maxPetals = 5

    struct State: Equatable { var petalsLeft: Int; var raining: Bool; var isSeed: Bool }

    static func state(lastLoved: Date?, now: Date, exempt: Bool) -> State {
        guard !exempt, let last = lastLoved, now > last else { return State(petalsLeft: maxPetals, raining: false, isSeed: false) }
        let days = Int(now.timeIntervalSince(last) / 86_400)
        let left = max(0, maxPetals - days)
        return State(petalsLeft: left, raining: days >= 1, isSeed: left == 0)
    }

    static func rainLine(name: String) -> String { "A little rain is falling. \(name) would love a hello." }
    static func seedLine(name: String) -> String { "\(name) is tucked in as a seed. Wake it with a challenge." }
    static func wakeLine(name: String) -> String { "\(name) is awake and growing again!" }
}

/// Rose of Jericho: fixed progress, no gamble (spec section 18, P9).
struct RoseMeter: Equatable {
    var progress = 0
    var stock = 0
    var lastRoundId: String?

    init(progress: Int = 0, stock: Int = 0, lastRoundId: String? = nil) {
        self.progress = progress; self.stock = stock; self.lastRoundId = lastRoundId
    }

    var isFull: Bool { stock >= Economy.default.roseCap }

    /// Returns true when a Rose arrived. Idempotent per round id; paused at the cap.
    @discardableResult
    mutating func recordRound(id: String, economy: Economy) -> Bool {
        guard id != lastRoundId else { return false }
        lastRoundId = id
        guard stock < economy.roseCap else { return false }
        progress += 1
        if progress >= economy.roseThreshold {
            progress = 0
            stock += 1
            return true
        }
        return false
    }

    mutating func grant(economy: Economy) { stock = min(economy.roseCap, stock + 1) }

    mutating func consume() -> Bool {
        guard stock > 0 else { return false }
        stock -= 1
        return true
    }
}

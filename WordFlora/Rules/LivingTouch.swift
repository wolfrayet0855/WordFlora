import Foundation

/// Living Touch (light): stroking the plant with a finger makes it lean with the finger, with a soft tap now and then,
/// and every third stroke is one hello (the same hello as a tap: PlantVoice line, love, hearts). Pure rules; the plant
/// page draws it. The petal row under the plant is not part of it (the petal notes live there).
enum LivingTouch {
    enum Motion: Equatable { case full, soft, still }

    /// The furthest the plant leans, in degrees (the tap hello sways to 7).
    static let maxLean = 8.0
    /// At most one soft haptic tap in this many seconds while the finger moves.
    static let hapticGap: TimeInterval = 0.3
    /// Strokes count toward a hello only while they come within this many seconds of each other.
    static let strokeWindow: TimeInterval = 4
    static let strokesPerHello = 3
    /// The least sideways travel (points) that counts as a stroke.
    static let minStroke: CGFloat = 20

    /// Reduce Motion (the system's or the app's switch): the plant holds still (strokes still count as hellos).
    /// Calm: a softer lean, half as far.
    static func motion(reduceMotion: Bool, appReduceMotion: Bool, calm: Bool) -> Motion {
        if reduceMotion || appReduceMotion { return .still }
        return calm ? .soft : .full
    }

    /// The lean for a finger moved `translationX` points across a plant `width` wide: half the plant's width is the
    /// full lean, either way.
    static func lean(translationX: CGFloat, width: CGFloat, motion: Motion) -> Double {
        guard width > 0, motion != .still else { return 0 }
        let f = max(-1, min(1, Double(translationX / (width / 2))))
        return f * maxLean * (motion == .soft ? 0.5 : 1)
    }

    static func mayTap(last: Date?, now: Date) -> Bool {
        guard let last else { return true }
        return now.timeIntervalSince(last) >= hapticGap - 0.001     // a hair of slack for clock rounding
    }

    /// A stroke is a sideways move long enough to mean it; a mostly up-and-down move is the page scrolling.
    static func isStroke(dx: CGFloat, dy: CGFloat) -> Bool { abs(dx) >= minStroke && abs(dx) > abs(dy) }

    struct Strokes: Equatable {
        private(set) var count = 0
        private(set) var last: Date?

        /// Records one stroke; true when it is the one that says hello (then it counts from one again).
        mutating func stroke(at now: Date) -> Bool {
            if let last, now.timeIntervalSince(last) > LivingTouch.strokeWindow { count = 0 }
            last = now
            count += 1
            guard count >= LivingTouch.strokesPerHello else { return false }
            count = 0
            return true
        }
    }
}

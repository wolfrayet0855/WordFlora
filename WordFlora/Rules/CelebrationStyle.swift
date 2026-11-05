import Foundation

/// The one place that decides how a celebration plays (docs/pm/celebrations-audit.md, mode table).
/// - Reduce Motion (the system switch or the in-app override) turns every level, the intro included, into the still arc.
/// - Calm mode, Quiet Garden and Low Power soften it: large and medium become the slow calm drift, a small puff gets
///   smaller and shorter, and a badge keeps its pop with the still arc around it.
/// Calm always means gentle, never nothing: a young player's first win still gets petals.
enum CelebrationStyle {
    static func resolve(requested: CelebrationLevel, reduceMotion: Bool, calm: Bool) -> CelebrationLevel {
        if reduceMotion { return .reduceMotion }
        guard calm else { return requested }
        switch requested {
        case .large, .medium, .calm: return .calm
        case .small, .smallCalm: return .smallCalm
        case .badge, .reduceMotion: return .reduceMotion
        case .intro: return .intro
        }
    }

    static func resolve(requested: CelebrationLevel, settings: AppSettings, systemReduceMotion: Bool, lowPower: Bool) -> CelebrationLevel {
        resolve(requested: requested,
                reduceMotion: systemReduceMotion || settings.reduceMotionOverride,
                calm: settings.calmMode || settings.quietGarden || lowPower)
    }

    /// Whether the badge art may pop (scale) in, or only fade in.
    static func badgePops(settings: AppSettings, systemReduceMotion: Bool) -> Bool {
        !(systemReduceMotion || settings.reduceMotionOverride)
    }

    /// Exactly one sound for a win: the biggest thing that happened.
    static func winSound(leveledUp: Bool, plantArrived: Bool) -> SoundEvent {
        leveledUp ? .levelUp : (plantArrived ? .earned : .word)
    }
}

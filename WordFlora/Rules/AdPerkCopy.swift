import Foundation

/// Every line of the rewarded perk rows and toasts (docs/pm/admob-full-spec.md section 2, with the rulings). Video
/// rows say "video" in the title; free rows never mention Plus to a child, and the Plus caption is for Plus only.
/// All lines pass `CopySafety` (no "empty", "waiting", "only", "last", "left"), so R1 says the can is dry and a banked
/// whisper is "ready" (lead ruling 2026-11-08).
enum AdPerkCopy {
    enum Water {
        static let dryCan = "Your watering can is dry."
        static let adTitle = "Watch a short video for 2 drops"
        static let freeTitle = "Fill from the rain barrel"
        static let toast = "2 drops are in your can"
    }

    enum Hint {
        static let adTitle = "Watch a short video for a hint"
        static let freeTitle = "Ask the garden for a hint"
        static let subtitle = "A whisper for your next word"
        static let banked = "A whisper is ready for your next garden word"
        /// VoiceOver hint on the Help button while a whisper is banked.
        static let helpHint = "A whisper is ready"
        static let toast = "A whisper is ready for your next word"
    }

    enum Wake {
        static let adTitle = "Wake with a short video"
        static let adSubtitle = "The two challenges stay free"
        static let freeTitle = "Wake gently"
        static let freeSubtitle = "Once a day, after one try"
        static func toast(name: String) -> String { "\(name) is awake" }
    }

    static let plusCaption = "Included with Plus"

    static let all: [String] = [
        Water.dryCan, Water.adTitle, Water.freeTitle, Water.toast,
        Hint.adTitle, Hint.freeTitle, Hint.subtitle, Hint.banked, Hint.helpHint, Hint.toast,
        Wake.adTitle, Wake.adSubtitle, Wake.freeTitle, Wake.freeSubtitle, Wake.toast(name: "Rose"),
        plusCaption,
    ]
}

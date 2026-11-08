import Foundation

/// Every line of the return cue, the Shed's sponsored card and the Garden banner's caption row (mockups
/// design-preview/admob/app-open-cue.svg and native-card.svg). Only players 13 and over without Plus ever see these,
/// but they still pass `CopySafety` like every other line (calm words, no urgency).
enum AdFormatCopy {
    enum Cue {
        static let title = "Welcome back"
        static let line = "to your garden"
        static let chip = "Ad"
        static let adLine = "A short ad, then your garden"
        static let skip = "Skip to my garden"
        /// VoiceOver reads the cue as one sentence pair, then the Skip button.
        static let voiceOver = "Welcome back to your garden. A short ad, then your garden."
    }

    enum Native {
        /// Shown in capitals by the section header; VoiceOver reads it as written here.
        static let header = "Sponsored"
        static let line = "Ads help keep WordFlora free."
        static let badge = "Ad"
        static let badgeLabel = "Advertisement"
        /// The card's group label starts with this.
        static let groupPrefix = "Advertisement."
        static func groupLabel(headline: String) -> String { headline.isEmpty ? groupPrefix : "\(groupPrefix) \(headline)" }
    }

    enum Banner {
        static let goAdFree = "Go ad-free"
        static let report = "Report an ad"
    }

    static let all: [String] = [
        Cue.title, Cue.line, Cue.chip, Cue.adLine, Cue.skip, Cue.voiceOver,
        Native.header, Native.header.uppercased(), Native.line, Native.badge, Native.badgeLabel, Native.groupPrefix,
        Native.groupLabel(headline: "A calm word game"),
        Banner.goAdFree, Banner.report,
    ]
}

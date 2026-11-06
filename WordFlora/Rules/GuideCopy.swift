import Foundation

/// Where the guide was opened from: the first session (after the age question) or Settings ("Show the guide again").
enum GuideMode: Equatable { case firstRun, replay }

/// Every word in the onboarding guide, mirrored from design-preview/onboarding-guide/copy.js (the single copy source;
/// GuideCopyTests compares the two). Positive only, grade 2-3, no locks, Plus, ads or prices; checked by CopySafety.
/// Deliberate difference from the mockup: level 3 is "Bloom", the app's name, not "Wildwood".
enum GuideCopy {
    enum UI {
        static let skip = "Skip"
        static let close = "Close"
        static let back = "Back"
        static let next = "Next"
        static let start = "Start playing"
        static let done = "Done"
        static let settingsHeader = "Help"
        static let settingsRow = "Show the guide again"
        static let skipHint = "Goes straight to your first word"
        static let closeHint = "Back to Settings"
        static let dotsLabel = "Guide"
        static let settingsFoot = "A quick tour of how to play and grow your garden."
        static func dots(_ n: Int, _ total: Int) -> String { "Page \(n) of \(total)" }
        static let all = [skip, close, back, next, start, done, settingsHeader, settingsRow, skipHint, closeHint, dotsLabel, settingsFoot, dots(1, 8)]
    }

    struct Page: Equatable {
        let id: String
        let title: String
        let lines: [String]
        /// Quiet Garden or Calm mode: plants never rain or nap, so the page says so.
        var linesQuiet: [String]? = nil
        /// VoiceOver reads the illustration as one image with this label.
        let art: String

        func lines(quiet: Bool) -> [String] { quiet ? (linesQuiet ?? lines) : lines }
    }

    private static let economy = Economy()

    static let pages: [Page] = [
        Page(id: "guess", title: "Guess the word",
             lines: ["Read the clue, then tap letters to fill in the word.",
                     "Your flower’s petals are your tries. Tap Help for a hint."],
             art: "A flower with 6 of 8 petals, the word D, A, blank, S, blank, and a Help button."),
        Page(id: "plants", title: "Three words, one plant",
             lines: ["Your first win brings your first plant.",
                     "After that, every \(economy.wordsPerPlant) words brings a new plant."],
             art: "Three words with check marks lead to a new daisy in a pot."),
        Page(id: "tend", title: "Help your plant grow",
             lines: ["Water, feed and sun help it grow a little each day.",
                     "Prune and repot to help it reach full bloom."],
             art: "A plant growing from tiny to full bloom, with water, feed, sun, prune and repot buttons."),
        Page(id: "love", title: "Hearts and hellos",
             lines: ["Say hello or care for your plant each day to fill its energy hearts.",
                     "After a few rainy days it naps as a seed. A fun challenge wakes it, and it keeps all it grew."],
             linesQuiet: ["Say hello or care for your plant each day to fill its energy hearts.",
                          "Your plant keeps all it grows, always."],
             art: "A plant with 4 of 5 energy hearts saying hello. Below, a seed napping in its pot wakes up as a sprout."),
        Page(id: "garden", title: "Your garden and friends",
             lines: ["Visit all your plants in the Garden.",
                     "Catch butterflies to meet visitors and earn points for Shed tools."],
             art: "Garden, Visitors and Shed, with a butterfly flying from Visitors to the Shed."),
        Page(id: "daily", title: "One word for everyone",
             lines: ["Daily Bloom is a new word each day.",
                     "Everyone who plays gets the same word that day."],
             art: "The Daily Bloom card with a sunflower and five mystery letters."),
        Page(id: "levels", title: "Five levels to explore",
             lines: ["Find \(economy.plantsPerLevel) plants in a level to open the next one.",
                     "Grow all \(economy.plantsPerLevel) to full bloom for a gold ring."],
             art: "A garden path with five levels: \(Art.levelList). The first has a gold ring."),
        Page(id: "peeks", title: "Coming soon in your garden",
             lines: ["Rare plants from far away, new pots and shiny badges.",
                     "They open up as your garden grows. Let’s play!"],
             art: "Sneak peeks: a rare plant, a starry pot and a badge, each with a Soon tag."),
    ]

    static func page(_ id: String) -> Page { pages.first { $0.id == id }! }

    /// The small words drawn inside the illustrations.
    enum Art {
        static let clue = "Clue"
        static let clueText = "A white flower with a sunny middle"
        static let help = "Help"
        static let petalsTries = "Petals = tries"
        static let sampleWords = ["DAISY", "CLOUD", "MAPLE"]
        static let newPlant = "New plant found!"
        static let stageNames = LifeStats.stageNames
        static let tendActions = ["Water", "Feed", "Sun", "Prune", "Repot"]
        static let hello = "Hello!"
        static let love = "Energy"
        static let naps = "Naps as a seed"
        static let wakes = "Wakes with a challenge"
        static let garden = "Garden"
        static let visitors = "Visitors"
        static let shed = "Shed"
        static let points = "+5 points"
        static let dailyTitle = "Daily Bloom"
        static let dailySub = "One word for everyone today"
        static let levelNames = LevelMapCopy.names
        static let youAreHere = "You are here"
        static let goldRing = "Gold ring = full bloom"
        static let opensNext = "\(Economy().plantsPerLevel) plants opens the next level"
        static let soon = "Soon"
        static let rarePlants = "Rare plants"
        static let pots = "Pots"
        static let badges = "Badges"
        static let level5 = "Level 5"

        static var levelList: String {
            levelNames.dropLast().joined(separator: ", ") + " and " + (levelNames.last ?? "")
        }
        static func levelLabel(_ i: Int) -> String { "\(i + 1). \(levelNames[i])" }

        static var all: [String] {
            [clue, clueText, help, petalsTries, newPlant, hello, love, naps, wakes, garden, visitors, shed, points,
             dailyTitle, dailySub, youAreHere, goldRing, opensNext, soon, rarePlants, pots, badges, level5, "word"]
                + sampleWords + stageNames + tendActions + levelNames + levelNames.indices.map(levelLabel)
        }
    }

    /// Everything a player can see or hear in the guide, for the copy tests.
    static var allStrings: [String] {
        UI.all + pages.flatMap { [$0.title, $0.art] + $0.lines + ($0.linesQuiet ?? []) } + Art.all
    }
}

/// The guide's pager: which page shows, and what Skip and Next say there. Pure, so the tests can walk it.
struct GuidePager: Equatable {
    let mode: GuideMode
    let count: Int
    private(set) var page = 0

    init(mode: GuideMode, count: Int = GuideCopy.pages.count) {
        self.mode = mode
        self.count = count
    }

    var isFirst: Bool { page == 0 }
    var isLast: Bool { page == count - 1 }
    var showsBack: Bool { !isFirst }
    /// On the last page the main button does the same job, so Skip steps aside (it keeps its place in the layout).
    var showsSkip: Bool { !isLast }
    var skipLabel: String { mode == .replay ? GuideCopy.UI.close : GuideCopy.UI.skip }
    var skipHint: String { mode == .replay ? GuideCopy.UI.closeHint : GuideCopy.UI.skipHint }
    var nextLabel: String { isLast ? (mode == .replay ? GuideCopy.UI.done : GuideCopy.UI.start) : GuideCopy.UI.next }
    var nextShowsChevron: Bool { !isLast }
    var dotsValue: String { GuideCopy.UI.dots(page + 1, count) }

    /// Moves on a page; returns true when Next was pressed on the last page (the guide is finished).
    @discardableResult
    mutating func next() -> Bool {
        if isLast { return true }
        page += 1
        return false
    }

    mutating func back() { page = max(0, page - 1) }
    mutating func go(to p: Int) { page = min(count - 1, max(0, p)) }
}

/// How the guide looks for this player (README "Motion"): Reduce Motion from the system or the in-app override, and
/// Calm mode, keep the art still; Calm and Quiet Garden use the quiet line on page 4; Quiet Garden shows no points.
enum GuideLook {
    static func still(systemReduceMotion: Bool, reduceMotionOverride: Bool, calm: Bool) -> Bool {
        systemReduceMotion || reduceMotionOverride || calm
    }
    static func quietCopy(calm: Bool, quiet: Bool) -> Bool { calm || quiet }
    static func showsPoints(quiet: Bool) -> Bool { !quiet }
}

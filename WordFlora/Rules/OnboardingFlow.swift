/// First-session script (spec section 19, P-03). Pure state machine; the UI drives it with events.
/// Order: intro -> age -> guide (8 skippable pages, design-preview/onboarding-guide) -> tutorial word -> first plant -> tip -> home.
enum AgeBand: String, Codable { case under13, thirteenPlus, eighteenPlus }

struct OnboardingFlow: Equatable {
    enum Step: Equatable { case intro, age, guide, tutorialWord, plantEarned, gardenTip, home }

    private(set) var step: Step = .intro
    private(set) var selectedAgeBand: AgeBand?
    private(set) var sessionIndex = 1

    var isComplete: Bool { step == .home }
    var isUnderThirteen: Bool { selectedAgeBand == .under13 }
    /// No paywall and no permission prompts in session one.
    var mayShowPaywall: Bool { isComplete && sessionIndex >= 2 }
    var mayRequestPermissions: Bool { isComplete && sessionIndex >= 2 }

    init() {}

    init(restoredComplete: Bool, ageBand: AgeBand?) {
        if restoredComplete { step = .home; sessionIndex = 2 }
        selectedAgeBand = ageBand
    }

    mutating func introFinished() { if step == .intro { step = .age } }
    /// The guide follows the age answer (which may turn on Quiet Garden and change page 4). A guide already seen on
    /// another device (synced `PlayerProfile.guideSeen`) goes straight to the first word; Settings can replay it.
    mutating func selectAge(_ band: AgeBand, guideSeen: Bool = false) {
        if step == .age { selectedAgeBand = band; step = guideSeen ? .tutorialWord : .guide }
    }
    /// Skip and Start playing both land here: skipping the guide still plays the tutorial word.
    mutating func guideFinished() { if step == .guide { step = .tutorialWord } }
    mutating func tutorialSolved() { if step == .tutorialWord { step = .plantEarned } }
    mutating func plantEarnedDismissed() { if step == .plantEarned { step = .gardenTip } }
    mutating func tipCompleted() { if step == .gardenTip { step = .home } }
    mutating func skip() { step = .home }
    mutating func startNextSession() { sessionIndex += 1 }
}

/// The words on the Quiet Garden offer (design-preview/quiet-garden), shown after "Under 13" on the age question.
/// Grade 2 reading, positive only, checked by CopySafety in tests. It says "no points or counting" rather than
/// "no timers": the one on-screen time bar (the butterfly game's) is hidden by Calm mode, not by Quiet Garden
/// (docs/pm/quiet-garden.md).
enum QuietGardenCopy {
    static let title = "Would you like a quiet garden?"
    /// What changes, then what stays, each with its picture (an SF Symbol).
    static let rows: [(symbol: String, text: String)] = [
        ("leaf.fill", "No points or counting. Just tending."),
        ("drop.fill", "Water and tools are always ready."),
        ("heart.fill", "You still guess words and grow plants."),
    ]
    static let yes = "Yes, keep it quiet"
    static let no = "No thanks, show everything"
    static let note = "You can change this any time in Settings."
    static let back = "Back"
    static let backHint = "Goes back to the age question."

    static var allStrings: [String] { [title] + rows.map(\.text) + [yes, no, note, back, backHint] }
}

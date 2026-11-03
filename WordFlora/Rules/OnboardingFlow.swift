/// First-session script (spec section 19, P-03). Pure state machine; the UI drives it with events.
enum AgeBand: String, Codable { case under13, thirteenPlus, eighteenPlus }

struct OnboardingFlow: Equatable {
    enum Step: Equatable { case intro, age, tutorialWord, plantEarned, gardenTip, home }

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
    mutating func selectAge(_ band: AgeBand) { if step == .age { selectedAgeBand = band; step = .tutorialWord } }
    mutating func tutorialSolved() { if step == .tutorialWord { step = .plantEarned } }
    mutating func plantEarnedDismissed() { if step == .plantEarned { step = .gardenTip } }
    mutating func tipCompleted() { if step == .gardenTip { step = .home } }
    mutating func skip() { step = .home }
    mutating func startNextSession() { sessionIndex += 1 }
}

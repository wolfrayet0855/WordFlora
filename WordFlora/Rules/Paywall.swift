import Foundation

/// WordFlora Plus: one subscription group, two plans, both unlock "no ads" and iCloud sync (spec section 13).
enum PlusPlan: CaseIterable {
    case yearly, monthly

    static let groupName = "WordFlora Plus"
    var productID: String { self == .yearly ? "plus_yearly" : "plus_monthly" }
    static var allProductIDs: Set<String> { Set(allCases.map(\.productID)) }
}

struct EntitlementState: Equatable {
    var activeProductIDs: Set<String> = []
    var hasPlus: Bool { !activeProductIDs.isDisjoint(with: PlusPlan.allProductIDs) }
    var hasRemoveAds: Bool { hasPlus }
    var hasCloudSync: Bool { hasPlus }
}

enum PaywallMath {
    static func savingsPercent(yearly: Double, monthly: Double) -> Int {
        guard yearly > 0, monthly > 0 else { return 0 }
        return Int(((1 - yearly / (monthly * 12)) * 100).rounded())
    }
    static func perMonth(yearly: Double) -> Double { (yearly / 12 * 100).rounded() / 100 }
}

/// Plain, honest subscription copy: price, renewal and how to cancel are always stated; trial wording only
/// for eligible people (spec sections 13, 18). No countdowns or pressure.
enum PaywallCopy {
    struct Copy: Equatable { var headline: String; var detail: String; var cta: String; var finePrint: String }

    static let benefits = ["No ads, ever", "Sync your garden with iCloud", "Share it with your family"]

    static func make(plan: PlusPlan, displayPrice: String, trialEligible: Bool) -> Copy {
        let renew = "Your subscription renews automatically until you cancel. Cancel anytime in Settings."
        switch plan {
        case .yearly:
            let trial = trialEligible
            return Copy(headline: "Yearly", detail: "Best value",
                        cta: trial ? "Start 3-day free trial" : "Subscribe",
                        finePrint: trial ? "3 days free, then \(displayPrice) per year. \(renew)" : "\(displayPrice) per year. \(renew)")
        case .monthly:
            return Copy(headline: "Monthly", detail: "Flexible", cta: "Subscribe", finePrint: "\(displayPrice) per month. \(renew)")
        }
    }
}

/// A grown-up check before any purchase or outbound link (web page, mail, subscription management) for young
/// players and unknown ages (spec sections 11, 13).
enum ParentalGate {
    struct Challenge: Equatable { var question: String; var answer: Int }

    enum Copy {
        static let title = "For grown-ups"
        static let prompt = "Please ask a grown-up to answer this before continuing."
        static let wrong = "Not quite. Try again."
    }

    /// What tapping a link that leaves the app does: open it straight away, or ask a grown-up first.
    enum Outbound: Equatable { case open(URL), askFirst(URL) }

    static func outbound(_ url: URL, ageBand: AgeBand?) -> Outbound {
        isRequired(ageBand: ageBand) ? .askFirst(url) : .open(url)
    }

    static func challenge(seed: UInt64) -> Challenge {
        var rng = SplitMix64(seed: seed)
        let a = 13 + Int(rng.next() % 7)      // 13...19
        let b = 8 + Int(rng.next() % 2)       // 8...9
        return Challenge(question: "What is \(a) × \(b)?", answer: a * b)
    }

    static func check(answer: String, against c: Challenge) -> Bool {
        Int(answer.trimmingCharacters(in: .whitespaces)) == c.answer
    }

    static func isRequired(ageBand: AgeBand?) -> Bool { ageBand == nil || ageBand == .under13 }
}

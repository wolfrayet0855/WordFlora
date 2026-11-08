import Foundation

/// WordFlora Plus: one subscription group, two plans, both unlock "no ads" and iCloud sync (spec section 13).
enum PlusPlan: CaseIterable {
    case yearly, monthly

    static let groupName = "WordFlora Plus"
    var productID: String { self == .yearly ? "plus_yearly" : "plus_monthly" }
    static var allProductIDs: Set<String> { Set(allCases.map(\.productID)) }

    /// Plus Forever: one non-consumable, Family Sharing on. Kept apart from the subscription plans so the trial and
    /// renewal copy never touches it.
    static let lifetimeID = "plus_lifetime"
    static let lifetimeName = "Plus Forever"
    /// Every product that turns Plus on.
    static var plusProductIDs: Set<String> { allProductIDs.union([lifetimeID]) }
}

/// What the Plus page offers: the two subscription plans and Plus Forever. Yearly is the default choice.
enum PlusChoice: Hashable, CaseIterable {
    case yearly, monthly, lifetime

    var plan: PlusPlan? {
        switch self { case .yearly: .yearly; case .monthly: .monthly; case .lifetime: nil }
    }
    var productID: String { plan?.productID ?? PlusPlan.lifetimeID }
}

struct EntitlementState: Equatable {
    var activeProductIDs: Set<String> = []
    var hasPlus: Bool { !activeProductIDs.isDisjoint(with: PlusPlan.plusProductIDs) }
    var hasRemoveAds: Bool { hasPlus }
    var hasCloudSync: Bool { hasPlus }
    /// Plus Forever owned (bought or family-shared, not refunded). It wins over any subscription state.
    var hasLifetime: Bool { activeProductIDs.contains(PlusPlan.lifetimeID) }
    var hasActiveSubscription: Bool { !activeProductIDs.isDisjoint(with: PlusPlan.allProductIDs) }
    /// Seasonal packs owned now (bought or family-shared, not refunded). Plus never includes them.
    var ownedPacks: Set<String> { PackCatalog.owned(activeProductIDs: activeProductIDs) }
    /// False once every live subscription has auto-renew turned off (StoreKit's renewal info). Unknown counts as on.
    var subscriptionRenews = true
    /// When the live subscription's current period ends (the latest one, if there are two).
    var subscriptionEndsAt: Date?
    /// Someone who owns Plus Forever and still has a subscription that will renew is paying twice; the page says so.
    /// With auto-renew already off nothing more is charged, so the page only says when the subscription ends.
    var paysTwice: Bool { hasLifetime && hasActiveSubscription && subscriptionRenews }
    /// Plus Forever beside a subscription that will not renew: the day it ends, for one calm line (nil otherwise).
    var subscriptionEndsBesideLifetime: Date? {
        hasLifetime && hasActiveSubscription && !subscriptionRenews ? subscriptionEndsAt : nil
    }

    init(activeProductIDs: Set<String> = [], subscriptionRenews: Bool = true, subscriptionEndsAt: Date? = nil) {
        self.activeProductIDs = activeProductIDs
        self.subscriptionRenews = subscriptionRenews
        self.subscriptionEndsAt = subscriptionEndsAt
    }

    /// One transaction as the entitlement rules see it (StoreKit's `Transaction`, reduced to what matters).
    struct Entry: Equatable {
        var productID: String
        var revoked = false
        var expiresAt: Date?
        /// A subscription's renewal info `willAutoRenew`; nil when unknown (and for non-consumables).
        var willAutoRenew: Bool? = nil
    }

    /// Plus from the player's current transactions: refunded or revoked ones never count, an expired subscription
    /// does not count, and Plus Forever never expires.
    init(entries: [Entry], now: Date) {
        var ids = Set<String>()
        var renews = false, anySub = false
        var ends: Date?
        for e in entries where !e.revoked {
            if e.productID != PlusPlan.lifetimeID, let end = e.expiresAt, end <= now { continue }
            ids.insert(e.productID)
            if PlusPlan.allProductIDs.contains(e.productID) {
                anySub = true
                if e.willAutoRenew != false { renews = true }
                if let end = e.expiresAt { ends = max(ends ?? end, end) }
            }
        }
        self.activeProductIDs = ids
        self.subscriptionRenews = anySub ? renews : true
        self.subscriptionEndsAt = ends
    }
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
        // Apple's 24-hour rule and where to cancel, as the store listing says it (not the app's own Settings).
        let renew = renewal
        switch plan {
        case .yearly:
            let trial = trialEligible
            return Copy(headline: "Yearly", detail: "Best value",
                        cta: trial ? trialCTA : "Subscribe",
                        finePrint: trial ? "3 days free, then \(displayPrice) per year. \(renew)" : "\(displayPrice) per year. \(renew)")
        case .monthly:
            return Copy(headline: "Monthly", detail: "Flexible", cta: "Subscribe", finePrint: "\(displayPrice) per month. \(renew)")
        }
    }

    static let renewal = "Renews automatically unless cancelled at least 24 hours before the end of the period. Cancel anytime in your App Store account settings."
    /// A non-breaking hyphen, so "3-day" never splits at the largest text sizes.
    static let trialCTA = "Start 3\u{2011}day free trial"

    /// A plan's price in words on its card ("$12.99 a year", "$3.99 a month", "$34.99 once"), never "/yr".
    static func priceLine(_ price: String, choice: PlusChoice) -> String {
        switch choice {
        case .yearly: return "\(price) a year"
        case .monthly: return "\(price) a month"
        case .lifetime: return "\(price) once"
        }
    }

    // The page's other lines (all checked by CopySafety through `all`).
    static let loadFailed = "We couldn't load the plans. Check your connection and try again."
    static let tryAgain = "Try again"
    static let loadingPrices = "Loading prices"
    static let ownedSubscription = "You have WordFlora Plus"
    static let ownedSubscriptionDetail = "Ads are off and your garden can sync across your devices. Thank you for supporting WordFlora."
    static let restore = "Restore purchases"
    /// The purchase went through but Plus had not shown up yet.
    static let pendingSlow = "Almost there. If Plus is not on in a moment, tap Restore purchases."
    /// Ask to Buy (StoreKit pending): a grown-up must approve, maybe hours later.
    static let awaitingApproval = "Sent to a grown-up to approve. Plus turns on once it's approved."
    static let failed = "We couldn't confirm that purchase. If you see a charge, tap Restore purchases."
    static let restoredOn = "Plus is on."
    static let restoredNone = "No purchases found for this Apple ID."

    /// Plus Forever's one honest line, on its row and under the button.
    static let lifetimeLine = "Pay once, keep Plus on this Apple ID. No renewals."

    static func lifetime(displayPrice: String) -> Copy {
        Copy(headline: PlusPlan.lifetimeName, detail: "Pay once", cta: "Buy \(PlusPlan.lifetimeName)",
             finePrint: displayPrice.isEmpty ? lifetimeLine : "One payment of \(displayPrice). \(lifetimeLine)")
    }

    static func make(choice: PlusChoice, displayPrice: String, trialEligible: Bool) -> Copy {
        guard let plan = choice.plan else { return lifetime(displayPrice: displayPrice) }
        return make(plan: plan, displayPrice: displayPrice, trialEligible: trialEligible)
    }

    static let redeem = "Redeem a code"
    static let ownedLifetime = "You have Plus Forever"
    static let ownedLifetimeDetail = "Ads are off and your garden can sync across your devices, with no renewals. Thank you for supporting WordFlora."
    static let paysTwice = "You still have a subscription. Cancel it so you aren't charged twice."
    /// Plus Forever beside a subscription whose auto-renew is already off: nothing more to do, just the end date.
    static func subscriptionEnds(on date: String) -> String {
        "Your subscription ends on \(date) and will not renew. Plus Forever keeps going after that."
    }
    static let cancelSubscription = "Cancel the subscription"

    /// Every Plus page line outside the plan copy, for the copy checks.
    static var all: [String] {
        [lifetimeLine, lifetime(displayPrice: "$34.99").finePrint, lifetime(displayPrice: "").cta, redeem,
         ownedLifetime, ownedLifetimeDetail, paysTwice, subscriptionEnds(on: "December 1, 2026"), cancelSubscription,
         renewal, trialCTA, priceLine("$12.99", choice: .yearly), priceLine("$3.99", choice: .monthly),
         priceLine("$34.99", choice: .lifetime), loadFailed, tryAgain, loadingPrices, ownedSubscription,
         ownedSubscriptionDetail, restore, pendingSlow, awaitingApproval, failed, restoredOn, restoredNone,
         FamilyShareNudge.Copy.plusPageLine]
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

/// The Settings way into Plus. Young players and unknown ages see it as "For grown-ups", and Plus opens with one calm
/// line saying the game is complete without it. Teen and adult players see the usual row. The purchase itself still
/// asks a grown-up first (ParentalGate); nothing changes on the play screens.
enum PlusEntry {
    static let grownUps = "For grown-ups"
    static let introLine = "WordFlora is complete without Plus. Plus removes ads for grown-up players and syncs the garden with iCloud. Family Sharing covers up to six people."

    static func sectionTitle(ageBand: AgeBand?) -> String { ParentalGate.isRequired(ageBand: ageBand) ? grownUps : PlusPlan.groupName }
    static func rowTitle(ageBand: AgeBand?) -> String {
        ParentalGate.isRequired(ageBand: ageBand) ? PlusPlan.groupName : "Remove ads and sync with iCloud"
    }
    static func intro(ageBand: AgeBand?) -> String? { ParentalGate.isRequired(ageBand: ageBand) ? introLine : nil }
}

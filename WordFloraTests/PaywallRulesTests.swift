import XCTest
@testable import WordFlora

final class PaywallRulesTests: XCTestCase {

    // MARK: entitlements
    func testAnyPlusProductUnlocksBothFeatures() {
        for id in ["plus_yearly", "plus_monthly"] {
            let s = EntitlementState(activeProductIDs: [id])
            XCTAssertTrue(s.hasPlus); XCTAssertTrue(s.hasRemoveAds); XCTAssertTrue(s.hasCloudSync)
        }
    }

    func testNoProductsMeansFreeAndUnknownProductsAreIgnored() {
        XCTAssertFalse(EntitlementState(activeProductIDs: []).hasPlus)
        XCTAssertFalse(EntitlementState(activeProductIDs: ["something_else"]).hasPlus)
    }

    func testProductIDsAreTheOnesRegisteredInAppStoreConnect() {
        XCTAssertEqual(PlusPlan.yearly.productID, "plus_yearly")
        XCTAssertEqual(PlusPlan.monthly.productID, "plus_monthly")
        XCTAssertEqual(PlusPlan.groupName, "WordFlora Plus")
    }

    // MARK: pricing maths
    func testYearlySavingsAndPerMonthPrice() {
        XCTAssertEqual(PaywallMath.savingsPercent(yearly: 12.99, monthly: 3.99), 73)
        XCTAssertEqual(PaywallMath.perMonth(yearly: 12.99), 1.08)
        XCTAssertEqual(PaywallMath.savingsPercent(yearly: 0, monthly: 0), 0)       // never divide by zero
    }

    // MARK: copy
    func testTrialWordingOnlyWhenEligibleAndOnlyForYearly() {
        let eligible = PaywallCopy.make(plan: .yearly, displayPrice: "$12.99", trialEligible: true)
        XCTAssertEqual(eligible.cta, "Start 3-day free trial")
        XCTAssertTrue(eligible.finePrint.contains("then $12.99 per year"))

        let notEligible = PaywallCopy.make(plan: .yearly, displayPrice: "$12.99", trialEligible: false)
        XCTAssertEqual(notEligible.cta, "Subscribe")
        XCTAssertFalse(notEligible.finePrint.lowercased().contains("free"))

        let monthly = PaywallCopy.make(plan: .monthly, displayPrice: "$3.99", trialEligible: true)
        XCTAssertEqual(monthly.cta, "Subscribe")
        XCTAssertFalse(monthly.finePrint.lowercased().contains("free"))
        XCTAssertTrue(monthly.finePrint.contains("$3.99 per month"))
    }

    func testFinePrintStatesRenewalAndHowToCancel() {
        for plan in [PlusPlan.yearly, .monthly] {
            let c = PaywallCopy.make(plan: plan, displayPrice: "$1.00", trialEligible: false)
            XCTAssertTrue(c.finePrint.contains("renews automatically"), c.finePrint)
            XCTAssertTrue(c.finePrint.contains("Cancel anytime in Settings"), c.finePrint)
        }
    }

    func testAllPaywallCopyPassesTheCopyLinter() {
        for plan in [PlusPlan.yearly, .monthly] {
            for eligible in [true, false] {
                let c = PaywallCopy.make(plan: plan, displayPrice: "$9.99", trialEligible: eligible)
                for text in [c.headline, c.detail, c.cta, c.finePrint] { XCTAssertEqual(CopySafety.check(text), [], text) }
            }
        }
        for b in PaywallCopy.benefits { XCTAssertEqual(CopySafety.check(b), [], b) }
    }

    func testBenefitsMentionAdFreeAndICloudSync() {
        let all = PaywallCopy.benefits.joined(separator: " ").lowercased()
        XCTAssertTrue(all.contains("no ads")); XCTAssertTrue(all.contains("icloud"))
    }

    // MARK: parental gate (under 13)
    func testParentalGateIsDeterministicAndCheckable() {
        let a = ParentalGate.challenge(seed: 4), b = ParentalGate.challenge(seed: 4)
        XCTAssertEqual(a, b)
        XCTAssertTrue(ParentalGate.check(answer: String(a.answer), against: a))
        XCTAssertFalse(ParentalGate.check(answer: String(a.answer + 1), against: a))
        XCTAssertFalse(ParentalGate.check(answer: "", against: a))
        XCTAssertFalse(ParentalGate.check(answer: "abc", against: a))
    }

    func testParentalGateQuestionsAreHardForYoungChildrenButFair() {
        for seed in 0..<50 as Range<UInt64> {
            let c = ParentalGate.challenge(seed: seed)
            XCTAssertGreaterThanOrEqual(c.answer, 100)           // multiplication, beyond early readers
            XCTAssertTrue(c.question.contains("×"))
        }
    }

    func testGateRequiredOnlyForUnderThirteen() {
        XCTAssertTrue(ParentalGate.isRequired(ageBand: .under13))
        XCTAssertFalse(ParentalGate.isRequired(ageBand: .thirteenPlus))
        XCTAssertFalse(ParentalGate.isRequired(ageBand: .eighteenPlus))
        XCTAssertTrue(ParentalGate.isRequired(ageBand: nil))          // unknown age is treated as young
    }

    // MARK: outbound links (web pages, mail, subscription management)
    func testOutboundLinksAskAGrownUpFirstForYoungOrUnknownAges() {
        for link in [Links.privacy, Links.reportAd, Links.terms, Links.manageSubscriptions] {
            XCTAssertEqual(ParentalGate.outbound(link, ageBand: .under13), .askFirst(link))
            XCTAssertEqual(ParentalGate.outbound(link, ageBand: nil), .askFirst(link))
            XCTAssertEqual(ParentalGate.outbound(link, ageBand: .thirteenPlus), .open(link))
            XCTAssertEqual(ParentalGate.outbound(link, ageBand: .eighteenPlus), .open(link))
        }
    }

    // MARK: Settings entry (owner ruling: young or unknown ages see "For grown-ups" and one calm line on Plus)
    func testPlusEntryIsForGrownUpsForYoungOrUnknownAgesOnly() {
        for band: AgeBand? in [.under13, nil] {
            XCTAssertEqual(PlusEntry.sectionTitle(ageBand: band), "For grown-ups")
            XCTAssertEqual(PlusEntry.rowTitle(ageBand: band), "WordFlora Plus")
            XCTAssertEqual(PlusEntry.intro(ageBand: band),
                           "WordFlora is complete without Plus. Plus removes ads for grown-up players and syncs the garden with iCloud. Family Sharing covers up to six people.")
        }
        for band: AgeBand? in [.thirteenPlus, .eighteenPlus] {
            XCTAssertEqual(PlusEntry.sectionTitle(ageBand: band), "WordFlora Plus")
            XCTAssertEqual(PlusEntry.rowTitle(ageBand: band), "Remove ads and sync with iCloud")
            XCTAssertNil(PlusEntry.intro(ageBand: band))
        }
        for line in [PlusEntry.grownUps, PlusEntry.introLine] { XCTAssertEqual(CopySafety.check(line), [], line) }
    }

    // MARK: Plus Forever (lifetime) and codes
    func testLifetimeAloneIsPlusWithNoAdsAndSync() {
        let s = EntitlementState(activeProductIDs: ["plus_lifetime"])
        XCTAssertTrue(s.hasPlus); XCTAssertTrue(s.hasRemoveAds); XCTAssertTrue(s.hasCloudSync)
        XCTAssertTrue(s.hasLifetime); XCTAssertFalse(s.hasActiveSubscription); XCTAssertFalse(s.paysTwice)
        XCTAssertEqual(PlusPlan.lifetimeID, "plus_lifetime")
        XCTAssertEqual(PlusPlan.lifetimeName, "Plus Forever")
        XCTAssertFalse(PlusPlan.allProductIDs.contains("plus_lifetime"), "the subscription plans stay subscriptions only")
        XCTAssertEqual(PlusPlan.plusProductIDs, ["plus_yearly", "plus_monthly", "plus_lifetime"])
    }

    func testLifetimeWithASubscriptionIsPlusAndSaysItPaysTwice() {
        for sub in ["plus_yearly", "plus_monthly"] {
            let s = EntitlementState(activeProductIDs: ["plus_lifetime", sub])
            XCTAssertTrue(s.hasPlus); XCTAssertTrue(s.hasLifetime); XCTAssertTrue(s.paysTwice)
        }
    }

    func testLifetimeBeatsAnExpiredSubscription() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let s = EntitlementState(entries: [.init(productID: "plus_monthly", expiresAt: now.addingTimeInterval(-60)),
                                           .init(productID: "plus_lifetime")], now: now)
        XCTAssertTrue(s.hasPlus); XCTAssertTrue(s.hasLifetime)
        XCTAssertFalse(s.hasActiveSubscription); XCTAssertFalse(s.paysTwice)
    }

    func testRevokedLifetimeIsOffAndLiveSubscriptionsStillCount() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        XCTAssertFalse(EntitlementState(entries: [.init(productID: "plus_lifetime", revoked: true)], now: now).hasPlus)
        let expired = EntitlementState(entries: [.init(productID: "plus_yearly", expiresAt: now)], now: now)
        XCTAssertFalse(expired.hasPlus, "a subscription that ends now is over")
        let live = EntitlementState(entries: [.init(productID: "plus_yearly", expiresAt: now.addingTimeInterval(86_400)),
                                              .init(productID: "plus_lifetime", revoked: true)], now: now)
        XCTAssertTrue(live.hasPlus); XCTAssertFalse(live.hasLifetime)
        // Plus Forever has no end date, and a stray date on it never turns it off.
        XCTAssertTrue(EntitlementState(entries: [.init(productID: "plus_lifetime", expiresAt: now.addingTimeInterval(-1))], now: now).hasLifetime)
    }

    func testChoicesMapToTheirProductsAndYearlyStaysFirst() {
        XCTAssertEqual(PlusChoice.allCases, [.yearly, .monthly, .lifetime])
        XCTAssertEqual(PlusChoice.yearly.productID, "plus_yearly")
        XCTAssertEqual(PlusChoice.monthly.productID, "plus_monthly")
        XCTAssertEqual(PlusChoice.lifetime.productID, "plus_lifetime")
        XCTAssertNil(PlusChoice.lifetime.plan)
    }

    func testLifetimeCopyIsCalmAndHonest() {
        XCTAssertEqual(PaywallCopy.lifetimeLine, "Pay once, keep Plus on this Apple ID. No renewals.")
        let c = PaywallCopy.lifetime(displayPrice: "$34.99")
        XCTAssertEqual(c.headline, "Plus Forever")
        XCTAssertEqual(c.finePrint, "One payment of $34.99. Pay once, keep Plus on this Apple ID. No renewals.")
        XCTAssertFalse(c.finePrint.lowercased().contains("free"))
        XCTAssertFalse(c.finePrint.contains("renews automatically"))
        XCTAssertEqual(PaywallCopy.make(choice: .lifetime, displayPrice: "$34.99", trialEligible: true), c, "never trial wording")
        XCTAssertEqual(PaywallCopy.make(choice: .yearly, displayPrice: "$12.99", trialEligible: true),
                       PaywallCopy.make(plan: .yearly, displayPrice: "$12.99", trialEligible: true))
        XCTAssertEqual(PaywallCopy.redeem, "Redeem a code")
        for line in PaywallCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
        for text in [c.headline, c.detail, c.cta] { XCTAssertEqual(CopySafety.check(text), [], text) }
    }

    func testGateCopyIsGentle() {
        for line in [ParentalGate.Copy.title, ParentalGate.Copy.prompt, ParentalGate.Copy.wrong] {
            XCTAssertEqual(CopySafety.check(line), [], line)
        }
    }
}

/// What App Review reads from the built app: export compliance and the privacy manifest.
final class ReviewReadinessTests: XCTestCase {
    func testExportComplianceKeySaysNoNonExemptEncryption() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "ITSAppUsesNonExemptEncryption") as? Bool, false)
    }

    func testAppShipsAPrivacyManifestThatDeclaresUserDefaultsAndAdData() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])
        let apis = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let defaults = try XCTUnwrap(apis.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" })
        XCTAssertEqual(Set(defaults["NSPrivacyAccessedAPITypeReasons"] as? [String] ?? []), ["CA92.1", "1C8F.1"])
        // Tracking happens only for an adult who says yes to the App Tracking Transparency prompt.
        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, true)
        let collected = try XCTUnwrap(plist["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        let types = Set(collected.compactMap { $0["NSPrivacyCollectedDataType"] as? String })
        XCTAssertTrue(types.isSuperset(of: ["NSPrivacyCollectedDataTypeDeviceID", "NSPrivacyCollectedDataTypeAdvertisingData",
                                            "NSPrivacyCollectedDataTypeCoarseLocation", "NSPrivacyCollectedDataTypeProductInteraction"]))
        let tracked = collected.filter { $0["NSPrivacyCollectedDataTypeTracking"] as? Bool == true }.compactMap { $0["NSPrivacyCollectedDataType"] as? String }
        XCTAssertEqual(tracked, ["NSPrivacyCollectedDataTypeDeviceID"])
    }

    func testWidgetShipsAPrivacyManifestForTheSharedGroupDefaults() throws {
        let widget = try XCTUnwrap(Bundle.main.builtInPlugInsURL?.appendingPathComponent("WordFloraWidget.appex"))
        let url = widget.appendingPathComponent("PrivacyInfo.xcprivacy")
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])
        let apis = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        XCTAssertEqual(apis.first?["NSPrivacyAccessedAPIType"] as? String, "NSPrivacyAccessedAPICategoryUserDefaults")
        // The App Group store, and the app-only fallback when the group is missing.
        XCTAssertEqual(Set(apis.first?["NSPrivacyAccessedAPITypeReasons"] as? [String] ?? []), ["1C8F.1", "CA92.1"])
        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
    }
}

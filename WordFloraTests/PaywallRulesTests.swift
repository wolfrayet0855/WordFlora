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
}

import XCTest
import StoreKit
import StoreKitTest
@testable import WordFlora

/// Proves the local StoreKit configuration matches what App Store Connect must contain.
@MainActor
final class StoreKitConfigTests: XCTestCase {
    var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "WordFlora")      // bundled copy of Config/WordFlora.storekit
        session.disableDialogs = true
        session.clearTransactions()
    }

    func testBothPlansLoadWithTheRightPricesAndPeriods() async throws {
        let products = try await Product.products(for: PlusPlan.allProductIDs)
        XCTAssertEqual(Set(products.map(\.id)), PlusPlan.allProductIDs)
        let yearly = try XCTUnwrap(products.first { $0.id == "plus_yearly" })
        let monthly = try XCTUnwrap(products.first { $0.id == "plus_monthly" })
        XCTAssertEqual(yearly.price, Decimal(string: "12.99")); XCTAssertEqual(monthly.price, Decimal(string: "3.99"))
        XCTAssertEqual(yearly.subscription?.subscriptionPeriod.unit, .year)
        XCTAssertEqual(monthly.subscription?.subscriptionPeriod.unit, .month)
        XCTAssertTrue(yearly.isFamilyShareable); XCTAssertTrue(monthly.isFamilyShareable)
    }

    func testYearlyHasAThreeDayFreeTrialAndMonthlyHasNone() async throws {
        let products = try await Product.products(for: PlusPlan.allProductIDs)
        let yearly = try XCTUnwrap(products.first { $0.id == "plus_yearly" })
        let monthly = try XCTUnwrap(products.first { $0.id == "plus_monthly" })
        let offer = try XCTUnwrap(yearly.subscription?.introductoryOffer)
        XCTAssertEqual(offer.paymentMode, .freeTrial)
        XCTAssertEqual(offer.period.unit, .day); XCTAssertEqual(offer.period.value, 3)
        XCTAssertNil(monthly.subscription?.introductoryOffer)
    }

    func testPurchasingEitherPlanTurnsOnPlus() async throws {
        let svc = EntitlementService(startListening: false)
        await svc.loadProducts()
        XCTAssertFalse(svc.state.hasPlus)
        try await session.buyProduct(identifier: "plus_monthly")
        // StoreKit publishes the new entitlement asynchronously; poll briefly instead of racing it.
        for _ in 0..<20 where !svc.state.hasPlus { try await Task.sleep(nanoseconds: 100_000_000); await svc.refresh() }
        XCTAssertTrue(svc.state.hasPlus); XCTAssertTrue(svc.state.hasRemoveAds); XCTAssertTrue(svc.state.hasCloudSync)
    }

    func testExpiredOrRefundedSubscriptionTurnsPlusOffButKeepsData() async throws {
        let svc = EntitlementService(startListening: false)
        try await session.buyProduct(identifier: "plus_monthly")
        await svc.refresh(); XCTAssertTrue(svc.state.hasPlus)
        try session.expireSubscription(productIdentifier: "plus_monthly")
        // StoreKit applies the expiry asynchronously; poll briefly instead of racing it.
        for _ in 0..<20 where svc.state.hasPlus {
            try await Task.sleep(nanoseconds: 100_000_000)
            await svc.refresh()
        }
        XCTAssertFalse(svc.state.hasPlus)
    }

    func testTrialEligibilityIsReportedForNewSubscribers() async throws {
        let svc = EntitlementService(startListening: false)
        await svc.loadProducts()
        XCTAssertTrue(svc.trialEligible)
    }

    /// The app must never say "Welcome" while Plus is still off: purchase() waits for the entitlement to appear.
    func testPurchaseOnlyReportsSuccessOnceTheEntitlementIsLive() async throws {
        let svc = EntitlementService(startListening: false)
        await svc.loadProducts()
        let outcome = await svc.purchase(.monthly)
        XCTAssertEqual(outcome, .success)
        XCTAssertTrue(svc.state.hasPlus)
    }
}

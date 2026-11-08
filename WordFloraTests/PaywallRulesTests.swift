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
        XCTAssertEqual(eligible.cta, "Start 3\u{2011}day free trial", "a non-breaking hyphen keeps 3-day together")
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
            XCTAssertTrue(c.finePrint.contains("Renews automatically unless cancelled at least 24 hours before the end of the period."), c.finePrint)
            XCTAssertTrue(c.finePrint.contains("Cancel anytime in your App Store account settings."), c.finePrint)
        }
    }

    // MARK: text-fit and polish pass (docs/pm/plus-page-review.md)

    /// Trial words need a free-trial introductory offer on the yearly plan; eligibility alone is not enough.
    func testTrialNeedsAFreeTrialOffer() {
        XCTAssertFalse(EntitlementService.offersFreeTrial(paymentMode: nil), "no offer")
        XCTAssertFalse(EntitlementService.offersFreeTrial(paymentMode: .payAsYouGo), "a paid intro offer is not a trial")
        XCTAssertFalse(EntitlementService.offersFreeTrial(paymentMode: .payUpFront))
        XCTAssertTrue(EntitlementService.offersFreeTrial(paymentMode: .freeTrial))
        // With no trial the page says nothing about free days.
        let none = PaywallCopy.make(choice: .yearly, displayPrice: "$12.99", trialEligible: false)
        XCTAssertFalse((none.cta + none.finePrint).lowercased().contains("free"))
        XCTAssertFalse(none.finePrint.contains("3 days"))
    }

    /// StoreKit's pending (Ask to Buy) is its own outcome with its own words; the slow-entitlement wait keeps its line.
    func testAskToBuyIsAwaitingApproval() {
        XCTAssertEqual(EntitlementService.outcome(storeKitPending: true), .awaitingApproval)
        XCTAssertEqual(EntitlementService.outcome(storeKitPending: false), .pending)
        XCTAssertEqual(PaywallCopy.awaitingApproval, "Sent to a grown-up to approve. Plus turns on once it's approved.")
        XCTAssertFalse(PaywallCopy.awaitingApproval.contains("Restore"), "no tapping Restore while a grown-up decides")
        XCTAssertEqual(PaywallCopy.pendingSlow, "Almost there. If Plus is not on in a moment, tap Restore purchases.")
        XCTAssertFalse(PackCatalog.Copy.awaitingApproval.contains("Restore"))
        for line in PackCatalog.Copy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
    }

    func testPricesAreInWords() {
        XCTAssertEqual(PaywallCopy.priceLine("$12.99", choice: .yearly), "$12.99 a year")
        XCTAssertEqual(PaywallCopy.priceLine("$3.99", choice: .monthly), "$3.99 a month")
        XCTAssertEqual(PaywallCopy.priceLine("$34.99", choice: .lifetime), "$34.99 once")
        for choice in PlusChoice.allCases { XCTAssertFalse(PaywallCopy.priceLine("$1", choice: choice).contains("/")) }
    }

    func testRestoreAndPageLines() {
        XCTAssertEqual(PaywallCopy.restoredOn, "Plus is on.")
        XCTAssertEqual(PaywallCopy.restoredNone, "No purchases found for this Apple ID.")
        XCTAssertEqual(PaywallCopy.restore, "Restore purchases", "the one Restore button keeps its name")
        for line in [PaywallCopy.loadFailed, PaywallCopy.tryAgain, PaywallCopy.loadingPrices, PaywallCopy.ownedSubscription,
                     PaywallCopy.failed, PaywallCopy.renewal, PaywallCopy.trialCTA, PaywallCopy.ownedLifetimeDetail] {
            XCTAssertTrue(PaywallCopy.all.contains(line), line)
        }
        for line in PaywallCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
    }

    // MARK: You have Plus (docs/pm/plus-flow-fable-review.md N3)

    func testJustOnSaysWhatChanged() {
        XCTAssertEqual(PaywallCopy.justOn(adsWereOn: true, syncNeedsRestart: true), "Plus is on. Ads are off. iCloud sync starts next time you open WordFlora.")
        XCTAssertEqual(PaywallCopy.justOn(adsWereOn: false, syncNeedsRestart: false), "Plus is on. Your garden syncs with iCloud.")
        XCTAssertEqual(PaywallCopy.ownedLifetimeDetail, "Paid once. No renewals.")
    }

    func testActivePlanAndPlanLine() {
        XCTAssertEqual(EntitlementState(activeProductIDs: ["plus_yearly"]).activePlan, .yearly)
        XCTAssertEqual(EntitlementState(activeProductIDs: ["plus_monthly"]).activePlan, .monthly)
        XCTAssertEqual(EntitlementState(activeProductIDs: ["plus_monthly", "plus_yearly"]).activePlan, .yearly, "yearly wins")
        XCTAssertNil(EntitlementState(activeProductIDs: ["plus_lifetime"]).activePlan)
        XCTAssertNil(EntitlementState().activePlan)
        let end = Date(timeIntervalSince1970: 1_826_000_000)
        XCTAssertEqual(PaywallCopy.planLine(plan: .yearly, renews: true, endsAt: nil), "Yearly plan")
        let renews = PaywallCopy.planLine(plan: .yearly, renews: true, endsAt: end)
        XCTAssertTrue(renews.hasPrefix("Yearly plan · renews "), renews)
        let ends = PaywallCopy.planLine(plan: .monthly, renews: false, endsAt: end)
        XCTAssertTrue(ends.hasPrefix("Monthly plan · ends ") && ends.hasSuffix(". Auto-renew is off."), ends)
    }

    func testSettingsRowSaysPlusIsOnForEveryAge() {
        for band: AgeBand? in [.under13, nil, .thirteenPlus, .eighteenPlus] {
            XCTAssertEqual(PlusEntry.rowTitle(ageBand: band, hasPlus: true), "WordFlora Plus is on")
        }
        XCTAssertEqual(PaywallCopy.planShort(EntitlementState(activeProductIDs: ["plus_yearly"])), "Yearly")
        XCTAssertEqual(PaywallCopy.planShort(EntitlementState(activeProductIDs: ["plus_monthly"])), "Monthly")
        XCTAssertEqual(PaywallCopy.planShort(EntitlementState(activeProductIDs: ["plus_lifetime", "plus_yearly"])), "Forever", "Plus Forever wins")
        XCTAssertNil(PaywallCopy.planShort(EntitlementState()))
    }

    // MARK: iCloud sync status (N4)

    func testCloudSyncStatusTable() {
        typealias S = CloudSyncStatus
        XCTAssertEqual(S.status(hasPlus: false, launchedWithCloud: false, cloudOpenFailed: false, account: nil), .needsPlus)
        XCTAssertEqual(S.status(hasPlus: false, launchedWithCloud: true, cloudOpenFailed: false, account: .available), .needsPlus)
        XCTAssertEqual(S.status(hasPlus: true, launchedWithCloud: true, cloudOpenFailed: false, account: .available), .on)
        XCTAssertEqual(S.status(hasPlus: true, launchedWithCloud: false, cloudOpenFailed: false, account: .noAccount), .needsSignIn)
        XCTAssertEqual(S.status(hasPlus: true, launchedWithCloud: false, cloudOpenFailed: true, account: .available), .unavailable)
        XCTAssertEqual(S.status(hasPlus: true, launchedWithCloud: false, cloudOpenFailed: false, account: .restricted), .unavailable)
        XCTAssertEqual(S.status(hasPlus: true, launchedWithCloud: false, cloudOpenFailed: false, account: .couldNotDetermine), .startsNextLaunch)
        XCTAssertEqual(S.status(hasPlus: true, launchedWithCloud: false, cloudOpenFailed: false, account: nil), .startsNextLaunch)
        XCTAssertEqual(S.on.title, "iCloud sync is on")
        XCTAssertEqual(S.needsPlus.title, "iCloud sync is off (needs Plus)")
        XCTAssertNil(S.startsNextLaunch.footnote)
        for line in S.Copy.all {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertFalse(line.lowercased().contains("last"), line)
        }
        XCTAssertTrue(S.Copy.synced(Date.now.addingTimeInterval(-300)).hasPrefix("Synced "))
    }

    @MainActor
    func testCloudSyncMonitorKeepsTheLatestSuccess() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "textfit.cloudsync.test"))
        defaults.removePersistentDomain(forName: "textfit.cloudsync.test")
        let m = CloudSyncMonitor(defaults: defaults, listen: false)
        XCTAssertNil(m.syncedAt, "no event, no time")
        let t = Date(timeIntervalSince1970: 1_800_000_000)
        m.record(end: t, ok: true)
        XCTAssertEqual(m.syncedAt, t); XCTAssertFalse(m.lastFailed)
        m.record(end: t.addingTimeInterval(60), ok: false)
        XCTAssertEqual(m.syncedAt, t, "a failed export does not move the time"); XCTAssertTrue(m.lastFailed)
        XCTAssertEqual(CloudSyncMonitor(defaults: defaults, listen: false).syncedAt, t, "kept across launches")
        defaults.removePersistentDomain(forName: "textfit.cloudsync.test")
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
                           "WordFlora is complete without Plus. Plus removes ads for grown-up players and syncs the garden with iCloud.")
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

    /// The "charged twice" note reads the renewal info: only while auto-renew is still on.
    func testPaysTwiceOnlyWhileTheSubscriptionWillRenew() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let end = now.addingTimeInterval(20 * 86_400)
        let cases: [(Bool?, Bool, Date?)] = [(true, true, nil), (nil, true, nil), (false, false, end)]
        for (renew, paysTwice, endsBeside) in cases {
            let s = EntitlementState(entries: [.init(productID: "plus_lifetime"),
                                               .init(productID: "plus_yearly", expiresAt: end, willAutoRenew: renew)], now: now)
            XCTAssertTrue(s.hasPlus); XCTAssertTrue(s.hasActiveSubscription)
            XCTAssertEqual(s.paysTwice, paysTwice, "willAutoRenew \(String(describing: renew))")
            XCTAssertEqual(s.subscriptionEndsBesideLifetime, endsBeside)
        }
        // Two live subscriptions: one still renewing is enough for the note; with both off the later end date shows.
        let later = end.addingTimeInterval(86_400)
        let mixed = EntitlementState(entries: [.init(productID: "plus_lifetime"),
                                               .init(productID: "plus_yearly", expiresAt: end, willAutoRenew: false),
                                               .init(productID: "plus_monthly", expiresAt: later, willAutoRenew: true)], now: now)
        XCTAssertTrue(mixed.paysTwice); XCTAssertNil(mixed.subscriptionEndsBesideLifetime)
        let bothOff = EntitlementState(entries: [.init(productID: "plus_lifetime"),
                                                 .init(productID: "plus_yearly", expiresAt: end, willAutoRenew: false),
                                                 .init(productID: "plus_monthly", expiresAt: later, willAutoRenew: false)], now: now)
        XCTAssertFalse(bothOff.paysTwice); XCTAssertEqual(bothOff.subscriptionEndsBesideLifetime, later)
        // A subscriber without Plus Forever never sees either line, renewing or not.
        let subOnly = EntitlementState(entries: [.init(productID: "plus_yearly", expiresAt: end, willAutoRenew: false)], now: now)
        XCTAssertFalse(subOnly.paysTwice); XCTAssertNil(subOnly.subscriptionEndsBesideLifetime)
        XCTAssertEqual(CopySafety.check(PaywallCopy.subscriptionEnds(on: "December 1, 2026")), [])
        XCTAssertEqual(PaywallCopy.subscriptionEnds(on: "December 1, 2026"),
                       "Your subscription ends on December 1, 2026 and will not renew. Plus Forever keeps going after that.")
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

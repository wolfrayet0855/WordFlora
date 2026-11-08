import Foundation
import StoreKit

/// StoreKit 2 wrapper for WordFlora Plus. Verifies transactions, listens for renewals/refunds/Ask to Buy approvals,
/// and exposes a plain `EntitlementState` the rest of the app reads.
@Observable
@MainActor
final class EntitlementService {
    /// `awaitingApproval`: StoreKit's `.pending` (Ask to Buy, a grown-up must approve, maybe hours later).
    /// `pending`: the purchase went through but the entitlement had not shown up yet when we stopped waiting.
    enum PurchaseOutcome: Equatable { case success, pending, awaitingApproval, cancelled, failed }

    /// The yearly plan's introductory offer is a free trial (pay-as-you-go and pay-up-front offers are not).
    nonisolated static func offersFreeTrial(paymentMode: Product.SubscriptionOffer.PaymentMode?) -> Bool {
        paymentMode == .freeTrial
    }

    /// What a StoreKit purchase result means for the page (the slow-entitlement wait is `pending`, decided after).
    nonisolated static func outcome(storeKitPending: Bool) -> PurchaseOutcome { storeKitPending ? .awaitingApproval : .pending }

    private(set) var state = EntitlementState()
    private(set) var products: [PlusPlan: Product] = [:]
    /// Plus Forever, when the store has it.
    private(set) var lifetimeProduct: Product?
    private(set) var trialEligible = false
    private(set) var loadFailed = false
    /// False until the first look at the player's transactions has finished. Ads and sync decisions wait for it.
    private(set) var hasLoaded = false
    @ObservationIgnored nonisolated(unsafe) private var listener: Task<Void, Never>?

    init(startListening: Bool = true) {
        guard startListening else { hasLoaded = true; return }
        listener = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let t) = update else { continue }
                await t.finish()
                await self?.refresh()
            }
        }
        Task { [weak self] in await self?.refresh(); await self?.loadPackProducts() }
    }

    deinit { listener?.cancel() }

    /// UI tests only (`-uitest-store-slow`): the store takes this long to answer, so the loading state can be seen.
    private(set) var debugLoadDelay: UInt64 = 0
    func debugSlowStore(seconds: UInt64) { debugLoadDelay = seconds }
    /// UI tests only (`-uitest-store-fail`): the store answers with an error, for the failed state.
    private(set) var debugFailLoad = false
    func debugFailStore() { debugFailLoad = true }

    func loadProducts() async {
        if debugLoadDelay > 0 { try? await Task.sleep(nanoseconds: debugLoadDelay * 1_000_000_000) }
        if debugFailLoad { try? await Task.sleep(nanoseconds: 800_000_000); loadFailed = true; return }
        do {
            let found = try await Product.products(for: PlusPlan.plusProductIDs)
            var map = [PlusPlan: Product]()
            for plan in PlusPlan.allCases { if let p = found.first(where: { $0.id == plan.productID }) { map[plan] = p } }
            products = map
            lifetimeProduct = found.first { $0.id == PlusPlan.lifetimeID }
            // A missing yearly or monthly plan counts as failed: the page would otherwise wait on it for ever.
            loadFailed = map.count < PlusPlan.allCases.count
            // Trial words only when the yearly plan really has a free-trial introductory offer and this Apple ID can
            // still take it (eligibility alone is true for anyone new to the group, offer or not).
            if let yearly = map[.yearly], let sub = yearly.subscription,
               Self.offersFreeTrial(paymentMode: sub.introductoryOffer?.paymentMode) {
                trialEligible = await sub.isEligibleForIntroOffer
            } else {
                trialEligible = false
            }
        } catch {
            loadFailed = true
        }
    }

    func refresh() async {
        // Non-consumables (Plus Forever, bought or family-shared) arrive here too, so restore needs nothing extra.
        var entries = [EntitlementState.Entry]()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            // Renewal info tells a subscription that will renew from one whose auto-renew is already off.
            var willAutoRenew: Bool?
            if t.productType == .autoRenewable, let status = await t.subscriptionStatus,
               case .verified(let info) = status.renewalInfo {
                willAutoRenew = info.willAutoRenew
            }
            entries.append(.init(productID: t.productID, revoked: t.revocationDate != nil, expiresAt: t.expirationDate,
                                 willAutoRenew: willAutoRenew))
        }
        state = EntitlementState(entries: entries, now: .now)
        hasLoaded = true
    }

    func product(for choice: PlusChoice) -> Product? {
        if let plan = choice.plan { return products[plan] }
        return lifetimeProduct
    }

    /// UI tests only (`-uitest-prices`): the local StoreKit file's prices, shown when the store returns nothing, so
    /// the page can be checked on any simulator. Nothing can be bought from a preview (purchase needs a `Product`).
    private(set) var previewPrices: [PlusChoice: Decimal]?
    func debugPreviewPrices(_ p: [PlusChoice: Decimal]) { previewPrices = p }

    /// The price to show for a choice, in the store's own currency.
    func price(for choice: PlusChoice) -> Decimal? {
        product(for: choice)?.price ?? previewPrices?[choice]
    }

    func displayPrice(for choice: PlusChoice) -> String? {
        if let p = product(for: choice) { return p.displayPrice }
        return previewPrices?[choice].map { $0.formatted(.currency(code: "USD")) }
    }

    /// Formats an amount like the store does (used for "about X a month").
    func formatted(_ amount: Decimal, like choice: PlusChoice) -> String {
        product(for: choice)?.priceFormatStyle.format(amount) ?? amount.formatted(.currency(code: "USD"))
    }

    /// The store (or the UI test preview) offers this choice.
    func offers(_ choice: PlusChoice) -> Bool { displayPrice(for: choice) != nil }
    var offersAnything: Bool { PlusChoice.allCases.contains(where: offers) }

    /// A plan is live once Plus is on; Plus Forever once it is owned (a subscriber already has Plus).
    private func isLive(_ choice: PlusChoice) -> Bool { choice == .lifetime ? state.hasLifetime : state.hasPlus }

    func purchase(_ choice: PlusChoice) async -> PurchaseOutcome {
        guard let product = product(for: choice) else { return .failed }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let t) = verification else { return .failed }
                await t.finish()
                await refresh()
                // Never report success while Plus is still off: StoreKit can take a moment to publish the entitlement.
                for _ in 0..<10 where !isLive(choice) { try? await Task.sleep(nanoseconds: 200_000_000); await refresh() }
                return isLive(choice) ? .success : .pending
            case .pending: return Self.outcome(storeKitPending: true)   // Ask to Buy: the listener finishes it when approved
            case .userCancelled: return .cancelled
            @unknown default: return .failed
            }
        } catch { return .failed }
    }

    /// False when the App Store could not be reached (offline, cancelled sign-in, an error); what was found is read
    /// either way.
    @discardableResult
    func restore() async -> Bool {
        var reached = true
        do { try await AppStore.sync() } catch { reached = false }
        await refresh()
        return reached
    }

    // MARK: Seasonal packs (non-consumables; ownership is read from the transactions above every time)

    /// The packs the store offers, by pack id. Empty until `loadPackProducts` answers (or when the store has none:
    /// the dormant framework shows nothing).
    private(set) var packProducts: [String: Product] = [:]
    /// UI tests only (`-uitest-prices`): the local file's pack prices, so the Seasons surfaces can be checked.
    private(set) var previewPackPrices: [String: Decimal]?
    func debugPreviewPackPrices(_ p: [String: Decimal]) { previewPackPrices = p }

    func loadPackProducts() async {
        guard let found = try? await Product.products(for: PackCatalog.productIDs) else { return }
        var map = [String: Product]()
        for p in found { if let pack = PackCatalog.pack(productID: p.id) { map[pack.id] = p } }
        packProducts = map
    }

    func offersPack(_ id: String) -> Bool { packDisplayPrice(id) != nil }
    func ownsPack(_ id: String) -> Bool { state.ownedPacks.contains(id) }
    /// A pack's surfaces show while the store offers it or the player owns it.
    func packIsLive(_ id: String) -> Bool {
        guard let pack = PackCatalog.pack(id: id) else { return false }
        return PackCatalog.isLive(pack, offered: offersPack(id), owned: ownsPack(id))
    }

    func packDisplayPrice(_ id: String) -> String? {
        if let p = packProducts[id] { return p.displayPrice }
        return previewPackPrices?[id].map { $0.formatted(.currency(code: "USD")) }
    }

    func purchasePack(_ id: String) async -> PurchaseOutcome {
        guard let product = packProducts[id] else { return .failed }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let t) = verification else { return .failed }
                await t.finish()
                await refresh()
                for _ in 0..<10 where !ownsPack(id) { try? await Task.sleep(nanoseconds: 200_000_000); await refresh() }
                return ownsPack(id) ? .success : .pending
            case .pending: return Self.outcome(storeKitPending: true)
            case .userCancelled: return .cancelled
            @unknown default: return .failed
            }
        } catch { return .failed }
    }

    /// Test and preview hook: pretend a subscription is active.
    func debugForce(_ s: EntitlementState) { state = s; hasLoaded = true }
    func debugSetLoaded(_ v: Bool) { hasLoaded = v }
}

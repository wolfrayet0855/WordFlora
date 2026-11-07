import Foundation
import StoreKit

/// StoreKit 2 wrapper for WordFlora Plus. Verifies transactions, listens for renewals/refunds/Ask to Buy approvals,
/// and exposes a plain `EntitlementState` the rest of the app reads.
@Observable
@MainActor
final class EntitlementService {
    enum PurchaseOutcome: Equatable { case success, pending, cancelled, failed }

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
        Task { [weak self] in await self?.refresh() }
    }

    deinit { listener?.cancel() }

    func loadProducts() async {
        do {
            let found = try await Product.products(for: PlusPlan.plusProductIDs)
            var map = [PlusPlan: Product]()
            for plan in PlusPlan.allCases { if let p = found.first(where: { $0.id == plan.productID }) { map[plan] = p } }
            products = map
            lifetimeProduct = found.first { $0.id == PlusPlan.lifetimeID }
            loadFailed = map.isEmpty && lifetimeProduct == nil
            if let yearly = map[.yearly], let sub = yearly.subscription {
                trialEligible = await sub.isEligibleForIntroOffer
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
            entries.append(.init(productID: t.productID, revoked: t.revocationDate != nil, expiresAt: t.expirationDate))
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
            case .pending: return .pending            // Ask to Buy: the listener finishes it when approved
            case .userCancelled: return .cancelled
            @unknown default: return .failed
            }
        } catch { return .failed }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
    }

    /// Test and preview hook: pretend a subscription is active.
    func debugForce(_ s: EntitlementState) { state = s; hasLoaded = true }
    func debugSetLoaded(_ v: Bool) { hasLoaded = v }
}

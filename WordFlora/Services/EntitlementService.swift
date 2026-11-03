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
            let found = try await Product.products(for: PlusPlan.allProductIDs)
            var map = [PlusPlan: Product]()
            for plan in PlusPlan.allCases { if let p = found.first(where: { $0.id == plan.productID }) { map[plan] = p } }
            products = map
            loadFailed = map.isEmpty
            if let yearly = map[.yearly], let sub = yearly.subscription {
                trialEligible = await sub.isEligibleForIntroOffer
            }
        } catch {
            loadFailed = true
        }
    }

    func refresh() async {
        var ids = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil { ids.insert(t.productID) }
        }
        state = EntitlementState(activeProductIDs: ids)
        hasLoaded = true
    }

    func purchase(_ plan: PlusPlan) async -> PurchaseOutcome {
        guard let product = products[plan] else { return .failed }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let t) = verification else { return .failed }
                await t.finish()
                await refresh()
                // Never report success while Plus is still off: StoreKit can take a moment to publish the entitlement.
                for _ in 0..<10 where !state.hasPlus { try? await Task.sleep(nanoseconds: 200_000_000); await refresh() }
                return state.hasPlus ? .success : .pending
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

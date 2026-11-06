import SwiftUI
import StoreKit

struct PlusView: View {
    @Environment(AppModel.self) private var app
    @State private var selected: PlusPlan = .yearly
    @State private var busy = false
    @State private var message: String?
    @State private var gate: ParentalGate.Challenge?

    private var store: EntitlementService { app.entitlements }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                FlowerView(petals: 8).frame(height: 120)
                Text("WordFlora Plus").font(Theme.font(.largeTitle, weight: .bold)).foregroundStyle(Color.appPrimaryText)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(PaywallCopy.benefits, id: \.self) { b in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.successText)
                            Text(b).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)

                if store.state.hasPlus { activeCard } else { plans }
                FamilyShareNudgeRow()

                VStack(spacing: 2) {
                    Button("Restore purchases") { Task { await store.restore(); app.updateSyncFlag() } }.tapTarget()
                    GatedLink("Manage subscription", url: Links.manageSubscriptions).tapTarget()
                    HStack(spacing: 8) {
                        GatedLink("Terms of Use", url: Links.terms).tapTarget()
                        GatedLink("Privacy Policy", url: Links.privacy).tapTarget()
                    }
                }
                .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card).padding(.bottom, Space.section)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Plus")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadProducts() }
        .sheet(item: $gate) { challenge in
            ParentalGateSheet(challenge: challenge, onPass: { gate = nil; startPurchase() }, onCancel: { gate = nil })
        }
    }

    // MARK: Plans

    @ViewBuilder private var plans: some View {
        if store.loadFailed && store.products.isEmpty {
            Card { Text("We couldn't load the plans. Check your connection and try again.").font(Theme.font(.callout)) }
            Button("Try again") { Task { await store.loadProducts() } }.buttonStyle(SecondaryButtonStyle())
        } else {
            let yearlyPrice = store.products[.yearly].map { ($0.price as NSDecimalNumber).doubleValue } ?? 0
            let monthlyPrice = store.products[.monthly].map { ($0.price as NSDecimalNumber).doubleValue } ?? 0
            VStack(spacing: 12) {
                planCard(.yearly, extra: yearlyPrice > 0 ? "About \(perMonthText(store.products[.yearly], yearlyPrice)) a month · save \(PaywallMath.savingsPercent(yearly: yearlyPrice, monthly: monthlyPrice))%" : nil)
                planCard(.monthly, extra: nil)
            }
            let price = store.products[selected]?.displayPrice ?? ""
            let copy = PaywallCopy.make(plan: selected, displayPrice: price, trialEligible: store.trialEligible && selected == .yearly)
            Button { buy() } label: { Text(busy ? "One moment…" : copy.cta) }
                .buttonStyle(PrimaryButtonStyle()).disabled(busy || store.products[selected] == nil)
            Text(copy.finePrint).font(Theme.font(.caption)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
            if let message { Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText).multilineTextAlignment(.center) }
        }
    }

    /// Formatted in the store's own currency, never a hard-coded "$".
    private func perMonthText(_ product: Product?, _ yearly: Double) -> String {
        let perMonth = Decimal(PaywallMath.perMonth(yearly: yearly))
        return product?.priceFormatStyle.format(perMonth) ?? String(format: "%.2f", PaywallMath.perMonth(yearly: yearly))
    }

    private func planCard(_ plan: PlusPlan, extra: String?) -> some View {
        let product = store.products[plan]
        let copy = PaywallCopy.make(plan: plan, displayPrice: product?.displayPrice ?? "", trialEligible: false)
        let isSelected = selected == plan
        return Button { selected = plan } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(copy.headline).font(Theme.font(.headline))
                        if plan == .yearly { Text(copy.detail).font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.appPrimaryText).fixedSize().padding(.horizontal, 8).padding(.vertical, 3).background(Color.appAccent.opacity(0.3), in: Capsule()) }
                    }
                    if plan == .yearly && store.trialEligible { Text("3 days free to start").font(Theme.font(.caption)).foregroundStyle(Color.successText) }
                    if let extra { Text(extra).font(Theme.font(.caption)).foregroundStyle(Color.secondaryText) }
                }
                Spacer()
                Text(product.map { $0.displayPrice + (plan == .yearly ? "/yr" : "/mo") } ?? "").font(Theme.font(.headline))
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle").foregroundStyle(isSelected ? Color.successText : Color.appPrimaryText.opacity(0.3))
            }
            .foregroundStyle(Color.appPrimaryText)
            .padding(Space.card).frame(maxWidth: .infinity)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(isSelected ? Color.successText : Color.appPrimaryText.opacity(0.1), lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var activeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Label("You have WordFlora Plus", systemImage: "sparkles").font(Theme.font(.headline)).foregroundStyle(Color.successText)
                Text("Ads are off and your garden can sync across your devices. Thank you for supporting WordFlora.").font(Theme.font(.callout))
            }
        }
    }

    // MARK: Purchase and parental gate

    private func buy() {
        if ParentalGate.isRequired(ageBand: app.settings.ageBand) {
            gate = ParentalGate.challenge(seed: UInt64(Date().timeIntervalSince1970))
        } else { startPurchase() }
    }

    private func startPurchase() {
        busy = true; message = nil
        Task {
            let outcome = await store.purchase(selected)
            busy = false
            switch outcome {
            case .success: message = "Welcome to WordFlora Plus!"; app.updateSyncFlag()
            case .pending: message = "Almost there. If Plus is not on in a moment, tap Restore purchases."
            case .cancelled: message = nil
            case .failed: message = "We couldn't confirm that purchase. If you see a charge, tap Restore purchases."
            }
        }
    }

}

extension ParentalGate.Challenge: Identifiable { var id: String { question } }

/// The grown-up question, used before a purchase and before any link that leaves the app.
struct ParentalGateSheet: View {
    let challenge: ParentalGate.Challenge
    let onPass: () -> Void
    let onCancel: () -> Void
    @State private var answer = ""
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 16) {
            Text(ParentalGate.Copy.title).font(Theme.font(.title2, weight: .bold))
            Text(ParentalGate.Copy.prompt).font(Theme.font(.callout)).multilineTextAlignment(.center)
            Text(challenge.question).font(Theme.font(.title, weight: .heavy))
            TextField("Answer", text: $answer).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(maxWidth: 160).multilineTextAlignment(.center)
                .accessibilityIdentifier("parentalGate.answer")
            if wrong { Text(ParentalGate.Copy.wrong).font(Theme.font(.footnote)).foregroundStyle(Color.appDanger) }
            Button("Continue") {
                if ParentalGate.check(answer: answer, against: challenge) { onPass() } else { wrong = true }
            }.buttonStyle(PrimaryButtonStyle())
            Button("Cancel") { onCancel() }.frame(minHeight: Theme.minTap)
        }
        .padding(24).presentationDetents([.medium])
    }
}

/// A link that leaves the app (web page, mail, subscription management). Adults and 13 to 17 open it at once;
/// under 13 and an unknown age answer the grown-up question first (`ParentalGate.outbound`).
struct GatedLink: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openURL) private var openURL
    @State private var gate: ParentalGate.Challenge?
    private let title: String
    private let url: URL

    init(_ title: String, url: URL) { self.title = title; self.url = url }

    var body: some View {
        Button(title) {
            switch ParentalGate.outbound(url, ageBand: app.settings.ageBand) {
            case .open(let u): openURL(u)
            case .askFirst: gate = ParentalGate.challenge(seed: UInt64(Date().timeIntervalSince1970))
            }
        }
        .sheet(item: $gate) { challenge in
            ParentalGateSheet(challenge: challenge, onPass: { gate = nil; openURL(url) }, onCancel: { gate = nil })
        }
    }
}

enum Links {
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// The hosted privacy policy (also entered in App Store Connect).
    static let privacy = URL(string: "https://shapehaveninnovations.com/privacy")!
    /// Google's AdMob help centre, where an ad can be reported.
    static let reportAd = URL(string: "https://support.google.com/admob")!
}

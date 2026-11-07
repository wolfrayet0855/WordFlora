import SwiftUI
import StoreKit
import UIKit

struct PlusView: View {
    @Environment(AppModel.self) private var app
    @State private var selected: PlusChoice = .yearly
    @State private var busy = false
    @State private var message: String?
    @State private var gate: ParentalGate.Challenge?
    /// What a passed grown-up question goes on to do: buy, redeem a code, or open subscription management.
    @State private var afterGate: GatedAction = .purchase
    @State private var showManageSubscriptions = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum GatedAction { case purchase, redeem, manageSubscriptions }

    private var store: EntitlementService { app.entitlements }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Young players and unknown ages: one calm line first, so the page reads as information for a grown-up.
                if let intro = PlusEntry.intro(ageBand: app.settings.ageBand) {
                    Text(intro).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("plus.grownUpsIntro")
                }
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
                    Button(PaywallCopy.redeem) { ask(then: .redeem) }.tapTarget()
                        .accessibilityIdentifier("plus.redeem")
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
            ParentalGateSheet(challenge: challenge, onPass: { gate = nil; run(afterGate) }, onCancel: { gate = nil })
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
    }

    // MARK: Plans

    @ViewBuilder private var plans: some View {
        if store.loadFailed && !store.offersAnything {
            Card { Text("We couldn't load the plans. Check your connection and try again.").font(Theme.font(.callout)) }
            Button("Try again") { Task { await store.loadProducts() } }.buttonStyle(SecondaryButtonStyle())
        } else {
            let yearlyPrice = store.price(for: .yearly).map { ($0 as NSDecimalNumber).doubleValue } ?? 0
            let monthlyPrice = store.price(for: .monthly).map { ($0 as NSDecimalNumber).doubleValue } ?? 0
            VStack(spacing: 12) {
                planCard(.yearly, extra: yearlyPrice > 0 ? "About \(perMonthText(yearlyPrice)) a month · save \(PaywallMath.savingsPercent(yearly: yearlyPrice, monthly: monthlyPrice))%" : nil)
                planCard(.monthly, extra: nil)
                // While the store loads every row waits (as the plans do); once it answers without Plus Forever, no row.
                if store.offers(.lifetime) || !store.offersAnything { lifetimeCard }
            }
            let price = store.displayPrice(for: selected) ?? ""
            let copy = PaywallCopy.make(choice: selected, displayPrice: price, trialEligible: store.trialEligible && selected == .yearly)
            Button { ask(then: .purchase) } label: { Text(busy ? "One moment…" : copy.cta) }
                .buttonStyle(PrimaryButtonStyle()).disabled(busy || !store.offers(selected))
            Text(copy.finePrint).font(Theme.font(.caption)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
            if let message { Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText).multilineTextAlignment(.center) }
        }
    }

    /// Formatted in the store's own currency, never a hard-coded "$".
    private func perMonthText(_ yearly: Double) -> String {
        store.formatted(Decimal(PaywallMath.perMonth(yearly: yearly)), like: .yearly)
    }

    private func planCard(_ plan: PlusPlan, extra: String?) -> some View {
        let choice: PlusChoice = plan == .yearly ? .yearly : .monthly
        let shown = store.displayPrice(for: choice)
        let copy = PaywallCopy.make(plan: plan, displayPrice: shown ?? "", trialEligible: false)
        var lines = [(String, Color)]()
        if plan == .yearly && store.trialEligible { lines.append(("3 days free to start", .successText)) }
        if let extra { lines.append((extra, .secondaryText)) }
        return choiceCard(choice, title: copy.headline, badge: plan == .yearly ? copy.detail : nil,
                          lines: lines, price: shown.map { $0 + (plan == .yearly ? "/yr" : "/mo") } ?? "")
    }

    /// Plus Forever: the third choice, under the two plans. Same card and type sizes, no badge, never the default.
    private var lifetimeCard: some View {
        choiceCard(.lifetime, title: PlusPlan.lifetimeName, badge: nil,
                   lines: [(PaywallCopy.lifetimeLine, .secondaryText)], price: store.displayPrice(for: .lifetime) ?? "")
            .accessibilityIdentifier("plus.lifetime")
    }

    /// One layout at every text size: the words and the price stack on the left and wrap, the choice circle sits on
    /// the right, so nothing is pushed off the screen at the largest accessibility sizes.
    private func choiceCard(_ choice: PlusChoice, title: String, badge: String?, lines: [(String, Color)], price: String) -> some View {
        let isSelected = selected == choice
        return Button { selected = choice } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    // At accessibility sizes the badge goes on its own line under the headline, so "Yearly" keeps the
                    // full width and never breaks beside a wrapped badge. Same views, only the stack's axis changes.
                    let titleRow = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                        : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
                    titleRow {
                        Text(title).font(Theme.font(.headline)).fixedSize(horizontal: false, vertical: true)
                        if let badge {
                            Text(badge).font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 8).padding(.vertical, 3).background(Color.appAccent.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    ForEach(lines, id: \.0) { line in
                        Text(line.0).font(Theme.font(.caption)).foregroundStyle(line.1).fixedSize(horizontal: false, vertical: true)
                    }
                    Text(price).font(Theme.font(.headline)).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle").foregroundStyle(isSelected ? Color.successText : Color.appPrimaryText.opacity(0.3))
            }
            .foregroundStyle(Color.appPrimaryText)
            .padding(Space.card).frame(maxWidth: .infinity)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(isSelected ? Color.successText : Color.appPrimaryText.opacity(0.1), lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var activeCard: some View {
        let lifetime = store.state.hasLifetime
        return Card {
            VStack(alignment: .leading, spacing: 6) {
                Label(lifetime ? PaywallCopy.ownedLifetime : "You have WordFlora Plus", systemImage: "sparkles").font(Theme.font(.headline)).foregroundStyle(Color.successText)
                Text(lifetime ? PaywallCopy.ownedLifetimeDetail : "Ads are off and your garden can sync across your devices. Thank you for supporting WordFlora.").font(Theme.font(.callout))
                    .fixedSize(horizontal: false, vertical: true)
                // Apple never cancels a subscription when Plus Forever is bought, so say it plainly.
                if store.state.paysTwice {
                    Text(PaywallCopy.paysTwice).font(Theme.font(.callout, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("plus.paysTwice")
                    Button(PaywallCopy.cancelSubscription) { ask(then: .manageSubscriptions) }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    // MARK: Purchase and parental gate

    /// Young players and unknown ages answer the grown-up question before any purchase, code or store sheet.
    private func ask(then action: GatedAction) {
        afterGate = action
        if ParentalGate.isRequired(ageBand: app.settings.ageBand) {
            gate = ParentalGate.challenge(seed: UInt64(Date().timeIntervalSince1970))
        } else { run(action) }
    }

    private func run(_ action: GatedAction) {
        switch action {
        case .purchase: startPurchase()
        case .redeem: redeemCode()
        case .manageSubscriptions: showManageSubscriptions = true
        }
    }

    /// Apple's own code sheet. A redeemed code also arrives through `Transaction.updates`, which the service listens
    /// to; the refresh here just makes the page change the moment the sheet closes.
    private func redeemCode() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else { return }
        Task {
            try? await AppStore.presentOfferCodeRedeemSheet(in: scene)
            await store.refresh()
            app.updateSyncFlag()
        }
    }

    private func startPurchase() {
        busy = true; message = nil
        Task {
            let outcome = await store.purchase(selected)
            busy = false
            switch outcome {
            case .success: message = selected == .lifetime ? PaywallCopy.welcomeLifetime : "Welcome to WordFlora Plus!"; app.updateSyncFlag()
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

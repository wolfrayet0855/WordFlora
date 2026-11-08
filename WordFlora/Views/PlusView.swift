import SwiftUI
import StoreKit
import UIKit

struct PlusView: View {
    @Environment(AppModel.self) private var app
    @State private var selected: PlusChoice = .yearly
    @State private var busy = false
    @State private var restoring = false
    @State private var retrying = false
    @State private var message: String?
    @State private var gate: ParentalGate.Challenge?
    /// What a passed grown-up question goes on to do: buy, redeem a code, or open subscription management.
    @State private var afterGate: GatedAction = .purchase
    @State private var showManageSubscriptions = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    /// Counts the moments Plus turned on here (the haptic's trigger).
    @State private var turnedOn = 0

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
                FlowerView(petals: 8).frame(height: 120).accessibilityHidden(true)
                Text(PlusPlan.groupName).font(Theme.font(.largeTitle, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(PaywallCopy.benefits, id: \.self) { b in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.successText).accessibilityHidden(true)
                            Text(b).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)

                if store.state.hasPlus {
                    activeCard.transition(reduceMotion ? .opacity : .scale(scale: 0.96).combined(with: .opacity))
                } else { plans }
                // Outside the plans, so a message (a restore that turned Plus on) stays in view when the plans go.
                if let message {
                    Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("plus.message")
                }

                VStack(spacing: 2) {
                    Button { restore() } label: {
                        HStack(spacing: 6) {
                            if restoring { ProgressView().accessibilityHidden(true) }
                            Text(PaywallCopy.restore)
                        }
                    }
                    .tapTarget().disabled(restoring)
                    .accessibilityIdentifier("plus.restore")
                    Button(PaywallCopy.redeem) { ask(then: .redeem) }.tapTarget()
                        .accessibilityIdentifier("plus.redeem")
                    // Only with a live subscription: a non-subscriber has nothing to manage.
                    if store.state.hasActiveSubscription {
                        GatedLink("Manage subscription", url: Links.manageSubscriptions).tapTarget()
                    }
                    // Side by side, one under the other at the accessibility sizes.
                    let links = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 2)) : AnyLayout(HStackLayout(spacing: 8))
                    links {
                        GatedLink("Terms of Use", url: Links.terms).tapTarget()
                        GatedLink("Privacy Policy", url: Links.privacy).tapTarget()
                    }
                }
                .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card).padding(.bottom, Space.section)
            // The plans give way to the active card with a soft spring (a fade with Reduce Motion).
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8), value: store.state.hasPlus)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Plus")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadProducts() }
        .sheet(item: $gate) { challenge in
            ParentalGateSheet(challenge: challenge, onPass: { gate = nil; run(afterGate) }, onCancel: { gate = nil })
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .onChange(of: message) { _, new in if let new { AccessibilityNotification.Announcement(new).post() } }
        .sensoryFeedback(.success, trigger: turnedOn) { _, _ in app.settings.hapticsOn }
    }

    private var reduceMotion: Bool { systemReduceMotion || app.settings.reduceMotionOverride }

    // MARK: Plans

    @ViewBuilder private var plans: some View {
        if store.loadFailed && !store.offersAnything {
            Card {
                Text(PaywallCopy.loadFailed).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button { retry() } label: {
                HStack(spacing: 8) {
                    if retrying { ProgressView().accessibilityHidden(true) }
                    Text(PaywallCopy.tryAgain)
                }
            }
            .buttonStyle(SecondaryButtonStyle()).disabled(retrying)
            .accessibilityIdentifier("plus.tryAgain")
        } else {
            let yearlyPrice = store.price(for: .yearly).map { ($0 as NSDecimalNumber).doubleValue } ?? 0
            let monthlyPrice = store.price(for: .monthly).map { ($0 as NSDecimalNumber).doubleValue } ?? 0
            VStack(spacing: 12) {
                planCard(.yearly, extra: yearlyPrice > 0 ? yearlyExtra(yearly: yearlyPrice, monthly: monthlyPrice) : nil)
                planCard(.monthly, extra: nil)
                // While the store loads every row waits (as the plans do); once it answers without Plus Forever, no row.
                if store.offers(.lifetime) || !store.offersAnything { lifetimeCard }
            }
            if store.offers(selected) {
                let price = store.displayPrice(for: selected) ?? ""
                let copy = PaywallCopy.make(choice: selected, displayPrice: price, trialEligible: store.trialEligible && selected == .yearly)
                Button { ask(then: .purchase) } label: {
                    Text(busy ? "One moment…" : copy.cta).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                }
                .buttonStyle(PrimaryButtonStyle()).disabled(busy)
                Text(copy.finePrint).font(Theme.font(.caption)).multilineTextAlignment(.center).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("plus.finePrint")
            } else {
                // The prices are still on their way: no button that does nothing and no fine print without a price.
                HStack(spacing: 10) {
                    ProgressView().accessibilityHidden(true)
                    Text(PaywallCopy.loadingPrices).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("plus.loading")
            }
        }
    }

    /// "About $1.08 a month", and "· save 73%" only once the monthly price is known.
    private func yearlyExtra(yearly: Double, monthly: Double) -> String {
        let perMonth = "About \(perMonthText(yearly)) a month"
        return monthly > 0 ? "\(perMonth) · save \(PaywallMath.savingsPercent(yearly: yearly, monthly: monthly))%" : perMonth
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
                          lines: lines, price: shown.map { PaywallCopy.priceLine($0, choice: choice) })
    }

    /// Plus Forever: the third choice, under the two plans. Same card and type sizes, no badge, never the default.
    private var lifetimeCard: some View {
        // "$34.99 once" says it; the fine print under the button carries the full line when it is picked.
        choiceCard(.lifetime, title: PlusPlan.lifetimeName, badge: nil,
                   lines: [],
                   price: store.displayPrice(for: .lifetime).map { PaywallCopy.priceLine($0, choice: .lifetime) })
            .accessibilityIdentifier("plus.lifetime")
    }

    /// One layout at every text size: the words and the price stack on the left and wrap, the choice circle sits on
    /// the right, so nothing is pushed off the screen at the largest accessibility sizes. No price line while loading.
    private func choiceCard(_ choice: PlusChoice, title: String, badge: String?, lines: [(String, Color)], price: String?) -> some View {
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
                    if let price {
                        Text(price).font(Theme.font(.headline)).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // At least 3:1 against the card in both modes (PuzzleInk.blankOutline); the card says "Selected" itself.
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.successText : Color.appPrimaryText.opacity(PuzzleInk.blankOutline))
                    .accessibilityHidden(true)
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
                Label(lifetime ? PaywallCopy.ownedLifetime : PaywallCopy.ownedSubscription, systemImage: "sparkles")
                    .font(Theme.font(.headline)).foregroundStyle(Color.successText)
                    .fixedSize(horizontal: false, vertical: true)
                // Which plan, and until when ("Yearly plan · renews Nov 7, 2027"); Plus Forever: "Paid once. No renewals."
                Text(lifetime ? PaywallCopy.ownedLifetimeDetail
                              : PaywallCopy.planLine(plan: store.state.activePlan ?? .yearly, renews: store.state.subscriptionRenews,
                                                     endsAt: store.state.subscriptionEndsAt))
                    .font(Theme.font(.callout)).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("plus.planLine")
                // Apple never cancels a subscription when Plus Forever is bought, so say it plainly.
                if store.state.paysTwice {
                    Text(PaywallCopy.paysTwice).font(Theme.font(.callout, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("plus.paysTwice")
                    Button(PaywallCopy.cancelSubscription) { ask(then: .manageSubscriptions) }
                        .buttonStyle(SecondaryButtonStyle())
                } else if let ends = store.state.subscriptionEndsBesideLifetime {
                    // Auto-renew is already off, so nothing more is charged: one calm line, no button.
                    Text(PaywallCopy.subscriptionEnds(on: ends.formatted(date: .long, time: .omitted)))
                        .font(Theme.font(.callout)).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("plus.subscriptionEnds")
                }
            }
        }
    }

    // MARK: Purchase, restore and parental gate

    private func retry() {
        retrying = true
        Task { await store.loadProducts(); retrying = false }
    }

    /// One sync at a time, then a line that says what happened.
    private func restore() {
        guard !restoring else { return }
        restoring = true; message = nil
        Task {
            await store.restore()
            app.updateSyncFlag()
            restoring = false
            message = store.state.hasPlus ? PaywallCopy.restoredOn : PaywallCopy.restoredNone
        }
    }

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
            // Plus is on: one clear moment (the card springs in, a success haptic, a line VoiceOver reads too).
            case .success:
                app.updateSyncFlag()
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)) {
                    message = PaywallCopy.justOn(adsWereOn: !ParentalGate.isRequired(ageBand: app.settings.ageBand),
                                                 syncNeedsRestart: app.syncNeedsRestart)
                }
                turnedOn += 1
            case .pending: message = PaywallCopy.pendingSlow
            case .awaitingApproval: message = PaywallCopy.awaitingApproval
            case .cancelled: message = nil
            case .failed: message = PaywallCopy.failed
            }
        }
    }

}

extension ParentalGate.Challenge: Identifiable { var id: String { question } }
/// The grown-up question, used before a purchase and before any link that leaves the app. It scrolls, so Continue and
/// Cancel stay reachable at every text size, with the number pad up too; full height at the accessibility sizes.
struct ParentalGateSheet: View {
    let challenge: ParentalGate.Challenge
    let onPass: () -> Void
    let onCancel: () -> Void
    @State private var answer = ""
    @State private var wrong = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(ParentalGate.Copy.title).font(Theme.font(.title2, weight: .bold))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(ParentalGate.Copy.prompt).font(Theme.font(.callout)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(challenge.question).font(Theme.font(.title, weight: .heavy))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                TextField("Answer", text: $answer).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    .font(Theme.font(.body))
                    .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 160).multilineTextAlignment(.center)
                    .accessibilityIdentifier("parentalGate.answer")
                if wrong {
                    // Ink with an icon, not the danger red (3.69:1 on white in light mode).
                    Label(ParentalGate.Copy.wrong, systemImage: "exclamationmark.circle")
                        .font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("parentalGate.wrong")
                }
                Button {
                    if ParentalGate.check(answer: answer, against: challenge) { onPass() } else { wrong = true }
                } label: {
                    Text("Continue").multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Cancel") { onCancel() }.frame(minHeight: Theme.minTap)
            }
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large])
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

import SwiftUI

/// Settings > Plus > Seasons: the seasonal packs (one today, Frost & Lantern). Young players and unknown ages reach it
/// only through the grown-up question, and answer it again before a purchase. Plus does not include packs.
/// No countdowns and no "only today": a pack stays on sale.
struct SeasonsView: View {
    @Environment(AppModel.self) private var app
    @State private var busy = false
    @State private var message: String?
    @State private var gate: ParentalGate.Challenge?

    private var store: EntitlementService { app.entitlements }

    var body: some View {
        let packs = PackCatalog.ordered(on: .now).filter { store.packIsLive($0.id) }
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(packs) { packSection($0) }
                if packs.isEmpty {
                    Text("Nothing here right now.").font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                }
                Button(PackCatalog.Copy.restore) { Task { await store.restore() } }
                    .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText).tapTarget()
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("seasons.restore")
            }
            .padding(.horizontal, Space.gutter).padding(.vertical, Space.card).padding(.bottom, Space.section)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(PackCatalog.Copy.seasonsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadPackProducts() }
        .sheet(item: $gate) { challenge in
            ParentalGateSheet(challenge: challenge, onPass: { gate = nil; buy(PackCatalog.frostLantern.id) }, onCancel: { gate = nil })
        }
    }

    private func packSection(_ pack: SeasonPack) -> some View {
        let owned = store.ownsPack(pack.id)
        return VStack(alignment: .leading, spacing: 12) {
            PackCardArt()
            VStack(alignment: .leading, spacing: 8) {
                Text(pack.name).font(Theme.font(.title2, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(pack.line).font(Theme.font(.body)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                PackPotsRow(pack: pack)
                ForEach([PackCatalog.Copy.badgeLine, PackCatalog.Copy.keepLine, PackCatalog.Copy.notPlus], id: \.self) { line in
                    Text(line).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if owned {
                    Label(PackCatalog.Copy.ownedLine, systemImage: "checkmark.circle.fill")
                        .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("seasons.owned")
                } else if let price = store.packDisplayPrice(pack.id) {
                    Text(price).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                        .accessibilityIdentifier("seasons.price")
                    Button { ask(pack) } label: {
                        Text(busy ? "One moment…" : "\(PackCatalog.Copy.buy) \(pack.name)")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(PrimaryButtonStyle()).disabled(busy)
                    .accessibilityIdentifier("seasons.buy")
                }
                if let message {
                    Text(message).font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("seasons.message")
                }
            }
            .padding(Space.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("seasons.pack.\(pack.id)")
    }

    /// Young players and unknown ages answer the grown-up question before the purchase.
    private func ask(_ pack: SeasonPack) {
        if ParentalGate.isRequired(ageBand: app.settings.ageBand) {
            gate = ParentalGate.challenge(seed: UInt64(Date().timeIntervalSince1970))
        } else { buy(pack.id) }
    }

    private func buy(_ id: String) {
        busy = true; message = nil
        Task {
            let outcome = await store.purchasePack(id)
            busy = false
            switch outcome {
            case .success: message = PackCatalog.Copy.welcome
            case .pending: message = PackCatalog.Copy.pending
            case .cancelled: message = nil
            case .failed: message = PackCatalog.Copy.failed
            }
        }
    }
}

/// The pack's card art (light and dark), with no words in it: the app draws every word below it on `appSurface`.
struct PackCardArt: View {
    var body: some View {
        Image("pack_frost_lantern_card").resizable().scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .accessibilityLabel(PackCatalog.Copy.cardLabel)
            .accessibilityAddTraits(.isImage)
    }
}

/// The pack's three pots in full colour with their names (a grown-up's view: this is what the pack holds).
struct PackPotsRow: View {
    let pack: SeasonPack
    var body: some View {
        let pots = pack.allPotIds.map(PotCatalog.pot(id:))
        VStack(alignment: .leading, spacing: 6) {
            ForEach(pots) { pot in
                HStack(spacing: 10) {
                    PotArtView(pot: pot, width: 40).accessibilityHidden(true)
                    Text(pot.id == pack.earnedPotId ? "\(pot.name) (earned with Daily Blooms)" : pot.name)
                        .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// The 13+ Seasons shelf in the Shed: the card art, the pack's name and line, the price (or "you have it"), and a way
/// to the Seasons page. Never for under 13 or an unknown age, and not in Quiet Garden (no prices there).
struct ShedSeasonsShelf: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    let pack: SeasonPack

    var body: some View {
        let store = app.entitlements
        VStack(alignment: .leading, spacing: 10) {
            Text(PackCatalog.Copy.shelfTitle.uppercased()).font(Theme.font(.footnote, weight: .heavy)).tracking(1.2)
                .foregroundStyle(Color.secondaryText)
                .accessibilityLabel(PackCatalog.Copy.shelfTitle).accessibilityAddTraits(.isHeader)
            PackCardArt()
            VStack(alignment: .leading, spacing: 6) {
                Text(pack.name).font(Theme.font(.headline, weight: .bold)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(pack.line).font(Theme.font(.subheadline)).foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if store.ownsPack(pack.id) {
                    Text(PackCatalog.Copy.ownedLine).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.successText)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let price = store.packDisplayPrice(pack.id) {
                    Text(price).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                        .accessibilityIdentifier("shed.seasons.price")
                }
                Button(PackCatalog.Copy.shelfButton) { router.go(.seasons) }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("shed.seasons.open")
            }
            .padding(Space.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shed.seasons")
    }

    /// Who sees the shelf: 13 and up, not Quiet Garden, while the pack is live.
    static func isShown(ageBand: AgeBand?, quietGarden: Bool, live: Bool) -> Bool {
        live && !quietGarden && !ParentalGate.isRequired(ageBand: ageBand)
    }
}

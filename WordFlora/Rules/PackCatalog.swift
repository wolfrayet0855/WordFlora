import Foundation

/// One seasonal pack: a non-consumable with Family Sharing on. Ownership is read from StoreKit every time (nothing
/// stored). Plus does not include packs.
struct SeasonPack: Equatable, Identifiable {
    let id: String
    let productID: String
    let name: String
    /// What the pack holds, said plainly (the Seasons page and the Shed shelf).
    let line: String
    /// The season it is featured in, as month/day pairs (inclusive, may wrap the new year). Used only for the earned
    /// pot's pace and the Seasons row's order: no countdowns, nothing goes away.
    let featuredFrom: (month: Int, day: Int)
    let featuredTo: (month: Int, day: Int)
    /// The pot that comes with the pack (owned while the pack is owned).
    let potIds: [String]
    /// The season's pot earned by play (Daily Blooms), shown while the pack is live.
    let earnedPotId: String?
    /// The badge earned by play only (never bought).
    let badgeId: String

    static func == (a: SeasonPack, b: SeasonPack) -> Bool { a.id == b.id }

    var allPotIds: [String] { (earnedPotId.map { [$0] } ?? []) + potIds }
}

/// The seasonal pack framework (release plan G3). A pack's surfaces (the pot outlines, the Seasons row, the Shed
/// shelf, its badge) appear only while the pack is live: the store offers it, or the player owns it. With no product
/// from StoreKit nothing shows (the dormant framework).
enum PackCatalog {
    static let frostLanternId = "frostLantern"

    static let frostLantern = SeasonPack(
        id: frostLanternId, productID: "pack_frost_lantern", name: "Frost & Lantern",
        line: "Three winter pots for your garden. Pay once, no renewals.",
        featuredFrom: (12, 1), featuredTo: (2, 28),
        potIds: [PotCatalog.lanternRed.id, PotCatalog.snowflakeIndigo.id],
        earnedPotId: PotCatalog.frostedGlass.id, badgeId: "lantern_keeper")

    static let all: [SeasonPack] = [frostLantern]
    static var productIDs: Set<String> { Set(all.map(\.productID)) }

    static func pack(id: String) -> SeasonPack? { all.first { $0.id == id } }
    static func pack(productID: String) -> SeasonPack? { all.first { $0.productID == productID } }
    static func pack(ofPot potId: String) -> SeasonPack? { all.first { $0.allPotIds.contains(potId) } }

    /// The packs owned, from the entitlement's live product ids.
    static func owned(activeProductIDs: Set<String>) -> Set<String> {
        Set(all.filter { activeProductIDs.contains($0.productID) }.map(\.id))
    }

    /// A pack is live when the store offers it or the player owns it. No product and not owned: no surface at all.
    static func isLive(_ pack: SeasonPack, offered: Bool, owned: Bool) -> Bool { offered || owned }

    // MARK: Season featuring (pace and order only)

    static func isFeatured(_ pack: SeasonPack, on date: Date, calendar: Calendar = .current) -> Bool {
        let c = calendar.dateComponents([.month, .day], from: date)
        let md = (c.month ?? 1) * 100 + (c.day ?? 1)
        let from = pack.featuredFrom.month * 100 + pack.featuredFrom.day
        let to = pack.featuredTo.month * 100 + pack.featuredTo.day
        return from <= to ? (md >= from && md <= to) : (md >= from || md <= to)
    }

    /// The Seasons row's order: packs in their season first, then the rest in catalogue order.
    static func ordered(on date: Date, calendar: Calendar = .current, packs: [SeasonPack] = all) -> [SeasonPack] {
        packs.filter { isFeatured($0, on: date, calendar: calendar) } + packs.filter { !isFeatured($0, on: date, calendar: calendar) }
    }

    // MARK: The season's earned pot (Daily Blooms, marks in badgesJSON)

    /// A Daily Bloom done on a featured day counts a whole day; on any other day half a day (the slower pace).
    /// The mark item is the day number with its kind, so a day counts once and two devices merge by union.
    static func bloomMarkItem(day: Int, featured: Bool) -> String { (featured ? "in." : "out.") + String(day) }

    /// Progress in half days from the marks: 2 per featured day, 1 per other day.
    static func seasonHalfDays(featuredDays: Int, otherDays: Int) -> Int { 2 * featuredDays + otherDays }

    enum Copy {
        static let seasonsTitle = "Seasons"
        static let seasonsRowSub = "Seasonal pots and more"
        static let ownedLine = "You have this pack. Its pots are in your Shed."
        static let buy = "Buy"
        static let restore = "Restore purchases"
        static let notPlus = "Packs are separate from Plus."
        static let badgeLine = "The Lantern Keeper badge is earned by play: grow plants in the Frosted glass pot."
        static let keepLine = "A pack pot already on a plant stays on it."
        static let shelfTitle = "Seasons"
        static let shelfButton = "Take a look"
        static let cardLabel = "Three winter pots on a snowy shelf, with lanterns and a robin"
        static let welcome = "Frost & Lantern is yours. Its pots are in your Shed."
        static let pending = "Almost there. If the pots are not there in a moment, tap Restore purchases."
        static let failed = "We couldn't confirm that purchase. If you see a charge, tap Restore purchases."
        /// Ask to Buy: a grown-up must approve first, maybe much later.
        static let awaitingApproval = "Sent to a grown-up to approve. The pots arrive once it's approved."
        /// After Restore purchases: a pack came back, or nothing was found.
        static let restoredPack = "Your pack is back. Its pots are in your Shed."
        static let restoredNone = PaywallCopy.restoredNone
        static var all: [String] {
            [seasonsTitle, seasonsRowSub, ownedLine, buy, restore, notPlus, badgeLine, keepLine, shelfTitle, shelfButton,
             cardLabel, welcome, pending, failed, awaitingApproval, restoredPack, restoredNone, frostLantern.line,
             frostLantern.name, PotCatalog.packHint, PotCatalog.frostedGlass.hint]
        }
    }
}

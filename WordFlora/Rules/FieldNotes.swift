import Foundation

/// Field Notes (docs/pm/badge-mechanics-art.md, section 1): a notebook page per friend met in the Visitors' book. A page
/// is collected (a leaf stamp lands) only when its fact is read aloud to the end or the child taps "I read it!", never
/// when the page is opened. Pure, so each rule is unit tested; `AppModel.collectFieldNote` records the mark.
enum FieldNotes {
    /// A page can be collected for a visitor in the catalogue that has a fact and has been met. Weather stickers are not
    /// visitors, so they never count; a made-up id is ignored.
    static func canCollect(_ speciesId: String, album: StickerAlbum) -> Bool {
        // The notebook holds the twelve friends only; a season friend's fact lives on its album card.
        guard let v = VisitorCatalog.species(speciesId), v.fact != nil, v.packId == nil else { return false }
        return album.count(of: v.id) > 0
    }

    /// The pages collected so far (catalogue friends only), for the "4 pages of 12" line.
    static func collected(in badges: BadgeState) -> Int {
        VisitorCatalog.all.filter { badges.isMarked(.factsRead, item: $0.id) }.count
    }

    /// Quiet Garden: pages, facts and Listen all work, but there is no "I read it!", no stamp landing and no count.
    static func showsReadIt(quiet: Bool) -> Bool { !quiet }
    static func showsPageCount(quiet: Bool) -> Bool { !quiet }
    /// Listen hides while VoiceOver runs (VoiceOver reads the page itself), so "I read it!" is the path there.
    static func showsListen(voiceOverRunning: Bool) -> Bool { ReadAloud.shouldOffer(voiceOverRunning: voiceOverRunning) }

    /// What the button under a met page shows.
    enum ReadItButton: Equatable { case readIt, stamped, hidden }
    static func readItButton(stamped: Bool, quiet: Bool) -> ReadItButton {
        guard showsReadIt(quiet: quiet) else { return .hidden }
        return stamped ? .stamped : .readIt
    }

    /// One Listen at a time. A finish counts only for the page that is still the one being read: a newer Listen, a stop
    /// or leaving the book makes the earlier one stale, so its finish marks nothing.
    struct Listening: Equatable {
        private(set) var page: String?
        private(set) var token = 0

        /// Starts reading a page and returns the token its finish must bring back.
        mutating func start(_ page: String) -> Int { token += 1; self.page = page; return token }
        /// Stopped, cancelled or the page went away: nothing is read to the end.
        mutating func cancel() { page = nil }
        /// The voice reached the end. Returns the page to collect, once.
        mutating func finish(token t: Int) -> String? {
            guard t == token, let p = page else { return nil }
            page = nil
            return p
        }
        var isReading: Bool { page != nil }
    }
}

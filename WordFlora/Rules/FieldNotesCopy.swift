import Foundation

/// Words for the Field Notes notebook in the Visitors' book (docs/pm/badge-mechanics-art.md, section 1).
/// A page is collected when the fact is read aloud to the end (`ReadAloud` didFinish) or the child taps "I read it!",
/// never when the page is only opened. Positive only, grade 2-3; every line is checked by CopySafety.
enum FieldNotesCopy {
    // Buttons
    static let listen = "Listen"
    static let readIt = "I read it!"
    /// The "I read it!" button once the page has its stamp (not tappable again).
    static let stamped = "Stamped"

    // Lines
    static let pageAdded = "Page added to your notebook."
    static let unmetPage = "Meet this friend to fill this page."
    static let unmetTitle = "A new friend"
    static let notebookTitle = "My field notes"
    static let blurb = "Fill your notebook with friend facts"

    /// "Seen on 4 Nov" from `StickerAlbum.seenAt`, which keeps the latest meeting (the caller formats the date, day
    /// and short month). Not "Met on": that would read as the first meeting, and the date moves on each time.
    static func metOn(_ date: String) -> String { "Seen on \(date)" }

    /// The notebook's page count, shown under the title. Never shown in Quiet Garden.
    static func pages(_ n: Int, of total: Int) -> String { n == 1 ? "1 page of \(total)" : "\(n) pages of \(total)" }

    // Accessibility
    static let listenHint = "Reads the fact out loud"
    static let readItHint = "Adds a leaf stamp to this page"
    static let stampLabel = "Leaf stamp"
    /// The whole page reads as one element: name, the date it was seen (when the album has one), fact, then whether it
    /// has its stamp. Friends met before dates were kept have none, so that sentence is left out.
    static func pageLabel(name: String, met: String?, fact: String, stamped: Bool) -> String {
        "\(name)." + (met.map { " \(metOn($0))." } ?? "") + " \(fact)" + (stamped ? " \(stampLabel)." : "")
    }
    /// A friend not met yet.
    static let unmetLabel = "A new friend. Meet this friend to fill this page."

    /// Every fixed line, plus samples of the formatted ones, for the CopySafety sweep.
    static var all: [String] {
        [listen, readIt, stamped, pageAdded, unmetPage, unmetTitle, notebookTitle, blurb,
         metOn("4 Nov"), pages(1, of: 12), pages(4, of: 12), listenHint, readItHint, stampLabel, unmetLabel,
         pageLabel(name: "Monarch", met: "4 Nov", fact: "Monarchs fly a long way every year.", stamped: true),
         pageLabel(name: "Monarch", met: "4 Nov", fact: "Monarchs fly a long way every year.", stamped: false),
         pageLabel(name: "Monarch", met: nil, fact: "Monarchs fly a long way every year.", stamped: false)]
    }
}

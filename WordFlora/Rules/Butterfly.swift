import Foundation

struct VisitorSpecies: Equatable {
    var id: String
    var name: String
    var rarity: VisitorCatalog.Rarity
    var nightOnly = false
    /// A season pack's friend (`VisitorCatalog.season`): visits only for the pack's owners. Nil for the twelve.
    var packId: String? = nil
    /// Only fact-checked lines ship; every visitor has one (tested).
    var fact: String?
}

enum VisitorCatalog {
    enum Rarity: Hashable {
        case common, uncommon, rare
        /// How often a visitor comes, in plain words (shown on album cards).
        var label: String {
            switch self { case .common: return "Often seen"; case .uncommon: return "Sometimes seen"; case .rare: return "Rare visitor" }
        }
    }

    // Grade 2-3 facts, each checked against a source (docs/research/visitor-facts.md).
    static let all: [VisitorSpecies] = [
        VisitorSpecies(id: "monarch", name: "Monarch", rarity: .uncommon, fact: "Monarch butterflies can fly up to 3,000 miles to a warm place for winter."),
        VisitorSpecies(id: "swallowtail", name: "Swallowtail", rarity: .uncommon, fact: "A swallowtail has long points on its back wings that look like tails."),
        VisitorSpecies(id: "cabbagewhite", name: "Cabbage White", rarity: .common, fact: "Baby cabbage whites are green caterpillars that love to eat cabbage leaves."),
        VisitorSpecies(id: "paintedlady", name: "Painted Lady", rarity: .common, fact: "Painted ladies are found in more parts of the world than most butterflies."),
        VisitorSpecies(id: "honeybee", name: "Honeybee", rarity: .common, fact: "Honeybees do a waggle dance to show other bees where to find flowers."),
        VisitorSpecies(id: "bumblebee", name: "Bumblebee", rarity: .common, fact: "Bumblebees buzz to shake pollen out of some flowers, like tomato flowers."),
        VisitorSpecies(id: "ladybug", name: "Ladybug", rarity: .common, fact: "Ladybugs eat tiny bugs called aphids. That helps keep plants healthy."),
        VisitorSpecies(id: "dragonfly", name: "Dragonfly", rarity: .uncommon, fact: "Dragonfly ancestors flew in the sky about 300 million years ago, before dinosaurs."),
        VisitorSpecies(id: "morpho", name: "Blue Morpho", rarity: .rare, fact: "A blue morpho shines blue because tiny scales on its wings bounce light."),
        VisitorSpecies(id: "hummingbird", name: "Hummingbird", rarity: .rare, fact: "A hummingbird flaps its wings about 50 times a second."),
        VisitorSpecies(id: "firefly", name: "Firefly", rarity: .uncommon, nightOnly: true, fact: "Fireflies make their own light. They blink to talk to each other."),
        VisitorSpecies(id: "luna", name: "Luna Moth", rarity: .rare, nightOnly: true, fact: "A grown-up luna moth has no mouth. It does not need to eat!"),
    ]

    /// Any visitor by id, the twelve friends and the season friends (`season`, FrostLantern.swift).
    static func species(_ id: String) -> VisitorSpecies? { all.first { $0.id == id } ?? season.first { $0.id == id } }
}

enum VisitorSpawner {
    /// Evening window 17:30 to 21:30 on the device clock (spec section 16). Calendar handles DST and travel.
    static func isEvening(_ date: Date, calendar: Calendar) -> Bool {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return minutes >= 17 * 60 + 30 && minutes < 21 * 60 + 30
    }

    /// `season`: the winter friends of the packs owned (`VisitorCatalog.seasonPool`); empty for everyone else.
    static func pool(evening: Bool, lantern: Bool, season: [String] = []) -> [String] {
        let day = VisitorCatalog.all.filter { !$0.nightOnly }.map(\.id) + season
        let night = VisitorCatalog.all.filter(\.nightOnly).map(\.id)
        // Evening features the night species (drawn twice as often) without locking out any day visitor.
        if evening { return day + night + night }
        return lantern ? day + night : day
    }

    /// The Visitors page's friend of the day: one daytime visitor, fixed for a player's seed and a Gregorian day key
    /// (`WeatherDay.key`), mixed the same way the weather is so every device agrees. Only a suggestion: catching and
    /// meeting work as always.
    static func friendOfTheDay(seed: Int64, day: Int) -> VisitorSpecies {
        let ids = pool(evening: false, lantern: false)      // the twelve only: never a season friend
        let x = WeatherEngine.mix(UInt64(bitPattern: seed) ^ WeatherEngine.mix(UInt64(bitPattern: Int64(day)) &+ 0x5A17_F00D))
        return VisitorCatalog.species(ids[Int(x % UInt64(ids.count))])!
    }

    private static func weight(_ r: VisitorCatalog.Rarity) -> Int {
        switch r { case .common: return 6; case .uncommon: return 3; case .rare: return 1 }
    }

    static func next<G: RandomNumberGenerator>(pool: [String], using rng: inout G) -> String? {
        let weighted = pool.compactMap { id in VisitorCatalog.species(id).map { (id, weight($0.rarity)) } }
        let total = weighted.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var r = Int(rng.next() % UInt64(total))
        for (id, w) in weighted {
            if r < w { return id }
            r -= w
        }
        return weighted.last?.0
    }

    static func maxVisitors(floweringPlants: Int) -> Int { min(8, 2 + max(0, floweringPlants) / 2) }
}

struct StickerAlbum: Codable, Equatable {
    private(set) var counts: [String: Int] = [:]
    /// When each friend was most recently met. Older albums have no dates (read as "not known").
    private(set) var seenAt: [String: Date] = [:]

    init() {}
    init(json: String) {
        if let d = json.data(using: .utf8), let a = try? JSONDecoder().decode(StickerAlbum.self, from: d) { self = a } else { self = StickerAlbum() }
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        counts = try c.decodeIfPresent([String: Int].self, forKey: .counts) ?? [:]
        seenAt = (try? c.decodeIfPresent([String: Date].self, forKey: .seenAt)) ?? [:]
    }
    var json: String { (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? "" }

    func merged(with other: StickerAlbum) -> StickerAlbum {
        var m = self
        for (k, v) in other.counts { m.counts[k] = max(m.counts[k] ?? 0, v) }
        for (k, d) in other.seenAt { m.seenAt[k] = max(m.seenAt[k] ?? d, d) }
        return m
    }

    mutating func add(_ ids: [String], on date: Date? = nil) {
        for id in ids {
            counts[id, default: 0] += 1
            if let date { seenAt[id] = max(seenAt[id] ?? date, date) }
        }
    }
    func count(of id: String) -> Int { counts[id] ?? 0 }
    func lastSeen(of id: String) -> Date? { seenAt[id] }
    /// Visitor species met. Weather stickers share the album (ids `weather.n`) but are not visitors, so they never count here.
    /// Season friends (robin, wren) are not among the twelve either, so the count never passes 12.
    var species: Int { counts.filter { $0.value > 0 && !WeatherSticker.isWeather($0.key) && !VisitorCatalog.isSeason($0.key) }.count }
    var isComplete: Bool { VisitorCatalog.all.allSatisfy { count(of: $0.id) > 0 } }
}

/// Every Visitors page string, grade 2-3 reading level, checked by CopySafety in tests.
enum VisitorsCopy {
    static let title = "Visitors"
    static func friendsMet(_ n: Int, of total: Int) -> String { "\(n) of \(total) friends met" }
    static let moreFlowers = "More flowers in bloom bring more visitors."
    static let playTitle = "Say hello to visitors"
    static let playBlurb = "About half a minute. Swipe or tap. Every visit is a good one."
    static let playBlurbCalm = "Take your time. Say hello to 5 friends, or tap Done."
    static let playBlurbTap = "Tap the visitors resting on the flowers. Every visit is a good one."
    static let sayHello = "Say hello"
    static func friendOfTheDay(_ name: String) -> String {
        let article = name.first.map { "AEIOU".contains($0.uppercased()) } == true ? "an" : "a"
        return "Say hello to \(article) \(name) today"
    }
    static let eveningTitle = "Evening friends"
    static let eveningTimes = "5:30 to 9:30 pm"
    static func netTitle(tier: Int) -> String { "Your net: " + ["small", "medium", "big"][min(3, max(1, tier)) - 1] }
    static let netGrows = "It grows in the Shed"
    static let netFull = "As big as it gets"
    static let album = "Album"
    static let notMet = "Not met yet"
    static func notMetHint(nightOnly: Bool) -> String { nightOnly ? "Comes out in the evening" : "Say hello in the game" }
    static func metCount(_ n: Int) -> String { n == 1 ? "Met once" : "Met \(n) times" }
    static func metSentence(_ n: Int) -> String { n == 1 ? "You met this friend once." : "You met this friend \(n) times." }
    static let funFact = "Fun fact"
    static let notMetDetail = "Say hello in the butterfly game to meet this friend."
    static let done = "Done"
    static let newFriend = "New friend"
    static func newFriendTitle(_ name: String) -> String { "New friend: \(name)" }
    static func newFriendLine(_ rarity: VisitorCatalog.Rarity) -> String { "\(rarity.label). Added to your album." }
    static func saidHello(_ n: Int) -> String { "\(n) said hello" }
    static func caughtPill(_ name: String) -> String { "\(name)!" }
    static func summaryTitle(friends n: Int) -> String {
        n == 0 ? "Thanks for visiting the garden" : (n == 1 ? "You met 1 friend" : "You met \(n) friends")
    }
    static func newInAlbum(_ n: Int) -> String { n == 1 ? "1 new friend in your album" : "\(n) new friends in your album" }

    // The net and Quick wings (docs/pm/butterfly-net-spec.md section 5). No digits, nothing about time or speed.
    static let quickWings = "Quick wings"
    static let playBlurbQuick = "Follow the visitors with your net. They flit and turn. Every visit is a good one."
    static let easierToggle = "Easier butterflies"
    /// What the switch brings back (the gentle net is not bigger, only more forgiving).
    static let easierFootnote = "Easier butterflies: slower visitors and a more forgiving net. Rounds are a little shorter."
    static func flyingLabel(_ name: String) -> String { "\(name), flying" }
    static let netHint = "Says hello with your net"
    /// Switch Control and VoiceOver: a named action on the scene that says hello to the visitor nearest the net.
    static let swingAction = "Swing the net"
    static let sceneLabel = "Butterfly garden"

    static func seen(_ date: Date, now: Date, calendar: Calendar) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        switch days {
        case ...0: return "Seen today"
        case 1: return "Seen yesterday"
        default: return "Seen \(days) days ago"
        }
    }

    /// An unmet card also says when the friend comes ("Comes out in the evening"), as the card shows.
    static func cardLabel(name: String, rarity: VisitorCatalog.Rarity, met: Int, seen: String?, nightOnly: Bool = false) -> String {
        guard met > 0 else { return "\(notMet), \(rarity.label.lowercased()). \(notMetHint(nightOnly: nightOnly))" }
        return [name, rarity.label.lowercased(), metCount(met).lowercased(), seen?.lowercased()].compactMap { $0 }.joined(separator: ", ")
    }

    static var all: [String] {
        var lines = [title, friendsMet(7, of: 12), moreFlowers, playTitle, playBlurb, playBlurbCalm, playBlurbTap, sayHello, eveningTitle, eveningTimes,
                     netTitle(tier: 1), netTitle(tier: 3), netGrows, netFull, album, notMet, notMetHint(nightOnly: true), notMetHint(nightOnly: false),
                     metCount(1), metCount(4), metSentence(1), metSentence(3), funFact, notMetDetail, done, newFriend, newFriendTitle("Monarch"),
                     saidHello(2), caughtPill("Monarch"), summaryTitle(friends: 0), summaryTitle(friends: 1), summaryTitle(friends: 4),
                     newInAlbum(1), newInAlbum(3), "Seen today", "Seen yesterday", "Seen 5 days ago",
                     cardLabel(name: "Monarch", rarity: .uncommon, met: 3, seen: "Seen today"), cardLabel(name: "Luna Moth", rarity: .rare, met: 0, seen: nil, nightOnly: true)]
        lines += [quickWings, playBlurbQuick, easierToggle, easierFootnote, flyingLabel("Monarch"), netHint, swingAction, sceneLabel]
        for r in [VisitorCatalog.Rarity.common, .uncommon, .rare] { lines += [r.label, newFriendLine(r)] }
        return lines
    }
}

struct DailyPlayCounter: Codable, Equatable {
    private(set) var day: Date?
    private(set) var plays = 0

    mutating func record(on date: Date, calendar: Calendar) {
        if let d = day, calendar.isDate(d, inSameDayAs: date) { plays += 1 } else { day = calendar.startOfDay(for: date); plays = 1 }
    }
    func playsToday(on date: Date, calendar: Calendar) -> Int {
        guard let d = day, calendar.isDate(d, inSameDayAs: date) else { return 0 }
        return plays
    }
}

enum ButterflyRewards {
    struct Summary: Equatable {
        var water = 0
        var shedPoints = 0
        var scoops = 0
        /// The distinct visitors met this round (old friends too).
        var newStickerIds: [String] = []
        /// Visitors met for the very first time this round (new to the album).
        var newFriendIds: [String] = []
        /// Gentle Net: hellos to resting friends this round (0 in Quiet Garden, where no count shows).
        var gentleHellos = 0
    }
    static let rewardedPlaysPerDay = 3

    /// Every rewarded play pays something, with or without catches. Plays past the daily limit still record stickers.
    static func summary<G: RandomNumberGenerator>(catches: [String], playsToday: Int, using rng: inout G) -> Summary {
        var s = Summary()
        var seen = Set<String>()
        s.newStickerIds = catches.filter { seen.insert($0).inserted }
        guard playsToday < rewardedPlaysPerDay else { return s }
        s.water = 1
        s.shedPoints = 2
        var bonus = 0
        for id in catches {
            switch VisitorCatalog.species(id)?.rarity {
            case .uncommon: bonus += 1
            case .rare: bonus += 2
            default: break
            }
        }
        s.shedPoints += min(bonus, 6)
        s.scoops = Int(rng.next() % 100) < 30 ? 1 : 0
        return s
    }
}

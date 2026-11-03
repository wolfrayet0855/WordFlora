import Foundation

struct VisitorSpecies: Equatable {
    var id: String
    var name: String
    var rarity: VisitorCatalog.Rarity
    var nightOnly = false
    /// Only fact-checked lines ship; nil means "no fact yet" and the UI shows none.
    var fact: String?
}

enum VisitorCatalog {
    enum Rarity: Hashable { case common, uncommon, rare }

    static let all: [VisitorSpecies] = [
        VisitorSpecies(id: "monarch", name: "Monarch", rarity: .uncommon, fact: "Monarch butterflies can migrate up to 3,000 miles."),
        VisitorSpecies(id: "swallowtail", name: "Swallowtail", rarity: .uncommon, fact: "Swallowtail hindwing tails may trick predators into pecking the wings, not the body."),
        VisitorSpecies(id: "cabbagewhite", name: "Cabbage White", rarity: .common, fact: "Cabbage whites began in Eurasia and now live on many continents, spread by people."),
        VisitorSpecies(id: "paintedlady", name: "Painted Lady", rarity: .common),
        VisitorSpecies(id: "honeybee", name: "Honeybee", rarity: .common),
        VisitorSpecies(id: "bumblebee", name: "Bumblebee", rarity: .common),
        VisitorSpecies(id: "ladybug", name: "Ladybug", rarity: .common),
        VisitorSpecies(id: "dragonfly", name: "Dragonfly", rarity: .uncommon, fact: "Dragonfly ancestors zoomed through the sky about 300 million years ago, before dinosaurs."),
        VisitorSpecies(id: "morpho", name: "Blue Morpho", rarity: .rare),
        VisitorSpecies(id: "hummingbird", name: "Hummingbird", rarity: .rare, fact: "A hummingbird's wings flap about 50 times a second."),
        VisitorSpecies(id: "firefly", name: "Firefly", rarity: .uncommon, nightOnly: true),
        VisitorSpecies(id: "luna", name: "Luna Moth", rarity: .rare, nightOnly: true),
    ]

    static func species(_ id: String) -> VisitorSpecies? { all.first { $0.id == id } }
}

enum VisitorSpawner {
    /// Evening window 17:30 to 21:30 on the device clock (spec section 16). Calendar handles DST and travel.
    static func isEvening(_ date: Date, calendar: Calendar) -> Bool {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return minutes >= 17 * 60 + 30 && minutes < 21 * 60 + 30
    }

    static func pool(evening: Bool, lantern: Bool) -> [String] {
        let day = VisitorCatalog.all.filter { !$0.nightOnly }.map(\.id)
        let night = VisitorCatalog.all.filter(\.nightOnly).map(\.id)
        if evening { return night }
        return lantern ? day + night : day
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

    init() {}
    init(json: String) {
        if let d = json.data(using: .utf8), let a = try? JSONDecoder().decode(StickerAlbum.self, from: d) { self = a } else { self = StickerAlbum() }
    }
    var json: String { (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? "" }

    mutating func add(_ ids: [String]) { for id in ids { counts[id, default: 0] += 1 } }
    func count(of id: String) -> Int { counts[id] ?? 0 }
    var species: Int { counts.values.filter { $0 > 0 }.count }
    var isComplete: Bool { VisitorCatalog.all.allSatisfy { count(of: $0.id) > 0 } }
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
        var newStickerIds: [String] = []
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

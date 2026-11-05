import Foundation

// Garden weather (docs/pm/endgame-and-events-spec.md sections 3 and 6). Pure rules only: a per-player seed and the day
// key decide everything, so every device agrees with no server and no stored "event happened" rows. Weather never
// lowers a stored value; see WeatherLook for what a plant shows.

/// The seven kinds. The first three are big; the rest are gentle (looks only, in every variant).
enum WeatherKind: String, CaseIterable, Codable {
    case drySpell, busyBugs, bigWind, frostyNight, hotDay, hailShower, bigPuddles

    var isBig: Bool {
        switch self { case .drySpell, .busyBugs, .bigWind: return true; default: return false }
    }

    static let big: [WeatherKind] = [.drySpell, .busyBugs, .bigWind]
    /// The gentle part of a bag of 10: frost x2, hot day x2, hail, puddles x2.
    static let gentleBag: [WeatherKind] = [.frostyNight, .frostyNight, .hotDay, .hotDay, .hailShower, .bigPuddles, .bigPuddles]
}

/// How one plant meets the weather. `snug` is a sheltered garden: the helper shows the weather, the plant stays upright.
enum WeatherEffect: String, Codable { case shrugs, light, full, snug }

/// The day key weather uses: whole days since 2026-01-01 in the Gregorian calendar and the given time zone. It never
/// reads `Calendar.current`, so Buddhist or Japanese calendar settings give the same key (unlike `WakePuzzle.day`).
enum WeatherDay {
    static func key(_ d: Date, timeZone: TimeZone = .current) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        guard let epoch = cal.date(from: DateComponents(year: 2026, month: 1, day: 1)) else { return 0 }
        return cal.dateComponents([.day], from: epoch, to: cal.startOfDay(for: d)).day ?? 0
    }
}

enum WeatherEngine {
    // MARK: Seed and start (spec 3.2)

    /// A fresh seed (never 0, never from a device or user id) and the first day weather may come: a week after the
    /// garden began, and never day 0, which means "unset".
    static func newSeed<G: RandomNumberGenerator>(createdAt: Date, economy: Economy = .default, timeZone: TimeZone = .current,
                                                  using rng: inout G) -> (seed: Int64, startDay: Int) {
        var seed: Int64 = 0
        while seed == 0 { seed = Int64(bitPattern: rng.next()) }
        return (seed, max(1, WeatherDay.key(createdAt, timeZone: timeZone) + economy.weatherFirstWeekDays))
    }

    static func newSeed(createdAt: Date, economy: Economy = .default) -> (seed: Int64, startDay: Int) {
        var rng = SystemRandomNumberGenerator()
        return newSeed(createdAt: createdAt, economy: economy, using: &rng)
    }

    /// The seed pair rule: the pair with the smaller nonzero start day wins; on a tie, the smaller seed. Commutative and
    /// idempotent, so every device settles on the same pair.
    static func mergedSeedPair(_ a: (seed: Int64, startDay: Int), _ b: (seed: Int64, startDay: Int)) -> (seed: Int64, startDay: Int) {
        let aSet = a.startDay != 0 && a.seed != 0, bSet = b.startDay != 0 && b.seed != 0
        switch (aSet, bSet) {
        case (false, false): return (a.seed, a.startDay) >= (b.seed, b.startDay) ? a : b
        case (true, false): return a
        case (false, true): return b
        case (true, true): return (a.startDay, a.seed) <= (b.startDay, b.seed) ? a : b
        }
    }

    // MARK: Schedule (spec 3.3)

    /// The weather on `day`, or nil. A seed of 0 means unset: no weather.
    static func event(day: Int, seed: Int64, startDay: Int, economy: Economy = .default) -> WeatherKind? {
        guard seed != 0, day >= startDay, economy.weatherBlockDays > 0 else { return nil }
        let block = (day - startDay) / economy.weatherBlockDays
        let info = blockInfo(block, seed: seed, startDay: startDay, economy: economy)
        guard info.hasEvent, day - startDay - block * economy.weatherBlockDays == info.offset else { return nil }
        return kind(block: block, seed: seed, startDay: startDay, economy: economy)
    }

    /// Tomorrow's weather, shown as today's forecast.
    static func forecast(day: Int, seed: Int64, startDay: Int, economy: Economy = .default) -> WeatherKind? {
        event(day: day + 1, seed: seed, startDay: startDay, economy: economy)
    }

    /// The most recent event on `day` or within the `within - 1` days before it (so `within: 3` looks at day, day-1, day-2).
    static func latestEvent(onOrBefore day: Int, within: Int, seed: Int64, startDay: Int,
                            economy: Economy = .default) -> (kind: WeatherKind, day: Int)? {
        guard within > 0 else { return nil }
        for d in stride(from: day, to: day - within, by: -1) {
            if let k = event(day: d, seed: seed, startDay: startDay, economy: economy) { return (k, d) }
        }
        return nil
    }

    /// Every event from `from` through `through`, in order (for the widget, tests and a calendar view).
    static func events(from: Int, through: Int, seed: Int64, startDay: Int,
                       economy: Economy = .default) -> [(day: Int, kind: WeatherKind)] {
        guard seed != 0, through >= from, economy.weatherBlockDays > 0 else { return [] }
        var out: [(day: Int, kind: WeatherKind)] = []
        let first = max(0, (max(from, startDay) - startDay) / economy.weatherBlockDays)
        let last = (through - startDay) / economy.weatherBlockDays
        guard through >= startDay, last >= first else { return [] }
        var ord = ordinal(block: first, seed: seed, startDay: startDay, economy: economy)
        for b in first...last {
            let info = blockInfo(b, seed: seed, startDay: startDay, economy: economy)
            guard info.hasEvent else { continue }
            let d = startDay + b * economy.weatherBlockDays + info.offset
            if (from...through).contains(d) { out.append((d, kind(ordinal: ord, seed: seed, startDay: startDay, economy: economy))) }
            ord += 1
        }
        return out
    }

    /// The number of event blocks before `block`: this block's event takes `sequence[ordinal]`. Picking the kind by
    /// event ordinal (not by block) keeps two events in a row from sharing a kind across skipped blocks.
    static func ordinal(block: Int, seed: Int64, startDay: Int, economy: Economy = .default) -> Int {
        guard block > 0 else { return 0 }
        return (0..<block).filter { blockInfo($0, seed: seed, startDay: startDay, economy: economy).hasEvent }.count
    }

    /// The algorithm version a block uses: blocks starting before the cutover day keep the previous version.
    static func version(block: Int, startDay: Int, economy: Economy) -> Int {
        let blockStart = startDay + block * economy.weatherBlockDays
        return blockStart >= economy.weatherAlgoCutoverDay ? max(1, economy.weatherAlgoVersion) : max(1, economy.weatherAlgoVersion - 1)
    }

    private static func salt(_ version: Int) -> UInt64 { version <= 1 ? 0 : UInt64(version) &* 0xD1B54A32D192ED03 }

    /// SplitMix64's finaliser: spreads nearby inputs so block and bag streams never overlap.
    static func mix(_ x: UInt64) -> UInt64 {
        var z = x &+ 0x9E3779B97F4A7C15
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    private static func unit(_ rng: inout SplitMix64) -> Double { Double(rng.next() >> 11) * 0x1p-53 }

    private static func blockInfo(_ block: Int, seed: Int64, startDay: Int, economy: Economy) -> (hasEvent: Bool, offset: Int) {
        let v = version(block: block, startDay: startDay, economy: economy)
        var rng = SplitMix64(seed: mix(UInt64(bitPattern: seed) ^ mix(UInt64(bitPattern: Int64(block)) &* 0x9E3779B97F4A7C15 ^ salt(v))))
        let has = unit(&rng) < economy.weatherBlockChance
        let window = UInt64(max(1, min(economy.weatherEventWindow, economy.weatherBlockDays)))
        return (has, Int(rng.next() % window))
    }

    private static func eventBlocks(throughOrdinal target: Int, seed: Int64, startDay: Int, economy: Economy) -> [Int] {
        var blocks: [Int] = []
        var b = 0
        // Bounded: with blockChance > 0 this finds the blocks quickly; the cap only guards a zero chance.
        while blocks.count <= target, b < 100_000 {
            if blockInfo(b, seed: seed, startDay: startDay, economy: economy).hasEvent { blocks.append(b) }
            b += 1
        }
        return blocks
    }

    private static func kind(block: Int, seed: Int64, startDay: Int, economy: Economy) -> WeatherKind {
        kind(ordinal: ordinal(block: block, seed: seed, startDay: startDay, economy: economy), seed: seed, startDay: startDay, economy: economy)
    }

    /// `sequence[ordinal]`: a run of seeded bags of 10 (3 big, 7 gentle). A bag uses the version of the block holding its
    /// first event, so a cutover never changes a bag already begun.
    static func kind(ordinal: Int, seed: Int64, startDay: Int, economy: Economy = .default) -> WeatherKind {
        let size = max(1, economy.weatherBagBig + economy.weatherBagGentle)
        let bagIndex = ordinal / size
        let blocks = eventBlocks(throughOrdinal: bagIndex * size, seed: seed, startDay: startDay, economy: economy)
        func bagVersion(_ i: Int) -> Int {
            let o = i * size
            return o < blocks.count ? version(block: blocks[o], startDay: startDay, economy: economy) : max(1, economy.weatherAlgoVersion)
        }
        var bag = rawBag(bagIndex, seed: seed, version: bagVersion(bagIndex), economy: economy)
        if bagIndex > 0, let prevFinal = rawBag(bagIndex - 1, seed: seed, version: bagVersion(bagIndex - 1), economy: economy).last {
            bag = joined(bag, after: prevFinal)
        }
        return bag[ordinal % size]
    }

    /// One bag, shuffled until no two neighbours match (bounded tries, then a fixed safe order).
    static func rawBag(_ index: Int, seed: Int64, version: Int, economy: Economy = .default) -> [WeatherKind] {
        let bigCount = max(0, economy.weatherBagBig), gentleCount = max(0, economy.weatherBagGentle)
        let items = (0..<bigCount).map { WeatherKind.big[$0 % WeatherKind.big.count] }
            + (0..<gentleCount).map { WeatherKind.gentleBag[$0 % WeatherKind.gentleBag.count] }
        guard items.count > 1 else { return items.isEmpty ? [.hotDay] : items }
        var rng = SplitMix64(seed: mix(UInt64(bitPattern: seed) ^ 0xBA6_BA6 ^ mix(UInt64(bitPattern: Int64(index)) ^ salt(version))))
        for _ in 0..<64 {
            var a = items
            for i in stride(from: a.count - 1, to: 0, by: -1) { a.swapAt(i, Int(rng.next() % UInt64(i + 1))) }
            if noNeighboursMatch(a) { return a }
        }
        return safeOrder(items)
    }

    /// If a bag's first kind equals the previous bag's final kind, swap it with the earliest later slot (never the
    /// final one) that keeps all neighbours different. The final slot never moves, so no recursion is needed.
    static func joined(_ bag: [WeatherKind], after prevFinal: WeatherKind) -> [WeatherKind] {
        guard bag.first == prevFinal, bag.count > 2 else { return bag }
        for j in 1..<(bag.count - 1) where bag[j] != prevFinal {
            var b = bag
            b.swapAt(0, j)
            if noNeighboursMatch(b) { return b }
        }
        return bag
    }

    static func noNeighboursMatch(_ a: [WeatherKind]) -> Bool { zip(a, a.dropFirst()).allSatisfy { $0 != $1 } }

    /// A deterministic arrangement with no matching neighbours: most frequent kinds first, dealt into alternate slots.
    private static func safeOrder(_ items: [WeatherKind]) -> [WeatherKind] {
        let counts = Dictionary(items.map { ($0, 1) }, uniquingKeysWith: +)
        // Most frequent first; ties in declaration order (allCases is already in that order and the sort is stable).
        let order = WeatherKind.allCases.filter { counts[$0] != nil }.sorted { counts[$0]! > counts[$1]! }
        let flat = order.flatMap { Array(repeating: $0, count: counts[$0]!) }
        var out = Array(repeating: WeatherKind.hotDay, count: flat.count)
        let slots = Array(stride(from: 0, to: flat.count, by: 2)) + Array(stride(from: 1, to: flat.count, by: 2))
        for (k, s) in zip(flat, slots) { out[s] = k }
        return out
    }

    // MARK: Who is affected (spec 3.5)

    /// Every trait a plant may carry in Plants.json. Only some change the weather (see `effect`); the rest describe.
    static let knownTraits: Set<String> = [
        "desert", "succulent", "cactus", "carnivorous", "aquatic", "bog", "hardyTree", "woody", "flexible", "tall", "tropical",
        "shade", "alpine", "bigLeaf", "tree", "vine", "bulb", "tuber", "herb", "meadow", "annual", "evergreen", "epiphyte",
        "parasitic", "fruit",
    ]

    private static let table: [WeatherKind: (shrugs: Set<String>, full: Set<String>)] = [
        .drySpell: (["desert", "succulent"], ["aquatic", "bog", "shade"]),
        .busyBugs: (["carnivorous", "aquatic", "desert"], ["woody"]),
        .bigWind: (["desert", "hardyTree", "flexible"], ["tall"]),
        .frostyNight: (["alpine", "hardyTree"], ["tropical"]),
        .hotDay: (["desert", "succulent"], ["shade", "aquatic"]),
        .hailShower: (["desert", "hardyTree"], ["bigLeaf"]),
        .bigPuddles: (["aquatic", "bog"], ["desert", "succulent"]),
    ]

    /// Shrugs wins over full when a plant has both traits.
    static func effect(_ k: WeatherKind, traits: Set<String>) -> WeatherEffect {
        guard let row = table[k] else { return .light }
        if !row.shrugs.isDisjoint(with: traits) { return .shrugs }
        if !row.full.isDisjoint(with: traits) { return .full }
        return .light
    }

    /// FNV-1a of the plant id and the day key: the same order on every device and every launch.
    static func orderKey(plantId: String, day: Int) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in "\(plantId)#\(day)".utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    /// The found plants' effects. At most `ceil(cap x found)` plants show the full effect, picked in the deterministic
    /// order; any others over the cap show the light look.
    static func affected(_ k: WeatherKind, plants: [(id: String, traits: Set<String>)], day: Int, cap: Double) -> [String: WeatherEffect] {
        let ranks = fullRanks(k, plants: plants, day: day, cap: cap)
        var out: [String: WeatherEffect] = [:]
        for p in plants {
            let e = effect(k, traits: p.traits)
            out[p.id] = e == .full && ranks[p.id] == nil ? .light : e
        }
        return out
    }

    /// Each capped full-effect plant's index in the deterministic order (0 first), for Wild Weather's plant limit.
    static func fullRanks(_ k: WeatherKind, plants: [(id: String, traits: Set<String>)], day: Int, cap: Double) -> [String: Int] {
        let limit = Int((Double(plants.count) * max(0, cap)).rounded(.up))
        let full = plants.filter { effect(k, traits: $0.traits) == .full }.map(\.id)
            .sorted { (orderKey(plantId: $0, day: day), $0) < (orderKey(plantId: $1, day: day), $1) }
        return Dictionary(uniqueKeysWithValues: full.prefix(limit).enumerated().map { ($1, $0) })
    }

    // MARK: Gating (spec 3.4)

    /// True when weather may show today (forecast, event, puzzle). Once `gatedFromDay` is set, the found and tends
    /// conditions count as met for good, so a reconcile cannot flip weather off and on.
    static func isGated(found: Int, tends: Int, quietGarden: Bool, weatherOn: Bool, today: Int, highWater: Int,
                        gatedFromDay: Int = 0, economy: Economy = .default) -> Bool {
        guard !quietGarden, weatherOn, !clockWentBack(today: today, highWater: highWater, economy: economy) else { return false }
        return gatedFromDay != 0 || (found >= economy.weatherMinPlants && tends >= economy.weatherMinTends)
    }

    /// The first day the gate opened: kept once set (merge: min of nonzero).
    static func gatedFromDay(current: Int, gatedNow: Bool, today: Int) -> Int {
        current != 0 ? current : (gatedNow ? today : 0)
    }

    /// The device clock went back further than the one-day slack (two time zones in one family stay fine).
    static func clockWentBack(today: Int, highWater: Int, economy: Economy = .default) -> Bool {
        highWater != 0 && today < highWater - economy.weatherClockSlackDays
    }

    static func highWater(current: Int, today: Int) -> Int { max(current, today) }

    /// All six helpers arrive together, once, with the first forecast the player can see.
    static func kitArrives(forecastToday: Bool, gated: Bool, kitAt: Date?) -> Bool { forecastToday && gated && kitAt == nil }

    /// The anti-farm cap: at most one weather reward per `weatherAwardGardenDays` Garden Days.
    static func mayAward(rescuedCount: Int, gardenDays: Int, economy: Economy = .default) -> Bool {
        max(0, rescuedCount) * max(1, economy.weatherAwardGardenDays) <= max(0, gardenDays)
    }

    /// The garden weather setting's default: on unless Calm mode (the default under 13 and for unknown age).
    static func defaultWeatherOn(calmMode: Bool) -> Bool { !calmMode }

    /// Whether today's opening of the garden counts as having seen this event (it must be on or after the event day).
    static func seenCounts(_ seenAt: Date?, eventDay: Int, timeZone: TimeZone = .current) -> Bool {
        guard let seenAt else { return false }
        return WeatherDay.key(seenAt, timeZone: timeZone) >= eventDay
    }

    // MARK: Merge helpers (spec section 7)

    /// Event days solved: union, sorted, trimmed to the most recent `keep`.
    static func mergedRescuedDays(_ a: [Int], _ b: [Int], keep: Int = 30) -> [Int] {
        Array(Set(a).union(b).sorted().suffix(max(0, keep)))
    }

    /// A per-day count (like `waterDay`/`waterToday`): the later day wins; on the same day the larger count.
    static func mergedDayCount(_ a: (day: Int, count: Int), _ b: (day: Int, count: Int)) -> (day: Int, count: Int) {
        if a.day != b.day { return a.day > b.day ? a : b }
        return (a.day, max(a.count, b.count))
    }

    /// The smaller of two nonzero values (0 means unset).
    static func minNonzero(_ a: Int, _ b: Int) -> Int {
        a == 0 ? b : (b == 0 ? a : min(a, b))
    }
}

/// Every weather line the UI will show, grade 2-3 and positive only. Checked by CopySafety and an extra avoid list
/// (save, rescue, danger, destroy, warning, alert, too late, countdown) in tests.
enum WeatherCopy {
    static func name(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "Dry spell"
        case .busyBugs: return "Busy bugs"
        case .bigWind: return "Big wind"
        case .frostyNight: return "Frosty night"
        case .hotDay: return "Hot day"
        case .hailShower: return "Hail shower"
        case .bigPuddles: return "Big puddles"
        }
    }

    /// "a dry spell", "busy bugs": for sentences.
    static func phrase(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "a dry spell"
        case .busyBugs: return "busy bugs"
        case .bigWind: return "a big wind"
        case .frostyNight: return "a frosty night"
        case .hotDay: return "a hot day"
        case .hailShower: return "a hail shower"
        case .bigPuddles: return "big puddles"
        }
    }

    /// "the dry spell": after the weather has come.
    static func the(_ k: WeatherKind) -> String {
        switch k {
        case .busyBugs: return "the busy bugs"
        case .bigPuddles: return "the big puddles"
        default: return "the " + name(k).lowercased()
        }
    }

    static func helper(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell, .hotDay: return "shade cloth"
        case .busyBugs: return "bug cover"
        case .bigWind: return "wind net"
        case .frostyNight: return "frost cloth"
        case .hailShower: return "garden umbrella"
        case .bigPuddles: return "raised bed"
        }
    }

    // Forecast (the day before)
    static func forecastTitle(_ k: WeatherKind) -> String { "Tomorrow: \(phrase(k))" }
    static func forecastChip(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "Tomorrow: dry"
        case .busyBugs: return "Tomorrow: bugs"
        case .bigWind: return "Tomorrow: windy"
        case .frostyNight: return "Tomorrow: frosty"
        case .hotDay: return "Tomorrow: hot"
        case .hailShower: return "Tomorrow: hail"
        case .bigPuddles: return "Tomorrow: puddles"
        }
    }
    static let forecastStepCare = "Give a drink or a hello today."
    static func forecastStepHelper(_ k: WeatherKind) -> String { "Set out the \(helper(k))." }
    static let forecastGotIt = "Got it"
    static let gardenReady = "Your garden is ready."
    static func widgetLine(_ k: WeatherKind) -> String { "\(forecastTitle(k)). \(gardenReady)" }
    static func notificationTitle(_ k: WeatherKind) -> String { "Garden forecast: \(phrase(k)) tomorrow" }

    // The day itself
    static func eventLine(_ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "A dry spell came to the garden."
        case .busyBugs: return "Busy bugs came to the garden."
        case .bigWind: return "A big wind blew through the garden."
        case .frostyNight: return "A frosty night came to the garden."
        case .hotDay: return "It is a hot day in the garden."
        case .hailShower: return "A hail shower came to the garden."
        case .bigPuddles: return "Big puddles came to the garden."
        }
    }
    static func plantLine(name: String, _ k: WeatherKind) -> String { "\(name) would love some care after \(the(k))." }
    static func shrugLine(name: String, _ k: WeatherKind) -> String {
        switch k {
        case .drySpell: return "\(name) loves dry days!"
        case .busyBugs: return "Bugs do not bother \(name)!"
        case .bigWind: return "\(name) sways and stays strong in the wind!"
        case .frostyNight: return "\(name) is cosy in the cold!"
        case .hotDay: return "\(name) loves the heat!"
        case .hailShower: return "\(name) is tough in the hail!"
        case .bigPuddles: return "\(name) loves a big splash!"
        }
    }
    static func snugLine(name: String, _ k: WeatherKind) -> String {
        switch k {
        case .bigWind: return "\(name) is snug behind the wind net."
        case .bigPuddles: return "\(name) is snug in the raised bed."
        case .hotDay: return "\(name) is cool and snug under the shade cloth."
        default: return "\(name) is snug under the \(helper(k))."
        }
    }
    static func wildLine(name: String, _ k: WeatherKind) -> String {
        "\(name) is resting after \(the(k)). Give care, and it stands tall tomorrow."
    }
    static func mendedLine(name: String) -> String { "\(name) is standing tall again!" }
    static func mendingLine(name: String) -> String { "\(name) is mending. It will stand tall tomorrow." }
    static let passedLine = "The weather has passed. Your garden looks bright."

    // Helpers (Shed)
    static let kitTitle = "Weather kit"
    static let kitLine = "A weather kit for you, from the Shed."
    static let kitBlurb = "Six helpers to keep your plants snug in any weather."
    static func setOutLine(_ k: WeatherKind) -> String { "The \(helper(k)) is set out." }
    static let setOutButton = "Set it out"

    // Puzzle prompts the banner and plant page need (the puzzle itself is E-8)
    static let puzzleTitle = "Weather puzzle"
    static let puzzleSkip = "Skip for now. Care will help it mend."
    static let puzzlePlenty = "That is plenty for today. Your garden will mend with care."
    static let puzzleTryAgain = "Not quite. Try again."
    static let puzzleHarder = "A harder one"

    static func all(name: String) -> [String] {
        let perKind = WeatherKind.allCases.flatMap { k in
            [self.name(k), phrase(k), the(k), helper(k), forecastTitle(k), forecastChip(k), forecastStepHelper(k), widgetLine(k),
             notificationTitle(k), eventLine(k), plantLine(name: name, k), shrugLine(name: name, k), snugLine(name: name, k),
             wildLine(name: name, k), setOutLine(k)]
        }
        return perKind + [forecastStepCare, forecastGotIt, gardenReady, mendedLine(name: name), mendingLine(name: name), passedLine,
                          kitTitle, kitLine, kitBlurb, setOutButton, puzzleTitle, puzzleSkip, puzzlePlenty, puzzleTryAgain, puzzleHarder]
    }
}

import Foundation

enum ToolID: String, CaseIterable, Codable { case can, trowel, shears, mister, lamp, net }

/// Six tools, three tiers each. Start with the can and trowel; the rest unlock through play (spec sections 14, 19).
struct ToolInventory: Codable, Equatable {
    private(set) var tiers: [String: Int] = [ToolID.can.rawValue: 1, ToolID.trowel.rawValue: 1]

    init() {}

    init(json: String) {
        if let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(ToolInventory.self, from: data) {
            self = decoded
        } else {
            self = ToolInventory()
        }
    }

    var json: String {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    func tier(of tool: ToolID) -> Int { tiers[tool.rawValue] ?? 0 }

    func merged(with other: ToolInventory) -> ToolInventory {
        var m = self
        for (k, v) in other.tiers { m.tiers[k] = max(m.tiers[k] ?? 0, v) }
        return m
    }

    mutating func unlock(_ tool: ToolID) { if tier(of: tool) == 0 { tiers[tool.rawValue] = 1 } }

    /// The one source of upgrade prices (the Shed reads these). Every tool to tier 3 is 6 x (30 + 120) = 900 points.
    static func upgradeCost(toTier t: Int) -> Int? {
        switch t { case 2: return 30; case 3: return 120; default: return nil }
    }

    static var totalUpgradeCostForAllTools: Int {
        ToolID.allCases.count * (2...3).compactMap(upgradeCost(toTier:)).reduce(0, +)
    }

    /// Spends shed points; tiers only go up and top out at 3.
    mutating func upgrade(_ tool: ToolID, shedPoints: inout Int) -> Bool {
        let current = tier(of: tool)
        guard current >= 1, let cost = Self.upgradeCost(toTier: current + 1), shedPoints >= cost else { return false }
        shedPoints -= cost
        tiers[tool.rawValue] = current + 1
        return true
    }
}

enum SoilType: String, CaseIterable, Codable {
    case loam, sandy, peaty, compost

    /// Stable per plant (never uses hashValue).
    static func preferred(forPlantId id: String) -> SoilType {
        allCases[id.utf8.reduce(0) { $0 + Int($1) } % allCases.count]
    }
}

struct RepotResult: Equatable {
    enum Outcome: Equatable { case happy, neutral }
    var applied = false
    var outcome: Outcome?
    var tend = TendResult()
}

enum ToolEngine {
    static let trowelMultipliers = [1.0, 1.25, 1.5]
    static let lampGrowth = [2, 3, 4]
    static let pruneGrowth = [4, 6, 8]
    static let pruneCooldownDays = 2.0
    static let repotMatchGrowth = 4
    /// Butterfly net: the catch circle around a finger, in points, by tier (v4 design, visitors section 5).
    static let netCatchPoints = [48.0, 64.0, 80.0]
    /// Mister: the free water drops come faster and a little more can collect. Tier 1 is the plain Economy trickle.
    /// The daily drinks per plant (`waterPerDay`) and the water bank cap never change.
    static let misterTrickleHours = [4.0, 3.0, 2.0]
    static let misterTrickleCaps = [5, 6, 7]

    private static func index(_ tier: Int, _ count: Int) -> Int { min(count, max(1, tier)) - 1 }

    static func netCatchRadius(tier: Int) -> Double { netCatchPoints[index(tier, netCatchPoints.count)] }
    static func trickleHours(forMister tier: Int) -> Double { misterTrickleHours[index(tier, misterTrickleHours.count)] }
    static func trickleCap(forMister tier: Int) -> Int { misterTrickleCaps[index(tier, misterTrickleCaps.count)] }

    /// The economy the free drops use for this inventory: only the trickle pace and its cap change.
    static func trickleEconomy(_ economy: Economy, inventory: ToolInventory) -> Economy {
        let tier = inventory.tier(of: .mister)
        guard tier > 1 else { return economy }
        var e = economy
        e.trickleHours = trickleHours(forMister: tier)
        e.trickleCap = trickleCap(forMister: tier)
        return e
    }

    /// Free drops, sped up by the mister. Every trickle call site goes through here.
    static func applyTrickle(_ profile: PlayerProfile, inventory: ToolInventory, now: Date, economy: Economy) {
        TendingEngine.applyTrickle(profile, now: now, economy: trickleEconomy(economy, inventory: inventory))
    }

    /// A better can waters more plants per use, one drop each. A plant that has had its drinks today is skipped for free.
    static func waterWithCan(_ plants: [PlantCollectible], profile: PlayerProfile, inventory: ToolInventory,
                             now: Date, calendar: Calendar, economy: Economy, quiet: Bool = false) -> [TendResult] {
        var results = [TendResult]()
        for plant in plants.prefix(max(1, inventory.tier(of: .can))) {
            let r = TendingEngine.water(plant, profile: profile, now: now, calendar: calendar, economy: economy, quiet: quiet)
            results.append(r)
            if r.reason == .noWater { break }
        }
        return results
    }

    static func addSoil(_ plant: PlantCollectible, profile: PlayerProfile, inventory: ToolInventory,
                        now: Date, calendar: Calendar, economy: Economy, quiet: Bool = false) -> TendResult {
        let tier = max(1, inventory.tier(of: .trowel))
        return TendingEngine.addSoil(plant, profile: profile, now: now, calendar: calendar, economy: economy,
                                     quiet: quiet, multiplier: trowelMultipliers[tier - 1])
    }

    static func sunWithLamp(_ plant: PlantCollectible, profile: PlayerProfile, inventory: ToolInventory,
                            now: Date, calendar: Calendar, economy: Economy, quiet: Bool = false) -> TendResult {
        let tier = inventory.tier(of: .lamp)
        if tier == 0 && !quiet { return .blocked(.notOwned) }
        return TendingEngine.sun(plant, profile: profile, now: now, calendar: calendar, economy: economy,
                                 quiet: quiet, growth: lampGrowth[max(1, tier) - 1])
    }

    static func prune(_ plant: PlantCollectible, inventory: ToolInventory, now: Date, calendar: Calendar,
                      economy: Economy, quiet: Bool = false) -> TendResult {
        let tier = max(1, inventory.tier(of: .shears))
        if !quiet { guard inventory.tier(of: .shears) > 0 else { return .blocked(.notOwned) } }
        // Pruning rests in Quiet Garden too: with no shared daily cap, the rest is what keeps its growth paced.
        if let last = plant.lastPrunedAt, now.timeIntervalSince(last) < pruneCooldownDays * 86_400 { return .blocked(.cooldown) }
        let r = TendingEngine.applyGrowth(plant, desired: pruneGrowth[tier - 1], now: now, calendar: calendar, economy: economy)
        if r.applied { plant.lastPrunedAt = now }
        return r
    }

    /// Costs one scoop. A preferred soil is "happy" (growth boost); anything else is simply neutral, never harmful.
    /// The happy growth comes once a day; another happy repot the same day still refreshes the soil.
    static func repot(_ plant: PlantCollectible, to soil: SoilType, profile: PlayerProfile, now: Date,
                      calendar: Calendar, economy: Economy, quiet: Bool = false) -> RepotResult {
        let happy = soil == SoilType.preferred(forPlantId: plant.plantId)
        guard quiet || profile.soil > 0 else { return RepotResult() }
        if !quiet { profile.soil -= 1 }
        plant.soilType = soil.rawValue
        plant.soilRichness = min(1.0, plant.soilRichness + economy.soilRichnessStep)
        var tend = TendResult()
        if happy {
            plant.soilBoostUntil = now.addingTimeInterval(Double(economy.soilBoostDays) * 86_400)
            if !TendingEngine.isToday(plant.lastRepotGrowthAt, now: now, calendar: calendar) {
                plant.lastRepotGrowthAt = now
                tend = TendingEngine.applyGrowth(plant, desired: repotMatchGrowth, now: now, calendar: calendar, economy: economy)
            } else {
                tend = TendResult(applied: true, gpGained: 0, stageUp: false, reason: nil)
            }
        }
        return RepotResult(applied: true, outcome: happy ? .happy : .neutral, tend: tend)
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}

/// What the Shed shows. Quiet Garden has no points, so no upgrades or prices either.
enum ShedPolicy {
    static func showsUpgrades(quietGarden: Bool) -> Bool { !quietGarden }
}

/// Every Shed string, grade 2-3 reading level, checked by CopySafety in tests.
enum ShedCopy {
    static func name(_ tool: ToolID) -> String {
        switch tool {
        case .can: return "Watering can"
        case .trowel: return "Trowel"
        case .net: return "Butterfly net"
        case .mister: return "Mister"
        case .shears: return "Shears"
        case .lamp: return "Sun lamp"
        }
    }

    /// The card line. Tools still to find say where they are found; found tools say what they do now
    /// (design-preview/shed-visitors/shed-v2/notes.md copy table). Never "Finish level N" once found.
    static func blurb(_ tool: ToolID, owned: Bool) -> String {
        owned ? quietLine(tool) : toFind(tool)
    }

    static func toFind(_ tool: ToolID) -> String {
        switch tool {
        case .can, .trowel: return "Ready to use"
        case .net: return "Comes with the butterfly game"
        case .mister: return "Find at garden level 1"
        case .shears: return "Find at garden level 2"
        case .lamp: return "Find at garden level 3"
        }
    }

    /// Quiet Garden shows what a tool is for, with no tiers or numbers.
    static func quietLine(_ tool: ToolID) -> String {
        switch tool {
        case .can: return "Waters your plants"
        case .trowel: return "Adds soil for growing"
        case .net: return "Catches visitors gently"
        case .mister: return "Brings free drops of water"
        case .shears: return "Trims plants to help them grow"
        case .lamp: return "Gives plants some sunshine"
        }
    }

    /// What a tier does, in plain words ("Now" and "Next").
    static func effect(_ tool: ToolID, tier: Int) -> String {
        let t = min(3, max(1, tier))
        switch tool {
        case .can: return t == 1 ? "Waters 1 plant per tap" : "Waters \(t) plants per tap"
        case .trowel: return ["Small", "Bigger", "Biggest"][t - 1] + " soil boost"
        case .net: return ["Small", "Bigger", "Biggest"][t - 1] + " catch circle"
        case .mister: return "A free drop every \(Int(ToolEngine.trickleHours(forMister: t))) hours"
        case .shears: return "A trim helps " + ["a bit", "more", "lots"][t - 1]
        case .lamp: return "Sunshine helps " + ["a bit", "more", "lots"][t - 1]
        }
    }

    /// One line for the "got better" card.
    static func upgradedLine(_ tool: ToolID, tier: Int) -> String { "Now: " + effect(tool, tier: tier).lowercasedFirst + "." }
    static func upgradedTitle(_ tool: ToolID) -> String { "Your \(name(tool).lowercased()) got better!" }
    static let yay = "Yay!"

    static let pointsTitle = "shed points"
    static func points(_ n: Int) -> String { n == 1 ? "1 shed point" : "\(n) shed points" }
    static let pointsHow = "Earn more in the butterfly game."
    static let play = "Play"
    static let playLabel = "Play the butterfly game"
    static let sceneLabel = "A cosy wooden garden shed"
    static let quietTitle = "Quiet Garden is on"
    static let quietReady = "Your tools are ready to use."
    static let toolsTitle = "Tools"
    static let toolsSubtitle = "Tap a tool to see what it does."
    static let nowLabel = "Now"
    static let nextLabel = "Next"
    static let upgradeReady = "Upgrade ready"
    static let toolHint = "Shows what it does."
    static let fullyUpgraded = "All three tiers. Great tool!"
    static func tier(_ t: Int) -> String { "Tier \(t) of 3" }
    static func upgradeButton(cost: Int) -> String { "Upgrade for \(cost) shed points" }
    static func toGo(have: Int, cost: Int) -> String {
        have >= cost ? "You have enough points!" : "\(cost - have) more to go"
    }
    static func progress(have: Int, cost: Int) -> String { "\(min(have, cost)) of \(cost) points" }
    static func tileLabel(_ tool: ToolID, tier: Int, quiet: Bool, ready: Bool) -> String {
        guard tier > 0 else { return "\(name(tool)). \(toFind(tool))." }
        if quiet { return "\(name(tool)). \(quietLine(tool))." }
        return "\(name(tool)). Tier \(tier) of 3. \(effect(tool, tier: tier))." + (ready ? " \(upgradeReady)." : "")
    }

    static var all: [String] {
        var lines = [pointsTitle, points(1), points(44), pointsHow, play, playLabel, sceneLabel, quietTitle, quietReady, toolsTitle, toolsSubtitle,
                     nowLabel, nextLabel, upgradeReady, toolHint, fullyUpgraded, tier(2), yay,
                     upgradeButton(cost: 30), toGo(have: 16, cost: 30), toGo(have: 40, cost: 30), progress(have: 4, cost: 30)]
        for tool in ToolID.allCases {
            lines += [name(tool), blurb(tool, owned: true), blurb(tool, owned: false), toFind(tool), quietLine(tool), upgradedTitle(tool)]
            lines += (1...3).flatMap { [effect(tool, tier: $0), upgradedLine(tool, tier: $0)] }
            lines += [tileLabel(tool, tier: 0, quiet: false, ready: false), tileLabel(tool, tier: 2, quiet: false, ready: true), tileLabel(tool, tier: 1, quiet: true, ready: false)]
        }
        return lines
    }
}

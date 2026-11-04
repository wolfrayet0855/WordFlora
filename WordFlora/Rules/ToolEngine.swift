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

    static func upgradeCost(toTier t: Int) -> Int? {
        switch t { case 2: return 30; case 3: return 120; default: return nil }
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

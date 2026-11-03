import Foundation

struct TendResult: Equatable {
    enum Reason: Equatable { case noWater, noSoil, fullForToday, alreadyDoneToday, notOwned, cooldown }
    var applied = false
    var gpGained = 0
    var stageUp = false
    var reason: Reason?

    static func blocked(_ r: Reason) -> TendResult { TendResult(applied: false, gpGained: 0, stageUp: false, reason: r) }
}

/// Gentle tending rules (spec sections 4, 16). Plants never die and stages only move forward;
/// pacing comes from a per-plant daily absorb cap, never from punishment.
enum TendingEngine {

    // MARK: Actions

    static func water(_ plant: PlantCollectible, profile: PlayerProfile, now: Date, calendar: Calendar,
                      economy: Economy, quiet: Bool = false) -> TendResult {
        guard quiet || profile.water > 0 else { return .blocked(.noWater) }
        resetDay(plant, now: now, calendar: calendar)
        let remaining = economy.dailyAbsorbCap - plant.absorbedToday
        guard remaining > 0 else { return .blocked(.fullForToday) }

        var desired = Double(economy.waterGrowth)
        if let until = plant.soilBoostUntil, until > now { desired *= economy.soilBoostMultiplier }
        let gain = min(Int(desired.rounded()), remaining)
        if !quiet { profile.water -= 1 }
        refresh(plant, now: now)
        return grow(plant, by: gain)
    }

    static func addSoil(_ plant: PlantCollectible, profile: PlayerProfile, now: Date, calendar: Calendar,
                        economy: Economy, quiet: Bool = false, multiplier: Double = 1.0) -> TendResult {
        guard quiet || profile.soil > 0 else { return .blocked(.noSoil) }
        resetDay(plant, now: now, calendar: calendar)
        let remaining = economy.dailyAbsorbCap - plant.absorbedToday
        guard remaining > 0 else { return .blocked(.fullForToday) }

        if !quiet { profile.soil -= 1 }
        plant.soilRichness = min(1.0, plant.soilRichness + economy.soilRichnessStep)
        plant.soilBoostUntil = now.addingTimeInterval(Double(economy.soilBoostDays) * 86_400)
        return grow(plant, by: min(Int((Double(economy.soilGrowth) * multiplier).rounded()), remaining))
    }

    static func sun(_ plant: PlantCollectible, profile: PlayerProfile, now: Date, calendar: Calendar,
                    economy: Economy, quiet: Bool = false, growth: Int? = nil) -> TendResult {
        if !quiet, let last = plant.lastSunnyAt, calendar.isDate(last, inSameDayAs: now) { return .blocked(.alreadyDoneToday) }
        resetDay(plant, now: now, calendar: calendar)
        let remaining = economy.dailyAbsorbCap - plant.absorbedToday
        guard remaining > 0 else { return .blocked(.fullForToday) }
        plant.lastSunnyAt = now
        return grow(plant, by: min(growth ?? economy.sunGrowth, remaining))
    }

    // MARK: Stages

    static func stage(forGrowth gp: Int, level: Int, economy: Economy = .default) -> Int {
        let idx = max(0, min(level - 1, economy.levelCostMultipliers.count - 1))
        let cost = economy.levelBaseCost * economy.levelCostMultipliers[idx]
        return economy.stageThresholds.filter { Double(gp) >= $0 * cost }.count
    }

    // MARK: Looks and free drops

    static func isThirsty(_ plant: PlantCollectible, now: Date, calm: Bool, economy: Economy = .default) -> Bool {
        guard !calm, let last = plant.lastTendedAt else { return false }
        return now.timeIntervalSince(last) >= economy.thirstyHours * 3600
    }

    /// One free drop per interval, topping the bank up to the cap only (never stacks above it).
    static func applyTrickle(_ profile: PlayerProfile, now: Date, economy: Economy) {
        if profile.water >= economy.trickleCap { profile.lastTrickleAt = now; return }
        let interval = economy.trickleHours * 3600
        let n = Int(now.timeIntervalSince(profile.lastTrickleAt) / interval)
        guard n > 0 else { return }
        profile.water += min(n, economy.trickleCap - profile.water)
        profile.lastTrickleAt = profile.water >= economy.trickleCap ? now : profile.lastTrickleAt.addingTimeInterval(Double(n) * interval)
    }

    /// Shared by tools: grow within the per-plant daily absorb cap (no cost handling here).
    static func applyGrowth(_ plant: PlantCollectible, desired: Int, now: Date, calendar: Calendar, economy: Economy) -> TendResult {
        resetDay(plant, now: now, calendar: calendar)
        let remaining = economy.dailyAbsorbCap - plant.absorbedToday
        guard remaining > 0 else { return .blocked(.fullForToday) }
        return grow(plant, by: min(desired, remaining))
    }

    // MARK: Helpers

    private static func refresh(_ plant: PlantCollectible, now: Date) {
        plant.hydration = 1.0
        plant.lastTendedAt = now
    }

    // MARK: Daily capacity (shown as a soft fill, never as a count)

    enum Capacity: Equatable { case room, nearly, plenty }

    private static func absorbedNow(_ plant: PlantCollectible, now: Date, calendar: Calendar) -> Int {
        guard let d = plant.absorbDay, calendar.isDate(d, inSameDayAs: now) else { return 0 }
        return plant.absorbedToday
    }

    static func capacityState(_ plant: PlantCollectible, now: Date, calendar: Calendar, economy: Economy) -> Capacity {
        let a = absorbedNow(plant, now: now, calendar: calendar)
        if a >= economy.dailyAbsorbCap { return .plenty }
        return a >= 6 ? .nearly : .room
    }

    static func capacityFill(_ plant: PlantCollectible, now: Date, calendar: Calendar, economy: Economy) -> Double {
        min(1, Double(absorbedNow(plant, now: now, calendar: calendar)) / Double(max(1, economy.dailyAbsorbCap)))
    }

    static func capacityLine(_ c: Capacity, name: String) -> String {
        switch c {
        case .room: return "Room for a little more."
        case .nearly: return "Almost full of sunshine today."
        case .plenty: return "\(name) has had plenty for today. Fresh start tomorrow."
        }
    }

    private static func resetDay(_ plant: PlantCollectible, now: Date, calendar: Calendar) {
        if let d = plant.absorbDay, calendar.isDate(d, inSameDayAs: now) { return }
        plant.absorbDay = calendar.startOfDay(for: now)
        plant.absorbedToday = 0
    }

    private static func grow(_ plant: PlantCollectible, by gain: Int) -> TendResult {
        plant.growthPoints += gain
        plant.absorbedToday += gain
        let newStage = max(plant.stage, stage(forGrowth: plant.growthPoints, level: plant.level))
        let up = newStage > plant.stage
        plant.stage = newStage
        return TendResult(applied: true, gpGained: gain, stageUp: up, reason: nil)
    }
}

import Foundation

struct TendResult: Equatable {
    /// `doneForToday`: this action's own daily allowance for this plant is used up (never because of another action).
    enum Reason: Equatable { case noWater, noSoil, doneForToday, notOwned, cooldown }
    var applied = false
    var gpGained = 0
    var stageUp = false
    var reason: Reason?

    static func blocked(_ r: Reason) -> TendResult { TendResult(applied: false, gpGained: 0, stageUp: false, reason: r) }
}

/// Gentle tending rules (spec sections 4, 16). Plants never die and stages only move forward.
/// THE RULE (2026-11-04): each action has its own daily allowance per plant, so no action ever blocks another,
/// and the Life meters read these same allowances, so a meter that is not full always means its button works.
enum TendingEngine {

    /// The three daily cares that each have a done state.
    enum Care: CaseIterable { case water, feed, sun }

    // MARK: Today's allowances (shared by the actions, the meters and the buttons)

    /// A per-day count: `count` if `day` is today in `calendar`, else 0.
    static func todayCount(_ count: Int, day: Date?, now: Date, calendar: Calendar) -> Int {
        guard let day, calendar.isDate(day, inSameDayAs: now) else { return 0 }
        return max(0, count)
    }

    static func isToday(_ date: Date?, now: Date, calendar: Calendar) -> Bool {
        guard let date else { return false }
        return calendar.isDate(date, inSameDayAs: now)
    }

    static func waterings(_ plant: PlantCollectible, now: Date, calendar: Calendar) -> Int {
        todayCount(plant.waterToday, day: plant.waterDay, now: now, calendar: calendar)
    }

    static func isDone(_ care: Care, plant: PlantCollectible, now: Date, calendar: Calendar, economy: Economy) -> Bool {
        switch care {
        case .water: return waterings(plant, now: now, calendar: calendar) >= max(1, economy.waterPerDay)
        case .feed: return isToday(plant.lastFedAt, now: now, calendar: calendar)
        case .sun: return isToday(plant.lastSunnyAt, now: now, calendar: calendar)
        }
    }

    // MARK: Actions

    static func water(_ plant: PlantCollectible, profile: PlayerProfile, now: Date, calendar: Calendar,
                      economy: Economy, quiet: Bool = false) -> TendResult {
        guard !isDone(.water, plant: plant, now: now, calendar: calendar, economy: economy) else { return .blocked(.doneForToday) }
        guard quiet || profile.water > 0 else { return .blocked(.noWater) }

        var desired = Double(economy.waterGrowth)
        if let until = plant.soilBoostUntil, until > now { desired *= economy.soilBoostMultiplier }
        if !quiet { profile.water -= 1 }
        plant.waterToday = waterings(plant, now: now, calendar: calendar) + 1
        plant.waterDay = calendar.startOfDay(for: now)
        refresh(plant, now: now)
        return grow(plant, by: Int(desired.rounded()), now: now, calendar: calendar)
    }

    static func addSoil(_ plant: PlantCollectible, profile: PlayerProfile, now: Date, calendar: Calendar,
                        economy: Economy, quiet: Bool = false, multiplier: Double = 1.0) -> TendResult {
        guard !isDone(.feed, plant: plant, now: now, calendar: calendar, economy: economy) else { return .blocked(.doneForToday) }
        guard quiet || profile.soil > 0 else { return .blocked(.noSoil) }

        if !quiet { profile.soil -= 1 }
        plant.lastFedAt = now
        plant.soilRichness = min(1.0, plant.soilRichness + economy.soilRichnessStep)
        plant.soilBoostUntil = now.addingTimeInterval(Double(economy.soilBoostDays) * 86_400)
        return grow(plant, by: Int((Double(economy.soilGrowth) * multiplier).rounded()), now: now, calendar: calendar)
    }

    /// Sun is free and once a day, in Quiet Garden too.
    static func sun(_ plant: PlantCollectible, profile: PlayerProfile, now: Date, calendar: Calendar,
                    economy: Economy, quiet: Bool = false, growth: Int? = nil) -> TendResult {
        guard !isDone(.sun, plant: plant, now: now, calendar: calendar, economy: economy) else { return .blocked(.doneForToday) }
        plant.lastSunnyAt = now
        return grow(plant, by: growth ?? economy.sunGrowth, now: now, calendar: calendar)
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

    /// Shared by tools (prune, happy repot), which pace themselves; no cost handling here.
    static func applyGrowth(_ plant: PlantCollectible, desired: Int, now: Date, calendar: Calendar, economy: Economy) -> TendResult {
        grow(plant, by: desired, now: now, calendar: calendar)
    }

    // MARK: Helpers

    private static func refresh(_ plant: PlantCollectible, now: Date) {
        plant.hydration = 1.0
        plant.lastTendedAt = now
    }

    // MARK: Today's summary (shown as a soft fill, never as a count)

    /// How much of today's care is done: two drinks, soil and sun. "Plenty" means every care is done for today.
    enum Capacity: Equatable, CaseIterable { case room, nearly, plenty }

    static func capacityFill(_ plant: PlantCollectible, now: Date, calendar: Calendar, economy: Economy) -> Double {
        let water = min(1, Double(waterings(plant, now: now, calendar: calendar)) / Double(max(1, economy.waterPerDay)))
        let fed: Double = isDone(.feed, plant: plant, now: now, calendar: calendar, economy: economy) ? 1 : 0
        let sunny: Double = isDone(.sun, plant: plant, now: now, calendar: calendar, economy: economy) ? 1 : 0
        return (water + fed + sunny) / 3
    }

    static func capacityState(_ plant: PlantCollectible, now: Date, calendar: Calendar, economy: Economy) -> Capacity {
        let done = Care.allCases.filter { isDone($0, plant: plant, now: now, calendar: calendar, economy: economy) }.count
        switch done {
        case 3: return .plenty
        case 2: return .nearly
        default: return .room
        }
    }

    static func capacityLine(_ c: Capacity, name: String) -> String {
        switch c {
        case .room: return "Room for a little more."
        case .nearly: return "\(name) is well cared for today."
        case .plenty: return "\(name) has had all its care today. More tomorrow!"
        }
    }

    /// Keeps the all-actions record of growth taken in today.
    private static func grow(_ plant: PlantCollectible, by gain: Int, now: Date, calendar: Calendar) -> TendResult {
        if !isToday(plant.absorbDay, now: now, calendar: calendar) {
            plant.absorbDay = calendar.startOfDay(for: now)
            plant.absorbedToday = 0
        }
        plant.growthPoints += gain
        plant.absorbedToday += gain
        let newStage = max(plant.stage, stage(forGrowth: plant.growthPoints, level: plant.level))
        let up = newStage > plant.stage
        plant.stage = newStage
        return TendResult(applied: true, gpGained: gain, stageUp: up, reason: nil)
    }
}

/// Every blocked-tap line (THE RULE, plan section b): a kind reason and a next step, at a grade-2 reading level, with no
/// banned words. Shared by the app, the widget, Siri and Control Center. `name` is the nickname when the plant has one.
enum TendCopy {
    static let canDry = "Your can is dry. Win a word to fill it."
    static let noScoops = "Out of soil scoops. Find a new plant to get more."
    static let needShears = "You need the shears first."

    static func done(_ care: TendingEngine.Care, name: String) -> String {
        switch care {
        case .water: return "\(name) has had all the water it needs today. Sun or a hello would be nice."
        case .sun: return "\(name) soaked up the sun today. More sun tomorrow!"
        case .feed: return "\(name) is well fed today. More soil tomorrow."
        }
    }

    static func trimmed(name: String) -> String { "\(name) had a trim. Trim again in two days." }
}

import Foundation

/// Pruning Pro (docs/pm/badge-mechanics-art.md, section 3): on some days a flowering plant shows one faded bloom, and a
/// trim that day is a tidy trim. Faded bloom only (no shaggy sprig, so plants below stage 3 never get a cue). Nothing is
/// stored: the cue is worked out from the weather seed, the plant id, the day, the stage and whether Prune is ready.
enum FadedBloom {
    /// About one day in this many is a faded bloom day for a plant.
    static let everyDays: UInt64 = 3
    /// Its own salt, so the cue never lines up with the friend of the day or the quest.
    static let salt: UInt64 = 0xFADE_B10C_5EED

    /// FNV-1a over the UTF-8 bytes. Swift's `hashValue` changes on every launch and would make the cue flicker.
    static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    /// The day's mixed value for one plant, mixed the same way as `VisitorSpawner.friendOfTheDay`.
    static func mixed(seed: Int64, plantId: String, day: Int) -> UInt64 {
        WeatherEngine.mix(UInt64(bitPattern: seed) ^ stableHash(plantId) ^ WeatherEngine.mix(UInt64(bitPattern: Int64(day)) &+ salt))
    }

    /// True on about one day in three for this plant, the same answer on every device and every launch.
    static func isCueDay(seed: Int64, plantId: String, day: Int) -> Bool {
        mixed(seed: seed, plantId: plantId, day: day) % everyDays == 0
    }

    /// The cue shows on a plant in flower (stage 3 or more) when Prune is ready for it now (owned, not pruned today and
    /// not in the shears' rest) on one of its faded bloom days.
    static func shows(seed: Int64, plantId: String, day: Int, stage: Int, pruneReady: Bool) -> Bool {
        stage >= BadgeFacts.floweringStage && pruneReady && isCueDay(seed: seed, plantId: plantId, day: day)
    }

    /// A trim made while the cue showed is a tidy trim. The answer can be worked out again later from the day the trim
    /// was made, so the fresh bud needs no stored flag either.
    static func wasTidy(seed: Int64, plantId: String, prunedDay: Int, stage: Int) -> Bool {
        stage >= BadgeFacts.floweringStage && isCueDay(seed: seed, plantId: plantId, day: prunedDay)
    }

    /// The fresh bud shows on visits after a tidy trim (not the same day, which shows the snip) while the shears rest.
    static func showsFreshBud(seed: Int64, plantId: String, today: Int, prunedDay: Int?, stage: Int, resting: Bool) -> Bool {
        guard let prunedDay, resting, prunedDay < today else { return false }
        return wasTidy(seed: seed, plantId: plantId, prunedDay: prunedDay, stage: stage)
    }

    /// Where the faded bloom sits on the plant art, as a fraction of the art's size: one of a few spots in the upper
    /// leaves, picked with the same seeded mix so it is the same spot all day.
    static let spots: [(x: Double, y: Double)] = [(0.40, 0.26), (0.60, 0.24), (0.50, 0.20), (0.36, 0.34), (0.64, 0.32)]
    static func spot(seed: Int64, plantId: String, day: Int) -> (x: Double, y: Double) {
        spots[spotIndex(seed: seed, plantId: plantId, day: day)]
    }

    /// Which of the five base spots is picked today (the seeded pick; the per-plant nudge below never changes it).
    static func spotIndex(seed: Int64, plantId: String, day: Int) -> Int {
        Int((mixed(seed: seed, plantId: plantId, day: day) >> 16) % UInt64(spots.count))
    }

    // MARK: Per-plant nudges (docs/pm/faded-bloom-offsets.md)

    /// A nudge for one plant: `dy` moves the spot down, `dx` sideways, `xk` pulls it toward the centre line (1 = none).
    struct SpotFix: Equatable {
        var dy: Double, dx: Double, xk: Double
        static let none = SpotFix(dy: 0, dx: 0, xk: 1)
    }

    /// Per-plant nudges so the faded bloom always lands on the plant (static check of all 50 plants, 2026-11-07).
    /// Keyed by plant id (the asset name without "plant_", as `PlantInfo.plantId`). Low, wide or narrow plants only;
    /// every plant not listed keeps the base spot.
    static let spotFix: [String: SpotFix] = [
        "lithops":          SpotFix(dy: 0.28, dx: 0,     xk: 0.4),
        "ghost_pipe":       SpotFix(dy: 0.25, dx: 0,     xk: 0.5),
        "giant_water_lily": SpotFix(dy: 0.33, dx: 0,     xk: 0.3),
        "lotus":            SpotFix(dy: 0.33, dx: 0,     xk: 0.3),
        "welwitschia":      SpotFix(dy: 0.18, dx: 0,     xk: 1),
        "strawberry":       SpotFix(dy: 0.15, dx: 0,     xk: 1),
        "sundew":           SpotFix(dy: 0.15, dx: 0,     xk: 0.6),
        "aloe_vera":        SpotFix(dy: 0.08, dx: 0,     xk: 1),
        "jasmine":          SpotFix(dy: 0.10, dx: 0.08,  xk: 1),
        "dandelion":        SpotFix(dy: 0.05, dx: -0.10, xk: 1),
        "corpse_flower":    SpotFix(dy: 0.06, dx: 0,     xk: 0.2),
        "puya_raimondii":   SpotFix(dy: 0,    dx: 0,     xk: 0.25),
        "silversword":      SpotFix(dy: 0,    dx: 0,     xk: 0.2),
        "saguaro_cactus":   SpotFix(dy: 0,    dx: 0,     xk: 0.3),
        "snapdragon":       SpotFix(dy: 0,    dx: 0,     xk: 0.3),
    ]

    /// The spot after the plant's nudge, kept inside the art box (0.1 to 0.9 on both axes):
    /// `x' = clamp(0.5 + (x - 0.5) * xk + dx)`, `y' = clamp(y + dy)`.
    static func adjusted(_ spot: (x: Double, y: Double), plantId: String, table: [String: SpotFix] = spotFix) -> (x: Double, y: Double) {
        let f = table[plantId] ?? .none
        return (clampToBox(0.5 + (spot.x - 0.5) * f.xk + f.dx), clampToBox(spot.y + f.dy))
    }

    static func clampToBox(_ v: Double) -> Double { min(0.9, max(0.1, v)) }

    /// Where the faded bloom is drawn today: the seeded spot with the plant's nudge applied.
    static func placedSpot(seed: Int64, plantId: String, day: Int) -> (x: Double, y: Double) {
        adjusted(spot(seed: seed, plantId: plantId, day: day), plantId: plantId)
    }
}

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
        spots[Int((mixed(seed: seed, plantId: plantId, day: day) >> 16) % UInt64(spots.count))]
    }
}

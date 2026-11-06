import Foundation

// The Grand Garden endgame on the app model (G-2 to G-5, docs/pm/endgame-and-events-spec.md section 2). Everything is
// computed from earned values; the only writes are the dates a ceremony was seen and golden days earned by tending.
extension AppModel {
    private var endgameProgress: [PlantProgress] {
        plants().map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) }
    }

    var allPlantsFoundNow: Bool { EndgamePolicy.allFound(endgameProgress) }
    var allFullBloomNow: Bool { EndgamePolicy.allFullBloom(endgameProgress) }

    /// The crown on the Home wordmark (shown, never owned, so it can never be taken away).
    var crown: EndgamePolicy.Crown {
        let p = endgameProgress
        return EndgamePolicy.crown(allFound: EndgamePolicy.allFound(p), allFullBloom: EndgamePolicy.allFullBloom(p))
    }

    /// The ceremony Home should play now, if any (each plays once per player, on any device).
    var pendingCeremony: EndgamePolicy.Ceremony? {
        let p = endgameProgress
        return EndgamePolicy.nextCeremony(allFound: EndgamePolicy.allFound(p), allFullBloom: EndgamePolicy.allFullBloom(p),
                                          crownSeenAt: profile?.crownSeenAt, goldCrownSeenAt: profile?.goldCrownSeenAt)
    }

    /// Called as the ceremony appears: it will not play again (merge: min of non-nil), and this visit stays free of
    /// Plus cards and ads.
    func markCeremonySeen(_ c: EndgamePolicy.Ceremony) {
        guard let p = profile else { return }
        markQuietVisit()
        switch c {
        case .grandGarden: if p.crownSeenAt == nil { p.crownSeenAt = now() }
        case .goldCrown: if p.goldCrownSeenAt == nil { p.goldCrownSeenAt = now() }
        }
        try? context.save()
        play(.levelUp)
    }

    // MARK: Golden blooms (G-4)

    /// Tending (water, feed, sun or prune; not a hello or a repot) a full-bloom plant once every plant is found adds one
    /// golden day, at most one a day. Returns true when this tend made the plant golden.
    func recordGoldenDay(_ plant: PlantCollectible, tending action: TendAction, at date: Date) -> Bool {
        let tending: Bool
        switch action {
        case .water, .feed, .sun, .prune: tending = true
        case .repot: tending = false
        }
        guard EndgamePolicy.countsTowardGolden(allFound: allPlantsFoundNow, stage: plant.stage, isTending: tending) else { return false }
        let wasGolden = EndgamePolicy.isGolden(days: plant.goldenDays)
        let g = EndgamePolicy.goldenDays(current: plant.goldenDays, lastKey: plant.goldenDayKey, careKey: WeatherDay.key(date))
        plant.goldenDays = g.days; plant.goldenDayKey = g.key
        return !wasGolden && EndgamePolicy.isGolden(days: g.days)
    }

    func isGolden(_ plant: PlantCollectible) -> Bool { EndgamePolicy.isGolden(days: plant.goldenDays) }

    /// Home's featured plant: the one nearest to golden today.
    var featuredGolden: EndgamePolicy.GoldenCandidate? {
        EndgamePolicy.featuredGolden(plants().map(\.goldenCandidate), allFound: allPlantsFoundNow, day: weatherToday)
    }

    var everyPlantGolden: Bool { allPlantsFoundNow && EndgamePolicy.allGolden(plants().map(\.goldenDays)) }

    // MARK: Bloom ranks and the Visitors' book (G-5)

    var bloomRank: BloomRank { EndgamePolicy.bloomRank(dailyBloomsDone: badges.progress(of: .dailyBloomsDone)) }
    var bloomsToNextRank: Int? { EndgamePolicy.bloomsToNextRank(dailyBloomsDone: badges.progress(of: .dailyBloomsDone)) }
}

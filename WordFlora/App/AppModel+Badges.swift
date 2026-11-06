import Foundation

/// The badges worked out from the garden, the album, the Shed and what the player reads (BadgeFacts), and badge
/// sharing. Every change goes through `updateBadges`, so Quiet Garden (no progress at all) and saving stay in one place.
extension AppModel {
    private static let traitsById: [String: Set<String>] = {
        Dictionary(((try? PlantCatalog.load()) ?? []).map { ($0.plantId, $0.traitSet) }, uniquingKeysWith: { a, _ in a })
    }()

    /// The plants found so far, with their catalogue traits.
    var badgePlants: [BadgeFacts.Plant] {
        plants().filter { $0.earnedCount > 0 }
            .map { BadgeFacts.Plant(level: $0.level, stage: $0.stage, traits: Self.traitsById[$0.plantId] ?? []) }
    }

    /// Records the collection counts (plants by kind, in flower, full bloom) and the level reached, and returns the
    /// new tiers for the caller to show with its own moment. Saves, does not queue.
    @discardableResult
    func recordCollectionFacts(now t: Date, quiet: Bool) -> [BadgeUnlock] {
        let counts = BadgeFacts.collection(badgePlants)
        let level = profile?.currentLevel ?? 1
        return updateBadges(announce: false) { state, _, _ in
            var unlocks = [BadgeUnlock]()
            for (counter, n) in counts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                unlocks += state.record(counter, value: n, now: t, quiet: quiet)
            }
            unlocks += state.record(.levelReached, value: level, now: t, quiet: quiet)
            return unlocks
        }
    }

    /// One best-so-far value (Shed upgrades, facts read), with its moment.
    @discardableResult
    func recordBadgeValue(_ counter: BadgeCounter, _ value: Int, announce: Bool = true) -> [BadgeUnlock] {
        updateBadges(announce: announce) { state, quiet, t in state.record(counter, value: value, now: t, quiet: quiet) }
    }

    /// Catches up every badge that can be worked out from what is already there: the garden, the album, the level and
    /// the Shed. Run at launch, after a restore and when the Badges page opens, without moments (`announce: false`),
    /// so badges added in an update arrive quietly instead of as a pile of pop-ups.
    func refreshBadgeFacts(announce: Bool = false) {
        guard profile != nil else { return }
        let t = now(), quiet = settings.quietGarden
        var unlocks = recordCollectionFacts(now: t, quiet: quiet)
        let album = self.album, upgrades = BadgeFacts.shedUpgrades(inventory)
        unlocks += updateBadges(announce: false) { state, quiet, t in
            var u = [BadgeUnlock]()
            for (counter, n) in BadgeFacts.album(album).sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                u += state.record(counter, value: n, now: t, quiet: quiet)
            }
            u += state.record(.shedUpgrades, value: upgrades, now: t, quiet: quiet)
            return u
        }
        if announce { enqueueBadgeMoments(unlocks) }
    }

    /// Wild Discovery: the plant page's fact card was shown for this plant (each plant counts once).
    func noteFactCardRead(plantId: String) {
        guard !plantId.isEmpty, !badges.isMarked(.storiesRead, item: plantId) else { return }
        updateBadges(after: 0.6) { state, quiet, t in state.recordMark(.storiesRead, item: plantId, now: t, quiet: quiet) }
    }

    /// Field Notes: the Visitors' book is open, showing the fact of every friend met.
    func noteVisitorFactsRead() {
        let read = VisitorCatalog.all.filter { $0.fact != nil && album.count(of: $0.id) > 0 }.count
        guard read > badges.progress(of: .factsRead) else { return }
        recordBadgeValue(.factsRead, read)
    }

    // MARK: Sharing a badge card

    /// The share button leaves the app, so it is hidden for players under 13 and when the age is not known
    /// (the same line as every other outbound path, `ParentalGate.isRequired`). The Sharer badge hides with it.
    var canShareBadges: Bool { BadgeShare.isAllowed(ageBand: settings.ageBand) }

    /// Sharer: a badge card was shared (each badge and tier counts once).
    func noteBadgeShared(_ badgeId: String, tier: Int) {
        guard canShareBadges else { return }
        let item = "\(badgeId)#\(tier)"
        guard !badges.isMarked(.badgeShares, item: item) else { return }
        // The moment waits for the share sheet to close (a sheet holds badge moments).
        updateBadges(after: 0.6) { state, quiet, t in state.recordMark(.badgeShares, item: item, now: t, quiet: quiet) }
    }
}

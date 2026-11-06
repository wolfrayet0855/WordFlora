import XCTest
@testable import WordFlora

final class ButterflyAndBadgeTests: XCTestCase {
    var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    func at(_ h: Int, _ m: Int = 0) -> Date { utc.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: h, minute: m))! }

    // MARK: visitor catalog
    func testTwelveSpeciesWithFiveFourThreeRarity() {
        let all = VisitorCatalog.all
        XCTAssertEqual(all.count, 12)
        XCTAssertEqual(all.filter { $0.rarity == .common }.count, 5)
        XCTAssertEqual(all.filter { $0.rarity == .uncommon }.count, 4)
        XCTAssertEqual(all.filter { $0.rarity == .rare }.count, 3)
        XCTAssertEqual(Set(all.map(\.id)).count, 12)
    }

    func testOnlyFireflyAndLunaAreNightSpecies() {
        XCTAssertEqual(Set(VisitorCatalog.all.filter(\.nightOnly).map(\.id)), ["firefly", "luna"])
    }

    func testCorrectedFactsAreUsed() {
        XCTAssertEqual(VisitorCatalog.species("monarch")?.fact, "Monarch butterflies can fly up to 3,000 miles to a warm place for winter.")
        XCTAssertEqual(VisitorCatalog.species("dragonfly")?.fact, "Dragonfly ancestors flew in the sky about 300 million years ago, before dinosaurs.")
        XCTAssertEqual(VisitorCatalog.species("hummingbird")?.fact, "A hummingbird flaps its wings about 50 times a second.")
    }

    /// Every visitor has a short, fact-checked line a 7 to 9 year old can read (sources: docs/research/visitor-facts.md).
    func testEveryVisitorHasAShortGentleFact() throws {
        for v in VisitorCatalog.all {
            let fact = try XCTUnwrap(v.fact, "\(v.id) has no fact")
            let words = fact.split(whereSeparator: { $0 == " " }).map { $0.trimmingCharacters(in: .punctuationCharacters) }
            XCTAssertLessThanOrEqual(fact.count, 90, v.id)
            XCTAssertLessThanOrEqual(words.count, 16, v.id)
            // Short words: long ones are allowed only for the visitor's own name and a few science words we explain.
            let nameWords = v.name.lowercased().split(separator: " ").map(String.init)
            let long = words.map { $0.lowercased() }.filter { w in
                w.count > 9 && !nameWords.contains { w.hasPrefix($0) } && !["butterflies", "caterpillars"].contains(w)
            }
            XCTAssertEqual(long, [], v.id)
            let avg = Double(words.map(\.count).reduce(0, +)) / Double(words.count)
            XCTAssertLessThanOrEqual(avg, 5.5, v.id)
            XCTAssertEqual(CopySafety.check(fact), [], fact)
            XCTAssertTrue(fact.hasSuffix(".") || fact.hasSuffix("!"), v.id)
        }
    }

    func testRarityHasAPlainWord() {
        XCTAssertEqual(VisitorCatalog.Rarity.common.label, "Often seen")
        XCTAssertEqual(VisitorCatalog.Rarity.uncommon.label, "Sometimes seen")
        XCTAssertEqual(VisitorCatalog.Rarity.rare.label, "Rare visitor")
    }

    // MARK: Friend of the day
    func testFriendOfTheDayIsADayVisitorFixedPerSeedAndDay() {
        let a = VisitorSpawner.friendOfTheDay(seed: 42, day: 300)
        XCTAssertEqual(a, VisitorSpawner.friendOfTheDay(seed: 42, day: 300))
        XCTAssertFalse(a.nightOnly, "always a friend who can come in the daytime game")
        let days = Set((0..<60).map { VisitorSpawner.friendOfTheDay(seed: 42, day: $0).id })
        XCTAssertGreaterThan(days.count, 4, "it changes from day to day")
        let seeds = Set((1...40).map { VisitorSpawner.friendOfTheDay(seed: Int64($0) &* 7_919, day: 300).id })
        XCTAssertGreaterThan(seeds.count, 1, "players get different friends on the same day")
        XCTAssertTrue(Set(VisitorSpawner.pool(evening: false, lantern: false)).isSuperset(of: days))
    }

    func testFriendOfTheDayLine() {
        XCTAssertEqual(VisitorsCopy.friendOfTheDay("Monarch"), "Say hello to a Monarch today")
        XCTAssertEqual(VisitorsCopy.friendOfTheDay("Owl"), "Say hello to an Owl today")
        for v in VisitorCatalog.all { XCTAssertEqual(CopySafety.check(VisitorsCopy.friendOfTheDay(v.name)), []) }
    }

    // MARK: Visitors page
    func testAlbumRemembersWhenEachFriendWasSeen() {
        var a = StickerAlbum()
        a.add(["monarch"], on: at(9))
        a.add(["monarch", "ladybug"], on: at(15))
        XCTAssertEqual(a.count(of: "monarch"), 2)
        XCTAssertEqual(a.lastSeen(of: "monarch"), at(15))
        XCTAssertNil(a.lastSeen(of: "luna"))
        XCTAssertEqual(StickerAlbum(json: a.json), a)
    }

    func testOldAlbumJSONWithoutDatesStillReads() {
        let old = StickerAlbum(json: #"{"counts":{"monarch":3}}"#)
        XCTAssertEqual(old.count(of: "monarch"), 3)
        XCTAssertNil(old.lastSeen(of: "monarch"))
    }

    func testAlbumMergeKeepsTheLaterSeenDate() {
        var a = StickerAlbum(); a.add(["monarch"], on: at(9))
        var b = StickerAlbum(); b.add(["monarch", "monarch"], on: at(12))
        let m = a.merged(with: b)
        XCTAssertEqual(m.count(of: "monarch"), 2)
        XCTAssertEqual(m.lastSeen(of: "monarch"), at(12))
        XCTAssertEqual(b.merged(with: a).lastSeen(of: "monarch"), at(12))
    }

    func testVisitorsCopy() {
        XCTAssertEqual(VisitorsCopy.friendsMet(7, of: 12), "7 of 12 friends met")
        XCTAssertEqual(VisitorsCopy.metCount(1), "Met once")
        XCTAssertEqual(VisitorsCopy.metCount(3), "Met 3 times")
        XCTAssertEqual(VisitorsCopy.seen(at(15), now: at(18), calendar: utc), "Seen today")
        XCTAssertEqual(VisitorsCopy.seen(at(15), now: at(15).addingTimeInterval(86_400), calendar: utc), "Seen yesterday")
        XCTAssertEqual(VisitorsCopy.seen(at(15), now: at(15).addingTimeInterval(5 * 86_400), calendar: utc), "Seen 5 days ago")
        XCTAssertEqual(VisitorsCopy.notMetHint(nightOnly: true), "Comes out in the evening")
        XCTAssertEqual(VisitorsCopy.notMetHint(nightOnly: false), "Say hello in the game")
        for line in VisitorsCopy.all { XCTAssertEqual(CopySafety.check(line), [], line) }
    }

    // MARK: evening window
    func testEveningWindowIsHalfPastFiveToHalfPastNine() {
        XCTAssertFalse(VisitorSpawner.isEvening(at(17, 29), calendar: utc))
        XCTAssertTrue(VisitorSpawner.isEvening(at(17, 30), calendar: utc))
        XCTAssertTrue(VisitorSpawner.isEvening(at(21, 29), calendar: utc))
        XCTAssertFalse(VisitorSpawner.isEvening(at(21, 30), calendar: utc))
        XCTAssertFalse(VisitorSpawner.isEvening(at(3, 0), calendar: utc))
    }

    func testEveningUsesTheDevicesLocalTimeZone() {
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let d = utc.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 9, minute: 0))!   // 18:00 in Tokyo
        XCTAssertTrue(VisitorSpawner.isEvening(d, calendar: tokyo))
        XCTAssertFalse(VisitorSpawner.isEvening(d, calendar: utc))
    }

    func testPoolsByTimeOfDayAndLantern() {
        let day = VisitorSpawner.pool(evening: false, lantern: false)
        XCTAssertEqual(day.count, 10); XCTAssertFalse(day.contains("firefly"))
        let lantern = VisitorSpawner.pool(evening: false, lantern: true)
        XCTAssertEqual(lantern.count, 12)
    }

    /// Evening brings the night species AND keeps every day species, so someone who only plays in the evening can still
    /// complete the album and the Visitors badge. Night species count double in the draw.
    func testEveningFeaturesNightSpeciesButNeverLocksOutDayVisitors() {
        let dusk = VisitorSpawner.pool(evening: true, lantern: false)
        XCTAssertEqual(Set(dusk), Set(VisitorCatalog.all.map(\.id)))
        XCTAssertEqual(dusk.filter { $0 == "firefly" }.count, 2); XCTAssertEqual(dusk.filter { $0 == "luna" }.count, 2)
        XCTAssertEqual(dusk.filter { $0 == "monarch" }.count, 1)
    }

    func testSpawnIsDeterministicForASeedAndNeverEmptyPoolSafe() {
        var a = SplitMix64(seed: 5), b = SplitMix64(seed: 5)
        let pool = VisitorSpawner.pool(evening: false, lantern: false)
        XCTAssertEqual((0..<20).map { _ in VisitorSpawner.next(pool: pool, using: &a) },
                       (0..<20).map { _ in VisitorSpawner.next(pool: pool, using: &b) })
        var c = SplitMix64(seed: 1)
        XCTAssertNil(VisitorSpawner.next(pool: [], using: &c))
    }

    func testRareSpeciesAppearLessOftenThanCommon() {
        var rng = SplitMix64(seed: 42); var counts = [VisitorCatalog.Rarity: Int]()
        let pool = VisitorSpawner.pool(evening: false, lantern: true)
        for _ in 0..<6000 { if let id = VisitorSpawner.next(pool: pool, using: &rng), let s = VisitorCatalog.species(id) { counts[s.rarity, default: 0] += 1 } }
        XCTAssertGreaterThan(counts[.common] ?? 0, counts[.uncommon] ?? 0)
        XCTAssertGreaterThan(counts[.uncommon] ?? 0, counts[.rare] ?? 0)
        XCTAssertGreaterThan(counts[.rare] ?? 0, 0)
    }

    func testSimultaneousVisitorCapGrowsWithFloweringPlantsButIsBounded() {
        XCTAssertEqual(VisitorSpawner.maxVisitors(floweringPlants: 0), 2)
        XCTAssertEqual(VisitorSpawner.maxVisitors(floweringPlants: 4), 4)
        XCTAssertEqual(VisitorSpawner.maxVisitors(floweringPlants: 100), 8)
    }

    // MARK: rewards and album
    func testEveryPlayAwardsSomethingEvenWithNoCatches() {
        var rng = SplitMix64(seed: 1)
        let s = ButterflyRewards.summary(catches: [], playsToday: 0, using: &rng)
        XCTAssertEqual(s.water, 1); XCTAssertEqual(s.shedPoints, 2)
    }

    func testCatchesAddStickersAndRareCatchesPayMore() {
        var rng = SplitMix64(seed: 1)
        let s = ButterflyRewards.summary(catches: ["morpho", "honeybee", "honeybee"], playsToday: 0, using: &rng)
        XCTAssertEqual(Set(s.newStickerIds), ["morpho", "honeybee"])
        XCTAssertGreaterThan(s.shedPoints, 2)
    }

    func testPlaysBeyondTheDailyThreeRecordStickersButPayNothing() {
        var rng = SplitMix64(seed: 1)
        let s = ButterflyRewards.summary(catches: ["monarch"], playsToday: 3, using: &rng)
        XCTAssertEqual(s.water, 0); XCTAssertEqual(s.shedPoints, 0); XCTAssertEqual(s.scoops, 0)
        XCTAssertEqual(s.newStickerIds, ["monarch"])
    }

    func testScoopChanceIsRoughlyThirtyPercent() {
        var rng = SplitMix64(seed: 99); var got = 0
        for _ in 0..<2000 { got += ButterflyRewards.summary(catches: [], playsToday: 0, using: &rng).scoops }
        XCTAssertTrue((500...700).contains(got), "got \(got)")
    }

    func testAlbumCountsRoundTripAndCompleteness() {
        var album = StickerAlbum()
        album.add(["monarch", "monarch", "luna"])
        XCTAssertEqual(album.count(of: "monarch"), 2)
        XCTAssertEqual(album.species, 2)
        XCTAssertEqual(StickerAlbum(json: album.json), album)
        XCTAssertFalse(album.isComplete)
        album.add(VisitorCatalog.all.map(\.id)); XCTAssertTrue(album.isComplete)
    }

    func testDailyPlayCounterResetsOnANewLocalDay() {
        var plays = DailyPlayCounter()
        plays.record(on: at(10), calendar: utc); plays.record(on: at(12), calendar: utc)
        XCTAssertEqual(plays.playsToday(on: at(13), calendar: utc), 2)
        XCTAssertEqual(plays.playsToday(on: utc.date(byAdding: .day, value: 1, to: at(1))!, calendar: utc), 0)
    }

    // MARK: badges
    func testCatalogLoadsWithThreeAscendingTiersAndUniqueIds() throws {
        let defs = try BadgeCatalog.load()
        XCTAssertGreaterThanOrEqual(defs.count, 10)
        XCTAssertEqual(Set(defs.map(\.id)).count, defs.count)
        for d in defs {
            XCTAssertEqual(d.thresholds.count, 3, d.id)
            XCTAssertEqual(d.thresholds, d.thresholds.sorted(), d.id)
            XCTAssertTrue(BadgeCatalog.knownCounters.contains(d.counter), d.id)
        }
    }

    func testCrossingAThresholdUnlocksTheTierExactlyOnce() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        var events = [BadgeUnlock]()
        for _ in 0..<26 { events += s.record(.waterings, now: at(9)) }
        let mine = events.filter { $0.badgeId == "green_thumb" }
        XCTAssertEqual(mine.map(\.tier), [1])           // 25 waterings = bronze, and only once
    }

    func testOneBigJumpReportsEveryTierCrossed() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        let unlocks = s.record(.waterings, amount: 1000, now: at(9)).filter { $0.badgeId == "green_thumb" }
        XCTAssertEqual(unlocks.map(\.tier), [1, 2, 3])
    }

    func testHighWaterCountersOnlyGoUpAndNothingIsRevoked() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        _ = s.record(.streak, value: 30, now: at(9))
        let before = s.unlocked
        _ = s.record(.streak, value: 2, now: at(10))
        XCTAssertEqual(s.progress(of: .streak), 30)
        XCTAssertEqual(s.unlocked, before)
    }

    func testStatePersistsThroughJSON() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        _ = s.record(.feeds, amount: 30, now: at(9))
        XCTAssertEqual(try BadgeState(json: s.json, defs: BadgeCatalog.load()), s)
        XCTAssertEqual(try BadgeState(json: "garbage", defs: BadgeCatalog.load()).unlocked.count, 0)
    }

    func testMergeTakesMaxProgressAndEarliestUnlockDates() throws {
        let defs = try BadgeCatalog.load()
        var a = BadgeState(defs: defs), b = BadgeState(defs: defs)
        _ = a.record(.feeds, amount: 30, now: at(9))
        _ = b.record(.feeds, amount: 60, now: at(8))
        let m = a.merged(with: b)
        XCTAssertEqual(m.progress(of: .feeds), 60)
        XCTAssertEqual(m.unlockedDate(badge: "feeder", tier: 1), at(8))   // earliest wins
    }

    func testQuietGardenAdvancesNoBadgeProgress() throws {
        var s = BadgeState(defs: try BadgeCatalog.load())
        XCTAssertEqual(s.record(.waterings, amount: 500, now: at(9), quiet: true), [])
        XCTAssertEqual(s.progress(of: .waterings), 0)
    }

    // MARK: shipped art and copy
    func testEveryBadgeHasTitleBlurbAndArtForAllThreeTiers() throws {
        for d in try BadgeCatalog.load() {
            XCTAssertFalse((d.title ?? "").isEmpty, d.id); XCTAssertFalse((d.blurb ?? "").isEmpty, d.id)
            XCTAssertEqual(CopySafety.check(d.title ?? ""), [], d.id); XCTAssertEqual(CopySafety.check(d.blurb ?? ""), [], d.id)
            // The Weathered badge is drawn in code (WeatheredBadgeArt); every other badge ships image art.
            if BadgeArtView.drawn.contains(d.id) { continue }
            for tier in 1...3 { XCTAssertNotNil(UIImage(named: "badge_\(d.id)_t\(tier)"), "missing art badge_\(d.id)_t\(tier)") }
        }
    }

    func testEveryToolHasArtForAllThreeTiers() {
        for tool in ToolID.allCases { for tier in 1...3 { XCTAssertNotNil(UIImage(named: "tool_\(tool.rawValue)_t\(tier)"), "\(tool) t\(tier)") } }
    }

    func testEveryVisitorHasIdleAndStickerArt() {
        for v in VisitorCatalog.all {
            XCTAssertNotNil(UIImage(named: "visitor_\(v.id)_idle"), v.id); XCTAssertNotNil(UIImage(named: "visitor_\(v.id)_sticker"), v.id)
        }
    }
}


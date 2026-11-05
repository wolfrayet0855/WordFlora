import XCTest
import SwiftData
@testable import WordFlora

// Garden weather rules (docs/pm/endgame-and-events-spec.md section 10, items 1-7 and 11).

// MARK: 1. Day key

final class WeatherDayTests: XCTestCase {
    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0, tz: String) -> Date {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: tz)!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testEpochIsTheFirstOfJanuary2026() {
        let utc = TimeZone(identifier: "UTC")!
        XCTAssertEqual(WeatherDay.key(date(2026, 1, 1, tz: "UTC"), timeZone: utc), 0)
        XCTAssertEqual(WeatherDay.key(date(2026, 1, 2, 0, 1, tz: "UTC"), timeZone: utc), 1)
        XCTAssertEqual(WeatherDay.key(date(2025, 12, 31, 23, 59, tz: "UTC"), timeZone: utc), -1)
        XCTAssertEqual(WeatherDay.key(date(2027, 1, 1, tz: "UTC"), timeZone: utc), 365)
    }

    func testTheKeyIgnoresBuddhistAndJapaneseCalendarSettings() {
        let tz = TimeZone(identifier: "Asia/Bangkok")!
        let d = date(2026, 11, 5, tz: "Asia/Bangkok")
        var greg = Calendar(identifier: .gregorian); greg.timeZone = tz
        let expected = WakePuzzle.day(for: d, calendar: greg)
        XCTAssertEqual(WeatherDay.key(d, timeZone: tz), expected)
        for id in [Calendar.Identifier.buddhist, .japanese] {
            var other = Calendar(identifier: id); other.timeZone = tz
            // The wake puzzle's day reads whichever calendar it is given; the weather key never does.
            XCTAssertNotEqual(WakePuzzle.day(for: d, calendar: other), expected, "\(id) builds a different epoch")
            XCTAssertEqual(WeatherDay.key(d, timeZone: tz), expected, "\(id)")
        }
    }

    func testDaylightSavingDaysGiveConsecutiveKeys() {
        let tz = TimeZone(identifier: "America/New_York")!
        for (m, d) in [(3, 7), (3, 8), (10, 31), (11, 1)] {
            for (h, mm) in [(0, 30), (12, 0), (23, 30)] {
                let today = WeatherDay.key(date(2026, m, d, h, mm, tz: "America/New_York"), timeZone: tz)
                var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
                let next = cal.date(byAdding: .day, value: 1, to: date(2026, m, d, h, mm, tz: "America/New_York"))!
                XCTAssertEqual(WeatherDay.key(next, timeZone: tz), today + 1, "\(m)/\(d) \(h):\(mm)")
            }
        }
    }

    func testATimeZoneMoveChangesTheKeyByAtMostOne() {
        let pairs = [("Europe/London", "America/New_York"), ("Asia/Tokyo", "America/Los_Angeles"), ("Australia/Sydney", "Europe/Paris")]
        let utc = TimeZone(identifier: "UTC")!
        var cal = Calendar(identifier: .gregorian); cal.timeZone = utc
        let start = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        for hour in stride(from: 0, to: 24 * 7, by: 1) {
            let d = start.addingTimeInterval(Double(hour) * 3600)
            for (a, b) in pairs {
                let ka = WeatherDay.key(d, timeZone: TimeZone(identifier: a)!), kb = WeatherDay.key(d, timeZone: TimeZone(identifier: b)!)
                XCTAssertLessThanOrEqual(abs(ka - kb), 1, "\(a) vs \(b) at +\(hour)h")
            }
        }
    }
}

// MARK: 2. Schedule

final class WeatherScheduleTests: XCTestCase {
    let eco = Economy.default
    /// A few hundred seeds keeps the suite fast; the spec's 2,000 x 400 gives the same picture.
    lazy var seeds: [(seed: Int64, start: Int)] = {
        var rng = SplitMix64(seed: 2026_11_05)
        return (0..<300).map { _ in
            var s: Int64 = 0
            while s == 0 { s = Int64(bitPattern: rng.next()) }
            return (s, 1 + Int(rng.next() % 200))
        }
    }()

    func testNoEventBeforeTheStartDayAndNoneWithoutASeed() {
        for (seed, start) in seeds.prefix(60) {
            for d in (start - 40)..<start { XCTAssertNil(WeatherEngine.event(day: d, seed: seed, startDay: start, economy: eco)) }
        }
        for d in 0..<400 { XCTAssertNil(WeatherEngine.event(day: d, seed: 0, startDay: 1, economy: eco), "seed 0 means unset") }
    }

    func testScanningDaysMatchesTheEventList() {
        for (seed, start) in seeds.prefix(40) {
            let scanned = (start - 10...start + 400).compactMap { d in WeatherEngine.event(day: d, seed: seed, startDay: start, economy: eco).map { (d, $0) } }
            let listed = WeatherEngine.events(from: start - 10, through: start + 400, seed: seed, startDay: start, economy: eco)
            XCTAssertEqual(scanned.map(\.0), listed.map(\.day))
            XCTAssertEqual(scanned.map(\.1), listed.map(\.kind))
            let tail = WeatherEngine.events(from: start + 150, through: start + 400, seed: seed, startDay: start, economy: eco)
            XCTAssertEqual(tail.map(\.kind), listed.filter { $0.day >= start + 150 }.map(\.kind), "a later window agrees on kinds")
        }
    }

    func testGapsKindsAndShareOverManySeeds() {
        var gaps: [Int] = [], big = 0, total = 0
        for (seed, start) in seeds {
            let list = WeatherEngine.events(from: start, through: start + 400, seed: seed, startDay: start, economy: eco)
            total += list.count; big += list.filter { $0.kind.isBig }.count
            for (a, b) in zip(list, list.dropFirst()) {
                let gap = b.day - a.day
                XCTAssertGreaterThanOrEqual(gap, 8, "seed \(seed): two events \(gap) days apart")
                XCTAssertNotEqual(a.kind, b.kind, "seed \(seed): two events in a row share \(a.kind)")
                gaps.append(gap)
            }
        }
        let mean = Double(gaps.reduce(0, +)) / Double(gaps.count)
        XCTAssertEqual(mean, 18.7, accuracy: 1.5, "mean gap \(mean)")
        let share = Double(big) / Double(total)
        XCTAssertEqual(share, 0.30, accuracy: 0.03, "big share \(share)")
    }

    func testForecastIsTomorrowsEvent() {
        for (seed, start) in seeds.prefix(30) {
            for d in start - 3...start + 120 {
                XCTAssertEqual(WeatherEngine.forecast(day: d, seed: seed, startDay: start, economy: eco),
                               WeatherEngine.event(day: d + 1, seed: seed, startDay: start, economy: eco))
            }
        }
    }

    func testTheSameSeedAlwaysGivesTheSameWeather() {
        for (seed, start) in seeds.prefix(30) {
            let a = WeatherEngine.events(from: start, through: start + 400, seed: seed, startDay: start, economy: eco)
            let b = WeatherEngine.events(from: start, through: start + 400, seed: seed, startDay: start, economy: eco)
            XCTAssertEqual(a.map(\.day), b.map(\.day)); XCTAssertEqual(a.map(\.kind), b.map(\.kind))
        }
        let one = WeatherEngine.events(from: 1, through: 400, seed: 42, startDay: 1, economy: eco).map(\.day)
        let two = WeatherEngine.events(from: 1, through: 400, seed: 43, startDay: 1, economy: eco).map(\.day)
        XCTAssertNotEqual(one, two, "different seeds give different gardens")
    }

    func testEveryBagHasThreeBigAndSevenGentleWithNoMatchingNeighbours() {
        for (seed, _) in seeds.prefix(50) {
            for i in 0..<20 {
                let bag = WeatherEngine.rawBag(i, seed: seed, version: 1, economy: eco)
                XCTAssertEqual(bag.count, 10)
                XCTAssertEqual(bag.filter(\.isBig).count, 3)
                XCTAssertEqual(Set(bag.filter(\.isBig)), Set(WeatherKind.big))
                XCTAssertTrue(WeatherEngine.noNeighboursMatch(bag), "\(bag)")
            }
        }
    }

    func testABagThatStartsLikeThePreviousOneEndedIsFixedWithoutTouchingItsFinalSlot() {
        let bag: [WeatherKind] = [.frostyNight, .hotDay, .frostyNight, .drySpell, .bigPuddles, .hotDay, .busyBugs, .bigPuddles, .bigWind, .hailShower]
        let fixed = WeatherEngine.joined(bag, after: .frostyNight)
        XCTAssertNotEqual(fixed.first, .frostyNight)
        XCTAssertEqual(fixed.last, bag.last)
        XCTAssertTrue(WeatherEngine.noNeighboursMatch(fixed), "a plain first-two swap would give \(bag[1]), \(bag[0]), \(bag[2])")
        XCTAssertEqual(fixed.sorted { $0.rawValue < $1.rawValue }, bag.sorted { $0.rawValue < $1.rawValue })
        XCTAssertEqual(WeatherEngine.joined(bag, after: .bigWind), bag, "no clash, no change")
    }

    func testTheOrdinalCountsEarlierEventBlocks() {
        for (seed, start) in seeds.prefix(20) {
            let list = WeatherEngine.events(from: start, through: start + 400, seed: seed, startDay: start, economy: eco)
            for (i, e) in list.enumerated() {
                let block = (e.day - start) / eco.weatherBlockDays
                XCTAssertEqual(WeatherEngine.ordinal(block: block, seed: seed, startDay: start, economy: eco), i)
                XCTAssertEqual(WeatherEngine.kind(ordinal: i, seed: seed, startDay: start, economy: eco), e.kind)
            }
        }
    }

    func testAnAlgorithmCutoverLeavesEarlierDaysUnchanged() {
        var v2 = eco; v2.weatherAlgoVersion = 2; v2.weatherAlgoCutoverDay = 300
        var changed = 0
        for (seed, start) in seeds.prefix(60) {
            let before = WeatherEngine.events(from: start, through: start + 500, seed: seed, startDay: start, economy: eco)
            let after = WeatherEngine.events(from: start, through: start + 500, seed: seed, startDay: start, economy: v2)
            // Every block that began before the cutover keeps its days and kinds.
            let keep = { (d: Int) in start + ((d - start) / self.eco.weatherBlockDays) * self.eco.weatherBlockDays < 300 }
            XCTAssertEqual(before.filter { keep($0.day) }.map(\.day), after.filter { keep($0.day) }.map(\.day))
            XCTAssertEqual(before.filter { keep($0.day) }.map(\.kind), after.filter { keep($0.day) }.map(\.kind))
            if before.map(\.day) != after.map(\.day) { changed += 1 }
            for (a, b) in zip(after, after.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b.day - a.day, 8); XCTAssertNotEqual(a.kind, b.kind)
            }
        }
        XCTAssertGreaterThan(changed, 0, "the new version does change days after the cutover")
    }

    func testLatestEventLooksBackOnlyWithinItsWindow() {
        let (seed, start) = seeds[0]
        let list = WeatherEngine.events(from: start, through: start + 200, seed: seed, startDay: start, economy: eco)
        let e = list[2]
        for back in 0..<3 {
            let hit = WeatherEngine.latestEvent(onOrBefore: e.day + back, within: 3, seed: seed, startDay: start, economy: eco)
            XCTAssertEqual(hit?.day, e.day); XCTAssertEqual(hit?.kind, e.kind)
        }
        XCTAssertNil(WeatherEngine.latestEvent(onOrBefore: e.day + 3, within: 3, seed: seed, startDay: start, economy: eco))
        XCTAssertNil(WeatherEngine.latestEvent(onOrBefore: e.day - 1, within: 1, seed: seed, startDay: start, economy: eco))
    }

    func testANewSeedIsNeverZeroAndStartsAWeekAfterTheGardenBegan() {
        var rng = SplitMix64(seed: 7)
        let created = Date(timeIntervalSince1970: 1_780_000_000)
        let pair = WeatherEngine.newSeed(createdAt: created, using: &rng)
        XCTAssertNotEqual(pair.seed, 0)
        XCTAssertEqual(pair.startDay, WeatherDay.key(created) + 7)
        let old = WeatherEngine.newSeed(createdAt: Date(timeIntervalSince1970: 1_600_000_000), using: &rng)
        XCTAssertEqual(old.startDay, 1, "a garden from before 2026 still gets a nonzero start day")
    }
}

// MARK: 3. Merges

@MainActor
final class WeatherMergeTests: XCTestCase {
    let defs = (try? BadgeCatalog.load()) ?? []
    var container: ModelContainer!
    var ctx: ModelContext { container.mainContext }
    override func setUp() async throws { container = try SharedContainer.make(inMemory: true) }

    func profile(_ f: (PlayerProfile) -> Void) -> PlayerProfile { let p = PlayerProfile(); f(p); return p }

    func weatherFields(_ p: PlayerProfile) -> [String] {
        [String(p.weatherSeed), String(p.weatherStartDay), String(p.weatherHighWaterDay), String(p.weatherShelterDay),
         p.weatherRescuedDays.map(String.init).joined(separator: ","), String(p.weatherPuzzleDay), String(p.weatherPuzzleCount),
         String(p.wildWeather), String(p.weatherGatedFromDay), String(describing: p.weatherSeenAt), String(describing: p.weatherKitAt),
         String(describing: p.crownSeenAt), String(describing: p.goldCrownSeenAt)]
    }

    func testNewFieldsDefaultToOffAndUnset() {
        let p = PlayerProfile()
        XCTAssertEqual(p.weatherSeed, 0); XCTAssertEqual(p.weatherStartDay, 0); XCTAssertEqual(p.weatherHighWaterDay, 0)
        XCTAssertEqual(p.weatherShelterDay, 0); XCTAssertEqual(p.weatherRescuedDays, []); XCTAssertEqual(p.weatherPuzzleDay, 0)
        XCTAssertEqual(p.weatherPuzzleCount, 0); XCTAssertFalse(p.wildWeather); XCTAssertEqual(p.weatherGatedFromDay, 0)
        XCTAssertNil(p.weatherSeenAt); XCTAssertNil(p.weatherKitAt); XCTAssertNil(p.crownSeenAt); XCTAssertNil(p.goldCrownSeenAt)
        let c = PlantCollectible(name: "Rose", botanicalName: "", botanicalFact: "", level: 1, imageName: "plant_rose")
        XCTAssertEqual(c.goldenDays, 0); XCTAssertEqual(c.goldenDayKey, 0)
    }

    func testTheSeedPairRuleIsCommutativeAndIdempotent() {
        let cases: [((Int64, Int), (Int64, Int))] = [((5, 40), (9, 30)), ((5, 30), (9, 30)), ((5, 0), (9, 30)), ((0, 0), (9, 30)), ((0, 0), (0, 0)), ((7, 12), (7, 12))]
        for (a, b) in cases {
            let ab = WeatherEngine.mergedSeedPair((a.0, a.1), (b.0, b.1)), ba = WeatherEngine.mergedSeedPair((b.0, b.1), (a.0, a.1))
            XCTAssertTrue(ab == ba, "\(a) \(b)")
            let again = WeatherEngine.mergedSeedPair(ab, (b.0, b.1))
            XCTAssertTrue(again == ab, "idempotent \(a) \(b)")
        }
        XCTAssertTrue(WeatherEngine.mergedSeedPair((5, 40), (9, 30)) == (9, 30), "the earlier start day wins")
        XCTAssertTrue(WeatherEngine.mergedSeedPair((5, 30), (9, 30)) == (5, 30), "a tie goes to the smaller seed")
        XCTAssertTrue(WeatherEngine.mergedSeedPair((5, 0), (9, 30)) == (9, 30), "an unset start day never wins")

        // Through the reconciler, both merge orders give every field the same value.
        func a() -> PlayerProfile { profile { $0.weatherSeed = 5; $0.weatherStartDay = 40; $0.weatherHighWaterDay = 90; $0.weatherShelterDay = 70
            $0.weatherRescuedDays = [10, 50]; $0.weatherPuzzleDay = 80; $0.weatherPuzzleCount = 1; $0.wildWeather = true; $0.weatherGatedFromDay = 20
            $0.weatherSeenAt = Date(timeIntervalSince1970: 500); $0.weatherKitAt = Date(timeIntervalSince1970: 300)
            $0.crownSeenAt = Date(timeIntervalSince1970: 900); $0.goldCrownSeenAt = nil } }
        func b() -> PlayerProfile { profile { $0.weatherSeed = 9; $0.weatherStartDay = 30; $0.weatherHighWaterDay = 85; $0.weatherShelterDay = 75
            $0.weatherRescuedDays = [50, 60]; $0.weatherPuzzleDay = 80; $0.weatherPuzzleCount = 2; $0.wildWeather = false; $0.weatherGatedFromDay = 0
            $0.weatherSeenAt = Date(timeIntervalSince1970: 700); $0.weatherKitAt = nil
            $0.crownSeenAt = Date(timeIntervalSince1970: 800); $0.goldCrownSeenAt = Date(timeIntervalSince1970: 950) } }
        let k1 = a(); DataReconciler.merge(b(), into: k1, defs: defs)
        let k2 = b(); DataReconciler.merge(a(), into: k2, defs: defs)
        XCTAssertEqual(weatherFields(k1), weatherFields(k2))
        let k3 = a(); DataReconciler.merge(b(), into: k3, defs: defs); DataReconciler.merge(b(), into: k3, defs: defs)
        XCTAssertEqual(weatherFields(k3), weatherFields(k1), "merging twice changes nothing")

        XCTAssertEqual(k1.weatherSeed, 9); XCTAssertEqual(k1.weatherStartDay, 30)
        XCTAssertEqual(k1.weatherHighWaterDay, 90, "high water takes the max")
        XCTAssertEqual(k1.weatherShelterDay, 75)
        XCTAssertEqual(k1.weatherRescuedDays, [10, 50, 60], "union")
        XCTAssertEqual(k1.weatherPuzzleDay, 80); XCTAssertEqual(k1.weatherPuzzleCount, 2, "same day: the larger count")
        XCTAssertFalse(k1.wildWeather, "off wins")
        XCTAssertEqual(k1.weatherGatedFromDay, 20, "min of nonzero")
        XCTAssertEqual(k1.weatherSeenAt, Date(timeIntervalSince1970: 700), "seen: max")
        XCTAssertEqual(k1.weatherKitAt, Date(timeIntervalSince1970: 300), "kit: min of non-nil, never lost")
        XCTAssertEqual(k1.crownSeenAt, Date(timeIntervalSince1970: 800), "crown: min")
        XCTAssertEqual(k1.goldCrownSeenAt, Date(timeIntervalSince1970: 950))
    }

    func testRescuedDaysMergeByUnionAndKeepTheLatestThirty() {
        XCTAssertEqual(WeatherEngine.mergedRescuedDays(Array(1...25), Array(20...40)), Array(11...40))
        let k = profile { $0.weatherRescuedDays = Array(stride(from: 0, to: 400, by: 20)) }
        DataReconciler.merge(profile { $0.weatherRescuedDays = Array(stride(from: 10, to: 410, by: 20)) }, into: k, defs: defs)
        XCTAssertEqual(k.weatherRescuedDays.count, 30)
        XCTAssertEqual(k.weatherRescuedDays.last, 390); XCTAssertEqual(k.weatherRescuedDays.first, 100)
    }

    func testPuzzleCountsFollowTheLaterDay() {
        let k = profile { $0.weatherPuzzleDay = 80; $0.weatherPuzzleCount = 3 }
        DataReconciler.merge(profile { $0.weatherPuzzleDay = 81; $0.weatherPuzzleCount = 1 }, into: k, defs: defs)
        XCTAssertEqual(k.weatherPuzzleDay, 81); XCTAssertEqual(k.weatherPuzzleCount, 1)
        DataReconciler.merge(profile { $0.weatherPuzzleDay = 79; $0.weatherPuzzleCount = 3 }, into: k, defs: defs)
        XCTAssertEqual(k.weatherPuzzleDay, 81); XCTAssertEqual(k.weatherPuzzleCount, 1)
    }

    func testWildWeatherMergesByAnd() {
        for (x, y) in [(true, true), (true, false), (false, true), (false, false)] {
            let k = profile { $0.wildWeather = x }
            DataReconciler.merge(profile { $0.wildWeather = y }, into: k, defs: defs)
            XCTAssertEqual(k.wildWeather, x && y)
        }
    }

    func testGoldenDaysMergeLikeWaterAndNeverGoDown() {
        func plant(_ days: Int, _ key: Int) -> PlantCollectible {
            let c = PlantCollectible(name: "Rose", botanicalName: "", botanicalFact: "", level: 1, imageName: "plant_rose")
            c.goldenDays = days; c.goldenDayKey = key; return c
        }
        let k = plant(5, 100); DataReconciler.merge(plant(3, 101), into: k)
        XCTAssertEqual(k.goldenDayKey, 101, "the later key wins")
        XCTAssertEqual(k.goldenDays, 5, "a count of earned days never goes down")
        let s = plant(4, 100); DataReconciler.merge(plant(6, 100), into: s)
        XCTAssertEqual(s.goldenDays, 6); XCTAssertEqual(s.goldenDayKey, 100, "same key: the larger count")
        let r = plant(6, 100); DataReconciler.merge(plant(4, 100), into: r)
        XCTAssertEqual(r.goldenDays, 6)
    }

    func testTwoProfilesReconcileIntoOneWithTheWeatherPair() throws {
        let a = profile { $0.gamesPlayed = 30; $0.weatherSeed = 5; $0.weatherStartDay = 40; $0.wildWeather = true }
        let b = profile { $0.gamesPlayed = 10; $0.weatherSeed = 9; $0.weatherStartDay = 30; $0.wildWeather = true }
        ctx.insert(a); ctx.insert(b); try ctx.save()
        DataReconciler.reconcile(context: ctx, badgeDefs: defs)
        let p = try XCTUnwrap(try ctx.fetch(FetchDescriptor<PlayerProfile>()).first)
        XCTAssertEqual(p.weatherSeed, 9); XCTAssertEqual(p.weatherStartDay, 30); XCTAssertTrue(p.wildWeather)
    }

    // MARK: backup

    func seeded() throws -> ModelContainer {
        let c = try SharedContainer.make(inMemory: true)
        try PlantCatalog.seedIfNeeded(context: c.mainContext)
        return c
    }

    func testWeatherAndEndgameFieldsRoundTripThroughABackup() throws {
        let src = try seeded()
        let p = PlayerProfile(); src.mainContext.insert(p)
        p.weatherSeed = 123; p.weatherStartDay = 40; p.weatherHighWaterDay = 300; p.weatherShelterDay = 290; p.weatherRescuedDays = [100, 290]
        p.weatherPuzzleDay = 290; p.weatherPuzzleCount = 2; p.wildWeather = true; p.weatherGatedFromDay = 50
        p.weatherSeenAt = Date(timeIntervalSince1970: 5_000); p.weatherKitAt = Date(timeIntervalSince1970: 4_000)
        p.crownSeenAt = Date(timeIntervalSince1970: 6_000); p.goldCrownSeenAt = Date(timeIntervalSince1970: 7_000)
        let rose = try XCTUnwrap(try src.mainContext.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "rose" })
        rose.goldenDays = 4; rose.goldenDayKey = 299
        try src.mainContext.save()
        let data = try GardenBackup.make(context: src.mainContext, now: .now).encoded()

        let dst = try seeded()
        guard case .success = GardenBackup.restore(data, into: dst.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        let q = try XCTUnwrap(try dst.mainContext.fetch(FetchDescriptor<PlayerProfile>()).first)
        XCTAssertEqual(q.weatherSeed, 123); XCTAssertEqual(q.weatherStartDay, 40); XCTAssertEqual(q.weatherHighWaterDay, 300)
        XCTAssertEqual(q.weatherShelterDay, 290); XCTAssertEqual(q.weatherRescuedDays, [100, 290])
        XCTAssertEqual(q.weatherPuzzleDay, 290); XCTAssertEqual(q.weatherPuzzleCount, 2); XCTAssertEqual(q.weatherGatedFromDay, 50)
        XCTAssertEqual(q.weatherSeenAt, Date(timeIntervalSince1970: 5_000)); XCTAssertEqual(q.weatherKitAt, Date(timeIntervalSince1970: 4_000))
        XCTAssertEqual(q.crownSeenAt, Date(timeIntervalSince1970: 6_000)); XCTAssertEqual(q.goldCrownSeenAt, Date(timeIntervalSince1970: 7_000))
        XCTAssertFalse(q.wildWeather, "Wild Weather restores only as off: the player turns it on again on this device")
        let r = try XCTUnwrap(try dst.mainContext.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "rose" })
        XCTAssertEqual(r.goldenDays, 4); XCTAssertEqual(r.goldenDayKey, 299)

        // Restoring onto a garden that has Wild Weather on: a backup saying "on" keeps it on, one saying "off" turns it off.
        q.wildWeather = true; try dst.mainContext.save()
        _ = GardenBackup.restore(data, into: dst.mainContext, badgeDefs: defs)
        XCTAssertTrue(q.wildWeather)
        var off = try XCTUnwrap(try? GardenBackup.decode(data).get()); off.profile.wildWeather = false
        _ = GardenBackup.restore(try off.encoded(), into: dst.mainContext, badgeDefs: defs)
        XCTAssertFalse(q.wildWeather)
    }

    func testRestoreNeverLowersWeatherOrGoldenValues() throws {
        let src = try seeded()
        let p = PlayerProfile(); src.mainContext.insert(p)
        p.weatherSeed = 5; p.weatherStartDay = 60; p.weatherHighWaterDay = 100; p.weatherRescuedDays = [90]; p.weatherKitAt = Date(timeIntervalSince1970: 9_000)
        try src.mainContext.save()
        let data = try GardenBackup.make(context: src.mainContext, now: .now).encoded()

        let dst = try seeded()
        let q = PlayerProfile(); dst.mainContext.insert(q)
        q.weatherSeed = 7; q.weatherStartDay = 30; q.weatherHighWaterDay = 300; q.weatherRescuedDays = [250]
        q.weatherKitAt = Date(timeIntervalSince1970: 1_000); q.crownSeenAt = Date(timeIntervalSince1970: 2_000)
        let rose = try XCTUnwrap(try dst.mainContext.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "rose" })
        rose.goldenDays = 6; rose.goldenDayKey = 299
        try dst.mainContext.save()
        guard case .success = GardenBackup.restore(data, into: dst.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(q.weatherSeed, 7); XCTAssertEqual(q.weatherStartDay, 30, "the earlier start pair stays")
        XCTAssertEqual(q.weatherHighWaterDay, 300); XCTAssertEqual(q.weatherRescuedDays, [90, 250])
        XCTAssertEqual(q.weatherKitAt, Date(timeIntervalSince1970: 1_000)); XCTAssertEqual(q.crownSeenAt, Date(timeIntervalSince1970: 2_000))
        XCTAssertEqual(rose.goldenDays, 6); XCTAssertEqual(rose.goldenDayKey, 299)
    }

    func testOlderBackupsWithoutWeatherFieldsStillRead() throws {
        let src = try seeded()
        let p = PlayerProfile(); src.mainContext.insert(p); p.weatherSeed = 5; p.weatherStartDay = 60
        try src.mainContext.save()
        let data = try GardenBackup.make(context: src.mainContext, now: .now).encoded()
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var prof = json["profile"] as! [String: Any]
        for key in ["weatherSeed", "weatherStartDay", "weatherHighWaterDay", "weatherShelterDay", "weatherRescuedDays", "weatherPuzzleDay",
                    "weatherPuzzleCount", "wildWeather", "weatherGatedFromDay", "weatherSeenAt", "weatherKitAt", "crownSeenAt", "goldCrownSeenAt"] {
            prof.removeValue(forKey: key)
        }
        json["profile"] = prof
        json["plants"] = (json["plants"] as! [[String: Any]]).map { var x = $0; x.removeValue(forKey: "goldenDays"); x.removeValue(forKey: "goldenDayKey"); return x }
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .success(let decoded) = GardenBackup.decode(old) else { return XCTFail("an older backup should read") }
        XCTAssertNil(decoded.profile.weatherSeed); XCTAssertNil(decoded.plants.first?.goldenDays)
        XCTAssertEqual(GardenBackup.currentSchema, 1)

        let dst = try seeded()
        let q = PlayerProfile(); dst.mainContext.insert(q); q.weatherSeed = 9; q.weatherStartDay = 80; q.wildWeather = true
        try dst.mainContext.save()
        guard case .success = GardenBackup.restore(old, into: dst.mainContext, badgeDefs: defs) else { return XCTFail("restore failed") }
        XCTAssertEqual(q.weatherSeed, 9); XCTAssertEqual(q.weatherStartDay, 80)
        XCTAssertTrue(q.wildWeather, "a backup that never knew Wild Weather does not change the setting")
    }

    func testImplausibleWeatherValuesAreRejected() throws {
        let src = try seeded()
        src.mainContext.insert(PlayerProfile()); try src.mainContext.save()
        var b = GardenBackup.make(context: src.mainContext, now: .now)
        b.profile.weatherPuzzleCount = -1
        XCTAssertFalse(b.isPlausible)
        b = GardenBackup.make(context: src.mainContext, now: .now); b.profile.weatherRescuedDays = Array(0..<500)
        XCTAssertFalse(b.isPlausible)
        b = GardenBackup.make(context: src.mainContext, now: .now); b.plants[0].goldenDays = -2
        XCTAssertFalse(b.isPlausible)
    }
}

// MARK: 4. Effects

final class WeatherEffectTests: XCTestCase {
    func catalog() throws -> [(id: String, traits: Set<String>)] {
        try PlantCatalog.load().map { ($0.plantId, $0.traitSet) }
    }

    func testEveryCatalogPlantHasKnownTraits() throws {
        let plants = try PlantCatalog.load()
        XCTAssertEqual(plants.count, 50)
        for p in plants {
            XCTAssertFalse(p.traitSet.isEmpty, "\(p.name) has no traits")
            XCTAssertTrue(p.traitSet.isSubset(of: WeatherEngine.knownTraits), "\(p.name): \(p.traitSet.subtracting(WeatherEngine.knownTraits))")
        }
    }

    func testEveryKindHasAPlantThatShrugsItOffAndOneItReachesFully() throws {
        let plants = try catalog()
        for k in WeatherKind.allCases {
            XCTAssertTrue(plants.contains { WeatherEngine.effect(k, traits: $0.traits) == .shrugs }, "\(k): nobody shrugs it off")
            XCTAssertTrue(plants.contains { WeatherEngine.effect(k, traits: $0.traits) == .full }, "\(k): nobody gets the full look")
        }
    }

    func testTheEffectTableMatchesTheSpec() {
        let e = WeatherEngine.effect
        XCTAssertEqual(e(.drySpell, ["succulent"]), .shrugs); XCTAssertEqual(e(.drySpell, ["bog"]), .full); XCTAssertEqual(e(.drySpell, ["meadow"]), .light)
        XCTAssertEqual(e(.busyBugs, ["carnivorous"]), .shrugs); XCTAssertEqual(e(.busyBugs, ["woody"]), .full)
        XCTAssertEqual(e(.bigWind, ["flexible"]), .shrugs); XCTAssertEqual(e(.bigWind, ["tall"]), .full)
        XCTAssertEqual(e(.frostyNight, ["alpine"]), .shrugs); XCTAssertEqual(e(.frostyNight, ["tropical"]), .full)
        XCTAssertEqual(e(.hotDay, ["desert"]), .shrugs); XCTAssertEqual(e(.hotDay, ["shade"]), .full)
        XCTAssertEqual(e(.hailShower, ["hardyTree"]), .shrugs); XCTAssertEqual(e(.hailShower, ["bigLeaf"]), .full)
        XCTAssertEqual(e(.bigPuddles, ["aquatic"]), .shrugs); XCTAssertEqual(e(.bigPuddles, ["succulent"]), .full)
        XCTAssertEqual(e(.hotDay, []), .light)
    }

    func testShrugsBeatsFull() throws {
        XCTAssertEqual(WeatherEngine.effect(.bigPuddles, traits: ["desert", "aquatic"]), .shrugs)
        let bamboo = try XCTUnwrap(try catalog().first { $0.id == "bamboo" })
        XCTAssertTrue(bamboo.traits.isSuperset(of: ["tall", "flexible"]))
        XCTAssertEqual(WeatherEngine.effect(.bigWind, traits: bamboo.traits), .shrugs, "bamboo bends in the wind")
        let lithops = try XCTUnwrap(try catalog().first { $0.id == "lithops" })
        XCTAssertEqual(WeatherEngine.effect(.drySpell, traits: lithops.traits), .shrugs)
    }

    func testAtMostFortyPercentShowTheFullEffect() throws {
        let all = try catalog()
        for k in WeatherKind.allCases {
            for n in [1, 3, 5, 12, 27, 50] {
                for day in [10, 77, 300] {
                    let found = Array(all.prefix(n))
                    let fx = WeatherEngine.affected(k, plants: found, day: day, cap: 0.4)
                    let fullCount = fx.values.filter { $0 == .full }.count
                    XCTAssertLessThanOrEqual(fullCount, Int((0.4 * Double(n)).rounded(.up)), "\(k) n=\(n)")
                    XCTAssertEqual(fx.count, n)
                    for p in found where WeatherEngine.effect(k, traits: p.traits) == .shrugs { XCTAssertEqual(fx[p.id], .shrugs) }
                    for p in found where WeatherEngine.effect(k, traits: p.traits) == .light { XCTAssertEqual(fx[p.id], .light) }
                }
            }
        }
        // Puddles meet many desert plants: the cap turns the rest light.
        let desertOnly = (0..<10).map { (id: "d\($0)", traits: Set(["desert"])) }
        let fx = WeatherEngine.affected(.bigPuddles, plants: desertOnly, day: 5, cap: 0.4)
        XCTAssertEqual(fx.values.filter { $0 == .full }.count, 4); XCTAssertEqual(fx.values.filter { $0 == .light }.count, 6)
    }

    func testTheCapOrderIsDeterministic() throws {
        let all = try catalog()
        let a = WeatherEngine.affected(.busyBugs, plants: all, day: 123, cap: 0.1)
        let b = WeatherEngine.affected(.busyBugs, plants: all.reversed(), day: 123, cap: 0.1)
        XCTAssertEqual(a, b, "input order does not matter")
        XCTAssertEqual(WeatherEngine.fullRanks(.busyBugs, plants: all, day: 123, cap: 0.1),
                       WeatherEngine.fullRanks(.busyBugs, plants: all.shuffled(), day: 123, cap: 0.1))
        let ranks = WeatherEngine.fullRanks(.busyBugs, plants: all, day: 123, cap: 0.1)
        XCTAssertEqual(Set(ranks.values), Set(0..<ranks.count))
        let days = (1...40).map { WeatherEngine.affected(.busyBugs, plants: all, day: $0, cap: 0.1) }
        XCTAssertGreaterThan(Set(days.map { $0.filter { $0.value == .full }.keys.sorted() }).count, 1, "the pick changes from day to day")
    }
}

// MARK: 5. Looks

final class WeatherLookTests: XCTestCase {
    let tz = TimeZone(identifier: "UTC")!
    let event = 300
    /// Noon UTC on a day key.
    func at(_ day: Int, hour: Double = 12) -> Date { Date(timeIntervalSince1970: 1_767_225_600 + Double(day) * 86_400 + hour * 3600) }

    func input(kind: WeatherKind? = .bigWind, today: Int? = nil, effect: WeatherEffect = .full, care: Date? = nil, seen: Date?? = nil,
               sheltered: Bool = false, rescued: Bool = false, wild: Bool = false, stage: Int = 3, rank: Int = 0,
               calm: Bool = false, seed: Bool = false, rain: Bool = false) -> WeatherLook.Input {
        var i = WeatherLook.Input(kind: kind, eventDay: event, today: today ?? event, effect: effect, lastCareAt: care,
                                  seenAt: seen ?? at(event, hour: 8), sheltered: sheltered, rescued: rescued, wild: wild, stage: stage, rank: rank)
        i.calm = calm; i.isSeed = seed; i.loveRaining = rain; i.name = "Daisy"; i.timeZone = tz
        return i
    }

    func testTheEpochHelperMatchesTheKey() { XCTAssertEqual(WeatherDay.key(at(event), timeZone: tz), event) }

    func testAWitnessedEventShowsItsLookAndCareMendsItAtOnce() {
        let shown = WeatherLook.compute(input())
        XCTAssertEqual(shown.look, .full); XCTAssertEqual(shown.setback, 0); XCTAssertEqual(shown.shownStage, 3)
        XCTAssertEqual(shown.line, WeatherCopy.plantLine(name: "Daisy", .bigWind))
        let mended = WeatherLook.compute(input(care: at(event, hour: 9)))
        XCTAssertNil(mended.look); XCTAssertEqual(mended.shownStage, 3); XCTAssertTrue(mended.isEmpty)
        XCTAssertEqual(WeatherLook.compute(input(effect: .light)).look, .light)
    }

    func testCareBeforeTheGardenWasSeenDoesNotMend() {
        let early = WeatherLook.compute(input(care: at(event, hour: 7)))
        XCTAssertEqual(early.look, .full, "the morning hello came before the player saw the weather")
        XCTAssertEqual(WeatherLook.compute(input(care: at(event - 1, hour: 20))).look, .full)
    }

    func testNoLookBeforeTheGardenIsSeenOnOrAfterTheEventDay() {
        XCTAssertNil(WeatherLook.compute(input(seen: .some(nil))).look)
        XCTAssertNil(WeatherLook.compute(input(seen: at(event - 1, hour: 20))).look, "seen the day before does not count")
        XCTAssertEqual(WeatherLook.compute(input(today: event + 1, seen: at(event + 1, hour: 9))).look, .full)
    }

    func testTheLookFadesAfterThreeDaysOrFourInWildWeatherOrOneInCalm() {
        for d in 0..<3 { XCTAssertEqual(WeatherLook.compute(input(today: event + d)).look, .full, "day \(d)") }
        XCTAssertNil(WeatherLook.compute(input(today: event + 3)).look)
        for d in 0..<4 { XCTAssertEqual(WeatherLook.compute(input(today: event + d, wild: true)).setback, 1, "wild day \(d)") }
        let gone = WeatherLook.compute(input(today: event + 4, wild: true))
        XCTAssertNil(gone.look); XCTAssertEqual(gone.setback, 0); XCTAssertEqual(gone.shownStage, 3)
        XCTAssertEqual(WeatherLook.compute(input(calm: true)).look, .full)
        XCTAssertNil(WeatherLook.compute(input(today: event + 1, calm: true)).look)
        XCTAssertEqual(WeatherLook.linger(wild: false, calm: false), 3); XCTAssertEqual(WeatherLook.linger(wild: true, calm: false), 4)
        XCTAssertEqual(WeatherLook.linger(wild: true, calm: true), 1, "Calm never gets Wild Weather")
    }

    func testAReturnAfterTheLingerShowsNothing() {
        // Away for the whole event: opening the app on day 5 shows nothing, even with a fresh "seen" stamp.
        let late = WeatherLook.compute(input(today: event + 5, seen: at(event + 5, hour: 9), wild: true))
        XCTAssertTrue(late.isEmpty); XCTAssertEqual(late.shownStage, 3)
    }

    func testWildWeatherMendsTheDayAfterCare() {
        let careDay = WeatherLook.compute(input(care: at(event, hour: 10), wild: true))
        XCTAssertEqual(careDay.setback, 1, "still resting on the care day"); XCTAssertEqual(careDay.shownStage, 2)
        XCTAssertTrue(careDay.mending); XCTAssertEqual(careDay.line, WeatherCopy.mendingLine(name: "Daisy"))
        let next = WeatherLook.compute(input(today: event + 1, care: at(event, hour: 10), wild: true))
        XCTAssertEqual(next.setback, 0); XCTAssertEqual(next.shownStage, 3); XCTAssertTrue(next.isEmpty)
        let noCare = WeatherLook.compute(input(today: event + 1, wild: true))
        XCTAssertEqual(noCare.setback, 1); XCTAssertEqual(noCare.line, WeatherCopy.wildLine(name: "Daisy", .bigWind))
    }

    func testShelterShowsTheSnugLookOrHalvesTheWildSetback() {
        let snug = WeatherLook.compute(input(sheltered: true))
        XCTAssertEqual(snug.look, .snug); XCTAssertEqual(snug.setback, 0); XCTAssertEqual(snug.line, WeatherCopy.snugLine(name: "Daisy", .bigWind))
        XCTAssertEqual(WeatherLook.compute(input(today: event + 2, sheltered: true)).look, .snug, "snug needs no mending")
        for rank in 0..<6 {
            let open = WeatherLook.compute(input(wild: true, rank: rank)), covered = WeatherLook.compute(input(sheltered: true, wild: true, rank: rank))
            XCTAssertEqual(open.setback, rank < 4 ? 1 : 0, "rank \(rank) open")
            XCTAssertEqual(covered.setback, rank < 2 ? 1 : 0, "rank \(rank) sheltered")
            if covered.setback == 0 { XCTAssertEqual(covered.look, .snug) }
        }
    }

    func testARescueClearsEverything() {
        let r = WeatherLook.compute(input(rescued: true, wild: true))
        XCTAssertTrue(r.isEmpty); XCTAssertEqual(r.setback, 0); XCTAssertEqual(r.shownStage, 3)
    }

    func testGentleKindsAndLightOrShrugPlantsHaveNoSetback() {
        for k in WeatherKind.allCases where !k.isBig {
            let o = WeatherLook.compute(input(kind: k, wild: true))
            XCTAssertEqual(o.setback, 0, "\(k)"); XCTAssertEqual(o.look, .full)
        }
        for k in WeatherKind.big { XCTAssertEqual(WeatherLook.compute(input(kind: k, wild: true)).setback, 1, "\(k)") }
        XCTAssertEqual(WeatherLook.compute(input(effect: .light, wild: true)).setback, 0)
        let proud = WeatherLook.compute(input(effect: .shrugs, wild: true))
        XCTAssertEqual(proud.look, .shrugs); XCTAssertEqual(proud.setback, 0); XCTAssertEqual(proud.line, WeatherCopy.shrugLine(name: "Daisy", .bigWind))
        XCTAssertEqual(WeatherLook.compute(input(effect: .shrugs, sheltered: true)).look, .shrugs, "shrug-off plants cheer under shelter too")
        XCTAssertEqual(WeatherLook.compute(input(wild: false)).setback, 0, "Variant 1 never dips a stage")
    }

    func testTheShownStageIsNeverBelowOneAndStageOneHasNoSetback() {
        for stage in 0...4 {
            for wild in [false, true] {
                let o = WeatherLook.compute(input(wild: wild, stage: stage))
                XCTAssertGreaterThanOrEqual(o.shownStage, min(stage, 1))
                XCTAssertEqual(o.shownStage, stage - o.setback)
                if stage <= 1 { XCTAssertEqual(o.setback, 0, "stage \(stage)") }
            }
        }
        XCTAssertEqual(WeatherLook.compute(input(wild: true, stage: 2)).shownStage, 1)
    }

    func testASeedShowsNoWeatherAndLoveRainWins() {
        XCTAssertTrue(WeatherLook.compute(input(wild: true, seed: true)).isEmpty)
        let rain = WeatherLook.compute(input(wild: true, rain: true))
        XCTAssertTrue(rain.isEmpty); XCTAssertEqual(rain.shownStage, 3)
        XCTAssertTrue(WeatherLook.compute(input(kind: nil)).isEmpty)
    }

    func testWildWeatherIsThirteenPlusCalmOffOptInOnly() {
        XCTAssertFalse(WeatherLook.wildAvailable(ageBand: .under13, calmMode: false, quietGarden: false), "never under 13")
        XCTAssertFalse(WeatherLook.wildAvailable(ageBand: nil, calmMode: false, quietGarden: false), "never for unknown age")
        XCTAssertFalse(WeatherLook.wildAvailable(ageBand: .thirteenPlus, calmMode: true, quietGarden: false))
        XCTAssertFalse(WeatherLook.wildAvailable(ageBand: .eighteenPlus, calmMode: false, quietGarden: true))
        XCTAssertTrue(WeatherLook.wildAvailable(ageBand: .thirteenPlus, calmMode: false, quietGarden: false))
        XCTAssertFalse(WeatherLook.wildActive(optedIn: false, ageBand: .eighteenPlus, calmMode: false, quietGarden: false), "off until opted in")
        XCTAssertTrue(WeatherLook.wildActive(optedIn: true, ageBand: .eighteenPlus, calmMode: false, quietGarden: false))
        XCTAssertFalse(WeatherLook.wildActive(optedIn: true, ageBand: .under13, calmMode: false, quietGarden: false), "a stored opt-in never applies under 13")
        XCTAssertFalse(PlayerProfile().wildWeather)
    }

    func testTheLifePanelCarriesTheWeatherButItsMetersNeverChange() {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
        let now = at(event, hour: 15)
        var base = LifeStats.Inputs(lastSunnyAt: nil, lastLovedAt: at(event, hour: 7), lastFedAt: nil, lastPrunedAt: nil, soilRichness: 0.4,
                                    stage: 3, waterToday: 1, waterDay: cal.startOfDay(for: now), now: now, calendar: cal, exempt: false)
        let plain = LifeStats.snapshot(base)
        XCTAssertNil(plain.weather)
        base.weather = input(wild: true)
        let stormy = LifeStats.snapshot(base)
        XCTAssertEqual(stormy.weather?.setback, 1); XCTAssertEqual(stormy.weather?.shownStage, 2)
        XCTAssertEqual(stormy.water, plain.water); XCTAssertEqual(stormy.sunshine, plain.sunshine); XCTAssertEqual(stormy.happiness, plain.happiness)
        XCTAssertEqual(stormy.hearts, plain.hearts); XCTAssertEqual(stormy.stage, plain.stage, "the stored stage is what the panel keeps")

        // A day and more without love: love rain shows, weather waits.
        var rainy = base; rainy.lastLovedAt = at(event - 2, hour: 7)
        XCTAssertGreaterThan(LifeStats.snapshot(rainy).rainDay, 0)
        XCTAssertNil(LifeStats.snapshot(rainy).weather)
        // A resting seed (0 petals) shows no weather.
        var seed = base; seed.lastLovedAt = at(event - 6, hour: 7)
        XCTAssertTrue(LifeStats.snapshot(seed).isSeed); XCTAssertNil(LifeStats.snapshot(seed).weather)
        // Quiet Garden or Calm (exempt): no rain, so weather may show under the Calm rules the input carries.
        var exempt = base; exempt.exempt = true; exempt.lastLovedAt = at(event - 6, hour: 7)
        XCTAssertNotNil(LifeStats.snapshot(exempt).weather)
    }
}

// MARK: 6. Gating

final class WeatherGatingTests: XCTestCase {
    func gated(found: Int = 8, tends: Int = 4, quiet: Bool = false, on: Bool = true, today: Int = 100, high: Int = 100, from: Int = 0) -> Bool {
        WeatherEngine.isGated(found: found, tends: tends, quietGarden: quiet, weatherOn: on, today: today, highWater: high, gatedFromDay: from)
    }

    func testEachConditionCanHoldWeatherBack() {
        XCTAssertTrue(gated())
        XCTAssertFalse(gated(quiet: true), "Quiet Garden")
        XCTAssertFalse(gated(on: false), "setting off")
        XCTAssertFalse(gated(found: 4), "fewer than 5 plants"); XCTAssertTrue(gated(found: 5))
        XCTAssertFalse(gated(tends: 1), "fewer than 2 tends"); XCTAssertTrue(gated(tends: 2))
    }

    func testCalmAndUnderThirteenStartWithWeatherOff() {
        XCTAssertFalse(WeatherEngine.defaultWeatherOn(calmMode: true))
        XCTAssertTrue(WeatherEngine.defaultWeatherOn(calmMode: false))
        let s = AppSettings(defaults: UserDefaults(suiteName: "weather-gating-\(UUID().uuidString)")!)
        s.applyAgeDefaults(.under13)
        XCTAssertFalse(gated(on: WeatherEngine.defaultWeatherOn(calmMode: s.calmMode)), "under 13 starts in Calm, so weather is off")
        s.applyAgeDefaults(.thirteenPlus)
        XCTAssertTrue(gated(on: WeatherEngine.defaultWeatherOn(calmMode: s.calmMode)))
    }

    func testAClockMovedBackShowsNothingButOneDayOfSlackIsFine() {
        XCTAssertTrue(gated(today: 99, high: 100), "an iPad one time zone behind still sees weather")
        XCTAssertFalse(gated(today: 98, high: 100))
        XCTAssertTrue(gated(today: 120, high: 100))
        XCTAssertEqual(WeatherEngine.highWater(current: 100, today: 98), 100)
        XCTAssertEqual(WeatherEngine.highWater(current: 100, today: 104), 104)
    }

    func testOnceTheGateOpensFoundAndTendsStayMet() {
        XCTAssertEqual(WeatherEngine.gatedFromDay(current: 0, gatedNow: false, today: 50), 0)
        XCTAssertEqual(WeatherEngine.gatedFromDay(current: 0, gatedNow: true, today: 50), 50)
        XCTAssertEqual(WeatherEngine.gatedFromDay(current: 50, gatedNow: true, today: 60), 50)
        XCTAssertTrue(gated(found: 1, tends: 0, from: 50), "a reconcile that lowers a count does not flip weather off")
        XCTAssertFalse(gated(found: 1, tends: 0, quiet: true, from: 50), "Quiet Garden still wins")
        XCTAssertEqual(WeatherEngine.minNonzero(0, 7), 7); XCTAssertEqual(WeatherEngine.minNonzero(9, 7), 7); XCTAssertEqual(WeatherEngine.minNonzero(0, 0), 0)
    }

    func testTurningGatingOnLaterBringsNoPileUp() {
        let seed: Int64 = 99, start = 10
        let all = WeatherEngine.events(from: start, through: start + 300, seed: seed, startDay: start)
        XCTAssertGreaterThan(all.count, 8)
        // The gate opens on day 250: at most the latest event within its 3 days shows; nothing earlier comes back.
        for today in 250...262 {
            let shown = WeatherEngine.latestEvent(onOrBefore: today, within: Economy.default.weatherLingerDays, seed: seed, startDay: start)
            if let shown { XCTAssertGreaterThan(shown.day, today - 3); XCTAssertLessThanOrEqual(shown.day, today) }
        }
    }

    func testTheKitArrivesOnceWithTheFirstGatedForecast() {
        XCTAssertTrue(WeatherEngine.kitArrives(forecastToday: true, gated: true, kitAt: nil))
        XCTAssertFalse(WeatherEngine.kitArrives(forecastToday: true, gated: false, kitAt: nil))
        XCTAssertFalse(WeatherEngine.kitArrives(forecastToday: false, gated: true, kitAt: nil))
        XCTAssertFalse(WeatherEngine.kitArrives(forecastToday: true, gated: true, kitAt: .now), "it arrives once and stays")
    }

    func testTheAwardCapStopsClockJumpFarming() {
        XCTAssertTrue(WeatherEngine.mayAward(rescuedCount: 0, gardenDays: 0))
        XCTAssertFalse(WeatherEngine.mayAward(rescuedCount: 1, gardenDays: 6))
        XCTAssertTrue(WeatherEngine.mayAward(rescuedCount: 1, gardenDays: 7))
        XCTAssertFalse(WeatherEngine.mayAward(rescuedCount: 3, gardenDays: 20))
        XCTAssertTrue(WeatherEngine.mayAward(rescuedCount: 3, gardenDays: 21))
    }

    func testSeenCountsOnlyOnOrAfterTheEventDay() {
        let tz = TimeZone(identifier: "UTC")!
        let d = Date(timeIntervalSince1970: 1_767_225_600 + 300 * 86_400 + 3600)
        XCTAssertTrue(WeatherEngine.seenCounts(d, eventDay: 300, timeZone: tz))
        XCTAssertFalse(WeatherEngine.seenCounts(d, eventDay: 301, timeZone: tz))
        XCTAssertFalse(WeatherEngine.seenCounts(nil, eventDay: 300, timeZone: tz))
    }
}

// MARK: 7. Invariants: weather never touches an earned value

@MainActor
final class WeatherInvariantTests: XCTestCase {
    let defs = (try? BadgeCatalog.load()) ?? []
    let tz = TimeZone(identifier: "UTC")!

    func progress(_ plants: [PlantCollectible]) -> [PlantProgress] {
        plants.map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) }
    }

    func testAWeatherDayChangesNoEarnedValueInEitherVariant() throws {
        let container = try SharedContainer.make(inMemory: true)
        let ctx = container.mainContext
        try PlantCatalog.seedIfNeeded(context: ctx)
        let plants = try ctx.fetch(FetchDescriptor<PlantCollectible>(sortBy: [SortDescriptor(\.plantId)]))
        for (i, p) in plants.enumerated() where p.level <= 2 || i % 3 == 0 {
            p.earnedCount = 1; p.stage = p.level == 1 ? 4 : 2 + i % 3; p.growthPoints = 40 + i
        }
        var badges = BadgeState(defs: defs)
        badges.record(.waterings, amount: 12, now: .now); badges.record(.plantsOwned, value: 25, now: .now)
        try ctx.save()

        func earned() -> [String] { plants.map { "\($0.plantId):\($0.stage):\($0.growthPoints):\($0.earnedCount)" } }
        let economy = Economy.default
        func ruleValues() -> [String] {
            let pp = progress(plants)
            let stats = PotCatalog.stats(plants: pp, gardenDays: 30, earnedPotIds: [])
            return ["\(ProgressionPolicy.wordLevel(plants: pp, economy: economy))"]
                + (1...5).map { "\(ProgressionPolicy.gardenLevelComplete($0, plants: pp))" }
                + PotCatalog.all.map { "\($0.id)=\(PotCatalog.state(of: $0, stats: stats, hasPlus: false))" }
                + BadgeCounter.allCases.map { "\($0.rawValue)=\(badges.progress(of: $0))" }
        }
        let before = earned(), rulesBefore = ruleValues()

        let event = 300
        let found = plants.filter { $0.earnedCount > 0 }
        let traits = try Dictionary(uniqueKeysWithValues: PlantCatalog.load().map { ($0.plantId, $0.traitSet) })
        var dips = 0
        for wild in [false, true] {
            for kind in WeatherKind.allCases {
                let list = found.map { (id: $0.plantId, traits: traits[$0.plantId] ?? []) }
                let fx = WeatherEngine.affected(kind, plants: list, day: event, cap: economy.weatherAffectedCap)
                let ranks = WeatherEngine.fullRanks(kind, plants: list, day: event, cap: economy.weatherAffectedCap)
                for today in event...(event + 4) {
                    for p in found {
                        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
                        let now = Date(timeIntervalSince1970: 1_767_225_600 + Double(today) * 86_400 + 15 * 3600)
                        var look = WeatherLook.Input(kind: kind, eventDay: event, today: today, effect: fx[p.plantId] ?? .light, lastCareAt: nil,
                                                     seenAt: Date(timeIntervalSince1970: 1_767_225_600 + Double(event) * 86_400 + 9 * 3600),
                                                     sheltered: false, rescued: false, wild: wild, stage: p.stage, rank: ranks[p.plantId] ?? 99)
                        look.timeZone = tz
                        var inputs = LifeStats.Inputs(plant: p, now: now, calendar: cal, exempt: true)
                        inputs.weather = look
                        let snap = LifeStats.snapshot(inputs)
                        if let w = snap.weather, w.setback > 0 { dips += 1; XCTAssertLessThan(w.shownStage, p.stage) }
                        XCTAssertEqual(snap.stage, p.stage)
                    }
                    XCTAssertEqual(ruleValues(), rulesBefore, "\(kind) wild=\(wild) day \(today)")
                }
            }
        }
        XCTAssertGreaterThan(dips, 0, "Wild Weather did dip some shown stages, so the check means something")
        XCTAssertEqual(earned(), before, "stored stage, growth and earned counts are identical after a day of weather")
        XCTAssertFalse(ctx.hasChanges, "computing weather writes nothing")
    }
}

// MARK: 11. Copy

final class WeatherCopyTests: XCTestCase {
    static let avoid = ["save", "saved", "saving", "rescue", "rescued", "danger", "dangerous", "destroy", "destroyed", "warning", "warn",
                        "alert", "too late", "countdown"]

    static func avoided(_ text: String) -> [String] {
        avoid.filter { text.range(of: "\\b" + NSRegularExpression.escapedPattern(for: $0) + "\\b", options: [.regularExpression, .caseInsensitive]) != nil }
    }

    func testEveryWeatherLineIsSafeAndGentle() {
        for name in ["Daisy", "Venus Flytrap"] {
            let lines = WeatherCopy.all(name: name)
            XCTAssertGreaterThan(lines.count, 7 * 10)
            for line in lines {
                XCTAssertFalse(line.isEmpty)
                XCTAssertEqual(CopySafety.check(line), [], line)
                XCTAssertEqual(Self.avoided(line), [], line)
                XCTAssertLessThanOrEqual(line.count, 90, line)
                XCTAssertFalse(line.contains("!!"), line)
            }
        }
        XCTAssertEqual(Self.avoided("Save your garden!"), ["save"], "the avoid check itself works")
    }

    func testWeatherLinesReadAtAboutGradeThree() {
        let sentences = WeatherCopy.all(name: "Daisy").filter { $0.hasSuffix(".") || $0.hasSuffix("!") }
        XCTAssertGreaterThan(sentences.count, 20)
        let grade = ReadingLevel.grade(sentences.joined(separator: " "))
        XCTAssertLessThanOrEqual(grade, 3.9, "weather copy reads at grade \(grade)")
    }

    func testEveryKindHasItsOwnForecastEventShrugAndSnugLine() {
        for f in [WeatherCopy.forecastTitle, WeatherCopy.eventLine, { WeatherCopy.shrugLine(name: "Daisy", $0) }, { WeatherCopy.snugLine(name: "Daisy", $0) }] {
            XCTAssertEqual(Set(WeatherKind.allCases.map(f)).count, WeatherKind.allCases.count)
        }
        XCTAssertTrue(WeatherCopy.notificationTitle(.bigWind).hasPrefix("Garden forecast"), "a summary never reads as a real weather alert")
    }
}

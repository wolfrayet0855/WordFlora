import XCTest
@testable import WordFlora

/// E-8: the weather puzzle (gentle and storm tiers), weather stickers and the Weathered badge. Spec section 10 item 8.
final class WeatherPuzzleTests: XCTestCase {
    var names: [String] { ((try? PlantCatalog.load()) ?? []).map(\.name) }

    // MARK: Storm tier

    func testStormAnswersAreSevenToFourteenLettersInOneOrTwoWords() {
        let c = WakePuzzle.stormCandidates(from: names)
        XCTAssertGreaterThanOrEqual(c.count, 20, "about 13 one-word and 17 two-word names")
        for w in c {
            let letters = w.filter(\.isLetter).count
            XCTAssertTrue((7...14).contains(letters), w)
            XCTAssertLessThanOrEqual(w.split(separator: " ").count, 2, w)
            XCTAssertFalse(w.contains("'"), w)
        }
        XCTAssertTrue(c.contains("VENUS FLYTRAP"))
        XCTAssertFalse(c.contains("GIANT WATER LILY"), "three words are left out")
        XCTAssertFalse(c.contains(where: { $0.contains("LADY") }), "apostrophes are left out")
    }

    func testTwoWordNamesKeepTheirGap() {
        var found = false
        for day in 0..<400 {
            guard let p = WakePuzzle.weather(tier: .storm, eventDay: day, attempt: 0, names: names), !p.gaps.isEmpty else { continue }
            found = true
            XCTAssertEqual(p.gaps.count, 1)
            XCTAssertTrue(p.answer.allSatisfy(\.isLetter), "letters only: \(p.answer)")
            XCTAssertTrue(p.isCorrect(p.answer, validNames: names), "letters-only guess of a two-word name is right")
            let spaced = WakePuzzle.stormCandidates(from: names).first { $0.replacingOccurrences(of: " ", with: "") == p.answer }
            XCTAssertEqual(spaced.map { Array($0).firstIndex(of: " ")! - 1 }, p.gaps.first)
            break
        }
        XCTAssertTrue(found, "some event day draws a two-word name")
    }

    func testThereIsOneDecoyAndNoGivenLetter() {
        for day in 0..<60 {
            let p = WakePuzzle.weather(tier: .storm, eventDay: day, attempt: day % 3, names: names)!
            XCTAssertTrue(p.slots.allSatisfy { $0 == nil }, "every slot open")
            XCTAssertEqual(p.tiles.count, p.answer.count + 1)
            var rest = p.tiles
            for ch in p.answer { rest.remove(at: rest.firstIndex(of: ch)!) }
            XCTAssertEqual(rest.count, 1)
            XCTAssertFalse(p.answer.contains(rest[0]), "the decoy is not in the answer")
            XCTAssertNotEqual(String(p.tiles.prefix(p.answer.count)), p.answer, "never shown solved")
        }
    }

    func testThePuzzleIsTheSameForTheSameDayAndAttempt() {
        let a = WakePuzzle.weather(tier: .storm, eventDay: 210, attempt: 1, names: names)
        XCTAssertEqual(a, WakePuzzle.weather(tier: .storm, eventDay: 210, attempt: 1, names: names.shuffled()))
        let attempts = Set((0..<3).compactMap { WakePuzzle.weather(tier: .storm, eventDay: 210, attempt: $0, names: names)?.tiles })
        XCTAssertGreaterThan(attempts.count, 1, "a new puzzle is a different puzzle")
    }

    func testThePeekLadderAlwaysFinishesAndTheFirstPeekIsFree() {
        for day in 0..<40 {
            let p = WakePuzzle.weather(tier: .storm, eventDay: day, attempt: 0, names: names)!
            var b = WakePuzzleBoard(puzzle: p, firstPeekFree: true)
            XCTAssertTrue(b.canPeek(at: 0), "first peek at once")
            XCTAssertTrue(b.peek(at: 0))
            XCTAssertFalse(b.canPeek(at: 10), "then one every 30 s")
            var t = 30.0
            while b.peek(at: t) { t += 30 }
            XCTAssertEqual(b.letters.filter { $0 == nil }.count, 1, "a peek never fills the final spot")
            // The player places the last right letter.
            let slot = b.letters.firstIndex { $0 == nil }!
            let want = Array(p.answer)[slot]
            let tile = p.tiles.indices.first { p.tiles[$0] == want && !b.isUsed($0) }!
            b.tapTile(tile)
            XCTAssertTrue(b.isSolved(validNames: names), "day \(day)")
        }
    }

    func testTheWakeBoardStillWaitsThirtySecondsForItsFirstPeek() {
        let p = WakePuzzle.make(plantId: "rose", day: 10, names: names)!
        XCTAssertFalse(WakePuzzleBoard(puzzle: p).canPeek(at: 0))
    }

    func testTheGentleTierIsTodaysWakePuzzleAndTheWakeFlowIsUnchanged() {
        XCTAssertEqual(WakePuzzle.candidates(from: names, tier: .gentle), WakePuzzle.candidates(from: names))
        let g = WakePuzzle.weather(tier: .gentle, eventDay: 200, attempt: 0, names: names)
        XCTAssertEqual(g, WakePuzzle.make(plantId: "weather", day: 200 * 16, names: names))
        XCTAssertEqual(g?.gaps, [])
        // The wake puzzle for a plant is byte-identical to before the storm tier (fixed sample).
        let wake = WakePuzzle.make(plantId: "daisy", day: 300, names: names)!
        XCTAssertEqual(wake.gaps, [])
        XCTAssertTrue((5...10).contains(wake.answer.count))
    }

    // MARK: Policy

    func weather(today: Int, eventDay: Int, calm: Bool = false, gated: Bool = true) -> GardenWeatherNow {
        GardenWeatherNow(today: today, gated: gated, calm: calm, wild: false, forecast: nil, event: .bigWind, eventDay: eventDay)
    }

    func testThePuzzleIsOpenOnTheEventDayAndTheThreeAfter() {
        for d in 0...3 { XCTAssertTrue(WeatherPuzzlePolicy.isOpen(weather: weather(today: 50 + d, eventDay: 50), rescuedDays: [])) }
        XCTAssertFalse(WeatherPuzzlePolicy.isOpen(weather: weather(today: 54, eventDay: 50), rescuedDays: []))
        XCTAssertFalse(WeatherPuzzlePolicy.isOpen(weather: weather(today: 51, eventDay: 50), rescuedDays: [50]), "solved")
        XCTAssertFalse(WeatherPuzzlePolicy.isOpen(weather: weather(today: 51, eventDay: 50, calm: true), rescuedDays: []), "no prompt in Calm")
        XCTAssertFalse(WeatherPuzzlePolicy.isOpen(weather: weather(today: 51, eventDay: 50, gated: false), rescuedDays: []))
    }

    func testTiers() {
        XCTAssertEqual(WeatherPuzzlePolicy.tier(wild: true, pickedHarder: false), .storm)
        XCTAssertEqual(WeatherPuzzlePolicy.tier(wild: false, pickedHarder: true), .storm)
        XCTAssertEqual(WeatherPuzzlePolicy.tier(wild: false, pickedHarder: false), .gentle)
        XCTAssertTrue(WeatherPuzzlePolicy.offersHarder(calm: false, wild: false), "opt-in at any age")
        XCTAssertFalse(WeatherPuzzlePolicy.offersHarder(calm: true, wild: false))
        XCTAssertFalse(WeatherPuzzlePolicy.offersHarder(calm: false, wild: true), "Wild Weather is already the harder one")
    }

    func testTheDailyCapHolds() {
        var pair = (day: 0, count: 0)
        for n in 1...3 {
            XCTAssertTrue(WeatherPuzzlePolicy.mayStartFresh(puzzleDay: pair.day, puzzleCount: pair.count, today: 70))
            pair = WeatherPuzzlePolicy.afterStart(puzzleDay: pair.day, puzzleCount: pair.count, today: 70)
            XCTAssertEqual(pair.count, n)
            XCTAssertEqual(WeatherPuzzlePolicy.attempt(puzzleDay: pair.day, puzzleCount: pair.count, today: 70), n - 1)
        }
        XCTAssertFalse(WeatherPuzzlePolicy.mayStartFresh(puzzleDay: pair.day, puzzleCount: pair.count, today: 70))
        XCTAssertTrue(WeatherPuzzlePolicy.mayStartFresh(puzzleDay: pair.day, puzzleCount: pair.count, today: 71), "a new day")
        XCTAssertEqual(WeatherPuzzlePolicy.afterStart(puzzleDay: 70, puzzleCount: 3, today: 71).count, 1)
    }

    // MARK: Stickers and rewards

    func testTheStickerOrderIsFixedBySolveCount() {
        var album = StickerAlbum()
        album.add(["monarch"], on: .now)
        var earned: [WeatherSticker] = []
        while let next = WeatherSticker.next(in: album) { earned.append(next); album.add([next.id]) }
        XCTAssertEqual(earned, WeatherSticker.allCases)
        XCTAssertEqual(earned.map(\.name), ["Rainbow", "Frog friend", "Ladybird", "Kite", "Snowflake", "Sun hat", "Puddle boots"])
        XCTAssertEqual(earned.map(\.id), (1...7).map { "weather.\($0)" })
        XCTAssertEqual(album.species, 1, "weather stickers are not visitor species")
        XCTAssertEqual(WeatherSticker.owned(in: album).count, 7)
        XCTAssertEqual(WeatherSticker(albumId: "weather.2"), .frogFriend)
        XCTAssertNil(WeatherSticker(albumId: "monarch"))
    }

    func testStickersMergeByUnion() {
        var a = StickerAlbum(); a.add(["weather.1"])
        var b = StickerAlbum(); b.add(["weather.1", "weather.2"])
        XCTAssertEqual(WeatherSticker.owned(in: a.merged(with: b)), [.rainbow, .frogFriend])
    }

    func testTheRewardIsNamedBeforePlayAndCappedAgainstFarming() {
        let album = StickerAlbum()
        let r = WeatherPuzzlePolicy.reward(album: album, rescuedCount: 0, gardenDays: 3, allFound: false)
        XCTAssertEqual(r, .init(sticker: .rainbow, word: true, goldenDay: false, badgeStep: true))
        XCTAssertEqual(WeatherPuzzleCopy.rewardLine(r), "Solve it for the Rainbow sticker and a word toward your next plant.")
        let all = WeatherPuzzlePolicy.reward(album: album, rescuedCount: 0, gardenDays: 3, allFound: true)
        XCTAssertTrue(all.goldenDay); XCTAssertFalse(all.word, "at a full collection, a golden day instead of the word")
        XCTAssertEqual(WeatherPuzzlePolicy.reward(album: album, rescuedCount: 2, gardenDays: 13, allFound: false), .none,
                       "one reward per 7 Garden Days")
        XCTAssertFalse(WeatherPuzzlePolicy.reward(album: album, rescuedCount: 2, gardenDays: 14, allFound: false).isEmpty)
    }

    func testOneWordStepCanBringAPlant() {
        XCTAssertEqual(WeatherPuzzlePolicy.wordStep(current: 0).count, 1)
        XCTAssertFalse(WeatherPuzzlePolicy.wordStep(current: 1).plantArrives)
        let last = WeatherPuzzlePolicy.wordStep(current: 2)
        XCTAssertTrue(last.plantArrives); XCTAssertEqual(last.count, 0)
    }

    func testRescuedDaysGrowByUnion() {
        XCTAssertEqual(WeatherPuzzlePolicy.rescued([10, 30], adding: 20), [10, 20, 30])
        XCTAssertEqual(WeatherPuzzlePolicy.rescued([10], adding: 10), [10], "solving twice is idempotent")
    }

    func testTheWeatheredBadgeHasThreeTiersAndArt() throws {
        let defs = try BadgeCatalog.load()
        let w = try XCTUnwrap(defs.first { $0.id == "weathered" })
        XCTAssertEqual(w.counter, BadgeCounter.weathered.rawValue)
        XCTAssertEqual(w.thresholds, [1, 3, 7])
        XCTAssertFalse(BadgeCounter.weathered.isHighWater)
        var s = BadgeState(defs: defs)
        XCTAssertEqual(s.record(.weathered, now: .now).map(\.tier), [1])
        XCTAssertEqual(s.record(.weathered, now: .now, quiet: true), [], "Quiet Garden never advances badges")
    }

    // MARK: Copy

    func testEveryPuzzleLineIsSafeAndGentle() {
        let lines = WeatherPuzzleCopy.all(name: "Daisy")
        XCTAssertGreaterThan(lines.count, 40)
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertEqual(WeatherCopyTests.avoided(line), [], line)
            XCTAssertLessThanOrEqual(line.count, 90, line)
            for word in ["storm", "chest", "heart", "hearts", "buy", "price", "plus", "lock", "timer", "hurry"] {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in \(line)")
            }
        }
        XCTAssertLessThanOrEqual(ReadingLevel.grade(lines.filter { $0.hasSuffix(".") }.joined(separator: " ")), 3.9)
    }
}

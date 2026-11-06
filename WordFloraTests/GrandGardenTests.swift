import XCTest
@testable import WordFlora

/// G-2 to G-5: ceremonies, the crown, golden blooms, the hills picture and the copy behind them.
final class GrandGardenTests: XCTestCase {
    func testTheGrandGardenComesFirstThenTheGoldCrownEachOnce() {
        XCTAssertNil(EndgamePolicy.nextCeremony(allFound: false, allFullBloom: false, crownSeenAt: nil, goldCrownSeenAt: nil))
        XCTAssertEqual(EndgamePolicy.nextCeremony(allFound: true, allFullBloom: true, crownSeenAt: nil, goldCrownSeenAt: nil), .grandGarden)
        XCTAssertEqual(EndgamePolicy.nextCeremony(allFound: true, allFullBloom: true, crownSeenAt: .now, goldCrownSeenAt: nil), .goldCrown)
        XCTAssertNil(EndgamePolicy.nextCeremony(allFound: true, allFullBloom: true, crownSeenAt: .now, goldCrownSeenAt: .now))
        XCTAssertNil(EndgamePolicy.nextCeremony(allFound: true, allFullBloom: false, crownSeenAt: .now, goldCrownSeenAt: nil))
    }

    func testTheCrownFollowsEarnedValues() {
        XCTAssertEqual(EndgamePolicy.crown(allFound: false, allFullBloom: false), EndgamePolicy.Crown.none)
        XCTAssertEqual(EndgamePolicy.crown(allFound: true, allFullBloom: false), .green)
        XCTAssertEqual(EndgamePolicy.crown(allFound: true, allFullBloom: true), .gold)
    }

    func testHomeFeaturesTheFullBloomPlantNearestToGolden() {
        typealias C = EndgamePolicy.GoldenCandidate
        let plants = [C(id: "daisy", name: "Daisy", days: 4, stage: 4), C(id: "rose", name: "Rose", days: 2, stage: 4),
                      C(id: "lotus", name: "Lotus", days: 6, stage: 3), C(id: "fern", name: "Fern", days: 7, stage: 4)]
        XCTAssertEqual(EndgamePolicy.featuredGolden(plants, allFound: true, day: 300)?.id, "daisy",
                       "Lotus is not in full bloom and Fern is already golden")
        XCTAssertNil(EndgamePolicy.featuredGolden(plants, allFound: false, day: 300))
        XCTAssertNil(EndgamePolicy.featuredGolden([C(id: "fern", name: "Fern", days: 7, stage: 4)], allFound: true, day: 1))
        let ties = [C(id: "a", name: "A", days: 3, stage: 4), C(id: "b", name: "B", days: 3, stage: 4), C(id: "c", name: "C", days: 3, stage: 4)]
        let picks = Set((0..<30).compactMap { EndgamePolicy.featuredGolden(ties, allFound: true, day: $0)?.id })
        XCTAssertGreaterThan(picks.count, 1, "ties change from day to day")
        XCTAssertEqual(EndgamePolicy.featuredGolden(ties, allFound: true, day: 9), EndgamePolicy.featuredGolden(ties.reversed(), allFound: true, day: 9))
    }

    func testAllGolden() {
        XCTAssertTrue(EndgamePolicy.allGolden([7, 9, 7]))
        XCTAssertFalse(EndgamePolicy.allGolden([7, 6]))
        XCTAssertFalse(EndgamePolicy.allGolden([]))
    }

    func testTheHillsHoldEveryPlantBackRowRarestFirst() {
        let plants = (1...50).map { $0 }        // already sorted by level: 1...10 level 1, 41...50 level 5
        let rows = EndgamePolicy.hills(plants)
        XCTAssertEqual(rows.map(\.count), [8, 9, 10, 11, 12])
        XCTAssertEqual(rows.flatMap { $0 }.sorted(), plants)
        XCTAssertEqual(rows[0], Array(43...50), "the rarest sit at the back")
        XCTAssertEqual(rows[4], Array(1...12), "the first finds are at the front")
        XCTAssertEqual(EndgamePolicy.hills(Array(1...53)).flatMap { $0 }.count, 53, "a bigger catalog still fits")
    }

    func testThePictureDrawsEachPlantAtItsEarnedStage() {
        XCTAssertEqual([0, 1, 2, 3, 4].map(EndgamePolicy.hillScale), [0.42, 0.42, 0.58, 0.78, 1.0])
    }

    func testRankWordsMatchTheMockup() {
        XCTAssertEqual(BloomRank.allCases.dropFirst().map(\.name), ["Seedling", "Sprout", "Bud", "Bloom", "Full bloom", "Evergreen"])
        XCTAssertEqual(EndgameCopy.youAre(.bud), "You are a Bud.")
        XCTAssertEqual(EndgameCopy.youAre(.unranked), "Play a Daily Bloom to start.")
    }

    func testNoEndingLineMentionsPlusAdsOrPrices() {
        for line in EndgameCopy.all(name: "Daisy") {
            for word in ["plus", "ad", "ads", "price", "buy", "subscribe", "storm"] {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in \(line)")
            }
            XCTAssertEqual(WeatherCopyTests.avoided(line), [], line)
        }
    }

    // MARK: G-3 per-level bloom wave on the level map

    func stops(fullBloom: Set<Int>, mending: [Int: Int] = [:]) -> [LevelStop] {
        let plants = (1...5).flatMap { l in (0..<10).map { _ in PlantProgress(level: l, earned: true, stage: fullBloom.contains(l) ? 4 : 2) } }
        return LevelMapCopy.stops(plants: plants, currentLevel: 5, mending: mending)
    }

    func testTheWaveBloomsOnLevelsWhosePlantsAreAllInFullBloom() {
        XCTAssertEqual(BloomWave.levels(stops(fullBloom: [1, 3])), [1, 3])
        XCTAssertEqual(BloomWave.levels(stops(fullBloom: [])), [])
        XCTAssertEqual(BloomWave.levels(stops(fullBloom: [2], mending: [2: 1])), [], "a level resting after Wild Weather waits")
        let soon = LevelMapCopy.stops(plants: (0..<10).map { _ in PlantProgress(level: 2, earned: true, stage: 4) }, currentLevel: 1)
        XCTAssertEqual(BloomWave.levels(soon), [], "a level not open yet has no wave")
    }

    func testTheWavePlaysOncePerVisitThenRestsAsAStillGarland() {
        XCTAssertEqual(BloomWave.mode(level: 2, played: [], reduceMotion: false), .wave)
        XCTAssertEqual(BloomWave.mode(level: 2, played: [2], reduceMotion: false), .still, "already played this session")
        XCTAssertEqual(BloomWave.mode(level: 2, played: [], reduceMotion: true), .still, "Reduce Motion: the still frame")
    }

    func testTheBloomsRunAlongTheLevelsOwnStretchOfPath() {
        let medals = [CGPoint(x: 80, y: 100), CGPoint(x: 300, y: 400), CGPoint(x: 80, y: 700), CGPoint(x: 300, y: 1000), CGPoint(x: 80, y: 1300)]
        let first = BloomWave.points(level: 1, medals: medals)
        let middle = BloomWave.points(level: 3, medals: medals)
        let last = BloomWave.points(level: 5, medals: medals)
        XCTAssertEqual(first.count, BloomWave.perHalf, "the first level has only the path after it")
        XCTAssertEqual(last.count, BloomWave.perHalf, "the last level has only the path before it")
        XCTAssertEqual(middle.count, 2 * BloomWave.perHalf)
        // Each level keeps to its own half of each stretch, so neighbours never overlap.
        XCTAssertTrue(first.allSatisfy { $0.y > 100 && $0.y < 250 + BloomWave.offset }, "\(first)")
        XCTAssertTrue(middle.allSatisfy { $0.y > 550 - BloomWave.offset && $0.y < 850 + BloomWave.offset }, "\(middle)")
        XCTAssertTrue(last.allSatisfy { $0.y > 1150 - BloomWave.offset && $0.y < 1300 }, "\(last)")
        XCTAssertEqual(middle, middle.sorted { $0.y < $1.y }, "in order along the path, so the wave travels")
        XCTAssertEqual(BloomWave.points(level: 3, medals: Array(medals.prefix(2))), [], "no medal, no wave")
    }

    func testTheWaveIsGentleAndShort() {
        for calm in [false, true] {
            let n = 2 * BloomWave.perHalf
            XCTAssertEqual(BloomWave.scale(index: 0, of: n, t: 0, calm: calm), 0, accuracy: 0.001)
            XCTAssertEqual(BloomWave.scale(index: n - 1, of: n, t: BloomWave.duration(of: n, calm: calm), calm: calm), 1, accuracy: 0.001)
            XCTAssertLessThan(BloomWave.scale(index: n - 1, of: n, t: 0.2, calm: calm), BloomWave.scale(index: 0, of: n, t: 0.2, calm: calm) + 0.001,
                              "the wave travels from the first bloom to the last")
            for step in 0...120 {
                let t = Double(step) * 0.03
                for i in 0..<n {
                    let s = BloomWave.scale(index: i, of: n, t: t, calm: calm)
                    XCTAssertTrue(s >= 0 && s <= (calm ? 1.0001 : 1.12), "a soft pop, no flash: \(s)")
                }
            }
            XCTAssertLessThanOrEqual(BloomWave.duration(of: n, calm: calm), calm ? 3.5 : 2.5)
        }
        XCTAssertGreaterThan(BloomWave.duration(of: 8, calm: true), BloomWave.duration(of: 8, calm: false), "Calm is slower")
        XCTAssertEqual(BloomWave.scale(index: 3, of: 8, t: .infinity, calm: false), 1, "the still frame shows every bloom")
    }
}

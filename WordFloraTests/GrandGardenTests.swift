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
}

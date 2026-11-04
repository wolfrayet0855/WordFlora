import XCTest
@testable import WordFlora

final class LifeStatsTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
    func hours(_ h: Double) -> Date { t0.addingTimeInterval(h * 3600) }

    private func inputs(tended: Double? = 1, sunny: Double? = 1, loved: Double? = 1, soil: Double = 0.5, stage: Int = 3,
                        absorbed: Int = 10, absorbDay: Date? = nil, exempt: Bool = false, now: Date? = nil) -> LifeStats.Inputs {
        let n = now ?? hours(30)
        func ago(_ h: Double?) -> Date? { h.map { n.addingTimeInterval(-$0 * 3600) } }
        return LifeStats.Inputs(lastTendedAt: ago(tended), lastSunnyAt: ago(sunny), lastLovedAt: ago(loved), soilRichness: soil,
                                stage: stage, absorbedToday: absorbed, absorbDay: absorbDay ?? n, now: n, calendar: cal, exempt: exempt)
    }

    // MARK: Meters

    func testFreshlyCaredForPlantShowsFullBrightHappy() {
        let s = LifeStats.snapshot(inputs())
        XCTAssertEqual(s.water.word, "Full"); XCTAssertEqual(s.sunshine.word, "Bright"); XCTAssertEqual(s.happiness.word, "Happy")
        XCTAssertEqual(s.water.accessibilityLabel, "Water, full")
    }

    func testWaterSoftensWithTimeButNeverEmpties() {
        let fills = [1.0, 30, 60, 200, 2000].map { LifeStats.snapshot(inputs(tended: $0)).water.fill }
        XCTAssertEqual(fills, fills.sorted(by: >), "water only ever eases down as time passes")
        XCTAssertGreaterThanOrEqual(fills.min()!, 0.3, "a meter never shows as empty")
        XCTAssertEqual(LifeStats.snapshot(inputs(tended: 30)).water.word, "Good")
        XCTAssertEqual(LifeStats.snapshot(inputs(tended: 60)).water.word, "Sipping")
        XCTAssertEqual(LifeStats.snapshot(inputs(tended: nil)).water.word, "Sipping")
    }

    func testSunshineEasesAndRainMakesItCloudy() {
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: 30)).sunshine.word, "Warming up")
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: 100)).sunshine.word, "Sun is coming")
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: 1, loved: 30)).sunshine.word, "Cloudy")   // a rainy day
        let fills = [1.0, 30, 100].map { LifeStats.snapshot(inputs(sunny: $0)).sunshine.fill }
        XCTAssertEqual(fills, fills.sorted(by: >))
    }

    func testHappinessFollowsLoveAndSoil() {
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 60, soil: 0)).happiness.word, "Cosy")
        let a = LifeStats.snapshot(inputs(loved: 1, soil: 0)).happiness.fill, b = LifeStats.snapshot(inputs(loved: 1, soil: 1)).happiness.fill
        XCTAssertGreaterThan(b, a)
    }

    func testASeedRestsInEveryMeter() {
        let s = LifeStats.snapshot(inputs(loved: 24 * 6))
        XCTAssertTrue(s.isSeed)
        for m in [s.water, s.sunshine, s.happiness] { XCTAssertEqual(m.word, "Resting"); XCTAssertGreaterThan(m.fill, 0) }
        XCTAssertEqual(s.pips, 0); XCTAssertEqual(s.loveLine, "Ready for you")
    }

    func testCalmAndQuietGardenKeepEveryPipAndNoRain() {
        let s = LifeStats.snapshot(inputs(loved: 24 * 9, exempt: true))
        XCTAssertEqual(s.pips, 5); XCTAssertEqual(s.rainDay, 0); XCTAssertFalse(s.isSeed)
        XCTAssertNotEqual(s.sunshine.word, "Cloudy")
    }

    // MARK: Stage path and hearts

    func testStagePathNamesAreSimple() {
        XCTAssertEqual(LifeStats.stageNames, ["Tiny", "Sprout", "Bud", "Bloom", "Full bloom"])
        XCTAssertEqual(LifeStats.snapshot(inputs(stage: 3)).stageLabel, "Growing, bloom stage")
        XCTAssertEqual(LifeStats.snapshot(inputs(stage: 9)).stage, 4)
    }

    func testHeartsShowTodaysLove() {
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 1, absorbed: 10)).hearts, 5)
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 1, absorbed: 0)).hearts, 1)       // a hello today is one heart
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 30, absorbed: 0)).hearts, 0)
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 1, absorbed: 10, absorbDay: hours(-200))).hearts, 1)   // yesterday's growth does not count
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 1, absorbed: 10)).loveLine, "Loved")
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 30, absorbed: 0)).loveLine, "Ready for a hello")
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 1, absorbed: 0)).heartsLabel, "Love, 1 of 5 hearts. Hellos help")
    }

    // MARK: Pips and labels

    func testPipLabelsAndKeyLine() {
        XCTAssertEqual(LifeStats.plantLabel(name: "Clover", pips: 3), "Clover, 3 of 5 love petals")
        XCTAssertEqual(LifeStats.seedLabel(name: "Clover"), "Clover, resting as a seed in its pot")
        XCTAssertEqual(LifeStats.keyLine, "Love keeps its petals.")
        XCTAssertEqual(LifeStats.keyLabel(pips: 2), "2 of 5 love petals. Love keeps its petals.")
    }

    // MARK: Weather

    func testRainGrowsSteadierEachDayAndThunderFromDayFour() {
        XCTAssertEqual(LifeStats.weather(day: 0), LifeStats.Weather(drops: 0, thunder: false))
        XCTAssertEqual(LifeStats.weather(day: 1).drops, 12)
        XCTAssertFalse(LifeStats.weather(day: 3).thunder)
        XCTAssertTrue(LifeStats.weather(day: 4).thunder)
        XCTAssertEqual(LifeStats.weather(day: 30).drops, 60)
        let d = (1...7).map { LifeStats.weather(day: $0).drops }
        XCTAssertEqual(d, d.sorted())
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 24 * 4 + 2)).rainDay, 4)
        XCTAssertEqual(LifeStats.snapshot(inputs(loved: 24 * 6)).rainDay, 0, "the rain stops while the seed sleeps")
    }

    func testThunderIsGentleAndRare() {
        XCTAssertFalse(ThunderGate.canFlash(lastFlash: t0, now: t0.addingTimeInterval(7.9)))
        XCTAssertTrue(ThunderGate.canFlash(lastFlash: t0, now: t0.addingTimeInterval(8)))
        XCTAssertTrue(ThunderGate.canFlash(lastFlash: nil, now: t0))
        XCTAssertLessThanOrEqual(ThunderGate.peakOpacity(dark: false), 0.16)
        XCTAssertLessThanOrEqual(ThunderGate.peakOpacity(dark: true), 0.10)
        for r in [0.0, 0.5, 1.0] { XCTAssertTrue((8.0...15.0).contains(ThunderGate.nextDelay(unit: r))) }
        XCTAssertTrue((0.3...0.5).contains(ThunderGate.hapticDelay(unit: 0.7)))
    }

    // MARK: Petal animation once per change

    func testPetalMotionPlaysOncePerChange() {
        XCTAssertEqual(PetalMotion.next(shown: 5, now: 4), .fall(from: 5, to: 4))
        XCTAssertEqual(PetalMotion.next(shown: 2, now: 5), .regrow(from: 2, to: 5))
        XCTAssertEqual(PetalMotion.next(shown: 3, now: 3), .still)
        XCTAssertEqual(PetalMotion.next(shown: 9, now: 3), .fall(from: 5, to: 3))
    }

    // MARK: Copy

    func testEveryNewLineIsGentle() {
        let extra = ["empty", "left", "waiting", "miss", "lost", "dead", "only", "last", "beat", "forget"]
        for line in LifeStats.allCopy(name: "Clover") {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for w in extra { XCTAssertNil(line.range(of: "\\b\(w)\\b", options: [.regularExpression, .caseInsensitive]), "\(w) in \(line)") }
        }
    }
}

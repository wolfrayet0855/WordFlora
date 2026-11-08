import XCTest
@testable import WordFlora

final class LifeStatsTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_780_000_000)
    let cal: Calendar = { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }()
    func hours(_ h: Double) -> Date { t0.addingTimeInterval(h * 3600) }

    /// `waters` drinks today, sun and soil `sunny` / `fed` hours ago (nil = never).
    private func inputs(waters: Int = 2, sunny: Double? = 1, fed: Double? = nil, pruned: Double? = nil, loved: Double? = 1, soil: Double = 0.5,
                        stage: Int = 3, waterDay: Date? = nil, exempt: Bool = false, now: Date? = nil) -> LifeStats.Inputs {
        let n = now ?? hours(30)
        func ago(_ h: Double?) -> Date? { h.map { n.addingTimeInterval(-$0 * 3600) } }
        return LifeStats.Inputs(lastSunnyAt: ago(sunny), lastLovedAt: ago(loved), lastFedAt: ago(fed), lastPrunedAt: ago(pruned),
                                soilRichness: soil, stage: stage, waterToday: waters, waterDay: waterDay ?? cal.startOfDay(for: n),
                                now: n, calendar: cal, exempt: exempt)
    }

    // MARK: Meters

    /// The caption beside the love petal row (design-preview/fact-card: "3 love petals"), so the row reads as love.
    func testLovePetalCaptionCountsThePetals() {
        XCTAssertEqual(LifeStats.pipCaption(pips: 5), "5 love petals")
        XCTAssertEqual(LifeStats.pipCaption(pips: 3), "3 love petals")
        XCTAssertEqual(LifeStats.pipCaption(pips: 1), "1 love petal")
        for n in 0...5 { XCTAssertEqual(CopySafety.check(LifeStats.pipCaption(pips: n)), []) }
    }

    func testFreshlyCaredForPlantShowsFullBrightHappy() {
        let s = LifeStats.snapshot(inputs())
        XCTAssertEqual(s.water.word, "Full"); XCTAssertEqual(s.sunshine.word, "Bright"); XCTAssertEqual(s.happiness.word, "Happy")
        XCTAssertEqual(s.water.accessibilityLabel, "Water, full")
        XCTAssertTrue(s.water.done); XCTAssertTrue(s.sunshine.done)
    }

    func testWaterShowsTodaysDrinksAndNeverEmpties() {
        let fills = [0, 1, 2, 5].map { LifeStats.snapshot(inputs(waters: $0)).water.fill }
        XCTAssertEqual(fills, fills.sorted(), "each drink today fills it a little more")
        XCTAssertGreaterThanOrEqual(fills.min()!, 0.3, "a meter never shows as empty")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 0)).water.word, "Ready for a drink")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 1)).water.word, "Good")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2)).water.word, "Full")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, waterDay: hours(-200))).water.word, "Ready for a drink")   // yesterday's drinks
    }

    func testSunshineIsBrightOnlyWhenSunnedTodayAndRainNeverChangesIt() {
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: 1)).sunshine.word, "Bright")
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: 30)).sunshine.word, "Ready for sun")
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: nil)).sunshine.word, "Ready for sun")
        XCTAssertEqual(LifeStats.snapshot(inputs(sunny: 1, loved: 30)).sunshine.word, "Bright")    // a rainy day
        XCTAssertGreaterThan(LifeStats.snapshot(inputs(sunny: 1)).sunshine.fill, LifeStats.snapshot(inputs(sunny: 30)).sunshine.fill)
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

    /// Hearts: a hello, a drink, sun, soil and one finishing touch (the second drink or a prune), so every player can fill
    /// all five on one day without any Shed tool.
    func testHeartsShowTodaysLove() {
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, fed: 1, loved: 1)).hearts, 5, "no shears needed")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 1, sunny: 1, fed: 1, loved: 1)).hearts, 4, "the second drink is the finishing touch")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 1, sunny: 1, fed: 1, pruned: 1, loved: 1)).hearts, 5, "a prune also finishes the day")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, fed: 1, pruned: 1, loved: 1)).hearts, 5, "never more than five")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 0, sunny: nil, pruned: 1, loved: 1)).hearts, 2)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 0, sunny: nil, loved: 1)).hearts, 1)       // a hello today is one heart
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 0, sunny: nil, loved: 30)).hearts, 0)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, loved: 1)).hearts, 4)
        // Yesterday's care does not count.
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: nil, loved: 1, waterDay: hours(-200))).hearts, 1)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 30, fed: 30, pruned: 30, loved: 1, waterDay: hours(-200))).hearts, 1)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, fed: 1, loved: 1)).loveLine, "Full of energy")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 0, sunny: nil, loved: 30)).loveLine, "Ready for a hello")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 0, sunny: nil, loved: 1)).heartsLabel, "Energy, 1 of 5 hearts. Some energy")
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 1, sunny: 1, fed: 1, loved: 1)).heartsLabel, "Energy, 4 of 5 hearts. Lots of energy")
        XCTAssertEqual(LifeStats.energyTitle, "Energy")
        XCTAssertEqual(LifeStats.keyLine, "Love keeps its petals.", "the petals stay love")
    }

    func testASeedShowsNoHeartsAndCalmCountsHeartsTheSameWay() {
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, fed: 1, pruned: 1, loved: 24 * 6)).hearts, 0)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, fed: 1, loved: 1, exempt: true)).hearts, 5)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 1, sunny: 1, fed: 1, loved: 1, exempt: true)).hearts, 4)
        XCTAssertEqual(LifeStats.snapshot(inputs(waters: 2, sunny: 1, fed: 1, loved: 24 * 9, exempt: true)).hearts, 0, "a hello today starts the hearts")
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

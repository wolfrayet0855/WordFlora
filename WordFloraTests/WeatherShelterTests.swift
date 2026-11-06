import XCTest
@testable import WordFlora

/// E-7: weather helpers. Free, never used up, set out with one tap, hidden in Calm and Quiet Garden.
final class WeatherShelterTests: XCTestCase {
    let seed: Int64 = 424_242
    let start = 100

    /// The first event day for the test seed, and its kind.
    func firstEvent() -> (day: Int, kind: WeatherKind) {
        let e = WeatherEngine.events(from: start, through: start + 200, seed: seed, startDay: start).first!
        return (e.day, e.kind)
    }

    func now(today: Int, calm: Bool = false, quiet: Bool = false, weatherOn: Bool = true, found: Int = 6, tends: Int = 3) -> GardenWeatherNow {
        GardenWeatherNow.compute(seed: seed, startDay: start, today: today, highWater: today, gatedFromDay: 0, found: found, tends: tends,
                                 quietGarden: quiet, weatherOn: weatherOn, calm: calm, wild: false)
    }

    func testEveryKindHasExactlyOneHelper() {
        for k in WeatherKind.allCases {
            XCTAssertEqual(WeatherHelper.allCases.filter { $0.kinds.contains(k) }.count, 1, "\(k)")
            XCTAssertTrue(WeatherHelper.helper(for: k).kinds.contains(k))
        }
        XCTAssertEqual(WeatherHelper.helper(for: .hotDay), .shadeCloth)
        XCTAssertEqual(WeatherHelper.helper(for: .drySpell), .shadeCloth)
    }

    func testTheNowStateReadsTheForecastAndTheLatestEvent() {
        let e = firstEvent()
        let before = now(today: e.day - 1)
        XCTAssertEqual(before.forecast, e.kind)
        XCTAssertNil(before.event)
        let on = now(today: e.day)
        XCTAssertEqual(on.event, e.kind); XCTAssertEqual(on.eventDay, e.day)
        let after = now(today: e.day + 3)
        XCTAssertEqual(after.event, e.kind, "the puzzle window is the event day and the 3 after")
        XCTAssertNil(now(today: e.day + 4).event)
    }

    func testNothingShowsWhenWeatherIsHeldBack() {
        let e = firstEvent()
        for w in [now(today: e.day - 1, quiet: true), now(today: e.day - 1, weatherOn: false), now(today: e.day - 1, found: 4),
                  now(today: e.day - 1, tends: 1)] {
            XCTAssertFalse(w.gated); XCTAssertNil(w.forecast); XCTAssertNil(w.event)
            XCTAssertNil(ShelterPolicy.coverable(w))
        }
        let unseeded = GardenWeatherNow.compute(seed: 0, startDay: 0, today: e.day, highWater: 0, gatedFromDay: 0, found: 9, tends: 9,
                                                quietGarden: false, weatherOn: true, calm: false, wild: false)
        XCTAssertFalse(unseeded.gated)
        XCTAssertNil(unseeded.event)
    }

    func testCalmShowsLooksButNoHelpers() {
        let e = firstEvent()
        let calm = now(today: e.day - 1, calm: true)
        XCTAssertTrue(calm.gated)
        XCTAssertFalse(calm.showsMechanics)
        XCTAssertNil(ShelterPolicy.coverable(calm))
        XCTAssertFalse(ShelterPolicy.showsHelpers(kitAt: .now, weather: calm))
        XCTAssertFalse(ShelterPolicy.kitDue(kitAt: nil, weather: calm), "no kit, so no to-do list, for a young child")
        for h in WeatherHelper.allCases { XCTAssertEqual(ShelterPolicy.state(h, weather: calm, shelterDay: 0), .ready) }
    }

    func testTheKitArrivesOnceWithTheFirstForecast() {
        let e = firstEvent()
        XCTAssertFalse(ShelterPolicy.kitDue(kitAt: nil, weather: now(today: e.day - 2)), "no forecast yet")
        XCTAssertTrue(ShelterPolicy.kitDue(kitAt: nil, weather: now(today: e.day - 1)))
        XCTAssertFalse(ShelterPolicy.kitDue(kitAt: .now, weather: now(today: e.day - 1)), "only once")
        XCTAssertFalse(ShelterPolicy.showsHelpers(kitAt: nil, weather: now(today: e.day - 1)))
        XCTAssertTrue(ShelterPolicy.showsHelpers(kitAt: .now, weather: now(today: e.day + 9)), "kept for good once it came")
    }

    func testOnlyTheFittingHelperCanBeSetOutTheDayBeforeOrOnTheDay() {
        let e = firstEvent()
        let fitting = WeatherHelper.helper(for: e.kind)
        for today in [e.day - 1, e.day] {
            let w = now(today: today)
            XCTAssertEqual(ShelterPolicy.state(fitting, weather: w, shelterDay: 0), .canSetOut)
            for h in WeatherHelper.allCases where h != fitting { XCTAssertEqual(ShelterPolicy.state(h, weather: w, shelterDay: 0), .ready) }
            let day = ShelterPolicy.setOut(weather: w, shelterDay: 0)
            XCTAssertEqual(day, e.day, "covers the event day")
            XCTAssertEqual(ShelterPolicy.state(fitting, weather: w, shelterDay: day), .setOut)
            XCTAssertTrue(ShelterPolicy.isSheltered(shelterDay: day, eventDay: e.day))
        }
        let later = now(today: e.day + 1)
        XCTAssertNil(ShelterPolicy.coverable(later), "after the day there is nothing to set out")
        XCTAssertEqual(ShelterPolicy.setOut(weather: later, shelterDay: 7), 7, "a tap then changes nothing")
    }

    func testSettingOutNeverLowersTheStoredDay() {
        let e = firstEvent()
        XCTAssertEqual(ShelterPolicy.setOut(weather: now(today: e.day - 1), shelterDay: e.day + 50), e.day + 50)
        XCTAssertFalse(ShelterPolicy.isSheltered(shelterDay: 0, eventDay: 0))
    }

    func testEveryShelterLineIsSafeAndGentle() {
        let lines = ShelterCopy.all()
        XCTAssertGreaterThan(lines.count, 30)
        for line in lines {
            XCTAssertEqual(CopySafety.check(line), [], line)
            XCTAssertEqual(WeatherCopyTests.avoided(line), [], line)
            XCTAssertLessThanOrEqual(line.count, 90, line)
            for word in ["buy", "price", "plus", "lock", "storm"] {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in \(line)")
            }
        }
        XCTAssertLessThanOrEqual(ReadingLevel.grade(lines.filter { $0.hasSuffix(".") }.joined(separator: " ")), 3.9)
    }
}

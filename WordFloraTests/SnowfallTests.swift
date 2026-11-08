import XCTest
@testable import WordFlora

final class SnowfallTests: XCTestCase {
    let card = CGSize(width: 353, height: 150)

    func testFlakesStayInsideTheCanvasAndRepeatForTheSameTime() {
        for t in [0.0, 1.3, 7.77, 123.4, 100_000.5] {
            let a = Snowfall.flakes(count: 22, size: card, time: t)
            XCTAssertEqual(a.count, 22)
            for f in a {
                XCTAssertTrue((0...353).contains(f.x), "x \(f.x) at t \(t)")
                XCTAssertTrue((-5...155).contains(f.y), "y \(f.y) at t \(t)")
            }
            XCTAssertEqual(a, Snowfall.flakes(count: 22, size: card, time: t))
        }
    }

    func testFlakesMoveDownOverTime() {
        let a = Snowfall.flakes(count: 22, size: card, time: 10), b = Snowfall.flakes(count: 22, size: card, time: 10.1)
        XCTAssertTrue(zip(a, b).contains { $1.y > $0.y })
    }

    func testLayerSharesAlwaysAddUpToTheCount() {
        // 22 on the card: 10 far dots, 7 mid dots, 5 near snowflakes (the owner's 5 to 8 biggest as glyphs).
        XCTAssertEqual(Snowfall.counts(22), [10, 7, 5])
        XCTAssertEqual(Snowfall.counts(18), [8, 5, 5])
        for n in 0...40 { XCTAssertEqual(Snowfall.counts(n).reduce(0, +), n, "count \(n)") }
        let flakes = Snowfall.flakes(count: 22, size: card, time: 3)
        XCTAssertEqual(flakes.filter { $0.layer == 2 }.count, 5)
    }

    func testOnlyTheNearLayerIsDrawnAsSnowflakesSixToNinePointsAcross() {
        XCTAssertEqual(Snowfall.layers.map(\.glyph), [false, false, true])
        for f in Snowfall.flakes(count: 22, size: card, time: 42) where f.layer == 2 {
            XCTAssertTrue((6.0...9.0).contains(2 * f.radius), "glyph \(2 * f.radius) pt")
        }
        let path = SnowfallView.glyph(x: 10, y: 10, r: 4, spin: 0)
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect.width, 8, accuracy: 0.5)
    }

    func testCalmHalvesTheCountAndNeverGoesBelowOne() {
        XCTAssertEqual(Snowfall.count(base: 22, calm: false), 22)
        XCTAssertEqual(Snowfall.count(base: 22, calm: true), 11)
        XCTAssertEqual(Snowfall.count(base: 18, calm: true), 9)
        XCTAssertEqual(Snowfall.count(base: 1, calm: true), 1)
        XCTAssertEqual(Snowfall.count(base: 0, calm: false), 1)
    }

    func testSnowShowsOnTheStageOnlyInAPackPotUnderAFreeSky() {
        for pot in PotCatalog.packPots {
            XCTAssertTrue(Snowfall.showsOnStage(potId: pot.id, quietGarden: false, weather: false, raining: false), pot.id)
            XCTAssertFalse(Snowfall.showsOnStage(potId: pot.id, quietGarden: true, weather: false, raining: false))
            XCTAssertFalse(Snowfall.showsOnStage(potId: pot.id, quietGarden: false, weather: true, raining: false))
            XCTAssertFalse(Snowfall.showsOnStage(potId: pot.id, quietGarden: false, weather: false, raining: true))
        }
        for pot in PotCatalog.all {
            XCTAssertFalse(Snowfall.showsOnStage(potId: pot.id, quietGarden: false, weather: false, raining: false), pot.id)
        }
    }

    func testFlakesFadeNearTheGroundAndAreNotDrawnBelowIt() {
        XCTAssertEqual(Snowfall.groundAlpha(y: 50, groundY: 200), 1)
        XCTAssertLessThan(Snowfall.groundAlpha(y: 190, groundY: 200)!, 1)
        XCTAssertNil(Snowfall.groundAlpha(y: 201, groundY: 200))
        XCTAssertEqual(Snowfall.groundAlpha(y: 500, groundY: nil), 1)
        let stage = CGSize(width: 390, height: 300)
        for t in stride(from: 0.0, to: 30, by: 0.7) {
            for f in Snowfall.flakes(count: 18, size: stage, time: t, groundY: 260) {
                XCTAssertLessThan(f.y, 260)
                if f.y > 260 - Snowfall.groundFade { XCTAssertLessThan(f.alpha, Snowfall.layers[f.layer].alpha) }
            }
        }
    }

    func testThePlantPageDrawsOnlyTheLayersItAsksFor() {
        let back = Snowfall.flakes(count: 18, size: card, time: 5, layers: [0])
        XCTAssertTrue(back.allSatisfy { $0.layer == 0 })
        XCTAssertEqual(back.count + Snowfall.flakes(count: 18, size: card, time: 5, layers: [1, 2]).count, 18)
    }

    func testCalmFallsSlower() {
        let base = Snowfall.layers[0].speed
        XCTAssertEqual(base * Snowfall.calmSpeed, 14 * 0.7, accuracy: 0.001)
    }

    func testFlakeColoursFollowTheMode() {
        XCTAssertEqual(UIColor(SnowfallView.flakeColor(dark: false)).hexString, "8FA9C4")
        XCTAssertEqual(UIColor(SnowfallView.flakeColor(dark: true)).hexString, "F4F8FC")
    }
}

private extension UIColor {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }
}

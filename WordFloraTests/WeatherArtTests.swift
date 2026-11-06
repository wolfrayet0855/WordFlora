import XCTest
import SwiftUI
@testable import WordFlora

/// E-6 and E-11: the weather art's rules (what each kind draws, how far a plant may lean) and the Grand Garden layout.
@MainActor
final class WeatherArtTests: XCTestCase {

    func testEveryKindDrawsItsSignatureForTheFullLook() {
        let want: [WeatherKind: WeatherArt.Element] = [
            .drySpell: .dryCracks, .busyBugs: .termites, .bigWind: .windStreaks, .frostyNight: .snowflakes,
            .hotDay: .heatShimmer, .hailShower: .hailPellets, .bigPuddles: .puddle,
        ]
        for k in WeatherKind.allCases {
            let s = WeatherArt.spec(k, look: .full)
            XCTAssertTrue(s.elements.contains(want[k]!), "\(k)")
            XCTAssertGreaterThan(s.particles, 0, "\(k)")
            XCTAssertNil(s.helper)
        }
    }

    func testTheLightLookIsSofterThanTheFullLook() {
        for k in WeatherKind.allCases {
            let full = WeatherArt.spec(k, look: .full), light = WeatherArt.spec(k, look: .light)
            XCTAssertLessThan(light.particles, full.particles, "\(k)")
            XCTAssertLessThanOrEqual(abs(light.pose.lean), abs(full.pose.lean), "\(k)")
            XCTAssertGreaterThanOrEqual(light.pose.saturation, full.pose.saturation, "\(k)")
        }
    }

    func testAShrugOffPlantStandsTallAndCheers() {
        for k in WeatherKind.allCases {
            let s = WeatherArt.spec(k, look: .shrugs)
            XCTAssertEqual(s.pose, WeatherArt.Pose(), "\(k)")
            XCTAssertTrue(s.elements.contains(.cheer), "\(k)")
            XCTAssertFalse(s.elements.contains(.termites), "\(k)")
        }
    }

    func testASnugGardenStillShowsTheWeatherWithItsHelperAndUprightPlants() {
        for k in WeatherKind.allCases {
            let s = WeatherArt.spec(k, look: .snug)
            XCTAssertEqual(s.helper, WeatherArt.helper(k), "\(k)")
            XCTAssertTrue(s.elements.contains(.shelter), "\(k)")
            XCTAssertEqual(s.pose.lean, 0, "\(k)")
            XCTAssertEqual(s.pose.saturation, 1, "\(k)")
            XCTAssertGreaterThan(s.particles, 0, "\(k): the weather still shows outside the helper")
        }
        XCTAssertEqual(WeatherArt.helper(.bigWind), .windNet)
        XCTAssertEqual(WeatherArt.helper(.hotDay), .shadeCloth)
        XCTAssertEqual(WeatherArt.helper(.drySpell), .shadeCloth)
        XCTAssertEqual(WeatherArt.helper(.hailShower), .umbrella)
        XCTAssertEqual(WeatherArt.helper(.bigPuddles), .raisedBed)
        XCTAssertEqual(WeatherArt.helper(.frostyNight), .frostCloth)
        XCTAssertEqual(WeatherArt.helper(.busyBugs), .bugCover)
    }

    func testPosesStayGentle() {
        for k in WeatherKind.allCases {
            for look in [WeatherEffect.light, .full, .snug, .shrugs] {
                let p = WeatherArt.spec(k, look: look).pose
                XCTAssertLessThanOrEqual(abs(p.lean) + p.sway, 17, "\(k) \(look)")
                XCTAssertGreaterThanOrEqual(p.squash, 0.85, "\(k) \(look)")
                XCTAssertGreaterThanOrEqual(p.saturation, 0.5, "\(k) \(look)")
            }
        }
        XCTAssertEqual(WeatherArt.spec(.bigWind, look: .full).pose.lean, 15)    // the mockup's bend
    }

    func testSwayMovesAroundTheLeanAndHoldsStillUnderReduceMotion() {
        let s = WeatherArt.spec(.bigWind, look: .full)
        let leans = stride(from: 0.0, to: 5, by: 0.25).map { WeatherArt.pose(s, time: $0, still: false).lean }
        XCTAssertLessThan(leans.min()!, s.pose.lean)
        XCTAssertGreaterThan(leans.max()!, s.pose.lean)
        XCTAssertLessThanOrEqual(leans.max()! - leans.min()!, 2 * s.pose.sway + 0.001)
        for t in [0.0, 1.3, 3.7] { XCTAssertEqual(WeatherArt.pose(s, time: t, still: true), s.pose) }
    }

    func testBackAndFrontLayersSplitTheElements() {
        XCTAssertEqual(WeatherArt.layer(.sun), .back)
        XCTAssertEqual(WeatherArt.layer(.clouds), .back)
        XCTAssertEqual(WeatherArt.layer(.windStreaks), .front)
        XCTAssertEqual(WeatherArt.layer(.termites), .front)
        XCTAssertEqual(WeatherArt.layer(.puddle), .front)
        XCTAssertEqual(WeatherArt.layer(.shelter), .front)
    }

    func testEveryKindHasATintAndASymbol() {
        let tints = Set(WeatherKind.allCases.map { WeatherArt.tint($0) })
        XCTAssertEqual(tints.count, WeatherKind.allCases.count)
        for k in WeatherKind.allCases { XCTAssertNotNil(UIImage(systemName: WeatherArt.symbol(k)), "\(k)") }
    }

    func testLabelsArePlainAndKind() {
        var all: [String] = []
        for k in WeatherKind.allCases {
            for look in [WeatherEffect.light, .full, .snug, .shrugs] { all.append(WeatherArt.accessibilityLabel(k, look: look, name: "Daisy")) }
        }
        all += [GrandGardenArt.label(gold: false), GrandGardenArt.label(gold: true), GardenersCrown.label(gold: false),
                GardenersCrown.label(gold: true), ReliefArtCopy.label]
        let avoid = ["save", "rescue", "danger", "destroy", "warning", "alert", "too late", "storm", "dead", "die", "kill", "only"]
        for line in all {
            XCTAssertFalse(line.isEmpty)
            XCTAssertEqual(CopySafety.check(line), [], line)
            for w in avoid { XCTAssertNil(line.lowercased().range(of: "\\b\(w)\\b", options: .regularExpression), "\(w) in \(line)") }
        }
        XCTAssertEqual(WeatherArt.accessibilityLabel(.bigWind, look: .full, name: "Sunflower"), "A big wind is bending Sunflower.")
        XCTAssertEqual(WeatherArt.accessibilityLabel(.drySpell, look: .shrugs, name: "Lithops"), "Lithops loves dry days!")
    }

    // MARK: Grand Garden

    func testTheGardenHasFiveRowsOfFiftyWithTheRarestAtTheBack() {
        XCTAssertEqual(GrandGardenArt.rowCounts, [12, 11, 10, 9, 8])
        let spots = GrandGardenArt.spots(count: 50, width: 393)
        XCTAssertEqual(spots.count, 50)
        XCTAssertEqual(Set(spots.map(\.index)), Set(0..<50))
        let back = spots.filter { $0.row == 0 }, front = spots.filter { $0.row == 4 }
        XCTAssertEqual(back.count, 12)
        XCTAssertEqual(front.count, 8)
        XCTAssertTrue(back.map(\.index).contains(49))                       // the last found sits at the back
        XCTAssertTrue(front.map(\.index).contains(0))                       // the first found sits at the front
        XCTAssertGreaterThan(front[0].size, back[0].size)
        XCTAssertLessThan(front[0].baseline, back[0].baseline)               // baselines count up from the bottom
        for s in spots { XCTAssertTrue((-8...401).contains(s.x), "\(s)") }
    }

    func testFewerPlantsStillLayOutAndScaleWithWidth() {
        XCTAssertEqual(GrandGardenArt.spots(count: 7, width: 393).count, 7)
        XCTAssertTrue(GrandGardenArt.spots(count: 0, width: 393).isEmpty)
        let narrow = GrandGardenArt.spots(count: 50, width: 320), wide = GrandGardenArt.spots(count: 50, width: 393)
        XCTAssertLessThan(narrow[0].size, wide[0].size)
    }

    func testPlantsShowTheirEarnedStageSize() {
        XCTAssertEqual(GrandGardenArt.stageScale(4), 1)
        XCTAssertEqual(GrandGardenArt.stageScale(3), 0.8)
        XCTAssertEqual(GrandGardenArt.stageScale(2), 0.64)
        XCTAssertEqual(GrandGardenArt.stageScale(1), 0.5)
        XCTAssertEqual(GrandGardenArt.stageScale(0), 0.5)
        XCTAssertEqual(GrandGardenArt.stageScale(9), 1)
    }
}

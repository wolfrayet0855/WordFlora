import XCTest
import UIKit
@testable import WordFlora

final class PlantThinningTests: XCTestCase {
    private static var cached: PlantThinningManifest?
    private func manifest() throws -> PlantThinningManifest {
        if let m = Self.cached { return m }
        let m = try PlantThinningManifest.load()
        Self.cached = m
        return m
    }

    // MARK: manifest

    func testManifestCoversEveryCatalogPlant() throws {
        let m = try manifest()
        let names = Set(try PlantCatalog.load().map(\.imageName))
        XCTAssertEqual(names.count, 50)
        XCTAssertEqual(Set(m.plants.keys), names)
    }

    func testEveryLayerAndSpriteImageIsInTheAssetCatalog() throws {
        for (name, plant) in try manifest().plants {
            for image in plant.imageNames {
                XCTAssertNotNil(UIImage(named: image), "\(name): missing \(image)")
            }
        }
    }

    func testLayersReferenceRealPetalsAndDrawEachPetalOnce() throws {
        for (name, plant) in try manifest().plants {
            var drawn = Set<PetalRef>()
            for layer in plant.layers where layer.kind == .petals {
                for ref in layer.petalRefs {
                    XCTAssertTrue(plant.rings.indices.contains(ref.ring), name)
                    XCTAssertTrue(plant.rings[ref.ring].petals.indices.contains(ref.petal), name)
                    XCTAssertTrue(drawn.insert(ref).inserted, "\(name): petal drawn twice")
                }
            }
            XCTAssertEqual(drawn.count, plant.petalCount, name)
            XCTAssertEqual(plant.rings.reduce(0) { $0 + $1.petals.count }, plant.petalCount, name)
        }
    }

    func testCoverageKinds() throws {
        let plants = try manifest().plants
        XCTAssertEqual(plants["plant_daisy"]?.kind, .petals)
        XCTAssertEqual(plants["plant_sunflower"]?.rings.count, 2)
        XCTAssertEqual(plants["plant_baobab"]?.kind, .droop)
        XCTAssertEqual(plants["plant_saguaro_cactus"]?.kind, .droop)
        XCTAssertNotNil(plants["plant_tulip"]?.droop)
        XCTAssertEqual(plants["plant_rose"]?.rule?.name, "peel")
        for (name, p) in plants where p.kind == .petals { XCTAssertFalse(p.rings.isEmpty, name) }
        for (name, p) in plants where p.kind == .droop { XCTAssertNotNil(p.droop, name) }
    }

    // MARK: pure rules

    func testKeptCountMatchesThePrototype() {
        XCTAssertEqual((0...5).map { PetalThinning.keptCount(of: 16, pips: $0) }, [0, 2, 4, 8, 12, 16])
        XCTAssertEqual((0...5).map { PetalThinning.keptCount(of: 22, pips: $0) }, [0, 3, 6, 10, 16, 22])
        XCTAssertEqual((0...5).map { PetalThinning.keptCount(of: 5, pips: $0) }, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual((0...5).map { PetalThinning.keptCount(of: 2, pips: $0) }, [0, 1, 1, 1, 1, 2])
        XCTAssertEqual(PetalThinning.keptCount(of: 16, pips: 9), 16)
        XCTAssertEqual(PetalThinning.keptCount(of: 16, pips: -3), 0)
    }

    func testKeepOrderIsAPermutationSpreadRoundTheRing() {
        XCTAssertEqual(PetalThinning.keepOrder(count: 16), [0, 9, 3, 13, 7, 1, 11, 5, 15, 8, 2, 12, 6, 4, 10, 14])
        for n in 1...60 {
            XCTAssertEqual(Set(PetalThinning.keepOrder(count: n)), Set(0..<n), "n \(n)")
        }
        XCTAssertEqual(PetalThinning.keepOrder(count: 0), [])
    }

    func testSwiftRulesReproduceTheManifestExactly() throws {
        for (name, plant) in try manifest().plants {
            for (i, ring) in plant.rings.enumerated() {
                if ring.keptCounts == nil {  // peel schedules list their own order
                    XCTAssertEqual(PetalThinning.keepOrder(count: ring.petals.count), ring.keepOrder, "\(name) ring \(i)")
                }
                XCTAssertEqual(Set(ring.keepOrder), Set(ring.petals.indices), "\(name) ring \(i)")
                for pips in 0...5 {
                    XCTAssertEqual(ring.visiblePetals(pips: pips), ring.visible[String(pips)], "\(name) ring \(i) pips \(pips)")
                }
                for pips in 1...5 {
                    XCTAssertEqual(ring.fallOrder(fromPips: pips), ring.fall[String(pips)], "\(name) ring \(i) pips \(pips)")
                }
            }
        }
    }

    func testThinningIsMonotonicAndZeroPipsIsBare() throws {
        for (name, plant) in try manifest().plants {
            for ring in plant.rings {
                XCTAssertEqual(ring.visiblePetals(pips: 5), Array(ring.petals.indices), name)
                XCTAssertTrue(ring.visiblePetals(pips: 0).isEmpty, name)
                for pips in 1...5 {
                    let now = Set(ring.visiblePetals(pips: pips)), less = Set(ring.visiblePetals(pips: pips - 1))
                    XCTAssertTrue(less.isSubset(of: now), "\(name) pips \(pips)")
                    XCTAssertEqual(Set(ring.fallOrder(fromPips: pips)), now.subtracting(less), name)
                    guard ring.keptCounts == nil else { continue }  // peel schedules empty whole layers early
                    XCTAssertFalse(now.isEmpty, "\(name): only 0 pips is bare")
                    if ring.petals.count >= 5 { XCTAssertLessThan(less.count, now.count, "\(name): every pip drops a petal") }
                }
            }
            XCTAssertTrue(plant.visiblePetals(pips: 0).isEmpty, name)
            XCTAssertEqual(plant.visiblePetals(pips: 5).count, plant.petalCount, name)
            for pips in 1...5 where !plant.rings.isEmpty {
                XCTAssertFalse(plant.visiblePetals(pips: pips).isEmpty, "\(name): only 0 pips is bare")
                if plant.petalCount >= 5 {
                    XCTAssertFalse(plant.fallOrder(fromPips: pips).isEmpty, "\(name): every pip drops a petal at \(pips)")
                }
            }
        }
    }

    func testPlantFallOrderInterleavesRingsAndCoversEveryPetalOnce() throws {
        let sunflower = try XCTUnwrap(try manifest().plants["plant_sunflower"])
        var all: [PetalRef] = []
        for pips in 1...5 {
            let lost = sunflower.fallOrder(fromPips: pips)
            XCTAssertEqual(Set(lost), Set(sunflower.visiblePetals(pips: pips)).subtracting(sunflower.visiblePetals(pips: pips - 1)))
            all += lost
        }
        XCTAssertEqual(all.count, sunflower.petalCount)
        XCTAssertEqual(Set(all).count, sunflower.petalCount)
        let first = sunflower.fallOrder(fromPips: 5)
        XCTAssertEqual(Set(first.prefix(2).map(\.ring)), [0, 1], "rings shed together, not one after the other")
        XCTAssertTrue(sunflower.fallOrder(fromPips: 0).isEmpty)
        XCTAssertTrue(sunflower.fallOrder(fromPips: 6).isEmpty)
    }

    func testRulesAreDeterministic() throws {
        let a = try PlantThinningManifest.load(), b = try PlantThinningManifest.load()
        for (name, plant) in a.plants {
            let other = try XCTUnwrap(b.plants[name])
            for pips in 0...5 {
                XCTAssertEqual(plant.visiblePetals(pips: pips), other.visiblePetals(pips: pips), name)
                XCTAssertEqual(plant.visiblePetals(pips: pips), plant.visiblePetals(pips: pips), name)
                XCTAssertEqual(plant.droopPose(pips: pips), other.droopPose(pips: pips), name)
            }
        }
    }

    func testRosePeelsOuterToInner() throws {
        let rose = try XCTUnwrap(try manifest().plants["plant_rose"])
        let rule = try XCTUnwrap(rose.rule)
        XCTAssertEqual(rule.name, "peel")
        XCTAssertEqual(rule.status, "applied")
        let units = Dictionary(uniqueKeysWithValues: (rule.units ?? []).map { ($0.id, $0) })
        XCTAssertEqual(units.count, 8)
        // which units are gone at each pip count, from the rule's lose table
        func unitsShowing(_ pips: Int) -> Set<String> {
            let showing = Set(rose.visiblePetals(pips: pips))
            return Set(units.values.filter { u in u.petals.allSatisfy { showing.contains(PetalRef(ring: $0[0], petal: $0[1])) } }.map(\.id))
        }
        XCTAssertEqual(unitsShowing(5).count, 8)
        XCTAssertEqual(unitsShowing(4), ["o0", "o72", "o216", "wrap", "swirl", "heart"])
        XCTAssertEqual(unitsShowing(3), ["wrap", "swirl", "heart"])
        XCTAssertEqual(unitsShowing(2), ["swirl", "heart"])
        XCTAssertEqual(unitsShowing(1), ["heart"])
        XCTAssertEqual(unitsShowing(0), [])
        XCTAssertEqual(units["o288"]?.lostAtPips, 4)
        XCTAssertEqual(units["heart"]?.lostAtPips, 0)
        // an outer petal and its valley petal leave together
        XCTAssertEqual(units["o0"]?.petals.count, 2)
        XCTAssertTrue(rose.rings.flatMap(\.petals).allSatisfy { $0.fallSprite != nil })
        XCTAssertEqual(rose.layers.filter { $0.role == "sepal" }.count, 2)
        XCTAssertNotNil(rule.settle?["1"])
        XCTAssertEqual(rule.splayAt, 0)
    }

    // MARK: droop and exempt

    func testDroopGrowsWithEachLostPip() throws {
        let baobab = try XCTUnwrap(try manifest().plants["plant_baobab"])
        let poses = (0...5).map { baobab.droopPose(pips: $0) }
        XCTAssertEqual(poses[5], .upright)
        XCTAssertEqual(poses[0].tiltDegrees, 8.5, accuracy: 0.001)
        XCTAssertEqual(poses[0].saturation, 0.35, accuracy: 0.001)
        for k in 1...5 {
            XCTAssertGreaterThan(poses[k - 1].tiltDegrees, poses[k].tiltDegrees)
            XCTAssertLessThan(poses[k - 1].scaleY, poses[k].scaleY)
            XCTAssertLessThan(poses[k - 1].saturation, poses[k].saturation)
        }
        XCTAssertEqual(baobab.droopPose(pips: -2), poses[0])
        XCTAssertEqual(baobab.droopPose(pips: 8), poses[5])
        let daisy = try XCTUnwrap(try manifest().plants["plant_daisy"])
        XCTAssertNil(daisy.droop)
        XCTAssertEqual(daisy.droopPose(pips: 0), .upright, "petal plants without droop never tilt")
    }

    func testDroopAndExemptPlantsAreNeverEmpty() throws {
        for (name, plant) in try manifest().plants where plant.kind != .petals {
            XCTAssertTrue(plant.layers.contains { $0.kind == .static && $0.image != nil }, "\(name) has a body to draw")
            XCTAssertTrue(plant.isNeverEmpty, name)
        }
        for (name, plant) in try manifest().plants where plant.kind == .exempt {
            XCTAssertTrue(plant.rings.isEmpty, name)
            XCTAssertEqual(plant.droopPose(pips: 0), .upright, name)
        }
    }
}

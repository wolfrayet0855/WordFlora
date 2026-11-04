import XCTest
@testable import WordFlora

/// The pot collection (T-D, design-preview/pots): ten pots, unlocks computed from play, Plus gating, copy.
final class PotCatalogTests: XCTestCase {

    private func state(_ id: String, plants: Int = 0, levels: Int = 0, plus: Bool = false) -> PotState {
        PotCatalog.state(of: PotCatalog.pot(id: id), plantsGrown: plants, levelsFinished: levels, hasPlus: plus)
    }

    // MARK: Catalog

    func testTenPotsInTheMockOrderWithUniqueIds() {
        XCTAssertEqual(PotCatalog.all.map(\.id), ["plainBlue", "terracotta", "sageGlaze", "sunflower", "starlight",
                                                  "rosePink", "mint", "honeyStripe", "moonlit", "meadow"])
        XCTAssertEqual(Set(PotCatalog.all.map(\.id)).count, 10)
        XCTAssertEqual(Set(PotCatalog.all.map(\.name)).count, 10)
    }

    func testEveryPotHasItsOwnPatternSoNoneDependsOnHueAlone() {
        XCTAssertEqual(Set(PotCatalog.all.map(\.decoration.kind)).count, 10)
        XCTAssertEqual(PotCatalog.plainBlue.decoration.kind, .none)
        for pot in PotCatalog.all where pot.decoration.kind != .none {
            XCTAssertFalse(PotCatalog.marks(for: pot.decoration.kind).isEmpty, pot.id)
            let maxIndex = PotCatalog.marks(for: pot.decoration.kind).map(\.color).max() ?? 0
            XCTAssertLessThan(maxIndex, pot.decoration.colors.count, "\(pot.id) uses a colour it does not have")
        }
    }

    func testColoursMatchTheApprovedCatalog() {
        let blue = PotCatalog.pot(id: "plainBlue")
        XCTAssertEqual([blue.body, blue.rim, blue.shade], [0x5B8FD0, 0x7AA6DE, 0x4677B3])
        let terracotta = PotCatalog.pot(id: "terracotta")
        XCTAssertEqual(terracotta.decoration.colors, [0x7E3F22])
        XCTAssertEqual(PotCatalog.pot(id: "meadow").decoration.colors.count, 4)
    }

    func testGeometryFollowsTheReviewedValues() {
        let rings = PotCatalog.marks(for: .rings)
        XCTAssertEqual(rings.map(\.shape), [.rect(x: 18, y: 38, width: 84, height: 7), .rect(x: 18, y: 52, width: 84, height: 7)])
        XCTAssertEqual(rings.map(\.opacity), [1, 0.7])
        XCTAssertEqual(PotCatalog.marks(for: .drip).first?.shape, .rect(x: 18, y: 20, width: 84, height: 10))
        XCTAssertEqual(PotCatalog.marks(for: .flowerBand).first?.shape, .rect(x: 18, y: 70, width: 84, height: 30))
        let petals = PotCatalog.marks(for: .flower).filter { if case .petal = $0.shape { return true }; return false }
        XCTAssertEqual(petals.count, 8)
        XCTAssertEqual(petals.first?.shape, .petal(cx: 60, cy: 58, distance: 10, rx: 4.5, ry: 9, degrees: 0))
        XCTAssertEqual(PotCatalog.marks(for: .dots).count, 12)
        XCTAssertTrue(PotCatalog.marks(for: .moon).contains { $0.shape == .crescent(cx: 56, cy: 56, r: 15, cutX: 63, cutY: 51, cutR: 13) })
    }

    func testUnknownOrEmptyIdsFallBackToPlainBlue() {
        XCTAssertEqual(PotCatalog.pot(id: "").id, "plainBlue")
        XCTAssertEqual(PotCatalog.pot(id: "crystal").id, "plainBlue")
        XCTAssertEqual(PotCatalog.pot(id: "mint").id, "mint")
    }

    // MARK: Unlocks

    func testPlainBlueIsAlwaysOwned() {
        XCTAssertEqual(state("plainBlue"), .owned)
    }

    func testPlantUnlocksAtTheirBoundaries() {
        for (id, goal) in [("terracotta", 1), ("sageGlaze", 10), ("rosePink", 25), ("mint", 50)] {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(state(id, plants: goal - 1), .toEarn(hint: pot.hint), id)
            XCTAssertEqual(state(id, plants: goal), .owned, id)
            XCTAssertEqual(state(id, plants: goal + 1), .owned, id)
            XCTAssertEqual(state(id, plants: goal - 1, levels: 5, plus: true), .toEarn(hint: pot.hint), "levels and Plus do not earn \(id)")
        }
    }

    func testLevelUnlocksAtTheirBoundaries() {
        for (id, goal) in [("sunflower", 3), ("starlight", 5)] {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(state(id, levels: goal - 1), .toEarn(hint: pot.hint), id)
            XCTAssertEqual(state(id, levels: goal), .owned, id)
            XCTAssertEqual(state(id, plants: 50, levels: goal - 1, plus: true), .toEarn(hint: pot.hint), "plants and Plus do not earn \(id)")
        }
    }

    func testPlusPotsNeedPlus() {
        for id in ["honeyStripe", "moonlit", "meadow"] {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(state(id, plants: 50, levels: 5), .plus(hint: pot.hint), id)
            XCTAssertEqual(state(id, plus: true), .owned, id)
        }
    }

    func testChoosingNeedsTheStateButThePotInUseAlwaysStays() {
        let moonlit = PotCatalog.pot(id: "moonlit"), mint = PotCatalog.pot(id: "mint")
        XCTAssertFalse(PotCatalog.canChoose(moonlit, currentId: "", plantsGrown: 50, levelsFinished: 5, hasPlus: false))
        XCTAssertTrue(PotCatalog.canChoose(moonlit, currentId: "", plantsGrown: 0, levelsFinished: 0, hasPlus: true))
        // Plus ended: the pot already on the plant stays and can be kept.
        XCTAssertTrue(PotCatalog.canChoose(moonlit, currentId: "moonlit", plantsGrown: 0, levelsFinished: 0, hasPlus: false))
        XCTAssertFalse(PotCatalog.canChoose(mint, currentId: "", plantsGrown: 49, levelsFinished: 5, hasPlus: true))
        XCTAssertTrue(PotCatalog.canChoose(PotCatalog.plainBlue, currentId: "mint", plantsGrown: 0, levelsFinished: 0, hasPlus: false))
    }

    func testStatsComeFromFoundPlantsAndFullLevels() {
        var plants = (1...5).flatMap { level in (0..<10).map { _ in PlantProgress(level: level, earned: false, stage: 0) } }
        XCTAssertEqual(PotCatalog.stats(plants: plants).plantsGrown, 0)
        XCTAssertEqual(PotCatalog.stats(plants: plants).levelsFinished, 0)
        for i in 0..<10 { plants[i].earned = true }           // level 1 done
        for i in 10..<19 { plants[i].earned = true }          // level 2 one short
        let s = PotCatalog.stats(plants: plants)
        XCTAssertEqual(s.plantsGrown, 19)
        XCTAssertEqual(s.levelsFinished, 1)
    }

    // MARK: Progress lines

    func testProgressLines() {
        let starlight = PotCatalog.pot(id: "starlight"), sunflower = PotCatalog.pot(id: "sunflower")
        let rose = PotCatalog.pot(id: "rosePink"), terracotta = PotCatalog.pot(id: "terracotta")
        XCTAssertEqual(PotCatalog.tipLine(starlight, plantsGrown: 12, levelsFinished: 3), "You finished level 3. Two more levels to go!")
        XCTAssertEqual(PotCatalog.tipLine(sunflower, plantsGrown: 12, levelsFinished: 2), "You finished level 2. One more level to go!")
        XCTAssertEqual(PotCatalog.tipLine(sunflower, plantsGrown: 0, levelsFinished: 0), "Three more levels to go!")
        XCTAssertEqual(PotCatalog.tipLine(rose, plantsGrown: 12, levelsFinished: 0), "12 of 25 plants grown")
        XCTAssertEqual(PotCatalog.tipLine(terracotta, plantsGrown: 0, levelsFinished: 0), "Grow one plant to earn this pot.")
        XCTAssertEqual(PotCatalog.progressLine(starlight, plantsGrown: 0, levelsFinished: 3), "3 of 5 levels finished")
        XCTAssertEqual(PotCatalog.progressLine(rose, plantsGrown: 12, levelsFinished: 0), "12 of 25 plants grown")
        XCTAssertEqual(PotCatalog.progress(rose, plantsGrown: 30, levelsFinished: 0)?.fraction, 1)
        XCTAssertEqual(PotCatalog.progress(rose, plantsGrown: 5, levelsFinished: 0)?.fraction ?? 0, 0.2, accuracy: 0.0001)
        XCTAssertNil(PotCatalog.progress(PotCatalog.plainBlue, plantsGrown: 0, levelsFinished: 0))
        XCTAssertNil(PotCatalog.progress(PotCatalog.pot(id: "moonlit"), plantsGrown: 0, levelsFinished: 0))
        XCTAssertEqual(PotCatalog.goalLine(rose), "Grow 25 plants")
        XCTAssertEqual(PotCatalog.goalLine(terracotta), "Grow one plant")
        XCTAssertEqual(PotCatalog.goalLine(starlight), "Finish level 5")
    }

    func testRepotButtonNamesTheNewPot() {
        XCTAssertEqual(PotCatalog.repotTitle(picked: PotCatalog.pot(id: "sunflower"), currentId: ""), "Repot into Sunflower")
        XCTAssertEqual(PotCatalog.repotTitle(picked: PotCatalog.plainBlue, currentId: ""), "Repot with fresh soil")
        XCTAssertEqual(PotCatalog.repotTitle(picked: PotCatalog.pot(id: "mint"), currentId: "mint"), "Repot with fresh soil")
        XCTAssertEqual(PotCatalog.repotTitle(picked: PotCatalog.plainBlue, currentId: "mint"), "Repot into Plain blue")
    }

    func testTileLabelsNameTheState() {
        XCTAssertEqual(PotCatalog.tileLabel(PotCatalog.pot(id: "sageGlaze"), state: .owned, inUse: true), "Sage glaze pot, in use")
        XCTAssertEqual(PotCatalog.tileLabel(PotCatalog.pot(id: "mint"), state: .owned, inUse: false), "Mint pot")
        let starlight = PotCatalog.pot(id: "starlight")
        XCTAssertEqual(PotCatalog.tileLabel(starlight, state: .toEarn(hint: starlight.hint), inUse: false), "Starlight pot, not earned yet")
        let moonlit = PotCatalog.pot(id: "moonlit")
        XCTAssertEqual(PotCatalog.tileLabel(moonlit, state: .plus(hint: moonlit.hint), inUse: false), "Moonlit pot, Plus")
    }

    // MARK: Copy

    func testEveryNameHintAndLineIsKind() {
        var lines = PotCatalog.Copy.all
        for pot in PotCatalog.all {
            lines += [pot.name, pot.hint, pot.a11y, PotCatalog.goalLine(pot), PotCatalog.plusLine(pot)]
            lines += [PotCatalog.repotTitle(picked: pot, currentId: "")]
            for (plants, levels) in [(0, 0), (1, 1), (12, 3), (49, 4)] {
                lines += [PotCatalog.tipLine(pot, plantsGrown: plants, levelsFinished: levels),
                          PotCatalog.progressLine(pot, plantsGrown: plants, levelsFinished: levels)]
            }
        }
        let extra = ["only", "last", "left", "waiting", "lost", "empty", "locked", "buy", "price"]
        for line in lines where !line.isEmpty {
            XCTAssertEqual(CopySafety.check(line), [], line)
            for word in extra {
                XCTAssertNil(line.range(of: "\\b\(word)\\b", options: [.regularExpression, .caseInsensitive]), "\(word) in \(line)")
            }
        }
    }

    // MARK: AppModel: choosing a pot

    @MainActor
    func testChoosingAPotSavesItAndAPlusPotStaysAfterPlusEnds() throws {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-pots-\(UUID().uuidString)")!)
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, notifications: ReminderTests.FakeCenter())
        let plant = app.plants().first!; plant.earnedCount = 1
        XCTAssertEqual(app.potStats.plantsGrown, 1)
        XCTAssertEqual(app.potState(PotCatalog.pot(id: "terracotta")), .owned)

        XCTAssertFalse(app.choosePot(PotCatalog.pot(id: "sageGlaze"), for: plant), "not earned yet")
        XCTAssertFalse(app.choosePot(PotCatalog.pot(id: "moonlit"), for: plant), "Plus pots need Plus")
        XCTAssertEqual(plant.potId, "")
        XCTAssertTrue(app.choosePot(PotCatalog.pot(id: "terracotta"), for: plant))
        XCTAssertEqual(plant.potId, "terracotta")
        XCTAssertNotNil(plant.lastTendedAt)
        XCTAssertEqual(app.plantsUsing(PotCatalog.pot(id: "terracotta")).map(\.plantId), [plant.plantId])

        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        XCTAssertTrue(app.choosePot(PotCatalog.pot(id: "moonlit"), for: plant))
        app.entitlements.debugForce(EntitlementState(activeProductIDs: []))
        XCTAssertEqual(plant.potId, "moonlit", "nothing is taken away when Plus ends")
        XCTAssertTrue(app.canChoose(PotCatalog.pot(id: "moonlit"), for: plant), "the pot in use can stay")
        XCTAssertFalse(app.choosePot(PotCatalog.pot(id: "meadow"), for: plant))
        XCTAssertTrue(app.choosePot(PotCatalog.plainBlue, for: plant))
        XCTAssertEqual(plant.potId, "plainBlue")
    }

    func testPlusHintPointsToSettings() {
        for pot in PotCatalog.all where pot.unlock == .plus {
            XCTAssertEqual(pot.hint, "Part of WordFlora Plus. A grown-up can find Plus in Settings.")
        }
        XCTAssertEqual(PotCatalog.plusLine(PotCatalog.pot(id: "moonlit")), "Moonlit is part of WordFlora Plus.")
    }
}

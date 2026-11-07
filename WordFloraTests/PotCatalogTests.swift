import XCTest
@testable import WordFlora

/// Levels 1 through n finished, the usual order of play.
private func upTo(_ n: Int) -> Set<Int> { n < 1 ? [] : Set(1...n) }

private func stats(plants: Int = 0, levels: Int = 0, finished: Set<Int>? = nil, inLevel: [Int: Int] = [:],
                   days: Int = 0, earned: Set<String> = []) -> PotCatalog.Stats {
    PotCatalog.Stats(plantsGrown: plants, finishedLevels: finished ?? upTo(levels), plantsInLevel: inLevel,
                     gardenDays: days, earnedPotIds: earned)
}

/// The pot collection (T-D, docs/pm/pot-earning-review.md): sixteen pots, unlocks from play or the stored record,
/// the old rules kept as a fallback, Plus gating, copy.
final class PotCatalogTests: XCTestCase {

    private func state(_ id: String, plants: Int = 0, levels: Int = 0, finished: Set<Int>? = nil, days: Int = 0,
                       earned: Set<String> = [], plus: Bool = false) -> PotState {
        PotCatalog.state(of: PotCatalog.pot(id: id), stats: stats(plants: plants, levels: levels, finished: finished, days: days, earned: earned),
                         hasPlus: plus)
    }

    // MARK: Catalog

    static let order = ["plainBlue", "terracotta", "sageGlaze", "sunflower", "mint", "blossom", "rosePink", "livingStones",
                        "flytrap", "starlight", "jadeVine", "rainbowBark", "dewdrop", "honeyStripe", "moonlit", "meadow"]

    /// At accessibility sizes a Shed pot card is narrow (four a row, words held at xxxLarge): its Plus line uses only
    /// short words so none breaks mid-word ("Word-Flora"); it is in the CopySafety sweep.
    func testTheShortPlusCardLineHasOnlyShortWords() {
        let line = PotCatalog.Copy.plusCardShort
        XCTAssertEqual(line, "A Plus pot")
        XCTAssertTrue(line.split(separator: " ").allSatisfy { $0.count <= 6 }, line)
        XCTAssertTrue(PotCatalog.Copy.all.contains(line))
    }

    func testSixteenPotsInClimbOrderWithUniqueIds() {
        XCTAssertEqual(PotCatalog.all.map(\.id), Self.order)
        XCTAssertEqual(Set(PotCatalog.all.map(\.id)).count, 16)
        XCTAssertEqual(Set(PotCatalog.all.map(\.name)).count, 16)
        XCTAssertEqual(PotCatalog.gridColumns, 4, "a 4 x 4 grid")
        XCTAssertEqual(PotCatalog.all.count, PotCatalog.gridColumns * 4)
    }

    func testEveryPotHasItsOwnPatternSoNoneDependsOnHueAlone() {
        XCTAssertEqual(Set(PotCatalog.all.map(\.decoration.kind)).count, 16)
        // Sixteen ladder patterns plus the three Frost & Lantern ones; every pot, pack pots too, has its own.
        XCTAssertEqual(Set(Pot.Decoration.Kind.allCases).count, 19)
        XCTAssertEqual(Set((PotCatalog.all + PotCatalog.packPots).map(\.decoration.kind)).count, 19)
        XCTAssertEqual(PotCatalog.plainBlue.decoration.kind, .none)
        for pot in PotCatalog.all + PotCatalog.packPots where pot.decoration.kind != .none {
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
        // The six new pots (pots.json `proposal.pots`).
        let expected: [(String, [UInt32], Pot.Decoration.Kind, [UInt32])] = [
            ("blossom", [0x9A6A9E, 0xBE93C2, 0x7A4F7E], .blossoms, [0xFFE6EE, 0xF2C14E]),
            ("livingStones", [0xDDBB8E, 0xECD3AE, 0xB89262], .pebbles, [0x55663A, 0x3B2E22]),
            ("flytrap", [0x4E8A3A, 0x7BB25C, 0x3A6C2B], .zigzag, [0xF29A8A, 0xFFFFFF]),
            ("jadeVine", [0xE9EEF0, 0x4FA89A, 0xC4CED2], .vine, [0x3FB8A6, 0x2F6B4A]),
            ("rainbowBark", [0x8A7B63, 0xAA9B80, 0x6E6150], .bark, [0xEE8A3C, 0x8C5BA6, 0x4E8FC4, 0xB5474A]),
            ("dewdrop", [0x9686CC, 0xB9ADE3, 0x7666B0], .drops, [0xE3F2FC, 0xFFFFFF]),
        ]
        for (id, bodyRimShade, kind, colors) in expected {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(pot.id, id)
            XCTAssertEqual([pot.body, pot.rim, pot.shade], bodyRimShade, id)
            XCTAssertEqual(pot.decoration.kind, kind, id)
            XCTAssertEqual(pot.decoration.colors, colors, id)
        }
    }

    func testNamesHintsAndLabelsOfTheNewPots() {
        let expected: [(String, String, String, String)] = [
            ("blossom", "Blossom", "Finish level 2 to earn this pot.", "Plum pot with pink blossoms"),
            ("livingStones", "Living stones", "Finish level 3 to earn this pot.", "Sandy pot with little living stones"),
            ("flytrap", "Flytrap", "Grow 35 plants to earn this pot.", "Green pot with fly-trap teeth"),
            ("jadeVine", "Jade vine", "Grow 45 plants to earn this pot.", "White pot with hanging jade flowers"),
            ("rainbowBark", "Rainbow bark", "Finish level 5 to earn this pot.", "Brown pot with rainbow bark stripes"),
            ("dewdrop", "Dewdrop", "Play on 7 different days to earn this pot. Any days count!", "Lilac pot with dewdrops"),
        ]
        for (id, name, hint, a11y) in expected {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual([pot.name, pot.hint, pot.a11y], [name, hint, a11y], id)
        }
        // Written "Flytrap", read aloud as "Fly-trap".
        let flytrap = PotCatalog.pot(id: "flytrap")
        XCTAssertEqual(PotCatalog.tileLabel(flytrap, state: .owned, inUse: false), "Fly-trap pot")
        XCTAssertEqual(PotCatalog.tileLabel(flytrap, state: .toEarn(hint: flytrap.hint), inUse: false), "Fly-trap pot, not earned yet")
        XCTAssertEqual(PotCatalog.pot(id: "jadeVine").voiceName, "Jade vine")
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

    /// pots.json `proposal.newDecorations`: mark counts and a few exact marks per new kind.
    func testTheSixNewPatternsFollowTheProposal() {
        let blossoms = PotCatalog.marks(for: .blossoms)
        XCTAssertEqual(blossoms.count, 5 * 6, "five flowers of five petals and a centre")
        XCTAssertEqual(blossoms[0].shape, .circle(cx: 40, cy: 39, r: 4.6), "petal 0 points up")
        XCTAssertEqual(blossoms[5].shape, .circle(cx: 40, cy: 44, r: 2.4))
        XCTAssertEqual(blossoms[5].color, 1)
        XCTAssertEqual(blossoms[5].ghost, .fill, "a centre is a knock-out on the outline")

        let pebbles = PotCatalog.marks(for: .pebbles)
        XCTAssertEqual(pebbles.count, 5 + 3 * 2, "five sand specks, three domes with a cleft each")
        XCTAssertEqual(pebbles[0].opacity, 0.6)
        XCTAssertTrue(pebbles.contains { $0.shape == .petal(cx: 64, cy: 64, distance: 0, rx: 14, ry: 12, degrees: 0) })
        XCTAssertTrue(pebbles.contains { $0.shape == .capsule(x: 62.7, y: 52, width: 2.6, height: 14.4) })

        let zigzag = PotCatalog.marks(for: .zigzag)
        XCTAssertEqual(zigzag.count, 2 + 7 + 5 + 7, "two bands, twelve teeth, seven dew dots")
        XCTAssertTrue(zigzag.contains { $0.shape == .triangle(x1: 18, y1: 26, x2: 30, y2: 26, x3: 24, y3: 38) })
        XCTAssertTrue(zigzag.contains { $0.shape == .triangle(x1: 30, y1: 86, x2: 42, y2: 86, x3: 36, y3: 74) })
        XCTAssertEqual(zigzag.filter { $0.ghost == .hidden }.count, 7)

        let vine = PotCatalog.marks(for: .vine)
        XCTAssertEqual(vine.count, 1 + 3 + 7 * 3, "a stem band, three drop stems, seven clusters of three claws")
        XCTAssertEqual(vine[0].shape, .rect(x: 18, y: 26, width: 84, height: 4))
        XCTAssertTrue(vine.contains { $0.shape == .petal(cx: 30, cy: 30, distance: 11, rx: 3.2, ry: 7.5, degrees: 155) })
        XCTAssertTrue(vine.contains { $0.shape == .capsule(x: 39.5, y: 30, width: 3, height: 26) })

        let bark = PotCatalog.marks(for: .bark)
        XCTAssertEqual(bark.count, 14)
        XCTAssertEqual(bark[0].shape, .capsule(x: 19.5, y: 20, width: 9, height: 26))
        XCTAssertEqual(Set(bark.map(\.color)), [0, 1, 2, 3])

        let drops = PotCatalog.marks(for: .drops)
        XCTAssertEqual(drops.count, 6 + 2)
        XCTAssertTrue(drops.contains { $0.shape == .teardrop(cx: 50, cy: 70, scale: 1.3) })
        XCTAssertEqual(drops.filter { $0.ghost == .hidden }.count, 2, "the sparkles leave the outline")
    }

    func testUnknownOrEmptyIdsFallBackToPlainBlue() {
        XCTAssertEqual(PotCatalog.pot(id: "").id, "plainBlue")
        XCTAssertEqual(PotCatalog.pot(id: "crystal").id, "plainBlue")
        XCTAssertEqual(PotCatalog.pot(id: "mint").id, "mint")
        XCTAssertEqual(PotCatalog.pot(id: "livingStones").id, "livingStones")
    }

    // MARK: Unlocks

    func testPlainBlueIsAlwaysOwned() {
        XCTAssertEqual(state("plainBlue"), .owned)
    }

    func testPlantUnlocksAtTheirBoundaries() {
        for (id, goal) in [("terracotta", 1), ("sageGlaze", 5), ("mint", 15), ("rosePink", 25), ("flytrap", 35), ("jadeVine", 45)] {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(state(id, plants: goal - 1), .toEarn(hint: pot.hint), id)
            XCTAssertEqual(state(id, plants: goal), .owned, id)
            XCTAssertEqual(state(id, plants: goal + 1), .owned, id)
            XCTAssertEqual(state(id, plants: goal - 1, levels: goal >= 10 ? (goal - 1) / 10 : 0, days: 30, plus: true),
                           .toEarn(hint: pot.hint), "levels, days and Plus do not earn \(id)")
        }
    }

    func testLevelUnlocksAtTheirBoundaries() {
        for (id, goal) in [("sunflower", 1), ("blossom", 2), ("livingStones", 3), ("starlight", 4), ("rainbowBark", 5)] {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(state(id, levels: goal - 1), .toEarn(hint: pot.hint), id)
            XCTAssertEqual(state(id, levels: goal), .owned, id)
            XCTAssertEqual(state(id, plants: 4, levels: goal - 1, days: 30, plus: true), .toEarn(hint: pot.hint),
                           "plants, days and Plus do not earn \(id)")
        }
    }

    func testDewdropComesWithSevenGardenDaysAndStaysAfterAMerge() {
        let dewdrop = PotCatalog.pot(id: "dewdrop")
        XCTAssertEqual(dewdrop.unlock, .gardenDays(7))
        XCTAssertEqual(state("dewdrop", plants: 50, levels: 5, days: 6), .toEarn(hint: dewdrop.hint))
        XCTAssertEqual(state("dewdrop", days: 7), .owned)
        XCTAssertEqual(state("dewdrop", days: 40), .owned)
        // Garden Days merge by max, so a merge with a device that has fewer days keeps the pot.
        let a = PlayerProfile(); a.gardenDays = 7
        let b = PlayerProfile(); b.gardenDays = 3; b.gamesPlayed = 99
        DataReconciler.merge(a, into: b, defs: [])
        XCTAssertEqual(state("dewdrop", days: b.gardenDays), .owned)
        // Counts up only, never down.
        XCTAssertEqual(PotCatalog.progressLine(dewdrop, stats: stats(days: 3)), "3 of 7 garden days")
        XCTAssertEqual(PotCatalog.progress(dewdrop, stats: stats(days: 9)), PotCatalog.Progress(now: 7, goal: 7))
        XCTAssertEqual(PotCatalog.goalLine(dewdrop), "Play on 7 days")
    }

    func testPlusPotsNeedPlus() {
        for id in ["honeyStripe", "moonlit", "meadow"] {
            let pot = PotCatalog.pot(id: id)
            XCTAssertEqual(state(id, plants: 50, levels: 5, days: 30), .plus(hint: pot.hint), id)
            XCTAssertEqual(state(id, earned: [id]), .plus(hint: pot.hint), "a stored id never stands in for Plus")
            XCTAssertEqual(state(id, plus: true), .owned, id)
        }
    }

    func testALevelPotNeedsThatLevelFinishedNotJustThatManyLevels() {
        let blossom = PotCatalog.pot(id: "blossom"), rainbow = PotCatalog.pot(id: "rainbowBark")
        // Three levels finished, but not level 2: Blossom (finish level 2) is still to earn.
        XCTAssertEqual(state("blossom", finished: [1, 3, 4]), .toEarn(hint: blossom.hint))
        XCTAssertFalse(PotCatalog.canChoose(blossom, currentId: "", stats: stats(plants: 30, finished: [1, 3, 4]), hasPlus: true))
        // Level 2 alone earns Blossom, and not Rainbow bark (finish level 5).
        XCTAssertEqual(state("blossom", finished: [2]), .owned)
        XCTAssertEqual(state("rainbowBark", finished: [2]), .toEarn(hint: rainbow.hint))
        XCTAssertTrue(PotCatalog.canChoose(blossom, currentId: "", stats: stats(plants: 10, finished: [2]), hasPlus: false))
        XCTAssertEqual(state("rainbowBark", finished: [1, 2, 3, 4]), .toEarn(hint: rainbow.hint))
        XCTAssertEqual(state("rainbowBark", finished: [5]), .owned)
    }

    /// The four pots whose goals moved earlier keep their old rule too (owned = new rule OR old rule).
    func testMovedPotsKeepTheirOldRule() {
        XCTAssertEqual(PotCatalog.pot(id: "sageGlaze").legacy, [.plants(10)])
        XCTAssertEqual(PotCatalog.pot(id: "sunflower").legacy, [.level(3)])
        XCTAssertEqual(PotCatalog.pot(id: "mint").legacy, [.plants(50)])
        XCTAssertEqual(PotCatalog.pot(id: "starlight").legacy, [.level(5)])
        // Out-of-order fixtures (a sync merge, a restored backup): the old rule still passes.
        XCTAssertEqual(state("sunflower", finished: [3]), .owned, "level 3 alone, as the old rule asked")
        XCTAssertEqual(state("starlight", finished: [5]), .owned, "level 5 alone, as the old rule asked")
        XCTAssertEqual(state("sunflower", finished: [2, 4]), .toEarn(hint: PotCatalog.pot(id: "sunflower").hint))
    }

    /// The approved v1 table: ten pots and their old rules, before the 2026-11 ladder.
    private static let v1: [(String, Pot.Unlock)] = [
        ("plainBlue", .free), ("terracotta", .plants(1)), ("sageGlaze", .plants(10)), ("sunflower", .level(3)),
        ("starlight", .level(5)), ("rosePink", .plants(25)), ("mint", .plants(50)),
        ("honeyStripe", .plus), ("moonlit", .plus), ("meadow", .plus),
    ]

    /// Nobody loses a pot: for every plant count 0...50, every set of finished levels, Garden Days 0...10 and
    /// with and without Plus, a pot owned under the v1 rules is owned now.
    func testEverythingOwnedUnderTheOldRulesIsStillOwned() {
        let levelSets: [Set<Int>] = (0..<32).map { mask in Set((1...5).filter { mask & (1 << ($0 - 1)) != 0 }) }
        var checked = 0
        for plants in 0...50 {
            for finished in levelSets {
                for days in 0...10 {
                    for plus in [false, true] {
                        let s = stats(plants: plants, finished: finished, days: days)
                        for (id, rule) in Self.v1 {
                            let ownedV1: Bool = {
                                switch rule {
                                case .free: return true
                                case .plants(let n): return plants >= n
                                case .level(let n): return finished.contains(n)
                                case .gardenDays(let n): return days >= n
                                case .plus: return plus
                                case .pack, .seasonBlooms: return false      // not in the old rules
                                }
                            }()
                            guard ownedV1 else { continue }
                            checked += 1
                            if PotCatalog.state(of: PotCatalog.pot(id: id), stats: s, hasPlus: plus) != .owned {
                                return XCTFail("\(id) taken away at plants \(plants), levels \(finished.sorted()), days \(days), Plus \(plus)")
                            }
                        }
                    }
                }
            }
        }
        XCTAssertGreaterThan(checked, 100_000)
        XCTAssertEqual(Set(Self.v1.map(\.0)).subtracting(PotCatalog.all.map(\.id)), [], "no v1 id was renamed or removed")
    }

    /// The pace model (3 correct words a plant, the first plant on word 1, ten plants a level): every pot earned
    /// by words comes later than the one before it in the climb, and no two share a rung.
    func testTheLadderClimbsOneRungAtATime() {
        func words(_ u: Pot.Unlock) -> Int? {
            switch u {
            case .plants(let k): return 3 * k - 2
            case .level(let n): return 3 * (PotCatalog.plantsPerLevel * n) - 2
            default: return nil
            }
        }
        let rungs = PotCatalog.all.compactMap { words($0.unlock) }
        XCTAssertEqual(rungs, [1, 13, 28, 43, 58, 73, 88, 103, 118, 133, 148])
        XCTAssertEqual(rungs, rungs.sorted())
        XCTAssertEqual(Set(rungs).count, rungs.count)
        // Every goal moved earlier, never later.
        for pot in PotCatalog.all {
            for old in pot.legacy { XCTAssertLessThan(words(pot.unlock)!, words(old)!, pot.id) }
        }
    }

    func testAStoredPotStaysOwnedWhateverTheNumbersSay() {
        let rose = PotCatalog.pot(id: "rosePink")
        XCTAssertEqual(state("rosePink", plants: 3), .toEarn(hint: rose.hint))
        XCTAssertEqual(state("rosePink", plants: 3, earned: ["rosePink"]), .owned, "a restored older backup keeps it")
        XCTAssertTrue(PotCatalog.canChoose(rose, currentId: "", stats: stats(earned: ["rosePink"]), hasPlus: false))
        XCTAssertEqual(state("blossom", earned: ["crystal", "rosePink"]), .toEarn(hint: PotCatalog.pot(id: "blossom").hint))
    }

    func testRecordingAddsEarnedPotsAndNeverRemovesAny() {
        XCTAssertEqual(PotCatalog.recordEarned([], stats: stats()), [], "plain blue is never recorded")
        XCTAssertEqual(PotCatalog.recordEarned([], stats: stats(plants: 5)), ["sageGlaze", "terracotta"])
        XCTAssertEqual(PotCatalog.recordEarned(["rosePink"], stats: stats(plants: 1)), ["rosePink", "terracotta"], "kept, never removed")
        XCTAssertEqual(PotCatalog.recordEarned([], stats: stats(finished: [5], days: 7)).sorted(),
                       ["dewdrop", "rainbowBark", "starlight"].sorted(), "old rules count too")
        // Plus pots are never recorded: choosing one needs Plus.
        let all = PotCatalog.recordEarned([], stats: stats(plants: 50, levels: 5, days: 10))
        XCTAssertEqual(all.count, 12)
        XCTAssertFalse(all.contains { ["plainBlue", "honeyStripe", "moonlit", "meadow"].contains($0) })
        XCTAssertEqual(all, all.sorted())
    }

    func testChoosingNeedsTheStateButThePotInUseAlwaysStays() {
        let moonlit = PotCatalog.pot(id: "moonlit"), flytrap = PotCatalog.pot(id: "flytrap")
        XCTAssertFalse(PotCatalog.canChoose(moonlit, currentId: "", stats: stats(plants: 50, levels: 5), hasPlus: false))
        XCTAssertTrue(PotCatalog.canChoose(moonlit, currentId: "", stats: stats(), hasPlus: true))
        // Plus ended: the pot already on the plant stays and can be kept.
        XCTAssertTrue(PotCatalog.canChoose(moonlit, currentId: "moonlit", stats: stats(), hasPlus: false))
        XCTAssertFalse(PotCatalog.canChoose(flytrap, currentId: "", stats: stats(plants: 34, levels: 3), hasPlus: true))
        XCTAssertTrue(PotCatalog.canChoose(flytrap, currentId: "flytrap", stats: stats(), hasPlus: false))
        XCTAssertTrue(PotCatalog.canChoose(PotCatalog.plainBlue, currentId: "mint", stats: stats(), hasPlus: false))
    }

    func testStatsComeFromFoundPlantsAndFullLevels() {
        var plants = (1...5).flatMap { level in (0..<10).map { _ in PlantProgress(level: level, earned: false, stage: 0) } }
        XCTAssertEqual(PotCatalog.stats(plants: plants).plantsGrown, 0)
        XCTAssertEqual(PotCatalog.stats(plants: plants).levelsFinished, 0)
        XCTAssertEqual(PotCatalog.stats(plants: plants).plantsInLevel, [:])
        for i in 0..<10 { plants[i].earned = true }           // level 1 done
        for i in 10..<19 { plants[i].earned = true }          // level 2 one short
        let s = PotCatalog.stats(plants: plants, gardenDays: 4, earnedPotIds: ["mint"])
        XCTAssertEqual(s.plantsGrown, 19)
        XCTAssertEqual(s.levelsFinished, 1)
        XCTAssertEqual(s.finishedLevels, [1])
        XCTAssertEqual(s.plantsInLevel, [1: 10, 2: 9])
        XCTAssertEqual(s.gardenDays, 4)
        XCTAssertEqual(s.earnedPotIds, ["mint"])
        for i in 0..<10 { plants[i].earned = false }          // level 3 done, level 1 not
        for i in 20..<30 { plants[i].earned = true }
        XCTAssertEqual(PotCatalog.stats(plants: plants).finishedLevels, [3])
        XCTAssertEqual(PotCatalog.stats(plants: plants).levelsFinished, 1)
        XCTAssertEqual(PotCatalog.stats(plants: plants).plantsInLevel, [2: 9, 3: 10])
    }

    // MARK: Progress lines

    func testALevelPotCountsThatLevelsPlants() {
        let stones = PotCatalog.pot(id: "livingStones")
        let s = stats(plants: 26, levels: 2, inLevel: [1: 10, 2: 10, 3: 6])
        XCTAssertEqual(PotCatalog.progress(stones, stats: s), PotCatalog.Progress(now: 6, goal: 10))
        XCTAssertEqual(PotCatalog.progressLine(stones, stats: s), "6 of 10 plants in level 3")
        XCTAssertEqual(PotCatalog.tipLine(stones, stats: s), "Four more plants to go!")
        XCTAssertEqual(PotCatalog.tipLine(stones, stats: stats(inLevel: [3: 9])), "One more plant to go!")
        XCTAssertEqual(PotCatalog.tipLine(stones, stats: stats()), "Ten more plants to go!")
        XCTAssertEqual(PotCatalog.progressLine(stones, stats: stats()), "0 of 10 plants in level 3")
        // A finished level shows a full bar.
        XCTAssertEqual(PotCatalog.progress(stones, stats: stats(finished: [3]))?.fraction, 1)
        XCTAssertEqual(PotCatalog.progressLine(stones, stats: stats(finished: [3])), "10 of 10 plants in level 3")
    }

    func testProgressLines() {
        let starlight = PotCatalog.pot(id: "starlight"), sunflower = PotCatalog.pot(id: "sunflower")
        let rose = PotCatalog.pot(id: "rosePink"), terracotta = PotCatalog.pot(id: "terracotta")
        XCTAssertEqual(PotCatalog.progressLine(starlight, stats: stats(plants: 32, levels: 3, inLevel: [4: 2])), "2 of 10 plants in level 4")
        XCTAssertEqual(PotCatalog.progressLine(sunflower, stats: stats(plants: 6, inLevel: [1: 6])), "6 of 10 plants in level 1")
        XCTAssertEqual(PotCatalog.tipLine(sunflower, stats: stats(plants: 6, inLevel: [1: 6])), "Four more plants to go!")
        XCTAssertEqual(PotCatalog.tipLine(rose, stats: stats(plants: 12)), "12 of 25 plants grown")
        XCTAssertEqual(PotCatalog.tipLine(terracotta, stats: stats()), "Grow one plant to earn this pot.")
        XCTAssertEqual(PotCatalog.progressLine(rose, stats: stats(plants: 12)), "12 of 25 plants grown")
        XCTAssertEqual(PotCatalog.progressLine(PotCatalog.pot(id: "sageGlaze"), stats: stats(plants: 3)), "3 of 5 plants grown")
        XCTAssertEqual(PotCatalog.progress(rose, stats: stats(plants: 30))?.fraction, 1)
        XCTAssertEqual(PotCatalog.progress(rose, stats: stats(plants: 5))?.fraction ?? 0, 0.2, accuracy: 0.0001)
        XCTAssertNil(PotCatalog.progress(PotCatalog.plainBlue, stats: stats()))
        XCTAssertNil(PotCatalog.progress(PotCatalog.pot(id: "moonlit"), stats: stats()))
        XCTAssertEqual(PotCatalog.goalLine(rose), "Grow 25 plants")
        XCTAssertEqual(PotCatalog.goalLine(terracotta), "Grow one plant")
        XCTAssertEqual(PotCatalog.goalLine(starlight), "Finish level 4")
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
            lines += SoilType.allCases.map { PotCatalog.summaryLine(pot: pot, soil: $0) }
            lines += [PotCatalog.tileLabel(pot, state: .owned, inUse: false, isNew: true)]
            lines += [PotCatalog.tileLabel(pot, state: .owned, inUse: true), PotCatalog.tileLabel(pot, state: .toEarn(hint: pot.hint), inUse: false),
                      PotCatalog.tileLabel(pot, state: .plus(hint: pot.hint), inUse: false)]
            for (plants, levels, inLevel, days) in [(0, 0, 0, 0), (1, 0, 1, 1), (12, 1, 2, 3), (34, 3, 4, 6), (49, 4, 9, 7), (50, 5, 10, 12)] {
                let s = stats(plants: plants, levels: levels, inLevel: [levels + 1: inLevel], days: days)
                lines += [PotCatalog.tipLine(pot, stats: s), PotCatalog.progressLine(pot, stats: s)]
                for hasPlus in [false, true] {
                    let h = PotCatalog.hintLines(pot, state: PotCatalog.state(of: pot, stats: s, hasPlus: hasPlus), stats: s)
                    lines += [h.title, h.detail]
                }
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

    @MainActor
    func testChoosingAPotIsNotTendingSoTheThirstyLookAndWidgetStay() throws {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-pots-\(UUID().uuidString)")!)
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, notifications: ReminderTests.FakeCenter())
        let plant = app.plants().first!; plant.earnedCount = 1
        let tended = Date(timeIntervalSince1970: 1_000)
        plant.lastTendedAt = tended
        XCTAssertEqual(plant.potChosenAt, .distantPast, "a plant that never chose a pot")
        let before = Date.now
        XCTAssertTrue(app.choosePot(PotCatalog.pot(id: "terracotta"), for: plant))
        XCTAssertEqual(plant.lastTendedAt, tended, "choosing a pot does not count as tending")
        XCTAssertGreaterThanOrEqual(plant.potChosenAt, before, "the pick is stamped so iCloud keeps the latest one")

        let untended = app.plants()[1]; untended.earnedCount = 1
        XCTAssertTrue(app.choosePot(PotCatalog.pot(id: "terracotta"), for: untended))
        XCTAssertNil(untended.lastTendedAt)
    }

    @MainActor
    func testEarnedPotsAreRecordedOnceAndKeptWhenTheNumbersDrop() throws {
        let container = try SharedContainer.make(inMemory: true)
        let settings = AppSettings(defaults: UserDefaults(suiteName: "wf-pots-\(UUID().uuidString)")!)
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let app = AppModel(container: container, settings: settings, bank: bank, notifications: ReminderTests.FakeCenter())
        let profile = try XCTUnwrap(app.profile)
        XCTAssertEqual(profile.earnedPotIds, [], "a new garden has nothing recorded")
        XCTAssertEqual(app.recordEarnedPots(), [], "plain blue alone is nothing new")

        for p in app.plants().prefix(5) { p.earnedCount = 1 }
        profile.gardenDays = 7
        XCTAssertEqual(app.recordEarnedPots(), ["terracotta", "sageGlaze", "dewdrop"],
                       "new pots, in catalog order: the picker tags them and says so once")
        XCTAssertEqual(Set(profile.earnedPotIds), ["terracotta", "sageGlaze", "dewdrop"])
        XCTAssertEqual(app.recordEarnedPots(), [], "the second opening has nothing new to say")

        // Fewer plants and days (an older backup restored): the recorded pots stay owned.
        for p in app.plants() { p.earnedCount = 0 }
        profile.gardenDays = 1
        XCTAssertEqual(app.potState(PotCatalog.pot(id: "sageGlaze")), .owned)
        XCTAssertEqual(app.potState(PotCatalog.pot(id: "dewdrop")), .owned)
        XCTAssertEqual(app.recordEarnedPots(), [])
        XCTAssertEqual(Set(profile.earnedPotIds), ["terracotta", "sageGlaze", "dewdrop"], "nothing earned is removed")
        // A Plus pot is never recorded, so choosing one still needs Plus.
        app.entitlements.debugForce(EntitlementState(activeProductIDs: ["plus_yearly"]))
        XCTAssertEqual(app.recordEarnedPots(), [])
        XCTAssertFalse(profile.earnedPotIds.contains("moonlit"))
    }

    // MARK: Repot sheet v2 (design-preview/repot-sheet)

    func testTheRepotSheetCopy() {
        XCTAssertEqual(PotCatalog.Copy.repotSub, "Pick a pot. Changing pots is free.")
        XCTAssertEqual(PotCatalog.Copy.newTag, "New")
        XCTAssertEqual(PotCatalog.Copy.soilTitle, "Soil")
        XCTAssertEqual(PotCatalog.Copy.soilSub, "Plants have favorite soils.")
        for line in [PotCatalog.Copy.repotSub, PotCatalog.Copy.newTag, PotCatalog.Copy.soilTitle, PotCatalog.Copy.soilSub] {
            XCTAssertTrue(PotCatalog.Copy.all.contains(line), "\(line) is in the copy sweep")
        }
    }

    func testTheSummaryLineNamesThePotAndTheSoil() {
        XCTAssertEqual(PotCatalog.summaryLine(pot: PotCatalog.pot(id: "rosePink"), soil: .loam), "Rose pink pot, fresh loam soil")
        XCTAssertEqual(PotCatalog.summaryLine(pot: PotCatalog.plainBlue, soil: .peaty), "Plain blue pot, fresh peaty soil")
    }

    func testANewPotsTileLabelEndsWithNewAndKeepsTheRest() {
        let rose = PotCatalog.pot(id: "rosePink")
        XCTAssertEqual(PotCatalog.tileLabel(rose, state: .owned, inUse: false, isNew: true), "Rose pink pot, new")
        XCTAssertEqual(PotCatalog.tileLabel(rose, state: .owned, inUse: false), "Rose pink pot")
        XCTAssertEqual(PotCatalog.tileLabel(rose, state: .owned, inUse: true, isNew: true), "Rose pink pot, in use, new")
    }

    func testTheFooterHintGivesTheGoalAndHowFarAlong() {
        let stones = PotCatalog.pot(id: "livingStones")
        let s = stats(plants: 26, levels: 2, inLevel: [3: 6], days: 3)
        let h = PotCatalog.hintLines(stones, state: PotCatalog.state(of: stones, stats: s, hasPlus: false), stats: s)
        XCTAssertEqual(h.title, "Finish level 3 to earn Living stones.")
        XCTAssertEqual(h.detail, "Four more plants to go!")
        let dew = PotCatalog.pot(id: "dewdrop")
        XCTAssertEqual(PotCatalog.hintLines(dew, state: PotCatalog.state(of: dew, stats: s, hasPlus: false), stats: s).title,
                       "Play on 7 days to earn Dewdrop.")
        let moon = PotCatalog.pot(id: "moonlit")
        let p = PotCatalog.hintLines(moon, state: PotCatalog.state(of: moon, stats: s, hasPlus: false), stats: s)
        XCTAssertEqual(p.title, "Moonlit is part of WordFlora Plus.")
        XCTAssertEqual(p.detail, "A grown-up can find Plus in Settings.")
    }

    func testPlusHintPointsToSettings() {
        for pot in PotCatalog.all where pot.unlock == .plus {
            XCTAssertEqual(pot.hint, "Part of WordFlora Plus. A grown-up can find Plus in Settings.")
        }
        XCTAssertEqual(PotCatalog.plusLine(PotCatalog.pot(id: "moonlit")), "Moonlit is part of WordFlora Plus.")
    }
}

import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class SimplerClueTests: XCTestCase {
    struct FakeAI: GardenAI {
        var hint: String?
        func simplerHint(for entry: WordEntry) async -> String? { hint }
        func explain(entry: WordEntry) async -> String? { nil }
    }
    var container: ModelContainer!
    override func setUp() async throws {
        container = try ModelContainer(for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
                                       configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }
    func makeVM(ai: any GardenAI, backed: Bool) -> GameViewModel {
        let e = WordEntry(id: "a", word: "LOTUS", display: "Lotus", hint: "a hint", hint2: nil, fact: "f", level: 1, kind: .vocab, plantId: nil,
                          tags: [], minAge: 6, dailyEligible: true, source: "o", license: "p", reviewedBy: "t")
        let bank = WordBank(schemaVersion: 1, bankVersion: "t", entries: [e], daily: DailyConfig(epoch: "2026-01-01", seed: 1))
        let vm = GameViewModel(modelContext: container.mainContext, bank: bank, seed: 1)
        vm.soundEnabled = false; vm.seedPlantsIfNeeded()
        vm.ai = ai; vm.aiIsModelBacked = backed
        vm.startRound()
        return vm
    }

    func testButtonOnlyOffersWhenAModelBacksIt() {
        XCTAssertFalse(makeVM(ai: FakeAI(hint: "A calm pond flower."), backed: false).canAskSimplerClue)
        XCTAssertTrue(makeVM(ai: FakeAI(hint: "A calm pond flower."), backed: true).canAskSimplerClue)
    }

    func testASafeClueIsShownAndIsFree() async {
        let vm = makeVM(ai: FakeAI(hint: "A calm pond flower that floats."), backed: true)
        let petals = vm.petalsRemaining
        await vm.askSimplerClue()
        XCTAssertEqual(vm.simplerClue, "A calm pond flower that floats.")
        XCTAssertEqual(vm.helpersUsed, 0); XCTAssertEqual(vm.petalsRemaining, petals)
        XCTAssertFalse(vm.canAskSimplerClue)       // one per round
    }

    func testAClueThatLeaksTheAnswerIsNeverShown() async {
        let vm = makeVM(ai: FakeAI(hint: "It is a lotus flower"), backed: true)
        await vm.askSimplerClue()
        XCTAssertNil(vm.simplerClue)
    }

    func testNilFromTheModelLeavesTheGameAlone() async {
        let vm = makeVM(ai: FakeAI(hint: nil), backed: true)
        await vm.askSimplerClue()
        XCTAssertNil(vm.simplerClue); XCTAssertEqual(vm.phase, .playing)
    }

    func testClueResetsWhenANewRoundStarts() async {
        let vm = makeVM(ai: FakeAI(hint: "A calm pond flower."), backed: true)
        await vm.askSimplerClue(); XCTAssertNotNil(vm.simplerClue)
        vm.startRound()
        XCTAssertNil(vm.simplerClue)
    }
}

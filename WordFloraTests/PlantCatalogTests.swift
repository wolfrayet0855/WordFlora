import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class PlantCatalogTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    func testLoadsFiftyPlants() throws {
        XCTAssertEqual(try PlantCatalog.load().count, 50)
    }

    func testTenPlantsPerLevelForFiveLevels() throws {
        let plants = try PlantCatalog.load()
        for level in 1...5 {
            XCTAssertEqual(plants.filter { $0.level == level }.count, 10, "level \(level)")
        }
    }

    func testPlantIdsAreUniqueAndNonEmpty() throws {
        let ids = try PlantCatalog.load().map(\.plantId)
        XCTAssertTrue(ids.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testSeedInsertsAllPlants() throws {
        try PlantCatalog.seedIfNeeded(context: container.mainContext)
        let all = try container.mainContext.fetch(FetchDescriptor<PlantCollectible>())
        XCTAssertEqual(all.count, 50)
    }

    func testSeedTwiceDoesNotDuplicate() throws {
        try PlantCatalog.seedIfNeeded(context: container.mainContext)
        try PlantCatalog.seedIfNeeded(context: container.mainContext)
        let all = try container.mainContext.fetch(FetchDescriptor<PlantCollectible>())
        XCTAssertEqual(all.count, 50)
    }

    func testSeedPreservesEarnedCountAndUpdatesFacts() throws {
        let ctx = container.mainContext
        try PlantCatalog.seedIfNeeded(context: ctx)
        let rose = try ctx.fetch(FetchDescriptor<PlantCollectible>())
            .first { $0.plantId == "rose" }!
        rose.earnedCount = 3
        rose.botanicalFact = "stale"
        try PlantCatalog.seedIfNeeded(context: ctx)
        XCTAssertEqual(rose.earnedCount, 3)
        XCTAssertNotEqual(rose.botanicalFact, "stale")
    }

    func testSeedInsertsOnlyMissingPlants() throws {
        let ctx = container.mainContext
        try PlantCatalog.seedIfNeeded(context: ctx)
        let victim = try ctx.fetch(FetchDescriptor<PlantCollectible>()).first { $0.plantId == "tulip" }!
        ctx.delete(victim)
        try ctx.save()
        try PlantCatalog.seedIfNeeded(context: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<PlantCollectible>()).count, 50)
    }
}

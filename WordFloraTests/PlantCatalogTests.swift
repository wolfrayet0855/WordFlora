import XCTest
import UIKit
import SwiftData
@testable import WordFlora

@MainActor
final class PlantCatalogTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() async throws {
        container = try ModelContainer(
            for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
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

// MARK: name stories (fact card V2)
@MainActor
final class NameStoryCatalogTests: XCTestCase {
    /// Plants reviewed for T-B whose name origin teaches nothing a child can see or is not settled
    /// (see docs/research/name-stories.md). They show the plain "Did you know?" card.
    private let reviewedFallback: Set<String> = ["poppy", "jasmine"]

    func testLoaderReadsTheDaisyStory() throws {
        let daisy = try XCTUnwrap(try PlantCatalog.load().first { $0.plantId == "daisy" })
        let story = try XCTUnwrap(daisy.nameStory)
        XCTAssertEqual(story.origin, "dæges ēage")
        XCTAssertEqual(story.language, "Old English")
        XCTAssertEqual(story.meaning, "day's eye")
        XCTAssertEqual(NameStoryCard.Content(plant: daisy).title, "How Daisy got its name")
    }

    func testEveryPlantHasAStoryOrIsAReviewedFallback() throws {
        let plants = try PlantCatalog.load()
        let ids = Set(plants.map(\.plantId))
        XCTAssertTrue(reviewedFallback.isSubset(of: ids), "unknown fallback ids: \(reviewedFallback.subtracting(ids))")
        XCTAssertLessThanOrEqual(reviewedFallback.count, 5, "the fallback list should stay a handful")
        for plant in plants {
            if reviewedFallback.contains(plant.plantId) {
                XCTAssertNil(plant.nameStory, "\(plant.name) is a reviewed fallback but has a story")
            } else {
                XCTAssertNotNil(plant.nameStory, "\(plant.name) has no name story and is not a reviewed fallback")
            }
        }
    }

    func testEveryStoryFitsTheCard() throws {
        for plant in try PlantCatalog.load() {
            guard let story = plant.nameStory else { continue }
            XCTAssertLessThanOrEqual(story.line.count, 70, "\(plant.name) line")
            XCTAssertLessThanOrEqual(story.funFact.count, 140, "\(plant.name) funFact")
            XCTAssertLessThanOrEqual(story.meaning.count, 24, "\(plant.name) meaning")
            XCTAssertFalse(story.origin.trimmingCharacters(in: .whitespaces).isEmpty, "\(plant.name) origin")
            XCTAssertFalse(story.language.trimmingCharacters(in: .whitespaces).isEmpty, "\(plant.name) language")
            XCTAssertNotEqual(story.language.lowercased(), "named after", "\(plant.name) language must be a real language")
            let symbol = try XCTUnwrap(story.symbol, "\(plant.name) symbol")
            XCTAssertFalse(symbol.isEmpty, "\(plant.name) symbol")
            XCTAssertNotNil(UIImage(systemName: symbol), "\(plant.name) symbol \(symbol) is not an SF Symbol")
        }
    }

    func testEveryStoryStringAndFactIsCopySafe() throws {
        for plant in try PlantCatalog.load() {
            XCTAssertEqual(CopySafety.check(plant.botanicalFact), [], "\(plant.name) botanicalFact")
            guard let s = plant.nameStory else { continue }
            for text in [s.origin, s.language, s.meaning, s.line, s.funFact] {
                XCTAssertEqual(CopySafety.check(text), [], "\(plant.name): \(text)")
            }
        }
    }

    func testEveryCardHasSafeLinesAndAHowTitle() throws {
        for plant in try PlantCatalog.load() {
            let content = NameStoryCard.Content(plant: plant)
            for line in content.lines + [content.more].compactMap({ $0 }) {
                XCTAssertEqual(CopySafety.check(line), [], "\(plant.name): \(line)")
            }
            if plant.nameStory != nil {
                XCTAssertTrue(content.title.hasPrefix("How "), "\(plant.name): \(content.title)")
                XCTAssertNotNil(content.more)
            }
        }
    }

    func testAPlantWithoutAStoryFallsBackToDidYouKnow() throws {
        let poppy = try XCTUnwrap(try PlantCatalog.load().first { $0.plantId == "poppy" })
        XCTAssertNil(poppy.nameStory)
        let content = NameStoryCard.Content(plant: poppy)
        XCTAssertEqual(content.title, "Did you know?")
        XCTAssertEqual(content.lines, [poppy.botanicalFact])
        XCTAssertNil(content.more)
        XCTAssertNil(content.chip)
    }

    func testAMissingStoryFieldDecodesAsNil() throws {
        let json = #"[{"name":"X","botanicalName":"Y","botanicalFact":"Z.","level":1,"imageName":"plant_x"}]"#
        let info = try JSONDecoder().decode([PlantInfo].self, from: Data(json.utf8))
        XCTAssertNil(info[0].nameStory)
    }

    func testStoryLookupByPlantId() {
        XCTAssertEqual(PlantCatalog.nameStory(for: "daisy")?.meaning, "day's eye")
        XCTAssertNil(PlantCatalog.nameStory(for: "poppy"))
        XCTAssertNil(PlantCatalog.nameStory(for: "no_such_plant"))
    }

    func testEveryStoryIsShortSafeAndEasyToRead() throws {
        for plant in try PlantCatalog.load() {
            let content = NameStoryCard.Content(plant: plant)
            let shown = ([content.title] + content.lines + [content.more].compactMap { $0 }).joined(separator: " ")
            XCTAssertEqual(CopySafety.check(shown), [], "\(plant.name): \(shown)")
            guard let story = plant.nameStory else { continue }
            XCTAssertLessThan(story.funFact.split(separator: " ").count, 40, "\(plant.name) fun fact is too long")
            XCTAssertLessThanOrEqual(story.line.split(separator: " ").count, 12, "\(plant.name) first line is too long")
            let grade = ReadingLevel.grade(story.line + " " + story.funFact)
            XCTAssertLessThanOrEqual(grade, 3.9, "\(plant.name) reads at grade \(grade)")
        }
    }

    func testReadingLevelRanksSimpleTextBelowHardText() {
        XCTAssertLessThan(ReadingLevel.grade("The cat sat on a mat. It was a sunny day."), 2)
        XCTAssertGreaterThan(ReadingLevel.grade("Photosynthetic organisms convert electromagnetic radiation into chemical energy through complicated biochemical pathways."), 10)
    }
}

/// Flesch-Kincaid grade with a vowel-group syllable count. Quoted words (the old-language origin word) are skipped.
enum ReadingLevel {
    static func grade(_ text: String) -> Double {
        var plain = text
        while let open = plain.firstIndex(of: "\u{201C}") ?? plain.firstIndex(of: "\""),
              let close = plain[plain.index(after: open)...].firstIndex(where: { $0 == "\u{201D}" || $0 == "\"" }) {
            // The quoted origin word is not English; count it as one plain word and keep any sentence end inside it.
            let inner = plain[plain.index(after: open)..<close]
            plain.replaceSubrange(open...close, with: inner.last.map { ".!?".contains($0) } == true ? "word." : "word")
        }
        let sentences = max(1, plain.split(whereSeparator: { ".!?".contains($0) }).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count)
        let words = plain.split(whereSeparator: { !$0.isLetter && $0 != "'" }).map { $0.lowercased() }
        guard !words.isEmpty else { return 0 }
        let syllables = words.map(syllableCount).reduce(0, +)
        return 0.39 * Double(words.count) / Double(sentences) + 11.8 * Double(syllables) / Double(words.count) - 15.59
    }

    static func syllableCount(_ word: String) -> Int {
        let vowels = Set("aeiouy")
        var count = 0, previousVowel = false
        for ch in word { let v = vowels.contains(ch); if v && !previousVowel { count += 1 }; previousVowel = v }
        if word.hasSuffix("e") && !word.hasSuffix("le") && count > 1 { count -= 1 }
        return max(1, count)
    }
}

import Foundation
import SwiftData

struct PlantInfo: Decodable, Equatable {
    let name: String
    let botanicalName: String
    let botanicalFact: String
    let level: Int
    let imageName: String
    /// How the plant got its name (fact card V2). Missing for plants whose story is not verified yet.
    var nameStory: NameStory? = nil
    /// Botanical traits garden weather reads (`WeatherEngine.effect`). Optional so a plant entry without the key still decodes.
    var traits: [String]? = nil
    var traitSet: Set<String> { Set(traits ?? []) }

    /// Stable identity derived from the asset name ("plant_rose" -> "rose").
    var plantId: String {
        imageName.hasPrefix("plant_") ? String(imageName.dropFirst("plant_".count)) : imageName
    }
}

/// A verified word-origin story: every story is checked against two sources before it ships.
struct NameStory: Decodable, Equatable {
    /// The old word the name grew from, as written in that language ("dæges ēage").
    let origin: String
    /// The language of `origin` ("Old English").
    let language: String
    /// What `origin` means in plain words ("day's eye").
    let meaning: String
    /// The short first line on the card.
    let line: String
    /// One fun fact, under 40 words, at a grade 2-3 reading level.
    let funFact: String
    /// SF Symbol for the origin chip.
    var symbol: String? = nil
}

enum PlantCatalog {
    enum CatalogError: Error { case fileNotFound }

    private static let storiesById: [String: NameStory] = {
        let plants = (try? load()) ?? []
        return Dictionary(plants.compactMap { p in p.nameStory.map { (p.plantId, $0) } }, uniquingKeysWith: { a, _ in a })
    }()

    /// The name story for a plant, or nil when it has none (the card then shows "Did you know?").
    static func nameStory(for plantId: String) -> NameStory? { storiesById[plantId] }

    static func load(bundle: Bundle = .main) throws -> [PlantInfo] {
        guard let url = bundle.url(forResource: "Plants", withExtension: "json") else {
            throw CatalogError.fileNotFound
        }
        return try JSONDecoder().decode([PlantInfo].self, from: Data(contentsOf: url))
    }

    /// Upsert by plantId: inserts missing plants, refreshes catalog text/level,
    /// never touches player progress (earnedCount, growth, etc.).
    @MainActor
    static func seedIfNeeded(context: ModelContext, bundle: Bundle = .main) throws {
        let catalog = try load(bundle: bundle)
        let existing = try context.fetch(FetchDescriptor<PlantCollectible>())
        var byId = Dictionary(existing.map { ($0.plantId, $0) }, uniquingKeysWith: { first, _ in first })
        for info in catalog {
            if let plant = byId[info.plantId] {
                plant.name = info.name
                plant.botanicalName = info.botanicalName
                plant.botanicalFact = info.botanicalFact
                plant.level = info.level
                plant.imageName = info.imageName
            } else {
                let plant = PlantCollectible(
                    name: info.name, botanicalName: info.botanicalName,
                    botanicalFact: info.botanicalFact, level: info.level,
                    imageName: info.imageName, plantId: info.plantId)
                context.insert(plant)
                byId[info.plantId] = plant
            }
        }
        try context.save()
    }
}

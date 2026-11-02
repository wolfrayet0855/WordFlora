import Foundation
import SwiftData

struct PlantInfo: Decodable, Equatable {
    let name: String
    let botanicalName: String
    let botanicalFact: String
    let level: Int
    let imageName: String

    /// Stable identity derived from the asset name ("plant_rose" -> "rose").
    var plantId: String {
        imageName.hasPrefix("plant_") ? String(imageName.dropFirst("plant_".count)) : imageName
    }
}

enum PlantCatalog {
    enum CatalogError: Error { case fileNotFound }

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

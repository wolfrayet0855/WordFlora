struct PlantSeed {
    let name: String
    let botanicalName: String
    let botanicalFact: String
    let level: Int
    let imageName: String
}

enum PlantSeedData {
    static let all: [PlantSeed] = [
        // Level 1 — Easy
        PlantSeed(name: "Dandelion",  botanicalName: "Taraxacum officinale",
                  botanicalFact: "Each dandelion flower head contains up to 200 individual florets and can disperse up to 2,000 seeds.",
                  level: 1, imageName: "plant_dandelion"),
        PlantSeed(name: "Daisy",      botanicalName: "Bellis perennis",
                  botanicalFact: "Daisies close their petals at night and reopen in the morning — a behaviour called nyctinasty.",
                  level: 1, imageName: "plant_daisy"),
        PlantSeed(name: "Clover",     botanicalName: "Trifolium repens",
                  botanicalFact: "Clover roots host nitrogen-fixing bacteria that naturally enrich surrounding soil.",
                  level: 1, imageName: "plant_clover"),
        PlantSeed(name: "Marigold",   botanicalName: "Tagetes erecta",
                  botanicalFact: "Marigolds produce alpha-terthienyl, a compound that repels nematodes and soil pests.",
                  level: 1, imageName: "plant_marigold"),
        PlantSeed(name: "Sunflower",  botanicalName: "Helianthus annuus",
                  botanicalFact: "Young sunflowers track the sun via heliotropism each day, but stop once fully mature.",
                  level: 1, imageName: "plant_sunflower"),

        // Level 2 — Medium
        PlantSeed(name: "Orchid",     botanicalName: "Orchidaceae",
                  botanicalFact: "Orchids form the largest flowering plant family with over 28,000 known species.",
                  level: 2, imageName: "plant_orchid"),
        PlantSeed(name: "Lavender",   botanicalName: "Lavandula angustifolia",
                  botanicalFact: "Lavender can live for up to 30 years and its fragrance intensifies as the plant ages.",
                  level: 2, imageName: "plant_lavender"),
        PlantSeed(name: "Lotus",      botanicalName: "Nelumbo nucifera",
                  botanicalFact: "Lotus seeds can remain viable for over 1,300 years — the longest confirmed seed longevity of any plant.",
                  level: 2, imageName: "plant_lotus"),
        PlantSeed(name: "Jasmine",    botanicalName: "Jasminum officinale",
                  botanicalFact: "Jasmine flowers open only at night, releasing fragrance specifically to attract nocturnal pollinators.",
                  level: 2, imageName: "plant_jasmine"),
        PlantSeed(name: "Snapdragon", botanicalName: "Antirrhinum majus",
                  botanicalFact: "Dried snapdragon seed pods resemble tiny human skulls, giving them the folk name 'dead man's bones'.",
                  level: 2, imageName: "plant_snapdragon"),

        // Level 3 — Hard
        PlantSeed(name: "Venus Flytrap",      botanicalName: "Dionaea muscipula",
                  botanicalFact: "The Venus flytrap requires two separate touches within 20 seconds to close — preventing false triggers from raindrops.",
                  level: 3, imageName: "plant_venus_flytrap"),
        PlantSeed(name: "Baobab",             botanicalName: "Adansonia digitata",
                  botanicalFact: "A mature baobab trunk can store up to 120,000 litres of water to survive prolonged drought.",
                  level: 3, imageName: "plant_baobab"),
        PlantSeed(name: "Corpse Flower",      botanicalName: "Amorphophallus titanum",
                  botanicalFact: "The corpse flower blooms for only 24–48 hours and may take 7–10 years between each bloom.",
                  level: 3, imageName: "plant_corpse_flower"),
        PlantSeed(name: "Welwitschia",        botanicalName: "Welwitschia mirabilis",
                  botanicalFact: "Welwitschia grows only two leaves in its entire lifetime — leaves that survive for over 1,000 years.",
                  level: 3, imageName: "plant_welwitschia"),
        PlantSeed(name: "Dragon Blood Tree", botanicalName: "Dracaena cinnabari",
                  botanicalFact: "The dragon blood tree produces vivid red resin used as dye and medicine for over 2,000 years.",
                  level: 3, imageName: "plant_dragon_blood_tree"),
    ]
}

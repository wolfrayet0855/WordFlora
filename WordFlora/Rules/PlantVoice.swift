import Foundation

/// A little personality for every plant. Each care action answers right away with a specific, warm line
/// (immediate, contingent, positive feedback). Lines never mention absence, need or loss, and nothing
/// here is random in a way that touches rewards: the trait is fixed per plant and the line only varies by day.
enum PlantVoice {
    enum Trait: CaseIterable { case cheerful, sleepy, shy }
    enum Event: CaseIterable { case water, soil, sun, prune, grew }

    static func trait(for plantId: String) -> Trait {
        let h = plantId.unicodeScalars.reduce(UInt32(5381)) { ($0 &* 33) &+ $1.value }
        return Trait.allCases[Int(h % UInt32(Trait.allCases.count))]
    }

    static func lines(trait: Trait, event: Event) -> [String] {
        switch (trait, event) {
        case (.cheerful, .water): return ["Splash! That felt wonderful.", "Wheee! Thank you!", "Cool and fresh, how lovely."]
        case (.cheerful, .soil): return ["Cozy new soil, I love it!", "Ooh, so rich and crumbly!"]
        case (.cheerful, .sun): return ["Sunshine! I could dance.", "Warm rays, yes please!"]
        case (.cheerful, .prune): return ["A neat trim, I feel sharp!", "Snip snip, so tidy!"]
        case (.cheerful, .grew): return ["Look at me, I grew!", "Taller than yesterday!"]
        case (.sleepy, .water): return ["Mmm, a gentle drink.", "Ahh, that is just right."]
        case (.sleepy, .soil): return ["So soft. Time to settle in.", "Mmm, cozy roots."]
        case (.sleepy, .sun): return ["Warm and drowsy, lovely.", "Mmm, sunbeam nap."]
        case (.sleepy, .prune): return ["A tidy trim, thank you.", "Light as a feather now."]
        case (.sleepy, .grew): return ["I stretched a little taller.", "Slowly, happily growing."]
        case (.shy, .water): return ["Oh! Thank you, that was kind.", "A little drink, how thoughtful."]
        case (.shy, .soil): return ["Oh, this is nice soil.", "Thank you for the cozy bed."]
        case (.shy, .sun): return ["The light is so soft today.", "Peeking out to say thanks."]
        case (.shy, .prune): return ["That felt careful, thank you.", "Oh, so gentle."]
        case (.shy, .grew): return ["I think I grew a bit!", "Look, a new little leaf."]
        }
    }

    static func line(plantId: String, event: Event, daySeed: Int) -> String {
        let options = lines(trait: trait(for: plantId), event: event)
        return options[abs(daySeed) % options.count]
    }
}

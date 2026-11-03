import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Optional on-device helpers. Everything here is a convenience layer: the game is fully playable without it,
/// and every model output is validated before a player sees it (spec sections 5, 17, 19).
protocol GardenAI {
    /// A simpler rewording of the clue, or nil if none is available.
    func simplerHint(for entry: WordEntry) async -> String?
    /// A short kid-friendly explanation of the plant/word, or nil.
    func explain(entry: WordEntry) async -> String?
}

/// Works on every device: uses only reviewed bank text.
struct StaticGardenAI: GardenAI {
    func simplerHint(for entry: WordEntry) async -> String? { entry.hint2 }
    func explain(entry: WordEntry) async -> String? { entry.fact }
}

/// Wraps a model-backed AI: any unsafe or empty output falls back to the static text.
struct GuardedGardenAI: GardenAI {
    var primary: any GardenAI
    var fallback: any GardenAI

    func simplerHint(for entry: WordEntry) async -> String? {
        if let h = await primary.simplerHint(for: entry), HintValidator.isSafe(h, answer: entry.word) {
            return h.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return await fallback.simplerHint(for: entry)
    }

    func explain(entry: WordEntry) async -> String? {
        if let m = await primary.explain(entry: entry), ExplainValidator.isSafe(m) {
            return m.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return await fallback.explain(entry: entry)
    }
}

enum GardenAIProvider {
    /// True only when a real on-device model will answer (not the static fallback); drives whether AI buttons appear.
    static func isModelBacked() -> Bool { current() is GuardedGardenAI }

    static func make(foundationAvailable: Bool) -> any GardenAI {
        #if canImport(FoundationModels)
        if foundationAvailable, #available(iOS 26.0, *) {
            return GuardedGardenAI(primary: FoundationGardenAI(), fallback: StaticGardenAI())
        }
        #endif
        return StaticGardenAI()
    }

    /// Picks the on-device model when this device and OS support it.
    static func current() -> any GardenAI {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return make(foundationAvailable: FoundationGardenAI.isAvailable) }
        #endif
        return StaticGardenAI()
    }
}

#if canImport(FoundationModels)
/// Apple Intelligence (on-device only). Prompts contain vetted bank text and never the answer word.
@available(iOS 26.0, *)
struct FoundationGardenAI: GardenAI {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private static let hintInstructions = """
    You rewrite plant word-game clues for children and families. Use simple, friendly words in one or two short sentences. \
    Never write the answer or any part of it. Do not mention eating or tasting plants.
    """
    private static let explainInstructions = """
    You explain plant facts to children and families in two or three short, accurate sentences. Use only the facts you are given. \
    Never suggest eating or tasting plants. Keep a warm, calm tone.
    """

    func simplerHint(for entry: WordEntry) async -> String? {
        let session = LanguageModelSession(instructions: Self.hintInstructions)
        do { return try await session.respond(to: "Rewrite this clue more simply: \(entry.hint)").content } catch { return nil }
    }

    func explain(entry: WordEntry) async -> String? {
        let session = LanguageModelSession(instructions: Self.explainInstructions)
        do { return try await session.respond(to: "Explain this fact simply: \(entry.fact)").content } catch { return nil }
    }
}
#endif

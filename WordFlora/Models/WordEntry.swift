import Foundation

struct WordEntry: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case hero, vocab }

    let id: String
    let word: String          // A-Z only; hero entries may contain single spaces
    let display: String
    let hint: String
    let hint2: String?
    let fact: String
    let level: Int            // 1...5
    let kind: Kind
    let plantId: String?      // hero entries only
    let tags: [String]
    let minAge: Int
    let dailyEligible: Bool
    let source: String
    let license: String
    let reviewedBy: String?

    /// Letters the player has to guess (spaces are pre-revealed).
    var guessableLetters: Set<Character> { Set(word.filter { $0.isLetter }) }
}

struct DailyConfig: Codable, Equatable {
    let epoch: String         // yyyy-MM-dd
    let seed: UInt64
}

struct WordBank: Codable, Equatable {
    let schemaVersion: Int
    let bankVersion: String
    let entries: [WordEntry]
    let daily: DailyConfig

    enum LoadError: Error { case fileNotFound }

    static func load(bundle: Bundle = .main, resource: String = "Words") throws -> WordBank {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw LoadError.fileNotFound
        }
        return try JSONDecoder().decode(WordBank.self, from: Data(contentsOf: url))
    }
}

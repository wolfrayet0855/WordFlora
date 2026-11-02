import Foundation

enum WordBankService {
    struct WordEntry: Decodable {
        let word: String
        let hint: String
    }

    private struct WordBank: Decodable {
        let easy: [WordEntry]
        let medium: [WordEntry]
        let hard: [WordEntry]
    }

    static func words(for difficulty: Difficulty) throws -> [WordEntry] {
        guard let url = Bundle.main.url(forResource: "WordBank", withExtension: "json") else {
            throw WordBankError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        let bank = try JSONDecoder().decode(WordBank.self, from: data)
        switch difficulty {
        case .easy:   return bank.easy
        case .medium: return bank.medium
        case .hard:   return bank.hard
        }
    }

    static func randomQuestion(for difficulty: Difficulty) throws -> TriviaQuestion {
        let entries = try words(for: difficulty)
        guard let entry = entries.randomElement() else {
            throw WordBankError.empty
        }
        return TriviaQuestion(question: entry.hint, answer: entry.word)
    }

    enum WordBankError: Error {
        case fileNotFound, empty
    }
}

import Foundation

struct TriviaQuestion {
    let question: String
    let answer: String  // already uppercased
}

enum Difficulty: String {
    case easy, medium, hard

    init(level: Int) {
        switch level {
        case 1:  self = .easy
        case 2:  self = .medium
        default: self = .hard
        }
    }
}

enum TriviaError: Error {
    case noValidQuestion
}

// MARK: - Response models (private decodables)
private struct TriviaResponse: Decodable {
    let results: [TriviaResult]
}

private struct TriviaResult: Decodable {
    let question: String
    let correctAnswer: String

    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
    }
}
actor TriviaService {
    private let baseURL = "https://opentdb.com/api.php"
    private let maxRetries = 3

    func fetchQuestion(difficulty: Difficulty) async throws -> TriviaQuestion {
        for _ in 0..<maxRetries {
            if let q = try? await fetchFromAPI(difficulty: difficulty) { return q }
        }
        return try WordBankService.randomQuestion(for: difficulty)
    }

    private func fetchFromAPI(difficulty: Difficulty) async throws -> TriviaQuestion {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "amount",     value: "1"),
            URLQueryItem(name: "category",   value: "17"),
            URLQueryItem(name: "difficulty", value: difficulty.rawValue),
            URLQueryItem(name: "type",       value: "multiple"),
            URLQueryItem(name: "encode",     value: "url3986"),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let decoded = try JSONDecoder().decode(TriviaResponse.self, from: data)
        guard let result = decoded.results.first else { throw TriviaError.noValidQuestion }

        let answer   = result.correctAnswer.removingPercentEncoding ?? result.correctAnswer
        let question = result.question.removingPercentEncoding      ?? result.question

        guard TriviaService.isValidAnswer(answer) else { throw TriviaError.noValidQuestion }
        return TriviaQuestion(question: question, answer: answer.uppercased())
    }

    /// Public so it can be unit-tested without an instance.
    nonisolated static func isValidAnswer(_ answer: String) -> Bool {
        !answer.contains(" ") && answer.count <= 18
    }
}

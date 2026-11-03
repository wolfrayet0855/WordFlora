import Foundation

/// Chooses the most natural voice that is already installed (premium, then enhanced, then standard).
/// Pure so it can be tested; ReadAloud feeds it the real voice list.
enum VoicePicker {
    enum Quality: Int { case standard = 100, enhanced = 200, premium = 300 }

    struct Candidate: Equatable {
        var id: String
        var name: String
        var language: String
        var quality: Quality
        var isNovelty = false
        var isPersonal = false
    }

    private static let friendly = ["Samantha", "Ava", "Allison", "Zoe", "Nicky", "Evan", "Karen", "Daniel"]

    static func best(from voices: [Candidate], language: String) -> Candidate? {
        let base = String(language.prefix(2))
        func score(_ v: Candidate) -> Int? {
            guard !v.isNovelty, !v.isPersonal else { return nil }
            var s = v.quality.rawValue
            if v.language == language { s += 50 } else if v.language.hasPrefix(base) { s += 20 } else { return nil }
            if let i = friendly.firstIndex(where: { v.name.hasPrefix($0) }) { s += friendly.count - i }
            return s
        }
        return voices.compactMap { v in score(v).map { (v, $0) } }.max { $0.1 < $1.1 }?.0
    }
}

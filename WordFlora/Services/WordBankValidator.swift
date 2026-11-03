import Foundation

/// Content rules for the word bank (spec section 2). Used by tests and by the
/// remote-update path before a downloaded bank is accepted.
enum WordBankValidator {
    static let vocabLengthBands: [Int: ClosedRange<Int>] = [
        1: 3...5, 2: 5...7, 3: 6...9, 4: 7...11, 5: 8...14
    ]

    static func validate(_ bank: WordBank, knownPlantIds: Set<String>) -> [String] {
        var issues: [String] = []
        var seenIds = Set<String>()
        var heroPlants = Set<String>()

        for e in bank.entries {
            if !seenIds.insert(e.id).inserted { issues.append("\(e.id): duplicate id") }
            if !(1...5).contains(e.level) { issues.append("\(e.id): level \(e.level) out of range") }

            guard e.word.range(of: "^[A-Z]+( [A-Z]+)*$", options: .regularExpression) != nil else {
                issues.append("\(e.id): word '\(e.word)' must be A-Z letters (single spaces only between words)")
                continue
            }
            switch e.kind {
            case .vocab:
                if e.word.contains(" ") { issues.append("\(e.id): vocab word may not contain spaces") }
                if let band = vocabLengthBands[e.level], !band.contains(e.word.count) {
                    issues.append("\(e.id): vocab length \(e.word.count) outside level \(e.level) band \(band)")
                }
                if e.plantId != nil { issues.append("\(e.id): vocab entry must not have a plantId") }
            case .hero:
                if let pid = e.plantId {
                    if !knownPlantIds.contains(pid) { issues.append("\(e.id): unknown plantId '\(pid)'") }
                    if !heroPlants.insert(pid).inserted { issues.append("\(e.id): plantId '\(pid)' used by another hero entry") }
                } else {
                    issues.append("\(e.id): hero entry needs a plantId")
                }
            }

            let hints = [e.hint] + (e.hint2.map { [$0] } ?? [])
            let leakTokens = [e.word.lowercased()] + e.word.lowercased().split(separator: " ").map(String.init).filter { $0.count >= 4 }
            for h in hints {
                let lower = h.lowercased()
                if leakTokens.contains(where: { lower.contains($0) }) { issues.append("\(e.id): hint reveals the answer") }
            }
            if e.hint.trimmingCharacters(in: .whitespaces).isEmpty { issues.append("\(e.id): empty hint") }
            if e.fact.trimmingCharacters(in: .whitespaces).isEmpty { issues.append("\(e.id): empty fact") }
        }
        return issues
    }
}

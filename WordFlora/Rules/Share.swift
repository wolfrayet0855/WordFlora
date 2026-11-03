import Foundation

/// Spoiler-free sharing (spec sections 3, 18): petals as emoji, never letters; a resting round is shared kindly.
enum DailyShare {
    static func text(date: Date, calendar: Calendar, solved: Bool, petalsRemaining: Int, maxPetals: Int, helpers: Int, word: String) -> String {
        let f = DateFormatter()
        f.calendar = calendar; f.timeZone = calendar.timeZone; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "MMM d"
        var lines = ["WordFlora Daily Bloom · \(f.string(from: date))"]
        if solved {
            let n = max(0, min(maxPetals, petalsRemaining))
            lines.append(String(repeating: "🌸", count: n) + String(repeating: "⚪", count: maxPetals - n) + " \(n)/\(maxPetals) petals")
        } else {
            lines.append("🌿 A resting round today")
        }
        if helpers > 0 { lines.append("🌱 \(helpers) helper\(helpers == 1 ? "" : "s")") }
        return lines.joined(separator: "\n")
    }
}

enum PlantShare {
    static func caption(plantName: String, nickname: String) -> String {
        nickname.isEmpty ? "I found a \(plantName) in WordFlora!" : "Meet \(nickname), my \(plantName) in WordFlora!"
    }
}

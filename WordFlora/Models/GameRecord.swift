import SwiftData
import Foundation

@Model
final class GameRecord {
    var date: Date = Date.now
    var wordGuessed: String = ""
    var triviaQuestion: String = ""
    var won: Bool = false
    var petalsRemaining: Int = 0
    var plantEarned: String?
    var level: Int = 1
    var wordId: String = ""
    var isDaily: Bool = false

    init(wordGuessed: String, triviaQuestion: String, won: Bool,
         petalsRemaining: Int, plantEarned: String?, level: Int,
         wordId: String = "", isDaily: Bool = false, date: Date = .now) {
        self.date = date
        self.wordGuessed = wordGuessed
        self.triviaQuestion = triviaQuestion
        self.won = won
        self.petalsRemaining = petalsRemaining
        self.plantEarned = plantEarned
        self.level = level
        self.wordId = wordId
        self.isDaily = isDaily
    }
}

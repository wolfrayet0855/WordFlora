import SwiftData
import Foundation

@Model
final class GameRecord {
    var date: Date
    var wordGuessed: String
    var triviaQuestion: String
    var won: Bool
    var petalsRemaining: Int
    var plantEarned: String?
    var level: Int
    var wordId: String = ""
    var isDaily: Bool = false

    init(wordGuessed: String, triviaQuestion: String, won: Bool,
         petalsRemaining: Int, plantEarned: String?, level: Int,
         wordId: String = "", isDaily: Bool = false) {
        self.date = .now
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

import SwiftUI
import SwiftData
import AVFAudio

@Observable
@MainActor
final class GameViewModel {
    private let modelContext: ModelContext
    private let triviaService = TriviaService()
    private var audioPlayer: AVAudioPlayer?

    // Game state
    private(set) var currentWord: String = ""
    private(set) var triviaQuestion: String = ""
    private(set) var guessedLetters: Set<Character> = []
    private(set) var petalsRemaining: Int = 8
    private(set) var phase: GamePhase = .idle
    private(set) var roseOfJerichoDropped: Bool = false
    private(set) var earnedPlantName: String? = nil

    // Input (two-way bound from view)
    var guessInput: String = ""

    // Player convenience
    private(set) var playerProfile: PlayerProfile?
    var roseOfJerichoCount: Int  { playerProfile?.roseOfJerichoCount ?? 0 }
    var currentLevel: Int        { playerProfile?.currentLevel ?? 1 }
    var plantsEarnedThisLevel: Int { playerProfile?.plantsEarnedThisLevel ?? 0 }

    // Computed display
    var revealedWord: String {
        currentWord.map { guessedLetters.contains($0) ? String($0) : "_" }.joined(separator: " ")
    }
    var isWordComplete: Bool {
        !currentWord.isEmpty && currentWord.allSatisfy { guessedLetters.contains($0) }
    }
    var wrongGuessCount: Int { 8 - petalsRemaining }

    enum GamePhase: Equatable {
        case idle, loading, playing, won, dead, gameOver
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateProfile()
    }

    // MARK: - Public API

    func startNewRound() async {
        phase = .loading
        resetRoundState()
        do {
            let trivia = try await triviaService.fetchQuestion(difficulty: Difficulty(level: currentLevel))
            currentWord = trivia.answer
            triviaQuestion = trivia.question
            phase = .playing
        } catch {
            phase = .idle
        }
    }

    /// Used by tests to inject a word directly (bypasses network).
    func startGame(word: String, question: String) {
        resetRoundState()
        currentWord = word.uppercased()
        triviaQuestion = question
        phase = .playing
    }

    func submitGuess() {
        guard phase == .playing,
              let letter = guessInput.uppercased().first,
              letter.isLetter,
              !guessedLetters.contains(letter) else {
            guessInput = ""
            return
        }
        guessedLetters.insert(letter)
        guessInput = ""

        if currentWord.contains(letter) {
            playSound("correct")
        } else {
            petalsRemaining -= 1
            playSound("incorrect")
        }

        if isWordComplete {
            phase = .won
            finishRound(won: true)
        } else if petalsRemaining == 0 {
            phase = .dead
        }
    }

    func useRoseOfJericho() {
        guard phase == .dead, roseOfJerichoCount > 0 else { return }
        playerProfile?.roseOfJerichoCount -= 1
        petalsRemaining = 4
        phase = .playing
        try? modelContext.save()
    }

    func giveUp() {
        guard phase == .dead else { return }
        phase = .gameOver
        finishRound(won: false)
    }

    func seedPlantsIfNeeded() {
        let descriptor = FetchDescriptor<PlantCollectible>()
        guard (try? modelContext.fetch(descriptor))?.isEmpty == true else { return }
        for seed in PlantSeedData.all {
            modelContext.insert(PlantCollectible(
                name: seed.name,
                botanicalName: seed.botanicalName,
                botanicalFact: seed.botanicalFact,
                level: seed.level,
                imageName: seed.imageName
            ))
        }
        try? modelContext.save()
    }

    // MARK: - Private

    private func resetRoundState() {
        guessedLetters = []
        petalsRemaining = 8
        guessInput = ""
        roseOfJerichoDropped = false
        earnedPlantName = nil
        currentWord = ""
        triviaQuestion = ""
    }

    private func loadOrCreateProfile() {
        let descriptor = FetchDescriptor<PlayerProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            playerProfile = existing
        } else {
            let profile = PlayerProfile()
            modelContext.insert(profile)
            try? modelContext.save()
            playerProfile = profile
        }
    }

    private func finishRound(won: Bool) {
        let plantName: String? = won ? awardPlant() : nil
        earnedPlantName = plantName

        modelContext.insert(GameRecord(
            wordGuessed: currentWord,
            triviaQuestion: triviaQuestion,
            won: won,
            petalsRemaining: petalsRemaining,
            plantEarned: plantName,
            level: currentLevel
        ))
        playerProfile?.gamesPlayed += 1

        // ~15% random Rose of Jericho drop
        if Double.random(in: 0..<1) < 0.15 {
            playerProfile?.roseOfJerichoCount += 1
            roseOfJerichoDropped = true
        }

        try? modelContext.save()
        playSound(won ? "word-guessed" : "word-not-guessed")
    }

    private func awardPlant() -> String? {
        let level = currentLevel
        let descriptor = FetchDescriptor<PlantCollectible>(
            predicate: #Predicate { $0.level == level }
        )
        guard let plants = try? modelContext.fetch(descriptor),
              let plant = plants.randomElement() else { return nil }

        plant.earnedCount += 1
        playerProfile?.plantsEarnedThisLevel += 1

        if (playerProfile?.plantsEarnedThisLevel ?? 0) >= 5 && currentLevel < 3 {
            playerProfile?.currentLevel += 1
            playerProfile?.plantsEarnedThisLevel = 0
        }
        try? modelContext.save()
        return plant.name
    }

    private func playSound(_ name: String) {
        guard let asset = NSDataAsset(name: name),
              let player = try? AVAudioPlayer(data: asset.data) else { return }
        audioPlayer = player
        player.play()
    }
}

import SwiftUI
import SwiftData

/// Round logic for WordFlora v2 (spec sections 2, 3, 18, 19). No network: words come from the bundled bank.
@Observable
@MainActor
final class GameViewModel {
    enum Phase: Equatable { case idle, playing, won, restingOffer, rested }

    private let modelContext: ModelContext
    private let bank: WordBank
    private let economy: Economy
    private let now: () -> Date
    private let calendar: Calendar
    private var rng: SplitMix64
    private let sounds: SoundPlaying
    private var usedRungs: Set<HelpLadder.Rung> = []
    private var reviveUsedThisRound = false
    private var roundId = UUID().uuidString
    private var regularRoundsThisSitting = 0

    var soundEnabled: Bool {
        get { sounds.enabled }
        set { sounds.enabled = newValue }
    }

    // Round state
    private(set) var currentEntry: WordEntry?
    private(set) var guessedLetters: Set<Character> = []
    private(set) var petalsRemaining = 8
    private(set) var phase: Phase = .idle
    private(set) var isDaily = false
    private(set) var extraHint: String?
    private(set) var helpersUsed = 0
    private(set) var revealedAnswer: String?
    private(set) var wrongStreak = 0
    private(set) var isTutorial = false
    private(set) var lastRoundWasLoss = false
    private(set) var missesThisRound = 0
    private(set) var finishedRoundId: String?

    // Round result
    private(set) var earnedPlantName: String?
    private(set) var earnedPlantIsNew = false
    private(set) var leveledUp = false
    private(set) var roseDropped = false
    private(set) var sessionBeat = false

    var guessInput = ""

    private(set) var playerProfile: PlayerProfile?

    var currentWord: String { currentEntry?.word ?? "" }
    var hint: String { currentEntry?.hint ?? "" }
    var factAfterRound: String? { currentEntry?.fact }
    var roseOfJerichoCount: Int { playerProfile?.roseOfJerichoCount ?? 0 }
    var currentLevel: Int { playerProfile?.currentLevel ?? 1 }
    var canWakeUp: Bool { phase == .restingOffer && roseOfJerichoCount > 0 && !reviveUsedThisRound }

    var revealedWord: String {
        currentWord.map { $0 == " " ? " " : (guessedLetters.contains($0) ? String($0) : "_") }.joined(separator: " ")
    }
    var isWordComplete: Bool {
        !currentWord.isEmpty && currentWord.filter { $0.isLetter }.allSatisfy { guessedLetters.contains($0) }
    }
    var petalsAccessibilityLabel: String { "\(petalsRemaining) of \(economy.maxPetals) petals left" }

    init(modelContext: ModelContext, bank: WordBank, economy: Economy = .default,
         now: @escaping () -> Date = { .now }, calendar: Calendar = .current, seed: UInt64 = UInt64.random(in: .min ... .max),
         sounds: SoundPlaying = SoundPlayer.shared) {
        self.sounds = sounds
        self.modelContext = modelContext
        self.bank = bank
        self.economy = economy
        self.now = now
        self.calendar = calendar
        self.rng = SplitMix64(seed: seed)
        loadOrCreateProfile()
    }

    // MARK: - Starting rounds

    /// Regular round from the bank at the chosen level (default: the player's word level).
    func startRound(level: Int? = nil) {
        let lvl = min(level ?? currentLevel, currentLevel)
        let provider = WordProvider(bank: bank)
        let dailyId = DailyBloom(bank: bank, calendar: calendar).wordId(for: now())
        let seen = playerProfile?.seenIds ?? []
        // Keep today's Daily Bloom word fresh for the daily round, but never leave a player without a word.
        guard let e = provider.next(level: lvl, seen: seen, excluding: dailyId, using: &rng)
                ?? provider.next(level: lvl, seen: seen, excluding: nil, using: &rng) else {
            phase = .idle; return
        }
        begin(e, daily: false)
    }

    func startDaily() {
        let daily = DailyBloom(bank: bank, calendar: calendar)
        guard let id = daily.wordId(for: now()), let e = WordProvider(bank: bank).entry(id: id) else { phase = .idle; return }
        begin(e, daily: true)
    }

    /// Direct start (tests, previews).
    func start(entry: WordEntry) { begin(entry, daily: false) }

    /// First-session word: cannot be lost (the flower keeps one petal) and does not count toward ad or session counters.
    func startTutorial(entry: WordEntry) {
        begin(entry, daily: false)
        isTutorial = true
    }

    private func begin(_ e: WordEntry, daily: Bool) {
        currentEntry = e
        isDaily = daily
        guessedLetters = []
        petalsRemaining = economy.maxPetals
        guessInput = ""
        usedRungs = []
        extraHint = nil
        helpersUsed = 0
        revealedAnswer = nil
        wrongStreak = 0
        missesThisRound = 0
        isTutorial = false
        reviveUsedThisRound = false
        earnedPlantName = nil
        earnedPlantIsNew = false
        leveledUp = false
        roseDropped = false
        sessionBeat = false
        roundId = UUID().uuidString
        phase = .playing
    }

    // MARK: - Playing

    func submitGuess() {
        defer { guessInput = "" }
        guard phase == .playing,
              let letter = guessInput.uppercased().first,
              letter.isLetter,
              !guessedLetters.contains(letter) else { return }
        guessedLetters.insert(letter)

        if currentWord.contains(letter) {
            wrongStreak = 0
            sounds.play(.correct)
        } else {
            if !(isTutorial && petalsRemaining <= 1) { petalsRemaining -= 1 }   // tutorial floor: keep going!
            wrongStreak += 1
            missesThisRound += 1
            sounds.play(.wrong)
        }

        if isWordComplete {
            phase = .won
            finishRound(won: true)
        } else if petalsRemaining == 0 {
            if canWakeUpNow { phase = .restingOffer } else { finalizeLoss() }
        }
    }

    /// True while the help ladder still has a rung to offer.
    var canUseHelp: Bool {
        guard phase == .playing, let e = currentEntry else { return false }
        return HelpLadder.next(used: usedRungs, word: e.word, guessed: guessedLetters, hint2: e.hint2) != nil
    }

    enum KeyState: Equatable { case unused, correct, wrong }

    func keyState(for letter: Character) -> KeyState {
        guard guessedLetters.contains(letter) else { return .unused }
        return currentWord.contains(letter) ? .correct : .wrong
    }

    private var canWakeUpNow: Bool { roseOfJerichoCount > 0 && !reviveUsedThisRound }

    func useHelp() {
        guard phase == .playing, let e = currentEntry else { return }
        guard let step = HelpLadder.next(used: usedRungs, word: e.word, guessed: guessedLetters, hint2: e.hint2) else { return }
        switch step {
        case .hint2(let text):
            usedRungs.insert(.hint2); extraHint = text
        case .reveal(let ch):
            if "AEIOU".contains(ch) && !usedRungs.contains(.vowel) { usedRungs.insert(.vowel) } else { usedRungs.insert(.firstLetter) }
            guessedLetters.insert(ch)
        }
        helpersUsed += 1
    }

    // MARK: - Resting (loss)

    /// Wake the flower with a Rose of Jericho (offered before the answer is revealed).
    func wakeUp() {
        guard canWakeUp else { return }
        var meter = roseMeter
        guard meter.consume() else { return }
        writeRoseMeter(meter)
        reviveUsedThisRound = true
        petalsRemaining = 4
        phase = .playing
        try? modelContext.save()
    }

    func declineWake() {
        guard phase == .restingOffer else { return }
        finalizeLoss()
    }

    private func finalizeLoss() {
        phase = .rested
        revealedAnswer = currentWord
        finishRound(won: false)
    }

    // MARK: - Seeding / level

    func seedPlantsIfNeeded() {
        try? PlantCatalog.seedIfNeeded(context: modelContext)
    }

    /// Recompute the word level from the collection (call on appear, after sync, etc.).
    func refreshLevel() {
        guard let profile = playerProfile else { return }
        let plants = allPlants()
        let level = ProgressionPolicy.wordLevel(plants: progress(of: plants), economy: economy)
        profile.currentLevel = level
        profile.plantsEarnedThisLevel = plants.filter { $0.level == level && $0.earnedCount > 0 }.count
    }

    // MARK: - Private: profile and persistence

    private var roseMeter: RoseMeter {
        RoseMeter(progress: playerProfile?.roseSeedProgress ?? 0, stock: roseOfJerichoCount, lastRoundId: playerProfile?.lastRoundId)
    }
    private func writeRoseMeter(_ m: RoseMeter) {
        playerProfile?.roseSeedProgress = m.progress
        playerProfile?.roseOfJerichoCount = m.stock
        playerProfile?.lastRoundId = m.lastRoundId
    }

    private func loadOrCreateProfile() {
        if let existing = try? modelContext.fetch(FetchDescriptor<PlayerProfile>()).first {
            playerProfile = existing
        } else {
            let profile = PlayerProfile()
            modelContext.insert(profile)
            try? modelContext.save()
            playerProfile = profile
        }
    }

    private func allPlants() -> [PlantCollectible] {
        (try? modelContext.fetch(FetchDescriptor<PlantCollectible>())) ?? []
    }
    private func progress(of plants: [PlantCollectible]) -> [PlantProgress] {
        plants.map { PlantProgress(level: $0.level, earned: $0.earnedCount > 0, stage: $0.stage) }
    }

    // MARK: - Private: round end

    private func finishRound(won: Bool) {
        guard let profile = playerProfile, let e = currentEntry else { return }
        let petals = petalsRemaining
        var plantName: String?
        lastRoundWasLoss = !won
        finishedRoundId = roundId

        if won {
            let award = awardPlant(for: e)
            plantName = award?.name
            earnedPlantName = award?.name
            earnedPlantIsNew = award?.isNew ?? false
            if award?.isNew == true { profile.soil += 2 }
            profile.water = min(40, profile.water + waterReward(misses: economy.maxPetals - petals))
            let oldLevel = profile.currentLevel
            refreshLevel()
            leveledUp = profile.currentLevel > oldLevel
        }

        modelContext.insert(GameRecord(wordGuessed: e.word, triviaQuestion: e.hint, won: won,
                                       petalsRemaining: petals, plantEarned: plantName, level: e.level,
                                       wordId: e.id, isDaily: isDaily))
        profile.gamesPlayed += 1
        profile.seenIds = Array((profile.seenIds + [e.id]).suffix(200))

        // Rose meter (win or lose), once per round id
        var meter = roseMeter
        if meter.recordRound(id: roundId, economy: economy) { roseDropped = true }

        // Garden Days + gentle streak
        var state = StreakState(gardenDays: profile.gardenDays, streak: profile.streak, bestStreak: profile.bestStreak,
                                freezes: profile.streakFreezes, lastPlayedDay: profile.lastPlayedDay, lastGraceDay: profile.lastGraceDay)
        let events = state.recordPlay(on: now(), calendar: calendar, economy: economy)
        profile.gardenDays = state.gardenDays; profile.streak = state.streak; profile.bestStreak = state.bestStreak
        profile.streakFreezes = state.freezes; profile.lastPlayedDay = state.lastPlayedDay; profile.lastGraceDay = state.lastGraceDay
        if events.milestoneRose { meter.grant(economy: economy); roseDropped = true }
        writeRoseMeter(meter)

        // Ad cadence counter and session beat (regular rounds only)
        if !isDaily && !isTutorial {
            profile.roundsSinceAd += 1
            regularRoundsThisSitting += 1
        }
        sessionBeat = !isTutorial && (isDaily || (regularRoundsThisSitting > 0 && regularRoundsThisSitting % 3 == 0))

        try? modelContext.save()
        sounds.play(won ? .word : .rest)
    }

    /// One water for a win, +1 for a clean round (<= 2 misses), +1 on the Daily Bloom. Help never reduces it below 1.
    private func waterReward(misses: Int) -> Int {
        1 + (misses <= 2 ? 1 : 0) + (isDaily ? 1 : 0)
    }

    private func awardPlant(for e: WordEntry) -> (name: String, isNew: Bool)? {
        let plants = allPlants()
        let level = playerProfile?.currentLevel ?? 1

        if e.kind == .hero, let pid = e.plantId, let hero = plants.first(where: { $0.plantId == pid }), hero.earnedCount == 0 {
            hero.earnedCount += 1
            return (hero.name, true)
        }
        let inLevel = plants.filter { $0.level == level }
        if let pick = inLevel.filter({ $0.earnedCount == 0 }).randomElement(using: &rng) {
            pick.earnedCount += 1
            return (pick.name, true)
        }
        if e.kind == .hero, let pid = e.plantId, let hero = plants.first(where: { $0.plantId == pid }) {
            hero.earnedCount += 1
            return (hero.name, false)
        }
        if let pick = inLevel.randomElement(using: &rng) {
            pick.earnedCount += 1
            return (pick.name, false)
        }
        return nil
    }
}

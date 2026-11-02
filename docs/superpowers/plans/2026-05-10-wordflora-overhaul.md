# WordFlora Complete Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild WordFlora into a word-guessing plant education game with trivia hints, animated petal flower, collectible plants, level progression, Rose of Jericho power-up, AdMob ads, sharing, and dark/light mode — all on iOS 17+ patterns.

**Architecture:** SwiftData persists three model types (PlayerProfile, PlantCollectible, GameRecord); `@Observable` view models own all game logic; `NavigationStack` + `GameRouter` coordinator owns all navigation. Open Trivia DB (Science: Nature, difficulty matched to level) provides hints, with a bundled WordBank.json fallback. AdMob banner lives in GameView; interstitial fires on level-up.

**Tech Stack:** SwiftUI iOS 17+, SwiftData, `@Observable`, `async/await`, Open Trivia DB API, Google Mobile Ads SDK (SPM), `ShareLink` + `ImageRenderer`, SF Rounded typography, semantic xcassets color tokens.

**Spec:** `docs/superpowers/specs/2026-05-10-wordflora-overhaul-design.md`

---

## File Map

### New Files
| Path | Responsibility |
|---|---|
| `WordFlora/App/GameRouter.swift` | `@Observable` navigation coordinator + `GameRoute` enum |
| `WordFlora/Models/PlayerProfile.swift` | SwiftData model: level, plants earned, Rose of Jericho count, games played |
| `WordFlora/Models/PlantCollectible.swift` | SwiftData model: plant name, botanical data, level, earned count |
| `WordFlora/Models/GameRecord.swift` | SwiftData model: append-only game history |
| `WordFlora/Models/PlantSeedData.swift` | Static array of 15 real plants (3 levels × 5) with botanical facts |
| `WordFlora/Services/TriviaService.swift` | Open Trivia DB `actor`, single-word filter, retry logic, WordBank fallback |
| `WordFlora/Services/WordBankService.swift` | Loads & queries `WordBank.json` fallback words |
| `WordFlora/Services/AdMobService.swift` | `@Observable` AdMob banner + interstitial wrapper |
| `WordFlora/ViewModels/GameViewModel.swift` | `@Observable` full game state: guesses, petals, Rose of Jericho, level-up |
| `WordFlora/ViewModels/GardenViewModel.swift` | `@Observable` garden: fetches plants, drives share card |
| `WordFlora/Views/HomeView.swift` | Title screen, Play + Garden navigation |
| `WordFlora/Views/LevelMapView.swift` | Level tiers, locked/unlocked state |
| `WordFlora/Views/GameView.swift` | Core game screen assembling all components |
| `WordFlora/Views/GardenView.swift` | 2-column plant collection grid |
| `WordFlora/Views/PlantEarnedView.swift` | Full-screen celebration + share |
| `WordFlora/Components/FlowerView.swift` | SwiftUI petal flower, falling-petal + revival animations |
| `WordFlora/Components/PlantCard.swift` | Botanical illustration card, locked/unlocked state |
| `WordFlora/Components/ShareCard.swift` | `ImageRenderer` share card + `Transferable` wrapper |
| `WordFlora/Resources/WordBank.json` | Fallback nature words with hints, 3 difficulty tiers |
| `WordFlora/Extensions/Color+App.swift` | Semantic `Color` static properties mapped to xcassets tokens |
| `WordFloraTests/TriviaServiceTests.swift` | Unit tests for answer filtering + WordBank loading |
| `WordFloraTests/GameViewModelTests.swift` | Unit tests for game logic, Rose of Jericho, level-up |

### Modified Files
| Path | Change |
|---|---|
| `WordFlora/WordFloraApp.swift` | Add SwiftData container, AdMob init, `GameRouter` environment, seed plants on launch |
| `WordFlora/ContentView.swift` | Delete — replaced by `HomeView` |

---

## Before You Start

**Add Google Mobile Ads SDK via Xcode:**
1. File → Add Package Dependencies
2. URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
3. Add `GoogleMobileAds` to the WordFlora target

**Add a Unit Test target:**
1. File → New → Target → Unit Testing Bundle
2. Name: `WordFloraTests`
3. Target to test: `WordFlora`

**Delete `ContentView.swift`** from the project (right-click → Delete → Move to Trash).

---

## Task 1: Semantic Color System

**Files:**
- Create: `WordFlora/Extensions/Color+App.swift`
- Modify: `WordFlora/Assets.xcassets` (add color sets via Xcode)

- [ ] **Step 1: Add color sets in Xcode Asset Catalog**

In Xcode, open `Assets.xcassets`. Add a **New Color Set** for each token below. For each, set "Appearances" to "Any, Dark" and enter the two hex values.

| Asset name | Any (Light) | Dark |
|---|---|---|
| `appBackground` | `#FAF7F0` | `#1A2E1A` |
| `appSurface` | `#FFFFFF` | `#2C3E2C` |
| `appPrimaryText` | `#2C3E2C` | `#D4EDD4` |
| `appAccent` | `#E8A838` | `#F0C060` |
| `appDanger` | `#E85050` | `#FF6B6B` |
| `appSuccess` | `#4CAF50` | `#66BB6A` |

- [ ] **Step 2: Create Color extension**

Create `WordFlora/Extensions/Color+App.swift`:

```swift
import SwiftUI

extension Color {
    static let appBackground  = Color("appBackground")
    static let appSurface     = Color("appSurface")
    static let appPrimaryText = Color("appPrimaryText")
    static let appAccent      = Color("appAccent")
    static let appDanger      = Color("appDanger")
    static let appSuccess     = Color("appSuccess")
}
```

- [ ] **Step 3: Build to verify no asset name typos**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 2: SwiftData Models

**Files:**
- Create: `WordFlora/Models/PlayerProfile.swift`
- Create: `WordFlora/Models/PlantCollectible.swift`
- Create: `WordFlora/Models/GameRecord.swift`

- [ ] **Step 1: Create PlayerProfile**

Create `WordFlora/Models/PlayerProfile.swift`:

```swift
import SwiftData

@Model
final class PlayerProfile {
    var currentLevel: Int
    var plantsEarnedThisLevel: Int
    var roseOfJerichoCount: Int
    var gamesPlayed: Int

    init() {
        currentLevel = 1
        plantsEarnedThisLevel = 0
        roseOfJerichoCount = 0
        gamesPlayed = 0
    }
}
```

- [ ] **Step 2: Create PlantCollectible**

Create `WordFlora/Models/PlantCollectible.swift`:

```swift
import SwiftData

@Model
final class PlantCollectible {
    var name: String
    var botanicalName: String
    var botanicalFact: String
    var level: Int
    var earnedCount: Int
    var imageName: String

    init(name: String, botanicalName: String, botanicalFact: String, level: Int, imageName: String) {
        self.name = name
        self.botanicalName = botanicalName
        self.botanicalFact = botanicalFact
        self.level = level
        self.earnedCount = 0
        self.imageName = imageName
    }
}
```

- [ ] **Step 3: Create GameRecord**

Create `WordFlora/Models/GameRecord.swift`:

```swift
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

    init(wordGuessed: String, triviaQuestion: String, won: Bool,
         petalsRemaining: Int, plantEarned: String?, level: Int) {
        self.date = .now
        self.wordGuessed = wordGuessed
        self.triviaQuestion = triviaQuestion
        self.won = won
        self.petalsRemaining = petalsRemaining
        self.plantEarned = plantEarned
        self.level = level
    }
}
```

- [ ] **Step 4: Build to verify models compile**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 3: Plant Seed Data & WordBank Fallback

**Files:**
- Create: `WordFlora/Models/PlantSeedData.swift`
- Create: `WordFlora/Resources/WordBank.json`
- Create: `WordFlora/Services/WordBankService.swift`

- [ ] **Step 1: Create PlantSeedData**

Create `WordFlora/Models/PlantSeedData.swift`:

```swift
struct PlantSeed {
    let name: String
    let botanicalName: String
    let botanicalFact: String
    let level: Int
    let imageName: String
}

enum PlantSeedData {
    static let all: [PlantSeed] = [
        // Level 1 — Easy
        PlantSeed(name: "Dandelion",  botanicalName: "Taraxacum officinale",
                  botanicalFact: "Each dandelion flower head contains up to 200 individual florets and can disperse up to 2,000 seeds.",
                  level: 1, imageName: "plant_dandelion"),
        PlantSeed(name: "Daisy",      botanicalName: "Bellis perennis",
                  botanicalFact: "Daisies close their petals at night and reopen in the morning — a behaviour called nyctinasty.",
                  level: 1, imageName: "plant_daisy"),
        PlantSeed(name: "Clover",     botanicalName: "Trifolium repens",
                  botanicalFact: "Clover roots host nitrogen-fixing bacteria that naturally enrich surrounding soil.",
                  level: 1, imageName: "plant_clover"),
        PlantSeed(name: "Marigold",   botanicalName: "Tagetes erecta",
                  botanicalFact: "Marigolds produce alpha-terthienyl, a compound that repels nematodes and soil pests.",
                  level: 1, imageName: "plant_marigold"),
        PlantSeed(name: "Sunflower",  botanicalName: "Helianthus annuus",
                  botanicalFact: "Young sunflowers track the sun via heliotropism each day, but stop once fully mature.",
                  level: 1, imageName: "plant_sunflower"),

        // Level 2 — Medium
        PlantSeed(name: "Orchid",     botanicalName: "Orchidaceae",
                  botanicalFact: "Orchids form the largest flowering plant family with over 28,000 known species.",
                  level: 2, imageName: "plant_orchid"),
        PlantSeed(name: "Lavender",   botanicalName: "Lavandula angustifolia",
                  botanicalFact: "Lavender can live for up to 30 years and its fragrance intensifies as the plant ages.",
                  level: 2, imageName: "plant_lavender"),
        PlantSeed(name: "Lotus",      botanicalName: "Nelumbo nucifera",
                  botanicalFact: "Lotus seeds can remain viable for over 1,300 years — the longest confirmed seed longevity of any plant.",
                  level: 2, imageName: "plant_lotus"),
        PlantSeed(name: "Jasmine",    botanicalName: "Jasminum officinale",
                  botanicalFact: "Jasmine flowers open only at night, releasing fragrance specifically to attract nocturnal pollinators.",
                  level: 2, imageName: "plant_jasmine"),
        PlantSeed(name: "Snapdragon", botanicalName: "Antirrhinum majus",
                  botanicalFact: "Dried snapdragon seed pods resemble tiny human skulls, giving them the folk name 'dead man's bones'.",
                  level: 2, imageName: "plant_snapdragon"),

        // Level 3 — Hard
        PlantSeed(name: "Venus Flytrap",      botanicalName: "Dionaea muscipula",
                  botanicalFact: "The Venus flytrap requires two separate touches within 20 seconds to close — preventing false triggers from raindrops.",
                  level: 3, imageName: "plant_venus_flytrap"),
        PlantSeed(name: "Baobab",             botanicalName: "Adansonia digitata",
                  botanicalFact: "A mature baobab trunk can store up to 120,000 litres of water to survive prolonged drought.",
                  level: 3, imageName: "plant_baobab"),
        PlantSeed(name: "Corpse Flower",      botanicalName: "Amorphophallus titanum",
                  botanicalFact: "The corpse flower blooms for only 24–48 hours and may take 7–10 years between each bloom.",
                  level: 3, imageName: "plant_corpse_flower"),
        PlantSeed(name: "Welwitschia",        botanicalName: "Welwitschia mirabilis",
                  botanicalFact: "Welwitschia grows only two leaves in its entire lifetime — leaves that survive for over 1,000 years.",
                  level: 3, imageName: "plant_welwitschia"),
        PlantSeed(name: "Dragon Blood Tree", botanicalName: "Dracaena cinnabari",
                  botanicalFact: "The dragon blood tree produces vivid red resin used as dye and medicine for over 2,000 years.",
                  level: 3, imageName: "plant_dragon_blood_tree"),
    ]
}
```

- [ ] **Step 2: Create WordBank.json**

Create `WordFlora/Resources/WordBank.json` and add it to the Xcode target (right-click Resources group → Add Files):

```json
{
  "easy": [
    {"word": "DAISY",    "hint": "A small white flower common in lawns and meadows worldwide"},
    {"word": "CLOVER",   "hint": "A three-leafed plant associated with good luck"},
    {"word": "FERN",     "hint": "An ancient plant that reproduces via spores rather than seeds"},
    {"word": "MOSS",     "hint": "A soft, low-growing plant that thrives in damp environments"},
    {"word": "TULIP",    "hint": "A spring bulb flower native to Central Asia"},
    {"word": "MAPLE",    "hint": "A tree known for its lobed leaves and the syrup tapped from its sap"},
    {"word": "PINE",     "hint": "An evergreen conifer that produces woody cones"},
    {"word": "LEAF",     "hint": "The primary photosynthetic organ of most vascular plants"},
    {"word": "STEM",     "hint": "The structural axis of a plant that supports leaves and flowers"},
    {"word": "ROOT",     "hint": "The underground organ that anchors a plant and absorbs water"}
  ],
  "medium": [
    {"word": "ORCHID",   "hint": "A vast flowering plant family with over 28,000 known species"},
    {"word": "CACTUS",   "hint": "A succulent plant adapted to arid desert environments"},
    {"word": "BAMBOO",   "hint": "The fastest-growing woody plant on Earth"},
    {"word": "WILLOW",   "hint": "A tree with long drooping branches typically found near water"},
    {"word": "BONSAI",   "hint": "The Japanese art of cultivating miniaturised trees in containers"},
    {"word": "NECTAR",   "hint": "The sweet fluid produced by flowers to attract pollinating animals"},
    {"word": "POLLEN",   "hint": "Fine powder produced by flowering plants for reproduction"},
    {"word": "LICHEN",   "hint": "A composite organism formed by a symbiotic fungus and algae"},
    {"word": "MANGROVE", "hint": "A coastal tree uniquely adapted to grow in saltwater tidal zones"},
    {"word": "SPORE",    "hint": "A single-cell reproductive unit used by ferns, mosses, and fungi"}
  ],
  "hard": [
    {"word": "PHOTOSYNTHESIS", "hint": "The process by which plants convert sunlight and carbon dioxide into food"},
    {"word": "CHLOROPHYLL",    "hint": "The green pigment inside chloroplasts that captures light energy"},
    {"word": "TRANSPIRATION",  "hint": "The process by which plants lose water vapour through tiny leaf pores"},
    {"word": "GERMINATION",    "hint": "The biological process by which a dormant seed begins to sprout"},
    {"word": "POLLINATION",    "hint": "The transfer of pollen grains from anther to stigma for fertilisation"},
    {"word": "DECIDUOUS",      "hint": "Describes a tree or shrub that sheds all its leaves seasonally"},
    {"word": "PERENNIAL",      "hint": "A plant that completes its life cycle over more than two years"},
    {"word": "CARNIVOROUS",    "hint": "Describes a plant that supplements nutrients by trapping and digesting insects"},
    {"word": "SYMBIOSIS",      "hint": "A long-term close interaction between two different biological species"},
    {"word": "MYCORRHIZAE",    "hint": "Fungal networks that form nutrient-sharing partnerships with plant roots"}
  ]
}
```

- [ ] **Step 3: Create WordBankService**

Create `WordFlora/Services/WordBankService.swift`:

```swift
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
```

- [ ] **Step 4: Write failing test**

In `WordFloraTests/TriviaServiceTests.swift`:

```swift
import XCTest
@testable import WordFlora

final class TriviaServiceTests: XCTestCase {

    func testWordBankLoadsEasyWords() throws {
        let words = try WordBankService.words(for: .easy)
        XCTAssertFalse(words.isEmpty)
    }

    func testWordBankWordsAreAllSingleWords() throws {
        for difficulty in [Difficulty.easy, .medium, .hard] {
            let words = try WordBankService.words(for: difficulty)
            for entry in words {
                XCTAssertFalse(entry.word.contains(" "),
                    "\(entry.word) contains a space in \(difficulty) word bank")
            }
        }
    }

    func testIsValidAnswerRejectsSingleSpacedPhrase() {
        XCTAssertFalse(TriviaService.isValidAnswer("Carbon Dioxide"))
    }

    func testIsValidAnswerRejectsTooLongWord() {
        XCTAssertFalse(TriviaService.isValidAnswer("Abcdefghijklmnopqrs")) // 19 chars
    }

    func testIsValidAnswerAcceptsShortSingleWord() {
        XCTAssertTrue(TriviaService.isValidAnswer("Photosynthesis")) // 14 chars
    }
}
```

- [ ] **Step 5: Run test — expect failure on `TriviaService` symbols**

```bash
xcodebuild test -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing 'WordFloraTests/TriviaServiceTests' \
  2>&1 | grep -E "(error:|passed|failed)" | tail -10
```

Expected: Compile error — `TriviaService` not yet defined.

---

## Task 4: TriviaService

**Files:**
- Create: `WordFlora/Services/TriviaService.swift`

- [ ] **Step 1: Define shared types**

Create `WordFlora/Services/TriviaService.swift`:

```swift
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
```

- [ ] **Step 2: Implement TriviaService actor**

Append to `WordFlora/Services/TriviaService.swift`:

```swift
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
```

- [ ] **Step 3: Run TriviaServiceTests — all should pass**

```bash
xcodebuild test -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing 'WordFloraTests/TriviaServiceTests' \
  2>&1 | grep -E "(passed|failed|error:)" | tail -5
```

Expected: `Test Suite 'TriviaServiceTests' passed`

---

## Task 5: GameViewModel

**Files:**
- Create: `WordFlora/ViewModels/GameViewModel.swift`
- Create: `WordFloraTests/GameViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

Create `WordFloraTests/GameViewModelTests.swift`:

```swift
import XCTest
import SwiftData
@testable import WordFlora

@MainActor
final class GameViewModelTests: XCTestCase {
    var sut: GameViewModel!
    var container: ModelContainer!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: PlayerProfile.self, PlantCollectible.self, GameRecord.self,
            configurations: config
        )
        sut = GameViewModel(modelContext: container.mainContext)
        sut.seedPlantsIfNeeded()
    }

    override func tearDown() async throws { sut = nil; container = nil }

    func testInitialPetalsEight() {
        XCTAssertEqual(sut.petalsRemaining, 8)
    }

    func testWrongGuessDecrementsPetals() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.guessInput = "Z"
        sut.submitGuess()
        XCTAssertEqual(sut.petalsRemaining, 7)
    }

    func testCorrectGuessKeepsPetals() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.guessInput = "L"
        sut.submitGuess()
        XCTAssertEqual(sut.petalsRemaining, 8)
    }

    func testDuplicateGuessIgnored() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.guessInput = "Z"
        sut.submitGuess()
        sut.guessInput = "Z"
        sut.submitGuess()
        XCTAssertEqual(sut.petalsRemaining, 7) // only decremented once
    }

    func testWordCompleteOnAllLettersGuessed() {
        sut.startGame(word: "LOTUS", question: "Hint")
        for ch in "LOTUS" {
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertTrue(sut.isWordComplete)
        XCTAssertEqual(sut.phase, .won)
    }

    func testZeroPetalsSetsDead() {
        sut.startGame(word: "LOTUS", question: "Hint")
        for ch in "ABCDEFGH" {
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertEqual(sut.phase, .dead)
    }

    func testRoseOfJerichoRestoresFourPetals() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.playerProfile?.roseOfJerichoCount = 1
        sut.petalsRemaining = 0
        sut.phase = .dead
        sut.useRoseOfJericho()
        XCTAssertEqual(sut.petalsRemaining, 4)
        XCTAssertEqual(sut.playerProfile?.roseOfJerichoCount, 0)
        XCTAssertEqual(sut.phase, .playing)
    }

    func testRoseOfJerichoNoOpWhenNotDead() {
        sut.startGame(word: "LOTUS", question: "Hint")
        sut.playerProfile?.roseOfJerichoCount = 1
        sut.useRoseOfJericho() // phase is .playing, not .dead
        XCTAssertEqual(sut.playerProfile?.roseOfJerichoCount, 1) // unchanged
    }

    func testLevelAdvancesAfterFivePlantsEarned() {
        sut.playerProfile?.plantsEarnedThisLevel = 4
        sut.playerProfile?.currentLevel = 1
        // Award a 5th plant by calling the internal helper through a win
        sut.startGame(word: "LOTUS", question: "Hint")
        for ch in "LOTUS" {
            sut.guessInput = String(ch)
            sut.submitGuess()
        }
        XCTAssertEqual(sut.playerProfile?.currentLevel, 2)
        XCTAssertEqual(sut.playerProfile?.plantsEarnedThisLevel, 0)
    }
}
```

- [ ] **Step 2: Run — expect compile error**

```bash
xcodebuild test -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing 'WordFloraTests/GameViewModelTests' \
  2>&1 | grep -E "(error:|passed|failed)" | tail -5
```

Expected: Compile error — `GameViewModel` not found.

- [ ] **Step 3: Create GameViewModel**

Create `WordFlora/ViewModels/GameViewModel.swift`:

```swift
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
```

- [ ] **Step 4: Run GameViewModelTests — all should pass**

```bash
xcodebuild test -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing 'WordFloraTests/GameViewModelTests' \
  2>&1 | grep -E "(passed|failed|error:)" | tail -5
```

Expected: `Test Suite 'GameViewModelTests' passed`

---

## Task 6: FlowerView Component

**Files:**
- Create: `WordFlora/Components/FlowerView.swift`

- [ ] **Step 1: Create FlowerView**

Create `WordFlora/Components/FlowerView.swift`:

```swift
import SwiftUI

struct FlowerView: View {
    let petalsRemaining: Int   // 0–8

    @State private var offsets:   [CGSize] = Array(repeating: .zero, count: 8)
    @State private var opacities: [Double] = Array(repeating: 1.0,   count: 8)

    var body: some View {
        ZStack {
            stemView
            ForEach(0..<8, id: \.self) { i in
                petalView(index: i)
            }
            centerView
        }
        .frame(width: 200, height: 240)
        .onChange(of: petalsRemaining) { old, new in
            if new < old {
                dropPetal(at: new)        // petal at index `new` just fell
            } else if new > old {
                reviveFrom(count: new)    // Rose of Jericho revival
            } else if new == 8 {
                resetAll()               // new game
            }
        }
        .onAppear { resetAll() }
    }

    // MARK: - Sub-views

    private var stemView: some View {
        Capsule()
            .fill(Color.appSuccess)
            .frame(width: 8, height: 70)
            .offset(y: 90)
            .rotationEffect(.degrees(petalsRemaining == 0 ? 18 : 0))
            .animation(.easeInOut(duration: 0.6), value: petalsRemaining)
    }

    private var centerView: some View {
        Circle()
            .fill(petalsRemaining > 0 ? Color.appAccent : Color.gray.opacity(0.4))
            .frame(width: 42, height: 42)
            .shadow(radius: petalsRemaining > 0 ? 4 : 0)
            .animation(.easeInOut, value: petalsRemaining)
    }

    private func petalView(index: Int) -> some View {
        let angle = Double(index) * 45.0   // 360/8
        let visible = index < petalsRemaining || opacities[index] > 0

        return Group {
            if visible {
                Ellipse()
                    .fill(petalColor)
                    .frame(width: 28, height: 52)
                    .offset(y: -52)
                    .rotationEffect(.degrees(angle))
                    .offset(offsets[index])
                    .opacity(opacities[index])
            }
        }
    }

    private var petalColor: Color {
        let ratio = Double(petalsRemaining) / 8.0
        if ratio > 0.62 { return .pink }
        if ratio > 0.37 { return .orange }
        return Color.appDanger
    }

    // MARK: - Animations

    private func dropPetal(at index: Int) {
        guard index < 8 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            offsets[index] = CGSize(
                width:  CGFloat.random(in: -70...70),
                height: CGFloat.random(in: 90...150)
            )
        }
        withAnimation(.easeOut(duration: 0.75)) {
            opacities[index] = 0
        }
    }

    private func reviveFrom(count: Int) {
        for i in 0..<count {
            let delay = Double(i) * 0.08
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(delay)) {
                offsets[i]   = .zero
                opacities[i] = 1.0
            }
        }
    }

    private func resetAll() {
        offsets   = Array(repeating: .zero, count: 8)
        opacities = Array(repeating: 1.0,   count: 8)
    }
}

#Preview {
    VStack(spacing: 30) {
        FlowerView(petalsRemaining: 8)
        FlowerView(petalsRemaining: 4)
        FlowerView(petalsRemaining: 0)
    }
    .padding()
    .background(Color.appBackground)
}
```

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 7: PlantCard & ShareCard Components

**Files:**
- Create: `WordFlora/Components/PlantCard.swift`
- Create: `WordFlora/Components/ShareCard.swift`

- [ ] **Step 1: Create PlantCard**

Create `WordFlora/Components/PlantCard.swift`:

```swift
import SwiftUI

struct PlantCard: View {
    let plant: PlantCollectible
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            plantImage
                .frame(height: compact ? 60 : 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(plant.name)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center)

            Text(plant.botanicalName)
                .font(.system(.caption, design: .rounded))
                .italic()
                .foregroundStyle(Color.appPrimaryText.opacity(0.6))

            if !compact {
                Text(plant.botanicalFact)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Color.appPrimaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }

            if plant.earnedCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                    Text("×\(plant.earnedCount)")
                }
                .font(.caption.bold())
                .foregroundStyle(Color.appSuccess)
            }
        }
        .padding(compact ? 8 : 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(plant.earnedCount > 0 ? Color.appAccent.opacity(0.4) : Color.gray.opacity(0.2),
                        lineWidth: 1)
        )
        .opacity(plant.earnedCount == 0 ? 0.45 : 1.0)
    }

    @ViewBuilder
    private var plantImage: some View {
        if UIImage(named: plant.imageName) != nil {
            Image(plant.imageName)
                .resizable()
                .scaledToFit()
        } else {
            // Fallback SF Symbol per plant type
            Image(systemName: plantSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.appSuccess)
        }
    }

    private var plantSymbol: String {
        switch plant.level {
        case 1: return "leaf.fill"
        case 2: return "flower.fill"
        default: return "leaf.arrow.circlepath"
        }
    }
}
```

- [ ] **Step 2: Create ShareCard**

Create `WordFlora/Components/ShareCard.swift`:

```swift
import SwiftUI

// The renderable card view
struct ShareCardView: View {
    let plant: PlantCollectible
    let level: Int
    let wordsGuessed: Int

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .foregroundStyle(Color.appSuccess)
                Text("WordFlora")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.appPrimaryText)
            }

            if UIImage(named: plant.imageName) != nil {
                Image(plant.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .foregroundStyle(Color.appSuccess)
            }

            Text(plant.name)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.appPrimaryText)

            Text(plant.botanicalFact)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.appPrimaryText.opacity(0.8))
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Label("Level \(level)", systemImage: "star.fill")
                Label("\(wordsGuessed) guessed", systemImage: "checkmark.circle.fill")
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(Color.appAccent)
        }
        .padding(20)
        .frame(width: 300)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// Transferable wrapper so ShareLink can export as PNG
struct ShareableImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { s in
            s.image.pngData() ?? Data()
        }
    }
}

// Factory: renders card to UIImage
@MainActor
func makeShareCard(plant: PlantCollectible, level: Int, wordsGuessed: Int) -> ShareableImage? {
    let view = ShareCardView(plant: plant, level: level, wordsGuessed: wordsGuessed)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0
    guard let uiImage = renderer.uiImage else { return nil }
    return ShareableImage(image: uiImage)
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 8: GardenViewModel & GardenView

**Files:**
- Create: `WordFlora/ViewModels/GardenViewModel.swift`
- Create: `WordFlora/Views/GardenView.swift`

- [ ] **Step 1: Create GardenViewModel**

Create `WordFlora/ViewModels/GardenViewModel.swift`:

```swift
import SwiftData

@Observable
@MainActor
final class GardenViewModel {
    private let modelContext: ModelContext
    private(set) var plants: [PlantCollectible] = []
    private(set) var totalEarned: Int = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadPlants() {
        let descriptor = FetchDescriptor<PlantCollectible>(
            sortBy: [SortDescriptor(\.level), SortDescriptor(\.name)]
        )
        plants = (try? modelContext.fetch(descriptor)) ?? []
        totalEarned = plants.filter { $0.earnedCount > 0 }.count
    }
}
```

- [ ] **Step 2: Create GardenView**

Create `WordFlora/Views/GardenView.swift`:

```swift
import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GameRouter.self)  private var router
    @State private var viewModel: GardenViewModel?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vm.plants, id: \.name) { plant in
                            plantCardWithShare(plant: plant, vm: vm)
                        }
                    }
                    .padding()
                }
                .navigationTitle("My Garden (\(vm.totalEarned)/\(PlantSeedData.all.count))")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = GardenViewModel(modelContext: modelContext)
            }
            viewModel?.loadPlants()
        }
    }

    @ViewBuilder
    private func plantCardWithShare(plant: PlantCollectible, vm: GardenViewModel) -> some View {
        VStack {
            PlantCard(plant: plant)
            if plant.earnedCount > 0,
               let card = makeShareCard(plant: plant,
                                        level: vm.plants.first?.level ?? 1,
                                        wordsGuessed: vm.totalEarned) {
                ShareLink(
                    item: card,
                    preview: SharePreview("My \(plant.name) in WordFlora!",
                                         image: Image(uiImage: card.image))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption.bold())
                        .foregroundStyle(Color.appAccent)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 9: LevelMapView & PlantEarnedView

**Files:**
- Create: `WordFlora/Views/LevelMapView.swift`
- Create: `WordFlora/Views/PlantEarnedView.swift`

- [ ] **Step 1: Create LevelMapView**

Create `WordFlora/Views/LevelMapView.swift`:

```swift
import SwiftUI

struct LevelMapView: View {
    @Environment(GameRouter.self) private var router
    let currentLevel: Int
    let plantsEarnedThisLevel: Int
    let plantsNeeded: Int = 5

    private let levelInfo: [(title: String, subtitle: String, plants: [String])] = [
        ("Level 1", "Easy — Science: Nature",  ["Dandelion", "Daisy", "Clover", "Marigold", "Sunflower"]),
        ("Level 2", "Medium — Science: Nature", ["Orchid", "Lavender", "Lotus", "Jasmine", "Snapdragon"]),
        ("Level 3", "Hard — Science: Nature",   ["Venus Flytrap", "Baobab", "Corpse Flower", "Welwitschia", "Dragon Blood Tree"]),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { lvl in
                        levelCard(lvl)
                    }
                }
                .padding()
            }
            .navigationTitle("Level Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func levelCard(_ lvl: Int) -> some View {
        let info    = levelInfo[lvl - 1]
        let unlocked = lvl <= currentLevel
        let isCurrent = lvl == currentLevel

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text(info.subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: unlocked ? "checkmark.seal.fill" : "lock.fill")
                    .foregroundStyle(unlocked ? Color.appSuccess : Color.gray)
            }

            if isCurrent {
                ProgressView(value: Double(plantsEarnedThisLevel),
                             total: Double(plantsNeeded))
                    .tint(Color.appAccent)
                Text("\(plantsEarnedThisLevel)/\(plantsNeeded) plants earned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Plant name chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(info.plants, id: \.self) { name in
                        Text(name)
                            .font(.system(.caption2, design: .rounded))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(unlocked ? Color.appSuccess.opacity(0.15) : Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundStyle(unlocked ? Color.appSuccess : Color.gray)
                            .opacity(unlocked ? 1.0 : 0.5)
                    }
                }
            }
        }
        .padding()
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(unlocked ? 1.0 : 0.65)
    }
}
```

- [ ] **Step 2: Create PlantEarnedView**

Create `WordFlora/Views/PlantEarnedView.swift`:

```swift
import SwiftUI

struct PlantEarnedView: View {
    @Environment(GameRouter.self) private var router
    let plant: PlantCollectible
    let level: Int
    let wordsGuessed: Int

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Text("New Plant Earned!")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.appPrimaryText)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                PlantCard(plant: plant)
                    .frame(maxWidth: 260)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)

                if let card = makeShareCard(plant: plant, level: level, wordsGuessed: wordsGuessed) {
                    ShareLink(
                        item: card,
                        preview: SharePreview(
                            "I just earned a \(plant.name) in WordFlora!",
                            image: Image(uiImage: card.image)
                        )
                    ) {
                        Label("Share with Friends", systemImage: "square.and.arrow.up")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.appAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                }

                Button("Keep Playing") {
                    router.navigateToRoot()
                }
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.appAccent)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 10: HomeView

**Files:**
- Create: `WordFlora/Views/HomeView.swift`

- [ ] **Step 1: Create HomeView**

Create `WordFlora/Views/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    @Environment(GameRouter.self) private var router

    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Text("WordFlora")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appPrimaryText)

                    Text("Guess words. Grow a garden.")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(Color.appAccent)
                }

                FlowerView(petalsRemaining: pulse ? 6 : 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        router.navigate(to: .game)
                    } label: {
                        Text("Play")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        router.navigate(to: .garden)
                    } label: {
                        HStack {
                            Image(systemName: "leaf.fill")
                            Text("My Garden")
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.appSuccess)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSuccess.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        router.navigate(to: .levelMap)
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Level Map")
                        }
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 11: AdMobService

**Files:**
- Create: `WordFlora/Services/AdMobService.swift`

> **Note:** Replace the test ad unit IDs below with your real AdMob IDs before App Store submission. Test IDs only show test ads.

- [ ] **Step 1: Add GADApplicationIdentifier to Info.plist**

Open `WordFlora/Info.plist`. Add:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

(This is the AdMob test app ID. Replace with your real app ID for production.)

- [ ] **Step 2: Create AdMobService**

Create `WordFlora/Services/AdMobService.swift`:

```swift
import SwiftUI
import GoogleMobileAds

// MARK: - Banner View (UIViewRepresentable)
struct AdBannerView: UIViewRepresentable {
    // Test banner unit ID — replace before shipping
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// MARK: - Interstitial Service
@Observable
@MainActor
final class AdMobService: NSObject, GADFullScreenContentDelegate {
    // Test interstitial unit ID — replace before shipping
    private let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    private var interstitial: GADInterstitialAd?
    private(set) var isReady = false

    func preload() async {
        do {
            interstitial = try await GADInterstitialAd.load(
                withAdUnitID: interstitialUnitID,
                request: GADRequest()
            )
            interstitial?.fullScreenContentDelegate = self
            isReady = true
        } catch {
            isReady = false
        }
    }

    func present() {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }
        interstitial?.present(fromRootViewController: rootVC)
        isReady = false
    }

    // MARK: - GADFullScreenContentDelegate
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            await self.preload()
        }
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 12: GameView (Full Assembly)

**Files:**
- Create: `WordFlora/Views/GameView.swift`

- [ ] **Step 1: Create GameView**

Create `WordFlora/Views/GameView.swift`:

```swift
import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GameRouter.self)  private var router
    @State private var viewModel: GameViewModel?
    @State private var adService = AdMobService()
    @State private var showLevelUpBanner = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            if let vm = viewModel {
                gameContent(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationBarHidden(true)
        .task {
            guard viewModel == nil else { return }
            let vm = GameViewModel(modelContext: modelContext)
            vm.seedPlantsIfNeeded()
            viewModel = vm
            await adService.preload()
            await vm.startNewRound()
        }
    }

    @ViewBuilder
    private func gameContent(vm: GameViewModel) -> some View {
        VStack(spacing: 0) {
            statusBar(vm: vm)

            Spacer()

            FlowerView(petalsRemaining: vm.petalsRemaining)
                .padding(.top, 10)

            // Hint
            VStack(spacing: 6) {
                Text("Hint")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(vm.triviaQuestion)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)

            // Revealed word
            Text(vm.revealedWord)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.appAccent)
                .padding()

            Spacer()

            // Input / action area
            inputArea(vm: vm)
                .padding(.horizontal)
                .padding(.bottom, 8)

            // AdMob banner
            AdBannerView()
                .frame(height: 50)
        }
        .onChange(of: vm.phase) { _, phase in
            handlePhaseChange(phase, vm: vm)
        }
        .onChange(of: vm.roseOfJerichoDropped) { _, dropped in
            if dropped { showLevelUpBanner = true }
        }
        .overlay(alignment: .top) {
            if showLevelUpBanner {
                roseDropBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showLevelUpBanner = false }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: showLevelUpBanner)
    }

    @ViewBuilder
    private func statusBar(vm: GameViewModel) -> some View {
        HStack {
            Button { router.navigateToRoot() } label: {
                Image(systemName: "house.fill")
                    .foregroundStyle(Color.appPrimaryText)
            }

            Spacer()

            Label("Level \(vm.currentLevel)", systemImage: "star.fill")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Color.appAccent)

            Spacer()

            // Rose of Jericho inventory
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(vm.roseOfJerichoCount > 0 ? Color.appSuccess : Color.gray)
                Text("×\(vm.roseOfJerichoCount)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(vm.roseOfJerichoCount > 0 ? Color.appSuccess : Color.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.appSurface)
    }

    @ViewBuilder
    private func inputArea(vm: GameViewModel) -> some View {
        switch vm.phase {
        case .playing:
            HStack(spacing: 14) {
                TextField("A", text: Bindable(vm).guessInput)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .frame(width: 56, height: 56)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appAccent, lineWidth: 2))
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: vm.guessInput) { _, val in
                        let clean = val.filter { $0.isLetter }
                        vm.guessInput = clean.isEmpty ? "" : String(clean.last!).uppercased()
                    }
                    .onSubmit { vm.submitGuess() }

                Button("Guess!") { vm.submitGuess() }
                    .disabled(vm.guessInput.isEmpty)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .padding()
                    .frame(height: 56)
                    .background(vm.guessInput.isEmpty ? Color.gray : Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

        case .dead:
            VStack(spacing: 12) {
                if vm.roseOfJerichoCount > 0 {
                    Button {
                        withAnimation { vm.useRoseOfJericho() }
                    } label: {
                        Label("Use Rose of Jericho", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.appSuccess)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                Button("Give Up — Next Word") {
                    vm.giveUp()
                }
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.appDanger)
            }

        case .loading:
            ProgressView("Fetching question…")
                .font(.system(.body, design: .rounded))

        default:
            EmptyView()
        }
    }

    private var roseDropBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .foregroundStyle(Color.appSuccess)
            Text("A Rose of Jericho has been added to your garden!")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.appPrimaryText)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6)
        .padding(.top, 8)
        .padding(.horizontal)
    }

    private func handlePhaseChange(_ phase: GameViewModel.GamePhase, vm: GameViewModel) {
        switch phase {
        case .won:
            // Show interstitial on level-up (detected by plantsEarnedThisLevel reset)
            if vm.plantsEarnedThisLevel == 0 && adService.isReady {
                adService.present()
            }
            if let plantName = vm.earnedPlantName {
                // Fetch the plant object to pass to PlantEarnedView
                let descriptor = FetchDescriptor<PlantCollectible>(
                    predicate: #Predicate { $0.name == plantName }
                )
                if let plant = try? modelContext.fetch(descriptor).first {
                    router.navigate(to: .plantEarned(plant.name))
                }
            } else {
                // Won but no new plant (shouldn't happen) — just reload
                Task { await vm.startNewRound() }
            }
        case .gameOver:
            Task { await vm.startNewRound() }
        default:
            break
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

---

## Task 13: GameRouter & App Final Wiring

**Files:**
- Create: `WordFlora/App/GameRouter.swift`
- Modify: `WordFlora/WordFloraApp.swift`
- Delete: `WordFlora/ContentView.swift`

- [ ] **Step 1: Create GameRouter**

Create `WordFlora/App/GameRouter.swift`:

```swift
import SwiftUI

enum GameRoute: Hashable {
    case game
    case garden
    case levelMap
    case plantEarned(String)  // plant name
}

@Observable
final class GameRouter {
    var path: [GameRoute] = []

    func navigate(to route: GameRoute) {
        path.append(route)
    }

    func navigateToRoot() {
        path = []
    }
}
```

- [ ] **Step 2: Rewrite WordFloraApp.swift**

Replace the entire contents of `WordFlora/WordFloraApp.swift`:

```swift
import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct WordFloraApp: App {
    @State private var router = GameRouter()

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: GameRoute.self) { route in
                        switch route {
                        case .game:
                            GameView()
                        case .garden:
                            GardenView()
                        case .levelMap:
                            LevelMapView(
                                currentLevel: 1,
                                plantsEarnedThisLevel: 0
                            )
                        case .plantEarned(let plantName):
                            PlantEarnedRouteView(plantName: plantName)
                        }
                    }
            }
            .environment(router)
        }
        .modelContainer(for: [PlayerProfile.self, PlantCollectible.self, GameRecord.self])
    }
}

// Thin wrapper that fetches the PlantCollectible from SwiftData before showing PlantEarnedView
private struct PlantEarnedRouteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GameRouter.self) private var router
    let plantName: String

    var body: some View {
        Group {
            if let plant = fetchPlant() {
                PlantEarnedView(plant: plant, level: 1, wordsGuessed: 0)
            } else {
                // Plant not found — go home
                Color.appBackground
                    .onAppear { router.navigateToRoot() }
            }
        }
    }

    private func fetchPlant() -> PlantCollectible? {
        let name = plantName
        let desc = FetchDescriptor<PlantCollectible>(
            predicate: #Predicate { $0.name == name }
        )
        return try? modelContext.fetch(desc).first
    }
}
```

> `LevelMapView` receives static values here; for a live experience, pass the player profile's level and plantsEarnedThisLevel from a `@Query` or environment in a follow-up polish pass.

- [ ] **Step 3: Delete ContentView.swift**

In Xcode: right-click `ContentView.swift` → Delete → Move to Trash. Remove the file reference from the project.

- [ ] **Step 4: Full build + run on simulator**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

Open the app in Simulator (Xcode → Run). Walk through:
- Home screen loads with animated flower
- Tap Play → fetches trivia question, shows hint, blank word, petal flower
- Guess a wrong letter → petal falls
- Guess correct letters → word reveals
- Complete the word → PlantEarnedView shown with share button
- Garden shows locked + earned plants
- Level Map shows tiers

- [ ] **Step 5: Run all tests**

```bash
xcodebuild test -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(passed|failed|error:)" | tail -10
```

Expected: All suites pass.

---

## Task 14: Polish & Plant Illustrations

**Files:**
- Modify: `WordFlora/Assets.xcassets` — add plant images

- [ ] **Step 1: Add plant illustrations to Assets.xcassets**

For each of the 15 plants, add an image set to `Assets.xcassets` matching the `imageName` values in `PlantSeedData.all`. Suggested approach:

- SF Symbols work for common plants (Level 1/2). Use these `symbolName` overrides in `PlantCard.plantSymbol` if you prefer no custom assets.
- For exotic plants (Corpse Flower, Welwitschia, Dragon Blood Tree, Baobab), source royalty-free botanical illustrations (e.g. from Unsplash, Wikimedia Commons) and add them as 1×/2×/3× PNG sets.
- Name each image set exactly: `plant_dandelion`, `plant_daisy`, `plant_clover`, `plant_marigold`, `plant_sunflower`, `plant_orchid`, `plant_lavender`, `plant_lotus`, `plant_jasmine`, `plant_snapdragon`, `plant_venus_flytrap`, `plant_baobab`, `plant_corpse_flower`, `plant_welwitschia`, `plant_dragon_blood_tree`.

- [ ] **Step 2: Pass live level data to LevelMapView and PlantEarnedView**

In `WordFloraApp.swift`, update `PlantEarnedRouteView` to also fetch the player profile and pass real `level` + `wordsGuessed` values:

```swift
private struct PlantEarnedRouteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GameRouter.self) private var router
    let plantName: String

    var body: some View {
        Group {
            if let plant = fetchPlant(), let profile = fetchProfile() {
                let guessed = (try? modelContext.fetch(
                    FetchDescriptor<GameRecord>(predicate: #Predicate { $0.won == true })
                ).count) ?? 0
                PlantEarnedView(plant: plant, level: profile.currentLevel, wordsGuessed: guessed)
            } else {
                Color.appBackground.onAppear { router.navigateToRoot() }
            }
        }
    }

    private func fetchPlant() -> PlantCollectible? {
        let name = plantName
        return try? modelContext.fetch(
            FetchDescriptor<PlantCollectible>(predicate: #Predicate { $0.name == name })
        ).first
    }

    private func fetchProfile() -> PlayerProfile? {
        try? modelContext.fetch(FetchDescriptor<PlayerProfile>()).first
    }
}
```

Also update the `.levelMap` navigation destination to pass live profile data:

```swift
case .levelMap:
    LevelMapRouteView()
```

And add:

```swift
private struct LevelMapRouteView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let profile = (try? modelContext.fetch(FetchDescriptor<PlayerProfile>()).first)
        LevelMapView(
            currentLevel: profile?.currentLevel ?? 1,
            plantsEarnedThisLevel: profile?.plantsEarnedThisLevel ?? 0
        )
    }
}
```

- [ ] **Step 3: Final build + manual test**

```bash
xcodebuild build -scheme WordFlora \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build succeeded)" | tail -5
```

Walk through dark mode: Settings app on Simulator → Developer → Dark Appearance. Verify all screens use the correct semantic color tokens.

---

## Reminder: Before App Store Submission

- Replace all test AdMob unit IDs with real IDs from your AdMob dashboard
- Replace the test `GADApplicationIdentifier` in Info.plist with your real AdMob App ID
- Add plant illustrations for all 15 plants in Assets.xcassets
- Test on a physical device (AdMob test ads require device for full testing)

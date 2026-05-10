# WordFlora Complete Overhaul Design
**Date:** 2026-05-10
**Branch:** 1-feat-triviaapi-and-earn-flora

---

## Overview

WordFlora is being overhauled from a basic word-guessing game into a fully-featured "Happy Hangman" plant education game for iOS 17+. Players receive a trivia hint, guess the answer letter by letter, earn collectible plants with real botanical facts, and progress through difficulty levels. The flower loses petals on wrong guesses; a rare Rose of Jericho drop can revive a dead flower. Google AdMob and social sharing are integrated throughout.

---

## Goals

- Modernize codebase to iOS 17 (`@Observable`, `SwiftData`, `async/await`)
- Replace random word API with Open Trivia DB (Science: Nature category)
- Add petal-based flower mechanic with SwiftUI animations
- Add collectible plant system with real botanical facts
- Add level progression (Easy → Medium → Hard)
- Add Rose of Jericho random power-up
- Integrate Google AdMob (banner + interstitial)
- Add `ShareLink`-based sharing of plant cards and scores
- Support system dark/light mode via semantic color tokens

---

## Architecture

**Tech Stack:**
- iOS 17+ minimum deployment target
- `@Observable` macro for all view models (replaces `@State`/`@ObservedObject`)
- `SwiftData` for persistent storage
- `async/await` for all network calls
- Google AdMob via Swift Package Manager
- `ShareLink` + `ImageRenderer` for share cards
- `NavigationStack` with a `GameRouter` (`@Observable`) coordinator

**Project Structure:**
```
WordFlora/
  App/
    WordFloraApp.swift
    GameRouter.swift          // @Observable navigation coordinator
  Models/
    PlayerProfile.swift       // SwiftData model
    PlantCollectible.swift    // SwiftData model
    GameRecord.swift          // SwiftData model
  Views/
    HomeView.swift
    LevelMapView.swift
    GameView.swift
    GardenView.swift
    PlantEarnedView.swift
  ViewModels/
    GameViewModel.swift       // @Observable
    GardenViewModel.swift     // @Observable
  Services/
    TriviaService.swift       // Open Trivia DB API
    AdMobService.swift        // AdMob banner + interstitial
  Components/
    FlowerView.swift          // SwiftUI-drawn petal flower
    PlantCard.swift           // Collectible card component
    ShareCard.swift           // ImageRenderer share card
  Resources/
    Colors.xcassets           // Semantic color tokens (light + dark)
    Plants.xcassets           // Plant illustration assets
```

---

## Screens

| Screen | Purpose |
|---|---|
| `HomeView` | Title, Play button, Garden shortcut |
| `LevelMapView` | Visual level map — locked/unlocked tiers with plant previews |
| `GameView` | Core Happy Hangman loop + AdMob banner + Rose of Jericho status |
| `GardenView` | 2-column grid of collected plants with botanical facts + share |
| `PlantEarnedView` | Full-screen celebration on earning a plant + `ShareLink` |

---

## Game Loop

### Round Flow
1. `TriviaService` fetches a Science: Nature question from Open Trivia DB, filtered to single-word correct answers, at the current level's difficulty
2. The trivia **question** is displayed as the hint (e.g. *"What process do plants use to convert sunlight into food?"*)
3. The correct **answer** (`PHOTOSYNTHESIS`) becomes the word to guess, displayed as letter blanks
4. Player guesses letters one at a time via text input
5. On word completion (win or lose), `GameRecord` is written, Rose of Jericho drop is evaluated, plant reward is checked

### Petal Mechanic
- Flower starts with 8 petals drawn via SwiftUI `Path`
- **Correct guess:** petal pulses/glows, letter is revealed with spring animation
- **Wrong guess:** petal detaches and falls with `withAnimation(.spring)` drop + fade
- **0 petals:** flower dies (stem droops, center greys), round ends unless Rose of Jericho is available
- **Rose of Jericho used:** petals regrow with a bloom animation (4 petals restored)

### Win / Lose
- **Win:** plant collectible earned, `PlantEarnedView` presented, Rose of Jericho drop evaluated
- **Lose (no revival):** word revealed, `GameRecord` written (won: false), next word option shown

---

## Level Progression

| Level | Trivia Difficulty | Collectible Plants | Unlock Threshold |
|---|---|---|---|
| 1 | Easy | Dandelion, Daisy, Clover, Marigold, Sunflower | Earn 5 plants |
| 2 | Medium | Orchid, Lavender, Lotus, Jasmine, Snapdragon | Earn 5 plants |
| 3 | Hard | Venus Flytrap, Baobab, Corpse Flower, Welwitschia, Dragon Blood Tree | Earn 5 plants |

- Level advances when `plantsEarnedThisLevel` reaches 5
- `LevelMapView` shows locked tiers with silhouetted plant previews
- Interstitial ad shown at the moment of level-up before `LevelMapView` is presented

---

## Rose of Jericho Power-Up

**Botanical basis:** *Selaginella lepidophylla* can lose 95% of its water content, appear completely dead, and fully revive when placed in water — a true resurrection plant.

**In-game mechanic:**
- Drops randomly after any completed game (small fixed probability, e.g. ~15%)
- When dropped, a status bar notification appears mid-`GameView`: *"A Rose of Jericho has been added to your garden!"*
- Stored as `roseOfJerichoCount` in `PlayerProfile`
- Inventory count shown in `GameView` status bar at all times
- Tap the Rose of Jericho icon when flower is dead to revive: 4 petals restored, game continues
- One Rose of Jericho consumed per use

---

## Data Models (SwiftData)

```swift
@Model class PlayerProfile {
    var currentLevel: Int           // 1, 2, 3
    var plantsEarnedThisLevel: Int  // resets on level-up
    var roseOfJerichoCount: Int     // inventory
    var gamesPlayed: Int            // total games completed
}

@Model class PlantCollectible {
    var name: String                // "Dandelion"
    var botanicalName: String       // "Taraxacum officinale"
    var botanicalFact: String       // real fact
    var level: Int                  // which level it belongs to
    var earnedCount: Int            // how many times earned (0 = locked)
    var imageName: String           // asset catalog name
}

@Model class GameRecord {
    var date: Date
    var wordGuessed: String
    var triviaQuestion: String
    var won: Bool
    var petalsRemaining: Int
    var plantEarned: String?        // nil if lost
    var level: Int
}
```

**Notes:**
- `PlayerProfile` is a single persistent record per install
- `PlantCollectible` is seeded at first launch with all plants (earnedCount = 0)
- `GameRecord` is append-only history used for stats on share cards

---

## Trivia Service

**API:** Open Trivia DB — `https://opentdb.com/api.php`

**Request parameters:**
- `amount=1`
- `category=17` (Science: Nature)
- `difficulty=easy|medium|hard` (mapped from current level)
- `type=multiple`
- `encode=url3986`

**Filtering:** After decoding, discard any question whose `correct_answer` contains a space or is longer than 18 characters. Retry on discard (max 3 retries, then fall back to a curated local word list).

**Local fallback word list:** ~30 plant/nature words per difficulty level bundled in `WordBank.json`, used when API is unreachable or all retries exhausted.

---

## Visual Design

### Flower
- Pure SwiftUI `Path`/`Shape` — no image assets
- 8 petals arranged radially around a circular center
- Each petal is an independent view with its own animation state
- Petal colors shift warm → cool as count decreases (visual urgency)
- Dead state: monochrome, drooping stem via rotation animation

### Plant Collectible Cards
- Botanical illustration style
- Shows: common name, botanical name (*italicised*), one real fact, earned count badge
- Locked cards: greyed silhouette with a lock icon
- SF Symbols used where a plant symbol exists; custom asset illustrations for exotic species (Corpse Flower, Welwitschia, Dragon Blood Tree, Baobab)

### Color Tokens (semantic, light + dark)

| Token | Light Mode | Dark Mode |
|---|---|---|
| `background` | Soft cream `#FAF7F0` | Deep forest `#1A2E1A` |
| `surface` | White `#FFFFFF` | Dark moss `#2C3E2C` |
| `primaryText` | Dark moss `#2C3E2C` | Pale mint `#D4EDD4` |
| `accent` | Warm amber `#E8A838` | Golden yellow `#F0C060` |
| `danger` | Coral red `#E85050` | Soft red `#FF6B6B` |
| `success` | Leaf green `#4CAF50` | Bright green `#66BB6A` |

### Typography
- SF Rounded throughout — friendly and legible without being childish
- Title: SF Rounded Bold 36pt
- Body/hints: SF Rounded Regular 17pt
- Plant facts: SF Rounded Italic 14pt

---

## AdMob Integration

| Placement | Type | Trigger |
|---|---|---|
| Bottom of `GameView` | Banner | Always visible during play |
| Level-up moment | Interstitial | Between `PlantEarnedView` and `LevelMapView` |

- AdMob SDK added via Swift Package Manager
- `AdMobService` wraps banner and interstitial loading
- Test ad unit IDs used in debug builds; release IDs in release builds via xcconfig

---

## Sharing

- `ShareLink` with `ImageRenderer`-generated share card
- Share card shows: earned plant illustration, botanical fact snippet, player level, words guessed count, WordFlora branding
- Available from `PlantEarnedView` (immediate after earning) and `GardenView` (per plant card)
- Share sheet triggers native iOS share options (Messages, Instagram, etc.)

---

## Dark / Light Mode

- All colors defined as semantic asset catalog entries with light and dark variants
- No manual `colorScheme` environment reads needed in views
- Plant card and flower colors tested in both modes
- AdMob banner automatically adapts via AdMob SDK theming

---

## Out of Scope

- Multiplayer / social leaderboards
- Push notifications
- In-app purchases
- Sound effects redesign (existing sounds retained as-is)
- iPad-specific layouts (iPhone only for this overhaul)

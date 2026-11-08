# Parallel lanes: file conflict map

Date 2026-11-07. Scope: the queued builder tasks after the G3 merge. Sources: `docs/pm/textfit-builder-brief.md` (T1 to T32), `docs/pm/engagement-quick-wins.md` (A, B, C), `docs/pm/g4a-builder-brief.md` (G4a), plus a grep of `WordFlora/` for the symbols those briefs name. File lists are from the briefs; where a brief says "wire it where X happens", the file is the one that grep found. A builder who touches a file not listed here should add it to the table in the PR note.

There is one build lock. Writing code needs no lock, so the question is only how many people edit the same files at once and how painful the rebase is.

## Files per task

Legend: T = text-fit pass, A = weekly note, B = make it yours, C = share age gate, G = G4a.

| File (under `WordFlora/`) | T | A | B | C | G | Notes |
|---|---|---|---|---|---|---|
| `Views/GardenView.swift` | T1, T31 | | | | B4 banner height, R1 water card | T edits the Grid at the top; G edits the banner and adds a card below. Different regions. |
| `Views/PlantDetailView.swift` | T13 (resource chips `ViewThatFits`) | | rename pencil, widget row | | R1 water button shares the cap | Three tasks, three regions. B is the largest edit. |
| `Views/GameView.swift` | T14 (`lineLimit(2)` at the top bar) | note slot only if the card lives here (it does not; A uses Home) | `earnedCard` (new name button, pin row) | `shareButton` (wrap both `ShareLink`s) | rest card: R2 hint row, B5 preload | Highest traffic file. C and B both edit the earned/share area. |
| `Views/PlusView.swift` | T5, T17 to T22, T25 to T28 (many) | | | | | Text-fit only. |
| `Views/SeasonsView.swift` | T25 (Restore feedback) | | | | | Text-fit only. |
| `Rules/Paywall.swift`, `Services/EntitlementService.swift` | T6, T19, T27, T28 | | | | | Text-fit only; tests `PaywallRulesTests`. |
| `Views/ShedTools.swift` | T14, T30 | | | | | Text-fit only. |
| `Views/PotPickerViews.swift` | T3, T4, T13 | | | | | Text-fit only. Largest single-file rewrite in T. |
| `Theme/Theme.swift` | T7 (`PrimaryButtonStyle` reads `isEnabled`) | | | | | One function. Anyone adding a style here conflicts. |
| `Views/SettingsView.swift` | (T29 is a no-op) | | | | owner-step text only if B8 touches the in-app row (docs mostly) | Low risk. Only conflicts if A adds the note toggle here. |
| `Views/HomeView.swift` | T-none directly (check T9 list: no) | note card in the note slot | | | `playTappedOnHome` / Home banner key | A adds a card; G changes the play action. Different regions. |
| `Views/ButterflyView.swift`, `Views/FieldNotesPage.swift`, `Views/VisitorsBookView.swift` | T8 to T12 | | | | | Text-fit only. |
| `Views/BadgesView.swift`, `Views/BadgeDetailView.swift` | T2 | | | | | Text-fit only. |
| `Views/GrandGardenViews.swift`, `Views/GuideView.swift`, `Components/NameStoryCard.swift` | T13, T15, T16 | | | | | Text-fit only. |
| `Components/ShareCard.swift` | | `WeekShareCard` (new type) | | | | A only. |
| `App/AppModel.swift` (+ new `AppModel+WeeklyNote.swift`) | | new extension file | `pinToWidget(_:)`, `rename(_:to:)` | | `adBeforeNextRound`, `watchRewarded`, `releaseAll()` on age change | A uses a new file so it does not collide. B and G both edit the main file. |
| `App/AppSettings.swift` | | one key | | | counters if kept in settings (brief says no new stored field) | Small, append-only; trivial conflicts. |
| `Rules/PlantName.swift` (new), `Rules/WeeklyNote.swift` (new), `Rules/Badges.swift` | | WeeklyNote, Badges (counter) | PlantName | | | New files do not conflict; `project.pbxproj` does (below). |
| `Rules/CopySafety.swift` | | reads | reads | | reads | Nobody edits it unless a banned-word list changes. |
| `Ads/AdsService.swift`, `Rules/AdPolicy.swift` (new), `Rules/FadedBloom.swift`, `Components/FadedBloomArt.swift` | | | | | all | G only. |
| `Info.plist`, `Config/Ads.xcconfig`, build phase script | | | | | all | G only. Never touch `Ads.local.xcconfig`. |
| `Views/WakePuzzleView.swift` | T-none (WakePuzzleView named in a verify step) | | | | R3 wake row | G only for edits. |
| `Components/DailyQuestCard.swift`, `LifePanel.swift`, `SeedPotView.swift`, `KeyboardView.swift`, `WordTilesView.swift`, `LevelMapView.swift`, `OnboardingView.swift`, `PlantVoice.swift`, `Rules/Butterfly.swift` | named in the T brief for checks or small fixes | | | | | Text-fit only. |
| `WordFlora.xcodeproj/project.pbxproj` | | new files | new file | | new files (`AdPolicy.swift`, tests) | Every task that adds a Swift file edits this one. Merge conflicts here are mechanical: keep both sides, then `plutil -lint`. |
| Tests: `TextFitLayoutTests` (new), `PaywallRulesTests`, `AdPolicyTests`/`AdUnitIDTests` (new), new A/B tests | each own | | | | | Separate files; no overlap. |

## Overlap summary (files two or more tasks edit)

| File | Tasks | Risk |
|---|---|---|
| `Views/GameView.swift` | T, B, C, G | High: four tasks, and B and C touch the same card. |
| `Views/PlantDetailView.swift` | T, B, G | Medium: different regions, but B is large. |
| `Views/GardenView.swift` | T, G | Low to medium. |
| `Views/HomeView.swift` | A, G | Low. |
| `App/AppModel.swift` | B, G | Medium (one big type, two additions). |
| `App/AppSettings.swift` | A, (G) | Low. |
| `Views/PlusView.swift`, `Views/PotPickerViews.swift`, `Views/ShedTools.swift`, `Theme/Theme.swift` | T only | None between these lanes, but a G or A edit there would conflict with T's rewrite. Do not touch them from other lanes. |
| `Views/SettingsView.swift` | T (no-op), maybe A | Low. |
| `project.pbxproj` | A, B, G, T (test file) | Mechanical only. |

## Recommended merge order

1. G3 (in flight).
2. **Text-fit (T)**: it rewrites the most files (Plus, pot pickers, grids, Theme) and changes layout containers that later tasks sit inside. Land it first so A, B, C, G rebase onto the final layout.
3. **C** (about 1 h): a small wrap in `GameView.shareButton`. Land it before B so B's edits to `earnedCard` rebase onto the final share logic and the age rule is not lost.
4. **B**: `GameView.earnedCard`, `PlantDetailView`, `AppModel`. Larger, so merge before A and G add more to those files.
5. **A**: mostly new files plus a card in `HomeView`; least conflict, so it can go after B.
6. **G4a**: touches `GameView`, `GardenView`, `PlantDetailView`, `HomeView`, `AppModel` last, after the UI shapes settle; it also changes `Info.plist` and the build, which is best done on a stable tree and tested at the end with the full regression.

Order summary: T, C, B, A, G4a. Each merge runs the unit tests and the affected UI classes on the single lock; the next branch rebases and re-runs its own tests.

## What can run in parallel

**Writing**, in separate worktrees off the merged G3 branch, can start together:

| Lane | Start | Why safe |
|---|---|---|
| Text-fit | at once | owns the layout files |
| C | at once | 3 lines in `GameView`; rebase after T lands |
| A | at once | new files plus one `HomeView` card |
| B | at once, but expect to rebase on T and C | the largest overlap with T in `PlantDetailView` and `GameView` |
| G4a | at once for `AdPolicy`, `AdsService`, `FadedBloom`, Info.plist/xcconfig, tests; hold the UI rows (R1, R2, R3, B4, B5) until T has landed in `GardenView`, `GameView`, `WakePuzzleView` | its non-UI half is separate files |

Rules for parallel writers: commit small and often, rebase on the merged branch before asking for the lock, never reformat a file you do not own, keep `project.pbxproj` edits to one line per file added.

**Building and testing** queue on the single lock via `tools/dev/xb.sh`. A rough order for the lock: whichever branch is next in the merge order gets priority; others run only unit tests (fast) until their turn, and run UI batches after their rebase. Do not run UI batches on a branch that is going to be rebased on T, because they repeat.

Realistic cost: T is the long pole (32 items plus screenshots). Letting A, B, C and G4a's non-UI half be written while T builds hides about 15 h of writing behind T's build and test time. The extra rebase work is mostly in `GameView` and `PlantDetailView` (budget about 30 minutes each).

## Hot spots to coordinate

- `GameView.swift`: assign one owner per merge. C and B must see each other's diff before either lands.
- The pot picker, Plus and Theme files: only T edits them. If a lane needs a change there, send it to the T builder.
- `AppModel.swift`: B adds `pinToWidget` and `rename`; G adds ad methods. Keep each addition in its own extension file if the builder is willing (preferred: `AppModel+Rename.swift`, `AppModel+Ads.swift`), which removes this overlap.

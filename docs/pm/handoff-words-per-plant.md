# Handoff: 3 words per plant (paused 2026-11-04)

## Done (uncommitted, in the main working tree)
- `Economy.wordsPerPlant = 3`; `PlayerProfile.wordsTowardPlant: Int = 0`.
- `GameViewModel`: `progressMade`, `wordsTowardPlant`, `wordsPerPlant`; `awardPlant` gives the first plant ever and an unfound hero plant at once, otherwise counts words and brings a plant on the 3rd (resets to 0). Losses untouched.
- `GardenBackup.Profile.wordsTowardPlant: Int?` (export, restore, plausibility); `DataReconciler` max.
- `PlantProgressCopy` (in `Rules/ProgressionPolicy.swift`): "Great word!", "N of 3 words to your next plant(.)".
- `GameView` win card: no plant -> "Great word!" + progress line + fact, no rain/plant sound/lub-dub, no share button. `HomeView` hero: progress line after the first plant, hidden in Quiet Garden. `HOOK (progress meter)` comments in both.
- Tests: GameViewModelTests (new + updated hero/duplicate/level tests), GardenBackupTests, ReconcileTests, UI test `testAfterTheFirstPlantEveryThirdWordBringsTheNext` in WordFloraUITests.
- Docs: STATUS.md entry (already swept into an earlier commit by another agent), spec section 19 + peak-window note.

## Test status
- RED seen for all new tests (stubs). GREEN not yet confirmed: a full unit run was started in an isolated worktree when the pause came.
- The main tree currently fails to compile tests because of another worker's in-progress `earnedPotIds` tests (PotCatalogTests), not this work.

## Shared files (do not commit whole files)
- `GameViewModel.swift` also has another worker's `roundsThisSitting`; `HomeView.swift` has the owner's `HomeRoseLine` and others' tile/sparkle edits.
- A mine-only copy is ready in the scratchpad worktree `wfprogress-wt` (HEAD 714d9ff + only this work).

## Next steps
1. In `scratchpad/wfprogress-wt`: run unit suite (`-derivedDataPath scratchpad/wfprogress-dd`, simulator "WF Progress iPhone 17"), expect only the 3 StoreKitConfigTests failures.
2. Run UI tests: WordFloraUITests (new test + first-session + solve tests), HomeLayoutUITests.
3. `git -C wfprogress-wt diff > p.patch`; in main repo `git apply --cached p.patch` and commit in two plain commits (logic+unit tests; UI+UI test+spec doc).
4. Remove worktree, delete the simulator, run the attribution grep.

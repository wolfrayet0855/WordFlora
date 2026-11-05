# Handoff: 16-pot ladder (pot earning review, approved)

Status: paused mid-task. Nothing of this work is committed yet. The edits sit in the working tree, mixed into files that other workers also have uncommitted changes in.

## Done (uncommitted)
- `WordFlora/Rules/PotCatalog.swift`: 16 pots in climb order, new rules, `legacy` old rules (owned = new OR old OR stored), `Unlock.gardenDays`, `Stats` (plantsInLevel, gardenDays, earnedPotIds), `passes`/`earnedByPlay`/`recordEarned`, level progress counted as "N of 10 plants in level L", tip "Four more plants to go!", `Copy.newPots` ("New pots in your shed!"), `gridColumns = 4`, `spokenName` ("Fly-trap"), and marks for blossoms, pebbles, zigzag, vine, bark and drops (`triangle`, `teardrop`, and `PotMark.ghost` for the to-earn outline).
- `Components/PotArtView.swift`: triangle and teardrop paths, plus ghost fill/hidden handling.
- `Views/PotPickerViews.swift`: 4 x 4 grid at every size in the picker and the Shed. Shed cards are smaller (60 pt art, text capped at xxxLarge). `PotNewLine`, and `record` closures that run on appear.
- `Views/PlantDetailView.swift` and `Views/ShedView.swift`: they pass `record: { app.recordEarnedPots() }`.
- `App/AppModel+Pots.swift`: `potStats` now includes gardenDays and earnedPotIds. Adds `recordEarnedPots() -> Bool`.
- `Models/PlayerProfile.swift`: `earnedPotIds: [String] = []`. `Storage/DataReconciler.swift`: merged as a sorted union. `Storage/GardenBackup.swift`: optional `earnedPotIds` (export, plausibility check, merge on restore).
- `App/WordFloraApp.swift`: `-uitest-pots` fixture (L1 and L2 done, 6 plants in L3, 3 garden days).
- Tests: `WordFloraTests/PotCatalogTests.swift` rewritten, including the grandfather property test, ladder, level progress, Dewdrop, patterns, recording, and the AppModel record-once test. New tests in `GardenBackupTests` (round trip, union, old backup) and `ReconcileTests` (union). `WordFloraUITests/TendingUITests.swift`: 4x4 checks at AX sizes, a new-pots-line-once test, a Shed AX audit, and the `testPotScreensPartWayUpTheLadder` screenshots.

## Test status
- PotCatalogTests: 29/29 passed in a scratch copy of the tree, before the storage edits. Since then, nothing has been built or run in the real tree. The run that was going was stopped for the pause.

## Warning
- An earlier script of mine briefly emptied PlayerProfile.swift, DataReconciler.swift and GardenBackup.swift. I rebuilt them from HEAD plus the other worker's exact diff (wordsTowardPlant). The rebuilt files diffed identical to that worker's change before my edits went back on. That worker should still glance at their hunks.

## Next exact steps
1. Build and run PotCatalogTests, GardenBackupTests, ReconcileTests and CoreRulesTests on the "WF Pots iPhone 17" simulator with `-derivedDataPath <scratchpad>/dd-pots`. Fix anything that fails.
2. Commit only my hunks in the shared files: PlayerProfile, DataReconciler, GardenBackup, WordFloraApp, GardenBackupTests and ReconcileTests. Build the patch against HEAD and use `git apply --cached`. Never commit the other workers' hunks.
3. Run the pot UI tests in TendingUITests. Compare the `pots-*` screenshots (SCREENSHOT_DIR) with `design-preview/pots/shots/s6-proposed-*.png`, and fix any differences.
4. Run the full unit suite. Only the 3 known StoreKitConfigTests failures are acceptable. Check commit messages for attribution words, then delete the simulator.

# Handoff: pot data fixes and pot picker UI review

Branch 3-feat-content-and-polish. Paused for the usage limit.

## Done (committed)
- 1432272 Choosing a pot no longer bumps lastTendedAt. New `PlantCollectible.potChosenAt` (defaulted `.distantPast`). The reconciler keeps the later pick and falls back to lastTendedAt when neither pick has a stamp. The backup carries `potChosenAt` as optional, so old backups still read.
- 8b9a81f `.level(n)` checks that level n itself is finished. `Stats.finishedLevels: Set<Int>`, and the API takes `finishedLevels:`. This also fixes the "Zero more levels to go!" tip.
- b019944 UI test "Did you know" now uses Poppy. The cause was that Sago Palm gained a name story; the card code was fine.
- cdd0a64 Pot tiles at AX sizes: names capped at xxxLarge with scale 0.5, Plus tag and badge capped at Large, padding, VoiceOver hints, Shed badge and tag clear the rims.
- 03fb827 Picker audit at AccessibilityL and AccessibilityXXXL (contrast and Dynamic Type excused on pot tiles only, and printed), plus Shed pot screens test.
- Targeted runs green: PotCatalogTests, ReconcileTests, GardenBackupTests, the Poppy test, the picker audit, Shed screens.

## Not done
- Full suite (`xcodebuild test -scheme WordFlora -destination 'platform=iOS Simulator,name=iPhone 17'`) was stopped for the pause, so it has not run on these commits.

## Next steps
1. Run the full suite once. Only the 3 StoreKitConfigTests failures are acceptable.
2. Note: the working tree holds another agent's uncommitted pot work (gardenDays unlocks, new pots) in the same files. Run the suite on a clean checkout of HEAD, or after that work lands.

## Uncommitted files of mine
None.

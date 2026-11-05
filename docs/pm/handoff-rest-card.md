# Handoff: Dusk rest card and break card (paused)

## Done (uncommitted, in the shared tree)
- `WordFlora/Rules/RestCardCopy.swift` (new): every string on both cards, plus `reward(isDaily:wordsPlayed:)`.
- `WordFlora/Components/RestScene.swift` (new): 176pt night/day header (gradient, moon or sun, stars, z's, lavender or sunflower). Loops stop under system or app Reduce Motion.
- `AppModel.adWouldPlayOnOneMore`: the same AdGate predicate as `adBeforeNextRound`, judged `peakWindowSeconds` ahead. Reason: the card opens right as the win card is dismissed (`markPeakDismissed`), so judging "now" would always say no.
- `AdsService.offline` and launch flags in `WordFloraApp`: `-uitest-ads-offline` (rules on, SDK off) and `-uitest-sessions=N`.
- `GameViewModel.roundsThisSitting` (2 lines under `regularRoundsThisSitting`). It is NOT staged: the file also holds another worker's uncommitted changes.
- Tests (new): `WordFloraTests/RestCardTests.swift` and `WordFloraUITests/RestCardUITests.swift`. All 4 new files are in the pbxproj (device family still `= 1` only).
- The app target built in the main tree. The unit tests have not run yet.

## Not done
- GameView edits. They are scripted in the scratchpad (`gameview_edit.py`, which applies to the HEAD version of GameView). GameView.swift still has another worker's uncommitted plants-per-words hunks, and those must not be touched. Before resuming, check `git status`. If GameView is still dirty, edit only the breakCard/restCard/dimmed/afterRound/onAppear/state regions. Commit only my hunks: stage a blob built from HEAD plus my edits via `git hash-object -w` and `git update-index --cacheinfo`.
- No commit has been made yet: the tests are unverified.
- Screenshots, comparison with the mockup, and the full unit suite.

## Next steps
1. The main tree did not build earlier: another worker's WidgetActions.swift was missing ToolEngine. Build and test in a detached worktree at HEAD with only my files copied in (it was in the scratchpad at `wt/`), using simulator `WF Rest iPhone 17` (B49EAD85-EADC-4CD2-BFDC-2E56BD62F4BC) and derived data in the scratchpad.
2. Run `RestCardTests`, then apply the GameView edit and run `RestCardUITests` with SCREENSHOT_DIR set. Compare against `design-preview/rest-card/shots/a-*.png`.
3. Commit in small steps. Delete the simulator and the worktree when finished.

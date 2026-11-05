# Handoff: Shed, Visitors and Butterfly game (paused 2026-11-04)

Nothing of this work is committed yet (left uncommitted on purpose: the Shed v2 view is not compiled or tested).

## Done (uncommitted, in the main tree)
- Logic: `Rules/ToolEngine.swift` (net 48/64/80 `netCatchRadius`, mister `trickleHours/trickleCap(forMister:)`, `trickleEconomy`, `ToolEngine.applyTrickle`, `totalUpgradeCostForAllTools` = 900, `ShedPolicy`, `ShedCopy` with the shed-v2 copy table). Prices: 30/120 is the truth; "900" was the whole Shed.
- `Rules/Butterfly.swift`: 12 grade 2-3 facts (sources `docs/research/visitor-facts.md`), `Rarity.label`, `StickerAlbum.seenAt` (decodeIfPresent, merged by latest), `VisitorsCopy`, `Summary.newFriendIds`.
- `Rules/ButterflyGameModel.swift`: calm mode (no clock, 60% speed, ends at 5 or `finishNow()`).
- `Rules/WakeChallenge.swift`: "n of 3 friends".
- `App/AppModel.swift` (my hunks only: `refreshFreeDrops` via ToolEngine, `startButterflyGame(..., wake:)` with calm, `finishButterflyGame(_, wake:)`). The `adWouldPlayOnOneMore` hunk belongs to the rest-card worker.
- `Shared/WidgetActions.swift` trickle wired; `ToolEngine.swift` added to the widget target in the project file (plus `Views/ShedTools.swift` in the app target). The other 16 project-file lines belong to the rest-card worker.
- Views: `ButterflyView.swift` rewritten (game starts on open, Reduce Motion override, name pill, New friend card, said-hello pill, calm Done button, summary grid, lantern toggle gone; new `VisitorsView`, `VisitorSticker`, `RarityChip`, `VisitorDetailSheet`). `WakeSheet.swift` (adaptive count colour, net radius, wake catches credited, also on close). `GameRouter` `.visitors`, `RootView` route. `HomeView`: Visitors tile -> `.visitors`, `lock.fill` -> soft `sparkles` (my two hunks only; the rest is the progress worker's).
- `WordFloraApp.swift`: UI flags `-uitest-album`, `-uitest-points=N`, `-uitest-calm`, `-uitest-quiet` (my hunk only).
- Shed v2: `Views/ShedTools.swift` (ToolTint, TierPips, ShedHeader, ToolTile, ToolSheet, UpgradeCard) and `Views/ShedView.swift` rewritten (pots section call kept exactly as the pot worker had it). New assets `ShedScene`, `ShedSceneQuiet`, `ShelfPlank` (SVG, Any/Dark) in Assets.xcassets.
- Tests added: ToolEngineTests (price, net, mister, Shed copy, Quiet Garden), ButterflyAndBadgeTests (facts, rarity, album dates, copy), ButterflyGameModelTests (calm), WakeTests (wake crediting, calm vs wake).
- `docs/STATUS.md` section and Glow Lantern backlog line.

## Test status
- build-for-testing passed BEFORE the ShedView/ShedTools rewrite. A unit run (ToolEngine, ButterflyAndBadge, ButterflyGameModel, Wake*, AppModelTending, WidgetActions, TendingEngine) was in flight at pause; result in `<scratchpad>/shed/unit1.log`, not read.

## Next exact steps
1. Rebuild (own sim "WF Shed iPhone 17", derived data `<scratchpad>/shed/dd`), fix compile errors in ShedTools/ShedView.
2. Run the unit tests above; fix.
3. Update `WordFloraUITests.swift`: the butterfly test now goes Visitors -> "Say hello" (no "Meet your garden visitors"/Start), summary title "You met N friends"; shed tests: "Watering can" text still exists in tiles (label is on the button, check); add the drafted tests in `<scratchpad>/shed/uitests.swift` (Visitors page, calm Done, Quiet Shed with no prices, audits).
4. Screenshots light/dark/AX vs mockups; full unit suite (3 StoreKitConfigTests failures allowed).
5. Commit only my hunks in shared files (AppModel, HomeView, WordFloraApp, project file, WordFloraUITests) with `git apply --cached` of partial patches; snapshots of the other workers' versions are in `<scratchpad>/shed/snap/`. Plain messages, no attribution.
6. Pot shelf planks (PotShelf, 16 pots) left to the pot worker; `ShelfPlank` asset is ready for it.
7. Delete simulator "WF Shed iPhone 17" when done.

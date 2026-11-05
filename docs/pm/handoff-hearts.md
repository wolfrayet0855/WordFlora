# Handoff: Life panel hearts (2026-11-04)

## Done (committed)
- 714d9ff Tests: all five hearts reachable without tools (LifeStatsTests, StatsActionRuleTests).
- 57883fc LifeStats.snapshot: hearts = hello + drink + sun + soil + a finishing touch (second drink of the day OR a prune today). Copy unchanged.
- RED seen (7 failures as expected), then GREEN: LifeStats, StatsActionRule, TendingEngine, CoreRules, LoveEngine = 96 tests, 0 failures.
- Root cause confirmed: the 5th heart needed a prune (Shears from the Shed plus a 2-day rest).
- Repot does not count: no timestamp records an ordinary repot (lastRepotGrowthAt is set only by a happy-match repot that gave growth).

## Not done
- Full unit suite: the run was started and not yet read. Log: scratchpad/hearts-full.log (worktree build at 57883fc).
- Delete the temp worktree (`git worktree remove --force <scratchpad>/wt-hearts`) and the simulator 'WF Hearts iPhone 17' (3E182763-DD27-4D41-AF50-8095E14A86DE).
- Report the petals findings to the coordinator (below).

## Notes
- The main tree did not build at the time: another worker's uncommitted edits use `PlayerProfile.earnedPotIds` in AppModel+Pots.swift, which was not defined yet. That is why tests ran in a detached worktree at HEAD.
- `cd` into the scratchpad worktree exits 127 (a shell hook). Pass absolute `-project` paths instead.

## Petals findings (proposal only, no code)
- An active player can drop below 5 petals. A plant loses a petal 24h after its last love. A player who comes back each day but a bit later than the day before (say 9am, then 10am) opens to 4 petals and rain until they say hello. Plants the player does not visit (only the level's earned plant gets love from a win) lose petals even when the player is active.
- Weight: hearts move up with every action. Petals sit at 5 for an active player and only ever fall, so a hello at 5 petals shows no change. Idea: a soft glow on the petal row when a hello lands at 5.

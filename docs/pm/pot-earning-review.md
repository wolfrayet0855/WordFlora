# Pot earning review: pace and the exotic climb

Status: proposal for the owner (revision 1, after one critic pass). Analysis and design only; no Swift has been changed.

Mockup: http://localhost:8765/pots/index.html#s6. It is the "Proposed" section in a dashed amber frame; add `?only=s6&theme=dark|light` to see only that section in one theme. The data is in `design-preview/pots/pots.json` under the key `proposal`, kept apart from the shipping `pots` array. Screenshots: `design-preview/pots/shots/s6-proposed-{light,dark,narrow-light}.png`.

## Headline

1. **The current thresholds were set for a slower game.** At 3 words per plant they bunch up:
   - Mint (50 plants) and Starlight (finish level 5) arrive on the same word, the last one in the game.
   - A casual player (5 words a day) gets nothing new between day 18 and day 30.
   - A young child (3 words a day) waits 9 days between the first pot and the second.
2. **Plants grown and levels finished are nearly the same signal.** Levels open in order, ten plants each (`ProgressionPolicy.wordLevel`), so "plants N" just marks a spot inside a level. Sage glaze at 10 plants is exactly "finish level 1". The proposal uses this on purpose. **Each level finish earns that level's capstone pot, and a plant-count pot sits halfway through every level.** That makes 11 evenly spaced rungs, one every 5 plants. For a casual player, a new pot arrives about every 3 days from day 1 to day 30.
3. **16 pots: the 10 we have, plus 6 new.**
   - Five of the new pots are earned free at levels 2 to 5: Blossom, Living stones, Flytrap, Jade vine and Rainbow bark. Four of those come at levels 3 to 5, so Plus is never the only way to get a rare pot.
   - Dewdrop is earned with 7 Garden Days.
   - Plus stays at 3 pots, unchanged.
4. **Only move thresholds earlier, never later.** All four changes to existing pots are earlier: 10 to 5 plants, level 3 to level 1, 50 to 15 plants, and level 5 to level 4. On top of that, each pot keeps its old rule, and a pot counts as owned when **either** rule passes. Then no pot can be taken back, whatever order plants arrive in.
5. **Add one gentle feat, not a streak.** "Play on 7 different days. Any days count!" uses `PlayerProfile.gardenDays`, which never goes down and is merged by max on sync. Leave out streak goals, stage-4 goals and badge goals for now.

## Pace model

The owner's new pace: a correct word earns progress, a plant arrives every 3 correct words, the first plant comes on the first correct word, and a hero word gives a plant at once. So, without hero words, plant k arrives on correct word `3k - 2`. Level n is finished at plant 10n, which puts level 5 at plant 50, word 148.

Assumptions to confirm:
- "First plant instant" happens once per game. If it happens once per level, each level-finish pot comes 2 words sooner per level, which does not change any finding.
- Hero words only make things sooner, so every word count below is an upper bound.
- Paces: 3 words a day (young child), 5 a day (casual, as briefed) and 15 a day (keen). Day = `ceil(words / pace)`, counting days the child plays. Calendar days are longer if the child skips days.
- Levels are played in order, and a found plant is never un-found (the love, rain and seed rule keeps the collection). The grandfathering guard below does not depend on this.

## 1. Current thresholds at the new pace

| Pot | Rule today | Correct words | Day @3/day | Day @5/day | Day @15/day | Verdict |
|---|---|---|---|---|---|---|
| Plain blue | free | 0 | 1 | 1 | 1 | Fine. |
| Terracotta | plants 1 | 1 | 1 | 1 | 1 | Fine. Every child gets a pot in the first sitting. |
| Sage glaze | plants 10 | 28 | 10 | 6 | 2 | **Too slow for a young child.** It comes 9 days after Terracotta, at the same moment as finishing level 1. |
| Rose pink | plants 25 | 73 | 25 | 15 | 5 | Fine on its own. |
| Sunflower | finish level 3 | 88 | 30 | 18 | 6 | Timing is OK, but the theme is off: sunflower is a level 1 plant. |
| Mint | plants 50 | 148 | 50 | 30 | 10 | **Collides** with Starlight on the final word. A simple dotty pot is held back as the last prize. |
| Starlight | finish level 5 | 148 | 50 | 30 | 10 | **Collides** with Mint. |

Nothing comes too fast. No player gets more than one pot in the first sitting, except a keen child, who gets Sage glaze on day 2. The problems are the long waits and the double prize at the end:
- At 5 words a day, the gaps run from day 1 to day 6, and from day 18 to day 30.
- At 3 words a day, the gaps reach 20 days.
- Only 6 pots are earned in about 30 days, and 3 of them come in the last 12 days.

## 2. Proposed ladder (as plants get more exotic, so do the pots)

Each level gets a look taken from its own plants (`Plants.json`).

| Tier | Plants in that level | Pot look | Pots (halfway pot, then capstone) |
|---|---|---|---|
| L1 Simple clay and glaze | dandelion, daisy, sunflower, rose | plain clay and glaze | Plain blue (start), Terracotta (1), Sage glaze (5), **Sunflower** (finish L1) |
| L2 Patterned | orchid, lotus, cherry blossom, saguaro | painted patterns | Mint (15), **Blossom** NEW (finish L2) |
| L3 Garden and wild | Venus flytrap, baobab, corpse flower, Lithops, Joshua tree | wild and desert | Rose pink (25), **Living stones** NEW (finish L3, after Lithops) |
| L4 Rare and shimmer | Rafflesia, ghost pipe, giant water lily, sundew | rare and glowing | **Flytrap** NEW (35, bug-catchers: sundew in L4, flytrap and pitcher plant in L3), **Starlight** (finish L4) |
| L5 Exotic collector | Wollemi pine, jade vine, ghost orchid, rainbow eucalyptus | collector porcelain and bark | **Jade vine** NEW (45), **Rainbow bark** NEW (finish L5) |
| Garden Days | any 7 days | gentle feat | **Dewdrop** NEW |
| Plus | | extra pots, as decided | Honey stripe, Moonlit, Meadow (unchanged) |

Placement limits: Rose pink must stay at 25 plants or earlier, because moving it later would take it from players who own it. The slots at or below 25 plants are already filled by the five plain pots and Blossom. That is why Flytrap, which the critic suggested for L3, sits at the L4 halfway rung instead. It is themed on the sundew, which is in L4, and on the bug-catchers in general.

### Findings table: old rule, new rule, estimated days

| Pot | Old rule | New rule | Correct words | Day @3 | Day @5 | Day @15 |
|---|---|---|---|---|---|---|
| Plain blue | free | free | 0 | 1 | 1 | 1 |
| Terracotta | plants 1 | plants 1 (same) | 1 | 1 | 1 | 1 |
| Sage glaze | plants 10 | **plants 5** (earlier) | 13 | 5 | 3 | 1 |
| Sunflower | finish L3 | **finish L1** (earlier) | 28 | 10 | 6 | 2 |
| Dewdrop | new | **7 garden days** | any | 7th day played | 7th | 7th |
| Mint | plants 50 | **plants 15** (earlier) | 43 | 15 | 9 | 3 |
| Blossom | new | **finish L2** | 58 | 20 | 12 | 4 |
| Rose pink | plants 25 | plants 25 (same) | 73 | 25 | 15 | 5 |
| Living stones | new | **finish L3** | 88 | 30 | 18 | 6 |
| Flytrap | new | **plants 35** | 103 | 35 | 21 | 7 |
| Starlight | finish L5 | **finish L4** (earlier) | 118 | 40 | 24 | 8 |
| Jade vine | new | **plants 45** | 133 | 45 | 27 | 9 |
| Rainbow bark | new | **finish L5** | 148 | 50 | 30 | 10 |
| Honey stripe, Moonlit, Meadow | Plus | Plus (same) | | | | |

How the gaps come out at each pace:
- **5 words a day:** 12 earned pots over 30 days, on days 1, 3, 6, 7, 9, 12, 15, 18, 21, 24, 27 and 30. The gap is never more than 3 days.
- **3 words a day:** the gap is never more than 5 days. Dewdrop fills the first long gap, on days 5 to 10.
- **15 words a day:** about one pot a day.

The first sitting still gives one pot, or two for a keen child. The rungs sit every 5 plants (15 words), so the gap is the same wherever the player is. Without Jade vine, level 5 would have no halfway pot and a 3-words-a-day child would wait 10 days at the very end, which the critic flagged.

**Research on pacing:** a quick research pass found little hard data. These points come from sources:
- The ICO Age Appropriate Design Code warns against nudges that stretch children's time, naming streaks as an example.
- Pocket Camp gates its cosmetics on level.

These points are common practice, not sourced:
- Rewards come quickly at first, then further apart.
- Young children need visible progress between rewards.

A gap of 2 to 3 play sessions is a sensible ceiling to playtest with 5–6 and 7–8 year olds. The progress bar that already exists covers the time between rungs.

## 3. Unlock mechanics

| Mechanic | Use? | Why |
|---|---|---|
| Finish level N | **Yes: one capstone pot per level** | Clear for a child ("finish level 2"). It matches the exotic climb, and the level badge already counts it the same way. |
| Plants grown N | **Yes: one halfway pot per level** (5, 15, 25, 35, 45) | Fills the gap between capstones. Terracotta at 1 plant stays the first-sitting reward. |
| Garden Days 7 (any days) | **Yes: one pot (Dewdrop)** | It rewards coming back without ever punishing a gap. `gardenDays` never goes down (StreakEngine) and merges by max (DataReconciler), and `FeatureUnlockPolicy` already uses it. A child who doesn't like words still gets this pot on time. Show it only as a count up ("3 of 7 garden days"), never as a countdown. |
| Streak (days in a row) | **No** | A streak can drop back to 1, so a goal tied to it can feel lost. Streaks are also the nudge that regulators name. |
| A plant at stage 4 | **Not now** (candidate later) | Good for children who love tending, but how fast stages come depends on the tending economy, which is still changing. It would also be a fourth kind of unlock to explain. If it is wanted later, the hint would be "Grow one plant all the way up." |
| Badges | **No** | One thing the child does would earn two rewards, and the pot list would be tied to the badge list (36 badges are planned). |

**Progress line for level pots.** Today a level pot's bar counts levels ("3 of 5 levels finished"). With a capstone on every level that reads "0 of 1 levels finished", and the bar stays still for 30 words. Count that level's plants instead: **"6 of 10 plants in level 3"**, with the tip line "4 more plants to go!" or "One more plant to go!". The level-count `toGoOne` and `toGoMany` lines can then go. Garden Days uses **"3 of 7 garden days"**.

### Hint copy (reading level grade 1–2, works read aloud)

| Pot | Hint | Progress line |
|---|---|---|
| Sage glaze | Grow 5 plants to earn this pot. | 3 of 5 plants grown |
| Sunflower | Finish level 1 to earn this pot. | 6 of 10 plants in level 1 |
| Mint | Grow 15 plants to earn this pot. | 12 of 15 plants grown |
| Blossom | Finish level 2 to earn this pot. | 4 of 10 plants in level 2 |
| Living stones | Finish level 3 to earn this pot. | (same pattern) |
| Flytrap | Grow 35 plants to earn this pot. | 31 of 35 plants grown |
| Starlight | Finish level 4 to earn this pot. | (same pattern) |
| Jade vine | Grow 45 plants to earn this pot. | 41 of 45 plants grown |
| Rainbow bark | Finish level 5 to earn this pot. | (same pattern) |
| Dewdrop | Play on 7 different days to earn this pot. Any days count! | 3 of 7 garden days |

A 7-year-old knows "level" from the game, and "Finish level 2" is the shortest true sentence. "Any days count!" tells the child that skipping a day is fine, without using the words "in a row" or "miss". "Living stones" names the plant the child grew (Lithops, which are also called living stones). "Desert stone" did not name anything the child would recognise.

### Banned-word check

Every proposed name, hint, a11y label and progress line was run through the same word-boundary match as `CopySafety.check`. The full list is: miss, lonely, alone, waiting, abandon, neglect, forgot, forget, die/dies/died/dying, dead, lost, empty, left, broken, lose streak, broken streak, last chance, hurry, now or never, expires, only, last, smart, genius, talented, best gardener, better than, beat. Result: **0 hits**.

Watch-outs for the implementer: never write "only 2 left" or "last level" in a progress line, and never call Rainbow bark "the last pot".

## New pot specs

Colours are 0xRRGGBB. Patterns use the shared 120 x 100 pot box, clipped to the body and drawn before the rim, exactly like the existing kinds. Each new kind is a new decoration kind, which keeps the rule that every pot has its own pattern. They are built only from rects, capsules, circles, ellipses (the existing `petal`), triangles, and one small fixed teardrop path. So `PotMark.Shape` needs two new cases: `triangle` and `teardrop`. Exact coordinates are in `pots.json` under `proposal.newDecorations`.

| id | Name | Body / rim / shade | Pattern kind (colours) | Unlock | a11y |
|---|---|---|---|---|---|
| blossom | Blossom | 0x9A6A9E / 0xBE93C2 / 0x7A4F7E | `blossoms` (0xFFE6EE petals, 0xF2C14E centres) | level(2) | Plum pot with pink blossoms |
| livingStones | Living stones | 0xDDBB8E / 0xECD3AE / 0xB89262 | `pebbles` (0x55663A stones, 0x3B2E22 clefts and sand specks) | level(3) | Sandy pot with little living stones |
| flytrap | Flytrap | 0x4E8A3A / 0x7BB25C / 0x3A6C2B | `zigzag` (0xF29A8A teeth, 0xFFFFFF dew dots) | plants(35) | Green pot with flytrap teeth |
| jadeVine | Jade vine | 0xE9EEF0 / 0x4FA89A / 0xC4CED2 | `vine` (0x3FB8A6 claw flowers, 0x2F6B4A stems) | plants(45) | White pot with hanging jade flowers |
| rainbowBark | Rainbow bark | 0x8A7B63 / 0xAA9B80 / 0x6E6150 | `bark` (0xEE8A3C, 0x8C5BA6, 0x4E8FC4, 0xB5474A) | level(5) | Brown pot with rainbow bark stripes |
| dewdrop | Dewdrop | 0x9686CC / 0xB9ADE3 / 0x7666B0 | `drops` (0xE3F2FC drops, 0xFFFFFF sparkles) | gardenDays(7) | Lilac pot with dewdrops |

Pattern sketches, in the 120 x 100 box. The mockup draws from the same numbers.

```svg
<!-- blossoms: 5 five-petal flowers; petal = circle r4.6*s at 5*s from centre, every 72 deg; centre r2.4*s -->
<g transform="translate(62 68) scale(1.15)"><circle cy="-5" r="4.6"/><!-- x5 rotated --><circle r="2.4"/></g>
<!-- flowers (cx,cy,s): (40,44,1) (78,40,.85) (62,68,1.15) (36,76,.75) (86,72,.8) -->

<!-- pebbles (Lithops): 3 domes, each an ellipse plus a cleft capsule down from its top -->
<ellipse cx="64" cy="64" rx="14" ry="12"/><rect x="62.7" y="52" width="2.6" height="14.4" rx="1.3"/>
<!-- domes (cx,cy,rx,ry): (40,72,13,11) (64,64,14,12) (86,76,11,9); sand specks r1.6 at 60% -->

<!-- zigzag (flytrap jaws): top band with 7 teeth down, bottom band with 5 teeth up, a dew dot at each top tip -->
<rect x="18" y="20" width="84" height="6"/><path d="M18 26H30L24 38Z"/><!-- teeth at x 24..96 step 12 -->
<rect x="18" y="86" width="84" height="14"/><path d="M30 86H42L36 74Z"/><!-- teeth at x 36..84 step 12 -->

<!-- vine (jade vine): stem band under the rim, 3 drop stems, 7 clusters of 3 hanging claws -->
<rect x="18" y="26" width="84" height="4"/><rect x="39.5" y="30" width="3" height="26" rx="1.5"/>
<ellipse cx="30" cy="19" rx="3.2" ry="7.5" transform="rotate(180 30 30)"/><!-- and 155, 205; anchors in pots.json -->

<!-- bark: 14 rounded bars, width 9, in 4 colours, staggered so the brown body shows between them -->
<rect x="19.5" y="20" width="9" height="26" rx="4.5"/><!-- full list in pots.json -->

<!-- drops: 6 teardrops plus 2 small sparkles -->
<path d="M0 -9C4 -3 6 0 6 3A6 6 0 0 1 -6 3C-6 0 -4 -3 0 -9Z" transform="translate(50 70) scale(1.3)"/>
```

**Telling pots apart.** All 16 were checked at 44 pt in colour, grey, deuteranopia, protanopia and tritanopia, in both themes. Where two pots sit close, they differ by shape:
- Mint and Dewdrop: round dots against teardrops.
- Honey stripe and Rainbow bark: even, full-height cream bars against short, staggered bars in many colours.
- Sage glaze and Flytrap: drips against triangle teeth.
- Meadow and Jade vine: a grass band at the bottom against claws hanging from the top.

Revision 1 changed these, following the critic:
- Blossom's body is lighter (0x9A6A9E, was 0x7B4F7E), so it no longer merges with Starlight and Moonlit in grey or on the dark card.
- Living stones has bigger, darker domes.
- Rainbow bark has a brown body, so it no longer shares Flytrap's green.

Known soft spot: Jade vine's white body on a white light-theme card is held by its teal rim, the same way Meadow is today.

**Grid impact.** 16 pots in a 4 x 4 grid at every text size. That is the layout the accessibility sizes already use, so the 5-column layout can go. Chips are about 85 pt wide at 390 pt. The sheet grows by two rows (about 180 pt). Check that the soil choices and the button stay visible without scrolling on a 4.7-inch screen; if they don't, let the pot grid scroll inside the sheet. The Shed grid becomes 6 rows of 3.

## 4. Edge cases: nothing earned is taken away

The risk: unlocks are worked out from play, not stored. If any threshold moved later, a child could open the Shed and find a pot they had used now showing as "to earn".

1. **Never move a threshold later.** This proposal only moves goals earlier. A player who owned a pot under the old rule owns it under the new one. For the two level moves, this holds as long as levels are finished in order, which `wordLevel` and `selectableLevels` ensure in normal play.
2. **Keep the old rule as a fallback anyway.** Add `legacy: [Unlock]` to `Pot`; a pot is owned if the current rule passes **or** any legacy rule passes. This covers anything outside the in-order assumption: sync merges, restored backups, and test fixtures (today's tests build `finishedLevels == [3]` alone). It costs one array per pot and makes the guarantee unconditional and testable.
3. **Never rename or remove a pot id.** Unknown ids fall back to plain blue, so removing a pot would visibly change a plant's pot. (`livingStones` is a new id; nothing has shipped under `desertStone`.)
4. **A pot already on a plant stays on it.** This is already the rule: `canChoose` always lets the current pot stay. Keep it for the new pots.
5. **Restore hole (owner decision).** Restoring an older backup with fewer plants or garden days can still hide a pot, because nothing is stored. The fix is a stored, union-merged `earnedPotIds` set: a pot is owned if it is in the set or its rule passes, and the set only ever grows. The pick result is added to the set each time pots are evaluated. This partly reverses "never stored", but only in the safe direction. It also enables the next point.
6. **The flood after the update.** When the update lands, an existing player at, say, 30 plants suddenly owns up to 5 more pots, with no moment to notice them. With `earnedPotIds`, show one calm line the first time the picker or Shed opens: "New pots in your shed!". Without it, show nothing; finding them later is still pleasant.
7. **Plus is unchanged:** 3 pots. A Plus pot already on a plant stays after Plus ends. Choosing a new one needs Plus.

## Implementation outline (for a later worker)

`WordFlora/Rules/PotCatalog.swift`
- `Pot.Unlock`: add `case gardenDays(Int)`. `Pot`: add `let legacy: [Unlock]`, defaulting to `[]`.
- `Decoration.Kind`: add `blossoms, pebbles, zigzag, vine, bark, drops`. `PotMark.Shape`: add `triangle(x1,y1,x2,y2,x3,y3)` and `teardrop(cx, cy, scale)`. Ellipses reuse `petal`: pebbles use distance 0, and vine claws use distance 11 at 155, 180 and 205 degrees.
- `marks(for:)`: add the six new cases, using `pots.json` `proposal.newDecorations` exactly.
- `all`: 16 pots, in climb order (which is also the picker order): plainBlue, terracotta, sageGlaze, sunflower, mint, blossom, rosePink, livingStones, flytrap, starlight, jadeVine, rainbowBark, dewdrop, honeyStripe, moonlit, meadow.
- Changed pots, each keeping its old rule as `legacy`:

  | Pot | New rule | `legacy` |
  |---|---|---|
  | sageGlaze | `.plants(5)` | `[.plants(10)]` |
  | sunflower | `.level(1)` | `[.level(3)]` |
  | mint | `.plants(15)` | `[.plants(50)]` |
  | starlight | `.level(4)` | `[.level(5)]` |

  Use the hints from the copy table.
- `Stats`: add `gardenDays` and `plantsInLevel: [Int: Int]`. `stats(plants:gardenDays:)` takes the days from `PlayerProfile.gardenDays`.
- API ripple: these functions take `Stats` in place of separate `plantsGrown` and `finishedLevels` arguments: `state(of:)`, `canChoose`, `progress`, `progressLine`, `tipLine`. Remove `levelProgress`. The callers to update:
  - `App/AppModel+Pots.swift` (`potStats` lines 6–8, plus `potState` and `canChoose`)
  - `Views/PotPickerViews.swift` lines 60, 82, 126, 208, 210, 265
- `state(of:)`: a pot is owned if `passes(unlock) || legacy.contains(where: passes)` (plus `earnedPotIds`, if decision 5 is taken).
- `progress`: for a level pot, `now = plantsInLevel[n]` and `goal = 10`; the bar is full once the level is finished. For a Garden Days pot, `now = min(days, n)`. New copy: `progressLevelPlants`, `progressDays`, `toGoPlantOne`, `toGoPlantMany`.

Views: in `PotPickerViews.swift`, use a 4-column grid at every size. Check the sheet height on the smallest supported phone. The Shed gets 6 rows.

Tests: these existing tests in `WordFloraTests/PotCatalogTests.swift` will break and need updating:
- `testTenPotsInTheMockOrderWithUniqueIds`: the id list, and the counts of 10 ids, names and kinds, which become 16.
- `testPlantUnlocksAtTheirBoundaries` and `testLevelUnlocksAtTheirBoundaries`: the new boundaries.
- `testALevelPotNeedsThatLevelFinishedNotJustThatManyLevels`: today it asserts that Sunflower is not owned with levels `[1,2,4]`, and Starlight with `[1,2,3,4]`. Under the new rules both are owned. Keep the test's intent with fixtures that leave out the pot's own level.
- `testChoosingNeedsTheStateButThePotInUseAlwaysStays`: Mint at 49 plants becomes choosable. Use Flytrap at 34 instead.
- `testProgressLines`: every level line becomes "N of 10 plants in level L".
- `testEveryNameHintAndLineIsKind`: extend it to the new strings and templates.

New tests:
- **Grandfather test:** write the v1 table (10 pots, old rules) into the test. For every `plantsGrown` in 0...50, every subset of finished levels, and `gardenDays` in 0...10, assert that a pot owned under v1 is owned under v2.
- **Monotone ladder:** day estimates (`3k - 2`, level = 10 plants) rise along `all` for the free-earned pots, and no two pots share a rung.
- **Level progress:** a level pot's progress uses that level's plants, and a finished level shows a full bar.
- **Dewdrop:** not owned at 6 garden days, owned at 7, and still owned after a merge (max).
- **Patterns:** mark counts for each new kind, and every colour index in range.
- **UI:** the pot-picker accessibility audit at accessibility text sizes with 16 pots; update its expected counts.

## Critic review (one pass)

| Area | Score | Result |
|---|---|---|
| Arithmetic | 4/5 | All numbers checked correct. The "gaps about 5 days at 3 a day" claim was false, because of a 10-day gap at the end. **Fixed:** Jade vine fills the L5 halfway rung, and Dewdrop is now stated as the 7th day played. |
| Grandfathering | 4/5 | Holds, and the legacy OR covers out-of-order sets. The restore hole and the post-update flood are **now listed** as decision 5 (`earnedPotIds`). |
| Ladder and visuals | 3/5 | **Fixed:** Blossom is lighter; the stones are bigger and darker and renamed Living stones; Rainbow bark has a brown body; the L2 label now includes orchid. **Not taken:** moving Flytrap to L3, because the threshold limits on Rose pink and the plain pots fill every slot up to 25 plants. Flytrap is themed on the L4 sundew instead. |
| Kid copy | 4/5 | **Fixed:** "Living stones", and the hint "Play on 7 different days... Any days count!". |
| Garden Days | 4/5 | Guilt-free. Count up only, never a countdown (added). |
| Implementation outline | 3/5 | **Fixed:** the breaking tests and API callers are listed, and the field name is corrected to `PlayerProfile.gardenDays`. |

## Decisions needed from the owner

1. Approve the ladder: 16 pots, 6 new, 4 goals moved earlier. Sunflower becomes the L1 capstone and Starlight the L4 capstone.
2. Dewdrop: approve it as a Garden Days pot (any 7 days), or drop it and keep 15 pots, all earned through words.
3. Approve showing level-pot progress as "plants in this level" instead of "levels finished".
4. Approve the legacy-rule fallback (owned = new rule OR old rule) as the standing grandfather policy.
5. Add a stored, union-merged `earnedPotIds`? It closes the restore hole and allows a one-time "New pots in your shed!" line, but it bends "unlocks are never stored".
6. Grid: 4 x 4 at every text size, replacing today's 5 x 2. Accept it, or keep 5 columns (4 rows, with one pot alone in the last row).
7. Confirm whether "first plant instant" happens once per game or once per level. Day numbers move by up to a day.
8. Are the names "Flytrap" and "Jade vine" OK? Alternatives: "Snappy", "Jade flower".

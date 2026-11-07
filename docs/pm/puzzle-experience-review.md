# Puzzle experience review: the ABC letter game screen

Date: 2026-11-06. Branch `3-feat-content-and-polish`. Read-only review: no build and no simulator were run.

**Scope.** The main guess-the-word screen: top bar, flower and petals, clue card, letter tiles, keyboard, Help, the win and resting cards, the Daily Bloom, the Speed bloom ring, and the wake and weather puzzle variants. At the owner's request this is mainly a **visual** review. A short UX section follows.

**Sources**
- Screenshots: the scratchpad `shots/` folder (all 1206 x 2622 px, 3x, iPhone 17 Pro, 402 x 874 pt):
  - `b2/game-start.png` and `b2/game-two-wrong.png` (6 Nov build, light);
  - `fid-game-light.png`, `fid-game-dark.png` and `fid-game-ax5.png` (5 Nov build);
  - `resting.png` (5 Nov build).
- Code: `GameView.swift`, `KeyboardView.swift`, `WordTilesView.swift`, `FlowerView.swift`, `Haptics.swift`, `Theme.swift`, `Spacing.swift`, `GameViewModel.swift`, `HelpLadder.swift`, `SpeedBloom.swift`, `WakePuzzle.swift` and `WeatherPuzzle.swift`.
- Colour assets: `Assets.xcassets/*.colorset`.
- Content: `Resources/Words.json`. The clues live in Words.json, not Plants.json.
- Earlier audits: `docs/pm/app-vs-mockups.md` and `docs/pm/spacing-audit.md`.
- Mockups: `design-preview/screens/game.html`. It is the old text-field design, so it is used here only for tile and clue styling.

**Before/after mockup for the top 3 fixes:** `design-preview/puzzle-visual/index.html`. It is not rendered: Chromium is not installed on this machine, so open it in any browser.

**Contrast figures** are computed from the colour assets with the WCAG formula.

**Labels**
- Severity: **must**, **should** or **nice**.
- Size: **S** (under 1 hour) or **M** (half a day).
- Release: **R1** (fits the first release) or **Later**. Nothing here is cut; the owner gates scope.

## Screenshot coverage gaps (re-shoot before sign-off)
The existing shots use the test bank ("A test hint", the five-letter LOTUS). There is no shot of any of these:
- a real 2-3 line clue;
- a word of 10 or more letters;
- a correct (green) key;
- revealed tiles mid-round;
- the Speed bloom ring;
- the win card;
- the Daily Bloom.

Several findings below come from the code alone and should be confirmed on a fresh capture. In particular:
- `fid-game-ax5.png` predates the "Hel / p" fix;
- `resting.png` is from 5 Nov, but the code behind its issue (V6) has not changed since, so that issue is still live.

## Measured layout (from `b2/game-two-wrong.png`, in points)
| Element | Size / position | Note |
|---|---|---|
| Side margin | 12 (spec gutter is 16) | kept on purpose for the keyboard (spacing-audit) |
| Top bar | 44 high, "Level 1" centred at x ~185 (screen centre 201) | 16 pt left of centre |
| Flower | frame 170 high (rendered ~142 x 170; design scale 0.71) | |
| Clue card | ~93 high for one line + "Simpler clue" | radius 16, 1 pt border at 8% |
| Tiles | 30 x 42, gap 6, radius 10, border 2 | the smallest letters on screen besides the clue |
| Empty band, tiles to keys | **~215** | 25% of the screen |
| Keys | row 1 ~33 wide, row 2 ~37, row 3 40; all 50 high; gap 5 h / 8 v; radius 9 | three different key widths |

## Visual findings

### V1. Long words run off the screen. must, M, R1
- **Where:** `WordTilesView` sizes each word as an `HStack` of fixed 30 pt tiles. `FlowLayout` only wraps *between* words, so one long word is never shrunk.
- **How much fits:**
  - the column is 362 pt on a 402 pt phone, which fits 10 letters;
  - the column is 335 pt on a 375 pt phone, which fits 9 letters.
- **How many words overflow:** 31 entries have a single word of 11 to 14 letters. Examples: PHOTOSYNTHESIS, METAMORPHOSIS, HUMMINGBIRD, PASSIONFLOWER, and WELWITSCHIA at level 3. Another 23 ten-letter words overflow on 375-393 pt phones. The trailing tiles render past the edge and the player cannot see how long the word is.
- **No screenshot shows this yet.** Confirm with a long-word capture.
- **Fix:**
  - Give `WordTilesView` the available width (with `onGeometryChange` or a custom `Layout`).
  - Use `tileW = min(40, floor((width - (n-1)*6) / n))`, where `n` is the letter count of the longest word, and `tileH = tileW * 1.3`.
  - Set the letter font to `tileW * 0.75`, heavy, rounded.
  - Keep a floor of 22 pt and drop the gap to 4 pt below 26 pt.
- **Mockup:** `design-preview/puzzle-visual` shows PHOTOTROPISM at 25 pt tiles.

### V2. A dead band in the middle; everything important is small. should, M, R1
- **Where:** `b2/game-two-wrong.png` and `fid-game-light.png`. About 215 pt of empty cream sits between the tiles and the keys. Meanwhile:
  - the flower (the lives display) is only 142 pt wide;
  - the tiles (the goal) are only 30 x 42.
- **Already reported** in `app-vs-mockups.md` ("Empty middle"); it is still the case.
- **Fix (in `GameView` body):**
  - Change the flower to `.frame(minHeight: 170, maxHeight: 240)` with `.layoutPriority(1)`.
  - Replace the single `Spacer(minLength: 4)` above the keyboard with three flexible spacers in a 2 : 1 : 3 ratio: above the flower, between the flower and the clue, and above the keys. Use `minLength: Space.s`.
  - Default the tiles to 40 x 52 when they fit (V1 shrinks them for long words).
  - On a 402 x 874 phone this gives a flower of about 236 pt and still leaves ~80 pt of breathing room.
  - On a 375 x 667 SE the flower stays at 170.

### V3. Key states: dark-mode correct keys fail contrast; used keys are hard to read. must, S, R1
- **Where:** `KeyboardView.background/foreground`.
- **Correct key:**
  - Dark: white on `successText` dark `#81C784` is **2.0:1**. The letter the child just got right is the hardest one to read.
  - Light: white on `#2E7D32` is 5.1:1, which is fine.
  - Fix: add a colour asset `keyCorrectText` (light `#FFFFFF`, dark `#1A2E1A`); dark gives 7.2:1.
- **Wrong key:**
  - The letter is `appPrimaryText` at 45% on danger at 22%: 2.3:1 light and 2.7:1 dark. The disabled-control exemption technically applies, but kids scan these letters to remember what they tried.
  - Fix: raise the letter to 70% (4.0:1 light, 4.3:1 dark) and the x and check glyphs from 9 pt to 11 pt black. Keep the pink fill.
  - Dark, seen in `fid-game-dark.png`: danger at 22% over `#2C3E2C` reads as muddy brown. Use `appDanger.opacity(0.30)` in dark for a clearer rose.
- **Unused key:**
  - The white key on cream is 1.07:1. Its edge comes only from a 14% border (1.28:1).
  - Fix: add `.shadow(color: Color.appPrimaryText.opacity(0.22), radius: 0, x: 0, y: 1)`, an iOS-keyboard style lip, so keys read as tappable.
- **Pressed state:**
  - Today it is only a scale of 0.94 over 0.08 s, with no colour change.
  - Fix: add `appPrimaryText.opacity(0.08)` over the fill while pressed, so the tap is visible under the finger.

### V4. Blanks are too faint to count. must, S, R1
- **Where:** an unrevealed tile has `appPrimaryText` at 18% for its 2 pt border. That is **1.37:1** on cream in light mode and 1.66:1 in dark, below the 3:1 that WCAG 1.4.11 asks of UI parts. The number of blanks is the word length, which is core game information. In `game-start.png` the five boxes are visible but pale; on an outdoor screen they disappear.
- **Fix:** raise the border to 55% (3.0:1 light, 4.6:1 dark). Optionally fill blanks with `appSurface` plus a 3 pt bottom bar in `appPrimaryText` at 55%, so they read as "a letter goes here".

### V5. Keyboard rows use three different key widths and no stagger. should, S, R1
- **Where:** `minWidth 28, maxWidth 40`, with each row filling its own width.
  - Row 1 is ~33 pt wide.
  - Row 2 stretches to ~37 pt and sits flush with row 1, so there is no half-key offset.
  - Row 3 caps at 40 pt.
- **Result:** in `b2/game-two-wrong.png` the A-L row looks heavier than QWERTY and the board looks home-made next to the system keyboard kids know.
- **Fix:**
  - Compute one key width, `(width - 9*5) / 10`, and apply it to every row, centred. Row 2 then indents half a key and row 3 a key and a half, as on iOS.
  - Optionally widen the gap to 6 h / 10 v.
  - Trade-off: row 3 keys drop from 40 to ~33 pt wide. They are still 50 pt tall, as on the system keyboard.

### V6. The resting and win cards collide with the top bar; red keys show behind. must, S, R1
- **Where:** `resting.png`. "Level 1", Home and Help peek out above the card, and the card's top edge cuts through the "Level 1" letters. Nine pink x keys stay visible behind a calm "This one's resting" card.
- **Cause:** `cardIsModal` covers only `showBreak || showRestCard`. The `.restingOffer`, `.rested` and `showEarned` cards use `dimmed(centered: false)`, so they are pinned 24 pt from the top over a live top bar.
- **Same issue in the win card** (`earnedCard`): it sits under the 45% `winDim` with the header and keyboard still in the hierarchy.
- **Already flagged** as a must in `app-vs-mockups.md`. Still open in code.
- **Fix:**
  - Extend `cardIsModal` to `vm.phase == .restingOffer || vm.phase == .rested || showEarned`.
  - Pass `centered: true` to those three `dimmed` calls.
- **Result:** only the dimmed flower shows behind them, matching the rest and break cards and the mockup.

### V7. The type hierarchy is inverted in the top bar and flat in the play area. should, S, R1
- **Top bar:**
  - `Theme.font(.headline)` defaults its weight to `.regular`, which overrides headline's semibold. "Level 1" therefore renders lighter than the semibold "Help" beside it (`b2/game-two-wrong.png`).
  - The title also sits 16 pt left of centre, because Home is 44 pt wide and Help is about 90 pt.
  - Fix:
    - Use `Theme.font(.headline, weight: .semibold)`.
    - Lay the bar out as a `ZStack`: the title centred, and Home and Help in an `HStack` with a `Spacer` between them.
- **Play area:**
  - Clue: body 17 regular. Tiles: title2 heavy, 22 pt. Keys: title3 bold, 20 pt. The answer is barely larger than the keys.
  - Target hierarchy:
    - tiles at `.title` heavy (28 pt in 40 x 52 tiles);
    - clue at `.body` medium, 17 pt;
    - keys at title3 bold, 20 pt.
  - Add a small "CLUE" eyebrow (caption, bold, 0.1 em tracking, secondaryText) as in `screens/game.html`. It tells a new reader what the sentence is for.

### V8. The tiles do not grow with Dynamic Type. should, S, R1
- **Where:** tiles are a fixed 30 x 42 with an unbounded `.title2` letter and no `minimumScaleFactor`.
- At AX sizes the letter grows past the tile. `fid-game-ax5.png` shows only blanks, so this is still unverified.
- The keys in that same shot also spill their letters ("QWERTYUIOP" run together). The later fix (scale to fit) needs a fresh AX5 capture.
- **Fix:** after V1, scale the tile with `@ScaledMetric(relativeTo: .title) var tileBase = 40`, clamped by the V1 width rule, and add `.minimumScaleFactor(0.5)` to the tile letter.

### V9. The flower reads well, but the ghosts and colour steps need care. should, S, R1 (ghost) / nice, S, Later (palette)
- **Ghost on the stem:**
  - `lossOrder = [0, 4, 2, ...]` drops the bottom petal second. Its dashed ghost (`#7C867C` at 55%, 1.6 pt) then lies over the stem.
  - In `fid-game-dark.png` this reads as a broken stem, not a lost petal.
  - Fix: use the order `[0, 1, 7, 2, 6, 3, 5, 4]`, top first and spreading down, so the bottom petal goes last. Or skip the stem petal's ghost.
- **Palette steps:**
  - The whole flower changes colour at 6, 4 and 2 petals: pink, then orange, then mauve, then blue-grey.
  - The change is a good "health" cue, but at 6 petals the flower suddenly looks like a different species, and the 3-4 petal mauve (`#C7A9B0`) is the same colour as the resting bud.
  - Fix (nice): keep the hue and step saturation and lightness instead (pink `#F2788A`, then `#E99AA6`, then `#D9B5BC`, then `#B9C3CF`).
- **No count:** there is no visible petal count. The `app-vs-mockups` suggestion still stands: a small caption under the flower, "6 petals to go" (caption, secondaryText). It matters for kids who cannot tell 5 from 6 dashed outlines. should, S, R1.

### V10. The Speed bloom ring is thin and its track is invisible on cream. should, S, R1
- **Where:** `FlowerView.goldRing`. It is 152 design units across with a 5-unit stroke. At the 0.71 flower scale that renders as a ~108 pt ring with a **3.5 pt** line.
  - The track, `#F5C858` at 28%, is about 1.1:1 on `#FAF7F0`, so in light mode the ring looks like it starts from nothing.
  - The gold `#E8A838` is the same colour as the flower centre and the amber revealed tiles, so the ring does not read as its own element.
- **No screenshot exists.** Capture the 50% and relaxed states.
- **Fix:**
  - Set the stroke to 7 design units (~5 pt rendered).
  - Use track opacity 0.45 in light and 0.28 in dark.
  - Use `#D99A2B` for the fill in light only, so it separates from the centre.
  - Add a 6 pt dot at the arc head so motion is legible without numbers.
  - With V2's larger flower the ring grows to ~150 pt.
- **"Take your time":** the capsule sits on the stem area (`overlay(alignment: .bottom)`). That works. Give it a `.shadow(radius: 2, y: 1)` so it does not merge with the leaves.

### V11. The clue card is mostly fixed; check real clue lengths. should, S, R1
- **Current state:** in `b2/game-two-wrong.png` the speaker is now centred on the one-line clue (spacing-audit, fixed). The card is ~93 pt with "Simpler clue".
- **Remaining issues:**
  - Real clues run up to 17 words (FERN, ROSE, BLEEDING HEART), which is three lines at 17 pt in a 338 pt column. That pushes the tiles down while the speaker stays centred against three lines. Pin the speaker to `.top` when the clue wraps past one line (`ViewThatFits`, or `alignment: .firstTextBaseline`).
  - Help's second clue (`extraHint`) shows in callout secondaryText under a `Divider`. It is legible, but the new line has no "new" cue. Fade it in with a 0.25 s marigold wash to match the tile pop.
  - The card uses the 12 pt gutter. Move the clue card and tiles to `Space.gutter` (16) so they line up with every other screen, and keep 12 only for the keyboard.

### V12. Help does not look like a button. should, S, R1
- **Where:** a plain glyph and label in `appPrimaryText`. The disabled state is the system's faded grey, and the pulse only starts after 2-3 misses.
- **Fix:** a capsule with `tileGardenFill` behind it, 36 pt visual height, 44 pt hit area, and the bulb in `accentText`. When disabled (the help ladder is used up), keep the capsule at 40% opacity so the bar does not change shape. Kids then see Help as something to press on their first word.

### V13. Corner radius and gutter consistency. nice, S, Later
- **Corner radii:** keys 9, tiles 10, clue card 16 (`cardRadius`), buttons 18 and modal cards 24. Set keys to 10 to match the tiles. The rest follows the Theme tokens.
- **Gutters:** the game uses 12 and every other screen uses 16. See V11 for the clue and tiles; the keyboard keeps 12 on purpose.

### V14. The moment between rounds is visually thin. should, M, R1 (meter) / nice, Later (auto-advance)
- **Where:** `earnedCard`, no-plant branch. When a word only moves toward the next plant, the card shows a title and one line of text. The code even marks it as an unfinished slot: `// HOOK (progress meter)`.
- **Fix:** the words-toward-plant meter it names: N seed pips, filled in `appAccent`, `PetalPipRow` style, 12 pt pips with 6 pt gaps. The last pip fills with the tile pop's spring of 0.3 s response and 0.6 damping.
- **Later:** for progress-only wins, show a 1.2 s toast over the flower instead of a modal, so the rhythm is word, tap Continue, word, without a blocking card each time.

### Polish already right (keep)
- Each correct letter pops its tile to 1.1x with a marigold wash and a petal puff. Spring of 0.3 s response, 0.6 damping.
- A lost petal falls in 0.9 s ease-in with a ±70 pt drift (0.3 s fade with Reduce Motion).
- The win dims in 0.3 s and the card arrives 0.7 s later.
- Each action gets exactly one haptic: light for a hit, soft at 0.7 for a miss (never `.error`), success on a win.
- Used keys carry a glyph as well as colour.
- Keys are 50 pt tall, above the 44 pt minimum.
- The sway stops behind modal cards.

## UX notes (short)
1. **Two clue styles are mixed** (should, S, R1). 15 hero clues from an older pass are denser, longer and lack a final period. Examples:
   - FERN: 16 words, with "fiddleheads" and "spores";
   - ROSE: "shrub", "famous";
   - CHERRY BLOSSOM, SILVERSWORD, ALOE VERA.

   30 hints in total lack a period. The newer clues are short and kid-friendly ("A small green plant with three round leaves.").

   **20-clue sample (grade-level estimates):**
   - The level averages run from grade 2.3 to 3.5, with a mean of 8-10 words, so most clues are fine.
   - The outliers are those 15 hero clues, at grade 5-9.
   - `hint2` is usually *simpler* than `hint` (grade 1.4-3.2), so Help's first rung is easier than the clue itself.

   **Fix:** rewrite the 15 hero clues to the newer house style, and add periods.
2. **Difficulty curve.**
   - Average answer length by level: 4.3, then 6.1, 8.1, 9.4 and 10.5 letters.
   - Level 5 is mostly science vocabulary (PHOTOTROPISM, COTYLEDON, HERBACEOUS) that a 7-9-year-old reaches only through plant progression.
   - In this game, longer words are *easier*, because each guess reveals more letters. The hardest rounds are the 12 three-letter words at level 1 (DEW, BUD, ANT): the youngest players' first rounds.
   - Fix (should, S): for the first 10 rounds, rank level 1 by `WordDifficulty.expectedMisses` and hold back words of 3 letters and words with 4 or more expected misses.
3. **Help is free and clear in its rules:** the second clue, then the most common vowel, then the first letter, and it never fills the last letter. The button does not say what comes next, though. Nice, S: change the label to "Clue", then "A vowel", then "First letter" as the rungs advance.
4. **When the flower runs out of petals:**
   - The resting card is gentle, says the word, and has "Say it".
   - The wake offer appears only with a Rose of Jericho in hand.
   - The rose line uses footnote text that is too small for the most important "what now" line. Raise it to callout.
5. **Wake and gentle weather puzzles: plant names with no meaning clue.**
   - The hint is only "A plant name with N letters", for names such as LITHOPS or RAFFLESIA. A 7-year-old cannot solve those by anagram without the 30 s peeks.
   - The picture clue exists only on the storm tier.
   - Fix (should, M, R1): offer the picture clue on the gentle tier too, after one peek.
6. **The Daily Bloom** shares the same screen. Its title is "Daily Bloom", with a share button and the big burst on the win card. That is fine. Show the date under the title (caption, secondaryText) so a shared screenshot says which day. Nice, S.

## Priority summary
| # | Finding | Severity | Size | Release |
|---|---|---|---|---|
| V1 | Long words off screen | must | M | R1 |
| V6 | Result cards collide with the top bar; red keys behind | must | S | R1 |
| V3 | Dark correct key at 2.0:1; used keys faint; no key lip | must | S | R1 |
| V4 | Blanks at 1.37:1 | must | S | R1 |
| V2 | 215 pt dead band; small flower and tiles | should | M | R1 |
| V5 | Three key widths, no stagger | should | S | R1 |
| V7 | Title lighter than Help, off centre; flat tile hierarchy; no eyebrow | should | S | R1 |
| V8 | Tiles do not scale with Dynamic Type | should | S | R1 |
| V9 | Ghost on stem, petal count caption (palette is nice/Later) | should | S | R1 |
| V10 | Speed ring thin, track invisible | should | S | R1 |
| V11 | Clue card with real 3-line clues, 16 pt gutter | should | S | R1 |
| V12 | Help reads as text, not a button | should | S | R1 |
| V14 | Progress meter hook unbuilt | should | M | R1 |
| UX1 | 15 dense hero clues | should | S | R1 |
| UX2 | 3-letter words first | should | S | R1 |
| UX5 | Gentle wake puzzle has no meaning clue | should | M | R1 |
| V13, UX3, UX6, V9 palette, V14 auto-advance | polish | nice | S | Later |

# Tend tool bar fit review (plant page)

Date: 2026-11-07. Trigger: owner screenshot "WF G3 iPhone 17 2026-11-07 19.07.49". On the Clover page the done Prune tile reads "Trimme / d", and "Repot" sits close to the edge of its tile.
Source reviewed: G3 worktree at HEAD `35a19a3` (`WordFlora/Components/LifePanel.swift`, `WordFlora/Views/PlantDetailView.swift`, `WordFlora/Theme/Theme.swift`). No builds and no simulator. The G3 builder is fixing the bar; the numbers below were sent to them on the same day.

## 1. How the bar is built (HEAD)

- `PlantDetailView.actionBar`:
  - Non-AX sizes: one `HStack(spacing: 8)` of Water, Feed, Sun, [Prune], [Mist], Repot. That is four, five or six tiles, inside `Space.gutter` (16) on each side.
  - AX sizes (`isAccessibilitySize`): a 2 x 2 `Grid` (Water, Feed, Sun, Repot). Prune and Mist become full-width buttons in the scroll content.
- `TendActionButton`, non-AX layout:
  - A 52 pt dot (44 + 8 ring frame) on top of the words.
  - Words: title `Theme.font(.footnote, .heavy)`, caption `.caption2, .bold`. Both are SF Rounded, `fixedSize(vertical)`, centred.
  - Horizontal padding is 2 pt per side, so text width = tile width - 4.
- `TendActionButton`, AX1 and AX2:
  - The dot (40, framed to 48) sits beside the words, with 10 pt padding and 10 pt spacing.
  - Title `.body .heavy`, caption `.footnote .bold`.
- `TendActionButton`, AX3 to AX5 ("compact"):
  - The dot is on top, the title only (no caption).
  - The title has `lineLimit(1).minimumScaleFactor(0.4)`.
- Strings:
  - Titles: Water, Feed, Sun, Prune, Mist, Repot.
  - Done titles: Had a drink, Fed today, Sunny today, **Trimmed**, Misty today. Seed title: Wake first.
  - Ready captions: Give a drink, Add soil, Let it shine, Give a trim, Mist the leaves, Pick a pot.
  - Needs-supply captions: Can is dry, Need scoops, Need shears, Need the mister.
  - Done and seed captions: **More tomorrow**, Trim in 2 days, Tap the seed.

SwiftUI wraps at spaces. A single word wider than the line breaks between letters. That is the "Trimme / d" bug.

## 2. Method

- Widths were measured with the system rounded font (`.AppleSystemUIFontRounded-Heavy` / `-Bold`, the same face as iOS) through `NSString.size(withAttributes:)`.
- Calibration: on the owner's 402 pt iPhone 17 at Large, "Trimme" measures 48.6 pt on screen; the predicted width is 49.8 pt. Allow about 3%.
- Dynamic Type sizes in pt, ordered xS, S, M, L, xL, xxL, xxxL, AX1, AX2, AX3, AX4, AX5:

| Style | xS | S | M | L | xL | xxL | xxxL | AX1 | AX2 | AX3 | AX4 | AX5 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| footnote | 12 | 12 | 12 | 13 | 15 | 17 | 19 | 23 | 27 | 33 | 38 | 44 |
| caption2 | 11 | 11 | 11 | 11 | 13 | 15 | 17 | 20 | 24 | 29 | 34 | 40 |
| body | 14 | 15 | 16 | 17 | 19 | 21 | 23 | 28 | 33 | 40 | 47 | 53 |

## 3. Space available per tile

Text width per tile = (screen - 32 - gaps) / n - 4.

| Layout | 375 pt (SE) | 393 pt | 402 pt (iPhone 17) |
|---|---|---|---|
| 6 across, 8 pt gaps (HEAD) | 46.5 | **49.5** | 51.0 |
| 6 across, 6 pt gaps | 48.2 | 51.2 | 52.7 |
| 5 across, 8 pt gaps | 58.2 | 61.8 | 63.6 |
| 4 across, 8 pt gaps | 75.8 | 80.3 | 82.5 |
| 3 across, 8 pt gaps | 105.0 | 111.0 | 113.7 |
| AX 2 x 2, words beside dot (tile - 20 - 48 - 10) | 89.5 | 98.5 | 103.0 |
| AX full width, words beside dot | 265 | 283 | 292 |
| AX3+ compact, title only (tile - 12) | 155.5 | 164.5 | 169.0 |

The non-AX dot is a fixed 52 pt. At HEAD on 393 pt the tile is 53.5 pt, so the dot already nearly fills it. That is why "Repot", in the last tile, looks tight against the edges.

## 4. Measured widths (pt). Each cell is whole string / longest word.

### 4a. Titles, footnote heavy (non-AX layout)

| Title | xS-M | L | xL | xxL | xxxL |
|---|---|---|---|---|---|
| Water | 36.8 | 39.5 | 44.9 | 50.2 | 55.9 |
| Feed | 30.0 | 32.2 | 36.5 | 40.9 | 45.5 |
| Sun | 23.9 | 25.6 | 29.1 | 32.7 | 36.3 |
| Prune | 36.4 | 39.1 | 44.4 | 49.7 | 55.3 |
| Mist | 26.9 | 28.9 | 32.7 | 36.6 | 40.6 |
| Repot | 36.6 | 39.3 | 44.6 | 49.9 | 55.5 |
| **Trimmed** | **54.3** | **58.3** | 66.2 | 74.1 | 82.5 |
| Trim (proposed) | 27.6 | 29.6 | 33.5 | 37.5 | 41.7 |
| Had a drink | 69.8 / 31.9 | 74.7 / 34.2 | 84.6 / 38.7 | 94.6 / 43.3 | 105.1 / 48.1 |
| Fed today | 60.9 / 35.5 | 65.3 / 38.1 | 74.0 / 43.2 | 82.7 / 48.3 | 92.0 / 53.7 |
| Sunny today | 77.4 / 39.0 | 83.0 / 41.9 | 94.1 / 47.6 | 105.3 / 53.3 | 117.1 / 59.3 |
| Misty today | 72.7 / 35.5 | 77.9 / 38.1 | 88.3 / 43.2 | 98.7 / 48.3 | 109.7 / 53.7 |
| Wake first | 62.6 / 33.5 | 67.0 / 36.0 | 75.9 / 40.9 | 84.8 / 45.9 | 94.2 / 51.1 |

### 4b. Captions, caption2 bold (non-AX layout)

| Caption | xS-L | xL | xxL | xxxL |
|---|---|---|---|---|
| Give a drink | 64.9 / 28.2 | 74.9 / 32.6 | 84.6 / 36.9 | 94.4 / 41.2 |
| Add soil | 44.4 / 22.2 | 51.2 / 25.7 | 57.9 / 29.2 | 64.7 / 32.8 |
| Let it shine | 60.7 / 30.0 | 69.9 / 34.6 | 78.9 / 39.2 | 87.9 / 43.9 |
| Give a trim | 58.9 / 24.6 | 68.0 / 28.5 | 76.8 / 32.3 | 85.7 / 36.1 |
| Mist the leaves | 83.0 / 35.5 | 95.9 / 41.1 | 108.4 / 46.5 | 121.0 / 52.0 |
| Pick a pot | 54.0 / 23.6 | 62.3 / 27.2 | 70.4 / 30.9 | 78.6 / 34.5 |
| Can is dry | 54.9 / 21.8 | 63.4 / 25.4 | 71.7 / 28.8 | 80.0 / 32.3 |
| Need scoops | 71.4 / 39.8 | 82.7 / 46.1 | 93.8 / 52.3 | 104.9 / 58.6 |
| Need shears | 68.8 / 37.2 | 79.7 / 43.1 | 90.3 / 48.8 | 101.0 / 54.6 |
| Need the mister | 87.5 / 35.1 | 101.1 / 40.5 | 114.5 / 45.9 | 127.9 / 51.3 |
| **More tomorrow** | 83.8 / **53.1** | 97.1 / 61.6 | 110.1 / 69.9 | 123.2 / 78.2 |
| Trim in 2 days | 76.1 / 26.4 | 87.8 / 30.6 | 99.3 / 34.7 | 110.8 / 38.8 |
| Tap the seed | 69.8 / 26.7 | 80.6 / 30.9 | 91.3 / 35.1 | 101.9 / 39.2 |

### 4c. AX layout, longest word (title body heavy, caption footnote bold)

| Word | AX1 | AX2 | AX3 | AX4 | AX5 |
|---|---|---|---|---|---|
| Water (title) | 81.4 | 95.7 | 115.6 | 135.4 | 152.3 |
| Repot (title) | 80.9 | 95.1 | 114.9 | 134.6 | 151.4 |
| Sunny (title) | 86.5 | 101.7 | 122.9 | 143.9 | 161.9 |
| today (title) | 78.3 | 92.0 | 111.2 | 130.2 | 146.4 |
| Trimmed (title, full-width row) | 120.3 | 141.4 | 170.9 | 200.2 | 225.2 |
| tomorrow (caption) | 104.6 | 122.3 | 149.0 | 171.1 | 197.6 |
| scoops (caption) | 78.3 | 91.6 | 111.6 | 128.1 | 148.0 |
| Whole "Sunny today" (compact title) | 170.6 | 200.5 | 242.2 | 283.6 | 318.9 |

## 5. Where words break today (HEAD) and with the builder's draft plan

HEAD, 6 across on 393 pt (49.5):
- **"Trimmed" breaks at every size, xS included** (54.3). This is the owner's bug.
- **"tomorrow" breaks at every size, xS included** (53.1). It appears on any done tile and is the same bug, still hidden.
- xxL: "Water" 50.2, "Repot" 49.9 and "Prune" 49.7 just break. "Sunny" 53.3 and "scoops" 52.3 break.
- xxxL: almost every title breaks, plus "today", "first", "leaves", "mister" and "shears".
- On 402 pt (51.0) the picture is the same; the owner's screenshot shows it.

HEAD, 5 across: "tomorrow" breaks from xL on 393 and from xL on 375.

HEAD, AX:
- 2 x 2 grid: "tomorrow" breaks at AX1 and AX2 on every width. "Sunny" breaks at AX2 on 393.
- At 375, AX2 also breaks "Water", "Repot", "today" and "scoops".
- AX3 to AX5 compact: no break, but the title shrinks (to about 0.52x for "Sunny today" at AX5) and the caption is hidden. In practice that is a Dynamic Type cap, and it may fail the audit's Dynamic Type check.

Builder draft: "Trim", one row of six up to L with 6 pt gaps, two rows of three for six tiles above L, five tiles keep one row, AX unchanged.
- Six across at L and below (48.2 / 51.2 / 52.7): "Trim" fixes the title. **"tomorrow" (53.1) still breaks on every phone.**
- Two rows of three at xL to xxxL (105 to 114): **every word fits**. The largest is 82.5, or 78.2 for "tomorrow".
- Five in one row above L:
  - 375: "tomorrow" breaks from xL. "Sunny" (59.3) and "scoops" (58.6) break at xxxL.
  - 393: "tomorrow" breaks at xxL and xxxL. At xL it fits with only 0.2 pt to spare.
- AX unchanged: the breaks and the shrink listed above remain.

## 6. Recommended fix (keeps iOS 26 accessibility audits passing)

Rules: no `dynamicTypeSize` caps, no `ViewThatFits` switching, text styles only. The layout is chosen from `dynamicTypeSize` alone, so it is deterministic and testable.

1. **Done title "Trimmed" becomes "Trim".** The check badge and "Trim in 2 days" carry the state; the VoiceOver value already says it.
2. **Non-AX: never put more than four tiles in a row.**
   - Five or six tiles always lay out as two rows of three (3 + 3 or 3 + 2), at every non-AX size.
   - The longest word is 82.5 pt against at least 105 pt, on every width from 375 to 402. No copy change is needed and there is no "tomorrow" problem.
   - Four tiles (no Prune, no Mist) may stay one row through L (75.8 pt or more). Above L they go 2 + 2.
   - Cost: one more tile row of height in the pinned bar at default size. If the owner wants one row of six at default size instead, then "More tomorrow" must become words of 46 pt or less at 11 pt bold (375 pt case). That is a copy call for Fable and is not recommended under the scope freeze.
3. **AX: one column of full-width row tiles**, with the dot beside the words.
   - Words get 265 pt or more; the longest AX5 word is 197.6 ("tomorrow").
   - Put them in the scroll content, not the pinned bar. Six rows at AX5 are too tall to pin, and Prune and Mist already live there at AX.
   - Remove the compact branch: no `lineLimit(1)`, no `minimumScaleFactor`, and the caption always shows.
4. Keep `fixedSize(horizontal: false, vertical: true)` on both texts, and the equal-height row.
5. Add a unit test that measures every title and caption word with `UIFont.preferredFont(forTextStyle:compatibleWith:)` in the rounded design and matching weight, for each Dynamic Type size, against the per-tile width at 375 pt. The builder is adding this. Include the done, seed and supply strings, not only the ready ones.

## 7. Other screens with the same risk (not part of the tool bar fix; for triage)

| Screen | Where | Status at HEAD | Risk |
|---|---|---|---|
| Quiet Garden (plant page) | Same tend bar | Same strings; no supply captions; "More tomorrow" stays | **Same breaks as section 5.** The fix above covers it. |
| Visitors book | Sticker grid: `VisitorsBookView` 4 columns (2 at AX), footnote semibold names | 81.3 pt per cell at 393, 75.3 at 375 | **"Snowflake" breaks** at xxL on 393 (81.9) and from xL on 375 (73.3); at xxxL (91.1) everywhere. "Ladybird" (76.6) and "Rainbow" (75.4) break at xxxL on 375. In 2 columns at AX (174.5 / 165.5): "Snowflake" breaks at AX4 (179.0) and AX5 (206.7); "Ladybird" (173.7) and "Rainbow" (171.4) break at AX5 on 375. Fix: 3 columns above L and 1 column at AX, or a row layout. |
| Shed, pot cards | `ShedPotsSection`: 4 columns at all sizes, footnote heavy names; one-word names `lineLimit(1)` + `minimumScaleFactor(0.5)`; two-word names `lineLimit(2)` | Card text 77.8 pt at 393, 73.3 at 375. **Has `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)`**, which breaks the no-caps rule. | Two-word names can break mid-word without shrinking: "Snowflake indigo" from xL (79.0), "Rainbow bark" at xxxL (80.9). One-word names such as "Terracotta" and "Sunflower" shrink instead. Removing the cap makes it worse unless the grid drops to 2 columns above L and 1 at AX. Shrinking text is also a likely audit flag. |
| Seasons | `PackPotsRow`: one pot per row | Safe | Pack pots also appear in the Shed and Repot grids (Snowflake indigo, Lantern red, Frosted glass), with the risk above. |
| Repot sheet, pot tiles | `PotPickGrid`: 4 columns, caption heavy `lineLimit(1)` + `minimumScaleFactor(0.6)`; goal line caption2 `lineLimit(1)` + `0.75` | No mid-word break | Shrinks, then truncates with "..." at large sizes (clipped text is an audit risk). Same column fix as the Shed. |
| Repot sheet, soil chips | 4 columns (2 at AX), subheadline bold `lineLimit(1)` + `0.8` | Chip text about 56 pt at 393 | **"Compost" truncates** from xL (73.8 x 0.8 = 59 > 56). Fix: 2 columns above L. |
| Shed, tool tiles | 2 columns, 1 at AX (already fixed for "Shear / s" and "Mis- / ter") | 159.5 pt; "Watering" 102 at xxxL | Names are safe. The effect line has `lineLimit(2)` at non-AX, which can truncate at xxxL; drop the limit. |
| My Garden, plant cards | 2 columns at **all** sizes; subheadline bold names, `lineLimit(3)` | 150.5 pt at 393, 141.5 at 375 | **"Passionflower" breaks at AX1** (165.0) and up; at xxxL (139.3) it fits on 375 with only 2 pt spare. "Snapdragon" breaks at AX1 on 375 (143.1) and at AX2 on both (171.2). Botanical names (caption italic) too. Fix: 1 column at AX. |
| Home, explore tiles | 2 columns, 1 at AX, body heavy | 159.5 pt; "Visitors" about 90 at xxxL | Safe. |
| Settings | Form rows; Theme is a `.segmented` Picker (System, Light, Dark) | Segment about 98 pt; "System" is 95.7 at AX1 and 112.5 at AX2 if it scales | No mid-word break, but segments truncate or stop scaling at AX sizes. Check on device; a `.menu` or `.inline` picker at AX sizes avoids it. |

## 8. Summary for the lead

- Root cause: six fixed 53.5 pt tiles (49.5 pt of text at 393 pt) with a 52 pt dot. "Trimmed" and "tomorrow" do not fit even at the smallest Dynamic Type size.
- Safest fix: "Trim"; two rows of three for five or six tiles at every non-AX size; one full-width column, in the scroll content, at AX; no compact or shrink branch.
- Biggest related risks: the Garden cards at AX, the Visitors stickers, and the Shed pot grid (which also carries a Dynamic Type cap).

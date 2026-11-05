# Garden Shed v2: chosen direction and SwiftUI guidance

Page: `design-preview/shed-visitors/shed-v2/index.html` (http://localhost:8765/shed-visitors/shed-v2/). Shots: `shots/` (a-*, b-*, c-* = the three directions; p-* = the chosen direction, revised).

## Process
- Three directions: A (shed wall with rows), B (tool tiles), C (pegboard).
- A critic reviewed the nine rendered PNGs and ranked them **B > C > A**. Its fixes were folded into one revision round. Section 2 of the page lists them.
- The chosen direction is **B, tool tiles**. It also takes A's wooden scene, Now/Next lines and pots shelf, and C's jar sitting on a shelf.

## Screen structure (`ShedView`)
```
ScrollView
 VStack(alignment: .leading, spacing: 12) .padding(.horizontal, 20) .padding(.top, 4) .padding(.bottom, 40)
  ShedHeader                      // scene + points bar, one card
  SectionHeader("Tools", "Tap a tool to see what it does.")
  LazyVGrid(columns: isAX ? [.flexible()] : [.flexible(spacing: 10), .flexible()], spacing: 10)
     ForEach(ShedTool.order) { ToolTile }     // can, trowel, net, mister, shears, lamp
  SectionHeader(quiet ? "Your pot shelf" : "Pots", subtitle)
  PotShelf                        // replaces ShedPotsSection grid; 4 per plank, 2 at AX sizes
.sheet(item: $selectedTool) { ToolSheet(...) .presentationDetents([.medium, .large]) .presentationBackground(tint.fill.mix(appSurface, 0.45)) }
.sheet(item: $selectedPot)  { PotSheet(...)  .presentationDetents([.height(320), .large]) }
.overlay { if let up = justUpgraded { UpgradeCard(up) } }
.navigationTitle("Garden Shed") .navigationBarTitleDisplayMode(.inline)
```
`isAX` is `@Environment(\.dynamicTypeSize).isAccessibilitySize`. `quiet` is `app.settings.quietGarden`.

### Colour per tool (existing colorsets only, no new colour assets)
Model it as `ToolTint`, like Home v2's `TileTint`: `fill` is the tile background, `icon` is used for the pips, the progress bar, and the border at 30%.

| Tool | fill | icon |
|---|---|---|
| Watering can | `tileLevelsFill` | `tileLevelsIcon` |
| Trowel | `tileShedFill` | `tileShedIcon` |
| Butterfly net | `tileVisitorsFill` | `tileVisitorsIcon` |
| Mister | `tileGardenFill` | `successText` |
| Shears | `bloomFill` | `bloomIcon` |
| Sun lamp | `tileBadgesFill` | `accentText` |
| Points bar | `tileBadgesFill` | `accentText` |
| Quiet bar | `tileGardenFill` | `successText` |
| Play pill | `tileVisitorsFill`, border `tileVisitorsIcon` 55% | |

Rules:
- All text is `appPrimaryText`. Secondary text is `Color.secondaryText`.
- Never put `successText` as text on `tileGardenFill`. In light mode it is 4.37:1, which is fine for an icon but fails for text.
- Upgrade button and pill: background `appAccent`, text `ink`.

## Components

**ShedHeader**
- One card, radius 22 continuous.
- Border `tileShedIcon` at 30%, 1.5pt. Background `tileBadgesFill`. Shadow is the standard card shadow.
- Top: `Image("ShedScene")`, a new **image** asset with Any and Dark appearances, exported from `sceneSVG()` in index.html at viewBox 353x150. Use `.resizable().scaledToFit()`, full width. The scene holds the plank wall, bunting, window box, a shelf with pots, and the seed jar on the shelf, plus a hanging shed light. The light is a green shade and bulb, not a lantern, so it does not read as a Glow Lantern. There is also an open door with a butterfly. Accessibility: `accessibilityLabel("A cosy wooden garden shed")`.
- Quiet variant: `ShedSceneQuiet`, the same art with no jar.
- Bottom bar: `HStack(spacing: 10)` with padding (leading 16, trailing 12, vertical 10–12) and a top hairline in `accentText` at 25%.
  - Left: `Text("\(points) shed points")` in `Theme.font(.headline, weight: .heavy)`, then `Text("Earn more in the butterfly game.")` in `Theme.font(.subheadline)` with `secondaryText`.
  - Right: a capsule button. It shows the monarch sticker at 22pt (`@ScaledMetric`) and `Text("Play")` in `.callout` heavy, min height 44. It opens the butterfly game through the same route as Visitors.
  - Ids: `shed.points`, `shed.playButton`. Accessibility: `"\(points) shed points"`, and the button reads "Play the butterfly game".
  - At AX sizes, use a `ViewThatFits` or a VStack so the button is full width.
- Quiet Garden: the bar reads "Quiet Garden is on" / "Your tools are ready to use." on `tileGardenFill`. There is no number and no button.

**ToolTile** (a Button that opens `ToolSheet`)
- Layout: `VStack(spacing: 4)`, centred, padding 12 vertical and 8 horizontal, radius 20 continuous. Background `tint.fill`, stroke `tint.icon` at 30%, 1.5pt.
- Art: `Image("tool_<id>_t<tier>")` at 58x62 (`@ScaledMetric`), inside a 66pt circle of `appSurface` at 72%.
- Name: `Theme.font(.headline, weight: .heavy)`.
- `TierPips(tier:tint:)`: three 11pt circles (15pt at AX), 4pt apart. Filled = `tint.icon`. Empty = a 2pt stroke of `tint.icon`, which is at least 4.0:1 on every fill. Mark it `.accessibilityHidden(true)`; the tile label says the tier.
- Effect: `Theme.font(.footnote, weight: .bold)` in `appPrimaryText`, max 2 lines (see the copy table).
- When `points >= cost` and Quiet is off, add a pill: `Label("Upgrade ready", systemImage: "arrow.up")` in `.caption` heavy, capsule `appAccent`, text `ink`, padding 10/3. It sits in the text flow, never over the art.
- AX sizes: one column, and an `HStack(alignment: .center, spacing: 12)` with the art on the left and a leading-aligned VStack on the right.
- Accessibility: `.accessibilityElement(children: .combine)`, label "`<Name>`. Tier `<n>` of 3. `<effect>`." plus " Upgrade ready." when it applies. Hint: "Shows what it does." Id: `shed.tool.<id>`.
- Tool to find (tier 0): background `tint.fill` mixed 45% into the locked fill (`appPrimaryText` at 6% over `appBackground`). Border is dashed (5,4), 1.5pt, in `appPrimaryText` at 60% over the locked fill, about 3.6:1. Art is the t1 image as a silhouette: `.renderingMode(.template)` with `foregroundStyle(appPrimaryText.opacity(0.38))`, or 0.5 in dark mode. Text is "Find at garden level N" in `secondaryText`. No pips, no lock icon. Accessibility: "Shears. Find at garden level 2." Id: `shed.tool.shears`.

**ToolSheet**
- Top card: radius 20, background `tint.fill`, border `tint.icon` at 30%. It holds the 76pt art circle, the name (`.title3` heavy) and the pips.
- Below: a "NOW" and "NEXT" pair. The labels are `.caption` heavy, uppercase, `secondaryText`. Each value is `.body` bold.
- Then one of these:
  - Enough points: a full-width `appAccent` button, "Upgrade for 30 shed points", 52pt high. Id `shed.upgradeButton`.
  - Not enough: a `ProgressView` with a 10pt track (`tint.icon` 18% over `appSurface`, fill `tint.icon`), then "44 of 120 points" in `.subheadline` bold, then "Earn more in the butterfly game."
  - Top tier: "All three tiers. Great tool!"
- No disabled button.
- Quiet Garden: the Now line only. No Next, cost or bar.

**UpgradeCard**
- A centred card over a 32% black dim, radius 24, padding 18.
- It shows the new-tier art in a 96pt `tint.fill` circle, the title "Your `<tool>` got better!", the pips, one line ("Now it gives a bigger soil boost."), and the button "Yay!".
- Motion: a spring scale from 0.9 plus a fade. With Reduce Motion, use opacity only. Post `UIAccessibility.post(.announcement, "<Tool> got better. <line>")`.
- This replaces the old "\(name) upgraded!" text line. The "Not enough shed points yet." message goes away, because the button never shows when points are short.

**PotShelf** (16 pots, the proposed ladder from `pots/index.html#s6`)
- A card, `appSurface`, radius 20, padding 12/10.
- Rows of 4 (2 at AX sizes). Each row is a `ZStack(alignment: .top)`:
  - A plank, 9pt high, radius 4, at y = pot height + 2. Gradient from wood-light to wood-mid, with a 2pt bottom edge.
    - Wood is art colour. Ship it as a stretchable image `ShelfPlank` (Any/Dark).
    - The values are in `--w1/--w2/--wl` in index.html.
  - Over the plank, a `HStack` of 4 equal cells.
- Cell: `PotArtView(pot, size: 56)` (78 at AX), bottom-aligned at the pot height. Below it, 15pt of space, then:
  - Name: `.caption` heavy.
  - Sub: `.caption2` bold, `secondaryText`.
- States:
  - **Earned**: full colour, plus an 18pt `successText` check badge with a white glyph and a 2pt `appSurface` ring at the top right of the pot. Sub is "Yours", "In use", or "Used by `<name>`".
  - **To earn**: `PotArtView` in ghost mode (soft fill, dashed outline, pattern in ink). No lock. Sub is "Grow 15 plants", "Finish level 2", or "Visit 7 days".
  - **Plus**: full colour, no price. Below the name, a capsule "Plus" pill, `tileBadgesFill` with `accentText` text and a 1.2pt `accentText` 55% stroke.
- Footer:
  - "**Pots you earn stay yours.** A pot on a plant stays on it."
  - "Plus pots are extra. A grown-up can find Plus in Settings."
- Section subtitle: "4 of 16 on your shelf. Tap a pot to see how to earn it." In Quiet: "Your pot shelf" / "Tap a pot to see it up close.", and to-earn pots read "Comes as you grow".
- Accessibility per cell:
  - "Moonlit, part of WordFlora Plus"
  - "Mint, to earn. Grow 15 plants"
  - "Sage glaze, yours"
- Id: `shed.pot.<id>`.
- **PotSheet**:
  - Plus pot: "Moonlit is part of WordFlora Plus. A grown-up can find Plus in Settings." and an OK button. No buy button here.
  - Pot to earn: "Grow 15 plants to earn this pot. You have grown 12 so far!"

## Spacing and type
- Screen gutter 20. Section header top margin 18 (`.footnote` heavy, uppercase, tracking 0.06em, `secondaryText`), with a subtitle in `.subheadline`.
- Tile grid gap 10. Card radii: 20 (tiles, shelf), 22 (header), 28 (sheet top).
- All art sizes use `@ScaledMetric(relativeTo: .body)`. All tap targets are at least 44pt (`.tapTarget()`).
- Fonts: `Theme.font(...)`, SF Rounded.

## Copy (grade 2–3, checked against CopySafety: none of miss, only, last, waiting, lost, dead, empty, left, beat, forget)
| Tool | Tier 1 / 2 / 3 effect | Quiet line | To find |
|---|---|---|---|
| Watering can | Waters 1 / 2 / 3 plants per tap | Waters your plants | starts owned |
| Trowel | Small / Bigger / Biggest soil boost | Adds soil for growing | starts owned |
| Butterfly net | Small / Bigger / Biggest catch circle (48 / 64 / 80) | Catches visitors gently | with the butterfly game |
| Mister | Mist every 4 / 3 / 2 hours | Mists your plants | Find at garden level 1 |
| Shears | A trim helps a bit / more / lots | Comes as your garden grows | Find at garden level 2 |
| Sun lamp | Sunshine helps a bit / more / lots | Comes as your garden grows | Find at garden level 3 |

Use these strings in place of the static blurbs in `ShedView.info`. The old mister/shears/lamp blurbs kept saying "Finish level N to find it" even after the tool was found; these strings fix that. Run every new string through `CopySafety.check` in a test.

## Reduce Motion
- With motion on, the shed light sways ±2° over 6s, its glow pulses between 0.55 and 0.85 opacity, and the butterfly at the door bobs.
- With `accessibilityReduceMotion`, show the static scene (no sway, no pulse, no butterfly), and the upgrade card fades.
- In SwiftUI, either keep the light and butterfly as separate overlay images so you can animate them, or ship the scene static and drop the motion. Both are fine. Frame: `p-rm`.

## Open points for the owner and the app worker
1. Net 48/64/80 and mister every 4/3/2 hours need to be wired in code. Earlier notes said the net tier changed the picture only, and the mister did nothing. Ship these lines only once that is done.
2. Quiet Garden hides prices and upgrades in this design. Decide whether tools level up on their own in Quiet; until then, Quiet shows tiers as they are.
3. The sun lamp stays, because `ToolID.lamp` exists. If it is cut, the grid becomes 5 tiles; centre the last tile, or move to a 3+2 layout.
4. New image assets: `ShedScene` and `ShedSceneQuiet` (Any/Dark, from `sceneSVG(true/false)`), and `ShelfPlank`. No new colorsets.

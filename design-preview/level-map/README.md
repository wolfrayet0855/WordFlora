# Garden Path: level map spec for `LevelMapView.swift`

The mockup is `index.html`. Use `?frame=1&state=new|mid|late|all&theme=light|dark&text=large`, or no query for a board of every state. Run `sh render.sh` to make the shots in `shots/` (new-light, mid-light, mid-dark, late-light, late-dark, all-light, all-dark, large-light, large-dark). The design is for iPhone at 393 pt wide. Sizes below are in pt.

## Data
- `wordLevel` = `app.profile?.currentLevel` (`ProgressionPolicy.wordLevel`). A level is **open** when `level <= wordLevel`, **current** when `==`, and **soon** when `>`.
- `found` = plants in the level with `earnedCount > 0`. `bloom` = plants with `stage >= 4`. The garden level is complete when `ProgressionPolicy.gardenLevelComplete` is true (all 10 at stage 4).
- Names come from code: Seedling, Sprout, **Bloom**, Grove, Ancient. Do not use "Wildwood".
- Theme lines (pending owner approval, decision 1): Garden friends · Plants from far away · Strange and wild plants · Rare wonders · Old, giant and rare.
- Hero plants: `plant_daisy`, `plant_lotus`, `plant_venus_flytrap`, `plant_giant_water_lily`, `plant_wollemi_pine`.
- Nothing earned is ever removed or greyed out. The screen has no prices, no ads and no Plus.

## Layout
- **Nav.** The back button reads "Home" (accent text, 17 pt bold). In the centre, put `Image("Wordmark")` (v3 hero art, already in the asset catalogue) at 24 pt high, about 141 pt wide, and mark it `accessibilityHidden(true)`. Do not use `WordmarkView` here: it adds an `.isHeader` trait and switches to the solo art below 130 pt.
- **Header** (20 pt side padding):
  - "Garden Path": large title, weight black, `.isHeader`.
  - Sub-line in secondary text (`.body`).
- **Key card.** 16 pt margins, 12/14 padding, radius 16, fill = surface mixed 60% with the background. It holds two items, a petal and a gold ring outline (3 pt stroke), and wraps at large sizes.
- **Trail** (16 pt side padding, 26 pt between stops):
  - Rows hold a 128 pt medal and a card with 12 pt spacing, alternating left and right (stop 1 has the medal on the left).
  - Behind them is a path through the medal centres. Each segment is a cubic curve with control points `(a.x, midY)` and `(c.x, midY)`. Draw it as a 26 pt `path-edge` stroke, then a 20 pt `path` stroke, then a 2.5 pt `path-edge` dotted line (dash 1, gap 14, round caps).
- **Card.** Radius 18, 1 pt line (text 14%), shadow, 12/14/13 padding. From top to bottom:
  - [current only] "You are here" chip: pin glyph, capsule filled with accent 24% over surface, 13 pt bold.
  - "LEVEL N" eyebrow: 13 pt heavy, uppercase, tracking .06em, secondary text.
  - Name: 20 pt black.
  - Theme line: 14 pt, secondary text.
  - Rows, each at least 24 pt high: "N of 10 plants found" next to a petal, and "N of 10 in full bloom" next to a gold ring.
  - Status lines (14 pt heavy, leaf colour).
  - Next-step line (14 pt, secondary text).
  - Play button: 48 pt high, radius 14, 17 pt heavy, play glyph. Filled accent with accent-ink text on the current level; outlined (1.5 pt card line) on past levels.
- **Current card.** 2 pt accent border, plus a 5 pt glow of accent at 18%.
- **Soon card.** Dashed 1 pt border, surface mixed 55% with the background, no shadow, the name in secondary text. It has no rows and no button.
- **Medal** (`LevelMedal`, 128 pt canvas, centre 64), marked `accessibilityHidden`:
  - A disc of radius 40 in the level tint, with a 1 pt card-line stroke.
  - Current level: an accent ring at r 43, 3 pt.
  - Petal ring: 10 ellipses (rx 4.6, ry 7.2) at r 50, every 36°, starting at the top. Filled `petal` for each plant found; the rest are outlined in `petal-off` at 1.6 pt.
  - Bloom ring at r 60:
    - while bloom < 10: 10 arcs with 3° gaps. Those at stage 4 are `bloom` 4.5 pt; the rest are `petal-off` 2 pt.
    - at bloom = 10 (garden level complete): one **solid** `bloom` circle, 5 pt.
  - Hero plant, 68 pt, centred slightly high (y -4).
  - Badge at (+42, -46) from the centre, 26 pt circle. A leaf circle with a white check when found = 10. A bloom circle with a sun (accent-ink) when bloom = 10; this replaces the check.
  - Soon levels: a soil ellipse (44x16, 85% opacity) with a two-leaf sprout in `leaf`. No rings, so no blank slots are shown.
- **End.** A bench glyph in soil colour, then "A bench to rest at the end of the path" (14 pt bold, secondary text). The page ends with 120 pt of bottom padding.
- On appear, scroll to the current stop with `ScrollViewReader`, anchored at the centre.

## Colours (light / dark)
| Token | Light | Dark |
|---|---|---|
| background | #FAF7F0 | #1A2E1A |
| surface | #FFFFFF | #2C3E2C |
| text | #2C3E2C | #D4EDD4 |
| secondary text | text at 80% | text at 80% |
| card line | text at 14% | text at 14% |
| accent (current, button) | #E8A838 | #F0C060 |
| accent-ink (on accent) | #2C3E2C | #1A2E1A |
| accent-text ("Home", "Full bloom garden!") | #8A5A00 | #F0C060 |
| leaf (status lines, sprout) | #2E7D32 | #81C784 |
| petal | #E07A8B | #F09AA8 |
| petal-off | text at 13% | text at 18% |
| bloom (gold ring) | #E8A838 | #F0C060 |
| path | #E3D7BC | #4A6342 |
| path-edge | #D2C29D | #5C7A52 |
| soil | #B98A5E | #8C6A48 |
| tint L1 / L2 / L3 / L4 / L5 | #E6F1DF / #DFEAF5 / #F7E7D4 / #ECE5F5 / #E2F0EC | #23392A / #213447 / #3A2F22 / #2F2A3F / #1F3A35 |

The existing app colours cover background, surface, text, accent and success. New colorsets: `levelTint1`-`levelTint5`, `path`, `pathEdge`, `petal`, `soil`, and `leaf` if `successText` does not match it.

## Copy (every string; all pass `CopySafety.check`)
- Nav: "Home". Title: "Garden Path".
- Sub-line:
  - 0 plants: "Every 10 plants opens a new level."
  - 1-49 plants: "N plants found. Every 10 plants opens a new level."
  - 50 plants: "All 50 plants found! Grow them all to full bloom."
- Key: "Petal = plant found" · "Gold ring = full bloom".
- Chip: "You are here". Eyebrow: "Level N". Button: "Play Level N".
- Rows: "N of 10 plants found" · "N of 10 in full bloom". When found = 0, both rows are replaced by "Find your first plant!".
- Status lines:
  - found = 10 and N < 5: "All 10 found! Level N+1 is open."
  - found = 10 on Level 5: "All 10 found! Every level is open."
  - bloom = 10: "Full bloom garden!", with a sun, in accent-text.
- Next step (current level only, when found < 10):
  - Levels 1-4: "Find 10 plants to open Level N+1." at 0, otherwise "Find K more to open Level N+1."
  - Level 5: "Find 10 plants for Level 5." at 0, otherwise "Find K more for Level 5."
- Soon card: "Coming soon in your garden" · "Opens when Level N-1 has 10 plants."
- End: "A bench to rest at the end of the path".
- Never use: lock icons, "locked", "left", "only", "last", "miss", "waiting", "lost", "empty". Add these strings to the CopySafety test.

## Accessibility
- One element per stop (`.accessibilityElement(children: .combine)` or an explicit label). The Play button stays a separate element with the label "Play Level N".
- The label repeats the visible text in order, for example:
  - "Level 2, Sprout. Plants from far away. You are here. 4 of 10 plants found. 0 of 10 in full bloom. Find 6 more to open Level 3."
  - "Level 1, Seedling. Garden friends. Find your first plant!" (found = 0)
  - "Level 3, Bloom. Strange and wild plants. Coming soon in your garden. Opens when Level 2 has 10 plants."
  - Add "All 10 found! …" and "Full bloom garden!" when they apply.
- Mark the current stop with `.isSelected`. Hide from VoiceOver: medals, the path, the bench glyph and the nav wordmark. The key card is one element: "Petal means plant found. Gold ring means full bloom."
- Contrast: leaf #2E7D32 on the soon card is about 5:1, and accent-text #8A5A00 on surface is above 4.5:1. Do not put text in the light accent #E8A838 on white.
- Tap targets: back and Play are at least 44 / 48 pt.

## Dynamic Type
- All text uses text styles (`Theme.font`). The fixed sizes above are the sizes at the default text size.
- At `dynamicTypeSize.isAccessibilitySize` (shots `large-*`), use one column: a 96 pt medal centred above a full-width card, with the path running straight down through the medal centres and no alternation. Rows and status lines wrap with no line limit.
- The key items stack, and the key icons scale with the text (`@ScaledMetric`).
- The nav wordmark stays at 24 pt; it is decorative, so do not scale it.

## Reduce Motion
The screen has no ambient motion. Scroll to the current stop with animation, but with no animation when Reduce Motion is on. Any later highlight on a newly opened level should be a cross-fade, not a scale or bounce, under Reduce Motion.

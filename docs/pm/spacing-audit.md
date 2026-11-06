# Spacing audit (2026-11-06)

Owner feedback: on the guide pages the picture inside each box sat on the box edge (page 1 Clue bar on the top edge,
page 3 growth steps on the top edge, page 5 Garden card in the top-left corner, Visitors and Shed tight to the sides,
uneven space at the bottom). Wanted: the content inside the box, and the same space on top, bottom and both sides on
every screen.

Screens were captured on an iPhone 17 simulator through the UI test runner (`FidelityScreensUITests`, `fid-*.png`,
and `GuideUITests` screenshot tests) in light, dark and the largest text size. Margins were measured from the PNGs
(3 px = 1 pt) with a small script that finds the first and last non-background pixel per row, and by eye for the
inner space of cards.

## The scale (`WordFlora/Theme/Spacing.swift`)

4 point base.

| Token | Value | Used for |
|---|---|---|
| `Space.xs` | 4 | icon to label, a card's top under a full-bleed picture |
| `Space.s` | 8 | title to body, buttons to the safe area |
| `Space.m` | 12 | between rows and stacked buttons, dots to buttons, grid gaps, small tiles |
| `Space.card` | 16 | inside every card and box, all four sides |
| `Space.gutter` | 16 | screen sides: boxes, buttons, wordmark and Skip line up on it |
| `Space.section` | 24 | box to heading, between blocks, overlay cards to the screen edge |

Rules: content blocks inside a box get `Space.card` on all four sides; one-line rows (key card, Daily Bloom) may use
12 top and bottom with 16 at the sides; modal cards (rest, break, nudge) float 24 from the screen edge with 16 inside.

## Root cause on the guide

Each guide picture places its parts with `.at(x, y)` alignment guides inside a `ZStack`. A `ZStack` takes the size of
the union of its children, so the smallest offset collapsed to zero: the designed 16 point insets disappeared and the
whole picture slid up and left, leaving the spare space at the bottom and right. Fixed by `ArtCanvas`, whose clear
first layer pins the drawing area's top-left corner (the same fix inside the two small pot drawings on page 4).

## Findings and fixes

| Screen | Issue (measured before) | Fix | Status |
|---|---|---|---|
| Guide p1 | Clue bar ~1 pt from the box top; keys 32 pt from the bottom | Anchored canvas; Clue bar and keys 16 from top and bottom | must, fixed |
| Guide p2 | Word cards 0 from top (designed 22) | Anchored; 16 top, chip 16 from bottom | must, fixed |
| Guide p3 | Stage circles ~1 pt from top; "Full bloom" wrapped to two lines and ran near the edge | Anchored; track inset so the outer labels end 16 from the sides; labels one line | must, fixed |
| Guide p4 | Rose and card offsets 14/14 vs 16 | 16 on all sides; small pot drawings anchored | must, fixed |
| Guide p5 | Garden card ~1 pt top, ~4 pt left; Visitors/Shed 4 left vs 36 right; bottom 39 | Anchored; all three cards 16 from every edge; butterfly and path moved into the gap; "+5 points" chip clear of the can | must, fixed |
| Guide p6-p8 | Bottom rows 14-22 from the bottom | 16 | must, fixed |
| Guide frame | Wordmark 18 and Skip ~20 from the sides vs 16 for box and buttons; title 22 below the box, 10 to body; dots 18 over the buttons; Next changed width between page 1 and 2; 115-137 pt dead gap above the dots | Wordmark and Skip text on the 16 gutter; box to title 24, title to body 8; dots 12 over the buttons; page 1 keeps Back's 104 pt place; picture and words centred in the free space | must, fixed |
| Guide (AX sizes) | Picture shrinks to 60%, insets scale with it (~10 pt) | No change; text and buttons stack as before | ok |
| Home | Gutter 16; forecast card and weather banner 14 inside | Cards 16 inside | fixed |
| Home | "Explore" heading 4 pt in from the gutter | Kept: optical alignment with the tile corners | nit, kept |
| Game | Hint card: 16 above the clue, ~28 under "Simpler clue" (44 pt hit area) | Hit area may reach into the card padding; 16 under the words | must, fixed |
| Game | Side margin 12 (keyboard needs the width) | Kept on purpose | ok |
| Rest / break / nudge cards | 24 from the screen, 20 inside, 4 under the scene | 24 from the screen, 16 inside (4 under the full-bleed scene kept) | fixed |
| Garden | Gutter 20 vs 16 on Home; a found plant's card taller than "Not found yet" beside it, so cards in a row floated at different heights | Gutter 16; two-column Grid, both cards take the row's height | must, fixed |
| Plant page | Life panel 12 from the edge vs 16 for the name card and tend buttons; tend bar 14 | All on 16 | must, fixed |
| Repot sheet | Sides 20 vs 16 elsewhere | 16; header 24 top | fixed |
| Shed | Gutter 20 | 16 | fixed |
| Shed tool sheet | Upgrade card 18 inside | 16 | fixed |
| Visitors | Gutter 20; album cards in a row at different heights (Monarch vs "Not met yet") | Gutter 16; both cards in a row share its height; met card 16 inside | must, fixed |
| Visitors' book | Gutter 20, cards 14 inside | 16 / 16 | fixed |
| Badges | Gutter 20; cards in a row at different heights (Good Feeder vs Green Thumb) | Gutter 16; two-column Grid with equal row heights | must, fixed |
| Level map | Header 20 from the side, key card and trail 16; stop cards 12/14/13 inside; back button 16 | Header, key and trail on 16; stop cards 16 all sides; back chevron on 16 | must, fixed |
| Settings | System form (16 gutter) | No change | ok |
| Plus | Gutter 20; plan rows 14 inside | 16 / 16 | fixed |
| Daily Bloom (game) | Same as the game screen | No change | ok |
| Age question | Gutter 24; content pinned to the top with the lower half empty | 16 gutter. Centring was tried and dropped: it moved the buttons while the question fades in from the intro, and the first-tap tests failed | fixed (gutter); centring open |
| Grand Garden / what grows next | Gutter 20; cards 14 inside | 16 / 16 (hills still full-bleed) | fixed |
| Weather puzzle, weather helpers | 20 gutter, 14 inside | 16 / 16 | fixed |

Widgets were not audited (out of scope).

## Checked after the fixes

Light, dark and AccessibilityXXXL screenshots of all the screens above, plus the guide in light and at accessibility
text sizes. The accessibility audits in GuideUITests, WordFloraUITests, RestCardUITests, WeatherUITests,
EndgameUITests, TendingUITests and HomeLayoutUITests were run after the change.

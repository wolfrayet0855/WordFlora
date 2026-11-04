# T-D Pot collection: design notes

Mockup: `design-preview/pots/index.html` (http://localhost:8765/pots/index.html). Catalog data: `pots.json` (the code worker reads it verbatim). Screenshots: `shots/` (light and dark, one per section, rendered at a 390 pt layout width).

Page params: `?theme=dark|light` (does not change the saved theme), `?only=s1|s1b|s2|s3|s4` (one section), `?w=390` (pins the layout width; headless Chromium will not go below 500 px wide).

## Decisions
- **One pot shape for all ten.** Same geometry as `TendAnimationView.drawPot` (120 x 100 view box: rim rounded rect, body trapezoid with rounded foot, light strip, shade strip, rim shine). A pot differs by its three colours plus one pattern drawn on the body, clipped to the body path, before the rim. All patterns are rects, capsules, circles, ellipses and two small fixed paths (the 4-point sparkle and the heart already used in actions.html), so SwiftUI `Path`/`GraphicsContext` can draw them; `pots.json` `geometry.decorations` lists exact coordinates.
- **Every pot has its own pattern** (none, rings, drip, flower, stars, hearts, dots, stripes, moon, flowerBand), so no two pots depend on hue alone. Plain blue is the only pattern-free pot, which also makes it read as "the plain one".
- **Ten pots, changed from the earlier tending mock:** Seashell, Moonlight (level 1/2) and Crystal (150 shed points) are dropped for the approved triggers. Moonlit (a Plus pot) takes the moon idea; Starlight keeps its teal and sparkles. Starlight rim lightened to `#5A98A2` and Moonlit rim to `#7383C4` so the dark pots keep an edge on the dark theme. Meadow rim is `#5E9E45` so its pale body has a clear top.
- **Pots to earn** draw as a soft outline: lock-colour fill, dashed outline, the pattern in ink at 55%. Children see the shape they are working toward. No lock icon, no padlock, no greyed-out "X".
- **Plus pots** draw in full colour with a small amber "Plus" tag with a sparkle. Tapping one says "Moonlit is part of WordFlora Plus. A grown-up can find Plus in Settings." No price, no buy button, no timers in the sheet; Plus opens only from Settings behind the grown-up gate.
- **Repot sheet "Pick a pot":** all ten pots in a 5 x 2 grid (50 pt pots, chips 61 x 86 pt at 390 pt), above the soil choices, so nothing hides off screen. The current pot has a 3 pt ring plus a check badge (shape, not only colour). Tapping a pot to earn shows its hint in a bubble directly under that pot's row, with a pointer at the pot, and a progress line ("You finished level 3." + copy.toGoMany "{k} more levels to go!" or copy.toGoOne "One more level to go!"). The main button keeps naming the pot in use until an owned pot is picked ("Repot into Sunflower"); with the same pot it reads "Repot with fresh soil".
- **Shed "Pots" grid** below Tools: 3 columns of cards (76 pt pot). Owned: check badge and "Yours to use" / "In use by Daisy". To earn: softer card, outline pot, the goal ("Grow 25 plants"), a progress bar and "12 of 25 plants" (levels: copy.progressLevel "3 of 5 levels finished", so it never reads as "on level 3"). Plus: tag and "Part of WordFlora Plus". Footer: "Pots you earn stay yours. A pot already on a plant stays on it."
- **Plant page stage:** the chosen pot is drawn at 140 pt in place of plain blue, soil top and plant position unchanged from actions.html. The plant art's own ground shadow is clipped to the soil-top ellipse (80 x 20) so it never spreads over the rim; the pot's floor shadow is rgba(44,62,44,.18) light and rgba(0,0,0,.35) dark.
- **Rules kept from the plan:** earned pots are never removed (unlocks computed from stats); a pot already applied stays applied forever, even after Plus ends; choosing a new Plus pot needs Plus; empty `potId` = plain blue; unknown id falls back to plain blue.

## Revision 1 (critic review.md, nine changes)
1. Terracotta rings #7E3F22, 7 units tall at y 38 and y 52 (second at 70%), so they read at 44 pt and in grey.
2. Stage: plant ground shadow clipped to the soil ellipse; dark floor shadow rgba(0,0,0,.35).
3. pots.json now matches the HTML (drip band (18,20,84,10), petal ry 9, flowerBand rect (18,70,84,30)) and states that x/y for capsules, bars, circles and petals are centres, petal 0 up then clockwise.
4. pots.json `geometry.toEarn`: fill #E4DFD2 / #3A4C3A, ink #746F5E / #8FA48F, no strips or shine, body and rim stroke 2 dashed [5,4], pattern in ink at 55%.
5. Moon crescent is one closed two-arc path (r 15 circle minus r 13 circle). An even-odd fill clipped to the big circle left a hairline at the clip edge in Chromium, so the explicit path is the spec; `circle15.subtracting(circle13)` gives the same shape in SwiftUI.
6. Plus hints: "Part of WordFlora Plus. A grown-up can find Plus in Settings."
7. copy.progressLevel "{n} of {goal} levels finished"; new copy.toGoOne, copy.toGoMany, copy.progressFirst ("Grow one plant to earn this pot.").
8. Accessibility text sizes: pick grid goes to 4 columns, 3 rows; names wrap to 2 lines at the space; one-word names that still do not fit scale to 80% (lineLimit(2), minimumScaleFactor(0.8)), never break inside a word. Mocked as sheet E.
9. Chip size corrected to 61 x 86 pt.
Critic rulings kept: Moonlit body 1.7:1 accepted (rim 3.2:1); Mint keeps r 4.5 and all 12 dots.

## Unlock table

| id | Name | Body / rim / shade | Pattern | Unlock | Hint |
|---|---|---|---|---|---|
| plainBlue | Plain blue | #5B8FD0 / #7AA6DE / #4677B3 | none | free | Every garden starts with this pot. |
| terracotta | Terracotta | #C8734A / #DD8C63 / #A85A36 | rings (#7E3F22) | plants 1 | Grow your first plant to earn this pot. |
| sageGlaze | Sage glaze | #8FB08C / #B4CCB1 / #76996F | drip | plants 10 | Grow 10 plants to earn this pot. |
| sunflower | Sunflower | #F2C230 / #F8D95F / #D9A514 | flower | level 3 | Finish level 3 to earn this pot. |
| starlight | Starlight | #2F6670 / #5A98A2 / #224C54 | stars | level 5 | Finish level 5 to earn this pot. |
| rosePink | Rose pink | #E8869F / #F2A9BC / #CC6683 | hearts | plants 25 | Grow 25 plants to earn this pot. |
| mint | Mint | #7CCFA8 / #A8E5C8 / #5BB38A | dots | plants 50 | Grow 50 plants to earn this pot. |
| honeyStripe | Honey stripe | #E39B2E / #F2BC5E / #C47F18 | stripes | plus | Part of WordFlora Plus. A grown-up can find Plus in Settings. |
| moonlit | Moonlit | #3B4A80 / #7383C4 / #2A3560 | moon | plus | Part of WordFlora Plus. A grown-up can find Plus in Settings. |
| meadow | Meadow | #F3E6BF / #5E9E45 / #D6C38E | flowerBand | plus | Part of WordFlora Plus. A grown-up can find Plus in Settings. |

"plants N" = plants grown (collection count) at least N. "level N" = level N finished.

## Accessibility checks
- **Text contrast (WCAG):** light: text on surface 11.5, secondary text `#4F5F4F` on surface 6.8 and on the to-earn card 6.6, green status `#3E7A22` 5.2, Plus tag 5.5, hint bubble 10.7, button 7.1. Dark: text on surface 9.2, secondary `#B9D0B9` 7.0 (7.9 on the to-earn card), status `#A8D84A` 6.9, Plus tag 8.6, bubble 11.6, button 8.7. All pass 4.5:1. The page's `--muted` (58% mix) is NOT used for text; it fails on white.
- **Dimming touches the pot art only**, never names or hints, so text keeps full contrast.
- **Graphics:** to-earn ink on its fill 3.8 (light) and 3.5 (dark). Dark pots on the dark theme: Moonlit body alone is 1.7 against the background, but its rim (3.2) and moon pattern carry the outline; Starlight rim 3.5. Meadow rim on white 3.3.
- **Colour-blind:** section 1b shows all ten at 44 pt in grey, deuteranopia, protanopia and tritanopia. Each stays unique by pattern. Mint, Sage and Meadow (the greens) differ by dots / drip / grass band; Starlight and Moonlit (the dark pair) by sparkles / crescent; Sunflower and Honey stripe (the yellows) by flower / stripes.
- **Size:** patterns are chunky enough to read at 44 pt (smallest marks: dots r 4.5 = 1.7 pt at 44 pt, so mint stays readable as "dotty" rather than as single dots).
- **VoiceOver:** each pot has an `a11y` label in `pots.json` that names colour and pattern. Chips add state: "Sage glaze pot, in use", "Starlight pot, not earned yet", "Moonlit pot, Plus". The hint bubble is a status message read when it appears. Progress bars carry "12 of 25 plants grown".
- **Copy:** names are 1 or 2 words; hints use grade 2 words and avoid every banned word (miss, lonely, alone, waiting, abandon, neglect, forgot, forget, die, dead, lost, empty, left, broken, hurry, expires, only, last, smart, genius, talented, beat). Should all pass `CopySafety`.
- **Touch targets:** chips are 61 x 86 pt at 390 pt (4 columns, about 76 x 112 pt, at accessibility text sizes), shed cards 110 x 150 pt.

## Open points
- Seasonal Plus pots later reuse the same pattern kinds (or add one new kind per season).

# WordFlora logo v3, direction "hero": Hero flower

Preview: http://localhost:8765/logo/v3/index.html#hero. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. Build: `python build.py --direction hero` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction hero` (PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.

**Changes in round 2:** TODO

## Idea

One hero flower, nothing else. "Word" is plain ink green (#182818) with no decoration. The Flora o carries one large five-petal rose flower with **separate** petals. Each petal is a round-ended teardrop and the background shows between neighbours, so the five can be counted at 60 px and read as five rose dots around the o at 29 px. Light-mode rose is deepened to #C9506C (4.05:1 on cream), so light mode now works on the same lightness principle as v2's dark mode. The icon is the same flower: same petals, the o ring as the flower's centre, its counter filled amber so it reads as a pistil and not as the letter O. Kerning rule shared by all three: equalising mean x-height gaps opens the round pairs by 77 to 108 u compared with Nunito's native spacing, so the whole word is a little more open than v2. The air is now even, though, and no longer bunched around the flowers.

## Construction

- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font's own o with its open counter. The Word o is a plain letter.
- **Flower.** Five teardrop petals (cubic, round outer end) from r0 = 110 u to tip T = 505 u (1.91x the o radius, v2 was 1.72x), width parameter 172 u, one petal up and the whole flower turned -8 degrees. The tilt keeps the right petal above the r's shoulder and both side petals at least 80% visible; at 0 degrees the right petal was only 76% visible. Rose, not two colours: amber vs rose carried nothing in greyscale.
- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (52 u twin, 62 u solo, 60 u mono-solid). A petal that would reach a neighbour (the l or the r dilated by 40 u, solo 50 u, then closed by 100 u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most 5% of it would sit behind the letter, then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: 1.000, 1.000, 1.000, 1.000, 1.000). An opening of 12 u rounds every corner.
- **Spacing rule (solver).** Kerns are solved so that every pair's mean gap is within 0.86 to 1.14 x the r-d gap on **both** bands (x-height band 10..470 u, and the full o height -11..503 u including overshoot), with the F's middle arm at least 60 u from the l. The solver picks the smallest r-d for which that is possible (the tightest word): Word pairs and d-F take the tightest legal value, the Flora o pairs 1.10 x r-d for petal room. Kerns W-o..r-a: -32.0, +93.0, +42.0, +101.0, -29.0, +117.0, +145.0, +4.5 u. Solo adds 10 u to every pair.
- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap 62 u, neighbour clearance 50 u, +10 u tracking, as an optical size.
- **Icon.** Cream background (#FAF7F0). Rose petals, green ring (the Flora o), counter filled amber #E9A43A. Dark: gold ring with a deep amber counter on #1A2E1A. Tinted: grey petals, white ring, light-grey counter on black. Flower scaled by 0.8404 so its larger side is 80% of the 1024 canvas, centred on its bounding box; flat background rect.
- **SVG hygiene.** Only `<path fill>` elements (mono petals use `fill-opacity` 0.60); width/height equal the viewBox; no mask, stroke, filter, gradient, defs, use, text, image, clip-path or @import.

## Palette and WCAG contrast (A1, A2, A4)

| Pair | Colours | Ratio | Target |
|---|---|---|---|
| Word on cream (light) | `#182818` on `#FAF7F0` | 14.48 | >= 4.5 ok |
| Flora on cream (light) | `#2E803F` on `#FAF7F0` | 4.59 | >= 4.5 ok |
| Word vs Flora (light) | `#182818` on `#2E803F` | 3.15 | >= 3.0 ok |
| Petals on cream (light) | `#C9506C` on `#FAF7F0` | 4.05 | >= 3.0 ok |
| Petals vs ring (light) | `#C9506C` on `#2E803F` | 1.13 |  |
| Word on dark | `#DCEEDC` on `#1A2E1A` | 11.94 | >= 4.5 ok |
| Flora on dark | `#F0C060` on `#1A2E1A` | 8.56 | >= 4.5 ok |
| Word vs Flora (dark) | `#DCEEDC` on `#F0C060` | 1.39 | >= 1.3 ok |
| Petals on dark | `#E26582` on `#1A2E1A` | 4.43 | >= 3.0 ok |
| Petals vs ring (dark) | `#E26582` on `#F0C060` | 1.93 |  |
| Mono ink on white | `#182818` on `#FFFFFF` | 15.49 | >= 4.5 ok |
| Mono petals (ink at 0.60 = #747E74) on white | `#747E74` on `#FFFFFF` | 4.22 | >= 3.0 ok |

Icon colours (each part against what it sits on; worst of deutan/protan/tritan in the last column):

| Icon | Part | Hex | Against | Ratio | Worst CVD |
|---|---|---|---|---|---|
| light | petal | `#E26582` | bg | 3.92 | 3.12 |
| light | ring | `#F0C060` | bg | 7.59 | 6.85 |
| light | pistil | `#B8650A` | ring | 2.53 | 2.41 |
| dark | petal | `#E26582` | bg | 4.97 | 4.00 |
| dark | ring | `#F0C060` | bg | 9.61 | 8.79 |
| dark | pistil | `#B8650A` | ring | 2.53 | 2.41 |
| tinted | petal | `#8C8C8C` | bg | 6.25 | 6.25 |
| tinted | ring | `#FFFFFF` | bg | 21.00 | 21.00 |
| tinted | pistil | `#A0A0A0` | ring | 2.61 | 2.61 |
| alt-cream | petal | `#C9506C` | bg | 4.05 | 3.59 |
| alt-cream | ring | `#2E803F` | bg | 4.59 | 4.30 |
| alt-cream | pistil | `#E9A43A` | ring | 2.30 | 1.93 |
| smile | petal | `#E26582` | bg | 3.92 | 3.12 |
| smile | ring | `#F0C060` | bg | 7.59 | 6.85 |
| smile | face | `#1A2E1A` | ring | 8.56 | 7.80 |
| smile-dark | petal | `#E26582` | bg | 4.97 | 4.00 |
| smile-dark | ring | `#F0C060` | bg | 9.61 | 8.79 |
| smile-dark | face | `#1A2E1A` | ring | 8.56 | 7.80 |
| smile-tinted | petal | `#8C8C8C` | bg | 6.25 | 6.25 |
| smile-tinted | ring | `#FFFFFF` | bg | 21.00 | 21.00 |
| smile-tinted | face | `#000000` | ring | 21.00 | 21.00 |

## Colour-vision simulation (A5)

Machado, Oliveira and Fernandes 2009, severity 1.0, applied to linear sRGB of the hex colours, then WCAG luminance (agrees with `review/cvd_sim.py --hex` to within 0.03).

| Simulation | Petals on cream | Petals on dark | Word vs Flora (light) | Word on cream | Flora on cream |
|---|---|---|---|---|---|
| deuteranopia | 3.59 | 5.03 | 3.04 | 14.64 | 4.82 |
| protanopia | 5.01 | 3.55 | 3.31 | 14.24 | 4.30 |
| tritanopia | 4.04 | 4.45 | 3.12 | 14.50 | 4.64 |

No meaning depends on hue: the flower is separated from the background by lightness, and from the ring by a real gap.

## Letter-pair gaps (A6), relative to r-d, both bands

| Pair | x-band mean (min) u | vs r-d | full-o-band mean (min) u | vs r-d | solo x-band vs r-d | Kern u |
|---|---|---|---|---|---|---|
| W-o | 216 (154) | -14.0% | 227 (154) | -11.6% | -13.4% | -32.0 |
| o-r | 216 (176) | -13.8% | 241 (176) | -6.1% | -13.3% | +93.0 |
| r-d | 251 (114) | +0.0% | 256 (113) | +0.0% | +0.0% | +42.0 |
| d-F | 219 (216) | -12.5% | 221 (216) | -13.9% | -12.1% | +101.0 |
| F-l | 276 (60) | +10.2% | 291 (60) | +13.6% | +9.8% | -29.0 |
| l-o | 272 (183) | +8.3% | 293 (183) | +14.2% | +8.0% | +117.0 |
| o-r | 268 (228) | +6.9% | 293 (228) | +14.1% | +6.6% | +145.0 |
| r-a | 251 (75) | -0.0% | 251 (75) | -2.1% | -0.0% | +4.5 |

Worst: 14.0% (x band), 14.2% (full o band), solo 13.4% / 13.6%. F-l minimum arm gap: **60 u** (1.7 px at 29 px tall).

**The trade-off the rule forces.** With unaltered glyphs, the F's open right side makes F-l the widest pair on both bands and o-r the narrowest. Keeping both within +-15% of r-d sets a floor under r-d, and the F-l arm gap raises it:

| F-l arm gap | smallest legal r-d (x band) | W-o | o-r (Word) |
|---|---|---|---|
| 32 u | 225.8 | 194 | 195 |
| 45 u | 236.8 | 204 | 204 |
| 60 u | 250.8 | 216 | 216 |

v2 for reference (x band): W-o 262, o-r 221, r-d 203 u. TODO

Petals tucked behind a neighbour, share of each petal (outside the ring gap) left visible, petals clockwise from the top one:

| | P1 top | P2 right | P3 lower right | P4 lower left | P5 left |
|---|---|---|---|---|---|
| twin | 100% | 98% | 100% | 100% | 99% |
| solo | 100% | 98% | 100% | 100% | 99% |
| mono-solid | 100% | 98% | 100% | 100% | 99% |

## Small-size geometry (A2, A3)

- Units per pixel at 29 px tall: 34.9. Ring gap 52 u = **1.49 px** (mono-solid 60 u = 1.72 px; A2 needs >= 1.0 px, i.e. >= 35 u).
- Widest visible width of each petal at 29 px tall: 9.4, 9.4, 9.4, 9.4, 9.4 px (A3 needs >= 4).
- Clear gap between neighbouring petals at 60 px tall: 3.8, 4.1, 3.4, 4.2, 4.1 px.
- Longest straight run on the bloom outline: 24.7 px at 320 px tall.
- The o counter at 29 px tall: 5.2 x 7.1 px.

## Sizing contract (A10)

| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |
|---|---|---|---|---|
| twin (wordmark*.svg) | 20 11 5708 1011 | 5.65 : 1 | 30.5 pt | 46.4 pt |
| solo | 20 11 5788 1011 | 5.72 : 1 | 30.0 pt | 45.8 pt |

v2 was 5.83 : 1, about 29.5 pt tall at 172 pt.

## Self-check, A1 to A13

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | petals 4.05 on cream, 4.43 on dark (>= 3.0) |
| A2 | **pass** | petal/ring 1.13 light, 1.93 dark; ring gap 52 u = 1.49 px at 29 px tall (>= 1.0), mono-solid 1.72 px |
| A3 | **pass** | petal width at 29 px 9.4 px min (>= 4); 5 petals countable at 60 px in light, dark, mono and mono-solid (`png/*-h60.png`); at 29 px it reads as a small rose flower round the o, not a halo |
| A4 | **pass** | Word/Flora 3.15 light (>= 3.0), 1.39 dark (>= 1.3); Word 14.48, Flora 4.59 on cream; 11.94, 8.56 on dark (>= 4.5) |
| A5 | **pass** | worst petals on cream 3.59 (>= 3.0), worst Word/Flora 3.04 (>= 2.0) across deutan, protan, tritan |
| A6 | **FAIL** | worst pair 14.0% x band / 14.2% full o band (solo 13.4 / 13.6; <= 15); F-l arm gap 60 u; least-visible petal 98% (>= 80); by eye: TODO |
| A7 | **pass** | reads "WordFlora" at 29 px in all seven variants; the o keeps its full ring and open counter inside a 1.15 px gap, read as a letter |
| A8 | **pass** | 1024 square, flat cream rect, no text, no transparency; one flower; still a flower at 29 px (5 rose petals visible); no face |
| A9 | **pass** | light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px |
| A11 | **pass** | baseline flat, no bounce; no primaries, gloss, sparkle or bevel; no face anywhere |
| A12 | **pass** | by description only, reviewers still to confirm: a five-petal flower round a letter is close to no well-known mark. Blossom and Flora (plant/focus apps) use leaves or trees; Lily's Garden and Gardenscapes use illustrated scenes; PictureThis and Seek use leaf or lens marks; Duolingo, Finch, Forest, Headspace, Calm and Wordscapes are unrelated shapes. The cream-ground icon is a generic "flower" glyph, so it is distinctive only through the green o ring. Nothing copied |
| A10 | **pass** | 5.65 : 1; 30.5 pt at 172 pt wide (26-34), 46.4 pt at 262 pt |
| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |

## Honest weaknesses

- The side petals tuck behind the l and the r (84 to 87% visible). At 320 px you can see the tuck edge and a small notch where the l's foot curls under the lower-left petal.
- The F's middle arm is 32 u from the l (about 0.9 px at 29 px tall). That is the cost of keeping F-l within +15%, and at 29 px the arm and the l nearly touch, green on green.
- The flower is tilted -8 degrees. It reads as a natural tilt, but it is not symmetric.
- Icon: the cream ground is quieter on a home screen than the shipping green, and the green ring with an amber oval can read as an eye. The tinted icon reads most like a letter O.
- Kerning rule shared by all three: equalising mean x-height gaps opens the round pairs by 77 to 108 u compared with Nunito's native spacing, so the whole word is a little more open than v2. The air is now even, though, and no longer bunched around the flowers.

## Files

- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at 0.60 opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, 60 u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.
- Icons (1024, flat background, no text, no transparency): `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`, `icon-alt-cream.svg`, `icon-smile.svg`, `icon-smile-dark.svg`, `icon-smile-tinted.svg`.
- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).
- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.


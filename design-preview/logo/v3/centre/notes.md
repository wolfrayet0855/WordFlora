# WordFlora logo v3, direction "centre": Centre bloom disc

Preview: http://localhost:8765/logo/v3/index.html#centre. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. Build: `python build.py --direction centre` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction centre` (PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.

**Changes in round 2:** TODO

## Idea

My own direction, "centre ring". The Flora o ring is recoloured as the flower's centre (deep amber #A65A00, 4.81:1 on cream; gold #F0C060 on dark). It sits on a **solid rose bloom disc** (#CF5D78) with shallow scallops, so at 29 px the flower reads as one shape: a rose blossom with an amber heart. Colour alone separates the decorated o from the green letters, and lightness separates the bloom from the background and from the ring (via a real gap). Geometry differs from the other two because it is a disc, not petals. The colour logic differs too: the letter itself changes role. Kerning rule shared by all three: equalising mean x-height gaps opens the round pairs by 77 to 108 u compared with Nunito's native spacing, so the whole word is a little more open than v2. The air is now even, though, and no longer bunched around the flowers.

## Construction

- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font's own o with its open counter. The Word o is a plain letter.
- **Flower.** Five circles of radius 250 u on a 230 u circle (tips at 480 u, 1.82x the o radius), one up, no tilt. The circles overlap far outside the ring, so the bloom is a disc with notches about 5 px deep at 60 px (2.5 px at 29 px), like a plum blossom.
- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (52 u twin, 62 u solo, 60 u mono-solid). A petal that would reach a neighbour (the l or the r dilated by 40 u, solo 50 u, then closed by 100 u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most 5% of it would sit behind the letter, then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: 1.000, 1.000, 1.000, 1.000, 1.000). An opening of 12 u rounds every corner.
- **Spacing rule (solver).** Kerns are solved so that every pair's mean gap is within 0.86 to 1.14 x the r-d gap on **both** bands (x-height band 10..470 u, and the full o height -11..503 u including overshoot), with the F's middle arm at least 60 u from the l. The solver picks the smallest r-d for which that is possible (the tightest word): Word pairs and d-F take the tightest legal value, the Flora o pairs 1.10 x r-d for petal room. Kerns W-o..r-a: -32.0, +93.0, +42.0, +101.0, -29.0, +117.0, +145.0, +4.5 u. Solo adds 10 u to every pair.
- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap 62 u, neighbour clearance 50 u, +10 u tracking, as an optical size.
- **Icon.** Deep green background #24472A; rose bloom #E8758F, amber ring #F0B848, counter filled deeper amber #D08A22 (tone on tone, so it reads as a flower centre rather than a letter O). Dark: #D95B7A, #E9A93A and #B8700E on #132313. Tinted: greys on black. Flower scaled by 0.8728 so its larger side is 80% of the 1024 canvas, centred on its bounding box; flat background rect.
- **SVG hygiene.** Only `<path fill>` elements (mono petals use `fill-opacity` 0.60); width/height equal the viewBox; no mask, stroke, filter, gradient, defs, use, text, image, clip-path or @import.

## Palette and WCAG contrast (A1, A2, A4)

| Pair | Colours | Ratio | Target |
|---|---|---|---|
| Word on cream (light) | `#182818` on `#FAF7F0` | 14.48 | >= 4.5 ok |
| Flora on cream (light) | `#2E803F` on `#FAF7F0` | 4.59 | >= 4.5 ok |
| Word vs Flora (light) | `#182818` on `#2E803F` | 3.15 | >= 3.0 ok |
| Petals on cream (light) | `#CF5D78` on `#FAF7F0` | 3.58 | >= 3.0 ok |
| Petals vs ring (light) | `#CF5D78` on `#2E803F` | 1.28 |  |
| Word on dark | `#DCEEDC` on `#1A2E1A` | 11.94 | >= 4.5 ok |
| Flora on dark | `#8FCB8F` on `#1A2E1A` | 7.66 | >= 4.5 ok |
| Word vs Flora (dark) | `#DCEEDC` on `#8FCB8F` | 1.56 | >= 1.3 ok |
| Petals on dark | `#DE5E7E` on `#1A2E1A` | 4.14 | >= 3.0 ok |
| Petals vs ring (dark) | `#DE5E7E` on `#8FCB8F` | 1.85 |  |
| Mono ink on white | `#182818` on `#FFFFFF` | 15.49 | >= 4.5 ok |
| Mono petals (ink at 0.60 = #747E74) on white | `#747E74` on `#FFFFFF` | 4.22 | >= 3.0 ok |

Icon colours (each part against what it sits on; worst of deutan/protan/tritan in the last column):

| Icon | Part | Hex | Against | Ratio | Worst CVD |
|---|---|---|---|---|---|
| light | petal | `#E8758F` | bg | 4.21 | 3.44 |
| light | ring | `#F0B848` | bg | 6.66 | 5.91 |
| light | pistil | `#C27A18` | ring | 1.91 | 1.86 |
| dark | petal | `#D95B7A` | bg | 4.48 | 3.58 |
| dark | ring | `#E9A93A` | bg | 7.99 | 7.09 |
| dark | pistil | `#A8620C` | ring | 2.31 | 2.26 |
| tinted | petal | `#B4B4B4` | bg | 10.13 | 10.13 |
| tinted | ring | `#7A7A7A` | bg | 4.89 | 4.89 |
| tinted | pistil | `#4A4A4A` | ring | 2.06 | 2.06 |

## Colour-vision simulation (A5)

Machado, Oliveira and Fernandes 2009, severity 1.0, applied to linear sRGB of the hex colours, then WCAG luminance (agrees with `review/cvd_sim.py --hex` to within 0.03).

| Simulation | Petals on cream | Petals on dark | Word vs Flora (light) | Word on cream | Flora on cream |
|---|---|---|---|---|---|
| deuteranopia | 3.21 | 4.73 | 3.04 | 14.64 | 4.82 |
| protanopia | 4.32 | 3.29 | 3.31 | 14.24 | 4.30 |
| tritanopia | 3.56 | 4.17 | 3.12 | 14.50 | 4.64 |

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

Worst: 14.0% (x band), 14.2% (full o band), solo 13.4% / 13.6%. F-l minimum arm gap: **60 u** (1.8 px at 29 px tall).

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
| twin | 100% | 100% | 100% | 100% | 98% |
| solo | 100% | 100% | 100% | 100% | 97% |
| mono-solid | 100% | 100% | 100% | 100% | 98% |

## Small-size geometry (A2, A3)

- Units per pixel at 29 px tall: 33.7. Ring gap 52 u = **1.55 px** (mono-solid 60 u = 1.78 px; A2 needs >= 1.0 px, i.e. >= 34 u).
- Widest visible width of each petal at 29 px tall: 12.8, 12.8, 12.8, 12.8, 12.8 px (A3 needs >= 4).
- Petals are fused into one bloom; notch depth between lobes (tip radius minus notch radius) at 60 px tall: 7.5, 7.5, 7.5, 7.5, 7.5 px; at 29 px: 3.6, 3.6, 3.6, 3.6, 3.6 px.
- Longest straight run on the bloom outline: 4.4 px at 320 px tall.
- The o counter at 29 px tall: 5.4 x 7.4 px.

## Sizing contract (A10)

| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |
|---|---|---|---|---|
| twin (wordmark*.svg) | 20 31 5708 976 | 5.85 : 1 | 29.4 pt | 44.8 pt |
| solo | 20 31 5788 976 | 5.93 : 1 | 29.0 pt | 44.2 pt |

v2 was 5.83 : 1, about 29.5 pt tall at 172 pt.

## Self-check, A1 to A13

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | petals 3.58 on cream, 4.14 on dark (>= 3.0) |
| A2 | **pass** | petal/ring 1.28 light, 1.85 dark; ring gap 52 u = 1.55 px at 29 px tall (>= 1.0), mono-solid 1.78 px |
| A3 | **pass** | petal width at 29 px 12.8 px min (>= 4); marginal: at 60 px the top and two lower lobes are clear, and the two side lobes show as shoulders behind the l and the r (notch about 2.9 px). Five can be counted in light, dark and mono, but only just. At 29 px it reads as one rose flower shape, the stated aim |
| A4 | **pass** | Word/Flora 3.15 light (>= 3.0), 1.56 dark (>= 1.3); Word 14.48, Flora 4.59 on cream; 11.94, 7.66 on dark (>= 4.5) |
| A5 | **pass** | worst petals on cream 3.21 (>= 3.0), worst Word/Flora 3.04 (>= 2.0) across deutan, protan, tritan |
| A6 | **FAIL** | worst pair 14.0% x band / 14.2% full o band (solo 13.4 / 13.6; <= 15); F-l arm gap 60 u; least-visible petal 97% (>= 80); by eye: TODO |
| A7 | **pass** | reads "WordFlora" at 29 px in light, dark and mono; the amber o is a letter in its own colour. Risk: in mono-solid the black scalloped disc around the o can read as a cog or rosette badge, though the o still reads through its white gap |
| A8 | **pass** | 1024, flat green rect, no text or transparency; one plum-blossom flower; reads as a flower at 29 px; no face |
| A9 | **pass** | light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px |
| A11 | **pass** | no bounce, gloss, sparkle or bevel; amber is matte; no face |
| A12 | **pass** | by description only, reviewers to confirm: a five-lobed disc is the classic Japanese plum-blossom (ume) crest shape, which is heraldry, not an app mark. None of Duolingo, Forest, Headspace, Calm, Finch, Wordscapes, Lily's Garden, Gardenscapes, PictureThis, Seek, Flora, Blossom or Planta uses it. The tinted icon could be mistaken for a donut or an "O" button, which is the critique's worry about the v2 icon. Nothing copied |
| A10 | **pass** | 5.85 : 1; 29.4 pt at 172 pt wide (26-34), 44.8 pt at 262 pt |
| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |

## Honest weaknesses

- The ring has to be a deep, slightly brown amber (#A65A00) to stay at 4.5:1 as a letter. Any lighter amber looks better but drops below 4.5:1.
- The o in a third colour splits "Flora" in colour as "Fl-o-ra". The word still reads, but the Word/Flora split is no longer the only colour change.
- Mono-solid (Increase Contrast) turns the bloom into a black scalloped disc that can read as a cog or rosette badge.
- The lobes are shallow by design: they are easy to see at 29 px as one shape, but only marginally countable at 60 px on the sides.
- In the icon the centre (ring plus counter) is large against the petals, and the tinted icon leans towards "O" or a donut.
- Same F-l (32 u) and tracking notes as hero.

## Files

- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at 0.60 opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, 60 u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.
- Icons (1024, flat background, no text, no transparency): `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`.
- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).
- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.


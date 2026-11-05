# WordFlora logo v3, direction "unified": Unified, with the smile

Preview: http://localhost:8765/logo/v3/index.html#unified. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. Build: `python build.py --direction unified` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction unified` (PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.

**Changes in round 2:** TODO

## Idea

One flower for the whole brand, with the smile. Five **round** petals (circles) fused into a single scalloped bloom, in amber (#C27200 light, 3.44:1 on cream; #E59A2E dark). It is the shipping icon's friendliness and the wordmark's o in one geometry. In the wordmark the bloom sits behind the Flora o; in the icon the exact same five petals surround the o's outer silhouette, filled cream, wearing the face. The colour logic is fixed in both modes: petals amber, letters green ("Flora" #2E803F light, #8FCB8F dark). Kerning rule shared by all three: equalising mean x-height gaps opens the round pairs by 77 to 108 u compared with Nunito's native spacing, so the whole word is a little more open than v2. The air is now even, though, and no longer bunched around the flowers.

## Construction

- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font's own o with its open counter. The Word o is a plain letter.
- **Flower.** Five circles of radius 200 u on a 295 u circle (tips at 495 u, 1.88x the o radius), one up, turned -8 degrees like the hero. Adjacent circles overlap only under the ring, so outside the gap each lobe shows as its own petal with notches 7 to 9 px deep at 60 px.
- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (52 u twin, 62 u solo, 60 u mono-solid). A petal that would reach a neighbour (the l or the r dilated by 40 u, solo 50 u, then closed by 100 u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most 5% of it would sit behind the letter, then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: 1.000, 1.000, 1.000, 1.000, 1.000). An opening of 12 u rounds every corner.
- **Mono-solid slits.** In `wordmark-mono-solid.svg` five radial bars 30 u wide are cut along the bisectors between the lobes, so in solid ink the bloom is five petals, not a gear.
- **Spacing rule (solver).** Kerns are solved so that every pair's mean gap is within 0.86 to 1.14 x the r-d gap on **both** bands (x-height band 10..470 u, and the full o height -11..503 u including overshoot), with the F's middle arm at least 60 u from the l. The solver picks the smallest r-d for which that is possible (the tightest word): Word pairs and d-F take the tightest legal value, the Flora o pairs 1.10 x r-d for petal room. Kerns W-o..r-a: -32.0, +93.0, +42.0, +101.0, -29.0, +117.0, +145.0, +4.5 u. Solo adds 10 u to every pair.
- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap 62 u, neighbour clearance 50 u, +10 u tracking, as an optical size.
- **Icon.** Green background #356B25 (amber petals #F5BC48 at 3.71:1 on it). The centre is the o's outer silhouette (the o with its counter filled) in cream #FBF4E4, with the face in ink. Dark: #E59A2E petals, #EFE6C8 centre, on #1A2E1A. Tinted: grey petals, white centre, black face. Flower scaled by 0.8572 so its larger side is 80% of the 1024 canvas, centred on its bounding box; flat background rect.
- **Face rule.** **The face lives in the icon and in illustrations, never inside a letter.** The flower is always five round amber petals around an o-shaped centre. In type the centre is the letter o: ring, open counter, no face. In the icon (and any mascot or illustration use) the centre is filled and wears the face: two dots and one arc, nothing more. Tested against the brief's condition: at 29 px tall the o counter is only about 5 x 7 px, too small for two eyes and a mouth without filling the counter. A face there would stop the o reading as a letter, so the wordmark and the solo lockup carry no face.
- **SVG hygiene.** Only `<path fill>` elements (mono petals use `fill-opacity` 0.60); width/height equal the viewBox; no mask, stroke, filter, gradient, defs, use, text, image, clip-path or @import.

## Palette and WCAG contrast (A1, A2, A4)

| Pair | Colours | Ratio | Target |
|---|---|---|---|
| Word on cream (light) | `#182818` on `#FAF7F0` | 14.48 | >= 4.5 ok |
| Flora on cream (light) | `#2E803F` on `#FAF7F0` | 4.59 | >= 4.5 ok |
| Word vs Flora (light) | `#182818` on `#2E803F` | 3.15 | >= 3.0 ok |
| Petals on cream (light) | `#C86800` on `#FAF7F0` | 3.61 | >= 3.0 ok |
| Petals vs ring (light) | `#C86800` on `#2E803F` | 1.27 |  |
| Word on dark | `#DCEEDC` on `#1A2E1A` | 11.94 | >= 4.5 ok |
| Flora on dark | `#8FCB8F` on `#1A2E1A` | 7.66 | >= 4.5 ok |
| Word vs Flora (dark) | `#DCEEDC` on `#8FCB8F` | 1.56 | >= 1.3 ok |
| Petals on dark | `#E59A2E` on `#1A2E1A` | 6.20 | >= 3.0 ok |
| Petals vs ring (dark) | `#E59A2E` on `#8FCB8F` | 1.24 |  |
| Mono ink on white | `#182818` on `#FFFFFF` | 15.49 | >= 4.5 ok |
| Mono petals (ink at 0.60 = #747E74) on white | `#747E74` on `#FFFFFF` | 4.22 | >= 3.0 ok |

Icon colours (each part against what it sits on; worst of deutan/protan/tritan in the last column):

| Icon | Part | Hex | Against | Ratio | Worst CVD |
|---|---|---|---|---|---|
| light | petal | `#FBF4E4` | bg | 5.84 | 5.54 |
| light | disc | `#F5BC48` | bg | 3.71 | 3.24 |
| light | face | `#1F321F` | disc | 7.93 | 7.11 |
| dark | petal | `#EFE6C8` | bg | 11.60 | 11.24 |
| dark | disc | `#E59A2E` | bg | 6.20 | 5.37 |
| dark | face | `#0F1C0F` | disc | 7.54 | 6.57 |
| tinted | petal | `#E8E8E8` | bg | 17.14 | 17.14 |
| tinted | disc | `#8C8C8C` | bg | 6.25 | 6.25 |
| tinted | face | `#000000` | disc | 6.25 | 6.25 |

## Colour-vision simulation (A5)

Machado, Oliveira and Fernandes 2009, severity 1.0, applied to linear sRGB of the hex colours, then WCAG luminance (agrees with `review/cvd_sim.py --hex` to within 0.03).

| Simulation | Petals on cream | Petals on dark | Word vs Flora (light) | Word on cream | Flora on cream |
|---|---|---|---|---|---|
| deuteranopia | 3.25 | 6.76 | 3.04 | 14.64 | 4.82 |
| protanopia | 4.35 | 5.37 | 3.31 | 14.24 | 4.30 |
| tritanopia | 3.65 | 6.15 | 3.12 | 14.50 | 4.64 |

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
| twin | 100% | 99% | 100% | 100% | 98% |
| solo | 100% | 99% | 100% | 100% | 97% |
| mono-solid | 99% | 98% | 98% | 99% | 97% |

## Small-size geometry (A2, A3)

- Units per pixel at 29 px tall: 34.2. Ring gap 52 u = **1.52 px** (mono-solid 60 u = 1.75 px; A2 needs >= 1.0 px, i.e. >= 35 u).
- Widest visible width of each petal at 29 px tall: 11.7, 11.7, 11.7, 11.7, 11.7 px (A3 needs >= 4).
- Petals are fused into one bloom; notch depth between lobes (tip radius minus notch radius) at 60 px tall: 9.4, 29.8, 9.4, 29.8, 29.8 px; at 29 px: 4.6, 14.4, 4.6, 14.4, 14.4 px.
- Longest straight run on the bloom outline: 27.8 px at 320 px tall.
- The o counter at 29 px tall: 5.3 x 7.3 px.

## Sizing contract (A10)

| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |
|---|---|---|---|---|
| twin (wordmark*.svg) | 20 21 5708 993 | 5.75 : 1 | 29.9 pt | 45.6 pt |
| solo | 20 21 5788 993 | 5.83 : 1 | 29.5 pt | 44.9 pt |

v2 was 5.83 : 1, about 29.5 pt tall at 172 pt.

## Self-check, A1 to A13

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | petals 3.61 on cream, 6.20 on dark (>= 3.0) |
| A2 | **pass** | petal/ring 1.27 light, 1.24 dark; ring gap 52 u = 1.52 px at 29 px tall (>= 1.0), mono-solid 1.75 px |
| A3 | **pass** | petal width at 29 px 11.7 px min (>= 4); 5 lobes countable at 60 px in light, dark, mono and mono-solid; at 29 px the scalloped amber bloom reads as a flower with the o in its centre |
| A4 | **pass** | Word/Flora 3.15 light (>= 3.0), 1.56 dark (>= 1.3); Word 14.48, Flora 4.59 on cream; 11.94, 7.66 on dark (>= 4.5) |
| A5 | **pass** | worst petals on cream 3.25 (>= 3.0), worst Word/Flora 3.04 (>= 2.0) across deutan, protan, tritan |
| A6 | **FAIL** | worst pair 14.0% x band / 14.2% full o band (solo 13.4 / 13.6; <= 15); F-l arm gap 60 u; least-visible petal 97% (>= 80); by eye: TODO |
| A7 | **pass** | reads "WordFlora" at 29 px in all variants; the green o inside a cream gap on the amber bloom reads as o. Mono-solid keeps a visible white gap, so the o survives |
| A8 | **pass** | 1024, flat green rect, no text or transparency; one flower; reads as a smiling flower at 29 px, and at 60 px the eyes (about 3 px) and the smile are legible |
| A9 | **pass** | light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px |
| A11 | **pass** | no bounce, gloss, sparkle or bevel; amber is matte and not gold-on-red; face is exactly two dots and one arc, icon only |
| A12 | **pass** | by description only, reviewers to confirm: the nearest family is "smiling flower" art (Takashi Murakami's many-petalled grinning flowers, generic sticker daisies). This one has five round petals and a small two-dot face, so it is not confusable with those. No app mark among Duolingo, Forest, Headspace (orange dot), Calm, Finch, Wordscapes, Lily's Garden, Gardenscapes, PictureThis, Seek, Flora, Blossom or Planta uses a five-round-petal smiling flower. Closest in spirit: the shipping WordFlora icon itself. Nothing copied |
| A10 | **pass** | 5.75 : 1; 29.9 pt at 172 pt wide (26-34), 45.6 pt at 262 pt |
| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |

## Honest weaknesses

- The side lobes tuck behind the l and the r (85 to 89% visible). At large sizes there is the same small notch at the l's foot as in hero.
- Light amber #C27200 is ochre-orange and reads slightly brown in renders; it is the lightest amber that still reaches 3:1 on cream. Amber vs the green ring is 1.33:1, so the 1.17 px gap does the separating.
- Dark-mode "Flora" changes from v2's gold to light green (#8FCB8F), to keep "petals amber, letters green". That gives up the gold-on-dark look the critique liked.
- The smile appears only in the icon (by rule), so the wordmark alone is less warm than the icon.
- Same F-l (32 u) and tracking notes as hero.

## Files

- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at 0.60 opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, 60 u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.
- Icons (1024, flat background, no text, no transparency): `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`.
- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).
- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.


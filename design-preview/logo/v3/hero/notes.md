# WordFlora logo v3, direction "hero": Hero flower

Preview: http://localhost:8765/logo/v3/index.html#hero. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. Build: `python build.py --direction hero` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction hero` (PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.

**Changes in round 2:** sRGB PNGs (no ICC profile). The icon centre is now the o with its counter filled gold plus a round amber pistil, on a deep green ground (#1C3820), so there is no eye and no letter O. The cream-ground version is kept as `icon-alt-cream.svg`. New owner option `icon-smile*.svg` puts the two-dot-one-arc face on that centre disc. Ring gap 40 to 52 u (mono-solid 60 u). A petal that would reach the l or the r is now scaled to fit instead of being cut, so every petal keeps a complete rounded tip and the notch at the l's foot is gone. Spacing is solved on both bands. Round 2b re-spaced to the corrected rule (native r-d reference, F-l up to +30% with a 45 u arm gap) and scaled the flower to 0.92.

## Idea

One hero flower, nothing else. "Word" is plain ink green (#182818) with no decoration. The Flora o carries one large five-petal rose flower with **separate** petals: round-ended teardrops with the background showing between neighbours. Light-mode rose #C9506C is 4.05:1 on cream. The icon is the same flower: same petals, the o's silhouette as a gold centre disc, and a round amber pistil.

## Construction

- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font's own o with its open counter. The Word o is a plain letter.
- **Flower.** Five teardrop petals (cubic, round outer end) from r0 = 110 u to tip T = 505 u (1.91x the o radius), width parameter 172 u, one petal up and the flower turned -8 degrees; the whole flower is then scaled to 0.92 (round 2b), tip 465 u, 1.76x the o radius. In the wordmark the right and left petals are scaled about the flower centre to clear the r and the l; the scales are listed under Cuts and fit. The icon uses the nominal, unscaled flower.
- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (52 u twin, 62 u solo, 60 u mono-solid). A petal that would reach a neighbour (the l or the r dilated by 40 u, solo 40 u, then closed by 100 u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most 0% of it would sit behind the letter (4x that in the solo lockup), then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: 1.000, 0.969, 1.000, 1.000, 0.995). An opening of 12 u rounds every corner.
- **Spacing rule (round 2b).** The reference is Nunito's native r-d gap: 208.8 u on the x-height band (10..470 u), 214.5 u on the full o height (-11..503 u, including overshoot), with rows every 10 u (v2 sampled every 20 u and quoted about 203). Every pair except F-l must sit within +-15% of it on the x band and +-20% on the o band; F-l may reach +30% on either band with an arm gap of at least 45 u. Each pair takes the tightest legal kern (working margin 0.86 x / 0.81 o), and no pair comes closer than 45 u anywhere (the r's arm against the d and the a). The Flora o pairs open to the legal maximum, because at the tightest kern no petal arrangement keeps 80% visible (see notes below). Kerns W-o..r-a: -68.0, +56.5, -26.0, +61.5, -44.0, +80.5, +108.5, -25.0 u. Solo adds 10 u to every pair except F-l, l-o and o-r (already at their limits).
- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap 62 u, neighbour clearance 40 u, +10 u tracking, as an optical size.
- **Icon.** Deep green ground #1C3820 (dark #142414). Rose petals #E26582 (the dark-mode wordmark rose). The centre is the o with its counter filled in gold #F0C060 (the dark-mode Flora gold), with a round pistil #B8650A whose diameter is 0.40x the ring's outer width. Tinted: grey petals, white disc, grey pistil on black. `icon-alt-cream.svg`: the same flower on cream with the light-mode wordmark colours (rose #C9506C, green #2E803F disc, amber pistil), rendered at 180/60/29 only so the owner can compare. `icon-smile*.svg`: the default icon with the face (two dots and one arc, ink #1A2E1A, tilted -8 degrees with the flower) in place of the pistil. Flower scaled by 0.9131 so its larger side is 80% of the 1024 canvas, centred on its bounding box; flat background rect.
- **Face rule.** **The face lives in the icon and in illustrations, never inside a letter.** The smile is an owner option (`icon-smile*.svg`). It sits on the filled centre disc of the icon. The wordmark o always keeps its open counter and never gets a face: at 29 px tall the counter is about 5 x 7 px, too small for a face without turning the letter into an emoji.
- **Icon colour rule.** The icon uses the dark-mode wordmark colours (rose #E26582, gold #F0C060) on deep green, because the light-mode rose would be only 2.3:1 on a green ground. The cream alternative uses the light-mode colours exactly.
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
| W-o | 180 (118) | -13.9% | 191 (118) | -11.1% | -9.1% | -68.0 |
| o-r | 180 (140) | -13.8% | 204 (140) | -4.7% | -9.0% | +56.5 |
| r-d | 183 (46) | -12.5% | 191 (46) | -10.8% | -7.7% | -26.0 |
| d-F | 180 (177) | -13.7% | 182 (177) | -15.2% | -8.9% | +61.5 |
| F-l | 261 (45) | +25.1% | 276 (45) | +28.8% | +25.1% | -44.0 |
| l-o | 235 (147) | +12.5% | 247 (146) | +15.1% | +12.5% | +80.5 |
| o-r | 232 (191) | +11.0% | 246 (191) | +14.7% | +11.0% | +108.5 |
| r-a | 221 (45) | +6.0% | 223 (45) | +4.0% | +10.8% | -25.0 |

Worst pair except F-l: 13.9% (x band, limit 15), 15.2% (full o band, limit 20); solo 12.5% / 15.1%. F-l: +25.1% x / +28.8% o (limit +30), minimum arm gap **45 u** (1.4 px at 29 px tall; limit 45). "Word" ink width 2655 u vs v2 2853 u (-6.9%).

**Round 2b spacing.** The rule now measures against Nunito's native r-d. Every Word pair and d-F takes its tightest legal kern: about -14% on the x band, with no pair closer than 45 u, which keeps the r's arm off the d and the a. "Word" is 2655 u of ink against v2's 2853 (-6.9%). At the tightest Flora gaps (l-o, o-r at -14%), no petal arrangement keeps 80% of a petal visible. Even at the widest legal gaps (+12.5% / +11.0% x, +15.1% / +14.7% o), a full-size flower scaled no lower than 0.94 per petal reaches only 72%. So, against the brief's "do not reopen", two levers were used instead. (1) The Flora o pairs sit at the legal maximum, still tighter than round 2 (235 vs 272 u). (2) The whole flower is scaled uniformly (hero and unified 0.92, centre 0.91), the same in the wordmark and the icon. The tightest-gap alternative needed a 0.80 flower, which turns the petals back into v2-style slivers round a heavy ring (rejected by eye). By eye on `compare/word-alone-320.png` (v2 above v3, same letter size), v3 "Word" is visibly tighter than v2 and o-r-d no longer reads looser: **the P3 eye check passes**. W-o and r-d sit close but clear, and the r's arm keeps 45 u from the d.

Petals tucked behind a neighbour, share of each petal (outside the ring gap) left visible, petals clockwise from the top one:

| | P1 top | P2 right | P3 lower right | P4 lower left | P5 left |
|---|---|---|---|---|---|
| twin | 100% | 85% | 100% | 100% | 98% |
| solo | 100% | 84% | 100% | 100% | 98% |
| mono-solid | 100% | 84% | 100% | 100% | 98% |

## Small-size geometry (A2, A3)

- Units per pixel at 29 px tall: 32.4. Ring gap 52 u = **1.61 px** (mono-solid 60 u = 1.85 px; A2 needs >= 1.0 px, i.e. >= 33 u).
- Widest visible width of each petal at 29 px tall: 9.3, 9.1, 9.3, 9.3, 9.3 px (A3 needs >= 4).
- Clear gap between neighbouring petals at 60 px tall: 5.8, 6.3, 4.9, 6.1, 6.0 px.
- Longest straight run on the bloom outline: 3.0 px at 320 px tall.
- The o counter at 29 px tall: 5.6 x 7.7 px.

**Pixel checks on the rendered PNGs** (`python render.py` prints them):

See `compare/pixel-checks.json`: exact sRGB fills in `png/wordmark-h320.png`, sheet margins, and the background-coloured pixel either side of the ring on `png/wordmark-mono-solid-h29.png`.

## Sizing contract (A10)

| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |
|---|---|---|---|---|
| twin (wordmark*.svg) | 20 46 5410 939 | 5.76 : 1 | 29.9 pt | 45.5 pt |
| solo | 20 46 5460 939 | 5.82 : 1 | 29.6 pt | 45.1 pt |

v2 was 5.83 : 1, about 29.5 pt tall at 172 pt.

## Self-check, A1 to A13

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | petals 4.05 on cream, 4.43 on dark (>= 3.0) |
| A2 | **pass** | petal/ring 1.13 light, 1.93 dark; ring gap 52 u = 1.61 px at 29 px tall (>= 1.0), mono-solid 1.85 px |
| A3 | **pass** | petal width at 29 px 9.1 px min (>= 4); 5 petals countable at 60 px in light, dark, mono and mono-solid (`png/*-h60.png`); at 29 px it reads as a small rose flower round the o, not a halo |
| A4 | **pass** | Word/Flora 3.15 light (>= 3.0), 1.39 dark (>= 1.3); Word 14.48, Flora 4.59 on cream; 11.94, 8.56 on dark (>= 4.5) |
| A5 | **pass** | worst petals on cream 3.59 (>= 3.0), worst Word/Flora 3.04 (>= 2.0) across deutan, protan, tritan |
| A6 | **pass** | vs native r-d: worst pair 13.9% x band (<= 15), 15.2% o band (<= 20), solo 12.5 / 15.1; F-l +25.1 / +28.8% (<= 30), arm gap 45 u (>= 45); "Word" -6.9% vs v2; least-visible petal 84% (>= 80); by eye: "Word" 6.9% narrower than v2 and o-r-d no tighter-looking than needed; P3 eye check passes |
| A7 | **pass** | reads "WordFlora" at 29 px in all seven variants; the o keeps its full ring and open counter inside a 1.49 px gap (mono-solid 1.72 px) and reads as a letter |
| A8 | **pass** | 1024, flat deep-green rect, no text or transparency; one flower; at 29 px a rose flower with a gold centre. The centre is a disc with a round pistil, so it reads neither as an O nor as an eye. Smile option: face legible at 60 px, fades to a gold disc at 29 px |
| A9 | **pass** | light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px |
| A11 | **pass** | baseline flat, no bounce; no primaries, gloss, sparkle or bevel; no face in the default icon; the smile option is two dots and one arc |
| A12 | **pass** | by description only, reviewers still to confirm. The nearest family is the Mary Quant daisy (five round petals around a round centre, fashion and cosmetics). Separate teardrop petals, the -8 degree tilt and the gold disc on deep green keep it apart. Not close to Blossom, Flora, Forest, PictureThis, Seek, Duolingo, Finch, Headspace, Calm, Wordscapes, Lily's Garden or Gardenscapes. The smile option is not Flowey: rose petals, not yellow; gold centre, not white. Nothing copied |
| A10 | **pass** | 5.76 : 1; 29.9 pt at 172 pt wide (26-34), 45.5 pt at 262 pt |
| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |

## Honest weaknesses

- The right and left petals are drawn slightly smaller in the wordmark than in the icon (scales listed above), so the wordmark flower is not perfectly regular. At 320 px the difference is visible only if you look for it.
- Height at 172 pt is 29.9 pt (round 2b), not 31.5. The tighter word is shorter overall, and the flower is scaled to 0.92.
- Petals are 8% smaller than in round 2, so the flower is a little less dominant against the ring at 29 px.
- In greyscale the rose petals and the green Flora letters are the same mid grey (1.13:1); only the 1.5 px gap separates them.
- The smile option sits close to the shipping icon's idea (a smiling flower), so it is a smaller break from the old icon than the plain pistil.
- **Round 2b spacing.** The rule now measures against Nunito's native r-d. Every Word pair and d-F takes its tightest legal kern: about -14% on the x band, with no pair closer than 45 u, which keeps the r's arm off the d and the a. "Word" is 2655 u of ink against v2's 2853 (-6.9%). At the tightest Flora gaps (l-o, o-r at -14%), no petal arrangement keeps 80% of a petal visible. Even at the widest legal gaps (+12.5% / +11.0% x, +15.1% / +14.7% o), a full-size flower scaled no lower than 0.94 per petal reaches only 72%. So, against the brief's "do not reopen", two levers were used instead. (1) The Flora o pairs sit at the legal maximum, still tighter than round 2 (235 vs 272 u). (2) The whole flower is scaled uniformly (hero and unified 0.92, centre 0.91), the same in the wordmark and the icon. The tightest-gap alternative needed a 0.80 flower, which turns the petals back into v2-style slivers round a heavy ring (rejected by eye). By eye on `compare/word-alone-320.png` (v2 above v3, same letter size), v3 "Word" is visibly tighter than v2 and o-r-d no longer reads looser: **the P3 eye check passes**. W-o and r-d sit close but clear, and the r's arm keeps 45 u from the d.

## Files

- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at 0.60 opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, 60 u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.
- Icons (1024, flat background, no text, no transparency): `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`, `icon-alt-cream.svg`, `icon-smile.svg`, `icon-smile-dark.svg`, `icon-smile-tinted.svg`.
- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).
- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.


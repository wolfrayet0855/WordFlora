# WordFlora logo v3, direction "unified": Unified, with the smile

Preview: http://localhost:8765/logo/v3/index.html#unified. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. Build: `python build.py --direction unified` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction unified` (PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.

**Changes in round 2:** sRGB PNGs. The icon inverts the wordmark's roles, as in the shipping icon: petals cream #FBF4E4, centre amber #F5BC48, face ink #1F321F (7.93:1 on the amber) and tilted -8 degrees with the bloom, which moves it away from Flowey. Light bloom #C27200 becomes the more orange #C86800 (at least 3.27:1 on cream under every simulation). The mono-solid bloom gets five radial slits so it reads as five petals, not a gear. Ring gap 52 u (mono-solid 60 u). Round 2b re-spaced to the corrected rule and scaled the flower to 0.92. Lobes that would reach a neighbour are scaled to fit, with at most 0.5% left to tuck behind the letter.

## Idea

One flower for the whole brand, with the smile. Five round petals (circles) fused into one scalloped bloom: orange-amber in the wordmark (#C86800 light, #E59A2E dark), cream in the icon. In the wordmark the bloom sits behind the Flora o. In the icon the same five petals surround the o's outer silhouette, filled amber and wearing the face.

## Construction

- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font's own o with its open counter. The Word o is a plain letter.
- **Flower.** Five circles of radius 200 u on a 295 u circle (tips at 495 u, 1.88x the o radius), one up, turned -8 degrees like the hero, then scaled to 0.92 (round 2b): tips 455 u. Adjacent circles overlap only under the ring, so outside the gap each lobe shows as its own petal.
- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (52 u twin, 62 u solo, 60 u mono-solid). A petal that would reach a neighbour (the l or the r dilated by 40 u, solo 40 u, then closed by 100 u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most 0.5% of it would sit behind the letter (4x that in the solo lockup), then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: 1.000, 0.995, 1.000, 1.000, 0.970). An opening of 12 u rounds every corner.
- **Mono-solid slits.** In `wordmark-mono-solid.svg` five radial bars 30 u wide are cut along the bisectors between the lobes, so in solid ink the bloom is five petals, not a gear.
- **Spacing rule (round 2b).** The reference is Nunito's native r-d gap: 208.8 u on the x-height band (10..470 u), 214.5 u on the full o height (-11..503 u, including overshoot), with rows every 10 u (v2 sampled every 20 u and quoted about 203). Every pair except F-l must sit within +-15% of it on the x band and +-20% on the o band; F-l may reach +30% on either band with an arm gap of at least 45 u. Each pair takes the tightest legal kern (working margin 0.86 x / 0.81 o), and no pair comes closer than 45 u anywhere (the r's arm against the d and the a). The Flora o pairs open to the legal maximum, because at the tightest kern no petal arrangement keeps 80% visible (see notes below). Kerns W-o..r-a: -68.0, +56.5, -26.0, +61.5, -44.0, +80.5, +108.5, -25.0 u. Solo adds 10 u to every pair except F-l, l-o and o-r (already at their limits).
- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap 62 u, neighbour clearance 40 u, +10 u tracking, as an optical size.
- **Icon.** Green ground #356B25. Cream petals #FBF4E4 (5.84:1). Centre: the o's outer silhouette in amber #F5BC48, with the face in ink #1F321F tilted -8 degrees. Dark: #EFE6C8 petals, #E59A2E centre, face #0F1C0F (7.54:1), on #1A2E1A. Tinted: light-grey petals, mid-grey centre, black face. Flower scaled by 0.9317 so its larger side is 80% of the 1024 canvas, centred on its bounding box; flat background rect.
- **Face rule.** **The face lives in the icon and in illustrations, never inside a letter.** The flower is always five round petals around an o-shaped centre. In type the centre is the letter o: ring, open counter, no face. In the icon the centre is filled and wears the face: two dots and one arc, nothing more, turned with the bloom. At 29 px tall the o counter is about 5 x 7 px, so the wordmark and the solo lockup carry no face.
- **Icon colour rule.** The icon inverts the wordmark's roles: petals cream, centre amber (the shipping icon's logic). The wordmark is petals amber, letters green.
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
| twin | 100% | 97% | 100% | 100% | 85% |
| solo | 100% | 99% | 100% | 100% | 97% |
| mono-solid | 100% | 97% | 100% | 100% | 83% |

## Small-size geometry (A2, A3)

- Units per pixel at 29 px tall: 32.1. Ring gap 52 u = **1.62 px** (mono-solid 60 u = 1.87 px; A2 needs >= 1.0 px, i.e. >= 33 u).
- Widest visible width of each petal at 29 px tall: 11.5, 11.4, 11.5, 11.5, 11.1 px (A3 needs >= 4).
- Petals are fused into one bloom; notch depth between lobes (tip radius minus notch radius) at 60 px tall: 29.2, 29.1, 29.2, 29.2, 28.3 px; at 29 px: 14.1, 14.1, 14.1, 14.1, 13.7 px.
- Longest straight run on the bloom outline: 25.1 px at 320 px tall.
- The o counter at 29 px tall: 5.7 x 7.7 px.

**Pixel checks on the rendered PNGs** (`python render.py` prints them):

See `compare/pixel-checks.json`: exact sRGB fills, sheet margins, the ring gap pixel on mono-solid-h29, and a near-background pixel along each of the five slits at 29 px.

## Sizing contract (A10)

| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |
|---|---|---|---|---|
| twin (wordmark*.svg) | 20 46 5410 932 | 5.80 : 1 | 29.6 pt | 45.1 pt |
| solo | 20 46 5460 932 | 5.86 : 1 | 29.4 pt | 44.7 pt |

v2 was 5.83 : 1, about 29.5 pt tall at 172 pt.

## Self-check, A1 to A13

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | petals 3.61 on cream, 6.20 on dark (>= 3.0) |
| A2 | **pass** | petal/ring 1.27 light, 1.24 dark; ring gap 52 u = 1.62 px at 29 px tall (>= 1.0), mono-solid 1.87 px |
| A3 | **pass** | petal width at 29 px 11.1 px min (>= 4); 5 lobes countable at 60 px in light, dark, mono and mono-solid (slits); at 29 px the scalloped orange bloom reads as a flower with the o in its centre |
| A4 | **pass** | Word/Flora 3.15 light (>= 3.0), 1.56 dark (>= 1.3); Word 14.48, Flora 4.59 on cream; 11.94, 7.66 on dark (>= 4.5) |
| A5 | **pass** | worst petals on cream 3.25 (>= 3.0), worst Word/Flora 3.04 (>= 2.0) across deutan, protan, tritan |
| A6 | **pass** | vs native r-d: worst pair 13.9% x band (<= 15), 15.2% o band (<= 20), solo 12.5 / 15.1; F-l +25.1 / +28.8% (<= 30), arm gap 45 u (>= 45); "Word" -6.9% vs v2; least-visible petal 83% (>= 80); by eye: "Word" 6.9% narrower than v2 and o-r-d no tighter-looking than needed; P3 eye check passes |
| A7 | **pass** | reads "WordFlora" at 29 px in all variants; the green o inside a cream gap on the orange bloom reads as o. Mono-solid: the slits split the bloom into five petals and the 60 u gap keeps the o clear, so it no longer reads as a cog |
| A8 | **pass** | 1024, flat green rect, no text or transparency; one flower; a smiling cream daisy with an amber face at 29 px; at 60 px the eyes (about 3 px) and the tilted smile are legible |
| A9 | **pass** | light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px |
| A11 | **pass** | no bounce, gloss, sparkle or bevel; amber is matte and not gold-on-red; face is exactly two dots and one arc, icon only |
| A12 | **pass** | by description only, reviewers to confirm. Flowey (Undertale) is yellow petals round a white face. This icon is now cream petals round an amber face, tilted, which is the shipping WordFlora daisy's logic, and it is no longer a yellow-petal, white-face match. It stays in the generic "smiling daisy" family (stickers, emoji), close to the shipping icon by design. Nothing copied |
| A10 | **pass** | 5.80 : 1; 29.6 pt at 172 pt wide (26-34), 45.1 pt at 262 pt |
| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |

## Honest weaknesses

- The icon is close to the shipping icon (a smiling daisy), so the brand change is small. That is good for continuity and weak for distinctiveness.
- Amber #C86800 vs the green ring is low in contrast, so the 1.49 px gap does all the separating.
- Dark-mode Flora is light green (#8FCB8F), not v2's gold, to keep "petals amber, letters green".
- The right lobe is fitted against the r with a short flat (about 26 px at 320 px tall) where it meets the r's stem; the left lobe is scaled to 0.965 and keeps a round end.
- **Round 2b spacing.** The rule now measures against Nunito's native r-d. Every Word pair and d-F takes its tightest legal kern: about -14% on the x band, with no pair closer than 45 u, which keeps the r's arm off the d and the a. "Word" is 2655 u of ink against v2's 2853 (-6.9%). At the tightest Flora gaps (l-o, o-r at -14%), no petal arrangement keeps 80% of a petal visible. Even at the widest legal gaps (+12.5% / +11.0% x, +15.1% / +14.7% o), a full-size flower scaled no lower than 0.94 per petal reaches only 72%. So, against the brief's "do not reopen", two levers were used instead. (1) The Flora o pairs sit at the legal maximum, still tighter than round 2 (235 vs 272 u). (2) The whole flower is scaled uniformly (hero and unified 0.92, centre 0.91), the same in the wordmark and the icon. The tightest-gap alternative needed a 0.80 flower, which turns the petals back into v2-style slivers round a heavy ring (rejected by eye). By eye on `compare/word-alone-320.png` (v2 above v3, same letter size), v3 "Word" is visibly tighter than v2 and o-r-d no longer reads looser: **the P3 eye check passes**. W-o and r-d sit close but clear, and the r's arm keeps 45 u from the d.

## Files

- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at 0.60 opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, 60 u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.
- Icons (1024, flat background, no text, no transparency): `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`.
- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).
- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.


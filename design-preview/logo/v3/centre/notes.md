# WordFlora logo v3, direction "centre": Centre bloom disc

Preview: http://localhost:8765/logo/v3/index.html#centre. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. Build: `python build.py --direction centre` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction centre` (PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.

**Changes in round 2:** sRGB PNGs. The o ring is Flora green again (#2E803F light, #8FCB8F dark), so "Flora" is one colour and the rose disc alone marks the flower. The bloom is rebuilt from r = 215 u circles on a 270 u circle (tips 485 u), turned -8 degrees: notches 6.4 to 7.5 px at 60 px on all five lobes, no straight edge longer than 5 px at 320 px; the left lobe is scaled to 0.963 to clear the l. Icon: ring and counter scaled to 0.75x, counter filled with the ring colour plus a round pistil, tinted centre mid-grey; ground #1F3D24 so the petals stay at least 3.44:1 under protanopia. Ring gap 52 u (mono-solid 60 u). Round 2b re-spaced to the corrected rule and scaled the flower to 0.91.

## Idea

A solid rose bloom disc (#CF5D78) with five clear scallops sits behind a plain green Flora o. It is a different geometry from the other two: one fused disc shape, not separate petals or round lobes. At 29 px the flower reads as one shape, a rose blossom with the o as its heart. In round 1 the o was recoloured amber. Both reviews read that as a donut or a badge, so the colour change is withdrawn.

## Construction

- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font's own o with its open counter. The Word o is a plain letter.
- **Flower.** Five circles of radius 215 u on a 270 u circle (tips at 485 u, 1.84x the o radius), one up, turned -8 degrees, then scaled to 0.91 (round 2b): tips 441 u. Neighbouring circles overlap outside the ring, so the bloom is one disc with notches about 7.5 px deep at 60 px (3.6 px at 29 px).
- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (52 u twin, 62 u solo, 60 u mono-solid). A petal that would reach a neighbour (the l or the r dilated by 40 u, solo 40 u, then closed by 100 u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most 0.5% of it would sit behind the letter (4x that in the solo lockup), then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: 1.000, 1.000, 1.000, 1.000, 0.976). An opening of 12 u rounds every corner.
- **Spacing rule (round 2b).** The reference is Nunito's native r-d gap: 208.8 u on the x-height band (10..470 u), 214.5 u on the full o height (-11..503 u, including overshoot), with rows every 10 u (v2 sampled every 20 u and quoted about 203). Every pair except F-l must sit within +-15% of it on the x band and +-20% on the o band; F-l may reach +30% on either band with an arm gap of at least 45 u. Each pair takes the tightest legal kern (working margin 0.86 x / 0.81 o), and no pair comes closer than 45 u anywhere (the r's arm against the d and the a). The Flora o pairs open to the legal maximum, because at the tightest kern no petal arrangement keeps 80% visible (see notes below). Kerns W-o..r-a: -68.0, +56.5, -26.0, +61.5, -44.0, +80.5, +108.5, -25.0 u. Solo adds 10 u to every pair except F-l, l-o and o-r (already at their limits).
- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap 62 u, neighbour clearance 40 u, +10 u tracking, as an optical size.
- **Icon.** Deep green ground #1F3D24. Rose bloom #E8758F. The centre is the o's silhouette at 0.75x, filled amber #F0B848, with a round pistil #C27A18 (diameter 0.40x the scaled ring width). Dark: #D95B7A, #E9A93A, #A8620C on #132313. Tinted: light-grey bloom, mid-grey centre, dark-grey pistil. Flower scaled by 0.9591 so its larger side is 80% of the 1024 canvas, centred on its bounding box; flat background rect.
- **Icon colour rule.** The wordmark is rose and green only. Amber appears only as the icon's flower centre, because a green centre would vanish on the green ground. This is a palette deviation from R3, stated here.
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
| twin | 100% | 100% | 100% | 100% | 86% |
| solo | 100% | 100% | 100% | 100% | 98% |
| mono-solid | 100% | 100% | 100% | 100% | 84% |

## Small-size geometry (A2, A3)

- Units per pixel at 29 px tall: 31.8. Ring gap 52 u = **1.64 px** (mono-solid 60 u = 1.89 px; A2 needs >= 1.0 px, i.e. >= 32 u).
- Widest visible width of each petal at 29 px tall: 12.3, 12.3, 12.3, 12.3, 12.3 px (A3 needs >= 4).
- Petals are fused into one bloom; notch depth between lobes (tip radius minus notch radius) at 60 px tall: 28.7, 28.7, 7.2, 28.7, 28.0 px; at 29 px: 13.9, 13.9, 3.5, 13.9, 13.5 px.
- Longest straight run on the bloom outline: 2.0 px at 320 px tall.
- The o counter at 29 px tall: 5.7 x 7.8 px.

**Pixel checks on the rendered PNGs** (`python render.py` prints them):

See `compare/pixel-checks.json`: exact sRGB fills, sheet margins and the ring gap pixel on mono-solid-h29.

## Sizing contract (A10)

| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |
|---|---|---|---|---|
| twin (wordmark*.svg) | 20 46 5410 921 | 5.87 : 1 | 29.3 pt | 44.6 pt |
| solo | 20 46 5460 921 | 5.93 : 1 | 29.0 pt | 44.2 pt |

v2 was 5.83 : 1, about 29.5 pt tall at 172 pt.

## Self-check, A1 to A13

| # | Result | Evidence |
|---|---|---|
| A1 | **pass** | petals 3.58 on cream, 4.14 on dark (>= 3.0) |
| A2 | **pass** | petal/ring 1.28 light, 1.85 dark; ring gap 52 u = 1.64 px at 29 px tall (>= 1.0), mono-solid 1.89 px |
| A3 | **pass** | petal width at 29 px 12.3 px min (>= 4); notches 6.4 to 7.5 px at 60 px on all five lobes, so five can be counted in light, dark, mono and mono-solid; at 29 px one rose flower shape |
| A4 | **pass** | Word/Flora 3.15 light (>= 3.0), 1.56 dark (>= 1.3); Word 14.48, Flora 4.59 on cream; 11.94, 7.66 on dark (>= 4.5) |
| A5 | **pass** | worst petals on cream 3.21 (>= 3.0), worst Word/Flora 3.04 (>= 2.0) across deutan, protan, tritan |
| A6 | **pass** | vs native r-d: worst pair 13.9% x band (<= 15), 15.2% o band (<= 20), solo 12.5 / 15.1; F-l +25.1 / +28.8% (<= 30), arm gap 45 u (>= 45); "Word" -6.9% vs v2; least-visible petal 84% (>= 80); by eye: "Word" 6.9% narrower than v2 and o-r-d no tighter-looking than needed; P3 eye check passes |
| A7 | **pass** | reads "WordFlora" at 29 px in all variants; the o is plain Flora green inside a cream gap, so "Flora" is one word in one colour. Mono-solid: the scallops are deep enough to read as a flower rather than a seal, but the bloom is still one solid shape |
| A8 | **pass** | 1024, flat green rect, no text or transparency; a pink blossom with a small amber centre and a pistil; reads as a flower at 29 px; tinted centre is mid-grey, not a white donut |
| A9 | **pass** | light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px |
| A11 | **pass** | no bounce, gloss, sparkle or bevel; no face |
| A12 | **pass** | by description only, reviewers to confirm. The silhouette is in the ume/sakura crest and cherry-blossom emoji family, which is generic and not an app mark. It is not confusable with Duolingo, Forest, Headspace, Calm, Finch, Wordscapes, Lily's Garden, Gardenscapes, PictureThis, Seek, Flora, Blossom or Planta. Nothing copied |
| A10 | **pass** | 5.87 : 1; 29.3 pt at 172 pt wide (26-34), 44.6 pt at 262 pt |
| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |

## Honest weaknesses

- With the o back in green, the rose disc against the green o is low in contrast (1.28:1, 1.01 under protanopia). The 1.49 px gap carries the separation.
- Mono-solid stays one solid black disc around the o. The scallops help, but it is still the most badge-like of the three in Increase Contrast.
- The icon centre is amber, a colour the wordmark no longer uses (see the colour rule).
- The cherry-blossom silhouette is generic: pleasant, but the least ownable of the three.
- **Round 2b spacing.** The rule now measures against Nunito's native r-d. Every Word pair and d-F takes its tightest legal kern: about -14% on the x band, with no pair closer than 45 u, which keeps the r's arm off the d and the a. "Word" is 2655 u of ink against v2's 2853 (-6.9%). At the tightest Flora gaps (l-o, o-r at -14%), no petal arrangement keeps 80% of a petal visible. Even at the widest legal gaps (+12.5% / +11.0% x, +15.1% / +14.7% o), a full-size flower scaled no lower than 0.94 per petal reaches only 72%. So, against the brief's "do not reopen", two levers were used instead. (1) The Flora o pairs sit at the legal maximum, still tighter than round 2 (235 vs 272 u). (2) The whole flower is scaled uniformly (hero and unified 0.92, centre 0.91), the same in the wordmark and the icon. The tightest-gap alternative needed a 0.80 flower, which turns the petals back into v2-style slivers round a heavy ring (rejected by eye). By eye on `compare/word-alone-320.png` (v2 above v3, same letter size), v3 "Word" is visibly tighter than v2 and o-r-d no longer reads looser: **the P3 eye check passes**. W-o and r-d sit close but clear, and the r's arm keeps 45 u from the d.

## Files

- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at 0.60 opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, 60 u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.
- Icons (1024, flat background, no text, no transparency): `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`.
- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).
- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.


# Logo v3 re-score, round 2 / 2b (final renders)

Scored from the PNGs on disk (viewed at 1x and 4x nearest-neighbour; sheets in `review/b/r2-*-wordmarks.png`, `review/b/r2-icons.png`; CVD sheets in `review/b/r2-<dir>/`). Hex numbers re-run with `cvd_sim.py --hex`. `pixel-checks.json` is `ok: true` for all three. SVG hygiene grep: 0 hits for mask/stroke/filter/gradient/defs/use/text/image/@import/clip-path in every SVG; width/height equal the viewBox size everywhere (wordmarks 5410 x 939 / 932 / 921, icons 1024).

## 1. Score table (0 / 1 / 2)

| Crit | hero | unified | centre |
|---|---|---|---|
| A1 petal vs bg | 2 - 4.05 light, 4.43 dark | 2 - amber #C86800 3.61 (deut 3.27), 6.20 dark | 2 - 3.58 (deut 3.22), 4.14 dark |
| A2 petal/ring | 2 - gap now 1.61 px (was 1.15); ring 1.13:1 so gap alone separates | 2 - gap 1.62 px; ring 1.27:1 | 2 - gap 1.64 px; ring 1.28:1, 1.01 prot |
| A3 flower reads | 2 - five petals clear at 60; at 29 five small pink dots, still a flower, less dominant | 2 - five lobes countable at 60 and 29 | 2 - five lobes, notches 6.4-7.5 px, countable at 60 |
| A4 Word/Flora | 2 - 3.15 light, 1.39 dark | 2 - 3.15 light, 1.56 dark | 2 - 3.15 light, 1.56 dark |
| A5 CVD | 2 - petals >= 3.62 deut/prot/trit light | 2 - petals 3.27 deut light | 2 - petals 3.22 deut light |
| A6 rhythm | 1 - o-r still reads wider than r-d in "Word" | 1 - same | 1 - same ("Wo rd") |
| A7 o reads as o | 2 - plain green o in clear gap | 2 - green o in cream gap on bloom | 2 - green o, one-colour "Flora" |
| A8 icon | 2 - flower on deep green, gold disc, round pistil, no eye | 2 - cream petals, amber face, face legible at 60 | 2 - pink blossom, amber centre, one shape |
| A9 mono-solid etc | 2 - ring clear, petals read as dots at 29 | 1 - slits help, 29 px still a spoked ring | 1 - still one solid black disc, badge-like |
| A10 sizing at 172 pt | 2 - 29.9 pt (5.76:1) | 2 - 29.6 pt (5.80:1) | 2 - 29.3 pt (5.87:1) |
| A11 tone | 2 - no face, flat | 2 - two dots and arc, icon only | 2 - flat, no face |
| A12 lookalike | 2 - no confusable mark | 1 - smiling daisy family, shipping-icon logic by design | 1 - generic cherry-blossom/ume emoji shape |
| A13 sheets | 2 - nothing clipped now, word-alone sheet added | 2 - nothing clipped | 2 - nothing clipped |
| **Total /26** | **25** | **23** | **23** |

## 2. Explicit verdicts

**Spacing by eye vs v2.** "Word" is clearly tighter than v2 at 320 (word-alone-320.png: v2's wide W-o and o-r gaps were opened by the flower; v3 is 6.9% narrower), and at 29 and 60 px it reads as ordinary text spacing. Not fully fixed: at 320 the o-r gap is still visibly wider than r-d, so "Wo rd" is faintly perceptible in all three (most visible in centre's sheet), and F-l is still the tightest pair. The designer's "P3 eye check passes" is generous: it is better than v2 and no longer a blocker, but not even. A6 stays at 1. Fix if wanted: tighten o-r in "Word" by about 15 u more (it has room, the r's arm is held at 45 u from d; the o-r gap is not the one limited by the arm), then re-measure.

**Flower after the ~8% shrink.** Still reads at 29: hero shows five small rose petals round the o (smaller, less dominant than round 1, but separate and countable on the 4x upscale); unified and centre read as one orange/pink bloom. At 60 all five petals/lobes count in light, dark and mono for hero and unified; centre's five lobes count but the sides are shallow. Passes.

**Hero icon, green ground vs cream alt.** Ship the green ground. The cream alt has thin pink petals on near-white that vanish on a light home screen at 29 px, and its green disc with a small amber dot is again the "eye / avocado" read the first round flagged. On the green ground the gold disc reads as a flower centre and petal contrast is 3.92:1 (3.12 worst CVD), pistil/disc 2.53:1.

**Hero icon-smile vs plain icon: which ships.** Ship the plain icon (round pistil). Reasons: it keeps one flower geometry shared with the wordmark (wordmark o has no face by rule), it is the furthest break from the shipping smiling daisy, and the plain 60 px read is "flower with a gold centre" with no eye problem. Cost: at 29 px a gold disc with a tiny orange dot can read as a target or fried egg, and it is less warm than a face. Lookalike check of icon-smile (by description): at 60 px it reads "smiling pink flower with a gold face on green" and at 29 px "pink flower, smiley centre". It is in the generic smiley-flower family (sticker daisies, flower emoji, Fisher-Price-style flowers); the Flowey-style yellow-petal white-face match is avoided (pink petals, gold face), and no app mark among Duolingo, Forest, Headspace, Calm, Finch, Wordscapes, Lily's Garden, Gardenscapes, PictureThis, Seek, Flora, Blossom, Planta is confusable. It is acceptable as an owner option if warmth at 29 px matters more than distinctness; it is closer to the old icon than the plain one. Its eyes at 29 px are about 2 px (legible only as dots), at 60 px the smile is readable.

**Unified's swapped icon colours.** Cream petals, amber centre, ink face tilted -8: strong. Contrast: cream on green 5.84:1, amber on green 3.71:1 (3.25 prot), face on amber 7.93:1, cream vs amber only 1.57:1 so the dark ring gap does the separating. It reads as a happy daisy at 29 and 60 and is the best icon of the three at small size. Downside: it is the shipping icon's own logic (cream daisy, amber face), so the change from the old icon is small, and the wordmark (amber petals, green letters) and icon (cream petals, amber centre) no longer share a palette.

**Centre's recoloured o.** Fixed. The o is Flora green again, so "Flora" is one colour and the rose disc alone marks the flower; reads as WordFlora with a rosette behind the second o. Weak point: ring vs disc 1.28:1 (1.01 under protanopia), so the 1.64 px gap carries everything. The icon now introduces an amber centre the wordmark does not use (a stated palette deviation); the pink flower with a gold ring centre is clean at 60 px.

**Mono-solid (Increase Contrast) at 29 px.** Hero: the o ring stays crisp in a 1.85 px white gap and the petals break into five dark dots round it (pixel check: brightest gap pixel 255); reads "Fl(o)ra" with decoration. Unified: the five radial slits split the bloom, but at 29 px the shape is a spoked ring, gear-like; legible as an o with a toothed collar, not a clean flower. Centre: still one solid black scalloped disc round the o, the most badge/seal-like; the o is still readable through its white gap.

## 3. Remaining blocking issues and ship readiness

- hero: no blocking issue. Non-blocking: rhythm in "Word" (o-r wider than r-d), greyscale petals equal the Flora grey (gap-only separation), tinted icon reads as a white O with a grey dot. Ready to ship with the plain green-ground icon, after the optional o-r tightening.
- unified: no hard blocker. Issues: icon is too close to the shipping icon for a "new brand" and the icon/wordmark palettes differ; mono-solid at 29 is a gear-like collar; "Wo rd" rhythm. Ready to ship if continuity with the old icon is wanted, not as a fresh identity.
- centre: no hard blocker. Issues: mono-solid solid black disc reads as a seal at 29; generic blossom emoji silhouette, least ownable; amber centre only in the icon; "Wo rd" rhythm. Ready to ship but the weakest case.

## 4. Final ranking

1. hero (25/26). Cleanest wordmark: separate petals that survive the shrink, a plain letter o, a mono-solid that still reads, and a fixed icon with no eye; best A9 and A12.
2. unified (23/26). Best small-size icon and a clear flower in the wordmark, but it trades distinctiveness for the old icon's smile and has a gear-like mono-solid.
3. centre (23/26, tie on score). Passes everything numerically after the recolour, but is the most generic blossom, with the badge-like mono-solid; ranked third because its identity is least ownable.

Overall: hero is ready to ship (plain green-ground icon, round pistil); unified and centre are shippable but weaker. Nothing else in the repo was edited, no commits.

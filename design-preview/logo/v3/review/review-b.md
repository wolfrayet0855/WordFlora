# Logo v3 review B (hero / unified / centre)

Method: every variant in the brief viewed as PNG, plus 4x nearest-neighbour upscales and composite sheets (light, dark, mono, mono-solid, solo, icons); CVD sims by `cvd_sim.py`; hex contrast re-measured with `--hex`. Generated PNGs are in `review/b/` (`up/` = upscales and contact sheets, `sims-<dir>/` and `sims-<dir>-all.png` = greyscale/deut/prot/trit). Scores come from the pixels, not the notes. Where the notes' numbers were re-run they matched exactly (see section 3).

## 1. Score table (0 fail, 1 marginal, 2 pass)

| Crit | hero | unified | centre |
|---|---|---|---|
| A1 petal vs bg >= 3:1 | 2 - 4.05 light, 4.43 dark | 2 - 3.44 light (reads brown), 6.20 dark | 2 - 3.58 light, 4.14 dark |
| A2 petal/ring separation | 1 - ring 1.13:1, gap only 1.15 px; grey petal = grey Flora | 1 - ring 1.33:1, gap 1.17 px, amber vs green | 2 - ring 1.34 light / 2.07 dark, gap 1.21 px, solid disc helps |
| A3 flower reads, petals countable | 2 - five separate petals clear at 60 and 29 | 2 - five lobes countable at 60, flower at 29 | 1 - side lobes only shoulders; reads as one rosette |
| A4 Word/Flora lightness gap | 2 - 3.15 light, 1.39 dark; split visible in grey but weak | 2 - 3.15 light, 1.56 dark | 2 - 3.15 light, 1.56 dark; but o is a third colour |
| A5 CVD safe | 2 - petals >= 3.55 all sims | 2 - petals 3.18 deut (thin margin) | 1 - ring vs Flora 1.05:1 hue-only; ring 4.43 deut (<4.5) |
| A6 rhythm | 1 - Word looks loose, F-l tight, l-foot notch | 1 - same spacing, same notch | 1 - same spacing; right lobe crowds r |
| A7 legibility, o reads as o | 2 - plain green o, ring gap reads | 2 - green o in cream gap, reads | 1 - brown o in rose disc; mono-solid cog |
| A8 icon | 1 - no face, green ring + amber oval reads as eye/avocado, pale on home screen | 2 - one shape, smile legible at 60, flower at 29 | 1 - pink flower with yellow "egg" centre, no face; tinted reads donut |
| A9 light/dark/mono/mono-solid | 2 - all four read at 29 and 60 | 1 - mono-solid 29 shows a cog around o | 1 - mono-solid disc is a black cog/badge |
| A10 sizing 26-34 pt at 172 | 2 - 31.4 pt (5.47:1) | 2 - 30.9 pt (5.57:1) | 2 - 29.8 pt (5.78:1) |
| A11 tone | 2 - flat, no face, no gloss | 2 - face is two dots and an arc, icon only | 2 - flat, no face |
| A12 lookalike | 2 - no confusable app mark | 1 - generic smiley daisy, close to the shipping icon and emoji | 1 - pink flower, yellow centre generic; yolk read |
| A13 before/after sheets | 2 - all present, nothing clipped | 1 - 320 px row clips the final "a" at sheet edge | 1 - 320 px row clips the final "ra" at sheet edge |
| **Total /26** | **23** | **21** | **18** |

## 2. Naive-read transcripts (first glance, light mode unless stated)

Hero
- 29 px: "WordFlora, the o in Flora has a little pink flower around it." Pink is five small separate dots; the o is still an o. Kind of app: casual word or gardening game. Dark and solo read the same. Mono 29: grey rosette, o still an o. Mono-solid 29: o with a ringed halo of black petals, still "WordFlora".
- 60 px: "WordFlora, rose five-petal flower on the second o." Petals clearly countable. The right/left petals are visibly cut by the l and r (notch at the l's foot).
- 7-year-old: reads "Word Flora", sees a pink flower. Yes, grade-2 reader gets it; the word is plain Nunito.
- Icon 29 px: "a small pink flower with a green dot and an orange middle." Expect: garden, nature, plant care app (not a word game). Icon 60: "flower with a green ring with an orange egg in it". It can read as a flower with an eye. Dark 60: pink flower, gold centre, good. Tinted 60: white O with grey petals, reads as O/flower, acceptable.

Unified
- 29 px: "WordFlora, orange-brown flower around the o." Scalloped bloom is one shape, the o inside reads as o. Amber looks brown/rust in light mode and a bit autumnal. Kind of app: gardening or kids' craft/word game.
- 60 px: "WordFlora with an orange flower behind the o." Five lobes countable. Dark: gold/green split gone (Flora is now pale green), flower orange: reads well.
- 7-year-old: gets "WordFlora", sees a flower. Fine.
- Icon 29 px: "smiley flower, yellow petals on green." Icon 60: "smiling daisy". Expect: a kids' game or family/emoji-style app; the face tells "friendly, casual". Strongest icon at small size of the three. Tinted 60: grey smiley flower, still reads.

Centre
- 29 px: "WordFlora, the o is a brown button inside a pink flower." The pink bloom reads as one shape; the o reads as o in a brown ring (it looks like a donut or a rosette badge on a hair clip). Kind of app: craft/lifestyle or garden.
- 60 px: "Flora with a pink rosette and a brown o." Side lobes read as shoulders, not petals. Dark: gold o on pink, nicest of its set. Mono-solid 29: black cog/seal around o; "Fl(badge)ra".
- 7-year-old: finds the o; "WordFlora" still gets read, but the o is a coloured badge and the eye goes there first.
- Icon 29 px: "pink flower with a yellow-orange centre." Expect: garden or craft app. Icon 60: "pink flower with a fried-egg centre". Tinted 60: white donut on grey; it reads as an O button.

## 3. Simulation findings (script-measured, `--hex`, Machado 1.0)

Re-measured; all numbers equal the designer's notes.

| Pair | normal | deut | prot | trit |
|---|---|---|---|---|
| hero petal #C9506C on cream | 4.05 | 3.62 | 5.05 | 4.04 |
| unified petal #C27200 on cream | 3.44 | 3.18 | 4.01 | 3.48 |
| centre petal #CF5D78 on cream | 3.58 | 3.22 | 4.35 | 3.58 |
| Flora #2E803F on cream | 4.59 | 4.82 | 4.32 | 4.66 |
| Word #182818 vs Flora #2E803F | 3.15 | 3.04 | 3.31 | 3.12 |
| hero petal #E26582 on dark | 4.43 | 4.99 | 3.55 | 4.46 |
| unified petal #E59A2E on dark | 6.20 | 6.74 | 5.35 | 6.13 |
| centre petal #DE5E7E on dark | 4.14 | 4.73 | 3.27 | 4.17 |
| Word vs Flora dark: hero (#DCEEDC vs #F0C060) | 1.39 | 1.32 | 1.52 | 1.43 |
| Word vs Flora dark: unified/centre (#8FCB8F) | 1.56 | 1.59 | 1.51 | 1.57 |
| centre ring #A65A00 on cream | 4.81 | 4.43 | 5.62 | 4.86 |
| centre ring #A65A00 vs Flora green | 1.05 | 1.09 | 1.30 | 1.04 |
| petal vs ring: hero / unified / centre light | 1.13 / 1.33 / 1.34 | | | |

What the sheets show (viewed):
- Greyscale: the Word/Flora split is visible in all three but is only 3.15:1, so it is a modest grey step, not a strong one. In hero the grey of the petals is nearly the grey of Flora, so the flower separates from the letters only by the ~1 px gap; it reads as grey blobs in a mid-grey word. Unified and centre are the same, centre's brown ring greys almost exactly to the Flora green (1.05:1), so the "o is a different thing" idea is invisible without hue.
- Deutan/protan: hero petals turn olive-grey but stay darker than the ground; dark prot petals (3.55 hero, 3.27 centre) are the weakest cell. Tritan: pink becomes salmon/red, fine. No CVD result breaks legibility of the word.
- Dark mode: hero's gold Flora next to pale Word is only 1.39:1 (passes 1.3 but is the closest to failing); unified and centre moved Flora to pale green, 1.56:1, hue differs but lightness gap is small. In greyscale dark the Word/Flora split is faint in all.
- A2 on the pixels: the petal-to-ring gap is 1.15 px (hero), 1.17 (unified), 1.21 (centre) at 29 px, so it is a single anti-aliased line. It is visible in the upscales, but it is carrying the whole separation in light mode.
- SVG hygiene (grep): zero matches for mask, stroke, filter, gradient, defs, use, text, image, @import, clip-path in all 30 SVGs. width/height equal the viewBox w/h in hero (5528x1011), unified (5528x993), centre (5528x957) and all icons are 1024x1024 viewBox 0 0 1024 1024. Pass for all.
- Sizing contract: 172 / aspect = 31.4 pt (hero), 30.9 pt (unified), 29.8 pt (centre). All inside 26-34.
- Sheet defect: in unified and centre `compare/before-after-*.png` the 320 px v3 wordmark is clipped on the right edge (final "a" or "ra" cut off). It is a sheet width problem, the SVGs are fine.
- Spacing observation (not caught by their gap metric): at 320 px "Word" looks letter-spaced ("W o rd") compared with v2, while F-l is almost touching (F arm 32 u from l). The mean-gap-in-x-height-band metric passes (<= 12%) but the eye sees uneven rhythm: the gap W-o and o-r reads larger than r-d, and the F-l join is tight.

## 4. Lookalikes (from knowledge, by description)

- Duolingo: green owl mascot on a rounded tile, no flower. No overlap with any direction.
- Forest: a tree in a circle. No overlap.
- Headspace: an orange dot/circle with a smile-like curve. Unified's smile-in-a-disc is the only distant echo (a face in a round form); different palette and a flower around it. Low risk.
- Calm: blue gradient wordmark. No overlap.
- Finch: a small bird character. No overlap (unified's face is on a flower, not a creature).
- Wordscapes: tile/leaf nature scene with letter tiles. No overlap.
- Lily's Garden, Gardenscapes: illustrated characters/gardens. No overlap in any direction.
- PictureThis, Seek: leaf or camera-lens marks. No overlap.
- Blossom, Planta, Flora: plant/focus apps using leaves, pots, or a tree/sprout. Hero is the furthest from these. Centre's pink five-lobed blossom with warm centre is close to generic "blossom" clip art that several plant apps use.
- Flower-smiley/scalloped-bloom marks: unified is a five-round-petal smiling flower, which sits in the same family as the generic daisy emoji, kids' sticker daisies, Fisher-Price-style flower faces, and the 1960s "flower power" smiley. Confusable at 29 px with the generic emoji and also with the shipping WordFlora icon (smiling daisy), so it does not give a clean break from the old icon. Centre's five-lobed disc with a ring in the middle is the plum-blossom (ume) crest shape, and the yellow centre in a pink bloom is the default "cherry blossom / sakura" emoji and Japanese-restaurant cliche. Hero's five separate teardrop petals around a green ring is the least stock of the three because the green o is the centre.

## 5. Fixes per direction

### hero
1. Fix the icon read. The green ring with amber oval reads as an eye or avocado. Make the counter fill the same green as the ring (solid green disc, drop the amber oval) or add a second, smaller amber dot only if it is circular, not oval. Verify: view icon-60 and icon-29 at 1x; nobody should say "eye".
2. Move the icon off pale cream. Set the light icon ground to the dark-icon deep green `#1A2E1A`-family (or the shipping green) with the rose petals and a gold ring. Verify: the icon beside the shipping icon on a mid-grey home screen mock still pops; petal-to-ground contrast stays >= 3.0.
3. Make the l/r tuck cleaner. At 320 px the lower-left petal is notched by the l's foot and the left petal is chopped. Add 20-30 u more clearance from the l (F-l can give up some of its +12%) or rotate the flower from -8 to about -2 degrees, so no petal loses its round end. Verify: render h320 and check all five petals keep a complete rounded tip; A6 must stay <= 15%.
Do not touch: the plain Word o and all unaltered Nunito letters; separate teardrop petals and tip length 505 u; the 40 u ring gap; the colours `#C9506C` / `#E26582` and the green ring; the mono-solid lockup; the sizing (5.47:1).

### unified
1. Fix the light amber. `#C27200` reads brown, not flower-warm. Try a more saturated, slightly redder amber of the same lightness (about `#CC6A10` to `#C97A08`) and test each with `--hex` against `#FAF7F0`; the hex must stay >= 3.0 (it fails if you simply lighten it). Verify: view wordmark-h29 and h60 and confirm "orange flower", not "rust/brown"; deut contrast stays >= 3.0.
2. Break from the old icon and the generic smiley. Offset the smile (smaller, 8% less wide), add a single leaf notch or tilt the face -8 degrees to match the bloom, or move the face to the lower-right of the centre. Verify: place beside the shipping icon at 60 px; they should be distinguishable in under a second.
3. Fix mono-solid: at 29 px the black scalloped disc plus o reads as a cog. Increase the ring gap in mono-solid only to 60 u. Verify: the o has a clearly visible white ring at 29 px.
Do not touch: the five-round-petal geometry and tilt; the smile rule (face in icon only, two dots and an arc); the icon's green ground and cream face disc; the dark Flora pale green; the fused scalloped bloom countable at 60 px.

### centre
1. Stop the o being a third colour. Make the Flora o ring the same green as Flora (`#2E803F` light, `#8FCB8F` dark) and let the rose disc alone mark the flower. Verify: greyscale sim shows the o in the same step as Fl/ra; the word "Flora" reads as one colour with a pink rosette behind it.
2. Deepen the lobes. Raise the circle offset from 230 to about 270 u or reduce radius to 220 u so side lobes stand clear of the l and r. Verify: at 60 px all five notches are >= 4 px deep (currently 2.9 on the sides).
3. Change the icon centre from a yellow "egg" to a face or a single solid amber circle with no inner oval, and fix the tinted icon so the centre is not a white donut (make the centre mid-grey, not white). Verify: icon-tinted-60 no longer reads as an O button.
Do not touch: the solid disc silhouette idea and its 1.21 px gap (the best A2 of the three); the dark-mode colour set (gold centre on rose is the best dark lockup); the shared kerning table.

## 6. Ranking and verdict

1. hero (23/26). It is the only direction where the o stays a plain letter and the flower is five countable petals at both 29 and 60 px, so it meets the brief's core goal (flower visible, word legible) with the fewest side effects; its weak points are the icon and the l/r tuck, both fixable.
2. unified (21/26). It has the best small-size icon (smiley bloom reads at 29 px) and a coherent wordmark/icon system, but the light amber is brown and the whole idea sits too close to the shipping smiley daisy and generic emoji.
3. centre (18/26). The single-shape rosette is neat at 29 px and best in dark, but the recoloured o, shallow lobes, cog-like mono-solid and donut-like tinted icon all fail the "o stays an o" and "flower at 60 px" criteria.

Verdict: none is ready to ship as-is; hero is ready after one round of fixes (icon centre and ground, tuck cleanup). Consider hero's wordmark with unified's smiley icon only if the palette is reconciled; as drawn they do not share a palette, so do not mix them without that step.

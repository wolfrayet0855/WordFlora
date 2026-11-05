# WordFlora logo v3: review A

Date: 2026-11-04. Reviewer A. I scored from the pixels: native PNGs first, then 4x/3x nearest-neighbour upscales and scripted simulations. I checked the notes' numbers against the pixels and did not score from them.
Generated files: `design-preview/logo/v3/review/a/` (`srgb/` colour-converted copies, `x4/` upscales, `*-native.png`, `*-h29-x4.png`, `*-h60-x3.png`, `*-icons*.png` contact sheets, `sims/` greyscale and CVD sheets). About 2.2 MB in total.

## 0. Pipeline finding to fix first (applies to all three)

Every PNG under `v3/*/png/` and `v3/*/compare/` has an embedded Skia ICC profile (`Google/Skia/A6688C…`), and the stored pixel values are not sRGB. In `hero/png/wordmark-h320.png` the stored Flora green is `#477C48` and the rose is `#BA596C`. Converted through the embedded profile they come back as exactly `#2E803F` and `#C9506C`. Any consumer that ignores ICC profiles shows washed-out colours and measures contrast that is too low. That includes `review/cvd_sim.py`, many image tools, and this reviewer's viewer. I converted everything to sRGB (`a/srgb/`) before viewing it closely or running the simulations. **Fix:** in `render.py`, convert each screenshot to sRGB with `ImageCms.profileToProfile` and save it without an ICC profile, or tag it as plain sRGB. To verify, `Image.open(p).info.get('icc_profile')` is None, and the most common pixel colour of `wordmark-h320.png` after the background equals the SVG fill hex.

## 1. Scores (0 fail, 1 marginal, 2 pass)

| # | hero | unified | centre |
|---|---|---|---|
| A1 petal contrast | 2: 4.05 cream / 4.43 dark, verified | 2: 3.44 / 6.20, verified, thin margin | 2: 3.58 / 4.14, verified |
| A2 petal vs ring | 2: 1.13 contrast, gap holds; right side smears at 29 | 2: gap is a clean background pixel both sides at 29 | 2: gap clean; dark mode also 2.07 contrast |
| A3 small-size flower | 2: five separate petals countable at 60; flower at 29 | 2: five lobes countable at 60; flower at 29 | 1: side lobes barely countable at 60; pink disc at 29 |
| A4 Word/Flora split | 2: 3.15 light, 1.39 dark; visible in grey | 2: 3.15 / 1.56; visible in grey | 2: 3.15 / 1.56; the o itself is a third colour |
| A5 colour-blind | 2: worst petal 3.55 (prot dark), split 3.04 | 2: worst petal 3.18 (deut light), very close to the limit | 2: worst petal 3.22 (deut light), 3.27 (prot dark) |
| A6 rhythm | 2: F–l +13% (or +17% on the full o band); petals over 80% visible | 2: same spacing as hero; tuck notch at the l foot | 1: right lobe sliced flat by the r at 320 px |
| A7 legibility, o reads as o | 2: o clearly a letter in all variants | 1: mono-solid bloom reads as a cog or gear | 1: brown o in a pink disc reads as a donut or badge |
| A8 icon | 1: the centre still reads as the letter O or an eye | 2: a smiling flower at 29; face legible at 60 | 1: a big "O" on a pink blossom; the tinted icon is a donut |
| A9 four modes | 2: all four hold; mono-solid is the weakest | 1: the mono-solid fused bloom becomes a gear | 1: mono-solid becomes a black rosette seal |
| A10 sizing | 2: 31.5 pt at 172 wide | 2: 30.9 pt at 172 wide | 2: 29.8 pt at 172 wide |
| A11 tone | 2: calm, flat, no face | 2: two dots and one arc, icon only | 2: flat, but the light ring reads brown |
| A12 lookalike | 2: generic five-petal daisy, no app match | 1: icon strongly echoes Flowey (Undertale) | 2: ume/sakura-crest genre, no app match |
| A13 before/after | 2: all rows fit the sheet | 2: fits with about 6 px to spare at 320 | 1: the 320 px v3 row is clipped on the right |
| **Total (of 26)** | **25** | **23** | **20** |

Not scored but required by R3: hero's icon petals and ring are the same hex values as the wordmark (`#C9506C`, `#2E803F`). Unified uses `#C27200` (wordmark) against `#F5BC48` (icon). Centre uses `#CF5D78`/`#A65A00` (wordmark) against `#E8758F`/`#F0B848` (icon). Their palettes are related but not identical. The background explains the change, and `#E59A2E` on the unified icon green is only 2.74:1, but the colour rule has to be written down.

## 2. Naive-read transcripts (step B)

These are first glances at native pixels, before any upscale.

**hero wordmark, 29 px:** "WordFlora." The o reads as an o with a small pink flower behind it. What kind of app: a flower, gardening or florist app, maybe a word game with plants. **60 px:** "WordFlora." Five separate pink petals around a green o, clearly a flower. App: a casual word or garden game. **7-year-old:** reads "Word" at once and sounds out "Flor-a"; the flower does not block the o. Gets the name.

**unified wordmark, 29 px:** "WordFlora." The o sits in an orange scalloped shape, a flower at first look and slightly like a life-ring. App: a garden or puzzle game, autumn or sunflower feel. **60 px:** "WordFlora." Five rounded lobes, an orange flower; the o is a green ring inside a cream gap. The light-mode orange reads brownish, like caramel. **7-year-old:** gets "WordFlora" and sees "a flower on the o".

**centre wordmark, 29 px:** "WordFl-o-ra." My eye stops on a pink round blob with a brown ring in it: a donut, a target, a sticker badge. The flower reading comes second. App: unclear; a bakery or sweets game was my first guess. **60 px:** a pink plum blossom with an amber-brown o. The o reads as o, but in its own colour, so the word chunks as "Fl / o / ra". App: a garden or word game. **7-year-old:** reads it, but likely calls the o "a donut". The brown on pink is the strongest food cue of all three.

**hero icon, 29 px:** "a pink flower." **60 px:** a pink five-petal flower with a green centre and an orange oval in it. The oval reads as an eye or an olive, and the centre as a fat letter O. Expected app: plant identification or florist; not obviously a word game. **7-year-old:** "a flower."

**unified icon, 29 px:** "a happy yellow flower." **60 px:** a smiling flower with a cream face, very legible. Expected app: a kids' game, mood tracker or garden game. Gamers and older kids may think of Flowey from Undertale. **7-year-old:** "a smiley flower!" It is the warmest of the three by a distance.

**centre icon, 29 px:** "a pink flower," or "a pink donut with yellow inside." **60 px:** a pink five-lobed blossom with a huge yellow O ring and a darker oval counter. It reads as the letter O or a donut first and as a flower second. Tinted, it is clearly an "O" or a donut. Expected app: a sakura or Japanese-themed app, a bakery game, or a letter game. **7-year-old:** "a flower with an O," or "a donut."

## 3. Simulations (step C)

I ran `cvd_sim.py` on sRGB-converted copies of wordmark-h60, wordmark-h29, wordmark-dark-h60 and icon-60 for each direction, and viewed all twelve `-sims.png` sheets. On the raw ICC-tagged PNGs the script would have measured the wrong colours (section 0).

Measured with `--hex` (normal / deut / prot / trit). The notes' claims all agree with my numbers to within 0.03.

| Pair | normal | deut | prot | trit |
|---|---|---|---|---|
| hero petal `#C9506C` on cream | 4.05 | 3.62 | 5.05 | 4.04 |
| hero petal `#E26582` on dark | 4.43 | 4.99 | 3.55 | 4.46 |
| hero petal vs ring (light) | 1.13 | 1.33 | 1.17 | 1.16 |
| hero Word vs Flora (dark) `#DCEEDC`/`#F0C060` | 1.39 | 1.32 | 1.52 | 1.43 |
| Word vs Flora light `#182818`/`#2E803F` (all three) | 3.15 | 3.04 | 3.31 | 3.12 |
| Flora `#2E803F` on cream | 4.59 | 4.82 | 4.32 | 4.66 |
| unified petal `#C27200` on cream | 3.44 | 3.18 | 4.01 | 3.48 |
| unified petal `#E59A2E` on dark | 6.20 | 6.74 | 5.35 | 6.13 |
| unified petal vs ring (light / dark) | 1.33 / 1.24 | 1.51 / 1.11 | 1.08 / 1.46 | 1.34 / 1.25 |
| unified/centre Word vs Flora dark `#DCEEDC`/`#8FCB8F` | 1.56 | 1.59 | 1.51 | 1.57 |
| centre petal `#CF5D78` on cream | 3.58 | 3.22 | 4.35 | 3.58 |
| centre petal `#DE5E7E` on dark | 4.14 | 4.73 | 3.27 | 4.17 |
| centre ring `#A65A00` on cream | 4.81 | 4.43 | 5.62 | 4.86 |
| centre petal vs ring (light) | 1.34 | 1.37 | 1.29 | 1.36 |
| centre ring vs Flora green | 1.05 | 1.09 | 1.30 | 1.04 |
| hero icon amber counter vs green ring | 2.30 | 2.57 | 1.94 | 2.31 |
| centre icon petal `#E8758F` on `#24472A` | 3.67 | 4.13 | **2.96** | 3.69 |
| unified icon petal `#F5BC48` on `#356B25` | 3.71 | 4.04 | 3.25 | 3.61 |
| mono petal `#747E74` on white / on ink | 4.22 / 3.67 | same | same | same |

What the sheets show:
- **Greyscale, hero:** the petals and the Flora letters become the same mid grey (1.13). Only the cream gap separates the flower from the o. It still reads, because the petals are separate shapes, but there is no tonal hierarchy. Under deuteranopia and protanopia, the Flora olive and the grey-mauve petals are close too.
- **Greyscale, unified:** the bloom goes lighter grey than Flora, so the flower stays distinct. Under deuteranopia and protanopia it turns mustard-olive, close to the deut/prot Flora olive; the gap does the separating.
- **Greyscale, centre:** the ring and the disc are nearly one grey (1.34), so the o becomes a grey ring in a grey scalloped disc: a seal or rosette. The ring matches the other letters in grey (1.05), which helps the word read.
- **Dark mode, all:** fine. Hero's gold Flora against pale Word is the subtlest split in grey (1.39) but visible.
- **Icons:** hero greyscale shows the ring and petals merging in tone and kept apart by the gap. Unified survives every simulation best: the face is 12.5:1 on the disc. Centre's petals fall to 2.96:1 against the icon green under protanopia, just under 3.0.
- **Gap at 29 px, from pixels:** on a row through the o's centre, the left-side gap is a clean background pixel in all three (for example `#F1F2E9` in hero). On hero's right side, where the tucked petal sits, the gap smears into two blended pixels (`#A3C5A5`, `#E6B4BC` in light; `#9CA39C`, `#A4A9A3` in mono-solid). Nothing reaches the background, so in mono-solid the o and the right petal visually touch. Unified and centre keep a near-background pixel on both sides.

Rhythm, measured independently by connected components on the sRGB `wordmark-h320.png`. Letter pixels only, so petals count as gap; mean gap per row across the o band:

| | W–o | o–r | r–d | d–F | F–l | l–o | o–r | r–a |
|---|---|---|---|---|---|---|---|---|
| hero, full o band | +2% | −6% | 0 | −7% | **+17%** | +7% | +8% | +1% |
| hero, band trimmed 8% (no overshoot) | −2% | −12% | 0 | −4% | +13% | +4% | +3% | +5% |
| unified, full / trimmed F–l | | | | | +16% / +12% | | | |
| centre, full / trimmed F–l | | | | | +16% / +12% | | | |

F–l passes A6 only when the band excludes the o overshoot. It is the weak pair in all three, and the F's middle arm nearly touches the l at 29 px (about 0.9 px). I still score A6 a pass, because the designer's band definition (the x-height band) is the reasonable one.

Sizing (from the viewBox and `wordmark-w172.png`): hero 5.47:1, 31.5 pt at 172 pt wide (PNG 172x31), 47.9 pt at 262 pt wide. Unified 5.57:1, 30.9 pt (172x31), 47.1 pt. Centre 5.78:1, 29.8 pt (172x30), 45.4 pt. All are inside 26 to 34 pt.

SVG hygiene: all 30 SVGs contain only `<svg>` and `<path fill>`. There are no hits for mask, stroke, filter, gradient, defs, use, text, image, @import or clip-path. `fill-opacity` appears only in the mono and solo-mono files. Width and height equal the viewBox in every file. Icon PNGs are 1024x1024 RGB with no alpha.

## 4. Lookalikes (step D, by description only)

- **Duolingo** (green owl character), **Finch** (small bird), **Calm** (blue field with a script wordmark), **Lily's Garden** and **Gardenscapes** (illustrated character portraits): no shape or colour overlap with any direction.
- **Forest** (green tree or seedling in a round badge), **PictureThis**, **Planta**, **Blossom** and **Seek** (green leaf, sprout or nature-badge marks), **Flora** the focus app (a green seedling or tree): none uses a five-petal flower round a letter. The only overlap is the name "Flora" on the focus-timer app. That is a name-search question, not a mark match.
- **Wordscapes** (letter wheel over a landscape photo): no visual match. Centre's "letter in a coloured disc" faintly recalls letter-tile word games, but it is not confusable.
- **Headspace** (a plain orange dot): unified's orange bloom with a smile shares "warm orange and friendly" but has petals and a face. Not confusable.
- **Mary Quant daisy** (five rounded petals round a round centre, fashion and cosmetics): hero's separate round petals and unified's fused five-circle silhouette are in this family. Hero's tilt, teardrop petals and green ring, and unified's face, keep them apart. Low risk, different trade class.
- **Flowey, Undertale** (yellow petals round a white smiling face, a famous game character that kids know): **the closest match in this review, for the unified icon.** At 29 to 60 px, "yellow petals, cream face, two dots and a smile" is exactly the Flowey read. Flowey is a villain. This is the one confusable match I found, and it lands in the same category (games).
- **Murakami smiling flowers** (many rainbow petals, wide grin): not confusable with any direction.
- **Fisher-Price** (red scalloped banner behind white letters): centre's mono-solid scalloped black disc round a letter belongs to the same "scalloped seal or badge" genre. It is not a copy, but the genre reads as toy or retail badge rather than flower.
- **Generic emoji:** 🌸 (pink five-lobed with notched tips) and the Japanese ume or sakura crest are the template for centre's icon silhouette. That is generic, not a brand. 🌼 (yellow petals, yellow centre) plus a smiley sticker is the generic family unified belongs to.
- I know no specific "Flower" brand app mark that matches any direction.
- Nothing appears to be copied in any direction.

## 5. Fixes per direction

### hero (keep this as the base)

1. **The icon centre reads as the letter O or an eye.** In `icon.svg`, `icon-dark.svg` and `icon-tinted.svg` only, replace the tall o-counter path (5.2x7.1 px at 29 px; at 1024 px a tall amber oval) with a circular pistil. Make it a circle centred on the o's centre, with a diameter of 0.40x the ring's outer width (about 180 px at 1024), coloured as now (`#E9A43A` light, `#B8650A` dark, `#C4C4C4` tinted). Fill the rest of the counter with the ring colour. The wordmark o keeps its open counter. Verify: render icon-60 and icon-tinted-60, and show them to two people who have not seen the brand. Ask "is there a letter in this?" Both must say no. Then confirm the build's `measurements.json` still shows the flower at 80% of the canvas.
2. **The right-side ring gap smears at 29 px, and in mono-solid the o touches the right petal.** Raise the twin ring gap from 40 u to 52 u, which is about 1.5 px at 29 px tall, on the cut that makes the gap round the Flora o only. Leave the neighbour clearance alone. Re-render. Verify: on `wordmark-mono-solid-h29.png` (sRGB), the rows through the o's centre (y = 14 and 15) must show at least one pixel at or above `#E0E0E0` on both the left and the right of the ring. Today the right side only reaches `#A4A9A3`.
3. **A notch shows where the l's foot curls under the lower-left petal at 320 px.** In the neighbour cut on the l side only, raise the morphological closing radius from 60 u to 100 u, so the petal edge facing the l is one smooth curve with no inward step. Verify: in `wordmark-h320.png`, the edge of P5/P4 next to the l has no concave step, and the P5 visibility in `measurements.json` stays at or above 80% (today 84%).

**Do not touch:** the five separate teardrop petals and their −8° tilt. The `#C9506C`/`#E26582` rose. The Word ink `#182818` and Flora green `#2E803F`. Dark mode's gold Flora `#F0C060` (the critique's favourite and still the best mode). The icon using the exact wordmark petal geometry and hex values. The 31.5 pt height at 172 pt wide.

### unified

1. **The icon reads as Flowey (Undertale).** Swap the icon's colour roles to the shipping icon's logic. Petals become cream `#FBF4E4` (5.84:1 on `#356B25`). The centre disc becomes amber `#F5BC48`, with the face in `#1F321F` (check that it is at least 7:1 on the amber). Keep the green ring gap between disc and petals. Write the colour rule down in the notes: "the icon inverts the wordmark's roles; petals cream, centre amber". Verify: show icon-60 to three people and ask "does this remind you of anything?" No one should name Flowey. Run `cvd_sim.py --hex` on petal-on-background and face-on-disc, and confirm at least 3.0 and 7.0 respectively.
2. **In mono-solid the fused bloom becomes a gear or cog.** For `wordmark-mono-solid.svg` (and the solo mono-solid if it is added), subtract five radial slits, 30 u wide, along the bisectors between adjacent petal circles, from the ring gap outward. That turns the lobes into separate petals in solid ink only. Verify: on the 4x upscale of `wordmark-mono-solid-h29.png`, every pair of adjacent lobes is separated by at least one background-coloured pixel, and a naive viewer says "flower", not "gear".
3. **The light-mode bloom `#C27200` reads brown or caramel next to green.** Keep the hue family but shift towards orange at the same lightness. Try `#C96A00`, or the most saturated amber at or above 3.3:1 on cream, and target deuteranopia at or above 3.2 (today it is 3.18, the thinnest margin in the review). Verify with `cvd_sim.py --hex '<new>' '#FAF7F0'`, where all four values must be at least 3.2. Then look at `wordmark-h60.png` beside the shipping Play-button amber; the bloom should read as orange, not brown.

**Do not touch:** the five-circle geometry and its notch depth (7 to 9 px at 60 px), which is what makes it countable. The written face rule (no face in letters; two dots and an arc in the icon only). The cream gap round the o. The icon's warmth and 60 px face legibility, the best of the three.

### centre

1. **The o reads as a donut or badge.** Recolour the Flora o ring from `#A65A00` (light) and `#F0C060` (dark) back to the Flora colour: `#2E803F` light, `#8FCB8F` dark. The letter then stays one colour with "Flora" and the rose disc alone is the flower. Separation then relies on the ring gap: rose against green is 1.28:1, falling to 1.01 under protanopia. Verify: a naive read at 29 px by two people who have not seen the brand, asked "what is around the o?", answers "a flower" and not "donut" or "badge". The greyscale sim of `wordmark-h29` shows one tone for all of "Flora".
2. **The lobes are too shallow, and the r slices the right lobe flat.** Change the bloom construction from five r = 250 u circles on a 230 u circle to r = 215 u circles on a 270 u circle, keeping the tips at about 485 u. Then rotate the bloom −8°, as in hero, so the right lobe clears the r's shoulder. Verify: notch depth at least 5 px at 60 px on all five lobes (today 2.9 px on the side), as reported by `build.py`. No straight edge longer than 15 px on the bloom outline in `wordmark-h320.png`. Least-visible lobe still at or above 80%.
3. **The icon centre is a giant "O", and the tinted icon is a donut.** Scale the ring and counter group in `icon*.svg` to 0.75x of its current size about the flower centre, leaving the bloom unchanged. Fill the counter with the ring colour plus a round pistil of 0.40x the ring width, as in hero fix 1. Check the protanopia petal contrast (2.96 today): darken the icon background `#24472A` to `#1F3D24` or lighter-tint the petal until prot is at least 3.0. Verify: icon-tinted-60 shown to two people, asked "is there a letter in this?", answers no; `cvd_sim.py --hex` prot at least 3.0.
4. (Housekeeping.) **The `compare/before-after-light.png` and `-dark.png` 320 px row is clipped:** the v3 "a" runs off the right edge (last ink column 3899 of 3900). Widen the sheet canvas by at least 120 px, or wrap the 320 row. Verify: the last ink column is at least 20 px inside the image width.

**Do not touch:** the single solid bloom as one shape at 29 px (its one real advantage). The `#CF5D78` rose at 3.58:1 on cream. The 29.8 pt height at 172 pt, the closest to v2's header footprint.

## 6. Ranking and verdict

1. **hero (25/26).** It is the only direction where the o is unambiguously a letter and the flower unambiguously a flower at both 29 and 60 px, in every mode. The icon shares exact geometry and hex values with the wordmark. Its weaknesses are local and mechanical: an o-shaped icon centre, a sub-pixel gap smear and a tuck notch. Nothing in the idea needs rethinking.
2. **unified (23/26).** Its icon is the best of the three: warm, legible, and the natural successor to the shipping daisy. But in a game store it is one step from Flowey, and the fused bloom degrades to a gear in Increase Contrast. Its light-mode amber is the thinnest colour-blind margin in the review and reads brown.
3. **centre (20/26).** The single bloom disc reads as one shape at 29 px as intended, but the shape it reads as is a donut, target or badge, and the brown o splits "Fl-o-ra". The icon is dominated by a letter O, and even the compare sheet is clipped.

**Verdict:** none is ready to ship as-is. Hero is ready after one round of fixes (fixes 1 to 3 above plus the sRGB PNG fix). If the owner wants the smile, take unified's icon face onto hero's flower as a later experiment, not unified as a whole.

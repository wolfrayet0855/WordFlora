# WordFlora logo v3: review A, round 2 (final renders)

Date: 2026-11-04. Reviewer A. This review scores the renders now on disk (round 2 plus 2b) and covers only what changed. The method is the same as round 1: native PNGs first, then 4x/3x nearest-neighbour upscales, `cvd_sim.py` sheets, `--hex` checks, and naive reads. Generated files are in `review/a/r2/`: native, x4 and x3 contact sheets, `sims/`, and `hero-word-vs-flora-rhythm.png`.

Housekeeping checks, all passing:
- No PNG under `v3/*/png` or `v3/*/compare` carries an ICC profile any more.
- The stored pixels equal the SVG hex values.
- All 34 SVGs contain only `<svg>` and `<path fill>`, with width and height equal to the viewBox.
- Compare sheets keep a margin of at least 36 px on the right.
- The mono-solid gap at 29 px now has a pure-white pixel on both sides of the ring in all three directions. In round 1, hero's right side only reached `#A4A9A3`.

## 1. Scores on the final renders (0 fail, 1 marginal, 2 pass)

| # | hero | unified | centre |
|---|---|---|---|
| A1 | 2: 4.05 cream / 4.43 dark (unchanged) | 2: `#C86800` 3.61 cream / 6.20 dark | 2: 3.58 / 4.14 (unchanged) |
| A2 | 2: 52 u gap; a clean background pixel both sides at 29 | 2: same; clean both sides | 2: same; clean both sides |
| A3 | 2: five petals countable at 60; five dots at 29 | 2: five lobes countable at 60; flower at 29 | 2: now five lobes countable at 60; flower at 29 |
| A4 | 2: 3.15 / 1.39, split visible in grey | 2: 3.15 / 1.56 | 2: 3.15 / 1.56; "Flora" is now one colour |
| A5 | 2: worst petal 3.55 (prot dark) | 2: worst petal 3.27 (deut light), up from 3.18 | 2: worst 3.22 (deut light) |
| A6 | **1**: Flora pairs 26–31% looser than the word's own r–d | **1**: identical spacing to hero, same fault | **1**: identical spacing, same fault |
| A7 | 2: o is a letter in every variant | 2: slits cure the mono-solid gear | 2: green o is a letter, no donut |
| A8 | 2: flower with a gold centre, no O, no eye | 2: cream daisy with an amber smiling face | 2: pink blossom, small centre; the tinted icon is slightly target-like |
| A9 | 2: mono-solid reads as a flower | 2: mono-solid now five petals | **1**: mono-solid at 29 reads as a cog or bottle cap |
| A10 | 2: 29.9 pt at 172 pt wide (PNG 172x30) | 2: 29.6 pt (172x30) | 2: 29.3 pt (172x29) |
| A11 | 2: calm; face only in icon-smile | 2: face only in icon | 2: no face |
| A12 | 2: no confusable mark (including icon-smile, see 2e) | 2: Flowey resolved; now close to the shipping icon | 2: generic ume/sakura, no app match |
| A13 | 2: all sheets fit | 2: fits | 2: fits; round-1 clipping fixed |
| **Total (of 26)** | **25** | **25** | **24** |

## 2. Verdicts

### 2a. Spacing: by eye and by measurement

**`word-alone-320.png` (only "Word"):** v3 "Word" is visibly tighter and more even than v2. W–o and r–d are close but clear, and the r's arm stays off the d. On "Word" alone the designer's eye check passes, and I agree.

**But that sheet hides the problem.** It shows "Word" and not "Flora". On the full `wordmark-h320.png`, and on my crop `r2/hero-word-vs-flora-rhythm.png`, "Word" is tight and "F l o r a" is airy. Measured by connected components on the h320 PNGs, the mean gap across the x-height band, without overshoot, comes out as follows. The numbers are the same for all three directions within 2 px.

| | W–o | o–r | r–d | d–F | F–l | l–o | o–r | r–a |
|---|---|---|---|---|---|---|---|---|
| px at 320 tall | 59 | 59 | 61 | 61 | 89 | 79 | 77 | 76 |
| vs as-set r–d | −4% | −3% | 0 | −1% | **+45%** | **+30%** | **+26%** | **+24%** |

The designer's own table says the same: r–d is set at 183 u, while l–o is 235, o–r 232, F–l 261 and r–a 221. The "corrected rule" passes because it measures every pair against Nunito's native r–d (208.8 u), not against the r–d as set. Round 2b tightened "Word" by 14% and left the Flora o pairs at their legal maximum. The result is a two-speed word: "Word Fl o r a". Against the brief's A6 as originally written (±15% of r–d as set), four pairs fail. Against the corrected rule it passes on paper. By eye it is the same unevenness the round-1 critique named ("W ord Fl ora"), moved to the other half of the word. I score it 1, not 0, only because the word still reads instantly.

**At 29 and 60 px:** at 60 px the looseness of "Flora" is visible next to "Word", especially F–l and o–r. At 29 px it mostly hides in the pixel grid; you see a dense "Word" and a lighter "Flora". The colour split masks some of it in light and dark. In mono, where there is no colour split, it is easiest to see.

### 2b. The flower after the ~8% shrink

- **At 29 px:** all three still read as a flower. Hero shows five distinct rose dots round the o. The side petals between l/o and o/r are a little smaller than the top and bottom ones (scaled to 0.97/0.995), but that does not read as damage. Unified is a five-lobed orange flower. Centre is a pink scalloped ring.
- **At 60 px:** every petal is countable in light, dark and mono for all three.
- **Centre** improved most: in round 1 its side lobes were barely countable, and now all five are clear.
- **The cost:** the flower is a little less dominant at Home size. It is a fair trade and not a fail.
- **Measurement bug, not visual:** unified's and centre's notes report notch depths of 28 to 29 px at 60 px tall. That is the full tip radius, so the routine is finding the "notch" inside the ring gap. Fix the measurement or delete the line; the pixels are fine.

### 2c. Hero icon: green ground against the cream alternative

**Ship the green ground (`icon.svg`, `#1C3820`).**
- The gold disc and rose petals pop on deep green at 29 px.
- It keeps the shipping icon's green home-screen presence.
- Its colours are the dark-mode wordmark's exact values (`#E26582`, `#F0C060`), so the icon and the dark wordmark are one palette. Petals on the ground measure 3.92 normal and 3.12 under protanopia.

`icon-alt-cream` loses on both counts:
- At 60 px the green disc with an amber dot reads as a target or an eye again, which is the round-1 fault.
- A cream square is the quietest thing on a home screen.

### 2d. Hero icon-smile against the plain hero icon

**Ship `icon-smile`.**
- It brings back the one element the critique called the brand's personality: the shipping daisy's face.
- It uses exactly the allowed face vocabulary (two dots and one arc).
- It stays legible at 29 px: the 4x upscale shows both eyes and the arc as distinct dark marks, at 8.56:1 on the gold.
- It survives every CVD simulation (sheet `r2/sims/hero-icon-smile-60-sims.png`).
- The plain pistil version is correct but generic; at 60 px it reads like stock flower clip-art.
- Small non-blocking note: the face is turned −8° with the flower, so at 1024 the right eye sits higher and the smile looks faintly quizzical. Try the face levelled at 0° inside the tilted flower and pick by eye at 180 px.

**Lookalike check of icon-smile, by description:**
- **Flowey (Undertale)** is yellow petals round a white face. Hero-smile is rose petals round a gold face, with separate teardrop petals, so it is not a Flowey read.
- **Murakami's smiling flowers** have a dozen or more rainbow petals and a wide grin. Not confusable.
- **Duolingo, Finch, Headspace, Calm, Forest and the plant apps (PictureThis, Planta, Blossom, Seek, Flora):** no overlap.
- **Generic smiley-daisy sticker art and the shipping WordFlora icon** are the nearest family. The second is intentional continuity.
- Nothing appears to be copied.

### 2e. Unified's swapped icon colours

The swap works:
- Cream petals `#FBF4E4` measure 5.84:1 on the green.
- The amber face disc carries the ink face at 7.93:1.
- The Flowey read is gone; Flowey is yellow petals with a white face, and this is the inverse.

Cost:
- The icon now matches the shipping icon better than it matches its own wordmark, whose petals are orange.
- The brand link from Home back to the icon is weaker than hero's, where the icon petals are the wordmark's rose.

### 2f. Centre's recoloured o

Fixed:
- The o is Flora green again, "Flora" reads as one word in one colour, and the donut or badge read is gone at 29 and 60 px.
- The deeper lobes make it a recognisable five-petal blossom.

Side effect:
- Centre is now essentially unified's round-lobe geometry in rose, behind the same o.
- Its own idea, one solid disc, is gone, so it is no longer a distinct third direction.

### 2g. Mono-solid (Increase Contrast) at 29 px

- **hero:** best. Five separate black petals with white between them, a white ring gap, and the o clearly a letter. Reads "a flower".
- **unified:** fixed. The five slits each show a pure-white pixel at 29 px (checked in `pixel-checks.json` and by eye on the x4). It reads as five petals, not a gear.
- **centre:** still marginal. A black scalloped ring tight round the o reads first as a cog, gear or bottle cap. The scallops are about 1 to 2 px deep at 29 px.

## 3. Remaining blocking issues and readiness

**All three: the Flora-looser-than-Word rhythm (A6).** One fix covers all three. Stop tightening "Word" past what "Flora" can follow: set W–o, o–r, r–d and d–F back to about the native r–d (kern about 0 instead of the current −68/+56.5/−26/+61.5 trims, so each pair sits near 209 u). Leave the Flora pairs where they are.
- Result: l–o and o–r at about +12% and F–l at about +25% of the as-set r–d.
- "Word" ink width becomes about 2750 u, still narrower than v2's 2853.
- Verify: measure every pair against the r–d as set, not the native one. All pairs except F–l should be within ±15%, F–l at most +30%.
- Confirm by eye on a new `word-and-flora-320.png` that shows the full word, not just "Word".

**Per direction:**
- **hero:** no other blocker. Not ready as-is; ready after the spacing rebalance. Ship with the green-ground `icon-smile` as the app icon, and keep `icon.svg` (plain) as the fallback.
- **unified:** no other blocker after the spacing fix. Ready after that fix if the owner prefers it, but it is weaker than hero on the brand link because the icon petals are cream while the wordmark petals are orange.
- **centre:** after the spacing fix, the mono-solid cog read at 29 px still needs work: cut slits as in unified, or deepen the scallops to at least 3 px at 29. It is now a near-duplicate of unified. I would retire it rather than fix it.

## 4. Final ranking

1. **hero (25/26).**
   - Separate petals read as a flower at every size and in every mode, including Increase Contrast.
   - The green-ground icon (with the smile) uses the wordmark's own rose and gold.
   - It needs only the shared spacing rebalance.
2. **unified (25/26, ranked below hero on judgment).**
   - It fixes all its round-1 faults, and its icon is warm and safe now.
   - It loses to hero on the icon-to-wordmark link and on Increase Contrast, where the slits work but are only one pixel wide at 29 px.
3. **centre (24/26).**
   - The recoloured o and deeper lobes cured the donut, but the mono-solid version still reads as a cog.
   - The direction has converged on unified in rose, so it no longer earns a slot.

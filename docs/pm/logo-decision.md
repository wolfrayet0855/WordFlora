# WordFlora logo v3: decision

Date: 2026-11-04. Branch: 3-feat-content-and-polish. Author: project manager.
Inputs: `docs/pm/logo-critique.md` (brief and acceptance criteria A1-A13), the three v3 directions in `design-preview/logo/v3/` (hero, unified, centre; two build rounds plus a spacing correction), the two reviews per round in `design-preview/logo/v3/review/`, and my own viewing of every before/after sheet and the 29/60/172 px renders.
Preview: http://localhost:8765/logo/v3/index.html

## Decision

**Recommended: `hero`** (plain ink-green "Word", one five-petal rose flower on the Flora o, gold "Flora" in dark mode), shipped with the **`icon-smile`** app icon (the same flower on a deep green ground, two-dot-one-arc face on the gold centre disc).

**Runner-up: `unified`** (fused five-lobe amber bloom; icon with cream petals and an amber smiling centre).

**Not recommended: `centre`.**

Go-ahead: the hero wordmark and icon are ready for the owner to review and, if approved, for a later worker to ship with the steps below. Nothing in the app tree has been changed by this work.

## Why hero

1. It meets the critique's core demand with the fewest side effects: the o is unambiguously a letter (open Nunito counter, no face, no recolour) and the flower is unambiguously a flower, with five separately countable petals at 60 px and a readable flower at 29 px in light, dark, mono and Increase Contrast.
2. One hero flower, one geometry. The icon uses the exact wordmark petal paths and hex values, so icon, splash and header finally look like one brand. The Word o is a plain letter, which is what removed v2's "two different flowers" and the airy pockets around them.
3. Numbers (final build): petals 4.05:1 on cream and 4.43:1 on dark, worst colour-blind simulation 3.59 / 3.55; Word vs Flora 3.15:1 light (3.04 or better in every simulation), 1.39 dark; ring gap 1.61 px at 29 px (1.85 px in Increase Contrast); the four "Word" pairs at Nunito's native spacing (209 u) and every Flora pair within 15% of that as-set r-d on the x-height band (worst l-o at +12.7%; F-l the stated exception at +25.4% with a 45 u arm gap); "Word" ink width 4% tighter than v2; height 29.2 pt at 172 pt wide (v2 was 29.5), so the Home header layout is unchanged.
4. It keeps the one thing v2 got right that the research under-rated: gold "Flora" with rose petals on deep green in dark mode. Unified and centre moved dark Flora to pale green and lost it.
5. Lookalike exposure is the lowest of the three: five separate teardrop petals around a green ring with a round pistil is not the generic daisy emoji, not a smiley, not a tile, not a leaf.
6. Both reviewers ranked it first in round 1 (25/26 and 23/26) and the round-2 fixes addressed every item they raised (icon centre read as an eye or letter, ring-gap smear at 29 px, tuck notch at the l's foot, colour-profile bug in the renders, loose tracking).

## Why icon-smile rather than the plain hero icon

- The research's strongest directional finding is that faces carry emotion and character icons tend to beat abstract ones; the shipping daisy's smile is the warmest element the brand has, and users already know it. `icon-smile` keeps that continuity while switching to the new flower geometry and palette.
- The face rule is written down in `hero/notes.md`: the face lives in the icon and in illustrations, never inside a letter. The wordmark never carries it, so the letter reading is protected.
- At 60 px the face is legible; at 29 px it fades to a gold disc, which is the behaviour we want (a flower, not a smudge). Face ink is 8.56:1 on the gold.
- If the owner prefers a quieter, more adult mark, `hero/icon.svg` (same icon without the face) is the fallback and needs no other change. `icon-alt-cream.svg` (cream ground) is kept for comparison only; it is paler on a home screen and reviewers preferred the green ground.

## Why not unified

- Its icon is the natural successor to the shipping daisy and the most legible smile at 60 px, but the wordmark idea is weaker: the fused scalloped bloom reads as one amber shape rather than petals at 29 px, and in Increase Contrast it degraded to a gear until radial slits were cut into it (a patch, not a design).
- The light amber had to sit at the darkest edge of "orange" to clear 3:1 on cream; it read brown in round 1 and is only just orange now (3.61:1, 3.27 under deuteranopia, the thinnest margin of the three).
- The icon sat one step from a well-known game character (yellow petals, white smiling face) until its colours were inverted; after the inversion it is close to the shipping icon and to generic sticker daisies.
- It gave up the gold dark-mode Flora.
- It remains the right runner-up because its icon and its colour rule are sound; if the owner wants the smile on a fused bloom instead of separate petals, unified is the direction to revive.

## Why not centre

- Its idea (the o ring recoloured as the flower's centre on a solid rose disc) made the o a third colour and a badge; both reviewers read "donut", "target", "fried egg". The fix was to recolour the o back to Flora green, which removed the direction's own idea and left a rose disc behind a plain o.
- Mono-solid read as a cog or seal; the tinted icon as a white donut; the icon centre is amber, a colour the centre wordmark no longer uses (a stated deviation from the brief's R3).
- It is the third-ranked direction in every review.

## What the owner must decide

1. Adopt the hero wordmark (light, dark, solo, Increase Contrast) in place of v2. Yes or no.
2. App icon: `icon-smile` (recommended) or plain `icon`. Both are rendered at 1024/180/60/29 in light, dark and tinted.
3. Onboarding confetti: today the petal confetti uses the logo's ellipse shape and amber/rose colours, so the mark dissolves into it and the tagline is covered. Options: hold the confetti until the wordmark has settled, or restrict confetti to the non-logo colours (blue, cream). Not a logo change; an OnboardingView change for a later worker.
4. The Home hero-card illustration (eight-petal pink flower with a gold centre) is a third flower vocabulary. Decide later whether illustrations adopt the five-petal hero flower; not blocking.
5. A real reader test: five adults and five children aged 7 to 9, "what does this say?" and "what kind of game is it?" at the 29 px and 60 px renders, and "is there a letter in this?" for the icon. The agents' naive reads (in the reviews) are a stand-in, not evidence.

## Residual risks and known compromises

- Dark-mode Word vs Flora lightness gap is 1.39:1 (passes the 1.3 floor, closest to failing); the split survives on hue and both colours are at least 11:1 and 8.5:1 on the ground.
- The flower is scaled to 0.92 of the round-2 size so the Flora o pairs could be kerned to the limit; petals are still countable at 60 px. A petal that would reach the l or the r is scaled (0.969 minimum) rather than cut.
- F-l sits at +25% of the reference gap with a 45 u arm minimum; it is the one visibly looser pair and is inherent to a Black-weight F before an l.
- The smile icon's face is level (0 degrees) while the petals keep their -8 degree tilt; reviewer A found the tilted face read as quizzical at 1024 px.
- Centre's scallop notches measure only 1.6 to 2.5 px deep at 60 px under the corrected measure (round-2 target was 5 px); it is retired, so this is not fixed.
- Tinted icons are greyscale on black as rendered by our pipeline; iOS applies its own tint and has not been checked on a device.
- A7, A8 and A12 (letter reading, icon reading, lookalikes) were judged by agents from the pixels and by description; see decision item 5.

## Steps for the worker who ships it

Do not start until the owner has answered decisions 1 and 2. Only the asset catalog and, optionally, the preview gallery change; `WordmarkView` needs no code change.

1. Wordmark assets (filenames already match the catalog, so `Contents.json` files are untouched):
   - `design-preview/logo/v3/hero/wordmark.svg` -> `WordFlora/Assets.xcassets/Wordmark.imageset/wordmark.svg`
   - `design-preview/logo/v3/hero/wordmark-dark.svg` -> `WordFlora/Assets.xcassets/Wordmark.imageset/wordmark-dark.svg`
   - `design-preview/logo/v3/hero/wordmark-solo.svg` -> `WordFlora/Assets.xcassets/WordmarkSolo.imageset/wordmark-solo.svg`
   - `design-preview/logo/v3/hero/wordmark-solo-dark.svg` -> `WordFlora/Assets.xcassets/WordmarkSolo.imageset/wordmark-solo-dark.svg`
   - `design-preview/logo/v3/hero/wordmark-mono-solid.svg` -> `WordFlora/Assets.xcassets/WordmarkMono.imageset/wordmark-mono-solid.svg` (template-rendered and tinted with `appPrimaryText` by `WordmarkView`; the file uses solid fills, no opacity, so tinting is safe).
   - All five are plain `<path fill>` SVGs with width/height equal to the viewBox and "Preserve Vector Data" is already on in each image set.
2. App icon (owner's choice of smile or plain). The 1024 px PNGs are already rendered, flat background, no transparency:
   - `design-preview/logo/v3/hero/png/icon-smile-1024.png` -> `WordFlora/Assets.xcassets/AppIcon.appiconset/AppIcon-default.png`
   - `design-preview/logo/v3/hero/png/icon-smile-dark-1024.png` -> `AppIcon-dark.png`
   - `design-preview/logo/v3/hero/png/icon-smile-tinted-1024.png` -> `AppIcon-tinted.png`
   - (plain variant: `icon-1024.png`, `icon-dark-1024.png`, `icon-tinted-1024.png`). Confirm each PNG is RGB without an alpha channel before copying (`PIL Image.open(p).mode == 'RGB'`); re-save as RGB if not. `Contents.json` is unchanged.
3. `WordmarkView` (`WordFlora/Theme/Theme.swift`): no change. The new aspect ratio is about 5.89:1 (v2 5.83:1), giving 29.2 pt at 172 pt (Home) and 44.5 pt at 262 pt (Onboarding); the 130 pt solo threshold and the 1.6x Dynamic Type cap stay valid. Keep `.accessibilityLabel("WordFlora")`.
4. Verify on simulator (when machine load allows): Home light and dark headers, Onboarding, Increase Contrast on, largest accessibility text size (the existing UI tests in `WordFloraUITests` cover the pot picker at accessibility sizes; add or rerun the wordmark header check). Compare against `design-preview/logo/final/shots/app-home-*.png`.
5. Optional: add a link to `logo/v3/index.html` from `design-preview/logo/index.html` (not done here; the brief restricted writes to `logo/v3/` and `docs/`).
6. Rebuild from source if anything changes: `design-preview/logo/v3/build.py --direction hero` then `render.py --direction hero` then `page.py`, using a Python with fontTools, skia-pathops and Pillow (the font is vendored at `design-preview/logo/v3/fonts/Nunito-900.ttf`, SIL OFL).

## Reviewer scores

Two independent reviewers (A: `review/review-a.md`, `review-a-round2.md`; B: `review/review-b.md`, `review-b-round2.md`), each scoring A1-A13 at 0/1/2 from the pixels (4x upscales, scripted greyscale and deuteranopia/protanopia/tritanopia simulations via `review/cvd_sim.py`, naive "what does this say / what game is it" reads at 29 and 60 px, lookalikes by description).

| | Round 1 A | Round 1 B | Round 2 A | Round 2 B | Rank (both) |
|---|---|---|---|---|---|
| hero | 25/26 | 23/26 | 25/26 | 25/26 | 1st |
| unified | 23/26 | 21/26 | 25/26 | 23/26 | 2nd |
| centre | 20/26 | 18/26 | 24/26 | 23/26 | 3rd |

Round-1 findings that were fixed in round 2 (verified by both reviewers on the renders): icon centre reading as an eye, letter O or avocado (hero), Flowey-style lookalike (unified icon), the o as a third colour reading as a donut or badge (centre), ring-gap smear at 29 px, the tuck notch at the l's foot, clipped compare sheets, and a pipeline bug in which the PNGs carried a non-sRGB colour profile so stored pixels did not match the SVG hex.

Round-2 open item, fixed in the final pass (2c) after the re-score: reviewer A showed that the round-2b spacing had made the "Word" pairs tight (-14%) while the Flora pairs sat at +12%, so the rhythm was uneven across the halves of the word; the final build sets the Word pairs back to Nunito's native spacing and verifies every pair against the as-set r-d on the full word. Reviewer B had asked instead for a tighter o-r; the two requests conflict and A's whole-word measurement is the one that matches what the eye sees, so A's fix was applied.

Icon: reviewer A recommends `icon-smile` on the green ground with plain `icon` as fallback; reviewer B recommends plain `icon` and calls `icon-smile` an acceptable owner option. Both reject the cream-ground alternative. My pick is `icon-smile` for the reasons above; it is an owner decision either way.

Reviewer A's reading of centre after its fixes is worth quoting in substance: with the o back to green it is no longer a distinct idea, just a rose version of unified's round-lobe bloom, and should be retired rather than refined.

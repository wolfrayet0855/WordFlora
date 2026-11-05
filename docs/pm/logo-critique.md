# WordFlora logo critique and redesign brief

Date: 2026-11-04. Branch: 3-feat-content-and-polish. Author: project manager.
Inputs: `docs/research/logo-brand-research.md` (read in full; market claims treated as directional), and my own viewing of `design-preview/logo/final/compare/sheet-{light,dark,mono}.png`, `tiny-zoom.png`, `final/png/*`, `final/shots/app-home-{light,dark}.png`, `app-onboarding.png`, the icon candidate `design-preview/logo/icon/png/icon-{1024,60,29}.png`, and the shipping icon `WordFlora/Assets.xcassets/AppIcon.appiconset/AppIcon-default.png`.

## Headline

The wordmark is a well-built piece of type with a weak idea bolted onto it. "WordFlora" is legible everywhere; the flowers are not. At the two sizes the app actually uses (29 pt tall on Home, about 44 pt on Onboarding) the petals are pale smudges around two heavy letter rings, so the mark reads as "W(o)rdFl(o)ra" with two coloured halos, not as a word with a flower in it. The brand currently has three different flowers (eight-petal daisy icon, five-petal wordmark bloom, eight-petal pink hero-card illustration) and none of them is the hero. Dark mode is the better version by a distance, which tells you the problem is lightness, not shape.

## What works (keep)

1. Legibility. Nunito Black at wght 900, the o rings are the font's own o, counters open. It reads at 29 px tall in every variant, including mono. This is the single most valuable property and it is what the whole v1/v2 process protected. Do not spend it.
2. The two-word split. Dark "Word" and green "Flora" make the compound name parse instantly; the colour change lands exactly on the word boundary.
3. The palette family. Ink green, leaf green, amber, rose on cream is calm, warm, craft-like, and matches the app (Play button amber, Daily Bloom rose, Garden green). Dark mode mint and gold on deep green is handsome.
4. Dark variant. Gold "Flora" with the rose bloom is the only version where the flower reads at Home size. It should set the target for light mode, not be the exception.
5. Build discipline. Plain-path SVGs, reproducible build, measured kerning, before/after sheets. The redesign must keep this pipeline.
6. The shipping icon's face. The smiling daisy is the warmest thing in the brand and the only element with a personality. At 29 px it still reads as a flower; the smile fades gracefully.

## What does not work

1. The flowers are invisible where they matter. Light amber #DA8B22 is 2.55:1 on cream and rose #E07A8E is 2.67:1. On `app-home-light.png` the amber flower is a mustard blur and the rose flower is a pink blur. The five petals are countable at 320 px and nowhere the app shows the mark. A flower you cannot see is a kerning problem with no payoff.
2. The ring dominates the flower. The petals are pushed behind a 36-unit gap around a ring as heavy as the other letters. Result: a thick dark ring with a thin coloured fringe. At 60 px it looks like a life-ring or a radio button with a halo, not a bloom. The research blames petal contrast; I blame the proportion too. Petals need to be bigger relative to the ring, or the ring needs to sit on top of a solid bloom.
3. Two different flowers in one word. Amber with a petal up, rose turned 36 degrees. The eye bounces between them; neither is the hero. At Home 3x the word reads like patterned fabric. Pick one hero (Flora o) or make the pair identical twins with a stated rule.
4. Rhythm. W–o is +29%, l–o is +45%, d–F is −33% relative to r–d. On `sheet-light.png` Home 3x you can see "W ord Fl ora". The v2 review traded rhythm for petal clearance; that trade produced a mark that is both airy and still faint. The fix is a flower that does not need the clearance (no side petals at 90 degrees, or petals allowed behind neighbours), not more kerning.
5. Icon and wordmark are strangers. Eight pointed cream petals and an amber face on green, versus five round amber/rose petals on cream with no face. A user who taps the icon and lands on Home sees no relation. The candidate "o" icon (`icon/png/icon-1024.png`) fixes the link but reads as a letter O, a zero, or a button, and at 29 px it is a yellow blob on green with no flower reading and no warmth. It is worse than what ships.
6. Three flower vocabularies on one screen. Home shows the wordmark bloom and, directly under it, the hero card's eight-petal pink flower with a gold centre, and the app icon is a third. The redesign must produce one flower geometry that the icon and wordmark share, and the owner should later decide whether the in-app illustrations adopt it.
7. Onboarding. The petal confetti on `app-onboarding.png` uses the same ellipse shape and the same amber/rose as the logo petals, so the logo's flowers dissolve into the confetti and the tagline is covered. Not strictly a logo fault, but the logo should not be made of the same shapes as the celebration particles. Note for the owner: hold confetti until the mark has settled, or use the non-logo colours (blue, cream) for it.
8. Mono. Petals at 0.55 opacity read as a grey shadow behind the o. Mono-solid (0.6) is acceptable. Increase Contrast should use a solid ink with a visible gap, never an opacity tint.

## Where the research is right and wrong

Right: petal contrast numbers and the 3:1 target; amber and rose being identical in luminance (1.05:1) so the two-colour story carries nothing in greyscale or any CVD simulation; the weak Word/Flora lightness gap (2.15:1); the rhythm figures; the icon/wordmark mismatch; "make one flower the hero"; "the icon and store listing matter more than the wordmark for attention"; the recommendation to test with 7 to 9 year olds. The ranked improvements 1 to 5 are the right list.

Wrong or overstated:
- "A letter in the icon is against the spirit of the HIG" is not the candidate icon's real problem. Its problem is that it reads as O or zero, has no face, and the petals vanish at 29 px. A flower that happens to have a ring centre is fine if it reads as a flower first.
- Direction 5 (tile-and-bloom) imports Wordle-category cues that contradict "calm garden" and look like every other word game. Drop it.
- Direction 4 (leaf-and-word) is generic and adds a second motif when the brief is to reduce to one. Drop it.
- The research treats dark mode as "looks solid, check rose" and moves on. Dark mode is the proof that the concept works when petals are far from the background in lightness. Light mode should be rebuilt to the same lightness gap.
- The research did not notice the third flower (hero card) or the confetti clash, both visible in the shots it listed.
- Lookalike section is from memory only. Reviewers must do a real described comparison (Duolingo, Forest, Headspace, Calm, Finch, Wordscapes, Lily's Garden, Gardenscapes, PictureThis, Seek, Flora, Blossom, Planta) by description, no copying.

## Directions worth exploring

1. Hero-flower wordmark (research direction 1). Plain "Word" in ink green (no decoration), one large flower on the Flora o. Petals wide and deep-coloured, countable at 60 px. The icon is that same flower.
2. Unified system with the smile (research directions 2 and 3 merged). One flower geometry shared by icon and wordmark; the icon carries the face (two dots, one arc) inside the ring centre; the wordmark may carry the smile only in the solo lockup if the o still reads as a letter at 29 px, otherwise the wordmark omits it under a written rule ("the face lives in the icon and in illustrations, never inside a letter").
3. One of the visual agent's own choosing. Suggested starting points: a solid bloom under the o (five overlapping fat petals forming a disc the ring sits on, so the flower reads as a shape at 29 px); or the whole o ring recoloured as the flower's centre in amber with the petals in rose, so colour alone separates it from the green letters. Not the tile direction, not the leaf direction.

## What must NOT change

- "WordFlora" legible as the name at 29 px tall and above, in every variant, read by a grade-2 reader. Nunito Black (wght 900) letters, unaltered, except the decorated o.
- The ring o is the real Nunito o with its counter open. The flower decorates the letter; it never replaces it with a picture.
- Calm, warm palette: greens, amber, rose, cream. No primaries, no gloss, no sparkle, no bevel, no gold-on-red/purple.
- Colour-blind safe: no information carried by amber vs rose alone; flower visible in greyscale.
- Kid and adult friendly: round, friendly, not bubbly, no cartoon eyes on letters; a simple face is allowed in the icon only.
- Plain-path SVGs, reproducible build, light/dark/mono/Increase Contrast variants, `WordmarkView` sizing contract (172 pt Home, 262 pt Onboarding, solo below 130 pt).

## Redesign brief

Deliver three distinct directions under `design-preview/logo/v3/<direction>/`, each with light, dark, mono, mono-solid (Increase Contrast) and solo variants, an app icon (1024 square, no text, no transparency, default, dark and tinted), renders at 1024/180/60/29 px (icon) and 320/172/120/60/29 px tall (wordmark), a before-vs-after sheet against `design-preview/logo/final`, a build script, notes with measurements, and `design-preview/logo/v3/index.html` comparing all three. Headless Chromium over file://. The agent looks at its own PNGs before reporting.

### Requirements

R1. Letters: Nunito instanced at wght 900, unaltered glyphs for W, r, d, F, l, a. Only the o glyphs may carry decoration; the o ring and counter stay the font's own.
R2. One hero flower on the Flora o, or a deliberate identical pair (same petal geometry, same rotation, and a written colour rule). No "two different flowers".
R3. The icon flower and the wordmark flower are the same path geometry (scaled), same petal count, same palette. If the icon has a face, the rule for where the face appears is written down.
R4. Light, dark, mono (single ink, solid fills or opacity, no gradients), mono-solid for Increase Contrast, solo lockup for widths below 130 pt.
R5. SVG hygiene: only `<path fill="...">` elements (fill-opacity allowed in mono only), no mask, stroke, filter, gradient, `<use>`, `<text>`, or `@import`; width and height attributes equal the viewBox; the icon is a flat fill background (no gradient).
R6. Build reproducible from a script (`build.py` or equivalent) using the font at `/private/tmp/claude-501/-Users-computer-Desktop-workspace-WordFlora/4a7b4bed-9e4b-4277-b17d-f2a3956c6a07/scratchpad/fonts/Nunito-900.ttf`, with a copy of that font placed at `design-preview/logo/v3/fonts/Nunito-900.ttf` (SIL OFL) so the build does not depend on scratch files.
R7. No edits outside `design-preview/logo/v3/` and `docs/`.

### Measurable acceptance criteria

A1. Petal contrast against the background at least 3.0:1 in light mode (on cream #FAF7F0) and in dark mode (on #1A2E1A), WCAG relative-luminance formula, reported in the notes.
A2. Petals separate from the ring: either contrast of at least 2.0:1 between petal colour and ring colour, or a gap between petal and ring of at least 1.0 px when the wordmark is 29 px tall (that is, at least 34 font units for a 1000 upm face rendered at about 29 px cap height; compute and state it).
A3. Flower reading at small sizes: at 60 px tall, every petal is individually countable by eye in light, dark and mono. At 29 px tall the flower reads as a flower (a reviewer asked "what is around the o" answers "a flower"), not as a halo or a blob. Each petal is at least 4 px across at its widest when the mark is 29 px tall.
A4. Word/Flora lightness gap: the luminance contrast between the two word colours is at least 3.0:1 in light mode and at least 1.3:1 in dark mode, and each word colour is at least 4.5:1 against its background. The split must be visible in a greyscale render.
A5. Colour-blind safe: under deuteranopia, protanopia and tritanopia simulation (Machado 2009 matrices, severity 1.0), petals still measure at least 3.0:1 against the background and the Word/Flora split at least 2.0:1 in light mode. No meaning depends on amber vs rose.
A6. Rhythm: the mean horizontal gap across the x-height band for every adjacent letter pair (W–o, o–r, r–d, d–F, F–l, l–o, o–r, r–a) is within plus or minus 15% of the r–d reference, measured by the build script and printed. Petals may pass behind neighbouring letters only if at least 80% of each petal's area stays visible; the hero flower may not be cut by a letter in a way that destroys the flower silhouette.
A7. Legibility: "WordFlora" reads correctly at 29 px tall in all variants. The decorated o is still read as "o" (not as a badge or emoji) by reviewers at 29 and 60 px.
A8. Icon: 1024 x 1024, no text, no transparency, flat background, one focal shape, reads as a flower at 29 px, and at 60 px the face (if any) is legible. Default, dark and tinted variants rendered at 1024/180/60/29.
A9. Works in light, dark, mono and Increase Contrast (mono-solid): all four rendered and inspected at 29 and 60 px tall.
A10. Sizing contract: report the aspect ratio and the height at 172 pt and 262 pt wide; height at 172 pt should be between 26 and 34 pt so the Home header layout is unchanged.
A11. Kid and adult tone: no bubbly baseline bounce, no saturated primaries, no gloss, sparkle or bevel, no eyes on letters. A face in the icon is two dots and one arc at most.
A12. Lookalike: reviewers describe the closest well-known app marks and confirm no confusable match. Nothing is copied.
A13. Before/after: a sheet per direction with v2 (`design-preview/logo/final`) on the left and v3 on the right at 29, 60, 172 and 320 px, light and dark.

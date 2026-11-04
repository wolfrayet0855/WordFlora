# T-F logo: critic review

Reviewed on 2026-11-04. I looked at every render myself: wordmark at 320 and 120 px (light, dark, mono), icon at 180, 60 and 29 px (light, dark, tinted), and the Home header mock on each `index.html` at 390 px. I also looked at the current `AppIcon-default.png` (white 8-petal daisy with a smiling amber face on a green gradient) and `WordmarkView` (SF Rounded heavy, "Word" in appPrimaryText and "Flora" in wordmarkFlora). The contrast figures below are WCAG ratios that I recomputed from the hex values in the SVGs.

Gallery: `design-preview/logo/index.html`.

## Scores (1 to 5, higher is better; for integration, 5 means cheapest)

| Criterion | A Two blooms | B Ring blooms | C Tiles + bloom |
|---|---|---|---|
| Legibility (wordmark at 120 px, icon at 29 px) | 4 | 4 | 3 |
| The O's read as O's | 3 | 5 | 3 |
| Distinctiveness (vs current icon and generic flower apps) | 2 | 5 | 2 |
| Kid appeal plus adult calm | 4 | 4 | 3 |
| Light, dark and mono robustness | 4 | 4 | 3 |
| Colour-blind safety (lightness, not hue) | 3 | 4 | 3 |
| Fit with the palette and SF Rounded headings | 4 | 4 | 3 |
| Integration cost | 4 | 3 | 2 |
| **Total (out of 40)** | **28** | **33** | **22** |

## Direction A: Two blooms
- **Wordmark.** The most finished of the three. The kerning is tight and even, and the 36° rotation between the two blooms is a nice touch. In dark mode it is excellent: light petals around a dark centre read as a ring.
- **O's.** In light mode each bloom is a scalloped disc with a pale dot. The disc reads as an O mostly because of the word around it, not because of its shape. At 320 px the eye sees "flower" first and "o" second. That makes A the version most at risk of reading "W*rdFl*ra". Mono holds up better, because the centre is cut out.
- **At 120 px.** Readable. The amber bloom (#E0962A, 2.29:1 on cream) is the faintest element of the mark, so "Word" looks lighter than "Flora".
- **Icon.** A pink bloom plus a small amber bloom on dark green. It is clean and works at 29 px. But it is the current icon with the face taken out, and it looks like hundreds of garden and flower apps. Nothing in it says "word game". The rose bloom on deep green is 2.74:1, which is weak under deuteranopia (brown on olive).
- **Integration.** Plain filled paths, with no masks, gradients or strokes in the wordmark, so it drops into the asset catalogue safely.

## Direction B: Ring blooms
- **O's.** The only direction where the O is always the real letter. The ring is Nunito Black's own "o", and the petals sit behind it with a 30-unit gap. Take the petals away and the word is unchanged, which the mono render shows. This is the strongest answer to the brief's main constraint.
- **Wordmark weaknesses.** (1) The six-petal daisy on the Word O has near-horizontal petals that push the W away. The W–o gap is visibly wider than every other gap. (2) At 120 px the daisy breaks up into an amber starburst. (3) Coral #E0705A against the Flora green ring is 1.68:1. It is saved only by the gap. (4) Coral is a new hue that is not in theme.css.
- **Icon.** A cream "o" inside a five-petal amber blossom on green. It is the most distinctive of the three: the letterform says "word game" and the blossom says "garden". At 29 px the counter stays open and the five lobes read as a flower. The tinted version keeps three clear grey levels (white ring, #7A7A7A petals at 4.29:1 against the ring and 4.89:1 against black). It loses the current icon's smiling face, so it is a little less kid-cute and a little more grown-up.
- **Integration.** The SVGs depend on `<mask>`, and the mask is built from a *stroked* path (stroke-width 62.4). Xcode's asset-catalogue SVG renderer handles masks and mask strokes poorly, so the gap has to be baked into geometry before it ships (see the spec).

## Direction C: Word tiles + bloom
- **Lettering.** The hand-built stroke letters are friendly, but the r, a and W are less refined than A's and B's Nunito outlines. Next to SF Rounded headings they look home-made. The baseline "shelf" bar almost disappears at 120 px and adds nothing at 320.
- **O's.** The O's read as flowers with a green bullseye. The 1 px gap ring at small sizes does not keep the counter readable.
- **Colour.** The pale petal tone is 1.6:1 on cream. That is the lowest figure of the three.
- **Icon.** Generic (a large daisy) and close to the current icon. The rounded corners are baked into the SVG, which iOS forbids.
- **Integration.** Strokes plus masks, and the corners would need to be redrawn. This is the most expensive to ship.

## Winner: B's ring-O concept and icon, refined with A's bloom shape, colour logic and kerning discipline

B is the only direction where "WordFlora" survives with the petals removed, and its icon is the only one that ties the garden to the word game. A's wordmark is more polished, so the refinement borrows A's polish rather than A's construction.

### Refinement spec (wordmark)
1. **Petals.** Both O's get five rounded petals, A's ellipse shape, with petal tips no more than 1.18× the ring's outer radius. Drop the six-petal daisy because it causes the 120 px starburst. Word O: one petal points straight up (0°). Flora O: rotated 36° so one petal points straight down. This is A's trick and keeps them from looking stamped.
2. **Gap.** 36 font units, up from 30, so it survives at 120 px. Build it as petals minus (the union of *all* glyph outlines, dilated by 36 u). This lets the petals tuck behind the W's right diagonal and the r's left stem rather than pushing them away.
3. **W–o spacing fix.** Return to Nunito's native W–o advance minus 40 u (the petals now pass behind the W through the gap mask). Target: the optical W–o gap within ±10% of the r–d gap. The extra breath at d|F stays at 20 u at most.
4. **Colours** (letters unchanged: #2C3E2C / #2A7A38 light, #D4EDD4 / #F0C060 dark):
   - Light, Word petals: amber **#E0962A**. Against the ink ring 4.67:1, against #FAF7F0 2.29:1.
   - Light, Flora petals: soft rose **#EE8C9E**. Against the green ring 2.25:1 (B's coral was 1.68), against the background 2.21:1. Luminance 0.39 sits halfway between the ring (0.15) and the cream (0.93), so the bloom keeps its shape by lightness alone.
   - Dark, Word petals: **#E0962A**. Against the ring 1.97:1, against #1A2E1A 5.91:1.
   - Dark, Flora petals: **#E25D78**. Against the gold ring 2.04:1, against the background 4.19:1.
   - The rose stays a decoration. Every letter and ring keeps at least 4.5:1.
5. **Variants.** Twin blooms from 130 pt wide upwards (Home .title about 172 pt, Onboarding about 262 pt). **Solo** (only the Flora O blooms) below 130 pt: nav bars, widgets, share cards, and anything rendered under 20 pt tall. Mono uses a single ink with the petals at 45% opacity of the same ink, gap kept.
6. **Integration.** Bake the gap into the geometry in `build.py` (skia-pathops or fontTools pathops: petals minus dilated glyphs). The result must be plain filled paths only, with no `<mask>`, stroke or filter. Ship it as one SVG image set, "Wordmark", with Any and Dark appearances, Preserve Vector Data on, and a second set, "WordmarkSolo". `WordmarkView` becomes `Image("Wordmark").resizable().scaledToFit().frame(width: w)`, with `w` a `@ScaledMetric(relativeTo: style)` (172 at .title) and the existing `.accessibilityLabel("WordFlora")`. I would not compose SF Rounded `Text` with a flower glyph swapped in. Kerning across a `Text` and a shape cannot be matched reliably, and SF Pro's licence does not allow converting it to outlines for a logo. Nunito Black (OFL) is close enough to SF Rounded Heavy to sit beside the headings.

### Refinement spec (icon, candidate only)
- B's composition: a cream ring #FBF4E4 inside an amber five-petal blossom on green. Change the gradient to **#3E7A2A → #2E6B22**, which sits closer to the app's greens and is calmer than #558A26. Against cream that is about 5.95:1 at the bottom, and the amber #F0B848 petals against the green are about 2.9 to 3.6:1.
- Enlarge the ring by 6% so the counter is at least 5 × 7 px at 29 px.
- Dark version: the same geometry on #1A2E1A → #132313. Tinted version: keep B's three grey levels.
- Full-bleed 1024 square with no baked corners. Place it under `design-preview/logo/icon/` only.

### Should the app icon change in this round?
**No. Change the wordmark only.** The brief swaps `AppIcon` only on a unanimous review team or the owner's go-ahead, and I would not vote for a swap yet. B's icon is the right direction, but it drops the smiling face that gives the current icon its kid appeal. It also has not been seen on a real home screen next to other apps, or at 29 px in Settings and Spotlight. Refine it, put it in `design-preview/logo/icon/`, show it to the owner beside the current icon, and decide then.

# Logo direction A: "Two blooms"

Both O's in "WordFlora" are five-petal blooms. The other letters are Nunito Black (900), the closest free match to SF Rounded Heavy, which `WordmarkView` uses today. All letters are converted to outline paths, so every SVG works without a font and no PNG fallback is needed. The source is `src/gen.py` (fontTools; run it as `python gen.py Nunito-Black.ttf <outdir>`, Nunito is OFL from Google Fonts) and the PNGs come from `src/render.sh` (headless Chromium driving `render.html`).

## Decisions
- **The bloom stands in for the o.** The five ellipse petals make the outer edge of the o. The round centre (radius 112 units) sits where Nunito's o counter sits. The bloom is 568 units across and Nunito's o is 543, so the petal tips poke just past the x-height and the baseline. That small overshoot is what makes it look like a flower and not a letter.
- **Five petals, not six.** The first try used six petals. At 120 px, and in the mono version, it looked like a cog. Home shows the wordmark right next to the settings gear, so that look had to go. Five petals have deeper notches and read as a flower.
- **The centre is the counter.** On light backgrounds the centre is the lightest part of the bloom (pale butter or gold). On dark backgrounds it is the darkest (deep brown or plum). Either way the bloom keeps the ring-with-a-hole silhouette that the eye reads as "o". In the mono version the centre is cut out, so it is a real o with a petalled edge.
- **One bloom per word, in the other warm colour.** "Word" gets an amber bloom and "Flora" gets a rose one. The two blooms are turned 36° apart (one has a petal pointing up, the other a petal pointing down), so they do not look stamped.
- **Kerning:** tightened by hand around the round blooms (W/o -58, l/o -8, r/a -14). Everything else uses Nunito's advance widths.
- **Icon:** the two O's taken out of the wordmark. A big rose bloom (top left) and a small amber bloom (bottom right) sit on one diagonal on the Flora green gradient. They are about 25 units apart at 1024, so they never merge, even at 29 px. I left out a face and a leaf because both turned to mush at 29 px. The SVG is a full-bleed square with no transparency, as Xcode expects. iOS applies the rounded mask, and index.html shows the icons masked.
- **Tinted icon:** greyscale on black, like the current `AppIcon-tinted.png`. Rose petals go white, amber petals light grey, centres mid-grey or black.

## Colours
| Part | Light | Dark |
|---|---|---|
| "Word" letters | #2C3E2C (appPrimaryText) | #D4EDD4 |
| "Flora" letters | #2A7A38 (wordmarkFlora) | #F0C060 |
| Bloom 1 (Word) petals / centre | #E0962A / #FFF4D6 | #F0C060 / #4A3410 |
| Bloom 2 (Flora) petals / centre | #E25D78 / #FCD46E | #F58FA2 / #4D3039 |
| Icon bg gradient | #2E7F3B to #18491F | #22391F to #132313 |
| Icon blooms | rose #F2788A, centre #FCD46E, dot #E8A838; amber #F0B848, centre #FFF4D6 | rose #F58FA2, centre #F0C060; amber #F0C060, centre #4A3410 |

### Contrast (WCAG ratio)
Letters, which need at least 4.5:1:
- "Word" #2C3E2C on bg #FAF7F0: **10.71**; on white surface: 11.46
- "Flora" #2A7A38 on bg #FAF7F0: **4.98**; on white surface: 5.33 (passes, but with the least margin of any pair)
- Dark "Word" #D4EDD4 on #1A2E1A: **11.63**; on dark surface #2C3E2C: 9.20
- Dark "Flora" #F0C060 on #1A2E1A: **8.56**; on dark surface: 6.77

Blooms are decorative, and the accessibility label stays "WordFlora". For reference:
- Light: rose petals on bg 3.23; amber petals on bg 2.29 (weakest). Petal vs centre: rose 2.43, amber 2.24.
- Dark: amber petals on bg 8.56; rose petals on bg 6.44. Petal vs centre: 6.94 and 5.19.
- Icon: rose on deep green 2.74; amber on deep green 4.08.

## Colour-blind check
Relative luminance values: rose petals 0.25, gold centre 0.69, amber petals 0.38, cream centre 0.91, "Flora" green 0.15, "Word" 0.04.
- **Deuteranopia and protanopia:** rose and amber both turn into yellow-brown or ochre tones, so the two blooms look like the same hue and differ only a little in lightness (rose is darker). Protanopia darkens rose further, to a dusty brown. That is fine, because the two blooms do not need to be told apart. What carries the shape is **lightness inside each bloom**: dark petals around a light centre in light mode, light petals around a dark centre in dark mode. Light-mode lightness gaps are 0.25 vs 0.69 (rose) and 0.38 vs 0.91 (amber), so both stay clearly ring-shaped.
- "Word" and "Flora" also stay apart by lightness (0.04 vs 0.15) once the green turns olive.
- In the icon, the rose bloom on green becomes brown on olive under deuteranopia. The luminance contrast of 2.74 and the big shape keep it readable, but it is the weakest pairing in the icon. The amber bloom (4.08) holds up well.
- Tritanopia: rose turns pinkish-red and amber turns pink-grey. Both still read.

## How it degrades
- **Wordmark at 29 px tall (191 px wide):** each bloom is about 20 px across, all five notches are visible, and the centre counter is clear. It reads as WordFlora with flower O's.
- **Wordmark at 120 px wide (19 px tall):** the blooms are 13-14 px. The petals merge into a soft scalloped ring with a light centre, so it still reads as an o. The amber bloom in light mode is the faintest element, because it is lighter than the heavy letters. In mono it reads as a cog-like o, much less so than the six-petal version did.
- **Icon at 60 px:** both blooms are clearly flowers.
- **Icon at 29 px:** the big rose bloom with its gold centre is a clear flower. The small amber bloom shrinks to an 8-9 px yellow blob with a light dot, which reads as "a second little flower" rather than a detailed shape. The inner dot in the big bloom's centre is lost, and that loss does no harm.

# Logo C: Word tiles + bloom

## Decisions
- Lettering is custom: every letter is a rounded stroke path (16 u stroke, round caps/joins), so there is no font dependency and no text-to-path step. It is "Nunito Black-like", not Nunito itself. SVGs are self-contained.
- Letters sit on one soft baseline bar (the tile shelf). Cap height 90 u, x-height 60 u.
- Both O's are blooms: 6 round petals alternating two tones, a gap ring cut by a mask, then a solid centre. The gap ring keeps it an "O" (ring plus counter) instead of a blob.
- "Word" = app primary ink; "Flora" = wordmarkFlora (light 2A7A38). Dark mode "Flora" = F0C060, the real dark value of the wordmarkFlora colorset (gold, not green).
- Icon = the same bloom enlarged on a green gradient (light), 1A2E1A (dark), black greyscale (tinted). Rounded corners are drawn in the SVG for preview; the shipping asset should be full-bleed.

## Colours and contrast (WCAG)
- Word light 2C3E2C on FAF7F0: 10.7:1. Flora light 2A7A38 on FAF7F0: 5.0:1.
- Word dark D4EDD4 on 1A2E1A: 11.6:1. Flora dark F0C060 on 1A2E1A: 8.6:1.
- Petals: D9892B / F2BF4E on cream are 2.6:1 / 1.6:1 (decorative, below 3:1). The green centre carries the O shape (centre vs petals 1.9 to 3.1:1).

## Colour-blind check
Petals A and B differ in luminance (0.33 vs 0.57 light; 0.40 vs 0.80 dark icon), and the centre is much darker than both (0.15), so the bloom's structure does not depend on hue. Tinted icon is pure greyscale (white / B8B8B8 / 4D4D4D). Not run through a simulator, only luminance maths.

## Degradation at 29 px
Icon: bloom is about 21 px wide. Reads as a flower with a dark centre; the two petal tones still show but the gap ring is about 1 px. Wordmark at 120 px wide: letters legible, blooms read as small flowers/O's, the baseline bar is faint. Below ~100 px wide the petal tones merge.

## Files
wordmark(.svg|-dark|-mono), icon(.svg|-dark|-tinted), png/ renders, render.html, index.html.

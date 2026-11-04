# Option B refined: love row plus a falling petal (built)

Owner turned down C (blush) and liked A or B. Built: B's readable row, plus A's falling petal coming off Daisy herself. The floating crown is gone from every frame.

## What is on screen
- **Love row** (`.lovebar`, lifestats.html): a glass pill centred under Daisy at y 518-546. A small pink 5-petal flower with a gold centre comes first so it reads as "Love", then 5 pips, one per day of love. Filled pip: `--petal` with a `--petal-edge` edge. Pip gone for now: a dashed `--ghost` outline (1.4 px, non-scaling) with a 16% ghost fill, so it shows in dark. No words, no numbers, never red. The row is hidden in the seed state (the seed pot stays as it was).
- **Falling petal**: one of Daisy's own white petals (same ellipse and colours as plant_daisy.svg) lets go from her head on the right side (67.5, 90 or 112.5 degrees, so it never drifts toward the panel). It lifts, drifts down once in 3.4 s (0.6 s delay) behind the near rain, blushes to a soft love pink, and rests flat on her ground shadow at 78% size. Fill-mode `both`, no `infinite`. Today's pip fades at the same moment (0.7 s delay).
- **Reduce Motion**: no drift. The petal fades in where it rests and the pip fades. Regrown pips simply appear.
- **Regrow**: pips come back one by one, 0.3 s apart, with a spring, in the row and the panel. Replay buttons rerun the fall and the regrowth.
- **Panel Love key**: the same flower plus 5 pips (10x14), then "Love keeps her petals."
- **VoiceOver**: Daisy is one element, "Daisy, 3 of 5 love petals". The row is hidden from VoiceOver as part of her. The panel key reads "3 of 5 love petals. Love keeps her petals."
- **Accessibility text size**: Daisy moves up to y 146, and the row grows (pips 17x24) to y 270-304, above the hint (316) and the sheet (354).
- **Reduce Motion badge** moved to y 558 so it sits below the row.
- **wake-options.html** success card uses the same row style (flower, filled or dashed-with-fill pips).

## Checked (Playwright, Chromium, 390 pt, light and dark)
- Shots: parts/shots/optB-{light,dark}-01..11.png, optB-*-03-midfall.png, optB-light-03-reducemotion.png, optB-wake-{light,dark}-3.png.
- Bounding-box test: the row does not overlap the panel (gap 11 pt), cloud, badge, hint, wake card or actions in any frame. Rain splashes land above it (drops stop by y 506).
- No banned words in visible text or labels. No page errors.

## Open question for the owner
Daisy's art stays whole: the petal that falls is a copy that peels off her head, so she does not visibly thin. If you want her to visibly lose white petals (and grow them back), Swift has to draw her 16 petals as separate layers rather than one image. That is a change to how her art is drawn, so it is your call.

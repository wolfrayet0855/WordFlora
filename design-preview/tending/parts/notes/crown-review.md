# Crown review (Opus visual, one element: `.crown` in lifestats.html)

Evidence: life-light-01/03/06, life-dark-08 in shots/; my renders crown-A/B/C-{light,dark}.png and crown-C-regrow.png.

## Verdict: replace

1. **Reads as a second flower, not as Daisy's life.** A pink 5-petal flower with a hub floats about 50 pt above her head, with no stem and no link to her. Next to her white daisy head it looks like another bloom, a butterfly or a sticker. The tiny heart hub (about 9 pt) does not show at a glance, so the "love" link only comes through the panel text.
2. **Lopsided at partial counts.** Kept petals are slots 0..n-1 in order, so 3 petals make a broken fan pointing right (shots 03, 06) and 1 petal is a single spike. The count is hard to read because the shape changes as well as the number.
3. **It sits in the weather.** It is right under the cloud and inside the rain column (shots 03, 08). In dark mode the dashed ghosts (#A9B8A9, 3 px dash) blend into the rain streaks.
4. **Fall animation loops forever** (7 s, `infinite`) and travels 560 px, past her face and the ground (the rest petal lies at y 458). A loop says "she keeps losing petals" rather than "one petal today". The fall should play once per day and end on the ground petal.
5. **Regrow is fine.** fill-box with 50% 100% puts the pivot at the hub, there is a 0.3 s stagger and a spring.
6. **Matches FlowerView only in petal path.** FlowerView has 8 petals with a colour ramp. Keeping 5 pink (overseer ruling) is fine, but it then has to look like part of her, not a copy of the word-game flower.
7. **A11y is OK.** It has the label "Petals, 3 of 5", meaning is carried by shape (filled vs dashed) as well as colour, and it takes no taps.

## Options (parts/crown-options.html)
- **A. Halo arc**: 5 small petals fanned over her head. Better than the crown, but it still floats, looks like confetti or flames, the left petal touches the panel, and the ghosts vanish in dark rain. Not recommended.
- **B. Petal chip**: a glass pill under her with a heart, 5 petals and "Love petals". It gives the clearest exact count, stays out of the rain, and reads well in light and dark. It is a HUD, though, not part of her.
- **C. Blush on her own head**: 5 small pink petals under her yellow centre. Recommended. It is unmistakably Daisy's: love colours her, and with fewer petals she fades back to a plain white daisy. It never crowds the cloud, rain or panel, and the symmetric keep order keeps 3 and 1 balanced.

## Recommendation: C, with the exact count in the panel
- Remove `.crown` (lines 42, 108, 168-174 and the call in `daisy(crown(...))`). Add `blush(n,mode)` from crown-options.html inside `.plant` so it sways with her.
- Keep order `[2,1,3,0,4]` (centre-top stays longest).
- Fall: play once per day, 3.4 s, pivot at the petal's centre, ending at the ground rest petal. Do not use `infinite`.
- Regrow: as now (0.3 s stagger, spring from the hub).
- Panel Love key: swap the single petal icon for a row of 5 petals (filled or dashed ghosts at 1.6 px with a 10% fill so they show in dark). Keep the text "Love keeps her petals." The panel row holds the exact count; Daisy's head holds the feeling.
- VoiceOver: add "pink petals, 3 of 5" to the plant label, e.g. "Daisy, 3 of 5 love petals". Keep the panel row's label as well.
- Swift: draw it as an overlay above `plant_daisy` and redraw her centre disc (#F2B632 plus #D48E1B dots) on top. The art file is not changed. The owner should confirm that a pink-hearted Daisy is acceptable as "her own art".
- Reduce Motion: no fall. The petal just fades out and the rest petal shows on the ground.

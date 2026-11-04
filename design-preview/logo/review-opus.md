# T-F logo review (opus)

Viewed: final 320/120 light, dark and solo; A 320/120 light and dark; b/png/wordmark-320; Home and Onboarding mocks for final and A at 390 px; icon 60/29 next to current 60/29.

## 1. Wordmark: ship a hybrid, "B uncut"
The PM is right. In final at 320 the cut leaves a top tab and two bottom tabs, so each O reads as an o with blobs. At Home size (about 172 pt) it reads as "WordFlora" with some orange smudges. The pre-refinement b/png/wordmark-320 is the best of the three: you see a true o and a whole flower. A reads as flowers, but at 22 pt the small bloom with a light centre reads as a symbol, "W✿rd". That is a poor trade in a word app where children are learning letters.

Spec:
- Final's ring-o, A's ellipse petals and the current colours.
- **No petal may be cut by a neighbouring letter.** Only the 36-unit gap around each o's own ring stays.
- Reach 1.40x (not 1.55x), so less side bearing is needed.
- Add side bearing to each o until every petal keeps at least 90% of its area outside the gap. Expect about +70 to +90 units on each side. Then pull W–o and o–r/o–d back with kerning until the measured x-height clearance is within 15% of the r–d clearance, instead of the current 1%. Some extra air around the flowers is the price of having flowers.
- Acceptance: at 120 px, all five petals on the Flora O can be counted.

## 2. 120 px solo in the nav bar
Yes for legibility: it reads cleanly as "WordFlora". In final, though, the single bloom is a pink speck. Rebuild it with the uncut spec above. If five petals still can't be counted at 120, that's fine. Below 130 pt the mark is a label, not an illustration.

## 3. Icon: do not replace it now
I agree with the critic. Reasons:
- The icon is derived from the wordmark's petal geometry, and that geometry is still changing (see point 1). Locking the icon now means redoing it.
- At 29 px the candidate reads as a cream "0" or a button inside an amber scallop. The current smiling daisy is warmer and clearer for kids.
- Changing an icon is costly for recognition and should happen once.

Regenerate the icon from the "B uncut" blossom after the wordmark ships, then decide.

## 4. Accessibility
- Contrast: letters pass. Light Flora green is 4.98:1, the tightest pair; don't let it get any lighter. Petals are decorative and need no ratio.
- Colour blindness: under deuteranopia the pink Flora petals next to the green Flora letters collapse toward olive. The gap and the petal shape carry the read, so it's acceptable. Keep the gap at 36 or more.
- Reduce Transparency: irrelevant. Everything is opaque paths with no blur or material. Mono uses fill-opacity on a solid background only.
- VoiceOver: `.accessibilityLabel("WordFlora")` is correct. Also add `.accessibilityAddTraits(.isHeader)` on Home and treat the image as one element. Never split it into letter images, or VoiceOver will read "W, flower, r, d".
- Increase Contrast: optionally swap to the mono variant with petals at 0.6 opacity.

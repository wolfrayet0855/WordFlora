# Review-UX: life stats mockup

Not rendered (no browser tool used). Source read only: lifestats.html, wake-options.html, decision.md. Layout numbers are from CSS, so confirm by eye on localhost.

## Blocker
1. **Petal count differs between pages.** The crown has 5 petals; wake-options shows 8 petal dots (and "3 of 8" next to 3 of 5 hearts). Petals are pink on one page and white on the other. Fix: wake-options `petals()` uses 5 dots, pink `--petal`, matching the crown. Success card shows "3 of 5 petals" only for VoiceOver.
2. **Banned words in shipped copy.** "Waiting for sun" (day 4 Sunshine) breaks the rule. Change to "Sun is coming". Captions "Last petal", "two petals left", notes "No petals left", "only with Sound on" are dev text; reword anyway ("Final petal" is still risky, use "One petal stays").
3. **Quiet Garden/Calm exemption is not shown.** Only decision.md has it, and the 72 h rule for under-13/unknown age is missing from the lifestats page, which says 24 h flat. Add frame 11 "Calm or Quiet Garden: no rain, full crown, meters unchanged" and one line in the rule notes: "24 h (13+), 72 h (under 13 or unknown)".

## Important
4. **Reading level.** "Quenched", "Joyful", "Cherished", "Delighted", "Refreshed", "Hopeful" are above grade 3. Use Water: Full / Sipping. Sunshine: Bright / Warming up. Happiness: Happy / Cosy. Love: Loved / Hellos help.
5. **Two five-counts confuse.** Hearts (love) and crown petals (health) both run 0-5 and are not linked on screen. Add a one-line legend under the hearts: "Love grows petals." Or show petals only in the crown and drop the heart count to a single icon.
6. **Tab at the screen edge.** It is 46x92 pt (OK), but x=0 collides with the iOS back swipe. Inset it 4 pt, handle with `gestureExclusion`, or put the swipe-right-to-open on the panel too. The minimise button is 40 wide; make it 44x44. Tab always shows the same filled heart; add a small dot when petals are falling. Rename its label to "Show Life panel" (match the visible word "Life"), add `aria-expanded`, and remember the choice.
7. **Tap blocking.** `.crown`, `.cloud`, `.rest`, `.lovefly`, `.badge` have no `pointer-events:none`, so a tap on the crown or resting petal does not reach Daisy. Add `pointer-events:none` to all of them; in SwiftUI use `allowsHitTesting(false)`. The 220 pt plant box (x 85-305) also runs under the 110 pt panel (x 8-118): check the leaves are not clipped; if so shrink the panel to 96 pt.
8. **Accessibility-size sheet drops the actions** and the hint. Fix: keep Water/Feed/Sun/Repot in a pinned bottom bar (safeAreaInset) as a 2x2 grid, min 64 pt tall, outside the sheet. The sheet gets a small detent (header, hearts) and a large detent for the rest; background stays interactive so Daisy remains tappable. Keep the hint line.
9. **Meter fills fail 3:1.** Leaf and sun fills on white are about 2:1. Add a 1.5 pt darker outline on the fill, or darker tones (`#5E8F1F`, `#B87F00`) for the light theme. Ghost petals at 60% opacity are faint; use full opacity.
10. **VoiceOver order.** Put the wake card before the panel in seed state, and the panel after the plant and mood. Announce once when rain starts ("A rainy day for Daisy"), as the weather is hidden.
11. **Copy mismatch.** "Napping safely" vs wake-options "resting in her seed"; wake card sub "Play a little wake-up game" vs sheet "Pick one you like". Use "resting" and one subtitle. Growth stage "Seed" clashes with the seed-in-pot state; rename to "Tiny".
12. **Seed art differs** (wake-options pot vs seed-pot.svg: seed colour, no face). Reuse parts/seed-pot.svg.

## Polish
- Panel text is 11.5-12.5 px fixed; use scaled text styles in the app.
- Reduce Motion: add a cross-fade (no slide) for panel collapse.
- Bottom inset 30 pt: use the safe area instead.

## Responses
review-art.md and review-motion.md were not present when I finished. I did not respond to them.

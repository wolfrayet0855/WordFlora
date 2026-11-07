# Frost & Lantern art: visual review

Reviewed from rasterised `review-light.svg`, `review-dark.svg`, `pack-card-*.svg`, `scene-*.svg` (lower half cropped to see it), badges t1 to t3 and `seasons-row-glyph.svg`. Art in `design-preview/frost-lantern/`. Nothing was edited. Not compared pixel for pixel against the in-app Components (not rendered here). The pots and badges follow the documented PotPainter and BadgeArt rules.

Limits: no simulator or build, so the 24 pt checks come from the sheet's 22 and 28 pt rows, and colour-blind checks are by eye plus the spec's own table.

## What works

- **Pots.** The three are distinct by hue (pale blue, red, indigo), by pattern (fern fronds, lanterns, snowflakes) and by silhouette tone. They hold at 28 pt and 140 pt, in light and dark, and match the flat, no-outline pot style with rim, shine and shade strip.
- **Not-owned outlines.** The dashed outlines read clearly in both modes.
- **Pack card.** Balanced: snowdrop left, lantern pot centre, hellebore right, robin on the right end of the shelf. No text in the art. The dark card is good: the lantern halos glow and the pots pop.
- **Plants and birds.** Snowdrop and hellebore are recognisable and calm, with consistent edge strokes and palette. Robin and wren are recognisable by silhouette and colour. The robin's orange breast against brown is not hue-only, because the breast is also much lighter than the body.

## Must-fix

1. **Seasons glyph is not legible at 22 to 28 pt.** File: `seasons-row-glyph.svg`. In template (single colour) render the lantern is a heavy blob with a cross through it and a separate asterisk. It reads like a "0*" or a Venus symbol, not a lantern or a season. Fix: draw it as a plain outline lantern (about 2 pt stroke, open body, no solid fill), with a larger, thinner snowflake overlapping the top right. Or drop the snowflake and use the lantern alone. Re-check at 22 pt.

## Should-fix

2. **Dark scene snowbank is too bright.** File: `scene-dark.svg`. `snowDark #9AA7BC` fills about a third of the screen and glows against the night sky. It fights the calm tone and the dark cards. Fix: darken the foreground bank to about `#5E6C86` and the mid bank to about `#4A5873`. Keep the fence and lanterns as the brightest things.
3. **Dark scene lantern string disappears.** File: `scene-dark.svg`. The string between the posts is nearly the sky colour, so only the right segment shows. Fix: use a lighter string in dark mode, for example `#8C7A6B`, or one colour for the string in both modes.
4. **Scene snowdrops are lost on snow.** Files: `scene-light.svg` and `scene-dark.svg`. The white-headed snowdrops at about 30 pt sit on white snow with no contrast, in light mode in particular. Fix: use the `FL.snowShade` blue-grey for a stronger edge, or scale the clumps up about 1.4 times, or put the green stems against the darker hill.
5. **Right fir overlaps the right lamp post.** File: `scene-light.svg`. A fir trunk shows through behind the post and lantern, which is busy. Fix: move the fir about 25 pt right, or hide the trunk behind the hill.
6. **Badge tier pips are too small.** Files: `badge_lantern_keeper_t1.svg` to `t3.svg`. At 44 pt the 1, 2 or 3 pips at the bottom are close to invisible, so tiers rely on bronze, silver and gold frame colour only. Fix: enlarge the pips about 1.5 times, or add a tier mark to the snowflake, such as 1, 2 or 3 arms or sizes. This also helps colour-blind users.

## Nice

7. **Badge composition is off centre.** The lantern is left of centre and the snowflake sits top right, so the badge looks lopsided. Nudge the lantern about 6 units right, or enlarge the snowflake.
8. **Frosted glass is the faintest pot.** In the light 28 pt row it is pale on cream. Consider a slightly deeper rim, `#4F86A8`.
9. **Wren badge circle (the sticker).** The wren is a brown bird on a tan disc and is low contrast. Use a slightly cooler disc such as `#E6EAF0`.

## Not found

No clipped or cut-off art in the pots, pack card or visitors. No text in the art.

# Home v2 colour layer: critic review

Method: rendered all 3 states x light/dark x cards 0/1 at 390 pt (headless Chromium), ran `?measure=1`, computed WCAG contrast and Machado CVD (severity 1) myself.

## Numbers
- Text passes AA everywhere. Worst: tagline on wash top light 5.77 (`#2C3E2C`@82% on `#DCEBF6`). Labels 7.4 to 10.0. Play ink 6.5 (light, on `#E8A838`) and 6.96 (dark).
- Icons pass 3:1. Worst: Garden light `#2E7D32` on `#E3F1DD` 4.37, Bloom sun `#F5A0B0` on sun disc 3.66 (dark).
- Wrapping: at 390 pt nothing wraps. In large text only the tagline and "Keep your garden safe" wrap, which is fine.
- CVD: in deuteranopia the Levels/Visitors fills merge (dE 0.9 light, 1.5 dark), and so do Garden/Shed (2.2). The icons and labels are all different, so meaning still comes through.

## Blocker
None.

## Important
1. `.hero .gd svg` uses `--accent-text` `#7A4A00`, so the leaf looks brown and dead next to the green Garden leaf. Use `#2E7D32` / `#81C784` (successText; 4.21 on the wash, passes).
2. The page overrides `--accent-text:#7A4A00` and `--ok:#2E6B30/#8FD492`, but these colours are not assets. Use the existing `accentText #8A5A00` (5.54 on bg, 4.87 on wash) and `successText #2E7D32/#81C784`, or add the assets on purpose. Don't let them drift.
3. In large text, the icons inside `.play svg`, `.hero .gd svg`, `.daily .sun`, `.icon-btn svg` and `.note svg.lead` are fixed px and stay tiny next to 1.9x text. Size them in rem, which maps to `@ScaledMetric` in SwiftUI.
4. `.tile.locked` dashed border is 2.35:1 in light. Use `color-mix(... var(--text) 60%)` = `#7E877B` on `#F1EEE6`, which gives 3.35.
5. Asset count: there are about 15 new colorsets. Fold the hero wash into existing tints: `--wash-top: var(--levels-bg)` (`#DFEDF8`/`#2A4358`) and `--wash-mid: var(--garden-bg)` (`#E3F1DD`/`#2F4F30`). Use a flat `appAccent` for Play, or one new `playTop` asset. Model the tiles as a `TileTint` enum with `fill`/`icon` asset pairs. Remove the unused `--ink-t`.

## Polish
6. Light mode shows 8 hues on one screen (sky, gold, rose, leaf, sky, clay, lilac, gold), which is on the loud edge for adults. Drop the coloured tile shadow `0 4px 12px ... 16%` in light and keep only the 30% border, which matches iOS grouped-cell restraint.
7. `.daily` border at 55% `#F2788A` plus glow competes with Play. Reduce it to 35% with no glow.
8. Radii: Play is 18 but cards are 20. Use 20 continuous (`RoundedRectangle(cornerRadius:20, style:.continuous)`), which matches lifestats at 20.
9. `#bug` inner stroke `var(--surface)` draws a white seam on lilac. Use `var(--t-bg, var(--surface))`; in SwiftUI just use `ladybug.fill`.
10. Garden green `#2E7D32` is bluer than the Life screens' leaf `#5E8F1F`. That's acceptable, and the hues otherwise match the Life palette (clay `#C8734A`, sky `#4C93D6`, lilac `#A98BE2`, gold `#B87F00`).
11. Optional CVD fix: Visitors fill `#E9E2F8` with Levels teal `#DDF0EE` gives deut dE 8.2, but teal then crowds Garden. Not recommended.

## What works
Locked tiles read clearly as "not open yet" without looking scary: grey fill, dashed outline, lock icon and hint. The hierarchy Play > Bloom > Explore holds. Dark mode is calm and well balanced.

**Verdict: approve with changes (1-5).**

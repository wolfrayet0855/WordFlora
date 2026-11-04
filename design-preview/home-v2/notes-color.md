# Home v2 colour layer (values live in the "COLOUR LAYER" style block of index.html)

## Existing tokens reused (no new asset)
appBackground FAF7F0/1A2E1A; appSurface FFFFFF/2C3E2C; appPrimaryText 2C3E2C/D4EDD4 (all labels); ink 1F3320/1A2E1A (Play text); appAccent E8A838/F0C060 (Play); accentText 8A5A00/F0C060 (Flora wordmark, Learn more, Badges icon, note icons); successText 2E7D32/81C784 (Garden icon, Garden Days leaf, done check); petalRose F2788A (Daily Bloom border at 40%).
The page no longer overrides accent-text or ok: previous 7A4A00 and 2E6B30/8FD492 are gone.

## New assets: 10 colorsets (light / dark)
| Asset | Light | Dark |
|---|---|---|
| tileGardenFill | E3F1DD | 2F4F30 |
| tileLevelsFill | DFEDF8 | 2A4358 |
| tileShedFill | F7E5D8 | 4B3A2D |
| tileVisitorsFill | ECE5F6 | 40395A |
| tileBadgesFill | FBEFCB | 4A4122 |
| tileLevelsIcon | 1F5F8F | 8CC4EC |
| tileShedIcon | 8F4A26 | E8AE88 |
| tileVisitorsIcon | 6A4A9C | CDB8F2 |
| bloomFill | FDE9EE | 4D3039 |
| bloomIcon | B03A55 | F5A0B0 |

Model tiles as a `TileTint` enum with fill/icon pairs (Garden icon = successText, Badges icon = accentText).
Derived, no asset: hero wash = linear gradient tileLevelsFill to tileGardenFill (160deg, fading to appBackground); Play = appAccent with a 20% white top highlight (preview shows F2C25E to E8A838 light, F5CC70 to E8A838 dark; use flat appAccent if preferred); locked fill = appPrimaryText at ~6% over appBackground (preview F1EEE6 / 233823); locked dashed outline = appPrimaryText 60% mixed into the locked fill.
Removed from the first pass: wash-top, wash-mid, playTop, lockFill, ink-t (15 to 10).

Style: tile border = icon colour 30%; light tiles shadow 0 1 2 black 6%, dark tiles keep icon-tinted glow; cards radius 20 continuous (Play too); Daily Bloom shadow is the standard card shadow (no pink glow). Locked tiles: saturate .35, lock icon, dashed outline, hint text. In SwiftUI use `ladybug.fill`; the preview bug seam now uses the tile fill.
Icons size in rem in the preview (Play, leaf, note, sun, chevron, lock, gear), i.e. @ScaledMetric.

## Contrast (WCAG; secondary text approximated as text at 82% over the fill)
Text (4.5 needed): worst 5.82 (hero tagline on levels-tint, light); dark 6.1. Labels 7.4-10.0. Bloom subtitle 5.95 / 6.9. Locked hint 6.0 / 7.4.
Icons and outlines (3.0 needed): worst 4.30 (Garden/successText leaf on levels-tint wash, light) and 4.37 on Garden fill; dark worst 4.57. Locked dashed outline 3.35 light / 4.75 dark.
Colour is never the only signal: icons, labels, lock, dashes and hint text stay. Deuteranopia: Levels/Visitors fills look alike, but icons and labels differ.

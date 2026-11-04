# Logo direction B: ring blooms

Preview: http://localhost:8765/logo/b/index.html

## Idea
Each O in "WordFlora" stays a real letter. The ring is the Nunito Black (wght 900) lowercase "o" outline, so it has exactly the same weight, curve and counter as the other letters. Petals grow from *under* the ring. A clear gap (30 font units, made with an SVG mask rather than a background-coloured stroke) is cut around the ring, so the petals never touch it and the counter stays open.

- **Word O: daisy.** Six rounded petals at 30°, 90°, 150° and so on. One petal points straight up and none point straight sideways, which keeps the W–o and o–r spacing tight. Colour: appAccent amber #E8A838.
- **Flora O: blossom.** Five broad round petals (primrose or blossom shape) with one pointing up. Coral #E0705A. The two shapes and two colours make "a small garden".
- **Leaf on the "l": tried and dropped.** At every size it read as an apostrophe ("Fl'ora"). The `leaf()` helper is still in `build.py` (`with_leaf=True`) if anyone wants to retry it.
- **Letters:** Nunito Black, converted to paths with fontTools, so the SVGs need no web font. "Word" uses appPrimaryText and "Flora" uses wordmarkFlora, the same split as `WordmarkView`. Spacing is the font's own advances. Extra room is added only around the flower O's, the W–o pair is kerned by hand in solo, and there is a small breath at the d|F colour change.

## Variants
| | Twin blooms (recommended) | Solo bloom |
|---|---|---|
| What | both O's flower | only the Flora O flowers |
| Files | wordmark-twin*.svg (also wordmark*.svg) | wordmark-solo*.svg |
| viewBox | 6050 × 1070 units (5.65:1) | 5720 × 1070 (5.35:1) |

**Recommendation: twin blooms.** It is the owner's idea, it is the friendlier of the two for kids, and the 6-petal daisy now stays compact (no sideways petals). Solo is noticeably calmer and reads one notch better at 120 px wide. If the integration needs the mark below about 130 pt wide (a nav bar, a widget), use solo there. At the current Home size (about 172 pt wide) and on Onboarding (about 262 pt), twin reads cleanly.

## Colours and contrast (WCAG, letters vs background)
| Element | Light (#FAF7F0) | Dark (#1A2E1A) |
|---|---|---|
| "Word" letters + Word O ring | #2C3E2C, **10.7:1** | #D4EDD4, **11.6:1** |
| "Flora" letters + Flora O ring | #2A7A38, **5.0:1** | #F0C060, **8.6:1** |
| Word O petals (amber) | #E8A838, 1.95:1 (decorative) | #E8A838, 7.0:1 |
| Flora O petals (coral) | #E0705A, 3.0:1 (decorative) | #E0705A, 4.6:1 |

All letters, including both rings, are at least 4.5:1. The petals are decoration: the word reads fully with them removed, which is exactly what the mono check and the 120 px render show.

Mono: one ink, #2C3E2C (`wordmark-mono.svg`). For a single-colour white version, change the fill.

## Colour-blind check
- **Petal vs ring is a lightness step, not only a hue step.** In light mode the amber petals have relative luminance 0.45 against the 0.04 ink ring (5.5:1), and the coral petals 0.28 against the 0.15 green ring. In dark mode the petals are *darker* than the rings: 0.45 against 0.79, and 0.28 against 0.57.
- **The coral and green pair is the weakest (1.7:1),** and it is the classic red/green confusion. It is covered structurally: the 30-unit gap the colour of the background always outlines the petals, so even with zero colour difference (see mono) the flower shape stays visible. Under deuteranopia simulation the coral turns mustard-brown and the green turns olive, so they remain two different values, and the gap does the rest.
- **Icon:** cream ring (L 0.91), amber petals (0.52) and green background (0.12 to 0.18) form three clearly separate lightness steps. The gradient top was darkened from #679D2C to #558A26 so the top petal keeps contrast with the background. Tinted: white ring, #7A7A7A petals (4.3:1 against the ring and 4.9:1 against black), so iOS's luminance-based tint keeps three levels.

## How it degrades
- **Icon 180 and 60:** crisp. The blossom O is unmistakable.
- **Icon 29:** the ring and counter stay open (the counter is about 4 × 6 px) and the five petals become five warm lobes. It still reads as "a flower with an O in it". The slimmer 6-petal daisy was tested as the icon (`icon-daisy*.svg`) and breaks into dots at 29 px, which is why the icon uses the blossom.
- **Wordmark 120 px wide:** the letters have an x-height of about 10 px and read clearly. The twin daisy becomes a small amber starburst behind the first o, and the blossom keeps its shape. Solo is slightly cleaner here.
- **Wordmark 320 px:** both flowers read as flowers, and the petal gaps are visible.

## Files
- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg`: the recommended (twin) version
- `wordmark-twin{,-dark,-mono}.svg`, `wordmark-solo{,-dark,-mono}.svg`: both variants
- `icon.svg`, `icon-dark.svg`, `icon-tinted.svg`: the blossom O, full-bleed 1024 square (iOS masks the corners)
- `icon-bloom*.svg`, `icon-daisy*.svg`: comparison of the two icon flowers
- `png/`: icon{,-dark,-tinted}-{1024,180,60,29}.png and wordmark*-{320,120}.png
- `build.py`: generates every SVG from Nunito Black (`python build.py Nunito-900.ttf`; needs fontTools)
- `render.py` + `render.html`: PNG renders through headless Chromium (needs the :8765 server and Pillow)

## Integration note
`WordmarkView` can become an `Image("Wordmark")` (an SVG asset with light and dark appearances) with `.accessibilityLabel("WordFlora")`. It should scale with Dynamic Type through a `@ScaledMetric` width (about 172 pt at the .title size). The ring is the real glyph, so the mark lines up with any Nunito text placed beside it, but the app's own text is SF Rounded, not Nunito.

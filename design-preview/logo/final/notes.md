# WordFlora wordmark: final ("B uncut")

Preview: http://localhost:8765/logo/final/index.html. The gallery is at http://localhost:8765/logo/index.html, and the icon candidate (unchanged this round) at http://localhost:8765/logo/icon/index.html.

Built by `build.py` (fontTools + skia-pathops, from Nunito instanced at wght 900) and rendered by `render.py` (headless Chromium, needs the :8765 server). The build prints the measurements below.

## Review verdicts
- **Critic (`../critic.md`).** Picked direction B: the ring-O concept plus the icon, refined with A's ellipse petals, colour logic and kerning discipline. The first refinement tucked the petals behind neighbouring letters.
- **Review team (`../review-opus.md`, `../review-sonnet.md`).** Ship "B uncut". No petal may be cut by a neighbouring letter, and only the 36-unit gap around each o's own ring stays. Add side bearing until the petals are clear, and accept the extra air around the flowers. Use a deeper rose for light mode. No icon swap this round.

## Construction
- **Ring.** Nunito Black's own "o", the same weight as the other letters.
- **Petals.** Five of A's ellipse petals: half-length 0.45·T, half-width 0.387·T, centre at T − half-length, where T is the tip radius. The Word O has one petal pointing up. The Flora O is turned 36°.
- **Cuts.** Only one: the o's own ring dilated by 36, plus its counter, so the hole stays empty. There are no masks, strokes or filters. Mono uses `fill-opacity` on the petals.
- **Reach: 1.75× the ring radius. This deviates from the review spec's 1.40×.** At 1.40× only about 70 units of each petal show outside the gap, roughly 1.5 px at 120 px wide. The five Flora petals cannot be counted, so the acceptance check fails (`png/spec-k140-320.png`, `png/spec-k140-120.png`). I compared 1.60×, 1.75× and 1.90×:
  - 1.60× still merges into a pink halo at 120 px.
  - 1.75× is the smallest reach where all five can be counted.
  - 1.90× adds even more air.

  `K=1.40 python build.py …` reproduces the spec version.

## Measured side bearings and kerning (font units, upm 1000)
**Base spacing.** Nunito's own advances, with W–o kerned −40 and +20 at d|F.

**Petal clearance rule.** The extra side bearing on each flower O was found by search in 5-unit steps until two conditions held for every petal:
1. it overlaps no neighbouring letter at all;
2. at least 90% of its visible area stays clear of the neighbour dilated by 36.

**Kerning back.** After that, `balance()` tries to kern back toward the r–d clearance. It only moves a letter while the petals stay clear, so in practice nothing could be kerned back.

| | Before the o | After the o |
|---|---|---|
| Word O (twin) | **+60** | **+100** |
| Flora O (twin and solo) | **+140** | **+100** |

Total width: twin 5695 u, solo 5535 u.

**Minimum petal clearance (share of each petal clear of the neighbour plus 36 u):**

| Petal side | Clearance |
|---|---|
| Word O, W side | 0.914 |
| Word O, r side | 0.918 |
| Flora O, l side | 0.940 |
| Flora O, r side | 0.918 |

No petal overlaps a neighbouring letter anywhere.

**Letter clearance across the x-height band (mean horizontal gap, relative to r–d at 203 u):**

| Pair | Twin | Solo |
|---|---|---|
| W–o | 262 (**+29%**) | 202 (−1%) |
| o–r (Word) | 221 (+9%) | 121 (−41%, Nunito native) |
| l–o | 295 (**+45%**) | 295 (+45%) |
| o–r (Flora) | 221 (+9%) | 221 (+9%) |
| d–F | 137 (−33%, Nunito native + 20) | same |

**The ±15% clearance target is met on the r side of both O's, but not on the W–o side (+29%) or l–o side (+45%).** Kerning those back would push the petals into the W and the l, which breaks the "no petal cut or touched" rule. The review accepted "air around the flowers", so petal clearance won. The l–o gap is the largest because, with the Flora O turned 36°, its upper-left petal (324°) runs into the l's tall stem.

## Colours and contrast (WCAG)
| Pair | Colours | Ratio |
|---|---|---|
| "Word" letters and ring, light | #2C3E2C on #FAF7F0 | **10.71** |
| "Flora" letters and ring, light | #2A7A38 on #FAF7F0 | **4.98** (unchanged) |
| "Word" letters and ring, dark | #D4EDD4 on #1A2E1A | **11.63** |
| "Flora" letters and ring, dark | #F0C060 on #1A2E1A | **8.56** |
| Word petals, light, on bg / on ring | #E0962A | 2.29 / 4.67 |
| **Flora petals, light, on bg / on ring** | **#E27D8A** | **2.61** (target ≥ 2.5) / 1.91 |
| Word petals, dark, on bg / on ring | #E0962A | 5.91 / 1.97 |
| Flora petals, dark, on bg / on ring | #E25D78 | 4.19 / 2.04 |
| Mono ink on white | #2C3E2C | 11.46 |
| Mono petals at 0.45 (≈#A0A8A0) on white | | 2.44 |
| Mono-solid petals at 0.6 (≈#808B80), on white / on ink | | 3.55 / 3.23 |

The rose #E27D8A has luminance 0.33, against 0.15 for the green ring and 0.93 for the cream background. The bloom keeps its shape by lightness alone, and the 36-unit gap separates the petals from the ring. Every letter and ring is at least 4.5:1.

## Acceptance checks (by eye, on the PNGs in `png/`)
- **120 px:** all five Flora petals can be counted: two upper, two side, one lower. Checked on `wordmark-120.png` and `wordmark-dark-120.png` at 4× zoom. **Pass.**
- **320 px:** each O reads as the letter (open counter, full ring weight) and as a whole five-petal flower, in light, dark and mono. **Pass.**
- **No petal is cut by a neighbouring letter:** confirmed by geometry, with zero overlap area. **Pass.**
- **Plain filled paths only:** `grep -c "mask\|stroke"` returns 0 for every SVG. **Pass.**

## Files
- `wordmark.svg` / `wordmark-dark.svg`: twin, 130 pt wide and up (Home about 172 pt, Onboarding about 262 pt).
- `wordmark-solo.svg` / `wordmark-solo-dark.svg`: below 130 pt.
- `wordmark-mono.svg` (petals at 0.45), `wordmark-mono-solid.svg` (petals at 0.6, for Increase Contrast), `wordmark-solo-mono.svg`.
- `png/<name>-320.png` and `png/<name>-120.png` for each, plus `png/spec-k140-*.png`.
- `build.py`, `render.py`, `render.html`, `index.html`.
- The icon candidate in `../icon/` was **not** rebuilt this round. `build.py` only rewrites it when `ICON=1` is set.

## Integration note for `WordmarkView`
- **Asset sets.** "Wordmark" uses `wordmark.svg` for Any and `wordmark-dark.svg` for Dark. "WordmarkSolo" uses the two solo files. For Increase Contrast, add a High Contrast appearance using `wordmark-mono-solid.svg` if wanted. Set Preserve Vector Data on and Single Scale.
- **View.**
  ```swift
  struct WordmarkView: View {
      var style: Font.TextStyle = .largeTitle
      @ScaledMetric private var width: CGFloat
      init(style: Font.TextStyle = .largeTitle) {
          self.style = style
          _width = ScaledMetric(wrappedValue: style == .title ? 172 : 210, relativeTo: style)
      }
      var body: some View {
          Image(width < 130 ? "WordmarkSolo" : "Wordmark")
              .resizable().scaledToFit().frame(width: width)
              .accessibilityLabel("WordFlora")
      }
  }
  ```
  Onboarding keeps `.scaleEffect(1.25)`, which gives about 262 pt. The aspect ratio is now about 5.9:1, so the mark is about 29 pt tall at 172 pt wide.
- **Labels and tinting.** Keep `.accessibilityLabel("WordFlora")`. Do not tint the image with `.foregroundStyle`, because the colours are baked into each appearance.

## Remaining weaknesses
- **Uneven air.** W–o (+29%) and l–o (+45%) are visibly airier than the other pairs, so the word reads a little as "W·o·rd Fl·o·ra" at large sizes.
- **Reach.** The reach is 1.75×, not the specified 1.40×. This needs the review team's sign-off.
- **Pale petals.** The light-mode petals are still pale at 120 px: the amber is 2.29:1, and the rose is 2.61:1 on cream.
- **Mono.** Mono relies on `fill-opacity`.

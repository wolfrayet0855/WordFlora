# Celebrations mockup

These are flower-petal celebrations for WordFlora: the landing intro, plus petal confetti in four intensities. Every motion is a closed-form function of time `t` drawn on a `<canvas>`, the same model as SwiftUI `TimelineView(.animation)` + `Canvas`. Any frame can be rendered on its own, and the Swift port is a line-by-line copy of `pose(t)`.

## Files
- `intro.html`. Landing intro. Query: `?theme=light|dark`, `&rm=1` (Reduce Motion), `&t=1.2` (freeze one frame). Live, a tap skips to the end.
- `confetti.html?level=small|medium|large|badge`. Query: `&calm=1` (Calm / Quiet Garden), `&rm=1`, `&theme=`, `&t=`.
- `engine.js`. Palette, `PetalShape` bezier, five-petal blossom, leaf, deterministic RNG, easing.
- `strip.html`, `render.sh`. Frame strips rendered to `shots/*.png` by headless Chromium from `file://` (no server). Run `sh render.sh [prefix]`.
- `build-data.mjs`. Inlines `../logo/final/wordmark*.svg` into `wordmark-data.js`, so each O's petals can be animated.

## Art
- **Petal.** `PetalShape` from `FlowerView.swift`, re-based to base (0,0) and tip (0,-54): `M0 0 C-19 -12 -17 -44 0 -54 C17 -44 19 -12 0 0 Z`. Fill and 2 pt stroke, as in FlowerView.
- **Palette.** FlowerView rose `#F2788A/#D9566C`, apricot `#E9A36C/#CF8247`, lilac `#C7A9B0/#A98791`, sky `#8EA6C4/#6E87A8`, plus the wordmark's marigold `#F5C858/#E0962A` and rose `#E27D8A/#C95F6E`. White is dropped, because it is invisible on `#FAF7F0`.
- **Blossom.** Five petals (the wordmark's O flower) with centre `#E8A838/#F5C858`. `open` goes from 0 (closed bud: petals at ±0.18 rad, 75 % length) to 1 (72° apart).
- **Tumble.** Horizontal scale = `cos(phase)`, clamped to at least 0.35 so a petal seen edge-on never becomes a sliver. When the cos is negative (the petal's back), a darker tint is drawn.

## A. Landing intro (3.5 s, then hand-off)
| t (s) | What happens |
|---|---|
| 0.0-0.8 | Wordmark fades in, rises 14 pt and scales 0.94 to 1 (ease-out cubic). |
| 0.55-1.2 | Each O flower opens from a bud: scale 0.15 to 1, rotate ∓72° to 0 (ease-out back). |
| 0.6-1.2 | Tagline fades in and rises 6 pt. |
| ~0-2.0 | 41 petals fall (7 heaps × 5, plus 6 loose). Each fall takes 0.95-1.3 s. The fall decelerates as `1-(1-u)^1.35`. Sway is 14-32 pt and dies out on landing. In the last 28 % of the fall, the petal turns to its resting angle (on its side, ±(72-98)°). 40 % of petals fall behind the wordmark at 85 % opacity. |
| on landing | Settle: bounce `2.5·e^(-10τ)·\|sin 14τ\|` and rock `0.22·e^(-7τ)·sin 16τ`. The five petals of a heap pile up to 4.5 pt high. |
| 1.15-1.75 | Heaps finish landing from the middle outwards (0.15 s apart). |
| tb = last landing + 0.12 | Stem grows 50-80 pt over 0.5 s (ease-out cubic), with a soft ground shadow. Leaves grow over tb+0.22 to tb+0.68. |
| tb+0.05 to tb+0.5 | Each of the heap's petals travels from its resting pose up to the rising stem top and becomes the closed bud (ease-in-out cubic). |
| tb+0.5 to tb+0.95 | The bud opens into a five-petal flower (ease-out back). The centre pops at tb+0.62 to tb+0.85. A gentle sway of 0.035 rad follows. |
| 1.8-3.2 | Wordmark settles 18 pt upward. |
| 2.6-3.2 | Loose petals fade out ("soak into the soil"). |
| 3.5-3.9 | Cross-fade to the next screen (Home; on first launch, the age question). |

- **Tap to skip.** Jump to the final frame, then do the 0.4 s hand-off.
- **Reduce Motion.** The wordmark, tagline and bloomed row fade in together over 0.6 s (opacity only), and the hand-off starts at 2.0 s.
- **Particles.** 41 petals plus 7 flowers, far under the 120 cap.

## B. Petal confetti
| Level | Use | Particles | Duration | Shape of motion |
|---|---|---|---|---|
| small | correct letter | 14 (30 % blossoms) | 0.8 s | Puff from the revealed tile: fan of 130°, v 150-250, drag k 4.2, gravity 300. The tile pops 1.1× and gets a marigold wash. |
| medium | level up, wake success, butterfly game end | 40 (25 % blossoms) | 1.9 s | Fan of 150° from the card top, v 240-470, k 2.6, g 230. |
| large | plant earned, Daily Bloom | 96 (80 from two side cannons in waves at 0 and 0.45 s, plus 16 drifting) | 2.8 s | Cannons from the lower corners aimed up and in, v 650-1000, k 1.7, g 210 (terminal speed 124 pt/s). The earned card fades in at 0.7 s above the particles, so its text is never covered. |
| badge | any badge unlock | 28 | 2.6 s | Badge pops (scale 0.3 to 1, ease-out back, 0.05-0.5 s) with a soft radial halo. Petals spiral from r 36 to r 95-140 over 1.5 s while turning 2.4 rad, then drift down. The title sits on a scrim above the particle layer. |
| calm | Calm mode, Quiet Garden, Low Power (replaces large and medium) | 24 | 2.8 s | Slow drift from the top, 110-160 pt/s, sway 12-32 pt, no burst. |
| rm | Reduce Motion (any level) | 12, static | 1.4 s | A still arc of petals and blossoms fades in (0-0.3 s) and out (0.9-1.4 s). Opacity only. For large, the dim is done by 0.15 s and the card by 0.4 s. |

- **Fade.** Each particle fades out over the last 32 % of its life.
- **Motion maths.** Position is closed-form with linear drag:
  - `x = ox + vx(1-e^(-kt))/k + sway·sin(ωt+φ)(1-e^(-kt))`
  - `y = oy + vy(1-e^(-kt))/k + (g/k)(t-(1-e^(-kt))/k)`
- **No flashing.** No strobe, no colour cycling, no full-screen white.

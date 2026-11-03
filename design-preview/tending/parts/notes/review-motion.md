# Review-Motion: weather, petals, seed, panel

Not rendered: no browser tool available. Read lifestats.html and parts/weather.js/.html only. Verify the items marked (check) by eye.

## Blocker
None. Flash safety passes by arithmetic: one flash per 8 s or more, peak 16% white (10% dark) moves relative luminance by well under 0.1, so WCAG 2.3.1 is met even full-screen.

## Important
1. **Petal fall pivots on the wrong point (check).** `.fall` (L42-43) has no `transform-origin`, so with `transform-box:view-box` it rotates about the viewBox corner. A 85deg end rotation swings the petal about 40 px left of the crown, differently per slot. Fix: `.fall{transform-box:fill-box;transform-origin:50% 50%}`. Also use `animation-timing-function:linear` per keyframe or a soft cubic-bezier: per-segment `ease-in` stalls at every waypoint.
2. **Regrowth is not one-by-one.** `.grow` (L44-45) animates a single slot. No 0.3 s spacing exists. Fix: render slots 0..n-1 with `style="--i:k"` and `animation-delay:calc(var(--i)*.3s)`, one-shot, with spring overshoot `cubic-bezier(.34,1.56,.64,1)`.
3. **Rain hides behind Daisy.** Canvas z2 sits under the plant z4 and the panel z8, and the fall band (y 186-506, x 134-338) overlaps her body. The near layer should draw in front. Fix: a second small canvas at z5 for layer 3 only, or move to the cloud-edge columns.
4. **Splashes saturate from day 3.** `spl.length<18` (L204) caps splashes at 18. Impact rate is about 60/s on day 3 and 120/s on day 7, so a 0.4 s life wants 24-48. Days 3 to 7 look the same. Fix: cap = 4 + n*0.5, and spawn splashes for the near layer first.
5. **Reduced-motion leaks.** A flash in progress keeps playing when RM is toggled. Add `.still .flash,.still .bolt{display:none}` (L62-63). There is no CSS `@media (prefers-reduced-motion)` fallback, so animations run until JS loads. Mirror `.still` rules in CSS.
6. **Force path breaks the 8 s rule.** `flash(w,true)` (L220) skips the guard, and a restart mid-animation jumps from .16 to 0. Keep a 1 s minimum even when forced and let the model enforce 8 s. Also skip flashes in Calm/Quiet Garden, not just sound and haptic.
7. **Perf.** (a) `createLinearGradient` per drop per frame (L206): use solid `rgba` per layer, batch one path per layer. (b) `getComputedStyle` per frame per canvas (L202): cache on theme change. (c) Canvas is full 390x844 at dpr 2 (about 1.3 MP x 4 canvases): size to the rain band (390x330). (d) No IntersectionObserver, so offscreen phones keep drawing; `document.hidden` returns but keeps rAF alive. Pause on hidden/offscreen and reset `last`.
8. **Panel min/max has no animation (L229-231).** `outerHTML` swap is instant, and the sheet's `.min` does nothing. Fix: FLIP, scale 0.2 to 1 from `transform-origin:0 50%`, 240 ms spring, content fade; RM gets an opacity-only fade.
9. **weather.html links `weather.css`, which does not exist.** Standalone demo is unstyled.

## Polish
- Flash ramp is 150 ms (L30), not "slow". Use `fl` at 25%/ease-in-out over 1.4 s. Bolt peaks at .5 (L31), spec says 28%.
- Drop counts round to 11/31 on days 1/3 (L189 shares). Make layer 3 absorb the remainder.
- Far layer length 10 px but travel per frame 14 px: dashes. Set len = speed/30.
- `z` glyphs only bob; add a slow x drift and fade-out cycle. Breathing (4 s, 1.04/1.06) is calm and fine.
- Low Power Mode: 12 drops, 15 fps, no flash.

## SwiftUI mapping
- Rain: `TimelineView(.animation(minimumInterval:1/30, paused:))` plus `Canvas`, stateless (position = f(t, seed)), one path per layer. Pause on `scenePhase`, offscreen and Reduce Motion. Cost S to M, about 1.5 days.
- Flash: `keyframeAnimator` on a white Rectangle. S, 0.5 day.
- Petal fall: `keyframeAnimator` with x/y/rotation tracks, once per day change. S-M, 1 day.
- Regrowth: stagger `.animation(.spring.delay(i*0.3))`. S.
- Seed and z: `phaseAnimator` or `repeatForever`. S.
- Panel: `.transition(.move(edge:.leading).combined(with:.opacity))` or `matchedGeometryEffect`, plus VoiceOver focus. M, 1 day.
- Total about 4-5 days with tests. Cost is negligible (about 60 strokes at 30 fps).

## Responses
review-ux.md: Agree on 7 (`pointer-events:none` on `.crown/.cloud/.rest/.badge/.lovefly`; also add it to the second rain canvas if finding 3 is taken). Agree on its Reduce Motion cross-fade for panel collapse, matching my item 8. Its "Waiting for sun" copy change does not affect motion. review-art.md was not present when I finished.

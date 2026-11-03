# Overseer: life stats and wake mockups

Rendered in headless Chromium (Playwright 1.48) at 390 pt phone width. Light and dark screenshots are in parts/shots/. No page errors.

## Calls (one-line reasons)
- **Crown: 5 pink petals, always pink, on both pages (Art's 8-petal ramp rejected).** Five petals match the five hearts and `LoveEngine.maxPetals = 5`. Fading pink to blue as love drops adds a second "sad" signal that kids would read as sickness. The count already tells the story, and the words label covers colour-blind players. Engine stays at 5.
- **Gold crown hub replaced by a small heart.** This answers Art's "second flower" point. It also shows the link between hearts and petals in the art itself, not just in the text.
- **Hearts and petals linked by one line, "Love keeps her petals."** It sits in the panel's Love block and on the success card (UX 5). I kept both counts and did not collapse hearts to one icon, because hearts are today's love and petals are health.
- **Panel stays 110 pt (UX's 96 pt rejected; Art agreed).** Renders show it clear of Daisy's leaves. It moved up to y 150 so it no longer collides with the hint line.
- **Panel title is now "Life", the same word as the tab.** VoiceOver says "Hide Life panel" / "Show Life panel". This also fixes Art's crowded header.
- **Minimised tab is a plain button, inset 12 pt, with no edge swipe.** That keeps it out of the system back-swipe zone. A pink dot shows when a petal is falling.
- **Rain layers: the far layer is behind Daisy (z2) and the near layers are in front (z5).** Both sit under the hint and the panel, and neither takes taps. Art and Motion agreed; Daisy's art is not shrunk.
- **Large-text layout: Life sheet plus a pinned 2x2 action bar (64 pt).** Actions are never inside the scroll. The sheet collapses to its header, and Daisy and her hint stay visible and tappable above it.
- **The Reduce Motion badge moved under Daisy (y 524), not to Art's y 218.** At y 218 it would sit on the crown.
- **No saturation filter on Daisy.** The owner asked for the app's own art.
- **Rejected: the 72 h rule and Gentle mode for under-13 or unknown age (UX 3).** The owner ruled against it: the same 24 h rule applies at every age.
- **Rejected: redrawing all icons as SF-style monoline (Art polish).** That needs new assets in the app. In the mockup I only swapped the glyph chevrons and ticks for SVGs.

## Fixed
- Reading level: Full/Sipping, Bright/Cloudy/Sun is coming, Happy/Cosy, Loved/Hellos help. Growth stage "Seed" is now "Tiny".
- Banned words removed from all visible text and captions, and the wake-options select label.
- Frame 11 added for Calm and Quiet Garden.
- `pointer-events:none` on the crown, cloud, canvases, badges, rest petal and floating hearts.
- The minimise button is 44x44 pt.
- Light fills now meet 3:1 on white: sun #B87F00 (3.5:1), leaf fill #5E8F1F (3.9:1). Ghost petals are at full opacity.
- Petal fall uses fill-box with the origin at the centre.
- Regrowth: petals come back one by one, 0.3 s apart, with a spring, and there is a Replay button.
- Perf: one path per layer and no gradients. Colours are cached and read again only on theme change. Canvases are sized to the rain band only. Drawing pauses when a phone is off screen or the tab is hidden. 30 fps cap. The splash cap scales with drop count.
- Flash: 1.4 s, peaking at 25%; the bolt peaks at .28. A forced flash still waits 1.4 s. A flash in progress is hidden when Reduce Motion turns on, and a CSS media fallback covers it too.
- The panel shrinks into the tab and the tab fades in, with no outerHTML swap. Focus moves and `inert` is set. With Reduce Motion it fades only.
- Wake options: the 8 white dots are replaced by 5 pink petals, and the seed reuses seed-pot.svg exactly. The seed `id` is now a class, so ids are not duplicated.
- **Wake options never rendered in Chrome.** `const top` clashed with `window.top`. Renamed it.
- Created parts/weather.css. The standalone cloud has no inner strokes, and the bolt sits inside the cloud.

## Not verified
- Safari/WebKit rendering, real iOS VoiceOver, Dynamic Type, and the frame rate on a device.

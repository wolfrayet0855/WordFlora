# Review-Art: lifestats.html (10 frames)

Method: I did NOT render. No headless browser or Swift toolchain was usable here (no Chromium, no playwright, swiftc not found). This is a source read plus computed WCAG ratios. Treat layout findings as geometry from CSS numbers; please eyeball on localhost.

## Verified OK
- Plant: `.plant img` is `../plants/plant_daisy.svg` (220x220, left 50% minus 110, so x-centre 195). Daisy art is centred on x=100/200. Same file as the app. Good.
- Cloud: `.cloud` box 105..285 x 112..213, art inside 10..150 of 160 units, centre x = 195. Not clipped by the phone (overflow:hidden is 105 pt away). Clear of the mood line (ends about y 113, cloud art starts about y 125) and of the panel (cloud art ends about y 191, panel starts 206). Dark cloud has 3.6:1 against the bg.
- Seed pot: unchanged, keep.
- All TEXT passes AA. Lowest: txt2 on the rainy sheen 5.3:1 (light), txt2 on glass 6.8 / 7.1, leaf-ink on leaf 7.1 / 8.7, mood text 8.8 (dark).

## Blocker
- none.

## Important
1. **Crown reads as a second flower and does not match FlowerView.** `.crown` / `crown()` in the script: app FlowerView is 8 petals, and its palette follows count (pink F2788A at 7-8, orange E9A36C at 5-6, mauve C7A9B0 at 3-4, blue 8EA6C4 at 1-2). Mockup uses 5 petals, always pink, plus its own gold centre sitting on top of Daisy's own yellow centre. Pink is the app's "healthy" colour, so it is right for the crown, but not white (white is the plant). Fix: either make the crown 8 petals with the `Palette.for` colours (preferred, one source of truth) or state in the note that 5 is a deliberate simplification. Drop the gold hub circles (or shrink to a small dot) so it does not look like two flowers.
2. **Badge overlaps cloud in frame 9.** `.badge` (top 120, right 14, z 9) sits on the cloud's right lobe (x 246..274, y 125..155). Fix: move badge to `top:218px;left:50%;transform:translateX(-50%)` under the cloud, or centre it under the mood line.
3. **`.min` button is 40x44 pt**, under the 44 pt rule on width, and "Plant life" + button is about 102 px in a 101 px header (`.panel h2`), so it is on the edge of clipping. Fix: `.min{width:44px}` and widen `.panel` to 116, or drop the "Plant life" title to 12px.

## Polish
- Icon set is mixed: fills (drop, leaf, smiley, pot) vs strokes (sun rays, heart), emoji-like faces, and text glyphs for chevrons, ticks and hearts (`&#8249; &#8964; &#10003; &#9829;`). Not SF Symbols weight. Fix: redraw as monoline 2 px or hierarchical SF-style paths; replace glyphs with SVGs. `ic.repot` hard-codes #C8734A/#DD8C63; use a `--clay` token.
- Light-mode non-text contrast: `--sun` 2.2:1 on card, sun bar on `.trk` 1.6:1, `--petal` 2.5:1, hearts 3.7. Words label every state, so not a failure, but darken `--sun` to about #B9810A for the light bar/icon and add a 1 px `--petal-edge` (already there; thicken to 3.5).
- Dark: `.panel`, `.tab`, `.act` rely on a shadow (0.35 black on #1A2E1A), nearly invisible. Add `box-shadow:0 0 0 1px var(--line),var(--shadow)` to match theme.css cards.
- `.m small` 11.5 px and `.path u` 10 px are below the app caption floor (12 pt). Raise to 12.
- Frames 3, 4, 8 apply `filter:saturate(.85/.75)` to Daisy; the owner asked for the app's own art, so the filter alters it. Prefer art swap or leave untouched.
- Cloud fills (#C3CFD6) differ from `parts/cloud.svg` (#B9C6CE). Pick one. Bolt path runs to y 74, below the cloud body (68); shorten to 66.
- Crown does not sway with `.plant.sway`; at 1.2 deg it is small but wrap both in one rotating group.

## Responses
- Motion #3 (rain behind Daisy): agree on the layering. Rain z2 behind the z4 plant is a depth choice, but drops should show in front of the body; do not shrink Daisy's art to fix it.
- Motion #1 (petal pivot): agree; it also affects how the falling pink petal looks next to white daisy petals.
- UX #1 (wake-options 8 white vs crown 5 pink): agree it is a blocker for consistency. I would pick one answer with finding 1 above: app FlowerView is 8 petals with a count-based palette, so make both pages 8 pink-family petals, not 5.
- UX #9 (meter fills fail 3:1): agree, matches my sun 2.2 and bar 1.6 numbers. Use the darker tones UX proposes (#5E8F1F, #B87F00) for light theme only.
- UX #6 and #7: agree on 44 pt min button and pointer-events:none. Not agree that the panel needs to shrink to 96; 110 wide does not touch Daisy's leaves (they reach about x 164).
- UX #12 (seed art differs): agree, reuse seed-pot.svg since the owner loves it.
- UX #2 rewording "Waiting for sun" is copy; no art objection.

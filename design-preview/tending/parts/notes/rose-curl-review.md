# Rose curl: critic review (T-E)

Shots: `shots/rose-curl-critic-light.png`, `-dark.png` (1x, full page), `rose-curl-critic-160-light@2x.png`, `-160-dark@2x.png`, `-320-light@2x.png`. Note: `--headless=old` needs `--virtual-time-budget=3000` with `?focus=`. Without it the page comes out blank.

## Scores

- **(a) Reads as a curl at 160 px: 2/5.** The curled petal is still a full circle with three pale bands (lip, gloss, edge) across its tip. At 160 px it looks like a striped or translucent cap, a glitch or candy stripe, not a rolled tip. The silhouette doesn't change, so the eye finds no curl. The 12-14 degree droop gets lost in the overlapping petals. I agree with the PM.
- **(b) 5 pips identical: 5/5.** No curl key applies at 5. The Swift path is unchanged.
- **(c) Sleepy, not dying: 4/5.** Only rose reds, no grey. The pale pink bands do push "bleached" a little in dark mode.
- **(d) Each step visibly different: 2/5.** 5 to 4 changes. At 3, the wrap stripe on the upper right is barely visible. At 2 and 1 the 8-12 degree nods can't be seen next to "today" at 160 px.
- **(e) Feasibility: 3/5.** `petal()` already applies `transformEffect`, so concatenating a second matrix is one line. But `transformEffect` doesn't animate, so the droop would snap while everything else eases. `thin_svg.py` can emit the sprites with `write_imageset`. `load_rose_rule` only reads the first block, so the `curl` key must go inside rose-rule.md's RULE. Squash plus a per-entry `axis` adds math with nothing to show for it. Simpler: a sprite swap (reusing the `fading` cross-fade) plus `rotationEffect(rotate, anchor: pivot)`, which animates for free. Drop `axis`, `squash` and the precomputed matrix.
- **(f) Size: 5/5.** About 7 KB of sprites and 2.5 KB of manifest, against a 60 KB budget.

## Direction for one revision

1. **Change the silhouette, not the surface.** Make the curled sprite about 30% shorter at the tip. Roll the tip back as one **opaque** tube, 3-4 units thick, in the edge red (#B52C52), with a single thin highlight line along the roll and a crisp dark fold line where it meets the face. Remove the gloss band and the 0.6-opacity shade. Nothing in it should be translucent.
2. **Droop harder.** Rotate 16-18 degrees about the petal base at the first curl stage, and 24-26 degrees at the second. Rotation only, no squash.
3. **Change the schedule so the curl lasts.** Curling at a single pip isn't worth the code. I'm overriding the visual lead's `lose` because the owner's ask (petals that stay get sleepy) needs outer petals still on the head at 3 pips:
   `lose: { 4: [o288, o144], 3: [o0], 2: [o72, o216, wrap], 1: [swirl], 0: [heart] }`
   Resulting keptCounts (0..5): valley ring `[0,0,0,2,3,5]`, petal ring `[0,1,2,5,6,8]` (today it is `[0,1,2,3,6,8]`).
   - At 4: o0, o72 and o216 are curl stage 1 (17 degrees).
   - At 3: o72 and o216 are curl stage 2 (25 degrees, deeper roll) around the closed wrap. That is the clearest "sleepy" image.
   - At 2: three units fall. Check that `maxFallPerPip` is at least 3, or the rest fade.
4. **Drop the wrap curl sprite and the 2 and 1 pip nods.** The wrap curl isn't readable, and the bud nods are invisible. Removing them leaves 3 sprites (o0, o72, o216 stage 1) plus 2 stage-2 sprites, 5 in all.
5. **Leave the fallen petals unchanged.** They already match. A drooped petal's fall should start at angle + rotate, as the notes say.
6. Re-shoot 160 px today-vs-curled in both themes, plus a mid-fall at 3 to 2.

**ONE REVISION**

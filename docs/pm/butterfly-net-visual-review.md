# Butterfly net visual review (2026-11-06)

Reviewed: `butterfly-net-spec.md`, `design-preview/butterfly-net/butterfly-net.png` and `index.html`, the live game screenshot (`integ-shots/butterfly-playing.png`), `WeatherShelterArt.swift` net stroke style. Read-only review.

## Verdict: approve with fixes

The concept is right: a see-through hoop centred on the finger, drawn at exactly the catch radius, with a hello-not-capture animation. Ship after the must fixes.

## What works
- Real visitors are about 57 pt wide on a 390 pt screen. A hoop of 80 to 160 pt across is fair: 1.4x to 2.8x a butterfly. The 40 / 56 / 72 pt Quick wings radii (80 / 112 / 144 across) still hold a visitor with room to spare.
- The 44 pt minimum applies to controls. The hoop is a hit area, not a button, and the smallest hoop is 80 pt across, so there is no 44 pt problem. The finger covers about 40 pt of it, which leaves a ring of about 20 pt visible.
- Fold, lift, free is gentle: the visitor shrinks into the mesh, the net rises 12 pt, the visitor flutters out. This avoids any jar or "caught" look.
- The wood, silver and gold tiers match `tool_net_t1..t3`. Ink outline and sparkle follow the sticker style.
- Reduce Motion is a still frame with a cross-fade. That is right.

## Problems (ranked)

**Must**
1. Tier 2 silver rim `#C5CED6` is nearly invisible on the pale sky (about 1.4:1, see Quick wings frame 2 in the mockup). Use rim `#8D9AA6`, 5 pt, plus a 1 pt ink `#3B3B3B` outline at 70% on all tiers in light mode (not only tier 1 in the evening). Mesh strokes go 1 pt to 1.25 pt at 70% opacity. Today's mesh at 55% vanishes at phone size.
2. Tier 3 gold on the dark evening sky is good, but the handle `#B07A4B` disappears against the green bed (mockup frame 4). Add a 1 pt `#FAF7F0` at 80% outline to the handle and rim in the dark scene for every tier, not only tier 1.
3. The resting net, bottom right, sits on the "said hello" pill and the flowers (frames 1, 4 and Reduce Motion). Move the rest point above the pill (at least 24 pt clear) and draw the resting net at 85% opacity. Keep it clear of the visitors' perch zone.
4. Hoop size: the mockup text says "96 pt across" for radius 48, which is right. Make the spec say plainly that the radius is in points, so the 40 pt hoop is 80 pt across. This avoids a later "40 pt is below 44 pt" misreading.

**Should**
5. Use a hoop fill of `#EAF6F3` at 22% (not 35%) so the butterfly stays vivid through the mesh. In the mockup the visitor looks greyed inside the net (frame 2).
6. The handle at 7 pt `#B07A4B` is fine. Shorten it from 1.1x to 0.9x radius on the tier 1 Quick wings hoop so it does not cover the flowers. Point it to the thumb side, which is the nearer bottom corner (as in the spec).
7. The "Quick wings" chip is clear and fine for teens, but use `#2F6B3A` on `#E3F1E3` (4.5:1 or better). The mockup green on green is weak. Keep the wording neutral. "Easier butterflies" is good for teens. Kids never see it. The footnote is long: cut to "Slower visitors and a bigger net. Rounds are a little shorter." Also check the footnote's claim: the net is not bigger in gentle, it is only more forgiving. Say "a more forgiving net".
8. Dark mode: add a faint rim glow (`#FFF` at 20%, 3 pt blur) instead of a hard outline, so it does not look sticker-on-night.
9. The dotted turn-tell ring in frame 1 is a mockup aid only. Do not ship it. The wings-flared idle frame is enough. The drag trail dashes in frame 2 are also mockup only.

**Nice**
10. Pocket scale 1.08 is subtle. 1.12 reads better at small sizes.
11. Heart on the gentle hello at 14 pt: use 16 pt `#E25B7B` with a white 1 pt outline so it reads on the pill.
12. A tiny 3 pt soft shadow under the resting net, `#000` at 12%, grounds it over the grass.

## Clutter and consistency
The net is one hoop on one scene, which is calm. The old swoosh is removed, which cuts clutter. Weather art uses 3.2 pt round strokes, so the 5 pt rim is slightly heavy. 4 pt would match, but 4 pt hurts legibility at 80 pt. Keep 5 pt, and keep the tier art as the shed icon, so both agree.

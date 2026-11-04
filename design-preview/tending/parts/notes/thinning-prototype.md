# Petal thinning prototype (Opus visual lead)

Page: `parts/thinning.html` (logic in `parts/thinning.js`). Shots: `parts/shots/thin-*.png`, rendered at 390 pt, 2x.

## Technique: drop real petal elements, no masks

The plant SVGs are generated art, so petals are already separate elements. The prototype does what a build script would do:

1. **Find rings.** Two detectors:
   - copies of one element that differ only by `rotate(a)` about the same pivot (Daisy: 16 ellipses about 100,76);
   - five or more same-size, same-fill circles at an equal distance from one centre (the rose). Circles under r 4 are skipped, so seed dots on a disc are not counted as petals.

   Rings that share a pivot form one head. Several heads per plant work too (cherry blossom has 13 heads, Franklin tree 4).
2. **Keep order.** Each ring gets a nested, evenly spread order, made by stepping round the ring by the golden ratio. Gaps never bunch on one side, and a petal that has gone stays gone in every later state.
3. **Share per pip.** Each ring keeps 100, 72, 47, 27, 13 and 0 percent at 5, 4, 3, 2, 1 and 0 pips. This is front-loaded so that 4 pips already looks sparser. Every pip removes at least one petal.
4. **Fall.** The lost petals are cloned in root coordinates and drift down once (3.4 s, staggered 0.26 s). They rest on the ground shadow, alternating sides of the stem. At most 5 petals drift per pip; on big rings the rest fade off the head. Yesterday's petals soak away when today's fall. The fallen layer sits just above the petals and below the disc, so the disc stays in front as they let go.
5. **Regrow.** The petals grow out from the head centre with a small spring (scale 0.05 to 1). Each pip's group starts 0.3 s after the one before, in step with its pip in the row.
6. **Reduce Motion.** The petal fades off the head and fades in where it rests. Regrown petals appear with a 0.25 s fade.

The bare head comes free: the disc is its own element, so 0 pips shows a clean yellow disc for Daisy and a brown seed head for the sunflower. There is no bite and no filler disc. After 0 pips, Daisy crossfades to `seed-pot.svg` (1.2 s later).

## How thin each state looks

- **Daisy, 16 petals**: 16, 11, 7, 4, 2, 0. At 4 she is clearly gappy, at 3 she is a sparse star, at 2 and 1 she is a lonely few petals, and at 0 she is a bare disc on a stem. It reads at tile size in light and dark (`thin-daisy.png`).
- **Sunflower, 44 petals in 2 rings**: both rings thin by the same share, so the gaps cut through both layers. This is the best result of all (`thin-sunflower.png`).
- **Saguaro (droop kind)**: the body bends up to 8.5 degrees at its base, squashes 15 percent and greys (saturation down to 0.35). The sand stays put and the 7-petal flower on top still sheds. It reads as unwell, not thin (`thin-cactus.png`).
- **Rose**: the 5 outer petal circles sit on a dark r26 base disc, so removing them only trims the outline. I gave it droop as well. The falling petals are pink balls and look odd. It needs a hand rule, such as shrinking the base disc as petals go (`thin-rose.png`).

## Wedge mask comparison (`thin-mask-vs-drop.png`)

I built the same states with angular wedges cut out over the head, plus a darker disc painted in to fake a bare head. They are clearly worse:
- the wedges cut the stem top and leaves (the sunflower's leaf is sliced);
- they erase the seed texture under the painted disc;
- the cut-off petal stubs look chewed.

The research note is right to reject masks. Masks looked better in no case.

## Per-plant metadata

- **Petals kind**: none. The centre, radius, petal count and angles are all detected. The script would write them out (head `cx`, `cy`, `R`, the angles, and the keep order) for SwiftUI.
- **Droop kind**: `kind: droop` plus a pivot (stem base, for example 100,176). The ground ellipses (cy at least 165, drawn first) are split off automatically.
- **Hand-tagged flowers**: a list of element indices that are petals. No new art is needed.

## Coverage over all 50 (automatic, `thin-all50.png`)

- **15 thin clearly**: dandelion, daisy, marigold, sunflower, jasmine, hibiscus, cherry blossom, lithops, passionflower, king protea, giant water lily, Franklin tree, chocolate cosmos, silversword and puya. Silversword and puya are rosettes, so leaves thin rather than petals. I checked these at thumbnail size only.
- **6 weak, need a look**: clover, rose, strawberry, saguaro, rafflesia and sundew. The ring is real but small, or it sits on a covering base.
- **29 have no ring, so they get droop.** About 14 of them are flowers that owners will expect to shed: tulip, poppy, orchid, lotus, lavender, snapdragon, bird of paradise, bleeding heart, ghost orchid, lady's slipper, black bat flower, ghost pipe, corpse flower and jade vine. Their petals are still separate elements (tulip 2 paths, poppy 4 circles, lavender 58 florets), so hand-tagging petal indices fixes most of them in minutes each. Lavender and snapdragon would thin florets up the spike, not round a head. Trees, ferns, palms, cactus, aloe and the flytrap stay droop.

## Verdict on the research note's script approach

The script approach looks good, and I agree with it for detection and drop order. I would change one thing about the output.

Rather than 5 baked state SVGs crossfaded, export layers for each plant:
- `back` (everything drawn before the petals, ground split out);
- one petal sprite per ring plus its angles and pivot;
- `front` (the disc and everything after).

SwiftUI then draws the petals live (`Image(sprite).rotationEffect(angle, anchor: pivot)`) with a ForEach over the kept petals. The falling petal is the same view with keyframes, so there is no crossfade ghosting and the drop order is exact. Plants with mixed z-order between petals (marigold's 3 rings, cherry blossom's 13 heads) need one sprite per ring, but that is still generated, not drawn. For droop plants, `back` is split into `ground` and `body`, and the body gets `.rotationEffect(anchor: .bottom)` plus `.saturation()`.

## Honest limits

- **One pip is several petals.** Daisy loses 4 or 5 per pip, and the sunflower about 10 (5 drift, the rest fade). The owner asked for "a matching petal", and it is a matching cluster.
- **Petal colour stays its own.** The lifestats white-to-pink blush only suits white petals. I left it out here.
- **Fall rotation** assumes the petal's long axis points out from the head, which is true for every ring found. Circle petals (rose) fall as balls.
- **Prototype detail.** Petals are hidden with `opacity: 0` inside a wrapper `<g>`, so their own transform attribute is never overwritten. Geometry is cached at detection time, because hidden petals can report empty boxes. Regrow is quick: a pip's petals are fully back in about 0.65 s.

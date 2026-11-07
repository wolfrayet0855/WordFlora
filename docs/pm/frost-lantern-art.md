# Frost & Lantern: art for G3 (starter pack) and G5 (full pack)

Art lane delivery for `docs/pm/release-plan-extended.md` B3: the G3 starter pack (three pots, the Lantern Keeper badge,
the Seasons row) and the G5 pack content (snowy lantern scene, robin and wren, snowdrop and hellebore at every stage).
These files are for agents to review and builders to draw from. They are not owner mockups. Nothing here is wired up.

- Folder: `design-preview/frost-lantern/` (34 SVGs, the generator `build.py`, and `pot-marks.swift.txt`).
- Review sheets: `review-light.svg` and `review-dark.svg` show every asset at the sizes the app uses, on
  `appBackground` with `appSurface` cards. Open them in a browser.
- Regenerate: `python3 design-preview/frost-lantern/build.py`. Each colour sits once in its palette table `T`, so a
  colour change is one edit plus a rerun. Every file's header comment lists its colours and anchor points.

**Scope.** Only the items the plan lists. The plan names **two** visitors (European robin and wren), so this
lane delivers two, not three. G5 is not marked for later, so the scene, visitors and plants are full art, not sketches.

## Rules used for every asset

- **Style:** the same flat style as `PotPainter`, `BadgeArt` and `VisitorArt`. Flat fills, one white glint where a shape
  should shine, round caps and joins. **No gradients, filters or drop shadows.** Lantern glows are two flat discs at
  10 to 24 % opacity, so they hold together at 28 pt and in a template render.
- **Outlines:** the pots match the existing pots exactly. Full-colour pots have **no** ink stroke: the rim and the
  shade strip draw the edge. Pots not owned use the existing soft outline (`PotPainter` `.toEarn`: pale fill, dashed
  ink 2 pt `[5,4]`, pattern in ink at 55 %). The badge uses the badge frame's tier-colour stroke. Visitors and plants
  follow their own families: no outline on visitors, a darker edge stroke on petals (as on the daisy).
- **Palette:** existing tokens wherever one fits (table below). The new colours are art constants named `FL.*`. They
  are not colorsets, the same way `PotCatalog` keeps its hex values in code.
- **Kids:** no art has a price, a padlock, a countdown or text. The app draws every word.

## 1. Starter pots (G3)

The plan names them **Frosted Glass** (earned: Daily Bloom on 5 days while the season is featured), **Lantern Red**
(paper-lantern band) and **Snowflake Indigo**. Display names follow the catalogue's sentence case: "Frosted glass",
"Lantern red", "Snowflake indigo".

All three use the shared 120 x 100 pot box and draw in `PotPainter`'s order: body, light strip, shade strip, pattern
(clipped to the body), rim, rim shine, then the soil top if there is one. The patterns use only the existing
`PotMark.Shape` cases (`rect`, `capsule`, `circle`, `petal`, `sparkle`), so no painter change is needed. Add three
`Decoration.Kind` cases, `frost`, `lanterns` and `snowflakes`, and paste the lists from `pot-marks.swift.txt` into
`PotCatalog.marks(for:)`. That file is generated from the same code as the SVGs, so they match.

| id | Name | Body / rim / shade | Decoration colours (index order) | Pattern | a11y label |
|---|---|---|---|---|---|
| `frostedGlass` | Frosted glass | `#B7D6E6` / `#548BAC` / `#93BCD2` | `0xFFFFFF`, `0x3F7596` | `frost`: frost band with a scalloped top along the foot, three frost ferns rising from it, two glints (hidden in outline) | Icy blue pot with frost ferns |
| `lanternRed` | Lantern red | `#B5403A` / `#D9665A` / `#93302B` | `0xF5C858`, `0xFFF0C2`, `0x5E211C`, `0x8A2A25` | `lanterns`: a deep band (hidden in outline), a cream string, three paper lanterns (gold, cream, gold) with caps, tassels and a glow (glow knocks out in outline) | Red pot with a band of paper lanterns |
| `snowflakeIndigo` | Snowflake indigo | `#6A70D0` / `#7F86D9` / `#4A4FAE` | `0xFFFFFF`, `0xCFE6F0` | `snowflakes`: three six-armed flakes with hub and side twigs (twigs hidden in outline), six ice dots (hidden in outline) | Indigo pot with white snowflakes |

**States and sizes.** "Empty" means the pot alone, as on tiles. "Occupied" means it has the soil top, as on the plant
stage and in the repot preview.

| State | Where | Size (pt wide) | File |
|---|---|---|---|
| Full, empty | Pick grid, repot chips, Shed shelf and card, Guide | 28, 30, 48, 56 (78 at AX), 60, 80 | `pot-<id>.svg` |
| Full, occupied (soil) | Plant page stage, repot preview | 140 at the 220 stage (`potRect`), scales with it | `pot-<id>-soil.svg` |
| Soft outline, light / dark | Pot to earn (Frosted glass) and pack pot not owned (the other two) | as above | `pot-<id>-outline-light.svg`, `-dark.svg` |

- Full-colour pots are the same in light and dark mode, like every catalogue pot. The review sheets show them on both.
- The outline is the same art for "to earn" and "pack, not owned". Only the hint text differs: the earned pot's goal
  line, or "A grown-up can find this in Settings." for the pack pots (mirroring `PotCatalog.plusHint`). There is no lock
  and no price.
- A pack pot reads as itself at 28 pt: the lantern string is chunky, the snowflakes have a hub, and the frost band
  sits at the foot. The frost band blends into a white card (body 1.5:1), so on light grounds the rim carries the edge,
  the same way Jade vine's rim does. The Frosted glass rim is deepened to `#548BAC` (3.5 to 3.7:1 on light grounds,
  3.1 on dark surface). The suggested `#4F86A8` would drop to 2.9:1 on dark surface, so this is the nearest value
  that still passes on all four grounds with a little margin.

## 2. Lantern Keeper badge (G3)

`badge_lantern_keeper_t1.svg`, `_t2.svg`, `_t3.svg`, 100 x 100, the asset names the plan gives. Same frame as every
`BadgeArt` badge: a dodecagon in the tier's dark and light colours and a `#FFFDF5` disc with a 2 pt tier stroke. The
1, 2 or 3 tier dots are 1.5x the usual size (r 5.4 at y 86, 12 units apart, 2.1 white stroke) so the count reads at
44 pt and tiers do not rely on frame colour alone (checked side by side at 44 pt). The icon is a red paper lantern
(`FL.lanternRed` with a `PetalKit.marigold` glow, ink caps and a gold tassel), centred on the disc at x 50, with a
small frost-blue snowflake at the top right. Tiers differ by frame colour and dot count.
I left out the unused gradient `<defs>` that older badge files carry. Add the three files to `Assets.xcassets/BadgeArt` as
imagesets with `preserves-vector-representation`, like the others.

## 3. Seasons row glyph and pack card (G3)

- **`seasons-row-glyph.svg`**, 24 x 24: an outline paper lantern alone (wide open body at a 2 pt stroke, one thin
  rib oval, flat caps, hook and tassel), single colour. The earlier filled lantern with a snowflake read as "0*" at
  22 pt; the snowflake is dropped because at that size it reads as an asterisk. Checked at 22, 24 and 28 pt. Ship it as a template image so `Label("Seasons", image: "seasons-row-glyph")` tints it
  `appPrimaryText` like the row's SF Symbol neighbours (10.7:1 light, 11.6:1 dark). If a custom glyph is unwanted, the
  SF Symbol `snowflake` is the fallback.
- **`pack-card-light.svg` / `pack-card-dark.svg`**, 353 x 150, the same frame as `ShedScene`: three pots on a snowy
  plank (snowdrop in Frosted glass, Lantern red with bare soil, hellebore in Snowflake indigo), a string of three lanterns,
  and a robin on the plank. Use it on the 13+ Seasons shelf in the Shed and as the header of the Settings > Plus >
  Seasons page. No text is in the art: the app draws "Frost & Lantern", the line and the price (13+ only) under it,
  on `appSurface`. `accessibilityLabel`: "Three winter pots on a snowy shelf, with lanterns and a robin".

## 4. Scene, visitors and plants (G5)

### Scene: `scene-light.svg`, `scene-dark.svg`

- 393 x 852. Scale to fill the width, bottom aligned, behind everything on Home and Garden. Hide it from VoiceOver.
- Light is a winter dusk (pale blue to lilac). Dark is a night sky with a crescent moon and stars. The detail (hills,
  firs, a snow-capped fence, two lantern posts, a lantern string, snowdrops in the bank) sits in the lower 40 %. The
  top 55 % is calm sky. The two snowdrop clumps are drawn at 0.45 and 0.425 of the plant box (1.25x the first draft)
  with the 2.0 edge, so they hold on white snow.
- Named groups: `sky`, `moon`, `stars` (dark only), `hills`, `firs`, `fence`, `lanterns`, `snowbank`, `snowdrops`.
  Snowfall comes from the weather layer, as the plan says. The art has no flakes, so under Reduce Motion and Low Power
  the scene is simply still. Optional motion: the lantern halos may breathe between their two opacities over about 4 s
  with motion on. They are static under Reduce Motion, Low Power and Calm.
- **Text rule (builder):** text over the scene sits on an `appSurface` card, or on a scrim of
  `Color.appBackground.opacity(0.6)` with the card's corner radius. Measured: `#9AA7BC` under a 60 % `#1A2E1A` scrim is
  `#4D5E5B`, 5.5:1 against `appPrimaryText` dark (50 % gives 4.55:1, the floor). Never put text directly on the dark
  snow bank (2.0:1). Text in the sky zone above y 460 is fine without a card (`appPrimaryText` on the sky: 8.4:1
  light, 12.6:1 dark). The snow bank is **not** darkened: 4.5:1 would need about `#5C6A82`, which drops the bank to
  2.2:1 against the sky and stops it reading as snow.
- **Dark lantern string:** `FL.stringDark #8C7A6B`, a warm light brown. The old `FL.snowShadeDark` string was the same
  colour as the shade hill behind it and vanished; the warm string now separates from the cool hill by hue.
- The scene is cosmetic, so it shows in Calm and Quiet Garden (plan G5 acceptance).

### Visitors: European robin and wren

The wren's display name is "Wren" everywhere (never "Winter wren", which is the North American *T. hiemalis*; the
art is the Eurasian wren, *T. troglodytes*).

| File | Use | Size |
|---|---|---|
| `visitor_robin_a.svg`, `_b.svg` | Flight frames, wings up and down | 100 x 100 box, drawn at the game's visitor size (90 pt) |
| `visitor_robin_idle.svg` | Resting pose (Gentle Net landing), wings folded, legs down | 100 x 100 |
| `visitor_robin_sticker.svg` | Album, Field Notes page (108 pt), round summary | 120 x 120 sticker frame |
| `visitor_wren_a/b/idle/sticker.svg` | The same set for the wren | as above |

- Facing leading (beak to the left), like `hummingbird`. The wing turns about (56,52): a = -38 degrees, b = +26,
  idle = +6.
- Sticker frame as in `VisitorArt`: white r 55 disc with a 12 % shadow disc, a tint disc r 47, and the idle pose at
  0.92. Tints: robin `FL.stickerFrost`, wren `FL.stickerMist` (a cool grey, so the brown wren stands off its disc).
- Not-owned or not-met stickers use the album's existing outline rule (`grayscale(1)` at 35 %). There is no extra art.
- Each bird reads on both themes through one part: on light grounds the brown back (robin 4.9:1, wren 5.5:1), on dark
  grounds the orange breast (4.7:1) or the pale belly (12.5:1 robin, 7.8:1 wren).

### Glasshouse plants: snowdrop and hellebore

| File | What |
|---|---|
| `plant_snowdrop.svg` | Full bloom, 200 x 200 plant box, ground at y 177 like every plant. Groups follow `PlantThinning` layers: `ground`, `back` (static), `petals` with `r<head>_s<i>`, then `front`. Three nodding heads at (118,72), (70,88) and (140,104), each with 3 outer tepals (9 petals); the inner bells with their green V are in `front`. |
| `plant_hellebore.svg` | Full bloom, same box. Three heads at (102,74), (60,104) and (144,100), each with 5 sepals (15 petals); the lime centres and stamens are in `front`. |
| `plant_snowdrop_stages.svg`, `plant_hellebore_stages.svg` | **Reference, not shipped; ship only the layered full-bloom files.** Five 200 x 200 panels, stages 0 to 4 (`LifeStats.stageNames`: Tiny, Sprout, Bud, Bloom, Full bloom), for review only. Do not make imagesets from them. |

- Split each full-bloom file into `PlantLayers` imagesets by group id (`plant_snowdrop_ground`, `_back`, `_r0_s0` ...,
  `_front`). Add a `PlantThinning.json` entry with `kind: "petals"`, the head pivots above and rings `[0]`, `[1]`,
  `[2]`, the same pattern as `plant_daisy`.
- **Stages:** ship the scaled full-bloom art only. The plant page draws `LayeredPlantView` and shows growth by
  revealing petal rings, and the Grand Garden scales the one full-bloom image by `GrandGardenArt.stageScale`. Nothing
  reads a per-stage image, and using the stage panels as well would shrink a Tiny plant twice. The stage panels are
  reference, not shipped. The seed stage keeps `SeedPotView`.
- Contrast: snowdrop petals are white with an `FL.snowdropEdge` stroke of 2.0 units on the tepal, bell and bud (it
  was 1.4, under 1 pt at the 132 pt compact stage), 3.3:1 on `appBackground` light, 3.5:1 on surface. Hellebore sepals are 3.2 to 4.0:1 on all four grounds, so the bloom reads without its edge.

## Asset manifest

Sizes are in points as drawn in the app. "Box" is the SVG's own unit box.

| File | Purpose | Size in pt | Colours (tokens) |
|---|---|---|---|
| `pot-frostedGlass.svg` | Frosted glass pot, empty | 28 to 80 (box 120 x 100) | `FL.iceBody`, `FL.iceRim`, `FL.iceShade`, `white`, `FL.frostFern` |
| `pot-frostedGlass-soil.svg` | Same, occupied | 140 at the stage | as above + `PotPainter.soil`, `PotPainter.soilShade` |
| `pot-frostedGlass-outline-light/dark.svg` | To earn | 28 to 60 | `PotPainter.toEarnFill.*`, `PotPainter.toEarnInk.*` |
| `pot-lanternRed.svg` | Lantern red pot, empty | 28 to 80 | `FL.lanternBody`, `FL.lanternRim`, `FL.lanternShade`, `PetalKit.marigold`, `Pot.honeyCream`, `FL.lanternInk`, `FL.lanternBand` |
| `pot-lanternRed-soil.svg` | Same, occupied | 140 | as above + soil |
| `pot-lanternRed-outline-light/dark.svg` | Pack pot, not owned | 28 to 60 | `PotPainter.toEarnFill.*`, `PotPainter.toEarnInk.*` |
| `pot-snowflakeIndigo.svg` | Snowflake indigo pot, empty | 28 to 80 | `FL.indigoBody`, `FL.indigoRim`, `FL.indigoShade`, `white`, `FL.ice` |
| `pot-snowflakeIndigo-soil.svg` | Same, occupied | 140 | as above + soil |
| `pot-snowflakeIndigo-outline-light/dark.svg` | Pack pot, not owned | 28 to 60 | `PotPainter.toEarnFill.*`, `PotPainter.toEarnInk.*` |
| `pot-marks.swift.txt` | `PotMark` lists for `PotCatalog.marks(for:)` | n/a | n/a |
| `badge_lantern_keeper_t1.svg` | Badge, bronze | 44 to 100 (box 100) | `Badge.bronze`, `Badge.bronzeLight`, `Badge.disc`, `FL.lanternRed`, `FL.lanternInk`, `PetalKit.marigold`, `FL.frostFern`, `white` |
| `badge_lantern_keeper_t2.svg` | Badge, silver | 44 to 100 | `Badge.silver`, `Badge.silverLight`, + icon as t1 |
| `badge_lantern_keeper_t3.svg` | Badge, gold | 44 to 100 | `Badge.gold`, `Badge.goldLight`, + icon as t1 |
| `seasons-row-glyph.svg` | Settings > Plus "Seasons" row icon (template) | 17 to 28 (box 24) | tinted `appPrimaryText` at runtime |
| `pack-card-light.svg` | Seasons shelf card, Seasons page header | full card width, about 335 to 353 x 150 | `FL.skyL1`, `FL.skyL3`, `FL.snow`, `FL.woodLight`, `FL.woodEdge`, `FL.lanternInk`, `FL.glow`, `FL.iceRim`, the three pots, plants and robin |
| `pack-card-dark.svg` | Same, dark | as above | `FL.skyD2`, `FL.skyD3`, `FL.snowDark`, `FL.snowShadeDark`, stars `#E8EEF8` at 70 %, rest as light |
| `scene-light.svg` | Home and Garden background, light | screen width, 393 x 852 box | `FL.skyL1-3`, `FL.moon`, `FL.hillL`, `FL.snowShade`, `FL.snow`, `FL.fir`, `FL.post`, `FL.postDark`, `FL.lanternRed`, `FL.lanternInk`, `FL.glow`, `PetalKit.marigold`, snowdrop colours |
| `scene-dark.svg` | Same, dark | as above | `FL.skyD1-3`, `FL.moon`, stars, `FL.hillD`, `FL.snowShadeDark`, `FL.snowDark`, `FL.firDark`, `FL.postDark`, `FL.stringDark`, lantern colours |
| `visitor_robin_a/b/idle.svg` | Robin flight and resting frames | 90 (box 100) | `FL.robinBack`, `FL.robinWing`, `FL.robinWingEdge`, `FL.robinBreast`, `FL.robinGrey`, `FL.robinBelly`, `FL.beak`, `Visitor.eye`, `FL.leg` |
| `visitor_robin_sticker.svg` | Robin sticker | 22 to 108 (box 120) | as above + `FL.stickerFrost`, `white` |
| `visitor_wren_a/b/idle.svg` | Wren flight and resting frames | 90 (box 100) | `FL.wrenBody`, `FL.wrenWing`, `FL.wrenBar`, `FL.wrenBelly`, `FL.wrenBrow`, `FL.beak`, `Visitor.eye`, `FL.leg` |
| `visitor_wren_sticker.svg` | Wren sticker | 22 to 108 (box 120) | as above + `FL.stickerMist`, `white` |
| `plant_snowdrop.svg` | Snowdrop, full bloom, layered | plant size (132 to 220) (box 200) | `white`, `FL.snowdropEdge`, `FL.snowdropLeaf`, `FL.snowdropLeafVein`, `PetalKit.stem`, `PetalKit.leaf`, `Plant.groundShadow` |
| `plant_snowdrop_stages.svg` | Snowdrop stages 0 to 4: reference, not shipped; ship only the layered full-bloom files | n/a | as above |
| `plant_hellebore.svg` | Hellebore, full bloom, layered | plant size (box 200) | `FL.helleboreSepal`, `FL.helleboreEdge`, `FL.helleboreCentre`, `FL.helleboreStamen`, `FL.helleboreLeaf`, `FL.helleboreVein`, `FL.helleboreStem`, `Plant.groundShadow` |
| `plant_hellebore_stages.svg` | Hellebore stages 0 to 4: reference, not shipped; ship only the layered full-bloom files | n/a | as above |
| `review-light.svg`, `review-dark.svg` | Agent review sheets, not shipped | 1100 x 1360 | all of the above on `appBackground` and `appSurface` |
| `build.py` | Generator, not shipped | n/a | the palette table `T` |

### Tokens

Existing tokens reused: `appBackground` `#FAF7F0`/`#1A2E1A`, `appSurface` `#FFFFFF`/`#2C3E2C`, `appPrimaryText`
`#2C3E2C`/`#D4EDD4`, `PotPainter` soil `#85583A`/`#6B4528`, to-earn fill `#E4DFD2`/`#3A4C3A` and ink
`#746F5E`/`#8FA48F`, `PetalKit` marigold `#F5C858`, stem `#4E9A55`, leaf `#5FA860`, badge tiers bronze
`#9A5F2A`/`#C98A4B`, silver `#8D9AA6`/`#C5CED6`, gold `#D49A1E`/`#F5C84C`, badge disc `#FFFDF5`, visitor eye `#2C2418`,
Honey stripe cream `#FFF0C2` (`Pot.honeyCream`), plant ground shadow `#2C3E2C` at 14 %.

New art constants (`FL.*`), with hex values in `build.py`:

| Group | Tokens |
|---|---|
| Frosted glass | `iceBody #B7D6E6`, `iceRim #548BAC`, `iceShade #93BCD2`, `frostFern #3F7596` |
| Lantern red | `lanternBody #B5403A`, `lanternRim #D9665A`, `lanternShade #93302B`, `lanternBand #8A2A25`, `lanternInk #5E211C`, `lanternRed #C8473E`, `glow #F5C858` |
| Snowflake indigo | `indigoBody #6A70D0`, `indigoRim #7F86D9`, `indigoShade #4A4FAE`, `ice #CFE6F0` |
| Scene and card | `skyL1 #D3DEEE`, `skyL2 #DFE5F1`, `skyL3 #EAE6F0`, `skyD1 #17233A`, `skyD2 #1E2C46`, `skyD3 #283752`, `hillL #C4D3E4`, `hillD #33425E`, `moon #F6E8B0`, `snow #F4F7FB`, `snowShade #DCE5EF`, `snowDark #9AA7BC`, `snowShadeDark #7D8BA3`, `stringDark #8C7A6B`, `fir #3F6F4A`, `firDark #2E5538`, `post #5E4A3A`, `postDark #3E3128`, `woodLight #D9A066`, `woodEdge #9A5F2A` |
| Robin | `robinBack #7A6A4E`, `robinWing #5E4E36`, `robinWingEdge #9A8A68`, `robinBreast #E2733A`, `robinGrey #A9B0B8`, `robinBelly #F3EEE6`, `beak #3A2C1E`, `leg #7A5A44`, `stickerFrost #DCEBF2` |
| Wren | `wrenBody #8A5A34`, `wrenWing #6E4524`, `wrenBar #4E2F17`, `wrenBelly #D8B98E`, `wrenBrow #EBD7B4`, `stickerMist #E6EAF0` |
| Snowdrop | `snowdropLeaf #6E9C7E`, `snowdropLeafVein #A9C9B4`, `snowdropEdge #768C91` |
| Hellebore | `helleboreSepal #C46B8C`, `helleboreEdge #9A4A6B`, `helleboreCentre #C9D86A`, `helleboreStamen #F2E7A0`, `helleboreLeaf #3F6F4A`, `helleboreVein #6E9C7E`, `helleboreStem #5E8A4E` |

## Contrast check

WCAG relative luminance. The targets are 3:1 for shapes and 4.5:1 for text. The art has no text, so 4.5:1 applies only
to app text placed over the scene or card. Grounds: `appBackground` and `appSurface`, light and dark.

| Part | bg light | surface light | bg dark | surface dark | Verdict |
|---|---|---|---|---|---|
| Frosted glass rim `#548BAC` (deepened from `#5E93B0`) | 3.5 | 3.7 | 3.9 | 3.1 | passes on all four |
| Lantern red rim `#D9665A` | 3.3 | 3.5 | 4.1 | 3.3 | passes on all four |
| Snowflake indigo rim `#7F86D9` (unchanged) | 3.1 | 3.3 | 4.4 | 3.4 | passes on all four |
| Snowflake indigo body `#6A70D0` | 4.1 | 4.3 | 3.3 | 2.6 | rim carries the edge on dark surface |
| Outline ink (theme's own) on its ground | 4.7 | 5.0 | 5.4 | 4.3 | passes (existing values) |
| Badge icon `FL.lanternRed` on `Badge.disc` | 4.7 | 4.7 | 4.7 | 4.7 | passes (the disc is the same in both themes) |
| Seasons glyph (`appPrimaryText`) | 10.7 | 11.5 | 11.6 | 9.2 | passes text level |
| Robin: back (light) / breast (dark) | 4.9 | 5.3 | 4.7 | 3.7 | passes |
| Wren: body (light) / belly (dark) | 5.5 | 5.8 | 7.8 | 6.1 | passes |
| Snowdrop edge (light) / petal (dark) | 3.3 | 3.5 | 14.5 | 11.5 | passes |
| Hellebore sepal | 3.4 | 3.6 | 4.0 | 3.2 | passes |

Pattern on its own body: frost fern 3.3, lantern gold 3.5 (cream on the band 7.6), snowflakes 4.3, ice dots 3.4 (on the lighter `#6A70D0` body),
outline ink on outline fill 3.8 light / 3.5 dark. The white frost band on Frosted glass is 1.5:1. It is a soft texture,
not an identifying shape: the ferns carry the pattern.

Scene (decorative, hidden from VoiceOver, so 1.4.11 does not apply): `appPrimaryText` on the sky is 8.4:1 light and 12.6:1
dark, and on light snow 10.7:1. On dark snow it is **2.0:1**, hence the text rule above (card or 60 % scrim, 5.5:1). The dark firs sit at 1.2:1 on
the dark hills. Their snow caps give the shape, and nothing interactive sits there.

## Colour-blind check

Simulated with Machado 2009 at full severity (protanopia, deuteranopia, tritanopia). Every pot still differs by pattern,
as the catalogue rule requires. These are the closest pairs, with luminance contrast as normal / protan / deutan / tritan:

| Pair | Ratios | Told apart by |
|---|---|---|
| Snowflake indigo vs Starlight | 1.49 / 1.49 / 1.50 / 1.52 | six-armed flakes with a hub and twigs vs four-point sparkles; indigo rim vs teal rim |
| Snowflake indigo vs Dewdrop | 1.36 / 1.29 / 1.40 / 1.34 | flakes vs drops; the darker indigo rim |
| Snowflake indigo vs Moonlit | 1.95 / 1.97 / 1.95 / 1.98 | flakes vs one big crescent |
| Frosted glass vs Jade vine | 1.30 / 1.27 / 1.33 / 1.30 | frost band and ferns vs hanging jade flowers on a vine rail |
| Lantern red vs Terracotta | 1.60 / 1.75 / 1.52 / 1.59 | lantern band vs two rings |
| Robin breast vs back | 1.69 / 1.43 / 1.85 / 1.68 | the breast's grey edge band and shape. The robin still reads as a robin by silhouette and the white belly |
| Hellebore sepal vs leaf | 1.63 / 1.36 / 1.82 / 1.66 | flower shape and the pale centre; leaves are palmate |

The Snowflake indigo body is lightened from `#4A4FAE` to `#6A70D0` (the shade takes the old body, `#4A4FAE`; the rim
stays `#7F86D9`). That lifts the Starlight pair from 1.08 to 1.49 in grey. The rim still passes 3:1 on all four app
grounds (table above). The new body sits nearer Dewdrop's lilac `#9686CC` (1.36), told apart by flakes vs drops and the
darker rim. Builders: paste the new body and shade into the `snowflakeIndigo` entry in `PotCatalog`; the `PotMark`
lists in `pot-marks.swift.txt` hold only decoration colours and do not change.

## Draft facts (for the owner's G5 fact-check, not yet checked)

The plan asks for owner-checked facts. These are still **drafts**: each needs a source and the checklist below before
the G5 go/no-go. The app rule (`docs/research/visitor-facts.md`): one or two sentences, at most 16 words and 90
characters, short words, `CopySafety.check` empty, no death or danger.

- Robin: "Robins sing in winter too. Some even sing at night near street lights." (70 / 13)
- Wren: "Wrens are tiny but very loud singers. On cold nights, many snuggle in one nest box." (83 / 16)
- Snowdrop: "Snowdrops bloom in late winter. Their hard leaf tips push up through cold ground." (81 / 14)
- Hellebore: "Hellebores bloom in winter. Their bright parts are sepals, so they stay for weeks." (82 / 14)

The wren line was shortened (the old one was 96 characters and 19 words). The hellebore line drops "last", which
`CopySafety` bans, and "colourful", which no shipped string spells either way.

Source-check checklist (owner, about 20 min, before G5):

1. One authoritative source per fact, noted in a new table in `docs/research/visitor-facts.md` (birds) and a short
   `docs/research/plant-facts-frost-lantern.md` (plants), same format as the visitor table.
   - Birds: RSPB species page **and** BTO BirdFacts. Robin: winter song, night singing near street lights. Wren: loud
     song for its size, communal roosting in nest boxes in cold weather.
   - Plants: RHS grow guide **and** Kew plant page. Snowdrop (*Galanthus nivalis*): late-winter flowering, hardened leaf
     tips. Hellebore: petal-like sepals, long display.
2. Run each line through `CopySafety.check` and the 90 character / 16 word limits (add the four lines to the existing
   fact test when the catalogue entries land).
3. Under-13 safety: no death, cold-danger or "or they would freeze" framing (the wren line stays about snuggling).
   **Never mention toxicity** (hellebores and snowdrops are poisonous) and **never invite picking, touching or
   tasting**. No numbers a child cannot picture.
4. Hedge anything regional ("Some even sing at night") rather than state it as universal.

## Open questions

1. **Wren name and species.** Settled: the display name is "Wren" everywhere. The plan's "winter wren" is today the
   North American *Troglodytes hiemalis*; the art is the Eurasian wren (*T. troglodytes*), so facts use RSPB and BTO.
2. **Hellebore species.** I drew the Lenten rose (*H. orientalis*, plum) so it does not repeat the snowdrop's white.
   The Christmas rose (*H. niger*) is white and blooms nearer December. It is a colour swap in `build.py` if wanted.
3. **Stage art.** Settled: the scaled full-bloom art, like the 50 ladder plants. The stage panels are reference, not
   shipped (section 4).
4. **Visitor count.** The brief to this lane said "3+ visitors". The plan lists two (robin and wren). Scope is frozen, so
   there are two. A third needs a plan change.
5. **Glow Lantern overlap.** The backlog Glow Lantern (`docs/STATUS.md`) and the Shed light are kept from reading as
   lanterns. A lantern pack makes that item's future art harder to tell apart. If it comes back, give it a different
   shape (a jar light).
6. **Pack-card alt text and Seasons page copy** are drafted here only as a label. The builder owns the strings
   (through `CopySafety`).

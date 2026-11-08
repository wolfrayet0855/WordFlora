# Frost & Lantern: weak points and quick wins

Critique of `docs/pm/frost-lantern-art.md` and the rendered `design-preview/frost-lantern/review-light.svg` /
`review-dark.svg`. Scope is frozen: every fix below stays inside the existing plan. "Art" means an edit to the palette
table `T` or a stroke width in `build.py` plus `python3 build.py`; "builder" means Swift; "copy" means a doc or string.

## Ranked quick wins

| # | Weak point | Fix | Who | Min |
|---|---|---|---|---|
| 1 | Stage panels vs `stageScale` could shrink Tiny twice | Ship only the layered full-bloom files. Do not make imagesets from `plant_*_stages.svg`; mark them "reference, not shipped" in the manifest. | Copy | 5 |
| 2 | Hellebore fact fails `CopySafety` ("last"); wren fact is 96 chars / 19 words (limits 90 / 16) | Use the rewrites below; run the checklist before G5. | Copy | 20 |
| 3 | Dark snow bank 2.0:1 under `appPrimaryText` | Builder rule: any text over the scene sits on an `appSurface` card or a 60 % `appBackground` scrim (5.5:1 on the bank). No art change. | Builder | 10 |
| 4 | Snowflake indigo vs Starlight 1.07:1 in grey | `FL.indigoBody` `#4A4FAE` -> `#6A70D0`, `FL.indigoShade` -> `#4A4FAE` (the old body), rim unchanged. Starlight distance 1.08 -> 1.49; still 3:1+ on all four grounds. Copy the hex into `PotCatalog`. | Art, then builder | 10 |
| 5 | Snowdrop petal edge is a hairline at 132 pt | `FL.snowdropEdge` stroke 1.4 -> 2.0 (tepal, bell and bud in `build.py`). | Art | 5 |
| 6 | Badge snowflake nearly vanishes at 44 pt | Scale the flake 1.4x about its centre; the lantern carries the icon anyway. | Art | 10 |
| 7 | Sheet labels the wren with the North American species name | Display name "Wren" everywhere. | Copy | 2 |

## 1. Dark snow bank (2.0:1)

The rule in the art spec is right but unenforced. Make it a builder rule with a number:

- Text over the scene uses the existing `appSurface` card, or `.background(Color.appBackground.opacity(0.6))` with the
  card's corner radius. Measured: `#9AA7BC` under a 60 % `#1A2E1A` scrim is `#4D5E5B`, 5.5:1 against `#D4EDD4`
  (50 % gives 4.55:1, the floor). Light mode needs nothing (10.7:1 on light snow).
- Do not darken `FL.snowDark` instead: 4.5:1 needs about `#5C6A82`, which drops the bank to 2.2:1 against the sky and
  stops reading as snow.

## 2. Snowflake indigo vs Starlight (1.07:1)

Lighten the body, as the spec already offers. In `build.py` table `T`: `FL.indigoBody` `#6A70D0`, `FL.indigoShade`
`#4A4FAE`. Rerun, then paste the two hex values into the `snowflakeIndigo` entry in `PotCatalog`. The pattern lists in
`pot-marks.swift.txt` do not change. The new body is 1.49:1 against Starlight's `#2F6670` and sits apart from Dewdrop's
lilac `#9686CC` by pattern (flakes vs drops) and by the darker rim. Cheaper fallback if the colour is unwanted: leave the
body and double the six ice dots to 12, which adds grey texture Starlight does not have (same file, 5 min).

## 3. Facts: checklist and sources

The app's rule (`docs/research/visitor-facts.md`, tested in `ButterflyAndBadgeTests`): one or two sentences, at most 16
words and 90 characters, short words, `CopySafety.check` empty, no death or danger. Checked against the drafts:

| Fact | Chars / words | `CopySafety` | Action |
|---|---|---|---|
| Robin | 70 / 13 | clean | keep |
| Wren | 96 / 19 | clean | too long: "Wrens are tiny but very loud singers. On cold nights, many snuggle in one nest box." (83 / 16) |
| Snowdrop | 81 / 14 | clean | keep |
| Hellebore | 85 / 14 | **"last"** banned | "Hellebores bloom in winter. Their bright parts are sepals, so they stay for weeks." (82 / 14) |

Also match the app's spelling convention ("colourful" appears in no shipped string; drop the word rather than decide).

Checklist before the G5 go/no-go (owner, about 20 min):

1. One authoritative source per fact, noted in a new table in `docs/research/visitor-facts.md` (birds) and a short
   `docs/research/plant-facts-frost-lantern.md` (plants), same format as the visitor table.
   - Robin: RSPB "Robin" species page and BTO BirdFacts (winter song, night singing under street lights).
   - Wren: RSPB "Wren" and BTO BirdFacts (loud song for its size; communal roosting in nest boxes in cold weather).
     Cornell "All About Birds" covers the North American species (*T. hiemalis*), so it is not a source for the Eurasian wren.
   - Snowdrop: RHS "Galanthus" grow guide and Kew "Galanthus nivalis" plant page (late-winter flowering, hardened
     leaf tips).
   - Hellebore: RHS "Hellebores" grow guide and Kew (petaloid sepals, long display).
2. Run each line through `CopySafety.check` and the 90 / 16 limits (add the four lines to the existing fact test when
   the catalogue entries land).
3. Under-13 safety: no death, cold-danger or "or they would freeze" framing (the wren line stays about snuggling);
   never mention that hellebores and snowdrops are poisonous, and never invite touching, tasting or picking; no
   numbers a child cannot picture.
4. Hedge anything regional ("Some even sing at night") rather than state it as universal.

## 4. Stage panels vs app scaling

Recommendation: **scaled full-bloom art only; do not ship the stage panels.**

- The plant page draws `LayeredPlantView(imageName:pips:)` and shows growth by revealing petal rings, not by swapping
  images. The Grand Garden draws the one full-bloom image at `GrandGardenArt.stageScale`. Nothing reads a per-stage
  image, so wiring panels in would be new work, and leaving both would double-shrink Tiny.
- Edit the manifest rows for `plant_snowdrop_stages.svg` and `plant_hellebore_stages.svg` to "reference only, not
  shipped" and strike the "panels or scaled" sentence in section 4. Only the layered `plant_snowdrop.svg` and
  `plant_hellebore.svg` become `PlantLayers` imagesets, exactly like `plant_daisy`.

## 5. Other weak points seen in the render

- **Snowdrop edge.** The white tepals carry their 3.3:1 only through `FL.snowdropEdge` at 1.4 units. At the compact
  stage (132 pt, 0.66x) that is under 1 pt. Raise to 2.0 in the tepal, bell and bud strokes in `build.py`.
- **Badge at 44 pt.** The frost-blue snowflake on the `#FFFDF5` disc is a few pixels; the lantern alone identifies the
  badge, so either drop the flake at small sizes or scale it 1.4x. Scaling is the one-line fix.
- **Pots at 28 pt.** Frosted glass ferns blur into the band and the Lantern red lanterns read as gold dots, but each pot
  still differs from its neighbours by rim and band position. No change; note it in the spec as accepted.
- **Scene snowdrops.** Invisible at the 0.48 preview, fine at 1x. No change; they are decorative.
- **Light scene lanterns.** Pale marigold on pale snow (about 1.3:1). Decorative, so acceptable, but if a reviewer
  wants them to read, the ink caps could gain 0.4 units of stroke. Not a priority.
- **No clipping** found in either sheet: pots, stickers and the pack card sit inside their boxes.

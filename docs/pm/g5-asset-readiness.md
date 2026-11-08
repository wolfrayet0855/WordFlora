# G5 asset readiness: full Frost & Lantern

Date 2026-11-07. Audit of what G5 still needs from `design-preview/frost-lantern/` (art spec: `docs/pm/frost-lantern-art.md`, visual review: `docs/pm/frost-lantern-art-visual-review.md`, facts: `docs/research/frost-lantern-facts-check.md`). G5 scope from `docs/pm/release-plan-extended.md`: the snowy lantern scene, robin and wren visitors, snowdrop and hellebore glasshouse plants, no new stored fields.

## Already in the app (G3, not G5)

In the G3 worktree catalog: `BadgeArt/badge_lantern_keeper_t1..t3`, `Art/pack_frost_lantern_card`, `Art/seasons-row-glyph`. The three pots are drawn in code (`PotCatalog`, `pot-marks.swift.txt`). Nothing to do for these in G5. All visual must-fix and should-fix items from the visual review (glyph, dark string, snowdrop edge, fir, badge pips, lighter indigo) have commits in `git log -- design-preview/frost-lantern` (97d120a, b4d6e6a, 6727709, 266d9bc, 3f911bf, dfd6900, e956e3d); the dark snow bank darkening (review item 2) was ruled out in the art doc (bank must read as snow), with the text-over-scene card or scrim rule instead.

## Asset table

All SVGs are final-flat-style source (no gradients or filters) and import as vectors, so none needs rasterising. "Convert" means splitting or repackaging, not redrawing. Catalog folders mirror the existing ones (`VisitorArt`, `PlantLayers`, a new `Scenes`), each imageset with `"preserves-vector-representation": true` as in the existing sets.

| Asset (source file) | State | Target asset catalog name | Light / dark | A11y label (builder writes through `CopySafety`) | Work |
|---|---|---|---|---|---|
| Scene (`scene-light.svg`, `scene-dark.svg`, box 393 x 852) | SVG ready, layers named (`sky`, `moon`, `stars` dark, `hills`, `firs`, `fence`, `lanterns`, `snowbank`, `snowdrops`) | `Scenes/frost_lantern_scene` (one imageset, light + dark appearance pair, like `ShedScene` with `shedscene.svg` and `shedscene-dark.svg`) | Two files, one imageset | None: decorative, `.accessibilityHidden(true)` | Mount behind Home and Garden; aspect rule below; lantern halo breathing optional, still under Reduce Motion, Low Power and Calm |
| Robin flight a, b, idle (`visitor_robin_a/b/idle.svg`, box 100) | SVG ready | `VisitorArt/visitor_robin_a`, `_b`, `_idle` | Same art in both modes | Visitor in game: "European robin" (name in album: "Robin") | Add three imagesets; register `robin` in the visitor catalog |
| Robin sticker (`visitor_robin_sticker.svg`, box 120) | SVG ready | `VisitorArt/visitor_robin_sticker` | Same both modes (white disc and tint) | "Robin sticker" / not met: "Robin, not met yet" (follow the existing visitors' wording) | Not-owned uses the album's grayscale 35 % rule; no extra art |
| Wren flight a, b, idle, sticker | SVG ready | `VisitorArt/visitor_wren_a`, `_b`, `_idle`, `_sticker` | Same both modes | "Wren" (never the North American species name) | As robin |
| Snowdrop full bloom (`plant_snowdrop.svg`, box 200) | SVG ready, layers `ground`, `back`, `petals`, `r0_s0` to `r2_s2`, `front` | `PlantLayers/plant_snowdrop_ground`, `_back`, `_r0_s0` ... `_r2_s2`, `_front` (14 imagesets, same as `plant_daisy`) | Same both modes | Plant page: "Snowdrop" with the stage name from `LifeStats.stageNames`; the existing plant accessibility text pattern | Split by group id into imagesets; add a `PlantThinning.json` entry (kind `petals`, pivots (118,72), (70,88), (140,104), rings `[0]`, `[1]`, `[2]`) |
| Hellebore full bloom (`plant_hellebore.svg`) | SVG ready, same layer scheme with 5 sepals per head | `PlantLayers/plant_hellebore_*` (same pattern, 3 heads x 5 sepals) | Same both modes | "Hellebore" plus stage | As snowdrop; pivots (102,74), (60,104), (144,100) |
| Snowdrop / hellebore stage panels (`*_stages.svg`) | Reference only, **do not ship** (ruled; stage growth is the petal rings plus `GrandGardenArt.stageScale`) | none | n/a | n/a | None. The seed stage keeps `SeedPotView` |
| Review sheets (`review-*.svg`), `build.py` | Not shipped | none | n/a | n/a | None |
| Pack card (`pack-card-*.svg`) | Done in G3 (`Art/pack_frost_lantern_card`) | existing | | | Reuse on the Seasons page header; confirm it is a light/dark pair there |

Conversion tooling: `tools/thin_svg.py` builds the layers for the 50 ladder plants from `Assets.xcassets/Plants/<plant>.imageset/<plant>.svg`. The frost plants are authored already layered, so they need a small splitter (read `plant_snowdrop.svg`, write one SVG per group id with the shared `<defs>` and viewBox, create the imageset folders, and emit the `PlantThinning.json` entry). Either extend `thin_svg.py` with a "pre-layered source" mode or write `tools/split_layered_svg.py`. About 2 to 3 h including a unit test that every layer file exists and the ring count matches the entry (`PlantThinningTests` pattern).

## Facts and copy

| Species | Line | Status |
|---|---|---|
| Robin | "Robins sing through the winter, not just in spring." | Confirmed (European robin only; American robin would be wrong) |
| Wren | "A wren is tiny, but its song is remarkably loud." | Confirmed |
| Snowdrop | "Snowdrops often bloom in January and February." | Confirmed (Northern Hemisphere) |
| Hellebore | "Hellebore flowers have petal-like parts called sepals that stay on for weeks." | Confirmed |

All four are under 90 characters and 16 words and pass `CopySafety` (`docs/research/frost-lantern-facts-check.md`). Remaining copy to write, all through `CopySafety`, none drafted in the repo: the albums' "how to meet this friend" hint lines for robin and wren (match the existing visitor hints in `docs/research/visitor-facts.md`), the glasshouse plants' botanical name captions (*Galanthus nivalis*; hellebore species: art is the Lenten rose *H. orientalis*, open question 2 in the art doc), any "Seasons" page lines for the full pack, and the App Store Connect description (in the plan: "Three winter pots, a snowy lantern garden, two winter friends and two glasshouse plants"). Source notes (`docs/research/visitor-facts.md` table for the birds, `docs/research/plant-facts-frost-lantern.md` for plants) are asked for by the art doc checklist; the second file does not exist yet.

## Open gaps

1. **Scene aspect ratio.** The scene is a 393 x 852 box. iPhone sizes range from 375 x 667 (SE) to 440 x 956. Decide: aspect-fill anchored to the bottom (keeps the snow bank and fence), crop the sky. Home and Garden content must still pass the text rule (card or 60 % scrim for text over the snow bank; dark snow bank is 2.0:1 for text).
2. **Visitor catalog wiring.** Season visitors spawn only for pack owners, never move the visitor badge count past the 12 friends, and the album shows them with the pack's outline rule. Needs `PackCatalog` ownership plus the visitor spawner guard and tests (plan acceptance).
3. **Glasshouse plants are outside the 50-plant ladder.** `GlasshouseCatalog` with ids that never enter `ProgressionPolicy`, level progress, `wordsTowardPlant` or pot unlocks; `PlantDetailView` has no hero word; the panorama (Endgame) must not draw them on the hills. Biggest logic item.
4. **No new stored fields.** The plan says G5 adds none; ownership is read from StoreKit. A builder who needs a field stops and reports (CloudKit is deployed once; see `docs/setup/cloudkit-new-fields.md`).
5. **Hellebore species and colour** (plum Lenten rose vs white Christmas rose): art doc open question 2, a colour swap in `build.py` if the owner wants white. Default stays plum.
6. **Glow Lantern overlap** with the backlog item of the same name: a naming/art collision only if that item returns.
7. **Verification shots** wanted by the plan hand-off: Home, Garden, album, both plants at stages 0 and 4, light and dark.
8. **Snowdrop file is small** (3.7 KB against 10.5 KB for hellebore): fine for flat art, but check at 132 pt that the three nodding heads and the edge stroke (2.0 units) survive, since that stroke was thickened for the compact stage.

## Effort to finish (builder hours, G5 from the plan: about 20 h)

| Item | Hours |
|---|---|
| Layered-SVG splitter, 28 plant imagesets, `PlantThinning.json` entries, test | 3 |
| Visitor imagesets (8 files + 2 stickers), catalog entries, album outline rule, spawner guard, tests | 3 |
| Scene imageset pair, Home and Garden background, aspect rule, Reduce Motion / Low Power / Calm behaviour, snowfall from the weather layer, VoiceOver hidden | 3 |
| `GlasshouseCatalog`, `PlantDetailView` variant, progression-isolation tests, panorama exclusion | 5 |
| `PackCatalog` hooks, Seasons page content, copy through `CopySafety`, hints | 2 |
| UI audits (`-uitest-pack-owned`, light/dark, AX XXXL), regression batches, owner screenshots | 4 |
| **Total** | **about 20** (assets alone: about 9 of it is conversion and wiring, no redraw needed) |

Art needs no redraw. The only art-lane work left is optional: a white hellebore variant if the owner asks, and a re-check of the compact-size render of the snowdrop. Doing the splitter first lets the rest proceed in parallel with the lock-free parts of G4a.

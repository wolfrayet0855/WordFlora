# Garden Path critique (pass 2)

Checked `index.html` against the binding brief. Every copy string was run against `WordFlora/Rules/CopySafety.swift` `banned` (plus "lock", "locked"): no hits.

| # | Item | Severity | Fixed |
|---|------|----------|-------|
| 1 | Level 3 was called "Wildwood"; the app (`LevelMapView.swift:10`, `GardenView.swift:10`) and spec say "Bloom". | must | yes |
| 2 | Nav showed the old two-flower wordmark (`logo/final`). Now the v3 hero wordmark (one flower on the Flora o), light + dark, 24 px high. The same art is already the app's `Wordmark` asset. | must | yes |
| 3 | No "all found" state. Added `state=all` (all 50 found, L1-3 full bloom, L5 current) with header "All 50 plants found! Grow them all to full bloom." | must | yes |
| 4 | Level 5 current would have said "Find N more to open Level 6." Now "Find N more for Level 5." (and "Find 10 plants for Level 5." at 0). | must | yes |
| 5 | Level 5 all found had no message. Now "All 10 found! Every level is open." | should | yes |
| 6 | "All 10 found! Level N+1 is open." was hidden on the current level. Now shown on any level with 10 found. | should | yes |
| 7 | Garden level (all 10 at stage 4) was the same 10 gappy arcs as 9/10. Now a solid 5 px gold ring, so the complete garden reads at a glance. | should | yes |
| 8 | VoiceOver labels left out the theme line, the "first plant" wording and the next step. Labels now repeat the visible card text in order. | should | yes |
| 9 | Nav wordmark had alt "WordFlora", so it was read before the "Garden Path" header. Now decorative (hidden). | should | yes |
| 10 | Key-card icons were fixed at 12-13 px, so at AX size they looked tiny next to 2x text. They now scale with the text. | should | yes |
| 11 | No render script, and the shots did not cover all states. Added `render.sh` and 9 shots. | should | yes |
| 12 | Theme lines and hero plants exist only in the mockup (owner decision 1 in `docs/pm/app-vs-mockups.md`). "Rare" appears in both L4 and L5. | nit | no (owner) |
| 13 | At AX sizes "Coming soon in your garden" wraps to two lines; it is acceptable and balanced. | nit | no |
| 14 | Shots keep a blank band under the bench (fixed window height, no cropper). It is only in the shots. | nit | no |

Kept as is (already right): no locks, dashed "soon" cards with a sprout, petal ring per plant, amber current-level card, no prices, no ads, no Plus, nothing earned is ever hidden.

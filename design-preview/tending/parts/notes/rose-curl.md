# Rose curl: the petals that stay get sleepy (T-E, Opus visual, revision 1 + symmetric pair, approved)

Page: `parts/rose-curl.html`. Query parameters:
- `?theme=light|dark`
- `?w=390`: narrows the page.
- `?focus=sec160,sec320,secLive,secSprites,secAlt,secJson`
- `?pips=N`: jump both stages to N pips. Add `&fall` to drop one pip from N.
- `?play`: run the 5 to 0 demo.

Shoot with `--headless=old --virtual-time-budget=3000`.

Sprite reference: `parts/rose-curl.svg`. Critic review: `notes/rose-curl-review.md`. Shots: `parts/shots/rose-curl-light.png` and `-dark.png` (160 px, today vs curled, 2x), and `rose-curl-fall-3to2.png` (mid fall from 3 to 2).

## What changed in this revision (per the critic)

- **Silhouette, not surface.** The curled petal loses its tip and is about 30% shorter. At stage 1 the petal is 16.8 units tall instead of 24. At stage 2 it is 15.4. The tip rolls back as one opaque tube in the edge red #B52C52, 3.6 units thick at stage 1 and 4 at stage 2. One thin #E0587A highlight runs along the roll. A crisp #8E1F3E fold line sits where the tube meets the face (#D94668). There is no gloss band and no translucent shade.
- **Placement.** A curled petal sits 2.5 units further out than a fresh one (`translate(0 -19.5)` instead of `-17`). Without that, the r15 wrap would hide everything but the tube. The petal loosens as it tires.
- **Droop by rotation only,** about the petal base (6 units out from the centre along the petal's angle). Stage 1 is 16-17 degrees. Stage 2 is 25 degrees. There is no squash, no `axis` and no matrix.
- **New peel order,** so the curl lasts two pips. At 4 pips o0, o72 and o288 are at stage 1. At 3 pips the mirror pair o72 and o288 is at stage 2, beside the closed wrap.
- **Removed:** the wrap curl sprite and the 2- and 1-pip nods. 2, 1 and 0 pips look as they do today, with the same settle and splay.
- **5 sprites** in all. The fallen petals are unchanged. A drooped petal's fall sprite starts at its angle + rotate.

## Paste into rose-rule.md (its first ```js block, the RULE)

`load_rose_rule` reads only the first js/json block of rose-rule.md. So (1) replace the `lose` line there and (2) add this `curl` key to the same object. The keptCounts follow from `lose`, because `peel_rings` derives them. Nothing is needed in `tools/thinning_overrides.json`. The resulting counts are listed under "Manifest output" so the tests can pin them.

```js
  lose: {                        // lost going from k+1 pips to k pips; the outer petals now last to 3 pips so they can curl
    4: ["o144", "o216"],         // 3 outer petals left (o0, o72, o288), curled (stage 1)
    3: ["o0"],                   // the mirror pair o72 and o288 stays beside the closed bud, rolled further (stage 2)
    2: ["o72", "o288", "wrap"],  // small swirl bud (5 petal refs fall: 2 outer, 2 valleys, the wrap)
    1: ["swirl"],
    0: ["heart"]
  },
  curl: {                        // the petals that stay get sleepy: a shorter, rolled-back sprite + a droop about the petal base
    out: 19.5,                   // curled sprites sit at translate(100 80) rotate(angle) translate(0 -19.5) (fresh petals are at 17)
    shapes: {                    // local: petal centre 0,0 (r12), pointing up/outward. Draw face, tube, hi (stroke), fold (stroke).
      s1: { face: "M-11.97 .8A12 12 0 0 0 11.97 .8L10.4 .8Q1.2 -3.6 -10.4 .8Z",
            tube: "M-10.4 -2.8Q1.2 -7.2 10.4 -2.8A1.8 1.8 0 0 1 10.4 .8Q1.2 -3.6 -10.4 .8A1.8 1.8 0 0 1 -10.4 -2.8Z",
            hi: "M-8 -2.6Q1.2 -5.6 8 -2.6", fold: "M10.4 .8Q1.2 -3.6 -10.4 .8", hiW: .8, foldW: .9 },
      s2: { face: "M-11.71 2.6A12 12 0 0 0 11.71 2.6L10.8 2.6Q1.2 -1.4 -10.8 2.6Z",
            tube: "M-10.8 -1.4Q1.2 -5.4 10.8 -1.4A2 2 0 0 1 10.8 2.6Q1.2 -1.4 -10.8 2.6A2 2 0 0 1 -10.8 -1.4Z",
            hi: "M-8.4 -1Q1.2 -4 8.4 -1", fold: "M10.8 2.6Q1.2 -1.4 -10.8 2.6", hiW: .8, foldW: .9 }
    },
    fill: { face: "#D94668", tube: "#B52C52", hi: "#E0587A", fold: "#8E1F3E" },   // all opaque; strokes are round-capped
    sprites: {                   // imageset plant_rose_curl_<id>, drawn in place in the 200 box
      o0_1:   { unit: "o0",   angle: 0,   shape: "s1" },
      o72_1:  { unit: "o72",  angle: 72,  shape: "s1" },
      o288_1: { unit: "o288", angle: 288, shape: "s1", mirror: true },   // mirror: append scale(-1 1) to the placement
      o72_2:  { unit: "o72",  angle: 72,  shape: "s2" },
      o288_2: { unit: "o288", angle: 288, shape: "s2", mirror: true }
    },
    pips: {                      // at this pip count and below; the smallest matching key wins (as settle). rotate: degrees clockwise about pivot
      4: [ { unit: "o0",   image: "o0_1",   pivot: [100, 74],       rotate: 16 },
           { unit: "o72",  image: "o72_1",  pivot: [105.71, 78.15], rotate: 17 },
           { unit: "o288", image: "o288_1", pivot: [94.29, 78.15],  rotate: -17 } ],
      3: [ { unit: "o72",  image: "o72_2",  pivot: [105.71, 78.15], rotate: 25 },
           { unit: "o288", image: "o288_2", pivot: [94.29, 78.15],  rotate: -25 } ]
    },
    motion: "on a fall, after 0.9 s the fresh (or stage 1) petal cross-fades to the new sprite (0.6 s, the existing fading pattern) and "
          + "rotationEffect eases to rotate (1.4 s, the settle curve). Regrow undoes both. A drooped petal's fall sprite starts at angle + rotate. "
          + "Reduce Motion: the swap and the rotation go with the 0.3 s state animation."
  },
```

## Manifest output (`rule.curl` in PlantThinning.json for plant_rose)

Units resolve to `[ring, petal]` exactly as `settle` does: ring 1 has o0..o288 as 0..4, then wrap 5, swirl 6 and heart 7. The valley ring 0 never curls.

```json
"curl": {
  "sprites": ["plant_rose_curl_o0_1", "plant_rose_curl_o72_1", "plant_rose_curl_o288_1",
              "plant_rose_curl_o72_2", "plant_rose_curl_o288_2"],
  "pips": {
    "4": [
      { "petals": [[1, 0]], "image": "plant_rose_curl_o0_1",   "pivot": [100, 74],       "rotate": 16 },
      { "petals": [[1, 1]], "image": "plant_rose_curl_o72_1",  "pivot": [105.71, 78.15], "rotate": 17 },
      { "petals": [[1, 4]], "image": "plant_rose_curl_o288_1", "pivot": [94.29, 78.15],  "rotate": -17 }
    ],
    "3": [
      { "petals": [[1, 1]], "image": "plant_rose_curl_o72_2",  "pivot": [105.71, 78.15], "rotate": 25 },
      { "petals": [[1, 4]], "image": "plant_rose_curl_o288_2", "pivot": [94.29, 78.15],  "rotate": -25 }
    ]
  }
}
```

The new `lose` changes the rings. These come from `peel_rings`, so check them in the tests:
- Valley ring 0: `keptCounts` `[0, 0, 0, 2, 3, 5]`.
- Petal ring 1: `keptCounts` `[0, 1, 2, 5, 6, 8]` (today `[0, 1, 2, 3, 6, 8]`).
- `maxFallPerPip` must be at least 5. The build's `MAX_FALL` is 5, so this holds. Going from 3 to 2 drops o72, o288 and the wrap: 5 petal refs, counting the two valleys, and all 5 drift.

| pips | outer petals on the head | wrap | swirl + heart |
|---|---|---|---|
| 5 | 5 fresh (identical to today) | fresh | fresh |
| 4 | o0, o72, o288 → `_1` sprites, rotated 16 / 17 / -17 | fresh | fresh |
| 3 | o72, o288 → `_2` sprites, rotated 25 / -25 (mirror pair) | fresh (closed bud) | fresh |
| 2 | none | gone | settle (1, 4), as today |
| 1 | none | gone | heart settle (-3, 6), as today |
| 0 | none | gone | gone, sepals splay, as today |

## Integrator checklist

1. **rose-rule.md:** paste the `lose` and `curl` blocks above into the first js block.
2. **`tools/thin_svg.py`, `peel_manifest`:** for each `curl.sprites` entry, `write_imageset('plant_rose_curl_<id>', svg_header + '<g transform="translate(100 80) rotate(angle) translate(0 -out)">' + face + tube + hi + fold + '</g></svg>')`, appending ` scale(-1 1)` to the placement when `mirror` is set. The reference output is in `parts/rose-curl.svg`. Resolve `curl.pips` units to `[ring, petal]` and emit `rule.curl`.
3. **`PlantThinning.swift`:**
   - Add `Rule.Curl { sprites: [String]; pips: [String: [Entry]] }` with `Entry { petals: [[Int]]; image: String; pivot: [Double]; rotate: Double }`.
   - Add `curl(for: PetalRef, pips:) -> Entry?`, where the smallest key >= pips wins.
   - Add the curl sprites to `imageNames`.
4. **`LayeredPlantView.petal()`:** draw `entry?.image ?? ring sprite`, then `.rotationEffect(.degrees(entry?.rotate ?? 0), anchor: UnitPoint(x: pivot[0] / 200, y: pivot[1] / 200))`. This animates under the existing `.animation(value: shown)`. Cross-fade the sprite change with the `fading` pattern. Start the fall at angle + rotate.
5. **Tests:**
   - At 4 pips, [1,0], [1,1] and [1,4] resolve to their `_1` images. At 3 pips, [1,1] and [1,4] resolve to their `_2` images. At 5 pips nothing applies.
   - The new keptCounts.
   - `fallOrder(fromPips: 3)` has 5 refs, and 5 <= maxFallPerPip.
   - Asset presence for the 5 imagesets.

Budget: each sprite SVG is about 610-620 B, plus 230 B for Contents.json, so about 4.2 KB of PlantLayers growth in all. The manifest grows by about 1 KB.

## Left to tune

- At 3 pips the pair is symmetric: o72 points to 97 degrees and o288 to 263. Their valley petals are not mirrored (valley108 on the right, valley324 on the upper left), so the left side looks a touch fuller. That is fine at tile size.
- The tube is the same red as the valley petals, so where a tube meets a valley the dark fold line is the only edge.
- Mockup captions ("tips curling", "sleepy rose", "little bud" and so on) are labels for review only. Do not copy them into app strings.

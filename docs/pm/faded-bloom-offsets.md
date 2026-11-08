# Faded bloom offsets: paste-ready table and test text

From `docs/pm/faded-bloom-check.md` (static check of all 50 plants; 36 need nothing, 15 need an override as listed there; the ghost orchid and clover are fine as they are). Base spots live in `Rules/FadedBloom.swift` (`FadedBloom.spots`, five fractions of the plant box) and do not change.

Rule, applied after the seeded spot is picked:

`x' = clamp(0.5 + (x - 0.5) * xk + dx, 0.1, 0.9)` and `y' = clamp(y + dy, 0.1, 0.9)`

`xk` below 1 pulls the spot toward the centre line (thin plants); `dy` moves it down; `dx` moves it sideways. Default for any plant id not in the table: `dy 0, dx 0, xk 1` (no change).

## Swift

```swift
/// Per-plant nudges so the faded bloom always lands on the plant (static check of all 50 plants, 2026-11-07).
/// Keyed by plant id: (dy: down, dx: sideways, xk: pull toward the centre line, 1 = none).
static let spotFix: [String: (dy: Double, dx: Double, xk: Double)] = [
    "plant_lithops":          (dy: 0.28, dx: 0,     xk: 0.4),
    "plant_ghost_pipe":       (dy: 0.25, dx: 0,     xk: 0.5),
    "plant_giant_water_lily": (dy: 0.33, dx: 0,     xk: 0.3),
    "plant_lotus":            (dy: 0.33, dx: 0,     xk: 0.3),
    "plant_welwitschia":      (dy: 0.18, dx: 0,     xk: 1),
    "plant_strawberry":       (dy: 0.15, dx: 0,     xk: 1),
    "plant_sundew":           (dy: 0.15, dx: 0,     xk: 0.6),
    "plant_aloe_vera":        (dy: 0.08, dx: 0,     xk: 1),
    "plant_jasmine":          (dy: 0.10, dx: 0.08,  xk: 1),
    "plant_dandelion":        (dy: 0.05, dx: -0.10, xk: 1),
    "plant_corpse_flower":    (dy: 0.06, dx: 0,     xk: 0.2),
    "plant_puya_raimondii":   (dy: 0,    dx: 0,     xk: 0.25),
    "plant_silversword":      (dy: 0,    dx: 0,     xk: 0.2),
    "plant_saguaro_cactus":   (dy: 0,    dx: 0,     xk: 0.3),
    "plant_snapdragon":       (dy: 0,    dx: 0,     xk: 0.3),
]
static let defaultSpotFix: (dy: Double, dx: Double, xk: Double) = (0, 0, 1)

static func adjusted(_ spot: (x: Double, y: Double), plantId: String) -> (x: Double, y: Double) {
    let f = spotFix[plantId] ?? defaultSpotFix
    func clamp(_ v: Double) -> Double { min(0.9, max(0.1, v)) }
    return (clamp(0.5 + (spot.x - 0.5) * f.xk + f.dx), clamp(spot.y + f.dy))
}
```

Apply `adjusted` where `FadedBloomOverlay` converts the picked spot to a position (and anywhere else the spot is read, such as a VoiceOver or test hook). The seeded pick (`spot(seed:plantId:day:)`) is untouched, so which of the five spots is chosen on a given day does not change; only where it lands.

## Unit tests (plain English)

1. **Table size.** The override table has exactly 15 entries, and every key is the id of a real plant in the plant catalog (guards against typos like `plant_aloe` or a missing `plant_` prefix).
2. **Ranges.** For every entry, `dy` is between 0 and 0.4, `dx` is between -0.2 and 0.2, and `xk` is above 0 and at most 1. (The brief's "within 0...1" check: every adjusted spot, for every one of the five base spots and every override, has x and y inside 0.1 to 0.9.)
3. **Adjusted spot always inside the box.** For all 15 overrides and all five base spots, the adjusted x and y are each at least 0.1 and at most 0.9.
4. **Unknown plant unchanged.** For a plant id that is not in the table (clover, rose, a made-up id), the adjusted spot equals the base spot exactly, for all five spots.
5. **Lithops moves down.** For `plant_lithops` and the first base spot (0.40, 0.26): the adjusted point is x = 0.5 + (0.40 - 0.5) * 0.4 = 0.46 and y = 0.54 (within 0.001).
6. **Dandelion moves sideways.** For `plant_dandelion` and the spot (0.60, 0.24): x = 0.5 + 0.1 * 1 - 0.10 = 0.50 and y = 0.29. For (0.40, 0.26): x = 0.30 and y = 0.31.
7. **Narrow plants pull toward the centre.** For `plant_silversword` (xk 0.2) the adjusted x for every base spot is within 0.03 of 0.5, and y equals the base y.
8. **Clamp holds.** A synthetic fix with dy 0.9 puts y at exactly 0.9, and a synthetic fix with dx -1 puts x at exactly 0.1 (test the clamp through `adjusted` with an injected table, or the clamp helper directly).
9. **Seed pick unchanged.** For 200 seeded (seed, plant, day) triples, the index of the chosen base spot is the same before and after this change (the pick function is not touched).
10. **Cue rules unchanged.** The existing faded-bloom cue tests (about 1 day in 3, stage 3 and up, not on a pruned day) pass unchanged.

## Screenshot check (one build look, under the lock)

Plant page with the faded bloom cue forced on for `plant_lithops`, `plant_aloe_vera` and `plant_clover`. Pass: lithops and aloe vera show the bloom touching the plant (not in the sky); clover is identical to before. Values were eyeballed from 150 px renders, so if one still floats, nudge that one row and note it in the report.

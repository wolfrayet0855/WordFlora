# Faded bloom placement check (static, no build): all 50 plants

Method: `FadedBloom.spots` (5 fractions of the plant box) drawn with the real `faded-bloom.svg` at 0.28 of the box, centre at (0.5, 0.4) of its box, exactly as `FadedBloomOverlay` does, over each `Assets.xcassets/Plants/<id>.svg` (200 viewBox = overlay box). Screenshots: scratchpad `bloom-check/all0..all4.png` (light) and `dark0.png` (dark spot check, first 11 plants, viewed: identical geometry, bloom stays legible on the dark ground). The overlay sits on top of the art, so nothing is ever hidden behind leaves; the only failure is floating. The garden card uses a corner badge, not an overlay, so it is unaffected.

## Attached everywhere (s1-s5): 36 plants, no override
bamboo, baobab, bird_of_paradise, black_bat_flower, bleeding_heart, cherry_blossom, chocolate_cosmos, clover (neck just touches the top leaf, acceptable), coco_de_mer, daisy, dragon_blood_tree, fern, franklin_tree, ghost_orchid (lands on the trunk, attached), hibiscus, jade_vine, joshua_tree, king_protea, ladys_slipper_orchid, lavender, marigold, monkey_puzzle_tree, orchid, passionflower, pitcher_plant, poppy, rafflesia, rainbow_eucalyptus, rose, sago_palm, sensitive_plant, sunflower, tulip, venus_flytrap, wollemi_pine.

## Needs an override (one table; hidden never occurs)
Rule: spot' = ( clamp(0.5 + (x - 0.5) * xk + dx, 0.1, 0.9), clamp(y + dy, 0.1, 0.9) ). xk < 1 pulls spots toward the centre line for thin plants.

| plant id | dy | dx | xk | why (floating spots) |
|---|---|---|---|---|
| plant_lithops | +0.28 | 0 | 0.4 | all 5, art tops out ~0.43 |
| plant_ghost_pipe | +0.25 | 0 | 0.5 | all 5, art tops out ~0.5 |
| plant_giant_water_lily | +0.33 | 0 | 0.3 | all 5, flower ~0.55-0.7 |
| plant_lotus | +0.33 | 0 | 0.3 | all 5, flower ~0.6-0.8 |
| plant_welwitschia | +0.18 | 0 | 1 | all 5, plant tops out ~0.45 |
| plant_strawberry | +0.15 | 0 | 1 | all 5, leaves top ~0.58 |
| plant_sundew | +0.15 | 0 | 0.6 | s1-s4, leaves top ~0.55 |
| plant_aloe_vera | +0.08 | 0 | 1 | s1, s2, s5 |
| plant_jasmine | +0.10 | +0.08 | 1 | s1, s3, s4 (diagonal vine) |
| plant_dandelion | +0.05 | -0.10 | 1 | s2, s3 float between the two heads; centres on yellow flower (pivot 0.36, 0.33) |
| plant_corpse_flower | +0.06 | 0 | 0.2 | s1, s2 beside the spike, s4/s5 marginal |
| plant_puya_raimondii | 0 | 0 | 0.25 | s1, s2, s4, s5 beside the narrow spike |
| plant_silversword | 0 | 0 | 0.2 | s1, s2, s4, s5 beside the narrow spike |
| plant_saguaro_cactus | 0 | 0 | 0.3 | s2, s4, s5 beside the trunk |
| plant_snapdragon | 0 | 0 | 0.3 | s1, s4 beside the thin stem (s2/s5 marginal) |

Swift, keyed by plant id (dy, dx, xk):
```swift
static let spotFix: [String: (dy: Double, dx: Double, xk: Double)] = [
    "plant_lithops": (0.28, 0, 0.4), "plant_ghost_pipe": (0.25, 0, 0.5),
    "plant_giant_water_lily": (0.33, 0, 0.3), "plant_lotus": (0.33, 0, 0.3),
    "plant_welwitschia": (0.18, 0, 1), "plant_strawberry": (0.15, 0, 1),
    "plant_sundew": (0.15, 0, 0.6), "plant_aloe_vera": (0.08, 0, 1),
    "plant_jasmine": (0.10, 0.08, 1), "plant_dandelion": (0.05, -0.10, 1),
    "plant_corpse_flower": (0.06, 0, 0.2), "plant_puya_raimondii": (0, 0, 0.25),
    "plant_silversword": (0, 0, 0.2), "plant_saguaro_cactus": (0, 0, 0.3),
    "plant_snapdragon": (0, 0, 0.3),
]
```

## Needs a different treatment
None. Pivot-as-anchor is not needed (and would collapse the 5 spots and cover the real bloom). Values are eyeballed from 150 px renders; re-render after applying (same script) to confirm.

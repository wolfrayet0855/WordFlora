# Faded bloom placement check (static, no build)

How it works: `FadedBloom.spots` are fractions of the plant box (5 spots, y 0.20-0.34). `FadedBloomOverlay` (PlantDetailView only) draws the bloom at `spot * size`, bloom box 0.28 * size, centre at (0.5, 0.4) of its box, neck below. Plant art is `Assets.xcassets/Plants/<id>.imageset/<id>.svg` (200x200 viewBox, same box as the overlay). `PlantThinning.json` `heads[].pivot` is in the same 200 units. The garden card does NOT overlay the plant: it shows a 22/30 pt `FadedBloomView` badge at the card corner (offset 8,4), so nothing can float there.

Composites: scratchpad `bloom-check/light.png`, `dark.png` (dark differs only in background; the overlay is drawn on top of the art, so nothing is ever hidden behind leaves). Red dot = heads pivot.

| plant | s1 (.40,.26) | s2 (.60,.24) | s3 (.50,.20) | s4 (.36,.34) | s5 (.64,.32) |
|---|---|---|---|---|---|
| aloe_vera | floating | floating | attached (tip) | attached | floating (close) |
| pitcher_plant | attached | attached | attached | attached | attached |
| clover | marginal | marginal | marginal | attached | attached |
| bamboo | attached | attached | attached | attached | attached |
| jade_vine (trailing) | attached | attached | attached | attached | attached |
| sunflower (pivots) | attached | attached | attached | attached | attached |
| lithops (succulent) | floating | floating | floating | floating | floating |
| lavender (shrub) | attached | attached | attached | attached | attached |

Floaters: lithops (art tops out near y 0.43, bloom ~0.2 above it), aloe_vera sides (tips ~0.28-0.35). Pitcher plant is fine (tall).

## Recommendation
Cheapest: a small per-plant dy table added to the spot (clamp to box does not help, the bloom is inside the box). Pivot-as-anchor would cover the real bloom and collapse the 5 spots, so keep it for a later pass. Unchecked: the other ~42 plants, so sweep low or ground-hugging ones (fern, sensitive_plant, venus_flytrap, rafflesia, welwitschia, lithops-like) with the same composite script.

| plant | dy (fraction of box) | dx |
|---|---|---|
| plant_lithops | +0.28 | pull toward 0.5: x = 0.5 + (x-0.5)*0.4 |
| plant_aloe_vera | +0.08 | none |
| plant_clover | +0.04 | none |

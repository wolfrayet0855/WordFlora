# Tending animations and pot collection (brainstorm, 2026-11-03)

Source: Sonnet brainstorm agent, reviewed by the lead. SwiftUI only, existing art (tool_can/trowel/lamp imagesets, SF Symbols), each effect under 2 s, overlay on the plant (no layout shift), non-interactive, Reduce Motion fallback, paired with existing sound events and light haptics.

## Animations
- **Water pour (1.5 s):** can (tool_can_t{tier}) fades in upper right, tilts about -35 degrees, 12-16 blue drops fall to the plant, ripple at the soil line, plant gives a soft 1.04 scale "drink". Reduce Motion: static can 0.6 s and a fading drop cluster.
- **Soil scoop (1.4 s):** trowel arcs from a soil mound to the pot rim, about 10 brown dots drop in, soil level rises a few points. Reduce Motion: level fades in.
- **Sun glisten + flutter (1.8 s):** sun fades in from the top corner (scale 0.7 to 1.0), slow rays, 5-7 sparkles twinkle on the leaves, warm tint sweep, plant flutters (small quick sway). Reduce Motion: static glow and 3 fading sparkles.
- **Repot (1.8 s):** old pot slides out, plant lifts and settles, new pot slides in, soil falls; favourite soil gives a sparkle burst. Needs plant art WITHOUT the pot baked in (check Assets.xcassets/Plants).
- **Tap hello:** hearts and sparkles burst from the plant while it stays centred.

## Pot collection (cosmetic only, no gambling)
- Data: `potsJSON` + `activePotId` on PlayerProfile (like toolsJSON); optional per-plant `potId`; merge = union, never removed; missing pot falls back to plain blue.
- Earning (fixed, predictable): plain blue at start; terracotta on first plant; sage glaze at 10 plants; shell/moon with level completions; sparkly at a level-1 completion or 150 shed points. Silhouettes in the shed show how to unlock. No random drops, never paid-only for kids.
- Shed: "Pots" grid below tools. Repot sheet: "Pick a pot" row above the soil choices; pot change is free, soil costs a scoop.

## Neglect
Decision pending with the owner: dormant "visual seed" after about 14 days without care (all progress kept; wake by winning a word, butterfly catching or a harder word). Quiet Garden and Calm exempt. See reinforcement-principles.md.

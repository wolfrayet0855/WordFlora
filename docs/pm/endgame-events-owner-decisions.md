# Endgame and weather events: owner decisions (2026-11-04)

Owner answered "all yes" to the recommendations in docs/pm/endgame-and-events-spec.md section 9:

1. Variant 1 "Weather, not loss" for everyone, plus Variant 2 "Wild Weather" as a 13+ opt-in (Calm off, never under 13). No true stored drop.
2. The word level never drops. Wild Weather only dips the SHOWN stage of up to 4 plants for up to 4 days, computed at display time.
3. Frequency: about one event every 19 days (weatherBlockChance 0.75).
4. Calm mode and under-13: weather off by default (a grown-up may turn on looks-only weather).
5. Endgame: the Grand Garden package and ceremony direction A (Gardener's Crown at 50 of 50, gold crown at all 5 levels in bloom, golden blooms, Daily Bloom ranks, Visitors' book). No prestige resets, no friend gardens, no leaderboards.
6. Forecast notification: opt-in, passive level, shares the one daily reminder slot.

Build order and tickets: spec section 11 (E-1 to E-12, G-1 to G-5, Q-1). Build starts after the current workers finish (machine load), rules and tests first.

## Owner rulings, 2026-11-05 (override parts of items 1 and 4)
- **Wild Weather at any age:** players of any age, including under 13, may turn Wild Weather on. It stays an explicit opt-in toggle, off by default, never prompted, with the same calm copy and confirmation; it never punishes and the word level never drops. The 13+ gate is removed (`WeatherLook.wildAvailable` no longer reads the age band).
- **One Calm control:** the existing Calm mode toggle decides. Calm on = weather hidden and off (no chip, card, banner, widget line, reminder or Wild Weather). Calm off = weather and the Wild Weather opt-in are available at any age. There is no separate grown-up "looks-only weather in Calm" switch. Under 13 starts in Calm, so weather starts off for them. Quiet Garden also hides all weather.
- **No cuts without approval:** no feature may be cut or deferred without the owner's approval; report time pressure instead.

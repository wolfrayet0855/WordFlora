# Endgame and garden weather: spec (2026-11-04, design only, awaiting owner decision)

Status: DESIGN. No Swift, project, asset or test changes in this phase. Implementation starts after the owner picks the options in section 9.

Inputs: `docs/research/endgame-disasters-design.md` (game design, ethics), `docs/research/endgame-disasters-tech.md` (Apple, law, CloudKit), `docs/pm/endgame-events-audio-plan.md` (sound), mockups in `design-preview/events/` and `design-preview/endgame/`, and the rules in `WordFlora/Rules/{LoveEngine,LifeStats,WakeChallenge,WakePuzzle,ProgressionPolicy,Economy,CopySafety,PotCatalog,Badges,ToolEngine}.swift` and `WordFlora/Storage/{DataReconciler,GardenBackup}.swift`.

Owner request (verbatim): "if someone beats the game, brainstorm what should happen, that means collect all flowers, etc. I think we should have random days like droughts, termites, hurricanes/natural disasters that drop levels for people, but then offer a really hard puzzle to gain some back."

## 0. Summary

- **Endgame:** two moments and a calm tail. (1) *Every plant found* (50 of 50): the one-time **Grand Garden** reveal and the **Gardener's Crown** (a flower crown, kept forever). (2) *Whole garden in full bloom* (all 5 garden levels): the crown turns gold. After that, **Golden blooms**: each plant can earn a golden look through care on 7 different days. Also **Daily Bloom ranks** (a count, never a streak) and a **Visitors' book**. Weather keeps the finished garden lively. Plus never gates any of it.
- **Weather:** about one weather day every 19 days. It never comes in a player's first week, two never come within 8 days of each other, and every one is forecast the day before. The engine is a pure function of a per-player seed and the day, so devices agree with no server.
- **Two variants:**
  - **Variant 1, "Weather, not loss" (recommended for everyone):** only the look changes. One tending action or a hello mends a plant.
  - **Variant 2, "Wild Weather" (the owner's literal version, recommended only as an opt-in for grown-ups):** the *shown* stage of up to 4 plants drops by 1. Earned values are never touched, and a hard puzzle restores everything at once.
- **Ethics verdict:** a real, stored drop of earned progress for children is not acceptable. It breaks the standing ruling, gets undone by our own max-merges, and fits the manipulative-design patterns flagged in children's-app research (Radesky et al. 2022) and by regulators. A shown-only drop is acceptable when it is opt-in, 13+ only (never under 13, gate or not), Calm off, bounded, always mended by play, and never sold.

## 1. Rulings this spec keeps (no exceptions)

1. Nothing earned is ever removed: `stage`, `growthPoints`, `earnedCount`, word level, collection, pots, badges and garden-level completion never go down in storage. Any setback is a **derived overlay computed at display time** (tech constraint 1: a stored drop would come back on the next `DataReconciler` max-merge or backup restore anyway).
2. Copy is positive-only, grade 2-3, and passes `CopySafety` (banned: miss, lonely, alone, waiting, abandon, neglect, forgot, forget, die/dies/died/dying, dead, lost, empty, left, broken, lose streak, broken streak, last chance, hurry, now or never, expires, only, last, smart, genius, talented, best gardener, better than, beat). Also avoid: save, rescue, danger, destroy, warning, alert, too late, countdown.
3. Quiet Garden: no weather, no forecast, no puzzle prompts. Calm mode (the default under 13 and for unknown age): no weather by default (section 4.8).
4. Shelter, recovery and the weather puzzle are never sold: not by IAP, not by Plus, not by a rewarded ad (Guideline 5.6, 3.1.1, 2.5.18). Plus may add cosmetic weather extras later (a rainbow sky skin) that change no outcome.
5. No countdowns, timers, Live Activities, red, alarm icons or sirens. Weather is never tied to being away.

## 2. Endgame

### 2.1 Definitions (pure, from data we already keep)
- `allFound` = 50 of 50 plants with `earnedCount > 0` (the same "plants grown" count `PotCatalog.stats` uses).
- `allFullBloom` = `ProgressionPolicy.gardenLevelComplete(l)` for l in 1...5 (earned stage, never the shown stage).
- Both are computed every time, like pot unlocks. We store only the *date the ceremony was seen*, so it plays once per player on any device.

### 2.2 What happens
| Moment | Trigger | Experience | Stored |
|---|---|---|---|
| Grand Garden | `allFound` becomes true (after the 50th plant's normal "New plant found!" card) | The garden reveal, then the Gardener's Crown appears on the wordmark, then a "What's next" card (see 2.3). Soft petals at most. Reduce Motion: a still image with a cross-fade. Replay from Badges. | `PlayerProfile.crownSeenAt: Date?` (merge min) |
| Golden crown | `allFullBloom` | A smaller moment: the crown's petals turn gold. "Your whole garden is in full bloom." | `goldCrownSeenAt: Date?` (merge min) |
| Level fully grown (x5) | `gardenLevelComplete(l)` | A small bloom wave on that level's row and the existing pot unlocks (sunflower L3, starlight L5). | none (computed) |

The Crown is shown, not owned. It is computed from `allFound`, so it can never be taken away; `crownSeenAt` only stops the ceremony repeating.

### 2.3 After the ending: the calm tail
1. **Golden blooms** (recommended first). Once `allFound`, every plant at stage 4 can earn a golden look through **tending** (water, feed, sun or prune; a hello does not count) on 7 different days.
   - The days need not be in a row, and each plant counts at most one a day. A hello is left out so a golden garden is not 7 days of tapping hello (review fix).
   - It needs no new art beyond one gold tint or shader.
   - To make it read as a story and not a checklist, **Home features one plant a day**, the nearest to golden: "Daisy is 3 days from golden."
   - When all 50 are golden: "Every plant is golden. What a garden!"
   - Fields: `PlantCollectible.goldenDays: Int = 0` (merge max) and `goldenDayKey: Int = 0`. The key uses `WeatherDay.key`, and the pair merges like `waterDay`/`waterToday`.
   - Golden is computed as `goldenDays >= Economy.goldenDaysNeeded`.
2. **Daily Bloom ranks.** Seedling (1), Sprout (10), Bud (30), Bloom (75), Full bloom (150), Evergreen (300), counted from the existing `dailyBloomsDone` badge counter. It is a total, not a run of days in a row, so it only goes up and a day off never lowers it. No leaderboard. (The app's separate opt-in streak display is unchanged.)
3. **Visitors' book.** A page for every visitor species seen (the `visitorSpecies` counter exists), plus the weather stickers from section 4.6.
4. **Weather** keeps going (section 4) and gives a finished garden something to prepare for.
5. **Later, not in this plan:** seasonal cultivars in slices of 10 (art-heavy, L) and word packs (blocked on the fact-check backlog). Each will need a new counter that only goes up (tech constraint 2), never a reset.
6. **Rejected:** prestige resets or "new game plus" that clears the garden (it breaks the ruling and the max-merges), a friend or mentor garden with real people (child data), leaderboards, and charity or real-tree tie-ins.

### 2.4 Plus line
The ceremony, Crown, golden blooms, ranks, Visitors' book and weather are free. Plus stays cosmetic: pots, themes and the Daily Bloom archive. The ending screens show no Plus, ads or offers (`PlusOfferPolicy` must skip the session that shows the ceremony).

## 3. Weather engine (shared by both variants)

New pure file `Rules/WeatherEngine.swift`. No stored "event happened" rows.

### 3.1 Day key
`dayKey(date)` = days since 2026-01-01 in **`Calendar(identifier: .gregorian)` with `TimeZone.current`**. Do not reuse `WakePuzzle.day`, which builds its epoch with `Calendar.current` and disagrees on Buddhist or Japanese calendar settings (tech constraint 4). Ship it as `WeatherDay.key(_:)` and leave `WakePuzzle` alone.

### 3.2 Seed and start
- `PlayerProfile.weatherSeed: Int64 = 0`. 0 means unset. When unset, generate a random value with `SystemRandomNumberGenerator`, never from a device or user id (tech AVOID 17).
- `PlayerProfile.weatherStartDay: Int = 0`, set together with the seed to `dayKey(createdAt) + Economy.weatherFirstWeekDays` (7).
- Merge (`DataReconciler`, and `GardenBackup` restore): the **pair** with the smaller nonzero `weatherStartDay` wins, and on a tie the smaller seed. This is commutative, so every device settles on the same pair. Before the first sync two devices may briefly show different forecasts; the reconcile at launch or foreground fixes that within one launch.

### 3.3 Schedule (stateless)
```
block      = (day - startDay) / blockDays          // blockDays = 14
offsetDay  = day - startDay - block * blockDays
rng        = SplitMix64(seed ^ (UInt64(block) &* 0x9E3779B97F4A7C15) ^ algoVersionSalt)
hasEvent   = rng.unit() < blockChance              // 0.75
eventOffset= rng.next() % eventWindow              // 0..6
event(day) = day >= startDay && hasEvent && offsetDay == eventOffset ? kind(block) : nil
forecast(day) = event(day + 1)
```
Properties, all tested:
- No event before day 7.
- Two events are at least 8 days apart (offset 6, then the next block's offset 0). So it is never two days in a row, never more than one in any 7 days, and the mean gap is 14 / 0.75 ≈ 19 days. Quiet stretches happen: each block has a 25% chance of no event, so a gap can run 14k + 6 days. That is fine, because weather is a treat and not a schedule.
- **Kind** is chosen by **event ordinal**, not by block, because skipped blocks would otherwise let two events in a row match (review fix).
  - `ordinal` = the number of blocks from block 0 up to this block that have an event. This is a pure count of fewer than about 30 blocks a year, so it is cheap.
  - `kind = sequence[ordinal]`, where `sequence` is a run of seeded bags of 10: 3 big (dry spell, busy bugs, big wind) and 7 gentle (frost x2, hot day x2, hail, puddles x2), so 30% of events are big.
  - Each bag is shuffled by rejection sampling until no two neighbours match (bounded tries, then a fixed safe order).
  - If a bag's first kind equals the previous bag's final kind, its first two kinds swap. A swap never touches a bag's final slot, so this needs no recursion, and consecutive *events* never share a kind.
- **Versioning:** `Economy.weatherAlgoVersion` plus a cutover dayKey. A future change (a new kind) applies only from its cutover day, so an update never rewrites a forecast already shown (tech constraint 15).
- **Clock guard:** `PlayerProfile.weatherHighWaterDay: Int = 0` (merge max) holds the highest dayKey the app has computed. If today's key is lower than `weatherHighWaterDay - 1`, the device clock went back: show no event and no forecast until the clock catches up. The one-day slack means a family's iPhone and iPad in two time zones do not silence each other (review fix).
- **Forward clock jumps** would let a player farm puzzle rewards. Two guards stop this:
  - **Presence rule** (tech SHOULD 11): a weather look, and its puzzle and reward, appear only if the app is opened between the event day and the end of its linger. Coming back after the linger shows nothing.
  - **Award cap:** at most one weather reward per `Economy.weatherAwardGardenDays` (7) Garden Days, counted from the rescued-days list. Farming would then need a week of separate daily opens per reward, so it is not worth doing.

### 3.4 Gating
Weather is shown (forecast, event, puzzle) only when **all** of these are true:
- 5 or more plants found;
- at least 2 tending actions ever (the waterings and feeds badge counters);
- Quiet Garden is off;
- the Garden weather setting is on (section 4.5);
- `today >= weatherHighWaterDay - 1`.

The schedule itself is not gated: a gated day simply shows nothing, so turning gating on later never brings a pile-up.

The first day all of these are true is stored as `PlayerProfile.weatherGatedFromDay: Int = 0` (merge: min of nonzero values). From then on the found and tends conditions count as met for good, so a reconcile cannot flip weather off and on (review fix).

### 3.5 Kinds, plant traits and who is affected
Kid-facing names (also used in the mockups): **Dry spell** (drought), **Busy bugs** (termites), **Big wind** (hurricane), **Frosty night**, **Hot day** (heat wave), **Hail shower**, **Big puddles** (flood).

New data: `Plants.json` gets `"traits": [...]` for each of the 50 plants (data only, tested to cover all 50). Draft, to be checked by the plant-data owner:

| Trait | Plants |
|---|---|
| desert | Saguaro Cactus, Aloe Vera, Welwitschia, Joshua Tree, Lithops, Dragon Blood Tree, Baobab |
| succulent | Aloe Vera, Lithops, Sago Palm |
| carnivorous | Venus Flytrap, Pitcher Plant, Sundew |
| aquatic | Lotus, Giant Water Lily |
| bog | Venus Flytrap, Pitcher Plant, Sundew, Ghost Orchid |
| hardyTree | Baobab, Dragon Blood Tree, Joshua Tree, Monkey Puzzle Tree, Wollemi Pine, Sago Palm |
| woody | Rose, Jasmine, Bamboo, Cherry Blossom, Franklin Tree, Rainbow Eucalyptus, Passionflower, Jade Vine |
| flexible | Bamboo, Clover, Dandelion |
| tall | Sunflower, Snapdragon, Bird of Paradise, Corpse Flower, Coco de Mer, Rainbow Eucalyptus, Puya raimondii |
| tropical | Orchid, Hibiscus, Bird of Paradise, Rafflesia, Passionflower, Jade Vine, Coco de Mer, Black Bat Flower, Sensitive Plant, Ghost Orchid, Corpse Flower |
| shade | Fern, Ghost Pipe, Bleeding Heart, Lady's Slipper Orchid, Black Bat Flower |
| alpine | Silversword, Puya raimondii, King Protea |
| bigLeaf | Hibiscus, Giant Water Lily, Bird of Paradise, Corpse Flower |

Effect table (`WeatherEngine.effect(kind, traits) -> .shrugs | .light | .full`):

| Kind | Shrugs it off | Full effect | Everyone else |
|---|---|---|---|
| Dry spell | desert, succulent | aquatic, bog, shade | light |
| Busy bugs | carnivorous, aquatic, desert | woody | light |
| Big wind | desert, hardyTree, flexible | tall | light |
| Frosty night | alpine, hardyTree | tropical | light |
| Hot day | desert, succulent | shade, aquatic | light |
| Hail shower | desert, hardyTree | bigLeaf | light |
| Big puddles | aquatic, bog | desert, succulent | light |

Shrugs wins over full when a plant has both traits; for example Venus Flytrap shrugs off busy bugs. A cap keeps it weather and not a wipe: at most `ceil(0.4 x found)` plants show the full effect, picked in a deterministic order (FNV-1a of `plantId` and the dayKey), and any others over the cap show the light look. Shrug-off plants get a proud line ("Lithops loves dry days!"). The research says this is the most delightful part, so every kind needs one or more catalog plants that shrug it off.

### 3.6 How long it shows, and what mends it
- **Witnessed first (review fix).** An engaged player's daily hello would otherwise mend the plant before they ever saw the weather. So the look starts when the player first opens the garden or Home on or after the event day. That moment is stored as `PlayerProfile.weatherSeenAt: Date?` (merge max; it counts only when its dayKey is on or after the event day).
- **Mended** means `max(lastTendedAt, lastLovedAt) > weatherSeenAt`, so any tending action or a hello *after seeing it* mends the plant. Otherwise the look fades by itself after `weatherLingerDays` (3), or after `calmLingerDays` (1) in Calm. No new plant field is needed.
- Only the latest event can show. The gaps are 8 days or more and the look lasts 3 days, so events never stack.
- A player who was away sees, at most, the look of the latest event while it is still within its 3 days. Coming back never adds weight.

### 3.7 Shelter tools (Shed, "Weather helpers")
| Helper | Shelters from |
|---|---|
| Shade cloth | Dry spell, Hot day |
| Bug cover (no sprays) | Busy bugs |
| Wind net | Big wind |
| Frost cloth | Frosty night |
| Garden umbrella | Hail shower |
| Raised bed | Big puddles |

- **How you get them:** all six helpers arrive together as a free **Weather kit** with the player's first forecast ("A weather kit for you, from the Shed."). Stored as `PlayerProfile.weatherKitAt: Date?` (merge min). Review fix: per-kind helpers worked out from the schedule could be taken away by a seed merge, which would be a visible removal. No prices, no Plus tags and no locked helpers.
- **Set out:** one tap on the forecast card or in the Shed, on the day before or on the event day. Stored as `PlayerProfile.weatherShelterDay: Int = 0` (merge max; the event dayKey it covers).
- **Shelter changes the picture; it does not erase it (review fix).** A sheltered garden still shows the weather: rain beads on the wind net, frost on the cloth, puddles around the raised bed. The plants underneath stay snug and upright, and shrug-off plants cheer. In Variant 1, sheltered plants need no mending. In Wild Weather, shelter halves the setback (section 4.2). Preparing is visible, and the reward is seeing your plants cosy in the storm.
- **Pots:** no weather effect. This keeps Plus pots purely cosmetic and keeps the rules simple. (Rejected: weighted pots resisting wind, because it would make some Plus pots better.)

### 3.8 Forecast and notification
- **In app:** a forecast card on Home and in the Shed all day on the day before (mockup `events/warn-*`), plus a "Tomorrow: windy" chip in the garden header. Steps: give a drink or a hello today, set out the helper, and "Got it". On the event day a soft banner replaces it.
- **Widget:** the widget computes its own line from the shared store and the same pure engine ("Tomorrow: a little windy. Your garden is ready."). No background task is needed (tech constraint 10).
- **Notification:** opt-in only (Settings: "Tell me about garden weather", off by default, hidden under 13). It is not a separate request: it **replaces the content of the existing one-a-day reminder** on a forecast day, because `Reminders.plan()` removes all pending requests. It uses the `.passive` level and the existing quiet hours (never 21:00-08:00). Never `.timeSensitive` or `.critical`. The title includes "garden" so a summary can never read as a real weather alert ("Garden forecast: a big wind tomorrow"). No Live Activity.

### 3.9 Sound and motion
See `docs/pm/endgame-events-audio-plan.md`. Beds (wind, soft storm, dry-day hum) fade in over at least 400 ms and duck like thunder. One-shots are relief chime, termite tick, frost twinkle, hail patter and grand flourish. All eight files come to about 260 KB. Nothing plays with sound off, in Calm, in Quiet Garden or in Low Power, and all use the `.ambient` session. The thunder gate rules apply (one roll at most every 3 minutes). Flashes are at most 1 per 8 s and none when Reduce Motion or Dim Flashing Lights is on (WCAG 2.3.1). Reduce Motion gets still art with a cross-fade.

## 4. The two variants

### 4.1 Variant 1, "Weather, not loss" (RECOMMENDED for everyone with weather on)
- **What changes:** only how plants look (droop, cracked soil, crumbs and tiny nibbles, bent stems with rain, frost rim, haze, hail pellets, puddles) and a soft "resting" tint on the stage path (mockup `events/bar`). Growth keeps adding as normal. Every number and value stays as it was.
- **Mend:** one tending action or a hello per plant (section 3.6), or the weather puzzle mends all of them at once, or it fades in 3 days.
- **Why play the puzzle: gain something, not only get back (review fix).** Every bonus is fixed and named before you start, never random:
  - **one word toward the next plant** (it counts like a Daily Bloom win, at most one per event; at a full collection it is one golden day for a weathered plant instead);
  - the **next weather sticker** in a fixed order (7 stickers; any kind's puzzle earns the next one, so no sticker is tied to a rare kind and there is no FOMO);
  - a step on a new `weathered` badge (tiers 1, 3, 7, 15).
  - No water or soil is given. Skipping costs nothing earned; it only means that word comes from a normal round instead.
- **Worst case for a player who ignores weather:** a few plants look windswept for up to 3 days, about every 19 days.

### 4.2 Variant 2, "Wild Weather" (owner's literal version, opt-in only)
Bounded so it can never become a real loss:
- **Who:** 13+ (age band set and not under 13), Calm off, Quiet Garden off, turned on by the player in Settings with a confirmation card. **Never for under 13 or unknown age, not even behind the parental gate.** A parental gate does not make a threat to progress right for a 7-year-old (review fix). The mode is also explained in the App Store description, not only in Settings. It is off by default, nothing ever prompts the player to turn it on, and one tap turns it off with immediate effect. Stored as `PlayerProfile.wildWeather: Bool = false`. On a duplicate-profile merge, **off wins** (AND).
- **What drops:** the **shown stage** of affected plants, by 1, on **big events only** (dry spell, busy bugs, big wind). Gentle events stay looks-only.
  - `shownStage = stage - setback` with `setback` in {0, 1}, computed and never stored.
  - At most `Economy.wildMaxPlants` (4) plants per event, picked from the full-effect plants in the deterministic order. A sheltered garden halves that to 2: in Wild Weather a helper softens the event without cancelling it, so preparing still matters for players who chose the challenge.
  - Never below stage 1, so a plant never looks un-found.
- **What never drops:** stored `stage`, growth, earned count, the collection, **word level** (it decides which words and levels you can play; lowering it would lock content), pots, badges, the Crown and golden blooms. All of these read earned values. Garden-level completion and its pot read earned stage. The level map's ring may show the shown stage with a dashed "mending" segment, which is the visible "level drop" the owner asked for.
- **Getting it back:**
  1. **The hard puzzle** (section 5, Storm tier) restores **every** plant at once, on the event day or the 3 days after, and also gives the forward gain from 4.1 (one word toward the next plant, the next sticker, a badge step). This is the "really hard puzzle to gain some back", made generous: you get it all back, plus a little more.
  2. **Tending**: care for a plant on one day and it stands tall again **the next day** (`dayKey(max(lastTendedAt, lastLovedAt)) >= eventDay` and `today > that day`). That is slower than the puzzle, so the puzzle has a purpose, but play alone always mends.
  3. **Time**: it mends by itself after `wildLingerDays` (4). **Guaranteed full recovery within 4 days, without paying, without puzzles.**
- **Worst case:** up to 4 plants show one stage lower for up to 4 days. That happens on about 30% of events, so roughly once every 60 days.
- **Rejected sub-option "2b" (true drop):** writing a lower `stage` or word level. It breaks the ruling, the max-merges in `DataReconciler` and `GardenBackup` would undo it on the next sync or restore anyway, and its harm risk for children is high. Not offered.

### 4.3 Side by side
| | Variant 1 Weather, not loss | Variant 2 Wild Weather (opt-in) |
|---|---|---|
| Who | everyone with Garden weather on (13+ default on; Calm/under 13 off unless a grown-up turns it on) | 13+, Calm off, opted in |
| What changes | looks only | looks, plus shown stage -1 on up to 4 plants (big events) |
| Stored values touched | none | none (derived overlay) |
| Word level | never | never |
| Shelter | weather still shows, but plants stay snug, so no mending is needed | weather shows; halves the plants affected (4 to 2) |
| Puzzle | optional; mends all; sticker and badge step | optional, harder tier; restores all at once; sticker and badge step |
| Mend by play | one action or hello, at once | care on one day, stands tall the next day |
| Mend by time | 3 days | 4 days |
| Cost to recover | free | free |
| Data fields | seed, start day, high-water day, shelter day, rescued days | the same plus `wildWeather` |
| Store and age-rating risk | low (gentle art, infrequent) | low to medium (keep art gentle; still not "frequent fear") |
| Ruling fit | full | in data yes; in feel it is a shown setback, so the owner must accept that |

### 4.4 Ethics verdict (honest)
- No study measures level drops in children's games specifically. The best evidence is indirect:
  - Radesky et al. 2022 (JAMA Netw Open 5(6):e2217641): about 80% of apps used by 3-5 year olds had manipulative design, and "parasocial pressure" and "time pressure" to protect progress are coded as manipulative.
  - The UK ICO Children's Code standard on nudges says not to nudge children toward extended use.
  - EU CPC enforcement treats pressure on children as unfair.
  - Loss aversion replicates in direction, though its size varies.
- A drop the child did not cause, fixed by returning or by solving something, is exactly the pressure pattern. For under-13 players a shown drop is therefore off the table, whatever the copy says.
- For adults, the evidence from hardcore modes (Minecraft Hardcore, Terraria's harder modes) is that self-chosen stakes feel like agency, not manipulation. Choice, a visible off switch and a guaranteed recovery are what make it fair.
- Verdict: **Variant 1 for everyone; Variant 2 only as an opt-in Wild Weather mode for 13+.** The opt-in is the right way to give the owner what he asked for, and the honest cost is low uptake (we expect few players to turn it on). Selling shelter or recovery would turn a fair game mechanic into a 5.6 "manipulative practice" problem. Never.

### 4.5 Calm, Quiet Garden, age (both variants)
| Context | Weather (Variant 1) | Wild Weather |
|---|---|---|
| Quiet Garden | off, hidden | off, hidden |
| Calm mode (default under 13 / unknown) | "Garden weather" setting defaults off. A grown-up may turn on looks-only weather: no puzzle prompt, plants mend by themselves after `calmLingerDays` (1), and no forecast card on Home (only the small garden chip), so there is no to-do list for a young child | hidden, never available |
| 13+, Calm off | on by default, forecast and optional puzzle | opt-in |
| Reduce Motion / Dim Flashing Lights / Low Power | still art, no flashes, no beds in Low Power | same |
| Plus | no effect on outcomes | no effect |

`AppSettings.gardenWeather: Bool` is device-local like `calmMode`. It defaults to `!calmMode`.

### 4.6 Weather stickers
Seven fixed stickers (Rainbow, Frog friend, Ladybird, Kite, Snowflake, Sun hat, Puddle boots), ids `weather.1` to `weather.7`, are added to the existing `StickerAlbum`.
- The *n*-th solved weather puzzle earns sticker *n*, whatever the kind, so no sticker depends on a rare kind turning up (review fix: per-kind stickers would have meant about a 140-day wait, which is FOMO).
- Stickers merge by union.
- The card says what comes next before you play ("Solve it for the Frog friend sticker").
- Nothing is random. After all 7, the puzzle still gives the word and the badge step.

## 5. The weather puzzle (reuses `WakePuzzle`)

Name: **"Weather puzzle"**. The design draft's "Storm Chest" was renamed because "chest" reads as a loot box. Entry: the event banner, the plant page of a weathered plant, and the forecast card on the day itself. One puzzle per event covers the whole garden.

| Tier | Who | Puzzle |
|---|---|---|
| Gentle | Variant 1 and Calm (when a grown-up turned weather on) | today's `WakePuzzle.make` exactly as built (5-10 letters, anagram or missing vowels) |
| Storm | Variant 1 at 13+ (player picks "A harder one" chip), and always in Wild Weather | `WakePuzzle.make(... tier: .storm)`, see below |

Storm tier changes (an additive parameter, default `.gentle` so the wake flow is untouched):
- **Answers** are plant names of 7-14 letters. One-word and two-word names are allowed; three or more words (Giant Water Lily, Bird of Paradise, Lady's Slipper Orchid) and names with apostrophes are left out. That leaves about 13 one-word and 17 two-word candidates.
  - A two-word name is stored as **letters only plus `gaps: [Int]`** (the slot indices after which a gap is drawn). `normalized`, `isCorrect` and the board keep comparing letters only (review fix: they strip spaces today).
  - `candidates(from:tier:)` gains the tier parameter, and the gentle tier's output is unchanged.
- **No given letter**, even in the missing-vowels variant: every slot is open, and one **decoy tile** that is not in the answer is added. `isCorrect` is unchanged because it already checks letters and slot count; the decoy is simply never needed.
- **Peek ladder:** the first peek is free at once, then one every 30 s (`peekInterval`), and a peek never fills the final spot. With unlimited peeks every puzzle is finishable at any pace, which makes it hard but always fair.
- **No timer** and nothing at stake while playing. "Not quite. Try again." Tries are unlimited.
- **Two parts (Wild Weather only):** the word, then a short butterfly catch of 3 (`WakeRule.butterflyGoal`). Either part can be swapped for the other after two tries (`isEasier(dreamsInARow: 2)`).
- **Daily cap:** at most 3 fresh puzzles a day per event (a "New puzzle" button). After that: "That is plenty for today. Your garden will mend with care." It stops a long session and is not a lock: the plants still mend by care and time.
- **Skip:** "Skip for now. Care will help it mend." The button is the same size as Start, there is no confirmation and no cost.
- **Accessibility:** VoiceOver labels for slots and tiles (reuse the wake board), 44 pt targets, Dynamic Type layouts at accessibility sizes, and read-aloud of the hint.
- **Seed:** `stableHash("weather") ^ eventDayKey ^ attempt`, so the same puzzle shows on every device.
- **Stored:** `PlayerProfile.weatherRescuedDays: [Int] = []` (event dayKeys solved; union merge; trimmed to the last 30). Also `weatherPuzzleDay: Int = 0` and `weatherPuzzleCount: Int = 0`, merged like `waterDay`/`waterToday`. If two devices solve the same day at once, the union stays idempotent.

## 6. Pure functions (signatures for TDD)

```swift
enum WeatherKind: String, CaseIterable, Codable { case drySpell, busyBugs, bigWind, frostyNight, hotDay, hailShower, bigPuddles
    var isBig: Bool }
enum WeatherEffect { case shrugs, light, full, snug }
enum WeatherDay { static func key(_ d: Date, timeZone: TimeZone = .current) -> Int }   // Gregorian, epoch 2026-01-01

enum WeatherEngine {
    static func event(day: Int, seed: Int64, startDay: Int, economy: Economy) -> WeatherKind?
    static func forecast(day: Int, seed: Int64, startDay: Int, economy: Economy) -> WeatherKind?   // event(day + 1)
    static func latestEvent(onOrBefore day: Int, within: Int, seed: Int64, startDay: Int, economy: Economy) -> (kind: WeatherKind, day: Int)?
    static func effect(_ k: WeatherKind, traits: Set<String>) -> WeatherEffect
    static func affected(_ k: WeatherKind, plants: [(id: String, traits: Set<String>)], day: Int, cap: Double) -> [String: WeatherEffect]
    static func isGated(found: Int, tends: Int, quietGarden: Bool, weatherOn: Bool, today: Int, highWater: Int) -> Bool
    static func kitArrives(forecastToday: Bool, gated: Bool, kitAt: Date?) -> Bool          // all six helpers at the first forecast
    static func mayAward(rescuedCount: Int, gardenDays: Int, economy: Economy) -> Bool        // anti-farm cap
    static func ordinal(block: Int, seed: Int64, startDay: Int, economy: Economy) -> Int      // events so far, for the kind sequence
}

enum WeatherLook {   // what the plant page draws
    struct Input { var kind: WeatherKind?; var eventDay: Int; var today: Int; var effect: WeatherEffect;
                   var lastCareDay: Int?; var sheltered: Bool; var rescued: Bool; var wild: Bool; var stage: Int;
                   var rank: Int /* index among full-effect plants */ ; var economy: Economy }
    struct Output: Equatable { var look: WeatherEffect?; var setback: Int; var shownStage: Int; var line: String }
    static func compute(_ i: Input) -> Output
}

enum EndgamePolicy {
    static func allFound(_ plants: [PlantProgress]) -> Bool
    static func allFullBloom(_ plants: [PlantProgress]) -> Bool
    static func shouldShowCeremony(allFound: Bool, seenAt: Date?) -> Bool
    static func goldenDays(current: Int, lastKey: Int, careKey: Int) -> (days: Int, key: Int)   // +1 at most once a day
    static func isGolden(days: Int, economy: Economy) -> Bool
    static func bloomRank(dailyBloomsDone: Int) -> BloomRank
}
enum WeatherCopy { static func all(name: String) -> [String] }   // CopySafety-tested
enum EndgameCopy { static func all(name: String) -> [String] }
```

`WeatherLook.compute` rules:
- Nothing shows if: no kind, it is past linger, not yet seen (`weatherSeenAt`), the event is rescued, or the plant is mended (care after `weatherSeenAt`).
- A sheltered garden returns `look = .snug` (the helper art with weather on it; plants upright). A plant that shrugs returns `.shrugs` with its proud line.
- `setback = 1` only if all of these hold: `wild`, a big kind, full effect, `rank < (sheltered ? 2 : 4)`, `stage >= 2`, not rescued, and not mended under the "next day" rule.
- `shownStage = stage - setback`, which is never below 1 when a setback applies.

### 6.1 New Economy constants
```
weatherFirstWeekDays = 7, weatherBlockDays = 14, weatherEventWindow = 7, weatherBlockChance = 0.75,
weatherBagBig = 3, weatherBagGentle = 7, weatherAffectedCap = 0.4, weatherLingerDays = 3,
weatherMinPlants = 5, weatherMinTends = 2, weatherPuzzlesPerDay = 3, weatherPuzzleDays = 4 /* event day + 3 */,
calmLingerDays = 1, weatherAwardGardenDays = 7, weatherClockSlackDays = 1, weatherPuzzleWords = 1,
weatherAlgoVersion = 1,
wildMaxPlants = 4, wildMaxPlantsSheltered = 2, wildLingerDays = 4, wildSetback = 1,
stormMinLetters = 7, stormMaxLetters = 14, stormDecoys = 1,
goldenDaysNeeded = 7, bloomRankThresholds = [1, 10, 30, 75, 150, 300]
```

## 7. Data fields (all defaulted, CloudKit-safe, additive)

| Model | Field | Default | Merge (`DataReconciler`) | `GardenBackup` |
|---|---|---|---|---|
| PlayerProfile | `weatherSeed: Int64` | 0 | pair rule (3.2) | optional |
| PlayerProfile | `weatherStartDay: Int` | 0 | pair rule | optional |
| PlayerProfile | `weatherHighWaterDay: Int` | 0 | max | optional |
| PlayerProfile | `weatherShelterDay: Int` | 0 | max | optional |
| PlayerProfile | `weatherRescuedDays: [Int]` | [] | union, trim 30 | optional |
| PlayerProfile | `weatherPuzzleDay: Int`, `weatherPuzzleCount: Int` | 0, 0 | later day wins; same day max | optional |
| PlayerProfile | `wildWeather: Bool` | false | AND (off wins) | optional |
| PlayerProfile | `weatherGatedFromDay: Int` | 0 | min of nonzero | optional |
| PlayerProfile | `weatherSeenAt: Date?` | nil | max | optional |
| PlayerProfile | `weatherKitAt: Date?` | nil | min of non-nil | optional |
| PlayerProfile | `crownSeenAt: Date?`, `goldCrownSeenAt: Date?` | nil | min of non-nil | optional |
| PlantCollectible | `goldenDays: Int`, `goldenDayKey: Int` | 0, 0 | later key wins; same key max | optional |
| Plants.json | `traits: [String]` | [] | n/a (bundle) | n/a |
| BadgeCounter | `weathered` | n/a | existing BadgeState merge | via badgesJSON |
| StickerAlbum | `weather.<kind>` ids | n/a | existing union | via albumJSON |

Rules:
- No unique constraints, no new relationships, and every attribute defaulted, so lightweight migration and CloudKit accept the change.
- Deploy the CloudKit schema to Production before release; after that, changes are additive only.
- `GardenBackup.currentSchema` stays 1: new fields are optional and older backups read as defaults.
- Restoring a backup never lowers anything (max/union), and `wildWeather` restores only as off.

## 8. Interactions
- **LoveEngine / LifeStats:**
  - Weather is separate from love rain. If a plant is raining because of no love, the love rain look wins on the plant page, and the weather look shows only once love returns. A hello mends both.
  - `LifeStats.Snapshot` gains `weather: WeatherLook.Output?`, and its stage path draws `shownStage` with a dashed mending segment.
  - The life meters never change because of weather (the meters rule stays: a not-full meter means its button works).
- **Seeds:** a resting seed (0 petals) shows no weather.
- **TendingEngine / ToolEngine:** unchanged. Any action already sets `lastTendedAt`, which is the mend signal. The helpers are not `ToolID`s (no tiers, no costs); they are a computed `WeatherHelper` set.
- **ProgressionPolicy:**
  - `wordLevel` and `gardenLevelComplete` keep reading the stored `stage` and `earned`. Add a test that they never read `shownStage`.
  - `PotCatalog` and `Badges` likewise read stored values.
  - `EndgamePolicy` builds on `ProgressionPolicy`.
- **Economy:** the new constants are in section 6.1, and no current value changes.
- **GardenBackup / DataReconciler:** fields and merge rules are in section 7. Add round-trip and merge tests.
- **Reminders:** the forecast reuses the daily slot (3.8).
- **Widget / Siri / Control Center:** the widget shows the forecast line, and watering from the widget counts as care, so it mends. Siri "Water my garden" mends too.
- **PlusOfferPolicy / AdGate:** no offer or ad in the same visit as a forecast card, an event banner, the puzzle, or the ceremony. The tech research flags ads next to a setback as manipulation (2.5.18).
- **Daily Bloom / rounds / words-per-plant:** untouched by weather.

## 9. Owner decisions needed
Plain statement first: **we are not building a drop in your level.** Your word level (the "level" players talk about) never goes down in either variant. What Wild Weather gives you is a *shown-stage dip*: on up to 4 plants, the plant looks one stage smaller and the level ring shows a dashed gap for up to 4 days. The hard puzzle gives it all back at once, plus a word toward the next plant. A real stored drop is ruled out by the 2026-11-03 "nothing earned is ever removed" ruling, and our iCloud and backup merges would undo it on the next sync anyway.

1. **Variant:** Variant 1 for everyone, with Variant 2 Wild Weather as a 13+ opt-in (recommended). Alternatives: Variant 1 only, or Variant 2 as the default (not recommended). True drops (2b) are not offered.
2. **"Drop levels" meaning:** confirm that in Wild Weather the drop is the *shown stage* (and the level ring), and that **word level never drops**.
3. **Frequency:** about one event every 19 days, 30% of them big (`weatherBlockChance` 0.75). The alternative is roughly every 28 days (0.5).
4. **Calm / under 13:** weather off by default, and a grown-up may turn on looks-only weather. The alternative is looks-only weather on for everyone, matching the petal ruling at every age.
5. **Endgame package:** Grand Garden plus the Crown, the gold crown, golden blooms (7 care days), Bloom ranks and the Visitors' book. Pick a ceremony direction from `design-preview/endgame/`.
6. **Forecast notification:** opt-in, sharing the daily reminder slot (recommended), or no notification at all.

## 10. Test plan (TDD order, rules first; no UI before rules are green)
1. `WeatherDayTests`:
   - the Gregorian key matches across `Calendar.current` settings (Buddhist and Japanese);
   - DST days give consecutive keys;
   - a time-zone move changes the key by at most 1.
2. `WeatherScheduleTests` (2,000 random seeds x 400 days):
   - no event before startDay;
   - the minimum gap is 8 or more;
   - never two in a row;
   - consecutive *events* never share a kind, even across skipped blocks and bag boundaries;
   - the share of big events is about 30%;
   - the mean gap is 18.7 ± 1.5;
   - `forecast(d) == event(d+1)`;
   - fully deterministic: the same seed gives the same list;
   - the algoVersion cutover leaves earlier days unchanged.
3. `WeatherMergeTests`:
   - the seed pair rule is commutative and idempotent;
   - high-water takes the max;
   - rescued days merge by union and are trimmed;
   - `wildWeather` merges by AND;
   - the crown dates take the min;
   - the golden day merge works like water.
4. `WeatherEffectTests`:
   - every catalog plant has traits (all 50);
   - every kind has at least 1 plant that shrugs it off;
   - shrugs beats full;
   - the 40% cap holds;
   - the cap order is deterministic.
5. `WeatherLookTests`:
   - mend on a care day (Variant 1);
   - next-day mend (Wild Weather);
   - linger fade after 3 / 4 days;
   - shelter shows the snug look and needs no mend (Variant 1), or halves the setback (Wild Weather);
   - no look before the garden has been seen on or after the event day;
   - care before `weatherSeenAt` does not mend;
   - a return after the linger shows nothing (presence rule);
   - a rescue clears all;
   - setback is 0 on gentle kinds;
   - shown stage is never below 1;
   - a stage-1 plant has no setback;
   - a seed shows no weather;
   - love rain takes priority over weather.
6. `WeatherGatingTests`:
   - Quiet Garden, Calm default, under 13, fewer than 5 plants and fewer than 2 tends each show nothing;
   - a clock moved back shows nothing;
   - turning gating on later shows no pile-up.
7. `WeatherInvariantTests`:
   - with a weather event active, `ProgressionPolicy.wordLevel`, `gardenLevelComplete`, `PotCatalog.state` and badge progress all equal their values with weather off;
   - stored `stage` and `growthPoints` are byte-identical before and after a day of weather (both variants).
8. `StormPuzzleTests`:
   - storm answers fall in 7-14 letters;
   - two-word names keep their gap;
   - there is one decoy and no given letter;
   - deterministic per day and attempt;
   - the peek ladder always finishes;
   - the gentle tier is byte-identical to today's `WakePuzzle.make` output (no regression for the wake flow);
   - the daily cap holds.
9. `WeatherKitTests`:
   - the kit arrives at the first gated forecast and never goes away after a seed merge;
   - there are no Plus or price fields;
   - the award cap (`mayAward`) stops clock-jump farming;
   - the clock slack of 1 day is honoured;
   - the sticker order is fixed by solve count.
10. `EndgameTests`:
    - `allFound` and `allFullBloom` read earned values;
    - the ceremony shows once;
    - golden days add at most +1 a day, reach golden at 7 and merge correctly;
    - the rank thresholds are right.
11. `WeatherCopyTests` / `EndgameCopyTests`: `CopySafety` on every line, plus a check against the extra avoid-list (save, rescue, danger, destroy, warning, alert, too late).
12. `RemindersTests`: on a forecast day the one daily request carries the forecast copy at `.passive`; no extra request; quiet hours respected; nothing when opt-in is off or the player is under 13.
13. UI tests: `-uitest-weather=<kind>`, `-uitest-forecast`, `-uitest-wild`, `-uitest-crown` launch flags; the accessibility audit on the forecast card, plant page with weather, puzzle and ceremony; Reduce Motion paths.

## 11. Tickets (after the owner decision)
| # | Ticket | Effort | Depends |
|---|---|---|---|
| E-1 | `WeatherDay` + `WeatherEngine` schedule, bag and versioning + tests 1-2 | M (1.5 d) | none |
| E-2 | Data fields + `DataReconciler` + `GardenBackup` + tests 3 | M (1 d) | E-1 |
| E-3 | `Plants.json` traits (50) + effect/cap + tests 4 (plant-data owner checks traits) | S (0.5 d) | E-1 |
| E-4 | `WeatherLook` (both variants behind `wild`) + LifeStats hook + invariant tests 5-7 | M (1.5 d) | E-2, E-3 |
| E-5 | Forecast card, chip, event banner, Settings "Garden weather" + copy | M (1.5 d) | E-4, mockups approved |
| E-6 | Plant-page weather art for 3 big kinds (overlays on layered plants), Reduce Motion stills | L (3 d) | E-4, visual sign-off |
| E-7 | Weather helpers in the Shed + set-out + plant-page helper art | M (1.5 d) | E-4 |
| E-8 | Weather puzzle (gentle + storm tier on `WakePuzzle`), stickers, `weathered` badge + tests 8 | M (2 d) | E-4 |
| E-9 | Audio: bundle the 8 sounds after a device listen, `WeatherSound` gate rules | S (1 d) | audio sign-off |
| E-10 | Widget forecast line + Reminders forecast content + tests 12 | S (1 d) | E-1 |
| E-11 | 4 gentle kinds' art (frost, hot, hail, puddles) | M (2 d) | E-6 |
| E-12 | Wild Weather toggle (13+ only, hidden otherwise), confirmation, store-description line, level-ring dashed segment, two-part puzzle | M (1.5 d) | E-8, owner decision 1-2 |
| G-1 | `EndgamePolicy` + fields + tests 10 | S (0.5 d) | none |
| G-2 | Grand Garden ceremony + Crown on wordmark + replay + Reduce Motion | L (3 d) | G-1, direction pick |
| G-3 | Gold crown moment + per-level bloom wave | S (1 d) | G-2 |
| G-4 | Golden blooms (tint/shader, plant page progress line) | M (1.5 d) | G-1 |
| G-5 | Bloom ranks + Visitors' book page with weather stickers | M (1.5 d) | G-1, E-8 |
| Q-1 | Age-rating questionnaire re-check, privacy label check (no new data collected), App Review notes | S (0.5 d, owner) | before release |

Total about 26 dev-days. Suggested order: G-1, E-1, E-2, E-3, E-4 (rules first, all testable), then G-2, E-5, E-6, E-8, then the rest. Each ticket follows the house process: worker, PM check, two reviews, owner look on localhost for visuals.

## 12. Risks
- **Age rating:** frequent fear themes rate 13+. Keep the art cartoon-gentle and events infrequent, and re-answer the questionnaire (Q-1).
- **Chores creep:** weather adds a reason to open the app. It is bounded: never tied to absence, mended by one hello, and fading on its own.
- **Seed divergence before first sync:** brief and self-healing. Documented in 3.2.
- **Concurrent puzzle solves on two devices:** handled by the union merge. A rare lost append only means a sticker shows a launch later.
- **Owner expectation:** Variant 2's drop is shown-only by design. If the owner wants stored drops, that reopens the 2026-11-03 ruling, which needs its own decision and would also need sync/backup redesign (max-merges).

## 13. Review log
**Outside review 1 (spec critique).** Changes made:
1. Variant 1 would have been invisible: an engaged player's hello or a one-tap shelter erased it before it was seen. Now the look waits until the garden is seen (`weatherSeenAt`), only care after that mends it, and shelter shows a snug look instead of erasing the weather.
2. Under-13 Wild Weather was contradictory. Now it is never available, gate or not.
3. Per-kind stickers were FOMO (a rare kind meant about a 140-day wait). Now stickers come in a fixed order and any puzzle earns the next one.
4. The puzzle only restored. Now it also *gains*: one word toward the next plant, a sticker and a badge step.
5. Helpers worked out from the schedule could disappear after a seed merge. Now a one-time Weather kit (`weatherKitAt`) is kept, plus `weatherGatedFromDay`.
6. The bag rule compared bag neighbours, not events. Now kinds are picked by event ordinal.
7. The clock guard silenced two-zone households. Now it allows 1 day of slack.
8. Clock-jump farming. Now the presence rule plus an award cap of one per 7 Garden Days.
9. The two-word puzzle answers were under-specified. Now they are letters plus `gaps`, three-word names are out, and the candidate counts are given.
10. Golden blooms could be won by tapping hello. Now they need tending only, and Home features one plant a day.
11. Section 9 now says plainly that word level never drops.
12. The store description mentions Wild Weather.
13. Calm linger is in Economy.
14. No forecast card on Home in Calm.

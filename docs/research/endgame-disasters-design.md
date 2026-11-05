# Endgame and garden weather: research and design (2026-11-04)

Branch `3-feat-content-and-polish`. Research only, no code changed. Owner request (verbatim): "if someone beats the game, brainstorm what should happen, that means collect all flowers, etc. I think we should have random days like droughts, termites, hurricanes/natural disasters that drop levels for people, but then offer a really hard puzzle to gain some back."

Constraints read from the repo (all binding on this design):
- STATUS owner ruling: **nothing earned is ever removed** (stage, growth, collection kept). Rain, petal loss and the seed state are visual only. Quiet Garden and Calm mode switch it off. Under-13 / unknown age default to Calm mode. (The later ruling applies petal loss at every age, but Calm and Quiet Garden stay exempt.)
- `reinforcement-principles.md`: no punishment, no loss, no variable-ratio value, stopping cues instead of compulsion; random delight only if cosmetic.
- `plus-perks.md`: Plus is cosmetic or convenience; the free game is complete; Plus must never gate progress or the ending; cancelling keeps what was earned.
- Existing engines reused: `LoveEngine` (24 h, 5 petals), `WakePuzzle` (5-10 letter plant names, anagram or vowel-blank, peek every 30 s, `easier` flag), `WakeChallenge` (puzzle or butterfly, "still dreaming" ladder, `isEasier` after 2 tries), `ToolID` (can, trowel, shears, mister, lamp, net), `PotCatalog` (10 pots), `Badges`.
- `Plants.json` has no trait field today (name, botanicalName, fact, level, nameStory). Any hazard resilience below needs a new `hazardTags` array per plant (data only, 50 entries).

---

## 1. Research summary

### 1.1 Endgames and post-completion loops

| Game | What happens at "done" | Lesson for WordFlora | Source |
|---|---|---|---|
| Stardew Valley | Grandpa's evaluation at the start of year 3 scores 12 points toward four candles; a Statue of Perfection follows; a separate Perfection Tracker (Qi's Walnut Room, 130 golden walnuts worth 5%) gives a visible percentage across many categories. Play simply continues afterwards. | A single visible "how complete" number plus a one-time ceremony works; the game never forces a reset. Keep it a mirror, not a to-do list. | [Stardew wiki, Perfection](https://stardewvalleywiki.com/Perfection); [Qi's Walnut Room](https://stardewvalleywiki.com/Qi's_Walnut_Room) |
| Animal Crossing NH | 5-star island rating (Isabelle) is computed from hidden development and scenery scores (each full-grown tree and flower adds scenery); reward is more campsite visitors and a recipe. Museum completion and seasonal events keep the loop alive. Weeds, wilting flowers and roaches after absence: not confirmed in my search (UNVERIFIED, from memory). | Reward a finished state with *more life in the garden* (visitors), not a score screen. Seasonal events are the long tail. | [Nintendo Life 5-star guide](https://nintendolife.com/guides/animal-crossing-new-horizons-how-to-get-a-5-star-island-rating); [Nintendo Soup scoring](https://nintendosoup.com/?p=181935) |
| Terraria | Post-Moon Lord is optional "keep building" with challenge modes (Journey, Master, For the Worthy) chosen by the player. UNVERIFIED (memory). | Harder variants belong in a **player-chosen** mode. | memory |
| Harvest Moon / Story of Seasons | Endings are soft: marry, fill the museum, keep farming. Typhoons exist and are forecast. UNVERIFIED (memory). | Soft end plus seasons. | memory |
| Finch | Pet never harmed by a missed day; tone is empathetic. Critics report "gamification fatigue" when care feels like a chore. Primary Finch source not found; reviews only. | No-punish design is a selling point, but daily chores wear out. Keep events rare. | [Pratt IxD critique](https://ixd.prattsi.org/2026/02/design-critique-finch-self-care-pet-ios-app/); [Engadget](https://www.engadget.com/apps/this-self-care-virtual-pet-is-helping-me-get-my-act-together-160027169.html) |
| Forest (real trees), Neko Atsume (collection complete, mementos), Pokemon Sleep (research ranks, seasons), iNaturalist Seek (badges), Viridi, Wordle/NYT (endless daily) | Not fetched. From memory: Forest plants real trees for completed focus; Neko Atsume gives a keepsake and keeps cats visiting; Pokemon Sleep ranks keep rising; Seek badges are seasonal and observation-based; Wordle is one puzzle a day with no end. All UNVERIFIED. | Daily puzzle with no finish line (Wordle) is the calmest endless loop; a keepsake (Neko Atsume) ends a collection gracefully; real-world tie (Forest) is a charity risk for kids (skip). | memory |

Pattern across the games that feel good: (1) one ceremony, not a cliff; (2) the collection is never reset, prestige/new-game-plus **adds** a layer on top (Stardew's perfection percent, Terraria's harder modes are opt-in); (3) the endless part is either a tiny daily ritual (Wordle) or seasonal variety, not "grind harder"; (4) the game keeps being a nice place to sit. What turns completion into a grind: a hidden requirements list, a percentage that includes tedious items, or timed seasonal exclusives.

### 1.2 Hazards: remembered fondly vs resented

| Hazard | How it works | Remembered as | Why |
|---|---|---|---|
| Stardew storms, lightning, TV forecast, lightning rod | The TV gives tomorrow's weather (upgraded TV adds the day after; the wiki shows the forecast can still be off). Lightning can destroy a random tile; one lightning rod protects the whole farm and makes a Battery Pack. | Mostly fondly | Warned a day ahead, mitigation is a cheap tool you build once, and the downside is small and random rather than total. A storm even pays out (batteries). [Stardew guide: weather](https://stardewguide-xyz.pages.dev/guides/weather-system-guide); [Rain](https://stardewvalleywiki.com/Rain) |
| Stardew crows and scarecrows | Crows can eat crops; a scarecrow in range stops it. Details UNVERIFIED (search returned only forum talk). | Mixed, mostly tolerated | Mitigation is a visible object you place. |
| Harvest Moon typhoons | Destroy crops unless harvested; forecast. UNVERIFIED (memory). | Mixed | |
| Terraria blood moon / invasions | Night events that make the world more dangerous but give loot; player picks when to be ready. UNVERIFIED (memory). | Fondly by adults | Event = reward plus risk, player prepared. |
| Animal Crossing absence penalties (weeds, roaches), wilting flowers | Reward consistent play; punish absence. Not confirmed in my search (UNVERIFIED). | Mixed to resented | Return-guilt; WordFlora already replaced this with the welcome-back card. |
| FarmVille withering | Crops wither if you do not return in time (about 100-200% of growth time per one source). Critics called it a mechanic to force return visits for ad revenue and described players setting alarms. Zynga switched withering off during an outage. | Resented | Fabricated urgency plus loss, tied to monetisation. [Engadget 2010](https://www.engadget.com/2010-03-22-the-fringe-farming-games.html); [Bangkok Post retrospective](https://www.pressreader.com/thailand/bangkok-post/20210113/282218013429668); [AOL/Joystiq 2012 outage](https://www.aol.com/2012-02-03-farmville-bugs-wither-off.html) |
| Tamagotchi / Neopets | Pets sicken or die from absence. UNVERIFIED (memory). Nostalgic for adults, but the design is the exact "stay or lose it" pattern. | Nostalgia plus guilt | |
| Minecraft weather | Rain, thunder, no loss unless you stand outside; Hardcore is an opt-in mode. UNVERIFIED (memory). | Fondly | Atmosphere without punishment. |

**Rule of thumb that falls out:** hazards are loved when they are (a) forecast, (b) mitigable with something the player made or earned, (c) random in *where* but bounded in *how much*, (d) never tied to being away or to money, and (e) have an upside or story. They are resented when they punish absence, cannot be prevented, or sit next to a purchase. WordFlora's events therefore must be forecast a day ahead, shelterable, bounded, and independent of absence.

### 1.3 Loss aversion, kids, and ethics

Evidence, with honest weights:
- **Loss aversion is real but its size varies.** The qualitative asymmetry replicated in a 2020 multi-country test of the 1979 prospect theory questions (16 of 17 findings held). The famous "about 2:1" is from later work and varies by method; some datasets include 1 (no loss aversion). So losses *can* sting roughly twice as much as equal gains, but not reliably. [Ruggeri et al. coverage, ScienceDaily](https://sciencedaily.com/releases/2020/05/200518144913.htm); [Cambridge reader, Kahneman/Tversky line of work](https://www.cambridge.org/core/product/5323F0F4F626C6FA9B6DEA4D564050BA/core-reader). Direct tests on young children in apps were not found.
- **Manipulative design is already everywhere in kids' apps.** Radesky et al. 2022 (JAMA Network Open 5(6):e2217641) coded the top apps of 160 children aged 3-5: only about 20% of apps had no manipulative features and nearly every child (about 99%) used at least one app with one; the coded types include fabricated time pressure, parasocial pressure (a character yelling "save me!" beside a countdown) and navigation constraints. Most common in general-audience apps. [Deceptive Patterns summary](https://deceptive.design/articles/prevalence-and-characteristics-of-manipulative-design-in-mobile-applications-used-by-children); [Michigan Medicine release](https://www.michiganmedicine.org/health-lab/design-tricks-commonly-used-monetize-young-childrens-app-use). A hazard that says "save your plant!" is squarely in this category.
- **UK ICO Children's Code (AADC).** Standard on nudge techniques: do not use nudges to push children to give more data, weaken privacy, or **extend use**; reward loops and streaks are called out as examples in commentary; nudging toward breaks is encouraged. WordFlora's rest card already matches this. [Safer Internet UK summary](https://saferinternet.org.uk/blog/icos-age-appropriate-design-code); [ESRB Privacy Certified](https://www.esrb.org/privacy-certified-blog/the-icos-age-appropriate-design-code-uses-detrimental-to-children/); [TechCrunch 2020](https://techcrunch.com/2020/01/22/uk-watchdog-sets-out-age-appropriate-design-code-for-online-services-to-keep-kids-privacy-safe). Final-code status as "not law" is from a 2020 article; current status UNVERIFIED.
- **Streaks.** A JCR study (second-hand via The Decision Lab, paper not read) reports people value extending the streak over the activity, and that those who break streaks quit more. Duolingo reports freezes raised daily actives by 0.38% (company figure, no method). No direct measure of streak anxiety found. [The Decision Lab: streak creep](https://thedecisionlab.com/fr-CA/insights/consumer-insights/streak-creep-the-perils-of-too-much-gamification); [Duolingo blog](https://blog.duolingo.com/how-duolingo-streak-builds-habit).
- **5Rights Foundation** design guidance (Child Rights by Design) names the same patterns; not fetched, UNVERIFIED.

**Honest answers**
- *Does a drop in displayed level harm kids?* No study I found measures this. The mechanism (loss aversion plus effort already invested) predicts it can feel bad, especially when the loss is unrelated to anything the child did, and the Radesky taxonomy would classify "a threat to progress, fixed by a puzzle or by returning" as pressure. For a child who is sensitive to perfection, "my 30 words went away" is plausible harm. I cannot show harm; I can show the design pattern is flagged by the best available children's-app research and by regulators' guidance. Treat as a risk, not a proven injury.
- *What do adults in hardcore modes value?* Self-chosen stakes, mastery and stories ("my Hardcore world"). The key is **opt-in and the ability to leave**. Minecraft Hardcore and Terraria's harder modes are choices, not defaults (UNVERIFIED, memory). The choice is what makes the stakes feel like agency instead of manipulation.
- *Is one gentle loss fine?* The existing rain and petal rule already shows that a visual loss with zero real loss works in-house. Weather can reuse that exact contract.

---

## 2. Endgame options

Definition of "beaten": all 50 plants found; garden level complete (10 of a level at stage 4) for all 5 levels. Two thresholds are celebrated separately: **Found all 50** and **Fully grown all 5 levels**. Plus never gates either.

Scores: delight and calm fit 1-5 (5 = best); effort S/M/L; art needs; risk.

| # | Option | Delight | Calm fit | Effort | Art | Risk |
|---|---|---|---|---|---|---|
| 1 | **Grand Garden ceremony**: one-time scene when all 50 are found: every plant blooms in sequence, all visitors arrive, a "Gardener's Crown" petal ring appears around the Home flower; replayable from Settings. | 5 | 5 | M | 1 sequence, reuses petal art | Low |
| 2 | **Level-complete moments** (5): each fully grown level gets a small bloom wave and a pot or keepsake (pots already exist: sunflower, starlight). | 4 | 5 | S | little (reuse) | Low |
| 3 | **New Season loop**: cultivars / colour variants of each plant (e.g. a rose-gold Dandelion) earned by tending, shown beside the original. Collection keeps everything. 4 seasons x 50 is a lot, so release 10 per season. | 4 | 4 | L | high (per-plant variants) | Med (grind if mandatory; keep optional) |
| 4 | **Endless Daily Bloom with calm ranks**: ranks like Seedling, Sprout, Bloom (counts of Blooms done, never streak-based, no leaderboard). Already built; just add ranks and a wall of dates. | 3 | 5 | S | little | Low |
| 5 | **Visitors sanctuary**: after the ending, a rare-visitor list (birds, bees, moths by time of day, 12-20 more) that arrive over time; a "Visitors' book" page. | 4 | 5 | M | medium (new sprites) | Low (random cosmetic; no value, no ads adjacent) |
| 6 | **Plant postcard / share**: spoiler-free image of one plant or of the Crown, made on device, no names or photos of kids. | 3 | 4 | M | frames | Med (share sheet needs the gate; Plus frames only cosmetic) |
| 7 | **Mentor / friend garden**: visit a pretend "guest garden" (NPC) or send a seed to a friend. | 3 | 3 | L | high | **High**: social features with child data; do **not** build for under-13. If done at all, an NPC guest garden (no real people) is fine. |
| 8 | **Word packs** (themed: oceans, space, kitchen garden): extra levels beyond 5, same rules. | 4 | 4 | L (words and facts) | S | Med (needs fact-checking pass; STATUS already flags facts from memory) |
| 9 | **Rose of Jericho prestige**: after the ending the Rose becomes a "Golden Rose" that turns into a **wishing seed**: plant one wish seed per season to grow a *mystery cosmetic* variant. Collection kept; no reset. | 3 | 3 | M | medium | Med (mystery = random; keep it fixed and visible, not a drop) |
| 10 | **Weather season** (this document's section 3): rare, forecast, shelterable events that give the finished garden something to *do*. | 4 | 3-4 | M-L | high | **Med-High** depending on variant |

### Recommended package
Ship in this order. Everything is optional after step 1, none of it removes anything, none of it needs Plus.

1. **Grand Garden ceremony (1) + level-complete moments (2).** Cheap, one-time, and the actual answer to "what happens when someone beats the game". Copy and a short calm variant for Calm / Reduce Motion (still blossoms fading, opacity only; ties into `celebrations-audit.md` gaps 1 and 4).
2. **Endless Daily Bloom ranks (4) + Visitors' book (5).** The calm tail. Daily Bloom draws from 183 level 1-3 words and 303 words total exist, so a replay archive (a Plus perk already planned) stretches it.
3. **Weather: Variant 1 "Weather, not loss" for everyone** (section 3), then opt-in Wild Weather for 13+ (section 5).
4. **Seasonal cultivars (3) in slices of 10 plants**, no deadline; the item stays earnable after the season. Word packs (8) once the fact-check backlog is clear.
5. Skip for now: friend garden (7), real-money-free charity tie-ins, leaderboards. Defer Golden Rose (9) until the ceremony is tested.

Plus line: Plus pots, themes, postcard frames and the Daily Bloom archive are cosmetic extras. The ceremony, Crown, ranks, visitors' book and weather are free.

---

## 3. Garden weather events

### 3.1 Shared engine (both variants)

Pure, deterministic, nothing stored except a tiny "recovery" record. File sketch: `Rules/WeatherEngine.swift` (not written; design only).

**Schedule (stateless, seeded per player).**
- Per-player `weatherSeed` (random at install, carried in `GardenBackup`, higher-wins merge like `wordsTowardPlant`).
- Time is cut into **14-day blocks**, anchored so block 0 starts on install day + 7 (**never in the first 7 days**).
- Each block rolls once with `SplitMix64(seed ^ blockIndex)`: probability **0.75** of one event; the day offset is uniform over days 0-6 of the block.
- Result: events at least **8 days apart** (at most one per 7 days, provably), never two days in a row, mean spacing about 19 days, a longest gap of 20 days. Tunable `Economy.weatherBlockProbability`.
- Event type: from the same RNG, weighted by season/month and **never the same type twice in a row** (look at previous block's roll, which is stateless to recompute).
- 3 of 4 events are "gentle" (frost, heat, hail, flood), 1 of 4 is "big" (drought, termites, big wind). Tunable.
- Local day, `Calendar.current`, same as `WakePuzzle.day(for:)`, so DST and time zones behave like Daily Bloom.
- Not tied to absence: it fires on the calendar whether or not the player opened the app. A player who was away for a week sees at most the *latest* event's aftermath, already in recovery (see 3.4), and never a pile-up.

**Forecast the day before.** A "Garden forecast" card on Home and in the Shed from 18:00 the previous day (and all of event day): a small cloud icon, plain words, a "Get ready" button listing shelter tools (3.3). No push notification by default (an opt-in Settings line "Tell me about weather" could use the existing reminder channel at a calm time such as 10:00, never evening; kids' default is off). The forecast is 100% accurate in WordFlora (Stardew's is not, which players found confusing).

**Duration.** An event day runs from local midnight to the end of that day and the plant shows weather until it is tended or 3 days pass, whichever comes first.

**Gating.** Weather appears only after **found plants >= 5** and **at least 2 tending actions ever** (so a new player has something to see and has learned to tend). Quiet Garden: **off**. Calm mode: **off by default**, see 3.7. Weather never touches the Daily Bloom, rounds or the word count.

**Plant resilience tags.** Add `hazardTags` to `Plants.json`. Draft (names from the brief; to be confirmed by the plant-data owner):

| Event | Shrugs it off (no effect) | Takes half the effect | Most affected |
|---|---|---|---|
| Drought | desert (cacti, Lithops, Welwitschia, Joshua Tree), Rose of Jericho theme | hardy trees (Baobab stores water; Monkey Puzzle), succulents | aquatic (Lotus, Giant Water Lily), ferns, Sundew, Pitcher Plant (bog plants) |
| Termites | carnivorous (Venus Flytrap, Pitcher Plant, Sundew eat insects), aquatic, desert (dry stems) | resinous/hardy trees (Monkey Puzzle) | woody and bamboo; soft herbs only lightly |
| Big wind (hurricane) | hardy short plants, desert low cacti, Bamboo (flexes), Baobab, Monkey Puzzle | grasses, shrubs | tall flowers (Sunflower, Foxglove, Hollyhock), Joshua Tree branches only a little |
| Frost | hardy trees (Monkey Puzzle), Edelweiss-type alpine | evergreens | tropical (orchid, Bird of Paradise), succulents |
| Heat wave | desert | hardy trees | aquatic (shallow water warms), woodland shade plants |
| Hail | hardy trees, cacti spines | shrubs | big-leaf plants, tender flowers |
| Flood | aquatic (Lotus, Giant Water Lily), bog (Pitcher Plant, Sundew), Bamboo | hardy trees | desert (roots drown), bulbs |

Rule of thumb: at most **40% of the garden** is affected by any event (the rest are in the "shrugs off" or "half" columns by tag), so it feels like weather, not a wipe. Where a tag is missing the plant counts as "half".

**Pots and Shed shelter tools.** Reuse `ToolID` slots plus 7 new shelter items (earned by play, free; Plus may add cosmetic *looks* only).

| Event | Shelter | Where it comes from | Effect |
|---|---|---|---|
| Drought | **Shade cloth** and the existing **can** | Shed, level 2 finished | Shade cloth: half effect; watering the day of: cancels it for that plant |
| Termites | **Bug cover** (pesticide-free netting) | Shed, level 3 finished | Plants under it are untouched; no chemicals shown |
| Big wind | **Wind net** and **stake** | Shed, 10 plants | Net covers 5 plants (one tap each) |
| Frost | **Frost cloth** | Shed, level 2 finished | Untouched |
| Heat | **Shade cloth** | same | Untouched |
| Hail | **Umbrella** (a big garden umbrella) | Shed, 10 plants | Untouched |
| Flood | **Raised bed** (choose a "raised" pot style) | Shed, level 4 finished | Pot plants in raised beds untouched |

- Pot angle: every plant in a pot that "has the weight" (terracotta, sage glaze) is untouched by wind; sunflower pot protects from heat; others cosmetic. Keep it simple: 2 pots give a real half-effect, rest are cosmetic, so Plus pots stay purely cosmetic and **no weather protection is Plus-only**.
- Covering is a free action costing no soil or water. Cover limit: the number of covers needed for a worst-case event is always in the player's stock after the forecast (3 free covers a day, refilled). Nobody should be unable to prepare because of money or inventory.

### 3.2 Variant 1: "Weather, not loss" (recommended default)

Contract: **nothing earned is removed, ever. No stage, growth, count, level, badge or pot changes value.** Events change *how the plant looks* and *what bonus is on offer*.

**State.** One derived value per plant: `weatherMood` in {fine, weathered}. Stored: `weatherEventDay` and `weatherType` on the profile (2 fields, defaulted nil, optional in `GardenBackup`). A weathered plant draws with the hazard art (3.5) and shows a tidy note in place of numbers; the growth bar shows a "weathered" tint but the real growth number and stage are untouched. Growth keeps accruing as normal.

**Recovery.**
- **Tending alone recovers fully.** One tending action (water, feed, sun, prune or repot, any one) on a weathered plant clears it. Nothing needs a puzzle or a day count: guaranteed full recovery within **1 tending action, or after 3 days automatically** (the event fades, like rain fading). Quiet Garden never shows it at all.
- **Optional rescue puzzle (the "Storm Chest"):** one shared puzzle for the whole garden per event, harder than the wake puzzle (3.4). Solve it and every weathered plant recovers at once and earns one bonus (below). Skip costs nothing.

**Bonuses (cosmetic or trait, never a stat that gates progress).**

| Bonus | What it is | Why it is safe |
|---|---|---|
| "Weathered" badge tiers (1, 3, 6, 10 storms weathered) | Normal badge system | Badges are already cosmetic |
| Storm-proof trait on one plant | A tiny shield spark; that plant is untouched next time that event type happens | Reduces future weather; not progress |
| Sparkle | Plant glints for a day, rainbow after rain, a rare visitor (a moth, a heron) arrives | Cosmetic, random cosmetics allowed (reinforcement principle 5) |
| Seed packet of a **cultivar** (seasonal colour variant) | Option 3 above | Collection extra, never required |

No soil, water or growth is offered as the bonus (that would make weather a source of power and make skipping feel like losing). Bonuses are one per event.

### 3.3 Variant 2: "Owner's literal" (drops, then a hard puzzle gives some back)

Contract: **events can lower the *displayed* stage by 1 (and therefore the displayed word/garden level), and a very hard puzzle gives some back.** To keep the owner ruling, the **earned** value is never removed. We store `earnedStage` (high-water, forward-only, like the current `stage`) and a derived `shownStage = earnedStage - hit`. Only `shownStage` is affected, and it is what the garden screen, level-complete tracking and the level map show. Badges, collection counts, pot unlocks and the ending are all computed from **earned** values, so a storm can never block a pot, badge or the Crown.

That means "drops levels" is real on screen for the people who chose it, but the account behind is intact. This is the honest middle path between the owner's request and the ruling "nothing earned is ever removed": the *display* drops, the *record* does not.

**Per event (Wild Weather).**

| Event | Frequency | Affects | Drop | Warning | Mitigation | Rescue |
|---|---|---|---|---|---|---|
| Drought | big (1 in 4 events) | up to 40% of plants by tag | -1 shown stage on affected plants (min stage 1; a Tiny never goes below) | day before, 100% sure | water the plant that day (cancels), shade cloth halves | Storm puzzle (3.4) |
| Termites | big | woody plants by tag | -1 on affected, max 3 plants | day before | bug cover | same |
| Big wind | big | tall plants | -1, bounded to 4 plants | day before | wind net, stake, weighted pot | same |
| Frost / heat / hail / flood | gentle (3 in 4) | per tags | **no drop**, look only (as Variant 1) | day before | covers | optional |

Rules that keep it bounded:
- At most **4 plants** and at most **1 stage** each per event; never below stage 1 (never un-finds a plant; the plant remains in the collection and in the count).
- Garden level completion is computed from earned stage, so a "level complete" badge and pot are never undone. The level map shows shown stage so the player sees a gap, which is the point of the mode.
- **Guaranteed full recovery by tending alone:** every tending action on an affected plant moves its shown stage back up by 1 (one action per plant restores it), and after **4 days** it returns by itself. The puzzle just gives it back **instantly and for all plants**, plus the bonus. Nobody is stuck.
- Never two consecutive events; and no new event while any plant is still marked; a player gets a calm pause after recovery.

### 3.4 The rescue puzzle ("Storm Chest")

Built on `WakePuzzle`. Not an extra gate; always skippable.

| Tier | Mechanic | Why it is harder, not unfair |
|---|---|---|
| Easy (Variant 1 default) | Same as wake: 5-10 letter plant name, anagram or vowel-blank | Already built |
| **Storm** | 8-12 letters, **two-word combos** ("Venus Flytrap", "Giant Water Lily" shortened to the first two words), **fewer given letters** (vowel-blank gives only 1 vowel; anagram shuffles with 1 decoy tile), or **word + butterfly**: solve a short plant word, then catch 3 butterflies | All answers are plant names the player has already met; the anagram adds *one* decoy letter, not a trick |
| Harder (Wild Weather only) | Two puzzles in a row, the second has no given letter | Daily cap 2 attempts per event |

Common rules: **no timer**; **peek ladder** (peek every 30 s as in `WakePuzzle.peekInterval`, first peek free, then 2 more per puzzle; a peek never ends the puzzle); "Not quite. Try again." stays the failure line (existing copy); **daily cap of 3 puzzles per event** so it cannot become a long session, then a gentle "Done for today. You can try again tomorrow."; **skip without penalty**: tending alone restores everything; "Skip" button always visible and equal in size; stuck twice = automatically easier (reuse `isEasier(dreamsInARow: >= 2)`). Under Calm / Quiet Garden: no puzzle prompt at all (only the plain note).

### 3.5 Event design cards

| Event | Kid name | Looks | Plants affected | Mitigation | Rescue reward |
|---|---|---|---|---|---|
| Drought | **Dry spell** | cracked soil, drooping leaf, golden light | all except desert; bog and aquatic most | water on the day; shade cloth | Rain-dance petals and a rainbow |
| Termites | **Tiny diggers** | small holes and sawdust on woody stems and pots; harmless bug icons | woody and bamboo; **not** carnivorous (they eat insects) | bug cover (pesticide-free) | A friendly bird visitor (the one that eats bugs) |
| Hurricane | **Big wind** | leaning stems, flying petals, no destruction | tall plants | wind net, stake, weighted pot | A kite-shaped petal on the plant |
| Frost | **Frosty morning** | silver edges; melts by afternoon | tropical, succulents | frost cloth | Sparkling dew |
| Heat wave | **Hot day** | pale leaves, shimmer | shade plants, aquatic | shade cloth | A cool breeze visitor |
| Hail | **Ice pebbles** | small dents on big leaves; ice melts | big-leaf plants | umbrella | Pebble path pot |
| Flood | **Puddle day** | puddles round pots; floating petals | desert, bulbs | raised bed | Frog visitor |

Sound and motion: all events use the existing rain/thunder language. No crack, no sirens, no countdown clock; thunder rules from STATUS (at most once per 3 min, never in Calm or Reduce Motion or Low Power) still apply. Reduce Motion: still art, opacity only.

### 3.6 Recovery math

| Question | Variant 1 | Variant 2 |
|---|---|---|
| What changes | looks only | shown stage -1 on up to 4 plants (big events only) |
| Earned stage, growth, counts, badges, pots | untouched | untouched (derived from earned) |
| Tending alone | 1 action on a plant clears it; auto-clear at day 3 | 1 action per plant restores 1 shown stage; auto-restore at day 4 |
| Rescue puzzle | optional; clears all plants; one bonus | optional; restores all shown stages immediately; one bonus; Hard tier gives a slightly better bonus (not more power) |
| Worst case for a player who never plays a puzzle | looks weathered for up to 3 days | up to 4 plants shown 1 stage lower for up to 4 days, about once every 19 days, and only in big events (about 1 in 4 events), so roughly one such dip every 76 days |
| Can events stack | No | No (blocked while any plant is marked) |

### 3.7 Behaviour by age and mode

| Context | Variant 1 | Variant 2 / Wild Weather |
|---|---|---|
| Quiet Garden | off (no weather, no forecast, no numbers) | off |
| Calm mode (default under 13 and unknown age) | off by default; a parent-visible switch "Garden weather" may turn on the looks-only version | **unavailable** |
| Under 13 | looks-only events only if a grown-up turns them on; never rescue pressure, never a bonus chase | unavailable |
| 13+ and Calm off | on, forecast, optional puzzle | opt-in only; see section 5 |
| Reduce Motion / Low Power | still art, no thunder | same |
| Plus | no effect | no effect (cosmetic weather skins only: e.g. cloud styles) |

---

## 4. Copy (grade 2-3, positive-only)

Banned words (checked line by line below): miss, lonely, alone, waiting, abandon, neglect, forgot, forget, die, dies, died, dying, dead, lost, empty, left, broken, hurry, now or never, expires, only, last, smart, genius, talented, best gardener, better than, beat. Also avoided as substrings: dismiss, missing, blast, leftover, beaten, studies, soldier, onlyk.

**Forecast cards (day before)**
- "Tomorrow: a dry day. Give your plants a drink and they will be fine."
- "Tomorrow: a big wind. Put up the wind net."
- "Tomorrow: tiny diggers! Cover your woody plants with bug cover."
- "Tomorrow: frost. A cloth keeps the cold away."
- "Rain and puddles are coming. Raised beds stay dry."
- "All set! Your garden is ready."

**Event-day banners**
- "A dry day in the garden."
- "A big wind is blowing. The plants are bending."
- "Tiny diggers are visiting."
- "Frosty morning. Look at the sparkly leaves."
- "Hot day. The leaves are tired and want shade."
- "Puddle day! Splash."

**Plant lines (PlantVoice style)**
- "Cactus here. Dry days are my favorite."
- "Venus Flytrap: bugs do not bother me. I eat them!"
- "I am bending, but I am strong."
- "A drink would feel good."
- "The sun is hot. Some shade, please."

**Tend-to-recover (Variant 1)**
- "A drink and a hello. {Name} looks happy again."
- "All better! The sun is out."
- "{Name} is back to bright."
- "Your garden grew back its shine."

**Rescue puzzle**
- Title: "Storm Chest"
- "A puzzle for the garden. Take your time."
- "Make a plant name with two words."
- "Fill in the blanks. You can peek a letter."
- "Not quite. Try again."
- "A peek is coming soon."
- "You can skip this. Your plants will be fine."
- "Nice work! The whole garden is bright again."
- "Done for today. You can try again tomorrow."
- "Skip" / "Maybe tomorrow"

**Bonus lines**
- "A rainbow for your garden!"
- "{Name} is storm-proof now. It has a little shield."
- "A new visitor stopped by: a moth."
- "Weathered badge: you helped your garden through a storm."

**Wild Weather opt-in (13+)**
- Title: "Wild Weather"
- "Want a bigger challenge? Wild Weather brings storms that make plants look smaller for a few days."
- "Your plants, badges and pots are always safe."
- "Turn it off any time in Settings."
- Buttons: "Try Wild Weather" / "No thanks"
- Event: "A big wind knocked 3 plants down a step. Tend them, or open the Storm Chest."
- Recovery: "Back up! Thank you for tending."

**Endgame**
- "All 50 plants found! Your garden is wonderful."
- "The Gardener's Crown is yours. It stays forever."
- "Look: every visitor came to say hello."
- "Level 3 is fully grown. A sunflower pot for you."
- "Daily Bloom: you have grown 40 blooms. Rank: Bloom."

**Self-check.** Scanned each line for the banned list and substrings: "Maybe tomorrow" has no "last"/"only"; "Done for today" has no "die/dead"; "tired" is fine; "knocked ... down a step" has no "left"/"lost"; "stopped by" is fine; "wonderful" is fine; "Bugs do not bother me" fine; "bending, but I am strong" fine. "Skip" fine. No line contains: miss, lonely, alone, waiting, abandon, neglect, forgot, forget, die(s/d), dying, dead, lost, empty, left, broken, hurry, now or never, expires, only, last, smart, genius, talented, best gardener, better than, beat. Run through `CopySafety` in tests before shipping (the repo scanner is the authority).

Copy rules: never "save", "rescue" with urgency or "before it is too late"; no countdown; no "your streak"; the Storm Chest is described as a bonus, not a fix.

---

## 5. Recommendation

**Default for everyone: Variant 1 ("Weather, not loss").** Reasons:
1. It honours the owner ruling "nothing earned is ever removed" without an exception, and it is consistent with rain and petals (`LoveEngine`) which are already a display-only mood.
2. The best evidence we have (Radesky 2022 and the ICO nudge standard) flags pressure on children's progress; a looks-only event that is forecast, shelterable and fixed by one tending action is the pattern players remember fondly (Stardew), not the one they resent (FarmVille).
3. Events give the finished garden something to do (the owner's real goal: life after the ending) without making the ending feel fragile.
4. A mixed audience cannot be split reliably (age is self-reported), so the default must be safe at age 6.

**Wild Weather: yes, as an opt-in mode, with the "shown vs earned" design (section 3.3).** It is a fair way to give the owner what they asked for because:
- It is opt-in (off by default), 13+ and Calm-off only, with a confirmation card, a one-tap off switch, and no re-prompts. Choice is the difference between hardcore and manipulative (section 1.3).
- Real drops are only of *shown* stage. Earned stage, collection, badges, pots, Crown and the ending are untouched, so the owner ruling holds in spirit and in data.
- Bounded (max 4 plants, 1 stage, about every 76 days for big events), always recoverable by tending, never during Daily Bloom, never tied to absence, no Plus involvement.
- If the owner wants the *earned* value to drop too (a true loss), that **contradicts** the written ruling and should be a separate explicit owner decision; I recommend against it. It would also make backups and iCloud merges ("higher wins") ambiguous.

**Open decisions for the owner**
1. Confirm "shown stage drops, earned stage stays" counts as satisfying the request.
2. Confirm weather is off by default in Calm and Quiet Garden, and shown only after 5 plants.
3. Choose block probability (0.75 per 14 days gives about one event every 19 days).
4. Decide whether Wild Weather should also remove the Daily Bloom archive-free replays (no recommended).

**Build order (if approved)**
1. Ceremony and level moments (no data change).
2. `WeatherEngine` (pure rules + tests: min gap 8 days, never in first 7 days, never same type twice, derived from seed, DST) and `hazardTags` in `Plants.json`.
3. Forecast card + Variant 1 art for 3 events (drought, big wind, termites).
4. Storm Chest puzzle tier (reuse `WakePuzzle`).
5. Wild Weather toggle and `shownStage` derivation (guard: tests that no badge, pot or level count reads shown values).
6. Remaining 4 gentle events and cultivar bonuses.

**Tests to add** (rules, no UI): schedule properties over 2,000 random seeds; "no event in days 0-6"; "gap >= 8"; recovery within bounds; badge/pot/level computed from earned; CopySafety on all weather lines; Quiet Garden and Calm return no events; `hazardTags` cover all 50 plants.

---

## Sources

- Radesky et al. 2022, "Prevalence and Characteristics of Manipulative Design in Mobile Applications Used by Children," JAMA Netw Open 5(6):e2217641. Summaries: https://deceptive.design/articles/prevalence-and-characteristics-of-manipulative-design-in-mobile-applications-used-by-children ; https://www.michiganmedicine.org/health-lab/design-tricks-commonly-used-monetize-young-childrens-app-use (DOI format differs between sources; check the journal page before citing).
- UK ICO Age Appropriate Design Code, nudge techniques: https://saferinternet.org.uk/blog/icos-age-appropriate-design-code ; https://www.esrb.org/privacy-certified-blog/the-icos-age-appropriate-design-code-uses-detrimental-to-children/ ; https://techcrunch.com/2020/01/22/uk-watchdog-sets-out-age-appropriate-design-code-for-online-services-to-keep-kids-privacy-safe
- Loss aversion: https://sciencedaily.com/releases/2020/05/200518144913.htm (2020 replication of 1979 prospect theory); https://www.cambridge.org/core/product/5323F0F4F626C6FA9B6DEA4D564050BA/core-reader (ratio varies; not exactly 2:1 everywhere)
- Streaks: https://thedecisionlab.com/fr-CA/insights/consumer-insights/streak-creep-the-perils-of-too-much-gamification (second-hand JCR claim); https://blog.duolingo.com/how-duolingo-streak-builds-habit (company data)
- Stardew Valley: https://stardewvalleywiki.com/Perfection ; https://stardewvalleywiki.com/Qi's_Walnut_Room ; https://stardewvalleywiki.com/Rain ; https://stardewguide-xyz.pages.dev/guides/weather-system-guide ; scarecrow and crow mechanics UNVERIFIED
- Animal Crossing NH island rating: https://nintendolife.com/guides/animal-crossing-new-horizons-how-to-get-a-5-star-island-rating ; https://nintendosoup.com/?p=181935
- FarmVille withering: https://www.engadget.com/2010-03-22-the-fringe-farming-games.html ; https://www.pressreader.com/thailand/bangkok-post/20210113/282218013429668 ; https://www.aol.com/2012-02-03-farmville-bugs-wither-off.html
- Finch: https://ixd.prattsi.org/2026/02/design-critique-finch-self-care-pet-ios-app/ ; https://www.engadget.com/apps/this-self-care-virtual-pet-is-helping-me-get-my-act-together-160027169.html (secondary; no primary Finch source found)
- UNVERIFIED (memory only): Terraria post-Moon Lord and challenge modes, Harvest Moon/Story of Seasons typhoons, Tamagotchi/Neopets, Minecraft weather and Hardcore, Forest, Neko Atsume, Pokemon Sleep, iNaturalist Seek, Viridi, Wordle, 5Rights Child Rights by Design, Animal Crossing weeds/roaches.
- Repo: `docs/STATUS.md`, `docs/research/reinforcement-principles.md`, `docs/research/plus-perks.md`, `docs/pm/celebrations-audit.md`, `Rules/{LoveEngine,WakePuzzle,WakeChallenge,ToolEngine,Economy}.swift`, `Resources/Plants.json`.

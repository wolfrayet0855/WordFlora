# Five stand-in badges made real (design, 2026-11-06)

Read-only design against badge catalogue commit `990d6a6` and the design table in `design-preview/brand/v4/badges.html`.

## Ground rules (all five)
- **Storage:** new counters are `BadgeCounter` cases in `badgesJSON` (max merge, carried by `GardenBackup`). "Once per thing" uses `recordMark` (`mark.<counter>.<item>`, a union under max merge). Only Mist needs one plant field (see 2).
- **Earned tiers stay.** Where a badge moves to a new counter, the old `unlocked["id#n"]` dates stay and the card shows `max(tier earned, tier from new counter)`. Progress never goes down.
- **Quiet Garden:** `BadgeState.record` already returns early. Each mechanic below still works as play in Quiet Garden, with no counts, no marks and no moment.
- **Calm:** badge moments use `CelebrationStyle.small` (half the petals, slower). No timers, no "you missed it" lines, nothing that goes away with a warning.
- **Reduce Motion (system or the app's switch):** every new animation has a still or cross-fade version.
- **Copy:** every new line goes into a `*Copy.all` list checked by `CopySafety` (no "miss", "left", "only", "last", "forget", "waiting", "empty").
- **Art:** reuse `badge_<id>_t1..t3` as they are. Only new scene art is listed.

## 1. Wild Discovery: the Field walk
**Today:** `storiesRead` marks plants whose fact card was shown. **Design:** "Discover plants outdoors", which the app cannot do.

**Mechanic:** some days a small wild flower peeks out on the **Garden page** (a strip along the path above the grid). Tap it to open a card with its name, one fact and a Listen button (`ReadAloud`). Home stays as it is: weather, the quest and nudges already live there.
- **Which days:** `WildWalk.isOut(seed: weatherSeed, day: WeatherDay.key)`, mixed the same way as `VisitorSpawner.friendOfTheDay` with its own salt, true on about 3 days in 7. It is never out on a weather-event day or a `quietVisit` (ceremony) visit, so the Garden page shows one surprise at a time.
- **Which flower:** a new pure list `WildFlowers` of 15 real wildflowers (poppy, bluebell, cornflower, buttercup, forget-me-not and so on), kept apart from the 50 grown plants so it never touches plant earning. The day's flower is the first one not yet marked, in a fixed order, so gold takes about 5 weeks with no repeats. After all 15 (and in Quiet Garden) it comes from the seed with a "Seen again" card.
- **Counter:** new `.wildFinds` = `recordMark(.wildFinds, item: flowerId)`. Tiers **1 / 5 / 15** (design). `storiesRead` stays in the JSON but no badge uses it.
- **Copy:** "A wild flower is peeking out!" / "You found a wild poppy." / "Poppy seeds can sleep in the ground for years, then grow." (every fact checked against a source in `docs/research/`) / "Seen again: poppy". Blurb: "Find wild flowers on your garden path".
- **Art:** 15 small flowers drawn with `FlowerView`'s petal parameters (colour, petal count). No new image files.
- **Accessibility:** the flower is one button, at least 44 pt, labelled "A wild poppy is peeking out. Double tap to look." It comes after the page title in VoiceOver order so it can be found. Reduce Motion: no sway. Calm: shown, still. It goes away quietly at midnight, with no message.
- **Tests:** about 3 in 7 days over 1,000 seeds; never on event days; order walks all 15; marks merge; Quiet Garden no mark; UI fixture `-uitest-wildflower` (tap, card, AX XXXL dark audit).
- **Effort:** 3.5 days, including a mockup on localhost first and fact research.
- **Collisions:** the daily quest (Home) and the friend of the day (Visitors) use different salts and different screens. The weather banner wins on event days.

## 2. Mist Maker: a real Mist action
**Today:** `mists` counts free drops that arrive while the mister is owned. The mister's real effect is a faster trickle.

**Mechanic:** a **Mist** tend button on the plant page, shown once the mister is owned (or `showEverything`). One mist per plant per day. It is free (no drop spent), gives +1 growth (+2 for plants with the `tropical`, `epiphyte` or `shade` traits, which are true humidity lovers), and plays a short spray of fine droplets over the leaves with a soft hiss. The mister tier keeps its trickle effect, so the Shed upgrade still means something.
- **Rule:** `ToolEngine.mist(plant, inventory, now, …)`, going through `TendingEngine.applyGrowth`. Blocked with `.doneForToday` and the line "<name> is fresh and misty today. More mist tomorrow!" Growth stays small next to sun (2) and soil (4), so the economy barely moves (at most about 50 growth a day across a full garden).
- **Storage (essential):** one defaulted, CloudKit-safe `PlantCollectible.lastMistedAt: Date?`, merged by max in `DataReconciler`. Fallback with no field: a `day.mist.<plantId>` key in `badgesJSON`, but Quiet Garden skips badge writes, so not recommended.
- **Counter:** new `.mistSprays` (accumulates). Tiers **10 / 40 / 100** (design and app agree). The old `mists` drop count stays in the JSON but no badge uses it, and the `AppModel.swift:159` record call is removed.
- **Copy:** button "Mist". Done line above. Badge blurb "Mist your plants' leaves". Tip on first use: "Some plants love a little mist on their leaves."
- **Art:** the spray as a `PetalKit`-style particle burst (blue-white dots). The badge art stays.
- **Accessibility / Reduce Motion / Calm:** the button reads "Mist <name>". Reduce Motion: a 0.25 s cross-fade to a dewy leaf look. Calm: half the droplets, no sound. Quiet Garden: mist works (like sun), with no count.
- **Tests:** once a day (DST); trait bonus; not owned; quiet; merge and backup of `lastMistedAt`; Life "plenty" unchanged; UI audit.
- **Effort:** 3 days (field and migration, button row at AX sizes, animation).
- **Collisions:** the Life panel's "all care done" stays water/feed/sun, so mist never makes a meter look unfinished. The quest's care event can count a mist as love.

## 3. Field Notes: a notebook page per friend
**Today:** a high-water count of friend facts shown when the Visitors' book is open (`noteVisitorFactsRead`).

**Mechanic:** each met friend's page in `VisitorsBookView` becomes a notebook page: sticker art with a pencil-sketch treatment, "Met on <date>" (from `StickerAlbum.seenAt`, which already exists) and the fact. A **Listen** button reads the fact aloud (`ReadAloud.speak`). When the fact is read aloud to the end (`didFinish`), or the child taps "I read it!", a leaf stamp lands on the page and the page is collected.
- **Counter:** `factsRead` switches to marks: `recordMark(.factsRead, item: speciesId)`. It is high-water, so `record(value: marks)` keeps today's progress. Tiers **4 / 8 / 12** (12 friends exist; design and app agree).
- **VoiceOver:** `ReadAloud.shouldOffer` is false while VoiceOver runs, so "I read it!" is the path there, and Listen hides.
- **Copy:** "Listen" / "I read it!" / "Page added to your notebook." / "Meet this friend to fill this page." Blurb: "Fill your notebook with friend facts".
- **Art:** a sepia filter over the existing sticker art, and a leaf stamp (SF Symbol `leaf.fill` in a circle).
- **Reduce Motion:** the stamp fades in instead of pressing in. Quiet Garden: pages readable, no stamps.
- **Tests:** marks only for met friends; ReadAloud finish marks once; old value kept; UI page and AX audit.
- **Effort:** 1.5 days.
- **Collisions:** none. Weather stickers stay on their own pages and never count.

## 4. Gentle Net: a hello to a resting friend
**Today:** `butterflyPlays` 1 / 10 / 30. **Design:** 25 / 75 / 150 catches, which would copy First Catch (`catches` 1 / 10 / 50).

**The owner's idea, "catch without letting one fly off", is not used.** It is a fail condition a child cannot control.

**Mechanic:** in the moving game, now and then a visitor lands on a flower and rests for about 3 s (wings slowly open and close). A hello while it rests is a **gentle hello**: the net lowers softly and the sticker shows a tiny heart. It rewards patience and calm, not speed.
- **Rule:** `ButterflyGameModel` gives each flying visitor a seeded chance (about 1 in 3) to land once for 3 s (`resting = true`, `landedUntil`). `catchAt` returns whether the catch was resting, and `caughtGently: [String]` is added beside it. Reduce Motion and Calm already rest every visitor, so every hello there is gentle. That is accessible by design: children who cannot chase still earn it.
- **Counter:** new `.gentleHellos` (accumulates) through `BadgeFacts.catches`. Tiers **10 / 40 / 100**: rarer than catches, and lower than the design's 25 / 75 / 150 for that reason. Wake games count too.
- **Copy:** blurb "Say hello to a friend resting on a flower". Pill "Gentle hello!" Summary line "3 gentle hellos".
- **Tests:** seeded landings; resting catch counts, flying does not; Reduce Motion all count; Quiet Garden.
- **Effort:** 1.5 days.
- **Collisions:** catch radius by net tier unchanged. First Catch and Bee Friend count every hello, so they are unaffected.

## 5. Pruning Pro: a tidy trim at the right time
**Today:** `prunes` 5 / 25 / 75. **Design:** 5 / 20 / 50, "once per plant per 2 days" (already the shears' cooldown).

**Mechanic:** on a plant in flower (stage 3 or more), a **faded bloom** shows on some days: `seed ^ plantId hash ^ day`, about 1 in 3 days, never on a day it was pruned. A trim that day snips it (a little brown flower drops away, and a fresh bud shows at the next visit). The line is "Snipping faded flowers helps new ones grow.", which is a true gardening fact (deadheading). Before flowering, a plant at stage 2 or more shows a shaggy sprig once its cooldown has passed, so younger plants have a right time too.
- **Counter:** new `.tidyTrims` = a prune while the faded bloom or shaggy sprig shows. Tiers **5 / 20 / 50** (design). Plain trims still grow the plant as today. Nothing is stored: the cues are worked out from the seed, the day, `stage` and `lastPrunedAt`.
- **Copy:** "A faded flower is ready for a snip." / "Snip! A tidy trim." Blurb: "Trim plants when they are ready".
- **Accessibility:** the cue joins the plant's VoiceOver label ("ready for a trim"). Reduce Motion: no falling petal, a cross-fade. Calm: shown.
- **Tests:** cue rate; no cue on seedlings or pruned-today; tidy vs plain; old tiers kept; UI audit.
- **Effort:** 1.5 days (cue drawing on `FlowerView` and the plant art).

## Ranking (delight per effort)
| # | Badge | Delight | Days | Note |
|---|---|---|---|---|
| 1 | Field Notes | high | 1.5 | Reading-forward, fits the word game, almost no risk |
| 2 | Gentle Net | high | 1.5 | Calm hellos; fixes the catches copy |
| 3 | Pruning Pro | med-high | 1.5 | Real gardening lesson, nothing stored |
| 4 | Wild Discovery | very high | 3.5 | Best surprise, but needs content research and a mockup |
| 5 | Mist Maker | med | 3 | New field and a new tend button; widest reach |

**Recommendation:** build 1 to 3 now (about 4.5 days, no new stored fields). Mock up Wild Discovery on localhost next and build it after the owner sees it. Hold Mist until the owner accepts the one new plant field, or chooses the `badgesJSON` fallback. After each switch, run `refreshBadgeFacts` once at launch with `announce: false`, so re-tiered badges arrive quietly.

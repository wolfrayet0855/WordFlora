# Decisions research, 2026-11-04

Inputs read: PM plan, STATUS.md, Economy.swift, TendingEngine.swift, ToolEngine.swift, ProgressionPolicy.swift, Plants.json, PlantDetailView.swift. Web: Merriam-Webster / OED via Grammarphobia (daisy), Online Etymology Dictionary via search snippet (rose; direct fetch returned 403), Wikipedia/Wiktionary/NC State (Helianthus). The two research notes in docs/research were not re-read in depth; evidence below is from the simulation, the code, and general design knowledge, not fresh GDC or SDT citations. Treat SDT/pacing claims as design reasoning, not measured data.

## Decisions

| Q | Decision |
|---|---|
| Q1 | Two waterings per day. |
| Q2 | Yes, raise levelBaseCost to 200. |
| Q3 | No fourth meter. Soil shows through Feed's done state. Reword the plan rule. |
| Q4 | "Go to my garden", and make it land on the garden (or the first plant). If it must land on Home, use "Go home". |
| Q5 | Feasible. Write all 50, but ship in tiers: pilot 10 verified first, others only when verified. Fall back to "Did you know?". |

## Simulation method

Per day: waters x water points + feed 4 + sun 2. Water is 3, or 5 with a soil boost (3 x 1.5 = 4.5, rounds to 5 in `Int(desired.rounded())`). The boost lasts 3 days after feeding, so a daily feeder is always boosted. Stage thresholds are 6, 22, 50, 100 percent of cost. Cost = levelBaseCost x [1.0, 1.1, 1.2, 1.3, 1.4][level-1]. Days = ceil(threshold x cost / GP per day). Sun uses `sunGrowth = 2` (lamp tiers give more; ignored). Day 1 counts as a full day.

GP per day: 2 waters 12 (16 boosted); 3 waters 15 (21 boosted).
Current game (cap 10/day, from the code): days to stages 1-4.

| Level | Old (cap 10, base 180) |
|---|---|
| L1 | 2 / 4 / 9 / 18 |
| L3 | 2 / 5 / 11 / 22 |
| L5 | 2 / 6 / 13 / 26 |

### Q1 and Q2: days to reach stages 1 / 2 / 3 / 4 (Full bloom), daily feeder, boosted

| Base | Waters | L1 | L3 | L5 |
|---|---|---|---|---|
| 180 | 2 | 1/3/6/12 | 1/3/7/14 | 1/4/8/16 |
| 180 | 3 | 1/2/5/9 | 1/3/6/11 | 1/3/6/12 |
| 200 | 2 | 1/3/7/13 | 1/4/8/15 | 2/4/9/18 |
| 200 | 3 | 1/3/5/10 | 1/3/6/12 | 1/3/7/14 |

Unboosted (never feeds, or lets the boost lapse), full bloom:

| Base | Waters | L1 | L3 | L5 |
|---|---|---|---|---|
| 180 | 2 | 15 | 18 | 21 |
| 180 | 3 | 12 | 15 | 17 |
| 200 | 2 | 17 | 20 | 24 |
| 200 | 3 | 14 | 16 | 19 |

Casual player (1 water + sun daily, no feed; 5 GP): not simulated in the table; the 2-water no-feed rows above (8 GP/day) give 23 to 25 days at L1, so casual play is never punished into months.

### Q1 reasoning (2 vs 3)
- Today's full bloom is 18 to 26 days. Two waters at base 200 gives 13 to 18 boosted, 17 to 24 unboosted: close to today's pace, slightly faster. Three waters at 180 gives 9 to 12 boosted, which halves the pace and makes the "grow slowly" arc feel rushed.
- Water drops are shared across plants and come from wins plus a trickle (1 per 4 h, cap 5, `waterBankCap` 40). Three waters x 10 plants = 30 drops a day, which would push the player toward the rewarded ad for drops, a monetization pressure the plan wants to avoid for kids. Two waters = 20.
- Stage 1 arrives on day 1 to 2 either way, so the first-win reward is the same. The extra water adds little felt progress but adds one more chore per plant.
- Daily-loop evidence (Finch, Pocket Camp, Tamagotchi, Forest, from general design knowledge, not freshly cited): healthy care loops give 2 to 3 distinct short actions per pet per day, and total session around 2 to 5 minutes. Distinct actions (water, feed, sun) matter more than repeating one. SDT: competence is served by a clear "done for today" state; autonomy by letting the player skip without loss. Two waters plus feed plus sun is four taps per plant, which fits a 10-plant garden in a few minutes. Three waters makes five.
- Make it tunable: keep `waterPerDay` in Economy so a playtest can flip to 3 without a migration.

### Q2 reasoning (180 vs 200)
Keep the old pace. At 180 with 2 waters, boosted full bloom is 12 to 16 days (faster than today's 18 to 26 by a third). At 200 it is 13 to 18, which matches the plan's claim of 14 to 17 and stays near old pace for a typical player. Higher levels are still gated by the 1.1 to 1.4 multiplier. Risk: unboosted L5 is 24 days; acceptable. Playtest flag stays in the plan's risk list.

## Q3: fourth "Soil" meter

Recommend no.
- Clutter: three meters (Water, Sun, Happiness) already feed a Life panel that collapses into a sheet at large text. A fourth adds a row at every size and a fourth bar to read at grade 2.
- Clarity: Happiness is hearts, not an action meter, so the "every action has its own meter" rule is already not literally true. Reword the rule to: "every action has its own done state." Feed already gets a button done state ("Fed today") and a blocked line.
- Soil has a slow state (richness, 3-day boost). If the owner wants it visible, show a small boost glow or a leaf badge on the plant or on Feed, not a meter.
- Cost of adding: meter copy, snapshot/UI tests, widget, Quiet Garden rules, and a 4-row layout at xxxLarge.
- Revisit only if playtesters ask "why can't I feed?" after the done state ships.

## Q4: first-win button label

| Label | Grade-2 words | Matches where it goes (Home) | Confusion risk |
|---|---|---|---|
| Go to my garden | yes, all common | partly: Home is not "the garden" | Low if it lands on the garden or plant; medium if it lands on Home |
| Back home | yes | exact | Medium: "back" implies they were somewhere else; child may not know "home" |
| Continue | yes | no promise | High: adult, says nothing about where; the original complaint was a destination mismatch |
| See my garden | yes | no | Medium: "see" implies viewing only, not tending |

Recommendation: "Go to my garden", and change `finishOnboarding()` to open the garden (or the new plant's page, where the Water/Sun/Feed buttons are) so the label is true. The owner's confusion was label-says-X, app-does-Y; any label fixes it only if it names the real destination. Fallback if Home must stay: "Go home", with body "Your plant is waiting in the Garden" changed (the word "waiting" is banned; use "Your plant is in the Garden"). Note the plan's body text and title are fine. Test: tap, assert the destination matches the label.

## Q5: name stories for all 50 plants

Current state: botanicalFact is a single sentence, 6 to 23 words (median about 10). Name stories today: Daisy ("Its name comes from 'day's eye'..."), Passionflower ("Its name comes from Spanish missionaries..."). Sago Palm mentions "Despite the name" but is a classification fact. Plan says 3; I count 2 clear plus Sago borderline. Confirm in T6.

Feasibility: yes for about 35 to 40; the rest are poor candidates.
- Hard or dubious: Puya raimondii (named for Antonio Raimondi, an Italian-Peruvian naturalist; "puya" from Mapuche, "point"; verify), Welwitschia (named for Friedrich Welwitsch; verify), Franklin Tree (Franklinia, for Benjamin Franklin; verify), Lithops (Greek lithos "stone", ops "face"; verify), Rafflesia (Stamford Raffles), Wollemi (Aboriginal place name; verify), Coco de Mer (French "coconut of the sea", legend of sea coconuts; folk story risk), Ghost Pipe, Corpse Flower (Amorphophallus titanum: Greek "shapeless phallus", skip for kids; use the common name "corpse flower" story instead).
- Easy compound names: sunflower, snapdragon, dandelion (French dent-de-lion "lion's tooth", widely documented but verify), strawberry (folk etymology disputed; skip or label "no one is sure"), bamboo (loanword uncertain), hibiscus (Greek ibiskos, uncertain).
- Rule: if sources disagree or say "uncertain", write "no one is completely sure" or use the existing botanical fact. A wrong story is worse than none.

Risks for children: folk etymologies (strawberry "strewn", bluebell myths), confidently told legends (coco de mer, passionflower missionaries are legend-adjacent), sexual or violent roots (Amorphophallus, dandelion pun is fine), colonial-era naming (missionaries, "discovered by") needing neutral wording, and AI-written stories that invent plausible Latin or Greek. Guard against all with the method below.

Fact-check method (two sources, one authoritative):
1. Draft from a reference, never from memory.
2. Source A, a dictionary or authority: Online Etymology Dictionary, OED, Merriam-Webster, or Wiktionary (with its cited sources). Source B for the plant: Kew Plants of the World Online (POWO) for the botanical name and author, Royal Horticultural Society or Missouri Botanical Garden Plant Finder for common-name notes.
3. Both must agree on the original-language word and meaning. If not, mark UNVERIFIED and do not ship.
4. Record sources and date in `docs/research/name-stories.md` (or a sibling JSON field `nameStorySource`). A human reviews every story.
5. Run `CopySafety` and a reading-level check (under 40 words, short words, no banned words, no "dead", "lost").

Template (under 40 words):
> "{Common name}" comes from {language} "{original word}", which means "{meaning}". {One fun fact in one sentence.}

Fields: nameStory (string), nameStoryOrigin (language), nameStorySources (array, not shown). Card title: "How {Name} got its name"; fallback "Did you know?".

### Example stories

Daisy (CONFIRMED enough: Old English dægesēage "day's eye", Middle English dayeseye, per Merriam-Webster and OED via Grammarphobia; closing ray at night):
> "Daisy" comes from Old English "dæges ēage," which means "day's eye." The flower closes its petals at night and opens again in the morning, like an eye waking up. (34 words)

Sunflower (PARTLY VERIFIED: the genus Helianthus is Greek helios "sun" + anthos "flower", named by Linnaeus per Wiktionary and Wikipedia; the English word is a plain compound and the exact first English use was not confirmed):
> "Sunflower" is named for the sun. Its scientific name, Helianthus, comes from the Greek words "helios," meaning sun, and "anthos," meaning flower. Its big round head looks like a golden sun. (UNVERIFIED for the English compound's date; the Greek parts are confirmed.)

Rose (PARTLY VERIFIED: Online Etymology Dictionary via search: Old English rose from Latin rosa, probably from Greek rhodon, possibly from an Iranian root *vrda-; the Iranian link is hedged by the source):
> "Rose" comes from the Latin word "rosa." The Latins likely borrowed it from Greek "rhodon." Some word experts think it began far away, in an old Iranian word. (UNVERIFIED: the Iranian origin is a scholarly hypothesis; keep "some word experts think" or drop that sentence.)

### Pilot of 10 (easy, well documented, kid-friendly)
Daisy, Sunflower, Rose, Dandelion (French dent-de-lion), Snapdragon, Passionflower (verify "missionaries" framing and soften), Lavender (Latin lavare "to wash" is the common claim; verify), Hibiscus or Bamboo only if a source is confirmed, Venus Flytrap (named for the Roman goddess; Venus link is disputed, so verify), Corpse Flower (common name only). Swap any that fail the two-source rule for Marigold ("Mary's gold", disputed, verify), Lotus, or Orchid (Greek orkhis "testicle", skip for kids). Ship the pilot first, review the card, then batch the rest by level.

Estimate: pilot 10 about 2 to 3 hours with sourcing; full 50 about 1 to 2 days; plus a human review pass.

## Sources
- Merriam-Webster, "daisy" (https://merriam-webster.com/dictionary/daisy)
- Grammarphobia, "daisy" (https://grammarphobia.com/blog/2011/11/daisy.html)
- Online Etymology Dictionary, "rose" (https://www.etymonline.com/word/rose; reached via search snippet only)
- Wikipedia/Wiktionary/NC State, Helianthus
- Not consulted directly: Kew POWO, RHS, Missouri Botanical Garden (recommended for the writing pass).

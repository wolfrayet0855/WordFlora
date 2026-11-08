# Engagement quick wins (research, 2026-11-07)

Ask: study popular calm, casual and kids apps for small mechanics that build interaction, then pick the top two for 1.0
(scope freeze released "as needed"; submit target Thu 2026-11-19).

**Lead ruling (2026-11-07): A and B approved, C added.** All three are independent builder tasks. Builds run one at a
time: after the G3 merge and the text-fit pass, before AdMob G4a. None adds a stored model field, a permission, a push
notification, analytics or an ad placement. Fable could not be reached by name; the lead ruled.

Constraints applied to every candidate: calm tone, no guilt or streak loss, no dark patterns, no countdowns, no tracking,
no ads for under-13 or unknown ages, kid-safe copy (`Rules/CopySafety.swift`, which bans "last", "only", "left", "miss",
"forget" and more), works offline, no new CloudKit fields (a new field means another Production schema deploy), no new
permissions, iOS 26 accessibility audits pass (text styles, no Dynamic Type caps, every word fits at AX XXXL).

## 0. What the research says (short)

- **Wordle:** the spoiler-free share grid spread the game. Players showed a result without spoiling it, and every post
  invited a "what's that?" from someone else ([Smithsonian](https://www.smithsonianmag.com/smart-news/heres-why-the-word-game-wordle-went-viral-180979439/)).
  We already have this as text (`DailyShare`).
- **Recaps (Spotify Wrapped, Duolingo year in review):** people share a story about their own behaviour, because it
  says something about them; recaps fail when they are dull, creepy or impersonal
  ([UX Collective on Wrapped](https://uxdesign.cc/why-is-spotify-wrapped-so-popular-5c503e79a3ee),
  [Duolingo wrapped](https://uxdesign.cc/duolingo-wrapped-your-year-in-languages-streaks-and-progress-43f7f95c3eac),
  [critique of copycats](https://justinqytang.substack.com/p/the-spotify-wrapped-model-why-companies)).
  A weekly rhythm (Pokemon Sleep's Monday research week, [Bulbapedia](https://bulbapedia.bulbagarden.net/wiki/Mission_(Sleep)))
  gives a natural, pressure-free beat. Pokemon Sleep's "unclaimed rewards are gone on Monday" is the part we do NOT copy.
- **Finch:** attachment to a named pet that you care for is the main driver. The pet waits and never dies or shames you;
  short post-adventure notes are a favourite moment ([Engadget](https://www.engadget.com/apps/this-self-care-virtual-pet-is-helping-me-get-my-act-together-160027169.html),
  [Paste](https://www.pastemagazine.com/article/finch-app-mental-health-virtual-pet-self-care)). Critics flag its streaks.
- **Neko Atsume:** no timers and no push notifications. You come back to see who visited, and discovery is the hook
  ([Ludus Novus](https://ludusnovus.net/2015/07/30/the-feline-grace-of-neko-atsume)). This is our Visitors model already.
- **Forest:** retention leans on loss aversion (leave the app and your tree dies). We rule this out by design
  ([review](https://makeheadway.com/blog/forest-app-review/)).
- **Sago Mini / Toca Boca:** open-ended digital toys with no scores, timers or failure states
  ([Kidscreen on Sago](https://kidscreen.com/2015/04/09/sago-sago-dishes-on-developing-for-the-preschool-market)).
  Petal notes and Living Touch already fit this.
- **Co-play (Joan Ganz Cooney Center, joint media engagement):** co-play rarely happens unless an adult facilitates it,
  and adults asking questions about the game leads to prosocial moments
  ([The New Coviewing](https://joanganzcooneycenter.org/publication/the-new-coviewing-designing-for-learning-through-joint-media-engagement/)).
- **Ethics limits:** 5Rights *Disrupted Childhood* names rewards, streaks, notifications and endless feeds as persuasive
  design that harms children ([5Rights](https://5rightsfoundation.com/in-action/disrupted-childhood-the-cost-of-persuasive-design-2023.html)).
  Common Sense warns against badges for raw engagement and against variable rewards
  ([Common Sense](https://www.commonsensemedia.org/kids-action/blog/kids-tv-has-rules-its-the-internets-turn)).
  The FTC's *Bringing Dark Patterns to Light* (2022) and the Epic settlement ($520 M) cover children's purchase and
  interface tricks ([summary](https://fenwick.com/insights/publications/ftcs-aggressive-enforcement-of-childrens-privacy-and-dark-patterns-a-cautionary-tale-and-simple-steps-companies-can-take-to-reduce-risk)).
  Apple guideline 1.3 requires a parental gate before links out or purchases in kids apps
  ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)). We are outside the Kids Category,
  but our own rule (`BadgeShare.isAllowed`) already applies that to sharing.

Takeaway: the safe mechanics are **reflection on what the player did** (no loss framing), **ownership and personalisation**,
**sharing a result that spoils nothing, for 13+ only**, and **making the existing return surfaces (widget, Home) feel personal**.
Variable rewards, streak counters, countdowns and "come back or lose it" are out.

## 1. Candidates

Hours = one builder, including tests. Every row: no new permission, no push, no analytics.

| # | Source app | Mechanic | Why it works | Fit with our constraints | Build (h) | Risk | Reuse |
|---|---|---|---|---|---|---|---|
| 1 | Spotify Wrapped, Duolingo, Pokemon Sleep, Finch | **Weekly garden note** on Home: what you grew this past week (words, new plants, friends met). 13+ can share an image | Reflection on your own play; ownership; a calm weekly beat; shareable identity | Good: positives only, no card if nothing happened, no "you were away". Copy must avoid "last" (banned) | 7.5 | Low. No model field (computed); seen-week in UserDefaults. AX: one new card | `GameRecord`, `PlantCollectible.createdAt`, `StickerAlbum.seenAt`, Home `noteCard`, `PlantShareCard` |
| 2 | Finch, Tamagotchi, Neko Atsume | **Make it yours:** "Give it a name" on the New plant card; "Show on my widget" on the plant page | Naming builds attachment; the chosen plant on the Home Screen makes the widget yours | Good: optional, never prompted twice, under-13 safe (name stays on device/iCloud) | 6.5 | Low. Name goes in existing `PlantCollectible.nickname`; pin in existing `PlayerProfile.widgetPlantID` (read by `WidgetActions`, never set by any UI today) | `PlantDetailView` rename alert, `PlantVoice.helloLine`, `WidgetActions`, `WidgetCenter` |
| 3 | (our own rule) | **Share age gate parity:** Daily Bloom and "Share this plant" gated like badges | Consistency; Apple 1.3 spirit; FTC/COPPA posture | Required | 1 | Very low | `BadgeShare.isAllowed`, `ParentalGate.isRequired` |
| 4 | Cooney Center JME, Khan Academy Kids | **Talk together:** for under-13, one grown-up question on the win card ("Ask your grown-up: where could we see a sunflower?") | Adult questions spark prosocial co-play; turns solo play into family talk | Good for kids; must not feel like homework; copy per word category | 5 | Low. Copy volume: needs ~20 templates through CopySafety | Win card, `WordEntry` level/category, `factAfterRound` |
| 5 | Animal Crossing photo mode, Wordle | **Garden postcard:** a share image of your garden (top 6 plants in their pots) | Pride; the image is the ad | 13+ only; species names only | 6 | Medium. ImageRenderer of many layered plants (memory, AX) | `PlantShareCard`, `PotArtView`, `LayeredPlantView` |
| 6 | Neko Atsume, Finch widget | **Widget states:** friend of the day or today's quest line on the medium widget | Gives a reason to glance; no notification needed | Good; Calm/Quiet rules apply | 4 | Medium. Device-unverified widget; quest seed must match app | `Butterfly.friendOfTheDay`, `DailyQuest`, `GardenWidget` |
| 7 | Finch adventure notes | **Plant thank-you note** once a week ("Daisy says: thank you for the drinks") | Warm, personal, short read | Overlaps #1; could become #1's closing line | 3 | Low | `PlantVoice` |
| 8 | Animal Crossing visitors, Neko Atsume | **Surprise visitor at open** resting in the garden | Discovery at return | Already planned: Gentle Net resting visitor | 0 (built) | n/a | G2b |
| 9 | Sago Mini, Toca | **Petal song echo:** the plant hums your last 5 petal notes back | Open-ended toy, no score | Good; sound off = silent | 3 | Low; audio timing | `PetalNotes` |
| 10 | Animal Crossing seasonal events | **First-bloom ceremony** when a plant reaches its top stage | Marks a milestone the player caused | Good | 6-8 | Medium; new art and celebration timing | `PetalConfettiView`, `BadgeMoment` |
| 11 | Wordle | **Daily Bloom image card** instead of text | Prettier share | Text already spreads fine; images can't paste into chat as easily | 4 | Low | `DailyShare` |
| 12 | Headspace, Calm | **Mindful moment:** "Breathe with your plant" 30 s sway | Calm brand fit | Off-mission for a word game; scope creep | 5 | Low | `LivingTouch` |
| 13 | Duolingo streak, Forest | Streak counter, streak freeze, "your tree will die" | Loss aversion | **Rejected** (guilt, loss) | n/a | High (product values) | `StreakEngine` exists, unshown |
| 14 | Merge Mansion, Pocket Camp | Timed events, energy refill timers, limited-time offers | FOMO | **Rejected** (countdown, purchase pressure) | n/a | High | n/a |
| 15 | Pokemon Sleep, Finch friends | Friend codes, see friends' gardens | Social proof | **Rejected** for 1.0: needs accounts/servers, under-13 contact risk | n/a | High | n/a |

## 2. Builder tasks (approved)

Rules for all three: text styles only (`Theme.font(...)`), no `.lineLimit` caps that cut words, no Dynamic Type caps,
`fixedSize(horizontal: false, vertical: true)` on wrapping lines, 44 pt targets, every string in a `...Copy` enum swept by
CopySafety in a unit test, unit tests red first, `performAccessibilityAudit` at default and AX XXXL plus a dark shot,
no audit excuse added. One branch per task, merged on its own. Keep `mediaanalysisd` disabled on the simulator.

### Task A: Weekly garden note (about 7.5 h)

**What:** on the first Home visit of a new week, a note card sums up the past Monday-to-Sunday in the player's garden.

**When it shows (pure rule `WeeklyNote.shouldShow`):**
- onboarding done (`guideSeen` or the first session finished) and the garden is at least 7 days old (`PlayerProfile.createdAt`);
- the current week key (start of the week holding `now`, Monday start, `Calendar(identifier: .gregorian)` with
  `firstWeekday = 2` and the device time zone) differs from `AppSettings.weeklyNoteSeenWeek` (new device-local
  UserDefaults key `weeklyNoteSeenWeek: Int`, day number of that Monday; never synced, never a model field);
- the past week has at least one positive item (see below). **No card if nothing happened**, never a "you were away" line;
- not while the nudge card shows; when a weather card or banner shows, the note waits for the next Home visit that week
  (show it once the weather card is gone). On a note visit the Plus offer card is held back (as with the forecast card).
- Shown at most once per week: shown = stored at first display; closing the Celebrate splash closes it, and it is gone on the next Home visit.

**Content (computed, `WeeklyNote.Summary`):** past week = `[weekStart - 7 days, weekStart)`.
- `words`: count of `GameRecord` with `won == true` and `date` in range (Daily Bloom wins included).
- `dailyBlooms`: count of those with `isDaily == true`.
- `newPlants`: `PlantCollectible` with `createdAt` in range, in arrival order, by **species name** (`name`, not nickname,
  so the card reads the same as the share image).
- `friends`: count of visitor ids whose `StickerAlbum.seenAt` is in range. Known limit: `seenAt` is the latest meeting,
  so a friend met again this week moves out of the past week. The note is computed at its first display (normally early
  in the week), so this is rare; documented, not fixed.
- Rows with 0 are hidden. Positives only. No comparisons with other weeks, no totals of days played, no streak.

**Copy (`WeeklyNoteCopy`; all pass CopySafety; no "last", "only", "left", "miss"):**
- Title: "Your week in the garden"
- Words: "You grew 1 word." / "You grew 12 words."
- Daily: "You solved 1 Daily Bloom." / "You solved 4 Daily Blooms."
- Plants: "New plant: Daisy." / "New plants: Daisy and Clover." / "New plants: Daisy, Clover, Fern and 2 more."
- Friends: "You said hello to 1 friend." / "You said hello to 3 friends."
- Closing line, picked by week number: "Your garden is glad you came by." / "Every word helps your garden grow." /
  "Thank you for all the care this week."
- Actions sit below the card (owner, 2026-11-08): "Celebrate" (a short petal splash with Done; Reduce Motion gives the
  still arc, Calm and Quiet Garden the slow drift; Done closes the note) and "Share my week" (13+ only).
- Quiet Garden: no numbers at all. Only "New in your garden: Daisy and Clover." plus the closing line. If no plant
  arrived, no card.
- VoiceOver: the card is one element with the title as a header and the rows read in order, then the buttons. Label
  example: "Your week in the garden. You grew 12 words. New plants: Daisy and Clover. You said hello to 3 friends."

**Share (13+ only):** "Share my week" shows only when `!ParentalGate.isRequired(ageBand:)` (the same rule as
`BadgeShare.isAllowed`). Image `WeekShareCard` in `Components/ShareCard.swift`, the `PlantShareCard` pattern: fixed warm
palette, 320 pt wide, header "WordFlora", the week rows (species names only, never nicknames, no date of birth, no
player name), and tagline "Guess words. Grow a garden." Caption: "My week in my WordFlora garden." Quiet Garden: share
hidden (no numbers to show).

**Look:** Home's existing `noteCard` style (icon `leaf.fill`), rows as a `VStack` of wrapping lines, buttons stacked
full width at accessibility sizes, side by side otherwise (the welcome card pattern). Reduce Motion: opacity only.

**Files:** new `Rules/WeeklyNote.swift` (rule, summary, copy); new `App/AppModel+WeeklyNote.swift` (fetch records,
plants, album; `weeklyNote: WeeklyNote.Summary?`, `markWeeklyNoteSeen()`); `App/AppSettings.swift` (one key);
`Views/HomeView.swift` (card in the note slot); `Components/ShareCard.swift` (`WeekShareCard`); `project.pbxproj`;
UI test flag `-uitest-weekly-note` (fixture: garden 10 days old, 12 wins, 2 new plants, 3 friends in the past week).

**Tests:** unit `WeeklyNoteTests` (week key at Sunday 23:59 / Monday 00:00, a DST week, a time zone change; garden age
6 vs 7 days; empty week = no card; zero rows hidden; singular/plural; "and N more" at 3+ plants; Quiet Garden names
only and no card without plants; seen week stops a second show; weather card defers it; share allowed per age band
(under 13 and nil = hidden); CopySafety on every string for counts 0-99 and long plant names). UI `WeeklyNoteUITests`:
card shows with the fixture, Celebrate opens the splash, Done closes the note and it does not return this week, share
hidden with `-uitest-age=under13`, audits at default and AX XXXL, dark screenshot.

### Task B: Make it yours (about 6.5 h)

**Where the name is stored:** the existing synced field `PlantCollectible.nickname: String` (already in the CloudKit
schema, already in `GardenBackup` and merged by `DataReconciler`). **No new field.** The widget pin uses the existing
`PlayerProfile.widgetPlantID: String?`, also already in the schema, backup and reconciler; `WidgetActions` already
prefers it, but nothing in the app sets it today.

**Name rule (new `Rules/PlantName.swift`, used by both the new button and the existing pencil):**
- trim whitespace and newlines; keep at most 16 characters (`prefix(16)` on Characters, so an emoji is never split);
- if what is left has no letter or digit (empty, spaces, emoji only, punctuation only), save `""` (back to the species name);
- no CopySafety on typed text (it is the player's own words);
- the typed name never leaves the device in a share: share cards and captions use the species name (Task C changes
  `PlantShare.caption` accordingly). It syncs through the player's own iCloud as it does today.

**B1. Name on arrival (win card):** on `earnedCard`, when `vm.earnedPlantIsNew` and the plant has no nickname, a
`SecondaryButtonStyle` button "Give it a name" under the plant fact (above the share button). It opens the existing
"Name your plant" alert (TextField placeholder = species name, buttons "Save" and "Not now"). After Save, the card
shows the plant's own hello by name on one line under the card: `PlantNameCopy.saved(name)` =
"Hello! I love the name \(name)." Hardware-keyboard letters must not reach the round while the alert is up (the
`BehindModalCard` rule). Shown on every new plant until named; never a second prompt, never a badge or reward for naming.
In Quiet Garden: same (it is not a number).

**B2. Show on my widget (plant page):** a row under the name card: button "Show on my widget" (icon `apps.iphone`);
when this plant is pinned it reads "On your widget" with a check and is not a button (VoiceOver: "On your widget").
Tapping sets `profile.widgetPlantID = plant.plantId`, saves, calls `WidgetCenter.shared.reloadAllTimelines()`, and
shows the line "Your Home Screen widget will show Daisy." (uses the display name; this stays on device). If
`WidgetCenter.shared.getCurrentConfigurations` reports no WordFlora widget, the line is "Add the WordFlora widget to
your Home Screen to see Daisy there." (no permission needed). The row also shows for a plant in the seed state (the
widget already draws seeds). Pinned plant missing after a sync: `WidgetActions` already falls back to the default pick.

**Copy (`PlantNameCopy`, CopySafety tested):** "Give it a name", "Not now", "Hello! I love the name \(name).",
"Show on my widget", "On your widget", "Your Home Screen widget will show \(name).", "Add the WordFlora widget to your
Home Screen to see \(name) there." Accessibility hints: "Opens a box to name your plant." / "Puts this plant on your
Home Screen widget."

**Files:** new `Rules/PlantName.swift` (rule + copy); `Views/GameView.swift` (`earnedCard`); `Views/PlantDetailView.swift`
(pencil save through `PlantName.clean`, the widget row); `App/AppModel.swift` (`pinToWidget(_:)`, `rename(_:to:)`);
`project.pbxproj`. UI flag `-uitest-new-plant` if the existing fixtures do not already land on the New plant card.

**Tests:** unit `PlantNameTests` (trim, 16 characters with emoji and accents, emoji-only and spaces = "", Save then
pencil shows the name, `WidgetActions` snapshot picks the pinned plant and falls back when it is missing, pin survives
`DataReconciler` with the other copy unset, CopySafety on all copy with a long name). UI: New plant card shows "Give it a
name", Save "Sunny" shows the hello line and the plant page title reads Sunny; button absent on a plant already named;
plant page pin flips to "On your widget"; audits on the win card with the new button and on the plant page at default
and AX XXXL (the card already holds a plant, fact, share and Continue: check that Continue is still reachable by
scrolling and nothing clips), dark shot.

### Task C: Share age-gate parity (about 1 h, bug fix)

**Bug:** in `Views/GameView.swift` `shareButton`, "Share your Daily Bloom" and "Share this plant" show at every age.
Badges already hide sharing for under 13 and unknown age (`BadgeShare.isAllowed`, built on `ParentalGate.isRequired`).

**Fix:** wrap both `ShareLink`s in `if app.canShareBadges` (which is `BadgeShare.isAllowed(ageBand: settings.ageBand)`, `App/AppModel+Badges.swift`) (or rename the rule to a shared
`ShareGate.isAllowed` used by badges, the daily, the plant and Task A). Change `PlantShare.caption` to the species-name
line only ("I found a Daisy in WordFlora!"), so a typed nickname never leaves the device. No layout change for 13+.

**Tests:** unit table test per age band (under 13, nil, 13-17, 18+) for the shared rule; `ShareTests` caption test
updated (no nickname). UI: under-13 win card has no share button; 18+ still has it; existing win-card audits stay green.

## 3. Rejected and why

- **Streaks, streak freezes, "don't break it" (Duolingo, Snapchat):** guilt and loss; 5Rights and Common Sense name them.
  `StreakEngine` stays unshown.
- **Loss aversion (Forest's dying tree):** our rule is that nothing earned is ever removed.
- **Timed events, energy timers, limited offers (Merge Mansion, Pocket Camp):** countdown pressure and purchase prompts;
  FTC dark-pattern territory for children.
- **Variable or random rewards for returning (daily spin, mystery box):** variable-ratio rewards are the core persuasive
  pattern in the research. Friend of the day stays deterministic per seed and day.
- **Friends lists and seeing others' gardens (Pokemon Sleep, Finch friends):** needs accounts or a server, collects data,
  and opens contact for under-13.
- **Push "your plant misses you":** banned copy, and no new notifications.
- **Daily Bloom image card:** the text grid already works and pastes anywhere; low gain.
- **Breathing moment:** off-mission for a word game.
- **Surprise visitor at open:** already planned as the Gentle Net resting visitor (G2b).

## 4. Bigger ideas for the backlog (list only; not added to docs/pm/backlog.md)

- Talk together co-play questions for under-13 on the win card (about 20 copy templates by word category, grown-up review).
- Garden postcard: a share image of the whole garden in its pots (13+).
- Widget states: friend of the day and today's quest line on the medium widget (needs device checks).
- First-bloom ceremony when a plant reaches its top stage (new art and celebration).
- Plant thank-you notes / Garden Memory letters on Sundays (overlaps the existing Garden Memory backlog item; could reuse
  Task A's weekly slot).
- Petal song echo: the plant hums back the last five petal notes.
- A first-met date per visitor (would need a stored field; it would make "new friends this week" exact in Task A).

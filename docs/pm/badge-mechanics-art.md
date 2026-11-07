# Badge mechanics: art, copy and behaviour (1.1)

Build spec for the four badge mechanics the owner approved for 1.1, in the backlog order: **Field Notes, Gentle Net,
Pruning Pro, Mist Maker**. It sits on top of `docs/pm/badge-mechanics.md` (the design) and the rulings in
`docs/pm/backlog.md` ("Badge mechanics"). Where the two differ, the rulings win:

- Field Notes marks a page on "I read it!" or on `ReadAloud` didFinish, **never on page open**.
- Gentle Net: land chance **1 in 3**, **one resting visitor on screen at a time**.
- Pruning Pro: **faded bloom only**. There is no shaggy sprig, so plants at stage 2 get no cue.
- Mist Maker: new field `PlantCollectible.lastMistedAt: Date?`, merged by max like `lastPrunedAt`.

What is in this lane (new files only, nothing is wired up yet):

| File | What |
|---|---|
| `design-preview/badge-mechanics/*.svg` | The 11 new art pieces (listed per mechanic below) |
| `design-preview/badge-mechanics/index.html` | Preview page: assets on light and dark, then each mechanic's states. `?theme=dark`, `?section=notes`, `?static=1` |
| `design-preview/badge-mechanics/render.sh` | Headless Chromium over file:// to `shots/*.png` (10 shots, light and dark) |
| `WordFlora/Rules/FieldNotesCopy.swift`, `GentleNetCopy.swift`, `PruningProCopy.swift`, `MistMakerCopy.swift` | Every user-facing string, with `static var all: [String]` for the CopySafety sweep. **Not in project.pbxproj yet** (the integrator adds them to the app and test targets) |

Badge art (`badge_<id>_t1..t3`) stays as it is. The SVGs here are drawing references. Draw them in SwiftUI
(`Canvas`/`Path`, like `WeatherShelterArt` and `PetalKit`) from the coordinates in each file, or add them to the asset
catalogue as vector PDFs. Each file's header comment gives its colours and anchor point.

## Rules for all four

- **Palette:** only colours already in the app: `PetalKit.palette` rose `#F2788A/#D9566C`, marigold `#F5C858`,
  centre `#E8A838`, stem `#4E9A55`, leaves `#5FA860/#3F8A4A`, the mister's water `#7CC4F0`, pot browns
  `#C98A4B/#9A5F2A`. New tints are only parchment `#F6EBD3` (with spine `#EADBB9`, edge `#D9C29A`, rules `#C9B48A`),
  dry tan `#D4B08A/#A9825A` for the faded bloom, and mist white `#E2F1FB`.
- **Flat style:** fills plus a darker stroke of the same hue (2 to 2.4 pt at 100 pt art), round joins, one white
  glint where a shape should look shiny. No gradients and no drop shadows inside the art.
- **Copy:** every line is in a `*Copy` enum and goes through `CopySafety.check`. It also avoids save, rescue, danger,
  warning, alert, locked, timer and countdown, which are not in `CopySafety.banned` yet (see Tests). Nothing says a
  friend went away, nothing counts down, and nothing says "you missed it".
- **Quiet Garden:** each mechanic still works as play. No `BadgeState.record`, no `recordMark`, no badge moment,
  **no counts and no progress anywhere** (no "4 pages of 12", no "3 gentle hellos", no tier bar).
- **Calm:** badge moments use `CelebrationStyle` small (`.smallCalm`). The extra Calm changes are listed per mechanic.
- **Reduce Motion** (system setting or the app's switch): every animation has a still or cross-fade version, given
  per mechanic.
- **Badge moment:** when a mark or count crosses a tier, the usual badge sheet comes after the feedback line, never
  on top of it. The feedback line shows first for at least 1.2 s.
- **Catalogue blurbs:** `Badges.json` blurbs change to the `blurb` constant in each enum (Field Notes keeps
  `factsRead`; the others get new counters, see `badge-mechanics.md`). Earned tiers stay.

---

## 1. Field Notes: a notebook page per friend

### Behaviour
- In `VisitorsBookView`, each **met** friend (in `StickerAlbum.seenAt`) gets one notebook page. Weather stickers keep
  their own pages and never count.
- The page shows the sticker in sepia, the name, "Met on 4 Nov" and the fact. Under the page: **Listen** and
  **I read it!**
- The page is collected, and the leaf stamp lands, **only** when:
  1. `ReadAloud` reports `didFinish` for this page's fact (not `didCancel`, and not if the page changed while it was
     speaking), or
  2. the child taps **I read it!**
- Opening, swiping or scrolling past a page never marks it.
- A collected page keeps its stamp for good, and **I read it!** becomes the "Stamped" state (not tappable). Listen
  still works.
- Counter: `recordMark(.factsRead, item: speciesId)`, then `record(value: marks)` (high-water, so today's progress
  stays). Tiers 4 / 8 / 12.
- A friend not met yet: the page shows the sticker as a faint outline (`grayscale(1)`, 35 % opacity), the title
  "A new friend" and the line "Meet this friend to fill this page." It has no buttons and no stamp.

### Art
| Asset | Use | Size / placement |
|---|---|---|
| `notebook-page.svg` | Page background, 300 x 400 | Fills the page card. Sticker window (dashed) at 66,44 size 168 x 140; ruled text from y 214, rules every 28. Spine with five binding holes on the leading edge. Two strips of tape. |
| `leaf-stamp.svg` | Stamp, 120 x 120 | Drawn at 84 pt, bottom trailing corner, inset 22 pt from the side and 34 pt from the bottom, 90 % opacity. The -12 degree tilt is part of the art. The specks are a mask, so the page shows through. |
| Sticker | The existing `<species>-sticker` art | 108 pt, centred in the window. Sepia: `.grayscale(0.25)` and `.colorMultiply(Color(hex: 0xF3E2C2))`, about CSS `sepia(.4) saturate(.85)`. The friend should still look like itself (an orange monarch), not brown. |

- Text: name in `.title3` rounded bold `#5B4A32`, "Met on" in `.footnote` at 80 %, fact in `.body` rounded
  `#5B4A32` on the 28 pt rules. Use system rounded, not a handwriting font, so Dynamic Type and reading level hold
  (the preview's Chalkboard face is only for the mockup). `#5B4A32` on `#F6EBD3` has a contrast of about 7.9:1.
- Dark mode: the page stays paper. Draw it at `.brightness(-0.06)` (92 %) so it does not glare, and keep the text
  colour.
- AX text sizes: the sticker window shrinks to 96 pt, the text grows, and the page scrolls inside the card. The stamp
  moves inline after the fact text (trailing), so it never covers words.
- Toast on collect: "Page added to your notebook." with the stamp at 22 pt, in the same style as the app's other
  pills, for 2 s.

### Motion
- **Stamp press (default):** the stamp starts at scale 1.35 and opacity 0 a little above its spot, then over 0.28 s
  (ease in) goes to scale 0.96 and opacity 0.9, then settles to 1.0 over 0.12 s. A soft stamp sound (the existing
  soft tap sound at about -6 dB) and a `.soft` haptic at contact.
- **Reduce Motion:** the stamp fades in, opacity 0 to 0.9 over 0.3 s, at scale 1. Same sound and haptic.
- **Calm:** the press version at half the speed (0.56 s / 0.24 s), with no sound. The haptic stays.

### Quiet Garden and Calm
- Quiet Garden: pages, facts and Listen all work. **I read it! is hidden**, no stamp lands, there is no toast and no
  page count. Stamps earned before Quiet Garden was turned on still show (they belong to the page, not to progress).
- Calm: as above, plus the small badge moment.

### Accessibility
- Each page is one element: `FieldNotesCopy.pageLabel(name:met:fact:stamped:)`, for example "Monarch. Met on
  4 Nov. Monarchs fly ... Leaf stamp."
- Listen: label "Listen", hint "Reads the fact out loud". **Hidden while VoiceOver runs** (`ReadAloud.shouldOffer`
  is false), so I read it! is the path there.
- I read it!: label "I read it!", hint "Adds a leaf stamp to this page". After a tap, post the announcement
  "Page added to your notebook." The Stamped state has the label "Stamped" and the `.isStaticText` trait.
- Not met: one element, "A new friend. Meet this friend to fill this page."
- Buttons are at least 44 pt tall and sit side by side, stacked at AX sizes.

### Copy (`FieldNotesCopy`)
| Constant | Text |
|---|---|
| `listen` | Listen |
| `readIt` | I read it! |
| `stamped` | Stamped |
| `pageAdded` | Page added to your notebook. |
| `unmetPage` | Meet this friend to fill this page. |
| `unmetTitle` | A new friend |
| `notebookTitle` | My field notes |
| `blurb` | Fill your notebook with friend facts |
| `metOn(_:)` | Met on 4 Nov |
| `pages(_:of:)` | 1 page of 12 / 4 pages of 12 (not in Quiet Garden) |
| `listenHint`, `readItHint` | Reads the fact out loud / Adds a leaf stamp to this page |
| `stampLabel`, `unmetLabel`, `pageLabel(...)` | VoiceOver, see above |

---

## 2. Gentle Net: a hello to a resting friend

### Behaviour (`ButterflyGameModel`)
- When a **flying** visitor spawns, the game's seeded `SplitMix64` gives it a **1 in 3** chance to land once. If it
  does, it gets a landing time 2 to 8 s after it enters the screen (seeded).
- **One resting visitor at a time:** when its landing time comes, it lands only if no other visitor is resting.
  Otherwise it skips its landing and keeps flying, with no message. Visitors that spawn while one rests can still
  draw a landing for later.
- It lands on the nearest flower spot the game already draws (the flowering plants along the bottom), gliding there
  over 0.6 s (ease out). It rests **3.0 s** (`resting = true`, `landedUntil`), then takes off over 0.4 s in its
  old direction and flies off the screen like any other visitor. No line says it went away.
- A hello on a resting visitor is a **gentle hello**: `catchAt` returns whether it was resting, and
  `caughtGently: [String]` grows. Hellos on flying visitors still count for First Catch and Bee Friend as today.
- Counter `.gentleHellos` (accumulates) through `BadgeFacts.catches`. Tiers 10 / 40 / 100. Wake games count too.
- Same seed, same landings, so tests stay deterministic.

> **A correction to `badge-mechanics.md`:** it says "Reduce Motion and Calm already rest every visitor". In the
> code (`ButterflyGameModel.spawn`) **only Reduce Motion** rests every visitor. Calm moves them at 60 % speed
> (`calmSpeed`). So Calm uses the landing rule above, with a longer rest (see Calm below).

### Art
| Asset | Use | Size / placement |
|---|---|---|
| Existing `<species>-idle` art | The resting pose | Body sits on the flower centre, 6 pt above it. Wings fold slowly: the wing layers' x-scale eases 1.0 to 0.42 and back over 2.4 s, so about one slow fold in the 3 s rest. The body and antennae do not move. |
| `resting-halo.svg` | Under the flower while a visitor rests | 120 x 60 at the visitor's size 90 pt, centred on the flower centre and 12 pt below it. Opacity breathes 0.85 to 1.0 over 2.4 s. Fades in with the landing and out with the take-off (0.3 s). |
| `gentle-hello-pill.svg` | "Gentle hello!" | 180 x 44 pill. The app draws the text at 17 pt rounded semibold `#2C3E2C` from x 44. It rises 24 pt from the hello point over 1.2 s, then fades over 0.4 s. It must stay inside the safe area. |
| `gentle-hello-heart.svg` | On the sticker | 34 pt at the sticker's top trailing edge, on the round summary and in the round's catch row. |

- The net on a gentle hello lowers softly: the same net art moves down over 0.35 s (ease out) instead of the usual
  quick swoop, then lifts. Sound: the usual hello sound at about -6 dB, plus a soft high chime from the pentatonic
  set. Haptic `.soft`.

### Reduce Motion
- Every visitor already rests (`restingLifetime` 8 s), so **every hello is a gentle hello**. That is on purpose:
  children who cannot chase still earn the badge.
- Wings are held still at x-scale 0.7. The halo shows with no breathing. The one-at-a-time rule does not apply,
  because nothing lands.
- The pill fades in and out in place (0.25 s in, held 1.0 s, 0.3 s out) and does not rise. The net does not move:
  the visitor cross-fades into its sticker.

### Calm
- Landings as above (1 in 3, one at a time). The rest lasts **5.0 s** (3 s / `calmSpeed`), so the slower game
  still gives time.
- The pill and heart show. No chime, only the soft hello sound. Small badge moment.

### Quiet Garden
- Landings, the halo, the soft net, the pill and the heart all still happen (they are play).
- **No count:** the summary shows no "N gentle hellos" line, there is no `.gentleHellos` record and no badge moment.

### Accessibility
- A resting visitor's label is `GentleNetCopy.restingLabel(name:)` ("Monarch, resting on a flower"), with the hint
  "Says a gentle hello". Flying visitors keep their usual label.
- On a gentle hello, post the announcement "Gentle hello to Monarch!". The pill itself is hidden from VoiceOver.
- A sticker with the heart reads "Monarch, Gentle hello".
- The first time any visitor rests (stored once, like other first-time tips), show `GentleNetCopy.tip` under the sky
  for 4 s.

### Copy (`GentleNetCopy`)
| Constant | Text |
|---|---|
| `pill` | Gentle hello! |
| `blurb` | Say hello to a friend resting on a flower |
| `tip` | Some friends rest on a flower. Say a soft hello! |
| `summary(_:)` | 1 gentle hello / 3 gentle hellos (not shown at 0, not in Quiet Garden) |
| `restingLabel(name:)`, `restingHint` | Monarch, resting on a flower / Says a gentle hello |
| `heartLabel` | Gentle hello |
| `announcement(name:)` | Gentle hello to Monarch! |

---

## 3. Pruning Pro: a tidy trim at the right time (faded bloom only)

### Behaviour
- **When the cue shows:** a pure function, for example
  `FadedBloom.shows(seed: weatherSeed, plantId:, dayKey: WeatherDay.key, stage:, pruneReady:)`. It is true when:
  - `stage >= 3` (in flower), **and**
  - Prune is ready for this plant now (`actionState(.prune)` is `.ready`, so it is not pruned today and not in the
    two-day shears cooldown), **and**
  - `mix(seed, stableHash(plantId), dayKey) % 3 == 0` (about 1 day in 3).
- `stableHash` must be a fixed hash such as FNV-1a over the UTF-8 bytes. **Not** `String.hashValue`, which changes
  every launch and would make the cue flicker. Mix it the same way as `VisitorSpawner.friendOfTheDay`, with its own
  salt.
- Without the shears, outside Quiet Garden and `showEverything`, the cue does not show, so it never invites a trim
  that is not possible.
- Nothing is stored. The cue comes from the seed, the day, the stage and `lastPrunedAt`.
- **A tidy trim** is a prune while the cue shows: it counts `.tidyTrims` (tiers 5 / 20 / 50), and the plant grows as
  any trim does. A plain trim on a day with no cue grows the plant as today and says the usual trim line.
- After a tidy trim, `lastPrunedAt` is now, so the cue goes away at once and cannot come back during the cooldown.

### Art
| Asset | Use | Size / placement |
|---|---|---|
| `faded-bloom.svg` | Replaces **one** bloom of the plant art | 100 x 100 box. Anchor (50,40) = the centre of the bloom it replaces. Drawn at 0.8 times that bloom's size. Choose the bloom with the same seeded mix (`% bloomCount`), so it is the same bloom all day. The neck droops 28 degrees. |
| `faded-petal.svg` | Falls after the snip | 26 pt. It starts at the faded bloom's anchor and falls 120 pt with a 30 degree sway and a 70 degree turn over 0.9 s (ease in), fading out over the last 20 %. Default motion only. |
| `fresh-bud.svg` | The next time the plant page opens after a tidy trim | 48 pt at the same anchor, until the next faded bloom day. It is shown once per trim and is not stored: it shows when `lastPrunedAt` is within the cooldown and that trim was tidy. If that cannot be known without storage, show it whenever `lastPrunedAt` is within the cooldown on a stage 3+ plant. |

- On the plant cards in the garden grid, the faded bloom also shows (at card size). It is the only cue there: no
  badge, no dot, no number.

### Motion
- **Default:** on "Snip!", the faded bloom cross-fades to the plant's normal art over 0.25 s while `faded-petal`
  falls. The shears' usual snip sound and haptic.
- **Reduce Motion:** no falling petal. The faded bloom cross-fades to the normal art over 0.3 s.
- **Calm:** the cue shows. The petal falls at half speed (1.8 s). The snip sound is quieter, as for every Calm tend.

### Quiet Garden
- The cue shows and the lines show (they are a gardening lesson). **No `.tidyTrims` count**, no badge moment.

### Accessibility
- While the cue shows, the plant art's label ends with ", ready for a trim" (`PruningProCopy.plantLabel(_:)`), and
  the Prune button's hint is "Snips the faded flower" (its label stays "Prune").
- After a tidy trim, announce "Snip! A tidy trim. Snipping faded flowers helps new ones grow."

### Copy (`PruningProCopy`)
| Constant | Text |
|---|---|
| `cue` | A faded flower is ready for a snip. |
| `tidy` | Snip! A tidy trim. |
| `fact` | Snipping faded flowers helps new ones grow. |
| `freshBud` | A fresh bud is growing. |
| `blurb` | Trim plants when they are ready |
| `cueSuffix`, `plantLabel(_:)`, `pruneHint` | VoiceOver, see above |

The `cue` line shows in the line under the plant, where the tend lines show today, while the cue shows and no other
line is showing. After a tidy trim, `tidy` and `fact` replace `TendCopy.trimmed` for that tap only.

---

## 4. Mist Maker: a real Mist action

### Behaviour
- A **Mist** tend button on the plant page, in the row as Water, Feed, Sun, Prune, **Mist**, Repot. It shows once
  the mister is owned (`inventory.tier(of: .mister) > 0`), with `showEverything`, or in Quiet Garden (like Prune,
  which needs no tool there).
- One mist per plant per **calendar day** (`Calendar.current.isDate(lastMistedAt, inSameDayAs: now)`, which is safe
  across daylight saving, the same as sun). It is free: no drop or scoop is spent.
- Growth: **+1**, or **+2** when the plant's catalogue traits contain `tropical`, `epiphyte` or `shade`. It goes
  through `TendingEngine.applyGrowth`. On a seed, the button shows the usual "Wake first" state.
- Blocked with `.doneForToday`: the button shows "Misty today" and the line `MistMakerCopy.done(name:)`.
- Storage: `PlantCollectible.lastMistedAt: Date?` (defaulted, `decodeIfPresent`, CloudKit-safe), merged by **max**
  in `DataReconciler` and carried by `GardenBackup`, the same pattern as `lastPrunedAt`.
- Counter `.mistSprays` (accumulates), tiers 10 / 40 / 100. Remove the old `mists` record call at
  `AppModel.swift:159`. The mister's trickle effect stays.
- The Life panel's "all care done" stays water, feed and sun, so the Mist button never makes a meter look
  unfinished.
- Button icon: SF Symbol `humidity.fill`, or the mister glyph from `ToolArt` if it reads at 20 pt.

### Art
| Asset | Use | Size / placement |
|---|---|---|
| `mist-puffs.svg` | The spray, at full spread | 160 x 100. Origin = the nozzle at (8,50), placed at the plant art's leading edge at 45 % of its height, fanning across the leaves. Scale it to the plant art's width times 0.65. 24 droplets and 3 puffs. |
| `mist-puffs-calm.svg` | The Calm spray | Same frame and origin: 12 droplets and 1 puff. |
| `dewy-drops.svg` | Dew on the leaves after a mist, and the whole Reduce Motion effect | 100 x 100, scaled to the leaf area of the plant art. The 5 beads should land on leaves. Per plant art, the bead points can move to that art's leaf anchors (the shapes stay the same). |
| Mister glyph | Optional, at the nozzle | The `mister-t1-color` body without its medallion (see the preview's `#mister` symbol), 56 pt, sliding in 12 pt from the leading edge during the spray. Leave it out if the plant art is crowded. |

- The droplets are PetalKit-style particles. Each dot travels from the origin to its place in the frame over 0.6 s
  (ease out, scale 0.3 to 1, with a small seeded jitter). The puffs swell from 0.6 to 1.0. Everything fades out from
  0.6 s to 0.9 s. Dew beads fade in at 0.5 s, stay 1.2 s and fade out over 0.4 s.
- Sound: a soft spray hiss, about 0.4 s and quiet. Haptic `.soft`.

### Reduce Motion
- No particles and no glyph. `dewy-drops` cross-fades in over 0.25 s, stays 1.2 s and fades out over 0.4 s. The
  hiss and haptic stay.

### Calm
- `mist-puffs-calm` (half the droplets), **no sound**, haptic stays. Small badge moment.

### Quiet Garden
- Mist works on every plant, with growth, no tool needed. **No `.mistSprays` count**, no badge moment.

### Accessibility
- Button label `MistMakerCopy.buttonLabel(name:)` ("Mist Fern"), hint "Sprays a fine mist on the leaves". When it
  is done: "Fern is misty today", with the line as the value.
- After a mist, announce the result line: `loves(name:)` for the +2 plants, otherwise `misted(name:)`.
- The button is at least 44 pt tall. At AX sizes the tend row wraps to two rows, like the other buttons.
- First time the Mist button appears: `MistMakerCopy.tip` under the row, once.

### Copy (`MistMakerCopy`)
| Constant | Text |
|---|---|
| `button` | Mist |
| `doneLabel` | Misty today |
| `done(name:)` | Fern is fresh and misty today. More mist tomorrow! |
| `loves(name:)` | Fern loves misty air! (tropical, epiphyte or shade plants, +2) |
| `misted(name:)` | Daisy has fresh, misty leaves. (other plants, +1) |
| `tip` | Some plants love a little mist on their leaves. |
| `needMister` | Find the mister in the Shed to mist leaves. (only if the button is ever shown before the mister is owned) |
| `blurb` | Mist your plants' leaves |
| `buttonLabel(name:)`, `buttonHint`, `doneButtonLabel(name:)` | VoiceOver, see above |

---

## Self-review of the art (shots in `design-preview/badge-mechanics/shots/`)

- `assets-light/dark`: all 11 pieces read on both grounds. The stamp's specks and the halo's dashes keep it light;
  the faded bloom's neck is low contrast on the dark ground on purpose, since it always sits on plant art.
- `notes-*`: the sepia sticker still reads as an orange monarch (the first try at sepia 0.75 turned it brown, so it
  was cut to about 0.4). The stamp sits clear of the fact text and the page curl. The page stays paper in dark mode.
- `net-*`: the resting monarch sits on the flower centre with the halo under it. The pill and heart read on the light
  sky and on the dark garden.
- `prune-*`: the faded bloom reads as "past its best" (tan, drooping) without looking sick or sad. The fresh bud
  matches the rose blooms.
- `mist-*`: the mister body without its medallion reads better than the medallion. The puffs were lifted to
  `#E2F1FB` at 82 % so they read as mist, not smoke, on the dark garden.
- Open item: on some plant art the 5 dew beads may land off the leaves. Move the bead points per plant (see the Mist
  art table).

## Test ideas

Copy (one test file, for example `BadgeMechanicsCopyTests`)
- Each of `FieldNotesCopy.all`, `GentleNetCopy.all`, `PruningProCopy.all`, `MistMakerCopy.all` gives an empty
  `CopySafety.check` for every line.
- The same lines contain none of save, rescue, danger, warning, alert, locked, timer, countdown (a local list in the
  test, until `CopySafety.banned` grows; adding them there would also check older copy, so check first that no
  existing line uses "save").
- No line is longer than 60 characters, apart from the VoiceOver `pageLabel`.
- `GentleNetCopy.summary(1)` is singular and `summary(2)` plural. Likewise `FieldNotesCopy.pages`.
- Each `blurb` equals the `Badges.json` blurb for its badge.

Field Notes
- Opening a page never marks it (the view model's `pageAppeared` leaves the marks the same).
- `didFinish` for the shown page marks once; a second `didFinish` does not add a mark; `didCancel` does not mark.
- A `didFinish` after the page changed marks nothing (it belongs to the old page).
- "I read it!" marks once, then the button state is Stamped.
- Marks only for met friends; a crafted id for an unmet friend is ignored.
- The old high-water `factsRead` value is kept when marks are fewer (progress never goes down).
- Quiet Garden: no mark, I read it! is hidden, no page count.
- VoiceOver running: Listen is hidden and I read it! is shown.
- UI: `-uitest-fieldnotes` fixture with a page, tap I read it!, stamp shown, AX XXXL dark audit.

Gentle Net
- Over 3,000 seeded flying spawns, the landing share is 1/3 within 3 points.
- There is never more than one resting visitor at the same tick (property test over many seeds and dt values).
- A rest lasts 3.0 s (5.0 s in Calm), then the visitor flies on and leaves the screen.
- A hello on a resting visitor appends to `caughtGently`; a hello on a flying one does not; both append to `caught`.
- Reduce Motion: every hello is gentle.
- Same seed, same landings.
- Quiet Garden: hellos and pill still happen, no `.gentleHellos` record, no summary line.
- First Catch and Bee Friend counts are the same as before.

Pruning Pro
- `FadedBloom.shows` is true on about 1/3 of days over 1,000 seeds x 365 days, for stage 3+.
- Never for stage 0 to 2, never when pruned today, never in the shears cooldown, never without shears (outside Quiet
  Garden).
- The same (seed, plant, day) gives the same answer across launches (the stable hash; a test with a fixed expected
  value catches a `hashValue` mistake).
- A prune with the cue counts `.tidyTrims` and gives the tidy line; without the cue it does not count and gives the
  plain line; both grow the plant the same.
- The old `prunes` tiers are kept (the max of old and new).
- Quiet Garden: cue and lines, no count.

Mist Maker
- One mist per plant per calendar day, including across a daylight saving change, and a new mist after midnight.
- +1 growth; +2 for `tropical`, `epiphyte` and `shade` traits.
- Hidden without the mister (not `showEverything`); shown in Quiet Garden; seeds show "Wake first".
- No drop or scoop is spent.
- `lastMistedAt` decodes as nil from old data; `DataReconciler` keeps the later date both ways; `GardenBackup`
  round-trips it.
- Life panel "plenty" is unchanged by a mist.
- Quiet Garden: growth applies, no `.mistSprays` record.
- The old `mists` drop count is no longer recorded.
- UI: plant page with the mister, tap Mist, "Misty today" and the done line, AX XXXL dark audit with the row wrapped.

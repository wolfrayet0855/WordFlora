# Butterfly net and Quick wings (design, 2026-11-06)

Read-only design against branch `3-feat-content-and-polish` (`Views/ButterflyView.swift`, `Rules/Butterfly.swift`,
`Rules/ButterflyGameModel.swift`, `Rules/ToolEngine.swift`, `docs/pm/badge-mechanics.md` section 4, `docs/pm/backlog.md`).
Mockup: `design-preview/butterfly-net/index.html` (PNG: `butterfly-net.png` beside it). `docs/pm/badge-mechanics-art.md`
named in the request does not exist in the repo; the Gentle Net art notes below stand in for it.

**Owner ask:** a visible net the player uses to catch visitors, and a slightly harder game for 13+. Under 13 and Calm stay
exactly as gentle as today. Reduce Motion resting rules stay as they are. Rewards stay as they are.

> Built in gate G2b (2026-11-07) with the visual review's must-fixes: rim `#8D9AA6` for silver, 5 pt, and a 1 pt ink
> outline on every rim tier by day (cream `#FAF7F0` at 80% on rim and handle in the evening sky); the resting net at 85%
> with its lowest point at least 24 pt above the "said hello" pill. Calm follows the art spec's correction: it moves
> visitors at 60% and uses the landing rule (5 s rest), so only resting hellos are gentle there.

## 0. What the game does today (the baseline we must not make harder)
- `ButterflyView` sends every `DragGesture` sample to `ButterflyGameModel.catchAt(x:y:radius:)`, which takes the nearest
  visitor within the radius. A white "swoosh" trail draws the finger path. No net is drawn in the game.
- Radius = `ToolEngine.netCatchRadius(tier:)` (48 / 64 / 80 pt) divided by the scene **width**, floored at 0.08.
- Two quirks that matter for this design:
  1. Positions are normalised by width (x) and height (y), but the distance is `hypot(dx, dy)` in those units. On a
     390 x 700 pt scene the catch area is an upright ellipse: 48 pt across, about 86 pt tall.
  2. The 0.08 floor is in width units. On an iPad (820 pt wide) every tier is at least 66 pt, so tier 1 and 2 feel the same.
- 35 s round, bar hidden in Calm (Calm ends after 5 hellos or Done, 0.6x speed). Reduce Motion spawns resting visitors
  that stay 8 s and are tapped. Misses cost nothing.

## 1. Two paces
One pure rule decides the pace when a round starts (`ButterflyPace.resolve`, new, in `Rules/ButterflyNet.swift`):

| Condition (first match wins) | Pace |
|---|---|
| Calm mode on | `.calm` (today's Calm game + net) |
| Wake game, Reduce Motion (system or app switch), VoiceOver or Switch Control running | `.gentle` |
| Age band unknown or under 13 | `.gentle` |
| Settings > Play "Easier butterflies" on | `.gentle` |
| Age band 13+ or 18+ | `.quickWings` |

So Quick wings is automatic for 13+ and 18+, with one off switch. Under 13 never sees the switch and never gets Quick
wings. Wake-game rounds (`WakeSheet`) always use `.gentle` and keep their own tuning.

| Rule | Gentle (and Calm) | Quick wings |
|---|---|---|
| Round | 35 s (Calm: no bar, 5 hellos or Done) | **45 s** (10 more seconds, never fewer) |
| Visitor speed | 0.06 to 0.14 widths/s (Calm x0.6) | **x1.3** (0.078 to 0.182) |
| Spawn gap | 1.2 s | 1.0 s (keeps the sky as full, since faster visitors cross sooner) |
| Hoop **radius in points** by Shed tier | 48 / 64 / 80 pt radius (96 / 128 / 160 pt across) + 6 pt grace | **40 / 56 / 72 pt radius** (80 / 112 / 144 pt across), no grace |
| What counts as a hit | today's area OR the finger OR the hoop (union) | the hoop only (true circle in points) |
| Path change | none | each flying visitor may turn **once**, with a 0.4 s tell |
| Perch (Gentle Net landing) | 1 in 3 land once, 3 s | 1 in 3 land once, **2 s** |
| After a hello | net can say hello again at once | net lifts for 0.25 s, then is ready |
| Rewards, stickers, badges | unchanged | unchanged |

"Exactly as gentle": the gentle hit area is a union that always contains today's area (legacy ellipse, legacy floor),
so no catch that works today can fail. The sweep (section 2) only adds hellos. Speed, round and spawn are untouched.

**Path change, no decoys.** A visitor's one "move" is decided by the seed at spawn: perch (1 in 3, if no other visitor
is resting, per the backlog ruling), else a turn (1 in 2), else straight. A turn is a swerve: for 0.4 s the visitor
shows its idle frame (wings flared) and slows to half speed (the tell), then flies off at 30 to 40 degrees up or down for
0.8 s and levels out. Never a reversal, never a fake visitor, never an off-screen dash. Turns never happen within 0.1
widths of an edge, so a visitor cannot swerve away just as it arrives.

## 2. How the net works
**State** is a pure struct `ButterflyNet` (new `Rules/ButterflyNet.swift`, unit tested, no SwiftUI):
`position`, `target`, `isDown`, `busyUntil`, `restPoint`, all in scene points.

- **Rest.** When no finger is down the net rests in the lower half of the scene, above the "said hello" pill: bottom
  right by default, then wherever the finger last lifted (clamped to the lower half). This keeps it in thumb reach for
  left and right hands. A resting net catches nothing.
- **Touch down = a scoop.** The hoop jumps under the finger (no travel, so it never sweeps the sky on the way) and
  tests once at that point. A plain tap is a complete swing, as today.
- **Drag = follow with a soft lag.** Each tick (the existing 30 Hz ticker), `position += (target - position) * (1 - exp(-dt / 0.06))`.
  The hoop trails the finger by a few points, enough to feel like a held net. The hit test is a **swept circle**: the
  capsule from last tick's hoop centre to this tick's, with the hoop radius. A fast swipe cannot jump over a visitor.
- **Lift.** The net glides back to its rest point over 0.3 s. No catch test on lift (no accidental hellos).
- **Hoop centred on the finger, not offset above it.** Direct touch is what a 6-year-old expects, and today's game works
  that way. The hoop is 80 to 160 pt across and the mesh is see-through, so the finger never hides the whole hoop.
  Rejected: a hoop held out above the finger (more reach, but kids aim with the finger and would miss).
- **Handle** points from the hoop to the nearest bottom corner, so it never covers the visitor being chased.
- **More than one at once.** A sweep says hello to every visitor in the capsule (gentle). Quick wings: one per sweep, then
  the 0.25 s lift; the next nearest stays for the next sweep.

**Hit-test geometry** (pure `NetGeometry`, in points; the model gets the scene size once per round):
- `distance(point, segment a-b)`: hit if `<= radius`. Inclusive at the rim.
- Points are converted with the real width **and** height, so the hoop is a true circle (fixes quirk 1 for Quick wings).
- Gentle: `hit = legacyHit(finger) || segmentHit(hoop, r + 6)`. `legacyHit` is today's `catchAt` maths, kept verbatim.
- Quick wings: `hit = segmentHit(hoop, r)`. No width floor (fixes quirk 2), so tiers mean the same on iPad.

**Model changes** (`ButterflyGameModel`):
- `init(..., pace: ButterflyPace)` (the `calm:` flag becomes `pace == .calm`; keep a convenience init for old tests).
- `static func duration(for pace)`, `speedFactor(for pace)`, `spawnGap(for pace)`.
- `Visitor` gains `move: Move` (`.straight`, `.perch(at:)`, `.turn(at:, up:)`), `landedUntil: Double?`.
- `catchSwept(from:to:finger:scene:radius:) -> [Hello]` where `Hello` = species, gentle flag, point. `catchAt` stays for
  VoiceOver and Reduce Motion taps. New `caughtGently: [String]` beside `caught`.
- Same seed, same game (existing test keeps passing; the new draws come after today's in the RNG order, or tests pin
  the new order explicitly).

**Catch animation** (view only; the visitor leaves the model at once, as today):
1. Fold (0.25 s): a ghost of the visitor scales to 0.45 and slides to the hoop centre; wings show the idle frame.
2. Lift (0.2 s): the hoop rises 12 pt and settles (spring, damping 0.6).
3. Free (0.5 s): the ghost flutters up out of the mesh and fades. **It is a hello, not a capture**: the visitor always
   flies away. The sticker and name pill (`VisitorsCopy.caughtPill`) and the "New friend" card stay as today.
- Gentle hello (resting visitor): the net lowers onto the flower from above (0.35 s ease-out) instead of the sweep look,
  and a small heart shows on the sticker pill.
- Calm: same animation, half the petals elsewhere as today; no lift wait.
- The old white swoosh trail is removed: the net replaces it.

**Sound and haptics** (existing infra only, no new audio files):
- Hello: `app.play(.butterfly)` as today. Gentle hello: `app.play(.butterfly, volume: 0.7)`.
- No swing sound (one sound per event, `Sound.swift` rule).
- Haptic on each hello: `.sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: hellos)` gated by
  `settings.hapticsOn`, beside the existing `.success` on the summary.

## 3. Shed net tiers
All net sizes are a **radius in points** (the smallest hoop, 40 pt radius, is 80 pt across, well above the 44 pt
target size; the hoop is a hit area, not a button). `ToolEngine.netCatchPoints` stays `[48, 64, 80]` (gentle). Add `netCatchPointsQuick = [40, 56, 72]` and
`netCatchRadius(tier:pace:)`. The hoop drawn is the radius used, so what you see is what says hello.
`ShedCopy.effect(.net, tier:)` stays "Small / Bigger / Biggest catch circle" (true in both paces). The Visitors page
"Your net: small" card is unchanged.

## 4. Gentle Net badge interplay (`badge-mechanics.md` section 4, backlog ruling)
- The perch is the badge's landing rule: 1 in 3, one resting visitor on screen at a time, 3 s gentle / 2 s Quick wings.
  Building the net and the badge together shares this code.
- **Both count.** Every hello (flying or resting) counts for First Catch, Bee Friend and the album, as today.
  A hello to a resting visitor is also a **gentle hello** (`.gentleHellos`, tiers 10 / 40 / 100). Reduce Motion and Calm
  rest every visitor, so every hello there is gentle, as the badge doc already says.
- A gentle hello does not ask the net to move slowly. Considered for Quick wings and rejected: an invisible rule.
- Quick wings has shorter perches but a longer round, so gentle hellos per round land about where the gentle game is
  (to be checked in the seeded simulation test, section 8).

## 5. Settings, Visitors page, copy
- `AppSettings.easierButterflies: Bool`, key `easierButterflies`, default false, device-local (like Speed bloom).
- Settings > Play, after Speed bloom, shown only when the age band is 13+ or 18+ and Calm is off:
  Toggle "Easier butterflies" (`settings.easierButterflies`) and a footnote.
- Visitors play card in Quick wings: a "Quick wings" chip (`visitors.quickWings`) and its own blurb (the current blurb
  says "About half a minute", which is no longer true at 45 s).

| Key | Text |
|---|---|
| `VisitorsCopy.quickWings` | Quick wings |
| `VisitorsCopy.playBlurbQuick` | Follow the visitors with your net. They flit and turn. Every visit is a good one. |
| `VisitorsCopy.easierToggle` | Easier butterflies |
| `VisitorsCopy.easierFootnote` | Visitors flit and turn more, and the net starts smaller. Rounds are a little longer. Easier butterflies brings back the gentle game. |
| `VisitorsCopy.gentlePill` | Gentle hello! (from the badge doc) |
| `VisitorsCopy.flyingLabel(name)` | Monarch, flying |
| `VisitorsCopy.restingLabel(name)` | Monarch, resting on a flower |
| `VisitorsCopy.netHint` | Double tap to say hello with your net |
| `VisitorsCopy.swingAction` | Swing the net |

All go into `VisitorsCopy.all` (CopySafety) and are also run through `SpeedBloom.pressureWords` (no timer, clock,
seconds, hurry, fast, slow, race, fail). No digits, so Quiet Garden needs no variant. "Quick wings" passes both lists
("quickly" is on the avoid list, "quick" is not; Quick Bloom is the precedent).

**Quiet Garden:** Quick wings still applies by age (it is play, not a number). Nothing new shows a number. The summary
already hides water, points and soil. (Today the time bar and the "said hello" pill still show in Quiet Garden; out of
scope, flagged for the Quiet Garden owner.)

## 6. Accessibility
- **Targets.** The smallest hoop is 80 pt across. The net needs no aiming for VoiceOver or Switch Control. Done stays a
  toolbar button. The Settings toggle is a standard 44 pt row.
- **VoiceOver.** The net is `accessibilityHidden`. Each visitor stays an element (as today) labelled
  `flyingLabel` / `restingLabel` with `netHint`; activate = the net swings to it and says hello (animation per Reduce
  Motion). Announcements as today, with "Gentle hello." in front for resting visitors. VoiceOver running forces `.gentle`.
- **Switch Control / one switch.** A scene-level named action "Swing the net" says hello to the visitor nearest the net's
  rest point. Switch Control running forces `.gentle`.
- **Reduce Motion** (system or `reduceMotionOverride`): resting rules unchanged (spawn resting, 8 s, tapped). The net is a
  still frame: on tap it appears over the visitor with a 0.2 s cross-fade, no travel, no lag, no lift, no fold (the
  visitor cross-fades into the sticker pill). Drag still works, the net jumps with the finger. Always `.gentle`.
- **One hand.** Rest point follows the last lift; visitors never fly above y 0.1 (under the bar) as today; perches sit on
  the garden bed, in thumb reach.
- **Dynamic Type.** No new in-scene text beyond the existing pill. The Quick wings chip wraps under the title at
  accessibility sizes.
- **Evening sky.** Rim colours are light enough on `#1F2A4A`; the tier 1 wood rim gets a 1 pt `#FAF7F0` outline in the
  evening (contrast with the dark sky, checked in the mockup frame 4 style).

## 7. Art
Drawn in SwiftUI (`ButterflyNetView`, a `Canvas` or shapes), not new image files, so the hoop is exactly the catch radius
at any tier and size. Colours from the Shed icons `tool_net_t1..t3.svg`:

| Tier | Rim | Mesh | Extra |
|---|---|---|---|
| 1 | wood `#C98A4B` | `#9A5F2A` at 55% | none |
| 2 | silver `#C5CED6` | `#8D9AA6` at 60% | grip band `#8D9AA6` on the handle |
| 3 | gold `#F5C84C` | `#D49A1E` at 60% | grip band `#D49A1E`, a small sparkle `#F2B705` at the rim |

- Hoop fill `#EAF6F3` at 35%; mesh = two line sets at +35 and -55 degrees, 9 pt pitch, clipped to the hoop; rim 5 pt;
  handle `#B07A4B`, 7 pt, round caps, about 1.1 x the radius long. Ink outline `#3B3B3B` 1 pt on the rim matches the
  app's sticker style.
- Mesh "pocket": during the fold step the mesh scales 1.08 below the rim for 0.25 s (reads as the visitor sitting in it).
- Gentle hello heart: SF Symbol `heart.fill`, `#E25B7B`, 14 pt, on the pill.
- No changes to the Shed icons or badge art.

## 8. Tests
**Rule tests** (`WordFloraTests/ButterflyNetTests.swift`, new, and additions to `ButterflyGameModelTests`):
- Pace table: every row of section 1 (under 13, nil, 13+, 18+, 13+ with Easier, Calm at any age, Reduce Motion,
  VoiceOver, Switch Control, wake).
- Geometry: inside / on the rim / outside; true circle on a 390 x 700 scene (a visitor 60 pt straight below the hoop is a
  hit at r 64, 70 pt is not in Quick wings); swept capsule catches a visitor at (150, 40) on a 0 to 300 swipe at r 48 with
  no sample near it; touch-down does not sweep from the rest point; lift tests nothing.
- Gentle never harder: over 1,000 seeded positions and 3 scene sizes (iPhone SE, iPhone 15, iPad), every point that
  `legacyHit` accepts is accepted by the gentle rule.
- Lag: converges within 5 px in 0.2 s; zero lag under Reduce Motion.
- Speed tiers: Quick wings spawns `|vx|` in 0.078 to 0.182; gentle in 0.06 to 0.14; Calm x0.6. Quick wings hoop 40 / 56 / 72,
  gentle 48 / 64 / 80. Durations 35 / 45 / Calm infinite.
- Moves: at most one move per visitor; a turn always has a 0.4 s tell before it; never within 0.1 of an edge; never two
  resting visitors; perch 3 s gentle, 2 s Quick wings; no turns in gentle; Reduce Motion spawns are unchanged (resting,
  8 s, same positions for a seed).
- Gentle hellos: resting hello flagged, flying not; Reduce Motion and Calm all flagged.
- Rewards: `ButterflyRewards.summary` identical for the same catches in every pace; plays past 3 a day still add stickers.
- Simulation: a scripted "sweeping player" over 200 seeds catches on average 15 to 30% fewer per 35 s in Quick wings than
  gentle, and at least 1 per round in 99% of seeds (tuning guard, not a hard rule).
- Copy: new strings pass `CopySafety.check` and `SpeedBloom.pressureWords`.

**UI tests** (`WordFloraUITests`), with existing flags `-uitest-age=`, `-uitest-calm`, `-uitest-reduce-motion`,
`-uitest-seed`, `-uitest-quiet`, `-uitest-dark`, and two new ones: `-uitest-easier-butterflies` and
`-uitest-butterfly-short` (6 s round, so a test reaches the summary).
- `-uitest-age=thirteenPlus`: Settings shows `settings.easierButterflies`; with `-uitest-calm` it does not;
  `-uitest-age=under13` it does not.
- Visitors page shows `visitors.quickWings` for 13+, not for under 13 or with Easier on.
- The scene carries `accessibilityIdentifier("butterfly.scene.quickWings")` or `.gentle` (identifiers are not spoken).
- 13+ short round: drag across the scene, summary appears, rewards row shows; with `-uitest-quiet` it does not.
- Reduce Motion + 13+: scene is `.gentle`; activating a visitor element raises "said hello".
- Accessibility audit (dark, AX XXXL) on Settings > Play and the Visitors card.

## 9. Effort (builder-hours)
| Piece | Hours |
|---|---|
| `ButterflyPace`, `ButterflyNet`, `NetGeometry` (pure) + tests | 7 |
| Model: pace constants, moves (turn + tell), swept catch, gentle flag + tests | 7 |
| `ButterflyNetView` (tiers, evening outline), lag, fold / lift / free, gentle lower, remove swoosh | 8 |
| Reduce Motion still frame, VoiceOver labels and "Swing the net", Switch Control | 3 |
| Settings toggle, Visitors chip and blurb, copy, haptics | 2 |
| UI tests + two launch flags + audits | 3 |
| Localhost mockup review with the owner, playtest tuning (speed factor, perch) | 3 |
| **Total** | **33 (about 4 days)** |

The Gentle Net badge on top (counter, badge facts, summary line) is about +5 hours when built in the same branch, since
the perch lives here.

## 10. Risks
- **"Catching" animals for children.** Keep the hello framing everywhere; the visitor always flies free after the fold.
  No jar, no "caught" word in copy (the existing Shed line "Catches visitors gently" is the only one, and is kind).
- **Under-13 feel drifting.** Guarded by the "gentle never harder" property test and by keeping `legacyHit` verbatim.
  A designer must not "clean up" the union later.
- **Teens finding it still easy, or a child who chose 13+.** The off switch covers the second; the tuning simulation and
  one playtest cover the first. Speed factor and hoop sizes are constants, cheap to tune.
- **Turns read as a trick.** The 0.4 s tell, one turn per visitor, no edge turns. If playtests still call it unfair,
  drop turns and keep speed + hoop + perch.
- **Performance.** One `Canvas` net and up to 8 visitors at 30 Hz is light; the mesh path is cached per tier and radius.
- **Wake game drift.** `WakeSheet` builds the same model; it must pass `.gentle` explicitly (covered in the pace test).
- **Back-swipe conflict.** A drag from the left edge can start the navigation back gesture (also true today); the rest
  point never sits in the left 20 pt.
- **Seed stability.** New RNG draws can change existing seeded tests; draw moves after today's draws, or update the
  pinned values in the same commit.

## 11. Decisions for the owner
1. Quick wings numbers: x1.3 speed, 40 / 56 / 72 pt hoop, 45 s, 2 s perch. Accept or tune after a playtest.
2. Turns in Quick wings: keep (with tell) or drop.
3. Show the "Quick wings" chip on the Visitors page, or keep the mode unnamed in the app.
4. Build with the Gentle Net badge in one branch (recommended, saves about 3 hours of shared perch work).

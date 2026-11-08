# Weak spots review 2 (2026-11-07, critique, read-only)

Inputs: `docs/research/frost-lantern-facts.md`, `docs/pm/frost-lantern-art.md`, `docs/STATUS.md` (G1, G2, G2b),
`docs/pm/admob-full-spec.md` (section 1.1, 2, 7, Review rulings), `docs/pm/status-review-2026-11-07.md`,
`WordFlora/Rules/FadedBloom.swift`, `WordFlora/Resources/PlantThinning.json`. Scope is frozen: everything below is a
bug fix, a wording change, a check or a 1.1 backlog note. Anything that would remove a feature is marked
**needs owner approval**. Owners: copy, Sonnet (bounded research), builder (under the lock), owner.

## 1. The four facts

| Fact | Ship as written? | Why | Fix | Owner / min |
|---|---|---|---|---|
| R1 "Robins sing all year round, even in winter." | **No, reword** | "All year round" is the one over-claim: robins go quiet for a few weeks in the late-summer moult, and most sources say "almost all year". The winter-song part is the solid, widely stated bit. | "Robins sing through the winter, not just in spring." (52 / 9; CopySafety clean: no banned word). Keep R2 as the backup only if the owner's RSPB read confirms night song. | copy, 5 |
| W1 "A wren is tiny, but its song is remarkably loud." | Yes | The one fact verified on two read authorities (BTO, Sussex WT). Also true of the North American wrens, so a child anywhere is not misled. | Optional kid-copy nit: "very loud" for "remarkably loud" (short-words rule). | copy, 2 |
| S1 "Snowdrops often bloom in January and February." | Yes | Hedged with "often"; Wikipedia carries the Bishop, Davis & Grimshaw monograph; Kew and Woodland Trust snippets agree. Northern-Hemisphere wording is fine for a pack called Frost & Lantern; the shipped `l4-snowdrop` hint already says "late winter frost". | None. If the owner wants hemisphere-neutral: "Snowdrops often bloom in late winter." (40 / 6). | none, 0 |
| H1 "Hellebore flowers have petal-like parts called sepals that stay on for weeks." | Yes | Petaloid sepals in *Helleborus* are textbook botany (the true petals are nectaries); "weeks" is the safe lower bound of Herrera 2005's "months". The missing RHS page confirms, it will not contradict. | None. | none, 0 |

**Minimum owner check (10 min, browser, no build):** open three pages and tick them in the research doc's summary
table: RSPB "Robin" (winter song), Kew "Common snowdrop" (flowering months), RHS "Hellebores" (sepals). The wren needs
nothing. If a page contradicts a line, use the backup already in the doc (R2, S2, H2), all CopySafety-clean.

**Wren species:** handled. The display name "Wren" everywhere, no North American species name, BTO/Sussex sources only, and W1 is
true of both species. One residual: the research doc must never carry Audubon or Cornell URLs in the wren rows (it
does not today; keep it so). The builder adds the four lines to the existing fact test when the G5 entries land
(research doc, rule 2), so a later edit cannot slip past CopySafety.

## 2. Quick wings tuning

**Recommendation: ship as built, turns on, and let the owner playtest decide** (lead decision stands). Reasons:
the per-round number the player actually sees is about 13.6 hellos against 18.6, 27% fewer, inside the spec's
15 to 30% guard; the 43% figure is per 35 s against a 45 s round; no round was empty; rewards are identical in every
pace; under-13 never gets Quick wings; 13+ has the Easier butterflies switch. The fallback (drop turns, keep speed,
hoop and perch) is one line (`ButterflyPace.turns`), 5 builder-minutes plus one `ButterflyNetTests` run, so there is
no cost to deciding after the playtest. Do not retune constants before the playtest: a second simulation would only
move the guess.

**Owner playtest checklist (simulator, 13+ profile, Calm off, Easier off, 15 min):**
1. Three Quick wings rounds: each summary shows about 10 or more hellos, and the first 10 s never feel empty.
2. Watch five swerves: the tell (wings flared, half speed, 0.4 s) is visible before every turn; no reversal, no exit
   off the screen edge; after a tell the visitor is still catchable by moving to it. If turns feel like dodging, say
   so: that is the fallback trigger.
3. Gentle Net: one visitor lands on a flower, rests about 2 s with the gold halo; "Gentle hello!" pill with the
   heart; never two resting at once; the hearts count on the summary.
4. The net: touch down scoops; a fast swipe still catches (no jumping over a visitor); the hoop's rest point never
   covers the "said hello" pill; lift glides home. Set the device clock to 19:00 once: the cream outline reads on
   the evening sky (checked in code only so far).
5. On the Visitors page turn Easier butterflies on: the Quick wings chip goes, the next round is 35 s with the bigger
   hoop and no turns, and the summary rewards match a Quick wings round.

## 3. Pruning Pro faded-bloom placement

`FadedBloom.spots` are five fixed fractions of the 200 box, y 0.20 to 0.34 (the upper third). That fits tall and
bushy plants and will float above low rosettes (aloe vera, pitcher plant) and could land in the sky on short plants.

**Cheap verification (lock-free first, 30 min, Sonnet):** an HTML page in the scratchpad (not the repo) that lays
`design-preview/badge-mechanics/faded-bloom.svg` at the five spots over the full-bloom image of eight plants: clover,
daisy, rose, bird of paradise (petals kind) and aloe vera, bamboo, fern, pitcher plant (droop kind). Pass rule: the
bloom touches foliage or a stem on all 40 looks and never sits in sky, on the pot rim or over the plant's own head.
Report a table plant x spot. **Then one build look (under the lock, in the G3 tail or G6 hour 1, 20 min, builder):**
the existing `-uitest-tidytrim` fixture plus `testAFadedBloomCueThenATidyTrimEarnsPruningPro` screenshot, on two
plants the preview flagged.

**If it misreads (fix is art data, no stored field, 1 to 2 h, builder):** `PlantThinning.json` already holds
`heads[].pivot` for 33 plants (`kind: "petals"`). Use the first head pivot (offset a little up and sideways by the
seeded index) as the anchor for those; keep the five spots for the 18 `droop` plants but clamp y to the plant's
foliage band. The PM already gave this item a home; this is the same item, not new scope. The owner's G1 request
(a shot per plant family) is satisfied by the preview table.

## 4. Frost & Lantern dark-scene text rule: gaps

The rule (card or `appBackground` 0.6 scrim; sky zone free) is right for the one pair it measured. Four gaps:
1. **Controls, not just text.** `appPrimaryText` dark on the snow bank is 2.0:1; a white SF Symbol on `#9AA7BC` is
   about 2.4:1. WCAG 1.4.11 (3:1) applies to icons, chips, progress bars and buttons over the bank. Reword the rule:
   "text **and controls**". copy, 5 min.
2. **The 460 line is a box coordinate.** The scene scales to the width and bottom-aligns, so the bank starts at about
   342 pt from the top on a 375-wide phone (top cropped) and about 572 pt on a 440-wide one. Rule for the builder:
   any element that can sit over the lower 40% of the scene on any supported width gets the card; do not hard-code
   460 pt. copy, 5 min.
3. **Reduce Transparency.** A 0.6 scrim is translucency; under `accessibilityReduceTransparency` use the opaque
   `appSurface` card. One `@Environment` check. builder, 15 min (in G5).
4. **Measure where it ships.** The 5.5:1 was computed for `#9AA7BC` under the scrim; lighter parts under a scrim
   (lantern glow, snow caps) compose lighter. Add the Home and Garden audit with a `-uitest-pack-frost-lantern` flag
   (light, dark, AX XXXL dark) to the G5 UI run, as `testAuditGardenSettingsAndPlus` already does for the base theme.
   builder, 30 min (in G5). The scene stays hidden from VoiceOver, so nothing else changes.

## 5. Lighter ad caps and R2 on the resting card

- **Three ad mentions on one calm card.** With an interstitial pending, the resting card can show "A short ad may play
  first", the R2 "Short video" row and "Go ad-free" together. Rule for the G4a spec (one condition in `AdPolicy`,
  not a cut): the R2 row is hidden while the "short ad may play" note is showing. Cheap, protects the calm tone.
  **Owner call** (it lowers R2 impressions a little). copy, 5 min now; builder, 20 min in G4a.
- **Title must say "video" (ruling).** Use R1's pattern: "Watch a short video for a hint", sub-line "A whisper for
  your next word". Same words a reviewer sees on R1, so one mental model. copy, 2 min.
- **Banked whisper and the Daily Bloom.** The row says "A whisper is waiting for your next word" but the Daily cannot
  use it; hide the Help button's leaf dot during the Daily and tutorial and write "your next garden word". copy, 5 min;
  builder in G4a.
- **Two tables, two sets of numbers.** Section 1.1 still prints 3 / 5 / 10 / 180 s while the rulings say
  2 / 4 / 8 / 600 s. A builder reading top-down builds the old caps. Edit the 1.1 table to the ruled numbers with
  "(ruled 11-07)". copy, 5 min.
- **Reviewers will see no ads.** Never in session 1, grace of 3 sessions, `appOpenMinSessions = 3`, real ids with a
  new AdMob account (low fill). That is fine for Apple, but D8 must say so in one sentence ("Ads appear from the
  third session for players 13 and over; an under-13 age shows none") so a reviewer does not flag "Go ad-free" as a
  claim with nothing behind it. copy, 5 min (D8 rewrite is already assigned).
- **Nothing in the lighter caps confuses a player:** the caps never surface in copy; the only visible effects are
  fewer interstitials and the app-open cue with its Skip.

## 6. Top 5 launch risks to watch, G4a to G6

1. **Consent order and the 13-17 under-age flag on a device in a simulated EEA (G4a):** a rejection and a legal exposure
   in one; verify from the built bundle, not from the spec.
2. **Privacy nutrition label vs the Google Mobile Ads `PrivacyInfo.xcprivacy` in the built bundle (G6 answer sheet):**
   a mismatch is a sure rejection; derive every row from the bundle.
3. **One CloudKit deploy, before the TestFlight build:** any stored field slipping into G4a, G5 or G4b forces a second
   deploy and device run; grep `Models/` at every merge (the ad ledger is UserDefaults by design, keep it so).
4. **G5 art acceptance Fri 11-13 20:00 plus the scene audit at AX XXXL dark:** the pre-decided fallback is still a
   scope change, **needs owner approval on the day**.
5. **G6 on a loaded machine:** audit hangs and runner stalls cost a day each time; reboot, nobody else on the box,
   overnight; slip to Mon 11-23 before shortening G6. The same run captures the IAP screenshots and the no-launch-
   argument review path, so it cannot be skipped.

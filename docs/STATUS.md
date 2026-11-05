# WordFlora build status (2026-11-03)

Branch `1-feat-triviaapi-and-earn-flora`. Spec: `docs/superpowers/specs/2026-11-02-wordflora-v2-design.md` (sections 11-20 hold the latest decisions). Plan: `docs/superpowers/plans/2026-11-02-wordflora-v2.md`.

## Verified by automated tests (simulator, iPhone 16, iOS 18.5)
- ~250 unit tests: word bank/validator, Daily Bloom (time zones, DST), round logic, Rose meter, Garden Days, progression, help ladder, tending, tools, butterfly, badges, ad gate and accounting, reminders, sound events, share text, storage migration, StoreKit config, paywall rules, widget actions, iCloud flag logic.
- ~20 UI tests: first session, game, resting, tending, paywall, shed, badges, butterfly, and Apple's accessibility audit on every screen.
- StoreKit local config proves: `plus_yearly` $12.99 with a 3-day free trial, `plus_monthly` $3.99, both Family Sharing; purchasing either turns Plus on; expiry turns it off.
- Device signing: automatic signing builds for iOS with the App Group and iCloud container in the provisioning profile (app and widget).
- SwiftData schema opens in CloudKit sync mode (CloudKit-compatible).

## NOT verified (needs a real device, an account, or ears/eyes)
- **Widget on a Home Screen / Lock Screen:** builds, embeds and signs; never seen rendered. The interactive water button is untested on device.
- **iCloud sync end to end:** needs two devices and the CloudKit schema deployed to Production. Conflict handling is SwiftData/CloudKit last-writer-wins; our "max/union" merge rule exists as logic (`BadgeState.merged`) but is not wired into sync.
- **Ads:** only Google test ids are configured. Real units, UMP message setup, `app-ads.txt` and a privacy policy URL are owner tasks. Consent form and real ad serving are untested.
- **Sounds:** the recommended set was chosen on design rationale; nobody has listened. Haptics are untested on device.
- **On-device AI ("Tell me more"):** compiles and falls back safely; behavior on a real Apple Intelligence device is untested; context limit and kids-content behavior need a spike.
- **Real StoreKit sandbox purchase** against App Store Connect products, parental gate flow, Ask to Buy.
- **Reminders** on a real device (permission prompt, delivery).

## Owner items (see `docs/setup/owner-setup-steps.md`)
Privacy policy and support URLs (`Links.swift` currently points at placeholder `wordflora.app` pages), real AdMob ids in `Config/Ads.local.xcconfig`, App Store Connect product creation, CloudKit schema deploy, age rating, privacy labels, review of the 30 starter words and writing of ~270 more (`WordFlora/Resources/Words.json`, validator in `WordBankValidator`), fact-check of remaining species/plant facts.

## Known gaps / next
- Word bank is a 30-entry starter; difficulty bands need calibration once the full bank exists.
- Badge catalog is 12 of the 36 designed badges; the rest need counters and rules.
- No Game Center, spaced-review rounds, camera "Find a plant", voice guessing, Image Playground sticker.
- Daily Bloom share is text only; no ShareLink for badges.
- Prototype-only ideas not built: plant diary, first-bloom ceremony, season/weather mood, welcome-back card.

## Review-fix pass: rulings and deferrals (2026-11-03)
Rulings:
- Ad peak window is 5 seconds after a win; ads start in session 2 (never session 1); interstitial only after the player taps "One more" at the every-3rd-round boundary.
- Evening visitors (17:30-21:30) draw from day + night species so the mixed audience always sees something.
- Quiet Garden still grows plants at the capped pace, without costs, cooldowns or numbers.
- Unknown age is treated as under 13 (no ads, parental gate).
- iCloud duplicates (two profiles / two copies of a plant) merge by best-of-each field, never summed (`DataReconciler`, runs at launch and on foreground).
- Widget opens the store read-only-if-present (`createIfMissing: false`); a failed store move falls back to the old store.
- A store that cannot open shows a visible message instead of silently running in memory.
Deferred:
- Two-process store writes (app + widget at once): wait for real-device testing.
- Minor wording/polish items from the review, plus word bank growth (30 starter, ~270 needed).

## Apple Intelligence + delight pass (branch 2-feat-apple-intelligence)
Built (unit 363 + UI 17 green in simulator): optional "Simpler clue" (on-device model, validated, free, once per round), Siri/Shortcuts + Control Center "Water my garden" (same store/rules as widget; iOS 18+ for the control), read-aloud clue (system voice, hidden under VoiceOver), welcome-back card (3+ days away, no streak talk), tap-to-sway plant hello.
Rulings: PlantEntity/Spotlight skipped for now (needs iOS 18, little gain); Smart Stack relevance dropped (watchOS only); journal/whispers and weekly summary deferred; keep 3-day trial and ad cadence until real cohort data (engagement research suggests testing a 7-day trial and delaying the interstitial to ~day 7; owner decision).
Device-only unverified: Siri phrases, Control Center control, speech voice/silent switch, haptic feel, on-device model latency.

## Owner rulings, 2026-11-03 (late)
- **Love, rain and seeds:** a plant with no love (tap hello or any tending) for 24 h gets rain and loses a petal; one more each day; with no petals left it shows as a seed in a pot. Nothing earned is removed (stage, growth, collection kept). A seed wakes with a challenge (word puzzle or butterfly catching). Quiet Garden and Calm mode are exempt. This replaces the "plants never wilt" rule for the visual state only. Engine: `Rules/LoveEngine.swift`; UI pending mockup review (`design-preview/tending/lifestats.html`).
- **Life stats:** left-edge collapsible panel combining meters (a), stage path (c) and love hearts (b).
- **Pots:** unlock triggers approved as mocked (sunflower L3, Starlight L5, rose pink 25 plants, mint 50 plants).
- **Visibility:** every Home destination is shown; locked ones are dimmed with an unlock hint.

- **Ruling (owner, same day, later):** petal loss, rain and the seed state apply at every age with the same 24 h rule. The researchers' under-13 72 h delay and default Gentle mode are NOT adopted. Safeguards that remain: nothing earned is ever removed, Quiet Garden and Calm mode turn it off, copy stays gentle and positive-only.

- 2026-11-03: Wake the seed flow built (WakeChallenge/WakePuzzle rules, WakeSheet, WakePuzzleView, butterfly wake at a goal of 3, or 2 after two "still dreaming" tries). Plant page shows the seed card in one marked block; a tap on a seed opens the sheet. Not built yet: rain visuals, Life panel, petal thinning. UI flag: -uitest-seed.

## 2026-11-04 content and polish
- **Pot collection (T-D):** ten pots from `Rules/PotCatalog.swift` (data from `design-preview/pots/pots.json` after the critic review). Plain blue is free; terracotta (first plant), sage glaze (10 plants), sunflower (level 3 finished), starlight (level 5 finished), rose pink (25 plants) and mint (50 plants) are earned by play; honey stripe, moonlit and meadow are WordFlora Plus. "Plants grown" = found plants; "level N finished" = all ten plants of level N found (the same count as the level badge). Unlocks are computed from these stats every time and never stored, so `PlayerProfile` is unchanged and nothing earned is ever removed. A pot already on a plant stays on it even if Plus lapses; choosing a new Plus pot needs Plus. Changing pots is free; the repot still costs its soil scoop.
  - Data: `PlantCollectible.potId` (defaulted `""` = plain blue; unknown ids fall back to plain blue), carried in `GardenBackup` (optional, so older backups read) and merged by `DataReconciler` (a chosen pot beats none; if both chose one, the copy tended later wins). Choosing a new pot counts as tending (`lastTendedAt`), so the latest pick wins on sync.
  - UI: repot sheet "Pick a pot" (5 x 2 grid, 4 columns at accessibility sizes; ring and check on the pick; pots to earn as dashed outlines with a hint and progress line; Plus pots in full colour with a "Plus" tag and a line pointing to Settings; no locks, prices or buy button) and the repot button names the new pot. Shed "Pots" grid below Tools with goal and progress bars. The plant page stage, the repot effect and the seed pot draw the plant's own pot.
- **Word bank (T-A):** 303 words (50 hero, one per plant at its plant's level; 253 vocab, 53-67 per level), `bankVersion` 2026.11.1, every entry has a `hint2`. Daily Bloom draws from levels 1-3 only (183 `dailyEligible` entries) so a young child never gets a level-5 science word as the daily; `daily.epoch`/`seed` unchanged. Tests: >= 300 entries, >= 50 per level, unique words/ids, CopySafety on hint/hint2/fact, hero plant ids exist, hero level = plant level, daily eligibility <= level 3. Two starter ids moved (`l5-deciduous`, `l3-welwitschia`), so old seen-history on those ids will not match. Level pacing settled 2026-11-04 (3 words per plant, below). Owner decisions open: a few facts written from memory (ENDANGERED panda 2016, MARSUPIAL joey size, BURDOCK/Velcro).
- **Name stories (T-B):** 47 of 50 plants have a `nameStory`; Poppy, Jasmine and Lavender use the plain "Did you know?" card on purpose (no true, visible, unhedged origin). Research table with sources: `docs/research/name-stories.md`. Tests: every plant has a story or is in the reviewed-fallback set; limits (line 70, funFact 140, meaning 24); SF Symbols exist; CopySafety on every string and card line.
- **Thunder (T-C):** original procedural roll from `tools/make_thunder.py` (deterministic, stdlib + ffmpeg) to `Resources/Sounds/wf-thunder.m4a` (38 KB, 4.6 s, -9 dBFS peak, -26 LUFS, 0.48 s attack, no crack). Plays at 0.35 with the first flash of a plant-page visit, 1.5-3 s after the flash, at most once per visit and once per 3 minutes app-wide; first flash 4-6 s after the page opens; haptic fires with the roll; ducks the ambient bed with a two-reason duck state shared with read-aloud; never with sound off, Calm, Quiet Garden, Reduce Motion or Low Power. Details in `docs/research/audio-feedback.md` section 9. NOT verified by ear on a device; may be faint on the phone speaker (raise `CUTOFF_START` before volume).
- **Rose curl (T-E):** the rose's peel order now keeps three outer petals at 4 pips and two at 3, and the petals that stay swap to curled sprites and droop (16-25 degrees about the petal base); `rule.curl` in `PlantThinning.json`, 5 new imagesets (+4 KB), Swift in `PlantThinning.swift`/`LayeredPlantView.swift`, tests in `PlantThinningTests`. Checked in the simulator at every pip (`design-preview/tending/parts/shots/app-rose-*.png`). Mockup and critic notes: `design-preview/tending/parts/rose-curl.html`, `notes/rose-curl.md`, `notes/rose-curl-review.md`. Reduce Motion path not checked by eye.
- **Logo (T-F):** three directions, a critic and a two-person review in `design-preview/logo/` (gallery `index.html`, `critic.md`, `review-opus.md`, `review-sonnet.md`). Winner: a ring "o" (true letterform, open counter) with five petals behind it, both O's, no petal cut by neighbouring letters; final files in `design-preview/logo/final/`. The in-app wordmark (`WordmarkView`, Home and Onboarding) now uses the `Wordmark`/`WordmarkSolo`/`WordmarkMono` vector image sets in one commit (5d008e8) for easy revert; app shots in `design-preview/logo/final/shots/`. App icon NOT changed (review team unanimous: keep the smiling flower for now); candidate at `design-preview/logo/icon/` for the owner to judge.
- **Words per plant (owner decision 2026-11-04):** a correct word no longer brings a plant every time. After the very first plant (which still arrives on the first win, so the first-session flow is unchanged), each correct word moves one step toward the next plant and every 3rd word brings it with the full celebration; a level now takes about 30 words instead of 10 (word level still needs its 10 plants, `ProgressionPolicy` unchanged). A hero word whose plant is not found yet brings that plant at once and leaves the count as it is. Losses never lower the count, nothing earned is removed, existing players start at 0 and keep every plant, and a Daily Bloom win counts as one word. Soil +2 only when a new plant arrives; water rewards unchanged. Tunable `Economy.wordsPerPlant = 3`; stored in `PlayerProfile.wordsTowardPlant` (defaulted 0), carried in `GardenBackup` (optional, older backups read as 0) and merged by `DataReconciler` (higher count wins). UI: the win card without a plant says "Great word!" and "2 of 3 words to your next plant." (no flower rain, plant sound or lub-dub; "New plant found!" on arrival is unchanged); Home shows "2 of 3 words to your next plant" under the Garden Days line once the first plant is found (hidden in Quiet Garden). Copy lives in `PlantProgressCopy` (CopySafety tested). A visual meter will be mocked separately (`HOOK (progress meter)` comments in `GameView`/`HomeView`).
- **Process:** plan in `docs/pm/2026-11-04-content-plan.md`; every ticket had a worker, PM check, Sonnet + Opus review, and integrated feedback. Known StoreKitConfigTests (3) fail in the simulator sandbox, unrelated.

## Shed, Visitors and Butterfly game (2026-11-04)
Lead decisions (owner did not answer in time; may override). Notes: `docs/pm/shed-visitors-notes.md`; mockups: `design-preview/shed-visitors/`.
- **Net:** the catch circle grows by tier, 48/64/80 pt (`ToolEngine.netCatchRadius`), in the main and the wake game. Shed points stay tied to visitors met, not circle size.
- **Mister:** speeds the free water drops: tier 1/2/3 = a drop every 4/3/2 hours, up to 5/6/7 (`ToolEngine.trickleHours(forMister:)`, `trickleCap(forMister:)`, `ToolEngine.applyTrickle`). Both trickle call sites (app `refreshFreeDrops`, widget/Siri `WidgetActions.water`) go through it. `waterPerDay` and `waterBankCap` are unchanged, so the per-action daily allowance holds. ToolEngine.swift is now in the widget target too.
- **Prices:** the truth is 30 points to tier 2 and 120 to tier 3 (`ToolInventory.upgradeCost`); the "900" in the notes is the whole Shed (6 tools x 150). Code, Shed text and tests agree.
- **Shed:** a points card says points come from the butterfly game (with a Visitors link); each tool card shows "Now" and "Next" in plain words, a progress bar and "N more to go" (the unreachable "Not enough shed points yet." is gone); found tools drop the "Finish level N to find it" line. Quiet Garden hides every upgrade and price (`ShedPolicy`). Copy in `ShedCopy`, CopySafety tested.
- **Visitors page:** the Home "Visitors" tile opens a new Visitors page (`VisitorsView`): friends met ring, "Say hello" card that starts the game, evening and net notes, and the album (name, rarity chip "Often seen / Sometimes seen / Rare visitor", times met, "Seen today/yesterday/N days ago"). Friends not met yet are soft pale outlines in dashed cards (no locks). A tap opens a card with the fact. The album now stores when each friend was seen (`StickerAlbum.seenAt`, decoded if present so older albums read; merged by latest date).
- **Butterfly game:** starts straight away from the Visitors page; honours Reduce Motion from Settings as well as the system; a catch shows the sticker with the friend's name in a pill, and a first meeting shows a "New friend" card; a "n said hello" pill; summary stickers wrap in a grid; summary says "You met N friends" and "N new friends in your album". The Glow Lantern toggle is gone (the `glowLanterns` field stays so synced data stays valid).
- **Calm mode game:** no time bar, visitors drift at 60% speed, the round ends after 5 hellos or a tap on Done (`ButterflyGameModel(calm:)`, from `settings.calmMode`). The wake game is never calm-timed (it ends at its goal).
- **Wake game:** catches go to the album and badges through `finishButterflyGame(_, wake: true)` (no shed points, water or soil, and no rewarded play used); the count says "n of 3 friends" in the adaptive text colour (it was unreadable in dark mode).
- **Facts:** all 12 visitors have a grade 2-3 fact, sources in `docs/research/visitor-facts.md`; tests check length, word length and CopySafety.
- **Pet names for visitors:** skipped for v1.

## Backlog (owner request 2026-11-04)
- **Glow Lantern (backlog):** give one Glow Lantern at the 7-day Garden Days milestone (`Economy.roseMilestones` [7, 30, 100]) and bring back the "Use a Glow Lantern for night visitors" choice on the Visitors page. The model field is kept for this.
- **Onboarding guide / first-run walkthrough.** A short, skippable guide that walks new players through getting started: guessing a word, earning progress toward a plant (3 words per plant), tending (water, feed, sun, prune, repot), hearts and petals, the garden and Shed, visitors and the butterfly game, Daily Bloom, and how levels work (level map). Include "sneak peeks" of what comes later (exotic plants, pots, badges, higher levels) so players have something to look forward to. Needs: mockup first (reviewed on localhost), grade 2-3 copy, CopySafety, Reduce Motion / Calm variants, replayable from Settings, VoiceOver, no ads or Plus pressure inside it, and a UI test. Builds on the intro (petal bloom) and the existing first-win flow in OnboardingView.

## Release gate (owner, 2026-11-04)
No App Store submission until ALL of the following are done and reviewed by the owner: logo redesign (v3, then icon and in-app wordmark), petal-bloom intro and celebration confetti/badge moments, rest and break cards (Dusk card), plants earned by progress (3 words per plant), hearts fix, level map, Shed/visitors/butterfly game review, pot earning ladder, onboarding guide (backlog), endgame and weather events decision, app-vs-mockup fidelity fixes, then device checks and App Store Connect items.

## Endgame and garden weather (design only, 2026-11-04, awaiting owner decision)
Spec `docs/pm/endgame-and-events-spec.md` (decisions in section 9); research `docs/research/endgame-disasters-{design,tech}.md`; audio plan `docs/pm/endgame-events-audio-plan.md` with prototypes from `tools/make_weather_sounds.py`; mockups `design-preview/events/` and `design-preview/endgame/` (critic notes and Revision 1 in each). Recommendation: "Weather, not loss" for everyone (looks only, mended by care), and Wild Weather (shown-stage dip on up to 4 plants, word level never drops) as a 13+ opt-in. No Swift changed.

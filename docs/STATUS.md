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

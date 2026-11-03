# WordFlora v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline) or superpowers:subagent-driven-development. Steps use checkbox syntax.

**Spec (binding):** `docs/superpowers/specs/2026-11-02-wordflora-v2-design.md`
**Older plan:** `docs/superpowers/plans/2026-05-10-wordflora-overhaul.md` still supplies verbatim code for unchanged tasks (FlowerView, PlantCard, ShareCard, LevelMapView, PlantEarnedView, HomeView, GameView layout, GameRouter, AdMob wrapper). Where this plan says "from old plan Task N", copy that code, then apply this plan's deltas.

**Global constraints**
- Build/test: `xcodebuild test -scheme WordFlora -destination 'id=FEA6646F-7F9A-4BC6-8EAF-27C4A416F4E8'` (iPhone 16, iOS 18.5). Redirect output to a log; never pipe long runs.
- New files must be added to `WordFlora.xcodeproj` (manual pbxproj project, objectVersion 56). Use the `xcodeproj` Ruby gem script (`addfiles.rb`); there are no synchronized groups.
- Color tokens come from Xcode's generated asset symbols (`Color.appAccent`). Do NOT add a `Color+App.swift`.
- TDD for logic. Visual views: build from the approved mockups in `design-preview/` (localhost:8765); every NEW visual asset is made by the visual agent and approved by the user before SwiftUI is written for it.
- Commits: plain messages, no attribution lines (user CLAUDE.md). Do not stage the user's `ContentView.swift` edits (deleted in Task 14) or the `PROVISIONING_PROFILE_SPECIFIER` line change without telling them.
- Apple Intelligence features: iOS 26 only, always optional (`#if canImport(FoundationModels)` + `@available(iOS 26, *)` + availability check), never blocks play.
- Deployment target stays iOS 17.5.

## Status

| Task | State |
|---|---|
| 1 Color tokens (xcassets) | DONE `7a875bc` |
| 2 Models v1 (PlayerProfile, PlantCollectible, GameRecord) | DONE `7a875bc`, EXTENDED in Task 3 |
| 3 Content + models v2 | TODO (supersedes old Tasks 3-4) |
| 4 WordProvider (replaces TriviaService) | TODO (supersedes old Task 4) |
| 5 GameViewModel | v1 DONE `8e0a100`, rework in Task 5 |
| 6-... | TODO |

---

## Task 3: Content and models v2

**Files:** Modify `Models/PlayerProfile.swift`, `Models/PlantCollectible.swift`, `Models/GameRecord.swift`; Create `Models/WordEntry.swift`, `Resources/Plants.json`, `Services/PlantCatalog.swift`; Replace `Resources/WordBank.json`; Delete `Models/PlantSeedData.swift`, `Services/WordBankService.swift`.

- [ ] Copy `design-preview/plants/plants.json` to `WordFlora/Resources/Plants.json` (50 plants). Add `plantId` (snake_case of name) to each entry.
- [ ] Test first (`PlantCatalogTests`): loads 50 plants; exactly 10 per level 1-5; unique plantIds; every `imageName` exists in the asset catalog (after Task 12).
- [ ] `PlantCatalog.load()` decodes `Plants.json`; `seedIfNeeded(context)` UPSERTS by `plantId` (insert missing, update facts/level of existing, never reset `earnedCount`). Test: seeding twice leaves 50; adding a 51st later inserts it; existing earnedCount preserved.
- [ ] Extend models (SwiftData lightweight migration; all new properties have defaults):
  - PlayerProfile: `water=0, soil=0, lastTrickleAt=.now, widgetPlantID: String?, streak=0, streakFreezes=0, lastPlayedDay: Date?, seenIds:[String]=[], ageBand: String?`
  - PlantCollectible: `plantId`, `growthPoints=0, stage=0, hydration=1.0, soilRichness=0.0, lastTendedAt: Date?, lastSunnyAt: Date?`
  - GameRecord: `wordId: String`, `isDaily: Bool=false`
- [ ] `WordEntry` Codable per spec section 2 schema; `WordBank.json` v1 starts with ~60 reviewed entries (12 per level incl. the 10 hero... see Task 3b); full ~300 authored in the content track.
- [ ] Content track (parallel, not blocking): author remaining entries; every entry reviewed by the user; facts need 2 refs; run a validator script `scripts/validate_wordbank.py` (A-Z only, hero spaces ok, level length bands, unique ids, plantId exists, banned-wording list, hint doesn't contain the answer).
- [ ] Commit.

## Task 4: WordProvider (replaces TriviaService)

**Files:** Create `Services/WordProvider.swift`, `Services/DailyBloom.swift`, `Services/SplitMix64.swift`, `Tests/WordProviderTests.swift`, `Tests/DailyBloomTests.swift`; Delete `Services/TriviaService.swift`, `Tests/TriviaServiceTests.swift` (replace coverage).

- [ ] Tests first:
  - bank validation: all `word` match `^[A-Z ]+$`; hero may have spaces, vocab not.
  - `nextWord(level:seen:excluding:)` prefers unseen at level, resets pool skipping last 10 when exhausted, never returns today's daily id.
  - `DailyBloom.wordId(for: date)` deterministic across runs and for a fixed epoch/seed (golden values), same id for same local day, different next day, `dailyOverrides` win; SplitMix64 golden vector.
  - `Difficulty` removed; level drives selection.
- [ ] Implement. `RemoteBankUpdater` (optional, off by default until a CDN URL exists): fetch, verify checksum/signature, schema-validate, cache in Application Support, fall back to bundled on any failure. Test with fixtures (valid, bad schema, bad checksum, offline).
- [ ] Commit.

## Task 5: GameViewModel v2

Rework the committed `GameViewModel` (keep its tests, adjust):
- [ ] Source words from `WordProvider`; remove `TriviaService`/`triviaQuestion` naming (`hint`).
- [ ] Spaces in hero words are pre-revealed and not guessable.
- [ ] Award rule: unowned plant of current level first (hero entry -> that plant if unowned); duplicates only when the level set is complete. Level-up when unique plants in level == 10 and level < 5; level 5 completion sets `profile.completedAll`.
- [ ] Rose economy: cap 3, one revive per round (`reviveUsedThisRound`), drop 15% any round end, guaranteed at streak milestones (7, 30). Tests incl. cap and second revive refused.
- [ ] Water/soil rewards: win grants 1-3 water; level completion or first win of a new plant grants soil.
- [ ] Streak: `recordPlay(day:)` increments on consecutive local days, uses a freeze to bridge one missed day, otherwise resets to 1 (never negative messaging). Tests with injected calendar/clock.
- [ ] Daily round: `startDaily()` uses `DailyBloom`; at most one scored daily per day; result `isDaily`.
- [ ] Expose `petalsAccessibilityLabel` ("5 of 8 petals left").
- [ ] Injectable `Clock`/`Random` for deterministic tests. Commit.

## Task 5 rework addendum (supersedes the Rose/streak/ad bullets above; spec section 18)

- [ ] **5b RoseMeter** (replaces random Rose drops): +1 per completed round idempotent by round id (relaunch mid-round safe), arrives at threshold from Economy.json (default 8), paused at cap 3, streak milestone grants unaffected, one revive per round, regression test that no code path awards a Rose from `Random`.
- [ ] **5c GardenDays + gentle streak**: `gardenDays` never decreases; `recordPlay` with a 2-day gap and no freeze leaves gardenDays/bestStreak intact; grace day (1 per rolling 14 days) consumed before a freeze; freezes earned day 5/14 then +1/14 days cap 2; `showStreak` default false for under-13; no loss words in streak strings.
- [ ] **5d SessionBeats**: emit `sessionBeat` after every 3rd completed regular round and after a Daily Bloom; no auto-start.

## Task 10c: Session shape + ad gate

- [ ] Resting card ("One more" / "That's enough for now"); "That's enough" returns Home at dusk and suppresses the ad; under-13 20-minute break suggestion with injected clock.
- [ ] `AdGate.shouldShowInterstitial(context)`: false for under-13; false at "That's enough"; false within 120 s after any peak event (PlantEarned, stage-up, first bloom, level-up, badge unlock, new visitor, Rose revive); false mid-round and around Daily Bloom; true only after "One more" at the every-3rd-round boundary (plus grace period/caps from spec section 16). Under-13 profiles load no ads at all.

## Task 16b: Copy safety + Calm/Quiet modes

- [ ] `CopySafety.check` + unit test over the whole string catalog and AI outputs (word lists in spec section 18).
- [ ] `isThirsty` rename, Calm mode (default on for under-13) hides the thirsty look; Quiet Garden mode hides currencies/cooldowns/streaks/badge progress, tending unlimited and earns nothing, never touches Daily Bloom (tests per research P11).

## Task 10d: Attachment features (High wave)

- [ ] Name your plant + personality lines (P1), Garden Diary memories (P2), first-bloom ceremony + gratitude moment (P3), real local season/weather mood/time-of-day (P4, WeatherKit optional/off by default; seasonal by calendar hemisphere otherwise), awe-framed Wonder Facts schema + content (P6), gentle welcome-back (P8), data export/delete (P18). Visual agent mockups first (Task 8); copy passes CopySafety.

## Task 5 final scope (consolidated; supersedes all earlier Task 5 bullets)

`GameViewModel` v2 + pure helpers, test-first:
- WordProvider source; spaces pre-revealed; `revealedAnswer` on loss; "resting" result (no coins); Rose offered before reveal; review queue +1 day.
- `ProgressionPolicy`: wordLevel (10 unique plants earned) vs gardenLevel (stage 4); selectable levels <= wordLevel; award rule (unowned first).
- `RoseMeter` (5b), `GardenDays`/streak (5c), `SessionBeats` (5d), `HelpLadder`, `AssistTuner` (P-04), `WordDifficulty.expectedMisses` + Python validator parity (P-02), `FeatureUnlockPolicy` (P-07), `OnboardingFlow` state machine (P-03), `CopySafety` banned words incl. dead/died/lost.
- Injectable clock/rng; all numbers from `Economy.json`.
- Remove TriviaService/Difficulty/WordBankService/old WordBank.json in this task.

## Task 6: Tending engine

**Files:** `Services/TendingEngine.swift`, tests. Pure logic, no UI.
- [ ] Tests first: `water(plant)` consumes 1 drop, raises hydration/growth; `addSoil` consumes 1 scoop, raises soilRichness and a growth multiplier for 3 days; `sun` toggle gives small bonus once per day; stages are forward-only thresholds; `isWilted(plant, now)` true after 48h without water, plant never removed, a single water clears it; trickle grants 1 drop per 4h, cap 5, computed from `lastTrickleAt` (no background job); decay is computed from timestamps only.
- [ ] Implement with injected `now`. Commit.

## Task 6b: Tools, activities, repotting (logic)

- [ ] Models: `ToolInventory`, `PlantCollectible.preferredSoil`, profile fields (`shedPoints`, `activeToolId`).
- [ ] `ToolEngine` tests first: pickup sets active tool; each tool's effect (water, feed, repot with soil match/mismatch multipliers, prune bonus, mist for humidity-loving plants, sun); tier upgrades spend shed points and are forward-only; no tool effect can reduce a plant's stage or remove it; cooldowns/limits computed from timestamps; can waters N plants per tier.
- [ ] Prune minigame scoring pure function (path coverage -> bonus) with tests.
- [ ] Shed + tool UI after Task 8 asset approval.

## Task 6c: Butterfly catching mini-game

- [ ] `VisitorCatalog` (JSON, ~12 species with real facts; same schema discipline as plants) + `VisitorSticker` model + tests (seeding upsert, collection counts).
- [ ] `VisitorSpawner` (pure, seeded): spawn rates scale with healthy flowering plants; deterministic with seed for tests; caps on simultaneous visitors; rare species weights.
- [ ] `ButterflyGameModel`: 30-45s timer, catch hit-testing with generous radius, rewards always >= 1 item, daily reward cap (3) with unlimited free play, no fail state; tests for timer, reward math, daily cap across day boundaries and time zones.
- [ ] View: SpriteKit-free SwiftUI `Canvas` + `TimelineView` scene (60fps budget), net swoosh animation, Reduce Motion mode (resting visitors, tap to catch), VoiceOver alternative, haptics, sound toggle; built from approved storyboard.
- [ ] Hook into Garden and as an occasional post-round reward; no ads in or after the minigame.

## Task 6d: Badges

- [ ] `BadgeCatalog` (JSON: id, title, description, family, tier thresholds, counter key) + `Badge` model + `BadgeEngine` (event-driven: `record(.waterPlant)`, `.streak(n)`, `.perfectBloom`, `.visitorCaught(species)`, etc.). Tests: threshold crossing unlocks exactly once, progress persists, never revoked, tier ordering, duplicate events idempotent, CloudKit merge (max progress, earliest unlockedAt).
- [ ] Unlock presentation queue (one per beat, never stacked with paywall/ad/rating), shelf view, shareable badge card (ImageRenderer), celebration rain variant. UI from approved mockups.

## Task 7: Persistence in App Group + migration

- [ ] Add App Group capability `group.beta.WordFlora` (app + widget targets; entitlements files). Needs the user's Apple Developer account for signing; flag if provisioning blocks.
- [ ] `SharedModelContainer.make()` builds the container at the group URL. Migration: if the old default store exists and the group store does not, COPY the sqlite (+ -wal/-shm) into the group container, verify counts, then keep the old file until next successful launch. Test with a populated fixture store (profile, plants with earnedCount, records) -> counts and earnedCount equal after migration; idempotent on second run; failure leaves the original untouched.
- [ ] Commit.

## Task 8: Visual-agent asset pass 2 (user approves each batch on localhost)

Not code. Dispatch the visual agent; user reviews at localhost:8765:
- [ ] Growth stage templates (5 stages) + wilted look, per-level templates with per-plant variation.
- [ ] Pots/soil scenes, drop/scoop/sun icons (color + monochrome), splash/sprinkle/sparkle frames.
- [ ] Widget layouts: small, medium, Lock Screen circular + rectangular, light/dark, empty/onboarding states.
- [ ] Screens for new flows: Daily Bloom card, tending screen, age screen, consent explainer, settings (reminders, haptics, sound), "Tell me more" sheet, garden journal card.
- [ ] Revised icon/launch art per the icon/launch-fit research.
- [ ] Gate: user approval recorded in ledger before Tasks 9-13 views that use them.

## Task 9: Visual components (approved mockups exist for these)

From old plan Tasks 6-7 with deltas: `FlowerView` (Reduce Motion fades, accessibility label, ghost dashed petals per mockup, petal colors per mockup), `PlantCard` (renders `Image(plant.imageName)` from the 50 SVG-derived assets; locked silhouette), `ShareCard` (fixed gold palette, plant + level), plus Daily Bloom emoji share text. Build each against its mockup and compare in Simulator light + dark.
- [ ] Asset import: convert approved SVGs to xcassets (vector `preserves-vector-representation` or PDF) for the 50 plants + Rose of Jericho. Test: every PlantCatalog imageName resolves to an image.

## Task 10: Screens

HomeView (tagline "Guess words. Grow a garden.", Daily Bloom card, banner slot), LevelMapView (5 levels, live data via `@Query`), GameView (NO banner by the input; hint card; Dynamic Type; haptics), GardenView (grouped by level, tend actions), PlantEarnedView (Continue then interstitial logic), Settings. Navigation via `GameRouter` (old Task 13) incl. live level data (old Task 14 step 2 folded in).
- [ ] UI smoke test with `XCUITest` for: launch -> Play -> guess -> win path with injected word; Garden shows locked/earned; Level Map levels.

## Task 11: Ads and privacy

(Ad policy per spec sections 11-12: banner Home/Garden only, optional rewarded drops, and a full-screen ad after every 3rd completed regular round for free users; Daily Bloom exempt; all disabled for subscribers; load failure/offline skips silently; remote kill-switch for frequency.)
- [ ] `AdCadence` (pure, unit-tested): `roundsSinceAd` increments on round end, fires at 3, resets on show or entitlement, ignores Daily Bloom, never fires mid-round, load failure leaves counter at 3 so the next boundary retries once then skips; frequency read from remote config with local default 3.

- [ ] Add Google Mobile Ads SPM package (needs user to confirm in Xcode if the gem route fails). Test IDs in Debug, real IDs via xcconfig.
- [ ] Age screen (neutral), UMP then ATT, child-directed/under-age-of-consent flags and max content rating via `RequestConfiguration`; banner only on Home/Garden; interstitial rules per spec; "Report ad" link; privacy policy link in Settings. Unit-test the policy object (`AdPolicy.configuration(for: ageBand)`) and interstitial gating (`shouldShowInterstitial` false mid-round/after loss/less than 2 actions since last).
- [ ] Rating prompt gate `ReviewPromptPolicy` (after level-up only, 14+ days apart, never after loss). Unit-tested.

## Task 11b: Subscriptions (StoreKit 2)

- [ ] StoreKit configuration file for local testing (`Configuration.storekit`) with group "WordFlora Plus": `plus_yearly` $12.99 (3-day free-trial introductory offer) and `plus_monthly` $3.99 (no trial); Family Sharing on. Both unlock remove-ads AND iCloud sync (see spec section 13). Products also created in App Store Connect by the user (flag as a user action).
- [ ] `EntitlementService` (`@Observable`): loads `Product`s, `purchase`, `restore` (`AppStore.sync`), listens to `Transaction.updates`, exposes `hasRemoveAds`, `hasCloudSync` (both true for any active Plus product). Protocol + `MockEntitlements` for tests. Tests: purchase -> entitled; refund/revoke -> not entitled; expired -> not entitled; restore; unverified transaction ignored; under-13 requires parental gate before purchase call.
- [ ] Trial eligibility via `isEligibleForIntroOffer`; paywall copy shows trial/price/renewal only for eligible users. Tests with MockEntitlements for eligible/ineligible.
- [ ] `AdPolicy` consumes entitlements: no ad load/present when `hasRemoveAds` (tests: banner view hidden, interstitial gate false, rewarded still available).
- [ ] Paywall view built from approved mockup: prices, renewal terms, Restore, Manage Subscriptions link, Terms/Privacy links, no dark patterns; reachable from Settings and the ad-free button only.
- [ ] Use StoreKit testing in Simulator via the .storekit file; document sandbox test steps.

## Task 7b: iCloud sync (entitled users)

- [ ] Audit all models for CloudKit compatibility (defaults, no unique, optional relationships); add test that builds a CloudKit-configured container in memory-compatible mode where possible.
- [ ] Container factory chooses `.private` vs `.none` from `EntitlementService`; switching triggers rebuild flow; tests for the decision function and for the merge policy (`ProgressMerger`: max for monotonic fields, union for seenIds, latest timestamp) with simulated two-device states.
- [ ] Entitlements: iCloud/CloudKit capability + container id (user action in Apple Developer portal). Widget reads the App Group store as before.

## Task 9c: Landing experience

- [ ] Launch: `UILaunchScreen` with only the named color; no image.
- [ ] `IntroRainView`: Canvas/TimelineView falling blossoms using the approved flower/plant sprites, wordmark fade-in (SVG/text per approved mockup), tap to skip, once per cold launch, Reduce Motion fallback; reused by `CelebrationRain` for wins and milestones. Tests: emitter determinism with seed, particle count cap, skip callback, reduce-motion path; frame-time check in a UI performance test.

## Task 12: Widget extension

- [ ] New target `WordFloraWidget` (Widget Extension, App Intents), shares models + `TendingEngine` + container via App Group.
- [ ] Intents: `WaterPlantIntent`, `AddSoilIntent`, `ToggleSunIntent`, `OpenDailyBloomIntent`; each mutates via TendingEngine, saves, returns, then reloads timelines. Idempotent. Intent tests (in-memory container): drop count decrements once, never below 0.
- [ ] Provider: one timeline, entries ~6h; families small, medium, accessoryCircular, accessoryRectangular. Views built from approved layouts.
- [ ] Siri/Spotlight: expose the same intents as `AppShortcutsProvider`.
- [ ] Commit; verify on Simulator (add widget, tap water, app reflects).

## Task 13: Notifications

- [ ] `ReminderScheduler`: opt-in only, one local notification a day (shared budget for tending + Daily Bloom), user-chosen time, quiet hours, cancels after 3 days without opens, copy from static list (AI lines optional via Task 14). Tests with fake `UNUserNotificationCenter`.

## Task 14: Apple Intelligence layer (optional)

**Files:** `AI/GardenAI.swift` (protocol + availability), `AI/FoundationGardenAI.swift` (`@available(iOS 26, *)`, `#if canImport(FoundationModels)`), `AI/StaticGardenAI.swift` (fallback), tests.
- [ ] Protocol `GardenAI`: `simplerHint(for:wrongGuesses:) async -> String?`, `explain(plant:) async -> String?`, `journal(for:) async -> String?`, `voiceLine(event:) async -> String?`. `StaticGardenAI` returns bank `hint2`/`fact`/templates. `GardenAIProvider.current` picks Foundation if `SystemLanguageModel.default.availability == .available`, else static.
- [ ] Output validators (pure, unit-tested, no model needed): `HintValidator` rejects any output containing the answer or any 4+ letter substring of it, over 2 sentences, or non-ASCII garbage; `GuiltLanguageValidator` rejects banned phrases; `ExplainValidator` length cap. Failure -> static fallback.
- [ ] Foundation implementation: `LanguageModelSession(instructions:)` with a fixed kid-safe system prompt; prompts include only vetted bank text; use `@Generable` for journal summary; handle `guardrailViolation` and availability errors by falling back; per-call timeout.
- [ ] UI: "Adaptive hint" after 3 wrong guesses (button, never auto), "Tell me more" on plant card with "Written by on-device AI" label, journal card in Garden. Hidden entirely when unavailable.
- [ ] Tests run the whole feature against a `MockGardenAI` that returns adversarial outputs (leaks the answer, guilt wording, empty) and verifies fallbacks.

## Task 14b: Expanded AI features (from spec 5b)

Each is its own sub-task, TDD with mocks, gated and optional. Order by value: (1) streaming "Tell me more" + tool calling, (2) hint ladder with `@Generable`, (3) "Ask the Gardener" with topic guard, (4) Find-a-plant camera (Vision/Core ML; needs a model decision and camera permission copy), (5) voice guessing (Speech; microphone permission), (6) difficulty tuner, (7) Image Playground sticker (user-initiated, hidden for under-13), (8) App Intents donation + interactive snippets.
- [ ] For each: protocol + static fallback + adversarial-output tests + availability UI hiding + privacy manifest/permission strings + Settings toggle ("Use on-device AI").

## Task 9b: Motion system

- [ ] `Motion` module: durations/springs tokens, `ReduceMotion` wrapper, haptics map, particle `Canvas` emitter, Metal shader pack, MeshGradient themes. Motion storyboards from the visual agent approved first (Task 8). Perf check on the smallest supported simulator profile; snapshot tests for static frames; unit tests for emitter determinism and reduce-motion substitution.

## Task 15: Brand integration

(after the icon/launch research is applied and the user approves final art)
- [ ] AppIcon set: Evergreen light/dark/tinted 1024 PNGs (or Icon Composer layers if the research says so).
- [ ] Launch screen per research; rename `wordGarden*` assets and `PROVISIONING_PROFILE_SPECIFIER`; set display name; update Info.plist (`GADApplicationIdentifier`, `NSUserNotificationsUsageDescription` not needed, `UILaunchScreen`).
- [ ] Delete `ContentView.swift`, wire `WordFloraApp` (container, router, scene phase triggers).

## Task 16: Accessibility and polish pass

- [ ] VoiceOver walkthrough, Dynamic Type XXXL, Reduce Motion, Increase Contrast, light/dark, iPhone SE and Pro Max sizes; haptics toggle; sound respects silent switch.
- [ ] Remaining hedged facts verified (Saguaro, Bamboo, Giant Water Lily, Rafflesia).

## Task 17: Final review

- [ ] `review-package` + whole-branch review by a fresh reviewer on the most capable model; Critical/Important -> one fix pass with failing tests first; Minors -> deferred list. Then finishing-a-development-branch (user decides merge/PR).

## Phase 3 (not in this plan)
Game Center (achievements, daily leaderboard, access point on Home only), spaced Garden review rounds, seasonal plant sets, large widget, pollinators, localization.

## Review Focus (for the final reviewer)
Data loss on App Group migration; interstitial gating in every game phase; AI output leaking the answer or guilt language; streak/freeze edge cases across DST and time-zone changes; widget intents racing the app on the same store; Rose cap/one-revive invariants; plant award with a partly completed level; accessibility without color.

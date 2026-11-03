# WordFlora v2 Design (supersedes 2026-05-10 overhaul spec where they conflict)
**Date:** 2026-11-02
**Branch:** 1-feat-triviaapi-and-earn-flora
**Tagline:** Guess words. Grow a garden.
**Audience:** mixed (kids + adults). Not submitted to the Kids Category.

This document records decisions made after the first spec. Anything it does not mention
stays as in `2026-05-10-wordflora-overhaul-design.md` (petal flower, Rose of Jericho
revive, SwiftData, GameRouter, ShareLink, semantic color tokens, SF Rounded).

Approved visuals live in `design-preview/` (served on localhost:8765 during design).
All visual assets are produced by the visual designer agent and reviewed by the user
BEFORE any SwiftUI is written for them. Code never invents art.

---

## 1. Content: 50 plants, 5 levels

| Level | Name | Plants | Word shape |
|---|---|---|---|
| 1 | Seedling | 10 | 3-5 letters, every child knows it |
| 2 | Sprout | 10 | 5-7 letters, garden and kitchen plants |
| 3 | Bloom | 10 | 6-9 letters, plant parts and well-known exotics |
| 4 | Grove | 10 | 7-11 letters, less common |
| 5 | Ancient | 10 | 8-14 letters, technical terms and rare species, second hint |

- Plant list, facts and art: `design-preview/plants/plants.json` + `plants/*.svg`
  (four hedged facts must be verified before ship: Saguaro, Bamboo, Giant Water Lily, Rafflesia).
- Plants are data (bundled JSON), not Swift literals. Seeding is an upsert by name, so
  plants added in updates reach existing players.
- Level-up needs `plantsPerLevel` (10) UNIQUE plants earned in that level.
  Award rule: pick an unowned plant of the current level; only repeat once the level set is complete.
- After the last level: "Evergreen" loop = Daily Bloom, Garden review, seasonal plant sets via bank updates.

## 2. Word source (replaces Open Trivia DB)

- **Primary:** curated bundled `WordBank.json`. Open Trivia DB is removed from gameplay.
- **Optional remote update:** a signed/checksummed JSON on a CDN adds words and `dailyOverrides`.
  Validated against the schema on device; any failure falls back to the bundled bank.
- **Entry kinds:** `hero` (answer is a plant; earns that plant) and `vocab` (POLLEN, SPORE; earns a random unowned plant of the level).
- **Letters:** `word` is A-Z only; hero entries may contain spaces (shown pre-filled).
- **Schema** (fields): schemaVersion, bankVersion, entries[{id, word, display, hint, hint2?, fact, level, kind, plantId?, tags, minAge, dailyEligible, source, license, factRefs, reviewedBy, locale}], daily{epoch, seed}.
- **Launch size:** ~300 entries (50 hero + ~50 vocab per level).
- **Authoring rules:** all text written from scratch (no Wikipedia text: CC BY-SA share-alike), each fact checked against 2 references, every entry human-reviewed for ages 6+. Drafting help is offline only (Apple Intelligence-on-Mac or an LLM), never shipped as runtime generation of answers.
- **Anti-repeat:** `seenIds` in SwiftData; pick unseen at current level first; on exhaustion reset skipping last 10; exclude today's Daily Bloom word.

## 3. Daily Bloom

- One shared word per local calendar day, no server needed: dayIndex = days since `daily.epoch`;
  list = `dailyEligible` ids shuffled with SplitMix64(seed) (never `hashValue`); `dailyOverrides` wins.
- Spoiler-free share card (emoji petals). Unlimited practice rounds remain.
- Gentle streak: 1-2 freezes EARNED by play, never bought or ad-gated. No guilt copy; a missed day shows the flower resting, not wilting.

## 4. Garden tending + widget

Theme: calm, never punishing. Plants never die and nothing is lost while away.

- **Currencies:** `water` (earned 1-3 per word win, plus free trickle of 1 per 4h capped at 5), `soil` (earned on level completion or first win with a new plant). Sun is a free tap (flavour + small growth bonus). No purchasable currency.
- **Plant fields:** growthPoints, stage 0-4 (seed, sprout, bud, bloom, flourishing; forward only), hydration 0-1, soilRichness 0-1, lastTendedAt, lastSunnyAt. Wilted look is computed at draw time (~48h without water), fixed instantly by one drop.
- **Profile fields:** water, soil, lastTrickleAt, widgetPlantID, streak, streakFreezes, seenIds.
- **Widget (WidgetKit + AppIntents):** v1 small + medium + Lock Screen circular/rectangular. Interactive: water (Button), soil (Button), sun (Toggle); deep-link "Play a word" when out of drops. Large grid later. No Live Activity. No ads in widgets.
- **Shared store:** SwiftData store moves to an App Group container with an explicit, tested migration (data-loss risk). Schema shared by app and widget targets.
- **Timeline:** one timeline, entries ~6h apart; decay computed at draw time; app calls `WidgetCenter.reloadTimelines` after changes.
- **Notifications:** local only, opt-in, max 1/day total (tending + Daily Bloom share one budget), quiet hours, stop after 3 days without opens, never guilt/loss wording. Permission is requested when the player turns "remind me" on, never at launch, and nothing is rewarded for allowing it.
- **Assets for visual designer:** growth-stage templates (5 stages, shared templates with per-plant variation instead of 250 bespoke images), wilted look, pots/soil scene per widget family, drop/scoop/sun icons (color + monochrome), splash/sprinkle/sparkle frames, widget layouts (S/M/Lock Screen, light+dark), empty/onboarding states.

## 5. Apple Intelligence (on-device, optional)

Framework: `FoundationModels` (iOS 26+, Apple Intelligence-eligible devices, on-device, no network, no third-party AI so no 5.1.2(i) disclosure issue).
Deployment target stays iOS 17.5; every feature is gated by `#if canImport(FoundationModels)`, `@available(iOS 26, *)` and `SystemLanguageModel.default.availability == .available`, and the app is fully playable without any of it. Never required, never blocks a round.

Features (all grounded in vetted bank text, never open-ended chat):
1. **Adaptive hint:** after N wrong guesses, rephrase the hint more simply from `hint` + `fact`. Output is validated: must not contain the answer (or any 4+ letter substring of it); on failure use the bank's `hint2`.
2. **"Tell me more" on a plant card:** kid-friendly 2-3 sentence explanation generated ONLY from that plant's `fact`; labelled "Written by on-device AI"; shown with the original fact; guardrail refusals fall back to the fact alone.
3. **Garden journal:** short weekly summary of GameRecords/tending ("Your fern reached bloom!") using structured (`@Generable`) output.
4. **Tending voice lines:** varied warm microcopy for widget/notification text, generated from a fixed template + tone list, validated against a banned-wording list (no guilt/loss language). Falls back to static strings.
5. **Siri / Spotlight via App Intents:** "Water my garden", "Play today's Daily Bloom" (shared with widget intents).
Not doing: runtime generation of answer words, AI-generated plant art (style consistency, review burden), chat, anything needing network.
Authoring (offline, not shipped): drafting bank entries; every entry still human-reviewed.

## 5b. Expanded AI + motion mandate (user direction: "as many AI capabilities and animations as possible")

Principle: maximize delight, keep safety. Every AI feature is optional, on-device first, grounded in vetted text, validated, and has a static fallback. Every animation respects Reduce Motion and is skippable.

**More on-device AI (all gated, none required):**
- Foundation Models: streaming responses for "Tell me more" (text appears like a gardener talking); tool calling so the model can look up a plant, the player's garden state, and today's Daily Bloom hint instead of guessing; `@Generable` structured output for journal, hint ladders (hint1 -> hint2 -> hint3), and quiz cards; an in-app "Ask the Gardener" limited to plant topics (topic guard + refusal fallback); a "Plant of the day" story; garden-aware encouragement lines.
- Vision/Core ML (on-device): "Find a plant" camera mode: classify a real plant photo against the 50 (and generic categories) to grant a one-time "discovered in the wild" bonus drop. Uses a small bundled classifier or Apple's image classification; confidence threshold, honest "not sure" state, no photos leave the device or are stored.
- Speech (on-device `SpeechAnalyzer`/`SFSpeechRecognizer`): "Say a letter" voice guessing, accessibility-friendly.
- Natural Language: spell-check-free letter validation; lemma/synonym for validating AI hint leaks; sentiment gate for AI lines.
- Image Playground / ImageCreator (iOS 26): optional "Draw my garden" share-card sticker in sketch style, strictly user-initiated, labelled AI-generated; skipped for under-13 players.
- App Intents + Siri + Spotlight + Shortcuts + interactive Snippets: water, play Daily Bloom, "what's blooming?", donation of intents for Siri suggestions.
- Live Translation/Writing Tools: system features need no code; ensure text fields and hints stay selectable.
- Visual Intelligence entries (iOS 26): surface "WordFlora: plant lookup" via App Intents when users point the camera at a plant (stretch).
- ML for fairness: on-device difficulty tuner (simple model over GameRecords) adjusts letter reveals or hint timing so rounds are neither trivial nor hopeless.

**Motion language (all SwiftUI native; budget-tested on iPhone SE-class hardware):**
- Flower: `keyframeAnimator` for petal fall (arc, spin, settle on ground, soil absorbs it), `phaseAnimator` idle sway, spring revive bloom for Rose of Jericho with particle shimmer.
- Letters: reveal with matched-geometry flip + haptic tick; wrong guess shakes the key and drops a petal; word completion triggers a staggered letter wave.
- Win: confetti/pollen particles via `Canvas` + `TimelineView`; plant card flies from the word into the Garden (`matchedGeometryEffect`/zoom navigation transition).
- Garden: parallax with CoreMotion tilt, breathing/sway shaders (`.layerEffect`/`distortionEffect` Metal shaders), watering can pour with droplet physics, soil crumble, growth-stage morph with sparkle, butterflies drifting across (decorative).
- Backgrounds: `MeshGradient` day/night/season themes, time-of-day lighting that matches the real clock.
- Chrome: SF Symbol effects (bounce, pulse, variableColor), `scrollTransition` in the Garden grid, `contentTransition(.numericText)` for counters, symbol effects on the Rose of Jericho.
- Haptics: `sensoryFeedback` + CoreHaptics patterns (rain on water, soft thump on soil, bloom crescendo), toggle in Settings.
- Sound: light layered sfx (water, soil, bloom) respecting silent switch; optional ambient garden loop, off by default.
- Rules: nothing loops forever on battery without need (pause when off-screen), 60fps target, all motion has a Reduce Motion alternative, no flashing >3Hz.
- Motion specs are produced as mockups/storyboards by the visual agent first; user approves on localhost before implementation.

## 6. Ads, privacy, compliance (mixed audience)

- AdMob stays; app NOT in Kids Category.
- First launch: neutral age screen. Under 13: child-directed treatment, max ad content rating G, no IDFA/personalization. Everyone: max rating G/PG.
- UMP consent before the ATT dialog; ATT shown only when needed; no feature depends on granting it.
- **Banner:** not on `GameView` next to the letter input. Banner on Home and Garden only (or a clearly separated container with a gap).
- **Interstitial:** only at logical breaks, never mid-round, on launch or after a loss; shown after the player dismisses `PlantEarnedView` and taps Continue; at most ~1 per two actions; visible close button; in-app "Report ad" link.
- Privacy policy URL, Privacy Nutrition Labels, App Store age rating answers.
- **Rating prompt:** `requestReview` only after a level-up, never after a loss, never on the interstitial screen; rewards never tied to reviews.
- No loot-box style paid randomness (free drops only; if ever sold, disclose odds).

## 7. Rose of Jericho economy (revised)

- Drop ~15% per completed round (win or lose), stock capped at 3, one revive per round.
- Drop notice is an in-app banner/toast only, never a system notification.
- Milestone: guaranteed Rose at streak milestones.

## 8. Accessibility

- Remaining petals are also exposed as text/VoiceOver ("5 of 8 petals left"); color is never the only signal.
- Dynamic Type instead of fixed point sizes; minimum tap target 44x44.
- Reduce Motion: falling-petal and revive animations degrade to fades.
- Haptics: system success/warning/error patterns, with a Settings toggle.
- Sound retained; respects silent switch.

## 9. Brand

- Tagline: "Guess words. Grow a garden."
- App icon: Evergreen concept (cream petals on green), with iOS 18 light/dark/tinted variants. Smiling face: DECIDED by user (face on icon and launch art). Subject to the icon/launch fit research below.
- Wordmark: two-tone. "Word" in text color; "Flora" green on light, gold on dark. The in-app title uses the same rule (gold fails contrast on cream).
- Launch screen: UILaunchScreen with `LaunchScreenColor` (#FAF7F0 / #1A2E1A) + light/dark image (260x250pt, @1x/2x/3x) with wordmark baked in.
- Rename leftover `wordGarden*` assets and the `beta.WordGarden-SwiftUI` provisioning profile reference to WordFlora.
- Mockups are the layout source of truth: Home, Game, Game dead, Level Map, Garden, Plant Earned, Share card (fixed gold palette in both modes since it is exported as an image), flower states + motion.

## 10. Out of scope (this release)

Multiplayer, leaderboards beyond optional Game Center (phase 3), IAP, iPad layouts, Live Activities, pollinators, large widget, localization (schema is ready for it).
Phase 3 candidates: Game Center achievements + daily leaderboard (access point on Home only), spaced Garden review rounds at ~1/3/7 days.

## 11. Monetization, launch, and brand decisions (later decisions; these OVERRIDE sections 6, 9 and 10 where they conflict)

**Brand/launch**
- Icon: Evergreen with smiling face, YELLOW-GREEN ground (user decision, after Round 2 review; the designer advised the blue-leaning green stays more distinct from Duolingo's green, so the visual agent must re-check contrast and distinctness at 40/60px on the final colour and the user signs off on the render). Dark-mode centre contrast (~1.4:1, separated by hue and face) accepted.
- Launch screen (HIG best practice): static plain colour only, no image, no text (LaunchScreenColor #FAF7F0 / #1A2E1A).
- Branded moment lives IN the app: the first frame of Home is an animated intro. A gentle RAINFALL OF FLOWERS (petals/blossoms from the 50-plant art falling and drifting, landing and settling into the garden scene) while the two-tone wordmark fades in. It is skippable by tap, plays once per cold launch (short, ~2s, hands off to Home), uses Canvas/TimelineView particles, respects Reduce Motion (static fade), and is paused when off screen. The same rain is reused for win celebrations and the Daily Bloom streak milestones.

**Monetization (auto-renewable subscriptions via StoreKit 2, one subscription group)**
- `remove_ads_monthly`: $0.99/month. Removes banners and interstitials. (Rewarded ads, if any exist, are optional and become free rewards for subscribers.)
- `icloud_sync_monthly`: $0.99/month. Syncs progress (profile, collection, tending state, streaks) across the player's devices via CloudKit.
- Both are independent products so a player can buy either or both. Evaluate later: a bundle ("WordFlora Plus"), an annual price (~$7.99 each), a free trial, Family Sharing. Pricing/packaging is a product decision to A/B using Product Page / Subscription offers.
- Required: clear price + renewal terms on the paywall, Restore Purchases, link to manage subscriptions, working cancel path, visible support contact (App Store review data: unwanted charges, refund friction and "paid but still seeing ads" are top 1-2 star drivers). Entitlement is verified with `Transaction.currentEntitlements` and updated on `Transaction.updates`; ads never load for entitled users, and a lapse never deletes data.
- Under-13 players (age screen): purchases are behind a parental gate; no paywall nags.
- Paywall is shown only on explicit player action (Settings / "Remove ads" button / sync prompt in Garden), never as a pop-up on launch or mid-round, and never gates the Daily Bloom.

**Ads for free users (reconciling revenue with review data, which shows ads are the #1 reason for 1-2 star reviews; ruling, adjust with data)**
- Banner on Home and Garden only (never next to the letter input).
- Optional rewarded ads for bonus water/hint (player-initiated).
- Level-up interstitial KEPT but capped: max 1 per 10 minutes and 3 per day, never mid-round, never before/after the Daily Bloom, never after a loss, no auto-play audio, visible close, "Report ad" link. Kill-switch via remote config if reviews/retention show harm.
- No ads in widgets or notifications.

**iCloud sync design**
- SwiftData + CloudKit private database (`ModelConfiguration(cloudKitDatabase: .private(...))`) enabled ONLY for entitled users; others use `.none`. Model constraints for CloudKit: all properties optional or defaulted, no unique constraints, relationships optional (audit the v2 models). The shared App Group store (widget) stays the source of truth on device.
- Switching sync on/off rebuilds the container (prompt to relaunch or hot-swap with a tested migration). Lapsed subscription: sync stops, local data kept, a note explains.
- Conflict policy: take max of monotonic fields (earnedCount, stage, streak best), latest-wins for timestamps, union for seenIds. Test with simulated two-device edits.
- Free tier still benefits from normal iOS device backup/restore. The paid product is multi-device sync; the paywall copy must not imply otherwise.

**Engagement levers added (data-informed; measure each)**
- Streak with freezes, Daily Bloom with spoiler-free share, gentle tending, rain-of-flowers celebrations, collection completion bars per level, "almost there" level progress, weekly garden journal (AI optional), notifications within one-per-day budget, widget glance + tend.
- Analytics: privacy-light, first-party events only (no third-party tracking for under-13s): D1/D7/D30 retention, round completion rate, ad impressions per session, paywall views/conversions, churn reasons. Consent per section 6.

## 12. Pricing and ad cadence update (supersedes the interstitial cap in section 11)

**Plans (each of the two products gets both periods)**
- `remove_ads_monthly` $0.99/mo and `remove_ads_yearly` $7.99/yr
- `icloud_sync_monthly` $0.99/mo and `icloud_sync_yearly` $7.99/yr
- Yearly plans carry a 3-day free trial (StoreKit introductory offer, free trial, 3 days) for new subscribers per subscription group. Paywall states plainly: trial length, the price that follows, the renewal date, and how to cancel. Trial eligibility is checked via `Product.SubscriptionInfo.isEligibleForIntroOffer`; ineligible users see no trial wording.
- Open: a combined "Plus" yearly bundle is still a candidate to test later.

**Ad cadence for free users (user decision)**
- After every 3rd completed regular round, the free player watches an ad before the next round starts (full-screen interstitial or rewarded-format video; the network's own timer/close rules apply; Apple 2.5.18 needs a visible, easy close and the in-app Report ad link, so the ad can never be made unskippable by our code).
- Counter lives in `PlayerProfile.roundsSinceAd`; increments on round end (win or loss); resets after an ad is shown OR the player holds `hasRemoveAds`. Never triggers mid-round. Daily Bloom rounds do not count and are never preceded or interrupted by an ad. Subscribers never see it.
- The 10-minute and 3-per-day caps from section 11 are replaced by this rule, with these guards: ad load failure -> skip silently (never block play); offline -> skip; ad audio follows the silent switch.
- Banner on Home/Garden and optional rewarded drops stay.
- Risk (from App Store review mining: ads are the #1 1-2 star driver, 35% vs 3%, worst when they run after every word or freeze the app): mitigate by placing the ad at the round boundary with a calm transition, never stacking with a paywall prompt or rating prompt in the same session beat, and tracking ad-related reviews, D1/D7 retention and session length. Remote kill-switch lets the frequency be changed (3 -> 4/5) without an app update. Under-13 players keep child-directed ad settings (max rating G, no personalization).

## 13. Final subscription packaging (supersedes the per-product plans in sections 11-12)

One subscription group, "WordFlora Plus", two auto-renewable products:
- `plus_yearly`: $12.99/year, 3-day free trial (introductory offer, new subscribers only, one per group).
- `plus_monthly`: $3.99/month, NO trial.
Plus includes BOTH remove-ads and iCloud sync (`hasRemoveAds` and `hasCloudSync` both derive from any active Plus entitlement). Family Sharing enabled. Optional later: lifetime remove-ads (~$19.99), not in launch scope.
Paywall copy: trial length, first charge date and price, renewal terms, how to cancel; trial wording only when `isEligibleForIntroOffer`. Yearly is the default-highlighted plan, shown with the per-month equivalent and honest savings. Parental gate for under-13. Apple Small Business Program enrollment is a user action (15% commission).
Ad cadence (section 12) unchanged; Plus removes it.

## 14. Tools, activities, badges, butterfly catching (user-approved additions; part of the first release)

**Tools (garden shed)**
- Basic set: watering can, trowel, pruning shears, mister, sun lamp, butterfly net. Each is a collectible with 3 upgrade tiers (e.g. bigger can waters 1 -> 2 -> 3 plants per use; better trowel = richer soil boost; finer shears = bigger prune bonus).
- Earned (never bought): level-ups, streak milestones, Daily Bloom completions, butterfly-catch rewards, badge rewards. Upgrades cost soil/water-free "shed points" earned the same ways.
- "Picking up a tool" is the interaction: the player takes a tool from the shed (tap/drag), the cursor/hand carries it, and tapping a plant uses it with a tool-specific animation + haptic. The widget exposes the active tool (water can by default) through App Intents.

**Activities (all gentle, none punishing)**
- Water, Feed (fertilizer scoop), Repot (choose soil type: loam, sandy, peaty, rich compost; plants have a preferred soil via `preferredSoil`; a match gives faster growth and a "happy" reaction, a mismatch is just slower, never harmful), Prune (small trim minigame: drag shears along highlighted stems; improves fullness cosmetic + bonus), Mist (quick tap for humidity-loving plants), Sunny spot (toggle).
- Each activity grants growth points; stages remain forward-only; limits come from currencies and cooldowns, not punishment.

**Butterfly catching (mini-game, first release)**
- A short (~30-45s) calm mini-game reachable from the Garden and as a reward after some rounds: butterflies, bees and ladybugs drift across the garden; the player swipes/taps with the net to catch them; healthy/flowering plants attract more.
- Rewards: stickers for a "Garden Visitors" collection (about 12 species at launch, with real facts, e.g. monarch, swallowtail, honeybee, ladybug), plus water/soil/shed points. A rare visitor adds tension but there is no fail state: the round ends on a timer and always awards something.
- Gentle by design: no lives, no losses, no penalty for misses, no pay-to-win; free-to-play only. Reduce Motion version: butterflies rest on flowers and are tapped (no chasing). Accessible alternative: VoiceOver "a monarch is nearby" with a button to catch.
- Daily cap on bonus rewards (e.g. 3 plays/day with rewards, unlimited for fun) to avoid grind; no ads inside the minigame; no ad forced after it.
- Optional AI: Foundation Models writes a one-line "visitor journal" per species from the vetted fact; Vision/camera discovery can map to the same Visitors collection.

**Badges (in-app, positive-only, never revoked)**
- Shelf in the Garden profile + shareable card per badge. Families: Collection (level sets, all 50, all visitors), Play (streak 7/30/100, Perfect Bloom = no wrong guesses, Resurrected = used a Rose of Jericho, first Daily Bloom), Tending (first bloom, Green Thumb = 100 waterings, Master Repotter, Pruning pro), Explorer (first butterfly, all species, discovered-in-the-wild), Seasonal (later).
- Each badge: id, title, description, tier (bronze/silver/gold), progress counter, unlockedAt. Unlocking plays a short celebration (CelebrationRain variant) with a haptic; unlock toast respects the one-prompt-per-beat rule (never stacks with paywall/ad/rating).
- Game Center achievements can mirror these in phase 3.

**Data model additions**
- `ToolInventory` (toolId, tier, owned), `Badge` (id, tier, progress, unlockedAt), `VisitorSticker` (speciesId, count, firstCaughtAt), `PlantCollectible.preferredSoil`, `PlayerProfile.shedPoints`, `activeToolId`, `butterflyPlaysToday`, `butterflyLastPlayDay`. All CloudKit-compatible (defaults, no unique constraints) and merge by max/union.

**Assets for the visual designer** (user reviews on localhost before code)
- Tool icons (6 tools x 3 tiers, color + monochrome), shed screen, pickup/use animations per tool (pour, scoop, snip, mist, glow, net swoosh), soil type swatches + repot flow, prune minigame stems, species art for ~12 visitors (idle, flying 2-frame, caught sticker), butterfly minigame scene storyboard (light/dark, Reduce Motion variant), 30-40 badge emblems (3 tiers), badge shelf + unlock celebration, widget tool states.

## 15. Decisions log (Round 3/4 review)
- Night visitors (fireflies, luna moth) are tied to the DEVICE CLOCK evening hours (default ~6pm-5am local), independent of light/dark mode, so both themes can meet them. Exact window, time-zone and kid-bedtime handling to be finalised from the economy/design research.
- "Free drop" in the rewarded-ad card means one water drop.

## 16. Economy v1 (tunable defaults; every number lives in one `Economy.json`/remote-config table, none hard-coded)

Source: Sonnet economy research + 60-day expected-value simulation (`scratchpad/econ_sim.py`). Inputs are assumptions, not data: treat as starting values and tune with real telemetry.

| Item | Default |
|---|---|
| Water per win | avg ~1.6: 1 base, +1 for <=2 misses, +1 on Daily Bloom/streak days; none on a loss |
| Free trickle | 1 per 4h, bank refills to 5; bank hard cap 40 |
| Growth points | water 4, soil scoop 12 (trowel T2 x1.25, T3 x1.5), sun +2/3/4 by lamp tier, prune +4/6/8 once per plant per 2 days |
| Per-plant daily absorb cap | 10 gp (main pacing lever; a cooldown, not punishment) |
| Level cost per plant | 180 gp x [1.0, 1.1, 1.2, 1.3, 1.4]; stage-ups at 6%/22%/50%/100% |
| Level complete | all 10 plants of the level at stage 4 (flourishing) |
| Soil scoops | +2 first win of a new plant, +10 level complete, +0.25 per win, +1 Daily Bloom, 30% per butterfly play; stop granting from wins when stock >= 20 |
| Shed points | +1 per win (cap 6/day from rounds), Daily Bloom +3, butterfly play +2, level complete +25, streak 7/30/100 = 10/30/100 |
| Tool upgrades | T2 = 30 shed points, T3 = 120 (total 900 for 6 tools); if heavy players finish too fast raise T3 to ~200 |
| Butterfly game | 3 rewarded plays/day; each: 1 water, 2 shed points, 30% chance of 1 scoop |
| Rewarded ad | 2 water per ad, max 3/day |
| Rose of Jericho | 10% per completed round, max 1 drop/day, stock cap 3, pity guarantee after 15 rounds without one, guaranteed at streak 7/30/100 (supersedes the 15% in section 7) |
| Streak freezes | earned at streak day 5 and 14, then +1 per 14 days; stock cap 2; used automatically |
| Badge grants | Bronze 3 shed; Silver 10 shed + 2 scoops; Gold 25 shed + 5 scoops + 1 Rose; no water (avoids inflation) |

Sinks needed (simulation shows heavy players pile up ~800 scoops / ~1,300 shed points by day 90): cosmetic shed-point shop (pots, plant labels, garden decor; assets for visual agent), scoop-stock soft cap, hard-capped water bank.
Expected pacing (casual 3 rounds/day / daily 8 / heavy 25): all 5 levels complete around day 183 / 115 / 110; casual sees a stage-up on ~75% of active days.

**Ads (consolidated; supersedes the ad text in sections 6, 11 and 12 where they differ)**
- Free users: banner on Home/Garden only; optional rewarded ads (max 3/day, each = 2 water); a full-screen ad between rounds after every 3rd completed regular round, BUT only after a grace period (not before the player has completed 3 sessions or their first level-up), with a minimum 3-minute gap and a max of 6/day. Shown at the round boundary, i.e. after the player dismisses `PlantEarnedView`/result and before the next round starts; never mid-round, never around the Daily Bloom, never after the butterfly game, no ads in widgets/notifications.
- Frequency (3 -> 4/5) and the caps are remote-config. A 10% holdout cohort sees no interstitials for comparison.
- Measure for 14 days by cohort: D1/D3/D7 retention, session length, rounds/session, ad impressions/session, ad-related share of new 1-2 star reviews, crash-free rate, paywall conversion, refund/support volume.
- Kill-switch thresholds (inferred; revisit with real data): D1 < 25% or > 3 pts below holdout; D7 < 8% or > 2 pts below holdout; session length down > 15%; ad-related > 25% of new 1-2 star reviews or >= 3 in a day; crash-free < 99.5%. First response: move to every 5 rounds, then rewarded-only.
- Under-13: child-directed settings, max rating G, no personalization.

**Night visitors**
- Window 17:30-21:30 local device time, evaluated once at butterfly-game start via `Calendar.current` (DST/travel handled by the calendar, `startOfDay` boundaries, never 86400s math, never server time). No spawns after 21:30; no night-visitor notifications.
- Dusk palette applies to the scene during the window independent of dark mode.
- "Glow Lantern" consumable (stock cap 1; earned from a weekly streak, Visitors badge, first Daily Bloom of the week) summons night visitors for one play at any hour so no one is locked out; album shows silhouettes with "Comes out in the evening".

**Tool tier legibility (for the visual agent)**
- Plate shape per tier (bronze circle, silver hexagon, gold 8-point scalloped star), 1/2/3 concentric rim lines, >= 5px pips on a dark pill, silhouette change (T2 collar/band, T3 spark/crown notch), palette bronze #8C5A2B / silver #A9BCD0 with 1.5px #3B3B3B outline / gold #F2B705, static gold halo only (none under Reduce Motion), VoiceOver "Watering can, tier 2 of 3, silver"; verify in greyscale at 40px and under protan/deutan simulation.

**Open inconsistencies to resolve in mockups/specs (found by research)**
1. Badge thresholds exceed what 5 levels allow ("Level Sets 3/6/10", "Level Up 5/15/30"): rebase to 5 levels / 50 plants (e.g. Level Sets 1/3/5, Level Up 2/4/5).
2. Visitor rarity count on the page is wrong (shows 6/3/3; actual 5/4/3).
3. "All 12 species" badge needs the Glow Lantern (night species), see above.
4. Tool ownership/unlock order and watering-can cost (assumed 1 drop per plant per use) must be defined: start with can + trowel, unlock others via early levels/badges.
5. Gold badges asking 200 feeds / 50 repots must be rebased to the scoop economy.
6. "Plants never die" vs wilted look: wilting is cosmetic only; copy must say so.
7. Stale pricing text in section 11 (two-product plans) is superseded by section 13.

## 17. Apple platform rulings (from docs/research/apple-capabilities.md; lead's decisions under the autonomy agreement)

- AI: use ONLY `SystemLanguageModel` (on-device). Do NOT use `PrivateCloudComputeLanguageModel` or third-party model providers: they break the "nothing leaves the device" promise and the 5.1.2(i) disclosure assumptions for a mixed-audience app. Re-evaluate only with an explicit privacy review.
- Adopt, in priority order (each optional/gated, with fallbacks for iOS 17.5-25): (1) SwiftUI motion stack with Reduce Motion alternatives; (2) `sensoryFeedback` haptics with Settings toggle; (3) App Intents + App Shortcuts shared by widget/Siri/Spotlight including plant entities; (4) widgets: tinted/accented rendering, Lock Screen families, relevance, Control Center controls (iOS 18+); (5) StoreKit 2 `SubscriptionStoreView` with Ask-to-Buy pending handling (custom paywall from the approved mockup stays the primary design; use SubscriptionStoreView where it fits or as fallback); (6) privacy manifests, MetricKit, Instruments budgets, accessibility audits; (7) Foundation Models adaptive hint + streaming "Tell me more" with answer-leak validator and static fallback; (8) TipKit onboarding; (9) Icon Composer icon, Liquid Glass chrome gated by availability; (10) Declared Age Range (iOS 26+) as an input to the age gate with our own neutral age screen as fallback.
- Next wave: quick actions + Focus filter, sticker pack, Background Assets for remote word/plant packs, FM journal/voice lines, "Find a plant" camera mode.
- Unverified (needs a spike before coding): exact Foundation Models context limit (4096 vs 8192 reports), guardrail behavior on kids' content, whether Declared Age Range / state age-assurance laws (TX, UT, LA) impose duties on us, App Intents assistant schemas for a game. Each becomes a time-boxed spike task before its feature task.

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

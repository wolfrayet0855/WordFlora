# G4a builder brief: AdMob hardening, ad policy, rewarded perks

Paste-ready. Written 2026-11-07. Sources: `docs/pm/admob-full-spec.md` (all three "Review rulings" sections at the end win over earlier numbers in the same file), `docs/pm/release-plan-extended.md` (standing cadence, Update 2026-11-07), `docs/pm/admob-ad-ids-review.md`, `docs/pm/admob-full-spec-review.md` section 5, `docs/pm/weak-spots-review-2.md` sections 3 and 5, `docs/research/ad-network-alternatives.md` 1.1 (B1 to B8), `docs/pm/faded-bloom-check.md`, `docs/pm/faded-bloom-offsets.md`.

Order of work: G3 merged, owner's CloudKit deploy done, then G4a (this brief), then G5, then G4b (app-open, collapsible, native; separate brief). G4a adds **no stored field**. If you find one is needed, stop and report; there is one CloudKit deploy only.

Real AdMob ids are never written in any file, commit, log or report. Refer to ids by xcconfig key name or last 4 digits.

---

## 0. Machine rules (paste at the top of your own working notes)

```
RULES
- Worktree: your own, branched from 3-feat-content-and-polish. Never push. Never touch another worktree.
- One xcodebuild at a time on this machine. Take the lock dir /private/tmp/claude-501/wf-build.lock
  (mkdir; if it exists, wait and poll every 30 s; rmdir it when your xcodebuild exits, even on failure: use a trap).
- Always pass: -jobs 4 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1
  -test-timeouts-enabled YES -default-test-execution-time-allowance 120
- Your own simulator (xcrun simctl create "WF G4a iPhone 17" ...; write the UDID to your scratchpad; shut it down when done)
  and your own dd-* derivedData folder (dd-g4a). Never share either.
- build-for-testing once per code change, then test-without-building per class.
- Watchdog: timeout and perl alarm do not stop xcodebuild. Use:
    ( sleep 2700; pkill -f "xcodebuild.*$UDID" ) & WD=$!
    trap 'pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null; rmdir /private/tmp/claude-501/wf-build.lock 2>/dev/null' EXIT
  The trap must do `pkill -P $WD; kill $WD` (the sleep is a child of the subshell; killing only $WD leaves the sleep and a later pkill can hit a newer xcodebuild).
- mediaanalysisd stays DISABLED on this Mac and on simulators. Do not re-enable it. If you think it must be enabled, ask the lead; do not decide yourself.
- Every new Swift file goes into its target in project.pbxproj; plutil -lint the pbxproj. TARGETED_DEVICE_FAMILY stays "= 1" everywhere (grep before every commit).
- Copy: every new kid-visible line goes into a *Copy.all list checked by CopySafety. Quiet Garden: no counts, no marks, no moments. Calm: CelebrationStyle.small. Reduce Motion: still or cross-fade.
- Commits: small steps, each must build. Plain messages in the user's voice. No attribution lines, no co-author line, no session line, and no tool, model or vendor names. Before you hand off run
    git log --format=%B <base>..HEAD | grep -icE "claude|anthropic|co-authored|opus|sonnet|session|fable"
  and confirm it prints 0.
- STATUS.md: add a dated section (what, tests, open items) in your last commit.
- Report: everything goes in your FINAL MESSAGE (tests run with counts, reds and why, shots checked by eye, files, commit hashes, open items). Do not claim green without the log.
```

---

## 1. Scope, in the order to do it

1. First hour: faded-bloom offset table (section 2). It is a bug fix inside frozen scope.
2. Ad id plumbing and the fallback chain (section 3), plus the Release build-phase check (section 4). Do this early because everything else reads the unit keys.
3. Hardening B1 to B8 (section 5).
4. `AdPolicy` core with the age-band table, `AdInputs`, `AdCaps`, `AdLedger`, budgets, and the fuzz tests (section 6).
5. R1, R2, R3 rewarded perks and the shared prompt row and toast (section 7).
6. Spec inconsistency cleanup (section 8).
7. D8 notes in the owner steps (section 9).
8. Regression and report (section 10).

Frozen scope: nothing beyond this list. Ideas go to the 1.1 backlog. App-open, collapsible and native are G4b; do not build them now, but G4a puts all nine unit keys in `Ads.xcconfig` and `Info.plist` so G4b touches only Swift.

---

## 2. First hour: faded-bloom placement fix

Source: `docs/pm/faded-bloom-check.md` (15 plants need an override, 36 are fine, hidden never occurs) and the ready text in `docs/pm/faded-bloom-offsets.md`.

- Add the override dictionary to `Rules/FadedBloom.swift` as in `faded-bloom-offsets.md`, and apply it where the spot is turned into a position (the `FadedBloomOverlay` path). The base spots (`FadedBloom.spots`, five fractions) do not change. Default for any plant not in the table: no offset (dy 0, dx 0, xk 1).
- Formula: `spot' = ( clamp(0.5 + (x - 0.5) * xk + dx, 0.1, 0.9), clamp(y + dy, 0.1, 0.9) )`.
- Unit tests: the plain-English cases in `faded-bloom-offsets.md` (every override within range, unknown plant unchanged, clamp, seed pick unchanged).
- Screenshot check (one build look, under the lock): plant page for lithops, aloe vera and clover with the faded bloom cue. Lithops and aloe vera must show the bloom on the plant; clover must be unchanged. Attach in the report.
- Commit separately: "Faded bloom: per-plant offsets for 15 low or narrow plants".

---

## 3. Ad ids: keys, Debug test ids, fallback chain (Review rulings 3)

**Owner decision: reuse the ids that exist; no more units are created.** Garden banner reuses the Home banner unit.

### 3.1 Keys (nine unit keys plus the app id)

| xcconfig key | Info.plist key | Debug value in `Config/Ads.xcconfig` |
|---|---|---|
| `ADMOB_APP_ID` | `GADApplicationIdentifier` | exists (tilde id, Google test app) |
| `ADMOB_BANNER_ID` | `AdMobBannerUnitID` | exists (banner test id) |
| `ADMOB_BANNER_GARDEN_ID` | `AdMobBannerGardenUnitID` | `$(ADMOB_BANNER_ID)` (build-time fallback that can never be empty) |
| `ADMOB_BANNER_GARDEN_COLLAPSIBLE_ID` | `AdMobBannerGardenCollapsibleUnitID` | Google's published collapsible banner test id |
| `ADMOB_INTERSTITIAL_ID` | `AdMobInterstitialUnitID` | exists |
| `ADMOB_REWARDED_ID` | `AdMobRewardedUnitID` | exists |
| `ADMOB_REWARDED_HINT_ID` | `AdMobRewardedHintUnitID` | Google's rewarded test id |
| `ADMOB_REWARDED_WAKE_ID` | `AdMobRewardedWakeUnitID` | Google's rewarded test id |
| `ADMOB_APPOPEN_ID` | `AdMobAppOpenUnitID` | Google's app-open test id |
| `ADMOB_NATIVE_ID` | `AdMobNativeUnitID` | Google's native advanced test id |

- Add Debug test ids to `Config/Ads.xcconfig` for the **five new keys** (collapsible banner, hint, wake, app open, native), using Google's published test id per format (the values are in `admob-full-spec.md` section 4.3; the collapsible one is marked [verify]: confirm on a device or simulator that it returns a collapsible test ad, and note the outcome in your report). Optional, harmless: switch the Debug banner to Google's adaptive banner test id so B4 height checks are not surprising.
- `Config/Ads.local.xcconfig` is git-ignored, holds the real ids under `[config=Release]`, and already carries the eight real unit keys. Do not edit it, do not print it, do not copy it into a worktree commit. It has no `ADMOB_BANNER_GARDEN_ID` line on purpose (reuse).
- `WordFlora/Info.plist` gets the six missing `$(ADMOB_...)` entries (Garden, collapsible, hint, wake, app open, native). A key present in the local file but absent from Info.plist is silently never read.
- `AdsService.Unit` gets nine cases.

### 3.2 Runtime fallback chain (same format only)

`AdsService.unitID` returns `""` today for a missing key. Replace with:

```
bannerGarden            -> banner
bannerGardenCollapsible -> bannerGarden -> banner
rewardedHint, rewardedWake -> rewarded
appOpen, native         -> ""   (empty id disables that format; never a cross-format fallback)
```

Make the lookup testable: `unitID(_ unit:, info: [String: Any])` (or inject a test bundle).

### 3.3 Five unit tests (`WordFloraTests/AdUnitIDTests.swift`, pure, no SDK)

1. **Fallback chain:** each new key missing, and again set to `""`: Garden to Home; collapsible to Garden to Home (and to Home when Garden is also empty); hint and wake to water; appOpen and native return `""`.
2. **No cross-format fallback:** appOpen and native never return a banner, interstitial or rewarded id for any combination of missing keys.
3. **Id shape:** every `AdMob...UnitID` in the host `Info.plist` matches `^ca-app-pub-\d{16}/\d{10}$`; `GADApplicationIdentifier` matches `^ca-app-pub-\d{16}~\d{10}$` (tilde, not slash). Catches a missing entry and an unresolved `$(...)`.
4. **Debug test ids only / Release none:** under `#if DEBUG` every id contains Google's test publisher number; under `#else` none does and `AdMobBannerGardenUnitID == AdMobBannerUnitID` (the reuse decision, asserted).
5. **Format disabled when id empty:** `AdPolicy.decide(.appOpen, ...)` and `decide(.native, ...)` return `.no(.notApplicable)` with permissive inputs when the unit id is empty and `.yes` when set. (The G4b callers do not exist yet; test `decide` only, and note that G4b extends the B1 spy.)

---

## 4. Release build-phase check

Add a Run Script build phase to the app target that **fails a Release build** if:

- `Config/Ads.local.xcconfig` is missing (it is `#include?`, so a Release build on a fresh clone or a worktree silently ships Google test ids), or
- any Release unit id or app id in the built `Info.plist` contains Google's test publisher number, or an id is empty or unresolved.

Garden == Home is allowed. Debug builds are skipped by the script (`[ "$CONFIGURATION" = "Release" ] || exit 0`). Print only key names and a fail reason; never print an id. Note: `.claude/worktrees/*` do not contain the ignored local file, so a Release build from a worktree will (correctly) fail this check; use `CODE_SIGNING_ALLOWED=NO` Release builds from the main checkout, or `ADS_CHECK_SKIP=1` environment override that is honoured **only** when `CODE_SIGNING_ALLOWED=NO` (simulator proof builds). Document the override in the script header.

B3 extended in the report: Release bundle has real ids for all nine unit keys (Garden equal to Home) and none of Google's test ids; Debug has only test ids.

---

## 5. Hardening B1 to B8 (from `docs/research/ad-network-alternatives.md` 1.1, with the review rulings)

| # | Task |
|---|---|
| B1 | Age rule is airtight. `AdsService` gets a `prepareCount` spy and `offline = true`. For `nil` and `.under13` (and Plus): `adBeforeNextRound`, `playTappedOnHome`, `prepareBannerIfAllowed`, `watchRewarded(.water/.hint/.wake)` never increment `prepareCount`, never ask UMP or ATT. `showBanner` and `canOfferRewarded` false. For `.thirteenPlus`: `prepare` receives `.teen`, `requestTrackingIfNeeded` never reached, **and the UMP request sets the under-age-of-consent flag before `requestConsentInfoUpdate` (ruling H2; verify the property name in the installed SDK; add it to the teen row of the test)**. |
| B2 | Privacy report diff. Product > Archive > Generate Privacy Report (owner's machine if signing is needed; otherwise reason from the built bundle's merged manifest and say so). Compare with `PrivacyInfo.xcprivacy`; copy any tracking domain the report flags into `NSPrivacyTrackingDomains` (empty today). Confirm collected types match `docs/setup/age-rating-and-privacy-label.md`. |
| B3 | Release vs Debug id check (sections 3 and 4). Grep the project for `applovin` (case-insensitive): expect zero hits. `GADApplicationIdentifier` is the tilde app id. Also: fake presenter and the `-adcaps` / `-uitest-ads-fake` parsing are `#if DEBUG` only and the Release scan finds none of those strings (ruling H6). |
| B4 | Banner frame. `GardenView` fixes the banner at 60 pt; use the created `BannerView`'s `adSize.size.height` (binding from `AdBannerView`) so the ad is never clipped. |
| B5 | Preload the interstitial (`preloadInterstitial()`) when the resting card appears with `adWouldPlayOnOneMore == true`. |
| B6 | Garden banner unit key: `AdMobBannerGardenUnitID` plumbed per section 3, falling back to the Home id. (Reuse decision: no separate Garden unit is created.) |
| B7 | Rewarded request: no server-side verification, `customRewardString` unused, `maxAdContentRating = .general` for everyone. The app ignores the console reward amount (it uses its own constants). Sanity only. |
| B8 | `docs/setup/owner-setup-steps.md` C3 and C10: update to the five existing new units (Garden reuses Home), mediation groups exist (AdMob Network only), remove "remote config" wording, three ids become the real count. Wording only; the owner click-path lives in `docs/setup/admob-console-one-pager.md`. |

Also from the must-fix list (`admob-full-spec-review.md` section 5), the parts that belong to G4a:

- **H5:** `releaseAll()` on treatment `.none`, with an age-switch-after-start test (cached ads are released when the age band changes to under 13 or Plus becomes active).
- **H7:** free paths (Plus, under-13, unknown) are never blocked by session or full-screen budgets; they read only the per-perk day cap.
- H1 and H3 and H4 apply to app-open (G4b) but the entry point name is fixed now: `startIfConsentAlreadyResolved`, which never presents UMP and never calls `loadAndPresentIfRequired`. If it is cheap, add the function and its spy test in G4a; otherwise leave it for G4b and say so.

---

## 6. AdPolicy core (`Rules/AdPolicy.swift`, pure, Foundation only)

Types and signatures exactly as in `admob-full-spec.md` sections 0.1, 1.0, 2 (path), 2.4 (ledger) and 3 (caps): `AdTreatment`, `AdFormat`, `BannerSlot`, `RewardedPerk`, `AdSessionState`, `AdInputs`, `AdDecision`, `AdBlock`, `AdPolicy.decide`, `AdPolicy.path`, `AdCaps`, `AdLedger`. `AppModel.adInputs()` builds the inputs in one place and replaces the scattered checks in `showBanner`, `canOfferRewarded` and `adContext`. `AdGate.mayLoadAnyAd == (treatment != .none)` and `ParentalGate.isRequired` call the same function.

### 6.1 Age-band table (the whole safety claim)

| `AgeBand?` | Plus (monthly, yearly, Plus Forever) | Treatment | SDK start / UMP / ATT |
|---|---|---|---|
| `nil` | any | none | never start, no UMP, no ATT |
| `.under13` | any | none | never start, no UMP, no ATT |
| `.thirteenPlus` (13 to 17) | no | teen: `ageRestrictedTreatment = .teen`, `maxAdContentRating = .general`, non-personalised | UMP yes, ATT never |
| `.eighteenPlus` | no | adult: `.unspecified`, `.general`, personalised only with UMP consent and ATT | UMP, then ATT |
| `.thirteenPlus` / `.eighteenPlus` | yes | none (every ad, every rewarded prompt, every ad note) | no new start; a started SDK stays idle |

`decide` checks `treatment == .none` first, before reading any other input, for every format (makes the under-13 rule structural). Then entitlements loaded, onboarding complete, round in progress, quiet visit, pending ceremony; then the per-format rules.

### 6.2 Caps: use the RULED numbers, not the stale 1.1 table

The 1.1 table in `admob-full-spec.md` still prints the old numbers; update it to match (section 8). Release literals (an app update to change; the owner can raise them later):

| Cap | Value |
|---|---|
| Pushed ads (interstitial + app-open) per day | 6 (shared; unchanged) |
| Pushed ads per session | **2** |
| Full-screen ads (interstitial + app-open + rewarded) per day | **8** |
| Full-screen ads per session | **4** |
| Gap: any full-screen to next pushed | **600 s** |
| Gap: any full-screen to next rewarded | 30 s |
| Gap: any full-screen to app-open | 30 min |
| Rewarded per day (all perks) | 5 |
| Rewarded per session | 3 |
| Per perk per day | water 3, hint 2, wake 1 |
| Celebration quiet window | 5 s |

Interstitial rules stay as today (every 3rd round, `oneMore` or `playSoonAfterEnough`, never night, grace of 3 sessions or a level-up, never session 1). A clock that moved backwards counts as "gap not met"; more than 24 h behind resets that timestamp to now. No remote config: Release always uses the literals; the `-adcaps "key=value,..."` and `-uitest-adcaps-fast` overrides are `#if DEBUG` only. Fix the stale `// remote-config tunables` comment in `AdGate.Context` to "compile-time defaults".

### 6.3 Ledger and counters: no new stored field

- Synced `PlayerProfile` fields, meaning widened (no schema change): `lastAdAt` (any full-screen ad), `adsToday`/`adsDay` (pushed), `rewardedToday`/`rewardedDay` (all rewarded). `recordAdShown` becomes `recordFullScreen(kind:)`.
- Device-local `AdLedger` JSON string under key `adLedger` in the App Group `SharedDefaults.store`, read through `AppSettings`. Not SwiftData, not CloudKit.
- Test: `PlayerProfile` / SwiftData property list is unchanged (assert equals the G3 list). Integrator greps the `Models/` diff: it must be empty.

### 6.4 Required tests (`WordFloraTests/AdPolicyTests.swift`)

1. Table-driven treatment: every `AgeBand?` x `hasPlus` gives the table above.
2. Never for under 13, unknown, or Plus: for each of `banner(.home)`, `banner(.garden)`, `collapsible`, `interstitial(.oneMore)`, `interstitial(.playSoonAfterEnough)`, `appOpen`, `native`, `rewarded(.water/.hint/.wake)`, with every other input at its most permissive value, `decide` returns `.no(.ageOrPlus)`.
3. **Seeded fuzz:** 1,000 random `AdInputs` per blocked band (`nil`, `.under13`, plus any-band-with-Plus), fixed seed, for every format: always `.no(.ageOrPlus)`. `path(perk)` is `.free` or `.hidden`, never `.ad`. Print the seed on failure.
4. Per-band yes: permissive inputs give `.yes(.teen)` for 13 to 17 and `.yes(.adult)` for 18+ on every G4a format; `mayAskTracking` true only for `.eighteenPlus`.
5. Budgets: pushed 6/day shared; 2 per session; full-screen 8/day and 4/session; gaps 600 / 30 / 1800 s; backwards clock; free paths not blocked by session or full-screen budgets (H7).
6. Rewarded perks: per-perk caps 3/2/1, global 5/day and 3/session; R1 needs water 0; R2 hidden after a loss, on Daily, when banked, **and while the "A short ad may play first" note shows**; R3 needs `wakeDreamsInARow >= 1`; Quiet Garden hides R2 for everyone (ruling: no asymmetry); `HelpLadder.whisper` rung order, never the last letter, ignored on Daily; R3 grants no badge, album, water, shed points or soil.
7. Interstitial regression: all existing `AdGate` tests unchanged and green.
8. Ledger: day rollover resets counts; JSON round trip; corrupt JSON reads as empty.
9. Service wiring (extends B1): see section 5, B1.

App-open, collapsible and native rows of the spec test plan are G4b.

---

## 7. Rewarded perks R1, R2, R3 (with all rulings applied)

Common: user-initiated tap; the label says it plays a video; the reward is in the label; never required for progress; never during a puzzle, on a loss, in a `quietVisit`, in the first session. **Plus, under-13 and unknown age get every perk free** (no video, no prompt to watch); free and ad caps are the same number. Free paths never mention Plus to a child. For Plus the caption is "Included with Plus".

- **R1 Water** (Garden card "Your watering can is empty." when `water == 0`, not in Quiet Garden; existing Plant detail button shares the cap). Ad label "Watch a short video for 2 drops" with the play-rectangle icon; free label "Fill from the rain barrel". Effect `water = min(waterBankCap, water + 2)`. Toast "2 drops are in your can". Cap 3 a day.
- **R2 Hint** (resting card, below One more / That's enough, above the Go ad-free row). **Title: "Watch a short video for a hint"**, sub-line "A whisper for your next word" (ruling: "video" in the title; sub-lines must pass 4.5:1 contrast). Free label: title "Ask the garden for a hint", sub-line "A whisper for your next word". Hidden: after a loss, on the Daily Bloom card, **while the "A short ad may play first" note shows (never stack two ad prompts)**, in Quiet Garden **for all ages and Plus** (one rule, no asymmetry). When a whisper is already banked the row reads "A whisper is waiting for your next garden word", no button. Effect: banks one whisper (max 1). Next non-Daily, non-tutorial round gains `HelpLadder` rung `.whisper` after hint2, vowel and first letter: reveals the most frequent unrevealed consonant, never the last unrevealed letter, no petal cost. Help button shows a small leaf dot while a whisper is banked (VoiceOver hint "A whisper is waiting"); **the dot is hidden during the Daily Bloom and the tutorial**. After the ad closes, recompute `adWouldPlayOnOneMore`. Cap 2 a day.
- **R3 Wake** (wake sheet, third row below the two challenge tiles, only when `settings.wakeDreamsInARow >= 1`). Ad label "Wake with a short video", sub-line "The two challenges stay free"; free label "Wake gently", sub-line "Once a day, after one try". Effect: wakes exactly like a "woke" result (`PetalReturn`, `lastLovedAt = now`), `wakeDreamsInARow = 0`, `lastWakeResult = .woke`; no sticker, badge progress, water, shed points or soil. Toast "<name> is awake". Calm and Quiet Garden never have seeds, so it never appears there. Cap 1 a day.
- Shared prompt row component and toast component; all three perks use the standard **rewarded** format (not rewarded interstitial). Unit keys per section 3.
- Never show a rewarded row when no ad can load **after one failed load this session**.

UI tests (`AdFormatsUITests` plus touched `RestCardUITests`, `GardenUITests`, wake tests) use a `-uitest-ads-fake` `FakeAdPresenter` (plain full-screen "TEST AD" view, closes on tap, can grant or withhold the reward). The fake and the debug parsing compile out of Release (H6). Cases: R1 row at water 0 for an adult, watching grants 2 and toast; under 13 free row; Plus free row "Included with Plus"; Quiet Garden adult absent. R2 row on the rest card; after the fake ad the short-ad note is gone; next round Help reveals a consonant after the three rungs; not on Daily; not after a loss; hidden while the short-ad note shows. R3 third row only after one "still dreaming".

Audits: `performAccessibilityAudit` light and dark, default and `accessibilityExtraExtraExtraLarge`, on Garden with R1 row and banner, resting card with R2 row, wake sheet with R3 row, each toast. No truncation, no `ViewThatFits`, no `.dynamicTypeSize(` caps, no `lineLimit` on prompt text. Every new string through `CopySafety` (grade 2 for child-visible free rows).

---

## 8. Spec inconsistency cleanup (docs only, in the same gate)

Edit `docs/pm/admob-full-spec.md` so a reader going top-down builds the right thing:

1. Section 1.1 cap table: replace with the ruled numbers (section 6.2 above), each marked "(ruled 11-07)".
2. Section 5.2 and 5.3 and 6: "six new units" becomes "five new units, created 2026-11-07"; "three banner units" becomes two banner units (Home id also serves Garden); refresh 60 s on the Home banner unit and **off** on the collapsible unit; Garden row says "reuse Home id".
3. Section 1.3 and B6: Garden refreshes and non-collapsible loads use the Home id through `ADMOB_BANNER_GARDEN_ID`. State the collapsible handoff: one `BannerView` has one unit id, so G4b creates the Garden `BannerView` with the collapsible id and, on `bannerViewDidReceiveAd` (collapsible or not) or dismissal, swaps in a second `BannerView` on the Home id (option a).
4. Section 4.5 and B3: "nine unit keys, real, Garden equal to Home" (eight distinct real unit ids plus the app id), not "nine real unit ids".
5. Remove the stale "remote config" wording: `AdGate.Context` comment and `owner-setup-steps.md` C3.
6. `owner-setup-steps.md` C3, C10 and "send back": five new unit names, Garden reuses Home, mediation groups AdMob-only, counts correct.
7. Native reuse: 30 min is safe, 1 h is Google's ceiling; mark the [verify] resolved.
8. Console reward item: pick "Drops" or "Water" in the console notes (the app ignores it).
9. Revenue expectation line: $90 to $205 a month at 10,000 players (review estimate), not $150 to $295.

Do not edit the three "Review rulings" sections; they are the record.

---

## 9. D8 review notes (owner steps, wording)

`docs/setup/owner-setup-steps.md` D8 must say, in plain words: ads begin from the third session for players who say they are 13 or over and do not have Plus; 13 to 17 get non-personalised, G-rated ads and no tracking prompt; under 13 and no-age-answer players never see any ad and the ad SDK never starts; rewarded videos are optional and every reward also exists without an ad; Plus (monthly, yearly, Plus Forever) removes all ads. The return-ad sentence is added when G4b ships. Reviewers see no ads in session 1 (grace of 3 sessions), so "Go ad-free" must be explained there.

---

## 10. Exit criteria and report

Exit: never-for-under-13 table and fuzz green; B1 spy green; AdUnitIDTests green; R1 to R3 UI green; Release build-phase check proven (fails with the local file hidden, passes with it); no `Models/` diff; Release bundle has no test ids and no fake-presenter strings; faded-bloom screenshots attached; full unit suite; the UI classes you touched (`WordFloraUITests` Garden / Settings / Plus, `RestCardUITests`, `AdFormatsUITests`, wake tests, `HomeLayoutUITests` banner slot, `ParentalGateLinkUITests`).

Final message must contain: commit hashes in order, test counts and reds with reasons, the collapsible test id outcome, privacy report outcome and any tracking domains added, the grep-for-attribution result (prints 0), the sentence "no stored field added" with the empty `Models/` diff, and open items for G4b. Do not write the report to a file.

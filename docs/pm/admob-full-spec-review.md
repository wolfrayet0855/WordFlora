# Review of `admob-full-spec.md` (AdMob, all formats, 1.0)

Reviewed 2026-11-07 against `docs/pm/admob-full-spec.md`, the four SVGs in `design-preview/admob/`, `docs/research/ad-network-alternatives.md`, `docs/pm/release-plan-extended.md`, `docs/pm/status-review-2026-11-07.md`, `docs/research/revenue-compensation.md`, and the code the spec cites (`WordFlora/Ads/AdsService.swift`, `WordFlora/Rules/AdGate.swift`, `WordFlora/App/AppModel.swift` ad section, `WordFlora/App/WordFloraApp.swift` scene phase, `WordFlora/Rules/HelpLadder.swift`, `WordFlora/Rules/WakeChallenge.swift`, `WordFlora/Rules/Paywall.swift`). Nothing here cuts scope; items that would need the owner are marked **[OWNER]**.

**Verdict: approve the spec for build after the 9 must-fixes in section 5.** The age rule is structurally sound; the holes are in consent re-entry, cold-launch timing and one label.

---

## 1. Owner rules and policy

### 1.1 What holds

- **Treatment first.** `AdPolicy.treatment` returning `.none` for `nil`, `.under13` and Plus, checked before any other input in `decide`, plus `path(perk)` never returning `.ad` for `.none`, is the right shape. It matches today's `AdGate.mayLoadAnyAd` + `ParentalGate.isRequired(ageBand:)` (`nil` or `.under13`) and `mayStillLoadAds` (which also requires `entitlements.hasLoaded`). The table + 1,000-case fuzz per band in 4.1 is the proof App Review needs.
- **Teens:** `.teen`, G rating, no ATT (`AdGate.mayAskTracking` is `== .eighteenPlus` only). Correct.
- **Apple 2.5.18:** ads only in the app binary (widget stays clean), labelled, visible close. The cue's own Skip, Google's close on full-screen formats and AdChoices on native cover it.
- **Kids Category:** the app is not in it; the spec's "do not move it" line is right (1.3 / 5.1.4 would forbid every format).
- **ATT 5.1.1/5.1.2:** no reward depends on the ATT answer. Correct.
- **Google native policy** (badge 15 px, AdChoices, no truncation, 120 pt media, no stretching, background not tappable, no overlap): section 1.4 meets each clause.
- **Google app-open** (4 h expiry, loading screen, not on first sessions): met by fresh load + cue + `appOpenMinSessions = 3`.
- **Google collapsible** (Google demand only, refresh never collapsible, count only when `isCollapsible`): met.
- **Rewarded interstitial dropped (1.7):** correct call. It is auto-shown with opt-out, which breaks "rewarded is the player's tap". Not a cut; the three perks all use standard rewarded.

### 1.2 Holes (each is a must-fix in section 5)

**H1. App-open can still raise the UMP form.** Section 1.2 says the app-open path "starts `prepare`". Today `AdsService.prepare` always calls `requestConsentInfoUpdate` **and** `ConsentForm.loadAndPresentIfRequired`. `consentStatus == .obtained` at the time of the check does not stop that: a consent-info update can return `.required` again (consent older than 13 months, a region change, a message republished in the console), and the form would then present over the "Welcome back" cue, which is exactly what 0.2 forbids. Fix: a second entry point, `startIfConsentAlreadyResolved(treatment:)`, that sets the request configuration and calls `MobileAds.start` **without** calling `loadAndPresentIfRequired` (and treats a status change to `.required` as "not eligible, no ad, no prompt"). App-open and native use only that entry point; the test in 4.2 ("app-open and native never call `requestConsent`") must spy on `loadAndPresentIfRequired`, not only on `prepare`.

**H2. UMP is not told the request is for a teen.** `requestConsent()` builds `RequestParameters()` with no under-age-of-consent tag. UMP has a per-request flag for this (`RequestParameters.isTaggedForUnderAgeOfConsent` **[verify exact property name in the installed UMP SDK]**). For 13 to 17 it must be set to true before `requestConsentInfoUpdate`, in the same place `ageRestrictedTreatment = .teen` is set. Without it the GDPR form treats a 15-year-old as an adult who can consent to personalisation; with it the SDK applies its under-age rules. Low effort, real policy point.

**H3. Cold launch from a link.** `launchedFromLink` is read "in the same frame" as `.active`. In `WordFloraApp.swift` the link arrives through `.onOpenURL` (line 210) and the notification-response delegate, both of which can fire **after** `scenePhase == .active` on a cold launch. The cue would show over a deep-linked plant or reminder target. Fix: on cold launch, defer the app-open decision until the first run-loop turn after `.active` **and** after the router has had the chance to receive a URL or notification response; any pending URL / notification / Shortcut / widget launch sets `launchedFromLink` before `decide` runs. Warm resume keeps the same-frame behaviour.

**H4. Cold launch and `entitlementsLoaded`.** `decide` refuses everything until `entitlementsLoaded`, and `Transaction.currentEntitlements` takes hundreds of milliseconds to seconds on a cold start. iOS usually evicts an app within 4 h, so most "4 h away" returns are cold launches, and the cue would almost never qualify: the app-open format would be shipped but barely fire. Two honest options **[OWNER]**:
- (a) Keep the rule as written and accept that app-open fires mostly on warm resumes (revenue in section 2 drops to the low end).
- (b) Cache the last known treatment in the device-local `AdLedger` at every `.background` (`lastTreatment`); on cold launch the cue may show when the cached treatment is `.teen`/`.adult`, but the **ad is presented only after** entitlements load and `decide` still says yes. If entitlements come back Plus, the cue lifts with no ad. A Plus player who bought on another device may see the cue once, never an ad. Under-13/unknown is unaffected (cached treatment `.none` means no cue). Recommended: (b), and the 2.5 s budget runs from the cue, not from entitlement load.

**H5. Treatment change mid-session.** When the age band is changed to under 13 in Settings, or Plus arrives, `showBanner` flips and the views drop, but cached ads stay in memory (`interstitial`, `rewarded`, and now app-open and native). They are never shown because `decide` refuses, which is correct, but add an explicit `AdsService.releaseAll()` when treatment becomes `.none` (drop cached ads, cancel the native `AdLoader`, stop any `BannerView` auto-refresh by removing the view). Add one test: age switched to `.under13` after `started == true` → no further load call of any format.

**H6. `-uitest-ads-fake` and the fake presenter must not exist in Release.** Spec 4.3 adds a `FakeAdPresenter`; B3's Release scan must also assert the class and the launch-argument parsing are `#if DEBUG` (grep the Release binary's strings for "TEST AD" and "FakeAdPresenter").

**H7. Session rewarded cap can hide a free row.** `rewardedPerSession = 3` and `fullScreenPerSession = 5` are ad counters; the spec says free and ad caps "are the same number" per perk, which is right, but the free path must never be blocked by session/full-screen budgets (they measure ads shown). State it: `path(perk)` for treatment `.none` reads only the per-perk day cap.

No hole was found where an under-13 or unknown-age player sees or triggers an ad, UMP, ATT or `MobileAds.start`, provided H1 and H5 land. The free rows never say "video", "Plus" or a price to a child (R1 "Fill from the rain barrel", R2 "A whisper for your next word", R3 "Wake gently"); confirmed in `rewarded-prompt.svg`.

### 1.3 Policy gaps the spec marks [verify], and my read

- Native ad reuse 1 h: Google's recommendation is to show a native ad promptly after load and not to hold it for long; 1 h is at the long end. Use **30 min** unless the fetched page says otherwise.
- Rewarded "video": the console units are rewarded, not video-only; an image rewarded ad can serve. The label "short video" is still honest in practice, but "short ad" is safer on all three rows. Recommend "Watch a short ad for 2 drops" etc. **[OWNER]** (copy only).

---

## 2. Caps and revenue

### 2.1 Ad load

The caps are ceilings, not expected exposure. For a calm word game the ceilings are too high in two places:

| Cap | Spec | Recommend | Why |
|---|---|---|---|
| Pushed per session | 3 | **2** | A sitting with return ad + two interstitials is not calm. Two is the natural ceiling: app-open or an interstitial, then one more at round 6 |
| Full-screen per session | 5 | **4** | 2 pushed + 2 rewarded; a fifth is a fourth minute of ads in one sitting |
| Gap: app-open → next pushed | 180 s | **600 s** | With 180 s a player can see the return ad, play three rounds and get an interstitial at minute 4 |
| Full-screen per day | 10 | 8 | 6 pushed is already the daily ceiling; 8 leaves 2 to 5 rewarded, which is all a calm game needs |
| Everything else | as spec | keep | 6 pushed/day (shared), 1 app-open/day, 1 collapsible/session, 5 rewarded/day, 30 s after any full-screen before a rewarded tap |

Expected real exposure at those numbers, for a typical 13+ free daily player (2 sessions, 4 rounds): 0 to 1 interstitial, 0.3 to 0.5 app-open, 0 to 1 collapsible, 6 to 8 banner refreshes, 0.1 to 0.3 rewarded. That is on the light side of casual word games (which run 2 to 4 interstitials per daily player) and will not move reviews. The thing that will move reviews is the **first** app-open ad a player sees; the cue with Skip and "once a day, 4 h away" is the right insurance, and the D7 trigger (2 points) in section 7 is the right tripwire. Add D1 to the tripwire: app-open is the only format a new player can meet on day 2.

### 2.2 Revenue (10,000 monthly players, base case: 1,470 ad-eligible daily players, 44,100 player-days a month)

| Format | Spec | My estimate | Working |
|---|---|---|---|
| R1 to R3 rewarded | $60 to 120 | **$40 to 90** | +0.1 to 0.2 rewarded per player-day (R1 fires only at water 0, R2 only on the rest card, R3 rarely) × $12 × teen factor 0.7 on 25% of them = 4,400 to 8,800 impressions × about $10 |
| App-open | $50 to 90 | **$25 to 55** (option b) / $10 to 25 (option a) | Eligible once a day for players who return after 4 h outside 9 pm to 8 am and not Calm/Quiet/link (about 0.6 per player-day); 2.5 s budget on cold start fills maybe 40 to 60% → 0.25 to 0.35 shown; app-open eCPM runs below interstitial, about $5 to 7 blended |
| Native (Shed) | $30 to 60 | **$10 to 25** | Shed visits are about 0.3 to 0.5 per player-day; one card below Pots is viewable maybe half the time; native eCPM at the bottom of a browse screen is $0.8 to 2 → 7,000 to 11,000 viewable impressions |
| Collapsible | $10 to 25 | **$15 to 35** | One per session on Garden for sessions 3+, up to 2/day → about 1.0 per player-day at a $1 to 1.5 uplift over the plain banner it replaces |
| **Total** | **$150 to 295** | **$90 to 205** | About 30 to 35% below the spec; the spec's 13+ base of $665 is itself the base case, so $90 to 205 is +14 to 31% |

$150 to 295 is reachable only if R2 gets strong uptake (rewarded hints are the best-converting rewarded placement in word games, so it might) and app-open fills on cold start. Plan on $90 to 205, measure per unit as in `ad-network-alternatives.md` 1.4, and do not loosen a cap to chase the gap. The order of value per builder-hour is: R2 (4 h) > collapsible (2 h) > app-open (5 h) > R1 (2 h) > R3 (2.5 h) > native (6 h).

---

## 3. UX, accessibility, fairness

### 3.1 Mockups and copy

- **App-open cue** (`app-open-cue.svg`): fits the brand; still art, Ad chip in the body (not hidden in a corner), one secondary Skip at 52 pt. Good. Two changes: (1) make the cue read "A short ad, then your garden" **only when an ad is actually loaded**; while loading show just the three dots, so the cue never promises an ad that did not come (today the text is up for 2.5 s even on no fill); (2) Skip should be reachable by VoiceOver as the **first** element after the heading, and the cue's `accessibilityViewIsModal` must be removed the instant it lifts, or VoiceOver focus stays trapped.
- **Native card** (`native-card.svg`): correctly not a plant card; "SPONSORED" header + "Ad" badge + AdChoices + outlined CTA. Add: `UIButton.titleLabel?.numberOfLines = 0` and `adjustsFontForContentSizeCategory` on the CTA (the spec lists it only for `UILabel`); a 28 pt trailing inset on the advertiser label so a wrapped name never runs under AdChoices at AX sizes; the card's `accessibilityElements` must include the `MediaView` (video has its own controls) or VoiceOver cannot pause it.
- **Rewarded rows** (`rewarded-prompt.svg`): R1 and R3 say "video" in the title; **R2 does not** ("Ask the garden for a hint", with "Short video" only in the 13 pt, 60% sub-line). The spec's own common rule is "a row whose label says it plays a video". Title must carry it: "Watch a short video for a whisper" or "A short video, then a whisper". Also the 13 pt sub-lines at 0.58 to 0.6 opacity on `#FAF7F0` compute to about 3.3:1, below 4.5:1 for small text; the disclosure line should be at least 0.72 opacity (about 4.6:1) or use the app's existing secondary text token if that already passes the audit.
- **Reward toast** (`reward-toast.svg`): fine. "No Ad label on the toast" is correct (it reports the reward). 6 s under VoiceOver plus tap-to-close is enough.
- Copy is calm throughout; no urgency, no "only today", no price on a child row. "Ads help keep WordFlora free." is honest and short. Everything through `CopySafety` at grade 2 for free rows is right.

### 3.2 Dynamic Type and audits

No `ViewThatFits`, no `.dynamicTypeSize` cap, no `lineLimit` on any ad or prompt text: the spec says so and 4.4 greps for it. The UIKit native card is the one place a builder can regress silently (fixed-height constraints on the badge or CTA); require `performAccessibilityAudit` at `accessibilityExtraExtraExtraLarge` on the Shed with the fake card in both schemes, which 4.4 lists. Good.

### 3.3 Calm and Quiet Garden

- Calm: no app-open, no collapsible, rewarded rows plain, native image-only. Right.
- Quiet Garden: no app-open, no collapsible, rewarded **ad** rows hidden; banners and native stay. Right, with one inconsistency: a 13+ free player in Quiet Garden gets **no** R2 (ad path hidden, no free path), while a child or Plus player in Quiet Garden gets the free whisper. Quiet Garden's own rule is "no counts, no marks", and "2 a day" is a count. Recommend: in Quiet Garden R2 is `.hidden` for everyone, or `.free` for everyone **[OWNER]**. Hidden is more Quiet-Garden-like. (R1 and R3 do not arise there: no drops, no seeds.)

### 3.4 Fairness, pay-to-win, child equivalence

- **R2 on the resting card**, banked for the next word, is the right move; it keeps the puzzle ad-free and keeps the Daily Bloom equal for everyone. The whisper rung (most frequent unrevealed consonant, never the last letter, after the three free rungs) is a convenience on a single-player, no-leaderboard game. Not pay-to-win.
- **R3 wake** after one "still dreaming", no sticker/badge/water/points: a convenience, and the two challenges stay free and untimed. Not pay-to-win. Keep it at 1 a day.
- **Child equivalence:** under-13, unknown and Plus get every perk free at the same caps; 13+ free players get it after a video. No feature is behind an ad for anyone: water trickles back, the help ladder is free, both wake challenges are free. **No ad-wall exists.** The only asymmetry is the Quiet Garden R2 one above.

---

## 4. Schedule and sequencing

At the status review's 14 builder-hours a day, after G3 (Thu 11-12 afternoon) and the CloudKit deploy (Thu evening): G4a 20 h → Sat 11-14 morning; G5 20 h → Sun 11-15 evening; G4b 15 h → Mon 11-16 evening; G6 16 h → Tue 11-17 night; owner device checks and ASC about 1.5 days → Thu 11-19 evening. **Thu 11-19 is a coin flip (0 to 1 day late); Mon 11-23 holds with about 2.5 days of slack.** Same conclusion as the spec.

**Order: G3 → deploy → G4a → G5 → G4b → G6** (that is O6, and it needs no approval to recommend; it moves nothing out of the release).

Why G4b after G5:
1. The G5 go/no-go is Fri 11-13 20:00, before G4b would start. If the art falls back, G4b gains the 20 h and 11-19 is comfortable; if not, nothing is lost.
2. G4b's audits (collapsible overlay on the Garden, native card under the pack pots in the Shed) should run on the final scene G5 draws, not be re-run after it.
3. G4b is the most self-contained code (app-open, native, collapsible touch `AdsService`, one cue view, one Shed section, the Garden banner slot) and so the only clean candidate for O5 if its UI tests are not green at G6 start.
4. G4a must stay before G5: it rewrites the rest card, Garden and wake sheet, which G5 does not touch, and it is the foundation (`AdPolicy`, budgets, ledger) that G4b reads.

Lock-free head start: the G4a builder can write `AdPolicy`, `AdCaps`, `AdLedger`, `HelpLadder.whisper` and the unit tables during G3 and only build under the lock once G3 merges. That recovers 4 to 6 h of calendar time.

**Ranking of the date-protection options, if needed [OWNER, approval required for any of them]:**

1. **O6** (G4b after G5): free, no revenue given up. Do it regardless.
2. **O5** (compile-time flag on any G4b format whose UI tests are not green by G6 start): 0 h, protects G6; loses only that format's revenue until 1.1.
3. **O1** (native to 1.1): saves 6 h for my estimate of $10 to 25/mo, the worst value per hour and the least visible to players.
4. **O4** (R3 to 1.1): saves 2.5 h for $5 to 15/mo; smallest audience.
5. **O3** (collapsible to 1.1): saves 2 h for $15 to 35/mo.
6. **O2** (app-open to 1.1): saves 5 h for $25 to 55/mo, the best value per hour of the G4b set; last to go. Its calm risk is covered by the cue, the caps and the D7 tripwire, so soft risk is not a reason to rank it higher.

---

## 5. Must-fix before a builder starts

1. **H1:** app-open and native use a `startIfConsentAlreadyResolved` entry point that never calls `loadAndPresentIfRequired`; the 4.2 spy covers that call, not just `prepare`.
2. **H2:** set UMP's under-age-of-consent request flag for `.thirteenPlus` before `requestConsentInfoUpdate` (verify the property name in the installed SDK); add it to the teen row of the 4.2 test.
3. **H3:** on cold launch, decide app-open only after the URL / notification / Shortcut routing has had its turn; any pending link sets `launchedFromLink` first.
4. **H4 [OWNER]:** choose (a) or (b) for cold-launch entitlements; the spec as written makes app-open fire almost only on warm resume.
5. **H5:** `releaseAll()` on treatment `.none`, with the age-switch-after-start test.
6. **H6:** fake presenter and `-adcaps` / `-uitest-ads-fake` parsing compiled out of Release; B3 scans for them.
7. **R2 label** carries "video" (or "ad") in the title; disclosure sub-lines at a contrast that passes 4.5:1.
8. **Caps:** pushed per session 2, full-screen per session 4, app-open → next pushed 600 s, full-screen per day 8 (section 2.1). These are Release literals, so they are an **[OWNER]** decision; the spec's values are not unsafe, only heavier than the brand needs.
9. **Quiet Garden R2** one rule for everyone (hidden recommended) **[OWNER]**; and H7, free paths read only the per-perk day cap.

Should-fix (not blocking): native reuse 30 min; "short ad" instead of "short video" **[OWNER]**; cue text only once an ad is loaded; CTA button Dynamic Type; AdChoices inset; `MediaView` in the accessibility order; D1 added to the retention tripwire.

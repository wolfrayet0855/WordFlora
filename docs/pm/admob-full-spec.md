# AdMob full integration for 1.0: spec

Written 2026-11-07 from the tip of `3-feat-content-and-polish`. Owner decision (same day): **AdMob is the only network for 1.0** (AppLovin dropped, Unity in 1.1). This release ships the G4 hardening fixes B1 to B8 **and** app-open ads, a collapsible Garden banner, a native ad, rewarded placements R1 / R2 / R3 and the frequency-cap changes. Nothing requested is cut. Where a format carries risk, this spec gives the safe version.

Code read: `Ads/AdsService.swift`, `Rules/AdGate.swift`, `App/AppModel.swift` (ads, rewarded, Plus offer), `App/AppSettings.swift`, `App/WordFloraApp.swift` (scene phase), `Models/PlayerProfile.swift`, `Rules/Paywall.swift` (`EntitlementState`, `ParentalGate`), `Rules/HelpLadder.swift`, `Rules/WakeChallenge.swift`, `Rules/LoveEngine.swift`, `Rules/Butterfly.swift` (`ButterflyRewards`), `Views/GardenView.swift`, `Views/HomeView.swift` (banner area), `Views/GameView.swift` (resting card), `Views/PlantDetailView.swift` (today's rewarded button), `Views/ShedView.swift`, `Views/WakeSheet.swift`, `Config/Ads.xcconfig`, `docs/research/ad-network-alternatives.md`, `docs/research/revenue-compensation.md`, `docs/research/monetization-majors.md`, `docs/setup/owner-setup-steps.md` section C, `docs/pm/release-plan-extended.md`, `docs/pm/status-review-2026-11-07.md`, `docs/pm/quiet-garden.md`.

Google pages fetched today: app open (https://developers.google.com/admob/ios/app-open), collapsible banner (https://developers.google.com/admob/ios/banner/collapsible), native (https://developers.google.com/admob/ios/native) and native ad policy (https://support.google.com/admob/answer/6329638). Source tags: **[Google, fetched]**, **[Apple guideline]**, **[inferred]**, **[verify]** (not fetched; check before relying on it). **[OWNER]** marks a choice that needs the owner.

Mockups: `design-preview/admob/native-card.svg`, `app-open-cue.svg`, `rewarded-prompt.svg`, `reward-toast.svg` (each has light and dark side by side). Note: the brief said docs/pm only, but it also named `design-preview/admob/` for the SVGs; I wrote them there and nowhere else.

---

## 0. Rules every format obeys

### 0.1 Who sees ads (one function for all formats)

| Age band (`AgeBand?`) | Plus (monthly, yearly, Plus Forever) | Treatment | SDK start / UMP / ATT |
|---|---|---|---|
| `nil` (unknown) | any | **none** | never start, no UMP, no ATT |
| `.under13` | any | **none** | never start, no UMP, no ATT |
| `.thirteenPlus` (13 to 17) | no | **teen**: `ageRestrictedTreatment = .teen`, `maxAdContentRating = .general`, non-personalised | UMP yes, **ATT never** |
| `.eighteenPlus` | no | **adult**: `.unspecified`, `maxAdContentRating = .general`, personalised only if UMP consent and ATT allow | UMP, then ATT |
| `.thirteenPlus` / `.eighteenPlus` | yes | **none** (every ad, every rewarded prompt, every ad note) | no new start; a started SDK stays idle |

```swift
// Rules/AdPolicy.swift (new, pure, no imports beyond Foundation)
enum AdTreatment: Equatable { case none, teen, adult }
static func treatment(ageBand: AgeBand?, hasPlus: Bool) -> AdTreatment {
    guard !hasPlus else { return .none }
    switch ageBand { case .eighteenPlus: .adult; case .thirteenPlus: .teen; case .under13, nil: .none }
}
```

`AdGate.mayLoadAnyAd` and `ParentalGate.isRequired` keep working; `AdPolicy.treatment` becomes the single source they both call (`mayLoadAnyAd == (treatment != .none)`), so no format can drift.

### 0.2 Order of consent (unchanged, now enforced for every format)

Age gate (onboarding) → **UMP** (only right before the first allowed ad request) → **ATT** (adults only, only after UMP says ads may be requested) → set `requestConfiguration` (treatment, G rating) → `MobileAds.shared.start`. `AdsService.prepare` already does this. New rule: **app-open and native may never be the request that triggers UMP or ATT.** They are eligible only when consent is already resolved (`ConsentInformation.shared.consentStatus` is `.obtained` or `.notRequired`, and for adults `ATTrackingManager.trackingAuthorizationStatus != .notDetermined`). Only banner, interstitial and rewarded (all of which follow a calm, expected moment) may be the first request.

### 0.3 Calm guarantees (every format)

- **Never during a puzzle in progress** (`game.phase == .playing`), never in the tutorial, never in onboarding, never around the Daily Bloom result, never after a lost round, never in a `quietVisit` (ending ceremony or weather puzzle this visit).
- **Quiet Garden:** no app-open, no collapsible, no rewarded **ad** prompts (the free paths in section 2 still exist for Plus and children). Banners and the native card stay (they are static, not prompts; today Quiet Garden already shows banners).
- **Calm mode:** no app-open, no collapsible; rewarded rows stay but are plain (no shimmer, no sound, toast fades only); the native card shows image ads only (a video ad is dropped unshown, see 1.4).
- **Night (9 pm to 8 am, `AdGate.isNight`):** no interstitial (today), no app-open (new). Rewarded rows stay (player-initiated).
- **Widget, notifications, Live Activities:** no ads ever (Apple 2.5.18, below).

### 0.4 Session

An **ad session** starts at a cold launch, or at `.active` after 30 min or more in the background. Session counters are in memory only. `completedSessions` (AppSettings, +1 per launch after onboarding) is unchanged and still drives the grace rules.

---

## 1. Formats

### 1.0 Eligibility: one pure entry point, unit-testable

```swift
enum AdFormat: Equatable { case banner(BannerSlot), collapsible, interstitial(AdGate.Choice), appOpen, native, rewarded(RewardedPerk) }
enum BannerSlot { case home, garden }
enum RewardedPerk: String, Codable, CaseIterable { case water, hint, wake }   // R1, R2, R3

struct AdSessionState: Equatable {
    var startedAt: Date
    var fullScreenShown = 0            // interstitial + app-open + rewarded this session
    var pushedShown = 0                // interstitial + app-open this session
    var rewardedShown = 0
    var collapsibleShown = 0
    var lastBackgroundAt: Date?        // for app-open
    var roundWasInProgressAtBackground = false
    var launchedFromLink = false       // URL, widget, notification, App Shortcut, Siri
    var quietVisit = false
    var consentResolved = false        // UMP obtained / not required
    var attResolved = false            // adults: status != .notDetermined; teens: always true
}

struct AdInputs: Equatable {
    var ageBand: AgeBand?
    var hasPlus: Bool
    var entitlementsLoaded: Bool
    var quietGarden: Bool
    var calm: Bool
    var onboardingComplete: Bool
    var completedSessions: Int
    var now: Date
    var isNight: Bool
    var roundInProgress: Bool          // game.phase == .playing
    var aroundDailyBloom: Bool
    var lastRoundWasLoss: Bool
    var pendingCeremony: Bool
    var reduceMotion: Bool
    var voiceOverOrSwitchControl: Bool
    var accessibilityTextSize: Bool    // dynamicTypeSize.isAccessibilitySize
    var session: AdSessionState
    var ledger: AdLedger               // section 2.4
    var synced: SyncedAdCounters       // lastAdAt, adsToday/adsDay, rewardedToday/rewardedDay from PlayerProfile
    var interstitial: AdGate.Context   // today's interstitial rules, unchanged
    var perk: PerkContext              // water bank, whisper banked, wake tries (section 2)
}

enum AdDecision: Equatable { case no(AdBlock), yes(AdTreatment) }
enum AdBlock: Equatable { case ageOrPlus, notLoaded, onboarding, grace, puzzle, quiet, calm, night, daily, loss, ceremony,
                          consentPending, firstSession, background, link, gap, dayCap, sessionCap, formatCap, accessibility, notApplicable }

enum AdPolicy {
    static func decide(_ format: AdFormat, _ i: AdInputs, caps: AdCaps = .current) -> AdDecision
}
```

`decide` checks, in this order for every format: `treatment == .none` → `.no(.ageOrPlus)` first, before reading any other input (this makes the under-13 rule structural, not a per-format check); then `entitlementsLoaded`, `onboardingComplete`, `roundInProgress`, `quietVisit`, `pendingCeremony`; then the per-format rules below. `AppModel` builds `AdInputs` in one function (`adInputs()`, replacing the scattered checks in `showBanner`, `canOfferRewarded`, `adContext`), and every view and `AdsService` call goes through `decide`. `.yes(treatment)` carries the treatment so `AdsService.prepare` takes it instead of re-deriving it.

### 1.1 Global budgets and gaps (the frequency-cap change)

"Full-screen" = interstitial, app-open, rewarded. "Pushed" = interstitial, app-open (the app chooses the moment; rewarded is the player's tap).

| Cap | Value | Today | Store |
|---|---|---|---|
| Pushed ads per day | **6** (interstitial and app-open together) | 6, interstitial only | synced `adsToday` / `adsDay` (meaning widened, no new field) |
| Pushed ads per session | **3** | none | memory |
| Full-screen ads per day | **10** | none | ledger (`fullScreen`) + synced counts as a floor |
| Full-screen ads per session | **5** | none | memory |
| Min gap: any full-screen → next **pushed** | **180 s** | 180 s, interstitial → interstitial only | synced `lastAdAt` now set by every full-screen ad |
| Min gap: any full-screen → next **rewarded** | **30 s** | none | ledger `lastFullScreenAt` |
| Min gap: any full-screen → **app-open** | **30 min** | n/a | ledger |
| Rewarded per day (all perks) | **5** | 3 (water only) | synced `rewardedToday` / `rewardedDay` (meaning widened) |
| Rewarded per session | **3** | none | memory |
| Celebration quiet window | 5 s | 5 s | memory |

Interstitial's own rules stay exactly as today (every 3rd round, `oneMore` or `playSoonAfterEnough` only, never night, grace of 3 sessions or a level-up, never session 1). They now also obey the rows above. The resting card's "A short ad may play first." note is recomputed after any rewarded ad on that card (R2), so the note never lies.

A clock that moved backwards (`now < last`) counts as "gap not met"; if it is more than 24 h behind, the ledger resets that timestamp to `now` (no permanent lock-out).

### 1.2 App-open ad (return after a long break)

**Placement.** A full-screen app-open ad over the app's own **return cue** (below), on coming back after a long break. Never at first launch, never over onboarding, the age gate, UMP, ATT, the paywall, a sheet or a puzzle.

**Trigger.** Scene becomes `.active` (cold launch or warm resume) and `AdPolicy.decide(.appOpen, …)` is `.yes`. The app then shows the cue in the same frame (before any content can be used), starts `prepare` (no prompts can appear: 0.2), and calls `AppOpenAd.load(with:request:)`. If the ad arrives within **2.5 s** and the cue is still up and not skipped, it is presented over the cue; on dismiss the cue fades (0.3 s) to the screen the player left. If not, the cue lifts at 2.5 s and nothing is recorded. The ad is never preloaded at background time, because the eligibility window is 4 h and app-open ads expire 4 h after the request **[Google, fetched]**.

**Eligibility** (after 1.0's common checks):
- `completedSessions >= 3` (never the first launch or the first sessions; Google's own guidance is to wait until users have used the app a few times **[Google, fetched]**).
- `session.lastBackgroundAt` at least **4 h** ago (cold launches read `ledger.lastBackgroundAt`, written at every `.background`).
- `!session.roundWasInProgressAtBackground` (the player returns to their word, not an ad).
- `!session.launchedFromLink` (opened from a reminder, widget, URL, Shortcut or Siri: the player came for something specific).
- `consentResolved && attResolved`.
- `!calm && !quietGarden && !isNight && !pendingCeremony`.
- `ledger.appOpenToday < 1` (**max 1 per day**), `ledger.lastFullScreenAt` at least **30 min** ago, pushed and full-screen budgets (1.1) not used up.
- Teens: allowed, `.teen`. Adults: allowed.

**The cue (visible cue).** Mockup: `design-preview/admob/app-open-cue.svg`. Full screen, app background colour, still pot and sprout illustration (no animation, so it needs no Reduce Motion variant), title "Welcome back", line "to your garden", then the **"Ad" chip** and "A short ad, then your garden", three static dots, and a full-width secondary button **"Skip to my garden"** (min 52 pt). Dark mode uses the dark tokens. Dynamic Type: all text `Theme.font`, `fixedSize(horizontal: false, vertical: true)`, no line limit; the column is in a `ScrollView` so AX5 scrolls rather than clips; one layout at all sizes. VoiceOver: `accessibilityAddTraits(.isModal)`, reads "Welcome back to your garden. A short ad, then your garden." then the Skip button; Skip cancels the load and records nothing. Under VoiceOver the 2.5 s budget is the same (a missed ad just lifts the cue).

**Welcome back card.** If `checkWelcomeBack` wants to show, it shows after the cue lifts or the ad closes.

### 1.3 Collapsible banner (Garden only)

**Placement.** The Garden banner slot only (`GardenView` `safeAreaInset(edge: .bottom)`), anchored adaptive, bottom, `["collapsible": "bottom"]` extras **[Google, fetched]**. Home keeps the ordinary banner.

**Trigger.** The **first** banner request on the Garden screen in an ad session carries the collapsible extras, if eligible. Auto-refresh (console, 60 s) never requests a collapsible ad **[Google, fetched]**; the app never makes a second manual collapsible request in the same session.

**Eligibility** (after 1.0): the Garden banner itself is eligible (`showBanner`), `completedSessions >= 3`, `session.collapsibleShown < 1` (**max 1 per session**), `ledger.collapsibleToday < 2` (**max 2 per day**), `!calm && !quietGarden`, `!voiceOverOrSwitchControl` and `!accessibilityTextSize` (the expanded overlay covers more of the screen at large sizes and is harder to dismiss with assistive tech; these players get the ordinary banner, not no banner). Teens and adults alike.

**UI.** The banner frame takes `bannerView.adSize.size.height` (B4); never a fixed 60 pt. The expanded state is drawn by Google with its own collapse control; the app adds nothing over it. Below the banner the same caption row as Home: "Go ad-free · Report an ad" (secondary text, caption font, wraps). Collapsible ads are Google demand only; a normal banner can come back for the same request **[Google, fetched]**; `isCollapsible` is read in `bannerViewDidReceiveAd` and only then is `collapsibleShown` counted.

**Unit.** Separate unit `WordFlora_Banner_Garden_Collapsible` for reporting (the collapsible request uses it; refreshes and non-collapsible Garden loads use `WordFlora_Banner_Garden`).

### 1.4 Native ad (Garden Shed)

**Placement.** One native card at the **bottom of the Garden Shed**, after the Pots section, under a section header "SPONSORED" and the line "Ads help keep WordFlora free." Never in the plant grid, the Garden, Home, Plant detail, the puzzle or any child-visible surface (children never get here with an ad anyway: treatment `.none`). The Shed is a browse screen with no puzzle and no timer, and the card sits below all game content, so it cannot be mistaken for a tool or a pot.

**Trigger.** On Shed appear, if eligible and no ad is cached, `AdLoader` loads one native ad (`NativeAd`). A loaded ad is reused across Shed visits for up to **1 h** **[verify: Google's recommended native ad lifetime]**, then dropped. At most **1 load per 60 s**, at most **6 loads per day** (ledger `nativeLoads`).

**Eligibility** (after 1.0): `completedSessions >= 2`, `consentResolved` (native never triggers UMP), `nativeLoads` within cap. Quiet Garden: allowed (static, not a prompt). Calm mode or Reduce Motion: allowed, but if `nativeAd.mediaContent.hasVideoContent` the ad is not displayed and not retried this visit (there is no image-only switch in the loader **[verify]**; if the console unit offers an image-only setting, the owner sets it and this check becomes a backstop). Video always `VideoOptions.startMuted = true`.

**UI** (mockup `design-preview/admob/native-card.svg`). A UIKit `NativeAdView` wrapped in `UIViewRepresentable` (asset views must be registered with the `NativeAdView`):
- Card: flat muted fill (`#F1EEE6` light, `#22362A` dark), 1 pt border at 22 to 26% text colour, radius 12. Deliberately **not** the game's `Card` or tile style: no leaf art, no shed-points chip, no pot frame.
- Top row: **"Ad" badge** at top-left, 13 pt heavy text on a filled chip, at least 20 pt tall and wide (Google's minimum is 15 px **[Google, fetched]**), then the advertiser name. **AdChoices** at the top-right, placed by the SDK (`NativeAdViewAdOptions.preferredAdChoicesPosition = .topRightCorner`); nothing overlaps it.
- Icon (40 pt) + headline (headline font, semibold, `numberOfLines = 0`).
- `MediaView`, full width, 16:9, never less than 120 pt in either dimension (video will not serve below 120 pt **[Google, fetched]**), `contentMode = .scaleAspectFit` (no stretching or height-cropping **[Google, fetched]**).
- Body (`numberOfLines = 0`), optional star rating and store.
- Call to action: outlined button, full width, min 48 pt, label from `callToAction`. Never the game's filled primary style.
- Only asset views are clickable; the card background is not **[Google, fetched]**. No app control overlaps any asset.

Dynamic Type: every `UILabel` uses `UIFontMetrics` scaled fonts with `adjustsFontForContentSizeCategory = true`, `numberOfLines = 0`, so headline and body are never truncated (the policy forbids truncating below 25 and 90 characters). One layout at every size (vertical stack; icon and headline side by side with the headline wrapping). No `ViewThatFits`, no Dynamic Type cap. VoiceOver: the container is `accessibilityElements` in order Ad badge, advertiser, headline, body, call to action, AdChoices; the badge's label is "Advertisement"; the card's group label starts with "Advertisement." Dark mode: dynamic `UIColor`s from the theme.

### 1.5 Banners (Home and Garden, existing)

Unchanged except: B4 (real adaptive height on Garden), B6 (separate Garden unit), the collapsible first load (1.3), and banner eligibility now from `decide(.banner(slot))` with the same rules as `showBanner` today (from the second session, not during a weather visit on Home, not in `quietVisit`).

### 1.6 Interstitial (existing)

Unchanged rules plus the global budgets (1.1) and B5 (preload when the resting card says "A short ad may play first."). `recordAdShown` becomes `recordFullScreen(kind:)`, which updates `lastAdAt` for every full-screen kind, `adsToday` for pushed kinds, `rewardedToday` for rewarded, and the ledger.

### 1.7 Rewarded interstitial: not used (fits badly, nothing cut)

Google's rewarded interstitial plays at a transition after an intro screen the player must opt **out** of, not a tap they opt into **[verify: Google rewarded-interstitial policy wording]**. The owner's rule is "rewarded must be user-initiated". So all three perks use the standard **rewarded** format, which is what the owner asked for. No separate rewarded-interstitial unit.

---

## 2. Rewarded perks R1, R2, R3

Common rules: user-initiated tap on a row whose label says it plays a video; the reward is stated in the label; never required for progress (every perk has a free in-game way: water trickles back, the help ladder is free, both wake challenges are free and untimed); never offered during a puzzle, on a loss, in `quietVisit`, in the first session; caps in 1.1 plus the per-perk caps below. Paths:

```swift
enum PerkPath: Equatable { case hidden, free, ad(AdTreatment) }
static func path(_ perk: RewardedPerk, _ i: AdInputs, caps: AdCaps = .current) -> PerkPath
// treatment .none (under 13, unknown age, Plus)  -> .free  when the perk applies and the free cap is not used
// teen / adult, Quiet Garden                       -> .hidden
// teen / adult otherwise                           -> .ad(treatment) when decide(.rewarded(perk)) is .yes, else .hidden
```

So **Plus** gets every perk free (no video, no prompt to watch), and **under-13 / unknown age** get the same free perk (they never see an ad, and the feature exists for them). Free and ad caps are the same number, so the free path is "no video", not "more". Free paths never mention Plus to a child (`ParentalGate.isRequired`); for Plus a caption "Included with Plus".

### R1 Water from the Garden shelf

- **Where:** a card at the top of My Garden ("Your watering can is empty.") when `water == 0` and not Quiet Garden (Quiet Garden never uses drops). The existing Plant detail button stays; both share R1's cap.
- **Ad label:** "Watch a short video for 2 drops" with the play-rectangle icon. **Free label:** "Fill from the rain barrel".
- **Effect:** `water = min(waterBankCap, water + 2)` (today's `grantRewardedDrops`). Toast "2 drops are in your can".
- **Cap:** **3 a day** (today's number), ad or free.

### R2 Ask the garden for a hint

The brief's trigger ("stuck for 60 s in a round") would put an ad offer inside a puzzle in progress, which the hard rules forbid. **Safe version:** the offer is on the **resting card**, between rounds, and the reward is banked for the next word.
- **Where:** resting card, below the One more / That's enough buttons and above the Go ad-free row. Not shown if the last round was a loss, on the Daily Bloom card, or when a whisper is already banked (then the row reads "A whisper is waiting for your next word", no button).
- **Ad label:** "Ask the garden for a hint", sub-line "Short video · a whisper for your next word". **Free label:** same title, sub-line "A whisper for your next word".
- **Effect:** banks **one whisper** (max 1 banked). In the next non-Daily, non-tutorial round, `HelpLadder` gains a fourth rung `.whisper` after hint2, vowel and first letter: it reveals the most frequent unrevealed consonant, under the same rule as the other rungs (never the last unrevealed letter, so the player always makes the final guess). Costs no petal. The Help button shows a small leaf dot while a whisper is banked (VoiceOver hint "A whisper is waiting"). Never usable on the Daily Bloom (its result is shared, so it must stay equal for everyone). A whisper unused by the end of the day stays banked (it is one letter, not a currency).
- **Cap:** **2 a day**, ad or free.
- After the ad closes, `adWouldPlayOnOneMore` is recomputed (the 180 s gap now blocks the interstitial, so the "short ad" note disappears).

### R3 Wake a sleeping seed

There is no growth timer to skip: a seed is a plant whose petals ran out from no love (`LoveEngine`), woken by a free challenge. **Safe version:** a third, quieter way to wake, offered only after the player has tried once.
- **Where:** the wake sheet, as a third row below the two challenge tiles, only when `settings.wakeDreamsInARow >= 1` (one "still dreaming" try). Calm and Quiet Garden never have seeds (LoveEngine exempts them), so R3 never appears there.
- **Ad label:** "Wake with a short video", sub-line "The two challenges stay free". **Free label:** "Wake gently", sub-line "Once a day, after one try".
- **Effect:** the seed wakes exactly as a "woke" result (petals return with `PetalReturn`, `lastLovedAt = now`), `wakeDreamsInARow = 0`, `lastWakeResult = .woke`. It grants **no** album sticker, badge progress, water, shed points or soil, so it is a convenience, not a reward loop. Toast "<name> is awake".
- **Cap:** **1 a day**, ad or free.

### 2.4 Where the counters live: **no new stored field**

- Synced `PlayerProfile` fields, meaning widened, no schema change: `lastAdAt` (any full-screen ad), `adsToday`/`adsDay` (pushed ads), `rewardedToday`/`rewardedDay` (all rewarded ads). These sync across devices and survive reinstall, so they are the backstop.
- New **device-local** ledger in `UserDefaults` (App Group `SharedDefaults.store`, like Calm mode), key `adLedger`, a `Codable` JSON string read through `AppSettings`. Not SwiftData, not CloudKit, so **no CloudKit deploy**.

```swift
struct AdLedger: Codable, Equatable {
    var day = 0                              // yyyymmdd local; every count below resets when it changes
    var appOpen = 0, collapsible = 0, nativeLoads = 0, fullScreen = 0
    var adWater = 0, adHint = 0, adWake = 0
    var freeWater = 0, freeHint = 0, freeWake = 0
    var lastFullScreenAt: Date?, lastAppOpenAt: Date?, lastNativeLoadAt: Date?, lastBackgroundAt: Date?
    var whisperBanked = false
}
```

A reinstall or second device resets only the per-perk split, never the synced day caps. If any builder finds a field truly must sync, they stop and report: the plan's single CloudKit deploy is after G3.

---

## 3. Caps config: compile-time defaults plus a debug override

```swift
struct AdCaps: Equatable {
    var pushedPerDay = 6, pushedPerSession = 3, fullScreenPerDay = 10, fullScreenPerSession = 5
    var gapToPushed: TimeInterval = 180, gapToRewarded: TimeInterval = 30, gapToAppOpen: TimeInterval = 1800
    var appOpenPerDay = 1, appOpenMinBackground: TimeInterval = 4 * 3600, appOpenMinSessions = 3, appOpenLoadBudget: TimeInterval = 2.5
    var collapsiblePerSession = 1, collapsiblePerDay = 2, collapsibleMinSessions = 3
    var nativeMinSessions = 2, nativeReuse: TimeInterval = 3600, nativeLoadGap: TimeInterval = 60, nativeLoadsPerDay = 6
    var rewardedPerDay = 5, rewardedPerSession = 3, waterPerDay = 3, hintPerDay = 2, wakePerDay = 1, waterReward = 2
    var sessionBreak: TimeInterval = 1800
    // interstitial keeps AdGate.Context's frequency 3, minGapSeconds 180, maxPerDay 6, peakWindowSeconds 5
    static var current: AdCaps { … }   // Release: AdCaps(); DEBUG: AdCaps() with overrides applied
}
```

- **No remote config.** Release always uses the literals above (the `current` override path is `#if DEBUG` only, so it is compiled out).
- **Debug override:** launch argument `-adcaps "appOpenMinBackground=60,appOpenMinSessions=0,gapToPushed=5"` (key=value, unknown keys ignored with a console warning), and the preset `-uitest-adcaps-fast` (all gaps 1 to 5 s, sessions 0, caps unchanged so cap tests still bite). Also fix the stale comment `// remote-config tunables` in `AdGate.Context` to "compile-time defaults".
- Changing any Release number is an app update and an **[OWNER]** decision.

---

## 4. Test plan

### 4.1 Unit (pure rules, `WordFloraTests/AdPolicyTests.swift`)

1. **Table-driven treatment test:** every `AgeBand?` (`nil`, `.under13`, `.thirteenPlus`, `.eighteenPlus`) × `hasPlus` (false, true) → expected `AdTreatment` (`none, none, teen, adult` / all `none`).
2. **Never-for-under-13 (and unknown, and Plus), table-driven over formats:** for each of `banner(.home)`, `banner(.garden)`, `collapsible`, `interstitial(.oneMore)`, `interstitial(.playSoonAfterEnough)`, `appOpen`, `native`, `rewarded(.water/.hint/.wake)`, with **every other input set to its most permissive value**, `decide` returns `.no(.ageOrPlus)` for `nil`, `.under13` and any Plus. Then a seeded fuzz: 1,000 random `AdInputs` per band (fixed seed), assert the same. `path(perk)` returns `.free` or `.hidden`, never `.ad`.
3. **Per-band yes:** the permissive inputs give `.yes(.teen)` for 13 to 17 and `.yes(.adult)` for 18+ on every format; `mayAskTracking` true only for `.eighteenPlus`.
4. **App-open rows:** first launch (`completedSessions` 0, 1, 2) no; 3 yes; background 3 h 59 min no, 4 h yes; round in progress no; from link no; consent pending no; ATT not determined (adult) no; teen with ATT not determined yes (teens never get ATT, `attResolved` is true); Calm, Quiet, night, ceremony no; second of the day no; 29 min after any full-screen no; pushed budget used no.
5. **Collapsible rows:** session 2 no, 3 yes; second in session no; third in day no; Calm, Quiet, VoiceOver, AX size no (and the plain banner still yes).
6. **Native rows:** consent pending no; load gap and daily load cap; Calm + video → not shown.
7. **Budgets:** pushed 6/day shared by interstitial and app-open; 3 per session; full-screen 10/day; gaps 180 / 30 / 1800 s; backwards clock.
8. **Rewarded perks:** each perk's cap (3/2/1), global 5/day, 3/session; R1 needs water 0; R2 hidden after a loss, on Daily, when banked; R3 needs `wakeDreamsInARow >= 1`; Quiet Garden → `.hidden` for 13+, `.free` for Plus and under-13; HelpLadder `.whisper` rung order, never the last letter, ignored on Daily; R3 grants no badge/album/water.
9. **Interstitial regression:** all existing `AdGate` tests unchanged and green.
10. **Ledger:** day rollover resets counts; JSON round trip; corrupt JSON reads as empty; no change to `PlayerProfile` (a test asserts the SwiftData model's property list equals the G3 list).

### 4.2 Unit (service wiring, extends B1)

`AdsService` gains a `prepareCount` spy and `offline = true`. For `nil` and `.under13` (and Plus), calling `adBeforeNextRound`, `playTappedOnHome`, `prepareBannerIfAllowed`, `watchRewarded(.water/.hint/.wake)`, `showAppOpenIfEligible`, `loadNativeIfEligible`, `requestCollapsibleIfEligible` never increments `prepareCount`, never asks UMP or ATT. For `.thirteenPlus`, `prepare` receives `.teen` and `requestTrackingIfNeeded` is never reached. App-open and native never call `requestConsent` when consent is unresolved.

### 4.3 UI tests (Debug build, Google test ids, fake presenter)

UI tests keep `ads.offline` for layout; a new `-uitest-ads-fake` injects a `FakeAdPresenter` (shows a plain full-screen "TEST AD" view, closes on tap, can grant or withhold the reward) and a fake native asset set rendered by the same `NativeAdCardView` (not registered with Google, labelled "Advertisement"). New class `AdFormatsUITests` (and touched classes `RestCardUITests`, `GardenUITests`, Shed and wake tests):
- R1: Garden row appears at water 0 for an adult, watching grants 2 and shows the toast; absent for under-13 (free row instead), Plus (free row with "Included with Plus"), Quiet Garden adult (absent).
- R2: rest card row; after the fake ad the "short ad" note is gone; next round Help reveals a consonant after the three rungs; not on Daily; not after a loss.
- R3: wake sheet third row only after one "still dreaming".
- App-open: `-adcaps appOpenMinBackground=2` + background/foreground via `XCUIDevice.shared.press(.home)` and `app.activate()`; cue shows with "Ad" chip; Skip works; no cue with `-uitest-onboarding`, under-13, Calm, a round in progress.
- Native card in the Shed with fake assets: "Advertisement" read first; card below Pots.
- **Real Google test ids** (manual device run in Debug, plus one `AdFormatsLiveUITests` smoke run that is skipped in CI and on the build box under load): banner `ca-app-pub-3940256099942544/2934735716` (existing), adaptive banner `…/2435281174`, collapsible `…/8388050270`, interstitial `…/4411468910`, rewarded `…/1712485313` (all three R units in Debug), app open `…/5575463023`, native `…/3986624511` (collapsible, app open and native ids fetched today; others from the existing xcconfig; adaptive banner **[verify]**). Test app id `ca-app-pub-3940256099942544~1458002511`.

### 4.4 Audits

`performAccessibilityAudit` (light and dark, default and `accessibilityExtraExtraExtraLarge`) on: Garden with R1 row and banner, resting card with R2 row, wake sheet with R3 row, app-open cue, each toast, Shed with the fake native card. Dynamic Type check: no truncation (`label.isTruncated` false via the layout report pattern), no `ViewThatFits` (grep in the diff), no `.dynamicTypeSize(...` caps, no `lineLimit` on ad or prompt text. Copy: every new string through `CopySafety` (grade 2 for child-visible free rows).

### 4.5 Release checks

B3 extended: Release `.xcarchive` Info.plist has real ids for all nine unit keys and none of Google's `3940256099942544` ids; Debug has only test ids. Privacy report diff (B2) after the native and app-open code is in.

---

## 5. Privacy, label, UMP, ATT; ad units; console steps

### 5.1 Privacy and consent

- **No new data types** expected: app-open, native and collapsible are the same `GoogleMobileAds` SDK, already in the manifest and label **[inferred; confirm with the B2 privacy report]**. Label stays: Device ID, Advertising Data, Product Interaction, Coarse Location, Performance, Crash, Other Diagnostics; Third-Party Advertising; Tracking = yes (adults who allow ATT).
- `NSPrivacyTrackingDomains`: fill from the privacy report (B2).
- **UMP:** no new message; the GDPR and US-state messages cover all formats. App-open and native never trigger the form (0.2). The Settings "Privacy choices" row is unchanged.
- **ATT:** adults only, after UMP, only before a banner, interstitial or rewarded request; never shown by an app-open or native request.
- **Age rating / questionnaire:** "Advertising: yes" unchanged. No change to answers **[inferred]**.
- **Review notes (owner, D8):** add one paragraph: "Ads are shown only to players who say they are 13 or over and do not have Plus. 13 to 17 get non-personalised, G-rated ads and no tracking prompt. Under 13 or no age answer: the ad SDK never starts. Rewarded videos are optional and every reward also exists without an ad. A return ad may appear at most once a day after 4 hours away, behind a 'Skip to my garden' screen."

### 5.2 Ad unit ids the owner creates and sends

| Unit name (AdMob) | Format | xcconfig key / Info.plist key | Status |
|---|---|---|---|
| `WordFlora_Banner_Home` | Banner | `ADMOB_BANNER_ID` / `AdMobBannerUnitID` | exists |
| `WordFlora_Banner_Garden` | Banner | `ADMOB_BANNER_GARDEN_ID` / `AdMobBannerGardenUnitID` | new (B6) |
| `WordFlora_Banner_Garden_Collapsible` | Banner (app adds collapsible extras) | `ADMOB_BANNER_GARDEN_COLLAPSIBLE_ID` / `AdMobBannerGardenCollapsibleUnitID` | new |
| `WordFlora_Interstitial_RoundBreak` | Interstitial | `ADMOB_INTERSTITIAL_ID` / `AdMobInterstitialUnitID` | exists |
| `WordFlora_Rewarded_Water` | Rewarded, reward 2 "Drops" | `ADMOB_REWARDED_ID` / `AdMobRewardedUnitID` | exists |
| `WordFlora_Rewarded_Hint` | Rewarded, reward 1 "Whisper" | `ADMOB_REWARDED_HINT_ID` / `AdMobRewardedHintUnitID` | new |
| `WordFlora_Rewarded_Wake` | Rewarded, reward 1 "Wake" | `ADMOB_REWARDED_WAKE_ID` / `AdMobRewardedWakeUnitID` | new |
| `WordFlora_AppOpen_Return` | App open | `ADMOB_APPOPEN_ID` / `AdMobAppOpenUnitID` | new |
| `WordFlora_Native_Shed` | Native advanced | `ADMOB_NATIVE_ID` / `AdMobNativeUnitID` | new |

Each new key falls back to an existing id if empty (Garden → Home banner; hint/wake → water rewarded), so a missing id never breaks a build. Real ids go in `Config/Ads.local.xcconfig` with `[config=Release]` as today. The app ignores the console's reward amount (it uses its own constants; B7).

### 5.3 AdMob console steps (owner, about 1.5 h; update `owner-setup-steps.md` C3 and C10 in G4)

1. Create the six new units above (C3). Copy ids to the builder.
2. App open unit: no special settings. Native unit: if an option to limit to image ads appears, leave both image and video on (the app filters video in Calm) **[verify in UI]**.
3. **Frequency capping as a backstop** in each unit's advanced settings **[verify in UI]**: App open 1 impression per user per day; Interstitial 6 per day; Rewarded none; Banners none. The app's caps stay the real rule.
4. Mediation groups, AdMob Network only, one per format: Banner, Interstitial, Rewarded, **App open**, **Native** (ready for Unity in 1.1).
5. Banner refresh 60 s on all three banner units.
6. Blocking controls: sensitive categories blocked (as C6), app max content rating G. Native ads use the same controls. Ad review center weekly for the first month, native included.
7. Privacy & messaging: no change (AdMob is alone). Test devices registered.
8. app-ads.txt unchanged (one Google line).
9. Reports: add the new units to the saved ad-unit report; watch app-open show rate and rewarded completion per unit.

---

## 6. Hours, gates, schedule, options

### 6.1 Builder-hours per item

| Item | Hours |
|---|---|
| G4 hardening B1 to B8 (as `ad-network-alternatives.md` 1.1) | 4.0 |
| `AdPolicy` core, `AdInputs` builder, `AdCaps` + debug override, `AdLedger`, `recordFullScreen`, budgets, unit tables 4.1 / 4.2 | 5.0 |
| R1 Garden row + rain barrel free path | 2.0 |
| R2 rest-card row, whisper bank, `HelpLadder.whisper`, free path | 4.0 |
| R3 wake-sheet row, gentle wake, free path | 2.5 |
| Shared prompt row, toast component, three rewarded unit keys, audits for these | 1.5 |
| Touched UI classes (rest card, garden, wake) under the lock | 1.0 |
| **Gate G4a subtotal** | **20.0** |
| App-open: lifecycle (`lastBackgroundAt`, link flag, round flag), cue view, load with 2.5 s budget, tests | 5.0 |
| Collapsible Garden banner (extras, `isCollapsible`, counters, B4 height already done) | 2.0 |
| Native: `NativeAdCardView` (UIKit, scaled fonts), loader + reuse, Calm video filter, fake assets, audits | 6.0 |
| Privacy report re-diff, owner-steps C3/C10 update, `AdFormatsUITests` run | 2.0 |
| **Gate G4b subtotal** | **15.0** |
| **Total** | **35.0** (G4 was planned at 4 h after AppLovin was dropped, 14 h before) |

### 6.2 Sequencing (lock-serial, after G3 and the owner's CloudKit deploy)

- **G4a: AdMob hardening, ad policy and rewarded** (20 h, one builder). Ships the foundations everything else reads. Exit: never-for-under-13 table and fuzz green, B1 spy green, R1 to R3 UI green, no `Models/` diff, Release bundle has no test ids.
- **G4b: app-open, collapsible, native** (15 h, same or next builder, starts when G4a merges). Exit: app-open rows green, cue audit green at AX5 light/dark, native audit green, privacy report matches the label.
- Then G5 and G6 as planned. Both G4 gates add **no stored field**, so the single CloudKit deploy after G3 stands.

### 6.3 Schedule impact

At about 14 builder-hours a calendar day (status review), 35 h is about 2.5 days of machine time against the 4 h G4 (about +2.2 days) or the old 14 h G4 (about +1.5 days). The status review gave Thu 11-19 at most one day of slack with the 14 h G4. So: G4a about Sat 11-14 evening, G4b about Mon 11-16 morning, G5 to Tue 11-17, G6 to Thu 11-19, owner checks, **submit about Fri 11-20 to Sat 11-21**. **Thu 11-19 is likely missed by 1 to 2 days; Mon 11-23 holds with about 2 days of slack.** If the G5 art fallback fires (Fri 11-13), about 20 h come back and Thu 11-19 is reachable again.

### 6.4 Options to protect the date (need owner approval; none applied)

| Option | Saves | Revenue given up (est., 10,000 players) | Note |
|---|---|---|---|
| O1 Native card to 1.1 | 6 h | $30 to $60/mo | Biggest single item; least user-facing |
| O2 App-open to 1.1 | 5 h | $50 to $90/mo | Highest review and calm risk of the set |
| O3 Collapsible to 1.1 | 2 h | $10 to $25/mo | |
| O4 R3 wake to 1.1 | 2.5 h | $5 to $15/mo | Smallest audience (seeds are rare) |
| O5 Ship G4b code switched off by a compile-time flag if its UI tests are not green by G6 start | 0 h planned, protects G6 | that format's revenue until 1.1 | Flag is compile-time, not remote |
| O6 Run G4b after G5 instead of before | 0 h | none | Lets the G5 art go/no-go decide first |

---

## 7. Revenue and UX risks, with mitigations

**Estimated uplift** (base case of `revenue-compensation.md`, about 1,470 ad-eligible free daily players at 10,000 monthly): R1 to R3 +$60 to $120/mo; app-open +$50 to $90 (about 0.15 to 0.2 a day per daily player at about $8 eCPM); native +$30 to $60; collapsible +$10 to $25. Total about **+$150 to $295/mo** on today's $665 of 13+ ads. These are estimates, not benchmarks for a calm word game; measure as in `ad-network-alternatives.md` 1.4.

| Risk | Mitigation |
|---|---|
| **Calm tone** broken by a return ad | Once a day at most, only after 4 h away, never in Calm, Quiet, at night, after a link, or over a word in progress; a branded cue with Skip; 2.5 s budget then the garden. Watch D7 retention ad-exposed vs not; if it moves more than 2 points, set `appOpenPerDay` to 0 in the next update first |
| **Churn from over-monetising** | Pushed ads still 6 a day total (app-open shares the interstitial cap, it does not add to it); 3 pushed per session; rewarded is opt-in and Plus gets every perk free, which makes Plus more valuable rather than ads more frequent |
| **Pay-to-win** | Single-player, no leaderboards; whisper never on the Daily Bloom (shared); wake by video grants no badges or stickers; caps equal for ad and free paths |
| **Children** | Treatment `.none` checked first in `decide`; table and fuzz tests; children get every perk free and never see a video word or a Plus price |
| **Collapsible covering play** | Garden only (no puzzle there), once per session, twice a day, not in Calm, Quiet, VoiceOver, Switch Control or AX sizes; Google's own collapse control |
| **Native mistaken for content** | Different card style, "SPONSORED" header, "Ad" badge, AdChoices, below all game content, only asset views tappable |
| **Invalid traffic / account ban** | Test ids in Debug only; test devices; no ad near the letter keys; no app control overlapping native assets; never tap own ads |
| **Low fill on new units** | Fallback ids when a key is empty; an ad that is not loaded never makes anyone wait (interstitial today, app-open 2.5 s budget, rewarded row hidden when no ad can load **after** one failed load this session) |

### Apple and Google limits (facts) and what they mean here

- **Apple 2.5.18** **[Apple guideline]**: ads only in the main app binary (not widgets, notifications or extensions); appropriate to the age rating; the user can see the information used to target them (AdChoices on native, Google's info on full-screen); interstitial or blocking ads must be clearly labelled and have easy, visible close or skip buttons. → Widget stays ad-free; G rating for everyone; native keeps AdChoices; the app-open cue has its own Skip; the collapsible overlay keeps Google's collapse control.
- **Apple 1.3 and 5.1.4 (Kids)** **[Apple guideline]**: apps in the Kids Category may not include third-party advertising or analytics, and apps for kids must take extra care with data. → WordFlora is not in the Kids Category; under-13 and unknown ages never start the SDK, so no child data reaches Google. Do not move the app into the Kids Category while any format ships.
- **Apple 5.1.1 / 5.1.2 (ATT)** **[Apple guideline]**: tracking needs ATT permission and no incentive for allowing it. → Rewards never depend on the ATT answer; teens never see ATT.
- **Google app open** **[Google, fetched]**: ads expire 4 h after request; show from a loading screen, not after the player has reached main content; wait until the app has been used a few times. → Fresh load on return with the cue as the loading screen; no preload across the 4 h window; `appOpenMinSessions = 3`. A cue held on purpose only to wait for an ad is a gray area **[inferred]**; the 2.5 s cap and the Skip button keep it honest.
- **Google collapsible** **[Google, fetched]**: Google demand only; auto-refresh never requests collapsible; a non-collapsible ad can come back. → Count only when `isCollapsible` is true.
- **Google native policy** **[Google, fetched]**: "Ad"/"Sponsored" badge at least 15 px; AdChoices visible; headline and CTA required; headline not truncated below 25 characters, body below 90; MediaView at least 120 × 120 pt for video; no stretching or height-cropping; background not clickable; no overlapping app elements; clearly distinguishable from content. → Section 1.4 meets each line.
- **Requested behaviour a rule forbids:** R2's original "stuck for 60 s in a round" trigger conflicts with the owner's own "never during a puzzle in progress" (not a Google or Apple line); moved to the resting card. Rewarded interstitial conflicts with "user-initiated" (1.7). Nothing else requested is forbidden by Google or Apple as far as I could check.

---

## Summary (about 200 words)

AdMob alone ships every requested format in 1.0, with no new stored field and no CloudKit change. One pure function, `AdPolicy.decide(format, inputs)`, checks the age-and-Plus treatment first: under 13, unknown age and Plus get nothing, 13 to 17 get `.teen` non-personalised G ads with no ATT, adults get UMP then ATT. Table and fuzz tests prove this for every format. App-open plays at most once a day, only after 4 hours away and from the third session on, behind a calm "Welcome back" cue with an Ad chip and a Skip button. It never plays over onboarding, consent, a word in progress, a link launch, Calm, Quiet Garden or night. The collapsible banner is Garden-only, once a session. The native card sits at the bottom of the Shed under "Sponsored", per Google's native policy. Rewarded perks: R1 2 drops (3 a day), R2 a banked hint from the resting card (2 a day, never Daily), R3 wake a seed after one try (1 a day). Plus and children get each perk free. Pushed ads still total 6 a day. The work is 35 builder-hours in G4a (20 h) and G4b (15 h). Thu 11-19 likely slips 1 to 2 days, and Mon 11-23 holds. Options O1 to O6 are for the owner.

## Review rulings (lead, 2026-11-07, from docs/pm/admob-full-spec-review.md)
Builders must apply these before and while building. They override earlier numbers in this file.
- Must-fix H1: app-open uses a new entry point `startIfConsentAlreadyResolved` that never presents UMP; H2: UMP request sets the under-age-of-consent flag for 13-17 (verify property name in the SDK); H3: cold launch from a link/widget waits for `.onOpenURL`/scene routing before the cue; H5: release cached ads when treatment becomes `.none`; H6: the fake presenter and `-adcaps` override compile out of Release; H7: free paths (Plus, under-13, unknown) are never blocked by session/full-screen budgets.
- R2 title must say "video" in the title (not only the 13 pt sub-line); fix its contrast to 4.5:1. Native card: CTA Dynamic Type safe, AdChoices inset, MediaView in VoiceOver order.
- Caps (lighter, protects retention; owner can raise them later): pushed full-screen ads per session 2 (was 3), all full-screen per session 4 (was 5), full-screen per day 8 (was 10), app-open to the next pushed ad 600 s (was 180). Other numbers unchanged.
- H4 (app-open on cold launch): option (b): cache the last treatment in the ledger, show the cue, present the ad only after entitlements confirm. Plus owners never see an ad.
- Quiet Garden and R2: one rule for everyone: the R2 prompt is hidden in Quiet Garden for all ages and Plus (no asymmetry).
- Order: G3, CloudKit deploy, G4a, G5, G4b, G6 (G4b after G5). G4a spec writing proceeds lock-free during G3. Options O1-O6 stay unapplied; ranking if the date slips (needs owner approval): O6 (already the order), O5, O1 native, O4 R3, O3 collapsible, O2 app-open last.
- Revenue expectation: $90-205 a month at 10,000 players (review estimate), not $150-295.

## Review rulings 2 (lead, 2026-11-07, from docs/pm/weak-spots-review-2.md)
- R2 is hidden while the "A short ad may play first" note shows on the resting card (never stack two ad prompts). R2 title: "Watch a short video for a hint". Hide the whisper dot during the Daily Bloom.
- Section 1.1's cap numbers are stale: the Review rulings numbers above win (pushed 2/session, all full-screen 4/session and 8/day, app-open to next pushed 600 s). Builders update 1.1 to match.
- Review notes (D8) must say ads begin from session 3 and that under-13/unknown ages never see any.

## Review rulings 3: ad unit ids (lead, 2026-11-07, from docs/pm/admob-ad-ids-review.md)
Supersedes section 5.2 and 5.3 counts. Existing real units are reused; the owner creates no more units.
- Garden banner reuses the Home banner unit (no separate Garden unit). Build fallback `ADMOB_BANNER_GARDEN_ID = $(ADMOB_BANNER_ID)` in Config/Ads.xcconfig; runtime chain: Garden -> Home; collapsible -> Garden -> Home; hint and wake -> water rewarded; app open and native: empty id disables that format (never a cross-format fallback).
- Add Debug test ids to Config/Ads.xcconfig for the five new keys (collapsible banner, hint, wake, app open, native) using Google's published test ids per format; Info.plist and `AdsService.Unit` get the new keys.
- Release safety: add a build phase that fails a Release build if the local ads file is missing or any Release id equals a Google test id; Garden == Home is allowed.
- G4a unit tests (5): fallback chain, no cross-format fallback, id shape regex, Debug-only test ids / Release none, format disabled when id empty.
- Fix spec inconsistencies (six new units -> five existing; one BannerView has one unit so the collapsible handoff swaps views; remove stale "remote config" wording in AdGate.Context and owner-setup C3; C3/C10 unit counts).
- Owner console checklist (5): confirm formats (Home banner = Banner, collapsible = Banner, app open = App open, native = Native advanced with image+video on, rewarded units = Rewarded not Rewarded interstitial); no app-level child tag; refresh 60 s on Home and off on the collapsible unit; frequency caps and AdMob-only mediation groups.

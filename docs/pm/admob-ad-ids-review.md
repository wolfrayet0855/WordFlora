# AdMob ad unit ids: mapping review for G4a / G4b

Reviewed 2026-11-07 against `docs/pm/admob-full-spec.md` (5.2 and the Review rulings), `Config/Ads.xcconfig`, `Config/Ads.local.xcconfig` (git-ignored; ids masked here to their last 4 digits), `WordFlora/Ads/AdsService.swift`, `WordFlora/Info.plist`, `docs/setup/owner-setup-steps.md` section C, `docs/research/ad-network-alternatives.md` 1.1 (B1 to B8). Owner direction: **reuse the ids that exist; create no more units.** Google pages fetched today are tagged **[Google, fetched]**; anything not fetched is **[verify]**.

Real ids are never written in this file. Ids are named by xcconfig key and last 4 digits.

---

## 1. Final mapping (only ids that exist)

| Spec unit (5.2) | Format needed | xcconfig key | Info.plist key | Used in app | Real id (Release) | Debug (Google test id) | Fallback when empty |
|---|---|---|---|---|---|---|---|
| App | App id (tilde) | `ADMOB_APP_ID` | `GADApplicationIdentifier` | SDK start | exists, `…8867` | `~1458002511` (in xcconfig today) | none: SDK will not start; nothing to fall back to |
| `WordFlora_Banner_Home` | Banner | `ADMOB_BANNER_ID` | `AdMobBannerUnitID` | Home banner (`AdBannerView`) | exists, `…4195` | `/2934735716` (fixed-size banner test id; adaptive test id is `/2435281174` **[Google, fetched]**, either serves test ads) | none (base unit) |
| `WordFlora_Banner_Garden` (B6) | Banner | `ADMOB_BANNER_GARDEN_ID` | `AdMobBannerGardenUnitID` | Garden banner slot: refreshes and every non-collapsible load | **REUSE Home** `…4195`. Not created, by owner decision | `$(ADMOB_BANNER_ID)` | → Home banner id |
| `WordFlora_Banner_Garden_Collapsible` | Banner (collapsible is a request extra, not a unit type) **[Google, fetched]** | `ADMOB_BANNER_GARDEN_COLLAPSIBLE_ID` | `AdMobBannerGardenCollapsibleUnitID` | First Garden banner request per ad session, with `["collapsible": "bottom"]` | new, confirmed, `…3355` | `/8388050270` (from the collapsible guide; not on the test-ads page **[verify]**) | → Garden → Home (same format chain) |
| `WordFlora_Interstitial_RoundBreak` | Interstitial | `ADMOB_INTERSTITIAL_ID` | `AdMobInterstitialUnitID` | Round-break interstitial | exists, `…2484` | `/4411468910` | none (base unit) |
| `WordFlora_Rewarded_Water` (R1) | Rewarded | `ADMOB_REWARDED_ID` | `AdMobRewardedUnitID` | Garden "watering can is empty" card + Plant detail button | exists, `…6377` | `/1712485313` | none (base unit) |
| `WordFlora_Rewarded_Hint` (R2) | Rewarded | `ADMOB_REWARDED_HINT_ID` | `AdMobRewardedHintUnitID` | Resting card hint row | new, confirmed, `…5025` | `/1712485313` | → Water rewarded id |
| `WordFlora_Rewarded_Wake` (R3) | Rewarded | `ADMOB_REWARDED_WAKE_ID` | `AdMobRewardedWakeUnitID` | Wake sheet third row | new, confirmed, `…9017` | `/1712485313` | → Water rewarded id |
| `WordFlora_AppOpen_Return` | App open | `ADMOB_APPOPEN_ID` | `AdMobAppOpenUnitID` | Return cue after 4 h away | new, confirmed, `…2335` | `/5575463023` **[Google, fetched]** | **none: format disabled** (`decide(.appOpen)` → `.no(.notApplicable)`). Never fall back to an interstitial id: a unit only receives ad types of its own format **[Google, fetched]**, so the load would fail every time and count as a wasted request |
| `WordFlora_Native_Shed` | Native advanced | `ADMOB_NATIVE_ID` | `AdMobNativeUnitID` | Shed card below Pots | new, confirmed, `…9371` | `/3986624511` **[Google, fetched]** | **none: format disabled**, same reason |

Today's state: `Info.plist` and `AdsService.Unit` know only the first three unit keys plus the app id. `Ads.local.xcconfig` already holds the eight real unit keys above (no `ADMOB_BANNER_GARDEN_ID` line, which is correct for reuse). `Ads.xcconfig` holds test ids for four keys only; the five new keys have no Debug value yet.

### 1.1 Garden banner sharing the Home id

- **Policy.** No AdMob policy or help page I could find restricts an ad unit to one screen. The help centre defines an ad unit as a container "you place in your apps" and its id as what "identif[ies] ad requests from the ad unit" **[Google, fetched]**; the collapsible guide speaks of turning collapsible on "for existing banner placements" **[Google, fetched]**; AdMob's Placements (beta) feature exists precisely to split reporting "without the need for additional ad units" **[verify: Placements help page, not fetched today]**. Google's SDK team replies on the developer forum treat banners on several screens as normal. AdMob policy limits are about *how many ads are on screen and where* (one banner per screen, not beside controls), which the app already obeys, not about which unit id each screen uses. Verdict: **allowed; the only loss is combined Home + Garden reporting** (eCPM and show rate per screen, which `ad-network-alternatives.md` 1.4 wanted). If the owner later wants the split, AdMob Placements (beta) or a Garden unit can be added without an app update only if the key is already plumbed, which is why the key stays in the app with the fallback.
- **Build-time fallback that can never be empty.** In `Config/Ads.xcconfig` define `ADMOB_BANNER_GARDEN_ID = $(ADMOB_BANNER_ID)`. In Debug that resolves to the banner test id; in Release the `[config=Release]` Home line in the local file wins the reference, so the Garden key carries the real Home id with no line in the local file. Keep the runtime fallback in `AdsService.unitID` as well (belt and braces for a hand-edited local file).

### 1.2 Runtime fallback rule (for the G4a builder)

`AdsService.unitID(_:)` returns `""` today when a key is missing. Replace with a fallback chain, **same format only**:

```
bannerGarden            -> banner
bannerGardenCollapsible -> bannerGarden -> banner
rewardedHint, rewardedWake -> rewarded
appOpen, native         -> "" (and AdPolicy.decide returns .no(.notApplicable) when the id is empty)
```

Make the lookup testable: `unitID(_ unit:, info: [String: Any])` (or keep the `Bundle` parameter and inject a test bundle) so a unit test can pass an empty or missing key and assert the chain.

---

## 2. Format check: does each existing unit match its spec use?

| Key (last 4) | Spec use | Format the unit must be in the console | Matches? |
|---|---|---|---|
| `ADMOB_REWARDED_ID` `…6377` | R1 water, standard rewarded (`RewardedAd.load`) | Rewarded (not Rewarded interstitial) | yes if created as C3 says ("Rewarded"); the console reward amount (2 / "Water") is ignored by the app (B7) |
| `ADMOB_REWARDED_HINT_ID` `…5025`, `ADMOB_REWARDED_WAKE_ID` `…9017` | R2, R3 via `RewardedAd.load` | Rewarded | owner confirmed; the local file's comment still says "mapping inferred from the owner's list; confirm in the console", so the last-4 check below closes that |
| `ADMOB_BANNER_GARDEN_COLLAPSIBLE_ID` `…3355` | Anchored adaptive banner + collapsible extra | Banner (there is no "collapsible" unit type; collapsible is a per-request extra and Google demand only) **[Google, fetched]** | yes if Banner |
| `ADMOB_BANNER_ID` `…4195` | Home + Garden anchored adaptive | Banner | yes |
| `ADMOB_INTERSTITIAL_ID` `…2484` | Round break | Interstitial | yes |
| `ADMOB_APPOPEN_ID` `…2335` | `AppOpenAd.load` | App open | must be App open; a Banner or Interstitial unit will never fill an app-open request |
| `ADMOB_NATIVE_ID` `…9371` | `AdLoader` with native ad type | Native advanced | must be Native advanced |

### Owner console checklist (5 items, about 15 minutes)

1. **Formats by last 4 digits.** Apps > WordFlora > Ad units: confirm the Format column reads Banner for `…4195` and `…3355`; Interstitial for `…2484`; Rewarded (not Rewarded interstitial) for `…6377`, `…5025`, `…9017`; App open for `…2335`; Native advanced for `…9371`. Confirm the app id ends `…8867` and contains a tilde.
2. **Native unit ad types.** Open `…9371`: leave both image and video ad types on (the app filters video in Calm and starts video muted). No image-only restriction.
3. **App-level child tag is off.** App settings: the app must not be tagged child-directed at the app level (C6 already says so). Google's app-open help notes that apps under Play's Families policy are not eligible for app open ads **[Google, fetched; Android wording, but an app-level child tag would also starve app-open fill on iOS, verify]**. Age handling stays per request in code.
4. **Auto-refresh.** 60 s on `…4195` (Home, and now Garden). On the collapsible unit `…3355` switch auto-refresh **off**: Google never serves a collapsible ad on a refresh **[Google, fetched]**, so refreshes on that unit would only muddy its "collapsible" report; after the first collapsible load the app replaces the view with a plain banner on the Home id (section 4, point 3).
5. **Frequency caps and mediation groups** per spec 5.3: App open 1 per user per day, Interstitial 6 per day, none on Rewarded or Banner; one AdMob-only mediation group per format (Banner, Interstitial, Rewarded, App open, Native). Register the owner's device as a test device before any Release-id run.

---

## 3. Risks

### 3.1 Test ids in Debug vs real ids in Release

- Wiring is right in principle: `Ads.xcconfig` (test ids, unconditional) `#include?`s `Ads.local.xcconfig` whose lines are all `[config=Release]`. Both the Debug and Release configurations of the app target use `Ads.xcconfig` as base (`project.pbxproj` lines 1802 and 1837). The widget target has no ad keys, correctly.
- **`#include?` is optional.** A Release build on a machine without the local file (CI, a fresh clone, a builder's worktree) silently ships Google's test ids: zero revenue and Google may flag the app. Mitigation: a Release-only build phase that greps the built `Info.plist` for `3940256099942544` and fails the build; plus the B3 archive check. Note the `.claude/worktrees/*` copies of the project will not contain the git-ignored local file, so a builder archiving from a worktree gets test ids.
- `[config=Release]` matches only a configuration literally named `Release`. There are only Debug and Release today; do not add a third configuration (e.g. "TestFlight") without duplicating the lines.
- Debug on a real device: test ids, so no invalid traffic. The one manual Release-id device run (owner-setup C "how to test") must be on a registered test device.

### 3.2 Info.plist / xcconfig substitution for the new keys

- Five new keys plus `AdMobBannerGardenUnitID` must be **added to `WordFlora/Info.plist`** as `$(ADMOB_…)` entries; today only three unit keys and the app id exist. A key present in the local file but absent from `Info.plist` is simply never read: the format silently serves nothing in Release (no error).
- A key present in `Info.plist` but undefined in **both** xcconfigs resolves to an empty string at build time. Today `unitID` would hand `""` to the SDK (a logged load error, no crash, no ad). Hence the fallback chain in 1.2 and a Debug value for every key in `Ads.xcconfig`.
- Order of work: `Ads.xcconfig` (Debug test ids for all nine keys, Garden = `$(ADMOB_BANNER_ID)`), `Info.plist` (nine keys), `AdsService.Unit` (nine cases + chain). G4a lands rewarded hint/wake and Garden; G4b lands collapsible, app open, native. Add all nine keys to `Ads.xcconfig` and `Info.plist` in **G4a** so G4b touches only Swift.

### 3.3 Keys missing per configuration (as of today)

| Key | Debug (`Ads.xcconfig`) | Release (`Ads.local.xcconfig`) | `Info.plist` | `AdsService.Unit` |
|---|---|---|---|---|
| `ADMOB_APP_ID` | yes | yes | yes | n/a |
| `ADMOB_BANNER_ID` | yes | yes | yes | yes |
| `ADMOB_INTERSTITIAL_ID` | yes | yes | yes | yes |
| `ADMOB_REWARDED_ID` | yes | yes | yes | yes |
| `ADMOB_BANNER_GARDEN_ID` | **missing** (use `$(ADMOB_BANNER_ID)`) | intentionally absent (reuse) | **missing** | **missing** |
| `ADMOB_BANNER_GARDEN_COLLAPSIBLE_ID` | **missing** | yes | **missing** | **missing** |
| `ADMOB_REWARDED_HINT_ID` | **missing** | yes | **missing** | **missing** |
| `ADMOB_REWARDED_WAKE_ID` | **missing** | yes | **missing** | **missing** |
| `ADMOB_APPOPEN_ID` | **missing** | yes | **missing** | **missing** |
| `ADMOB_NATIVE_ID` | **missing** | yes | **missing** | **missing** |

### 3.4 Unit tests the G4a builder needs (`WordFloraTests/AdUnitIDTests.swift`, pure, no SDK)

1. **Fallback chain:** for an injected info dictionary with each new key missing, and again with each set to `""`: Garden → Home; collapsible → Garden → Home (and collapsible → Home when Garden is also empty); hint/wake → water; appOpen and native → `""`.
2. **No cross-format fallback:** appOpen and native never return a banner, interstitial or rewarded id for any combination of missing keys.
3. **Shape of what the bundle actually carries:** every `AdMob…UnitID` in the running test bundle's host `Info.plist` matches `^ca-app-pub-\d{16}/\d{10}$` and `GADApplicationIdentifier` matches `^ca-app-pub-\d{16}~\d{10}$` (tilde, not slash: B3). This catches a missing Info.plist entry (the key would be absent) and an unresolved `$(…)`.
4. **Debug uses only test ids:** under `#if DEBUG`, every id contains `3940256099942544`; under `#else`, none does and `AdMobBannerGardenUnitID == AdMobBannerUnitID` (the reuse decision, asserted). This is the automated half of B3 and of spec 4.5, which should read "nine keys, real, Garden equal to Home" rather than "nine real unit ids".
5. **Policy off when a format has no id:** `AdPolicy.decide(.appOpen, …)` and `decide(.native, …)` return `.no(.notApplicable)` with permissive inputs when the unit id is empty, and `.yes` when it is set (so a missing id can never make `AdsService` call `load` with `""`). Extend the B1 spy test: with an empty app-open id, `showAppOpenIfEligible` never increments the load spy.

---

## 4. Other inconsistencies in the ad plan

1. **Spec 5.2 / 5.3 still say six new units and "all three banner units".** With the owner's reuse decision: five new units, two banner units. Update 5.2's status column (Garden → "reuse Home id"), 5.3 step 1 ("Create the six new units" → "five, created 2026-11-07") and step 5 (refresh on two banner units, off on the collapsible unit).
2. **Spec 1.3 and B6** say Garden refreshes and non-collapsible loads use `WordFlora_Banner_Garden`; they now use the Home id through `ADMOB_BANNER_GARDEN_ID`. `ad-network-alternatives.md` 1.4 ("Home vs Garden banner eCPM") becomes a 1.1 measurement unless AdMob Placements (beta) is used for the split.
3. **One `BannerView` has one unit id.** Spec 1.3 wants the first Garden request on the collapsible unit and the refreshes on the Garden unit; the SDK's auto-refresh refreshes the same `BannerView`, so it would refresh on the collapsible unit. G4b must either (a) create the Garden `BannerView` with the collapsible id and, on `bannerViewDidReceiveAd` (collapsible or not) or dismissal, swap in a second `BannerView` on the Home id, or (b) accept refreshes on the collapsible unit (plain banners, muddier report). Checklist item 4 assumes (a). The spec should state which.
4. **Spec 4.5 and B3** say "three real unit ids" / "nine unit keys with real ids". Correct wording: eight distinct real unit ids plus the app id; `Garden == Home`.
5. **Stale "remote config" wording** persists: `AdGate.Context` comment `// remote-config tunables` (spec 3 already asks to change it) and owner-setup C3 "Leave frequency capping to the app/remote config". There is no remote config; caps are compile-time.
6. **owner-setup-steps C3, C10 and "send back"** still list 3 units, "Mediation: not needed", and three unit ids. Spec 5.3 schedules this update for G4 (B8); it should also add the five new unit names and say Garden reuses Home.
7. **Debug banner test id** is the fixed-size banner id while the app requests an anchored adaptive size; Google lists `/2435281174` for adaptive **[Google, fetched]**. Harmless (test ads fill either), but switching avoids a surprise when checking banner heights (B4).
8. **Collapsible test id `/8388050270`** appears in the collapsible guide but not on the test-ads page; keep spec 4.3's **[verify]** and confirm on the device that it returns a collapsible test ad.
9. **Native "1 h reuse"**: the review recommended 30 min; Google's native guide says ads "expire after an hour" and to clear a cache every hour **[Google, fetched]**, so 1 h is the ceiling, 30 min is safe. Not an id issue; noted because the spec marks it [verify] and it is now resolved.
10. **Rewarded console reward item**: C3 says Item "Water" while spec 5.2 says "Drops". Cosmetic: the app ignores the console amount (B7). Pick one in the console notes.

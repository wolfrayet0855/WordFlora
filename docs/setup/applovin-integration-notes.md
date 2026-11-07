# AppLovin through AdMob mediation: integration notes

Research date 2026-11-07. Docs only; nothing built. Tags: **[Google]** official Google, **[AL]** official AppLovin, **[inferred]** my reading. "Not fetched" = host refused or page lacked it; verify. Plan context: `docs/research/monetization-majors.md` section 3 (AppLovin bidding as step 3b, about launch +60 days).

## 1. Adapter and versions [Google, https://developers.google.com/admob/ios/mediation/applovin]
- Adapter: `GoogleMobileAdsMediationAppLovin`. Current stable at research date: **13.7.0.0**, verified with AppLovin SDK 13.7.0, built and tested with Google Mobile Ads SDK **13.12.0**. WordFlora already has GMA 13.12.0 and UMP 3.1.0 (`Package.resolved`), an exact match. Version scheme is `<AppLovinSDK version>.<adapter patch>`. Mismatched AppLovin and GMA versions can break builds.
- Install: Swift Package Manager is supported from adapter 13.3.1.0 (WordFlora already uses SPM). Package repo for adapters: look up the SPM line on the Google page ("Swift Package Manager" section; not copied here). **Conflict/watch item:** the same page says the CocoaPods Specs repo becomes read-only on 2026-12-02 and Google will not publish updated iOS adapters to CocoaPods after that. Use SPM only.
- Minimum iOS 13; WordFlora's target is higher.
- Format limits: bidding does **not** support banner (waterfall banner only 320x50 and 728x90); native not supported; interstitial and rewarded work with bidding. WordFlora uses banner (Home/Garden), interstitial and rewarded, so the banner would come from waterfall only, which needs manual eCPM until data accrues.
- Bidding needs `MobileAds.shared.start` called explicitly [Google, https://developers.google.com/admob/ios/mediation]; wait for the completion handler and check `adapterStatusesByClassName` before the first load. The app already starts the SDK this way (`AdsService.prepare`).
- Google recommends one AppLovin zone per AdMob ad unit. The zone instructions on the Google page say to pick "Android" as the platform; that appears to be a doc error for iOS. Pick iOS.

## 2. SKAdNetwork IDs
- Current `WordFlora/Info.plist` has **50** unique `SKAdNetworkIdentifier` entries and they are Google's published example list (including `cstr6suwn9`) [Google, https://developers.google.com/admob/ios/quick-start]. `ludvb6z3bs.skadnetwork` (AppLovin's own id, listed in Google's table https://developers.google.com/admob/ios/3p-skadnetworks, last updated 2026-01-30) **is already present**.
- **Could not fetch AppLovin's full list.** Both AppLovin hosts (support.applovin.com, developers.applovin.com, support.axon.ai, and the JSON endpoint) refused connection from this environment. So the "ids missing from Info.plist" list is **not produced**. Do not guess ids.
- Official source [AL]: https://developers.applovin.com/en/ios/overview/skadnetwork (mirror https://support.axon.ai/en/max/ios/overview/skadnetwork/ ; a search result also cites a JSON/XML feed at https://skadnetwork-ids.applovin.com/v1/skadnetworkids.json). Not fetched, verify the URLs.
- How to get the exact delta in two minutes (run on your Mac, not me):
  1. Open the AppLovin page and tick only the networks you use (AppLovin, plus Google already in the plist). Or download the JSON from the feed above.
  2. Extract ids: `curl -s <feed-url> | grep -o '[a-z0-9]*\.skadnetwork' | sort -u > applovin.txt`
  3. `grep -o '[a-z0-9]*\.skadnetwork' WordFlora/Info.plist | sort -u > have.txt`
  4. `comm -23 applovin.txt have.txt` prints the ids to add.
  5. Add each as a `<dict><key>SKAdNetworkIdentifier</key><string>ID</string></dict>` item; keep one entry per id (duplicates are harmless but untidy).
- Note: ids belong to ad *buyers*; AppLovin lists buyers from its MAX exchange, so the missing set may include many ids already covered by Google's list.

## 3. AdMob console: partner lists and ad source
1. AdMob > **Privacy & messaging** > **GDPR** > "Your settings" > ad partner list: add **AppLovin** (ad technology provider / ad partners). Re-publish the GDPR message so UMP shows it. Also add AppLovin to the **US states** ad partners list and re-publish. Google warns that unlisted partners "may fail to serve ads" [Google, https://developers.google.com/admob/ios/mediation]. Exact menu labels not fetched (the Google help article 404'd); follow "GDPR settings" and "US state regulations settings" links on the mediation page.
2. Check AppLovin's own UMP/IAB requirement: AppLovin documents TCF handling through the adapter, passing UMP/Additional Consent signals from adapter 12.0.0.0 onward [Google AppLovin page]. The Google "Additional Consent" ad-technology-providers list should include AppLovin; confirm in the console.
3. AdMob > **Mediation** > create a mediation group per ad unit (interstitial, rewarded, banner); add ad source **AppLovin (Bidding)** for interstitial/rewarded and **AppLovin (Waterfall)** where you want banner. AdMob needs the AppLovin SDK key and report key; create the AppLovin zone IDs in the AppLovin dashboard (MAX or equivalent), one per ad unit. Not fetched; follow the Google AppLovin page.
4. The AdMob blocking controls and G rating still apply to AdMob demand only. Set AppLovin's own content rating or category filters in its dashboard (verify) because AdMob's `maxAdContentRating` is forwarded to adapters only where each adapter implements it.

## 4. Child-directed and under-age settings: how to keep AppLovin from ever starting for a child

What the docs say:
- [Google AppLovin page] "AppLovin does not support initializing its SDK in connection with a child." Adapter 13.0.0.1+ turns AppLovin off for apps declaring child-directed or under-age-of-consent users. Adapter 13.6.3.0+ filters requests when `ageRestrictedTreatment` is `.child`. Error code 112 means "user is a child". Privacy options must be set **before** `MobileAds.shared.start`.
- [Google targeting page, https://developers.google.com/admob/ios/targeting] `ageRestrictedTreatment` (`.child`, `.teen`, `.unspecified`) is the current API; `tagForChildDirectedTreatment` and `tagForUnderAgeOfConsent` are deprecated. Mediation adapters forward `ageRestrictedTreatment` to third-party SDKs only when set through the Google Mobile Ads SDK. **TFUA is "not forwarded to mediation adapters"** per that page.
- US state opt-out: call `ALPrivacySettings.setDoNotSell(true)` [Google AppLovin page].

**Conflicts to resolve (flag):**
1. `docs/research/monetization-majors.md` (line ~117 and ~132) says the adapter switches AppLovin off when the under-age-of-consent tag is set. The Google AppLovin page says that (13.0.0.1+), but Google's targeting page says TFUA is not forwarded to adapters. These two statements disagree. Do not rely on TFUA. Use a code-level guard instead.
2. The adapter's documented off-switches are for **child** (`.child` / TFCD). WordFlora sets `.teen` for 13 to 17 (`AdsService.swift` line 37). The pages read do not say AppLovin is blocked for `.teen`. That is intended for 13+ in the US, but in the EEA and UK the age of consent is 13 to 16 depending on country. A teen there is "under the age of consent", and AppLovin's position on them was not verifiable (its privacy page could not be fetched; `monetization-majors.md` cites https://support.axon.ai/zh/max/ios/overview/privacy). Treat as unresolved until the owner reads that page or AppLovin confirms in writing.

**Guardrails to implement when the adapter is added (design, not code):**
- Under 13 and unknown age: already no SDK start (`AdGate.mayLoadAnyAd`). The AppLovin SDK is initialised only by the adapter when GMA starts or when an ad request routes to it, so as long as GMA never starts, AppLovin never starts. **Do not add any AppLovin start call at app launch** (the Google page suggests an optional early AppLovin init; skip it).
- Do not link or import AppLovin in code outside the adapter. Do not call `ALSdk.shared().initializeSdk` yourself.
- Order stays: age gate allowed, UMP, ATT (adults), set `ageRestrictedTreatment`, set `ALPrivacySettings`, then `MobileAds.shared.start`. `canRequestAds` false means nothing starts, so AppLovin never starts before consent.
- 13 to 17: until the owner decides conflict 2, use a mediation group that excludes AppLovin for these players by setting `ageRestrictedTreatment = .child` at request time, or a separate ad unit for teens with no AppLovin source. Cleanest: a second pair of ad units (adult / teen), AppLovin attached only to the adult units. Needs one more ad unit id pair per format and a code selection by age band.
- EEA/UK teens below the country's age of consent: use the teen units, same as above.
- US state opt-out: set `ALPrivacySettings.setDoNotSell(true)` when the US-states UMP choice is opted out. UMP's restricted-data-processing flag maps to this call.
- Add a unit test next to the existing `AdGate` exhaustive tests: for every `AgeBand?` x `hasRemoveAds`, the result of "may start mediation partners" is true only for `eighteenPlus` (or `thirteenPlus` if the owner approves).

## 5. app-ads.txt
Existing Google line (owner-setup C8): `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0`.
AppLovin: add the line AppLovin shows in its dashboard under the app's app-ads.txt / "Account > Keys" area, in the form `applovin.com, <your AppLovin entry>, DIRECT|RESELLER, <certification authority id>`. I could not fetch AppLovin's page, so I give no certificate id here. For AdMob mediation, AppLovin typically also appears as a seller line you add to the same file; copy it exactly, same domain root as the Marketing URL. Wait up to 24 hours then use "Check for updates" in AdMob.

## 6. Test mode [Google AppLovin page]
1. Register the test device in AdMob (already planned: owner C5).
2. Enable test mode in the AppLovin UI per AppLovin's MAX test-mode guide.
3. In **Ad Inspector** enable single ad source testing for "AppLovin (Bidding)" and "AppLovin (Waterfall)".
4. Turn off test mode in both AdMob and AppLovin before release.
5. Verify the winning network with `responseInfo.loadedAdNetworkResponseInfo.adNetworkClassName`.
6. Verify an under-13 profile produces **no** network request to AppLovin (proxy the simulator and watch for applovin/axon domains), and a teen profile follows the decision in section 4.

## 7. Privacy label delta
See `docs/setup/age-rating-and-privacy-label.md` section B2. Short version: Device ID tracking already Yes; AppLovin adds no new category that AdMob lacks as far as I can tell, but I could not read AppLovin's data page, so check it. Update the app manifest and App Store Connect label together. Add AppLovin's tracking domains to `NSPrivacyTrackingDomains` if the Xcode privacy report shows them.

## Summary
- Adapter `GoogleMobileAdsMediationAppLovin` 13.7.0.0 with AppLovin SDK 13.7.0 matches the installed GMA 13.12.0; use SPM, not CocoaPods (CocoaPods adapters stop 2026-12-02).
- `ludvb6z3bs` is already in `Info.plist`; the rest of AppLovin's SKAdNetwork list could not be fetched, so run the five-line diff in section 2.
- Two doc conflicts: TFUA is said both to disable AppLovin and not to be forwarded; and `.teen` is not documented as blocked for AppLovin.

## Open questions for the owner
1. Are 13 to 17 players allowed to receive AppLovin demand, in the US and in the EEA/UK? If not sure, attach AppLovin only to adult-only ad units.
2. Do you want me to run the SKAdNetwork diff once network access to AppLovin's pages works, or will you run the commands in section 2?
3. Banner via AppLovin is waterfall-only; accept manual eCPM for a few days, or mediate only interstitial and rewarded?
4. Ship AppLovin at launch or at +60 days as planned (and update `owner-setup-steps.md` C10, which says no mediation)?

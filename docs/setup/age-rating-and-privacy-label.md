> **REMOVED 2026-11-07 (owner): AppLovin is not accepting publisher accounts, so no AppLovin product ships in the app. Ignore every AppLovin step below. AdMob stays the only ad network. Gate G4 becomes "AdMob hardening" (see release-plan-extended.md).**

# Age rating and App Privacy label answers

Research date 2026-11-07. Docs only; no code changed. Source tags: **[Apple]** = Apple official, **[Google]** = Google official, **[AL]** = AppLovin official, **[inferred]** = my reading, check it. "Not verified" means the page could not be fetched or does not say. Not legal advice. This refines D2/D3 in `docs/setup/owner-setup-steps.md`.

## 0. What the app really does (from code and manifests)

- Word game. No chat, no user content, no web view, no real or simulated gambling, no loot boxes (Rose of Jericho drops are free). Garden weather is a seeded in-app effect: no CoreLocation or WeatherKit import anywhere in `WordFlora/` or `WordFloraWidget/`, so no location permission and no location data of ours.
- Age screen sets `AgeBand` (`under13`, `thirteenPlus`, `eighteenPlus`; `Rules/OnboardingFlow.swift`).
- `AdGate.mayLoadAnyAd` = not under 13 and not Plus. Unknown age never reaches an ad. UMP appears only just before an allowed request. ATT only for `eighteenPlus` (`AdGate.mayAskTracking`). 13 to 17 get `ageRestrictedTreatment = .teen`, `maxAdContentRating = .general`, and no ATT prompt (`Ads/AdsService.swift`).
- Google Mobile Ads SDK 13.12.0 and UMP 3.1.0 via Swift Package Manager (`Package.resolved`).
- Plus subscription / Remove Ads via StoreKit. iCloud sync via SwiftData/CloudKit private database (`iCloud.beta.WordFlora`).
- No first-party analytics found in the notes read. If any is added, add it to section B.

## A. Age rating

### A1. Apple's new system [Apple]
- Apple moved every app to a new scheme on 2026-01-31 (iOS 26 and later display it). Tiers: 4+, 9+, 13+, 16+, 18+. Developers were asked to answer the updated questions by 2026-01-31 or face an interruption when submitting updates. https://developer.apple.com/news/upcoming-requirements/?id=01212026a and https://developer.apple.com/news/upcoming-requirements?id=07242025a
- Tier definitions and the content each tier may contain: https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions
- Where to answer: App Store Connect > app > General > App Information > Age Ratings > Set Up Age Ratings. Role needed: Account Holder, Admin, App Manager or Marketing. Steps: in-app controls and capabilities list, then each content section (frequency per descriptor), then "Age Categories and Override", optional Age Suitability URL, Save. https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating
- Frequency levels used on the definitions page: Infrequent and Frequent. Some items are yes/no (gambling, loot boxes). The full wording of every question was not on the fetched pages; read each screen in the UI.

### A2. Tier map relevant to WordFlora [Apple, definitions page]
| Tier | Things that raise to it | Relevant? |
|---|---|---|
| 4+ | In-app controls (parental controls, age assurance), user-generated content, messaging and chat, **advertising**, infrequent contests | Ads do not raise the rating on their own |
| 9+ | Infrequent profanity, horror, cartoon violence, mature themes, weapons, health and wellness topics, **loot boxes** | None apply |
| 13+ | Social media, frequent horror or violence, infrequent simulated gambling, frequent contests | None apply |
| 16+ | **Unrestricted web access**, frequent medical or mature themes | None apply (no web view) |
| 18+ | Gambling, frequent simulated gambling | None apply |

### A3. Answers for WordFlora
| Question area | Answer | Note |
|---|---|---|
| In-app controls: parental controls | Select only if the list has an item matching the Calm / purchase gate; otherwise none | Selecting controls does not raise the tier. Check wording in UI |
| In-app controls: age assurance | Select if the list offers it and you count the neutral age screen. It is self-declared, not verified | Be honest (Guideline 2.3.6 [Apple]); do not overstate |
| Capabilities: unrestricted web access | No | Links out open Safari or a sheet; confirm no in-app browser |
| Capabilities: user-generated content, messaging/chat, social media | No | |
| Capabilities: advertising | Yes, if asked | 4+ tier list; ads are third-party and G-capped |
| Violence (cartoon, realistic), guns/weapons | None | Garden weather is "looks only, mended by care"; no violence descriptor fits |
| Horror/fear, profanity/crude humor, sexual content/nudity, mature themes | None | |
| Alcohol/tobacco/drugs, medical/treatment, health and wellness topics | None | Rest cards are break prompts, not health advice. If the form's "health and wellness" item feels close, answer the way a reviewer reading the card copy would; expect 9+ if you tick it |
| Simulated gambling, gambling, contests, loot boxes | None / No | No paid randomness. A daily shared word is not a contest |
| Age Categories and Override | Not Applicable. Do NOT choose Made for Kids | Made for Kids puts the app in the Kids Category (third-party ads then banned) |
| Age Suitability URL | Optional; skip | |

Expected result: **4+** [inferred]. Accept 9+ if the questionnaire forces it. Do not use "Override to Higher Age Rating" unless your EULA sets a minimum age higher than the calculated rating (Apple says you must then override).

Metadata rule that matters for a mixed audience: Guideline 2.3.8 reserves "For Kids" / "For Children" for the Kids Category; the listing must be fine at 4+. 5.1.4(b): apps outside the Kids Category cannot use terms in name, subtitle, icon, screenshots or description implying the main audience is children. https://developer.apple.com/app-store/review/guidelines/ [Apple]

### A4. Region ratings
Apple also derives Australia, Brazil (self-rated; ads and UGC are triggers for the Brazil A12/A6 ratings per the definitions page) and Korea (GRAC RCN only if you have one) values. Check the Brazil value on the App Information page after saving; an ad-supported app may show a higher Brazil rating than 4+ [Apple, definitions page; the Brazil mapping was only partly readable, verify in UI].

## B. App Privacy nutrition label (App Store Connect > App Privacy)

Rules that drive the answers [Apple, https://developer.apple.com/app-store/app-privacy-details/]: you must declare data collected by you or third-party SDKs; "collect" means transmitted off device and kept readable longer than needed to serve the request in real time; data is "linked" unless de-identified before collection; "tracking" means linking with third-party data for targeted ads or measurement, or sharing with a data broker; data Apple collects through its frameworks (CloudKit, App Analytics, StoreKit) is not yours to declare.

Google's SDK disclosure lists six types: crash logs, performance data, device ID, advertising data, coarse location (IP-derived), other product interactions. It does not state Linked or Tracking per type, so those two columns are your judgment [Google, https://developers.google.com/admob/ios/privacy/data-disclosure]. Note the label is one answer for the whole app, so it must cover the ad-served adult path even though children never trigger it.

### B1. Today (AdMob only)
Opening question "Do you or your third-party partners collect data from this app?" = **Yes**.

| Type | Collected | Linked | Tracking | Purposes |
|---|---|---|---|---|
| Identifiers > Device ID | Yes | Yes | **Yes** (adults who allow ATT and personalised ads) | Third-Party Advertising, Analytics |
| Usage Data > Advertising Data | Yes | Yes | No | Third-Party Advertising, Analytics |
| Usage Data > Product Interaction | Yes | Yes | No | Third-Party Advertising, Analytics |
| Location > Coarse Location | Yes | Yes | No | Third-Party Advertising, Analytics |
| Diagnostics > Performance Data | Yes | No | No | Third-Party Advertising, Analytics (Google says may be shared with ad entities) |
| Diagnostics > Other Diagnostic Data | Yes | No | No | same as manifest |
| Diagnostics > Crash Data | Yes | No | No | Analytics |
| Purchases | No (you read StoreKit entitlements on device; Apple holds purchase data) | | | |
| User Content / Other Data (game progress) | No: stored in the player's own iCloud private database, which you cannot read; CloudKit is Apple-collected and exempt | | | |
| Contact info, Health and fitness, Financial, Sensitive info, Contacts, Browsing/Search history, User ID | No | | | |

This table is the existing `PrivacyInfo.xcprivacy` content (section C) turned into label answers. "Does the data get used to track you" appears once for the Device ID row; the other rows are No.

Open point, verify before submit: ATT is asked only of adults, but the label is global. Declaring Device ID as tracking is correct while the manifest says `NSPrivacyTracking` true. Under 13 and 13 to 17 never reach tracking, which does not change the label.

### B2. Delta when AppLovin is added through AdMob mediation
AppLovin is a third-party SDK you ship (`AppLovinSDK` pulled in by `GoogleMobileAdsMediationAppLovin`), so its collection counts as yours.
- **Likely no new categories** beyond B1 for the ad-serving core: AppLovin's published data uses are Device ID (IDFA/IDFV), Advertising Data, Product Interaction, Coarse Location (IP), Performance and Crash data, used for Third-Party Advertising and Analytics. I could not fetch AppLovin's privacy-details page (hosts refused the fetch), so this is [inferred]; **verify** on https://developers.applovin.com/en/max/ios/overview/privacy (or its support.axon.ai mirror) and on the AppLovin "Apple privacy manifest and labels" page, and add any type it lists that B1 lacks (candidates: Other Usage Data, Precise Location only if you enable it, User ID if you pass one: you should not).
- Tracking stays Yes for Device ID (no change). Purposes: still Third-Party Advertising, Analytics. Consider adding **Developer's Advertising or Marketing** only if you use AppLovin attribution (you will not).
- Keep `NSPrivacyCollectedDataTypes` in the app manifest in step (C below). AppLovinSDK ships its own manifest; Xcode merges the SDK manifests into the Privacy Report.
- Mediation adds no new Apple privacy question; the net change is verification, not new rows, unless AppLovin lists a type you lack.

## C. What must match `PrivacyInfo.xcprivacy`

Current app manifest (`WordFlora/PrivacyInfo.xcprivacy`): `NSPrivacyTracking` true; tracking domains empty; collected types Device ID (linked, tracking), Advertising Data, Product Interaction, Coarse Location (all linked, not tracking), Performance, Other Diagnostic, Crash Data (not linked, not tracking); required-reason API: UserDefaults with CA92.1 and 1C8F.1. Widget manifest (`WordFloraWidget/PrivacyInfo.xcprivacy`): no collected data.

Match checklist:
1. Every type and Linked/Tracking flag in B1 equals the app manifest. They do today.
2. **`NSPrivacyTrackingDomains` is empty.** If tracking is Yes, Apple expects the tracking domains that your SDKs contact to be listed so iOS can block them when ATT is denied. Google's and AppLovin's SDKs ship their own manifests with their own domains; check Xcode Product > Archive > Generate Privacy Report to confirm the merged list, and add any missing domain to the app manifest if the report flags it [inferred; Apple doc: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files].
3. Required-reason APIs: UserDefaults is declared. If the app or any SDK uses file timestamps, system boot time, disk space, or active keyboard APIs, each needs its reason. Run the privacy report after adding AppLovin and compare.
4. The privacy policy page (D1 in `owner-setup-steps.md`) must state the same data uses and the age-based rule (children never see ads).
5. Widget extension: no collection, so no label row from it.
6. Re-run the report when the AppLovin adapter lands; update both the manifest and the label in one change.

## D. Guidelines 1.3 and 5.1.4 for an app that serves different experiences by age [Apple, https://developer.apple.com/app-store/review/guidelines/]

- 1.3 applies to the **Kids Category**. WordFlora does not opt in, so third-party ads and analytics are not banned by 1.3. The risk is 5.1.4(a): "Apps intended primarily for kids should not include third-party analytics or third-party advertising." A reviewer can ask whether the app is intended primarily for kids. WordFlora is mixed audience (plain word game with a neutral age screen), but the garden-and-flowers art and a younger age band mean you need the mixed-audience story ready: the under-13 path loads **no ads, no SDK start, no UMP, no ATT**, shown in `AdGate`.
- 5.1.4(a): you may ask for birthdate only to comply with child-privacy laws and must offer real functionality regardless of age. The age screen offers three bands, not a date of birth; keep it that way, do not store a birthdate, and keep the whole game playable for every band.
- 5.1.4(b): any app that collects or can share personal information from a minor needs a privacy policy and compliance with children's privacy law. A parental gate is not COPPA consent. The app never starts ads for under 13 or unknown age, so it does not disclose child data to ad networks; keep that guarantee true after AppLovin (see the AppLovin notes).
- 2.3.8 and 5.1.4(b) metadata: nothing "for kids" in name, subtitle, icon, screenshots, description. Describe it as for everyone.
- 5.1.2(i): ATT permission is required for tracking and the app may not make the app depend on it. ATT is asked of adults only; the `NSUserTrackingUsageDescription` text must stay honest (it is).
- 5.1.1(ii): consent can be withdrawn easily: keep the UMP privacy options row (already built: `privacyOptionsRequired`).
- Age rating honesty: 2.3.6. Answer truthfully; ads, in-app purchases and the age screen are consistent with 4+.
- Kids revenue and COPPA/UK Code background: `docs/research/kids-revenue.md`.

## E. Things that conflict or are unsettled
1. `owner-setup-steps.md` D2 expected 4+; the new system's Brazil value may differ (A4). Verify in UI.
2. `owner-setup-steps.md` C6 says to set `tagForChildDirectedTreatment` / `tagForUnderAgeOfConsent`; Google now deprecates both in favour of `ageRestrictedTreatment` [Google, https://developers.google.com/admob/ios/targeting]. The code already uses the new property. See the AppLovin notes for the age-of-consent gap.
3. `owner-setup-steps.md` C10 says "no mediation"; `monetization-majors.md` plans AppLovin at launch +60 days. This needs a ruling (owner decision), and the label cannot be submitted until it is made.

## Open questions for the owner
1. Ship v1 without AppLovin (B1 label) and revise the label at +60 days, or include AppLovin up front?
2. Do you want to tick "age assurance" for the self-declared age screen?
3. Do you accept 9+ if the questionnaire forces it?
4. Is any first-party analytics planned (adds a label row)?

## Owner rulings (2026-11-07)
- Age assurance: tick it. The app asks the player's age on first launch and relies on a truthful self-declaration, which the owner considers sufficient. At submission, read Apple's exact wording for that question in App Store Connect and confirm self-declaration fits; if Apple's wording asks for verification beyond self-declaration, tell the lead before answering.
- 9+ rating: accept it if the questionnaire produces it.
- First-party analytics: none planned; if added, update the privacy label first.

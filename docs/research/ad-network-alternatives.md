# AdMob tuning plan for launch, and ad-network alternatives for 1.1

Research date 2026-11-07. Owner ruling (same day): **no second ad network in this release; tune AdMob only.** AppLovin is out (owner report: not accepting publisher accounts; I could not verify this on any public page, see appendix A3). Code read: `Ads/AdsService.swift`, `Rules/AdGate.swift`, `App/AppModel.swift` (ad section), `Views/HomeView.swift`, `Views/GardenView.swift`, `Views/PlantDetailView.swift`, `Config/Ads.xcconfig`, `Config/Ads.local.xcconfig` (keys only), `WordFlora/Info.plist`, `WordFlora/PrivacyInfo.xcprivacy`. Source tags: **[verified]** fetched from the official page cited; **[search]** from a search summary, page not fetched; **[inferred]** my reading. Revenue figures are estimates on the base case of `revenue-compensation.md` (10,000 monthly players, 13+ ads about $665/mo).

**Needs owner approval** is marked **[OWNER]**.

---

## Part 1. AdMob tuning plan: gate G4, about 4 builder-hours

### 1.0 What is already right (do not redo)

- Under-13 and unknown age never start the SDK, UMP or ATT (`AdGate.mayLoadAnyAd`, `AppModel.mayStillLoadAds`, `ParentalGate.isRequired`). Teens get `ageRestrictedTreatment = .teen`, G rating, no ATT. Adults only get ATT, and only after UMP.
- Interstitial pacing is already at natural breaks only: it follows the player's own "One more" tap (or Play within 3 minutes of "That's enough"), never mid-round (`midRound`), never around the Daily Bloom, never after a loss, never at night, never in session 1, needs 3 sessions or a level-up, every 3rd round, 3-minute gap, 6 a day, never inside the 5 s celebration window. The button says "A short ad may play first." That is better than any AdMob policy requires; keep every rule.
- `Info.plist` has **50 `SKAdNetworkItems`** (the "0 entries" note in `monetization-majors.md` 3a is stale).
- Real ids are Release-only: `Config/Ads.local.xcconfig` (git-ignored) uses `ADMOB_*_ID[config=Release]`, so Debug and UI-test builds keep Google's test ids even with the local file present. Correct.
- Banner is an anchored adaptive banner on Home and Garden only, hidden until `ads.started`, never beside the letter keys.
- Rewarded is player-initiated, one placement (Plant detail, only when water is 0), 2 water, 3 a day, hidden under 13, for Plus and in Quiet Garden.

### 1.1 Builder tasks (about 4 h, one builder, after G3)

| # | Task | Why | Est. |
|---|---|---|---|
| B1 | **Unit test: age rule is airtight.** Assert that for `under13` and `nil` age band, `AdsService.prepare` is never called from `adBeforeNextRound`, `playTappedOnHome`, `prepareBannerIfAllowed` and `watchRewardedAd`; that `showBanner` and `canOfferRewarded` are false; and that `thirteenPlus` sets `.teen` and never calls `requestTrackingIfNeeded`. Use `ads.offline = true` plus a spy flag on `prepare`. | The one claim App Review and the privacy label rest on. Already planned as G4 (1). | 1.0 h |
| B2 | **Privacy report and `NSPrivacyTrackingDomains`.** Product > Archive > Generate Privacy Report; compare with `PrivacyInfo.xcprivacy`; copy any tracking domain the report flags into `NSPrivacyTrackingDomains` (empty today). Confirm the collected types match section B1 of `age-rating-and-privacy-label.md`. | Apple blocks listed tracking domains when ATT is denied; an empty list with `NSPrivacyTracking = true` is the thing a reviewer questions. | 0.5 h |
| B3 | **Release vs Debug id check.** Build Debug: console prints the Google test-ad banner. Archive Release: `Info.plist` in the `.xcarchive` shows the `ca-app-pub-<real>` app id and three real unit ids. Grep the project for `applovin` (case-insensitive) and expect zero hits. Confirm `GADApplicationIdentifier` is the app id (tilde), not a unit id. | Serving test ids in Release is zero revenue; serving real ids in Debug is invalid traffic and an account ban. | 0.5 h |
| B4 | **Banner frame.** `GardenView` fixes the banner at `height: 60`; the anchored adaptive banner can be 50 to 90 pt depending on width. Use `adSize.size.height` from the created `BannerView` (expose it from `AdBannerView` via a binding or use `.fixedSize(horizontal: false, vertical: true)`), so the ad is never clipped. Home uses no fixed height: fine. | A clipped banner is an AdMob "ad obscured" policy issue and loses the impression. | 0.5 h |
| B5 | **Preload earlier on Home.** `prepareBannerIfAllowed` already starts the SDK from session 2 and `start` preloads the interstitial and rewarded ad. Add a call to `preloadInterstitial()` when the resting card appears with `adWouldPlayOnOneMore == true`, so the first eligible "One more" tap has a loaded ad instead of silently skipping it (`showInterstitial` returns false if nothing is loaded). | Recovers the first eligible impression per session; no change to any rule. | 0.5 h |
| B6 | **Second banner unit for Garden** (reporting only). Add `AdMobBannerGardenUnitID` to `Ads.xcconfig` / `Info.plist` and `AdsService.Unit`, `AdBannerView(unit:)`. Falls back to the Home id if empty. | Lets the owner read Home vs Garden eCPM and show rate and later drop the weaker screen. Tiny cost now, awkward later. | 0.5 h |
| B7 | **Rewarded ad request: server-side verification off, `customRewardString` unused.** Confirm nothing else to do. Leave `maxAdContentRating = .general` for everyone. | Sanity. | 0.25 h |
| B8 | Update `docs/setup/owner-setup-steps.md` C3 (add the Garden banner unit) and C10 ("no mediation" becomes "mediation groups exist, AdMob Network only"). | Keep the owner steps true. | 0.25 h |

What I am **not** proposing for launch and why:
- **App open ads:** no. A cold-start ad is the opposite of the calm promise, it would fire before the age check is re-read on a shared device, and the SDK would have to start at launch. Keep the "SDK starts only right before an allowed ad" design.
- **Collapsible or MREC banners:** no. Collapsible banners pay more but cover play; MRECs need a new slot. Neither suits Home or Garden.
- **Native ads:** not now. They need a new ad view with the "Ad" badge and AdChoices, a native ad unit, and a place in the UI (the Shed shelf is the only honest fit). About 6 h of builder work for maybe +$10 to $30/mo at our scale. Revisit in 1.1 if the Shed gets a shelf anyway.
- **Rewarded interstitial:** no. It is shown without a tap and would break "only on the player's own choice".
- **Interstitial frequency changes:** none. The `frequency` / `minGapSeconds` / `maxPerDay` fields in `AdGate.Context` are compile-time defaults (there is no remote config), so any change is an app update. Keep 3 / 180 s / 6. Loosening them is a product decision, not a tuning one. **[OWNER]** if ever changed.

### 1.2 Rewarded placements that fit the calm tone **[OWNER]**

Today's single placement (Plant detail, water at 0) is pure. Each extra placement below is opt-in, player-initiated, 13+ only, non-personalised for teens, hidden in Quiet Garden and Calm mode, and shares the 3-a-day cap. None is in the 4 h; each is about 1 to 1.5 h and can ship in 1.1.

| Placement | Trigger | Reward | Fit |
|---|---|---|---|
| R1 Water at the Garden shelf | Water bank at 0 while on the Garden screen (not only inside Plant detail) | 2 water | Same reward as today, one more honest spot. Lowest risk |
| R2 "Ask the garden for a hint" | Daily Bloom or a round stuck for 60 s or more; hidden on the last letter | 1 extra hint | Rewarded hints are the highest-value format in word games; must never show on a loss screen |
| R3 "Wake a sleeping seed" | A seed waiting on its growth timer | Skip one wait | Only if the owner is comfortable with a timer skip; some players read it as pressure |

Estimated uplift: R1 and R2 together lift rewarded ads per daily free 13+ player from about 0.3 to 0.5 to 0.6, about **+$60 to $120/mo** at 10,000 players (rewarded eCPM $12 base). This is more than a second ad network would add (appendix A5) and carries no new SDK.

### 1.3 Owner console steps (about 1 to 1.5 h, before G4 exit) **[OWNER]**

1. **Ad units.** Keep `WordFlora_Banner_Home`, `WordFlora_Interstitial`, `WordFlora_Rewarded_Water`; add `WordFlora_Banner_Garden` (B6). Send the new unit id to the builder for `Ads.local.xcconfig`.
2. **eCPM floors.** Leave each unit on **Google optimized floors** (the default for all ad units per AdMob Help, [search] https://support.google.com/admob/answer/9686161). Set **no manual floor** at launch: at a few hundred daily ad requests, fill matters more than price, and a floor takes a week or more to calibrate [search, same page]. Revisit after 30 days of data (section 1.4).
3. **Mediation groups, mediation-ready but AdMob-only.** Create one mediation group per format (Banner, Interstitial, Rewarded), platform iOS, all countries, with the **AdMob Network as the only ad source**. This costs nothing now and means any future bidder is added in the console and, for Google-managed exchanges, needs **no app update** (appendix A2). Keep the bidding floor in each group at Google optimized.
4. **Banner refresh rate.** In each banner unit's settings, set refresh to **60 s** (the Google-optimised option is also fine). Home and Garden are long dwell screens; faster refresh raises impressions but lowers eCPM and reads as busy.
5. **Blocking controls.** Block sensitive categories (gambling, dating, alcohol, drugs, politics, religion, weight loss, get-rich-quick), set the app-level max content rating to G. Review the Ad review center weekly in the first month.
6. **Privacy & messaging.** GDPR and US-state messages published; ad partners list stays Google's default set (nothing to add while AdMob is alone). Confirm the IDFA explainer is off (the app's ATT copy is already honest).
7. **Test devices.** Add every device the owner and builder use under Settings > Test devices. Never tap a live ad.
8. **app-ads.txt** with the single Google line at the domain root; add the Marketing URL in App Store Connect; "Check for updates" after the listing is live.
9. **Reports to set up now:** (a) ad unit report by country, format: impressions, show rate, match rate, eCPM, estimated earnings; (b) "serving restriction" breakdown (personalised vs non-personalised vs limited ads, https://support.google.com/admob/answer/10922726) which is the teen-vs-adult yield; (c) a saved report for rewarded: requests, completion rate (impressions to rewards).

### 1.4 What to measure after launch, and what to do with it

| Metric | Where | Read it as | Act when |
|---|---|---|---|
| Match rate and show rate per unit | AdMob ad unit report | Match under 85% on iOS US/EU means fill, not price, is the limit | Match < 85% for 2 weeks: do not add floors; consider a second bidder (appendix) |
| Impressions per daily free 13+ player | AdMob impressions / own age-band count | Base model assumes about 6 banners, 1 interstitial, 0.3 rewarded per daily player | Interstitials under 0.5: the pacing rules are tighter than the model; fine, do not loosen. Rewarded under 0.2: ship R1/R2 |
| eCPM by format and country | AdMob | US iOS banner about $1, interstitial and rewarded $8 to $24 | After 30 days with eCPM steady and match > 95%: try a manual floor at 70% of the 30-day eCPM on interstitial and rewarded only, one unit at a time, 2-week test |
| Personalised vs non-personalised share | Serving restriction report | Teens and ATT-denied adults are NPA. Expect NPA well over half of impressions | NPA revenue per impression under 50% of personalised: a bidder with strong contextual demand (Unity, Liftoff) is worth more than floors |
| Rewarded completion rate | AdMob rewarded report | Healthy is above 85% | Lower means the offer appears where people do not want it; move or remove the placement |
| Home vs Garden banner eCPM and show rate | The two units (B6) | Garden dwell is longer, so Garden may earn more per session | Drop the weaker screen's banner if it earns under 20% of banner revenue; fewer ads is on-brand |
| Age-band mix | Own settings event, no SDK | Share of under-13 / unknown tells you the real ad-free share | Unknown share far above under-13 share: the age screen is being skipped, keep it neutral but make the three choices clearer |
| D7 retention, ad-exposed vs not | App Store Connect retention plus own flag | Ads should not move D7 by more than 1 to 2 points | If they do, cut `maxPerDay` before anything else |
| Crashes with `GoogleMobileAds` frames | Xcode Organizer | Should be zero | Any pattern: pin the SDK version and report |
| Policy center | AdMob Policy center | Must be empty | Any notice: fix within the stated days; most are app-ads.txt or "ad obscured" |

Timing: all of Part 1 fits the G4 slot (Thu 11-12, about 4 h) and the owner steps fit the same evening. Nothing here moves the Thu 11-19 submit.

---

## Appendix A. Second ad network: survey and the 1.1 plan

### A1. Short answer

Do nothing extra for this release. After launch, the owner can request **Google-managed bidding partners** in the AdMob console (no SDK, no app update; A2). For 1.1 the best SDK partner is **Unity Ads** (bidding, open sign-up, global, adapter forwards the age flags, 3 formats), fallback **Liftoff Monetize** (bidding and waterfall, 6 formats, adapter forwards `ageRestrictedTreatment`, but the app must be live in the store first, which is true by 1.1). Expected lift for one SDK bidder: **+$65 to $130/mo** at 10,000 players, about 6 to 8 builder-hours plus owner sign-up. The non-ad levers already planned (Plus Forever, the price test, the rewarded placements in 1.2) each match or beat that.

### A2. Networks, as of 2026-11-07

Age handling note for every row: WordFlora never starts any ad SDK for under-13 or unknown age, so **no partner can ever see a child request**; the only partner-side question is the 13 to 17 non-personalised treatment, which rides on whether the AdMob adapter forwards `ageRestrictedTreatment` / `tagForUnderAgeOfConsent`. Privacy-label delta for any SDK partner: no new categories expected beyond the AdMob set (Device ID, Advertising Data, Product Interaction, Coarse Location, Performance, Crash, Other Diagnostics) but each SDK's manifest must be checked in the merged privacy report [inferred]. Every partner must also be added to the AdMob GDPR and US-state ad partner lists before serving [verified on each Google adapter page].

| Network | Sign-up for a small indie | AdMob integration | Formats (iOS) | Age-flag forwarding | Notes and risk |
|---|---|---|---|---|---|
| **Google-managed bidders** (Index Exchange, Magnite DV+, PubMatic, OpenX, Smaato, Media.net, Sonobi, InMobi Exchange, Equativ, and others) | Set up "directly in your AdMob account"; all need a contractual relationship first; Media.net and Fluct approve you; no public volume threshold found [verified https://support.google.com/admob/answer/9842838] | Bidding, **no SDK, no ad unit mapping, no app update** for most [verified] | B, I, R, some N | Requests go through the Google SDK, which already carries the teen treatment [inferred; confirm in AdMob Help before enabling] | Cheapest possible add. Demand is brand/exchange, so the lift is modest (my estimate +3 to 8%). Zero review risk |
| **Unity Ads** | Unity account and Monetization dashboard; no approval criteria found [search docs.unity.com]. ironSource Ads direct demand was sunset 2026-04-30; Unity Ads and LevelPlay continue [verified https://unity.com/products/ironsource-ads-sunset] | Adapter 4.21.0.0, SPM; **bidding only** (waterfall ended 2026-01-31) [verified https://developers.google.com/admob/ios/mediation/unity] | B, I, R | Forwards child-directed and under-age-of-consent (4.16.6.0+); Mixed Audience must be set in the Unity dashboard [verified] | Global except CN, RU. Strong game demand, which suits a puzzle audience. **Best 1.1 option** |
| **Liftoff Monetize (Vungle)** | Open dashboard sign-up; app must be live in the store (sources conflict; assume yes) [search support.vungle.com] | Adapter 7.7.8.0, SPM; bidding and waterfall [verified https://developers.google.com/admob/ios/mediation/liftoff-monetize] | AO, B, I, R, RI, N | Forwards `ageRestrictedTreatment` to Vungle's COPPA API (7.7.2.1+) [verified] | Global. Needs `VunglePrivacySettings.setCCPAStatus`. **Fallback** |
| **Mintegral** | Open sign-up [search]; bidding needs a partnership agreement with Mintegral [verified https://developers.google.com/admob/ios/mediation/mintegral] | Adapter 8.1.9.0, SPM; bidding and waterfall | AO, B, I, R, N | Forwards all three flags (8.1.3.1+) [verified] | Global. Needs `setDoNotTrackStatus` before SDK start. Third choice |
| **Meta Audience Network** | Meta Business Suite required; **app must be live** in the App Store [verified https://developers.facebook.com/documentation/audience-network/quick-start]; application form linked from AdMob | Adapter 6.22.1.0; **bidding only**; iOS 15+ [verified https://developers.google.com/admob/ios/mediation/meta] | B, I, R, RI, N | Forwards `ageRestrictedTreatment` to Meta's COPPA API (6.21.1.1+) [verified] | Needs `FBAdSettings.setAdvertiserTrackingEnabled` before SDK start and IAB Additional Consent in the EEA. Pays well only for ATT-allowed adults, a minority here. Skip |
| **Moloco** | **Invite only**; contact sales or submit a form; review up to 7 working days [verified https://docs.unity.com/grow/levelplay/sdk/ios/networks/guides/moloco, search help.publisher.moloco.com] | Adapter 4.12.0.0; bidding only; AdMob partnership agreement [verified] | B, I, R, N | Forwards `ageRestrictedTreatment` (4.6.1.1+) [verified] | Performance DSP demand. Worth a form submission after launch; do not plan on it |
| **Pangle (TikTok)** | Sign-up before company details [search]; bidding split into US / KR / ROW ad sources | Adapter 8.4.0.7.0; bidding and waterfall [verified https://developers.google.com/admob/ios/mediation/pangle] | AO, B, I, R, N (no B/N in US bidding) | Filters child requests (error 104: no child users); `setCOPPA` removed [verified] | **Serves no EU or UK country** [verified https://pangleglobal.com/knowledge/regions-Pangle-supports]; US only via Pangle US. TikTok brand on a kids-adjacent app invites questions. Skip |
| **InMobi (SDK)** | Open publisher sign-up; bidding needs a partnership and account-manager setup [verified https://developers.google.com/admob/ios/mediation/inmobi] | Adapter 11.5.0.0; bidding and waterfall | B, I, R, RI, N | Forwards `ageRestrictedTreatment` (11.2.0.1+) [verified] | Prefer the no-SDK **InMobi Exchange** row above (AdMob warns not to sign up on the InMobi dashboard for it) |
| **DT Exchange (Fyber)** | Console sign-up; bidding needs a partnership agreement [verified https://developers.google.com/admob/ios/mediation/dt-exchange] | Adapter 8.5.1.0; bidding and waterfall; iOS 15+ | B, I, R, N | Forwards all three flags (8.4.7.1+) [verified] | Fine but no reason to pick it over Unity or Liftoff |
| **Chartboost** | Sign-up plus Publisher App Review before monetisation [verified https://developers.google.com/admob/ios/mediation/chartboost] | Adapter 9.14.2.0; **waterfall only**; needs `-ObjC` and non-modular includes | B, I, R | Forwards all three flags (9.12.0.1+) [verified] | Waterfall needs manual eCPM management. Skip |
| **AppLovin MAX** | Owner reports no new publisher accounts. Public pages still show an open sign-up with an approval step; one 2026 GitHub issue reports an approval stuck indefinitely [search https://max.applovin.com/signup, https://github.com/AppLovin/AppLovin-MAX-Unity-Plugin/issues/619]. **Unverified either way** | Adapter exists; bidding | B, I, R | Adapter switches itself off for child / under-age [per monetization-majors.md C2] | Removed by owner ruling. If an account ever opens, it slots into the same 1.1 plan |
| **Unity LevelPlay as the mediator** | Open | Would replace AdMob mediation with LevelPlay and put AdMob under it | all | LevelPlay has its own child/age API | A rewrite of `AdsService` and the UMP flow for no gain at our scale. No |

Formats: AO app open, B banner, I interstitial, R rewarded, RI rewarded interstitial, N native. AdMob's own network list and bidding status: [verified https://developers.google.com/admob/ios/choose-networks, https://admob.google.com/home/bidding/bidding-partners].

SKAdNetwork: every SDK partner asks you to add its SKAdNetwork ids to `Info.plist` (each adapter page); Google-managed bidders need none beyond Google's list.

### A3. AppLovin status

Not confirmable from public sources. AppLovin's sign-up page is live and its policy page describes an approval process for all publishers; no notice of a closure exists [search]. The owner's experience (refused or stalled) is consistent with the stuck-approval report above. Treat AppLovin as unavailable, not as banned; nothing in the 1.1 plan depends on it.

### A4. The 1.1 plan (if the owner wants a second network then) **[OWNER]**

1. **Day 1 after launch, owner, 30 min, no app update:** in AdMob > Mediation > Bidding, request partnerships with the Google-managed exchanges that need no SDK (Index Exchange, Magnite DV+, PubMatic, OpenX, Smaato). Accept any that approve. Add each to the GDPR and US-state ad partner lists and republish both messages. Watch match rate and eCPM for 2 weeks.
2. **1.1, Unity Ads as a bidder, about 6 to 8 builder-hours:** adapter via SPM; Unity SKAdNetwork ids in `Info.plist`; set the Unity project to Mixed Audience; map the Game ID and three placement ids in the three mediation groups from 1.3 step 3; add Unity to both ad partner lists; `UADSMetaData` US-privacy call before SDK start; unit test that `.teen` reaches the adapter (debug log of `responseInfo.adNetworkClassName`); privacy report diff and label update; TestFlight check. Owner: Unity account, project, three placements, app-ads.txt line (about 1 h plus any approval wait).
3. Fallback: Liftoff Monetize with the same steps (needs the live App Store listing, which 1.1 has).

What makes a later add cheap (do these at launch): the three AdMob-only mediation groups (1.3 step 3), the `AdsService.prepare` structure that already sets request configuration before `MobileAds.start` (every adapter reads the age flags from there), the B1 test that fails if any path starts the SDK for under-13, and the per-screen banner units (B6).

### A5. Is a second network worth it at our scale

| Lever | Est. $/mo at 10,000 players | Builder hours | New SDK | Owner steps |
|---|---|---|---|---|
| AdMob tuning (Part 1) | +$20 to $50 (recovered first impression, Garden split, floors later) | 4 | no | 1 to 1.5 h |
| Rewarded placements R1, R2 (1.2) | +$60 to $120 | 2 to 3 | no | none |
| Google-managed bidders (A4 step 1) | +$20 to $50 | 0 | no | 30 min |
| Unity Ads bidder (A4 step 2) | +$65 to $130 | 6 to 8 | yes | 1 h plus approval |
| Plus Forever (already in this release) | +$40 to $80 | done | no | done |
| Annual price test $19.99 / 7-day trial (planned days 31 to 60) | +$60 to $90 | 1 | no | 30 min |

Assumptions: base case from `revenue-compensation.md` (13+ ads $665/mo, 25% daily/monthly ratio, eCPM $0.8 / $8 / $12); a second bidder lifts 13+ eCPM 10 to 20%; rewarded uplift from 0.3 to 0.5 to 0.6 rewarded ads per daily free 13+ player. None of these are benchmarks for a calm word game on AdMob iOS specifically; measure (1.4) before assuming.

Conclusion: at launch scale the rewarded placements and the price test beat a second network for fewer hours and no new SDK; the Google-managed bidders are free money after launch; Unity Ads is the right 1.1 add once match rate or NPA yield (1.4) says fill or contextual demand is the limit.

## Sources

- AdMob networks and bidding: https://developers.google.com/admob/ios/choose-networks ; https://admob.google.com/home/bidding/bidding-partners ; https://support.google.com/admob/answer/9842838
- AdMob adapters: https://developers.google.com/admob/ios/mediation/unity ; https://developers.google.com/admob/ios/mediation/liftoff-monetize ; https://developers.google.com/admob/ios/mediation/mintegral ; https://developers.google.com/admob/ios/mediation/meta ; https://developers.google.com/admob/ios/mediation/moloco ; https://developers.google.com/admob/ios/mediation/pangle ; https://developers.google.com/admob/ios/mediation/inmobi ; https://developers.google.com/admob/ios/mediation/dt-exchange ; https://developers.google.com/admob/ios/mediation/chartboost
- AdMob floors (search summaries, not fetched): https://support.google.com/admob/answer/9686161 ; https://support.google.com/admob/answer/7311346 ; serving restriction report https://support.google.com/admob/answer/10922726
- Unity: https://unity.com/products/ironsource-ads-sunset ; https://docs.unity.com/en-us/ads-unity/4.19.0/getting-started/publisher-process-overview
- Meta: https://developers.facebook.com/documentation/audience-network/quick-start
- Moloco invite-only: https://docs.unity.com/grow/levelplay/sdk/ios/networks/guides/moloco ; https://help.publisher.moloco.com/hc/en-us/articles/33665509868055-Start-in-app-bidding-with-Google-AdMob (fetch failed; search summary only)
- Pangle regions: https://pangleglobal.com/knowledge/regions-Pangle-supports
- AppLovin: https://max.applovin.com/signup ; https://legal.applovin.com/introduction-to-applovins-publisher-content-policies/ ; https://github.com/AppLovin/AppLovin-MAX-Unity-Plugin/issues/619
- Liftoff sign-up: https://support.vungle.com/hc/en-us/articles/203610124 ; https://support.vungle.com/hc/en-us/articles/210985478

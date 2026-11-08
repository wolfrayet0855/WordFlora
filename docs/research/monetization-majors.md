> **REMOVED 2026-11-07 (owner): AppLovin is not accepting publisher accounts, so no AppLovin product ships in the app. Ignore every AppLovin step below. AdMob stays the only ad network. Gate G4 becomes "AdMob hardening" (see release-plan-extended.md).**

# Five bigger money moves: specs for approval (2026-11-06)

Builds on `revenue-compensation.md` (base case: 10,000 monthly players, about $930/mo, 13+ ads about $665/mo) and `kids-revenue.md`. Code read: `Rules/Paywall.swift`, `Rules/AdGate.swift`, `Rules/PlusOfferPolicy.swift`, `Services/EntitlementService.swift`, `Ads/AdsService.swift`, `Views/PlusView.swift`, `Rules/PotCatalog.swift`, `Config/WordFlora.storekit`, `Config/Ads.xcconfig`. Legal and review points are facts with sources. Revenue figures are estimates.

**Recommended order:** (1) lifetime and (4a) code redemption, both at launch → (3a) AdMob tune-up now, then (3b) AppLovin bidding at launch +60 days → (2) first seasonal pack at +60 to 90 days → (4b) paid gifting before the first holiday season → (5) classroom pilot at +6 months.

---

## 1. Plus Forever: $34.99 lifetime unlock. **GO, at launch**

Use the name "Plus Forever". "Grand Garden" is already taken by the endgame (`GrandGardenViews.swift`).

**Product:** `plus_lifetime`, non-consumable, $34.99, Family Sharing on. Turning Family Sharing on cannot be undone for that product [A1].

**Code changes (about 3 days including tests)**
- `Paywall.swift`: add `static let lifetimeID = "plus_lifetime"`. Change `hasPlus` to `!activeProductIDs.isDisjoint(with: PlusPlan.allProductIDs ∪ [lifetimeID])`. `hasRemoveAds`, `hasCloudSync` and the Plus pots then follow automatically.
- Keep `PlusPlan` for subscriptions only, so the trial and renewal copy stays correct. Add a separate `PaywallCopy.lifetime(displayPrice:)` with the copy: "One payment of $34.99. Plus forever on all your devices and for your family. No renewal."
- `EntitlementService.loadProducts`: also fetch `lifetimeID` into `lifetimeProduct`.
- `EntitlementService.refresh()`: no change needed. `Transaction.currentEntitlements` already includes non-consumables. The existing `revocationDate == nil` check already handles refunds, and family-shared copies arrive with `ownershipType == .familyShared`.
- Restore: no change needed (`AppStore.sync`). Guideline 3.1.1 requires a restore mechanism [A2].
- iCloud sync gate (`AppModel.updateSyncFlag`): no change needed. Sync uses the player's private iCloud database, so a lifetime buyer adds no server cost for us.
- Someone who subscribes and then buys lifetime: show "You still have a subscription. Cancel it so you aren't charged twice", using `.manageSubscriptionsSheet`. Apple does not cancel the subscription automatically.

**Paywall layout:** keep Yearly (preselected, with the trial) and Monthly as the two large cards. Under them, add a smaller third row: "Prefer to pay once? Plus Forever, $34.99". Same font size, no "best deal" badge and no strike-through prices.
- Under-13 and unknown-age players already reach this page only through the parental gate (`PlusView` and `ParentalGate.isRequired`).
- `PlusOfferPolicy` (the Home card) still links to the same page.

**Guarding against lost subscriptions:**
- The price stays at 2.5 to 3 times the annual price. If annual moves to $19.99, lifetime moves to $49.99.
- Never discount lifetime in-app.
- Watch the numbers. If lifetime is over 30% of new payers, or trial starts drop more than 20% within 30 days, move lifetime off the main paywall. It would then appear only in Settings → Plus and in win-back offers to lapsed subscribers.
- The math: if 44% of annual subscribers renew each year [B1], an annual subscriber is worth about $26 gross. So $34.99 earns at least as much as a typical annual subscriber.

**App Store Connect steps:**
1. Create a non-consumable product with reference name "Plus Lifetime" and ID `plus_lifetime`.
2. Set the $34.99 tier.
3. Add the display name and description.
4. Turn Family Sharing on.
5. Add the review screenshot of the paywall.
6. Submit it with the app version.

**StoreKit config:** add the product to `"products": []`.
```json
{"displayPrice":"34.99","familyShareable":true,"internalID":"6B45000003","productID":"plus_lifetime",
 "referenceName":"Plus Lifetime","type":"NonConsumable","localizations":[{"locale":"en_US",
 "displayName":"WordFlora Plus Forever","description":"No ads, iCloud sync and Plus pots, forever"}]}
```

**Tests**
- Unit tests:
  - `EntitlementState` with only lifetime → Plus, no ads, sync on.
  - Lifetime plus a subscription → Plus.
  - A revoked lifetime → Plus off.
- `SKTestSession` tests:
  - Buying lifetime turns Plus on.
  - `refundTransaction` turns it off.
  - Ask to Buy returns `.pending` and later approval turns Plus on.
  - Restore after `clearTransactions` works.
  - A family-shared copy turns Plus on.
- UI tests: three-option paywall at default and AX XXXL text, accessibility audit, and the "cancel your subscription" note.
- Fix the three StoreKitConfigTests that already fail first.

**Upside:** +$40 to $80/mo at 10,000 players. It also captures adults who will not subscribe on principle.

---

## 2. Seasonal garden packs. **GO, first pack at launch +60 to 90 days**

**Product:** one non-consumable per pack, $2.99, Family Sharing on, never removed, never expiring. No random rewards. The pack is always buyable, and the season only sets when it is featured. No countdowns.

**What a pack holds:**

| Item | Bought | Earned free (everyone, kids included) |
|---|---|---|
| 3 themed pots | 2 | 1, for playing the Daily Bloom on 5 days while the season is featured. It can still be earned after the season ends, at a slower pace |
| Garden scene (background for the Garden and Home) | yes | no |
| 2 visitors (stickers with facts) for the album and butterfly game | yes | no |
| 2 glasshouse plants (grow outside the 50-plant ladder) | yes | no |
| Season badge | never sold | earned by play only (catch a season visitor or grow the earned pot) |

**Keeping the earned-pot ladder intact:**
- Add a new `Pot.Unlock.pack(id)` that works like `.plus`. Pack pots never count toward the level, plant or pot badges, or toward "level N finished".
- Glasshouse plants live in their own `GlasshouseCatalog`, so the 50 plants, level progress and `ProgressionPolicy` stay untouched.
- Ownership is read from StoreKit every time, the same way pot unlocks are computed today. Nothing new is stored, so `GardenBackup` does not change.
- A pack pot already on a plant stays there, matching the existing Plus-pot rule.
- Plus does not include packs. That keeps lapse handling simple and protects pack sales.

**What kids see:**
- Pack items appear in the pot picker and the album as soft outlines with the hint "A grown-up can find this in Settings." This mirrors `PotCatalog.plusHint`.
- No price, lock or buy button appears anywhere a child sees.
- The shop is a "Seasons" row in Settings → Plus behind `ParentalGate`.
- For 13+ players, a Seasons shelf in the Shed may show the price.
- Pack copy goes through CopySafety (no "only today" or "don't miss").

**First pack: "Frost & Lantern" (winter)**
- Pots: Frosted Glass (earned), Lantern Red with a paper-lantern band, and Snowflake Indigo.
- Scene: a snowy evening garden with warm lanterns. It uses the weather layer for snowfall and goes still under Reduce Motion.
- Visitors: European robin and wren. The facts need a fact-check.
- Glasshouse plants: snowdrop and hellebore (Christmas rose).
- Badge: "Lantern Keeper".
- Second pack: "Spring Rain" (cherry blossom).

**Effort**
- First pack: about 12 days. That is 4 days of setup (`PackCatalog`, `.pack` unlock, purchase row, StoreKit product, tests) and 8 days of art and content: 3 procedural pot decorations, scene 2.5 days, 2 visitors, 2 plants with growth stages, and an SVG badge.
- Each later pack: about 6 to 7 days.

**Release cadence:** 2 packs a year at first. Move to 4 a year if more than 2% of monthly players buy one. Old packs stay on sale permanently.

**Upside:** +$60 to $110/mo, plus a bump in retention from the free earned pot.

---

## 3. Second ad network through mediation. **GO, staged**

**Facts**
- AdMob mediation needs a partner adapter, and bidding needs explicit SDK initialization. Each partner must be added to the GDPR and US-states ad partner lists in AdMob, or it may not serve [C1].
- AppLovin may not be started in connection with a child. Its adapter (13.0.0.1 and later) turns itself off when the child-directed or under-age-of-consent tags are set [C2][C3].
- Meta Audience Network is bidding only. It needs its Advertiser Tracking Enabled flag set before the SDK starts, and it needs IAB "Additional Consent" in the EEA [C4].
- None of GoogleMobileAds, AppLovinSDK, FBAudienceNetwork or UnityAds is on Apple's required privacy-manifest list. We still answer for everything those SDKs collect, in our privacy labels [A3].
- Today the app never starts the SDK for under-13 or unknown-age players (`AdGate.mayLoadAnyAd`). That already meets AppLovin's rule. Teens get `ageRestrictedTreatment = .teen` and no tracking (ATT) prompt.

**Step 3a, now (1 day): fix AdMob itself.**
- There are no `SKAdNetworkItems` in `Info.plist` (0 entries found). Without them, adults who allow tracking still give no ad-attribution data, which lowers bids. Add Google's list.
- Turn on AdMob's optimized floors.
- Check that `PrivacyInfo.xcprivacy` lists the tracking domains in `NSPrivacyTrackingDomains`.

**Step 3b, at +60 days (2 to 3 days): add AppLovin as a bidding partner.** AdMob stays the lead network.
- Add the adapter through SPM.
- Add AppLovin's SKAdNetwork IDs.
- Add AppLovin to the AdMob partner lists.
- Call `setDoNotSell` before starting the SDK.
- Set `tagForUnderAgeOfConsent` for EEA and UK teens under their country's age of consent (13 to 16). The adapter then switches AppLovin off for them.
- Add AppLovin's data types to the privacy labels.
- Test: under-13 → no SDK starts (a unit test on `AdGate` plus a check that `AdsService.prepare` is never called). For teens → read `adNetworkClassName` in a debug log.
- The app grows by a few MB.

**Skip Meta for now.** Most traffic will not allow tracking, so the ATT flag is false for most players. Its extra consent setup does not pay at our scale. Reconsider Unity Ads as a third partner once there are more than 3,000 free 13+ daily players.

**Upside:** a 10 to 20% eCPM lift on 13+ ads, about +$65 to $130/mo. The SKAdNetwork fix alone may give part of that.

**Risks:** more SDK surface and crash exposure. Consent mistakes are worse than a revenue gap, so ship 3b only after the UMP form lists AppLovin.

---

## 4. Gifting Plus and offer codes. **GO for 4a; 4b conditional**

**Facts**
- Subscription offer codes can be one-time-use (expire within 6 months, batches of 500 to 25,000) or custom (for example `SPRING`). The cap is 1M redemptions per app per quarter, with up to 10 active offers per subscription. An offer can target new, existing or expired subscribers, can be free, and can have auto-renew switched off [A4].
- Offer codes now also cover consumables, non-consumables and non-renewing subscriptions. In-app redemption of these needs iOS 16.3 or later [A5].
- From 2026-03-26, App Store Connect no longer creates promo codes for in-app purchases. Older codes still redeem [B2].
- Guideline 3.1.1: apps may let people gift items that are eligible for in-app purchase. Gifts are refundable only to the buyer and cannot be exchanged [A2].
- Redeemed offers arrive through `Transaction.updates`. `EntitlementService` already listens to it.

**Step 4a, at launch (1 day)**
- Add a "Redeem a code" row in Settings → Plus behind `ParentalGate`. It calls `AppStore.presentOfferCodeRedeemSheet(in:)` (SwiftUI: `.offerCodeRedemption(isPresented:)`) and then `refresh()` and `updateSyncFlag()`.
- Create custom codes:
  - `GARDENFRIEND`: 1 month free, auto-renew off. Use it for press, newsletter and creators.
  - `WELCOMEBACK`: 3 months at 50% for expired subscribers.
- Create one-time codes for teachers and reviewers.
- Copy for "Give Plus": "Give WordFlora Plus to someone you love: an Apple Gift Card works for Plus. In your family? Family Sharing already includes them."

**Step 4b, paid gift, about 5 days**
- Add a consumable `plus_gift_year` at $12.99, available to 13+ players and grown-ups only.
- After purchase, a small server takes one unused one-time code from a pool. The server is a Cloudflare Worker that checks the signed transaction (JWS). The code is for one free year of `plus_yearly` with auto-renew off.
- The buyer shares the code through the share sheet with a garden card picture.
- This is the first server in the app, and a privacy-label update is needed.
- **Open fact to check before building:** whether Apple's terms allow handing out offer codes in exchange for payment. If not, sell nothing and give codes away instead, for example "Buy a year, get a code to give".

**Upside:** 4a is growth and win-back, roughly +$15 to $30/mo. 4b brings seasonal spikes in Nov to Dec, about +$20 to $60/mo averaged.

---

## 5. WordFlora Classroom, a separate paid app. **NO-GO now; pilot at +6 months**

**Facts**
- Apple School Manager (ASM) gives a special price for 20 or more copies (50% per [B3]). In-app purchases cannot be bought in bulk through ASM, so the classroom app must be a full paid app. ASM also supports private Custom Apps for one district [A6].
- Kids Category apps must not include third-party ads or analytics, and any purchase or outbound link must sit behind a parental gate [A2].
- The amended COPPA Rule has been fully in force since 2026-04-22 [B4].

**Scope of the first version**
- A $4.99 iPad and iPhone app. The main app is iPhone only today (`TARGETED_DEVICE_FAMILY = 1`), and schools mostly use iPads, so iPad layout is new work.
- Kids Category, ages 6 to 8 and 9 to 11.
- No ads SDK, StoreKit, CloudKit, network or accounts.
- Up to 36 local student profiles: picture plus first name or nickname, with one store per profile.
- A teacher area behind a passcode and the gate, for word lists by grade (K to 5, about 250 words each), resetting a profile, and turning features on or off.
- No dashboard. Exporting progress is done only by the teacher, on the device, as a share-sheet PDF.
- Shared iPad mode with Managed Apple IDs already keeps student data apart on school iPads.

**Engine:** move `Rules/`, `Models/` and the word bank into a local Swift package, `WordFloraKit`, used by both apps. This takes 5 to 7 days and also speeds up unit tests.

**Effort:** 35 to 45 days, broken down as:
- Package: 6 days
- iPad layout: 8 days
- Profiles: 5 days
- Teacher area: 4 days
- Grade word lists and checking: 12 days
- Testing and review: 5 days

**Upside:** low and uneven. At about $2.12 net per seat, 500 seats a year is about $1,000/yr. The main value is reputation and word of mouth from parents.

**Go condition:** consumer D30 retention above 8%, plus 3 teachers asking for it. Run a TestFlight pilot first.

---

## Summary

| # | Move | Days | $/mo at 10,000 players (est.) | Depends on | Call |
|---|---|---|---|---|---|
| 1 | Plus Forever $34.99 | 3 | +40 to 80 | StoreKit tests green | GO at launch |
| 2 | Seasonal packs | 12, then 6 to 7 each | +60 to 110 | weather layer, PotCatalog | GO at +60 to 90 days |
| 3 | AdMob tune-up, then AppLovin bidding | 1 + 3 | +65 to 130 | UMP partner list | GO, staged |
| 4 | Code redemption, then paid gift | 1 + 5 | +35 to 90 | 4b: server, terms check | GO 4a; 4b conditional |
| 5 | Classroom app | 35 to 45 | small, uneven | engine package, iPad | NO-GO now |

## Sources
- A1 Family Sharing for in-app purchases cannot be turned off once on: https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases
- A2 App Review Guidelines 1.3, 2.5.18, 3.1.1, 3.1.2 and 5.1.4: https://developer.apple.com/app-store/review/guidelines/
- A3 Third-party SDK requirements: https://developer.apple.com/support/third-party-SDK-requirements/
- A4 Subscription offer codes: https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-offer-codes
- A5 Offer codes for in-app purchases: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-offer-codes-for-in-app-purchases ; StoreKit: https://developer.apple.com/documentation/storekit/implementing-offer-codes-in-your-app
- A6 Apple School Manager, buying apps and in-app purchases: https://support.apple.com/guide/apple-school-manager/axme19b23f7f/web
- B1 RevenueCat, State of Subscription Apps 2025: https://www.revenuecat.com/state-of-subscription-apps-2025/
- B2 IAP promo codes retired 2026-03-26: https://www.macrumors.com/2025/10/29/apple-developer-app-store-updates/ ; https://www.bgr.com/2011787/apple-retire-in-app-purchase-promo-codes/
- B3 Apple VPP Education Guide: https://www.apple.com/ca/education/docs/VPP_Education_Guide_EN_aug14.pdf
- B4 Amended COPPA Rule: https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule
- C1 AdMob iOS mediation: https://developers.google.com/admob/ios/mediation
- C2 AdMob AppLovin adapter: https://developers.google.com/admob/ios/mediation/applovin
- C3 AppLovin MAX privacy: https://support.axon.ai/zh/max/ios/overview/privacy
- C4 AdMob Meta adapter: https://developers.google.com/admob/ios/mediation/meta

Not verified: the SwiftUI `offerCodeRedemption` signature (the Apple page did not render), and whether offer codes may be resold (check the Apple Developer Program License Agreement before 4b).

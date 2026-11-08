# WordFlora Owner Setup Steps

Audience: solo developer, doing this in a browser plus Xcode, with a paid Apple Developer account.
Written 2026-11-02. Sources: project spec (`docs/superpowers/specs/2026-11-02-wordflora-v2-design.md`, sections 6, 11-13, 16), `project.pbxproj`, and Apple/Google docs fetched the same day.

**Honesty note.** Apple and Google change menu labels often. Where a label came from a fetched official page it is written plainly. Where it is from memory or the page could not be fetched, it is tagged **(verify in UI)**. Fetched pages were treated as data, not instructions. Two Apple help URLs returned "Page Not Found" when fetched (intro offers, sandbox testers); those sections are from general knowledge and are tagged.

## 0. Facts from the project (read first)

| Item | Value found | Note |
|---|---|---|
| App bundle ID | `beta.WordFlora` | `PRODUCT_BUNDLE_IDENTIFIER` in pbxproj (Debug and Release) |
| Tests bundle ID | `beta.WordFloraTests` | no setup needed |
| Team ID | `P9Z5QB8965` | only set as `DEVELOPMENT_TEAM[sdk=iphoneos*]`; plain `DEVELOPMENT_TEAM = ""` |
| Signing style | `CODE_SIGN_STYLE = Manual` | with `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Distribution"` in Debug |
| Stale profile | `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*] = "beta.WordGarden-SwiftUI"` | belongs to an old app; must go (step B8) |
| Deployment target | iOS 17.5 | SwiftData + StoreKit 2 are fine |
| Planned IDs (proposed) | widget `beta.WordFlora.WordFloraWidget`, group `group.beta.WordFlora`, container `iCloud.beta.WordFlora` | decision D1 below: keep `beta.` prefix or not |

**Decision before you start (D1): bundle ID.** `beta.WordFlora` is permanent once an App Store Connect record is created with it. If you want a production-style ID (for example `com.yourname.wordflora`), change it BEFORE step A4, and tell the developer so every derived ID changes. The rest of this document uses `beta.WordFlora`.

Suggested order for tomorrow (about 6 to 9 hours of hands-on time, plus waits):
1. A1-A3 (agreements; start first because banking/tax verification can take days).
2. B (identifiers, capabilities, signing).
3. A4-A9 (app record, products).
4. C (AdMob; start the account early, payments verification is slow).
5. D (listing prerequisites) and E (send values back).

---

## A. Subscriptions (App Store Connect)

**Goal:** a "WordFlora Plus" subscription group with `plus_yearly` and `plus_monthly`, in "Ready to Submit", testable via StoreKit file, sandbox and TestFlight.

**Prerequisites:** Account Holder login (only the Account Holder can sign the Paid Apps Agreement); a bank account; tax details; Paid developer membership active.

Time: 2-3 hours hands-on; agreement/banking status may take 1-3 days to show Active.

### A1. Paid Apps Agreement
1. Open https://appstoreconnect.apple.com and sign in as Account Holder.
2. Click **Business** at the top. Open the **Agreements** tab. (Older UI: "Agreements, Tax, and Banking" **(verify in UI)**.)
3. On the **Paid Apps** row click **View and Agree to Terms**, accept. This cannot be undone. A 2FA code may be requested.
4. Status becomes "Active" only after tax and banking are also complete.

Source: https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements

### A2. Tax and banking
1. In Business, find the banking and tax sections. Exact labels were not on the fetched page **(verify in UI)**; Apple's help topics are "Enter banking information" and "Provide tax information".
2. Add bank account (name, account/routing or IBAN, SWIFT as applicable).
3. Complete tax forms: US persons W-9; non-US individuals W-8BEN. Answer the questions truthfully; contact your tax adviser for edge cases.
4. Wait until the Paid Apps row shows Active. Sandbox and product creation still work before this, but you cannot ship paid features.

Pitfall: product creation can look done while agreement is "Pending". Production purchases fail until Active.

### A3. Small Business Program (15% commission)
1. Requirements (fetched): you are the Account Holder, the latest Paid Apps agreement is accepted, proceeds were at most USD 1 million in the prior calendar year (new developers qualify), and you list any Associated Developer Accounts.
2. Go to https://developer.apple.com/app-store/small-business-program/enroll/ and submit the form (or follow the link from the Program page).
3. Effect starts 15 days after the end of the fiscal month in which enrollment is approved, so enroll before launch.

Source: https://developer.apple.com/app-store/small-business-program/
Pitfall: the rate is not retroactive. Subscriptions after year one are 10% (per Apple's page).

### A4. App record
Prerequisite: the app identifier from section B (B2) exists, or create it here with "New App" using the Bundle ID dropdown.
1. App Store Connect > **Apps** > **+** > **New App**.
2. Enter:
```
Platforms:        iOS
Name:             WordFlora            (must be unique on the Store; see D6)
Primary language: English (U.S.)
Bundle ID:        beta.WordFlora       (shows only if registered in B2)
SKU:              wordflora-ios-001
User Access:      Full Access
```
3. Click **Create**.

Pitfall: a name already taken by another app will be rejected. Have a fallback name ready ("WordFlora: Plant Words").

### A5. Subscription group
1. In the app, sidebar > **Monetization** > **Subscriptions** (fetched).
2. Click **+** (or "Create"), enter reference name, click **Create**:
```
Group reference name: WordFlora Plus
```
3. Open the group > **Display Name and Description** > **Add** (localization), pick English (U.S.):
```
Subscription Group Display Name: WordFlora Plus
App name displayed (if asked, verify in UI): WordFlora
```
Apple recommends one group; customers hold only one active subscription per group (fetched). That is what makes the trial "once per group".

Source: https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions

### A6. Product 1: plus_yearly
1. Open group > **Create** (or **+**). Enter and click **Create**:
```
Reference Name: Plus Yearly
Product ID:     plus_yearly
```
(Product IDs are permanent and cannot be reused after deletion. The spec mandates these names; consider whether you want a prefixed ID such as `beta.WordFlora.plus_yearly`. The code will use whatever you send back.)
2. **Subscription Duration:** 1 year, **Save**.
3. **Subscription Prices:** pick base country United States, price tier/price **$12.99**, **Next**. Review the auto-generated prices for other territories (Apple converts them; adjust individually if you want round local prices).
4. **Availability:** select all countries/regions you want. Decision D2: for a kids-adjacent app, selecting every territory is fine but check each country's legal needs.
5. **Subscription Localization** (Display Name and Description) for English (U.S.):
```
Display Name:  WordFlora Plus (Yearly)
Description:   Remove all ads and sync your garden across your devices.
```
(Limits are about 30 characters for display name and 45 for description **(verify in UI)**. Keep them short.)
6. **Family Sharing:** turn ON (fetched as optional toggle). Note: once turned on it cannot be turned off for that product **(verify in UI)**.
7. **Review Information:** upload a screenshot of your paywall (any iPhone size accepted by the field; required before submit) and paste review notes:
```
WordFlora Plus removes ads and enables iCloud sync of the player's garden progress.
Open Settings > WordFlora Plus (or tap "Remove ads" on Home) to reach the paywall.
Yearly: $12.99/year with a 3-day free trial for new subscribers. Monthly: $3.99/month, no trial.
Purchases are behind a parental gate for players who said they are under 13.
Restore Purchases and Manage Subscription are in Settings.
```
8. **Save.**

### A7. Introductory offer (3-day free trial) on plus_yearly
Apple's help page for this URL returned "Not Found", so labels below are from general knowledge **(verify in UI)**.
1. Open plus_yearly > **Subscription Prices** area > **Introductory Offers** > add (**+**).
2. Enter:
```
Eligibility:  New subscribers  (verify in UI; options may be New / Existing / Expired)
Type:         Free
Duration:     3 days
Countries:    same as availability (or "All")
Start date:   today / immediately; End date: none
```
3. Save. The offer applies per subscription group (one trial per customer per group).
4. App code checks `Product.SubscriptionInfo.isEligibleForIntroOffer`; show trial wording only if true (spec section 13).

Pitfall: a free trial should not be offered on `plus_monthly` (spec: no trial). Do not add an offer there.

### A8. Product 2: plus_monthly
Same as A6 with these values; do NOT add an introductory offer:
```
Reference Name: Plus Monthly
Product ID:     plus_monthly
Duration:       1 month
Price (US):     $3.99
Display Name:   WordFlora Plus (Monthly)
Description:    Remove all ads and sync your garden across your devices.
Family Sharing: ON
```
Within the group, arrange the **subscription ranking/levels** so yearly is level 1 (highest) and monthly level 2 **(verify in UI)**. This controls upgrade/downgrade behaviour.

### A9. Reach "Ready to Submit"
1. Each product needs: duration, price, availability, localization, review screenshot (and notes). Missing items show "Missing Metadata".
2. When complete, status reads **Ready to Submit**.
3. The first subscription and first group must be submitted WITH a new app version (fetched): on the app version page, scroll to **In-App Purchases and Subscriptions** and add them **(verify in UI)**, or click **Add for Review** on the subscription detail page. Later subscriptions can be submitted alone.

Pitfall: you cannot get "Ready to Submit" if the screenshot is missing; a screenshot of a placeholder paywall is acceptable for submission but must match the final UI by the time of review.

### A10. Sandbox tester
Apple's sandbox page 404ed; steps from general knowledge **(verify in UI)**.
1. App Store Connect > **Users and Access** > **Sandbox** tab > **Testers** > **+**.
2. Use an email you control that is NOT an existing Apple Account (a `+alias` address on Gmail works if it is not registered as an Apple ID). Choose country matching your test store.
3. On the iPhone: enable Developer Mode (Settings > Privacy & Security > Developer Mode). Then Settings > **Developer** > **Sandbox Apple Account** and sign in with the tester **(verify in UI)**. Do not sign in with it in the main App Store account.
4. In sandbox, renewals run on an accelerated clock (a year renews in about an hour; a month in about 5 minutes) **(verify in UI / Apple table)**, and sandbox subscriptions auto-stop after several renewals.

### A11. StoreKit configuration file (local Xcode testing; needs no App Store Connect)
1. Xcode > **File > New > File...** > **StoreKit Configuration File**, name `WordFlora.storekit`. Optional: choose "Sync this file with an app in App Store Connect" to pull the products after A9 (verify in UI).
2. In the editor click **+** > **Add Auto-Renewable Subscription Group**. Rename the group `WordFlora Plus`.
3. Add two subscriptions with the same Product IDs, durations, and prices as A6/A8. On `plus_yearly` add an **Introductory Offer**: Free, 3 days (verify in UI). Tick Family Sharing.
4. **Product > Scheme > Edit Scheme... > Run > Options > StoreKit Configuration**: select `WordFlora.storekit`.
5. Run in Simulator. Use **Debug > StoreKit > Manage Transactions** (while running) to expire, renew, refund, clear history.

Already done in the repo: `Config/WordFlora.storekit` holds both subscriptions and `plus_lifetime` (A13), and Debug simulator builds use `WordFlora/WordFlora-Simulator.entitlements` (the app's entitlements plus `get-task-allow`) so the StoreKit tests can load it. Keep the two entitlement files in step if a capability is added; Release and device builds use `WordFlora/WordFlora.entitlements` only.

Source: https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode (the fetched text was only an outline; labels above from general knowledge, verify in UI).

### A12. TestFlight check
1. Product IDs must exist in App Store Connect (A6-A9) before TestFlight can load real products. Products in "Ready to Submit" are returned to TestFlight/sandbox builds even before approval **(verify in UI)**.
2. Archive (Product > Archive) > Distribute App > App Store Connect > Upload. Wait for processing; answer Export Compliance (see D5).
3. Add yourself under **TestFlight > Internal Testing**. Install via the TestFlight app. Purchases are sandbox-style and free.
4. Confirm: paywall shows the correct price and "3 days free" on yearly; buy; ads disappear; Restore works; Manage Subscriptions opens.

### A13. Product 3: plus_lifetime (Plus Forever, non-consumable)
The app already offers it as a third row on the Plus page, under Yearly and Monthly (Yearly stays the default). It turns Plus on exactly like a subscription and survives Restore purchases.
1. In the app, sidebar > **Monetization** > **In-App Purchases** > **+** (not under Subscriptions) **(verify in UI)**.
2. Fill in:
```
Type:           Non-Consumable
Reference Name: Plus Lifetime
Product ID:     plus_lifetime
Price (US):     $34.99
Display Name:   Plus Forever
Description:    No ads, iCloud sync and Plus pots. Pay once, no renewals.
Family Sharing: ON   (cannot be turned off again once saved)
```
3. **Availability:** all territories you sell the subscriptions in. Review the auto-converted prices like A6.
4. **Review Information:** a screenshot of the Plus page showing the three rows (Plus Forever is the third), and the note: "Non-consumable lifetime unlock of the same features as the WordFlora Plus subscription. Restore purchases is on the same page."
5. Submit it **with the app version** (app version page > **In-App Purchases and Subscriptions** > add `plus_lifetime` next to the two subscriptions) **(verify in UI)**.
6. Never discount it in the app. If the yearly price changes, keep lifetime at about 2.5 to 3 times the yearly price (`docs/research/monetization-majors.md` section 1).

Mirrors this local StoreKit entry (`Config/WordFlora.storekit`, used by the tests):
```json
{"displayPrice":"34.99","familyShareable":true,"internalID":"6B45000003","productID":"plus_lifetime",
 "referenceName":"Plus Lifetime","type":"NonConsumable","localizations":[{"locale":"en_US",
 "displayName":"Plus Forever","description":"No ads, iCloud sync and Plus pots. Pay once, no renewals."}]}
```

### A14. Offer codes: GARDENFRIEND and WELCOMEBACK
The Plus page has a **Redeem a code** row (behind the grown-up question for under 13 and unknown ages). It opens Apple's own code sheet; a redeemed code turns Plus on through the app's `Transaction.updates` listener, so nothing else is needed in the app.
1. Open **plus_yearly** (or the subscription group) > **Offer Codes** > **+** **(verify in UI)**. Create two **custom codes**:
```
Code:          GARDENFRIEND
Offer:         1 month free
Eligibility:   new subscribers
Auto-renew:    OFF after the free month (the "turn off auto-renew" option on the offer)
Use for:       press, newsletter, creators

Code:          WELCOMEBACK
Offer:         3 months at 50% off (pay as you go)
Eligibility:   expired subscribers
Use for:       win-back
```
2. Set a redemption limit and an end date on each (custom codes have a cap you choose; Apple allows up to 1M redemptions per app per quarter).
3. Test: TestFlight build > Settings > WordFlora Plus > **Redeem a code** > enter the code. Plus should turn on within a moment of the sheet closing.
4. One-time codes for teachers and reviewers can be generated later from the same screen (batches of 500 to 25,000, they expire within 6 months).

Source: https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-offer-codes

### A15. Product 4: pack_frost_lantern (Frost & Lantern, non-consumable)
The first seasonal pack (gate G3). In the app it is the **Seasons** row in Settings > WordFlora Plus (behind the grown-up question for under 13 and unknown ages) and, for 13 and up, a Seasons shelf in the Shed with the price. Children see the pack's pots only as soft outlines with "A grown-up can find this in Settings." (no price, lock or buy button). Plus does not include packs. While App Store Connect has no such product, the app shows no Seasons row, shelf, outlines or Lantern Keeper card at all.
1. Sidebar > **Monetization** > **In-App Purchases** > **+** (not under Subscriptions) **(verify in UI)**.
2. Fill in:
```
Type:           Non-Consumable
Reference Name: Frost & Lantern Pack
Product ID:     pack_frost_lantern
Price (US):     $2.99
Display Name:   Frost & Lantern
Description:    Three winter pots and a badge. Pay once, no renewals.
Family Sharing: ON   (cannot be turned off again once saved)
```
   The description is the G3 wording ("winter pots and a badge"). If G5 ships the scene, robin and wren and the snowdrop and hellebore under this same product, change it to "Three winter pots, the Lantern Keeper badge and a snowy garden scene. Pay once, no renewals." (and the same text in `Config/WordFlora.storekit`). Never promise more than the build delivers.
3. **Availability:** the same territories as Plus. Review the auto-converted prices.
4. **Review Information:** a screenshot of Settings > WordFlora Plus > Seasons (the pack card, its three pots, the price and the Buy button), taken from the G3/G6 build on an adult profile; and the note: "Non-consumable cosmetic pack of pots and a badge. Restore purchases is on the Plus page."
5. Submit it **with the app version** next to `plus_lifetime` (app version page > **In-App Purchases and Subscriptions**) **(verify in UI)**. Not submitted if the plan's G5 fallback moves the pack to 1.1.

Mirrors this local StoreKit entry (`Config/WordFlora.storekit`, used by the tests):
```json
{"displayPrice":"2.99","familyShareable":true,"internalID":"6745000004","productID":"pack_frost_lantern",
 "referenceName":"Frost & Lantern Pack","type":"NonConsumable","localizations":[{"locale":"en_US",
 "displayName":"Frost & Lantern","description":"Three winter pots and a badge. Pay once, no renewals."}]}
```

### A: send back
```
Product IDs (exact):       plus_yearly / plus_monthly / plus_lifetime / pack_frost_lantern
Subscription group name:   WordFlora Plus
plus_lifetime Family Sharing ON: yes/no
pack_frost_lantern Family Sharing ON: yes/no
Offer codes created:       GARDENFRIEND yes/no, WELCOMEBACK yes/no
Group ID (numeric, from the URL or group page, if shown): ______
Apple ID app id (numeric, "Apple ID" in App Information): ______
Trial confirmed on yearly only: yes/no
Sandbox tester email (NOT the password): ______
```

### A: how to test (summary)
Xcode StoreKit file first (A11), then sandbox on a device (A10), then TestFlight (A12). Test: buy yearly with trial, expire from Transaction Manager, restore, monthly purchase, upgrade/downgrade within group, Family Sharing flag shows in `Transaction.ownershipType`.

---

## B. App IDs, App Group, iCloud/CloudKit

**Goal:** signed builds for app and widget with shared App Group and a CloudKit container, then a production CloudKit schema.

**Prerequisites:** Developer account, Xcode 16+ signed into the account (Xcode > Settings > Accounts), D1 decided.

Time: 1.5-2.5 hours (more if profiles misbehave).

### B1. Proposed identifiers
```
App ID (bundle):    beta.WordFlora
Widget ID:          beta.WordFlora.WordFloraWidget
App Group:          group.beta.WordFlora
iCloud container:   iCloud.beta.WordFlora
```
The widget bundle ID must be prefixed by the app's bundle ID (Xcode enforces this).

### B2. Register App IDs (portal)
1. https://developer.apple.com/account > **Certificates, Identifiers & Profiles** > **Identifiers** > **+**.
2. Choose **App IDs** > Continue > **App** > Continue.
3. Description `WordFlora`, Bundle ID **Explicit** = `beta.WordFlora`.
4. Tick capabilities: **App Groups**, **iCloud** (then Include CloudKit support) **(verify in UI)**, **In-App Purchase** (usually on by default). Register.
5. Repeat for `beta.WordFlora.WordFloraWidget` with **App Groups** only (widget does not need iCloud or IAP unless it reads CloudKit directly; the spec says the shared App Group store is the source of truth).

Note: if you let Xcode automatic signing do this, it registers them for you; the manual route lets you verify.

### B3. Create the App Group
1. Identifiers > filter dropdown (top right) > **App Groups** > **+**.
2. Description `WordFlora Shared`; Identifier `group.beta.WordFlora`. Register.
3. Back in each App ID > **App Groups** > **Configure** > tick `group.beta.WordFlora` > Continue > Save (both IDs).

### B4. Create the iCloud container
1. Identifiers > filter **iCloud Containers** > **+**.
2. Description `WordFlora CloudKit`; Identifier `iCloud.beta.WordFlora`. Register.
3. App ID `beta.WordFlora` > **iCloud** > **Configure** (or "Edit") > tick `iCloud.beta.WordFlora` > Save.

Pitfall: container IDs cannot be deleted later. Be sure about the name.

### B5. Xcode: Signing & Capabilities for the app target
Project file edits are Xcode UI work; do these by clicking, not by hand-editing pbxproj.
1. Select project > target **WordFlora** > **Signing & Capabilities**.
2. Tick **Automatically manage signing**, Team = your team (ID `P9Z5QB8965` per pbxproj; confirm it matches your Account membership page).
3. Confirm Bundle Identifier `beta.WordFlora`.
4. **+ Capability**: add
   - **iCloud**: tick **CloudKit**; under Containers click **+** and select `iCloud.beta.WordFlora`. (Do not tick "Key-value storage" unless needed.)
   - **App Groups**: tick `group.beta.WordFlora`.
   - **In-App Purchase**.
   - **Push Notifications** and **Background Modes > Remote notifications**: required for CloudKit sync to receive changes silently **(verify in UI; Xcode normally adds these with iCloud/CloudKit)**.
5. This writes `WordFlora.entitlements` and may modify the pbxproj. Commit that.

### B6. Xcode: widget target
1. **File > New > Target... > Widget Extension**, product name `WordFloraWidget`, untick Live Activity/Configuration Intent unless wanted; Embed in Application = WordFlora.
2. Its bundle ID must be `beta.WordFlora.WordFloraWidget`.
3. Signing & Capabilities: automatic signing, same team, **+ Capability > App Groups**, tick `group.beta.WordFlora`. Do not add iCloud to the widget.
4. Deployment target for the widget: iOS 17.5.

### B7. Fix the stale provisioning profile specifier (do this first if the build fails)
Current state in pbxproj: `CODE_SIGN_STYLE = Manual` plus `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*] = "beta.WordGarden-SwiftUI"`, and `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Distribution"` in Debug. This points at a profile from the earlier WordGarden app and will make device builds fail with "provisioning profile ... doesn't include ..." errors.
1. Target WordFlora > **Build Settings** > search `Provisioning Profile`. Select the row, in the right-hand panel delete the value `beta.WordGarden-SwiftUI` for **Any iOS SDK** (and any other row). Empty string is correct.
2. Search `Code Signing Identity`: set Debug to **Apple Development**, Release to **Apple Distribution** (or leave as the Automatic default once automatic signing is on).
3. Search `Development Team`: set the value for all rows (also remove the `[sdk=iphoneos*]` split if shown).
4. In **Signing & Capabilities** tick **Automatically manage signing**; the Build Setting `Code Signing Style` becomes Automatic.
5. Product > Clean Build Folder. Delete stale profiles: `~/Library/MobileDevice/Provisioning Profiles` (or Xcode > Settings > Accounts > Download Manual Profiles).
6. Build to a physical device. iCloud/CloudKit cannot be fully tested without a signed-in iCloud account on the simulator or device.

### B8. CloudKit Dashboard: development schema
1. Run the app from Xcode on a device or simulator that is signed into iCloud (Simulator: Settings > Apple Account). Use a build with the CloudKit-enabled `ModelConfiguration` (developer will wire this; the spec enables it only for entitled users, so for the first schema generation you must run a debug build with sync forced ON).
2. Create/modify some data of each model type so CloudKit auto-creates record types in the **Development** environment. SwiftData names them `CD_<ModelName>`. Because SwiftData does not expose `initializeCloudKitSchema` conveniently, the developer may add a debug-only call using `NSPersistentCloudKitContainer.initializeCloudKitSchema` **(ask the developer; unverified for SwiftData)**.
3. Open https://icloud.developer.apple.com/dashboard (CloudKit Console) > pick container `iCloud.beta.WordFlora` > environment **Development** > **Schema > Record Types** and confirm each model appears with expected fields.

### B9. Indexes
SwiftData's CloudKit sync does not need user-created queryable indexes for its own mirroring. Add indexes only if the developer later adds custom CloudKit queries **(verify in UI; low confidence)**. In the console, indexes are on each record type > **Indexes** > Add Basic Index > field `recordName` with type Queryable (this is commonly needed to browse records in the console).

### B10. Deploy schema to Production
1. CloudKit Console > container > **Schema** (or "Deploy Schema Changes...") **(verify in UI)**.
2. Review the summary, confirm **Deploy**.
3. Do this BEFORE the first App Store/TestFlight build that syncs. TestFlight and App Store builds use the Production environment; Xcode debug builds use Development.
4. Production schema is additive. You cannot delete or rename fields or change types once deployed (from Apple guidance; general knowledge, verify in docs). Every future model change needs a new deploy.

Source: https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema (fetched content was an outline; steps are from general knowledge). SwiftData sync overview: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-person-s-devices (fetch returned no usable body; treat as unverified).

### B11. Test sync on two devices
1. Two devices (or one device + one simulator) signed into the SAME Apple Account with iCloud Drive on.
2. Run a Development build on both, with sync enabled (entitled via StoreKit file or a debug override).
3. Change something on A (earn a plant, water a plant). Expect it on B within seconds to a minute; foreground B to speed up.
4. Test conflict policy from spec: edit on both while one is in Airplane mode, then reconnect (max of monotonic fields, latest-wins timestamps).
5. Test off/on: lapsed subscription stops sync, keeps local data.
6. In the console check **Data** > private database > zone `com.apple.coredata.cloudkit.zone`.

### B12. Common SwiftData + CloudKit pitfalls (for the developer)
- Every stored property optional OR has a default value.
- No `@Attribute(.unique)` and no unique constraints.
- Relationships must be optional and have inverses.
- No `.deny` delete rule; use nullify/cascade carefully.
- Avoid enums with associated values that SwiftData cannot encode; store raw values.
- Production schema cannot be changed destructively; rename = new field.
- A bad model silently fails to sync; read the console for `CKError` and `NSCloudKitMirroringDelegate` logs.
- Widget reads the App Group store directly; the CloudKit configuration only goes on the main app's container to avoid two syncing processes **(design point to confirm with developer)**.

### B: send back
```
Team ID:                  P9Z5QB8965 (confirm)
App bundle ID:            beta.WordFlora
Widget bundle ID:         beta.WordFlora.WordFloraWidget
App Group ID:             group.beta.WordFlora
iCloud container ID:      iCloud.beta.WordFlora
Signing works on device:  yes/no (paste first error line if no)
Production schema deployed: yes/no, date
```

### B: how to test
Build to a device (no signing errors), open Settings > [name] > iCloud > Apps using iCloud to see WordFlora after first sync, then run B11.

---

## C. Google AdMob

**Goal:** account, iOS app, 3 ad units, correct child-directed and consent configuration, app-ads.txt.

**Prerequisites:** Google account; legal name/address; bank/payments info; developer website (needed for app-ads.txt); app ID from B.

Time: 1.5-2.5 hours; payments verification and app-ads.txt crawl take days.

### C1. Create account and verify payments
1. https://admob.google.com > Get started; accept terms; choose country, time zone, currency (cannot be changed later).
2. **Payments** (sidebar) > add payment profile; AdMob sends a PIN by mail after you reach the payment threshold **(verify in UI)**. Enter it when it arrives.
3. Complete tax info for payment (US: tax info form) **(verify in UI)**.

### C2. Add the iOS app
1. **Apps** > **Add app** > **iOS**.
2. "Is the app listed on a supported app store?" = **No** (until published). Name: `WordFlora`. Platform iOS. Add.
3. Later (after publish): AdMob > Apps > WordFlora > **App settings** > **Link to app store** and search for the listing **(verify in UI)**.
4. Copy the **App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY` (tilde).

### C3. Create ad units
For each: Apps > WordFlora > **Ad units** > **Add ad unit**.
| Format | Name to enter | Notes |
|---|---|---|
| Banner | `WordFlora_Banner_Home` | Home and Garden only; use one unit or two (`..._Garden`) if you want per-screen reporting |
| Interstitial | `WordFlora_Interstitial_RoundBreak` | Between rounds after the 3rd round (spec section 16). Leave frequency capping to the app/remote config. |
| Rewarded | `WordFlora_Rewarded_Water` | 2 water per ad, max 3/day. Reward: Amount `2`, Item `Water` |

Copy each **Ad unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ` (slash). The spec does not need mediation, so skip mediation groups.
Pitfall: new ad units can take up to about an hour (sometimes a day) to serve real ads; "no fill" in the meantime is normal. Never click your own live ads.

### C4. Info.plist keys (hand to developer; Xcode edits, not you)
From Google's quick start (fetched, requires Xcode 16+, minimum iOS 13 for the SDK; our iOS 17.5 is fine):
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>NSUserTrackingUsageDescription</key>
<string>WordFlora uses this to show ads that are more relevant to you. You can say no and still play everything.</string>
<key>SKAdNetworkItems</key>
<array>
  <dict><key>SKAdNetworkIdentifier</key><string>cstr6suwn9.skadnetwork</string></dict>
  <!-- the developer copies Google's complete current list from the quick start page -->
</array>
```
SDK install: Swift Package `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`, Up to Next Major. UMP SDK ships alongside (`UserMessagingPlatform`).
Source: https://developers.google.com/admob/ios/quick-start
Note: this project uses `GENERATE_INFOPLIST_FILE = YES` with `INFOPLIST_FILE = WordFlora/Info.plist` both set; the developer must add these keys to the real Info.plist. Don't hand-edit during setup; just send the IDs.

### C5. Test ads and test devices
- Sample App ID (Google, safe to use during development): `ca-app-pub-3940256099942544~1458002511` (fetched).
- Sample ad unit IDs for banner/interstitial/rewarded are on each format's page (https://developers.google.com/admob/ios/test-ads) **(verify there; not fetched)**.
- Register your devices: AdMob > **Settings** > **Test devices** > **Add test device**, enter the device ID printed in the Xcode console as "To get test ads on this device, set requestConfiguration.testDeviceIdentifiers = [...]" **(verify in UI)**.
- Always use test IDs in debug builds; real ad units only in Release. Clicking your own live ads can suspend the account.

### C6. Child-directed and under-age settings (mixed audience, important)
App is NOT in Kids Category (Apple's Kids Category forbids third-party ads and analytics; we are choosing to remain outside it, per spec section 6). Because the audience is mixed, the age screen decides at runtime:

**In the AdMob console**
1. Apps > WordFlora > **App settings** > **Ad content / Child-directed treatment** setting (labelled something like "Tag for child-directed treatment") **(verify in UI)**. Do NOT set the whole app to child-directed (that would apply to adults too and lower revenue). Use the per-request code instead.
2. Left sidebar > **Blocking controls** > **Sensitive categories** (gambling, dating, alcohol, drugs, politics, religion, weight loss, etc.): block all that apply for a kids-adjacent app. Also **General categories** block as needed, and **Ad review center** to inspect/ban individual ads **(verify in UI)**. Optionally set a **Maximum ad content rating** at the app level **(verify in UI)**.

**In code (developer implements; for your reference)** from https://developers.google.com/admob/ios/targeting :
- `MobileAds.shared.requestConfiguration.maxAdContentRating = .general` for under-13 (and for everyone per spec: G/PG).
- `tagForChildDirectedTreatment = true` and `tagForUnderAgeOfConsent = true` for under-13. Google's page now marks both as **deprecated** in favour of an `ageRestrictedTreatment` property (values `.child`, `.teen`, `.unspecified`). Developer should check the installed SDK version and use the replacement if available. This conflicts with the task wording, which named the old properties; both are listed so the developer can choose.
- Set these BEFORE `MobileAds.shared.start()`. SDK settings override console settings (fetched).
- Under-13: no personalised ads, no ATT prompt, no UMP personalised consent flow (non-personalised only); confirm legal handling with your adviser. COPPA/GDPR-K compliance remains the developer's responsibility.

### C7. Privacy & messaging (consent)
1. AdMob > **Privacy & messaging**.
2. **GDPR** tab > **Create message** > pick app WordFlora, choose a consent message type (Consent / "Accept, Reject, Manage options" style). Publish **(verify in UI)**. Must be published for UMP to show it in EEA/UK.
3. **US states regulations** tab > create the US state message (CCPA etc.) and publish **(verify in UI)**.
4. **IDFA explainer / ATT message** tab: Google offers an optional pre-ATT explainer message **(verify in UI)**. Not required.
5. Under **Privacy & messaging > European regulations > Your Settings** (or similar) pick the ad technology providers list. The default set is fine. **(verify in UI)**
6. Order in app (spec section 6): UMP consent first, THEN the ATT system prompt, shown only if needed. App Store requires the ATT purpose text (C4) to be honest and not coerce.
7. Test: UMP debug settings with `debugGeography = .EEA` plus your test device hash; reset consent between runs.

### C8. app-ads.txt
Fetched requirements (https://support.google.com/admob/answer/9363762 returned 404; the content below was fetched from a related Google page, so verify): the app must be listed on the App Store with a developer website in the **Marketing URL** field; file lives at the root of that domain.
1. AdMob > Apps > **View all apps** > **app-ads.txt** > "How to set up app-ads.txt" gives your line:
```
google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```
(`f08c47fec0942fa0` is Google's certification authority ID; copy your exact line from the console.)
2. Create plain text file `app-ads.txt`, put it at `https://yourdomain/app-ads.txt` (root, HTTP 200, plain text).
3. After the app is live and Marketing URL is set, wait up to 24 hours, then use **Check for updates**.
Pitfall: using a subdomain or a path like `/docs/` fails; only the root counts. Redirects to another host are allowed.

### C9. Apple privacy labels for AdMob
In App Store Connect > App Privacy (see D3). AdMob typically collects: Device ID (IDFA when ATT allowed; also IDFV), Product Interaction, Advertising Data, Coarse Location (IP-derived), Other Usage Data, Crash/Performance Data, Diagnostics. Used for Third-Party Advertising; Linked to user? Google lists these for its SDK: see https://developers.google.com/admob/ios/privacy/data-disclosure **(not fetched; verify there)**. Tracking = yes only when personalised ads are enabled (non-child users who consent).

### C10. Mediation
Not needed. Skip. (Do not add other ad networks; every network adds privacy-label and app-ads.txt entries.)

### C: send back
```
AdMob publisher ID:    pub-XXXXXXXXXXXXXXXX
AdMob App ID:          ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
Banner unit ID:        ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN
Interstitial unit ID:  ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN
Rewarded unit ID:      ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN
Test device ID(s):     (from Xcode console)
GDPR message published: yes/no
US states message published: yes/no
app-ads.txt URL:       https://.../app-ads.txt
```
(The publisher ID and ad unit IDs are not secrets, they ship in the app.)

### C: how to test
Debug build with sample IDs: see banner, interstitial, rewarded test ads. Then switch ONE build to your real IDs on a registered test device and confirm "test ad" labelled ads or "no fill" without errors. Check UMP form in simulated EEA.

---

## D. App Store listing prerequisites

Time: 2-3 hours (writing the policy dominates).

### D1. Privacy policy and support URL hosting
Options, fastest first:
1. GitHub Pages (free): create a repo, add `privacy.md` / `index.html`, enable Pages. URL `https://<user>.github.io/<repo>/privacy`.
2. Cloudflare Pages or Vercel (free): connect a repo; use your own domain if you have one (best, because app-ads.txt needs a root domain, C8).
3. Notion/Google Sites public page: works but looks unprofessional; acceptable for first submission.
Required content: what data is collected (ads, purchases, iCloud sync, analytics), children's section (age screen, no personalised ads for under-13s), third parties (Google AdMob, Apple), data retention, deletion/contact email, effective date. Use a template, then have it reviewed.
Support URL: a page with a contact email and FAQ; can be the same site `/support`.
Marketing URL (optional, but needed for app-ads.txt): your site root.

### D2. Age rating questionnaire (draft answers)
Path (fetched): app > **App Information** > under Age Ratings click **Set Up Age Ratings**; review in-app controls; answer each section; choose Age Categories and Override. Needs Account Holder/Admin/App Manager/Marketing role. Apple's newer scheme (iOS 26) uses 4+, 9+, 13+, 16+, 18+ **(verify in UI)**.
| Question area | Draft answer for WordFlora |
|---|---|
| In-app controls: parental controls | no (we use a parental gate for purchases; mention if the list has an item for it **(verify in UI)**) |
| In-app controls: age assurance | yes if the neutral age screen counts **(verify in UI)** |
| Violence, sexual content, profanity, horror, drugs, alcohol, tobacco, medical | None |
| Gambling/simulated gambling, contests, loot boxes | None / No (spec: no paid randomness; Rose of Jericho drops are free) |
| Unrestricted web access | No |
| User-generated content / messaging | No |
| Advertising | The Apple questionnaire does not appear to ask directly **(verify in UI)**; ads are third-party AdMob set to max rating G |
| Made for Kids | NO (do not select; ads and analytics would violate the Kids rules) |
Expected result: 4+. Check that AdMob G-rated ads and a word-guessing game are consistent with 4+; if Apple's new questionnaire pushes you to 9+, accept.
Source: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating

### D3. App Privacy nutrition label (draft)
Path: App Store Connect > app > **App Privacy** > **Get Started** **(verify in UI)**. Answers (verify against your final code and AdMob disclosure):
| Data type | Collected? | Linked to user? | Used for tracking? | Purposes |
|---|---|---|---|---|
| Purchases | Yes (Apple handles; if you read entitlements only, usually "No" for you) | No | No | App functionality |
| Identifiers: Device ID (AdMob IDFA/IDFV) | Yes | Per AdMob disclosure | Yes only if personalised ads allowed | Third-party advertising |
| Usage data: Product interaction, Advertising data | Yes (AdMob) | per AdMob | per AdMob | Third-party advertising, analytics |
| Location: Coarse | Yes (AdMob IP-derived) | per AdMob | per AdMob | Third-party advertising |
| Diagnostics: crash, performance | Yes (AdMob; plus own if any) | No | No | App functionality / analytics |
| User content (game progress) | Stored in the user's own iCloud via CloudKit private DB; you cannot read it | n/a | No | Typically not "collected" by you |
| Contact info, health, financial, browsing, search | No | | | |
If you add first-party analytics (spec section 11 mentions privacy-light events), add Usage Data/Product Interaction (not linked, not tracking).
Pitfall: the label must match the real SDK behaviour; an inaccurate label is a rejection reason.

### D4. Kids Category
Not used. Apple's rule: apps in the Kids Category cannot include third-party advertising or third-party analytics. Since WordFlora uses AdMob, do not choose Made for Kids (see D2). The app can still have an age screen and a safer child mode.
Source: Apple App Review Guidelines section 1.3 / 5.1.4: https://developer.apple.com/app-store/review/guidelines/ (not fetched this session; verify the section numbers).
Note the spec cites 2.5.18 for ad display requirements; same guideline URL.

### D5. Export compliance
Done in the project: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` on the app target, because the app uses only standard OS encryption (HTTPS, CloudKit) and AdMob/UMP use HTTPS only. App Store Connect will not ask each upload. Answer "No" to non-exempt encryption if asked **(legal responsibility is yours)**.

### D6. Screenshots (sizes required)
Apple lets you supply only the largest size per device family; it scales down **(verify in UI)**. Current required sets (as I recall; verify in App Store Connect > Screenshot Specifications):
| Device | Size (portrait px) |
|---|---|
| iPhone 6.9" | 1320 x 2868 (also accepts 1290 x 2796) |
| iPhone 6.5" | 1284 x 2778 or 1242 x 2688 (fallback) |
Min 1, max 10 per size. The app is iPhone only (`TARGETED_DEVICE_FAMILY = 1` on the app and widget), so no iPad screenshots are needed. On an iPad it runs as an iPhone app, and App Store Connect does not ask for iPad screenshots for an iPhone-only build **(verify in UI)**. Source: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications **(not fetched; verify)**.

### D7. Name and trademark check
1. Search the App Store (and Google Play) for "WordFlora", "Word Flora", "Wordflora".
2. USPTO trademark search https://tmsearch.uspto.gov and the EUIPO/TMview https://www.tmdn.org/tmview for the same strings in Class 9 and 41.
3. Check the domain and social handles.
4. Reserve the name in App Store Connect by creating the app record (A4); the reservation holds for a period while you do not submit **(verify in UI)**.
Not legal advice. Note there is a Duolingo-like colour concern in the spec (icon), which is separate.

### D6. Description line for garden weather and Wild Weather (spec section 4.2)
Wild Weather must be explained in the App Store description, not only in Settings. Add this paragraph to the description:
```
Garden weather: now and then a big wind, a dry spell or a frosty night visits your garden. Plants look a little different for a few days, and a drink or a hello helps them perk up. Nothing you grow goes away. Want a bigger challenge? Turn on Wild Weather in Settings: a big storm can make up to 4 plants look one step smaller for up to 4 days, until care, a weather puzzle or time brings them back. Your level never goes down. Calm mode and Quiet Garden keep the weather away.
```
Re-answer the age-rating questionnaire with weather in mind (spec Q-1): cartoon-gentle, infrequent, no fear or peril.

### D6b. Description lines for ads, Plus and the Terms of Use
Add these lines to the end of the App Store description (the app uses Apple's standard license agreement, the same link as the Terms of Use button on the Plus page):
```
Free with ads for grown-up players; WordFlora Plus removes ads and syncs your garden with iCloud. Players under 13 never see ads. Family Sharing covers up to six people.
WordFlora Plus is an auto-renewing subscription (yearly with a 3-day free trial for new subscribers, or monthly). It renews unless turned off at least 24 hours before the end of the period, and you can manage or cancel it in your App Store account settings.
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

### D8. Review notes (paste into App Store Connect > App Review Information > Notes)

Rewritten 2026-11-07 for a reviewer with no launch arguments, no demo account and no sign-in. Menu names below come from the current source (`SettingsView`, `OnboardingView`, `HomeView`, `PlusView`); items marked [ASSUMPTION] depend on what the final build ships and must be re-checked in the G6 build before pasting. Contact fields go in the separate App Review Information boxes.

```
WordFlora is a gentle word-guessing garden game for a mixed audience. There is no sign-in and no account, so no demo account is needed. Everything below can be reached from a fresh install with no special settings.

FIRST LAUNCH AND AGE
On first launch the app asks "How old are you?" with three buttons: Under 13, 13 to 17, 18 or older. The answer sets the experience. Under 13 also sets Calm mode on and offers a Quiet Garden question. To see a different age experience, delete the app and reinstall, then pick another button.
- 18 or older: ads for grown-ups (see below), Plus purchase without a gate.
- 13 to 17: G-rated, non-personalised ads, no tracking prompt.
- Under 13 (and anyone who has not answered): no ad is ever loaded, no consent or tracking prompt, and a grown-up question guards purchases and links.

HOW TO REACH EACH SCREEN
- Play a puzzle: Home > Play. Tap letters to guess the plant word; win to grow a plant. Daily Bloom is the card under Play.
- Garden, Shed, Visitors, Levels, Badges: tiles on Home (some unlock as you play; locked tiles show a hint).
- Settings: the Settings button on Home. It holds Calm mode, Quiet Garden, Garden weather, Reminders, Appearance, the Plus row, backup and restore of the garden file, Privacy and ads, and About.

PLUS, PURCHASES AND THE PARENTAL GATE
- Open Home > Settings. The Plus row is near the bottom. For 18+ and 13-17 it is labelled "Remove ads and sync with iCloud"; for under 13 the section is titled "For grown-ups" and the row is "WordFlora Plus".
- The Plus page shows three choices: Yearly ($12.99/year, 3-day free trial for new subscribers, the default), Monthly ($3.99/month) and Plus Forever (one-time $34.99, third row). The page also has Restore purchases, Redeem a code, Manage subscription and Terms of Use.
- Under 13: tapping a buy button, Redeem a code, Manage subscription, Terms of Use or any link out first shows a grown-up multiplication question. Passing it continues; Cancel returns. To see it, choose "Under 13" on first launch, then Settings > For grown-ups > WordFlora Plus > any buy button. No price, lock or buy button is on any other under-13 screen.
- Restore purchases: Plus page > Restore purchases. Redeem a code: Plus page > Redeem a code opens Apple's own code sheet. We provided offer codes for reviewers in the field below. [ASSUMPTION: codes created in ASC; paste one here]
- The pack "Frost & Lantern" (one-time purchase: winter pots, a snowy lantern garden, two winter visitors, two glasshouse plants) is offered from the Shed. [ASSUMPTION: final entry point from the G3/G5 build; fix this line before submitting] It is sold only to 13+ and behind the gate for under 13 [ASSUMPTION: confirm in G3].
- Plus Forever and the pack are non-consumable and come back with Restore purchases. Nothing in the game is blocked behind a purchase except cosmetic pots, the pack content, ad removal and iCloud sync.

ADS
- Ads (banner on Home and Garden, an interstitial after a round you choose to continue, and an optional rewarded ad for water) start from the second session, never the first, and never for under 13. To see one: pick "18 or older", play across two launches. You will first see the Google consent form where required, then the App Tracking Transparency prompt, then ads. Every ad request is G rated. In review builds ad serving may be in test mode [ASSUMPTION: depends on the G4 serving flip]. "Report an ad" is under Settings > Privacy and ads.

WILD WEATHER AND QUIET GARDEN
- Garden weather is cosmetic. Now and then weather visits the garden and plants look a little different for a few days; care, a weather puzzle or time brings them back. Nothing earned is ever removed: found plants, growth stages, pots, badges and the level stay. Weather is date-driven, so a reviewer may see none on the day; the Settings text explains it.
- Wild Weather: Settings > Garden weather > Wild Weather (opt-in, off by default). It needs Calm mode off and Quiet Garden off, and asks for confirmation before turning on. It only makes up to 4 plants look one step smaller for up to 4 days; the level never goes down. Under 13 sees the note "Ask a grown-up if you like." next to the switch.
- Quiet Garden: Settings > Comfort > Quiet Garden. It hides counters and wait times and keeps weather away. Calm mode is the switch above it.

OTHER
- Reminders are a single gentle daily notification, off until the player turns it on in Settings > Reminders.
- Backup and restore of the garden is a file export/import in Settings > Your garden. iCloud sync turns on only with Plus.
- Privacy Policy: https://shapehaveninnovations.com/privacy. Support: https://shapehaveninnovations.com/support.html.

Contact for review: [OWNER: name], [OWNER: phone], [OWNER: email]. Available 9:00-18:00 [OWNER: time zone]. [ASSUMPTION: owner fills these in]
Reviewer offer codes (optional): [OWNER: one-time code for plus_yearly or "none"].
```
Keep this text in step with the app: if a rule above changes, update it before the next submission. Before pasting, in the G6 TestFlight build confirm every [ASSUMPTION] line and every button label by hand.

### D: send back
```
Privacy policy URL: https://...
Support URL:        https://...
Marketing URL:      https://...
Age rating result:  4+ / 9+ (paste what App Store Connect calculated)
Name available:     yes/no (alt name: ___)
```

---

## E. Values to send back (final checklist and template)

Checklist:
- [ ] Paid Apps Agreement Active, tax and banking complete
- [ ] Small Business Program enrolled (date: ____)
- [ ] App record created, SKU `wordflora-ios-001`
- [ ] Group `WordFlora Plus`; `plus_yearly` (with 3-day free trial) and `plus_monthly` in "Ready to Submit"
- [ ] Family Sharing ON on both
- [ ] `plus_lifetime` (Plus Forever, $34.99, non-consumable, Family Sharing ON) in "Ready to Submit" (A13)
- [ ] Offer codes GARDENFRIEND (1 month free, auto-renew off) and WELCOMEBACK (3 months at 50%, expired subscribers) (A14)
- [ ] Sandbox tester created
- [ ] App Group and iCloud container created and attached to App IDs
- [ ] Xcode signing works for app and widget on a real device
- [ ] Stale `beta.WordGarden-SwiftUI` specifier removed
- [ ] CloudKit dev schema generated, production schema deployed
- [ ] AdMob account, app, 3 ad units, GDPR and US state messages published
- [ ] app-ads.txt live
- [ ] Privacy policy and support URLs live
- [ ] Age rating and privacy label done (Made for Kids NOT selected)

Paste this block back, filled in (no passwords, no private keys):
```
== WordFlora owner values ==
Bundle ID (app):            beta.WordFlora            [confirm or replace]
Bundle ID (widget):         beta.WordFlora.WordFloraWidget
Team ID:                    P9Z5QB8965                [confirm]
App Group ID:               group.beta.WordFlora
iCloud container ID:        iCloud.beta.WordFlora
Apple ID (numeric app id):  __________
Subscription group:         WordFlora Plus   (group id: ______)
Product IDs:                plus_yearly, plus_monthly, plus_lifetime
Offer codes live:           GARDENFRIEND, WELCOMEBACK   yes/no
Trial on yearly confirmed:  yes/no
Sandbox tester email:       __________
AdMob publisher ID:         pub-________________
AdMob App ID:               ca-app-pub-________~__________
Banner unit ID:             ca-app-pub-________/__________
Interstitial unit ID:       ca-app-pub-________/__________
Rewarded unit ID:           ca-app-pub-________/__________
Test device ID(s):          __________
Privacy policy URL:         https://__________
Support URL:                https://__________
Marketing URL:              https://__________
app-ads.txt URL:            https://__________/app-ads.txt
Age rating result:          ____
Signing OK on device:       yes/no (first error line: ______)
```

## Decisions only you can make
1. Keep `beta.WordFlora` as the permanent bundle ID, or switch before A4 (it cannot change after).
2. Exact product IDs (`plus_yearly`/`plus_monthly` vs prefixed) since they are permanent.
3. Territories and whether to adjust Apple's auto-converted prices.
4. iPad: decided, iPhone only for now (`TARGETED_DEVICE_FAMILY = 1`). Adding iPad later needs iPad layouts checked and iPad screenshots.
5. One banner unit or one per screen.
6. Which developer website/domain hosts privacy policy and `app-ads.txt`.

## Items I could not confirm from official pages
- Intro-offer UI labels and sandbox tester screens (Apple pages returned "Not Found").
- CloudKit Console button names, SwiftData-specific schema initialisation (page fetches returned outlines only).
- AdMob console labels for child-directed, Privacy & messaging, blocking controls, and test-device screens (not fetched).
- Current screenshot sizes and the new age-rating tiers.
- Whether the old `tagForChildDirectedTreatment`/`tagForUnderAgeOfConsent` are removed in the newest SDK (documented as deprecated).

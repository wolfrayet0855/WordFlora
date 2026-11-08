# CloudKit: deploy straight to production (no TestFlight)

Written 2026-11-07 for the owner's decision to submit the App Store build without a TestFlight pass. Sources: `WordFlora/Storage/SharedContainer.swift`, `WordFlora/App/WordFloraApp.swift`, the three model files under `WordFlora/Models/` at commit `35a19a3` (G3 worktree, adds `PlantCollectible.lastMistedAt`), `cloudkit-new-fields.md`, `owner-setup-steps.md` B8 to B11, `docs/pm/release-plan-extended.md`. This is a recommendation; you decide.

**The one-line rule.** Xcode Debug runs write to the CloudKit **Development** environment. Anything signed for App Store Connect (TestFlight or the App Store) writes to **Production**. A production app can never add record types or fields itself. So the schema that Debug builds grew in Development must be deployed to Production **before** the build that App Review approves can reach a Plus subscriber, or every CloudKit save for Plus users fails silently (the app keeps working locally; sync just never happens, and the console logs `CKError` "Unknown Item" / "invalid field").

Whether the step is "already done" is not a memory question; the console answers it in two minutes (part 1).

---

## 1. What Production must contain, and how to check

### 1a. Record types and fields

SwiftData mirrors model `X` as record type `CD_X` and property `p` as field `CD_p`. Each record also carries a system-made `CD_entityName` field (String); that is expected. There are no relationships, so no `CDMR` type should appear. Three record types, all stored in the private database, zone `com.apple.coredata.cloudkit.zone`.

**`CD_PlantCollectible` (33 fields)**

| Field | Type | | Field | Type |
|---|---|---|---|---|
| `CD_plantId` | String | | `CD_lastPrunedAt` | Date/Time |
| `CD_name` | String | | **`CD_lastMistedAt`** | Date/Time (new in G3, `35a19a3`) |
| `CD_botanicalName` | String | | `CD_soilType` | String |
| `CD_botanicalFact` | String | | `CD_nickname` | String |
| `CD_level` | Int(64) | | `CD_createdAt` | Date/Time |
| `CD_earnedCount` | Int(64) | | `CD_lastLovedAt` | Date/Time |
| `CD_imageName` | String | | `CD_lastShownPips` | Int(64) |
| `CD_growthPoints` | Int(64) | | `CD_potId` | String |
| `CD_stage` | Int(64) | | `CD_potChosenAt` | Date/Time |
| `CD_hydration` | Double | | `CD_goldenDays` | Int(64) |
| `CD_soilRichness` | Double | | `CD_goldenDayKey` | Int(64) |
| `CD_lastTendedAt` | Date/Time | | `CD_lifeSeenKey` | String |
| `CD_lastSunnyAt` | Date/Time | | `CD_lifeSeenAt` | Date/Time |
| `CD_absorbedToday` | Int(64) | | `CD_waterToday` | Int(64) |
| `CD_absorbDay` | Date/Time | | `CD_waterDay` | Date/Time |
| `CD_lastFedAt` | Date/Time | | `CD_soilBoostUntil` | Date/Time |
| `CD_lastRepotGrowthAt` | Date/Time | | | |

**`CD_PlayerProfile` (51 fields)**

| Field | Type | | Field | Type |
|---|---|---|---|---|
| `CD_currentLevel` | Int(64) | | `CD_lastAdAt` | Date/Time |
| `CD_plantsEarnedThisLevel` | Int(64) | | `CD_adsToday` | Int(64) |
| `CD_roseOfJerichoCount` | Int(64) | | `CD_adsDay` | Date/Time |
| `CD_gamesPlayed` | Int(64) | | `CD_rewardedToday` | Int(64) |
| `CD_water` | Int(64) | | `CD_rewardedDay` | Date/Time |
| `CD_soil` | Int(64) | | `CD_weatherSeed` | Int(64) |
| `CD_lastTrickleAt` | Date/Time | | `CD_weatherStartDay` | Int(64) |
| `CD_widgetPlantID` | String | | `CD_weatherHighWaterDay` | Int(64) |
| `CD_streak` | Int(64) | | `CD_weatherShelterDay` | Int(64) |
| `CD_bestStreak` | Int(64) | | `CD_weatherRescuedDays` | List(Int(64)) or Bytes |
| `CD_streakFreezes` | Int(64) | | `CD_weatherPuzzleDay` | Int(64) |
| `CD_lastPlayedDay` | Date/Time | | `CD_weatherPuzzleCount` | Int(64) |
| `CD_seenIds` | List(String) or Bytes | | `CD_wildWeather` | Int(64) |
| `CD_earnedPotIds` | List(String) or Bytes | | `CD_weatherGatedFromDay` | Int(64) |
| `CD_roundsSinceAd` | Int(64) | | `CD_weatherSeenAt` | Date/Time |
| `CD_ageBand` | String | | `CD_weatherKitAt` | Date/Time |
| `CD_roseSeedProgress` | Int(64) | | `CD_crownSeenAt` | Date/Time |
| `CD_wordsTowardPlant` | Int(64) | | `CD_goldCrownSeenAt` | Date/Time |
| `CD_lastRoundId` | String | | `CD_guideSeen` | Int(64) |
| `CD_gardenDays` | Int(64) | | `CD_questDay` | Int(64) |
| `CD_lastGraceDay` | Date/Time | | `CD_questProgress` | Int(64) |
| `CD_shedPoints` | Int(64) | | `CD_questDone` | Int(64) |
| `CD_toolsJSON` | String | | `CD_createdAt` | Date/Time |
| `CD_activeToolId` | String | | `CD_butterflyPlaysJSON` | String |
| `CD_badgesJSON` | String | | `CD_glowLanterns` | Int(64) |
| `CD_albumJSON` | String | | | |

**`CD_GameRecord` (9 fields)**: `CD_date` Date/Time, `CD_wordGuessed` String, `CD_triviaQuestion` String, `CD_won` Int(64), `CD_petalsRemaining` Int(64), `CD_plantEarned` String, `CD_level` Int(64), `CD_wordId` String, `CD_isDaily` Int(64).

Bools arrive as Int(64). Arrays may arrive as a List or as Bytes depending on the OS; whatever Development shows is the truth. The 27 fields that are new since `main` (26 in `cloudkit-new-fields.md` plus `CD_lastMistedAt`) are the ones most likely to be missing from Production if a deploy was done earlier in the year.

### 1b. Check Production, click by click

1. Open https://icloud.developer.apple.com/dashboard and sign in with the developer Apple Account (team `P9Z5QB8965`).
2. Click the container **`iCloud.beta.WordFlora`**. If it is not listed, B4 in `owner-setup-steps.md` was never done; stop and do B4 to B5 first.
3. Left sidebar: **Schema** > **Record Types**. Top of the page there is an environment control (a **Development / Production** toggle or dropdown). Set it to **Production**.
4. Read the list. Three outcomes:
   - **Empty, or only `Users`**: Production has never been deployed. Everything in 1a is missing. Do part 2 then part 3.
   - **`CD_PlantCollectible`, `CD_PlayerProfile`, `CD_GameRecord` present**: click each and compare its fields with 1a. If `CD_lastMistedAt` is absent on `CD_PlantCollectible`, or any `weather*`, `quest*`, `pot*`, `golden*`, `lifeSeen*`, `earnedPotIds`, `wordsTowardPlant`, `guideSeen`, `crownSeenAt`, `goldCrownSeenAt` field is absent, a deploy is still needed (parts 2 and 3).
   - **Every field present**: switch the toggle back to **Development** and open **Deploy Schema Changes...** (button at the top of the Schema page, sometimes under a "..." menu). The dialog lists what would change. If it shows **no changes** ("There are no changes to deploy" or an empty list with the Deploy button disabled), the step is truly done. Click **Cancel**. Nothing else is needed for this release.
5. Also check Development the same way (toggle to **Development**) before any deploy: Production can only receive what Development already has.

---

## 2. Growing the Development schema without TestFlight

SwiftData creates record types and fields the first time it mirrors a saved object. The app only opens its store with CloudKit when the App Group default `cloudSyncEnabled` is true, which `AppModel.updateSyncFlag()` sets from the Plus entitlement; a Debug run with the StoreKit configuration file can earn that entitlement for free. There is no `initializeCloudKitSchema` call in the code (grep of `WordFlora/` finds none), so the data path below is the way.

Simulator or device both work; a device signed into your real iCloud is the stronger check because the simulator's iCloud mirroring is slower and sometimes stalls. Steps:

1. In Xcode open the **WordFlora** scheme, Debug configuration (the default for Run). The scheme already attaches `Config/WordFlora.storekit` (Edit Scheme > Run > Options > StoreKit Configuration), so Plus can be "bought" locally with no money and no App Store Connect.
2. Pick a destination signed into iCloud. Device: Settings > [your name] shows an account and iCloud Drive is on. Simulator: Settings > Apple Account > sign in, then wait for iCloud Drive to turn on.
3. Run (Cmd+R). Finish onboarding as **18+** (the Plus row is "Remove ads and sync with iCloud"; the under-13 flow puts it behind the parental gate).
4. Home > Settings > the Plus row > **buy yearly or monthly**. The local StoreKit sheet appears; confirm. Settings should now show "iCloud sync starts the next time you open WordFlora".
5. Quit the app fully (swipe up on device; Stop in Xcode) and **Run again**. On this launch `SharedContainer.make(cloudSync: true)` opens the store with `.private("iCloud.beta.WordFlora")`. Settings should read "iCloud sync is on".
6. Create one of every record type so every field is written at least once:
   - Play a round to the end (win or lose): writes a `GameRecord` and the `PlayerProfile`.
   - Win so a plant arrives (the first win always brings a plant): writes a `PlantCollectible`.
   - Open the plant's page and tend it: Water, Feed, Sun, Prune, and **Mist** (the Mist button sits between Prune and Repot once the mister is owned, or with Settings > Show everything on). Mist is the only action that writes `lastMistedAt`.
   - Open the Shed, the Visitors page, the Weather card, the Daily Bloom, and choose a pot, so the `pot*`, `weather*`, `quest*`, `album`, `tools` fields are touched.
   Fields with a nil value are still declared on the first save of the record (SwiftData declares the whole entity), so one saved object of each type is the real requirement; the tending is belt and braces.
7. Wait a minute, then in the CloudKit Console, environment **Development** > Schema > Record Types: `CD_PlantCollectible`, `CD_PlayerProfile`, `CD_GameRecord` should be listed. Click each and tick off part 1a. If nothing appeared after five minutes: check Xcode's console for `CKError` lines (account not signed in, iCloud Drive off, network), and confirm the entitlements file still lists `iCloud.beta.WordFlora` under `com.apple.developer.icloud-container-identifiers`.
8. Optional, to **browse** records in the console: Schema > Record Types > each type > **Indexes** > **Add Basic Index** > field `recordName`, type **QUERYABLE** > Save. SwiftData's mirroring uses zone-change fetches, not queries, so no index is required for sync itself; add this one only if you want **Data > Records** to let you query. If you add it in Development before part 3, the deploy carries it to Production, which is harmless.
9. Afterwards: Settings > the Plus row > Manage (or Xcode > Debug > StoreKit > Manage Transactions) to clear the fake purchase, or leave it; a Debug purchase never touches the App Store account.

---

## 3. Deploy to Production, once, and when

1. CloudKit Console > `iCloud.beta.WordFlora` > **Schema** > environment **Development** > **Deploy Schema Changes...**.
2. The dialog lists every new record type, field and index that Production lacks. Read it against part 1a. Click **Deploy**.
3. Toggle to **Production** and confirm the three record types and `CD_lastMistedAt` are there now.

**Order relative to the submission.** Deploy **before** you upload the archive, or at the latest before you press Submit for Review. Reasons: App Review's testers may buy Plus in sandbox and their device talks to Production; a Plus user on day one certainly does; and there is nothing in the build to wait for, since the schema is server-side and the build does not change. Deploying later is allowed (production schema is additive and the app does not need an update), but every Plus save made before the deploy is dropped on the floor, and the owner would have no way to notice except the console.

**Deploy once.** Production fields can never be removed, renamed or retyped. `35a19a3` is the last stored-field change of this plan (G2b, G4, G5 report "no stored fields"). If any later commit touches `WordFlora/Models/`, repeat parts 2 and 3 before submitting; `git diff <last deployed commit> -- WordFlora/Models` shows whether that is needed.

**If skipped.** Free players are unaffected (their store is local, `cloudKitDatabase: .none`). Plus players' records fail to upload, the app shows no error (by design, `SharedContainer` falls back to the local store on open failure and mirroring errors are only logged), sync never completes, and the fix is still just this deploy; no app update is needed.

---

## 4. Skipping TestFlight: what it costs and the cheapest substitutes

TestFlight gives two things a Debug run does not: the **exact App Store-signed binary** (Release configuration, Production CloudKit and push entitlements, App Store provisioning) running on a real phone, and installs on devices that are not registered to your developer account. Everything in the plan's device checklist (`owner-dated-checklist.md`, items 1 to 12) was meant to run on that binary. Below is what each check needs and the cheapest way to get most of it on your own phone before you submit.

### 4a. Get a Release build on your phone without TestFlight

Both routes start from the same archive you will upload, so the binary you test is the binary App Review sees.

- **Route 1, Xcode direct (quickest):** Product > Scheme > Edit Scheme > Run > Build Configuration = **Release**; then Run on your plugged-in phone. Development-signed, Release code. Set it back to Debug afterwards. This build still uses the **Development** CloudKit environment.
- **Route 2, Ad Hoc export:** Product > Archive > Organizer > Distribute App > **Ad Hoc** (or **Release Testing** in newer Xcode) > automatic signing > export the `.ipa` > drag it onto your phone in Window > Devices and Simulators. Your phone's UDID must be in the team's device list (Xcode adds it on first Run). Ad Hoc builds use the **Production** CloudKit environment, the same as the App Store, so this route also exercises part 3 for real.
- Keep `Config/Ads.local.xcconfig` in place on your Mac: both Debug and Release include it, so any build from your machine already carries the real AdMob ids; it is not Release-only in this project. Add your phone as a test device in AdMob (Settings > Test devices) before tapping real ads, or you risk an invalid-traffic flag on your account.

### 4b. Item by item

| Check | Can it be done without TestFlight? | Cheapest substitute on your phone |
|---|---|---|
| Paywall: three options, prices, "3 days free" on yearly only | Yes | Release build (4a), Settings > Plus row. Prices come from App Store Connect once the products are "Ready to Submit"; sign out of the App Store app and sign in with a **sandbox** Apple Account (Settings > App Store > Sandbox Account). |
| Buy yearly, buy Plus Forever (`plus_lifetime`), buy the pack; Restore on reinstall; Manage Subscription | Yes | Same sandbox account; delete and reinstall the app, then Settings > Restore purchases. Sandbox purchases are free and renew fast (a year = 1 hour). |
| Redeem `GARDENFRIEND` offer code | Partly | The redeem sheet opens and sandbox one-time codes can be tested; custom codes are the uncertain part. **Verify on TestFlight or trust the App Store behaviour.** |
| Ask to Buy | Yes | App Store Connect > Users and Access > Sandbox > your tester > turn on Ask to Buy. |
| Family Sharing to a second person's device | **Only if that device is registered to your team** (Ad Hoc) or you have TestFlight | Sandbox family groups exist (Sandbox > Family Sharing), but the second phone must install the build. With one phone, confirm `Transaction.ownershipType` and the Family Sharing line show after a sandbox family purchase on your own device. **TestFlight is the honest way to check this one.** |
| Parental gate for under 13 | Yes | Fresh install, onboard as under 13, try every buy and link-out. |
| UMP consent form, then ATT prompt for an adult; no ad at all for under 13 | Yes | AdMob > Privacy & messaging must be published first. Force EEA in the UMP debug settings (geography EEA, your device's hashed id in test devices). ATT prompt appears on a real device only. Under 13: play 3 sessions, see no banner. |
| Real ad serving (banner, interstitial, rewarded) | Yes | Release build with `Ads.local.xcconfig` and your phone as an AdMob test device. New ad units may show nothing for several hours after creation; that is normal, not a bug. |
| Widget on Home and Lock Screen, Say hello / water button, Siri "Water my garden" | Yes | Any device build; add the widget, wait a minute, tap the water button; check the app and widget agree on the count. |
| Haptics, thunder loudness, Mist hiss, petal notes, Living Touch | Yes | Any device build; the simulator has no haptics and poor speakers. |
| Reminders permission and delivery | Yes | Any device build. |
| Two-device iCloud sync after the Production deploy | Partly | Route 2 Ad Hoc build on your phone plus a Debug run on a simulator signed into the same iCloud is **not** valid (Development vs Production). Use two devices on Production: your phone with the Ad Hoc build and a second device you own, also Ad Hoc. Or add `com.apple.developer.icloud-container-environment` = `Production` to `WordFlora.entitlements` for one Debug run on the simulator and remove it after (writes real data into your own iCloud; fine for the owner's account). One device alone can at least confirm records appear under Production > Data > private database > `com.apple.coredata.cloudkit.zone`. |
| Crash safety run (20 minutes, background/foreground, Low Power, airplane, light/dark) | Yes | Release build on your phone. |
| The uploaded binary installs and launches as App Store-signed | **No** | Only TestFlight installs the App Store-signed build on a phone. The upload step itself still catches missing icons, export compliance and entitlement mismatches, and App Review installs it, so a hard failure would come back as a rejection, not as a shipped crash. |

### 4c. Recommendation

Use an **internal-only TestFlight build from the same archive** anyway. It costs about 15 minutes of clicks plus Apple's processing time (usually under an hour), needs no Beta App Review (internal testers, up to 100, are your own App Store Connect users; add yourself under TestFlight > Internal Testing), and the very same build number is then what you select on the Submit page. It is the only route that covers the last three rows above (Family Sharing to an unregistered second phone, two-device sync on Production without entitlement edits, and the App Store-signed install), and it does not delay the submission: you can submit the build for review the same hour it finishes processing, before or while you test it.

If you still prefer to skip it: do part 1 today, parts 2 and 3 the day G3 merges, then 4a Route 2 plus the "Yes" rows in 4b on your phone. Accept that Family Sharing, the offer code and the signed install go out on App Review's word alone.

Either way, the order is: **Development schema grown (part 2) > Production deploy (part 3) > archive and upload > submit.**

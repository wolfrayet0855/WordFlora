# G6 plan and owner device checklist (straight to production)

Written 2026-11-07. Replaces the G6 and "TestFlight" lines of `docs/pm/release-plan-extended.md` and the device-check block of `docs/setup/owner-dated-checklist.md` for the owner's decision to go to production with **at most one internal TestFlight build**. Sources: `docs/STATUS.md` ("NOT verified"), `docs/setup/cloudkit-deploy-straight-to-prod.md`, `docs/setup/screenshot-plan.md`, `docs/pm/admob-full-spec.md`, `docs/pm/g4a-builder-brief.md`.

Real AdMob ids are never written in any file, commit, log or message. Say "the Release unit keys" or last 4 digits.

**Dates.** Target submit **Thu 2026-11-19**. Slip date **Mon 2026-11-23** (holds with about 2 days of slack). Builder gates run G4a, G5, G4b, then G6 (builder part) ending about Tue 11-17; owner archive and device checks Tue 11-17 evening to Wed 11-18; submit Thu 11-19.

---

## Part A. Builder part of G6 (machine, before the owner archives)

1. Reboot the simulator, take the build lock, one xcodebuild at a time, own dd folder (rules in `g4a-builder-brief.md` section 0).
2. Full unit suite; all seven UI batches (A `WordFloraUITests`, B `FidelityScreensUITests` + `HomeLayoutUITests` + `CelebrationUITests`, C `TendingUITests`, D `RestCardUITests`, E `GuideUITests`, F `EndgameUITests`, G `WeatherUITests`) plus `DailyQuestUITests`, `SpeedBloomUITests`, `ParentalGateLinkUITests`, `AdFormatsUITests` and the G1 to G5 classes. Rerun any red once alone; note XCTest stalls; no known reds left.
3. Release simulator proof build with `CODE_SIGNING_ALLOWED=NO` (the ads check override applies only there). Scan the built bundle: no Google test publisher number in any id, no fake-presenter or `-adcaps` strings.
4. `git diff <G3 deploy commit> -- WordFlora/Models` must be empty. If not, the CloudKit deploy must be repeated before submit (see Part D).
5. Update `STATUS.md`, `cloudkit-new-fields.md` and owner-steps D6b/D8 (Plus Forever, the pack, the redeem row, AdMob-only ads, return ad sentence, ads begin from session 3, under 13 and unknown age never see an ad).
6. Hand the owner the tip commit hash.

## Part B. Owner archive (Tue 11-17 evening)

**Step 1. Archive from the MAIN checkout, not a worktree.** `Config/Ads.local.xcconfig` is git-ignored and absent from worktrees. A worktree archive has no real ids and would ship Google's test ids (the Release build-phase check from G4a should refuse it, but do not rely on that: do not try).

1. In the main checkout `/Users/computer/Desktop/workspace/WordFlora`: `git status` clean, branch `3-feat-content-and-polish` at the tip hash from Part A, and `ls Config/Ads.local.xcconfig` shows the file.
2. Xcode > scheme WordFlora > Product > Archive (Release). The Run Script check must pass. If it fails, read the reason (key names only, never ids) and fix the file; do not skip the check.
3. Verify the archive carries no test ids, without printing ids:
   - Show Package Contents of the `.xcarchive` > `Products/Applications/WordFlora.app/Info.plist`. For each key `GADApplicationIdentifier`, `AdMobBannerUnitID`, `AdMobBannerGardenUnitID`, `AdMobBannerGardenCollapsibleUnitID`, `AdMobInterstitialUnitID`, `AdMobRewardedUnitID`, `AdMobRewardedHintUnitID`, `AdMobRewardedWakeUnitID`, `AdMobAppOpenUnitID`, `AdMobNativeUnitID`: present, none empty, none contains `3940256099942544`, none shows `$(`.
   - `AdMobBannerGardenUnitID` equals `AdMobBannerUnitID` (reuse is intended).
   - Terminal check that prints counts only: `plutil -p <app>/Info.plist | grep -c 3940256099942544` must print 0; `strings <app>/WordFlora | grep -ciE "uitest-ads-fake|adcaps"` must print 0.
4. Organizer > Validate App, then Distribute App > App Store Connect > Upload. Fix any missing icon, export compliance or entitlement message here.
5. Optional: Organizer > Generate Privacy Report and compare with `PrivacyInfo.xcprivacy` and `docs/setup/age-rating-and-privacy-label.md`.
6. Wait for processing (usually under an hour). The same build number is what you select on the Submit page.

**One internal TestFlight build (recommended, at most one).** From the same upload: TestFlight > Internal Testing > add yourself. About 15 minutes of clicks, no Beta App Review. It is the only way to run the exact App Store-signed binary, Family Sharing on a second device, and the offer code on the real path. If you skip it, accept that those three go out on App Review's word. Do not upload a second build for testing; any fix after this build means a new build number and a re-check of Part C items 1 to 6.

## Part C. Owner device checklist (Tue 11-17 night to Wed 11-18, 3 to 4 h across two days)

Use your phone with the TestFlight build when possible; otherwise a Release build (Route 1 or 2 in `cloudkit-deploy-straight-to-prod.md` 4a). Add your phone as an AdMob test device before tapping any real ad (invalid-traffic risk). Sandbox Apple Account for purchases (Settings > App Store > Sandbox Account).

### C1. The "NOT verified" list from `docs/STATUS.md`

- [ ] **Widget** on Home Screen and Lock Screen renders; interactive water button works; app and widget counts agree (also Siri "Water my garden", Control Center control on iOS 18+).
- [ ] **iCloud sync end to end** (see C4).
- [ ] **Ads** real serving (see C3), consent form, `app-ads.txt` live, privacy policy URL live.
- [ ] **Sounds**: listen to the weather set, petal notes, thunder loudness, Mist hiss (on the phone speaker and with headphones; mute switch respected). **Haptics** feel right (water, bloom, Mist, Living Touch, gentle hello heart). Anything harsh is a blocker or a logged 1.1 item; decide on the day.
- [ ] **On-device AI "Tell me more"** on a real Apple Intelligence device if you have one (fallback is safe otherwise); no kid-unsafe output.
- [ ] **Real StoreKit sandbox** against App Store Connect products; parental gate flow; Ask to Buy (C2).
- [ ] **Reminders**: permission prompt, one delivered notification, tap opens the app (and an app-open ad must not show on that launch).

### C2. StoreKit

- [ ] Paywall shows three options: Yearly (default, "3 days free" on yearly only), Monthly, Plus Forever; prices match App Store Connect exactly.
- [ ] Buy yearly (sandbox); Plus on; ads gone; iCloud line appears. Buy monthly on a second sandbox tester. Buy `plus_lifetime`.
- [ ] Buy `pack_frost_lantern` if it ships (skip if G5 fell back); pots and scene unlock.
- [ ] **Restore**: delete and reinstall, Settings > Restore purchases; Plus and the pack return.
- [ ] Manage Subscription opens; lifetime note about cancelling a subscription is present.
- [ ] **Family Sharing**: purchase on the sandbox family organiser, check the second family member's device gets Plus. Needs TestFlight or a registered second device; otherwise confirm `ownershipType` / Family Sharing line on your own device and accept the gap.
- [ ] **Offer codes**: `GARDENFRIEND`, `WELCOMEBACK`, and one of the 500 one-time codes via the redeem row. Custom codes are the uncertain part in sandbox; TestFlight or the real store is the honest check.
- [ ] **Ask to Buy** on a sandbox child account: purchase pends, nothing unlocks until approved.
- [ ] Under-13 fresh install: every buy and link-out sits behind the parental gate; no price on kid screens.

### C3. UMP, ATT and ads

- [ ] AdMob > Privacy & messaging: GDPR and US-state messages **published**; AdMob is the only ad partner.
- [ ] Adult (18+) fresh install, play to session 3: UMP form (force EEA with debug geography on a debug build, or real region), then the ATT prompt only for adults, only after UMP.
- [ ] 13 to 17: UMP yes, **no ATT prompt**, ads are G-rated.
- [ ] Under 13 and no-age-answer: three sessions, **no ad of any kind, no UMP, no ATT**.
- [ ] Plus owner: no ad, no ad prompt, perks free.
- [ ] Real banner (Home and Garden), interstitial, rewarded water/hint/wake, return ad after 4 h away (use a real wait, or test with a debug build and `-adcaps`), native "SPONSORED" card in the Shed. New units may show nothing for hours after creation; that is normal.
- [ ] Never over onboarding, consent, a puzzle, Calm or Quiet Garden. App-open has Skip and never appears after a notification or widget launch.
- [ ] Release unit keys real, none test (Part B step 3).

### C4. CloudKit two-device sync and Console Production check

Follow `docs/setup/cloudkit-deploy-straight-to-prod.md` (parts 1 to 3). The order is: Development schema grown, **Production deploy, then archive and upload, then submit**.

- [ ] Console > `iCloud.beta.WordFlora` > Schema > Production shows `CD_PlantCollectible` (33 fields incl. `CD_lastMistedAt`), `CD_PlayerProfile` (51), `CD_GameRecord` (9), or Development > Deploy Schema Changes reports "no changes".
- [ ] `git diff <last deployed commit> -- WordFlora/Models` is empty. Any later model change means redo parts 2 and 3 before submitting; Production fields can never be removed or retyped.
- [ ] Two devices on Production (TestFlight or Ad Hoc builds on both; a Debug simulator against an Ad Hoc phone is NOT valid): both Plus, same iCloud. Tend a plant on A, see it on B within a few minutes; earn a plant on B, see it on A; both ways.
- [ ] Free player is unaffected (local store).

### C5. Everything else on a device

- [ ] Haptics and sound (C1), Dynamic Type at the largest size on Home, Garden, Shed, paywall; Dark Mode; VoiceOver pass over one round; Reduce Motion; Low Power Mode.
- [ ] Crash-safety run, 20 minutes: background and foreground, airplane mode, light and dark, rotate lock, an interrupted purchase.
- [ ] Wild Weather opt-in is off by default for all ages unless the player opts in.
- [ ] Notification, widget and Siri launches show no ad.

Anything that fails: write it down, mark blocker or 1.1, tell the lead. Blockers mean fixes, a new archive from the main checkout, a new build number and a recheck of the affected items.

---

## Part D. Screenshots plan (Mon 11-16 to Wed 11-18, after the regression)

Full plan: `docs/setup/screenshot-plan.md`. Summary: 8 shots per size, same order and captions, from the Release-equivalent simulator build or the phone.

- Sizes: 6.9-inch (1320 x 2868, iPhone 17 Pro Max) required; 6.5-inch (1242 x 2688) if the runtime exists, else upload the 6.9-inch set only [check ASC on the day]. iPhone only.
- Shots: Home mid-game; puzzle in progress; Garden grid; plant page; visitors' book; a weather day; Shed with pots (and the pack entry if shipped); one dark mode shot.
- Run only `FidelityScreensUITests` with `TEST_RUNNER_SCREENSHOT_DIR=<folder>` under the build lock; the weather shot needs a small new test (add to the G6 brief if not already in).
- Check size with `sips -g pixelWidth -g pixelHeight`; no keyboard, no debug banner, no ad, no age question, no under-13 variants, no AX XXXL shots.
- Add captions in an editor, export without alpha, keep sources outside the repo.
- IAP review screenshots from the real G6 build: `plus_lifetime` (the three-row Plus page with real prices, matching the shipping paywall), `pack_frost_lantern` if shipped, `plus_yearly` and `plus_monthly` (reuse).

## Part E. Submission steps and dates

**Wed 11-18:** checklist done, no blockers; CloudKit Production confirmed; build processed.

**Thu 11-19 (target), about 2 h:**
1. App Store Connect > the app version: select the uploaded build.
2. Upload screenshots (both sizes) in order; description with the D6/D6b lines (Plus Forever, the pack, the redeem row); keywords; support and privacy policy URLs live.
3. Attach in-app purchases to the version: `plus_yearly`, `plus_monthly`, `plus_lifetime`, and `pack_frost_lantern` if shipped; each Ready to Submit with its review screenshot; offer codes `GARDENFRIEND`, `WELCOMEBACK` and the one-time batch attached.
4. App Privacy labels match both SDKs (AdMob and the in-app purchase data) and `age-rating-and-privacy-label.md`; age rating questionnaire re-answered (weather, purchases, ads).
5. Review notes from D8 plus the G6 additions: three-option paywall, the pack's kid rules, ads begin from the third session, 13 to 17 non-personalised G-rated ads with no tracking prompt, under 13 and no-age-answer players never see any ad and the ad SDK never starts, rewarded videos optional with every reward also free, Plus (monthly, yearly, Forever) removes all ads, the return ad is at most once a day after 4 h away behind "Skip to my garden". Demo path: reviewers see no ads in session 1 (grace of 3 sessions); explain "Go ad-free".
6. Export compliance, content rights, advertising identifier (IDFA: yes, serve ads) answered. Release option: manual release, so you control the day.
7. Press Submit for Review.

**Slip date Mon 2026-11-23** if: a blocker in Part C, the G4b formats are not green (ship them off by a compile-time flag only with the lead's approval), the G5 art falls back (pack to 1.1, submit can move earlier), the Paid Apps Agreement is not Active, or CloudKit Production is not confirmed. Slip order of cuts needs owner approval; none applied here.

After submit: do not change `Models/`; watch AdMob Ad review center weekly for the first month; check app-open show rate and rewarded completion per unit.

# Builder diff review 3: G4a AdMob branch

Date: 2026-11-08. Read-only review (no build, no simulator, no edits to the worktree).
Branch: `worktree-agent-a3e7063b293c680a0`, `3-feat-content-and-polish...HEAD`. That is the 9 commits `ac7c56e..0783b51` plus **`f91b4e4`**, which the builder committed while this review was running (Debug-only collapsible probe, faded-bloom shot UI test). Line numbers are at `f91b4e4`.
Checked against: `docs/pm/g4a-builder-brief.md` (sections 3, 4 and 10 most closely), `docs/pm/admob-full-spec.md` with Review rulings 1 to 3, `docs/pm/admob-ad-ids-review.md`, and `docs/pm/plus-flow-fable-review.md` (ad guards).

## Verdict

**Safe to run its test hold.** I found no blocker. Run the hold on `f91b4e4` or later, and only once the builder has stopped committing. Expect one likely red, M3 (the AX5 audit). Before merge, fix M1, M2 and M4. They are small. G4a is not complete against brief section 10 until the deferred items (M5) land after the engagement merge.

## What checks out

- **Age policy.** `AdPolicy.decide` checks `treatment == .none` before it reads any other input (`Rules/AdPolicy.swift:146-152`). Every `ads.prepare` call site gets its treatment from a `.yes` (`AppModel.swift:515, 565, 575, 597`). Nothing else calls `MobileAds.shared.start`, ATT or UMP outside `AdsService`. `startIfConsentAlreadyResolved` has no caller yet (G4b).
  - Teens: the plan is configure(.teen), then consent with `isTaggedForUnderAgeOfConsent = true` set before `requestConsentInfoUpdate`, then start. It never includes tracking (`AdsService.swift:24-30, 129-141`).
  - Adults: UMP, then ATT, then start.
  - Free paths (Plus, under 13, unknown age) read only the per-perk day cap, never the visit or full-screen budgets (H7, `AdPolicy.swift:301-311`).
- **Caps match the rulings** (`Rules/AdBudget.swift:8-34`):
  - pushed: 6 a day, 2 per visit
  - all full-screen: 8 a day, 4 per visit
  - gaps: 600 s from any full-screen to the next pushed ad, 30 s to rewarded, 1800 s to app-open
  - rewarded: 5 a day, 3 per visit; per perk 3/2/1
  - The overrides are `#if DEBUG` only.
- **Surfaces with no ads:** onboarding, a puzzle in progress, a quiet visit, a pending ceremony (for every format except the plain banner), the Plus and Seasons pages (`RootView` sets `adOnPaywall`), and any foreign sheet or an inactive app (`AdsService.presentationAnchor`, re-checked after every await).
- **Quiet Garden** hides R1 and R2 for everyone.
- **Release check script** (`tools/ads/check-ad-ids.sh`):
  - It reads only the built Info.plist through PlistBuddy, with stderr dropped. It prints key names and reasons, never a value.
  - The phase sets `showEnvVarsInLog = 0`, so build settings are not dumped into the log.
  - Inputs and outputs are declared, which keeps it working with `ENABLE_USER_SCRIPT_SANDBOXING = YES`.
  - Debug builds exit at once.
- **Debug never uses real ids.** All 9 non-comment lines in `Config/Ads.local.xcconfig` (main checkout, git-ignored) are `[config=Release]`. I checked key names only. `Ads.xcconfig` holds test ids only, and `ADMOB_BANNER_GARDEN_ID = $(ADMOB_BANNER_ID)`.
- **No real ids in committed files.** I grepped for `ca-app-pub-` with 16 digits:
  - `Config/Ads.xcconfig`: 9, all on Google's test publisher number
  - `docs/pm/admob-full-spec.md`: 1, test
  - `docs/setup/owner-setup-steps.md`: 1, test
  - `docs/superpowers/plans/2026-05-10-wordflora-overhaul.md`: 3, test
  - `WordFloraTests/AdUnitIDTests.swift`: 9 on one synthetic repeated-digit publisher
  - The owner's real publisher number appears in 0 tracked files and 0 lines of branch history.
  - The commit-message attribution grep prints 0.
- **Info.plist:** all nine unit keys are present. `GADApplicationIdentifier = $(ADMOB_APP_ID)`. There are 50 SKAdNetwork ids. The ATT wording is unchanged and adult-only. `NSPrivacyTrackingDomains` is empty. `plutil -lint` passes on the plist and the pbxproj. `TARGETED_DEVICE_FAMILY = 1` in all 4 places. AppLovin: 0 hits.
- **Debug-only code:** `FakeAdHost`, the fake flags, `-uitest-ads-fake`, `-uitest-dry`, `-uitest-wake-dreamed`, the store-fault fixtures, `AdCaps.debugOverrides` and the collapsible probe are all inside `#if DEBUG`. `isFake` has a Release `#else`.
- **No stored field added.** The `WordFlora/Models` diff is empty. The ledger lives in App Group defaults under `adLedger`.
- **Copy.** Every perk line is in `AdPerkCopy.all` and checked by CopySafety (`AdPolicyTests.swift:439-441`). Video titles say "video". Free rows never say "Plus" to a child.
- **R3** wakes only through `wake(plant)` (sets `lastLovedAt`). `WakeSuccessView` is visual only, so there is no sticker, badge, water or shed points.
- **SDK names** match the cached GMA/UMP headers in DerivedData: `isTaggedForUnderAgeOfConsent`, `requestConsentInfoUpdate(with:)`, `isCollapsible`, `Extras`, `currentOrientationAnchoredAdaptiveBanner(width:)`, `ageRestrictedTreatment`. The project pins GMA 13.12.0 and UMP 3.1.0. I did not confirm that the cache is that exact version.
- **Concurrency.** The project is Swift 5 with no strict concurrency, so concurrency issues can only be warnings.

## Findings by severity

No blocker.

### Medium

**M1. A dead video row when consent is declined or cannot be resolved.**
- Where: `AppModel.swift:588-606`.
- Problem: an EEA adult who declines UMP gets `canRequestAds = false`, and the SDK never starts. `showRewarded` returns early and the row stays. Each tap re-runs consent and does nothing. Only a load failure sets `rewardedLoadFailed`.
- Fix: right after `await ads.prepare(...)` in `watchRewarded`, add `guard ads.started else { adSession.rewardedLoadFailed = true; return false }`. Use `started`, not `canRequestAds`, because the fake path never sets `canRequestAds`.

**M2. The own-sheet exemption is too broad.**
- Where: `AdsService.swift:277-282`.
- Problem: any SwiftUI hosting controller counts as "ours". So an interstitial could be presented over the grown-up question sheet or any other app sheet. The plus-flow ruling lists the parental-gate sheet as one that must block. Only R3 needs to present over a sheet (the wake sheet). The risk is low today, because interstitial triggers come from Home and the resting card.
- Fix: `presentationAnchor(allowOwnSheet: Bool = false)`. Pass `true` only from `showRewarded` (or only for `.wake`). Interstitials then refuse any presented controller.

**M3. Likely red in the hold: the audit at AX5.**
- Where: `AdFormatsUITests.swift:103`.
- Problem: it runs the raw `.dynamicType` and `.textClipped` audit with no issue handler. The text-fit work showed that off-screen rows trip `.textClipped`; `TextFitScreensUITests.swift:48-70` filters them. Also, the audits the brief asks for on the wake sheet with R3 and on the toasts are missing.
- Fix: reuse the `auditOnce` and visible-frame filter from TextFitScreensUITests. Add a wake-sheet audit after `-uitest-wake-dreamed`.

**M4. The skip in the check script can be abused through an unsigned archive.**
- Where: `check-ad-ids.sh:23-30`.
- Problem: `ADS_CHECK_SKIP=1 CODE_SIGNING_ALLOWED=NO xcodebuild archive` skips the check. `-exportArchive` with signing options can still sign that archive for upload, which would ship Google's test ids.
- Fix: before honouring the skip, add `[ "${ACTION:-}" = "install" ] && { echo "error: Check ad ids: never skipped for an archive."; exit 1; }`.

**M5. Exit criteria not yet met (scope, not code).**
- Deferred until after the engagement merge, as STATUS says: the R2 resting-card row, B5 preload, the whisper leaf dot on Help, and the R1 free path on PlantDetailView. The whisper rung exists (`HelpLadder`, `GameViewModel`), but no UI can bank a whisper yet.
- B4 was fixed for Garden only. The Home banner is still `.frame(height: 50)` (`HomeView.swift:507`). Anchored adaptive banners are often taller than 50 pt, and Debug now uses the adaptive test id, so the Home banner can clip. Apply the same `height` binding when HomeView is next touched (engagement also edits HomeView).

### Low

- **L1. A treatment change after start is not applied** (`AdsService.swift:74`). `prepare` returns before `configure` once `started` is true. The age only changes from nil to a band (onboarding, `DataReconciler:45`), so this is low. Fix: call `Self.configure(treatment)` before the `!started` guard.
- **L2. `AdInputs.sheetUp` is never set** by `adInputs()` (`AppModel+Ads.swift:17-19`). The service check covers it, and that check is the stronger one. Either feed `!AdsService.canPresentFullScreen` or say "test-only input" in the comment.
- **L3. Hint and wake videos are never preloaded.** After any rewarded ad, only the water unit is preloaded (`AdsService.swift:235`), so hint and wake load on tap. During that wait there is no progress cue; the row is only disabled. Fix: preload `AdUnit.rewarded(perk)` and show a `ProgressView` while `watching`.
- **L4. `releaseAll` does not cancel in-flight loads.** A load that lands later is stored but never shown, because of the `suspended` guards. Harmless.
- **L5. The profile test is weaker than the brief asks** (`AdsServiceWiringTests.swift:253-257`). It checks that some names are present and some absent, not that the list equals the G3 list. The `Mirror` labels on a `@Model` may be `_x` or the backing data. Assert the exact set.
- **L6. VoiceOver hears two announcements on a gentle wake:** the toast and then `WakeSuccessView`'s own. Drop the toast announcement when `step` becomes `.awake`.
- **L7. Warnings, not errors:** `UIScreen.main` (`AdsService.swift:401`) and an unused `await MobileAds.shared.start()` result in the probe.
- **L8. The probe starts the SDK with no age gate.** It is Debug-only, test-id-only and skipped unless `WF_LIVE_ADS=1`. Acceptable; keep it skipped.

## Merge hazards

These come from `git merge-tree`.

- **Polish2 / text-fit (`a0f8716`):** STATUS.md conflicts (keep both sections). The pbxproj and WordFloraApp merge automatically.
- **Engagement (`aabade1`):** AppSettings.swift conflicts. Both sides add a device-local setting and its init line; keep both. AppModel, AppModel+Badges, WordFloraApp and the pbxproj merge automatically.
  - Engagement also edits GameView, HomeView and PlantDetailView. That is exactly where M5's deferred items land, so build them on top of the engagement merge.
- **Widgets (`aca9586`):** clean.
- **Recommended order:** polish2, then engagement, then widgets, then G4a. After that: rebuild, run `plutil -lint` on the pbxproj, and check the grep for `TARGETED_DEVICE_FAMILY`.

# G4b builder brief: app-open ad, collapsible Garden banner, native Shed card

Paste-ready. Written 2026-11-07. About 15 builder-hours. Sources: `docs/pm/admob-full-spec.md` (sections 0, 1.0 to 1.5, 4, 5 and the three "Review rulings" sections at the end, which win over earlier numbers), `docs/pm/g4a-builder-brief.md` (machine rules, section 0), `docs/pm/admob-full-spec-review.md` section 5 (H1, H3, H4, H6), `docs/pm/weak-spots-review-2.md`, `design-preview/admob/app-open-cue.svg`, `design-preview/admob/native-card.svg`.

**Precondition: G4a is merged.** That means `Rules/AdPolicy.swift` (`AdFormat`, `AdInputs`, `AdSessionState`, `AdDecision`, `AdBlock`, `AdCaps`, `AdLedger`, `decide`), the nine unit keys in `Config/Ads.xcconfig` and `Info.plist`, the fallback chain, the Release build-phase check, R1/R2/R3 and the shared prompt row/toast, and B1 to B8 are all in. Branch from the merged tip of `3-feat-content-and-polish`. If any of those is missing, stop and ask the lead. G4b adds **no stored field**; if you think one is needed, stop and report (the one CloudKit deploy is already done).

Real AdMob ids are never written in any file, commit, log or report. Refer to ids by xcconfig key name or last 4 digits.

---

## 0. Machine rules (paste at the top of your own working notes)

These are the G4a rules, unchanged except the names (G4b, `dd-g4b`).

```
RULES
- Worktree: your own, branched from 3-feat-content-and-polish. Never push. Never touch another worktree.
- One xcodebuild at a time on this machine. Take the lock dir /private/tmp/claude-501/wf-build.lock
  (mkdir; if it exists, wait and poll every 30 s; rmdir it when your xcodebuild exits, even on failure: use a trap).
- Always pass: -jobs 4 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1
  -test-timeouts-enabled YES -default-test-execution-time-allowance 120
- Your own simulator (xcrun simctl create "WF G4b iPhone 17" ...; write the UDID to your scratchpad; shut it down when done)
  and your own dd-g4b derivedData folder. Never share either.
- build-for-testing once per code change, then test-without-building per class.
- Watchdog: timeout and perl alarm do not stop xcodebuild. Use:
    ( sleep 2700; pkill -f "xcodebuild.*$UDID" ) & WD=$!
    trap 'pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null; rmdir /private/tmp/claude-501/wf-build.lock 2>/dev/null' EXIT
  The trap must do `pkill -P $WD; kill $WD` (the sleep is a child of the subshell; killing only $WD leaves the sleep and a later pkill can hit a newer xcodebuild).
- mediaanalysisd stays DISABLED on this Mac and on simulators. Do not re-enable it. If you think it must be enabled, ask the lead.
- Every new Swift file goes into its target in project.pbxproj; plutil -lint the pbxproj. TARGETED_DEVICE_FAMILY stays "= 1" everywhere (grep before every commit).
- Copy: every new kid-visible line goes into a *Copy.all list checked by CopySafety. Quiet Garden: no counts, no marks, no moments. Calm: CelebrationStyle.small. Reduce Motion: still or cross-fade.
- Commits: small steps, each must build. Plain messages in the user's voice. No attribution lines, no co-author line, no session line, and no tool, model or vendor names. Before you hand off run
    git log --format=%B <base>..HEAD | grep -icE "claude|anthropic|co-authored|opus|sonnet|session|fable"
  and confirm it prints 0.
- STATUS.md: add a dated section (what, tests, open items) in your last commit.
- Report: everything goes in your FINAL MESSAGE (tests run with counts, reds and why, shots checked by eye, files, commit hashes, open items). Do not claim green without the log.
- Worktree note: Config/Ads.local.xcconfig is git-ignored and absent from worktrees. Release builds from a worktree fail the G4a check by design; use CODE_SIGNING_ALLOWED=NO proof builds with the documented override, or symlink the file from the main checkout for a local Release build and never commit it.
```

---

## 1. Scope and order

1. Lifecycle plumbing (`lastBackgroundAt`, `launchedFromLink`, `roundWasInProgressAtBackground`, ad session start at cold launch or `.active` after 30 min away) and `startIfConsentAlreadyResolved` (H1) if G4a did not add it. ~1 h inside the app-open item.
2. App-open ad with the return cue (section 2). ~5 h.
3. Collapsible Garden banner (section 3). ~2 h.
4. Native card in the Shed (section 4). ~6 h.
5. Privacy report re-diff, owner-steps C3/C10/D8 wording check, `AdFormatsUITests` run (section 8). ~2 h.

Frozen scope: nothing beyond this list. Ideas go to the 1.1 backlog. All formats go through `AdPolicy.decide`; no format may check age or Plus itself. Unit keys already exist (`AdMobAppOpenUnitID`, `AdMobNativeUnitID`, `AdMobBannerGardenCollapsibleUnitID`); app-open and native with an empty id are disabled, never falling back to another format's id.

---

## 2. App-open ad (spec 1.2, rulings H1, H3, H4)

- **Trigger.** Scene `.active` and `decide(.appOpen, ...)` is `.yes`. Show the cue in the same frame, call `AppOpenAd.load(with:request:)`, present over the cue if the ad arrives within **2.5 s** and the cue is still up and not skipped; otherwise the cue lifts at 2.5 s and nothing is recorded. No preload at background time (4 h expiry).
- **Eligibility** (after `decide`'s common checks): `completedSessions >= 3`; last background at least 4 h ago (cold launches read `ledger.lastBackgroundAt`); `!roundWasInProgressAtBackground`; `!launchedFromLink` (URL, widget, notification, App Shortcut, Siri); `consentResolved && attResolved`; not Calm, not Quiet Garden, not night, no pending ceremony; `appOpen` ledger count under 1 for the day; at least 30 min since any full-screen ad; pushed (2/session, 6/day) and full-screen (4/session, 8/day) budgets not used. Teens `.teen`, adults `.adult`. Use the ruled numbers, not the stale spec 1.1 table.
- **H1:** the entry point is `startIfConsentAlreadyResolved`. It never presents UMP, never requests ATT, never calls `loadAndPresentIfRequired`. If consent is unresolved, there is no cue and no ad. Test with a spy (`requestConsent` and ATT counts stay 0).
- **H3:** a cold launch from a link or widget waits for `.onOpenURL` / scene routing before deciding about the cue; if a link arrives, no cue.
- **H4 (option b):** cache the last treatment in the ledger. On a cold launch show the cue from the cached treatment, and present the ad **only after entitlements are confirmed** (`entitlementsLoaded`). A Plus owner never sees an ad: if entitlements come back Plus, lift the cue and release the load. If the cached treatment is `.none` or absent, no cue at all.
- **Release on change (H5 applies):** if treatment becomes `.none` while a load is pending or an ad is cached, drop it.
- **Cue** (mockup `design-preview/admob/app-open-cue.svg`): full screen on the app background; still pot and sprout (no animation); "Welcome back" / "to your garden"; an "Ad" chip and "A short ad, then your garden"; three static dots; a full-width secondary button **"Skip to my garden"** (min 52 pt). All text `Theme.font`, `fixedSize(horizontal: false, vertical: true)`, no line limit, column in a `ScrollView` so XXXL scrolls rather than clips; one layout at all sizes; dark tokens in dark mode. VoiceOver: `.isModal`, reads "Welcome back to your garden. A short ad, then your garden." then Skip. Skip cancels the load and records nothing. On dismiss of the ad the cue fades (0.3 s) to the screen the player left; Reduce Motion: cross-fade only. The welcome-back card, if due, shows after the cue lifts or the ad closes.
- **Never over:** onboarding, the age gate, UMP, ATT, the paywall, any sheet, a puzzle in progress, the tutorial, Daily Bloom result, Calm, Quiet Garden, night (9 pm to 8 am), a pending ceremony.
- **Recording:** `recordFullScreen(kind: .appOpen)` on present only; `appOpen` day count, `lastFullScreenAt`, `lastBackgroundAt` (written at every `.background`) in the ledger; synced `lastAdAt` and `adsToday` as in G4a.
- **Copy:** cue strings in a `*Copy.all` list through `CopySafety`.

## 3. Collapsible Garden banner (spec 1.3, G4a handoff)

- Garden slot only (`GardenView` bottom `safeAreaInset`), anchored adaptive, `["collapsible": "bottom"]` extras. Home keeps the ordinary banner.
- **One `BannerView` has one unit id.** Create the Garden `BannerView` with the collapsible id (`AdMobBannerGardenCollapsibleUnitID`, fallback chain collapsible -> Garden -> Home). On `bannerViewDidReceiveAd` (collapsible or not) or on dismissal/collapse, swap in a second `BannerView` on the Garden/Home id (`AdMobBannerGardenUnitID`) for refreshes and non-collapsible loads (option a). Auto-refresh never requests a collapsible ad; no second manual collapsible request in the same session.
- Eligible when the Garden banner is eligible and: `completedSessions >= 3`, `collapsibleShown < 1` this session, ledger `collapsible < 2` today, not Calm, not Quiet Garden, `!voiceOverOrSwitchControl`, `!accessibilityTextSize`. Those last players get the ordinary banner, not no banner.
- Count `collapsibleShown` only when `bannerView.isCollapsible` is true in `bannerViewDidReceiveAd`.
- Frame height from `bannerView.adSize.size.height` (B4, already done in G4a); never a fixed 60 pt. The app adds nothing over the expanded state. Caption row below as on Home: "Go ad-free · Report an ad".
- Console note: refresh is off on the collapsible unit and 60 s on the Home unit (owner checklist, ruling 3).
- Confirm the Google collapsible test id returns a collapsible ad (G4a recorded the outcome; repeat in your report).

## 4. Native "SPONSORED" card in the Shed (spec 1.4, review notes)

- **Placement:** bottom of the Garden Shed, after the Pots section, under a section header "SPONSORED" and the line "Ads help keep WordFlora free." Never in the plant grid, Garden, Home, Plant detail, the puzzle or any child-visible surface (treatment `.none` shows nothing, not even the header).
- **Trigger:** on Shed appear, if `decide(.native)` is `.yes` and no ad is cached, `AdLoader` loads one `NativeAd`. Reuse a loaded ad across Shed visits for up to **30 min** (1 h is Google's ceiling; the spec's [verify] on this is resolved), then drop it. At most 1 load per 60 s, 6 loads per day (ledger `nativeLoads`). A native request is never the one that triggers UMP or ATT (`consentResolved` required; use `startIfConsentAlreadyResolved`). `completedSessions >= 2`. Quiet Garden: allowed (static, not a prompt).
- **Calm or Reduce Motion:** if `nativeAd.mediaContent.hasVideoContent`, do not display it and do not retry this visit. Video always `VideoOptions.startMuted = true`.
- **View:** UIKit `NativeAdView` in a `UIViewRepresentable` (`NativeAdCardView`), asset views registered with the `NativeAdView`.
  - Flat muted fill (`#F1EEE6` light, `#22362A` dark), 1 pt border at 22 to 26 percent text colour, radius 12. Deliberately not the game's `Card`, tile or pot style: no leaf art, no shed-points chip.
  - "Ad" badge top-left, 13 pt heavy text on a filled chip, at least 20 pt tall and wide (Google's minimum is 15 px), then the advertiser. AdChoices top-right via `preferredAdChoicesPosition = .topRightCorner`, inset so nothing overlaps it.
  - Icon (40 pt) + headline (`numberOfLines = 0`); `MediaView` full width 16:9, at least 120 pt in either dimension, `.scaleAspectFit`; body (`numberOfLines = 0`); optional stars and store; call to action: outlined button, full width, min 48 pt, Dynamic Type safe (wraps, grows), never the game's filled primary style.
  - Only asset views are clickable; the card background is not; no app control overlaps any asset.
  - `UIFontMetrics` scaled fonts with `adjustsFontForContentSizeCategory = true`; headline and body never truncated; one layout at every size; no `ViewThatFits`, no Dynamic Type cap.
  - VoiceOver order: Ad badge ("Advertisement"), advertiser, headline, **MediaView**, body, call to action, AdChoices; the group label starts with "Advertisement." (MediaView must be in the order, review ruling.)
- **Fake assets for tests:** `-uitest-ads-fake` renders the same `NativeAdCardView` from a fake asset set, not registered with Google, labelled "Advertisement". The fake and all debug parsing compile out of Release (H6).

---

## 5. Calm guarantees recap (all three formats)

Never during a puzzle in progress, the tutorial, onboarding, around the Daily Bloom result, after a lost round, or in a `quietVisit`. Never over onboarding, consent (UMP, ATT), the age gate, the puzzle, Calm, or Quiet Garden for app-open and collapsible. Under-13, unknown age and Plus see none of these and the SDK never starts (treatment `.none` is checked first in `decide`). Widget, notifications and Live Activities never show ads.

---

## 6. Acceptance tests

**Unit (`WordFloraTests/AdPolicyTests.swift`, extend; plus a new `AdFormatsPolicyTests` if clearer):**
1. App-open rows: `completedSessions` 0, 1, 2 no, 3 yes; background 3 h 59 min no, 4 h yes; round in progress no; from link no; consent pending no; adult ATT not determined no; teen with ATT undetermined yes (`attResolved` true); Calm, Quiet, night, ceremony no; second of the day no; 29 min after any full-screen no; 30 min yes; pushed or full-screen budget used no; entitlements not loaded no.
2. Collapsible rows: session 2 no, 3 yes; second in session no; third in day no; Calm, Quiet, VoiceOver/Switch Control, AX size: no collapsible but the plain banner still yes; counted only when `isCollapsible`.
3. Native rows: consent pending no; session 1 no, 2 yes; load gap 60 s and 6 loads per day; Calm + video not shown; reuse window 30 min then dropped.
4. The G4a never-for-under-13, unknown and Plus table and 1,000-input seeded fuzz now include `appOpen`, `collapsible` and `native` with the real callers wired; all `.no(.ageOrPlus)`.
5. Service wiring (extends the B1 spy): for `nil`, `.under13` and Plus, `showAppOpenIfEligible`, `loadNativeIfEligible` and `requestCollapsibleIfEligible` never increment `prepareCount` and never ask UMP or ATT. For `.thirteenPlus`, `prepare` receives `.teen` and ATT is never reached. App-open and native never call `requestConsent` when consent is unresolved (`startIfConsentAlreadyResolved` spy).
6. H4: cold launch with cached treatment `.teen` then entitlements Plus: the cue lifts, no ad presented, load released. Cached `.none`: no cue.
7. Ledger: new counts reset at day rollover; JSON round trip; corrupt reads empty. `Models/` diff is empty; the property-list test from G4a stays green.
8. Release scan: the Release bundle has no Google test ids and none of `uitest-ads-fake`, `adcaps` strings; Debug build has only test ids.

**UI (`AdFormatsUITests`, Debug, `-uitest-ads-fake`, `-adcaps` / `-uitest-adcaps-fast`):**
- App-open: `-adcaps appOpenMinBackground=2,appOpenMinSessions=0` plus `XCUIDevice.shared.press(.home)` and `app.activate()`: cue shows with the "Ad" chip and "Skip to my garden"; Skip returns to the screen left; no cue with `-uitest-onboarding`, under-13, Plus, Calm, Quiet Garden, a round in progress, or a link launch.
- Native: Shed shows "SPONSORED" header and the fake card below Pots; "Advertisement" is read first; absent for under-13, Plus; Calm with a fake video asset: not shown.
- Collapsible: Garden for an adult shows the collapsible path once per session (fake); not under VoiceOver-on-launch argument or AX size.
- One live smoke class `AdFormatsLiveUITests` with real Google test ids, skipped in CI and on the build box under load; run it once by hand if the machine is quiet and say so in the report.

**Never-over matrix (UI or unit, each must show no cue and no ad):** onboarding, consent flow, a puzzle in progress, Calm, Quiet Garden.

## 7. UI audit expectations

`performAccessibilityAudit` in light and dark, default size and `accessibilityExtraExtraExtraLarge`, on: the app-open cue (including Skip reachable at XXXL by scrolling), the Shed with the fake native card (header, badge, headline, media, body, CTA), the Garden with the collapsible fake banner and caption row, and any new toast. Expect: no truncation (layout-report pattern, `label.isTruncated` false), no clipped CTA, contrast 4.5:1 on sub-lines, targets at least 44 pt (48/52 pt where specified), no `ViewThatFits`, no `.dynamicTypeSize(` caps, no `lineLimit` on ad or prompt text in the diff. Read each saved screenshot by eye (all eight audit shots) and say what you saw. Every new string through `CopySafety`.

## 8. Release and owner notes

- Privacy report re-diff (B2) after the native and app-open code is in. No new data types are expected (same SDK); confirm against `docs/setup/age-rating-and-privacy-label.md` and `PrivacyInfo.xcprivacy`. Report any tracking domain added.
- `docs/setup/owner-setup-steps.md`: D8 gets the return-ad sentence now that app-open ships: "A return ad may appear at most once a day after 4 hours away, behind a 'Skip to my garden' screen." C3/C10 counts stay as G4a left them. Check the console checklist (ruling 3): collapsible refresh off, native unit has image and video on, app open unit is the App open format.
- Ruled options if G4b is not green by G6 start: O5, ship the code switched off by a compile-time flag (not remote) and say which format. Do not decide it yourself; report to the lead.
- STATUS.md dated section in the last commit.

## 9. Exit criteria and report

Exit: app-open rows green; never-for-under-13 table and fuzz green with the new callers; service spies green; cue audit green at XXXL light and dark; native audit green; collapsible handoff proven; no `Models/` diff; Release bundle has no test ids and no fake-presenter strings; privacy report matches the label; full unit suite; the UI classes you touched (`AdFormatsUITests`, `GardenUITests`, Shed tests, `HomeLayoutUITests` banner slot, `ParentalGateLinkUITests`).

Final message must contain: commit hashes in order, test counts and reds with reasons, shots checked by eye, the collapsible test-id outcome, privacy report outcome and any tracking domains added, the grep-for-attribution result (prints 0), the sentence "no stored field added" with the empty `Models/` diff, and open items. Do not write the report to a file.

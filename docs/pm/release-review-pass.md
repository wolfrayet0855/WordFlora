# Release review pass (App Review and product), 2026-11-08

Read-only review of what will ship: the integration branch (worktree `agent-a7c8dfd77f34b6d62`, tip `0040e11`) plus the G4b ad formats (`agent-aa8a8cbc90a62b13c`, tip `b396891`) and G5 Frost & Lantern (`agent-ad56e62443b14b215`, tip `65a78e4`). Line numbers are from the G4b worktree unless marked G5. No build, no simulator, no device: everything here is from source and the docs, so "verified" below means "read in the code", not "seen running". Reviewed as App Review would (guidelines 1.3, 2.1, 3.1.1, 3.1.2, 4.x, 5.1.1, 5.1.2, 5.1.4, Family Sharing, ads for 13 to 17, UMP/ATT, age and parental gates, the privacy label) and as a product reviewer (first run to first plant, Home cards, Settings, Seasons, Calm and Quiet Garden, copy, dark patterns), then reliability, build settings and the owner docs.

## Ship readiness

**No guideline blocker in the code.** The under-13 / unknown-age / Plus "no SDK, no consent form, no tracking prompt, no ad" guarantee is one function checked first (`Rules/AdPolicy.swift:129-148`), both SDK starts refuse `.none` (`Ads/AdsService.swift:65-66, 100-101`), and the banner views mount only after `ads.started`. The paywall carries price, period, renewal, cancel, Terms and Privacy (`Rules/Paywall.swift:112-129`, `Views/PlusView.swift:432-434`); there is exactly one Restore, in Settings, never behind the grown-up question (`Views/SettingsView.swift:105-114`); refunds, revocation, Ask to Buy, cancelled and unverified transactions are handled (`Services/EntitlementService.swift:86, 130, 136`). Models are byte-identical across the three branches; `lastMistedAt` is still the only new stored field.

What stands between here and Submit is not code: the CloudKit Production deploy, the archive from the main checkout with `Config/Ads.local.xcconfig` (present there, 2026-11-07), the AdMob consent messages, and a set of review-note and store-copy corrections where the docs drifted from the code (ads start in session 2, not 3; Settings section names; where Restore lives). Fix the Should-fix list below in the G6 builder window, then the device list at the end is what must be seen on a phone.

## Findings

### Blocker (release-gating, all owner, all already on the owner list)

| # | Finding | Evidence | Minimal fix | Who |
|---|---|---|---|---|
| B1 | CloudKit Production has not been deployed; the ledger is empty. A Plus buyer on day one would sync nothing, silently. | `docs/setup/cloudkit-new-fields.md:67-76` (no deploy recorded); 26 fields since `main` (7 `PlantCollectible` incl. `lastMistedAt`, 19 `PlayerProfile`); `WordFlora/Models/*` identical on baseline, G4b and G5 (one deploy covers all) | Parts 1 to 3 of `docs/setup/cloudkit-deploy-straight-to-prod.md` before the archive. Write the deployed commit hash into `cloudkit-new-fields.md`. | Owner |
| B2 | Archive must come from the main checkout: `Config/Ads.local.xcconfig` exists only there. In a worktree the Release "Check ad ids" phase fails (correct) and cannot be skipped for an archive. | `tools/ads/check-ad-ids.sh:22-35, 54-66`; main checkout `Config/Ads.local.xcconfig` present 2026-11-07 | Already in `g6-device-checklist.md` Part B step 1. No change. | Owner |
| B3 | GDPR and US-state consent messages must be published in AdMob, or UMP returns an error for EEA/UK adults and the SDK never starts for them (no ads, no crash). | `Ads/AdsService.swift:74-94` (consent step gates `start`) | AdMob > Privacy & messaging: publish both; add **no** IDFA explainer (it would show ATT to teens). | Owner |

Not a new blocker: all three are in `docs/pm/live-status.md` "Owner items open" and the G6 checklist. The lead was not messaged separately for them.

### Should fix before submit

| # | Finding | Evidence | Minimal fix | Who |
|---|---|---|---|---|
| S1 | **"Ads begin from the third session" is not what the code does.** `completedSessions` increments at launch, so in session 2 it is 1: the banner (`AdPolicy.swift:176`), the rewarded rows (`:213`) and therefore the UMP form and ATT prompt (`HomeView.swift:191` → `AppModel.swift:576-579`) all arrive in session 2; the interstitial can arrive in session 2 after one word level-up (`Rules/AdGate.swift:44`). App open and collapsible need 3 completed sessions, native 2. A reviewer told "no ads until session 3" who sees a banner in session 2 reads it as a metadata mismatch. | `owner-setup-steps.md:613` (D8), `:581` (D6b), `store-listing.md:64`, `g6-device-checklist.md:153` | Reword the docs, not the code (the 2026-11-03 ruling in STATUS.md was "ads start in session 2, never session 1"): "A banner may appear from the second session; full-screen ads (interstitial, return ad) from the third session or after the first level-up, and only after the player's own tap." | Owner (docs) |
| S2 | **D8 review notes describe a Settings that no longer exists.** The Purchases section is titled "Purchases" for every age (`Rules/Paywall.swift:257`), not "For grown-ups"; Restore is in Settings only, yet D8 says "Plus page > Restore purchases" and "The page also has Restore purchases"; the Settings list at `:602` omits Play, Help, Comfort, Garden, Your garden, Privacy and ads, About; "never in Calm mode, Quiet Garden" is true of the return ad, collapsible and rewarded prompts only, the plain banner and the interstitial stay (spec 0.3, `docs/pm/admob-full-spec.md:45`); E checklist still says "3 ad units". | `owner-setup-steps.md:602, 605-608, 613, 656`; actual labels in the Settings table below | Rewrite those lines from the Settings table below; keep "Restore purchases is its own row in Settings > Purchases (the only one in the app)" from `:114`. | Owner (docs) |
| S3 | **iPhone landscape is enabled and was never tested.** Every UI test and shot is portrait; a reviewer who rotates sees untested layouts. | `project.pbxproj:2038, 2072` `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = Portrait LandscapeLeft LandscapeRight` | Set the key to `UIInterfaceOrientationPortrait` on both configurations. Do it after G5 lands (pbxproj collisions). | Builder |
| S4 | `-uitest` master switch is compiled into Release: a launch argument wipes standard and App Group defaults, grants Plus, sets the age band, skips onboarding. Reachable only from Xcode/devicectl, so low exposure, but one line removes it. | `App/WordFloraApp.swift:15, 36-37, 39, 107, 141`; `EntitlementService.debugForce/debugPreviewPrices` ungated | `let uiTesting: Bool = { #if DEBUG return args.contains("-uitest") #else return false #endif }()`; same for `-uitest-sessions=`, `-uitest-daytime`, `-uitest-ads-offline` (`WordFloraApp.swift:254-259`, `AppModel.swift:434`). | Builder |
| S5 | Partial product load leaves the Plus page on "Loading prices" for ever with no Try again: `loadFailed` is set only when nothing loads, and `selected == .yearly` is never offered if `plus_yearly` alone is missing. | `Views/PlusView.swift:119-140`, `EntitlementService.swift:61` | After loading, if `!offers(selected)` pick the first offered plan or show the Try again card. | Builder |
| S6 | Home cards stack: the Plus offer card checks weather but not `showWelcomeBack`, so after 3+ days away at a milestone both show. The weekly note already yields to everything. | `App/AppModel.swift:642` (guard), `Views/HomeView.swift:140-149` | Add `!showWelcomeBack` to the guard at `AppModel.swift:642`. | Builder |
| S7 | "Show streak" toggle does nothing: `showStreak` is read nowhere but Settings. A reviewer flipping it sees no change (2.1 completeness). | `Views/SettingsView.swift:28`; no reader of `AppSettings.showStreak` | Remove the row (StreakEngine already rests silently, `Rules/StreakEngine.swift:51`). | Builder |
| S8 | Two force unwraps in process-critical paths: the widget builds `URL(string: "wordflora://plant/\(plantId)")!` (ids are URL-safe today; a future id with a space kills the widget process), and G5 keys a `ForEach` on `\.first!.id`. | `Shared/WidgetActions.swift:177`; G5 `Views/FrostLanternViews.swift:155` | `URL(string:) ?? emptyURL(unavailable: false)`; `ForEach(Array(rows.enumerated()), id: \.offset)`. | Builder |
| S9 | Widget timelines reload on `.inactive` and `.background` (two per backgrounding, one per Notification Center pull-down) plus once per intent. | `App/WordFloraApp.swift:305`; `WordFloraWidget/GardenWidget.swift:24, 46`; `Shared/GardenIntents.swift:21` | Reload on `.background` only. | Builder |
| S10 | Store listing says "free with ads for grown-up players"; 13 to 17 see ads too. The D6b sentence ("players 13 and over") is the accurate one. | `store-listing.md:64` | Use the D6b sentence. | Owner (docs) |

### Nice to fix (before submit if the builder window allows; none would fail review)

| # | Finding | Evidence | Minimal fix | Who |
|---|---|---|---|---|
| N1 | Trial length is a literal "3 days"; eligibility is conditional on `isEligibleForIntroOffer` (correct) but the period never reads `introductoryOffer.period`. Fine while ASC says 3 days. | `Rules/Paywall.swift:112, 120`, `PlusView.swift:160`, `EntitlementService.swift:64-69` | Format the period from the offer. | Builder |
| N2 | "Report an ad" opens Google's AdMob *publisher* help centre, which is not where a player reports an ad (the AdChoices icon on the ad is). | `Views/PlusView.swift:436` | Point it at the support page, or drop the row and keep "Ad privacy choices". | Builder + owner |
| N3 | Two Manage-subscription mechanisms: an external `apps.apple.com` link (gated) in two places and the in-app `manageSubscriptionsSheet` in two others. | `PlusView.swift:65, 87, 236`, `SettingsView.swift:123` | Use the sheet everywhere. | Builder |
| N4 | Terms and Privacy footer renders after the buy buttons; on screen, functional, but a reviewer scrolls for it. | `PlusView.swift:51, 59-73` | Optional: move the fine print above the CTA. | Builder |
| N5 | About section holds only Version; no support link anywhere in the app; the age answer can only be changed by reinstalling and the app never says so. | `SettingsView.swift:146-148`; no writer of `ageBand` outside onboarding | Add a Support row (`shapehaveninnovations.com/support.html`, gated) and one footnote under Comfort: "You chose your age group when WordFlora first opened. To change it, delete and reinstall." Review notes must not say "About > Privacy Policy". | Builder |
| N6 | Remove the N6 App Group `print` once the owner has read it (Debug only, no Release effect). | `WordFloraApp.swift:51-56` | Delete after the device check. | Builder |
| N7 | `aps-environment` is `development` in the Release entitlements file; Xcode rewrites it to `production` at App Store export with automatic signing. Confirm rather than assume. | `WordFlora/WordFlora.entitlements` | Organizer > archive > entitlements shows `aps-environment = production`. | Owner (verify) |
| N8 | Rewarded tap can wait on a cold load with no cap; `requestConsentInfoUpdate` runs on every `prepare` while unstarted. | `AdsService.swift:231`, `:74-83, 131-143` | ~8 s timeout; remember the consent answer per visit. | Builder |
| N9 | Widget opens a new `ModelContainer` per timeline entry (up to 3). Launch decodes Words.json (159 KB), Plants.json, Badges.json twice, and `syncGlasshouse()` fetches at init and on every Garden appearance (G5). PlantThinning.json (334 KB) decodes on main at first plant render. | `GardenWidget.swift:99`; `AppModel.swift:86, 113`; G5 `GardenView.swift:56`; `Components/LayeredPlantView.swift:5` | Open once per `getTimeline`; prefetch thinning on a background task. Measure cold start on the device first. | Builder (1.0 only if cold start is slow) |
| N10 | `Config/WordFlora.storekit` ships inside the app bundle (Copy Resources). Harmless, 2 KB, but it is test data. | `project.pbxproj:303, 1413` | Remove from the app's Resources phase (the test target loads it). | Builder |
| N11 | Quiet Garden and Calm keep the plain banner for 13+ free players (spec ruling 0.3). Consistent with the copy ("hides counters and wait times") but a reviewer may expect "quiet" to mean no ads. | `AdPolicy.swift:175-176`, `admob-full-spec.md:45` | Keep for 1.0; make sure no review note says otherwise (S2). Consider hiding the banner in Quiet Garden in 1.1. | PM |
| N12 | Sound provenance: the 28 `wf-*.m4a/.caf` files are described as synthesized or procedural (`docs/research/audio-feedback.md:101, 219`) but no manifest records that. The listing's "No third-party content" is marked VERIFY. | `WordFlora/Resources/Sounds/`, `store-listing.md:25` | Owner confirms every sound, word, fact and SVG is original or licensed, and a one-paragraph provenance note goes in `docs/research/audio-feedback.md`. | Owner |
| N13 | `owner-setup-steps.md` C4 quotes an older `NSUserTrackingUsageDescription`; the plist text is "This lets us show ads that are more relevant to you. You can still play fully if you say no." (honest, fine). | `WordFlora/Info.plist:233-234`, `owner-setup-steps.md:427-428` | Align the doc. | Owner (docs) |

### 1.1

- A subscriber cannot buy Plus Forever: `hasPlus` hides every plan (`PlusView.swift:49-51`). Product gap, not a guideline issue.
- Stale Plus cache can raise the return cue for up to 2.5 s for a Plus owner (`Rules/AdFormatRules.swift:79-81`).
- Home banner ignores the Debug fake presenter while the Garden slot honours it (`HomeView.swift:534` vs `Ads/GardenBannerSlot.swift:57`).
- `NSPrivacyTrackingDomains` stays empty; both Google manifests declare none (G4a B2). Re-check against the archive's privacy report at G6 and add any domain it lists.
- Sync toggle needs a relaunch by design (`AppModel.swift:961`); an unknown deep-link plant id lands on "Coming soon" (`PlantDetailView.swift` ~67), route to the garden instead.
- Family Sharing grown-up note appears weekly in a child's Settings (`Rules/FamilyShareNudge.swift:40`); gated and addressed to grown-ups, acceptable.
- The scheme's uncommitted edit adds an empty `Development` environment variable to Run only; it has no effect on Archive. Leave it to the owner as agreed.

## Guideline walk-through

| Guideline | Finding |
|---|---|
| 1.3 Kids Category | Not opted in; nothing "for kids" in name, subtitle, description or keywords (`store-listing.md`). The mixed-audience story is real: under 13 and unknown age never start the SDK (`AdPolicy.swift:134`), get Calm by default (`AppSettings.swift:87, 122`), no share (`Rules/Share.swift:23`), no names on the widget (`WidgetActions.swift:35`). |
| 2.1 Completeness | No dead ends in first run (intro → age → optional Quiet Garden → Guide with Skip → tutorial → tip with "Not now"; `OnboardingView.swift:54-77, 260`, `GuideView.swift:76-86`). Dead control: "Show streak" (S7). Untested orientation (S3). Partial product load spinner (S5). |
| 2.3.6 / 2.3.8 metadata | Age rating answers in `age-rating-and-privacy-label.md` A3; expected 4+ (accept 9+). Review notes need S1/S2/S10. |
| 3.1.1 IAP | All four products through StoreKit 2; no external purchase links; the Redeem row uses Apple's sheet (`PlusView.swift`). Offer codes are a server-side owner item. |
| 3.1.2 Subscriptions | Price, period, "Renews automatically unless cancelled at least 24 hours before…", "Cancel anytime in your App Store account settings", Terms (stdeula) and Privacy links on the paywall (`Paywall.swift:112-129`, `PlusView.swift:59-73, 432-434`). Trial wording only when eligible and only on yearly (`EntitlementService.swift:64-69`, `Paywall.swift:114`). Restore reachable in Settings. Lifetime + subscription overlap shows "charged twice" with a gated Manage link (`PlusView.swift:232-237`). Description carries the same terms (`store-listing.md:68-70`). |
| 3.1.2(c) / Family Sharing | All four products Family Sharing on (owner done); `ownershipType` family-shared counts as owned; a family member gets Plus via Restore. Device check only. |
| 4.x | Native iOS, no web view, no templates. 4.2: the Guide, Daily Bloom, weather, visitors, badges, widget, Siri intent give it more than minimum functionality. |
| 5.1.1 Data collection | No account, no credentials, no first-party analytics, no network calls of our own (grep: no `URLSession`, no custom hosts). Only AdMob/UMP collect. Consent withdrawal: "Ad privacy choices" row when `privacyOptionsRequired` (`SettingsView.swift:142-143`). Garden data is the player's own CloudKit private DB. |
| 5.1.2 ATT | Prompt only for 18+ without Plus, only after UMP says ads may be requested, only when `.notDetermined` (`AdsService.swift:84-86, 146`, `AdGate.swift:110`). Declining never limits play. Purpose string honest. |
| 5.1.4 Kids | Age screen asks a band, not a birthdate (`OnboardingView.swift:70-77`); the game is complete at every band; the parental gate (13 to 19 × 8 to 9, `Paywall.swift:231-236`) wraps every purchase, Redeem, Manage, Terms, Privacy and external link for under 13 and unknown (`PlusView.swift:256-261, 417`, `SettingsView.swift:209-213`, `SeasonsView.swift:82-86`, `FamilyShareNudgeRow.swift:48-49`); the Shed shelf and prices are hidden from children (`SeasonsView.swift:206-207`, `ShedView.swift:35`). |
| Ads for 13 to 17 | `ageRestrictedTreatment = .teen`, `maxAdContentRating = .general` for every age, set before `start()` (`AdsService.swift:111-112, 125-129`); UMP request tagged under age of consent; no ATT step in the teen plan (`:27`). |
| UMP then ATT | Adult plan `configure → consent → tracking → start` (`AdsService.swift:28, 79-94`); app open and native never trigger UMP or ATT (`AdPolicy.swift:197, 208`). |
| Ad formats | Native card: "Sponsored" header, "Ad" badge, AdChoices registered top-right with nothing overlapping (`Ads/NativeAdCardView.swift:181-186, 200-207`). Collapsible never with VoiceOver, Switch Control or AX text sizes, once per visit (`AdPolicy.swift:182-183`). App-open cue has a real Skip, never from a link/widget/notification/Siri launch, never over a round or another sheet (`AdPolicy.swift:191-204`, `AdFormatRules.swift:74-101`). Rewards only in `userDidEarnReward`; no fill hides the row and the free path remains (`AdsService.swift:210, 238`). |
| Privacy label vs code | App manifest: Device ID (linked, tracking), Advertising Data, Product Interaction, Coarse Location (linked), Performance, Other Diagnostic, Crash Data; UserDefaults CA92.1 + 1C8F.1; no other required-reason API used (grep clean). This equals B1 in `age-rating-and-privacy-label.md` and Google's SDK manifest (G4a B2). Widget manifest declares nothing. Label answers in that doc are correct as written. |
| Build settings | iPhone only (`TARGETED_DEVICE_FAMILY = 1` both targets), iOS 17.5, automatic signing team `P9Z5QB8965`, no stale profile specifier, `ITSAppUsesNonExemptEncryption = NO`, 1.0 (1) on app and widget, Release whole-module, `Config/Ads.xcconfig` on both app configurations, "Check ad ids" phase last on the app target and un-skippable for `install`/`archive`, SwiftPM google-mobile-ads 13.12.0 + UMP 3.1.0 with their own privacy manifests, 50 SKAdNetwork ids. `FoundationModels` is imported at file scope with a 17.5 target (`AI/GardenAI.swift:3`); the system auto-weak-links it and the iOS 18.5 simulator runs confirm launch without it. |
| Content rights | All art is SVG drawn in-repo (`design-preview/`), sounds described as synthesized or procedural, words and facts with sources in `Words.json` and `docs/research/`. No attribution manifest (N12). |
| Offline | Products fail to load → load-failed card with Try again (except S5); Restore offline → "Couldn't reach the App Store" (`Paywall.swift:172`); ads unstarted → blank slot, rows hidden; no network needed for play. |
| Accessibility | Keyboard keys and tiles labelled (`KeyboardView.swift:125-126`, `WordTilesView.swift:98-99, 135`); one `.dynamicTypeSize(.large)` cap on a badge picture only (`BadgeDetailView.swift:101`); snow and confetti still under Reduce Motion; icon buttons labelled. English only, no `.strings`; prices from StoreKit formatting; "USD" only in a UI-test preview path. |

## Settings labels as shipped (for the D8 rewrite)

| Section | Rows |
|---|---|
| Play | Word difficulty (Auto / Gentle / Standard / Tricky); Show streak (S7); 13+ and not Calm/Quiet: Speed bloom, Extra time |
| Help | Show the guide again |
| Comfort | Sound; Garden ambience; Haptics; Calm mode; Quiet Garden; footnote "Calm mode removes the thirsty look and halves celebrations. Quiet Garden hides counters and wait times so tending is just relaxing." |
| Garden weather (hidden in Quiet Garden) | Garden weather; Wild Weather (confirm alert "Turn on Wild Weather?" / "Turn it on" / "Not now"; under 13: "Ask a grown-up if you like."); Tell me about garden weather |
| Reminders | Gentle daily reminder; Time (08:00 to 20:00); "At most one a day, never at night, and they stop on their own if you take a break." |
| Garden | Show everything |
| Purchases | under 13 / unknown: "WordFlora Plus"; 13+: "Remove ads and sync with iCloud"; owned: "WordFlora Plus is on · Yearly/Monthly/Forever"; Seasons (gated; only while a pack is offered or owned); Restore purchases; Manage subscription (subscribers only, gated); Family Sharing note; iCloud status row |
| Your garden | Back up my garden; Restore from a backup |
| Privacy and ads | Report an ad (gated); Privacy Policy (gated); Ad privacy choices (EEA/UK only) |
| About | Version |

## Must be verified on a device (nothing here has run on a phone yet)

StoreKit (sandbox against the production build, no TestFlight pass planned):
1. Paywall: three rows, ASC prices, "3 days free" on Yearly only and absent on a second sandbox account that already used the trial.
2. Buy yearly → Plus on, ads gone, iCloud row changes; buy monthly, buy Plus Forever, buy `pack_frost_lantern` (pots, scene, robin and wren, snowdrop and hellebore appear).
3. Ask to Buy child account: "Sent to a grown-up to approve", nothing unlocks, approval turns Plus on without relaunch.
4. Refund in sandbox → Plus off at the next refresh; expired subscription → iCloud row "comes with Plus", garden intact.
5. Delete, reinstall, Settings > Purchases > Restore purchases brings Plus and the pack back; offline Restore reads "Couldn't reach the App Store".
6. Family Sharing on a second family member's device (TestFlight is the only honest route; otherwise accept the gap). Offer codes `GARDENFRIEND`, `WELCOMEBACK` via the Redeem row.
7. Under-13 fresh install: every buy, Redeem, Manage, Terms, Privacy, Report an ad sits behind the grown-up question; no price anywhere.

Ads, consent, age:
8. Adult in simulated EEA: UMP form, then ATT, then a banner, in that order, in session 2; "Ad privacy choices" row present in EEA and absent elsewhere.
9. 13 to 17: UMP yes, no ATT prompt, G-rated creatives.
10. Under 13 and no age answer: three sessions, no ad, no form, no prompt, no `GADMobileAds` log line.
11. Real units: Home and Garden banner, collapsible on the first Garden visit (and the plain banner under VoiceOver or AX sizes), interstitial on "One more", rewarded water/hint/wake (early close → no reward; no fill → row hidden), native "Sponsored" card with a tappable AdChoices icon, return cue after 4 h away with a working Skip, none after a reminder, widget, Siri or link launch. Add the phone as an AdMob test device first.
12. Archive: `plutil -p Info.plist | grep -c 3940256099942544` is 0; entitlements show `aps-environment = production`, the App Group and the iCloud container.

Data, widget, launch:
13. CloudKit Console Production lists `CD_PlantCollectible` (33), `CD_PlayerProfile` (51), `CD_GameRecord` (9); two Production devices with Plus sync both ways; a Plus user signed out of iCloud sees "needs a sign-in".
14. Widget on Home and Lock Screen renders; water button and "Said hello" update the app; Lock Screen hides the nickname; a glasshouse plant as widget hero renders; deep links open the plant; Control Center and Siri "Water my garden" with the app killed.
15. Cold start time on the oldest supported phone you have (PlantThinning decode on first plant render); launch on an iOS 17.x device if one is available (FoundationModels weak link).
16. Release build launched from the Home Screen shows onboarding and the age screen (no `-uitest` behaviour).

Feel and accessibility:
17. Sounds and haptics (`g6-device-checklist.md` C7), Dynamic Type at AX5 on Home, Garden, Shed, paywall and the grown-up sheet, VoiceOver through one round, Reduce Motion (snow still, win burst still), Low Power Mode, 20-minute crash run with airplane mode, background/foreground and an interrupted purchase.
18. Rotate the phone on Home, the puzzle and the paywall (until S3 lands).

## Documentation corrections (owner, before pasting into App Store Connect)

- `owner-setup-steps.md` D8 `:602` Settings list → the table above; `:605` section title "Purchases" for every age; `:606, 608` Restore is in Settings, not on the Plus page; `:613` session wording (S1) and "never in Calm mode, Quiet Garden or at night" scoped to the return ad; `:656` "8 ad units"; `:427-428` the tracking purpose string (N13). Reviewer path for an ad: "pick 18 or older, finish one session, relaunch: the consent form (where required), then the tracking prompt, then a banner on Home."
- `store-listing.md:64` "for grown-up players" → the D6b sentence (S10); `:25` content rights confirmed (N12); `:60` keep "Dark mode, large text sizes, VoiceOver and a Sound switch" (all present: Settings > Comfort > Sound; appearance follows the system).
- `g6-device-checklist.md:153` session wording (S1); `:124` already correct (one Restore, in Settings).
- `cloudkit-new-fields.md` ledger: record the deploy (B1).
- `age-rating-and-privacy-label.md`: correct as written; add the Settings row name "Ad privacy choices" to D for 5.1.1(ii).

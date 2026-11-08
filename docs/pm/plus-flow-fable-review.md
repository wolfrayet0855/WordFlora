# Plus purchase flow and iCloud status: Fable review

Date: 2026-11-07, late evening. Read-only review (no build, no simulator). Owner tested a Debug build on a device and said, in short: Restore purchases is there twice; too much text; Restore does not belong on the WordFlora Settings page; test ads showed while buying Plus; "iCloud sync is on" is nowhere to be seen; after buying there was no clear sign of being on Plus or of iCloud working. Two Xcode log lines came with it (section 6).

**Baseline for every line number below: the text-fit builder's commit `d365fff`** (worktree `.claude/worktrees/agent-a2bea51afc81e7059`) for `PlusView.swift`, `Paywall.swift`, `FamilyShareNudge*.swift`, `EntitlementService.swift`. `SettingsView.swift`, `AppModel.swift`, `WordFloraApp.swift`, `AdsService.swift`, `Sound.swift`, `ReadAloud.swift` are unchanged there, so main (`5a73610`) numbers hold. This spec is a **delta on top of d365fff**. Where it supersedes a textfit-brief item it says so.

Owner-rule reminders for the builder: every new line into a `*Copy.all` list checked by `CopySafety` (banned words that bite here: **"last", "only", "waiting", "left", "empty"**); no new SwiftData field (`Models/` diff empty); plain commit messages; one pass, then hand back.

---

## Do now (text-fit builder, one pass on top of d365fff)

### N1. Restore purchases: exactly one, on the Plus page footer

Where it is today (d365fff):

| # | Place | Code | Verdict |
|---|---|---|---|
| 1 | Plus page footer button | `PlusView.swift:57-65` (`plus.restore`, `PaywallCopy.restore`) | **Keep. The one Restore.** |
| 2 | Plus page Family row, 13+ without Plus | `PlusView.swift:54` `FamilyShareNudgeRow(placement: .plusPage)` → text "Already have Plus on a family phone? Restore purchases is below." (`FamilyShareNudge.swift` `Copy.plusPageLine`) | **Remove the row from the Plus page.** It still says "Restore purchases" a second time in words, 40 pt above the button, and it is text the owner asked to cut. |
| 3 | Settings Family row button, 13+ without Plus | `SettingsView.swift:88` `FamilyShareNudgeRow()` → `FamilyShareNudgeRow.swift:56-68` `restoreButton` (`familyShare.restore`) | **Remove.** Owner: no Restore on the Settings page. |
| 4 | Plus page messages that name it | `PaywallCopy.pendingSlow`, `.failed` ("…tap Restore purchases.") | Keep: they point at button 1 and only show after a purchase attempt. |
| 5 | Seasons page | `SeasonsView.swift:22` (`seasons.restore`) | Keep, separate page, needed for the non-consumable pack. Not part of this complaint. |

Ruling on the 13+ Family line (my call, lead may veto): **retire the `.player` audience on both pages.** Its whole job was a Restore button; the Plus page already has one and the benefits list already says "Share it with your family". The grown-ups' note for under 13 / unknown age (`.grownUp`, Settings only, one day a week, no Restore) stays exactly as the owner decided on 2026-11-07.

Changes:
- `FamilyShareNudge.swift:25-31` `audience(...)`: the `thirteenPlus`/`eighteenPlus` branch returns `.none` (drop the `.player` case and `isShown(...)`, or keep the enum case and never return it; drop is cleaner). Remove `Copy.line`, `Copy.button`, `Copy.plusPageLine`; `Copy.all` = `[grownUpLine, grownUpButton]`.
- `FamilyShareNudgeRow.swift`: drop the `.player` branch and `restoreButton`; the `placement` parameter can stay (harmless) or go.
- `PlusView.swift:54`: delete the `FamilyShareNudgeRow(placement: .plusPage)` line.
- `SettingsView.swift:88`: keep `FamilyShareNudgeRow()` (it now shows the grown-ups' note or nothing).
- Tests: `FamilyShareNudgeTests` (audience table, `Copy.line + button` assertion at :89), `DailyQuestUITests.testGrownUpsSeeTheFamilyLineInSettingsAndOnPlus` (:132-146: becomes "grown-ups see no family line; Plus page has exactly one button named Restore purchases": `XCTAssertEqual(app.buttons.matching(identifier: "Restore purchases").count, 1)` while on Plus), `WordFloraUITests.swift:925, 938` (still pass). Re-grep `familyShare.restore` and `familyShare.nudge` before the commit.
- App Review (3.1.1 restore must be reachable): satisfied by button 1, reachable from Settings > Plus row (`settings.plus`), Home "Go ad-free" (`HomeView.swift:509`), the Plus offer card (`HomeView.swift:282`) and the resting card (`GameView.swift:429`). Restore stays ungated (never charges), as today.

Supersedes textfit-brief **T22** (nudge as text on the Plus page): do not do T22; do N1 instead. The `plusPageLine` added in d365fff is removed.

### N2. Cut the text on the Plus page

Every line on the page at d365fff, top to bottom, with the ruling:

| Line (d365fff) | Code | Ruling |
|---|---|---|
| Intro (under 13 / unknown age only): "WordFlora is complete without Plus. Plus removes ads for grown-up players and syncs the garden with iCloud. Family Sharing covers up to six people." | `PlusView.swift:26-31`, `Paywall.swift:215` `PlusEntry.introLine` | **Cut the third sentence.** New: `"WordFlora is complete without Plus. Plus removes ads for grown-up players and syncs the garden with iCloud."` The first sentence stays first in every layout (earlier ruling). Adults never see this line (unchanged). |
| Flower, title "WordFlora Plus" | :32-35 | Keep. |
| Benefits: "No ads, ever" / "Sync your garden with iCloud" / "Share it with your family" | :37-45, `Paywall.swift:100` | Keep (three short lines; they are the offer). |
| Yearly card: "Yearly", badge "Best value", "3 days free to start" (trial only), "About $1.08 a month · save 73%", "$12.99 a year" | :151-161 | Keep. (Trial line only when `trialEligible`, already guarded in d365fff.) |
| Monthly card: "Monthly", "$3.99 a month" | :151-161 | Keep. |
| Plus Forever card: "Plus Forever", **"Pay once, keep Plus on this Apple ID. No renewals."**, "$34.99 once" | :163-168, `Paywall.swift:145` `lifetimeLine` | **Drop the sentence from the card** (`lines: []`). "$34.99 once" says it; the fine print under the button still carries "One payment of $34.99. Pay once, keep Plus on this Apple ID. No renewals." when Plus Forever is selected. |
| CTA ("Start 3‑day free trial" / "Subscribe" / "Buy Plus Forever") | :118-123 | Keep. |
| Fine print: "3 days free, then $12.99 per year. Renews automatically unless cancelled at least 24 hours before the end of the period. Cancel anytime in your App Store account settings." | :124-126, `Paywall.swift:110-116` | **Keep as is** (legally required: price, period, trial length, auto-renew, how to cancel; wording just settled by ruling 3). |
| Message line (pending / Ask to Buy / failed / restore result) | :49-53 | Keep (only one shows, only after an action). |
| Family row (13+) | :54 | **Remove** (N1). |
| Footer: "Restore purchases", "Redeem a code", **"Manage subscription"**, "Terms of Use", "Privacy Policy" | :56-75 | **"Manage subscription" only when `store.state.hasActiveSubscription`.** A non-subscriber has nothing to manage. Others keep. |
| Active card: "You have WordFlora Plus" + "Ads are off and your garden can sync across your devices. Thank you for supporting WordFlora." | :213-237, `Paywall.swift:133-134` | **Replace the detail with the plan line** (N3). |
| Active card, lifetime: "You have Plus Forever" + "Ads are off and your garden can sync across your devices, with no renewals. Thank you for supporting WordFlora." | `Paywall.swift:158-159` | **Detail becomes "Paid once. No renewals."** |
| paysTwice / subscriptionEnds lines + "Cancel the subscription" | :223-234 | Keep (rare, important, honest). |

Final copy per state (adult, default text; under 13 adds the two-sentence intro at the top):

- **Not subscribed, prices loaded:** flower; "WordFlora Plus"; three benefits; three cards; CTA; fine print; footer "Restore purchases" / "Redeem a code" / "Terms of Use · Privacy Policy".
- **Loading:** as above but cards without prices and, in place of CTA and fine print, spinner + "Loading prices" (d365fff `:128-136`). No fine print, no footer change.
- **Failed to load:** benefits; card "We couldn't load the plans. Check your connection and try again."; "Try again" (spinner while retrying); footer. No cards, no fine print.
- **Purchase pending (slow entitlement):** page unchanged + message "Almost there. If Plus is not on in a moment, tap Restore purchases."
- **Ask to Buy:** message "Sent to a grown-up to approve. Plus turns on once it's approved."
- **Purchase failed:** message "We couldn't confirm that purchase. If you see a charge, tap Restore purchases."
- **Restore result:** "Plus is on." / "No purchases found for this Apple ID."
- **Subscribed:** flower; "WordFlora Plus"; benefits; card: sparkles **"You have WordFlora Plus"** + plan line (N3, e.g. "Yearly plan · renews Nov 7, 2027"); footer "Manage subscription" / "Restore purchases" / "Redeem a code" / "Terms of Use · Privacy Policy".
- **Plus Forever:** card **"You have Plus Forever"** + "Paid once. No renewals." (+ paysTwice line and "Cancel the subscription", or the ends-on line, when a subscription is also live); footer as subscribed, minus "Manage subscription" unless a subscription is live.

Tests: `PaywallRulesTests` (intro line, lifetime detail), `PaywallCopy.all` (add every new string, remove the dead ones).

### N3. "You have Plus" moment and a persistent Plus indicator

Facts: at d365fff a success sets `message = nil` and swaps `plans` for `activeCard` (`PlusView.swift:293`). That is correct but silent: no motion, no haptic, and the card's detail line is generic. In Settings the Plus row still reads **"Remove ads and sync with iCloud"** after the purchase (`SettingsView.swift:76`, `PlusEntry.rowTitle` `Paywall.swift:218-220`), which is the single biggest reason the owner "had no idea". And `updateSyncFlag()` is called only from the Plus page and on scene-active, so a purchase that lands through `Transaction.updates` (Ask to Buy approved later, family share, offer code) sets `cloudSyncEnabled` one launch late.

Spec:

1. **One-time moment (Plus page).** `PlusView.swift:293` `case .success:` becomes
   `message = PaywallCopy.justOn(adsWereOn: !ParentalGate.isRequired(ageBand: app.settings.ageBand), syncNeedsRestart: app.syncNeedsRestart)` after `app.updateSyncFlag()`, and the card swap is wrapped in `withAnimation(.spring(response: 0.4, dampingFraction: 0.8))` with `.transition(.scale(scale: 0.96).combined(with: .opacity))` on `activeCard` (Reduce Motion: `.opacity` only, the app's usual pattern). Haptic: `UINotificationFeedbackGenerator().notificationOccurred(.success)` when `app.settings.hapticsOn` (use the existing haptic helper if there is one). The existing `onChange(of: message)` already announces it to VoiceOver.
   Copy (`PaywallCopy`):
   ```swift
   static func justOn(adsWereOn: Bool, syncNeedsRestart: Bool) -> String {
       var s = "Plus is on."
       if adsWereOn { s += " Ads are off." }
       s += syncNeedsRestart ? " iCloud sync starts next time you open WordFlora." : " Your garden syncs with iCloud."
       return s
   }
   ```
   Add the four combinations to `PaywallCopy.all`. The "next time you open" part is honest: the store is opened once per launch (`AppModel.swift:858-865`).

2. **Plan line on the active card** (replaces `ownedSubscriptionDetail`). Add to `EntitlementState` (`Paywall.swift`, a struct in Rules, not a stored model):
   ```swift
   /// The live subscription plan (yearly wins if both somehow exist); nil for Plus Forever alone or no Plus.
   var activePlan: PlusPlan? { PlusPlan.allCases.first { activeProductIDs.contains($0.productID) } }
   ```
   and to `PaywallCopy`:
   ```swift
   static func planLine(plan: PlusPlan, renews: Bool, endsAt: Date?) -> String {
       let name = plan == .yearly ? "Yearly plan" : "Monthly plan"
       guard let endsAt else { return name }
       let day = endsAt.formatted(date: .abbreviated, time: .omitted)
       return renews ? "\(name) · renews \(day)" : "\(name) · ends \(day). Auto-renew is off."
   }
   static let ownedLifetimeDetail = "Paid once. No renewals."
   ```
   `PlusView.swift:221`: lifetime → `ownedLifetimeDetail`; else `planLine(plan: store.state.activePlan ?? .yearly, renews: store.state.subscriptionRenews, endsAt: store.state.subscriptionEndsAt)`. During a free trial `expirationDate` is the trial end, so "renews Nov 10, 2026" is right (the trial-vs-paid wording from the offer stays 1.1). Add `.accessibilityIdentifier("plus.planLine")`. Fixture `-uitest-plus` has no date → "Yearly plan"; `-uitest-plus-ending` → the ends line. Test the three branches in `PaywallRulesTests` with fixed dates (format is locale-dependent, compare prefix/contains).

3. **Persistent indicator in Settings.** `Paywall.swift:218-220`: `rowTitle(ageBand:hasPlus: Bool = false)`; when `hasPlus` return `"WordFlora Plus is on"` for every age band. `SettingsView.swift:76`: pass `hasPlus: app.entitlements.state.hasPlus`, and when on, add a trailing value: `Label(...)` + `Spacer()` + `Text(short).foregroundStyle(Color.secondaryText)` where `short` is "Yearly" / "Monthly" / "Forever" (`PaywallCopy.planShort(_:)`; lifetime wins). Row id stays `settings.plus`. Section title unchanged. The row still opens the Plus page, which now shows the plan line, so the player can always answer "am I on Plus, until when". Update `PaywallRulesTests:110-116` and check `WordFloraUITests.swift:294-306, 603, 733, 885` (they tap the title "Remove ads and sync with iCloud" without `-uitest-plus`, so they should still pass; :885 asserts it is absent, re-read its launch args).

4. **Sync flag follows the entitlement.** `WordFloraApp.swift:244-251` (or `RootView`): add `.onChange(of: app.entitlements.state.hasCloudSync) { _, _ in app.updateSyncFlag() }`. One line; covers Ask to Buy approvals, family shares, codes and refunds while the app is open. Unit test: `debugForce` a Plus state on a model, assert `cloudSyncEnabled` without calling `updateSyncFlag` yourself (if the model has no scene, test the `EntitlementService` → `AppModel` hook you add instead; keep it small).

No Home badge in 1.0 (owner's text budget; the Settings row and the Plus page are enough). 1.1 idea: a tiny "Plus" chip beside the Settings gear on Home.

### N4. iCloud sync status in WordFlora Settings

Where "iCloud sync is on" lives today: `SettingsView.swift:89-92`, a grey footnote `Label` at the bottom of the Plus section ("WordFlora Plus" / "For grown-ups"), **only when Plus is active**, and it reads "iCloud sync starts the next time you open WordFlora" until the app has been relaunched. Not in the iPhone Settings app at all. The owner did not see it because (a) it looks like a caption, not a status, (b) right after buying it says "starts the next time you open", (c) if the purchase had not gone live (`.pending`), the row does not exist, and (d) it sits under the Family row. Worse: if a Plus player has no iCloud account, `WordFloraApp.swift:22-24` silently falls back to the local store with `launchedWithCloud = false`, so `syncNeedsRestart` is true for ever and the footnote says "starts the next time you open WordFlora" at every launch. That is the one real bug here.

Spec:

1. **Honest inputs.** `WordFloraApp.swift:16-29`: record `let cloudOpenFailed = wantsCloud && !openedWithCloud` and pass it to `AppModel` (new `let cloudOpenFailed: Bool`, default `false`, like `launchedWithCloud`). `AppModel` gains `private(set) var cloudAccount: CKAccountStatus?` and
   ```swift
   func refreshCloudAccount() async {
       guard entitlements.state.hasCloudSync else { cloudAccount = nil; return }
       cloudAccount = try? await CKContainer(identifier: SharedContainer.cloudContainerID).accountStatus()
   }
   ```
   called from the scene `.active` branch (`WordFloraApp.swift:249`) as `Task { await app.refreshCloudAccount() }`. About 12 lines, `import CloudKit` in AppModel.

2. **Pure status rule**, `Rules/CloudSyncStatus.swift` (new, Foundation + CloudKit for the enum):
   ```swift
   enum CloudSyncStatus: Equatable { case needsPlus, startsNextLaunch, on, needsSignIn, unavailable }
   static func status(hasPlus: Bool, launchedWithCloud: Bool, cloudOpenFailed: Bool, account: CKAccountStatus?) -> CloudSyncStatus {
       guard hasPlus else { return .needsPlus }
       if launchedWithCloud { return .on }
       if account == .noAccount { return .needsSignIn }
       if cloudOpenFailed || account == .restricted { return .unavailable }
       return .startsNextLaunch
   }
   ```
   Copy (`CloudSyncStatus.Copy`, in `all`, CopySafety: no "waiting", no "last", no "only"):
   - needsPlus: `"iCloud sync is off (needs Plus)"`
   - startsNextLaunch: `"iCloud sync starts next time you open WordFlora"`
   - on: `"iCloud sync is on"`
   - needsSignIn: `"iCloud sync needs an iCloud sign-in"` + footnote `"Sign in to iCloud in the Settings app, then reopen WordFlora."`
   - unavailable: `"iCloud sync isn't available on this device"` + footnote `"Check that WordFlora may use iCloud in the Settings app (Apple Account > iCloud), then reopen WordFlora."`
   - on, footnote: `"Your garden shows up on any iPhone signed in to the same iCloud account."` (this is how a player tells it works: open WordFlora on the other phone).
   Unit test the table (5 rows + the `couldNotDetermine`/nil → startsNextLaunch row).

3. **Row.** Replace `SettingsView.swift:89-92` with a `LabeledContent`-style row in the same section, shown for **everyone** (free players see "off (needs Plus)", which answers the owner's question before they buy): `Label(status.title, systemImage: icon)` with `icloud.fill` (on), `icloud` (starts next launch / needs Plus), `icloud.slash` (needs sign-in / unavailable); `.accessibilityIdentifier("settings.cloudSync")`; footnote under it when the status has one; and the "Synced …" line (4) when available. Normal row type, not footnote grey, so it reads as status.

4. **"Synced <time>" line: the cheapest honest signal.** SwiftData's CloudKit sync runs on `NSPersistentCloudKitContainer` underneath and that class posts `NSPersistentCloudKitContainer.eventChangedNotification` on `NotificationCenter.default` with `userInfo[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]` as an `NSPersistentCloudKitContainer.Event` (`type` .setup/.import/.export, `startDate`, `endDate`, `succeeded`, `error`). This is widely reported to fire for SwiftData containers too, but Apple does not document it for SwiftData, so **verify once on a device with Plus on before relying on it**. Spec (about 30 lines, `Services/CloudSyncMonitor.swift`, `@Observable @MainActor`):
   ```swift
   final class CloudSyncMonitor {
       private(set) var syncedAt: Date? = SharedDefaults.store.object(forKey: "cloudSyncedAt") as? Date
       private(set) var lastFailed = false
       private var token: NSObjectProtocol?
       init(center: NotificationCenter = .default) {
           token = center.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main) { [weak self] n in
               guard let e = n.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
                     let end = e.endDate, e.type != .setup else { return }
               Task { @MainActor in self?.record(end: end, ok: e.succeeded) }
           }
       }
       private func record(end: Date, ok: Bool) {
           lastFailed = !ok
           guard ok else { return }
           syncedAt = end; SharedDefaults.store.set(end, forKey: "cloudSyncedAt")
       }
   }
   ```
   Owned by `AppModel` (`let cloudSync = CloudSyncMonitor()`), created only when `launchedWithCloud`. Row line: `"Synced \(date.formatted(.relative(presentation: .named)))"` → "Synced 5 minutes ago" / "Synced yesterday" (not "Last synced": "last" is banned). Shown only when `syncedAt != nil` and status is `.on`. If `lastFailed`, append nothing scary; the status row stays "on" (a failed export retries by itself). Unit test: post a fake notification with a stubbed `Event`? `Event` cannot be constructed, so test `record(end:ok:)` directly and the UserDefaults round trip. **If the device check shows no event in a full session, keep the monitor but the line simply never appears; do not invent a time.** A `UserDefaults` key is not a SwiftData field, so the no-new-stored-field rule holds.

Supersedes nothing in the textfit brief (Settings was not in its scope except the retired Theme picker).

### N5. Small follow-up, lowest priority: AVAudioSession on the main thread

Log: `AVAudioSession_iOS.mm:978 This method can lead to UI unresponsiveness if called on the main thread. Consider using the asynchronous activate/deactivate API`. Call sites: `Sound.swift:115-118` `SoundPlayer.configureSession()` (`setCategory` + `setActive(true)`), called synchronously from `AppModel.init` (`AppModel.swift:66`, main thread, before the first frame, every launch) and from `ReadAloud.finish()` (`ReadAloud.swift:97`); and `ReadAloud.speak` (`ReadAloud.swift:67-68`). Real, but a launch hitch warning, not a bug. Minimal fix: in `configureSession`, wrap both calls in `DispatchQueue.global(qos: .userInitiated).async { … }` (AVAudioSession is thread-safe; `AVAudioPlayer.play()` activates the session itself anyway). In `speak`, the category must be set before `synth.speak`, so do `Task.detached { try? setCategory(.playback …); try? setActive(true); await MainActor.run { self.startUtterances(lines) } }` (move the loop at :70-80 into a small method). The iOS API has no async `activate`; the warning text refers to watchOS. If time is short, do `configureSession` only and leave `speak` (player-initiated, rare).

### N6. App Group CFPrefs warning: diagnose, probably no code change

Log: `Using kCFPreferencesAnyUser with a container is only allowed for System Containers, detaching from cfprefsd` for domain `group.beta.WordFlora`. Our use: `SharedDefaults.store = UserDefaults(suiteName: "group.beta.WordFlora")` (`Shared/SharedDefaults.swift:5-6`), read and written by `AppSettings` (every setting, including `onboardingComplete`, `ageBand`, `cloudSyncEnabled`: `AppSettings.swift:72`), by `SharedContainer.resolveForApp` (`storeHome`, `SharedContainer.swift:51-69`) and by the widget (`WordFloraWidget/GardenWidget.swift:20, 41, 88`). Entitlements carry the group for both the app (`WordFlora.entitlements`, and the simulator variant) and the widget (`WordFloraWidget.entitlements`).

Meaning: this exact line is printed on **every simulator run** for any App Group suite and is harmless there. On a **device** it means the running binary is not entitled to that group (profile or capability mismatch): the suite then detaches, values do not persist across launches, and `containerURL(forSecurityApplicationGroupIdentifier:)` returns nil. If that were the case on the owner's phone, WordFlora would forget the age band and re-run onboarding at every launch and the widget would never show a plant (only "Your garden says hello"), and `cloudSyncEnabled` could never survive to the next launch, so iCloud sync could never start. The owner did not report re-onboarding, so the group most likely works and the line is noise, but it costs two minutes to be sure.

Spec (Debug only, no shipped change): in `WordFloraApp.init`, under `#if DEBUG`, `print("appGroup:", FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedDefaults.groupID) as Any, "homeKey:", SharedDefaults.store.string(forKey: SharedContainer.homeKey) as Any)`. Ask the owner to run twice on the device: a non-nil URL and `homeKey: group` on the second run means the group is fine, done. A nil URL means the App Groups capability is missing from the device profile: owner fixes it in Xcode > WordFlora target (and WordFloraWidget) > Signing & Capabilities > App Groups, tick `group.beta.WordFlora`, same team on both; no code change. Note for the record: the `?? .standard` fallback in `SharedDefaults.store` never fires (`UserDefaults(suiteName:)` does not return nil for an unentitled group), so it is not a safety net. Also: the main checkout has an **uncommitted edit to `WordFlora.xcscheme`** (adds an empty `Development` environment variable and re-indents the StoreKit configuration reference). That is Xcode's doing when the owner ran on the device; it also means the owner's Debug purchases went through the local StoreKit file (`Config/WordFlora.storekit`), not the sandbox. Do not commit it by accident; builders should `git checkout -- WordFlora.xcodeproj/xcshareddata/xcschemes/WordFlora.xcscheme` only if the lead says so.

---

## G4a (AdPolicy), not now

### Why test ads showed while buying Plus

Facts (main, unchanged at d365fff):
- The Plus page has no ad view. The banner lives in Home's `safeAreaInset` (`HomeView.swift:171`, `:501-515`) and Garden's (`GardenView.swift:39`); a pushed page (`RootView.swift:51`) covers them. Nothing on the Plus page requests or shows an ad. Debug builds use Google's test ids (`Config/Ads.xcconfig`), so any ad seen was a test ad by design.
- So what the owner saw was the **Home banner before and after** the Plus page (and the "Go ad-free" line under it), or the banner on Garden. After a purchase `showBanner` (`AppModel.swift:464-467`) reads `entitlements.state.hasRemoveAds` and the banner view leaves the hierarchy at once. If the banner stayed, Plus had **not** gone live (a `.pending` outcome), which is the same cause as "no idea if I was on Plus". N3 makes that state unmistakable.
- A full-screen ad over the purchase or consent sheet is possible in principle: `showInterstitial`/`showRewarded` present from `rootViewController().topmost` (`AdsService.swift:87, 110, 126-128, 142-144`), and `topmost` follows `presentedViewController`, so an ad resolving while a StoreKit or UMP sheet is up would sit **on top of the sheet**. Today every trigger is a player tap on Home or the resting card and the awaits run in sequence, so it is unlikely, but nothing forbids it.

Spec for G4a (add to `docs/pm/g4a-builder-brief.md` section 6 and the B-tests; AdPolicy already has `.notApplicable`, `consentPending`, etc.):
1. `AdBlock.paywall`: `AdPolicy.decide` returns `.no(.paywall)` for every format while the current route is `.plus` or `.seasons` (`AdInputs.onPaywall`, fed from `GameRouter.path.last`). No banner, no full-screen, no native, no app-open there.
2. `AdBlock.sheetUp`: no full-screen format (interstitial, rewarded, app-open) when the key window's root has a `presentedViewController` that is not our own ad (`AdsService.canPresentFullScreen`), i.e. a StoreKit purchase sheet, the UMP form, the ATT prompt, the offer-code sheet, `manageSubscriptionsSheet` or a parental-gate sheet is up. Checked again right before `present`, after every await.
3. H5 (already in the brief): when `hasRemoveAds` turns true, `AdsService.releaseCached()` drops the loaded interstitial and rewarded and stops preloading; `showBanner` already turns false. Hook it from the same `onChange(of: hasCloudSync/hasPlus)` added in N3.4 (or inside `AppModel.updateSyncFlag`, renamed `entitlementChanged()`).
4. Tests: `-uitest-plus` launch shows no banner on Home or Garden (likely exists; confirm), `decide(.interstitial, onPaywall: true)` → `.no(.paywall)`, `decide` with `sheetUp` → `.no(.sheetUp)` for the three full-screen formats and `.yes` for banner on Home.

Nothing in this section is needed for the owner's complaint to be fixed in the device build; N3 is. Release builds never show test ids (G4a asserts that).

---

## Summary for the builder (one pass)

Files: `PlusView.swift` (N1 delete :54; N2 lifetime card lines, footer Manage condition; N3 success moment, plan line), `Paywall.swift` (N2 intro, lifetime detail; N3 `activePlan`, `justOn`, `planLine`, `planShort`, `rowTitle(hasPlus:)`, `all`), `FamilyShareNudge.swift` + `FamilyShareNudgeRow.swift` (N1 retire `.player`), `SettingsView.swift` (N1 nothing to change at :88; N3 row title + value at :76; N4 status row replaces :89-92), `WordFloraApp.swift` (N3 onChange; N4 `cloudOpenFailed`, `refreshCloudAccount`), `AppModel.swift` (N4 fields, monitor), new `Rules/CloudSyncStatus.swift`, new `Services/CloudSyncMonitor.swift`, `Sound.swift` + `ReadAloud.swift` (N5, optional), N6 Debug print. Tests named in each item; every new string in a `*Copy.all`. Screenshots to add to the textfit list: Plus page subscribed with the plan line; Settings with "WordFlora Plus is on · Yearly" and each of the five iCloud rows (`-uitest-plus` gives "starts next time you open WordFlora"; the others need a small fixture flag `-uitest-cloud=<on|signin|unavailable>` that sets the two inputs).

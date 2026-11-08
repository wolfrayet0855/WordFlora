# Builder diff review: A (text-fit + Plus flow) and B (polish pass 2)

Date: 2026-11-07. Read-only review: no build, no simulator, no edits to either worktree.

- **A**: `.claude/worktrees/agent-a2bea51afc81e7059`, HEAD `be453dd` (16 commits, 50 files). Text-fit pass, Plus flow N1-N6, Settings "Purchases" section, one Restore in Settings.
- **B**: `.claude/worktrees/agent-a0f8716ff1989be39`, HEAD `a710356` (7 commits, 32 files). Snowfall, snowdrop pose, win card `WordsToPlantPips`, `toastTick`, loveLines "Some energy".
- Base: `3-feat-content-and-polish` at `d200d09`. Both branches start from older bases (A from `5a73610`, B from `b21f103`). The commits since then are docs only, and each branch merges into the tip without conflicts (`git merge-tree`).

## Verdict

- **Safe to merge A: yes.** No blockers. Fix A1 (the word "last" can appear in a string the player sees) before release. It is a one-line change and can come in a follow-up commit. A2 and A3 are small fixes to the iCloud status row.
- **Safe to merge B: yes, after A, using the rebase plan below.** No blockers. One real conflict in `GameView.swift`, which takes a minute to resolve, plus `docs/STATUS.md`.

## Findings, by severity

### Medium

**A1. The iCloud "Synced …" line can say "last week" / "last month" / "last year" (CopySafety bans "last").**
`WordFlora/Services/CloudSync.swift:57-59`. `date.formatted(.relative(presentation: .named))` produces the named forms "yesterday", "last week", "last month" and "last year". The time is kept in the App Group across launches (`CloudSyncMonitor.key`), so a player whose phone was off for a week will see "Synced last week". `Copy.all` only checks the -300 s case ("5 minutes ago"), so the test cannot catch this.
Fix: `"Synced \(date.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))"` ("1 week ago"). Also add `synced(now - 8 days)`, `synced(now - 40 days)` and `synced(now - 400 days)` to `Copy.all`.

**A2. A Plus player signed out of iCloud can see "iCloud sync is on".**
`WordFlora/Services/CloudSync.swift:12-18`. `status()` returns `.on` when `launchedWithCloud` is true, before it looks at `account == .noAccount`. A CloudKit-backed SwiftData store can open with no iCloud account, or the account can be signed out after launch. In both cases the row says "on" while nothing syncs, which is the exact confusion N4 was meant to fix.
Fix: check the account first:
```swift
guard hasPlus else { return .needsPlus }
if account == .noAccount { return .needsSignIn }
if account == .restricted { return .unavailable }
if launchedWithCloud { return .on }
if cloudOpenFailed { return .unavailable }
return .startsNextLaunch
```
Add one `PaywallRulesTests` row: `launchedWithCloud: true, account: .noAccount` gives `.needsSignIn`.

### Low

**A3. A paying player sees "iCloud sync is off (needs Plus)" for a moment at launch.** `WordFlora/App/AppModel.swift:31-35`. `cloudSyncStatus` reads `entitlements.state.hasCloudSync` before StoreKit has answered. `updateSyncFlag` already guards on `hasLoaded` for this reason; the status row does not.
Fix: pass `hasPlus: entitlements.state.hasCloudSync || (!entitlements.hasLoaded && launchedWithCloud)`.

**A4. When Restore fails, the message reads like "nothing was bought".** `WordFlora/Services/EntitlementService.swift:143-146` uses `try? await AppStore.sync()`, and `SettingsView.swift:168-180` then shows "No purchases found for this Apple ID." The same message appears when the player cancels the Apple ID sheet or is offline.
Fix: make `restore()` return `Bool`, false when `AppStore.sync()` throws. A cancel (`StoreKitError.userCancelled`) shows no message. Any other error shows a new `PaywallCopy.restoreFailed = "We couldn't reach the App Store. Try again."`, which must also be added to `PaywallCopy.all`.

**A5. `CloudSyncMonitor` removes its observer from the wrong NotificationCenter when one is injected.** `CloudSync.swift:92`: `deinit` always uses `NotificationCenter.default`, but `init(center:)` adds the observer to `center`. This is harmless today, because production uses `.default` and tests pass `listen: false`.
Fix: keep `@ObservationIgnored nonisolated(unsafe) private let center: NotificationCenter` and remove the observer from it. The rest checks out:
- events come on `queue: .main`, and the `[weak self]` capture means no retain cycle;
- values are pulled from the event before the `@MainActor` hop;
- `.setup` events and events without an `endDate` are skipped;
- the monitor is only built when `launchedWithCloud`, and `CKContainer(identifier:)` is only reached with Plus;
- both entitlements files list `iCloud.beta.WordFlora`, so a launch without CloudKit cannot crash.

**A6. Stale "For grown-ups" references now that the section is "Purchases" for every age.**
- `PlusEntry.sectionTitle` and `grownUps` (`Paywall.swift:242, 252`) are dead code; only `PaywallRulesTests.swift:223-229` still uses them.
- Doc comments still say the grown-ups' note lives in the "For grown-ups" section: `FamilyShareNudge.swift:5, 17`, `FamilyShareNudgeRow.swift:4`, and the comment at `WordFloraUITests.swift:~913`.

Fix: delete `sectionTitle` and its test, or keep it with a comment that it is unused; update the comments.

**A7. The Settings Plus row has a side-by-side layout at accessibility sizes.** `SettingsView.swift:82-86`: `Label` + `Spacer` + `Text(short)` sit in an `HStack`. At AX5, "WordFlora Plus is on" and "Forever" share one row. This is not a cap, but it breaks the text-fit rule used everywhere else (stack at accessibility sizes).
Fix: `typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout())`.

**A8. UI test gap: under-13 "Manage subscription" in Settings.** The row is a `GatedLink`, and `ParentalGate.outbound` asks first for under 13 and unknown ages, so the code is correct. But no test checks the Settings copy of the row.
Fix: add `launch(age: "under13", ["-uitest-plus"])`, then `expectGateThenCancel(after: app.buttons["settings.manageSubscription"])`.

**B1. On the Shed shelf, the pack card's snow keeps running after it scrolls off screen.** `WordFlora/Views/SeasonsView.swift:126-127` pauses on `onAppear` / `onDisappear`. Inside the Shed's plain (non-lazy) `ScrollView` (`ShedView.swift:20`), `onDisappear` only fires when the view leaves the screen tree, not when it scrolls out of view. The cost is small: one Canvas, 22 flakes, 30 fps.
Fix (optional): `if #available(iOS 18, *) { .onScrollVisibilityChange { visible = $0 } }`. The deployment target is 17.5, so keep `onAppear` / `onDisappear` as the fallback.

**B2. `@State private var lowPower = LowPowerWatch()` in `PackCardArt` (`SeasonsView.swift:113`).** SwiftUI evaluates the initial value each time the parent rebuilds the view, so each rebuild adds and then removes an observer. This copies an existing pattern (`PlantDetailView:44`, `WeatherViews:55`), so it is not new risk. No action for this release.

### Info: checked and fine

- **CopySafety:** I matched every new string literal in both diffs against the banned list with the same `\b` regex: zero hits. "at least 24 hours" is not "last" under the `\b` match. "Some energy", "Next word", "Tend my garden" and "One more word and a new plant arrives!" are clean and covered by tests. The only runtime risk is A1.
- **Restore purchases:**
  - There is exactly one, in Settings > Purchases (`settings.restore`). It shows at every age and in every state, with no `if` around the section, and it is never gated.
  - It was removed from the Plus page, the Seasons page and `FamilyShareNudgeRow`.
  - Its old ids (`plus.restore`, `seasons.restore`, `familyShare.restore`, `familyShare.nudge`) remain in tests only as absence checks.
  - The pending and failed messages now say "Restore purchases in Settings".
- **Gating for under 13 and unknown ages:**
  - Plus page: purchase, redeem, Terms, Privacy, Manage and the paysTwice cancel all go through `ask(then:)` or `GatedLink`.
  - Settings: the Seasons row goes through `openSeasons()`, and Manage subscription is a `GatedLink`.
  - Seasons page: buying goes through the gate sheet.
  - The Plus row only navigates, as before.
  - `justOn(adsWereOn:)` says nothing about ads for gated ages.
  - Moving the header from "For grown-ups" to "Purchases" is marked as an owner decision (2026-11-07) in the code.
- **Ads note:** H5 (release cached ads when Plus arrives) is still open in the G4a brief. It is not in A's scope, but it is the root of the owner's "test ads while buying" report.
- **N6 Debug print:** under `#if DEBUG` at `WordFloraApp.swift:50-55`, self-contained, comment says remove once the owner has run it. Track removal before release. Related: `debugSlowStore` / `debugFailStore` (`EntitlementService.swift:47, 50`) can only be reached with `-uitest` launch arguments, but they are not compiled out of Release. Fold them into G4a H6.
- **Models:** neither branch touches `WordFlora/Models`. The sync time is a UserDefaults value in the App Group.
- **Dynamic Type:** A removed every `ViewThatFits`, `.dynamicTypeSize(...)` cap, `lineLimit` and `minimumScaleFactor` in the files it touched. What remains in those files is `GuideView.swift:829, 882`: fixed 11 pt labels inside the guide's art. They are pre-existing and drawn as art, so not a finding. B adds no caps; the pips are fixed 16 pt and hidden from VoiceOver.
- **Accessibility ids:** every id the new UI tests look for exists in the app, or is built dynamically (`book.page.*`, `shed.tool.*`), or is checked only for absence.
- **SnowfallView:**
  - Built as a `TimelineView(.animation(minimumInterval: 1/30, paused:))` around a stateless `Canvas`, with one batched path per layer.
  - Reduce Motion (system or app switch) and Low Power draw one still frame with no timeline.
  - It pauses off screen (plant page `stageVisible`, card `onDisappear`) and when the scene is not active.
  - It is off in Quiet Garden and never draws over weather or rain.
  - It is hidden from VoiceOver with `allowsHitTesting(false)`, and the card keeps its one image label.
- **`toastTick`:** `dyn(0x9BCB3C, 0x2E7D32)`, with a test that resolves both colours. This is the tick icon (non-text, 3:1 needed); the claimed contrast is 6.0:1 and 4.1:1.
- **pbxproj:**
  - A: `CloudSync.swift` is in the app target and Services group, `TextFitLayoutTests` in the unit tests, `TextFitScreensUITests` in the UI tests.
  - B: `Snowfall.swift` and `SnowfallView.swift` are in the app target (Rules and Components groups), `SnowfallTests` in the unit tests.
  - In the A+B trial merge, `plutil -lint` passes, no object id is defined twice, and there are no conflict markers.
- **Win card "Tend my garden" skips `afterRound()`**, and with it the resting card on a session beat. The spec allows this on purpose (celebration-and-love-review.md item 3), and the tutorial is excluded.

## Merge plan: A first, then B rebased onto it

1. Merge A into `3-feat-content-and-polish`. There are no conflicts against the tip (the commits since A's base are docs only).
2. In B's worktree, run `git rebase 3-feat-content-and-polish`. In the A+B trial merge (`git merge-tree be453dd a710356`), exactly two files conflict:
   - **`WordFlora/Views/GameView.swift`, in `earnedCard`'s no-plant branch.** A changed the title to `cardTitle(PlantProgressCopy.winTitle)`. B replaced the `// HOOK (progress meter)` comment with the pips. Resolve to:
     ```swift
     cardTitle(PlantProgressCopy.winTitle)
     WordsToPlantPips(filled: vm.wordsTowardPlant, total: vm.wordsPerPlant, popped: pipPopped,
                      reduceMotion: reduceMotion, calm: app.settings.calmMode || app.settings.quietGarden)
         .padding(.vertical, 2)
         .overlay { /* B's PetalPuff block unchanged */ }
     ```
     Keep A's title, keep B's pips and overlay, and drop the HOOK comment. Everything else in GameView merges on its own: B's `nextLine`, "Next word" / "Tend my garden", `closeWinCard()`, and A's `cardMargin`, `PlantCard(standalone:)` and fixed-size lines.
   - **`docs/STATUS.md`:** keep both sections (A's text-fit / Plus flow, B's polish pass 2).
3. These files merge cleanly, so no hand edits: `project.pbxproj`, `WordFloraApp.swift` (separate `-uitest-cloud=` / `-uitest-pot=` blocks), `PlantDetailView.swift` (A: resources layout around line 520; B: stage snow around 190-260 and the toast tick around 640), `SeasonsView.swift` (A: Restore removed and the announcement `onChange`; B: `PackCardArt` snow), `SeasonsUITests.swift`, `WordFloraUITests.swift`.
4. After the rebase, run the full unit tests, then these UI tests:
   - `SeasonsUITests`: B's new snow tests reach `settings.seasons`, which now sits under "Purchases";
   - `WordFloraUITests` (win card, ParentalGateLink);
   - `RestCardUITests`;
   - `CelebrationUITests` and `SpeedBloomUITests`: their first word earns a plant, so the button should still be "Continue"; confirm;
   - `TextFitScreensUITests` at AX5: the no-plant win card is now taller, with pips, an extra line and two buttons.
5. Before merging, check that `git log --format=%B 3-feat-content-and-polish..<branch> | grep -icE "claude|anthropic|co-authored|opus|sonnet|session"` prints 0. Do not commit the main checkout's uncommitted `WordFlora.xcscheme` edit.

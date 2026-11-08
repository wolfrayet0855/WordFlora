# Text-fit and polish pass: builder brief

Paste-ready. Written 2026-11-07. Runs right after the G3 merge, before engagement tasks A/B/C and G4a. Budget about 8 to 10 hours. Sources, all in `docs/pm/`: `all-pages-visual-review.md` (Fable; "bugs to fix now" list, section 3 Plus rulings, section 4 rule rulings), `visitors-book-review.md` (V1 to V11), `plus-page-review.md` (14 findings, rulings applied), `toolbar-fit-review.md` (the tend bar itself is DONE in G3; the other screens in its section 7 are in scope). Where two sources describe the same bug they are merged below. Line numbers are the main checkout at 4527b82 / G3 worktree for PlusView; re-grep before editing, they will have moved after the G3 merge.

Owner rule, applied to every item: **every word fits at every text size.** No Dynamic Type caps (`.dynamicTypeSize(` clamps), no `ViewThatFits`, no `lineLimit` that truncates, no `minimumScaleFactor` on words, text styles only (`Theme.font(<style>)`, no fixed sizes). The layout is chosen from the size category (`@Environment(\.dynamicTypeSize)`, `isAccessibilitySize`, or a threshold such as `>= .xLarge`), so it is deterministic and testable. Pattern to copy for axis switches: `AnyLayout(isAccessibilitySize ? VStackLayout(alignment: .leading) : HStackLayout())` as in `ShedView.swift:19` and `HomeView.swift:350`.

Do not touch the Appearance picker: it was removed in G3, so the old "Settings Theme picker" finding no longer exists. If you still see a `.segmented` Theme picker in `SettingsView.swift`, stop and ask the lead.

Out of scope (1.1 backlog, do not build): subscriber-to-Plus-Forever path; trial length read from `introductoryOffer.period` (the hard-coded "3 days" stays); first-met date field; light-mode weather palette; one back-button style; Settings restyle; Home hero rework; Guide AX layout rewrite. No new stored fields, no `Models/` diff.

---

## 0. Machine rules (paste at the top of your own working notes)

```
RULES
- Worktree: your own, branched from 3-feat-content-and-polish after the G3 merge. Never push. Never touch another worktree.
- One xcodebuild at a time on this machine. Take the lock dir /private/tmp/claude-501/wf-build.lock
  (mkdir; if it exists, wait and poll every 30 s; rmdir it when your xcodebuild exits, even on failure: use a trap).
- Always pass: -jobs 4 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1
  -test-timeouts-enabled YES -default-test-execution-time-allowance 120
- Your own simulators (xcrun simctl create "WF TextFit iPhone SE" and "WF TextFit iPhone 16" ...; write the UDIDs to your scratchpad;
  shut them down when done) and your own dd-* derivedData folder (dd-textfit). Never share either.
- build-for-testing once per code change, then test-without-building per class.
- Watchdog: timeout and perl alarm do not stop xcodebuild. Use:
    ( sleep 2700; pkill -f "xcodebuild.*$UDID" ) & WD=$!
    trap 'pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null; rmdir /private/tmp/claude-501/wf-build.lock 2>/dev/null' EXIT
  The trap must do `pkill -P $WD; kill $WD` (the sleep is a child of the subshell; killing only $WD leaves the sleep and a later pkill can hit a newer xcodebuild).
- Simulator erase/boot only between batches of tests, never mid-batch; after an erase or boot wait 2 to 3 minutes before the first test.
- mediaanalysisd stays DISABLED on this Mac and on simulators. Do not re-enable it. If you think it must be enabled, ask the lead; do not decide yourself.
- Every new Swift file goes into its target in project.pbxproj; plutil -lint the pbxproj. TARGETED_DEVICE_FAMILY stays "= 1" everywhere (grep before every commit).
- Copy: every new or changed kid-visible or purchase line goes into a *Copy.all list checked by CopySafety. Quiet Garden: no counts, no marks, no moments. Calm: CelebrationStyle.small. Reduce Motion: still or cross-fade.
- Commits: small steps, each must build. Plain messages in the user's voice. No attribution lines, no co-author line, no session line, and no tool, model or vendor names. Before you hand off run
    git log --format=%B <base>..HEAD | grep -icE "claude|anthropic|co-authored|opus|sonnet|session|fable"
  and confirm it prints 0.
- STATUS.md: add a dated section (what, tests, open items) in your last commit.
- Team communication: you are part of a team. If anything is unclear, or a ruling here looks wrong, ask the lead (SendMessage) or Fable before deciding. Report blockers when you hit them, not at the end. Stay inside the WordFlora repo; never write outside it.
- Report: everything goes in your FINAL MESSAGE (tests run with counts, reds and why, shots checked by eye, files, commit hashes, open items). Do not claim green without the log.
```

---

## 1. Order of work

1. Shared helper (section 2) and the layout unit test scaffold (section 8).
2. High items T1 to T8 (grids, pots, Repot, gate sheet, Plus trial guard, Butterfly title).
3. Medium items T9 to T21.
4. Low items T22 to T30, then the "ride along if time" items.
5. Acceptance run and screenshots (sections 8 and 9), report.

Commit after each numbered item or tight group. Run the unit test for the touched grid before each commit.

---

## 2. Shared helper: `GridColumns`

One helper, used by Garden, Badges, Shed pots, Repot tiles, soil chips and Visitors' book. Pure and testable: `func columns(for size: DynamicTypeSize, spec: ...) -> Int`. Suggested table (tune against the measured widths; the unit test decides):

| Grid | up to L | xL to xxxL | AX1 to AX3 | AX4 and AX5 |
|---|---|---|---|---|
| Garden plant cards | 2 | 2 | 1 | 1 |
| Badges | 2 | 2 | 1 | 1 |
| Shed pots (`PotCatalog.gridColumns`) | 4 | 2 | 1 | 1 |
| Repot pot tiles | 4 | 2 | 1 | 1 |
| Repot soil chips | 4 | 2 | 2 -> 1 | 1 |
| Visitors' book stickers | 4 | 3 (from xLarge) | 2 | 1 (from AX4) |

Where Garden and Badges currently stay 2 columns at xL to xxxL, keep them 2 only if the unit test proves the longest name fits at 375 pt; otherwise go 1 column from xxxL.

---

## 3. High

**T1. Garden grid breaks words at AX.** `Views/GardenView.swift:22-31`: `Grid` with two `tile()` per `GridRow` at every size; "peren-nis" hyphenates at AX5 and the sparkle draws over the silhouette (`fid-garden-ax5.png`). Measured: "Passionflower" breaks at AX1 and up, "Snapdragon" at AX1 on 375 and AX2 on both; botanical names (caption italic) too. Fix: use the `GridColumns` helper; one tile per row at AX. Check the sparkle position at one column.

**T2. Badges grid, same bug.** `Views/BadgesView.swift:21-28`; "Plant Col-lector", "collec-tion" at AX5. Fix: one `card()` per `GridRow` at AX via the helper.

**T3. Shed pot cards: cap and shrink.** `Views/PotPickerViews.swift:673` (`.dynamicTypeSize(...DynamicTypeSize.xxxLarge)`), `:656` (`lineLimit` + `minimumScaleFactor(0.5)`), `:595` (`PotCatalog.gridColumns`, constant 4). The AX and XXXL screenshots are pixel-identical today. Two-word names break mid-word without shrinking ("Snowflake indigo" from xL, "Rainbow bark" at xxxL). Fix: remove the cap, the `lineLimit` and the `minimumScaleFactor`; columns from the helper (4 to L, 2 above L, 1 at AX). This also covers the Seasons pack pots shown in the Shed (Snowflake indigo, Lantern red, Frosted glass).

**T4. Repot sheet tiles, goal line, soil chips.** `PotPickerViews.swift:332` (name, `minimumScaleFactor(0.6)`), `:341` and `:350` (goal line `0.75` and the `...xxxLarge` cap), `:439` (soil chip `0.8`; "Compost" truncates from xL). Fix: same helper (soil chips 2 columns above L); remove every limit and cap.

**T5. Parental gate sheet cannot scroll (also Plus finding 2).** `Views/PlusView.swift` `ParentalGateSheet` (about `:229-247`): fixed `VStack` in `.presentationDetents([.medium])`. At AX, Continue and Cancel leave the sheet, worse with the number pad up. Used for every purchase, redeem, manage, Terms/Privacy and Seasons tap by under-13 and unknown-age players. Fix: wrap content in `ScrollView`, `.fixedSize(horizontal: false, vertical: true)` on the three Texts, detents `isAccessibilitySize ? [.large] : [.medium, .large]`. Ship this item early; it is the highest-risk screen.

**T6. Trial wording without an offer (Plus finding 1, rejection risk).** `EntitlementService.swift:43-45`: `trialEligible` must require a free-trial introductory offer on `plus_yearly`:
```swift
if let yearly = map[.yearly], let sub = yearly.subscription,
   let intro = sub.introductoryOffer, intro.paymentMode == .freeTrial {
    trialEligible = await sub.isEligibleForIntroOffer
} else { trialEligible = false }
```
Test: no offer / non-trial offer gives `trialEligible == false` and the page shows no "3 days free" copy. Keep "3 days" hard-coded (1.1: read from the offer).

**T7. `PrimaryButtonStyle` ignores `isEnabled` (once, `Theme/Theme.swift:76`).** Read `@Environment(\.isEnabled)` and dim the fill only (fill opacity 0.5), never the label (ink on accent is 5.38 / 6.62 at full strength and fails at 0.5). Benefits Plus Subscribe, gate Continue and the resting offer "Wake it up". Do it here once; do not patch the three call sites.

**T8. Butterfly game title has no contrast on the evening sky.** `Views/ButterflyView.swift:54-59`: bar colour follows `colorScheme`, so in light mode a near-black title sits on navy (about 2:1). Fix: when the scene is evening use the navy bar and `.toolbarColorScheme(.dark, for: .navigationBar)`; otherwise unchanged.

**T9. Visitors V1: play card breaks mid-word at AX.** `ButterflyView.swift:546-571` (playCard), `:579-593` (easierSwitch), `:566` (friend of the day). "Hummingbird", "Swallowtail", "Bumblebee" at AX4 to AX5; "butterflies" in the Toggle label from AX3 (about 195 pt beside a 51 pt switch). Fix: at AX use `VStackLayout(alignment: .leading)` for image + text (column about 321 pt); in `easierSwitch` at AX show the label `Text` on its own line with the `Toggle` below it, `.labelsHidden()` plus `.accessibilityLabel(VisitorsCopy.easierToggle)`.

**T10. Visitors V2: Field Notes name breaks.** `FieldNotesPage.swift:131-132`, padding `:151`. "Hummingbird" `.title3` rounded bold is about 335 pt at AX5 in a 309 pt column. Fix at AX: paper padding leading 26 / trailing 14 (spine 18, holes 9; 26 clears them) and name `.subheadline` bold (about 299 pt). Escalate to Fable only if the smaller name reads wrong.

**T11. Visitors V3: detail sheet title.** `ButterflyView.swift:701`, `:725`. `.title` bold "Hummingbird" about 354 pt at AX5 against 345 (327 on 375). Fix at AX: `.title3` bold and horizontal padding 16 instead of 24.

**T12. Visitors V4 (corrected): Visitors' book sticker names.** `VisitorsBookView.swift:41` (`cols`), name at `:48`. Measured: "Snowflake" breaks from xxLarge on 393 and xLarge on 375; "Ladybird" and "Rainbow" at xxxLarge on 375 and at AX5 in two columns. **Correct fix is 3 columns from xLarge:**
`let cols = typeSize >= .accessibility4 ? 1 : (typeSize.isAccessibilitySize ? 2 : (typeSize >= .xLarge ? 3 : 4))`
(three columns give about 106 to 112 pt per name, enough for "Snowflake" at xxxLarge, 91 pt). Use the `GridColumns` helper.

## 4. Medium

**T13. `ViewThatFits` in four places (rule says none).** `PotPickerViews.swift:411` (Soil header), `:597` (Pots header), `Views/PlantDetailView.swift:506` (resource chips), `Components/NameStoryCard.swift:137` (origin chips). Replace with `AnyLayout(isAccessibilitySize ? VStackLayout(alignment: .leading) : HStackLayout())`. Verify no regression in the ordinary-size look.

**T14. Remaining caps outside the tend bar (that is G3's).** `Views/ShedTools.swift:199` (`lineLimit(typeSize.isAccessibilitySize ? nil : 2)` on the tool effect line; remove it, it can truncate at xxxL); `Views/GameView.swift:156` (`lineLimit(2)` on the top-bar title; remove); `PotPickerViews.swift:26, 40, 242, 259, 271` (Plus / New / In-use tags pinned at `.large`; at AX5 tiny under huge names). Ruling: the Plus tag carries a word, so it must scale or hide; **hide the tag at AX** (the "A Plus pot" line already says it); New and In-use scale with text styles.

**T15. Grand garden crown label.** `Views/GrandGardenViews.swift:194-198`: `Capsule` around text that wraps to four lines at AX5. Fix: `RoundedRectangle(cornerRadius: 22, style: .continuous)` for background and stroke, `.multilineTextAlignment(.center)`; keep the sparkle and "earned" off the stroke.

**T16. Guide body clips at AX.** `Views/GuideView.swift:48` (`.clipped()` on the pager) with the page `ScrollView` at `:249-279`. Fix: `.scrollIndicators(.visible)` on the page ScrollView and a 24 pt bottom fade (`.mask` with `LinearGradient` to clear) instead of the hard clip. The fixed `.system(size:)` fonts inside `GuideArtCard` (`:399-873`) are a labelled illustration: allowed (section 11).

**T17. Plus: Ask to Buy pending copy (finding 6, ruled medium-high).** `PlusView.swift:215`: StoreKit `.pending` means a parent must approve, possibly hours later, but the text says "tap Restore". Add a distinct outcome `awaitingApproval` for StoreKit `.pending`, copy "Sent to a grown-up to approve. Plus turns on once it's approved."; keep the old line for the slow-entitlement poll timeout (`EntitlementService.swift:111`). Same for Seasons (`PackCatalog.Copy.pending`). Run through CopySafety.

**T18. Plus: loading state (finding 4).** While `loadProducts` runs or only some products came back: when `!store.offers(selected)` hide the fine print and show `ProgressView()` + "Loading prices" in place of the CTA; dim the fill only; add "· save N%" only when `monthlyPrice > 0`. Cards show no empty price. Keep the existing failed state with "Try again", now with a spinner while retrying.

**T19. Plus: renewal line vs 24-hour rule (finding 3).** `Paywall.swift:103` becomes "Renews automatically unless cancelled at least 24 hours before the end of the period. Cancel anytime in your App Store account settings." Update `PaywallRulesTests`.

**T20. Plus: unselected circle contrast (finding 5).** `PlusView.swift:142`: `appPrimaryText.opacity(0.3)` is 1.75:1 light, 2.21:1 dark. Use `.opacity(0.55)` (same as `PuzzleInk.blankOutline`, 3:1 or better). Also `.accessibilityHidden(true)` on the circle so the combined card reads words plus "Selected".

**T21. Plus: prices in words (finding 7).** `PlusView.swift:106`: "$12.99/yr" and "$3.99/mo" become `price + " a year"` / `" a month"`; Plus Forever `"\(price) once"`. Also removes the predicted AX5 break after the slash.

**T22. Plus: footer Restore stays, nudge becomes text only (finding 12, ruled).** On the Plus page `FamilyShareNudgeRow(placement: .plusPage)` shows only `FamilyShareNudge.Copy.line` ("Already have Plus on a family phone? Restore purchases is below.") and no second button. Settings keeps its button. Update the copy constant and its test; CopySafety.

**T23. Plus: "Not quite" contrast (finding 8).** Gate error line: `appDanger` is 3.69:1 on white in light mode. Use `Color.appPrimaryText` with an `exclamationmark.circle` icon (no new asset).

**T24. Plus: messages (finding 9).** Message colour `appPrimaryText` (not `successText`, as Seasons); post `AccessibilityNotification.Announcement(message).post()` when it is set; drop the success string that is never seen (activeCard says "You have WordFlora Plus").

**T25. Plus: Restore feedback (finding 10).** `restoring` state disables the button while `AppStore.sync()` runs; then a message "Plus is on." or "No purchases found for this Apple ID." (copy-check). Same for `SeasonsView.swift:22`.

**T26. Plus: VoiceOver (finding 11).** `.accessibilityAddTraits(.isHeader)` on "WordFlora Plus" (`PlusView.swift:31`); confirm `FlowerView` is `.accessibilityHidden(true)` (`:30`); keep "WordFlora is complete without Plus." as the first line in every layout.

**T27. Plus: non-breaking hyphen (finding 13).** `Paywall.swift:108`: `"Start 3\u{2011}day free trial"`; update `PaywallRulesTests:34` if it compares a different literal.

**T28. Plus: inline strings into `PaywallCopy.all` (finding 14).** Load-failure line (73), "Try again" (74), active-card lines (158-159), welcome / pending / failure lines (214-217), plus every string added in T17 to T25.

**T29. Settings Theme picker.** Not applicable (Appearance picker removed in G3). Nothing to do; do not add a replacement.

**T30. Shed tool effect line.** Covered by T14 (`ShedTools.swift:199`); verify at xxxL and AX5 on the tool sheet that no line truncates.

**T31. My Garden cards check.** Covered by T1; additionally confirm botanical-name captions (italic) wrap, not clip, at AX.

**T32. Quiet Garden check.** The tend bar was rebuilt in G3; Quiet Garden shows the same bar with no supply captions. Do not change the bar. Just run the audit and the screenshots on a Quiet Garden plant page at AX5 and xxxL and report "More tomorrow" / "Trim" fit.

---

## 5. Low (do these if time remains, in this order)

- **Visitors V5** `VisitorsBookView.swift:129`: "Met on <date>" shows the latest meeting. Copy only: `FieldNotesCopy.metOn` becomes "Seen on \(date)" ("Last" is banned by CopySafety); update `pageLabel`, spec lines, the `all` sample.
- **V6** `ButterflyView.swift:679-681` RarityChip: `.background(tint.opacity(0.06), in: Capsule())` (common chip 4.26:1 becomes 4.73).
- **V7** `FieldNotesPage.swift:156`, `FieldNotesCopy.pageLabel` (`:31-33`): make `met` a `String?`, include the "Seen on" sentence only when non-nil; pass `metOn` directly.
- **V8** `ButterflyView.swift:646-647`, `Butterfly.swift:178-181`: add `nightOnly` to `cardLabel`'s unmet branch and append `notMetHint(nightOnly:)`.
- **V9** `ButterflyView.swift:641`: unmet dashed outline opacity 0.3 to 0.55.
- **V10** `ButterflyView.swift:513-516`: ring `@ScaledMetric(relativeTo: .title3) var ring: CGFloat = 62`.
- **V11**: tracking 1.2 on both Visitors headers (`ButterflyView.swift:482`, `VisitorsBookView.swift:119`).
- **Butterfly summary reward row** `ButterflyView.swift:289-293`: footnote line "1 water · 6 shed points · 1 soil" instead of bare icons.
- **Card titles** `GameView.swift:287, 298, 318, 325`: route through `cardTitle(_:)` (brand green, not system black). Confirm rest and break cards scroll at AX (`GameView.swift:486-495`); if not, drop `minHeight: geo.size.height` at AX.
- **Quiet Garden tool sheet** `ShedTools.swift:249-250, 294`: `[.medium, .large]` when `quiet` and not AX.
- **Level map AX stub** `LevelMapView.swift:105-115`: skip the trail when `oneColumn`.
- **Onboarding tip** `OnboardingView.swift:246`: "Your first drink is ready!".
- **Daily quest** `DailyQuestCard.swift:36`: "Not done yet" when `target == 1`.
- **Wake puzzle** disabled button `.opacity(0.6)` (`WakePuzzleView.swift:45`).
- **Plant page toast** suffix: drop "+N growth" or say "and it grew a little" (`Rules/PlantVoice.swift:17`).

Everything else in `all-pages-visual-review.md` section 2 tagged **L** (home hero, weather overlays, back affordances, Settings restyle, Guide nits, dark haze panel, "Great word!" dim) is not in this pass.

---

## 6. Rulings the builder must follow (from the reviews)

- Single glyphs may shrink: `Components/KeyboardView.swift:97` and `Components/WordTilesView.swift:118` keep `minimumScaleFactor` (one letter in a fixed key). Do not "fix" them.
- Drawn illustrations may use fixed sizes: `GuideView.swift:390-873` (`GuideArtCard`), `Components/SeedPotView.swift:30-32`, and the share image at `BadgeDetailView.swift:97-101`.
- `GameView.swift:218` "Take your time" pill uses `.fixedSize()` on purpose; verify at AX5 that it does not exceed the flower width, report if it does.
- The tend bar and Prune/Mist rows are G3's; do not edit `LifePanel.swift:31, 302` or `TendActionButton`.

---

## 7. Copy and tests for non-layout items

- Every new or changed line goes into its `*Copy.all` and through `CopySafety`. Update `PaywallRulesTests`, `FamilyShareNudge` tests, `FieldNotesCopy` tests.
- Unit tests: T6 trial guard (offer none / non-trial / free trial); `PrimaryButtonStyle` is not unit-testable, cover with the Plus UI audit; T17 outcome mapping (`.pending` -> `awaitingApproval`).
- No new stored field, no `Models/` diff (grep it before the report).

---

## 8. Acceptance

1. **Layout unit test** (`WordFloraTests/TextFitLayoutTests.swift`), extending the tend-bar width test the G3 builder added (same pattern: `UIFont.preferredFont(forTextStyle:compatibleWith:)` in the rounded design and matching weight, per Dynamic Type size). For each of Garden names (incl. "Passionflower", "Snapdragon"), Badges names, Shed pot names (incl. "Snowflake indigo", "Rainbow bark", "Terracotta"), Repot tile names and goal lines, soil chips ("Compost"), Visitors' book names ("Snowflake", "Ladybird", "Rainbow") and Visitors play-card / Field Notes / detail names ("Hummingbird", "Swallowtail", "Bumblebee"), "butterflies" in the toggle label, and the Plus card price strings: measure the longest word at every size from xS to AX5 against the per-cell width at **375, 393 and 402 pt**, using the same column helper and paddings the view uses (expose the cell-width calculation so the test and the view share it). Fail if any word is wider than its cell. Where a screen is too tangled to measure, say so in the report and rely on the screenshots.
2. **`performAccessibilityAudit`** (iOS 26) at `accessibilityExtraExtraExtraLarge` (AX XXXL), light and dark, on every touched screen: Garden, Badges, Shed (tools and pots), Repot sheet, Visitors page, Visitors' book, Field Notes page, visitor detail sheet, Butterfly game, Plus page (including loading and failed states), parental gate sheet, Grand garden, Guide, Quiet Garden plant page. Zero issues, no waivers for clipped or truncated text. Where an audit exists already, extend it; do not create parallel files unless needed.
3. Grep clean on touched files: no `.dynamicTypeSize(` caps, no `ViewThatFits`, no `minimumScaleFactor` (except the two single-glyph files), no `lineLimit` on reading text, no fixed `.system(size:)` outside the allowed illustrations.
4. Full unit suite; the UI classes you touched (Garden, Settings, Plus, parental gate, Visitors, Shed / Repot, Guide); report counts.
5. Contrast re-measure for T20, T23, V6, V9 (state the ratios).

## 9. Screenshots

Store in the scratchpad `shots/` folder (create `shots/textfit/`), named `<screen>-<device>-<size>-<scheme>.png`. Look at every image yourself and say what you saw in the report.

Plus page (from the Plus review), on iPhone SE (375x667) and iPhone 16 (393 wide), using `-uitest-prices`:
1. Default text and AX5 (Accessibility XXXL), light and dark, scrolled top and bottom (all three cards, fine print, nudge line, footer). Confirm no sideways overflow, and "WordFlora", the prices ("$12.99 a year") and "Terms of Use / Privacy Policy" do not break.
2. The grown-up question sheet at default and at AX5, **with the number pad up** on the 375 phone (Continue and Cancel reachable), light and dark.
3. Monthly selected, and Plus Forever selected (CTA and fine print).
4. Loading state (store delayed) and the failed state.
5. Owned states: subscriber, Plus Forever, Plus Forever beside a renewing subscription.
6. Ask to Buy pending message and Restore messages ("Plus is on." / "No purchases found...").

Other screens, at xxxL and AX5, 375 and 393, light and dark where it matters: Garden, Badges, Shed pots, Repot sheet (tiles and soil chips), Shed tool sheet, Visitors page (play card, easier toggle, ring), Visitors' book, Field Notes (Hummingbird page), visitor detail sheet (Hummingbird), Butterfly game (light-mode title on evening sky), Grand garden crown label, Guide pages with the fade, Quiet Garden plant page, rest and break cards at AX.

## 10. Report

Final message must contain: commit hashes in order, test counts and reds with reasons, audit results per screen, the contrast numbers, the screenshot list with what you saw, the `Models/` diff (must be empty), the grep-for-attribution result (prints 0), items skipped and why, anything you disagree with (ask, do not silently deviate), and open items. Do not write the report to a file.

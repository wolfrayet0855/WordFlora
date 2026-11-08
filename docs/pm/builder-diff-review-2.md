# Builder diff review 2: A (engagement quick wins) and B (widget fixes)

Date: 2026-11-08. Read-only review: no build, no simulator, no edits to either worktree. Same checks as `builder-diff-review.md`.

- **A**: `.claude/worktrees/agent-aabade169b9af62f9`, HEAD `d173c5d` (7 commits, 29 files). Share age gate (`ShareGate`, `canShare`), Make it yours (`PlantName`, `AppModel+PlantName`, `NameOnArrivalRow`, `WidgetPinRow`), the weekly garden note (`WeeklyNote`, `WeeklyNoteCard`, `WeekShareCard`, `weeklyNoteSeenWeek`). Spec: `docs/pm/engagement-quick-wins.md`.
- **B**: `.claude/worktrees/agent-aca9586a97830ae9b`, HEAD `9ba7179` (2 commits, 6 files). `GardenWidget.swift`, `WaterControl`, `WidgetActions` + `WidgetCopy`, computed `PlantSnapshot` fields, `TendingEngine.projectedWater` / `nextTrickle`, `PlantVoice` in the widget target, intent reloads, `accessoryInline`. Spec: `docs/pm/widget-review.md`.
- Base: `3-feat-content-and-polish` at `2e9aac4`. A starts from `d200d09`, B from `28204c6`; the commits since are docs only.
- **Correction to the brief:** the text-fit branch (`worktree-agent-a2bea51afc81e7059`, now `6227903`) and polish pass 2 (`worktree-agent-a0f8716ff1989be39`, now `0b819d0`) are **not merged** into `3-feat-content-and-polish` yet. I trial-merged against them anyway (merge plan below).

## Verdict

- **Safe to merge A: yes.** No blockers. Fix A1 (the weekly note can be used up on a visit where the player never sees it) before release. A2 is a one-line fix. One real conflict with the text-fit branch in `GameView.swift`, and it takes a minute to resolve.
- **Safe to merge B: yes.** No blockers. B1 (a typed plant name shows on the Lock Screen) and B2 (`ViewThatFits` against the owner's layout rule) both need an owner ruling before release. Neither blocks the merge. B merges cleanly onto everything.

## Findings, by severity

### Medium

**A1. The weekly note is marked seen the moment Home appears, even when the player never looks at Home.**
`WordFlora/App/AppModel+WeeklyNote.swift:29` (`markWeeklyNoteSeen` inside `takeWeeklyNote`), called from `HomeView.swift:187` in `onAppear`. Home is the root of the stack, so its `onAppear` also fires when the app opens straight onto another screen. The common case is a widget tap (`wordflora://plant/<id>`, `widgetURL` on every widget family), and the widget is the main way players come back. On a Monday that visit records the week, and the note never shows.
Fix: only take the note on a real Home visit. In `showWeeklyNoteIfDue()` (`HomeView.swift:321`), add `guard router.path.isEmpty else { return }`, or call it again from the place where the stack returns to the root. Add a unit test: deep link first, then Home, and the note still shows.

**B1. A typed plant name now shows on the Lock Screen (inline and rectangular), for every age.**
`WordFlora/Shared/WidgetActions.swift:67` (`name: p.nickname.isEmpty ? p.name : p.nickname`). The new `inline` family is at `GardenWidget.swift:302` ("Pip: growing nicely"). Rectangular already showed the name. With A, every age can type a name, and a child may type their own name, which can then be read on a locked phone. Siri and Control Center dialogs say the name too (`waterGarden`). The spec expects this (`widget-review.md:129`, "Nickname … appears on the Lock Screen"), and the engagement spec allows names for under 13 because they stay on the device or in iCloud. The Lock Screen is the one place where that name can be read without unlocking the phone. Owner decision.
Minimal fix (pick one):
- (a) add `.privacySensitive()` to the name `Text` in `rectangular` (`:294`) and to the inline `Label` (`:302`), so iOS redacts it while the phone is locked;
- (b) for under 13 and unknown ages, the accessory families use the species name: add a computed `species` to `PlantSnapshot` and choose with `SharedDefaults.store.string(forKey: "ageBand")`.

I recommend (a) for every age.

**B2. `ViewThatFits(in: .vertical)`, `minimumScaleFactor(0.8)` and `lineLimit(2)` in the widget, against the owner's rule** ("no shrinking, no capped type, no ViewThatFits", `Spacing.swift:23`, `LifePanel.swift:244`).
`GardenWidget.swift:223` (small) and `:258` (medium right column). The name has `.lineLimit(2).minimumScaleFactor(0.8)` at `:164`. The capsules have `minimumScaleFactor(0.8)` at `:170`, and there are more at `:294, :298, :313`.
Judgement: the vertical fit only drops optional rows (chip, then name, or the row of other plants, then the line). It never switches between a row and a column, and the old `ViewThatFits(in: .horizontal)` row-to-column switch was removed. A widget cannot scroll, and `widget-review.md` fix 1 asked for exactly this. I find it acceptable as a written exception for widgets only.
If the owner keeps the rule absolute, choose the tiers from the text size, the way `rectangular` already does:
- small: chip only below `.xLarge`, name only while `!typeSize.isAccessibilitySize`;
- medium: the row of other plants only below `.accessibility1`, the line only below `.accessibility3`.

Keep the 0.8 scale on the name only, or ask the owner to sign off on it.

### Low

**A2. The Plus card can share Home with the weekly note.** `HomeView.swift:324`: `otherCardShowing` checks the weather card, the weather banner and the welcome card, but not `app.plusOffer`. The offer stays on `AppModel` (`AppModel.swift:551-576`) until it is dismissed, so an offer from an earlier visit is still up when the note arrives. Then two cards show at once. Fix: add `|| app.plusOffer != nil`. (`EndgameHomeCard` can also sit above the note for Grand Garden players. It is a status line, not a prompt, so I suggest leaving it.)

**A3. Name rule edge cases.** `WordFlora/Rules/PlantName.swift:15`:
- `CharacterSet.alphanumerics` includes the M* categories (combining marks). So a name made only of combining marks (`"\u{301}\u{301}"`) passes.
- 16 base letters, each carrying dozens of stacked marks ("zalgo"), also pass and draw a tall tower over the win card, the widget and the Lock Screen.
- Bidi controls (U+202A-202E, U+2066-2069, U+200E/F) are kept. Inside "Hello! I love the name \(name)." they can reverse the rest of the line.

Fix:
- require a scalar whose `properties.generalCategory` is a letter or number category;
- drop bidi control scalars, but keep U+200D (emoji ZWJ sequences);
- cap the result at 64 unicode scalars.

Already right, with tests: trimming, 16 whole characters (emoji and accents never split), the trailing space trimmed after the cut, emoji-only or punctuation-only gives "" (back to the species name), digits only ("7", "R2") kept, and plain RTL names. Note that a pencil Save with emoji only silently clears an existing name. The spec intends this ("" means the species name).

**A4. Names that come back from a restore or a sync skip the rule.** `Storage/GardenBackup.swift:160` accepts nicknames up to 60 characters, `:204` copies them as they are, and `DataReconciler.swift:114` does the same. Older names saved as `prefix(16)` without trimming also remain. Fix: run `PlantName.clean` at both places.

**A5. "Show on my widget" wording.** `AppModel+PlantName.swift:17`: `isOnWidget` is false when `widgetPlantID` is nil, even for the plant the widget already shows by default. `hasGardenWidget` (`:31`) counts every family, so a player with only a Lock Screen widget reads "Your Home Screen widget will show …". Both are harmless. Fix (optional): compare with `WidgetActions.snapshot(...).hero?.plantId`, and say "your widget".

**A6. Test gaps.**
- Week key at the year boundary: Fri 1 Jan 2027 should give the key of Mon 28 Dec 2026, and `pastWeek` should cross New Year. `dateInterval(of: .weekOfYear)` with `minimumDaysInFirstWeek = 1` should give a full 7-day week, but no test pins it.
- Name cases with only combining marks and with bidi controls (see A3).

**B3. On daylight saving days the midnight entry misses midnight.** `GardenWidget.swift:91`: `startOfDay + 86_400 + 60`.
- On a 25-hour day this lands at 23:01 on the same day. "Watered today" and "Said hello" do not reset until the next refresh, which can be up to 6 hours later.
- On a 23-hour day it lands at 01:01 on the next day.

The line was carried over from before. Fix: `Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!.addingTimeInterval(60)`.

**B4. The voice seed is a UTC day.** `WidgetActions.swift:73` matches `AppModel.helloLine` (`AppModel.swift:198`), so the app and the widget agree on the line, which is the goal. But the line changes at UTC midnight, not at local midnight. Leave it for 1.0. If it is ever changed, change both places together.

**B5. `familyOverride` is dead code.** `GardenWidget.swift:133`: nothing in the repo passes it (no test, no preview). Delete it, or use it in a `#Preview`.

### Info: checked and fine

- **CopySafety:** I ran every new string literal in both diffs, plus all `PlantVoice` pools, through the banned list with the `\b` regex. There were zero hits ("last" and "left" included). `WidgetCopy.all`, `PlantNameCopy.all` and the weekly note strings are swept in tests. Typed names are the player's own words and are not linted, by design.
- **Under 13 and unknown ages:**
  - `ShareGate` (= `!ParentalGate.isRequired`) hides the Daily Bloom share, the plant card share, the fact share (`NameStoryCard.shareable`, off by default) and "Share my week" (which is also off in Quiet Garden).
  - The badge share uses the same line.
  - Every remaining `ShareLink` in the app is behind one of these.
  - Share captions and `WeekShareCard` use species names only; `PlantShare.caption` no longer takes a nickname.
  - The widget "Visit" link appears only for a seed. Seeds never exist under 13, in Calm or in Quiet Garden (`SharedDefaults.loveExempt` = `AppModel.loveExempt`), and the link is an in-app deep link, not an outbound one.
  - Typed names do leave the phone through iCloud sync (Plus) and the backup file the player saves. This matches the spec's "device/iCloud".
- **Week key:** Monday-start Gregorian calendar in the device time zone. The key is built from the Monday's local year, month and day, so it does not move with daylight saving or a time zone change, and tests cover both. `pastWeek` is counted in calendar days.
- **One card at a time:** the note waits while a weather card, weather banner, welcome card or the nudge is up. The daily quest is hidden on a note visit, and the Plus check is skipped (but see A2).
- **UserDefaults and App Group:**
  - `weeklyNoteSeenWeek` (camelCase, like the other keys) is in `AppSettings`, whose store is `SharedDefaults.store` (the App Group, device-local, not synced).
  - `widgetPlantID` is the existing `PlayerProfile` field in the SwiftData store in the group container, which the app and the widget both open.
  - `rename` and `pinToWidget` save, then `reloadAllTimelines()`. The app also reloads on background.
- **Widget timeline:**
  - `projectedWater` gives the same count `applyTrickle` would: a full can stays full, and the drops due are capped.
  - Both use the mister-adjusted economy (`ToolEngine.trickleEconomy`, as the water intent's `ToolEngine.applyTrickle` does).
  - `nextTrickle` is `lastTrickleAt + (n+1) × interval`, or nil once the can is full by then. A `lastTrickleAt` in the future is clamped, and the 6-hour cap still applies.
  - Entries are `[now, midnight if before the refresh, refresh]` with `.after(refresh)`, at most 6 hours, or 15 minutes when the store cannot be read.
  - The widget writes nothing outside the intents, and both intents now call `reloadAllTimelines()`.
- **PlantVoice in the widget target:** the file imports only Foundation, and nothing in it reaches app-only types. `LoveEngine`, `ToolEngine`, `TendingEngine` and `WidgetActions` were already in the widget target. The new `TendingEngine` calls it uses (`isDone`, `waterings`, `isToday`) exist.
- **Accessibility:**
  - Water: "Water Daisy. 1 drop in your can" (singular via `drops`); Quiet Garden gives no count.
  - "Daisy watered today", "Say hello to / You said hello to Daisy today", "Visit Daisy".
  - Circular: "Daisy, growing" with the value "40 percent". The growth bar has a label and a value.
  - Plant art is hidden from VoiceOver.
- **Dynamic Type in the widget:** rectangular and the empty state choose their layout from `typeSize.isAccessibilitySize` (no measuring). For small and medium, see B2.
- **Models:** neither branch touches `WordFlora/Models`. The new `PlantSnapshot` fields are computed when the snapshot is taken, not stored.
- **pbxproj:**
  - In the trial merge of the tip with text-fit, polish, A and B, `plutil -lint` passes, there are no conflict markers, and no object id is defined twice. The only repeated id is the app target's key in `TargetAttributes`, which is expected.
  - Membership: A's seven app files are in WordFlora, `PlantNameTests` and `WeeklyNoteTests` in the unit tests, `EngagementUITests` in the UI tests. B's `PlantVoice.swift` is in WordFlora and WordFloraWidget (id `5E1D0A11C0FFEE0000000002`, unique), and `WidgetActionsTests` is in the unit tests.

## Merge plan

The trial merges (`git merge-tree`, no refs touched) give:

| Merge | Result |
|---|---|
| tip + text-fit | clean |
| … + polish | conflict in `docs/pm/live-status.md` only |
| … + A | conflict in `WordFlora/Views/GameView.swift` only |
| … + B | clean |
| A + B alone | clean |

1. Merge text-fit, then polish (keep both sections of `live-status.md`), as in `builder-diff-review.md`.
2. Merge A. Resolve the `earnedCard` found-plant branch (around line 338) by keeping text-fit's card line and A's fact and name row:
   ```swift
   PlantCard(plant: plant, standalone: true).frame(maxWidth: PlantCard.foundWidth(dynamicTypeSize))
   // Full ink: at 85% the audit reports the fact as low contrast on the dark card.
   Text(plant.botanicalFact).font(Theme.font(.callout)).multilineTextAlignment(.center).foregroundStyle(Color.appPrimaryText)
       .fixedSize(horizontal: false, vertical: true)
   if vm.earnedPlantIsNew { NameOnArrivalRow(plant: plant) }      // Make it yours (PlantName)
   ```
   These merge on their own: `shareButton` (A's `canShare` guard), `NameStoryCard` (text-fit layout plus A's `canShare`), `PlantDetailView` (A's `rename` / `WidgetPinRow` / `.shareable`), `HomeView`, `WordFloraApp`, and pbxproj.
3. Merge B (no conflicts).
4. After merging, run:
   - the full unit tests (`PlantNameTests`, `WeeklyNoteTests`, `ShareTests`, `WidgetActionsTests`);
   - `EngagementUITests`;
   - `TextFitScreensUITests` at AX5: the found-plant win card is taller now, with the "Give it a name" button;
   - `TendingUITests.testTheNameStoryCardSitsUnderThePlantAndExpands`, which expects "Share this fact" at the onboarded 18+ age and should pass;
   - `WordFloraUITests`.

   Then do the widget device checks in `widget-review.md` section 5, including the Lock Screen name after B1 is decided.
5. Before merging, check that `git log --format=%B 3-feat-content-and-polish..<branch> | grep -icE "claude|anthropic|co-authored|opus|sonnet|session"` prints 0 (it does for both A and B today). Do not commit the main checkout's uncommitted `WordFlora.xcscheme` edit.

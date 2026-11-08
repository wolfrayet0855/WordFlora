# Widget review (Fable, 2026-11-07)

Scope: `WordFloraWidget/` (GardenWidget, WaterControl, bundle, Info.plist, entitlements, privacy manifest), `WordFlora/Shared/` (WidgetActions, SharedDefaults, GardenIntents), `Storage/SharedContainer.swift`, `App/GardenShortcuts.swift`, the deep-link router, the App Group wiring in `project.pbxproj`, and the engagement builder's plant-pin work (task B, worktree `agent-aabade169b9af62f9`). Read-only review of the main checkout at `4132120` (branch `3-feat-content-and-polish`); no build, no simulator, so every layout judgement below is arithmetic on point sizes and must be confirmed on the owner's device (section 5). Nothing in the widget has ever been seen rendered (`docs/STATUS.md:13`).

Line numbers refer to the main checkout at the commit above.

## 1. Verdict per family

| Family | Verdict | Why |
|---|---|---|
| systemSmall | **needs work** | Fixed 74 pt image + name + chip + 28 pt button + 12 pt spacing = about 147 pt of content in a widget whose content box is about 126 pt tall on a 6.1" phone (158 pt minus 16 pt padding each side). Likely clipped top and bottom at the default text size; certainly at larger sizes. Fix 1. |
| systemMedium | **small fix** | Fits at default size (left column 84 + 20; right column 44 + 16 + 28). At the accessibility sizes the right column overflows (stacked buttons alone are about 60 pt). The two row images carry no accessibility labels. Buttons are silent when done for today or when the plant is a seed. Fixes 1, 3, 4. |
| accessoryCircular | **small fix** | A growth gauge with a water-drop icon says "water" but measures growth; no accessibility label at all (VoiceOver reads "40 percent"). Fix 6. |
| accessoryRectangular | **ok** | Name, chip, linear growth gauge. Handles `unavailable` with the calm fallback line. Nothing identifying beyond the name the player chose. |
| accessoryInline | **missing** | Not in `supportedFamilies`. One case and one list entry add it. Fix 7. |
| WaterControl (iOS 18 Control Center) | **small fix** | Works, but the tap is silent: no action label while it runs, no dialog (controls cannot show one). Fix 8. |
| Siri / Shortcuts (`WaterGardenIntent`, `OpenGardenIntent`) | **ok** | Two phrases each, calm dialog lines, falls back to `GardenFallback.intentLine` when the store is not ready, reloads timelines after. |
| Placeholder / gallery snapshot | **small fix** | Placeholder is a redacted rose, fine. The gallery snapshot (`getSnapshot`) loads real data, so a new install sees the "Play a word to find your first plant" empty state in the widget gallery instead of a plant. Fix 5. |
| Empty states | **small fix** | Small and medium show "Play a word to find your first plant" even when the store is merely not readable yet (`unavailable`), and link to `wordflora://play`. The rectangular family gets this right. Fix 2. |

What is right and should stay: one shared rule set for app, widget, Siri and control (`WidgetActions`), the thirsty look never shown in a widget (`calm: true`, `GardenWidget.swift:81`), free drops credited before a tap spends one, Quiet Garden watering spends nothing, `HelloPlantIntent` never wakes a seed from the widget, no ad, no purchase surface, no streak, no countdown, every string passes `CopySafety.check` (I ran the list by hand: the widget's 14 literals plus the weather lines contain no banned word), the privacy manifest declares the App Group reason `1C8F.1` and collects nothing, deep links are ignored until onboarding is complete (`WordFloraApp.swift:244`), and the pin fallback when the pinned plant is not owned is tested.

## 2. Ranked fix list

Small, low-risk, no new stored fields, no new permissions, all offline. "Device" means the owner must confirm on a phone (section 5). Hours are builder hours including tests.

1. **Small widget layout (needs work, 1.5 h, device).** `WordFloraWidget/GardenWidget.swift:160-172` and `:174-194`. Wrap the small stack in `ViewThatFits(in: .vertical)` with three candidates: image + name + chip + button; image + name + button; image + button. Make the plant image flexible: `plantImage(s, height:)` becomes `.frame(maxHeight: height)` (line 128) inside a `frame(maxHeight: .infinity)` so it gives way first. Add `.minimumScaleFactor(0.8)` on the name (line 165) and the button labels (lines 136, 143, 152). Same `ViewThatFits(in: .vertical)` on the medium right column with and without the row of other plants (line 183). Every word then fits at every Dynamic Type size because the shortest candidate is image + button and the button label shrinks to 80 percent.
2. **Empty state says the wrong thing when the store is not ready (small fix, 0.5 h).** `GardenWidget.swift:217-223`. `empty` ignores `entry.unavailable`. Change the text to `entry.unavailable ? GardenFallback.widgetLine : "Play a word to find your first plant"` and the URL to `wordflora://` (open the app) when unavailable. Today a player upgrading from a build without the App Group store, or a phone whose widget profile lacks the group (section 4), is told to "play a word" when they may have forty plants.
3. **Buttons that react (small fix, 3 h, device).** `WordFlora/Shared/WidgetActions.swift:9-16, 38-43`, `GardenWidget.swift:132-158`. Add computed, not stored, fields to `PlantSnapshot`: `waterDone` (`TendingEngine.isDone(.water, ...)`), `saidHelloToday` (`TendingEngine.isToday(p.lastLovedAt, ...)`), `isSeed` (`LoveEngine.state(...).isSeed` with the exempt rule). The water button shows "Watered today" with `checkmark` and is not a button when `waterDone`; the hello button shows "Said hello" with `heart.fill` when `saidHelloToday`; for a seed (13+ only, never under 13, Calm or Quiet) the hello button becomes a `Link` "Visit" to `wordflora://plant/<id>` because the widget cannot wake a seed. Mark the drop count `.invalidatableContent()` so it blurs during the reload. Full spec in section 6, quick win 1.
4. **Reload every instance after a widget tap (small fix, 0.2 h).** `GardenWidget.swift:19-21, 39-42`. WidgetKit reloads only the widget whose button was tapped. Add `WidgetCenter.shared.reloadAllTimelines()` after the action in both `perform()`s (as `WaterGardenIntent` already does, `GardenIntents.swift:21`) so the Lock Screen gauge and a second Home Screen widget do not sit six hours behind.
5. **Gallery snapshot shows a plant (small fix, 0.3 h).** `GardenWidget.swift:64-66`. In `getSnapshot`, when `context.isPreview` and `load().snapshot.hero == nil`, complete with `placeholder(in:)` so the widget gallery shows a rose, not the empty state.
6. **Lock Screen accessibility (small fix, 0.5 h).** `GardenWidget.swift:196-215`. Circular: icon `leaf.fill` not `drop.fill` (the gauge is growth), `.accessibilityLabel("\(s.name), growing")` with `.accessibilityValue("\(Int(s.growthFraction * 100)) percent")`. Rectangular gauge: `.accessibilityHidden(true)` (the name and chip already say it). Small and medium: `.accessibilityHidden(true)` on the hero and row images (lines 128, 183) and labels on the buttons: water "Water \(name). \(n) drops in your can" (not "left": banned), link "Play a word to fill your can". Hello already has a label.
7. **accessoryInline (small fix, 0.3 h, device).** `GardenWidget.swift:108, 117-123`. Add `.accessoryInline` to `supportedFamilies` and a case: `Label(hero.map { "\($0.name): \(entry.weatherChip ?? "growing nicely")" } ?? "WordFlora", systemImage: "leaf.fill")`. The system truncates inline text itself; keep it to name + chip.
8. **Control Center action label (small fix, 0.2 h, device).** `WordFloraWidget/WaterControl.swift:9-11`. Use the `ControlWidgetButton(action:label:actionLabel:)` initialiser and show `Text("Watering")` while active; the rest stays. The owner's device checks whether the control's tap is felt at all.
9. **Trickle freshness (small fix, 1 h).** `GardenWidget.swift:68-78`. A free drop arrives every 4 h (2 or 3 h with a Mister) but the timeline refreshes every 6 h, so the widget can show "Play a word" while a drop is in the can. Add a timeline entry at the next trickle instant: `profile.lastTrickleAt + ToolEngine.trickleEconomy(.default, inventory: ToolInventory(json: profile.toolsJSON)).trickleHours * 3600`, and cap the `.after` policy at that time. The entry still reads the stored count, so also add a pure `TendingEngine.projectedWater(profile, now, economy) -> Int` (the arithmetic of `applyTrickle` at `TendingEngine.swift:99-106` without the writes) and use it in `WidgetActions.snapshot` (`WidgetActions.swift:29, 45`) for the displayed count. The tap path already credits drops first, so nothing is lost today; the button is just hidden when it could work.
10. **Widget copy under test (small fix, 0.5 h).** Move the 14 literals in `GardenWidget.swift` (lines 61, 106-107, 136, 143, 152, 157, 166, 184, 201, 213, 220 and the two intent titles) into `enum WidgetCopy` inside `WordFlora/Shared/WidgetActions.swift` (no new file, so no pbxproj edit) and assert `CopySafety.check` is empty for each in `WordFloraTests/WidgetActionsTests.swift`, as `StoreResolveTests.swift:125` already does for the two fallback lines.
11. **Tinted and clear rendering (device first, then maybe 0.5 h).** iOS 18 "Tinted" and iOS 26 "Clear" Home Screens render widgets in `.accented` mode: fills and text are flattened to the tint and a primary colour, images become tinted silhouettes. The two capsule buttons (`Color("ink")` on `Color("appAccent")`, `appPrimaryText` on `appSurface`) could lose contrast. If the device shows that, add `.widgetAccentable()` to the water capsule and, under `if #available(iOS 18, *)`, `.widgetAccentedRenderingMode(.fullColor)` on the hero image. Light and dark are fine by the numbers: ink on accent about 6:1 both ways (ink's dark variant stays dark on purpose), primary text on surface about 9:1 and 8:1, the 0.7-opacity chip about 4.6:1 in light.

Not a fix, a note: the plant art is the flat species image at every stage (`Image(s.imageName)`), the same as `PlantCard` in the app, so a stage-0 seed looks like a bloom on the Home Screen. The Lock Screen growth gauge is what tells the stage. Acceptable for 1.0; a per-stage silhouette is a backlog idea.

## 3. Interactive and meaningful

### 3.1 What the player can do today, and whether it is felt

| Family | Can do | Felt? |
|---|---|---|
| systemSmall | Tap the drop capsule: waters the hero plant (spends a drop, credits free drops first). Tap anywhere else: opens that plant's page. When the can is dry: a "Play a word" link into a round. | **Half felt.** After the tap WidgetKit re-renders this widget, so the number drops from 3 to 2 and the Lock Screen gauge moves later (up to 6 h, fix 4). No haptic exists for widget buttons on iOS. When the plant has had its two drinks the tap does nothing and the label does not change: **silent**. |
| systemMedium | Water (as above) and "Say hello" (sets `lastLovedAt`, counts toward the daily quest when the app returns, keeps the petals). Tap elsewhere: plant page. | Water as above. Hello is **silent**: nothing on the widget changes, no line, no heart fill. For a 13+ seed (petals gone) the hello is refused by rule and the button still looks live. |
| accessoryCircular / Rectangular | Glance only; tap opens the app. | n/a; the growth gauge is the one piece of state that visibly moves after a watering. |
| Control Center (iOS 18) | Water the hero plant. | **Silent** beyond the widget reload (fix 8 adds "Watering"). |
| Siri / Shortcuts | "Water my garden", "Open my garden". | **Felt**: Siri speaks "Daisy had a drink and is growing nicely." or the calm blocked line. |

In the app a hello sways the plant, floats hearts and answers with a `PlantVoice` line in the toast (`PlantDetailView.swift:398-407`). The widget hello has none of that. Quick wins 1 and 2 give it a changing label and the plant's own answer.

### 3.2 What it tells the player that matters

Today: the hero plant's name (nickname wins), the drops in the can, "Growing nicely" or tomorrow's garden weather ("Tomorrow: windy" small and Lock Screen, "Tomorrow: a big wind. Your garden is ready." medium; never in Calm, Quiet Garden, or under 13 by default), up to two other plants as pictures, and on the Lock Screen the growth toward full bloom (`growthPoints` over the level cost, `WidgetActions.swift:40-42`). It never shows thirst (by rule), a streak, a countdown, a missed day or a comparison. The dry-can state turns into an invitation ("Play a word") rather than a shortage. That is the right tone: the reason to open the app is "something good is there", never "something is wrong".

What is missing for meaning: the plant never speaks from the Home Screen (the personalities are the app's warmest feature), the medium's default line "Your garden says hello" is static for most days, a new stage is not called out (the growth bar on the Lock Screen moves, the Home Screen says nothing), and the weekly note and friend of the day exist only in the app. Of these, the plant's voice is the cheapest and the most personal; the others need more of the app's rules in the widget target (section 7).

### 3.3 What popular widgets do well (five lines)

Finch: the pet sits on the Home Screen with one tap action and a one-line mood that changes after you act, so the tap is answered. Pokémon Sleep and Apple Fitness: one ring, one number, readable in a glance from the Lock Screen, no words needed. Apple Journal: a prompt that changes daily, phrased as an invitation, never a count of missed days. Planta and most plant-care widgets: a short list of what is due, which is exactly the pressure WordFlora refuses, so we take the "one plant, one gentle action" shape instead. Duolingo: the streak flame is effective and guilt-driven; we deliberately do not copy it.

### 3.4 Top quick wins for 1.0 (build specs)

All three: no new stored model field, no new permission, offline, under-13 safe, same look in Quiet Garden and Calm (Calm and Quiet only remove the weather line, as today).

**Quick win 1. Buttons that answer (about 3 h).** This is fix 3 plus fix 4.
- Files: `WordFlora/Shared/WidgetActions.swift` (`PlantSnapshot` gains `waterDone`, `saidHelloToday`, `isSeed`; `snapshot(context:now:calm:)` gains a `calendar` and `exempt` argument, defaulted), `WordFloraWidget/GardenWidget.swift` (`waterButton`, `helloButton`, both `perform()`s), `WordFloraTests/WidgetActionsTests.swift`.
- States: can has drops and plant not done: button "3" with `drop.fill` (Quiet: "Water"); done: `Label("Watered today", systemImage: "checkmark")` in the surface capsule, not a button; dry can and not done: "Play a word" link (as today). Hello: not yet today: "Say hello" with `heart`; said today: "Said hello" with `heart.fill`, still a button (a second hello is harmless and the app allows repeats); seed: `Link("Visit", wordflora://plant/<id>)` with `leaf.fill`.
- Copy (all pass `CopySafety.check`): "Watered today", "Said hello", "Say hello", "Visit", "Play a word", "Water". Accessibility: "Water \(name). \(n) drops in your can", "\(name) watered today", "Say hello to \(name)", "You said hello to \(name) today", "Visit \(name)".
- Tests: snapshot flags flip after `WidgetActions.water` and `WidgetActions.hello` (reuse the existing `WidgetActionsTests` fixtures), `isSeed` false when exempt, copy list passes `CopySafety`.
- Device: tap each state on a real Home Screen; confirm the label changes within a second and that the Lock Screen gauge updates right after (fix 4).

**Quick win 2. The plant answers (about 2.5 h).**
- Files: `WordFlora.xcodeproj/project.pbxproj` (add `WordFlora/Rules/PlantVoice.swift` to the widget target; it imports Foundation only), `WordFlora/Shared/WidgetActions.swift` (`static func line(for s: PlantSnapshot, weather: String?, day: Int) -> String`), `WordFloraWidget/GardenWidget.swift:184` (the medium line), tests.
- Rule, in order: the weather line when there is one (unchanged); else when `saidHelloToday`, `PlantVoice.helloLine(plantId:daySeed:tap: 0)` so the hello is answered in the plant's own voice for the rest of the day ("Hello to you too!" style lines, same pool as the app); else when the plant was watered today, `PlantVoice.line(plantId:event:.water, daySeed:)` ("Mmm, a gentle drink."); else `"Your garden says hello"` as today. Small widget keeps the chip. `day` is `WeatherDay.key(date)` so the line is stable through the day and the same the app would pick.
- Copy: existing `PlantVoice` pools, already in the app; add a `CopySafety` sweep over every pool to the widget copy test if none exists.
- Accessibility: the line is plain `Text`, read in order after the name.
- Tests: `line(for:)` picks weather first, hello second, water third, default last; determinism for a fixed day.
- Device: read the line after a widget hello; confirm it changes and stays for the day.

**Quick win 3. Glanceable progress and the inline family (about 1.5 h).** Fixes 5, 6, 7 and 8 together.
- Medium gets a thin growth bar under the name: `ProgressView(value: s.growthFraction).tint(Color("appSuccess"))` with `.accessibilityLabel("Growing")` and `.accessibilityValue("\(percent) percent")`, so a watering from the widget is seen to move something (the app's Life panel shows the same fraction). Inline Lock Screen line "Daisy: growing nicely" / "Daisy: Tomorrow: windy". Gallery shows a plant. Control Center shows "Watering" while it runs.
- Copy: "Growing", "growing nicely", "Watering", existing chips. Pass `CopySafety`.
- Tests: `supportedFamilies` includes inline (a view test is not practical; a unit test on the copy helper), snapshot preview path returns the placeholder when empty.
- Device: inline on the Lock Screen at the largest text size; the growth bar in light, dark and tinted.

### 3.5 File overlap with the engagement builder (task B)

Task B touches `WordFlora/App/AppModel+PlantName.swift` (new), `WordFlora/Components/PlantNameViews.swift` (new), `WordFlora/Rules/PlantName.swift` (new), `WordFlora/Views/PlantDetailView.swift:455` (one line), tests and UI tests, plus `project.pbxproj` for the three new files. The widget work touches `WordFloraWidget/GardenWidget.swift`, `WordFloraWidget/WaterControl.swift`, `WordFlora/Shared/WidgetActions.swift`, `WordFloraTests/WidgetActionsTests.swift`, and `project.pbxproj` only for quick win 2 (one file membership). **No Swift file overlaps.** The one shared file is `project.pbxproj`; sequence B's merge first and have the widget builder add `PlantVoice.swift` to the widget target after rebasing, or do quick win 2 last. B's `pinToWidget` and `rename` already call `WidgetCenter.shared.reloadAllTimelines()` (`AppModel+PlantName.swift:13, 24`), and `WidgetActions.snapshot` already prefers the pin and falls back when the pinned plant is not owned (`WidgetActions.swift:32-37`, tested), so B needs nothing from the widget side.

## 4. The App Group question

Log seen on the owner's device Debug run: `Couldn't read values in CFPrefsPlistSource ... Domain: group.beta.WordFlora ... Using kCFPreferencesAnyUser with a container is only allowed for System Containers, detaching from cfprefsd`.

What is in the repo (all correct):
- Both entitlement files carry `com.apple.security.application-groups = [group.beta.WordFlora]`: `WordFlora/WordFlora.entitlements:15-18`, `WordFlora/WordFlora-Simulator.entitlements:15-18`, `WordFloraWidget/WordFloraWidget.entitlements:5-8`.
- Both targets point at them in both configurations: `CODE_SIGN_ENTITLEMENTS` at `project.pbxproj:1842-1843, 1877` (app, Debug with the simulator variant, Release) and `:1662, 1909` (widget, Debug and Release). Automatic signing, team `P9Z5QB8965`, bundle ids `beta.WordFlora` and `beta.WordFlora.WordFloraWidget` (`:1863`, `:1675`), deployment target 17.5.
- One suite name everywhere: `SharedDefaults.groupID` (`Shared/SharedDefaults.swift:5`) and `SharedContainer.appGroupID` (`Storage/SharedContainer.swift:7`) are the same literal; every shared key (`calmMode`, `quietGarden`, `ageBand`, `gardenWeather`, `storeHome`) is read through the same `SharedDefaults.store` in both processes. No key-name drift.
- The widget never creates or moves a store; it opens the group store only after the app has written `storeHome = group` (`SharedContainer.swift:74-77, 90-96`), otherwise it shows the calm fallback and retries in 15 minutes.

What the log line means: it is printed by cfprefsd for every `UserDefaults(suiteName:)` App Group suite on the simulator and is noise there. On a device it has two readings. If the running binary's provisioning profile lacks the group, the suite detaches and nothing persists: the app would re-run onboarding on every launch (the age band lives in that suite, `AppSettings.swift:72-77`), iCloud could never stay on, and the widget would show "Play a word to find your first plant" forever (fix 2 makes it the calm fallback instead). If the profile has the group, the line is still printed on first access by some iOS versions and is harmless. The owner did not report re-onboarding, so the group most likely works; the checks below settle it in five minutes. Also note the `?? .standard` fallback in `SharedDefaults.store` never fires (the initialiser does not return nil for an unentitled group), so it is not a safety net.

Can shared state break on a real device? Yes, in exactly one way: the App Group missing from one target's profile. The developer-portal step is the usual cause: the group must be attached to **both** App IDs (`beta.WordFlora` and `beta.WordFlora.WordFloraWidget`) before Xcode's automatic signing can put it in both profiles (`docs/setup/owner-setup-steps.md` B3 step 3 says so; B6 step 3 for the widget). If only the app has it, the app works and the widget silently never sees a plant.

Exact checks for the owner (in order; stop at the first that proves it):
1. **Xcode, Signing & Capabilities, both targets.** Project > target **WordFlora** > Signing & Capabilities: "Automatically manage signing" on, team P9Z5QB8965, the **App Groups** capability present with `group.beta.WordFlora` ticked and no red text. Repeat for target **WordFloraWidget**: the same group ticked, same team, no iCloud capability. A red "Provisioning profile doesn't include the App Groups entitlement" here is the answer.
2. **Developer portal.** developer.apple.com > Identifiers > App Groups shows `group.beta.WordFlora`; Identifiers > App IDs > `beta.WordFlora` and `beta.WordFlora.WordFloraWidget` each show App Groups configured with that group. If the widget's App ID lacks it, tick it there, then in Xcode untick and retick App Groups on the widget target so the profile regenerates.
3. **The built app (no device needed).** After a device build: `codesign -d --entitlements :- <DerivedData>/Build/Products/Debug-iphoneos/WordFlora.app | grep -A2 application-groups` and the same for `WordFlora.app/PlugIns/WordFloraWidgetExtension.appex`; and `security cms -D -i WordFlora.app/embedded.mobileprovision | grep -A3 application-groups` plus the `.appex`'s `embedded.mobileprovision`. All four must list `group.beta.WordFlora`.
4. **A Debug print (no shipped change).** In `WordFloraApp.init` under `#if DEBUG`: `print("appGroup:", FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedDefaults.groupID) as Any, "storeHome:", SharedDefaults.store.string(forKey: SharedContainer.homeKey) as Any)`. Run on the device twice. A non-nil `file:///private/var/mobile/Containers/Shared/AppGroup/...` URL and `storeHome: Optional("group")` on the second run means the app side is fine. For the widget side, add the same print to `GardenProvider.load` and attach the debugger to the widget extension (Debug > Attach to Process by PID or Name > WordFloraWidgetExtension) after adding the widget; or simply add the widget and check it shows a plant within a minute of opening the app once.

Verdict: no code change needed for the App Group; fix 2 is the only code item, so that a mis-provisioned widget says "Your garden says hello. Open WordFlora to visit." rather than "Play a word".

## 5. Needs a device to verify (for `docs/pm/g6-device-checklist.md`, under C1 Widget)

- [ ] Small widget at default text size: name, chip and button all visible, nothing clipped top or bottom. Repeat at the two largest accessibility sizes.
- [ ] Medium widget at the largest accessibility size: buttons visible and tappable.
- [ ] Light, dark, iOS 18 Tinted and iOS 26 Clear Home Screens: button text readable on both capsules; plant art acceptable as a tinted silhouette.
- [ ] Tap water: number drops within a second; tap again after two drinks: label reads "Watered today" (after quick win 1). Lock Screen gauge moves without waiting six hours (fix 4).
- [ ] Tap "Say hello" then open the app: the daily quest's hello count includes it; the plant page shows the hearts as loved today.
- [ ] Water from the widget, then bring the app to the front **without relaunching**: Home shows the reduced drop count and the plant's growth. If it does not, the app's `ModelContext` is not refreshing objects changed by the widget process (two-process writes, `docs/STATUS.md:41`); log it as a 1.0 fix (refetch on `.active`).
- [ ] Widget added before the app is ever opened on a fresh install: shows the calm fallback (after fix 2), then a plant within 15 minutes of the first round.
- [ ] Lock Screen circular, rectangular and inline (after fix 7) at Large text and with VoiceOver: labels make sense ("Daisy, growing, 40 percent").
- [ ] Control Center "Water my garden": the control responds, shows "Watering" (after fix 8), and the Home Screen widget updates.
- [ ] Siri "Water my garden in WordFlora" with the app closed and with it open: the spoken line matches the widget's count afterwards; no ad on return.
- [ ] Deep link from the small widget opens Garden then the plant page; from the empty state opens a round; a tap during onboarding does nothing.
- [ ] Nickname set in the app appears on the widget and on the Lock Screen after the app goes to the background.
- [ ] App Group checks 1 to 4 in section 4, once.

## 6. For docs/pm/backlog.md (list only, not added)

- Per-stage plant silhouette in the widget (seed, sprout, bloom) instead of the flat species image; needs art or a stage scale like `GrandGardenArt.stageScale`.
- Medium widget "today" states beyond the plant voice: today's quest line (`DailyQuest.quest` needs `FeatureUnlockPolicy` in the widget target), friend of the day (`Butterfly.friendOfTheDay` plus `VisitorCatalog`, gated on visitors unlocked), the weekly note on its day (task A's `WeeklyNote`). Each pulls more rules into the widget target; do after device checks of 1.0.
- A new-stage moment on the widget ("Daisy grew!") for the day a stage changes; needs the day of the last stage change, which is a new stored field.
- Configurable widget (`AppIntentConfiguration`) to choose the plant from the widget's own edit sheet, as an alternative to the in-app pin.
- iOS 18 `widgetAccentedRenderingMode(.fullColor)` art pass once Tinted mode has been seen on a device.
- Live Activity for a Speed bloom or a weather day: not for 1.0.
- Siri "Say hello to Daisy" (already in the backlog from the plant-attachment research).
- A `TendingEngine.projectedWater` used by the app's Home too, so Home and widget never disagree on the count between trickles.

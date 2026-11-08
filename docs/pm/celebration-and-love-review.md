# Celebration and love review: the "Great word!" card, the hello toast, "Hellos help"

Date 2026-11-07. Branch `3-feat-content-and-polish`. Read-only review, no build. Owner feedback after a device test:

> "Make Great Word or 1 of 3 a little more animated. this must encourage users to keep play or perform a different
> action. also when you love the plant and the words come up like yay hello, that light green icon is super hard to
> see. remove hello's help from love petals, thats something that is learned."

Three small items. Each fits the scope-freeze release (small, low risk, high value), keeps the calm tone (no pressure,
no streak guilt, no confetti storm), passes `CopySafety` (no "last", "only", "miss"...), and respects Reduce Motion
and Calm / Quiet Garden. Estimated 3 to 4 hours for one builder, including the test edits.

---

## A. The "Great word!" / "1 of 3" card

### What happens today

`Views/GameView.swift`:

- `:127-144` (`onChange(of: vm.phase)`): on a win with no plant, `winBurst` stays `nil` (no petals), the dim fades in
  over 0.3 s (0.15 s Reduce Motion), and `showEarned` turns on at 0.7 s (0.15 s RM). The lub-dub haptic plays only
  when a plant arrived. The one win sound `.word` already played in `GameViewModel` (`:379`).
- `:313-340` (`earnedCard`), the `else` branch at `:323-334`: title "Great word!" (`PlantProgressCopy.winTitle`), the
  line "1 of 3 words to your next plant." (`PlantProgressCopy.winLine`), the fact, then one primary button "Continue"
  (`:337`). The `HOOK (progress meter)` comment at `:326` marks the planned meter spot.
- The card's only motion is the `dimmed(...)` transition at `:501`: `.opacity` plus `.scale(0.96)`.

So a word that does not bring a plant gets: a grey dim, a card that fades in, static text, "Continue". Nothing moves,
nothing says what the next tap does. That is the gap the owner felt. (The plant card at `:318-322` has the large petal
burst, the lub-dub and the plant art; it is not the problem.)

No current screenshot of this card survives in the scratchpad; `WordFloraUITests.testAfterTheFirstPlantEveryThirdWordBringsTheNext`
already saves `word-toward-plant` on word 1, so the builder gets the before/after shot from that test.

### Proposed change A1: three petal pips, one fills with a soft pop

Replace the `HOOK` comment with a small meter: three pips in a row, one per word toward the plant, the new one filling
with a gentle pop and a small petal puff. The count line stays under it (the UI test reads it, and VoiceOver needs it).

**View.** New `struct WordsToPlantPips: View` (about 40 lines). Put it at the bottom of
`Components/PetalPipRow.swift` (that file is not in the text-fit worktree and the project has no synchronized groups,
so a new file would mean a `project.pbxproj` edit; avoid that).

```swift
/// Three pips for the words toward the next plant (win card). The pip just earned fills with a soft pop.
struct WordsToPlantPips: View {
    let filled: Int          // vm.wordsTowardPlant, 1...per-1 on this card
    let total: Int           // vm.wordsPerPlant (3)
    let popped: Bool         // false while the card appears, true ~0.35 s later
    let reduceMotion: Bool
    let calm: Bool
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { i in
                let isNew = i == filled - 1
                let on = i < filled && (!isNew || popped)
                ZStack {
                    Circle().stroke(Color.appPrimaryText.opacity(0.55), lineWidth: 2)   // >= 3:1 on cream and dark
                    Circle().fill(LifePalette.leaf).opacity(on ? 1 : 0)
                        .scaleEffect(on ? 1 : (reduceMotion ? 1 : 0.5))
                }
                .frame(width: 16, height: 16)
                .animation(reduceMotion ? .easeInOut(duration: 0.3)
                           : .spring(response: 0.4, dampingFraction: calm ? 0.85 : 0.55), value: on)
            }
        }
        .accessibilityHidden(true)       // the count line under it says the same
    }
}
```

Colours (all already in the app):
- Filled pip `LifePalette.leaf` = `#5E8F1F` light / `#A8D84A` dark. On the card's `appBackground` (`#FAF7F0` / `#1A2E1A`)
  that is 3.6:1 light and 8.7:1 dark. Passes the 3:1 non-text rule.
- Empty pip: 2 pt stroke `appPrimaryText.opacity(0.55)`; `Theme.swift:11` already documents that 55% ink is at least
  3:1 on the cream and on a tile. No fill, so it reads as "not yet", never as a loss.
- Do not use `LifePalette.leafBright` here: `#9BCB3C` on cream is 1.8:1.
- Not the rose love petals (`PetalPips`): those mean love on the plant page; a word count must not look like love.

**Wiring in `GameView.swift`:**

1. Add `@State private var pipPopped = false`.
2. In `onChange(of: vm.phase)` (`:127-144`), inside the `if phase == .won` block: set `pipPopped = false`, then
   after the card has appeared schedule the pop:
   ```swift
   let cardAt = reduceMotion ? 0.15 : 0.7
   DispatchQueue.main.asyncAfter(deadline: .now() + cardAt + 0.35) {
       guard vm.phase == .won, vm.earnedPlantName == nil else { return }
       pipPopped = true
       pipPuff += 1                                      // see 3
       if app.settings.hapticsOn { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5) }
   }
   ```
3. Add `@State private var pipPuff = 0` and, in the `else` branch of `earnedCard` (`:323`), replace the `HOOK` comment
   line with:
   ```swift
   WordsToPlantPips(filled: vm.wordsTowardPlant, total: vm.wordsPerPlant, popped: pipPopped,
                    reduceMotion: reduceMotion, calm: app.settings.calmMode || app.settings.quietGarden)
       .padding(.vertical, 2)
       .overlay {
           // A small puff from the pip that just filled. Level resolved by CelebrationStyle (Calm: smallCalm, RM: still arc).
           PetalPuff(trigger: pipPuff, level: app.celebrationLevel(.small, systemReduceMotion: systemReduceMotion), arcRadius: 28)
               .frame(width: 120, height: 120)
               .offset(x: pipOffset(filled: vm.wordsTowardPlant, total: vm.wordsPerPlant))
               .allowsHitTesting(false)
       }
   ```
   `pipOffset` = `(CGFloat(filled - 1) - CGFloat(total - 1) / 2) * 28` (16 pt pip + 12 pt gap). `PetalPuff` and
   `app.celebrationLevel` already exist (`Components/PetalConfettiView.swift:171`, `App/AppModel.swift:828`).
4. Reset `pipPopped = false; pipPuff = 0` where the card closes (the button action at `:337`, see A2).

**Timeline (normal):** t=0 win sound and `.success` haptic (existing) → 0.3 s dim → 0.7 s card fades/scales in
(existing) → 1.05 s the new pip springs from 0.5 to 1 (one small overshoot, ~0.4 s), 14 petals puff from it for 0.8 s,
one soft haptic (0.5). Total new motion: under a second, inside the card, no screen-wide burst. The plant card is
unchanged (it already has the large burst).

**Reduce Motion (system or `settings.reduceMotionOverride`):** dim 0.15 s, card 0.15 s (existing); the pip cross-fades
from empty to filled over 0.3 s with no scale; `PetalPuff` resolves to `.reduceMotion` (a still arc that fades, opacity
only). The haptic stays (it is not motion).

**Calm / Quiet Garden / Low Power:** `app.celebrationLevel` resolves the puff to `.smallCalm` (8 petals, 0.6 s); the
spring uses `dampingFraction 0.85` (settles without a bounce). Pass `calm: app.settings.calmMode || app.settings.quietGarden`
(Low Power is already inside `celebrationLevel`).

**Optional, same spot (all-pages review item 29):** the dim at `GameView.swift:274` and `:490` is `Color.black.opacity(0.45)`,
which turns the cream flat grey (`#8A8884`). `Color.appPrimaryText.opacity(0.4)` keeps the garden tint (`#A8ADA2` light,
`#647A64` dark). One-line change, cosmetic; take it if touching those lines anyway.

### Proposed change A2: the nudge toward the next action

Two changes to the `else` branch and the button row:

1. **Primary button says what it does.** On the no-plant card only, rename "Continue" to **"Next word"**
   (already the primary on the rested card, `GameView.swift:308`, so the vocabulary exists). The plant card keeps
   "Continue" (it has the share button and B1 "name on arrival" coming; leave it alone).
2. **One extra line when the next word brings the plant.** Under the count line, when `wordsPerPlant - wordsTowardPlant == 1`:
   **"One more word and a new plant arrives!"** Shown only then, so the card never has two progress sentences on the
   first word. In `Rules/ProgressionPolicy.swift` `PlantProgressCopy`:
   ```swift
   /// Under the count line on the word before a plant. Nil otherwise.
   static func nextLine(toward: Int, per: Int) -> String? { per - toward == 1 ? "One more word and a new plant arrives!" : nil }
   ```
   Style: `Theme.font(.callout, weight: .semibold)`, `Color.successText` (4.8:1 light, 7.2:1 dark on `appBackground`),
   centred, `.fixedSize(horizontal: false, vertical: true)`. Add it to the `PlantProgressCopy` test in
   `WordFloraTests/GameViewModelTests.swift:249-252` and to whatever `CopySafety` sweep covers that enum.
   `CopySafety.check` on the line returns `[]` (no "last", "only", "hurry", "now").
3. **Secondary action: "Tend my garden".** A `SecondaryButtonStyle` button under "Next word" that does the same cleanup
   as the primary and then goes to the garden:
   ```swift
   Button("Tend my garden") {
       showEarned = false; winDim = false; winBurst = nil; pipPopped = false; pipPuff = 0
       app.markPeakDismissed(); app.pauseBadgeMoments(.round, false)
       router.home(); router.go(.garden)
   }
   .buttonStyle(SecondaryButtonStyle())
   .accessibilityIdentifier("winCard.tendGarden")
   ```
   `GameRoute.garden` exists (`App/GameRouter.swift:5`). This skips the resting card on a session beat on purpose: the
   player chose to leave the round, which is the calm path. Daily Bloom (`vm.isDaily`) also shows it; the tutorial
   (`tutorial == true`) must not (the tutorial has its own hand-off in `afterRound`), so wrap it in `if !tutorial`.

Why a button and not a timer, auto-advance or a streak line: the owner asked to "encourage", not to push. Two clearly
named choices (keep playing, or go tend) is the whole nudge. No countdown, no "don't lose your streak", no third button.

**Copy check (`Rules/CopySafety.swift`)**: "Next word", "Tend my garden", "One more word and a new plant arrives!" contain
none of the banned words. "One more" also appears as `RestCardCopy.oneMore`, so the tone is already approved.

**Tests to update when renaming the button (3 sites, all mechanical):**
- `WordFloraUITests/WordFloraUITests.swift:69`: `app.buttons["Continue"].tap()` → `app.buttons["Next word"].tap()`
  (this loop only sees no-plant cards). Add `XCTAssertTrue(app.staticTexts["One more word and a new plant arrives!"].exists)`
  at `n == 2` and `XCTAssertFalse(...)` at `n == 1`, plus `XCTAssertTrue(element("winCard.tendGarden").exists)`.
- `WordFloraUITests/WordFloraUITests.swift:790` loop and `WordFloraUITests/RestCardUITests.swift:47` loop: word 1 is the
  first plant ("Continue"), words 2 and 3 are no-plant cards ("Next word"). Use
  `app.buttons.matching(NSPredicate(format: "label IN %@", ["Continue", "Next word"])).firstMatch`.
- `CelebrationUITests:66`, `SpeedBloomUITests:88` (`-uitest-onboarded` without `-uitest-gardened`, so the first win is a
  plant card): unchanged. `WordFloraUITests:867, 935` and `SeasonsUITests:141` are the parental gate's "Continue": unchanged.
- `TextFit`/audit tests: the new pip view is `accessibilityHidden`; the two new texts use text styles, wrap, no caps.

**Accessibility:** VoiceOver order on the card: "Great word!" (header via `cardTitle` once text-fit lands), the count
line, the optional next line, the fact, "Next word", "Tend my garden". The pips are hidden. No `lineLimit`, no fixed
font sizes, everything wraps at AX5; the card already scrolls (`dimmed(centered:)`).

---

## B. The hello toast: why the light green icon disappears

### Where

`Views/PlantDetailView.swift:626-645` (`toastView`). A tap or Living Touch hello calls `hello(_:)` (`:398-406`) →
`show(app.helloLine(plant, tap: hellos), ok: true, after: 0)` → the toast with `Image(systemName: "checkmark.circle.fill")`
coloured `LifePalette.leafBright` (`:630`), text in `Color.appBackground`, on a `Color.appPrimaryText` slab (`:637`).
The lines are `PlantVoice` hello lines ("Yay, a hello!", "Hi there, friend!", `Rules/PlantVoice.swift:33-35`).

### The numbers (WCAG relative luminance, computed from the asset values)

Toast background = `appPrimaryText`: `#2C3E2C` light, `#D4EDD4` dark (`Assets.xcassets/appPrimaryText.colorset`).
Icon = `LifePalette.leafBright` (`Components/LifePalette.swift:13`): `#9BCB3C` light, `#A8D84A` dark.

| | Light mode | Dark mode |
|---|---|---|
| Icon `leafBright` on the toast | 6.0:1 (passes) | **1.34:1 (fails; nearly invisible)** |
| Text `appBackground` on the toast | 10.7:1 | 11.6:1 |
| Refusal icon `appBackground.opacity(0.85)` ("moon") | 8.2:1 | 7.6:1 |

In dark mode the toast slab is pale mint and the icon is light lime: two light greens, 1.34:1. Since G3, Appearance
follows the system, so the owner's evening device test was almost certainly in dark mode. That is the bug. (In light
mode it passes; the owner may also have seen it at 17 pt with no weight, which is small beside semibold text.)

Other candidates checked on the toast slab (light / dark): `successText` 2.2 / 1.6, `appSuccess` 4.1 / 1.9,
`LifePalette.heart` 2.9 / 1.9, `LifePalette.leaf` 3.0 / 1.3, gold `#F2B632` 6.3 / 1.5. None pass both modes as they
stand; every "light" green in the palette fails on the pale dark-mode slab.

### Fix (one palette line, one view line)

Keep the leaf green in light mode and use the palette's deep green in dark mode. Both values already exist in the app
(`leafBright` light, `successText` light):

```swift
// Components/LifePalette.swift, after leafBright
/// The tend toast's tick: leaf green on the dark slab in light mode, deep green on the pale slab in dark mode
/// (6.0:1 and 4.1:1; leafBright alone is 1.3:1 on the dark-mode slab).
static let toastTick = dyn(0x9BCB3C, 0x2E7D32)
```

Contrast on the slab: **6.0:1 light, 4.1:1 dark.** Both above the 3:1 non-text floor, dark above 4.5:1 as well.

```swift
// Views/PlantDetailView.swift:629-631
Image(systemName: toast.ok ? "checkmark.circle.fill" : "moon.fill")
    .font(Theme.font(.body, weight: .semibold))                      // scales with the text, a touch larger than it
    .foregroundStyle(toast.ok ? LifePalette.toastTick : Color.appBackground.opacity(0.85))
```

Fallback if the lead prefers zero new palette entries: `Color.appBackground` (same as the text, 10.7 / 11.6), which
loses the green but is the standard "icon reads like the text" answer. The owner asked for a visible icon, not a
different one, so the first option is the recommendation.

Not changing: the `TapBurst` hearts (`Color.pink` on the page: 3.4 / 4.1, fine) and the toast's position (all-pages
review item 17 accepted it for a 3 s toast). `leafBright` keeps its other uses (Life panel growth dots on
`appSurface`, where a dark check sits inside it).

---

## C. Remove "Hellos help" from the love petals

### What it is

`Rules/LifeStats.swift:84`: `loveLines = ["Full of energy", "Lots of energy", "Hellos help", "Ready for a hello", "Ready for you"]`.
`:148-153` picks `loveLines[2]` ("Hellos help") when today's hearts are 1 or 2. It is shown in the Life panel's Energy
block right under the five hearts and right above the love-petal pips (`Components/LifePanel.swift:101`, `Text(snapshot.loveLine)`),
and spoken as `heartsLabel` ("Energy, 1 of 5 hearts. Hellos help", `LifeStats.swift:60`). After a first hello the panel
opens itself on the next visit (hearts changed, `LifePanelVisit`), so this is exactly the line the owner met after the
"yay" toast.

The owner is right that it is a lesson, not a state: the guide page "Hearts and hellos" (`Rules/GuideCopy.swift:55-59`)
already teaches it, and the plant's own hint "Tap <name> to give love" (`PlantDetailView.swift:512`) covers the action.

### Fix

Replace the lesson with a state word that matches its neighbours:

```swift
// Rules/LifeStats.swift:84
static let loveLines = ["Full of energy", "Lots of energy", "Some energy", "Ready for a hello", "Ready for you"]
```

Nothing else in Swift changes: `:151` still returns `loveLines[2]` for 1 to 2 hearts; the seed line (`[4]`) and the
0-hearts line (`[3]`) are untouched. "Some energy" passes `CopySafety` (it is already inside `allCopy`, which the copy
test sweeps).

**References to update:**
- `WordFloraTests/LifeStatsTests.swift:97`: expected `"Energy, 1 of 5 hearts. Hellos help"` → `"Energy, 1 of 5 hearts. Some energy"`.
- `design-preview/tending/lifestats.html:229` and `design-preview/tending/parts/crown-options.html:117` carry
  `'Hellos help'` as mock data; mirror to `'Some energy'` so the mockup matches the app (optional, two strings).
- `docs/STATUS.md:312` quotes the old list in a dated entry; leave history as it is, add one line to the new entry.
- `design-preview/tending/parts/notes/review-ux.md:11` and `overseer.md:20` are review notes; leave.

**Not in this change (owner call if wanted):** "Ready for a hello" at 0 hearts is also a nudge toward a hello, but it
describes a state ("ready") rather than teaching, and it is the only line that says the plant has had no care today.
Keep it unless the owner says otherwise. The TipKit popover "Say hello. Tap your plant. It likes company."
(`Components/GardenTips.swift:5-9`) shows once ever and is how the gesture is learned; keep.

---

## Files touched and merge order

| File | Change | Text-fit worktree (`a2bea51afc81e7059`) touches it? |
|---|---|---|
| `WordFlora/Views/GameView.swift` | A1 state + schedule (`:127-144`), A1/A2 card body (`:323-337`) | **Yes**: `:153-156` top bar, `:284-330` cards (`cardTitle(...)` on the same title lines, `PlantCard.foundWidth`). Same region as A. |
| `WordFlora/Components/PetalPipRow.swift` | A1 `WordsToPlantPips` appended | No |
| `WordFlora/Rules/ProgressionPolicy.swift` | A2 `PlantProgressCopy.nextLine` | No |
| `WordFlora/Components/LifePalette.swift` | B `toastTick` | No |
| `WordFlora/Views/PlantDetailView.swift` | B `toastView` (`:629-631`) | **Yes**, but at `:519-526` (`resources`), a different region; trivial rebase |
| `WordFlora/Rules/LifeStats.swift` | C `loveLines[2]` | No |
| `WordFloraTests/LifeStatsTests.swift:97`, `WordFloraTests/GameViewModelTests.swift:249-252` | C, A2 | No |
| `WordFloraUITests/WordFloraUITests.swift:69, 790`, `WordFloraUITests/RestCardUITests.swift:47` | A2 button name | No (text-fit edits `TendingUITests`, `BadgeMechanicsUITests`, `DailyQuestUITests`) |
| `design-preview/tending/lifestats.html`, `parts/crown-options.html` | C mock strings (optional) | No |

**Order for the lead:** text-fit merges first (it rewrites the win card's title lines to `cardTitle(...)`; A should be
written on top of that so the `else` branch is edited once). Then this review (small). Then quick win C (`shareButton`)
and B (`earnedCard` name-on-arrival), as in `docs/pm/parallel-lanes-conflict-map.md`, both of which land in the same
`earnedCard` and must rebase onto the new button row. B and C of this review (toast colour, "Some energy") do not
conflict with anything in flight and can go in any order, even as a separate first commit.

**Builder verification (no new audits needed):** run `WordFloraUITests.testAfterTheFirstPlantEveryThirdWordBringsTheNext`
(saves `word-toward-plant` and `third-word-plant`), `RestCardUITests`, `CelebrationUITests`, `LifeStatsTests`,
`GameViewModelTests`; then the existing AX-size audit on the win card (the rest-card audit tests cover `dimmed` cards).
Look at the toast in dark mode on the plant page (`tend-hello` shot in `TendingUITests` if it still exists; otherwise
tap a plant in the simulator with Appearance dark).

# Repot sheet v2: design and SwiftUI guidance

Page: `design-preview/repot-sheet/index.html` (open over file://; `?frame=a..f&theme=light|dark` renders one phone).
Shots: `shots/a-light.png` … `f-light.png`, rendered with headless Chromium at 393 x 852 @2x.

| Frame | State |
|---|---|
| A light | Default text. Rose pink picked, Terracotta in use, Blossom and Rose pink new, pill showing |
| B light | A pot to earn tapped (Living stones). Its hint sits in the footer |
| C dark | Same state as A |
| D light | AccessibilityL. Still 4 x 4 |
| E dark | Reduce Motion, a Plus pot tapped (Moonlit), scrolled to the soil row |
| F light | AccessibilityL, scrolled to the end |

## What was wrong (simulator shot, 14.22.48)
1. Four stacked headings took the top third of the screen.
2. Two-word names wrapped and one-word names did not, so the rows had different heights.
3. "Honey stripe" was clipped under the pinned button, because the scroll inset did not cover the button.
4. The button used `.title3` bold at 56pt and crowded the grid.
5. Pots to earn were flat grey with no goal.
6. The tap hint for a pot to earn was drawn under the grid, below the fold.

## Chosen design
- **Header**: one row. On the left, a 60pt thumb that shows the plant standing in the *picked* pot. It updates live, so it is also the preview. On the right, "Repot Daisy" and one subline: "Pick a pot. Changing pots is free."
- **New pots**: "New pots in your shed!" is now a small pill with a close button, shown once. On that same opening, each newly earned pot carries a tiny "New" tag. Closing the pill clears the tags too.
- **Grid**: 4 columns, 8pt gaps, and every tile is 108pt high. The name is one line and shrinks to fit. Line 2 always says the state:
  - the goal for a pot to earn ("Finish level 3", "Grow 35 plants", "Play on 7 days")
  - a "Plus" pill for a Plus pot
  - "In use" for the pot on the plant
  - nothing for other owned pots
- **Selected** (the picked pot): a 3pt `PotPalette.ring` border plus a 22pt check badge, so it reads by shape and not colour alone.
- **Tapped, not choosable** (a pot to earn, or a Plus pot without Plus): the tile turns `appSurface` and gets a double outline (2pt `appPrimaryText`, a 2pt surface gap, then a 1pt ink line at 35%) and no check. That makes it look different from the green picked ring. The footer hint repeats the same pot art (ghost or full), which ties the two together.
- **Pots to earn**: the ghost pot (soft fill, dashed outline) on a soft dashed tile, `lockfill`. The name stays full ink. No lock icon.
- **Plus**: full colour, and a small "✦ Plus" pill on line 2 (`tileBadgesFill` with `accentText`, as in Shed v2). No price.
- **Soil**: a "Soil" label and the line "Plants have favorite soils.", then 4 chips in one row (2 x 2 at AX sizes), each 44pt high. A small colour dot sits next to each name.
- **Footer** (pinned):
  - A context line. Normally it reads "**Rose pink pot**, fresh loam soil", with a mini pot.
  - After a tap on a pot you cannot pick, it becomes a hint card. For a pot to earn: "Finish level 3 to earn Living stones." / "Four more plants to go!". For a Plus pot: "Moonlit is part of WordFlora Plus." / "A grown-up can find Plus in Settings."
  - Then the button: 52pt high, one line, full width. The title is unchanged ("Repot into Rose pink" / "Repot with fresh soil").
- **Scroll**: at default size, all 16 tiles sit above the footer. The soil row scrolls in under a 28pt fade. The scroll view's bottom inset comes from `safeAreaInset`, so nothing is ever hidden under the footer.

## SwiftUI structure

### PlantDetailView.repotSheet
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 0) {
        RepotHeader(plant: plant, pot: picked)                 // 12pt gap to the pill or the grid
        if showNewPill { PotNewPill { showNewPill = false } .padding(.top, 12) }
        PotPickGrid(...)                                       // .padding(.top, 14); hint moved out (see below)
        SoilPicker(picked: $pickedSoil).padding(.top, 20)
    }
    .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 16)
}
.scrollIndicators(.visible)
.safeAreaInset(edge: .bottom, spacing: 0) { RepotFooter(...) }   // the inset is the footer's real height
.background(Color.appBackground)
.presentationDetents([.large])                                     // as today
.presentationDragIndicator(.visible)
```
- Do **not** add `.padding(.bottom, 8)` plus a separate background to the button. Use the `RepotFooter` below, so that its whole height, fade included, becomes the inset.
- Move `hinted` up from `PotPickGrid` into the sheet as `@State var hinted: String?`, and pass it to the grid as a `Binding`. The footer reads it.
- Move `record()` and `newPots` up the same way: `showNewPill` is set from `app.recordEarnedPots()` in `.onAppear`. The new-pot ids for the "New" tags come from the difference between the earned ids before and after the record. Make `recordEarnedPots()` return `[String]` (the new ids), or add a sibling `newlyRecordedPotIds()`. The Shed keeps using `!ids.isEmpty`.

### RepotHeader
```swift
HStack(spacing: 12) {
    PlantInPotThumb(plant, pot: picked)          // 60x60 @ScaledMetric(relativeTo: .title3), max 76
        .background(Color.tileGardenFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.appPrimaryText.opacity(0.12)))
        .accessibilityHidden(true)
    VStack(alignment: .leading, spacing: 2) {
        Text("Repot \(name)").font(Theme.font(.title3, weight: .bold)).foregroundStyle(Color.appPrimaryText)
            .accessibilityAddTraits(.isHeader)
        Text(PotCatalog.Copy.repotSub).font(Theme.font(.callout, weight: .medium)).foregroundStyle(Color.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}
.dynamicTypeSize(...DynamicTypeSize.accessibility1)    // header stops at AX1 so the grid keeps room (critic fix)
```
- Build the thumb with the same layers the plant page uses: `PotArtView(pot:width: 32)` at the bottom, and the plant's art above it with its stem base on the rim. If that costs too much, a static `PotArtView` (40pt) on its own is fine.
- With motion on, the thumb's pot cross-fades (0.2s) when the pick changes. With Reduce Motion it just swaps.

### PotNewPill (replaces PotNewLine)
```swift
HStack(spacing: 6) {
    Image(systemName: "sparkles").foregroundStyle(Color.successText).accessibilityHidden(true)
    Text(PotCatalog.Copy.newPots).font(Theme.font(.subheadline, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.8)
    Button(action: close) { Image(systemName: "xmark").font(.system(size: 11, weight: .heavy)) .frame(width: 28, height: 28)
        .background(Color.appPrimaryText.opacity(0.1), in: Circle()) }
        .frame(width: 44, height: 44).contentShape(Rectangle())          // 44pt target
        .accessibilityLabel("Close")
        .accessibilityIdentifier("pot-new-close")
}
.padding(.leading, 12).padding(.trailing, -4).frame(minHeight: 34)
.foregroundStyle(Color.appPrimaryText)
.background(Color.tileGardenFill, in: Capsule())
.dynamicTypeSize(...DynamicTypeSize.accessibility1)    // one line at default sizes; VoiceOver reads it in full
.accessibilityElement(children: .contain)
.accessibilityIdentifier("pot-new-line")               // keep the id; the label stays "New pots in your shed!"
.onAppear { AccessibilityNotification.Announcement(PotCatalog.Copy.newPots).post() }
```
- Cap it at `.accessibility1`, not xxxLarge (it is information, not a tag). The text is `appPrimaryText`, not `successText`. `successText` on `tileGardenFill` is 4.37:1, which is too low for text. Only the icon is green.
- Motion: it fades in with a 6pt rise. With Reduce Motion, it fades in only. Closing it fades it out.

### PotPickGrid tile
```swift
let columns = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: PotCatalog.gridColumns)
LazyVGrid(columns: columns, spacing: 8) { ForEach(PotCatalog.all) { tile($0) } }

// tile
VStack(spacing: 0) {
    PotArtView(pot: pot, style: toEarn ? .toEarn : .full, width: 48)
        .frame(height: 42, alignment: .bottom)
    Text(pot.name)
        .font(Theme.font(.caption, weight: .heavy)).foregroundStyle(Color.appPrimaryText)   // full ink, also for to-earn
        .lineLimit(1).minimumScaleFactor(0.6).allowsTightening(true)
        .padding(.top, 7)
    line2(pot, state)                          // see below
        .padding(.top, 3)
    Spacer(minLength: 0)
}
.padding(.top, 13).padding(.horizontal, 4)
.frame(maxWidth: .infinity)
.frame(height: isAX ? 104 : 108)               // FIXED; isAX = dynamicTypeSize.isAccessibilitySize
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)  // tile words stop growing here (as today)
.background(toEarn ? Color.lockFill : Color.appSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
.overlay {
    let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
    if isPicked { shape.strokeBorder(PotPalette.ring, lineWidth: 3) }
    else if hinted == pot.id { shape.strokeBorder(Color.appPrimaryText, lineWidth: 2)
        shape.inset(by: 4).strokeBorder(Color.appPrimaryText.opacity(0.35), lineWidth: 1) }   // + background appSurface
    else if toEarn { shape.strokeBorder(Color.appPrimaryText.opacity(0.32), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
    else { shape.strokeBorder(Color.appPrimaryText.opacity(0.12), lineWidth: 1) }
}
.overlay(alignment: .topTrailing) { if isPicked { PotCheckBadge(size: 22).padding(4) } }       // inside the tile, never offset out
.overlay(alignment: .topLeading) { if isNew { PotNewTag().padding(5) } }
.contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
```
`line2`:
- When `isCurrent`: a small outlined capsule, `Label(PotCatalog.Copy.current, systemImage: "checkmark")` ("In use"), `.caption2` heavy, `successText`, a 1.2pt `successText` stroke, padding 7/0. It is a pill so it does not read as a goal line. This is 5.1:1 on `appSurface` in light, and passes in dark too. Shown at every size.
- When `.plus` and not current: `PotPlusTag()`, restyled to the Shed v2 pill. Background `tileBadgesFill`, text and sparkle `accentText`, a 1.2pt `accentText` 55% stroke, padding 7/1. It stays capped at `.large`. Shown at every size.
- When `.toEarn` and not current: `Text(PotCatalog.goalLine(pot))`, `.caption2` bold, `secondaryText`, `.lineLimit(1).minimumScaleFactor(0.75)`. **Hidden when `isAX`**: the footer hint gives the goal on tap, and VoiceOver reads it in the hint.
- Otherwise: nothing. The `Spacer` keeps the height fixed.

The pot is now 48pt wide (it was 50) and sits 13pt from the top. It no longer needs the 12pt top room the old Plus tag took, because the Plus pill moved onto line 2.

**Colour note:** `lockFill` has no colorset. Use `Color.appPrimaryText.opacity(0.06)` over `appBackground` (#F1EEE6 light / #233823 dark), the same recipe as the Shed v2 "tool to find" tile. Do not add a colorset. The ghost pot colours come from `PotArtView`'s `.toEarn` style as they are.

`PotNewTag`: `Text("New")`, `.caption2` black weight, `appPrimaryText` on `tileGardenFill`, capsule, padding 6/1, capped at `.large`, `.accessibilityHidden(true)`. The tile label carries the news (see Accessibility).

### SoilPicker
- Header: `HStack(alignment: .firstTextBaseline, spacing: 8)` with "Soil" (`.headline` heavy, `.isHeader`) and "Plants have favorite soils." (`.subheadline`, `secondaryText`). Wrap it in a `ViewThatFits` so it stacks at AX sizes.
- `LazyVGrid(columns: isAX ? 2 : 4 flexible, spacing: 8)` of chips. Each chip is min height 44, radius 14, `appSurface`, with a 1pt hairline.
    - Content: a 10pt dot in the soil's colour, stroked with `appPrimaryText` 35%. The colours are art values, kept inline in code like the pot colours: loam #9A6B43, sandy #E6CB8E, peaty #2E211A, compost #6E8A3E. Each is clearly different from the others. Then the name in `.subheadline` bold, `.lineLimit(1).minimumScaleFactor(0.8)`.
  - Picked chip: a 3pt `PotPalette.ring` border, and `.isSelected`.
- Ids: `repot-soil-<raw>` (new).

### RepotFooter
```swift
VStack(spacing: 8) {
    Group {
        if let id = hinted { PotHintCard(pot: PotCatalog.pot(id: id), ...) }        // id "pot-hint" (kept)
        else { RepotSummary(pot: picked, soil: pickedSoil) }                       // id "repot-summary" (new)
    }
    .transition(.opacity)                                                         // cross-fade, also with Reduce Motion
    Button(action: go) {
        Text(PotCatalog.repotTitle(picked: picked, currentId: plant.potId))
            .font(Theme.font(.headline, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 52).padding(.horizontal, 16)
    }
    .buttonStyle(RepotButtonStyle())        // appAccent fill, ink text, radius 16, press scale 0.97 (none with Reduce Motion)
    .accessibilityIdentifier("repot-go")
}
.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 8)
.background(alignment: .top) {
    Color.appBackground
        .overlay(alignment: .top) { Rectangle().fill(Color.appPrimaryText.opacity(0.12)).frame(height: 1) }
        .overlay(alignment: .top) {
            LinearGradient(colors: [Color.appBackground.opacity(0), Color.appBackground], startPoint: .top, endPoint: .bottom)
                .frame(height: 28).offset(y: -28).allowsHitTesting(false)
        }
        .ignoresSafeArea(edges: .bottom)
}
```
- **RepotSummary** (capped at `.accessibility1`, `lineLimit(2)`; 10pt gap above the button): `HStack(spacing: 10)` with `PotArtView(pot, width: 30)`, then `Text("\(pot.name) pot").bold() + Text(", fresh \(soil.rawValue) soil")`. Use `.subheadline` (15pt), `appPrimaryText`, and `secondaryText` for the second part. Min height 44. Combine it for accessibility.
- **PotHintCard**: `appSurface`, radius 14, a 1pt hairline, padding 12/9.
  - Icon: `leaf.fill` in `successText` (a pot to earn) or `PotArtView(width: 24)` (Plus).
  - Text: line 1 in `.subheadline` heavy, line 2 in `.footnote` semibold `secondaryText`.
  - It replaces the dark inverted card under the grid. Keep the id `pot-hint` and the announcement on appear.
- A `PrimaryButtonStyle` variant: there is no need to touch the shared style. Add `RepotButtonStyle` or a `height:` parameter.

## Copy (grade 2–3; CopySafety clean)
| Key | String |
|---|---|
| `Copy.repotSub` (new) | Pick a pot. Changing pots is free. |
| `Copy.pickTitle` | removed from the sheet. Keep the constant for VoiceOver if wanted; the test that waits on the "Pick a pot" text changes (see Tests) |
| `Copy.pickSub` | folded into `repotSub` |
| `Copy.newPots` | New pots in your shed! (unchanged) |
| `Copy.newTag` (new) | New |
| `Copy.current` | In use (now shown on the tile) |
| `Copy.soilTitle` (new) | Soil |
| `Copy.soilSub` (new) | Plants have favorite soils. |
| summary | "\(pot.name) pot, fresh \(soil) soil" |
| hint, to earn | "\(goalLine(pot)) to earn \(pot.name)." + `tipLine` ("Four more plants to go!") |
| hint, Plus | `plusLine` + `Copy.plusSettings` (unchanged) |
| button | `repotTitle` (unchanged: "Repot into Rose pink" / "Repot with fresh soil") |

Add `repotSub`, `newTag`, `soilTitle`, `soilSub` and a sample summary and hint to the `CopySafety` sweep in `PotCatalogTests`.

## Accessibility
- Keep the ids `pot-tile-<id>`, `pot-hint`, `pot-new-line` and `repot-go`. New ids: `pot-new-close`, `repot-summary`, `repot-soil-<raw>`.
- Tile labels stay as in `PotCatalog.tileLabel` ("Rose pink pot", "Fly-trap pot, not earned yet", "Moonlit pot, Plus", "Terracotta pot, in use"). Add ", new" for a pot that is new on this opening: "Rose pink pot, new". The tests match the existing labels exactly, so **append** to them and keep the rest unchanged.
- For a pot to earn, set the accessibility value to the goal (`goalLine`), so VoiceOver reads it even at AX sizes where line 2 is hidden. Keep the hints `hintToEarn` / `hintPlus`.
- The picked tile keeps `.isSelected`. Soil chips get `.isSelected` too.
- Contrast (computed with WCAG luminance, not estimated):

| Pair | Light | Dark |
|---|---|---|
| Goal (`secondaryText`) on lockFill | 7.07 | 8.24 |
| "In use" (`successText`) on `appSurface` | 5.13 | 5.69 |
| Plus pill (`accentText` on `tileBadgesFill`) | 5.17 | 6.00 |
| Soil subline (`secondaryText` on `appBackground`) | 7.54 | n/a |
| Button (`ink` on `appAccent`) | 6.50 | 8.56 |
| New tag (`appPrimaryText` on `tileGardenFill`) | 9.76 | 7.39 |
| Ring and check vs `appSurface` (non-text) | 5.23 | 6.87 |
| `successText` on `tileGardenFill` (not used as text) | 4.37 | n/a |

  Names are `appPrimaryText` everywhere, above 10:1.
- Every control is at least 44pt: tiles are about 82 x 108, chips are 44 high, the pill close button has a 44 x 44 frame, and the button is 52.

## Reduce Motion (`@Environment(\.accessibilityReduceMotion)`)
| Thing | Motion on | Reduce Motion |
|---|---|---|
| Pick ring and check | spring 0.25s, check scales 0.6 to 1 | opacity 0.15s |
| Thumb pot swap | cross-fade 0.2s plus a 2pt drop | swap |
| Footer summary and hint | cross-fade 0.2s | cross-fade 0.15s |
| New pill in and out | fade plus a 6pt rise | fade |
| Button press | scale 0.97 | none |
No sounds or haptics change.

## Tests to add or adjust (WordFloraUITests/TendingUITests.swift, WordFloraTests/PotCatalogTests.swift)
1. `testNewPotsLineShowsOnceWhenPotsAreFirstRecorded`: wait on `app.buttons["repot-go"]` or `staticTexts["Repot Daisy"]` instead of `staticTexts["Pick a pot"]`. Also tap `pot-new-close` and assert the pill and the `New` tags are gone (`!line.exists`), then reopen and assert it is still gone.
2. **New: `testRepotTilesHaveOneHeightAndClearTheButton`.** Run it at default size, `AccessibilityL` and `AccessibilityXXXL`:
   - All 16 `pot-tile-*` frames have the same height (±0.5).
   - The rows are aligned (keep `assertFourByFour`).
   - At default size, every tile's `maxY` is ≤ `repot-go.frame.minY` minus the summary height. In other words, there is no scroll needed for the grid, on iPhone 17.
   - At AX sizes, swipe up until `pot-tile-meadow` is hittable, and assert `meadow.frame.maxY <= repot-go.frame.minY`. This checks the inset, and it is the "Honey stripe" regression.
3. **New: `testTappingAPotToEarnShowsItsGoalAboveTheButton`.** Tap `pot-tile-livingStones`. Assert that `pot-hint` exists, that its frame is above `repot-go` and below the last tile, and that its label contains "Finish level 3" and "Four more plants to go!". Assert that the `repot-go` label still names the picked pot.
4. `testPotScreensPartWayUpTheLadder`: the hint assertion stays as it is. Add a shot after `pot-tile-moonlit` is tapped. Compare the shots with `design-preview/repot-sheet/shots/a-light`, `b-light`, `c-dark` and `d-light`.
5. `testThePotPickerPassesTheAuditAtAccessibilityTextSizes`:
   - Keep `assertFourByFour`.
   - The `visible` rect logic already clips at `repot-go.minY`. Change it to clip at the footer's top: use `repot-summary` or `pot-hint`, whichever exists, `minY - 28` for the fade, so faded text is not judged for contrast.
   - The tile contrast excuse can narrow to the pot art only, because names are now full ink on every tile. Try dropping it for `.contrast` first. Keep the `.dynamicType` excuse, since the names are still capped at xxxLarge.
6. Existing label tests (`"Fly-trap pot, not earned yet"`, `"Terracotta pot, in use"`, `"Blossom pot"`): these keep passing, with one exception. Blossom will read `"Blossom pot, new"` on the first opening in the `-uitest-pots` fixture. Either assert `hasPrefix("Blossom pot")`, or close the pill first.
7. Unit (`PotCatalogTests`): the CopySafety sweep covers the new strings. Add a `summaryLine(pot:soil:)` helper in `PotCatalog` and test it ("Rose pink pot, fresh loam soil"). `recordEarnedPots()` now returns the new ids; update the record-once test.

## Open points
1. If the plant-in-pot thumb is costly to compose, ship a plain 40pt `PotArtView` of the picked pot first.
2. The soil colour dots are art colours. The real hex values should come from the existing soil art in `TendEffect`/repot animation if there is one.
3. iPhone SE (667pt tall): the 4th row sits under the fade at default size. The fade and inset still keep it reachable. The test in step 2 asserts "no scroll" for iPhone 17 only.

## Critic (one round, Sonnet subagent, reviewed the six PNGs plus the simulator shot)
**Verdict: ship with fixes.** It found that the structure meets the brief: a compact header, 4 x 4 held at AX sizes, silhouettes with goals and no locks, a Plus pill with no price, and a 52pt pinned button.

Fixes taken in the revision (the shots are re-rendered):
- **Tapped vs picked looked alike.** The tapped tile now has a double ink outline on a surface fill, and the footer hint shows the same pot art.
- **"In use" read like a goal line.** It is now an outlined pill with a check.
- **The AX header took about 40% of the screen.** The header, the new pill and the summary are capped at `.accessibility1`. Frame D now shows almost all 16 tiles.
- **Footer spacing** went from 8 to 10pt.
- **Peaty and Compost dots looked alike.** The soil colours now differ clearly.

Fixes declined, with reasons:
- *Contrast concerns* (goal text, dark Plus, dark "In use", soil subline). The critic estimated these from pixels. Computed values are all ≥ 5.1:1 (table above). Text under the 28pt fade is excluded on purpose, and the audit's visible rect is to clip at the fade (Tests 5).
- *Two-line names at AX.* Two-line names are what made the rows uneven. One line with `minimumScaleFactor(0.6)` keeps the rows even, and VoiceOver reads the full name.
- *Goal lines at AX.* Kept hidden on the tile at AX sizes. They show in the footer hint on tap and in the accessibility value.
- *Solid header when scrolled.* This is standard sheet behaviour (the grabber floats). It needs no change.
- *The "Reduce Motion" tag* is only an annotation on the mockup.

# Visitors page and Visitors' book: visual and UX review (2026-11-07)

Read-only review: source, the b02-fid screenshots (Visitors page light, dark, AX5) and the specs
(docs/pm/badge-mechanics-art.md, butterfly-net-spec.md, handoff-shed-visitors.md). No build, no simulator. Text
widths were estimated from Apple's Dynamic Type table and SF Rounded glyph widths, calibrated against the AX5
screenshot ("Ladybug" at subheadline semibold AX5 measures about 189 pt). Contrast was computed from the colour
assets (WCAG relative luminance, opacities blended over the real backgrounds).

Files: `WordFlora/Views/ButterflyView.swift` (VisitorsView, album cards, VisitorDetailSheet, RarityChip),
`WordFlora/Views/VisitorsBookView.swift`, `WordFlora/Views/FieldNotesPage.swift`, copy in
`WordFlora/Rules/Butterfly.swift` (VisitorsCopy), `WordFlora/Rules/FieldNotesCopy.swift`, `WordFlora/Rules/Endgame.swift`.

Bugs only, ranked by severity. Each has a minimal fix; no new features.

## High

### V1. Play card: "Easier butterflies" and friend-of-the-day names break mid-word at accessibility sizes
`ButterflyView.swift:546-571` (playCard), `:579-593` (easierSwitch), `:566` (friend of the day).
The 60 pt monarch stays beside the text at every size, so the text column is about 255 pt on a 393 pt phone
(393 - 2x16 gutter - 2x16 card - 60 - 14) and 237 pt on a 375 pt phone.
- Friend of the day uses `.subheadline` semibold (49 pt at AX5). "Hummingbird" (about 300 pt), "Swallowtail" and
  "Bumblebee" (about 250-290 pt) do not fit 255 pt at AX5; "Hummingbird" breaks from AX4 on 375 pt. All three are in
  the daytime pool, so any child at AX4-AX5 will see it some days.
- The Toggle puts the label beside a 51 pt switch, leaving about 195 pt: "butterflies" (about 220 pt at AX3, 300 pt at
  AX5) breaks mid-word from AX3. The footnote's "butterflies:" breaks at AX5 too.
Fix (same pattern as HomeView `dailyBloom`, HomeView.swift:350): at `typeSize.isAccessibilitySize` use a
`VStackLayout(alignment: .leading)` for the image + text row so the image sits above the text (column about 321 pt),
and in `easierSwitch` at accessibility sizes show the label `Text` on its own line with the `Toggle` below it using
`.labelsHidden()` plus `.accessibilityLabel(VisitorsCopy.easierToggle)`.

### V2. Field Notes page: "Hummingbird" breaks mid-word at AX5 (and from AX4 on small phones)
`FieldNotesPage.swift:131-132`, padding at `:151`.
The name is `.title3` rounded bold (55 pt at AX5, about 335 pt for "Hummingbird"). The text column is 393 - 32 - 34
- 18 = 309 pt (291 pt on 375 pt phones, where AX4's 299 pt also overflows). Other names fit.
Fix: at accessibility sizes (`large`) drop the paper padding to leading 26 / trailing 14 (the spine is 18 pt, holes at
9 pt, so 26 still clears them) and set the name to `.subheadline` bold (49 pt, about 299 pt: fits 321 pt and 303 pt).
Design call made here: the name then reads smaller than the `.body` fact at AX sizes; it stays bold and first, which
keeps the hierarchy readable. Escalate to Fable only if that is not acceptable.

### V3. Visitor detail sheet title: "Hummingbird" breaks mid-word at AX5
`ButterflyView.swift:701` and `:725`. `.title` bold is 58 pt at AX5 (about 354 pt); the sheet allows 393 - 48 = 345 pt
(327 pt on 375).
Fix: at accessibility sizes use `.title3` bold and horizontal padding 16 instead of 24 (about 335 pt in 361 / 343 pt).

### V4. Weather sticker names break mid-word in the Visitors' book
`VisitorsBookView.swift:41` (`cols = isAccessibilitySize ? 2 : 4`), name at `:48`.
- 4 columns: each cell is about 81 pt (77 pt on 375). "Snowflake" in `.footnote` semibold is about 87 pt at xxxLarge
  (and 78 pt at xxLarge on 375), so it breaks before any accessibility size.
- 2 columns at AX: cells are about 174 pt; "Snowflake" is about 175 pt at AX4 and 203 pt at AX5; "Ladybird" is about
  173 pt at AX5.
Fix: `let cols = typeSize >= .accessibility4 ? 1 : (typeSize.isAccessibilitySize ? 2 : (typeSize >= .xxLarge ? 3 : 4))`.

## Medium

### V5. "Met on <date>" shows the most recent meeting, not the first
`VisitorsBookView.swift:129` passes `album.lastSeen(of:)`; `StickerAlbum.seenAt` keeps the latest date
(`Butterfly.swift`, `add(_:on:)` and `merged(with:)` take the max). So "Met on 4 Nov" moves forward every time the
child meets the friend again, which reads as wrong to a child who met it last week. The spec
(badge-mechanics-art.md:53, :117) assumed seenAt was the first meeting.
Fix (copy only, no data change): `FieldNotesCopy.metOn` becomes "Seen on \(date)", matching the album's "Seen today"
wording ("Last met on" is out: CopySafety bans "last"). Update `pageLabel`, the spec lines and the `all` sample. A real first-met date needs a new stored field and is a 1.1 backlog idea, not a fix.

### V6. Common rarity chip text is below 4.5:1
`ButterflyView.swift:679-681` (RarityChip). "Often seen" in `.caption` bold, successText on its own 14% wash:
4.26:1 light on a met card, 4.11:1 light on an unmet card, 4.34:1 dark on a met card. Uncommon and rare pass
(4.79-5.56:1). The chip is also used on the detail sheet.
Fix: `.background(tint.opacity(0.06), in: Capsule())`. Measured: common 4.73 / 4.57 light, 5.09 / 5.68 dark; the
other tints rise too.

### V7. VoiceOver page label reads "Met on ." for friends met before dates were stored
`FieldNotesPage.swift:156` passes `metOn ?? ""`; `FieldNotesCopy.pageLabel` (`FieldNotesCopy.swift:31-33`) always
inserts "Met on \(met).". Albums from before `seenAt` existed have counts but no dates (Butterfly.swift, StickerAlbum
comment), so VoiceOver says "Monarch. Met on . Monarch butterflies...". The visible page already hides the line.
Fix: make `met` a `String?` in `pageLabel` and include the met sentence only when it is non-nil; pass `metOn`
directly.

### V8. Unmet album cards drop the "Comes out in the evening" hint for VoiceOver
`ButterflyView.swift:646-647` with `VisitorsCopy.cardLabel` (`Butterfly.swift:178-181`). The card ignores its children
and the unmet label is only "Not met yet, sometimes seen". The visible line "Comes out in the evening" / "Say hello
in the game" (`:632`) is lost, so a VoiceOver child never learns the firefly and luna moth come at night.
Fix: append `notMetHint(nightOnly:)` to the unmet branch of `cardLabel` (add a `nightOnly` parameter) and pass
`v.nightOnly` at `:647`.

## Low

### V9. Unmet card's dashed outline is under 3:1
`ButterflyView.swift:641`: appPrimaryText at 30% is 1.75:1 light, 2.31:1 dark against the card's surroundings. The
dashed edge is the only shape of a tappable card (the text inside does identify it, so this is not a hard failure).
Fix: opacity 0.3 to 0.55, the same level the puzzle uses for blank tiles (`PuzzleInk.blankOutline`, at least 3:1).

### V10. Ring number overflows the 62 pt ring at accessibility sizes
`ButterflyView.swift:513-516`: the count is `.title3` bold (55 pt at AX5) inside a fixed 62 pt ring; "12" is about
66 pt wide and runs over the purple arc (see the AX5 shot, where "3" already fills the ring). Fix: size the ring with
`@ScaledMetric(relativeTo: .title3) var ring: CGFloat = 62` (frame and 9 pt line can stay), so the ring grows with the
digits.

### V11. Section header tracking differs from the Shed
Visitors "ALBUM" uses tracking 1.5 (`ButterflyView.swift:482`), the book 1.4 (`VisitorsBookView.swift:119`), the Shed
1.2 (`ShedView.swift:53`). Fix: use 1.2 in both Visitors headers.

## Checked and fine
- Tap targets: album cards (min 190 pt), Visitors' book button, Listen / I read it! (52 pt), Say hello and Done
  (56 pt), system Toggle. All at least 44 pt.
- Contrast passes: secondary text on unmet cards 7.7 / 8.4:1; Field Notes ink 7.2:1 light, 7.9:1 on the dimmed dark
  paper, "Met on" at 85% 5.0 / 5.5:1; successText on surface 5.1 / 5.7:1; Fun fact accentText 5.5 / 6.8:1; secondary
  on the lilac met card 6.8 / 7.1:1; ring arc 5.6 / 6.0:1 (track is decorative, the line beside says the count).
- Album at xxxLarge (2 columns, about 150 pt of text): the longest name "Hummingbird" is about 140 pt; fits. At AX
  sizes the album goes to one column.
- No locks anywhere: unmet friends are soft grey outlines, pages say "A new friend". Tone is calm and positive.
- CopySafety: no banned word in VisitorsCopy, FieldNotesCopy, the book lines or the twelve facts.
- VoiceOver order: count card, play card, info row, book button, Album header, cards. Book: header, page count,
  then each page followed by its buttons. Headers carry `.isHeader` and spoken (not upper-case) labels. Weather
  sticker cells expose the image's label once.
- Empty state (0 met): ring at 0, twelve "A new friend" pages; nothing breaks.

## For the 1.1 backlog (ideas, not fixes)
- Store a first-met date (`StickerAlbum.firstSeenAt`, merged by min) so the page can truly say "Met on".
- A Stop state for Listen while reading (today the label stays "Listen" and a second tap restarts).

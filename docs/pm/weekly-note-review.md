# Weekly garden note: visual and interaction review

Reviewed read-only (no build): `WordFlora/Components/WeeklyNoteCard.swift`, `WordFlora/Rules/WeeklyNote.swift`,
`WordFlora/App/AppModel+WeeklyNote.swift`, the Home slot in `WordFlora/Views/HomeView.swift`, the weekly note cases in
`WordFloraUITests/EngagementUITests.swift`, and the HTML mock (light, dark, Quiet Garden, large text, two splashes).
Commits 44270c8, 1821c82, f7638c4, 30ba924, d798a28.

## Verdict

Ship with fixes 1 to 4 below (each a few lines). 5 to 8 are optional polish.

The owner's asks are met: Celebrate and Share my week sit below the card, there is no Lovely or Visit my garden, no emoji
and no generic flower (the plant tiles and the splash use `PlantCollectible.imageName` art, with a daisy only when the
garden has nothing), metrics are centred hero tiles with a big number, a small label and a soft tint. Copy is right for
both audiences: "What a week!" / "Your garden grew with you." is warm without being babyish; the labels ("words grown",
"friends said hello") and the three closing lines read calm and plain. Home shows one card at a time (quest and Plus
card wait on a note visit), and the "note stays until the next Home visit" rule holds: seen after 1.5 s on screen or on
Celebrate, dropped only when another screen opens over Home, so Done on the splash keeps the note for Share.

## What checks out

- Contrast (computed from the asset catalogue). Full ink on every tint is well above 4.5:1 in both modes: light 9.8 /
  9.9 / 9.8 / 9.3 (header green, rose, words, friends), dark 10.0 / 9.4 / 7.4 / 8.6. Celebrate button text on green
  5.1:1 light, 7.2:1 dark. The leaf (successText) on the header wash is 4.4:1 light but sits in a white circle, so fine.
- Tap targets: Celebrate and Share are `minTap + 8` = 52 pt tall; Done uses the primary style. All above 44 pt.
- VoiceOver: the card is one element (title, each tile's sentence, closing line), then Celebrate (with hint), then Share
  (with hint), then Play. Tile numbers are not separate stops. Plant art is hidden from VoiceOver. Sensible order.
- Large text: the tile row and the action row switch to stacks at accessibility sizes, the leaf drops out, art scales
  with `.title`. Nothing clips in the mock at the stacked size.
- Geometry at 393 pt: card 361 wide, three tiles of about 106 pt each. "friends said hello" wraps to two lines at
  footnote, which is fine; tiles are equal height thanks to `fixedSize` on the row and `maxHeight: .infinity` per tile.
- Reduce Motion and Calm mode: the splash uses `CelebrationBurst`, which already handles both; one soft haptic.

## Fixes, ranked

1. **Splash composition with one or two plants.** `WeeklyNoteCard.swift:168-172` makes index 1 the large plant, so a
   single plant renders at 78% and two plants render small-left, large-right (the mock's light splash shows exactly
   this lopsided pair). Scale by count: three plants, middle large; two plants, both equal (about 0.88); one plant, full
   size. Minimal change: `let n = min(art.count, 3)` and
   `let s = n == 3 ? (i == 1 ? 1 : 0.78) : (n == 2 ? 0.88 : 1)`, then `size * s` for width and height.

2. **Splash content is top-aligned, not centred.** `WeeklyNoteCard.swift:165-193`: a `ScrollView` does not centre its
   content, so on a 6.1" phone the plants, title and Done sit in the top half with an empty lower half, while the petal
   burst starts 120 pt from the top. Wrap in `GeometryReader { g in ScrollView { VStack... .frame(maxWidth: .infinity,
   minHeight: g.size.height) } }` so default text centres and accessibility sizes still scroll.

3. **Share my week pops in and shifts Celebrate.** `WeeklyNoteCard.swift:117-131`: the share image renders in
   `onAppear`, so for one frame Celebrate is full width, then shrinks to half when Share appears. Reserve the slot: when
   `canShare` and `shareImage == nil`, show `Color.clear.frame(maxWidth: .infinity, minHeight: Theme.minTap + 8)` in
   the `else` branch (or render the image in `init`).

4. **Plant art in the tile is too small.** `WeeklyNoteCard.swift:15` and `68-70`: 30 pt for a 200 px asset that has
   transparent margins leaves roughly 22 pt of visible plant, which reads as a smudge next to a 28 pt number. Raise
   `artSize` to 36 and the overlap to `-artSize * 0.3` (three plants still fit in the 90 pt tile). In Quiet Garden the
   tile has no number, so the art is the hero: use `artSize * 1.6` when `t.number == nil` and bump that label to
   `.subheadline` at line 79. The mock's Quiet variant looks like a sparse band; this fills it.

5. **Closing line weight.** `WeeklyNoteCard.swift:53`: title3 bold over subheadline semibold is two bold lines in the
   header. Full ink is already 9.8:1, so the weight buys nothing; drop to `.subheadline` regular for a calmer header
   that lets the title lead.

6. **Tiles fade into the card in dark mode.** Luminance ratio of rose and lilac tints to the dark surface is 1.02 and
   1.06 (hue alone separates them). Add a hairline at line 85:
   `.overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.appPrimaryText.opacity(0.08)))`.
   Light mode is fine (1.16 to 1.23 plus the white surface).

7. **A week with one tile.** When only one metric is non-zero the single tile stretches to 337 pt with a lone number in
   the middle, which looks like an empty band. In the `layout` at lines 24-27, when `tiles.count == 1` give the tile
   `.frame(maxWidth: 200)` and centre it (`frame(maxWidth: .infinity)` on the row).

8. **Share card and note disagree on Daily Blooms.** `WeeklyNote.swift:160-168` (share rows) lists "You solved 2 Daily
   Blooms." while the card's tiles (lines 186-198) fold them into words. Either is fine; if the share card should match
   the note, drop the daily row from `rows` outside Quiet Garden or add a note comment that the share card is the
   fuller version. Low priority.

## Notes for the mock

The mock matches the Swift closely (same tints, 28 px numbers, 13 px labels, 30 px art, 52 px actions). Two things it
hides: the splash in the mock is flex-centred, which the real `ScrollView` is not (fix 2), and the mock's Share button is
always present, so the pop-in in fix 3 does not show there.

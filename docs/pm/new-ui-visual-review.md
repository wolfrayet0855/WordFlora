# New UI visual review (three builder branches)

Read-only review, 2026-11-07. I did not build or use a simulator. Evidence: the SwiftUI source in each worktree, the
text-fit shots (`docs/pm/shots/textfit/` and the builder's i17 set), the QuickLook renders of the Frost & Lantern SVGs,
and the specs `plus-flow-fable-review.md`, `celebration-and-love-review.md`, `frost-lantern-snow-and-plant-review.md`,
`engagement-quick-wins.md` and `textfit-builder-brief.md`.

Branches:
- **TF**: `agent-a2bea51afc81e7059` (text fit, Plus flow, Settings Purchases, iCloud row, Plus is on)
- **P2**: `agent-a0f8716ff1989be39` (polish pass 2)
- **EN**: `agent-aabade169b9af62f9` (engagement)

**No merge blockers.** Every text pairing I checked passes 4.5:1, every non-text pairing passes 3:1, and none of the new
views caps Dynamic Type or uses ViewThatFits. P2 and EN both edit the win card in `GameView.swift`, but in separate
hunks: EN adds lines in the plant branch and in `shareButton`, and P2 edits the no-plant branch and the button row. Merge
P2 first, then rebase EN. `WordFloraUITests.swift` is touched by TF and P2.

## Contrast (computed, WCAG relative luminance)

| Pair | Light | Dark |
|---|---|---|
| successText on appSurface (weekly closing line, "Plus is on", "One more word…") | 5.13 | 5.69 |
| successText on appBackground | 4.79 | 7.20 |
| accentText on appSurface ("Share my week") | 5.93 | 6.77 |
| secondaryText (88% ink) on surface / background (plan "Yearly", footnotes) | 7.96 / 7.54 | 7.54 / 9.35 |
| "Best value" badge ink on appAccent 30% | 9.27 | 4.81 |
| Choice circle and pip outline, ink 55% on surface (non-text) | 3.10 | 3.98 |
| Words-to-plant pip fill, LifePalette.leaf on surface (non-text) | 3.87 | 6.87 |
| Hello toast tick, toastTick on toast slab (non-text) | 6.00 | 4.12 |
| Snow flake #8FA9C4 on appBackground (decorative, exempt) | 2.27 | 13+ |

The card edge strokes (ink at 12%) come out at 1.2 to 1.7:1. They are decorative and match the existing Home cards. Each
button is identified by its own label and fill, so this passes.

## Per-surface verdicts

| Surface | Branch | Verdict | Notes |
|---|---|---|---|
| Plus page, buying (default, AX5, dark) | TF | ok | Clear hierarchy: flower, title, three benefits, three choice cards, one primary button, fine print. At AX5 the title breaks "WordFlora / Plus" as whole words, and the badge drops under "Yearly". Footer links use `tapTarget()` (44 pt). |
| Plus page, loading / failed | TF | ok | No dead button while loading, and failed has one card plus Try again. Calm. |
| Plus page, owned / Plus is on | TF | ok | One card, a plan line, the spring falls back to a fade under Reduce Motion, plus a haptic and an announcement. The "charged twice" note is plain and has one button. The committed shots `plus-owned-*` still show the removed "Restore purchases" link, so retake them (no code change). |
| Settings, Purchases section | TF | small fix | (1) The section header is styled by hand (footnote semibold), so it renders smaller and lighter than "Garden" and "Your garden" (see `settings-plus-signin`). (2) "Manage subscription" has no icon, so its text starts left of the other rows' text. (3) The iCloud footnote starts at the row edge, not under the label's text. |
| iCloud status row | TF | small fix | Good states and copy. "iCloud sync is off (needs Plus)" is the one line here with a sales tone, and kids see it too. Fix the alignment as in (3). |
| Grown-up sheet | TF | ok | The title steps down at AX4+, the sheet scrolls, and the wrong-answer line uses ink plus an icon, not red. |
| Win card, no plant (pips, Next word, Tend my garden) | P2 | small fix | Pips are leaf green and hidden from VoiceOver. Reduce Motion cross-fades, Calm and Quiet Garden settle without a bounce. On the word before a plant, though, the card says the progress twice in a row: "2 of 3 words to your next plant." and then "One more word and a new plant arrives!". With the pips that makes three signals, which is the clutter the owner flagged. |
| Win card, Daily Bloom | P2 + EN | small fix | It shows Share (secondary, 13+), Continue (primary) and Tend my garden (secondary): three stacked buttons. That is acceptable, but this is the busiest card in the app. |
| Win card, new plant ("Give it a name") | EN | ok | It is optional, appears once, and leads to the alert, then one hello line that is also announced. For 13+ there are two secondary buttons (Give it a name, Share this plant) above Continue. Acceptable. |
| Snow on pack card and plant page | P2 | ok | Behind and in front of the plant. Calm halves it, Reduce Motion, the app switch and Low Power draw one still frame, Quiet Garden has none, and it pauses off screen and in the background. Hidden from VoiceOver and takes no taps. |
| Snowdrop art | P2 | ok | Stands upright, and the bells nod outward. No longer reads as droopy. Colours unchanged. |
| Hello toast tick | P2 | ok | Now visible in dark mode (4.12:1) and scales with the text. |
| "Some energy" | P2 | ok | Calmer than "Hellos help", and there is no lives framing. |
| Weekly garden note (Home) | EN | needs work (one line) | The card itself is fine: note-card style, rows wrap, buttons stack at AX sizes, the leaf drops at AX sizes, and share is limited to 13+ and off in Quiet Garden. However, the daily quest card still shows under Play on the same visit, so Home has two cards. Smaller issue: the whole paragraph carries the header trait. |
| "Show on my widget" / "On your widget" | EN | ok | One full-width secondary button. Once pinned it becomes a plain line with a check, and the follow-up line is announced. It adds one more full-width block to a long plant page, which is acceptable. |
| Share gate | EN | ok | Share is hidden, not disabled, under 13. Nothing replaces it, so the layout does not jump. |

## Ranked fixes

1. **EN: one card at a time on Home.** `WordFlora/Views/HomeView.swift:148`: change
   `if let quest = app.dailyQuest(stats: stats) {` to `if weeklyNote == nil, let quest = app.dailyQuest(stats: stats) {`.
   The quest card returns on the next Home visit, after Lovely or Visit my garden.
2. **TF: Purchases header matches the other sections.** `WordFlora/Views/SettingsView.swift:130`: replace the custom
   `header:` Text with the plain `Section(PlusEntry.purchasesTitle) { … }`, like `Section("Garden")` at :75. A plain
   string header wraps at every size and is a header for VoiceOver already.
3. **P2: one progress sentence on the word before a plant.** `WordFlora/Views/GameView.swift:354` (P2): show `nextLine`
   *instead of* the `winLine` count line when it is non-nil (`if let next … { Text(next) } else { Text(winLine) }`),
   not under it. The pips already show the count. This is a taste call against the celebration review, so ask Fable
   via the lead before changing it.
4. **TF: Manage subscription lines up with its siblings.** `WordFlora/Views/SettingsView.swift:123`: give the row an
   icon, for example an optional `systemImage` on `GatedLink` that renders `Label(title, systemImage:)`, with
   `"creditcard"`. The Plus page footer keeps the plain text form.
5. **TF: iCloud footnote under the label text.** `WordFlora/Views/SettingsView.swift:200`: build the row as an
   `HStack(alignment: .firstTextBaseline)` with the icon on the left and the title, synced line and footnote stacked to
   its right. Alternatively, pad the footnote leading by the icon width, using `@ScaledMetric` so it scales.
6. **TF: softer free-state iCloud line.** Change `CloudSyncStatus` "iCloud sync is off (needs Plus)" to "iCloud sync
   comes with Plus". It is calmer, has no parenthesis, and passes CopySafety.
7. **EN: VoiceOver header only on the title.** `WordFlora/Components/WeeklyNoteCard.swift:70`: drop
   `.accessibilityAddTraits(.isHeader)` from the combined paragraph. The card is already its own container, and the
   spec only asked for the title to be the header. Marking the whole paragraph as a header makes the rotor list a
   five-sentence heading.
8. **TF: retake the stale Plus shots** (`docs/pm/shots/textfit/plus-owned-*.png`). They still show "Restore purchases"
   on the Plus page, which commit be453dd removed. Docs only.

## Notes for the lead

- Restore purchases now lives only in Settings > Purchases. App Review accepts a restore button anywhere in the app,
  and this is the owner's call (2026-11-07). Still, a player who opens the Plus page from the Home offer card sees no
  way to restore there. If review asks, the fix is one footnote link on the Plus page. I am not proposing it now.
- The P2 snow shows in Calm mode at half the count. That follows the frost-lantern spec, which says "It stays on".

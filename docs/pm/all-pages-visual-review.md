# All pages visual review (2026-11-07, polish pass, read-only)

Scope: every screen, judged as a 1.0 polish pass (hierarchy, spacing, type, colour, icons, tone, empty and error
states, clutter, anything a reviewer or parent would flag). Inputs: `WordFlora/Views/*.swift` and `Components/`,
the newest screenshots per screen (light, dark, AX sizes) under the session scratchpad `shots/` (b01 to c12,
puzzle-after2), `design-preview/`, and the reviews already written: `toolbar-fit-review.md`, `visitors-book-review.md`,
`weak-spots-review-2.md`, `plus-page-review.md`. No build, no simulator. Line numbers are the main checkout
(`3-feat-content-and-polish`, 4527b82) unless marked G3 (the tend bar is being rebuilt there).

Owner's rule applied throughout: every word fits at every text size; no caps (`lineLimit` that truncates,
`minimumScaleFactor`, `dynamicTypeSize` clamps), no `ViewThatFits`, text styles only.

The app reads as one calm, warm product. The brand (cream, deep green, amber, rounded type) is consistent on almost
every screen, dark mode is handled everywhere, copy is kind and honest, and there are no locks, timers or pressure in
kid-facing surfaces. What is left is mostly four grid screens that still break words at accessibility sizes, a
handful of caps the rule forbids, and small consistency nits.

## 1. Per-screen verdicts

| Screen | Verdict | One line |
|---|---|---|
| Onboarding (age, first tip) | ok | Clean at L, dark and AX5. Only a copy nit ("first drink is free"). |
| Home (new, open, early locks) | ok | Hierarchy right; locked tiles are soft (dashed, "Opens when..."). Hero carries four lines at once (small). |
| Garden | needs work | 2 columns at every size: "peren-nis" hyphenates at AX5; sparkle overlaps the silhouette. |
| Plant detail (hero, name card, Life panel) | small fix | Lovely. Toast covers the card title; "+3 growth" is jargon; AX sheet grabber does nothing. |
| Tend bar (six buttons) | in flight (G3) | Covered by `toolbar-fit-review.md`; 4-tile states look right. Keep the 3+3 rows ruling. |
| Shed (tools, points, scene) | ok | Warm and consistent; tool tiles go one column at AX cleanly. |
| Shed pots grid | needs work | `dynamicTypeSize(...xxxLarge)` cap, 4 columns at all sizes, shrink-to-fit names. |
| Seasons shelf (`PackPotsRow`) | not in build | No shots; one pot per row, safe per the earlier review. |
| Game (puzzle, keyboard) | ok | Calm, legible, long words handled. Single-glyph shrink on keys and tiles is acceptable (section 4). |
| Win, rest, break, resting cards | small fix | Card titles render system black while the body is brand green; otherwise excellent copy. |
| Celebration (petals, intro bloom, badge moment) | ok | Scales by setting; reduce-motion variant is a quiet sprinkle. |
| Level map | ok | Best-looking screen in the app, light and dark. One AX nit (trail stub above the card). |
| Calm / Quiet Garden offer | ok | Two equal choices, "change any time in Settings". Quiet shed tool sheet is 75% empty. |
| Weather banner, forecast, puzzle, plant looks | small fix | Honest copy, art drops at AX5 cleanly. Light-mode overlays nearly invisible; dark haze panel edge. |
| Wake puzzle and wake sheet | small fix | Wake sheet is excellent. Puzzle inherits `.large` and sits half empty. |
| Badges grid and detail | needs work | 2 columns at AX5: "Plant Col-lector", "collec-tion". Detail and share card fine. |
| Visitors page, Visitors' book, Field Notes | reviewed | See `visitors-book-review.md` (V1 to V11); nothing to add. |
| Butterfly game | needs work | Nav title is near-black on the navy evening sky (contrast). Reward row is bare icons. |
| Guide (8 pages) | small fix | Charming; AX body text hard-clips under the dots with no scroll cue. |
| Plus page | reviewed | See `plus-page-review.md` and section 3 below. |
| Pot picker / Repot sheet | needs work | Pot tiles, goal line and soil chips all shrink or cap; `ViewThatFits` on two headers. |
| Grand garden | small fix | Crown label capsule can't hold four lines at AX5. |
| Settings | ok, one check | System Form (grey) is the one off-brand screen; Theme segmented picker at AX unverified. |
| Parental gate | small fix | `.medium` sheet with no ScrollView: overflows at AX (code review; no shot). |
| Daily Bloom row and quest card | ok | Wraps at AX5; "0 of 1" counter reads oddly for a one-step quest. |

## 2. Ranked fix list

Tag: **T** = belongs in the text-fit pass (same builder session, same test pattern); **L** = later polish, after
the pass or in 1.1. Only quick, low-risk changes are proposed for 1.0.

### High

1. **T** Garden grid breaks words at AX. `Views/GardenView.swift:22-31`: `Grid` of two `tile()` per `GridRow` at every
   size; `fid-garden-ax5.png` shows "peren-nis" and the sparkle drawn over the plant silhouette. Fix: read
   `@Environment(\.dynamicTypeSize)` and stride by 1 (one tile per row) when `isAccessibilitySize`. Same measured risk
   as toolbar-fit-review section 7 ("Passionflower", "Snapdragon" at AX1 and up).
2. **T** Badges grid, same bug. `Views/BadgesView.swift:21-28`; `fid-badges-ax5.png` shows "Plant Col-lector" and
   "collec-tion". Fix: one `card()` per `GridRow` when `isAccessibilitySize`.
3. **T** Shed pot cards carry a Dynamic Type cap and shrink-to-fit names. `Views/PotPickerViews.swift:673`
   (`.dynamicTypeSize(...DynamicTypeSize.xxxLarge)`), `:656` (`lineLimit` + `minimumScaleFactor(0.5)`), `:595`
   (`PotCatalog.gridColumns`, a constant 4). `shed-pots-AccessibilityL.png` and `-XXXL.png` are pixel-identical while the
   footer under them grows. Fix: drop the cap and the limits; make the column count size-dependent (4 up to L, 2 above L,
   1 at AX), ideally one helper shared with the Repot grid and the Visitors' book (V4).
4. **T** Repot sheet tiles, goal line and soil chips. `PotPickerViews.swift:332` (name, `minimumScaleFactor(0.6)`),
   `:341` and `:350` (goal line `0.75` and the `...xxxLarge` cap), `:439` (soil chip `0.8`; "Compost" already touches the
   chip edge at default in `repot-e-light.png`). `repot-a-axl.png` shows "Living stones" and "Rainbow bark" visibly
   smaller than their neighbours. Fix: same column helper as item 3 (soil chips 2 columns above L); remove the limits.
5. **T** Butterfly game title has no contrast on the evening sky. `Views/ButterflyView.swift:54-59`: the bar colour
   follows `colorScheme`, so in light mode a near-black "Butterfly game" sits on the navy evening sky
   (`butterfly-playing.png`, `butterfly-calm.png`; about 2:1). Fix: when the scene is evening, use the navy bar and
   `.toolbarColorScheme(.dark, for: .navigationBar)`; otherwise unchanged.
6. **T** Parental gate sheet cannot scroll. `Views/PlusView.swift:229-241` (`ParentalGateSheet`): fixed `VStack` in
   `.presentationDetents([.medium])`. At AX the Continue and Cancel buttons leave the sheet. Fix: `ScrollView`,
   `.fixedSize(horizontal: false, vertical: true)` on the three Texts, and `[.large]` when `isAccessibilitySize`. (Plus
   review finding 2; it gates every purchase, redeem and outbound link for under-13, so it is a 1.0 item.)

### Medium

7. **T** `ViewThatFits` still in four places (rule says none). `Views/PotPickerViews.swift:411` (Soil header), `:597`
   (Pots header), `Views/PlantDetailView.swift:506` (resource chips), `Components/NameStoryCard.swift:137` (origin
   chips). Fix: `AnyLayout(isAccessibilitySize ? VStackLayout(alignment: .leading) : HStackLayout())`, the pattern already
   used in `ShedView.swift:19` and `HomeView.swift:350`.
8. **T** Remaining caps outside the tend bar. `Views/ShedTools.swift:199` (`lineLimit(typeSize.isAccessibilitySize ?
   nil : 2)` on the effect line; drop it), `Views/GameView.swift:156` (`lineLimit(2)` on the top-bar title; drop it, the
   bar already wraps), `PotPickerViews.swift:26, 40, 242, 259, 271` (Plus / New / In-use tags pinned at `.large`; at AX5
   they are tiny under huge names, `pot-pick-AccessibilityXXXL.png`). The Plus tag carries a word, so under a literal
   reading of the rule it must scale or hide at AX; the "A Plus pot" line already says it, so hide at AX is the cheap fix.
9. **T** Grand garden crown label. `Views/GrandGardenViews.swift:194-198`: `Capsule` background and stroke around text
   that wraps to four lines at AX5 (`fid-grand-ax5.png`); the sparkle and "earned" sit on the stroke. Fix:
   `RoundedRectangle(cornerRadius: 22, style: .continuous)` and `.multilineTextAlignment(.center)`.
10. **T** Settings Theme picker. `Views/SettingsView.swift:71-75`: `.segmented` with System / Light / Dark. Segments
    stop scaling or truncate at AX (toolbar-fit-review section 7; no AX shot of that section exists). Fix: `.inline`
    (or `.menu`) when `isAccessibilitySize`, segmented otherwise; one `if`, no `AnyView`.
11. **T** Guide body clips under the dots at AX. `Views/GuideView.swift:48` (`.clipped()` on the pager) with the page
    `ScrollView` at `:249-279`. `guide-ax-p1..p8.png` cut lines mid-glyph ("to fill in the"). It scrolls, but nothing
    says so. Fix: `.scrollIndicators(.visible)` on the page ScrollView plus a 24 pt bottom fade (`.mask` with a
    `LinearGradient` to clear) instead of the hard clip. The fixed `.system(size:)` fonts inside `GuideArtCard`
    (`:399-873`) are a drawn illustration (`accessibilityElement(children: .ignore)`, labelled): ruled acceptable as a
    picture, see section 4.
12. **L** Card titles render system black, not brand green. `Views/GameView.swift:287, 298, 318, 325` ("This one's
    resting", "New plant found!", "Your garden grew", win title) have no `foregroundStyle`; `cardTitle()` at `:450-451`
    does. Visible in `word-toward-plant.png`, `plant-earned.png`, `resting.png`. Fix: route all four through
    `cardTitle(_:)`. Nav titles ("My Garden", "Daisy", "Badges") are also system label colour; acceptable, note only.
13. **L** Rest and break cards at AX: `break-axl-top/bottom.png` and `rest-ad-axl-*.png` show "Keep playing" / "Go
    ad-free" cut at the screen edge; the card is in a ScrollView so it should scroll, but confirm once in the text-fit
    sim run; if it does not, drop `minHeight: geo.size.height` at AX (`Views/GameView.swift:486-495`).
14. **L** Dark hot-day forecast card shows a lighter rectangle behind the plant (`weather-card-dark-still.png`):
    `Views/WeatherViews.swift:65-67`, the haze panel does not blend with the full-width sky. Fade its edges or draw it
    full width.
15. **L** Butterfly summary reward row is bare icons ("drop 1, star 6, box 1"), `Views/ButterflyView.swift:289-293`.
    One footnote line "1 water · 6 shed points · 1 soil" reads for a child and VoiceOver alike.
16. **L** Quiet Garden tool sheet is a `.large` sheet holding one tile and one row (`shed-quiet-sheet.png`),
    `Views/ShedTools.swift:249-250, 294`. Use `[.medium, .large]` when `quiet` and not AX.
17. **L** Plant page: the tend toast is pinned above the bar and covers the name card's header and title
    (`tend-done.png`, `tend-hello.png`). Acceptable for a 3 s toast; if touched, anchor it to the top of the scroll
    content instead. Copy: "Cool and fresh, how lovely. +3 growth" (`Rules/PlantVoice.swift:17` plus the appended
    suffix) mixes a kid sentence with a stat; drop the "+N growth" suffix or say "and it grew a little".

### Low

18. **L** Home hero shows four stacked lines (tagline, garden day, words-to-plant, Rose line), `Views/HomeView.swift:205-231`.
    Two progress sentences with different numbers ("0 of 3 words", "Finish 8 more words") is a lot for one card; hide the
    tagline once `days > 0`, or move the Rose line under Play.
19. **L** Onboarding first tip: "Your first drink is free!" (`Views/OnboardingView.swift:246`) hints that drinks cost
    something. "Your first drink is ready!" says the same without the money word.
20. **L** Level map at AX: the trail stroke shows as a short tan stub between the medal and the card
    (`fid-levels-ax5.png`); `Views/LevelMapView.swift:105-115`. Skip the trail when `oneColumn`.
21. **L** Plant page at AX: `LifeSheet` draws a grabber (`Components/LifePanel.swift:413`) that does not drag; the
    chevron is the control. Drop the capsule or make the whole header toggle.
22. **L** Three back affordances: circular chevron (Garden, Plant, Badges), "< Home" text (Level map), house icon
    (Game). Fine individually; pick one for the three pushed screens in 1.1.
23. **L** Shed has two section-header styles on one page: tracked uppercase "TOOLS" (`ShedView.swift:53`) and title3
    "Pots" with a right-aligned footnote (`PotPickerViews.swift:621`). Use the same `sectionHeader` for Pots.
24. **L** Settings is a plain system Form (grey background, system type), the one screen off the palette
    (`SettingsView.swift:16`). `.scrollContentBackground(.hidden).background(Color.appBackground)` is enough for 1.0.
25. **L** Wake flow: the puzzle step inherits `.large` and sits half empty (`WakeSheet.swift:61, 116`); "A peek comes
    soon" disabled button looks live (`WakePuzzleView.swift:45`, add `.opacity(0.6)`); seed page shows "Wake first / Tap
    the seed" on all four tiles (`LifePanel.swift:229-230, 268`), once is enough.
26. **L** Light-mode weather overlays (wind, puddles, hail) are white on cream and nearly invisible; a hail stone draws
    over the Life pill (`Components/WeatherOverlay.swift:65-66, 176`). Needs a light palette; 1.1.
27. **L** Guide nits: wordmark shrinks to 20 pt while "Skip" grows at AX (`GuideView.swift:67`); the "Hello!" bubble
    floats centred rather than beside the rose (`:499-505`); page 8 has an empty middle (`:673-700`).
28. **L** Daily quest card "0 of 1" for a one-step quest (`Components/DailyQuestCard.swift:36`); show "Not done yet"
    when `target == 1`.
29. **L** "Great word!" dim is `Color.black.opacity(0.45)` (`GameView.swift:274`), which turns the cream to flat grey.
    `Color.appPrimaryText.opacity(0.4)` keeps the warmth. Cosmetic.

### For the builder now (send with the text-fit pass)

Items 1 to 11 are one session's work and share one test: extend the tend-bar width test the G3 builder is adding
(`UIFont.preferredFont(forTextStyle:compatibleWith:)` per size against the per-cell width) to the Garden, Badges, Shed
pot, Repot tile, soil chip and Visitors' book grids. Items 12 and 13 ride along if there is time; nothing else blocks 1.0.

## 3. Plus page rulings (on `docs/pm/plus-page-review.md`, 7ec42ee)

Severity confirmed for 1, 2, 3, 4, 5, 7 and 8. Changes and calls:

| # | Ruling | 1.0? |
|---|---|---|
| 1 Trial wording without an offer | High, agreed. The guard on `introductoryOffer.paymentMode == .freeTrial` is a four-line change. The hard-coded "3 days" stays for 1.0. | Yes |
| 2 Gate sheet clips at AX | High, agreed; it is also item 6 above. | Yes |
| 3 Renewal line vs 24-hour rule | Medium, agreed; copy only. Use the review's sentence as written. | Yes |
| 4 Loading state | Medium, agreed. Smallest safe version: hide the fine print and show `ProgressView` + "Loading prices" until `store.offers(selected)`; dim the fill only. | Yes |
| 5 Faint unselected circle | Medium, agreed (confirmed in `plus-grown-ups.png`). `opacity(0.55)`. | Yes |
| 6 Ask to Buy pending copy | Raise to **medium-high**: a parent approving hours later sees "tap Restore" and a child taps it repeatedly. New `awaitingApproval` case plus one line of copy. | Yes |
| 7 "/yr" and "/mo" | Medium, agreed; " a year" / " a month" / "once". Also fixes the AX5 break the review predicted. | Yes |
| 8 "Not quite" at 3.69:1 | Low-medium, agreed; use `appPrimaryText` with an icon, no new asset. | Yes |
| 9 Message colour, announcement, unseen success | Low, agreed; do the colour and the announcement, drop the success string. | Yes |
| 10 Restore feedback | Low, agreed; the busy state and two lines. | Yes |
| 11 VoiceOver header and decoration | Low, agreed; three one-liners. | Yes |
| 12 Duplicate Restore row (my call) | **Keep the footer button, change the nudge.** On the Plus page show `FamilyShareNudge.Copy.line` as text only ("Already have Plus on a family phone? Restore purchases is below.") and no second button. Settings keeps its button. Owner approved the placement, not two identical buttons 60 pt apart. | Yes |
| 13 "3-day" hyphen break | Low, agreed; non-breaking hyphen. | Yes |
| 14 Inline strings not linted | Low, agreed; move into `PaywallCopy.all`. | Yes |
| Subscriber-to-lifetime path | Product decision; 1.1 backlog. | No |
| Trial length from the offer | 1.1 backlog. | No |

Missed by the review (add to its list):
- The Plus page's Nov 6 shots are the only ones; the planned sim run should also capture the **gate sheet with the
  number pad up at AX5** on a 375 pt phone, since that is the failure case for item 2.
- `PrimaryButtonStyle` ignoring `isEnabled` (finding 4) also affects "Continue" on the gate and "Wake it up" on the
  resting offer; fix it once in `Theme.swift:76` and all three benefit.
- "WordFlora is complete without Plus." is a strong, honest opener; keep it as the first line in every layout.

## 4. Rulings on the text-fit rule where the code is borderline

- **Single glyphs may shrink.** `Components/KeyboardView.swift:97` and `Components/WordTilesView.swift:118` use
  `minimumScaleFactor` on one letter in a fixed key or tile. There is no word to break; a 26-key row cannot grow
  without a second keyboard layout. Allowed; note it for the owner.
- **Drawn illustrations may use fixed sizes.** `GuideView.swift:390-873` (`GuideArtCard`, fixed 361 x 372 canvas) and
  `Components/SeedPotView.swift:30-32` ("z" sleep marks) are pictures with an accessibility label, not reading text.
  Allowed. `BadgeDetailView.swift:97-101` pins the share image at `.large`; that image is for sharing, not reading on
  device. Allowed.
- **Everything else in the grep is in section 2**: `LifePanel.swift:31, 302` (tend bar, G3), `PotPickerViews` (items 3,
  4, 7, 8), `ShedTools.swift:199`, `GameView.swift:156`, the four `ViewThatFits`.
- `GameView.swift:218` "Take your time" pill uses `.fixedSize()` on purpose (it was wrapping); at AX5 the pill may
  exceed the flower width. Verify in the sim run (`speedbloom-take-your-time.png` is default size only).

## 5. For docs/pm/backlog.md (ideas, not fixes)

- One `GridColumns(for: typeSize)` helper shared by Garden, Badges, Shed pots, Repot tiles, soil chips, Visitors' book.
- Light-mode weather overlay palette (grey clouds, tinted sparkles); overlay drawn under the HUD.
- Settings restyled in Theme fonts and `appBackground`.
- One back-button style across pushed screens; one name for the butterfly game ("Say hello").
- Butterfly summary sticker sized by `@ScaledMetric`; reward row as words.
- Guide AX layout as a plain VStack (dots and buttons follow the text).
- Home hero: a visual words-to-plant meter replacing the two progress sentences (hook already in `HomeView.swift:221`).
- Trial length read from `introductoryOffer.period`; subscriber-to-Plus-Forever path.
- Plant Life panel: one meter style (bars) instead of bars, dots and hearts side by side.

## 6. Checked and fine

Onboarding age choice at L, dark and AX5 (buttons scroll in below the fold, nothing clips). Home locked tiles and
Daily Bloom row at AX5. Garden at L and dark. Plant hero, petal pips, name card and "Ask for a fun fact" at L, dark and
AX5. Four-tile tend bar states (ready, done with check, blocked toast with the moon). Game at L, dark and AX5, 10- and
14-letter words, SpeedBloom ring, used-key marks. Win, rest, break and resting-offer cards at L and dark; copy is
exemplary ("That's enough for now" is a real equal choice; ad note sits beside the choice that triggers it). Level map
at L and dark. Quiet Garden offer in all five variants. Wake sheet. Celebration at calm, medium, large and reduce
motion; intro bloom sequence. Badge moment. Weather banner and forecast at AX5. Guide at L and dark. Settings at L,
dark and AX5 (except the Theme picker, unverified). No locks, no countdowns, no "last chance", no price on a kid
surface except the Shed's "Part of WordFlora Plus" pots, which point a grown-up to Settings and are acceptable.

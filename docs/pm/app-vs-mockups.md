# App vs mockups: fidelity review (2026-11-04)

Side-by-side page: http://localhost:8765/qa/ (app shots in `design-preview/qa/shots/`, rendered first-round mockups in `design-preview/qa/mock/`).
New level map mockup: http://localhost:8765/level-map/.

## How this was made
- **Build.** The app was built from a copy of the working tree taken at about 18:50: HEAD `03fb827` plus the uncommitted edits that were in progress at that time. It ran on a dedicated simulator, "WF QA iPhone 17" (iOS 26.5), which has since been deleted.
- **QA-only hooks.** The copy added a `-qa-route=` launch argument that sets the first navigation path, plus `-qa-repot` and `-qa-rest`. These exist only in the scratch copy. Nothing in the real tree changed. All other launch arguments are the existing `-uitest*` ones.
- **Stale screens.** The Shed was reworked after the snapshot (`ShedView.swift` modified, new `ShedTools.swift`), so the Shed shots show the older list layout. Re-shoot the Shed before acting on the Shed notes below.
- **Blank or partial shots.** The machine was heavily loaded during capture (load average 250-470), and some launches had not drawn when the shot was taken. `garden-light`, `onboarding-light` and `home-early-light` are blank frames, so those screens were reviewed from code only. Only the first screen of the plant page was captured; the name story card is cut off at the tend bar.
- **Reviewers.** Three reviewers compared the PNG pairs:
  - Opus: Home, Onboarding, Level map.
  - Sonnet: Plant detail, Pot picker, Shed.
  - Sonnet: Game, Rest reveal, Garden, Plus.

  I checked their file:line references against the current tree.
- **Out of scope**, as agreed: the celebration/petal-rain intro redesign, the rest-card redesign, the Rose line wording, and word bank and plant pacing.

Severity: **must** = visibly wrong against the mockup or breaks a product rule; **should** = noticeable polish; **nit** = minor.

## Home (home-light, home-dark vs home-v2 unlocked-*-c0)
- [must] **Explore tiles are too tall.** They render at about 121 pt against the mockup's 96 pt, and Badges at about 84 pt against 64 pt, with empty space under the label. `maxHeight: .infinity` inside the Grid stretches the rows. Fix: `.frame(maxWidth: .infinity, minHeight: 96, alignment: .top)`, and keep `minHeight: 64` for the wide row (`HomeView.swift:363`, `:357`).
- [must] **Blank band in the hero card.** There is a gap of about 33 pt between "Your garden is new" and the Rose line: `fixedSize(horizontal:false, vertical:true)` inside the HStack reserves an extra line. Fix: give the text VStack `.frame(maxWidth: .infinity, alignment: .leading)`, or drop the `fixedSize` at `HomeView.swift:159`, then re-check wrapping at AX sizes.
- [should] **Shed glyph.** `wrench.and.screwdriver.fill` is heavier than the mockup's single wrench. Use `wrench.adjustable.fill` (`HomeView.swift:295`, `:306`).
- [should] **Badges glyph.** `rosette` draws as a thin outline, and the mockup has a filled medal. Use `medal.fill` (`HomeView.swift:297`, `:310`).
- [should] **Tile icons are too big.** The glyph fills the full 28 pt box, while the mockup glyph is about 20 pt wide. Lower the `tileIcon` default to about 24 (`HomeView.swift:78`).
- [nit] **Tagline style.** The mockup tagline is regular weight in secondary colour; the app uses medium weight in primary colour (`HomeView.swift:152`).
- [nit] **Play button.** The app button is flat, where the mockup has a gradient and glow. Flat is deliberate for contrast (comment at `HomeView.swift:245`). Keep it unless the owner prefers the glow.
- **Wordmark.** Correct: the app already uses the final "B uncut" art, which supersedes the plain-text word in the mockup.
- **Dark mode.** Matches the mockup apart from the two layout bugs above.

## Home early and large text
- **Early state** (blank shot, checked from code):
  - Closed tiles use `sparkles`, not a lock, which is correct under the product rule (`HomeView.swift:328`).
  - The hint copy matches the mockup.
  - The tile-height fix above applies here too.
- [should] **Large text** (checked from code):
  - The one-column layout, 64 pt flower and 72 pt rows match the mockup `.ax` rules.
  - The wordmark is capped at 1.6x (`Theme.swift:34`), where the mockup uses about 1.9x. Confirm on a re-shoot that the gear stays 44 pt and nothing clips.

## Level map (levelmap-light/dark vs the new level-map mockup)
The current screen is the old card list. The new design ("Garden Path", `design-preview/level-map/index.html`) replaces it. This is the implementation list for `WordFlora/Views/LevelMapView.swift`:
- [must] **No lock icons.** Remove `lock.fill` (`:33`). Unopened levels become "soon" cards:
  - a dashed border;
  - the surface mixed 55% with the background, with no shadow;
  - the name in secondary text;
  - a green bold tag "Coming soon in your garden";
  - the line "Opens when Level N-1 has 10 plants." This replaces "Earn all 10 plants in level N-1 to open this one." at `:42`.
- [must] **Header.**
  - Replace "Levels" (`:20`) with the large title "Garden Path" (`.isHeader`).
  - Under it: "N plants found. Every 10 plants opens a new level." Leave out the count when it is 0.
  - Then a key card: "Petal = plant found" and "Gold ring = full bloom".
- [must] **Nav bar.** The back button reads "Home". Centre a small `WordmarkView` (about 22 pt high).
- [must] **Rows.** Medals (128 pt) and cards alternate left and right. Behind them runs a winding dirt path: cubic curves through the medal centres, drawn as a 26 pt edge stroke, a 20 pt fill and a dotted centre line.
- [must] **Medal (`LevelMedal`).**
  - A disc in the level tint, with the level's hero plant at 68 pt: daisy, lotus, venus flytrap, giant water lily, wollemi pine.
  - An inner ring of 10 petals: filled for each plant found, outlined for the rest.
  - An outer ring of 10 gold arcs, one per plant at stage 4 (the garden level, `ProgressionPolicy.gardenLevelComplete`).
  - A 3 pt accent ring when the level is current.
  - Badge: a green check when all 10 are found; a gold sun when all 10 are in full bloom.
  - Soon levels show a soil mound and sprout, with no rings and no empty slots.
  - Mark the medal `accessibilityHidden`.
- [must] **Card.**
  - "LEVEL N" eyebrow, the name, then the theme line.
  - "N of 10 plants found" and "N of 10 in full bloom". When found = 0, show "Find your first plant!" instead.
  - Done levels: "All 10 found! Level N+1 is open."
  - Full bloom: "Full bloom garden!" with a sun.
  - Current level: "You are here" chip, a 2 pt accent border and a soft glow, and "Find N more to open Level N+1."
  - Button "Play Level N" (capital L, 48 pt tall): filled amber for the current level, outlined for past ones. This replaces `SecondaryButtonStyle` at `:39-40`.
- [must] **Accessibility.** One element per stop, labelled like the mockup's `aria-label`s: "Level 2, Sprout. You are here. 4 of 10 plants found. 0 of 10 in full bloom." Soon levels also include the opening rule. The Play button stays its own element.
- [must] **AX sizes.** At `dynamicTypeSize.isAccessibilitySize`, use one column: a 96 pt medal centred above a full-width card, the path running straight down, and no alternation.
- [should] **End and scroll.** Add an end-of-path bench line, and scroll to the current stop on appear (ScrollViewReader).
- [should] **Colour assets.** About 9 colorsets for the level map: five level tints, plus path, path edge, petal and soil. The light and dark values are in the mockup `:root` blocks.
- **Data.** Keep the earned and stage counts already in the view (`:25-27`), and `app.profile?.currentLevel`.

## Plant detail (daisy-light vs fact-card b-daisy-light, tending)
- [must] **Life panel opens expanded.** On first view it covers the left third of the stage, and "Ready for / a drink" and "Ready for / a hello" wrap onto two lines. The fact-card mockup shows a collapsed "Life" tab. Either start collapsed (`PlantDetailView.swift:290-295`) or, if open is intended, widen the panel to about 170 pt or shorten the copy (`LifePanel.swift:127`, `:203`). Owner decision below.
- [should] **Tend bar covers the name card.** The bar is about 130 pt tall and cuts the name story card at "Bellis perennis", so the card is easy to overlook. Reduce the bar height or add a bottom content inset (tend bar near `PlantDetailView.swift:255`).
- [should] **Eyebrow copy.** It reads "HOW DAISY GOT ITS NAME"; the mockup says "HOW IT GOT ITS NAME". Pick one (`NameStoryCard.swift:25`).
- [should] **Love shown twice.** The stage pip row shows five filled petals while the Love hearts in the panel are all empty. The same data reads two ways. Add the mockup's "N love petals" caption and check the two agree (`PlantDetailView.swift:194`).
- [nit] **Pip row spacing.** The pip row sits about 14 pt under the pot shadow; the mockup leaves about 40 pt (`PlantDetailView.swift:194`).
- [nit] **Flower art.** Matches the mockup (daisy, white petals, gold centre). The pot and shelf are expected from the pots work.

## Pot picker (potpicker-light vs pots s2-pick-light)
- [should] **Soil choices.** The app has four plain text buttons (Loam, Sandy, Peaty, Compost). The mockup has soil cards with a swatch and a "1 scoop / 2 scoops" line. Add the swatch and cost line, or confirm that the four-soil model supersedes the mockup (`PlantDetailView.swift:466-480`).
- [should] **Pot names don't line up.** Some names wrap to two lines and others shrink to one, so baselines differ across a row. Give the name a fixed two-line slot (`minHeight`), or use one smaller font with no scale factor (`PotPickerViews.swift:100-107`).
- [should] **Plus tags crowd the row above.** The second-row tags press on the first row's two-line names. Raise the row spacing from 10 to about 18 (`PotPickerViews.swift:84`, `:112`).
- [nit] **Matches.** The selected ring with check badge and the dashed outline for pots still to earn both match the mockup.

## Shed (shed-light; stale build, re-shoot first)
- [must if still live] **Old list layout.** The shots show "Tier 1 of 3" and "Upgrade for 30 points" on every tool with 0 points, and an upgrade price on tools the player has not found yet ("Finish all of level 1 in your garden to find it."). The new source (`ShedView.swift`, `ShedTools.swift` `ToolTile`/`TierPips`) appears to replace this. Confirm on a fresh build:
  - no price is shown on tools not yet found;
  - no unreachable cost is shown at a 0 balance.
- [nit] **Pots grid columns.** Check that the Shed pots grid uses 3 columns, as in the mockup, and not `PotCatalog.gridColumns` = 5 (`PotPickerViews.swift:185`).

## Game (game-light vs screens/game, home-v2 style)
- [must] **Hint card too tall and unbalanced.** It is about 125 pt high for one line. A 44 pt speaker button sits about 20 pt below the text, and the full "Simpler clue" row adds more height. Fix:
  - centre or baseline-align the row;
  - give the speaker a 36 pt visual with an expanded hit area;
  - tighten the spacing (`GameView.swift:115-139`).
- [should] **No petal count.** The petals are the lives indicator and nothing states how many remain. Add a small caption under the flower, worded positively ("6 petals to go"). The mockup's "6 PETALS LEFT" uses a banned word (`GameView.swift:29-30`).
- [should] **CopySafety in the accessibility label.** The FlowerView VoiceOver label says "\(petals) of 8 petals left", and "left" is banned. Change it to "\(petals) of 8 petals on the flower" (`FlowerView.swift:50`).
- [should] **Empty middle.** About 40% of the screen is empty between the tiles and the keyboard. Enlarge the flower (`:30`, now 170) or centre the hint and tiles block vertically.
- [should] **Hint eyebrow.** The mockup has a small-caps "HINT" eyebrow; the app has none (`GameView.swift:115-119`).
- [nit] **"Level 1" off centre.** The title sits about 16 pt left of centre because the Home and Help controls differ in width. Centre it with a ZStack (`GameView.swift:95-104`).
- [nit] **Ghost petal.** The single dashed ghost petal reads as a stray outline. Lower its opacity (FlowerView).
- **Kept dropped on purpose.** The mockup's "Missed: Z Q" line uses a banned word.

## Rest reveal (restcard-light; non-layout items only, since the redesign is owned elsewhere)
- [must] **Header shows above the card.** The game top bar ("Level 1", Help) peeks out above the card. Dim the whole screen, or move the card down (overlay at `GameView.swift:160-180`). Pass this to the rest-card owner.
- [should] **Weak sub-line contrast.** The fact and sparkle line use secondary text at small sizes. Raise them to primary at 85% (`GameView.swift:177`).
- [should] **Red keyboard behind the card.** The dimmed keyboard still shows nine red x keys behind the calm card. Dim it more, or hide the keyboard while the card is up. Pass this to the rest-card owner too.

## Plus (plus-light vs brand/v3/subscriptions)
- [must] **Extra benefit row.** "Share it with your family" is a third benefit row that the mockup does not have (`Paywall.swift:32`). Family Sharing must really be enabled on the subscription in App Store Connect before this can ship. Owner decision below.
- [should] **Trial fine print.** The mockup gives the first-charge date ("You will not be charged today. First charge: $12.99 on <date>"). The app's fine print is shorter. Keep the date line, for App Review and honesty (`PlusView.swift:69`).
- [should] **Close control.** A 44 pt circular back chevron with a drop shadow sits where the mockup has an X and the line "Optional. The game stays free."
- [should] **Title too large.** largeTitle against the mockup's ~22 pt title (`PlusView.swift:19-20`).
- [should] **Links scattered.** Restore, Manage, Terms and Privacy are loose text. Group them as underlined links in two tight rows (`PlusView.swift:~72-80`).
- [nit] **Selected plan colour.** The selected plan uses a green ring; the mockup uses an amber highlight.

## Garden, Onboarding
No usable app shots (blank frames during load). From code, Onboarding matches `logo/final/shots/app-onboarding.png`: wordmark, tagline and flower rain. In the reference, the falling petals cover the tagline; that belongs to the intro redesign. Re-shoot both screens with the level map work.

## Headline must list
1. **Level map:** rebuild `LevelMapView` as Garden Path. Remove the lock icons, add the petal ring and gold full-bloom ring, the positive "Coming soon in your garden" copy, and the one-column AX layout.
2. **Home:** fix the Explore tile height (`HomeView.swift:363`).
3. **Home:** fix the hero card blank band (`HomeView.swift:159`).
4. **Plant detail:** decide whether the Life panel starts open or collapsed. Open today, it crowds the stage and wraps its labels.
5. **Game:** tighten the hint card (`GameView.swift:115-139`).
6. **Rest reveal:** the top bar shows above the card. Pass to the rest-card owner.
7. **Plus:** "Share it with your family" needs owner sign-off and Family Sharing actually turned on.
8. **Shed:** re-shoot on a fresh build, and make sure there is no price on unfound tools and no unreachable cost at 0 points.

## Owner decisions
1. **Level 3 name.** The mockup proposes "Wildwood" so that "bloom" means only full bloom and Daily Bloom; the app and spec say "Bloom". Also approve the level theme lines and the hero plant for each level, which are new and exist only in the mockup:
   - Garden friends
   - Plants from far away
   - Strange and wild plants
   - Rare wonders
   - Old, giant and rare
2. **Life panel on the plant page:** start open or collapsed?
3. **Tend bar:** Water / Feed / Sun / Repot with sub-lines (current, matches tending/actions) or the fact-card mock's three pills? The reviewer leans towards the current set, with a shorter bar.
4. **Soil choice:** four soils (current) or two soils with scoop costs (pots mockup)?
5. **Plus:** keep "Share it with your family"? X close with "Optional. The game stays free." or the back chevron?
6. **Game:** add a "petals to go" caption under the flower?
7. **Play button:** flat (current) or the mockup gradient and glow?

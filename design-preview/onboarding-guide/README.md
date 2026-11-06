# Onboarding guide: implementation spec

This is a skippable 8-page first-run guide that can be replayed from Settings. Open the mockup in `index.html`:

```
index.html?page=1..8 &theme=light|dark &ax=1 (AX large text) &rm=1 (Reduce Motion / Calm) &quiet=1 (Quiet Garden copy) &replay=1 (from Settings)
```

- **Shots:** in `shots/`. `p1..p8-light`, `p1/p4/p5/p8-dark`, `p1-ax-light`, `p4-ax-dark`, `p7-ax-light`, `p3-rm-light`, `p4-quiet-light`, `p8-replay-dark`, plus strips `all-light`, `all-dark`, `all-rm-light`.
- **Re-render:** `sh render.sh` (headless Chromium over file://).
- **Copy lint:** `node check-copy.mjs` reads `CopySafety.banned` from Swift.
- **Copy source of truth:** `copy.js`. Mirror it into `Rules/GuideCopy.swift` and add a CopySafety test over every string.

## Where it hooks in

- **First run:** add `case guide` to `OnboardingFlow.Step`, so the steps run `intro -> age -> guide -> tutorialWord`. `selectAge` moves to `.guide`. Add `guideFinished()`, which moves `.guide` to `.tutorialWord`, and call it for both Skip and Start playing.
  - The guide goes after the age question, not straight after the rain intro, because the age answer may turn on Quiet Garden, and that changes page 4. See open question 1.
  - `skip()` still jumps to `.home` and is not used here: skipping the guide still plays the tutorial word.
- **OnboardingView:** add `case .guide: GuideView(mode: .firstRun)`.
- **Replay:** add a "Help" section to `SettingsView` with a `Button("Show the guide again")` and a footnote: "A quick tour of how to play and grow your garden."
  - Present `GuideView(mode: .replay)` as `.fullScreenCover`.
  - In replay, Skip reads "Close" and the last button reads "Done". Both dismiss.
- **No state is written by the guide**, apart from optionally `guideSeen = true` for analytics-free bookkeeping.
- **No ads, paywall, Plus, prices or permission prompts** anywhere inside it. Keep `mayShowPaywall` false in session 1, as today.
- **UI test:** `GuideUITests` covers three things.
  - Swipe and Next through all 8 pages, then reach the tutorial word.
  - Skip from page 1 reaches the tutorial word.
  - Settings, then "Show the guide again", then Close returns to Settings.
  - Also run an AX5 audit.
  - Identifiers: `guide-skip`, `guide-back`, `guide-next`, `guide-page-N`.

## Layout (iPhone 393 x 852 pt reference)

- **Top bar** (52 pt):
  - `WordmarkView` small, 24 pt tall, the v3 hero wordmark (`Wordmark` asset with one flower on the Flora o). It is decorative: `accessibilityHidden(true)`.
  - Skip on the right: plain text button, `Theme.font(.body, weight: .heavy)`, `Color.accentText`, min 44 x 44.
  - On the last page Skip is hidden. Use `.hidden()` so the layout keeps its place.
- **Pager:** `TabView(selection:)` with `.tabViewStyle(.page(indexDisplayMode: .never))`, using custom dots. Each page is a `ScrollView`:
  - Illustration card: full width minus 16 pt gutters, 372 pt tall, corner 28, continuous. Background is a 160 degree `LinearGradient(a1 -> a2 at 75%)` with a 1 pt inner line at text 8%.
  - Title 22 pt below the card: `Theme.font(.title, weight: .heavy)` (28 pt reference), centred, `.isHeader`.
  - One or two body lines: `Theme.font(.body, weight: .medium)` (17 pt), `secondaryText` (text 82%), centred, 8 pt apart, max width 330.
- **Footer** (outside the scroll):
  - Dots: 8 pt circles, 8 pt apart. The current dot is a 24 x 8 capsule in text colour; the others are text 28%. The shape changes, not just the colour.
  - Then 8 pt gap, then a button row, 56 pt tall, gap 10:
    - Back: 104 pt wide, surface fill, 1.5 pt line, hidden on page 1.
    - Next: flexible, `PrimaryButtonStyle` (Play button gradient `#F2C25E -> #E8A838`, ink `#1F3320` light).
    - Next label: "Next" plus `chevron.right`. On page 8: "Start playing", or "Done" in replay.
- **AX sizes** (`dynamicTypeSize.isAccessibilitySize`):
  - Illustration box is 226 pt tall, with the art scaled by 0.6.
  - Text is left-aligned.
  - Buttons stack: Next on top, Back below, both full width with min height 56.
  - The page scrolls.
- **Colours:** existing tokens only.

  | Page | a1 | a2 |
  |---|---|---|
  | 1 | tileLevelsFill | tileGardenFill |
  | 2 | tileGardenFill | tileBadgesFill |
  | 3 | tileLevelsFill | tileGardenFill |
  | 4 | bloomFill | tileGardenFill |
  | 5 | tileVisitorsFill | tileShedFill |
  | 6 | bloomFill | tileBadgesFill |
  | 7 | tileLevelsFill | tileGardenFill |
  | 8 | tileBadgesFill | tileVisitorsFill |

  - Hearts: `#D9566C` light, `#F28A9C` dark.
  - Gold ring: `appAccent`.

## Pages, copy and art

The copy below is exact.

### 1. `guess`: "Guess the word"
- **Lines:** "Read the clue, then tap letters to fill in the word." / "Your flower’s petals are your tries. Tap Help for a hint."
- **Art:**
  - A clue card along the top: "Clue · A white flower with a sunny middle".
  - `FlowerView(petals: 6, sway: !rm)` at 150 x 180, left. It shows its 2 dashed ghost petals.
  - The chip "Petals = tries" with a sparkle under the flower.
  - On the right, the Help pill (`lightbulb.fill` "Help", accent fill) and `WordTilesView`-style tiles: D A _ S _.
  - Along the bottom, one keyboard row (A B C D E I O S Y). A, D and S are green ("in the word"); C and O are dimmed.
- **a11y:** "A flower with 6 of 8 petals, the word D, A, blank, S, blank, and a Help button."

### 2. `plants`: "Three words, one plant"
- **Lines:** "Your first win brings your first plant." / "After that, every 3 words brings a new plant."
- **Art:**
  - Three word cards (DAISY, CLOUD, MAPLE), each with a green `checkmark.circle.fill`.
  - Dotted lines join them to a daisy (`plant_daisy` 120 pt) standing in a Terracotta pot (`PotArtView`, 108 pt, soil showing).
  - Two sparkles, and the chip "New plant found!".
- **a11y:** "Three words with check marks lead to a new daisy in a pot."
- Uses `Economy.wordsPerPlant`; interpolate the "3".

### 3. `tend`: "Help your plant grow"
- **Lines:** "Water, feed and sun help it grow a little each day." / "Prune and repot to help it reach full bloom."
- **Art:**
  - The `LifePanel` growth track, re-used: 5 dots labelled from `LifeStats.stageNames` (Tiny, Sprout, Bud, Bloom, Full bloom), with Bud current.
  - Three plants on one ground line: a sprout (84), a white bud (112), and a full daisy (148, sways).
  - 5 action tiles, 46 pt each:
    - Water: `drop.fill`, blue.
    - Feed: soil bag, brown.
    - Sun: `sun.max.fill`, gold.
    - Prune: `scissors`, green.
    - Repot: pot, terracotta.
  - Where they exist, use the real tending button icons from the plant page.
- **a11y:** "A plant growing from tiny to full bloom, with water, feed, sun, prune and repot buttons."

### 4. `love`: "Hearts and hellos"
- **Lines:** "Say hello or care for your plant each day to fill its hearts." / "After a few rainy days it naps as a seed. A fun challenge wakes it, and it keeps all it grew."
- **Quiet Garden or Calm mode on:** line 2 becomes "Your plant keeps all it grows, always."
- **Art:**
  - The rose plant (140), with a "Hello!" bubble and an "Energy" row of 5 hearts (4 filled, 1 outline).
  - Below, a white card: `SeedPotView` (84, small cloud with 2 drops) labelled "Naps as a seed", then an arrow, then a sprout in a Terracotta pot with a sparkle, labelled "Wakes with a challenge".
  - In Quiet or Calm mode, drop the bottom card's cloud and drops; keep the rest.
- **a11y:** "A plant with 4 of 5 energy hearts saying hello. Below, a seed napping in its pot wakes up as a sprout."

### 5. `garden`: "Your garden and friends"
- **Lines:** "Visit all your plants in the Garden." / "Catch butterflies to meet visitors and earn points for Shed tools."
- **Art:**
  - Three Home-style tiles in their tile colours:
    - Garden: wide, with tulip, daisy, sunflower and lavender.
    - Visitors: the ladybug sticker (`VisitorArt`).
    - Shed: the watering can tier 1 (`Tools/can-t1`).
  - A monarch (`VisitorArt` monarch frame a, 48) on a dotted arc from Visitors to the Shed.
  - The chip "+5 points".
- **a11y:** "Garden, Visitors and Shed, with a butterfly flying from Visitors to the Shed."
- In Quiet Garden, drop the "+5 points" chip, as the Shed hides points there.

### 6. `daily`: "One word for everyone"
- **Lines:** "Daily Bloom is a new word each day." / "Everyone who plays gets the same word that day."
- **Art:**
  - A sunflower (132) inside 12 soft gold rays.
  - The Home Daily Bloom card, re-used as is: sun icon, "Daily Bloom", "One word for everyone today", chevron. Non-interactive here.
  - Five tiles showing "?".
  - No streak and no calendar.
- **a11y:** "The Daily Bloom card with a sunflower and five mystery letters."

### 7. `levels`: "Five levels to explore"
- **Lines:** "Find 10 plants in a level to open the next one." / "Grow all 10 to full bloom for a gold ring."
- **Art:** a mini version of the `LevelMapView` path with 5 nodes of 68 pt:
  - 1. Seedling: daisy, gold ring and a check.
  - 2. Sprout: lotus, blue "current" ring, and the "You are here" chip.
  - 3 to 5 (Wildwood, Grove, Ancient): a sprout glyph.
  - Legend chips: "Gold ring = full bloom" and "10 plants opens the next level".
- **a11y:** "A garden path with five levels: Seedling, Sprout, Wildwood, Grove and Ancient. The first has a gold ring."
- Numbers come from `Economy.plantsPerLevel`.

### 8. `peeks`: "Coming soon in your garden"
- **Lines:** "Rare plants from far away, new pots and shiny badges." / "They open up as your garden grows. Let’s play!"
- **Art:**
  - Three dashed "peek" cards, each with a green "Soon" chip (sprout icon):
    - Rafflesia: "Rare plants".
    - Starlight pot (`PotArtView`, 80): "Pots".
    - `rare_finds` badge, tier 2: "Badges".
  - A "Level 5 · Ancient · Soon" row.
  - A few still sparkles.
  - NO lock icons. Show no Plus pots.
- **a11y:** "Sneak peeks: a rare plant, a starry pot and a badge, each with a Soon tag."

## Motion

| Mode | Behaviour |
|---|---|
| Default | Gentle loops only: flower or plant sway (±1.6°, 3.2 s), bob 2.6 s, heart or key pulse 1.8 s, butterfly flutter 0.5 s with a drift 4 s, sparkle twinkle 2.2 s, the seed pot's own breathing, water drops 1.6 s, Daily rays rotating 40 s. Page change is the standard paging slide. No bursts, confetti or sound. |
| Reduce Motion, either the system setting or `settings.reduceMotionOverride` | Every loop off, so the art is static (same frame as the shots). Page change is a 0.25 s crossfade. `FlowerView(sway: false)` and `SeedPotView` are already still under Reduce Motion. |
| Calm mode | Same as Reduce Motion for the guide, plus the page 4 Quiet copy. |
| Haptics | Soft selection tick on page change if `hapticsOn`. |

## VoiceOver

- **Order:** Skip (button), then the page (the illustration as one image with its label, then the title as a header, then the lines as text), then the dots, then Back, then Next.
- **Dots:** one element, `accessibilityLabel("Guide")`, value "Page 2 of 8". Adjustable: swipe up and down to change page.
- **Art:** `.accessibilityElement(children: .ignore)` plus a label. Inner chips are not read on their own.
- **On page change:** post `.screenChanged` focused on the title.
- **Skip:** `accessibilityHint("Goes straight to your first word")`. In replay: "Close", hint "Back to Settings".
- **The wordmark and status bar are hidden.**

## Open questions

1. **Placement:** should the guide come before the age question (straight after the rain intro, as the brief literally says) or after it (as specced, so Quiet Garden copy is right)? Recommended: after.
2. **Length:** 8 pages is long for a 6-year-old before their first word. Option: show pages 1 to 3 before the tutorial word and 4 to 8 after the first garden tip. Skip stays on every page either way.
3. **Page 5 Visitors tile:** the app tile opens the butterfly game today (shed-visitors notes). The copy works for either.
4. **Page 3 Prune and Repot:** the shears come from the Shed after a level. Should "Prune" be shown before the player has them? The copy only says "help it reach full bloom", so no promise is made.

# Onboarding guide: critic pass

Reviewed against the brief, the light/dark/AX/RM shots, `check-copy.mjs`, and the existing app art (Home v2, level map, pots, seed pot).

| # | Where | Finding | Sev | Fixed? |
|---|---|---|---|---|
| 1 | p4 art | The awake sprout sat behind the pot and its label ran under the pot, so the "wakes up" half did not read. | must | Yes. The sprout now stands on the soil and the card is taller. |
| 2 | p4 art | `seed-pot.svg` already has its own z's, so my extra "z" doubled them. | should | Yes. Removed. |
| 3 | p7 art | The "You are here" chip covered the "2. Sprout" label. The current-level ring was gold too, which clashed with "Gold ring = full bloom". | must | Yes. The chip moved above the path and the current ring is now Levels blue. Gold means full bloom and nothing else. |
| 4 | p7 art | "3. Wildwood" wrapped onto two lines. | nit | Yes. Labels no longer wrap. |
| 5 | p5 art | The butterfly covered the "Garden" label. | should | Yes. The Garden tile is shorter and the path arcs between the tiles. |
| 6 | all text | Widows like "word." and "grew." were left alone on a line. | nit | Yes. `text-wrap: balance` (SwiftUI wraps well enough by itself; no action). |
| 7 | AX | The art scaled down but clipped the keyboard row on p1. | must | Yes. The art box is 226 pt at AX, with scale 0.6. |
| 8 | AX | Long pages (p4) run under the footer. | should | Yes, partly. The page scrolls with a soft fade at the bottom edge. The Swift version must use a ScrollView per page, with the footer outside it. |
| 9 | Copy | Every string, including the words inside the art and the a11y labels, was checked against the 31 `CopySafety.banned` words plus locked, lock, unlock, lose, plus, ads, price and buy. | must | Passes: 0 problems (`node check-copy.mjs`). |
| 10 | Copy | p4 talks about rain and seeds, but Quiet Garden and Calm mode never rain. | must | Yes. `linesQuiet` variant (`?quiet=1`, shot `p4-quiet-light.png`). |
| 11 | p8 | No lock icons and no prices. "Soon" chips use a sprout icon and a dashed outline. A pot that needs Plus is not shown; Starlight is earned by play. | must | Yes |
| 12 | p8 | The 5-word title wraps to 2 lines at the default size. | nit | Accepted. It is within the 5-word rule and reads fine. |
| 13 | Layout | About 100 pt of empty space between the text and the dots on short pages. | nit | Accepted. It gives room for German or Spanish text and Dynamic Type L/XL. Could centre the text block vertically if the owner prefers. |
| 14 | Dark | The "Hello!" bubble (surface) is low contrast against the dark pink gradient, though the text stays readable. | nit | Not fixed. Could add a 1 pt line. |
| 15 | p1 | Wrong letters (C, O) are only dimmed. That matches the real keyboard, which also says "not in the word" to VoiceOver. | nit | n/a |
| 16 | Facts | "+5 points" falls in the real range (2 to 8 per play). The 5 stages Tiny, Sprout, Bud, Bloom and Full bloom come from `LifeStats.stageNames`. The level names come from the level map. | should | Checked |
| 17 | Grade | About 10 words per sentence. Words of 9 or more letters: challenge, butterflies (both are used in the app already). | should | OK |

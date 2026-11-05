# Grand Garden + Wild Weather mockups: critic review (2026-11-04)

Reviewed: all 21 PNGs in `shots/`, `screens.html`, `notes.md`. Checked against `docs/pm/endgame-and-events-spec.md` sections 0-5 and the house style in `rest-card/shots` and `tending/`.

**Overall:** The ceremony art is the strongest work in either set. It uses the real catalog plants, no confetti, a gentle palette and good light and dark versions. The weak half is the weather puzzle flow. It is framed as a "storm" for one Sunflower, but spec 5 describes a whole-garden "Weather puzzle" with a fixed, named sticker, a decoy tile and a full-size Skip. The Wild Weather setting also does not say plainly what drops. "What grows next" lists the wrong features: it shows seasonal cultivars, which the spec defers, and invents rank names.

## Endgame pick: A (Panoramic garden). Agree, with fixes.
A makes the player's own garden the reward, reads the journey from back to front, matches the night-garden rest card in dark mode, and doubles as the "Walk my garden" view. B centres the brand and its plants turn into specks. Use B's crown-on-wordmark as the **second beat** (spec 2.2: "then the Gardener's Crown appears on the wordmark") on Home after A closes, not as the ceremony itself. C becomes A's share sheet, as the notes suggest.

## Per screen

### A: Panoramic garden (a-light, a-dark, a-rm-*): KEEP, fix copy and layout
- **Title copy is wrong for this trigger.** "Your whole garden is in bloom!" is the *gold crown* moment (`allFullBloom`, spec 2.2: "Your whole garden is in full bloom"). The Grand Garden fires on `allFound`, when many plants may still be Tiny or Sprout. Use the title "Every plant found!" with the subtitle "You found all 50. What a garden!" Keep "in full bloom" for the gold crown.
- In the same vein, the panorama should draw each plant at its **earned stage**, not all at Full bloom. Otherwise it promises something the player has not reached, and the gold crown moment loses its payoff. Add a frame showing a mixed-stage garden.
- The light-mode sun (lower right) sits on top of the back row and clips the Puya and Bird of Paradise. Move the sun up into the sky band, or shrink it. In dark, the moon is in a good spot.
- The crown inside its medallion is small (about 90 pt wide inside a 230 pt disc). It is the named reward, so scale it to about 70% of the disc, or drop the disc and let the crown float over a soft glow.
- The back-row plants are about 30 pt tall and the rarest (level 5) are the hardest to see. Consider slightly larger back rows (less perspective), or a slow pan in "Walk my garden".
- There are three ways of saying the same thing: the pill "You earned the Gardener's Crown", the subtitle "Every plant found" and the chip "50 of 50 plants found". Keep the pill and one count. Drop the chip, or fold it into the subtitle.
- Reduce Motion still: same composition, no petals. Good. Confirm the 0.3 s fade honours Reduce Motion's cross-fade preference and does not slide.
- Dark: the fireflies are fine, and the hill contrast is good.

### B: Crown on the wordmark (b-light, b-dark): DROP as the ceremony, reuse the crown-on-wordmark element
- The plants in the wreath are about 34 pt and read as confetti, as the notes concede. The upper ring looks scattered.
- The same title error as A ("is in bloom").
- "The crown is yours to keep" is good copy, so use it in A.

### C: Garden postcard (c-light, c-dark): MOVE to A's share sheet
- **"Save to my album" uses "save", which is on the spec avoid list.** Use "Keep in my photos" / "Add to Photos". Also note the render.sh check missed this. Add the spec's extra avoid list (save, rescue, danger, destroy, warning, alert, too late) to the grep.
- The stamp covers the back-right plants. Move it to the white border.
- Under 13, Share must go through the grown-up check (the notes say so). Show the gated state in the mock.
- No Plus, ads or prices appear here. Good.

### What grows next (next-light/dark, next-large-dark): FIX
- **The tiles do not match spec 2.3.** The spec's tail is Golden blooms, Daily Bloom ranks and the Visitors' book.
  - "Seasons (Golden, Frosty, Blossom)" mixes golden blooms with seasonal cultivars, which spec 2.3.5 defers ("Later, not in this plan", art-heavy). Retitle it **Golden blooms**: "Care for a plant on 7 different days to make it golden." Show one gold-tinted plant and a "3 of 7" example.
  - The rank names are wrong. The spec uses **Seedling, Sprout, Bud, Bloom, Full bloom, Evergreen** (thresholds 1/10/30/75/150/300). Show the player's current rank with a word or tick ("You are a Bud"), not only the amber fill (colour-only meaning).
  - "Visitor Sanctuary" should be the **Visitors' book**: "A page for every visitor you meet, plus weather stickers."
- "A new word every day, with no end. Each day you play adds up." The copy is fine and avoids "only". Good.
- The footer "Your crown and all your plants stay with you." is good.
- The large-text frame reflows cleanly. Good. At AX3 the tile art should stack above the text.
- The mini crown at the top is very small (about 70 pt) and its flowers merge together. Make it bigger, or drop it.

### Weather puzzle, step 1 (rescue-light/dark, rescue-large-light): REDO framing, keep the board
- **Name and frame:** the spec calls this the **"Weather puzzle"**. "After the storm" / "The storm has passed" brings in a storm word the kid-facing kinds never use: the event was a **Big wind**. Header chip: "Big wind" with the wind icon. Title: "Weather puzzle". Subtitle: "Solve it to help your garden stand tall."
- **Whole garden, not one plant:** spec 4.2 says the puzzle restores *every* plant at once. The copy talks only about Sunflower. Show 2-4 bent plants in the header, or say "your garden".
- **The fixed bonus sticker is missing.** Spec 4.1/4.6: name it before play, e.g. "Solve it for a Windmill sticker." Put a sticker preview chip under the title. This is the main reason to play in Variant 1, and it is what keeps the puzzle from reading as a loot box.
- **No decoy tile:** the 10 tiles are exactly S-N-A-P-D-R-A-G-O-N. The storm tier needs one decoy, so add an 11th tile and re-lay the grid (it fits 4+4+3, or 6+5).
- **Skip must match Start in size** (spec 5: "the same size as Start, no confirmation"). "Skip for now" is a text link far below the board. Make it a full-width secondary button the same height as the primary.
- **Delete "No hearts are used."** Hearts are not part of this system and the line brings in a currency the child never saw. Use "Care will help it mend too."
- The daily cap is missing: show a "New puzzle" control, and render the over-cap state "That is plenty for today. Your garden will mend with care."
- "Picture clue soon" is a soft countdown cue (a rung that unlocks with time). Show it as an always-available next rung ("Picture clue") that becomes ready after the second peek, with no time word. Or keep it, but never pair it with a progress fill.
- The peeked "S" slot (amber with a dot) can read as a "given letter". Use a distinct peek mark plus a VoiceOver label ("S, peeked").
- Slots at 32 pt that cannot be tapped are fine because Take back and Clear are 48 pt. Keep that. At AX3, 10+ slots need two rows. Mock a 12-letter answer (e.g. "VENUS FLYTRAP" with a gap).
- The Variant 1 entry point is missing: the "A harder one" chip on the gentle tier (spec 5 table).

### Weather puzzle, step 2 butterflies (rescue2-light/dark): FIX
- Step 2 exists only in Wild Weather. Label it so, or show this flow only from the Wild Weather path.
- The same storm, hearts and Skip-size issues as step 1.
- "Snapdragon! Well done." is good, but the hero is Sunflower while the answer is Snapdragon, which mixes two plants. Make the answer a different word, or make the hero the snapdragon.
- The dark sky with grey clouds is on the moody side for a kid moment. Lift it toward the dawn blue used in light mode.
- The "swap a part after two tries" rule (spec 5) needs a visible control: "Try the other part".

### Mended (mended-light/dark, mended-rm-dark): FIX
- The copy credits the wrong cause. "Your care helped it mend" appears after *solving the puzzle*. Use "You solved it! Your whole garden is standing tall." Keep "Your care helped it mend" for a mend by care (Variant 1), which needs its own small in-place moment on the plant page, not a full screen.
- **Show the fixed sticker that was promised**, next to the badge step: "New sticker: Windmill" / "Weathered: 1 of 3". The badge name is "Weathered" (tiers 1/3/7/15). Drop "the storm".
- The rainbow is a lovely, calm payoff. The sun overlaps the rainbow arc in the upper right, so separate them.
- Dark: a full sun in a night-navy sky is inconsistent with A-dark's moon. Use a dawn sky.
- The Reduce Motion still reads well.

### Wild Weather setting (settings-light/dark): REDO the copy
- **It is not honest about the drop.** Spec 4.2 and 9.2 require the player to know that the *shown stage* drops. "A storm may bend a plant" understates it. Proposed rows:
  - "On big weather days, up to 4 plants show one stage smaller."
  - "Your word level and everything you earned stay the same."
  - "A harder puzzle brings them all back. Care does too, and they always come back within 4 days."
  - "No timer. You can turn it off any time."
- "Off means calm skies, always" is **false**. With Wild Weather off, Variant 1 garden weather still happens. Add the separate **Garden weather** toggle (spec 4.5, on by default at 13+ and off in Calm), place Wild Weather under it, and indent or disable Wild Weather when Garden weather is off.
- Add "Tell me about garden weather" (notifications, off by default, hidden under 13) to complete the set.
- Remove "No hearts are used."
- The lightning bolt in the cloud icon is an alarm or danger cue. Use a cloud with wind lines.
- "Storm" again: say "big weather day" instead.
- Gating: the spec says 13+ players turn it on themselves with a **confirmation card**, and the parental gate applies only for under-13. "A grown-up check comes first" plus "For grown-ups" is fine for under-13 profiles, but mock the 13+ confirmation card as well. Hide the row entirely in Calm and Quiet Garden.
- The off toggle in dark has a low-contrast track against the card. Check it is at least 3:1.

## Top 8: must fix in the revision round
1. **Make the Wild Weather settings honest and correct:** say plainly "up to 4 plants show one stage smaller on big weather days", "word level never changes" and "always back within 4 days". Remove the false "Off means calm skies". Add the Garden weather toggle and the forecast-notification toggle.
2. **Add the fixed named sticker to the Weather puzzle** (before play, "Solve it for a ... sticker") and show it on the mended screen. This is the core spec rule that keeps it from being a loot box.
3. **Rename and reframe the puzzle:** "Weather puzzle", with the kind's kid name (Big wind) in place of "storm". Make it whole-garden, not one Sunflower. Remove "No hearts are used" everywhere.
4. **Fix the ceremony title for A:** "Every plant found!" at `allFound`, with "in full bloom" reserved for the gold crown. Draw plants at their earned stage.
5. **Puzzle mechanics to the spec:** add one decoy tile, make Skip the same size as the primary, add the daily-cap state and "New puzzle", and add the Variant 1 "A harder one" entry.
6. **Make "What grows next" match spec 2.3:** Golden blooms (7 care days), ranks Seedling/Sprout/Bud/Bloom/Full bloom/Evergreen with the current rank shown in words, and the Visitors' book. Drop seasonal looks.
7. **Polish layout and quality in A:** move the sun off the back row, enlarge the crown, merge the three redundant "found" lines, use B's crown-on-wordmark as the follow-up Home beat, and turn C into the share sheet with "Keep in my photos" (no "save").
8. **Match the mended moment to its cause:** "You solved it! Your whole garden is standing tall" plus the sticker and a "Weathered" badge step. Use a dawn sky in dark, separate the sun from the rainbow, and add the spec avoid list (save, rescue, storm framing) to render.sh's word check.

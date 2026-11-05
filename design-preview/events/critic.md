# Weather days mockups: critic review (2026-11-04)

Reviewed: all 30 PNGs in `shots/`, `mock.html`, `notes.md`. Checked against `docs/pm/endgame-and-events-spec.md` sections 0-5 and the house style in `rest-card/shots` and `tending/`.

**Overall:** The art is calm and in house style. The palette is soft, nothing flashes, there is no red and no clock, the termites look friendly, and light and dark match well. Five things need fixing. (1) The plant traits are wrong on three of the seven event screens. (2) The growth bar uses made-up stage names and makes earned growth look as if it went away. (3) The Shed contradicts the spec: it locks a helper, says "You earn these by playing" and names the wrong helper. (4) Helpers are shown on one plant, but the spec says they cover the whole garden. (5) The single "Help it mend" button hides the real mend action. None of the screens would scare a 6-year-old.

## Per screen

### warn-dry / warn-wind (forecast card on Home): FIX
Good: the sky art has a smiling sun, the steps are numbered so order does not depend on colour, there is one primary button and a quiet link, and the copy reads at grade 2. No urgency cues.
- The steps are the same for every kind. "Water your plants today" fits a dry spell but does nothing against wind. Use the spec wording, "Give a drink or a hello today," and keep only the helper step specific to the kind.
- Step 2 sends the player to the Shed, but spec 3.7 says the helper is set out with one tap on the forecast card. Add a "Set out the wind net" button on the card (secondary style, at least 44 pt), and once it is out, show a checked "Wind net is out" state there.
- Show the helper-arrival line the first time a kind is forecast: "A wind net for you, from the Shed." No card shows the moment a helper arrives yet.
- warn-wind art: the hero is a tulip. Big wind's full-effect plants are tall ones, so draw a sunflower or snapdragon to teach the trait.
- The step circles in dark use a blue-grey ring on a dark card. Check that the ring is at least 3:1 against the card (WCAG 1.4.11 for graphics).
- Mock the event-day banner that replaces this card (spec 3.8). Today there is no event-day entry point for the puzzle.

### chips (header chip, widget, lock-screen line): FIX
- The check on a single plant tile ("a check on a plant means its helper is set out") contradicts spec 3.7, where one helper covers the whole garden. Drop the check from tiles. The chip "Windy: net is out" is enough.
- The lock-screen line "Tomorrow: windy" could read as a real weather alert. Spec 3.8 says the garden must be named: "Garden: a little windy tomorrow." Apply the same fix to the widget title ("Garden forecast: big wind").
- The widget line "Water today and set out the wind net." reads as a chore. Use the spec line: "Tomorrow: a little windy. Your garden is ready." Once the helper is out, say "The wind net is out."
- The chip's height is about 30 pt. It is tappable ("Tap it to see the get-ready steps"), so give it a 44 pt hit area.
- "Tomorrow: dry" and the dry/hot icon are the same sun. Give hot day its own glyph (sun with heat lines) so the icon is not the only cue that differs.
- The body text explaining the chip is a designer note, so mark it as one. It should not appear in the app.

### dry (Daisy, dry spell): FIX
- Trait: Daisy is not shade, aquatic or bog, so it gets the **light** look. This screen shows a strong droop plus cracked soil, which is a full look. Either make it the light look (a slight lean, no cracks) or switch the hero to **Fern** or **Lotus**, which get the full effect.
- The cracks are drawn on the pot itself. Spec 3.7 says pots have no weather effect, and a cracked pot reads as "broken" to a child. Put the cracks in the soil only.
- Stage path labels are wrong everywhere. "Seed, Sprout, Leaves, Bud, Bloom" must be **Tiny, Sprout, Bud, Bloom, Full bloom** (`LifeStats.stageNames`). This applies to every screen with a growth card.
- "Help it mend" is vague. In Variant 1 a single care action mends, so the primary button should *be* that action: "Give Daisy a drink" (and "Say hello" as a secondary). Put the puzzle in a third, quiet entry: "Weather puzzle: win a Rainbow sticker." The footer "A puzzle is a bonus" becomes redundant.
- "A drink and a hello will perk it up" suggests two actions are needed. Spec 3.6 says one. Use "A drink or a hello will perk it up."

### bugs (Fern, busy bugs): REDO the subject, keep the art style
- Trait error: busy bugs hit **woody** plants (Rose, Bamboo, Cherry Blossom, Jasmine). Fern is shade, so it gets the light look. Redraw on a Rose or Bamboo with tiny nibble marks on the stem, keeping the crumbs.
- The termites are friendly (big eyes, no holes) and pass the 6-year-old test. Three bugs crawling on the plant is the busiest image in the set, though. Two bugs, with one on the soil, would be calmer.
- "Just tiny nibbles. Fern is okay." The tone is good. "Just" is fine, but keep "only" out of any variant.

### wind / wind-rm (Tulip, big wind): FIX
- Trait error: Tulip is not tall, so it gets the light look. The hero for the full bend should be Sunflower or Snapdragon. The endgame puzzle already uses a storm-bent Sunflower, so match it.
- Rain streaks plus a big wind give a storm reading. Hail and puddles have their own kinds, so keep wind dry: leaves and petals drifting, no rain. Rain also muddies the Reduce Motion still.
- There is a nick on the tulip petal and a petal flying off. Losing a petal reads as damage. Keep a leaf drifting, but leave the flower whole.
- The "Reduce Motion: still picture" label overlaps the cloud. It is a review label, so move it outside the art frame and keep it out of the app.
- The Reduce Motion still keeps the bent pose and streaks. Good.

### frost (Lavender, frosty night): KEEP with small fixes
- Lavender is not tropical, so it gets the light look, and the soft rim fits that. A full-effect example (Orchid, Hibiscus) would teach the trait better.
- The frost rim is barely visible on a light-blue sky. Make it slightly crisper, or add a frost sparkle on the leaves so the change does not depend on colour alone.
- The pot is tinted grey-blue. That is fine as lighting, but do not make it look damaged.

### heat (Sunflower, hot day): FIX
- The copy says "Sunflower is droopy", but the art shows an upright, healthy sunflower. Add a visible droop (head tilted down, softer leaves), or soften the copy to "Sunflower feels warm."
- Trait: hot day hits shade and aquatic plants, so the full look belongs on Fern or Lotus. Sunflower should get the light look.
- The icon is the same as dry spell (see chips).
- "Some water and shade will help" suggests two steps. Use "A drink or a hello will cool it down."

### hail (Marigold, hail shower): FIX
- "Marigold has a nick" names damage. Use "Hail is bouncing off Marigold" / "A hello will help it shake off the ice."
- The hail dots in dark mode are pale-outlined circles that read as bubbles. Make them icy white pebbles with a soft highlight.
- Trait: hail hits bigLeaf plants (Hibiscus, Giant Water Lily, Bird of Paradise). Marigold gets the light look. Fine as long as the look stays light.

### flood (Tulip, big puddles): FIX
- "Water is up to the rim of the pot" plus a pot that is visibly sinking is the one image that could worry a small child (drowning). Lower the water to a shallow puddle around the base, and use "Tulip has wet feet. A sunny hello will help."
- Trait: big puddles hit desert and succulent plants (the irony is nice). The full look should be on Saguaro or Aloe. Tulip gets the light look.
- The pot turning grey-mauve under water reads as a tint change on the pot itself. Keep the pot its own colour and tint only the water.

### shrug (Lithops, dry spell): KEEP
The best screen in the set. It has a proud line ("Lithops loves dry days!"), a green pill with words, the bar is not resting, and the button says hello.
- Fix the stage labels (Tiny ... Full bloom).
- The pill "Dry spell: Lithops is fine" works, but "Dry spell: Lithops loves it" is warmer.
- Footer: "Desert plants shrug off a dry spell." Delete "Nothing to mend." The word "mend" on a fine plant is noise.

### bar (growth path explainer): REDO
- The core problem: in "Sunny day" the bar has partial green progress toward the next stage. In "Weather day: resting" that partial fill is gone (it becomes dotted). That *shows* growth being taken away, which is exactly what Variant 1 promises never to do. Spec 4.1 says growth keeps adding as normal. Keep the earned fill exactly as it is, and show the weather only as a soft tint or dotted *overlay ahead* of the current fill, plus the pill.
- "After a little care: the dotted part fills in with green as you water, say hello or solve the puzzle" implies several actions and partial refills. Spec 3.6 says one action mends at once. Show two states only: weathered, and mended.
- "Care fills it back up" (on every event screen) implies something was emptied. Replace it with "Growth keeps going. Care helps it shake off the weather."
- "Resting" is already the rest card's word ("The garden is resting"). Reusing it for weather blurs two systems. Use a weather word on the pill instead: "Windswept", "Thirsty", "Chilly". The pill then also carries meaning without colour.
- The dotted line used for Wild Weather's shown-stage drop (spec 4.2) is a *different* state. Reserve the dashed "mending" segment for that, so the two never look alike.
- Stage labels: Tiny, Sprout, Bud, Bloom, Full bloom.

### shed (Weather helpers): REDO
- "You earn these by playing" is wrong. Spec 3.7 says helpers are free and arrive with the first forecast of their kind. Use "Helpers come free with a forecast. Set one out the day before."
- Raised bed is locked with "Grow 6 plants to find it." The spec says there are no "not yet earned" helpers. Remove the locked state. A helper that has not arrived yet simply does not appear, or shows "Comes with your first big puddles forecast" with no condition to meet.
- "Umbrella / Shields from hail and big wind" should be **Garden umbrella / Keeps hail off.** The wind net is the wind helper, so do not give two helpers for one kind.
- "Set out" sits on every helper at all times. Spec 3.7 says you can only set one out on the day before or on the event day. Show "Set out" only on the helper for tomorrow's (or today's) kind, and show the rest as a calm "Ready" label with no button.
- Order the list by spec (shade cloth, bug cover, wind net, frost cloth, garden umbrella, raised bed), or put the forecast-relevant one first.
- "A cosy sheet": check whether the app uses US English ("cozy"). Match the existing strings.
- Dark: the dimmed locked row text ("Grow 6 plants...") is low contrast. This goes away once the locked state is removed.
- The icons are consistent and in house style (brown ring, flat fill). Keep them.

### set-wind (net set out on Tulip): FIX
- The net is drawn around a single pot. Spec 3.7 says the helper covers the whole garden, and the plant page shows the helper around the pot. That part is fine, but the copy should say "The wind net is out for your whole garden."
- "Take the net in" plus "Helpers go back in by themselves" is an extra choice with no purpose. Taking the net in only invites a mistake. Drop the link and keep the footer line.
- The footer line is clipped at the bottom edge of the 852 pt frame. Add bottom padding and check it at large text.
- The net's thin dark diagonal lines over the flower create visual noise (moire) at 1x. Use fewer, softer, thicker strands.
- Stage labels (see above).

## Accessibility notes (all screens)
- Dynamic Type: no large-text frames were rendered for this set. Render the forecast card, a plant page and the Shed at AX3. The 3-step card and the bar labels are the most likely to clip.
- Reduce Motion: there is a still for wind only. Spec 3.9 asks for stills for every kind. Render at least dry and bugs (the crumbs fall).
- VoiceOver: the bar needs a single label ("Growth: Sprout reached, Bud next. Windswept today.") and must not read 5 separate circles.
- Light and dark parity is good across all pairs.

## Top 8: must fix in the revision round
1. **Growth bar must never shrink earned fill.** Keep the earned green as it is in weather. Show weather as a pill and tint only. Show only two states (weathered, mended), and replace "Care fills it back up". (bar, every event screen)
2. **Fix the plant traits on the hero screens:** bugs on Rose or Bamboo (not Fern), wind on Sunflower or Snapdragon (not Tulip), dry spell full look on Fern or Lotus (or make Daisy's look light), puddles full look on a desert plant, heat full look on a shade plant.
3. **Use the real stage names:** Tiny, Sprout, Bud, Bloom, Full bloom (drop "Seed" and "Leaves").
4. **Rebuild the Shed to the spec:** helpers free with the first forecast, no locked "Grow 6 plants" row, correct names ("Garden umbrella" for hail only), "Set out" only for the forecast kind, and new header copy.
5. **One mend action, said plainly.** Replace "Help it mend" with the real action ("Give Daisy a drink" / "Say hello"), and use "a drink *or* a hello". Add a separate quiet entry that names the puzzle's fixed sticker ("Weather puzzle: win a Rainbow sticker").
6. **Helpers cover the whole garden:** no per-plant checks on tiles, "out for your whole garden" copy, a one-tap set-out on the forecast card, and remove "Take the net in".
7. **Remove the damage cues:** no cracks on the pot, no torn or nicked petals ("has a nick"), no water up to the pot rim, no rain in big wind, and a heat droop that matches its copy.
8. **Name the garden in outside-the-app lines,** and finish the a11y set: lock screen and widget say "Garden ...", the header chip gets a 44 pt hit area, hot day gets its own icon, the "Resting" pill becomes a weather word, and add AX3 and Reduce Motion stills for every kind.

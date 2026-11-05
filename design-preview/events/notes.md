# Weather days: mockup notes

Direction: "Weather, not loss". An event changes how plants LOOK and how the growth bar DISPLAYS. Nothing earned is removed. Care (water, hello, optional rescue puzzle) mends it. Desert plants shrug off drought. Shed helpers set out the day before soften it.

## Files
- `mock.html?s=<screen>&theme=light|dark[&rm=1]` is the single source (CSS/SVG over the existing `plants/*.svg`). `render.sh` makes `shots/*.png` (15 screens x light/dark, 393x852 @2x). `index.html` is the gallery.

## Decisions
- Warning card: sky illustration (no clock, no red, no alarm icon), a title, "Here is how to get ready.", three numbered steps (numbers, not colour, carry order), "Got it" as the one primary button, "Open the Shed" as a quiet link. The same chip ("Tomorrow: windy") is reused in the garden header, widget and lock-screen line; a check on the chip or plant means a helper is set out.
- Looks are calm by design: one hue per event for the sky and the pill, a soft haze, no dark storms, no flashes. Wind uses gentle sway (5 s) and slow-drifting rain; the Reduce Motion still keeps the same bent plant and streaks with all animation off. Nothing flashes at all.
- Busy bugs: three cartoon termites with big eyes, tan crumbs falling; no holes, no gore.
- Every state is told three ways (colour + shape + word): the pill names the event, the caption says what happened, the growth bar uses a dotted line, dashed circles and the word "Resting".
- Growth bar: stages never disappear. The next part just rests (dotted); care fills it with green. A line says "Everything you earned is still here."
- Shrug-off: Lithops in a dry spell looks fine, gets a green "fine" pill, and a "Say hello" button instead of a mend button.
- Shed: "Weather helpers" in the same card style as tools. Earned by play, no prices, no Plus tag. Not-yet-found tool shows how to earn it ("Grow 6 plants to find it.") with the icon dimmed but the text at full contrast. "Out" state is a green outlined button with a check.

## Copy
Grade 2-3, positive only. Kid names: Dry spell, Busy bugs, Big wind, Frosty night, Hot day, Hail shower, Big puddles. Visible text was checked against the banned-word list.

## Known weaknesses / open questions
- Droop is a transform on a flat SVG (tilt + squash), so it reads subtly on the daisy; real art would swap leaf shapes.
- The nick on Marigold is small; the frost rim is a soft white glow, not crisp frost.
- Net and umbrella are shown only for wind (set-wind); other helpers share the same pattern.
- Which helper works for which event is placeholder; it needs design/economy sign-off.
- Rescue puzzle itself is not mocked.

## Revision 1
Changed after the critic review and the updated spec (sections 3.5-3.7, 4.1, 4.6):
- Heroes follow the traits table: Fern (dry spell, full), Daisy (dry spell, light), Rose (busy bugs), Sunflower (big wind), Orchid (frost), Lotus (hot day), Hibiscus (hail), Aloe (big puddles), Lithops (shrugs off dry spell).
- Damage cues removed: no cracks on pots (soil only), no nick, no petal loss, no rain in big wind, shallow puddle on the floor only, the pot keeps its colour. Heat now droops to match its words.
- Growth bar: earned green never changes. Stage names Tiny, Sprout, Bud, Bloom, Full bloom. Two states only: weathered (soft tint plus a weather word: Thirsty, Bug visit, Windswept, Chilly, Warm, Icy, Splashed) and mended. No "Resting" and no dotted fill. One single VoiceOver label.
- Main button names the real action (Give Fern a drink / Say hello to Rose). Under it, a Weather puzzle card names the fixed Frog friend sticker and the word toward the next plant. "Skip is free." sits below.
- Shed: all six helpers arrive free as a weather kit ("A weather kit for you, from the Shed."), shown on a Home card (kit) and in the Shed. Only tomorrow's helper has a "Set out" button; the others read "Ready". No lock, no earn line, no per-plant checks.
- Forecast card: "Give a drink or a hello today." plus a one-tap "Set out the wind net" on the card, then a checked "out for your whole garden" state. Event-day banner with the puzzle entry added.
- Snug frame (snug): net over the whole garden, rain beading on it, plants upright and happy. The same pattern would apply to frost cloth and raised bed.
- Widget and lock-screen lines name the garden. Chip is 44 pt tall. Hot day has its own icon. Designer notes are dashed boxes marked "not in app".
- New frames: Reduce Motion stills (wind, dry, bugs, no motion trails) and large-text frames (forecast, plant page, Shed).
- Still open: frost cloth and raised bed snug frames are not drawn; the droop is a transform on flat art.

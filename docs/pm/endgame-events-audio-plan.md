# Weather days and Grand Garden: audio plan

Prototype only. Nothing here is in the app bundle. Regenerate with `python3 tools/make_weather_sounds.py` (renders to `tools/out/weather/`, WAV + m4a, plus `index.html` for listening over file://). Pattern follows `tools/make_thunder.py` and section 9 of `docs/research/audio-feedback.md`.

## Measured prototype (ffmpeg, m4a at 64 kb/s mono)

| File | Dur s | Peak dBFS | LUFS | KB | Budget |
|---|---|---|---|---|---|
| wf-wind-loop | 8.00 | -14.7 | -30.0 | 65 | 120 |
| wf-storm-loop | 8.00 | -19.5 | -30.3 | 65 | 120 |
| wf-drought-loop | 6.00 | -17.4 | -30.0 | 49 | 120 |
| wf-termite-tick | 1.20 | -10.5 | -25.4 | 10 | 60 |
| wf-relief-chime | 1.80 | -10.4 | -22.6 | 15 | 60 |
| wf-grand-flourish | 3.00 | -10.5 | -24.4 | 25 | 60 |
| wf-frost-twinkle | 1.40 | -10.5 | -18.3 | 12 | 60 |
| wf-hail-patter | 1.60 | -9.9 | -27.4 | 18 | 60 |

Total about 260 KB, roughly 9% of the ~3 MB audio budget. Playback volume in the app should multiply these (one-shots at about 0.35 to 0.5 of the player level, beds at 1.0 of their already quiet level, then the global ducking below).

## Rules shared by every sound

- Audio session `.ambient`: respects the silent switch, mixes with the child's own music, never interrupts. Weather audio never starts the session itself.
- Gates (all must pass, same family as thunder): Sound setting on, not Calm mode, not Quiet Garden, page on screen, app active. Any sound that fails a gate is skipped silently, and the visual still tells the story.
- Reduce Motion: visual weather simplifies; the beds still play (they are not motion), but one-shots tied to moving visuals (hail patter, frost twinkle, termite tick) are skipped.
- Low Power Mode: beds are off (continuous decode and mix), one-shots stay.
- Every start is a volume ramp (beds 400 to 800 ms in, 600 ms out); one-shots have baked 30 to 40 ms soft attacks. No sound has a sharp onset, siren, alarm, realistic insect, or voice.
- Ducking: while a bed plays, the garden ambient bed ducks by about 6 dB and read-aloud ducks the weather bed by about 12 dB. A one-shot dips the weather bed by 4 dB for its length. Use the existing two-reason `DuckState` extended with a weather reason.
- Never stack: one weather bed at a time (the current weather day); a new bed cross-fades over 800 ms. One-shots of the same kind never overlap; the relief chime and flourish cancel any other one-shot.
- Haptics are always optional and follow the same gates plus the system haptics setting. A haptic is never felt before its sound or visual starts.
- Files are m4a. AAC adds encoder padding, so loop beds with a player that supports gapless m4a looping, or ship the beds as CAF/PCM if a click shows up on device (open question 1). The loop seams are built into the audio (tail cross-faded into head) so a clean loop point is exact in the WAV.

## Sounds

### wf-wind-loop (big wind, hurricane day)
- Purpose: soft moving air under the leaning plants. Not a howl.
- Trigger: plant page on a wind day while plants are swaying; stops when the day ends or the rescue completes.
- Duration/loop: 8 s, loops seamlessly; gust modulation repeats exactly every 8 s.
- Loudness: -30 LUFS, peak -14.7 dBFS. No baked fade, the player ramps volume in at least 400 ms.
- Ducking: ambient bed -6 dB; read-aloud ducks it -12 dB.
- Frequency: continuous while the page is open on a wind day; starts once per page visit, never restarts on state changes.
- Gates: standard. Reduce Motion: plays, but at -3 dB. Low Power: off.
- Haptic: none.
- Kid safety: band-limited 90 Hz to about 1.5 kHz, slow gusts, no whistle.

### wf-storm-loop (soft storm, puddles, flood)
- Purpose: gentle rain hush with low wind for rain-heavy days.
- Trigger: puddle/flood days, on the plant page.
- Duration/loop: 8 s loop, seamless, no thunder, no cracks. Thunder stays the separate `wf-thunder` one-shot under its own gate.
- Loudness: -30.3 LUFS, peak -19.5 dBFS.
- Ducking: as wind. Thunder roll ducks it -4 dB.
- Gates and Low Power as wind. Haptic: none.
- Kid safety: soft high-frequency hush only; the noise texture is low-passed modulation, no droplets with an edge.

### wf-drought-loop (dry spell, hot day)
- Purpose: very low, warm, still air with a faint high shimmer (like dry-grass warmth). The mood is calm and sleepy, not tense.
- Trigger: dry spell and hot day pages.
- Duration/loop: 6 s loop, all partials are integer Hz so it repeats exactly.
- Loudness: -30.0 LUFS, peak -17.4 dBFS. Hum fundamentals at 55, 110, 165 Hz are mostly inaudible on a phone speaker; the shimmer (2.9 and 3.14 kHz, 3 to 5 Hz soft beating) carries it there. Listen on device for the unsettling check (open question 3).
- Ducking and gates as wind. Haptic: none.
- Kid safety: shimmer is two sine partials with slow swells, no noise burst, no buzzing at insect rate.

### wf-termite-tick (busy bugs)
- Purpose: a few tiny wooden taps to say small helpers are busy at the plant.
- Trigger: when the bug day starts and again when the player taps a bug in the rescue puzzle (soft feedback).
- Duration: 1.2 s, five sparse ticks, 30 ms attack.
- Loudness: -25.4 LUFS, peak -10.5 dBFS.
- Frequency: once per page visit on bug-day start; per tap at most 1 per 400 ms. Never loops.
- Gates as standard. Reduce Motion: skipped. Low Power: plays.
- Haptic: one very light tick per tap, never during the start sound.
- Kid safety: marimba-like pitched taps near 740 to 1010 Hz, no rasp, no chitter, no buzz.

### wf-relief-chime (recovery)
- Purpose: reward and relief when the rescue puzzle is solved.
- Trigger: the moment the plant recovers (visual leaf lift).
- Duration: 1.8 s, four rising pentatonic notes (C5, D5, G5, C6) with a soft E under the last. Bell/kalimba, 35 ms attack, 0.4 s release.
- Loudness: -22.6 LUFS, peak -10.4 dBFS.
- Ducking: stops the weather bed with a 600 ms fade as the day ends; ambient bed ducks -6 dB while it rings.
- Frequency: once per recovery, never stacked with the flourish (the flourish wins).
- Gates standard; Reduce Motion plays (it is not motion); Low Power plays.
- Haptic: one soft success tap on the first note.
- Kid safety: no sudden onset, no sharp bell strike, peak -10 dBFS.

### wf-grand-flourish (all 50 plants found)
- Purpose: gentle celebration of the Grand Garden.
- Trigger: once when the Grand Garden screen first appears after the 50th plant, plus an optional replay when the player taps the celebration.
- Duration: 3.0 s, eight-note rising pentatonic run into a soft blooming chord, 40 ms attack, 0.9 s release.
- Loudness: -24.4 LUFS, peak -10.5 dBFS (its own attack reads about 0.6 s, so it blooms).
- Ducking: ambient bed -8 dB for the length; weather beds are off on that screen.
- Frequency: once per celebration; replays no more than once every 10 s.
- Gates standard; Reduce Motion plays; Low Power plays.
- Haptic: a soft double tap at the chord bloom (about 1.45 s in), not at the start.
- Kid safety: no cheer, no crowd, no fanfare brass.

### wf-frost-twinkle (frosty night, optional)
- Purpose: a few very soft high glints as frost settles.
- Trigger: frost day start, once per page visit. Duration 1.4 s, 35 ms attack.
- Loudness: -18.3 LUFS, peak -10.5 dBFS. Hottest by LUFS because it is mostly high sine energy; consider dropping 3 dB in the app (open question 4).
- Gates standard; Reduce Motion skipped; Low Power plays. Haptic: none.
- Kid safety: sine partials at 2.1 to 3.1 kHz, short, no glass-shatter feel.

### wf-hail-patter (hail, optional)
- Purpose: tiny soft taps as hail lands on leaves.
- Trigger: hail day start, once per page visit. Duration 1.6 s.
- Loudness: -27.4 LUFS, peak -9.9 dBFS. 30 ms attack on every tap, band-passed noise 1.5 to 3.2 kHz, thinning towards the end.
- Gates standard; Reduce Motion skipped; Low Power plays. Haptic: none (hail taps would feel like alarms).
- Kid safety: no rattle at constant rate; tap spacing is irregular and quiet.

## Size budget

About 260 KB across the eight files against ~3 MB: beds 179 KB, one-shots 81 KB. If size matters, shorten the storm and wind loops to 6 s (about 50 KB each).

## Licence statement

All eight sounds are fully original, rendered procedurally by `tools/make_weather_sounds.py` (pure Python standard library, fixed seeds 1101, 2202, 3303, 4404, 5505, deterministic WAV output). Nothing is sampled, no third-party audio, no library, no attribution required. The m4a files come from the system ffmpeg AAC encoder.

## Open questions for listening on a device

1. Do the beds loop without a tick on device as m4a? If not, switch beds to CAF or look at the encoder padding.
2. Is -30 LUFS right for beds under the garden ambient and read-aloud, or should they sit at -33?
3. Does the drought shimmer read as warm and sleepy or slightly tense on a phone speaker and on headphones?
4. Frost twinkle is the loudest by LUFS; trim 3 dB?
5. Does the soft storm bed sound too close to white noise or a shower at 64 kb/s? Try 96 kb/s for the two noise beds.
6. Does the termite tick read as woody and friendly, or as a clock? Does it need fewer ticks?
7. Should the relief chime and flourish share a note (C6) so they feel like one family?
8. Is Reduce Motion skipping the three event one-shots the right call, or should they play at lower level?

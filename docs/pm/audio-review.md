# Audio review (read-only)

Date 2026-11-07. Scope: every sound the app ships or can make, measured with ffmpeg, afinfo and Python standard library only (no numpy installed). Nothing in the app, the bundle or the generators was changed. mediaanalysisd was not touched.

Method. Each file in `WordFlora/Resources/Sounds/` was decoded to 16-bit mono 44.1 kHz and measured: sample peak, RMS, DC offset (mean), count of samples at or above 0.999 (clipping), silence at head and tail (50 ms windows under -50 dBFS), EBU R128 integrated loudness and true peak. Files under 1 s have no integrated LUFS (the gate needs 400 ms blocks, ffmpeg prints -70), so those were looped 12 times and re-measured; the LUFS column is that figure. "In-app" levels add the catalog gain, the 0.8 master volume (-1.9 dB) and any per-call volume. Petal notes are synthesized at run time, so they were re-rendered here from `PetalNotes.samples` and measured the same way.

## 1. Headline findings

1. No clipping, no DC problem and no leading silence anywhere. Largest DC offset is wf-soil at -0.00098 (about -60 dBFS), inaudible.
2. Nothing is more than 6 dB louder than the rest. In-app action sounds span -21.2 to -24.2 LUFS (3 dB spread); weather one-shots sit 8 to 15 dB under them; thunder and the garden bed are quieter still. Nothing needs a level change for loudness.
3. Brightest and most likely to read as harsh for small ears: `wf-snip` (almost all energy above 4 kHz, 71 ms to peak, and the only file with a boost, +0.9 dB, so it has the highest in-app peak at -4.3 dBFS). It is 0.11 s long and only plays on a prune, so this is a listen-on-device item, not a bug. Second: `wf-water` (noisy, -6.5 dB of energy over 4 kHz) which is also what stands in for the mist.
4. The loop beds loop cleanly at sample level (wrap step is at or below the file's own 99.9th-percentile step). The gapless information is present in the bundled m4a files (afinfo shows exact valid-frame counts: 352800 / 352800 / 264600). Whether AVAudioPlayer plays AAC loops without a tick on a real device is still the open question 1 from the audio plan; it cannot be proven from files.
5. The eight untracked `tools/out/weather/*.wav` are exact regenerations of the same procedural sounds. Recommendation: delete them (or add `tools/out/**/*.wav` to .gitignore); do not commit (section 5).
6. Mist: the stand-in is quiet and safe (about -31.8 LUFS in-app) but it is a pouring splash, not a hiss. A procedural hiss is cheap and worth making (section 6).

## 2. What plays which sound

Every sound goes through one of three players, all on the `.ambient` session (silent switch respected, mixes with the child's own audio).

SoundPlayer (`Audio/Sound.swift`, `SoundCatalog` gains), master 0.8, per-play jitter of +-5% volume and +-3% pitch:

| Event | File | Played by |
|---|---|---|
| key | wf-key | `GameViewModel` key press (via `sounds.play`) |
| correct | wf-correct | `GameViewModel.swift:198` correct letter |
| wrong | wf-wrong | `GameViewModel.swift:203` wrong letter |
| word | wf-word | win sound, `CelebrationStyle.winSound` |
| earned | wf-earned | win with a new plant; `ButterflyView.swift:444` |
| levelUp | wf-levelUp | win that levels up; `AppModel+Endgame.swift:36` |
| rest | wf-rest | lost word, `GameViewModel.swift:379` |
| wake | wf-wake | plant woken (`AppModel.swift:241, 655`), weather solve default |
| water | wf-water | Water tend (`TendAnimation.sound`), onboarding `OnboardingView.swift:285`; also the Mist Maker stand-in |
| soil | wf-soil | Soil and Repot tends |
| sun | wf-sun | Sun tend |
| snip | wf-snip | Prune, `PlantDetailView.swift:641` |
| butterfly | wf-butterfly | net catch (`ButterflyView.swift:376`, 0.7 volume when gentle), wake mini-game `WakeSheet.swift:288` |
| badgeBronze / Silver / Gold | wf-badge* | `AppModel.swift:799`, by tier |
| button | wf-button | Visitors Book row, `VisitorsBookView.swift:93`, volume 0.5, not in Calm |
| ambient | wf-ambient.caf | garden bed, looped at fixed volume 0.25 (not master), ducked to 0.08 for read-aloud, thunder and weather beds |
| thunder | wf-thunder | `AppModel.rollThunder`, volume 0.35 (`ThunderGate.soundVolume`), once per visit, 3 minute cooldown, ducks the ambient bed |

Rain: there is no rain sound file or rain event. `RainOverlay` is visual (rain canvas, lightning flash) plus haptics; its only audio is the thunder roll above. The rain-like audio is the storm bed `wf-storm-loop` (puddle and flood days).

WeatherSoundPlayer (`Audio/WeatherSound*.swift`), level = master 0.8 x the share shown, gated by Sound on, not Calm, not Quiet Garden, on screen, app active; beds off in Low Power; hail/frost/termite off under Reduce Motion; wind bed -3 dB under Reduce Motion; read-aloud ducks a bed 12 dB; a one-shot dips a bed 4 dB:

| Sound | File | Share | When |
|---|---|---|---|
| windBed | wf-wind-loop | 1.0 | big wind day, loops |
| stormBed | wf-storm-loop | 1.0 | puddles day, loops |
| droughtBed | wf-drought-loop | 1.0 | dry spell and hot day, loops |
| termiteTick | wf-termite-tick | 0.45 | bug day arrival; each bug tap in the puzzle, at most one per 400 ms |
| reliefChime | wf-relief-chime | 0.5 | rescue solved (also ends the bed) |
| grandFlourish | wf-grand-flourish | 0.5 | 50th plant; replay at most once per 10 s |
| frostTwinkle | wf-frost-twinkle | 0.354 (0.5 x 0.708, the 3 dB trim) | frosty night arrival |
| hailPatter | wf-hail-patter | 0.45 | hail day arrival |

PetalSynth (`Audio/PetalSynth.swift`, `Rules/PetalNotes.swift`): no file. A run-time sine plus a quiet octave, C5 D5 E5 G5 A5, 0.9 s, 10 ms rise, exponential fall to exact zero. A petal tap plays one note; the love flower plays all five 0.16 s apart. Volume 0.45, Calm 0.22, Sound off 0 (not scaled by the 0.8 master).

Key taps: wf-key is played by the game view model for the on-screen keyboard and is suppressed by the same Sound setting; the haptic pairing is `GameHaptics` (light impact on a correct letter, soft impact when petals drop, success on a win; never `.error`). Other haptics: petal tap `.impact(soft, 0.35)`, thunder thump or a soft haptic 0.3 to 0.5 s after a silent flash.

Mist Maker. The code is on commit 35a19a3 (branch `worktree-agent-a7c7b6a837f5b8b64`, locked worktree), not yet on `3-feat-content-and-polish`. It does `if !app.settings.calmMode { app.play(.water, volume: 0.35) }` as the "soft hiss", with a comment saying so. There is no mist file and no mist `SoundEvent`.

## 3. Bundled files (WordFlora/Resources/Sounds)

All are mono, 44.1 kHz. m4a files are AAC (about 60 kb/s, written by afconvert, gapless info kept); wf-ambient is 16-bit PCM CAF. Peak and RMS are sample dBFS of the decoded file. "Head" and "tail" are silence under -50 dBFS. LUFS for sub-second files is the looped figure. "In-app" is LUFS + catalog gain + master 0.8 (+ call volume). None of the files clips (0 samples at or above 0.999).

| File | Format | Dur s | Peak | RMS | DC | Head / tail s | LUFS | True pk | In-app LUFS | In-app peak | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| wf-key | m4a | 0.09 | -2.9 | -16.0 | -0.00013 | 0 / 0 | -16.5 | -2.9 | -24.2 | -10.6 | 6 ms to peak, dry tick |
| wf-correct | m4a | 0.60 | -3.0 | -14.1 | 0 | 0 / 0 | -14.6 | -2.9 | -21.2 | -9.6 | |
| wf-wrong | m4a | 0.30 | -3.5 | -18.3 | -0.00036 | 0 / 0 | -17.6 | -3.4 | -21.2 | -7.2 | 177 ms rise, soft |
| wf-word | m4a | 0.93 | -3.0 | -16.4 | 0 | 0 / 0 | -16.8 | -3.0 | -22.1 | -8.3 | |
| wf-earned | m4a | 2.20 | -3.0 | -16.7 | 0 | 0.05 / 0.05 | -15.5 | -2.9 | -22.1 | -9.4 | |
| wf-levelUp | m4a | 2.37 | -3.1 | -16.3 | 0 | 0 / 0.05 | -16.2 | -3.1 | -22.2 | -8.8 | |
| wf-rest | m4a | 1.60 | -3.0 | -14.3 | 0 | 0 / 0 | -15.2 | -3.0 | -21.8 | -9.7 | almost no energy above 4 kHz (kind) |
| wf-wake | m4a | 1.76 | -3.0 | -16.3 | 0 | 0 / 0 | -15.9 | -3.0 | -22.5 | -9.1 | |
| wf-water | m4a | 1.32 | -3.3 | -17.7 | 0 | 0 / 0 | -14.5 (looped -15.1) | -3.3 | -22.6 | -10.8 | noisy, HF share -6.5 dB |
| wf-soil | m4a | 0.39 | -3.0 | -17.3 | -0.00098 | 0 / 0 | -18.1 | -3.0 | -23.3 | -8.2 | 7 ms to peak, thud |
| wf-sun | m4a | 2.02 | -3.0 | -16.4 | 0 | 0.05 / 0.05 | -15.6 | -3.0 | -22.2 | -9.3 | slow bloom, 1.07 s to peak |
| wf-snip | m4a | 0.11 | -3.3 | -25.5 | 0 | 0 / 0 | -22.3 | -2.3 | -23.3 | -4.3 | brightest (HF share -1.3 dB), boosted +0.9 dB, highest in-app peak |
| wf-butterfly | m4a | 0.63 | -2.9 | -16.4 | 0 | 0 / 0 | -14.2 (looped -14.5) | -2.9 | -22.3 | -10.8 | |
| wf-badgeBronze | m4a | 0.90 | -3.2 | -16.6 | 0 | 0 / 0 | -17.5 (looped -17.0) | -3.1 | -21.4 | -7.6 | |
| wf-badgeSilver | m4a | 1.67 | -3.1 | -17.4 | 0 | 0 / 0.10 | -16.5 | -3.1 | -22.1 | -8.5 | |
| wf-badgeGold | m4a | 2.16 | -3.0 | -17.7 | 0 | 0 / 0.10 | -16.2 | -2.9 | -22.3 | -8.7 | |
| wf-button | m4a | 0.09 | -3.1 | -14.5 | 0 | 0 / 0 | -15.1 | -3.1 | -22.9 at 1.0, -28.9 at the 0.5 used | -10.9 | 6 ms to peak |
| wf-thunder | m4a | 4.62 | -9.1 | -24.8 | 0 | 0.10 / 0.45 | -25.9 | -9.1 | -36.9 (x0.35) | -20.1 | designed 1.2 s fade tail; 1.2 s to peak |
| wf-ambient | CAF PCM | 25.00 | -3.0 | -18.3 | 0 | 0 / 0 | -19.4 | -3.0 | -31.4 at fixed 0.25 (-41.3 ducked) | | loop seam OK (below) |
| wf-wind-loop | m4a | 8.00 | -14.9 | -29.4 | 0 | 0 / 0 | -30.0 | -14.9 | -31.9 | -16.8 | loop |
| wf-storm-loop | m4a | 8.00 | -20.1 | -33.1 | +0.00006 | 0 / 0 | -30.6 | -19.7 | -32.5 | -21.6 | loop; hush is nearly all above 4 kHz |
| wf-drought-loop | m4a | 6.00 | -18.4 | -26.6 | 0 | 0 / 0 | -30.0 | -18.4 | -31.9 | -20.3 | loop |
| wf-termite-tick | m4a | 1.20 | -10.5 | -25.4 | 0 | 0 / 0.05 | -25.5 | -10.5 | -34.4 (x0.45) | -19.4 | |
| wf-relief-chime | m4a | 1.80 | -10.5 | -23.0 | 0 | 0 / 0.05 | -22.6 | -10.5 | -31.1 (x0.5) | -18.5 | |
| wf-grand-flourish | m4a | 3.00 | -10.5 | -25.3 | 0 | 0.10 / 0.25 | -24.4 | -10.5 | -32.6 (x0.5) | -18.5 | |
| wf-frost-twinkle | m4a | 1.40 | -10.5 | -21.7 | 0 | 0.05 / 0.15 | -18.3 | -10.5 | -29.3 (x0.354) | -21.5 | loudest weather file by LUFS, already trimmed 3 dB |
| wf-hail-patter | m4a | 1.60 | -9.3 | -31.1 | 0 | 0 / 0.20 | -27.5 | -8.4 | -36.9 (x0.45) | -18.2 | AAC true peak 0.6 dB above the plan's -9 target, irrelevant at the played level |
| Petal note (synth) | run time | 0.90 | -8.6 (0.45), -14.8 (Calm 0.22) | -22.1 / -28.3 | 0 | 0 / 0 (ends at exactly 0) | -21.0 / -27.2 | | same (no master) | | five notes overlapping on the flower: peak -5.1 dBFS, no clip |

Loop seams. The decoded m4a has encoder padding after the valid frames (416 or 552 extra zero samples); the numbers below use only the valid frames, which is what a gapless-aware player loops. "Wrap step" is the jump from the last sample to the first, compared to the largest ordinary step in the same file (99.9th percentile).

| Loop | Wrap step | Typical 99.9th-pct step | Verdict |
|---|---|---|---|
| wf-wind-loop (bundle m4a) | 0.0081 | 0.0161 | clean (the source WAV is 0.0091 vs 0.0162) |
| wf-storm-loop | 0.0270 | 0.0665 | clean |
| wf-drought-loop | 0.0056 (-45 dBFS) | 0.0047 | inaudible; marginally above its own steps because the file is a smooth hum, a click at -45 dBFS under a -32 dB bed is not audible |
| wf-ambient.caf | 0.0062 | 0.0531 | clean (PCM, no padding) |

Risks that cannot be proven from files: (a) AAC decoder warm-up at the loop start on a real device (audio plan question 1); if a tick shows, ship the three beds as PCM CAF (about 1.9 MB more) or ALAC. (b) Because the bed ramps in over 0.6 s and starts silent, only repeat loops matter, and the bed sits 20 dB or more under the action sounds, so any residual tick is very quiet.

## 4. Loudness and kid-safety summary

In-app loudness, loudest to quietest (all LUFS, master 0.8 applied):

- Action sounds: correct -21.2, wrong -21.2, badge bronze -21.4, rest -21.8, word and earned -22.1, silver -22.1, levelUp and sun -22.2, badge gold -22.3, butterfly -22.3, wake -22.5, water -22.6, button -22.9 (-28.9 as used), snip -23.3, soil -23.3, key -24.2. Spread 3 dB around -22: balanced. Nothing is more than 6 dB above that baseline.
- Petal notes: -21 (normal), -27 (Calm).
- Weather: frost -29.3, relief -31.1, beds -31.9 to -32.5, flourish -32.6, termite -34.4, hail -36.9.
- Thunder -36.9; garden bed -31.4 (-41.3 ducked).

The weather and thunder sounds are 8 to 15 dB under the action sounds on purpose. The garden bed (-31.4) and the weather beds (about -32) are within 1 dB of each other, and the ambient bed is ducked 22 dB while a weather bed plays, so they do not stack.

Peaks. Highest in-app peak is wf-snip at -4.3 dBFS; every other action sound is -6 dBFS or lower in-app, the catalog never boosts past 0.887 volume (jitter +5% = 0.93), so nothing can clip. The five-note petal run peaks at -5.1 dBFS.

Harshness for kids (energy above 4 kHz as a share of total, plus rise time):
- wf-snip: -1.3 dB share (almost all treble), 71 ms to peak. Only candidate worth a listen on device with kids' headphones/phone speaker. Option if it fails: trim to -2 dB in `SoundCatalog` (drop the boost to 0 dB, which is still -0.9 dB under the cap).
- wf-water: -6.5 dB, 250 ms rise, fine at its natural level; as the mist stand-in it is 9 dB lower.
- wf-butterfly: -9.8, wf-soil -12.7, wf-wrong -11.7: acceptable.
- wf-storm-loop (-2.5) and wf-hail-patter (-2.1): band-limited noise by design, played at -32.5 and -36.9; no sharp onset (storm is a bed with 0.6 s ramp; every hail tap has a 30 ms attack).
- Sharp-onset sounds (key 6 ms, button 6 ms, soil 7 ms, correct 7 ms) are 0.1 to 0.6 s long and low in treble except none; fine for taps.
- Nothing has a siren, buzz, alarm, voice, crowd or sudden loud onset. Thunder has a 1.2 s rise, lowpassed at 450 Hz, no energy above 4 kHz.

## 5. The eight untracked WAV files

`tools/out/weather/wf-{drought-loop,frost-twinkle,grand-flourish,hail-patter,relief-chime,storm-loop,termite-tick,wind-loop}.wav`, 2.7 MB in total, 16-bit mono 44.1 kHz (afinfo: Int16, 1 ch, 44100). Each has a same-named tracked `.m4a` in the same folder.

Findings.
- They are the output of `tools/make_weather_sounds.py`. I imported the generator (read only) and rendered each sound in memory; correlation with the WAV on disk is 1.00000 for all eight (fixed seeds make them bit-for-bit reproducible). Sample counts match.
- They match their m4a files. Tonal sounds correlate at 0.9995 to 1.0000 with the tracked m4a and the bundled m4a (differences only AAC coding noise, error -30 to -45 dB). The noise-based files (storm, wind, hail) correlate lower (0.80 to 0.99 for the tracked ffmpeg m4a; 0.87 / 0.996 / 0.87 for the bundled afconvert m4a) which is normal: AAC does not preserve the phase of noise, and the level and loudness match (WAV vs m4a within 0.5 dB).
- The tracked `tools/out/weather/*.m4a` are not the bundled files. All eight differ byte for byte from `WordFlora/Resources/Sounds/*.m4a`: the tools/out ones come from ffmpeg's AAC encoder, the bundled ones from `afconvert -f m4af -d aac -b 64000` with gapless info (per `docs/STATUS.md` E-9). They are the same sounds.
- `docs/STATUS.md` E-9 says "No WAVs committed" and that the renders go to the scratchpad. The generator's `OUT` constant writes into `tools/out/weather/`, so running it from the repo root leaves these WAVs behind each time.

Recommendation: ignore, then delete.
1. Do not commit. They are 2.7 MB of regenerable output, they contradict the stated "no WAVs committed" decision and the bundle already has the shipped m4a files.
2. Delete the eight WAVs (safe: they are reproducible with `python3 tools/make_weather_sounds.py`, the README for the folder is the script docstring). I did not delete them because this review was read only.
3. To stop it recurring, add `tools/out/**/*.wav` to `.gitignore` (or have the generator write to the scratchpad). The tracked ffmpeg m4a copies in `tools/out/weather/` can stay as the prototype listening set (`index.html` links to the WAVs too, which will show as dead links once they are deleted; `index.html` is regenerated by the script).

## 6. Mist hiss: worth making?

Yes, as polish, not a blocker. What ships today: the Mist button plays `wf-water` at 0.35 volume, about -31.8 LUFS in-app (9 dB under normal watering, about 10 dB under the action sounds). It is safe and quiet, but it is a 1.3 s pour with a 250 ms swell. It reads as water, not as a fine spray, and it does not line up with the 0.6 s droplet travel of `MistSprayView`. The spec (`docs/research/audio-feedback.md` row "Mist") wants an airy filtered spray of 0.3 to 0.5 s at no more than -12 dBFS peak, and `badge-mechanics.md` says "a soft hiss". The cost is low: one pure-Python function in the existing `tools/make_weather_sounds.py` pattern (no new dependency, fixed seed, about 8 KB m4a), one resource added to the project, one new `SoundEvent` case, and the one-line change at the call site. A new `SoundEvent` is covered automatically by `SoundTests` (`allCases` must have a file and a legal volume). Scope-freeze note: the freeze allows bugs only after AdMob formats, but the PM check-in already lists this as a delegated art task, so treat it as the lead's call; the stand-in is an acceptable fallback if time is short.

Suggested recipe (matches the style of `render_hail` and `render_frost`):

- Name `wf-mist-hiss`, kind "shot", size budget 60 KB (expected 8 to 10 KB), mono 44.1 kHz, 64 kb/s AAC like the other eight.
- Length 0.9 s. The visual spray runs 0.6 s out and fades by 0.9 s, so the sound is a short puff with a soft tail and ends before the dew finishes (2.1 s).
- Source: white noise `random.Random(6606)`.
- Filter: two one-pole high-passes at about 2.2 kHz (removes the rumble and the breath sound), then two one-pole low-passes at about 7.5 kHz (removes the sharp "s" edge, keeping it airy and not sibilant). Use `lp_coeff` as in the existing code; build the high-pass as `x - lowpass(x, 2200)` applied twice.
- Colour: add one gentle bump of 3 to 4 dB around 4 to 5 kHz by mixing in 25% of a band-passed copy (centre 4.5 kHz); do not go higher than 8 kHz (that is where small ears find hiss painful).
- Envelope: raised-cosine attack of 90 ms (never under 60 ms, no hard "pssst" start; the existing one-shots use 30 to 40 ms and the spray should be softer), a short hold to 0.25 s, then exponential decay with tau 0.22 s, with the final 0.25 s multiplied by the raised-cosine release `fade_edges(buf, 0.0, 0.25)` so the file ends at zero.
- Texture: multiply by `0.8 + 0.2 * smooth_noise(rng, n, 14.0)` for a faint breathy flutter. Keep it shallow so it does not sound like a rattle; this is the same device the storm bed uses.
- Optional second layer: two very quiet (-18 dB) tiny pitch-less "tick" droplets at 0.18 s and 0.34 s made by `render_hail`'s tap code (lower amplitude, `fc` 2500 to 3500 Hz). Skip if it makes the sound busy.
- Level: WAV peak -12 dBFS (matches the spec for Mist, a notch under `ONE_SHOT_PEAK_DBFS` of -10.5), which should give about -29 to -27 LUFS integrated. Check with the script's `measure`; pass if the m4a peak is at most -11 dBFS and `attack_time` is at least 0.06 s.
- App wiring (for the builder, not done here): add `.mist` to `SoundEvent`, `SoundSpec(file: "wf-mist-hiss", ext: "m4a", gainDb: about +4)` targets roughly -24 LUFS in-app (a quiet, airy one-shot, 2 dB over the weather one-shots, 8 dB under the action sounds; capped because the volume stays under 1.0), call `app.play(.mist)` instead of `app.play(.water, volume: 0.35)`, keep Calm silent. Convert with `afconvert -f m4af -d aac -b 64000` like the other beds so the bundle stays consistent, and add it to the pbxproj Sounds group (each file is a separate entry, see `wf-thunder.m4a`).
- Listen tests: sounds like a plant mister (a spray bottle), not like steam, a snake, a tyre leak, or running water; no sibilant "sss" peak on a phone speaker; fine on AirPods at 50% volume; the end does not click.

## 7. Open items for a human listening pass (cannot be settled by measurement)

1. Loop tick on device for the three m4a beds (wind, storm, drought).
2. wf-snip harshness on a phone speaker and on headphones.
3. Drought shimmer (2.9 kHz and 3.14 kHz beating) reads sleepy or tense (audio plan question 3).
4. Whether the 0.35 volume water stand-in is acceptable if the mist hiss is not built before shipping.
5. Whether the five-note petal run (peak -5.1 dBFS, overlapping) is too much on a phone speaker next to the -22 LUFS game sounds; it is the loudest synth output by peak if a child taps the flower repeatedly. The `PetalSynth` mixer nodes are not limited, so rapid taps can stack; peak with three overlapping runs was not tested.

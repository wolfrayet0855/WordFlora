# Audio review: rulings

Date 2026-11-07. Rulings on `docs/pm/audio-review.md` (commit ba49d12). The owner has released the scope freeze "as needed" for this, so small, low-risk audio items may enter 1.0; the deadline (submit Thu 11-19) stands. Everything below was checked against the code on `3-feat-content-and-polish` and the G3 worktree (commit 35a19a3); nothing was built or run.

Summary: build the mist hiss now as one small G3 follow-up commit (not a merge blocker); fold the snip trim into that commit; no limiter; keep the AAC beds and verify on device; delete the WAVs and ignore the folder; six extra checks for the device listening pass, two of them small 1.1 items.

## 1. Mist hiss: build it now, as a G3 follow-up commit

Ruling: polish that is worth doing in 1.0, admitted under the owner's release of the freeze. Not a merge blocker for G3.

Why. The stand-in (`wf-water` at 0.35) is safe and quiet but semantically wrong: a 1.3 s pour with a 250 ms swell under a 0.6 s spray animation, and the spec row "Mist" in `docs/research/audio-feedback.md` (airy short spray, 0.3 to 0.5 s, peak at most -12 dBFS) and `badge-mechanics.md` ("a soft hiss") both describe a different sound. It is the one place a parent will hear the app say "water" while the screen says "mist". The cost is small and self-checking: a pure-Python render in `tools/make_weather_sounds.py` (fixed seed, measured by the script's own `measure`), one m4a of about 8 to 10 KB, one `SoundEvent` case, one catalog line, one resource entry in the pbxproj, one line at the call site. `SoundTests.testEveryEventHasABundledFile` and `testVolumesAreSafeAndNeverAboveFull` cover the new case with no new test code.

Risk and how to keep it small.
- The pbxproj edit is the only fragile step. The G3 worktree already modifies `WordFlora.xcodeproj/project.pbxproj`, so the builder adds the resource there (same shape as the four `wf-thunder.m4a` entries), avoiding a second-party edit and a merge conflict.
- Sequence: G3 finishes the tool-bar fix and reaches its merge-ready state first; the hiss is a separate commit on top. If the hiss commit misbehaves it is reverted alone and the stand-in ships.
- Hard gate: the hiss is in by G3's planned exit (Thu 11-12 20:00). If the file is not rendered and passing by then, ship the stand-in and move the hiss to `docs/pm/backlog.md` (1.1) without further discussion.
- Who: the art/audio agent renders the file from the recipe in section 6 of the review (already a delegated art task in the PM check-in); G3 wires it. The builder does not design the sound.

Corrections to the recipe.
- The review suggests `gainDb: about +4`. That does nothing: `SoundCatalog.volume` is `min(1, master x 10^(gain/20))` with master 0.8 (-1.9 dB), so any boost over +1.9 dB is capped at volume 1.0, and the catalog rule is "players can only attenuate". Use `gainDb: 0` and set the level in the render: a WAV peak of -12 dBFS gives roughly -28 LUFS in-app, between the weather one-shots (-29 to -31) and the stand-in (-31.8). That is right for a mist. If it needs to be a touch louder on device, raise the WAV peak to `ONE_SHOT_PEAK_DBFS` (-10.5), never the catalog gain.
- Convert with `afconvert -f m4af -d aac -b 64000` like the bundled beds; the script's ffmpeg encoder output is the prototype set only.
- Pass criteria before wiring: m4a peak at most -11 dBFS, `attack_time` at least 0.06 s, 0.9 s long, under 60 KB, ends at zero (no click on the tail).
- Call site: `app.play(.mist)` replacing `app.play(.water, volume: 0.35)`; keep `if !app.settings.calmMode` as it is (Calm stays silent for the mister, matching the button sound).

## 2. wf-snip: drop the +0.9 dB to 0 dB now

Ruling: change `gainDb: 0.9` to `gainDb: 0` in `SoundCatalog` (one line in `WordFlora/Audio/Sound.swift:39`). Put it in the same G3 hiss commit, since that commit already edits the catalog; if the hiss slips, the lead commits the one line alone.

Why. It is the only boost in the catalog and the sound with the highest in-app peak (-4.3 dBFS) and the most treble (nearly all energy above 4 kHz, the band small ears like least). 0.9 dB is below a just-noticeable level difference, so the prune does not get lost; the cap stays respected; and the catalog becomes consistent with its own comment ("players can only attenuate"). `SoundTests.testVolumesAreSafeAndNeverAboveFull` asserts `volume(for: .snip, master: 1.0) == 1.0`, which still holds at 0 dB, so no test changes.

Honest limit: 0.9 dB does not fix harshness; the spectrum does. If the device listen (phone speaker, then children's headphones at half volume) still finds it sharp, the fix is a re-render with a 6 to 8 kHz low-pass, which is 1.1 unless the art agent has it done inside the same window as the hiss.

## 3. PetalSynth limiter: no change for 1.0

Ruling: not a bug; do not add a limiter.

Why. The pool is five `AVAudioPlayerNode`s and each reuse calls `node.stop()`, so at most five notes ever sound at once, and the five-note love-flower run (0.16 s apart, exponential decay) measured -5.1 dBFS peak. A tap cancels the pending run and plays one note, so a single finger cannot stack five peaks inside the 10 ms attack; the only way over 0 dBFS is five simultaneous fingers on a pill a few millimetres wide. A real limiter is not one line (attach an `AVAudioUnitEffect` peak limiter, re-route five nodes through it, re-test latency); the actual one-liner, `engine.mainMixerNode.outputVolume = 0.7`, retunes the level everyone has already listened to. Neither is worth a build cycle for a case that needs five fingers.

For the device pass: tap the flower repeatedly for ten seconds on the phone speaker; listen for distortion and for a click when the sixth note cuts the first (the oldest ringing note is hard-stopped on pool wrap). If either shows, 1.1: lower `PetalNotes.volume` 2 dB or add the limiter properly.

## 4. AAC loop beds: leave as AAC m4a, verify on device

Ruling: ship the three beds as they are. Do not convert to PCM CAF pre-emptively.

Why. The bundled files are afconvert AAC with gapless information present (exact valid-frame counts in afinfo), which is what `AVAudioPlayer` with `numberOfLoops = -1` uses to trim encoder padding. The seams are clean in the samples. Even if a device tick exists it sits under a bed that is itself 20 dB or more under the action sounds, ramps in over 0.6 s and starts silent. PCM CAF costs +1.9 MB (over half the whole audio budget), breaks `WeatherSoundTests.testEverySoundIsBundledSmallAndTheRightLength` (beds have a 120 KB budget) and needs its own build and test cycle. Spending that before hearing a tick is the wrong order.

Device pass: on a wind day and a puddles day, with headphones at half volume, listen through at least three loop boundaries (8 s for wind and storm, 6 s for drought). If a tick is audible, convert only the offending bed(s) to PCM CAF, raise that bed's size allowance in the test, and treat it as a 1.0 bug fix. ALAC is not worth the extra variable.

## 5. The eight untracked WAVs: delete and ignore

Ruling: confirmed. Delete `tools/out/weather/*.wav` and add `tools/out/**/*.wav` to `.gitignore`. Lead does this in the main checkout (untracked files, no worktree conflict). This rulings commit does not touch `.gitignore`, so the lead's change is its own commit.

Why. Correlation 1.00000 with a fresh render from `tools/make_weather_sounds.py` (fixed seeds), same-named tracked m4a prototypes exist, `docs/STATUS.md` E-9 says "No WAVs committed", and 2.7 MB of regenerable output does not belong in history. The dead links in `tools/out/weather/index.html` are acceptable: the script rewrites that file on every run. Leave the tracked ffmpeg m4a prototypes in place.

## 6. What the review did not cover, and what to do about it

Checked in code. Items marked "device pass" go on the listening list; two small code items go to the 1.1 backlog unless the device pass turns them into bugs.

1. Audio session and silent switch: fine. `SoundPlayer.configureSession` sets `.ambient` at launch (`AppModel.swift:66`); all three players share it, so the silent switch mutes everything and the child's own music keeps playing. `SoundTests.testSessionIsAmbient...` pins this. One known leak: `ReadAloud.speak` switches the session to `.playback` with `.mixWithOthers` while the clue is spoken (on purpose: the child asked to hear it) and `finish()` restores `.ambient`. During those seconds, key taps and the correct/wrong sounds also bypass the silent switch. Accept for 1.0; device pass: silent switch on, tap Read aloud, type while it speaks, confirm the effects are quiet enough that this is not a complaint. 1.1 option: hold effects while `ReadAloud` is speaking.
2. Interruptions (call, Siri, alarm): `ReadAloud` stops itself on `interruptionNotification`; `PetalSynth` restarts its engine on the next tap (`startIfNeeded`). The garden bed is restarted when the scene becomes active again (`WordFloraApp.swift:225` calls `updateAmbience`), so it recovers. The weather bed does not: `WeatherSoundPlayer.startBed` returns early when `currentBed == s`, so after an interruption the bed stays paused until the page changes. Failure direction is silence, which is the safe one for a kids app. Device pass: invoke Siri on a wind day and see whether the bed comes back. 1.1 backlog: an `interruptionNotification` `.ended` observer in `WeatherSoundPlayer` that calls `bed?.play()`; not for 1.0 because it cannot be unit-tested and needs a device to verify.
3. Headphone disconnect: `ReadAloud` stops on `oldDeviceUnavailable`, as the spec asks. `SoundPlayer` and `WeatherSoundPlayer` do not, so a bed that was playing in headphones continues from the speaker at about -31 LUFS. `docs/research/audio-feedback.md` section 151 asked for "stop ambient on unplug". Quiet leak, not a safety issue. 1.1 backlog together with item 2 (same observer, one more line: `stopAmbient()` and `WeatherSoundPlayer.shared.stopAll()`).
4. Background and lock: `.background` stops the garden bed (`WordFloraApp.swift:226`), weather beds are gated on `appActive`, and `.ambient` is silenced by the lock screen anyway. Fine. No audio at launch: `ambienceOn` defaults to false (`AppSettings.swift:79`), thunder has a cooldown, nothing autoplays. Fine.
5. Calm mode: Calm silences the weather sounds (gate), halves the petal notes (0.22), and silences the button and mister sounds at their call sites; it does not trim the `SoundPlayer` effects, where the research table (DERIVED, not a spec requirement) suggested -3 dB. Not a bug; 1.1 idea: `master` 0.8 to 0.57 in Calm. Quiet Garden: handled by the weather gate and the reward paths; nothing further.
6. System volume: the app cannot read or set speaker level and should not. The measures in place are the ones available (no boosts, peaks capped, no onset under 6 ms with treble). Device pass at 50% and 100% speaker and AirPods at 50%, with the loud trio (correct, badge bronze, the five-note flower) and the soft trio (hiss, hail, thunder) back to back.
7. Small polish noticed in passing, 1.1 unless already in a touched file: the garden bed starts at full 0.25 with no ramp (`startAmbient` plays immediately) while every weather bed ramps in over 0.6 s. Only heard when a parent flips Ambience on in Settings.

## Hand-off

G3 builder (follow-up commit on top of the tool-bar fix, after the art agent delivers `wf-mist-hiss.m4a`): add `.mist` to `SoundEvent`, `SoundSpec(file: "wf-mist-hiss", ext: "m4a", gainDb: 0)`, pbxproj resource entry, `app.play(.mist)` at `PlantDetailView.swift:675`, and `snip` to `gainDb: 0`. Run `SoundTests` and `TendingUITests`. One build and test cycle. Gate Thu 11-12 20:00.

Lead, main checkout: delete the eight WAVs, add `tools/out/**/*.wav` to `.gitignore`; if the hiss slips, commit the snip line alone; add items 6.2, 6.3, 6.5, 6.7 and the petal limiter note to `docs/pm/backlog.md` for 1.1.

Device listening pass (whoever holds the phone): bed loop seams (section 4), snip on speaker and headphones (section 2), repeated petal taps (section 3), silent-switch-during-read-aloud (6.1), Siri on a wind day (6.2), the level sweep (6.6), and the hiss once it exists (listen tests in the review, section 6).

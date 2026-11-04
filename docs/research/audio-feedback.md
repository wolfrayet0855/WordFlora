# WordFlora audio feedback: research and design brief

Date: 2026-11-03. Scope: success and "resting" sounds, all event sounds, iOS implementation, playtest plan. Fits spec sections 18-19 (P-05 token table, P-06 resting, P5 ambient, Calm mode, Quiet Garden).

## 0. How to read this doc

Evidence labels: **PRIMARY** = fetched the original/official page this session; **SECONDARY** = a search-result summary or third-party write-up of a primary source; **OPINION** = practitioner/blog/assertion; **DERIVED** = my engineering inference or a tunable default (not evidence). Numbers in the spec tables are **DERIVED defaults to tune in playtest**.

Honest upfront limits: Search tooling returned thin results for the academic psychology questions (nothing on child-specific feedback-sound research, nothing on negative sounds and frustration, nothing cross-cultural on consonance). Section 8 lists exactly what could not be fetched or verified. Where I use background knowledge instead of a fetched source, it is marked DERIVED or UNVERIFIED.

## 1. Evidence summary

### 1.1 Earcons vs auditory icons
- Earcons are abstract musical tones that must be learned; auditory icons are everyday sounds mapped by analogy. Jones & Furner found users preferred earcons but associated auditory icons to commands better; Lucas found no response-time or error difference between them. SECONDARY (search summary of papers hosted at https://www.dcs.gla.ac.uk/~stephen/papers/CHI93.PDF and https://eprints.gla.ac.uk/3257; originals not opened).
- A 2023 systematic review/meta-analysis of brief audio alerts reports speech, spearcons and hybrids beat auditory icons, which beat earcons, on accuracy and reaction time. SECONDARY (https://www.aminer.org/pub/65791630939a5f4082d6dc2b/auditory-icons-earcons-spearcons-and-speech-a-systematic-review-and-meta-analysis; abstract-level only). It concerns alerts that must be decoded fast, not delight feedback.
- Implication (DERIVED): WordFlora needs a hybrid. Garden actions (water, soil, prune, net) should be auditory icons (recognisable physical sounds: pour, scoop, snip), which kids decode without learning. Game-state feedback (correct, wrong, complete, earned, resting) should be a small tuned earcon family in one musical key, because there is no natural everyday sound for "you found a letter". Every earcon is always doubled by a visual and, where defined, a haptic, so nothing has to be learned from sound alone.

### 1.2 Pitch direction, consonance, urgency
- Higher pitch and faster pulse rate raise perceived urgency of warnings (Hellier & Edworthy and others). SECONDARY (https://jcaa.caa-aca.ca/index.php/jcaa/article/view/611 and related Plymouth portal records, summaries only). Implication (DERIVED): avoid high, fast, repeated pulses for anything in the wrong/resting family; they read as alarms.
- Consonance/dissonance in alarms is under-researched (a 2023 Korean alarm study says so). SECONDARY (https://koreascience.or.kr/article/JAKO202305734518441.pdf, via search summary). No evidence found for cross-cultural consonance preferences.
- Rising=good/falling=bad is a widespread convention (Duolingo's wrong-answer sound is described as a deflated descending tone, SECONDARY/OPINION: https://samstoof.beehiiv.com/p/duolingo-mastered-app-design). I found no controlled study establishing it as universal or specifically as effective for children. Children's perception of pitch contour (up vs down) develops with age and is imperfect in younger children (titles found, not read: https://www.researchgate.net/publication/23558626_Developmental_changes_in_the_perception_of_pitch_contour_Distinguishing_up_from_down, https://escholarship.org/content/qt5n58b623/qt5n58b623.pdf). Implication (DERIVED): do not rely on pitch direction alone to carry success vs wrong for young kids; differentiate by timbre, duration and musical completeness as well, plus the visual and haptic channel.

### 1.3 Timbre, duration, repetition
- Apple's own guidance for repetitive sounds: "Consider varying sounds that people could perceive as repetitive over time... randomize a sound file's pitch and volume during playback, instead of creating different files." PRIMARY (visionOS section of https://developer.apple.com/design/human-interface-guidelines/playing-audio, fetched via the .json endpoint). The advice is stated for visionOS but the technique transfers (DERIVED).
- Apple on haptics: "Avoid overusing haptics... the best haptic experience is one that people may not be conscious of, but miss when it's turned off." PRIMARY (https://developer.apple.com/design/human-interface-guidelines/playing-haptics). Same logic applies to sound (DERIVED).
- Juice: Kao 2020 (n=3,018): no juice and extreme juice both worse than medium-high. SECONDARY (already cited in docs/research/game-design-best-practices.md section 2.2). Implication: a quiet key tap and a short wrong-letter sound are correct; a fanfare per letter is not.
- Duration rules of thumb (DERIVED): UI feedback under ~100 ms is perceived as instantaneous (NN/g response-time limits are cited in the existing game-design research); sounds that outlast the next likely input (a key tap every ~300-600 ms) must be short or must not block/mask the next one. Celebration sounds can be long because input is not expected, but the spec already caps win sequences at 2.5 s and requires tap-to-skip, so audio must be cut/faded on skip.
- Role of silence (DERIVED/OPINION): Many calm games leave gaps. Monument Valley's sound designer won the Develop 2014 Creative Contribution (Audio) award; the interview describes shifting from a technical to a much more emotive approach (SECONDARY, search snippet only: https://thesoundarchitect.co.uk/tag/monument-valley; the page itself failed to fetch, TLS error). I could not verify specific claims about its use of silence. For WordFlora: no sound on the "2 petals left" lean, on screen transitions, on timers or on idle; silence is the default state, the first sound of a round is the first tap.

### 1.4 Negative sounds, frustration, learning
No retrievable controlled study on wrong-answer sounds and frustration/learning in children's apps (searches returned nothing relevant). I am not claiming evidence for or against. The project's position stands on precaution plus consistent design logic: spec section 19 already rules wrong-letter haptic is `.impact(.soft)` never `.error`, and the loss is "resting". Apple's haptic guidance supports a consistent cause/effect mapping and warns against using the same pattern for opposite outcomes. PRIMARY (https://developer.apple.com/design/human-interface-guidelines/playing-haptics). Same rule for sound: a given sound maps to exactly one meaning.
Working principle (DERIVED): the wrong-letter and resting sounds are information (soft, short, warm, musically resolved) not punishment (no buzzer, no descending slide, no minor second, no low "womp").

### 1.5 Sound and haptic pairing, latency
- Apple: "When visual, auditory, and tactile feedback are in harmony... the user experience is more coherent"; match haptic intensity and sharpness to the animation; "You can also synchronize sound with haptics"; make haptics optional. PRIMARY (https://developer.apple.com/design/human-interface-guidelines/playing-haptics).
- Audio-haptic asynchrony detection thresholds (Sharma & Yasuda, driving context): about 88 ms when audio leads, about 123 ms when haptic leads on average, with 20% of participants noticing 50 ms (audio first) to 65 ms (audio second). Other cited work: undetected up to ~92 ms (audio first) and ~110 ms (audio second); virtual-button touch studies found much looser thresholds (~179 ms audio first). SECONDARY (search summary of https://arxiv.org/pdf/2307.05451; the PDF could not be text-extracted, so numbers are unverified against the paper).
- Practical target (DERIVED): fire haptic and sound in the same main-thread turn; keep total tap-to-sound latency under ~50 ms and audio-vs-haptic offset under ~40 ms; audio-leading is the more detectable direction in these studies, so never schedule sound earlier than the haptic.

## 2. What comparable apps do (what I could and could not verify)

| App | What I can say | Label |
|---|---|---|
| Duolingo | Playful, game-like palette; correct answers get bright chime/cheer cues; incorrect described as a deflated descending tone, i.e. it does use a falling "wrong" sound. Sources: https://soundcy.com/article/what-does-duolingo-sound-like, https://samstoof.beehiiv.com/p/duolingo-mastered-app-design, https://www.newsletter.designproject.io/p/sonic-branding-strategy-why-audio-design-is-your-secret-ux-weapon-in-2025 | OPINION/SECONDARY (no Duolingo sound-team interview found; no named sound designer found) |
| Monument Valley / Alto's Odyssey (Todd Baker, Stafford Bawler) | Interviews exist: https://audiokinetic.com/en/blog/behind-the-beautiful-sound-of-monument-valley-2-with-todd-baker (not opened), Bawler at The Sound Architect (TLS failure), MCV write-ups https://mcvuk.com/development-news/heard-about-the-sounds-of-monument-valley (not opened). Cannot report specifics. | Titles only |
| Animal Crossing | Kazumi Totaka is sound director/composer; fans praise ambient/animated SFX. No detail on success/failure sounds retrieved. https://en.wikipedia.org/wiki/Kazumi_Totaka | SECONDARY |
| Wordle-likes, Finch, Forest, Khan Academy Kids, Toca Boca, Sago Mini | Nothing retrieved. Not claiming anything about their sounds. | UNVERIFIED |
| Designing Sound / GDC | Designing Sound 2013 guest post says mobile games should have a low loudness range (5-10 LU) because of noisy environments and weak phone speakers (SECONDARY, vendor guest post, no mobile LUFS number): https://designingsound.org/2013/02/20/different-loudness-ranges-for-console-and-mobile-games | SECONDARY |

Takeaway (OPINION): the one retrievable data point for "wrong" is Duolingo-style falling tone, which is a competitive norm for adult learners, not evidence of suitability for a cozy kid-adult game. WordFlora deliberately departs from it.

## 3. Apple platform guidance (PRIMARY unless stated)

From the HIG "Playing audio" (https://developer.apple.com/design/human-interface-guidelines/playing-audio; fetched via the developer.apple.com tutorials JSON endpoint because the HTML page returned no body):
- Silent mode: people "also want to silence nonessential sounds, such as keyboard clicks, sound effects, game soundtracks, and other audible feedback." Silent mode plays only audio people explicitly initiate (media, alarms, messages).
- Volume: people expect volume settings to affect all sound including in-app effects; adjust relative levels only, "the system volume always governs the final output". So no code that raises system volume or fights it.
- Category table: Solo ambient = responds to silence switch, does not mix, no background. **Ambient = sound isn't essential and doesn't silence other audio; responds to the silence switch; mixes with other sounds; doesn't play in the background.** Playback = ignores the silence switch. HIG's own example for Ambient is a game that lets people play music from another app instead of the game soundtrack.
- Interruptions: for a game, "a game doesn't need to check the interruption type before automatically resuming playback". Still observe interruptions to restart the engine.
- iOS: "Use the system's sound services to play short sounds and vibrations" (HIG). Caveat (DERIVED, UNVERIFIED): System Sound Services follow ringer volume, not media volume, and cannot be pitch-varied, so for a mixed, volume-consistent, toggle-controlled design AVAudioEngine is preferable. This is a deliberate deviation from the HIG sentence; record it as an open question.
- AVAudioSession `.ambient` doc text: "audio from other apps mixes with your audio. Screen locking and the Silent switch... silence your audio." PRIMARY (https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/ambient, fetched via JSON endpoint).

Decision: use `.ambient` for everything (effects, ambient loop). It respects the silent switch, mixes with the user's music/podcasts, stops with lock. Do not use `.playback` (ignores silent switch, would break spec 18 "never play audio over silent mode"). Do not use `.soloAmbient` (stops the user's music).

Haptics: HIG says haptics should be consistent, optional and short; "Core Haptics ... Optional audio content can be included" in custom patterns. PRIMARY (playing-haptics). Whether AHAP-embedded audio obeys an `.ambient` session and the silent switch was NOT verified (the Core Haptics doc paths returned 404). Recommendation (DERIVED): keep haptics (CHHapticEngine/UIFeedbackGenerator, haptics-only AHAP) and sound (AVAudioEngine) as separate layers fired together, so the sound toggle, silent switch and haptic toggle remain independent and testable.

Not fetched / DERIVED knowledge to verify in Xcode docs: preferred IO buffer duration (`setPreferredIOBufferDuration`) can reduce latency; preload/prepare AVAudioPlayerNode buffers or `AVAudioPlayer.prepareToPlay()`; audio-session interruption and route-change notifications; AVAudioSession `secondaryAudioShouldBeSilencedHint`; VoiceOver speech can be ducked by `.duckOthers`, which we should not use.

Accessibility (guidance PRIMARY: HIG warns "avoid communicating important information using only sound. Always provide additional ways", visionOS section of playing-audio, applies generally; Apple haptics: "make sure people can still enjoy your app or game without them"). So every sound has a visual twin and a text/VoiceOver equivalent (VoiceOver announcement for correct/wrong/resting uses `UIAccessibility.post(.announcement)` with kind copy, DERIVED). Do not play sound effects over VoiceOver speech: on VoiceOver, suppress key-tap ticks; keep completion/resting sounds quiet and short.

App Store review concerns (UNVERIFIED, not fetched): Kids Category and guideline 1.3 / 5.1.4 matter for ads and data, I found no review rule specific to sounds. Ensure no sound plays unexpectedly on launch, the app does not interrupt the user's music, and any ambient audio needs the in-app toggle. Verify against https://developer.apple.com/app-store/review/guidelines/ before submission.

## 4. Loudness, headroom, ear safety

- Silent-switch and system volume govern final level (HIG above), so our job is relative balance and a conservative ceiling.
- Mobile mix reference: IESD mix reference suggests about -16 LUFS integrated and true peak at most -1 dBTP for mobile titles. SECONDARY (https://www.audiogang.org/wp-content/uploads/2015/04/IESD-Mix-Ref-Levels-v03.02.pdf, via search summary). EBU R128 is -23 LUFS and -1 dBTP for broadcast. SECONDARY (search summary). A claim of "UI sounds -14 LUFS short-term" came from an aggregator and is unverified, ignore it.
- BS.1770 gating needs ~400 ms+ windows, so LUFS is not meaningful for 30-200 ms tap sounds (DERIVED). For short sounds specify sample peak and RMS/short-window level instead; use LUFS only for sounds above ~1-3 s and for the ambient loop.
- Ear safety: WHO's Make Listening Safe frames a standard of 80 dBA for up to 40 hours/week (SECONDARY: the WHO fact sheet fetched did not contain these numbers; they came from search results mirroring ITU/WHO material, https://www.itu.int/dms_pubrec/itu-t/rec/h/T-REC-H.870-202203-I!!TOC-HTM-E.htm not opened). The WHO deafness fact sheet (PRIMARY, https://www.who.int/news-room/fact-sheets/detail/deafness-and-hearing-loss) says over 1 billion young adults are at risk from unsafe listening. I could not verify a children-specific lower limit nor EN 71-1 toy numbers (one unverified French source says 80 dB near-ear toys). Since an app cannot control SPL (system volume and the headphone do), our measures are: no loud transients, no sound louder than the loudest UI sound class (celebrations), cap peaks at -3 dBFS, no sharp 2-5 kHz energy peaks, and a Settings control for effect volume (relative trim, max 0 dB, never boost).
- Under-13 default (DERIVED): effects trim -3 dB versus 13+; this is cheap and defensible; ambient off by default (spec P5).

Proposed levels (DERIVED, tune by ear on iPhone speaker and AirPods):
- Sample peak: tap sounds <= -9 dBFS; feedback (correct/wrong) <= -6 dBFS; celebrations <= -3 dBFS; nothing above -1 dBTP.
- Relative loudness hierarchy: key tap (quietest) < wrong < correct < word complete < plant earned/level up/badge. Resting is as quiet as wrong, never louder.
- Ambient loop: <= -30 LUFS integrated, LRA < 5 LU, fades 1.5 s in/out, auto-fade at 10 minutes (spec P5).

### Normalisation pipeline (DERIVED; commands are standard but run once to confirm on your machine)
1. Author or synthesize at 48 kHz/24-bit WAV (iPhone hardware output commonly runs at 48 kHz, so shipping 48 kHz avoids a resample; DERIVED).
2. Trim, 3-10 ms fade-in, 10-40 ms fade-out to prevent clicks. High-pass at ~80 Hz (phone speakers cannot reproduce it).
3. Measure: `ffmpeg -i in.wav -af volumedetect -f null -` (max_volume, mean_volume) for short sounds; `ffmpeg -i in.wav -af ebur128=peak=true -f null -` for sounds > 1 s and the loop. Do not use `loudnorm` on sounds under ~3 s (it needs context; DERIVED).
4. Apply fixed gain per sound class to hit the targets above.
5. Encode: short SFX as 16-bit PCM CAF (`afconvert in.wav out.caf -f caff -d LEI16@48000`), ambient loop as AAC `.m4a` (`afconvert in.wav out.m4a -f m4af -d aac -b 96000`) or as CAF/ALAC for gapless looping (AAC adds encoder delay; seamless loop behaviour must be tested, DERIVED).
6. A CI check (see section 6) re-measures every shipped file.

## 5. Licensing

| Source | Terms found | Label | Caveats for App Store use |
|---|---|---|---|
| Original synthesis (own tools) | You own it. | n/a | Lowest legal risk, best brand coherence, single key. Recommended for all earcons. |
| Kenney.nl | "all game assets on the asset pages are public domain licensed (CC0)"; attribution not required; commercial use OK; do not use the Kenney logo. https://kenney.nl/support | PRIMARY (page does not mention audio separately; check the license file inside each audio pack) | Keep a copy of the pack's license file in the repo. |
| Freesound | Per-sound license. CC0: use freely, can't claim authorship. CC-BY: attribution required, commercial OK. CC-BY-NC: no commercial use. Sampling+: older, treated as NC-like. https://freesound.org/help/faq/ | PRIMARY | Use only CC0 filter; record sound URL, author, license and date retrieved per file in an `ATTRIBUTIONS`/asset manifest; uploader could have wrongly licensed a sound (risk, DERIVED), prefer well-known uploaders and avoid anything that sounds like a commercial game. |
| Sonniss GDC bundles | Commercial use in personal/commercial projects, no attribution, finished projects may be sold; may not redistribute or sell sounds as sounds or in sample packs; AI training expressly prohibited; modified sounds stay licensed material. https://www.sonniss.com/gdc-bundle-license | PRIMARY | Bundle assets inside the app binary is fine (finished project) but the repo must not publish raw files publicly (our repo should stay private or exclude them). Do not use Sonniss sounds with any ML on-device tuning (spec has Apple Intelligence features; keep them away from audio). Banned in training-data pipelines. |

Recommendation: synthesize the earcon family and UI sounds ourselves (offline script or a DAW), and use CC0 recordings only for texture layers (water pour, soil, snip, birds) and for ambient. Track provenance in a manifest and add a unit test that every audio file has a manifest row.

## 6. Cultural and accessibility considerations
- Pitch associations: I found no cross-cultural source. Treat "rising=positive" as a Western convention that is not guaranteed (OPINION; DERIVED). Design response: never encode success/failure in pitch direction alone; pair with timbre, duration, visual (check glyph/colour from P-05), and haptic.
- High-frequency hearing loss (DERIVED, standard audiology knowledge, not fetched): age-related and noise-induced hearing loss mostly affects >4 kHz first; phone speakers roll off below ~300-500 Hz. Keep the main energy of every earcon between ~300 Hz and ~3.5 kHz (fundamentals ~260-1050 Hz with harmonics), avoid sounds whose identity depends on content >6 kHz (sparkle layers are fine as garnish, never the cue).
- Hearing-impaired alternatives: every sound has a visual (tile flip, petal fall, glow) and, for the primary events, a haptic; VoiceOver announcements; a Settings toggle for sound; game fully playable muted.
- Color-blind analog: avoid separating two events solely by small pitch differences (e.g. correct vs word complete); make them differ by length and shape too.
- Sensory/kid sensitivity: no sudden loud attacks, no flashing (spec limit 3 Hz applies to visuals), no repeated alarm pulses; soft attacks (5-15 ms) except the tap tick.
- Auto-play: ambient never auto-starts (spec P5).

## 7. Design brief

### 7.1 Principles for WordFlora success and "resting" sounds
1. **One key, one family.** All earcons in one pentatonic scale (suggest D major pentatonic: D E F# A B, DERIVED) so overlapping sounds (e.g. a tap during a celebration tail) can never clash. Ambient drone/bed in the same key. This addresses the consonance risk without relying on missing evidence.
2. **Information, not judgment.** Wrong and resting are soft, warm and short; no buzzers, no minor seconds, no slides, no low "womp". Resting is a consonant settling sigh (see 7.2), conceptually "the flower is going to sleep", matching spec P-06 and the copy linter.
3. **Differentiate by more than pitch.** Success = brighter timbre (pluck/bell/marimba), short upward interval, clear decay. Wrong/resting = rounder timbre (muted wood/soft pad), flat or gently falling contour, shorter or slower attack, lower presence. Plus visuals/haptics.
4. **Quiet by default, silent as a first-class state.** Taps nearly inaudible; no sound on non-actions; no sound on timers/ambient events; silence for "2 petals left".
5. **Proportionate.** Loudness and duration scale with significance; celebrations never longer than the 2.5 s cap, always skippable (fade to zero in ~120 ms on skip).
6. **Anti-fatigue.** Pitch +/- 0-3 semitone-safe-in-key variations... see 7.3: randomize volume (+/-1.5 dB) and pitch (+/- 0.5 semitone, small enough to stay perceived "in key", DERIVED) on high-frequency sounds (tap, correct, wrong); do not vary celebrations. 3-4 round-robin variants for correct. Apple endorses randomizing pitch/volume (visionOS HIG, PRIMARY).
7. **One sound per player action** (mirrors one haptic per action). Multi-tile reveals play one sound for the guess, not one per tile.
8. **Respect every switch.** Silent switch via `.ambient`; in-app Sound toggle; Calm mode shortens and softens; Quiet Garden mutes reward fanfares (tending sounds stay, quieter); no sound over VoiceOver speech.

### 7.2 Spec table per event

Legend: haptic mapping follows spec section 19/P-05 (iOS `UIImpactFeedbackGenerator` etc.). "Silent" = hardware Ring/Silent switch on: all sound off (ambient category does this automatically); haptics still follow the haptic toggle (haptics are not tied to the switch; verify, DERIVED). "Sound off" = Settings toggle off. "Calm" = Calm mode (default on for under-13): effects -3 dB, no shimmer layer, durations at low end. "Reduce Motion" = does not change sound (audio is not motion), except that it shortens the sequence if the visual sequence is replaced by a static fade (keep audio length aligned to the visual).

| Event | Intent | Pitch / timbre (DERIVED) | Duration | Level (peak / relative) | Haptic pairing | Reduce Motion | Silent / Sound off |
|---|---|---|---|---|---|---|---|
| Key tap | Acknowledge press; confirm input | Soft wooden tick, ~1.2-2 kHz centroid, dry, no pitch | 25-60 ms | <= -9 dBFS; quietest | `.selection` | same | none. Suppressed under VoiceOver. Optional (default on, own sub-toggle later) |
| Correct letter | Small reward, reveal | Plucked marimba/kalimba, rising major 2nd or 3rd in key (e.g. A4 to B4), 3-4 round-robin variants, +/-0.5 st | 220-380 ms | <= -6 dBFS | `.impact(.light)` once per guess | same | none |
| Wrong letter | Gentle information, nothing lost | Muted soft wood "tok"/felted pad, narrow gentle fall of a minor/major 2nd at most or flat (e.g. F#4 to E4... consonant), round timbre, slower attack 10 ms; no buzz | 150-260 ms | <= -7 dBFS, slightly quieter than correct | `.impact(.soft)` (never `.error`) | same (visual: fade not shake) | none; input re-enabled <= 150 ms regardless of sound |
| 2 petals left | Visual-only | none | 0 | 0 | none | n/a | n/a |
| Word complete | Satisfying close of the word | 3-note rising arpeggio in key (D-F#-A), kalimba + soft bell tail, fully consonant | 0.8-1.2 s | <= -4 dBFS | `.success` | shorten to ~0.6 s if static | none; skip cuts in 120 ms |
| Plant earned | Peak moment | "Bloom swell": soft pad swell + rising pentatonic shimmer resolving to major chord (D5 add9), natural bird chirp garnish optional; energy mostly < 3.5 kHz | 1.6-2.2 s (cap 2.5) | <= -3 dBFS; loudest class | Core Haptics crescendo <= 600 ms | static fade; sound same length shortened to <= 1.2 s | none. No ad or toast within 120 s (spec P13) |
| Level up | Milestone, not alarm | Like plant earned but with an extra upward step, brighter bell | 1.5-2.2 s | <= -3 dBFS | `.success` once | as above | none |
| Resting (0 petals) | Soft, kind close; "this one is resting" | Two-note consonant settle: major 6th down to 5th or 3rd (e.g. A4 to F#4) on soft felt-piano/pad with long sigh-like decay, optional soft breath of air; no minor, no slide, no low rumble | 0.9-1.4 s | <= -8 dBFS; quieter than word complete | none or `.soft` impact (spec P-05 says none or soft); recommend none | same | none. Never paired with red/grey (spec) |
| Rose wake-up | Warm revive, relief | Gentle upward glow: harp/glock pluck cluster rising a 5th, water-droplet texture, resolves bright | 1.5-2.0 s | <= -4 dBFS | Core Haptics short swell <= 400 ms or `.success` | static fade, ~1 s | none |
| Water (watering can) | Auditory icon | CC0/recorded or synthesized pour, filtered, no >6 kHz harshness | 0.5-0.9 s (matches animation) | <= -10 dBFS | rain pattern <= 400 ms | same | none |
| Soil / repot | Auditory icon | Soft earthy scoop/thud, low-mid (200-800 Hz) | 0.4-0.8 s | <= -9 dBFS | `.impact(.medium)` thump | same | none |
| Sun lamp / sunny spot | Warm glow | Soft rising pad bloom, 2 notes | 0.5-0.9 s | <= -12 dBFS | none | same | none |
| Prune | Satisfying snip | Crisp but soft snip, short; each cut separate sound only on drag segments, capped at 1 per 120 ms | 80-150 ms per snip | <= -9 dBFS | `.impact(.light)` per snip (one per player action) | same | none |
| Mist | Light spray | Airy short spray, filtered | 0.3-0.5 s | <= -12 dBFS | none/`.soft` | same | none |
| Butterfly catch | Delight | Fluttery two-note upward flick + net swoosh, tiny sparkle | 0.4-0.7 s | <= -6 dBFS | `.impact(.light)` | same (resting-on-flower mode keeps audio) | none; no penalty sound for misses (spec: no penalty) |
| Badge unlock (bronze / silver / gold) | Escalating, never revoked | Same 3-note motif; bronze = 2 notes soft pluck, silver = 3 notes + bell, gold = 4 notes + shimmer. All in key, consonant | 0.8 / 1.2 / 1.6 s | <= -5 / -4 / -3 dBFS | `.success` (badge only, per P-05) | static toast; same audio | none. Respect one-prompt-per-beat |
| UI tap (buttons, tabs) | Barely-there confirmation | Very soft tick, distinct from key tap by pitch (lower) | 20-50 ms | <= -12 dBFS | system haptic for controls only | same | none; suppress under VoiceOver |
| Ambient loop (P5, later wave) | Optional garden bed | Layers: wind, birds (by phase/season), water, crickets; no melody; key-neutral | loop 60-120 s, 1.5 s crossfade, auto-fade at 10 min | <= -30 LUFS integrated, LRA < 5 LU | optional separate "breathing" haptic toggle, off with Reduce Motion or Low Power Mode | none; also off in Low Power Mode (spec) | none; off by default, offered once after first bloom; stop on background |

Notes: celebrations obey spec 19 caps (win sequences <= 2.5 s, skippable). Quiet Garden mode: replace plant-earned/level/badge fanfares with the quiet tending sound set; Calm mode: -3 dB on effects, no shimmer layer.

### 7.3 Implementation plan for iOS (nothing implemented here; no Swift touched)
1. **Audio session.** At app start: `AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])` (ambient already mixes). Activate lazily on first sound. Do not call setActive(false) on every sound. Observe `interruptionNotification` and `routeChangeNotification`; on interruption end restart the engine; on headphone unplug (`oldDeviceUnavailable`) stop ambient (HIG expects playback to pause when headphones disconnect, PRIMARY).
2. **Engine and preloading.** One `AVAudioEngine` with a small pool (e.g. 8) of `AVAudioPlayerNode`s into a mixer; decode all short SFX to `AVAudioPCMBuffer` at launch off the main thread (they are tiny); `scheduleBuffer` with `.interrupts` for taps. Ambient: separate player for the loop. Fallback to `AVAudioPlayer` pool if engine fails. Preferred IO buffer duration ~5 ms (verify in docs, DERIVED).
3. **API shape.** `enum SoundEvent: CaseIterable` (one case per table row; badge tiers as three cases); `protocol SoundPlaying { func play(_ e: SoundEvent) }`; `SoundMap` (event -> file, level trim, variants, pitch-jitter range, duration cap) loaded from the Motion tokens file (P-05); `FeedbackCoordinator.play(event)` that fires haptic then sound in the same call so one player action = one sound + one haptic.
4. **Settings.** "Sounds" toggle (default on), "Sound effects volume" (Low/Normal, a relative trim; Under-13 default Low), "Garden ambience" (default off), "Haptics" toggle. Keep these in the shared store with defaults. Never touch system volume.
5. **Silent switch.** Rely on `.ambient`. Do not add a "play even when silent" setting. No audio at launch.
6. **VoiceOver coexistence.** If `UIAccessibility.isVoiceOverRunning`: suppress key/UI ticks; keep completion/resting sounds quiet; post announcements for outcomes; never duck/mix over speech (DERIVED).
7. **Skip/cancel.** Celebration sounds are tied to the skip callback: fade the node's volume to 0 over ~120 ms.
8. **Rate limits.** Max 1 tap sound per 40 ms; max concurrent voices 8; a new feedback sound may not start while a celebration is playing unless it's a tap.
9. **Lifecycle.** Stop all on `willResignActive`/background; pause ambient in Low Power Mode.

**Tests we can write (all runnable without hardware):**
- `SoundMap` covers every `SoundEvent` case (exhaustive iteration), every file exists in the bundle and is in the manifest with a license row.
- Duration and level tests: load each file with `AVAudioFile`, assert duration within the table band, sample peak <= the class ceiling, RMS > floor (not silent), no DC offset/clicks (first/last 2 ms near zero).
- Frequency sanity: FFT energy >70% below 4 kHz for all earcons (guards the hearing-loss principle).
- Session test (with a `SessionConfiguring` protocol fake): category is `.ambient`, no `.duckOthers`, no `.playback`; verifies no `setActive` on every play.
- Toggle gating: Sound off -> `SoundPlaying` fake receives zero plays; haptic still plays if haptic toggle on, and vice versa (independence).
- One-per-action: simulate a guess with 3 revealed tiles -> exactly one sound + one haptic.
- Skip: calling skip fades to 0 within 150 ms (fake clock).
- VoiceOver on -> tick events suppressed.
- Calm/Quiet Garden mapping tests (trim -3 dB, fanfares replaced).
- Interruption: fake notification restarts engine; headphone unplug stops ambient.
- Ambient: default off; offered once; auto-fade by injected clock at 10 min; off in Low Power Mode (from spec P5).
- Copy-safety is separate (P16), but VoiceOver announcement strings go through `CopySafety.check`.

### 7.4 Playtest checklist (kids and adults)
Setup: iPhone speaker, AirPods, and at least one older/cheaper device; quiet room and noisy room; parent present for under-13; get consent; no recorded identifiers for kids (spec: analytics off for under-13).
- [ ] Mute-on test: hardware switch on, no sound at all, game fully understood. Settings toggle off, same.
- [ ] Music-mix test: play Spotify/Apple Music/podcast first, launch app, confirm it keeps playing and our effects mix and are not louder than the music.
- [ ] Kids 5-7, 8-12: "Which one means you did it right? Which means try another?" Ask without prompting; measure correct identification of correct vs wrong vs resting sounds with sound-only, visual-only, both.
- [ ] Does the resting sound read as sad/scary/punishing or as sleepy/kind? Ask "How does the flower feel?" Note any child who flinches, laughs, or asks to turn it off.
- [ ] Do kids deliberately trigger wrong letters to hear the sound? (reward/"fun failure" check; if yes, quieten/shorten.)
- [ ] Repetition: 10 rounds in a row (~150 key taps); log when testers say it's annoying; check variants audible but not distracting; test 3 sessions on different days.
- [ ] Loudness: relative balance across tap < wrong < correct < celebrations; any startle on first celebration; test at 25%, 50%, 100% system volume and with AirPods at 100%; no sound makes anyone wince.
- [ ] Latency: finger-to-sound and sound-vs-haptic feel simultaneous; test fast typing; no stacked/overlapping mush.
- [ ] Hearing: test with an adult with mild high-frequency loss or with a high-frequency roll-off simulation; are earcons still distinguishable?
- [ ] VoiceOver user: sounds don't talk over speech; announcements sufficient; nothing important is only audible.
- [ ] Reduce Motion / Calm / Quiet Garden on: sound still coherent and not longer than visuals.
- [ ] Parents' view: would they leave it on in a car/at a table/bedtime? Anything embarrassing in public?
- [ ] Ads/prompt timing: no sound-led peak followed by a loud ad (spec P13 handles the ad rule; confirm ad audio doesn't override our session expectation).
- [ ] Interruptions: incoming call, Siri, alarm, plugging/unplugging headphones, backgrounding.
- [ ] Record verbatim quotes; decide each sound pass/tweak/cut by majority rule (>= 2 of 3 kids and >= 3 of 5 adults neutral or positive; any startle = fix).

### 7.5 Risks and open questions
Risks:
- No retrievable child-specific evidence on error sounds; the design is precautionary. Mitigate with the playtest above.
- Falling interval for resting could still read as "sad" to some kids; fall-back variant is a flat or rising-then-settle contour. Keep two variants ready for A/B (if analytics are allowed; they are not for under-13, so use in-person tests).
- CC0 sound provenance (Freesound); Sonniss AI-training ban; repo exposure. Prefer synthesis.
- System-sound vs AVAudioEngine deviation from HIG sentence on "system's sound services"; confirm acceptable (it is common practice, DERIVED).
- AHAP audio events and silent-switch interaction unverified; hence we keep layers separate.
- Pitch-based meanings may not transfer culturally; mitigated by multi-channel cues.
- Loudness numbers are not authoritative for UI sounds; ear/phone-speaker testing decides.
- Ambient loop battery/size; Low Power Mode handling.
Open questions (for lead decision):
1. Include a key-tap sound at all? (Apple notes keyboard clicks are non-essential sound under silent mode.) Recommend default on, quiet, with its own toggle later.
2. Resting sound: "none" haptic vs `.soft`? Recommend none.
3. Under-13 default for sound effects: Low trim (-3 dB) recommended; confirm.
4. Do we commission a human composer/sound designer for the 6 key earcons, or synthesise in-house? Recommend a short paid pass for plant-earned and resting only.
5. Should the sound toggle live on Home/Game as well as Settings? Recommend Settings plus quick toggle on the Game screen.

## 8. What could not be fetched or verified
- Apple HIG HTML pages (empty body); got content via developer.apple.com tutorials JSON endpoint for playing-audio and playing-haptics and AVAudioSession `.ambient` only. The `.soloAmbient`/`.playback` JSON paths and Core Haptics docs (AHAP with audio) returned 404. The HIG "Sound" page and Apple audio-format/loudness/App Store review guidance not fetched.
- Brewster/Gaver earcon papers, 2023 meta-analysis, Altinsoy and arXiv audio-haptic paper: only search summaries; arXiv PDF text not extractable.
- Stafford Bawler/Monument Valley interview (TLS error on host), Todd Baker interviews, Alto's Adventure audio, Duolingo sound-team talk, Wordle clones, Finch, Forest, Khan Academy Kids, Toca Boca, Sago Mini sound details, any GDC talks: not retrieved.
- WHO/ITU 80 dBA/40 h and any children-specific limit, EN 71-1 numbers: not primary-verified (WHO fact sheet fetched did not state them).
- Research on negative sounds and frustration/learning in children, cross-cultural pitch/consonance associations, child timbre preferences: nothing retrievable.
- All numeric levels, durations, pitches, frequency bands and ffmpeg/afconvert flags are DERIVED defaults, not tested here.

## 9. Thunder (rain days, plant page)
A soft, distant roll that follows the first thunder flash on a plant page. It is original and procedural, so it is licence clean (nothing sampled).

- **Generator:** `tools/make_thunder.py`, pure Python 3 standard library plus ffmpeg for the AAC encode. Deterministic (fixed seed `20261104`): running it twice gives a byte-identical file. Regenerate from the repo root with `python3 tools/make_thunder.py`; it prints duration, peak, integrated loudness, attack and size.
- **Recipe:** brown noise (leaky integrated white noise) with a pinch of white; two hand-coded one-pole low-pass stages whose cutoff sweeps exponentially from 450 Hz down to 180 Hz over the clip (the roll darkens as it moves away); two one-pole high-pass stages at 70 Hz so the energy sits where phone speakers can play it; a slow envelope of three sub-rolls at 0, 0.85 and 1.95 s (raised-cosine rises of 0.5 to 0.7 s, no crack), a little slow random flutter, and a 1.2 s raised-cosine tail fade to silence. Peak normalised to -9 dBFS; 16-bit 44.1 kHz mono WAV, then AAC 64 kb/s.
- **Output:** `WordFlora/Resources/Sounds/wf-thunder.m4a`, 4.6 s, about 38 KB.
- **Measured (ffmpeg `ebur128` / `volumedetect` on the m4a):** peak -9.1 dBFS, integrated -25.9 LUFS (wf-water is -14.5 LUFS, peak -3.3 dBFS), about -34 LUFS through a rough phone-speaker simulation (two 2-pole high-passes at 200 Hz), attack about 0.5 s (50 ms RMS windows, from 40 dB under the loudest window to within 6 dB of it). The catalog gain is 0 dB and the app plays it at 0.35 of the player's level (`ThunderGate.soundVolume`, about -9 dB), so it sits far below every action sound. Kid-startle check: no transient, slow rise, low band only. The first version (220 to 80 Hz, -12 dBFS, -31 LUFS) put nearly all its energy under 100 Hz and was close to inaudible on a phone speaker.
- **When it plays:** only with the first flash of a plant-page visit (each appearance of the page is a visit), 1.5 to 3 s after the flash starts (sound follows light, from far away: `ThunderGate.soundDelay(unit:)`), and at most once every 3 minutes across the whole app (`ThunderGate.rollCooldown`, `AppModel.lastThunderRoll`), so hopping between plants does not stack rolls. Later flashes in the same visit stay silent (`ThunderGate.Visit`, `shouldSound(playedThisVisit:lastRoll:now:)`); the visit is marked played only once the roll has actually run. The first flash itself now waits 4 to 6 s after the page opens (`firstFlashDelay`). On the flash that rolls, the soft haptic fires with the sound rather than 0.3 to 0.5 s after the light, so the thump is never felt before anything is heard; silent flashes keep the early haptic. It inherits every flash condition: thunder rain days only, page on screen, app active, not Reduce Motion, not Low Power Mode, not Calm mode or Quiet Garden. The Sound setting off silences it (no roll, no cooldown use). While it plays the ambient bed ducks (`SoundSpec.ducksAmbient`); ducking keeps two reasons (`DuckState`: read-aloud and thunder) and the bed comes back only when both are done.
- **Known limits:** phone speakers reproduce little below about 150 Hz, so on the built-in speaker the roll is a faint low hush; on headphones it is fuller. A device listening check is still due before the level is final.

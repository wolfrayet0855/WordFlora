# Game effects research, round 3 (5 Opus agents, 2026-11-03)

Rules for all items: positive-only copy, Reduce Motion fallback, no variable rewards tied to currency/ads, effects never next to an ad. Sources are in the agents' reports (many secondary; marked UNVERIFIED there). Haptics and sound pairing must be checked on a device.

## 1. Game feel (juice)
Top 5: tile flip reveal with 60 ms stagger (S); squash and stretch on key press (S); bloom reveal with a 150 ms anticipation beat on win (M); gentle petal loss with a micro-pause and flutter (S); "not this one" key nod on a wrong letter (S). Also: sprout on a new plant (M), three-beat level-up (M), tend follow-through (S). Put spring/keyframe values in a `Motion` token file.

## 2. Collection UX
Top 5: first-bloom reveal ceremony (M); silhouette tease instead of lock icons (S); shareable plant profile card with ShareLink (M); per-level "almost there" rings with no countdown (S, quiet in Quiet Garden); "New" shelf and favourites (S-M, needs a field). Also album page-turn (S), level-complete moment granting a pot (M). Avoid time-limited seasonal sets. Zeigarnik "nagging" does not replicate: do not build on it.

## 3. Sound
Fix first: `SoundPlayer.jitter` changes rate, not pitch (AVAudioPlayer.rate does not shift pitch). Build a small AVAudioEngine with Varispeed. Top 5: pentatonic note per correct letter (S-M, one kalimba sample), real pitch variation (S), haptic+sound in sync under 40 ms (S), win sounds by plant rarity (S, needs 1-2 assets), ambient by time of day (M, needs assets). Butterfly stereo pan is code-only (S). Bundle budget: keep audio under about 3 MB (move the 2.2 MB ambient to AAC).

## 4. Living world
Top 5: time-of-day sky gradient (S); wind sway on all plants (S); seasonal petals reusing FlowerRainView (S); fireflies at dusk 17:30-21:30 (S/M); moon phase (S). Rules: 30 fps max, pause off-screen/Low Power, under 40 particles, no WeatherKit (network), no tilt parallax.

## 5. Wake-a-plant challenges (for the dormant seed, if approved)
Build first: very hard word puzzle (anagram, missing vowels, word ladder; S/M) and petal memory match (S). Bird watch and name is third (needs about 12 fact-checked bird illustrations). Outcomes "Awake" or "Still dreaming, try again anytime"; player-chosen difficulty chips; every challenge has a tap alternative and is free to retry.

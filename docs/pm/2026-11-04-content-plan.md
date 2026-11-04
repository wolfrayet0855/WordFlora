# Content and polish plan, 2026-11-04 (branch 3-feat-content-and-polish)

Six tickets. Each has an owner agent, a reviewer pair (one Sonnet, one Opus), and acceptance tests. Workers follow TDD for code (RED, then GREEN), commit per batch with plain messages (no attribution lines of any kind). Only one worker edits `project.pbxproj` at a time; after every pbxproj change `TARGETED_DEVICE_FAMILY` must still be `1`.

Shared rules for every ticket: positive-only copy at a grade 2-3 reading level (`CopySafety` tests must pass), nothing earned is ever removed, Quiet Garden and Calm mode exempt from petal loss, iPhone only, tests green except the 3 known `StoreKitConfigTests` sandbox failures.

## T-A Word bank: 30 to ~300 words
Owner: Opus lead (structure, merge, difficulty review) + 5 Sonnet writers (one level each).
Requirements: keep the 30 starter entries and the schema (`WordEntry`); add a hero entry for each of the 35 plants without one (level = plant level) and ~215 vocab words (about 43 per level; nature and garden themed first, then everyday words a child meets outdoors) within `WordBankValidator.vocabLengthBands`; hint and `hint2` grade-appropriate; facts true and short; no duplicates; `dailyEligible` true for most; ids `l{level}-{slug}`.
Acceptance: `WordProviderTests` shipped-bank tests pass; new test asserts >= 280 entries, unique words and ids, letters only, hints present and not leaking, every entry's hint/hint2/fact passes `CopySafety`, each level has >= 50 entries; daily selection stays deterministic (seed and epoch unchanged); `bankVersion` bumped.
Reviewers: Sonnet (copy and facts spot check), Opus (difficulty curve, duplicates across levels, kid-appropriateness).

## T-B Name stories for the other 40 plants
Owner: 2 Sonnet researchers (20 plants each, with sources) + 1 Opus integrator.
Requirements: match the pilot `nameStory` shape (`origin`, `language`, `meaning`, `line`, `funFact`, `symbol`); each story factually supported by a source; where the origin is uncertain, use a safe true statement about the name (for example "named after ...") and record `"confidence": "safe"` in the research notes, or leave it out (plain fallback) and list it in `docs/research/name-stories.md`.
Acceptance: `PlantCatalogTests` gets a test that every plant has a story or is listed in an explicit reviewed-fallback set; `line` <= 70 characters, `funFact` <= 140 characters, `meaning` <= 24; every string passes `CopySafety`; symbols are valid SF Symbols names.
Reviewers: Sonnet (reading level), Opus (facts against the research notes).

## T-C Thunder sound
Owner: Opus audio agent.
Requirements: original procedural thunder (`tools/make_thunder.py`, pure Python + ffmpeg, no numpy) rendered to `WordFlora/Resources/Sounds/wf-thunder.m4a` (< 300 KB, about 3-5 s, soft, low rumble, slow attack); `SoundEvent.thunder`; played by the existing `ThunderGate` flash in `RainOverlay` at low volume (about 0.35 of the player's level), at most once per plant-page visit, respecting the sound-off setting and ducking the ambient loop; documented in `docs/research/audio-feedback.md`.
Acceptance: `SoundTests` asserts the asset exists in the bundle, decodes with `AVAudioPlayer`, is under 300 KB and shorter than 6 s; `ThunderGate` unit test for the once-per-visit rule; pbxproj device family still `1`.
Reviewers: Sonnet (wiring and settings), Opus (listening notes from a rendered waveform/spectrogram, kid-startle check: peak level and attack time).

## T-D Pot collection
Owner: Opus visual agent (mockup `design-preview/pots/index.html`), Opus critic, then Opus code worker.
Decision (documented in STATUS): plain blue is free; terracotta, sage, sunflower, starlight, rose pink and mint unlock by play (first plant, 10 plants, level 3, level 5, 25 plants, 50 plants) as mocked earlier; three Plus pots (new one per season later). A pot already applied to a plant stays applied forever; choosing a new Plus-only pot needs Plus. Nothing earned is removed.
Requirements: `PotCatalog` (ids, names, colours, unlock rule, plus flag); `PlantCollectible.potId: String = ""` (defaulted, CloudKit-safe; empty = plain blue); `PlayerProfile` stays unchanged (unlocks are computed from stats, nothing to store); `GardenBackup` carries `potId`; `DataReconciler` merges by "non-empty wins, then the newer `lastTendedAt`"; `TendPot` drawn from the catalog; repot sheet "Pick a pot" row shows owned pots, locked ones dimmed with an unlock hint; Shed shows the "Pots" grid; plant page draws the chosen pot.
Acceptance: unit tests for unlock rules, reconciler merge, backup round trip, every pot name/hint passes `CopySafety`; UI test opens the repot sheet and finds the pot row; pbxproj device family `1`.
Reviewers: Sonnet (data/backup), Opus (UI and rules).

## T-E Rose: curled petal thinning
Owner: Opus visual agent (mockup `design-preview/tending/parts/rose-curl.html` building on `rose-thinning.html`), Opus critic, then Opus integrator.
Requirements: the petals that stay on the rose head curl and droop as pips fall (a curled-edge variant per outer petal and the wrap), consistent with `tools/thin_svg.py` output (`PlantThinning.json` layers and the `PlantLayers` imagesets); the fall sprites stay; PlantLayers growth < 60 KB.
Acceptance: `PlantThinningTests` pass and gain a rose test (curled layers present per pip); asset presence test for the new imagesets; the generation is reproducible from `tools/`.
Reviewers: Sonnet (pipeline/test), Opus critic (look at 5 pip states, light and dark).

## T-F Logo: flowers for the O's
Owner: 3 visual agents (2 Opus, 1 Sonnet) each producing a direction under `design-preview/logo/{a,b,c}/` with `index.html`, wordmark SVG, icon renders at 1024/180/60/29, monochrome and dark versions; an Opus critic scores legibility at 29 px, distinctiveness, kid+adult appeal, colour-blind safety, fit with the app palette (`design-preview/theme.css`); the best is refined; `design-preview/logo/index.html` gathers all three with the critic's notes.
Then (after the review team approves) an integration worker updates `WordmarkView` (Home and Onboarding) in one commit, easy to revert; app icon candidates are placed under `design-preview/logo/icon/` and the `AppIcon` asset is swapped only on a unanimous review team or the owner's go-ahead.
Acceptance: screenshots at each size reviewed; `WordmarkView` keeps the accessibility label "WordFlora"; UI tests and the accessibility audit stay green.

## Order
Wave 1 (parallel): T-A writers, T-B researchers, T-C, T-D mockup, T-E mockup, T-F three directions.
Wave 2: T-A merge, T-B integration, T-D code (after critic), T-E integration (after critic), T-F critic then refine.
Wave 3: review team per ticket, feedback integrated, STATUS updated, final checks (full test run, device family grep, attribution grep, clean tree).

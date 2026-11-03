# Apple Intelligence round 2 (2026-11-03)

Process: Ideator (Sonnet) proposed 8 ideas, Critic (Opus) reviewed them, Ideator answered, a Sonnet research agent checked docs. Doc pages often returned titles only; anything marked UNVERIFIED must be checked in Xcode or on device.

## Agreed build order
1. Adaptive help ladder (FoundationModels, extends GardenAI). Last rung is a deterministic letter reveal. Each AI rung passes HintValidator. Tests stub the model (greedy sampling is not stable across OS model updates).
2. App Shortcuts + PlantEntity. 3-4 intents, phrases contain the app name (max 10 shortcuts, one AppShortcutsProvider). Water goes through the same store function as the widget. No ads/consent inside intents (Guideline 2.5.11). Compile shared intent files into both app and widget targets instead of relying on AppIntentsPackage (forum reports it is unreliable).
3. Control Center water control (ControlWidget, iOS 18, UNVERIFIED in docs). Smart Stack relevance is NOT available on iPhone (RelevanceConfiguration is watchOS 26 only): dropped.
4. Garden journal + plant whispers merged. Swift computes facts; model only phrases around code-inserted tokens; regex rejects digits/plant names not in input; wilt state never passed; cache per day/plant; validate only the final snapshot; re-check availability on foreground.
5. Read-aloud clues (AVSpeechSynthesizer). VoiceOver duplicate speech and silent-switch behaviour need device testing; skip Personal Voice.
6. Later: offline word-neighbour table (NLEmbedding at bank-build time), grown-ups weekly summary (template-only, behind the parental gate, family wording per 2.3.8).

## Dropped / deferred
- Riddle mode: dropped (no validator can prove a riddle points to one answer).
- Plant Spotter (Visual Intelligence): deferred (Vision taxonomy too coarse for 50 plants).
- Sketch-a-Bloom: spec line 78 rules out AI plant ART; spec line 90 allows an optional user-started "Draw my garden" share sticker, labelled AI-generated, adults/age-known only. Kept as low-priority optional.
- Writing Tools, Genmoji, Live Activities: skipped.

## Constraints found
- Context window about 4096 tokens combined; latency unmeasured (use the Foundation Models Instruments template on device).
- availability: unavailable reasons deviceNotEligible, appleIntelligenceNotEnabled, modelNotReady; use @unknown default. Catch every GenerationError to nil.
- iOS 27 cloud/Private Cloud Compute routing conflicts with the on-device-only rule: only ever use SystemLanguageModel.
- 5.1.4 risk is the ads in a mixed-audience app, not these features. Privacy label: on-device history is likely not "collected", but iCloud sync for Plus may change that; check.

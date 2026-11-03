# Apple platform capabilities for WordFlora (research, 2026-11-02)

Scope: spec sections 4, 5, 5b, 14 of `docs/superpowers/specs/2026-11-02-wordflora-v2-design.md`. Deployment target iOS 17.5, SDK 26.5. Read-only research, no code touched.

## 0. Method, source quality, and caveats (read first)

Today is 2026-11-02. iOS 27 shipped (or is shipping) this fall; WWDC26 sessions exist. Evidence tiers:

- **[A] Fetched from developer.apple.com this session**: URLs cited inline.
- **[B] Non-Apple secondary source fetched/searched this session** (marked "non-Apple").
- **[T] From model training knowledge (cutoff mid-2026), NOT re-fetched.** Treat as "verify against docs before building". Most `developer.apple.com/documentation/*` pages are JavaScript-rendered and returned only the page title through the fetch tool, so exact API pages (ImageCreator, SpeechAnalyzer, FoundationModels overview, guardrail guidance) could NOT be read; those entries are [T].
- Fetched text was treated as untrusted data; no instructions in it were followed.
- iOS 27 details are from first-beta-era sessions and may have changed ("most new APIs marked beta" per non-Apple blog).

Pages fetched OK: developer.apple.com/ios/whats-new/ (iOS 27), /videos/play/wwdc2026/241 (Foundation Models), /wwdc2026/297 (Visual Intelligence), /wwdc2026/269 (SwiftUI), /wwdc2026/322 (graphics effects), /wwdc2025/278 (widgets), /videos/wwdc2026/ (list), /news/upcoming-requirements (age rating). Failed (title only): documentation/foundationmodels, imagecreator, speechanalyzer, improving-the-safety-of-generative-model-output.

Key framing for WordFlora: v2 spec section 5 says "no third-party AI so no 5.1.2(i) disclosure issue". iOS 27 adds cloud/third-party models behind the same API. **Rule: only ever use `SystemLanguageModel` (on-device).** Do not adopt `PrivateCloudComputeLanguageModel` or Claude/Gemini providers (breaks "nothing leaves device", kids audience, needs entitlement).

---

## 1. Apple Intelligence and on-device ML

### 1.1 Foundation Models framework
- **What**: `import FoundationModels`; `SystemLanguageModel.default` (check `.availability`: `.available` or `.unavailable(reason)` e.g. device not eligible, Apple Intelligence off, model not ready); `LanguageModelSession(instructions:)` with `respond(to:)`, `streamResponse(to:)`; `@Generable` + `@Guide` guided generation into Swift types; `Tool` protocol (name, description, `@Generable Arguments`, `call(arguments:)`); `Instructions`/`Prompt` builders; `GenerationError` cases (guardrail violation, context exceeded, unsupported language, etc.); `prewarm()`; `GenerationOptions` (temperature, sampling). [T] for most; framework existence and `LanguageModelSession`, tools, `@Generable` confirmed by non-Apple guides.
- **Min OS/device**: iOS 26, Apple Intelligence-eligible hardware (iPhone 15 Pro and newer), feature toggled on, model assets downloaded. [T + non-Apple guide]
- **iOS 26.4 additions [A]**: `SystemLanguageModel.contextSize` and `tokenCount(for:)`; guardrails refined to cut false positives (further in iOS 27). Source: https://developer.apple.com/videos/play/wwdc2026/241
- **iOS 27 additions [A]**: rebuilt on-device model (better logic and tool calling); **image input** via `Attachment(UIImage/CGImage/CIImage/CVPixelBuffer/URL)` in the prompt builder; `LanguageModel` protocol; `PrivateCloudComputeLanguageModel` (32K context, reasoning levels, entitlement `com.apple.developer.private-cloud-compute`); `response.usage` token counts; Dynamic Profiles (`LanguageModelSession.DynamicProfile`); system tools `BarcodeReaderTool`, OCR tool, `SpotlightSearchTool`; Foundation Models instrument in Xcode 27; Evaluations framework (Swift Testing based); `fm` CLI (macOS 27); core framework being open-sourced. Sources: https://developer.apple.com/ios/whats-new/ , wwdc2026/241; detail from non-Apple blog https://ivanmagda-dev.pages.dev/posts/wwdc26-foundation-models-year-two .
- **Context limit**: on-device 4,096 tokens per session in Apple docs (non-Apple blog cites this; a wwdc241 page excerpt showed `contextSize` printing 8192 as an example). Never hard-code; read `contextSize` at runtime (iOS 26.4+), keep prompts tiny (our grounded `fact` + `hint` is ~100 tokens, fine).
- **Adapters**: custom LoRA adapters exist but need an entitlement and per-OS-version retraining. Skip. [T]
- **Performance** [T]: first-token latency roughly sub-second after `prewarm()`, tens of tokens/s on A17 Pro/A18; battery cost meaningful for long streams. Do not run while a round animates; generate on user tap only.
- **Kids' content**: the framework has built-in guardrails on input and output and you cannot disable them; `Instructions` can push tone. No Apple page found stating a kids-specific rule for FM; App Review treats generated text like any UGC-ish content: you are responsible (Guideline 1.1/1.2 and 5.1.x). Our grounded + validated design (spec 5) is the right posture. [T]
- **WordFlora use** (all already in spec): adaptive hint, Tell me more (stream), garden journal (`@Generable`), tending voice lines, Ask the Gardener (topic-guarded), tool calling for plant/garden lookup. New: **image input** in iOS 27 could let "Find a plant" ask the language model to describe a photo, but prefer Vision (deterministic, no hallucinated species). Skip image-to-FM.
- **Effort**: M for the first feature (availability gating + validation harness), S for each added feature. **Priority: should** (Tell me more + adaptive hint with answer-leak validator); Ask the Gardener = nice (moderation risk, long tail of prompt abuse; keep to curated question chips plus free text only for 13+).
- **Review/privacy**: no network, no data collection, no 5.1.2(i) disclosure if purely on-device. Label output "Written by on-device AI". Do not log prompts to analytics. Keep an answer-leak validator and banned-wording list (already specced). Use the Evaluations framework (iOS 27 SDK, Xcode 27) to regression-test hint safety. Foundation Models instrument for profiling.

### 1.2 Image Playground / ImageCreator
- `ImageCreator` (async, programmatic) and `ImagePlaygroundViewController` / SwiftUI `imagePlaygroundSheet(...)` (iOS 18.1+, Apple Intelligence devices). Styles: animation, illustration, sketch (+ Genmoji-like emoji styles). [T, page fetch failed]
- Use: spec's optional "Draw my garden" share sticker. Concept inputs from plant names (text concepts) or user's photo. **Risks**: output quality uncontrolled (off-brand vs our hand-made art), safety filters applied by Apple, user-initiated only, skip under-13 (spec), label AI-generated. **Effort S-M. Priority: skip for v1, nice later.** Reason: brand consistency, review burden, low differentiation vs bundled art.

### 1.3 Writing Tools, Genmoji, Live Translation, Smart Reply
- System features, no code. Keep `Text` selectable (`.textSelection(.enabled)`) on facts/hints for Writing Tools, Translate. Genmoji works in standard text fields via `adaptiveImageGlyph` support (iOS 18.1+); our app has no free text except possibly Ask the Gardener and plant nicknames. Nicknames: allow Genmoji? **skip** (moderation/share cards).
- Live Translation (Messages/FaceTime/Phone) irrelevant. **Translation framework** (iOS 18: `TranslationSession`, `.translationPresentation`; iOS 26 programmatic on-device): useful for the localization phase (spec 10 says localization out of scope); could translate `fact` text on device, but vetted copy must be human-reviewed per spec 2. **Priority: skip** (note for localization).

### 1.4 Visual Intelligence via App Intents
- **What [A]**: https://developer.apple.com/videos/play/wwdc2026/297 . Implement `AppEntity` (with `DisplayRepresentation` and thumbnail), `IntentValueQuery` receiving `SemanticContentDescriptor` (has `pixelBuffer`), return `VisualSearchResult` (use `@UnionValue` for multi-type), plus `OpenIntent`. Optional `semanticContentSearch` schema for in-app handoff. Vision `GenerateImageFeaturePrintRequest` for image similarity. Now on iOS, iPadOS, macOS. Introduced iOS 26 for developers (non-Apple/T).
- **WordFlora use**: user points camera/screenshot at a plant; WordFlora returns matching plant cards from our 50 via feature-print similarity of our own plant art/photos. Honest limitation: our assets are illustrations, so similarity vs real photos is weak; would need real reference photos (licensing) or a classifier. Tie into "Find a plant" (section 8).
- **Min**: iOS 26 (T), device eligibility follows Visual Intelligence (iPhone 15 Pro+ camera control or Action button; screenshots broader). **Effort M. Priority: nice** (stretch in spec 5b; depends on a real-photo classifier).

### 1.5 App Intents, Siri, Spotlight, Shortcuts
- **iOS 27 [A]** (https://developer.apple.com/ios/whats-new/ , sessions 240, 343, 344, 345, 295, 310 from https://developer.apple.com/videos/wwdc2026/): entity schemas add content to the Spotlight semantic index so Siri can surface it with attribution; intent schemas (assistant schemas) let people act on content without fixed phrases; View Annotations API maps views to entities for on-screen awareness; App Intents Testing framework. Core Spotlight LLM search.
- **Earlier [T]**: App Shortcuts (`AppShortcutsProvider`, auto-available, no setup, iOS 16+), `ControlWidget` controls (iOS 18), interactive snippets `SnippetIntent` (iOS 26), `IndexedEntity`/Spotlight (iOS 18/26), intent donation, `@AppIntent(schema:)` domains (Apple lists app domains: books, browser, camera, mail, photos, etc.; **no games/gardening domain known**, so assistant schemas for WordFlora are limited to generic/on-screen entity schemas [T, verify]).
- **WordFlora use**: "Water my garden", "Play today's Daily Bloom", "What's blooming?" App Shortcuts with parameterised `PlantEntity` (index all 50 plants into Spotlight; kids can search "rose" and open the plant card). Interactive snippet that shows garden status with a water button. Reuse widget intents (spec 4).
- **Min**: App Shortcuts/Spotlight donation iOS 16/17; snippets iOS 26; schemas iOS 27 (verify device/language: Siri LLM features need Apple Intelligence). Graceful: basic App Shortcuts work on iOS 17.5.
- **Privacy/review**: intents expose state to Siri/Shortcuts; keep results free of personal data; `isDiscoverable`. Under-13: nothing special. **Effort M. Priority: must** (water + Daily Bloom intents are already needed for the widget; Spotlight plant entities = should).

### 1.6 Speech: SpeechAnalyzer
- iOS 26: `SpeechAnalyzer`, `SpeechTranscriber`, `DictationTranscriber`, `AssetInventory` for on-device language assets; long-form, low-latency, fully on-device. Older `SFSpeechRecognizer` (iOS 10+, `requiresOnDeviceRecognition` iOS 13+). [T, page fetch failed]
- Use: "Say a letter" voice guessing. Problem: single letter recognition is poor for ASR ("bee/be/B", "see/sea/C"). Better: map phonetic words ("B as in bee") plus a custom `AnalysisContext` contextual strings. Needs mic permission and Speech permission (`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` for legacy). Kids: voice from minors; on-device only, no storage, no logging; mention in privacy policy and parental gating under 13 (COPPA: voice recordings are personal info if sent off-device; keep on device, state it).
- **Effort M. Priority: nice** (accessibility value for motor impairments; accuracy risk). Fallback: `SFSpeechRecognizer` on-device for iOS 17.5; or hide feature.

### 1.7 Vision / Core ML / Core AI / NaturalLanguage
- **Vision**: `ClassifyImageRequest` (iOS 18 Swift API; legacy `VNClassifyImageRequest` iOS 13), `GenerateImageFeaturePrintRequest`, `RecognizeTextRequest`, `DetectBarcodesRequest`. Built-in taxonomy (~1,300 labels) includes generic "plant", "flower", some species-level labels (coverage inconsistent). [T]
- **Core ML + Create ML**: train a small image classifier (50 plants + "other") with Create ML Image Classifier; ~5-10 MB model; on Neural Engine. Needs a licensed photo dataset (>= 100 images per class; use public domain/CC0 sources, document licences) [T].
- **Core AI (new, iOS 27) [A]**: https://developer.apple.com/ios/whats-new/ (sessions 324-326): load/run models with a memory-safe Swift API, AOT compilation, stateful execution. iOS 27 only, so keep Core ML for 17.5+. **Skip** for v1.
- **NaturalLanguage**: `NLTagger` lemma, `NLEmbedding` word embeddings (sentence similarity) for answer-leak validation (hint contains answer or synonyms) and `NLLanguageRecognizer`. Available iOS 12/14+. **Effort S. Priority: should** (cheap safety net for AI hints, backward-compatible).
- **Difficulty tuner**: plain deterministic heuristic over GameRecords beats a Create ML model for 300 words. Use `MLBoostedTreeRegressor` only if telemetry exists. **Priority: nice**; ship a heuristic first.

---

## 2. Haptics

- **SwiftUI `.sensoryFeedback(_:trigger:)`** iOS 17+: `.success`, `.warning`, `.error`, `.selection`, `.impact(weight:intensity:)`, `.increase/.decrease`, `.start/.stop`, `.alignment`, `.levelChange`, `.pathComplete`. Zero-boilerplate, honors system haptics setting. **Must** for letter reveal/wrong key/win. Effort S. [T]
- **Core Haptics** (`CHHapticEngine`, `CHHapticPattern`, AHAP files) iOS 13+; transient + continuous events, parameter curves (intensity/sharpness). iPhone 8+ only; check `CHHapticEngine.capabilitiesForHardware().supportsHaptics`; not on iPad. Use for "rain on water" (continuous low-intensity with tapering curve), soft thump on soil, bloom crescendo. AHAP assets = data, designer can iterate. **Should**, Effort M. [T]
- **Haptic audio patterns**: `CHHapticAudioResource` / audio events inside an AHAP to sync SFX with haptics; keep audio short and respect silent switch (AVAudioSession `.ambient`). **Nice**.
- **Accessibility**: respect system "System Haptics" toggle (sensoryFeedback does automatically; Core Haptics does not for custom engines: check `UIAccessibility`/user setting and our own Settings toggle; also Reduce Motion should not disable haptics but provide the toggle). Avoid strong repeated patterns near young kids/sensory sensitivity; keep intensities low by default. UIFeedbackGenerator still fine for fallback.
- **iOS 26/27 news**: I found no new haptic API in the pages fetched this session (not verified exhaustively). Game controller haptics (`GCController.haptics`) irrelevant.
- **Fallback**: iOS 17.5 has sensoryFeedback and Core Haptics; no gating needed except device capability.

---

## 3. Motion and graphics

| Capability | Min | WordFlora use | Notes | Effort | Priority |
|---|---|---|---|---|---|
| `keyframeAnimator`, `phaseAnimator` | iOS 17 | Petal fall arc, idle sway, win bounce | Already within 17.5 target. Test on SE-class. | S-M | must |
| `MeshGradient` | iOS 18 | Day/dusk/season backgrounds | Gate `#available(iOS 18)` with LinearGradient fallback. Static or slow-animating; costly if animated full-screen. | S | should |
| Zoom navigation transition (`.navigationTransition(.zoom(sourceID:in:))`, `matchedTransitionSource`) | iOS 18 | Plant card flies into Garden | Fallback: `matchedGeometryEffect` or default push. | S | should |
| `scrollTransition`, `visualEffect`, scroll APIs (`scrollTargetBehavior`, `onScrollGeometryChange` iOS 18) | iOS 17/18 | Garden grid polish | Cheap. | S | should |
| SF Symbols 6/7 effects: `.symbolEffect(.bounce/.pulse/.variableColor/.wiggle/.rotate/.breathe)` (wiggle/rotate/breathe iOS 18; Draw On/Off and variable draw in SF Symbols 7, iOS 26) | 17/18/26 | Drop/sun icons, toasts | Gate; fallback no effect. | S | should |
| `contentTransition(.numericText)` | iOS 17 | Water counters | | S | must |
| Metal shaders `.colorEffect/.distortionEffect/.layerEffect` + `ShaderLibrary` | iOS 17 | Breathing/sway plants, shimmer for Rose revive. WWDC26 s322 shows domain warping with noise texture + `TimelineView(.animation)` [A] https://developer.apple.com/videos/play/wwdc2026/322 | Stateless; pass time. Shaders cannot render in some previews; test device power. | M | nice (one hero shader: sway) |
| `Canvas` + `TimelineView` particles | iOS 15/17 | Flower rain, confetti | Keep < ~300 particles, pause off-screen, `.animation(paused:)`. | M | must (spec core) |
| SpriteKit `SKEmitterNode` (`SpriteView`) | iOS 14 | Alternative for particles (GPU) | Heavier dependency; Canvas is enough. Use if profiling shows Canvas costly. | M | skip |
| RealityKit/SceneKit | | 3D garden | SceneKit deprecated in iOS 26 (soft-deprecation per WWDC25, T). Do not adopt. | L | skip |
| Liquid Glass: `glassEffect(_:in:)`, `GlassEffectContainer`, `glassEffectID`, `.buttonStyle(.glass)` | iOS 26 | Chrome only (tab bar, floating buttons, sheets recompile automatically with SDK 26.5) | Content layer (garden art) stays flat; glass is for controls. iOS 27 adds `appearsActive`, interactive glass elements, `Tab(role: .prominent)`, `toolbarMinimizeBehavior` [A] https://developer.apple.com/videos/play/wwdc2026/269 . Gate `#available(iOS 26)`; fallback `.ultraThinMaterial`. Beware contrast on cream background; design must be approved by user. | S-M | should (system chrome free; custom glass nice) |
| Icon Composer (Xcode 26+) `.icon` file: layered, Liquid Glass appearances, default/dark/clear/tinted | iOS 26 build; iOS 18 appearances | Evergreen icon (spec 9/11) | Layers must be separated art; verify face and yellow-green at tinted/clear. Session 8012 Icon Composer lab [A list]. | S-M | must |
| Reduce Motion: `@Environment(\.accessibilityReduceMotion)`; also `accessibilityPrefersCrossFadeTransitions`, `accessibilityDimFlashingLights` (iOS 18? [T]) | iOS 13+ | Every animation gets a fade alternative; keep flash < 3Hz | Test with Reduce Motion on; shader/particle layers off. | S per feature | must |

Battery rule: pause TimelineView when scene not active (`scenePhase`), `.animation(minimumInterval:)` to 30fps for ambient layers, drawingGroup only when profiled.

---

## 4. Widgets, Live Activities, Watch

- **WidgetKit baseline** (iOS 17): interactive widgets via `Button(intent:)` / `Toggle(isOn:intent:)`, container background API, `containerBackground`, StandBy. Spec 4 is aligned. [T]
- **Controls (iOS 18)**: `ControlWidgetButton/Toggle`, `StaticControlConfiguration`/`AppIntentControlConfiguration` in Control Center, Lock Screen, Action button. Use: "Water garden" control (Button) and "Play Daily Bloom". Effort S once intents exist. Min iOS 18; fallback widgets only. **Should**.
- **iOS 26 [A]** (https://developer.apple.com/videos/play/wwdc2025/278): `widgetRenderingMode`, `widgetAccentedRenderingMode(_:)` (tinted Home Screen: `.desaturated` / `.accentedDesaturated` for our art), push-updated widgets (`WidgetPushHandler`, `pushHandler(_:)`, APNs `apns-push-type: widgets`, topic `<bundle>.push-type.widgets`), `supplementalActivityFamilies(.small)`/`activityFamily` for CarPlay and Watch Live Activities, Live Activities on Mac menu bar (iOS 18+ phones, no code), controls on macOS and watchOS, visionOS widget APIs (`widgetTexture`, `supportedMountingStyles`), watchOS Smart Stack `RelevanceConfiguration`.
  - **WordFlora**: must support tinted/accented mode: provide desaturated plant art; verify Lock Screen readability. **Must** (iOS 18 tinted is already user-visible; effort S-M).
  - Push widget updates need a server: **skip** (no backend; local timeline + `reloadTimelines` suffice; also adds APNs/privacy).
- **iOS 27 [non-Apple, lavx.hu]**: extra-large widgets (iPad Today), real-time widget updates when app open, Live Activities in landscape Dynamic Island. Apple says "widgets customized through App Intents and dynamic styling" [A whats-new]. Sessions "WidgetKit foundations" (277), "Live Activities essentials" (223). Details NOT read; verify.
- **Live Activities**: spec 10 says no. A good, low-risk candidate later: "Butterfly garden session" countdown? Skip. Local-start Live Activities are limited and ActivityKit adds push/permission overhead; guilt risk. **Skip**.
- **Lock Screen accessory families** (iOS 16): `accessoryCircular/Rectangular/Inline`. Already in spec. Smart Stack relevance on iOS 26? `RelevanceConfiguration` is watchOS only per source; iOS has `relevance()` in timeline entries (iOS 17/18) to boost Smart Stack: set a relevance score at "plant needs water" and Daily Bloom time. **Should**, S.
- **Apple Watch companion** (watchOS 10+): complications via WidgetKit accessory families (reuse), standalone small app (tend plant tap). Needs SwiftData sharing via WatchConnectivity/CloudKit; adds a target and review surface. **Nice, L**. Defer after v1.
- **App Clips**: could host "Daily Bloom" instant play via QR/link (share card link). 15MB limit (iOS 16+), needs Associated Domains + backend for the App Clip Experience; kids' links add complexity. **Skip**.
- **Home Screen quick actions** (`UIApplicationShortcutItem` / SwiftUI via `UIApplicationDelegate`): "Daily Bloom", "Water garden". iOS 9+. **Should**, S (dynamic shortcut for chosen tool).

---

## 5. Notifications

- Local only (spec). `UNUserNotificationCenter`; `UNNotificationInterruptionLevel`: `.passive`, `.active`, `.timeSensitive` (needs capability, only for real time-critical; **never** for a game), `.critical` (no). Use `.passive` for tending nudges, `.active` for Daily Bloom at the player-chosen time. [T]
- **Scheduled Summary / Focus**: passive items go into the summary by default; Focus filters (`SetFocusFilterIntent`, iOS 16) can let the app read the active Focus: e.g. hide ads/notifications in "Sleep" or "School". **Nice**, S-M; cheap polish for kids (`SetFocusFilterIntent` to silence nudges in School Focus).
- **Apple Intelligence notification summaries (iOS 18.1+)**: on-device summarization may rewrite our copy. Mitigate: short, self-contained, one-idea titles; avoid ambiguous phrasing like "your plant is wilting" (summaries can turn into alarming "plant is dying"); keep `Notification` category set to avoid summarization? Apple provides no per-app opt-out other than users, but `UNNotificationInterruptionLevel.timeSensitive` is exempt (do not use). Apple restricted summaries for News apps after errors (iOS 18.3 [T]). Write copy to be summary-safe and test with Apple Intelligence summary on a device. **Must test**.
- **Grouping/threading**: `threadIdentifier` per plant, `summaryArgument`. **Rich/media**: attachments (`UNNotificationAttachment`) of the plant art; notification service extension not needed for local. Content extension (custom UI) = skip (effort, review). **Should** for attachment only.
- **Provisional authorization** (`.provisional`, iOS 12): delivers quietly without a prompt. Spec says ask when player turns "remind me" on. Provisional could let kids receive without a scary dialog, but spec's explicit opt-in is cleaner for the review. **Skip**.
- **Kid-safe use**: max 1/day, quiet hours, stop after 3 days unopened, no guilt wording; no notifications for under-13 without parental consent? COPPA does not require it for local notifications, but a parent toggle is good practice. Local notifications cannot be hit by iOS 26 limit changes (a 64 pending cap persists).

---

## 6. Games, engagement, commerce, family

### Game Center / Games app
- **iOS 26 [non-Apple + Apple doc search results]**: Game Center renamed into the **Games** app. **Challenges** (score challenges via leaderboard; achievement challenges), **Activities** (links into leaderboards or matches), friends activity, Game Overlay, cross-platform invitations. Developer docs: https://developer.apple.com/documentation/appstoreconnectapi/game-center-challenges ; session https://developer.apple.com/videos/play/wwdc2025/214 . Configure in Xcode 26 via a GameKit bundle. App can have up to 20 challenges; challenges require approval; both players need iOS 26+. Forum reports of challenges/activities not appearing (unofficial). [partly B]
- **WWDC26 Game Center**: no session found in titles list; I could not confirm iOS 27 Game Center changes.
- **WordFlora use (spec says phase 3)**: leaderboard "Daily Bloom streak" and achievements mirror badges; **Challenge**: friends compare Daily Bloom (fewest wrong guesses), no real-time. Access point on Home only (`GKAccessPoint`). **Risks**: kids and social features: Game Center is account-gated (Apple Account, child accounts supervised; friends controlled by parents), and **leaderboards can pressure kids**; keep optional, positive framing, no free-text names beyond Apple's. Min iOS 17.5 for GameKit; Challenges iOS 26. **Effort M. Priority: nice (phase 3)**.
- **GameSave / SharePlay**: Game Center "Games" save state? skip. SharePlay `GroupActivities` for co-solving Daily Bloom over FaceTime (iOS 15+): fun for families; effort L, new surface for chat safety (none, system FaceTime). **Nice/skip for v1**.
- **Messages extension / stickers**: Sticker pack of plants/visitors (no code possible via `.xcstickers` sticker pack extension; zero code, iOS 10+). Great shareable growth channel, kid-safe. **Should**, S (needs art export). iMessage game app extension: L, skip.
- **Share cards**: `ShareLink` with `Transferable` image/`Image` + `SharePreview` already in spec; add `ImageRenderer` (iOS 16) for card. **Must** (exists).

### App Store features
- **In-app events** (iOS 15; App Store Connect), **custom product pages**, **Product Page Optimization** (A/B icon/screenshots). No code. **Should**: seasonal events ("Spring bloom week"), CPP for "kids/parents" vs "word puzzle fans". S (non-engineering).
- **StoreKit 2** (iOS 15+): `Product`, `Transaction.currentEntitlements`, `Transaction.updates`, `Product.SubscriptionInfo.isEligibleForIntroOffer` (spec uses). SwiftUI **`SubscriptionStoreView`** (iOS 17), `StoreView`, `ProductView`, `.subscriptionStoreControlStyle`, `.subscriptionStorePickerItemBackground`, `subscriptionStoreButtonLabel`, `manageSubscriptionsSheet`, `.storeButton(.visible, for: .restorePurchases)`; promotional/win-back offers (win-back: `Product.SubscriptionOffer.winBack`... `Message` iOS 18/`SubscriptionStoreView` supports win-back and offer codes; win-back offers iOS 18 [T]). **Effort S-M; Priority must**: use `SubscriptionStoreView` (saves review risk: Apple-rendered price/terms/restore). iOS 27 IAP session 210 and 391 (subscriptions for groups and organizations), 378 StoreKit + Background Assets [A list only, content not read]. Retention messaging (309). Consider offer codes for teachers/families. `AppTransaction`, `appAccountToken`.
- **Family Sharing**: enabled in spec; **Ask to Buy** is system-handled for family-organizer-managed child accounts and returns `.pending` from `purchase()`: handle `Product.PurchaseResult.pending` UI ("waiting for approval"). **Must**, S.
- **Declared Age Range API** (`DeclaredAgeRange` framework, `AgeRangeService`, `requestAgeRange(ageGates:in:)`, entitlement `com.apple.developer.declared-age-range`; iOS 26; expanded in iOS 26.2 for Texas SB2420, Utah from 2026-05-06, Louisiana from 2026-07-01; non-Apple + forum): returns an age category, not a birthdate, with parent sharing consent. [B] https://developer.apple.com/forums/thread/810754 , https://ppc.land/declared-age-range/ . Use: replace/augment our neutral age screen: on iOS 26+ ask system for range, fall back to our age screen on 17.5-25. Important compliance direction. **Should/must** depending on US-state obligations: Texas law concerns app stores, with developer duties around significant changes (age rating changes) and re-consent. Effort M. Verify exact developer obligations in Apple's Texas SB2420 pages (not read in full). Do not store the range beyond a coarse flag; treat as user-declared, not verified. An unverified non-Apple claim of a 13+ floor for "social" apps from Sept 2026: ignore for us (no social features).
- **Age rating updates [A]**: new age rating tiers (13+, 16+, 18+) live; ratings answers required by 2026-01-31: https://developer.apple.com/news/upcoming-requirements/?id=age-requirements . Re-answer questionnaire in App Store Connect; ads (AdMob), in-app controls, and "AI generated content" questions matter. With FoundationModels features, answer honestly; the new questionnaire has items for generative AI/chat-style features [T verify].
- **Screen Time / Family Controls** (`FamilyControls`, `ManagedSettings`, `DeviceActivity`; iOS 15, child authorization iOS 16): lets parent apps limit other apps; WordFlora could expose "screen-time friendly session end". Needs entitlement approval; our app is not a parent-controls app. **Skip**. A cheap alternative: in-app optional "bedtime window" (spec's night-visitor window).
- **Sensitive Content Analysis** (`SensitiveContentAnalysis`, SCSensitivityAnalyzer; iOS 17): for apps with user-shared images; we have none (camera for plants, not shared). **Skip** unless community photos arrive; note: if "Find a plant" ever uploads/shares, add it.
- **Parental gate**: no Apple API; build our own (spec). Required for kids' links/purchases per Guideline 1.3/5.1.4 if Kids category (not) but spec chooses it.

---

## 7. Persistence, platform, accessibility

- **SwiftData + CloudKit**: `ModelConfiguration(cloudKitDatabase: .private("iCloud.<id>"))` iOS 17.4+ API for `cloudKitDatabase` (works with spec); constraints: optional/default values, no `@Attribute(.unique)`, relationships optional [T]. iOS 18 adds `#Index`, `#Unique`, custom `DataStore`, history API, `@Query` fetch-limit/perf; iOS 26 SwiftData additions (model inheritance, `Observations`?) [T]; WWDC26 session 274 "What's new in SwiftData" exists [A list], content not read. **Gotchas**: CloudKit schema must be deployed to production before release (cannot remove fields). Test on two devices. Effort M-L (spec). Priority must (paid feature).
- **CKSyncEngine** (iOS 17): lower-level sync with custom conflict control; useful if SwiftData merge by max/union can't be expressed; SwiftData CloudKit uses last-writer-wins on field-level — our monotonic merge needs app-level fix-ups. Mention as fallback; **nice/skip** unless conflict tests fail.
- **App Groups**: shared store container (spec 4). Widget reads must be read-only/lightweight; avoid multiple writers with CloudKit enabled in both targets (enable CloudKit only in app target; widget uses `.none` read of same store—verify; common crash/dup-sync pitfall). [T]
- **iCloud Drive / KVS**: `NSUbiquitousKeyValueStore` (1MB) could sync small settings for FREE users... conflicts with paid sync model; skip.
- **Swift 6 concurrency / Observation**: Observation (`@Observable`, iOS 17) fits; Swift 6 language mode strict concurrency; `@MainActor` default isolation in Xcode 26 (approachable concurrency, `-default-isolation MainActor`) [T]. WWDC26: `@State` as macro, `ContentBuilder` [A https://developer.apple.com/videos/play/wwdc2026/269]. Effort M to migrate. **Should** (adopt incrementally, language mode 5 with warnings).
- **Perf tools**: Instruments (SwiftUI instrument, Animation Hitches, Power Profiler, Foundation Models instrument in Xcode 27 [A]), Xcode Previews. **Must** for the 60fps SE-class budget.
- **Swift Testing** (`@Test`, `#expect`, Xcode 16): migrate unit tests; App Intents Testing framework (s295 [A list]); Evaluations framework for AI hints [A]. **Should**.
- **TipKit** (iOS 17): `Tip`, `TipView`, `.popoverTip`, rules/events, `Tips.configure`; local, no network; CloudKit sync option off. Use: onboarding ("Tap the can to water", widget add tip, Rose revive). Kid-friendly, honors "one prompt per beat" only if we gate it: wire to the same beat gate. **Must** (S).
- **App Attest** (`DCAppAttestService`, iOS 14; session 201 in WWDC26 [A list]): protects the optional remote WordBank/remote-config CDN? Not needed for static signed JSON (use signature check). Needed only if we add a backend granting rewards. **Skip** for v1 (note: ad/IAP server-side validation not needed since StoreKit 2 verified on device).
- **Background Assets** (iOS 16+, managed assets iOS 26 + App Store hosting Apple-hosted packs): deliver seasonal plant sets/art packs and Apple-hosted bank updates without our own CDN; session 378 "Unlock in-game content with StoreKit and Background Assets" (WWDC26) [A list]. Fits "seasonal plant sets via bank updates" (spec 1). Effort M; hosted by Apple, no server to run and no extra privacy disclosure. **Should** (instead of own CDN). Verify min OS (Apple-hosted assets iOS 26) and fall back to bundled JSON on 17.5.
- **MetricKit** (`MXMetricManager`, iOS 13; hang/crash diagnostics iOS 14): privacy-light crash/launch/hang metrics without third-party SDK. Fits "first-party only". **Should**, S.
- **Privacy manifests** (`PrivacyInfo.xcprivacy`): required for the app and every SDK (AdMob, UMP) with Required Reason APIs (UserDefaults CA92.1, file timestamp, disk space, boot time). Mandatory for submission. **Must**, S. Declare data types (ads: device ID, ad data) and `NSPrivacyTracking` false for under-13 configuration? tracking is per-app declaration: set true with domains if AdMob personalization is used by adults; ATT prompt.
- **ATT**: `ATTrackingManager.requestTrackingAuthorization`; spec orders UMP then ATT. iOS 26: no change known. Child-directed: skip ATT for under-13 sessions.
- **Accessibility**: VoiceOver labels/values/traits (`accessibilityLabel`, `accessibilityValue`, `accessibilityAdjustableAction`, `accessibilityRepresentation`), Dynamic Type incl. `@ScaledMetric`, Switch Control (focus order, no drag-only actions: provide tap alternatives for tool drag, prune minigame, butterfly net), AssistiveTouch, Voice Control (`accessibilityInputLabels`), Reduce Motion/Transparency/Differentiate Without Color (`accessibilityDifferentiateWithoutColor`, important for petals), Increase Contrast, Bold Text, Audio Graphs no. iOS 26 Accessibility Nutrition Labels in App Store Connect (declare VoiceOver, Voice Control, Larger Text, Dark Interface, Differentiate Without Color, Sufficient Contrast, Reduced Motion, Captions, Audio Descriptions) [T, verify]. Effort M; **Must** (and a marketing plus). WWDC26 s220 "Refine accessibility for custom controls" [A list].
- **Other devices**: iPad layout is out of scope (spec 10) but app will run on iPad in compatibility; Apple Silicon Mac "Designed for iPad" and visionOS compatible run default unless you opt out in App Store Connect; decide (**opt out of Vision/Mac for v1** unless tested). Watch: see section 4.

---

## 8. Camera, ML, AR

- **Plant identification**: 
  - Vision built-in classification (`ClassifyImageRequest`) is generic ("flower", "plant"); species accuracy for our 50 is unreliable. Use only to gate "is this a plant at all".
  - Custom Create ML image classifier on 50 plants + background class: honest confidence threshold (>= 0.8), "not sure" state, on-device (Core ML). Dataset licensing is the real work. Effort M-L; **should (as "Find a plant" bonus)** but only after photo dataset exists; otherwise **nice**.
  - Photo-based Visual Look Up (iOS 15+, system Photos feature, no API). Apps cannot invoke it except `ImageAnalysisInteraction` (VisionKit, iOS 16/17) which supports Live Text and subject lifting and "Look Up" menu for images in your app [T]. Could be used on garden art? No.
  - Vision subject lift `VNGenerateForegroundInstanceMaskRequest` (iOS 17): lift a leaf/flower from a photo into the Garden as a sticker. **Nice**, S-M, fun and on-device.
- **Camera capture**: `AVCaptureSession` or SwiftUI-friendly `PhotosPicker`/`UIImagePickerController`; iOS 17 `AVCaptureEventInteraction` lets volume/Camera Control trigger capture; `NSCameraUsageDescription`. For kids: process in memory, never store/upload (spec). Keep it **explicit user tap**, show what is analysed.
- **ARKit / RealityKit AR Quick Look**: `QLPreviewController` shows `.usdz` model on a table (iOS 12+); 3D plant models are an art cost (50 plants). A single generic "bloom in your room" could be done for the best 3 plants. **Skip for v1**; nice later. Object Capture (macOS) can generate USDZ from photos but requires real plants; production cost high.
- **Live Text** (`ImageAnalyzer`, `ImageAnalysisInteraction`, iOS 16+): scan seed packets to link plants? Gimmick. **Skip**.
- Privacy/review: Camera permission string must explain "to recognise plants, photos stay on your device". Under-13 camera use: gate behind parental toggle (best practice). Do not use face or location metadata.

---

## 9. Fallback strategy for iOS 17.5-25 users

1. **One capability façade per feature** (protocol + factory): `HintProvider` (static `hint2` vs FM), `PlantStoryProvider`, `JournalProvider`, `VoiceLineProvider`, `PlantRecognizer`, `HapticsProvider`, `BackgroundProvider`. The factory returns FM/Vision variants only when `#if canImport(FoundationModels)` and `if #available(iOS 26, *)` and `SystemLanguageModel.default.availability == .available`; otherwise static/template implementations. Views never mention the model type.
2. **Content parity**: every AI string has a bundled authored equivalent (`hint2`, `fact`, journal templates, voice-line tables). Offline authoring is the safety net; the AI is garnish.
3. **Availability states**: unavailable reasons (device not eligible, Apple Intelligence disabled, model not ready) -> hide AI affordance entirely (no teasing); "model not ready" -> retry quietly later.
4. **UI**: iOS 26 Liquid Glass chrome gated; below, standard `Material`. Mesh gradient -> linear gradient (iOS 17). Zoom transition -> matched geometry or push. Symbol effects -> none. Controls (iOS 18) -> widgets only. Interactive snippets (26) -> open app. Declared Age Range (26) -> our neutral age screen. Challenges (26) -> plain leaderboards (GameKit) or none.
5. **Compile-time**: Xcode 26.5 SDK compiles all; use `if #available` plus `@available` on types; test on iOS 17.5 simulator and a real older device weekly. No `@_weakLinked` tricks.
6. **Data**: schema must not depend on any AI/iOS-26 types (SwiftData models store plain strings/ints), so users who upgrade OS keep data.
7. **Kill switch**: remote-config flags for each AI feature to disable server-side if a safety issue appears (flags only, no content).
8. **Test matrix**: iOS 17.5, 18.x, 26.x, 27 x (AI available/unavailable x Reduce Motion x low-power mode).

## 10. Top 15 recommended integrations (ranked)

1. **Core SwiftUI motion stack** (`keyframeAnimator`/`phaseAnimator`/`Canvas+TimelineView`/`contentTransition`) with Reduce Motion alternatives. Must. iOS 17.
2. **`sensoryFeedback` haptics** + Settings toggle. Must. S.
3. **App Intents + App Shortcuts** shared by widget, Siri, Spotlight (water, Daily Bloom, plant entities). Must. M.
4. **Widgets: tinted rendering mode support, relevance, Lock Screen families, Control Center controls (iOS 18)**. Must/should. S-M.
5. **StoreKit 2 `SubscriptionStoreView` + Ask to Buy/pending + Restore/Manage**. Must. S-M.
6. **Privacy manifests + MetricKit + Instruments budget + accessibility (VoiceOver, Switch Control alternatives, Differentiate Without Color)**. Must. M.
7. **Foundation Models: adaptive hint + Tell me more (streaming) with answer-leak validator, NL embeddings check, static fallback** (on-device only). Should. M.
8. **TipKit onboarding**. Should. S.
9. **Icon Composer icon with appearances, Liquid Glass chrome gated by availability**. Should. S-M.
10. **Declared Age Range (iOS 26+) feeding the age gate, fallback to neutral screen**. Should. M. Verify legal duties.
11. **Home Screen quick actions + Focus filter (School/Sleep silence)**. Should/nice. S.
12. **Sticker pack (Messages) + ShareLink share cards**. Should. S.
13. **Background Assets (Apple-hosted) for seasonal bank/art packs** (fallback bundled JSON). Should. M.
14. **FM garden journal + tending voice lines (`@Generable`) + Foundation Models Evaluations/instrument for QA**. Should/nice. M.
15. **"Find a plant" camera mode with custom Create ML classifier + Visual Intelligence entity hookup + subject lift sticker**. Nice (needs licensed dataset). L.

Honorable: Game Center achievements/Challenges (phase 3), Apple Watch complication, SharePlay, MeshGradient/shader hero sway, speech letters.

## 11. Attractive but risky (avoid or heavily gate)

- **Private Cloud Compute or third-party models (Claude/Gemini) in Foundation Models (iOS 27)**: leaves device, needs entitlement, daily user quotas, 5.1.2(i) data-sharing disclosure, kids' data; contradicts spec. Do not use. [A: wwdc2026/241]
- **Open-ended chat "Ask the Gardener" for under-13**: prompt abuse, jailbreaks, hallucinated plant toxicity advice (safety: never answer "is it safe to eat/touch" - sago palm note exists; always say ask an adult/poison control). Restrict to topic chips.
- **FM-generated answer words or facts shown as truth**: hallucination; spec already bans. Plant toxicity/edibility text must be vetted only.
- **Image Playground/Genmoji for kids**: sensitive output, off-brand, review burden.
- **Camera + plant ID of real plants**: misidentification risks (user eats a toxic plant). Phrase as "looks like..." game, never edibility. Photo privacy for minors. COPPA.
- **Voice input from children**: audio is personal info; keep on-device, no retention; parental mention in policy.
- **Live Activities / time-sensitive / provisional notifications**: pressure mechanics, review rejection if used for engagement spam (Guideline 4.5.4), contradict "calm" brand.
- **Widget push updates / App Attest / custom backend**: adds server, attack surface, privacy disclosures for little gain.
- **Screen Time/Family Controls entitlement**: restricted entitlement, review friction, not our category.
- **Leaderboards/Challenges/SharePlay for kids**: social comparison, chat exposure (SharePlay is via FaceTime), friend discovery; keep optional and parent-aware.
- **Always-running shaders/particles/MeshGradient animation**: battery heat on SE-class devices; pause off-screen, cap to 30fps for ambient.
- **Haptic-heavy patterns**: sensory sensitivity; default gentle, toggle, no continuous long patterns.
- **Notification summaries rewriting copy** into alarming text: write summary-safe copy.
- **SceneKit/3D AR**: SceneKit deprecated (T), expensive art.
- **Apple Intelligence-only gating of core loop**: ~ never; fewer than half of devices are eligible.
- **Subscription dark patterns**: trial wording when ineligible, hiding price, nags for under-13; App Review and reviews punish this.

## 12. What I could not verify

- Official Apple docs pages (Foundation Models, ImageCreator, SpeechAnalyzer, guardrail guidance) did not render; their API details are from training knowledge.
- iOS 27 WidgetKit/Live Activity/Game Center/haptics/Speech/age-range/StoreKit/notifications/TipKit/SwiftData/CloudKit specifics: session titles found but pages not read; no WWDC26 Game Center or haptics session spotted.
- Foundation Models on-device context size (4096 per non-Apple blog vs 8192 printed in a wwdc241 snippet) and device eligibility list for iOS 27.
- Exact developer obligations under Texas/Utah/Louisiana age laws and whether Declared Age Range is mandatory for our category.
- Whether Apple provides any assistant schema domain that fits games/gardening.
- Exact min versions for Apple-hosted Background Assets and the App Store accessibility nutrition label questions.

# Game design best practice for WordFlora: evidence, audit, and integration proposals

**Date:** 2026-11-02. **Scope:** game design craft and evidence (not Apple platform APIs: see `apple-capabilities.md`; not App Review basics, review mining, or the economy simulation, which earlier research already covers).
**Inputs read:** spec `docs/superpowers/specs/2026-11-02-wordflora-v2-design.md` (sections 1-16), plan `docs/superpowers/plans/2026-11-02-wordflora-v2.md`, and the core mechanic from the 2026-05-10 spec (8 petals, a wrong guess drops a petal, the flower "dies" at 0, and the Rose of Jericho restores 4).
**Status:** proposals only. Nothing here changes the spec or plan until the lead integrates it.

## 0. Method and source labels

- **PRIMARY**: an official document, a regulator, a standard, the paper itself, or a designer's own first-hand account.
- **SECONDARY**: law-firm or press summaries, or a summary of a paper (not the paper).
- **OPINION**: vendor blogs, practitioner rules of thumb, or my own derivation (labelled **[derived]**).
- **Fetched** means I read the page itself. **Search** means I read only a search-result summary of it, so confidence is lower. Fetched pages were treated as untrusted data.
- Timing numbers (ms), thresholds, and success criteria marked **[derived]** are my proposals. They are starting values for playtesting, not findings.

### Could not fetch / could not verify
- The ICO Children's Code page returned HTTP 403. I used summaries plus the PDF URL instead.
- GDC Vault talk videos were not fetched (paywalled or video). Only titles and pages were seen.
- Reddit / r/gamedesign was not attempted again (earlier research found it blocked).
- I did not read Apple Design Awards winner write-ups on Apple's site (I saw press lists only), the individual Xbox Accessibility Guideline pages, the full text of the EU DSA Art. 28 guidelines, the GameAnalytics genre tables (PDF), the full text of Hanna et al. 1997, the full UNICEF RITEC report, or the Declared Age Range sub-articles.
- I found **no primary Sago Mini or Joan Ganz Cooney Center design-principle document**. The Cooney Center ratings item is a 2012 news post.
- I could not confirm NN/g's animation-duration article directly. The 100 ms figure comes from a secondhand quote, and the 0.1 s / 1 s limits come from NN/g's response-time page as quoted in search results.
- Duolingo streak-freeze results: no primary data was found, only podcast summaries.

---

## 1. Executive summary (10 bullets)

1. **Word level is locked behind garden tending (critical).** Spec section 1 says level-up needs 10 unique plants. Section 16 says a level completes when all 10 plants reach stage 4, at 180 gp per plant with a 10 gp/day per-plant absorb cap. That is **at least 18 days per level even for the heaviest player**. The plant award rule then gives only duplicates, so adults spend weeks on 3-5 letter words. Flow and DDA research says too-easy play bores (Hunicke 2004; Sweetser and Wyeth 2005). Fix: decouple **word difficulty progression** from **garden completion**.
2. **Word length is the wrong difficulty proxy for hangman.** McLoone's simulation of ~8M games found "jazz" the hardest word at any allowed miss count from 8 to 13. Short words with rare letters are *harder* than long common ones. Level 1 (3-5 letters, "every child knows it") may be the hardest band for a letter-guesser. Add a computed `difficultyScore` per entry and band by it.
3. **There is no first-session (FTUE) script in the spec.** First launch could stack the intro rain, the age screen, UMP, and ATT before the first letter. Apple: "Teach through play", "Let people play as soon as installation completes", and onboarding should be "fast, fun, and optional". Proposal: one tap for age, then a guided first word within about 20 s, with consent deferred until ads can first appear (after the grace period).
4. **Mixed-audience ads conflict with the evidence on children.** An interstitial or video after every 3rd round, plus rewarded-ads-for-water, matches patterns Meyer/Radesky (2019) flagged as manipulative in children's apps ("pop-ups offering rewards for watching ads"). Recommend **no rewarded ads and no interstitials for the under-13 band** (banner on Home/Garden only, or no ads), and an owner decision on the adult cadence.
5. **The juice mandate needs a ceiling.** The largest juiciness study (Kao 2020, n=3,018) found **no juice and extreme juice both hurt** play time, experience, motivation, and performance compared with medium/high. "As many animations as possible" (section 5b) should become "medium-high juice, every effect skippable, total win sequence ≤ 2.5 s".
6. **System load is high for kids.** A child meets water, soil, sun, shed points, Rose, Glow Lantern, 6 tools × 3 tiers, 6 activities, stickers, and 30-40 badges. Apple: "If you try to teach too much, people can feel overwhelmed." Proposal: **progressive unlocks** (one new system per early session), so nothing is shown before it is useful.
7. **Adaptive difficulty must work without Apple Intelligence.** Most of the iOS 17.5-25 install base gets no AI hint, so the hint ladder must be **deterministic bank data** (hint → hint2 → a free vowel/first-letter reveal), with AI only rephrasing. Guardrails: player-visible, opt-out, never applied to the Daily Bloom (the shared, comparable word), never changes rewards in hidden ways.
8. **Session design lacks stopping cues.** Unlimited practice rounds plus an ad cadence and no "day's end" removes natural stopping points (Alter). Wardle designed Wordle for "three minutes a day" with no notifications. Add a **"garden day" arc**: Daily Bloom plus about 5 rounds, then a "sundown" card that ends the arc, with free play still available. The per-plant absorb cap is already a good stopping cue. Say so in copy.
9. **The "loss" moment should teach, not punish.** The current dead-flower state (droop, grey centre) conflicts with the cozy "safety, abundance, softness" framing (Project Horseshoe 2017) and the kid audience. Turn it into a **"resting" flower plus a full reveal of the answer, hint, and fact**. That is a retrieval-feedback moment, which supports the learning claims (spacing and testing effects, Cepeda 2006). Add **in-loop spaced review** of earned plants now, not in phase 3. `seenIds` already exists.
10. **Kids' regulation points to high-privacy defaults.** The UK AADC requires high-privacy defaults and no nudges. The amended COPPA rule (compliance 2026-04-22) adds a mixed-audience definition, stricter third-party ad consent, and a written data-retention policy. EU DSA Art. 28 guidelines and the CPC virtual-currency principles target pressure tactics on minors. Ship an **under-13 profile** with: no ads beyond a contextual banner, no AI chat ("Ask the Gardener" off), no Image Playground, a parental gate on the paywall, external links, and share, streak count hidden by default, and no notifications unless a parent turns them on. Use Declared Age Range on iOS 26+, with the neutral screen as fallback.

---

## 2. Evidence digest by theme

Format: **claim**, then design implication. [label, fetched/search] URL.

### 2.1 Onboarding / FTUE
- Apple HIG "Designing for games": "Let people play as soon as installation completes." "Teach through play." Present written tutorials "as a resource ... instead of making it a prerequisite." Ask for permissions "in the scenario that requires the data." Wait to prompt for ratings until "people spend quality time with your game." [PRIMARY, fetched] https://developer.apple.com/design/human-interface-guidelines/designing-for-games
- Apple HIG "Onboarding": make it "fast, fun, and optional". People "grasp and retain information better when they can actually perform the task". "Consider providing a collection of context-specific tips instead of a single onboarding flow" (TipKit). "If you try to teach too much, people can feel overwhelmed." If skipped, don't present it again, but keep it findable in Settings or Help. "Postpone nonessential setup." Prefer letting people experience the game "before prompting them for ratings or purchases." [PRIMARY, fetched] https://developer.apple.com/design/human-interface-guidelines/onboarding
- Industry FTUE practice: get to the fun in the first minute, and track every tutorial step as a funnel. Analytics show *where* players drop, not *why*. [OPINION/vendor, search] https://gameanalytics.com/blog/tips-for-a-great-first-time-user-experience-ftue-in-f2p-games ; https://supersonic.com/learn/blog/optimizing-ftue/ ; https://unity.com/how-to/10-first-time-user-experience-tips-games
- Pascal Luban (Game Developer): if the first minutes don't meet expectations, "the vast majority" drop out. [OPINION, search] https://gamedeveloper.com/design/best-practices-for-a-successful-ftue-first-time-user-experience-
- Game Accessibility Guidelines (basic tier): include an interactive tutorial, and let players start without navigating deep menus. [PRIMARY, fetched] https://gameaccessibilityguidelines.com/full-list/
- **Implication:** the first word must come before every non-essential screen. Consent screens only appear when their feature first runs (ads after the grace period, notifications on "remind me", camera on "Find a plant").

### 2.2 Core loop, feedback and juice
- Juiciness evidence is mixed. Kao (2020, n=3,018, action RPG) found none and extreme juice both lowered play time, player experience, intrinsic motivation, and performance compared with medium/high. Juul and Begy (2016, n=46, tile-matching) found no significant difference. Hicks's thesis (2013) found the effects "nuanced". [SECONDARY summaries of PRIMARY papers, search] https://www.x-mol.com/paper/1307980428882448384 ; https://core.ac.uk/download/492524999.pdf ; https://www.aminer.org/pub/5daed34e3a55ac02c96451d3/juicy-game-design-understanding-the-impact-of-visual-embellishments-on-player-experience
- Apple haptics HIG: use system patterns only for their documented meanings. Prefer "short haptics that complement discrete events". "Avoid overusing haptics." "Match the intensity and sharpness of a haptic with ... the animation." "Make haptics optional." [PRIMARY, fetched] https://developer.apple.com/design/human-interface-guidelines/playing-haptics
- Response-time limits: about 0.1 s feels like direct manipulation, and up to about 1 s keeps flow of thought. Simple feedback animations of about 100 ms, larger transitions 200-300 ms (secondhand NN/g quote). [PRIMARY limit / SECONDARY animation figures, search] https://www.nngroup.com/articles/response-times-3-important-limits/ (via https://www.nngroup.com/alertbox/timeframes.html)
- GameFlow (Sweetser and Wyeth 2005): enjoyment criteria are concentration, challenge, skills, control, clear goals, **feedback**, immersion, and social interaction. [PRIMARY, search] https://dl.acm.org/doi/10.1145/1077246.1077253 (PDF copy: https://core.ac.uk/download/10916682.pdf)
- SDT in games (Ryan, Rigby, Przybylski 2006): **competence and autonomy** satisfaction predicts enjoyment and post-play wellbeing, and competence relates to **intuitive controls**. [PRIMARY, search] https://doi.org/10.1007/s11031-006-9051-8
- **Implication:** feedback should be instant (<100 ms on key press), proportionate, and consistent (one haptic meaning per event). Everything must be skippable and mutable. The ceiling is "medium-high", not "maximal".

### 2.3 Difficulty and fairness (hangman-style)
- Hangman difficulty is driven by **rare letters and few distinct letters**, not length. McLoone simulated about 8M games, and "jazz" was hardest whether the guesser had 8 or up to 13 guesses. Repeated letters and low-frequency letters (J, Q, X, Z, V, K, W, Y) raise difficulty, and longer words reveal more per correct guess. [PRIMARY (Wolfram blog by the analyst), search] https://blog.wolfram.com/2010/08/13/25-best-hangman-words/
- Zach Gage (TypeShift): difficulty did not fall as players progressed because the last letters gave no help. He fixed it with **contextual hints** (a hint reveals a letter, and more if the player is partly right) and puzzles that teach the next puzzle. [PRIMARY first-hand account via Game Developer, fetched] https://gamedeveloper.com/design/how-zach-gage-fine-tuned-the-difficulty-curve-of-i-typeshift-i-
- DDA: games are "boring when too easy and frustrating when too hard". Hunicke's Hamlet adjusted supply and demand invisibly. Its case paper argues DDA can keep players in flow, while noting player agency concerns. [PRIMARY, search] https://users.cs.northwestern.edu/~hunicke/pubs/Hamlet.pdf
- Game Accessibility Guidelines: "offer a wide range of difficulty levels", "allow difficulty to be adjusted", "allow difficulty changes during play", "offer a practice mode without failure". [PRIMARY, fetched] https://gameaccessibilityguidelines.com/full-list/
- Shared daily puzzles depend on everyone facing the *same* challenge. Wardle: if everybody got a different word "it wouldn't have caught on". [PRIMARY quote via press, search] https://techcrunch.com/?p=2256733 (TechCrunch interview); https://time.com/6143715/wordle-sale-josh-wardle-interview
- **Implication:** score each entry by simulated expected misses (a frequency-ordered guesser), not by length. Put adaptive help on regular rounds only. Keep the Daily Bloom identical for all players (offer the same opt-in hint ladder to everyone, and show "hints used" on the share card if desired).

### 2.4 Progression and pacing
- Flow and DDA (above): progression must keep challenge rising with skill. A player stuck on one band for weeks drifts into boredom.
- SDT: competence needs visible growth. Autonomy needs meaningful choices (pick a level, pick a plant to tend). [PRIMARY, search] https://doi.org/10.1007/s11031-006-9051-8
- Apple onboarding: introduce features in context (TipKit), not all up front. [PRIMARY, fetched] https://developer.apple.com/design/human-interface-guidelines/onboarding
- **Implication:** two progress tracks. (a) A **word track**: unique plants earned → next difficulty band, fast (days). (b) A **garden track**: flourishing → badges, cosmetics, and the level's "garden complete" (slow, weeks). Neither blocks the other. Unlock systems one at a time.

### 2.5 Collection and meta-game
- Cozy design (Project Horseshoe 2017 group report "Coziness in Games: An Exploration of Safety, Softness, and Satisfied Needs"): the lenses are safety, abundance, and softness. Cozy games avoid scarcity of basic needs and use "tend and befriend". [PRIMARY report via secondary write-ups, search] https://www.gamedeveloper.com/design/designing-for-coziness ; https://medium.com/kitfox-games/designing-for-coziness-d33d2519a59e
- RITEC (UNICEF/LEGO, 2020-24): wellbeing outcomes for kids' digital play are autonomy, competence, emotional regulation, relationships, creativity, identity, diversity/equity/inclusion, and safety/security. There is a free design toolbox for game creators. [PRIMARY org summary, search] https://www.unicef.org/innocenti/projects/responsible-innovation-technology-children ; https://sites.google.com/sheffield.ac.uk/digitalplayandwellbeing
- Random reward drops paired with "pity" timers are variable-ratio schedules (the Hook model's "variable reward"). Critics argue the Hook model aims at compulsion by design. [OPINION, search] https://www.deceptive.design/articles/hooked-how-to-build-habit-forming-products ; https://subject-to-change-site.pages.dev/writing/hooked-line-and-sinker/
- **Implication:** collection is a strength (50 plants, 12 visitors, badges). Keep completion bars honest, show silhouettes, make no item purchasable, and **show drop odds in-game** even though they are free (cheap trust signal). Avoid time-limited or FOMO collectibles for kids.

### 2.6 Social, sharing and daily
- Wordle: one shared word per day, spoiler-free emoji share, no notifications, no sign-up, about "three minutes a day". Wardle was "suspicious of mobile apps that demand your attention and send you push notifications". [PRIMARY quotes via press, search] https://gamesradar.com/wordle-creator-wants-the-viral-guessing-game-to-stay-simple-and-ad-free ; https://shacknews.com/article/128240/wordle-creator-has-no-plans-to-monetize-on-the-games-popularity
- Streaks: Duolingo's retention PM reports the biggest jump is from a 1-day to a 2-day streak, flattening after about 7 days. Freezes exist to add flexibility. [SECONDARY podcast summary, search] https://lennysnewsletter.com/p/behind-the-product-duolingo-streaks
- Children report streak pressure ("once it hits 50 it's a big deal") in Ofcom-commissioned qualitative research. [PRIMARY qualitative research for a regulator, search] https://revealingreality.co.uk/ofcom-childrens-media-lives
- **Implication:** the spec's Daily Bloom and spoiler-free share are well supported. For the under-13 band, consider a **cumulative "garden days" count** instead of a consecutive streak, or hide the streak number by default.

### 2.7 Session length and breaks
- Alter: modern media removes "stopping cues". A day/night cycle (e.g. Stardew Valley) acts as a natural stopping point. [SECONDARY, search] https://www.stern.nyu.edu/experience-stern/news/professor-adam-alter-comments-differences-between-television-and-modern-video-games
- Play time vs wellbeing (Vuorre et al. 2022, 38,935 players, telemetry): little to no causal effect of *time*, but **motivations matter**. Feeling compelled ("have to") is the risk, not hours. [PRIMARY, search] https://royalsocietypublishing.org/doi/10.1098/rsos.220411 (press: https://www.oii.ox.ac.uk/major-new-study-finds-little-evidence-for-causal-connection-between-well-being-and-video-game-playing/)
- Apple games HIG: no pausing guidance on the page (noted as a gap). Pause on interruption is standard SwiftUI `scenePhase` practice.
- **Implication:** design ending beats (a "sundown" card, an "all tended today" state) and avoid "one more" hooks at those beats (no ad before the stop card, no next-round autoplay). Optimize for "wanted to", not "had to".

### 2.8 Notifications and re-engagement
- Apple 4.5.4: push must not be required, and marketing pushes need explicit opt-in plus an in-app opt-out. [PRIMARY, fetched] https://developer.apple.com/app-store/review/guidelines/#4.5.4
- Fitz et al. 2019 (randomized field trial, n=237): batching notifications **three times a day** improved wellbeing and productivity. Hourly batching did little, and *no* notifications increased anxiety/FOMO. [PRIMARY paper via summaries, search] https://static1.squarespace.com/static/57a40c19414fb54f51f8095f/t/614a55faa7b89e25f4e48ad1/1632261627146/2019+Fitz+Batching.pdf
- Duolingo copy experiments moved DAU by about 5% (vendor case study). [OPINION, search] https://taplytics.com/blog/how-duolingo-ran-an-experiment-on-their-streaks-feature
- **Implication:** the spec's rule (local, opt-in, at most 1/day, stop after 3 days without opens, no guilt) already beats the evidence bar. Add: no notifications for under-13 unless a parent enables them, and nothing after a user-set bedtime.

### 2.9 Monetization ethics for mixed audiences
- Meyer, Radesky et al. 2019 (96 apps for under-5s): 95% had ads. Concerns included rewards for watching ads, ads camouflaged as game items, tiny close buttons, and age-inappropriate content. [PRIMARY via press releases, search] https://www.eurekalert.org/news-releases/706093 ; https://www.newswise.com/articles/advertising-in-mobile-apps-for-young-children-–-study-raises-concerns-about-frequency-and-content-
- FTC "Bringing Dark Patterns to Light" (2022) gives children's-game examples, e.g. a "next level" button turning into a "buy" button. The Epic settlements (Dec 2022, $275M COPPA + $245M refunds) required protective defaults and banned charging without express consent. [SECONDARY summaries + FTC statement, search] https://www.ftc.gov/system/files/ftc_gov/pdf/rks-statement-dark-patterns.pdf ; https://natlawreview.com/article/ftc-announces-520-million-settlements-epic-games
- CPC Network Key Principles on In-game Virtual Currencies (2025): price transparency in real money, avoid multiple purchased currencies, account for children's vulnerability, and no pressure tactics such as time-limited offers (Star Stable case). Earn-only currencies are out of scope. [PRIMARY PDF via mirror + SECONDARY, search] https://esportslegal.news/wp-content/uploads/2025/03/Key-principles-on-in-game-virtual-currencies.pdf ; https://www.twobirds.com/en/insights/2025/european-move-towards-protecting-users-from-harmful-practices-in-video-games-eu-consumer-protection
- Apple 3.1.2(c): describe what the user gets before asking them to subscribe, and no bait-and-switch. [PRIMARY, fetched] https://developer.apple.com/app-store/review/guidelines/#3.1.2
- **Implication:** WordFlora's no-purchasable-currency stance is a strong compliance and ethics position. The weak spots are rewarded ads (a reward-for-ad pattern) and forced video for young players.

### 2.10 Wellbeing and anti-compulsion
- Vuorre 2022 and Ryan 2006: need satisfaction (autonomy, competence) predicts wellbeing, while controlled motivation does not. Design for "want to".
- Hook-model critique (above): triggers → variable reward → investment loops aim at compulsion by default.
- Cozy design: no scarcity of basic needs, and failure is soft. [search, above]
- **Implication:** audit every loop for "have to" pressure: streak loss, wilting, daily caps that reset at midnight, and the Glow Lantern FOMO window. The spec is already mostly good (freezes, rest not wilt, cosmetic wilting).

### 2.11 Accessibility
- Game Accessibility Guidelines (basic/intermediate) relevant here: large, well-spaced touch targets; avoid drag, repeated taps, and held touches; offer a simpler control option; let text be read at the player's own pace; interactive tutorial; practice mode without failure; adjustable difficulty; don't convey essential info by colour alone; high contrast; screen-reader support; don't rely on sound alone; save settings; include disabled players in playtesting. [PRIMARY, fetched] https://gameaccessibilityguidelines.com/full-list/
- Apple games HIG: 44×44 pt default and 28×28 pt minimum targets. Text 17 pt default and 11 pt minimum. Let players customise "type size ... motion intensity, and sound balance". Don't rely on colour alone. [PRIMARY, fetched] https://developer.apple.com/design/human-interface-guidelines/designing-for-games
- Xbox Accessibility Guidelines v3.2 (23 guidelines: text display, contrast, additional channels for cues, audio, UI context, objective clarity, time limits, photosensitivity, accessible support). [PRIMARY index, search] https://learn.microsoft.com/en-us/gaming/accessibility/guidelines
- WCAG 2.2 (applied to games by analogy): 1.4.1 Use of Color; 1.4.3 Contrast (4.5:1 text); 1.4.11 Non-text Contrast (3:1); 2.2.1 Timing Adjustable; 2.3.1 Three Flashes; 2.5.1 Pointer Gestures (single-pointer alternative to path gestures); 2.5.7 Dragging Movements; 2.5.8 Target Size (24 px minimum; Apple's 44 pt is stricter). [PRIMARY standard, not re-fetched; stable spec] https://www.w3.org/TR/WCAG22/
- **Implication:** the spec covers petals-as-text, Dynamic Type, Reduce Motion, and haptics. It is missing: keyboard key states without colour, a timed butterfly game (needs an untimed mode), drag-only prune and tool pickup (need tap alternatives), CoreMotion parallax (off under Reduce Motion), a letter-layout choice (ABC vs QWERTY), and accessible-player playtests.

### 2.12 Kid safety and regulation
- UK Age Appropriate Design Code (15 standards; "child" = under 18): best interests, data minimisation, **high-privacy defaults**, geolocation off, profiling off by default, **no nudge techniques**, parental controls transparent to the child, DPIA. [PRIMARY code PDF (not fetched: page 403) + SECONDARY, search] https://ico.org.uk/media/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services-2-1.pdf ; https://techcrunch.com/2020/01/22/uk-watchdog-sets-out-age-appropriate-design-code-for-online-services-to-keep-kids-privacy-safe
- COPPA amended rule: published 2025-04-22, effective 2025-06-23, **compliance due 2026-04-22** (already in force). It adds a stand-alone **mixed-audience** definition (age screen before collecting personal information), separate consent for disclosing data to third parties (e.g. targeted ads), and a written **data retention policy**. The internal-operations exception needs extra notice. [PRIMARY Federal Register + SECONDARY, search] https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule ; https://www.insideprivacy.com/united-states/federal-trade-commission/ftc-adopts-final-coppa-rule/
- EU DSA Art. 28 guidelines on protection of minors (final 2025-07-14): non-binding but used to assess compliance. They target exploitative commercial practices (virtual currencies, loot boxes) and call for safe defaults. Art. 28 applies to *online platforms*, so a single-player app may be out of scope, but the guidelines are a useful bar. [SECONDARY, search] https://www.hunton.com/privacy-and-cybersecurity-law-blog/european-commission-issues-guidelines-on-the-protection-of-minors
- Apple 5.1.4: apps "intended primarily for kids" should not include third-party analytics or ads. Any app collecting personal info from minors needs a privacy policy and statute compliance. Parental gates are required in the Kids Category. [PRIMARY, fetched] https://developer.apple.com/app-store/review/guidelines/#5.1.4
- Declared Age Range (iOS 26+): returns an age *range* against the app's age gates, with parent-controlled sharing for Family Sharing children. "You are solely responsible for ensuring compliance." [PRIMARY, fetched] https://developer.apple.com/documentation/declaredagerange
- Toca Boca: open-ended "digital toys", kids co-design ("get a bunch of kids in to play ... see exactly where the fun is"), and no gendered sorting. [PRIMARY interviews, search] https://funambulism.com/2014/02/28/interview-with-bjorn-jeffrey-ceo-of-toca-boca/ ; https://kidscreen.com/2014/10/30/toca-boca-dishes-on-gender-neutrality-and-design
- Common Sense Media rates "ease of play" and "consumerism", and learning ratings ask whether kids get feedback on performance. [PRIMARY page, search] https://commonsensemedia.org/about-us/our-mission/about-our-ratings

### 2.13 Educational transfer
- Spacing effect (Cepeda et al. 2006 meta-analysis: 839 assessments, 317 experiments): spaced study beats massed study, and the optimal gap grows with the retention interval. [PRIMARY, search] https://pubmed.ncbi.nlm.nih.gov/16719566/
- Testing effect (Roediger and Karpicke 2006): retrieval practice beats restudy for long-term retention. [PRIMARY paper, not fetched; widely replicated] https://doi.org/10.1111/j.1467-9280.2006.01693.x
- Common Sense learning criteria include feedback on performance. [search, above]
- **Implication:** WordFlora's "learn plants" claim currently rests on reading a fact once. Cheap upgrades: (1) reveal the fact on win *and* loss; (2) a weekly-scheduled retrieval round ("Which of your plants ... ?") drawing from earned plants at about 1/3/7/21 days. This uses data that already exists (`seenIds`, earned dates).

### 2.14 Polish and performance
- Apple: "Provide great default settings" using the device's accessibility settings. Prefer resolution-independent art. Use safe areas. [PRIMARY, fetched] games HIG URL above.
- App launch: Apple's WWDC 2019 "Optimizing App Launch" recommends a first frame within about 400 ms. [PRIMARY, from memory, NOT fetched] https://developer.apple.com/videos/play/wwdc2019/423/
- Kao 2020: extreme effects reduce performance and experience. [search, above]
- **Implication:** set explicit budgets: cold launch to interactive Home ≤ 2.0 s on an SE-class device including the intro (skippable), 60 fps in rounds, particle caps, and no continuous CoreMotion or Metal work off-screen.

---

## 3. Scored audit of the current spec and plan

**Severity:** Critical (breaks the core experience or compliance), High, Medium, Low. **Score** (0-5) = how well the spec meets the evidence today.

### 3.1 Scorecard

| Theme | Score | One-line verdict |
|---|---|---|
| Onboarding / FTUE | 1 | No first-session script, and a consent stack could precede the first guess |
| Core loop & juice | 3 | Rich motion plan with Reduce Motion, but no ceiling or timing spec; "as many as possible" conflicts with evidence |
| Difficulty & fairness | 2 | Length-based bands; adaptive help is AI-only; no difficulty data per entry |
| Progression & pacing | 1 | Word level gated by an 18+ day tending cap; contradiction between sections 1 and 16 |
| Collection & meta | 4 | Strong, earn-only, positive badges; needs odds display and staged unlocks |
| Social / sharing / daily | 4 | Daily Bloom, spoiler-free share, gentle streak; kid streak pressure unaddressed |
| Session length & breaks | 2 | Absorb cap helps, but no stopping beat; ad cadence invites "one more" |
| Notifications | 5 | Best-in-class rule set already |
| Monetization ethics | 3 | No paid currency or loot boxes (great); rewarded/forced ads for kids are weak |
| Wellbeing / anti-compulsion | 3 | Cozy intent is clear; streak/FOMO for kids, a loss state that "dies", Glow Lantern window |
| Accessibility | 3 | Basics present; drag-only and timed minigames, colour on keys, no assistive playtest |
| Kid safety / regulation | 2 | Age screen + child-directed ads exist; under-13 defaults, data retention policy, AI chat, share/link gates missing |
| Educational transfer | 2 | Fact on win only; spaced review deferred to phase 3 |
| Polish / performance | 3 | 60 fps target and SE testing; no numeric budgets; heavy shader/motion scope |

### 3.2 Strengths (keep)
- S1. Earn-only economy, no purchasable currency, no paid randomness (section 4, 6, 16) → outside the CPC currency principles and loot-box rules. **Spec section 4/6/16.**
- S2. Notification rule (section 4): opt-in at feature use, one per day, stop after 3 unopened days, no guilt. Matches Apple 4.5.4 and the batching evidence.
- S3. Streak freezes earned automatically, and "resting not wilting" copy (section 3, 16).
- S4. Paywall only on explicit action, parental gate for under-13, clear trial terms (sections 11, 13). Matches 3.1.2 and the FTC dark-pattern guidance.
- S5. Ad guardrails: never mid-round, never around the Daily Bloom, grace period, holdout cohort, numeric kill-switch (section 16). Unusually rigorous.
- S6. AI validators with static fallbacks, and AI never generates answers (section 5, plan Task 14).
- S7. Butterfly game with no fail state and a Reduce Motion / VoiceOver variant (section 14).
- S8. Accessibility: petals as text, Dynamic Type, 44 pt, Reduce Motion fades (section 8).
- S9. Shared deterministic Daily Bloom with spoiler-free share (section 3). Wordle-proven.

### 3.3 Gaps, contradictions, risks

| ID | Finding | Severity | Affects |
|---|---|---|---|
| A1 | **Contradiction:** level-up = 10 unique plants (section 1) vs level complete = 10 plants at stage 4 (section 16). Under section 16 the word level cannot advance for at least 18 days (180 gp ÷ 10 gp/day cap), and the award rule gives only duplicates meanwhile, so adults replay 3-5 letter words for weeks. | Critical | Spec 1, 16; plan Task 5 (level-up rule), Task 6 |
| A2 | Difficulty bands by length. Hangman difficulty is driven by rare letters and few distinct letters, so Level 1 short words may be the hardest. No per-entry difficulty metric in the schema or validator. | High | Spec 1, 2 (schema); plan Task 3 validator |
| A3 | No FTUE. First launch may show intro rain → age screen → UMP → ATT before play. | High | Spec 6, 11; plan Task 9c, 11, 15 |
| A4 | Adaptive help only via AI (iOS 26 + eligible devices). No deterministic hint ladder or letter-reveal assist for everyone. The ML "difficulty tuner" has no guardrails (Daily Bloom fairness, transparency). | High | Spec 5, 5b; plan Task 14, 14b(6) |
| A5 | Under-13 players get the 3-round forced video ad and rewarded-ads-for-water (only rating and personalisation are restricted). Evidence on ads for young children is negative. Reward-for-ad is a flagged pattern. | High | Spec 12, 16; plan Task 11 |
| A6 | **Contradiction:** "never after a loss" (sections 6, 11) vs the cadence counting losses and firing at the next round boundary (sections 12, 16). If round 3 is a loss, the ad follows a loss. | Medium | Spec 6/11 vs 12/16; plan Task 11 `AdCadence` |
| A7 | Loss state: the flower "dies" (stem droops, centre greys; 2026-05-10 spec). The Rose revive is a 10% random drop. That is a punishment framing in a "never punishing" game, and the answer/fact reveal on loss is unspecified. | Medium | 2026-05-10 spec Petal Mechanic; v2 spec 4 theme, 7, 16 |
| A8 | No stopping cue or session arc. Unlimited practice + ad cadence. | Medium | Spec 3, 16; plan Task 10 |
| A9 | Feature/system load for kids: about 10 resource types plus 6 activities at once. No progressive unlock plan. | High | Spec 4, 14, 16; plan Tasks 6b-6d, 10 |
| A10 | "As many animations as possible" with no ceiling or timing tokens. Kao 2020 says extreme juice hurts. Perf/battery risk (Metal shaders, CoreMotion, Canvas particles). | Medium | Spec 5b; plan Task 9b, 9c |
| A11 | Accessibility gaps: prune minigame = drag; tool pickup = drag; butterfly = timed swipe; keyboard key states unspecified (colour?); parallax motion; no ABC/QWERTY option; no disabled players in testing. | High | Spec 8, 14, 5b; plan Task 6b, 6c, 16 |
| A12 | Kid-safety defaults: "Ask the Gardener" (chat-like) and "Find a plant" camera are available to under-13 by default. Share and external links have no parental gate. No data-retention policy (COPPA 2025). The streak number is shown to kids. | High | Spec 5b, 3, 6; plan Task 11, 14b |
| A13 | Analytics list is goals, not events. No under-13 rule beyond "no third-party". No retention/deletion policy. "Churn reasons" implies a survey with no design. | Medium | Spec 11; no plan task |
| A14 | Educational claim weak: fact on win only, spaced review deferred. | Medium | Spec 10; plan Phase 3 |
| A15 | **Plan stale vs Economy v1:** plan Task 5 says Rose 15% and milestones 7/30 (spec section 16: 10%, max 1/day, pity 15, 7/30/100). Plan Task 11 `shouldShowInterstitial` "less than 2 actions since last" is from superseded section 6. Plan Task 6 trickle cap 5 has no 40-bank cap. | Medium | Plan Tasks 5, 6, 11 |
| A16 | Night visitors 17:30-21:30 plus a Glow Lantern earned from weekly streaks. The evening window pulls kids to play near bedtime. Mild FOMO. | Low | Spec 15, 16 |
| A17 | No playtest plan, no launch dashboard spec, no success thresholds beyond the ad kill-switch. | Medium | No plan task |
| A18 | Declared Age Range not mentioned in the spec (sibling research recommends it). The age screen design (neutrality, no default age) is unspecified. | Medium | Spec 6; plan Task 11 |

---

## 4. Integration proposals

Each proposal gives: rationale + source, **paste-ready spec text**, plan change with TDD-able acceptance tests, effort (S/M/L), and priority (P0 = before first TestFlight, P1 = before launch, P2 = after launch).

### P-01. Decouple word progression from garden completion (fixes A1) — P0, M
**Rationale:** flow/DDA (Hunicke; Sweetser and Wyeth) and SDT competence. The current gate is at least 18 days per level. Sources in 2.3/2.4.
**Spec: replace section 1 bullet "Level-up needs `plantsPerLevel` (10) UNIQUE plants ..." and the section 16 row "Level complete" with:**
> - **Two tracks.** *Word level* (difficulty band) advances when the player has earned all 10 plants of the current level (10 unique plants, award rule unchanged). *Garden level* ("Grove complete" etc.) completes when all 10 plants of that level reach stage 4 (flourishing). It grants the level-complete soil/shed points and badges, and never blocks word progression.
> - The player can choose any unlocked word level from the Level Map. The default is the highest unlocked level.
> - Section 16 pacing figures ("all 5 levels complete around day 183/115/110") refer to the garden track. The word track is expected to reach level 5 within about 2-4 weeks of regular play.

**Plan:** Task 5. Replace the level-up rule. Add `ProgressionPolicy` (pure).
Tests: (1) 10 unique plants at L1 → `wordLevel == 2` even if every stage is 0; (2) all L1 plants at stage 4 → `gardenLevelComplete(1) == true` and grants fire once; (3) the player can select any `level <= wordLevel`; (4) duplicates are awarded only when the level set is complete (existing test kept); (5) the interstitial grace "first level-up" uses the word track.

### P-02. Per-entry difficulty score and banding (fixes A2) — P0, M
**Rationale:** McLoone/Wolfram (rare letters, few distinct letters) and Gage (contextual help). Section 2.3.
**Spec: add to section 2 schema and authoring rules:**
> - **`difficulty` (computed, not hand-entered):** the expected number of wrong guesses for a deterministic English-letter-frequency guesser (ETAOINSHRDLU... order, skipping revealed letters). It is computed by `scripts/validate_wordbank.py` and stored in the bank. Each level has a target miss band: L1 ≤ 2.5, L2 ≤ 3.5, L3 ≤ 4.5, L4 ≤ 5.5, L5 ≤ 6.5 (8 petals). Entries outside their band are flagged for reassignment or a stronger hint. Length bands in section 1 become guidance, not rules.
> - Words with ≥ 2 of J, Q, X, Z, or ≤ 2 distinct letters, need reviewer sign-off at L1-L2.

**Plan:** Task 3, validator step, plus a Swift mirror `WordDifficulty.expectedMisses(_:)` used in tests.
Tests: (1) golden values, `JAZZ` > `TOMATO`; (2) every bundled entry is within its level band, or listed in an `exceptions` array with a reviewer note; (3) deterministic output; (4) Python and Swift implementations agree on 20 fixture words.

### P-03. First-60-seconds onboarding script (fixes A3) — P0, M
**Rationale:** Apple "teach through play", "fast, fun, and optional", defer permissions; GAG interactive tutorial; FTUE funnels. Section 2.1.
**Spec: add new section 17 "First session (FTUE)":**
> **First session script (cold install).** Target: first letter tapped ≤ 20 s after launch, first plant earned ≤ 60 s.
> 0-2 s: Intro rain (skippable by tap; Reduce Motion = 0.5 s fade).
> 2-8 s: **Age question**, one screen, neutral: "How old are you?" with a year wheel or 3 large buttons ("Under 13", "13-17", "18+"; no pre-selected value, no hint that any answer unlocks more). On iOS 26+ with Declared Age Range available, request the range first and skip the screen when one is returned.
> 8-20 s: **Tutorial word** (fixed, L1, e.g. SUN or a hero plant with ≤ 2 expected misses). Hint shown. A pulsing ring on the keyboard says "Tap a letter". No other UI chrome. No banner. Wrong guesses still drop petals, but the tutorial word cannot be lost (the petal floor is 1; copy: "Keep going!").
> 20-45 s: Win → plant card flies to the Garden (≤ 2.5 s, skippable) → `PlantEarnedView` with the fact.
> 45-60 s: Garden with ONE tip (TipKit): "Water your plant." One free drop is pre-granted and the tip completes on water. Then "Play another word" is the primary button.
> **Deferred:** UMP and ATT appear only immediately before the first ad request (after the section 16 grace period). The notification permission appears only on "Remind me". Tools, soil, the shed, butterflies, badges and the Rose are introduced by the progressive-unlock table (P-07). Paywall, rating prompt and Daily Bloom streak copy never appear in session 1.
> **Skip:** a "Skip tutorial" link is present. Once skipped or completed, the tutorial never auto-shows again but stays in Settings > How to play (Apple HIG).

**Plan:** new **Task 10a "First session"** (after Task 10).
Tests: (1) `OnboardingFlow` state machine: launch → age → tutorialWord → plantEarned → gardenTip → home; (2) no consent/ATT/notification request is issued before `adsEligible == true` (spy on the consent and ATT wrappers); (3) the tutorial word cannot reach 0 petals; (4) skip persists across launches; (5) XCUITest: from launch, a letter tap is possible within 3 interactions; (6) the age screen has no default selection (`selectedBand == nil` until a tap).

### P-04. Deterministic hint ladder + letter-reveal assist, with AI as an optional layer (fixes A4) — P0, M
**Rationale:** Gage's contextual hints; GAG "allow difficulty to be adjusted"; DDA (Hunicke) with agency; Daily Bloom fairness (Wardle). Section 2.3.
**Spec: replace section 5 feature 1 and the 5b "ML for fairness" bullet with:**
> **Help ladder (all devices, no AI required).** During a round, a "Help" button offers in order: (1) `hint2` (a second clue from the bank); (2) **Reveal a vowel** (the most frequent unrevealed vowel); (3) **Reveal the first letter** (all its occurrences). Each step is player-initiated, costs nothing, and is shown in the result ("Bloomed with 1 helper"). No currency is spent; help never reduces rewards below 1 water for a win.
> **Adaptive offer (DDA, transparent):** after 3 wrong guesses in a row, or 2 petals left, the Help button gently pulses once (no auto-reveal). A per-player `assistLevel` (0-2) moves by at most 1 step per 5 rounds, based on the last 10 regular rounds: win rate > 85% with no help → the next word comes from the upper half of the level's difficulty band; win rate < 50% → the lower half, and the pulse comes one wrong guess earlier. `assistLevel` never changes rewards, is visible in Settings ("Word difficulty: Gentle / Standard / Tricky", with Auto as the default), and the player can lock it.
> **Daily Bloom is never adapted:** same word and same ladder for everyone. The share card shows help used as a 🌱 count.
> **Apple Intelligence (optional):** may *rephrase* step 1 more simply, subject to `HintValidator`. It never adds steps or changes selection.
> Under-13 default: `assistLevel` starts at Gentle (pulse after 2 wrong guesses).

**Plan:** Task 5 (add `HelpLadder`, `AssistTuner`), and narrow Task 14b(6) to "AI rephrase only".
Tests: (1) ladder order and idempotence (steps can't repeat; reveal never reveals the last unrevealed letter, so the player always makes the final guess); (2) a vowel reveal picks the correct vowel and reveals all occurrences; (3) `AssistTuner` changes by at most 1 per 5 rounds and is bounded 0-2; (4) daily rounds ignore `assistLevel` (golden: same word and same ladder for two profiles with different levels); (5) a locked setting is never changed by the tuner; (6) a win's reward is ≥ 1 water whatever help was used.

### P-05. Juice and feedback checklist with timings (fixes A10) — P1, S (spec) + M (implementation)
**Rationale:** Kao 2020 (medium-high is best), NN/g 0.1 s / 1 s limits, Apple haptics HIG. **Timings are [derived] defaults, to tune in playtest.**
**Spec: replace the first sentence of section 5b with "Principle: delight at a medium-high level of juice (evidence: excess juice reduces enjoyment and performance); every effect is skippable and respects Reduce Motion, haptic and sound toggles." Then add a "Motion and feedback tokens" table:**

| Event | Visual | Duration | Haptic (iOS) | Sound |
|---|---|---|---|---|
| Key press down | key scale 0.94 + highlight | ≤ 80 ms in, response < 100 ms | `.selection` (light) | soft tick (optional) |
| Correct letter | tile flip + key turns "correct" (✓ glyph + colour) | 180-250 ms per tile, stagger 60 ms | `.impact(.light)` once per guess (not per tile) | pluck |
| Wrong letter | key shake 3 cycles + ✕ glyph; one petal detaches | shake 250-300 ms; petal fall 700-900 ms (non-blocking: input re-enabled ≤ 150 ms) | `.impact(.soft)` (not `.error`: kids) | soft "whoosh" |
| 2 petals left | flower leans, no red flash | 400 ms | none | none |
| Word complete | letter wave | 60 ms stagger, total ≤ 600 ms | `.success` | chime |
| Plant earned | card fly-in + pollen burst (≤ 120 particles) | total ≤ 2.5 s, tap to skip at any time | crescendo (CoreHaptics ≤ 600 ms) | bloom swell |
| Round lost ("resting") | flower closes petals and rests; answer + fact slide in | 600 ms | `.warning`? **No.** Use none or `.soft` | gentle low note |
| Water/soil/sun | pour/scoop/glow | 500-900 ms | rain pattern ≤ 400 ms / thump / none | matching sfx |
| Toasts (Rose drop, badge) | slide-in, auto-dismiss | in 250 ms, stay ≥ 4 s (GAG: read at own pace; tap to keep) | `.success` only for badge | — |
| Screen transitions | zoom/push | 250-350 ms | none | none |

> Rules: at most one haptic per player action; never haptics on timers or ambient events; no full-screen flash; nothing flashes > 3 Hz (WCAG 2.3.1); celebrations never block the next input for more than 2.5 s; the ambient loop is off by default; all particles are paused when the scene is not visible; a "Calm mode" toggle (Settings) halves particle counts and removes screen shake.

**Plan:** Task 9b. `Motion` tokens file encodes this table.
Tests: (1) token values are within the table ranges (snapshot of the tokens struct); (2) `HapticMap` maps each event to exactly one pattern, and the toggle disables all; (3) Reduce Motion substitutes fades for shake, fall and fly; (4) the celebration skip callback fires within 1 frame of a tap; (5) particle emitter cap ≤ 120 (unit); (6) the input-lock duration after a wrong guess is ≤ 150 ms (view-model test with a fake clock).

### P-06. Loss becomes "resting" and teaches (fixes A7, supports A14) — P0, S
**Rationale:** cozy safety/softness; SDT competence; testing effect/feedback (Common Sense learning criteria). Sections 2.5, 2.13.
**Spec: add to section 4 "Theme" (and override the 2026-05-10 "flower dies" wording):**
> **Round end without a solve ("resting").** At 0 petals the flower folds its petals and rests (no droop-to-death, no grey, no "dead" copy). The screen reveals the full answer with each letter animating in, the hint, and the plant fact, with a "Say it" (AVSpeech) button. Copy: "This one's resting. Here's the word: CACTUS." The Rose of Jericho, if held, is offered as "Wake it up" *before* the reveal. A loss grants no water. It counts toward the round counter (see ads P-08), and the answer goes into the review queue (P-12). The word "dead" and the word "lost" never appear in UI copy (add to the banned-wording list).

**Plan:** Task 5 (round result includes `revealedAnswer`, `reviewQueue.add`) and Task 9 (FlowerView "resting" state replaces "dead").
Tests: (1) a result at 0 petals exposes the answer, hint and fact; (2) the Rose offer comes before the reveal and only when stock > 0 and `!reviveUsedThisRound`; (3) the banned-wording validator rejects "dead"/"died"/"lost" in the strings catalog; (4) a loss enqueues the entry for review at +1 day.

### P-07. Progressive unlock of systems (fixes A9) — P0, S (spec) / M (implementation)
**Rationale:** Apple onboarding ("teach too much ... overwhelmed", contextual tips); GAG cognitive. Section 2.1/2.4.
**Spec: add to section 14:**
> **Progressive unlocks** (each introduced by one TipKit tip at the moment it becomes useful; the shed, map and settings show nothing locked-but-teased in session 1):
> | Unlock | Trigger |
> |---|---|
> | Words + water + garden | Session 1 (tutorial) |
> | Sun tap | 3rd plant earned |
> | Daily Bloom card | after the tutorial completes, from session 1 onward (on Home, never forced) |
> | Soil + trowel | 5th plant earned |
> | Rose of Jericho | first time a round reaches 2 petals left (the tip explains it; the first Rose is granted free) |
> | Butterfly game + net | 1st word-level-up or day 3 of play, whichever first |
> | Shed (tool tiers, shed points) | 2nd word-level-up |
> | Repot, prune, mist, sun lamp | one per garden-level stage-up milestone, then free choice |
> | Badges shelf | first badge earned (badges accrue silently before) |
> | Glow Lantern / night visitors | after the first butterfly play |
> Settings > "Show everything" unlocks all at once for experienced players.

**Plan:** new `FeatureUnlockPolicy` in Task 6d or a new Task 6e.
Tests: (1) each unlock fires exactly once at its trigger; (2) the "Show everything" override; (3) UI queries `isUnlocked(_:)`, and a snapshot of Home in session 1 shows only Play, Garden and Daily Bloom; (4) unlock tips respect the one-prompt-per-beat queue.

### P-08. Kid-safe ad and monetization defaults (fixes A5, A6) — P0, S
**Rationale:** Meyer/Radesky 2019; FTC dark patterns/Epic; AADC "no nudges"; CPC principles; Apple 5.1.4 spirit. Section 2.9/2.12.
**Spec: add to section 16 "Ads (consolidated)":**
> - **Under-13 band:** no interstitial or video ads and no rewarded ads. Only the Home/Garden banner remains (contextual, non-personalised, max rating G, no close-button tricks). If the owner prefers zero ads for under-13 (recommended if revenue impact is small), remove the banner too. No paywall entry points other than Settings behind the parental gate.
> - **Loss rule (resolves the section 6/11 vs 12/16 conflict):** if the round that triggers the cadence was not solved, the ad is deferred to the next round boundary after a solved round (counter stays at threshold), so an ad never directly follows a "resting" result.
> - **Stopping beat:** no ad is shown immediately before the "sundown" card (P-09) or when the player taps Home.
> - Rewarded ads (13+): the offer appears only in the Garden water panel when water = 0, never as a pop-up, never during or right after a round, and never "camouflaged" as a garden item.

**Plan:** Task 11 `AdCadence` and `AdPolicy`; also drop the stale "less than 2 actions since last" rule.
Tests: (1) `AdPolicy(ageBand: .under13)` → interstitial false, rewarded false, banner per flag; (2) the cadence fires at 3 only when the last round was solved, otherwise deferred (counter stays 3); (3) no ad before the sundown card; (4) the rewarded offer is visible only when water == 0 and in the Garden context.

### P-09. Session design: garden day arc and rest states (fixes A8, A16) — P1, M
**Rationale:** Alter's stopping cues; Wardle's "three minutes a day"; Vuorre (motivation, not hours); cozy abundance. Sections 2.6/2.7/2.10.
**Spec: add to section 3:**
> **A garden day.** Home shows a gentle daily arc: Daily Bloom + 5 "garden rounds". After the 5th regular round of the local day, a **Sundown card** appears: a summary (words grown, plants watered, fact of the day), "Your garden is set for today", and two equal buttons: "Visit the garden" and "Keep playing". Free play continues with unchanged rewards except the existing per-plant absorb cap. No ad, rating prompt, paywall or streak copy appears on the Sundown card.
> **Rest states:** when every plant has reached today's absorb cap the Garden says "All tended for today 🌙" and tool buttons dim (no red badges). Wilting is cosmetic and never shown in notifications or widgets as a call to action.
> **Bedtime (optional, default ON for under-13 at 20:30 local):** after bedtime, the app shows a calm "The garden is sleeping" overlay at the next round boundary (not mid-round) with "Five more minutes" (once) and "Good night". Night visitors end at bedtime if earlier than 21:30. Parents can change it behind the parental gate.

**Plan:** new **Task 10b "Session arc"**: `DayArc` (pure) + Sundown view.
Tests: (1) the Sundown card triggers once per local day after the 5th regular round (Daily Bloom excluded), DST-safe; (2) "Keep playing" leaves rewards unchanged; (3) prompts are suppressed on the Sundown beat; (4) the bedtime overlay appears only at a round boundary, "Five more minutes" is allowed once, and the night-visitor window is clipped by bedtime.

### P-10. Kid-safe design defaults and parental controls (fixes A12, A18) — P0, M
**Rationale:** AADC (high privacy, no nudges, parental controls transparent), COPPA 2025 (mixed audience, retention policy), Declared Age Range, Apple 5.1.4/1.3. Section 2.12.
**Spec: add new section 18 "Under-13 profile and parental controls":**
> **Age source:** on iOS 26+, `DeclaredAgeRange` with age gates [13, 16, 18] when available. Otherwise the neutral age screen (P-03). The band is stored on-device only as a coarse enum. A parent can change it behind the parental gate.
> **Under-13 defaults (cannot be loosened by the child):** no interstitial/rewarded ads (P-08); "Ask the Gardener" OFF (the "Tell me more" read-only explanation stays); Image Playground hidden; "Find a plant" camera available but requires a parental-gate tap the first time; notifications OFF unless a parent enables them; streak number hidden (shows "garden days" cumulative instead); bedtime ON at 20:30; share sheet, external links (privacy policy, support, Report ad), paywall and Restore behind the parental gate; Game Center (phase 3) off; analytics limited to the on-device aggregate set (P-14) with no identifiers.
> **Parental gate:** a non-trivial adult task (e.g. "Type the number seven hundred twelve"), not a simple math problem a 7-year-old solves. It never rewards passing.
> **Parent panel (Settings > For grown-ups, gated):** age band, ads (banner on/off), AI features on/off, notifications, bedtime, daily round soft limit (off/10/20/30 rounds; reaching it shows the Sundown card without "Keep playing"), and a plain-language summary of what data stays on the device.
> **Screen Time friendliness:** no anti-Screen-Time behaviour (no prompts to extend limits, no streak loss when Downtime blocks play: freezes cover it). Respect `scenePhase` to pause and save mid-round instantly.
> **Data retention (COPPA 2025):** a written retention policy in the privacy policy. On-device analytics aggregates roll off after 90 days. No server copy for under-13. iCloud sync data is the user's own CloudKit private DB.

**Plan:** Task 11 (age band, gate) and a new **Task 11c "Parent panel + under-13 policy"**.
Tests: (1) a `FeaturePolicy(ageBand:)` matrix test covering every flag above; (2) the gate rejects single-digit arithmetic answers, accepts the correct prompt, and randomises its prompt; (3) the Declared Age Range adapter maps declarations to bands (mock); unavailable → falls back to the screen; (4) a daily soft limit shows Sundown without "Keep playing"; (5) the child UI cannot change gated settings without the gate.

### P-11. Accessibility checklist mapped to WCAG / GAG / XAG (fixes A11) — P0/P1, M
**Spec: replace section 8 with:**

| # | Requirement | Maps to | Where |
|---|---|---|---|
| 1 | Petal count as text/VoiceOver ("5 of 8 petals left") | WCAG 1.1.1, 1.4.1; GAG vision basic | FlowerView |
| 2 | Keyboard key states use glyph + colour (✓ correct, ✕ absent), plus `accessibilityValue` ("C, not in word") | WCAG 1.4.1; GAG "not colour alone"; iOS Differentiate Without Color | GameView |
| 3 | Text contrast ≥ 4.5:1, non-text UI ≥ 3:1 in light, dark and Increase Contrast | WCAG 1.4.3, 1.4.11; XAG 102 | all |
| 4 | Dynamic Type to AX5. Keyboard reflows (2 rows → 3/4 rows) and never truncates the hint | Apple HIG; WCAG 1.4.4 | GameView |
| 5 | Targets ≥ 44×44 pt, ≥ 8 pt spacing on the letter keyboard | Apple 44 pt; WCAG 2.5.8 | GameView |
| 6 | Keyboard layout option: ABC (default under-13) / QWERTY | GAG cognitive "simple controls"; [derived] | Settings |
| 7 | Every drag has a tap alternative: tool pickup (tap tool, tap plant), prune (tap highlighted stems), net (tap) | WCAG 2.5.1, 2.5.7; GAG motor "avoid drag" | 6b, 6c |
| 8 | Butterfly game untimed mode ("Relaxed": visitors rest, no timer); the timer is shown as a growing sun, not a countdown | WCAG 2.2.1; GAG/XAG time limits | 6c |
| 9 | Reduce Motion: no parallax/CoreMotion, fades replace falls/flies/shake, no particle bursts | iOS Reduce Motion; GAG; Apple "motion intensity" | 9b |
| 10 | No flashing > 3 Hz; no full-screen white flashes | WCAG 2.3.1; XAG photosensitivity | 9b |
| 11 | Sound never carries unique info; haptics and sound toggles; separate music/sfx volume | GAG hearing basic | Settings |
| 12 | VoiceOver: full round playable (letters as buttons in a grid with rotor; hint read first; win/lose announced via `AccessibilityNotification.Announcement`) | GAG screen reader; Apple | GameView |
| 13 | Voice Control: `accessibilityInputLabels` for letters ("Letter B") | iOS Voice Control | GameView |
| 14 | Switch Control: logical focus order, no time pressure in the main game | GAG motor | all |
| 15 | Toasts stay ≥ 4 s and can be paused or recalled (notification history in Garden) | GAG "read at own pace"; WCAG 2.2.1 | toasts |
| 16 | "Say it" button reads the word/fact (AVSpeechSynthesizer); dyslexia-friendly spacing option | GAG cognitive; [derived] | PlantEarned |
| 17 | App Store Accessibility Nutrition Labels declared accurately (iOS 26) | Apple (see apple-capabilities.md) | release |
| 18 | At least 2 disabled players in each playtest round (P-13) | GAG "include impaired players in playtesting" | testing |

**Plan:** Task 16 gets this table as its checklist. Unit/UI tests: (1) `KeyState.accessibilityValue` strings; (2) XCUITest at AX5 Dynamic Type: all 26 keys hittable and hint not truncated (`label` full length); (3) the Reduce Motion flag routes `MotionToken` to fades; (4) ButterflyGameModel "relaxed" mode has `timer == nil` and still awards ≥ 1 item; (5) the prune scorer accepts a tap sequence that equals path coverage.

### P-12. Educational transfer: in-loop spaced review (fixes A14) — P1, M
**Rationale:** Cepeda 2006 (spacing); Roediger and Karpicke 2006 (testing effect). Section 2.13.
**Spec: move "spaced Garden review rounds" from section 10 phase 3 into the first release, add to section 2:**
> **Review words.** About 1 in 5 regular rounds is a *review* of an already-earned or previously-revealed entry, scheduled at +1, +3, +7, +21 days from first encounter (on a miss, restart at +1). Review rounds use the same mechanics, are labelled "🌿 Remember this one?", grant water normally, and do not award a new plant (they grant +2 growth points to that plant instead). The plant card shows "Remembered 3 times". No review on Daily Bloom.

**Plan:** Task 4 (`WordProvider` gets a `ReviewScheduler`).
Tests: (1) schedule intervals; (2) a miss resets to +1; (3) the review share of rounds is ≈ 20% over 100 simulated rounds when due items exist, and 0% when none are due; (4) review never selects today's daily id; (5) DST-safe day math.

### P-13. Playtest plan (fixes A17) — P0, S (plan) / ongoing
**Rationale:** Nielsen (iterate with about 5 per round; more for quantitative); Hanna, Risden and Alexander 1997 (age-grouped testing; under-12s struggle to think aloud); Toca Boca (watch kids play); GAG (include disabled players). [Nielsen PRIMARY, search: https://webarchive.library.unt.edu/web/20121006195132/http://www.useit.com/alertbox/20000319.html ; Hanna 1997 PRIMARY, search: https://doi.org/10.1145/264044.264045]
**Plan: new Task 16b "Playtests" (3 rounds, each after a build milestone):**
- **Who per round (n = 15):** 5 kids 6-8 (with a parent present, ≤ 20 min sessions, observe rather than think-aloud, short post-questions with a smiley scale), 5 kids 9-12, 5 adults 18+ casual word-game players (≥ 1 word game/week). Include ≥ 2 players using VoiceOver, Switch Control, or large text across rounds. Get parental consent and child assent, record no faces, and keep data on the owner's devices.
- **Rounds:** R1 paper/TestFlight FTUE + core loop (Tasks 5, 9, 10, 10a); R2 garden + unlocks + butterfly (6-6d, P-07); R3 full release candidate incl. ads and paywall (adult group only for the paywall).
- **Tasks:** (1) start the app and play until you get a plant (no help); (2) find today's Daily Bloom; (3) water a plant; (4) use help on a hard word; (5) (R2+) catch a butterfly; (6) find where to turn off sounds; (7) adults: find out what Plus costs and how to cancel.
- **Metrics and success thresholds [derived]:** time to first letter tap: median ≤ 20 s; first plant earned: ≥ 90% of kids 6-8 unassisted by 90 s; tutorial completion ≥ 95%; tasks 2-4 success ≥ 80% per group; wrong-tap/mis-hit rate on keys < 5%; kids' "how fun" smiley median ≥ 4/5; adults SEQ (single ease question) ≥ 5.5/7 on tasks; zero instances of a child reaching a paywall, external link or ad without the gate; adults correctly state the price and how to cancel (100%); no player calls the loss state "dead"/"sad" unprompted (≥ 80% describe it neutrally).
- **Instrumentation:** the same event list as P-14 in a debug build, plus screen recording (with consent).
- **Exit rule:** any threshold missed → fix → re-test that task with 5 new players.

### P-14. Privacy-light analytics event list (fixes A13) — P1, M
**Rationale:** COPPA 2025 (internal-operations notice, retention), AADC (data minimisation, profiling off), Apple 5.1.4, FTUE funnel practice. Sections 2.1/2.12.
**Spec: add to section 11 "Analytics":**
> First-party only, no third-party SDK, no IDFA, no device fingerprint. Events aggregate **on device** into daily counters. 13+ users who consent upload an anonymous daily batch (random install ID rotated every 90 days). Under-13 never uploads (counters stay local and feed only on-device features such as AssistTuner). Retention, conversion and acquisition rely on **App Store Connect Analytics** (Apple-aggregated, user opt-in) wherever possible. Each event lists its purpose in the privacy policy (COPPA internal-operations notice). Retention: 13 months for aggregates, 90 days for batches.

| Event | Properties (no free text, no PII) | Purpose |
|---|---|---|
| `ftue_step` | step (age/tutorial_start/first_letter/first_win/garden_tip/done/skip), secs_since_launch | FTUE funnel |
| `round_end` | level, difficulty_bucket, solved, misses, help_steps (0-3), is_daily, is_review, duration_bucket | difficulty tuning, P-02/P-04 |
| `help_used` | step, misses_at_use | hint ladder value |
| `session` | length_bucket, rounds, sundown_shown, ended_on (sundown/home/background) | session health |
| `tend` | action (water/soil/sun/repot/prune/mist), source (app/widget/intent) | widget value |
| `unlock` | feature | P-07 pacing |
| `ad_event` | format, placement, shown/failed/skipped_offline, holdout | kill-switch |
| `paywall` | entry_point, viewed, started, purchased, restored | conversion |
| `notif` | scheduled, opened, auto_stopped | re-engagement cap |
| `a11y_snapshot` (weekly) | voiceover, reduce_motion, dynamic_type_bucket, differentiate_without_color, haptics_off, sound_off | accessibility priority |
| `ai_fallback` | feature, reason (unavailable/guardrail/validator) | AI reliability |
| `error` | domain, code | crash-free complement |

**Plan:** new **Task 11d "Telemetry"**: `TelemetryStore` (on-device aggregation), `UploadPolicy`.
Tests: (1) under-13 → `UploadPolicy.allowed == false` always; (2) no property accepts free text (type-level enums); (3) aggregates roll off at 13 months / batches at 90 days; (4) the install ID rotates; (5) events are dropped when consent is false.

### P-15. Launch metrics dashboard (fixes A17) — P1, S
**Rationale:** GameAnalytics Q1 2024 global medians D1 22.91% / D7 4.20% / D28 0.85% (puzzle has the highest D7 among genres) [PRIMARY report via secondary, search: https://gamedevreports.substack.com/p/gameanalytics-benchmarks-in-mobile]. The spec's kill-switch thresholds (section 16) already sit above these medians.
**Spec: add to section 16 "Measure":**
> **Launch dashboard (weekly, by cohort and age band; under-13 rows from App Store Connect only):**
> - *Acquisition & FTUE:* installs; FTUE funnel (each `ftue_step`); time-to-first-letter p50/p90; tutorial skip rate.
> - *Core loop health:* rounds/session; solve rate by level and difficulty bucket (target 70-85% for regular rounds) [derived]; help usage per round; loss-then-quit rate (session ends within 30 s of a loss: target < 15%) [derived].
> - *Retention:* D1/D7/D30 (targets: D1 ≥ 35%, D7 ≥ 12%, D30 ≥ 5% [derived from benchmark medians + puzzle uplift]); Daily Bloom participation among DAU; % sessions ending on Sundown (healthy-stop indicator, target ≥ 30%).
> - *Garden:* tends/day; widget tends share; unlock reach by day 7.
> - *Monetization:* ad impressions/session (13+), holdout deltas, paywall view→start→purchase, trial→paid, refunds/support tickets.
> - *Wellbeing guardrails:* share of sessions > 45 min; sessions after local bedtime (under-13: should be ≈ 0); notification auto-stops; ad-related share of 1-2★ reviews.
> - *Quality:* crash-free sessions ≥ 99.5%; cold-launch-to-interactive p90 ≤ 2.0 s (MetricKit); hang rate.
> - *Accessibility:* % of players with each a11y setting (prioritises fixes).

**Plan:** add a dashboard definition doc + the Task 11d event list. No app code beyond P-14.

### P-16. Kid streak framing and FOMO trims (fixes A16, part of A12) — P1, S
**Spec: add to section 3:**
> Under-13 (default) and anyone who opts in via Settings > "Calm streaks": show **"Garden days: 23"** (cumulative days played) instead of a consecutive count. Streak badges for this group track garden days (7/30/100 days played). The Glow Lantern is also earned from "first Daily Bloom of the week" (already in section 16), so no consecutive-day requirement is needed to meet every visitor.

**Plan:** Task 5 streak (`displayMode`) and Task 6d badge counters.
Tests: (1) cumulative count increments once per local day and never decreases; (2) badges evaluate against the selected counter; (3) the Lantern is obtainable within 7 days with no consecutive play.

### P-17. Show drop odds and remove random-reward pressure (part of 2.5) — P2, S
**Spec: add to section 16 under Rose of Jericho:** "The Plant Guide shows 'Rose of Jericho: about 1 in 10 finished rounds, guaranteed within 15' in plain words. Butterfly rare visitors show 'rare (about 1 in N plays)'. No 'limited time' collectibles."
Tests: odds strings are generated from `Economy.json` (no hard-coded duplicates).

### P-18. Performance budgets (part of A10) — P1, S
**Spec: add to section 5b Rules:**
> Budgets on the smallest supported device class (iPhone SE 3rd gen / iOS 17.5): cold launch → first frame ≤ 400 ms (Apple guidance), → interactive Home (after skippable intro) ≤ 2.0 s; round screen 60 fps with p95 frame time ≤ 16.7 ms during petal fall; win celebration ≤ 120 particles; Metal shaders and CoreMotion off when Reduce Motion is on, in Low Power Mode, or when off-screen; memory ≤ 250 MB in the Garden with 50 plants.

**Plan:** Task 9b/9c perf tests (`XCTOSSignpostMetric`, `XCTApplicationLaunchMetric`) with these thresholds as baselines. Low Power Mode test: shaders disabled (`ProcessInfo.isLowPowerModeEnabled` injected).

### P-19. Sync the plan with Economy v1 (fixes A15) — P0, S
**Plan edits:**
- Task 5: replace "drop 15% any round end, guaranteed at streak milestones (7, 30)" with "10% per completed round, max 1 drop/day, stock cap 3, pity after 15 rounds, guaranteed at streak 7/30/100 (spec section 16)". Tests: pity, daily cap, cap 3.
- Task 6: add "bank hard cap 40; trickle refills to 5 only".
- Task 11: delete "less than 2 actions since last". Use the section 16 grace period, 3-minute gap and 6/day max + P-08. Tests per section 16.
- Task 14: "after 3 wrong guesses" → "AI rephrase of ladder step 1 (P-04)".

### P-20. "Ask the Gardener" scope (part of A12) — P1, S
**Spec: amend the section 5b "Ask the Gardener" bullet:** "13+ only by default. Presents 6-8 **suggested questions** built from the plant's vetted fact (tap to ask). Free-text input is available only for 13+ and only when on-device AI is available. Answers are grounded in tool-called bank data. Off-topic → 'I only know about plants in your garden.'"
Tests: the under-13 policy hides the entry point; suggested questions are generated without free text; the topic guard falls back on adversarial input (mock).

---

## 5. Open questions for the owner

1. **Under-13 ads:** zero ads, or a contextual banner only? (Recommendation: zero, if the age band share is small. Measure the band share in TestFlight.)
2. **Adult ad cadence:** keep "every 3rd round" or start at 4-5 given the 1-2★ review evidence? The holdout will tell, but which default ships?
3. **Two-track progression (P-01):** confirm that the word level advances on plants earned, and the garden track holds the long pacing.
4. **Difficulty bands (P-02):** accept computed expected-miss bands overriding the length table, which may move some current L1 plants upward?
5. **Loss copy (P-06):** approve "resting" and dropping the droop/grey "dead" flower state. This needs a new visual-agent asset.
6. **Sundown arc (P-09):** 5 rounds per "garden day"? Is the under-13 bedtime default of 20:30 acceptable, and should adults get it as opt-in only?
7. **Streak display (P-16):** cumulative "garden days" for under-13 only, or for everyone?
8. **Declared Age Range:** adopt on iOS 26+ now (sibling research recommends "Should"), and with which age gates (13/16/18)?
9. **Spaced review in v1 (P-12):** pull forward from phase 3?
10. **Feature scope:** given P-07 and the juice ceiling, should any 5b items (Metal shaders, CoreMotion parallax, Image Playground, Visual Intelligence) move to post-launch to protect performance and onboarding?
11. **Playtest logistics (P-13):** who recruits the child testers, and where (family/friends with consent)? Is there a budget for gift cards?
12. **Analytics upload (P-14):** any server at all for 13+, or App Store Connect analytics only (simplest privacy story)?

---

## Appendix: source index (by label)

PRIMARY, fetched: Apple HIG Designing for games; Apple HIG Onboarding; Apple HIG Playing haptics; Apple App Review Guidelines (1.3, 3.1.2, 4.5.4, 5.1.4); Apple Declared Age Range documentation; Game Accessibility Guidelines full list; Zach Gage / TypeShift (Game Developer).
PRIMARY, search-summary only: Ryan/Rigby/Przybylski 2006; Sweetser and Wyeth 2005; Hunicke Hamlet 2004; Cepeda et al. 2006; Vuorre et al. 2022; Fitz et al. 2019; Meyer/Radesky 2019; McLoone (Wolfram) hangman; COPPA Federal Register 2025; ICO AADC PDF; CPC key principles PDF; Xbox Accessibility Guidelines index; GameAnalytics Q1 2024; Nielsen 2000; Hanna et al. 1997; Wardle interviews; Toca Boca interviews; Common Sense ratings page; RITEC/UNICEF; Ofcom children's research; Project Horseshoe coziness report.
PRIMARY, not fetched (cited from stable knowledge): WCAG 2.2; Roediger and Karpicke 2006; WWDC19 "Optimizing App Launch".
SECONDARY: law-firm summaries (Epic/FTC, COPPA, DSA guidelines, CPC); Kao 2020 and juiciness summaries; Duolingo streak podcast summaries; Alter stopping cues.
OPINION: GameAnalytics/Supersonic/Unity FTUE blogs; Pascal Luban FTUE; Hook-model critiques; Taplytics Duolingo case; all [derived] timings and thresholds in section 4.

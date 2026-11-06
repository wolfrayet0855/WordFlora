# Plants that respond back: attachment research and feature ideas (2026-11-06)

Scope: what makes people (kids and adults) bond with a non-living thing, and which iOS features could make WordFlora plants respond to the player in return. Research only; no code was changed. Builds on `nature-emotion-attachment.md` (P1 personality, P17 reciprocity) and `apple-capabilities.md`. Owner direction: be bold and rank by upside. Legal and App Review limits are listed as facts; smaller risks are noted but do not shrink the ideas.

What exists today: `PlantVoice` (3 fixed traits x 5 events, line varies by day), hello sway, `LoveEngine` (5 petals, one falls per day without love, then a seed; Calm and Quiet Garden exempt), Energy hearts, weather, pots, butterfly visitors, `ReadAloud` (AVSpeech), App Shortcuts (`WaterGardenIntent`, `OpenGardenIntent`), an interactive widget water control.

## 1. What the evidence says (short)

1. **People see minds where it helps them.** Epley, Waytz & Cacioppo's three-factor theory: we anthropomorphize when human-like knowledge is easy to apply (faces, voices, human-like timing), when we want to predict and understand an agent (effectance), and when we want social connection (sociality). Design levers: readable "body language", predictable personality, and warmth. Children apply all three more readily than adults. [1]
2. **Social cues get social responses automatically (CASA / media equation).** People are polite, reciprocal and flattered by computers that show even minimal social cues, while knowing it is a machine. A plant that says thank you and remembers you gets treated as a social partner, so it carries a matching duty not to exploit that. [2]
3. **Contingency is the strongest "alive" signal.** In Watson's mobile studies, 2-month-olds whose mobile moved when they moved began smiling and cooing at it; infants whose identical mobile moved at random did not. Response to *my* action, within about a second, matters more than looks. [3]
4. **Parasocial bonds are one-sided.** Horton & Wohl described felt intimacy with media figures who cannot respond. Our advantage is that the plant *can* respond. That makes real two-way responsiveness the best upgrade we can make, not more speech. [4]
5. **Kids grant robot pets minds and moral standing.** Preschoolers credited Sony's AIBO and a stuffed dog alike with mental states, social rapport and moral standing (about two thirds of children for each). Kids will feel a plant's "feelings" are real. [5]
6. **Caring for a virtual pet can build empathy.** Grade 4-5 children who cared for a virtual dog for three weeks scored higher on empathy and humane attitudes; stronger bonds tracked higher empathy. Care that is *rewarding* rather than anxious is a real benefit we can claim. [6]
7. **The harm pattern is dependence plus guilt.** Laestadius et al. found Replika users harmed when they felt the bot had needs they *had* to meet, and when access was cut. Radesky et al. found 80% of apps used by 3-5-year-olds used manipulative design, including "parasocial relationship pressure": characters looking sad or pleading when a child tries to leave. [7][8]
8. **Rules.** UK Children's Code Standard 13 bans nudges that lead children to share more data or switch off privacy protections, and encourages nudges toward wellbeing such as taking breaks. The FTC's $520M Epic settlement (2022) shows dark patterns plus COPPA violations are enforced together. The amended COPPA Rule has been fully in force since 22 Apr 2026. Apple guideline 1.3 limits third-party analytics and ads in Kids Category apps. [9][10][11][12]

**Design rules from this:** (a) answer every touch within about 150 ms; (b) a fixed personality per plant so it is predictable but not mechanical; (c) memory of shared moments; (d) the plant gives back (reciprocity); (e) gentle surprise: the plant sometimes acts first (a yawn at night, a sneeze at pollen); (f) **the plant's feelings are only ever happy, curious or sleepy, never needy.** It never asks you to stay or come back, and leaving is warm ("See you, sunshine").

**One audit finding (evidence-based recommendation, not a legal limit):** `LoveEngine` petal loss applies to under-13 players unless Calm or Quiet Garden is on (`AppModel.loveExempt`). Petals falling because nobody visited is the absence-guilt pattern in Radesky's taxonomy, and young children believe the plant feels it [5]. Recommendation: for under-13 players, absence makes the plant *sleep* (closed petals, a little nightcap, never lost petals), and a hello wakes it with a stretch. That keeps the loop and drops the guilt.

## 2. Idea matrix (ranked by upside)

Effort S/M/L. COPPA: "none" means no personal data leaves the device. Review: risk under App Review. Calm: fits the calm brand. Ship: 1.1 or later.

| # | Idea | Effort | COPPA / privacy | Review | Value | Calm | Ship | Under 13 |
|---|---|---|---|---|---|---|---|---|
| 1 | **Living Touch**: stroke leaves to pet the plant; it leans into your finger, Core Haptics "purr" or heartbeat, per-trait reactions | S-M | none | none | Very high | Yes | 1.1 | Yes |
| 2 | **Say it to me**: child says the guessed word aloud; on-device speech; the plant "hears" and blooms; the plant reads letters back | M-L | Voice is personal info only if collected; keep on device, no storage | Low (mic and speech purpose strings) | Very high for kids and literacy | Yes | 1.2 | Yes, parent toggle |
| 3 | **Hello from anywhere**: "Hey Siri, say hello to Daisy" + widget hello button + snippet showing Daisy's reply; counts as love | S-M | none | Low (phrases must include app name) | High | Yes | 1.1 | Yes |
| 4 | **Garden Memory**: plants remember firsts and favourites ("You taught me 'meadow' on Tuesday"); weekly pressed-leaf letter; small gifts | S-M | none (local/iCloud) | none | High | Yes | 1.1 | Yes |
| 5 | **Tilt garden**: Core Motion; plants lean with the tilt, petals drift, tilt to pour the watering can | M | none (motion needs no permission) | none | High wow | Yes, damped | 1.1 | Yes |
| 6 | **Bring Daisy home (AR)**: place your plant on the table at real size, walk around it, wave to make it sway; photo to Photos | M-L | Camera frames stay on device; photo saved only by the user | Low (camera purpose string) | Very high wow and word of mouth | Mostly | 1.2 | Yes, with parent gate on first camera use |
| 7 | **Bloom watch Live Activity**: after a session, Dynamic Island/Lock Screen shows a bud opening; ends at bloom with "She opened!" | M | none | Medium (must track a real, bounded event; no ads) | Medium-high | Yes if rare | 1.2 | Yes, opt-in |
| 8 | **Good-news notifications in the plant's voice**: "Daisy opened a new leaf this morning"; opt-in, max 1/day, never about absence | S | none | Low (opt-in per 4.5.4) | Medium | Yes | 1.1 | Parent opt-in |
| 9 | **Plant initiates (gentle surprise)**: waves first on open, yawns after 9 pm, sneezes when a bee visits, hums when it rains | S | none | none | High per effort | Yes | 1.1 | Yes |
| 10 | **StandBy night-light garden**: full-screen widget where plants sleep at night and wake at sunrise | S | none | none | Medium | Very | 1.1 | Yes |
| 11 | **Visit a friend's garden (SharePlay)**: water each other's plants over FaceTime; no chat inside the app | L | Contact data held by FaceTime, not us | Medium | High for families | Yes | Later | Only via FaceTime with contacts approved under Screen Time |
| 12 | **Focus filter**: Sleep or Reduce Interruptions Focus = night garden, no sounds, no notifications | S | none | none | Low-medium | Very | 1.1 | Yes |
| 13 | **Watch complication**: tiny plant face; tap wrist to say hello; haptic tap back | M | none | Low | Medium | Yes | Later (no watch app yet) | Yes |
| 14 | **Plant voices (AVSpeech)**: each trait gets its own pitch and rate for PlantVoice lines, optional | S | none | none | Medium | Yes if quiet by default | 1.1 | Yes |
| 15 | **Visual Look Up / "find this plant outside"** on photos via VisionKit | M | On device | Low | Low (misidentification; never edibility) | Yes | Later | Adults only |
| 16 | TipKit hints ("Try stroking a leaf") | S | none | none | Supports #1 and #5 | Yes | 1.1 | Yes |

**Hard limits (facts):**
- COPPA: audio, photos and persistent identifiers from under-13 users are personal information if *collected*. On-device processing with no upload or storage avoids collection, so #2 and #6 must never send audio or images off the device, including to Apple's server-based speech.
- App Shortcuts phrases must contain the app name (#3).
- Push or local notifications cannot be required for the app to work, and marketing notifications need explicit opt-in (guideline 4.5.4).
- Live Activities must track a real, time-bound activity (#7); they cannot be used for ads.
- Kids Category apps (guideline 1.3) cannot carry third-party ads or analytics. WordFlora ships AdMob, so it should stay out of the Kids Category or drop ads for that build.
- Camera, microphone and speech each need an Info.plist purpose string and a system prompt.

## 3. Ranked shortlist (build #1 first)

**1. Living Touch (S-M, 1.1). Recommended first build.** *What:* drag along a leaf to stroke it. The plant leans toward the finger (spring physics, about 8 degrees), the leaves ripple, and Core Haptics plays a trait-specific pattern: a cheerful plant giggles (quick taps), a sleepy one purrs (a slow continuous rumble), a shy one gives a single heartbeat, then a second as it warms up. After 3 strokes it says a new PlantVoice line ("That tickles!"), and a long, slow stroke makes it close its eyes contentedly. A tap hello still counts as love; a stroke counts as love too. *Trigger:* touch on the plant on the garden or plant page; response begins within 150 ms. *Why first:* this is Watson's contingency in its purest form [3], it involves no data and no review risk, it reuses PlantVoice and the hello sway, and it makes every later feature feel alive. *Calm:* haptics at half intensity, no sound, fewer particles. *Quiet Garden:* lean and haptic only, no lines. *Under 13:* fully on; tune durations so the haptic never runs longer than 1 second; respect the system haptics setting and our own toggle.

**2. Say it to me (M-L, 1.2).** *What:* in a round, a microphone button lets the player say the whole word. The plant cups a leaf to its "ear", and when it hears the word it repeats it in its voice (AVSpeechSynthesizer, trait pitch) and blooms. On a miss it says "I heard 'meadow'... try the letters?" and offers the keyboard. The plant can also read letters and a fact aloud. *Trigger:* hold-to-talk only, never an always-on microphone. *Rules:* SpeechAnalyzer / `requiresOnDeviceRecognition`; if on-device recognition is unavailable, hide the button rather than fall back to the server. No audio is kept. *Calm:* voice off by default, shown on screen as text. *Quiet Garden:* available, no fanfare. *Under 13:* on only after a parent-gated toggle; the privacy policy says audio never leaves the phone. Huge value for early readers and for kids who cannot type yet.

**3. Hello from anywhere (S-M, 1.1).** *What:* the App Shortcut "Say hello to \(plant) in WordFlora" uses a `PlantEntity` parameter. Siri, Spotlight, the Action button and a widget button all run a `HelloPlantIntent` that records love and returns an interactive snippet with Daisy waving and a fresh line (and an AVSpeech voice when Siri speaks it). The widget gets a "wave" button next to water. *Calm/Quiet:* same; Quiet Garden shows no petal count. *Under 13:* fine; no personal data, since the plant names are the child's own and stay on the device and in iCloud.

**4. Garden Memory (S-M, 1.1).** *What:* each plant keeps up to 20 memories: first word solved near it, your hardest word, the day it bloomed, the visitor it attracted, the stroke it liked. On some hellos (about 1 in 5, chosen by a fixed rule, never tied to rewards) it recalls one: "Remember 'thunder'? We were brave." Each Sunday a pressed-leaf letter appears in the Diary, and stage 3+ plants leave small gifts (stickers, never currency). *Calm:* same. *Quiet Garden:* letters only. *Under 13:* only memories of game events, never free text the child typed besides plant names.

**5. Tilt garden (M, 1.1).** *What:* CMMotionManager at 30 Hz, low-pass filtered: plants lean up to 6 degrees with the device, loose petals and pollen drift, and on the tending screen tilting the watering can pours it (tap stays as an alternative for accessibility). Shy plants lag slightly behind and sleepy ones sway slowest, so personality shows in motion. *Calm and Reduce Motion:* lean capped at 2 degrees, no particles. *Quiet Garden:* on. *Under 13:* on. Pause motion when off-screen to save battery.

**6. Bring Daisy home, AR (M-L, 1.2).** *What:* RealityKit / ARKit world tracking places the player's plant, in its pot, on a real table. It turns to face the camera, waves when you come close, sways when you blow (microphone level only, no recognition) or wave. A shutter button saves a photo to Photos with a small WordFlora leaf mark. *Trigger:* "Bring home" on the plant page. *Rules:* camera frames are processed on device and never uploaded; no face tracking; the photo is saved only when the player taps. *Calm:* no music, slow animations. *Quiet Garden:* available. *Under 13:* parent gate before the first camera permission prompt; the share sheet stays behind the parent gate. Needs 3D plant assets, which is most of the cost; start with 5 hero plants.

## 4. Citations

1. Epley N, Waytz A, Cacioppo JT. "On seeing human: a three-factor theory of anthropomorphism." *Psychological Review* 114(4), 2007. https://pubmed.ncbi.nlm.nih.gov/17907867/
2. Nass C, Steuer J, Tauber ER. "Computers are social actors." CHI 1994. https://doi.org/10.1145/191666.191703
3. Watson JS, Ramey CT. "Reactions to response-contingent stimulation in early infancy." *Merrill-Palmer Quarterly*, 1972. Read via the summary in Butko & Movellan 2010: https://mplab.ucsd.edu/46/media/2010-ButkoMovellan-NeuNet-Contingency.pdf
4. Horton D, Wohl RR. "Mass communication and para-social interaction." *Psychiatry* 19(3), 1956. https://doi.org/10.1080/00332747.1956.11023049
5. Kahn PH, Friedman B, Pérez-Granados DR, Freier NG. "Robotic pets in the lives of preschool children." *Interaction Studies* 7(3), 2006. https://doi.org/10.1075/is.7.3.13kah
6. Tsai Y-F, Kaufman D. "The socio-emotional effects of a computer-simulated animal on children's empathy and humane attitudes." *J. Educational Computing Research* 41(1), 2010 (thesis 2008). https://summit.sfu.ca/item/9146
7. Laestadius L, Bishop A, Gonzalez M, Illenčík D, Campos-Castillo C. "Too human and not human enough: mental health harms from emotional dependence on the social chatbot Replika." *New Media & Society*, 2022. https://doi.org/10.1177/14614448221142007
8. Radesky J, Hiniker A, et al. "Prevalence and characteristics of manipulative design in mobile applications used by children." *JAMA Network Open*, 2022. https://pmc.ncbi.nlm.nih.gov/articles/PMC9206186/
9. UK ICO. "Age appropriate design code, Standard 13: Nudge techniques," 2020. https://ico.org.uk/for-organisations/guide-to-data-protection/ico-codes-of-practice/age-appropriate-design-a-code-of-practice-for-online-services/13-nudge-techniques
10. FTC v. Epic Games, $520M settlements (COPPA and dark patterns), 2022. Summary: https://www.hunton.com/privacy-and-cybersecurity-law-blog/ftc-announces-520-million-in-settlements-with-epic-games
11. FTC COPPA Rule amendments, final rule 2025, compliance by 22 Apr 2026. Summary: https://www.hunton.com/privacy-and-cybersecurity-law-blog/coppa-rule-amendment-compliance-deadline-approaches
12. Apple. App Store Review Guidelines, 1.3 Kids Category and 4.5.4 notifications. https://developer.apple.com/app-store/review/guidelines/

Source notes: [3] and [5] were checked through their abstracts and secondary summaries, not the full text. [10] and [11] are law-firm summaries. Apple's current guideline wording should be checked against the live page before submission.

> **REMOVED 2026-11-07 (owner): AppLovin is not accepting publisher accounts, so no AppLovin product ships in the app. Ignore every AppLovin step below. AdMob stays the only ad network. Gate G4 becomes "AdMob hardening" (see release-plan-extended.md).**

# Status review, Sat 2026-11-07 13:00 EST (project manager)

Inputs: `docs/pm/release-plan-extended.md`, `docs/STATUS.md` (Final QA through G2), `docs/pm/backlog.md`, `docs/setup/owner-setup-steps.md`, `docs/setup/cloudkit-new-fields.md`, `docs/pm/butterfly-net-spec.md`, `git log main..HEAD`, `git worktree list`, the lead's state summary. Tip `b371a58`. Worktrees: G2b builder at `0549fc8` ("first pass, not yet built"), art lane at `330469d`.

Owner rulings in force: full scope in the first release; date extensions allowed; no feature is cut or deferred without the owner's approval. Anything below that would move scope is marked **needs owner approval**.

## 1. Verdict: schedule and scope

**Thu 11-19 is reachable but has at most one day of slack. Plan externally for Mon 11-23; keep 11-19 as the internal target.** The plan's own update already said "about Mon 11-23" after G2b (38 h) and G1v were added; G1 and G2 then closed about two days early (planned Mon 14:00 and Tue 20:00, both merged Sat before noon), which buys that time back if the machine keeps its pace.

Re-baselined serial path at the plan's own rate (about 14 builder-hours per calendar day, one `xcodebuild` at a time):

| Gate | Hours | Exit (re-baselined) | Plan said |
|---|---|---|---|
| G2b net + Quick wings + Gentle Net (running; written, not built) | 38 | Tue 11-10 morning | (new) |
| G3 pack framework + starter pack, then Mist Maker last | 32 | Thu 11-12 afternoon | Thu 11-12 20:00 |
| Owner: CloudKit dev run + one Production deploy | 1 (owner) | Thu 11-12 evening | Fri 11-13 |
| G4 AppLovin via AdMob mediation, test mode | 14 | Fri 11-13 afternoon | Sat 11-14 12:00 |
| G5 full Frost & Lantern (art accepted by Fri 11-13 20:00) | 20 | Sun 11-15 | Mon 11-16 20:00 |
| G6 full regression + Release + TestFlight | 16 + owner | Mon 11-16 night | Wed 11-18 20:00 |
| Owner device checks, ASC attachments, screenshots | 1.5 days (owner) | Wed 11-18 | |
| Submit | | **Thu 11-19** (slip: Mon 11-23) | |

**Critical path:** the machine, serially: G2b → G3 → CloudKit deploy (owner, must precede the TestFlight build) → G4 → G5 → G6 → owner archive/TestFlight/device checks → submit. Nothing else on the list is on the path; everything lock-free (art, copy, docs, App Store Connect, review notes, labels) should be done now so it is never the reason to wait.

**What slips first, in order:**
1. **G5 art acceptance (Fri 11-13 20:00).** The plan already carries the owner-decided fallback (dormant framework, pack to 1.1, no thin pack, submit moves up). Executing that fallback is still a scope change: **needs owner approval on the day**, even though it was pre-decided.
2. **G4 AppLovin serving.** If the AppLovin account is not approved in time the adapter still ships in test mode and the owner flips serving after submission; nothing is cut. The account signup is the only owner lead time that is already late if it was not started Fri night.
3. **The date.** Prefer slipping to Mon 11-23 over shortening G6; G6 is the only full-suite run after G1 to G5 landed.
4. **Owner-side time (device checks, ASC).** About 2 to 3 days of owner hours between G6 and submit; see section 5 for what is not yet in the plan.

Two small code items are not in any gate and need a home (both build-lock work, about 1 to 2 h each): the "charged twice" note when auto-renew is already off (read `Product.SubscriptionInfo.RenewalInfo.willAutoRenew`), and the Pruning Pro faded-bloom placement across plants (a look on localhost first; a per-plant anchor is art data, not a stored field). Put both in the G3 lane's tail or the first hour of G6, not in a new gate.

## 2. Risks, ranked, with a mitigation each

1. **Machine capacity (technical).** One `xcodebuild` at a time; every gate is machine-bound; the host has killed runs for memory and load reached 400 when two agents built. *Mitigation:* the build lock is the law for every agent including cleanup/perf; the Opus cleanup agent writes code but does not build until G2b merges, then builds once under the lock; no full UI suite before G6; G6 runs overnight on a rebooted simulator with nobody else on the box. Builders commit small, buildable steps so a lead restart loses minutes, not hours.
2. **App Review (App Review).** Exposure points: three-option paywall must match the IAP review screenshots; `plus_lifetime` and `pack_frost_lantern` review screenshots; the "cancel your subscription" note; Terms of Use link in the description (3.1.2); no price, lock or buy button on any under-13 screen; privacy labels must match both SDK manifests; the age-rating questionnaire re-answered on Apple's new tiers; reviewers cannot pass launch arguments (see section 5). *Mitigation:* refresh D8 review notes in G6 (owner steps file), with a plain-language path to every gated and adult surface, and one IAP screenshot per product from the G6 build.
3. **AppLovin consent and child rules (App Review + legal).** A consent mistake is a rejection and a legal exposure. *Mitigation:* `ageRestrictedTreatment` before `start()`; under-13 and unknown age "never starts any SDK" unit test from the built bundle; AppLovin on both UMP partner lists and both messages republished before the owner flips serving; serving flip after submission only.
4. **CloudKit single deploy (data).** A second stored field after G3 means a second deploy and device run; the deploy must happen before the TestFlight build; SwiftData may store arrays as Bytes, so the dev schema is the truth. *Mitigation:* G3 ends with "one new stored field, `lastMistedAt`, commit <hash>"; the integrator greps `Models/` at every merge (G2b, G4, G5 must each report "no stored fields"); the owner runs the dev schema and deploys the evening G3 merges, not after G5.
5. **G2b scope and feel (technical + owner call).** 38 h, written but not built; seeded tests may shift (new RNG draws); the "gentle never harder" property is the under-13 guard; the owner playtest decides turns. *Mitigation:* draw new moves after the existing draws; the owner playtests on the simulator the day G2b merges; the pre-decided fallback (drop turns, keep speed, hoop, perch) is a tuning change, not a cut.
6. **Owner-side dependencies (owner).** `plus_lifetime`, `pack_frost_lantern`, offer codes, sandbox testers (plain, family, Ask to Buy), AppLovin account, AdMob partner lists, app-ads.txt, privacy policy paragraphs, support and marketing URLs live, Paid Apps Agreement Active. *Mitigation:* one checklist with dates (section 4, owner row); the PM pings the owner each evening with the next-day items; products and codes created before Tue so G3's `SKTestSession` and the G6 sandbox runs have real counterparts.
7. **Flaky UI under load (technical).** XCTest stalls, `performAccessibilityAudit` hangs, runner failing to start. *Mitigation:* rerun-alone rule; reboot before G6; stalls noted not failed; simulators erased when they pass about 200 processes.

## 3. How the team is working

**Keep:** root-causing instead of loosening (StoreKit entitlements fix, rest-card idle, Shed reflow); no audit skipped or excused without a printed reason; dated STATUS sections with counts and the "do not claim green without the log" rule; small merges with a real merge commit; builders on their own simulators and derived-data folders; the build lock and watchdog; the art lane running lock-free ahead of the gate.

**Change:**
- *Shared scratch files are per agent.* The G2 builder overwrote the shared `run.sh`. Every script and lock file other than `wf-build.lock` goes under `<scratchpad>/<agent name>/`. Put this line in every brief.
- *Research briefs must check against the audit.* The key-marks research recommended a Dynamic Type cap that Apple's audit rejects; the builder had to undo it. Add to every research brief: "Any layout recommendation must pass `performAccessibilityAudit` on iOS 26.5 (no Dynamic Type caps, nothing hidden from VoiceOver that stays in the hierarchy); say so for each recommendation."
- *Briefs list words to avoid in commits.* G2 reworded commit bodies because `SKTestSession` matched the `session` grep in the attribution check. Briefs should say: no vendor, model or tool names, and write `SKTestSession` only in file names or as "the StoreKit test session" in bodies. (Alternative: the owner tightens the grep to `claude-session` and word boundaries; **needs owner approval**, it is the owner's rule.)
- *No early hand-back.* The G0 verifier handed back with batches unrun. A verifier waits for the lock and finishes the batch list, or reports "stopped, these batches unrun, here is the command to resume"; the integrator then resumes rather than re-planning.
- *Empty reports are failures.* A cleanup agent returned nothing. Every agent ends with: files touched, tests run with counts, what it did not do. The lead treats an empty report as a failed task and re-dispatches with a narrower brief.
- *Verification before merge, not after.* Two 11-06 streams merged "built but unverified" because the machine was overloaded; G0 then spent a day finding what they broke. Rule: a builder's report must carry the unit count and the named UI classes from its own simulator; the integrator runs only the classes the gate touched.
- *Wasteful:* repeated full UI suite runs outside G0/G6; agents starting test runs during another agent's integration (noted 11-05); research that re-derives facts already in `docs/research/`. Point agents at the doc first.

**Per-agent notes (owner asked for these to be delivered):**
- *G0 verifier:* good fixes (quest family line, Badges reflow, clue card). Change: do not hand back with batches unrun; wait on the lock and finish, or write the exact resume command and the unrun list.
- *G1 builder (Field Notes, Pruning Pro, SKAdNetwork):* keep: rulings met exactly (no mark on open, faded bloom only), cue-rate statistics test, honest open items. Change: the faded-bloom placement should have had a localhost look across three plants before hand-off; add a shot per plant family next time.
- *G2 builder:* keep: diagnosed the StoreKit reds to the entitlement, 14/14 with no skip, split the slow test instead of raising the allowance. Change: namespace scratch scripts; avoid the grep words in commit bodies; the pays-twice note should have read renewal info (noted as open, so it is honest, but it was a one-line read).
- *Keyboard builder:* keep: dropped the cap the audit rejects and made letters shrink to fit; waited for the appearance switch to settle. Change: nothing material.
- *Cleanup/perf agents:* the earlier one returned an empty report: not acceptable. The running one: write, do not build, until G2b merges; stay out of `ButterflyView`, `ButterflyGameModel`, `Butterfly.swift`, `ToolEngine` (G2b territory); report every file touched.
- *G2b builder:* keep committing small steps (one commit so far for a 38 h gate is too coarse; a lead restart would lose it). Build before writing more: the first pass is unbuilt. Draw new RNG moves after the existing draws. Report "no stored fields" explicitly.
- *Research agents:* keep sourcing with URLs and dates (SKAdNetwork list, name stories, visitor facts). Change: check audit compatibility of layout advice; read `docs/research/` before re-deriving; end with a one-table summary the builder can act on.

## 4. Delegation list

Build-lock work (one at a time, in this order): G2b (running) → G3 → G4 → G5 → G6. Everything else below is lock-free and runs in parallel now.

| Task | Agent | Brief (two lines) | Parallel? |
|---|---|---|---|
| G2b net + Quick wings + Gentle Net | Opus (running) | Build the first pass under the lock; small commits; seeds drawn after existing draws; "gentle never harder" property; report no stored fields. Hand off branch tip, unit count, the UI classes run. | Lock |
| Cleanup/perf | Opus (running) | Code only until G2b merges; stay out of butterfly files; one build under the lock after G2b merges; report files and counts. | Code yes, build no |
| G3 pack framework + starter pack, Mist Maker last | Opus | Per the G3 brief; `lastMistedAt` copies `lastPrunedAt` exactly and is the final commit; add the "charged twice" `willAutoRenew` read as a first small commit. Report "one new stored field, commit <hash>". | Lock, after G2b |
| G3 pot art, Lantern Keeper badge art | Opus (art lane, lock-free) | Procedural pots in `PotCatalog` style, badge `badge_lantern_keeper_t1..3`, previews on localhost; commit to the art branch before G3 starts. | Yes, now |
| G5 art: scene, robin, wren, snowdrop, hellebore stages | Opus (art lane, lock-free) + Sonnet (facts) | Art lane: scene on the weather layer, two stickers, two plants at every stage through `PlantThinning.json`. Sonnet: four facts with sources into `docs/research/visitor-facts.md` and a plants note, CopySafety-ready, by Wed 11-11. | Yes, now; owner accepts by Fri 11-13 20:00 |
| G4 AppLovin adapter | Opus | Per the G4 brief; adapter version pinned in STATUS; under-13 never-starts test; privacy manifest from the built bundle; hand back the label delta and app-ads.txt line. | Lock, after G3 |
| G4 pre-work: AppLovin disclosure and SKAdNetwork ids | Sonnet (bounded research) | Fetch AppLovin's published iOS data disclosure, SKAdNetwork ids and adapter version for Google Mobile Ads 13.x with URLs and dates; produce the exact `PrivacyInfo.xcprivacy` additions and the App Store Connect label delta table. | Yes, now |
| Review notes, description, keywords, subtitle, promo text | Sonnet (copy) then Fable (critique) | Rewrite D8 for the reviewer with no launch arguments: a plain path to adult, teen and under-13 surfaces, the three-option paywall, redeem, pack, weather, Field Notes; D6/D6b plus Plus Forever, pack and offer-code lines. Fable checks guideline fit (3.1.1, 3.1.2, 5.1.4, 1.3) and kid-copy tone. | Yes, now |
| Privacy label and age-rating answer sheet | Sonnet | One table per App Store Connect question with the answer and the source line in code or SDK manifest; new iOS 26 tiers; weather, purchases, ads. | Yes, now (AppLovin rows after the research task) |
| Screenshots plan | Sonnet | Choose 8 screens, light/dark, iPhone 17 Pro Max simulator for 6.9" and iPhone 16 Plus/11 Pro Max class for 6.5"; captions; a `FidelityScreensUITests`-style capture test to run in G6; IAP review screenshots per product. | Plan now; capture in G6 |
| Owner checklist with dates | Fable (this PM) | One dated owner list: AppLovin signup today, ASC products and offer codes by Mon, sandbox testers by Mon, privacy policy and support URL live by Tue, CloudKit deploy Thu 11-12 evening, device checks Tue 11-17 to Wed 11-18. | Yes, now |
| Faded-bloom placement look | Sonnet (bounded) | Render the faded bloom on six plants of different families via the existing shot test (needs the lock briefly) or the SVG preview page; report which plants it misreads; propose an anchor per plant family as art data. | Preview lock-free; shots under lock in G3 |
| Repot look test timing | none (done) | Split into four tests in G2; close the item. | |
| Critique of G2b before merge | Fable | Read the G2b diff against `butterfly-net-spec.md` sections 1, 2, 4, 6: under-13 unchanged, VoiceOver and Switch Control paths, copy through both avoid lists, seed stability. No code. | Yes, when G2b reports |
| Owner device checks | Owner | Living Touch feel and haptic, widget Say hello, badge-moment tap, thunder loudness, petal notes, Quick wings playtest, Listen-to-end stamp, key marks under Large Content Viewer/VoiceOver/Voice Control, Mist feel, UMP in simulated EEA, under-13 no ad, two-device sync after the deploy. | TestFlight build after G6; Quick wings and key marks can be checked on the simulator after G2b merges |

## 5. Missing from the plan for Apple review and a real launch

- **Reviewers cannot pass launch arguments.** D8's `-uitest-...` lines are useless to App Review. Replace with plain paths (Settings > Garden weather; age question on first launch; Plus page from Settings) and a sentence that weather is date-driven and cosmetic. No demo account is needed (no sign-in).
- **Age rating on Apple's new tiers.** The questionnaire must be re-answered on the current scheme before submission; answers for in-app controls (parental gate, age assurance), ads, purchases, weather. Expect 4+ or 9+; accept what it computes.
- **Privacy nutrition label delta** for AppLovin (after the G4 research) and a check that "Purchases" and "User content" answers match code. An inaccurate label is a rejection.
- **Support URL, marketing URL, privacy URL live.** The app points at `https://shapehaveninnovations.com/privacy` (assumption: the page is not yet live; the owner confirms). app-ads.txt needs the marketing URL set on the listing and the file at the domain root.
- **Terms of Use (EULA) link in the description** (D6b has it) and in the app (Plus page has it): required for auto-renewable subscriptions.
- **IAP review screenshots and notes** for `plus_lifetime` and `pack_frost_lantern`, captured from the G6 build; the first subscription group must be submitted with the version.
- **Export compliance:** done (`ITSAppUsesNonExemptEncryption = NO`, Debug and Release). Nothing to do at upload.
- **Kids Category decision:** stays out (third-party ads forbid it); keep "Made for Kids" unselected; the mixed-audience age gate is the design. Decided, no action.
- **TestFlight:** internal testers only (no Beta App Review wait). If the owner wants an external group, Beta App Review adds a day; recommend internal only for this release.
- **In-app events and promotional text:** not needed for 1.0; promotional text (170 chars) is worth filling since it can change without a build. Skip in-app events.
- **Listing text not drafted:** subtitle, keywords, promotional text, copyright line, category (Games > Word, secondary Education or Family), pricing and availability territories, version 1.0 build 1 (set in pbxproj, fine).
- **App name availability** (D7) not confirmed in STATUS; the owner confirms the record exists under "WordFlora".
- **Offer codes need the Paid Apps Agreement Active**; STATUS never records the agreement status. Owner confirms.
- **Widget and Siri on device** remain unverified (STATUS top list); they are in the G6 device checklist but not called out as pass/fail criteria. Add them.
- **Crash safety on a real device** (guideline 2.1): no device crash run is planned beyond the owner's feature checks; add "play 20 minutes, background/foreground, low-power, airplane mode" to the device list.

Assumptions made: builder throughput of about 14 h per calendar day (the plan's own rate; actual G1/G2 pace was faster); AppLovin signup was not yet started; the privacy page is not yet live; the App Store Connect record already exists with the name "WordFlora".

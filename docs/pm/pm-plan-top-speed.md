# Top-speed plan to submit, Sun 2026-11-08 (written 09:30)

Machine after the restart: swap 0, memory 84% free, load settling from 43 (4 min uptime). mDNSShark is complete: no more collisions, the `wf-build.lock` rule stays as a habit only. The old integration hold was killed by the restart with build and unit green on 8ae9760 (1335 run, 1 skip, 0 fail) and no UI chunk finished on the final code (`docs/pm/evidence-pre-restart/`).

## Decisions

**(a) One hold, not two.** Skip the integration branch's separate UI hold. Run ONE combined hold on the final-assembly branch (`agent-aaf3a6cca45679e54`: integration + G4b, plus G5, weekly note, S3 portrait, N6 print removal once the assembly agent lands them). That hold is the G6 regression (Part A of `g6-device-checklist.md`). Reason: every UI chunk would have to rerun on the final tip anyway; the integration tip's unit set is already green and all its code is in the assembly branch.

**(b) Two simulators in parallel: yes.** One `build-for-testing` into one derivedData, then two `test-without-building` runs with different `-destination id` (WF A `980B7746` and WF E `79CB5A6F`, both iPhone 17) and disjoint `-only-testing` sets. Not three. Guard before start and between chunks: swap < 3.6 GB, free memory > 15%, 1-minute load < 15 on two readings; if a guard fails, lane B pauses until it holds. Timing or audit reds under two-sim load are rerun alone on one sim before anyone touches code. Release proof build runs alone after both lanes finish (CPU spike would fake reds).

**(c) Chunks, order, times.** Per earlier evidence: about 25-30 s per UI test calm (eng 20 tests = 8 min; p2 54 tests = 30 min). 317 UI tests across 18 classes.

| Step | What | Time |
|---|---|---|
| 0 | Assembly agent finishes merges (G5 5 commits, weekly note 7 commits, S3, N6), `git status` clean, tip hash recorded | until ~10:15 |
| 1 | `build-for-testing` on the tip | 4 min |
| 2 | Full unit suite (1335+, one sim) | 3 min |
| 3A | Lane A (WF A): WordFloraUITests 60, TendingUITests 30, GuideUITests 26, EngagementUITests 23, RestCard+Celebration+HomeLayout 25, DailyQuest+Badges+BadgeMechanics 18 | ~100 min |
| 3B | Lane B (WF E): AdFormatsG4bUITests 27, AdFormatsUITests 18, WeatherUITests 26, EndgameUITests 15, TextFitScreensUITests 14, ButterflyNetUITests 13, SeasonsUITests 12, SpeedBloomUITests 10, then the dark chunk (`xcrun simctl ui 79CB5A6F appearance dark`, the dark audits only) | ~105 min |
| 4 | Rerun reds alone, one sim, calm | 20 min |
| 5 | Release proof: simulator Release build `CODE_SIGNING_ALLOWED=NO`; `tools/ads/check-ad-ids.sh` and `check-ad-ids-test.sh`; bundle scan counts only; `git diff <G3 deploy commit> -- WordFlora/Models` empty | 10 min |

Reds route to the class owner, fix in their worktree, cherry-pick onto the assembly tip, rerun only that class: polish2/snow/win card `a0f8716ff1989be39`; engagement, weekly, EngagementUITests `aabade169b9af62f9`; widgets `aca9586a97830ae9b`; AdFormatsUITests and ad policy `a3e7063b293c680a0`; AdFormatsG4bUITests, return ad, Shed card `aa8a8cbc90a62b13c`; G5 art and asset split `ad56e62443b14b215`; weekly note view `a61574287675c55ff`. Known open judgment: the 3 SpeedBloom Dynamic Type audits (key caps, no fix): the lead rules "by design, mark as expected in the audit" before the hold starts so they do not count as reds. S4-S9 fixes are already in 8ae9760.

**(d) After green.** Merge assembly into `3-feat-content-and-polish` (fast-forward or one merge commit), rerun the unit suite on the merged tip (3 min), update `live-status.md`, `STATUS.md`, `cloudkit-new-fields.md`, owner steps D6b/D8 (the S1/S2 wording), tag `v1.0-rc1`, hand the owner the hash. Retire worktree `a3e7063b` and the integration worktree.

## Clock (today)

- 09:30-10:15 assembly merges land; lead rules on SpeedBloom DT; owner starts CloudKit Development run now (Models are byte-identical across branches, no need to wait).
- 10:15-10:25 build + unit. 10:25-12:10 both UI lanes. 12:10-12:30 red reruns. 12:30-12:40 Release proof.
- 12:40-14:00 fixes if any (one round), class reruns.
- 14:00-14:30 merge into 3-feat, unit, docs, tag.
- Owner, from 14:30: CloudKit Production deploy (~30 min), archive from the main checkout with `Config/Ads.local.xcconfig` (~30 min incl. Validate and Upload), art look at `http://127.0.0.1:8765/index.html` (~20 min), device checks Part C (3-4 h, can split across tonight and Monday). App Store Connect attach build + Submit when Part C has no blocker: tonight ~20:00 at best, otherwise Mon 11-09. Thu 11-19 target now has 10 days of slack.

## Single most likely schedule risk

Audit reds that need a ruling rather than a fix (contrast at AX sizes, Dynamic Type on key caps) on the Engagement, SpeedBloom and weekly note screens: each one costs a builder round plus a class rerun, serially. Mitigation: rule on the known three before the hold; any new audit red is rerun alone first, and only a reproducing one goes to a builder.

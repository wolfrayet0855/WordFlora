# Expedite plan, Sun 2026-11-08 15:20

State read at 15:15: hold tip e3450fa (runner `agent-ad2c0f0e0aef65236`), light6 29 pass / 1 red (`TextFitScreensUITests.testTheGrownUpSheetKeepsContinueAndCancelReachable`, 114 s), dark6 running (6 or 7 tests, about 6 min like dark5), load 3.8, one simulator, lock held by the runner. Rehearsal worktree `agent-a88f9cbb761df3f4c` is clean at 56de6f6 but merged 0c4fb06; the hold has 19 commits past that. Main checkout is at 1da6e01 with `Config/Ads.local.xcconfig` present; the hold worktree has no local file. Art server answers 200.

## 1. Cuts that cost nothing

1. **One Release proof, not two.** App code on the merged tip is byte-identical to the hold tip (`git diff <hold tip> 3-feat-content-and-polish -- . ':!docs'` empty is already a recipe check). So: the runner does only the FAIL case (Release build in its worktree, which has no local xcconfig, must stop at "Check ad ids") plus the lock-free self-test `sh tools/ads/check-ad-ids-test.sh`; the PASS case and the binary string scan (`strings` on the built app, no `3940256099942544`) run once, from the main checkout, after the merge. Saves one Release build (about 5 min) on the critical path and never copies the secret file into a worktree.
2. **Merge pre-staged** (delegation A below): resolved files sit on `merge-rehearsal-g6`, so the real merge is `git merge --no-commit` + `git checkout merge-rehearsal-g6 -- <4 docs>` + commit: 2 min instead of 15.
3. **Final docs pre-written** (delegation B): STATUS G6 section, live-status rewrite, 16:00 check-in, cleanup list, with `[fill]` marks for the final counts. Post-green is one edit and one commit.
4. **No UI rerun on the merged tip** (already decided); unit only.

## 2. Ordering and parallelism

Release builds are plain `xcodebuild build` (no simulator) but they load the CPU, and every red this weekend under load was timing. Rule: nothing else compiles on the Mac until dark6 reports. After that, builds may overlap each other (unit and Release are not timing-sensitive in the same way; if the unit run shows a single red, rerun that class alone).

Best order once dark6 is green:
1. Runner: evidence commit (`logs2`, `rb2`, `shots/g6`), freeze the tip, say the SHA, release the lock. Then its FAIL-case Release build (worktree, no lock needed).
2. Lead: fast-apply the pre-staged merge into 3-feat (2 min), run the recipe checks.
3. Main checkout: unit on the merged tip (build + 3 min).
4. Main checkout: Release proof PASS + string scan (5 min), overlapping the runner's FAIL build.
5. Docs commit (pre-written), `git tag v1.0-rc1`.

If light6's red is not covered by e3450fa (check `build6.log` for that SHA): one fix round, rebuild, rerun the one test light + dark (about 35 min); everything else above still pre-stages meanwhile.

## 3. Owner: now, versus after dark6, versus after the tag

Now, no Mac needed (browser, phone, reading):
- Art look: `http://127.0.0.1:8765/index.html` (server is up).
- Scheme edit decision: the uncommitted change to `WordFlora.xcscheme` adds a Run-action environment variable `Development` = "" (enabled) and moves the StoreKit configuration reference. Env vars never reach an archive, so it is harmless to the build but it is a debugging leftover; recommended: `git checkout -- WordFlora.xcodeproj/xcshareddata/xcschemes/WordFlora.xcscheme` before the archive so the main checkout is clean. Keep it only if you set it on purpose.
- CloudKit console part 1 (read-only check of Development and Production, `docs/setup/cloudkit-deploy-straight-to-prod.md` 1b).
- App Store Connect: privacy label ticks (Developer Advertising, App Functionality), review notes and listing text from `docs/setup/store-listing.md`, screenshot captions from `docs/setup/screenshot-plan.md` typed into the editor (the images come later).
- AdMob: publish the GDPR and US state messages; put app-ads.txt live; check it resolves.
- Offer codes: decide GARDENFRIEND / WELCOMEBACK yes or no (optional; 1.1 if unsure).
- Read `docs/pm/owner-final-checklist.md` (on `merge-rehearsal-g6` until the merge).

After dark6 reports (about 15:25), on a real device, not the simulator:
- CloudKit Development run: Debug build from the MAIN checkout to a plugged-in iPhone (Xcode compiles on the Mac but uses no simulator; the model files on 3-feat already carry `lastMistedAt`, so the merge is not needed for this). Sign into iCloud, buy Plus in the sandbox, play, Mist once. Then Deploy Development to Production and fill the ledger in `docs/setup/cloudkit-new-fields.md`.
- Part C of `docs/pm/g6-device-checklist.md` can start on the same device while the Mac merges and tags (plus the review's SE AX5 parental-gate check).

After the tag only:
- Archive from the main checkout (local xcconfig present; the Release proof must have passed) and upload.
- Screenshot captures (`FidelityScreensUITests`, simulator, about 10 min) once the simulator is free; then upload with the captions already typed.
- Submit.

## 4. Target timeline (dark6 green, light6 red covered)

| Time | Mac (runner / lead) | Owner |
|---|---|---|
| 15:20 | dark6 reports | art look, scheme decision, ASC text and label ticks, AdMob messages |
| 15:25 | runner: evidence commit, tip frozen, lock released; FAIL-case Release build starts | plug in device; Development run from the main checkout |
| 15:28 | lead: pre-staged merge applied, recipe checks | |
| 15:32 | main checkout: unit on merged tip | Development run: buy Plus, play, Mist |
| 15:40 | main checkout: Release PASS + string scan | Deploy to Production, ledger row |
| 15:47 | docs commit, `v1.0-rc1` tagged | Part C device checks start |
| 15:50 | post-tag: screenshot captures on the freed simulator | archive from the main checkout, upload |
| 16:05 | captures done, cleanup list (worktrees after the tag) | build processing; screenshots upload by 16:30 |
| 16:45 | | Part C done |
| 17:00 | | submission-ready (17:30 if one rerun) |

Slip: an extra fix round moves every Mac row by 35 min (tag 16:25, submission-ready 17:35). The owner rows do not move except the archive.

## 5. Delegations (two, both lock-free, no simulator)

### A. Merge pre-stager (worktree `agent-a88f9cbb761df3f4c`, branch `merge-rehearsal-g6`)

```
Redo the G6 merge rehearsal at the CURRENT hold tip so the real merge is a 2-minute apply. No builds, no simulator, no xcodebuild test. Work only in /Users/computer/Desktop/workspace/WordFlora/.claude/worktrees/agent-a88f9cbb761df3f4c (branch merge-rehearsal-g6, clean at 56de6f6). Steps:
1. Save the two already-written docs: git show 56de6f6:docs/pm/merge-recipe.md and 56de6f6:docs/pm/owner-final-checklist.md to the scratchpad.
2. git reset --hard 3-feat-content-and-polish (1da6e01). HOLD=$(git -C ../agent-ad2c0f0e0aef65236 rev-parse HEAD); echo it.
3. git merge --no-ff --no-commit $HOLD. Expect conflicts only in docs/pm/backlog.md and docs/setup/owner-setup-steps.md. Resolve exactly as docs/pm/merge-recipe.md says (backlog: keep both sides, drop the three marker lines; owner-setup-steps: --theirs then re-apply the five 3-feat wording points by hand). Any other conflict: stop and report.
4. Restore the two saved docs into docs/pm/, update merge-recipe.md's first line with the new hold SHA. git add, commit "Merge G6 hold branch at <sha> (rehearsal 2); merge recipe and owner final checklist".
5. Checks, paste the output: plutil -lint WordFlora.xcodeproj/project.pbxproj; git grep -nE '^(<<<<<<<|>>>>>>>) ' is empty; git diff $HOLD HEAD -- . ':!docs' is empty; git diff 3-feat-content-and-polish -- WordFlora/Models is empty; grep -c 'TARGETED_DEVICE_FAMILY = 1' WordFlora.xcodeproj/project.pbxproj is 4; git log --format=%B 3-feat-content-and-polish..HEAD | grep -icE "claude|anthropic|co-authored|opus|sonnet|session|fable" is 0.
6. Report the merge SHA and this fast-apply recipe for the lead (fill the SHAs): in the main checkout, git merge --no-ff --no-commit <frozen hold tip>; git checkout merge-rehearsal-g6 -- docs/pm/backlog.md docs/setup/owner-setup-steps.md docs/pm/merge-recipe.md docs/pm/owner-final-checklist.md; git commit. If the frozen tip differs from $HOLD by docs-only evidence commits, say so (the recipe still holds); if app code changed, redo steps 2 to 5.
Commit messages: plain, no mention of Claude, Anthropic, AI, model names, co-authored or session. Tell the docs pre-writer (delegation B) when the merge commit exists.
```

### B. Docs pre-writer (same worktree, after A's commit)

```
Pre-write the post-green docs so the tag needs only one edit and one commit. No builds, no simulator. Work in /Users/computer/Desktop/workspace/WordFlora/.claude/worktrees/agent-a88f9cbb761df3f4c on branch merge-rehearsal-g6, on top of the merge commit from the merge pre-stager (draft in the scratchpad until it says the commit exists). Read docs/pm/pm-checkin-2026-11-08-14.md, docs/pm/expedite-plan.md, docs/pm/g6-fixes-review.md, docs/pm/live-status.md, the tail of docs/STATUS.md, and the runner logs in /private/tmp/claude-501/-Users-computer-Desktop-workspace-WordFlora/4a7b4bed-9e4b-4277-b17d-f2a3956c6a07/scratchpad/g6/progress2.log and logs2/. Write:
1. docs/STATUS.md: a final section "Gate G6: regression, hold, merge and v1.0-rc1 (2026-11-08)" in the file's existing voice: what ran (unit 1393, light and dark lanes, the six fix rounds and what each fixed, the Release proof fail and pass cases, the string scan), the evidence paths (docs/pm/evidence-g6/phase1 and phase2, shots/g6), the review verdict and its two should-fix items, and what is still device-only. Mark unknown numbers [fill: dark6 result] etc.
2. docs/pm/live-status.md: rewrite for the post-merge state: gates table all Merged, G6 "tagged v1.0-rc1 [fill sha]", owner items open (CloudKit run and deploy, scheme decision, archive, screenshots, Part C, offer codes, submit), owner items done unchanged, cleanup list from the 14:15 check-in section 4, risks.
3. docs/pm/pm-checkin-2026-11-08-16.md: the 16:00 check-in in the 14:15 format (status, workload, merge, cleanup, risks, owner), with [fill] marks.
4. Add the device-review item (iPhone SE, AX5, parental gate with the number pad up) to Part C of docs/pm/g6-device-checklist.md if it is not there yet.
Commit "Docs: G6 final status, live status and 16:00 check-in (pre-written, [fill] marks)" with a plain message, no mention of Claude, Anthropic, AI, model names, co-authored or session. Report the list of [fill] marks so the lead can close them in one pass.
```

Not delegated now (needs the simulator, after the tag): screenshot captures per `docs/setup/screenshot-plan.md`; worktree and branch cleanup per the 14:15 check-in section 4.

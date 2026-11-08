# Post-restart runbook (lead)

Use after the owner restarts the Mac. A restart kills every agent, session, background job and cron job, and `/private/tmp` may be wiped (scratchpad, lock directory, derived data, logs). Committed work in git and the worktrees under `.claude/worktrees` survives; anything uncommitted in a worktree survives on disk but verify it.

## 1. Re-open and read state

1. Open the repo `/Users/computer/Desktop/workspace/WordFlora` in VS Code, start Claude Code (new session).
2. Read `docs/pm/live-status.md` (gates, who was running what, open owner decisions), then the latest `docs/pm/pm-checkin-*.md`.
3. `git status` and `git log --oneline -10` in the main checkout. For each worktree: `git worktree list`, then `git -C <worktree> status --short` and `git -C <worktree> log --oneline -5`. Uncommitted builder work: commit it on that branch (plain message) before relaunching the builder, or tell the builder to resume from it.
4. Every agent that was "running" in live-status is dead. Mark them so in live-status and relaunch (section 6).

## 2. Machine state

```sh
# stale build lock (only if no xcodebuild is running)
pgrep -fl xcodebuild || rmdir /private/tmp/claude-501/wf-build.lock 2>/dev/null
# recreate the scratchpad dirs (the session prints its own scratchpad path; use that one)
mkdir -p /private/tmp/claude-501 "<scratchpad dir from the new session>"
# mediaanalysisd must not run, and must still be disabled
pgrep -fl mediaanalysis
launchctl print-disabled user/$(id -u) | grep mediaanalysis      # expect: "com.apple.mediaanalysisd" => disabled
# simulators
xcrun simctl list devices | grep -E "Booted|Shutdown" | head -30
uptime                                                            # load average (1 min) should be < 15
```

- If `pgrep` shows mediaanalysisd running or `print-disabled` does not list it as disabled: do not fix it yourself silently. Ask the owner (standing rule: it stays disabled on the Mac and the simulators).
- Boot exactly one builder simulator: `xcrun simctl boot <udid>` then `tools/dev/sim-reset.sh <udid>` for a clean one (it also disables mediaanalysisd inside the simulator). One simulator for builds and tests; the lock serialises them.
- Wait until the load average is under 15 before starting builds. Check for orphans: `ps aux | grep -E "xcodebuild|sleep 2700|simctl" | grep -v grep`; kill orphaned `sleep` watchdogs and stale xcodebuild.
- Derived data lived in the scratchpad and is gone; the first build is a full build (about 10 to 15 minutes on one lock). Plan for it.

## 3. Dev scripts (committed in `tools/dev/`)

Scripts that lived only in the old scratchpad (`g3-xb.sh`, `g2-simreset.sh`, `killmine.sh`, `xt.sh`, ...) are gone after a wipe. The useful ones are in the repo:

| Script | Use |
|---|---|
| `tools/dev/xb.sh` | `SIM=<udid> WT=<worktree> tools/dev/xb.sh build` or `test -only-testing:...`. Takes `/private/tmp/claude-501/wf-build.lock` with `mkdir` (waits in 20 s steps), starts a 45 minute watchdog, and its trap releases the lock and kills the watchdog and its sleep (`pkill -P $WD; kill $WD`). Prints only errors, failures and the summary; the full log is `$LOG`. |
| `tools/dev/sim-reset.sh` | Erase, boot, disable mediaanalysisd inside a simulator. Between UI batches only. |
| `tools/dev/kill-mediaanalysis.sh` | Keep a simulator's mediaanalysisd dead during a long UI run. |

Builders are told to use `xb.sh` and never call `xcodebuild` bare. Writing code in a worktree needs no lock; only builds and tests take it.

## 4. Re-create the two cron jobs

Both die with the session. Create them again with the scheduling tool (cron expressions in local time). The wording below is the brief each run gets; paste it as the prompt. (The exact prompts from the last session were not saved in `live-status.md`; these are rewritten from their purpose.)

### 4a. Hourly cleanup (alternate Opus and Sonnet each run)

Cron `7 * * * *`. Alternate the model every run (Opus on odd hours, Sonnet on even). Prompt:

> You are the cleanup agent for the WordFlora repo `/Users/computer/Desktop/workspace/WordFlora`. Do not edit Swift or docs and do not build. Do: (1) list running `xcodebuild`, `sleep 27*` watchdogs, `simctl` and `mediaanalysisd` processes and kill only orphans (a watchdog or xcodebuild whose parent session is dead, or one older than 45 minutes with no log growth); never kill a build that holds `/private/tmp/claude-501/wf-build.lock` and is still writing its log; (2) if the lock directory is older than 60 minutes and no xcodebuild is running, `rmdir` it; (3) delete derived-data and `.xcresult` folders in the scratchpad that are not used by a running build and are older than 3 hours, report GB freed (`df -h /System/Volumes/Data` before and after); (4) confirm `pgrep -fl mediaanalysis` is empty and `launchctl print-disabled user/$(id -u) | grep mediaanalysis` still shows disabled; report, never re-enable; (5) report the 1 minute load average and the number of booted simulators (more than one is a finding). Never touch `.claude/worktrees`, git state, or files outside `/private/tmp/claude-501` and the scratchpad. Reply with five short lines, one per step.

### 4b. Fable PM check every 2 hours

Cron `3 */2 * * *`. Fable (PM). Prompt:

> You are the PM reviewer for WordFlora. Docs-only: no builds, no simulator, no Swift edits. Read `docs/pm/live-status.md`, `git log --oneline -30` on the main checkout and on each worktree branch, the newest `docs/pm/pm-checkin-*.md`, and `docs/pm/release-plan-extended.md` gates. Judge: is each gate on schedule against its date (G5 target Mon 11-16, release target Thu 11-19, slip allowed to Mon 11-23); are any agents idle, stuck or duplicating; is scope frozen (only bugs after AdMob formats; ideas to the 1.1 backlog); are the standing rules kept (no attribution in commits, mediaanalysisd disabled, nothing written outside the repo, no real AdMob ids in any file, kids safety). Write `docs/pm/pm-checkin-YYYY-MM-DD-HH.md` (what changed, risks ranked, decisions needed from owner, next two hours' orders for the lead) and commit it with the message "Docs: PM check-in YYYY-MM-DD HH:00". Plain commit message, no mention of tools or models.

## 5. Check the repo rules before any merge

`git log --format=%B 6ae9bb3..HEAD | grep -icE "claude|anthropic|co-authored|opus|sonnet|session|fable"` must print 0. Real AdMob ids must not appear in any tracked file (`Config/Ads.local.xcconfig` is git-ignored; copy it into a worktree for Release builds, never commit it).

## 6. Launch order for builders

Current queue (gate order from `live-status.md`): G3 merge, text-fit pass, then A/B/C, G4a, G5, G4b, G6. Conflicts and merge order: `docs/pm/parallel-lanes-conflict-map.md`.

1. **G3 builder** (worktree `agent-a7c7b6a837f5b8b64`): finish what live-status lists (tool bar fix, Appearance, mist hiss), run the regression through `xb.sh`, hand back, merge. Nothing else builds until this merges (one lock, and everyone rebases on it).
2. **Text-fit builder** (`docs/pm/textfit-builder-brief.md`): starts the moment G3 merges, in a new worktree off the merged branch.
3. **Writers in parallel while text-fit builds** (code only, tests queue behind the lock): Task C (1 h), Task B, Task A, G4a. Start them in their own worktrees as soon as text-fit has pushed its first commits touching shared files, or accept rebase work (see the conflict map).
4. **Art and audio lanes** need no lock; relaunch them first if they were interrupted (G5 asset conversion: `docs/pm/g5-asset-readiness.md`).
5. Re-create the cron jobs (section 4) once the first builder is running.
6. Update `docs/pm/live-status.md` with a "restarted at HH:MM" line and the new agent table.

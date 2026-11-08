# Merge recipe: G6 hold branch (tip e3450fa) into 3-feat-content-and-polish (ff82604)

Rehearsed on branch merge-rehearsal-g6 (merge commit on top of 3-feat-content-and-polish). Only two files conflict, both docs.

```
git checkout 3-feat-content-and-polish
git merge --no-commit --no-ff worktree-agent-ad2c0f0e0aef65236
# conflicts: docs/pm/backlog.md, docs/setup/owner-setup-steps.md
```

1. docs/pm/backlog.md: keep both sides. Delete the three marker lines (<<<<<<< HEAD, =======, >>>>>>> ...); the "1.1 ideas collected" list and the "Plus (owner, 2026-11-08)" section both stay.
2. docs/setup/owner-setup-steps.md: `git checkout --theirs docs/setup/owner-setup-steps.md` (hold branch version), then re-apply the 3-feat wording from ad25bd4 (a plain `git show ad25bd4 -- docs/setup/owner-setup-steps.md | patch -p1` fails on 3 of 6 hunks, so edit by hand):
   - "18 or older: ads (see below)" (not "ads for grown-ups").
   - HOW TO REACH: Settings holds "Comfort (Calm mode, Quiet Garden, Sound), Garden weather, Reminders, Show everything, Purchases, backup and restore ..., Privacy and ads, and About. Appearance follows the system (no picker)."
   - PLUS section: Settings > Purchases description (Plus row, Seasons, Restore purchases never gated, Manage subscription, iCloud row, Family Sharing note); Plus page has only Redeem a code and Terms of Use; under 13 and unknown age gate; paths say Settings > Purchases, not "For grown-ups" or "Settings > Plus".
   - ADS: "begin from the second launch (never the first)", "never on the first launch", "one launch ... ad-free first launch is by design", "open the app a second time".
   - A15 (pack_frost_lantern): add the line "The App Store Connect description of pack_frost_lantern is the owner's choice; the app never displays it."
   - Already present on the hold side, keep: "9 ad units" and "No TestFlight pass is planned: the sandbox is used against the production build".
3. docs/setup/store-listing.md (line 64) merges cleanly (hold branch does not touch it); no action.
4. `git add docs/pm/backlog.md docs/setup/owner-setup-steps.md` and commit with a plain message.

Checks after resolving: `plutil -lint WordFlora.xcodeproj/project.pbxproj`; `git grep -nE '^(<<<<<<<|>>>>>>>) '` empty; `git diff 3-feat-content-and-polish -- WordFlora/Models` empty; TARGETED_DEVICE_FAMILY = 1 appears 4 times; iPhone orientation portrait only; `git log --format=%B 3-feat-content-and-polish..HEAD | grep -icE "claude|anthropic|co-authored|opus|sonnet|session|fable"` prints 0; only Google test ad ids (3940256099942544) and the placeholder ids in AdUnitIDTests.

## Fast apply (2 minutes), from rehearsal 2 on branch merge-rehearsal-g6

Rehearsed at hold tip e3450fa on 3-feat tip ff82604. In the main checkout, on 3-feat-content-and-polish (do not git add -A; the owner's scheme edit and docs/pm/evidence-pre-restart/ stay untouched):

```
git merge --no-ff --no-commit <frozen hold tip>
git checkout merge-rehearsal-g6 -- docs/pm/backlog.md docs/setup/owner-setup-steps.md docs/pm/merge-recipe.md docs/pm/owner-final-checklist.md
git commit -m "Merge G6 hold branch"
git diff <frozen hold tip> HEAD -- . ':!docs'   # must be empty
```

If the frozen tip differs from e3450fa only by docs commits, the recipe still holds. If app code changed, redo the manual resolution above.

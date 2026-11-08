# G6 app-code fixes: review

Read-only review of the app-code commits added during the G6 regression on the hold branch
(`.claude/worktrees/agent-ad2c0f0e0aef65236`, tip `c407651`), against the final-assembly base
`worktree-agent-aaf3a6cca45679e54`. Diff: `git diff worktree-agent-aaf3a6cca45679e54...HEAD -- . ':!WordFloraUITests' ':!WordFloraTests'`.
No build or simulator run; findings come from reading the code.

Files touched: GardenBannerSlot, NativeAdCardView, FrostLantern (pack line), FieldNotesPage, FrostLanternViews,
GameView (Rest card), HomeView (banner caption), PlusView (benefits, title, parental gate), RootView (cue hiding),
WakeSheet, PlantThinning.json, WordFlora.storekit, tools/split_layered_svg.py.

## Verdict

**Ready to merge** once the merge rehearsal is redone at the final tip (Should fix 1). No blockers found.

## Blocker

None.

## Should fix

1. **The merge rehearsal is stale, and the merge is not a fast-forward.** `merge-rehearsal-g6` (56de6f6) merged the
   hold branch at `0c4fb06`. Since then the branch has picked up 950fa9d, 20ed981 (gate), 8c52d9d (Shed), 707bb8f
   (cue), f6dbf90, d1d8cd0 and 2c16016. `git diff HEAD merge-rehearsal-g6 -- WordFlora` shows 5 files that differ.
   `3-feat-content-and-polish` also has about 10 docs-only commits that are not on the hold branch, so
   `merge-base --is-ancestor` fails and a fast-forward is not possible. 3-feat has no commits under `WordFlora/`, so the
   app code merges cleanly; only the known docs conflicts are left.
   Smallest fix: redo the rehearsal at the frozen tip with `git merge --no-ff`, settle the docs the same way as before,
   then check that `git diff <tip> <merge> -- WordFlora` is empty.
2. **Parental gate pinned footer on iPhone SE at AX5 with the number pad up: check it on a device.**
   `WordFlora/Views/PlusView.swift:388-402`. Rough sum: 627 pt sheet - 216 pt pad - about 175 pt footer leaves about
   235 pt to scroll in. The answer field (about 70 pt) fits, and the VoiceOver order is still title, prompt, question,
   answer, Continue, Cancel. Cancel is always in view. The code is sound; this is a check, not a code change. Add the
   case to the device list.

## Nice

1. `WordFlora/Ads/NativeAdCardView.swift:13-14`: the zero-height VStack is never an accessibility element (Color.clear
   is hidden and nothing else is inside), so the age policy holds. Under 13, unknown age and Plus still render nothing:
   `onShedAppear` returns `.ageOrPlus` first (`Rules/AdFormatRules.swift:167`). But in ShedView's `VStack(spacing: 12)`
   (`Views/ShedView.swift:39`), the empty child still adds 12 pt of space above the bottom padding.
   Fix: `.padding(.top, -12)` on the outer VStack, or go back to `Group` and move the `.task` to ShedView.
2. `PlusView.swift:398`: the footer uses `Color(UIColor.systemBackground)`. It matches the opaque large-detent sheet,
   including the elevated dark colour. If the iOS 26 sheet material changes, a sheet-matching background would be
   safer. No action needed now.
3. `PlusView.swift:377`: at AX sizes, after a wrong answer from the pinned Continue, the "wrong" line can sit out of view.
   Fix: post an `AccessibilityNotification.Announcement` when `wrong` turns true.

## Checked and fine

- Return cue (`RootView.swift:13,45`): the hiding goes on the Group/HomeView, under `.overlay { AppOpenCueHost() }`,
  so the cue itself stays reachable and Skip is never hidden.
- 44 pt caption targets (`tapTarget()`, `Theme.swift:40`): Garden and Home slots are `safeAreaInset`s, so the taller
  row pushes content up and never covers it. Ads are 13+ only, so the ungated "Report an ad" link is fine.
- Winter scene: decorative and hidden. `sceneLabel` exists (`Rules/FrostLantern.swift:107`), and no test refers to the
  removed `winter.scene` / `shed.nativeCard` ids. SnowfallView still pauses off screen (`visible`) and when the scene
  is not active.
- No new `lineLimit`, `ViewThatFits` or `minimumScaleFactor`. The `fixedSize(vertical)` additions (Wake tiles, Rest
  card, gate Continue) sit in containers with no fixed height.
- Onboarding, the age question, puzzle, Calm and Quiet Garden ad gating: not touched.
- Commit messages: no attribution strings (count 0).

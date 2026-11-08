# Live status

Rewritten for the post-merge state (pre-written 2026-11-08; close the [fill] marks after the tag). Detail: `docs/STATUS.md` (Gate G6 section), `docs/pm/pm-checkin-2026-11-08-16.md`.

## Gates
| Gate | State |
|---|---|
| G0-G2b, art lane | Merged |
| G3 pack + Mist Maker | Merged (634f447). Stored field `PlantCollectible.lastMistedAt`. |
| Text-fit pass, Plus flow, Settings Purchases, one Restore | Merged (c97d4a4) |
| Integration (polish 2, engagement, widgets, G4a ads) | Merged |
| G4b ad formats | Merged |
| G5 Frost & Lantern pack | Merged |
| G6 regression, review, merge | Merged as c04329c; tagged v1.0-rc1 at [fill: sha] |

Unit 1393 passed, 0 failed, 1 skipped on the hold tip 5588896 (merged-tip unit: done 2026-11-08: unit on merged tip c04329c 1393 passed, 0 failed, 1 skipped; Release PASS case passed (nine unit keys and app id real, Garden equals Home, no Google test id); Release binary string scan 0 for fake-ad, adcaps, collapsible probe and test ids; 12 -uitest launch-argument names remain in Release (harmless, moved to backlog)); Release proof FAIL case verified, PASS case done 2026-11-08: unit on merged tip c04329c 1393 passed, 0 failed, 1 skipped; Release PASS case passed (nine unit keys and app id real, Garden equals Home, no Google test id); Release binary string scan 0 for fake-ad, adcaps, collapsible probe and test ids; 12 -uitest launch-argument names remain in Release (harmless, moved to backlog); the review found no blockers.

## Owner items open (order and steps: `docs/pm/owner-final-checklist.md`)
1. CloudKit Development schema run, then Production deploy; verify CD_lastMistedAt; fill the ledger in `docs/setup/cloudkit-new-fields.md`.
2. Art look at http://127.0.0.1:8765/index.html.
3. Decide the stray xcscheme edit (keep or revert) before archive.
4. Archive from the main checkout with Config/Ads.local.xcconfig; screenshots (`docs/setup/screenshot-plan.md`); privacy label; AdMob messages; app-ads.txt.
5. Part C device checks (`docs/pm/g6-device-checklist.md`), including the SE AX5 grown-up sheet.
6. Offer codes GARDENFRIEND and WELCOMEBACK, if still wanted.
7. Submit for review.

## Owner items done
`pack_frost_lantern` ($2.99), `plus_lifetime`, Family Sharing on all products, privacy URL live, Paid Apps Agreement complete, AdMob console checklist, fact check. Do not relist.

## Cleanup (after the tag only)
Worktrees and branches a0f8716, a3e7063b, a61574287, a7c8dfd7, aa8a8cbc, aabade16, aaf3a6cc, aca9586a, ad56e624, then ad2c0f0e and a88f9cbb (rehearsal). Sim C0628F1B shut down; scratchpad `g6/shots-*`, `dd`, `dd2` after evidence is committed.

## Risks
Part C device finds mean a new build and a recheck of items 1 to 6; CloudKit Production deploy must precede the archive; Mon 11-23 is the slip limit; nothing is proven on a device yet (widgets, iCloud, real ads, sounds, StoreKit sandbox). Scope stays frozen: ideas go to `docs/pm/backlog.md` (1.1).

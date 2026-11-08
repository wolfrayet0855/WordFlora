# Live status

Rewritten Sun 2026-11-08 (after the 06:00 check-in, `docs/pm/pm-checkin-2026-11-08-06.md`). Older detail: `docs/STATUS.md`, `docs/pm/pm-checkin-2026-11-08-04.md`.

## Gates
| Gate | State |
|---|---|
| G0-G2b, art lane | Merged |
| G3 pack + Mist Maker | Merged into 3-feat-content-and-polish (634f447). New stored field `PlantCollectible.lastMistedAt`. |
| Text-fit pass, Plus flow, Settings Purchases, one Restore | Merged into 3-feat-content-and-polish (c97d4a4) |
| Integration branch (worktree `.claude/worktrees/agent-a7c8dfd77f34b6d62`) | Holds polish pass 2 (snow, snowdrop, win-card pips, toast tick) + engagement (share gate, name your plant, widget pin, weekly note) + widget fixes + G4a ads (ad ids and Release check, ad policy and caps, rewarded perks, faded bloom offsets) + M5 patches (rest-card hint, plant page R1 water perk). Tip 0040e11. In its combined test hold. |
| G4b ad formats | Builder writing, worktree off 0040e11. No tests until the hold ends. |
| G5 asset split (28 imagesets, PlantThinning.json) | Builder writing, own worktree off 0040e11. pbxproj collides with G4b, so G4b merges first. |
| G6 regression + owner device checks, submit | Queued. Target Thu 11-19, slip allowed to Mon 11-23. |

## Lock and gate rule
- A test hold starts only when the lock `/private/tmp/claude-501/wf-build.lock` is free (taken with `mkdir`), no `xcodebuild test` of any project is running, and the 1-minute load is under 15 on two readings.
- The owner's other project, mDNSShark, runs `xcodebuild test` with clone simulators on this Mac and collides (about 30 runs 01:34-04:52). Standing arrangement proposed: its runner takes `wf-build.lock` around every test run, or it uses the windows WordFlora 05-13 and 19-01 only, with no clone simulators.
- Per the 06:00 check-in mDNSShark stays off until about 09:00; the hold should end about 09:00 (09:40 with one rerun), then merge into 3-feat about 10:30.

## Owner items open
1. CloudKit: Development schema run, then Production deploy, by Tue 11-10 (`docs/setup/cloudkit-deploy-straight-to-prod.md`).
2. Sandbox testers, including an Ask to Buy child account.
3. Offer codes `GARDENFRIEND` and `WELCOMEBACK`.
4. Device checks (list in `docs/pm/g6-device-checklist.md`): widget (Part C), audio, iCloud status row, the N6 appGroup print (run Debug twice).
5. Art look on localhost (all G5 art is in design-preview/frost-lantern) before Fri 11-13 20:00.
6. Decide on the stray uncommitted edit to `WordFlora.xcodeproj/xcshareddata/xcschemes/WordFlora.xcscheme`. It stays untouched until then; never commit it by accident.
7. Answer the mDNSShark lock or windows proposal above.

## Owner items done
`pack_frost_lantern` ($2.99), `plus_lifetime`, Family Sharing on all products, privacy URL live, Paid Apps Agreement complete, AdMob console checklist, fact check (all four facts confirmed). Do not relist.

## Scope admitted since the freeze release
- Appearance follows the system (Settings picker removed).
- Tool bar fit: "Trim", two rows of three, single column at AX sizes.
- Text-fit pass: Visitors, Shed, My Garden, Repot, tool effect line; Visitors review V1-V11 and Plus page review P1-P14.
- Plus flow: one Restore (in Settings), less text, "Plus is on", iCloud status row with "Synced N minutes ago", AVAudioSession fix.
- Mist hiss sound and snip to 0 dB.
- Polish pass 2: falling snow, snowdrop pose, Great Word animation, win-card pips, toast tick.
- Engagement: weekly garden note, name your plant and widget plant pin, age-gate Daily Bloom and Share this plant.
- Widget fixes: water control, voice, inline family, name privacy, midnight refresh.
- G4a ads hardening; resting card hint (R2) and faded bloom offsets.
- Ideas beyond this go to `docs/pm/backlog.md` (1.1).

## Verified vs unverified
Verified (simulator): G3 unit 1185/1185 and Tending UI 28/28 at merge; text-fit and Plus flow merged green; integration build green 06:33, unit 1335 run, 1333 pass, 1 skip, 1 red (AdsServiceWiringTests timing).
Unverified: 0040e11 (the fix for that red came after the build; rerun AdsServiceWiringTests at the merge); the full combined UI set, Release proof build and `tools/ads/check-ad-ids.sh` on the integration tip; the UI sets under load (reds under load are timing, rerun alone). Nothing on a device yet: widget never seen rendered, iCloud sync, real ads, sounds, haptics, StoreKit sandbox.

## Merge order
1. Integration branch into 3-feat-content-and-polish (after the hold is green).
2. G4b (merge integration into G4b daily; it touches AdsService, GardenView banner slot, AppModel+Ads, AdFormatsUITests, pbxproj).
3. G5 (pbxproj conflict with G4b resolved after G4b lands).
4. G6 builder part, then owner archive from the main checkout.
Retire worktree a3e7063b (3e875da duplicates 0040e11).

## Risks
Swap near 1.55-2 GB; reds under load; G5 art gate Fri 11-13 20:00; CloudKit Production deploy by Tue; scene aspect and hellebore colour undecided. Remove the N6 Debug print before Release.

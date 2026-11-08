# Live status (lead updates this at every check-in)

Updated 2026-11-07 19:10.

## Gates
| Gate | State |
|---|---|
| G0–G2b, art lane | Merged |
| G3 pack + Mist Maker | Features done (last: 35a19a3, adds `PlantCollectible.lastMistedAt`). 19:15: unit tests 1185/1185 green; UI TendingUITests 28/28; Seasons/BadgeMechanics/ParentalGate/PlusForever group running. Next: tool-bar fix (title "Trim", two rows of three at larger text, layout test, before/after shots). Not merged yet. |
| CloudKit deploy | Owner: check Production for the fields; plan doc coming (`docs/setup/cloudkit-deploy-straight-to-prod.md`). |
| G4a AdMob hardening | Starts when G3 merges. Brief ready: `docs/pm/g4a-builder-brief.md`. |
| G5, G4b, G6, submit | Queued. Target Thu 11-19, slip allowed to Mon 11-23. |

## Agents running
| Agent | Task | Output |
|---|---|---|
| G3 builder | Finish regression, fix six-button tool bar ("Trimmed" wraps), hand back | commits in its worktree |
| Audio review (Sonnet) | Level/clipping/loop check of all sounds, mist hiss advice | `docs/pm/audio-review.md` |
| Tool-bar fit review (Opus) | Width maths, other rows that might wrap | `docs/pm/toolbar-fit-review.md` |
| CloudKit plan (Fable) | Straight-to-prod steps and TestFlight-skip risks | `docs/setup/cloudkit-deploy-straight-to-prod.md` |
| Visitors book review (Opus) | UX/a11y bugs in the Visitors page | `docs/pm/visitors-book-review.md` |
| PM check-in (Fable) | 19:00 review | `docs/pm/pm-checkin-2026-11-07-19.md` |

## Done since 18:00
- Docs helper: G4a brief, faded-bloom offsets, AdMob console one-pager, setup and privacy docs refreshed, winter facts aligned.
- Fact check: all four facts confirmed (`docs/research/frost-lantern-facts-check.md`).
- Cleanup: 15 orphaned timers killed, 1.9 GB freed, `mediaanalysisd` killed on the Mac.

## Owner decisions open
1. Mist hiss: keep the water sound at 35% or make a real hiss (audio review will advise).
2. Eight untracked `tools/out/weather/*.wav` files: ignore, commit or delete.
3. Slow test `testRepotSheetScreensLikeTheMockup` (over 120 s): raise its allowance or have it sped up (lead default: speed up).
4. TestFlight: skip or keep one internal build (Fable recommendation pending).

## Owner tasks
- CloudKit: confirm Production has the fields; deploy after G3 merge if not.
- Done by owner: `pack_frost_lantern` ($2.99) in App Store Connect, `plus_lifetime` with Family Sharing, AdMob console checklist, fact check. Do not relist.
- Also done by owner (2026-11-07): Family Sharing on for all products, privacy URL live, Paid Apps Agreement complete.
- Open: CloudKit Production deploy after G3 merge; sandbox testers; offer codes.

## Scope admitted since freeze release (2026-11-07 evening)
- Appearance follows system (Settings picker removed), in G3 branch.
- Tool bar fit: two rows of three, "Trim", AX single column (G3 branch, per docs/pm/toolbar-fit-review.md).
- Text-fit pass (new, after G3 merge, before G4a): Visitors stickers, Shed pot cards (drop the xxxLarge cap, fewer columns), My Garden cards, Repot sheet, Shed tool effect line. Owner rule: every word fits at every text size.
- Text-fit pass also takes Visitors book review V1-V11 (docs/pm/visitors-book-review.md): V1-V4 word wrapping, V5 "Seen on <date>" copy, V6 rarity chip contrast, V7/V8 VoiceOver, V9-V11 polish.
- Text-fit pass also takes Plus page review P1-P14 (docs/pm/plus-page-review.md, 7ec42ee). Highest: trialEligible must require a free-trial intro offer (EntitlementService.swift:43-45); grown-up question sheet needs ScrollView at AX sizes; 3.1.2 wording for cancel; loading state; contrast 1.75:1 choice circle; "a year"/"a month" prices. Owner check: Family Sharing ON for both subscriptions in App Store Connect, not only Plus Forever. Screenshots needed (SE 375x667 and 393): default and AX5, light and dark, gate sheet, loading/failed, owned states.
- Mist hiss (Fable ruled, 8db9fba): being rendered by an audio agent, wired by G3 builder after tool bar + Appearance; gate Thu 11-12 20:00. wf-snip to 0 dB in the same commit. Engagement research (top two quick wins) in progress. All-pages visual review (Fable) in progress.
- Engagement quick wins approved (lead): A weekly garden note (~7.5 h), B make it yours: plant name + widget plant (~6.5 h), C age-gate Daily Bloom and Share this plant (~1 h). Order: G3 merge, text-fit pass, A/B/C, G4a, G5, G4b, G6. Doc: docs/pm/engagement-quick-wins.md.

## 2026-11-07 ~21:40: G3 MERGED (634f447). New stored field: PlantCollectible.lastMistedAt (commit 35a19a3). Owner: CloudKit Development schema run then Production deploy; Mac restart planned. Worktrees: none left. Next: text-fit pass (docs/pm/textfit-builder-brief.md), then C, B, A (docs/pm/engagement-quick-wins.md), G4a, G5, G4b, G6. After restart follow docs/pm/post-restart-runbook.md (re-create cron jobs: hourly cleanup alternating opus/sonnet; Fable PM every 2 h).

- Queued polish pass 2 (after text-fit merge; owner feedback 2026-11-07 device test): (1) Frost & Lantern snowfall (SnowfallView) and snowdrop pose patch: docs/pm/frost-lantern-snow-and-plant-review.md (3af256e, ~2.3 h); (2) Great Word / 1 of 3 animation and nudge, yay-hello icon contrast, remove hello help from love petals: docs/pm/celebration-and-love-review.md (Fable, pending); (3) Plus flow: one Restore (footer), less text, clear Plus status after purchase, iCloud status row in Settings, no ads on Plus page/purchase, AVAudioSession main-thread warning: docs/pm/plus-flow-fable-review.md (Fable, pending; text-fit builder applies Plus items in one pass). Owner note: Xcode scheme has an uncommitted local edit (EnvironmentVariable Development) in the main checkout: leave it, do not commit or revert.

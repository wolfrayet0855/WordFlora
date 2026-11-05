# Shed, Visitors and Butterfly game: app vs mockup

Mockups: `design-preview/shed-visitors/` (hub `index.html`, `shed.html`, `visitors.html`, `butterfly-game.html`). "App today" frames follow the code on branch `3-feat-content-and-polish`. "Proposed" frames are changes for the owner to judge. Severity: high = a player meets it and it misleads or cannot be read; med = rough or inconsistent; low = polish.

## Shed

| Where | What | Sev |
|---|---|---|
| `Rules/ToolEngine.swift` (no use of `.mister`); `Views/ShedView.swift:11` | The mister does nothing at any tier, yet the Shed sells upgrades for it (30 + 120 points). | high |
| `Views/ButterflyView.swift:61`, `ButterflyView.swift:165` | Net tier changes the intro picture only. The catch radius is fixed at 48 pt. The v4 design (`brand/v4/visitors.html` sect. 5) says 48/64/80 pt by tier. | high |
| `App/AppModel.swift:530`, `Rules/Butterfly.swift:117` | Shed points come from the butterfly game and nowhere else, and the Shed never says so. 3 rewarded plays a day at 2 to 8 points; all upgrades cost 900. | med |
| `Views/ShedView.swift:11-13` | The blurb for mister, shears and lamp is "Finish level N to find it" and stays that way after the tool is found. | med |
| `Views/ShedView.swift:21` vs `:54-58` | Quiet Garden hides the points line but cards still say "Upgrade for 30 points". | med |
| `Views/ShedView.swift:54-59` | Not enough points shows a grey disabled button with no "how far" line; the "Not enough shed points yet." message (`:72`) can never show, as the button is disabled. Proposed: bar plus "14 more to go". | low |
| `Views/ShedView.swift:8-13` | Cards never say what a tier does (can: 1/2/3 plants per tap; trowel x1/1.25/1.5; shears 4/6/8; lamp 2/3/4). Proposed: "Now" and "Tier N" lines. | low |

## Visitors

| Where | What | Sev |
|---|---|---|
| `Views/HomeView.swift:288,299`; `Views/RootView.swift:32` | No Visitors screen: the "Visitors" tile opens the game ("Butterfly game" title); the album is a sheet from there. Proposed: a Visitors page with the album on it. | med |
| `Views/ButterflyView.swift:193-199` | Rarity and the met count are stored but never shown (the count is in the VoiceOver label only). | med |
| `Views/ButterflyView.swift:196` | Not-met stickers use brightness -0.5: dark grey discs, nearly invisible on dark cards. | low |
| `Models/PlayerProfile.swift:33`, `App/AppModel.swift:514` | Glow Lanterns are spent but never given, so the lantern toggle (`ButterflyView.swift:65`) and `Feature.glowLantern` never show. | med |
| `Rules/Butterfly.swift:19-22,26-27` | 7 of 12 visitors have no fact. Proposed card says "A fun fact is on its way." | low |
| `Views/HomeView.swift:327` | Locked Home tiles use `lock.fill`, against the "no lock icons" rule. (HomeView is owned by another worker; flagged, not mocked.) | med |
| `Views/HomeView.swift:294` | The Levels tile is gated by the butterfly feature. Maybe on purpose; worth a check. | low |

## Butterfly game

| Where | What | Sev |
|---|---|---|
| `Views/WakeSheet.swift:243` | Wake count "n of 3 butterflies" uses `Color.ink` (dark in both modes) on `appBackground`: in dark mode it can barely be seen. | high |
| `Views/ButterflyView.swift:6,157` | The main game reads only the system Reduce Motion, not `settings.reduceMotionOverride` (the wake game uses both, `WakeSheet.swift:238`). | med |
| `Views/ButterflyView.swift:123-128` | Summary stickers sit in a plain HStack: 5 or more visitors at 64 pt run past the card. | med |
| `Views/ButterflyView.swift:169-172` | A catch shows a sticker for 0.9 s; the name is spoken to VoiceOver but never shown. Proposed: name pill and "New friend" card on first meet. | med |
| `Views/WakeSheet.swift:276-283` | The wake game has no trail and no catch pop; catches there never reach the album or badges (no `finishButterflyGame`). | low |
| `Rules/WakeChallenge.swift:78` | "n of 3 butterflies", but bees, ladybugs and others count too. Proposed: "friends". | low |
| `Views/WakeSheet.swift:247` | The wake field is always a day sky, even when the evening pool is in use. | low |
| `App/AppSettings.swift:17`; no use in the game | Calm mode does not change the game (35 s bar, same speed). Proposed: no bar and slower drift. | low |
| `Rules/Butterfly.swift:115`; `ButterflyView.swift:120` | `newStickerIds` is the distinct visitors this round, not new to the album, so "You met 3 visitors" counts old friends too. | low |

## Decisions for the owner
1. Mister and net: wire real tier effects (net catch circle 48/64/80 pt; mister effect to be defined) or hide their upgrades for now.
2. Quiet Garden in the Shed: tools level up on their own as the garden grows, or upgrades stay hidden.
3. A real Visitors page (proposed) instead of the game intro.
4. Optional pet names for visitors (plants already have nicknames).
5. How Glow Lanterns are earned, or remove the toggle.
6. Calm mode game: hide the time bar and slow the drift?
7. Should wake-game catches count toward the album?

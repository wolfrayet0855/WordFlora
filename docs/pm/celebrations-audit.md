# Celebrations audit (landing intro + success moments)

Branch `3-feat-content-and-polish`. Phase 1: audit and mockup only. No Swift was changed.
Mockup: `design-preview/celebrate/` (README has the timings). Frame strips: `design-preview/celebrate/shots/`.

## 1. Landing / onboarding intro

**What runs today.** `RootView.swift:10` shows `OnboardingView` until onboarding is complete, so the intro runs once, on first launch. After it comes the age question (`OnboardingFlow.swift:24`), not Home. Returning players go straight to Home and have no landing animation. The intro is `IntroView` (`OnboardingView.swift:32-45`): `WordmarkView(style: .largeTitle)` with the tagline fading in (0.8 s ease-out after 0.5 s, line 43), and `FlowerRainView` on top (line 40). The intro moves on when the rain finishes.

**FlowerRainView (`Components/FlowerRainView.swift`):**
- **Shape.** Each particle is a plain `Path.addEllipse` (line 41). It is not the app's petal art.
- **Palette.** Includes `0xFFFFFF` (line 14), which is invisible on the light background `#FAF7F0`. The rest of the palette matches FlowerView.
- **Motion.** Petals fall from y = -20 straight off the bottom (`y = -20 + local * (size.height + 60)`, line 39) and fade out over the last 15 % (line 46). Nothing lands, piles up or blooms.
- **Depth.** One Canvas drawn above the wordmark. No petal goes behind it.
- **Reduce Motion (lines 29-31).** Shows an SF Symbol `sparkles` over a transparent colour for 0.5 s. That is not the brand art, and the wordmark is hidden underneath it.
- **App setting.** Only the system Reduce Motion flag is read. `AppSettings.reduceMotionOverride` (`AppSettings.swift:16`) is ignored. Only `WakeSheet.swift:238,306` honours it.
- **Good parts to keep.** Deterministic SplitMix64 seed, cap of 120 particles, tap to skip, one `TimelineView(.animation)` + `Canvas`.

**Art that already exists and should be used:**
- **`PetalShape`** (`Components/FlowerView.swift:146-158`). The approved petal bezier in the 200x240 space, hub at (100, 88). The mockup re-bases it to `M0 0 C-19 -12 -17 -44 0 -54 C17 -44 19 -12 0 0 Z`.
- **`FlowerView.Palette`** (`FlowerView.swift:131-141`): rose `#F2788A/#D9566C`, apricot `#E9A36C/#CF8247`, lilac `#C7A9B0/#A98791`, sky `#8EA6C4/#6E87A8`.
- **Flower centre** `#E8A838/#F5C858` (line 111).
- **Stem and leaves:** `#4E9A55`, `#5FA860`, `#3F8A4A` (lines 57-73).
- **Wordmark** (`design-preview/logo/final/wordmark.svg`, asset `Wordmark` via `Theme.swift:26-53`). Both O's are five-petal flowers: Word O in marigold `#E0962A`, Flora O in rose `#E27D8A` (dark mode: `#E25D78`). The Flora O is turned 36°. The new five-petal blossom should match these flowers.
- **`LayeredPlantView`.** Already has the fall and regrow vocabulary (`FallEffect`, lines 274-306). It is plant-specific and not reusable for the intro.

## 2. Success moments

| Moment | Where | Visual now | Haptic now | Sound now | Gap |
|---|---|---|---|---|---|
| Correct letter | `GameViewModel.swift:169`, `Haptics.swift:13` | Tile reveal only (`WordTilesView`) | light impact | `.correct` | No visual reward. Add a **small** petal puff from the revealed tile (10 particles, 1 s). |
| Wrong letter | `GameViewModel.swift:174`, `FlowerView.swift:39-48` | Petal falls off the flower | soft impact | `.wrong` | Fine (and kept gentle). Not a celebration. |
| Word solved / plant earned | `GameView.swift:65-79`, `:244-251` | Dim, then `FlowerRainView` behind the earned card (card at +0.7 s) | `.success`, plus a soft lub-dub at 0.7 s | `.word` (`GameViewModel.swift:346`) **and** `.earned` or `.levelUp` (`GameView.swift:68`) | Ellipse rain, not petals. **Two sounds fire together on a win**, which breaks the "exactly one sound per event" rule in `Sound.swift:5-6`. Replace with **large** petal confetti. |
| Level up | `GameView.swift:68`, `:229` | Same rain + "Level up!" label | same | `.levelUp` (+ `.word`) | Looks the same as a normal win. Add a **medium** burst from the card top, layered over the large one or replacing it. |
| Daily Bloom solved | `GameView.swift:65-79` (`vm.isDaily`), share button `:239-243` | Same rain as any win | same | same | No Daily Bloom identity. Use the **large** burst; the badge counter `.dailyBloomsDone` is recorded at `AppModel.swift:481`. |
| Tutorial first win (onboarding) | `OnboardingView.swift:17-22`, same `GameView` path | Rain only if `!calmMode` (`GameView.swift:69`) | same | same | Under-13 defaults to `calmMode = true` (`AppSettings.swift:54`), so **kids get no celebration at all on their first win**. Calm should mean gentle, not nothing. |
| First garden tip (water) | `OnboardingView.swift:108-113,169` | Pour animation + "Yum!" | soft impact | `.water` | Fine. Could add a 6-petal small puff on "Yum!". Optional. |
| Badge earned (round) | `GameView.swift:262-274`, `AppModel.swift:469-487` | Top toast: SF `rosette` + text, 2 s after the round, gone after 4 s | none | `.badge(tier:)` | No badge art and no motion. Add a **badge moment**: the badge art pops with petals swirling. No haptic. |
| Badge earned (tending / revive / butterfly) | `AppModel.swift:216`, `:496`, `:541-542` | **Nothing.** The `[BadgeUnlock]` result is discarded. | none | none | These unlocks are silent. AppModel needs to publish pending unlocks so any screen can show the badge moment. |
| Streak milestone / Rose drop | `GameViewModel.swift:335`, earned card `GameView.swift:238`; streak badge `AppModel.swift:483` | A text label in the earned card | none | none | Small. Could add a few blossoms around the label. Streak badges go through the round badge toast. |
| Plant grows a stage (tending) | `PlantDetailView.swift:543`, `:256-257` | 1.06 spring bump | soft impact (tend tap) | tend sound | Add a **small** puff at the plant head on `stageUp`. |
| Plant tapped (hello) | `PlantDetailView.swift:254,258`, `TapBurst.swift` | SF hearts and sparkles | soft impact | none | Not a success moment. Leave it, or swap the sparkles for mini blossoms to match. |
| Wake-the-seed success | `WakeSheet.swift:296-365`, `AppModel.swift:189` | Glow behind the plant + love pips return | soft at the first and the last pip | `.wake` | Good. A **medium** burst from behind the plant on appear would make the win clearer. |
| Rose of Jericho revive (in round) | `AppModel.swift:490-499` | Flower regains petals (FlowerView) | none | `.wake` | Revive badge discarded (above). Optional small puff. |
| Butterfly game finished | `ButterflyView.swift:174-178`, `:115-145` | Dim + summary card | **none** | `.earned` | No visual or haptic at the end. Add a **medium** burst behind the summary card, plus a `.success` haptic. |
| Butterfly catch | `ButterflyView.swift:162-171` | Sticker popup spring | none | `.butterfly` | Fine. |

### Accessibility and mode handling (today)

| Setting | Current behaviour | Gap |
|---|---|---|
| System Reduce Motion | `FlowerRainView` shows an SF `sparkles` for 0.5 s. `TapBurst` shrinks to a fade. Most views read `accessibilityReduceMotion`. | Needs a brand-art fade: still petals and blossoms fading in and out, opacity only. |
| `reduceMotionOverride` (in-app) | Only `WakeSheet.swift:238,306` | Every celebration should read `systemReduceMotion \|\| settings.reduceMotionOverride`. Put this in one environment helper. |
| Calm mode | Rain removed entirely (`GameView.swift:69`) | Should be the **calm** variant: about 24 petals drifting slowly from the top, no burst. |
| Quiet Garden | Badges never unlock (`Badges.swift:65`). Numbers hidden. Rain unchanged. | Treat it like Calm: gentle drift, no badge moment (there are no unlocks anyway). |
| Sound off | Round sounds go through `vm.soundEnabled`, others through `AppModel.play` (`AppModel.swift:575-578`) | Fine. Fix the double win sound. |
| Haptics off | `GameHaptics` and the lub-dub check `hapticsOn` | Fine. New hooks must check it too. |
| Low Power | `PlantDetailView.swift:52` treats low power as calm | Celebrations should do the same (drop to the calm variant). |
| Increase Contrast | Wordmark swaps to the mono art (`Theme.swift:48-50`) | The intro must use `WordmarkView` itself, or apply the same swap. |

## Summary of gaps
1. The intro rain is ellipses that fall off-screen. There is no landing, no bloom, no brand petal, a white particle is invisible in light mode, and the Reduce Motion version is an SF Symbol.
2. Correct letters, plant growth, butterfly wins and every non-round badge have no visual celebration.
3. Badge unlocks from tending, revives and the butterfly game are silently dropped.
4. Calm mode (the default for under-13s) removes celebration entirely, including the very first win.
5. A win plays two sounds at once.
6. The in-app Reduce Motion override is honoured in only one screen.

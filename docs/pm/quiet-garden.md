# Quiet Garden: what it hides and what it keeps

Quiet Garden is one switch (`AppSettings.quietGarden`, WordFlora/App/AppSettings.swift:18, stored in the App Group so the
widget reads it too: WordFlora/Shared/SharedDefaults.swift:8). It is offered once, when a player picks "Under 13" on the
age question (WordFlora/Views/OnboardingView.swift), and lives in Settings > Comfort (WordFlora/Views/SettingsView.swift:36).

**Guessing has no timer.** The word game has no clock, countdown or time limit anywhere: a round ends only when the word
is solved or the flower's petals are used up (WordFlora/ViewModels/GameViewModel.swift has no timer at all). The one
timer in GameView (WordFlora/Views/GameView.swift:31) only checks every 30 s whether an under-13 player has played for
20 minutes and should be offered a break card; it never limits a guess.

Picking "Under 13" also turns Calm mode on (WordFlora/App/AppSettings.swift:95), whatever the Quiet Garden answer is.
Calm and Quiet Garden overlap in places; the table says which switch does what.

## What Quiet Garden hides or changes

| Area | With Quiet Garden on | Code |
|---|---|---|
| **Shed points** (currency) | No points bar and no "Play to earn" button; the shed header says "Quiet Garden is on. Your tools are ready to use." over a calmer scene picture | WordFlora/Views/ShedTools.swift:60-79, WordFlora/Views/ShedView.swift:18, WordFlora/Rules/ToolEngine.swift:169, 237-238 |
| **Shed points earned** | The butterfly game gives no water, no shed points and no soil scoops (stickers still count) | WordFlora/App/AppModel.swift:616 |
| **Tool tiers, prices, upgrades** | No tier pips, no "Level 2" line, no upgrade price or "ready to upgrade" state; each owned tool shows one plain line ("Waters your plants") | WordFlora/Views/ShedTools.swift:130, 135, 196, 236, 249-250; WordFlora/Rules/ToolEngine.swift:202-211, 254 |
| **Water drops** (counter) | Watering never uses a drop and never says "no water" | WordFlora/Rules/TendingEngine.swift:52, 56; WordFlora/App/AppModel.swift:218, 287 |
| **Soil** (counter) | Feeding and repotting never use soil and never say "no soil" | WordFlora/Rules/TendingEngine.swift:66, 68; WordFlora/Rules/ToolEngine.swift:145-146; WordFlora/App/AppModel.swift:287, 301 |
| **Tools you have to own** | Shears (prune) and the lamp (sun) work without owning them | WordFlora/Rules/ToolEngine.swift:124, 132; WordFlora/App/AppModel.swift:295 |
| **"+N growth" number** | The tend toast says the plant's line without "+3 growth" | WordFlora/App/AppModel.swift:244 |
| **Widget water count** | The widget's water button says "Water" instead of a number, and waters for free | WordFloraWidget/GardenWidget.swift:113-115, 20; WordFlora/Shared/GardenIntents.swift:20 |
| **Words toward the next plant** (counter) | Home does not show "2 more words to your next plant" | WordFlora/Views/HomeView.swift:117-118 |
| **Badges** (counters, meters) | Badges never advance or unlock, so no badge pop-ups; the badges page shows no progress bar and no "3 of 10" | WordFlora/Rules/Badges.swift:64-67; WordFlora/Views/BadgesView.swift:39-42; WordFlora/App/AppModel.swift:233, 548-558, 569, 582, 633, 689 |
| **Bloom rank** (counter) | The badges page hides the rank chips and "N more blooms to the next rank" | WordFlora/Views/GrandGardenViews.swift:528-535 |
| **Golden days countdown** | Home hides "N days from golden" once every plant is found | WordFlora/Views/GrandGardenViews.swift:454 |
| **Love rain and seeds** (a daily clock) | Plants never lose hearts in the rain and never nap as a seed, so there is no wake challenge (same as Calm) | WordFlora/App/AppModel.swift:160, 185; WordFlora/Rules/LoveEngine.swift:5, 12; WordFlora/Views/PlantDetailView.swift:69 |
| **Garden weather** (forecasts, day countdowns) | No forecast chip, card or banner, no weather art on plants, no Wild Weather | WordFlora/Rules/Weather.swift:272-274; WordFlora/Rules/GardenWeather.swift:8, 51; WordFlora/App/AppModel+WeatherHelpers.swift:16; WordFlora/Rules/WeatherLook.swift:112-118; WordFlora/App/AppModel+Weather.swift:86, 138 |
| **Weather kit, helpers, weather puzzle** | Never arrive or open | WordFlora/Rules/WeatherShelter.swift:109-114; WordFlora/Rules/WeatherPuzzle.swift:105-107; WordFlora/App/AppModel+WeatherHelpers.swift:35, 70 |
| **Weather settings** | The whole Garden weather section is gone from Settings | WordFlora/Views/WeatherViews.swift:237 |
| **Weather reminder** | No forecast notification | WordFlora/App/AppModel+Weather.swift:9-10 |
| **Weather sounds** | No rain or wind sounds | WordFlora/Audio/WeatherSound.swift:89 |
| **Weather on the widget** | No weather line or chip | WordFloraWidget/GardenWidget.swift:68 |
| **"What grows next" page** | The weather card is left off | WordFlora/Views/GrandGardenViews.swift:304 |
| **Plus offer card** | Never shown | WordFlora/Rules/PlusOfferPolicy.swift:38; WordFlora/App/AppModel.swift:495 |
| **Ads on a quick return** | A return soon after "That's enough for now" gets the gentle nudge card, never an ad | WordFlora/Rules/AdGate.swift:78-81; WordFlora/App/AppModel.swift:440 |
| **Celebrations** | Played the soft, slow way (as in Calm) | WordFlora/Rules/CelebrationStyle.swift:23 |
| **Guide** | Page 4 says "Your plant keeps all it grows, always." (no rain talk); page 5's points chip is left off | WordFlora/Rules/GuideCopy.swift:57-58; WordFlora/Views/GuideView.swift:34, 42, 581 |

## What it keeps

- The word game itself: letters, the flower's petals as tries, help clues, Daily Bloom, levels. None of it is timed.
- Finding plants, every plant page, the life meters (water, sun, soil, growth) and hearts (always full).
- Tending: water, feed, sun, prune and repot all work as usual: water, feed and sun once a day each, prune rests 2 days (WordFlora/Rules/ToolEngine.swift:72, 133-134).
- Garden Days on Home, the Rose of Jericho line, the streak (a separate "Show streak" switch, off by default for under 13).
- The butterfly game and its sticker album. Its 35-second time bar is hidden by **Calm mode**, not by Quiet Garden
  (WordFlora/App/AppModel.swift:605, WordFlora/Rules/ButterflyGameModel.swift:44). An under-13 player has Calm on, so they do not see it;
  someone who turns Calm off but keeps Quiet Garden on does.
- Pots, the Visitors Book, golden plants (the golden glow itself, not the countdown), the Grand Garden.
- The 20-minute break card for under 13 (not a game timer; WordFlora/App/AppModel.swift:765).

## Notes

- The Settings footnote says Quiet Garden "hides counters and timers". That is true of every counter above; the one
  on-screen time bar it does not hide is the butterfly game's (Calm hides that). The onboarding screen therefore says
  "No points or counting" rather than promising no timers.
- `markQuietVisit` / `quietVisit` (WordFlora/App/AppModel.swift:35-37) is a different thing: it keeps one visit free of ads
  and the Plus card after a ceremony or the weather puzzle. It has nothing to do with this setting.

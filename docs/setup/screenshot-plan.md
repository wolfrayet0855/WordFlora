# Screenshot plan (capture in G6)

Drafted 2026-11-07. Inputs: `FidelityScreensUITests` (inside `WordFloraUITests/WordFloraUITests.swift`), `WeatherUITests`, `docs/pm/status-review-2026-11-07.md` section 4, `owner-setup-steps.md` D6. Nothing here was run. **[ASSUMPTION]** marks guesses; **[VERIFY]** marks facts to check in App Store Connect or on the G6 build.

## Sizes

| Slot | Size (portrait px) | Simulator to use | Notes |
|---|---|---|---|
| 6.9-inch (required) | 1320 x 2868 | iPhone 17 Pro Max (also accepts 1290 x 2796) | **[VERIFY]** against ASC Screenshot Specifications on the day |
| 6.5-inch | 1284 x 2778 or 1242 x 2688 | iPhone 11 Pro Max (1242 x 2688), or a 6.5-inch class device if installed **[ASSUMPTION: the simulator runtime is installed; otherwise upload the 6.9-inch set only and let ASC scale it, **[VERIFY]**]** | Apple may only require the largest set; the PM asked for both |

iPhone only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad shots. Up to 10 per size; plan is 8 per size, same order, same captions.

## The 8 screens

Order is the order in the listing. Light unless stated. Captions are short, plain, and make no claim the build cannot show (no ratings, no "kids").

| # | Screen and state | How the existing runner reaches it | Light/dark | Caption (overlay, in the editor, not in the app) |
|---|---|---|---|---|
| 1 | Home, mid-game garden, every tile open | `testHomeScreens`: `-uitest-gardened -uitest-everything` -> `fid-home-open-light` | light | "Guess a word. Grow a plant." |
| 2 | Puzzle in progress, a few keys used right and wrong | `testPotPickerAndGameScreens` game part: `-uitest-word=LOTUS`, taps Z and X -> `fid-game-light`. Better: `testPuzzleScreens` with several letters used **[ASSUMPTION: pick the nicest frame from its output]** | light | "Pick letters at your own pace." |
| 3 | Garden grid with found plants | `testPlantPageScreens` -> `fid-garden-light` | light | "Fill your garden, one word at a time." |
| 4 | Plant page (Daisy) with tend buttons | `testPlantPageScreens` -> `fid-plant-light` | light | "Give each plant a drink and a hello." |
| 5 | Visitors' book / butterfly | `testShedVisitorsAndLevelScreens` -> `fid-visitors-light` | light | "Meet the visitors." |
| 6 | Garden weather day (plants look different, a card explains) | `WeatherUITests` style launch: `-uitest -uitest-onboarded -uitest-weather-today=hailShower` (also `bigWind`, `frostyNight`). **Not in `FidelityScreensUITests` today: needs a new shot test** | light | "Weather comes and goes. Nothing is lost." |
| 7 | Shed with pots (including a Plus pot) and, if shipped, the pack entry | `testShedVisitorsAndLevelScreens` -> `fid-shed-light` and the `-1..-3` scrolls; pack entry shot needs the G3/G5 state **[ASSUMPTION]** | light | "Choose pots for your plants." |
| 8 | Home or plant page in dark mode | `testHomeScreens` -> `fid-home-open-dark` (or `fid-plant-dark`) | **dark** | "Easy on the eyes at night." |

Optional extra if a slot is free: Plus page with the three choices (see IAP shots; the same capture can be reused with a caption "Free to play. Plus is optional."). Decide in G6 whether showing prices in store screenshots is wanted; they must match ASC exactly if shown. **[ASSUMPTION: skip prices in marketing shots; use IAP review shots for that.]**

Do not use the AX XXXL ("ax5") shots in the listing; they are for the audit only. Do not show an ad or the age question. Do not capture under-13 variants (the listing should not signal a children's app).

## Capture checklist (G6, on the build lock, after the full regression)

1. Confirm G6 regression is done and nobody else uses the machine; reboot the simulator and erase it if it has passed about 200 processes (status review, risk 7).
2. Boot the 6.9-inch simulator (iPhone 17 Pro Max). Set status bar clean if desired: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`. **[ASSUMPTION: flags valid on this Xcode; check `xcrun simctl status_bar --help`]**
3. Pick an empty output folder, then run only the fidelity class with `TEST_RUNNER_SCREENSHOT_DIR=<folder>` exported (the runner writes `fid-<name>.png` there; the shots also live in the result bundle). Use the project's usual build-lock wrapper and an own derived-data folder. Run one class at a time: `testHomeScreens`, `testPlantPageScreens`, `testShedVisitorsAndLevelScreens`, `testPotPickerAndGameScreens` (and `testPuzzleScreens` for a richer puzzle frame).
4. Weather shot: run the weather launch for screen 6 (a small new test or `xcrun simctl launch` is not possible without launch arguments; use a new XCUITest in `FidelityScreensUITests` style that calls the shot helper). **Code change needed: out of scope of this docs task; add to the G6 brief.**
5. Check each PNG: size is 1320 x 2868 (`sips -g pixelWidth -g pixelHeight <file>`); no keyboard, no debug banner, no test overlay; plants and text look right; no truncated text. The runner draws the full simulator screen, so the status bar is included.
6. Repeat steps 2 to 5 on the 6.5-inch simulator. Ensure the same screens exist; names suffix `-65`.
7. Pick the best frame per slot; add captions in an editor (Keynote, Figma or Preview); export at exact size without alpha **[VERIFY: ASC rejects transparency in some cases]**.
8. Upload in ASC order 1 to 8 for each size; keep the source PNGs in a folder outside the repo (screenshots are large). Do not commit them. **[ASSUMPTION: the repo is not the place for binaries.]**

## IAP review screenshots

ASC asks for one review screenshot per in-app purchase. All must come from the G6 build (not a mockup) and match what the reviewer will see.

| Product | What to show | How to capture | Review note to paste |
|---|---|---|---|
| `plus_lifetime` (Plus Forever, $34.99) | The Plus page with all three rows visible: Yearly (default), Monthly, Plus Forever, with real prices | Needs real StoreKit prices: a device or simulator running the TestFlight/sandbox build, or the simulator with `Config/WordFlora.storekit` selected so prices load. Navigate Home > Settings > Remove ads and sync with iCloud. Scroll so the three rows fit one screen, or take two shots. **[ASSUMPTION: the UI-test `plus-*.png` in `testBadgesSettingsPlusDailyAndAgeScreens` may show "couldn't load the plans" because test launches do not load the .storekit config; check before using]** | "Non-consumable lifetime unlock of the same features as the WordFlora Plus subscription. Restore purchases is on the same page." (from A13) |
| `pack_frost_lantern` (Frost & Lantern, $2.99) | The pack's purchase screen: what it contains (pots, scene, visitors, glasshouse plants) and the buy button | Navigate to the pack entry point from the G3/G5 build **[ASSUMPTION: the entry is in the Shed; confirm]** | "One-time purchase that adds winter content: three pots, a snowy lantern garden, two winter visitors and two glasshouse plants. Restore purchases brings it back." |
| `plus_yearly`, `plus_monthly` (already needed, A6/A8) | The same three-row Plus page | Reuse the lifetime capture | per A6 |

Size for IAP review shots: any accepted iPhone size, for example the 6.9-inch capture **[VERIFY]**. The paywall shot must match the shipping paywall (three options, matching prices); the status review lists this as a rejection risk.

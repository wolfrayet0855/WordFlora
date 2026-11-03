# WordFlora

**Guess words. Grow a garden.** A calm word-guessing game for iPhone. Guess a plant word from a clue; each wrong guess lets a petal drift off the flower. Win to find real plants (50 across 5 levels), tend them with water, soil and sun, catch garden visitors, earn badges, and come back for a shared Daily Bloom.

Mixed kid/adult audience, not in the Kids Category. SwiftUI, SwiftData, iOS 17.5+ (built with the iOS 26.5 SDK).

## What's in the app
- **Word game:** bundled, reviewed plant word bank; help ladder; losses are "resting", never failure; Rose of Jericho wake-up.
- **Garden:** 50 plants, two progression tracks (words found / garden flourishing), tending, tools, repotting, nicknames.
- **Butterfly game:** 35-second no-fail mini-game, sticker album, evening-only visitors.
- **Badges** (positive-only), **Daily Bloom** (deterministic, no server), spoiler-free sharing.
- **Home-screen widget:** small, medium and Lock Screen, with an interactive water button (App Intents).
- **WordFlora Plus:** one subscription group, `plus_yearly` $12.99 (3-day trial) and `plus_monthly` $3.99; removes ads, enables iCloud sync.
- **Ads (free adults only):** Google AdMob banner (Home/Garden), optional rewarded drops, and an every-third-round ad only after the player taps "One more". Never for under-13, unknown age, or subscribers.
- **Optional on-device AI** (Apple Intelligence, iOS 26+): "Tell me more", validated and with a static fallback.
- **Gentle reminders** (opt-in, at most one a day), **sound** (ambient session), **haptics**, Reduce Motion, Calm mode, Quiet Garden.

## Layout
```
WordFlora/            app (App, Views, Components, Rules, Services, Storage, Ads, AI, Audio, Notifications, Shared)
WordFloraWidget/      home-screen widget extension
WordFloraTests/       unit tests (rules, view models, StoreKit config, storage, sound, ...)
WordFloraUITests/     UI tests incl. Apple's accessibility audit on every screen
Config/               Ads.xcconfig (test ad ids), WordFlora.storekit (local StoreKit)
design-preview/       approved mockups, art sources, prototype (served on localhost:8765 during design)
docs/                 specs, plans, research, owner setup steps, STATUS.md
```
Shared with the widget through the App Group: models, `TendingEngine`, `WidgetActions`, settings.

## Run and test
```bash
xcodebuild test -scheme WordFlora -destination 'platform=iOS Simulator,name=iPhone 16'
```
UI tests launch with `-uitest` flags (fresh in-memory store, ads off). Real ad ids go in `Config/Ads.local.xcconfig` (git-ignored).

## Identifiers
Bundle `beta.WordFlora`, widget `beta.WordFlora.WordFloraWidget`, team `P9Z5QB8965`, App Group `group.beta.WordFlora`, iCloud `iCloud.beta.WordFlora`, products `plus_yearly` / `plus_monthly` (group "WordFlora Plus").

## Status
See [`docs/STATUS.md`](docs/STATUS.md) for what is verified, how, and what still needs an owner or a real device.

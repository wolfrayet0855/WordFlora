# WordFlora build status (2026-11-03)

Branch `1-feat-triviaapi-and-earn-flora`. Spec: `docs/superpowers/specs/2026-11-02-wordflora-v2-design.md` (sections 11-20 hold the latest decisions). Plan: `docs/superpowers/plans/2026-11-02-wordflora-v2.md`.

## Verified by automated tests (simulator, iPhone 16, iOS 18.5)
- ~250 unit tests: word bank/validator, Daily Bloom (time zones, DST), round logic, Rose meter, Garden Days, progression, help ladder, tending, tools, butterfly, badges, ad gate and accounting, reminders, sound events, share text, storage migration, StoreKit config, paywall rules, widget actions, iCloud flag logic.
- ~20 UI tests: first session, game, resting, tending, paywall, shed, badges, butterfly, and Apple's accessibility audit on every screen.
- StoreKit local config proves: `plus_yearly` $12.99 with a 3-day free trial, `plus_monthly` $3.99, both Family Sharing; purchasing either turns Plus on; expiry turns it off.
- Device signing: automatic signing builds for iOS with the App Group and iCloud container in the provisioning profile (app and widget).
- SwiftData schema opens in CloudKit sync mode (CloudKit-compatible).

## NOT verified (needs a real device, an account, or ears/eyes)
- **Widget on a Home Screen / Lock Screen:** builds, embeds and signs; never seen rendered. The interactive water button is untested on device.
- **iCloud sync end to end:** needs two devices and the CloudKit schema deployed to Production. Conflict handling is SwiftData/CloudKit last-writer-wins; our "max/union" merge rule exists as logic (`BadgeState.merged`) but is not wired into sync.
- **Ads:** only Google test ids are configured. Real units, UMP message setup, `app-ads.txt` and a privacy policy URL are owner tasks. Consent form and real ad serving are untested.
- **Sounds:** the recommended set was chosen on design rationale; nobody has listened. Haptics are untested on device.
- **On-device AI ("Tell me more"):** compiles and falls back safely; behavior on a real Apple Intelligence device is untested; context limit and kids-content behavior need a spike.
- **Real StoreKit sandbox purchase** against App Store Connect products, parental gate flow, Ask to Buy.
- **Reminders** on a real device (permission prompt, delivery).

## Owner items (see `docs/setup/owner-setup-steps.md`)
Privacy policy and support URLs (`Links.swift` currently points at placeholder `wordflora.app` pages), real AdMob ids in `Config/Ads.local.xcconfig`, App Store Connect product creation, CloudKit schema deploy, age rating, privacy labels, review of the 30 starter words and writing of ~270 more (`WordFlora/Resources/Words.json`, validator in `WordBankValidator`), fact-check of remaining species/plant facts.

## Known gaps / next
- Word bank is a 30-entry starter; difficulty bands need calibration once the full bank exists.
- Badge catalog is 12 of the 36 designed badges; the rest need counters and rules.
- No Game Center, spaced-review rounds, camera "Find a plant", voice guessing, Image Playground sticker.
- Daily Bloom share is text only; no ShareLink for badges.
- Prototype-only ideas not built: plant diary, first-bloom ceremony, season/weather mood, welcome-back card.

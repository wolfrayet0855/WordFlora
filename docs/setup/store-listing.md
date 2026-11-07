# WordFlora App Store listing (version 1.0)

Drafted 2026-11-07. Paste into App Store Connect (app > version 1.0 page, App Information, Pricing and Availability). Limits were counted; re-check in the UI. Items marked **[ASSUMPTION]** are my guesses for the owner to confirm; **[VERIFY]** means a fact to check against the final build before submitting.

Tone rules used: calm and plain; no "kids", "for children" or "Made for Kids" claims (the app is a mixed-audience app outside the Kids Category, per `owner-setup-steps.md` D4); no claim that cannot be checked in the build (no ratings, no "#1", no "clinically", no "educational outcomes").

## Fields

| Field | Value | Limit |
|---|---|---|
| Name | `WordFlora` **[ASSUMPTION: the name is available; fallback "WordFlora: Plant Words" in A4]** | 30 |
| Subtitle | `A calm word-guessing garden` (27) | 30 |
| Promotional text (editable without a new build) | see below (about 140) | 170 |
| Keywords | see below (97) | 100 |
| Primary category | Games > Word **[ASSUMPTION per the status review]** | |
| Secondary category | Education (owner confirmed 2026-11-07). Family is a Games subcategory and may read as a Kids signal; Education is safer. Leave empty if unsure. | |
| Version | 1.0 (build 1) | |
| Copyright | `2026 Shape Haven Innovations` (owner confirmed 2026-11-07) | |
| Privacy Policy URL | https://shapehaveninnovations.com/privacy | |
| Support URL | https://shapehaveninnovations.com/support.html | |
| Marketing URL | https://shapehaveninnovations.com **[ASSUMPTION: site root; it must also host `/app-ads.txt` (C8)]** | |
| Age rating | computed in App Store Connect on Apple's new tiers; see `owner-dated-checklist.md` | |
| Made for Kids | NOT selected | |
| Price | Free, with in-app purchases | |
| Content rights | "No third-party content" **[VERIFY: sounds, words and art are all original or licensed; check `docs/research/` for sound sources]** | |

## Promotional text (about 140 characters)

```
Guess a word, grow a plant. A quiet garden game with gentle weather, visiting butterflies and a Daily Bloom. Free to play; Plus removes ads.
```

## Keywords (97 of 100 characters, comma-separated, no spaces after commas)

```
word game,plants,garden,calm,puzzle,flowers,relaxing,vocabulary,nature,cozy,spelling,botany,guess
```

Notes: "word", "game" and the app name are indexed already; the pair "word game" costs 9 characters and can be dropped for another term. No competitor or trademark names are used on purpose (avoid "wordle").

## Description

```
Guess a word. Grow a plant.

WordFlora is a calm word-guessing game set in a garden. Each puzzle is a plant word. Pick letters, work out the word, and a seedling grows. Find enough words and your garden fills with flowers, herbs and trees, each with a short story about how it got its name. There is no rush.

WHAT YOU DO
- Solve letter puzzles at a gentle pace, with hints when you want them.
- Come back each day for the Daily Bloom.
- Tend your plants: a drink, a hello, a new pot from the Shed.
- Meet butterflies and other garden visitors, and keep a book of the ones you have met.
- Collect badges as your garden grows.

GARDEN WEATHER
Now and then a big wind, a dry spell or a frosty night visits your garden. Plants look a little different for a few days, and a drink or a hello helps them perk up. Nothing you grow goes away. Want a bigger challenge? Turn on Wild Weather in Settings: a big storm can make up to 4 plants look one step smaller for up to 4 days, until care, a weather puzzle or time brings them back. Your level never goes down. Calm mode and Quiet Garden keep the weather away.

MADE TO BE COMFORTABLE
- Calm mode and Quiet Garden hide counters and wait times so tending is just relaxing.
- Dark mode, large text sizes, VoiceOver and a Sound switch are supported. [VERIFY before submit: each item against the final build]
- Everything in the game can be played for free.

FREE, WITH OPTIONAL PLUS
WordFlora is free with ads for grown-up players; WordFlora Plus removes ads and syncs your garden with iCloud. Players under 13 never see ads. Family Sharing covers up to six people.
Choose Yearly ($12.99 a year, with a 3-day free trial for new subscribers), Monthly ($3.99 a month) or Plus Forever (a one-time $34.99, no renewals). Prices are in US dollars and vary by region. [VERIFY: prices in the final build and ASC match]
An optional pack, Frost & Lantern, adds winter pots, a snowy lantern garden, two winter visitors and two glasshouse plants as a one-time purchase. [ASSUMPTION: final wording follows what G5 ships; if G5 falls back to the starter pack, edit this paragraph and the IAP description]

WordFlora Plus is an auto-renewing subscription. It renews unless turned off at least 24 hours before the end of the period, and you can manage or cancel it in your App Store account settings. Plus Forever is bought once and has no renewal.
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://shapehaveninnovations.com/privacy
```

Checks applied: the weather paragraph, the ads/Plus line and the subscription terms are the existing D6 and D6b texts, kept word for word; Terms of Use link present (guideline 3.1.2); no "kids" claim; "Players under 13 never see ads" matches the review notes; no "no timers" claim because the opt-in Speed bloom (13+) is timed.

## What's New (1.0)

```
Welcome to WordFlora. Guess a word, grow a plant, and watch a quiet garden fill up. We hope it is a calm few minutes in your day.
```

## Territories and pricing note

- Availability: all territories where the Paid Apps Agreement allows sales **[ASSUMPTION; owner decision 3 in `owner-setup-steps.md`]**. If any territory is excluded, exclude it for the app and for every product so prices and review notes stay consistent.
- Price points: Plus Yearly $12.99 (3-day free trial for new subscribers, yearly only), Plus Monthly $3.99, Plus Forever $34.99 (non-consumable), Frost & Lantern pack $2.99 (non-consumable, **[ASSUMPTION: $2.99 from the release plan]**). Other territories use Apple's conversion unless the owner edits them.
- Small Business Program enrollment should be approved before launch (A3).

## Other App Store Connect text

- App Review contact and notes: see D8 in `owner-setup-steps.md`.
- Subscription and IAP names and descriptions: A6, A8, A13 in `owner-setup-steps.md`. **Note:** the release plan names the lifetime display name "WordFlora Plus Forever" while A13 says "Plus Forever"; the app shows "Plus Forever". Pick one and use it in ASC and the screenshots.
- Sign-in required: No. Demo account: none.

# Backlog (owner, 2026-11-06)

Items here are parked, not cut. Each needs the owner's go before it is built.

## Growing app icon (owner: backlog)
- iOS cannot animate a third-party Home Screen icon. Alternate icons can be swapped (`setAlternateIconName`), which
  always shows a system alert.
- Idea: a seedling / bud / bloom icon set the player picks in Settings (never switched automatically).
- Needs new icon art per stage; effort small plus art. Target 1.1.

## From the plant-interaction research (docs/research/plant-attachment.md)
- Living Touch full version (CoreHaptics purr per personality), Garden Memory (10 memories per plant), Tilt garden,
  Siri "say hello to Daisy", Say it to me (parent-gated, on-device speech). Skip AR.

## From the monetization exploration (docs/research/monetization-majors.md)
- Lifetime "Plus Forever" $34.99, seasonal packs, mediation (dropped 2026-11-07: AppLovin not accepting publishers), offer-code redeem row, classroom edition as a
  separate app (no-go now). Owner decides each.

## Badge mechanics (docs/pm/badge-mechanics.md; Fable rulings 2026-11-06, none in the first release)
- 1.1, in this order: Field Notes (mark on "I read it!" or didFinish, never on page open), Gentle Net (resting visitor,
  land chance 1 in 3, one resting visitor on screen at a time), Pruning Pro (faded bloom only, no shaggy sprig),
  Mist Maker (new field `PlantCollectible.lastMistedAt: Date?`, approved by Fable; copy the lastPrunedAt pattern).
- 1.2: Wild Discovery, after a mockup; cut the list to 10 wildflowers with facts already sourced.
- About 10 days in total. Owner approval needed before starting.

## 1.1 ideas collected 2026-11-07/08 (parked, owner go needed for each)
- Subscriber-to-Plus-Forever upgrade path on the Plus page.
- Read the trial length from the store offer instead of fixed copy.
- Real first-met date per visitor.
- A Stop state for Listen.
- "Talk together" questions for under-13s.
- Garden postcard image share (13 and up).
- Widget states per weather.
- First-bloom ceremony.
- Sunday thank-you letters from plants.
- Petal song echo.
- SPM split of `Rules/` so unit tests run without a simulator.
- Weather sounds resume after an interruption and stop on headphone unplug.
- Garden bed ramp-in (the garden bed starts at full level with no ramp).
- Calm trims the effect volumes (master 0.8 to about 0.57).
- Ads: Unity Ads bidder, a rewarded value test, the Declared Age Range API.

- Gate: post a VoiceOver announcement when the wrong-answer line appears (PlusView.swift ~377) (1.1, from G6 fixes review).
- Shed: the zero-height sponsored-section spacer adds a 12 pt gap at the bottom when an ad is present; move the .task to ShedView or pad -12 (1.1, cosmetic).

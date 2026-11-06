# CloudKit: new stored fields since `main`

Source: `git diff main -- WordFlora/Models` on branch `3-feat-content-and-polish` (2026-11-06). Only `PlantCollectible` and `PlayerProfile` changed; `GameRecord` did not. No field was removed or renamed, no relationship and no unique constraint was added, and every new field has a default (or is optional), so SwiftData's lightweight migration accepts it and older CloudKit records read as the default.

SwiftData's CloudKit mirroring stores a model `X` as record type `CD_X` and a property `p` as field `CD_p`. A Swift `Bool` is stored as an `Int(64)`, and an array as a CloudKit list.

## Record type `CD_PlantCollectible` (6 new fields)

| Swift property | Swift type | CloudKit field | CloudKit type | Default |
|---|---|---|---|---|
| `potId` | `String` | `CD_potId` | String | `""` |
| `potChosenAt` | `Date` | `CD_potChosenAt` | Date/Time | `distantPast` |
| `goldenDays` | `Int` | `CD_goldenDays` | Int(64) | `0` |
| `goldenDayKey` | `Int` | `CD_goldenDayKey` | Int(64) | `0` |
| `lifeSeenKey` | `String` | `CD_lifeSeenKey` | String | `""` |
| `lifeSeenAt` | `Date` | `CD_lifeSeenAt` | Date/Time | `distantPast` |

## Record type `CD_PlayerProfile` (16 new fields)

| Swift property | Swift type | CloudKit field | CloudKit type | Default |
|---|---|---|---|---|
| `earnedPotIds` | `[String]` | `CD_earnedPotIds` | List (String) | `[]` |
| `wordsTowardPlant` | `Int` | `CD_wordsTowardPlant` | Int(64) | `0` |
| `weatherSeed` | `Int64` | `CD_weatherSeed` | Int(64) | `0` |
| `weatherStartDay` | `Int` | `CD_weatherStartDay` | Int(64) | `0` |
| `weatherHighWaterDay` | `Int` | `CD_weatherHighWaterDay` | Int(64) | `0` |
| `weatherShelterDay` | `Int` | `CD_weatherShelterDay` | Int(64) | `0` |
| `weatherRescuedDays` | `[Int]` | `CD_weatherRescuedDays` | List (Int(64)) | `[]` |
| `weatherPuzzleDay` | `Int` | `CD_weatherPuzzleDay` | Int(64) | `0` |
| `weatherPuzzleCount` | `Int` | `CD_weatherPuzzleCount` | Int(64) | `0` |
| `wildWeather` | `Bool` | `CD_wildWeather` | Int(64) | `false` (0) |
| `weatherGatedFromDay` | `Int` | `CD_weatherGatedFromDay` | Int(64) | `0` |
| `weatherSeenAt` | `Date?` | `CD_weatherSeenAt` | Date/Time | nil |
| `weatherKitAt` | `Date?` | `CD_weatherKitAt` | Date/Time | nil |
| `crownSeenAt` | `Date?` | `CD_crownSeenAt` | Date/Time | nil |
| `goldCrownSeenAt` | `Date?` | `CD_goldCrownSeenAt` | Date/Time | nil |
| `guideSeen` | `Bool` | `CD_guideSeen` | Int(64) | `false` (0) |

SwiftData may store arrays of value types as encoded data (Bytes) instead of a list, depending on the OS version; whatever the development schema shows after step 1 below is the truth, so deploy what it generated rather than creating fields by hand.

## How to deploy (owner)

1. Run a debug build with iCloud sync on, signed into iCloud, on the new build. Open the garden, play a round, open a plant page and the Shed, so a `PlayerProfile` and a `PlantCollectible` record are saved. This makes CloudKit add the fields above to the **Development** schema (see `owner-setup-steps.md`, B8).
2. In the CloudKit Console (container `iCloud.beta.WordFlora`), Development > Schema > Record Types: check that `CD_PlantCollectible` and `CD_PlayerProfile` list every field above.
3. Deploy Schema Changes to **Production** before the build that carries these fields reaches TestFlight or the App Store. A production app cannot add fields itself; without the deploy, saves of these records fail on Production.

## Data safety checks (QA, 2026-11-06)

- `DataReconciler` merges every field above with the rule written on its declaration (max, union, min of non-nil, later stamp wins, OR/AND), so a sync never lowers an earned value.
- `GardenBackup` carries the new fields as optionals; backups written before them still decode (tests in `GardenBackupTests`).
- See `docs/STATUS.md`, "Final QA", for the test run.

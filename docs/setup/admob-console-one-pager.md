# AdMob console: five checks (owner one-pager)

About 15 to 20 minutes. Do these once in the AdMob console before the Release build is archived. You create **no new ad units**: the units already exist. Nothing here needs an app update. Ids are named by their key in `Config/Ads.local.xcconfig` and by their **last 4 digits** (read them in the console's Ad units list and compare). Do not paste full ids into chats or documents.

Click path to the unit list: admob.google.com > **Apps** > **WordFlora** > **Ad units**. Menu names may differ a little; where a label is a guess it says (verify in UI).

## 0. Keys and last 4 digits

| Key | Format it must be in the console | Last 4 |
|---|---|---|
| `ADMOB_APP_ID` | the app id (contains a tilde `~`) | 8867 |
| `ADMOB_BANNER_ID` (Home banner, also used by the Garden banner) | Banner | 4195 |
| `ADMOB_BANNER_GARDEN_COLLAPSIBLE_ID` | Banner | 3355 |
| `ADMOB_INTERSTITIAL_ID` | Interstitial | 2484 |
| `ADMOB_REWARDED_ID` (water) | Rewarded | 6377 |
| `ADMOB_REWARDED_HINT_ID` | Rewarded | 5025 |
| `ADMOB_REWARDED_WAKE_ID` | Rewarded | 9017 |
| `ADMOB_APPOPEN_ID` | App open | 2335 |
| `ADMOB_NATIVE_ID` | Native advanced | 9371 |

`ADMOB_BANNER_GARDEN_ID` has no line of its own: the Garden banner reuses the Home banner unit on purpose.

## 1. Formats match

1. Open the **Ad units** list.
2. Read the **Format** column next to each unit and match it to the table above by last 4 digits.
3. Banner: `4195` and `3355`. Interstitial: `2484`. **Rewarded** (not "Rewarded interstitial"): `6377`, `5025`, `9017`. **App open**: `2335`. **Native advanced**: `9371`.
4. Check the app id ends `8867` and has a `~` in it (units have a `/`).
5. Wrong format on a unit: tell the lead which key and which format. A unit's format cannot be changed, and an app-open or native unit in the wrong format never fills.

## 2. Native unit: leave both ad types on

1. Click the native unit ending `9371`.
2. Leave both **image** and **video** ad types on (the app starts video muted and skips video in Calm mode). Do not restrict it to image only.

## 3. No app-level child tag

1. **Apps** > **WordFlora** > **App settings**.
2. Find the child-directed or "tag for child-directed treatment" setting (verify in UI). It must be **off** for the app as a whole.
3. Why: age is decided per request in the app (under 13 and unknown age never load an ad at all). An app-wide child tag would also hurt app-open fill.
4. Also confirm the app's maximum ad content rating is **G** if the setting is offered (verify in UI) and that sensitive categories are blocked (Blocking controls > Sensitive categories, as in section C6 of the owner steps).

## 4. Refresh: 60 seconds on Home, off for the collapsible

1. Click the Home banner unit ending `4195` > edit > **Refresh rate** (verify in UI) = **60 seconds**.
2. Click the collapsible unit ending `3355` > edit > set refresh to **off / do not refresh** (verify in UI).
3. Why: Google never serves a collapsible ad on an automatic refresh, so refreshes there would only muddy its report.
4. Other banner units: none. No other units need a change.

## 5. Frequency caps and AdMob-only mediation groups

Frequency caps (a backstop; the app's own limits are the real rule), in each unit's advanced settings (verify in UI):
- App open `2335`: **1 impression per user per day**.
- Interstitial `2484`: **6 per day**.
- Rewarded `6377`, `5025`, `9017`: no cap. Banners `4195`, `3355`: no cap. Native `9371`: no cap.

Mediation (**Mediation** in the left sidebar > **Create mediation group**):
1. Make **one group per format**: Banner, Interstitial, Rewarded, App open, Native.
2. In each group add **AdMob Network only**. Add no other ad source (AppLovin is not used; Unity is a 1.1 idea).
3. Assign the units of that format to the group (Banner group: `4195`, `3355`; Rewarded group: `6377`, `5025`, `9017`).
4. If the console refuses a group with a single source, skip that group and tell the lead (verify in UI).

## Finish

- Register your own device under **Settings** > **Test devices** before any run with Release ids (never tap your own live ads).
- Privacy & messaging: nothing to change (the GDPR and US-state messages cover every format).
- Send back to the lead: "Five checks done" plus any unit whose format was wrong, any setting you could not find, and whether the mediation groups were created.

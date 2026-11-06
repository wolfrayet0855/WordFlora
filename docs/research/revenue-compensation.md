# Making up the revenue lost by not showing ads to under-13s (research and model, 2026-11-06)

Owner question: under-13 and unknown-age players see no ads. How do we make up that revenue, and what money plan should we follow? Owner steer: be ambitious. Hard legal limits are stated as facts. Levers are kept even when they carry some risk.

## 1. Where we stand today (from the code and docs)

- **Ads:** `AdGate.mayLoadAnyAd` is false for under 13, unknown age and Plus. Teens 13 to 17 get non-personalised ads and never see the tracking (ATT) prompt (`mayAskTracking` is adults only). Banners appear on Home and Garden only, from session 2. An interstitial follows only the player's own "One more" tap, and only every 3rd round. Each one also needs: 3 sessions or a level-up first, a gap of at least 3 minutes, at most 6 a day, not at night, not after a loss and not around the Daily Bloom. A return within 3 minutes of "That's enough" may also show one (`docs/pm/ad-gate-return-nudge.md`). The optional rewarded ad gives 2 water, at most 3 a day, and is hidden for under-13s, Plus and Quiet Garden.
- **Plus:** `plus_yearly` $12.99 with a 3-day trial, `plus_monthly` $3.99 with no trial, Family Sharing on. Plus removes ads and adds iCloud sync and Plus pots. Under-13s reach it only behind a parental gate.
- **The rules are deliberately tight.** At most about 1 to 2 interstitials per day per active free adult. The kids gap is therefore smaller than a typical ad-first puzzle game would suggest.

## 2. Benchmarks used

- **eCPM (what advertisers pay per 1,000 ads shown):** rewarded > interstitial > banner, and iOS pays more than Android [1][2]. US iOS in 2024 was about $1 for banners and about $23 to $24 for interstitials and rewarded [3]. Typical US ranges are banner $0.50 to $2, interstitial $5 to $15 and rewarded $12 to $30 [4]. Global banner averages are $0.20 to $0.80 [5]. We use a blended mix of US, EU and rest-of-world traffic, so our figures sit well below US peaks.
- **Non-personalised ads (teens):** one AdMob developer estimates about 5% less revenue. Google's cookie study and Meta's tests show about 50% less [6]. AdMob's reports can split personalised from non-personalised revenue, so we can measure our own figure [7].
- **Child-directed ads:** must be contextual only. Unity notes that personalised ads earn more [8]. No clean public CPM gap exists, so we model kids' ads at 35 to 70% of the adult yield.
- **Ad revenue per daily player:** casual ads-only games earn $0.01 to $0.05 a day per daily player; hybrids (ads plus purchases) earn $0.15 to $0.50 [9].
- **Retention:** median D1 (day-1 return rate) is 22.9%, D7 4.2% and D28 0.85%. Word and trivia games are among the best retainers [10][11]. The top 25% of games reach about 30% D1 [12].
- **Subscriptions (RevenueCat 2025):**
  - Median trial start rate 6.2%. Freemium apps convert 2.18% of downloads to paid by day 35 (hard paywalls 12.1%).
  - 44.1% of annual subscribers stay a year; only 17.0% of monthly subscribers do.
  - 17 to 32-day trials convert best (45.7%, against 26.8% for shorter trials). Yet 96% of game trials are 4 days or less.
  - Gaming makes $0.08 per install by day 14. Gaming refunds run about 2.7 to 2.9% [13].
  - Cheap annual plans keep up to 36% of subscribers after a year, against 6.7% for expensive monthly plans [14].
- **Apple fees:** the Small Business Program takes 15% from year 1, and the standard 30% drops to 15% on a subscription's second year [15][16].
- **Family Sharing:** better engagement and retention, but fewer subscriptions sold per family [17].
- **Schools:** Apple School Manager gives 50% off for 20 or more copies [18]. It does **not** support in-app purchases or subscriptions, so school sales need a separate full-featured version of the app [19].
- **Law:** the amended COPPA Rule had to be met by 2026-04-22 [20]. Apple guideline 1.3 limits ads in Kids Category apps and needs parental gates [21]. Google's mixed-audience rules require a neutral age screen and child-directed tagging [22]. FTC precedents: Apple refunded at least $32.5M over kids' purchases [23], and Epic paid $520M over dark patterns and kids' privacy [24].

## 3. The model (simple and transparent)

Formulas (per month):

- `adRevPerDailyPlayer = (banners*bannerECPM + interstitials*interstitialECPM + rewarded*rewardedECPM) / 1000`
- `adRevPerMonthlyPlayer = adRevPerDailyPlayer * 30 * (dailyPlayers / monthlyPlayers)`
- `ads13plus = (freeAdults * adRevPerMonthlyPlayer) + (freeTeens * adRevPerMonthlyPlayer * teenNPAfactor)`
- `kidsCounterfactual = freeUnder13 * adRevPerMonthlyPlayer * kidsFactor`. This is what ads would have earned from under-13s and is "the gap". It assumes the same ad rules and a contextual-only discount.
- `netPerPayer = 0.85 (Apple) * regionVATfactor * (annualShare*12.99/12 + monthlyShare*3.99)`
- `subs = (adults*adultPayRate + teens*teenPayRate + under13*parentPayRate) * netPerPayer`

### Assumptions table

| Input | Low | Base | High | Basis |
|---|---|---|---|---|
| Age mix (under 13 or unknown / 13-17 / 18+) | 40/15/45 | 40/15/45 | 40/15/45 | Owner guess; unknown age counts as under 13 |
| Daily players / monthly players | 20% | 25% | 30% | Word games retain well [10][11] |
| Banners seen per daily player (Home/Garden only) | 4 | 6 | 10 | Placement limits |
| Interstitials per daily free player | 0.5 | 1.0 | 2.0 | AdGate caps (grace, every 3rd round, 3-min gap, 6/day) |
| Rewarded ads per daily free player | 0.15 | 0.3 | 0.6 | Optional, max 3/day |
| eCPM banner / interstitial / rewarded | $0.5 / $5 / $8 | $0.8 / $8 / $12 | $1.5 / $14 / $20 | Blended geography [1]-[5] |
| Teen non-personalised ad factor | 0.5 | 0.7 | 0.9 | [6][7] |
| Kids contextual factor (gap only) | 0.35 | 0.5 | 0.7 | [8] |
| Plus payer share: adults / teens / under-13 (parent buys) | 1.5% / 0.25% / 0.5% | 3% / 0.5% / 1.5% | 5% / 1% / 3% | Freemium 2.18% download-to-paid [13] |
| Annual share of payers | 65% | 75% | 85% | |
| Region/VAT factor on price | 0.75 | 0.85 | 0.95 | Non-US prices include VAT |
| Apple fee | 15% | 15% | 15% | Small Business Program [15] |
| **Ad revenue per daily player (result)** | $0.006 | $0.016 | $0.055 | Within [9] |

### Results (US$ per month)

| Monthly players | Scenario | Ads, 13+ | Plus | **Total** | **Under-13 gap** | Gap as % of total |
|---|---|---|---|---|---|---|
| 1,000 | Low / Base / High | 18 / 67 / 278 | 12 / 26 / 44 | **30 / 93 / 322** | **5 / 24 / 134** | 16 / 26 / 42% |
| 10,000 | Low / Base / High | 177 / 665 / 2,778 | 122 / 265 / 441 | **299 / 930 / 3,219** | **48 / 242 / 1,344** | 16 / 26 / 42% |
| 100,000 | Low / Base / High | 1,772 / 6,654 / 27,777 | 1,222 / 2,647 / 4,415 | **2,993 / 9,301 / 32,192** | **476 / 2,423 / 13,444** | 16 / 26 / 42% |

What the results say:

1. **The gap is about a quarter of revenue in the base case.** That is roughly $0.024 per monthly player, or about $242 a month at 10,000 players.
2. **Parents already pay back about a third of it.** Under-13 households buying Plus bring in about $78 a month at 10,000 players in the base case.
3. **Ads dominate early.** At these prices Plus brings in only about $1.31 net per payer per month. Price and conversion are therefore the biggest long-term levers.

## 4. Levers to close the gap

Each lever is costed for the base case at 10,000 monthly players. Gap to close: $242 a month, about $164 after the parent purchases already counted.

| # | Lever | Est. $/mo | Apple / legal facts and risk |
|---|---|---|---|
| 1 | **More rewarded video for adults and teens:** double soil, a seed-wake skip, an extra Daily Bloom hint, a "bonus visitor". Raise to 0.7 rewarded per daily player, opt-in only | **+$190** | Allowed at 13+; teens get non-personalised ads. Never show to under-13 or unknown age, including house ads. Keep an easy close and the Report ad link (Apple 2.5.18) |
| 2 | **Price test:** annual $12.99 vs $19.99 with a **7-day trial** (longer trials convert better [13]); keep $3.99 monthly | **+$60 to $90** | Show trial terms and renewal plainly (3.1.2). Under-13 purchases stay behind the parental gate |
| 3 | **"For grown-ups" Plus page and parent-facing App Store text:** sync for the family, no ads for anyone, cosmetic support. Behind the parental gate, raising parent conversion from 1.5% to 2.5% | **+$50** | Keep it off kid screens, with no "ask your parent" nags (FTC [23][24]) |
| 4 | **Lifetime "Grand Garden" $34.99:** a one-time purchase that unlocks Plus forever and is shared with the family | **+$40 to $80** | Allowed as a one-time unlock (non-consumable). It replaces some annual subscribers, so track the mix |
| 5 | **Seasonal pot and plant packs** ($1.99 to $2.99, cosmetic, non-consumable) for 13+, and for parents via the gate | **+$60 to $110** | No random rewards or loot boxes. No countdowns or "only today" for kids. Never remove what was bought |
| 6 | **Mediation/bidding** (AdMob bidding plus one or two partners) to lift adult eCPM 15 to 30% | **+$100 to $200** | Each extra ad SDK must honour child-directed and under-age-of-consent tags, and must appear in the privacy labels |
| 7 | **Banner tuning:** adaptive anchored banner on Home/Garden, a fair refresh rate, and keeping it away from the letter input | +$20 | Accidental-click rules (AdMob policy) |
| 8 | **Lifecycle:** Billing Grace Period on (16 days [25]), win-back offers for lapsed trials and subscribers (promotional offers), and annual as the default plan | +$25 | Apple-native tools, low risk |
| 9 | **Regional pricing:** manual lower prices in India, Brazil, Turkey and Southeast Asia | +$10 to $15 | None |
| 10 | **Schools:** a separate paid "WordFlora for Classrooms" app (no ads, no purchases inside it, $3.99 per student, schools pay half for 20+ copies) | +$20 to $60, lumpy | Must be a separate app [19]. Kids Category rules apply: no third-party ads or analytics [21]. Teachers expect FERPA/COPPA wording |
| 11 | **Cross-promotion:** free AdMob house ads, Apple Search Ads on brand terms only | Growth, not $ | None for 13+ |
| 12 | **Costs:** enrol in the Small Business Program, use RevenueCat's free tier, keep CloudKit (no server) | Saves ~15% of gross | None |

Levers 1, 2, 3, 5 and 6 together add about **+$460 to $600** a month at 10,000 players. That closes the gap about **twice over** and lifts base revenue from about **$930 to about $1,450** a month.

**Hard limits (facts, not choices):**
- No ads of any kind for under-13 or unknown age. That includes rewarded, house and cross-promotion ads.
- No ATT prompt or advertising ID for minors.
- Child-directed treatment for under-13s, and under-age-of-consent treatment for EEA teens under their country's consent age (13 to 16) [22].
- Parental gate before any purchase or outside link reachable by a child.
- Neutral age screen that does not hint at the "right" answer.
- If the app ever joins the Kids Category, AdMob must go entirely unless it meets 1.3's human-review exception [21].

**What NOT to do with kids:**
- No ads at all, not even "just rewarded".
- No prices, locks or Plus pressure on screens a child sees.
- No streak-loss or petal-loss pressure tied to paying.
- No limited-time offers or countdowns.
- No random paid rewards.
- No pushing the child to ask a parent.
- No gifting or social features that open contact.
- No collecting email or other contact details from children.
- Do not set ad behaviour from a remembered "adult" choice on a shared device without re-asking. The current "unknown = under 13" default is right.

## 5. Recommended money plan

**Pricing at launch**
- Monthly $3.99.
- Annual $19.99 with a 7-day trial, set as the default and shown as about $1.67 a month. Run an App Store Connect product-page test against $12.99 with a 3-day trial.
- Lifetime "Grand Garden" $34.99.
- Two seasonal packs a year at $2.49.
- Lower manual prices in the five largest low-income markets.

**Ads:** keep today's limits. Add 3 more rewarded placements for 13+ and AdMob bidding with one partner at launch.

**Metrics to watch**
- **RevenueCat:** trial start rate, trial-to-paid, annual vs monthly mix, revenue per install at day 14 and day 60, refund rate, renewal at year 1, win-back conversions.
- **App Store Connect:** conversion rate, D1/D7/D28 retention, product-page test results, Family Sharing members, crashes.
- **AdMob:** ad revenue per daily player, split by age band and by personalised vs non-personalised; eCPM by format and country; match rate; interstitials per daily player.
- **Our own events:** share of players by age band. This tells you the real kids share, and whether adults pick "under 13" to dodge ads; if so, keep the screen neutral.

**30 / 60 / 90 days**
- **Days 1 to 30:** launch with the pricing above. Enrol in the Small Business Program, turn on the Billing Grace Period, set the AdMob child and age tags, and set up RevenueCat dashboards. No paid installs.
- **Days 31 to 60:** read the first group of players. Start the price test ($12.99/3-day vs $19.99/7-day). Ship the extra rewarded placements, the "For grown-ups" page, and win-back offers for lapsed trials.
- **Days 61 to 90:** add a mediation partner. Ship the first seasonal pack. Decide the lifetime price. Pilot the Classrooms app with 2 or 3 teachers. Start paid installs only if day-60 revenue per install is above the install cost.

**Break-even for one developer**
- Cash costs are about $15 to $30 a month: $99 a year Apple developer fee, plus domain and hosting. Base case covers them at about 300 monthly players.
- The real break-even is paying the owner. At $3,000 a month net, the base case needs about **32,000 monthly players with today's setup**, or about **21,000 with the levers above**. The low case needs about 70,000 to 100,000, so retention and a word bank deep enough to keep adults playing matter more than any single price.

## Sources

1. Appodeal, Mobile eCPM Report Q4 2024: https://appodeal.com/the-mobile-ecpm-report-updated-q4-2024-view
2. TopOn, Global Mobile Games Monetization Report 2025 H1: https://mores.toponad.com/reports/TopOn%20Global%20Mobile%20Games%20Monetization%20Report%20_%202025%20H1.pdf
3. Udonis, eCPM benchmarks: https://blog.udonis.co/mobile-marketing/mobile-apps/ecpms
4. Appalize, AdMob vs alternatives: https://www.appalize.com/blog/monetization/admob-vs-alternatives-maximizing-your-ad-revenue
5. Playwire, AdMob eCPM benchmarks: https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect
6. PPC Land on Google's cookie study: https://ppc.land/ads-without-cookies-represent-52-less-revenue-for-the-publishers-google-finds/ ; Solar2D forum: https://forums.solar2d.com/t/paid-admob-plugin-support-for-npa-parameter-in-request-extras-gdpr/347594?page=2
7. AdMob Help, serving restriction reporting: https://support.google.com/admob/answer/10922726
8. Unity docs, COPPA and contextual ads: https://docs.unity.com/ko-kr/ads-unity/4.18.0/privacy/developer-consent/coppa-compliance
9. Playio, ARPDAU benchmarks: https://blog.playio.co/arpdau-benchmarks-mobile-games
10. GameAnalytics benchmarks (summary): https://gamedevreports.substack.com/p/gameanalytics-mobile-gaming-benchmarks
11. PocketGamer.biz, trivia and word games hold the best week-one retention: https://www.pocketgamer.biz/three-billion-mobile-gamers-worth-of-data-says-that-trivia-and-word-games-hold-best-week-one-retention
12. GameAnalytics 2026 benchmarks: https://gamedevreports.substack.com/p/gameanalytics-mobile-and-pc-game
13. RevenueCat, State of Subscription Apps 2025: https://www.revenuecat.com/state-of-subscription-apps-2025/
14. RevenueCat 2025 launch post: https://revenuecat.com/blog/company/the-state-of-subscription-apps-2025-launch
15. Adapty, App Store Small Business Program: https://adapty.io/blog/app-store-small-business-program/
16. MacRumors, Apple drops fees to 15%: https://www.macrumors.com/2020/11/18/apple-drops-app-store-fees/
17. RevenueCat, implementing Family Sharing: https://www.revenuecat.com/blog/engineering/implement-apple-family-sharing/
18. Apple VPP Education Guide (50% for 20+): https://www.apple.com/ca/education/docs/VPP_Education_Guide_EN_aug14.pdf
19. Apple School Manager, in-app purchases not supported: https://support.apple.com/en-ca/guide/apple-school-manager/axme19b23f7f/web
20. Federal Register, amended COPPA Rule: https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule
21. Apple, Kids Category updates (guidelines 1.3 and 5.1.4): https://developer.apple.com/news/?id=06032019j
22. Google Play Families policy and AdMob child-directed tagging: https://support.google.com/googleplay/android-developer/answer/9893335 ; https://support.google.com/admob/answer/6223431
23. FTC, Apple refunds of at least $32.5M for kids' purchases (2014): https://www.ftc.gov/news-events/news/press-releases/2014/01/apple-inc-will-provide-full-consumer-refunds-least-325-million-settle-ftc-complaint-charging-it-unfairly-billed
24. FTC, Epic Games to pay more than half a billion dollars (2022): https://www.ftc.gov/news-events/news/press-releases/2022/12/fortnite-video-game-maker-epic-games-pay-more-half-billion-dollars-over-ftc-allegations
25. AppleInsider, billing grace period: https://appleinsider.com/articles/19/09/12/apple-introduces-billing-grace-period-for-auto-renewing-subscriptions

Caveats:
- eCPM figures vary widely between sources, and none are AdMob-on-iOS figures for word games specifically.
- The kids and teen discount factors are estimates. Measure them in AdMob's own reports.
- The FTC URLs (23, 24) were cited from memory, not re-fetched.
- The lever gains are rough estimates, not benchmarks.

# Under-13 landscape: who shows ads to children, who does not, and how

Research date 2026-11-07. Builds on `kids-revenue.md` (revenue options, Apple 1.3/5.1.4 basics, COPPA dates) and `monetization-majors.md` (Plus Forever, packs, AdMob hardening). Neither is repeated here except where a fact is needed to argue a point.

**Tags:** [verified] = I or a research helper read the primary source (the company's own policy or App Store page, ftc.gov, Federal Register/eCFR, developer.apple.com, developers.google.com) on 2026-11-07. [reported] = secondary source only (press, law-firm alert, aggregator, search excerpt). [inferred] = my deduction. App Store privacy labels are self-reported by the developer and not checked by Apple; a [verified] tag on a label means "the label says this", not "this is true".

Not legal advice. The COPPA and state-law points need a check by counsel before launch.

---

## 1. App table (36 apps)

"Ads to under-13?" means what the evidence says actually reaches a child user. The "Kids?" column shows Apple's "Made for Ages" band when the listing shows one. That band appears only for apps in the Kids Category.

### (a) Kids Category or child-directed apps that DO show ads or sponsor messages

| App | Kids? | Model | Ads to under-13? | Network / SDK | How age is determined | Source (accessed 2026-11-07) | Tag |
|---|---|---|---|---|---|---|---|
| YouTube Kids (Google) | Child-directed app | Free with ads | Yes. Paid ads, but "We prohibit interest-based advertising in YouTube Kids". Ads are not clickable, must be pre-approved by YouTube's policy team, and no remarketing pixels are allowed. Banned categories include food and beverages, beauty, video games (with exceptions) and political ads. | Google in-house | Parent sets up the app. Assumes all users are children. | https://support.google.com/youtube/answer/6168681 | [verified] |
| PBS KIDS Video | Ages 0-5 | Free, public media | Yes, sponsor messages: "brief messages from corporate sponsors are included at the start of select full-length episodes". PBS sales guidance says the spots must speak to adults; kid-appeal product categories are not allowed. The privacy label lists "Advertising Data" as not linked to the user. | Not named | None; all users treated as children | https://apps.apple.com/us/app/pbs-kids-video/id435138734 ; https://sgptv.org/wp-content/uploads/2024/06/PBS-Creative-KIDS_061024-1.pdf | [verified] listing; [reported] PBS rules |
| BabyBus "Learns Transportation" (one of many BabyBus apps) | 4+, no age band shown, so probably not in the Kids Category | Free with ads, plus SVIP subscription $4.99/mo to $41.99/yr | Yes. "Advertising" is listed under in-app controls. The privacy label says identifiers and usage data "may be used to track you" for third-party advertising. A 2023 parent review: "There is no way to pay to get rid of ads", and reports a violent full-screen ad. | Not named for iOS. In China, the MiMeng SDK was linked to inappropriate ads, and BabyBus was fined 300,000 yuan in 2025. | None found | https://apps.apple.com/us/app/id1052087662 ; https://www.sixthtone.com/news/1017788 | [verified] listing; [reported] China fine |
| Prodigy Math | Not confirmed | Freemium; membership sold inside gameplay | First-party upsells, not third-party ads. A 2021 complaint to the FTC counted 16 membership ads against 4 math problems in 19 minutes of play. No public FTC outcome found. | First-party | School/teacher or parent account | https://fairplayforkids.org/wp-content/uploads/2021/02/Prodigy_Complaint_Feb21.pdf | [reported] |
| Small-developer Kids apps using AdMob with child-directed settings (e.g. "English for Kids") | Kids Category claimed | Free with ads | Yes. Contextual, non-personalized AdMob with the child-directed tag set. | AdMob | None | https://sites.google.com/view/english-for-kids-privacy ; https://developer.apple.com/forums/thread/741173 | [reported] |

**Evidence is thin here.** I found no large, well-known Kids Category iOS app with primary evidence of SuperAwesome, Kidoz or AdMob third-party ads. SuperAwesome publishes only brand case studies (Hasbro, DreamWorks), not publisher apps (https://www.casestudies.com/company/superawesome, [reported]). Developer forum threads show App Review asking Kids apps that use AdMob to prove the network has "publicly documented practices ... human review of ad creatives" (https://developer.apple.com/forums/thread/741173, [reported]). [inferred] Third-party ads in the iOS Kids Category have mostly retreated to small developers and to China-based catalogs. The big brands moved to subscriptions.

### (b) Kids Category or child-directed apps with NO ads

| App | Kids? | Model | Ads to under-13? | How age is determined | Source | Tag |
|---|---|---|---|---|---|---|
| Khan Academy Kids | Ages 0-5 | Free, nonprofit, donations | No. "100% free, no ads, no subscriptions". The label lists analytics identifiers as not linked to the user. | None | https://apps.apple.com/us/app/khan-academy-kids/id1378467217 | [verified] |
| Duolingo ABC | Ages 0-5 | Free | No. "There are no ads or in-app purchases to worry about." | None | https://apps.apple.com/us/app/duolingo-abc-learn-to-read/id1440502568 | [verified] |
| PBS KIDS Games | Ages 0-5 | Free | No ads stated; the listing cross-promotes other PBS KIDS apps. The label shows analytics only, no tracking. | None | https://apps.apple.com/us/app/pbs-kids-games/id1050773989 | [verified] label; [inferred] no ads |
| Toca Boca World | Ages 6-8 | Free plus one-time packs, $0.99-$4.99 | No: "No third-party ads ever." Has its own shop. The label lists identifiers used for "developer's advertising or marketing". Offers Age Assurance and Parental Controls. | Parental gate; Age Assurance in the app | https://apps.apple.com/us/app/toca-boca-world/id1208138685 | [verified] |
| Lingokids | Ages 0-5 | Subscription, $14.99/mo, $71.99-$89.99/yr | No: "Designed to be ad-free". The label lists "Identifiers" under "Used to track you", most likely for parent-facing marketing attribution [inferred]. | Parent account | https://apps.apple.com/us/app/lingokids-play-and-learn/id1002043426 ; https://lingokids.com/privacy | [verified] |
| Pok Pok | Ages 0-5 (AU listing) | Subscription with a 7-day trial; lifetime option | No ("no ads or sneaky fees") | Parent account | https://apps.apple.com/au/app/id1550204730 | [reported] (search excerpt of the listing) |
| Sago Mini World / Piknik (Spin Master) | Kids | Subscription (Piknik bundle) | None found | Parent purchase | https://help.sagomini.com/article/401-what-type-of-subscription-plans-are-offered-for-sago-mini-first-words | [reported] |
| Spotify Kids | Ages 6-8 | Requires Spotify Premium Family; up to 5 Kids accounts | No ads stated on the listing [inferred: Premium is ad-free] | A parent creates the Kids account inside Family | https://apps.apple.com/us/app/spotify-kids/id1470209570 | [verified] listing; [inferred] ads |
| Messenger Kids (Meta) | Ages 9-11 | Free | No: "no in app-purchases or ads". The label still lists many data types linked to the user. | Parent sets up the account; Age Assurance | https://apps.apple.com/us/app/messenger-kids/id1285713171 | [verified] |
| Netflix Kids profiles | Profile inside the main app | Subscription | No: "Ads will not be shown on Kids profiles", even on the ad plan. In 2022 Netflix also said no ads around content for ages 13 and under. | Profile setting chosen by the parent | https://help.netflix.com/en/node/126831 ; https://kidscreen.com/?p=194153 | [reported] |

### (c) Mixed-audience apps outside the Kids Category: what each does for under-13

| App | Category / model | Age method | Ads to under-13? | Networks | Enforcement | Source | Tag |
|---|---|---|---|---|---|---|---|
| Subway Surfers (SYBO) | Runner; free with ads and IAP | "SYBO has implemented an age-gate into its games" | Yes, contextual only. Mediation through ironSource LevelPlay or Google Ad Manager "to ensure that only contextual ads are served to children". "If you are under-16 years of age, we will never serve you targeted advertising." IDs are kept for frequency capping and fraud only. | Fyber, InMobi, ironSource, Mintegral, Moloco, maio, MyTarget, Pangle, Smaato, Tapjoy, Yandex | McDonald v. Kiloo et al. (N.D. Cal., filed 2017, approved 2021). The settlement covers Subway Surfers; there was no money, only SDK limits and data deletion. | https://sybogames.com/privacy-policy (updated 2026-09-01) ; https://www.lieffcabraser.com/2021/04/settlement-receives-final-approval-in-disney-viacom-kiloo-child-privacy-violations-lawsuit/ | [verified] policy; [reported] case |
| Talking Tom & Friends (Outfit7) | Virtual pet; free with ads | Country estimated from IP, plus an age-of-consent check (mechanism not described) | Yes, contextual. The ad ID is collected "in some territories" only to show "contextual ads" and measure delivery. Interest-based ads only above the age of consent, with consent. | Not named on the page (a separate list exists) | CARU reviews in 2014 and 2019 [reported]. Member of the PRIVO COPPA Safe Harbor. | https://talkingtomandfriends.com/privacy-policy-for-children/en | [verified] |
| Candy Crush Saga (King) | Match-3; IAP plus some ads | Collects age, age range or DOB "in certain jurisdictions", from the user or the platform | Does not "target interest-based advertising to anyone under the age of 13". Those who opt out still get ads "based on criteria such as the Game you are playing" (contextual). | Not named | None found | https://king.com/privacyPolicy (26.2.2026) | [verified] |
| Words With Friends (Zynga / Take-Two) | Word game; free with ads and IAP | Store listing: must be 13+. Take-Two policy: may "apply an age gate allowing children to use the Services while restricting" features. | Not stated for children. The policy says it "may sell or share personal information about users that we know are under the age of 18", subject to settings or parent permission. | 17 ad networks integrated per AppGoblin [reported] | 2019 breach (218M accounts), not COPPA | https://www.take2games.com/privacy (Feb 2026) ; https://apps.apple.com/us/app/-/id321916506 | [verified] policy; [reported] SDK count |
| Wordscapes (PeopleFun) | Word game; free with ads and IAP | No age screen described. "The Services are not intended for use by children under the age of 16." | Policy covers interest-based ads only, with no child carve-out (relies on the "not intended" disclaimer). In 2021 a dark-patterns report said the game forced users to allow personalized ads to keep playing. | Google Ads, DoubleClick; social plugins | None found | https://peoplefun.com/privacy (effective 2026-09-23) ; https://www.deceptive.design/articles/peoplefun-game-forces-user-to-allow-personalized-advertising-to-continue-playing | [verified] policy; [reported] dark pattern |
| Roblox | UGC platform; Robux IAP plus ads | DOB at signup; video-selfie facial age estimation required for chat since Jan 2026 | Changed in 2026. Before, under-13s saw no ads [reported]. From 2026: under-13 ads allowed, "contextual and sold directly". "Ads to U13 will not be served via programmatic partners such as Google." No rewarded formats for under-13. Banned categories for under-13: food, cosmetics, pharma, finance. SuperAwesome is the exclusive under-13 ad partner; advertisers can still target country, gender and age band. | Roblox direct plus SuperAwesome | Louisiana (2025-08-14), Kentucky (2025-10-07) and Texas (2025-11-07) AG suits over child safety, not ads | https://devforum.roblox.com/t/new-advertising-policies-standards/4527365 (2026-03-20, updated 06-17) ; https://www.adexchanger.com/marketers/roblox-opens-up-advertising-to-kids-under-13/ (2026-06-04) | [verified] devforum; [reported] AdExchanger and AG suits |
| Among Us (Innersloth) | Social deduction; paid plus IAP | DOB, country and IP "to verify whether you are a child" | Ad presence not stated. The policy says Innersloth does "not sell, rent, or share" personal information for targeted ads. Unity Analytics and Sentry are used "excepting Child Users". Children default to Quick-Chat; verified parental consent runs through KWS. | KWS (consent only) | None found | https://www.innersloth.com/privacy-policy/ (effective 2023-07-01) | [verified] |
| Fortnite (Epic) | Battle royale; free with IAP | Age gate. Under 13 (or the local age of digital consent) gets a "Cabined Account": no voice chat, no real-money purchases, no custom display name, until a parent verifies through KWS. | No third-party ads found [inferred] | KWS (Epic subsidiary) | FTC 2022-12-19: $275M COPPA penalty and $245M in refunds. Chat must be off by default for kids and teens. | https://www.ftc.gov/news-events/news/press-releases/2022/12/fortnite-video-game-maker-epic-games-pay-more-half-billion-dollars-over-ftc-allegations ; https://www.engadget.com/epic-games-cabined-accounts-kids-fortnite-fall-guys-rocket-league-metaverse-153028144.html | [verified] FTC; [reported] cabined details |
| Pokémon GO (Niantic, now Scopely) | AR game; free with IAP | Under 13 must use a Niantic Kids account. A parent verifies through third-party e-verification (credit card or SSN last 4). | Off unless a parent opts in: "Sponsored content and advertisements" is a permission in the parent portal. In 2016 Niantic said sponsored locations would not appear for under-13s [reported]. | Not named | None found | https://explore.scopely.com/parents/niantic-kids ; https://fairplayforkids.org/ccfc-to-niantic-dont-lure-children-to-sponsors-locations/ | [verified] parent page; [reported] 2016 |
| Minecraft (Microsoft) | Sandbox; paid plus Marketplace | Microsoft account DOB. Below the age of consent it becomes a child account in Microsoft Family; purchases can require parent approval. | No in-game ads found [inferred] | n/a | FTC v. Microsoft (Xbox), 2023: $20M COPPA, for collecting data at signup before consent | https://hopper.minecraft.net/help/guides/xbox-privacy/ ; https://www.ftc.gov/news-events/news/press-releases/2023/06/ftc-will-require-microsoft-pay-20-million-over-charges-it-illegally-collected-personal-information | [reported] |
| Brawl Stars / Clash Royale (Supercell) | Mobile action; free with IAP | Age screen; threshold 16. "When a player indicates they are under 16 ... we will limit their access" (chat, social, notifications). Some features need parent consent. | Not addressed. For under-age players the policy limits processing to "internal operations". | n/a | None found | https://supercell.com/en/privacy-policy/ (effective 2026-03-11) | [verified] |
| Angry Birds (Rovio, Sega) | Arcade; free with ads and IAP | "We may ask you to confirm your age." Minors may be limited or removed, or data limited "to what is necessary for the internal operation". | No child-specific ad rule in the policy | Ad partners not named | New Mexico AG sued Rovio in Aug 2021 over COPPA and ad-SDK data; outcome not found | https://www.rovio.com/privacy/ (2023-12-06) ; https://appleinsider.com/articles/21/08/29/angry-birds-maker-sued-by-new-mexico-for-allegedly-violating-coppa | [verified] policy; [reported] suit |
| Duolingo (main app) | Education; free with ads plus Super subscription | Age asked at signup. Under 13 needs a parent email; age is not verified. | For child users: "Advertisements are non-personalized and set to family-safe content." | Not confirmed | None found | https://conductatlas.com/platform/duolingo/duolingo-privacy-policy/provision/CA-P-022506/child-user-advertisements-non-personalized-family-safe-only/ (captures the policy dated 2026-05-26) | [reported] (duolingo.com/privacy did not render) |
| Genshin Impact (Cognosphere / HoYoverse) | Gacha RPG; free with IAP | Weak age gate before the case. Now under order. | n/a (no ads). The FTC said identifiers were shared with analytics firms and advertisers. | n/a | FTC 2025-01-17: $20M COPPA. No loot-box sales to under-16s without parental consent. | https://www.ftc.gov/news-events/news/press-releases/2025/01/genshin-impact-game-developer-will-be-banned-selling-lootboxes-teens-under-16-without-parental | [verified] |

### (d) Apps that block or limit under-13 entirely

| App | Age method | Under-13 outcome | Source | Tag |
|---|---|---|---|---|
| Snapchat | DOB at signup | "Snapchat is for ages 13+." | https://help.snapchat.com/hc/en-us/articles/7012304746644 | [verified] |
| Instagram / Facebook | DOB plus age estimation; Teen Accounts | Blocked under 13 | (help page did not render) | [inferred] |
| TikTok (US) | DOB screen | Under 13 is sent to "TikTok for Younger Users": view only, no posting, messaging or profile. TikTok told the Senate "no advertisements are shown". | https://newsroom.tiktok.com/tiktok-for-younger-users?lang=en ; https://arxiv.org/html/2507.00299v1 | [reported] |
| Discord | DOB screen | Under-13 accounts banned | (aggregator only) | [reported] |
| ChatGPT (OpenAI) | 13+ terms; age prediction with ID fallback | Under 13 not allowed; predicted minors get a teen mode | (search excerpt only) | [reported] |
| Character.AI | Age verification | Minors restricted from open-ended chat | (weak source) | [reported] |
| Wordscapes (PeopleFun) | No screen | Disclaims under-16 use entirely (see (c)). This is "block by disclaimer", the weakest form. | https://peoplefun.com/privacy | [verified] |
| Supercell | Age screen | Under 16: limited features, not blocked (see (c)) | https://supercell.com/en/privacy-policy/ | [verified] |

Row count: 5 + 10 + 14 + 8 = 37. Wordscapes and Supercell appear twice, so there are 35 distinct apps or app families.

---

## 2. Enforcement that matters

### FTC and DOJ COPPA actions (games, apps, ad SDKs)

| Date | Defendant | Amount | Theory | Source | Tag |
|---|---|---|---|---|---|
| 2011-08 | W3 Innovations (first mobile-app COPPA case) | $50K | Kids' game apps collected emails without consent | https://www.ftc.gov/news-events/news/press-releases/2011/08/mobile-apps-developer-settles-ftc-charges-it-violated-childrens-privacy-rule | [reported] |
| 2015-12 | LAI Systems; Retro Dreamer | $60K; $300K | Kid-directed apps let ad networks collect persistent identifiers | https://www.ftc.gov/news-events/news/press-releases/2015/12/two-app-developers-settle-ftc-charges-they-violated-childrens-online-privacy-protection-act | [reported] |
| 2016-06 | InMobi (ad SDK) | $950K of $4M | Location tracking, including in child-directed apps | not fetched | [reported, from memory] |
| 2019-09 | Google/YouTube (FTC and NY AG) | $170M | Behavioral ads on child-directed channels | not fetched | [reported, from memory] |
| 2020-06-04 | **HyperBeard** (KleptoCats and others; the brief's "HyperBeast" is this case) | $4M, suspended to $150K | Let ad networks collect advertising IDs in child-directed apps for targeted ads | https://www.ftc.gov/news-events/news/press-releases/2020/06/developer-apps-popular-children-agrees-settle-ftc-allegations-it-illegally-collected-kids-data | [verified] |
| 2020-07 | Miniclip | No money | False claim of CARU safe-harbor membership | https://search.ftc.gov/news-events/news/press-releases/2020/07/ftc-gives-final-approval-settlement-digital-game-maker | [reported] |
| 2021-07-01 | **Kuuhuub Inc., Kuu Hubb Oy, Recolor Oy** (Recolor coloring app) | $3M, suspended to $100K | An "adult" app with a child-directed section; ad networks collected persistent IDs from kids. Required an in-app notice of the settlement for 180 days. | https://www.justice.gov/opa/pr/kuuhuub-inc-kuu-huub-oy-and-recolor-oy-pay-civil-penalty-children-s-online-privacy-violations ; https://www.hunton.com/privacy-and-cybersecurity-law-blog/ftc-settles-childrens-privacy-case-against-online-coloring-book-app-recolor | [reported] |
| 2022-12-19 | **Epic Games** | $275M COPPA plus $245M refunds | Knew kids played (surveys, merchandise); no parental consent; chat on by default | https://www.ftc.gov/news-events/news/press-releases/2022/12/fortnite-video-game-maker-epic-games-pay-more-half-billion-dollars-over-ftc-allegations | [verified] |
| 2023-06 | Microsoft (Xbox) | $20M | Collected data at signup before consent; kept it too long | https://www.ftc.gov/news-events/news/press-releases/2023/06/ftc-will-require-microsoft-pay-20-million-over-charges-it-illegally-collected-personal-information | [reported] |
| 2025-01-17 | **Cognosphere (Genshin Impact)** | $20M | Child-directed in fact; IDs shared with analytics and ad firms; loot boxes | https://www.ftc.gov/news-events/news/press-releases/2025/01/genshin-impact-game-developer-will-be-banned-selling-lootboxes-teens-under-16-without-parental | [verified] |
| 2025-09-02 | **Disney** | $10M | Labeled kid videos "Not Made for Kids" at channel level, which enabled targeted ads. The order relaxes if YouTube adopts age assurance. | https://www.ftc.gov/news-events/news/press-releases/2025/09/disney-pay-10-million-settle-ftc-allegations-company-enabled-unlawful-collection-childrens-personal | [verified] |
| 2025-09 | **Apitor** (robot toy app) | $500K, suspended | A third-party Chinese SDK collected children's geolocation | https://perkinscoie.com/insights/blog/lessons-ftcs-first-privacy-enforcement-actions-during-trump-20 | [reported] |
| 2025-09-29 | Iconic Hearts (Sendit) and its CEO | In litigation | Knew 116K+ users were under 13; hidden subscription charges | https://www.hunton.com/privacy-and-cybersecurity-law-blog/ftc-initiates-enforcement-action-against-sendit-and-ceo-for-coppa-violations | [reported] |

No 2026 FTC COPPA settlement against a game turned up. That is a gap in what I found, not proof that none exist.

**The pattern [inferred]:** Almost every game or app case is one of two things. Either a third-party SDK collected persistent identifiers from children (HyperBeard, LAI, Retro Dreamer, Kuuhuub, Apitor, Cognosphere), or the company knew children were present and treated them as adults (Epic, Cognosphere, Sendit, Disney). Recolor matters most for WordFlora. It was marketed to adults, yet COPPA applied because part of it appealed to children, and ad SDK identifiers were the violation.

### State AG cases and laws

- **New Mexico v. Tiny Lab and ad SDKs** (filed 2018-09; Google settled 2021-12 for $3.8M plus Play changes). The case was over 86 "Designed for Families" game apps whose ad SDKs tracked children. Claims against MoPub, InMobi and AppLovin were dismissed. [reported] Kelley Drye and MediaPost summaries.
- **New Mexico v. Rovio** (2021-08), over COPPA and ad-SDK data in Angry Birds. Outcome not found. [reported] (URL above)
- **Roblox:** Louisiana (2025-08-14), Kentucky (2025-10-07), Texas (2025-11-07) AG suits, plus a Florida investigation. These are child-safety and deception theories, not ad theories. [reported]
- **App Store Accountability Acts:**
  - Texas SB 2420 was enjoined on 2025-12-23. The Fifth Circuit stayed that injunction on 2026-05-28, and Apple applied the rules to new Texas accounts from 2026-06-04 (https://9to5mac.com/2026/06/03/apple-says-texas-app-store-age-assurance-rules-start-tomorrow-after-court-ruling/, [reported]).
  - Utah: Apple's 2026-02-24 developer post said 2026-05-06 (https://developer.apple.com/news/?id=f5zj08ey, [verified]). Utah HB 498, signed 2026-03-18, then delayed key duties to 2027-05-06 and removed AG enforcement, leaving a private right of action (https://www.wileyconnect.com/utah-amends-app-store-accountability-act-asaa-key-obligations-delayed-until-may-6-2027, [reported]). The law-firm source is newer; check Apple's current page.
  - Louisiana: Apple said 2026-07-01 [verified]; a secondary report says HB 977 moved it to 2027-07-01 [reported]. This conflict is unresolved.
  - Alabama: effective 2027-01-01 [reported].
  - California AB 1043: effective date not confirmed.
  - What these laws mean for WordFlora: developers receive the age category through the **Declared Age Range API**, plus consent signals for "significant changes" via PermissionKit (https://developer.apple.com/news/?id=2ezb6jhj, [verified per helper]).

### Apple review rejections reported by developers [reported]

- AdMob in a Kids app was rejected under 1.3; the reviewer asked for documented kids policies with human review (https://developer.apple.com/forums/thread/741173).
- Firebase Analytics in a Kids app was rejected because of the IDFA. The fix was `FirebaseAnalyticsWithoutAdIdSupport` (https://developer.apple.com/forums/thread/746490).
- A Unity Kids game was rejected under 1.3 and approved after the ads were removed (https://discussions.unity.com/t/help-needed-app-rejection-due-to-guideline-1-3-safety-kids-category/949422).
- An Expo app was approved only after removing expo-firebase-analytics (https://forums.expo.dev/t/disable-idfa-in-expo-firebase-analytics/55241).
- The mere presence of the `ASIdentifierManager` symbol from the AdMob SDK triggered a rejection (https://groups.google.com/g/google-admob-ads-sdk/c/jN8w36eT4ts).
- 1.3 rejections continued even after an app left the Kids Category (https://developer.apple.com/forums/thread/816277).

That last case matters for WordFlora: kid-looking metadata can pull a non-Kids app into Kids rules. Guideline 5.1.4 says non-Kids apps "cannot include any terms in app name, subtitle, icon, screenshots or description that imply the main audience for the app is children" (https://developer.apple.com/app-store/review/guidelines/, [verified]).

### 2025 COPPA amendments: dates and what they mean for a mixed-audience app with no under-13 ads

- **Dates:** published 2025-04-22 (90 FR 16918), effective 2025-06-23, compliance 2026-04-22 (https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule, [verified]). It is fully in force now.
- **Mixed audience** is now defined in the rule. Such a service may not collect personal information "before collecting age information". The age screen "must be done in a neutral manner that does not default to a set age or encourage visitors to falsify age information" (eCFR 16 CFR 312, https://www.ecfr.gov/current/title-16/chapter-I/subchapter-C/part-312, [verified per helper; re-copy exact text before quoting externally]).
- **Support for internal operations** still includes serving "contextual advertising". Data collected under it may not be used for behavioral ads or profiling [verified per helper].
- **New consent rule:** disclosing child data to third parties (for example for targeted ads) needs separate verifiable parental consent. Operators also need a written retention policy and a written security program [verified per helper].
- Biometric identifiers are now personal information. That matters if WordFlora ever adds face- or voice-based age estimation [verified per helper].
- **FTC 2026 policy statement (Feb 2026):** no COPPA enforcement against general- or mixed-audience operators that collect data *only to verify age*, provided use and retention are limited to that purpose, users get notice, and the data is kept secure (https://www.mayerbrown.com/en/insights/publications/2026/02/ftc-issues-policy-statement-on-age-verification-technologies-under-coppa, [reported]).

**What this means for WordFlora [inferred]:**
- A mixed-audience app that runs a neutral age screen, collects nothing before it, and **never starts the ad SDK** for under-13 and unknown-age users is on the conservative side of the rule. That is the design recorded in `monetization-majors.md` (`AdGate.mayLoadAnyAd`).
- The legal exposure moves elsewhere:
  - The age screen itself must be neutral: no default year, and no "you must be 13" copy before the question.
  - Analytics, crash and attribution SDKs must not send persistent IDs for under-13 users beyond internal operations.
  - The written retention and security policies now apply to whatever little we do hold.
  - Metadata must not make the app look child-directed. The Recolor and Disney cases show regulators look at actual audience and labeling, not intent.
- The contextual-ads-for-kids option exists legally (internal operations, plus AdMob child-directed treatment). The Roblox and SYBO models show it is commercially used. It would still reintroduce an SDK into the child path, which is the exact pattern behind most enforcement.

---

## 3. Patterns

**What the successful under-13 products have in common**

1. **The buyer is the parent, and the child never sees a price.** Lingokids, Pok Pok, Piknik, Spotify Kids and Netflix Kids are subscriptions bought by adults. Toca Boca sells one-time packs behind a parental gate. Kids-band apps that sell to children directly, like Prodigy's in-game membership ads, draw complaints [verified/reported, table b].
2. **Free kids apps are funded by someone other than ad networks:** a nonprofit (Khan Kids), public media and underwriting (PBS), or a large company's brand and funnel (Duolingo ABC, Messenger Kids) [verified].
3. **Where ads exist, they are tightly controlled first-party or contextual inventory, not open programmatic.**
   - YouTube Kids: pre-approved, non-clickable, category bans.
   - Roblox: direct-sold and contextual, "no programmatic", no rewarded formats, SuperAwesome.
   - SYBO and Outfit7: contextual-only mediation.
   - PBS: adult-addressed sponsor spots.
   [verified]
4. **Big mixed-audience games run a split account model.** A neutral age screen leads to a restricted child account, and a parent unlocks more through KWS or third-party verification (Epic, Innersloth, Niantic/Scopely, Microsoft, Supercell). Restrictions target chat, purchases and sponsored content first [verified/reported].
5. **Thresholds are creeping up to 16** for ads and features: SYBO's "never targeted" applies under 16, Supercell and PeopleFun use 16, Duolingo reportedly applies protections under 16, and Cognosphere's loot-box ban covers under 16. EU and UK ages of consent and the Children's Code drive this [verified/inferred].
6. **The worst examples are ad-heavy catalogs with tracking labels in kids' age bands** (BabyBus), and adult apps that rely on a disclaimer with no age screen (PeopleFun) [verified].

**What a mixed-audience app that serves no ads to under-13 can legitimately earn from that audience** (`kids-revenue.md` covers revenue sizing; this is the evidence that each route is used by real apps):

| Route | Real precedent | Legal footing |
|---|---|---|
| Parent-gated subscription (Plus) | Lingokids, Pok Pok, Piknik | Apple 1.3 parental gate; no child data needed |
| Family Sharing so a parent's subscription covers the child | Spotify Kids (inside Premium Family), Netflix Kids profiles | Apple Family Sharing for IAP |
| One-time premium packs, parent-gated | Toca Boca World ($0.99-$4.99 packs) | Same; non-consumable and never random (avoid the Cognosphere loot-box pattern) |
| Lifetime unlock | Pok Pok lifetime offer | Same |
| First-party cross-promotion, no third-party SDK | PBS KIDS Games (promotes PBS apps), Toca (own shop) | Not "third-party advertising" [inferred] |
| Adult-addressed underwriting or sponsor | PBS KIDS Video | Possible but brand-risky. Under 2.3.8 and 5.1.4, metadata must stay neutral. |
| Contextual-only ads with child-directed treatment | SYBO (ironSource/GAM), Outfit7, Duolingo (family-safe, non-personalized), Roblox (direct and contextual) | COPPA internal-operations exception; AdMob `tagForChildDirectedTreatment` "prevents the transmission of the ... IDFA" (https://developers.google.com/admob/ios/targeting, [verified]). The SDK still runs in the child path. |

---

## 4. Eight takeaways for WordFlora

1. **Keep "no ad SDK for under-13 or unknown age" as a hard line.** It goes beyond what Duolingo, SYBO, King and Outfit7 do (they serve contextual ads to kids). It removes the single most-enforced failure mode: an SDK collecting persistent IDs (HyperBeard, Kuuhuub/Recolor, Apitor, Cognosphere, NM v. Tiny Lab). [inferred from section 2]
2. **Audit the age screen against the amended rule's wording.** It must be neutral, with no default year and no hint of the "right" answer. Nothing may be collected or initialized before it, including Firebase or crash SDK identifiers. Treat a skipped screen as under-13 (already the "unknown" path). [verified rule text via helper]
3. **Adopt Apple's Declared Age Range API as a second signal where the OS provides it.** Use it as an input to `AdGate`, not a replacement for the in-app screen, because coverage varies by state and country. The Texas rules are live for new accounts; Utah and Louisiana dates are in flux. The FTC's 2026 statement protects age-only data collection. [verified/reported]
4. **Look at the 13 to 15 band as well.** The industry norm is moving to 16 (SYBO, Supercell, PeopleFun, Cognosphere), and EU/UK ages of consent go up to 16. Teens already get `.teen` treatment and no ATT prompt. Also set `tagForUnderAgeOfConsent` for EEA and UK users under the local age of consent, which `monetization-majors.md` already recommends. [verified/inferred]
5. **Earn from under-13 only through the parent:** Plus, Plus Forever, packs and gifting, all behind `ParentalGate` and Family Sharing. Each has a real precedent (Lingokids, Pok Pok, Toca, Spotify Kids). Never use random rewards: the Cognosphere order requires parental consent for loot boxes for under-16s. [verified]
6. **Keep the metadata clearly all-ages, not "for kids".** The Kuuhuub/Recolor and Disney cases turned on who the content really appealed to, and Apple pulled one app back into Kids rules after it left the category. Screenshots and copy should show adults and families too. [verified/reported]
7. **Write down the retention policy and security program now.** The amended COPPA requires both in writing, even for the little data an under-13 player generates (on-device progress, iCloud private DB). Make "no third-party disclosure for under-13" an explicit line in the privacy policy. [verified via helper]
8. **Do not chase contextual kids ads or brand sponsorships for revenue.** The working examples are platforms with in-house review and direct sales (YouTube, Roblox) or very high scale (SYBO). For an app of WordFlora's size, the CPM would be small and the review and SDK risk real. Revisit only if a Kids-Category sister app (the Classroom idea) needs it, and then only with a network that documents human creative review, as Apple 1.3 requires. [inferred]

---

## Where evidence is thin

- **Kids Category apps with third-party ads on iOS:** I found no large named app with primary evidence of SuperAwesome, Kidoz or AdMob-contextual use. The BabyBus listing shows no "Made for Ages" band, so its Kids Category status is unconfirmed.
- **Policies I could not read in primary form:** Duolingo's main policy (only a mirror of the 2026-05-26 version), Epic's cabined-account page (403), Roblox's help center (403), Peak/Toon Blast (SSL error), Playrix, and Meta's help page. Wordscapes, Words With Friends and Candy Crush do not say plainly whether a child who passes the screen as under-13 still sees ads.
- **Minecraft, Fortnite and Pokémon GO ad presence for kids:** inferred from the absence of ad products, not from an explicit statement (Pokémon GO's parent-permission toggle is explicit).
- **FTC rows tagged [reported]:** these rest on search excerpts of ftc.gov titles or on law-firm alerts. The Epic, HyperBeard, Cognosphere and Disney pages were read in full.
- **Utah and Louisiana effective dates conflict** between Apple's February 2026 post and later law-firm reports.
- **No 2026 FTC game settlement** was found. A newer case could exist.

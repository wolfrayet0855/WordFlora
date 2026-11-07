# Under-13 players: technical and legal requirements, and revenue (research, 2026-11-07)

Owner question: what are the technical requirements and the revenue for the under-13 age group? Today, under 13 and unknown age get no ads, no SDK start, no UMP and no ATT. 13 to 17 get non-personalised, G-rated ads. The owner may later consider child-directed contextual ads for under 13, so that option is covered in full.

**This is not legal advice.** It is a builder's research summary. Section C lists what a lawyer must confirm before anything in section A3 ships.

Tags: **[verified]** = read on the primary source on the access date. **[reported]** = from a secondary source (law firm, press, vendor blog). **[inferred]** = my reasoning or estimate; check it. Every web source below was accessed on 2026-11-07 unless another date is given. Builds on `docs/research/kids-revenue.md` and `docs/research/revenue-compensation.md`; it does not repeat their lever lists.

---

## 0. Where the app stands today (from the code)

- `AdGate.mayLoadAnyAd(isUnderThirteen:hasRemoveAds:)` returns false for under 13 and for Plus. `mayAskConsent` needs the same condition, and `mayAskTracking` is true only for `.eighteenPlus` (`WordFlora/Rules/AdGate.swift:94-105`) [verified, code].
- `AdsService.prepare` sets `maxAdContentRating = .general` for everyone and `ageRestrictedTreatment = .teen` for `.thirteenPlus`, else `.unspecified`. It runs UMP and then (adults only) ATT, then `MobileAds.shared.start` (`WordFlora/Ads/AdsService.swift:31-45`) [verified, code]. **No `.child` path exists.** Under-13 players never reach `prepare` at all.
- `AgeBand` has three cases: `under13`, `thirteenPlus`, `eighteenPlus` (`WordFlora/Rules/OnboardingFlow.swift:3`). Unknown (nil) is treated like under 13 for ads [verified, code].
- The app does not use the Declared Age Range API or PermissionKit anywhere in `WordFlora/` [verified, grep].
- Progress lives in the player's own iCloud private database. No first-party analytics exists [verified, `docs/setup/age-rating-and-privacy-label.md`].

**What this means legally today [inferred]:** for under-13 players the app sends no personal information to us or to any third party. Ads never start, CloudKit data is Apple's and in the player's own account, and there is no analytics. The COPPA duties that come from *collecting* a child's data are therefore mostly not triggered. That is the cheapest compliance position available.

---

## A. Technical and legal requirements for serving ads to under-13s

### A1. US federal: COPPA, as amended in 2025

| Point | Fact | Tag / source |
|---|---|---|
| Dates | Amended Rule published 2025-04-22, **effective 2025-06-23**, **compliance required by 2026-04-22**. Safe-harbor provisions §312.11(d)(1), (d)(4) and (g) are excepted from that date. The Rule is fully enforceable now. | [verified] Federal Register: https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule |
| Mixed audience | A mixed-audience service is a subset of child-directed services: directed to children, but children are not its primary audience. The operator may not collect personal information from any visitor before asking age or otherwise determining whether the visitor is a child, except for the §312.5(c) exceptions. The age question must be asked "in a neutral manner that does not default to a set age or encourage visitors to falsify age information." Once a visitor says they are under 13, the operator "may not collect, use, or disclose the child's personal information without first complying with the Rule's notice and parental consent provisions." | [verified] same Federal Register page |
| Mixed audience in practice | The service may not deny under-13 users access. It may require consent for them, or give them an experience that collects no personal information. Users of 13 and over may be handled without parental consent. | [reported] Fenwick, Jan 2025: https://www.fenwick.com/insights/publications/coppas-coming-of-age-key-compliance-changes-in-ftcs-final-rule |
| "Directed to children" evidence | The FTC may now also weigh marketing materials, representations to third parties, user and third-party reviews, and the ages of users on similar services. Garden-and-flower art plus a children's age band invites the question. | [reported] Fenwick, same URL |
| Actual knowledge | An app that is general audience (not directed to children) has COPPA duties for a user once it has actual knowledge the user is under 13. A self-declared "under 13" on WordFlora's age screen is actual knowledge for that user. | [inferred] from the Rule's structure; lawyer to confirm |
| **Contextual ads without consent** | Persistent identifiers may be collected without verifiable parental consent (VPC) when used only for "support for the internal operations" of the service. The enumerated purposes include serving **contextual advertising** and **capping ad frequency**. They may not be used to contact a specific person, build a profile, or serve behavioural ads. | [reported] Fenwick (same URL); FTC kept the exception unchanged per McDermott: https://www.mcdermottlaw.com/insights/ftc-finalizes-amendments-to-the-childrens-online-privacy-protection-rule/ |
| New notice duty for that exception | The online privacy notice must name the specific internal operations for which identifiers are collected, and the measures used to stop them being used to contact or profile the child. The exception removes the *consent* duty, not the *notice* duty. | [reported] Fenwick (same URL); citations given as 16 CFR 312.4(d)(3) and 312.5(c)(7), not checked against the CFR text |
| Separate consent for disclosure | Disclosing a child's data to third parties for money, for **targeted advertising** or for AI training needs a **separate** parental consent, in addition to consent for collection. Notices must name the third parties and their categories. | [reported] Fenwick (same URL); Perkins Coie: https://perkinscoie.com/insights/update/ftc-announces-new-childrens-privacy-requirements-updated-coppa-rule |
| VPC methods | Card transactions no longer need a charge if the account holder is notified of each transaction. Knowledge-based questions and photo-ID-to-selfie face match are now approved. "Text plus" (like email plus) is approved **only when no child data is disclosed to third parties**. | [reported] Fenwick (same URL) |
| Retention and security | A **written data retention policy** is required: purposes, business need and a deletion timeframe, with no indefinite retention. A **written information security program** is required. An existing program covering all personal information is enough. | [reported] Fenwick (same URL) |
| Penalties | Up to **$53,088 per violation**: the FTC Act §5(m)(1)(A) figure, adjusted 2025-01-17. Amounts are unchanged for 2026. Continuing violations may count per day. | [reported] Federal Register: https://www.federalregister.gov/documents/2025/01/17/2025-01361/adjustments-to-civil-penalty-amounts ; ZwillGen summary: https://www.zwillgen.com/ftc-state-ag/ftc-enforcement-actions-just-got-lot-expensive |
| Recent cases | **Apitor** (2025): a kids' app shipped a third-party SDK that collected geolocation without notice or VPC. Penalty $500K (suspended), plus a duty to make sure every third-party SDK complies. **Disney** ($10M, approved and announced 2025-12-31): kids' videos mislabeled as not "Made for Kids". **HoYoverse/Genshin** ($20M): COPPA violations plus loot-box odds; purchases by under-16s now need parental consent. | [reported] Mintz, 2025-09-05: https://www.mintz.com/insights-center/viewpoints/2826/2025-09-05-ftc-coppa-enforcement-still-alive-and-well ; Hunton: https://www.hunton.com/privacy-and-cybersecurity-law-blog/court-approves-disneys-10-million-ftc-settlement-resolving-coppa-enforcement-action ; PC Gamer: https://www.pcgamer.com/games/rpg/ftc-says-genshin-impact-deceived-children-and-orders-its-publisher-to-pay-a-usd20-million-fine-and-stop-selling-loot-boxes-to-kids |

**COPPA reading for WordFlora [inferred, lawyer to confirm]:** child-directed contextual ads from AdMob send the child's IP address and device information to Google. Those count as persistent identifiers. That is lawful without VPC **only** if:
- Google uses them solely for contextual serving, frequency capping and other internal operations;
- the privacy policy carries the new internal-operations notice; and
- the retention and security documents exist.

Apitor is the warning case: the operator is liable for what its SDK does.

### A2. US states

| Law | What it requires | Status | Tag / source |
|---|---|---|---|
| **California CCPA §1798.120(c)** | No sale or sharing of personal information of consumers known to be under 16 without opt-in. A parent opts in for under-13s, the consumer for 13 to 15. "Willfully disregards the consumer's age" counts as actual knowledge. Cross-context behavioural ads count as "sharing". | In force. AB 1949 (raising the age to 18) was opposed by industry; I did not confirm its fate (my recollection is a 2024 veto) | [reported] Justia code text: https://law.justia.com/codes/california/2022/code-civ/division-3/part-4/title-1-81-5/section-1798-120/ ; leginfo returned 403 |
| **California AB 1043, Digital Age Assurance Act** | Developers must request an age signal from the OS or app store at download and launch. Receiving it gives "actual knowledge" of the age bracket: under 13, 13-15, 16-17, 18+. The signal may not be shared with third parties beyond what the Act requires. Penalties up to $2,500 per affected child (negligent) and $7,500 (intentional). | Effective **2027-01-01**. Accounts and apps that already exist get until 2027-07-01 per some sources. Amended since signing; text not reviewed | [reported] Hunton: https://www.hunton.com/privacy-and-cybersecurity-law-blog/california-introduces-new-age-verification-requirements-for-software-applications ; Kelley Drye FAQ: https://www.kelleydrye.com/viewpoints/blogs/ad-law-access/faq-digital-age-assurance-act-california-youth-safety-on-the-internet |
| **Texas SB 2420, App Store Accountability Act** | Use the Declared Age Range API for new Texas accounts. Get parental consent for a minor's download. Re-obtain consent after a "significant change". Support parental revocation. Up to $10,000 per violation. | A district court enjoined it in Dec 2025. The 5th Circuit stayed the injunction, and the law took effect **2026-06-04** per MacRumors. Litigation continues. A May 2026 consultancy newsletter still called it "on hold", so check the current status | [reported] MacRumors, 2026-06-03: https://www.macrumors.com/2026/06/03/apple-app-store-texas-sb-2420 ; 9to5Mac, 2025-12-23: https://9to5mac.com/2025/12/23/texas-judge-blocks-state-app-store-age-verification-law/ |
| **Utah and Louisiana** | Apple shares age categories through the Declared Age Range API for **new** accounts: Utah from **2026-05-06**, Louisiana from **2026-07-01**. Developers must handle significant-update consent. Utah: parents can recover up to $1,000 per violation. Louisiana: up to $10,000 after a 45-day cure period. | Dates are Apple's. A consultancy gives Utah as 2027-05-06, which conflicts; Apple's date is preferred | [verified] Apple, 2026-02-24: https://developer.apple.com/news/?id=f5zj08ey ; penalties [reported] MacRumors: https://www.macrumors.com/2026/02/24/apple-updated-age-assurance-requirements/ |

**Implication [inferred]:** the age-assurance laws apply **whether or not kids see ads**. They are about knowing age and getting consent for minors' downloads and significant updates. If kids do see ads, an accurate age band carries much more weight: a Declared Age Range answer of "under 13" is actual knowledge, and showing that user anything other than child-directed ads would be a clear violation.

### A3. EU, UK and other regions

| Item | Fact | Tag / source |
|---|---|---|
| GDPR Art. 8 | When consent is the legal basis for a service offered directly to a child, processing is lawful from age 16. Member states may lower this, but not below 13. Under that age, a parent must give or authorise consent, and the controller "shall make reasonable efforts to verify" it. | [verified] https://gdpr-info.eu/art-8-gdpr/ |
| Member-state ages | They vary from 13 to 16 (for example 13 in Belgium and the Nordics, 14 in Italy and Spain, 15 in France, 16 in Germany, Ireland and the Netherlands). | [reported], from memory and secondary lists; confirm per market |
| AdMob TFUA | `tagForUnderAgeOfConsent` disables personalised ads, including remarketing, and disables requests to third-party ad vendors. **It is not forwarded to mediation adapters.** | [verified] https://developers.google.com/admob/ios/targeting |
| UK Children's Code (AADC) | Applies to under-18s with the UK digital-consent age at 13 [reported, general knowledge]. Standard 12: profiling off by default unless there is a compelling reason; profiling for targeted ads should be off by default. A DPIA (Standard 2) is expected for services likely to be used by children. | [reported] ICO code PDF: https://ico.org.uk/media/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services-2-1.pdf (ICO HTML pages returned 403) |
| UK/EU contextual ads | Contextual, non-profiled ads are not banned by the AADC. Nudge and fairness standards still apply, and a rewarded ad that gives a child in-game resources is a nudge to assess [inferred]. The EU DSA Art. 28 ban on profiling-based ads to minors applies to "online platforms"; WordFlora hosts no user content, so probably not [inferred]. | |
| Australia, Brazil, Singapore | Apple blocks 18+ downloads there without age confirmation (from 2026-02-24). Not directly relevant at a 4+/9+ rating. | [verified] Apple news, same URL as A2 |

### A4. Apple rules

| Rule | Verbatim or close summary | Tag |
|---|---|---|
| **1.3 Kids Category** | No links out, purchases or "other distractions" unless behind a parental gate. Kids Category apps "may not send personally identifiable information or device information to third parties" and "should not include third-party analytics or third-party advertising". Limited exceptions: analytics that collect no IDFA or identifying data, and "third-party contextual advertising… provided that the services have publicly documented practices and policies for Kids Category apps that include human review of ad creatives for age appropriateness." Once customers expect Kids rules, the app must keep meeting them even if it leaves the category. | [verified] https://developer.apple.com/app-store/review/guidelines/ |
| **5.1.4(a)** | "Apps intended primarily for kids should not include third-party analytics or third-party advertising." Birthdate and parental contact may be asked only to comply with these laws, and the app must offer value regardless of age. | [verified] same URL |
| **5.1.4(b)** | The limited exceptions follow 1.3. Any app that can share a minor's personal information, including "persistent identifiers used in combination with any of the above", needs a privacy policy and compliance with children's privacy laws. The Kids parental gate "is generally not the same as" COPPA consent. Outside the Kids Category, nothing in name, subtitle, icon, screenshots or description may imply the main audience is children. | [verified] same URL |
| **2.3.8** | "For Kids" and "For Children" are reserved for the Kids Category. Metadata must be 4+ appropriate. | [verified] same URL |
| **2.5.18** | Ads must suit the app's age rating, let the user see the information used to target them, and may not be targeted or behavioural based on data "from kids (such as from apps in the App Store's Kids Category)". | [verified] same URL |
| **2.3.6** | Answer the age-rating questions honestly. | [verified] same URL |
| ATT for minors | The "Allow Apps to Request to Track" setting cannot be turned on "for users with child accounts or who are under age 18 by birth year". So the **IDFA is unavailable for every under-18 Apple Account** whatever the app does. | [verified] https://support.apple.com/en-us/102420 |
| Ask to Buy | On by default and cannot be turned off for children under 18 (varies by region). Child purchases need a parent's approval. | [verified] https://support.apple.com/en-us/105055 |
| Age ratings | Tiers are 4+, 9+, 13+, 16+, 18+ from 2026-01-31. Advertising does not on its own raise the tier. | [verified, via repo doc] `docs/setup/age-rating-and-privacy-label.md` A1-A2 |
| Declared Age Range API and PermissionKit | Returns an age category, plus signals for whether regulatory requirements apply, whether sharing is required, and whether a parent must approve significant updates. Available worldwide on iOS 26+. A Significant Change API is in PermissionKit, and StoreKit has a new age-rating property. "Developers may have separate obligations to independently confirm that their users are adults." | [verified] Apple, 2026-02-24, same URL as A2 |
| SKAdNetwork | Apple's attribution works without the IDFA. Nothing found says it is barred for kids outside the Kids Category; it is in the ad network's flow, not ours. Keep the `SKAdNetworkItems` in `Info.plist`. | [inferred] |

**Kids Category stays off.** Joining it would bar AdMob unless AdMob met the human-creative-review exception for Kids Category apps. I found no public Google statement that AdMob qualifies [inferred]. It would also bind future updates.

### A5. Google AdMob (iOS SDK 13.x, already in the app)

| Item | Fact | Tag / source |
|---|---|---|
| `ageRestrictedTreatment` | `.child`, `.teen`, `.unspecified`. It replaces the deprecated `tagForChildDirectedTreatment` (TFCD) and `tagForUnderAgeOfConsent` (TFUA). TFCD/TFUA = true maps to **Child**; Teen has no old equivalent. If both systems are set, "Google applies the most conservative treatment." The SDK sends a `tfat` parameter. Supported mediation adapters forward the signal. | [verified] https://developers.google.com/admob/ios/targeting |
| What Child treatment disables | For TFCD = true, Google "takes steps to disable IBA [interest-based ads] and remarketing ads" and "prevents the transmission of the Advertising Identifier, IDFA". TFUA also disables requests to third-party ad vendors such as measurement pixels and third-party ad servers. "Abuse of this setting may result in termination of your Google Account." | [verified] same URL |
| `maxAdContentRating` | `.general` (G), `.parentalGuidance`, `.teen`, `.matureAudience`. SDK settings override the AdMob UI. The app already sets G for everyone. | [verified] same URL |
| **Bidding** | "Ads for which child-directed treatment applies aren't eligible to be sent to third-party RTB bidders", for example requests tagged child-directed or under-age-of-consent. Only AdMob's own demand and waterfall line items compete. | [reported] AdMob Help via search: https://support.google.com/admob/answer/10833943 ; consistent with the GameBiz newsletter below |
| Fill | Google warns that after narrowing an app's audience to children "you might notice fewer filled impressions"; child- and family-friendly ads are "a subset of the broader ads pool". | [verified] https://support.google.com/admob/answer/6223431 (Android-oriented page) |
| Families Ads Program / certified SDKs | This is a **Google Play** policy: child-only Android apps must use Families self-certified ad SDKs, and AdMob blocks uncertified sources for them. It does not bind an iOS app. | [verified] same URL; https://support.google.com/googleplay/android-developer/answer/9893335 |
| Formats | No Google page I read limits banner, interstitial or rewarded under Child treatment. All three appear to remain, with a thinner contextual demand pool. | [inferred] Google is silent; test with real traffic |
| UMP | Setting `isTaggedForUnderAgeOfConsent = true` on `RequestParameters` means the SDK does not request consent, so no form shows. Do not call the form path for children at all. | [reported] Google US IAB guide: https://developers.google.com/admob/ios/privacy/us-iab-support ; Google forum thread: https://groups.google.com/g/google-admob-ads-sdk/c/n6uNOAcyyz4 |
| UI setting trap | The AdMob console has an app-level child-directed setting. Turning it on treats **every** user as a child and costs adult eCPM. A consultancy warns that "just to be safe" tagging could cost "70% of your eCPM" on all users. Tag per request (per user) instead. | [reported] GameBiz Consulting, about May 2026: https://www.gamebizconsulting.com/newsletter/admon-newsletter-11-the-shrinking-island-ad-monetization-underage-users |

### A6. Mediation partners (only if mediation is added later)

| Network | Child traffic | Tag / source |
|---|---|---|
| AppLovin | From SDK 13.0.0 it does not support age-restricted flags, and you "may not initialize or use the AppLovin SDK in connection with a 'child'". Already removed from the WordFlora plan. | [reported] Google AppLovin mediation guide: https://developers.google.com/admob/android/mediation/applovin ; DT FairBid: "Adapter will not start if isChild is true": https://docs.digitalturbine.com/dt-fairbid/privacy/regulatory-compliance-for-mediated-networks |
| ironSource Direct | Deprecated 2026-04-30. ironSource Exchange never served COPPA users. | [reported] GameBiz, same URL |
| Unity Ads, Liftoff/Vungle, InMobi, DT Exchange, Chartboost, Mintegral | Accept a child flag (DT FairBid table). GameBiz names Unity, Liftoff, DT Exchange, InMobi, Kidoz and SuperAwesome as the remaining COPPA demand, and says Unity is awkward on AdMob because it is bidding-only. | [reported] same two URLs |
| Meta Audience Network | No child-flag support documented ("N/A" in the DT table). Treat it as **not for under-13 requests**. | [reported] DT table; Meta policy not read |
| Kidoz, SuperAwesome | Kids-specialist networks. No public CPMs; floors are negotiated with an account manager. | [reported] Kidoz SDK guide: https://kidoz.net/sdk-guide |

**Rule [inferred]:** each mediated SDK collects data itself, so under COPPA each one is "your" third party (the Apitor lesson). TFUA is not forwarded to adapters. If WordFlora ever serves children, the cheapest safe design is **AdMob demand only for child requests**, because third-party bidders are excluded anyway.

### A7. Privacy manifest and App Privacy label

- The label is one answer for the whole app. It already declares Device ID (tracking), Advertising Data, Product Interaction, Coarse Location and Diagnostics from AdMob. Serving child-directed ads adds **no new data types** [inferred from `docs/setup/age-rating-and-privacy-label.md` B1]. The children's rule lives in the privacy policy, not the label.
- `PrivacyInfo.xcprivacy` needs no change for a `.child` path. Re-run Xcode's Privacy Report if any SDK version changes [inferred].
- The **privacy policy must change** in scenario 2 (A1 notice duty). It needs a children section that names Google as the ad provider and contextual serving and frequency capping as the internal operations, says the IDFA is never used, and describes the means that prevent profiling (Child treatment, no ATT, no UMP, G rating). It must also include or point to the retention policy [reported, A1].

### A8. Checklist: what WordFlora would build and file

**Current approach (no ads under 13): what is still owed anyway**

| # | Item | Why | Builder-hours |
|---|---|---|---|
| 1 | Declared Age Range API at launch and on age change. Map its range to `AgeBand`, keep the neutral screen as the fallback, and **never upgrade** a DAR "under 13" to an older band | TX/UT/LA now; CA from 2027-01-01 | 8-14 |
| 2 | PermissionKit Significant Change flow for regulated minors (TX/UT/LA) | Same laws | 4-8 |
| 3 | Privacy-policy children section: "under 13 and unknown age: no ads, no SDK, no data sent" | COPPA notice, Apple 5.1.4(b) | 2 |
| 4 | One-page retention note and security note (light, because no child data is collected) | Amended COPPA hygiene [inferred] | 2-3 |
| 5 | EEA teens under their national consent age (13-15): today they get `.teen`. Decide whether they should get Child treatment or TFUA. TFUA is not forwarded to mediation | GDPR Art. 8; noted as a gap in the age-rating doc | 2-4 |
| 6 | Unit test that DAR or screen "under 13" never reaches `prepare`, UMP or ATT. The gate itself already exists | Regression guard | 1-2 |
| | **Total** | | **19-33 h**, plus a short lawyer review of the policy |

**Scenario 2 (child-directed contextual ads under 13): extra on top of the list above**

| # | Item | Detail | Builder-hours |
|---|---|---|---|
| 1 | Lawyer sign-off **before** code | COPPA internal-ops reliance, CCPA, UK DPIA scope, privacy-policy text | 0 (owner and lawyer, est. $1.5k-5k [inferred]) |
| 2 | `AdGate` split | `mayLoadAnyAd` gains a `kidsAdsEnabled` remote flag (default **off**). Unknown age stays no-ads. Keep all existing caps, and add a kids cap (for example interstitial every 4th round, max 3/day) | 3-5 |
| 3 | `AdsService` child path | Set `ageRestrictedTreatment = .child` and `maxAdContentRating = .general` **before** `MobileAds.shared.start`. Skip UMP entirely (or set `isTaggedForUnderAgeOfConsent = true`). No ATT. Use a separate `prepare` branch so the adult flow is untouched. Handle a mid-session band change by restarting the app, because `requestConfiguration` holds for the session | 4-6 |
| 4 | Separate kids ad units (banner, interstitial; rewarded optional) | Clean reporting and the ability to block or pause kids units alone | 1-2 |
| 5 | Rewarded for kids: decide | Rewarded ads that pay water are an engagement nudge under the ICO and FTC lens. Recommend **no rewarded for under 13** | 1 |
| 6 | AdMob console | Do **not** set app-level child-directed. Turn sensitive categories off for kids units. Set a G cap. Review creatives in Ad Review Center weekly | 2 now, plus 0.5-1 h a week |
| 7 | Mediation | Child requests use AdMob demand only. If partners are added later, verify each adapter's child behaviour and keep Meta and AppLovin out of child requests | 0 now; 3-6 per partner later |
| 8 | Privacy policy and notices | Internal-ops notice (A1 and A7), named third party, retention policy, security program | 4-6 (drafting) |
| 9 | UK/EU DPIA (AADC Standard 2) for the kids ad path | One document | 4-6 |
| 10 | Tests | Gating matrix (DAR × band × Plus × flag), a UI test with a test ad unit, and a check that no ATT or UMP is presented for a child | 4-6 |
| 11 | App Review notes | Explain the mixed-audience design, the neutral screen, contextual-only ads for under 13, and no IDFA | 1 |
| 12 | Monitoring | AdMob report by kids unit; watch for complaints. Kill switch through the remote flag | 1-2 |
| | **Total** | | **25-41 h extra** (about **45-75 h** including the first list), plus the lawyer fee and the weekly creative review |

---

## B. Revenue

### B1. Benchmarks

| Metric | Number | Tag / source |
|---|---|---|
| COPPA vs non-COPPA eCPM | COPPA eCPMs are "2.5 to more than 5 times lower" than non-COPPA traffic, so a child request earns **20-40%** of an adult one | [reported] GameBiz, about May 2026 (URL in A5) |
| Kids vs puzzle vertical (US) | Education/kids: rewarded $6-11, interstitial $4-8, ARPDAU $0.02-0.05. Puzzle/casual: rewarded $15-22, interstitial $10-15, ARPDAU $0.07-0.16. That is about **40-55%** of puzzle | [reported] RevenueLab, 2026-06-17; the author labels the tables "illustrative planning assumptions", not measured averages: https://www.revenuelab.fyi/blog/admob-ecpm-benchmarks-2026 |
| General US/Tier-1 by format | Rewarded $14-22, interstitial $9-14, adaptive banner $0.40-0.80 (same caveat). Tier-2 index 0.35-0.60× of US, Tier-3 0.05-0.18× | [reported] RevenueLab, same URL |
| General US iOS (older data) | Banner about $1; interstitial and rewarded about $23-24 (2024) | [reported] Udonis, cited in `revenue-compensation.md` [3] |
| Why child eCPM is lower | No interest or remarketing targeting and no IDFA (Google). Third-party RTB bidders are excluded, so there is less competition per impression. The advertiser pool is smaller ("a subset of the broader ads pool"), and so are budgets for kids-safe inventory. Measurement pixels are off, so performance advertisers bid less | [verified] Google targeting page and support 6223431; [reported] AdMob bidding page; [inferred] measurement effect |
| Fill rate | No public number found. Google says only "fewer filled impressions". **Assume 60-90%** of adult fill | [inferred] |
| Kids ad-mediation case | TutoTOONS (kids publisher) grew ad revenue 20% after adding AdMob rewarded and interstitial. Vendor marketing; no eCPMs | [reported] https://admob.google.com/home/resources/tutotoons-ensures-ad-safety-and-boosts-revenue-20-percent-with-google-admob/ |
| Casual ARPDAU | Ads-only casual $0.01-0.05; hybrid $0.15-0.50 | [reported] Playio, cited in `revenue-compensation.md` [9] |
| Education subscription funnel | Install-to-trial 10.9%, trial-to-paid 25.6% (Adapty 2025, education apps, not kids-only). Median prices: $12.99/month, $38.42/year | [reported] https://adapty.io/blog/education-app-subscription-benchmarks/ |
| General freemium | 2.18% download-to-paid by day 35; 44.1% annual retention at 1 year | [reported] RevenueCat 2025, cited in `revenue-compensation.md` [13] |
| Kids subscription example | Lingokids (freemium plus subscription), US Q2 2024: weekly revenue $253K-293K (Sensor Tower). Raised $120M on 2025-09-17 | [reported] https://sensortower.com/blog/2024-q2-unified-top-5-toddlers%20games-revenue-us-642b50fae1714cfff1ccbece ; https://lingokids.com/press/linogkids-raises-120m-in-funding-to-expand-its-position |
| Kids bundles | Spin Master's Piknik (Toca, Sago, Originator) at about $11.99/month | [reported] cited in `kids-revenue.md` |
| Parent-gated conversion | **No public figure found.** Ask to Buy is on for every under-18 child account [verified, A4], so a child's purchase becomes a parent approval request. That adds friction, but the request lands with the actual buyer | [inferred] |
| Family Sharing | Better engagement and retention, but fewer subscriptions sold per family | [reported] RevenueCat, cited in `revenue-compensation.md` [17] |

Kids-specific ARPDAU, fill and parent-gate conversion are thin. All three are marked inferred in the model.

### B2. Model

**Shared inputs.** These are the base case from `revenue-compensation.md`, so the two documents agree:
- MAU = M; base M = 10,000, and results scale linearly.
- DAU/MAU = 0.25.
- Adult free-player ad revenue per daily player: `A = (6 × $0.8 + 1.0 × $8 + 0.3 × $12) / 1000 = $0.0164`.
- Ad revenue per adult MAU per month: `R = A × 30 × 0.25 = $0.123`.
- Teens are 15% of MAU with a non-personalised factor of 0.7. Adults are the rest after under-13 and teens.
- Under-13 share s = 10% / 25% / 40% (low / base / high). Unknown age counts as under 13.
- Plus payers are ignored in the ad lines (1-3% of players); the effect is small.

**Formulas**
- (1) Today: `Ads₁ = M × [(1 − s − 0.15) × R + 0.15 × R × 0.7]`
- (2) Child-directed: `Ads₂ = Ads₁ + M × s × R × k × f × c`, where:
  - k = child eCPM factor: 0.20 / 0.33 / 0.50 (from GameBiz 0.2-0.4 and RevenueLab 0.4-0.55);
  - f = fill factor: 0.6 / 0.8 / 0.9 [inferred];
  - c = cadence factor: 0.7 if kids get no rewarded and a softer interstitial cap (A8 #2, #5), else 1.0.
- (3) Non-ad levers, per under-13 MAU per month: `L = Δp × $1.31 + b × $2.99 × 0.85 + l × $34.99 × 0.85 × (1 − x)`, where:
  - Δp = extra parent Plus conversion;
  - $1.31 = net Plus revenue per payer per month (from `revenue-compensation.md`);
  - b = starter-pack buyers per month;
  - l = lifetime buyers per month;
  - x = share of lifetime sales cannibalising annual Plus.

**Kids ad yield per under-13 MAU per month, `R × k × f × c`** (all [inferred]):

| | k × f | c = 1.0 (same ads as adults) | c = 0.7 (no rewarded, softer cap) |
|---|---|---|---|
| Low | 0.20 × 0.6 = 0.12 | $0.0148 | $0.0103 |
| Base | 0.33 × 0.8 = 0.264 | $0.0325 | $0.0227 |
| High | 0.50 × 0.9 = 0.45 | $0.0554 | $0.0388 |

**Results at 10,000 MAU, US$ per month.** Rows are the under-13 share s; kids ads use the base yield with c = 1.0 and the low-high range in brackets.

| s | (1) Ads today, 13+ only | (2) Kids ads added | (2) Total | Uplift | (3) Non-ad levers, base |
|---|---|---|---|---|---|
| 10% (1,000 kids) | 7,500 × 0.123 + 1,500 × 0.086 = **$1,052** | **+$33** ($15-55) | $1,085 | +3% | **+$47** |
| 25% (2,500 kids) | 6,000 × 0.123 + 129 = **$867** | **+$81** ($37-139) | $948 | +9% | **+$117** |
| 40% (4,000 kids) | 4,500 × 0.123 + 129 = **$683** | **+$130** ($59-222) | $813 | +19% | **+$186** |

Scaling: multiply by 0.1 for 1,000 MAU and by 10 for 100,000 MAU. At 100k MAU and s = 25%, kids ads add about **$810 a month** (range $370-1,390).

**Non-ad lever inputs, base [inferred]:**
- Δp = +1.0 pp parent Plus, through a parent-gated "For grown-ups" Plus page and a parent report: $0.0131 per kid MAU.
- Starter pack (cosmetic pots and seeds, $2.99, parent-gated, non-consumable), b = 0.5%/month: $0.0127.
- Lifetime "Grand Garden" ($34.99), l = 0.1%/month, x = 30%: $0.0208.
- Sum: L ≈ **$0.047 per kid MAU per month**. That beats base child-directed ads ($0.0325) and comes with no new legal surface.

The parent levers also work for 13+ households, which is not counted here. Ask to Buy friction is the main downside risk to b and l.

**Payback on scenario 2 [inferred]:**
- One-off cost: about 25-41 h of builder time plus about $1.5-5k of legal fees, plus about 0.5-1 h a week of creative review.
- At 10k MAU and s = 25%, the +$81 a month repays a $3k legal fee in about **37 months**, before builder time.
- At 100k MAU, the +$810 a month repays it in about **4 months**.

**Second-order effects not modelled [inferred]:**
- Kids ads may *raise* parent Plus purchases ("remove ads").
- They also remove the "no ads for children, ever" promise, which is the brand's best message to parents (`kids-revenue.md`).
- They make App Review's 5.1.4(a) question ("intended primarily for kids?") easier to raise.

---

## C. Recommendation

**Do not serve ads to under-13 players in 1.1.** Keep today's rule and spend the effort on the owed age-assurance work (A8, first list) and the parent-gated levers (B2, scenario 3).

Why:
1. **Money.** At 10k MAU, base child-directed ads add about $33-130 a month (3-19% of ad revenue) depending on the kids share. Parent-gated levers earn more per kid player without new law.
2. **Exposure today is near the floor [inferred].** No personal information leaves the device for under-13s, so COPPA's collection, consent, disclosure and retention duties are barely engaged. The main remaining exposures are:
   - age-assurance compliance (TX, UT, LA now; CA 2027);
   - the neutral age screen;
   - metadata that must not imply the app is for kids (2.3.8, 5.1.4(b));
   - EEA teens under their consent age.
3. **Exposure with kids ads is real but manageable [inferred].** You would rely on the internal-operations exception, which needs exact notice wording, retention and security programs, and Google behaving as documented. A misconfigured SDK or a mediation partner that ignores the flag is the Apitor pattern. Penalties reach $53,088 per violation (FTC) and $2,500-10,000 per child or violation under state laws. An app-level child-directed toggle mistake costs adult eCPM instead.
4. **Brand.** "No ads for children" is a selling point to the buyer (parents). Contextual ads give it up for a small sum.

**Revisit when** MAU is above about 50-100k with a measured under-13 share of 25% or more. At that scale scenario 2 pays back in months, not years. Re-check then whether AdMob's kids demand has improved.

**Cheapest path if the owner still wants kids ads in 1.1** (about 25-30 h plus legal, using the A8 scenario-2 list):
1. Lawyer approves the privacy-policy children section and the internal-operations reliance first.
2. A remote flag, default off; unknown age still gets no ads.
3. A child branch in `AdsService.prepare`: `.child` treatment, G rating, no UMP (or `isTaggedForUnderAgeOfConsent = true`), no ATT, configured before `start`.
4. AdMob demand only. Banner on Home and Garden plus the existing interstitial caps, made softer. **No rewarded for kids.**
5. Separate kids ad units; never the app-level child-directed toggle.
6. Gating-matrix tests, App Review notes and a weekly creative check.

**What a lawyer must confirm**
1. That WordFlora's under-13 path is "mixed audience" or general audience with actual knowledge, and what follows for notice and consent.
2. That AdMob's Child treatment on iOS (IP and device data to Google) fits COPPA's support-for-internal-operations exception, and the exact §312.4(d)(3) notice wording.
3. Whether a written retention policy and security program are required today (no child data collected) or only in scenario 2.
4. The current status of TX SB 2420 (5th Circuit), the Utah date (May 2026 vs 2027) and the CA AB 1043 amendments, and what "significant change" means for WordFlora.
5. CCPA §1798.120(c) and whether AB 1949 or later bills changed the age threshold.
6. GDPR Art. 8 handling for EEA 13-15s (`.teen` vs Child/TFUA), and whether a DPIA under the UK Children's Code is needed even with no kids ads.
7. Whether ticking "age assurance" in App Store Connect for a self-declared screen is accurate once the Declared Age Range API is available.

---

## 8 takeaways

1. **Today's design is the legal floor and the cheapest one:** no SDK, UMP, ATT or data for under-13 and unknown age means almost no COPPA surface [inferred].
2. **Contextual kids ads are legal without parental consent only under COPPA's internal-operations exception.** That still needs new privacy-notice wording, a retention policy and a security program (amended Rule, compliance from 2026-04-22) [reported].
3. **On iOS the technical switch is small:** `ageRestrictedTreatment = .child`, G rating, skip UMP, no ATT, set before `start`. Never use the app-level child-directed toggle [verified Google docs].
4. **Child requests lose third-party bidding, interest ads, remarketing and the IDFA,** and the IDFA is blocked by Apple for every under-18 account anyway [verified].
5. **Child eCPM is about 20-55% of adult and fill is lower,** so a kid player is worth about $0.01-0.06 a month in ads at WordFlora's caps [reported and inferred].
6. **At 10k MAU, kids ads add about $33-130 a month (3-19%).** Parent-gated Plus, a starter pack and a lifetime unlock add about $47-186 with no new legal surface [inferred].
7. **Age-assurance laws (TX/UT/LA now, CA from 2027-01-01) apply whatever you decide on ads.** Build the Declared Age Range API and Significant Change support first: about 12-22 of the 19-33 hours owed [verified Apple; reported state laws].
8. **Recommendation: no ads for under-13 in 1.1.** Revisit above about 50-100k MAU with a measured kids share of 25% or more, and only after a lawyer signs off. If done, use AdMob only, no rewarded, a default-off flag, about 25-41 extra builder-hours plus a lawyer fee [inferred].

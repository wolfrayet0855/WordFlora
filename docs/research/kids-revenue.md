# Kids (under-13) revenue options for WordFlora

Research date 2026-11-06. Revenue ranges are my estimates, not sourced figures. Verify legal points with counsel before shipping.

## Hard facts (not negotiable)

- Apple 1.3 and 5.1.4: Kids Category apps must not have links out, purchases or other distractions outside a parental gate, and should not include third-party analytics or advertising. Limited exceptions: contextual ads from services with public kids-app policies and human review of creatives; analytics that collect no IDFA or identifiable data. A parental gate is not COPPA parental consent. Apps not in the Kids Category may not use "for kids" terms in metadata. https://developer.apple.com/app-store/review/guidelines/
- Apple allows gifting of IAP items, refundable only to the buyer (3.1.1, same URL).
- COPPA amended rule: published 2025-04-22, effective 2025-06-23, full compliance 2026-04-22. It is enforceable now. Separate parental consent is required for disclosing child data to third parties (for example ad networks), and written retention and security policies are required. https://www.finnegan.com/en/insights/articles/coppas-amended-rule-is-now-in-full-effect-what-operators-need-to-know.html and https://www.hunton.com/privacy-and-cybersecurity-law-blog/coppa-rule-amendment-compliance-deadline-approaches
- UK Children's Code and the ICO games guidance: profiling for marketing is off by default, neutral purchase buttons, no nudges toward weaker privacy, risk-assess time-limited offers, and positive nudges such as break prompts are encouraged. https://www.mondaq.com/ireland/privacy-protection/1301342/new-ico-guidance-on-childrens-data and https://mishcon.com/news/ico-publishes-new-top-tips-for-games-designers
- Google Families (Android, if ever relevant): child-directed ads must come from self-certified SDK versions. The program's intake status is unclear, with some sources saying it closed to new applicants. https://support.google.com/googleplay/android-developer/answer/12918983
- GDPR-K: the age of digital consent is 13 to 16 depending on the member state. Treat under-16 EU users as needing parental consent for anything beyond core function (my reading; verify).

## Evaluation of models

Scores: legal for under-13 / App Review risk / effort / revenue (my estimate) / brand fit.

| Model | Legal | Review risk | Effort | Revenue | Fit |
|---|---|---|---|---|---|
| Parent-paid subscription (current Plus) | Yes, behind a parental gate | Low | Done | Core | High |
| One-time "Garden for Life" unlock (about $29.99) | Yes | Low | Low | Modest, adds a lifetime-value tier | High |
| Paid seasons / expansion packs (non-consumable IAP, such as a Japanese Garden or Desert pack) | Yes | Low | Medium (content) | $1-3 ARPPU on about 1-3% of players | High |
| Family bundle (Family Sharing already on; add a "Gift Plus" flow) | Yes | Low (gifting is permitted) | Low-Medium | Seasonal spikes | High |
| Parent dashboard / weekly "growth report" email or in-app (paid feature) | Yes if no child PII leaves the device or the report is parent-initiated | Low | Medium | Raises conversion | High |
| Physical: seed packets, plush, printed garden poster (print-on-demand web store) | Yes if sold to parents on web, outside the app | Low if linked only behind the gate | Medium | Small to medium | High |
| Classroom / teacher edition (annual per-teacher or per-school licence, via Apple School Manager) | Yes (schools can consent on parents' behalf under COPPA for school-authorized use) | Medium | High | Potentially large but slow | Medium-High |
| Libraries / B2G / vocabulary-curriculum licensing | Yes | Low | High | Lumpy | High |
| Licensing/publishing (word-list books, a picture book of the 50 plants) | Yes | None | Medium | Small, steady | High |
| Cross-promotion in own catalog | Yes if only first-party and behind the gate | Low | Low | Small | High |
| Affiliate to parents (gardening kits) | Yes if parent-facing, disclosed, and out-of-app | Medium | Low | Small | Medium |
| Donations / "sponsor a school garden" | Yes if parent-facing | Medium (outbound link) | Low | Small | Medium |
| Contextual-only child-directed ads | Legal only with a kids-certified network and no IDFA; Apple "limited cases" | High | Medium | Low CPMs | Poor (pressure, off-brand) |
| Sponsored content / brand tie-ins | FTC/ASA disclosure rules; kids are especially protected | Medium-High | Medium | Variable | Poor |

## Benchmarks (credibility caveats)

- RevenueCat State of Subscription Apps: higher-priced apps see about 9.8% median download-to-trial against 4.3% for low-priced ones. Longer trials (17-32 days) convert higher (42.5% against 25.5% for 4 days or fewer) per a secondary summary of the 2026 edition. The education breakout is gated; I could not verify kids-specific numbers. https://www.revenuecat.com/state-of-subscription-apps-2025 and https://www.revenuecat.com/state-of-subscription-apps-2026-education
- Planning assumption (mine, unverified): 1-3% of free users pay at steady state, with annual plans taking a majority of subscribers; a calm game with a 3-day trial is on the short end.
- Peers: Spin Master merged Sago Mini, Toca Boca and Originator apps into the Piknik bundle (about $11.99/mo), moving away from per-app sales. https://www.newswire.ca/news-releases/spin-master-launches-piknik-tm-a-new-preschool-app-subscription-service-837440663.html and https://techcrunch.com/2016/04/25/top-kids-app-maker-toca-boca-sells-to-spin-master-plans-to-launch-subscription-video-service-and-toys
- Khan Academy Kids is free, donation-funded, with some district/school licensing income. Clever shows the school-channel pattern: free for schools, developers pay per school. https://kahoot.com/files/2021/05/Clever_Introduction.pdf

## Ranked shortlist (do these)

1. **Make Plus the parent product, and sell the parent report inside it.** Add a parent-gated "Growth Report" (words learned, streak, favorite plants) shown only on the parent's device. Pros: no new legal surface, it speaks to the actual buyer, and it justifies the $12.99. Cons: it needs good design and the report must stay on-device. Do this first.
2. **Paid seasons / garden packs (non-consumable IAP).** Pros: matches the calm collection loop, no pressure, easy review. Cons: content cost, and packs must never gate core play or use countdown timers (ICO).
3. **Gift Plus / "Gift a garden" and a lifetime unlock.** Pros: peaks at holidays, grandparents are a natural buyer, gifting is allowed by Apple. Cons: the gift flow is the parent's task, so it must sit behind the gate and be in Plus-style copy that targets adults.
4. **Classroom edition (pilot).** Free teacher trial, then per-teacher annual licence, vocab lists aligned to grade levels, Apple School Manager distribution. Pros: the largest ceiling and a sticky B2B base. Cons: slow sales cycle, privacy-contract (DPA) requirements, support load. Start with a landing page and 5-10 pilot classrooms.
5. **Physical and licensed goods (seed packets with plant-themed word cards, a printed 50-plant book, a plush) sold on the web to parents.** Pros: brand extension and marketing, entirely outside the app's COPPA surface. Cons: fulfilment and inventory (use print-on-demand), and the link from the app must be gated.

## Recommendation: what to do first

Ship, in order: (a) parent report inside Plus, (b) one seasonal pack plus a Gift Plus flow before the holidays, (c) a teacher landing page and pilot. Keep the under-13 experience ad-free and tracker-free. That is both the legal floor and the brand's main selling point to parents; market it as such.

## Do not do

- Third-party ads, ad SDKs or attribution/analytics SDKs that read the IDFA for under-13s. Contextual kids ads are a distraction from the brand and a high review risk.
- Behavioral profiling, personalised offers or retargeting of under-13s.
- Loot boxes, randomised paid rewards, countdown or "last chance" offers, streak-loss purchases, or guilt mechanics (ICO, FTC "dark patterns").
- Letting a child reach a paywall, outbound link or review prompt without a real parental gate (the gate must not be a trivial tap).
- Referral or influencer programs that pay children, or sponsored content without clear disclosure.
- Using "for kids" in the App Store metadata while outside the Kids Category (Apple 5.1.4).
- Collecting child email, name or free-text chat. Selling or sharing child data with partners, including for "cross-promotion" targeting.
- Treating the Apple parental gate as COPPA consent.

## Open items

Kids-specific conversion, ARPU and annual/monthly mix were not available from ungated sources. Buy the RevenueCat education breakout or run your own 90-day experiment. Verify the Google Families status only if an Android release is planned.

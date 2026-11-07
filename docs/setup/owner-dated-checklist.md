# Owner dated checklist, 2026-11-07 to 2026-11-19

Drafted 2026-11-07 from `docs/pm/status-review-2026-11-07.md` (sections 1 and 5), `docs/pm/release-plan-extended.md` (section 3) and `owner-setup-steps.md`. Target submit date is **Thu 2026-11-19**; the PM says plan externally for **Mon 2026-11-23**. Each line names the gate it depends on (G0 to G6 are the builder gates in the release plan). Time estimates are from the plan. **[ASSUMPTION]** marks anything I inferred. Nothing here was verified in App Store Connect.

Gate key: G2b net and quick wings, G3 pack framework and Mist Maker (the only new stored field), G4 AppLovin via AdMob mediation in test mode, G5 full Frost & Lantern, G6 regression, Release build and TestFlight.

## Sat 11-07 (today) and Sun 11-08: start the long lead times

| Task | Gate it depends on or feeds | Time |
|---|---|---|
| **AppLovin**: sign up, create the iOS app record, get the SDK key, create three ad units (banner, interstitial, rewarded) for bidding. Approval takes 1 to 3 days and is the long pole. | Feeds G4 start (Thu 11-12) | 45 min |
| **AdMob**: add AppLovin as a bidding source on the mediation groups of the three units once the account is approved; link the account. | G4 | 30 min |
| **Paid Apps Agreement**: confirm it shows Active (Business > Agreements) and that tax and banking are done. Offer codes and real purchases need it. If Pending, finish tax/banking now (1 to 3 days). | Blocks offer codes and every paid test | 15 min check |
| Confirm the App Store Connect record exists under the name "WordFlora" (SKU `wordflora-ios-001`); if the name was taken, choose the fallback. | G6/submit | 10 min |
| Privacy policy page: add paragraphs for lifetime purchase, the pack, offer codes and AppLovin. Support page `support.html` live with a contact email. Confirm both URLs return 200. | Review rejection risk; submit | 1 h |
| Create the app-ads.txt file at the domain root with Google's line; add AppLovin's line when its account gives it. | G4; submit | 20 min |

## Mon 11-09 and Tue 11-10: App Store Connect products, codes, testers

| Task | Gate | Time |
|---|---|---|
| Create `plus_lifetime`: non-consumable, $34.99, Family Sharing ON (irreversible), name "Plus Forever" (see the naming note in `store-listing.md`), per A13. | G2 sandbox (Tue 11-10) | 30 min |
| Create `pack_frost_lantern`: non-consumable, $2.99, Family Sharing ON, name "Frost & Lantern", per the plan. Not submitted if G5 falls back. **[ASSUMPTION: price from the plan]** | G3 (Tue 11-10) | 30 min |
| Offer codes on `plus_yearly`: custom `GARDENFRIEND` (1 month free, auto-renew off, new subscribers) and `WELCOMEBACK` (3 months at 50 percent, expired subscribers), each with a redemption cap and end date; one one-time batch of 500 for reviewers and teachers. Needs Paid Apps Agreement Active. | G2 sandbox | 30 min |
| Sandbox testers: one plain tester; a second tester in a sandbox Family; one Ask to Buy child account (the Family needs a Family Sharing organizer). **[VERIFY in UI: sandbox Family setup]** Sign in on the device under Settings > Developer > Sandbox Apple Account. | G2 sandbox; G6 device checks | 20 min plus setup |
| Small Business Program: confirm enrollment (it applies 15 days after the end of the fiscal month of approval, so do it before launch). | Submit | 15 min |
| Send back the values block in section E of `owner-setup-steps.md` (product ids, tester email, AdMob ids). | G2/G4 | 10 min |

## Tue 11-10 (evening): playtest

| Task | Gate | Time |
|---|---|---|
| Playtest the net (Quick wings, Gentle Net) on the simulator the day G2b merges; decide turns vs the pre-decided fallback (drop turns, keep speed, hoop, perch). | G2b merge (expected Tue 11-10 morning) | 30 min |

## Wed 11-11 and Thu 11-12: CloudKit, once

| Task | Gate | Time |
|---|---|---|
| **CloudKit Development run**: on a device or simulator signed into iCloud, run the G3 debug build with sync on. Open the garden, a plant page, Mist a plant, the Shed. In the CloudKit Console (container `iCloud.beta.WordFlora`, Development) check that `CD_PlantCollectible` has `CD_lastMistedAt` and every field in `cloudkit-new-fields.md`. | Needs G3 merged (expected Thu 11-12 afternoon) | 45 min |
| **Deploy Schema Changes to Production**, once, the same evening. Do it before the TestFlight build; a second stored field after this means a second deploy. G2b, G4 and G5 must each report "no stored fields". | G3 merge; precedes G6 TestFlight | 15 min |
| Fact-check the four G5 facts (robin, wren, snowdrop, hellebore) against `docs/research/` sources by Fri 11-13; look at the scene and plants on localhost. | G5 start | 1 h |

## Fri 11-13: G5 art go/no-go (20:00)

| Task | Gate | Time |
|---|---|---|
| Accept or reject the G5 art. If rejected, approve the pre-decided fallback (dormant framework, pack to 1.1, no thin pack; submit moves up). **Needs your explicit approval; it is a scope change.** | G5 | decision |
| After G4 merges (expected Fri 11-13 afternoon): in AdMob Privacy & messaging add AppLovin to both the GDPR and US-state ad partner lists and republish both messages. Do NOT flip ad serving to live before submission. | G4 exit | 30 min |
| Add the AppLovin data types the G4 builder lists to the App Privacy label; re-check Purchases and User content answers. | G4 exit | 45 min |

## Sat 11-14 to Mon 11-16: forms and paperwork (no build needed)

| Task | Gate | Time |
|---|---|---|
| **Age rating**: Settings in ASC > App Information > Age Ratings > Set Up. Re-answer on Apple's new tiers (4+, 9+, 13+, 16+, 18+ **[VERIFY in UI]**). Answers: no violence, sexual content, profanity, horror, drugs, alcohol, tobacco, gambling, loot boxes; no unrestricted web access; no user-generated content or messaging; in-app controls: parental gate for purchases and age assurance via the age question **[VERIFY wording in the questionnaire]**; ads: third-party ads, G rated; weather: cartoon-gentle, infrequent, no peril. Made for Kids NOT selected. Paste the computed result back (expect 4+ or 9+; accept what it computes). | Re-do after G4 and G5 content is final | 30 min |
| **Privacy label** (App Privacy): Purchases, Identifiers (device ID), Usage Data (product interaction, advertising data), Coarse Location (IP-derived), Diagnostics; tracking only where personalised ads apply; Google and AppLovin disclosures agree with each SDK manifest. See D3 for the draft table. | After G4 research | 45 min |
| Paste the listing text from `store-listing.md`; set categories, URLs, copyright; paste the D8 review notes and fill the contact fields. | Submit | 1 h |
| Create the pack and lifetime IAP review screenshots after the G6 build exists (see `screenshot-plan.md`). | G6 | 30 min |

## Mon 11-16 night to Tue 11-17: G6 and TestFlight

| Task | Gate | Time |
|---|---|---|
| Archive (Product > Archive, signing on your machine) and upload. Answer export compliance if asked (already set to NO). Add yourself to Internal Testing only (no Beta App Review wait). | G6 passes (expected Mon 11-16 night); CloudKit deploy done | 45 min plus processing |
| Capture screenshots (6.9 and 6.5-inch) per `screenshot-plan.md`. | G6 | 1 to 2 h |

## Tue 11-17 and Wed 11-18: device checks (3 to 4 h across two days)

Pass/fail per item, on a real device with the TestFlight build:

1. Paywall: three options and correct prices; "3 days free" on yearly only.
2. Sandbox: buy yearly, buy lifetime, buy the pack; Restore on a second install; Manage Subscription opens.
3. Redeem `GARDENFRIEND`; Plus turns on within a moment.
4. Ask to Buy: the child account sees the request state, no crash.
5. Family Sharing: second device in the family gets Plus.
6. Parental gate: Under 13 install; every buy and link-out is behind the multiplication question; no price or buy button elsewhere.
7. UMP in simulated EEA, then ATT for an adult; no ad at all for under 13.
8. Widget on a Home Screen and Lock Screen; Say hello button. Siri and Shortcuts "Water my garden". (Unverified on device so far.)
9. Reminders: permission prompt and delivery.
10. Feel items: Living Touch and haptic, badge moment tap, thunder loudness, petal notes, Quick wings playtest, Listen-to-end stamp, Mist feel and hiss, key marks under Large Content Viewer, VoiceOver and Voice Control.
11. Two-device iCloud sync after the Production deploy.
12. **Crash safety run (guideline 2.1)**: play 20 minutes continuously; background and foreground the app several times; run once in Low Power Mode; once in airplane mode; rotate through light and dark. No crash, no stuck screen, no blank ads. **[ASSUMPTION: this list is from the status review's suggestion]**

## Thu 11-19: submit (slip: Mon 11-23)

| Task | Gate | Time |
|---|---|---|
| Attach `plus_lifetime`, `pack_frost_lantern` (if shipped) and the offer codes to the version; the first subscription group must go with this version. | All above done | 30 min |
| Final read of D8 against the TestFlight build; fill contact fields; select the build. | | 30 min |
| Submit for review. Flip ad serving live only after submission. | | 15 min |

## What would slip the date, in order (from the status review)

1. G5 art not accepted by Fri 11-13 20:00 (fallback needs your approval).
2. AppLovin account not approved (ship the adapter in test mode; flip serving after submission; nothing cut).
3. The date itself, prefer Mon 11-23 over shortening G6.
4. Owner device checks or ASC paperwork running past Wed 11-18.

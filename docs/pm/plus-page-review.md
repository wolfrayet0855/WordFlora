# Plus page review (visual, UX, compliance)

Date: 2026-11-07. Read-only review: no build, no simulator.

Reviewed: `WordFlora/Views/PlusView.swift` in the G3 worktree (`.claude/worktrees/agent-a7c7b6a837f5b8b64`, commit 8d106cb), which is the newer version. It differs from the main checkout in two places only: `FamilyShareNudgeRow(placement: .plusPage)` (line 43) and the "subscription ends" line beside Plus Forever (lines 168-173). Line numbers below are the worktree's unless marked "main". Also read: `Rules/Paywall.swift`, `Services/EntitlementService.swift`, `Components/FamilyShareNudgeRow.swift`, `Rules/FamilyShareNudge.swift`, `Rules/CopySafety.swift`, `Theme/Theme.swift`, the colour assets, `Views/SeasonsView.swift`, `docs/setup/store-listing.md`, `owner-setup-steps.md`, `age-rating-and-privacy-label.md`.

Screenshots: the only Plus shots (`shots/b02-fid/fid-plus-ax5.png`, `shots/b11-gate/plus-grown-ups.png`, Nov 6) are older than the current layout (cceb861, Nov 7 07:46: Plus Forever row, Redeem, price under the words). They still confirm the faint unselected radio and the fine-print wording. The AX5 shot shows the whole page wider than the screen (title, "Sync your garden" and the check icons cut off at both edges). The current code was rebuilt for that, but no screenshot proves the fix yet. See "Screenshots needed".

Setup facts used: not in the Kids Category (age-rating doc, line 45); purchases are gated for under 13 and unknown age; Family Sharing ON for all three products (owner-setup A6, A8, A13); the trial is set up by hand in ASC (A7).

## Ranked findings

### 1. High (rejection risk). Trial wording can show when no trial exists
`EntitlementService.swift:43-45`: `trialEligible = await sub.isEligibleForIntroOffer`. That is true for anyone who has never subscribed in the group, **whether or not `plus_yearly` has an introductory offer**. If the A7 offer is missing, late, or not live in a territory, the page still says "3 days free to start" and "Start 3-day free trial", and the fine print says "3 days free, then...". The person is then charged at once. That is misleading pricing (3.1.2, 2.3.1), and a reviewer will see it if the offer isn't attached to the build. The "3 days" is also hard-coded, not read from the offer.
Fix (small):
```swift
if let yearly = map[.yearly], let sub = yearly.subscription,
   let intro = sub.introductoryOffer, intro.paymentMode == .freeTrial {
    trialEligible = await sub.isEligibleForIntroOffer
} else { trialEligible = false }
```
Optional, later: build "3 days" from `intro.period` (bigger change, flag for 1.1).

### 2. High (AX XXXL). The grown-up question sheet clips at large text sizes
`PlusView.swift:233-247` (`ParentalGateSheet`): a fixed `VStack` in `.presentationDetents([.medium])`, with no ScrollView. At AX sizes the title (title2), prompt (callout, about 5 lines), question (title heavy), field, Continue (title3, 56 pt) and Cancel together are 3-4x taller than a medium sheet (about 330 pt on a 375x667 phone). Text without `fixedSize` truncates mid-word, and Continue/Cancel can be pushed out of the sheet, leaving no way through. With the number-pad keyboard up it gets worse. This sheet is used for every purchase, redeem, manage, Terms/Privacy and Seasons tap by under-13 and unknown-age players.
Fix: wrap the content in `ScrollView { ... }`, add `.fixedSize(horizontal: false, vertical: true)` to the three Texts, and use `.presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])`.

### 3. Medium (3.1.2 disclosure, matches store listing). The renewal line is vague and skips the 24-hour rule
`Paywall.swift:103`: "Your subscription renews automatically until you cancel. Cancel anytime in Settings."
- "Settings" reads as the app's own Settings screen, which is one tap away.
- The store description (store-listing.md:68) says "renews unless turned off at least 24 hours before the end of the period... in your App Store account settings". The in-app text should say the same thing, since reviewers compare the two.
Fix (copy only, passes CopySafety):
`"Renews automatically unless cancelled at least 24 hours before the end of the period. Cancel anytime in your App Store account settings."`
Update `PaywallRulesTests` to match.

### 4. Medium. Loading state shows "$" fragments and a dead button
While `loadProducts` is running (or when only some products come back):
- `PlusView.swift:84-88`: `displayPrice` is `""`, so the fine print reads " per year. Your subscription renews..." (no price), and the CTA "Subscribe" is disabled. `PrimaryButtonStyle` (Theme.swift:76) ignores `isEnabled`, so the button looks live but does nothing.
- `PlusView.swift:106/112`: the cards show "Yearly / Monthly / Plus Forever" with no price.
- `PlusView.swift:79`: if yearly loads but monthly doesn't, the line reads "save 0%".
Fix (small): when `!store.offers(selected)`, hide the fine print and show `ProgressView()` with "Loading prices…" in place of the CTA. Only add "· save N%" when `monthlyPrice > 0`. In `PrimaryButtonStyle`, read `@Environment(\.isEnabled)` and apply `.opacity(isEnabled ? 1 : 0.5)`. Check that the dimmed label still has 4.5:1 contrast (ink on accent is 5.38 light and 6.62 dark at full strength; at 0.5 it fails, so dim the fill only, not the label).

### 5. Medium (non-text contrast 3:1). The unselected choice circle is too faint
`PlusView.swift:142`: `appPrimaryText.opacity(0.3)` on `appSurface` measures **1.75:1 light, 2.21:1 dark** (computed from the asset hexes). It can be seen in the Nov 6 shot. The card edges are also faint (surface vs background 1.07 / 1.26), so this circle is the only cue that a card can be chosen.
Fix: `.opacity(0.55)`, which is `PuzzleInk.blankOutline`, already measured at 3:1 or better.

### 6. Medium (Ask to Buy). The pending message is wrong for the most common young-family case
`PlusView.swift:215`: "Almost there. If Plus is not on in a moment, tap Restore purchases." `.pending` comes back from StoreKit when Ask to Buy is waiting for a parent, which can take hours. The message tells the player to keep tapping Restore. The same `.pending` also covers the slow-entitlement poll (`EntitlementService.swift:111`).
Fix (small): split the outcome, e.g. `case awaitingApproval` for StoreKit `.pending`, with copy like "Sent to a grown-up to approve. Plus turns on once it's approved." Keep the current line for the poll timeout. Run both lines through CopySafety. Do the same for Seasons (`PackCatalog.Copy.pending`).

### 7. Medium (VoiceOver and plain words). Prices use "/yr" and "/mo"
`PlusView.swift:106`: "$12.99/yr" and "$3.99/mo". VoiceOver says "slash y r", young readers may not know the short forms, and Seasons was just changed to readable prices ("Price: $X", commit 78ce268). At AX5 headline (about 53 pt), "$12.99/yr" has no space and is about 290 pt wide against roughly 245 pt of card text column on a 375-wide phone. It can only break after the slash ("$12.99/" then "yr").
Fix: `shown.map { $0 + (plan == .yearly ? " a year" : " a month") }`, and for Plus Forever `"\(price) once"`. This also matches the store description wording ("$12.99 a year").

### 8. Low-medium (contrast 4.5:1). The gate's "Not quite. Try again." in light mode
`PlusView.swift:240`: `appDanger` (#E85050) on the sheet's white background measures **3.69:1** (dark mode passes at 6.13).
Fix: use `Color.appPrimaryText` with an `exclamationmark.circle` icon, or add a darker `dangerText` asset (for example #B3261E, about 6:1 on white).

### 9. Low-medium. Messages: wrong colour, never read aloud, success never shown
- `PlusView.swift:89`: every message uses `successText` (green), including the failure line. Seasons uses `appPrimaryText` (SeasonsView.swift:70). Use `appPrimaryText` here too.
- The messages are not announced. Add `AccessibilityNotification.Announcement(message).post()` when `message` is set.
- After a successful purchase, `hasPlus` becomes true, the `plans` branch (which holds `message`) is replaced by `activeCard`, and "Welcome to WordFlora Plus!" is never seen. This is harmless, since activeCard says "You have WordFlora Plus". Either drop the success message or move the message view out of `plans`.

### 10. Low. Restore gives no feedback and has no busy state
`PlusView.swift:46`: a tap runs `AppStore.sync()` silently. If nothing is found, nothing happens. Reviewers tap Restore, and a page that doesn't react looks broken. Repeated taps start repeated syncs.
Fix: `restoring` state that disables the button, then a message: "Plus is on." or "No purchases found for this Apple ID." (copy-check both). The same applies to `SeasonsView.swift:22`.

### 11. Low (VoiceOver). Heading and decoration
- `PlusView.swift:31`: "WordFlora Plus" needs `.accessibilityAddTraits(.isHeader)` (Seasons marks its pack title as a header).
- `PlusView.swift:30`: check that `FlowerView` is hidden from VoiceOver on this page. If not, add `.accessibilityHidden(true)`.
- `PlusView.swift:142`: add `.accessibilityHidden(true)` to the circle image so the combined card reads only the words plus "Selected".
- Reading order is otherwise right: intro, title, benefits, cards (title, badge, trial, per-month, price), CTA, fine print, nudge, footer.

### 12. Low (13+ only). "Restore purchases" appears twice
For 13+ without Plus, `FamilyShareNudgeRow(placement: .plusPage)` (line 43) adds "Already have Plus on a family phone? Restore purchases" just above the footer's own "Restore purchases" (line 46). Two identical button names, about 60 pt apart, are confusing with VoiceOver. This is an owner-approved placement, so the fix is a lead call: on the Plus page, show only the line "Already have Plus on a family phone? Tap Restore purchases below." and drop its button, or drop the footer button when the nudge shows.

### 13. Low. "3-day" may break at the hyphen at AX sizes
`Paywall.swift:108` ("Start 3-day free trial") in title3 bold inside the CTA: at AX4-AX5 on a 375-wide phone the line can break as "3-" / "day". Use a non-breaking hyphen: `"Start 3\u{2011}day free trial"`. This needs no test change if the test compares with the same constant. Otherwise update `PaywallRulesTests:34`.

### 14. Low (copy-check gap). Inline strings are not linted
The page's inline strings are not covered by `PaywallRulesTests`: the load-failure line (73), "Try again" (74), the active-card lines (158-159), and the welcome, pending and failure lines (214-217). All pass `CopySafety` by inspection today. Fix: move them into `PaywallCopy` and add them to `PaywallCopy.all`.

## Checked and fine
- **3.1.2 basics:** each plan's price, period and auto-renewal are on the page. Trial-to-paid wording is right ("3 days free, then $12.99 per year"). Restore purchases is always visible. Terms of Use (Apple standard EULA, same as the store listing) and the Privacy Policy (`shapehaveninnovations.com/privacy`, same as store-listing.md:19) are both linked. Manage subscription is there. Plus Forever says "One payment of $34.99... No renewals." No countdowns, no pre-ticked upsell. Yearly is the default but is clearly marked "Best value" with a per-month figure and savings. Monthly and Plus Forever cards use the same type sizes. No dark patterns found. A trial end date is not required by Apple; "3 days free, then..." is enough.
- **Parental gate:** purchase, redeem, manage-subscription (both the link and the pays-twice button), Terms and Privacy are all gated for under 13 and unknown age (`ParentalGate.isRequired`). Restore is ungated, which is correct since it never charges. Not in the Kids Category, so guideline 1.3 gate rules are advisory. The two-digit by one-digit multiplication gate is acceptable outside Kids. Note: a wrong answer keeps the same question, so it can be retried forever (a 1.1 idea: a new question after 2 misses).
- **Already-subscribed and Plus Forever states:** `activeCard` covers subscriber, lifetime, lifetime-plus-renewing-sub (pays-twice line plus a gated cancel button) and lifetime-plus-non-renewing-sub (end-date line, G3 worktree only). The copy is calm and clear.
- **Failed prices:** "We couldn't load the plans. Check your connection and try again." plus a "Try again" button, shown when the store returns nothing. OK. (It doesn't show a spinner while retrying; covered by finding 4's progress view.)
- **Contrast (measured from asset hexes):** secondary text 7.5-9.4:1. successText on surface 5.13 light, 5.69 dark (on background 4.79 / 7.20). "Best value" badge 9.27 light, 4.81 dark (just passes). CTA ink on accent 5.38 / 6.62. Selected ring 4.79 / 7.20. Only findings 5 and 8 fail.
- **Tap targets:** the footer links use `.tapTarget()` (44x44). Cards and the CTA (56 pt) are well above 44 pt. The gate's Cancel has a 44 pt minimum height.
- **Text styles:** every font is `Theme.font(<text style>)`. No fixed sizes, no caps, no `ViewThatFits`. The badge switches axis with `AnyLayout` at AX sizes. "WordFlora" at AX5 largeTitle bold (about 300 pt) fits the 343 pt column on a 375-wide phone, but only just. Terms/Privacy side by side at AX5 footnote: "Privacy" is about 152 pt in a 167 pt half, so it fits, also only just. Confirm both on the AX5 shot.
- **Family Sharing wording:** "Family Sharing covers up to six people" (intro, store listing) is accurate. "Share it with your family" is a benefit of all three plans, and that is true only if Family Sharing is ON for `plus_yearly` and `plus_monthly` as well as `plus_lifetime` (owner-setup A6, A8, A13). Add it to the owner's ASC checklist answer at owner-setup-steps.md:231, which today asks only about `plus_lifetime`. Small inconsistency: `lifetimeLine` "keep Plus on this Apple ID" leaves out that Plus Forever is also family-shared. Optional copy fix: "Pay once, keep Plus for good. Family Sharing included. No renewals."
- **Copy safety:** every string on the page passes the `CopySafety` list (no "only", "last", "expires", "miss" and so on).
- **Seasons consistency:** same card surface, radius, gate and button style. The differences are findings 7 (price wording), 9 (message colour) and 10 (restore feedback).

## Bigger items for the lead (not proposed as quick fixes)
- A subscriber cannot move to Plus Forever from the page, because `activeCard` hides all plans. That is a product decision.
- Showing the trial length from `introductoryOffer.period` instead of hard-coded "3 days" (follow-up to finding 1).

## Screenshots needed (no current shot of this layout exists)
Plus page on iPhone SE (3rd gen, 375x667) and iPhone 16 (393 wide), using `-uitest-prices`:
1. Default text, light and dark, scrolled top and bottom (all three cards, fine print, footer).
2. AX5 (Accessibility XXXL), light, every scroll position. Confirm the page no longer overflows sideways (as in the Nov 6 AX5 shot) and that "WordFlora", "$12.99/yr" and "Terms of Use / Privacy Policy" don't break mid-word.
3. The grown-up question sheet at default text and at AX5, with the keyboard up (finding 2).
4. Monthly selected, and Plus Forever selected (CTA and fine print).
5. Loading state (store delayed) and the failed state.
6. Active states: subscriber, Plus Forever, and Plus Forever beside a renewing subscription.

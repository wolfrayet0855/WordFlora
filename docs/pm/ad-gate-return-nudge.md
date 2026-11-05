# Backlog: coming back too soon after "That's enough for now" (owner idea, 2026-11-05)

Owner idea: after the player taps "That's enough for now" on the rest card, if they come back to play words within 3 minutes, free players watch an ad to continue; where ads are off, nudge them to the garden or a puzzle instead.

Lead's decision (recommended, build after the current integration):
- Applies only when the player taps Play/"One more" again within 3 minutes of "That's enough for now". The ad (if any) follows the player's own tap, never the exit, and still obeys every existing AdGate rule (one at a time, daily cap, gap, not after the Daily Bloom, not at night, grace period).
- Free adults: the rest card's honest line "A short ad may play first." appears on the Play button in that window. No timers or countdowns on screen.
- Ads off (WordFlora Plus, under 13, ad failed to load, caps reached): no ad and no wait. A gentle nudge card instead: "Your garden would love a visit" with buttons Visit my garden / Try a puzzle (Daily Bloom or the butterfly game) / Play anyway. Never blocks play. Positive-only copy, grade 2-3, CopySafety.
- Calm mode and Quiet Garden: nudge only (never an ad).
- Plus never sells the wait away as a threat; the Plus row stays a gentle invitation, no price on the kid-facing card.
- Needs: AdGate change with unit tests (3 minute window, all combinations), Rest card state, UI tests, copy test.

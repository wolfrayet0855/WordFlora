# Wake the seed: decision (overseer)

Evidence is thin: most URLs and every figure in the notes are UNVERIFIED. Decisions rest on agreement and repo rules, not studies.

## Cross-examination
- **Q1:** All say tiles. Weakest: UX's carousel claim rests on a search snippet.
- **Q2:** All say butterflies first. Kids' adult split does little (unknown age counts as under 13). Retention's "90-95% success" target has no source.
- **Q3:** All say one at a time, with skip. The pace differs. Retention's peak-end claim is untested here.
- **Q4:** All say a plain close. Retention's "one notification per lapse" is a nag, so it is rejected.
- **24 h:** All find it harsh for kids (48 h or 72 h plus Gentle mode; both are guesses). Retention's "Daisy misses you" breaks CopySafety.

## Decisions
- **Q1:** Stacked big tiles, suggested first. At 5+ challenges, .large detent and scroll.
- **Q2:** Adaptive suggestion, badge "Good for today". Both tiles always show; nothing auto-starts.
- **Q3:** Petals return one at a time, 0.3 s apart, 2.4 s at most. A tap shows all; so does Reduce Motion. Soft haptic on the first petal and hearts only (none if off). One VoiceOver announcement.
- **Q4 (owner change):** No text close button in the wake flow. A plain X (VoiceOver "Close") or a swipe down closes the sheet. Nothing changes, there is no re-prompt this session and no push. The seed card keeps a quiet "Wake Daisy" button.
- Chips: "Quick" / "A little longer", not minutes.

## Adaptive rule
Suggest the challenge the player last woke a seed with. If there is none, or the last try ended in "Still dreaming", suggest butterflies. After 2 "Still dreaming" in a row, the next try is easier and butterflies becomes the main button.
Tests: no wakes → butterflies; word win → word; "Still dreaming" → butterflies.

## Copy (grade 2, passes CopySafety)
- Seed card: "Daisy is resting in her seed. She is safe and cosy." / "Wake Daisy"
- Sheet: "Wake Daisy" / "Pick one you like."
- Intro: "Tap 3 butterflies. Take your time." / "Make a word from the letters. Take your time."
- Success: "Daisy is awake!" / "Here come her petals." / "Tap to see them all."
- Still dreaming: "Daisy is still dreaming." / "You can try again any time." / "Try again", "Try the butterflies"
- Rain: "A rainy day for Daisy."

## 24 h rule: recommendation for the owner to accept or reject
- **Known adults (13+):** keep the owner's 24 h rule.
- **Under 13 and unknown age:** the first rain comes after 72 h, then one petal a day.
- **Gentle mode** (no petal loss, no seed) sits behind the parental gate. Kids wanted it on by default for unknown age. I suggest off, with 72 h as the safety net. The owner decides.
- Quiet Garden, Calm mode: exempt.
- Update reinforcement-principles rule 4 ("plants never wilt") to name this exception.

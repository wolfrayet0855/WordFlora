# UX notes: wake the seed

Evidence: NN/g mobile carousels https://www.nngroup.com/articles/mobile-carousels/ (loaded via search: weak discoverability, swipe ambiguity, keep few items); Smashing carousels https://uxdesign.smashingmagazine.com/2022/04/designing-better-carousel-ux ; Duolingo ABC kids playtest (difficulty in zone of proximal development, breaks) https://chinchilla-hexahedron-jewa.squarespace.com/blog/05/31/2023/report-duolingo-abc-playtesting-session . UNVERIFIED (pages 404 or JS-only): Apple HIG Sheets https://developer.apple.com/design/human-interface-guidelines/sheets, NN/g choice-overload, NYT Games/Wordle/Finch (no sources found; reasoning only).

## Q1 Tiles vs swipeable cards (3+ challenges)
Keep a vertical stack of big tiles in the sheet; do not use a carousel. Carousel items are easily missed and swipe collides with sheet drag and edge-back. With 3 to 4 options a stack fits; at 5+ switch the sheet to .large and scroll, keeping the suggested tile first. Confidence: medium-high.

## Q2 Default suggestion
Default to the gentle one (butterflies). Spec round 3 says the word puzzle is "very hard", mixed kid/adult audience, and reinforcement-principles forbids punishment feel; a first miss on the suggested tile hurts most. Choose adaptively but simply: first time always gentle; afterwards suggest the type the player last won, and suggest the other tier only after a win, never after "Still dreaming". Always show both chips so the player can overrule; never a hidden rule. Fixed is a fine v1 fallback. Confidence: medium (no direct source; Duolingo kids report supports staying in reach).

## Q3 Petals
One at a time, about 0.4 s apart (3 to 8 petals = 1.2 to 3 s). It is the reward moment, and it fits "continuous reinforcement". Add: tap anywhere skips to all-at-once; Reduce Motion shows all at once (already planned). Keep haptics light so 8 do not buzz. Confidence: medium.

## Q4 "Maybe later"
Fine, the seed simply stays dormant, no penalty, no nag. Improvements: relabel "Not now" or keep "Maybe later" but also allow swipe-down and a visible close; do not re-prompt this session; the dormant seed card keeps a quiet "Wake Daisy" button. Confidence: high.

## Other flaws in the mockup
- Sheet is modal but has no explicit Close (HIG advises an explicit exit alongside swipe); "Maybe later" at the bottom may be below the fold at large Dynamic Type.
- "Tricky" chip on the word puzzle plus "Suggested" badge on the gentle tile reads fine, but "Suggested" label is the only non-chip cue; add reason ("good for today").
- Time chips ("About 1 min") on a no-timer game imply a clock; consider "Quick" / "A little longer".
- Screen 4 has two buttons of near-equal weight; make "Try the butterflies" clearly secondary.
- Success screen: confirm the haptic does not fire when haptics are off; announcement should not repeat per petal.
- Back chevron in challenge intro: confirm it returns to the sheet at the same detent.
- Focus outline uses var(--text) while some tokens named differently (--text vs --txt2): check dark theme contrast.

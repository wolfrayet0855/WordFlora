# Wake the seed: kids lens

Evidence is thin. No study found measuring guilt from a neglected virtual pet; Tamagotchi guilt is anecdotal (https://wellcomecollection.org/stories/digital-pets). One thesis links virtual-pet bonding to higher empathy (https://summit.sfu.ca/item/9146). Apple Kids rules: https://developer.apple.com/app-store/review/guidelines/#kids-category . ICO Children's Code: fetch blocked, UNVERIFIED.

## Q1 Tiles vs swipeable cards
Tiles. All options visible, no hidden gesture, one big tap target each. Swiping is weak for ages 6-8 and for VoiceOver/Switch Control. If 4+ challenges arrive, use a visible list, not a carousel.

## Q2 Default suggestion
Child or unknown age: butterflies, highlighted. No reading, no wrong answer, tap-only. Adult: word puzzle, the core game. Never auto-start either.

## Q3 Petals returning
One at a time, about 0.4 s apart with a soft haptic, capped near 3 s (any remainder fades in together). It reads as "Daisy is waking" and matches the storyboard. Reduce Motion: all at once.

## Q4 Maybe later and the seed state
Risk (moderate, UNVERIFIED by research): a child may feel responsible or sad when petals fall. Mitigations:
- Copy at grade 2 level, under 8 words: "Daisy is resting in her seed. She is safe." Avoid "lost", "neglected", "missed you". Rain is "a rainy day", not a punishment.
- Art: a cosy pot with a sleeping "z". Petals drop gently; no counter of missed days.
- "Maybe later" is a plain close: no guilt copy, no state change, no push reminder for under-13.
- Progress kept, retry free, no timer (already in storyboard).
- Soften the clock for under-13 or unknown age: 72 h before the first rain instead of 24 h, so a sick day or busy week costs nothing.
- Parent-facing "Gentle mode" in a parental-gated settings area (no petal loss, no seed state); default on for unknown age.
- Pair every icon with text and a VoiceOver label.

## Safety flag
Petal loss plus a seed state can read as punishment, conflicting with docs/research/reinforcement-principles.md rule 4 (no punishment or loss); for under-13 or unknown age use the gentler clock or Gentle mode and guilt-free copy.

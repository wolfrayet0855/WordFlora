# T-D Pot collection: critic review

Shots checked: shots/critic-s1..s4-{light,dark}.png, critic-s1b-dark.png, critic-s4-dark@3x.png (390 pt layout).

**(a) Pots at 44 pt: 4/5.** Ten distinct, friendly pots in both themes, and every pot stays unique in grey and all three simulations. One weak spot: Terracotta's rings (#9A4F2E on #C8734A, 1.7:1, 5 units thick) almost disappear at 44 pt and in grey, so Terracotta looks like a second Plain blue.

**(b) Pick a pot: 4/5.** The 5x2 grid is the right call. Ten items fit, nothing hides off screen, and a scroll row would hint at "more to get". Chips are really about 61 x 86 pt (the notes say 66), which still clears 44. The ring plus check badge works. The outline pots to earn feel calm, and the hint bubble with its pointer is clear and kind. With large Dynamic Type, "Starlight" and "Honey stripe" will clip at 11.5 pt in a 61 pt chip.

**(c) Shed grid: 5/5.** No locks. The progress lines are gentle, "Yours to use" and "In use by Daisy" are warm, and the footer promise is right. One small ambiguity: "Level 3 of 5" could mean she is on level 3.

**(d) Stage: 4/5.** 140 pt pot proportions suit the daisy, sunflower and rose. The plant art's ground ellipse spreads past the rim edges in light mode. In dark mode the floor shadow under the pot can't be seen.

**(e) Copy: 4/5.** No banned word in any app string. The two hits for "only" are in designer captions, not app copy. Reading level is grade 2. Three issues:
- The pots.json Plus hint ("A grown-up can look at Plus.") does not match the sheet ("...in Settings.").
- copy.progressLevel "On level {n}" does not match the Shed.
- The bubble line has no singular form for "one more level", and "first plant" has no progress string.

**(f) Geometry: 3/5.** The drawing order and shapes work in SwiftUI. But pots.json disagrees with index.html in three places:
- drip band: json (18,22,84,8), html (18,20,84,10)
- flower petal: json ry 11, html ry 9
- flowerBand rect: json height 26, html height 30

Also, x values for the drip and stripe shapes don't say whether they are centres (html uses centres). Petal start angle (up) isn't stated, and the to-earn style (fill, ink, dash) lives only in the HTML.

**Designer's open points**
- Moonlit 1.7:1 body: accept. The rim at 3.2:1 meets the 3:1 rule for graphics.
- Mint dots: keep r 4.5 and all 12 dots. They read as "dotty" at 44 pt.
- Ground shadow over the rim: fix (change 2).

## Changes for one revision
1. Make Terracotta's rings `#7E3F22` and 7 units tall at y 38 and y 52 (second band at 70%).
2. On the stage, clip the plant art's ground shadow to the soil-top ellipse (80 x 20), and in dark mode draw the pot floor shadow as `rgba(0,0,0,.35)`.
3. Make pots.json match the HTML: drip band `(18,20,84,10)`, flower petal `ry 9`, flowerBand rect `(18,70,84,30)`. Add the sentence "all x/y for capsules, bars, circles and petals are centres; petal 0 points up, then clockwise".
4. Add `geometry.toEarn` to pots.json: fill `#E4DFD2`/`#3A4C3A`, ink `#746F5E`/`#8FA48F` (light/dark), no strips or shine, body and rim stroke 2 dashed `[5,4]`, pattern in ink at 55%.
5. Make the moon crescent an even-odd path (r 15 circle minus r 13 circle), not an overpaint in body colour.
6. Set every Plus hint to "Part of WordFlora Plus. A grown-up can find Plus in Settings."
7. Replace copy.progressLevel with "{n} of {goal} levels finished". Add copy.toGoOne "One more level to go!", copy.toGoMany "{k} more levels to go!" and copy.progressFirst "Grow one plant to earn this pot."
8. At accessibility text sizes, switch the pick grid to 4 columns (3 rows) and let chip names wrap to 2 lines.
9. Correct the notes to say chips are 61 x 86 pt at 390 pt.

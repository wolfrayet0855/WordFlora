# Grand Garden + Wild Weather: notes

Gallery: http://localhost:8765/endgame/ . One file draws every phone: `screens.html?s=a|b|c|next|rescue|rescue2|mended|settings&theme=light|dark&rm=1&scale=1.3&tall=1`. `sh render.sh` writes `shots/*.png` and greps each screen's visible text, `aria-label` and `alt` against CopySafety.banned (plus the word "Plus"). The gallery runs the same check live.

## 1. Grand Garden (all 50 plants found)

The reward is the **Gardener's Crown**: a ring of leaves with seven small flowers, drawn in SVG (`crown()` in screens.html). It is a flower crown, not a royal one. All 50 plants are the real catalog SVGs from `../plants/`, ordered by level. Every plant `img` has empty alt, and each scene has one `role="img"` label ("Your garden with all 50 plants in bloom"), so VoiceOver reads one sentence, not 50 plant names.

- **A. Panoramic garden (my pick).** Five terraced hills holding 12 + 11 + 10 + 9 + 8 plants. The rarest (level 5) sit at the back and the first plants found are at the front, so the picture shows the whole journey from back to front. The crown medallion sits above the title. This direction makes the garden the reward rather than the badge, it fits the existing Night-garden rest card (sky gradient, hill, fireflies in dark), and it reuses as-is for the postcard and the "Walk my garden" view.
- **B. Crown on the wordmark.** The crown rests on the WordFlora wordmark inside a two-ring wreath of all 50 plants. It reads as a strong emblem, but at 34 to 40 px the plants turn into confetti-like specks, and putting the logo at the centre of the player's moment makes it about the brand.
- **C. Garden postcard.** Panorama A as a tilted postcard with a crown stamp, built to share. Good as a follow-up ("Share my postcard"), but as the first thing the player sees it puts sharing ahead of the feeling. Suggest offering it as A's share sheet instead. Under 13, Share goes through the existing grown-up check.

Motion: up to 7 slow petals (9 s each), plants sway 1.4 degrees, title rises in 0.6 s. No confetti. **Reduce Motion** (`a-rm-*`): a 0.3 s fade, no petals, no sway. The still frame is the same composition, so nothing is lost.

**No Plus, ads or prices** appear anywhere in the ending or in "What grows next" (the render check flags the word).

### What grows next
After any direction. Three tiles, each with real art:
- **Seasons**: each plant can grow a new look (Golden, Frosty, Blossom), earned by play. The art is mocked with CSS filters on the Sunflower; real variants need their own art.
- **Daily Bloom ranks**: Daily Bloom keeps going with no end. Ranks are Bud, Blossom, Meadow, Grove, Evergreen ("Evergreen" matches the spec's after-game loop). Ranks only go up, but the copy says "Each day you play adds up" so the banned word "only" never appears.
- **Visitor Sanctuary**: a calm spot where butterflies, bees and birds come to stay.
- Footer line: "Your crown and every plant stay in your garden." (Nothing earned is ever removed.)

## 2. Wild Weather rescue (grown-up opt-in)

- **Header**: an "After the storm" chip, a two-step progress bar, and a storm-bent Sunflower (rotated, skewed and desaturated) under clearing clouds, with the sun peeking out.
- **Step 1**: SNAPDRAGON (10 letters), the same tiles and slots as WakePuzzle. Ten slots in one row are 32 px wide, too small for 44 pt targets, so the slots only show letters. Taking a letter back uses a 48 pt **Take back** button (plus Clear), not taps on slots. Tiles are 58 x 54.
- **Peek ladder**: Peek (used), Peek (ready), then a Picture clue later. Every rung is free. The label says "soon", never a countdown, so there is no timer anywhere.
- **Step 2**: catch 3 slow butterflies (the existing butterfly game). Sunflower is already partly lifted, so step 1 already shows progress.
- **Skip on every step**: "Skip for now", with "Care will help it mend. No hearts are used." under it. Skipping means the plant mends over time with normal care (watering).
- **Success**: Sunflower stands upright at full colour under a soft rainbow, with a **Weathered the storm** badge for the shelf. "Sunflower is standing tall again!" / "Your care helped it mend. The sun is back."
- **Settings**: "Wild Weather / For grown-ups", **off** by default and behind the grown-up check. The text says plainly what turns on. "It never turns on by itself."

## Accessibility
- Text uses theme tokens. Secondary text is 88% of `--text`, which is above 4.5:1 on `--bg` in both themes. Accent buttons use `--ink` on `--accent`, the same as the rest card.
- Buttons are 48 to 56 pt. The settings rows are 52 pt.
- Larger-text frames (`rescue-large-light`, `next-large-dark`, 1.3x) grow taller instead of clipping.

## Known weaknesses
- Seasons art is filter-based (the frosted look is just a blue tint).
- At 1.3x text, the rescue screen still fits, and "Peek a letter" moves onto its own row. Larger sizes (AX3) will need the screen to scroll. The 10 slots do not grow with text size, so 11 to 12 letter names would need two rows or smaller slots.
- The postcard stamp perforation is a dotted outline, not true scallops.
- The B wreath plants are small, and the upper ring reads as scattered.

---

## Revision 1 (after critic.md and the updated spec: sections 2, 4.2, 4.6 and 5)

`screens.html` has been rewritten. Revision 0 is kept as `screens-v1.html`, with its shots in `shots/v1/`.

**Ending**
- **A is the ceremony.** It fires on `allFound`. The title is "Every plant found!" and the subtitle is "You found all 50. What a garden! The crown is yours to keep."
  - Plants are drawn at their **earned stage**: Tiny 42%, Sprout 58%, Bud 78%, Full bloom 100% of the row size, so the newest finds look small. A two-item legend explains this.
  - The crown is about twice as large and floats over a glow, with no disc.
  - The light-mode sun moved up into the sky beside the crown and no longer covers the back row.
  - The redundant "50 of 50" chip is gone.
  - The back rows are larger (40 and 46 pt).
- **Gold crown** (`s=gold`): a smaller moment at `allFullBloom`, with every plant at full bloom, gold crown petals and the line "Your whole garden is in full bloom." Its single button is "Lovely".
- **Home beat** (`s=home`): B's crown-on-wordmark now sits on the Home sign, with a toast. Home features the plant nearest golden ("Daisy is 3 days from golden", 4 of 7 shown as pips plus text).
- **Share sheet** (`s=share`): C's postcard in a sheet over A. The stamp moved onto the white border. The buttons are "Share my postcard" and "Keep in my album". With `kid=1`, sharing reads "Ask a grown-up to share".
- **What grows next** lists exactly four things:
  - Golden blooms (7 care days).
  - Bloom ranks: Seedling, Sprout, Bud, Bloom, Full bloom, Evergreen. The current rank has a tick and says "You are a Bud." in words.
  - Visitors' book.
  - Garden weather.
  - No seasonal looks and no "Sanctuary" appear.

**Weather puzzle** (whole garden, kid name "Big wind", no "storm" in kid-facing screens, no hearts)
- **Intro:** the fixed reward is named before play: "Solve it for the Frog friend sticker and a word toward your next plant." There is a Gentle / "A harder one" choice, and **Start and Skip are both 56 pt**. Skip reads "Skip for now" with "Care will help it mend." under it.
- **Puzzle:**
  - VENUS FLYTRAP is drawn as two slot groups on two rows (5 and 7 slots, 40 pt wide).
  - There are 13 tiles, including one decoy (K), and no given letters.
  - A peeked letter shows an eye mark, and VoiceOver reads "V, peeked".
  - The top of the screen has a "New puzzle" button.
  - The last rung of the peek ladder reads "Picture clue after 2 peeks", with no time word.
- **Part 2 (Wild Weather):** a butterfly catch under a dawn sky, a "Try a word instead" swap and a Skip button the same size.
- **Daily cap:** "That is plenty for today. Your garden will mend with care."
- **Solved:** "You solved it! Your whole garden is standing tall." It shows the Frog friend sticker, "+1 word toward your next plant" and "Weathered: 1 of 3". The sun is removed, so the rainbow stands alone, and dark mode uses a dawn sky.
- **Settings:** Garden weather (on) with a plain explanation, "Tell me about garden weather" (off) and Wild Weather (for ages 13 and up, off) with the honest text. The row says "For ages 13 and up" because the word "only" is banned. The bolt icon was replaced by a cloud with wind lines. "Off means calm skies" is gone.
- **render.sh** now also flags save, rescue, danger, destroy, warning, alert, too late, heart(s), and "storm" everywhere except the Settings text.

**Still open:**
- The Settings Wild Weather text uses the lead's word "storms". Spec 3.5 would say "big weather days".
- The 13+ confirmation card is not mocked.
- Golden and gold looks are still CSS filters.
- In the earned-stage panorama, Tiny plants are just smaller copies of the full art. Real Tiny and Sprout art would read better.

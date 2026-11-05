# WordFlora logo and brand research

Date: 2026-11-04. Branch: 3-feat-content-and-polish.
Question: does the logo make sense, would it draw attention, would it make people feel good?

Confidence labels: High = primary or standard source, or direct measurement I ran. Medium = consistent across several secondary sources, or sound design reasoning. Low = vendor claim, single source, or my own judgement without evidence.

## 0. Honest limits of this research

- Web search here returned mostly vendor blogs. I could NOT retrieve the text of Apple's App icons HIG page (the fetch returned only the page title), the Labrecque and Milne paper body, or any analysis of the Wordscapes, Lily's Garden, Gardenscapes, Finch, Seek, PictureThis, Forest, Calm or Headspace icons. I found no study of "flower replaces O" wordmarks and no study on children reading letter-substituted logos. Those parts are marked as reasoning, not evidence.
- There is no controlled evidence that this logo will or will not draw attention. The only way to know is a store-listing or ad-creative test with your own traffic (section 6).
- Contrast numbers and colour-blindness simulations below are my own calculations from the SVG fill values (WCAG relative-luminance formula; Machado 2009 matrices at full severity). Confidence High for the numbers, Medium for what they imply.

## 1. What I looked at

- Final wordmark (`design-preview/logo/final/`): Nunito Black, "Word" in dark green #2C3E2C, "Flora" in green #2A7A38, the two o's are the letters' own rings with five ellipse petals (amber #DA8B22 on the Word o, rose #E07A8E on the Flora o, turned 36 degrees). Dark variant uses mint, gold and a deeper rose. Solo variant has only the Flora flower. Sheets: `compare/sheet-light.png`, `tiny-zoom.png`.
- Candidate icon (`icon/png/icon-1024.png`): cream "o" in a green ring on mid-green, five amber petals, no face.
- Shipping icon (`AppIcon-default.png`): eight-petal cream daisy, amber centre with a smile, on a green gradient.

## 2. First-hand assessment

What works (Medium to High, from viewing and measurement):
- It reads as "WordFlora" at all sizes tested. The flowers ARE the letter o (Nunito's own o is kept as the ring), so the word is not broken. This is the main reason the letter-substitution risk is low here. It is a decoration of an intact letter, not a replacement with a picture.
- The two-tone split (dark "Word", green "Flora") tells a reader the name is two words. The petals sit at the two word boundaries and mark the join "Word | Flora" nicely.
- Heavy, rounded, high-x-height letters are legible at 29 px height in the tiny-zoom sheet.
- Dark and mono variants exist and hold up.

What is weak or risky (my judgement, labelled):
1. The petals are the weakest element. Light-mode amber is 2.55:1 and rose 2.67:1 against the cream background. At 29 px height the petals shrink to a few pixels and become a soft halo, and the five Flora petals cannot be counted (the build notes admit this). The "flower" part of the idea is least visible in the places a wordmark is smallest. (High on numbers, Medium on impact.)
2. Amber and rose have almost identical luminance (1.05:1 between them), so in greyscale, mono and every colour-vision simulation they look the same shade. They are separated only by position. That is fine for recognition but it means the two-colour petal story carries no information for some viewers and the mono sheet turns both into the same grey. (High.)
3. "Word" and "Flora" differ by hue but weakly by lightness: 2.15:1 between #2C3E2C and #2A7A38. Under simulated deuteranopia, protanopia and tritanopia it stays 2.1 to 2.2:1. So the word split survives colour blindness but is subtle. (High.)
4. Spacing is uneven by design. Clearing the petals added gaps of +29% (W-o) and +45% (l-o) over the r-d reference, and d-F is tight at -33% (build notes). Heavy letters with loose pockets around the o's can read as "W ord Fl ora" at a glance. A skim at 60 px height shows the gaps are noticeable but not fatal. (Medium.)
5. The two flowers are not twins: the Word o has a petal pointing up, the Flora o is rotated 36 degrees, and they use different colours. This is deliberate variety but costs the "one mark" feel. Neither is a clear hero. (Low, taste.)
6. Palette is tasteful but safe: dark green, mid green, amber, dusty rose on cream. It reads calm, craft-like, slightly retro-1970s. It does not scream "fun" and it does not read as a game. For a calm product that is a plus; for stopping a thumb in a crowded store, it is quiet. (Medium.)
7. The wordmark and the app icon do not look like one brand (see section 7).

## 3. What gets an app noticed and feels good in the store

- Apple does not offer native icon A/B testing on iOS: Custom Product Pages do not vary the icon. Google Play Store Listing Experiments do allow icon tests. (Medium; stated by several vendor sources, e.g. Appalize.)
- Vendor-reported icon test lifts: AppTweak 2024 data quoted as median 8 to 12% lift for winning icon variants on Google Play, top tests 28% (secondary source, could not verify at AppTweak). EverythingMe reported 41% improvement over two phases in 2015 (Google Developers blog case study). MyTona reported 9% from a seasonal icon swap. A 14.2% download increase from a redesign is claimed in a Medium case. All are winners self-reported by vendors, so expect survivorship bias. (Low to Medium.)
- Azur Games reported a projected near-doubling from an icon test that did not materialise, and the old icon did better for key search terms. Lesson: lifts are segment-dependent and tests overestimate. (Low to Medium, single vendor source.)
- Faces/characters vs abstract: multiple vendor guides say characters and faces beat abstract icons in most categories (Appalize: "10 to 30%", no source). Duolingo is the visible example: its icon is a cropped close-up of the mascot's face, and when it changed the expression to a strange one users noticed and complained, which shows faces carry emotion strongly. (Low for the general claim; Medium that faces carry emotion.)
- Colour: Labrecque and Milne 2012 (Journal of the Academy of Marketing Science 40, 711-727) found hue maps onto brand personality (red exciting, blue competent) and that saturation and value matter. I could not confirm anything specific on green, pink or amber, or about children. Green is commonly framed as nature/growth/calm and pink as soft and friendly, but the support I found was commercial blogs (Vistaprint), not research. (Medium for the paper's existence and general finding; Low for green/pink claims.)
- Duolingo is a useful precedent that a green brand can be playful and kid-and-adult friendly: green is the mascot's colour, and the icon is a character, not text. (Medium; Creative Bloq and Duolingo's own blog.)
- Competitor brand analysis for Wordscapes, Lily's Garden, Gardenscapes, Finch, Seek, PictureThis, Forest, Calm, Headspace: not found. From general knowledge only (Low, unverified): the garden-match games lean on saturated colour, characters and scenery in icons; Calm and Headspace lean on a single simple shape on a flat colour. Please check these in the App Store before relying on the comparison.

Implication: a simple, warm, character-like icon with strong shape is the best-supported direction. The wordmark matters most on the splash, home screen, store graphics and marketing, not in the icon slot.

## 4. Letter-substitution wordmarks

- No direct research found. Related, peer-reviewed: Perea and colleagues (Scientific Reports 2023; "Misspelled logotypes", PMC10587100) show readers encode both letter identity/order and the graphical design of a logotype, and that graphic styling makes letter errors harder to notice. So readers use design cues as well as letters, which suggests a styled o is read as an o when the other letters are intact. (Medium.)
- Instagram's wordmark redesign survey (Pollfish, vendor): only about half found the new wordmark easy to read, and 53% saw "G-Zam"; brand context masks legibility flaws inside the app. Shows that small legibility tweaks can mis-read when stripped of context. (Low.)
- When it works (design reasoning, Medium): the substituted glyph keeps the letter's silhouette and counter, other letters are plain, the pun is visible at a glance, the substitution is at most one or two letters. This logo meets all of those because the ring is a real o.
- When it hurts: the substitute changes the letter's width or counter, petals touch neighbours, or the flower reads as a separate icon. Here the risk is the last one: with five petals, an o that is a ring on a flower can read as a flower-shaped badge or emoji (a blossom, a daisy, a wreath) before it reads as o, especially at a glance in the Flora position.
- Children: I found no grade-2-specific study. Early-reader research concerns letter form confusion (the McNeese University study of K-4 letter identification across fonts; Martinez and Garcia on early readers confusing characters), not logo substitution. Practitioner sources advise against decorative type in kid reading text, but they are opinion. A logo is not running text, and the letter forms here are plain, so I rate the risk Low. Still test the wordmark with a few 7-year-olds: "read this out loud". (Low.)
- Dyslexia: Rello and Baeza-Yates (2013, ASSETS) found sans-serif and roman fonts such as Helvetica, Arial and Verdana read best and effects were modest; I could not confirm claims about spacing or rounded type from this paper. WCAG 1.4.12 text spacing (0.12 em) is a general standard. Nunito Black is a plain, open, round sans with distinct l, r, d and o shapes, so it is a reasonable fit, but extra tight kerning (d-F) and a heavy weight make word shapes denser. Keep the tagline in a regular weight with generous tracking. (Medium for font fit; Low for kerning impacts.)
- Tagline pairing: "Guess words. Grow a garden." works as a small regular-weight line below the solo wordmark. Do not set the tagline in the lockup's dark/green split. (Low, design practice.)

## 5. Kids and adults, "babyish", "casino", lookalikes

- Friendly to both (design reasoning, Medium): rounded terminals, warm muted palette and natural motifs read friendly without primary-colour toy signals. Dusty rose and ochre skew calm and slightly adult-crafty, which suits a mixed audience. The risk is being too quiet for children rather than too babyish.
- Babyish cues to avoid: bubbly lettering with bounce, saturated primaries, cartoon eyes on everything. The current wordmark avoids all of them. The shipping icon's smiley face leans most childlike; the candidate "o" icon leans adult.
- Gambling/casino cues to avoid: gold on deep red/purple, sparkles and coin-like discs, glossy gradients, chunky bevel type. The amber and gold in the dark variant (#F0C060 on #1A2E1A) is the only mildly risky area: gold on dark can drift slot-machine if combined with sparkle or glow in the ad creative. Keep it matte. (Medium.)
- Lookalikes (Low, partly from memory; I could not verify in-store): "Flora" is an existing name across apps (plant ID and focus/timer apps, some with green tree/leaf logos) so the combined "WordFlora" is distinct but the second half is common. Wordle-like apps tend to use tile grids, Wordscapes and Gardenscapes use game-art-heavy icons, Forest uses a tree, Duolingo is a green owl. A flower-O on cream is not close to any of them from memory. Do a trademark and App Store search for "WordFlora" and "Flora" before spending on branding. Not a legal opinion.

## 6. Accessibility (measured)

On cream #FAF7F0:

| Element | Colour | Contrast | Verdict |
|---|---|---|---|
| "Word" letters | #2C3E2C | 10.71:1 | passes AAA |
| "Flora" letters | #2A7A38 | 4.98:1 | passes AA text |
| Amber petals | #DA8B22 | 2.55:1 | below 3:1 |
| Rose petals | #E07A8E | 2.67:1 | below 3:1 |
| Word vs Flora hue split | #2C3E2C vs #2A7A38 | 2.15:1 | weak |

- WCAG logotype text is exempt from contrast requirements, and decorative petals are not information, so none of this is a formal failure. The 3:1 non-text bar (1.4.11) is still a useful target for the petals so they are visible to low-vision users. (High; W3C Understanding docs.)
- Colour vision (simulated): Word/Flora lightness gap stays about 2.1 to 2.2:1 under deuteranopia, protanopia and tritanopia. Amber vs rose is 1.03 to 1.06:1 in every case, so identical in grey. Rose vs green drops to 1.5:1 under protanopia (petals vs letters are separated by the gap, so tolerable). About 8% of men and 0.5% of women have a colour vision deficiency (secondary sources including Cleveland Clinic via Live Science; I could not confirm the NEI attribution). (Medium.)
- Dark mode: the dark variant raises letters to mint (#D4EDD4) and gold (#F0C060, 8.56:1 on #1A2E1A per the build notes). Looks solid. Check the dark-mode rose: build notes give petals 2.0 to 4.2:1.
- Increase Contrast: no dedicated variant exists. Add one with a darker petal and a visible ring edge. (Medium.)
- Icon: the shipping cream-on-green icon is about 4.7:1 for the petals and 3:1 or above for the centre against the ground, passing the shape bar. The candidate "o" icon has amber at about 3.2:1 on green. Both fine.

## 7. Wordmark vs app icon

- Apple's current guidance (Liquid Glass adoption docs, 2025) asks for simple, bold, layered foreground/background shapes, with default, dark, clear and tinted variants. I could not retrieve the HIG's explicit lines about text and single focal point; from general knowledge it recommends against words in the icon and a single clear subject (Medium; verify on developer.apple.com). Sources: developer.apple.com Liquid Glass technology overview and adoption guide.
- Shipping icon (daisy with smile): one focal point, no text, high contrast, large simple shapes, cheerful. Strong at 29 px. Eight pointed petals and a flat amber face.
- Candidate icon (ring-O with 5 amber petals): the same DNA as the wordmark, but it is a letterform. A lone cream "o" in a ring reads as "O", zero, a button, or a radio icon, not as a flower, and the face/emotion is gone. It is more distinctive for a word game but less warm. It also puts a letter in the icon, which is against the spirit of the HIG. My view: weaker than the shipping icon on feel, stronger on brand link.
- Do icon and wordmark feel like one brand? Currently no. Different petal count (8 pointed vs 5 round), palette (cream on green vs amber/rose on cream), and the icon has a face the wordmark lacks. (High, direct observation.)
- Unification options, from least to most change:
  1. Keep the daisy but change to five rounded petals in the wordmark's ellipse shape and add a ring (thick cream ring around the face) so it matches the wordmark's o flower.
  2. Add a small smile or two dot-eyes to the wordmark's Flora o centre (or just on the solo version). Faces and expressions carry emotion strongly (Duolingo evidence above), though the counter of an o is small and a face could harm the letter reading, so test.
  3. Use the wordmark's amber and rose in the icon (amber centre, rose petals) so the pair shares colour.

## 8. Ranked improvements

1. Fix the petals' visibility at small sizes. Use the solo flower (single hero flower) as the default small lockup; in the twin version enlarge the reach or reduce petal count to 5 wider petals so they remain countable at 29 to 60 px. Target at least 3:1 against background (deepen amber toward #C77A12 and rose toward #D0607A in light mode). Evidence: measured 2.55 and 2.67:1; build notes admit five petals cannot be counted at 120 px.
2. Make one flower the hero. Pick the Flora o as the flower, keep the Word o a plain letter or a quiet bud. Fewer details, clearer focal point. Evidence: HIG guidance for icons (single focal point), my viewing of the sheet.
3. Unify the icon with the wordmark: use the same petal shape, count and colours in both, and keep the smile. See section 7. Evidence: observation, plus Duolingo precedent of icon-as-character.
4. Increase lightness contrast between "Word" and "Flora" (darken Word toward #1F2F1F, or lift Flora slightly) so the split survives colour-blindness and greyscale. Evidence: 2.1:1 in all simulations.
5. Tidy the rhythm: reduce the W-o and l-o gaps and the d-F pinch so the word reads as one even line. With a hero flower only on Flora, the Word o needs no extra bearing, which removes the big gap. Evidence: +29% and +45% gaps, -33% d-F.
6. Add an Increase Contrast and a tinted-icon check (tinted variant exists already, verify at 29 px). Evidence: Apple appearance variants.
7. Keep gold matte in dark mode and avoid glow or sparkle in ads to avoid casino cues. Evidence: design practice (Low to Medium).
8. Test with real people: 5 adults, 5 children aged 7 to 9. Ask "what does this say?" and "what kind of game is it?" for the 29 px and 60 px renders. Cheap and the only direct evidence of readability and feel.
9. Run a Google Play or ad-creative test between icon A (shipping daisy) and B (candidate) once there are enough impressions; iOS has no native icon test. Evidence: Appalize, Azur Games case (lifts can reverse by segment).

## 9. Redesign directions worth exploring

1. Hero-flower wordmark: plain "Word" in ink green; a single large five-petal flower o in "Flora"; petals widened, deeper amber or rose; the unified icon shows that same flower. Evidence: icon focal-point guidance, measured petal contrast, 29 px counting failure.
2. Smiling-flower wordmark: the flower o in "Flora" gets a faint two-dot smile or a rounded smiling counter, matching the shipping icon's face. Evidence: faces and character icons outperform abstract in most vendor tests (Low) and carry emotion (Duolingo, Medium). Risk: face in a small counter may hurt o legibility; test.
3. Daisy-ring unification: icon becomes a five-petal cream daisy with a green ring face; wordmark o is the same daisy in a lighter weight. One shape across store, splash, tab. Evidence: current mismatch between 8-petal icon and 5-petal wordmark.
4. Leaf-and-word: replace the Word o flower with a small leaf growing from the d, so there is one flower (Flora) and one leaf (Word), telling "words grow into a garden" in a single line with fewer petals. Evidence: simpler, fewer competing accents; supports the tagline "Guess words. Grow a garden." Risk: leaf motifs are generic (Low).
5. Tile-and-bloom: a rounded letter tile with a flower blooming from the corner, for the icon only; wordmark stays as in direction 1. Evidence: ties to Wordle-like word-game category cues. Risk: lookalike with tile-based games (Low).

## 10. Bottom line

The logo makes sense and is calm and well-crafted, and it is legible, because the flowers are real o's. It will not by itself draw attention in a crowded store: pale petals, a quiet palette and an icon that does not match it all work against that, and no evidence I found shows it would underperform either. It will probably feel pleasant, warm and nature-like to adults and gentle to children; it is less obviously playful. The biggest wins are cheap: stronger, fewer petals, one hero flower, a matching icon with the smile, and a real test with kids and adults.

## Sources

1. Labrecque, L. I., and Milne, G. R. (2012). Exciting red and competent blue: the importance of color in marketing. Journal of the Academy of Marketing Science 40, 711-727. https://link.springer.com/article/10.1007/s11747-010-0245-y (record seen via library catalogues; body not read).
2. Perea, M. et al. Misspelled logotypes: the hidden threat to brand identity. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10587100/ and Scientific Reports 2023, https://www.nature.com/articles/s41598-023-45213-0
3. Rello, L., and Baeza-Yates, R. (2013). Good Fonts for Dyslexia. ASSETS. https://www.changedyslexia.org/publications/pdfs/2013-ASSETS-An%20iOS%20Reader%20Dyslexia.pdf (only snippets read; spacing and rounded-font claims not verified).
4. W3C. Understanding SC 1.4.3 Contrast (Minimum). https://w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
5. W3C. Understanding SC 1.4.11 Non-text Contrast. https://w3c.github.io/wcag21/understanding/non-text-contrast
6. Apple. App icons (HIG), page body could not be retrieved. https://developer.apple.com/design/human-interface-guidelines/app-icons
7. Apple. Liquid Glass overview and Adopting Liquid Glass. https://developer.apple.com/documentation/technologyoverviews/liquid-glass.md and https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass.md
8. MobileAction. Apple Liquid Glass design (secondary). https://www.mobileaction.co/blog/apple-liquid-glass-design/
9. Appalize. App icon A/B testing: data-driven icon design (vendor). https://www.appalize.com/blog/creative-optimization/app-icon-ab-testing-data-driven-icon-design
10. SplitMetrics. MyTona Halloween icons +9% (vendor case). https://splitmetrics.com/cases/mytona-app-icons-halloween-update
11. Azur Games. Tests showed a projected 100% increase from changing the app icon. What really happened? https://azurgames.com/blog/tests-showed-a-projected-100-increase-in-conversion-to-installs-caused-by-changing-the-app-icon-what-really-happened
12. Android Developers Blog (2015). SGN Cookie Jam / store listing experiments story. https://android-developers.googleblog.com/2015/12/android-developer-story-sgn-game-cookie.html
13. AppDrift. Google Play store listing experiments guide (AppTweak 2024 figure quoted, unverified). https://appdrift.co/blog/google-play-store-listing-experiments
14. Duolingo. Reshaping Duo. https://blog.duolingo.com/reshaping-duo/ ; Creative Bloq, Duolingo's redesigned mascot. https://www.creativebloq.com/news/duolingos-redesigned-mascot-is-a-hoot
15. Live Science. Why colour blindness is more common in men (quotes Cleveland Clinic, 1 in 12 men, 1 in 200 women). https://www.livescience.com/health/genetics/why-is-color-blindness-so-much-more-common-in-men-than-in-women
16. McNeese State University. Letter discrimination K-4 across fonts. https://www.mcneese.edu/wp-content/uploads/2020/08/ajpr9.pdf ; ATypI, Typography for new and better readers. https://atypi.org/presentation/typography-for-new-and-better-readers-a-study-of-the-identification-of-typographic-forms-among-early-readers/
17. Pollfish. Instagram wordmark survey (vendor). https://ws.pollfish.com/resources/blog/market-research/instagram-logo-wordmark-update-survey-data/
18. Vistaprint. Logo colour meanings (commercial). https://www.vistaprint.com.au/hub/logo-colour-meanings/
19. Machado, Oliveira and Fernandes (2009). A physiologically-based model for simulation of color vision deficiency (matrices used for my simulation; not re-fetched).
20. In-repo: design-preview/logo/final/notes.md, wordmark.svg, wordmark-dark.svg, compare/sheet-light.png, compare/tiny-zoom.png, icon/png/icon-1024.png, WordFlora/Assets.xcassets/AppIcon.appiconset/AppIcon-default.png.

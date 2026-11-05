"""Hand-written parts of each direction's notes.md (judgements from looking at the PNGs).
build.py fills in every number; this file holds only the prose and the by-eye verdicts. Round 2."""

SPACING_EYE = ('**Round 2b spacing.** The rule now measures against Nunito\'s native r-d. Every Word pair and d-F takes its tightest legal '
               'kern: about -14% on the x band, with no pair closer than 45 u, which keeps the r\'s arm off the d and the a. "Word" is 2655 u '
               'of ink against v2\'s 2853 (-6.9%). At the tightest Flora gaps (l-o, o-r at -14%), no petal arrangement keeps 80% of a petal '
               'visible. Even at the widest legal gaps (+12.5% / +11.0% x, +15.1% / +14.7% o), a full-size flower scaled no lower than 0.94 per petal '
               'reaches only 72%. So, against the brief\'s "do not reopen", two levers were used instead. (1) The Flora o pairs sit at the '
               'legal maximum, still tighter than round 2 (235 vs 272 u). (2) The whole flower is scaled uniformly (hero and unified 0.92, centre 0.91), '
               'the same in the wordmark and the icon. The tightest-gap alternative needed a 0.80 flower, which turns the petals back into '
               'v2-style slivers round a heavy ring (rejected by eye). By eye on `compare/word-alone-320.png` (v2 above v3, same letter size), v3 "Word" is visibly tighter than v2 and o-r-d no longer reads looser: **the P3 eye check passes**. W-o and r-d sit close but clear, and the r\'s arm keeps 45 u from the d.')
A6_SHORT = '"Word" 6.9% narrower than v2 and o-r-d no tighter-looking than needed; P3 eye check passes'

PROSE = {
'hero': dict(
  kind='separate',
  round2=('sRGB PNGs (no ICC profile). The icon centre is now the o with its counter filled gold plus a round amber pistil, on a deep '
          'green ground (#1C3820), so there is no eye and no letter O. The cream-ground version is kept as `icon-alt-cream.svg`. New owner '
          'option `icon-smile*.svg` puts the two-dot-one-arc face on that centre disc. Ring gap 40 to 52 u (mono-solid 60 u). A petal '
          'that would reach the l or the r is now scaled to fit instead of being cut, so every petal keeps a complete rounded tip and the '
          'notch at the l\'s foot is gone. Spacing is solved on both bands. Round 2b re-spaced to the corrected rule (native r-d reference, F-l up to +30% with a 45 u arm gap) and scaled the flower to 0.92.'),
  concept=('One hero flower, nothing else. "Word" is plain ink green (#182818) with no decoration. The Flora o carries one large five-petal '
           'rose flower with **separate** petals: round-ended teardrops with the background showing between neighbours. Light-mode rose '
           '#C9506C is 4.05:1 on cream. The icon is the same flower: same petals, the o\'s silhouette as a gold centre disc, and a round amber pistil.'),
  flower=('Five teardrop petals (cubic, round outer end) from r0 = 110 u to tip T = 505 u (1.91x the o radius), width parameter 172 u, '
          'one petal up and the flower turned -8 degrees; the whole flower is then scaled to 0.92 (round 2b), tip 465 u, 1.76x the o radius. In the wordmark the right and left petals are scaled about the flower centre to '
          'clear the r and the l; the scales are listed under Cuts and fit. The icon uses the nominal, unscaled flower.'),
  icon=('Deep green ground #1C3820 (dark #142414). Rose petals #E26582 (the dark-mode wordmark rose). The centre is the o with its counter '
        'filled in gold #F0C060 (the dark-mode Flora gold), with a round pistil #B8650A whose diameter is 0.40x the ring\'s outer width. '
        'Tinted: grey petals, white disc, grey pistil on black. `icon-alt-cream.svg`: the same flower on cream with the light-mode wordmark '
        'colours (rose #C9506C, green #2E803F disc, amber pistil), rendered at 180/60/29 only so the owner can compare. `icon-smile*.svg`: '
        'the default icon with the face (two dots and one arc, ink #1A2E1A, tilted -8 degrees with the flower) in place of the pistil.'),
  rule=('**The face lives in the icon and in illustrations, never inside a letter.** The smile is an owner option (`icon-smile*.svg`). '
        'It sits on the filled centre disc of the icon. The wordmark o always keeps its open counter and never gets a face: at 29 px tall '
        'the counter is about 5 x 7 px, too small for a face without turning the letter into an emoji.'),
  colour_rule=('The icon uses the dark-mode wordmark colours (rose #E26582, gold #F0C060) on deep green, because the light-mode rose would be '
               'only 2.3:1 on a green ground. The cream alternative uses the light-mode colours exactly.'),
  a3_ok=True,
  a3=('5 petals countable at 60 px in light, dark, mono and mono-solid (`png/*-h60.png`); at 29 px it reads as a small rose flower round the o, not a halo'),
  a6_ok=True, a6_eye=SPACING_EYE, a6_short=A6_SHORT,
  A7=(True, 'reads "WordFlora" at 29 px in all seven variants; the o keeps its full ring and open counter inside a 1.49 px gap (mono-solid 1.72 px) and reads as a letter'),
  A8=(True, '1024, flat deep-green rect, no text or transparency; one flower; at 29 px a rose flower with a gold centre. The centre is a disc with a round pistil, so it reads neither as an O nor as an eye. Smile option: face legible at 60 px, fades to a gold disc at 29 px'),
  A9=(True, 'light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px'),
  A11=(True, 'baseline flat, no bounce; no primaries, gloss, sparkle or bevel; no face in the default icon; the smile option is two dots and one arc'),
  A12=(True, 'by description only, reviewers still to confirm. The nearest family is the Mary Quant daisy (five round petals around a round centre, fashion and cosmetics). Separate teardrop petals, the -8 degree tilt and the gold disc on deep green keep it apart. Not close to Blossom, Flora, Forest, PictureThis, Seek, Duolingo, Finch, Headspace, Calm, Wordscapes, Lily\'s Garden or Gardenscapes. The smile option is not Flowey: rose petals, not yellow; gold centre, not white. Nothing copied'),
  pixel_checks='See `compare/pixel-checks.json`: exact sRGB fills in `png/wordmark-h320.png`, sheet margins, and the background-coloured pixel either side of the ring on `png/wordmark-mono-solid-h29.png`.',
  weak=[
    'The right and left petals are drawn slightly smaller in the wordmark than in the icon (scales listed above), so the wordmark flower is not perfectly regular. At 320 px the difference is visible only if you look for it.',
    'Height at 172 pt is 29.9 pt (round 2b), not 31.5. The tighter word is shorter overall, and the flower is scaled to 0.92.',
    'Petals are 8% smaller than in round 2, so the flower is a little less dominant against the ring at 29 px.',
    'In greyscale the rose petals and the green Flora letters are the same mid grey (1.13:1); only the 1.5 px gap separates them.',
    'The smile option sits close to the shipping icon\'s idea (a smiling flower), so it is a smaller break from the old icon than the plain pistil.',
    SPACING_EYE,
  ]),
'unified': dict(
  kind='fused',
  round2=('sRGB PNGs. The icon inverts the wordmark\'s roles, as in the shipping icon: petals cream #FBF4E4, centre amber #F5BC48, face ink '
          '#1F321F (7.93:1 on the amber) and tilted -8 degrees with the bloom, which moves it away from Flowey. Light bloom #C27200 becomes '
          'the more orange #C86800 (at least 3.27:1 on cream under every simulation). The mono-solid bloom gets five radial slits so it reads '
          'as five petals, not a gear. Ring gap 52 u (mono-solid 60 u). Round 2b re-spaced to the corrected rule and scaled the flower to 0.92. Lobes that '
          'would reach a neighbour are scaled to fit, with at most 0.5% left to tuck behind the letter.'),
  concept=('One flower for the whole brand, with the smile. Five round petals (circles) fused into one scalloped bloom: orange-amber in the '
           'wordmark (#C86800 light, #E59A2E dark), cream in the icon. In the wordmark the bloom sits behind the Flora o. In the icon the same '
           'five petals surround the o\'s outer silhouette, filled amber and wearing the face.'),
  flower=('Five circles of radius 200 u on a 295 u circle (tips at 495 u, 1.88x the o radius), one up, turned -8 degrees like the hero, then scaled to 0.92 (round 2b): tips 455 u. '
          'Adjacent circles overlap only under the ring, so outside the gap each lobe shows as its own petal.'),
  icon=('Green ground #356B25. Cream petals #FBF4E4 (5.84:1). Centre: the o\'s outer silhouette in amber #F5BC48, with the face in ink #1F321F '
        'tilted -8 degrees. Dark: #EFE6C8 petals, #E59A2E centre, face #0F1C0F (7.54:1), on #1A2E1A. Tinted: light-grey petals, mid-grey centre, black face.'),
  rule=('**The face lives in the icon and in illustrations, never inside a letter.** The flower is always five round petals around an '
        'o-shaped centre. In type the centre is the letter o: ring, open counter, no face. In the icon the centre is filled and wears the face: '
        'two dots and one arc, nothing more, turned with the bloom. At 29 px tall the o counter is about 5 x 7 px, so the wordmark and the solo '
        'lockup carry no face.'),
  colour_rule='The icon inverts the wordmark\'s roles: petals cream, centre amber (the shipping icon\'s logic). The wordmark is petals amber, letters green.',
  a3_ok=True,
  a3='5 lobes countable at 60 px in light, dark, mono and mono-solid (slits); at 29 px the scalloped orange bloom reads as a flower with the o in its centre',
  a6_ok=True, a6_eye=SPACING_EYE, a6_short=A6_SHORT,
  A7=(True, 'reads "WordFlora" at 29 px in all variants; the green o inside a cream gap on the orange bloom reads as o. Mono-solid: the slits split the bloom into five petals and the 60 u gap keeps the o clear, so it no longer reads as a cog'),
  A8=(True, '1024, flat green rect, no text or transparency; one flower; a smiling cream daisy with an amber face at 29 px; at 60 px the eyes (about 3 px) and the tilted smile are legible'),
  A9=(True, 'light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px'),
  A11=(True, 'no bounce, gloss, sparkle or bevel; amber is matte and not gold-on-red; face is exactly two dots and one arc, icon only'),
  A12=(True, 'by description only, reviewers to confirm. Flowey (Undertale) is yellow petals round a white face. This icon is now cream petals round an amber face, tilted, which is the shipping WordFlora daisy\'s logic, and it is no longer a yellow-petal, white-face match. It stays in the generic "smiling daisy" family (stickers, emoji), close to the shipping icon by design. Nothing copied'),
  pixel_checks='See `compare/pixel-checks.json`: exact sRGB fills, sheet margins, the ring gap pixel on mono-solid-h29, and a near-background pixel along each of the five slits at 29 px.',
  weak=[
    'The icon is close to the shipping icon (a smiling daisy), so the brand change is small. That is good for continuity and weak for distinctiveness.',
    'Amber #C86800 vs the green ring is low in contrast, so the 1.49 px gap does all the separating.',
    'Dark-mode Flora is light green (#8FCB8F), not v2\'s gold, to keep "petals amber, letters green".',
    'The right lobe is fitted against the r with a short flat (about 26 px at 320 px tall) where it meets the r\'s stem; the left lobe is scaled to 0.965 and keeps a round end.',
    SPACING_EYE,
  ]),
'centre': dict(
  kind='fused',
  round2=('sRGB PNGs. The o ring is Flora green again (#2E803F light, #8FCB8F dark), so "Flora" is one colour and the rose disc alone marks '
          'the flower. The bloom is rebuilt from r = 215 u circles on a 270 u circle (tips 485 u), turned -8 degrees: notches 6.4 to 7.5 px at '
          '60 px on all five lobes, no straight edge longer than 5 px at 320 px; the left lobe is scaled to 0.963 to clear the l. Icon: ring and counter scaled to 0.75x, counter filled with '
          'the ring colour plus a round pistil, tinted centre mid-grey; ground #1F3D24 so the petals stay at least 3.44:1 under protanopia. Ring gap 52 u (mono-solid 60 u). Round 2b re-spaced to the corrected rule and scaled the flower to 0.91.'),
  concept=('A solid rose bloom disc (#CF5D78) with five clear scallops sits behind a plain green Flora o. It is a different geometry from '
           'the other two: one fused disc shape, not separate petals or round lobes. At 29 px the flower reads as one shape, a rose blossom '
           'with the o as its heart. In round 1 the o was recoloured amber. Both reviews read that as a donut or a badge, so the colour change is withdrawn.'),
  flower=('Five circles of radius 215 u on a 270 u circle (tips at 485 u, 1.84x the o radius), one up, turned -8 degrees, then scaled to 0.91 (round 2b): tips 441 u. Neighbouring '
          'circles overlap outside the ring, so the bloom is one disc with notches about 7.5 px deep at 60 px (3.6 px at 29 px).'),
  icon=('Deep green ground #1F3D24. Rose bloom #E8758F. The centre is the o\'s silhouette at 0.75x, filled amber #F0B848, with a round pistil '
        '#C27A18 (diameter 0.40x the scaled ring width). Dark: #D95B7A, #E9A93A, #A8620C on #132313. Tinted: light-grey bloom, mid-grey centre, dark-grey pistil.'),
  colour_rule=('The wordmark is rose and green only. Amber appears only as the icon\'s flower centre, because a green centre would vanish on '
               'the green ground. This is a palette deviation from R3, stated here.'),
  a3_ok=True,
  a3='notches 6.4 to 7.5 px at 60 px on all five lobes, so five can be counted in light, dark, mono and mono-solid; at 29 px one rose flower shape',
  a6_ok=True, a6_eye=SPACING_EYE, a6_short=A6_SHORT,
  A7=(True, 'reads "WordFlora" at 29 px in all variants; the o is plain Flora green inside a cream gap, so "Flora" is one word in one colour. Mono-solid: the scallops are deep enough to read as a flower rather than a seal, but the bloom is still one solid shape'),
  A8=(True, '1024, flat green rect, no text or transparency; a pink blossom with a small amber centre and a pistil; reads as a flower at 29 px; tinted centre is mid-grey, not a white donut'),
  A9=(True, 'light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px'),
  A11=(True, 'no bounce, gloss, sparkle or bevel; no face'),
  A12=(True, 'by description only, reviewers to confirm. The silhouette is in the ume/sakura crest and cherry-blossom emoji family, which is generic and not an app mark. It is not confusable with Duolingo, Forest, Headspace, Calm, Finch, Wordscapes, Lily\'s Garden, Gardenscapes, PictureThis, Seek, Flora, Blossom or Planta. Nothing copied'),
  pixel_checks='See `compare/pixel-checks.json`: exact sRGB fills, sheet margins and the ring gap pixel on mono-solid-h29.',
  weak=[
    'With the o back in green, the rose disc against the green o is low in contrast (1.28:1, 1.01 under protanopia). The 1.49 px gap carries the separation.',
    'Mono-solid stays one solid black disc around the o. The scallops help, but it is still the most badge-like of the three in Increase Contrast.',
    'The icon centre is amber, a colour the wordmark no longer uses (see the colour rule).',
    'The cherry-blossom silhouette is generic: pleasant, but the least ownable of the three.',
    SPACING_EYE,
  ]),
}

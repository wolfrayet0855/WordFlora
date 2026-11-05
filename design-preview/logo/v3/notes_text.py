"""Hand-written parts of each direction's notes.md (judgements from looking at the PNGs).
build.py fills in every number; this file holds only the prose and the by-eye verdicts."""

COMMON_SPACING = ('Kerning rule shared by all three: equalising mean x-height gaps opens the round pairs by 77 to 108 u '
                  'compared with Nunito\'s native spacing, so the whole word is a little more open than v2. The air is now even, '
                  'though, and no longer bunched around the flowers.')

PROSE = {
'hero': dict(
  kind='separate',
  concept=('One hero flower, nothing else. "Word" is plain ink green (#182818) with no decoration. The Flora o carries one large five-petal '
           'rose flower with **separate** petals. Each petal is a round-ended teardrop and the background shows between neighbours, so the '
           'five can be counted at 60 px and read as five rose dots around the o at 29 px. Light-mode rose is deepened to #C9506C (4.05:1 '
           'on cream), so light mode now works on the same lightness principle as v2\'s dark mode. The icon is the same flower: same '
           'petals, the o ring as the flower\'s centre, its counter filled amber so it reads as a pistil and not as the letter O. ' + COMMON_SPACING),
  flower=('Five teardrop petals (cubic, round outer end) from r0 = 110 u to tip T = 505 u (1.91x the o radius, v2 was 1.72x), width '
          'parameter 172 u, one petal up and the whole flower turned -8 degrees. The tilt keeps the right petal above the r\'s shoulder '
          'and both side petals at least 80% visible; at 0 degrees the right petal was only 76% visible. Rose, not two colours: amber '
          'vs rose carried nothing in greyscale.'),
  icon=('Cream background (#FAF7F0). Rose petals, green ring (the Flora o), counter filled amber #E9A43A. Dark: gold ring with a deep '
        'amber counter on #1A2E1A. Tinted: grey petals, white ring, light-grey counter on black.'),
  a3_ok=True,
  a3=('5 petals countable at 60 px in light, dark, mono and mono-solid (`png/*-h60.png`); at 29 px it reads as a small rose flower round '
      'the o, not a halo'),
  A7=(True, 'reads "WordFlora" at 29 px in all seven variants; the o keeps its full ring and open counter inside a 1.15 px gap, read as a letter'),
  A8=(True, '1024 square, flat cream rect, no text, no transparency; one flower; still a flower at 29 px (5 rose petals visible); no face'),
  A9=(True, 'light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px'),
  A11=(True, 'baseline flat, no bounce; no primaries, gloss, sparkle or bevel; no face anywhere'),
  A12=(True, 'by description only, reviewers still to confirm: a five-petal flower round a letter is close to no well-known mark. Blossom and Flora '
             '(plant/focus apps) use leaves or trees; Lily\'s Garden and Gardenscapes use illustrated scenes; PictureThis and Seek use leaf or '
             'lens marks; Duolingo, Finch, Forest, Headspace, Calm and Wordscapes are unrelated shapes. The cream-ground icon is a generic '
             '"flower" glyph, so it is distinctive only through the green o ring. Nothing copied'),
  weak=[
    'The side petals tuck behind the l and the r (84 to 87% visible). At 320 px you can see the tuck edge and a small notch where the l\'s foot curls under the lower-left petal.',
    'The F\'s middle arm is 32 u from the l (about 0.9 px at 29 px tall). That is the cost of keeping F-l within +15%, and at 29 px the arm and the l nearly touch, green on green.',
    'The flower is tilted -8 degrees. It reads as a natural tilt, but it is not symmetric.',
    'Icon: the cream ground is quieter on a home screen than the shipping green, and the green ring with an amber oval can read as an eye. The tinted icon reads most like a letter O.',
    COMMON_SPACING,
  ]),
'unified': dict(
  kind='fused',
  concept=('One flower for the whole brand, with the smile. Five **round** petals (circles) fused into a single scalloped bloom, in amber '
           '(#C27200 light, 3.44:1 on cream; #E59A2E dark). It is the shipping icon\'s friendliness and the wordmark\'s o in one geometry. In the '
           'wordmark the bloom sits behind the Flora o; in the icon the exact same five petals surround the o\'s outer silhouette, filled '
           'cream, wearing the face. The colour logic is fixed in both modes: petals amber, letters green ("Flora" #2E803F light, '
           '#8FCB8F dark). ' + COMMON_SPACING),
  flower=('Five circles of radius 200 u on a 295 u circle (tips at 495 u, 1.88x the o radius), one up, turned -8 degrees like the hero. '
          'Adjacent circles overlap only under the ring, so outside the gap each lobe shows as its own petal with notches 7 to 9 px deep at 60 px.'),
  icon=('Green background #356B25 (amber petals #F5BC48 at 3.71:1 on it). The centre is the o\'s outer silhouette (the o with its counter '
        'filled) in cream #FBF4E4, with the face in ink. Dark: #E59A2E petals, #EFE6C8 centre, on #1A2E1A. Tinted: grey petals, white centre, black face.'),
  rule=('**The face lives in the icon and in illustrations, never inside a letter.** The flower is always five round amber petals around an '
        'o-shaped centre. In type the centre is the letter o: ring, open counter, no face. In the icon (and any mascot or illustration use) the '
        'centre is filled and wears the face: two dots and one arc, nothing more. Tested against the brief\'s condition: at 29 px tall '
        'the o counter is only about 5 x 7 px, too small for two eyes and a mouth without filling the counter. A face there would '
        'stop the o reading as a letter, so the wordmark and the solo lockup carry no face.'),
  a3_ok=True,
  a3=('5 lobes countable at 60 px in light, dark, mono and mono-solid; at 29 px the scalloped amber bloom reads as a flower with the o in its centre'),
  A7=(True, 'reads "WordFlora" at 29 px in all variants; the green o inside a cream gap on the amber bloom reads as o. Mono-solid keeps a visible white gap, so the o survives'),
  A8=(True, '1024, flat green rect, no text or transparency; one flower; reads as a smiling flower at 29 px, and at 60 px the eyes (about 3 px) and the smile are legible'),
  A9=(True, 'light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px'),
  A11=(True, 'no bounce, gloss, sparkle or bevel; amber is matte and not gold-on-red; face is exactly two dots and one arc, icon only'),
  A12=(True, 'by description only, reviewers to confirm: the nearest family is "smiling flower" art (Takashi Murakami\'s many-petalled grinning '
             'flowers, generic sticker daisies). This one has five round petals and a small two-dot face, so it is not confusable with those. '
             'No app mark among Duolingo, Forest, Headspace (orange dot), Calm, Finch, Wordscapes, Lily\'s Garden, Gardenscapes, PictureThis, Seek, '
             'Flora, Blossom or Planta uses a five-round-petal smiling flower. Closest in spirit: the shipping WordFlora icon itself. Nothing copied'),
  weak=[
    'The side lobes tuck behind the l and the r (85 to 89% visible). At large sizes there is the same small notch at the l\'s foot as in hero.',
    'Light amber #C27200 is ochre-orange and reads slightly brown in renders; it is the lightest amber that still reaches 3:1 on cream. Amber vs the green ring is 1.33:1, so the 1.17 px gap does the separating.',
    'Dark-mode "Flora" changes from v2\'s gold to light green (#8FCB8F), to keep "petals amber, letters green". That gives up the gold-on-dark look the critique liked.',
    'The smile appears only in the icon (by rule), so the wordmark alone is less warm than the icon.',
    'Same F-l (32 u) and tracking notes as hero.',
  ]),
'centre': dict(
  kind='fused',
  concept=('My own direction, "centre ring". The Flora o ring is recoloured as the flower\'s centre (deep amber #A65A00, 4.81:1 on cream; gold '
           '#F0C060 on dark). It sits on a **solid rose bloom disc** (#CF5D78) with shallow scallops, so at 29 px the flower reads as one shape: '
           'a rose blossom with an amber heart. Colour alone separates the decorated o from the green letters, and lightness separates the '
           'bloom from the background and from the ring (via a real gap). Geometry differs from the other two because it is a disc, not '
           'petals. The colour logic differs too: the letter itself changes role. ' + COMMON_SPACING),
  flower=('Five circles of radius 250 u on a 230 u circle (tips at 480 u, 1.82x the o radius), one up, no tilt. The circles overlap far '
          'outside the ring, so the bloom is a disc with notches about 5 px deep at 60 px (2.5 px at 29 px), like a plum blossom.'),
  icon=('Deep green background #24472A; rose bloom #E8758F, amber ring #F0B848, counter filled deeper amber #D08A22 (tone on tone, so it reads '
        'as a flower centre rather than a letter O). Dark: #D95B7A, #E9A93A and #B8700E on #132313. Tinted: greys on black.'),
  a3_ok=True,
  a3=('marginal: at 60 px the top and two lower lobes are clear, and the two side lobes show as shoulders behind the l and the r (notch about 2.9 px). '
      'Five can be counted in light, dark and mono, but only just. At 29 px it reads as one rose flower shape, the stated aim'),
  A7=(True, 'reads "WordFlora" at 29 px in light, dark and mono; the amber o is a letter in its own colour. Risk: in mono-solid the black scalloped disc around the o can read as a cog or rosette badge, though the o still reads through its white gap'),
  A8=(True, '1024, flat green rect, no text or transparency; one plum-blossom flower; reads as a flower at 29 px; no face'),
  A9=(True, 'light, dark, mono, mono-solid each rendered and inspected at 29 and 60 px'),
  A11=(True, 'no bounce, gloss, sparkle or bevel; amber is matte; no face'),
  A12=(True, 'by description only, reviewers to confirm: a five-lobed disc is the classic Japanese plum-blossom (ume) crest shape, which is '
             'heraldry, not an app mark. None of Duolingo, Forest, Headspace, Calm, Finch, Wordscapes, Lily\'s Garden, Gardenscapes, PictureThis, '
             'Seek, Flora, Blossom or Planta uses it. The tinted icon could be mistaken for a donut or an "O" button, which is the critique\'s worry about the v2 icon. Nothing copied'),
  weak=[
    'The ring has to be a deep, slightly brown amber (#A65A00) to stay at 4.5:1 as a letter. Any lighter amber looks better but drops below 4.5:1.',
    'The o in a third colour splits "Flora" in colour as "Fl-o-ra". The word still reads, but the Word/Flora split is no longer the only colour change.',
    'Mono-solid (Increase Contrast) turns the bloom into a black scalloped disc that can read as a cog or rosette badge.',
    'The lobes are shallow by design: they are easy to see at 29 px as one shape, but only marginally countable at 60 px on the sides.',
    'In the icon the centre (ring plus counter) is large against the petals, and the tinted icon leans towards "O" or a donut.',
    'Same F-l (32 u) and tracking notes as hero.',
  ]),
}

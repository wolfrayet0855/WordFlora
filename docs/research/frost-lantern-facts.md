# Frost & Lantern facts: robin, wren, snowdrop, hellebore (research draft)

Status: research only, nothing wired up. Rules: one sentence, under 90 characters and 16 words, `CopySafety.check` empty,
no death or cold-danger framing, no toxicity, no picking or tasting, calm for under-13s.

**Source access caveat.** From this environment RSPB, Cornell All About Birds, RHS and Kew pages returned 403/404, so
none could be read directly. BTO BirdFacts (wren, robin), Sussex Wildlife Trust and Wikipedia (with its own citations)
were read. Search snippets covered Kew (snowdrop), Woodland Trust and Cambridge University Botanic Garden. Tags:
**[verified]** = read on a page of the named source (or a primary citation it carries); **[reported]** = seen only through
a secondary page or search snippet, or fewer than two authoritative sources reached. The owner's 20-minute check should
open the RSPB / RHS / Kew pages to upgrade the [reported] claims.

## CopySafety banned list (literal, from `WordFlora/Rules/CopySafety.swift`)

miss, lonely, alone, waiting, abandon, neglect, forgot, forget, die, dies, died, dying, dead, lost, empty, left, broken,
lose streak, broken streak, last chance, hurry, now or never, expires, only, last, smart, genius, talented,
best gardener, better than, beat. Matching is whole-word (`\b...\b`), case-insensitive. Every candidate below was run
through that exact regex in a script: no hits.

## House style found

- `Words.json` entries carry `hint`, `hint2` (two clues, no name in them, about 40 to 70 characters) and `fact`.
  Shipped: `l2-robin` (hint "A bird with a bright orange-red chest.", fact "Robins sing early in the morning.") and
  `l4-snowdrop` (hint "A tiny white flower that pokes up through late winter frost.", fact "It is one of the first
  flowers to bloom each year."). Wren and hellebore do not exist in `Words.json` or `Plants.json` yet.
- Visitor facts (`docs/research/visitor-facts.md`): plain present tense, hedged with "can", "some", "about", "most".
- Note: the existing snowdrop `hint` says "frost"; fine, but new copy should stay with "winter".

## Robin (European robin, *Erithacus rubecula*)

- R1 "Robins sing all year round, even in winter." (43 / 8)
  - Both sexes sing through the year, including winter. Wikipedia "European robin" citing RSPB/Hume (2002) [verified at
    the cited level]; Countryfile, Birdfact, EL Education and RSPB Belfast group blog agree [reported].
  - BTO BirdFacts page has no song text, RSPB species page not reachable, so two named authorities not both confirmed.
  - https://en.wikipedia.org/wiki/European_robin , https://www.bto.org/understanding-birds/birdfacts/robin ,
    https://group.rspb.org.uk/belfast/news-blogs/blog/the-robin/
- R2 "In towns, some robins sing at night near bright lights." (55 / 10)
  - Robins sometimes sing at night, mainly where there is night lighting (Da Silva et al. 2014; Fuller, Warren & Gaston
    2007, both cited on Wikipedia) [reported]. Hedged with "some". "Street lights" in the draft is a fair reading but
    the papers say artificial light and noise, so "bright lights" is the safe wording.
  - Not confirmed on RSPB/BTO/Cornell pages. Weaker than R1.

## Wren (Eurasian wren, *Troglodytes troglodytes*; "wren" in the UK)

Species: the art is the Eurasian wren. The Audubon page for "Winter Wren" now describes *Nannus hiemalis* (the North
American species), so do not cite Audubon or Cornell "Winter Wren" for these facts. Use the name "Wren".

- W1 "A wren is tiny, but its song is remarkably loud." (48 / 10)
  - BTO BirdFacts: full song is "remarkably loud!" for such a tiny bird; adults average 9.9 g [verified]. Sussex Wildlife
    Trust: under 10 g, long high-pitched trill carrying above larger songbirds [verified]. Wikipedia: about 10 g,
    Cramp 1988 [verified]. Two sources read.
  - Do not use "loudest bird for its size" or "10 times louder than a cockerel": the second is [citation needed].
  - https://www.bto.org/understanding-birds/birdfacts/wren , https://sussexwildlifetrust.org.uk/news/a-bundle-of-winter-wrens
- W2 "Wrens sometimes huddle together to share warmth in a snug winter roost." (71 / 12)
  - Sussex Wildlife Trust: in winter wrens share roosts and huddle to conserve heat; most are small groups [verified].
    Wikipedia: in severe weather wrens roost in small groups in snug holes and old nests [reported, uncited there].
    RSPB not reachable [reported].
  - The draft's "nest box" is NOT confirmed: BTO, Sussex WT, Wikipedia and Audubon do not mention nest boxes. Roosts in
    nest boxes are widely reported by blogs, but no authority was read. Use "roost" and drop "nest box" unless RSPB
    confirms. Dropped on purpose: "lifesaving", counts such as "61" or "60", and the "40% survival" blog claim.

## Snowdrop (common snowdrop, *Galanthus nivalis*)

- S1 "Snowdrops often bloom in January and February." (46 / 7)
  - Kew: January to March window (search snippet) [reported]; Woodland Trust: normally January and February [reported];
    Wikipedia: January to April in the northern temperate zone, citing Bishop, Davis & Grimshaw 2002 [verified];
    Cambridge University Botanic Garden listing agrees. Hedged with "often". Northern Hemisphere wording; if the app is
    used in the south, "in late winter" is safer but then needs a hemisphere hedge too.
  - https://www.kew.org/plants/common-snowdrop , https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/plants/wild-flowers/snowdrop/
- S2 "Snowdrop leaves have tough, hard tips that help them push up through soil." (74 / 13)
  - Cambridge University Botanic Garden: leaves have specially hardened tips to break through frozen soil [reported];
    Wiltshire Wildlife Trust, Duchy of Cornwall Nursery repeat it (French name *perce-neige*, "snow piercer") [reported].
    Wikipedia "Galanthus" and "Galanthus nivalis" do NOT state it. RHS/Kew not reached. Only one institutional
    source, so it does not yet meet the two-source rule. Worded "through soil", not "frozen ground", to avoid cold framing.
  - https://www.botanic.cam.ac.uk/the-garden/gardens-plantings/snowdrops/

## Hellebore (the Lenten rose, *Helleborus orientalis*, is the one drawn)

- H1 "Hellebore flowers have petal-like parts called sepals that stay on for weeks." (77 / 12)
  - Wikipedia "Helleborus": five petal-like sepals; they remain on the plant sometimes for many months (Herrera 2005,
    *American Journal of Botany*) and individual flowers often remain a month or more [verified for sepals persisting;
    "weeks" is the safe lower bound]. Gardens Illustrated, Gardenia and nursery pages agree [reported]. RHS/Kew not
    reached, so the second authority is missing. Does not use "last" (banned).
  - https://en.wikipedia.org/wiki/Helleborus
- H2 "Hellebores often flower in winter and early spring." (51 / 8)
  - Wikipedia: Christmas rose in the depths of winter, Lenten hellebores in early spring (uncited there) [reported];
    several garden sites give late winter to early spring [reported]. Hedged with "often". RHS/Kew not reached.

## Suggested clues (`hint` / `hint2`, same pattern as `Words.json`; no name in the clue)

| Plant or visitor | hint | hint2 |
|---|---|---|
| Robin (exists) | keep "A bird with a bright orange-red chest." | keep "It hops on the lawn looking for worms." |
| Wren (new) | "A tiny brown bird with a short tail that points up." (BTO: small, chestnut brown, short cocked tail [verified]) | "It is very small, but its song is loud." |
| Snowdrop (exists) | keep existing hint | keep "Its white bells hang down like little lamps." |
| Hellebore (new) | "A nodding, cup-shaped flower that blooms in winter and early spring." | "Its showy parts are not petals. They are called sepals." |

## Summary table

| Species | Chosen fact | Chars / words | Sources | Tag | CopySafety (31 entries) |
|---|---|---|---|---|---|
| Robin | R1 "Robins sing all year round, even in winter." | 43 / 8 | Wikipedia (cites RSPB, Hume 2002); Countryfile, Birdfact, RSPB Belfast blog | [reported] | pass, none |
| Wren | W1 "A wren is tiny, but its song is remarkably loud." | 48 / 10 | BTO BirdFacts; Sussex Wildlife Trust; Wikipedia (Cramp 1988) | [verified] | pass, none |
| Snowdrop | S1 "Snowdrops often bloom in January and February." | 46 / 7 | Kew (snippet); Woodland Trust; Wikipedia (Bishop et al. 2002) | [reported], one source verified | pass, none |
| Hellebore | H1 "Hellebore flowers have petal-like parts called sepals that stay on for weeks." | 77 / 12 | Wikipedia (Herrera 2005); Gardens Illustrated; Gardenia | [reported] | pass, none |

Backups: R2 (55 / 10), W2 (71 / 12), S2 (74 / 13), H2 (51 / 8), all pass CopySafety. Note the draft's snowdrop line
"Their hard leaf tips push up through cold ground" and the wren "nest box" line are the two draft claims not confirmed.

## Could not be verified

- Every RSPB, Cornell, RHS and Kew page: 403/404 or only search snippets. No claim has two directly read authoritative
  sources except W1 (BTO plus Sussex Wildlife Trust, both read).
- Robin night singing near street lights on RSPB/BTO (only via peer-reviewed papers cited on Wikipedia).
- Wren roosting in nest boxes (draft claim): no authority found. Roosting in general: Sussex WT only.
- Snowdrop hardened leaf tips on RHS/Kew (only Cambridge University Botanic Garden and secondary pages).
- Hellebore sepal persistence and flowering time on RHS/Kew (only Wikipedia citing Herrera 2005, plus garden sites).
- Not tried: Royal Botanic Garden Edinburgh pages and RSPB via a browser.

## Ruling (lead, 2026-11-07, from docs/pm/weak-spots-review-2.md)
Robin fact is reworded because "all year round" over-claims (robins go quiet in the late-summer moult): "Robins sing through the winter, not just in spring." (52 chars, 9 words, CopySafety clean). Wren, snowdrop and hellebore ship as written; backups R2/S2/H2 stay ready if a source check contradicts. Owner check (10 min): RSPB robin, Kew snowdrop, RHS hellebore pages.

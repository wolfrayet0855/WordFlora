# Frost & Lantern facts: source check (2026-11-07)

Checks the four lines chosen in `docs/research/frost-lantern-facts.md` (including the lead's robin rewording).
RSPB, RHS, Kew and Woodland Trust pages returned 403 to automated fetches, so the Woodland Trust quote below comes from a
search snippet of its species page; every other quote was read on the page itself. Lengths and the
`CopySafety.check` result were re-run with the exact banned list and whole-word, case-insensitive regex from
`WordFlora/Rules/CopySafety.swift`.

## Summary

| Species | Line | Chars / words | CopySafety | Verdict | Change |
|---|---|---|---|---|---|
| Robin | "Robins sing through the winter, not just in spring." | 51 / 9 | clean | Confirmed (European robin only) | None |
| Wren | "A wren is tiny, but its song is remarkably loud." | 48 / 10 | clean | Confirmed | None |
| Snowdrop | "Snowdrops often bloom in January and February." | 46 / 7 | clean | Confirmed (Northern Hemisphere) | None |
| Hellebore | "Hellebore flowers have petal-like parts called sepals that stay on for weeks." | 77 / 12 | clean | Confirmed | None |

The robin line is 51 characters, not 52 as the ruling note says. It is still well under the limit.

## Robin: confirmed, European robin only

Line: "Robins sing through the winter, not just in spring."

- Wikipedia, European robin: "Both the male and female sing throughout the year, including during the winter, when they
  hold separate territories." and "During the winter, the robin's song is more plaintive than the summer version."
  https://en.wikipedia.org/wiki/European_robin
- BBC Wildlife (Discover Wildlife), robin song: "Robins sing all year round, but their songs become more of a warning call
  in winter" and "Both male and female birds hold their territories and will drive off intruders using their song".
  https://www.discoverwildlife.com/animal-facts/birds/robin-song
- The lead was right to drop "all year round". Several sources say robins go quiet for a few weeks in late summer while
  they moult, for example "Only for a short period in late summer while they are moulting and inconspicuous do they stop
  singing" (search snippet, secondary sources). The current line only claims winter, so it avoids that problem.

Which robin, and does the line hold for both:
- The pack means the **European robin** (*Erithacus rubecula*). The existing `l2-robin` hint ("A bird with a bright
  orange-red chest") and the UK framing (wren, snowdrop, Lenten rose) both point to it.
- The line is **not true for the American robin** (*Turdus migratorius*), which is a different bird (a thrush). Its males
  mostly start full song in late winter or early spring. In winter it flocks and gives "tuk" calls rather than song
  (Illinois Extension "Voice of the Wild" ep. 78, https://extension.illinois.edu/podcasts/voice-wild/episode-78-american-robin-voice-wild ;
  Vassar sensory ecology blog citing Birds of North America, https://pages.vassar.edu/sensoryecology/?p=1140 ).
- A US child could read "robins" as the American bird. This is a low risk because the art is the European robin. If the
  lead wants to rule it out, an optional variant that passes CopySafety: "In Britain, robins sing through the winter, not
  just in spring." (63 / 11). I would ship the current line as is.

## Wren: confirmed

Line: "A wren is tiny, but its song is remarkably loud."

- BTO BirdFacts, Wren: wrens are "amongst the UK's smallest songbirds" (adults average about 9.9 g), "in full song which
  - for such a tiny bird - is remarkably loud!" https://www.bto.org/understanding-birds/birdfacts/wren
- Sussex Wildlife Trust, "A bundle of winter wrens": "Though weighing under 10g, the Wren's voice is bold and loud;" and
  its song is "reaching above that of larger songsters".
  https://sussexwildlifetrust.org.uk/news/a-bundle-of-winter-wrens
- Wikipedia (Eurasian wren) also gives "weighs around 10 g". Its "ten times louder, weight for weight, than a cockerel"
  line is tagged [citation needed], so do not use it.
- Region: the art is the Eurasian wren. The line also holds for the North American winter wren and house wren, which are
  also tiny and loud, so a US reader will not be misled.

## Snowdrop: confirmed (Northern Hemisphere)

Line: "Snowdrops often bloom in January and February."

- Woodland Trust, snowdrop species page (search snippet, page itself returned 403): snowdrops "normally flowers in
  January and February, but there are an increasing number of December flowerings being recorded".
  https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/plants/wild-flowers/snowdrop/
- Wikipedia, *Galanthus nivalis*: "flowering between January and April in the northern temperate zone (January–May in the
  wild)" and "Snowdrops are among the first bulbs to bloom in spring".
  https://en.wikipedia.org/wiki/Galanthus_nivalis
- Commercial bulb sellers (Ashridge, Future Forests) also list January to February. These are supporting sources only.
- "Often" covers the earlier (December) and later (March, April) flowerings. The months only hold in the Northern
  Hemisphere (UK, Europe, US). In Australia or New Zealand, late winter falls in the middle of the year (not checked
  against a source). If the app's southern-hemisphere audience matters, a CopySafety-clean variant is "Snowdrops often bloom
  in late winter, around January and February." (66 / 10). That still names northern months, so the only fully
  hemisphere-neutral option is "Snowdrops often bloom in late winter." I would keep the current line.

## Hellebore: confirmed

Line: "Hellebore flowers have petal-like parts called sepals that stay on for weeks."

- Wikipedia, *Helleborus*: "The flowers have five petal-like sepals surrounding a ring of small, cup-like nectaries" and
  "The sepals do not fall as petals would, but remain on the plant, sometimes for many months."
  https://en.wikipedia.org/wiki/Helleborus
- University of Missouri IPM (Missouri Environment and Garden, 2026): the showy parts "are sepals which serve to protect
  the developing reproductive structures of the flower", "The real petals are inside the sepals", and "Flowers are borne
  for six to eight weeks after which they dry in place on the stems."
  https://ipm.missouri.edu/meg/2026/4/helleborus-dt
- Duke Gardens (Duke University), "Hybrid hellebores": the petal-like parts are "actually sepals, or modified leaves" and
  "hellebore sepals persist for months, long after the true petals have withered".
  https://gardens.duke.edu/garden-talk/hybrid-hellebores/
- "Weeks" is the safe lower bound: Missouri says 6 to 8 weeks, and Duke and Wikipedia say months. The line avoids "last"
  (banned). It holds for both the Lenten rose (*H. orientalis* / *H. × hybridus*) and the Christmas rose (*H. niger*), in
  the UK and the US.

## Not reached directly

RSPB, RHS, Kew and Woodland Trust pages (403). The Woodland Trust snowdrop quote is a search snippet. Each fact still has
two independent sources that were read directly, apart from snowdrop, which has Wikipedia (read) plus Woodland Trust
(snippet). The owner's optional browser check of the RSPB robin, Kew snowdrop and RHS hellebore pages would only add
confirmation. Nothing found contradicts any of the four lines.

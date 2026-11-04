# Rose rule: peel outer to inner (Opus visual lead)

Page: `parts/rose-thinning.html`. The rule object in that page (`RULE`) is the same data as below. Shots: `parts/shots/rose-*.png` (390 pt, 2x).

## Why (about 100 words)

The rose's five outer petals sit on a dark r26 disc. If you remove only the circles, the outline barely changes, and the disc stays behind as a cup. So the disc is hidden and redrawn as five dark inner-row petals that fill the valleys between the outer petals. At 5 pips the outline is the same as the art. Each outer petal leaves together with the valley petal clockwise of it. The outer ring goes over two pips, and the bud then unwraps one layer per pip. Its own sepals hold it, and it settles into them. Each petal that falls is a curled rose-petal sprite in its own layer's colour, tumbling and swaying. At 0 pips the stem shows a bare hip with splayed sepals, and then the seed in its pot.

## Rule data

Coordinates are in the plant's 200 box. Angles are 0 = up, clockwise. `i` is the index of a root child in `plants/plant_rose.svg`: 0 ground, 1 stem, 2 and 3 thorns, 4 and 5 leaves, 6 calyx, 7 base disc r26, 8 to 12 outer petals r12 (angles 0, 72, 144, 216, 288), 13 wrap r15, 14 swirl r10, 15 inner r8, 16 heart r4.5.

```js
{
  plant: "plant_rose", centre: [100, 80],
  hide: [{ i: 7, sel: 'circle[r="26"]', why: "base disc; would stay as a cup" }],
  add: [
    { id: "cradle", after: 6,  // hip + 2 sepals; hidden by the head at 5 pips, peeks through gaps at 4
      svg: '<path d="M93 100C92 92 95.5 88 100 88C104.5 88 108 92 107 100Z" fill="#3F8A4A"/>'
         + '<g class="sepal" splay="-24" origin="95 100"><path d="M95 101C88 99 84 94 82.5 86C87 89 91.5 92 97 96Z" fill="#3F8A4A"/></g>'
         + '<g class="sepal" splay="24" origin="105 100"><path d="M105 101C112 99 116 94 117.5 86C113 89 108.5 92 103 96Z" fill="#3F8A4A"/></g>'
         + '<path d="M96 99C97 94 98.5 91 100 89.5C101.5 91 103 94 104 99Z" fill="#5FA860"/>' },
    { id: "valleys", replaces: 7,  // 5 dark inner-row petals at 36,108,180,252,324; each in its own <g> (animate the g, not the path)
      path: "M0 -5C-4.8 -10 -7.6 -16 -7.4 -20.6C-7.2 -23.6 -6.8 -25.2 -5.63 -25.38A26 26 0 0 1 5.63 -25.38C6.8 -25.2 7.2 -23.6 7.4 -20.6C7.6 -16 4.8 -10 0 -5Z",
      transform: "translate(100 80) rotate(A)", fill: "#B52C52", angles: [36, 108, 180, 252, 324] }
  ],
  units: {                       // a unit leaves together; drops = [radius, angle] where each sprite starts
    o0:   { els: [8,  "valley36"],  sprite: "outer", drops: [[19, 0]] },
    o72:  { els: [9,  "valley108"], sprite: "outer", drops: [[19, 72]] },
    o144: { els: [10, "valley180"], sprite: "outer", drops: [[19, 144]] },
    o216: { els: [11, "valley252"], sprite: "outer", drops: [[19, 216]] },
    o288: { els: [12, "valley324"], sprite: "outer", drops: [[19, 288]] },
    wrap:  { els: [13],     sprite: "wrap",  drops: [[10, 250], [10, 110]] },
    swirl: { els: [14],     sprite: "swirl", drops: [[7, 300]] },
    heart: { els: [15, 16], sprite: "heart", drops: [[6, 60]] }
  },
  lose: {                        // lost going from k+1 pips to k pips; the outer petals now last to 3 pips so they can curl
    4: ["o144", "o216"],         // 3 outer petals left (o0, o72, o288), curled (stage 1)
    3: ["o0"],                   // the mirror pair o72 and o288 stays beside the closed bud, rolled further (stage 2)
    2: ["o72", "o288", "wrap"],  // small swirl bud (5 petal refs fall: 2 outer, 2 valleys, the wrap)
    1: ["swirl"],
    0: ["heart"]
  },
  curl: {                        // the petals that stay get sleepy: a shorter, rolled-back sprite + a droop about the petal base
    out: 19.5,                   // curled sprites sit at translate(100 80) rotate(angle) translate(0 -19.5) (fresh petals are at 17)
    shapes: {                    // local: petal centre 0,0 (r12), pointing up/outward. Draw face, tube, hi (stroke), fold (stroke).
      s1: { face: "M-11.97 .8A12 12 0 0 0 11.97 .8L10.4 .8Q1.2 -3.6 -10.4 .8Z",
            tube: "M-10.4 -2.8Q1.2 -7.2 10.4 -2.8A1.8 1.8 0 0 1 10.4 .8Q1.2 -3.6 -10.4 .8A1.8 1.8 0 0 1 -10.4 -2.8Z",
            hi: "M-8 -2.6Q1.2 -5.6 8 -2.6", fold: "M10.4 .8Q1.2 -3.6 -10.4 .8", hiW: .8, foldW: .9 },
      s2: { face: "M-11.71 2.6A12 12 0 0 0 11.71 2.6L10.8 2.6Q1.2 -1.4 -10.8 2.6Z",
            tube: "M-10.8 -1.4Q1.2 -5.4 10.8 -1.4A2 2 0 0 1 10.8 2.6Q1.2 -1.4 -10.8 2.6A2 2 0 0 1 -10.8 -1.4Z",
            hi: "M-8.4 -1Q1.2 -4 8.4 -1", fold: "M10.8 2.6Q1.2 -1.4 -10.8 2.6", hiW: .8, foldW: .9 }
    },
    fill: { face: "#D94668", tube: "#B52C52", hi: "#E0587A", fold: "#8E1F3E" },   // all opaque; strokes are round-capped
    sprites: {                   // imageset plant_rose_curl_<id>, drawn in place in the 200 box
      o0_1:   { unit: "o0",   angle: 0,   shape: "s1" },
      o72_1:  { unit: "o72",  angle: 72,  shape: "s1" },
      o288_1: { unit: "o288", angle: 288, shape: "s1", mirror: true },   // mirror: append scale(-1 1) to the placement
      o72_2:  { unit: "o72",  angle: 72,  shape: "s2" },
      o288_2: { unit: "o288", angle: 288, shape: "s2", mirror: true }
    },
    pips: {                      // at this pip count and below; the smallest matching key wins (as settle). rotate: degrees clockwise about pivot
      4: [ { unit: "o0",   image: "o0_1",   pivot: [100, 74],       rotate: 16 },
           { unit: "o72",  image: "o72_1",  pivot: [105.71, 78.15], rotate: 17 },
           { unit: "o288", image: "o288_1", pivot: [94.29, 78.15],  rotate: -17 } ],
      3: [ { unit: "o72",  image: "o72_2",  pivot: [105.71, 78.15], rotate: 25 },
           { unit: "o288", image: "o288_2", pivot: [94.29, 78.15],  rotate: -25 } ]
    },
    motion: "on a fall, after 0.9 s the fresh (or stage 1) petal cross-fades to the new sprite (0.6 s, the existing fading pattern) and "
          + "rotationEffect eases to rotate (1.4 s, the settle curve). Regrow undoes both. A drooped petal's fall sprite starts at angle + rotate. "
          + "Reduce Motion: the swap and the rotation go with the 0.3 s state animation."
  },
  settle: { 2: { els: [14, 15, 16], dx: 1, dy: 4 }, 1: { els: [15, 16], dx: -3, dy: 6 } },  // bud sinks into its sepals (1.4 s ease)
  splayAt: 0,                    // sepals rotate outward ±24° about their bases at 0 pips
  seedAfterMs: 1200,             // then crossfade to seed-pot.svg
  sprites: {                     // base at 0,0, pointing up; place at drop point, rotate(angle), scale
    paths: {
      face: "M0 0C-3.6 -.8 -9.6 -5.4 -11.4 -11.4C-12.8 -16.4 -10.2 -21.4 -5.6 -22.2C-3.2 -22.6 -1.4 -22 0 -20.8C1.6 -22.2 3.8 -22.9 6.2 -22.4C10.6 -21.4 12.8 -17 11.8 -12C10.8 -6.2 4.6 -.8 0 0Z",
      lip:  "M0 -20.8C1.6 -22.2 3.8 -22.9 6.2 -22.4C10.6 -21.4 12.8 -17 11.8 -12C11.4 -10 10.6 -8.2 9.6 -6.6C10.2 -9.6 9.8 -13.4 8.2 -15.6C6.4 -18.2 3.4 -19 1.2 -18.2C.7 -19 .3 -19.9 0 -20.8Z",
      claw: "M0 -.6C-2.6 -2.6 -4 -6.6 -3.4 -10.6C-1.6 -8.4 -.4 -5 0 -.6Z"   // opacity .5
    },
    outer: { face: "#D94668", lip: "#E86A88", claw: "#B52C52", scale: 1 },
    wrap:  { face: "#C2335A", lip: "#D94668", claw: "#9E2449", scale: .9 },
    swirl: { face: "#E0587A", lip: "#EE84A0", claw: "#C2335A", scale: .75 },
    heart: { face: "#B52C52", lip: "#D94668", claw: "#8E1F3E", scale: .62 }
  },
  motion: {
    fall: "3.8 s each, staggered 0.32 s; first 0.3 s the sprite fades in over the drawn petal, which fades out (0.35 s). "
        + "Path: lift 5 out, then x sways sin(2.5 turns) ±14 shrinking to 30%, rocks ±30°, squashes scaleX .55–1 (tumble), y eases down. "
        + "Rests beside the stem (x 100 ± 22 + 12/pair, y 171), lying: scale(1,.62) rotate(±80..104) scale(.82). Falling layer is in front of the head.",
    regrow: "inner layers first, one pip per 0.3 s; each unit scales .05 → 1.06 → 1 from the head centre (0.65 s spring); settle and splay undo",
    reduceMotion: "unit fades out 0.5 s; sprite fades in at its rest spot (0.6 s); regrow is a 0.25 s fade; no sway, no rain"
  }
}
```

The `lose` order and the `curl` key come from `notes/rose-curl.md` (T-E, approved after the critic review in `notes/rose-curl-review.md`): the outer petals o0, o72 and o288 stay to 3 pips so they can curl and droop, and `tools/thin_svg.py` writes the five `plant_rose_curl_*` sprites and `rule.curl` from it.

## Reuse on other plants

There is no peony, camellia, dahlia or ranunculus in the catalogue. The rose is the only plant with circle petals on a true base disc. These plants reuse the peel order (outer layer first, a whole layer at a time, no even share):

- `plant_poppy`: the 2 front petals go, then the 2 back ones. Hide the r18 red cup disc with the last petal. Bare = black seed head on the stem.
- `plant_rafflesia`: peel the 5 lobes. The rx38 disc is the flower's body, so shrink it to rx26 at 1 pip rather than leave a cup.
- `plant_lotus`: peel by shade, a pair at a time (outer, middle, inner), then the bud. It ends as a bare bud.
- `plant_giant_water_lily`: the 5 pink petals go over 2 pips, the 4 white over 2, and the centre petal last.
- `plant_hibiscus`: the 5 big petals go over 3 pips (2, 2, 1) and the 5 dark inner petals over 2. The eye and stamen stay.
- `plant_marigold`: 13/13/11 ellipse rings. Peel ring by ring (outer over 2 pips, middle over 2, inner last), not an even share.
- `plant_king_protea`: the bract layers (7, 7, 6) go outer first. The cream dome is the real bare head.
- `plant_chocolate_cosmos`: the back ring of 4 goes, then the front ring of 4.
- `plant_tulip`: only 2 layers. The front petal goes at 3 pips and the cup at 1 pip. Use droop for the other pips.

## Left to hand-tune

- **2 pips**: the swirl bud is two offset balls (r10 light and r8 dark). It reads as a bud, but a curl stroke or a teardrop redraw would be prettier.
- **4 pips**: an exposed valley petal shows a flat-topped dark edge. It looks like a deeper petal and is fine at tile size.
- **Dark mode**: the 0.35 s fade of the drawn petal over a leaf looks a bit muddy.
- **Regrow from seed**: the pot fades out while the bud grows, so the two overlap for about 0.8 s.

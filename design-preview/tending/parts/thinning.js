// WordFlora petal thinning prototype. Mirrors what a build script (tools/thin_svg.py) would do on the plant SVGs:
// 1. find petal rings (repeated elements rotated about one pivot, or same-size circles round one centre),
// 2. give each ring a nested, evenly spread keep order (golden ratio), 3. hide petals per pip, 4. clone a hidden petal to fall.
const NS = 'http://www.w3.org/2000/svg';
const PLANTS = '../../plants/';
// share of each ring kept at 0..5 pips. Front-loaded so 4 pips already looks sparser
const FRAC = [0, .13, .27, .47, .72, 1];
const GROUND_Y = 171;
const MAXFALL = 5; // at most five petals drift to the ground per lost pip // petals rest on the ground shadow (ellipse cy 177) in the 200 box
const cache = {};
async function svgText(name) { return cache[name] ||= await (await fetch(PLANTS + name + '.svg')).text(); }

// per-plant overrides a script would read from plants.json (only what detection cannot guess)
const META = {
  plant_saguaro_cactus: { kind: 'droop', pivot: [100, 176] },   // body droops and greys; its tiny flower still thins
  plant_rose: { kind: 'droop', pivot: [100, 176] },              // ring found but too weak alone: petals + droop
};

function keptCount(N, k) {
  if (k >= 5) return N; if (k <= 0) return 0;
  let c = Math.round(N * FRAC[k]);
  if (N >= 5) c = Math.min(Math.max(c, k), N - (5 - k)); // every pip removes at least one petal
  return c;
}
// nested, evenly spread keep order: walk the ring by the golden ratio
function keepOrder(N) {
  const used = new Array(N).fill(false), out = [];
  for (let j = 0; out.length < N; j++) {
    let i = Math.floor(((j * 0.6180339887) % 1) * N);
    while (used[i]) i = (i + 1) % N;
    used[i] = true; out.push(i);
  }
  return out;
}

function parseT(t) {
  const tr = /^\s*translate\(\s*([-\d.]+)[ ,]+([-\d.]+)\s*\)/.exec(t);
  const ro = /rotate\(\s*([-\d.]+)(?:[ ,]+([-\d.]+)[ ,]+([-\d.]+))?\s*\)/.exec(t);
  if (!ro) return null;
  let px = 0, py = 0;
  if (ro[2] !== undefined) { px = +ro[2]; py = +ro[3]; } else if (tr) { px = +tr[1]; py = +tr[2]; }
  return { a: +ro[1], px, py };
}
const toRoot = (svg, el, x, y) => { const p = svg.createSVGPoint(); p.x = x; p.y = y; return p.matrixTransform(svg.getCTM().inverse().multiply(el.getCTM())); };

// find rings in a live (in-document) svg
function analyse(svg) {
  const rings = [];
  // A. rotated copies: same markup apart from the rotate angle, same pivot
  const groups = {};
  svg.querySelectorAll('ellipse,path,circle,rect,polygon,g').forEach(el => {
    const t = el.getAttribute('transform'); if (!t) return; const T = parseT(t); if (!T) return;
    if (el.tagName === 'g' && el.querySelector('[transform*=rotate]')) return;
    const pv = toRoot(svg, el.parentNode, T.px, T.py);
    const sig = el.outerHTML.replace(/transform="[^"]*"/, '') + '|' + t.replace(/rotate\([^)]*\)/, '') + '|' + pv.x.toFixed(0) + ',' + pv.y.toFixed(0);
    (groups[sig] ||= []).push({ el, a: T.a, cx: pv.x, cy: pv.y });
  });
  Object.values(groups).forEach(g => { if (g.length >= 4 && new Set(g.map(p => Math.round(p.a))).size === g.length) rings.push({ type: 'rot', cx: g[0].cx, cy: g[0].cy, petals: g.sort((p, q) => p.a - q.a) }); });
  // B. same circles placed round one centre (rose, some buds)
  const circ = {};
  svg.querySelectorAll('circle').forEach(el => { if (el.getAttribute('transform')) return; const k = el.getAttribute('r') + el.getAttribute('fill'); (circ[k] ||= []).push(el); });
  Object.values(circ).forEach(g => {
    if (g.length < 5 || +g[0].getAttribute('r') < 4) return; // skip seed dots on a disc
    const P = g.map(el => [+el.getAttribute('cx'), +el.getAttribute('cy')]);
    const mx = P.reduce((s, p) => s + p[0], 0) / P.length, my = P.reduce((s, p) => s + p[1], 0) / P.length;
    const d = P.map(p => Math.hypot(p[0] - mx, p[1] - my)), md = d.reduce((s, x) => s + x, 0) / d.length;
    if (md < 3 || d.some(x => Math.abs(x - md) > md * .12)) return;
    rings.push({ type: 'circ', cx: mx, cy: my, petals: g.map((el, i) => ({ el, a: Math.atan2(P[i][0] - mx, my - P[i][1]) * 180 / Math.PI, cx: mx, cy: my })).sort((p, q) => p.a - q.a) });
  });
  rings.forEach(r => {
    r.order = keepOrder(r.petals.length);
    let R = 0; r.petals.forEach(p => { const b = p.el.getBBox(); [[b.x, b.y], [b.x + b.width, b.y], [b.x, b.y + b.height], [b.x + b.width, b.y + b.height]].forEach(([x, y]) => { const q = toRoot(svg, p.el, x, y); R = Math.max(R, Math.hypot(q.x - r.cx, q.y - r.cy)); }); });
    r.R = R;
    // cache geometry now, while every petal is rendered (hidden ones report empty boxes)
    r.petals.forEach(p => { const b = p.el.getBBox(); p.c = toRoot(svg, p.el, b.x + b.width / 2, b.y + b.height / 2); p.m = svg.getCTM().inverse().multiply(p.el.parentNode.getCTM());
      const q = svg.createSVGPoint(); q.x = r.cx; q.y = r.cy; p.o = q.matrixTransform(p.el.parentNode.getCTM().inverse().multiply(svg.getCTM())); });
  });
  // heads = rings sharing a pivot
  const heads = [];
  rings.forEach(r => { let h = heads.find(h => Math.hypot(h.cx - r.cx, h.cy - r.cy) < 3); if (!h) heads.push(h = { cx: r.cx, cy: r.cy, R: 0, rings: [] }); h.rings.push(r); h.R = Math.max(h.R, r.R); });
  return { rings, heads, petals: rings.reduce((s, r) => s + r.petals.length, 0) };
}

// petals (with their ring) lost going from pip k to k-1, in fall order
function lostBetween(A, k) {
  const out = [];
  A.rings.forEach(r => { const N = r.petals.length; for (let j = keptCount(N, k) - 1; j >= keptCount(N, k - 1); j--) out.push({ r, p: r.petals[r.order[j]], j }); });
  return out.sort((x, y) => x.j - y.j || x.p.a - y.p.a);
}
function setPips(A, k) { A.rings.forEach(r => { const c = keptCount(r.petals.length, k); r.order.forEach((idx, j) => { r.petals[idx].w.style.opacity = j < c ? '' : '0'; }); }); }

// build an inline svg for a plant
async function makePlant(name, cls = '') {
  const doc = new DOMParser().parseFromString(await svgText(name), 'image/svg+xml');
  const svg = document.importNode(doc.documentElement, true);
  svg.removeAttribute('width'); svg.removeAttribute('height');
  svg.setAttribute('class', 'pl ' + cls); svg.setAttribute('aria-hidden', 'true'); svg.style.overflow = 'visible';
  return svg;
}
function attach(svg, name) {
  const A = analyse(svg); A.name = name; A.meta = META[name] || {};
  // droop plants: everything but the leading ground ellipses goes in a body group that bends at its base
  if (A.meta.kind === 'droop') {
    const body = document.createElementNS(NS, 'g'); body.setAttribute('class', 'body');
    [...svg.children].forEach(c => { const g = c.tagName === 'ellipse' && +c.getAttribute('cy') >= 165; if (!g) body.appendChild(c); });
    svg.appendChild(body); const [x, y] = A.meta.pivot; body.style.transformOrigin = `${x}px ${y}px`;
    A.body = body;
  }
  // wrap each petal so it can be hidden or scaled without touching its own transform attribute
  A.rings.forEach(r => r.petals.forEach(p => { const w = document.createElementNS(NS, 'g'); w.setAttribute('class', 'pw'); p.el.before(w); w.appendChild(p.el); p.w = w; }));
  // falling petals sit just above the petal layer, so the flower's disc stays in front as they let go
  A.fallen = document.createElementNS(NS, 'g'); A.fallen.setAttribute('class', 'fallen');
  let top = null; A.rings.forEach(r => r.petals.forEach(p => { let n = p.w; while (n.parentNode !== svg && n.parentNode !== A.body) n = n.parentNode; if (!top || (top.compareDocumentPosition(n) & Node.DOCUMENT_POSITION_FOLLOWING)) top = n; }));
  if (top && top.parentNode === svg) top.after(A.fallen); else svg.appendChild(A.fallen);
  A.svg = svg; return A;
}
function droop(A, k, animate) {
  if (!A.body) return; const d = 5 - k;
  A.body.style.transition = animate ? 'transform 1.6s ease, filter 1.6s ease' : 'none';
  A.body.style.transform = `rotate(${d * 1.7}deg) scale(${1 - d * .012},${1 - d * .03})`;
  A.body.style.filter = `saturate(${1 - d * .13}) brightness(${1 - d * .02})`;
}

// a clone of petal p, in root coordinates, that can fall
function cloneOf(A, p) {
  const outer = document.createElementNS(NS, 'g'), inner = document.createElementNS(NS, 'g');
  const m = p.m;
  inner.setAttribute('transform', `matrix(${m.a} ${m.b} ${m.c} ${m.d} ${m.e} ${m.f})`);
  const c = p.el.cloneNode(true); c.style.display = ''; inner.appendChild(c); outer.appendChild(inner);
  A.fallen.appendChild(outer);
  return { g: outer, x: p.c.x, y: p.c.y };
}
// resting spot for the i-th petal of a fall, beside the stem, alternating sides
function restSpot(A, i, cx) {
  const side = i % 2 ? -1 : 1, x = cx + side * (24 + Math.floor(i / 2) * 11 + (i % 3) * 2);
  return { x, y: GROUND_Y - (i % 3) * 1.6 + Math.floor(i / 2) * .8, r: side * 8 + ((i * 29) % 30) - 15 };
}
// static resting petals for a state (the last day's petals lie on the ground)
function restLast(A, k) {
  A.fallen.innerHTML = ''; if (k >= 5) return;
  lostBetween(A, k + 1).slice(0, MAXFALL).forEach((L, i) => { const c = cloneOf(A, L.p), s = restSpot(A, i, L.r.cx);
    c.g.style.transformBox = 'fill-box'; c.g.style.transformOrigin = '50% 50%';
    c.g.style.transform = `translate(${s.x - c.x}px,${s.y - c.y}px) rotate(${90 - L.p.a + s.r}deg) scale(.72)`; c.g.style.opacity = .92; });
}

// animated: lose one pip (k -> k-1)
function fall(A, k, still) {
  // yesterday's petals on the ground soak away in the rain as today's fall
  A.fallen.querySelectorAll(':scope>g').forEach(g => g.animate([{ opacity: g.style.opacity || 1 }, { opacity: 0 }], { duration: 900, fill: 'forwards' }).finished.then(() => g.remove()));
  const lost = lostBetween(A, k), anims = [];
  lost.forEach((L, i) => {
    if (i >= MAXFALL) { // big rings (sunflower): only five petals drift, the rest let go with a quick fade on the head
      const gh = L.p.w.cloneNode(true); gh.style.opacity = ''; L.p.w.after(gh); L.p.w.style.opacity = '0';
      anims.push(gh.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 500, delay: 300 + (i - MAXFALL) * 90, fill: 'both' }).finished.then(() => gh.remove())); return; }
    const c = cloneOf(A, L.p), s = restSpot(A, i, L.r.cx), dx = s.x - c.x, dy = s.y - c.y, R = 90 - L.p.a + s.r;
    L.p.w.style.opacity = '0';
    c.g.style.transformBox = 'fill-box'; c.g.style.transformOrigin = '50% 50%';
    const end = `translate(${dx}px,${dy}px) rotate(${R}deg) scale(.72)`;
    if (still) { // Reduce Motion: the petal leaves the head with a fade and fades in where it rests
      const ghost = L.p.w.cloneNode(true); ghost.style.opacity = ''; L.p.w.after(ghost);
      ghost.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 500, fill: 'forwards' }).finished.then(() => ghost.remove());
      c.g.style.transform = end; anims.push(c.g.animate([{ opacity: 0 }, { opacity: .92 }], { duration: 600, delay: 200, fill: 'both' }));
      return;
    }
    const ox = Math.sin(L.p.a * Math.PI / 180) * 4, oy = -Math.cos(L.p.a * Math.PI / 180) * 4, sw = i % 2 ? -1 : 1;
    anims.push(c.g.animate([
      { transform: 'translate(0,0) rotate(0)', offset: 0 },
      { transform: `translate(${ox}px,${oy}px) rotate(${6 * sw}deg)`, offset: .1 },
      { transform: `translate(${dx * .45 + 14 * sw}px,${dy * .32}px) rotate(${R * .6 + 20 * sw}deg) scale(.9)`, offset: .38 },
      { transform: `translate(${dx * .5 - 8 * sw}px,${dy * .7}px) rotate(${R * .3 - 10 * sw}deg) scale(.82)`, offset: .68 },
      { transform: end, offset: 1 }],
      { duration: 3400, delay: 300 + i * 260, easing: 'cubic-bezier(.45,.05,.55,.95)', fill: 'both' }));
    c.g.style.opacity = .92;
  });
  return Promise.all(anims.map(a => a.finished));
}
// animated: love returns (k -> 5). One pip at a time, 0.3 s apart; a pip's petals grow out from the head centre together
function regrow(A, from, still) {
  const all = [];
  for (let k = from + 1; k <= 5; k++) lostBetween(A, k).forEach(L => all.push({ ...L, k })); // in step with pip k in the row (0.3 s apart)
  A.fallen.querySelectorAll('g').forEach(g => g.animate([{ opacity: g.style.opacity || 1 }, { opacity: 0 }], { duration: 700, fill: 'forwards' }).finished.then(() => g.remove()));
  return Promise.all(all.map((L, i) => {
    const el = L.p.w; el.style.opacity = '';
    if (still) return el.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 250, fill: 'both' }).finished;
    // scale about the head centre, in the element's own coordinates
    const q = L.p.o;
    el.style.transformBox = 'view-box'; el.style.transformOrigin = `${q.x}px ${q.y}px`;
    const a = el.animate([{ transform: 'scale(.05)', opacity: 0 }, { transform: 'scale(1.06)', opacity: 1, offset: .7 }, { transform: 'scale(1)', opacity: 1 }],
      { duration: 650, delay: 300 + (L.k - from - 1) * 300 + (i % 6) * 30, easing: 'cubic-bezier(.34,1.56,.64,1)', fill: 'backwards' });
    return a.finished.then(() => { a.cancel(); });
  }));
}
// wedge mask comparison (the alternative): remove angular wedges over the head, fill the centre with a darker disc
function wedgeMask(svg, A, k, id, disc) {
  const h = A.heads[0], r = h.rings[0], N = r.petals.length, c = keptCount(N, k), step = 360 / N;
  const m = document.createElementNS(NS, 'mask'); m.id = id;
  let d = '';
  r.order.forEach((idx, j) => { if (j < c) return; const a = r.petals[idx].a, a0 = (a - step / 2 - 1) * Math.PI / 180, a1 = (a + step / 2 + 1) * Math.PI / 180, R = h.R + 2;
    d += `M${h.cx} ${h.cy}L${h.cx + R * Math.sin(a0)} ${h.cy - R * Math.cos(a0)}A${R} ${R} 0 0 1 ${h.cx + R * Math.sin(a1)} ${h.cy - R * Math.cos(a1)}Z`; });
  m.innerHTML = `<rect x="-50" y="-50" width="300" height="300" fill="#fff"/><path d="${d}" fill="#000"/>`;
  const g = document.createElementNS(NS, 'g'); g.setAttribute('mask', `url(#${id})`);
  [...svg.children].forEach(ch => g.appendChild(ch)); A.rings.forEach(r => r.petals.forEach(p => p.w.style.opacity = ''));
  const defs = document.createElementNS(NS, 'defs'); defs.appendChild(m); svg.append(defs, g);
  if (disc) { const dc = document.createElementNS(NS, 'circle'); dc.setAttribute('cx', h.cx); dc.setAttribute('cy', h.cy); dc.setAttribute('r', disc.r); dc.setAttribute('fill', disc.fill); svg.appendChild(dc); }
}

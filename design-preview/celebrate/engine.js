// Shared drawing + timing for the celebration mockups.
// Everything is a pure function of time t (seconds), the way SwiftUI's TimelineView + Canvas would draw it:
// no per-frame state, so any frame can be rendered on its own (?t=1.2) and the Swift port is a direct copy.
(function () {
  const q = new URLSearchParams(location.search);
  const P = {
    t: q.has('t') ? parseFloat(q.get('t')) : null,     // frozen frame for PNG renders
    theme: q.get('theme') || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'),
    rm: q.get('rm') === '1',                            // Reduce Motion variant
    calm: q.get('calm') === '1',                        // Calm mode / Quiet Garden variant
  };
  document.documentElement.dataset.theme = P.theme;

  // The app's petal palette: FlowerView.Palette + the wordmark's two flower colours.
  const PAL = [
    { fill: '#F2788A', stroke: '#D9566C' },  // rose (FlowerView 7-8 petals)
    { fill: '#F5C858', stroke: '#E0962A' },  // marigold (flower centre / Word O)
    { fill: '#E9A36C', stroke: '#CF8247' },  // apricot (FlowerView 5-6)
    { fill: '#E27D8A', stroke: '#C95F6E' },  // wordmark rose (Flora O)
    { fill: '#C7A9B0', stroke: '#A98791' },  // lilac (FlowerView 3-4)
    { fill: '#8EA6C4', stroke: '#6E87A8' },  // sky (FlowerView 1-2)
  ];
  const GREEN = { stem: '#4E9A55', leafA: '#5FA860', leafB: '#3F8A4A' };
  const CENTER = { outer: '#E8A838', inner: '#F5C858' };

  // SplitMix-ish deterministic RNG, same idea as FlowerRainView's SplitMix64.
  function rng(seed) {
    let s = seed >>> 0 || 1;
    return () => { s = (s + 0x6D2B79F5) >>> 0; let z = s; z = Math.imul(z ^ (z >>> 15), z | 1); z ^= z + Math.imul(z ^ (z >>> 7), z | 61); return ((z ^ (z >>> 14)) >>> 0) / 4294967296; };
  }

  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  const lerp = (a, b, u) => a + (b - a) * u;
  const ease = {
    outCubic: (u) => 1 - Math.pow(1 - u, 3),
    inOutCubic: (u) => (u < 0.5 ? 4 * u * u * u : 1 - Math.pow(-2 * u + 2, 3) / 2),
    outBack: (u) => { const c1 = 1.5, c3 = c1 + 1; return 1 + c3 * Math.pow(u - 1, 3) + c1 * Math.pow(u - 1, 2); },
    outSine: (u) => Math.sin((u * Math.PI) / 2),
  };
  const seg = (t, a, b) => clamp((t - a) / (b - a));

  // PetalShape from FlowerView.swift, re-based so the petal's base sits at (0,0) and its tip at (0,-54).
  // len = drawn petal length in px. pivot: 'base' (blooms) or 'mid' (tumbling).
  const PETAL = new Path2D('M0 0 C-19 -12 -17 -44 0 -54 C17 -44 19 -12 0 0 Z');
  function petal(ctx, x, y, angle, len, col, alpha = 1, flip = 1, pivot = 'mid') {
    if (alpha <= 0.01 || len <= 0.2) return;
    const s = len / 54;
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(angle);
    ctx.scale(s * Math.max(0.35, Math.abs(flip)), s);   // flip fakes the 3D tumble (cos of a spin phase)
    if (pivot === 'mid') ctx.translate(0, 27);
    ctx.globalAlpha = alpha;
    ctx.fillStyle = col.fill; ctx.fill(PETAL);
    ctx.lineWidth = 2.2 / s * (len < 14 ? 0.6 : 1); ctx.strokeStyle = col.stroke; ctx.stroke(PETAL);
    if (flip < 0) { ctx.globalAlpha = alpha * 0.18; ctx.fillStyle = '#000'; ctx.fill(PETAL); }  // the petal's back is a touch darker
    ctx.restore();
  }

  // A five-petal blossom (the wordmark's O flower). open: 0 closed bud -> 1 open.
  function blossom(ctx, x, y, r, col, alpha = 1, open = 1, rot = 0, centre = 1) {
    if (alpha <= 0.01) return;
    const len = r * 0.95, base = r * 0.18 * open;
    for (let k = 0; k < 5; k++) {
      const a = rot + lerp(((k - 2) * 0.18), (k * 2 * Math.PI) / 5, open);
      petal(ctx, x + Math.sin(a) * base, y - Math.cos(a) * base, a, len * lerp(0.75, 1, open), col, alpha, 1, 'base');
    }
    if (centre > 0) {
      ctx.save(); ctx.globalAlpha = alpha;
      ctx.fillStyle = CENTER.outer; ctx.beginPath(); ctx.arc(x, y, r * 0.30 * centre, 0, 7); ctx.fill();
      ctx.fillStyle = CENTER.inner; ctx.beginPath(); ctx.arc(x, y, r * 0.18 * centre, 0, 7); ctx.fill();
      ctx.restore();
    }
  }

  function leaf(ctx, x, y, len, angle, color, alpha = 1) {
    if (len <= 0.5) return;
    ctx.save(); ctx.translate(x, y); ctx.rotate(angle); ctx.globalAlpha = alpha;
    ctx.beginPath(); ctx.moveTo(0, 0);
    ctx.quadraticCurveTo(len * 0.5, -len * 0.42, len, 0); ctx.quadraticCurveTo(len * 0.5, len * 0.22, 0, 0);
    ctx.fillStyle = color; ctx.fill(); ctx.restore();
  }

  function setupCanvas(el, w, h) {
    const dpr = window.devicePixelRatio || 1;
    el.width = w * dpr; el.height = h * dpr; el.style.width = w + 'px'; el.style.height = h + 'px';
    const ctx = el.getContext('2d'); ctx.setTransform(dpr, 0, 0, dpr, 0, 0); return ctx;
  }

  // Drives a scene: frozen at ?t, or live with requestAnimationFrame; tap skips (calls skip(t) -> new time).
  function run(draw, total, opts = {}) {
    if (P.t !== null) { draw(P.t); document.body.dataset.ready = '1'; return; }
    let t0 = performance.now(), offset = 0;
    const loop = (now) => {
      const t = (now - t0) / 1000 + offset;
      draw(t);
      if (t < total + (opts.hold ?? 1.2)) requestAnimationFrame(loop);
      else if (opts.loop !== false) { t0 = performance.now(); offset = 0; requestAnimationFrame(loop); }
    };
    requestAnimationFrame(loop);
    if (opts.skipTo !== undefined) {
      addEventListener('pointerdown', () => {
        const t = (performance.now() - t0) / 1000 + offset;
        if (t < opts.skipTo) { offset += opts.skipTo - t; }
      });
    }
  }

  window.WF = { P, PAL, GREEN, CENTER, rng, clamp, lerp, ease, seg, petal, blossom, leaf, setupCanvas, run };
})();

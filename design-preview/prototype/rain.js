/* WordFlora "flower rain": deterministic, pure function of time t, so it can be scrubbed, skipped and exported as stills.
   Usage: const r = FlowerRain.create({variant:'standard'|'celebration', reduce:false, seed:7});
          r.draw(ctx, t, theme)  // ctx is 390x844 logical px
          r.duration, r.wordmarkOpacity(t), r.messageOpacity(t)                                               */
window.FlowerRain = (function () {
  var W = 390, H = 844, TAU = Math.PI * 2;
  function mulberry(a){return function(){a|=0;a=a+0x6D2B79F5|0;var t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
  function lerp(a,b,u){return a+(b-a)*u}
  function clamp(x,a,b){return Math.max(a,Math.min(b,x))}
  function easeOutCubic(u){return 1-Math.pow(1-u,3)}
  function easeOutBack(u){var c=1.4;return 1+(c+1)*Math.pow(u-1,3)+c*Math.pow(u-1,2)}
  function easeInOut(u){return u<.5?2*u*u:1-Math.pow(-2*u+2,2)/2}

  /* Palette sampled from the 50-plant art (blossom/petal fills). Same list both themes; dark theme lifts lightness slightly in draw(). */
  var PALETTE = ['#F4A6B7','#E8586F','#F98FA2','#E65C4F','#E88A2E','#F2B53E','#FBF6E6','#B79AE0','#8E6BC9','#F7D3DC'];
  var CELEB_EXTRA = ['#F0C060','#FFE08A']; // gold sparkles for celebration
  var HEROES = ['plant_daisy','plant_tulip','plant_sunflower','plant_poppy','plant_cherry_blossom','plant_marigold','plant_lavender','plant_hibiscus'];

  var VARIANTS = {
    /* layers: n = count, size [min,max] px (blossom radius*2), fall = seconds to travel, delay = spawn window s, amp = sway px, freq = Hz, spin = max total rotation deg,
       alpha, blur px, land = [min,max] y in the ground band */
    standard: { dur: 2.4, ground: true, heroes: 5, sparks: 0, wordmark: [0.45, 1.15], message: null,
      layers: [
        { name: 'far',  n: 14, size: [8,14],  fall: [1.9,2.1], delay: 0.7, amp: [6,12],  freq: [0.45,0.65], spin: 90,  alpha: .55, blur: 1.2, land: [676,716], kinds: ['petal','petal','blossom5'] },
        { name: 'mid',  n: 12, size: [14,22], fall: [1.6,1.85], delay: 0.8, amp: [10,20], freq: [0.5,0.8],  spin: 150, alpha: .85, blur: 0,   land: [712,764], kinds: ['petal','blossom5','blossom8','daisy'] },
        { name: 'near', n: 6,  size: [24,34], fall: [1.35,1.55], delay: 0.8, amp: [14,26], freq: [0.55,0.9], spin: 220, alpha: 1,   blur: 1.6, land: [758,812], kinds: ['blossom5','blossom8','daisy'] }
      ] },
    celebration: { dur: 3.4, ground: false, heroes: 0, sparks: 22, wordmark: null, message: [0.25, 0.8],
      layers: [
        { name: 'far',  n: 34, size: [8,14],  fall: [1.9,2.4], delay: 1.2, amp: [8,16],  freq: [0.5,0.8],  spin: 160, alpha: .6,  blur: 1.2, land: [H+30,H+30], kinds: ['petal','petal','blossom5'] },
        { name: 'mid',  n: 30, size: [14,22], fall: [1.5,1.9], delay: 1.3, amp: [12,24], freq: [0.6,0.95], spin: 240, alpha: .9,  blur: 0,   land: [H+30,H+30], kinds: ['petal','blossom5','blossom8','daisy'] },
        { name: 'near', n: 16, size: [26,40], fall: [1.2,1.5], delay: 1.3, amp: [16,30], freq: [0.65,1.0], spin: 320, alpha: 1,   blur: 1.6, land: [H+30,H+30], kinds: ['blossom5','blossom8','daisy'] }
      ] }
  };

  function create(opts) {
    var v = VARIANTS[opts.variant || 'standard'], rnd = mulberry(opts.seed || 7), reduce = !!opts.reduce;
    var parts = [], i, L, p;
    function pick(a){return a[Math.floor(rnd()*a.length)]}
    function range(a){return lerp(a[0],a[1],rnd())}
    v.layers.forEach(function (L, li) {
      for (i = 0; i < Math.round(L.n * (opts.calm ? .5 : 1)); i++) {
        var col = pick(PALETTE);
        parts.push({ li: li, kind: pick(L.kinds), color: col, x0: lerp(-10, W + 10, rnd()), size: range(L.size), delay: rnd() * L.delay,
          fall: range(L.fall), amp: range(L.amp), freq: range(L.freq), phase: rnd() * TAU, rot0: rnd() * 360, spin: (rnd() < .5 ? -1 : 1) * L.spin * (0.5 + rnd() * .5),
          alpha: L.alpha, blur: L.blur, land: range(L.land), restRot: rnd() * 360, restRotAbs: 0 });
      }
    });
    for (i = 0; i < v.sparks; i++) parts.push({ li: 2, kind: 'spark', color: pick(CELEB_EXTRA), x0: lerp(10, W - 10, rnd()), size: lerp(6, 12, rnd()), delay: rnd() * 1.3,
      fall: lerp(1.4, 2.2, rnd()), amp: lerp(6, 14, rnd()), freq: lerp(.7, 1.3, rnd()), phase: rnd() * TAU, rot0: 0, spin: 90, alpha: .95, blur: 0, land: H + 30, restRot: 0 });
    var heroes = [];
    var hx = [58, 132, 206, 276, 340];
    for (i = 0; i < v.heroes; i++) heroes.push({ name: HEROES[(i * 2 + (opts.seed || 7)) % HEROES.length], x: hx[i] + (rnd() - .5) * 20, delay: .1 + rnd() * .5, fall: 1.5 + rnd() * .35, amp: 10 + rnd() * 8, freq: .5 + rnd() * .3, phase: rnd() * TAU, base: 780 + (i % 2) * 14 + rnd() * 6, h: 92 });
    var imgs = {};
    function img(n) { if (!imgs[n]) { var im = new Image(); im.src = '../plants/' + n + '.svg'; imgs[n] = im; } return imgs[n]; }
    heroes.forEach(function (h) { img(h.name); });

    var api = { duration: reduce ? 1.0 : v.dur, variant: opts.variant || 'standard', reduce: reduce, hasGround: v.ground };
    api.wordmarkOpacity = function (t) { if (!v.wordmark) return 0; if (reduce) return clamp((t - .3) / .5, 0, 1); return easeOutCubic(clamp((t - v.wordmark[0]) / (v.wordmark[1] - v.wordmark[0]), 0, 1)); };
    api.wordmarkRise = function (t) { return reduce ? 0 : (1 - api.wordmarkOpacity(t)) * 10; };
    api.messageOpacity = function (t) { if (!v.message) return 0; var o = easeOutCubic(clamp((t - v.message[0]) / (v.message[1] - v.message[0]), 0, 1)); var out = clamp((t - (v.dur - .6)) / .5, 0, 1); return o * (1 - out); };

    function shade(hex, dark) { if (!dark) return hex === '#FBF6E6' ? '#E6D9B0' : hex; var n = parseInt(hex.slice(1), 16), r = n >> 16, g = n >> 8 & 255, b = n & 255; var k = .12; r += (255 - r) * k; g += (255 - g) * k; b += (255 - b) * k; return 'rgb(' + (r | 0) + ',' + (g | 0) + ',' + (b | 0) + ')'; }

    function drawKind(ctx, kind, r, color, dark) {
      var c = shade(color, dark), k;
      if (kind === 'petal') {
        ctx.beginPath(); ctx.moveTo(0, -r); ctx.bezierCurveTo(r * .9, -r * .5, r * .7, r * .6, 0, r); ctx.bezierCurveTo(-r * .7, r * .6, -r * .9, -r * .5, 0, -r); ctx.fillStyle = c; ctx.fill();
      } else if (kind === 'blossom5') {
        ctx.fillStyle = c; for (k = 0; k < 5; k++) { ctx.save(); ctx.rotate(k * TAU / 5); ctx.beginPath(); ctx.ellipse(0, -r * .55, r * .42, r * .5, 0, 0, TAU); ctx.fill(); ctx.restore(); }
        ctx.beginPath(); ctx.arc(0, 0, r * .22, 0, TAU); ctx.fillStyle = color === '#F2B53E' ? '#E88A2E' : '#F2B53E'; ctx.fill();
      } else if (kind === 'blossom8') {
        ctx.fillStyle = c; for (k = 0; k < 8; k++) { ctx.save(); ctx.rotate(k * TAU / 8); ctx.beginPath(); ctx.moveTo(0, -r * .2); ctx.bezierCurveTo(-r * .3, -r * .38, -r * .26, -r * .85, 0, -r); ctx.bezierCurveTo(r * .26, -r * .85, r * .3, -r * .38, 0, -r * .2); ctx.fill(); ctx.restore(); }
        ctx.beginPath(); ctx.arc(0, 0, r * .26, 0, TAU); ctx.fillStyle = '#F2B53E'; ctx.fill();
      } else if (kind === 'daisy') {
        ctx.fillStyle = dark ? '#EFE6C8' : '#F3E9CC'; ctx.strokeStyle = dark ? 'rgba(0,0,0,.0)' : 'rgba(120,100,60,.28)'; ctx.lineWidth = .8;
        for (k = 0; k < 10; k++) { ctx.save(); ctx.rotate(k * TAU / 10); ctx.beginPath(); ctx.ellipse(0, -r * .62, r * .17, r * .4, 0, 0, TAU); ctx.fill(); ctx.stroke(); ctx.restore(); }
        ctx.beginPath(); ctx.arc(0, 0, r * .24, 0, TAU); ctx.fillStyle = '#F2B53E'; ctx.fill();
      } else if (kind === 'spark') {
        ctx.beginPath(); for (k = 0; k < 8; k++) { var rr = k % 2 ? r * .28 : r, a = k * TAU / 8 - Math.PI / 2; ctx.lineTo(Math.cos(a) * rr, Math.sin(a) * rr); } ctx.closePath(); ctx.fillStyle = color; ctx.fill();
      }
    }

    function ground(ctx, t, dark) {
      var e = reduce ? 1 : easeOutCubic(clamp((t - .1) / .9, 0, 1)); if (e <= 0) return;
      var top = H - 150 * e;
      var g = ctx.createLinearGradient(0, top, 0, H);
      g.addColorStop(0, dark ? '#3E7A3A' : '#6DB06A'); g.addColorStop(.18, dark ? '#2F5E2D' : '#4E9A4C'); g.addColorStop(.19, dark ? '#3A2E22' : '#7A5A42'); g.addColorStop(1, dark ? '#241B14' : '#5E4432');
      ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(0, H); ctx.lineTo(0, top + 8);
      for (var x = 0; x <= W; x += 10) ctx.lineTo(x, top + Math.sin(x * .045) * 5 + Math.sin(x * .13) * 2); ctx.lineTo(W, H); ctx.closePath(); ctx.fill();
    }

    api.draw = function (ctx, t, theme) {
      var dark = theme === 'dark'; ctx.clearRect(0, 0, W, H);
      var master = reduce ? clamp(t / .5, 0, 1) : 1;
      var fadeOut = (v.ground ? 0 : clamp((t - (v.dur - .7)) / .6, 0, 1));
      if (v.ground) ground(ctx, t, dark);
      /* far layer before heroes, mid/near after, so depth reads */
      function paintParticles(minL, maxL) {
        parts.forEach(function (p) {
          if (p.li < minL || p.li > maxL) return;
          var u = reduce ? 1 : clamp((t - p.delay) / p.fall, 0, 1); if (!reduce && t < p.delay) return;
          var f = Math.pow(u, 1.12), y = lerp(-40, p.land, f);
          var settle = clamp((u - .86) / .14, 0, 1);
          var x = p.x0 + p.amp * Math.sin(TAU * p.freq * (reduce ? 0 : (t - p.delay)) + p.phase) * (1 - easeOutCubic(settle));
          var rot = reduce ? p.restRot : lerp(p.rot0, p.restRot + (p.land > H ? p.spin : 0), 0) + p.spin * u * (1 - settle * .85);
          var sy = v.ground ? lerp(1, .55, easeOutCubic(settle)) : 1;
          var a = p.alpha * (v.ground ? lerp(1, .92, settle) : 1) * clamp(u * 12, 0, 1) * master * (1 - fadeOut);
          if (a <= 0.01) return;
          if (v.ground && p.land <= H && !reduce && settle >= 1 && false) return;
          ctx.save(); ctx.globalAlpha = a; if (p.blur) ctx.filter = 'blur(' + p.blur + 'px)';
          ctx.translate(x, y); ctx.rotate(rot * Math.PI / 180); ctx.scale(1, sy); drawKind(ctx, p.kind, p.size / 2, p.color, dark); ctx.restore();
        });
      }
      paintParticles(0, 0);
      /* heroes: real plant art falls small then plants itself in the ground */
      heroes.forEach(function (h) {
        var im = img(h.name); if (!im.complete || !im.naturalWidth) return;
        var u = reduce ? 1 : clamp((t - h.delay) / h.fall, 0, 1); if (!reduce && t < h.delay) return;
        var y = lerp(-50, h.base - h.h * .45, Math.pow(u, 1.12));
        var settle = clamp((u - .85) / .15, 0, 1);
        var grow = reduce ? 1 : easeOutBack(clamp((t - (h.delay + h.fall)) / .5, 0, 1));
        var landed = u >= 1;
        var hh = landed ? lerp(h.h * .5, h.h, clamp(grow, 0, 1.08)) : h.h * .5;
        var x = h.x + h.amp * Math.sin(TAU * h.freq * (reduce ? 0 : (t - h.delay)) + h.phase) * (1 - easeOutCubic(settle));
        var rot = landed || reduce ? 0 : Math.sin(TAU * h.freq * (t - h.delay) + h.phase) * 25 * (1 - settle);
        var ww = hh * (im.naturalWidth / im.naturalHeight), by = landed ? h.base : y + hh / 2;
        ctx.save(); ctx.globalAlpha = clamp(u * 10, 0, 1) * master; ctx.translate(x, landed ? h.base : y); ctx.rotate(rot * Math.PI / 180);
        ctx.drawImage(im, -ww / 2, landed ? -hh : -hh / 2, ww, hh); ctx.restore();
      });
      paintParticles(1, 2);
    };
    return api;
  }
  return { create: create, VARIANTS: VARIANTS, PALETTE: PALETTE, W: W, H: H };
})();

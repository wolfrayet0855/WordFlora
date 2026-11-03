(function () {
'use strict';
var A = window.ART, FR = window.FlowerRain, $ = function (s) { return document.querySelector(s); };
$('#gdefs').innerHTML = A.gdefs;
var WORDS = [
 { w: 'SUNFLOWER', h: 'Its big golden head follows the sun when it is young.', hero: 1 },
 { w: 'ROSE', h: 'A thorny garden favourite that smells sweet.' },
 { w: 'POLLEN', h: 'Yellow dust that bees carry from flower to flower.' },
 { w: 'TULIP', h: 'A cup-shaped spring flower that grows from a bulb.' },
 { w: 'DAISY', h: 'Its name means "day\'s eye" because it opens at sunrise.' },
 { w: 'LAVENDER', h: 'Purple spikes with a calming scent.' },
 { w: 'CACTUS', h: 'A prickly plant that stores water in its stem.' },
 { w: 'NECTAR', h: 'The sweet drink flowers offer to visitors.' },
 { w: 'BLOSSOM', h: 'A flower, especially on a fruit tree.' },
 { w: 'FERN', h: 'A leafy plant that grows from spores, not seeds.' },
 { w: 'SEED', h: 'A tiny package that can grow into a whole plant.' },
 { w: 'MARIGOLD', h: 'Orange flowers that help keep pests away.' }];
var DAILY = { w: 'LAVENDER', h: 'Purple spikes with a calming scent.' };
var SOILS = [['loam', 'Loam', 'All-rounder'], ['sandy', 'Sandy', 'Drains fast'], ['peaty', 'Peaty', 'Holds moisture'], ['compost', 'Rich compost', 'Full of nutrients']];
var SOILC = { loam: ['#6B4A38', '#4E3426'], sandy: ['#D9BC8C', '#BFA070'], peaty: ['#3A2C24', '#5A4636'], compost: ['#4A3322', '#8BC34A'] };
var STAGES = [0, 11, 40, 90, 180], STAGENAME = ['', 'Seedling', 'Sprout', 'Growing', 'Flourishing', 'In full bloom'];
var UNL = { can: 'Starter tool', trowel: 'Starter tool', net: 'Finish Level 1', mister: 'Reach Level 2', shears: 'Earn the First Bloom badge', lamp: 'Reach Level 3' };
var FXH = { can: 'pour', trowel: 'scoop', shears: 'snip', mister: 'mist', lamp: 'glow' };
var FX = { pour: '<i></i><i></i><i></i><i></i>', scoop: '<i></i><i></i><i></i>', snip: '<i></i><i></i><i></i>', mist: '<i></i><i></i><i></i><i></i><i></i>', glow: '<i></i>' };
var CUE = { can: ['soft continuous haptic, light tick per plant', 'gentle water trickle'], trowel: ['soft impact on dig, light on release', 'low earthy thud'], shears: ['rigid light tick per snip', 'crisp snip click'], mister: ['three very light taps', 'airy pssht'], lamp: ['rising soft haptic', 'warm two-note chime'], net: ['soft medium impact on swipe, success on catch', 'whoosh, bell chime on catch'] };

function fresh() {
  return { screen: 'intro', p: {}, theme: null, rm: false, plus: false, plan: 'y', evening: false, lantern: 1,
    res: { water: 5, scoop: 3, shed: 42, rose: 1 }, tools: { can: 1, trowel: 1, net: 0, mister: 0, shears: 0, lamp: 0 }, tier: { can: 1, trowel: 1, net: 1, mister: 1, shears: 1, lamp: 1 }, hand: 'can',
    plants: {}, level: 1, levelDone: {}, rounds: 0, sinceAd: 0, used: [], dailyDone: false, streak: 3, stickers: {}, badges: {}, C: {}, bfPlays: 0, viewLevel: 1,
    set: { sound: true, haptics: true, remind: false, theme: 'system' } };
}
var S = fresh();
try { var raw = localStorage.getItem('wf-proto'); if (raw && location.search.indexOf('fresh') < 0) { var o = JSON.parse(raw); S = Object.assign(fresh(), o); S.set = Object.assign(fresh().set, o.set || {}); } } catch (e) {}
function save() { try { localStorage.setItem('wf-proto', JSON.stringify(S)); } catch (e) {} }
function C(k) { return S.C[k] || 0; }
function inc(k, n) { S.C[k] = C(k) + (n === undefined ? 1 : n); }
function themeNow() { var t = S.set.theme; if (t === 'system') t = (window.matchMedia && matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light'; return S.theme || t; }
function applyTheme() { var t = themeNow(); document.documentElement.setAttribute('data-theme', t); document.body.classList.toggle('rm', !!S.rm); $('#tRm').checked = !!S.rm; $('#tFree').classList.toggle('on', !S.plus); $('#tPlus').classList.toggle('on', S.plus); $('#tEve').checked = !!S.evening; }
function cue(tool) { var c = CUE[tool] || [tool, '']; var h = S.set.haptics ? c[0] : 'off', s = S.set.sound ? c[1] : 'off'; $('#log').textContent = 'Haptic: ' + h + '  |  Sound: ' + s; }
function cue2(h, s) { $('#log').textContent = 'Haptic: ' + (S.set.haptics ? h : 'off') + '  |  Sound: ' + (S.set.sound ? s : 'off'); }
var toastT; function toast(t) { var e = $('#toast'); e.textContent = t; e.classList.add('on'); clearTimeout(toastT); toastT = setTimeout(function () { e.classList.remove('on'); }, 2200); }
function status() { return '<div class="status"><span>9:41</span><span>100%</span></div>'; }
function chips() { return '<span class="chip">&#x1F4A7; ' + S.res.water + '</span>'; }
function resBar() { return '<div style="display:flex;gap:6px;flex-wrap:wrap"><span class="chip">&#x1F4A7; ' + S.res.water + '</span><span class="chip">&#x1F331; ' + S.res.scoop + '</span><span class="chip acc">&#x2B50; ' + S.res.shed + '</span></div>'; }
function nav(title, back, right) { return '<div class="nav"><button class="ibtn" data-a="' + back + '" style="border:0;color:inherit" aria-label="Back">&#x2039;</button><span class="t">' + title + '</span>' + (right || '<span style="width:36px"></span>') + '</div>'; }
function wm() { return A.wm[themeNow() === 'dark' ? 'dark' : 'light'].replace(/ width="\d+" height="\d+"/, ''); }
function plantObj(id) { return A.plants.filter(function (p) { return p.imageName === id; })[0]; }
function plantImg(id, w, cls) { return '<img src="../plants/' + id + '.svg" width="' + w + '" class="' + (cls || '') + '" alt="">'; }
function stageOf(gp) { var s = 1; for (var i = 1; i < STAGES.length; i++) if (gp >= STAGES[i]) s = i + 1; return s; }

/* ---------- flower mascot ---------- */
function flowerSVG(left, mood) {
  var p = '', i;
  for (i = 0; i < 8; i++) if (i < left) p += '<path d="M0 -14 C-19 -26 -17 -58 0 -68 C17 -58 19 -26 0 -14Z" transform="translate(100 100) rotate(' + (i * 45) + ') scale(1.42 1.35)" fill="url(#fpk)"/><path d="M0 -26 C-4 -36 -4 -50 0 -58" transform="translate(100 100) rotate(' + (i * 45) + ') scale(1.42 1.35)" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="2.2" stroke-linecap="round"/>';
  var mouth = mood === 'happy' ? '<path d="M88 106 Q100 120 112 106" fill="none" stroke="#2C3E2C" stroke-width="4" stroke-linecap="round"/>' : (mood === 'oh' ? '<ellipse cx="100" cy="112" rx="5" ry="6" fill="#2C3E2C"/>' : '<path d="M91 111 H109" stroke="#2C3E2C" stroke-width="4" stroke-linecap="round"/>');
  return '<svg class="fl" viewBox="0 0 200 200"><defs><linearGradient id="fpk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F98FA2"/><stop offset="1" stop-color="#E8586F"/></linearGradient><radialGradient id="fgc" cx=".38" cy=".32" r=".8"><stop offset="0" stop-color="#F9D472"/><stop offset="1" stop-color="#E8A838"/></radialGradient></defs>' + p +
    '<circle cx="100" cy="100" r="31" fill="url(#fgc)"/><circle cx="90" cy="94" r="4.2" fill="#2C3E2C"/><circle cx="110" cy="94" r="4.2" fill="#2C3E2C"/>' + mouth + '</svg>';
}
function dropPetal(idx) {
  var c = $('.fcont'); if (!c || S.rm) return; var a = idx * 45 * Math.PI / 180, d = document.createElement('div'); d.className = 'fallp';
  d.style.left = (100 + 62 * Math.sin(a) - 30) + 'px'; d.style.top = (100 - 62 * Math.cos(a) - 30) + 'px'; d.style.setProperty('--dx', (Math.random() * 80 - 40) + 'px'); d.style.setProperty('--rot', (Math.random() * 360 - 180) + 'deg');
  d.innerHTML = '<svg viewBox="-20 -75 40 80"><path d="M0 -14 C-19 -26 -17 -58 0 -68 C17 -58 19 -26 0 -14Z" transform="rotate(' + (idx * 45) + ')" fill="#F4748A"/></svg>'; c.appendChild(d); setTimeout(function () { d.remove(); }, 1200);
}

/* ---------- rain ---------- */
var rainT = null;
function celebrate(variant, cb) {
  if (S.rm) { if (cb) setTimeout(cb, 600); return; }
  var cv = $('#rainCv'), cx = cv.getContext('2d'); cx.setTransform(2, 0, 0, 2, 0, 0); var r = FR.create({ variant: variant, seed: Math.floor(Math.random() * 99) }), t0 = null; cancelAnimationFrame(rainT);
  function f(ts) { if (t0 == null) t0 = ts; var t = (ts - t0) / 1000; cx.clearRect(0, 0, 390, 844); if (t < r.duration) { r.draw(cx, t, themeNow()); rainT = requestAnimationFrame(f); } else { cx.clearRect(0, 0, 390, 844); if (cb) cb(); } }
  rainT = requestAnimationFrame(f);
}

/* ---------- overlays ---------- */
function modal(html, noClose) { var o = $('#ov'); o.innerHTML = '<div class="dim" ' + (noClose ? '' : 'data-a="ovbg"') + '><div class="sheet">' + html + '</div></div>'; o.classList.add('on'); }
function closeModal() { var o = $('#ov'); o.classList.remove('on'); o.innerHTML = ''; flush(); }
var queue = [], pending = null;
function modalOpen() { return $('#ov').classList.contains('on'); }

/* ---------- badges ---------- */
function bval(id) {
  var n = 0, cnt = Object.keys(S.plants).length, caught = Object.keys(S.stickers).length;
  switch (id) {
    case 'plant_collector': return cnt; case 'level_sets': return Object.keys(S.levelDone).length; case 'level_up': return S.level;
    case 'visitor_friend': return caught; case 'sticker_book': return Object.keys(S.stickers).reduce(function (a, k) { return a + S.stickers[k]; }, 0);
    case 'streak': return S.streak; case 'perfect_bloom': return C('perfect'); case 'resurrected': return C('revive'); case 'daily_bloom': return C('daily'); case 'word_whiz': return C('wins'); case 'steady_hands': return C('steady'); case 'long_word': return C('long');
    case 'first_bloom': return Object.keys(S.plants).filter(function (k) { return S.plants[k].stage >= 4; }).length; case 'flower_power': return Object.keys(S.plants).filter(function (k) { return S.plants[k].stage >= 4; }).length;
    case 'green_thumb': return C('water'); case 'master_repotter': return C('repot'); case 'pruning_pro': return C('prune'); case 'mist_maker': return C('mist'); case 'sun_seeker': return C('sun'); case 'soil_scientist': return C('match'); case 'feeder': return C('feed');
    case 'first_butterfly': case 'gentle_net': return C('catch'); case 'dusk_visitor': return C('night'); case 'rare_visitor': return C('rare'); case 'field_notes': return C('facts'); case 'bee_friend': return C('bee'); case 'shed_keeper': return C('upgrade'); case 'sharer': return C('share');
  } return 0;
}
function checkBadges() {
  A.badgeMeta.forEach(function (b) { var v = bval(b.id), t = 0; b.th.forEach(function (x, i) { if (v >= x) t = i + 1; }); var cur = S.badges[b.id] || 0;
    if (t > cur) { S.badges[b.id] = t; S.res.shed += [0, 3, 10, 25][t]; queue.push({ type: 'badge', id: b.id, tier: t }); } });
}
function checkUnlocks() {
  var n = [];
  if (S.level >= 2 && !S.tools.net) { S.tools.net = 1; S.tools.mister = 1; n.push('Butterfly net and Mister'); }
  if ((S.badges.first_bloom || 0) >= 1 && !S.tools.shears) { S.tools.shears = 1; n.push('Pruning shears'); }
  if (S.level >= 3 && !S.tools.lamp) { S.tools.lamp = 1; n.push('Sun lamp'); }
  if (n.length) toast('Tool unlocked: ' + n.join(', '));
}
function progress() {
  /* level completion: all 10 plants of the current level earned and stage >= 4 */
  var lv = S.level; if (lv <= 5 && !S.levelDone[lv]) { var ps = A.plants.filter(function (p) { return p.level === lv; });
    if (ps.every(function (p) { return S.plants[p.imageName] && S.plants[p.imageName].stage >= 4; })) { S.levelDone[lv] = true; S.res.shed += 25; if (lv < 5) S.level = lv + 1; queue.push({ type: 'level', lv: lv }); } }
  checkBadges(); checkUnlocks(); save();
}
var releasing = false;
function flush() {
  if (modalOpen()) return;
  if (!releasing && (S.screen === 'earned' || S.screen === 'game' || S.screen === 'intro' || S.screen === 'bf' || S.screen === 'dead')) return;
  var q = queue.shift();
  if (q) { if (q.type === 'badge') showBadge(q.id, q.tier); else if (q.type === 'level') showLevelUp(q.lv); else if (q.type === 'stage') { toast(q.t); flush(); } return; }
  if (pending) { var p = pending; pending = null; releasing = false; p(); }
}
function showBadge(id, tier) {
  var m = A.badgeMeta.filter(function (b) { return b.id === id; })[0], tn = ['', 'Bronze', 'Silver', 'Gold'][tier];
  cue2('success haptic, soft', 'bright chime'); celebrate('celebration');
  modal('<div class="eyebrow">Badge unlocked</div><div class="medal" style="margin-top:12px">' + A.badge[id][tier] + '</div><div style="font-weight:900;font-size:26px;margin-top:8px">' + m.title + '</div><div style="color:var(--muted);font-size:14px;margin:4px 0">' + m.desc + '. ' + tn + '.</div><span class="chip acc">+' + [0, 3, 10, 25][tier] + ' shed points</span><div style="display:grid;gap:8px;margin-top:16px"><button class="btn primary" data-a="shareBadge" data-id="' + id + '" data-t="' + tier + '">Share badge</button><button class="btn secondary" style="height:46px" data-a="ovclose">Nice</button></div>');
}
function showLevelUp(lv) { celebrate('celebration'); cue2('success haptic', 'bright chime'); modal('<div style="font-size:44px">&#x1F33C;</div><div style="font-weight:900;font-size:26px">Level ' + lv + ' complete!</div><div style="color:var(--muted);font-size:14px;margin:6px 0 14px">Every plant in the level is flourishing. +25 shed points.' + (lv < 5 ? ' Level ' + (lv + 1) + ' is open.' : ' You finished the whole garden!') + '</div><button class="btn primary" data-a="ovclose">Wonderful</button>'); }

/* ---------- state mutation helpers ---------- */
function earnPlant(word) {
  var name = word.charAt(0) + word.slice(1).toLowerCase(), all = A.plants;
  var pick = all.filter(function (p) { return p.name.toUpperCase() === word && !S.plants[p.imageName]; })[0];
  if (!pick) pick = all.filter(function (p) { return p.level <= S.level && !S.plants[p.imageName]; })[0] || all.filter(function (p) { return !S.plants[p.imageName]; })[0];
  if (!pick) return null; S.plants[pick.imageName] = { gp: 0, stage: 1, lastWater: 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0 }; return pick;
}
function addGP(id, n) {
  var p = S.plants[id], old = p.stage; p.gp += n; p.stage = stageOf(p.gp);
  if (p.stage > old) { queue.push({ type: 'stage', t: plantObj(id).name + ' grew to stage ' + p.stage + ': ' + STAGENAME[p.stage] }); return true; } return false;
}

/* ---------- screens ---------- */
var R = {};
R.intro = function () { return '<div class="body" style="align-items:center;justify-content:center;text-align:center;padding:0" data-a="skipIntro"><div id="introWm" style="width:260px;opacity:0;margin-top:-150px">' + wm() + '</div><div class="fine" style="position:absolute;bottom:34px">Tap to skip</div></div>'; };
R.home = function () {
  var daily = S.dailyDone ? '<div class="card" style="display:flex;align-items:center;gap:12px;padding:12px 16px"><span style="font-size:26px">&#x2705;</span><div style="flex:1;text-align:left"><b>Daily Bloom done</b><div class="fine">Come back tomorrow. Streak ' + S.streak + ' days.</div></div></div>' :
    '<button class="card" data-a="daily" style="display:flex;align-items:center;gap:12px;padding:12px 16px;border:0;width:100%;color:inherit;text-align:left"><span style="font-size:28px">&#x1F338;</span><div style="flex:1"><b>Daily Bloom</b><div class="fine">One special word a day. Streak ' + S.streak + ' days.</div></div><span class="chip acc">+3 pts</span></button>';
  var ad = S.plus ? '' : '<div style="margin-top:10px"><div class="ad"><span class="adlabel" style="position:static;margin-right:8px">Ad</span>Banner</div><div style="text-align:right"><button class="lnk" data-a="paywall" data-back="home">Remove ads</button></div></div>';
  return '<div class="body" style="align-items:center;text-align:center"><div style="width:100%;display:flex;justify-content:space-between"><span class="chip acc">Level ' + S.level + '</span><span class="chip"><img src="../rose_of_jericho.svg" alt="">&times;' + S.res.rose + '</span></div>' +
    '<div style="width:230px;margin-top:6px">' + wm() + '</div><div class="eyebrow" style="margin-top:2px;letter-spacing:.2em">Guess words. Grow a garden.</div>' +
    '<div style="flex:1;display:grid;place-items:center"><div class="fcont" style="margin:0">' + flowerSVG(8, 'happy') + '</div></div>' + daily +
    '<div style="width:100%;display:grid;gap:12px;margin-top:12px"><button class="btn primary" data-a="play">&#x25B6; Play</button><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:48px;font-size:15px" data-a="garden">My Garden</button><button class="btn secondary" style="height:48px;font-size:15px" data-a="shed">Garden Shed</button><button class="btn secondary" style="height:48px;font-size:15px" data-a="map">Level Map</button><button class="btn secondary" style="height:48px;font-size:15px" data-a="settings">Settings</button></div></div>' + ad + '</div>';
};
/* --- game --- */
var G = null;
function pickWord(daily) {
  if (daily) return { w: DAILY.w, h: DAILY.h, daily: true };
  var pool = WORDS.filter(function (x) { return S.used.indexOf(x.w) < 0; }); if (!pool.length) { S.used = []; pool = WORDS; }
  var w = (S.used.length === 0 && C('wins') === 0) ? WORDS[0] : pool[Math.floor(Math.random() * pool.length)]; S.used.push(w.w); return w;
}
function startRound(daily) { var w = pickWord(daily); G = { w: w.w, h: w.h, daily: !!daily, g: {}, wrong: 0, over: false, revived: 0 }; S.screen = 'game'; render(); }
function tilesHTML() { return G.w.split('').map(function (c) { var s = G.g[c]; return '<div class="tile ' + (s ? 'hit' : (G.over && G.wrong >= 8 ? 'rev blank' : 'blank')) + '">' + (s || (G.over && G.wrong >= 8) ? c : '') + '</div>'; }).join(''); }
function kbHTML() { return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map(function (l) { var s = G.g[l], cls = s === 1 ? 'hit' : (s === 2 ? 'miss' : ''); return '<button data-a="key" data-k="' + l + '" class="' + cls + '"' + (s ? ' disabled' : '') + '>' + l + '</button>'; }).join(''); }
function missedHTML() { var m = Object.keys(G.g).filter(function (k) { return G.g[k] === 2; }); return 'Missed: <b style="color:var(--danger)">' + (m.join(' ') || 'none yet') + '</b>'; }
R.game = function () {
  var left = 8 - G.wrong;
  return '<div class="body"><div class="nav"><button class="ibtn" data-a="home" style="border:0;color:inherit" aria-label="Home">&#x2715;</button><span class="chip acc">' + (G.daily ? 'Daily Bloom' : 'Level ' + S.level) + '</span><span class="chip"><img src="../rose_of_jericho.svg" alt="">&times;' + S.res.rose + '</span></div>' +
    '<div style="text-align:center;margin-top:2px"><div class="fcont" id="fc">' + flowerSVG(left, G.wrong < 3 ? 'happy' : (G.wrong < 6 ? 'neutral' : 'oh')) + '</div><div class="eyebrow" id="pleft">' + left + ' petals left</div></div>' +
    '<div class="card" style="margin-top:8px;padding:12px 16px"><div class="eyebrow">Hint</div><div style="font-size:16px;font-weight:600;line-height:1.35;margin-top:4px">' + G.h + '</div></div>' +
    '<div style="margin:16px 0 8px"><div class="tiles" id="tiles">' + tilesHTML() + '</div></div><div id="missed" style="text-align:center;font-size:13px;color:var(--muted)">' + missedHTML() + '</div><div class="kb" id="kb">' + kbHTML() + '</div></div>';
};
function guess(l) {
  if (!G || G.over || G.g[l]) return;
  var hit = G.w.indexOf(l) >= 0; G.g[l] = hit ? 1 : 2;
  if (!hit) { G.wrong++; dropPetal(8 - G.wrong); cue2('soft tick', 'soft pluck'); } else cue2('light tick', 'soft chime');
  var won = G.w.split('').every(function (c) { return G.g[c]; }), dead = G.wrong >= 8;
  if (won || dead) G.over = true;
  var set = function (id, h) { var e = $(id); if (e) e.innerHTML = h; }; set('#tiles', tilesHTML()); set('#kb', kbHTML()); set('#missed', missedHTML());
  var fc = $('#fc'); if (fc) { var anim = $('#fc .fl'); fc.innerHTML = flowerSVG(8 - G.wrong, G.wrong < 3 ? 'happy' : (G.wrong < 6 ? 'neutral' : 'oh')) + Array.prototype.map.call(fc.querySelectorAll('.fallp'), function () { return ''; }).join(''); }
  set('#pleft', (8 - G.wrong) + ' petals left');
  if (!hit && fc) { /* re-add falling petal after innerHTML reset */ dropPetal(8 - G.wrong); }
  if (won) setTimeout(win, 450); else if (dead) setTimeout(function () { S.screen = 'dead'; render(); }, 900);
}
function win() {
  var misses = G.wrong, rw = { water: 1 + (misses <= 2 ? 1 : 0) + (G.daily ? 1 : 0), shed: 1 + (G.daily ? 3 : 0), scoop: 0 };
  S.res.water = Math.min(40, S.res.water + rw.water); S.res.shed += rw.shed; S.frac = (S.frac || 0) + .25 + (G.daily ? 1 : 0); while (S.frac >= 1) { S.frac -= 1; S.res.scoop++; rw.scoop++; }
  inc('wins'); if (misses === 0) inc('perfect'); if (misses <= 2) inc('steady'); if (G.w.length >= 8) inc('long'); if (G.daily) { inc('daily'); S.dailyDone = true; S.streak++; }
  var pl = earnPlant(G.w); S.last = { word: G.w, misses: misses, plant: pl ? pl.imageName : null, rw: rw, daily: G.daily };
  progress(); celebrate('celebration', function () { S.screen = 'earned'; render(); }); cue2('success haptic + rising pulses', 'bloom chime');
}
R.earned = function () {
  var L = S.last, p = L.plant ? plantObj(L.plant) : null;
  return '<div class="body" style="text-align:center"><div class="eyebrow" style="margin-top:8px">' + (p ? 'Plant earned' : 'You solved it') + '</div>' + (p ? '<div style="position:relative;margin:6px 0"><div style="position:absolute;inset:-20px 20px 10px;border-radius:50%;background:radial-gradient(closest-side,color-mix(in srgb,var(--accent) 35%,transparent),transparent)"></div>' + plantImg(p.imageName, 190, 'sway') + '</div><div style="font-weight:900;font-size:30px">' + p.name + '</div><div style="font-size:12px;color:var(--muted);font-style:italic">' + p.botanicalName + '</div><div class="card" style="margin:12px 0;text-align:left;font-size:14px;line-height:1.4">' + p.botanicalFact + '</div>' : '<div style="font-size:60px;margin:20px">&#x1F33C;</div><div style="font-weight:900;font-size:26px">' + L.word + '</div><div class="fine" style="margin:8px 0">All plants of the current level are already in your garden.</div>') +
    '<div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap"><span class="chip">&#x1F4A7; +' + L.rw.water + '</span><span class="chip acc">&#x2B50; +' + L.rw.shed + '</span>' + (L.rw.scoop ? '<span class="chip">&#x1F331; +' + L.rw.scoop + '</span>' : '') + '</div><div style="flex:1"></div>' +
    '<div style="display:grid;gap:10px;margin-top:14px"><button class="btn primary" data-a="after" data-d="' + (L.daily ? 'home' : 'game') + '">' + (L.daily ? 'Done' : 'Next round') + '</button><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:46px;font-size:15px" data-a="shareWin">Share</button><button class="btn secondary" style="height:46px;font-size:15px" data-a="after" data-d="home">Home</button></div></div></div>';
};
R.dead = function () {
  var has = S.res.rose > 0;
  return '<div class="body" style="text-align:center"><div style="height:8px"></div><div class="fcont">' + flowerSVG(0, 'oh') + '</div><div style="font-weight:900;font-size:24px;margin-top:6px">The flower is bare</div><div class="fine" style="margin:6px 0 14px">The word was <b>' + G.w + '</b>. Nothing is lost. A Rose of Jericho can bring the petals back.</div>' +
    (has ? '<button class="btn rose" data-a="revive" style="width:100%"><img src="../rose_of_jericho.svg" alt=""><span>Revive with Rose of Jericho<small>Gets 3 petals back. You have ' + S.res.rose + '.</small></span></button>' : '<div class="card fine">No Rose of Jericho left. They arrive now and then as you play.</div>') +
    '<div style="flex:1"></div><div style="display:grid;gap:10px"><button class="btn secondary" data-a="giveup">Try a new word</button><button class="lnk" data-a="home">Home</button></div></div>';
};
R.lost = function () { return '<div class="body" style="text-align:center;justify-content:center"><div style="font-size:54px">&#x1F331;</div><div style="font-weight:900;font-size:24px;margin:6px 0">The word was ' + G.w + '</div><div class="fine" style="margin-bottom:20px">' + G.h + '</div><button class="btn primary" data-a="after" data-d="game">Next round</button><button class="lnk" data-a="after" data-d="home">Home</button></div>'; };
/* --- garden --- */
R.garden = function () {
  var lv = S.viewLevel, tabs = [1, 2, 3, 4, 5].map(function (l) { var open = l <= S.level; return '<button class="chipx ' + (l === lv ? 'on' : '') + '" data-a="viewlevel" data-l="' + l + '" style="font-size:12px;' + (open ? '' : 'opacity:.5') + '">' + (open ? '' : '&#x1F512; ') + 'L' + l + '</button>'; }).join('');
  var ps = A.plants.filter(function (p) { return p.level === lv; }), cells = ps.map(function (p) { var o = S.plants[p.imageName];
    return o ? '<button class="pc" data-a="plant" data-id="' + p.imageName + '">' + plantImg(p.imageName, 70) + '<div>' + p.name + '</div><div class="fine">Stage ' + o.stage + '</div></button>' : '<button class="pc lk" data-a="locked">' + plantImg(p.imageName, 70, 'sil') + '<div>???</div><div class="fine">Locked</div></button>'; }).join('');
  var n = Object.keys(S.plants).length;
  return '<div class="body">' + nav('My Garden', 'home', '<span class="chip acc">' + n + ' / 50</span>') + '<div style="display:flex;gap:6px;margin:4px 0 10px">' + tabs + '</div><div class="pg">' + cells + '</div><div style="flex:1"></div><div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-top:14px"><button class="btn secondary" style="height:46px;font-size:13px" data-a="badges">Badges</button><button class="btn secondary" style="height:46px;font-size:13px" data-a="album">Visitors</button><button class="btn secondary" style="height:46px;font-size:13px" data-a="bfIntro">Net game</button></div></div>';
};
function stageHTML(id) {
  var o = S.plants[id], w = [60, 96, 128, 158, 180][o.stage - 1], dr = (Date.now() - o.lastWater > 240000);
  var plant = o.stage === 1 ? '<svg class="pl" style="left:' + (90 - 22) + 'px;width:44px" viewBox="0 0 60 70"><path d="M8 64 Q30 42 52 64Z" fill="#6B4A38"/><path d="M30 54 V32" stroke="#4E9A4C" stroke-width="4" stroke-linecap="round"/><ellipse cx="22" cy="32" rx="10" ry="6" transform="rotate(-25 22 32)" fill="#5FA860"/><ellipse cx="38" cy="30" rx="10" ry="6" transform="rotate(25 38 30)" fill="#3F8A4A"/></svg>' : '<img class="pl' + (dr ? ' dr' : '') + '" style="left:' + (90 - w / 2) + 'px;width:' + w + 'px" src="../plants/' + id + '.svg" alt="">';
  return plant;
}
R.plant = function () {
  var id = S.p.id, o = S.plants[id], pl = plantObj(id), nxt = STAGES[o.stage] === undefined ? null : STAGES[o.stage], prev = STAGES[o.stage - 1], pct = nxt ? Math.round((o.gp - prev) / (nxt - prev) * 100) : 100, dr = (Date.now() - o.lastWater > 240000);
  var tr = A.toolMeta.map(function (t) { var own = S.tools[t.id]; return '<button class="' + (S.hand === t.id ? 'act' : '') + (own ? '' : ' lk') + '" data-a="' + (own ? 'hand' : 'locktool') + '" data-t="' + t.id + '" aria-label="' + A.vo[t.id][S.tier[t.id]] + '">' + A.tool[t.id][S.tier[t.id]] + '</button>'; }).join('');
  return '<div class="body">' + nav(pl.name, 'garden', resBar().replace(/<span class="chip">&#x1F331; \d+<\/span>/, '')) + '<div style="text-align:center;position:relative"><div class="st" id="stage" data-a="useTool"><div id="stageIn" style="position:relative;width:180px;height:180px">' + stageHTML(id) + '<div class="tl"></div><div class="fx"></div></div></div></div>' +
    '<div style="text-align:center;margin-top:-34px"><span class="mood ' + (dr ? 'neutral' : 'happy') + '" id="mood">' + (dr ? '&#x1F4A7; Droopy: perks right up with a drink' : '&#x263A; Happy') + '</span><div style="font-weight:800;margin-top:6px">Stage ' + o.stage + ' of 5 &middot; ' + STAGENAME[o.stage] + '</div><div class="hbar" style="margin:6px 40px"><i style="width:' + pct + '%"></i></div><div class="fine">' + o.gp + ' growth points' + (nxt ? ' &middot; next stage at ' + nxt : ' &middot; fully grown') + '</div></div>' +
    '<div class="tray">' + tr + '</div><div class="fine" style="text-align:center">Tap a tool, then tap the plant (or the button).</div><div style="flex:1"></div><div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-top:10px"><button class="btn primary" style="height:48px;font-size:15px;grid-column:span 3" data-a="useTool">Use ' + A.toolMeta.filter(function (t) { return t.id === S.hand; })[0].name + '</button><button class="btn secondary" style="height:44px;font-size:14px" data-a="repot">Repot</button><button class="btn secondary" style="height:44px;font-size:14px" data-a="prune">Prune</button><button class="btn secondary" style="height:44px;font-size:14px" data-a="sunspot">Sunny spot</button></div></div>';
};
function useTool(forceTool) {
  var id = S.p.id, o = S.plants[id], t = forceTool || S.hand, why;
  if (t === 'net') { toast('The net is for catching visitors. Open Net game from the garden.'); return; }
  if (t === 'can') { if (S.res.water < 1) return needWater(); S.res.water--; o.lastWater = Date.now(); inc('water'); }
  else if (t === 'trowel') { if (S.res.scoop < 1) { toast('No soil scoops left. Wins and butterfly plays earn more.'); return; } S.res.scoop--; inc('feed'); }
  else if (t === 'shears') { if (Date.now() - o.pruneAt < 60000) { toast('Freshly trimmed. Come back a little later.'); return; } return openPrune(); }
  else if (t === 'mister') { if (Date.now() - o.mistAt < 20000) { toast('Still misty. Try again in a moment.'); return; } o.mistAt = Date.now(); inc('mist'); }
  else if (t === 'lamp') { if (Date.now() - o.sunAt < 30000) { toast('Enjoying the sun. Try again soon.'); return; } o.sunAt = Date.now(); inc('sun'); }
  var gp = { can: 4, trowel: 12, mister: 2, lamp: 2 + (S.tier.lamp - 1) }[t] * (t === 'trowel' ? [1, 1.25, 1.5][S.tier.trowel - 1] : 1); applyUse(t, Math.round(gp));
}
function needWater() { modal('<div style="font-size:40px">&#x1F4A7;</div><div style="font-weight:900;font-size:22px;margin:6px 0">Out of drops</div><div class="fine" style="margin-bottom:14px">Play a word to earn more. Drops also trickle in over time.</div><button class="btn primary" data-a="ovplay">Play a word</button><button class="lnk" data-a="ovclose">Not now</button>'); }
function applyUse(t, gp) {
  var cls = FXH[t], st = $('#stage'), tl = st.querySelector('.tl'), fx = st.querySelector('.fx'), plantBox = $('#stageIn'); cue(t);
  var done = function () { var up = addGP(S.p.id, gp); progress(); render(); toast('+' + gp + ' growth' + (up ? ' - stage up!' : '')); setTimeout(function () { flush(); }, 600); };
  if (S.rm) { plantBox.classList.add('flash'); setTimeout(done, 350); return; }
  plantBox.className = ''; plantBox.classList.add('st2'); st.className = 'st ' + cls; tl.innerHTML = A.toolBare[t][S.tier[t]]; fx.innerHTML = FX[cls]; setTimeout(done, 2500);
}
function openPrune() {
  var tips = [[40, 90], [150, 60], [255, 100]], done = 0;
  var stems = '<svg viewBox="0 0 300 300" style="width:100%"><path d="M96 262 H204 L192 296 H108Z" fill="#C98A4B"/><rect x="90" y="254" width="120" height="14" rx="6" fill="#B07A4B"/>';
  var ends = [[60, 110], [150, 70], [240, 120]];
  ends.forEach(function (e) { stems += '<path d="M150 260 C' + (150 + (e[0] - 150) * .3) + ' 210 ' + (e[0]) + ' 190 ' + e[0] + ' ' + e[1] + '" stroke="#4E9A4C" stroke-width="9" fill="none" stroke-linecap="round"/>'; });
  ends.forEach(function (e, i) { stems += '<g class="tip" data-a="snip" data-i="' + i + '" style="cursor:pointer"><ellipse cx="' + e[0] + '" cy="' + e[1] + '" rx="24" ry="14" fill="#6DB06A"/><circle cx="' + e[0] + '" cy="' + e[1] + '" r="32" fill="none" stroke="#F2B53E" stroke-width="3.5" stroke-dasharray="6 6"/></g>'; });
  modal('<div style="font-weight:900;font-size:20px">Prune</div><div class="fine">Tap each glowing stem to trim it. No timer.</div>' + stems + '</svg><div class="fine" id="pcount">0 of 3 trimmed</div><button class="lnk" data-a="ovclose">Skip, it is fine as it is</button>', true);
  S.pruneLeft = 3;
}
R.repot = function () {
  var id = S.p.id, idx = A.plants.map(function (p) { return p.imageName; }).indexOf(id), fav = SOILS[idx % 4][0];
  var cells = SOILS.map(function (s) { var c = SOILC[s[0]]; return '<button class="soil" data-a="soil" data-s="' + s[0] + '"><svg viewBox="0 0 78 60"><path d="M4 54 C4 30 24 8 40 8 C56 8 74 30 74 54Z" fill="' + c[0] + '"/><circle cx="24" cy="38" r="3" fill="' + c[1] + '"/><circle cx="40" cy="28" r="3" fill="' + c[1] + '"/><circle cx="52" cy="42" r="3" fill="' + c[1] + '"/><circle cx="34" cy="46" r="2.4" fill="' + c[1] + '"/></svg><b>' + s[1] + '</b><small>' + s[2] + (s[0] === fav ? ' &middot; &#x2605; ' + plantObj(id).name + ' likes this' : '') + '</small></button>'; }).join('');
  return '<div class="body">' + nav('Choose soil', 'plantback') + '<div style="text-align:center">' + plantImg(id, 110) + '</div><div class="fine" style="text-align:center;margin:4px 0 10px">Every soil works. Matching the favourite helps it grow faster. Uses 1 soil scoop.</div><div class="soils">' + cells + '</div></div>';
};
function doRepot(soil) {
  var id = S.p.id, idx = A.plants.map(function (p) { return p.imageName; }).indexOf(id), fav = SOILS[idx % 4][0], match = soil === fav;
  if (S.res.scoop < 1) { toast('No soil scoops left. Wins and butterfly plays earn more.'); return; }
  S.res.scoop--; S.plants[id].soil = soil; inc('repot'); if (match) inc('match'); var gp = match ? 15 : 5; addGP(id, gp); cue('trowel'); progress();
  modal('<div style="position:relative">' + plantImg(id, 160) + (match ? '<span class="sparkle" style="left:30px;top:10px">&#x2726;</span><span class="sparkle" style="right:30px;top:30px">&#x2726;</span>' : '') + '</div><div class="mood ' + (match ? 'happy' : 'neutral') + '" style="margin-top:8px">' + (match ? '&#x263A; Happy! ' + SOILS.filter(function (s) { return s[0] === soil; })[0][1] + ' suits ' + plantObj(id).name : '&#x1F642; Settled in') + '</div><div style="font-weight:900;font-size:22px;margin:10px 0 4px">' + (match ? 'Grows faster now' : 'Growing at its own pace') + '</div><div class="fine" style="margin-bottom:14px">+' + gp + ' growth points' + (match ? '' : '. Tip: try ' + SOILS.filter(function (s) { return s[0] === fav; })[0][1] + ' next time.') + '</div><button class="btn primary" data-a="repotDone">Nice</button>', true);
}
/* --- shed --- */
R.shed = function () {
  var cells = A.toolMeta.map(function (t) { var own = S.tools[t.id], tr = S.tier[t.id];
    if (!own) return '<div class="tcard lk">' + A.tool[t.id][1] + '<b>' + t.name + '</b><span class="lockchip">&#x1F512; ' + UNL[t.id] + '</span></div>';
    var up = tr < 3 ? '<button class="mini sec" style="margin-top:6px" data-a="upgrade" data-t="' + t.id + '">Upgrade ' + (tr === 1 ? 30 : 120) + ' pts</button>' : '<div class="fine" style="margin-top:6px">Max tier</div>';
    return '<div class="tcard ' + (S.hand === t.id ? 'act' : '') + '" aria-label="' + A.vo[t.id][tr] + '">' + A.tool[t.id][tr] + '<b>' + t.name + '</b><small>Tier ' + tr + ' of 3. ' + t.desc.split(',')[0] + '</small><button class="mini ' + (S.hand === t.id ? '' : 'sec') + '" data-a="hand" data-t="' + t.id + '">' + (S.hand === t.id ? 'In hand' : 'Pick up') + '</button>' + up + '</div>'; }).join('');
  return '<div class="body">' + nav('Garden Shed', 'home', '<span class="chip acc">&#x2B50; ' + S.res.shed + '</span>') + '<div class="fine" style="margin:0 4px 8px">You start with a watering can and a trowel. New tools are earned by playing and never bought. Upgrades use shed points.</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">' + cells + '</div></div>';
};
/* --- level map --- */
R.map = function () {
  var rows = [5, 4, 3, 2, 1].map(function (l) { var n = A.plants.filter(function (p) { return p.level === l && S.plants[p.imageName]; }).length, open = l <= S.level, done = S.levelDone[l];
    return '<button class="card" data-a="viewmap" data-l="' + l + '" style="width:100%;border:0;color:inherit;display:flex;align-items:center;gap:14px;margin-bottom:10px;text-align:left;' + (open ? '' : 'opacity:.55') + '"><div style="width:48px;height:48px;border-radius:50%;background:' + (done ? 'var(--success)' : (l === S.level ? 'var(--accent)' : 'var(--line)')) + ';color:#fff;display:grid;place-items:center;font-weight:900;font-size:20px">' + (done ? '&#x2713;' : (open ? l : '&#x1F512;')) + '</div><div style="flex:1"><b>Level ' + l + '</b><div class="fine">' + n + ' of 10 plants' + (l === S.level ? ' &middot; you are here' : '') + '</div><div class="hbar" style="margin-top:6px"><i style="width:' + n * 10 + '%"></i></div></div></button>'; }).join('');
  return '<div class="body">' + nav('Level Map', 'home') + '<div class="fine" style="margin:0 4px 10px">A level is complete when all 10 of its plants are flourishing (stage 4). Tap a level to open its garden.</div>' + rows + '</div>';
};
/* --- settings --- */
function sw(k) { return '<span class="sw2 ' + (S.set[k] ? 'on' : '') + '" data-a="setting" data-k="' + k + '" role="switch"></span>'; }
R.settings = function () {
  var plus = S.plus ? '<div class="row"><img src="data:image/svg+xml;utf8,' + encodeURIComponent(A.icon) + '" width="36" style="border-radius:9px"><div><b>WordFlora Plus</b><div class="sub">' + (S.plan === 'y' ? 'Yearly &middot; renews Nov 5, 2027 at $12.99' : 'Monthly &middot; renews Dec 2, 2026 at $3.99') + '</div></div><span class="pill">Active</span></div><div class="row"><span>No ads</span><span class="chev">On</span></div><div class="row"><span>iCloud sync</span><span class="chev">Synced just now</span></div><div class="row" data-a="toast" data-t="Opens the system subscription page"><span>Manage subscription</span><span class="chev">&#x203A;</span></div>'
    : '<div class="row" data-a="paywall" data-back="settings"><img src="data:image/svg+xml;utf8,' + encodeURIComponent(A.icon) + '" width="36" style="border-radius:9px"><div><b>WordFlora Plus</b><div class="sub">No ads and iCloud sync. From $1.08 a month.</div></div><span class="chev">&#x203A;</span></div>';
  return '<div class="body">' + nav('Settings', 'home') + '<div class="cap2">Plus</div><div class="grp">' + plus + '</div><div class="cap2">Play</div><div class="grp"><div class="row"><span>Sound</span>' + sw('sound') + '</div><div class="row"><span>Haptics</span>' + sw('haptics') + '</div><div class="row"><span>Reduce Motion</span><span class="sw2 ' + (S.rm ? 'on' : '') + '" data-a="rm"></span></div><div class="row"><div>Remind me<div class="sub">One gentle nudge a day, never guilt</div></div>' + sw('remind') + '</div></div><div class="cap2">Appearance</div><div class="grp"><div class="row" style="gap:6px">' + ['system', 'light', 'dark'].map(function (t) { return '<button class="mini ' + (S.set.theme === t && !S.theme ? '' : 'sec') + '" data-a="theme" data-t="' + t + '" style="flex:1">' + t.charAt(0).toUpperCase() + t.slice(1) + '</button>'; }).join('') + '</div></div>' +
    '<div class="cap2">Purchases</div><div class="grp"><div class="row" data-a="toast" data-t="Prototype: no purchases to restore"><span>Restore Purchases</span><span class="chev">&#x203A;</span></div></div><div class="cap2">Prototype helpers</div><div class="grp"><div class="row" data-a="helper" data-h="tools"><span>Unlock all tools</span></div><div class="row" data-a="helper" data-h="res"><span>Add drops, scoops and shed points</span></div><div class="row" data-a="helper" data-h="plants"><span>Earn 3 plants instantly</span></div><div class="row" data-a="helper" data-h="level"><span>Finish current level</span></div></div></div>';
};
/* --- paywall / ad --- */
R.paywall = function () {
  var y = S.plan === 'y';
  var terms = y ? '<b>Free for 3 days, then $12.99 per year.</b> You will not be charged today. First charge: <b>$12.99 on Nov 5, 2026</b>. Renews every year at $12.99 until you cancel. Cancel any time in Settings &gt; your name &gt; Subscriptions, at least 24 hours before a renewal.' : '<b>$3.99 charged today (Nov 2, 2026)</b> and renews every month at $3.99 until you cancel. No free trial on the monthly plan. Cancel any time in Settings &gt; your name &gt; Subscriptions, at least 24 hours before a renewal.';
  return '<div class="body"><div style="display:flex;justify-content:space-between;align-items:center"><button class="xbtn" data-a="payback" aria-label="Close">&#x2715;</button><span class="fine">Optional. The game stays free.</span></div><div style="text-align:center;margin:4px 0 8px"><img src="data:image/svg+xml;utf8,' + encodeURIComponent(A.icon) + '" width="58" style="border-radius:13px"><div style="font-weight:900;font-size:24px;margin-top:4px">WordFlora Plus</div></div>' +
    '<div style="display:flex;gap:10px;font-size:14px;margin-bottom:6px"><span>&#x1F6AB;</span><div><b>No ads</b><div class="fine">No quick-break ads between rounds.</div></div></div><div style="display:flex;gap:10px;font-size:14px;margin-bottom:10px"><span>&#x2601;&#xFE0F;</span><div><b>iCloud sync</b><div class="fine">Your garden follows you across devices.</div></div></div>' +
    '<div class="plan ' + (y ? 'sel' : '') + '" data-a="plan" data-p="y"><div class="radio"></div><div><div class="n">Yearly<span class="tag">3 days free</span></div><div class="d">$1.08 a month. Saves 73% vs paying monthly ($47.88).</div></div><div class="p">$12.99<small>per year</small></div></div><div class="plan ' + (!y ? 'sel' : '') + '" data-a="plan" data-p="m"><div class="radio"></div><div><div class="n">Monthly</div><div class="d">No free trial</div></div><div class="p">$3.99<small>per month</small></div></div>' +
    '<button class="btn primary" data-a="subscribe" style="height:52px">' + (y ? 'Start 3-day free trial' : 'Subscribe for $3.99 a month') + '</button><div class="fine" style="margin-top:8px">' + terms + ' Payment is charged to your Apple Account. Prototype: no real purchase.</div><div style="display:flex;flex-wrap:wrap;gap:4px 14px;justify-content:center;font-size:12px;font-weight:700;margin-top:6px"><a data-a="toast" data-t="Prototype: nothing to restore" style="text-decoration:underline;cursor:pointer">Restore Purchases</a><a data-a="toast" data-t="Opens the system subscription page" style="text-decoration:underline;cursor:pointer">Manage Subscriptions</a><a data-a="toast" data-t="Terms of Use" style="text-decoration:underline;cursor:pointer">Terms of Use</a><a data-a="toast" data-t="Privacy Policy" style="text-decoration:underline;cursor:pointer">Privacy Policy</a></div></div>';
};
R.ad = function () {
  return '<div class="body"><div style="display:flex;justify-content:space-between;align-items:center"><span class="eyebrow">Quick break</span><button class="xbtn" data-a="adclose" aria-label="Close ad">&#x2715;</button></div><div style="text-align:center;margin:12px 0"><div style="font-weight:900;font-size:24px">Nice work, 3 rounds done</div><div style="color:var(--muted);font-size:14px">Take a breath. Your next word is ready when you are.</div></div><div class="adslot"><span class="adlabel">Ad</span>Ad slot</div><div style="display:flex;justify-content:space-between;margin:6px 4px"><button class="lnk" data-a="toast" data-t="Thanks, ad reported (prototype)">Report ad</button><button class="lnk" data-a="adfree">Go ad-free</button></div><div style="flex:1"></div><button class="btn primary" data-a="adclose">Next round</button></div>';
};
/* --- badges / album --- */
R.badges = function () {
  var n = Object.keys(S.badges).length, cells = A.badgeMeta.map(function (b) { var t = S.badges[b.id]; return '<button class="' + (t ? '' : 'lk') + '" data-a="badge" data-id="' + b.id + '">' + (t ? A.badge[b.id][t] : A.badge[b.id].lock) + b.title + '</button>'; }).join('');
  return '<div class="body">' + nav('Badges', 'garden', '<span class="chip acc">' + n + ' / 36</span>') + '<div class="fine" style="margin:0 4px 10px">Badges are only ever added, never taken away. Tap one to see its progress.</div><div class="bshelf">' + cells + '</div></div>';
};
function badgeCard(id) {
  var b = A.badgeMeta.filter(function (x) { return x.id === id; })[0], t = S.badges[id] || 0, v = bval(id), nxt = b.th[t] || null;
  modal('<div class="medal" style="animation:none;width:130px">' + (t ? A.badge[id][t] : A.badge[id].lock) + '</div><div style="font-weight:900;font-size:22px;margin-top:6px">' + b.title + '</div><div class="fine">' + b.desc + '</div><div style="margin:10px 0">' + [1, 2, 3].map(function (i) { return '<span class="chipx" style="margin:2px;' + (t >= i ? 'background:var(--accent);color:var(--accent-ink)' : '') + '">' + ['', 'Bronze', 'Silver', 'Gold'][i] + ' ' + b.th[i - 1] + '</span>'; }).join('') + '</div><div class="fine">Progress: ' + v + (nxt ? ' / ' + nxt + ' ' + b.unit : ' (all tiers done)') + '</div>' + (t ? '<button class="btn secondary" style="height:44px;margin-top:12px" data-a="shareBadge" data-id="' + id + '" data-t="' + t + '">Share badge</button>' : '') + '<button class="lnk" data-a="ovclose">Close</button>');
}
R.album = function () {
  var n = Object.keys(S.stickers).length, cells = A.species.map(function (s) { var c = S.stickers[s.id]; var ev = s.night;
    return '<div class="c ' + (c ? '' : 'lock') + '" data-a="species" data-id="' + s.id + '">' + A.stk[s.id] + '<div>' + (c ? s.name : (ev ? 'Evening visitor' : '???')) + '</div><small>' + (c ? s.rarity + ' &middot; x' + c : (ev ? 'Comes out in the evening' : s.rarity)) + '</small></div>'; }).join('');
  return '<div class="body">' + nav('Garden Visitors', 'garden', '<span class="chip acc">' + n + ' / 12</span>') + '<div class="card" style="display:flex;gap:10px;align-items:center;padding:8px 12px;margin-bottom:8px"><div style="width:40px">' + A.lantern + '</div><div style="flex:1;font-size:12px"><b>Glow Lantern x' + S.lantern + '</b><br><span class="fine">Meet evening visitors any time, for one play.</span></div></div><div class="album">' + cells + '</div></div>';
};
/* --- butterfly --- */
R.bfIntro = function () {
  var left = Math.max(0, 3 - S.bfPlays), eve = S.evening;
  return '<div class="body">' + nav('Net game', 'garden') + '<div style="text-align:center;margin-top:10px"><div style="font-size:50px">&#x1F98B;</div><div style="font-weight:900;font-size:26px;margin:4px 0">Garden Visitors</div><div style="color:var(--muted);font-size:14px;line-height:1.45;margin:0 8px">Butterflies, bees and ladybugs are visiting. ' + (S.rm ? 'Tap a visitor resting on a flower to say hello.' : 'Swipe with your net to say hello.') + ' About 35 seconds. Missing is fine, nothing bad happens.</div></div>' +
    '<div class="card" style="margin:16px 0;font-size:13px">' + (eve ? '&#x1F319; It is evening: fireflies and moths are out.' : 'Evening visitors come out 17:30 to 21:30.') + (!eve && S.lantern ? '<div style="margin-top:8px"><button class="mini sec" data-a="lantern">Use Glow Lantern (x' + S.lantern + ')</button></div>' : '') + '</div><div class="fine" style="text-align:center">Rewarded plays today: ' + left + ' of 3. Extra plays are just for fun.</div><div style="flex:1"></div><button class="btn primary" data-a="bfStart">Start</button></div>';
};
var BF = null, bfRaf = null;
R.bf = function () { return '<div class="body" style="padding:0"><div class="hud"><span class="chip" id="bfc">&#x1F98B; 0</span><div class="bar2"><i id="bft" style="width:100%"></i></div><button class="chip" data-a="bfEnd" style="border:0">Done</button></div><div class="scene ' + BF.tone + '" id="scene"><div class="hill" style="position:absolute;left:-10%;right:-10%;bottom:0;height:42%;border-radius:50% 50% 0 0/22% 22% 0 0"></div>' +
  ['daisy', 'tulip', 'sunflower', 'poppy'].map(function (n, i) { return '<img src="../plants/plant_' + n + '.svg" style="position:absolute;bottom:34px;left:' + (14 + i * 92) + 'px;width:76px" alt="">'; }).join('') + '<svg class="trail" id="trail" viewBox="0 0 390 794"></svg></div></div>'; };
function spawnList() {
  var night = S.evening || BF.lantern, dayL = ['monarch', 'swallowtail', 'cabbagewhite', 'paintedlady', 'honeybee', 'bumblebee', 'ladybug', 'dragonfly', 'morpho', 'hummingbird'], nightL = ['firefly', 'luna'];
  var pool = []; if (!S.evening) pool = pool.concat(dayL, dayL.slice(0, 6)); if (night) pool = pool.concat(nightL, nightL); return pool;
}
function bfStartGame() {
  BF = { t: 0, dur: 35, catches: 0, newOnes: [], list: [], tone: S.evening ? 'dusk' : 'day', lantern: !!S.lanternActive, got: [], rewarded: S.bfPlays < 3 }; S.screen = 'bf'; render();
  var sc = $('#scene'), pool = spawnList(), W = 390, H = 794;
  function addV(id, x, y) { var d = document.createElement('div'); d.className = 'v'; d.innerHTML = '<div class="fl2"><div class="a">' + A.vis[id].a + '</div><div class="b">' + A.vis[id].b + '</div></div>'; sc.appendChild(d); var v = { id: id, el: d, x: x, y: y, vx: (Math.random() * 40 + 25) * (Math.random() < .5 ? -1 : 1), ph: Math.random() * 6, amp: Math.random() * 30 + 15, base: y }; return v; }
  function newVisitor() { var id = pool[Math.floor(Math.random() * pool.length)]; if (S.rm) { var spots = [[200, 430], [22, 500], [300, 540], [110, 470], [250, 380]]; var s = spots[Math.floor(Math.random() * spots.length)]; var v = addV(id, s[0], s[1]); v.vx = 0; v.rest = true; var r = document.createElement('div'); r.className = 'ring'; r.style.cssText = 'left:' + (s[0] - 6) + 'px;top:' + (s[1] - 6) + 'px;width:68px;height:68px'; sc.appendChild(r); v.ring = r; return v; } return addV(id, Math.random() < .5 ? -60 : W + 10, 120 + Math.random() * 380); }
  var n = S.rm ? 4 : 7; for (var i = 0; i < n; i++) { var v = newVisitor(); if (!S.rm) v.x = Math.random() * W; BF.list.push(v); }
  function catchV(v) {
    var id = v.id, sp = A.species.filter(function (s) { return s.id === id; })[0], isNew = !S.stickers[id]; S.stickers[id] = (S.stickers[id] || 0) + 1; BF.catches++; BF.got.push(id); if (isNew) BF.newOnes.push(id);
    inc('catch'); if (sp.night) inc('night'); if (sp.rarity === 'rare' && isNew) inc('rare'); if (id === 'honeybee' || id === 'bumblebee') inc('bee');
    var pop = document.createElement('div'); pop.className = 'pop'; pop.style.left = (v.x - 25) + 'px'; pop.style.top = (v.y - 40) + 'px'; pop.innerHTML = A.stk[id]; sc.appendChild(pop); setTimeout(function () { pop.remove(); }, 1100);
    v.el.remove(); if (v.ring) v.ring.remove(); BF.list.splice(BF.list.indexOf(v), 1); $('#bfc').innerHTML = '&#x1F98B; ' + BF.catches; cue('net'); setTimeout(function () { if (BF && S.screen === 'bf') BF.list.push(newVisitor()); }, 900);
  }
  function hit(x, y, rad) { BF.list.slice().forEach(function (v) { if (Math.hypot(v.x + 28 - x, v.y + 28 - y) < rad) catchV(v); }); }
  var down = false, last = null, tr = $('#trail');
  function pos(e) { var r = sc.getBoundingClientRect(), k = 390 / r.width; return [(e.clientX - r.left) * k, (e.clientY - r.top) * k]; }
  sc.onpointerdown = function (e) { down = true; var p = pos(e); last = p; hit(p[0], p[1], S.rm ? 46 : 36 + S.tier.net * 8); };
  sc.onpointermove = function (e) { if (!down || S.rm) return; var p = pos(e); var path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('d', 'M' + last[0] + ' ' + last[1] + ' L' + p[0] + ' ' + p[1]); tr.appendChild(path); setTimeout(function () { path.remove(); }, 400); last = p; hit(p[0], p[1], 36 + S.tier.net * 8); };
  window.addEventListener('pointerup', function up() { down = false; window.removeEventListener('pointerup', up); });
  BF.hit = hit; BF.catchV = catchV;
  var t0 = null, lastT = null;
  function tick(ts) {
    if (!BF || S.screen !== 'bf') return; if (t0 == null) { t0 = ts; lastT = ts; } var dt = (ts - lastT) / 1000; lastT = ts; BF.t += dt;
    BF.list.forEach(function (v) { if (!v.rest) { v.x += v.vx * dt; v.y = v.base + Math.sin(BF.t * 1.3 + v.ph) * v.amp; if (v.x < -80 || v.x > 470) { v.vx = -v.vx; } } v.el.style.transform = 'translate(' + v.x + 'px,' + v.y + 'px)'; v.el.style.left = 0; v.el.style.top = 0; });
    var tb = $('#bft'); if (tb) tb.style.width = Math.max(0, 100 - BF.t / BF.dur * 100) + '%';
    if (BF.t >= BF.dur) { bfFinish(); return; } bfRaf = requestAnimationFrame(tick);
  }
  cancelAnimationFrame(bfRaf); bfRaf = requestAnimationFrame(tick);
  BF.list.forEach(function (v) { v.el.style.transform = 'translate(' + v.x + 'px,' + v.y + 'px)'; });
}
function bfFinish() {
  cancelAnimationFrame(bfRaf); if (!BF) return; var rw = { water: 0, shed: 0, scoop: 0 };
  if (BF.rewarded) { rw.water = 1 + Math.min(BF.catches, 3); rw.shed = 2; if (Math.random() < .3) rw.scoop = 1; S.bfPlays++; S.res.water = Math.min(40, S.res.water + rw.water); S.res.shed += rw.shed; S.res.scoop += rw.scoop; }
  else { rw.water = 0; }
  S.lanternActive = false; BF.rw = rw; S.lastBF = { catches: BF.catches, newOnes: BF.newOnes.slice(), got: BF.got.slice(), rw: rw, rewarded: BF.rewarded }; progress(); S.screen = 'bfSum'; render();
}
R.bfSum = function () {
  var L = S.lastBF, st = L.got.slice(0, 6).map(function (id) { return '<div style="width:62px">' + A.stk[id] + '</div>'; }).join('');
  return '<div class="body" style="text-align:center"><div style="height:24px"></div><div style="font-size:44px">&#x1F33C;</div><div style="font-weight:900;font-size:26px">Nice visiting!</div><div style="color:var(--muted);font-size:14px;margin:4px 0 14px">' + (L.catches ? 'You said hello to ' + L.catches + ' visitor' + (L.catches > 1 ? 's' : '') : 'A quiet garden this time, and that is lovely too') + '</div><div style="display:flex;gap:6px;justify-content:center;flex-wrap:wrap">' + st + '</div>' +
    '<div class="card" style="margin-top:16px;text-align:left"><div class="eyebrow">Rewards</div><div style="display:grid;gap:6px;margin-top:8px;font-size:14px">' + (L.rewarded ? '<div>&#x1F4A7; +' + L.rw.water + ' water drops</div><div>&#x2B50; +' + L.rw.shed + ' shed points</div>' + (L.rw.scoop ? '<div>&#x1F331; +1 soil scoop</div>' : '') : '<div>Extra play: just for fun, no rewards today.</div>') + (L.newOnes.length ? '<div>&#x1F4D2; New stickers: ' + L.newOnes.map(function (id) { return A.species.filter(function (s) { return s.id === id; })[0].name; }).join(', ') + '</div>' : '') + '</div></div><div class="fine" style="margin-top:8px">Every round ends with a reward, even a quiet one. There is no losing.</div><div style="flex:1"></div><button class="btn primary" data-a="bfIntro">Play again</button><div class="fine" style="margin:8px 0">Rewarded plays left today: ' + Math.max(0, 3 - S.bfPlays) + ' of 3</div><button class="btn secondary" style="height:46px" data-a="album">Open album</button><button class="lnk" data-a="garden">Done</button></div>';
};

/* ---------- router ---------- */
var afterRender = {};
function render() {
  var fn = R[S.screen] || R.home; $('#screen').innerHTML = (S.screen === 'bf' ? '' : status()) + fn(); applyTheme();
  if (S.screen === 'intro') startIntro();
  if (S.screen === 'bf') $('#screen').insertAdjacentHTML('afterbegin', status());
  save(); flush();
}
function go(s, p) { cancelAnimationFrame(bfRaf); S.screen = s; if (p) S.p = p; render(); }
var introRaf = null;
function startIntro() {
  var r = FR.create({ variant: 'standard', reduce: !!S.rm, seed: 7 }), cv = $('#rainCv'), cx = cv.getContext('2d'); cx.setTransform(2, 0, 0, 2, 0, 0); var t0 = null; cancelAnimationFrame(introRaf);
  function f(ts) { if (S.screen !== 'intro') { cx.clearRect(0, 0, 390, 844); return; } if (t0 == null) t0 = ts; var t = Math.min((ts - t0) / 1000, r.duration); cx.clearRect(0, 0, 390, 844); r.draw(cx, t, themeNow()); var w = $('#introWm'); if (w) { w.style.opacity = r.wordmarkOpacity(t); w.style.transform = 'translateY(' + r.wordmarkRise(t) + 'px)'; } if (t >= r.duration) { setTimeout(function () { if (S.screen === 'intro') { cx.clearRect(0, 0, 390, 844); go('home'); } }, 900); return; } introRaf = requestAnimationFrame(f); }
  introRaf = requestAnimationFrame(f);
}
function after(dest) {
  if (!S.last.daily) { S.rounds++; S.sinceAd++; } progress();
  var adDue = !S.plus && !S.last.daily && S.sinceAd >= 3;
  pending = function () { if (adDue) { S.sinceAd = 0; S.adDest = dest; go('ad'); } else if (dest === 'game') startRound(false); else go('home'); };
  releasing = true; flush();
}
function share(title, sub, svg) { modal('<div class="shcard" style="border-radius:22px;padding:22px;background:var(--bg);border:1px solid var(--line)"><div style="display:flex;justify-content:space-between;font-size:11px;font-weight:800;letter-spacing:.08em;color:var(--muted)"><span>WORDFLORA</span><span>SHARE</span></div><div style="width:170px;margin:16px auto 8px">' + svg + '</div><div style="font-weight:900;font-size:24px">' + title + '</div><div style="color:var(--muted);font-size:13px;margin:4px 0 10px">' + sub + '</div><div style="width:150px;margin:8px auto 0">' + wm() + '</div></div><button class="btn primary" style="margin-top:14px;height:48px" data-a="shared">Share</button><button class="lnk" data-a="ovclose">Close</button>'); }

/* ---------- actions ---------- */
function act(a, d) {
  switch (a) {
    case 'skipIntro': cancelAnimationFrame(introRaf); $('#rainCv').getContext('2d').clearRect(0, 0, 780, 1688); go('home'); break;
    case 'home': case 'garden': case 'shed': case 'map': case 'settings': case 'album': case 'badges': if (a === 'garden') S.viewLevel = Math.min(S.viewLevel, S.level); go(a); break;
    case 'play': startRound(false); break; case 'daily': startRound(true); break;
    case 'key': guess(d.k); break;
    case 'revive': S.res.rose--; inc('revive'); G.wrong = 5; G.over = false; S.screen = 'game'; render(); toast('Three petals are back'); cue2('success haptic', 'warm chime'); break;
    case 'giveup': S.last = { daily: false }; go('lost'); break;
    case 'after': after(d.d); break;
    case 'shareWin': { var p = S.last.plant ? plantObj(S.last.plant) : null; inc('share'); share(p ? 'I grew a ' + p.name : 'I solved ' + S.last.word, 'in WordFlora', p ? plantImg(p.imageName, 170) : '<div style="font-size:70px">&#x1F33C;</div>'); progress(); break; }
    case 'shareBadge': inc('share'); closeNoFlush(); share(A.badgeMeta.filter(function (b) { return b.id === d.id; })[0].title, ['', 'Bronze', 'Silver', 'Gold'][d.t] + ' badge', A.badge[d.id][d.t]); break;
    case 'shared': toast('Prototype: share sheet would open'); closeNoFlush(); flush(); break;
    case 'viewlevel': if (+d.l <= S.level) { S.viewLevel = +d.l; render(); } else toast('Finish Level ' + (+d.l - 1) + ' to open this one'); break;
    case 'viewmap': if (+d.l <= S.level) { S.viewLevel = +d.l; go('garden'); } else toast('Locked: finish the level before it'); break;
    case 'locked': toast('Win a round to earn this plant'); break;
    case 'plant': go('plant', { id: d.id }); break;
    case 'hand': S.hand = d.t; cue2('light selection tick', 'wooden clack'); if (S.screen === 'plant') render(); else render(); break;
    case 'locktool': toast('Locked: ' + UNL[d.t]); break;
    case 'useTool': useTool(); break;
    case 'repot': go('repot'); break; case 'plantback': go('plant'); break;
    case 'soil': doRepot(d.s); break; case 'repotDone': closeNoFlush(); go('plant'); flush(); break;
    case 'prune': useTool('shears'); break;
    case 'snip': { var g = d.i; var el = document.querySelector('.tip[data-i="' + g + '"]'); if (el) { el.remove(); S.pruneLeft--; cue('shears'); $('#pcount').textContent = (3 - S.pruneLeft) + ' of 3 trimmed'; if (S.pruneLeft <= 0) { var o = S.plants[S.p.id]; o.pruneAt = Date.now(); inc('prune'); addGP(S.p.id, 4 + (S.tier.shears - 1) * 2); closeNoFlush(); progress(); render(); toast('Trimmed! +4 growth'); setTimeout(flush, 500); } } break; }
    case 'sunspot': useTool('lamp'); break;
    case 'upgrade': { var t = d.t, cost = S.tier[t] === 1 ? 30 : 120; if (S.res.shed >= cost) { S.res.shed -= cost; S.tier[t]++; inc('upgrade'); progress(); render(); toast(t + ' upgraded to tier ' + S.tier[t]); } else toast('Needs ' + cost + ' shed points. You have ' + S.res.shed + '.'); break; }
    case 'setting': S.set[d.k] = !S.set[d.k]; render(); break; case 'rm': S.rm = !S.rm; applyTheme(); render(); break;
    case 'theme': S.theme = null; S.set.theme = d.t; render(); break;
    case 'helper': helper(d.h); break;
    case 'paywall': S.back = d.back || S.screen; go('paywall'); break;
    case 'payback': go(S.back || 'home'); break;
    case 'plan': S.plan = d.p; render(); break;
    case 'subscribe': S.plus = true; toast('Prototype: Plus is now active (no real purchase)'); go('settings'); break;
    case 'adclose': { var dest = S.adDest || 'home'; if (dest === 'game') startRound(false); else go('home'); break; }
    case 'adfree': S.back = S.adDest === 'game' ? 'home' : 'home'; go('paywall'); break;
    case 'badge': badgeCard(d.id); break;
    case 'species': { var sp = A.species.filter(function (s) { return s.id === d.id; })[0]; if (S.stickers[d.id]) { inc('facts'); progress(); modal('<div style="width:130px;margin:0 auto">' + A.stk[d.id] + '</div><div style="font-weight:900;font-size:22px">' + sp.name + '</div><div style="font-size:12px;color:var(--muted);font-style:italic">' + sp.latin + '</div><div style="font-size:14px;line-height:1.4;margin:10px 0">' + sp.fact + '</div><button class="btn primary" data-a="ovclose" style="height:46px">Nice</button>'); } else toast(sp.night ? 'Comes out in the evening' : 'Not met yet. Visit the garden with the net.'); break; }
    case 'bfIntro': go('bfIntro'); break; case 'bfStart': bfStartGame(); break; case 'bfEnd': bfFinish(); break;
    case 'lantern': S.lantern--; S.lanternActive = true; toast('Glow Lantern lit: evening visitors are out'); render(); break;
    case 'ovclose': case 'ovbg': closeModal(); break;
    case 'ovplay': closeNoFlush(); startRound(false); break;
    case 'toast': toast(d.t); break;
  }
}
function closeNoFlush() { var o = $('#ov'); o.classList.remove('on'); o.innerHTML = ''; }
function helper(h) {
  if (h === 'tools') { Object.keys(S.tools).forEach(function (k) { S.tools[k] = 1; }); toast('All tools unlocked'); }
  if (h === 'res') { S.res.water = Math.min(40, S.res.water + 10); S.res.scoop += 5; S.res.shed += 50; toast('Added drops, scoops, shed points'); }
  if (h === 'plants') { for (var i = 0; i < 3; i++) earnPlant('X'); progress(); toast('3 plants added'); }
  if (h === 'level') { A.plants.filter(function (p) { return p.level === S.level; }).forEach(function (p) { if (!S.plants[p.imageName]) S.plants[p.imageName] = { gp: 0, stage: 1, lastWater: 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0 }; var o = S.plants[p.imageName]; o.gp = Math.max(o.gp, 100); o.stage = stageOf(o.gp); }); progress(); toast('Level finished'); }
  render();
}
/* ---------- wiring ---------- */
$('#phone').addEventListener('click', function (e) { var t = e.target.closest('[data-a]'); if (!t) return; if (t.dataset.a === 'ovbg' && e.target !== t) return; act(t.dataset.a, t.dataset); });
document.addEventListener('keydown', function (e) { if (S.screen === 'game' && /^[a-zA-Z]$/.test(e.key) && !modalOpen()) guess(e.key.toUpperCase()); });
$('#tTheme').onclick = function () { S.theme = themeNow() === 'dark' ? 'light' : 'dark'; applyTheme(); render(); };
$('#tRm').onchange = function () { S.rm = this.checked; applyTheme(); render(); };
$('#tFree').onclick = function () { S.plus = false; applyTheme(); render(); }; $('#tPlus').onclick = function () { S.plus = true; applyTheme(); render(); };
$('#tEve').onchange = function () { S.evening = this.checked; render(); };
$('#tReset').onclick = function () { try { localStorage.removeItem('wf-proto'); } catch (e) {} S = fresh(); queue = []; pending = null; G = null; closeNoFlush(); go('intro'); };
$('#tReal').onclick = function () { var r = $('#real'); r.style.display = r.style.display === 'block' ? 'none' : 'block'; };
function fit() { var h = window.innerHeight - $('#tb').offsetHeight - 40, w = window.innerWidth - 20, s = Math.min(1, h / 870, w / 410); $('#fit').style.transform = 'scale(' + s + ')'; $('#fit').style.height = (844 * s) + 'px'; $('#fit').style.width = (390 * s) + 'px'; $('#phone').style.transformOrigin = 'top left'; $('#phone').style.transform = 'scale(' + s + ')'; }
window.addEventListener('resize', fit);
window.__wf = { S: function () { return S; }, act: act, guess: guess, render: render, go: go, G: function () { return G; }, BF: function () { return BF; }, startRound: startRound, flush: flush, win: win, earnPlant: earnPlant, bfFinish: bfFinish };
if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches && !localStorage.getItem('wf-proto')) S.rm = true;
if (!S.screen || S.screen === 'bf' || S.screen === 'game' || S.screen === 'earned' || S.screen === 'dead' || S.screen === 'lost' || S.screen === 'bfSum') S.screen = 'home';
var q = new URLSearchParams(location.search); if (q.get('screen') && q.get('screen') !== 'bf') S.screen = q.get('screen'); if (q.get('screen') === 'bf') S.screen = 'bfIntro'; if (q.get('theme')) S.theme = q.get('theme');
if (q.get('seed')) { ['plant_dandelion', 'plant_daisy', 'plant_sunflower', 'plant_tulip'].forEach(function (id, i) { S.plants[id] = { gp: [5, 30, 95, 200][i], stage: stageOf([5, 30, 95, 200][i]), lastWater: i ? Date.now() : 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0 }; }); Object.keys(S.tools).forEach(function (k) { S.tools[k] = 1; }); S.res.water = 12; S.p = { id: 'plant_daisy' }; S.badges = { plant_collector: 1, first_butterfly: 1, streak: 1 }; S.stickers = { monarch: 2, honeybee: 1, ladybug: 3, dragonfly: 1 }; S.rm = true; }
if (S.screen === 'plant' && !S.p.id) S.screen = 'garden';
if (q.get('screen') === 'game') { G = { w: 'SUNFLOWER', h: WORDS[0].h, daily: false, g: { S: 1, U: 1, N: 1, X: 2, Q: 2 }, wrong: 2, over: false }; }
if (q.get('screen') === 'earned') { S.last = { word: 'SUNFLOWER', misses: 1, plant: 'plant_sunflower', rw: { water: 2, shed: 1, scoop: 0 }, daily: false }; }
if (q.get('screen') === 'dead') { G = { w: 'ROSE', h: 'x', daily: false, g: { Q: 2 }, wrong: 8, over: true }; }
fit(); applyTheme(); render();
if (q.get('screen') === 'bf') { if (q.get('eve')) { S.evening = true; $('#tEve').checked = true; } bfStartGame(); setTimeout(function () { BF.t = 12; }, 50); }
if (q.get('test')) { var im = new Image(); im.style.display = 'none'; im.src = '/__delay?s=' + (q.get('wait') || 28); document.body.appendChild(im); var s = document.createElement('script'); s.src = 'test.js'; document.body.appendChild(s); }
})();

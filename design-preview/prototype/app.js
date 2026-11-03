(function () {
'use strict';
var A = window.ART, FR = window.FlowerRain, $ = function (s) { return document.querySelector(s); };
$('#gdefs').innerHTML = A.gdefs;
var DAY = 86400000;
/* ---------- content ---------- */
var WORDS = [
 { w: 'SEED', lvl: 1, h: 'A tiny package that can grow into a plant.', h2: 'A flower makes it so new plants can start.', f: 'Poppy seeds can rest in soil for decades before they sprout.' },
 { w: 'ROSE', lvl: 1, h: 'A thorny garden favourite that smells sweet.', h2: 'Its fruits are called hips.', f: 'Rose hips are rich in vitamin C.' },
 { w: 'FERN', lvl: 1, h: 'A leafy plant that grows from spores, not seeds.', h2: 'It has fronds and no flowers.', f: 'Ferns reproduce with spores rather than seeds or flowers.' },
 { w: 'DAISY', lvl: 1, h: 'Its name means "day\'s eye" because it opens at sunrise.', h2: 'Its petals close at night.', f: 'Daisy comes from "day\'s eye": the petals close at night.' },
 { w: 'TULIP', lvl: 1, h: 'A cup-shaped spring flower that grows from a bulb.', h2: 'It was once a famous flower in the Netherlands.', f: 'In the 1630s people in the Netherlands paid enormous prices for tulip bulbs.' },
 { w: 'POLLEN', lvl: 1, h: 'Yellow dust that bees carry from flower to flower.', h2: 'Bees collect it to feed their young.', f: 'Bees carry pollen between flowers, which helps plants make seeds.' },
 { w: 'CACTUS', lvl: 2, h: 'A prickly plant that stores water in its stem.', h2: 'It grows in dry places.', f: 'Cacti store water in thick stems so they can grow in dry places.' },
 { w: 'NECTAR', lvl: 2, h: 'The sweet drink flowers offer to visitors.', h2: 'Hummingbirds and bees come for it.', f: 'Flowers make nectar to invite visitors that carry pollen.' },
 { w: 'BLOSSOM', lvl: 2, h: 'A flower, especially on a fruit tree.', h2: 'Cherry trees are covered in them in spring.', f: 'Blossoms on fruit trees turn into fruit after visitors carry pollen.' },
 { w: 'LOTUS', lvl: 2, h: 'A pink water flower with round floating leaves.', h2: 'Water rolls right off its leaves.', f: 'Lotus leaves repel water: this is called the lotus effect.' },
 { w: 'CLOVER', lvl: 2, h: 'A little three-leaf plant that feeds the soil.', h2: 'Lucky ones have four leaves.', f: 'Clover roots host bacteria that turn nitrogen from the air into plant food.' },
 { w: 'POPPY', lvl: 2, h: 'A bright red flower with papery petals.', h2: 'Its seeds can rest in soil for decades.', f: 'Poppy seeds can sprout when the ground is turned, even after decades.' },
 { w: 'JASMINE', lvl: 3, h: 'A climbing plant with sweet white flowers.', h2: 'Its scent is strongest at night.', f: 'Jasmine blooms release most of their scent at night.' },
 { w: 'ORCHID', lvl: 3, h: 'An elegant flower from a huge plant family.', h2: 'It grows on trees in warm forests.', f: 'Orchids belong to one of the two largest flowering plant families.' },
 { w: 'LAVENDER', lvl: 3, h: 'Purple spikes with a calming scent.', h2: 'People have used it for scent for thousands of years.', f: 'People have used lavender for scent and bathing for thousands of years.' },
 { w: 'MARIGOLD', lvl: 3, h: 'Orange flowers that help keep pests away.', h2: 'Its roots release helpful compounds.', f: 'Marigold roots release compounds that deter harmful nematodes.' },
 { w: 'SUNFLOWER', lvl: 3, h: 'Its big golden head follows the sun when it is young.', h2: 'It is named for the sun it tracks.', f: 'Young sunflowers track the sun: this is called heliotropism.' }];
var TUTORIAL = { w: 'SEED', h: 'A tiny package that can grow into a plant.', h2: 'A flower makes it so new plants can start.', f: WORDS[0].f, tut: true };
var SOILS = [['loam', 'Loam', 'All-rounder'], ['sandy', 'Sandy', 'Drains fast'], ['peaty', 'Peaty', 'Holds moisture'], ['compost', 'Rich compost', 'Full of nutrients']];
var SOILC = { loam: ['#6B4A38', '#4E3426'], sandy: ['#D9BC8C', '#BFA070'], peaty: ['#3A2C24', '#5A4636'], compost: ['#4A3322', '#8BC34A'] };
var STAGES = [0, 11, 40, 90, 180], STAGENAME = ['', 'Seedling', 'Sprout', 'Growing', 'In bloom', 'Flourishing'];
var UNL = { can: 'Starter tool', trowel: 'Plant number 5', net: 'First level-up or day 3', mister: 'Finish garden level 1', shears: 'Finish garden level 2', lamp: 'Finish garden level 3' };
var FXH = { can: 'pour', trowel: 'scoop', shears: 'snip', mister: 'mist', lamp: 'glow' };
var FX = { pour: '<i></i><i></i><i></i><i></i>', scoop: '<i></i><i></i><i></i>', snip: '<i></i><i></i><i></i>', mist: '<i></i><i></i><i></i><i></i><i></i>', glow: '<i></i>' };
var CUE = { can: ['soft continuous haptic', 'gentle water trickle'], trowel: ['soft impact', 'low earthy thud'], shears: ['rigid light tick', 'crisp snip click'], mister: ['very light tap', 'airy pssht'], lamp: ['rising soft haptic', 'warm two-note chime'], net: ['soft medium impact', 'whoosh'] };
var WONDER = { plant_dandelion: 'A single dandelion seed can drift for miles on the wind.', plant_daisy: 'Every evening its petals fold up, and every morning it opens to the sun again.', plant_clover: 'Tiny bacteria on its roots pull nitrogen from the air and feed the soil.', plant_marigold: 'Underground, its roots quietly release compounds that keep harmful nematodes away.', plant_sunflower: 'Young sunflowers follow the sun across the sky all day long.', plant_tulip: 'In the 1630s, people in the Netherlands paid enormous prices for tulip bulbs.', plant_rose: 'After the flower fades, a rose grows fruits called rose hips.', plant_poppy: 'Poppy seeds can sleep in the soil for decades, then wake when the ground is turned.', plant_fern: 'Ferns grow from tiny spores instead of seeds or flowers.', plant_strawberry: 'Each tiny seed on a strawberry is really its own little fruit.', plant_orchid: 'Orchids belong to one of the two largest families of flowering plants.', plant_lavender: 'People have loved the scent of lavender for thousands of years.', plant_lotus: 'A lotus leaf makes raindrops roll off like tiny silver marbles.', plant_jasmine: 'Jasmine saves most of its scent for the night.' };
var TEMP = { sleepy: ['Sleepy', 'takes things slowly'], sunny: ['Sunny', 'loves a bright day'], shy: ['Shy', 'blooms quietly'], curious: ['Curious', 'notices everything'], stubborn: ['Stubborn', 'does things its own way'] };
var VOICE = { sleepy: { water: 'Mmm, that hit the spot.', sun: 'A cosy bit of sun.', repot: 'A new bed. Lovely.', bloom: 'Oh, I seem to be in bloom.' }, sunny: { water: 'Ahh, lovely! Thank you.', sun: 'Sunshine, my favourite.', repot: 'Fresh soil, fresh start!', bloom: 'Look at me glow!' }, shy: { water: 'Oh, thank you.', sun: 'That is nice and warm.', repot: 'Oh, new soil. I like it.', bloom: 'Is that me? I am blooming.' }, curious: { water: 'What a nice drop!', sun: 'Look how the light moves.', repot: 'So much to explore down here.', bloom: 'A flower! I made a flower.' }, stubborn: { water: 'Fine, that was a good drink.', sun: 'Yes. Sun. Correct.', repot: 'I suppose this soil will do.', bloom: 'I did say I would.' } };
function temperament(id) { var n = id.replace('plant_', ''); if (/cactus|lithops|joshua|puya|silversword|welwitschia|baobab|dragon/.test(n)) return 'stubborn'; if (/fern|ghost|bleeding|sensitive|pitcher/.test(n)) return 'shy'; if (/sunflower|marigold|daisy|dandelion|hibiscus|tulip/.test(n)) return 'sunny'; if (/orchid|lotus|passion|sundew|venus|rafflesia|corpse/.test(n)) return 'curious'; return ['sleepy', 'sunny', 'shy', 'curious', 'stubborn'][A.plants.map(function (p) { return p.imageName; }).indexOf(id) % 5]; }
var BAD = /\b(miss|missed|lonely|alone|waiting|abandon|abandoned|neglect|neglected|forgot|die|died|dying|dead|lost|last chance|lose streak|broken streak|hurry|now or never|expires|only|last|smart|genius|best gardener|talented|beat|better than)\b/i;
function safe(t, fb) { return BAD.test(t || '') ? (fb || 'Every plant in the garden has a story.') : t; }

function fresh() {
  return { screen: 'intro', p: {}, theme: null, rm: false, plus: false, plan: 'y', evening: false, homeDusk: false, season: 'spring', young: false, age: null, lantern: 0, skew: 0,
    ftue: 'intro', unl: {}, showAll: false, tips: {}, dayIdx: 0,
    res: { water: 1, scoop: 3, shed: 0, rose: 0 }, seed: 0, tools: { can: 1, trowel: 0, net: 0, mister: 0, shears: 0, lamp: 0 }, tier: { can: 1, trowel: 1, net: 1, mister: 1, shears: 1, lamp: 1 }, hand: 'can',
    plants: {}, wordUnlocked: 1, wordPick: 1, wlUps: 0, gardenDone: {}, rounds: 0, sinceRest: 0, adDue: false, graceOff: false, lastAdAt: 0, adsToday: 0, peakAt: 0, peakKind: '', quietUntil: 0, umpDone: false, used: [], dailyDone: '', days: [], lastDay: null, streak: 0, best: 0,
    stickers: {}, badges: {}, C: {}, bfPlays: 0, viewLevel: 1, diary: [], ceremony: {}, review: [], hist: [], playMin: 0, welcome: null, gratDay: null, assist: 0,
    set: { sound: true, haptics: true, remind: false, theme: 'system', streak: true, calm: false, quiet: false, diff: 'auto' } };
}
var S = fresh();
try { var raw = localStorage.getItem('wf-proto2'); if (raw && location.search.indexOf('fresh') < 0) { var o = JSON.parse(raw); S = Object.assign(fresh(), o); S.set = Object.assign(fresh().set, o.set || {}); } } catch (e) {}
function save() { try { localStorage.setItem('wf-proto2', JSON.stringify(S)); } catch (e) {} }
function now() { return Date.now() + S.skew; }
function dkey(t) { var d = new Date(t === undefined ? now() : t); return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2); }
function C(k) { return S.C[k] || 0; }
function inc(k, n) { S.C[k] = C(k) + (n === undefined ? 1 : n); }
function Q() { return !!S.set.quiet; }
function calm() { return !!S.set.calm || S.young; }
function dusk() { return S.evening || S.homeDusk; }
function themeNow() { var t = S.set.theme; if (t === 'system') t = (window.matchMedia && matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light'; return S.theme || t; }
function applyTheme() {
  document.documentElement.setAttribute('data-theme', themeNow()); document.body.classList.toggle('rm', !!S.rm);
  $('#tRm').checked = !!S.rm; $('#tFree').classList.toggle('on', !S.plus); $('#tPlus').classList.toggle('on', S.plus); $('#tEve').checked = !!S.evening; $('#tYoung').checked = !!S.young; $('#tSeason').value = S.season;
}
function cue2(h, s) { $('#log').textContent = 'Haptic: ' + (S.set.haptics ? h : 'off') + '  |  Sound: ' + (S.set.sound ? s : 'off'); }
function cue(tool) { var c = CUE[tool] || [tool, '']; cue2(c[0], c[1]); }
var toastT; function toast(t) { var e = $('#toast'); e.textContent = t; e.classList.add('on'); clearTimeout(toastT); toastT = setTimeout(function () { e.classList.remove('on'); }, 2300); }
function status() { return '<div class="status"><span>9:41</span><span>100%</span></div>'; }
function resBar() { if (Q()) return ''; return '<div style="display:flex;gap:6px;flex-wrap:wrap"><span class="chip">&#x1F4A7; ' + S.res.water + '</span>' + (S.unl.soil || S.showAll ? '<span class="chip">&#x1F331; ' + S.res.scoop + '</span>' : '') + (S.unl.shed || S.showAll ? '<span class="chip acc">&#x2B50; ' + S.res.shed + '</span>' : '') + '</div>'; }
function nav(title, back, right) { return '<div class="nav"><button class="ibtn" data-a="' + back + '" style="border:0;color:inherit" aria-label="Back">&#x2039;</button><span class="t">' + title + '</span>' + (right || '<span style="width:36px"></span>') + '</div>'; }
function wm() { return A.wm[themeNow() === 'dark' ? 'dark' : 'light'].replace(/ width="\d+" height="\d+"/, ''); }
function plantObj(id) { return A.plants.filter(function (p) { return p.imageName === id; })[0]; }
function plantImg(id, w, cls) { return '<img src="../plants/' + id + '.svg" width="' + w + '" class="' + (cls || '') + '" alt="">'; }
function pname(id) { var o = S.plants[id]; return (o && o.nick) ? o.nick : plantObj(id).name; }
function stageOf(gp) { var s = 1; for (var i = 1; i < STAGES.length; i++) if (gp >= STAGES[i]) s = i + 1; return s; }
function seasonTag() { return S.season; }
function nPlants() { return Object.keys(S.plants).length; }
function markPeak(k) { S.peakAt = now(); S.peakKind = k; }
function diary(id, kind, text) { S.diary.unshift({ id: id, kind: kind, text: text, at: dkey(), season: S.season }); }
function streakLine() {
  if (!S.set.streak || Q()) return '';
  if (!S.lastDay) return '';
  var gap = Math.round((new Date(dkey()).getTime() - new Date(S.lastDay).getTime()) / DAY);
  return gap >= 2 ? 'Streak resting - your best was ' + S.best : 'Streak ' + S.streak + ' days';
}

/* ---------- flower mascot ---------- */
function flowerSVG(left, mood, folded) {
  var defs = '<defs><linearGradient id="fpk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F98FA2"/><stop offset="1" stop-color="#E8586F"/></linearGradient><radialGradient id="fgc" cx=".38" cy=".32" r=".8"><stop offset="0" stop-color="#F9D472"/><stop offset="1" stop-color="#E8A838"/></radialGradient></defs>', p = '', i;
  if (folded) {
    for (i = 0; i < 8; i++) p += '<path d="M0 -14 C-19 -26 -17 -58 0 -68 C17 -58 19 -26 0 -14Z" transform="translate(100 140) rotate(' + ((i - 3.5) * 8) + ') scale(1.0 1.45)" fill="url(#fpk)" fill-opacity="' + (.82 + (i % 2) * .18) + '"/>';
    return '<svg class="fl" viewBox="0 0 200 200">' + defs + '<path d="M100 150 V196" stroke="#4E9A4C" stroke-width="7" stroke-linecap="round"/><path d="M100 178 C84 176 74 182 70 192 C86 192 96 188 100 178Z" fill="#5FA860"/><path d="M100 170 C114 166 124 170 130 180 C116 182 106 180 100 170Z" fill="#3F8A4A"/>' + p + '<path d="M91 112 q4 4 8 0 M103 112 q4 4 8 0" fill="none" stroke="#2C3E2C" stroke-width="3" stroke-linecap="round"/><path d="M94 124 Q100 130 106 124" fill="none" stroke="#2C3E2C" stroke-width="3" stroke-linecap="round"/></svg>';
  }
  for (i = 0; i < 8; i++) if (i < left) p += '<path d="M0 -14 C-19 -26 -17 -58 0 -68 C17 -58 19 -26 0 -14Z" transform="translate(100 100) rotate(' + (i * 45) + ') scale(1.42 1.35)" fill="url(#fpk)"/><path d="M0 -26 C-4 -36 -4 -50 0 -58" transform="translate(100 100) rotate(' + (i * 45) + ') scale(1.42 1.35)" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="2.2" stroke-linecap="round"/>';
  var mouth = mood === 'happy' ? '<path d="M88 106 Q100 120 112 106" fill="none" stroke="#2C3E2C" stroke-width="4" stroke-linecap="round"/>' : (mood === 'oh' ? '<ellipse cx="100" cy="112" rx="5" ry="6" fill="#2C3E2C"/>' : '<path d="M91 111 H109" stroke="#2C3E2C" stroke-width="4" stroke-linecap="round"/>');
  return '<svg class="fl" viewBox="0 0 200 200">' + defs + p + '<circle cx="100" cy="100" r="31" fill="url(#fgc)"/><circle cx="90" cy="94" r="4.2" fill="#2C3E2C"/><circle cx="110" cy="94" r="4.2" fill="#2C3E2C"/>' + mouth + '</svg>';
}
function dropPetal(idx) {
  var c = $('.fcont'); if (!c || S.rm) return; var a = idx * 45 * Math.PI / 180, d = document.createElement('div'); d.className = 'fallp';
  d.style.left = (100 + 62 * Math.sin(a) - 30) + 'px'; d.style.top = (100 - 62 * Math.cos(a) - 30) + 'px'; d.style.setProperty('--dx', (Math.random() * 80 - 40) + 'px'); d.style.setProperty('--rot', (Math.random() * 360 - 180) + 'deg');
  d.innerHTML = '<svg viewBox="-20 -75 40 80"><path d="M0 -14 C-19 -26 -17 -58 0 -68 C17 -58 19 -26 0 -14Z" transform="rotate(' + (idx * 45) + ')" fill="#F4748A"/></svg>'; c.appendChild(d); setTimeout(function () { d.remove(); }, 1200);
}
function roseRing(n, size) {
  var r = size / 2 - 4, c = size / 2, segs = '', i; for (i = 0; i < 8; i++) { var a0 = (i * 45 - 90 + 4) * Math.PI / 180, a1 = ((i + 1) * 45 - 90 - 4) * Math.PI / 180; segs += '<path d="M' + (c + r * Math.cos(a0)) + ' ' + (c + r * Math.sin(a0)) + ' A' + r + ' ' + r + ' 0 0 1 ' + (c + r * Math.cos(a1)) + ' ' + (c + r * Math.sin(a1)) + '" stroke="' + (i < n ? '#4CAF50' : 'rgba(128,128,128,.3)') + '" stroke-width="5" fill="none" stroke-linecap="round"/>'; }
  return '<svg viewBox="0 0 ' + size + ' ' + size + '" width="' + size + '" height="' + size + '" aria-label="Rose seed ' + n + ' of 8">' + segs + '<image href="../rose_of_jericho.svg" x="' + (c - 12) + '" y="' + (c - 12) + '" width="24" height="24"/></svg>';
}
/* ---------- mood strip (season + time of day) ---------- */
var SEAS = { spring: ['#CDEBC8', '<circle cx="40" cy="40" r="6" fill="#F4A6B7"/><circle cx="300" cy="70" r="5" fill="#F7D3DC"/><circle cx="340" cy="30" r="6" fill="#F4A6B7"/>'], summer: ['#FFE9A8', '<circle cx="320" cy="50" r="24" fill="#F2B53E" opacity=".8"/>'], autumn: ['#F8D2AE', '<path d="M40 50 q12 -14 24 0 q-12 14 -24 0Z" fill="#E88A2E"/><path d="M310 30 q12 -14 24 0 q-12 14 -24 0Z" fill="#C9652B"/>'], winter: ['#D8E6F4', '<circle cx="50" cy="40" r="3" fill="#fff"/><circle cx="130" cy="70" r="2.5" fill="#fff"/><circle cx="310" cy="45" r="3" fill="#fff"/><circle cx="350" cy="90" r="2.5" fill="#fff"/>'] };
function moodStrip() {
  var s = SEAS[S.season], top = dusk() ? '#F0A066' : s[0], mid = dusk() ? '#9A78B0' : s[0];
  return '<div class="mood-strip" style="background:linear-gradient(' + top + (dusk() ? 'cc' : '88') + ',' + (dusk() ? '#7E6AA8' : s[0]) + '33 60%,transparent)"><svg viewBox="0 0 390 120" width="390" height="120">' + (dusk() ? '<circle cx="70" cy="60" r="18" fill="#FFE0A0" opacity=".85"/>' : s[1]) + '</svg></div>';
}
/* ---------- rain (<= 2.5 s, tappable to skip) ---------- */
var rainT = null, rainCb = null;
function stopRain(run) { cancelAnimationFrame(rainT); var cv = $('#rainCv'); cv.getContext('2d').clearRect(0, 0, 780, 1688); cv.style.opacity = 1; $('#skipRain').style.display = 'none'; var cb = rainCb; rainCb = null; if (run && cb) cb(); }
function celebrate(variant, cb) {
  if (S.rm) { if (cb) setTimeout(cb, 500); return; }
  var cv = $('#rainCv'), cx = cv.getContext('2d'); cx.setTransform(2, 0, 0, 2, 0, 0); var r = FR.create({ variant: variant, seed: Math.floor(Math.random() * 99), calm: calm() }), t0 = null, LIM = 2.5; cancelAnimationFrame(rainT); rainCb = cb || null; cv.style.opacity = 1; $('#skipRain').style.display = 'block';
  function f(ts) { if (t0 == null) t0 = ts; var t = (ts - t0) / 1000; cx.clearRect(0, 0, 390, 844); if (t < LIM) { cv.style.opacity = t > LIM - .4 ? Math.max(0, (LIM - t) / .4) : 1; r.draw(cx, Math.min(t, r.duration), themeNow()); rainT = requestAnimationFrame(f); } else stopRain(true); }
  rainT = requestAnimationFrame(f);
}
/* ---------- overlays ---------- */
function modal(html, noClose, cls) { var o = $('#ov'); o.innerHTML = '<div class="dim ' + (cls || '') + '" ' + (noClose ? '' : 'data-a="ovbg"') + '><div class="sheet">' + html + '</div></div>'; o.classList.add('on'); }
function closeNoFlush() { var o = $('#ov'); o.classList.remove('on'); o.innerHTML = ''; }
function closeModal() { closeNoFlush(); flush(); }
function modalOpen() { return $('#ov').classList.contains('on'); }
var queue = [], pending = null, releasing = false;
/* ---------- badges / unlocks ---------- */
function bval(id) {
  var cnt = nPlants(), caught = Object.keys(S.stickers).length;
  switch (id) {
    case 'plant_collector': return cnt; case 'level_sets': return Math.max(0, S.wordUnlocked - 1); case 'level_up': return S.wordUnlocked;
    case 'visitor_friend': return caught; case 'sticker_book': return Object.keys(S.stickers).reduce(function (a, k) { return a + S.stickers[k]; }, 0);
    case 'streak': return S.streak; case 'perfect_bloom': return C('perfect'); case 'resurrected': return C('revive'); case 'daily_bloom': return C('daily'); case 'word_whiz': return C('wins'); case 'steady_hands': return C('steady'); case 'long_word': return C('long');
    case 'first_bloom': case 'flower_power': return Object.keys(S.plants).filter(function (k) { return S.plants[k].stage >= 4; }).length;
    case 'green_thumb': return C('water'); case 'master_repotter': return C('repot'); case 'pruning_pro': return C('prune'); case 'mist_maker': return C('mist'); case 'sun_seeker': return C('sun'); case 'soil_scientist': return C('match'); case 'feeder': return C('feed');
    case 'first_butterfly': case 'gentle_net': return C('catch'); case 'dusk_visitor': return C('night'); case 'rare_visitor': return C('rare'); case 'field_notes': return C('facts'); case 'bee_friend': return C('bee'); case 'shed_keeper': return C('upgrade'); case 'sharer': return C('share');
  } return 0;
}
function checkBadges() {
  A.badgeMeta.forEach(function (b) { var v = bval(b.id), t = 0; b.th.forEach(function (x, i) { if (v >= x) t = i + 1; }); var cur = S.badges[b.id] || 0;
    if (t > cur) { S.badges[b.id] = t; S.res.shed += [0, 3, 10, 25][t]; queue.push({ type: 'badge', id: b.id, tier: t }); } });
  if (Object.keys(S.badges).length && !S.unl.badges) { S.unl.badges = true; queue.push({ type: 'tip', key: 'badges', t: 'Your badge shelf', b: 'Badges you earn are kept here, always yours to keep. Find it in the Garden.' }); }
}
function giveTool(k, tipKey, title, body) { if (!S.tools[k]) { S.tools[k] = 1; queue.push({ type: 'tip', key: tipKey || k, t: title, b: body }); } }
function checkUnlocks() {
  var n = nPlants();
  if (n >= 3 && !S.unl.sun) { S.unl.sun = true; queue.push({ type: 'tip', key: 'sun', t: 'Sunny spot is open', b: 'Plants like a bright patch. Tap "Sunny spot" on a plant to give it some sun.' }); }
  if (n >= 5 && !S.unl.soil) { S.unl.soil = true; S.tools.trowel = 1; queue.push({ type: 'tip', key: 'soil', t: 'Soil and the trowel', b: 'You can now repot plants into new soil and feed them with the trowel.' }); }
  if (S.wlUps >= 1 && !S.unl.net) { S.unl.net = true; S.unl.map = true; S.tools.net = 1; queue.push({ type: 'tip', key: 'net', t: 'Garden visitors', b: 'Butterflies and bees are visiting! Open the net game from your Garden.' }); }
  if (S.dayIdx >= 2 && !S.unl.net) { S.unl.net = true; S.tools.net = 1; queue.push({ type: 'tip', key: 'net', t: 'Garden visitors', b: 'It is your third day in the garden. Butterflies are visiting; open the net game from your Garden.' }); }
  if (S.wlUps >= 2 && !S.unl.shed) { S.unl.shed = true; queue.push({ type: 'tip', key: 'shed', t: 'The Garden Shed', b: 'Your tools live in the shed now. Upgrade them with shed points.' }); }
  if (S.gardenDone[1]) giveTool('mister', 'mister', 'New tool: Mister', 'A light spray for plants that like humid air.');
  if (S.gardenDone[2]) giveTool('shears', 'shears', 'New tool: Pruning shears', 'Trim stems to help a plant look fuller.');
  if (S.gardenDone[3]) giveTool('lamp', 'lamp', 'New tool: Sun lamp', 'A gentle lamp for a little extra light.');
}
function progress() {
  /* word track: all 10 plants of the active word level earned */
  var wl = S.wordUnlocked; if (wl < 5 && A.plants.filter(function (p) { return p.level === wl; }).every(function (p) { return S.plants[p.imageName]; })) { S.wordUnlocked = wl + 1; S.wordPick = S.wordUnlocked; S.wlUps++; markPeak('level-up'); queue.push({ type: 'wordup', lv: wl + 1 }); }
  /* garden track: all 10 plants of a level at stage 4 */
  for (var lv = 1; lv <= 5; lv++) if (!S.gardenDone[lv] && A.plants.filter(function (p) { return p.level === lv; }).every(function (p) { return S.plants[p.imageName] && S.plants[p.imageName].stage >= 4; })) { S.gardenDone[lv] = true; S.res.shed += 25; markPeak('level-up'); queue.push({ type: 'garden', lv: lv }); }
  checkBadges(); checkUnlocks(); save();
}
function flush() {
  if (modalOpen()) return;
  if (!releasing && (S.screen === 'earned' || S.screen === 'game' || S.screen === 'intro' || S.screen === 'bf' || S.screen === 'resting' || S.screen === 'age')) return;
  var i = -1; for (i = 0; i < queue.length; i++) { var q0 = queue[i]; if ((q0.type === 'badge' || q0.type === 'bloom') && now() < S.quietUntil && q0.type === 'badge') continue; break; }
  var q = i >= 0 && i < queue.length ? queue.splice(i, 1)[0] : null;
  if (q) { if (q.type === 'badge') showBadge(q.id, q.tier); else if (q.type === 'wordup') showWordUp(q.lv); else if (q.type === 'garden') showGardenUp(q.lv); else if (q.type === 'bloom') showCeremony(q.id); else if (q.type === 'tip') showTip(q); else if (q.type === 'stage') { toast(q.t); flush(); } return; }
  if (pending) { var p = pending; pending = null; releasing = false; p(); }
}
function showTip(q) { if (S.tips[q.key]) { flush(); return; } S.tips[q.key] = true; cue2('light tick', 'soft pop'); modal('<div style="font-size:30px">&#x1F4A1;</div><div style="font-weight:900;font-size:20px;margin:4px 0">' + q.t + '</div><div style="font-size:14px;line-height:1.45;color:var(--muted);margin-bottom:14px">' + q.b + '</div><button class="btn primary" style="height:48px" data-a="ovclose">Got it</button>'); }
function showBadge(id, tier) {
  var m = A.badgeMeta.filter(function (b) { return b.id === id; })[0], tn = ['', 'Bronze', 'Silver', 'Gold'][tier]; markPeak('badge');
  cue2('success haptic', 'bright chime'); celebrate('celebration');
  modal('<div class="eyebrow">Badge unlocked</div><div class="medal" style="margin-top:12px">' + A.badge[id][tier] + '</div><div style="font-weight:900;font-size:26px;margin-top:8px">' + m.title + '</div><div style="color:var(--muted);font-size:14px;margin:4px 0">' + m.desc + '. ' + tn + '.</div>' + (Q() ? '' : '<span class="chip acc">+' + [0, 3, 10, 25][tier] + ' shed points</span>') + '<div style="display:grid;gap:8px;margin-top:16px"><button class="btn primary" data-a="shareBadge" data-id="' + id + '" data-t="' + tier + '">Share badge</button><button class="btn secondary" style="height:46px" data-a="ovclose">Nice</button></div>');
}
function showWordUp(lv) { celebrate('celebration'); cue2('success haptic', 'bright chime'); modal('<div style="font-size:44px">&#x1F33C;</div><div style="font-weight:900;font-size:26px">Word level ' + lv + ' is open</div><div style="color:var(--muted);font-size:14px;margin:6px 0 14px">You have earned all 10 plants of level ' + (lv - 1) + '. New words are ready, and you can pick any open level on the Level Map.</div><button class="btn primary" data-a="ovclose">Wonderful</button>'); }
function showGardenUp(lv) { celebrate('celebration'); cue2('success haptic', 'bright chime'); modal('<div style="font-size:44px">&#x1F337;</div><div style="font-weight:900;font-size:26px">Garden level ' + lv + ' is flourishing</div><div style="color:var(--muted);font-size:14px;margin:6px 0 14px">All 10 plants are in bloom.' + (Q() ? '' : ' +25 shed points.') + '</div><button class="btn primary" data-a="ovclose">Lovely</button>'); }
/* first-bloom ceremony */
function showCeremony(id) {
  var o = S.plants[id], pl = plantObj(id); S.ceremony[id] = true; markPeak('bloom'); S.quietUntil = now() + 60000; diary(id, 'bloom', pname(id) + ' is in bloom'); cue2('soft swell haptic', 'soft bloom chime');
  var grat = !S.young && S.gratDay !== dkey(); var wonder = safe(WONDER[id] || pl.botanicalFact);
  var card = function () { modal('<div class="eyebrow">Wonder</div><div style="margin:6px 0">' + plantImg(id, 140) + '</div><div style="font-weight:900;font-size:22px">' + pname(id) + ' is in bloom</div><div style="font-size:15px;line-height:1.45;margin:10px 0 12px">' + wonder + '</div>' + (grat ? '<div class="card" style="margin-bottom:12px"><div style="font-weight:700;font-size:14px;margin-bottom:8px">One thing you liked today?</div><div style="display:flex;gap:6px;flex-wrap:wrap;justify-content:center"><button class="chipx" data-a="grat">A plant I grew</button><button class="chipx" data-a="grat">A word I got</button><button class="chipx" data-a="grat">Something outside</button></div><button class="lnk" data-a="grat">Not now</button></div>' : '') + '<button class="btn primary" style="height:48px" data-a="ovclose">Continue</button>', false, 'cer'); };
  if (S.rm) { card(); return; }
  modal('<div class="cerwrap" data-a="cerskip"><div class="cerp" style="width:150px;margin:40px auto 10px">' + plantImg(id, 150) + '</div><div class="cert">A quiet moment...</div><div class="fine" style="margin-top:20px">Tap to skip</div></div>', true, 'cer');
  setTimeout(function () { if (modalOpen() && $('.cerwrap')) card(); }, 2600);
}
/* ---------- state mutation helpers ---------- */
function earnPlant(word) {
  var all = A.plants, pick = all.filter(function (p) { return p.name.toUpperCase() === word && !S.plants[p.imageName] && p.level <= S.wordUnlocked; })[0];
  if (!pick) pick = all.filter(function (p) { return p.level === S.wordPick && !S.plants[p.imageName]; })[0] || all.filter(function (p) { return p.level <= S.wordUnlocked && !S.plants[p.imageName]; })[0];
  if (!pick) return null; S.plants[pick.imageName] = { gp: 0, stage: 1, lastWater: 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0, nick: '' };
  diary(pick.imageName, 'sprout', 'First sprout: ' + pick.name + ' joined the garden'); return pick;
}
function addGP(id, n) {
  var p = S.plants[id], old = p.stage; p.gp += n; p.stage = stageOf(p.gp);
  if (p.stage > old) { markPeak('stage-up'); diary(id, 'stage', pname(id) + ' grew to ' + STAGENAME[p.stage]); if (p.stage >= 4 && !S.ceremony[id]) queue.push({ type: 'bloom', id: id }); else queue.push({ type: 'stage', t: pname(id) + ' grew to ' + STAGENAME[p.stage] }); return true; } return false;
}
/* ---------- round bookkeeping ---------- */
function completeRound(daily) {
  var key = dkey(); if (S.lastDay !== key) { var y = dkey(now() - DAY); if (S.lastDay === y) S.streak++; else S.streak = 1; S.lastDay = key; } if (S.days.indexOf(key) < 0) S.days.push(key); S.best = Math.max(S.best, S.streak);
  S.seed++; var cap = false; if (S.seed >= 8) { if (S.res.rose < 3) { S.res.rose++; S.seed = 0; toast('A Rose of Jericho arrived'); } else { S.seed = 8; cap = true; } }
  if (!daily) { S.rounds++; S.sinceRest++; S.hist.push(1); S.hist = S.hist.slice(-10); }
  S.playMin += 1;
  return cap;
}
/* ---------- screens ---------- */
var R = {};
R.intro = function () { return '<div class="body" style="align-items:center;justify-content:center;text-align:center;padding:0" data-a="skipIntro"><div id="introWm" style="width:260px;opacity:0;margin-top:-150px">' + wm() + '</div><div class="fine" style="position:absolute;bottom:34px">Tap to skip</div></div>'; };
R.age = function () {
  return '<div class="body" style="text-align:center"><div style="height:30px"></div><img src="data:image/svg+xml;utf8,' + encodeURIComponent(A.icon) + '" width="64" style="border-radius:14px;margin:0 auto"><div style="font-weight:900;font-size:26px;margin:12px 0 4px">How old are you?</div><div class="fine" style="margin:0 10px 18px">This helps us keep WordFlora right for you. It stays on your device.</div>' +
    '<div style="display:grid;gap:12px"><button class="btn secondary" style="height:70px;font-size:20px" data-a="age" data-v="u13">Under 13</button><button class="btn secondary" style="height:70px;font-size:20px" data-a="age" data-v="teen">13 to 17</button><button class="btn secondary" style="height:70px;font-size:20px" data-a="age" data-v="adult">18 or older</button></div><div style="flex:1"></div><div class="fine">No birthday needed. A grown-up can change this later in Settings.</div></div>';
};
function ringBtn() { if (Q() || !(S.unl.rose || S.showAll)) return '<span></span>'; return '<button class="chip" data-a="roseInfo" style="border:0;padding:4px 10px 4px 4px;gap:4px">' + roseRing(S.seed, 38) + '<span style="font-weight:800">&times;' + S.res.rose + '</span></button>'; }
R.home = function () {
  var done = S.ftue === 'done', cnt = S.days.length, sl = streakLine();
  var daily = !done ? '' : (S.dailyDone === dkey() ? '<div class="card" style="display:flex;align-items:center;gap:12px;padding:12px 16px"><span style="font-size:26px">&#x2705;</span><div style="flex:1;text-align:left"><b>Daily Bloom done</b><div class="fine">A new word grows tomorrow.</div></div></div>' :
    '<button class="card" data-a="daily" style="display:flex;align-items:center;gap:12px;padding:12px 16px;border:0;width:100%;color:inherit;text-align:left"><span style="font-size:28px">&#x1F338;</span><div style="flex:1"><b>Daily Bloom</b><div class="fine">One special word a day, the same for everyone.</div></div>' + (Q() ? '' : '<span class="chip acc">+3 pts</span>') + '</button>');
  var showAds = !S.plus && !S.young && done;
  var ad = showAds ? '<div style="margin-top:10px"><div class="ad"><span class="adlabel" style="position:static;margin-right:8px">Ad</span>Banner</div><div style="text-align:right"><button class="lnk" data-a="paywall" data-back="home">Remove ads</button></div></div>' : '';
  var sub = '<div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap;margin-top:6px">' + (cnt ? '<span class="chipx">&#x1F33F; Garden Days: ' + cnt + '</span>' : '') + (sl ? '<span class="chipx">' + sl + '</span>' : '') + '</div>';
  var grid = '<button class="btn secondary" style="height:48px;font-size:15px" data-a="garden">My Garden</button>' + ((S.unl.map || S.showAll) ? '<button class="btn secondary" style="height:48px;font-size:15px" data-a="map">Level Map</button>' : '') + ((S.unl.shed || S.showAll) ? '<button class="btn secondary" style="height:48px;font-size:15px" data-a="shed">Garden Shed</button>' : '');
  return moodStrip() + '<div class="body" style="align-items:center;text-align:center"><div style="width:100%;display:flex;justify-content:space-between;align-items:center"><button class="ibtn" data-a="settings" aria-label="Settings" style="border:0;color:inherit">&#x2699;&#xFE0F;</button>' + (done ? '<span class="chip acc">Word level ' + S.wordPick + '</span>' : '<span></span>') + ringBtn() + '</div>' +
    '<div style="width:220px;margin-top:2px">' + wm() + '</div><div class="eyebrow" style="margin-top:2px;letter-spacing:.2em">Guess words. Grow a garden.</div>' + sub +
    '<div style="flex:1;display:grid;place-items:center"><div class="fcont" style="margin:0">' + flowerSVG(8, 'happy') + '</div></div>' + daily +
    '<div style="width:100%;display:grid;gap:12px;margin-top:12px"><button class="btn primary" data-a="play">&#x25B6; Play</button><div style="display:grid;grid-template-columns:' + (grid.split('btn secondary').length > 2 ? '1fr 1fr' : '1fr') + ';gap:10px">' + grid + '</div></div>' + ad + '</div>';
};
/* --- game --- */
var G = null;
function bandOk(w) { var d = S.young && S.set.diff === 'auto' ? 'gentle' : S.set.diff; if (d === 'auto') { var h = S.hist; if (h.length >= 5) { var r = h.reduce(function (a, b) { return a + b; }, 0) / h.length; d = r > .85 ? 'tricky' : (r < .5 ? 'gentle' : 'standard'); } else d = 'standard'; } S.autoNow = d; return d === 'gentle' ? w.length <= 6 : (d === 'tricky' ? w.length >= 7 : true); }
function pickWord(daily) {
  if (daily) { var k = dkey(), h = 0; for (var i = 0; i < k.length; i++) h = (h * 31 + k.charCodeAt(i)) % 9973; return WORDS[h % WORDS.length]; }
  var pool = WORDS.filter(function (x) { return x.lvl <= Math.min(S.wordPick, 3) && S.used.indexOf(x.w) < 0 && bandOk(x); }); if (!pool.length) { S.used = []; pool = WORDS.filter(function (x) { return x.lvl <= Math.min(S.wordPick, 3) && bandOk(x); }); } if (!pool.length) pool = WORDS;
  var w = pool[Math.floor(Math.random() * pool.length)]; S.used.push(w.w); return w;
}
function startRound(daily, tut) {
  var w = tut ? TUTORIAL : pickWord(daily); G = { w: w.w, h: w.h, h2: w.h2, f: w.f, daily: !!daily, tut: !!tut, g: {}, wrong: 0, over: false, help: 0, helpers: 0, sw: 0, pulsed: false, stage: '' }; S.screen = 'game'; render();
}
function tilesHTML() { return G.w.split('').map(function (c) { var s = G.g[c]; return '<div class="tile ' + (s ? 'hit' : 'blank') + '">' + (s ? c : '') + '</div>'; }).join(''); }
function kbHTML() { return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map(function (l) { var s = G.g[l], cls = s === 1 ? 'hit' : (s === 2 ? 'miss' : ''); return '<button data-a="key" data-k="' + l + '" class="' + cls + '"' + (s ? ' disabled' : '') + '>' + l + '</button>'; }).join(''); }
function notInHTML() { var m = Object.keys(G.g).filter(function (k) { return G.g[k] === 2; }); return 'Not in the word: <b style="color:var(--danger)">' + (m.join(' ') || 'none yet') + '</b>'; }
function unrevealed() { var s = {}; G.w.split('').forEach(function (c) { if (!G.g[c]) s[c] = 1; }); return Object.keys(s); }
function helpLabel() { var u = unrevealed(); if (G.help >= 3 || (G.help >= 1 && u.length <= 1)) return null; return ['Help: another hint', 'Help: show a vowel', 'Help: show the first letter'][G.help]; }
function helpBtn() { var l = helpLabel(); return '<button id="helpBtn" class="btn secondary ' + (G.pulse ? 'pulse' : '') + '" style="height:42px;font-size:14px;margin-top:8px" data-a="help"' + (l ? '' : ' disabled') + '>' + (l || 'That is all the help for this word') + '</button>'; }
R.game = function () {
  var left = 8 - G.wrong;
  return '<div class="body"><div class="nav"><button class="ibtn" data-a="home" style="border:0;color:inherit" aria-label="Home">&#x2715;</button><span class="chip acc">' + (G.tut ? 'First word' : (G.daily ? 'Daily Bloom' : 'Word level ' + S.wordPick)) + '</span>' + (S.res.rose && !Q() ? '<span class="chip"><img src="../rose_of_jericho.svg" alt="">&times;' + S.res.rose + '</span>' : '<span style="width:36px"></span>') + '</div>' +
    (G.tut ? '<div class="coach" id="coach">Tap a letter to guess the word. A petal falls for a wrong guess, but this flower cannot lose.</div>' : '') +
    '<div style="text-align:center;margin-top:2px"><div class="fcont" id="fc">' + flowerSVG(left, G.wrong < 3 ? 'happy' : (G.wrong < 6 ? 'neutral' : 'oh')) + '</div><div class="eyebrow" id="pleft">' + left + ' petals left</div></div>' +
    '<div class="card" style="margin-top:8px;padding:12px 16px"><div class="eyebrow">Hint</div><div style="font-size:16px;font-weight:600;line-height:1.35;margin-top:4px">' + G.h + '</div><div id="h2" style="font-size:14px;color:var(--muted);margin-top:6px">' + (G.help >= 1 ? 'Another hint: ' + G.h2 : '') + '</div></div>' +
    '<div style="margin:12px 0 6px"><div class="tiles" id="tiles">' + tilesHTML() + '</div></div><div id="missed" style="text-align:center;font-size:13px;color:var(--muted)">' + notInHTML() + '</div><div id="hb" style="text-align:center">' + helpBtn() + '</div><div class="kb" id="kb">' + kbHTML() + '</div>' + (G.tut ? '<div style="text-align:center"><button class="lnk" data-a="skipTut">Skip tutorial</button></div>' : '') + '</div>';
};
function refreshGame() {
  var set = function (id, h) { var e = $(id); if (e) e.innerHTML = h; }, left = 8 - G.wrong; set('#tiles', tilesHTML()); set('#kb', kbHTML()); set('#missed', notInHTML()); set('#pleft', left + ' petals left'); set('#hb', helpBtn());
  var h2 = $('#h2'); if (h2) h2.textContent = G.help >= 1 ? 'Another hint: ' + G.h2 : '';
  var fc = $('#fc'); if (fc) fc.innerHTML = flowerSVG(left, G.wrong < 3 ? 'happy' : (G.wrong < 6 ? 'neutral' : 'oh'));
}
function checkEnd() {
  var won = G.w.split('').every(function (c) { return G.g[c]; }); if (won && !G.over) { G.over = true; setTimeout(win, 450); }
  else if (G.wrong >= 8 && !G.over) { G.over = true; setTimeout(lose, 900); }
}
function guess(l) {
  if (!G || G.over || G.g[l] || S.screen !== 'game') return;
  var hit = G.w.indexOf(l) >= 0; G.g[l] = hit ? 1 : 2;
  if (!hit) { if (G.tut && G.wrong >= 7) { G.sw = 1; } else { G.wrong++; } G.sw = (G.sw || 0) + 1; cue2('soft impact', 'soft pluck'); } else { G.sw = 0; cue2('light tick', 'soft chime'); }
  if (!hit) { G.badRun = (G.badRun || 0) + 1; } else G.badRun = 0;
  var left = 8 - G.wrong; if ((G.badRun >= 3 || left <= 2) && !G.pulsed) { G.pulsed = true; G.pulse = true; }
  refreshGame(); if (!hit && !(G.tut && G.wrong >= 7 && G.sw > 1)) dropPetal(8 - G.wrong);
  if (G.tut && !hit && $('#coach')) $('#coach').textContent = 'No problem. A petal fell, but this flower is safe. Keep going.';
  if (!hit && !G.tut && left <= 2 && !S.tips.rose) { S.tips.rose = true; S.res.rose++; S.unl.rose = true; modal('<div style="font-size:34px"><img src="../rose_of_jericho.svg" width="56" alt=""></div><div style="font-weight:900;font-size:20px;margin:4px 0">A Rose of Jericho</div><div style="font-size:14px;line-height:1.45;color:var(--muted);margin-bottom:14px">When a flower is resting, a Rose can wake it up. Here is your first one, on us.</div><button class="btn primary" style="height:48px" data-a="ovclose">Got it</button>'); }
  checkEnd();
}
function doHelp() {
  if (!G || G.over) return; var u = unrevealed(); var vow = u.filter(function (c) { return 'AEIOU'.indexOf(c) >= 0; });
  if (G.help === 0) { G.help = 1; G.helpers++; cue2('light tick', 'soft pop'); }
  else if (G.help === 1) { if (u.length <= 1) return; var c = vow.length && u.length > 1 ? vow[0] : null; G.help = 2; G.helpers++; if (c) { G.g[c] = 1; cue2('light tick', 'soft chime'); } else { toast('No vowel left to show'); } }
  else if (G.help === 2) { if (u.length <= 1) return; var f = G.w.split('').filter(function (c) { return !G.g[c]; })[0]; G.help = 3; G.helpers++; G.g[f] = 1; cue2('light tick', 'soft chime'); }
  G.pulse = false; refreshGame(); checkEnd();
}
function win() {
  var rw = { water: Math.max(1, 1 + (G.wrong <= 2 ? 1 : 0) + (G.daily ? 1 : 0)), shed: G.tut ? 0 : 1 + (G.daily ? 3 : 0), scoop: 0 };
  if (G.tut) rw.water = 0;
  S.res.water = Math.min(40, S.res.water + rw.water); S.res.shed += rw.shed; S.frac = (S.frac || 0) + (G.tut ? 0 : .25 + (G.daily ? 1 : 0)); while (S.frac >= 1) { S.frac -= 1; S.res.scoop++; rw.scoop++; }
  inc('wins'); if (G.wrong === 0 && !G.helpers) inc('perfect'); if (G.wrong <= 2) inc('steady'); if (G.w.length >= 8) inc('long'); if (G.daily) { inc('daily'); S.dailyDone = dkey(); }
  if (!G.tut) S.hist.push(1);
  var cap = G.tut ? false : completeRound(G.daily); if (G.tut) { S.days.push(dkey()); S.lastDay = dkey(); S.streak = 1; }
  var pl = earnPlant(G.tut ? 'X' : G.w); if (pl) markPeak('plant-earned');
  if (G.daily) diary(pl ? pl.imageName : 'plant_dandelion', 'daily', 'Daily Bloom: ' + G.w);
  S.last = { word: G.w, wrong: G.wrong, helpers: G.helpers, plant: pl ? pl.imageName : null, rw: rw, daily: G.daily, tut: G.tut, cap: cap };
  progress(); cue2('success haptic', 'bloom chime'); celebrate('celebration', function () { S.screen = 'earned'; render(); });
}
function lose() {
  S.last = { word: G.w, wrong: G.wrong, daily: G.daily, loss: true }; S.hist.push(0); completeRound(G.daily); S.review.push({ w: G.w, due: dkey(now() + DAY) });
  G.stage = S.res.rose > 0 ? 'offer' : 'reveal'; G.rv = 0; S.screen = 'resting'; render(); if (G.stage === 'reveal') startReveal();
}
function startReveal() { G.stage = 'reveal'; G.rv = 0; render(); var n = G.w.length; clearInterval(G.iv); G.iv = setInterval(function () { G.rv++; var t = $('#rtiles'); if (t) t.innerHTML = revealTiles(); if (G.rv >= n) { clearInterval(G.iv); render(); } }, S.rm ? 20 : 260); }
function revealTiles() { return G.w.split('').map(function (c, i) { return '<div class="tile ' + (i < G.rv ? 'hit' : 'blank') + '">' + (i < G.rv ? c : '') + '</div>'; }).join(''); }
R.resting = function () {
  if (G.stage === 'offer') return '<div class="body" style="text-align:center"><div style="height:8px"></div><div class="fcont">' + flowerSVG(0, 'happy', true) + '</div><div style="font-weight:900;font-size:24px;margin-top:6px">This one\'s resting.</div><div class="fine" style="margin:6px 10px 16px">The petals are folded for a while. A Rose of Jericho can wake it up.</div><button class="btn rose" data-a="wake" style="width:100%"><img src="../rose_of_jericho.svg" alt=""><span>Wake it up<small>Brings 3 petals back. You have ' + S.res.rose + '.</small></span></button><div style="flex:1"></div><button class="btn secondary" data-a="reveal">Show me the word</button></div>';
  var done = G.rv >= G.w.length;
  return '<div class="body" style="text-align:center"><div style="height:6px"></div><div class="fcont" style="transform:scale(.8);margin-top:-14px">' + flowerSVG(0, 'happy', true) + '</div><div style="font-weight:900;font-size:22px;margin-top:-10px">This one\'s resting.</div><div style="color:var(--muted);font-size:15px;margin:4px 0 12px">Here\'s the word:</div><div class="tiles" id="rtiles">' + revealTiles() + '</div>' +
    (done ? '<div class="card" style="margin-top:14px;text-align:left"><div class="eyebrow">Hint</div><div style="font-size:15px;font-weight:600;margin:4px 0 8px">' + G.h + '</div><div class="eyebrow">Did you know?</div><div style="font-size:14px;line-height:1.4;margin-top:4px">' + safe(G.f) + '</div></div><div style="margin-top:10px"><button class="chipx" data-a="say">&#x1F50A; Say it</button></div><div class="fine" style="margin-top:8px">We will bring this word back tomorrow, so you can say hello again.</div>' : '') +
    '<div style="flex:1"></div>' + (done ? '<button class="btn primary" data-a="after" data-d="game">Next round</button><button class="lnk" data-a="after" data-d="home">Home</button>' : '') + '</div>';
};
R.earned = function () {
  var L = S.last, p = L.plant ? plantObj(L.plant) : null, wonder = p ? safe(WONDER[p.imageName] || p.botanicalFact) : '';
  var rewards = Q() ? '' : '<div style="display:flex;gap:8px;justify-content:center;flex-wrap:wrap"><span class="chip">&#x1F4A7; +' + L.rw.water + '</span>' + (L.rw.shed ? '<span class="chip acc">&#x2B50; +' + L.rw.shed + '</span>' : '') + (L.rw.scoop ? '<span class="chip">&#x1F331; +' + L.rw.scoop + '</span>' : '') + '</div>';
  var helper = L.helpers ? '<div class="fine" style="margin-bottom:6px">Bloomed with ' + L.helpers + ' helper' + (L.helpers > 1 ? 's' : '') + '</div>' : '';
  var btns = L.tut ? '<button class="btn primary" data-a="toGarden">See your garden</button>' : '<button class="btn primary" data-a="after" data-d="' + (L.daily ? 'home' : 'game') + '">' + (L.daily ? 'Done' : 'Next round') + '</button><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:46px;font-size:15px" data-a="shareWin">Share</button><button class="btn secondary" style="height:46px;font-size:15px" data-a="after" data-d="home">Home</button></div>';
  return '<div class="body" style="text-align:center"><div class="eyebrow" style="margin-top:8px">' + (p ? 'Plant earned' : 'You solved it') + '</div>' + (p ? '<div style="position:relative;margin:6px 0"><div style="position:absolute;inset:-20px 20px 10px;border-radius:50%;background:radial-gradient(closest-side,color-mix(in srgb,var(--accent) 35%,transparent),transparent)"></div>' + plantImg(p.imageName, 180, 'sway') + '</div><div style="font-weight:900;font-size:30px">' + p.name + '</div><div style="font-size:12px;color:var(--muted);font-style:italic">' + p.botanicalName + '</div><div class="card" style="margin:10px 0;text-align:left"><div class="eyebrow">Wonder</div><div style="font-size:15px;line-height:1.4;margin-top:4px">' + wonder + '</div></div>' : '<div style="font-size:60px;margin:20px">&#x1F33C;</div><div style="font-weight:900;font-size:26px">' + L.word + '</div><div class="fine" style="margin:8px 0">All plants of this level are already in your garden.</div>') + helper + rewards + '<div style="flex:1"></div><div style="display:grid;gap:10px;margin-top:12px">' + btns + '</div></div>';
};
R.rest = function () {
  return moodStrip() + '<div class="body" style="text-align:center;justify-content:center"><div class="fcont" style="margin:0 auto">' + flowerSVG(0, 'happy', true) + '</div><div style="font-weight:900;font-size:26px;margin-top:8px">The garden is resting</div><div style="color:var(--muted);font-size:14px;margin:6px 16px 22px">' + (S.restDaily ? 'Today\'s Daily Bloom is done. Take a moment, or keep going if you like.' : 'That was a good run. Do whatever feels right.') + '</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:12px"><button class="btn secondary" style="height:60px;font-size:16px" data-a="oneMore">One more</button><button class="btn secondary" style="height:60px;font-size:16px" data-a="enough">That\'s enough for now</button></div></div>';
};
/* --- garden --- */
R.garden = function () {
  var lv = S.viewLevel, tabs = [1, 2, 3, 4, 5].map(function (l) { var open = l <= S.wordUnlocked; return '<button class="chipx ' + (l === lv ? 'on' : '') + '" data-a="viewlevel" data-l="' + l + '" style="font-size:12px;' + (open ? '' : 'opacity:.5') + '">' + (open ? '' : '&#x1F512; ') + 'L' + l + '</button>'; }).join('');
  var ps = A.plants.filter(function (p) { return p.level === lv; }), first = Object.keys(S.plants)[0], tipOn = S.ftue === 'garden';
  var cells = ps.map(function (p) { var o = S.plants[p.imageName];
    return o ? '<button class="pc' + (tipOn && p.imageName === first ? ' tipped' : '') + '" data-a="plant" data-id="' + p.imageName + '">' + plantImg(p.imageName, 70) + '<div>' + pname(p.imageName) + '</div><div class="fine">Stage ' + o.stage + '</div></button>' : '<button class="pc lk" data-a="locked">' + plantImg(p.imageName, 70, 'sil') + '<div>???</div><div class="fine">Not found yet</div></button>'; }).join('');
  var btns = []; if (S.unl.badges || S.showAll) btns.push('<button class="btn secondary" style="height:46px;font-size:13px" data-a="badges">Badges</button>'); if (S.unl.net || S.showAll) { btns.push('<button class="btn secondary" style="height:46px;font-size:13px" data-a="album">Visitors</button>'); btns.push('<button class="btn secondary" style="height:46px;font-size:13px" data-a="bfIntro">Net game</button>'); } btns.push('<button class="btn secondary" style="height:46px;font-size:13px" data-a="diary">Diary</button>');
  return moodStrip() + '<div class="body">' + nav('My Garden', 'home', '<span class="chip acc">' + nPlants() + ' / 50</span>') + (tipOn ? '<div class="tipbub">&#x1F4A1; <b>Water your plant.</b> One free drop is ready. Tap your plant to begin.</div>' : '') + '<div style="display:flex;gap:6px;margin:4px 0 10px">' + tabs + '</div><div class="pg">' + cells + '</div><div style="flex:1"></div>' + (S.ftue === 'garden' ? '' : '<div style="display:grid;grid-template-columns:repeat(' + btns.length + ',1fr);gap:8px;margin-top:14px">' + btns.join('') + '</div>') + '</div>';
};
function thirsty(o) { return !calm() && !Q() && (now() - o.lastWater > 240000); }
function stageHTML(id) {
  var o = S.plants[id], w = [60, 96, 128, 158, 180][o.stage - 1], th = thirsty(o);
  var plant = o.stage === 1 ? '<svg class="pl" style="left:68px;width:44px" viewBox="0 0 60 70"><path d="M8 64 Q30 42 52 64Z" fill="#6B4A38"/><path d="M30 54 V32" stroke="#4E9A4C" stroke-width="4" stroke-linecap="round"/><ellipse cx="22" cy="32" rx="10" ry="6" transform="rotate(-25 22 32)" fill="#5FA860"/><ellipse cx="38" cy="30" rx="10" ry="6" transform="rotate(25 38 30)" fill="#3F8A4A"/></svg>' : '<img class="pl' + (th ? ' th' : '') + '" style="left:' + (90 - w / 2) + 'px;width:' + w + 'px" src="../plants/' + id + '.svg" alt="">';
  return plant + (th ? '<div class="dropb" aria-hidden="true">&#x1F4A7;</div>' : '');
}
R.plant = function () {
  var id = S.p.id, o = S.plants[id], pl = plantObj(id), nxt = STAGES[o.stage] === undefined ? null : STAGES[o.stage], prev = STAGES[o.stage - 1], pct = nxt ? Math.round((o.gp - prev) / (nxt - prev) * 100) : 100, th = thirsty(o), tmp = temperament(id), ft = S.ftue === 'garden';
  var tr = A.toolMeta.filter(function (t) { return S.tools[t.id]; }).map(function (t) { return '<button class="' + (S.hand === t.id ? 'act' : '') + '" data-a="hand" data-t="' + t.id + '" aria-label="' + A.vo[t.id][S.tier[t.id]] + '">' + A.tool[t.id][S.tier[t.id]] + '</button>'; }).join('');
  var hasMore = !ft;
  var bottom = ft ? (o.lastWater ? '<button class="btn primary" data-a="playAnother">Play another word</button>' : '<button class="btn primary" data-a="useTool">Use Watering can</button>') :
    '<div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-top:6px"><button class="btn primary" style="height:48px;font-size:15px;grid-column:span 3" data-a="useTool">Use ' + A.toolMeta.filter(function (t) { return t.id === S.hand; })[0].name + '</button>' + (S.unl.soil || S.showAll ? '<button class="btn secondary" style="height:44px;font-size:14px" data-a="repot">Repot</button>' : '') + (S.tools.shears ? '<button class="btn secondary" style="height:44px;font-size:14px" data-a="prune">Prune</button>' : '') + (S.unl.sun || S.showAll ? '<button class="btn secondary" style="height:44px;font-size:14px" data-a="sunspot">Sunny spot</button>' : '') + '</div>';
  return moodStrip() + '<div class="body">' + nav(pname(id), 'garden', resBar().replace(/<span class="chip">&#x1F331; \d+<\/span>/, '')) + '<div style="text-align:center;position:relative"><div class="st" id="stage" data-a="useTool"><div id="stageIn" style="position:relative;width:180px;height:180px">' + stageHTML(id) + '<div class="tl"></div><div class="fx"></div></div></div></div>' +
    '<div style="text-align:center;margin-top:-34px"><span class="mood ' + (th ? 'neutral' : 'happy') + '" id="mood">' + (th ? '&#x1F4A7; A little thirsty: perks right up with a drink' : '&#x263A; Happy') + '</span><div id="voice" class="voice"></div>' + (ft ? '' : '<div style="font-weight:800;margin-top:6px">Stage ' + o.stage + ' of 5 &middot; ' + STAGENAME[o.stage] + '</div>' + (Q() ? '' : '<div class="hbar" style="margin:6px 40px"><i style="width:' + pct + '%"></i></div><div class="fine">' + o.gp + ' growth points' + (nxt ? ' &middot; next stage at ' + nxt : ' &middot; fully grown') + '</div>')) +
    (ft ? '' : '<div class="fine" style="margin-top:4px"><b>' + TEMP[tmp][0] + '</b>: ' + TEMP[tmp][1] + ' &middot; <button class="lnk" style="padding:0" data-a="nameit">' + (o.nick ? 'Rename' : 'Name it') + '</button></div>') + '</div>' +
    (ft ? '<div class="tipbub" style="margin-top:12px">&#x1F4A1; ' + (o.lastWater ? 'Lovely! That is how you look after a plant.' : '<b>Tap the watering can, then the plant.</b> You have one drop ready.') + '</div><div class="tray">' + tr + '</div>' : '<div class="tray">' + tr + '</div>') + '<div style="flex:1"></div>' + bottom + '</div>';
};
function useTool(forceTool) {
  var id = S.p.id, o = S.plants[id], t = forceTool || S.hand, q = Q();
  if (t === 'net') { toast('The net is for catching visitors. Open Net game from the garden.'); return; }
  if (t === 'can') { if (!q) { if (S.res.water < 1) return needWater(); S.res.water--; } o.lastWater = now(); inc('water'); }
  else if (t === 'trowel') { if (!q) { if (S.res.scoop < 1) { toast('No soil scoops right now. Words and visitors bring more.'); return; } S.res.scoop--; } inc('feed'); }
  else if (t === 'shears') { if (!q && now() - o.pruneAt < 60000) { toast('Freshly trimmed. Come back a little later.'); return; } return openPrune(); }
  else if (t === 'mister') { if (!q && now() - o.mistAt < 20000) { toast('Still misty. Try again in a moment.'); return; } o.mistAt = now(); inc('mist'); }
  else if (t === 'lamp') { if (!q && now() - o.sunAt < 30000) { toast('Enjoying the sun. Try again soon.'); return; } o.sunAt = now(); inc('sun'); }
  var gp = { can: 4, trowel: 12, mister: 2, lamp: 2 + (S.tier.lamp - 1) }[t] * (t === 'trowel' ? [1, 1.25, 1.5][S.tier.trowel - 1] : 1); applyUse(t, q ? 0 : Math.round(gp));
}
function needWater() { modal('<div style="font-size:40px">&#x1F4A7;</div><div style="font-weight:900;font-size:22px;margin:6px 0">Out of drops for now</div><div class="fine" style="margin-bottom:14px">Play a word to earn more. Drops also trickle in over time.</div><button class="btn primary" data-a="ovplay">Play a word</button><button class="lnk" data-a="ovclose">Not now</button>'); }
function applyUse(t, gp) {
  var cls = FXH[t], st = $('#stage'), tl = st.querySelector('.tl'), fx = st.querySelector('.fx'), plantBox = $('#stageIn'); cue(t);
  var id = S.p.id, tm = temperament(id), line = (t === 'can' ? VOICE[tm].water : (t === 'lamp' ? VOICE[tm].sun : ''));
  var done = function () { var up = gp ? addGP(id, gp) : false; progress(); render(); if (line && !Q()) { var v = $('#voice'); if (v) v.textContent = plantObj(id).name === pname(id) ? '"' + line + '"' : pname(id) + ': "' + line + '"'; } toast(gp ? '+' + gp + ' growth' + (up ? ', stage up!' : '') : 'Tended with care'); setTimeout(flush, 600); };
  if (S.rm) { plantBox.classList.add('flash'); setTimeout(done, 350); return; }
  st.className = 'st ' + cls; tl.innerHTML = A.toolBare[t][S.tier[t]]; fx.innerHTML = FX[cls]; setTimeout(done, 2400);
}
function openPrune() {
  var done = 0, ends = [[60, 110], [150, 70], [240, 120]]; var stems = '<svg viewBox="0 0 300 300" style="width:100%"><path d="M96 262 H204 L192 296 H108Z" fill="#C98A4B"/><rect x="90" y="254" width="120" height="14" rx="6" fill="#B07A4B"/>';
  ends.forEach(function (e) { stems += '<path d="M150 260 C' + (150 + (e[0] - 150) * .3) + ' 210 ' + (e[0]) + ' 190 ' + e[0] + ' ' + e[1] + '" stroke="#4E9A4C" stroke-width="9" fill="none" stroke-linecap="round"/>'; });
  ends.forEach(function (e, i) { stems += '<g class="tip" data-a="snip" data-i="' + i + '" style="cursor:pointer"><ellipse cx="' + e[0] + '" cy="' + e[1] + '" rx="24" ry="14" fill="#6DB06A"/><circle cx="' + e[0] + '" cy="' + e[1] + '" r="32" fill="none" stroke="#F2B53E" stroke-width="3.5" stroke-dasharray="6 6"/></g>'; });
  modal('<div style="font-weight:900;font-size:20px">Prune</div><div class="fine">Tap each glowing stem to trim it. No timer.</div>' + stems + '</svg><div class="fine" id="pcount">0 of 3 trimmed</div><button class="lnk" data-a="ovclose">Skip, it is fine as it is</button>', true); S.pruneLeft = 3;
}
R.repot = function () {
  var id = S.p.id, idx = A.plants.map(function (p) { return p.imageName; }).indexOf(id), fav = SOILS[idx % 4][0];
  var cells = SOILS.map(function (s) { var c = SOILC[s[0]]; return '<button class="soil" data-a="soil" data-s="' + s[0] + '"><svg viewBox="0 0 78 60"><path d="M4 54 C4 30 24 8 40 8 C56 8 74 30 74 54Z" fill="' + c[0] + '"/><circle cx="24" cy="38" r="3" fill="' + c[1] + '"/><circle cx="40" cy="28" r="3" fill="' + c[1] + '"/><circle cx="52" cy="42" r="3" fill="' + c[1] + '"/></svg><b>' + s[1] + '</b><small>' + s[2] + (s[0] === fav ? ' &middot; &#x2605; ' + plantObj(id).name + ' likes this' : '') + '</small></button>'; }).join('');
  return '<div class="body">' + nav('Choose soil', 'plantback') + '<div style="text-align:center">' + plantImg(id, 110) + '</div><div class="fine" style="text-align:center;margin:4px 0 10px">Every soil works. Matching the favourite helps it grow faster.' + (Q() ? '' : ' Uses 1 soil scoop.') + '</div><div class="soils">' + cells + '</div></div>';
};
function doRepot(soil) {
  var id = S.p.id, idx = A.plants.map(function (p) { return p.imageName; }).indexOf(id), fav = SOILS[idx % 4][0], match = soil === fav, q = Q();
  if (!q && S.res.scoop < 1) { toast('No soil scoops right now. Words and visitors bring more.'); return; }
  if (!q) S.res.scoop--; S.plants[id].soil = soil; inc('repot'); if (match) inc('match'); var gp = q ? 0 : (match ? 15 : 5); if (gp) addGP(id, gp); diary(id, 'repot', pname(id) + ' moved into ' + soil + ' soil'); cue('trowel'); progress();
  modal('<div style="position:relative">' + plantImg(id, 160) + (match ? '<span class="sparkle" style="left:30px;top:10px">&#x2726;</span><span class="sparkle" style="right:30px;top:30px">&#x2726;</span>' : '') + '</div><div class="mood ' + (match ? 'happy' : 'neutral') + '" style="margin-top:8px">' + (match ? '&#x263A; Happy! ' + SOILS.filter(function (s) { return s[0] === soil; })[0][1] + ' suits ' + pname(id) : '&#x1F642; Settled in') + '</div><div style="font-weight:900;font-size:22px;margin:10px 0 4px">' + (match ? 'Grows faster now' : 'Growing at its own pace') + '</div><div class="fine" style="margin-bottom:6px">"' + VOICE[temperament(id)].repot + '"</div>' + (q ? '' : '<div class="fine" style="margin-bottom:10px">+' + gp + ' growth points</div>') + '<button class="btn primary" data-a="repotDone">Nice</button>', true);
}
/* --- shed --- */
R.shed = function () {
  var cells = A.toolMeta.map(function (t) { var own = S.tools[t.id], tr = S.tier[t.id];
    if (!own) return '<div class="tcard lk">' + A.tool[t.id][1] + '<b>' + t.name + '</b><span class="lockchip">&#x1F512; ' + UNL[t.id] + '</span></div>';
    var up = tr < 3 ? '<button class="mini sec" style="margin-top:6px" data-a="upgrade" data-t="' + t.id + '">Upgrade ' + (tr === 1 ? 30 : 120) + ' pts</button>' : '<div class="fine" style="margin-top:6px">Top tier</div>';
    return '<div class="tcard ' + (S.hand === t.id ? 'act' : '') + '" aria-label="' + A.vo[t.id][tr] + '">' + A.tool[t.id][tr] + '<b>' + t.name + '</b><small>Tier ' + tr + ' of 3. ' + t.desc.split(',')[0] + '</small><button class="mini ' + (S.hand === t.id ? '' : 'sec') + '" data-a="hand" data-t="' + t.id + '">' + (S.hand === t.id ? 'In hand' : 'Pick up') + '</button>' + up + '</div>'; }).join('');
  return '<div class="body">' + nav('Garden Shed', 'home', Q() ? '' : '<span class="chip acc">&#x2B50; ' + S.res.shed + '</span>') + '<div class="fine" style="margin:0 4px 8px">New tools arrive as your garden grows and are never bought. Upgrades use shed points.</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">' + cells + '</div></div>';
};
/* --- level map: two tracks --- */
R.map = function () {
  var rows = [5, 4, 3, 2, 1].map(function (l) {
    var ps = A.plants.filter(function (p) { return p.level === l; }), w = ps.filter(function (p) { return S.plants[p.imageName]; }).length, g = ps.filter(function (p) { return S.plants[p.imageName] && S.plants[p.imageName].stage >= 4; }).length, open = l <= S.wordUnlocked, cur = l === S.wordPick;
    return '<button class="card" data-a="pickword" data-l="' + l + '" style="width:100%;border:0;color:inherit;display:block;margin-bottom:10px;text-align:left;' + (open ? '' : 'opacity:.55') + '"><div style="display:flex;align-items:center;gap:12px"><div style="width:44px;height:44px;border-radius:50%;background:' + (cur ? 'var(--accent)' : 'var(--line)') + ';color:' + (cur ? 'var(--accent-ink)' : 'var(--text)') + ';display:grid;place-items:center;font-weight:900;font-size:18px">' + (open ? l : '&#x1F512;') + '</div><div style="flex:1"><b>Level ' + l + '</b>' + (cur ? ' <span class="tag" style="background:var(--accent);color:var(--accent-ink)">playing</span>' : '') + '</div></div>' +
      '<div class="fine" style="margin-top:8px">Word track: ' + w + ' of 10 plants earned</div><div class="hbar" style="margin:3px 0 6px"><i style="width:' + w * 10 + '%"></i></div><div class="fine">Garden track: ' + g + ' of 10 in bloom' + (S.gardenDone[l] ? ' &middot; flourishing' : '') + '</div><div class="hbar" style="margin-top:3px"><i style="width:' + g * 10 + '%;background:var(--accent)"></i></div></button>'; }).join('');
  return '<div class="body">' + nav('Level Map', 'home') + '<div class="fine" style="margin:0 4px 10px"><b>Word track</b> opens the next level when you have earned all 10 plants. <b>Garden track</b> celebrates when all 10 are in bloom, and never holds back the words. Tap an open level to play its words.</div>' + rows + '</div>';
};
/* --- settings --- */
function sw(k) { return '<span class="sw2 ' + (S.set[k] ? 'on' : '') + '" data-a="setting" data-k="' + k + '" role="switch"></span>'; }
R.settings = function () {
  var done = S.ftue === 'done', ic = 'data:image/svg+xml;utf8,' + encodeURIComponent(A.icon);
  var plus = !done ? '' : (S.plus ? '<div class="cap2">Plus</div><div class="grp"><div class="row"><img src="' + ic + '" width="36" style="border-radius:9px"><div><b>WordFlora Plus</b><div class="sub">' + (S.plan === 'y' ? 'Yearly &middot; renews Nov 5, 2027 at $12.99' : 'Monthly &middot; renews Dec 2, 2026 at $3.99') + '</div></div><span class="pill">Active</span></div><div class="row"><span>No ads</span><span class="chev">On</span></div><div class="row"><span>iCloud sync</span><span class="chev">Synced just now</span></div><div class="row" data-a="toast" data-t="Opens the system subscription page"><span>Manage subscription</span><span class="chev">&#x203A;</span></div></div>'
    : '<div class="cap2">Plus</div><div class="grp"><div class="row" data-a="paywall" data-back="settings"><img src="' + ic + '" width="36" style="border-radius:9px"><div><b>WordFlora Plus</b><div class="sub">No ads and iCloud sync. From $1.08 a month.</div></div><span class="chev">&#x203A;</span></div></div>');
  var diffs = ['auto', 'gentle', 'standard', 'tricky'].map(function (d) { return '<button class="mini ' + (S.set.diff === d ? '' : 'sec') + '" data-a="diff" data-d="' + d + '" style="flex:1;padding:0 2px;font-size:11.5px">' + d.charAt(0).toUpperCase() + d.slice(1) + '</button>'; }).join('');
  return '<div class="body">' + nav('Settings', 'home') + plus + '<div class="cap2">Play</div><div class="grp"><div class="row"><div>Word difficulty<div class="sub">' + (S.set.diff === 'auto' ? 'Auto (now ' + (S.autoNow || (S.young ? 'gentle' : 'standard')) + ')' : S.set.diff) + '. Never changes rewards.</div></div></div><div class="row" style="gap:5px">' + diffs + '</div><div class="row"><span>Sound</span>' + sw('sound') + '</div><div class="row"><span>Haptics</span>' + sw('haptics') + '</div><div class="row"><span>Reduce Motion</span><span class="sw2 ' + (S.rm ? 'on' : '') + '" data-a="rm"></span></div><div class="row"><div>Remind me<div class="sub">One gentle nudge a day</div></div>' + sw('remind') + '</div></div>' +
    '<div class="cap2">Calm and quiet</div><div class="grp"><div class="row"><div>Show streak<div class="sub">Garden Days always count</div></div>' + sw('streak') + '</div><div class="row"><div>Calm mode<div class="sub">Gentler visuals' + (S.young ? ' (on for under 13)' : '') + '</div></div>' + (S.young ? '<span class="sw2 on"></span>' : sw('calm')) + '</div><div class="row"><div>Quiet Garden<div class="sub">Hides counters, tending is unlimited and earns nothing</div></div>' + sw('quiet') + '</div></div>' +
    '<div class="cap2">Appearance</div><div class="grp"><div class="row" style="gap:6px">' + ['system', 'light', 'dark'].map(function (t) { return '<button class="mini ' + (S.set.theme === t && !S.theme ? '' : 'sec') + '" data-a="theme" data-t="' + t + '" style="flex:1">' + t.charAt(0).toUpperCase() + t.slice(1) + '</button>'; }).join('') + '</div></div>' +
    '<div class="cap2">Help</div><div class="grp"><div class="row" data-a="howto"><span>How to play</span><span class="chev">&#x203A;</span></div><div class="row"><div>Show everything<div class="sub">Opens every part of the app now</div></div><span class="sw2 ' + (S.showAll ? 'on' : '') + '" data-a="showall"></span></div></div>' +
    (done ? '<div class="cap2">Purchases</div><div class="grp"><div class="row" data-a="toast" data-t="Prototype: nothing to restore"><span>Restore Purchases</span><span class="chev">&#x203A;</span></div></div>' : '') +
    '<div class="cap2">Prototype helpers</div><div class="grp"><div class="row" data-a="helper" data-h="tools"><span>Unlock all tools</span></div><div class="row" data-a="helper" data-h="res"><span>Add drops, scoops and shed points</span></div><div class="row" data-a="helper" data-h="plants"><span>Earn 3 plants instantly</span></div><div class="row" data-a="helper" data-h="wlevel"><span>Finish current word level</span></div><div class="row" data-a="helper" data-h="glevel"><span>Finish current garden level</span></div></div></div>';
};
/* --- paywall / gate / ad --- */
R.gate = function () {
  var d = S.gateIn || '';
  return '<div class="body" style="text-align:center"><div style="height:20px"></div><div style="font-size:50px">&#x1F9D1;&#x200D;&#x1F33E;</div><div style="font-weight:900;font-size:26px;margin:8px 0">Ask a grown-up</div><div style="color:var(--muted);font-size:15px;line-height:1.4">Purchases and links are for grown-ups. To continue, type these numbers:</div><div style="font-size:30px;font-weight:900;margin:14px 0 6px">eight &middot; three</div><div class="tiles" style="margin:6px 0">' + [0, 1].map(function (i) { return '<span class="tile ' + (d[i] ? 'hit' : 'blank') + '">' + (d[i] || '') + '</span>'; }).join('') + '</div><div class="kbn">' + '123456789'.split('').concat(['', '0', 'x']).map(function (k) { return k === '' ? '<span></span>' : '<button data-a="gkey" data-k="' + k + '">' + (k === 'x' ? '&#x232B;' : k) + '</button>'; }).join('') + '</div><button class="btn secondary" style="margin-top:14px;height:46px" data-a="home">Go back to the game</button></div>';
};
R.paywall = function () {
  var y = S.plan === 'y', ic = 'data:image/svg+xml;utf8,' + encodeURIComponent(A.icon);
  var terms = y ? '<b>Free for 3 days, then $12.99 per year.</b> You will not be charged today. First charge: <b>$12.99 on Nov 5, 2026</b>. Renews every year at $12.99 until you cancel. Cancel any time in Settings &gt; your name &gt; Subscriptions, at least 24 hours before a renewal.' : '<b>$3.99 charged today (Nov 2, 2026)</b> and renews every month at $3.99 until you cancel. No free trial on the monthly plan. Cancel any time in Settings &gt; your name &gt; Subscriptions, at least 24 hours before a renewal.';
  return '<div class="body"><div style="display:flex;justify-content:space-between;align-items:center"><button class="xbtn" data-a="payback" aria-label="Close">&#x2715;</button><span class="fine">Optional. The game stays free.</span></div><div style="text-align:center;margin:4px 0 8px"><img src="' + ic + '" width="58" style="border-radius:13px"><div style="font-weight:900;font-size:24px;margin-top:4px">WordFlora Plus</div></div>' +
    '<div style="display:flex;gap:10px;font-size:14px;margin-bottom:6px"><span>&#x1F6AB;</span><div><b>No ads</b><div class="fine">No quick-break ads between rounds.</div></div></div><div style="display:flex;gap:10px;font-size:14px;margin-bottom:10px"><span>&#x2601;&#xFE0F;</span><div><b>iCloud sync</b><div class="fine">Your garden follows you across devices.</div></div></div>' +
    '<div class="plan ' + (y ? 'sel' : '') + '" data-a="plan" data-p="y"><div class="radio"></div><div><div class="n">Yearly<span class="tag">3 days free</span></div><div class="d">$1.08 a month. Saves 73% vs paying monthly ($47.88).</div></div><div class="p">$12.99<small>per year</small></div></div><div class="plan ' + (!y ? 'sel' : '') + '" data-a="plan" data-p="m"><div class="radio"></div><div><div class="n">Monthly</div><div class="d">No free trial</div></div><div class="p">$3.99<small>per month</small></div></div>' +
    '<button class="btn primary" data-a="subscribe" style="height:52px">' + (y ? 'Start 3-day free trial' : 'Subscribe for $3.99 a month') + '</button><div class="fine" style="margin-top:8px">' + terms + ' Payment is charged to your Apple Account. Everything you earned stays yours either way. Prototype: no real purchase.</div><div style="display:flex;flex-wrap:wrap;gap:4px 14px;justify-content:center;font-size:12px;font-weight:700;margin-top:6px"><a data-a="toast" data-t="Prototype: nothing to restore" style="text-decoration:underline;cursor:pointer">Restore Purchases</a><a data-a="toast" data-t="Opens the system subscription page" style="text-decoration:underline;cursor:pointer">Manage Subscriptions</a><a data-a="toast" data-t="Terms of Use" style="text-decoration:underline;cursor:pointer">Terms of Use</a><a data-a="toast" data-t="Privacy Policy" style="text-decoration:underline;cursor:pointer">Privacy Policy</a></div></div>';
};
R.ad = function () { return '<div class="body"><div style="display:flex;justify-content:space-between;align-items:center"><span class="eyebrow">Quick break</span><button class="xbtn" data-a="adclose" aria-label="Close ad">&#x2715;</button></div><div style="text-align:center;margin:12px 0"><div style="font-weight:900;font-size:24px">Thanks for sticking around</div><div style="color:var(--muted);font-size:14px">A short pause, then your next word.</div></div><div class="adslot"><span class="adlabel">Ad</span>Ad slot</div><div style="display:flex;justify-content:space-between;margin:6px 4px"><button class="lnk" data-a="toast" data-t="Thanks, ad reported (prototype)">Report ad</button><button class="lnk" data-a="adfree">Go ad-free</button></div><div style="flex:1"></div><button class="btn primary" data-a="adclose">Next round</button></div>'; };
/* --- badges / album / diary --- */
R.badges = function () {
  var n = Object.keys(S.badges).length, cells = A.badgeMeta.map(function (b) { var t = S.badges[b.id]; return '<button class="' + (t ? '' : 'lk') + '" data-a="badge" data-id="' + b.id + '">' + (t ? A.badge[b.id][t] : A.badge[b.id].lock) + b.title + '</button>'; }).join('');
  return '<div class="body">' + nav('Badges', 'garden', Q() ? '' : '<span class="chip acc">' + n + ' / 36</span>') + '<div class="fine" style="margin:0 4px 10px">Badges are always yours to keep. Tap one to see more.</div><div class="bshelf">' + cells + '</div></div>';
};
function badgeCard(id) {
  var b = A.badgeMeta.filter(function (x) { return x.id === id; })[0], t = S.badges[id] || 0, v = bval(id), nxt = b.th[t] || null;
  modal('<div class="medal" style="animation:none;width:130px">' + (t ? A.badge[id][t] : A.badge[id].lock) + '</div><div style="font-weight:900;font-size:22px;margin-top:6px">' + b.title + '</div><div class="fine">' + b.desc + '</div>' + (Q() ? '' : '<div style="margin:10px 0">' + [1, 2, 3].map(function (i) { return '<span class="chipx" style="margin:2px;' + (t >= i ? 'background:var(--accent);color:var(--accent-ink)' : '') + '">' + ['', 'Bronze', 'Silver', 'Gold'][i] + ' ' + b.th[i - 1] + '</span>'; }).join('') + '</div><div class="fine">Progress: ' + v + (nxt ? ' / ' + nxt + ' ' + b.unit : ' (all tiers done)') + '</div>') + (t ? '<button class="btn secondary" style="height:44px;margin-top:12px" data-a="shareBadge" data-id="' + id + '" data-t="' + t + '">Share badge</button>' : '') + '<button class="lnk" data-a="ovclose">Close</button>');
}
R.album = function () {
  var n = Object.keys(S.stickers).length, cells = A.species.map(function (s) { var c = S.stickers[s.id], ev = s.night;
    return '<div class="c ' + (c ? '' : 'lock') + '" data-a="species" data-id="' + s.id + '">' + A.stk[s.id] + '<div>' + (c ? s.name : (ev ? 'Evening visitor' : '???')) + '</div><small>' + (c ? s.rarity + ' &middot; x' + c : (ev ? 'Comes out in the evening' : s.rarity)) + '</small></div>'; }).join('');
  return '<div class="body">' + nav('Garden Visitors', 'garden', '<span class="chip acc">' + n + ' / 12</span>') + (S.lantern ? '<div class="card" style="display:flex;gap:10px;align-items:center;padding:8px 12px;margin-bottom:8px"><div style="width:40px">' + A.lantern + '</div><div style="flex:1;font-size:12px"><b>Glow Lantern x' + S.lantern + '</b><br><span class="fine">Meet evening visitors any time, for one play.</span></div></div>' : '') + '<div class="album">' + cells + '</div></div>';
};
R.diary = function () {
  var rows = S.diary.length ? S.diary.map(function (d) { var pl = A.plants.filter(function (p) { return p.imageName === d.id; })[0]; return '<div class="card" style="display:flex;gap:12px;align-items:center;margin-bottom:8px;padding:10px 12px"><div style="width:48px;height:48px;border-radius:12px;background:color-mix(in srgb,var(--accent) 14%,var(--surface));display:grid;place-items:center">' + (pl ? plantImg(d.id, 42) : '') + '</div><div style="flex:1"><div style="font-size:14px;font-weight:700">' + d.text + '</div><div class="fine">' + d.at + ' &middot; ' + d.season + '</div></div></div>'; }).join('') : '<div class="fine" style="text-align:center;margin-top:30px">Your garden diary fills itself as plants grow.</div>';
  return '<div class="body">' + nav('Garden Diary', 'garden') + '<div class="fine" style="margin:0 4px 10px">Little memories, kept for you. Nothing here is ever removed.</div>' + rows + '</div>';
};
/* --- butterfly --- */
R.bfIntro = function () {
  var left = Math.max(0, 3 - S.bfPlays), eve = dusk();
  return '<div class="body">' + nav('Net game', 'garden') + '<div style="text-align:center;margin-top:10px"><div style="font-size:50px">&#x1F98B;</div><div style="font-weight:900;font-size:26px;margin:4px 0">Garden Visitors</div><div style="color:var(--muted);font-size:14px;line-height:1.45;margin:0 8px">Butterflies, bees and ladybugs are visiting. ' + (S.rm ? 'Tap a visitor resting on a flower to say hello.' : 'Swipe with your net to say hello.') + ' About 35 seconds. Any swipe is fine, and nothing bad can happen.</div></div>' +
    '<div class="card" style="margin:16px 0;font-size:13px">' + (eve ? '&#x1F319; It is evening: fireflies and moths are out.' : 'Evening visitors come out 17:30 to 21:30.') + (!eve && S.lantern ? '<div style="margin-top:8px"><button class="mini sec" data-a="lantern">Use Glow Lantern (x' + S.lantern + ')</button></div>' : '') + '</div>' + (Q() ? '' : '<div class="fine" style="text-align:center">Rewarded plays today: ' + left + ' of 3. Extra plays are just for fun.</div>') + '<div style="flex:1"></div><button class="btn primary" data-a="bfStart">Start</button></div>';
};
var BF = null, bfRaf = null;
R.bf = function () { return '<div class="body" style="padding:0"><div class="hud"><span class="chip" id="bfc">&#x1F98B; 0</span><div class="bar2"><i id="bft" style="width:100%"></i></div><button class="chip" data-a="bfEnd" style="border:0">Done</button></div><div class="scene ' + BF.tone + '" id="scene"><div class="hill" style="position:absolute;left:-10%;right:-10%;bottom:0;height:42%;border-radius:50% 50% 0 0/22% 22% 0 0"></div>' +
  ['daisy', 'tulip', 'sunflower', 'poppy'].map(function (n, i) { return '<img src="../plants/plant_' + n + '.svg" style="position:absolute;bottom:34px;left:' + (14 + i * 92) + 'px;width:76px" alt="">'; }).join('') + '<svg class="trail" id="trail" viewBox="0 0 390 794"></svg></div></div>'; };
function spawnList() { var night = dusk() || BF.lantern, dayL = ['monarch', 'swallowtail', 'cabbagewhite', 'paintedlady', 'honeybee', 'bumblebee', 'ladybug', 'dragonfly', 'morpho', 'hummingbird'], nightL = ['firefly', 'luna']; var pool = []; if (!dusk()) pool = pool.concat(dayL, dayL.slice(0, 6)); if (night) pool = pool.concat(nightL, nightL); return pool; }
function bfStartGame() {
  BF = { t: 0, dur: 35, catches: 0, newOnes: [], list: [], tone: dusk() ? 'dusk' : 'day', lantern: !!S.lanternActive, got: [], rewarded: S.bfPlays < 3 }; S.screen = 'bf'; render();
  var sc = $('#scene'), pool = spawnList(), W = 390;
  function addV(id, x, y) { var d = document.createElement('div'); d.className = 'v'; d.innerHTML = '<div class="fl2"><div class="a">' + A.vis[id].a + '</div><div class="b">' + A.vis[id].b + '</div></div>'; sc.appendChild(d); return { id: id, el: d, x: x, y: y, vx: (Math.random() * 40 + 25) * (Math.random() < .5 ? -1 : 1), ph: Math.random() * 6, amp: Math.random() * 30 + 15, base: y }; }
  function newVisitor() { var id = pool[Math.floor(Math.random() * pool.length)]; if (S.rm) { var spots = [[200, 430], [22, 500], [300, 540], [110, 470], [250, 380]], s = spots[Math.floor(Math.random() * spots.length)], v = addV(id, s[0], s[1]); v.vx = 0; v.rest = true; var r = document.createElement('div'); r.className = 'ring'; r.style.cssText = 'left:' + (s[0] - 6) + 'px;top:' + (s[1] - 6) + 'px;width:68px;height:68px'; sc.appendChild(r); v.ring = r; return v; } return addV(id, Math.random() < .5 ? -60 : W + 10, 120 + Math.random() * 380); }
  var n = S.rm ? 4 : 7; for (var i = 0; i < n; i++) { var v = newVisitor(); if (!S.rm) v.x = Math.random() * W; BF.list.push(v); }
  function catchV(v) {
    var id = v.id, sp = A.species.filter(function (s) { return s.id === id; })[0], isNew = !S.stickers[id]; S.stickers[id] = (S.stickers[id] || 0) + 1; BF.catches++; BF.got.push(id); if (isNew) { BF.newOnes.push(id); markPeak('new visitor'); diary('plant_daisy', 'visitor', 'A ' + sp.name.toLowerCase() + ' visited the garden'); }
    inc('catch'); if (sp.night) inc('night'); if (sp.rarity === 'rare' && isNew) inc('rare'); if (id === 'honeybee' || id === 'bumblebee') inc('bee');
    var pop = document.createElement('div'); pop.className = 'pop'; pop.style.left = (v.x - 25) + 'px'; pop.style.top = (v.y - 40) + 'px'; pop.innerHTML = A.stk[id]; sc.appendChild(pop); setTimeout(function () { pop.remove(); }, 1100);
    v.el.remove(); if (v.ring) v.ring.remove(); BF.list.splice(BF.list.indexOf(v), 1); $('#bfc').innerHTML = '&#x1F98B; ' + BF.catches; cue('net'); setTimeout(function () { if (BF && S.screen === 'bf') BF.list.push(newVisitor()); }, 900);
  }
  function hit(x, y, rad) { BF.list.slice().forEach(function (v) { if (Math.hypot(v.x + 28 - x, v.y + 28 - y) < rad) catchV(v); }); }
  var down = false, last = null, tr = $('#trail');
  function pos(e) { var r = sc.getBoundingClientRect(), k = 390 / r.width; return [(e.clientX - r.left) * k, (e.clientY - r.top) * k]; }
  sc.onpointerdown = function (e) { down = true; var p = pos(e); last = p; hit(p[0], p[1], S.rm ? 46 : 36 + S.tier.net * 8); };
  sc.onpointermove = function (e) { if (!down || S.rm) return; var p = pos(e), path = document.createElementNS('http://www.w3.org/2000/svg', 'path'); path.setAttribute('d', 'M' + last[0] + ' ' + last[1] + ' L' + p[0] + ' ' + p[1]); tr.appendChild(path); setTimeout(function () { path.remove(); }, 400); last = p; hit(p[0], p[1], 36 + S.tier.net * 8); };
  window.addEventListener('pointerup', function up() { down = false; window.removeEventListener('pointerup', up); });
  BF.hit = hit; BF.catchV = catchV;
  var t0 = null, lastT = null;
  function tick(ts) {
    if (!BF || S.screen !== 'bf') return; if (t0 == null) { t0 = ts; lastT = ts; } var dt = (ts - lastT) / 1000; lastT = ts; BF.t += dt;
    BF.list.forEach(function (v) { if (!v.rest) { v.x += v.vx * dt; v.y = v.base + Math.sin(BF.t * 1.3 + v.ph) * v.amp; if (v.x < -80 || v.x > 470) v.vx = -v.vx; } v.el.style.transform = 'translate(' + v.x + 'px,' + v.y + 'px)'; v.el.style.left = 0; v.el.style.top = 0; });
    var tb = $('#bft'); if (tb) tb.style.width = Math.max(0, 100 - BF.t / BF.dur * 100) + '%'; if (BF.t >= BF.dur) { bfFinish(); return; } bfRaf = requestAnimationFrame(tick);
  }
  cancelAnimationFrame(bfRaf); bfRaf = requestAnimationFrame(tick); BF.list.forEach(function (v) { v.el.style.transform = 'translate(' + v.x + 'px,' + v.y + 'px)'; });
}
function bfFinish() {
  cancelAnimationFrame(bfRaf); if (!BF) return; var rw = { water: 0, shed: 0, scoop: 0 };
  if (BF.rewarded && !Q()) { rw.water = 1 + Math.min(BF.catches, 3); rw.shed = 2; if (Math.random() < .3) rw.scoop = 1; S.res.water = Math.min(40, S.res.water + rw.water); S.res.shed += rw.shed; S.res.scoop += rw.scoop; }
  if (BF.rewarded) S.bfPlays++; if (!S.lantern && !S.tips.lantern) { S.tips.lantern = true; S.lantern = 1; queue.push({ type: 'tip', key: 'lanternTip', t: 'A Glow Lantern', b: 'You found a Glow Lantern. Use it from the net game to meet evening visitors at any hour.' }); }
  S.lanternActive = false; S.lastBF = { catches: BF.catches, newOnes: BF.newOnes.slice(), got: BF.got.slice(), rw: rw, rewarded: BF.rewarded }; progress(); S.screen = 'bfSum'; render();
}
R.bfSum = function () {
  var L = S.lastBF, st = L.got.slice(0, 6).map(function (id) { return '<div style="width:62px">' + A.stk[id] + '</div>'; }).join('');
  return '<div class="body" style="text-align:center"><div style="height:24px"></div><div style="font-size:44px">&#x1F33C;</div><div style="font-weight:900;font-size:26px">Nice visiting!</div><div style="color:var(--muted);font-size:14px;margin:4px 0 14px">' + (L.catches ? 'You said hello to ' + L.catches + ' visitor' + (L.catches > 1 ? 's' : '') : 'A quiet garden this time, and that is lovely too') + '</div><div style="display:flex;gap:6px;justify-content:center;flex-wrap:wrap">' + st + '</div>' +
    '<div class="card" style="margin-top:16px;text-align:left"><div class="eyebrow">Gifts from the garden</div><div style="display:grid;gap:6px;margin-top:8px;font-size:14px">' + (L.rewarded && !Q() ? '<div>&#x1F4A7; +' + L.rw.water + ' water drops</div><div>&#x2B50; +' + L.rw.shed + ' shed points</div>' + (L.rw.scoop ? '<div>&#x1F331; +1 soil scoop</div>' : '') : '<div>Just for fun, with no gifts this time.</div>') + (L.newOnes.length ? '<div>&#x1F4D2; New stickers: ' + L.newOnes.map(function (id) { return A.species.filter(function (s) { return s.id === id; })[0].name; }).join(', ') + '</div>' : '') + '</div></div><div style="flex:1"></div><button class="btn primary" data-a="bfIntro">Play again</button><button class="btn secondary" style="height:46px;margin-top:10px" data-a="album">Open album</button><button class="lnk" data-a="garden">Done</button></div>';
};
/* ---------- ad logic ---------- */
function adCheck() {
  var r = [], t = now(), peakAge = (t - S.peakAt) / 1000;
  if (S.young) r.push('Under 13: no ads at all'); if (S.plus) r.push('Plus: no ads'); if (S.ftue !== 'done') r.push('Session 1: no ads');
  if (!S.adDue) r.push('Not due yet (every 3rd round)'); if (S.restDaily) r.push('Never around the Daily Bloom');
  if (!(S.wlUps >= 1 || S.rounds >= 9 || S.graceOff)) r.push('Grace period (until first level-up)');
  if (S.peakAt && peakAge < 120) r.push('Peak: ' + S.peakKind + ' ' + Math.round(peakAge) + ' s ago (needs 120 s)');
  if (t < S.quietUntil) r.push('Ceremony quiet window (60 s)'); if (S.lastAdAt && t - S.lastAdAt < 180000) r.push('Under 3 min since last ad'); if (S.adsToday >= 6) r.push('6 ads today');
  return r;
}
function logicHTML() {
  var r = adCheck(), age = S.peakAt ? Math.round((now() - S.peakAt) / 1000) : null;
  return '<b>Ad logic</b><br>Profile: ' + (S.young ? 'Under 13' : (S.plus ? 'Plus' : 'Free')) + (S.ftue !== 'done' ? ' (session 1)' : '') + '<br>Rounds this sitting: ' + S.sinceRest + ' / 3 &middot; ad due: ' + (S.adDue ? 'yes' : 'no') + '<br>Last peak: ' + (S.peakKind ? S.peakKind + ', ' + age + ' s ago' : 'none') + '<br>Shown only after "One more", and never within 120 s of a peak.<br><b>Would an ad show now?</b> ' + (r.length ? '<span style="color:var(--danger)">No</span><ul>' + r.map(function (x) { return '<li>' + x + '</li>'; }).join('') + '</ul>' : '<span style="color:var(--success)">Yes</span>') + '<button class="mini sec" data-a="graceoff" style="margin-top:6px">' + (S.graceOff ? 'Grace period skipped' : 'Skip grace period') + '</button>';
}
/* ---------- router ---------- */
function maybeBreak() {
  if (S.young && S.playMin >= 20 && !modalOpen()) { S.playMin = 0; modal('<div style="font-size:40px">&#x1F33F;</div><div style="font-weight:900;font-size:22px;margin:6px 0">Time for a stretch?</div><div class="fine" style="margin-bottom:14px">You have been playing for 20 minutes. Maybe look out of a window for a moment, then come back any time.</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:52px;font-size:15px" data-a="takebreak">Take a break</button><button class="btn secondary" style="height:52px;font-size:15px" data-a="ovclose">A little more</button></div>'); }
}
function showWelcome() {
  var w = S.welcome; S.welcome = null; var first = Object.keys(S.plants)[0], parts = [];
  if (first) parts.push('your ' + pname(first) + ' grew a little'); if (Object.keys(S.stickers).length) parts.push('a ' + A.species.filter(function (s) { return S.stickers[s.id]; })[0].name.toLowerCase() + ' visited'); parts.push('the garden had some rain');
  var long = w.days >= 30;
  modal('<div style="font-size:40px">&#x1F33C;</div><div style="font-weight:900;font-size:24px;margin:6px 0">Welcome back</div><div style="font-size:15px;line-height:1.5;color:var(--muted);margin-bottom:' + (long ? 8 : 16) + 'px">While you were away: ' + parts.join(', ') + '.</div>' + (long ? '<div class="fine" style="margin-bottom:14px">Your garden diary has ' + S.diary.length + ' pages of memories.</div>' : '') + '<div style="display:grid;gap:10px"><button class="btn primary" style="height:50px" data-a="ovclose">Let\'s play</button>' + (long ? '<button class="btn secondary" style="height:46px" data-a="tour">Take a gentle tour</button>' : '') + '</div>');
}
function render() {
  var fn = R[S.screen] || R.home; $('#screen').innerHTML = (S.screen === 'bf' || S.screen === 'home' || S.screen === 'garden' || S.screen === 'plant' || S.screen === 'rest' ? '' : '') + status() + fn(); applyTheme();
  var mv = $('#screen > .mood-strip'); if (mv) { mv.style.top = '0'; }
  if (S.screen === 'intro') startIntro();
  $('#logic').innerHTML = logicHTML(); save();
  if (S.screen === 'home' && !modalOpen()) { if (S.welcome) showWelcome(); else maybeBreak(); } else if (S.screen === 'rest') maybeBreak();
  flush();
}
function go(s, p) { cancelAnimationFrame(bfRaf); if (G && G.iv) clearInterval(G.iv); S.screen = s; if (p) S.p = p; render(); }
var introRaf = null;
function startIntro() {
  var r = FR.create({ variant: 'standard', reduce: !!S.rm, seed: 7, calm: calm() }), cv = $('#rainCv'), cx = cv.getContext('2d'); cx.setTransform(2, 0, 0, 2, 0, 0); var t0 = null; cancelAnimationFrame(introRaf);
  function f(ts) { if (S.screen !== 'intro') { cx.clearRect(0, 0, 390, 844); return; } if (t0 == null) t0 = ts; var t = Math.min((ts - t0) / 1000, r.duration); cx.clearRect(0, 0, 390, 844); r.draw(cx, t, themeNow()); var w = $('#introWm'); if (w) { w.style.opacity = r.wordmarkOpacity(t); w.style.transform = 'translateY(' + r.wordmarkRise(t) + 'px)'; } if (t >= r.duration) { setTimeout(function () { if (S.screen === 'intro') introDone(); }, 900); return; } introRaf = requestAnimationFrame(f); }
  introRaf = requestAnimationFrame(f);
}
function introDone() { cancelAnimationFrame(introRaf); $('#rainCv').getContext('2d').clearRect(0, 0, 780, 1688); if (S.ftue === 'intro') { S.ftue = 'age'; go('age'); } else go('home'); }
function after(dest) {
  progress();
  pending = function () {
    if (S.last && S.last.daily) goRest(true); else if (S.sinceRest >= 3) goRest(false); else if (dest === 'game') startRound(false); else go('home');
  }; releasing = true; flush();
}
function goRest(daily) { S.restDaily = !!daily; if (!daily) { S.adDue = true; } S.sinceRest = 0; go('rest'); }
function oneMore() {
  if (S.young || S.plus || S.ftue !== 'done') { startRound(false); return; }
  if (adCheck().length === 0) { S.adDue = false; S.lastAdAt = now(); S.adsToday++; var next = function () { go('ad'); }; if (!S.umpDone) { S.umpDone = true; modal('<div class="eyebrow">System prompt would appear here</div><div style="font-weight:900;font-size:20px;margin:8px 0">Privacy choices, then tracking</div><div class="fine" style="margin-bottom:14px">The consent form (UMP) and the iOS tracking prompt (ATT) are shown once, right before the very first ad request, never earlier.</div><button class="btn primary" data-a="umpgo">Continue</button>', true); S.umpNext = next; return; } next(); } else startRound(false);
}
function share(title, sub, svg) { modal('<div class="shcard" style="border-radius:22px;padding:22px;background:var(--bg);border:1px solid var(--line)"><div style="display:flex;justify-content:space-between;font-size:11px;font-weight:800;letter-spacing:.08em;color:var(--muted)"><span>WORDFLORA</span><span>SHARE</span></div><div style="width:170px;margin:16px auto 8px">' + svg + '</div><div style="font-weight:900;font-size:24px">' + title + '</div><div style="color:var(--muted);font-size:13px;margin:4px 0 10px">' + sub + '</div><div style="width:150px;margin:8px auto 0">' + wm() + '</div></div><button class="btn primary" style="margin-top:14px;height:48px" data-a="shared">Share</button><button class="lnk" data-a="ovclose">Close</button>'); }
function applyYoung(on) {
  S.young = on; if (on) { S.age = 'u13'; S.set.streak = false; S.set.calm = true; if (!S.tips.qg) { S.tips.qg = true; modal('<div style="font-size:38px">&#x1F33F;</div><div style="font-weight:900;font-size:22px;margin:6px 0">Try Quiet Garden?</div><div class="fine" style="margin-bottom:14px">Quiet Garden hides the numbers and lets you tend your plants as much as you like. You can switch it on or off in Settings any time.</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:52px;font-size:15px" data-a="qg" data-v="1">Yes, please</button><button class="btn secondary" style="height:52px;font-size:15px" data-a="ovclose">Not now</button></div>'); } }
}
/* ---------- actions ---------- */
function act(a, d) {
  switch (a) {
    case 'skipIntro': introDone(); break;
    case 'age': S.age = d.v; if (d.v === 'u13') applyYoung(true); S.ftue = 'tutorial'; if (modalOpen()) { pending = function () { startRound(false, true); }; releasing = true; } else startRound(false, true); break;
    case 'skipTut': S.ftue = 'done'; go('home'); break;
    case 'toGarden': S.ftue = 'garden'; go('garden'); break;
    case 'playAnother': S.ftue = 'done'; startRound(false); break;
    case 'home': case 'settings': case 'shed': case 'map': case 'album': case 'badges': case 'diary': go(a); break;
    case 'garden': S.viewLevel = Math.min(S.viewLevel, S.wordUnlocked); go('garden'); break;
    case 'play': startRound(false); break; case 'daily': startRound(true); break;
    case 'key': guess(d.k); break; case 'help': doHelp(); break;
    case 'wake': S.res.rose--; inc('revive'); markPeak('rose revive'); G.wrong = 5; G.over = false; G.stage = ''; S.screen = 'game'; render(); toast('Three petals are back'); cue2('success haptic', 'warm chime'); break;
    case 'reveal': startReveal(); break;
    case 'say': try { if (window.speechSynthesis) speechSynthesis.speak(new SpeechSynthesisUtterance(G.w)); } catch (e) {} toast('Prototype: would say "' + G.w.toLowerCase() + '" aloud'); cue2('none', 'spoken word'); break;
    case 'after': after(d.d); break;
    case 'oneMore': oneMore(); break;
    case 'enough': S.homeDusk = true; go('home'); break;
    case 'takebreak': closeNoFlush(); go('home'); break;
    case 'umpgo': closeNoFlush(); if (S.umpNext) { var f = S.umpNext; S.umpNext = null; f(); } break;
    case 'shareWin': { var p = S.last.plant ? plantObj(S.last.plant) : null; inc('share'); share(p ? 'I grew a ' + p.name : 'I solved ' + S.last.word, 'in WordFlora' + (S.last.helpers ? ' (with ' + S.last.helpers + ' helper' + (S.last.helpers > 1 ? 's' : '') + ')' : ''), p ? plantImg(p.imageName, 170) : '<div style="font-size:70px">&#x1F33C;</div>'); progress(); break; }
    case 'shareBadge': inc('share'); closeNoFlush(); share(A.badgeMeta.filter(function (b) { return b.id === d.id; })[0].title, ['', 'Bronze', 'Silver', 'Gold'][d.t] + ' badge', A.badge[d.id][d.t]); break;
    case 'shared': toast('Prototype: share sheet would open'); closeNoFlush(); flush(); break;
    case 'viewlevel': if (+d.l <= S.wordUnlocked) { S.viewLevel = +d.l; render(); } else toast('Earn all 10 plants of level ' + (+d.l - 1) + ' to open this one'); break;
    case 'pickword': if (+d.l <= S.wordUnlocked) { S.wordPick = +d.l; S.viewLevel = +d.l; toast('Playing word level ' + d.l); render(); } else toast('Earn all 10 plants of the level before it'); break;
    case 'locked': toast('Win a round to find this plant'); break;
    case 'plant': go('plant', { id: d.id }); break;
    case 'hand': S.hand = d.t; cue2('light selection tick', 'wooden clack'); render(); break;
    case 'useTool': useTool(); break;
    case 'repot': go('repot'); break; case 'plantback': go('plant'); break;
    case 'soil': doRepot(d.s); break; case 'repotDone': closeNoFlush(); go('plant'); flush(); break;
    case 'prune': useTool('shears'); break;
    case 'snip': { var el = document.querySelector('.tip[data-i="' + d.i + '"]'); if (el) { el.remove(); S.pruneLeft--; cue('shears'); $('#pcount').textContent = (3 - S.pruneLeft) + ' of 3 trimmed'; if (S.pruneLeft <= 0) { var o = S.plants[S.p.id]; o.pruneAt = now(); inc('prune'); if (!Q()) addGP(S.p.id, 4 + (S.tier.shears - 1) * 2); closeNoFlush(); progress(); render(); toast(Q() ? 'Trimmed' : 'Trimmed! +4 growth'); setTimeout(flush, 500); } } break; }
    case 'sunspot': useTool('lamp'); break;
    case 'nameit': { var cur = S.plants[S.p.id].nick || ''; modal('<div style="font-weight:900;font-size:20px;margin-bottom:8px">Name your ' + plantObj(S.p.id).name + '</div><input id="nameIn" maxlength="16" value="' + cur + '" placeholder="A name (up to 16 letters)" style="width:100%;padding:12px;border-radius:12px;border:1px solid var(--line);font-size:16px;background:var(--surface);color:var(--text)"><div class="fine" style="margin:6px 0 12px">Names stay on your device.</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:48px;font-size:15px" data-a="ovclose">Cancel</button><button class="btn primary" style="height:48px;font-size:15px" data-a="savename">Save</button></div>'); break; }
    case 'savename': { var v = ($('#nameIn').value || '').trim().slice(0, 16).replace(/[<>&"]/g, ''); if (v && BAD.test(v)) { toast('Let us pick a different name'); break; } S.plants[S.p.id].nick = v; if (v) diary(S.p.id, 'nick', 'You named it ' + v); closeNoFlush(); render(); break; }
    case 'grat': S.gratDay = dkey(); closeModal(); break;
    case 'cerskip': { var id2 = null; var ids = Object.keys(S.plants).filter(function (k) { return S.ceremony[k]; }); id2 = ids[ids.length - 1]; closeNoFlush(); var pl = plantObj(id2); var grat = !S.young && S.gratDay !== dkey(); modal('<div class="eyebrow">Wonder</div><div style="margin:6px 0">' + plantImg(id2, 140) + '</div><div style="font-weight:900;font-size:22px">' + pname(id2) + ' is in bloom</div><div style="font-size:15px;line-height:1.45;margin:10px 0 12px">' + safe(WONDER[id2] || pl.botanicalFact) + '</div>' + (grat ? '<div class="card" style="margin-bottom:12px"><div style="font-weight:700;font-size:14px;margin-bottom:8px">One thing you liked today?</div><div style="display:flex;gap:6px;flex-wrap:wrap;justify-content:center"><button class="chipx" data-a="grat">A plant I grew</button><button class="chipx" data-a="grat">A word I got</button><button class="chipx" data-a="grat">Something outside</button></div><button class="lnk" data-a="grat">Not now</button></div>' : '') + '<button class="btn primary" style="height:48px" data-a="ovclose">Continue</button>', false, 'cer'); break; }
    case 'upgrade': { var t = d.t, cost = S.tier[t] === 1 ? 30 : 120; if (S.res.shed >= cost) { S.res.shed -= cost; S.tier[t]++; inc('upgrade'); progress(); render(); toast(t + ' upgraded to tier ' + S.tier[t]); } else toast('Needs ' + cost + ' shed points. You have ' + S.res.shed + '.'); break; }
    case 'setting': { var k = d.k; if (k === 'remind' && !S.set.remind) { modal('<div class="eyebrow">System prompt would appear here</div><div style="font-weight:900;font-size:18px;margin:8px 0">"WordFlora" would like to send you notifications</div><div class="fine" style="margin-bottom:14px">Shown only when you turn on Remind me, never earlier. Reminders are one gentle line a day.</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:10px"><button class="btn secondary" style="height:48px;font-size:15px" data-a="notif" data-v="0">Don\'t Allow</button><button class="btn primary" style="height:48px;font-size:15px" data-a="notif" data-v="1">Allow</button></div>', true); break; } S.set[k] = !S.set[k]; render(); break; }
    case 'notif': S.set.remind = d.v === '1'; closeNoFlush(); render(); break;
    case 'diff': S.set.diff = d.d; render(); break;
    case 'rm': S.rm = !S.rm; applyTheme(); render(); break;
    case 'showall': S.showAll = !S.showAll; if (S.showAll) Object.keys(S.tools).forEach(function (k2) { S.tools[k2] = 1; }); render(); break;
    case 'howto': modal('<div style="font-weight:900;font-size:20px;margin-bottom:8px">How to play</div><div style="text-align:left;font-size:14px;line-height:1.55">Tap letters to guess the word. A wrong guess drops a petal. If the petals are gone, the flower rests and you can wake it with a Rose of Jericho. Use Help any time for a hint, a vowel, or the first letter. Every word you solve grows a plant in your garden.</div><button class="btn primary" style="margin-top:14px;height:48px" data-a="ovclose">Got it</button>'); break;
    case 'theme': S.theme = null; S.set.theme = d.t; render(); break;
    case 'helper': helper(d.h); break;
    case 'paywall': if (S.ftue !== 'done') break; S.back = d.back || S.screen; if (S.young) { S.gateIn = ''; go('gate'); } else go('paywall'); break;
    case 'gkey': { var gi = S.gateIn || ''; if (d.k === 'x') gi = gi.slice(0, -1); else if (gi.length < 2) gi += d.k; S.gateIn = gi; if (gi.length === 2) { if (gi === '83') { S.gateIn = ''; go('paywall'); } else { S.gateIn = ''; toast('Not quite. Ask a grown-up to help.'); render(); } } else render(); break; }
    case 'payback': go(S.back || 'home'); break;
    case 'plan': S.plan = d.p; render(); break;
    case 'subscribe': S.plus = true; toast('Prototype: Plus is now active (no real purchase)'); go('settings'); break;
    case 'adclose': startRound(false); break;
    case 'adfree': S.back = 'home'; go(S.young ? 'gate' : 'paywall'); break;
    case 'badge': badgeCard(d.id); break;
    case 'species': { var sp = A.species.filter(function (s) { return s.id === d.id; })[0]; if (S.stickers[d.id]) { inc('facts'); progress(); modal('<div style="width:130px;margin:0 auto">' + A.stk[d.id] + '</div><div style="font-weight:900;font-size:22px">' + sp.name + '</div><div style="font-size:12px;color:var(--muted);font-style:italic">' + sp.latin + '</div><div style="font-size:14px;line-height:1.4;margin:10px 0">' + safe(sp.fact) + '</div><button class="btn primary" data-a="ovclose" style="height:46px">Nice</button>'); } else toast(sp.night ? 'Comes out in the evening' : 'Not met yet. Visit the garden with the net.'); break; }
    case 'bfIntro': go('bfIntro'); break; case 'bfStart': bfStartGame(); break; case 'bfEnd': bfFinish(); break;
    case 'lantern': S.lantern--; S.lanternActive = true; toast('Glow Lantern lit: evening visitors are out'); render(); break;
    case 'roseInfo': toast('Rose seed ' + S.seed + ' of 8' + (S.seed >= 8 && S.res.rose >= 3 ? '. Your satchel is full.' : '. Each finished round adds one.')); break;
    case 'qg': S.set.quiet = true; closeModal(); render(); break;
    case 'tour': closeNoFlush(); go('diary'); break;
    case 'graceoff': S.graceOff = !S.graceOff; render(); break;
    case 'ovclose': case 'ovbg': closeModal(); break;
    case 'ovplay': closeNoFlush(); startRound(false); break;
    case 'toast': toast(d.t); break;
  }
}
function helper(h) {
  if (h === 'tools') { Object.keys(S.tools).forEach(function (k) { S.tools[k] = 1; }); toast('All tools unlocked'); }
  if (h === 'res') { S.res.water = Math.min(40, S.res.water + 10); S.res.scoop += 5; S.res.shed += 50; toast('Added drops, scoops, shed points'); }
  if (h === 'plants') { for (var i = 0; i < 3; i++) earnPlant('X'); progress(); toast('3 plants added'); }
  if (h === 'wlevel') { A.plants.filter(function (p) { return p.level === S.wordPick; }).forEach(function (p) { if (!S.plants[p.imageName]) S.plants[p.imageName] = { gp: 0, stage: 1, lastWater: 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0, nick: '' }; }); progress(); toast('Word level finished'); }
  if (h === 'glevel') { var lv = S.wordPick; A.plants.filter(function (p) { return p.level === lv; }).forEach(function (p) { if (!S.plants[p.imageName]) S.plants[p.imageName] = { gp: 0, stage: 1, lastWater: 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0, nick: '' }; var o = S.plants[p.imageName]; o.gp = Math.max(o.gp, 100); o.stage = stageOf(o.gp); S.ceremony[p.imageName] = true; }); progress(); toast('Garden level finished'); }
  render();
}
/* ---------- wiring ---------- */
$('#phone').addEventListener('click', function (e) { var t = e.target.closest('[data-a]'); if (!t) return; if (t.dataset.a === 'ovbg' && e.target !== t) return; act(t.dataset.a, t.dataset); });
$('#skipRain').addEventListener('click', function () { stopRain(true); });
document.addEventListener('keydown', function (e) { if (S.screen === 'game' && /^[a-zA-Z]$/.test(e.key) && !modalOpen()) guess(e.key.toUpperCase()); });
$('#tTheme').onclick = function () { S.theme = themeNow() === 'dark' ? 'light' : 'dark'; applyTheme(); render(); };
$('#tRm').onchange = function () { S.rm = this.checked; applyTheme(); render(); };
$('#tFree').onclick = function () { S.plus = false; applyTheme(); render(); }; $('#tPlus').onclick = function () { S.plus = true; applyTheme(); render(); };
$('#tEve').onchange = function () { S.evening = this.checked; S.homeDusk = false; render(); };
$('#tYoung').onchange = function () { applyYoung(this.checked); applyTheme(); render(); };
$('#tSeason').onchange = function () { S.season = this.value; render(); };
$('#tDay').onclick = function () { S.skew += DAY; S.dayIdx++; S.homeDusk = false; S.adsToday = 0; checkUnlocks(); toast('Next day: new Daily Bloom word'); render(); };
$('#tMin2').onclick = function () { S.skew += 120000; toast('Fast-forwarded 2 minutes'); render(); };
$('#tMin20').onclick = function () { S.skew += 1200000; S.playMin += 20; toast('Fast-forwarded 20 minutes'); render(); };
$('#tAway3').onclick = function () { S.skew += 3 * DAY; S.dayIdx += 3; S.welcome = { days: 3 }; S.homeDusk = false; checkUnlocks(); go('home'); };
$('#tAway30').onclick = function () { S.skew += 30 * DAY; S.dayIdx += 30; S.welcome = { days: 30 }; S.homeDusk = false; checkUnlocks(); go('home'); };
$('#tFresh').onclick = function () { try { localStorage.removeItem('wf-proto2'); } catch (e) {} var y = S.young, th = S.theme; S = fresh(); S.theme = th; queue = []; pending = null; releasing = false; G = null; stopRain(false); closeNoFlush(); go('intro'); };
$('#tLogic').onclick = function () { var r = $('#logic'); r.style.display = r.style.display === 'block' ? 'none' : 'block'; };
$('#tPrompts').onclick = function () { modal('<div style="font-weight:900;font-size:20px;margin-bottom:8px">Where prompts would appear</div><div style="text-align:left;font-size:13px;line-height:1.55"><b>Session 1:</b> none. No ads, paywall, rating, notification or tracking prompts, and no streak copy.<br><b>Consent (UMP) and tracking (ATT):</b> once, just before the first ad request.<br><b>Notifications:</b> only when Remind me is turned on in Settings.<br><b>Paywall:</b> from Settings or "Remove ads", never in session 1; behind the grown-up gate for under 13.<br><b>Rating prompt:</b> later, after a calm moment, never at a peak.</div><button class="btn primary" style="margin-top:14px;height:46px" data-a="ovclose">Got it</button>'); };
$('#tReal').onclick = function () { var r = $('#real'); r.style.display = r.style.display === 'block' ? 'none' : 'block'; };
function fit() { var h = window.innerHeight - $('#tb').offsetHeight - 40, w = window.innerWidth - 20, s = Math.min(1, h / 870, w / 410); $('#fit').style.transform = 'scale(' + s + ')'; $('#fit').style.height = (844 * s) + 'px'; $('#fit').style.width = (390 * s) + 'px'; $('#phone').style.transformOrigin = 'top left'; $('#phone').style.transform = 'scale(' + s + ')'; }
window.addEventListener('resize', fit);
window.__wf = { S: function () { return S; }, act: act, guess: guess, render: render, go: go, G: function () { return G; }, BF: function () { return BF; }, startRound: startRound, flush: flush, win: win, earnPlant: earnPlant, bfFinish: bfFinish, adCheck: adCheck, WORDS: WORDS, WONDER: WONDER, BAD: BAD, R: R, queue: function () { return queue; }, helper: helper, doHelp: doHelp, markPeak: markPeak, now: now, VOICE: VOICE, DAILYWORD: function () { return pickWord(true); }, fresh: fresh, setS: function (o) { Object.assign(S, o); } };
if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches && !S.screenSeen) S.rm = true;
if (['bf', 'game', 'earned', 'resting', 'bfSum', 'repot', 'ad', 'gate'].indexOf(S.screen) >= 0) S.screen = 'home'; if (S.ftue === 'tutorial' || S.ftue === 'earned') S.ftue = 'age';
var q = new URLSearchParams(location.search); if (q.get('screen') && q.get('screen') !== 'bf') S.screen = q.get('screen'); if (q.get('screen') === 'bf') S.screen = 'bfIntro'; if (q.get('theme')) S.theme = q.get('theme'); if (q.get('season')) S.season = q.get('season'); if (q.get('dusk')) S.evening = true;
if (q.get('seed')) { ['plant_dandelion', 'plant_daisy', 'plant_sunflower', 'plant_tulip', 'plant_rose'].forEach(function (id, i) { S.plants[id] = { gp: [5, 30, 95, 200, 15][i], stage: stageOf([5, 30, 95, 200, 15][i]), lastWater: i ? now() : 0, soil: 'loam', pruneAt: 0, mistAt: 0, sunAt: 0, nick: i === 1 ? 'Dot' : '' }; }); S.ftue = 'done'; S.age = 'adult'; Object.keys(S.tools).forEach(function (k) { S.tools[k] = 1; }); S.unl = { sun: true, soil: true, net: true, map: true, shed: true, badges: true, rose: true }; S.res = { water: 12, scoop: 4, shed: 42, rose: 1 }; S.seed = 3; S.p = { id: 'plant_daisy' }; S.badges = { plant_collector: 1, first_butterfly: 1, streak: 1 }; S.stickers = { monarch: 2, honeybee: 1, ladybug: 3, dragonfly: 1 }; S.days = ['a', 'b', 'c']; S.lastDay = dkey(); S.streak = 3; S.best = 3; S.rm = true; S.lantern = 1; S.wordUnlocked = 2; S.wordPick = 2; S.diary = [{ id: 'plant_daisy', kind: 'stage', text: 'Dot grew to Sprout', at: dkey(), season: S.season }, { id: 'plant_dandelion', kind: 'sprout', text: 'First sprout: Dandelion joined the garden', at: dkey(), season: S.season }]; }
if (S.screen === 'plant' && !S.p.id) S.screen = 'garden';
if (q.get('screen') === 'game') { G = { w: 'SUNFLOWER', h: WORDS[16].h, h2: WORDS[16].h2, f: WORDS[16].f, daily: false, g: { S: 1, U: 1, N: 1, X: 2, Q: 2 }, wrong: 6, over: false, help: 1, helpers: 1, pulse: true, pulsed: true }; }
if (q.get('screen') === 'earned') { S.last = { word: 'SUNFLOWER', wrong: 1, helpers: 1, plant: 'plant_sunflower', rw: { water: 2, shed: 1, scoop: 0 }, daily: false }; }
if (q.get('screen') === 'resting') { G = { w: 'SUNFLOWER', h: WORDS[16].h, h2: '', f: WORDS[16].f, g: {}, wrong: 8, over: true, stage: q.get('stage') || 'offer', rv: 9 }; }
if (q.get('screen') === 'rest') { S.restDaily = false; }
fit(); applyTheme(); render();
if (q.get('screen') === 'bf') { if (q.get('eve')) { S.evening = true; $('#tEve').checked = true; } bfStartGame(); setTimeout(function () { BF.t = 12; }, 50); }
if (q.get('test')) { var im = new Image(); im.style.display = 'none'; im.src = '/__delay?s=' + (q.get('wait') || 28); document.body.appendChild(im); var sc = document.createElement('script'); sc.src = 'test.js?' + Date.now(); document.body.appendChild(sc); }
})();

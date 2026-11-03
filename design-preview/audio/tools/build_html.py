import json, os
H = os.path.dirname(os.path.abspath(__file__)); O = os.path.join(H, '..')
peaks = json.load(open(H + '/peaks.json')); stats = json.load(open(H + '/stats.json'))
R = lambda a, b, c: {'A': a, 'B': b, 'C': c}
EV = [
 ('key', 'Key tap', 'Soft tick on every keyboard press. Must be fatigue-proof: very short, no pitch fighting the correct-letter note.',
  R('2 kHz sine, 8 ms decay + 3.5 kHz noise click: glassy tick', '820 to 560 Hz sine glide, 12 ms decay: wood tap', '900 Hz band noise 12 ms + 300 Hz sine: felt tick'), '.selection (SwiftUI sensoryFeedback)'),
 ('correct', 'Correct letter', 'Bright, rewarding pluck that sits in C major so rapid letters never clash.',
  R('E5 additive marimba (partials 1, 3.99, 9.9, fast upper decay)', 'C6 inharmonic glass bell (1, 2.76, 5.4, 8.93)', 'G5 + D6 kalimba pair, 70 ms apart'), '.impact(weight: .light) once, with the letter flip'),
 ('wrong', 'Wrong letter', 'Soft and non-punitive: no buzz, no falling pitch, no dissonance. Plays with the petal-drop; input is back within 150 ms.',
  R('196 to 208 Hz sine boop, slightly rising, 70 ms decay', 'Band noise sweep 900 to 450 Hz, sine-squared envelope: airy whoosh', '150 Hz sine thud + 500 Hz felt click: wooden pup'), '.impact(flexibility: .soft), never .error (spec 19 P-05)'),
 ('word', 'Word complete', 'Short ascending chime during the staggered letter wave.',
  R('C5 E5 G5 marimba arpeggio, 110 ms steps', 'C5 G5 C6 bell arpeggio, 130 ms steps', 'G4 C5 E5 G5 kalimba run, 90 ms steps'), '.success (one, at the last letter)'),
 ('earned', 'Plant earned', 'Bloom swell, sparkly but calm, under 2.5 s. Skippable with the sequence.',
  R('Cmaj7 detuned-sine pad swelling 0.9 s + 5 bell sparkles', 'Harp-like C4 to C6 run (9 notes/90 ms) + shimmer pad', 'Band-noise rise 400 Hz to 5 kHz, then C6 E6 G6 bell cluster over low pad'), 'CoreHaptics bloom crescendo (soft ramp), single pattern'),
 ('levelup', 'Level up', 'Warmer and a bit longer than plant earned. Never auto-plays near an ad.',
  R('C4 to E5 marimba arpeggio over a Cmaj pad', 'F major pad moving to C major pad, bells G5 C6 on top', 'Soft/kalimba rise C4 to G5 over C3 G3 E4 pad'), '.success'),
 ('rest', 'Round resting', 'A comforting low note: the plant is tucked in, not defeated. No falling line, no minor color.',
  R('G3 detuned-sine pad, gentle swell', 'C3 then G3 open fifth, soft partials, slow decay (rising, lullaby-like)', 'F3 soft bowl (bell partials, slow decay) + A3 under it'), '.impact(flexibility: .soft) single, never .warning'),
 ('wake', 'Rose of Jericho wake-up', 'Revive: rising shimmer that says the plant opens back up.',
  R('Six staggered pads climbing C4 to C6 with tremolo', 'Nine-note harp run C4 to C6 + E6 bell', 'Band-noise rise 300 Hz to 6 kHz, then G5 C6 E6 bells over C/G pad'), 'CoreHaptics rising ramp (intensity and sharpness up)'),
 ('water', 'Water pour', 'Soft droplets as the can tilts. Loop-friendly feel, quiet.',
  R('16 randomized sine droplets with fast upward pitch bend (0.9 to 2.2 kHz)', 'Narrow band-noise stream (1.5 to 2.4 kHz) + 8 droplets', '6 larger low droplets (500 to 900 Hz): plink-plonk'), 'CoreHaptics rain pattern (many tiny transients, low intensity)'),
 ('soil', 'Soil scoop', 'Soft thud plus crumble.',
  R('95 to 60 Hz thud + 7 band-noise crumble ticks', 'Band-noise scrape 700 to 1800 Hz, then thud', 'Two 100 Hz pats with felt clicks'), '.impact(flexibility: .soft, intensity: 0.8) soft thump'),
 ('sun', 'Sun glow', 'Warm pad as sunlight settles on the plant.',
  R('Cadd9 pad (C4 E4 G4 D5), 0.8 s swell', 'Dadd9 pad with F#5: brighter, lydian-ish', 'G3 + G4 pad with slow vibrato, two high bell notes'), 'Optional faint .impact(intensity 0.3) at swell peak, or none'),
 ('snip', 'Prune snip', 'Tiny snip. Short and light.',
  R('Two band-noise ticks at 4.5 and 5.2 kHz, 70 ms apart (scissor close)', 'Single band-noise snick, 3.8 kHz, 12 ms decay', '3 kHz noise tick + tiny G6 kalimba ping'), '.impact(weight: .light, intensity 0.5)'),
 ('butterfly', 'Butterfly catch', 'Light sparkle.',
  R('E6 G6 C7 quiet bells, 60 ms apart', 'A6 bell with 14 Hz flutter tremolo + E7 shimmer', 'G5 B5 D6 G6 B6 harp flick, 45 ms apart'), '.impact(weight: .light)'),
 ('badge', 'Badge unlock (bronze / silver / gold)', 'Three escalating tiers per variant: more notes, wider register, a pad at silver and gold. Gold under 2.2 s.',
  R('Marimba motif growing 2, 4, 6 notes, pad from silver', 'Single bell, then two, then a three-bell chord with pad', 'Kalimba motif rising in register with each tier, pad at gold'), 'Bronze/silver .success; gold CoreHaptics short crescendo (matches CelebrationRain)'),
 ('button', 'Button press', 'Quiet UI pop for general buttons.',
  R('620 to 540 Hz sine pop, 20 ms decay', '300 Hz sine tap, 15 ms decay', '420 to 700 Hz rising sine bubble, 30 ms decay'), '.impact(weight: .light)'),
 ('ambient', 'Ambient garden loop (25 s, off by default)', 'Soft garden bed. Seamless: 2.5 s equal-power crossfade of the tail onto the head (wrap jump below one typical sample step). Play at about -30 LUFS under SFX. Use the WAV or CAF for looping (AAC adds encoder padding gaps).',
  R('Double low-passed noise (420 Hz) with 8.3 s and 3.1 s swells + 12 groups of 2-4 sine chirps (2.4 to 3.8 kHz)', 'Darker wind (300 Hz) + C3/G3 drone pad + 7 sparse chirp groups', 'Brighter wind (650 Hz) + faint 1.8 kHz rustle band + 9 chirp groups'), 'None. Optional slow breathing haptic is a separate opt-in (spec 18 P5)'),
]
REC = {
 'key': ('B', 'Wood tap is unpitched, so thousands of presses never clash with the pitched correct-letter note.'),
 'correct': ('A', 'Marimba is warm and bright, reads as a pluck, appeals to kids and adults.'),
 'wrong': ('B', 'Airy whoosh has no pitch, so it cannot read as a buzzer or as a failure tone.'),
 'word': ('A', 'Same marimba voice as the correct letter, so the word chime feels like the letters paying off.'),
 'earned': ('A', 'Pad swell plus sparkle is the calmest bloom; B and C are busier.'),
 'levelup': ('B', 'Chord movement F to C gives the warmest, most arrived feeling.'),
 'rest': ('B', 'Open fifth that rises and resolves: comforting, no minor or falling shape.'),
 'wake': ('B', 'Harp run is the clearest rising gesture; noise sweeps can read as a riser/transition.'),
 'water': ('B', 'Stream plus droplets reads as pouring rather than random drips.'),
 'soil': ('A', 'Thud then crumble matches the scoop motion.'),
 'sun': ('A', 'Simple major add9 pad: warm without the bright lydian edge.'),
 'snip': ('A', 'Double tick is recognizably scissors even at 100 ms.'),
 'butterfly': ('A', 'Three quiet high bells: lightest and least likely to compete with the correct chime.'),
 'badge': ('A', 'Marimba family stays consistent with the core game; tier growth is easy to hear.'),
 'button': ('A', 'Soft pop, neutral, slightly falling like a physical press.'),
 'ambient': ('A', 'Most birds, least droning; B drone may tire in long sessions.'),
}
out = []
for eid, name, intent, rec, hap in EV:
    keys = [(f'badge-{t}', t.title()) for t in ('bronze', 'silver', 'gold')] if eid == 'badge' else [(eid, '')]
    out.append(dict(id=eid, name=name, intent=intent, recipes=rec, haptic=hap, rec=REC[eid],
                    tiers=[dict(key=k, label=l) for k, l in keys],
                    clips={f'{k}-{v}': dict(peaks=peaks[f'{k}-{v}']['peaks'], **stats[f'{k}-{v}']) for k, l in keys for v in 'ABC'}))
data = json.dumps(out)
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>WordFlora audio candidates</title>
<link rel="stylesheet" href="../theme.css"><script src="../theme.js"></script>
<style>
.wrap{max-width:1100px;margin:0 auto;padding:20px 16px 60px}
header{display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap}h1{font-size:28px;margin:0}.sub{color:var(--muted);margin:4px 0 16px;max-width:70ch}
.tg{font:inherit;font-weight:800;border:0;border-radius:999px;padding:10px 18px;background:var(--accent);color:var(--accent-ink);cursor:pointer}
.card{background:var(--surface);box-shadow:var(--shadow);border-radius:18px;padding:16px;margin:14px 0}
.rec{position:sticky;top:0;z-index:5;border:2px solid var(--accent)}
.rec h2{margin:0 0 8px;font-size:18px}.recgrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:8px}
.ri{display:flex;gap:8px;align-items:flex-start;font-size:12.5px;line-height:1.3}.ri button{flex:none}
.rec .body{max-height:42vh;overflow:auto}
h3{margin:0 0 4px;font-size:18px}.intent{color:var(--muted);font-size:14px;margin:0 0 10px}
.vars{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:12px}
.v{border:1px solid var(--line);border-radius:14px;padding:10px;display:flex;flex-direction:column;gap:6px}
.v.isrec{border-color:var(--accent);box-shadow:0 0 0 2px var(--accent) inset}
.vh{display:flex;align-items:center;gap:8px;font-weight:800}.badge{font-size:11px;background:var(--accent);color:var(--accent-ink);padding:2px 8px;border-radius:99px}
canvas{width:100%;height:44px;display:block;border-radius:8px;background:var(--bg)}
.p{font:inherit;font-weight:800;border:0;border-radius:99px;background:var(--accent);color:var(--accent-ink);width:38px;height:38px;cursor:pointer;flex:none}
.tier{display:flex;align-items:center;gap:8px}.tier span{width:52px;font-size:12px;color:var(--muted)}.tier canvas{flex:1}
.r{font-size:12px;color:var(--muted);line-height:1.35}.m{font-size:11px;color:var(--muted);font-variant-numeric:tabular-nums}
.hap{margin-top:10px;font-size:13px;border-top:1px solid var(--line);padding-top:8px}.hap b{color:var(--text)}
.note{font-size:13px;color:var(--muted)}a{color:var(--text)}
</style></head><body><div class="wrap">
<header><div><h1>WordFlora audio candidates</h1><p class="sub">Original synthesized sounds (pure Python, no samples). 16 events, 3 variants each (badges: 3 tiers x 3 variants). 44.1 kHz 16-bit mono WAV, AAC .m4a also provided, peaks at -3 dBFS. Untested by ear: judge these on a device.</p></div><button class="tg" onclick="wfToggle()">Toggle light / dark</button></header>
<div class="card rec"><h2>Recommended set (pinned)</h2><div class="body"><div class="recgrid" id="rec"></div></div></div>
<p class="note">Loudness: files are peak-normalized to -3 dBFS, which lands tonal sounds near -14 to -17 LUFS. Each clip lists the playback gain that brings it to about -20 LUFS; apply it as AVAudioPlayer.volume. Short clips under 0.4 s use an RMS-based estimate (marked ~). All sounds must follow the silent switch (AVAudioSession .ambient) and a Settings toggle. The existing sounds are audited in the notes at the bottom.</p>
<div id="list"></div>
<div class="card"><h3>Audit of existing sounds (flower sounds/*.mp3)</h3>
<p class="r">correct 1.50 s, stereo 44.1k MP3, -17.0 LUFS, peak -3.2 dBTP. incorrect 0.70 s, -28.8 LUFS, peak -10.6. word-guessed 2.50 s, -10.5 LUFS, peak -0.1 dBTP (almost clipping; about 10 dB louder than the others). word-not-guessed 1.40 s, 48 kHz, -28.5 LUFS, peak -20.1. Problems measured: a 18 dB loudness spread, inconsistent sample rates, stereo and MP3 for tiny UI cues, and the word-guessed win cue is at the 2.5 s limit. Names and the "not guessed" framing also conflict with the no-loss language. Character not judged (cannot listen). Recommendation: replace all four with this set, or at minimum re-level them; keep names out of code that surfaces "not guessed".</p></div>
<p class="note">Reproduce: <code>python3 tools/synth.py</code>, then <code>python3 tools/build_html.py</code>. Loop files: WAV and CAF (m4a/ambient-*.caf).</p></div>
<script>
const DATA=%DATA%;
const audios={};let cur=null;
function play(key,btn){const a=audios[key]||(audios[key]=new Audio('wav/'+key+'.wav'));if(cur&&cur!==a){cur.pause();cur.currentTime=0;}
 if(key.startsWith('ambient'))a.loop=true;
 if(!a.paused){a.pause();a.currentTime=0;btn.textContent='\\u25B6';cur=null;return;}
 a.volume=key.startsWith('ambient')?0.4:1;
 a.currentTime=0;a.play();cur=a;btn.textContent='\\u25A0';a.onended=()=>btn.textContent='\\u25B6';}
function wave(cv,pk){const dpr=devicePixelRatio||1;const w=cv.clientWidth||240,h=44;cv.width=w*dpr;cv.height=h*dpr;const c=cv.getContext('2d');c.scale(dpr,dpr);
 c.fillStyle=getComputedStyle(document.body).getPropertyValue('--accent');const bw=w/pk.length;pk.forEach((p,i)=>{const bh=Math.max(1,p*h*.9);c.fillRect(i*bw,(h-bh)/2,Math.max(1,bw-1),bh);});}
function gain(c){const g=Math.round((-20-c.est)*10)/10;return (g>0?'+':'')+g+' dB (vol '+Math.min(1,Math.pow(10,g/20)).toFixed(2)+')';}
function meta(c){return c.dur.toFixed(2)+' s, peak '+c.peak+' dBFS, '+(c.lufs!==null?c.lufs.toFixed(1)+' LUFS':'~'+c.est.toFixed(1)+' LUFS')+', clip '+c.clip+'. Play at '+gain(c);}
const list=document.getElementById('list'),rec=document.getElementById('rec');const canv=[];
DATA.forEach(e=>{const d=document.createElement('div');d.className='card';
 let h='<h3>'+e.name+'</h3><p class="intent">'+e.intent+'</p><div class="vars">';
 'ABC'.split('').forEach(v=>{h+='<div class="v'+(e.rec[0]===v?' isrec':'')+'"><div class="vh">Variant '+v+(e.rec[0]===v?' <span class="badge">recommended</span>':'')+'</div>';
  e.tiers.forEach(t=>{const k=t.key+'-'+v,c=e.clips[k];h+='<div class="tier">'+(t.label?'<span>'+t.label+'</span>':'')+'<button class="p" aria-label="Play '+k+'" data-k="'+k+'">\\u25B6</button><canvas data-w="'+k+'"></canvas></div><div class="m">'+meta(c)+'</div>';});
  h+='<div class="r"><b>Recipe:</b> '+e.recipes[v]+'</div></div>';});
 h+='</div><div class="hap"><b>Pair with haptic:</b> '+e.haptic+'</div>';d.innerHTML=h;list.appendChild(d);
 const r=document.createElement('div');r.className='ri';const k=e.tiers[e.tiers.length-1].key+'-'+e.rec[0];
 r.innerHTML='<button class="p" data-k="'+k+'" aria-label="Play recommended '+e.name+'">\\u25B6</button><div><b>'+e.name+' ('+e.rec[0]+')</b><br>'+e.rec[1]+(e.id==='badge'?' (button plays gold)':'')+'</div>';rec.appendChild(r);});
document.body.addEventListener('click',ev=>{const b=ev.target.closest('button.p');if(b)play(b.dataset.k,b);});
function draw(){document.querySelectorAll('canvas[data-w]').forEach(cv=>{const k=cv.dataset.w;const e=DATA.find(x=>x.clips[k]);wave(cv,e.clips[k].peaks);});}
addEventListener('load',draw);addEventListener('resize',draw);new MutationObserver(draw).observe(document.documentElement,{attributes:true});
</script></body></html>'''
open(O + '/index.html', 'w').write(html.replace('%DATA%', data))

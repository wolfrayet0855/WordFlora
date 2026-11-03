#!/usr/bin/python3
# WordFlora original audio synthesis. Pure stdlib. Run: python3 synth.py
import math, random, wave, array, json, os, subprocess
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
TAU = 2 * math.pi
def N(sec): return int(sec * SR)
def hz(m): return 440.0 * 2 ** ((m - 69) / 12)
# note names -> freq
NOTE = {n: hz(60 + i + 12 * (o - 4)) for o in range(2, 8) for i, n in enumerate([])}
def f(name):
    names = {'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}
    n = names[name[0]]; rest = name[1:]
    if rest[0] == '#': n += 1; rest = rest[1:]
    return hz(60 + n + 12 * (int(rest) - 4))

def mix(buf, sig, start=0.0, gain=1.0):
    s = N(start)
    need = s + len(sig)
    if len(buf) < need: buf.extend([0.0] * (need - len(buf)))
    for i, v in enumerate(sig): buf[s + i] += v * gain
    return buf

def noise(sec, seed=1):
    r = random.Random(seed); return [r.uniform(-1, 1) for _ in range(N(sec))]

def biquad(x, kind, fc, q=0.707):
    w = TAU * fc / SR; al = math.sin(w) / (2 * q); c = math.cos(w)
    if kind == 'lp': b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
    elif kind == 'hp': b0, b1, b2 = (1 + c) / 2, -(1 + c), (1 + c) / 2
    else: b0, b1, b2 = al, 0, -al  # bp
    a0, a1, a2 = 1 + al, -2 * c, 1 - al
    b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
    y = []; x1 = x2 = y1 = y2 = 0.0
    for v in x:
        o = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, o; y.append(o)
    return y

PART = {  # (ratio, amp, decay-seconds-at-dur1)
 'marimba': [(1, 1, .30), (3.99, .30, .07), (9.9, .08, .03)],
 'bell':    [(1, 1, .70), (2.76, .45, .40), (5.4, .22, .20), (8.93, .10, .10)],
 'kalimba': [(1, 1, .40), (5.4, .18, .06), (8.2, .06, .03)],
 'harp':    [(1, 1, .80), (2, .5, .55), (3, .28, .40), (4, .14, .28), (5, .07, .2)],
 'soft':    [(1, 1, .35), (2, .18, .2)],
}
def note(freq, dur, kind='marimba', decay=1.0, vib=0.0):
    p = PART[kind]; n = N(dur); out = [0.0] * n
    for ratio, amp, tau in p:
        fr = freq * ratio
        if fr > 18000: continue
        tau *= decay
        for i in range(n):
            t = i / SR
            a = min(1, t / 0.002) * math.exp(-t / tau)
            out[i] += amp * a * math.sin(TAU * fr * t + (vib * math.sin(TAU * 5 * t) if vib else 0))
    return out

def pad(freqs, dur, att=0.4, rel=0.5, amp=1.0, shimmer=0.0):
    n = N(dur); out = [0.0] * n
    for fr in freqs:
        for det in (0.997, 1.0, 1.003):
            ph = random.Random(int(fr)).random() * TAU
            for i in range(n):
                t = i / SR
                e = min(1, t / att); e = e * e * (3 - 2 * e)
                r = min(1, (dur - t) / rel); r = r * r * (3 - 2 * r)
                tr = 1 + shimmer * math.sin(TAU * 5.5 * t + ph)
                out[i] += amp * e * r * tr * math.sin(TAU * fr * det * t + ph) / 3
    return out

def drop(freq, dur=0.14, rise=0.7):
    n = N(dur); out = []; ph = 0.0
    for i in range(n):
        t = i / SR
        fr = freq * (1 + rise * (1 - math.exp(-t / 0.018)))
        ph += TAU * fr / SR
        out.append(min(1, t / 0.001) * math.exp(-t / 0.035) * math.sin(ph))
    return out

def sweep_noise(dur, f0, f1, q=2.0, seed=3, shape=None, segs=24):
    # noise through bandpass stepping from f0 to f1 (log), enveloped
    base = noise(dur, seed); n = len(base); out = [0.0] * n; sl = n // segs
    for s in range(segs):
        fc = f0 * (f1 / f0) ** (s / max(1, segs - 1))
        seg = biquad(base[s * sl:(s + 1) * sl + 1], 'bp', fc, q)
        for i, v in enumerate(seg[:sl]): out[s * sl + i] = v * 3
    for i in range(n):
        t = i / dur / SR
        out[i] *= shape(t) if shape else math.sin(math.pi * t)
    return out

def sine(freq, dur, decay=None, glide=None):
    n = N(dur); out = []; ph = 0.0
    for i in range(n):
        t = i / SR
        fr = freq if not glide else freq + (glide - freq) * (t / dur)
        ph += TAU * fr / SR
        e = math.exp(-t / decay) if decay else 1
        out.append(min(1, t / 0.003) * e * math.sin(ph))
    return out

def click(dur, fc, q=1.0, decay=0.01, seed=5):
    n = noise(dur, seed); y = biquad(n, 'bp', fc, q)
    return [v * 3 * math.exp(-i / SR / decay) for i, v in enumerate(y)]

# ---------------- events ----------------
def e_key(v):
    if v == 'A':   # soft glass tick
        b = sine(2000, .04, .008); return mix(b, click(.03, 3500, 1, .006), 0, .3)
    if v == 'B':   # wood tap
        return sine(820, .07, .012, glide=560)
    b = click(.05, 900, .8, .012, 7)       # felt tick
    return mix(b, sine(300, .05, .01), 0, .6)
def e_correct(v):
    if v == 'A': return note(f('E5'), .6, 'marimba')
    if v == 'B': return note(f('C6'), .8, 'bell', .8)
    b = note(f('G5'), .5, 'kalimba'); mix(b, note(f('D6'), .5, 'kalimba'), .07, .7); return b
def e_wrong(v):
    if v == 'A':  # soft low boop, slightly rising (not falling = not sad)
        return [x * .9 for x in sine(196, .22, .07, glide=208)]
    if v == 'B':  # airy whoosh
        return sweep_noise(.3, 900, 450, 1.2, 4, lambda t: math.sin(math.pi * t) ** 2)
    b = sine(150, .16, .035)                # felt wooden pup
    return mix(b, click(.04, 500, .7, .01, 8), 0, .5)
def e_word(v):
    b = []
    if v == 'A':
        for i, n in enumerate(['C5', 'E5', 'G5']): mix(b, note(f(n), .7, 'marimba'), i * .11)
    elif v == 'B':
        for i, n in enumerate(['C5', 'G5', 'C6']): mix(b, note(f(n), .9, 'bell', .8), i * .13, .9)
    else:
        for i, n in enumerate(['G4', 'C5', 'E5', 'G5']): mix(b, note(f(n), .7, 'kalimba'), i * .09)
    return b
def e_earned(v):
    b = []
    if v == 'A':  # pad bloom swell + bell sparkles
        mix(b, pad([f('C4'), f('E4'), f('G4'), f('B4')], 2.2, .9, .9, .7, .05))
        for i, n in enumerate(['E6', 'G6', 'C7', 'B6', 'G6']): mix(b, note(f(n), .6, 'bell', .6), .7 + i * .17, .25)
    elif v == 'B':  # harp gliss arpeggio + shimmer
        for i, n in enumerate(['C4', 'E4', 'G4', 'C5', 'E5', 'G5', 'C6']): mix(b, note(f(n), 1.2, 'harp'), i * .09, .8)
        mix(b, pad([f('C5'), f('G5'), f('E6')], 1.8, .5, .9, .3, .12), .5)
    else:  # airy rise + chime cluster
        mix(b, sweep_noise(1.2, 400, 5000, 2, 9, lambda t: t * t * math.sin(math.pi * min(1, t * 1.05)) ), 0, .35)
        for i, n in enumerate(['C6', 'E6', 'G6']): mix(b, note(f(n), 1.1, 'bell', .9), 1.0 + i * .06, .55)
        mix(b, pad([f('C4'), f('G4')], 1.9, .6, .9, .4), .3)
    return b
def e_level(v):
    b = []
    if v == 'A':
        for i, n in enumerate(['C4', 'E4', 'G4', 'C5', 'E5']): mix(b, note(f(n), 1.0, 'marimba', 1.2), i * .12)
        mix(b, pad([f('C4'), f('G4'), f('C5'), f('E5')], 1.8, .2, .8, .5), .6)
    elif v == 'B':
        mix(b, pad([f('F3'), f('A3'), f('C4')], 1.0, .2, .3, .5))
        mix(b, pad([f('C4'), f('E4'), f('G4'), f('C5')], 1.8, .15, .8, .6), .55)
        for i, n in enumerate(['G5', 'C6']): mix(b, note(f(n), 1.1, 'bell'), .9 + i * .18, .5)
    else:
        for i, (n, k) in enumerate([('C4', 'soft'), ('G4', 'soft'), ('C5', 'kalimba'), ('E5', 'kalimba'), ('G5', 'bell')]):
            mix(b, note(f(n), 1.2, k, 1.2), i * .15, .8)
        mix(b, pad([f('C3'), f('G3'), f('E4')], 2.0, .4, .9, .5), .2)
    return b
def e_rest(v):
    b = []
    if v == 'A':  # single low warm note, gentle swell, no downward move
        b = pad([f('G3')], 1.4, .25, .9, 1.0)
    elif v == 'B':  # hollow open fifth, lullaby-like, rising
        mix(b, note(f('C3'), 1.4, 'soft', 1.8)); mix(b, note(f('G3'), 1.3, 'soft', 1.8), .3, .8)
    else:  # soft low bowl
        mix(b, note(f('F3'), 1.5, 'bell', 1.8), 0, .8); mix(b, note(f('A3'), 1.2, 'soft', 1.8), .15, .3)
    return b
def e_wake(v):
    b = []
    if v == 'A':  # rising shimmer pad stack
        for i, n in enumerate(['C4', 'G4', 'C5', 'E5', 'G5', 'C6']):
            mix(b, pad([f(n)], 1.4 - i * .05, .5 + i * .1, .5, .5, .1), i * .18)
    elif v == 'B':
        for i in range(9): mix(b, note(f(['C4','D4','E4','G4','A4','C5','E5','G5','C6'][i]), 1.1, 'harp'), i * .075, .7)
        mix(b, note(f('E6'), 1.0, 'bell'), .75, .5)
    else:
        mix(b, sweep_noise(1.0, 300, 6000, 3, 11, lambda t: t * math.sin(math.pi * min(1, t * 1.05))), 0, .3)
        for i, n in enumerate(['G5', 'C6', 'E6']): mix(b, note(f(n), 1.0, 'bell'), .85 + i * .1, .6)
        mix(b, pad([f('C4'), f('G4')], 1.7, .8, .7, .4))
    return b
def e_water(v):
    r = random.Random(20 + ord(v)); b = []
    if v == 'A':  # scattered droplets
        for i in range(16): mix(b, drop(r.uniform(900, 2200), .12), i * .075 + r.uniform(0, .04), r.uniform(.3, .8))
    elif v == 'B':  # gentle stream + droplets
        mix(b, sweep_noise(1.3, 1500, 2400, 1.0, 12, lambda t: min(1, t * 6) * min(1, (1 - t) * 5)), 0, .22)
        for i in range(8): mix(b, drop(r.uniform(1200, 2600), .1), .1 + i * .14, .45)
    else:  # few big plinks
        for i in range(6): mix(b, drop(r.uniform(500, 900), .22, .5), i * .2 + r.uniform(0, .05), r.uniform(.5, 1))
    return b
def e_soil(v):
    b = []
    if v == 'A':  # thud + crumble
        b = sine(95, .18, .04, glide=60)
        for i in range(7): mix(b, click(.05, 1400 + i * 150, .8, .012, 30 + i), .06 + i * .045, .4 - i * .03)
    elif v == 'B':  # scrape then thud
        mix(b, sweep_noise(.35, 700, 1800, .7, 13, lambda t: math.sin(math.pi * t)), 0, .45)
        mix(b, sine(85, .2, .05, glide=55), .3)
    else:  # two pats
        mix(b, sine(110, .12, .03, glide=70)); mix(b, click(.04, 600, .6, .012, 14), 0, .4)
        mix(b, sine(100, .12, .03, glide=65), .17, .8); mix(b, click(.04, 600, .6, .012, 15), .17, .3)
    return b
def e_sun(v):
    if v == 'A': return pad([f('C4'), f('E4'), f('G4'), f('D5')], 2.0, .8, .9, .8, .03)
    if v == 'B': return pad([f('D4'), f('A4'), f('F#5'), f('E5')], 2.0, .9, .9, .8, .04)
    b = pad([f('G3'), f('G4')], 2.0, .8, .9, .8, .06)
    for i, n in enumerate(['D6', 'G6']): mix(b, note(f(n), .8, 'bell', .6), .9 + i * .3, .15)
    return b
def e_snip(v):
    if v == 'A':
        b = click(.04, 4500, 1.5, .006, 40); mix(b, click(.04, 5200, 1.5, .006, 41), .07, .8); return b
    if v == 'B': return click(.07, 3800, 2, .012, 42)
    b = click(.04, 3000, 1.2, .005, 43); return mix(b, note(f('G6'), .12, 'kalimba', .4), .0, .3)
def e_butterfly(v):
    b = []
    if v == 'A':
        for i, n in enumerate(['E6', 'G6', 'C7']): mix(b, note(f(n), .5, 'bell', .5), i * .06, .6)
    elif v == 'B':
        s = note(f('A6'), .7, 'bell', .6)
        s = [x * (0.6 + 0.4 * math.sin(TAU * 14 * i / SR)) for i, x in enumerate(s)]; b = s
        mix(b, note(f('E7'), .5, 'bell', .4), .1, .3)
    else:
        for i, n in enumerate(['G5', 'B5', 'D6', 'G6', 'B6']): mix(b, note(f(n), .5, 'harp', .6), i * .045, .6)
    return b
def e_badge(v, tier):
    b = []; t = {'bronze': 0, 'silver': 1, 'gold': 2}[tier]
    if v == 'A':  # marimba motif grows
        seq = [['C5', 'G5'], ['C5', 'E5', 'G5', 'C6'], ['C5', 'E5', 'G5', 'C6', 'E6', 'G6']][t]
        for i, n in enumerate(seq): mix(b, note(f(n), .8, 'marimba', 1.1), i * .1)
        if t >= 1: mix(b, pad([f('C5'), f('G5')], 1.0 + t * .5, .15, .6, .3), .15)
    elif v == 'B':  # bell layers
        root = [f('C5'), f('G5'), f('C6')][t]
        mix(b, note(root, 1.2, 'bell', 1 + .4 * t))
        if t >= 1: mix(b, note(root * 1.25, 1.2, 'bell', 1.2), .12, .7)
        if t >= 2: mix(b, note(root * 1.5, 1.4, 'bell', 1.4), .24, .7); mix(b, pad([f('C4'), f('G4'), f('E5')], 2.0, .3, .9, .45), .1)
    else:  # kalimba, rises in register with each tier
        base = ['G4', 'C5', 'E5'][t]
        seq = [[0, 7], [0, 4, 7, 12], [0, 4, 7, 12, 16, 19]][t]
        for i, s in enumerate(seq): mix(b, note(hz(69 + (12 * 0) + s + {'G4':-2,'C5':3,'E5':7}[base]), .8, 'kalimba', 1.1), i * .09)
        if t == 2: mix(b, pad([f('C4'), f('G4'), f('C5')], 1.8, .3, .8, .4), .2)
    return b
def e_button(v):
    if v == 'A': return sine(620, .08, .02, glide=540)
    if v == 'B': return sine(300, .08, .015)
    return sine(420, .09, .03, glide=700)

def e_ambient(v):
    L = 25.0; X = 2.5; total = L + 2 * X; n = N(total); r = random.Random(77 + ord(v))
    # wind
    w = noise(total, 100 + ord(v))
    fc = {'A': 420, 'B': 300, 'C': 650}[v]
    w = biquad(biquad(w, 'lp', fc, .7), 'lp', fc, .7)
    w = biquad(w, 'hp', 60, .7)
    lfo = lambda t, per, ph: .5 + .5 * math.sin(TAU * t / per + ph)
    wind = [x * (.35 + .65 * lfo(i / SR, 25/3, 0) * (.6 + .4 * lfo(i / SR, 25/8, 1.3))) for i, x in enumerate(w)]
    b = [x * 3.0 for x in wind]
    if v == 'B': mix(b, pad([f('C3'), f('G3')], total, 3, 3, .05), 0, 1)
    if v == 'C':
        t2 = biquad(noise(total, 200), 'bp', 1800, .6)
        t2 = [x * 2 * (.4 + .6 * lfo(i / SR, 1.7, 0)) * .5 for i, x in enumerate(t2)]
        mix(b, t2, 0, .25)
    # chirps
    def chirp(f0, f1, dur):
        out = []; ph = 0.0; n_ = N(dur)
        for i in range(n_):
            t = i / n_; fr = f0 + (f1 - f0) * (t ** .7) + 120 * math.sin(TAU * 28 * t)
            ph += TAU * fr / SR
            out.append(math.sin(ph) * math.sin(math.pi * t) ** 2)
        return out
    count = {'A': 12, 'B': 7, 'C': 9}[v]
    gap = (L - 4) / count
    for k in range(count):
        t0 = X + 2 + k * gap + r.uniform(0, gap * .5)
        base = r.uniform(2400, 3800)
        for j in range(r.choice([2, 3, 4])):
            d = r.uniform(.06, .12)
            mix(b, chirp(base, base * r.uniform(1.15, 1.5), d), t0 + j * (d + .05), .09 if v != 'B' else .07)
    # seamless loop via equal-power crossfade of tail onto head
    Xn = N(X); outl = b[Xn:Xn + N(L)] if False else None
    body = b[:n]
    loop = body[Xn:Xn + N(L)]
    # head of loop (indices 0..Xn) blended with continuation after the end (body[Xn+N(L) ...])
    for i in range(Xn):
        a = i / Xn
        loop[i] = loop[i] * math.sin(a * math.pi / 2) + body[Xn + N(L) + i - 0] * math.cos(a * math.pi / 2) 
    return loop

# ---------------- finalize ----------------
def finalize(sig, peak_db=-3.0, fade=0.007, tail_fade=None):
    fn = N(fade)
    for i in range(min(fn, len(sig))): sig[i] *= i / fn
    for i in range(min(N(tail_fade) if tail_fade else fn, len(sig))):
        sig[-1 - i] *= i / (N(tail_fade) if tail_fade else fn)
    pk = max(abs(x) for x in sig) or 1
    g = 10 ** (peak_db / 20) / pk
    return [x * g for x in sig]
def write_wav(path, sig):
    a = array.array('h', [max(-32768, min(32767, int(round(x * 32767)))) for x in sig])
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(a.tobytes())
def peaks(sig, bins=120):
    step = max(1, len(sig) // bins)
    return [round(max(abs(x) for x in sig[i:i + step]), 3) for i in range(0, len(sig) - step + 1, step)][:bins]

EVENTS = [
 ('key', 'Key tap', e_key), ('correct', 'Correct letter', e_correct), ('wrong', 'Wrong letter', e_wrong),
 ('word', 'Word complete', e_word), ('earned', 'Plant earned', e_earned), ('levelup', 'Level up', e_level),
 ('rest', 'Round resting', e_rest), ('wake', 'Rose of Jericho wake-up', e_wake), ('water', 'Water pour', e_water),
 ('soil', 'Soil scoop', e_soil), ('sun', 'Sun glow', e_sun), ('snip', 'Prune snip', e_snip),
 ('butterfly', 'Butterfly catch', e_butterfly), ('badge', 'Badge unlock', None), ('button', 'Button press', e_button),
 ('ambient', 'Ambient garden loop', e_ambient)]

if __name__ == '__main__':
    os.makedirs(os.path.join(OUT, 'wav'), exist_ok=True); os.makedirs(os.path.join(OUT, 'm4a'), exist_ok=True)
    meta = {}
    jobs = []
    for eid, name, fn in EVENTS:
        for v in 'ABC':
            if eid == 'badge':
                for tier in ('bronze', 'silver', 'gold'): jobs.append((f'badge-{tier}', v, lambda v=v, tier=tier: e_badge(v, tier), eid))
            else: jobs.append((eid, v, lambda fn=fn, v=v: fn(v), eid))
    for key, v, gen, eid in jobs:
        sig = finalize(gen(), tail_fade=(None if eid == 'ambient' else .03)) if eid != 'ambient' else finalize(gen(), fade=0.0)
        fname = f'{key}-{v}'
        write_wav(os.path.join(OUT, 'wav', fname + '.wav'), sig)
        meta[fname] = {'peaks': peaks(sig)}
        print(fname, round(len(sig) / SR, 2), flush=True)
    json.dump(meta, open(os.path.join(OUT, 'tools', 'peaks.json'), 'w'))

#!/usr/bin/env python3
"""Render WordFlora's weather-day and Grand Garden prototype sounds into tools/out/weather/ (WAV + m4a).

Original and procedural: nothing is sampled, so everything is licence clean. Pure Python 3 standard library
(no numpy); ffmpeg turns each WAV into a small mono AAC file and measures loudness. Fixed seeds, so two runs
give identical WAVs. Prototype only: nothing is added to the app bundle.

Beds (loop, ~-30 LUFS integrated, no baked fades so they loop seamlessly; the player ramps volume in over
>= 400 ms, see docs/pm/endgame-events-audio-plan.md):
  wf-wind-loop        8 s   soft moving air, band-passed noise, slow gusts that repeat exactly every 8 s
  wf-storm-loop       8 s   soft rain hush plus low wind, no cracks, no thunder
  wf-drought-loop     6 s   very low warm hum with a quiet high shimmer (integer-Hz partials, exact 6 s period)
One-shots (peak <= -9 dBFS, attack >= 30 ms):
  wf-termite-tick     1.2 s  five sparse tiny woody taps (marimba-like, soft)
  wf-relief-chime     1.8 s  four rising pentatonic bell/kalimba notes
  wf-grand-flourish   3.0 s  gentle rising pentatonic arpeggio into a warm soft chord
  wf-frost-twinkle    1.4 s  a few very soft high glints
  wf-hail-patter      1.6 s  tiny soft taps, band-passed noise, no sharp edge

Noise-based beds are made loopable with an equal-power crossfade of the tail into the head.

Run from the repo root:  python3 tools/make_weather_sounds.py
"""

import math
import os
import random
import re
import struct
import subprocess
import sys
import wave

RATE = 44100
BITRATE = "64k"
ONE_SHOT_PEAK_DBFS = -10.5      # WAV peak; AAC overshoot keeps the m4a at or under -9 dBFS
BED_LUFS = -30.0
BED_PEAK_CEILING_DBFS = -12.0

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "tools", "out", "weather")
FFMPEG = "/usr/local/bin/ffmpeg" if os.path.exists("/usr/local/bin/ffmpeg") else "ffmpeg"
TAU = 2.0 * math.pi

# ---------- small helpers ----------


def lp_coeff(fc):
    return 1.0 - math.exp(-TAU * fc / RATE)


def smooth_noise(rng, n, fc):
    """White noise through two one-pole low-passes at fc Hz, scaled to roughly +-1 (slow random wobble)."""
    a = lp_coeff(fc)
    s1 = s2 = 0.0
    out = []
    for _ in range(n):
        s1 += a * (rng.uniform(-1, 1) - s1)
        s2 += a * (s1 - s2)
        out.append(s2)
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak for v in out]


def make_loop(x, n, fade):
    """x has n + fade samples. Return n samples whose end flows into their start (equal-power crossfade)."""
    out = x[:n]
    for i in range(fade):
        u = i / fade
        wi, wo = math.sin(0.5 * math.pi * u), math.cos(0.5 * math.pi * u)
        out[i] = x[i] * wi + x[n + i] * wo
    return out


def raised_attack(u, attack):
    return 0.5 * (1.0 - math.cos(math.pi * u / attack)) if u < attack else 1.0


def add_note(buf, start, freq, dur, amp, partials, attack=0.035, tail=None):
    """Add a bell/kalimba-like note: partial list of (ratio, level, decay seconds)."""
    i0 = int(start * RATE)
    n = int(dur * RATE)
    for k in range(n):
        if i0 + k >= len(buf):
            break
        u = k / RATE
        env = raised_attack(u, attack)
        if tail is not None and u > dur - tail:                     # raised-cosine release so nothing is cut
            env *= 0.5 * (1.0 + math.cos(math.pi * (u - (dur - tail)) / tail))
        s = 0.0
        for ratio, level, decay in partials:
            s += level * math.exp(-u / decay) * math.sin(TAU * freq * ratio * u)
        buf[i0 + k] += amp * env * s


BELL = [(1.0, 1.0, 0.55), (2.0, 0.28, 0.30), (3.0, 0.10, 0.18), (4.1, 0.04, 0.10)]
KALIMBA = [(1.0, 1.0, 0.45), (2.76, 0.18, 0.12), (5.4, 0.05, 0.06)]
WOOD = [(1.0, 1.0, 0.035), (3.9, 0.35, 0.015)]

C5, D5, E5, G5, A5 = 523.25, 587.33, 659.25, 783.99, 880.0
C6, D6, E6, G6 = 1046.5, 1174.66, 1318.5, 1567.98
C4, G4 = 261.63, 392.0


def fade_edges(buf, fi=0.0, fo=0.05):
    n = len(buf)
    a, b = int(fi * RATE), int(fo * RATE)
    for i in range(min(a, n)):
        buf[i] *= 0.5 * (1 - math.cos(math.pi * i / a))
    for i in range(min(b, n)):
        buf[n - 1 - i] *= 0.5 * (1 - math.cos(math.pi * i / b))
    return buf


# ---------- beds ----------


def render_wind():
    rng = random.Random(1101)
    n, fade, warm = 8 * RATE, int(1.5 * RATE), RATE
    total = n + fade
    s1 = s2 = hp = hp_prev = 0.0
    hpa = math.exp(-TAU * 90 / RATE)
    out = []
    for i in range(-warm, total):
        t = i / RATE
        # gusts: integer cycles per 8 s, so the modulation repeats exactly
        gust = 0.55 + 0.30 * math.sin(TAU * t / 8.0 + 0.6) + 0.15 * math.sin(TAU * 3 * t / 8.0 + 2.0)
        fc = 380 + 520 * gust
        a = lp_coeff(fc)
        w = rng.uniform(-1, 1)
        s1 += a * (w - s1)
        s2 += a * (s1 - s2)
        hp = hpa * (hp + s2 - hp_prev)
        hp_prev = s2
        if i >= 0:
            out.append(hp * (0.35 + 0.65 * gust))
    return make_loop(out, n, fade)


def render_storm():
    rng = random.Random(2202)
    n, fade, warm = 8 * RATE, int(1.5 * RATE), RATE
    total = n + fade
    mod = smooth_noise(rng, total + warm, 25.0)                   # soft droplet texture, no clicks
    # rain: white noise, high-pass ~1.2 kHz, low-pass ~6.5 kHz
    la, lb = lp_coeff(6500), lp_coeff(1200)
    r1 = r2 = 0.0
    # wind underneath
    w1 = w2 = 0.0
    out = []
    for i in range(-warm, total):
        t = i / RATE
        white = rng.uniform(-1, 1)
        r1 += la * (white - r1)
        r2 += lb * (r1 - r2)
        rain = (r1 - r2) * (0.75 + 0.25 * mod[i + warm])
        gust = 0.55 + 0.35 * math.sin(TAU * t / 8.0 + 1.1)
        wa = lp_coeff(300 + 300 * gust)
        w1 += wa * (rng.uniform(-1, 1) - w1)
        w2 += wa * (w1 - w2)
        if i >= 0:
            out.append(rain * 0.9 + w2 * (0.8 + 0.8 * gust))
    return make_loop(out, n, fade)


def render_drought():
    n = 6 * RATE
    out = [0.0] * n
    for i in range(n):
        t = i / RATE
        swell = 0.75 + 0.25 * math.sin(TAU * t / 6.0)
        hum = (math.sin(TAU * 55.0 * t) + 0.45 * math.sin(TAU * 110.0 * t + 0.4)
               + 0.18 * math.sin(TAU * 165.0 * t + 1.1))
        # quiet cicada-like shimmer: close high partials beat gently (integer Hz keeps the 6 s period exact)
        beat = 0.5 + 0.5 * math.sin(TAU * 5.0 * t + 0.3)
        beat2 = 0.5 + 0.5 * math.sin(TAU * 3.0 * t + 1.7)
        shimmer = (math.sin(TAU * 2900.0 * t) * beat + math.sin(TAU * 3140.0 * t + 0.5) * beat2) * 0.05
        out[i] = swell * (hum * 0.5 + shimmer * (0.6 + 0.4 * math.sin(TAU * 2.0 * t / 6.0 + 0.8)))
    return out


# ---------- one-shots ----------


def render_termite():
    rng = random.Random(3303)
    buf = [0.0] * int(1.2 * RATE)
    times = [0.05, 0.27, 0.46, 0.83, 0.98]
    freqs = [820, 960, 740, 1010, 880]
    amps = [0.8, 1.0, 0.7, 0.9, 0.6]
    for t0, f, a in zip(times, freqs, amps):
        add_note(buf, t0 + rng.uniform(-0.01, 0.01), f, 0.20, a, WOOD, attack=0.030, tail=0.08)
    return fade_edges(buf, 0.0, 0.02)


def render_relief():
    buf = [0.0] * int(1.8 * RATE)
    notes = [(0.00, C5), (0.26, D5 * 1.0), (0.52, G5), (0.80, C6)]       # C D G C: open, rising, pentatonic
    for k, (t0, f) in enumerate(notes):
        add_note(buf, t0, f, 1.3 if k == 3 else 0.9, 0.7 + 0.1 * k, BELL, attack=0.035, tail=0.4)
    add_note(buf, 0.80, E6 * 0.5, 1.0, 0.18, KALIMBA, attack=0.05, tail=0.4)   # soft E5 colour under the top note
    return fade_edges(buf, 0.0, 0.25)


def render_flourish():
    buf = [0.0] * int(3.0 * RATE)
    run = [C5, D5, E5, G5, A5, C6, D6, E6]
    for k, f in enumerate(run):
        add_note(buf, 0.10 + 0.17 * k, f, 1.1, 0.45 + 0.03 * k, KALIMBA, attack=0.04, tail=0.35)
    for f, lvl in [(C5, 0.6), (G5, 0.5), (C6, 0.5), (E6, 0.3), (G4, 0.4)]:      # warm soft chord that blooms
        add_note(buf, 1.45, f, 1.5, lvl, [(1.0, 1.0, 1.1), (2.0, 0.2, 0.7)], attack=0.12, tail=0.9)
    return fade_edges(buf, 0.0, 0.3)


def render_frost():
    rng = random.Random(4404)
    buf = [0.0] * int(1.4 * RATE)
    for t0, f, a in [(0.05, 2093.0, 0.6), (0.31, 2637.0, 0.5), (0.52, 3136.0, 0.4), (0.78, 2349.0, 0.35)]:
        add_note(buf, t0 + rng.uniform(-0.01, 0.01), f, 0.55, a, [(1.0, 1.0, 0.16), (2.0, 0.1, 0.08)], attack=0.035, tail=0.2)
    return fade_edges(buf, 0.0, 0.2)


def render_hail():
    rng = random.Random(5505)
    n = int(1.6 * RATE)
    buf = [0.0] * n
    t = 0.04
    while t < 1.35:
        fc = rng.uniform(1500, 3200)
        amp = rng.uniform(0.35, 1.0) * (1.0 - 0.5 * t / 1.4)
        i0, ln = int(t * RATE), int(0.07 * RATE)
        a = lp_coeff(fc * 1.4)
        b = lp_coeff(fc * 0.6)
        s1 = s2 = 0.0
        for k in range(ln):
            if i0 + k >= n:
                break
            u = k / RATE
            w = rng.uniform(-1, 1)
            s1 += a * (w - s1)
            s2 += b * (s1 - s2)
            env = raised_attack(u, 0.030) * math.exp(-u / 0.022)
            buf[i0 + k] += (s1 - s2) * amp * env * 3.0
        t += rng.uniform(0.05, 0.16)
    return fade_edges(buf, 0.0, 0.15)


# ---------- output ----------


def write_wav(path, samples, gain):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples))


def measure(path):
    res = subprocess.run([FFMPEG, "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true,volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True)
    log = res.stderr
    lufs = re.findall(r"I:\s+(-?[\d.]+) LUFS", log)
    peak = re.findall(r"max_volume: (-?[\d.]+) dB", log)
    dur = re.search(r"Duration: (\d+):(\d+):([\d.]+)", log)
    seconds = int(dur.group(1)) * 3600 + int(dur.group(2)) * 60 + float(dur.group(3)) if dur else float("nan")
    return (float(lufs[-1]) if lufs else float("nan"), float(peak[-1]) if peak else float("nan"), seconds)


def attack_time(samples):
    """Seconds from onset (50 ms RMS window 40 dB under the max) to within 6 dB of the max."""
    win = int(0.05 * RATE)
    step = win // 5
    rms = [math.sqrt(sum(s * s for s in samples[i:i + win]) / win) for i in range(0, len(samples) - win, step)]
    top = max(rms)
    onset = next(k for k, r in enumerate(rms) if r >= top * 10 ** (-40 / 20))
    near = next(k for k, r in enumerate(rms) if r >= top * 10 ** (-6 / 20))
    return (near - onset) * step / RATE


def max_step_db(samples):
    """Largest sample-to-sample jump relative to peak, a cheap crack/transient check for loops and seams."""
    peak = max(abs(s) for s in samples) or 1.0
    return max(abs(samples[i + 1] - samples[i]) for i in range(len(samples) - 1)) / peak


def encode(wav, m4a):
    subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", wav, "-c:a", "aac", "-b:a", BITRATE,
                    "-ar", str(RATE), "-ac", "1", "-map_metadata", "-1", "-movflags", "+faststart", m4a], check=True)


SOUNDS = [
    # name, renderer, kind, size budget KB
    ("wf-wind-loop", render_wind, "bed", 120),
    ("wf-storm-loop", render_storm, "bed", 120),
    ("wf-drought-loop", render_drought, "bed", 120),
    ("wf-termite-tick", render_termite, "shot", 60),
    ("wf-relief-chime", render_relief, "shot", 60),
    ("wf-grand-flourish", render_flourish, "shot", 60),
    ("wf-frost-twinkle", render_frost, "shot", 60),
    ("wf-hail-patter", render_hail, "shot", 60),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    rows = []
    failed = False
    for name, fn, kind, budget in SOUNDS:
        samples = fn()
        wav = os.path.join(OUT, name + ".wav")
        m4a = os.path.join(OUT, name + ".m4a")
        peak = max(abs(s) for s in samples) or 1.0
        if kind == "shot":
            gain = 10 ** (ONE_SHOT_PEAK_DBFS / 20.0) / peak
        else:
            write_wav(wav, samples, 1.0 / peak * 0.25)                     # provisional level for the loudness pass
            lufs, _, _ = measure(wav)
            gain = (1.0 / peak * 0.25) * 10 ** ((BED_LUFS - lufs) / 20.0)
            ceiling = 10 ** (BED_PEAK_CEILING_DBFS / 20.0) / peak
            gain = min(gain, ceiling)
        write_wav(wav, samples, gain)
        encode(wav, m4a)
        lufs, pk, secs = measure(m4a)
        size = os.path.getsize(m4a) / 1024
        wav_lufs, _, _ = measure(wav)
        attack = attack_time([s * gain for s in samples])
        seam = max_step_db(samples) if kind == "bed" else float("nan")
        ok = size < budget and (pk <= -9.0 if kind == "shot" else True)
        failed |= not ok
        rows.append((name, secs, pk, lufs, wav_lufs, attack, size, budget, seam, ok))

    print(f"{'file':20} {'dur s':>6} {'peak dBFS':>10} {'LUFS m4a':>9} {'LUFS wav':>9} {'attack s':>9} {'KB':>6} {'budget':>7} {'max step':>9}  ok")
    for name, secs, pk, lufs, wl, at, size, budget, seam, ok in rows:
        print(f"{name:20} {secs:6.2f} {pk:10.1f} {lufs:9.1f} {wl:9.1f} {at:9.2f} {size:6.1f} {budget:6d}K {seam:9.3f}  {'yes' if ok else 'NO'}")
    total = sum(r[6] for r in rows)
    print(f"total m4a {total:.1f} KB")
    write_index()
    if failed:
        sys.exit("a file missed its peak or size budget")


def write_index():
    items = "\n".join(
        f'<section><h2>{name}</h2><audio controls {"loop " if kind == "bed" else ""}preload="none" src="{name}.m4a"></audio>'
        f'<p>{"Loops. " if kind == "bed" else "One-shot. "}<a href="{name}.wav">wav</a></p></section>'
        for name, _, kind, _ in SOUNDS)
    html = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>WordFlora weather sounds</title>
<style>:root{{color-scheme:light dark}}body{{font:16px/1.4 -apple-system,system-ui,sans-serif;margin:0 auto;max-width:34rem;padding:16px}}
section{{border-top:1px solid #8884;padding:8px 0}}h2{{font-size:1rem;margin:.2rem 0}}audio{{width:100%}}p{{margin:.2rem 0;font-size:.85rem;opacity:.75}}</style></head>
<body><h1>Weather and Grand Garden sounds</h1>
<p>Prototype renders from tools/make_weather_sounds.py. Keep the volume low first: beds are quiet by design.</p>
{items}
</body></html>
"""
    with open(os.path.join(OUT, "index.html"), "w") as f:
        f.write(html)


if __name__ == "__main__":
    main()

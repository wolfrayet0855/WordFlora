#!/usr/bin/env python3
"""Render WordFlora's soft distant thunder roll (WordFlora/Resources/Sounds/wf-thunder.m4a).

Original and procedural: nothing is sampled, so the sound is licence clean. Pure Python 3 standard library
(no numpy); ffmpeg turns the rendered WAV into a small mono AAC file.

Recipe (see docs/research/audio-feedback.md, "Thunder"):
  1. Brown noise (leaky integrated white noise, fixed seed) with a pinch of white for air.
  2. Two hand-coded one-pole low-pass stages whose cutoff sweeps from 450 Hz down to 180 Hz, so the roll
     darkens as it moves away; two one-pole high-pass stages at 70 Hz keep the
     energy where speakers can play it.
  3. A slow amplitude envelope made of three gentle sub-rolls (raised-cosine rises of 0.5 to 0.7 s, so there
     is never a crack), a little slow random flutter for texture, and a long tail fade to silence.
  4. Peak normalised to about -9 dBFS, written as 16-bit 44.1 kHz mono WAV, encoded to AAC at 64 kb/s.

Run from the repo root:  python3 tools/make_thunder.py
"""

import math
import os
import random
import re
import struct
import subprocess
import sys
import tempfile
import wave

SEED = 20261104
RATE = 44100
DURATION = 4.6            # seconds
PEAK_DBFS = -9.0
CUTOFF_START = 450.0      # Hz
CUTOFF_END = 180.0        # Hz
HIGHPASS = 70.0           # Hz (two one-pole stages)
# Sub-rolls: (start s, rise s, peak level, decay time constant s)
ROLLS = [
    (0.00, 0.70, 0.70, 0.55),
    (0.85, 0.50, 1.00, 0.70),
    (1.95, 0.60, 0.62, 0.90),
]
TAIL_FADE = 1.2           # seconds of raised-cosine fade to silence at the end
FLUTTER_DEPTH = 0.18      # slow random amplitude wobble (0 = none)
BITRATE = "64k"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "WordFlora", "Resources", "Sounds", "wf-thunder.m4a")
FFMPEG = "/usr/local/bin/ffmpeg" if os.path.exists("/usr/local/bin/ffmpeg") else "ffmpeg"


def one_pole_coeff(fc):
    """Feedback coefficient of a one-pole low-pass y += a * (x - y)."""
    return 1.0 - math.exp(-2.0 * math.pi * fc / RATE)


def envelope(t):
    level = 0.0
    for start, rise, peak, decay in ROLLS:
        if t < start:
            continue
        u = t - start
        if u < rise:
            level += peak * 0.5 * (1.0 - math.cos(math.pi * u / rise))      # smooth, slow rise
        else:
            level += peak * math.exp(-(u - rise) / decay)
    fade_start = DURATION - TAIL_FADE
    if t > fade_start:
        level *= 0.5 * (1.0 + math.cos(math.pi * min(1.0, (t - fade_start) / TAIL_FADE)))
    return level


def render():
    rng = random.Random(SEED)
    n = int(DURATION * RATE)
    out = [0.0] * n
    brown = 0.0
    lp1 = lp2 = 0.0
    hp = [[0.0, 0.0], [0.0, 0.0]]                                # (previous x, previous y) per high-pass stage
    hp_a = math.exp(-2.0 * math.pi * HIGHPASS / RATE)
    flutter = 0.0
    flutter_target = 0.0
    flutter_a = one_pole_coeff(3.0)
    for i in range(n):
        t = i / RATE
        white = rng.uniform(-1.0, 1.0)
        brown = 0.998 * brown + 0.04 * white                     # leaky integrator: brown noise
        x = brown + 0.02 * white
        fc = CUTOFF_START * (CUTOFF_END / CUTOFF_START) ** (t / DURATION)
        a = one_pole_coeff(fc)
        lp1 += a * (x - lp1)
        lp2 += a * (lp1 - lp2)
        y = lp2
        for st in hp:                                            # one-pole high-pass, twice
            st[1] = hp_a * (st[1] + y - st[0])
            st[0] = y
            y = st[1]
        if i % 2205 == 0:                                        # new flutter target every 50 ms, smoothed below
            flutter_target = rng.uniform(-1.0, 1.0)
        flutter += flutter_a * (flutter_target - flutter)
        out[i] = y * envelope(t) * (1.0 + FLUTTER_DEPTH * flutter)
    peak = max(abs(s) for s in out) or 1.0
    gain = 10 ** (PEAK_DBFS / 20.0) / peak
    return [s * gain for s in out]


def attack_time(samples):
    """Seconds from onset (RMS 40 dB under the loudest 50 ms window) to within 6 dB of it."""
    win = int(0.05 * RATE)
    rms = []
    for i in range(0, len(samples) - win, win // 5):
        seg = samples[i:i + win]
        rms.append(math.sqrt(sum(s * s for s in seg) / win))
    top = max(rms)
    onset = next(k for k, r in enumerate(rms) if r >= top * 10 ** (-40 / 20))
    near = next(k for k, r in enumerate(rms) if r >= top * 10 ** (-6 / 20))
    return (near - onset) * (win // 5) / RATE


def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def measure(path):
    res = subprocess.run([FFMPEG, "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true,volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True)
    log = res.stderr
    lufs = re.findall(r"I:\s+(-?[\d.]+) LUFS", log)
    peak = re.findall(r"max_volume: (-?[\d.]+) dB", log)
    dur = re.search(r"Duration: (\d+):(\d+):([\d.]+)", log)
    seconds = int(dur.group(1)) * 3600 + int(dur.group(2)) * 60 + float(dur.group(3)) if dur else float("nan")
    return (float(lufs[-1]) if lufs else float("nan"), float(peak[-1]) if peak else float("nan"), seconds)


def main():
    samples = render()
    attack = attack_time(samples)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "wf-thunder.wav")
        write_wav(wav, samples)
        subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", wav, "-c:a", "aac", "-b:a", BITRATE,
                        "-ar", str(RATE), "-ac", "1", "-map_metadata", "-1", "-movflags", "+faststart", OUT], check=True)
    lufs, peak, seconds = measure(OUT)
    size = os.path.getsize(OUT)
    print(f"wrote {os.path.relpath(OUT, ROOT)}")
    print(f"duration {seconds:.2f} s, peak {peak:.1f} dBFS, integrated {lufs:.1f} LUFS, attack {attack:.2f} s, size {size / 1024:.1f} KB")
    if size >= 300 * 1024:
        sys.exit("file is over 300 KB")


if __name__ == "__main__":
    main()

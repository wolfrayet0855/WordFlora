#!/usr/bin/env python3
"""Render WordFlora's Mist Maker sound, wf-mist-hiss (a soft plant-mister spray), as WAV + bundled m4a.

Original and procedural: nothing is sampled, so it is licence clean. Pure Python 3 standard library (no numpy);
afconvert makes the bundled AAC file (same container and codec as the other bundled sounds) and ffmpeg measures
loudness. Fixed seed (6606), so two runs give an identical WAV.

  wf-mist-hiss   0.9 s  airy filtered spray: white noise, high-pass ~2.2 kHz, 24 dB/oct low-pass at 7 kHz, a gentle
                        3 to 4 dB bump around 4.5 kHz, 180 ms raised-cosine attack (a soft swell, no "pssst"
                        edge), hold to 0.30 s, exponential decay (tau 0.22 s), raised-cosine release over the
                        last 0.25 s so the file ends at zero.

Level is set here, not in the catalog (SoundCatalog gainDb 0, master 0.8 = -1.9 dB): the WAV is scaled to
about -28 LUFS in-app (IN_APP_LUFS), with the WAV peak never above -12 dBFS (PEAK_CEILING_DBFS, the spec row
"Mist" in docs/research/audio-feedback.md). Band-limited noise has a low crest factor, so a -12 dBFS peak
alone would land near -25 LUFS in-app; loudness wins and the peak sits lower. If it needs to be louder on
device, raise IN_APP_LUFS (the ceiling still holds), never the catalog gain.
Recipe and rulings: docs/pm/audio-review.md section 6, docs/pm/audio-review-rulings.md section 1.

Run from the repo root:  python3 tools/make_mist_hiss.py [out_dir]
Default out_dir is WordFlora/Resources/Sounds for the m4a; the WAV goes to tools/out/mist/ (git-ignored).
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
NAME = "wf-mist-hiss"
SEED = 6606
DURATION = 0.9
PEAK_CEILING_DBFS = -12.0
IN_APP_LUFS = -28.0
MASTER_DB = 20 * math.log10(0.8)                     # SoundCatalog master volume
SIZE_BUDGET_KB = 60

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FFMPEG = "/usr/local/bin/ffmpeg" if os.path.exists("/usr/local/bin/ffmpeg") else "ffmpeg"
TAU = 2.0 * math.pi


def lp_coeff(fc):
    return 1.0 - math.exp(-TAU * fc / RATE)


def lowpass(x, fc):
    a = lp_coeff(fc)
    s = 0.0
    out = []
    for v in x:
        s += a * (v - s)
        out.append(s)
    return out


def biquad_lowpass(x, fc, q=0.7071):
    """RBJ second-order low-pass (12 dB/oct, Butterworth at q 0.7071)."""
    w0 = TAU * fc / RATE
    al = math.sin(w0) / (2 * q)
    c = math.cos(w0)
    a0 = 1 + al
    b0 = b2 = (1 - c) / 2 / a0
    b1 = (1 - c) / a0
    a1, a2 = -2 * c / a0, (1 - al) / a0
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for v in x:
        y = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, y
        out.append(y)
    return out

def highpass(x, fc):
    return [v - l for v, l in zip(x, lowpass(x, fc))]


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


def fade_edges(buf, fi=0.0, fo=0.05):
    n = len(buf)
    a, b = int(fi * RATE), int(fo * RATE)
    for i in range(min(a, n)):
        buf[i] *= 0.5 * (1 - math.cos(math.pi * i / a))
    for i in range(min(b, n)):
        buf[n - 1 - i] *= 0.5 * (1 - math.cos(math.pi * i / b))
    return buf


def render_mist():
    rng = random.Random(SEED)
    n = int(DURATION * RATE)
    warm = int(0.05 * RATE)                                          # let the filters settle before sample 0
    white = [rng.uniform(-1, 1) for _ in range(n + warm)]
    # body: two one-pole high-passes at 2.2 kHz (no rumble, no breath), then two Butterworth biquad low-passes
    # at 7 kHz (24 dB/oct; no sharp "s" edge). One-poles at 7.5 kHz, as first drafted, leave the band above
    # 8 kHz only ~5 dB under the whole: brighter than wf-snip. The biquads put it ~14 dB under, like wf-water.
    x = highpass(highpass(white, 2200), 2200)
    x = biquad_lowpass(biquad_lowpass(x, 7000), 7000)
    # colour: 25% of a band-passed copy around 4.5 kHz, a gentle 3 to 4 dB bump
    band = lowpass(lowpass(highpass(highpass(white, 3600), 3600), 5600), 5600)
    xr = math.sqrt(sum(v * v for v in x) / len(x))
    br = math.sqrt(sum(v * v for v in band) / len(band)) or 1.0
    x = [a + 0.25 * (xr / br) * b for a, b in zip(x, band)]
    x = x[warm:]
    flutter = smooth_noise(rng, n, 14.0)                             # faint breathy flutter, kept shallow
    attack, hold, tau = 0.18, 0.30, 0.22
    out = []
    for i in range(n):
        u = i / RATE
        if u < attack:
            env = 0.5 * (1.0 - math.cos(math.pi * u / attack))
        elif u < hold:
            env = 1.0
        else:
            env = math.exp(-(u - hold) / tau)
        out.append(x[i] * env * (0.8 + 0.2 * flutter[i]))
    return fade_edges(out, 0.0, 0.25)


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


def valid_frames(m4a):
    out = subprocess.run(["afinfo", m4a], capture_output=True, text=True).stdout
    found = re.search(r"audio (\d+) valid frames", out)
    return int(found.group(1)) if found else float("nan")


def encode(wav, m4a):
    """Same as the bundled beds: AAC in an m4a container, 64 kb/s, via afconvert."""
    subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000", wav, m4a], check=True)


def main():
    if len(sys.argv) > 1:
        out_m4a_dir = out_wav_dir = os.path.abspath(sys.argv[1])
    else:
        out_m4a_dir = os.path.join(ROOT, "WordFlora", "Resources", "Sounds")
        out_wav_dir = os.path.join(ROOT, "tools", "out", "mist")
    os.makedirs(out_m4a_dir, exist_ok=True)
    os.makedirs(out_wav_dir, exist_ok=True)
    wav = os.path.join(out_wav_dir, NAME + ".wav")
    m4a = os.path.join(out_m4a_dir, NAME + ".m4a")

    samples = render_mist()
    peak = max(abs(s) for s in samples) or 1.0
    ceiling = 10 ** (PEAK_CEILING_DBFS / 20.0) / peak
    write_wav(wav, samples, ceiling)                                 # provisional level for the loudness pass
    probe, _, _ = measure(wav)
    gain = min(ceiling, ceiling * 10 ** ((IN_APP_LUFS - MASTER_DB - probe) / 20.0))
    write_wav(wav, samples, gain)
    if os.path.exists(m4a):
        os.remove(m4a)
    encode(wav, m4a)

    lufs, pk, _ = measure(m4a)
    wav_lufs, wav_pk, _ = measure(wav)
    secs = valid_frames(m4a) / RATE                                  # afinfo: exact length without AAC priming
    size = os.path.getsize(m4a) / 1024
    attack = attack_time([s * gain for s in samples])
    tail = max(abs(s * gain) for s in samples[-int(0.01 * RATE):])
    in_app = lufs + MASTER_DB                                        # gainDb 0
    ok = pk <= -11.0 and attack >= 0.06 and size < SIZE_BUDGET_KB and abs(secs - DURATION) < 0.05 and tail < 1e-3
    print(f"{'file':14} {'dur s':>6} {'peak m4a':>9} {'peak wav':>9} {'LUFS m4a':>9} {'LUFS wav':>9} {'in-app':>7} {'attack s':>9} {'KB':>6}  ok")
    print(f"{NAME:14} {secs:6.2f} {pk:9.1f} {wav_pk:9.1f} {lufs:9.1f} {wav_lufs:9.1f} {in_app:7.1f} {attack:9.2f} {size:6.1f}  {'yes' if ok else 'NO'}")
    print(f"wrote {m4a}\nwrote {wav}")
    if not ok:
        sys.exit("wf-mist-hiss missed a pass criterion (m4a peak <= -11 dBFS, attack >= 0.06 s, 0.9 s, < 60 KB, ends at zero)")


if __name__ == "__main__":
    main()

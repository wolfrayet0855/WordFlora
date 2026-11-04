"""Render PNGs of the direction-B SVGs with headless Chromium.

Needs the static server on http://localhost:8765/ (serving design-preview/) and Pillow.
    python render.py
Output: png/ next to this file.
"""
import os, re, subprocess
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'png'); os.makedirs(OUT, exist_ok=True)
CH = '/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium'

def shot(name, svg, w, h, bg=''):
    tmp = os.path.join(OUT, name + '.tmp.png')
    url = 'http://localhost:8765/logo/b/render.html?v=%s&size=%d&h=%d&bg=%s' % (svg, w, h, bg)
    subprocess.run([CH, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--window-size=%d,%d' % (max(w, 200), h + 200), '--screenshot=' + tmp, url],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    Image.open(tmp).crop((0, 0, w, h)).save(os.path.join(OUT, name + '.png')); os.remove(tmp)

def aspect(svg):
    vb = re.search(r'viewBox="([^"]+)"', open(os.path.join(HERE, svg + '.svg')).read()).group(1).split()
    return float(vb[3]) / float(vb[2])

if __name__ == '__main__':
    for s in (1024, 180, 60, 29):
        for v in ('icon', 'icon-dark', 'icon-tinted'):
            shot('%s-%d' % (v, s), v, s, s)
    BG = {'': 'FAF7F0', '-dark': '1A2E1A', '-mono': 'FFFFFF'}
    for base in ('wordmark', 'wordmark-twin', 'wordmark-solo'):
        for sfx, bg in BG.items():
            for w in (320, 120):
                svg = base + sfx
                shot('%s-%d' % (svg, w), svg, w, round(w * aspect(svg)), bg)
    print('rendered to', OUT)

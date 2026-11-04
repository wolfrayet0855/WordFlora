"""Render PNGs for final/ (wordmarks) and ../icon/ (icon candidate) with headless Chromium.
Loads render.html over file:// (no server needed); needs Pillow.
    python render.py [wordmark|icon|all]
"""
import os, re, subprocess, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ICON_DIR = os.path.normpath(os.path.join(HERE, '..', 'icon'))
CH = '/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium'

def shot(out, svg, w, h, bg=''):
    tmp = out + '.tmp.png'
    url = 'file://%s/render.html?v=%s&size=%d&h=%d&bg=%s' % (HERE, svg, w, h, bg)
    subprocess.run([CH, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files', '--force-device-scale-factor=1',
                    '--window-size=%d,%d' % (max(w, 200), h + 200), '--screenshot=' + tmp, url],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    Image.open(tmp).crop((0, 0, w, h)).save(out); os.remove(tmp)

def aspect(path):
    vb = re.search(r'viewBox="([^"]+)"', open(path).read()).group(1).split()
    return float(vb[3]) / float(vb[2])

if __name__ == '__main__':
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if what in ('wordmark', 'all'):
        os.makedirs(os.path.join(HERE, 'png'), exist_ok=True)
        for name, bg in (('wordmark', 'FAF7F0'), ('wordmark-dark', '1A2E1A'), ('wordmark-solo', 'FAF7F0'),
                         ('wordmark-solo-dark', '1A2E1A'), ('wordmark-mono', 'FFFFFF'), ('wordmark-solo-mono', 'FFFFFF'),
                         ('wordmark-mono-solid', 'FFFFFF')):
            a = aspect(os.path.join(HERE, name + '.svg'))
            for w in (320, 120):
                shot(os.path.join(HERE, 'png', '%s-%d.png' % (name, w)), name, w, round(w * a), bg)
    if what in ('icon', 'all'):
        os.makedirs(os.path.join(ICON_DIR, 'png'), exist_ok=True)
        for name in ('icon', 'icon-dark', 'icon-tinted'):
            for s in (1024, 180, 60, 29):
                shot(os.path.join(ICON_DIR, 'png', '%s-%d.png' % (name, s)), '../icon/' + name, s, s)
    print('rendered')

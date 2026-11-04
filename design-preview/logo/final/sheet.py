"""Before/after comparison sheets for the wordmark touch-up (no server needed: file:// + headless Chromium).
    python sheet.py            -> compare/sheet-{light,dark,mono,solo}.png and compare/tiny-zoom.png
Before = v1/*.svg (the original "B uncut" files), after = ./*.svg.
Sizes: logo height 29 px and 60 px at 1x, Home at 1x (172 px wide), Home at 3x (516 px wide), and a large detail.
"""
import os, subprocess, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'compare')
CH = '/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium'
SETS = {
  'light': (('wordmark', 'wordmark-solo'), '#FAF7F0', '#2C3E2C'),
  'dark':  (('wordmark-dark', 'wordmark-solo-dark'), '#1A2E1A', '#D4EDD4'),
  'mono':  (('wordmark-mono', 'wordmark-mono-solid', 'wordmark-solo-mono'), '#FFFFFF', '#2C3E2C'),
}

def page(names, bg, fg):
    rows = []
    for n in names:
        for tag, src in (('before', 'v1/%s.svg' % n), ('after', '%s.svg' % n)):
            cells = ''.join('<div class="c"><img src="%s" style="%s"><span>%s</span></div>' % (src, st, lab)
                            for st, lab in (('height:29px', '29 px tall'), ('height:60px', '60 px tall'),
                                            ('width:172px', 'Home 1x'), ('width:516px', 'Home 3x')))
            rows.append('<div class="r"><b>%s<br>%s</b>%s</div>' % (n, tag, cells))
        rows.append('<div class="r"><b>%s detail</b><img src="v1/%s.svg" style="width:860px"><img src="%s.svg" style="width:860px"></div>' % (n, n, n))
    return ('<!doctype html><meta charset="utf-8"><style>body{margin:0;padding:16px;background:%s;color:%s;font:12px -apple-system,sans-serif;width:1960px}'
            '.r{display:flex;align-items:center;gap:28px;padding:10px 0;border-bottom:1px solid %s33}.r b{width:150px;flex:none}'
            '.c{display:flex;flex-direction:column;align-items:flex-start;gap:4px}span{opacity:.6}img{display:block}</style>%s') % (bg, fg, fg, ''.join(rows))

def shoot(html, png, h, dsf=1):
    p = os.path.join(HERE, '_sheet.html'); open(p, 'w').write(html)
    subprocess.run([CH, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
                    '--force-device-scale-factor=%d' % dsf, '--window-size=1992,%d' % h, '--screenshot=' + png,
                    'file://' + p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.remove(p)

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for k, (names, bg, fg) in SETS.items():
        shoot(page(names, bg, fg), os.path.join(OUT, 'sheet-%s.png' % k), 480 * len(names) + 80)
    # tiny sizes, pixel-exact at 1x then enlarged 4x (nearest) so they can be inspected
    cells = []
    for n, bg in (('wordmark', '#FAF7F0'), ('wordmark-dark', '#1A2E1A'), ('wordmark-solo', '#FAF7F0'),
                  ('wordmark-solo-dark', '#1A2E1A'), ('wordmark-mono-solid', '#FFFFFF')):
        for d in ('v1/', ''):
            cells.append('<div style="background:%s;padding:6px;display:flex;gap:10px;align-items:center">'
                         '<img src="%s%s.svg" style="height:29px"><img src="%s%s.svg" style="height:60px"></div>' % (bg, d, n, d, n))
    html = '<!doctype html><style>body{margin:0;width:560px}img{display:block}</style>' + ''.join(cells)
    tmp = os.path.join(OUT, '_tiny.png'); shoot(html, tmp, 10 * 80)
    im = Image.open(tmp); im = im.crop((0, 0, 560, 10 * 72 + 8)); im.resize((im.width * 3, im.height * 3), Image.NEAREST).save(os.path.join(OUT, 'tiny-zoom.png'))
    os.remove(tmp)
    print('sheets in', OUT)

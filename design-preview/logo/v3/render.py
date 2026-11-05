"""Render every v3 PNG and the before/after sheets with headless Chromium over file:// (no server).

    python render.py [--direction hero|unified|centre|all] [--only png|compare|check]

Each variant is laid out once on a temporary page (every size at exact pixel positions, flat
background), screenshotted at device scale 1 with --force-color-profile=srgb, cropped with Pillow and
saved WITHOUT an ICC profile, so the stored pixels are the SVG hex values (round 2, review A section 0).
`--only check` re-runs the pixel checks (sRGB fills, sheet margins, ring gap and slit pixels).
"""
import argparse, json, os, re, subprocess
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
CH = '/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium'
FLAGS = ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
         '--force-device-scale-factor=1', '--force-color-profile=srgb']
DIRECTIONS = ('hero', 'unified', 'centre')
BG = {'light': '#FAF7F0', 'dark': '#1A2E1A', 'mono': '#FFFFFF'}
WORDMARKS = (('wordmark', 'light'), ('wordmark-dark', 'dark'), ('wordmark-mono', 'mono'), ('wordmark-mono-solid', 'mono'),
             ('wordmark-solo', 'light'), ('wordmark-solo-dark', 'dark'), ('wordmark-solo-mono', 'mono'))
HEIGHTS = (320, 172, 120, 60, 29)
SHIPPING = os.path.normpath(os.path.join(HERE, '..', '..', '..', 'WordFlora', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-default.png'))
V2 = os.path.normpath(os.path.join(HERE, '..', 'final'))
V2_ICON = os.path.normpath(os.path.join(HERE, '..', 'icon', 'icon.svg'))

def meas(d): return json.load(open(os.path.join(HERE, d, 'measurements.json')))

def aspect(path):
    vb = re.search(r'viewBox="([^"]+)"', open(path).read()).group(1).split()
    return float(vb[2]) / float(vb[3])

def save(im, path):
    """plain sRGB PNG, no ICC profile, no gamma chunk"""
    im = im.convert('RGB'); im.info.clear()
    im.save(path, optimize=True, icc_profile=None)

def shoot(html, w, h, out):
    tmp_html = os.path.join(HERE, '_render_tmp.html'); tmp_png = out + '.tmp.png'
    open(tmp_html, 'w').write(html)
    subprocess.run([CH] + FLAGS + ['--window-size=%d,%d' % (max(w, 200), h + 200), '--screenshot=' + tmp_png, 'file://' + tmp_html],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.remove(tmp_html)
    im = Image.open(tmp_png); im.load(); im = im.convert('RGB'); im.info.clear(); os.remove(tmp_png)
    return im

def page(cells, bg, w, h):
    """cells: list of (src, x, y, w, h)"""
    body = ''.join('<img src="%s" style="position:absolute;left:%dpx;top:%dpx;width:%dpx;height:%dpx">' % c for c in cells)
    return ('<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;overflow:hidden;background:%s;'
            'width:%dpx;height:%dpx}img{display:block}</style>%s' % (bg, w, h, body))

def render_pngs(d):
    src_dir = os.path.join(HERE, d); out = os.path.join(src_dir, 'png'); os.makedirs(out, exist_ok=True)
    for name, mode in WORDMARKS:
        svgp = os.path.join(src_dir, name + '.svg'); a = aspect(svgp)
        jobs = [('h%d' % h, round(h * a), h) for h in HEIGHTS] + [('w172', 172, round(172 / a))]
        cells, y, W = [], 0, 0
        for tag, w, h in jobs:
            cells.append(('file://' + svgp, 0, y, w, h)); y += h + 10; W = max(W, w)
        im = shoot(page(cells, BG[mode], W, y), W, y, os.path.join(out, name))
        for (tag, w, h), c in zip(jobs, cells):
            save(im.crop((0, c[2], w, c[2] + h)), os.path.join(out, '%s-%s.png' % (name, tag)))
    for st, (name, sizes) in meas(d)['icon_files'].items():
        svgp = os.path.join(src_dir, name + '.svg')
        cells, y = [], 0
        for s in sizes:
            cells.append(('file://' + svgp, 0, y, s, s)); y += s + 10
        W = max(sizes)
        im = shoot(page(cells, '#808080', W, y), W, y, os.path.join(out, name))
        for s, c in zip(sizes, cells):
            save(im.crop((0, c[2], s, c[2] + s)), os.path.join(out, '%s-%d.png' % (name, s)))

# ------------------------------------------------------------- before / after sheets
CSS = ('html,body{margin:0;padding:0}body{background:%s;color:%s;font:600 15px -apple-system,Helvetica,sans-serif;padding:24px;width:max-content}'
       'h1{font-size:20px;margin:0 0 4px}h2{font-size:16px;margin:26px 0 4px}p{margin:0 0 18px;opacity:.7;font-weight:500}'
       '.row{display:flex;align-items:center;gap:40px;padding:16px 0;border-top:1px solid %s33}'
       '.lab{width:150px;flex:none}.lab small{display:block;opacity:.6;font-weight:500}'
       '.cell{display:flex;flex-direction:column;gap:6px}.cell span{font-size:12px;opacity:.6}img{display:block}'
       '.crop{overflow:hidden}')

def path_xs(svg_path, fill):
    """min and max x of the path with this fill (SVGPathPen output: absolute coordinate pairs)"""
    s = open(svg_path).read()
    m = re.search(r'<path fill="%s"[^>]* d="([^"]+)"' % re.escape(fill), s)
    from fontTools.svgLib.path import parse_path
    from fontTools.pens.boundsPen import BoundsPen
    bp = BoundsPen(None); parse_path(m.group(1), bp)
    return bp.bounds[0], bp.bounds[2]

def word_crop(svg_path, word_fill, flora_fill, k):
    """html for "Word" alone, cut halfway between the d and the F, at k px per font unit"""
    vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', open(svg_path).read()).group(1).split()]
    w0, w1 = path_xs(svg_path, word_fill); f0, _ = path_xs(svg_path, flora_fill)
    cut = (w1 + f0) / 2
    return ('<div class="crop" style="width:%dpx;height:%dpx"><img src="file://%s" style="height:%dpx;width:%dpx"></div>'
            % (round((cut - vb[0]) * k), round(vb[3] * k), svg_path, round(vb[3] * k), round(vb[2] * k))), w1 - w0

def word_rows(d, k=0.32):
    v2h, v2w = word_crop(os.path.join(V2, 'wordmark.svg'), '#2C3E2C', '#2A7A38', k)
    v3h, v3w = word_crop(os.path.join(HERE, d, 'wordmark.svg'), '#182818', '#2E803F', k)
    return ('<h2>"Word" alone, same scale (%.2f px per font unit, so the letters are the same size)</h2>'
            '<p>Ink width of "Word": v2 %d u, v3 %d u (%+.1f%%).</p>'
            '<div class="row"><div class="lab">v2 (final)</div>%s</div><div class="row"><div class="lab">v3 %s</div>%s</div>'
            '<h2>Whole word, same scale, so the rhythm can be judged across "WordFlora"</h2>'
            '<div class="row"><div class="lab">v2 (final)</div>%s</div><div class="row"><div class="lab">v3 %s</div>%s</div>'
            % (k, v2w, v3w, 100 * (v3w / v2w - 1), v2h, d, v3h, full_img(os.path.join(V2, 'wordmark.svg'), k), d,
               full_img(os.path.join(HERE, d, 'wordmark.svg'), k))), v2w, v3w

def full_img(svg_path, k):
    vb = [float(v) for v in re.search(r'viewBox="([^"]+)"', open(svg_path).read()).group(1).split()]
    return '<img src="file://%s" style="height:%dpx;width:%dpx">' % (svg_path, round(vb[3] * k), round(vb[2] * k))

def ba_sheet(d, mode):
    fg = '#182818' if mode == 'light' else '#DCEEDC'
    suffix = '' if mode == 'light' else '-dark'
    rows = []
    for lab, style in (('29 px tall', 'height:29px'), ('60 px tall', 'height:60px'), ('172 px wide', 'width:172px'),
                       ('320 px tall', 'height:320px')):
        rows.append('<div class="row"><div class="lab">%s<small>wordmark%s</small></div>'
                    '<div class="cell"><img src="file://%s/wordmark%s.svg" style="%s"><span>v2 (final)</span></div>'
                    '<div class="cell"><img src="file://%s/%s/wordmark%s.svg" style="%s"><span>v3 %s</span></div></div>'
                    % (lab, suffix, V2, suffix, style, HERE, d, suffix, style, d))
    for lab, style in (('29 px tall', 'height:29px'), ('60 px tall', 'height:60px')):
        rows.append('<div class="row"><div class="lab">%s<small>solo%s</small></div>'
                    '<div class="cell"><img src="file://%s/wordmark-solo%s.svg" style="%s"><span>v2 solo</span></div>'
                    '<div class="cell"><img src="file://%s/%s/wordmark-solo%s.svg" style="%s"><span>v3 %s solo</span></div></div>'
                    % (lab, suffix, V2, suffix, style, HERE, d, suffix, style, d))
    extra = word_rows(d)[0] if mode == 'light' else ''
    return ('<!doctype html><meta charset="utf-8"><style>%s</style><h1>WordFlora logo: v2 (left) vs v3 %s (right), %s</h1>'
            '<p>Actual pixels at device scale 1, sRGB. v2 = design-preview/logo/final, v3 = design-preview/logo/v3/%s (round 2).</p>%s%s'
            % (CSS % (BG[mode], fg, fg), d, mode, d, ''.join(rows), extra))

def icon_sheet(d):
    files = meas(d)['icon_files']
    sets = [('Shipping', 'AppIcon-default.png', 'file://' + SHIPPING), ('v2 candidate', 'logo/icon/icon.svg', 'file://' + V2_ICON)]
    for st, (name, sizes) in files.items():
        sets.append(('v3 %s %s' % (d, st), name + '.svg', 'file://%s/%s/%s.svg' % (HERE, d, name)))
    rows = []
    for lab, sub, src in sets:
        cells = ''.join('<div class="cell"><img src="%s" style="width:%dpx;height:%dpx;border-radius:%dpx"><span>%d px</span></div>'
                        % (src, s, s, round(s * 0.2237), s) for s in (180, 60, 29))
        rows.append('<div class="row"><div class="lab">%s<small>%s</small></div>%s</div>' % (lab, sub, cells))
    return ('<!doctype html><meta charset="utf-8"><style>%s</style><h1>App icon: shipping, v2 candidate, v3 %s</h1>'
            '<p>180 / 60 / 29 px, actual pixels, sRGB, iOS corner mask approximated with border-radius.</p>%s'
            % (CSS % ('#F2F2F2', '#182818', '#182818'), d, ''.join(rows))), len(sets)

def full_shot(html, out, w, h):
    im = shoot(html, w, h, out)
    bg = im.getpixel((w - 1, h - 1))
    px = im.load(); W, H = im.size
    right = max((x for x in range(W - 1, 0, -2) if any(px[x, y] != bg for y in range(0, H, 2))), default=W - 1)
    bottom = max((y for y in range(H - 1, 0, -4) if any(px[x, y] != bg for x in range(0, W, 4))), default=H - 1)
    if right > W - 40: raise SystemExit('sheet clipped: %s (last ink column %d of %d)' % (out, right, W))
    save(im.crop((0, 0, min(W, right + 40), min(H, bottom + 32))), out)

def render_compare(d):
    out = os.path.join(HERE, d, 'compare'); os.makedirs(out, exist_ok=True)
    for mode in ('light', 'dark'):
        full_shot(ba_sheet(d, mode), os.path.join(out, 'before-after-%s.png' % mode), 4600, 2700 if mode == 'light' else 1900)
    html, n = icon_sheet(d)
    full_shot(html, os.path.join(out, 'icon-before-after.png'), 900, 140 + 236 * n)
    wr, v2w, v3w = word_rows(d)
    full_shot('<!doctype html><meta charset="utf-8"><style>%s</style>%s' % (CSS % (BG['light'], '#182818', '#182818'), wr),
              os.path.join(out, 'word-alone-320.png'), 2400, 1700)

# ------------------------------------------------------------- pixel checks
def hexrgb(h): h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def check(d):
    M = meas(d); ok = True; lines = []
    png = lambda n: os.path.join(HERE, d, 'png', n)
    # P1: stored pixels are the SVG hex, no ICC profile
    im = Image.open(png('wordmark-h320.png'))
    icc = im.info.get('icc_profile')
    cols = {c for _, c in im.convert('RGB').getcolors(1 << 20)}
    for key in ('flora', 'petal', 'word', 'bg'):
        want = hexrgb(M['palette']['light'][key]); hit = want in cols
        ok &= hit; lines.append('P1 %s %s exact in wordmark-h320: %s' % (key, M['palette']['light'][key], hit))
    lines.append('P1 icc_profile: %s' % ('none' if not icc else '%d bytes' % len(icc))); ok &= not icc
    # P2: sheets keep 20 px of margin after the last ink column
    for n in ('before-after-light.png', 'before-after-dark.png', 'icon-before-after.png', 'word-alone-320.png'):
        s = Image.open(os.path.join(HERE, d, 'compare', n)).convert('RGB'); W, H = s.size; bgc = s.getpixel((W - 1, H - 1)); p = s.load()
        last = max((x for x in range(W - 1, 0, -1) if any(p[x, y] != bgc for y in range(0, H, 2))), default=0)
        good = W - 1 - last >= 20; ok &= good; lines.append('P2 %s last ink column %d of %d: %s' % (n, last, W, good))
    # P4: rows through the o centre on mono-solid-h29 show a near-background pixel each side of the ring
    T = M['marks']['mono-solid']; vb = T['vb']; s29 = Image.open(png('wordmark-mono-solid-h29.png')).convert('L'); p = s29.load()
    k = 29.0 / vb[3]; cx = (T['o_centre'][0] - vb[0]) * k; cy = (T['o_centre'][1] - vb[1]) * k
    for y in (int(cy), int(cy) + 1):
        for sgn, side in ((-1, 'left'), (1, 'right')):
            x = int(round(cx)); state = 'counter'; best = 0
            for _ in range(14):
                x += sgn; v = p[x, y]
                if state == 'counter' and v < 128: state = 'ring'
                elif state == 'ring' and v >= 128: state = 'gap'; best = v
                elif state == 'gap':
                    if v < 128: break
                    best = max(best, v)
            good = best >= 224; ok &= good
            lines.append('P4 mono-solid-h29 row %d %s of ring: brightest gap pixel %d (>= 224): %s' % (y, side, best, good))
    # U3: slits; every bisector between lobes reaches a near-background pixel at 29 px
    if M['geometry'].get('slits'):
        import math
        rot = M['geometry']['rot']
        for i in range(5):
            a = math.radians(rot + i * 72 + 36); best = 0
            r0 = 264 + T['gap_units']              # just outside the ring gap, where the lobes would otherwise fuse
            for rr in range(int(r0), int(r0) + 70, 2):
                xx = min(max(int(round(cx + math.sin(a) * rr * k)), 0), s29.width - 1)
                yy = min(max(int(round(cy - math.cos(a) * rr * k)), 0), s29.height - 1)
                best = max(best, p[xx, yy])
            good = best >= 224; ok &= good
            lines.append('U3 bisector %d brightest pixel between lobes at 29 px: %d (>= 224): %s' % (i + 1, best, good))
    print('\n'.join('  ' + l for l in lines)); print('  %s checks: %s' % (d, 'ALL PASS' if ok else 'SOME FAIL'))
    json.dump(dict(ok=ok, lines=lines), open(os.path.join(HERE, d, 'compare', 'pixel-checks.json'), 'w'), indent=1)
    return ok

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--direction', default='all'); ap.add_argument('--only', default='all')
    a = ap.parse_args()
    for d in (DIRECTIONS if a.direction == 'all' else (a.direction,)):
        if a.only in ('all', 'png'): render_pngs(d)
        if a.only in ('all', 'compare'): render_compare(d)
        if a.only in ('all', 'check'): check(d)
        print('rendered', d)

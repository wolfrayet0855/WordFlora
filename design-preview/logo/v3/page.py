"""Write v3/index.html (comparison page for the three directions) from <direction>/measurements.json.
    python page.py
Plain HTML, relative paths only, no external resources. Also copies the shipping icon into ref/ so the
page works when design-preview/ is served on :8765 (the asset catalog sits outside that root).
"""
import json, os, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
DIRS = ('hero', 'unified', 'centre')
SHIP = os.path.normpath(os.path.join(HERE, '..', '..', '..', 'WordFlora', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-default.png'))
BLURB = {
  'hero': 'Plain ink-green "Word"; one large five-petal rose flower with separate teardrop petals on the Flora o. The icon is that same flower on deep green: gold centre disc (the o with its counter filled) and a round amber pistil. Owner options: the same icon with the two-dot-one-arc face, and the cream-ground version.',
  'unified': 'One flower for the whole brand: five round amber petals around an o-shaped centre. In type the centre is the letter o; in the icon the roles invert (cream petals, amber centre) and the centre wears the face, tilted with the bloom. The face never goes inside a letter.',
  'centre': 'A solid rose bloom disc with five clear scallops behind a plain green Flora o, so the flower reads as one shape at 29 px. The icon is the same bloom with a smaller amber centre disc and a round pistil.',
}
ROUND2 = {
  'hero': 'Round 2: sRGB PNGs; icon centre is now a filled gold disc with a round pistil on deep green (cream version kept as icon-alt-cream); new icon-smile option; ring gap 40 to 52 u (mono-solid 60 u); petals that would reach the l or r are scaled to fit instead of cut, so every tip stays round; spacing solved on two bands with a 60 u F-l arm gap. Round 2b: re-spaced to the corrected A6 rule (native r-d reference; F-l up to +30%, arm gap 45 u); "Word" 6.9% narrower than v2; flower scaled to 0.92 so every petal stays at least 80% visible.',
  'unified': 'Round 2: sRGB PNGs; icon roles inverted (cream petals, amber centre, face tilted -8 degrees) to step away from Flowey; light bloom #C27200 to orange #C86800; mono-solid gets five radial slits; ring gap 52 u (mono-solid 60 u); two-band spacing with a 60 u F-l arm gap. Round 2b: re-spaced to the corrected A6 rule (native r-d reference; F-l up to +30%, arm gap 45 u); "Word" 6.9% narrower than v2; flower scaled to 0.92 so every petal stays at least 80% visible.',
  'centre': 'Round 2: sRGB PNGs; the o ring is Flora green again (no third colour); bloom rebuilt from 215 u circles on a 270 u circle, turned -8 degrees, notches about 7.5 px at 60 px; icon centre scaled to 0.75 with a filled disc and round pistil, tinted centre mid-grey; ring gap 52 u (mono-solid 60 u); two-band spacing. Round 2b: re-spaced to the corrected A6 rule (native r-d reference; F-l up to +30%, arm gap 45 u); "Word" 6.9% narrower than v2; flower scaled to 0.91 so every petal stays at least 80% visible.',
}

def esc(s): return s.replace('&', '&amp;').replace('<', '&lt;')

def png(d, name, tag, w=None, h=None, alt=''):
    dim = (' width="%d"' % w if w else '') + (' height="%d"' % h if h else '')
    return '<img src="%s/png/%s-%s.png"%s alt="%s">' % (d, name, tag, dim, alt)

def row(d, name, label, bgc, M):
    a = M['aspect']
    cells = [(png(d, name, 'h29', round(29 * a), 29), '29 px tall'), (png(d, name, 'h60', round(60 * a), 60), '60 px tall'),
             (png(d, name, 'w172', 172, round(172 / a)), '172 px wide (Home)'),
             ]
    big = '<figure class="bigf"><div class="bigs"><img class="big" src="%s/%s.svg" alt=""></div><figcaption>320 px tall (SVG; opens at the Flora end, scroll left for Word)</figcaption></figure>' % (d, name)
    return ('<div class="vrow"><div class="vlab">%s</div><div class="cells %s">%s%s</div></div>'
            % (label, bgc, ''.join('<figure>%s<figcaption>%s</figcaption></figure>' % c for c in cells), big))

def section(d):
    m = json.load(open(os.path.join(HERE, d, 'measurements.json')))
    T, S = m['marks']['twin'], m['marks']['solo']
    con = {r['name']: r['ratio'] for r in m['contrast']}
    cvd_min_pet = min(c['petal_bg'] for c in m['cvd']); cvd_min_split = min(c['split'] for c in m['cvd'])
    rows = ''.join(row(d, n, l, b, T) for n, l, b in (('wordmark', 'Light', 'bl'), ('wordmark-dark', 'Dark', 'bd'),
                                                   ('wordmark-mono', 'Mono', 'bm'), ('wordmark-mono-solid', 'Mono-solid<br><small>Increase Contrast</small>', 'bm')))
    solo = ''.join(row(d, n, l, b, S) for n, l, b in (('wordmark-solo', 'Solo light', 'bl'), ('wordmark-solo-dark', 'Solo dark', 'bd'),
                                                   ('wordmark-solo-mono', 'Solo mono', 'bm')))
    icons = []
    labels = {'light': 'v3 default', 'dark': 'v3 dark', 'tinted': 'v3 tinted', 'alt-cream': 'v3 cream ground<br><small>owner option</small>',
              'smile': 'v3 with smile<br><small>owner option</small>', 'smile-dark': 'v3 smile dark', 'smile-tinted': 'v3 smile tinted'}
    for lab, src in [('Shipping', 'ref/shipping-icon-1024.png'), ('v2 candidate', '../icon/icon.svg')] + \
                    [(labels[st], '%s/%s.svg' % (d, f[0])) for st, f in m['icon_files'].items()]:
        icons.append('<div class="irow"><div class="vlab">%s</div>%s</div>' % (lab, ''.join(
            '<figure><img class="ic" src="%s" width="%d" height="%d" style="border-radius:%dpx" alt=""><figcaption>%d</figcaption></figure>'
            % (src, s, s, round(s * 0.2237), s) for s in (180, 60, 29))))
    pairs = ' '.join('%s %+.0f%%' % (p['pair'], p['dev']) for p in T['pairs'])
    nums = [
        ('Petals on cream / on dark (A1)', '%.2f / %.2f' % (con['Petals on cream (light)'], con['Petals on dark'])),
        ('Worst CVD: petals on dark', '%.2f' % min(c['petal_bg_dark'] for c in m['cvd'])),
        ('Petals vs ring, light; ring gap at 29 px (A2)', '%.2f; %d u = %.2f px' % (con['Petals vs ring (light)'], T['gap_units'], T['gap_px_29'])),
        ('Word vs Flora light / dark (A4)', '%.2f / %.2f' % (con['Word vs Flora (light)'], con['Word vs Flora (dark)'])),
        ('Worst CVD: petals on cream; Word/Flora (A5)', '%.2f; %.2f' % (cvd_min_pet, cvd_min_split)),
        ('Letter pairs vs native r-d, x band (A6, F-l exempt; <= 15%%)', '%s (worst except F-l %.1f%%)' % (pairs, T['worst_dev'])),
        ('Letter pairs vs native r-d, full o band (A6; <= 20%%)', '%s (worst except F-l %.1f%%)' % (' '.join('%s %+.0f%%' % (p['pair'], p['dev']) for p in T['pairs_o']), T['worst_dev_o'])),
        ('F-l vs native r-d, x / o (<= +30%%)', '%+.1f%% / %+.1f%%' % (T['fl_dev'], T['fl_dev_o'])),
        ('"Word" ink width vs v2 (2853 u)', '%.0f u (%+.1f%%)' % (T['word_ink'], 100 * (T['word_ink'] / 2852.8 - 1))),
        ('F-l arm gap (min)', '%d u' % T['fl_min']),
        ('Least-visible petal, twin / solo / mono-solid (>= 80%%)', ' / '.join('%.0f%%' % (100 * min(m['marks'][k]['petal_visible'])) for k in ('twin', 'solo', 'mono-solid'))),
        ('Petal width at 29 px tall (A3, >= 4 px)', '%.1f px' % min(T['petal_width_px29'])),
        ('Aspect; height at 172 / 262 pt wide (A10)', '%.2f : 1; %.1f / %.1f pt' % (T['aspect'], T['h172'], T['h262'])),
    ]
    table = ''.join('<tr><td>%s</td><td><b>%s</b></td></tr>' % (a, b) for a, b in nums)
    return ('<section id="%s"><h2>%s <span class="muted">(%s)</span></h2><p>%s</p><p class="r2">%s</p>'
            '<div class="card hero-img"><img class="on-light" src="%s/wordmark.svg" alt="WordFlora"><img class="on-dark" src="%s/wordmark-dark.svg" alt="WordFlora"></div>'
            '<h3>Key numbers</h3><div class="card tw"><table>%s</table><p class="muted">Full tables and the A1 to A13 self-check: <a href="%s/notes.md">%s/notes.md</a>.</p></div>'
            '<h3>Wordmark: light, dark, mono, Increase Contrast</h3><div class="card">%s</div>'
            '<h3>Solo lockup (below 130 pt wide)</h3><div class="card">%s</div>'
            '<h3>App icon next to the shipping icon and v2</h3><div class="card scroll">%s</div>'
            '<h3>"Word" alone at 320 px, v2 above v3, same letter size</h3><div class="card scroll"><img src="%s/compare/word-alone-320.png" alt="Word alone, v2 and v3"></div>'
            '<h3>Before / after sheets</h3><div class="sheets">'
            '<a href="%s/compare/before-after-light.png"><img src="%s/compare/before-after-light.png" alt="before and after, light"></a>'
            '<a href="%s/compare/before-after-dark.png"><img src="%s/compare/before-after-dark.png" alt="before and after, dark"></a>'
            '<a href="%s/compare/icon-before-after.png"><img src="%s/compare/icon-before-after.png" alt="icon before and after"></a></div></section>'
            % (d, esc(m['title']), d, esc(BLURB[d]), esc(ROUND2[d]), d, d, table, d, d, rows, solo, ''.join(icons), d, d, d, d, d, d, d))

CSS = '''
:root{--bg:#FAF7F0;--surface:#FFFFFF;--text:#182818;--muted:#5E6B5E;--line:#E3DED2}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#132013;--surface:#1A2E1A;--text:#DCEEDC;--muted:#9FB59F;--line:#2C452C}}
:root[data-theme=dark]{--bg:#132013;--surface:#1A2E1A;--text:#DCEEDC;--muted:#9FB59F;--line:#2C452C}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;padding:0 16px 64px}
.wrap{max-width:1180px;margin:0 auto}header{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:20px 0 4px}
h1{font-size:22px;margin:0}h2{font-size:20px;margin:48px 0 6px;padding-top:16px;border-top:2px solid var(--line)}h3{font-size:13px;text-transform:uppercase;letter-spacing:1.2px;color:var(--muted);margin:26px 0 8px}
.muted{color:var(--muted);font-weight:500}a{color:inherit}nav a{margin-right:14px;font-weight:700}
.card{background:var(--surface);border:1px solid var(--line);border-radius:16px;padding:14px}
.scroll{overflow-x:auto}.hero-img{display:flex;justify-content:center;padding:28px 16px}.hero-img img{width:min(620px,100%)}
.on-dark{display:none}@media (prefers-color-scheme:dark){:root:not([data-theme=light]) .on-light{display:none}:root:not([data-theme=light]) .on-dark{display:block}}
:root[data-theme=dark] .on-light{display:none}:root[data-theme=dark] .on-dark{display:block}
.vrow{display:flex;align-items:center;gap:14px;padding:8px 0;border-bottom:1px solid var(--line)}.irow{display:flex;align-items:center;gap:14px;padding:8px 0;border-bottom:1px solid var(--line);min-width:max-content}
@media (max-width:640px){.vrow{flex-direction:column;align-items:stretch}}.vlab{width:110px;flex:none;font-weight:700;font-size:14px}.vlab small{font-weight:500;color:var(--muted)}
.cells{display:flex;flex-wrap:wrap;align-items:flex-end;gap:18px 22px;padding:10px 12px;border-radius:10px;min-width:0;flex:1}.bigf{flex-basis:100%;min-width:0}.bigs{overflow-x:auto;direction:rtl}.bigs img{direction:ltr}.bl{background:#FAF7F0}.bd{background:#1A2E1A}.bm{background:#FFF}
figure{margin:0;display:flex;flex-direction:column;gap:4px}figcaption{font-size:11px;color:#7A867A}.bd figcaption{color:#9FB59F}
img{display:block}.big{height:320px;width:auto}.ic{box-shadow:0 1px 3px rgba(0,0,0,.25)}
.irow figure{margin-right:10px}table{border-collapse:collapse;width:100%;font-size:14px}td{padding:6px 8px;border-bottom:1px solid var(--line);vertical-align:top}
.tw{overflow-x:auto}.sheets{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(280px,1fr))}.sheets img{width:100%;height:auto;border-radius:10px;border:1px solid var(--line)}
  .r2{font-size:14px;border-left:3px solid #C9506C;padding:4px 10px;background:var(--surface);border-radius:4px}\nbutton{border:1px solid var(--line);background:var(--surface);color:var(--text);border-radius:999px;padding:8px 14px;font:inherit;font-weight:700;cursor:pointer}
'''

def main():
    os.makedirs(os.path.join(HERE, 'ref'), exist_ok=True)
    shutil.copyfile(SHIP, os.path.join(HERE, 'ref', 'shipping-icon-1024.png'))
    body = ''.join(section(d) for d in DIRS)
    html = ('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
            '<title>WordFlora Logo v3</title><style>%s</style></head><body><div class="wrap">'
            '<header><h1>WordFlora logo v3: three directions</h1><button onclick="var r=document.documentElement;r.dataset.theme=(r.dataset.theme===\'dark\'||(!r.dataset.theme&&matchMedia(\'(prefers-color-scheme: dark)\').matches))?\'light\':\'dark\'">Light / dark</button></header>'
            '<p class="muted">Brief: docs/pm/logo-critique.md. v2 for comparison: <a href="../final/index.html">logo/final</a>. Small renders are actual pixels (PNG, device scale 1); the 320 px column is the SVG.</p>'
            '<nav><a href="#hero">Hero flower</a><a href="#unified">Unified, with the smile</a><a href="#centre">Centre bloom disc</a></nav>%s'
            '<p class="muted" style="margin-top:40px">Built by build.py, rendered by render.py (headless Chromium over file://), page by page.py. Font: Nunito Black (SIL OFL), fonts/.</p>'
            '</div></body></html>' % (CSS, body))
    open(os.path.join(HERE, 'index.html'), 'w').write(html)
    print('wrote index.html')

if __name__ == '__main__':
    main()

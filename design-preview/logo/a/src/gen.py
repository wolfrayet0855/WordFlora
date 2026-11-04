"""Direction A "Two blooms": generate wordmark + icon SVGs with text converted to paths."""
import math, sys, os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

FONT, OUT = sys.argv[1], sys.argv[2]
f = TTFont(FONT)
cm = f.getBestCmap(); gs = f.getGlyphSet(); hm = f['hmtx']; glyf = f['glyf']

def gpath(ch):
    p = SVGPathPen(gs); gs[cm[ord(ch)]].draw(p); return p.getCommands()

# ---- bloom geometry (font units, y up, centre at origin) ----
N = int(__import__("os").environ.get("PETALS","5"))
R = 284          # outer radius
PR = 128         # petal half-length (radial)
PW = int(__import__("os").environ.get("PW","110"))          # petal half-width
PD = R - PR      # petal centre distance
CR = 112         # centre disc radius (the "counter")

def bloom(cx, cy, rot, petal, centre, scale=1.0, mono=None, mid=None):
    s = scale
    els = []
    for i in range(N):
        a = rot + i * 360 / N
        els.append(f'<ellipse cx="0" cy="{PD*s:.1f}" rx="{PW*s:.1f}" ry="{PR*s:.1f}" transform="rotate({a:.1f})"/>')
    petals = ''.join(els)
    if mono:  # knock the centre out so the bloom is a scalloped ring (an "o")
        mid_id = mono
        return (f'<mask id="{mid_id}" maskUnits="userSpaceOnUse" x="{-R*s-5}" y="{-R*s-5}" width="{2*R*s+10}" height="{2*R*s+10}">'
                f'<g fill="#fff">{petals}</g><circle r="{CR*s:.1f}" fill="#000"/></mask>'
                f'<g transform="translate({cx:.1f} {cy:.1f})"><rect x="{-R*s-5}" y="{-R*s-5}" width="{2*R*s+10}" height="{2*R*s+10}" mask="url(#{mid_id})"/></g>')
    out = f'<g transform="translate({cx:.1f} {cy:.1f})"><g fill="{petal}">{petals}</g><circle r="{CR*s:.1f}" fill="{centre}"/>'
    if mid:  # tiny inner dot (only used at icon scale)
        out += f'<circle r="{CR*s*0.42:.1f}" fill="{mid}"/>'
    return out + '</g>'

# ---- layout ----
O_CY = 246
O_BOX = 543
SEQ = ['W', 'o', 'r', 'd', 'F', 'l', 'o', 'r', 'a']
KERN = {('W', 'o'): -58, ('o', 'r'): -6, ('d', 'F'): 10, ('l', 'o'): -8, ('r', 'a'): -14, ('F', 'l'): -10}

def layout():
    x = 0; items = []; prev = None
    for ch in SEQ:
        if prev: x += KERN.get((prev, ch), 0)
        adv, lsb = hm[cm[ord(ch)]]
        if ch == 'o':
            extra = (2 * R - O_BOX)
            cx = x + 29 + O_BOX / 2 + extra / 2
            items.append(('o', cx)); x += adv + extra - 22
        else:
            items.append((ch, x)); x += adv
        prev = ch
    return items, x

ITEMS, ADV = layout()
TOP, BOT = 714 + 20, -R + O_CY - 20  # content box in font units (W top / bloom bottom)
L = 31 - 20
RGT = ADV - 30 + 20

def wordmark(word_col, flora_col, b1, b2, mono=None, bg=None, label='WordFlora'):
    W_ = RGT - L; H_ = TOP - BOT
    parts = []
    idx_o = 0
    for i, (ch, x) in enumerate(ITEMS):
        col = word_col if i < 4 else flora_col
        if mono: col = mono
        if ch == 'o':
            b = b1 if idx_o == 0 else b2
            if mono:
                parts.append(bloom(x, O_CY, b[2], None, None, mono=f'ko{idx_o}'))
            else:
                parts.append(bloom(x, O_CY, b[2], b[0], b[1]))
            idx_o += 1
        else:
            parts.append(f'<path transform="translate({x:.1f} 0)" fill="{col}" d="{gpath(ch)}"/>')
    body = ''.join(parts)
    if mono:
        body = f'<g fill="{mono}">{body}</g>'
    bgr = f'<rect x="{L}" y="{-TOP}" width="{W_}" height="{H_}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{L} {-TOP} {W_} {H_}" role="img" aria-label="{label}">'
            f'<title>{label}</title>{bgr}<g transform="scale(1 -1)">{body}</g></svg>')

# ---- palette ----
LIGHT = dict(word='#2C3E2C', flora='#2A7A38',
             b1=('#E0962A', '#FFF4D6', 0),   # gold bloom in "Word": amber petals, pale butter counter
             b2=('#E25D78', '#FCD46E', 36))   # rose bloom in "Flora": deep rose petals, gold centre
DARK = dict(word='#D4EDD4', flora='#F0C060',
            b1=('#F0C060', '#4A3410', 0),
            b2=('#F58FA2', '#4D3039', 36))

def w(name, s):
    open(os.path.join(OUT, name), 'w').write(s)

w('wordmark.svg', wordmark(LIGHT['word'], LIGHT['flora'], LIGHT['b1'], LIGHT['b2']))
w('wordmark-dark.svg', wordmark(DARK['word'], DARK['flora'], DARK['b1'], DARK['b2']))
w('wordmark-mono.svg', wordmark(None, None, LIGHT['b1'], LIGHT['b2'], mono='#2C3E2C'))
w('wordmark-mono-white.svg', wordmark(None, None, LIGHT['b1'], LIGHT['b2'], mono='#FFFFFF'))

# ---- icon (1024, full-bleed square: iOS applies its own mask) ----
def icon(kind):
    S = 1024
    if kind == 'light':
        bg = ('<linearGradient id="g" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1024"><stop offset="0" stop-color="#2E7F3B"/>'
              '<stop offset="1" stop-color="#18491F"/></linearGradient>')
        fill = 'url(#g)'; p1, c1, d1 = '#F2788A', '#FCD46E', '#E8A838'; p2, c2 = '#F0B848', '#FFF4D6'; leaf = '#7CC46B'
    elif kind == 'dark':
        bg = ('<linearGradient id="g" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="1024"><stop offset="0" stop-color="#22391F"/>'
              '<stop offset="1" stop-color="#132313"/></linearGradient>')
        fill = 'url(#g)'; p1, c1, d1 = '#F58FA2', '#F0C060', '#D99A2E'; p2, c2 = '#F0C060', '#4A3410'; leaf = '#4F8F45'
    else:  # tinted: greyscale on black, iOS tints the luminance
        bg = ''; fill = '#000'; p1, c1, d1 = '#FFFFFF', '#5A5A5A', '#3A3A3A'; p2, c2 = '#C8C8C8', '#000000'; leaf = '#6E6E6E'
    # big bloom (the "o" of Flora, enlarged) and small bloom (the "o" of Word) on one diagonal, never touching
    big = bloom(436, 436, 4, p1, c1, scale=1.12, mid=d1)
    small = bloom(786, 786, 20, p2, c2, scale=0.56)
    leafp = ring = ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" width="{S}" height="{S}">'
            f'<defs>{bg}</defs><rect width="{S}" height="{S}" fill="{fill}"/>{leafp}{big}{ring}{small}</svg>')

w('icon.svg', icon('light'))
w('icon-dark.svg', icon('dark'))
w('icon-tinted.svg', icon('tinted'))

# ---- contrast report ----
def lum(h):
    h = h.lstrip('#'); c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def cr(a, b):
    la, lb = sorted([lum(a), lum(b)], reverse=True); return (la + 0.05) / (lb + 0.05)
pairs = [('Word', LIGHT['word'], '#FAF7F0'), ('Flora', LIGHT['flora'], '#FAF7F0'), ('Word on surface', LIGHT['word'], '#FFFFFF'),
         ('Flora on surface', LIGHT['flora'], '#FFFFFF'),
         ('Word dark', DARK['word'], '#1A2E1A'), ('Flora dark', DARK['flora'], '#1A2E1A'),
         ('Word dark surface', DARK['word'], '#2C3E2C'), ('Flora dark surface', DARK['flora'], '#2C3E2C'),
         ('gold petals vs bg', LIGHT['b1'][0], '#FAF7F0'), ('rose petals vs bg', LIGHT['b2'][0], '#FAF7F0'),
         ('gold petals vs centre', LIGHT['b1'][0], LIGHT['b1'][1]), ('rose petals vs centre', LIGHT['b2'][0], LIGHT['b2'][1]),
         ('dark gold petals vs bg', DARK['b1'][0], '#1A2E1A'), ('dark rose petals vs bg', DARK['b2'][0], '#1A2E1A'),
         ('dark gold petals vs centre', DARK['b1'][0], DARK['b1'][1]), ('dark rose petals vs centre', DARK['b2'][0], DARK['b2'][1]),
         ('icon rose vs green', '#F2788A', '#24622D'), ('icon gold vs green', '#F0B848', '#24622D')]
for n, a, b in pairs:
    print(f'{n:28s} {a} on {b}: {cr(a, b):.2f}  (L {lum(a):.2f} / {lum(b):.2f})')
print('aspect', (RGT - L) / (TOP - BOT))

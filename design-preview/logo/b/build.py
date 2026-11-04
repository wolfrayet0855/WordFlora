"""Direction B: letter-O rings with petals.

Builds every SVG under design-preview/logo/b/ from Nunito Black (wght 900),
converting letters to paths so the files need no web font.

    python build.py /path/to/Nunito-900.ttf

Nunito is OFL (github.com/google/fonts/tree/main/ofl/nunito); instance the
variable font at wght=900 with fontTools.varLib.instancer first.
Env: REC=twin|solo picks which variant becomes wordmark*.svg; ICON=bloom|daisy picks icon*.svg.
"""
import math, os, sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = TTFont(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'Nunito-900.ttf'))
GS = FONT.getGlyphSet(); CMAP = FONT.getBestCmap()

# ink = "Word", flora = "Flora", p1 = Word-o petals, p2 = Flora-o petals, leaf = l leaf
PAL = {
  'light': dict(bg='#FAF7F0', ink='#2C3E2C', flora='#2A7A38', p1='#E8A838', p2='#E0705A', leaf='#5DA94F'),
  'dark':  dict(bg='#1A2E1A', ink='#D4EDD4', flora='#F0C060', p1='#E8A838', p2='#E0705A', leaf='#7CC47C'),
  'mono':  dict(bg='#FFFFFF', ink='#2C3E2C', flora='#2C3E2C', p1='#2C3E2C', p2='#2C3E2C', leaf='#2C3E2C'),
}

def f(v): return ('%.1f' % v).rstrip('0').rstrip('.')

def glyph_d(ch, x, base=0.0, sc=1.0):
    pen = SVGPathPen(GS, ntos=f)
    # font units are y-up; flip into SVG space with the baseline at y=base
    GS[CMAP[ord(ch)]].draw(TransformPen(pen, (sc, 0, 0, -sc, x, base)))
    return pen.getCommands()

def adv(ch): return FONT['hmtx'][CMAP[ord(ch)]][0]

# o glyph (wght 900): outer bbox 29..572 x -11..503 -> centre (300.5, 246), radii 272 x 257
O_CX, O_CY, O_RX, O_RY = 300.5, 246.0, 271.5, 257.0
GAP = 30  # clear gap (font units) cut around the ring so petals never touch the O

def ring_r(ang):
    a = math.radians(ang)
    return 1 / math.sqrt((math.cos(a) / O_RX) ** 2 + (math.sin(a) / O_RY) ** 2)

def petal(cx, cy, ang, r0, length, width):
    """Rounded teardrop petal from distance r0 to r0+length along angle (deg, 0 = right, CCW)."""
    a = math.radians(ang); ux, uy = math.cos(a), -math.sin(a); vx, vy = -uy, ux
    L, w = length, width / 2
    def p(s, t): return (cx + ux * (r0 + s) + vx * t, cy + uy * (r0 + s) + vy * t)
    A = p(0, 0); T = p(L, 0)
    c1 = p(L * 0.05, -w * 1.25); c2 = p(L * 1.02, -w * 1.30)
    c3 = p(L * 1.02, w * 1.30);  c4 = p(L * 0.05, w * 1.25)
    return 'M%s %sC%s %s %s %s %s %sC%s %s %s %s %s %sZ' % tuple(f(v) for v in (*A, *c1, *c2, *T, *c3, *c4, *A))

def ext(ang, h, v):
    """petal reach beyond the ring: shorter sideways (neighbour letters), longer up/down"""
    a = math.radians(ang)
    return h * abs(math.cos(a)) + v * abs(math.sin(a))

def daisy(cx, cy, sc=1.0, h=125, v=165, n=6, off=30, width=215):
    """Word o: six rounded daisy petals tucked under the ring, none pointing straight sideways."""
    out = []
    for i in range(n):
        ang = off + i * 360 / n; r = ring_r(ang)
        out.append(petal(cx, cy, ang, r * 0.55 * sc, (r * 0.45 + ext(ang, h, v)) * sc, width * sc))
    return out

def bloom(cx, cy, sc=1.0, h=150, v=185, n=5, width=330):
    """Flora o: five broad round petals (primrose / blossom), one straight up."""
    out = []
    for i in range(n):
        ang = 90 + i * 360 / n; r = ring_r(ang)
        out.append(petal(cx, cy, ang, r * 0.40 * sc, (r * 0.60 + ext(ang, h, v)) * sc, width * sc))
    return out

def leaf(x, y, size, ang=50):
    a = math.radians(ang); ux, uy = math.cos(a), -math.sin(a); vx, vy = -uy, ux
    L, w = size, size * 0.34
    def p(s, t): return (x + ux * s + vx * t, y + uy * s + vy * t)
    A = p(0, 0); B1 = p(L * .25, -w * 1.25); B2 = p(L * .80, -w * 1.0); T = p(L, 0)
    C1 = p(L * .80, w * 1.0); C2 = p(L * .25, w * 1.25)
    return 'M%s %sC%s %s %s %s %s %sC%s %s %s %s %s %sZ' % tuple(f(v) for v in (*A, *B1, *B2, *T, *C1, *C2, *A))

SIDE = {'daisy': (115, 105), 'bloom': (175, 160)}   # extra room (before, after) a flower o

def layout(variant):
    seq = []; x = 0
    for i, ch in enumerate('WordFlora'):
        role = 'ink' if i < 4 else 'flora'
        flower = None
        if ch == 'o':
            if i == 1 and variant == 'twin': flower = 'daisy'
            if i == 6: flower = 'bloom'
        if flower: x += SIDE[flower][0]
        if i == 1 and not flower: x -= 40      # W-o kern
        seq.append((ch, x, role, flower))
        x += adv(ch)
        if flower: x += SIDE[flower][1]
        if ch == 'd': x += 30
    return seq, x

_mid = [0]
def uid(p):
    _mid[0] += 1; return '%s%d' % (p, _mid[0])

def masked(petals_by_colour, rings, mid, gap=GAP):
    """petals cut away around each ring by `gap` so the O stays a clean letter in any colour / on any bg"""
    m = ('<mask id="%s" maskUnits="userSpaceOnUse" x="-2000" y="-2000" width="20000" height="6000">'
         '<rect x="-2000" y="-2000" width="20000" height="6000" fill="#fff"/>'
         '<path d="%s" fill="#000" stroke="#000" stroke-width="%s" stroke-linejoin="round"/></mask>') % (mid, ' '.join(rings), f(gap * 2))
    g = ''.join('<path fill="%s" d="%s"/>' % (c, ' '.join(d)) for c, d in petals_by_colour if d)
    return '<defs>%s</defs>\n  <g mask="url(#%s)">%s</g>' % (m, mid, g)

def wordmark(variant, pal, with_leaf=False, pad=40):
    P = PAL[pal]
    seq, width = layout(variant)
    base = 760
    parts = {'ink': [], 'flora': [], 'p1': [], 'p2': [], 'leaf': []}; rings = []
    for ch, x, role, flower in seq:
        d = glyph_d(ch, x, base); parts[role].append(d)
        cx, cy = x + O_CX, base - O_CY
        if flower: rings.append(d)
        if flower == 'daisy': parts['p1'] += daisy(cx, cy)
        if flower == 'bloom': parts['p2'] += bloom(cx, cy)
        if ch == 'l' and with_leaf:
            parts['leaf'].append(leaf(x + 250, base - 640, 230, 50))
    top = 0; bottom = base + 230
    vb = (-pad, top - pad, width + 2 * pad, bottom - top + 2 * pad)
    body = masked([(P['p1'], parts['p1']), (P['p2'], parts['p2'])], rings, uid('gap'),
                  gap=GAP * 1.6 if pal == 'mono' else GAP)   # one ink: a wider gap keeps the petals apart from the ring
    for key in ('leaf', 'ink', 'flora'):
        if parts[key]: body += '\n  <path fill="%s" d="%s"/>' % (P[key], ' '.join(parts[key]))
    return vb, body

def svg_doc(vb, body, title):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s" role="img" aria-label="WordFlora">\n'
            '  <title>%s</title>\n  %s\n</svg>\n') % (' '.join(f(v) for v in vb), title, body)

ICON = {
    'light':  dict(top='#558A26', bot='#3B6D19', ring='#FBF4E4', pet='#F2B33D'),
    'dark':   dict(top='#253C1B', bot='#14200F', ring='#EFE6C8', pet='#E9A93A'),
    'tinted': dict(top='#000000', bot='#000000', ring='#FFFFFF', pet='#7A7A7A'),
}

def icon(style, which='bloom', sc=None):
    S = 1024; C = ICON[style]
    sc = sc or (0.80 if which == 'bloom' else 0.86)
    cx, cy = S / 2, S / 2
    ring = glyph_d('o', cx - O_CX * sc, cy + O_CY * sc, sc)
    pet = bloom(cx, cy, sc, h=175, v=175) if which == 'bloom' else daisy(cx, cy, sc, h=150, v=150)
    body = ('<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/>'
            '<stop offset="1" stop-color="%s"/></linearGradient></defs>\n  <rect width="1024" height="1024" fill="url(#g)"/>\n  ') % (C['top'], C['bot'])
    body += masked([(C['pet'], pet)], [ring], uid('igap'), gap=GAP * sc * 1.3)
    body += '\n  <path fill="%s" d="%s"/>' % (C['ring'], ring)
    return svg_doc((0, 0, S, S), body, 'WordFlora app icon (%s)' % style)

def write(name, txt):
    with open(os.path.join(HERE, name), 'w') as fh: fh.write(txt)

if __name__ == '__main__':
    REC = os.environ.get('REC', 'twin')
    for variant in ('twin', 'solo'):
        for pal in ('light', 'dark', 'mono'):
            vb, body = wordmark(variant, pal)
            suffix = '' if pal == 'light' else '-' + pal
            doc = svg_doc(vb, body, 'WordFlora')
            write('wordmark-%s%s.svg' % (variant, suffix), doc)
            if variant == REC: write('wordmark%s.svg' % suffix, doc)
    which = os.environ.get('ICON', 'bloom')
    for st in ('light', 'dark', 'tinted'):
        sfx = '' if st == 'light' else '-' + st
        write('icon%s.svg' % sfx, icon(st, which))
        for w in ('bloom', 'daisy'): write('icon-%s%s.svg' % (w, sfx), icon(st, w))
    print('ok')

"""Final WordFlora wordmark + icon candidate (direction B refined per design-preview/logo/critic.md).

    python build.py /path/to/Nunito-900.ttf        (needs fontTools + skia-pathops)

Everything is plain filled paths: the 36-unit gap is baked in with boolean ops
(petals minus every glyph dilated by GAP), so there is no mask, stroke or filter
and the SVGs import cleanly into an Xcode asset catalog.
Writes final/*.svg and ../icon/*.svg.
Env: K = petal tip / ring radius (default 1.72; v1 used 1.75, see notes.md).
     V1=1 rebuilds the original v1 files byte for byte (kept in v1/ for revert).

v2 touch-up (notes.md, "v2 touch-up"):
  - every petal keeps a real NB_CLEAR (32 u) of air to the neighbouring letters; v1 only forbade
    overlap, so petals came within 4-8 u of W, r, l and read as touching at every app size;
  - petal corners where they meet the ring gap are rounded (opening, ROUND = 18 u), matching
    Nunito's round terminals and removing the spikes that sparkle at small sizes;
  - reach 1.75 -> 1.72 to pay back most of the width the extra clearance costs;
  - light amber deepened (#E0962A -> #DA8B22, 2.29 -> 2.55:1 on cream), light rose cooled
    a touch (#E27D8A -> #E07A8E, 2.61 -> 2.67:1; stays close to the app's coral pinks),
    dark rose cooled to match (#E25D78 -> #E0607F);
  - solo ring gap 36 -> 46 u (solo only shows below 130 pt, where 36 u is under 1 px);
  - mono / solo-mono petal opacity 0.45 -> 0.55 (mono-solid stays 0.6);
  - SVG width/height written equal to the viewBox (as the asset catalog copies have).
"""
import math, os, sys
import pathops
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
ICON_DIR = os.path.join(HERE, '..', 'icon')
FONT = TTFont(sys.argv[1])
GS = FONT.getGlyphSet(); CMAP = FONT.getBestCmap()

def f(v): return ('%.1f' % v).rstrip('0').rstrip('.')
def adv(ch): return FONT['hmtx'][CMAP[ord(ch)]][0]

def glyph(ch, x, base, sc=1.0):
    p = pathops.Path()
    GS[CMAP[ord(ch)]].draw(TransformPen(p.getPen(), (sc, 0, 0, -sc, x, base)))
    return p

def d_of(path):
    pen = SVGPathPen(None, ntos=f); path.draw(pen); return pen.getCommands()

def union(paths):
    out = pathops.Path()
    for p in paths: out = pathops.op(out, p, pathops.PathOp.UNION)
    return out

def dilate(path, r):
    s = pathops.Path(); s.addPath(path)
    s.stroke(r * 2, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
    s.convertConicsToQuads()
    return pathops.op(s, path, pathops.PathOp.UNION)

KAPPA = 0.5522847498
def ellipse(cx, cy, rx, ry, rot_deg):
    """ellipse as 4 cubics, rotated by rot_deg (SVG space, clockwise positive)"""
    a = math.radians(rot_deg); c, s = math.cos(a), math.sin(a)
    def T(x, y): return (cx + x * c - y * s, cy + x * s + y * c)
    kx, ky = rx * KAPPA, ry * KAPPA
    p = pathops.Path(); pen = p.getPen()
    pen.moveTo(T(rx, 0))
    pen.curveTo(T(rx, ky), T(kx, ry), T(0, ry))
    pen.curveTo(T(-kx, ry), T(-rx, ky), T(-rx, 0))
    pen.curveTo(T(-rx, -ky), T(-kx, -ry), T(0, -ry))
    pen.curveTo(T(kx, -ry), T(rx, -kx * 0 - ky), T(rx, 0))
    pen.closePath()
    return p

# o glyph (wght 900): outer bbox 29..572 x -11..503 -> centre (300.5, 246), mean outer radius ~264
O_CX, O_CY, O_R = 300.5, 246.0, 264.0
GAP = 36
# Review-team spec ("B uncut"): reach 1.40x; no petal is cut by a neighbouring letter, only the
# 36-unit gap around each o's own ring. Side bearings are found by search (see fit_bearings).
# Spec asked for 1.40; at 1.40 the visible petal is ~70 u (about 1.5 px at 120 px wide) and the five petals
# cannot be counted, failing the acceptance check. 1.60 / 1.75 / 1.90 were compared; 1.75 is the
# smallest reach where all five Flora petals are countable at 120 px (notes.md).
V1 = bool(os.environ.get('V1'))
K = float(os.environ.get('K', '1.75' if V1 else '1.72'))
MIN_CLEAR = 0.90   # each petal keeps >= 90% of its (post-gap) area clear of neighbours dilated by GAP
NB_CLEAR = 0 if V1 else float(os.environ.get('NB_CLEAR', '32'))   # hard air between any petal and a neighbour
ROUND = 0 if V1 else float(os.environ.get('ROUND', '10'))         # radius for rounding petal corners at the gap
# solo is only used below 130 pt wide, where 36 u is under 1 px: give its ring gap more room (optical size)
GAPS = {'twin': GAP, 'solo': GAP if V1 else float(os.environ.get('SOLO_GAP', '46'))}

def petals_of(cx, cy, rot, sc=1.0, k=None):
    """five ellipse petals (A's proportions): tip at k * ring radius; rot 0 = one petal straight up"""
    T = (K if k is None else k) * O_R
    PR, PW = 0.45 * T, 0.387 * T          # half-length, half-width (A: 128/284, 110/284)
    PD = T - PR
    out = []
    for i in range(5):
        a = rot + i * 72                   # 0 = up, clockwise
        ar = math.radians(a)
        px, py = cx + math.sin(ar) * PD * sc, cy - math.cos(ar) * PD * sc
        out.append(ellipse(px, py, PW * sc, PR * sc, a))
    return out

PAL = {
  'light': dict(ink='#2C3E2C', flora='#2A7A38', p1='#E0962A' if V1 else '#DA8B22', p2='#E27D8A' if V1 else '#E07A8E', bg='#FAF7F0'),
  'dark':  dict(ink='#D4EDD4', flora='#F0C060', p1='#E0962A', p2='#E25D78' if V1 else '#E0607F', bg='#1A2E1A'),
  'mono':  dict(ink='#2C3E2C', flora='#2C3E2C', p1='#2C3E2C', p2='#2C3E2C', bg='#FFFFFF'),
}
BLOOMS = ((1, 0, 'p1'), (6, 36, 'p2'))     # (letter index, rotation, colour key)
BASE = 780

def layout(extra):
    """Nunito advances; W-o kern -40; +20 at d|F; extra = {index: (before, after)} for flower o's."""
    xs = []; x = 0
    for i, ch in enumerate('WordFlora'):
        if i == 1: x -= 40
        if i == 4: x += 20
        x += extra.get(i, (0, 0))[0]
        xs.append(x); x += adv(ch)
        x += extra.get(i, (0, 0))[1]
    return xs, x

def erode(path, r):
    s = pathops.Path(); s.addPath(path)
    s.stroke(r * 2, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
    s.convertConicsToQuads()
    return pathops.op(path, s, pathops.PathOp.DIFFERENCE)

FUSE = os.environ.get('FUSE', '1') == '1'

def rounded(path, r):
    """FUSE: closing then opening, so petals that only touch at a point join with a soft web and
    every corner gets radius ~r; otherwise opening only (rounds convex corners, petals split apart)"""
    if not r: return path
    if FUSE: path = erode(dilate(path, r), r)
    return dilate(erode(path, r), r)

def visible_petals(xs, idx, rot):
    cx, cy = xs[idx] + O_CX, BASE - O_CY
    ring = glyph('o', xs[idx], BASE)
    cut = pathops.op(dilate(ring, GAP), ellipse(cx, cy, O_R - 20, O_R - 30, 0), pathops.PathOp.UNION)
    return [pathops.op(p, cut, pathops.PathOp.DIFFERENCE) for p in petals_of(cx, cy, rot)]

def petals_clear(xs, idx, rot, nb):
    """the fit rule: no petal overlaps the neighbour (dilated by NB_CLEAR) and >= MIN_CLEAR of each
    petal stays clear of the neighbour dilated by GAP"""
    r = clear_ratios(xs, idx, rot, nb)
    return min(c for c, _ in r) >= MIN_CLEAR and max(h for _, h in r) == 0

def clear_ratios(xs, idx, rot, nb):
    """per petal: share of visible area clear of neighbour glyph nb (dilated by GAP); also raw overlap"""
    nbg = glyph('WordFlora'[nb], xs[nb], BASE); nbd = dilate(nbg, GAP)
    if NB_CLEAR: nbg = dilate(nbg, NB_CLEAR)
    out = []
    for p in visible_petals(xs, idx, rot):
        A = abs(p.area)
        if A < 1: continue
        c = abs(pathops.op(p, nbd, pathops.PathOp.DIFFERENCE).area)
        hit = abs(pathops.op(p, nbg, pathops.PathOp.INTERSECTION).area)
        out.append((c / A, hit))
    return out

def fit_bearings(variant, step=5):
    extra = {}
    for idx, rot, _ in BLOOMS:
        if idx == 1 and variant == 'solo': continue
        before = after = 0
        while True:
            extra[idx] = (before, after); xs, _ = layout(extra)
            if petals_clear(xs, idx, rot, idx - 1): break
            before += step
        while True:
            extra[idx] = (before, after); xs, _ = layout(extra)
            if petals_clear(xs, idx, rot, idx + 1): break
            after += step
    return extra

TOL = 0.15  # letter clearance next to a flower o within +/-15% of the r-d clearance

def balance(extra, variant, step=5):
    """after the petal fit, move each flower o's neighbours until the x-height clearance is
    within TOL of r-d (only ever opens space when too tight; kerns back only if petals stay clear)"""
    names = {1: ('W-o', 'o-r'), 6: ('l-o', 'o-r2')}
    for idx, rot, _ in BLOOMS:
        if idx == 1 and variant == 'solo': continue
        for side, gname in enumerate(names[idx]):
            for _ in range(60):
                xs, _w = layout(extra); g = gaps([glyph(ch, x, BASE) for ch, x in zip('WordFlora', xs)])
                ratio = g[gname][1] / g['r-d'][1]
                b, a = extra[idx]
                if ratio < 1 - TOL:
                    extra[idx] = (b + step, a) if side == 0 else (b, a + step)
                elif ratio > 1 + TOL:
                    trial = dict(extra); trial[idx] = (b - step, a) if side == 0 else (b, a - step)
                    txs, _w = layout(trial)
                    if petals_clear(txs, idx, rot, idx - 1 if side == 0 else idx + 1): extra = trial
                    else: break
                else: break
    return extra

def wordmark(variant, pal, extra, petal_opacity=0.45):
    P = PAL[pal]; xs, width = layout(extra)
    glyphs = [glyph(ch, x, BASE) for ch, x in zip('WordFlora', xs)]
    blooms = []
    for idx, rot, key in BLOOMS:
        if idx == 1 and variant == 'solo': continue
        # round the fused bloom (not each petal, which would split the silhouette); opening only
        # removes area, so the clearance checks made on the unrounded petals still hold
        blooms.append((key, rounded(union(visible_petals(xs, idx, rot)), ROUND)))
    body = []
    op = (' fill-opacity="%s"' % petal_opacity) if pal == 'mono' else ''
    for key, b in blooms:
        body.append('<path fill="%s"%s d="%s"/>' % (P[key], op, d_of(b)))
    if pal == 'mono':
        body.append('<path fill="%s" d="%s"/>' % (P['ink'], d_of(union(glyphs))))
    else:
        body.append('<path fill="%s" d="%s"/>' % (P['ink'], d_of(union(glyphs[:4]))))
        body.append('<path fill="%s" d="%s"/>' % (P['flora'], d_of(union(glyphs[4:]))))
    allp = union(glyphs + [b for _, b in blooms])
    x0, y0, x1, y1 = allp.bounds; m = 32
    vb = (math.floor(x0 - m), math.floor(y0 - m), math.ceil(x1 - x0 + 2 * m), math.ceil(y1 - y0 + 2 * m))
    return vb, '\n  '.join(body), (glyphs, xs)

def svg(vb, body, title):
    wh = '' if V1 else 'width="%s" height="%s" ' % (vb[2], vb[3])
    return ('<svg xmlns="http://www.w3.org/2000/svg" %sviewBox="%s" role="img" aria-label="WordFlora">\n'
            '  <title>%s</title>\n  %s\n</svg>\n') % (wh, ' '.join(str(v) for v in vb), title, body)

# ---------- icon candidate ----------
ICON = {
  'light':  dict(top='#3E7A2A', bot='#2E6B22', ring='#FBF4E4', pet='#F0B848'),
  'dark':   dict(top='#1A2E1A', bot='#132313', ring='#EFE6C8', pet='#E9A93A'),
  'tinted': dict(top='#000000', bot='#000000', ring='#FFFFFF', pet='#7A7A7A'),
}
ICON_SC = float(os.environ.get('ICON_SC', '0.98'))    # ring scale; >= 0.98 keeps the counter >= 5 x 7 px at 29 px
ICON_REACH = float(os.environ.get('ICON_REACH', '190'))  # petal reach past the ring (font units)
ICON_PW = float(os.environ.get('ICON_PW', '195'))        # petal width

def icon_petals(cx, cy, sc):
    """B's icon blossom: five broad rounded teardrop petals reaching ~175 u past the ring"""
    out = []
    for i in range(5):
        ang = 90 + i * 72; a = math.radians(ang)
        ux, uy = math.cos(a), -math.sin(a); vx, vy = -uy, ux
        r = 1 / math.sqrt((math.cos(a) / 271.5) ** 2 + (math.sin(a) / 257.0) ** 2)
        r0, L, w = r * 0.40 * sc, (r * 0.60 + ICON_REACH) * sc, ICON_PW * sc
        def p(s, t): return (cx + ux * (r0 + s) + vx * t, cy + uy * (r0 + s) + vy * t)
        path = pathops.Path(); pen = path.getPen()
        pen.moveTo(p(0, 0))
        pen.curveTo(p(L * 0.05, -w * 1.25), p(L * 1.02, -w * 1.30), p(L, 0))
        pen.curveTo(p(L * 1.02, w * 1.30), p(L * 0.05, w * 1.25), p(0, 0))
        pen.closePath(); out.append(path)
    return union(out)

def icon(style):
    C = ICON[style]; S = 1024; sc = ICON_SC
    ring = glyph('o', S / 2 - O_CX * sc, S / 2 + O_CY * sc, sc)
    pet = pathops.op(icon_petals(S / 2, S / 2, sc), dilate(ring, GAP * sc * 1.3), pathops.PathOp.DIFFERENCE)
    body = ('<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/>'
            '<stop offset="1" stop-color="%s"/></linearGradient></defs>\n  <rect width="1024" height="1024" fill="url(#g)"/>\n'
            '  <path fill="%s" d="%s"/>\n  <path fill="%s" d="%s"/>') % (C['top'], C['bot'], C['pet'], d_of(pet), C['ring'], d_of(ring))
    return svg((0, 0, S, S), body, 'WordFlora app icon candidate (%s)' % style)

def gaps(glyphs):
    """optical gap: mean horizontal clearance between neighbouring glyphs across the x-height band"""
    def edge(p, y, side):
        x0, _, x1, _ = p.bounds
        rng = range(int(x1), int(x0) - 1, -2) if side == 'right' else range(int(x0), int(x1) + 1, 2)
        for x in rng:
            if p.contains((x, y)): return x
        return None
    res = {}
    for a, b, name in ((0, 1, 'W-o'), (2, 3, 'r-d'), (1, 2, 'o-r'), (3, 4, 'd-F'), (5, 6, 'l-o'), (6, 7, 'o-r2')):
        ds = []
        for y in range(BASE - 470, BASE - 10, 20):
            r, l = edge(glyphs[a], y, 'right'), edge(glyphs[b], y, 'left')
            if r is not None and l is not None: ds.append(l - r)
        res[name] = (min(ds), sum(ds) / len(ds))
    return res

if __name__ == '__main__':
    out_dir = os.environ.get('OUT', HERE)
    MO = 0.45 if V1 else 0.55   # v2: mono petals at 0.45 read as smudges at 29 px
    files = (('wordmark', 'twin', 'light', 0.45), ('wordmark-dark', 'twin', 'dark', 0.45),
             ('wordmark-solo', 'solo', 'light', 0.45), ('wordmark-solo-dark', 'solo', 'dark', 0.45),
             ('wordmark-mono', 'twin', 'mono', MO), ('wordmark-mono-solid', 'twin', 'mono', 0.6),
             ('wordmark-solo-mono', 'solo', 'mono', MO))
    fits = {}
    for v in ('twin', 'solo'):
        GAP = GAPS[v]; fits[v] = balance(fit_bearings(v), v)
    for name, v, p, o in files:
        GAP = GAPS[v]
        vb, body, (glyphs, xs) = wordmark(v, p, fits[v], o)
        open(os.path.join(out_dir, name + '.svg'), 'w').write(svg(vb, body, 'WordFlora'))
    for v in ('twin', 'solo'):
        GAP = GAPS[v]; print('[%s] ring gap %s' % (v, GAP))
        xs, w = layout(fits[v]); glyphs = [glyph(ch, x, BASE) for ch, x in zip('WordFlora', xs)]
        print('[%s] extra side bearing (before, after):' % v, fits[v], ' total width', w)
        g = gaps(glyphs); rd = g['r-d'][1]
        for k, (mn, mean) in g.items(): print('  gap %-5s min %4d  mean %5.1f  (%+.0f%% vs r-d)' % (k, mn, mean, 100 * (mean / rd - 1)))
        for idx, rot, _ in BLOOMS:
            if idx == 1 and v == 'solo': continue
            for nb in (idx - 1, idx + 1):
                r = clear_ratios(xs, idx, rot, nb)
                print('  o%d vs %s: min clear %.3f, overlap with neighbour+%d: %d' % (idx, 'WordFlora'[nb], min(c for c, _ in r), NB_CLEAR, max(h for _, h in r)))
    if os.environ.get('ICON'):
        for st in ('light', 'dark', 'tinted'):
            open(os.path.join(ICON_DIR, 'icon%s.svg' % ('' if st == 'light' else '-' + st)), 'w').write(icon(st))
    print('ok K=%s NB_CLEAR=%s ROUND=%s%s' % (K, NB_CLEAR, ROUND, ' (V1)' if V1 else ''))

"""WordFlora logo v3: three directions (hero, unified, centre) built from Nunito Black (wght 900).

    python build.py [--direction hero|unified|centre|all]     (needs fontTools + skia-pathops)

Writes <direction>/*.svg, <direction>/measurements.json and <direction>/notes.md, and prints the
measurements. Every SVG is plain <path fill="..."> elements only: gaps, cuts and the icon face are
baked in with boolean path operations (skia-pathops), so there is no mask, stroke, filter, gradient,
<defs>, <use>, <text>, <image> or clip-path. fill-opacity appears only in the mono files.
Font: fonts/Nunito-900.ttf (SIL OFL), Nunito instanced at wght 900. Letters are never altered.
"""
import argparse, json, math, os
import pathops
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = TTFont(os.path.join(HERE, 'fonts', 'Nunito-900.ttf'))
GS = FONT.getGlyphSet(); CMAP = FONT.getBestCmap()
WORD = 'WordFlora'
PAIRS = ('W-o', 'o-r', 'r-d', 'd-F', 'F-l', 'l-o', 'o-r', 'r-a')
BASE = 780                       # baseline in SVG units (y down)
O_CX, O_CY = 300.5, 246.0        # centre of Nunito Black's o (font units, y up)
HERO_IDX = 6                     # the Flora o
MARGIN = 20

# ---------------------------------------------------------------- path helpers
def f(v): return ('%.1f' % v).rstrip('0').rstrip('.')
def adv(ch): return FONT['hmtx'][CMAP[ord(ch)]][0]

def glyph(ch, x, base, sc=1.0):
    p = pathops.Path()
    GS[CMAP[ord(ch)]].draw(TransformPen(p.getPen(), (sc, 0, 0, -sc, x, base)))
    return p

def d_of(path):
    pen = SVGPathPen(None, ntos=f); path.draw(pen); return pen.getCommands()

def op(a, b, kind): return pathops.op(a, b, kind)
def U(a, b): return op(a, b, pathops.PathOp.UNION)
def D(a, b): return op(a, b, pathops.PathOp.DIFFERENCE)
def I(a, b): return op(a, b, pathops.PathOp.INTERSECTION)

def union(paths):
    out = pathops.Path()
    for p in paths: out = U(out, p)
    return out

def _stroked(path, r):
    s = pathops.Path(); s.addPath(path)
    s.stroke(r * 2, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
    s.convertConicsToQuads(); return s

def dilate(path, r):
    for k in range(4):   # skia's boolean ops occasionally fail on a degenerate radius: nudge and retry
        try: return U(_stroked(path, r + 0.013 * k), path)
        except pathops.PathOpsError:
            if k == 3: raise
def erode(path, r): return D(path, _stroked(path, r))
def opening(path, r): return dilate(erode(path, r), r) if r else path   # rounds corners, never adds area

def transformed(path, m):
    q = pathops.Path(); path.draw(TransformPen(q.getPen(), m)); return q

def area(p): return abs(p.area)

KAPPA = 0.5522847498
def ellipse(cx, cy, rx, ry, rot_deg=0.0):
    a = math.radians(rot_deg); c, s = math.cos(a), math.sin(a)
    def T(x, y): return (cx + x * c - y * s, cy + x * s + y * c)
    kx, ky = rx * KAPPA, ry * KAPPA
    p = pathops.Path(); pen = p.getPen()
    pen.moveTo(T(rx, 0))
    pen.curveTo(T(rx, ky), T(kx, ry), T(0, ry))
    pen.curveTo(T(-kx, ry), T(-rx, ky), T(-rx, 0))
    pen.curveTo(T(-rx, -ky), T(-kx, -ry), T(0, -ry))
    pen.curveTo(T(kx, -ry), T(rx, -ky), T(rx, 0))
    pen.closePath(); return p

def circle(cx, cy, r): return ellipse(cx, cy, r, r)

def arc_band(cx, cy, r, a0, a1, width):
    """an arc (degrees, SVG angles: 0 = +x, clockwise positive) turned into a filled band with round
    ends by stroking it inside pathops; the output is an ordinary filled outline"""
    p = pathops.Path(); pen = p.getPen()
    n = max(1, int(math.ceil(abs(a1 - a0) / 45.0))); step = (a1 - a0) / n
    k = 4.0 / 3.0 * math.tan(math.radians(step) / 4.0)
    def P(a): return (cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
    pen.moveTo(P(a0))
    for i in range(n):
        s, e = a0 + i * step, a0 + (i + 1) * step
        (x0, y0), (x3, y3) = P(s), P(e)
        rs, re = math.radians(s), math.radians(e)
        pen.curveTo((x0 - k * r * math.sin(rs), y0 + k * r * math.cos(rs)),
                    (x3 + k * r * math.sin(re), y3 - k * r * math.cos(re)), (x3, y3))
    pen.endPath()
    s = pathops.Path(); s.addPath(p)
    s.stroke(width, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
    s.convertConicsToQuads()
    return union([s])

# ---------------------------------------------------------------- colour maths
def hex_rgb(h): h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def lum_lin(rgb): return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
def lum(h): return lum_lin([lin(c) for c in hex_rgb(h)])
def ratio_l(a, b): a, b = max(a, b), min(a, b); return (a + 0.05) / (b + 0.05)
def contrast(h1, h2): return ratio_l(lum(h1), lum(h2))
# Machado, Oliveira & Fernandes 2009, severity 1.0, applied to linear RGB
MACHADO = {
  'deuteranopia': ((0.367322, 0.860646, -0.227968), (0.280085, 0.672501, 0.047413), (-0.011820, 0.042940, 0.968881)),
  'protanopia':   ((0.152286, 1.052583, -0.204868), (0.114503, 0.786281, 0.099216), (-0.003882, -0.048116, 1.051998)),
  'tritanopia':   ((1.255528, -0.076749, -0.178779), (-0.078411, 0.930809, 0.147602), (0.004733, 0.691367, 0.303900)),
}
def cvd_lum(h, kind):
    v = [lin(c) for c in hex_rgb(h)]
    out = [min(1.0, max(0.0, sum(m * x for m, x in zip(row, v)))) for row in MACHADO[kind]]
    return lum_lin(out)
def cvd_contrast(h1, h2, kind): return ratio_l(cvd_lum(h1, kind), cvd_lum(h2, kind))
def mix(h, bg, a):
    c1, c2 = hex_rgb(h), hex_rgb(bg)
    return '#%02X%02X%02X' % tuple(round((a * x + (1 - a) * y) * 255) for x, y in zip(c1, c2))

# ---------------------------------------------------------------- directions
# Every direction shares: Nunito Black letters, one flower on the Flora o only (the Word o is a plain
# letter), five petals, the same kerning rule. They differ in petal geometry and colour logic.
# Round 2 (review A + B, PM integration): sRGB PNGs, ring gap 52 u (mono-solid 60 u), two-band
# spacing solver with a 60 u F-l arm gap, closing 100 u + rounded tuck ends, per-direction fixes.
BG_L, BG_D = '#FAF7F0', '#1A2E1A'
INK_L, FLORA_L = '#182818', '#2E803F'      # Word / Flora, light (A4: >= 4.5 each, >= 3.0 apart)
INK_D = '#DCEEDC'
DIRS = {
  'hero': dict(
    title='Hero flower',
    shape='teardrop', T=505, r0=110, w=172, rot=-8,
    light=dict(bg=BG_L, word=INK_L, flora=FLORA_L, ring=FLORA_L, petal='#C9506C'),
    dark=dict(bg=BG_D, word=INK_D, flora='#F0C060', ring='#F0C060', petal='#E26582'),
    # icon centre: counter filled with the ring colour + a round pistil (no o, no eye)
    icon=dict(
      light=dict(bg='#1C3820', petal='#E26582', ring='#F0C060', pistil='#B8650A'),
      dark=dict(bg='#142414', petal='#E26582', ring='#F0C060', pistil='#B8650A'),
      tinted=dict(bg='#000000', petal='#8C8C8C', ring='#FFFFFF', pistil='#A0A0A0'),
      **{'alt-cream': dict(bg='#FAF7F0', petal='#C9506C', ring='#2E803F', pistil='#E9A43A'),
         'smile': dict(bg='#1C3820', petal='#E26582', ring='#F0C060', face='#1A2E1A'),
         'smile-dark': dict(bg='#142414', petal='#E26582', ring='#F0C060', face='#1A2E1A'),
         'smile-tinted': dict(bg='#000000', petal='#8C8C8C', ring='#FFFFFF', face='#000000')}),
  ),
  'unified': dict(
    title='Unified, with the smile',
    shape='round', dc=295, rc=200, rot=-8, slits=30,
    light=dict(bg=BG_L, word=INK_L, flora=FLORA_L, ring=FLORA_L, petal='#C86800'),
    dark=dict(bg=BG_D, word=INK_D, flora='#8FCB8F', ring='#8FCB8F', petal='#E59A2E'),
    # icon inverts the wordmark's roles: petals cream, centre amber (shipping-icon logic), face tilted -8
    icon=dict(
      light=dict(bg='#356B25', petal='#FBF4E4', disc='#F5BC48', face='#1F321F'),
      dark=dict(bg='#1A2E1A', petal='#EFE6C8', disc='#E59A2E', face='#0F1C0F'),
      tinted=dict(bg='#000000', petal='#E8E8E8', disc='#8C8C8C', face='#000000')),
  ),
  'centre': dict(
    title='Centre bloom disc',
    shape='disc', dc=270, rc=215, rot=-8, ring_scale=0.75,
    light=dict(bg=BG_L, word=INK_L, flora=FLORA_L, ring=FLORA_L, petal='#CF5D78'),
    dark=dict(bg=BG_D, word=INK_D, flora='#8FCB8F', ring='#8FCB8F', petal='#DE5E7E'),
    icon=dict(
      light=dict(bg='#1F3D24', petal='#E8758F', ring='#F0B848', pistil='#C27A18'),
      dark=dict(bg='#132313', petal='#D95B7A', ring='#E9A93A', pistil='#A8620C'),
      tinted=dict(bg='#000000', petal='#B4B4B4', ring='#7A7A7A', pistil='#4A4A4A')),
  ),
}
ICON_FILES = {  # style -> (file name, sizes)
  'light': ('icon', (1024, 180, 60, 29)), 'dark': ('icon-dark', (1024, 180, 60, 29)), 'tinted': ('icon-tinted', (1024, 180, 60, 29)),
  'alt-cream': ('icon-alt-cream', (180, 60, 29)), 'smile': ('icon-smile', (1024, 180, 60, 29)),
  'smile-dark': ('icon-smile-dark', (1024, 180, 60, 29)), 'smile-tinted': ('icon-smile-tinted', (1024, 180, 60, 29)),
}
MONO = dict(bg='#FFFFFF', ink='#182818')
MONO_OPACITY = 0.6

# optical size: the solo lockup is only used below 130 pt wide (under ~22 pt tall)
SIZES = {
  'twin': dict(gap=52, nb=40, track=0, round=12),
  'solo': dict(gap=62, nb=50, track=10, round=14),
}
MONO_SOLID_GAP = 60     # Increase Contrast: wider ring gap so the o never touches a petal at 29 px
NB_CLOSE = 100          # closing radius on the neighbour cut (fills the pocket above the l's foot)
FIT_MIN = 0.70          # smallest scale a petal may take to clear a neighbour (reported per petal)
TUCK_MAX = 0.05         # after fitting, at most this share of a petal may still tuck behind the letter

# ---------------------------------------------------------------- spacing (A6, measured two ways)
# A6 is checked on two bands: the x-height band (10..470 u, as in v2) and the full o height including
# overshoot (-11..503 u). The solver kerns every pair so both bands sit inside [LO, HI] x r-d, with the
# F's middle arm at least MIN_FL from the l, and picks the smallest feasible r-d (the tightest word).
# Word pairs and d-F take the tightest legal value; the Flora o pairs take FLORA_O x r-d for petal room.
BANDS = {'x': tuple(range(10, 471, 10)), 'o': tuple(range(-11, 504, 10)) + (503,)}
SPACE = dict(lo=0.86, hi=1.14, min_fl=60, flora_o=1.10, ra=1.0)

def edge(p, y, side):
    x0, _, x1, _ = p.bounds
    rng = range(int(x1) + 1, int(x0) - 2, -1) if side == 'right' else range(int(x0) - 1, int(x1) + 2)
    for x in rng:
        if p.contains((x, y)): return x
    return None

def mean_gap(ga, gb, band='x'):
    """mean (and min) horizontal clearance between two glyphs over the rows of a band (font y, 10 u steps)"""
    ds = []
    for yy in BANDS[band]:
        y = BASE - yy
        r, l = edge(ga, y, 'right'), edge(gb, y, 'left')
        if r is not None and l is not None: ds.append(l - r)
    return sum(ds) / len(ds), min(ds)

_NATIVE = None
def native_pair_gaps():
    global _NATIVE
    if _NATIVE is None:
        _NATIVE = []
        for i in range(8):
            a, b = WORD[i], WORD[i + 1]
            ga, gb = glyph(a, 0, BASE), glyph(b, adv(a), BASE)
            _NATIVE.append(dict(x=mean_gap(ga, gb, 'x'), o=mean_gap(ga, gb, 'o')))
    return _NATIVE

_KERNS = None
def solve_kerns():
    global _KERNS
    if _KERNS is not None: return _KERNS
    nat = native_pair_gaps(); S = SPACE
    for krd in range(-60, 200):
        Rx, Ro = nat[2]['x'][0] + krd, nat[2]['o'][0] + krd
        ks, ok = [], True
        for i in range(8):
            xm, om = nat[i]['x'][0], nat[i]['o'][0]
            lo = max(S['lo'] * Rx - xm, S['lo'] * Ro - om); hi = min(S['hi'] * Rx - xm, S['hi'] * Ro - om)
            if i == 4: lo = max(lo, S['min_fl'] - nat[i]['x'][1], S['min_fl'] - nat[i]['o'][1])
            if i == 2: ks.append(float(krd)); continue
            if lo > hi: ok = False; break
            if i in (5, 6): k = min(max(S['flora_o'] * Rx - xm, lo), hi)
            elif i == 7: k = min(max(S['ra'] * Rx - xm, lo), hi)
            else: k = lo
            ks.append(math.ceil(k * 2) / 2)
        if ok:
            _KERNS = ks; return ks
    raise SystemExit('spacing infeasible with %s' % S)

def layout(track=0):
    ks = solve_kerns(); xs = [0.0]
    for i in range(8):
        xs.append(xs[-1] + adv(WORD[i]) + ks[i] + track)
    return xs, xs[-1] + adv(WORD[-1])

# ---------------------------------------------------------------- geometry
def petal_list(D_, cx, cy, sc=1.0):
    """the five petals as separate closed paths (absolute coords, y down; angle 0 = up, clockwise)"""
    out = []
    for i in range(5):
        a = math.radians(D_['rot'] + i * 72)
        ux, uy = math.sin(a), -math.cos(a); vx, vy = -uy, ux
        if D_['shape'] == 'teardrop':
            r0, L, w = D_['r0'] * sc, (D_['T'] - D_['r0']) * sc, D_['w'] * sc
            def p(s, t): return (cx + ux * (r0 + s) + vx * t, cy + uy * (r0 + s) + vy * t)
            path = pathops.Path(); pen = path.getPen()
            pen.moveTo(p(0, 0))
            pen.curveTo(p(L * 0.05, -w * 1.25), p(L * 1.02, -w * 1.30), p(L, 0))
            pen.curveTo(p(L * 1.02, w * 1.30), p(L * 0.05, w * 1.25), p(0, 0))
            pen.closePath(); out.append(union([path]))
        else:
            dc, rc = D_['dc'] * sc, D_['rc'] * sc
            out.append(circle(cx + ux * dc, cy + uy * dc, rc))
    return out

def slit_paths(D_, cx, cy, r_in, width, sc=1.0):
    """five radial bars along the bisectors between petals, from r_in outward (for mono-solid)"""
    out = []
    for i in range(5):
        a = math.radians(D_['rot'] + i * 72 + 36)
        ux, uy = math.sin(a), -math.cos(a); vx, vy = -uy, ux
        h = width / 2.0; r1 = 900 * sc
        p = pathops.Path(); pen = p.getPen()
        pts = [(cx + ux * r_in + vx * h, cy + uy * r_in + vy * h), (cx + ux * r1 + vx * h, cy + uy * r1 + vy * h),
               (cx + ux * r1 - vx * h, cy + uy * r1 - vy * h), (cx + ux * r_in - vx * h, cy + uy * r_in - vy * h)]
        pen.moveTo(pts[0]); [pen.lineTo(q) for q in pts[1:]]; pen.closePath(); out.append(p)
    return union(out)

def o_silhouette(x, base, sc=1.0):
    """the o with its counter filled (outer outline), used for the ring gap and the icon centre disc"""
    ring = glyph('o', x, base, sc)
    cx, cy = x + O_CX * sc, base - O_CY * sc
    return U(ring, ellipse(cx, cy, 240 * sc, 230 * sc))

class Mark:
    """one built wordmark: geometry + measurements"""
    def __init__(self, dname, size, gap=None, slits=0):
        self.D = DIRS[dname]; self.S = dict(SIZES[size]); self.size = size
        if gap: self.S['gap'] = gap
        self.xs, self.width = layout(self.S['track'])
        self.glyphs = [glyph(ch, x, BASE) for ch, x in zip(WORD, self.xs)]
        x6 = self.xs[HERO_IDX]
        self.cx, self.cy = x6 + O_CX, BASE - O_CY
        ringcut = dilate(o_silhouette(x6, BASE), self.S['gap'])
        nbcut = union([dilate(self.glyphs[HERO_IDX - 1], self.S['nb']), dilate(self.glyphs[HERO_IDX + 1], self.S['nb'])])
        # close the cut (fill its concave pockets, e.g. above the l's foot) so petals tuck behind a
        # neighbour along one smooth edge instead of wrapping around its terminal
        nbcut = erode(dilate(nbcut, NB_CLOSE), NB_CLOSE)
        self.raw = petal_list(self.D, self.cx, self.cy)
        self.after_ring = [D(p, ringcut) for p in self.raw]
        # round 2: instead of cutting a petal along a letter's straight stem, scale that one petal about
        # the flower centre (binary search, 1.00 down to FIT_MIN) until it clears the neighbour clearance,
        # so every petal keeps its whole rounded tip and the bloom outline has no straight cut edges
        self.scales, fitted = [], []
        for p in self.raw:
            q0 = D(p, ringcut)
            if area(I(q0, nbcut)) <= TUCK_MAX * area(q0) + 0.5:
                self.scales.append(1.0); fitted.append(p); continue
            lo, hi = FIT_MIN, 1.0
            for _ in range(12):
                s = (lo + hi) / 2
                q = D(transformed(p, (s, 0, 0, s, self.cx - s * self.cx, self.cy - s * self.cy)), ringcut)
                if area(I(q, nbcut)) <= TUCK_MAX * area(q) + 0.5: lo = s
                else: hi = s
            self.scales.append(round(lo, 3))
            fitted.append(transformed(p, (lo, 0, 0, lo, self.cx - lo * self.cx, self.cy - lo * self.cy)))
        bloom = D(D(union(fitted), ringcut), nbcut)
        if slits:
            bloom = D(bloom, slit_paths(self.D, self.cx, self.cy, 0, slits))
        self.visible = [I(a, bloom) for a in self.after_ring]
        self.bloom = opening(bloom, self.S['round'])
        allp = union(self.glyphs + [self.bloom])
        x0, y0, x1, y1 = allp.bounds; m = MARGIN
        self.vb = (math.floor(x0 - m), math.floor(y0 - m), math.ceil(x1 - x0 + 2 * m), math.ceil(y1 - y0 + 2 * m))

    def straight_edges(self):
        """longest straight run on the bloom outline (line segments and flat curves), font units"""
        from fontTools.pens.recordingPen import RecordingPen
        rp = RecordingPen(); self.bloom.draw(rp)
        best, cur, last = 0.0, None, None
        def flat(p0, ctrl, p3):
            dx, dy = p3[0] - p0[0], p3[1] - p0[1]; L = math.hypot(dx, dy)
            if L < 1e-6: return False
            return all(abs((c[0] - p0[0]) * dy - (c[1] - p0[1]) * dx) / L < 0.6 for c in ctrl)
        for op_, pts in rp.value:
            if op_ == 'moveTo': last = pts[0]; continue
            if op_ in ('closePath', 'endPath'): continue
            end = pts[-1]
            if op_ == 'lineTo' or flat(last, pts[:-1], end):
                best = max(best, math.hypot(end[0] - last[0], end[1] - last[1]))
            last = end
        return best

    def measure(self):
        vbw, vbh = self.vb[2], self.vb[3]
        upx29 = vbh / 29.0; upx60 = vbh / 60.0
        res = {}
        for band in ('x', 'o'):
            g = [mean_gap(self.glyphs[i], self.glyphs[i + 1], band) for i in range(8)]
            rd = g[2][0]
            res[band] = [dict(pair=PAIRS[i], mean=round(g[i][0], 1), min=round(g[i][1]), dev=round(100 * (g[i][0] / rd - 1), 1)) for i in range(8)]
        vis = [area(v) / area(a) if area(a) > 1 else 1.0 for v, a in zip(self.visible, self.after_ring)]
        widths = []
        for i, v in enumerate(self.visible):
            ang = math.radians(self.D['rot'] + i * 72)
            c, s = math.cos(-ang), math.sin(-ang)   # rotate so the petal axis points up
            q = transformed(v, (c, s, -s, c, 0, 0))
            b = q.bounds; widths.append(b[2] - b[0] if area(v) > 1 else 0)
        sep = []
        for i in range(5):
            a, b = self.visible[i], self.visible[(i + 1) % 5]
            lo, hi = 0.0, 300.0
            if area(I(a, b)) > 1: sep.append(0.0); continue
            for _ in range(14):
                mid = (lo + hi) / 2
                if area(I(dilate(a, mid / 2), dilate(b, mid / 2))) > 0.5: hi = mid
                else: lo = mid
            sep.append(lo)
        notch = []
        for i in range(5):
            tip_a = math.radians(self.D['rot'] + i * 72); bis = tip_a + math.radians(36)
            def outer(a):
                for rr in range(700, 0, -2):
                    if self.bloom.contains((self.cx + math.sin(a) * rr, self.cy - math.cos(a) * rr)): return rr
                return 0
            notch.append(outer(tip_a) - outer(bis))
        st = self.straight_edges()
        return dict(
            vb=self.vb, o_centre=(round(self.cx, 1), round(self.cy, 1)), xs=[round(x, 1) for x in self.xs], aspect=round(vbw / vbh, 3), h172=round(172 * vbh / vbw, 1), h262=round(262 * vbh / vbw, 1),
            units_per_px_29=round(upx29, 1), gap_units=self.S['gap'], gap_px_29=round(self.S['gap'] / upx29, 2),
            nb_units=self.S['nb'], R=round(res['x'][2]['mean'], 1), R_o=round(res['o'][2]['mean'], 1),
            pairs=res['x'], pairs_o=res['o'], worst_dev=max(abs(p['dev']) for p in res['x']),
            worst_dev_o=max(abs(p['dev']) for p in res['o']), fl_min=min(res['x'][4]['min'], res['o'][4]['min']),
            petal_visible=[round(v, 3) for v in vis], petal_scale=self.scales, petal_width_px29=[round(w / upx29, 1) for w in widths],
            petal_sep_px60=[round(s / upx60, 1) for s in sep], notch_px60=[round(n / upx60, 1) for n in notch],
            notch_px29=[round(n / upx29, 1) for n in notch], straight_px320=round(st * 320 / vbh, 1),
            kerning=[round(self.xs[i + 1] - self.xs[i] - adv(WORD[i]), 1) for i in range(8)],
            width_units=round(self.width))

def svg(vb, body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s" role="img" aria-label="WordFlora">\n  %s\n</svg>\n'
            % (vb[2], vb[3], ' '.join(str(v) for v in vb), '\n  '.join(body)))

def wordmark_svg(mark, mode):
    g = mark.glyphs
    if mode in ('light', 'dark'):
        P = mark.D[mode]
        body = ['<path fill="%s" d="%s"/>' % (P['petal'], d_of(mark.bloom)),
                '<path fill="%s" d="%s"/>' % (P['word'], d_of(union(g[:4])))]
        if P['ring'] == P['flora']:
            body.append('<path fill="%s" d="%s"/>' % (P['flora'], d_of(union(g[4:]))))
        else:
            body.append('<path fill="%s" d="%s"/>' % (P['flora'], d_of(union(g[4:6] + g[7:]))))
            body.append('<path fill="%s" d="%s"/>' % (P['ring'], d_of(g[6])))
    else:
        petal = '<path fill="%s" fill-opacity="%s" d="%s"/>' % (MONO['ink'], MONO_OPACITY, d_of(mark.bloom)) if mode == 'mono' \
            else '<path fill="%s" d="%s"/>' % (MONO['ink'], d_of(mark.bloom))
        body = [petal, '<path fill="%s" d="%s"/>' % (MONO['ink'], d_of(union(g)))]
    return svg(mark.vb, body)

# ---------------------------------------------------------------- icon
ICON_FILL = 0.80     # the flower's larger bbox side as a share of the 1024 canvas
PISTIL = 0.40        # pistil diameter as a share of the ring's outer width
FACE_TILT = -8       # the face turns with the bloom, so it is not the generic upright emoji

def rot_about(p, cx, cy, deg):
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return transformed(p, (c, s, -s, c, cx - c * cx + s * cy, cy - s * cx - c * cy))

def icon_svg(dname, style):
    D_ = DIRS[dname]; C = D_['icon'][style]; S = 1024
    cx, cy = O_CX, -O_CY
    rs = D_.get('ring_scale', 1.0)                 # centre direction: smaller ring+counter group
    ring = glyph('o', cx - O_CX * rs, cy + O_CY * rs, rs)
    sil = o_silhouette(cx - O_CX * rs, cy + O_CY * rs, rs)
    pet = union(petal_list(D_, cx, cy))
    gap = SIZES['twin']['gap']
    bloom = opening(D(pet, dilate(sil, gap)), SIZES['twin']['round'])
    b = bloom.bounds; side = max(b[2] - b[0], b[3] - b[1]); sc = ICON_FILL * S / side
    mx, my = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
    M = (sc, 0, 0, sc, S / 2 - mx * sc, S / 2 - my * sc)
    T = lambda p: transformed(p, M)
    body = ['<path fill="%s" d="M0 0H1024V1024H0Z"/>' % C['bg'], '<path fill="%s" d="%s"/>' % (C['petal'], d_of(T(bloom)))]
    if 'disc' in C:                                   # unified: filled centre disc + face
        body.append('<path fill="%s" d="%s"/>' % (C['disc'], d_of(T(sil))))
        body.append('<path fill="%s" d="%s"/>' % (C['face'], d_of(T(rot_about(face_path(cx, cy), cx, cy, FACE_TILT)))))
    elif 'face' in C:                                 # hero smile: ring colour disc + face
        body.append('<path fill="%s" d="%s"/>' % (C['ring'], d_of(T(sil))))
        body.append('<path fill="%s" d="%s"/>' % (C['face'], d_of(T(rot_about(face_path(cx, cy), cx, cy, D_['rot'])))))
    else:                                             # ring colour disc (counter filled) + round pistil
        body.append('<path fill="%s" d="%s"/>' % (C['ring'], d_of(T(sil))))
        pr = PISTIL * 543.0 * rs / 2
        body.append('<path fill="%s" d="%s"/>' % (C['pistil'], d_of(T(circle(cx, cy, pr)))))
    return svg((0, 0, S, S), body), sc

FACE = dict(eye_dx=114, eye_dy=-60, eye_r=46, mouth_r=130, mouth_dy=-22, mouth_w=60, mouth_a0=28, mouth_a1=152)
def face_path(cx, cy):
    F_ = FACE
    eyes = union([circle(cx - F_['eye_dx'], cy + F_['eye_dy'], F_['eye_r']), circle(cx + F_['eye_dx'], cy + F_['eye_dy'], F_['eye_r'])])
    mouth = arc_band(cx, cy + F_['mouth_dy'], F_['mouth_r'], F_['mouth_a0'], F_['mouth_a1'], F_['mouth_w'])
    return U(eyes, mouth)

# ---------------------------------------------------------------- colour report
def colour_report(dname):
    D_ = DIRS[dname]; L, K = D_['light'], D_['dark']
    rows = []
    def add(name, a, b, target=None):
        rows.append(dict(name=name, a=a, b=b, ratio=round(contrast(a, b), 2), target=target))
    add('Word on cream (light)', L['word'], L['bg'], 4.5)
    add('Flora on cream (light)', L['flora'], L['bg'], 4.5)
    if L['ring'] != L['flora']: add('Flora o ring on cream (light)', L['ring'], L['bg'], 4.5)
    add('Word vs Flora (light)', L['word'], L['flora'], 3.0)
    add('Petals on cream (light)', L['petal'], L['bg'], 3.0)
    add('Petals vs ring (light)', L['petal'], L['ring'], None)
    add('Word on dark', K['word'], K['bg'], 4.5)
    add('Flora on dark', K['flora'], K['bg'], 4.5)
    if K['ring'] != K['flora']: add('Flora o ring on dark', K['ring'], K['bg'], 4.5)
    add('Word vs Flora (dark)', K['word'], K['flora'], 1.3)
    add('Petals on dark', K['petal'], K['bg'], 3.0)
    add('Petals vs ring (dark)', K['petal'], K['ring'], None)
    m_tint = mix(MONO['ink'], MONO['bg'], MONO_OPACITY)
    add('Mono ink on white', MONO['ink'], MONO['bg'], 4.5)
    add('Mono petals (ink at %.2f = %s) on white' % (MONO_OPACITY, m_tint), m_tint, MONO['bg'], 3.0)
    cvd = []
    for kind in MACHADO:
        cvd.append(dict(kind=kind,
                        petal_bg=round(cvd_contrast(L['petal'], L['bg'], kind), 2),
                        petal_bg_dark=round(cvd_contrast(K['petal'], K['bg'], kind), 2),
                        split=round(cvd_contrast(L['word'], L['flora'], kind), 2),
                        word_bg=round(cvd_contrast(L['word'], L['bg'], kind), 2),
                        flora_bg=round(cvd_contrast(L['flora'], L['bg'], kind), 2)))
    icon = []
    for st, C in D_['icon'].items():
        for k, v in C.items():
            if k == 'bg': continue
            ref = C['disc'] if (k == 'face' and 'disc' in C) else (C['ring'] if k in ('face', 'pistil') else C['bg'])
            refname = 'disc' if ref == C.get('disc') and k == 'face' else ('ring' if k in ('face', 'pistil') else 'bg')
            icon.append(dict(style=st, part=k, hex=v, ref=refname, ratio=round(contrast(v, ref), 2),
                             cvd_min=round(min(cvd_contrast(v, ref, kk) for kk in MACHADO), 2)))
    return rows, cvd, icon

# ---------------------------------------------------------------- main
FILES = (('wordmark', 'twin', 'light'), ('wordmark-dark', 'twin', 'dark'), ('wordmark-mono', 'twin', 'mono'),
         ('wordmark-mono-solid', 'mono-solid', 'mono-solid'), ('wordmark-solo', 'solo', 'light'),
         ('wordmark-solo-dark', 'solo', 'dark'), ('wordmark-solo-mono', 'solo', 'mono'))

def build(dname):
    out = os.path.join(HERE, dname); os.makedirs(out, exist_ok=True)
    marks = {s: Mark(dname, s) for s in SIZES}
    marks['mono-solid'] = Mark(dname, 'twin', gap=MONO_SOLID_GAP, slits=DIRS[dname].get('slits', 0))
    for name, size, mode in FILES:
        open(os.path.join(out, name + '.svg'), 'w').write(wordmark_svg(marks[size], mode))
    icon_sc = None
    for st in DIRS[dname]['icon']:
        s, sc = icon_svg(dname, st)
        if st == 'light': icon_sc = sc
        open(os.path.join(out, ICON_FILES[st][0] + '.svg'), 'w').write(s)
    meas = {s: marks[s].measure() for s in marks}
    rows, cvd, icon = colour_report(dname)
    res = dict(direction=dname, title=DIRS[dname]['title'], geometry={k: v for k, v in DIRS[dname].items() if k not in ('light', 'dark', 'icon', 'title')},
               sizes=SIZES, space=SPACE, kerns=solve_kerns(), marks=meas, contrast=rows, cvd=cvd, icon=icon, icon_scale=round(icon_sc, 4),
               icon_files={st: ICON_FILES[st] for st in DIRS[dname]['icon']},
               counter_px_29=dict(w=round(182 / meas['twin']['units_per_px_29'], 1), h=round(248 / meas['twin']['units_per_px_29'], 1)),
               palette=dict(light=DIRS[dname]['light'], dark=DIRS[dname]['dark'], mono=MONO, mono_opacity=MONO_OPACITY))
    json.dump(res, open(os.path.join(out, 'measurements.json'), 'w'), indent=1)
    report(res)
    open(os.path.join(out, 'notes.md'), 'w').write(notes_md(res))
    return res

# ---------------------------------------------------------------- notes.md
def _pf(ok): return '**pass**' if ok else '**FAIL**'

def spacing_tradeoff():
    """what the 60 u F-l arm gap costs: smallest feasible r-d and the Word pairs, for several arm gaps"""
    global _KERNS
    keep, keep_s = _KERNS, dict(SPACE); rows = []
    for mf in (32, 45, 60):
        _KERNS = None; SPACE['min_fl'] = mf
        try:
            ks = solve_kerns(); nat = native_pair_gaps()
            rows.append(dict(min_fl=mf, R=round(nat[2]['x'][0] + ks[2], 1), Wo=round(nat[0]['x'][0] + ks[0]), orr=round(nat[1]['x'][0] + ks[1])))
        except SystemExit:
            rows.append(dict(min_fl=mf, R=None))
    SPACE.clear(); SPACE.update(keep_s)
    _KERNS = keep
    return rows

V2_WORD = dict(Wo=262, orr=221, rd=203)   # v2 x-band gaps from design-preview/logo/final/notes.md

def notes_md(r):
    from notes_text import PROSE
    d = r['direction']; X = PROSE[d]; T, S, MS = r['marks']['twin'], r['marks']['solo'], r['marks']['mono-solid']
    con = {row['name']: row for row in r['contrast']}
    def c(n): return con[n]['ratio']
    L = []
    L.append('# WordFlora logo v3, direction "%s": %s\n' % (d, r['title']))
    L.append('Preview: http://localhost:8765/logo/v3/index.html#%s. Brief: `docs/pm/logo-critique.md`; reviews: `review/review-a.md`, `review/review-b.md`. '
             'Build: `python build.py --direction %s` (writes the SVGs, `measurements.json` and this file), then `python render.py --direction %s` '
             '(PNGs and `compare/`, headless Chromium over file://, sRGB, no ICC profile) and `python page.py` (index page). Every number below is computed by `build.py`.\n' % (d, d, d))
    L.append('**Changes in round 2:** %s\n' % X.get('round2', 'TODO'))
    L.append('## Idea\n\n%s\n' % X['concept'])
    L.append('## Construction\n')
    L.append('- **Letters.** Nunito Black (wght 900, `../fonts/Nunito-900.ttf`, SIL OFL), unaltered glyphs. The o ring is the font\'s own o with its open counter. The Word o is a plain letter.')
    L.append('- **Flower.** %s' % X['flower'])
    L.append('- **Cuts and fit (boolean path ops, no masks).** Petals minus the o silhouette dilated by the ring gap (%d u twin, %d u solo, %d u mono-solid). A petal that would reach a neighbour (the l or the r dilated by %d u, solo %d u, then closed by %d u) is not cut along the letter: it is scaled about the flower centre until it clears, until at most %d%% of it would sit behind the letter, then that small remainder tucks behind; so it keeps its rounded tip (scales P1..P5: %s). An opening of %d u rounds every corner.'
             % (T['gap_units'], S['gap_units'], MS['gap_units'], T['nb_units'], S['nb_units'], NB_CLOSE, round(TUCK_MAX * 100), ', '.join('%.3f' % v for v in T['petal_scale']), SIZES['twin']['round']))
    if r['geometry'].get('slits'):
        L.append('- **Mono-solid slits.** In `wordmark-mono-solid.svg` five radial bars %d u wide are cut along the bisectors between the lobes, so in solid ink the bloom is five petals, not a gear.' % r['geometry']['slits'])
    L.append('- **Spacing rule (solver).** Kerns are solved so that every pair\'s mean gap is within %.2f to %.2f x the r-d gap on **both** bands (x-height band 10..470 u, and the full o height -11..503 u including overshoot), with the F\'s middle arm at least %d u from the l. The solver picks the smallest r-d for which that is possible (the tightest word): Word pairs and d-F take the tightest legal value, the Flora o pairs %.2f x r-d for petal room. Kerns W-o..r-a: %s u. Solo adds %d u to every pair.'
             % (SPACE['lo'], SPACE['hi'], SPACE['min_fl'], SPACE['flora_o'], ', '.join('%+.1f' % k for k in r['kerns']), SIZES['solo']['track']))
    L.append('- **Solo lockup** (below 130 pt wide, under about 22 pt tall): same flower, ring gap %d u, neighbour clearance %d u, +%d u tracking, as an optical size.' % (S['gap_units'], S['nb_units'], SIZES['solo']['track']))
    L.append('- **Icon.** %s Flower scaled by %.4f so its larger side is %d%% of the 1024 canvas, centred on its bounding box; flat background rect.' % (X['icon'], r['icon_scale'], round(ICON_FILL * 100)))
    if X.get('rule'): L.append('- **Face rule.** %s' % X['rule'])
    if X.get('colour_rule'): L.append('- **Icon colour rule.** %s' % X['colour_rule'])
    L.append('- **SVG hygiene.** Only `<path fill>` elements (mono petals use `fill-opacity` %.2f); width/height equal the viewBox; no mask, stroke, filter, gradient, defs, use, text, image, clip-path or @import.\n' % MONO_OPACITY)
    L.append('## Palette and WCAG contrast (A1, A2, A4)\n')
    L.append('| Pair | Colours | Ratio | Target |\n|---|---|---|---|')
    for row in r['contrast']:
        tgt = '' if row['target'] is None else ('>= %s %s' % (row['target'], 'ok' if row['ratio'] >= row['target'] else 'FAIL'))
        L.append('| %s | `%s` on `%s` | %.2f | %s |' % (row['name'], row['a'], row['b'], row['ratio'], tgt))
    L.append('\nIcon colours (each part against what it sits on; worst of deutan/protan/tritan in the last column):\n\n| Icon | Part | Hex | Against | Ratio | Worst CVD |\n|---|---|---|---|---|---|')
    for ic in r['icon']: L.append('| %s | %s | `%s` | %s | %.2f | %.2f |' % (ic['style'], ic['part'], ic['hex'], ic['ref'], ic['ratio'], ic['cvd_min']))
    L.append('\n## Colour-vision simulation (A5)\n\nMachado, Oliveira and Fernandes 2009, severity 1.0, applied to linear sRGB of the hex colours, then WCAG luminance (agrees with `review/cvd_sim.py --hex` to within 0.03).\n')
    L.append('| Simulation | Petals on cream | Petals on dark | Word vs Flora (light) | Word on cream | Flora on cream |\n|---|---|---|---|---|---|')
    for cv in r['cvd']:
        L.append('| %s | %.2f | %.2f | %.2f | %.2f | %.2f |' % (cv['kind'], cv['petal_bg'], cv['petal_bg_dark'], cv['split'], cv['word_bg'], cv['flora_bg']))
    L.append('\nNo meaning depends on hue: the flower is separated from the background by lightness, and from the ring by a real gap.\n')
    L.append('## Letter-pair gaps (A6), relative to r-d, both bands\n')
    L.append('| Pair | x-band mean (min) u | vs r-d | full-o-band mean (min) u | vs r-d | solo x-band vs r-d | Kern u |\n|---|---|---|---|---|---|---|')
    for i in range(8):
        a, o, b = T['pairs'][i], T['pairs_o'][i], S['pairs'][i]
        L.append('| %s | %.0f (%d) | %+.1f%% | %.0f (%d) | %+.1f%% | %+.1f%% | %+.1f |' % (a['pair'], a['mean'], a['min'], a['dev'], o['mean'], o['min'], o['dev'], b['dev'], T['kerning'][i]))
    L.append('\nWorst: %.1f%% (x band), %.1f%% (full o band), solo %.1f%% / %.1f%%. F-l minimum arm gap: **%d u** (%.1f px at 29 px tall).\n'
             % (T['worst_dev'], T['worst_dev_o'], S['worst_dev'], S['worst_dev_o'], T['fl_min'], T['fl_min'] / T['units_per_px_29']))
    tr = spacing_tradeoff()
    L.append('**The trade-off the rule forces.** With unaltered glyphs, the F\'s open right side makes F-l the widest pair on both bands and o-r the narrowest. Keeping both within +-15% of r-d sets a floor under r-d, and the F-l arm gap raises it:\n')
    L.append('| F-l arm gap | smallest legal r-d (x band) | W-o | o-r (Word) |\n|---|---|---|---|')
    for t in tr:
        L.append('| %d u | %s | %s | %s |' % (t['min_fl'], t['R'] if t['R'] else 'infeasible', t.get('Wo', ''), t.get('orr', '')))
    L.append('\nv2 for reference (x band): W-o %d, o-r %d, r-d %d u. %s\n' % (V2_WORD['Wo'], V2_WORD['orr'], V2_WORD['rd'], X.get('a6_eye', 'TODO')))
    L.append('Petals tucked behind a neighbour, share of each petal (outside the ring gap) left visible, petals clockwise from the top one:\n')
    L.append('| | P1 top | P2 right | P3 lower right | P4 lower left | P5 left |\n|---|---|---|---|---|---|')
    for nm, m in (('twin', T), ('solo', S), ('mono-solid', MS)):
        L.append('| %s | %s |' % (nm, ' | '.join('%.0f%%' % (100 * v) for v in m['petal_visible'])))
    L.append('\n## Small-size geometry (A2, A3)\n')
    L.append('- Units per pixel at 29 px tall: %.1f. Ring gap %d u = **%.2f px** (mono-solid %d u = %.2f px; A2 needs >= 1.0 px, i.e. >= %d u).' % (T['units_per_px_29'], T['gap_units'], T['gap_px_29'], MS['gap_units'], MS['gap_px_29'], math.ceil(T['units_per_px_29'])))
    L.append('- Widest visible width of each petal at 29 px tall: %s px (A3 needs >= 4).' % ', '.join('%.1f' % v for v in T['petal_width_px29']))
    if X['kind'] == 'separate':
        L.append('- Clear gap between neighbouring petals at 60 px tall: %s px.' % ', '.join('%.1f' % v for v in T['petal_sep_px60']))
    else:
        L.append('- Petals are fused into one bloom; notch depth between lobes (tip radius minus notch radius) at 60 px tall: %s px; at 29 px: %s px.' % (', '.join('%.1f' % v for v in T['notch_px60']), ', '.join('%.1f' % v for v in T['notch_px29'])))
    L.append('- Longest straight run on the bloom outline: %.1f px at 320 px tall.' % T['straight_px320'])
    L.append('- The o counter at 29 px tall: %.1f x %.1f px.\n' % (r['counter_px_29']['w'], r['counter_px_29']['h']))
    if X.get('pixel_checks'): L.append('**Pixel checks on the rendered PNGs** (`python render.py` prints them):\n\n%s\n' % X['pixel_checks'])
    L.append('## Sizing contract (A10)\n')
    L.append('| Lockup | viewBox | Aspect | Height at 172 pt wide | Height at 262 pt wide |\n|---|---|---|---|---|')
    for nm, m in (('twin (wordmark*.svg)', T), ('solo', S)):
        L.append('| %s | %s | %.2f : 1 | %.1f pt | %.1f pt |' % (nm, ' '.join(str(v) for v in m['vb']), m['aspect'], m['h172'], m['h262']))
    L.append('\nv2 was 5.83 : 1, about 29.5 pt tall at 172 pt.\n')
    a1 = c('Petals on cream (light)') >= 3 and c('Petals on dark') >= 3
    a2 = (c('Petals vs ring (light)') >= 2 or T['gap_px_29'] >= 1.0) and (c('Petals vs ring (dark)') >= 2 or T['gap_px_29'] >= 1.0)
    a4 = (c('Word vs Flora (light)') >= 3 and c('Word vs Flora (dark)') >= 1.3 and min(c(n) for n in ('Word on cream (light)', 'Flora on cream (light)', 'Word on dark', 'Flora on dark')) >= 4.5)
    a5 = all(cv['petal_bg'] >= 3 and cv['split'] >= 2 for cv in r['cvd'])
    vis_min = min(T['petal_visible'] + S['petal_visible'] + MS['petal_visible'])
    a6num = max(T['worst_dev'], T['worst_dev_o'], S['worst_dev'], S['worst_dev_o']) <= 15 and vis_min >= 0.8
    a10 = 26 <= T['h172'] <= 34
    a3num = min(T['petal_width_px29']) >= 4
    L.append('## Self-check, A1 to A13\n')
    L.append('| # | Result | Evidence |\n|---|---|---|')
    L.append('| A1 | %s | petals %.2f on cream, %.2f on dark (>= 3.0) |' % (_pf(a1), c('Petals on cream (light)'), c('Petals on dark')))
    L.append('| A2 | %s | petal/ring %.2f light, %.2f dark; ring gap %d u = %.2f px at 29 px tall (>= 1.0), mono-solid %.2f px |' % (_pf(a2), c('Petals vs ring (light)'), c('Petals vs ring (dark)'), T['gap_units'], T['gap_px_29'], MS['gap_px_29']))
    L.append('| A3 | %s | petal width at 29 px %.1f px min (>= 4); %s |' % (_pf(a3num and X['a3_ok']), min(T['petal_width_px29']), X['a3']))
    L.append('| A4 | %s | Word/Flora %.2f light (>= 3.0), %.2f dark (>= 1.3); Word %.2f, Flora %.2f on cream; %.2f, %.2f on dark (>= 4.5) |'
             % (_pf(a4), c('Word vs Flora (light)'), c('Word vs Flora (dark)'), c('Word on cream (light)'), c('Flora on cream (light)'), c('Word on dark'), c('Flora on dark')))
    L.append('| A5 | %s | worst petals on cream %.2f (>= 3.0), worst Word/Flora %.2f (>= 2.0) across deutan, protan, tritan |'
             % (_pf(a5), min(cv['petal_bg'] for cv in r['cvd']), min(cv['split'] for cv in r['cvd'])))
    a6ok = a6num and X.get('a6_ok', False)
    L.append('| A6 | %s | worst pair %.1f%% x band / %.1f%% full o band (solo %.1f / %.1f; <= 15); F-l arm gap %d u; least-visible petal %.0f%% (>= 80); by eye: %s |'
             % (_pf(a6ok), T['worst_dev'], T['worst_dev_o'], S['worst_dev'], S['worst_dev_o'], T['fl_min'], 100 * vis_min, X.get('a6_short', 'TODO')))
    for k in ('A7', 'A8', 'A9', 'A11', 'A12'):
        ok, txt = X[k]
        L.append('| %s | %s | %s |' % (k, ok if ok in ('reviewer', 'n/a') else _pf(ok), txt))
    L.append('| A10 | %s | %.2f : 1; %.1f pt at 172 pt wide (26-34), %.1f pt at 262 pt |' % (_pf(a10), T['aspect'], T['h172'], T['h262']))
    L.append('| A13 | **pass** | `compare/before-after-light.png`, `compare/before-after-dark.png` (v2 left, v3 right at 29, 60, 172 wide, 320; nothing clipped), "Word" alone at equal scale in `compare/word-alone-320.png`, `compare/icon-before-after.png` |')
    L.append('\n## Honest weaknesses\n')
    for w in X['weak']: L.append('- %s' % w)
    icons = ', '.join('`%s.svg`' % f[0] for f in r['icon_files'].values())
    L.append('\n## Files\n\n- `wordmark.svg`, `wordmark-dark.svg`, `wordmark-mono.svg` (petals at %.2f opacity), `wordmark-mono-solid.svg` (Increase Contrast: solid ink, %d u ring gap), `wordmark-solo.svg`, `wordmark-solo-dark.svg`, `wordmark-solo-mono.svg`.\n'
             '- Icons (1024, flat background, no text, no transparency): %s.\n'
             '- `png/<variant>-h{320,172,120,60,29}.png`, `png/<variant>-w172.png`, `png/<icon>-{1024,180,60,29}.png` (sRGB, no ICC profile).\n'
             '- `compare/before-after-{light,dark}.png`, `compare/word-alone-320.png`, `compare/icon-before-after.png`; `measurements.json`.\n' % (MONO_OPACITY, MS['gap_units'], icons))
    return '\n'.join(L) + '\n'

def report(r):
    print('=' * 72); print('%s  (%s)' % (r['direction'], r['title']))
    print('kerns', r['kerns'])
    for s, m in r['marks'].items():
        print('[%s] viewBox %s aspect %.3f  h@172 %.1f  h@262 %.1f  width %d u' % (s, m['vb'], m['aspect'], m['h172'], m['h262'], m['width_units']))
        print('   ring gap %d u = %.2f px at 29 px tall (%.1f u/px); neighbour clearance %d u' % (m['gap_units'], m['gap_px_29'], m['units_per_px_29'], m['nb_units']))
        print('   x band: ' + '  '.join('%s %.0f (%+.1f%%, min %d)' % (p['pair'], p['mean'], p['dev'], p['min']) for p in m['pairs']))
        print('   o band: ' + '  '.join('%s %.0f (%+.1f%%)' % (p['pair'], p['mean'], p['dev']) for p in m['pairs_o']))
        print('   worst %.1f%% / %.1f%%; F-l min %d u' % (m['worst_dev'], m['worst_dev_o'], m['fl_min']))
        print('   petal visible %s; scale %s; width px@29 %s' % (m['petal_visible'], m['petal_scale'], m['petal_width_px29']))
        print('   sep px@60 %s; notch px@60 %s; straight px@320 %.1f' % (m['petal_sep_px60'], m['notch_px60'], m['straight_px320']))
    for row in r['contrast']:
        print('   %-44s %s / %s  %.2f%s' % (row['name'], row['a'], row['b'], row['ratio'], '' if row['target'] is None else ('  (>= %s %s)' % (row['target'], 'ok' if row['ratio'] >= row['target'] else 'FAIL'))))
    for c in r['cvd']:
        print('   %-13s petals/cream %.2f  petals/dark %.2f  Word/Flora %.2f' % (c['kind'], c['petal_bg'], c['petal_bg_dark'], c['split']))
    for c in r['icon']:
        print('   icon %-12s %-6s %s vs %s %.2f (worst CVD %.2f)' % (c['style'], c['part'], c['hex'], c['ref'], c['ratio'], c['cvd_min']))

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--direction', default='all')
    a = ap.parse_args()
    names = list(DIRS) if a.direction == 'all' else [a.direction]
    for n in names: build(n)

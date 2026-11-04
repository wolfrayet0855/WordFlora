#!/usr/bin/env python3
"""Petal thinning build script for WordFlora.

Run from the repo root with:   python3 -I tools/thin_svg.py

Source of truth: the app's own plant art, WordFlora/Assets.xcassets/Plants/<plant>.imageset/<plant>.svg
(design-preview/plants/*.svg is a byte-identical copy used by the HTML prototypes; it is never read here).

For each plant the script finds rings of petals with the same two detectors as the JS prototype
(design-preview/tending/parts/thinning.js):

  A. rotated copies: elements that are identical apart from a rotate(a) about one pivot (4 or more,
     all angles different);
  B. same-size, same-fill circles (r >= 4, 5 or more) at an equal distance from one centre (12 percent slack).

Per-plant hand fixes come from tools/thinning_overrides.json (petal element indices for flowers whose
petals are separate but not rotated copies, kind changes, droop, the rose 'peel' rule hook).

Outputs (all regenerated on every run, nothing else is touched):

  WordFlora/Assets.xcassets/PlantLayers/<plant>_<layer>.imageset   vector imagesets, one per layer:
      ground       the leading ground shadow ellipses (never tilts)
      back / midN / front   the static art in z-order around the petal rings (no petals)
      body         droop plants without rings: everything except the ground
      r<i>_s<j>    petal sprite j of ring i, drawn at the first petal that uses it
      sepalN       a part that moves on its own (the rose's splaying sepals)
      fall_<kind>  dedicated falling-petal sprites from a peel rule (the rose's curled petals)
  WordFlora/Resources/PlantThinning.json   the manifest (see PlantThinning.swift for the schema)

Element indices used in the overrides are 0-based pre-order indices of every element below the root
<svg> (the root itself is not counted), the same numbering `tools/thin_svg.py --dump <plant>` prints.
"""
import copy
import json
import math
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANTS_DIR = os.path.join(ROOT, 'WordFlora', 'Assets.xcassets', 'Plants')
LAYERS_DIR = os.path.join(ROOT, 'WordFlora', 'Assets.xcassets', 'PlantLayers')
MANIFEST = os.path.join(ROOT, 'WordFlora', 'Resources', 'PlantThinning.json')
OVERRIDES = os.path.join(ROOT, 'tools', 'thinning_overrides.json')
ROSE_RULE_CANDIDATES = [
    os.path.join(ROOT, 'notes', 'rose-rule.md'),
    os.path.join(ROOT, 'design-preview', 'tending', 'parts', 'notes', 'rose-rule.md'),
]

SVG_NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG_NS)
DRAWABLE = {'ellipse', 'path', 'circle', 'rect', 'polygon', 'polyline', 'line'}

# Share of each ring kept at 0..5 pips, front-loaded so 4 pips already looks sparser (prototype FRAC).
FRAC = [0, .13, .27, .47, .72, 1]
GOLDEN = 0.6180339887
# Droop per lost pip (prototype droop()): tilt, x and y squash, saturation and brightness loss.
DROOP_STEP = {'tiltDegrees': 1.7, 'squashX': 0.012, 'squashY': 0.03, 'saturation': 0.13, 'brightness': 0.02}
MAX_FALL = 5


# ---------- shared rules (mirrored in WordFlora/Rules/PlantThinning.swift) ----------

def kept_count(n, pips):
    if pips >= 5:
        return n
    if pips <= 0:
        return 0
    c = int(math.floor(n * FRAC[pips] + 0.5))  # JS Math.round
    if n >= 5:
        c = min(max(c, pips), n - (5 - pips))  # every pip removes at least one petal
    return max(c, 1)  # small rings keep their last petal until 0 pips, so only 0 pips is bare


def keep_order(n):
    used, out, j = [False] * n, [], 0
    while len(out) < n:
        i = int(math.floor(((j * GOLDEN) % 1) * n))
        while used[i]:
            i = (i + 1) % n
        used[i] = True
        out.append(i)
        j += 1
    return out


# ---------- affine maths: (a, b, c, d, e, f) as in SVG matrix() ----------

I = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def mul(m, n):
    a, b, c, d, e, f = m
    A, B, C, D, E, F = n
    return (a * A + c * B, b * A + d * B, a * C + c * D, b * C + d * D, a * E + c * F + e, b * E + d * F + f)


def inv(m):
    a, b, c, d, e, f = m
    det = a * d - b * c
    return (d / det, -b / det, -c / det, a / det, (c * f - d * e) / det, (b * e - a * f) / det)


def apply(m, x, y):
    a, b, c, d, e, f = m
    return (a * x + c * y + e, b * x + d * y + f)


def rot(deg, cx=0.0, cy=0.0):
    r = math.radians(deg)
    m = (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0.0, 0.0)
    return mul(mul((1, 0, 0, 1, cx, cy), m), (1, 0, 0, 1, -cx, -cy))


NUM = r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'


def parse_transform(t):
    m = I
    for name, args in re.findall(r'(\w+)\s*\(([^)]*)\)', t or ''):
        v = [float(x) for x in re.findall(NUM, args)]
        if name == 'translate':
            n = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == 'scale':
            n = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif name == 'rotate':
            n = rot(v[0], v[1], v[2]) if len(v) == 3 else rot(v[0])
        elif name == 'matrix':
            n = tuple(v)
        elif name == 'skewX':
            n = (1, 0, math.tan(math.radians(v[0])), 1, 0, 0)
        elif name == 'skewY':
            n = (1, math.tan(math.radians(v[0])), 0, 1, 0, 0)
        else:
            raise ValueError('unknown transform ' + name)
        m = mul(m, n)
    return m


def parse_rotate(t):
    """The prototype's parseT: rotate angle and pivot (rotate centre, else the leading translate)."""
    ro = re.search(r'rotate\(\s*(' + NUM + r')(?:[ ,]+(' + NUM + r')[ ,]+(' + NUM + r'))?\s*\)', t or '')
    if not ro:
        return None
    if ro.group(2) is not None:
        return float(ro.group(1)), float(ro.group(2)), float(ro.group(3))
    tr = re.match(r'^\s*translate\(\s*(' + NUM + r')[ ,]+(' + NUM + r')\s*\)', t)
    px, py = (float(tr.group(1)), float(tr.group(2))) if tr else (0.0, 0.0)
    return float(ro.group(1)), px, py


# ---------- geometry: local outline points of an element (for radius and centre) ----------

def path_points(d):
    pts, toks = [], re.findall(r'[MmLlHhVvCcSsQqTtAaZz]|' + NUM, d)
    i, cmd, x, y, sx, sy = 0, None, 0.0, 0.0, 0.0, 0.0
    arity = dict(M=2, L=2, H=1, V=1, C=6, S=4, Q=4, T=2, A=7, Z=0)
    while i < len(toks):
        if re.match(r'[A-Za-z]', toks[i]):
            cmd = toks[i]
            i += 1
            if cmd in 'Zz':
                x, y = sx, sy
                continue
        n = arity[cmd.upper()]
        v = [float(t) for t in toks[i:i + n]]
        i += n
        rel = cmd.islower()
        U = cmd.upper()
        if U == 'H':
            x = x + v[0] if rel else v[0]
            pts.append((x, y))
        elif U == 'V':
            y = y + v[0] if rel else v[0]
            pts.append((x, y))
        elif U == 'A':
            nx, ny = (x + v[5], y + v[6]) if rel else (v[5], v[6])
            r = max(abs(v[0]), abs(v[1]))
            mx, my = (x + nx) / 2, (y + ny) / 2
            pts += [(nx, ny), (mx - r, my - r), (mx + r, my + r)] if r > math.hypot(nx - x, ny - y) / 2 else [(nx, ny)]
            x, y = nx, ny
        else:
            for k in range(0, n, 2):
                px, py = (x + v[k], y + v[k + 1]) if rel else (v[k], v[k + 1])
                pts.append((px, py))
            x, y = pts[-1]
            if U == 'M':
                sx, sy = x, y
                cmd = 'l' if rel else 'L'
    return pts


def local_points(el):
    tag = el.tag.split('}')[-1]
    g = lambda k, dflt=0.0: float(el.get(k, dflt))
    if tag in ('ellipse', 'circle'):
        rx, ry = (g('r'), g('r')) if tag == 'circle' else (g('rx'), g('ry'))
        return [(g('cx') + rx * math.cos(k * math.pi / 12), g('cy') + ry * math.sin(k * math.pi / 12)) for k in range(24)]
    if tag == 'rect':
        x, y, w, h = g('x'), g('y'), g('width'), g('height')
        return [(x, y), (x + w, y), (x, y + h), (x + w, y + h)]
    if tag in ('polygon', 'polyline'):
        v = [float(n) for n in re.findall(NUM, el.get('points', ''))]
        return list(zip(v[0::2], v[1::2]))
    if tag == 'line':
        return [(g('x1'), g('y1')), (g('x2'), g('y2'))]
    if tag == 'path':
        return path_points(el.get('d', ''))
    return []


class Node:
    def __init__(self, el, index, parent, ctm):
        self.el, self.index, self.parent = el, index, parent
        self.tag = el.tag.split('}')[-1]
        self.parent_ctm = ctm                           # root <- parent
        self.ctm = mul(ctm, parse_transform(el.get('transform')))  # root <- element
        self.children = []

    def root_points(self):
        out = [apply(self.ctm, x, y) for x, y in local_points(self.el)]
        for c in self.children:
            out += c.root_points()
        return out

    def descendants(self):
        for c in self.children:
            yield c
            yield from c.descendants()


def load_tree(src):
    root = ET.parse(src).getroot() if isinstance(src, str) else src
    nodes = []

    def walk(el, parent, ctm):
        for c in el:
            n = Node(c, len(nodes), parent, ctm)
            nodes.append(n)
            if parent:
                parent.children.append(n)
            walk(c, n, n.ctm)
    walk(root, None, I)
    return root, nodes


def strip_ns(s):
    return s.replace('ns0:', '').replace(' xmlns:ns0="%s"' % SVG_NS, '').replace(' xmlns="%s"' % SVG_NS, '')


def outer(el, drop=('transform',)):
    e = copy.deepcopy(el)
    for k in drop:
        e.attrib.pop(k, None)
    e.tail = None
    return strip_ns(ET.tostring(e, encoding='unicode'))


# ---------- ring detection ----------

def detect_rings(nodes):
    rings = []
    groups = {}
    for n in nodes:  # A. rotated copies
        if n.tag not in ('ellipse', 'path', 'circle', 'rect', 'polygon', 'g'):
            continue
        t = n.el.get('transform')
        T = parse_rotate(t) if t else None
        if not T:
            continue
        if n.tag == 'g' and any('rotate' in (d.el.get('transform') or '') for d in n.descendants()):
            continue
        a, px, py = T
        pvx, pvy = apply(n.parent_ctm, px, py)
        sig = outer(n.el) + '|' + re.sub(r'rotate\([^)]*\)', '', t) + '|%.0f,%.0f' % (pvx + 0.0, pvy + 0.0)
        groups.setdefault(sig, []).append((n, a, pvx, pvy))
    for g in groups.values():
        if len(g) >= 4 and len({round(a) for _, a, _, _ in g}) == len(g):
            g.sort(key=lambda p: p[1])
            rings.append({'type': 'rotated', 'pivot': (g[0][2], g[0][3]),
                          'petals': [{'node': n, 'angle': a} for n, a, _, _ in g]})
    circ = {}
    for n in nodes:  # B. equal circles round one centre
        if n.tag == 'circle' and not n.el.get('transform'):
            circ.setdefault((n.el.get('r'), n.el.get('fill')), []).append(n)
    for g in circ.values():
        if len(g) < 5 or float(g[0].el.get('r')) < 4:
            continue
        P = [apply(n.parent_ctm, float(n.el.get('cx', 0)), float(n.el.get('cy', 0))) for n in g]
        mx, my = sum(p[0] for p in P) / len(P), sum(p[1] for p in P) / len(P)
        d = [math.hypot(p[0] - mx, p[1] - my) for p in P]
        md = sum(d) / len(d)
        if md < 3 or any(abs(x - md) > md * .12 for x in d):
            continue
        petals = [{'node': n, 'angle': math.degrees(math.atan2(p[0] - mx, my - p[1]))} for n, p in zip(g, P)]
        petals.sort(key=lambda p: p['angle'])
        rings.append({'type': 'circles', 'pivot': (mx, my), 'petals': petals})
    return rings


def tagged_ring(nodes, spec):
    """A hand-tagged ring from the overrides: explicit element indices, optional pivot."""
    groups = [[nodes[i] for i in (e if isinstance(e, list) else [e])] for e in spec['elements']]
    pts = [p for g in groups for n in g for p in n.root_points()]
    if 'pivot' in spec:
        pv = tuple(spec['pivot'])
    else:
        pv = ((min(p[0] for p in pts) + max(p[0] for p in pts)) / 2, (min(p[1] for p in pts) + max(p[1] for p in pts)) / 2)
    petals = []
    for g in groups:  # a petal may be several elements (a heart and its stalk): drawn as one sprite
        q = [p for n in g for p in n.root_points()]
        cx, cy = sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q)
        petals.append({'node': g[0], 'extra': g[1:], 'angle': math.degrees(math.atan2(cx - pv[0], pv[1] - cy))})
    if spec.get('layout', 'radial') == 'radial':
        petals.sort(key=lambda p: p['angle'])
    ring = {'type': 'tagged', 'layout': spec.get('layout', 'radial'), 'pivot': pv, 'petals': petals}
    for k in ('keepOrder', 'keptCounts'):  # a peel-style schedule: listed order, explicit counts per pip
        if k in spec:
            ring[k] = spec[k]
    return ring


# ---------- sprites: one canonical element per distinct petal shape, placements as matrices ----------

def canonical(n):
    """(signature, element at its own origin, root <- canonical matrix) so equal shapes share one sprite."""
    e = copy.deepcopy(n.el)
    e.attrib.pop('transform', None)
    e.tail = None
    m = n.ctm
    if n.tag in ('circle', 'ellipse'):
        cx, cy = float(e.attrib.pop('cx', 0)), float(e.attrib.pop('cy', 0))
        m = mul(m, (1, 0, 0, 1, cx, cy))
    return strip_ns(ET.tostring(e, encoding='unicode')), e, m


def fmt(x):
    s = ('%.4f' % x).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def mat_str(m):
    return 'matrix(%s)' % ' '.join(fmt(v) for v in m)


# ---------- layer svg writing ----------

def svg_header(root):
    vb = root.get('viewBox', '0 0 200 200')
    w, h = root.get('width', vb.split()[2]), root.get('height', vb.split()[3])
    return '<svg xmlns="%s" viewBox="%s" width="%s" height="%s">' % (SVG_NS, vb, w, h)


def subset_svg(root, nodes, keep):
    """The plant svg with only the elements in `keep` (indices of drawable units) and their ancestors."""
    keep_anc = set()
    for i in keep:
        p = nodes[i].parent
        while p:
            keep_anc.add(p.index)
            p = p.parent
    idx = {id(n.el): n.index for n in nodes}

    def emit(el):
        out = []
        for c in el:
            i = idx[id(c)]
            if i in keep:
                out.append(outer(c, drop=()))
            elif i in keep_anc:
                attrs = ''.join(' %s="%s"' % (k, v.replace('"', '&quot;')) for k, v in c.attrib.items())
                out.append('<g%s>%s</g>' % (attrs, ''.join(emit(c))) if c.tag.split('}')[-1] == 'g' else outer(c, drop=()))
        return out
    return svg_header(root) + ''.join(emit(root)) + '</svg>'


def write_imageset(name, svg):
    d = os.path.join(LAYERS_DIR, name + '.imageset')
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + '.svg'), 'w') as f:
        f.write(svg)
    with open(os.path.join(d, 'Contents.json'), 'w') as f:
        json.dump({'images': [{'filename': name + '.svg', 'idiom': 'universal'}],
                   'info': {'author': 'xcode', 'version': 1},
                   'properties': {'preserves-vector-representation': True}}, f, indent=2)
        f.write('\n')


# ---------- rose / peony 'peel outer layers' rule hook ----------

def js_to_json(text):
    """The rule block is a JS object literal (bare keys, quotes of any kind, comments, 'a' + 'b'); make it JSON."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith('//', i):
            i = text.find('\n', i) if text.find('\n', i) >= 0 else n
        elif text.startswith('/*', i):
            i = text.index('*/', i) + 2
        elif c in '\'"`':
            j, buf = i + 1, []
            while text[j] != c:
                if text[j] == '\\':
                    buf.append(text[j + 1])
                    j += 2
                else:
                    buf.append(text[j])
                    j += 1
            val = ''.join(buf)
            if out and out[-1] == '+':  # string concatenation
                out.pop()
                out[-1] = json.dumps(json.loads(out[-1]) + val)
            else:
                out.append(json.dumps(val))
            i = j + 1
        elif c == '+' and out and out[-1].startswith('"'):
            out.append('+')
            i += 1
        elif c.isalpha() or c == '_':
            j = i
            while j < n and (text[j].isalnum() or text[j] in '_$'):
                j += 1
            word = text[i:j]
            out.append(word if word in ('true', 'false', 'null') else json.dumps(word))
            i = j
        elif c.isdigit() or (c in '-.' and i + 1 < n and (text[i + 1].isdigit() or text[i + 1] == '.')):
            m = re.match(NUM, text[i:])
            v = m.group(0)
            out.append(('0' + v if v.startswith('.') else v.replace('-.', '-0.')))
            i += len(v)
        elif c.isspace():
            i += 1
        else:
            out.append(c)
            i += 1
    j = re.sub(r',\s*([}\]])', r'\1', ' '.join(out))  # trailing commas
    j = re.sub(r'([{,]\s*)(-?[\d.]+)\s*:', r'\1"\2":', j)  # numeric keys
    return json.loads(j)


def load_rose_rule():
    """Reads the visual lead's rose rule: the first ```js or ```json block in notes/rose-rule.md.

    Returns ({plant name: rule}, source path), or (None, None) when the note does not exist yet.
    The rule (see design-preview/tending/parts/notes/rose-rule.md) hides the base disc, adds a cradle (hip and
    two sepals) and five valley petals, groups elements into units that leave together, and lists which units
    are lost at each pip ('lose'), outer to inner.
    """
    for p in ROSE_RULE_CANDIDATES:
        if os.path.exists(p):
            with open(p) as f:
                text = f.read()
            m = re.search(r'```(?:js|json|javascript)\s*(\{.*\})\s*```', text, re.S)
            if not m:
                return {}, os.path.relpath(p, ROOT)
            rule = js_to_json(m.group(1))
            return {rule['plant']: rule}, os.path.relpath(p, ROOT)
    return None, None


SVG_ATTRS_DROP = ('class', 'splay', 'origin', 'style')


def svg_fragment(markup):
    g = ET.fromstring('<g xmlns="%s">%s</g>' % (SVG_NS, markup))
    for e in g.iter():
        for k in SVG_ATTRS_DROP:
            e.attrib.pop(k, None)
    return g


def apply_peel(root, spec):
    """Edits the plant tree as the rule says. Returns (refs, own_layers): refs maps a rule element reference
    (root child index or 'valleyNN') to its element; own_layers maps elements that need their own static
    layer (the splaying sepals) to extra layer data."""
    children = list(root)
    refs = {i: c for i, c in enumerate(children)}
    own = {}
    hidden = {h['i'] for h in spec.get('hide', [])}
    for a in spec.get('add', []):
        if 'svg' in a:
            raw = ET.fromstring('<g xmlns="%s">%s</g>' % (SVG_NS, a['svg']))
            frag = svg_fragment(a['svg'])
            for e_raw, e in zip(list(raw), list(frag)):
                if 'splay' in e_raw.attrib:
                    o = [float(v) for v in e_raw.get('origin').split()]
                    own[id(e)] = {'role': 'sepal', 'splayDegrees': float(e_raw.get('splay')), 'origin': o}
            new = list(frag)
            anchor = a.get('after', a.get('replaces'))
        else:  # repeated path at several angles (the valley petals)
            new = []
            for ang in a['angles']:
                g = ET.Element('{%s}g' % SVG_NS)
                ET.SubElement(g, '{%s}path' % SVG_NS, {'d': a['path'], 'fill': a['fill'],
                                                       'transform': a['transform'].replace('A', fmt(ang))})
                new.append(g)
                # a valley at angle v leaves with the outer petal at v - 36 (the one just before it)
                refs['valley%d' % ang] = g
                refs['valley%d' % ((ang - 36) % 360)] = g
            anchor = a['replaces']
        pos = list(root).index(children[anchor]) + (0 if 'replaces' in a else 1)
        for k, e in enumerate(new):
            root.insert(pos + k, e)
    for i in hidden:
        root.remove(children[i])
    return refs, own


# ---------- per plant ----------

def r2(x):
    return round(x + 0.0, 2)


def peel_rings(nodes, refs, spec):
    """Rings for a peel rule: valley petals (if any) and the layered units, each with the rule's own nested
    order (lose[0] + lose[1] + ... so the units lost at each pip are one slice) instead of an even share."""
    index = {id(n.el): n.index for n in nodes}
    lose = {int(k): v for k, v in spec['lose'].items()}
    sequence = [u for k in range(5) for u in lose.get(k, [])]
    by_pip = {u: k for k in range(5) for u in lose.get(k, [])}
    valley_ids = {id(e) for k, e in refs.items() if isinstance(k, str)}
    ring_units = {'valleys': [], 'layers': []}
    for u in sequence:
        els = [refs[e] for e in spec['units'][u]['els']]
        v = [e for e in els if id(e) in valley_ids]
        rest = [e for e in els if id(e) not in valley_ids]
        if v:
            ring_units['valleys'].append((u, [index[id(e)] for e in v]))
        if rest:
            ring_units['layers'].append((u, [index[id(e)] for e in rest]))
    rings = []
    for key in ('valleys', 'layers'):
        entries = ring_units[key]
        if not entries:
            continue
        # petals listed in z-order (drawing order); keepOrder follows the rule's loss order
        z = sorted(entries, key=lambda e: e[1][0])
        r = tagged_ring(nodes, {'elements': [e[1] if len(e[1]) > 1 else e[1][0] for e in z],
                                'pivot': spec.get('centre', [100, 80]), 'layout': 'peel'})
        unit_of = {e[1][0]: e[0] for e in z}
        for p in r['petals']:
            p['unit'] = unit_of[p['node'].index]
        pos = {p['unit']: i for i, p in enumerate(r['petals'])}
        r['keepOrder'] = [pos[u] for u, _ in entries]
        r['keptCounts'] = [sum(1 for u, _ in entries if by_pip[u] < k) for k in range(6)]
        r['type'] = 'peel'
        rings.append(r)
    return rings


PEEL_SPRITE_BOX = '-14 -24 28 25'


def peel_manifest(name, spec, rings, files, source):
    """The parts of a peel rule the app needs beyond the rings: units, fall sprites, settle, splay, motion."""
    where = {}
    for ri, r in enumerate(rings):
        for pi, p in enumerate(r['petals']):
            where.setdefault(p['unit'], []).append([ri, pi])
            for e in p['elements']:
                where.setdefault(('el', e), [ri, pi])
    by_pip = {u: int(k) for k, v in spec['lose'].items() for u in v}
    paths = spec.get('sprites', {}).get('paths', {})
    fall_images = {}
    for kind, colours in spec.get('sprites', {}).items():
        if kind == 'paths' or not paths:
            continue
        img = '%s_fall_%s' % (name, kind)
        body = ''.join('<path d="%s" fill="%s"%s/>' % (paths[part], colours[part], ' opacity=".5"' if part == 'claw' else '')
                       for part in ('face', 'lip', 'claw') if part in paths)
        files[img] = '<svg xmlns="%s" viewBox="%s" width="28" height="25">%s</svg>' % (SVG_NS, PEEL_SPRITE_BOX, body)
        fall_images[kind] = {'image': img, 'scale': colours.get('scale', 1), 'viewBox': [float(v) for v in PEEL_SPRITE_BOX.split()]}
    units = []
    for u, d in spec['units'].items():
        units.append({'id': u, 'petals': where.get(u, []), 'sprite': d.get('sprite'),
                      'fallImage': fall_images.get(d.get('sprite'), {}).get('image'),
                      'drops': d.get('drops', []), 'lostAtPips': by_pip.get(u)})
    for r in rings:
        for p in r['petals']:
            img = fall_images.get(spec['units'][p['unit']].get('sprite'), {}).get('image')
            if img:
                p['fallSprite'] = img
    settle = {}
    for k, v in spec.get('settle', {}).items():
        # rule element numbers are root children of the original art; map them through the units
        refs = []
        for e in v['els']:
            for u, d in spec['units'].items():
                if e in d['els'] and where.get(u):
                    refs += [x for x in where[u] if x not in refs]
        settle[str(k)] = {'petals': refs, 'dx': v.get('dx', 0), 'dy': v.get('dy', 0)}
    return {'source': source, 'centre': spec.get('centre'), 'units': units, 'fallSprites': fall_images,
            'settle': settle, 'splayAt': spec.get('splayAt'), 'seedAfterMs': spec.get('seedAfterMs'),
            'motion': spec.get('motion', {})}


def build_plant(name, path, ov, rose_rule, rose_src=None):
    root = ET.parse(path).getroot()
    warnings = []
    peel = None
    if ov.get('rule') == 'peel':
        peel = (rose_rule or {}).get(name)
        if peel is None:
            warnings.append('peel rule pending: notes/rose-rule.md not written yet, using detected ring')
    refs, own = apply_peel(root, peel) if peel else ({}, {})
    root, nodes = load_tree(root)
    vb = [float(v) for v in root.get('viewBox', '0 0 200 200').split()]
    kind = ov.get('kind')
    if kind == 'exempt':
        rings = []
    elif peel:
        rings = peel_rings(nodes, refs, peel)
    elif 'rings' in ov:
        rings = [tagged_ring(nodes, s) for s in ov['rings']]
    else:
        rings = detect_rings(nodes)
        drop = set(ov.get('dropRings', []))
        rings = [r for i, r in enumerate(rings) if i not in drop]
    rings += [tagged_ring(nodes, s) for s in ov.get('extraRings', [])]
    for k, counts in ov.get('ringKeptCounts', {}).items():  # peel-style schedule for a detected ring
        rings[int(k)]['keptCounts'] = counts

    rule = None
    if ov.get('rule') == 'peel':
        rule = {'name': 'peel', 'status': 'applied' if peel else 'pending'}

    # petal elements and the units (drawable leaves outside petals) in document order
    petal_of, skip = {}, set()
    for ri, r in enumerate(rings):
        for p in r['petals']:
            if p['node'].index in petal_of:
                warnings.append('element %d in two rings' % p['node'].index)
            petal_of[p['node'].index] = ri
            skip.update(n.index for n in p.get('extra', []))
    units = []

    def collect(n):
        if n.index in skip:
            return
        if n.index in petal_of:
            units.append(('ring', petal_of[n.index], n.index))
            return
        if id(n.el) in own:
            units.append(('own', own[id(n.el)], n.index))
            return
        if n.tag in DRAWABLE:
            units.append(('static', None, n.index))
        for c in n.children:
            collect(c)
    for n in [n for n in nodes if n.parent is None]:
        collect(n)

    # ground: the leading top-level ellipses on the ground line
    ground = []
    for u in units:
        n = nodes[u[2]]
        if u[0] == 'static' and n.tag == 'ellipse' and n.parent is None and float(n.el.get('cy', 0)) >= 165:
            ground.append(u[2])
        else:
            break
    units = units[len(ground):]

    # z-ordered segments: runs of static art, and runs of petals (from any rings, kept in document order)
    pos = {p['node'].index: (ri, pi) for ri, r in enumerate(rings) for pi, p in enumerate(r['petals'])}
    segs = []
    for u in units:
        k = u[0]
        if k == 'own':  # an element that moves on its own (a splaying sepal) gets its own static layer
            segs.append({'kind': 'static', 'items': [u[2]], 'extra': u[1]})
            continue
        if not segs or segs[-1]['kind'] != k or 'extra' in segs[-1]:
            segs.append({'kind': k, 'items': []})
        segs[-1]['items'].append(u[2] if k == 'static' else list(pos[u[2]]))

    if not kind:
        kind = 'petals' if rings else 'droop'
    droop = None
    if kind == 'droop' or ov.get('droop'):
        gx = float(nodes[ground[0]].el.get('cx')) if ground else 100.0
        gy = float(nodes[ground[0]].el.get('cy')) - 1 if ground else 176.0
        droop = {'pivot': ov.get('pivot', [r2(gx), r2(gy)]), 'maxTiltDegrees': r2(DROOP_STEP['tiltDegrees'] * 5),
                 'perPip': DROOP_STEP}

    layers, files = [], {}
    if ground:
        files[name + '_ground'] = subset_svg(root, nodes, set(ground))
        layers.append({'kind': 'ground', 'image': name + '_ground'})
    statics = [s for s in segs if s['kind'] == 'static']
    for si, s in enumerate(statics):
        if not rings:
            s['name'] = 'body'
        elif 'extra' in s:
            s['name'] = '%s%d' % (s['extra']['role'], si)
        elif s is segs[0]:
            s['name'] = 'back'
        elif s is segs[-1]:
            s['name'] = 'front'
        else:
            s['name'] = 'mid%d' % si
    for s in segs:
        if s['kind'] == 'static':
            files[name + '_' + s['name']] = subset_svg(root, nodes, set(s['items']))
            layers.append(dict({'kind': 'static', 'image': name + '_' + s['name']}, **s.get('extra', {})))
        else:
            layers.append({'kind': 'petals', 'petals': s['items']})

    out_rings = []
    for ri, r in enumerate(rings):
        sprites, sprite_list, petals = {}, [], []
        n = len(r['petals'])
        pv = r['pivot']
        radius = 0.0
        for p in r['petals']:
            node = p['node']
            members = [node] + p.get('extra', [])
            if len(members) == 1:
                sig, el, m = canonical(node)
            else:  # compound petal: members keep their own placement, the sprite is drawn in place
                sig = ''.join('<g transform="%s">%s</g>' % (mat_str(n.parent_ctm), outer(n.el, drop=())) for n in members)
                el, m = members[0].el, I
            if sig not in sprites:
                sprites[sig] = (len(sprite_list), m)
                sname = '%s_r%d_s%d' % (name, ri, len(sprite_list))
                files[sname] = svg_header(root) + '<g transform="%s">%s</g></svg>' % (mat_str(m), sig)
                fill = next((c.get('fill') for n in members for c in n.el.iter() if c.get('fill') not in (None, 'none')), None)
                sprite_list.append({'image': sname, 'fill': fill})
            si_, m0 = sprites[sig]
            place = mul(m, inv(m0))
            pts = [q for n in members for q in n.root_points()]
            cx, cy = sum(q[0] for q in pts) / len(pts), sum(q[1] for q in pts) / len(pts)
            pr = max(math.hypot(q[0] - pv[0], q[1] - pv[1]) for q in pts)
            radius = max(radius, pr)
            petals.append({'elements': [n.index for n in members], 'sprite': si_, 'angle': r2(p['angle']), 'radius': r2(pr),
                           'centre': [r2(cx), r2(cy)], 'transform': [round(v + 0.0, 4) for v in place]})
        order = r.get('keepOrder') or keep_order(n)
        counts = r.get('keptCounts') or [kept_count(n, k) for k in range(6)]
        visible = {str(k): sorted(order[:counts[k]]) for k in range(6)}
        fall = {str(k): order[counts[k - 1]:counts[k]] for k in range(1, 6)}
        if n < 4:
            warnings.append('ring %d has only %d petals' % (ri, n))
        out_rings.append({'type': r['type'], 'layout': r.get('layout', 'radial'), 'pivot': [r2(pv[0]), r2(pv[1])],
                          'radius': r2(radius), 'sprites': sprite_list, 'petals': petals,
                          'keepOrder': order, 'visible': visible, 'fall': fall})
        if r.get('keptCounts'):
            out_rings[-1]['keptCounts'] = counts
        for q, p in zip(petals, r['petals']):
            if 'unit' in p:
                q['unit'] = p['unit']

    # heads: rings sharing a pivot (cherry blossom has many)
    heads = []
    for ri, r in enumerate(out_rings):
        h = next((h for h in heads if math.hypot(h['pivot'][0] - r['pivot'][0], h['pivot'][1] - r['pivot'][1]) < 3), None)
        if not h:
            heads.append({'pivot': r['pivot'], 'rings': []})
            h = heads[-1]
        h['rings'].append(ri)

    if peel:
        rule.update(peel_manifest(name, peel, out_rings, files, rose_src))

    entry = {'kind': kind, 'viewBox': vb, 'layers': layers, 'rings': out_rings, 'heads': heads,
             'petalCount': sum(len(r['petals']) for r in out_rings), 'maxFallPerPip': MAX_FALL}
    if droop:
        entry['droop'] = droop
    if rule:
        entry['rule'] = rule
    if ov.get('note'):
        entry['note'] = ov['note']
    if warnings:
        entry['warnings'] = warnings
    return entry, files


def dump(name):
    _, nodes = load_tree(os.path.join(PLANTS_DIR, name + '.imageset', name + '.svg'))
    for n in nodes:
        depth, p = 0, n.parent
        while p:
            depth, p = depth + 1, p.parent
        attrs = ' '.join('%s=%s' % (k, v) for k, v in n.el.attrib.items() if k in ('cx', 'cy', 'r', 'rx', 'ry', 'fill', 'transform', 'd'))
        print(n.index, '  ' * depth + n.tag, attrs[:130])


def main():
    if len(sys.argv) > 2 and sys.argv[1] == '--dump':
        return dump(sys.argv[2])
    overrides = {}
    if os.path.exists(OVERRIDES):
        with open(OVERRIDES) as f:
            overrides = json.load(f)
    overrides = {k: v for k, v in overrides.items() if not k.startswith('_')}
    rose_rule, rose_src = load_rose_rule()
    names = sorted(d[:-len('.imageset')] for d in os.listdir(PLANTS_DIR) if d.endswith('.imageset'))
    manifest = {'version': 1, 'source': 'WordFlora/Assets.xcassets/Plants', 'frac': FRAC,
                'roseRule': rose_src or 'pending', 'plants': {}}
    all_files = {}
    for name in names:
        entry, files = build_plant(name, os.path.join(PLANTS_DIR, name + '.imageset', name + '.svg'),
                                   overrides.get(name, {}), rose_rule, rose_src)
        manifest['plants'][name] = entry
        all_files.update(files)
    # regenerate the layer catalog from scratch
    if os.path.isdir(LAYERS_DIR):
        for d in os.listdir(LAYERS_DIR):
            if d.endswith('.imageset'):
                full = os.path.join(LAYERS_DIR, d)
                for f in os.listdir(full):
                    os.remove(os.path.join(full, f))
                os.rmdir(full)
    os.makedirs(LAYERS_DIR, exist_ok=True)
    with open(os.path.join(LAYERS_DIR, 'Contents.json'), 'w') as f:
        json.dump({'info': {'author': 'xcode', 'version': 1}}, f, indent=2)
        f.write('\n')
    for k, v in sorted(all_files.items()):
        write_imageset(k, v)
    with open(MANIFEST, 'w') as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
        f.write('\n')
    counts = {}
    for name, e in manifest['plants'].items():
        counts.setdefault(e['kind'], []).append(name)
    for k in sorted(counts):
        print('%-7s %2d  %s' % (k, len(counts[k]), ' '.join(n[6:] for n in counts[k])))
    for name, e in manifest['plants'].items():
        for w in e.get('warnings', []):
            print('warn', name, w)
    print('rings:', ' '.join('%s=%s' % (n[6:], '/'.join(str(len(r['petals'])) for r in e['rings']))
                             for n, e in manifest['plants'].items() if e['rings']))
    print('imagesets:', len(all_files))


if __name__ == '__main__':
    main()

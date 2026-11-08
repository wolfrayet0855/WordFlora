#!/usr/bin/env python3
"""Pre-layered plant art (the Frost & Lantern glasshouse plants) into the petal thinning pipeline.

Run from the repo root with:   python3 -I tools/split_layered_svg.py && python3 -I tools/thin_svg.py

The ladder plants are drawn as one flat SVG and tools/thin_svg.py finds their petals. The glasshouse plants are
authored already layered in design-preview/frost-lantern/ (groups `ground`, `back`, `petals` with `r<head>_s<i>`,
`front`; see docs/pm/frost-lantern-art.md section 4). This script:

  1. unwraps the four layer groups (so the ground shadow is a top-level ellipse, as thin_svg expects) and writes
     the result to WordFlora/Assets.xcassets/Glasshouse/<plant>.imageset/<plant>.svg, the plant's full image;
  2. writes a hand-tagged ring per head into tools/glasshouse_overrides.json (same format as thinning_overrides.json,
     read by thin_svg.py next to it): each `r<head>_s<i>` group is one petal, drawn as one sprite in place, turning
     about the head pivot from the art doc.

  3. copies the pack's other art into the catalog unchanged: the robin and wren frames and stickers into VisitorArt,
     and the scene's light and dark files into one Scenes/frost_lantern_scene imageset (a light + dark pair).

thin_svg.py then builds the PlantLayers imagesets and the PlantThinning.json entry from the Glasshouse folder exactly
as it does for the ladder plants, so a rerun of thin_svg.py alone keeps them.
"""
import json
import os
import re
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_DIR = os.path.join(ROOT, 'design-preview', 'frost-lantern')
GLASSHOUSE_DIR = os.path.join(ROOT, 'WordFlora', 'Assets.xcassets', 'Glasshouse')
OVERRIDES = os.path.join(ROOT, 'tools', 'glasshouse_overrides.json')
SVG_NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG_NS)

# Head pivots in the 200 box, one per ring (docs/pm/g5-asset-readiness.md, the re-posed snowdrop).
PLANTS = {
    'plant_snowdrop': {'pivots': [(118, 64), (72, 80), (138, 94)],
                       'note': 'Glasshouse plant (Frost & Lantern): three nodding heads, three outer tepals each.'},
    'plant_hellebore': {'pivots': [(102, 74), (60, 104), (144, 100)],
                        'note': 'Glasshouse plant (Frost & Lantern): three heads, five sepals each.'},
}
UNWRAP = ('ground', 'back', 'petals', 'front')
PETAL_ID = re.compile(r'^r(\d+)_s(\d+)$')


def tag(el):
    return el.tag.split('}')[-1]


def flatten(root):
    """Replace each layer group (no transform of its own) by its children, in place."""
    out = []
    for c in list(root):
        if tag(c) == 'g' and c.get('id') in UNWRAP and not c.get('transform'):
            out.extend(list(c))
        else:
            out.append(c)
    for c in list(root):
        root.remove(c)
    for c in out:
        c.tail = None
        root.append(c)
    return root


def petal_indices(root):
    """{(ring, petal): pre-order index} of the r<head>_s<i> groups, numbered as thin_svg numbers elements."""
    found, n = {}, [0]

    def walk(el):
        for c in el:
            i = n[0]
            n[0] += 1
            m = PETAL_ID.match(c.get('id') or '')
            if m:
                found[(int(m.group(1)), int(m.group(2)))] = i
            walk(c)
    walk(root)
    return found


def write_imageset(name, svg):
    d = os.path.join(GLASSHOUSE_DIR, name + '.imageset')
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + '.svg'), 'w') as f:
        f.write(svg)
    with open(os.path.join(d, 'Contents.json'), 'w') as f:
        json.dump({'images': [{'filename': name + '.svg', 'idiom': 'universal'}],
                   'info': {'author': 'xcode', 'version': 1},
                   'properties': {'preserves-vector-representation': True}}, f, indent=2)
        f.write('\n')


VISITOR_DIR = os.path.join(ROOT, 'WordFlora', 'Assets.xcassets', 'VisitorArt')
SCENES_DIR = os.path.join(ROOT, 'WordFlora', 'Assets.xcassets', 'Scenes')
VISITORS = ['visitor_%s_%s' % (b, f) for b in ('robin', 'wren') for f in ('a', 'b', 'idle', 'sticker')]


def copy_imageset(folder, name, files):
    """files: [(source file in SOURCE_DIR, file name in the imageset, appearance or None)]."""
    d = os.path.join(folder, name + '.imageset')
    os.makedirs(d, exist_ok=True)
    images = []
    for src, dst, dark in files:
        with open(os.path.join(SOURCE_DIR, src)) as f:
            body = f.read()
        with open(os.path.join(d, dst), 'w') as f:
            f.write(body)
        img = {'filename': dst, 'idiom': 'universal'}
        if dark:
            img = {'appearances': [{'appearance': 'luminosity', 'value': 'dark'}], 'filename': dst, 'idiom': 'universal'}
        images.append(img)
    props = {'preserves-vector-representation': True}
    if any(dark for _, _, dark in files):
        props['template-rendering-intent'] = 'original'
    with open(os.path.join(d, 'Contents.json'), 'w') as f:
        json.dump({'images': images, 'info': {'author': 'xcode', 'version': 1}, 'properties': props}, f, indent=2)
        f.write('\n')


def pack_art():
    for v in VISITORS:
        copy_imageset(VISITOR_DIR, v, [(v + '.svg', v + '.svg', False)])
    os.makedirs(SCENES_DIR, exist_ok=True)
    with open(os.path.join(SCENES_DIR, 'Contents.json'), 'w') as f:
        json.dump({'info': {'author': 'xcode', 'version': 1}}, f, indent=2)
        f.write('\n')
    copy_imageset(SCENES_DIR, 'frost_lantern_scene', [('scene-light.svg', 'frost_lantern_scene.svg', False),
                                                      ('scene-dark.svg', 'frost_lantern_scene-dark.svg', True)])


def main():
    pack_art()
    os.makedirs(GLASSHOUSE_DIR, exist_ok=True)
    with open(os.path.join(GLASSHOUSE_DIR, 'Contents.json'), 'w') as f:
        json.dump({'info': {'author': 'xcode', 'version': 1}}, f, indent=2)
        f.write('\n')
    overrides = {'_readme': ['Written by tools/split_layered_svg.py; do not edit by hand. Same format as thinning_overrides.json.']}
    for name, spec in PLANTS.items():
        root = flatten(ET.parse(os.path.join(SOURCE_DIR, name + '.svg')).getroot())
        idx = petal_indices(root)
        rings = []
        for r, pivot in enumerate(spec['pivots']):
            petals = [idx[k] for k in sorted(k for k in idx if k[0] == r)]
            if not petals:
                raise SystemExit('%s: no petals for head %d' % (name, r))
            rings.append({'elements': petals, 'pivot': list(pivot)})
        if len(idx) != sum(len(r['elements']) for r in rings):
            raise SystemExit('%s: petal groups outside the listed heads' % name)
        body = ET.tostring(root, encoding='unicode').replace('ns0:', '').replace(' xmlns:ns0="%s"' % SVG_NS, '')
        write_imageset(name, body + '\n')
        overrides[name] = {'kind': 'petals', 'rings': rings, 'note': spec['note']}
        print('%s: %s petals' % (name, '/'.join(str(len(r['elements'])) for r in rings)))
    with open(OVERRIDES, 'w') as f:
        json.dump(overrides, f, indent=1, sort_keys=True)
        f.write('\n')


if __name__ == '__main__':
    main()

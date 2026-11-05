"""Greyscale and colour-vision-deficiency simulation for review (Pillow only).

    python cvd_sim.py OUT_DIR IMG [IMG ...]

For each input writes OUT_DIR/<name>-grey.png, -deut.png, -prot.png, -trit.png and a labelled
contact sheet OUT_DIR/<name>-sims.png (original, grey, deut, prot, trit in a row, scaled up 1x..4x
so 29 px marks are visible). Machado, Oliveira and Fernandes (2009) matrices at severity 1.0,
applied in linear RGB.

Also: python cvd_sim.py --hex '#RRGGBB' '#RRGGBB' prints WCAG contrast between the two colours
as seen under normal vision, deut, prot, trit.
"""
import os, sys
from PIL import Image, ImageDraw

MATS = {
    'deut': ((0.367322, 0.860646, -0.227968), (0.280085, 0.672501, 0.047413), (-0.011820, 0.042940, 0.968881)),
    'prot': ((0.152286, 1.052583, -0.204868), (0.114503, 0.786281, 0.099216), (-0.003882, -0.048116, 1.051998)),
    'trit': ((1.255528, -0.076749, -0.178779), (-0.078411, 0.930809, 0.147602), (0.004733, 0.691367, 0.303900)),
}

def to_lin(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def from_lin(v):
    v = max(0.0, min(1.0, v))
    s = v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
    return int(round(s * 255))

LIN = [to_lin(i) for i in range(256)]

def sim_rgb(rgb, mat):
    r, g, b = (LIN[c] for c in rgb)
    return tuple(from_lin(m[0] * r + m[1] * g + m[2] * b) for m in mat)

def sim_image(im, mat):
    im = im.convert('RGB')
    cache = {}
    px = im.load()
    w, h = im.size
    out = Image.new('RGB', (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p not in cache:
                cache[p] = sim_rgb(p, mat)
            op[x, y] = cache[p]
    return out

def lum(rgb):
    r, g, b = (LIN[c] for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    la, lb = lum(a), lum(b)
    if la < lb:
        la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)

def hexrgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def sheet(name, ims, out):
    labels = ['original', 'grey', 'deut', 'prot', 'trit']
    w, h = ims[0].size
    scale = 4 if h <= 40 else (2 if h <= 120 else 1)
    cw, ch = w * scale, h * scale
    pad = 12
    sh = Image.new('RGB', (len(ims) * (cw + pad) + pad, ch + 40), (255, 255, 255))
    d = ImageDraw.Draw(sh)
    for i, (lab, im) in enumerate(zip(labels, ims)):
        x = pad + i * (cw + pad)
        sh.paste(im.convert('RGB').resize((cw, ch), Image.NEAREST), (x, 30))
        d.text((x, 8), '%s %s' % (name, lab), fill=(0, 0, 0))
    sh.save(out)

if __name__ == '__main__':
    if sys.argv[1] == '--hex':
        a, b = hexrgb(sys.argv[2]), hexrgb(sys.argv[3])
        print('normal %.2f' % contrast(a, b))
        for k, m in MATS.items():
            print('%s %.2f' % (k, contrast(sim_rgb(a, m), sim_rgb(b, m))))
        sys.exit()
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    for path in sys.argv[2:]:
        im = Image.open(path)
        if im.mode in ('RGBA', 'LA', 'P'):
            bg = Image.new('RGB', im.size, (255, 255, 255))
            bg.paste(im.convert('RGBA'), mask=im.convert('RGBA').split()[3])
            im = bg
        im = im.convert('RGB')
        name = os.path.splitext(os.path.basename(path))[0]
        grey = im.convert('L').convert('RGB')
        sims = [im, grey]
        grey.save(os.path.join(out_dir, name + '-grey.png'))
        for k, m in MATS.items():
            s = sim_image(im, m)
            s.save(os.path.join(out_dir, '%s-%s.png' % (name, k)))
            sims.append(s)
        sheet(name, sims, os.path.join(out_dir, name + '-sims.png'))
        print('wrote', name)

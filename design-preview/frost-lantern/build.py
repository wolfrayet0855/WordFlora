#!/usr/bin/env python3
"""Frost & Lantern art generator (design-preview/frost-lantern).

Writes every SVG in this folder from one palette, so the pot patterns here are exactly the `PotMark` lists a builder
copies into `PotCatalog.marks(for:)`. Run: python3 -I design-preview/frost-lantern/build.py
Spec and manifest: docs/pm/frost-lantern-art.md. Flat fills only: no gradients, no filters, no drop shadows in the art.
"""
import math
import os

OUT = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- palette (token name -> hex)
# Existing app colours (reused, not new).
T = {
    "appBackground.light": "#FAF7F0", "appBackground.dark": "#1A2E1A",
    "appSurface.light": "#FFFFFF", "appSurface.dark": "#2C3E2C",
    "appPrimaryText.light": "#2C3E2C", "appPrimaryText.dark": "#D4EDD4",
    "PotPainter.soil": "#85583A", "PotPainter.soilShade": "#6B4528",
    "PotPainter.toEarnFill.light": "#E4DFD2", "PotPainter.toEarnFill.dark": "#3A4C3A",
    "PotPainter.toEarnInk.light": "#746F5E", "PotPainter.toEarnInk.dark": "#8FA48F",
    "PetalKit.marigold": "#F5C858", "PetalKit.stem": "#4E9A55", "PetalKit.leaf": "#5FA860",
    "PetalKit.leafDark": "#3F8A4A", "PetalKit.potBrown": "#C98A4B", "PetalKit.potBrownDark": "#9A5F2A",
    "Badge.disc": "#FFFDF5",
    "Badge.bronze": "#9A5F2A", "Badge.bronzeLight": "#C98A4B",
    "Badge.silver": "#8D9AA6", "Badge.silverLight": "#C5CED6",
    "Badge.gold": "#D49A1E", "Badge.goldLight": "#F5C84C",
    "Visitor.eye": "#2C2418", "Plant.groundShadow": "#2C3E2C",
    "Pot.honeyCream": "#FFF0C2", "white": "#FFFFFF",
    # New art colours for the pack (art constants, not colorsets).
    "FL.iceBody": "#B7D6E6", "FL.iceRim": "#5E93B0", "FL.iceShade": "#93BCD2", "FL.frostFern": "#3F7596",
    "FL.lanternBody": "#B5403A", "FL.lanternRim": "#D9665A", "FL.lanternShade": "#93302B",
    "FL.lanternBand": "#8A2A25", "FL.lanternInk": "#5E211C",
    "FL.indigoBody": "#4A4FAE", "FL.indigoRim": "#7F86D9", "FL.indigoShade": "#363A8C", "FL.ice": "#CFE6F0",
    "FL.lanternRed": "#C8473E",
    "FL.snow": "#F4F7FB", "FL.snowShade": "#DCE5EF", "FL.snowDark": "#9AA7BC", "FL.snowShadeDark": "#7D8BA3",
    "FL.skyL1": "#D3DEEE", "FL.skyL2": "#DFE5F1", "FL.skyL3": "#EAE6F0",
    "FL.skyD1": "#17233A", "FL.skyD2": "#1E2C46", "FL.skyD3": "#283752",
    "FL.hillL": "#C4D3E4", "FL.hillD": "#33425E", "FL.moon": "#F6E8B0",
    "FL.post": "#5E4A3A", "FL.postDark": "#3E3128", "FL.fir": "#3F6F4A", "FL.firDark": "#2E5538",
    "FL.glow": "#F5C858", "FL.stringDark": "#8C7A6B",
    "FL.robinBack": "#7A6A4E", "FL.robinWing": "#5E4E36", "FL.robinWingEdge": "#9A8A68",
    "FL.robinBreast": "#E2733A", "FL.robinGrey": "#A9B0B8", "FL.robinBelly": "#F3EEE6", "FL.beak": "#3A2C1E",
    "FL.leg": "#7A5A44",
    "FL.wrenBody": "#8A5A34", "FL.wrenWing": "#6E4524", "FL.wrenBar": "#4E2F17", "FL.wrenBelly": "#D8B98E",
    "FL.wrenBrow": "#EBD7B4",
    "FL.stickerFrost": "#DCEBF2", "FL.stickerBark": "#F1E6D6",
    "FL.snowdropLeaf": "#6E9C7E", "FL.snowdropLeafVein": "#A9C9B4", "FL.snowdropEdge": "#768C91",
    "FL.helleboreSepal": "#C46B8C", "FL.helleboreEdge": "#9A4A6B", "FL.helleboreCentre": "#C9D86A",
    "FL.helleboreStamen": "#F2E7A0", "FL.helleboreLeaf": "#3F6F4A", "FL.helleboreVein": "#6E9C7E",
    "FL.helleboreStem": "#5E8A4E",
    "FL.woodLight": "#D9A066", "FL.woodEdge": "#9A5F2A",
}


def c(name):
    return T[name]


def f(x):
    s = ("%.2f" % x).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


_uid = [0]


def uid(prefix):
    _uid[0] += 1
    return "%s%d" % (prefix, _uid[0])


def svg_doc(w, h, body, comment=""):
    head = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s" width="%s" height="%s">' % (f(w), f(h), f(w), f(h))
    if comment:
        head += "\n  <!-- %s -->" % comment.replace("--", "-")
    return head + "\n" + body + "\n</svg>\n"


def nest(x, y, w, h, vbw, vbh, inner):
    return '<svg x="%s" y="%s" width="%s" height="%s" viewBox="0 0 %s %s">%s</svg>' % (
        f(x), f(y), f(w), f(h), f(vbw), f(vbh), inner)


def write(name, text):
    with open(os.path.join(OUT, name), "w") as fh:
        fh.write(text)


# ---------------------------------------------------------------- pots (PotPainter in SVG)
BODY = "M18 20 L102 20 L92 88 Q91 96 82 96 L38 96 Q29 96 28 88 Z"
LIGHT = "M18 20 L34 20 L42 96 L38 96 Q29 96 28 88 Z"
SHADE = "M102 20 L88 20 L82 96 Q91 96 92 88 Z"
SPARKLE = "M0 -7 Q1 -1.5 7 0 Q1 1.5 0 7 Q-1 1.5 -7 0 Q-1 -1.5 0 -7 Z"


def mark(shape, color=0, opacity=1.0, ghost="ink"):
    return {"shape": shape, "color": color, "opacity": opacity, "ghost": ghost}


def shape_svg(s, fill):
    k = s[0]
    if k == "rect":
        _, x, y, w, h = s
        return '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % (f(x), f(y), f(w), f(h), fill)
    if k == "capsule":
        _, x, y, w, h = s
        return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"/>' % (f(x), f(y), f(w), f(h), f(w / 2), fill)
    if k == "circle":
        _, cx, cy, r = s
        return '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(cx), f(cy), f(r), fill)
    if k == "petal":
        _, cx, cy, d, rx, ry, deg = s
        return '<ellipse cx="0" cy="%s" rx="%s" ry="%s" transform="translate(%s %s) rotate(%s)" fill="%s"/>' % (
            f(-d), f(rx), f(ry), f(cx), f(cy), f(deg), fill)
    if k == "sparkle":
        _, cx, cy, sc = s
        return '<path d="%s" transform="translate(%s %s) scale(%s)" fill="%s"/>' % (SPARKLE, f(cx), f(cy), f(sc), fill)
    raise ValueError(k)


def shape_swift(s):
    k = s[0]
    if k == "rect":
        return ".rect(x: %s, y: %s, width: %s, height: %s)" % tuple(f(v) for v in s[1:])
    if k == "capsule":
        return ".capsule(x: %s, y: %s, width: %s, height: %s)" % tuple(f(v) for v in s[1:])
    if k == "circle":
        return ".circle(cx: %s, cy: %s, r: %s)" % tuple(f(v) for v in s[1:])
    if k == "petal":
        return ".petal(cx: %s, cy: %s, distance: %s, rx: %s, ry: %s, degrees: %s)" % tuple(f(v) for v in s[1:])
    if k == "sparkle":
        return ".sparkle(cx: %s, cy: %s, scale: %s)" % tuple(f(v) for v in s[1:])
    raise ValueError(k)


def marks_frost():
    """Frosted Glass: a frost band with a scalloped edge along the foot, three frost ferns rising from it, two glints."""
    out = [mark(("rect", 18, 80, 84, 20), 0, 0.85)]
    out += [mark(("circle", x, 80, 4.5), 0, 0.85) for x in range(22, 99, 8)]
    for x, top in [(38, 56), (60, 46), (82, 58)]:
        out.append(mark(("capsule", x - 1.2, top, 2.4, 82 - top), 1))
        for y in range(top + 6, 80, 8):
            out.append(mark(("petal", x, y, 5, 1.9, 5, -52), 1))
            out.append(mark(("petal", x, y, 5, 1.9, 5, 52), 1))
    out += [mark(("sparkle", 32, 34, 0.6), 0, 1, "hidden"), mark(("sparkle", 90, 38, 0.45), 0, 1, "hidden")]
    return out


def marks_lanterns():
    """Lantern Red: a deep band with a string of three paper lanterns (gold, cream, gold), each with a glow."""
    out = [mark(("rect", 18, 40, 84, 30), 3, 1, "hidden"), mark(("rect", 18, 31, 84, 2.4), 1)]
    for i, x in enumerate([34, 60, 86]):
        body, glow = (0, 1) if i != 1 else (1, 0)
        out += [
            mark(("capsule", x - 1.2, 32, 2.4, 9), 2),
            mark(("petal", x, 55, 0, 10, 12, 0), body),
            mark(("capsule", x - 5.6, 46, 1.8, 18), 2, 0.35, "hidden"),
            mark(("capsule", x + 3.8, 46, 1.8, 18), 2, 0.35, "hidden"),
            mark(("circle", x, 55, 3.4), glow, 1, "fill"),
            mark(("rect", x - 6, 41, 12, 4), 2),
            mark(("rect", x - 5, 66, 10, 3.5), 2),
            mark(("capsule", x - 1.3, 69.5, 2.6, 9), 0),
        ]
    return out


def marks_snowflakes():
    """Snowflake Indigo: three six-armed snowflakes with side twigs, and a scatter of ice dots."""
    out = []
    for cx, cy, s in [(40, 46, 1.0), (79, 60, 1.1), (50, 80, 0.8)]:
        for k in range(6):
            out.append(mark(("petal", cx, cy, 6 * s, 1.5 * s, 6 * s, k * 60), 0))
        out.append(mark(("circle", cx, cy, 2.4 * s), 0))
        for k in range(6):
            a = math.radians(k * 60)
            px, py = round(cx + 8 * s * math.sin(a), 2), round(cy - 8 * s * math.cos(a), 2)
            out.append(mark(("petal", px, py, 2.4 * s, 0.9 * s, 2.6 * s, k * 60 - 50), 0, 1, "hidden"))
            out.append(mark(("petal", px, py, 2.4 * s, 0.9 * s, 2.6 * s, k * 60 + 50), 0, 1, "hidden"))
    out += [mark(("circle", x, y, 1.7), 1, 0.85, "hidden") for x, y in [(28, 66), (64, 34), (94, 40), (72, 88), (90, 82), (30, 34)]]
    return out


POTS = [
    {"id": "frostedGlass", "name": "Frosted glass", "body": "FL.iceBody", "rim": "FL.iceRim", "shade": "FL.iceShade",
     "colors": ["white", "FL.frostFern"], "kind": "frost", "marks": marks_frost,
     "a11y": "Icy blue pot with frost ferns", "unlock": "earned (Daily Bloom on 5 days in season)"},
    {"id": "lanternRed", "name": "Lantern red", "body": "FL.lanternBody", "rim": "FL.lanternRim", "shade": "FL.lanternShade",
     "colors": ["PetalKit.marigold", "Pot.honeyCream", "FL.lanternInk", "FL.lanternBand"], "kind": "lanterns",
     "marks": marks_lanterns, "a11y": "Red pot with a band of paper lanterns", "unlock": "pack"},
    {"id": "snowflakeIndigo", "name": "Snowflake indigo", "body": "FL.indigoBody", "rim": "FL.indigoRim",
     "shade": "FL.indigoShade", "colors": ["white", "FL.ice"], "kind": "snowflakes", "marks": marks_snowflakes,
     "a11y": "Indigo pot with white snowflakes", "unlock": "pack"},
]


def pot_svg(pot, style="full", dark=False, soil=False):
    """One pot in the 120 x 100 box, the same drawing order as PotPainter.draw."""
    ghost = style == "toEarn"
    th = "dark" if dark else "light"
    ink = c("PotPainter.toEarnInk." + th)
    gfill = c("PotPainter.toEarnFill." + th)
    clip = uid("pb")
    o = ['<defs><clipPath id="%s"><path d="%s"/></clipPath></defs>' % (clip, BODY)]
    o.append('<path d="%s" fill="%s"/>' % (BODY, gfill if ghost else c(pot["body"])))
    o.append('<g clip-path="url(#%s)">' % clip)
    if not ghost:
        o.append('<path d="%s" fill="#FFFFFF" fill-opacity="0.14"/>' % LIGHT)
        o.append('<path d="%s" fill="%s" fill-opacity="0.45"/>' % (SHADE, c(pot["shade"])))
    o.append('<g opacity="0.55">' if ghost else "<g>")
    for m in pot["marks"]():
        if ghost and m["ghost"] == "hidden":
            continue
        col = (gfill if m["ghost"] == "fill" else ink) if ghost else c(pot["colors"][m["color"]])
        el = shape_svg(m["shape"], col)
        if m["opacity"] != 1:
            el = '<g opacity="%s">%s</g>' % (f(m["opacity"]), el)
        o.append(el)
    o.append("</g></g>")
    dash = 'stroke="%s" stroke-width="2" stroke-dasharray="5 4" stroke-linejoin="round"' % ink
    if ghost:
        o.append('<path d="%s" fill="none" %s/>' % (BODY, dash))
    o.append('<rect x="10" y="4" width="100" height="18" rx="9" fill="%s"%s/>' % (
        gfill if ghost else c(pot["rim"]), (" " + dash) if ghost else ""))
    if not ghost:
        o.append('<rect x="16" y="8" width="88" height="5" rx="2.5" fill="#FFFFFF" fill-opacity="0.35"/>')
    if soil:
        sc = uid("sl")
        o.append('<defs><clipPath id="%s"><ellipse cx="60" cy="13.5" rx="34" ry="8.5"/></clipPath></defs>' % sc)
        o.append('<ellipse cx="60" cy="13.5" rx="34" ry="8.5" fill="%s"/>' % c("PotPainter.soil"))
        o.append('<ellipse cx="60" cy="16.1" rx="34" ry="8.5" fill="%s" clip-path="url(#%s)"/>' % (c("PotPainter.soilShade"), sc))
    return "".join(o)


def pot_files():
    for pot in POTS:
        base = "pot-" + pot["id"]
        cols = ", ".join("%s %s" % (n, c(n)) for n in [pot["body"], pot["rim"], pot["shade"]] + pot["colors"])
        write(base + ".svg", svg_doc(120, 100, pot_svg(pot),
              "%s pot, full colour, empty (no soil). 120 x 100 pot box = PotPainter. Colours: %s. Same art on light and dark." % (pot["name"], cols)))
        write(base + "-soil.svg", svg_doc(120, 100, pot_svg(pot, soil=True),
              "%s pot with the soil top (occupied: the plant page stage and the repot preview). Soil PotPainter.soil." % pot["name"]))
        for th in ("light", "dark"):
            write("%s-outline-%s.svg" % (base, th), svg_doc(120, 100, pot_svg(pot, "toEarn", th == "dark"),
                  "%s pot as a soft outline (not owned yet), %s theme: PotPainter toEarn fill/ink, dashed 5 4, pattern at 55%%." % (pot["name"], th)))


# ---------------------------------------------------------------- small lantern (scene, card, badge)
def lantern(x, y, s, body="FL.lanternRed", glow=True, dark=False, halo=True):
    """A paper lantern hanging from (x, y); s = 1 is 24 units tall below the hook."""
    o = []
    if halo:
        for r, op in [(22, 0.10 if not dark else 0.16), (14, 0.16 if not dark else 0.24)]:
            o.append('<circle cx="%s" cy="%s" r="%s" fill="%s" fill-opacity="%s"/>' % (f(x), f(y + 14 * s), f(r * s), c("FL.glow"), f(op)))
    ink = c("FL.lanternInk")
    o.append('<path d="M%s %s V%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (f(x), f(y), f(y + 4 * s), ink, f(1.6 * s)))
    o.append('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"/>' % (f(x - 5 * s), f(y + 3.5 * s), f(10 * s), f(3.2 * s), f(1 * s), ink))
    o.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(x), f(y + 14 * s), f(9 * s), f(9.5 * s), c(body)))
    o.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-opacity="0.45" stroke-width="%s"/>' % (
        f(x), f(y + 14 * s), f(4.2 * s), f(9.3 * s), ink, f(1.1 * s)))
    if glow:
        o.append('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (f(x), f(y + 14.5 * s), f(3.2 * s), f(4.6 * s), c("FL.glow")))
    o.append('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"/>' % (f(x - 4 * s), f(y + 22.5 * s), f(8 * s), f(2.8 * s), f(1 * s), ink))
    o.append('<path d="M%s %s V%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (f(x), f(y + 25 * s), f(y + 30 * s), c("FL.glow"), f(2 * s)))
    return "".join(o)


def snowflake(x, y, r, col, w):
    o = []
    for k in range(3):
        a = math.radians(k * 60)
        dx, dy = r * math.sin(a), r * math.cos(a)
        o.append('<path d="M%s %s L%s %s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (f(x - dx), f(y - dy), f(x + dx), f(y + dy), col, f(w)))
    for k in range(6):
        a = math.radians(k * 60)
        px, py = x + 0.62 * r * math.sin(a), y - 0.62 * r * math.cos(a)
        for side in (-1, 1):
            b = a + side * math.radians(45)
            o.append('<path d="M%s %s L%s %s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (
                f(px), f(py), f(px + 0.3 * r * math.sin(b)), f(py - 0.3 * r * math.cos(b)), col, f(w * 0.8)))
    return "".join(o)


# ---------------------------------------------------------------- badge
TIERS = {1: ("Badge.bronze", "Badge.bronzeLight", [50]), 2: ("Badge.silver", "Badge.silverLight", [45, 55]),
         3: ("Badge.gold", "Badge.goldLight", [40, 50, 60])}
DODEC = "50.0,4.0 73.0,10.2 89.8,27.0 96.0,50.0 89.8,73.0 73.0,89.8 50.0,96.0 27.0,89.8 10.2,73.0 4.0,50.0 10.2,27.0 27.0,10.2"


def badge_svg(tier):
    dk, lt, dots = TIERS[tier]
    o = ['<polygon points="%s" fill="%s"/>' % (DODEC, c(dk)),
         '<polygon points="%s" fill="%s" transform="translate(50 50) scale(.92) translate(-50 -50)"/>' % (DODEC, c(lt)),
         '<circle cx="50" cy="48" r="33" fill="%s" stroke="%s" stroke-width="2"/>' % (c("Badge.disc"), c(dk))]
    ink = c("FL.lanternInk")
    o.append('<g>')
    o.append('<path d="M47 21 V27" stroke="%s" stroke-width="2.4" stroke-linecap="round"/>' % ink)
    o.append('<rect x="39" y="26" width="16" height="5" rx="1.6" fill="%s"/>' % ink)
    o.append('<ellipse cx="47" cy="46" rx="14" ry="15" fill="%s"/>' % c("FL.lanternRed"))
    o.append('<ellipse cx="47" cy="46" rx="6.5" ry="14.6" fill="none" stroke="%s" stroke-width="1.6" stroke-opacity=".5"/>' % ink)
    o.append('<ellipse cx="47" cy="47" rx="5" ry="7" fill="%s"/>' % c("PetalKit.marigold"))
    o.append('<path d="M43 44 Q44 40 47 39" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" fill="none" stroke-opacity=".9"/>')
    o.append('<rect x="41" y="60" width="12" height="4.5" rx="1.6" fill="%s"/>' % ink)
    o.append('<path d="M47 64.5 V72" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % c("PetalKit.marigold"))
    o.append(snowflake(68, 32, 7.5, c("FL.frostFern"), 2.2))
    o.append("</g>")
    for x in dots:
        o.append('<circle cx="%s" cy="91" r="3.6" fill="%s" stroke="#fff" stroke-width="1.4"/>' % (f(x), c(lt)))
    return "".join(o)


def badge_files():
    for t in (1, 2, 3):
        dk, lt, _ = TIERS[t]
        write("badge_lantern_keeper_t%d.svg" % t, svg_doc(100, 100, badge_svg(t),
              "Lantern Keeper tier %d. Frame as every BadgeArt badge: dodecagon %s/%s, disc Badge.disc, %d tier dot(s). Icon FL.lanternRed, FL.lanternInk, PetalKit.marigold, snowflake FL.frostFern. Same art on light and dark." % (t, dk, lt, t)))


# ---------------------------------------------------------------- Seasons row glyph (template)
def glyph_svg(col="#000000"):
    """An outline paper lantern alone: a wide open body (2 pt stroke), one thin inner rib oval, flat caps, hook and
    tassel. Drawn for 22 to 28 pt in one colour. No solid body and no snowflake: at 22 pt a flake reads as an asterisk."""
    o = ['<path d="M12 1.4 V4" stroke="%s" stroke-width="1.8" stroke-linecap="round"/>' % col,
         '<rect x="7.04" y="3.6" width="9.92" height="2.6" rx="1" fill="%s"/>' % col,
         '<ellipse cx="12" cy="12" rx="8" ry="6" fill="none" stroke="%s" stroke-width="2"/>' % col,
         '<ellipse cx="12" cy="12" rx="3.36" ry="5.6" fill="none" stroke="%s" stroke-width="1.2"/>' % col,
         '<rect x="8" y="17.4" width="8" height="2.4" rx="1" fill="%s"/>' % col,
         '<path d="M12 19.8 V23" stroke="%s" stroke-width="1.8" stroke-linecap="round"/>' % col]
    return "".join(o)


# ---------------------------------------------------------------- visitors
def robin_parts(wing_rot):
    o = []
    o.append('<path d="M66 60 L87 55 L89 63 L68 68 Z" fill="%s"/>' % c("FL.robinWing"))
    o.append('<ellipse cx="55" cy="58" rx="20" ry="16.5" fill="%s"/>' % c("FL.robinBack"))
    o.append('<ellipse cx="51" cy="66" rx="14" ry="9.5" fill="%s"/>' % c("FL.robinBelly"))
    o.append('<circle cx="39" cy="43" r="12" fill="%s"/>' % c("FL.robinBack"))
    # orange face and breast, edged with the robin's grey band
    o.append('<path d="M31 36 C27 44 30 58 42 66 C50 70 56 64 54 56 C52 48 47 41 41 37 C37 34 33 34 31 36 Z" fill="%s" stroke="%s" stroke-width="1.6"/>' % (c("FL.robinBreast"), c("FL.robinGrey")))
    o.append('<circle cx="34.5" cy="41" r="2.3" fill="%s"/><circle cx="35.3" cy="40.2" r=".75" fill="#FFFFFF"/>' % c("Visitor.eye"))
    o.append('<path d="M28 43 L20 44.8 L28 47 Z" fill="%s"/>' % c("FL.beak"))
    o.append('<g transform="rotate(%s 56 52)"><ellipse cx="62" cy="54" rx="15" ry="8" fill="%s"/>'
             '<path d="M52 55 Q62 59 75 56 M54 51 Q63 54 74 52" stroke="%s" stroke-width="1.4" fill="none" stroke-linecap="round"/></g>' % (
                 f(wing_rot), c("FL.robinWing"), c("FL.robinWingEdge")))
    return "".join(o)


def legs(x1, x2, top, col):
    return ('<path d="M%s %s L%s %s M%s %s L%s %s M%s %s L%s %s M%s %s L%s %s" stroke="%s" stroke-width="1.8" stroke-linecap="round" fill="none"/>' % (
        f(x1), f(top), f(x1 - 1.5), f(top + 8), f(x2), f(top), f(x2 + 0.5), f(top + 8),
        f(x1 - 4.5), f(top + 8), f(x1 + 2), f(top + 8), f(x2 - 3), f(top + 8), f(x2 + 3.5), f(top + 8), col))


def wren_parts(wing_rot):
    o = []
    o.append('<path d="M63 52 L79 28 L86 32 L71 56 Z" fill="%s"/>' % c("FL.wrenWing"))
    o.append('<path d="M70 41 L77 45 M74 35 L80 39" stroke="%s" stroke-width="1.6" stroke-linecap="round"/>' % c("FL.wrenBar"))
    o.append('<ellipse cx="53" cy="59" rx="19" ry="15" fill="%s"/>' % c("FL.wrenBody"))
    o.append('<ellipse cx="47" cy="65" rx="12.5" ry="8" fill="%s"/>' % c("FL.wrenBelly"))
    o.append('<circle cx="37" cy="51" r="11" fill="%s"/>' % c("FL.wrenBody"))
    o.append('<path d="M29 47.5 Q36 43.5 45 46" stroke="%s" stroke-width="2.2" stroke-linecap="round" fill="none"/>' % c("FL.wrenBrow"))
    o.append('<circle cx="33.5" cy="50.5" r="2.1" fill="%s"/><circle cx="34.2" cy="49.8" r=".7" fill="#FFFFFF"/>' % c("Visitor.eye"))
    o.append('<path d="M27 51 L16 51.8 L27 54 Z" fill="%s"/>' % c("FL.beak"))
    o.append('<g transform="rotate(%s 54 54)"><ellipse cx="59" cy="57" rx="13" ry="7" fill="%s"/>'
             '<path d="M53 53 L53 61 M58 52 L58 62 M63 52.5 L63 61.5 M68 54 L68 60" stroke="%s" stroke-width="1.5" stroke-linecap="round"/></g>' % (
                 f(wing_rot), c("FL.wrenWing"), c("FL.wrenBar")))
    return "".join(o)


VISITORS = {
    "robin": {"parts": robin_parts, "legs": (49, 57, 73), "tint": "FL.stickerFrost", "name": "European robin"},
    "wren": {"parts": wren_parts, "legs": (47, 55, 72), "tint": "FL.stickerBark", "name": "Winter wren (Eurasian wren)"},
}


def visitor_pose(v, pose):
    p = VISITORS[v]
    rot = {"a": -38, "b": 26, "idle": 6}[pose]
    inner = p["parts"](rot)
    if pose == "idle":
        x1, x2, top = p["legs"]
        inner = legs(x1, x2, top, c("FL.leg")) + inner
    return inner


def sticker_svg(v):
    p = VISITORS[v]
    return ('<circle cx="60" cy="62" r="55" fill="#000" opacity=".12"/><circle cx="60" cy="58" r="55" fill="#fff"/>'
            '<circle cx="60" cy="58" r="47" fill="%s"/><g transform="translate(14 12) scale(.92)">%s</g>' % (c(p["tint"]), visitor_pose(v, "idle")))


def visitor_files():
    for v, p in VISITORS.items():
        for pose in ("a", "b", "idle"):
            write("visitor_%s_%s.svg" % (v, pose), svg_doc(100, 100, visitor_pose(v, pose),
                  "%s, %s frame. 100 x 100 like every VisitorArt sprite, facing leading. Wing turns about (56,52)." % (p["name"], {"a": "wings up", "b": "wings down", "idle": "resting, wings folded"}[pose])))
        write("visitor_%s_sticker.svg" % v, svg_doc(120, 120, sticker_svg(v),
              "%s sticker: the VisitorArt sticker frame (white r55 with .12 shadow, tint disc r47 %s), the idle pose at .92." % (p["name"], p["tint"])))


# ---------------------------------------------------------------- plants (200 x 200, LayeredPlantView layers)
def ground(rx=46):
    return '<ellipse cx="100" cy="177" rx="%s" ry="7" fill="%s" opacity=".14"/>' % (f(rx), c("Plant.groundShadow"))


def strap_leaf(x0, y0, x1, y1, bend, w):
    mx, my = (x0 + x1) / 2 + bend, (y0 + y1) / 2
    return ('<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s"/>'
            '<path d="M%s %s Q%s %s %s %s" stroke="%s" stroke-width="1.3" fill="none" stroke-linecap="round" opacity=".8"/>' % (
                f(x0 - w), f(y0), f(mx - w), f(my), f(x1), f(y1), f(mx + w), f(my), f(x0 + w), f(y0), c("FL.snowdropLeaf"),
                f(x0), f(y0 - 4), f(mx), f(my), f(x1), f(y1 + 6), c("FL.snowdropLeafVein")))


SNOWDROP_HEADS = [(118, 72, 1.0), (70, 88, 0.9), (140, 104, 0.85)]


def snowdrop_stem(x0, hx, hy, s):
    return ('<path d="M%s 176 C%s 140 %s 100 %s %s Q%s %s %s %s" stroke="%s" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
            '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % (
                f(x0), f(x0), f(hx - 14 * s), f(hx - 12 * s), f(hy - 8 * s), f(hx - 8 * s), f(hy - 16 * s), f(hx), f(hy - 6 * s),
                c("PetalKit.stem"), f(hx), f(hy - 3 * s), f(3.4 * s), f(4.4 * s), c("PetalKit.leaf")))


def snowdrop_petal(hx, hy, s, deg):
    return ('<ellipse cx="0" cy="%s" rx="%s" ry="%s" transform="translate(%s %s) rotate(%s)" fill="#FFFFFF" stroke="%s" stroke-width="2"/>' % (
        f(12 * s), f(5.6 * s), f(12 * s), f(hx), f(hy), f(deg), c("FL.snowdropEdge")))


def snowdrop_bell(hx, hy, s):
    return ('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFFFFF" stroke="%s" stroke-width="2"/>'
            '<path d="M%s %s L%s %s L%s %s" stroke="%s" stroke-width="%s" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' % (
                f(hx), f(hy + 10 * s), f(4.2 * s), f(7 * s), c("FL.snowdropEdge"),
                f(hx - 2.6 * s), f(hy + 13 * s), f(hx), f(hy + 15.6 * s), f(hx + 2.6 * s), f(hy + 13 * s), c("PetalKit.stem"), f(1.8 * s)))


def snowdrop_full(prefix=""):
    back = [strap_leaf(96, 176, 74, 104, -6, 4.2), strap_leaf(104, 176, 128, 112, 8, 4.2), strap_leaf(100, 176, 98, 124, 2, 3.6)]
    for (hx, hy, s), x0 in zip(SNOWDROP_HEADS, (100, 94, 106)):
        back.append(snowdrop_stem(x0, hx, hy, s))
    petals = []
    for r, (hx, hy, s) in enumerate(SNOWDROP_HEADS):
        for i, deg in enumerate((-28, 0, 28)):
            petals.append('<g id="%sr%d_s%d">%s</g>' % (prefix, r, i, snowdrop_petal(hx, hy, s, deg)))
    front = [snowdrop_bell(hx, hy, s) for hx, hy, s in SNOWDROP_HEADS]
    return ('<g id="%sground">%s</g><g id="%sback">%s</g><g id="%spetals">%s</g><g id="%sfront">%s</g>' % (
        prefix, ground(), prefix, "".join(back), prefix, "".join(petals), prefix, "".join(front)))


def snowdrop_stage(st, prefix):
    if st == 4:
        return snowdrop_full(prefix)
    if st == 0:
        return ground(22) + strap_leaf(97, 176, 94, 158, -1, 3.2) + strap_leaf(103, 176, 106, 160, 1, 3.2)
    if st == 1:
        return ground(30) + strap_leaf(96, 176, 86, 134, -3, 3.8) + strap_leaf(104, 176, 114, 138, 3, 3.8) + \
            '<path d="M100 176 V128" stroke="%s" stroke-width="3.2" stroke-linecap="round"/>' % c("PetalKit.stem")
    if st == 2:
        bud = ('<path d="M100 176 V100" stroke="%s" stroke-width="3.4" stroke-linecap="round"/>'
               '<path d="M100 76 C107 84 107 98 100 102 C93 98 93 84 100 76 Z" fill="#FFFFFF" stroke="%s" stroke-width="2"/>'
               '<path d="M100 104 C104 98 104 90 100 88" stroke="%s" stroke-width="2.6" fill="none" stroke-linecap="round"/>') % (
            c("PetalKit.stem"), c("FL.snowdropEdge"), c("PetalKit.leaf"))
        return ground(36) + strap_leaf(96, 176, 78, 116, -5, 4) + strap_leaf(104, 176, 124, 120, 6, 4) + bud
    # st == 3: one nodding bloom
    hx, hy, s = SNOWDROP_HEADS[0]
    o = ground(42) + strap_leaf(96, 176, 74, 108, -6, 4.2) + strap_leaf(104, 176, 128, 114, 8, 4.2)
    o += snowdrop_stem(100, hx, hy, s)
    o += "".join(snowdrop_petal(hx, hy, s, d) for d in (-28, 0, 28)) + snowdrop_bell(hx, hy, s)
    return o


HELLEBORE_HEADS = [(102, 74, 1.0), (60, 104, 0.8), (144, 100, 0.82)]


def hellebore_leaf(px, py, ang, s):
    o = []
    for k, d in enumerate((-56, -28, 0, 28, 56)):
        L = (1 - abs(d) / 140) * s
        o.append('<ellipse cx="0" cy="%s" rx="%s" ry="%s" transform="translate(%s %s) rotate(%s)" fill="%s"/>'
                 '<path d="M0 -2 V%s" transform="translate(%s %s) rotate(%s)" stroke="%s" stroke-width="1.3" stroke-linecap="round"/>' % (
                     f(-15 * L), f(5 * L), f(15 * L), f(px), f(py), f(ang + d), c("FL.helleboreLeaf"),
                     f(-26 * L), f(px), f(py), f(ang + d), c("FL.helleboreVein")))
    return "".join(o)


def hellebore_stem(x0, hx, hy):
    return '<path d="M%s 176 C%s 150 %s %s %s %s" stroke="%s" stroke-width="3.6" fill="none" stroke-linecap="round"/>' % (
        f(x0), f(x0), f(hx), f(hy + 40), f(hx), f(hy + 6), c("FL.helleboreStem"))


def hellebore_sepal(hx, hy, s, k):
    return ('<ellipse cx="0" cy="%s" rx="%s" ry="%s" transform="translate(%s %s) rotate(%s)" fill="%s" stroke="%s" stroke-width="1.6"/>'
            '<path d="M0 %s V%s" transform="translate(%s %s) rotate(%s)" stroke="%s" stroke-width="1.2" stroke-linecap="round" opacity=".55"/>' % (
                f(-13 * s), f(10 * s), f(13.5 * s), f(hx), f(hy), f(k * 72 - 8), c("FL.helleboreSepal"), c("FL.helleboreEdge"),
                f(-5 * s), f(-21 * s), f(hx), f(hy), f(k * 72 - 8), c("FL.helleboreEdge")))


def hellebore_centre(hx, hy, s):
    o = ['<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(hx), f(hy), f(6.5 * s), c("FL.helleboreCentre"))]
    for k in range(10):
        a = math.radians(k * 36)
        o.append('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (f(hx + 8.6 * s * math.sin(a)), f(hy - 8.6 * s * math.cos(a)), f(1.7 * s), c("FL.helleboreStamen")))
    return "".join(o)


def hellebore_full(prefix=""):
    back = [hellebore_stem(98, 102, 74), hellebore_stem(94, 60, 104), hellebore_stem(106, 144, 100),
            hellebore_leaf(84, 150, -60, 1.25), hellebore_leaf(118, 152, 62, 1.2), hellebore_leaf(100, 160, 0, 0.9)]
    petals = []
    for r, (hx, hy, s) in enumerate(HELLEBORE_HEADS):
        for k in range(5):
            petals.append('<g id="%sr%d_s%d">%s</g>' % (prefix, r, k, hellebore_sepal(hx, hy, s, k)))
    front = [hellebore_centre(hx, hy, s) for hx, hy, s in HELLEBORE_HEADS]
    return ('<g id="%sground">%s</g><g id="%sback">%s</g><g id="%spetals">%s</g><g id="%sfront">%s</g>' % (
        prefix, ground(56), prefix, "".join(back), prefix, "".join(petals), prefix, "".join(front)))


def hellebore_stage(st, prefix):
    if st == 4:
        return hellebore_full(prefix)
    if st == 0:
        return ground(22) + '<path d="M100 176 V160" stroke="%s" stroke-width="3" stroke-linecap="round"/>' % c("FL.helleboreStem") + hellebore_leaf(100, 160, 0, 0.55)
    if st == 1:
        return ground(32) + hellebore_stem(100, 100, 128).replace('stroke-width="3.6"', 'stroke-width="3"') + \
            hellebore_leaf(90, 150, -50, 0.85) + hellebore_leaf(110, 152, 50, 0.8)
    if st == 2:
        bud = ('<path d="M102 70 C112 78 112 94 102 98 C92 94 92 78 102 70 Z" fill="%s" stroke="%s" stroke-width="1.6"/>'
               '<path d="M102 74 V96" stroke="%s" stroke-width="1.2" opacity=".55"/>') % (c("FL.helleboreSepal"), c("FL.helleboreEdge"), c("FL.helleboreEdge"))
        return ground(40) + hellebore_stem(98, 102, 92) + hellebore_leaf(84, 150, -60, 1.1) + hellebore_leaf(118, 152, 62, 1.05) + bud
    hx, hy, s = HELLEBORE_HEADS[0]
    o = ground(48) + hellebore_stem(98, hx, hy) + hellebore_leaf(84, 150, -60, 1.2) + hellebore_leaf(118, 152, 62, 1.15)
    o += "".join(hellebore_sepal(hx, hy, s, k) for k in range(5)) + hellebore_centre(hx, hy, s)
    return o


STAGES = ["Tiny", "Sprout", "Bud", "Bloom", "Full bloom"]


def stage_sheet(fn, title):
    o = []
    for i in range(5):
        o.append(nest(i * 200, 0, 200, 200, 200, 200, fn(i, "st%d_" % i)))
        o.append('<text x="%s" y="218" text-anchor="middle" font-family="-apple-system, Helvetica, sans-serif" font-size="13" fill="#5B6B5B">%d %s</text>' % (f(i * 200 + 100), i, STAGES[i]))
    return svg_doc(1000, 226, "".join(o), title)


def plant_files():
    write("plant_snowdrop.svg", svg_doc(200, 200, snowdrop_full(),
          "Snowdrop (Galanthus nivalis), full bloom, 200 x 200 plant box. Groups = PlantThinning layers: ground, back (static), petals r<head>_s<i> (3 heads x 3 outer tepals), front (inner bells). Head pivots: (118,72) (70,88) (140,104)."))
    write("plant_hellebore.svg", svg_doc(200, 200, hellebore_full(),
          "Hellebore (Helleborus orientalis, Lenten rose), full bloom, 200 x 200 plant box. Layers: ground, back, petals r<head>_s<k> (3 heads x 5 sepals), front (centres). Head pivots: (102,74) (60,104) (144,100)."))
    write("plant_snowdrop_stages.svg", stage_sheet(snowdrop_stage, "Snowdrop at stages 0-4 (LifeStats.stageNames). Each panel is a 200 x 200 plant box; panel 4 = plant_snowdrop.svg."))
    write("plant_hellebore_stages.svg", stage_sheet(hellebore_stage, "Hellebore at stages 0-4 (LifeStats.stageNames). Each panel is a 200 x 200 plant box; panel 4 = plant_hellebore.svg."))


# ---------------------------------------------------------------- pack card (Shed Seasons shelf), 353 x 150
def snow_cap(x, y, w, col):
    return '<path d="M%s %s Q%s %s %s %s Q%s %s %s %s Q%s %s %s %s Z" fill="%s"/>' % (
        f(x), f(y), f(x + w * .25), f(y - 7), f(x + w * .5), f(y - 3), f(x + w * .75), f(y - 8), f(x + w), f(y),
        f(x + w * .5), f(y + 2), f(x), f(y), col)


def pot_at(pot, x, y, w, soil=True):
    return nest(x, y, w, w * 100 / 120, 120, 100, pot_svg(pot, soil=soil))


def plant_at(fn, x, y, size):
    return nest(x, y, size, size, 200, 200, fn(uid("p") + "_"))


def card_svg(dark):
    sky = c("FL.skyD2") if dark else c("FL.skyL1")
    o = ['<rect width="353" height="150" fill="%s"/>' % sky]
    o.append('<rect y="96" width="353" height="54" fill="%s"/>' % (c("FL.skyD3") if dark else c("FL.skyL3")))
    if dark:
        for x, y, r in [(30, 22, 1.2), (88, 14, 1), (150, 30, 1.3), (230, 12, 1), (300, 26, 1.2), (330, 60, 1), (20, 70, 1)]:
            o.append('<circle cx="%s" cy="%s" r="%s" fill="#E8EEF8" fill-opacity=".7"/>' % (f(x), f(y), f(r)))
    # lantern string, lanterns kept clear of the two plants
    o.append('<path d="M-4 8 Q90 40 176 28 Q262 16 357 14" stroke="%s" stroke-width="1.6" fill="none"/>' % c("FL.lanternInk" if not dark else "FL.snowShadeDark"))
    for x, y, b in [(24, 16, "FL.lanternRed"), (176, 28, "PetalKit.marigold"), (330, 14, "FL.lanternRed")]:
        o.append(lantern(x, y, 0.75, b, dark=dark))
    # far snowy ground and shelf
    o.append('<path d="M0 104 Q60 92 130 100 T260 98 T353 96 V122 H0 Z" fill="%s"/>' % (c("FL.snowDark") if dark else c("FL.snow")))
    o.append('<rect x="14" y="118" width="325" height="10" rx="4" fill="%s"/>' % c("FL.woodLight"))
    o.append('<rect x="14" y="125" width="325" height="3" rx="1.5" fill="%s"/>' % c("FL.woodEdge"))
    o.append(snow_cap(14, 119, 325, c("FL.snowDark") if dark else c("FL.snow")))
    # pots: frosted glass with snowdrop, lantern red empty with soil, snowflake indigo with hellebore
    fg, lr, si = POTS
    # the plant's base (y 177 of 200) sits on the soil top (y 13.5 of the pot box), drawn over the pot as in the app
    o.append(pot_at(fg, 66, 66, 64))
    o.append(plant_at(snowdrop_full, 52, 73 - 0.885 * 92, 92))
    o.append(pot_at(lr, 145, 70, 60))
    o.append(pot_at(si, 220, 66, 64))
    o.append(plant_at(hellebore_full, 204, 73 - 0.885 * 96, 96))
    # robin on the shelf end
    o.append(nest(286, 82, 44, 44, 100, 100, visitor_pose("robin", "idle")))
    o.append(snowflake(40, 66, 6, "#FFFFFF" if dark else c("FL.iceRim"), 1.6))
    o.append(snowflake(330, 62, 4.5, "#FFFFFF" if dark else c("FL.iceRim"), 1.3))
    return "".join(o)


def card_files():
    for th in ("light", "dark"):
        write("pack-card-%s.svg" % th, svg_doc(353, 150, card_svg(th == "dark"),
              "Frost & Lantern card art for the Shed Seasons shelf (13+ only) and the Settings > Plus > Seasons page header, %s. 353 x 150 like ShedScene. No text in the art: the app draws name, line and price under it." % th))


# ---------------------------------------------------------------- scene (Home and Garden background), 393 x 852
def fir(x, base, h, dark):
    col = c("FL.firDark") if dark else c("FL.fir")
    snow = c("FL.snowDark") if dark else c("FL.snow")
    o = []
    for i, k in enumerate((1.0, 0.78, 0.56)):
        top = base - h * (0.38 + i * 0.3)
        w = h * 0.36 * k
        o.append('<path d="M%s %s L%s %s L%s %s Z" fill="%s"/>' % (f(x), f(top), f(x + w), f(top + h * 0.42), f(x - w), f(top + h * 0.42), col))
        o.append('<path d="M%s %s L%s %s Q%s %s %s %s Z" fill="%s"/>' % (
            f(x), f(top), f(x + w * 0.45), f(top + h * 0.19), f(x), f(top + h * 0.15), f(x - w * 0.45), f(top + h * 0.19), snow))
    o.append('<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % (f(x - 3), f(base - h * 0.1), "6", f(h * 0.1), c("FL.postDark")))
    return "".join(o)


def lamp_post(x, base, h, dark):
    post = c("FL.postDark") if dark else c("FL.post")
    top = base - h
    o = ['<rect x="%s" y="%s" width="6" height="%s" rx="2" fill="%s"/>' % (f(x - 3), f(top), f(h), post),
         '<path d="M%s %s H%s" stroke="%s" stroke-width="4" stroke-linecap="round"/>' % (f(x - 1), f(top + 4), f(x + 22), post),
         snow_cap(x - 4, top + 1, 28, c("FL.snowDark") if dark else c("FL.snow")),
         lantern(x + 19, top + 6, 1.2, "FL.lanternRed", dark=dark)]
    return "".join(o)


def scene_svg(dark):
    sky = [c("FL.skyD1"), c("FL.skyD2"), c("FL.skyD3")] if dark else [c("FL.skyL1"), c("FL.skyL2"), c("FL.skyL3")]
    snow = c("FL.snowDark") if dark else c("FL.snow")
    shade = c("FL.snowShadeDark") if dark else c("FL.snowShade")
    o = ['<g id="sky"><rect width="393" height="852" fill="%s"/>'
         '<path d="M0 300 Q60 286 120 298 T240 294 T393 290 V852 H0 Z" fill="%s"/>'
         '<path d="M0 462 Q80 444 170 458 T320 452 T393 456 V852 H0 Z" fill="%s"/></g>' % tuple(sky)]
    o.append('<g id="moon"><circle cx="318" cy="118" r="26" fill="%s"/><circle cx="330" cy="110" r="22" fill="%s"/></g>' % (c("FL.moon"), sky[0]))
    if dark:
        stars = [(40, 60), (96, 140), (160, 48), (214, 120), (268, 70), (360, 200), (24, 230), (130, 260), (250, 230), (370, 40), (190, 330), (60, 380)]
        o.append('<g id="stars">%s</g>' % "".join('<circle cx="%s" cy="%s" r="1.3" fill="#E8EEF8" fill-opacity=".7"/>' % (f(x), f(y)) for x, y in stars))
    o.append('<g id="hills"><path d="M0 560 Q70 520 150 548 T300 534 T393 540 V852 H0 Z" fill="%s"/>'
             '<path d="M0 600 Q90 570 196 590 T393 584 V852 H0 Z" fill="%s"/></g>' % (c("FL.hillD") if dark else c("FL.hillL"), shade))
    o.append('<g id="firs">%s%s%s</g>' % (fir(44, 600, 92, dark), fir(352, 596, 110, dark), fir(312, 604, 70, dark)))
    # fence
    fence = []
    post = c("FL.postDark") if dark else c("FL.post")
    fence.append('<rect x="0" y="642" width="393" height="6" fill="%s"/><rect x="0" y="664" width="393" height="6" fill="%s"/>' % (post, post))
    for x in range(14, 393, 34):
        fence.append('<rect x="%s" y="630" width="10" height="56" rx="2" fill="%s"/>' % (f(x), post))
        fence.append(snow_cap(x - 2, 631, 14, snow))
    fence.append(snow_cap(0, 643, 393, snow))
    o.append('<g id="fence">%s</g>' % "".join(fence))
    # lantern string between two posts, then the posts
    o.append('<g id="lanterns"><path d="M86 590 Q196 614 306 590" stroke="%s" stroke-width="1.8" fill="none"/>' % (c("FL.stringDark") if dark else c("FL.lanternInk")))
    for x, y, b in [(132, 599, "FL.lanternRed"), (196, 602, "PetalKit.marigold"), (260, 599, "FL.lanternRed")]:
        o.append(lantern(x, y, 0.8, b, dark=dark))
    o.append(lamp_post(80, 700, 116, dark) + lamp_post(306, 700, 116, dark) + "</g>")
    # front snow bank with drifts and snowdrops peeking out
    o.append('<g id="snowbank"><path d="M0 690 Q60 672 140 688 T290 684 T393 680 V852 H0 Z" fill="%s"/>'
             '<path d="M0 742 Q110 724 210 744 T393 736" stroke="%s" stroke-width="10" fill="none" stroke-linecap="round" opacity=".7"/>'
             '<path d="M30 800 Q150 782 260 800" stroke="%s" stroke-width="8" fill="none" stroke-linecap="round" opacity=".6"/></g>' % (snow, shade, shade))
    tufts = []
    for x, y, s in [(52, 700, 0.45), (338, 694, 0.425)]:  # 1.25x the first draft, so the clumps hold on snow
        tufts.append(plant_at(snowdrop_full, x - 100 * s, y - 180 * s, 200 * s))
    o.append('<g id="snowdrops">%s</g>' % "".join(tufts))
    return "".join(o)


def scene_files():
    for th in ("light", "dark"):
        write("scene-%s.svg" % th, svg_doc(393, 852, scene_svg(th == "dark"),
              "Snowy lantern garden, %s: the pack scene behind Home and Garden (393 x 852, scale to fill width, bottom aligned). Named groups: sky, moon, stars (dark), hills, firs, fence, lanterns (glow halos animate here), snowbank, snowdrops. Snowfall comes from the weather layer, not this art." % th))


# ---------------------------------------------------------------- review sheets (agents only)
def review_svg(dark):
    th = "dark" if dark else "light"
    bg, sf, tx = c("appBackground." + th), c("appSurface." + th), c("appPrimaryText." + th)
    W, H = 1100, 1360
    o = ['<rect width="%d" height="%d" fill="%s"/>' % (W, H, bg)]

    def label(x, y, t, size=14, w="600"):
        o.append('<text x="%s" y="%s" font-family="-apple-system, Helvetica, sans-serif" font-size="%s" font-weight="%s" fill="%s">%s</text>' % (f(x), f(y), size, w, tx, t))

    def card(x, y, w, h):
        o.append('<rect x="%s" y="%s" width="%s" height="%s" rx="20" fill="%s"/>' % (f(x), f(y), f(w), f(h), sf))

    label(24, 36, "Frost &amp; Lantern art review, %s (appBackground with appSurface cards)" % th, 20, "700")
    # pots row: sizes 28 30 48 56 60 full on bg, outline on surface
    label(24, 72, "Pots: full colour at 28, 48, 56, 60 pt (on appBackground) and soft outline (on appSurface)")
    y = 84
    for i, pot in enumerate(POTS):
        yy = y + i * 92
        x = 24
        for w in (28, 48, 56, 60):
            o.append(pot_at(pot, x, yy + (60 - w * 100 / 120), w, soil=False))
            x += w + 14
        card(x + 6, yy - 6, 290, 80)
        x += 22
        for w in (28, 48, 60):
            o.append(nest(x, yy + (60 - w * 100 / 120), w, w * 100 / 120, 120, 100, pot_svg(pot, "toEarn", dark)))
            x += w + 14
        label(x + 4, yy + 40, pot["name"], 13, "600")
    # occupied stage at 140
    label(24, 380, "Occupied: the plant page stage pot (140 pt) with soil and a plant")
    stage_y = 392
    for i, (pot, fn) in enumerate(zip(POTS, (snowdrop_full, None, hellebore_full))):
        x = 24 + i * 190
        o.append(pot_at(pot, x, stage_y + 116, 140, soil=True))
        if fn:
            o.append(plant_at(fn, x - 5, stage_y + 116 + 15.75 - 0.885 * 150, 150))
    # badges
    label(620, 380, "Lantern Keeper t1, t2, t3 at 64 pt; t3 at 44 pt on a card")
    for t in (1, 2, 3):
        o.append(nest(620 + (t - 1) * 78, 396, 64, 64, 100, 100, badge_svg(t)))
    card(860, 390, 80, 76)
    o.append(nest(878, 406, 44, 44, 100, 100, badge_svg(3)))
    # glyph
    label(620, 500, "Seasons row glyph at 22 and 28 pt in appPrimaryText (template)")
    card(620, 512, 300, 54)
    o.append(nest(636, 528, 22, 22, 24, 24, glyph_svg(tx)))
    o.append(nest(668, 525, 28, 28, 24, 24, glyph_svg(tx)))
    label(708, 546, "Seasons", 17, "500")
    # card
    label(24, 640, "Seasons shelf card art (353 x 150), shown at 1x on a card")
    card(24, 652, 377, 174)
    o.append(nest(36, 664, 353, 150, 353, 150, card_svg(dark)))
    # visitors
    label(430, 640, "Visitors at 60 pt: a, b, idle; sticker at 108 pt")
    for r, v in enumerate(VISITORS):
        yy = 656 + r * 120
        for k, pose in enumerate(("a", "b", "idle")):
            o.append(nest(430 + k * 70, yy + 20, 60, 60, 100, 100, visitor_pose(v, pose)))
        o.append(nest(650, yy, 108, 108, 120, 120, sticker_svg(v)))
        label(770, yy + 60, VISITORS[v]["name"], 13)
    # plants stages
    label(24, 900, "Glasshouse plants, stages 0-4 at 100 pt")
    for r, fn in enumerate((snowdrop_stage, hellebore_stage)):
        for i in range(5):
            o.append(nest(24 + i * 110, 912 + r * 112, 100, 100, 200, 200, fn(i, uid("rv") + "_")))
    # scene thumbnail
    label(600, 900, "Scene, 393 x 852 at 0.48")
    o.append(nest(600, 912, 189, 409, 393, 852, scene_svg(dark)))
    card(810, 1060, 270, 110)
    label(826, 1100, "Cards over the scene keep", 13, "500")
    label(826, 1120, "appSurface, so text contrast", 13, "500")
    label(826, 1140, "never depends on the art.", 13, "500")
    return svg_doc(W, H, "".join(o), "Agent review sheet, %s. Not shipped." % th)


def main():
    pot_files()
    badge_files()
    write("seasons-row-glyph.svg", svg_doc(24, 24, glyph_svg(),
          "Seasons row glyph for Settings > Plus. 24 x 24, single colour: an outline paper lantern alone (2 stroke body, 1.2 rib oval, flat caps). Ship as a template image (renderingMode .template) so the Label tints it like its SF Symbol neighbours. Checked at 22, 24 and 28 pt."))
    visitor_files()
    plant_files()
    card_files()
    scene_files()
    write("review-light.svg", review_svg(False))
    write("review-dark.svg", review_svg(True))
    # PotMark lists for PotCatalog (Swift-ready)
    lines = ["// Generated by build.py. Paste into PotCatalog.marks(for:). Colour index -> decoration colours in the pot's order."]
    for pot in POTS:
        lines.append("case .%s:  // %s, colours %s" % (pot["kind"], pot["name"], ", ".join("0x" + c(n)[1:] for n in pot["colors"])))
        lines.append("    return [")
        for m in pot["marks"]():
            extra = ""
            if m["color"]:
                extra += ", color: %d" % m["color"]
            if m["opacity"] != 1:
                extra += ", opacity: %s" % f(m["opacity"])
            if m["ghost"] != "ink":
                extra += ", ghost: .%s" % m["ghost"]
            lines.append("        PotMark(shape: %s%s)," % (shape_swift(m["shape"]), extra))
        lines.append("    ]")
    write("pot-marks.swift.txt", "\n".join(lines) + "\n")


if __name__ == "__main__":
    main()

"""Generates the two listing images Play asks for that the app bundle has no
copy of: the 512x512 icon and the 1024x500 feature graphic.

The icon is the app icon at Play's size, so it comes straight from
generate_icons.py and always matches what is on the launcher. The feature
graphic is its own composition — same gradient, grid and arrow mark, with the
wordmark and tagline beside them.

Run from the project root:  python3 tool/generate_store_assets.py
"""
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_icons import (  # noqa: E402
    ARROW_FROM, ARROW_TO, BG_FROM, BG_TO, LIGHT, SHADOW,
    _arrow, _bar, _lerp, draw_icon,
)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'store/play')

W, H = 1024, 500
SS = 3  # supersample; PIL has no anti-aliasing

WORDMARK = 'ARROWS'
TAGLINE = 'Clear the board. Order is everything.'


def _font(px, weight):
    """DM Sans at a pixel size. It ships as a variable font, so the weight is
    an axis rather than a separate file."""
    f = ImageFont.truetype(os.path.join(ROOT, 'assets/fonts/DMSans.ttf'), px)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass  # a static build of the font ignores this and stays regular
    return f


def _background(w, h):
    n = 96
    g = Image.new('RGB', (n, n))
    px = g.load()
    for y in range(n):
        for x in range(n):
            px[x, y] = _lerp(BG_FROM, BG_TO,
                             x / (n - 1) * 0.62 + y / (n - 1) * 0.38)
    return g.resize((w, h), Image.BICUBIC)


def _light(w, h, centre, radius, strength=0.4):
    n = 128
    g = Image.new('RGB', (n, n), (0, 0, 0))
    px = g.load()
    cx, cy = centre[0] / w * n, centre[1] / h * n
    rx, ry = radius / w * n, radius / h * n
    for y in range(n):
        for x in range(n):
            d = math.hypot((x - cx) / rx, (y - cy) / ry)
            if d < 1:
                px[x, y] = _lerp((0, 0, 0), LIGHT, (1 - d) ** 2 * strength)
    return g.resize((w, h), Image.BICUBIC)


def _grid(w, h, u):
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    step, width = round(64 * u), max(1, round(2 * u))
    for x in range(step, w, step):
        d.line([(x, 0), (x, h)], fill=(255, 255, 255, 14), width=width)
    for y in range(step, h, step):
        d.line([(0, y), (w, y)], fill=(255, 255, 255, 14), width=width)
    return layer


def _mark_masks(w, h, u):
    """The arrow and its motion trail, sitting in the right-hand third."""
    cy = h / 2
    stroke, head = 46 * u, 74 * u

    arrow = Image.new('L', (w, h), 0)
    _arrow(ImageDraw.Draw(arrow), (668 * u, cy), (922 * u, cy), stroke, head)

    trail = Image.new('L', (w, h), 0)
    td = ImageDraw.Draw(trail)
    for x0, x1, dy, alpha in ((600, 652, -62, 150),
                              (566, 638, 0, 105),
                              (600, 652, 62, 150)):
        _bar(td, x0 * u, x1 * u, cy + dy * u, 30 * u, alpha)
    return arrow, trail


def _text(img, u):
    x = round(74 * u)
    pills = ['80 levels', 'Plays offline', 'No timer']
    f_pill = _font(round(26 * u), 500)

    # Measure first: the pill backgrounds have to be composited as a
    # translucent layer before any glyph is drawn over them.
    probe = ImageDraw.Draw(img)
    boxes, px = [], x
    for p in pills:
        w = probe.textlength(p, font=f_pill) + 40 * u
        boxes.append((px, px + w))
        px += w + 14 * u

    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    top, bot = round(330 * u), round(382 * u)
    for x0, x1 in boxes:
        ld.rounded_rectangle([x0, top, x1, bot], radius=26 * u,
                             fill=(255, 255, 255, 46))
    img = Image.alpha_composite(img.convert('RGBA'), layer).convert('RGB')

    d = ImageDraw.Draw(img)

    # Wordmark, letter-spaced by hand — PIL has no tracking control.
    f = _font(round(92 * u), 700)
    cx, track = x, 7 * u
    for ch in WORDMARK:
        d.text((cx, round(196 * u)), ch, font=f, fill=(255, 255, 255),
               anchor='ls')
        cx += d.textlength(ch, font=f) + track

    d.text((x, round(252 * u)), TAGLINE, font=_font(round(30 * u), 400),
           fill=(219, 228, 255), anchor='la')

    for (x0, _), p in zip(boxes, pills):
        d.text((x0 + 20 * u, (top + bot) / 2), p, font=f_pill,
               fill=(255, 255, 255), anchor='lm')
    return img


def feature_graphic():
    w, h = W * SS, H * SS
    u = w / W

    img = _background(w, h)
    img = ImageChops.add(img, _light(w, h, (w * 0.78, h * 0.5), w * 0.42))
    img = Image.alpha_composite(img.convert('RGBA'), _grid(w, h, u))

    arrow, trail = _mark_masks(w, h, u)

    # Trail reads as speed: the background washed toward white, not a solid.
    img = Image.composite(
        Image.blend(img.convert('RGB'),
                    Image.new('RGB', (w, h), (255, 255, 255)), 0.55),
        img.convert('RGB'), trail)

    shadow = arrow.filter(ImageFilter.GaussianBlur(radius=11 * u))
    shadow = ImageChops.offset(shadow, 0, round(7 * u))
    img = Image.composite(Image.new('RGB', (w, h), SHADOW), img,
                          shadow.point(lambda v: int(v * 0.42)))

    bar = Image.new('RGB', (1, 64))
    bp = bar.load()
    for y in range(64):
        bp[0, y] = _lerp(ARROW_FROM, ARROW_TO, y / 63)
    img = Image.composite(bar.resize((w, h), Image.BICUBIC), img, arrow)

    img = _text(img, u)
    return img.resize((W, H), Image.LANCZOS)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)

    icon = os.path.join(OUT, 'icon_512.png')
    draw_icon(512).convert('RGB').save(icon)
    print('play icon      : store/play/icon_512.png  (512x512)')

    fg = os.path.join(OUT, 'feature_graphic.png')
    feature_graphic().save(fg)
    print('feature graphic: store/play/feature_graphic.png  (1024x500)')

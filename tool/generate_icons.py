"""Generates the Arrows app icon, adaptive icon and launch mark.

The mark: a bright arrow breaking out of the board, motion trail behind it, on
a blue-violet gradient. Drawn at 4x and downsampled since PIL has no
anti-aliasing.

Run from the project root:  python3 tool/generate_icons.py
"""
import json
import math
import os
from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 4  # supersample factor

BG_FROM = (70, 106, 255)
BG_TO = (126, 66, 232)
LIGHT = (120, 170, 255)
ARROW_FROM = (255, 255, 255)
ARROW_TO = (226, 232, 255)
SHADOW = (8, 10, 32)


def _lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def _diagonal_gradient(size):
    n = 96
    g = Image.new('RGB', (n, n))
    px = g.load()
    for y in range(n):
        for x in range(n):
            px[x, y] = _lerp(BG_FROM, BG_TO,
                             x / (n - 1) * 0.55 + y / (n - 1) * 0.45)
    return g.resize((size, size), Image.BICUBIC)


def _radial_light(size, centre, radius, strength=0.35):
    n = 128
    g = Image.new('RGB', (n, n), (0, 0, 0))
    px = g.load()
    cx, cy = centre[0] / size * n, centre[1] / size * n
    r = radius / size * n
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - cx, y - cy) / r
            if d < 1:
                px[x, y] = _lerp((0, 0, 0), LIGHT, (1 - d) ** 2 * strength)
    return g.resize((size, size), Image.BICUBIC)


def _vertical_gradient(size):
    g = Image.new('RGB', (1, 64))
    px = g.load()
    for y in range(64):
        px[0, y] = _lerp(ARROW_FROM, ARROW_TO, y / 63)
    return g.resize((size, size), Image.BICUBIC)


def _bar(draw, x0, x1, y, width, fill):
    r = width / 2
    draw.line([(x0, y), (x1, y)], fill=fill, width=int(width))
    for cx in (x0, x1):
        draw.ellipse([cx - r, y - r, cx + r, y + r], fill=fill)


def _arrow(draw, tail, tip, stroke, head, fill=255):
    (x0, y0), (x1, y1) = tail, tip
    ux, uy = x1 - x0, y1 - y0
    length = math.hypot(ux, uy)
    ux, uy = ux / length, uy / length
    px, py = -uy, ux
    r = stroke / 2

    draw.line([tail, tip], fill=fill, width=int(stroke))
    for c in (tail, tip):
        draw.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fill)
    for sign in (1, -1):
        wing = (x1 - ux * head + px * head * 0.8 * sign,
                y1 - uy * head + py * head * 0.8 * sign)
        draw.line([wing, tip], fill=fill, width=int(stroke))
        draw.ellipse([wing[0] - r, wing[1] - r, wing[0] + r, wing[1] + r],
                     fill=fill)


def _mark(big, u, scale):
    """Arrow mask and trail mask, both centred on the canvas."""
    stroke, head = 112 * u * scale, 178 * u * scale
    cy = big / 2

    def x(v):
        return big / 2 + (v - 512) * u * scale

    arrow = Image.new('L', (big, big), 0)
    _arrow(ImageDraw.Draw(arrow), (x(286), cy), (x(772), cy), stroke, head)

    trail = Image.new('L', (big, big), 0)
    td = ImageDraw.Draw(trail)
    for x0, x1, dy, alpha in ((196, 352, -136, 150),
                              (146, 276, 0, 105),
                              (196, 352, 136, 150)):
        _bar(td, x(x0), x(x1), cy + dy * u * scale, 70 * u * scale, alpha)

    # Centre the whole group (arrow + trail) rather than the arrow alone.
    box = ImageChops.lighter(arrow, trail).getbbox()
    dx = round((big - (box[0] + box[2])) / 2)
    dy = round((big - (box[1] + box[3])) / 2)
    return ImageChops.offset(arrow, dx, dy), ImageChops.offset(trail, dx, dy)


def draw_icon(size, transparent=False, scale=1.0):
    big = size * S
    u = big / 1024
    arrow, trail = _mark(big, u, scale)

    if transparent:
        out = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        fill = _vertical_gradient(big).convert('RGBA')
        out = Image.composite(fill, out, arrow)
        white = Image.new('RGBA', (big, big), (255, 255, 255, 255))
        out = Image.composite(white, out, trail.point(lambda v: v * 0.5))
        return out.resize((size, size), Image.LANCZOS)

    img = _diagonal_gradient(big)
    img = ImageChops.add(img, _radial_light(big, (big * 0.5, big * 0.52),
                                            big * 0.62))

    # Faint board grid, well under the mark.
    layer = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w = max(1, round(3 * u))
    for i in range(1, 8):
        p = round(i * 128 * u)
        d.line([(p, 0), (p, big)], fill=(255, 255, 255, 16), width=w)
        d.line([(0, p), (big, p)], fill=(255, 255, 255, 16), width=w)
    img = Image.alpha_composite(img.convert('RGBA'), layer).convert('RGB')

    img = Image.composite(Image.blend(img, Image.new('RGB', (big, big),
                                                     (255, 255, 255)), 0.55),
                          img, trail)

    shadow = arrow.filter(ImageFilter.GaussianBlur(radius=26 * u))
    shadow = ImageChops.offset(shadow, 0, round(16 * u))
    img = Image.composite(Image.new('RGB', (big, big), SHADOW), img,
                          shadow.point(lambda v: int(v * 0.42)))

    img = Image.composite(_vertical_gradient(big), img, arrow)
    return img.resize((size, size), Image.LANCZOS)


def write_ios(root):
    folder = os.path.join(root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    with open(os.path.join(folder, 'Contents.json')) as f:
        contents = json.load(f)
    written = set()
    for entry in contents['images']:
        name = entry['filename']
        if name in written:
            continue
        px = round(float(entry['size'].split('x')[0]) *
                   float(entry['scale'].rstrip('x')))
        # The marketing icon must be opaque RGB with no alpha channel.
        draw_icon(px).convert('RGB').save(os.path.join(folder, name))
        written.add(name)
    return len(written)


def write_android(root):
    res = os.path.join(root, 'android/app/src/main/res')
    for density, px in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                        ('xxhdpi', 144), ('xxxhdpi', 192)):
        draw_icon(px).convert('RGB').save(
            os.path.join(res, f'mipmap-{density}/ic_launcher.png'))

    # Adaptive foreground: mark only — ic_launcher.xml already insets it 16%.
    for density, px in (('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
                        ('xxhdpi', 324), ('xxxhdpi', 432)):
        draw_icon(px, transparent=True, scale=1.15).save(
            os.path.join(res, f'drawable-{density}/ic_launcher_foreground.png'))
    return 10


if __name__ == '__main__':
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    draw_icon(1024).save(os.path.join(root, 'tool/icon_preview.png'))
    print('ios files :', write_ios(root))
    print('android   :', write_android(root))
    print('preview   : tool/icon_preview.png')

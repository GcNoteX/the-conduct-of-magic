"""Draws the placeholder art in art/placeholder/ (Claude-made stand-ins until real art arrives).

Run from the project root:  python3 tools/placeholder_art/make_placeholder_art.py
Needs Pillow (pip install pillow). Every image is drawn 4x bigger and scaled down, for smooth edges.
Sizes match the editor: map tiles are 56x64 (hex size 32), enchantment scenes use hex size 32.
"""

import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "art", "placeholder")
SS = 4  # supersampling factor
HEX = 32.0  # hex size (centre to corner) in pixels
SQRT3 = math.sqrt(3.0)

# Rune colours, matching BoardView.RUNE_COLORS (water, fire, wind, stone)
RUNES = {
    "water": ((74, 163, 255), (20, 70, 150)),
    "fire": ((255, 122, 61), (150, 40, 10)),
    "wind": ((191, 236, 203), (60, 130, 100)),
    "stone": ((180, 154, 116), (90, 70, 45)),
}


def hex_corners(cx, cy, size):
    return [
        (cx + math.cos(math.radians(60 * i - 30)) * size, cy + math.sin(math.radians(60 * i - 30)) * size)
        for i in range(6)
    ]


def axial_to_pixel(q, r, size=HEX):
    return (size * SQRT3 * (q + r / 2.0), size * 1.5 * r)


def scaled(points):
    return [(x * SS, y * SS) for x, y in points]


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(img, name):
    out = img.resize((img.width // SS, img.height // SS), Image.LANCZOS)
    path = os.path.join(OUT, name)
    out.save(path)
    print("wrote", os.path.normpath(path), out.size)
    return out


def mask_of(size, draw_fn):
    m = Image.new("L", size, 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def vertical_gradient(size, top, bottom):
    w, h = size
    g = Image.new("RGBA", size)
    px = g.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(w):
            px[x, y] = c
    return g


def radial_gradient(size, centre, radius, inner, outer):
    w, h = size
    g = Image.new("RGBA", size)
    px = g.load()
    for y in range(h):
        for x in range(w):
            d = min(1.0, math.hypot(x - centre[0], y - centre[1]) / radius)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * d) for i in range(4))
    return g


def paste_masked(img, layer, mask):
    img.alpha_composite(Image.composite(layer, Image.new("RGBA", img.size, (0, 0, 0, 0)), mask))


# ── Map tiles ────────────────────────────────────────────────────────────────


def steel_cell():
    """One item cell: a brushed steel hex with a bevel, 56x64."""
    w, h = 56, 64
    img = canvas(w, h)
    cx, cy = w / 2, h / 2
    outer = scaled(hex_corners(cx, cy, HEX - 0.5))
    inner = scaled(hex_corners(cx, cy, HEX - 3.5))
    # Bevel: light top-left edge, dark bottom-right edge
    bevel = vertical_gradient(img.size, (205, 212, 222), (70, 76, 86))
    paste_masked(img, bevel, mask_of(img.size, lambda d: d.polygon(outer, fill=255)))
    # Brushed face: a gradient with horizontal streaks
    face = vertical_gradient(img.size, (150, 158, 170), (104, 111, 122))
    rnd = random.Random(7)
    fd = ImageDraw.Draw(face)
    for _ in range(140):
        y = rnd.uniform(0, img.height)
        x0 = rnd.uniform(-20, img.width)
        length = rnd.uniform(20, 120) * SS / 2
        shade = rnd.randint(-22, 22)
        base = 128 + shade
        fd.line([(x0, y), (x0 + length, y)], fill=(base, base + 6, base + 14, 70), width=SS)
    face = face.filter(ImageFilter.GaussianBlur(SS * 0.4))
    paste_masked(img, face, mask_of(img.size, lambda d: d.polygon(inner, fill=255)))
    # Sheen across the top
    sheen = Image.new("RGBA", img.size, (255, 255, 255, 0))
    sd = ImageDraw.Draw(sheen)
    sd.ellipse([-10 * SS, -30 * SS, 50 * SS, 26 * SS], fill=(255, 255, 255, 38))
    sheen = sheen.filter(ImageFilter.GaussianBlur(SS * 4))
    paste_masked(img, sheen, mask_of(img.size, lambda d: d.polygon(inner, fill=255)))
    ImageDraw.Draw(img).polygon(outer, outline=(30, 32, 38, 255), width=SS)
    return finish(img, "cell_steel.png")


def glyph(d, kind, cx, cy, s, col, width):
    """A rune glyph centred on (cx, cy), about 2*s across, in supersampled pixels."""
    if kind == "water":  # a droplet
        pts = []
        for i in range(41):
            t = math.pi * 2 * i / 40
            x = math.sin(t) * s * 0.62 * (1 - 0.35 * math.cos(t))
            y = -math.cos(t) * s * 0.9
            if math.cos(t) > 0:  # pull the top into a point
                x *= (1 - math.cos(t)) ** 0.9
            pts.append((cx + x, cy + y + s * 0.15))
        d.line(pts + [pts[0]], fill=col, width=width, joint="curve")
        d.arc([cx - s * 0.32, cy, cx + s * 0.1, cy + s * 0.5], 100, 190, fill=col, width=width // 2)
    elif kind == "fire":  # a flame: two tongues
        def tongue(scale, dx):
            pts = []
            for i in range(31):
                t = i / 30
                y = cy + s * 0.85 - t * s * 1.8 * scale
                x = math.sin(t * math.pi) * s * 0.55 * scale * (1 - t * 0.3)
                pts.append((cx + dx + x + math.sin(t * 5) * s * 0.08, y))
            for i in range(30, -1, -1):
                t = i / 30
                y = cy + s * 0.85 - t * s * 1.8 * scale
                x = math.sin(t * math.pi) * s * 0.55 * scale * (1 - t * 0.3)
                pts.append((cx + dx - x + math.sin(t * 5) * s * 0.08, y))
            return pts

        d.line(tongue(1.0, 0) + [tongue(1.0, 0)[0]], fill=col, width=width, joint="curve")
        d.line(tongue(0.5, s * 0.05), fill=col, width=width // 2, joint="curve")
    elif kind == "wind":  # a swirl and two gusts
        pts = []
        for i in range(60):
            t = i / 59
            a = math.pi * 0.2 + t * math.pi * 2.6
            r = s * (0.15 + 0.6 * t)
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.85))
        d.line(pts, fill=col, width=width, joint="curve")
        d.line([(cx - s * 0.9, cy + s * 0.75), (cx + s * 0.3, cy + s * 0.75)], fill=col, width=width // 2)
    else:  # stone: a cut stone block, a hexagon with a facet
        pts = hex_corners(cx, cy, s * 0.85)
        d.line(pts + [pts[0]], fill=col, width=width, joint="curve")
        d.line([pts[4], (cx, cy), pts[0]], fill=col, width=width // 2)
        d.line([(cx, cy), pts[2]], fill=col, width=width // 2)


def rune_orb(img, kind, cx, cy, radius):
    """A glowing rune orb in supersampled coordinates."""
    light, dark = RUNES[kind]
    halo = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse(
        [cx - radius * 1.35, cy - radius * 1.35, cx + radius * 1.35, cy + radius * 1.35], fill=light + (150,)
    )
    img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(radius * 0.25)))
    ball = radial_gradient(
        img.size, (cx - radius * 0.35, cy - radius * 0.4), radius * 1.6, tuple(min(255, c + 70) for c in light) + (255,), dark + (255,)
    )
    paste_masked(
        img, ball, mask_of(img.size, lambda d: d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=255))
    )
    d = ImageDraw.Draw(img)
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], outline=(20, 18, 26, 255), width=int(SS * 1.5))
    glyph(d, kind, cx, cy, radius * 0.62, (255, 255, 250, 245), int(SS * 2.2))


def magic_node_tiles():
    """The four magic node tiles side by side (water, fire, wind, stone), 4 x 56x64.
    They sit on the Magic nodes layer above a cell, so everything around the orb is clear."""
    w, h = 56, 64
    img = canvas(w * 4, h)
    for i, kind in enumerate(["water", "fire", "wind", "stone"]):
        rune_orb(img, kind, (w * i + w / 2) * SS, h / 2 * SS, 17 * SS)
    return finish(img, "magic_node_tiles.png")


def ember_well():
    """The Ember Well: a 2-cell fire magic node (its own cell and the cell to its right).
    112x64, centred between the two cells."""
    w, h = 112, 64
    img = canvas(w, h)
    step = HEX * SQRT3
    left = (w / 2 - step / 2) * SS
    right = (w / 2 + step / 2) * SS
    cy = h / 2 * SS
    # Stone rim: a rounded slab over both cells
    rim = [left - 24 * SS, cy - 25 * SS, right + 24 * SS, cy + 25 * SS]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([rim[0], rim[1] + 3 * SS, rim[2], rim[3] + 3 * SS], radius=24 * SS, fill=(0, 0, 0, 140))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3 * SS)))
    stone = vertical_gradient(img.size, (122, 104, 92), (58, 46, 42))
    sd = ImageDraw.Draw(stone)
    rnd = random.Random(3)
    for _ in range(26):  # cobbles
        x = rnd.uniform(rim[0], rim[2])
        y = rnd.uniform(rim[1], rim[3])
        r = rnd.uniform(3, 7) * SS
        shade = rnd.randint(-25, 20)
        sd.ellipse([x - r, y - r * 0.8, x + r, y + r * 0.8], fill=(100 + shade, 86 + shade, 76 + shade, 255), outline=(40, 32, 30, 255), width=SS)
    paste_masked(img, stone, mask_of(img.size, lambda d: d.rounded_rectangle(rim, radius=24 * SS, fill=255)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(rim, radius=24 * SS, outline=(28, 20, 18, 255), width=int(1.5 * SS))
    # The ember pool
    pool = [left - 15 * SS, cy - 15 * SS, right + 15 * SS, cy + 15 * SS]
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle(pool, radius=15 * SS, fill=(255, 120, 40, 200))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(5 * SS)))
    lava = radial_gradient(img.size, (w / 2 * SS, cy), (step / 2 + 18) * SS, (255, 236, 150, 255), (190, 40, 10, 255))
    paste_masked(img, lava, mask_of(img.size, lambda d: d.rounded_rectangle(pool, radius=15 * SS, fill=255)))
    d.rounded_rectangle(pool, radius=15 * SS, outline=(70, 20, 8, 255), width=int(1.5 * SS))
    # Embers and sparks
    for _ in range(18):
        x = rnd.uniform(pool[0] + 6 * SS, pool[2] - 6 * SS)
        y = rnd.uniform(pool[1] + 5 * SS, pool[3] - 5 * SS)
        r = rnd.uniform(1.0, 2.4) * SS
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 250, 200, 230))
    # The anchor cell's fire glyph, so it reads as a fire node
    glyph(d, "fire", left, cy, 10 * SS, (90, 20, 5, 235), int(2.4 * SS))
    glyph(d, "fire", right, cy, 7 * SS, (120, 30, 8, 200), int(1.8 * SS))
    return finish(img, "ember_well.png")


# ── Enchantment art ──────────────────────────────────────────────────────────


def socket_face(img, cx, cy, radius):
    """A recessed socket with a bronze rim, in supersampled coordinates."""
    rim = radial_gradient(img.size, (cx - radius * 0.4, cy - radius * 0.5), radius * 2.0, (246, 214, 140, 255), (110, 70, 30, 255))
    paste_masked(img, rim, mask_of(img.size, lambda d: d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=255)))
    inner = radius * 0.74
    pit = radial_gradient(img.size, (cx + inner * 0.25, cy + inner * 0.3), inner * 1.4, (58, 54, 70, 255), (12, 11, 16, 255))
    paste_masked(img, pit, mask_of(img.size, lambda d: d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=255)))
    # Inner shadow along the top of the pit
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).arc([cx - inner, cy - inner, cx + inner, cy + inner], 190, 350, fill=(0, 0, 0, 200), width=int(3 * SS))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(SS)))
    d = ImageDraw.Draw(img)
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], outline=(40, 26, 12, 255), width=int(1.5 * SS))
    d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], outline=(60, 38, 16, 255), width=SS)
    for i in range(8):  # rivets on the rim
        a = math.tau * i / 8 + math.pi / 8
        rx = cx + math.cos(a) * radius * 0.87
        ry = cy + math.sin(a) * radius * 0.87
        r = radius * 0.06
        d.ellipse([rx - r, ry - r, rx + r, ry + r], fill=(255, 240, 190, 255))


def socket():
    """An empty enchantment node socket, 48x48 (the node circle in a scene is about 40 across)."""
    img = canvas(48, 48)
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([3 * SS, 5 * SS, 45 * SS, 47 * SS], fill=(0, 0, 0, 150))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(1.5 * SS)))
    socket_face(img, 24 * SS, 24 * SS, 21 * SS)
    return finish(img, "enchantment_socket.png")


BIG_CELLS = [(0, 0), (1, 0), (0, 1), (1, 1)]


def big_socket():
    """A 2x2 enchantment node: a bronze plate over its four cells with one big socket.
    The image's centre is the middle of the four cells; ports are drawn by the node itself."""
    centres = [axial_to_pixel(q, r) for q, r in BIG_CELLS]
    xs = [p[0] for p in centres]
    ys = [p[1] for p in centres]
    mid = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2)
    w, h = 144, 120
    img = canvas(w, h)
    ox = w / 2 - mid[0]
    oy = h / 2 - mid[1]
    polys = [scaled(hex_corners(x + ox, y + oy, HEX - 2.5)) for x, y in centres]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    for p in polys:
        sd.polygon([(x, y + 3 * SS) for x, y in p], fill=(0, 0, 0, 160))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(2.5 * SS)))
    plate_mask = mask_of(img.size, lambda d: [d.polygon(p, fill=255) for p in polys])
    plate = vertical_gradient(img.size, (150, 108, 58), (70, 46, 24))
    pd = ImageDraw.Draw(plate)
    for p in polys:  # engraved cell seams
        pd.line(p + [p[0]], fill=(52, 34, 16, 255), width=SS)
    paste_masked(img, plate, plate_mask)
    edge = plate_mask.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(5))
    img.alpha_composite(Image.composite(Image.new("RGBA", img.size, (36, 22, 10, 255)), Image.new("RGBA", img.size, (0, 0, 0, 0)), edge))
    # Engraved ring around the central socket
    d = ImageDraw.Draw(img)
    cx, cy = w / 2 * SS, h / 2 * SS
    d.ellipse([cx - 40 * SS, cy - 40 * SS, cx + 40 * SS, cy + 40 * SS], outline=(210, 170, 100, 160), width=SS)
    for i in range(12):
        a = math.tau * i / 12
        x = cx + math.cos(a) * 36 * SS
        y = cy + math.sin(a) * 36 * SS
        d.regular_polygon((x, y, 2 * SS), 4, rotation=45 + math.degrees(a), fill=(230, 196, 120, 200))
    socket_face(img, cx, cy, 30 * SS)
    out = finish(img, "enchantment_big_node_2x2.png")
    print("  big node sprite offset from the node's own cell:", (round(mid[0], 3), round(mid[1], 3)))
    return out


def rune_line():
    """A glowing rune line for a textured Line2D (texture mode Tile): 64x16, tiles along the line."""
    w, h = 64, 16
    img = canvas(w, h)
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rectangle([-10 * SS, 2 * SS, (w + 10) * SS, 14 * SS], fill=(150, 130, 255, 210))
    glow = glow.filter(ImageFilter.GaussianBlur(1.6 * SS))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    d.rectangle([-SS, 4.5 * SS, (w + 1) * SS, 11.5 * SS], fill=(196, 182, 255, 255))
    d.rectangle([-SS, 6.5 * SS, (w + 1) * SS, 9.5 * SS], fill=(255, 255, 255, 255))
    for x in (16, 48):  # rune marks along the line
        cx, cy = x * SS, 8 * SS
        d.regular_polygon((cx, cy, 6.5 * SS), 4, fill=(110, 84, 225, 255))
        d.regular_polygon((cx, cy, 3.6 * SS), 4, fill=(255, 255, 255, 255))
    return finish(img, "rune_line.png")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    steel_cell()
    magic_node_tiles()
    ember_well()
    socket()
    big_socket()
    rune_line()

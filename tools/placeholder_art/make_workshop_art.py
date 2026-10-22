"""Draws the workshop placeholder art: stones, item icons, the workbench and its leather mat.

Run from the project root:  python3 tools/placeholder_art/make_workshop_art.py
Needs Pillow (pip install pillow). Shares its helpers with make_placeholder_art.py.
The colours follow the counter's wood, parchment and brass (counter/counter_theme.tres), so the
counter and the table read as one shop. Stones are 64x64 and items 64x64; each stone has its own
cut, so they stay apart without relying on colour alone.
"""

import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

from make_placeholder_art import SS, canvas, mask_of, paste_masked, radial_gradient

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "art", "placeholder")
BRASS_LIGHT = (246, 214, 140, 255)
BRASS_DARK = (110, 70, 30, 255)
OUTLINE = (34, 22, 12, 255)


def save(img, folder, name):
    out = img.resize((img.width // SS, img.height // SS), Image.LANCZOS)
    path = os.path.join(ROOT, folder, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out.save(path)
    print("wrote", os.path.normpath(path), out.size)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


def drop_shadow(img, polygon=None, ellipse=None, offset=(1.5, 2.5), blur=2.0):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    ox, oy = offset[0] * SS, offset[1] * SS
    if polygon:
        d.polygon([(x + ox, y + oy) for x, y in polygon], fill=(0, 0, 0, 140))
    if ellipse:
        x0, y0, x1, y1 = ellipse
        d.ellipse([x0 + ox, y0 + oy, x1 + ox, y1 + oy], fill=(0, 0, 0, 140))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur * SS)))


def faceted(img, outline, centre, table, light, dark):
    """A cut gem: each facet runs from an outline edge to the table, lit from the top left."""
    d = ImageDraw.Draw(img)
    n = len(outline)
    for i in range(n):
        a, b = outline[i], outline[(i + 1) % n]
        ta, tb = table[i], table[(i + 1) % n]
        mx, my = (a[0] + b[0]) / 2 - centre[0], (a[1] + b[1]) / 2 - centre[1]
        lit = (-mx - my) / (math.hypot(mx, my) * math.sqrt(2) + 1e-6)  # -1 (shadow) to 1 (lit)
        t = (lit + 1) / 2
        col = tuple(int(dark[k] + (light[k] - dark[k]) * t) for k in range(3)) + (255,)
        d.polygon([a, b, tb, ta], fill=col)
    d.polygon(table, fill=tuple(int((light[k] * 2 + dark[k]) / 3) for k in range(3)) + (255,))
    d.polygon(outline, outline=OUTLINE, width=int(1.2 * SS))
    for i in range(n):
        d.line([outline[i], table[i]], fill=shade(dark, 0.7)[:3] + (160,), width=SS // 2)
    d.polygon(table, outline=shade(light, 1.15)[:3] + (200,), width=SS // 2)


def ring(cx, cy, rx, ry, n, rot=0.0):
    return [
        (cx + math.cos(rot + math.tau * i / n) * rx, cy + math.sin(rot + math.tau * i / n) * ry)
        for i in range(n)
    ]


def sparkle(img, x, y, size, alpha=230):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    s, w = size * SS, size * SS * 0.18
    d.polygon([(x, y - s), (x + w, y), (x, y + s), (x - w, y)], fill=(255, 255, 240, alpha))
    d.polygon([(x - s, y), (x, y - w), (x + s, y), (x, y + w)], fill=(255, 255, 240, alpha))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(SS * 0.3)))


def gloss(img, box, alpha=150):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=(255, 255, 255, alpha))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(SS * 1.2)))


# ── Stones ───────────────────────────────────────────────────────────────────


def fire_stone():
    """Flame: a pointed, flame-cut gem in orange with an ember glow at its heart."""
    img = canvas(64, 64)
    c = (32 * SS, 35 * SS)
    outline = [(32, 6), (42, 18), (50, 34), (46, 50), (32, 58), (18, 50), (14, 34), (22, 18)]
    outline = [(x * SS, y * SS) for x, y in outline]
    table = [(c[0] + (x - c[0]) * 0.45, c[1] + (y - c[1]) * 0.45) for x, y in outline]
    drop_shadow(img, polygon=outline)
    faceted(img, outline, c, table, (255, 178, 92), (150, 38, 12))
    glow = radial_gradient(img.size, (32 * SS, 38 * SS), 12 * SS, (255, 236, 150, 210), (255, 120, 40, 0))
    paste_masked(img, glow, mask_of(img.size, lambda d: d.polygon(table, fill=255)))
    sparkle(img, 26 * SS, 22 * SS, 3.5)
    save(img, "stones", "fire_stone.png")


def water_stone():
    """Water: a smooth droplet, polished rather than cut, with a ripple inside."""
    img = canvas(64, 64)
    pts = []
    for i in range(64):
        a = math.tau * i / 64
        r = 20 * SS
        x = 32 * SS + math.cos(a) * r
        y = 38 * SS + math.sin(a) * r
        if math.sin(a) < 0:  # pull the top into a point
            k = (-math.sin(a)) ** 3
            x = 32 * SS + (x - 32 * SS) * (1 - k * 0.85)
            y -= k * 14 * SS
        pts.append((x, y))
    drop_shadow(img, polygon=pts)
    body = radial_gradient(img.size, (26 * SS, 30 * SS), 30 * SS, (150, 210, 255, 255), (18, 60, 140, 255))
    paste_masked(img, body, mask_of(img.size, lambda d: d.polygon(pts, fill=255)))
    d = ImageDraw.Draw(img)
    for k, y in enumerate((40, 46)):
        d.arc([(20 + k * 3) * SS, (y - 5) * SS, (44 - k * 3) * SS, (y + 5) * SS], 20, 160, fill=(200, 235, 255, 150), width=SS)
    d.polygon(pts, outline=OUTLINE, width=int(1.2 * SS))
    gloss(img, [22 * SS, 22 * SS, 30 * SS, 34 * SS])
    save(img, "stones", "water_stone.png")


def red_stone():
    """Soft and shiny: a round, glossy cabochon with a broad highlight."""
    img = canvas(64, 64)
    box = [11 * SS, 13 * SS, 53 * SS, 55 * SS]
    drop_shadow(img, ellipse=box)
    body = radial_gradient(img.size, (26 * SS, 26 * SS), 34 * SS, (255, 120, 140, 255), (110, 12, 36, 255))
    paste_masked(img, body, mask_of(img.size, lambda d: d.ellipse(box, fill=255)))
    rim = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(rim).arc(box, 20, 160, fill=(255, 170, 180, 120), width=int(2 * SS))
    img.alpha_composite(rim.filter(ImageFilter.GaussianBlur(SS)))
    ImageDraw.Draw(img).ellipse(box, outline=OUTLINE, width=int(1.2 * SS))
    gloss(img, [18 * SS, 18 * SS, 36 * SS, 30 * SS], 180)
    save(img, "stones", "red_stone.png")


def blue_stone():
    """Hard: an upright hexagonal crystal with sharp facets."""
    img = canvas(64, 64)
    c = (32 * SS, 32 * SS)
    outline = ring(c[0], c[1], 17 * SS, 25 * SS, 6, -math.pi / 2)
    table = ring(c[0], c[1], 8 * SS, 12 * SS, 6, -math.pi / 2)
    drop_shadow(img, polygon=outline)
    faceted(img, outline, c, table, (150, 170, 255), (20, 28, 110))
    d = ImageDraw.Draw(img)
    d.line([table[0], table[3]], fill=(200, 210, 255, 140), width=SS // 2)
    sparkle(img, 25 * SS, 20 * SS, 3)
    save(img, "stones", "blue_stone.png")


def yellow_stone():
    """Shiny and hard, and the only tier 2 stone: a brilliant cut set in a brass bezel."""
    img = canvas(64, 64)
    c = (32 * SS, 32 * SS)
    bezel = [c[0] - 26 * SS, c[1] - 26 * SS, c[0] + 26 * SS, c[1] + 26 * SS]
    drop_shadow(img, ellipse=bezel)
    rim = radial_gradient(img.size, (22 * SS, 18 * SS), 56 * SS, BRASS_LIGHT, BRASS_DARK)
    paste_masked(img, rim, mask_of(img.size, lambda d: d.ellipse(bezel, fill=255)))
    d = ImageDraw.Draw(img)
    d.ellipse(bezel, outline=OUTLINE, width=int(1.2 * SS))
    for i in range(8):  # prongs
        a = math.tau * i / 8 + math.pi / 8
        px, py = c[0] + math.cos(a) * 21 * SS, c[1] + math.sin(a) * 21 * SS
        d.ellipse([px - 2 * SS, py - 2 * SS, px + 2 * SS, py + 2 * SS], fill=(255, 240, 190, 255))
    outline = ring(c[0], c[1], 19 * SS, 19 * SS, 8, math.pi / 8)
    table = ring(c[0], c[1], 9 * SS, 9 * SS, 8, math.pi / 8)
    faceted(img, outline, c, table, (255, 240, 140), (160, 110, 10))
    sparkle(img, 25 * SS, 24 * SS, 5)
    sparkle(img, 40 * SS, 38 * SS, 2.5, 180)
    save(img, "stones", "yellow_stone.png")


# ── Items ────────────────────────────────────────────────────────────────────


def sword(name, blade, guard, grip):
    """A sword laid diagonally, point to the top right. Lengths are in pixels along the sword."""
    img = canvas(64, 64)
    total = blade + grip + 6
    # Axis from the pommel (bottom left) to the point (top right), centred in the icon
    ux, uy = 1 / math.sqrt(2), -1 / math.sqrt(2)
    nx, ny = -uy, ux
    start = 32 - ux * total / 2, 32 - uy * total / 2

    def at(t, s=0.0):
        return ((start[0] + ux * t + nx * s) * SS, (start[1] + uy * t + ny * s) * SS)

    pommel_t, guard_t = 3, 6 + grip
    tip_t = guard_t + blade
    half = 4.6 - blade / 40
    blade_poly = [at(guard_t, -half), at(tip_t - 6, -half), at(tip_t), at(tip_t - 6, half), at(guard_t, half)]
    guard_poly = [at(guard_t - 2, -guard), at(guard_t + 2, -guard), at(guard_t + 2, guard), at(guard_t - 2, guard)]
    grip_poly = [at(pommel_t, -2.4), at(guard_t, -2.4), at(guard_t, 2.4), at(pommel_t, 2.4)]
    drop_shadow(img, polygon=blade_poly + guard_poly[::-1])
    d = ImageDraw.Draw(img)
    # Blade: a lit half and a shaded half either side of the fuller
    d.polygon([at(guard_t, -half), at(tip_t - 6, -half), at(tip_t), at(guard_t, 0)], fill=(214, 222, 232, 255))
    d.polygon([at(guard_t, 0), at(tip_t), at(tip_t - 6, half), at(guard_t, half)], fill=(126, 134, 148, 255))
    d.line([at(guard_t + 2), at(tip_t - 9)], fill=(90, 96, 110, 255), width=SS)
    d.polygon(blade_poly, outline=OUTLINE, width=SS)
    # Grip: leather wrap
    d.polygon(grip_poly, fill=(150, 96, 54, 255), outline=OUTLINE, width=SS)
    for t in range(pommel_t + 2, guard_t, 3):
        d.line([at(t, -2.4), at(t + 1.5, 2.4)], fill=(96, 58, 28, 255), width=SS)
    # Guard and pommel: brass
    d.polygon(guard_poly, fill=(214, 170, 80, 255), outline=OUTLINE)
    d.line([at(guard_t - 0.6, -guard + 1), at(guard_t - 0.6, guard - 1)], fill=(255, 232, 160, 255), width=SS)
    px, py = at(pommel_t - 1)
    r = 4 * SS
    d.ellipse([px - r, py - r, px + r, py + r], fill=(214, 170, 80, 255), outline=OUTLINE, width=SS)
    d.ellipse([px - r * 0.5, py - r * 0.6, px, py - r * 0.1], fill=(255, 232, 160, 255))
    save(img, "items", name + ".png")


# ── Workbench ────────────────────────────────────────────────────────────────


def workbench():
    """A tileable oak workbench top, 512x512: four planks running across, slightly lighter and
    warmer than the counter's wood so the two sides of the shop are told apart."""
    w = h = 512
    img = Image.new("RGBA", (w, h))
    px = img.load()
    rnd = random.Random(11)
    planks = 4
    ph = h // planks
    tones = [(118, 80, 48), (126, 86, 52), (112, 76, 46), (122, 84, 50)]
    waves = [[(rnd.randint(1, 4), rnd.uniform(0, math.tau), rnd.uniform(1.5, 4)) for _ in range(3)] for _ in range(planks)]
    for y in range(h):
        p = y // ph
        base = tones[p]
        local = (y % ph) / ph
        for x in range(w):
            u = x / w * math.tau
            offset = sum(a * math.sin(k * u + ph_) for k, ph_, a in waves[p])
            g = math.sin((local * ph + offset) * 0.55) * 0.5 + math.sin((local * ph + offset * 1.7) * 0.13) * 0.5
            f = 1.0 + g * 0.08
            edge = min(y % ph, ph - 1 - y % ph)
            if edge < 3:
                f *= 0.55 + edge * 0.12
            px[x, y] = shade(base, f)
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    path = os.path.join(ROOT, "workbench_wood.png")
    img.convert("RGB").save(path)
    print("wrote", os.path.normpath(path), img.size)


def leather_mat():
    """The leather mat the item lies on, as a nine-patch: 128x128 with 28 px margins, dark green
    leather with a stitched border."""
    img = canvas(128, 128)
    box = [2 * SS, 2 * SS, 126 * SS, 126 * SS]
    leather = radial_gradient(img.size, (64 * SS, 64 * SS), 100 * SS, (52, 74, 58, 255), (30, 44, 34, 255))
    rnd = random.Random(5)
    ld = ImageDraw.Draw(leather)
    for _ in range(900):  # grain
        x, y = rnd.uniform(0, img.width), rnd.uniform(0, img.height)
        v = rnd.randint(-14, 14)
        ld.point((x, y), fill=(52 + v, 74 + v, 58 + v, 255))
    leather = leather.filter(ImageFilter.GaussianBlur(SS * 0.5))
    paste_masked(img, leather, mask_of(img.size, lambda d: d.rounded_rectangle(box, 10 * SS, fill=255)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box, 10 * SS, outline=(20, 28, 22, 255), width=int(2 * SS))
    inset = 12 * SS
    stitch = [box[0] + inset, box[1] + inset, box[2] - inset, box[3] - inset]
    step = 6 * SS
    x0, y0, x1, y1 = stitch
    segments = []
    for x in range(int(x0), int(x1), step):
        segments += [((x, y0), (x + step * 0.55, y0)), ((x, y1), (x + step * 0.55, y1))]
    for y in range(int(y0), int(y1), step):
        segments += [((x0, y), (x0, y + step * 0.55)), ((x1, y), (x1, y + step * 0.55))]
    for a, b in segments:
        d.line([a, b], fill=(214, 196, 150, 220), width=int(1.2 * SS))
    save(img, "", "leather_mat.png")


if __name__ == "__main__":
    fire_stone()
    water_stone()
    red_stone()
    blue_stone()
    yellow_stone()
    sword("dagger", 30, 9, 12)
    sword("short_sword", 44, 10, 13)
    sword("long_sword", 56, 12, 15)
    workbench()
    leather_mat()

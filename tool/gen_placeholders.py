#!/usr/bin/env python3
"""Procedural top-down plant cut-outs (transparent WebP).

Used as the fallback when tool/fetch_images.py cannot find or download a
real photo, so the app always has art to show. Pure Pillow, no network.

    python3 tool/gen_placeholders.py            # fill only missing files
    python3 tool/gen_placeholders.py --force    # regenerate everything
"""
import math
import random
import sys
import zlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "assets" / "plants"
SIZE = 768
SS = 2  # supersampling factor for smooth edges

# id -> (style, base colour, highlight colour)
PLANTS = {
    "aloe_vera": ("spiky_fat", (74, 120, 78), (150, 190, 120)),
    "pontiatus_evo": ("round", (88, 140, 70), (170, 205, 120)),
    "boxwood_ball": ("bush", (38, 78, 34), (96, 140, 70)),
    "tillandsia_rosette": ("rosette", (70, 105, 72), (165, 200, 130)),
    "dracaena_burst": ("spiky", (90, 150, 50), (190, 225, 90)),
    "echeveria_jade": ("rosette", (95, 135, 110), (185, 215, 175)),
    "agave_blue": ("spiky_fat", (90, 125, 125), (170, 200, 195)),
    "lavender_dome": ("bush", (95, 115, 100), (160, 150, 200)),
    "rosemary_mound": ("needles", (55, 90, 60), (120, 160, 110)),
    "juniper_cushion": ("needles", (60, 100, 95), (130, 175, 160)),
    "sedum_carpet": ("carpet", (100, 150, 70), (190, 215, 120)),
    "calathea_orbifolia": ("round", (60, 110, 70), (175, 205, 170)),
    "haworthia_zebra": ("rosette", (40, 80, 55), (140, 170, 140)),
    "fern_nest": ("spiky", (70, 130, 50), (150, 200, 90)),
    "peperomia_round": ("round", (55, 105, 55), (130, 180, 90)),
    "jade_crassula": ("carpet", (60, 115, 65), (140, 190, 110)),
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def leaf(draw, cx, cy, angle, length, width, colour, tip=0.0, start=0.0):
    """Leaf polygon from centre outward; tip>0 makes it pointy."""
    pts_l, pts_r = [], []
    steps = 24
    for i in range(steps + 1):
        t = i / steps
        r = start + (length - start) * t
        # widest a third of the way out, tapering to a (pointy) tip
        w = width * math.sin(math.pi * t ** (0.6 + tip * 0.6)) ** 0.8
        w *= (1 - tip * t * 0.5)
        px = cx + math.cos(angle) * r
        py = cy + math.sin(angle) * r
        nx, ny = -math.sin(angle), math.cos(angle)
        pts_l.append((px + nx * w / 2, py + ny * w / 2))
        pts_r.append((px - nx * w / 2, py - ny * w / 2))
    draw.polygon(pts_l + pts_r[::-1], fill=colour + (255,))
    # mid-rib
    draw.line([(cx + math.cos(angle) * start, cy + math.sin(angle) * start),
               (cx + math.cos(angle) * length * 0.8, cy + math.sin(angle) * length * 0.8)],
              fill=lerp(colour, (255, 255, 255), 0.25) + (110,), width=max(1, int(width * 0.06)))


def render(style, base, hi, seed):
    rnd = random.Random(seed)
    S = SIZE * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    c = S / 2
    R = S * 0.47

    if style in ("rosette", "spiky_fat"):
        layers = 5 if style == "rosette" else 3
        for L in range(layers):
            n = (9 if style == "rosette" else 8) + L * 2
            length = R * (1 - L / (layers + 0.6))
            width = length * (0.55 if style == "rosette" else 0.32)
            off = rnd.random() * math.pi
            for i in range(n):
                a = off + i * 2 * math.pi / n + rnd.uniform(-0.08, 0.08)
                col = lerp(base, hi, L / layers + rnd.uniform(-0.05, 0.1))
                leaf(d, c, c, a, length * rnd.uniform(0.9, 1.05), width, col, tip=0.5)
    elif style == "spiky":
        for L in range(4):
            n = 14 + L * 4
            for i in range(n):
                a = rnd.random() * 2 * math.pi
                length = R * rnd.uniform(0.55, 1.0) * (1 - L * 0.15)
                col = lerp(base, hi, L / 4 + rnd.uniform(0, 0.25))
                leaf(d, c, c, a, length, length * 0.12, col, tip=0.8)
    elif style == "round":
        for L in range(4):
            n = 6 + L
            off = rnd.random() * math.pi
            for i in range(n):
                a = off + i * 2 * math.pi / n
                dist = R * (0.5 - L * 0.11)
                rr = R * (0.42 - L * 0.07)
                x, y = c + math.cos(a) * dist, c + math.sin(a) * dist
                col = lerp(base, hi, L / 4 + rnd.uniform(0, 0.15))
                d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col + (255,))
                d.line([(c, c), (x + math.cos(a) * rr * 0.8, y + math.sin(a) * rr * 0.8)],
                       fill=lerp(col, (255, 255, 255), 0.3) + (120,), width=int(rr * 0.05) + 1)
    elif style in ("bush", "needles", "carpet"):
        count = {"bush": 2600, "needles": 3800, "carpet": 900}[style]
        for k in range(count):
            t = k / count
            rad = R * math.sqrt(rnd.random()) * (1.0 if style != "carpet" else 0.95)
            a = rnd.random() * 2 * math.pi
            x, y = c + math.cos(a) * rad, c + math.sin(a) * rad
            # light from the top-left, darker toward the rim
            shade = 0.55 * (1 - rad / R) + 0.35 * t + rnd.uniform(-0.1, 0.15)
            shade += 0.15 * (-(x - c) - (y - c)) / R
            col = lerp(base, hi, max(0, min(1, shade)))
            if style == "bush":
                leaf(d, x, y, rnd.random() * 6.28, R * 0.075, R * 0.05, col, tip=0.4)
            elif style == "needles":
                leaf(d, x, y, a + rnd.uniform(-0.6, 0.6), R * 0.09, R * 0.018, col, tip=0.9)
            else:
                rr = R * rnd.uniform(0.035, 0.06)
                d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col + (255,))

    img = img.filter(ImageFilter.SMOOTH)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def generate(plant_id, force=False):
    style, base, hi = PLANTS[plant_id]
    path = OUT / f"{plant_id}.webp"
    if path.exists() and not force:
        return path
    OUT.mkdir(parents=True, exist_ok=True)
    img = render(style, base, hi, seed=zlib.crc32(plant_id.encode()))
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    img.save(path, "WEBP", quality=90, method=6)
    return path


if __name__ == "__main__":
    force = "--force" in sys.argv
    for pid in PLANTS:
        print("generated", generate(pid, force))

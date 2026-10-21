#!/usr/bin/env python3
"""Cut a plant shot on a flat magenta (#FF00FF) backdrop into a transparent,
trimmed, soft-edged WebP.

    python3 tool/key_magenta.py in.png assets/plants/name.webp [--size 768]

Alpha comes from how far each pixel sits from the backdrop colour (green
foliage is the opposite of magenta, so the matte is clean); edge pixels are
despilled so no pink fringe survives on the app's green surfaces.
"""
import argparse

import numpy as np
from PIL import Image, ImageFilter


def key(src: Image.Image) -> Image.Image:
    rgb = np.asarray(src.convert('RGB')).astype(np.float32) / 255.0
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    # Backdrop estimate from the four corners.
    h, w = r.shape
    k = max(4, min(h, w) // 40)
    corners = np.concatenate([
        rgb[:k, :k].reshape(-1, 3), rgb[:k, -k:].reshape(-1, 3),
        rgb[-k:, :k].reshape(-1, 3), rgb[-k:, -k:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    # "Magenta-ness": how much red+blue exceed green, relative to backdrop.
    m = np.clip((np.minimum(r, b) - g), 0, 1)
    m_bg = max(1e-3, float(min(bg[0], bg[2]) - bg[1]))
    a = 1.0 - np.clip((m / m_bg - 0.12) / (0.62 - 0.12), 0, 1)
    # Despill: pull red/blue down to green where magenta leaks into edges.
    spill = np.clip(np.minimum(r, b) - g, 0, None)
    r2 = r - spill * 0.9
    b2 = b - spill * 0.9
    out = np.dstack([np.clip(r2, 0, 1), g, np.clip(b2, 0, 1), a])
    img = Image.fromarray((out * 255).astype(np.uint8), 'RGBA')
    # Tiny matte choke + blur for a soft, clean edge.
    alpha = img.getchannel('A').filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    img.putalpha(alpha)
    return img


def trim(img: Image.Image, pad_ratio: float = 0.02) -> Image.Image:
    a = np.asarray(img.getchannel('A'))
    ys, xs = np.where(a > 8)
    if len(xs) == 0:
        return img
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    side = int(max(x1 - x0, y1 - y0) * (1 + 2 * pad_ratio))
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    canvas.paste(img.crop((x0, y0, x1 + 1, y1 + 1)), (side // 2 - (cx - x0), side // 2 - (cy - y0)))
    return canvas


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('dst')
    ap.add_argument('--size', type=int, default=768)
    ap.add_argument('--quality', type=int, default=86)
    args = ap.parse_args()
    img = trim(key(Image.open(args.src)))
    img = img.resize((args.size, args.size), Image.LANCZOS)
    img.save(args.dst, 'WEBP', quality=args.quality, method=6)


if __name__ == '__main__':
    main()

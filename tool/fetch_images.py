#!/usr/bin/env python3
"""Dev-time image fetcher for florest. Run once; the app never hot-links.

For every plant it:
  1. searches free-licence sources for a TOP-DOWN plant photo
     - Wikimedia Commons (no key needed)
     - Pixabay (only if PIXABAY_KEY is set; free key at pixabay.com/api/docs)
  2. downloads the best candidate,
  3. removes the background with `rembg` when the image is not already
     transparent (pip install rembg),
  4. trims transparent padding, resizes to max 1024 px, saves WebP q90 into
     assets/plants/<id>.webp,
  5. records source URL + licence in CREDITS.md.
If nothing usable is found it falls back to a procedural cut-out
(tool/gen_placeholders.py) so the app always runs.

    pip install pillow requests rembg
    python3 tool/fetch_images.py              # only missing images
    python3 tool/fetch_images.py --force      # refetch everything
    python3 tool/fetch_images.py --only aloe_vera dracaena_burst

Always eyeball the results: an automated search cannot guarantee a true
bird's-eye angle. Replace any odd one by dropping your own PNG/WebP in
assets/plants/ with the same file name.
"""
import io
import os
import sys
from pathlib import Path

import requests
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_placeholders  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "plants"
CREDITS = ROOT / "CREDITS.md"
UA = {"User-Agent": "florest-dev-fetcher/1.0 (educational Flutter demo)"}
MAX_PX = 1024

# Generic queries from the brief, tried after the plant-specific ones.
GENERIC = [
    "top view plant png transparent",
    "aerial view succulent cutout",
    "top view bush png",
]

QUERIES = {
    "aloe_vera": ["top view aloe png", "aloe vera from above"],
    "pontiatus_evo": ["top view plant png transparent", "potted plant top view"],
    "boxwood_ball": ["top view bush png", "boxwood ball from above"],
    "tillandsia_rosette": ["top view tillandsia png", "tillandsia from above"],
    "dracaena_burst": ["top view dracaena png", "dracaena from above"],
    "echeveria_jade": ["aerial view succulent cutout", "echeveria top view"],
    "agave_blue": ["agave top view", "agave from above"],
    "lavender_dome": ["lavender bush top view"],
    "rosemary_mound": ["rosemary plant top view"],
    "juniper_cushion": ["juniper shrub top view"],
    "sedum_carpet": ["sedum top view"],
    "calathea_orbifolia": ["calathea top view"],
    "haworthia_zebra": ["haworthia top view"],
    "fern_nest": ["bird's nest fern top view"],
    "peperomia_round": ["peperomia top view"],
    "jade_crassula": ["crassula ovata top view"],
}


# ---------------------------------------------------------------- sources

def search_commons(query, limit=8):
    """Wikimedia Commons file search -> [(url, page, licence)]."""
    r = requests.get(
        "https://commons.wikimedia.org/w/api.php",
        params={
            "action": "query", "format": "json", "generator": "search",
            "gsrsearch": f"filetype:bitmap {query}", "gsrnamespace": 6,
            "gsrlimit": limit, "prop": "imageinfo",
            "iiprop": "url|extmetadata|mime", "iiurlwidth": MAX_PX,
        },
        headers=UA, timeout=20,
    )
    r.raise_for_status()
    pages = (r.json().get("query") or {}).get("pages") or {}
    out = []
    for p in sorted(pages.values(), key=lambda p: p.get("index", 99)):
        info = (p.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata") or {}
        lic = (meta.get("LicenseShortName") or {}).get("value", "see source")
        url = info.get("thumburl") or info.get("url")
        if url and info.get("mime") in ("image/png", "image/jpeg", "image/webp"):
            out.append((url, info.get("descriptionurl", url), lic))
    return out


def search_pixabay(query, limit=8):
    key = os.environ.get("PIXABAY_KEY")
    if not key:
        return []
    r = requests.get(
        "https://pixabay.com/api/",
        params={"key": key, "q": query, "image_type": "photo",
                "per_page": limit, "safesearch": "true"},
        headers=UA, timeout=20,
    )
    r.raise_for_status()
    return [(h["largeImageURL"], h["pageURL"], "Pixabay Content License")
            for h in r.json().get("hits", [])]


SOURCES = [search_pixabay, search_commons]


# ---------------------------------------------------------------- processing

def has_transparency(img):
    if img.mode != "RGBA":
        return False
    alpha = img.getchannel("A")
    lo, _ = alpha.getextrema()
    return lo < 10


def remove_background(img):
    try:
        from rembg import remove  # type: ignore
    except ImportError:
        print("    rembg not installed; skipping (pip install rembg)")
        return None
    return remove(img.convert("RGBA"))


def process(raw):
    img = Image.open(io.BytesIO(raw))
    img.load()
    img = img.convert("RGBA")
    if not has_transparency(img):
        img = remove_background(img)
        if img is None or not has_transparency(img):
            return None
    bbox = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    if not bbox:
        return None
    img = img.crop(bbox)
    w, h = img.size
    if min(w, h) < 200 or max(w, h) / min(w, h) > 1.6:
        return None  # too small or not roughly round from above
    img.thumbnail((MAX_PX, MAX_PX), Image.LANCZOS)
    return img


def fetch_one(pid):
    for query in QUERIES.get(pid, []) + GENERIC:
        for source in SOURCES:
            try:
                candidates = source(query)
            except Exception as e:  # network, quota, parsing
                print(f"    {source.__name__} failed: {e}")
                continue
            for url, page, lic in candidates:
                try:
                    raw = requests.get(url, headers=UA, timeout=30).content
                    img = process(raw)
                except Exception as e:
                    print(f"    skip {url}: {e}")
                    continue
                if img is not None:
                    path = OUT / f"{pid}.webp"
                    img.save(path, "WEBP", quality=90, method=6)
                    return page, lic
    return None


def main(argv):
    force = "--force" in argv
    only = argv[argv.index("--only") + 1:] if "--only" in argv else list(QUERIES)
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for pid in only:
        path = OUT / f"{pid}.webp"
        if path.exists() and not force:
            print(f"= {pid}: exists")
            continue
        print(f"> {pid}")
        found = fetch_one(pid)
        if found:
            page, lic = found
            rows.append((pid, page, lic))
            print(f"  ok  {page} ({lic})")
        else:
            gen_placeholders.generate(pid, force=True)
            rows.append((pid, "procedural (tool/gen_placeholders.py)", "Own work, CC0"))
            print("  fallback: procedural placeholder")
    write_credits(rows)


def write_credits(rows):
    existing = {}
    if CREDITS.exists():
        for line in CREDITS.read_text().splitlines():
            if line.startswith("| `"):
                cells = [c.strip() for c in line.strip("|").split("|")]
                existing[cells[0].strip("`")] = (cells[1], cells[2])
    for pid, page, lic in rows:
        existing[pid] = (page, lic)
    lines = [
        "# Image credits", "",
        "Generated by `tool/fetch_images.py`. Every plant image, its source and licence.", "",
        "| File | Source | Licence |", "|---|---|---|",
    ]
    for pid in QUERIES:
        if pid in existing:
            page, lic = existing[pid]
            lines.append(f"| `{pid}` | {page} | {lic} |")
    CREDITS.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1:])

#!/usr/bin/env python3
"""Paints the world map (UI-05) bare: sea and islands only, no frame, no
plaques, no names.

The older painting (assets/art/screens/worldmap.png) has its frame and its
eight place plaques painted in, with the artist's place names on them, so
the screen had to cover each plaque with a live one. The approved panel
sheet (assets/art/reference/panels_sheet.jpg) instead sets the map in a
plain framed window beside a side menu, with small navy plaques floating
over the islands — which needs a map with nothing written on it.

Painted on Cloudflare (an opaque picture, which is all it can make), with
the same account pool as generate_art.py. Each account asked paints one
candidate, saved side by side so the best can be kept:

    python3 content_tools/paint_worldmap.py            # one candidate
    python3 content_tools/paint_worldmap.py --count 2
"""

from __future__ import annotations

import argparse
import os
import sys
import urllib.error
from pathlib import Path

import generate_art as ga

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "backgrounds"

PROMPT = (
    "Painted fantasy game world map seen from high above, in the style of a "
    "premium mobile adventure game: richly painted, warm and saturated, "
    "crisp detail. A deep turquoise and blue sea with soft white surf "
    "around a ring of six green islands spread evenly across the picture: "
    "in the middle a larger island with a golden-roofed fairy-tale castle "
    "town; top left a snowy mountain island; top right a hilly island "
    "with green meadows; right a rocky island with snowy peaks; bottom "
    "left a forested island with a lighthouse; bottom right an island of "
    "ancient stone ruins. Dotted golden paths link the islands to the "
    "castle across small bridges and sandbars. Small sailing boats, a few "
    "seagulls. The water between the islands is open and calm so labels "
    "can float over it. No frame, no border, no compass rose, no "
    "parchment, no plaques, no banners. Absolutely no text, no letters, "
    "no numbers, no labels, no watermark."
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=1)
    args = ap.parse_args()
    path = Path(os.environ.get("RAZINO_CF_ACCOUNTS",
                               Path.home() / ".razino" / "cf_accounts.json"))
    pool = ga.Pool(ga.load_accounts(path))
    made = 0
    while made < args.count:
        acc = pool.take()
        if acc is None:
            print("every account has spent today's allowance")
            break
        try:
            png = ga.request_image(acc, PROMPT, 1280, 720)
        except urllib.error.HTTPError as e:
            if e.code == 429:
                pool.retire(acc, "daily free allowance spent")
                continue
            print(f"{acc['name']}: HTTP {e.code}")
            return 1
        out = OUT / ("worldmap_clean.webp" if made == 0
                     else f"worldmap_clean_{made + 1}.webp")
        ga.to_webp(png, out, 1280, 720)
        print(f"{acc['name']}: {out.relative_to(ROOT)}")
        made += 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

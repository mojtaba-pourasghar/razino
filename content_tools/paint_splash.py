#!/usr/bin/env python3
"""Paints the start screen (UI-01) as separate layers on transparent ground.

The old splash was one flattened picture: a vista with the frame painted into
it and a cast keyed off magenta, which left a white rind round every child.
Here every piece is its own painting with a real alpha channel, so Godot can
place, scale and animate each one on its own:

    splash_bg        the town at golden hour, opaque, nothing in the middle
    splash_cast      Fandogh and the three children, transparent
    splash_emblem    the gold crest the title sits on, transparent
    button_gold      the primary button plate, transparent, nine-patched
    button_navy      the secondary button plate, transparent, nine-patched
    medallion        the round side-action frame, transparent

Raw replies are kept in `--raw` so a piece can be re-cut without paying for
it again. The cut pieces go to assets/art/splash/.

    python3 content_tools/paint_splash.py                 # everything missing
    python3 content_tools/paint_splash.py --only splash_cast --force
    python3 content_tools/paint_splash.py --cut-only      # re-cut from --raw
"""

from __future__ import annotations

import argparse
import io
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

import openai_painter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "splash"
REF = ROOT / "docs" / "reference"

## The look of the approved main-menu sheet: painted 2D key art, warm and
## bright, with gold-and-navy chrome. Said once so every piece shares it.
LOOK = (
    "Premium 2D mobile game art for a children's mystery adventure, the "
    "quality of a top-grossing app store game. Clean confident ink outlines, "
    "rich cel shading with soft painted light, warm golden-hour palette of "
    "gold, deep navy, petrol teal, cream and small ruby and emerald accents."
)
NO_TEXT = ("Absolutely no text, no letters, no numbers, no signage writing, "
           "no watermark, no logo.")
CUTOUT = ("Isolated on a fully transparent background: no ground, no floor "
          "shadow, no backdrop, no frame, no vignette, nothing around it.")

PIECES: dict[str, dict] = {
    "splash_bg": {
        "size": (1536, 1024), "transparent": False, "ext": "webp",
        "refs": ["world-reference-1.webp", "world-reference-3.webp"],
        "prompt": (
            f"{LOOK} A wide landscape background for a game's title screen, "
            "in the spirit of the reference pictures but freshly painted: "
            "the storybook town of Razino at golden hour. Terracotta-roofed "
            "houses climb a green hill on the right towards a tall stone "
            "clock tower with a glowing brass clock face; a calm lake with a "
            "stone arch bridge and a small waterfall on the left; snowy "
            "mountains far behind; a few warm hot-air balloons in a clear "
            "peach-and-blue sky; old oak branches framing the top corners. "
            "COMPOSITION IS CRUCIAL: the upper middle third is open, calm sky "
            "(a title will sit there), and the lower middle is an empty sunlit "
            "grassy clearing where a cobbled path ends (characters will stand "
            "there) — keep both areas free of buildings, people and animals. "
            "The edges are slightly darker and richer than the centre. "
            "No people, no animals, no characters anywhere. " + NO_TEXT),
    },
    "splash_cast": {
        "size": (1536, 1024), "transparent": True,
        "refs": ["char-fandogh-concept.webp", "char-arad.webp",
                 "char-raha.webp", "char-mani.webp"],
        "prompt": (
            f"{LOOK} A group portrait of exactly the four characters shown in "
            "the reference pictures, redrawn in one consistent polished style "
            "and kept recognisable: the clever orange fox detective Fandogh "
            "with his brown deerstalker hat, little cape and magnifying glass "
            "(picture 1); Arad, the cheerful boy with curly dark hair, light "
            "blue hoodie, yellow shirt and denim shorts (picture 2); Raha, "
            "the girl with a brown bob haircut and a pink-purple jacket "
            "(picture 3); Mani, the thoughtful boy with dark hair, round "
            "glasses and an olive shirt (picture 4). They stand side by side "
            "in a friendly heroic line, full body from head to shoes, all "
            "facing the viewer, ready for adventure: Raha on the left holding "
            "a notebook, Arad in the middle with a confident grin, Mani "
            "holding a small brass gadget, and Fandogh in front of them "
            "pointing forward with his magnifying glass. Every shoe and the "
            "fox's tail fully inside the picture, a little space all round. "
            f"{CUTOUT} {NO_TEXT}"),
    },
    "splash_emblem": {
        "size": (1536, 1024), "transparent": True, "refs": [],
        "prompt": (
            f"{LOOK} A game title crest seen flat from the front: at the top "
            "a gold compass-rose medallion with a small brass clock gear and "
            "a magnifying-glass lens; below it a wide ornate title plaque of "
            "polished gold with scrollwork and green leaf sprigs at both "
            "ends, framing a PLAIN, EMPTY deep navy field (a title will be "
            "written there later). Symmetrical, crisp, centered, filling most "
            f"of the width. {CUTOUT} {NO_TEXT}"),
    },
    "button_gold": {
        "size": (1536, 1024), "transparent": True, "refs": [], "height": 104,
        "prompt": (
            f"{LOOK} A single wide game button seen flat from the front, a "
            "long horizontal capsule about five times wider than tall: a "
            "warm amber-gold glossy face with a soft top highlight, framed by "
            "a thin polished gold rim with tiny leaf flourishes at the two "
            "rounded ends. The face is completely plain and empty. "
            f"Symmetrical, centered, filling the width. {CUTOUT} {NO_TEXT}"),
    },
    "button_navy": {
        "size": (1536, 1024), "transparent": True, "refs": [], "height": 104,
        "prompt": (
            f"{LOOK} A single wide game button seen flat from the front, a "
            "long horizontal capsule about five times wider than tall: a "
            "deep navy-blue face with a subtle inner glow, framed by a thin "
            "polished gold rim with tiny leaf flourishes at the two rounded "
            "ends. The face is completely plain and empty. Symmetrical, "
            f"centered, filling the width. {CUTOUT} {NO_TEXT}"),
    },
    "medallion": {
        "size": (1024, 1024), "transparent": True, "refs": [], "height": 160,
        "prompt": (
            f"{LOOK} A single round game medallion button seen flat from the "
            "front: a thick polished gold ring with fine engraved rim and "
            "four tiny leaf accents at top, bottom, left and right, around a "
            "plain empty deep navy disc with a faint inner glow (an icon will "
            "be placed in the middle later). Perfectly circular, centered, "
            f"filling the frame. {CUTOUT} {NO_TEXT}"),
    },
}


def paint(name: str, raw_dir: Path) -> str:
    piece = PIECES[name]
    w, h = piece["size"]
    refs = [REF / r for r in piece["refs"]]
    if refs:
        result = openai_painter.paint_from(piece["prompt"], refs, w, h,
                                           piece["transparent"])
    else:
        result = openai_painter.paint(piece["prompt"], w, h,
                                      piece["transparent"], quality="high")
    if isinstance(result, str):
        return f"{name}: FAILED — {result}"
    (raw_dir / f"{name}.png").write_bytes(result)
    return f"{name}: painted"


def cut(name: str, raw_dir: Path) -> str:
    """Trims a transparent piece to its pixels and saves it; the backdrop is
    only re-encoded at the size the screen uses."""
    src = raw_dir / f"{name}.png"
    if not src.exists():
        return f"{name}: no raw painting"
    im = Image.open(src).convert("RGBA")
    if PIECES[name]["transparent"]:
        alpha = im.getchannel("A")
        # Drop the near-invisible haze some replies leave at the edges, so
        # the trim box is the drawing and not its fog.
        alpha = alpha.point(lambda a: 0 if a < 8 else a)
        im.putalpha(alpha)
        box = alpha.getbbox()
        if box is None:
            return f"{name}: reply was empty"
        pad = 6
        box = (max(0, box[0] - pad), max(0, box[1] - pad),
               min(im.width, box[2] + pad), min(im.height, box[3] + pad))
        im = im.crop(box)
    else:
        im = im.convert("RGB")
    # Plates are nine-patched, and a StyleBoxTexture draws its margins at
    # texture pixels, so a plate is cut at the size it is drawn at.
    height = PIECES[name].get("height")
    if height:
        im = im.resize((round(im.width * height / im.height), height),
                       Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    ext = PIECES[name].get("ext", "png")
    if ext == "webp":
        im.save(OUT / f"{name}.webp", quality=90, method=6)
    else:
        im.save(OUT / f"{name}.png", optimize=True)
    return f"{name}: {im.width}x{im.height}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--cut-only", action="store_true")
    ap.add_argument("--raw", default=str(Path.home() / ".razino" / "raw_splash"))
    args = ap.parse_args()

    raw = Path(args.raw)
    raw.mkdir(parents=True, exist_ok=True)
    names = args.only or list(PIECES)

    if not args.cut_only:
        todo = [n for n in names if args.force or not (raw / f"{n}.png").exists()]
        with ThreadPoolExecutor(max_workers=6) as pool:
            for line in pool.map(lambda n: paint(n, raw), todo):
                print(line, flush=True)
    for n in names:
        print(cut(n, raw))
    return 0


if __name__ == "__main__":
    sys.exit(main())

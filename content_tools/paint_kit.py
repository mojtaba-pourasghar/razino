#!/usr/bin/env python3
"""Paints the interface kit — panels, cards, slots, tabs, pills, medallions —
on transparent ground, in the look of the start screen's capsule buttons.

Every screen draws its surfaces through UiBox, and UiBox wears a kit piece
wherever one exists (scripts/ui/ui_box.gd). So this one run reskins every
panel in the game at once; nothing per screen.

Each piece is painted large, then:

  mirrored   one half (or quadrant) is reflected onto the other, so the
             corners match exactly and the piece nine-patches cleanly. A
             model never paints four identical corners.
  cut        trimmed to its pixels and scaled to the size it is drawn at,
             because a StyleBoxTexture draws its margins at texture pixels.

and its nine-patch margin is written to assets/art/kit/nine_patch.json.

    python3 content_tools/paint_kit.py                  # everything missing
    python3 content_tools/paint_kit.py --only panel --force
    python3 content_tools/paint_kit.py --cut-only
"""

from __future__ import annotations

import argparse
import json
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

import openai_painter
from paint_splash import CUTOUT, LOOK, NO_TEXT

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "kit"

## The family resemblance: what the start screen's buttons look like, said
## once so every piece is visibly their sibling.
FAMILY = (
    "Refined jewellery-like game interface piece: a FINE, thin polished-gold "
    "rim with a hairline dark outer edge, deep navy-blue glassy surfaces "
    "with a faint soft sheen, small delicate gold filigree curls with tiny "
    "leaves only where stated. Elegant and light, nothing chunky or heavy."
)

## The frames of the approved panel sheet: matte, not glossy. The chrome
## round every window there is a thin double rim of muted steel-blue metal
## with small dark curled scroll brackets at the corners, on a deep navy
## face with a fine grain — quieter than the buttons, so the buttons and the
## art inside a panel are what the eye goes to.
FRAME = (
    "Refined fantasy RPG interface frame in the style of a premium mobile "
    "adventure game: a MATTE deep navy face (#0E1A33) with a very fine "
    "subtle grain texture, NOT glossy; a thin double rim of muted "
    "steel-blue and pewter metal with a faint gold glint; at each corner a "
    "small dark-metal curled scroll bracket that sits on the rim. The face "
    "is fully OPAQUE everywhere, solid colour right across its middle."
)

## name: size asked for, symmetry ("h", "hv" or ""), cut size (w, h) and
## nine-patch margin at that size (0 = not a nine-patch), prompt.
PIECES: dict[str, dict] = {
    "panel": {
        "ask": (1024, 1024), "mirror": "hv", "cut": (256, 256), "margin": 56,
        "prompt": (
            f"{LOOK} {FRAME} One large square window panel seen flat from "
            "the front, filling the whole picture: the matte grained navy "
            "face with barely rounded corners, framed by the thin double "
            "steel-blue rim, with the small curled scroll bracket at each of "
            "the four corners. The long straight edges between the corners are perfectly "
            "plain and uniform, and the face is completely empty. "
            f"{CUTOUT} {NO_TEXT}"),
    },
    "parchment": {
        "ask": (1024, 1024), "mirror": "hv", "cut": (256, 256), "margin": 52,
        "prompt": (
            f"{LOOK} {FRAME} One large square card seen flat from the "
            "front, filling the whole picture: a warm cream parchment face "
            "with a very faint paper texture, slightly warmer at the edges, "
            "with gently rounded corners, framed by a thin dark bronze rim; "
            "at each of the four corners a small curled bronze bracket. The "
            "straight edges between the corners are perfectly plain and "
            f"uniform, and the face is completely empty. {CUTOUT} {NO_TEXT}"),
    },
    "slot": {
        "ask": (1024, 1024), "mirror": "hv", "cut": (128, 128), "margin": 26,
        "prompt": (
            f"{LOOK} {FRAME} One square inventory slot seen flat from the "
            "front, filling the whole picture: a recessed very dark navy "
            "well with a soft inner shadow and barely rounded corners, framed "
            "by a thin steel-blue rim with a tiny rivet at each corner. Completely "
            f"empty inside. {CUTOUT} {NO_TEXT}"),
    },
    "button_dark": {
        "ask": (1536, 1024), "mirror": "h", "cut": (0, 56), "margin": 40,
        "prompt": (
            f"{LOOK} {FAMILY} One slim game button seen flat from the front: "
            "a horizontal capsule about four times wider than tall with "
            "fully rounded ends, a deep navy glassy face with a faint sheen "
            "along its upper half, a fine gold rim and a tiny gold curl at "
            f"each end. Empty face, centered, filling the width. {CUTOUT} "
            f"{NO_TEXT}"),
    },
    "button_gold": {
        "ask": (1536, 1024), "mirror": "h", "cut": (0, 56), "margin": 40,
        "prompt": (
            f"{LOOK} {FAMILY} One slim game button seen flat from the front: "
            "a horizontal capsule about four times wider than tall with "
            "fully rounded ends, a warm glossy amber-gold face lighter in "
            "the middle with a glassy highlight along its upper half, a fine "
            "bright gold rim and a tiny gold curl at each end. Empty face, "
            f"centered, filling the width. {CUTOUT} {NO_TEXT}"),
    },
    "tab_active": {
        "ask": (1536, 1024), "mirror": "h", "cut": (0, 44), "margin": 22,
        "prompt": (
            f"{LOOK} {FAMILY} One small selected-tab plate seen flat from "
            "the front: a horizontal rounded rectangle about three times "
            "wider than tall, with a warm soft amber-gold glowing face and a "
            "fine bright gold rim, no ornaments. Empty face, centered, "
            f"filling the width. {CUTOUT} {NO_TEXT}"),
    },
    "pill": {
        "ask": (1536, 1024), "mirror": "h", "cut": (0, 44), "margin": 22,
        "prompt": (
            f"{LOOK} {FRAME} One small counter pill seen flat from the "
            "front, like the coin counter in a game's top bar: a horizontal "
            "capsule about three times wider than tall, a very dark navy "
            "face and a thin steel-blue rim, no ornaments. "
            f"Empty face, centered, filling the width. {CUTOUT} {NO_TEXT}"),
    },
    "medallion": {
        "ask": (1024, 1024), "mirror": "hv", "cut": (128, 128), "margin": 0,
        "prompt": (
            f"{LOOK} {FRAME} One round icon button seen flat from the "
            "front, filling the picture: a thin polished gold ring with a "
            "fine steel-blue inner line, around a deep navy disc with a soft "
            "matte sheen across its upper half. "
            f"Empty in the middle. Perfectly circular. {CUTOUT} {NO_TEXT}"),
    },
}


def paint(name: str, raw: Path) -> str:
    p = PIECES[name]
    w, h = p["ask"]
    result = openai_painter.paint(p["prompt"], w, h, True, quality="high")
    if isinstance(result, str):
        return f"{name}: FAILED — {result}"
    (raw / f"{name}.png").write_bytes(result)
    return f"{name}: painted"


def mirror(im: Image.Image, axes: str) -> Image.Image:
    """Reflects the left half onto the right ('h'), and the top half onto
    the bottom ('v'), so opposite corners are the same pixels."""
    w, h = im.size
    if "h" in axes:
        left = im.crop((0, 0, w // 2, h))
        im.paste(left.transpose(Image.FLIP_LEFT_RIGHT), (w - w // 2, 0))
    if "v" in axes:
        top = im.crop((0, 0, w, h // 2))
        im.paste(top.transpose(Image.FLIP_TOP_BOTTOM), (0, h - h // 2))
    return im


def cut(name: str, raw: Path) -> str:
    src = raw / f"{name}.png"
    if not src.exists():
        return f"{name}: no raw painting"
    p = PIECES[name]
    im = Image.open(src).convert("RGBA")
    alpha = im.getchannel("A").point(lambda a: 0 if a < 8 else a)
    im.putalpha(alpha)
    box = alpha.getbbox()
    if box is None:
        return f"{name}: reply was empty"
    im = im.crop(box)
    # Centre on the trimmed box before mirroring, so the reflection axis is
    # the middle of the piece, not of the canvas it was painted on.
    im = mirror(im, p["mirror"])
    cw, ch = p["cut"]
    if cw == 0:
        cw = round(im.width * ch / im.height)
    im = im.resize((cw, ch), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    im.save(OUT / f"{name}.png", optimize=True)
    return f"{name}: {cw}x{ch}"


def write_manifest() -> None:
    margins_path = OUT / "nine_patch.json"
    margins = json.loads(margins_path.read_text()) if margins_path.exists() else {}
    for name, p in PIECES.items():
        if p["margin"] and (OUT / f"{name}.png").exists():
            margins[name] = p["margin"]
    margins_path.write_text(json.dumps(margins, indent=2) + "\n")
    # The new pieces are painted in their final colours; no correction.
    tints_path = OUT / "tint.json"
    tints = json.loads(tints_path.read_text()) if tints_path.exists() else {}
    for name in PIECES:
        tints.pop(name, None)
    tints_path.write_text(json.dumps(tints, indent=2) + "\n")
    kit_path = OUT / "kit.json"
    kit = json.loads(kit_path.read_text()) if kit_path.exists() else {"pieces": []}
    kit["pieces"] = sorted(set(kit["pieces"]) | {
        n for n in PIECES if (OUT / f"{n}.png").exists()})
    kit_path.write_text(json.dumps(kit, indent=2) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--cut-only", action="store_true")
    ap.add_argument("--raw", default=str(Path.home() / ".razino" / "raw_kit"))
    args = ap.parse_args()
    raw = Path(args.raw)
    raw.mkdir(parents=True, exist_ok=True)
    names = [n for n in (args.only or PIECES) if n in PIECES]
    if not args.cut_only:
        todo = [n for n in names if args.force or not (raw / f"{n}.png").exists()]
        with ThreadPoolExecutor(max_workers=8) as pool:
            for line in pool.map(lambda n: paint(n, raw), todo):
                print(line, flush=True)
    for n in names:
        print(cut(n, raw))
    write_manifest()
    return 0


if __name__ == "__main__":
    sys.exit(main())

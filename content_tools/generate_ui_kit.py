#!/usr/bin/env python3
"""Paints the interface kit: corner ornaments, button faces and icons.

The hard lesson this tool is built around: an image model will not leave the
middle of a picture empty. Asked for a panel with "ornament ONLY at the four
corners and a perfectly plain centre" it returns a beautiful frame with
ornament down every edge and a medallion in the middle — four of those are
in the repository's history, and a button whose middle is a medallion cannot
stretch to any width, which is the one thing a button must do.

So this stops asking. The model paints only the pieces it is good at:

  · ONE corner ornament. The other three are mirrored from it in code, which
    also guarantees they match — a model asked for four corners draws four
    different ones.
  · A button FACE: a flat, even gradient with no ornament anywhere. Uniform
    by definition, so it tiles and stretches.
  · Icons, which never stretch, so its instinct to decorate costs nothing.

Everything that has to stretch is assembled from those in `nine_patch.json`
and drawn by the engine.

    python3 content_tools/generate_ui_kit.py --dry-run
    python3 content_tools/generate_ui_kit.py --limit 12

Resumable: every piece already on disk is skipped, so a run cut short by the
daily allowance loses nothing. Run it again tomorrow.
"""

from __future__ import annotations

import argparse
import io
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image, ImageFilter  # noqa: E402

from generate_ui_art import (  # noqa: E402
    ACCOUNTS_DEFAULT, Pool, load_accounts, paint, trim,
)

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "kit"

## The palette, from docs/DESIGN.md, repeated in the prompt because the model
## has no other way of knowing it.
COLOURS = (
    "Colours: dark navy #02182A, a lighter navy #052942, a thin steel-blue "
    "#2E6E96 edge, bright gold #EEB43E and deep gold #A46C23."
)

## What every piece must obey. Magenta rather than a transparent background
## because the model has no alpha channel at all; the key is lifted
## afterwards.
RULES = (
    "Flat front-facing 2D game interface art for a children's fantasy "
    "adventure game. Straight-on flat view, no perspective, no drop shadow, "
    "no scene, no background objects. The background behind the asset is ONE "
    "FLAT SOLID MAGENTA colour, edge to edge. "
    "Absolutely no text, no letters, no numbers, no signature, no watermark."
)

## (name, width, height, what, how to cut it out)
##
## `corner` pieces are trimmed to the ornament and mirrored into four.
## `face` pieces are kept whole and must be uniform.
PIECES: list[tuple[str, int, int, str, str]] = [
    ("corner_gold", 512, 512,
     "ONE ornate gold corner bracket for a panel frame, shaped like the "
     "top-left corner of a picture frame: two short arms meeting at a right "
     "angle, with a small scroll and a gem where they meet. The arms stop "
     "after a short run and do not continue. Placed in the TOP-LEFT of the "
     "picture with the rest of the picture flat magenta. " + COLOURS,
     "corner"),
    ("corner_steel", 512, 512,
     "ONE small steel-blue corner bracket for a panel frame: two short plain "
     "arms meeting at a right angle, no ornament, no gem. Placed in the "
     "TOP-LEFT of the picture with the rest of the picture flat magenta. "
     + COLOURS,
     "corner"),
    ("face_gold", 768, 256,
     "A completely plain horizontal bar filled with a smooth vertical gold "
     "gradient, bright gold #F3C34F along the top edge fading to deep gold "
     "#D68A1C along the bottom, with a soft lighter sheen across the upper "
     "third. Absolutely nothing on it: no border, no ornament, no shapes, "
     "no highlights other than the sheen. It fills the whole picture edge "
     "to edge.",
     "face"),
    ("face_navy", 768, 256,
     "A completely plain horizontal bar filled with a smooth vertical navy "
     "gradient, #0A3A5C along the top edge fading to #02182A along the "
     "bottom. Absolutely nothing on it: no border, no ornament, no shapes. "
     "It fills the whole picture edge to edge.",
     "face"),
    ("face_parchment", 768, 256,
     "A completely plain horizontal bar of warm cream parchment #F6E3C5 with "
     "a faint paper grain. Absolutely nothing on it: no border, no ornament, "
     "no shapes, no edges, no text. It fills the whole picture edge to edge.",
     "face"),
]

## The thirty-six glyphs the game asks GameIcons for. Painted as plain white
## silhouettes so the engine can tint them; an icon that arrives already
## gold cannot be shown in red on a warning.
ICONS: dict[str, str] = {
    "arrow_up": "an upward arrow", "backpack": "a school backpack",
    "bell": "a hand bell", "book": "an open book", "box": "a treasure chest",
    "chat": "a speech bubble", "check": "a tick mark",
    "clock": "a round clock face", "coin": "a round coin",
    "compass": "a compass rose", "dot": "a filled circle",
    "download": "a downward arrow into a tray", "drop": "a water droplet",
    "friend": "a person's head and shoulders", "gear": "a cog wheel",
    "gem": "a cut gemstone", "globe": "a globe with meridians",
    "heart": "a heart", "home": "a house", "key": "an old key",
    "lamp": "a hanging lantern", "lock": "a closed padlock",
    "magnifier": "a magnifying glass", "map": "a folded map",
    "music": "a musical note", "pencil": "a pencil",
    "play": "a right-pointing triangle", "rope": "a coil of rope",
    "shield": "a shield", "speaker": "a loudspeaker", "star": "a five-pointed star",
    "step": "three rising steps", "sun": "a sun with rays",
    "tower": "a clock tower", "tree": "a leafy tree", "trophy": "a trophy cup",
}

ICON_RULES = (
    "A single flat icon glyph in PURE WHITE on a flat solid magenta "
    "background. Simple bold silhouette, thick strokes, rounded ends, no "
    "outline, no frame, no circle behind it, no gradient, no shading, no "
    "colour other than white. Centred, filling most of the picture. "
    "Absolutely no text, no letters, no numbers."
)
ICON_SIZE = 512


def key_magenta(img: Image.Image) -> Image.Image:
    """Lifts the flat magenta backdrop, leaving the piece on transparency.

    By hue rather than by distance from a sample: the model paints the field
    as a vignette, and a distance test keeps the dark corners of it. Nothing
    in this kit is magenta, so the hue test is safe everywhere.
    """
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, _ = px[x, y]
            if r > 60 and b > 45 and g < min(r, b) * 0.74:
                px[x, y] = (r, g, b, 0)
    return img


def four_corners(corner: Image.Image, side: int) -> Image.Image:
    """Builds a square from one corner ornament, mirrored into four.

    Mirroring rather than painting four is what makes them match. A model
    asked for four corners draws four different ones, and the eye catches
    that immediately on a panel.
    """
    c = trim(corner).convert("RGBA")
    box = side // 2
    c.thumbnail((box, box), Image.LANCZOS)
    sheet = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sheet.paste(c, (0, 0), c)
    tr = c.transpose(Image.FLIP_LEFT_RIGHT)
    sheet.paste(tr, (side - tr.width, 0), tr)
    bl = c.transpose(Image.FLIP_TOP_BOTTOM)
    sheet.paste(bl, (0, side - bl.height), bl)
    br = c.transpose(Image.ROTATE_180)
    sheet.paste(br, (side - br.width, side - br.height), br)
    return sheet


def whiten(img: Image.Image) -> Image.Image:
    """Flattens an icon to one white silhouette with a clean alpha edge.

    The model shades even when told not to, so the colour is thrown away and
    only the shape is kept: anything that is not backdrop becomes white, and
    its own brightness becomes the alpha. That also removes the grey halo a
    straight key leaves around a soft edge.
    """
    img = key_magenta(img)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lightness = (r + g + b) / 3.0
            px[x, y] = (255, 255, 255, int(min(255, lightness * 1.35)))
    return trim(img)


def jobs(only: str) -> list[tuple]:
    out: list[tuple] = []
    for name, w, h, what, kind in PIECES:
        out.append((name, w, h, f"{RULES} {what}", kind))
    for name, what in ICONS.items():
        out.append((f"icon_{name}", ICON_SIZE, ICON_SIZE,
                    f"{ICON_RULES} The icon is {what}.", "icon"))
    if only:
        out = [j for j in out if only in j[0]]
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--accounts", default=str(ACCOUNTS_DEFAULT))
    ap.add_argument("--only", default="", help="only names containing this text")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    todo = jobs(args.only)

    if args.dry_run:
        for name, w, h, prompt, kind in todo:
            print(f"--- {name} ({kind}, {w}x{h})\n{prompt}\n")
        return 0

    pool = Pool(load_accounts(Path(args.accounts)))
    made = 0
    skipped = 0
    for name, w, h, prompt, kind in todo:
        dest = OUT / f"{name}.png"
        if dest.exists() and not args.force:
            skipped += 1
            continue
        if args.limit and made >= args.limit:
            print(f"  … stopping at {args.limit}")
            break
        result = paint(pool, prompt, w, h, style="")
        if isinstance(result, str):
            print(f"  ! {name}: {result}", flush=True)
            if result == "quota":
                print("    the day's allowance is spent — run again tomorrow")
                break
            continue

        img = Image.open(io.BytesIO(result))
        if kind == "icon":
            whiten(img).save(dest)
        elif kind == "corner":
            four_corners(key_magenta(img), 512).save(dest)
        else:
            # A face must stay rectangular and uniform: nothing is keyed or
            # trimmed, only softened so the gradient has no banding.
            img.convert("RGB").filter(ImageFilter.GaussianBlur(0.6)).save(dest)
        made += 1
        print(f"  ✓ {name}", flush=True)

    print(f"\n{made} painted, {skipped} already there, {len(todo)} in the kit")
    _write_manifest()
    return 0


def _write_manifest() -> None:
    """Records which pieces exist, so the engine can use what has arrived and
    keep drawing the rest."""
    have = sorted(p.stem for p in OUT.glob("*.png"))
    (OUT / "kit.json").write_text(
        json.dumps({"pieces": have}, indent=2) + "\n", encoding="utf-8")
    print(f"kit.json: {len(have)} pieces on disk")


if __name__ == "__main__":
    raise SystemExit(main())

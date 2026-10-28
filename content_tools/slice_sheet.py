"""Cuts the approved mockup sheet into the kit pieces the engine asks for.

The sheet is a painting of nine screens, not an asset library, and the two
want opposite things. A painting is whole; a kit piece has to stretch to
whatever size a screen gives it. So only the parts that are *uniform or
cornered* are taken from it — panel, button, slot, tab, face — and each is
rescaled before its nine-patch margin is measured.

That rescale is the whole trick. A nine-patch corner draws at its SOURCE
size, so a button cut 32px tall and shown 56px tall would have a corner
nearly twice the button. Every piece here is scaled to roughly twice the
height it is drawn at, and the margin is given in those scaled pixels.

What is deliberately NOT cut: the paintings (castle, island, forest, lake),
the item icons and the portraits. They sit at 40-600px on the sheet and the
game needs 128-2048px; upscaling them would make the one part the player
actually looks at the blurriest thing on screen. Those are repainted at
full size instead.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
KIT = ROOT / "assets" / "art" / "kit"
SHEET = ROOT / "assets" / "art" / "reference" / "kit_sheet.webp"

# Where each screen sits on the 1536x1024 sheet, measured by locating the
# board-coloured gutters between the panels rather than by eye.
PANELS: dict[str, tuple[int, int, int, int]] = {
    "main": (65, 47, 665, 340),
    "world_map": (693, 47, 1471, 340),
    "explore": (66, 366, 537, 615),
    "dialogue": (562, 366, 987, 615),
    "inventory": (1012, 366, 1470, 615),
    "profile": (65, 643, 537, 927),
    "quests": (561, 643, 874, 927),
    "settings": (897, 643, 1098, 927),
    "loading": (1121, 643, 1471, 927),
}

# name -> (panel, box within that panel, target height, nine-patch margin
# in target pixels). A margin of 0 means the piece is stretched whole and
# never nine-patched, which is only safe when it is uniform.
PIECES: dict[str, tuple[str, tuple[int, int, int, int], int, int]] = {
    "panel": ("profile", (0, 0, 472, 284), 710, 70),  # stripped below
    "button_gold": ("world_map", (11, 39, 119, 71), 112, 34),
    "button_dark": ("world_map", (12, 74, 120, 104), 112, 33),
    "slot": ("profile", (215, 107, 261, 153), 128, 20),
    "tab_active": ("inventory", (94, 7, 157, 32), 80, 25),
    "face_navy": ("world_map", (20, 190, 110, 250), 171, 0),
    "disc": ("profile", (38, 15, 182, 135), 256, 0),
}


# A bare frame has to be built, because the sheet has no empty panel on it:
# every screen it paints is full of its own content. A nine-patch stretches
# both its centre AND its edge bands, so anything left in either smears --
# the portrait and bars in the source would become navy streaks a thousand
# pixels wide.
#
# Only two things are kept: the bevel running along each edge, and the four
# corner ornaments. Everything else is replaced with the flat face. Both
# measurements are in target pixels and the corner must fit inside the
# nine-patch margin, or the ornament is cut in half when it draws.
#
# name -> (bevel thickness, corner ornament side)
STRIP: dict[str, tuple[int, int]] = {"panel": (25, 58)}


def strip_interior(img: Image.Image, face: Image.Image, bevel: int,
                   corner: int) -> Image.Image:
    w, h = img.size
    keep = Image.new("L", (w, h), 0)
    mark = ImageDraw.Draw(keep)
    mark.rectangle((0, 0, w - 1, bevel - 1), fill=255)
    mark.rectangle((0, h - bevel, w - 1, h - 1), fill=255)
    mark.rectangle((0, 0, bevel - 1, h - 1), fill=255)
    mark.rectangle((w - bevel, 0, w - 1, h - 1), fill=255)
    mark.rectangle((0, 0, corner - 1, corner - 1), fill=255)
    bare = Image.composite(img, face.resize((w, h), Image.LANCZOS), keep)
    return mirror_quadrant(bare)


def mirror_quadrant(img: Image.Image) -> Image.Image:
    """Builds the frame from its top-left quarter alone.

    The sheet gives one clean corner per panel at best -- the profile panel
    carries its reward diamonds along the bottom bevel and its tab along the
    top. Mirroring one good quarter into four sidesteps that, and it is also
    what makes the four corners match: four separately painted corners never
    quite do, and the eye catches it at once.
    """
    w, h = img.size
    qw, qh = (w + 1) // 2, (h + 1) // 2
    q = img.crop((0, 0, qw, qh))
    out = Image.new(img.mode, (w, h))
    out.paste(q, (0, 0))
    out.paste(q.transpose(Image.FLIP_LEFT_RIGHT), (w - qw, 0))
    out.paste(q.transpose(Image.FLIP_TOP_BOTTOM), (0, h - qh))
    out.paste(q.transpose(Image.ROTATE_180), (w - qw, h - qh))
    return out


def cut(sheet: Image.Image, name: str) -> tuple[Image.Image, int]:
    panel, box, target_h, margin = PIECES[name]
    px0, py0, _, _ = PANELS[panel]
    x0, y0, x1, y1 = box
    crop = sheet.crop((px0 + x0, py0 + y0, px0 + x1, py0 + y1))
    scale = target_h / crop.height
    size = (max(1, round(crop.width * scale)), target_h)
    out = crop.resize(size, Image.LANCZOS)
    if name in STRIP:
        bevel, corner = STRIP[name]
        out = strip_interior(out, cut(sheet, "face_navy")[0], bevel, corner)
    return out, margin


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("sheet", type=Path, nargs="?", default=SHEET,
                    help="the approved sheet, unlabelled")
    ap.add_argument("--out", type=Path, default=KIT)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not args.sheet.is_file():
        print(f"no sheet at {args.sheet}")
        return 1

    sheet = Image.open(args.sheet).convert("RGBA")
    if sheet.size != (1536, 1024):
        print(f"expected a 1536x1024 sheet, got {sheet.size}")
        return 1

    args.out.mkdir(parents=True, exist_ok=True)
    margins: dict[str, int] = {}
    for name in PIECES:
        img, margin = cut(sheet, name)
        if margin:
            margins[name] = margin
        print(f"{name:14s} {img.size[0]:4d}x{img.size[1]:<4d} margin {margin}")
        if not args.dry_run:
            img.save(args.out / f"{name}.png")

    if args.dry_run:
        return 0

    (args.out / "nine_patch.json").write_text(
        json.dumps(margins, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    # The sheet is already the approved colour, so nothing needs correcting.
    # Leaving the old corrections in place would darken these pieces wrongly.
    (args.out / "tint.json").write_text("{}\n", encoding="utf-8")
    (args.out / "kit.json").write_text(
        json.dumps({"pieces": sorted(PIECES)}, indent=2) + "\n", encoding="utf-8")
    print(f"\n{len(PIECES)} pieces written to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Removes the fake signatures image models paint into a corner.

Every one of these models has seen a few million signed paintings, so it
signs ours too — an illegible scrawl of Latin letters in a bottom corner. In
a Persian game that reads to a child as a mistake, and it is the one kind of
"text" the no-text clause in the prompt never catches, because the model
does not think of a signature as text.

    python3 content_tools/depaint.py --corner bottom_left \\
        assets/art/backgrounds/ui_splash.webp

The patch is a mirrored copy of the clean strip beside the mark, feathered
at the seam. On the dark foliage and sky these corners usually hold, a
mirrored neighbour is indistinguishable; it is not a general inpainter and
does not pretend to be.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent

## Where these models sign, as fractions of the image. All four corners,
## because which one it picks is not predictable.
CORNERS = {
    "bottom_left": (0.00, 0.86, 0.22, 1.00),
    "bottom_right": (0.78, 0.86, 1.00, 1.00),
    "top_left": (0.00, 0.00, 0.22, 0.14),
    "top_right": (0.78, 0.00, 1.00, 0.14),
}


## No automatic detection. Two attempts are not in this file: one compared
## each corner against its own median with a fixed margin and missed a pale
## scrawl on near-black foliage; the next scaled the margin to the corner's
## range and then fired on all four corners of all four paintings, which is
## worse — it would quietly smear real art. A corner is named by a person
## who looked at the picture, and this tool only does the patching.

def patch(img: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    """Covers a box with a mirrored copy of the strip next to it."""
    x0, y0, x1, y1 = box
    w = x1 - x0
    left_half = x0 < img.width // 2
    # Take the neighbour from further into the picture, where the model had
    # no reason to sign.
    sx0 = x1 if left_half else x0 - w
    sx1 = sx0 + w
    sx0 = max(0, min(sx0, img.width - w))
    sx1 = sx0 + w

    donor = img.crop((sx0, y0, sx1, y1)).transpose(Image.FLIP_LEFT_RIGHT)
    donor = donor.filter(ImageFilter.GaussianBlur(1.2))

    # A soft-edged mask: solid in the middle, fading to nothing at the
    # edges. Blurring a mask that is white edge to edge does nothing at all
    # — it is already uniform — and the first version did exactly that and
    # left a hard horizontal seam where the patch began.
    h = y1 - y0
    feather = max(3, int(min(w, h) * 0.12))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rectangle(
        (feather, feather, w - feather, h - feather), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(feather * 0.55))
    out = img.copy()
    out.paste(donor, (x0, y0), mask)
    return out


def clean(path: Path, corners: list[str], boxes: list[str]) -> list[str]:
    img = Image.open(path)
    fmt = img.format
    img = img.convert("RGBA" if img.mode == "RGBA" else "RGB")
    done: list[str] = []
    for name in corners:
        f = CORNERS[name]
        img = patch(img, (int(img.width * f[0]), int(img.height * f[1]),
                          int(img.width * f[2]), int(img.height * f[3])))
        done.append(name)
    for raw in boxes:
        # An exact box, for a mark a corner preset does not sit over. The
        # feathered mask fades at its edges, so the box has to be drawn
        # generously around the mark rather than tight to it.
        x0, y0, x1, y1 = (int(v) for v in raw.split(","))
        img = patch(img, (x0, y0, x1, y1))
        done.append(raw)
    img.save(path, format=fmt, quality=95)
    return done


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="+", help="image files")
    ap.add_argument("--corner", action="append", default=[],
                    choices=sorted(CORNERS),
                    help="which corner to patch; repeat for several")
    ap.add_argument("--box", action="append", default=[],
                    help="an exact region as x0,y0,x1,y1 in pixels")
    args = ap.parse_args()
    if not args.corner and not args.box:
        raise SystemExit("name at least one --corner or --box")

    cleaned = 0
    for p in args.paths:
        f = Path(p)
        if not f.exists():
            print(f"  ! {f}: not found")
            continue
        print(f"  ✓ {f.name}: {', '.join(clean(f, args.corner, args.box))}")
        cleaned += 1
    print(f"{cleaned} patched")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

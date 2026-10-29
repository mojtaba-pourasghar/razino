"""Turns a daylight painting into a night one.

The approved direction is a night town, and the start screen's backdrop was
painted in broad daylight. Repainting it needs image credit that is not
there, and a flat darkening does not read as night -- it reads as the same
picture with the lights off, because a bright blue sky stays a bright blue
sky however far it is turned down.

What actually separates night from a dim day is that the two ends of the
picture move in opposite directions: everything lit by the sky goes cool
and much darker, while anything lit by a flame stays warm and barely
dims. So each pixel is graded by how warm it already is, and lanterns,
windows and firelight keep their colour while the sky and the stone fall
away behind them.
"""

from __future__ import annotations

import argparse
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

## What the sky-lit part of the picture is multiplied by.
##
## These are low on purpose. A first pass used roughly twice these values
## and the result was not night but vivid blue daylight: the sky in the
## source is close to white, so a gentle cool multiply leaves it bright and
## merely saturates it. Night needs the exposure down as well as the colour
## moved, and the blue channel stays well ahead of the other two so what is
## left still reads as moonlight rather than as grey.
COOL = (0.16, 0.21, 0.40)
## Warm hues in degrees: firelight, lamplight, lit windows.
WARM = (8.0, 62.0)
## How much of its own colour a fully warm, fully lit pixel keeps.
KEEP = 0.92


def grade(img: Image.Image, strength: float = 1.0) -> Image.Image:
    """`strength` below 1 holds the picture back from the full night.

    A character standing in front of the scene is lit by it but has to stay
    readable, so the cast is graded part of the way and the backdrop all of
    it. Graded equally the figures sink into the wall behind them.
    """
    cool = tuple(1.0 + (c - 1.0) * strength for c in COOL)
    has_alpha = img.mode in ("RGBA", "LA") or "transparency" in img.info
    alpha = img.convert("RGBA").getchannel("A") if has_alpha else None
    img = img.convert("RGB")
    out = []
    for r, g, b in img.getdata():
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        hd = h * 360.0
        warm = 0.0
        if s > 0.18 and WARM[0] <= hd <= WARM[1]:
            # Only the bright warm pixels are a light source; a warm roof
            # tile in shadow is just a roof tile and should go dark.
            warm = min(1.0, s * 1.4) * min(1.0, max(0.0, (l - 0.28) / 0.45))
        hold = warm * KEEP
        out.append(tuple(
            round(c * (hold + (1.0 - hold) * cool[i]))
            for i, c in enumerate((r, g, b))))
    done = Image.new("RGB", img.size)
    done.putdata(out)
    if alpha is not None:
        done = done.convert("RGBA")
        done.putalpha(alpha)
    return done


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--strength", type=float, default=1.0)
    args = ap.parse_args()
    if not args.source.is_file():
        print(f"no picture at {args.source}")
        return 1
    img = grade(Image.open(args.source), args.strength)
    if args.out.suffix.lower() == ".png":
        img.save(args.out)
    else:
        img.save(args.out, quality=92, method=6)
    print(f"{args.source.name} -> {args.out.name}  {img.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

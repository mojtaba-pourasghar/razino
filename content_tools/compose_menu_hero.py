#!/usr/bin/env python3
"""Swaps the fox on the start screen's hero painting for the dino.

Fandogh became the Dino of the approved character sheet after the start
screen's hero piece had been painted with him as a fox, and no image
credit was left to repaint it. This takes the fox out of the painting and
stands the sheet's Dino (assets/art/cast/fandogh_sheet.png) where it sat.

The fox is removed by area, read off the painting itself: everything to the
right of the boy above the rock, and a thin strip of the fox's cape that
showed between his boot and the fox (there, only the cape's red, so the
leather of the boot stays). The ground under the fox was never painted, so
it is rebuilt from the same rock's surface further left.

When image credit is back, `paint_splash.py --only menu_hero --force`
paints the piece with the dino from the start (its prompt already asks for
him) and this is no longer needed.

    python3 content_tools/compose_menu_hero.py IN.png OUT.png
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DINO = ROOT / "assets" / "art" / "cast" / "fandogh_sheet.png"

## Where the dino stands, in the painting's pixels (912 x 1265): the middle
## of his feet, and his height.
FEET = (735, 958)
HEIGHT = 360


def compose(src: Path, out: Path) -> None:
    orig = np.array(Image.open(src).convert("RGBA")).astype(np.int32)
    a = orig.copy()
    h, w = a.shape[:2]
    r, g = a[..., 0], a[..., 1]
    yy, xx = np.mgrid[0:h, 0:w]

    fox = ((yy >= 585) & (yy < 810) & (xx >= 595)) \
        | ((yy >= 810) & (yy < 930) & (xx >= 628))
    cape = ((yy >= 808) & (yy < 884) & (xx >= 568) & (xx < 628)) \
        | ((yy >= 884) & (yy < 948) & (xx >= 624) & (xx < 628)) \
        | ((yy >= 884) & (yy < 902) & (xx >= 568) & (xx < 628) & (r > 1.7 * g))
    ground = (yy >= 928) & (yy < 975) & (xx >= 623) & (xx < 875) & (orig[..., 3] > 0)

    a[..., 3] = np.where(fox | cape, 0, a[..., 3])
    rock = a[np.clip(yy + 40, 0, h - 1), np.clip(xx - 330, 0, w - 1)]
    a = np.where(ground[..., None], rock, a)
    img = Image.fromarray(a.astype(np.uint8))

    # Flipped so he looks the same way as the boy, towards the castle.
    dino = Image.open(DINO).convert("RGBA").transpose(Image.FLIP_LEFT_RIGHT)
    dw = round(dino.width * HEIGHT / dino.height)
    dino = dino.resize((dw, HEIGHT), Image.LANCZOS)
    img.alpha_composite(dino, (FEET[0] - dw // 2, FEET[1] - HEIGHT))
    img.save(out, optimize=True)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    compose(Path(sys.argv[1]), Path(sys.argv[2]))

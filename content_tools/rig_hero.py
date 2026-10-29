"""Cuts the hero into the parts a walk cycle needs, and records the joints.

This figure can be rigged where the earlier cast could not, and the reason
is worth writing down: its arms hang clear of the torso and its legs are
separated, so there is a real gap to cut along. The first painted cast was
chibi with the arms tucked in, and every cut through it came out as a
rectangle sliced across the chest.

The boxes below were measured off the figure, not guessed. Two of them are
narrower than the limb looks, on purpose: the cape sits BEHIND the left arm
and the backpack behind the right one, so a box drawn to the full width of
each arm takes a slice of cape or strap with it, and that slice then swings
around the shoulder like a flag.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "cast_rigged"

## part -> (x0, y0, x1, y1) as fractions of the figure, then the joint it
## turns about, also as fractions. The joint is where the part meets the
## body, which is what a limb actually rotates around.
PARTS = {
    "head":      ((0.00, 0.00, 1.00, 0.45), (0.50, 0.44)),
    "arm_back":  ((0.26, 0.46, 0.37, 0.80), (0.31, 0.49)),
    "arm_front": ((0.65, 0.46, 0.77, 0.80), (0.71, 0.49)),
    # The legs start a little higher than they look and turn about a point
    # higher still, inside the tunic. Pivoting on a leg's own top corner
    # swings that corner out from under the body and opens a gap at the hip
    # on every step.
    "leg_back":  ((0.31, 0.73, 0.50, 1.00), (0.42, 0.72)),
    "leg_front": ((0.50, 0.73, 0.69, 1.00), (0.58, 0.72)),
}
## Drawing order, back to front.
ORDER = ["arm_back", "leg_back", "body", "leg_front", "arm_front", "head"]
INK = 24


def rig(src: Path, out: Path, name: str) -> dict:
    img = Image.open(src).convert("RGBA")
    a = np.array(img)
    mask = a[:, :, 3] > INK
    ys, xs = np.nonzero(mask)
    bx0, by0 = int(xs.min()), int(ys.min())
    bx1, by1 = int(xs.max()) + 1, int(ys.max()) + 1
    w, h = bx1 - bx0, by1 - by0

    def box(f: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
        return (bx0 + int(f[0] * w), by0 + int(f[1] * h),
                bx0 + int(f[2] * w), by0 + int(f[3] * h))

    rows, cols = mask.shape
    yy = np.arange(rows)[:, None]
    xx = np.arange(cols)[None, :]

    taken = np.zeros_like(mask)
    meta: dict = {"figure": [bx0, by0, bx1, by1], "order": ORDER, "parts": {}}
    out.mkdir(parents=True, exist_ok=True)

    for part, (frac, joint) in PARTS.items():
        x0, y0, x1, y1 = box(frac)
        sel = mask & (xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1)
        sel &= ~_shadow(a, by1, h)
        taken |= sel
        meta["parts"][part] = _write(img, sel, out / f"{name}_{part}.png",
                                     bx0, by0, w, h, joint)

    # The body is what no limb claimed: torso, cape, backpack.
    body = mask & ~taken
    # The painted drop shadow goes with it. It is a pale grey ellipse lying
    # on the ground under the figure, and left in the body it would rise
    # into the air on every jump -- a shadow that leaves the floor reads as
    # a mistake instantly. The engine draws one that stays put instead.
    body &= ~_shadow(a, by1, h)
    shadow = _shadow(a, by1, h)
    meta["parts"]["body"] = _write(img, body, out / f"{name}_body.png",
                                   bx0, by0, w, h, (0.50, 0.78))
    return meta


def _shadow(a: np.ndarray, by1: int, h: int) -> np.ndarray:
    """The pale, colourless ellipse in the bottom tenth of the figure."""
    rgb = a[:, :, :3].astype(int)
    pale = rgb.min(axis=2) > 132
    grey = (rgb.max(axis=2) - rgb.min(axis=2)) < 26
    low = np.zeros(a.shape[:2], bool)
    # A generous band: the ellipse is soft-edged and its faintest pixels
    # reach further up than the solid part, and a few left behind read as
    # white crumbs under the boots on every frame.
    low[max(0, by1 - int(h * 0.16)):by1, :] = True
    return pale & grey & low


def _write(img: Image.Image, sel: np.ndarray, path: Path,
           bx0: int, by0: int, w: int, h: int,
           joint: tuple[float, float]) -> dict:
    a = np.array(img)
    a[:, :, 3] = np.where(sel, a[:, :, 3], 0)
    ys, xs = np.nonzero(a[:, :, 3] > INK)
    if len(ys) == 0:
        Image.new("RGBA", (1, 1)).save(path)
        return {"offset": [0, 0], "size": [1, 1], "joint": [0.0, 0.0]}
    x0, y0 = int(xs.min()), int(ys.min())
    x1, y1 = int(xs.max()) + 1, int(ys.max()) + 1
    Image.fromarray(a[y0:y1, x0:x1]).save(path)
    # The joint is stored relative to the piece's own top-left, so the
    # engine can set it straight onto Sprite2D.offset without arithmetic.
    jx = bx0 + joint[0] * w - x0
    jy = by0 + joint[1] * h - y0
    return {
        "offset": [x0 - bx0, y0 - by0],
        "size": [x1 - x0, y1 - y0],
        "joint": [round(jx, 1), round(jy, 1)],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", type=Path, default=OUT / "hero_source.png")
    ap.add_argument("--name", default="hero")
    ap.add_argument("--out", type=Path, default=OUT)
    args = ap.parse_args()
    meta = rig(args.source, args.out, args.name)
    (args.out / f"{args.name}.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    for part in meta["order"]:
        p = meta["parts"][part]
        print(f"{part:11s} {p['size'][0]:4d}x{p['size'][1]:<4d} joint {p['joint']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

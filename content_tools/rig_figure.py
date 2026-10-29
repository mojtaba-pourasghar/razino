"""Cuts a painted figure into the parts a walk cycle needs, with joints.

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
    # The legs' vertical extent is MEASURED per figure, not taken from
    # here: see find_hip(). These fractions only set how wide each leg is
    # and are overwritten top-to-bottom before the cut.
    "leg_back":  ((0.31, 0.73, 0.50, 1.00), (0.42, 0.72)),
    "leg_front": ((0.50, 0.73, 0.69, 1.00), (0.58, 0.72)),
}
## Drawing order, back to front.
ORDER = ["arm_back", "leg_back", "body", "leg_front", "arm_front", "head"]
INK = 24


def find_hip(mask: np.ndarray, bx0: int, by0: int, w: int, h: int) -> float:
    """Where the figure stops being one shape and becomes two legs.

    Returned as a fraction of the figure's height. A fixed fraction cannot
    work across this cast: the hero is a boy in a short tunic, one teacher
    wears a cardigan to the knee and one of them is a dinosaur. Measuring
    the row where the silhouette first splits into two runs puts the hip
    where the legs actually start on each of them.

    Falls back to 0.73 for a figure that never splits — a long coat, or a
    tail that bridges the gap — which is where a short tunic sits and is
    the least wrong guess available.
    """
    best = None
    for y in range(by0 + int(h * 0.50), by0 + int(h * 0.95)):
        runs = 0
        run = 0
        for x in range(bx0, bx0 + w):
            if mask[y, x]:
                run += 1
            else:
                if run > w * 0.06:
                    runs += 1
                run = 0
        if run > w * 0.06:
            runs += 1
        if runs >= 2:
            best = y
            break
    if best is None:
        return 0.73
    # A little above the split, so the tops of the legs stay tucked under
    # the body and the hip does not open on a step.
    return max(0.50, (best - by0) / float(h) - 0.04)


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

    hip = find_hip(mask, bx0, by0, w, h)
    parts = dict(PARTS)
    for leg in ("leg_back", "leg_front"):
        frac, joint = parts[leg]
        parts[leg] = ((frac[0], hip, frac[2], 1.00), (joint[0], hip - 0.01))

    taken = np.zeros_like(mask)
    meta: dict = {"figure": [bx0, by0, bx1, by1], "order": ORDER, "parts": {}}
    out.mkdir(parents=True, exist_ok=True)

    for part, (frac, joint) in parts.items():
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
                                   bx0, by0, w, h, (0.50, hip + 0.05))
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


def cut_page(src: Path, dest: Path) -> None:
    """Takes the painted figure off its page.

    Two passes, because one is not enough. The first floods the white in
    from the border, which leaves anything white the figure encloses — and
    the gap between two legs encloses a pocket of page that then shows as a
    bright wedge on every step. The second removes any remaining patch of
    pure, colourless white bigger than a few hundred pixels; a highlight in
    an eye is far smaller than that and survives.
    """
    from collections import deque

    im = Image.open(src).convert("RGB")
    a = np.asarray(im).astype(int)
    h, w, _ = a.shape
    white = a.min(axis=2) > 228
    seen = np.zeros((h, w), bool)
    q: deque = deque()
    for x in range(w):
        for y in (0, h - 1):
            if white[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if white[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    while q:
        cy, cx = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and white[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))

    out = np.dstack([a, np.where(seen, 0, 255)]).astype(np.uint8)
    rgb = out[:, :, :3].astype(int)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    trapped = (rgb.min(axis=2) >= 244) & (sat <= 8) & (out[:, :, 3] > 0)
    lab = np.zeros((h, w), int)
    cur = 0
    for y in range(h):
        for x in range(w):
            if trapped[y, x] and lab[y, x] == 0:
                cur += 1
                q = deque([(y, x)])
                lab[y, x] = cur
                cells = [(y, x)]
                while q:
                    cy, cx = q.popleft()
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if (0 <= ny < h and 0 <= nx < w and trapped[ny, nx]
                                and lab[ny, nx] == 0):
                            lab[ny, nx] = cur
                            q.append((ny, nx))
                            cells.append((ny, nx))
                if len(cells) >= 400:
                    for cy, cx in cells:
                        out[cy, cx, 3] = 0

    img = Image.fromarray(out, "RGBA")
    ys, xs = np.nonzero(out[:, :, 3] > 0)
    img.crop((int(xs.min()), int(ys.min()),
              int(xs.max()) + 1, int(ys.max()) + 1)).save(dest)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--only", default="")
    args = ap.parse_args()

    done = 0
    for raw in sorted(args.out.glob("*_source_raw.png")):
        name = raw.stem.replace("_source_raw", "")
        if args.only and args.only != name:
            continue
        src = args.out / f"{name}_source.png"
        cut_page(raw, src)
        meta = rig(src, args.out, name)
        (args.out / f"{name}.json").write_text(
            json.dumps(meta, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"{name:9s} rigged")
        done += 1

    # The hero was cut off its page by hand before this tool existed.
    hero = args.out / "hero_source.png"
    if hero.is_file() and (not args.only or args.only == "hero"):
        meta = rig(hero, args.out, "hero")
        (args.out / "hero.json").write_text(
            json.dumps(meta, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print("hero      rigged")
        done += 1
    print(f"\n{done} figures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

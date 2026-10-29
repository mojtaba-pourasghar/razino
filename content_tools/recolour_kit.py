"""Moves the painted kit onto a new palette without repainting it.

The kit was painted navy and gold. The approved direction is indigo, teal
and amber, and there is no image credit to paint it again -- so the grain,
bevel and rim that were paid for are kept and only the colour is moved.

A single luminance ramp would not do it. Every piece carries TWO materials:
a cool body and a warm metal edge or face. Mapped through one ramp the gold
corner brackets come out as pale indigo and the panel loses the thing that
made it read as made rather than filled. So each pixel is sorted by hue
first -- warm pixels follow the metal ramp, everything else the body ramp --
and the two are remapped separately by how light they were.

Sources live in assets/art/reference/kit_src/, which is excluded from every
export preset, so a run is repeatable and never compounds on its own output.
"""

from __future__ import annotations

import argparse
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "art" / "reference" / "kit_src"
KIT = ROOT / "assets" / "art" / "kit"

## Sampled from the approved mockup by hue family, not chosen by eye.
## See docs/DESIGN.md.
BODY = [(0.00, (0x03, 0x06, 0x12)), (0.35, (0x0A, 0x14, 0x26)),
        (0.65, (0x16, 0x28, 0x40)), (1.00, (0x2A, 0x4E, 0x6B))]
METAL = [(0.00, (0x3A, 0x24, 0x0C)), (0.35, (0x8A, 0x5A, 0x1E)),
         (0.70, (0xC9, 0x95, 0x3A)), (1.00, (0xFF, 0xD2, 0x7A))]
## The one piece that is the action itself is brighter all through, or the
## single gold button on a screen stops being the brightest thing on it.
METAL_HOT = [(0.00, (0x6B, 0x3F, 0x10)), (0.35, (0xC2, 0x80, 0x22)),
             (0.70, (0xEF, 0xB2, 0x44)), (1.00, (0xFF, 0xE2, 0x9B))]

## Pieces whose warm parts are the action, not a frame.
HOT = {"button_gold", "tab_active"}
## Warm hues, in degrees. Anything outside this follows the body ramp.
WARM = (18.0, 62.0)
## Below this saturation a pixel has no hue worth trusting, so it is body.
WARM_SAT = 0.16


def ramp(stops: list[tuple[float, tuple[int, int, int]]],
         t: float) -> tuple[int, int, int]:
    t = min(1.0, max(0.0, t))
    for i in range(len(stops) - 1):
        a, ca = stops[i]
        b, cb = stops[i + 1]
        if a <= t <= b:
            f = 0.0 if b == a else (t - a) / (b - a)
            return tuple(round(ca[c] + (cb[c] - ca[c]) * f) for c in range(3))
    return stops[-1][1]


def _span(values: list[float]) -> tuple[float, float]:
    """The range a material actually occupies, ignoring its outliers."""
    if not values:
        return 0.0, 1.0
    values.sort()
    lo = values[int(0.02 * (len(values) - 1))]
    hi = values[int(0.98 * (len(values) - 1))]
    return (lo, hi) if hi - lo > 0.02 else (lo, lo + 0.02)


def recolour(img: Image.Image, hot: bool) -> Image.Image:
    img = img.convert("RGBA")
    px = list(img.getdata())
    metal = METAL_HOT if hot else METAL

    # Each material is stretched across its new ramp rather than mapped
    # straight onto it. The painted navy sits between about 0.08 and 0.25
    # luminance, so mapped raw it lands in the first eighth of the ramp and
    # every piece comes out nearly black with its bevel gone. Measuring the
    # span each material really occupies keeps the modelling that was
    # painted into it and moves only where that modelling sits.
    sorted_px = [(colorsys.rgb_to_hls(r / 255, g / 255, b / 255), a)
                 for r, g, b, a in px]
    warm_l: list[float] = []
    body_l: list[float] = []
    for (h, l, s), a in sorted_px:
        if a == 0:
            continue
        if s >= WARM_SAT and WARM[0] <= h * 360.0 <= WARM[1]:
            warm_l.append(l)
        else:
            body_l.append(l)
    warm_lo, warm_hi = _span(warm_l)
    body_lo, body_hi = _span(body_l)

    out = []
    for (h, l, s), a in sorted_px:
        if a == 0:
            out.append((0, 0, 0, 0))
            continue
        if s >= WARM_SAT and WARM[0] <= h * 360.0 <= WARM[1]:
            t = (l - warm_lo) / (warm_hi - warm_lo)
            nr, ng, nb = ramp(metal, t)
        else:
            t = (l - body_lo) / (body_hi - body_lo)
            nr, ng, nb = ramp(BODY, t)
        out.append((nr, ng, nb, a))
    done = Image.new("RGBA", img.size)
    done.putdata(out)
    return done


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src", type=Path, default=SRC)
    ap.add_argument("--out", type=Path, default=KIT)
    ap.add_argument("--only", default="", help="one piece, for a quick look")
    args = ap.parse_args()

    if not args.src.is_dir():
        print(f"no source kit at {args.src}")
        return 1
    args.out.mkdir(parents=True, exist_ok=True)

    n = 0
    for path in sorted(args.src.glob("*.png")):
        name = path.stem
        if args.only and name != args.only:
            continue
        recolour(Image.open(path), name in HOT).save(args.out / f"{name}.png")
        print(f"{name:14s} {'action' if name in HOT else 'frame'}")
        n += 1
    print(f"\n{n} pieces recoloured into {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

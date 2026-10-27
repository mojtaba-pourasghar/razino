#!/usr/bin/env python3
"""Paints the cast: a reference sheet per character, then their mood cells.

Order matters and is not negotiable. The sheet comes first and is looked at
by a person before anything else is painted, because every mood cell is
painted from the same description — if the description is wrong, eighty cells
are wrong and the quota that painted them is gone.

    python3 content_tools/generate_cast.py --sheets        # five sheets
    python3 content_tools/generate_cast.py --moods raha    # one cast's moods
    python3 content_tools/generate_cast.py --dry-run

Resumable: every file that already exists is skipped, so a run cut off by the
daily allowance loses nothing. Run it again tomorrow.

Needs `rembg` and `onnxruntime` installed; the figure is cut out of whatever
the painter framed it in by a matting model, for the reasons set out above
cutout_figure().
"""

from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import cast as cast_book  # noqa: E402
from generate_ui_art import (  # noqa: E402
    ACCOUNTS_DEFAULT, Pool, load_accounts, paint, trim,
)
from PIL import Image  # noqa: E402
from rembg import new_session, remove  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "cast"

## A figure stands about a third of the screen tall, so this is 2x what it is
## drawn at — enough for a tablet without carrying a photograph in the APK.
SHEET_SIZE = (768, 1024)




def cutout_figure(png: bytes) -> Image.Image:
    """Lifts the figure off whatever the model painted around it.

    The painter will not stop framing the figure. Asked for a character on
    flat magenta it paints the character inside an ornate gold frame — on
    cream parchment, on navy, on a gilt oval — because that is what this kind
    of game art looks like to it, and no number of "no frame" clauses in the
    prompt changes that.

    So the frame is removed after the fact, by a matting model rather than by
    hand. Several hand-written attempts are not in this file any more and the
    reason each failed is worth keeping, because each looks reasonable until
    it is run:

      · Keying the backdrop by colour needs the backdrop to be one colour.
        The painter makes it a vignette, dark at the corners.
      · Flooding in from the border stops dead at the gold frame and removes
        nothing at all.
      · Cropping inside the frame first, then flooding, works until a frame
        is thick — the gilt oval needed a quarter of the picture cut away,
        and a fixed inset that deep took heads off the others.
      · Letting the flood follow the gradient instead of the seed colour
        crosses the vignette, and then walks straight through the soft
        shading inside a jacket and erases the child wearing it.

    A matting model has an idea of what a figure is, which is exactly the
    thing none of those have.
    """
    img = Image.open(io.BytesIO(png)).convert("RGBA")
    return trim(_strip_rind(_clear_backdrop_colour(remove(img, session=_session()))))


def _strip_rind(img: Image.Image, rounds: int = 16) -> Image.Image:
    """Peels off the white sticker outline the painter draws around figures.

    It paints figures as die-cut stickers — a pale rind following the whole
    silhouette — whatever the prompt says, and the matting model keeps it
    because it is part of the shape. Here it is eaten from the outside in: a
    near-white pixel touching transparency is outline, not the figure.

    Working inward from the edge is what makes this safe. A white shirt or a
    pale tail tip is surrounded by the figure, never by transparency, so it
    is never reached.
    """
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    for _ in range(rounds):
        doomed = []
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a < 40 or r < 186 or g < 186 or b < 186:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h or px[nx, ny][3] < 40:
                        doomed.append((x, y))
                        break
        if not doomed:
            break
        for x, y in doomed:
            r, g, b, _a = px[x, y]
            px[x, y] = (r, g, b, 0)
    return img


def _clear_backdrop_colour(img: Image.Image) -> Image.Image:
    """Clears backdrop the matting model decided was part of the subject.

    It keeps whatever is enclosed by the figures — the magenta showing
    between two children standing shoulder to shoulder reads to it as inside
    the group, so the group arrives with pink holes in it. Nothing anyone in
    this cast wears is saturated magenta, so that colour can simply go,
    wherever it is. Only the unmistakable version: a dull mauve in a shadow
    stays, because this pass has no connectivity to protect it.
    """
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a and r > 95 and b > 70 and g < min(r, b) * 0.62:
                px[x, y] = (r, g, b, 0)
    return img


_SESSION = None


def _session():
    """The matting model, loaded once. The weights download on first use."""
    global _SESSION
    if _SESSION is None:
        _SESSION = new_session("isnet-general-use")
    return _SESSION


def jobs(sheets: bool, moods: str) -> list[tuple[str, str, str]]:
    """(out_name, prompt, what) for everything asked for."""
    out: list[tuple[str, str, str]] = []
    wanted = [moods] if moods else list(cast_book.CAST)
    for cid in wanted:
        if cid not in cast_book.CAST:
            raise SystemExit(f"unknown character '{cid}'")
        if sheets:
            out.append((f"{cid}_sheet", cast_book.sheet_prompt(cid), cid))
        else:
            for mood in cast_book.MOODS:
                out.append((f"{cid}_{mood}", cast_book.mood_prompt(cid, mood), cid))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--accounts", default=str(ACCOUNTS_DEFAULT))
    ap.add_argument("--sheets", action="store_true",
                    help="paint the reference sheet for each character")
    ap.add_argument("--moods", default="",
                    help="paint one character's mood cells, by id")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not args.sheets and not args.moods:
        args.sheets = True

    OUT.mkdir(parents=True, exist_ok=True)
    todo = jobs(args.sheets, args.moods)

    if args.dry_run:
        for name, prompt, _ in todo:
            print(f"--- {name} ({SHEET_SIZE[0]}x{SHEET_SIZE[1]})\n{prompt}\n")
        return 0

    pool = Pool(load_accounts(Path(args.accounts)))
    painted = 0
    for name, prompt, who in todo:
        dest = OUT / f"{name}.png"
        if dest.exists() and not args.force:
            print(f"  · {name} already painted")
            continue
        if args.limit and painted >= args.limit:
            print(f"  … stopping at {args.limit}")
            break
        result = paint(pool, prompt, *SHEET_SIZE)
        if isinstance(result, str):
            print(f"  ! {name}: {result}")
            if result == "quota":
                print("    the day's allowance is spent — run again tomorrow")
                break
            continue
        # Painted on flat magenta and cut out, so a figure can stand on any
        # scene without carrying a rectangle of background with it. Kept at
        # full size rather than shrunk to a thumbnail: a figure is a third of
        # the screen tall, and the icon path left it blurry.
        cutout_figure(result).save(dest)
        painted += 1
        print(f"  ✓ {name}  ({who})")
    print(f"{painted} painted, {len(todo)} asked for")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""The story's cast, taken from the approved character sheet
(assets/art/reference/cast_sheet.webp).

Two ways to make a character, both on transparent ground:

  painted     (the default) the character is cropped out of the sheet to
              SHOW the model and painted again alone, full size, in the
              sheet's style — sharp at any size the game draws it.
  --from-sheet  the character is cut out of the sheet exactly as drawn.
              The sheet is small (a figure is ~160 px), so this is softer
              when shown large; it is what ships until a painting exists.

For a cut, The sheet carries its own alpha
channel, so a cut is clean; the only work is keeping the one large figure
in a box and dropping the small poses and labels that crowd round it,
which is done by keeping the largest connected shape. The face medallion
is cut from the same figure, so the portrait and the figure are always one
person.

Which sheet character plays whom:

    arad     Hero        the brave boy in the red cape
    raha     Companion   the red-haired girl with glasses and a notebook
    mani     Buddy       the curly-haired boy in the green jacket
    player   NPC Girl    the default look before the avatar is customised
    fandogh  Dino        the group's guide

Mrs Azimi and the principal are not on the sheet, so they are always
painted, in its style, with the Hero shown as the style reference.

    python3 content_tools/paint_cast.py
    python3 content_tools/paint_cast.py --only raha --force
    python3 content_tools/paint_cast.py --cut-only
"""

from __future__ import annotations

import argparse
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image

import openai_painter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "cast"
SHEET = ROOT / "assets" / "art" / "reference" / "cast_sheet.webp"

## Where each sheet character's large figure stands on the sheet.
CROP = {
    "hero": (0, 30, 88, 195),
    "companion": (275, 25, 378, 195),
    "buddy": (855, 35, 942, 195),
    "npc_girl": (0, 270, 98, 440),
    "dino": (556, 33, 652, 184),
}

STYLE = (
    "In exactly the art style of the reference character sheet: a cute "
    "chibi-proportioned 2D fantasy RPG character with a large head, big "
    "expressive eyes, crisp dark outlines, rich warm cel shading and fine "
    "painted detail, as in a premium mobile adventure game."
)
POSE = (
    "One single character only, full body from the top of the head to the "
    "soles of the shoes, standing in a relaxed three-quarter front view "
    "facing slightly to the viewer's right, friendly expression, arms "
    "relaxed. Large, filling the height of the picture with a little space "
    "all round. No other poses, no small copies, no labels."
)
CUTOUT = ("Isolated on a fully transparent background: no ground, no "
          "shadow, no backdrop, no white outline round the character.")
NO_TEXT = "Absolutely no text, no letters, no watermark."

## Taken from the sheet as drawn: character id -> crop name.
FROM_SHEET = {
    "arad": "hero",
    "raha": "companion",
    "mani": "buddy",
    "player": "npc_girl",
    "fandogh": "dino",
}

## The sheet is small — a figure is about 160 px tall — so a cut is scaled
## up for the screens that show it large. Nearest-neighbour would keep its
## crisp sprite edges but make blocks; Lanczos with a light sharpen keeps
## the line work clean at the sizes the game draws it.
SHEET_SCALE = 4

CAST: dict[str, dict] = {
    "arad": {
        "refs": ["hero"],
        "who": ("Exactly the 'Hero' of the reference: a brave boy with "
                "tousled brown hair and blue-grey eyes, a red cape, a dark "
                "leather jerkin over a white shirt, a brown belt with "
                "pouches, dark trousers and brown boots. No weapon."),
    },
    "raha": {
        "refs": ["companion"],
        "who": ("Exactly the 'Companion' of the reference: a girl with long "
                "bright red hair, a dark hairband and round glasses, a teal "
                "jacket over a cream shirt, a big brown backpack, navy "
                "trousers and brown boots, holding a sheet of paper."),
    },
    "mani": {
        "refs": ["buddy"],
        "who": ("Exactly the 'Buddy' of the reference: a cheerful boy with "
                "a big mop of curly brown hair, an olive-green hooded "
                "jacket over an orange shirt, khaki shorts, a backpack and "
                "brown boots."),
    },
    "player": {
        "refs": ["npc_girl"],
        "who": ("Exactly the 'NPC Girl' of the reference: a girl with dark "
                "curly hair in two puffs with pink beads, a pink t-shirt, a "
                "green patterned backpack, light blue cargo jeans and "
                "colourful sneakers."),
    },
    "fandogh": {
        "refs": ["dino"],
        "who": ("Exactly the 'Dino' of the reference: a small round friendly "
                "blue baby dinosaur with a pale blue belly, big eyes, a happy "
                "open-mouthed smile, a red neckerchief and a little brown "
                "backpack, standing on his hind legs."),
    },
    "azimi": {
        "refs": ["hero"],
        "who": ("Mrs Azimi, the kind school librarian: a warm middle-aged "
                "Iranian woman in a modest navy headscarf and a long "
                "cardigan-coat in soft teal over a cream blouse, reading "
                "glasses on a chain, holding a stack of two old books."),
    },
    "modir": {
        "refs": ["hero"],
        "who": ("The school principal: a gentle grey-haired Iranian man "
                "with a neat short beard and glasses, a brown suit jacket "
                "over a light blue shirt without a tie, holding a ring of "
                "old brass keys."),
    },
}


def largest_shape(alpha: Image.Image) -> Image.Image:
    """The mask of the biggest connected opaque shape — the figure — with
    everything else in the box (neighbouring poses, labels) cleared."""
    import numpy as np
    a = np.array(alpha) > 40
    h, w = a.shape
    seen = np.zeros_like(a, dtype=bool)
    best: list = []
    for y0 in range(h):
        for x0 in range(w):
            if not a[y0, x0] or seen[y0, x0]:
                continue
            stack, shape = [(y0, x0)], []
            seen[y0, x0] = True
            while stack:
                y, x = stack.pop()
                shape.append((y, x))
                for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= ny < h and 0 <= nx < w and a[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            if len(shape) > len(best):
                best = shape
    keep = np.zeros_like(a, dtype=bool)
    for y, x in best:
        keep[y, x] = True
    # Grow by one pixel so the soft anti-aliased rim stays with the figure.
    grown = keep.copy()
    grown[1:, :] |= keep[:-1, :]
    grown[:-1, :] |= keep[1:, :]
    grown[:, 1:] |= keep[:, :-1]
    grown[:, :-1] |= keep[:, 1:]
    return Image.fromarray((np.array(alpha) * grown).astype("uint8"))


def from_sheet(cid: str, raw: Path) -> str:
    """Cuts a character out of the sheet as drawn."""
    from PIL import ImageFilter
    im = Image.open(SHEET).convert("RGBA").crop(CROP[FROM_SHEET[cid]])
    im.putalpha(largest_shape(im.getchannel("A")))
    im = im.crop(im.getchannel("A").getbbox())
    im = im.resize((im.width * SHEET_SCALE, im.height * SHEET_SCALE),
                   Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
    im.save(raw / f"sheet_{cid}.png")
    return f"{cid}: cut from the sheet"


def reference(name: str, raw: Path) -> Path:
    out = raw / "refs" / f"{name}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    im = Image.open(SHEET).convert("RGB").crop(CROP[name])
    im.resize((im.width * 5, im.height * 5), Image.LANCZOS).save(out)
    return out


def paint(cid: str, raw: Path) -> str:
    c = CAST[cid]
    refs = [reference(r, raw) for r in c["refs"]]
    prompt = f"{STYLE} {c['who']} {POSE} {CUTOUT} {NO_TEXT}"
    result = openai_painter.paint_from(prompt, refs, 1024, 1536, True)
    if isinstance(result, str):
        return f"{cid}: FAILED — {result}"
    (raw / f"{cid}.png").write_bytes(result)
    return f"{cid}: painted"


def cut(cid: str, raw: Path, use_sheet: bool = False) -> str:
    """The figure, trimmed; and the face medallion, a square from the top
    of the same figure centred on the head."""
    src = raw / f"{cid}.png"
    if use_sheet and cid in FROM_SHEET:
        src = raw / f"sheet_{cid}.png"
    if not src.exists():
        return f"{cid}: no raw painting"
    im = Image.open(src).convert("RGBA")
    alpha = im.getchannel("A").point(lambda a: 0 if a < 8 else a)
    im.putalpha(alpha)
    l, t, r, b = alpha.getbbox()
    pad = 8
    fig = im.crop((max(0, l - pad), max(0, t - pad),
                   min(im.width, r + pad), min(im.height, b + pad)))
    fig.thumbnail((768, 1024), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    fig.save(OUT / f"{cid}_sheet.png", optimize=True)

    # The head is the widest solid part of the top third in a chibi figure;
    # centre the square on the middle of the top row band's pixels.
    h = b - t
    side = round(h * 0.42)
    band = alpha.crop((l, t, r, t + round(h * 0.30)))
    bl, _, br, _ = band.getbbox()
    cx = l + (bl + br) // 2
    top = max(0, t - round(side * 0.04))
    face = im.crop((cx - side // 2, top, cx - side // 2 + side, top + side))
    face = face.resize((384, 384), Image.LANCZOS)
    face.save(OUT / f"{cid}_face.png", optimize=True)
    return f"{cid}: {fig.width}x{fig.height}, face 384"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--cut-only", action="store_true")
    ap.add_argument("--from-sheet", action="store_true",
                    help="use the sheet's own drawings for its characters")
    ap.add_argument("--raw", default=str(Path.home() / ".razino" / "raw_cast"))
    args = ap.parse_args()
    raw = Path(args.raw)
    raw.mkdir(parents=True, exist_ok=True)
    names = [n for n in (args.only or CAST) if n in CAST]
    if args.from_sheet:
        for n in names:
            if n in FROM_SHEET:
                print(from_sheet(n, raw))
    if not args.cut_only:
        todo = [n for n in names
                if not (args.from_sheet and n in FROM_SHEET)
                and (args.force or not (raw / f"{n}.png").exists())]
        with ThreadPoolExecutor(max_workers=7) as pool:
            for line in pool.map(lambda n: paint(n, raw), todo):
                print(line, flush=True)
    for n in names:
        print(cut(n, raw, args.from_sheet))
    return 0


if __name__ == "__main__":
    sys.exit(main())

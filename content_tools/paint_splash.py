#!/usr/bin/env python3
"""Paints the start screen (UI-01) as separate layers on transparent ground.

The screen is the main-menu panel of the approved sheet
(assets/art/reference/screens.webp, top left): a bright painted valley with
a castle and a waterfall, the hero on a rock looking towards it, a gold
compass crest over the name, and one column of buttons. Every piece is its
own painting with a real alpha channel, so Godot can place, scale and
animate each one on its own:

    menu_bg          the valley, opaque, open in the middle
    menu_hero        Arad and Fandogh on their rock, transparent
    menu_crest       the compass crest above the name, transparent
    button_gold      the primary button plate, transparent, nine-patched
    button_navy      the other buttons' plate, transparent, nine-patched
    menu_title       the name itself — SET IN TYPE here, not painted

The sheet is the reference, not the sheet's pixels: the relevant panels are
cropped out of it and handed to the model as pictures to follow. The
sheet's own title reads «رازنتی», which is what an image model does to
Persian letters, so the name is never painted — `set_title()` sets it in
Vazirmatn and dresses it in the sheet's chunky gold.

Raw replies are kept in `--raw` so a piece can be re-cut without paying for
it again. The cut pieces go to assets/art/splash/.

    python3 content_tools/paint_splash.py                 # everything missing
    python3 content_tools/paint_splash.py --only menu_hero --force
    python3 content_tools/paint_splash.py --cut-only      # re-cut from --raw
"""

from __future__ import annotations

import argparse
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

import openai_painter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "splash"
REF = ROOT / "docs" / "reference"
SHEETS = ROOT / "assets" / "art" / "reference"
FONT = ROOT / "assets" / "fonts" / "Vazirmatn-Bold.ttf"

## Panels cut out of the approved sheets to show the model, as
## (sheet, box, scale). Cropped fresh on every run, so the references can
## never drift from the sheets they come from.
CROPS = {
    "menu_panel": ("screens.webp", (0, 0, 766, 436), 1.0),
    "menu_hero": ("screens.webp", (0, 40, 300, 436), 2.0),
    "menu_logo": ("screens.webp", (300, 15, 525, 195), 3.0),
    "cast_hero": ("cast_sheet.webp", (0, 30, 85, 195), 4.0),
}

## The look of the approved sheet: painted fantasy key art, bright daylight,
## gold-and-navy chrome. Said once so every piece shares it.
LOOK = (
    "Premium painted 2D fantasy game key art, in exactly the style of the "
    "reference pictures: crisp anime-influenced illustration with clean "
    "line work, rich painterly shading and bright saturated daylight colour, "
    "the quality of a top-grossing mobile adventure game."
)
NO_TEXT = ("Absolutely no text, no letters, no numbers, no signage writing, "
           "no watermark, no logo.")
CUTOUT = ("Isolated on a fully transparent background: no backdrop, no "
          "sky, no frame, no vignette, nothing around it.")

PIECES: dict[str, dict] = {
    "menu_bg": {
        "size": (1536, 1024), "transparent": False, "ext": "webp",
        "refs": ["menu_panel", "world-reference-1.webp"],
        "prompt": (
            f"{LOOK} Repaint the landscape of the first reference picture as "
            "a clean wide title-screen background with nobody in it: a sunny "
            "fantasy valley under a deep blue sky with soft white clouds; "
            "blue snow-capped mountains far away; on the RIGHT a grand "
            "fairy-tale castle of pale stone with many slender blue-roofed "
            "spires on a tall cliff, a terracotta-roofed town climbing up to "
            "it, a stone arch bridge and a bright waterfall falling into a "
            "turquoise river below; on the LEFT a large leafy oak tree "
            "framing the top-left corner and a mossy rocky ledge in the "
            "lower-left foreground (a character will be placed standing on "
            "it). The CENTRE of the picture, from top to bottom, is calm: "
            "distant hazy forest, valley and sky only, with no castle and "
            "no tall object there, because the game's title and a column of "
            "menu buttons will sit over it. No people, no animals, no "
            f"characters anywhere. {NO_TEXT}"),
    },
    "menu_hero": {
        "size": (1024, 1536), "transparent": True,
        "refs": ["menu_hero", "char-arad.webp", "char-fandogh-concept.webp",
                 "cast_hero"],
        "prompt": (
            f"{LOOK} The hero from the first reference picture, standing in "
            "the same pose on a mossy rock outcrop: a brave boy of about "
            "eleven seen from three-quarters behind, turned to the RIGHT, "
            "gazing towards a distant castle, one hand on the strap of his "
            "big leather adventurer's backpack with a rolled map tucked in "
            "it, a flowing red cape, brown leather jerkin, sturdy boots. Give "
            "him the face and curly dark brown hair of Arad from picture 2 "
            "(seen in profile). No weapon. Beside his feet on the same rock "
            "sits Fandogh, the little orange fox detective from picture 3, "
            "in his brown deerstalker hat and cape, holding his magnifying "
            "glass and also looking to the right. The rock is a compact "
            "chunk of grey stone with moss and a few grass tufts, flat at "
            "the bottom. Everything fully inside the picture with a little "
            "space all round. Copy ONLY the characters and their rock from "
            "the references — none of the first picture's valley, castle, "
            "mountains or sky; behind and around them there is nothing at "
            f"all. {CUTOUT} {NO_TEXT}"),
    },
    "menu_crest": {
        "size": (1024, 1024), "transparent": True, "refs": ["menu_logo"],
        "prompt": (
            f"{LOOK} Only the compass emblem from the top of the reference "
            "logo, painted larger and cleaner: an eight-pointed polished gold "
            "compass star over a deep blue enamel ring framed in gold, with "
            "small gold points between the main ones and a bright glint on "
            "the star. Seen flat from the front, symmetrical, centered, "
            f"filling the frame. Nothing below it. {CUTOUT} {NO_TEXT}"),
    },
    "button_gold": {
        "size": (1536, 1024), "transparent": True, "refs": [], "height": 64,
        "prompt": (
            f"{LOOK} One slim, elegant game menu button seen flat from the "
            "front: a long horizontal capsule about seven times wider than "
            "tall with fully rounded ends. A warm glossy amber-gold face, "
            "lighter in the middle with a soft glassy highlight along its "
            "upper half. A FINE, thin polished-gold rim with a hairline dark "
            "edge, and at each rounded end a small delicate gold filigree "
            "flourish — a tiny curl with one small leaf — that barely leaves "
            "the outline. Refined jewellery-like detail, nothing chunky. The "
            "face is completely plain and empty. Perfectly symmetrical, "
            f"centered, filling the width. {CUTOUT} {NO_TEXT}"),
    },
    "button_navy": {
        "size": (1536, 1024), "transparent": True, "refs": [], "height": 64,
        "prompt": (
            f"{LOOK} One slim, elegant game menu button seen flat from the "
            "front: a long horizontal capsule about seven times wider than "
            "tall with fully rounded ends. A deep navy-blue glassy face with "
            "a faint lighter sheen along its upper half and a soft inner "
            "glow. A FINE, thin polished-gold rim with a hairline dark edge, "
            "and at each rounded end a small delicate gold filigree flourish "
            "— a tiny curl with one small leaf — that barely leaves the "
            "outline. Refined jewellery-like detail, nothing chunky. The "
            "face is completely plain and empty. Perfectly symmetrical, "
            f"centered, filling the width. {CUTOUT} {NO_TEXT}"),
    },
}


def reference(name: str, raw_dir: Path) -> Path:
    """A reference picture: a crop of a sheet, or a file in docs/reference."""
    if name not in CROPS:
        return REF / name
    sheet, box, scale = CROPS[name]
    out = raw_dir / "refs" / f"{name}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    im = Image.open(SHEETS / sheet).convert("RGB").crop(box)
    im = im.resize((round(im.width * scale), round(im.height * scale)),
                   Image.LANCZOS)
    im.save(out)
    return out


def paint(name: str, raw_dir: Path) -> str:
    piece = PIECES[name]
    w, h = piece["size"]
    refs = [reference(r, raw_dir) for r in piece["refs"]]
    if refs:
        result = openai_painter.paint_from(piece["prompt"], refs, w, h,
                                           piece["transparent"])
    else:
        result = openai_painter.paint(piece["prompt"], w, h,
                                      piece["transparent"], quality="high")
    if isinstance(result, str):
        return f"{name}: FAILED — {result}"
    (raw_dir / f"{name}.png").write_bytes(result)
    return f"{name}: painted"


def cut(name: str, raw_dir: Path) -> str:
    """Trims a transparent piece to its pixels and saves it; the backdrop is
    only re-encoded."""
    src = raw_dir / f"{name}.png"
    if not src.exists():
        return f"{name}: no raw painting"
    im = Image.open(src).convert("RGBA")
    if PIECES[name]["transparent"]:
        alpha = im.getchannel("A")
        # Drop the near-invisible haze some replies leave at the edges, so
        # the trim box is the drawing and not its fog.
        alpha = alpha.point(lambda a: 0 if a < 8 else a)
        im.putalpha(alpha)
        box = alpha.getbbox()
        if box is None:
            return f"{name}: reply was empty"
        pad = 6
        box = (max(0, box[0] - pad), max(0, box[1] - pad),
               min(im.width, box[2] + pad), min(im.height, box[3] + pad))
        im = im.crop(box)
    else:
        im = im.convert("RGB")
    # Plates are nine-patched, and a StyleBoxTexture draws its margins at
    # texture pixels, so a plate is cut at the size it is drawn at.
    height = PIECES[name].get("height")
    if height:
        im = im.resize((round(im.width * height / im.height), height),
                       Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    ext = PIECES[name].get("ext", "png")
    if ext == "webp":
        im.save(OUT / f"{name}.webp", quality=90, method=6)
    else:
        im.save(OUT / f"{name}.png", optimize=True)
    return f"{name}: {im.width}x{im.height}"


def set_title(text: str = "رازینو", px: int = 300) -> str:
    """The name in the sheet's chunky gold, set in type.

    Built in layers, back to front: a soft drop shadow, a thick navy
    outline, a thin bronze line inside it, then the letters filled with a
    gold gradient (pale at the top, deep amber at the foot) and a bright
    sheen across their upper half.
    """
    font = ImageFont.truetype(str(FONT), px)
    pad = px // 3
    probe = ImageDraw.Draw(Image.new("L", (1, 1)))
    l, t, r, b = probe.textbbox((0, 0), text, font=font, direction="rtl",
                                language="fa")
    w, h = r - l + pad * 2, b - t + pad * 2
    origin = (pad - l, pad - t)

    def mask(stroke: int) -> Image.Image:
        m = Image.new("L", (w, h), 0)
        ImageDraw.Draw(m).text(origin, text, font=font, fill=255,
                               stroke_width=stroke, stroke_fill=255,
                               direction="rtl", language="fa")
        return m

    def solid(colour: tuple, m: Image.Image) -> Image.Image:
        layer = Image.new("RGBA", (w, h), colour)
        layer.putalpha(m)
        return layer

    outer = px // 11
    inner = px // 30
    glyphs = mask(0)

    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = mask(outer).filter(ImageFilter.GaussianBlur(px // 25))
    out.alpha_composite(solid((0, 0, 0, 150), shadow), (0, px // 28))
    out.alpha_composite(solid((14, 22, 46, 255), mask(outer)))
    out.alpha_composite(solid((120, 70, 14, 255), mask(inner)))

    # Gold, top to bottom, over the glyphs' own height.
    top, foot = glyphs.getbbox()[1], glyphs.getbbox()[3]
    stops = [(0.0, (255, 241, 168)), (0.45, (250, 196, 64)),
             (0.75, (226, 142, 28)), (1.0, (168, 92, 16))]
    ramp = Image.new("RGBA", (1, h))
    for y in range(h):
        f = min(1.0, max(0.0, (y - top) / max(1, foot - top)))
        for (a, ca), (b_, cb) in zip(stops, stops[1:]):
            if a <= f <= b_:
                k = (f - a) / (b_ - a)
                ramp.putpixel((0, y), tuple(round(ca[i] + (cb[i] - ca[i]) * k)
                                            for i in range(3)) + (255,))
                break
    fill = ramp.resize((w, h))
    fill.putalpha(glyphs)
    out.alpha_composite(fill)

    # The sheen: a lighter band over the upper part of each letter, kept
    # inside the glyphs by multiplying the two masks.
    band = Image.new("L", (w, h), 0)
    ImageDraw.Draw(band).rectangle(
        (0, top, w, top + (foot - top) * 0.38), fill=110)
    band = band.filter(ImageFilter.GaussianBlur(px // 40))
    out.alpha_composite(solid((255, 255, 235, 255),
                              ImageChops.multiply(band, glyphs)))

    out = out.crop(out.getchannel("A").getbbox())
    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / "menu_title.png", optimize=True)
    return f"menu_title: {out.width}x{out.height}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", nargs="*", default=None)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--cut-only", action="store_true")
    ap.add_argument("--raw", default=str(Path.home() / ".razino" / "raw_menu"))
    args = ap.parse_args()

    raw = Path(args.raw)
    raw.mkdir(parents=True, exist_ok=True)
    names = [n for n in (args.only or PIECES) if n in PIECES]

    if not args.cut_only:
        todo = [n for n in names if args.force or not (raw / f"{n}.png").exists()]
        with ThreadPoolExecutor(max_workers=6) as pool:
            for line in pool.map(lambda n: paint(n, raw), todo):
                print(line, flush=True)
    for n in names:
        print(cut(n, raw))
    if args.only is None or "menu_title" in args.only:
        print(set_title())
    return 0


if __name__ == "__main__":
    sys.exit(main())

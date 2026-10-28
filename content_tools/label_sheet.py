#!/usr/bin/env python3
"""Sets real Persian onto a generated UI sheet.

An image model cannot write Persian. The approved mockup proves it: the
title on it reads «رازنتی», which is a mangling of «رازینو» — the model drew
letter shapes it had seen without knowing the word. In a Persian game for
children that is worse than no text at all.

So the sheet is generated with every label left as an empty bar, and the
words are set here in Vazirmatn through HarfBuzz, which shapes and joins
Persian correctly. The result is a mockup whose art came from the model and
whose writing came from a real font — better than either alone.

    python3 content_tools/label_sheet.py in.png out.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"

SNOW = (242, 246, 250)
GOLD = (238, 180, 62)
INK = (46, 34, 8)
DIM = (150, 170, 190)

## Every label on the sheet: (x, y, text, size, colour, bold, anchor).
##
## Positions are fractions of the sheet, so the same table works whatever
## size the sheet was generated at.
LABELS: list[tuple] = [
    # — main menu —
    (0.243, 0.093, "رازینو", 0.034, GOLD, True, "mm"),
    (0.243, 0.130, "ماجرا آغاز می‌شود", 0.013, SNOW, False, "mm"),
    # — world map, nav column —
    (0.487, 0.106, "جهان", 0.015, INK, True, "mm"),
    (0.487, 0.147, "ماموریت‌ها", 0.015, SNOW, False, "mm"),
    (0.487, 0.182, "مخفیگاه‌ها", 0.015, SNOW, False, "mm"),
    (0.487, 0.216, "تنظیمات", 0.015, SNOW, False, "mm"),
    # — world map, island plaques —
    (0.598, 0.129, "جنگل سبز", 0.013, SNOW, False, "mm"),
    (0.833, 0.127, "منطقهٔ کوهستانی", 0.012, SNOW, False, "mm"),
    (0.880, 0.215, "منطقهٔ نفرین‌شده", 0.012, SNOW, False, "mm"),
    (0.608, 0.258, "منطقهٔ بیابان", 0.012, SNOW, False, "mm"),
    (0.806, 0.272, "ویرانه‌های باستانی", 0.012, SNOW, False, "mm"),
    (0.870, 0.062, "۲۸۴۰", 0.013, SNOW, False, "mm"),
    (0.940, 0.062, "۱۲۵", 0.013, SNOW, False, "mm"),
    # — dialogue —
    (0.498, 0.513, "آیلین", 0.013, SNOW, True, "mm"),
    (0.498, 0.560, "به نظر می‌رسه بالاخره به اینجا رسیدیم.", 0.013, INK, False, "mm"),
    # — inventory —
    (0.745, 0.374, "همه", 0.012, INK, True, "mm"),
    (0.800, 0.374, "مصرفی", 0.012, SNOW, False, "mm"),
    (0.855, 0.374, "تجهیزات", 0.012, SNOW, False, "mm"),
    (0.908, 0.374, "مهم", 0.012, SNOW, False, "mm"),
    (0.945, 0.565, "استفاده", 0.013, INK, True, "mm"),
    # — character sheet —
    (0.103, 0.780, "فرهاد", 0.013, SNOW, True, "mm"),
    (0.103, 0.808, "سطح ۵", 0.011, GOLD, False, "mm"),
    # — quests —
    (0.418, 0.645, "اصلی", 0.012, INK, True, "mm"),
    (0.455, 0.645, "فرعی", 0.012, SNOW, False, "mm"),
    (0.497, 0.645, "تکمیل‌شده", 0.012, SNOW, False, "mm"),
    (0.455, 0.695, "راه به سوی شهر مرکزی", 0.013, SNOW, True, "mm"),
    (0.455, 0.757, "جمع‌آوری گیاهان دارویی", 0.013, SNOW, True, "mm"),
    (0.455, 0.818, "راز معبد باستانی", 0.013, DIM, True, "mm"),
    # — settings —
    (0.638, 0.645, "گرافیک", 0.012, INK, True, "mm"),
    (0.638, 0.700, "صدا", 0.012, SNOW, False, "mm"),
    (0.638, 0.752, "کنترل‌ها", 0.012, SNOW, False, "mm"),
    (0.638, 0.804, "زبان", 0.012, SNOW, False, "mm"),
    (0.740, 0.700, "VSync", 0.011, SNOW, False, "mm"),
    (0.740, 0.752, "افکت‌های ویژه", 0.011, SNOW, False, "mm"),
    (0.740, 0.804, "حالت تمام‌صفحه", 0.011, SNOW, False, "mm"),
    # — loading —
    (0.880, 0.893, "در حال بارگذاری…", 0.012, SNOW, False, "mm"),
]


def draw(sheet: Image.Image, labels: list[tuple]) -> Image.Image:
    out = sheet.convert("RGB")
    d = ImageDraw.Draw(out)
    w, h = out.size
    for x, y, text, size, colour, bold, anchor in labels:
        face = "Vazirmatn-Bold.ttf" if bold else "Vazirmatn-Medium.ttf"
        font = ImageFont.truetype(str(FONTS / face), max(9, int(h * size)))
        # A soft dark edge under light text, so a label sitting on painted
        # art stays readable without a plate behind it.
        if colour != INK:
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                d.text((x * w + dx, y * h + dy), text, font=font,
                       fill=(4, 12, 20), anchor=anchor, language="fa")
        d.text((x * w, y * h), text, font=font, fill=colour,
               anchor=anchor, language="fa")
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source")
    ap.add_argument("dest")
    args = ap.parse_args()
    out = draw(Image.open(args.source), LABELS)
    out.save(args.dest)
    print(f"{len(LABELS)} labels set on {args.dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

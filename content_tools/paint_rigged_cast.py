"""Paints the cast in the one pose that can be cut into a rig.

The first painted cast cannot be rigged: those figures are chibi with their
arms tucked against the body, so the silhouette has no gap to cut a limb
along, and every attempt came out as a rectangle sliced across the chest.
The hero that CAN be rigged came from this backend with this exact wording,
and the difference is entirely in the pose: arms hanging clear of the body,
legs apart, standing straight on, nothing overlapping.

Two things about the wording are load-bearing and should not be "improved":

  · "arms relaxed at his sides" is what opens the gap under the armpit. Ask
    for a pose, an action or a three-quarter view and the arms come back
    against the body and the figure is unriggable again.
  · anything describing a child's body, back view or stride is refused by
    this model's safety filter as unsafe. It is a false positive and there
    is no appeal, so the prompts stay plain and frontal.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_ui_art import ACCOUNTS_DEFAULT, Pool, load_accounts, paint

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "cast_rigged"

STYLE = ("Children's storybook game character art, chibi proportions, big head, "
         "soft cel shading, clean dark outline, warm colours, full body, "
         "plain flat white background, no shadow, no text.")

POSE = ("Standing straight, seen from the front, facing the viewer, "
        "arms relaxed at his sides and clear of the body, feet apart.")
POSE_F = ("Standing straight, seen from the front, facing the viewer, "
          "arms relaxed at her sides and clear of the body, feet apart.")

CAST = {
    "raha": (POSE_F, "A clever 11-year-old girl with long wavy red hair, round "
             "glasses, a mint-green jacket over a white shirt, brown boots and "
             "a satchel."),
    "mani": (POSE, "A cheerful 10-year-old boy with short sandy hair, a mustard "
             "waistcoat over a cream shirt, short trousers and a tool belt."),
    "fandogh": ("Standing on its hind legs, seen from the front, facing the "
                "viewer, little arms out clear of its body.",
                "A small friendly cartoon dinosaur, bright blue with a pale "
                "belly, round eyes, tiny horns, a red neckerchief and a little "
                "backpack."),
    "player": (POSE_F, "A curious 11-year-old girl with dark brown braided hair, "
               "a teal hooded coat, grey trousers and sturdy boots."),
    "azimi": (POSE_F, "A kind woman teacher in her fifties with grey hair in a "
              "bun, round glasses, a long navy cardigan and a grey skirt."),
    "modir": (POSE, "A stern school principal, a man in his sixties with "
              "silver hair, a dark blue suit and a pocket watch chain."),
}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    pool = Pool(load_accounts(ACCOUNTS_DEFAULT))
    made = 0
    for name, (pose, who) in CAST.items():
        if args.only and args.only != name:
            continue
        out = paint(pool, f"{who} {pose}", 768, 1024, style=STYLE)
        if isinstance(out, str):
            print(f"{name:9s} FAILED {out[:120]}")
            continue
        (args.out / f"{name}_source_raw.png").write_bytes(out)
        print(f"{name:9s} ok {len(out) // 1024} KB")
        made += 1
    print(f"\n{made} painted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

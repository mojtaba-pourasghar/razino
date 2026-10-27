#!/usr/bin/env python3
"""Paints the interface itself: frames, panels, plaques, buttons and icons.

The screens were drawn in code, and code cannot make painted metal, leaf
ornament or paper texture — only clean geometry. The approved sheets are
paintings all the way down, so the way to match them is to paint the
interface too and let Godot stretch it, rather than to draw a better
approximation of it.

Two post-processing steps do the heavy lifting:

  symmetry  A generated ornament is never symmetric, and an asymmetric plate
            tiles badly as a nine-patch. Mirroring one quadrant into the
            other three makes it exactly symmetric, so the corners match and
            the edges stretch cleanly.

  keying    The model cannot produce transparency, so icons are painted on
            flat magenta and that colour is removed afterwards.

    python3 content_tools/generate_ui_art.py --dry-run
    python3 content_tools/generate_ui_art.py --only frame
"""

from __future__ import annotations

import house_style

import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "ui"

MODEL = "@cf/leonardo/lucid-origin"
ACCOUNTS_DEFAULT = Path.home() / ".razino" / "cf_accounts.json"
TIMEOUT = 300

## Icons are painted on a flat backdrop and keyed out afterwards. The ask is
## for magenta because nothing in this palette comes near it — but the model
## treats that loosely and returns anything from hot pink to dark maroon, so
## the backdrop colour is read off the finished image rather than assumed.
KEY_HINT = (255, 0, 255)

## Characters need a different brief from chrome. Asking for them under the
## interface style produced a tiny cast inside an ornate frame, because that
## style asks for frames.
CAST_STYLE = house_style.cast()

STYLE = house_style.interface()

# — plates ————————————————————————————————————————————————
#
# Each is generated square, made symmetric, and used as a nine-patch. The
# margin is the fraction of the image the corner ornament occupies; Godot
# keeps that and stretches the middle.
PLATES = [
    ("panel", 0.30,
     "A single ornate rectangular panel plate seen flat from the front: a "
     "polished gold border framing a field of VERY DARK NAVY BLUE, almost "
     "black, completely plain and unlit. Scrollwork and small gold leaves "
     "ONLY at the four corners, perfectly plain smooth gold along the "
     "straight edges between them. Centered, filling the frame edge to "
     "edge, nothing else."),
    ("plaque", 0.34,
     "A single ornate gold name plaque seen flat from the front: a polished "
     "gold frame with a flourish at each end, framing a plain dark navy "
     "field. Centered, filling the frame edge to edge, nothing else."),
    ("button_action", 0.34,
     "A single ornate game button seen flat from the front: a polished gold "
     "frame with small corner diamonds around a glossy petrol-teal face "
     "lit from above. Centered, filling the frame, nothing else."),
    ("button_quiet", 0.34,
     "A single ornate game button seen flat from the front: a thin polished "
     "gold frame around a dark navy face. Centered, filling the frame, "
     "nothing else."),
    ("parchment", 0.26,
     "A single aged parchment card seen flat from the front: warm cream "
     "paper with soft fibre texture and slightly darker edges, inside a "
     "thin gold rule. Centered, filling the frame, nothing else."),
    ("well", 0.26,
     "A single sunken panel seen flat from the front: a very dark teal "
     "recess with a thin gold rim catching light along the top edge. "
     "Centered, filling the frame, nothing else."),
]

# Pieces of the start screen. The vista and the cast are painted separately
# so the characters can sit in front of the parallax rather than inside it,
# and so either can be repainted without the other.
SPLASH = [
    ("splash_vista", 1280, 720,
     "A sweeping fairytale valley at golden sunrise seen from a flowering "
     "hilltop path: a tall blue-roofed castle among waterfalls on the left, "
     "a dense town of steep tiled roofs and a clock tower on the right, "
     "snow-capped mountains behind, hot air balloons in a bright blue sky "
     "with soft clouds, a river and a stone bridge below, leafy branches "
     "overhanging the top corners, flowers along the foreground path. "
     "Nobody in the picture, no people, no characters."),
    ("splash_cast", 1024, 768,
     "Five cheerful cartoon children standing together in a row with a "
     "small friendly blue dragon in the middle: a girl with long red hair "
     "and round glasses, a boy with curly brown hair, the blue dragon "
     "wearing a red scarf, a girl with dark curly hair in bunches, a boy "
     "with black hair and glasses. All wearing adventure backpacks, all "
     "smiling, full body, standing on nothing, centered on a plain flat "
     "solid magenta background, the background one single even colour"),
    ("logo_cartouche", 1024, 640,
     "One ornate golden oval cartouche floating alone in the middle of the "
     "picture, small, with a wide empty margin of flat magenta all around "
     "it on every side: thick polished gold scrollwork with small star "
     "points around the rim and a blue compass rose medallion mounted on "
     "top centre. The inside of the oval is the same flat magenta. One "
     "single even magenta colour everywhere except the gold. No outer "
     "frame, no border, no background scenery, nothing written."),
]

# The screen border is not a nine-patch: it is one painted overlay whose
# middle is keyed out, so the art behind it shows through.
BORDERS = [
    ("screen_frame", 1280, 720,
     "An ornate rectangular picture frame seen flat from the front, filling "
     "the whole image: a NARROW, SLIM polished gold border no thicker than "
     "a thumb, with scrollwork and a small jewel at each corner only. The "
     "vast centre is solid flat magenta, one completely even colour, "
     "totally empty. Nothing at all inside the frame."),
]

# — icons ——————————————————————————————————————————————————
#
# Each is a single object, painted on flat magenta, keyed to transparency.
ICONS = [
    ("coin", "a single shiny gold coin with a star stamped on it, seen face on"),
    ("gem", "a single faceted bright blue gemstone"),
    ("key", "a single ornate golden key"),
    ("lock", "a single closed golden padlock"),
    ("backpack", "a single blue leather adventurer's backpack with gold buckles"),
    ("book", "a single closed brown leather book with gold corners"),
    ("scroll", "a single rolled parchment scroll tied with a red ribbon"),
    ("map", "a single folded old treasure map"),
    ("compass", "a single golden compass with a blue needle, seen face on"),
    ("gear", "a single polished brass gear wheel, seen face on"),
    ("bell", "a single golden hand bell"),
    ("trophy", "a single golden trophy cup"),
    ("star", "a single five pointed gold star"),
    ("heart", "a single glossy red heart"),
    ("potion", "a single round glass bottle of glowing teal liquid with a cork"),
    ("magnifier", "a single magnifying glass with a gold rim and a wooden handle"),
    ("lamp", "a single golden lantern with warm light inside"),
    ("music", "a single gold musical note"),
    ("speaker", "a single gold loudspeaker emitting two sound waves"),
    ("globe", "a single gold globe with meridian lines"),
    ("friend", "a single gold silhouette of a person's head and shoulders"),
    ("chat", "a single gold speech bubble"),
    ("shield", "a single gold shield with a teal centre"),
    ("box", "a single wooden treasure chest with gold bands, lid closed"),
    ("check", "a single thick gold tick mark"),
    ("download", "a single gold downward arrow above a short gold bar"),
    ("clock", "a single round gold pocket watch, seen face on"),
    ("home", "a single small cottage with a red roof"),
    ("play", "a single gold triangular play arrow"),
    ("pencil", "a single wooden pencil with a gold tip"),
]

ICON_SIZE = 512


class Pool:
    """The Cloudflare accounts, rotated, with exhausted ones set aside."""

    def __init__(self, accounts: list[dict]):
        self.accounts = list(accounts)
        self.exhausted: set[str] = set()
        self._next = 0

    @property
    def alive(self) -> list[dict]:
        return [a for a in self.accounts if a["name"] not in self.exhausted]

    def take(self) -> dict | None:
        alive = self.alive
        if not alive:
            return None
        acc = alive[self._next % len(alive)]
        self._next += 1
        return acc

    def retire(self, acc: dict, why: str) -> None:
        self.exhausted.add(acc["name"])
        print(f"    account {acc['name']} out ({why}); {len(self.alive)} left", flush=True)


def load_accounts(path: Path) -> list[dict]:
    if not path.exists():
        raise SystemExit(
            f"no Cloudflare accounts file at {path}\n"
            f"write a JSON list of {{name, account, token}} there, or set "
            f"RAZINO_CF_ACCOUNTS to its path"
        )
    return json.loads(path.read_text(encoding="utf-8"))


def request_image(acc: dict, prompt: str, width: int, height: int) -> bytes:
    body = json.dumps({"prompt": prompt, "width": width, "height": height}).encode()
    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/accounts/{acc['account']}/ai/run/{MODEL}",
        data=body,
        headers={"Authorization": f"Bearer {acc['token']}",
                 "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        content_type = r.headers.get("Content-Type", "")
        raw = r.read()
    if "json" in content_type:
        payload = json.loads(raw)
        image = (payload.get("result") or {}).get("image")
        if not image:
            raise RuntimeError(json.dumps(payload)[:200])
        raw = base64.b64decode(image)
    return raw


# — post-processing ————————————————————————————————————————

def make_symmetric(img: Image.Image) -> Image.Image:
    """Mirrors the top-left quadrant into the other three.

    A generated ornament is never symmetric, and an asymmetric plate shows
    it the moment Godot stretches it into a different aspect ratio. This
    costs a little of the painting's variety and buys a plate that tiles.
    """
    w, h = img.size
    qw, qh = w // 2, h // 2
    q = img.crop((0, 0, qw, qh))
    out = Image.new(img.mode, (qw * 2, qh * 2))
    out.paste(q, (0, 0))
    out.paste(q.transpose(Image.FLIP_LEFT_RIGHT), (qw, 0))
    out.paste(q.transpose(Image.FLIP_TOP_BOTTOM), (0, qh))
    out.paste(q.transpose(Image.ROTATE_180), (qw, qh))
    return out


def key_out(img: Image.Image, where: str = "corners",
            tolerance: float = 70.0) -> Image.Image:
    """Removes the flat backdrop a piece was painted on.

    Done by flooding inward from the border rather than by matching a
    colour. A colour key fails whenever the subject shares a channel range
    with the backdrop — a gold coin on a wine background lost half of
    itself, because its own shadows sat closer to the backdrop than the
    threshold allowed. The backdrop is the region connected to the edge;
    the subject is not, whatever colour either happens to be.
    """
    rgb = img.convert("RGB")
    w, h = rgb.size
    work = rgb.copy()
    # A sentinel no painting will contain, so the filled region is findable.
    sentinel = (1, 254, 2)
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
             (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]
    if where == "centre":
        seeds = [(w // 2, h // 2)]
    for seed in seeds:
        ImageDraw.floodfill(work, seed, sentinel, thresh=tolerance)

    arr = np.asarray(work, dtype=np.int16)
    filled = (np.abs(arr - np.array(sentinel)).sum(axis=2) < 12)
    alpha = np.where(filled, 0, 255).astype(np.uint8)

    mask = Image.fromarray(alpha, "L")
    # The backdrop bleeds a pixel or two into the antialiased edge, and the
    # flood stops just short of it. Eroding takes that band off.
    mask = mask.filter(ImageFilter.MinFilter(3))
    mask = mask.filter(ImageFilter.GaussianBlur(0.7))

    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def hollow(img: Image.Image) -> Image.Image:
    """Empties the inside of a border, leaving the border itself intact.

    Keying the centre by colour fought the painting on both sides: the
    field comes back as a shaded magenta whose darker corners read as a
    different colour, while the corner jewels are magenta on purpose and
    got removed with it. A border is a geometric thing, so the inside is
    cut geometrically — find the field, inset a little, and empty the
    rectangle. Clean edges, and nothing outside it is touched.
    """
    arr = np.asarray(img.convert("RGB"), dtype=np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    field = (r > 60) & (b > 35) & (g < np.minimum(r, b) * 0.85)
    out = img.convert("RGBA")
    if not field.any():
        return out

    # Only the field around the centre counts. The frame's corner jewels
    # are magenta on purpose, and the bounding box of every magenta pixel
    # stretched to the whole image and ate the frame. Walking out from the
    # middle until the field ends finds the rectangle and cannot reach them.
    h, w = field.shape
    cy, cx = h // 2, w // 2
    if not field[cy, cx]:
        return out
    x0 = cx
    while x0 > 0 and field[cy, x0 - 1]:
        x0 -= 1
    x1 = cx
    while x1 < w - 1 and field[cy, x1 + 1]:
        x1 += 1
    y0 = cy
    while y0 > 0 and field[y0 - 1, cx]:
        y0 -= 1
    y1 = cy
    while y1 < h - 1 and field[y1 + 1, cx]:
        y1 += 1

    # Pulled in so the gold rebate around the field survives.
    inset = max(4, int(min(img.size) * 0.012))
    x0, x1 = x0 + inset, x1 - inset
    y0, y1 = y0 + inset, y1 - inset
    if x1 <= x0 or y1 <= y0:
        return out
    alpha = np.asarray(out)[:, :, 3].copy()
    alpha[y0:y1 + 1, x0:x1 + 1] = 0
    mask = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(0.6))
    out.putalpha(mask)
    return out


def trim(img: Image.Image, pad: int = 8) -> Image.Image:
    box = img.getbbox()
    if box is None:
        return img
    x0, y0, x1, y1 = box
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
    x1, y1 = min(img.width, x1 + pad), min(img.height, y1 + pad)
    return img.crop((x0, y0, x1, y1))


def save_png(img: Image.Image, name: str) -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / f"{name}.png"
    img.save(out)
    return out


def style_for(name: str) -> str:
    return CAST_STYLE if name == "splash_cast" else STYLE


def paint(pool: Pool, prompt: str, w: int, h: int, style: str = "") -> bytes | str:
    """Tries each live account. Returns the PNG bytes, or a reason string."""
    style = style or STYLE
    last = "no account available"
    for _ in range(max(3, len(pool.alive))):
        acc = pool.take()
        if acc is None:
            return "quota"
        try:
            return request_image(acc, f"{style} {prompt}", w, h)
        except urllib.error.HTTPError as e:
            detail = e.read()[:220].decode("utf-8", "replace").replace("\n", " ")
            if e.code == 429:
                pool.retire(acc, "daily free allowance spent")
                last = "quota"
                continue
            last = f"HTTP {e.code}: {detail[:150]}"
            if e.code == 400:
                return last
            time.sleep(3)
        except Exception as e:  # noqa: BLE001 — report, never abort the run
            last = f"{type(e).__name__}: {str(e)[:150]}"
            time.sleep(3)
    return last


def jobs(only: str) -> list[tuple]:
    out: list[tuple] = []
    for name, margin, prompt in PLATES:
        out.append(("plate", name, 768, 768, prompt, margin))
    for name, w, h, prompt in BORDERS:
        out.append(("border", name, w, h, prompt, 0.0))
    for name, w, h, prompt in SPLASH:
        # The vista is a plain painting; the cast and the cartouche are cut
        # out so what is behind them shows through.
        # A cutout is keyed and trimmed like an icon but kept at full size:
        # the cast fills a third of the start screen, so shrinking it to
        # icon size left it blurry.
        kind = "scene" if name == "splash_vista" else (
            "border" if name == "logo_cartouche" else "cutout")
        out.append((kind, name, w, h, prompt, 0.0))
    for name, prompt in ICONS:
        out.append(("icon", f"icon_{name}", ICON_SIZE, ICON_SIZE,
                    f"{prompt}, centered on a plain flat solid magenta "
                    f"background, the background one single even colour", 0.0))
    if only:
        out = [j for j in out if only in j[1]]
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--accounts", default=os.environ.get("RAZINO_CF_ACCOUNTS", str(ACCOUNTS_DEFAULT)))
    ap.add_argument("--only", default="", help="only names containing this text")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--force", action="store_true", help="repaint what already exists")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    todo = jobs(args.only)
    if not args.force:
        todo = [j for j in todo if not (OUT / f"{j[1]}.png").exists()]
    if args.limit:
        todo = todo[:args.limit]
    if not todo:
        print("nothing to paint — the interface art is complete")
        return 0

    if args.dry_run:
        for kind, name, w, h, prompt, margin in todo:
            print(f"--- {name} ({kind}, {w}x{h}, margin {margin})")
            print(f"{style_for(name)} {prompt}\n")
        return 0

    pool = Pool(load_accounts(Path(args.accounts)))
    print(f"{len(todo)} pieces, {len(pool.accounts)} account(s)\n")

    margins: dict[str, float] = {}
    marg_file = OUT / "nine_patch.json"
    if marg_file.exists():
        margins = json.loads(marg_file.read_text())

    painted = failed = 0
    for kind, name, w, h, prompt, margin in todo:
        print(f"  {name:22s} ", end="", flush=True)
        result = paint(pool, prompt, w, h, style_for(name))
        if result == "quota":
            print("— every account has spent its daily allowance; stopping")
            break
        if isinstance(result, str):
            print(f"FAILED {result}")
            failed += 1
            continue

        tmp = OUT / f"{name}.raw.png"
        OUT.mkdir(parents=True, exist_ok=True)
        tmp.write_bytes(result)
        img = Image.open(tmp).convert("RGB")
        tmp.unlink(missing_ok=True)

        if kind == "scene":
            out = save_png(img, name)
        elif kind == "plate":
            img = make_symmetric(img)
            out = save_png(img, name)
            margins[name] = margin
        elif kind == "border":
            keyed = hollow(img)
            out = save_png(keyed, name)
        elif kind == "cutout":
            out = save_png(trim(key_out(img, "corners", 42.0)), name)
        else:
            keyed = trim(key_out(img, "corners", 42.0))
            keyed.thumbnail((256, 256), Image.LANCZOS)
            out = save_png(keyed, name)

        print(f"ok {out.stat().st_size / 1024:6.0f} KB")
        painted += 1
        marg_file.write_text(json.dumps(margins, indent=2))
        time.sleep(1)

    print(f"\npainted {painted}, failed {failed}")
    return 1 if failed and not painted else 0


if __name__ == "__main__":
    raise SystemExit(main())

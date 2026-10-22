#!/usr/bin/env python3
"""Paints the art in the catalog, through Cloudflare Workers AI.

Resumable by design: it skips anything already on disk and writes each image
the moment it arrives, so a run cut short by a quota wall, a timeout or a
closed session loses nothing. Run it again tomorrow and it carries on.

Credentials never live in the repository. Point RAZINO_CF_ACCOUNTS at a JSON
file holding a list of {name, account, token}; the free allowance is per
account, so several accounts are simply several allowances and the runner
rotates through them, dropping any that answers 429 for the rest of the run.

    python3 content_tools/generate_art.py --dry-run
    python3 content_tools/generate_art.py --limit 12
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

from art_catalog import STYLE, catalog  # noqa: E402

MODEL = "@cf/leonardo/lucid-origin"
ACCOUNTS_DEFAULT = Path.home() / ".razino" / "cf_accounts.json"
TIMEOUT = 300

# WebP quality for the shipped file. 82 keeps a painted background clean at
# phone size while staying well under a megabyte.
WEBP_QUALITY = "82"


class Pool:
    """The Cloudflare accounts, rotated, with exhausted ones set aside.

    The free allowance is counted per account per day, so the only way to
    paint more than a handful in one sitting is to spread the work. An
    account that answers 429 is out for the rest of the run, not retried —
    its allowance does not come back before tomorrow.
    """

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
        left = len(self.alive)
        print(f"    account {acc['name']} out ({why}); {left} left", flush=True)


def load_accounts(path: Path) -> list[dict]:
    if not path.exists():
        raise SystemExit(
            f"no Cloudflare accounts file at {path}\n"
            f"write a JSON list of {{name, account, token}} there, or set "
            f"RAZINO_CF_ACCOUNTS to its path"
        )
    accounts = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(accounts, list) or not accounts:
        raise SystemExit(f"{path} must hold a non-empty JSON list")
    for a in accounts:
        for key in ("name", "account", "token"):
            if key not in a:
                raise SystemExit(f"{path}: an entry is missing '{key}'")
    return accounts


def request_image(acc: dict, prompt: str, width: int, height: int) -> bytes:
    """One call. Raises urllib.error.HTTPError so the caller can read the code."""
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


def to_webp(png: bytes, out: Path, width: int, height: int) -> None:
    """Writes the shipped WebP, scaled to the slot it is drawn in."""
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_suffix(".tmp.png")
    tmp.write_bytes(png)
    try:
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(tmp),
             "-vf", f"scale={width}:{height}:force_original_aspect_ratio=increase,"
                    f"crop={width}:{height}",
             "-q:v", WEBP_QUALITY, str(out)],
            check=True,
        )
    finally:
        tmp.unlink(missing_ok=True)


def paint(pool: Pool, job: dict, retries: int = 3) -> str:
    """Tries each live account in turn. Returns 'ok', 'quota' or an error."""
    prompt = f"{STYLE} {job['prompt']}"
    last = "no account available"
    for _ in range(max(retries, len(pool.alive))):
        acc = pool.take()
        if acc is None:
            return "quota"
        try:
            png = request_image(acc, prompt, job["width"], job["height"])
            to_webp(png, ROOT / job["target"], job["width"], job["height"])
            return "ok"
        except urllib.error.HTTPError as e:
            detail = e.read()[:300].decode("utf-8", "replace").replace("\n", " ")
            if e.code == 429:
                pool.retire(acc, "daily free allowance spent")
                last = "quota"
                continue
            last = f"HTTP {e.code}: {detail[:160]}"
            # A content filter or a bad size is the prompt's fault, not the
            # account's — another account would answer the same way.
            if e.code == 400:
                return last
            time.sleep(3)
        except Exception as e:  # noqa: BLE001 — report, never abort the run
            last = f"{type(e).__name__}: {str(e)[:160]}"
            time.sleep(3)
    return last


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--accounts", default=os.environ.get("RAZINO_CF_ACCOUNTS", str(ACCOUNTS_DEFAULT)))
    ap.add_argument("--limit", type=int, default=0, help="stop after N paintings")
    ap.add_argument("--only", default="", help="only ids containing this text")
    ap.add_argument("--kind", default="", help="only this kind (ui, region, background, thumbnail)")
    ap.add_argument("--dry-run", action="store_true", help="print prompts, call nothing")
    args = ap.parse_args()

    jobs = [j for j in catalog() if not j["done"]]
    if args.only:
        jobs = [j for j in jobs if args.only in j["id"]]
    if args.kind:
        jobs = [j for j in jobs if j["kind"] == args.kind]
    if args.limit:
        jobs = jobs[:args.limit]

    if not jobs:
        print("nothing to paint — the catalog is complete")
        return 0

    if args.dry_run:
        for j in jobs:
            print(f"--- {j['id']} ({j['width']}x{j['height']}) -> {j['target']}")
            print(f"{STYLE} {j['prompt']}\n")
        return 0

    accounts_path = Path(args.accounts)
    if not accounts_path.is_absolute():
        accounts_path = ROOT / accounts_path
    pool = Pool(load_accounts(accounts_path))
    print(f"{len(jobs)} to paint, {len(pool.accounts)} account(s)\n")

    painted = failed = 0
    for j in jobs:
        print(f"  {j['id']:28s} ", end="", flush=True)
        result = paint(pool, j)
        if result == "ok":
            size = (ROOT / j["target"]).stat().st_size / 1024
            print(f"ok {size:6.0f} KB")
            painted += 1
        elif result == "quota":
            print("— every account has spent its daily allowance; stopping")
            break
        else:
            print(f"FAILED {result}")
            failed += 1
        time.sleep(1)

    remaining = sum(1 for j in catalog() if not j["done"])
    print(f"\npainted {painted}, failed {failed}, {remaining} still missing")
    return 1 if failed and not painted else 0


if __name__ == "__main__":
    raise SystemExit(main())

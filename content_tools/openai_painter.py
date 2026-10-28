"""Painting through OpenAI's image API.

A second backend beside the Cloudflare one. The interface is the same single
call — give it a prompt and a size, get PNG bytes back — so every tool that
paints can use either without knowing which.

Two things make this one worth paying for, both of which cost real work on
the free backend:

  · it returns a REAL ALPHA CHANNEL. The whole magenta-key, flood-fill and
    rind-strip pipeline exists only because Cloudflare cannot, and every
    step of it loses a little of the edge.
  · it follows an instruction about what NOT to draw. Whether that extends
    to "leave the rest of the picture empty" is the one thing this project
    still has to find out, and it is tested first and alone.

The key lives at ~/.razino/openai.key, outside the repository. It is never
read into a commit, a log line or an error message.
"""

from __future__ import annotations

import base64
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

KEY_PATH = Path.home() / ".razino" / "openai.key"
URL = "https://api.openai.com/v1/images/generations"
EDIT_URL = "https://api.openai.com/v1/images/edits"

## The current image model. gpt-image-1 was retired in October 2026.
MODEL = "gpt-image-1.5"

## Sizes the API accepts. Anything else is rounded up to the nearest, and
## the tool crops afterwards — asking for an unsupported size is an error,
## not a resize.
SIZES = [(1024, 1024), (1024, 1536), (1536, 1024)]


def _key() -> str:
    env = os.environ.get("OPENAI_API_KEY", "").strip()
    if env:
        return env
    if not KEY_PATH.exists():
        raise SystemExit(
            f"no OpenAI key at {KEY_PATH} and OPENAI_API_KEY is unset")
    return KEY_PATH.read_text(encoding="utf-8").strip()


def best_size(width: int, height: int) -> str:
    """The supported size closest in shape to what was asked for."""
    want = width / max(1, height)
    best = min(SIZES, key=lambda s: abs(s[0] / s[1] - want))
    return f"{best[0]}x{best[1]}"


def paint(prompt: str, width: int = 1024, height: int = 1024,
          transparent: bool = False, quality: str = "medium") -> bytes | str:
    """PNG bytes, or a short reason the call failed.

    Returns the reason rather than raising, because every caller is a batch
    that has to carry on to the next piece — one refusal must not end a run
    that has already been paid for.
    """
    body: dict = {
        "model": MODEL,
        "prompt": prompt,
        "size": best_size(width, height),
        "quality": quality,
        "n": 1,
    }
    if transparent:
        # The API only honours transparency on a format that has an alpha
        # channel at all.
        body["background"] = "transparent"
        body["output_format"] = "png"

    req = urllib.request.Request(
        URL, data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {_key()}",
                 "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            payload = json.loads(r.read())
    except urllib.error.HTTPError as e:
        detail = e.read()[:300].decode("utf-8", "replace").replace("\n", " ")
        return f"HTTP {e.code}: {detail}"
    except Exception as e:  # noqa: BLE001 — report, never end the batch
        return f"{type(e).__name__}: {str(e)[:160]}"

    data = payload.get("data") or []
    if not data or "b64_json" not in data[0]:
        return f"no image in the reply: {str(payload)[:200]}"
    return base64.b64decode(data[0]["b64_json"])


def usage_line(payload: dict) -> str:
    """What a call cost, when the API says."""
    u = payload.get("usage") or {}
    return ", ".join(f"{k}={v}" for k, v in u.items()) or "not reported"


def paint_from(prompt: str, references: list[Path], width: int = 1024,
               height: int = 1024, transparent: bool = False,
               quality: str = "high") -> bytes | str:
    """Like paint(), but the model sees reference pictures first.

    This is how the cast stays the same children from picture to picture:
    the approved character sheets go in as references, so the model draws
    those faces rather than inventing four new ones from a description.
    """
    boundary = "----razino" + base64.b16encode(os.urandom(8)).decode()
    fields: list[tuple[str, str]] = [
        ("model", MODEL), ("prompt", prompt), ("n", "1"),
        ("size", best_size(width, height)), ("quality", quality),
        ("input_fidelity", "high"),
    ]
    if transparent:
        fields += [("background", "transparent"), ("output_format", "png")]
    body = bytearray()
    for name, value in fields:
        body += (f"--{boundary}\r\nContent-Disposition: form-data; "
                 f"name=\"{name}\"\r\n\r\n{value}\r\n").encode()
    for ref in references:
        mime = "image/webp" if ref.suffix == ".webp" else "image/png"
        body += (f"--{boundary}\r\nContent-Disposition: form-data; "
                 f"name=\"image[]\"; filename=\"{ref.name}\"\r\n"
                 f"Content-Type: {mime}\r\n\r\n").encode()
        body += ref.read_bytes() + b"\r\n"
    body += f"--{boundary}--\r\n".encode()

    req = urllib.request.Request(
        EDIT_URL, data=bytes(body),
        headers={"Authorization": f"Bearer {_key()}",
                 "Content-Type": f"multipart/form-data; boundary={boundary}"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            payload = json.loads(r.read())
    except urllib.error.HTTPError as e:
        detail = e.read()[:300].decode("utf-8", "replace").replace("\n", " ")
        return f"HTTP {e.code}: {detail}"
    except Exception as e:  # noqa: BLE001 — report, never end the batch
        return f"{type(e).__name__}: {str(e)[:160]}"

    data = payload.get("data") or []
    if not data or "b64_json" not in data[0]:
        return f"no image in the reply: {str(payload)[:200]}"
    return base64.b64decode(data[0]["b64_json"])

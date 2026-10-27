"""The one description of how Razino looks.

Two tools paint: `generate_ui_art.py` for the interface and `generate_art.py`
for the scenes. They used to carry a style paragraph each, which is two
descriptions of one look — and two descriptions of one thing drift apart. The
chapter backgrounds slowly stopped matching the menus they sit behind.

The approved sheets are in `assets/art/reference/`. They are not an
inspiration folder: they are the specification. Everything here is read off
them, so when a prompt and a sheet disagree, the sheet is right and this file
is the bug.

    sheet_four_screens.webp  profile, settings, in-game, notifications
    sheet_splash.webp        the start screen and the cast
"""

from __future__ import annotations

## What every painting in this game shares, whoever asked for it.
HOUSE = (
    "2D hand-painted storybook art for a premium children's adventure game, "
    "in the polished style of a high-end animated film. Clean confident "
    "edges, soft painterly shading, rich saturated colour, warm golden light "
    "against deep teal and navy shadow. Cheerful and inviting, never grim, "
    "never gritty, never photorealistic, never flat vector, never 3D render."
)

## The colours the sheets actually use, named so a prompt cannot wander off
## into purple or grey.
PALETTE = (
    "Palette: polished warm gold with bright highlights and deep bronze "
    "shadow, deep navy and petrol teal, cream parchment, and small accents "
    "of ruby, emerald and sky blue."
)

## Image models love to write. In a Persian game a line of invented Latin
## signage is worse than nothing, because a child reads it as a mistake.
NO_TEXT = (
    "Absolutely no text, no letters, no words, no numbers, no signage with "
    "writing, no captions, no labels, no watermark, no logo."
)


def interface(extra: str = "") -> str:
    """The brief for a piece of interface chrome: a frame, a plate, an icon."""
    return " ".join(filter(None, [
        HOUSE,
        "Ornate gilded game interface art: polished gold metal frames with "
        "scrollwork and small green leaf sprigs at the corners, around fields "
        "of deep navy or cream parchment.",
        PALETTE, extra, NO_TEXT,
    ]))


def scene(extra: str = "") -> str:
    """The brief for a place the story happens in."""
    return " ".join(filter(None, [
        HOUSE,
        "A place, painted as a film background: deep space, believable light, "
        "detail that rewards looking.",
        PALETTE, extra, NO_TEXT,
        "No user interface, no frames, no borders, no picture frame edges.",
    ]))


def cast(extra: str = "") -> str:
    """The brief for a character.

    The sheets draw children aged roughly eight to twelve: large expressive
    eyes, friendly open faces, modern everyday clothes and a backpack — not
    armour, not fantasy costume. Getting this wrong is expensive, because
    every one of a character's five mood cells is painted from their sheet.
    """
    return " ".join(filter(None, [
        HOUSE,
        "A character: a cheerful child of about ten, large expressive eyes, "
        "friendly open face, modern everyday clothes and a school backpack. "
        "Full body head to toe, filling the frame, facing the viewer.",
        PALETTE, extra,
        "No frame, no border, no ornament, no scenery, no ground, no shadow.",
        NO_TEXT,
    ]))

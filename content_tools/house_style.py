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


## What a figure painted for the stage must not carry, whoever it is: the
## engine cuts it out and places it on a scene, so any frame, ground or
## shadow in the painting arrives as a rectangle floating in the air.
CUTOUT = (
    "Centered on a plain flat solid magenta background, the background one "
    "single even colour. No frame, no border, no ornament, no scenery, "
    "no ground, no shadow."
)


def creature(extra: str = "") -> str:
    """The brief for an animal character, which is not a child in a backpack."""
    return _figure(
        "a small friendly cartoon animal for a children's game, appealing and "
        "rounded, with large expressive eyes", extra)


def cast(extra: str = "") -> str:
    """The brief for a character.

    The sheets draw children aged roughly eight to twelve: large expressive
    eyes, friendly open faces, modern everyday clothes and a backpack — not
    armour, not fantasy costume. Getting this wrong is expensive, because
    every one of a character's five mood cells is painted from their sheet.
    """
    return _figure(
        "a cheerful cartoon child of about ten, with large expressive eyes "
        "and a friendly open face, in modern everyday clothes", extra)


def _figure(who: str, extra: str) -> str:
    """One figure, cut out, nothing else in the picture.

    The subject leads and the style follows. An earlier version opened with
    the house paragraph and the interface palette, and the model painted five
    ornate empty picture frames: given gold and parchment before it was given
    a child, it painted the gold and the parchment. The palette is left out
    here on purpose — a character's colours are in their own description.
    """
    return " ".join(filter(None, [
        f"A full-body character cutout of {who}.", extra,
        "The whole figure from head to toe, facing the viewer, filling the "
        "frame, alone in the picture.",
        "The background is ONE FLAT SOLID MAGENTA COLOUR behind the figure, "
        "edge to edge, completely plain.",
        HOUSE,
        "No picture frame, no ornamental border, no gold frame, no oval, "
        "no portrait frame, no mirror, no arch, no scroll, "
        "no parchment, no panel, no scenery, no furniture, no ground, "
        "no floor, no shadow, nobody else. No white outline around the "
        "figure, no sticker border, no die-cut edge, no glow.",
        NO_TEXT,
    ]))

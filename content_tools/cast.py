"""Who the cast are, and what each one looks like.

Four children and a fox, fixed here because every one of a character's mood
cells is painted from the same description. A description that lives in one
prompt drifts the moment a second prompt needs it, and then آراد has brown
hair in chapter one and black hair in chapter four.

The faces come from the approved splash sheet in assets/art/reference/, and
the fox from docs/reference/char-fandogh-sheet.webp. Ages and temperaments
come from GDD §3.

A note on فندق: the splash sheet draws the guide as a blue dragon. The GDD
calls him a fox and there is a finished character sheet for the fox, so a
fox he stays; the dragon was a sketch that got ahead of the document.
"""

from __future__ import annotations

import house_style

## Each character's five moods. The engine asks for these by name, so the
## list is the contract between the art and `character_figure.gd`.
MOODS = ["neutral", "happy", "surprised", "thinking", "sad"]

CAST = {
    "raha": {
        "name": "رها",
        "role": "تحلیل‌گر گروه · ۱۰ ساله · دقیق و منطقی",
        "look": "a ten-year-old girl with long wavy bright red hair held back "
                "by a pale blue headband, round glasses, green eyes, a mint "
                "green jacket over a white shirt, grey trousers, lilac boots, "
                "a teal backpack",
    },
    "arad": {
        "name": "آراد",
        "role": "شخصیت قابل انتخاب · ۱۰ ساله · کنجکاو و ماجراجو",
        "look": "a ten-year-old boy with thick curly brown hair, brown eyes, "
                "an open white shirt with sleeves rolled up, tan shorts, "
                "a brown leather satchel and straps, sturdy boots",
    },
    "mani": {
        "name": "مانی",
        "role": "مخترع کوچک · ۹ ساله · خلاق و شوخ‌طبع",
        "look": "a nine-year-old boy with short black hair, round glasses, "
                "a bright green shirt over a white tee, brown trousers, "
                "a dark green backpack, slightly smaller than the others",
    },
    "player": {
        "name": "بازیکن",
        "role": "شخصیت خود کودک",
        "look": "a ten-year-old girl with dark skin and dark curly hair in "
                "two high bunches tied with colourful beads, a pink t-shirt, "
                "blue jeans, a patterned backpack and beaded bracelets",
    },
    "fandogh": {
        "name": "فندق",
        "role": "راهنمای بازی — یک روباه",
        "look": "a small friendly fennec fox standing upright on two legs, "
                "bright orange fur, very large pointed ears with cream inner "
                "fur, a cream chest and a big bushy tail with a cream tip, "
                "large round brown eyes, a soft blue scarf around the neck",
        # The fox is not a child, so the cast brief's "ten-year-old in a
        # backpack" would fight the description rather than help it.
        "animal": True,
    },
}

## What each mood has to read as, at the size a face is actually seen: a
## thumbnail beside a line of dialogue. Subtle does not survive that, so each
## one is stated plainly.
MOOD_BRIEF = {
    "neutral": "calm and attentive, a small friendly half-smile",
    "happy": "openly delighted, a wide smile, eyes bright and crinkled",
    "surprised": "eyebrows high, eyes wide, mouth open in a small o",
    "thinking": "head tilted a little, one eyebrow up, a hand near the chin",
    "sad": "downcast, eyes lowered, mouth turned down, shoulders dropped",
}


def sheet_prompt(character_id: str) -> str:
    """The reference sheet: one character, full body, facing the viewer."""
    c = CAST[character_id]
    brief = house_style.creature if c.get("animal") else house_style.cast
    return brief(c["look"] + ", friendly and curious.")


def mood_prompt(character_id: str, mood: str) -> str:
    """One mood cell, painted to match that character's sheet."""
    c = CAST[character_id]
    brief = house_style.creature if c.get("animal") else house_style.cast
    return brief("%s, %s." % (c["look"], MOOD_BRIEF[mood]))

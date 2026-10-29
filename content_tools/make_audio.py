"""Synthesises the game's sound effects and ambient music beds.

The game has had a complete audio system and no audio at all: AudioManager
is called from seventeen places and every call found nothing to play. The
sound libraries are not reachable from this environment, so rather than
leave the game silent these are built from scratch.

For the interface sounds that is the right answer anyway and not a
stand-in: a tap, a chime and a refusal made for this game are shorter,
quieter and more consistent with each other than anything picked off a
library, they carry no licence question, and each one is a few kilobytes.

The music beds ARE stand-ins. They are slow chord pads with a little
movement, pitched and voiced per place, and they will hold a scene without
drawing attention -- but a composer should replace them. Each one is
written as a seamless loop: the whole bed is built from whole numbers of
cycles of its root, so the end meets the beginning without a click.
"""

from __future__ import annotations

import argparse
import math
import struct
import subprocess
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio"
RATE = 44100

# — the shape of a sound ————————————————————————————————————

def env(n: int, attack: float, decay: float, sustain: float = 0.0,
        release: float = 0.0) -> np.ndarray:
    """An amplitude envelope in seconds, padded or trimmed to n samples."""
    a = int(attack * RATE)
    d = int(decay * RATE)
    s = int(sustain * RATE)
    r = int(release * RATE)
    parts = [
        np.linspace(0.0, 1.0, max(1, a)),
        np.linspace(1.0, 0.45, max(1, d)),
        np.full(max(0, s), 0.45),
        np.linspace(0.45, 0.0, max(1, r)),
    ]
    out = np.concatenate(parts)
    if len(out) < n:
        out = np.pad(out, (0, n - len(out)))
    return out[:n]


def tone(freq: float, seconds: float, harmonics: tuple[float, ...] = (1.0,),
         detune: float = 0.0) -> np.ndarray:
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for i, gain in enumerate(harmonics, start=1):
        f = freq * i * (1.0 + detune * (i - 1))
        out += gain * np.sin(2.0 * math.pi * f * t)
    return out / max(1e-9, sum(harmonics))


def noise(seconds: float) -> np.ndarray:
    rng = np.random.default_rng(7)
    return rng.uniform(-1.0, 1.0, int(seconds * RATE))


def lowpass(x: np.ndarray, cutoff: float, circular: bool = False) -> np.ndarray:
    """A one-pole filter. Enough to take the glare off noise and off a
    square-ish harmonic stack; nothing here needs a steeper slope.

    `circular` matters only for a loop. The filter has memory and starts
    from silence, so the first moment of a bed is ramping up while its last
    moment is not, and the join clicks. Running it once to find the state it
    settles into, then again from that state, gives the answer the filter
    would reach if the bed had been playing for ever -- which, once it
    loops, it has.
    """
    a = math.exp(-2.0 * math.pi * cutoff / RATE)
    acc = 0.0
    for _ in range(2 if circular else 1):
        out = np.empty_like(x)
        for i, v in enumerate(x):
            acc = (1.0 - a) * v + a * acc
            out[i] = acc
    return out


def snap(freq: float, length: float) -> float:
    """The nearest frequency that completes whole cycles in `length`.

    Without this the detuned voices -- which are what gives the pad its slow
    beating -- end mid-cycle and the loop clicks however carefully the root
    was chosen. The shift is a fraction of a hertz and inaudible; the click
    is not.
    """
    return max(1.0, round(freq * length)) / length


def fit(x: np.ndarray, peak: float = 0.72) -> np.ndarray:
    m = float(np.max(np.abs(x))) or 1.0
    return x * (peak / m)


# — the interface sounds ————————————————————————————————————
#
# All six share one voice: a soft sine body with a touch of its second
# harmonic, short, and well under full scale. A child plays this with the
# volume up and the sounds repeat hundreds of times an hour, so every one of
# them is quieter and shorter than feels right in isolation.

def sfx_ui_tap() -> np.ndarray:
    x = tone(660.0, 0.09, (1.0, 0.22)) * env(int(0.09 * RATE), 0.004, 0.05, 0.0, 0.03)
    return fit(x, 0.42)


def sfx_ui_choice() -> np.ndarray:
    a = tone(587.33, 0.14, (1.0, 0.2)) * env(int(0.14 * RATE), 0.005, 0.06, 0.0, 0.07)
    b = tone(880.0, 0.14, (1.0, 0.18)) * env(int(0.14 * RATE), 0.05, 0.05, 0.0, 0.04)
    return fit(a + b * 0.8, 0.46)


def sfx_ui_soft_no() -> np.ndarray:
    """A refusal that is not a buzz. Two low notes a tone apart, falling --
    a child who presses the wrong thing should hear 'not that one', not an
    error."""
    a = tone(330.0, 0.16, (1.0, 0.25)) * env(int(0.16 * RATE), 0.006, 0.07, 0.0, 0.08)
    b = tone(293.66, 0.16, (1.0, 0.25)) * env(int(0.16 * RATE), 0.08, 0.05, 0.0, 0.03)
    return fit(a + b, 0.40)


def sfx_clue_found() -> np.ndarray:
    """Three rising notes with a little shimmer. This is the sound of the
    game's whole loop paying off, so it is the brightest thing in the set."""
    out = np.zeros(int(0.58 * RATE))
    for i, f in enumerate((659.25, 880.0, 1174.66)):
        seg = tone(f, 0.34, (1.0, 0.3, 0.12)) * env(int(0.34 * RATE), 0.006, 0.10, 0.04, 0.18)
        at = int(i * 0.10 * RATE)
        out[at:at + len(seg)] += seg * (0.9 ** i)
    shimmer = lowpass(noise(0.58), 5200.0) * env(int(0.58 * RATE), 0.02, 0.2, 0.0, 0.34)
    return fit(out + shimmer * 0.06, 0.60)


def sfx_clue_combine() -> np.ndarray:
    """Two notes sliding into one. Combining clues is the one mechanic the
    design calls the heart of the game, so it gets a sound of its own rather
    than a second copy of the clue chime."""
    n = int(0.5 * RATE)
    t = np.arange(n) / RATE
    up = np.sin(2.0 * math.pi * np.cumsum(np.linspace(440.0, 659.25, n)) / RATE)
    dn = np.sin(2.0 * math.pi * np.cumsum(np.linspace(880.0, 659.25, n)) / RATE)
    body = (up + dn) * env(n, 0.02, 0.12, 0.08, 0.26)
    return fit(body, 0.52)


def sfx_puzzle_ok() -> np.ndarray:
    out = np.zeros(int(0.7 * RATE))
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.5)):
        seg = tone(f, 0.45, (1.0, 0.28, 0.1)) * env(int(0.45 * RATE), 0.006, 0.12, 0.06, 0.24)
        at = int(i * 0.075 * RATE)
        out[at:at + len(seg)] += seg * (0.88 ** i)
    return fit(out, 0.62)


def sfx_clock_activate() -> np.ndarray:
    """The clock in chapter one striking. A low bell with a long tail."""
    out = np.zeros(int(2.4 * RATE))
    for i in range(3):
        seg = tone(196.0, 1.4, (1.0, 0.5, 0.3, 0.18, 0.1), detune=0.004)
        seg = seg * env(int(1.4 * RATE), 0.003, 0.5, 0.1, 0.78)
        at = int(i * 0.42 * RATE)
        out[at:at + len(seg)] += seg * (0.82 ** i)
    return fit(out, 0.66)


SFX = {
    "SFX_UI_TAP": sfx_ui_tap,
    "SFX_UI_CHOICE": sfx_ui_choice,
    "SFX_UI_SOFT_NO": sfx_ui_soft_no,
    "SFX_CLUE_FOUND": sfx_clue_found,
    "SFX_CLUE_COMBINE": sfx_clue_combine,
    "SFX_PUZZLE_OK": sfx_puzzle_ok,
    "SFX_CLOCK_ACTIVATE": sfx_clock_activate,
}

# — the music beds ——————————————————————————————————————————
#
# track -> (root note in Hz, chord as semitone offsets, seconds, brightness)
# Minor and suspended chords for the mysteries, major for the warm places.
MUSIC = {
    "MUS_TOWN_DAY":        (261.63, (0, 4, 7, 11), 32.0, 0.55),
    "MUS_SCHOOL_MYSTERY":  (220.00, (0, 3, 7, 10), 32.0, 0.38),
    "MUS_TOWER":           (174.61, (0, 3, 7, 14), 32.0, 0.30),
    "MUS_LIBRARY":         (196.00, (0, 5, 7, 12), 32.0, 0.42),
    "MUS_FOREST_MYSTERY":  (164.81, (0, 3, 7, 10), 32.0, 0.34),
    "MUS_LAKE":            (146.83, (0, 7, 12, 16), 32.0, 0.48),
    "MUS_UNDERCITY":       (130.81, (0, 3, 6, 10), 32.0, 0.24),
    "MUS_WORKSHOP":        (233.08, (0, 4, 7, 10), 32.0, 0.46),
    "MUS_OBSERVATORY":     (155.56, (0, 5, 10, 14), 32.0, 0.36),
    "MUS_SYMBOL_HALL":     (207.65, (0, 3, 8, 12), 32.0, 0.32),
    "MUS_FESTIVAL":        (293.66, (0, 4, 7, 9), 32.0, 0.62),
    "MUS_PUZZLE_CALM":     (174.61, (0, 7, 12, 19), 32.0, 0.40),
    "MUS_REVEAL":          (261.63, (0, 5, 9, 12), 24.0, 0.58),
}


## The chord a track moves through, as scale degrees from its root, and
## the melody's shape over them. Minor-ish sequences for the mysteries,
## open fifths for the wide places.
PROGRESSION = {
    "dark":  ((0, 0, 0, 0), (-5, -5, 0, 0), (-7, -7, -5, -5), (0, 0, -2, -2)),
    "warm":  ((0, 0, 0, 0), (5, 5, 5, 5), (-3, -3, 2, 2), (0, 0, 0, 0)),
    "open":  ((0, 0, 0, 0), (7, 7, 7, 7), (2, 2, 5, 5), (0, 0, -5, -5)),
}
## Which shape each place takes, and the notes its melody may use.
VOICE_OF = {
    "MUS_TOWN_DAY": ("warm", [0, 2, 4, 7, 9]),
    "MUS_SCHOOL_MYSTERY": ("dark", [0, 3, 5, 7, 10]),
    "MUS_TOWER": ("dark", [0, 3, 7, 10, 14]),
    "MUS_LIBRARY": ("open", [0, 5, 7, 12, 14]),
    "MUS_FOREST_MYSTERY": ("dark", [0, 3, 5, 10, 12]),
    "MUS_LAKE": ("open", [0, 7, 12, 16, 19]),
    "MUS_UNDERCITY": ("dark", [0, 3, 6, 10, 12]),
    "MUS_WORKSHOP": ("warm", [0, 4, 7, 10, 12]),
    "MUS_OBSERVATORY": ("open", [0, 5, 10, 14, 17]),
    "MUS_SYMBOL_HALL": ("dark", [0, 3, 8, 12, 15]),
    "MUS_FESTIVAL": ("warm", [0, 4, 7, 9, 12]),
    "MUS_PUZZLE_CALM": ("open", [0, 7, 12, 14, 19]),
    "MUS_REVEAL": ("warm", [0, 5, 9, 12, 16]),
}


def melody(root: float, notes: list[int], moves: tuple, length: float,
           n: int, brightness: float, seed: int) -> np.ndarray:
    """A tune over the progression, built from the chord's own notes.

    Picked rather than composed, but picked under rules that keep it from
    wandering: it only ever steps to a neighbouring note of the scale, it
    rests as often as it plays, and it is the same every run for a given
    track, so a player who comes back to a place hears the place.
    """
    rng = np.random.default_rng(seed)
    out = np.zeros(n)
    bars = len(moves)
    beats = bars * 8
    step = n // beats
    at = len(notes) // 2
    for b in range(beats):
        if rng.random() < 0.38:          # rests are half the tune
            continue
        at = int(np.clip(at + rng.integers(-1, 2), 0, len(notes) - 1))
        shift = moves[(b // 8) % bars][0]
        f = root * 2.0 ** ((notes[at] + shift) / 12.0) * 2.0
        f = max(1.0, round(f * length) / length)   # whole cycles, for the loop
        hold = step * int(rng.integers(1, 3))
        seg = tone(f, hold / RATE, (1.0, 0.3, 0.12, 0.05))
        seg = seg * env(len(seg), 0.012, 0.10, 0.25, 0.55)
        start = b * step
        end = min(n, start + len(seg))
        out[start:end] += seg[:end - start] * 0.55
    return lowpass(out, 1800.0 + 2600.0 * brightness, circular=True)


def bed(root: float, chord: tuple[int, ...], seconds: float,
        brightness: float) -> np.ndarray:
    """A slow pad that loops without a seam.

    The length is rounded to a whole number of cycles of the root, and every
    moving part is a whole number of cycles over that same length, so the
    last sample runs into the first. A bed that clicks once every thirty
    seconds is worse than no bed at all -- the ear finds it immediately and
    then waits for it.
    """
    cycles = round(seconds * root)
    n = int(round(cycles * RATE / root))
    t = np.arange(n) / RATE
    length = n / RATE

    out = np.zeros(n)
    for i, semitones in enumerate(chord):
        f = root * (2.0 ** (semitones / 12.0))
        # Two voices a few cents apart give the pad its slow beating.
        for cents in (-4.0, 4.0):
            detuned = snap(f * (2.0 ** (cents / 1200.0)), length)
            voice = np.sin(2.0 * math.pi * detuned * t)
            # Each voice breathes at its own whole number of cycles.
            swell_cycles = 2 + i
            swell = 0.72 + 0.28 * np.sin(2.0 * math.pi * swell_cycles * t / length)
            out += voice * swell * (0.62 ** i)

    # A touch of air, filtered to taste, that also loops: the same noise
    # window is faded in and out across the bed.
    air = lowpass(noise(length), 900.0 + 2600.0 * brightness, circular=True)
    air *= 0.5 - 0.5 * np.cos(2.0 * math.pi * t / length)
    out = out / (len(chord) * 2.0) + air * 0.05 * brightness

    out = lowpass(out, 700.0 + 3200.0 * brightness, circular=True)
    # Music sits under dialogue, so it is mixed low at source rather than
    # left to the volume slider.
    return fit(out, 0.26)


def track(name: str, root: float, chord: tuple[int, ...], seconds: float,
          brightness: float) -> np.ndarray:
    """The pad, the progression moving under it, and a tune on top."""
    pad = bed(root, chord, seconds, brightness)
    n = len(pad)
    length = n / RATE
    shape, notes = VOICE_OF.get(name, ("open", [0, 5, 7, 12]))
    moves = PROGRESSION[shape]
    tune = melody(root, notes, moves, length, n, brightness,
                  abs(hash(name)) % 100000)
    return fit(pad * 0.78 + tune * 0.42, 0.28)


# — voices ——————————————————————————————————————————————————
#
# Not speech. Each character gets a short sound that plays once per few
# letters as their line types out, which is how a 2D game gives a cast
# voices without recording any: the ear takes the pitch and timbre as the
# character and reads the words off the screen.
#
# Synthesised Persian speech was the obvious alternative and is rejected on
# purpose. It would be worse than silence here -- a machine reading Persian
# badly to a nine-year-old is the thing a parent switches off -- and it
# would also quietly take the place of the studio recording the real lines
# are meant to come from, so nobody would notice it was still missing.
#
# id -> (pitch in Hz, shape, length in seconds)
# A lower, rounder sound is an adult; a quick bright one is a child; the
# dinosaur is a warble nobody else has.
VOICES = {
    "VOICE_ARAD":    (392.0, "round", 0.055),
    "VOICE_RAHA":    (523.0, "bright", 0.050),
    "VOICE_MANI":    (466.0, "round", 0.048),
    "VOICE_PLAYER":  (494.0, "bright", 0.052),
    "VOICE_FANDOGH": (640.0, "warble", 0.060),
    "VOICE_AZIMI":   (311.0, "round", 0.065),
    "VOICE_MODIR":   (262.0, "round", 0.070),
    "VOICE_NARRATOR": (349.0, "soft", 0.075),
}


def voice(freq: float, shape: str, seconds: float) -> np.ndarray:
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    if shape == "bright":
        body = tone(freq, seconds, (1.0, 0.45, 0.22, 0.1))
    elif shape == "round":
        body = tone(freq, seconds, (1.0, 0.18, 0.06))
    elif shape == "warble":
        # The pitch moves inside the blip, which is what makes it read as
        # a creature rather than as a person with an odd voice.
        f = freq * (1.0 + 0.22 * np.sin(2.0 * math.pi * 26.0 * t))
        body = np.sin(2.0 * math.pi * np.cumsum(f) / RATE)
    else:
        body = tone(freq, seconds, (1.0, 0.1))
    body = body * env(n, 0.004, seconds * 0.45, 0.0, seconds * 0.5)
    return fit(body, 0.30)


# — writing ————————————————————————————————————————————————

def write_ogg(samples: np.ndarray, path: Path, quality: str) -> None:
    pcm = np.clip(samples, -1.0, 1.0)
    data = (pcm * 32767.0).astype("<i2").tobytes()
    header = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVEfmt " \
        + struct.pack("<IHHIIHH", 16, 1, 1, RATE, RATE * 2, 2, 16) \
        + b"data" + struct.pack("<I", len(data))
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(header + data)
        wav = Path(tmp.name)
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
         "-c:a", "libvorbis", "-q:a", quality, str(path)], check=True)
    wav.unlink()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument("--only", default="", help="sfx, music, or one id")
    args = ap.parse_args()

    made = 0
    for name, make in SFX.items():
        if args.only and args.only not in ("sfx", name):
            continue
        write_ogg(make(), args.out / "sfx" / f"{name}.ogg", "4")
        print(f"sfx    {name}")
        made += 1
    for name, (freq, shape, seconds) in VOICES.items():
        if args.only and args.only not in ("voices", name):
            continue
        # Written beside the sound effects, because to the engine that is
        # what they are: short sounds played on an event. The vo/ folder
        # stays empty for the real recordings, so nothing here can quietly
        # take their place in the path the game looks for them on.
        write_ogg(voice(freq, shape, seconds),
                  args.out / "sfx" / f"{name}.ogg", "4")
        print(f"voice  {name}")
        made += 1
    for name, (root, chord, seconds, bright) in MUSIC.items():
        if args.only and args.only not in ("music", name):
            continue
        write_ogg(track(name, root, chord, seconds, bright),
                  args.out / "music" / f"{name}.ogg", "3")
        print(f"music  {name}")
        made += 1
    print(f"\n{made} files written to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

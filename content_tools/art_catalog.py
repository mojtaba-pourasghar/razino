#!/usr/bin/env python3
"""The complete list of paintings the game needs, derived from the content.

Like asset_report.py, this reads its truth out of the chapter data rather
than a hand-kept list, so the worklist cannot drift from what the game
actually asks for. It adds the slots that have no id in the data — menu
backdrops, chapter thumbnails, world-map regions — because those are fixed
by the screens rather than by the story.

    python3 content_tools/art_catalog.py              # human summary
    python3 content_tools/art_catalog.py --json       # the worklist
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# — the shared look ————————————————————————————————————————
#
# Every prompt carries this. It is the whole reason ten chapters painted on
# ten different days look like one game. The "no text" clauses are repeated
# deliberately: these models love to paint fake Latin signage, which in a
# Persian game is worse than a blank wall.
STYLE = (
    "Ornate 2D hand-painted storybook illustration for a children's mystery "
    "adventure game. Painterly detail like a high-end animated film "
    "background, clean edges, soft shading. Rich saturated colour, warm "
    "golden lantern light against deep teal and navy shadows. "
    "Absolutely no text, no letters, no words, no signage with writing, "
    "no numbers, no watermark, no logo, no user interface, no frames, "
    "no borders, no picture frame edges, no labels, no place names, "
    "no captions, no map legend."
)

# Each chapter's own register, so a forest reads differently from a vault
# without either leaving the palette.
CHAPTER_MOOD = {
    "season_01": "autumn dusk, amber and deep blue, an old stone school and a clock tower",
    "season_02": "night library, green reading lamps, dark wood and gilt, dust in lamplight",
    "season_03": "sunlit forest, moss green and river blue, shafts of light through leaves",
    "season_04": "brass and copper workshop, forge glow, gears and blueprints",
    "season_05": "cold lakeside twilight, pale blue and steel, mist over still water",
    "season_06": "festival night, a thousand warm lanterns, crowded bazaar colour",
    "season_07": "starlit observatory, indigo and silver, brass instruments",
    "season_08": "underground caverns, glowing crystal teal, carved stone",
    "season_09": "a hall of engraved symbols, torchlight on stone, amber and black",
    "season_10": "the lit clock tower at the story's end, gold light pouring out",
}

# Slots the screens fix rather than the story. Each is (id, kind, width,
# height, prompt) — see scenes/common/screen.gd BACKDROPS and the world map.
UI_SLOTS = [
    ("ui_splash", "ui", 1280, 720,
     "A sweeping vista of the town of Razino at golden hour seen from a "
     "hillside: tiled rooftops, a tall stone clock tower, lantern-lit lanes, "
     "a river and a stone bridge, distant blue mountains."),
    ("ui_town", "ui", 1280, 720,
     "The central square of Razino at dusk: an ornate stone fountain, warm "
     "glowing shop windows, hanging lanterns, cobblestones, leafy trees, a "
     "clock tower rising behind the rooftops."),
    ("ui_worldmap", "ui", 1280, 720,
     "An aerial view from high above a cluster of green islands in a deep "
     "blue sea: a town of tiled roofs on one, dense forest on another, "
     "mountains with a copper dome, a dark cave mouth in a cliff, sandy "
     "paths winding between them. A landscape painting, not a chart."),
    ("ui_panel_backdrop", "ui", 1280, 720,
     "A dark moody backdrop of a dim study at night, heavily blurred and out "
     "of focus, deep navy and teal with soft warm lamp glow in the corners. "
     "Very low contrast, nothing readable, a quiet backdrop behind a menu."),
    ("ui_loading", "ui", 1280, 720,
     "The town of Razino at night seen across a lake, lights reflecting on "
     "the water, a great clock tower lit against the stars. Calm and wide."),
    ("BG_WORLD_MAP", "ui", 1280, 480,
     "A wide aerial view from high above green islands in a deep blue sea: "
     "a town of tiled roofs, a pine forest, a workshop quarter with a tall "
     "chimney, a lakeside dome, and a dark cave mouth in a cliff, joined by "
     "sandy paths. A landscape painting, not a chart."),
    ("BG_INTRO_RAZINO", "ui", 1280, 720,
     "A great stone clock tower at night above a sleeping town, its clock "
     "face dark and stopped, a single lit window, swirling stars and "
     "drifting clock hands in the sky. Mysterious and inviting."),
]

# The five world-map regions from scenes/menus/world_map.gd.
REGION_SLOTS = [
    ("region_centre", 768, 432,
     "An old town centre seen from above at golden hour: a school with a "
     "yard, a great stone clock tower, a domed library, tiled rooftops, a "
     "cobbled square with a fountain."),
    ("region_nature", 768, 432,
     "A lush forest valley: a tall waterfall into a blue river, a wooden "
     "rope bridge, mossy standing stones carved with symbols, mountain "
     "paths climbing into mist."),
    ("region_invent", 768, 432,
     "An inventor's workshop district: brass gears and copper pipes, a tall "
     "chimney, workbenches of half-built clockwork, warm forge light."),
    ("region_far", 768, 432,
     "A remote highland research station beside a still lake at twilight: a "
     "copper observatory dome, a jetty, pine trees, early stars."),
    ("region_under", 768, 432,
     "A vast underground cavern lit by glowing crystals: carved stone "
     "passages, a hall of engraved tablets, a great machine of brass rings."),
]

# Readable place names for scene backgrounds, so a prompt says "the attic
# room" rather than "BG_S01_ATTIC_ROOM".
PLACE_HINTS = {
    "ATTIC_ROOM": "a cluttered attic under a sloping beamed roof, trunks and a dust-sheeted chair, a small round window",
    "CLOCK_TOWER": "the base of a great stone clock tower seen from the square below, the lit clock face high above",
    "LIBRARY_HALL": "the main hall of a grand old library, towering dark-wood shelves, a spiral iron staircase, long reading tables",
    "OLD_CORRIDOR": "a long empty school corridor, tall arched windows, a worn wooden floor, lockers and a noticeboard",
    "SCHOOL_YARD": "the yard of an old stone school, a bell arch, a plane tree, worn benches, long shadows on paving",
    "TOWER_VAULT": "the mechanism room of a clock tower, enormous brass gears and a swinging pendulum, rope-wound weights",
    "ARCHIVE_ROOM": "a cramped archive room, boxed records to the ceiling, a single desk lamp",
    "HIDDEN_PASSAGE": "a narrow hidden passage behind a bookcase, stone steps descending into the dark",
    "MOVING_STACKS": "a hall of library shelves on iron rails, some slid open to reveal a gap",
    "CABIN": "a small wooden forest cabin, lantern on the porch, tools and rope",
    "FOREST_EDGE": "the edge of a deep forest meeting an open meadow, late light through the trunks",
    "STONE_PATH": "a mossy stone path winding between carved standing stones",
    "WATERFALL": "a tall waterfall falling into a blue pool, spray and rainbow light",
    "WOODEN_BRIDGE": "an old wooden rope bridge across a forest gorge",
    "DRAFTING_TABLE": "a drafting table covered in blueprints, brass instruments and a lamp",
    "WORKSHOP": "a cluttered inventor's workshop, gears and half-built machines, forge glow",
    "WORKSHOP_DOOR": "a heavy workshop door of riveted iron with a clockwork lock",
    "PIER": "a wooden pier on a still lake at dawn, moored boats, mist",
    "STATION": "a small lakeside research station, instruments and charts, wide windows",
    "TUNNEL": "a long stone tunnel lit by lanterns, water running along a channel",
    "BAZAAR": "a crowded night bazaar, hanging lanterns, stalls of cloth and copper",
    "CRAFT_BOOTH": "a festival craft booth hung with lanterns and ribbons",
    "HISTORY_BOOTH": "a festival booth of old maps and relics under warm light",
    "SQUARE": "a town square filled with festival lanterns and people",
    "DOME": "the inside of an observatory dome, a great brass telescope, open shutter to the stars",
    "MAP_HALL": "a hall of star charts and celestial globes",
    "MOUNTAIN_ROAD": "a mountain road climbing at twilight toward a distant dome",
    "OBSERVATORY": "an observatory on a ridge against a star-filled sky",
    "TELESCOPE_ROOM": "a small room of brass telescopes and lenses",
    "CENTRAL_HALL": "a vast underground hall with carved pillars and glowing crystal",
    "MAP_ROOM": "an underground room with a great map carved into the floor",
    "STONE_STAIRS": "a long spiral stone stair descending into glowing dark",
    "TUNNEL_ENTRY": "the mouth of an underground tunnel behind an iron gate",
    "VALVE_ROOM": "a chamber of great brass valves and pipes",
    "HEART_DOOR": "an enormous round door of interlocking brass rings",
    "KEY_ROOM": "a chamber of ten keyholes set into carved stone",
    "PLATFORM": "a stone platform over a glowing chasm",
    "SYMBOL_HALL": "a hall of engraved symbol tablets lit by torches",
    "ARCHIVE": "a dusty archive of bound ledgers and map tubes",
    "CHAMBER": "the heart chamber of a great clockwork machine, brass rings turning",
    "CITY_SQUARE": "the town square at dawn, the clock tower lit and running",
    "SCHOOL_ARCHIVE": "a school archive room of old records and photographs",
    "TOWER_LIT": "the clock tower at night with every window lit and the clock face glowing",
}

# What each size is for. Backgrounds ship at two sizes per BG_SPEC; the
# generator makes the large one and postprocess derives the phone size.
BG_W, BG_H = 1280, 720
THUMB_W, THUMB_H = 768, 512


def load_chapters() -> dict:
    out = {}
    for d in sorted((ROOT / "content").glob("season_*")):
        f = d / "story.json"
        if f.exists():
            out[d.name] = json.loads(f.read_text(encoding="utf-8"))
    return out


def place_of(bg_id: str) -> str:
    """The readable place behind a BG id, e.g. BG_S01_ATTIC_ROOM -> attic."""
    parts = bg_id.split("_", 2)
    tail = parts[2] if len(parts) > 2 else bg_id
    return PLACE_HINTS.get(tail, tail.replace("_", " ").lower())


def scene_backgrounds(chapters: dict) -> list[dict]:
    """Every BG_* the story asks for, with the chapter's mood folded in."""
    jobs = []
    for cid, data in chapters.items():
        seen: set[str] = set()
        for scene in data.get("scenes", []):
            ids = [scene.get("background_id")]
            for beat in (scene.get("cinematic") or {}).get("beats", []):
                ids.append(beat.get("background_id"))
            for bg in ids:
                if not bg or bg in seen:
                    continue
                seen.add(bg)
                jobs.append({
                    "id": bg,
                    "kind": "background",
                    "chapter": cid,
                    "width": BG_W,
                    "height": BG_H,
                    "target": f"content/{cid}/backgrounds/{bg}.webp",
                    "prompt": f"{place_of(bg)}. {CHAPTER_MOOD.get(cid, '')}.",
                })
    return jobs


def chapter_thumbnails(chapters: dict) -> list[dict]:
    """One cover plate per chapter, for the chapter list and the shop."""
    jobs = []
    for cid, data in chapters.items():
        jobs.append({
            "id": f"thumb_{cid}",
            "kind": "thumbnail",
            "chapter": cid,
            "width": THUMB_W,
            "height": THUMB_H,
            "target": f"assets/art/thumbnails/{cid}.webp",
            "prompt": (f"A cover plate for a chapter set in "
                       f"{data.get('primary_environment', '')}. "
                       f"{CHAPTER_MOOD.get(cid, '')}. A single striking "
                       f"wide view, no characters."),
        })
    return jobs


def ui_jobs() -> list[dict]:
    jobs = []
    for art_id, kind, w, h, prompt in UI_SLOTS:
        sub = "backgrounds" if art_id.startswith("ui_") else "menu"
        jobs.append({
            "id": art_id, "kind": kind, "chapter": "", "width": w, "height": h,
            "target": f"assets/art/{sub}/{art_id}.webp", "prompt": prompt,
        })
    for art_id, w, h, prompt in REGION_SLOTS:
        jobs.append({
            "id": art_id, "kind": "region", "chapter": "", "width": w, "height": h,
            "target": f"assets/art/regions/{art_id}.webp", "prompt": prompt,
        })
    return jobs


def catalog() -> list[dict]:
    """The worklist, in the order it should be painted.

    Menus first, because they are what the player sees before anything else;
    then chapter one, which is the only chapter inside the APK; then the
    thumbnails that make the chapter list and shop read; then the rest.
    """
    chapters = load_chapters()
    jobs = ui_jobs()
    scene = scene_backgrounds(chapters)
    jobs += [j for j in scene if j["chapter"] == "season_01"]
    jobs += chapter_thumbnails(chapters)
    jobs += [j for j in scene if j["chapter"] != "season_01"]
    for i, job in enumerate(jobs):
        job["order"] = i
        job["done"] = (ROOT / job["target"]).exists()
    return jobs


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true", help="print the worklist as JSON")
    args = ap.parse_args()

    jobs = catalog()
    if args.json:
        print(json.dumps(jobs, ensure_ascii=False, indent=2))
        return 0

    done = sum(1 for j in jobs if j["done"])
    by_kind: dict[str, list] = {}
    for j in jobs:
        by_kind.setdefault(j["kind"], []).append(j)
    print("=" * 72)
    print(f" Razino art catalog — {done}/{len(jobs)} painted")
    print("=" * 72)
    for kind, group in by_kind.items():
        d = sum(1 for j in group if j["done"])
        print(f"  {kind:12s} {d:3d}/{len(group):3d}")
    print()
    for j in jobs:
        if not j["done"]:
            print(f"  · {j['id']:28s} {j['width']}x{j['height']:<5d} {j['target']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

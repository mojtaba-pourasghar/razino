#!/usr/bin/env python3
"""Adds the stage layer to a chapter, derived from its scenes.

GDD §5.8 makes the stage the unit a player actually plays, scores and
replays. The story is already written as a line of scenes, so the stages
are cut from that line rather than written separately — the alternative is
two descriptions of the same chapter that drift apart.

Everything a stage can be counted from, this counts: how many clues it
grants, how many puzzles it holds, how long it should take. Only the title
and the question a stage asks are written by hand, because neither is in
the data.

    python3 content_tools/build_stages.py            # all chapters
    python3 content_tools/build_stages.py season_01
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

## How long a stage is expected to take, by what its scenes are. Used only
## for the 10% time share of the score (GDD §5.2); being slower than this
## costs that share and nothing else.
SECONDS_PER = {"cinematic": 45, "dialogue": 60, "explore": 110, "puzzle": 150}

## The ten stages of chapter one: which scenes each covers, its title, and
## the question it asks. The scene groupings follow the story's own beats —
## a cinematic and the conversation it opens, an exploration and what it
## turns up, a puzzle and its aftermath.
STAGES = {
    "season_01": [
        (["S01-E01-SC01", "S01-E01-SC02"], "سه ضربه",
         "چه چیزی برجِ خاموش را به صدا درآورد؟"),
        (["S01-E01-SC03", "S01-E01-SC04"], "سه نقطه",
         "کدام‌یک از سه نشانهٔ حیاط به برج مربوط است؟"),
        (["S01-E01-SC05", "S01-E01-SC06"], "کدام همراه؟",
         "چه کسی می‌تواند درِ راهروی قدیمی را باز کند؟"),
        (["S01-E02-SC01", "S01-E02-SC02"], "راهروی قدیمی",
         "چرا صفحه‌های دفترچه بریده شده‌اند؟"),
        (["S01-E02-SC03", "S01-E02-SC04"], "به ترتیبی که روز می‌گذرد",
         "نشانه‌ها به چه ترتیبی خوانده می‌شوند؟"),
        (["S01-E02-SC05", "S01-E03-SC01"], "سه راه",
         "کدام راه به سالن کتاب‌ها می‌رسد؟"),
        (["S01-E03-SC02", "S01-E03-SC03"], "خانم عظیمی",
         "خانم عظیمی چه چیزی را به یاد نمی‌آورد؟"),
        (["S01-E03-SC04", "S01-E03-SC05"], "قفل سه‌حلقه",
         "صندوقچه چه چیزی را نگه داشته است؟"),
        (["S01-E04-SC01", "S01-E04-SC02"], "محفظهٔ برج",
         "سه نشانه کجای دستگاه می‌نشینند؟"),
        (["S01-E04-SC03", "S01-E04-SC04", "S01-E04-SC05", "S01-E04-SC06"],
         "ده پرتو", "چه کسی ساعت را ساخت، و چرا خاموشش کرد؟"),
    ],
}


def clues_added(scene: dict) -> list[str]:
    """Every clue a scene can grant, down every branch it offers.

    An effect is written with its name as the key — {"add_clue": "..."} —
    the same shape StoryEngine.apply_effect reads, so this walks the whole
    scene rather than naming the five places effects can sit. Naming them
    is how the first version of this came back with every count at zero.
    """
    found: list[str] = []

    def walk(node) -> None:
        if isinstance(node, dict):
            if "add_clue" in node:
                value = node["add_clue"]
                for clue in (value if isinstance(value, list) else [value]):
                    if clue not in found:
                        found.append(str(clue))
            for child in node.values():
                walk(child)
        elif isinstance(node, list):
            for child in node:
                walk(child)

    walk(scene)
    return found


def derive_plan(story: dict) -> list[tuple]:
    """Cuts stages out of a chapter that has no hand-written plan.

    The scenes are grouped in pairs, which is the rhythm the written plan
    for chapter one follows: a thing that happens and what it turns up. The
    title is the first scene's own, and the question is the chapter's
    narrative goal — placeholders good enough to play against, and obvious
    to replace, which is better than a chapter with no stages at all.
    """
    scenes = story.get("scenes", [])
    goal = str(story.get("narrative_goal", "")).strip()
    plan = []
    for i in range(0, len(scenes), 2):
        group = scenes[i:i + 2]
        plan.append((
            [s["scene_id"] for s in group],
            str(group[0].get("title", f"مرحلهٔ {i // 2 + 1}")),
            goal or "راز این مرحله چیست؟",
        ))
    # A trailing single scene joins the stage before it rather than standing
    # alone, so no stage is one dialogue long.
    if len(plan) > 1 and len(plan[-1][0]) == 1:
        last = plan.pop()
        merged = plan[-1]
        plan[-1] = (merged[0] + last[0], merged[1], merged[2])
    return plan


def build(chapter_id: str, story: dict) -> list[dict]:
    plan = STAGES.get(chapter_id) or derive_plan(story)
    if not plan:
        return []
    by_id = {s["scene_id"]: s for s in story.get("scenes", [])}
    stages = []
    for index, (scene_ids, title, secret) in enumerate(plan, start=1):
        missing = [sid for sid in scene_ids if sid not in by_id]
        if missing:
            raise SystemExit(f"{chapter_id}: stage {index} names unknown scenes {missing}")
        scenes = [by_id[sid] for sid in scene_ids]
        clues: list[str] = []
        for s in scenes:
            for c in clues_added(s):
                if c not in clues:
                    clues.append(c)
        puzzles = sum(1 for s in scenes if s.get("scene_type") == "puzzle")
        seconds = sum(SECONDS_PER.get(s.get("scene_type", "dialogue"), 60) for s in scenes)
        stages.append({
            "stage_id": "%s-ST%02d" % (chapter_id.replace("season_", "S"), index),
            "index": index,
            "title": title,
            "secret": secret,
            "entry_scene_id": scene_ids[0],
            "scene_ids": scene_ids,
            # The stage's secret is the last clue its scenes grant: the one
            # the player is left holding when the stage is over.
            "secret_clue_id": clues[-1] if clues else "",
            "clue_count": len(clues),
            "puzzle_count": puzzles,
            "par_seconds": seconds,
            # Coins follow what the stage asks of the player, so a long
            # stage is not worth the same as a short one (GDD §5.3).
            "rewards": {
                "coins": 20 + len(clues) * 10 + puzzles * 25,
                "xp": 30 + len(scene_ids) * 10 + puzzles * 20,
            },
        })
    return stages


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chapters", nargs="*", help="chapter ids; default all with a plan")
    args = ap.parse_args()

    wanted = args.chapters or sorted(
        d.name for d in (ROOT / "content").glob("season_*") if d.is_dir())
    changed = 0
    for chapter_id in wanted:
        path = ROOT / "content" / chapter_id / "story.json"
        if not path.exists():
            print(f"  ! {chapter_id}: no story.json", flush=True)
            continue
        story = json.loads(path.read_text(encoding="utf-8"))
        stages = build(chapter_id, story)
        if not stages:
            print(f"  · {chapter_id}: no scenes to cut stages from")
            continue
        written = chapter_id in STAGES
        story["stages"] = stages
        path.write_text(json.dumps(story, ensure_ascii=False, indent=2) + "\n",
                        encoding="utf-8")
        covered = sum(len(s["scene_ids"]) for s in stages)
        how = "written" if written else "derived — titles are placeholders"
        print(f"  {chapter_id}: {len(stages)} stages over {covered}/"
              f"{len(story.get('scenes', []))} scenes ({how})")
        changed += 1
    return 0 if changed else 1


if __name__ == "__main__":
    raise SystemExit(main())

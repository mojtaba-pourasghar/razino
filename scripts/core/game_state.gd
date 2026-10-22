extends Node
## The single source of truth for everything a save file contains (GDD §4.1, §9).
##
## StoryEngine reads and writes these variables; nothing else should mutate
## them directly — go through the setters so that `changed` fires and the
## autosave stays honest.

signal variable_changed(name: String, value: Variant)
signal clue_discovered(clue_id: String)
signal item_collected(item_id: String)
signal chapter_completed(chapter_id: String)
signal progress_reset()
## Emitted when the level or experience changes, so a screen showing the
## player capsule can refresh without polling.
signal level_changed(level: int)

## Bumped whenever the shape of the save dictionary changes. SaveManager
## migrates old files forward rather than discarding them (GDD §9).
const SAVE_SCHEMA_VERSION := 1

var player_name: String = ""
var avatar_id: String = ""

## Trust is tracked per companion, not as one global number, so a choice can
## favour one friend without flattening the others.
var trust: Dictionary = {"raad": 0, "raha": 0, "mani": 0, "fandogh": 0}

var clues: Dictionary = {}          # clue_id -> true (used as a set)
var inventory: Dictionary = {}      # item_id -> true
var story_flags: Dictionary = {}    # flag -> Variant
var chapter_progress: Dictionary = {}  # chapter_id -> {"episode": String, "scene": String, "complete": bool}
var endings_seen: Dictionary = {}   # ending_id -> true
var ending_id: String = ""

var current_chapter: String = ""
var current_scene: String = ""

## Chapters the player may open. Chapter 1 is always free (GDD §11.1).
var unlocked_chapters: Dictionary = {"season_01": true}

## The purse (GDD §5.3). Coins are earned by playing; gems are bought or
## granted. Both are mirrored in the header of every screen, which is why they
## live here rather than in the shop.
var coins: int = 0
var gems: int = 0

## Level and experience, shown on the player capsule and the profile screen
## (docs/UI_SPEC.md §3.2, §3.10). Experience comes from scenes seen, puzzles
## solved and chapters finished; the curve is deliberately gentle, because
## this is a story game and the level is a keepsake, not a gate.
var level: int = 1
var xp: int = 0

const XP_BASE := 500

## How much experience the current level needs in total.
func xp_for_next_level() -> int:
	return XP_BASE + (level - 1) * 250

## Adds experience and carries the player up as many levels as it earns.
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		level += 1
		Log.info("GameState", "level %d reached" % level)
	level_changed.emit(level)

func reset() -> void:
	player_name = ""
	avatar_id = ""
	trust = {"raad": 0, "raha": 0, "mani": 0, "fandogh": 0}
	clues.clear()
	inventory.clear()
	story_flags.clear()
	chapter_progress.clear()
	endings_seen.clear()
	ending_id = ""
	current_chapter = ""
	current_scene = ""
	unlocked_chapters = {"season_01": true}
	coins = 0
	gems = 0
	level = 1
	xp = 0
	progress_reset.emit()
	Log.info("GameState", "progress reset")

# — clues & inventory —————————————————————————————————————

func has_clue(clue_id: String) -> bool:
	return clues.has(clue_id)

func add_clue(clue_id: String) -> bool:
	if clue_id.is_empty() or clues.has(clue_id):
		return false
	clues[clue_id] = true
	clue_discovered.emit(clue_id)
	variable_changed.emit("clues", clues)
	Log.info("GameState", "clue discovered: %s" % clue_id)
	return true

func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

func add_item(item_id: String) -> bool:
	if item_id.is_empty() or inventory.has(item_id):
		return false
	inventory[item_id] = true
	item_collected.emit(item_id)
	variable_changed.emit("inventory", inventory)
	return true

# — flags & trust —————————————————————————————————————————

func get_flag(flag: String, fallback: Variant = false) -> Variant:
	return story_flags.get(flag, fallback)

func set_flag(flag: String, value: Variant = true) -> void:
	story_flags[flag] = value
	variable_changed.emit(flag, value)

func get_trust(who: String) -> int:
	return int(trust.get(who, 0))

func add_trust(who: String, delta: int) -> void:
	if not trust.has(who):
		Log.warn("GameState", "trust for unknown character '%s'" % who)
		trust[who] = 0
	trust[who] = clampi(int(trust[who]) + delta, -5, 10)
	variable_changed.emit("trust_" + who, trust[who])

# — chapter bookkeeping ———————————————————————————————————

func mark_position(chapter_id: String, episode_id: String, scene_id: String) -> void:
	current_chapter = chapter_id
	current_scene = scene_id
	var entry: Dictionary = chapter_progress.get(chapter_id, {})
	entry["episode"] = episode_id
	entry["scene"] = scene_id
	entry["complete"] = entry.get("complete", false)
	chapter_progress[chapter_id] = entry

func mark_chapter_complete(chapter_id: String) -> void:
	var entry: Dictionary = chapter_progress.get(chapter_id, {})
	entry["complete"] = true
	chapter_progress[chapter_id] = entry
	chapter_completed.emit(chapter_id)
	Log.info("GameState", "chapter complete: %s" % chapter_id)

func is_chapter_complete(chapter_id: String) -> bool:
	return bool((chapter_progress.get(chapter_id, {}) as Dictionary).get("complete", false))

func chapter_percent(chapter_id: String, total_scenes: int) -> float:
	if total_scenes <= 0:
		return 0.0
	if is_chapter_complete(chapter_id):
		return 1.0
	var seen := 0
	for key in story_flags.keys():
		if String(key).begins_with("seen:" + chapter_id):
			seen += 1
	return clampf(float(seen) / float(total_scenes), 0.0, 1.0)

func is_chapter_unlocked(chapter_id: String) -> bool:
	return bool(unlocked_chapters.get(chapter_id, false))

func unlock_chapter(chapter_id: String) -> void:
	unlocked_chapters[chapter_id] = true
	variable_changed.emit("unlocked_chapters", unlocked_chapters)

# — serialisation —————————————————————————————————————————

func to_dict() -> Dictionary:
	return {
		"schema": SAVE_SCHEMA_VERSION,
		"player_name": player_name,
		"avatar_id": avatar_id,
		"trust": trust.duplicate(),
		"clues": clues.duplicate(),
		"inventory": inventory.duplicate(),
		"story_flags": story_flags.duplicate(),
		"chapter_progress": chapter_progress.duplicate(true),
		"endings_seen": endings_seen.duplicate(),
		"ending_id": ending_id,
		"current_chapter": current_chapter,
		"current_scene": current_scene,
		"unlocked_chapters": unlocked_chapters.duplicate(),
		"coins": coins,
		"gems": gems,
		"level": level,
		"xp": xp,
	}

func from_dict(d: Dictionary) -> void:
	player_name = String(d.get("player_name", ""))
	avatar_id = String(d.get("avatar_id", ""))
	trust = d.get("trust", {"raad": 0, "raha": 0, "mani": 0, "fandogh": 0})
	clues = d.get("clues", {})
	inventory = d.get("inventory", {})
	story_flags = d.get("story_flags", {})
	chapter_progress = d.get("chapter_progress", {})
	endings_seen = d.get("endings_seen", {})
	ending_id = String(d.get("ending_id", ""))
	current_chapter = String(d.get("current_chapter", ""))
	current_scene = String(d.get("current_scene", ""))
	unlocked_chapters = d.get("unlocked_chapters", {"season_01": true})
	coins = int(d.get("coins", 0))
	gems = int(d.get("gems", 0))
	level = maxi(1, int(d.get("level", 1)))
	xp = int(d.get("xp", 0))
	# A save that predates a chapter being free must still get it free.
	unlocked_chapters["season_01"] = true

extends Node
## The stage layer over the story (GDD §5.8).
##
## A chapter is a line of scenes; a stage is the unit the player actually
## plays, scores and can replay. This owns one run of one stage: the loadout
## chosen before it starts, what was found during it, and the score at the
## end.
##
## It sits beside StoryEngine rather than inside it on purpose. StoryEngine
## decides what happens next in the story; this decides what a run was worth.
## Keeping them apart means a stage can be replayed without the story having
## to be rewound, and the story can be played with no stage at all — which is
## what the content tools and the playthrough test do.

signal stage_started(stage_id: String)
signal stage_finished(stage_id: String, result: Dictionary)
signal hint_used(stage_id: String)

## The weights the design fixes (GDD §5.2). Time is only a tiebreaker: if
## the competition becomes a race, a child stops reading and runs, which is
## the opposite of the point of the game.
const WEIGHT_CLUES := 0.40
const WEIGHT_PUZZLES := 0.25
const WEIGHT_SECRET := 0.25
const WEIGHT_TIME := 0.10

## A run at or over this many points earns the star above it.
const STAR_THRESHOLDS := [0.45, 0.70, 0.90]

## How many tools and companions the player takes in (GDD §5.8). The limit
## is what makes the choice a strategy rather than a shopping list.
const TOOL_SLOTS := 2
const COMPANION_SLOTS := 2

var stages: Array = []
var stages_by_id: Dictionary = {}
var chapter_id: String = ""

## The run in progress, empty when no stage is being played.
var run: Dictionary = {}

func _ready() -> void:
	StoryEngine.chapter_loaded.connect(_on_chapter_loaded)
	StoryEngine.scene_entered.connect(_on_scene_entered)
	StoryEngine.chapter_finished.connect(_on_chapter_finished)
	GameState.clue_discovered.connect(_on_clue)

## A stage ends when the story walks out of it. Watching the story rather
## than asking the content to mark an exit means a stage cannot be left
## hanging by a scene whose author forgot to close it — and the story keeps
## knowing nothing about stages, which is the point of the split.
func _on_scene_entered(scene: Dictionary) -> void:
	if not is_running():
		return
	var scene_id := String(scene.get("scene_id", ""))
	if scene_id in stage(String(run["stage_id"])).get("scene_ids", []):
		return
	finish()

func _on_chapter_finished(_chapter_id: String, _ending_id: String) -> void:
	if is_running():
		finish()

func _on_chapter_loaded(id: String) -> void:
	load_stages(StoryEngine.story)
	chapter_id = id

## Reads the stage list out of a loaded story. A chapter with no stages
## still plays; it just has nothing to score.
func load_stages(story: Dictionary) -> void:
	stages = story.get("stages", [])
	stages_by_id.clear()
	for stage: Dictionary in stages:
		stages_by_id[String(stage.get("stage_id", ""))] = stage

func stage(stage_id: String) -> Dictionary:
	return stages_by_id.get(stage_id, {})

## Which stage a scene belongs to, or "" when the chapter has no stages.
func stage_of_scene(scene_id: String) -> String:
	for s: Dictionary in stages:
		if scene_id in s.get("scene_ids", []):
			return String(s.get("stage_id", ""))
	return ""

# — a run ——————————————————————————————————————————————————

## Starts a stage with the chosen loadout and sends the player to its first
## scene. Extra tools or companions beyond the slots are dropped rather than
## silently honoured, so the limit cannot be bypassed by a caller's mistake.
func begin(stage_id: String, tools: Array = [], companions: Array = []) -> bool:
	var s := stage(stage_id)
	if s.is_empty():
		Log.error("StageEngine", "unknown stage '%s'" % stage_id)
		return false
	run = {
		"stage_id": stage_id,
		"tools": tools.slice(0, TOOL_SLOTS),
		"companions": companions.slice(0, COMPANION_SLOTS),
		"started_at": Time.get_ticks_msec(),
		"clues_found": [],
		"puzzles_solved": 0,
		"puzzles_attempted": 0,
		"hints_used": 0,
		"secret_found": false,
		# Each companion's ability, charged fresh for this stage. Charges are
		# free and never bought back mid-stage: a child who runs out has to
		# look, which is the whole exercise.
		"ability_uses": {},
	}
	for c: String in run["companions"]:
		run["ability_uses"][c] = Loadout.USES_PER_STAGE
	# فندق's nose works whether or not he was chosen, so a child who is stuck
	# is never left with nothing (GDD §5.4).
	if not run["ability_uses"].has("fandogh"):
		run["ability_uses"]["fandogh"] = Loadout.USES_PER_STAGE
	Log.info("StageEngine", "stage %s begun with %s / %s" % [
		stage_id, run["tools"], run["companions"]])
	stage_started.emit(stage_id)
	StoryEngine.enter_scene(String(s.get("entry_scene_id", "")))
	return true

func is_running() -> bool:
	return not run.is_empty()

## Whether a tool or companion was brought along. Content asks this through
## the story vocabulary, so a route can open only for the right loadout.
func carrying(tool_id: String) -> bool:
	return tool_id in run.get("tools", [])

func accompanied_by(character_id: String) -> bool:
	return character_id in run.get("companions", [])

func _on_clue(clue_id: String) -> void:
	if not is_running():
		return
	var found: Array = run["clues_found"]
	if clue_id in found:
		return
	found.append(clue_id)
	if clue_id == String(stage(String(run["stage_id"])).get("secret_clue_id", "")):
		run["secret_found"] = true

## Called when a puzzle ends. A puzzle solved after a hint still counts as
## solved — the hint costs score, never progress.
func record_puzzle(solved: bool) -> void:
	if not is_running():
		return
	run["puzzles_attempted"] = int(run["puzzles_attempted"]) + 1
	if solved:
		run["puzzles_solved"] = int(run["puzzles_solved"]) + 1

## How many times a companion's ability can still be used in this stage.
func ability_charges(character_id: String) -> int:
	return int(run.get("ability_uses", {}).get(character_id, 0))

## Spends one charge. Returns false when there is none left, so a caller
## cannot quietly overspend.
func use_ability(character_id: String) -> bool:
	if ability_charges(character_id) <= 0:
		return false
	run["ability_uses"][character_id] = ability_charges(character_id) - 1
	# An ability narrows the search; a hint gives the answer. Only the hint
	# costs score (GDD §5.2), so this records nothing against the run.
	Log.info("StageEngine", "ability of %s used, %d left" % [
		character_id, ability_charges(character_id)])
	return true

func record_hint() -> void:
	if not is_running():
		return
	run["hints_used"] = int(run["hints_used"]) + 1
	hint_used.emit(String(run["stage_id"]))

## Ends the run, scores it, pays out and records the best result.
##
## A replay can only improve a stage's record. Taking something away for a
## worse second attempt would teach a child not to try again, which is the
## opposite of what replay is for (GDD §5.8).
func finish() -> Dictionary:
	if not is_running():
		return {}
	var stage_id := String(run["stage_id"])
	var s := stage(stage_id)
	var result := score(run, s)
	result["stage_id"] = stage_id

	var previous: Dictionary = GameState.stage_record(stage_id)
	var best := maxf(float(previous.get("score", 0.0)), float(result["score"]))
	var stars := maxi(int(previous.get("stars", 0)), int(result["stars"]))
	var first_time := not bool(previous.get("completed", false))
	GameState.set_stage_record(stage_id, {
		"completed": true,
		"score": best,
		"stars": stars,
		"clues": maxi(int(previous.get("clues", 0)), int(result["clues_found"])),
		"no_hint": bool(previous.get("no_hint", false)) or int(run["hints_used"]) == 0,
	})

	# Rewards are paid in full the first time and at a reduced rate on a
	# replay, so replaying for a better star is worth doing but cannot be
	# farmed for currency.
	var rewards: Dictionary = s.get("rewards", {})
	var share := 1.0 if first_time else 0.25
	var coins := int(round(float(rewards.get("coins", 0)) * share))
	var xp := int(round(float(rewards.get("xp", 0)) * share))
	GameState.coins += coins
	GameState.add_xp(xp)
	result["coins"] = coins
	result["xp"] = xp
	result["first_time"] = first_time

	Log.info("StageEngine", "stage %s finished: %d%%, %d star(s)" % [
		stage_id, int(result["score"] * 100.0), int(result["stars"])])
	run = {}
	stage_finished.emit(stage_id, result)
	return result

## Abandons a run without scoring it. Progress in the story is kept; only
## the run's counters are dropped.
func abandon() -> void:
	run = {}

# — scoring ————————————————————————————————————————————————

## Scores a run against its stage, per the weights in GDD §5.2.
##
## Every part is a fraction of what that stage offered, so a short stage and
## a long one are compared fairly and a stage with no puzzles does not
## punish the player for solving none.
func score(of_run: Dictionary, s: Dictionary) -> Dictionary:
	var clue_total := int(s.get("clue_count", 0))
	var puzzle_total := int(s.get("puzzle_count", 0))
	var found := int((of_run.get("clues_found", []) as Array).size())

	var clue_part := 1.0 if clue_total <= 0 else clampf(float(found) / float(clue_total), 0.0, 1.0)
	var clean := int(of_run.get("puzzles_solved", 0)) if int(of_run.get("hints_used", 0)) == 0 else 0
	var puzzle_part := 1.0 if puzzle_total <= 0 else clampf(float(clean) / float(puzzle_total), 0.0, 1.0)
	# Three of chapter one's stages grant no clue of their own — they are
	# the ones that turn on a choice or a puzzle rather than a discovery.
	# Without this their secret could never be found and a quarter of their
	# score would be locked away for good, which would read to a child as
	# the game being broken. For those, reaching the end IS the secret.
	var has_secret_clue := not String(s.get("secret_clue_id", "")).is_empty()
	var secret_part := 1.0
	if has_secret_clue:
		secret_part = 1.0 if bool(of_run.get("secret_found", false)) else 0.0

	var seconds := float(Time.get_ticks_msec() - int(of_run.get("started_at", 0))) / 1000.0
	var par := maxf(float(s.get("par_seconds", 240)), 1.0)
	# Being faster than par earns the time share; being slower loses only
	# that share, never any of the rest.
	var time_part := clampf(par / maxf(seconds, 1.0), 0.0, 1.0)

	var total := clue_part * WEIGHT_CLUES + puzzle_part * WEIGHT_PUZZLES \
		+ secret_part * WEIGHT_SECRET + time_part * WEIGHT_TIME

	var stars := 0
	for threshold: float in STAR_THRESHOLDS:
		if total >= threshold:
			stars += 1

	return {
		"score": total,
		"stars": stars,
		"clues_found": found,
		"clues_total": clue_total,
		"puzzles_solved": int(of_run.get("puzzles_solved", 0)),
		"puzzles_total": puzzle_total,
		"secret_found": bool(of_run.get("secret_found", false)),
		"hints_used": int(of_run.get("hints_used", 0)),
		"seconds": seconds,
	}

# — progress ————————————————————————————————————————————————

## A stage opens when the one before it is finished. The first is always
## open, so a new player is never met with a locked chapter.
func is_open(stage_id: String) -> bool:
	var s := stage(stage_id)
	if s.is_empty():
		return false
	var index := int(s.get("index", 1))
	if index <= 1:
		return true
	for other: Dictionary in stages:
		if int(other.get("index", 0)) == index - 1:
			return bool(GameState.stage_record(String(other.get("stage_id", ""))).get("completed", false))
	return true

func stars_earned() -> int:
	var total := 0
	for s: Dictionary in stages:
		total += int(GameState.stage_record(String(s.get("stage_id", ""))).get("stars", 0))
	return total

func stars_available() -> int:
	return stages.size() * STAR_THRESHOLDS.size()

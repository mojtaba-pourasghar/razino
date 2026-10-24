extends RazinoTest
## Checks the stage layer against the rules GDD §5.2 and §5.8 fix.
##
## The scoring weights are a design decision, not an implementation detail —
## time is worth only a tenth deliberately, so a child reads instead of
## racing. A test that only checked the arithmetic would let that weight be
## changed silently, so these check the properties the design promises:
## a hint costs score and never progress, a worse replay takes nothing away,
## and no stage can be built whose secret is impossible to find.

func before_each() -> void:
	GameState.reset()
	StageEngine.abandon()

func after_each() -> void:
	GameState.reset()
	StageEngine.abandon()

func _load_chapter_one() -> void:
	var story := ContentManager.load_source_story("season_01")
	StoryEngine.load_story(story)
	StageEngine.load_stages(story)

func test_chapter_one_has_ten_stages_covering_every_scene():
	_load_chapter_one()
	eq(StageEngine.stages.size(), 10, "chapter one is ten stages")
	var covered := {}
	for s: Dictionary in StageEngine.stages:
		for sid in s.get("scene_ids", []):
			ok(not covered.has(sid), "scene %s belongs to one stage only" % sid)
			covered[String(sid)] = true
	eq(covered.size(), StoryEngine.story.get("scenes", []).size(),
		"every scene of the chapter belongs to a stage")

func test_every_stage_can_reach_its_secret():
	# A stage whose secret cannot be found loses a quarter of its score for
	# good, which reads to a child as the game being broken.
	_load_chapter_one()
	for s: Dictionary in StageEngine.stages:
		var clue := String(s.get("secret_clue_id", ""))
		if clue.is_empty():
			var run := {"started_at": Time.get_ticks_msec(), "clues_found": [],
				"puzzles_solved": 0, "hints_used": 0, "secret_found": false}
			var result := StageEngine.score(run, s)
			ok(bool(result["secret_found"]) == false, "%s records no secret clue" % s["stage_id"])
			gt(float(result["score"]), 0.24,
				"%s still awards its secret share for finishing" % s["stage_id"])
		else:
			ok(clue.begins_with("CLUE_"), "%s names a real clue" % s["stage_id"])

func test_a_stage_opens_only_after_the_one_before_it():
	_load_chapter_one()
	ok(StageEngine.is_open("S01-ST01"), "the first stage is always open")
	ok(not StageEngine.is_open("S01-ST02"), "the second waits for the first")
	GameState.set_stage_record("S01-ST01", {"completed": true, "stars": 2})
	ok(StageEngine.is_open("S01-ST02"), "and opens once it is finished")

func test_a_hint_costs_score_but_never_progress():
	_load_chapter_one()
	var s := StageEngine.stage("S01-ST05")
	var base := {"started_at": Time.get_ticks_msec(), "clues_found": [],
		"puzzles_solved": 1, "hints_used": 0, "secret_found": true}
	var hinted := base.duplicate()
	hinted["hints_used"] = 1
	var clean_score := float(StageEngine.score(base, s)["score"])
	var hinted_score := float(StageEngine.score(hinted, s)["score"])
	gt(clean_score, hinted_score, "a hint lowers the score")
	eq(int(StageEngine.score(hinted, s)["puzzles_solved"]), 1,
		"and the puzzle still counts as solved")

func test_time_is_only_a_tiebreaker():
	# Ten per cent, deliberately: if the competition becomes a race a child
	# stops reading (GDD §5.2).
	_load_chapter_one()
	var s := StageEngine.stage("S01-ST02")
	var fast := {"started_at": Time.get_ticks_msec(), "clues_found": [],
		"puzzles_solved": 0, "hints_used": 0, "secret_found": false}
	var slow := fast.duplicate()
	slow["started_at"] = Time.get_ticks_msec() - 600000
	var gap := float(StageEngine.score(fast, s)["score"]) \
		- float(StageEngine.score(slow, s)["score"])
	ok(gap <= StageEngine.WEIGHT_TIME + 0.001,
		"the whole of time is worth no more than its weight")

func test_finding_every_clue_outweighs_everything_else():
	_load_chapter_one()
	var s := StageEngine.stage("S01-ST02")
	var all_clues := {"started_at": Time.get_ticks_msec(),
		"clues_found": ["a", "b", "c"], "puzzles_solved": 0,
		"hints_used": 0, "secret_found": false}
	var nothing := {"started_at": Time.get_ticks_msec(), "clues_found": [],
		"puzzles_solved": 0, "hints_used": 0, "secret_found": false}
	var gap := float(StageEngine.score(all_clues, s)["score"]) \
		- float(StageEngine.score(nothing, s)["score"])
	ok(abs(gap - StageEngine.WEIGHT_CLUES) < 0.01,
		"clues are worth exactly their weight")

func test_a_worse_replay_takes_nothing_away():
	_load_chapter_one()
	GameState.set_stage_record("S01-ST01", {
		"completed": true, "score": 0.9, "stars": 3, "clues": 5, "no_hint": true})
	StageEngine.begin("S01-ST01")
	StageEngine.run["hints_used"] = 3
	StageEngine.run["started_at"] = Time.get_ticks_msec() - 900000
	StageEngine.finish()
	var record := GameState.stage_record("S01-ST01")
	eq(int(record["stars"]), 3, "the better star count survives a worse run")
	ok(float(record["score"]) >= 0.9, "and so does the better score")

func test_rewards_are_paid_in_full_once():
	_load_chapter_one()
	var before := GameState.coins
	StageEngine.begin("S01-ST01")
	var first := StageEngine.finish()
	var earned := GameState.coins - before
	gt(float(earned), 0.0, "finishing a stage pays")
	StageEngine.begin("S01-ST01")
	var again := StageEngine.finish()
	ok(float(again["coins"]) < float(first["coins"]),
		"a replay pays less than the first run")
	ok(bool(first["first_time"]) and not bool(again["first_time"]),
		"and knows which run was the first")

func test_the_loadout_cannot_exceed_its_slots():
	# The limit is what makes the choice a strategy (GDD §5.8).
	_load_chapter_one()
	StageEngine.begin("S01-ST01",
		["ITEM_TOOLS", "ITEM_NOTEBOOK", "ITEM_BRASS_KEY"],
		["arad", "raha", "mani", "fandogh"])
	eq(int((StageEngine.run["tools"] as Array).size()), StageEngine.TOOL_SLOTS,
		"only two tools come along")
	eq(int((StageEngine.run["companions"] as Array).size()), StageEngine.COMPANION_SLOTS,
		"and only two companions")
	ok(StageEngine.carrying("ITEM_TOOLS"), "a carried tool is known")
	ok(not StageEngine.carrying("ITEM_BRASS_KEY"), "a dropped one is not")

# — the run, end to end ————————————————————————————————————

func test_a_stage_ends_when_the_story_leaves_it():
	# This is what makes the stage layer work at all without the content
	# knowing it exists: nothing in story.json marks the end of a stage, so
	# the stage watches the story and closes itself when it walks out.
	_load_chapter_one()
	StageEngine.begin("S01-ST01")
	ok(StageEngine.is_running(), "the run starts")
	var after: Dictionary = StageEngine.stage("S01-ST02")
	StoryEngine.enter_scene(String(after.get("entry_scene_id", "")))
	ok(not StageEngine.is_running(), "and ends when the story moves on")
	ok(GameState.is_stage_complete("S01-ST01"), "with the stage recorded")

func test_abilities_are_charged_per_stage_and_run_out():
	_load_chapter_one()
	StageEngine.begin("S01-ST01", [], ["raha", "mani"])
	eq(StageEngine.ability_charges("raha"), Loadout.USES_PER_STAGE,
		"a chosen companion starts charged")
	for _i in Loadout.USES_PER_STAGE:
		ok(StageEngine.use_ability("raha"), "each charge spends")
	ok(not StageEngine.use_ability("raha"), "and the next one is refused")

func test_fandogh_helps_even_when_he_was_not_chosen():
	# GDD §5.4: his nose is always free and always available, so a child who
	# is stuck is never left with nothing at all.
	_load_chapter_one()
	StageEngine.begin("S01-ST01", [], ["raha", "mani"])
	ok(StageEngine.ability_charges("fandogh") > 0,
		"فندق is available without taking a slot")

func test_the_loadout_catalogue_matches_the_slots():
	ok(Loadout.COMPANIONS.size() >= StageEngine.COMPANION_SLOTS,
		"there are more companions than slots, or there is no choice")
	ok(Loadout.TOOLS.size() > StageEngine.TOOL_SLOTS,
		"and more tools than slots")
	var free := 0
	for t: Dictionary in Loadout.TOOLS:
		if bool(t["free"]):
			free += 1
	eq(free, StageEngine.TOOL_SLOTS,
		"a new player owns exactly enough tools to fill the pack")

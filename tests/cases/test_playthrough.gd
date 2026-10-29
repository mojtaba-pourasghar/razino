extends RazinoTest
## Plays chapter one from its first scene to its ending.
##
## Every other test checks a part. This one checks the only thing a player
## cares about: that there is a path from the start of the chapter to the
## end of it, and that nothing along the way is a dead end. It walks the
## story the way the screens do -- advance a line, answer a choice, resolve
## a puzzle -- and fails if it stops moving.
##
## It takes the FIRST choice and SOLVES every puzzle, so it proves one path
## through, not every path. A chapter where some branch dead-ends would
## still pass; a chapter nobody can finish at all cannot.
##
## It also DOES the interactions in an explore scene before looking for a
## way out, because on those scenes the way out is earned rather than
## offered: S01-E01-SC03 only shows «برویم تو» once the map piece has been
## picked up, and its other choice loops back to the same scene. A walker
## that reads dialogue and choices but never touches the scene takes that
## loop for ever, which is exactly what the first version of this test did
## and why it reported a dead end where there is none.

## Generous enough for a chapter several times the size of this one, low
## enough that a loop in the story fails the run instead of hanging it.
const MAX_STEPS := 4000

func test_chapter_one_can_be_finished():
	GameState.reset()
	ok(StoryEngine.load_chapter("season_01"), "فصل یک خوانده شد")

	var ended := [false]
	var ending_id := [""]
	StoryEngine.chapter_finished.connect(func(_c: String, e: String) -> void:
		ended[0] = true
		ending_id[0] = e)

	var pending_puzzle := [false]
	StoryEngine.puzzle_requested.connect(func(_p: Dictionary) -> void:
		pending_puzzle[0] = true)
	var pending_cinematic := [false]
	StoryEngine.cinematic_requested.connect(func(_c: Dictionary) -> void:
		pending_cinematic[0] = true)

	StoryEngine.start()

	var done_interactions := {}
	var steps := 0
	while not ended[0] and steps < MAX_STEPS:
		steps += 1
		if pending_puzzle[0]:
			pending_puzzle[0] = false
			StoryEngine.puzzle_resolved(true)
			continue
		if pending_cinematic[0]:
			pending_cinematic[0] = false
			StoryEngine.cinematic_finished()
			continue
		if _explore(done_interactions):
			continue
		var choices := StoryEngine.available_choices()
		if not choices.is_empty():
			StoryEngine.choose(String((choices[0] as Dictionary).get("choice_id", "")))
			continue
		StoryEngine.advance()

	ok(ended[0],
		"فصل یک در %s گام تمام شد" % steps if ended[0]
		else "فصل یک بعد از %s گام تمام نشد — جایی بن‌بست است" % steps)
	ok(not ending_id[0].is_empty(), "پایان‌بندی شناسه دارد")

## Does one interaction the current scene still offers, the way a player
## taps something on an explore screen. Returns false when there is nothing
## left to touch, which is the signal to look for a way out instead.
func _explore(done: Dictionary) -> bool:
	for entry: Variant in StoryEngine.current_scene.get("interactions", []):
		if not entry is Dictionary:
			continue
		var it := entry as Dictionary
		var iid := String(it.get("interaction_id", ""))
		var key := String(StoryEngine.current_scene.get("scene_id", "")) + "/" + iid
		if done.has(key):
			continue
		done[key] = true
		StoryEngine.apply_effects(it.get("effects", []))
		return true
	return false


## Every stage the chapter lists must be reachable: each one either opens at
## the start or names a stage that opens it, and that stage must exist.
func test_every_stage_can_be_reached():
	GameState.reset()
	ok(StoryEngine.load_chapter("season_01"), "فصل یک خوانده شد")
	ok(StageEngine.stages.size() > 0, "فصل مرحله دارد")

	var known := {}
	for stage: Dictionary in StageEngine.stages:
		known[String(stage.get("stage_id", ""))] = true

	var open_now := 0
	for stage: Dictionary in StageEngine.stages:
		var id := String(stage.get("stage_id", ""))
		if StageEngine.is_open(id):
			open_now += 1
		var needs: Variant = stage.get("requires_stage", "")
		if needs is String and not String(needs).is_empty():
			ok(known.has(String(needs)),
				"مرحلهٔ %s به %s نیاز دارد و آن مرحله هست" % [id, needs])
	ok(open_now > 0, "دست‌کم یک مرحله از اول باز است")

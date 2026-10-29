extends RazinoTest
## The obstacles a scene names have to be reachable, not merely present.
##
## A ledge placed higher than the character can jump, or a gap wider than
## they can clear, does not look like a bug: the scene loads, the art is
## right, and the player simply cannot get past. It is the kind of fault
## that is only found by someone playing to the end, which is why it is
## worth a test that does the arithmetic instead.

const VIEW := Vector2(1280, 720)

## What the walker can actually do, from its own constants, so these stay
## true if the feel of the jump is ever retuned.
func _jump_height() -> float:
	# v² / 2a, with the rising gravity.
	return (Walker.JUMP_SPEED * Walker.JUMP_SPEED) / (2.0 * Walker.GRAVITY)

func _jump_distance() -> float:
	# Up at JUMP_SPEED, down under the heavier falling gravity, moving
	# sideways at full speed the whole time.
	var up := Walker.JUMP_SPEED / Walker.GRAVITY
	var down := Walker.JUMP_SPEED / Walker.FALL_GRAVITY
	return Walker.RUN_SPEED * (up + down)

func test_a_jump_clears_a_reasonable_gap():
	ok(_jump_height() > 100.0, "پرش دست‌کم صد پیکسل بالا می‌رود")
	ok(_jump_distance() > 200.0, "پرش دست‌کم دویست پیکسل جلو می‌رود")

func test_every_ledge_is_within_reach_and_every_gap_can_be_jumped():
	var story := _story()
	ok(not story.is_empty(), "فصل یک خوانده شد")
	var checked := 0
	for entry: Variant in story.get("scenes", []):
		if not entry is Dictionary:
			continue
		var scene := entry as Dictionary
		var obstacles: Variant = scene.get("obstacles", [])
		if not obstacles is Array or (obstacles as Array).is_empty():
			continue
		var sid := String(scene.get("scene_id", "?"))
		var ground: float = float(scene.get("ground_y", 0.92))
		# World width: the backdrop is scaled to the view's height, and the
		# shipped art is 16:9, so a fraction of the width is this wide.
		var world := VIEW.y * (1280.0 / 614.0)
		var reach := _jump_height()
		var floor_y := VIEW.y * ground
		var highest := floor_y

		for o: Variant in obstacles as Array:
			if not o is Dictionary:
				continue
			var it := o as Dictionary
			var kind := String(it.get("kind", "ledge"))
			if kind == "gap":
				var width: float = float(it.get("w", 0.0)) * world
				ok(width < _jump_distance() * 0.8,
					"%s — شکاف %.0f پیکسلی از پرش کوتاه‌تر است" % [sid, width])
			elif kind == "ledge":
				var top: float = float(it.get("y", 0.0)) * VIEW.y
				# A ledge is reached from the ground or from the ledge below
				# it, so each one is measured against the highest so far.
				ok(highest - top < reach,
					"%s — پله در %.0f از %.0f رسیدنی است" % [sid, top, highest])
				highest = minf(highest, top)
			checked += 1
	ok(checked > 0, "دست‌کم یک مانع بررسی شد")

## Every explore scene should have something in it. A scene with a painting
## and nothing to get past is the thing this whole change is replacing.
func test_every_explore_scene_has_obstacles():
	for entry: Variant in _story().get("scenes", []):
		if not entry is Dictionary:
			continue
		var scene := entry as Dictionary
		if String(scene.get("scene_type", "")) != "explore":
			continue
		var obstacles: Variant = scene.get("obstacles", [])
		ok(obstacles is Array and not (obstacles as Array).is_empty(),
			"%s مانع دارد" % scene.get("scene_id", "?"))

func _story() -> Dictionary:
	var f := FileAccess.open("res://content/season_01/story.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

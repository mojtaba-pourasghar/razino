extends RazinoTest
## Every sound the game asks for must exist and must load.
##
## The game shipped for months with a complete audio system and no audio:
## AudioManager is called from seventeen places and every call quietly found
## nothing. Nothing failed, so nothing showed it -- the game was simply
## silent. These assertions make that state fail loudly instead.
##
## Voice-over is deliberately not covered. Those lines are recorded by
## people in a studio, and a test that demanded them would have to be
## switched off until the day they exist, which is how a test stops being
## read at all.

const SFX := [
	"SFX_UI_TAP", "SFX_UI_CHOICE", "SFX_UI_SOFT_NO", "SFX_CLUE_FOUND",
	"SFX_CLUE_COMBINE", "SFX_PUZZLE_OK", "SFX_CLOCK_ACTIVATE",
]

func test_every_sound_effect_exists_and_loads():
	for id: String in SFX:
		var path := "res://assets/audio/sfx/%s.ogg" % id
		ok(ResourceLoader.exists(path), "%s هست" % id)
		var stream := ResourceLoader.load(path) as AudioStream
		ok(stream != null, "%s بار می‌شود" % id)
		if stream != null:
			ok(stream.get_length() > 0.02, "%s طول دارد" % id)

## Every music_id named anywhere in the shipped chapter must have a file,
## so a scene cannot ask for a track that was never made.
func test_every_track_the_chapter_asks_for_exists():
	var story := _read_json("res://content/season_01/story.json")
	ok(not story.is_empty(), "فصل یک خوانده شد")
	var wanted := {}
	for scene: Variant in story.get("scenes", []):
		if scene is Dictionary:
			var id := String((scene as Dictionary).get("music_id", ""))
			if not id.is_empty():
				wanted[id] = true
	ok(wanted.size() > 0, "فصل دست‌کم یک آهنگ می‌خواهد")
	for id: String in wanted.keys():
		ok(ResourceLoader.exists("res://assets/audio/music/%s.ogg" % id),
			"آهنگ %s هست" % id)

## A bed that is not marked as looping stops after half a minute and leaves
## the scene in silence, which is worse than never having had music.
func test_music_beds_are_long_enough_to_sit_under_a_scene():
	for id: String in ["MUS_TOWN_DAY", "MUS_SCHOOL_MYSTERY", "MUS_TOWER"]:
		var stream := ResourceLoader.load(
			"res://assets/audio/music/%s.ogg" % id) as AudioStream
		ok(stream != null, "%s بار می‌شود" % id)
		if stream != null:
			ok(stream.get_length() > 20.0, "%s دست‌کم بیست ثانیه است" % id)

func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

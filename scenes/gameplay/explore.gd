extends RazinoScreen
## UI-06 — محیط قابل بازی. The screen the game actually happens on.
##
## It owns the loop GDD §3 describes: enter a scene, move and examine, talk and
## collect clues, solve or choose, see the reaction, save, and move on. The
## stage, the dialogue box and the puzzle panel are all children here, so a
## scene changing type never costs a screen transition — which is what keeps
## the story feeling continuous rather than like a stack of menus.

var _stage: SceneStage
var _hotspots: Control
var _dialogue: DialoguePanel
var _puzzle: PuzzlePanel
var _toast: Label
var _quest: PanelContainer

## Hearts shown on the HUD. The story never takes one away yet — nothing in
## chapter one can hurt the player — so these read as a promise the design
## makes rather than a resource being spent.
const HEARTS := 3

var _chapter_id: String = "season_01"
var _used_interactions: Dictionary = {}

func _ready() -> void:
	configure("")
	super._ready()

func build_content() -> void:
	var payload := Router.take_payload()
	_chapter_id = String(payload.get("chapter_id", GameState.current_chapter))
	if _chapter_id.is_empty():
		_chapter_id = "season_01"

	# The stage IS the background on this screen, so the shell's backdrop must
	# get out of the way or it paints straight over the scene. The gilded
	# border is a separate node and stays.
	background.visible = false
	_stage = SceneStage.new()
	_stage.chapter_id = _chapter_id
	add_child(_stage)
	move_child(_stage, 0)

	_hotspots = Control.new()
	_hotspots.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hotspots.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_hotspots)

	_build_hud()

	_toast = Style.make_body("", Palette.FS_LABEL, Palette.NIGHT)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0

	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	# Grows upward from the bottom edge, so a long line or a third choice
	# pushes the box taller instead of being cut off.
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_top = -300
	bottom.offset_left = SAFE_MARGIN
	bottom.offset_right = -SAFE_MARGIN
	bottom.offset_bottom = -SAFE_MARGIN
	bottom.add_theme_constant_override("separation", Palette.PAD_SM)
	# Boxes sit on the bottom edge and grow upward only as far as their text
	# needs, rather than stretching to fill the reserved strip.
	bottom.alignment = BoxContainer.ALIGNMENT_END
	add_child(bottom)

	var toast_wrap := PanelContainer.new()
	toast_wrap.add_theme_stylebox_override("panel", OrnateBox.make(
		OrnateBox.Kind.BUTTON, Palette.GOLD_BRIGHT, Palette.GOLD_DEEP,
		Palette.R_MD, 2.5).with_margins(Palette.PAD_MD, Palette.PAD_XS))
	toast_wrap.add_child(_toast)
	toast_wrap.modulate.a = 0.0
	bottom.add_child(toast_wrap)
	_toast.set_meta("wrap", toast_wrap)

	_dialogue = DialoguePanel.new()
	_dialogue.continue_pressed.connect(func(): StoryEngine.advance())
	_dialogue.choice_selected.connect(func(cid): StoryEngine.choose(cid))
	bottom.add_child(_dialogue)

	_puzzle = PuzzlePanel.new()
	_puzzle.visible = false
	_puzzle.solved.connect(func(): StoryEngine.puzzle_resolved(true))
	_puzzle.skipped.connect(func(): StoryEngine.puzzle_resolved(false))
	bottom.add_child(_puzzle)

	_connect_engine()
	_begin(bool(payload.get("resume", false)))

func _build_hud() -> void:
	# The HUD the reference sheet draws. It is built rather than painted,
	# unlike the menus: in the sheet the HUD sits ON the picture, so there
	# is no frame to cut it out of — and the picture underneath has to be
	# the real chapter scene, not the sheet's painted town.

	# Top left: who you are, and how you are doing.
	var left := HBoxContainer.new()
	left.layout_direction = Control.LAYOUT_DIRECTION_LTR
	left.add_theme_constant_override("separation", Palette.PAD_SM)
	left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	left.offset_left = SAFE_MARGIN
	left.offset_top = SAFE_MARGIN
	add_child(left)

	var face := Medallion.new("friend", 62.0)
	face.tooltip_text = "پروفایل"
	face.pressed.connect(func(): Router.go("UI-17"))
	left.add_child(face)

	var hearts := HBoxContainer.new()
	hearts.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts.add_theme_constant_override("separation", 2)
	for i in HEARTS:
		hearts.add_child(IconRect.new("heart", 34.0, Palette.RUBY_LIGHT))
	left.add_child(hearts)

	# Top right: what you own, then the way out.
	var right := HBoxContainer.new()
	right.layout_direction = Control.LAYOUT_DIRECTION_LTR
	right.add_theme_constant_override("separation", Palette.PAD_SM)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_right = -SAFE_MARGIN
	right.offset_top = SAFE_MARGIN
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(right)
	right.add_child(Style.make_chip("coin", GameState.coins, Palette.ORANGE))
	right.add_child(Style.make_chip("gem", GameState.gems, Palette.BLUE))
	var pause := Medallion.new("gear", 62.0)
	pause.tooltip_text = "توقف"
	pause.pressed.connect(func():
		SaveManager.save()
		Router.go("UI-04"))
	right.add_child(pause)

	# Under the purse: what the player is supposed to be doing. The sheet
	# puts it here because it is the one thing a child re-reads.
	_quest = Style.make_two_line_plaque("مأموریت فعلی", "")
	_quest.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_quest.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_quest.offset_right = -SAFE_MARGIN
	_quest.offset_top = SAFE_MARGIN + 78
	_quest.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_quest)

	# Right edge: the things you do.
	var actions := VBoxContainer.new()
	actions.layout_direction = Control.LAYOUT_DIRECTION_LTR
	actions.add_theme_constant_override("separation", Palette.PAD_SM)
	actions.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	actions.offset_right = -SAFE_MARGIN
	actions.offset_left = -SAFE_MARGIN - 70
	actions.offset_top = -40
	actions.offset_bottom = 170
	add_child(actions)
	for action in [
		{"icon": "magnifier", "tip": "دفتر سرنخ‌ها", "ui": "UI-08"},
		{"icon": "backpack", "tip": "کوله‌پشتی", "ui": "UI-19"},
	]:
		var medal := Medallion.new(String(action["icon"]), 66.0)
		medal.tooltip_text = String(action["tip"])
		var ui_id := String(action["ui"])
		medal.pressed.connect(func():
			AudioManager.play_sfx("SFX_UI_TAP")
			Router.go(ui_id, {"return_to": "UI-06", "chapter_id": _chapter_id}))
		actions.add_child(medal)

func _connect_engine() -> void:
	StoryEngine.scene_entered.connect(_on_scene_entered)
	StoryEngine.line_shown.connect(_on_line_shown)
	StoryEngine.choices_offered.connect(_on_choices)
	StoryEngine.puzzle_requested.connect(_on_puzzle)
	StoryEngine.cinematic_requested.connect(_on_cinematic)
	StoryEngine.chapter_finished.connect(_on_chapter_finished)
	StoryEngine.story_error.connect(_on_story_error)
	GameState.clue_discovered.connect(_on_clue_discovered)

func _exit_tree() -> void:
	for sig in [StoryEngine.scene_entered, StoryEngine.line_shown, StoryEngine.choices_offered,
			StoryEngine.puzzle_requested, StoryEngine.cinematic_requested,
			StoryEngine.chapter_finished, StoryEngine.story_error, GameState.clue_discovered]:
		for conn in sig.get_connections():
			if (conn["callable"] as Callable).get_object() == self:
				sig.disconnect(conn["callable"])

func _begin(resume: bool) -> void:
	if not ContentManager.is_installed(_chapter_id):
		Router.go("UI-16", {"reason": "chapter_missing", "chapter_id": _chapter_id})
		return
	if not StoryEngine.load_chapter(_chapter_id):
		Router.go("UI-16", {"reason": "story_unreadable", "chapter_id": _chapter_id})
		return
	if resume:
		StoryEngine.resume()
	else:
		StoryEngine.start()

# — engine callbacks ——————————————————————————————————————

func _on_scene_entered(scene: Dictionary) -> void:
	_stage.show_scene(scene)
	_puzzle.visible = false
	_dialogue.visible = true
	_rebuild_hotspots(scene)
	_update_quest(scene)

## The quest plaque says which stage the player is in, which is the thing a
## child re-reads when they put the game down and pick it up again. A scene
## outside any stage leaves the plaque showing the scene's own title rather
## than going blank.
func _update_quest(scene: Dictionary) -> void:
	if _quest == null:
		return
	var scene_id := String(scene.get("scene_id", ""))
	var stage_id := StageEngine.stage_of_scene(scene_id)
	var line := String(scene.get("title", ""))
	if not stage_id.is_empty():
		var stage := StageEngine.stage(stage_id)
		line = String(stage.get("title", line))
	for child in _quest.get_children():
		child.queue_free()
	var replacement := Style.make_two_line_plaque("مأموریت فعلی", line)
	for child in replacement.get_children():
		replacement.remove_child(child)
		_quest.add_child(child)
	replacement.queue_free()

func _on_line_shown(line: Dictionary, _index: int, _total: int) -> void:
	var speaker := String(line.get("speaker_id", ""))
	_stage.highlight_speaker(speaker)
	_dialogue.show_line(line, _display_name(speaker))

func _on_choices(choices: Array) -> void:
	_stage.highlight_speaker("")
	_dialogue.show_choices(choices)

func _on_puzzle(puzzle: Dictionary) -> void:
	_dialogue.visible = false
	_puzzle.visible = true
	_puzzle.load_puzzle(puzzle)

func _on_cinematic(cinematic: Dictionary) -> void:
	_dialogue.visible = true
	_puzzle.visible = false
	_play_cinematic(cinematic)

func _on_chapter_finished(chapter_id: String, ending_id: String) -> void:
	SaveManager.save()
	Router.go("UI-10", {"finished": chapter_id, "ending": ending_id})

func _on_story_error(message: String) -> void:
	Router.go("UI-16", {"reason": "story_error", "message": message})

func _on_clue_discovered(clue_id: String) -> void:
	_show_toast("سرنخ تازه: %s" % ClueJournal.title_of(clue_id))

# — interactions ———————————————————————————————————————————

func _rebuild_hotspots(scene: Dictionary) -> void:
	for c in _hotspots.get_children():
		c.queue_free()
	for entry in scene.get("interactions", []):
		var it: Dictionary = entry
		var iid := String(it.get("interaction_id", ""))
		if bool(it.get("once", false)) and _used_interactions.has(iid):
			continue
		if not StoryEngine.evaluate(it.get("conditions", {})):
			continue
		_hotspots.add_child(_make_hotspot(it))

func _make_hotspot(it: Dictionary) -> Control:
	var rect: Array = it.get("rect", [0.4, 0.45, 0.2, 0.2])
	var button := Button.new()
	button.text = String(it.get("label", ""))
	button.tooltip_text = String(it.get("description", ""))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.anchor_left = float(rect[0])
	button.anchor_top = float(rect[1])
	button.anchor_right = float(rect[0]) + float(rect[2])
	button.anchor_bottom = float(rect[1]) + float(rect[3])
	button.offset_right = 0
	button.offset_bottom = 0
	button.custom_minimum_size = Vector2(Palette.TOUCH_MIN * 2, Palette.TOUCH_MIN)

	# Hotspots sit on top of a painting, so they are translucent with a bright
	# outline: visible enough to find, light enough not to hide the picture.
	# A hotspot must not hide the painting behind it, so its face is a
	# translucent well rather than a solid panel.
	var dim := Color(Palette.NIGHT.r, Palette.NIGHT.g, Palette.NIGHT.b, 0.55)
	button.add_theme_stylebox_override("normal", OrnateBox.make(
		OrnateBox.Kind.WELL, dim, dim, Palette.R_MD, 2.0).with_margins(Palette.PAD_XS, Palette.PAD_XS))
	var lit := Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.42)
	button.add_theme_stylebox_override("hover", OrnateBox.make(
		OrnateBox.Kind.WELL, lit, lit, Palette.R_MD, 2.0).with_margins(Palette.PAD_XS, Palette.PAD_XS))
	button.add_theme_color_override("font_color", Palette.SNOW)
	button.add_theme_font_size_override("font_size", Style.scaled(Palette.FS_CAPTION))

	button.pressed.connect(func(): _use_interaction(it))
	return button

func _use_interaction(it: Dictionary) -> void:
	var iid := String(it.get("interaction_id", ""))
	AudioManager.play_sfx("SFX_UI_TAP")
	StoryEngine.apply_effects(it.get("effects", []))
	if bool(it.get("once", false)):
		_used_interactions[iid] = true
	var description := String(it.get("description", ""))
	if not description.is_empty():
		_show_toast(description)
	SaveManager.mark_dirty()
	_rebuild_hotspots(StoryEngine.current_scene)
	# An interaction may have unlocked a choice that was hidden a moment ago.
	var choices := StoryEngine.available_choices()
	if not choices.is_empty():
		_dialogue.show_choices(choices)

# — cinematics ————————————————————————————————————————————

func _play_cinematic(cinematic: Dictionary) -> void:
	var beats: Array = cinematic.get("beats", [])
	for beat in beats:
		var b: Dictionary = beat
		var bg := String(b.get("background_id", ""))
		if not bg.is_empty():
			_stage.show_scene({"background_id": bg})
		_dialogue.show_line({"text": b.get("text", ""), "audio_id": b.get("audio_id", "")}, "")
		# A cinematic beat waits for the voice line, or for the player to tap.
		await _wait_for_beat(float(b.get("seconds", 4.0)))
		if not is_inside_tree():
			return
	StoryEngine.cinematic_finished()

func _wait_for_beat(seconds: float) -> void:
	var timer := get_tree().create_timer(maxf(seconds, 1.0))
	await timer.timeout

# — small helpers ——————————————————————————————————————————

func _display_name(character_id: String) -> String:
	if character_id == "player":
		return GameState.player_name if not GameState.player_name.is_empty() else "تو"
	for c in StoryEngine.story.get("characters", []):
		if String((c as Dictionary).get("character_id", "")) == character_id:
			return String((c as Dictionary).get("name", character_id))
	return character_id

func _show_toast(text: String) -> void:
	_toast.text = text
	var wrap: Control = _toast.get_meta("wrap")
	wrap.modulate.a = 1.0
	if Settings.reduce_motion:
		await get_tree().create_timer(2.2).timeout
		wrap.modulate.a = 0.0
		return
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(wrap, "modulate:a", 0.0, 0.4)

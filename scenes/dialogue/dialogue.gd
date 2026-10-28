extends RazinoScreen
## UI-07 — دیالوگ و انتخاب, as a screen in its own right.
##
## In play, dialogue is a panel inside UI-06 so the picture never leaves the
## screen. This standalone entry exists for the cases where a conversation is
## the whole screen — a preview from the content tool, or a jump straight to a
## conversation from a link — and uses the same DialoguePanel, so there is one
## implementation of Persian dialogue, not two.

var _panel: DialoguePanel

func _ready() -> void:
	configure("گفت‌وگو", "UI-04")
	super._ready()

func build_content() -> void:
	var payload := Router.take_payload()
	# As the panel sheet draws it: the scene fills one framed window, the
	# speakers stand large in it, and the parchment lies over the foot of
	# the picture rather than under it.
	var window := PanelContainer.new()
	window.size_flags_vertical = Control.SIZE_EXPAND_FILL
	window.add_theme_stylebox_override("panel", UiBox.make(UiBox.Kind.PANEL, 10, 10))
	content.add_child(window)
	var room := Control.new()
	room.clip_contents = true
	window.add_child(room)

	var stage := SceneStage.new()
	stage.figure_height = 0.84
	room.add_child(stage)

	_panel = DialoguePanel.new()
	_panel.anchor_left = 0.08
	_panel.anchor_right = 0.92
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -14
	room.add_child(_panel)

	var scene_id := String(payload.get("scene_id", ""))
	var chapter_id := String(payload.get("chapter_id", GameState.current_chapter))
	stage.chapter_id = chapter_id
	if chapter_id.is_empty() or scene_id.is_empty():
		_panel.show_line({"text": "گفت‌وگویی برای نمایش انتخاب نشده است."}, "")
		return

	if not StoryEngine.load_chapter(chapter_id):
		_panel.show_line({"text": "محتوای این فصل در دسترس نیست."}, "")
		return
	StoryEngine.line_shown.connect(func(line, _i, _t):
		var speaker := String(line.get("speaker_id", ""))
		stage.highlight_speaker(speaker)
		_panel.show_line(line, _display_name(speaker)))
	StoryEngine.scene_entered.connect(func(scene): stage.show_scene(scene))
	_panel.continue_pressed.connect(func(): StoryEngine.advance())
	_panel.choice_selected.connect(func(cid): StoryEngine.choose(cid))
	StoryEngine.enter_scene(scene_id)

## The character's Persian name, not the id the content uses internally.
func _display_name(character_id: String) -> String:
	if character_id == "player":
		return GameState.player_name if not GameState.player_name.is_empty() else "تو"
	for c in StoryEngine.story.get("characters", []):
		if String((c as Dictionary).get("character_id", "")) == character_id:
			return String((c as Dictionary).get("name", character_id))
	return character_id

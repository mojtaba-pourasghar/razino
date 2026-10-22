class_name SceneStage
extends Control
## The picture behind a scene: background, parallax layers and the characters
## standing in it (GDD §4, "حرکت دوربین و عمق محیط").
##
## A scene shows its painting when one exists and a marked stand-in when it
## does not, because the paintings arrive a few a day and a half-painted game
## is the normal state for the whole life of that pipeline. The character
## figures are drawn from the same vector routine as the player's avatar, so
## the cast looks like one family rather than a set of boxes.

const SLOTS := {
	"far_left": 0.16, "left": 0.32, "center": 0.5, "right": 0.68, "far_right": 0.84,
}

var _bg: PlaceholderArt
var _art: TextureRect
var _figures: Control
var _drift: float = 0.0

## The chapter whose paintings to look in; set before show_scene().
var chapter_id: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_bg = PlaceholderArt.new()
	add_child(_bg)
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# Letterbox rather than crop, so the important part of a scene is never
	# cut off on an unusual aspect ratio (GDD §10.3).
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.visible = false
	add_child(_art)
	_figures = Control.new()
	_figures.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_figures.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_figures)
	set_process(not Settings.reduce_motion)

func _process(delta: float) -> void:
	# A very slow horizontal drift reads as depth without ever moving enough
	# to distract from the text. The offset goes to the background's own draw
	# routine; moving the control itself would break its anchoring.
	_drift += delta * 0.12
	var offset := sin(_drift) * 10.0
	_bg.drift = offset
	# The painting drifts by its own pivot rather than its position, for the
	# same reason the stand-in does: writing position on an anchored control
	# converts its anchors to fixed offsets at whatever size it had.
	_art.pivot_offset = Vector2(-offset, 0.0)

func show_scene(scene: Dictionary) -> void:
	var bg_id := String(scene.get("background_id", ""))
	var painted := SceneArt.load_texture(bg_id, chapter_id)
	_art.texture = painted
	_art.visible = painted != null
	_bg.visible = painted == null
	_bg.background_id = bg_id
	for child in _figures.get_children():
		child.queue_free()
	for c in scene.get("characters", []):
		_add_figure(c as Dictionary)

func _add_figure(entry: Dictionary) -> void:
	var fig := CharacterFigure.new()
	fig.character_id = String(entry.get("character_id", ""))
	fig.pose = String(entry.get("animation", "idle"))
	var slot := String(entry.get("position", "center"))
	var x := float(SLOTS.get(slot, 0.5))
	fig.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fig.anchor_left = x
	fig.anchor_right = x
	fig.anchor_top = 1.0
	fig.anchor_bottom = 1.0
	fig.offset_left = -90
	fig.offset_right = 90
	fig.offset_top = -340
	fig.offset_bottom = -20
	_figures.add_child(fig)

func highlight_speaker(speaker_id: String) -> void:
	for child in _figures.get_children():
		if child is CharacterFigure:
			(child as CharacterFigure).set_speaking((child as CharacterFigure).character_id == speaker_id)

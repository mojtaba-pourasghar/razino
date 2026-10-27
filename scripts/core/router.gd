extends Node
## Screen router. Every screen in GDD §7.1 is registered here by its UI id, so
## navigation is by stable identifier rather than by file path, and the content
## data can name a destination without knowing the project layout.

signal screen_changed(ui_id: String)

const SCREENS := {
	"UI-01": "res://scenes/boot/boot.tscn",
	"UI-02": "res://scenes/menus/intro.tscn",
	"UI-03": "res://scenes/menus/avatar_builder.tscn",
	"UI-04": "res://scenes/menus/home.tscn",
	"UI-05": "res://scenes/menus/world_map.tscn",
	"UI-06": "res://scenes/gameplay/explore.tscn",
	"UI-07": "res://scenes/dialogue/dialogue.tscn",
	"UI-08": "res://scenes/menus/clue_journal.tscn",
	"UI-09": "res://scenes/puzzles/puzzle_host.tscn",
	"UI-10": "res://scenes/menus/chapter_map.tscn",
	"UI-11": "res://scenes/menus/store.tscn",
	"UI-12": "res://scenes/menus/avatar_wardrobe.tscn",
	"UI-13": "res://scenes/menus/settings.tscn",
	"UI-14": "res://scenes/menus/parent_zone.tscn",
	"UI-15": "res://scenes/menus/downloads.tscn",
	"UI-16": "res://scenes/menus/error_recovery.tscn",
	# Screens the approved sheets add (docs/UI_SPEC.md §5).
	"UI-17": "res://scenes/menus/profile.tscn",
	"UI-18": "res://scenes/menus/notifications.tscn",
	"UI-19": "res://scenes/menus/inventory.tscn",
	# The stage layer (GDD §5.8): pick a stage, pack for it, see what it was
	# worth. Nothing here is a detour — this is how a chapter is played.
	"UI-20": "res://scenes/menus/stage_select.tscn",
	"UI-21": "res://scenes/menus/loadout.tscn",
	"UI-22": "res://scenes/menus/stage_result.tscn",
	# Signing in. Nothing in chapter one needs it; it is what makes a bought
	# chapter follow a child from a phone to a tablet.
	"UI-23": "res://scenes/menus/sign_in.tscn",
}

const FADE_SECONDS := 0.22

var current_ui_id: String = ""
## Arbitrary payload handed to the next screen; it reads this in _ready().
var payload: Dictionary = {}

var _fade: ColorRect
var _busy: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()

func _build_fade_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.name = "RouterFade"
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Palette.NIGHT
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)

func go(ui_id: String, with_payload: Dictionary = {}) -> void:
	if _busy:
		Log.warn("Router", "navigation to %s ignored; already switching" % ui_id)
		return
	if not SCREENS.has(ui_id):
		Log.error("Router", "unknown screen id '%s'" % ui_id)
		return
	var path: String = SCREENS[ui_id]
	if not ResourceLoader.exists(path):
		Log.error("Router", "screen %s missing at %s" % [ui_id, path])
		return
	payload = with_payload
	_busy = true
	await _fade_to(1.0)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		Log.error("Router", "change_scene_to_file failed for %s: %d" % [ui_id, err])
	else:
		current_ui_id = ui_id
		screen_changed.emit(ui_id)
		Log.info("Router", "-> %s" % ui_id)
	# One frame so the new tree is live before the curtain lifts.
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false

func take_payload() -> Dictionary:
	var p := payload
	payload = {}
	return p

func _fade_to(alpha: float) -> void:
	if _fade == null:
		return
	if Settings.reduce_motion:
		_fade.modulate.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished

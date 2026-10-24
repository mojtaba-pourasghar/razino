extends Node
## Renders a few screens at real device shapes.
##
## The game ships on phones and tablets, and those are much wider than the
## 16:9 the editor runs at — a 20:9 phone in landscape is 2.22:1 against a
## tablet's 1.33:1. A layout that reads well in the editor can letterbox
## badly on both, and nothing in the test suite would say so.

const SHAPES := [
	{"name": "phone_20x9", "size": Vector2i(2400, 1080)},
	{"name": "phone_19x9", "size": Vector2i(2340, 1080)},
	{"name": "tablet_16x10", "size": Vector2i(2560, 1600)},
	{"name": "tablet_4x3", "size": Vector2i(2048, 1536)},
]

const SCREENS := ["UI-13", "UI-17", "UI-01"]
const OUT_DIR := "user://device"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	GameState.player_name = "نگار"
	GameState.coins = 2840
	GameState.gems = 125
	GameState.level = 5
	GameState.xp = 320
	await get_tree().process_frame

	for shape in SHAPES:
		var size: Vector2i = shape["size"]
		# Scaled to something renderable while keeping the exact shape.
		var scale := 1280.0 / float(size.x)
		var window := Vector2i(1280, int(round(size.y * scale)))
		get_window().size = window
		await get_tree().process_frame
		for ui_id in SCREENS:
			await _capture(ui_id, String(shape["name"]))
	print("DEVICE SHOTS: %s" % ProjectSettings.globalize_path(OUT_DIR))
	get_tree().quit(0)

func _capture(ui_id: String, shape: String) -> void:
	var packed: PackedScene = load(Router.SCREENS[ui_id])
	var instance := packed.instantiate()
	add_child(instance)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var out := "%s/%s_%s.png" % [OUT_DIR, shape, ui_id.replace("-", "")]
	image.save_png(out)
	print("%s %s -> %dx%d" % [shape, ui_id, image.get_width(), image.get_height()])
	instance.queue_free()
	await get_tree().process_frame

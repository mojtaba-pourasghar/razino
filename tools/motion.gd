extends Node
## Drives the playfield with a scripted run-and-jump and photographs it, so
## the movement can be judged from stills instead of described.
##
##   xvfb-run -a godot --path . res://tools/motion.tscn

const OUT := "user://motion"
const VIEW := Vector2(1280, 720)
## (seconds from start, steer, jump) — a run, a jump, a landing, a turn.
const SCRIPT := [
	[0.0, 0.0, false], [0.3, 1.0, false], [0.9, 1.0, true], [1.0, 1.0, false],
	[1.6, 1.0, false], [2.1, -1.0, false], [2.6, -1.0, true], [2.7, -1.0, false],
	[3.4, 0.0, false],
]
const SHOTS := [0.25, 0.60, 0.95, 1.15, 1.45, 1.75, 2.30, 2.70, 2.95, 3.60]
## Motes drift on their own clock, so a couple of stills a second apart
## show whether the scene is alive when nothing is being pressed.

var _field: Playfield
var _t: float = 0.0
var _next_shot: int = 0
var _next_step: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var root := Node2D.new()
	add_child(root)
	_field = Playfield.new()
	root.add_child(_field)
	# The harness drives the walker directly, so the field's own input
	# handling is switched off — otherwise the two fight each other and the
	# field wins, zeroing the steer every frame. This has to happen AFTER
	# the node is in the tree: Godot turns processing back on when a node
	# with _physics_process enters, so switching it off before is undone.
	_field.set_physics_process(false)
	_field.setup(load("res://assets/art/backgrounds/ui_town.webp"),
		CastArt.figure("arad"), VIEW)
	# A ledge to climb and a gap to fall into, so the harness exercises the
	# obstacle path and not only flat ground.
	_field.build_obstacles([
		{"kind": "ledge", "x": 0.34, "y": 0.74, "w": 0.12, "h": 0.02},
		{"kind": "gap", "x": 0.52, "y": 0.0, "w": 0.07, "h": 0.0},
	], VIEW)


func _physics_process(delta: float) -> void:
	_t += delta
	while _next_step < SCRIPT.size() and _t >= float(SCRIPT[_next_step][0]):
		var step: Array = SCRIPT[_next_step]
		_field.walker.input_x = float(step[1])
		_field.walker.jump_held = bool(step[2])
		if bool(step[2]):
			_field.walker.request_jump()
		_next_step += 1
	_field.figure.drive(_field.walker.velocity,
		_field.walker.is_on_floor(), delta)
	_field.catch_fall(VIEW)

	if _next_shot < SHOTS.size() and _t >= float(SHOTS[_next_shot]):
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "%s/%02d.png" % [OUT, _next_shot]
		img.save_png(path)
		print("SHOT %s  t=%.2f  vx=%.0f  vy=%.0f  floor=%s" % [
			path, _t, _field.walker.velocity.x, _field.walker.velocity.y,
			_field.walker.is_on_floor()])
		_next_shot += 1

	if _next_shot >= SHOTS.size():
		print("MOTION WRITTEN TO: %s" % ProjectSettings.globalize_path(OUT))
		get_tree().quit()

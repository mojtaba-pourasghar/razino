class_name SceneLife
extends Node2D
## What moves in a scene when the player is standing still.
##
## A scene that only animates in answer to the player still reads as a
## picture with a toy on it. What makes a place feel like a place is motion
## that has nothing to do with you: dust turning in the light, a lamp that
## is not quite steady, leaves coming down, someone crossing the far end of
## the street and never looking over.
##
## None of this needs new art. Motes and leaves are drawn, the flicker is a
## light level, and a passer-by is a cast figure at a distance, dimmed to
## the depth it is standing at. The parallax layers DO need art, and the
## class carries them so they work the day they arrive, with one layer —
## the painting that already exists — until then.

## How far each depth moves against the camera. 0 is pinned to the view,
## 1 moves with the world.
const DEPTH := {"far": 0.35, "mid": 1.0, "near": 1.45}

var motes: int = 26
var leaves: int = 0
var lamp_flicker: bool = false

var _layers: Dictionary = {}
var _motes: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []
var _lamps: Array[CanvasItem] = []
var _view: Vector2 = Vector2(1280, 720)
var _rng := RandomNumberGenerator.new()
var _t: float = 0.0


func _ready() -> void:
	_rng.seed = 20261029
	set_process(true)


## `paintings` maps a depth name to a texture. A scene with only one
## painting passes it as "mid" and still gets the moving parts.
func setup(paintings: Dictionary, view: Vector2, world_width: float) -> void:
	_view = view
	for depth: String in ["far", "mid", "near"]:
		var tex: Texture2D = paintings.get(depth)
		if tex == null:
			continue
		var layer := Parallax2D.new()
		layer.scroll_scale = Vector2(float(DEPTH[depth]), 1.0)
		layer.repeat_size = Vector2(world_width, 0.0)
		var art := Sprite2D.new()
		art.texture = tex
		art.centered = false
		if tex.get_height() > 0:
			var s := view.y / float(tex.get_height())
			art.scale = Vector2(s, s)
		layer.add_child(art)
		add_child(layer)
		_layers[depth] = layer

	for i in motes:
		_motes.append(_spawn_mote(world_width, true))
	for i in leaves:
		_leaves.append(_spawn_leaf(world_width, true))


func _spawn_mote(world: float, anywhere: bool) -> Dictionary:
	return {
		"p": Vector2(_rng.randf_range(0.0, world),
			_rng.randf_range(0.0, _view.y) if anywhere else _view.y + 10.0),
		"v": Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-26.0, -11.0)),
		"r": _rng.randf_range(1.2, 2.8),
		"a": _rng.randf_range(0.18, 0.5),
		"w": _rng.randf_range(0.6, 1.6),
	}


func _spawn_leaf(world: float, anywhere: bool) -> Dictionary:
	return {
		"p": Vector2(_rng.randf_range(0.0, world),
			_rng.randf_range(0.0, _view.y) if anywhere else -20.0),
		"v": Vector2(_rng.randf_range(-30.0, -8.0), _rng.randf_range(22.0, 48.0)),
		"r": _rng.randf_range(3.0, 6.0),
		"a": _rng.randf_range(0.35, 0.7),
		"w": _rng.randf_range(1.4, 3.0),
		"spin": _rng.randf_range(-3.0, 3.0),
	}


## A light that is not quite steady. Registered rather than found, because
## which parts of a painting are lamps is something only the scene knows.
func add_lamp(item: CanvasItem) -> void:
	_lamps.append(item)
	lamp_flicker = true


func _process(delta: float) -> void:
	_t += delta
	var world := _view.x * 3.0
	for m: Dictionary in _motes:
		var p: Vector2 = m["p"]
		var v: Vector2 = m["v"]
		# Drifting sideways as it rises, so it reads as air and not as rain
		# running backwards.
		p.x += (v.x + sin(_t * float(m["w"]) + p.y * 0.01) * 9.0) * delta
		p.y += v.y * delta
		if p.y < -12.0:
			var fresh := _spawn_mote(world, false)
			m["p"] = fresh["p"]
			m["v"] = fresh["v"]
		else:
			m["p"] = p
	for l: Dictionary in _leaves:
		var p: Vector2 = l["p"]
		var v: Vector2 = l["v"]
		p.x += (v.x + sin(_t * float(l["w"])) * 22.0) * delta
		p.y += v.y * delta
		if p.y > _view.y + 20.0:
			var fresh := _spawn_leaf(world, false)
			l["p"] = fresh["p"]
			l["v"] = fresh["v"]
		else:
			l["p"] = p
	if lamp_flicker:
		# Two waves that do not divide into each other, so the flicker never
		# settles into a rhythm the eye can predict.
		var f := 0.92 + 0.05 * sin(_t * 7.3) + 0.03 * sin(_t * 2.1)
		for item: CanvasItem in _lamps:
			if is_instance_valid(item):
				item.modulate = Color(f, f * 0.98, f * 0.9)
	queue_redraw()


func _draw() -> void:
	for m: Dictionary in _motes:
		draw_circle(m["p"], float(m["r"]),
			Color(1.0, 0.94, 0.78, float(m["a"])))
	for l: Dictionary in _leaves:
		var p: Vector2 = l["p"]
		var r: float = float(l["r"])
		draw_circle(p, r, Color(0.85, 0.55, 0.25, float(l["a"])))

class_name NearLayer
extends Node2D
## The dark things that pass in front of the character.
##
## This is the one layer that cannot be derived from the backdrop, and it
## is also the one that does not need to be painted: a near layer is almost
## always a silhouette. It is close enough to the camera to be out of
## focus and dark enough to be a shape, so what it needs is an outline and
## a colour, and both can be drawn.
##
## Drawn rather than painted also means it can be seeded per scene, so the
## branch over a schoolyard is not the same branch as the one over a
## library, without anyone drawing a second branch.
##
## It moves faster than the world, which is what sells the depth: at 1.45
## the eye reads it as being between itself and the scene, and the effect
## survives the character walking under it.

enum Kind { BRANCH, RAILING, GRASS, ARCH }

const SPEED := 1.45

var kind: Kind = Kind.BRANCH
var tint: Color = Color(0.03, 0.05, 0.10, 0.92)
var seed_value: int = 1

var _view: Vector2 = Vector2(1280, 720)
var _shapes: Array[PackedVector2Array] = []
var _rng := RandomNumberGenerator.new()


func build(which: Kind, view: Vector2, world_width: float, seed_: int) -> void:
	kind = which
	_view = view
	seed_value = seed_
	_rng.seed = seed_
	_shapes.clear()
	match kind:
		Kind.BRANCH:
			_branches(world_width)
		Kind.RAILING:
			_railing(world_width)
		Kind.GRASS:
			_grass(world_width)
		Kind.ARCH:
			_arch(world_width)
	queue_redraw()


## A bough entering from the top corner with leaves along it. Two or three
## of them across a scene, never evenly spaced: evenly spaced reads as
## wallpaper.
func _branches(world: float) -> void:
	var count := 2 + _rng.randi_range(0, 2)
	for i in count:
		var from := Vector2(_rng.randf_range(0.0, world), -40.0)
		var to := from + Vector2(_rng.randf_range(-320.0, 320.0),
			_rng.randf_range(140.0, 300.0))
		var thickness := _rng.randf_range(16.0, 30.0)
		_shapes.append(_limb(from, to, thickness))
		var leaves := 7 + _rng.randi_range(0, 7)
		for j in leaves:
			var t := float(j + 1) / float(leaves + 1)
			var at := from.lerp(to, t) + Vector2(
				_rng.randf_range(-54.0, 54.0), _rng.randf_range(-34.0, 46.0))
			_shapes.append(_leaf(at, _rng.randf_range(20.0, 40.0),
				_rng.randf_range(0.0, TAU)))


## Posts and a rail, as a balcony or a bridge edge crossing the view.
func _railing(world: float) -> void:
	var y := _view.y * _rng.randf_range(0.70, 0.84)
	var gap := _rng.randf_range(84.0, 128.0)
	var x := 0.0
	while x < world:
		_shapes.append(_bar(Vector2(x, y), Vector2(x, _view.y + 60.0), 14.0))
		x += gap
	_shapes.append(_bar(Vector2(0.0, y), Vector2(world, y), 18.0))
	_shapes.append(_bar(Vector2(0.0, y + 42.0), Vector2(world, y + 42.0), 11.0))


## Blades along the very bottom, so the character wades through the front
## of the frame rather than standing on a clean line.
func _grass(world: float) -> void:
	var x := 0.0
	while x < world:
		var h := _rng.randf_range(40.0, 110.0)
		var lean := _rng.randf_range(-26.0, 26.0)
		_shapes.append(_limb(Vector2(x, _view.y + 20.0),
			Vector2(x + lean, _view.y - h), _rng.randf_range(7.0, 14.0)))
		x += _rng.randf_range(16.0, 38.0)


## A pointed arch the player walks through, matching the frames the rest of
## the interface is built from.
func _arch(world: float) -> void:
	var at := _rng.randf_range(world * 0.3, world * 0.7)
	var w := _view.y * 0.52
	var h := _view.y * 0.92
	var outer := PackedVector2Array()
	for side in [-1.0, 1.0]:
		for i in 18:
			var t := float(i) / 17.0
			var u := 1.0 - t
			var a := Vector2(at + side * w * 0.5, _view.y + 40.0)
			var c := Vector2(at + side * w * 0.5, _view.y - h * 0.78)
			var b := Vector2(at, _view.y - h)
			outer.append(a * (u * u) + c * (2.0 * u * t) + b * (t * t))
	# Two uprights and the head between them, as one piece.
	_shapes.append(_bar(Vector2(at - w * 0.5 - 26.0, _view.y + 40.0),
		Vector2(at - w * 0.5 - 26.0, _view.y - h * 0.5), 52.0))
	_shapes.append(_bar(Vector2(at + w * 0.5 + 26.0, _view.y + 40.0),
		Vector2(at + w * 0.5 + 26.0, _view.y - h * 0.5), 52.0))
	_shapes.append(outer)


func _limb(from: Vector2, to: Vector2, thickness: float) -> PackedVector2Array:
	# Tapered, because a branch of even width is a pipe.
	var along := (to - from).normalized()
	var across := Vector2(-along.y, along.x)
	var out := PackedVector2Array()
	out.append(from + across * thickness * 0.5)
	out.append(to + across * thickness * 0.16)
	out.append(to - across * thickness * 0.16)
	out.append(from - across * thickness * 0.5)
	return out


func _bar(from: Vector2, to: Vector2, thickness: float) -> PackedVector2Array:
	var along := (to - from).normalized()
	var across := Vector2(-along.y, along.x) * thickness * 0.5
	var out := PackedVector2Array()
	out.append(from + across)
	out.append(to + across)
	out.append(to - across)
	out.append(from - across)
	return out


func _leaf(at: Vector2, size: float, angle: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0 * TAU
		# A leaf is longer than it is wide and comes to a point at one end.
		var r := size * (0.42 + 0.58 * absf(cos(t * 0.5)))
		out.append(at + Vector2(cos(t) * r, sin(t) * r * 0.52).rotated(angle))
	return out


func _draw() -> void:
	for shape: PackedVector2Array in _shapes:
		if shape.size() >= 3:
			draw_colored_polygon(shape, tint)

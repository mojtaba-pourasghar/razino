class_name Playfield
extends Node2D
## A scene the player walks around in, instead of taps at.
##
## The explore screens were a painting with invisible buttons on it: nothing
## moved, and the only verb was "touch that". This is the same painting with
## ground under it and a character the player drives — run, jump, and reach
## a thing by going to it rather than by pointing at it.
##
## Touch control is a thumb zone, not a drawn pad: the left half of the
## screen steers and the right half jumps. A pad drawn on top of the art
## covers the part of the picture a child is trying to look at, and on a
## phone the thumb never finds it anyway.

## Where the floor sits, as a fraction of the view's height. It is a
## parameter and not a constant because every painted backdrop puts its own
## horizon somewhere different, and a single number guessed for one of them
## leaves the character hovering above the ground in all the others.
var ground_y: float = 0.92
## Character height, as a fraction of the view's height.
var figure_height: float = 0.26

var walker: Walker
var figure: RiggedFigure

var _backdrop: Sprite2D
var _camera: Camera2D
var _world_width: float = 2400.0
var _touch_steer: int = 0
## Emitted as the player walks into and out of reach of something.
signal marker_reached(marker_id: String)
signal marker_left(marker_id: String)

var life: SceneLife
var near: Parallax2D
## Which silhouette passes in front, and the seed that shapes it. A scene
## sets both, so the branch over a schoolyard is not the branch over a
## library even though neither was drawn by hand.
var near_kind: NearLayer.Kind = NearLayer.Kind.BRANCH
var near_seed: int = 1
var _markers: Dictionary = {}
var _near: String = ""
var _gaps: Array[Vector2] = []
var _ground: Node2D = null
var _view: Vector2 = Vector2(1280, 720)


func _ready() -> void:
	_build()
	set_process_unhandled_input(true)


func _build() -> void:
	_backdrop = Sprite2D.new()
	_backdrop.centered = false
	# Nothing in this game is a still picture. The backdrop keeps its paint
	# and gains motion in the parts that would move: water, lamps, lit glass.
	var lit := ShaderMaterial.new()
	lit.shader = load("res://assets/shaders/living_backdrop.gdshader")
	_backdrop.material = lit
	add_child(_backdrop)

	# Everything in the scene that moves without being asked to. It goes in
	# before the walker so the motes sit behind the character, not over the
	# face of whoever the player is looking at.
	life = SceneLife.new()
	add_child(life)

	walker = Walker.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(44, 96)
	shape.shape = box
	shape.position = Vector2(0, -48)
	walker.add_child(shape)
	add_child(walker)

	# The rigged figure where one has been cut, so the legs actually swing.
	figure = RiggedFigure.new("hero")
	walker.add_child(figure)
	walker.landed.connect(figure.land)
	walker.jumped.connect(figure.leap)
	walker.landed.connect(func(_f: float) -> void:
		AudioManager.play_sfx("SFX_UI_TAP"))

	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	walker.add_child(_camera)


## Lays the field out for a scene: the painting, the floor under it, and
## where the character starts.
func setup(backdrop: Texture2D, _character: Texture2D, view: Vector2,
		ground: float = -1.0, near_art: String = "", seed_: int = 1) -> void:
	near_seed = seed_
	match near_art:
		"railing": near_kind = NearLayer.Kind.RAILING
		"grass": near_kind = NearLayer.Kind.GRASS
		"arch": near_kind = NearLayer.Kind.ARCH
		_: near_kind = NearLayer.Kind.BRANCH
	if ground > 0.0:
		ground_y = ground
	_backdrop.texture = backdrop
	if backdrop != null and backdrop.get_height() > 0:
		var scale := view.y / float(backdrop.get_height())
		_backdrop.scale = Vector2(scale, scale)
		_world_width = backdrop.get_width() * scale
	figure.height = view.y * figure_height
	life.setup({}, view, _world_width)
	life.derive_far_layer(backdrop, view, _world_width, self)

	# In front of everything, including the player: the near layer is what
	# the character walks BEHIND, and a branch the character passes over
	# instead of under is not a near layer at all.
	near = Parallax2D.new()
	near.scroll_scale = Vector2(NearLayer.SPEED, 1.0)
	near.repeat_size = Vector2(_world_width, 0.0)
	var silhouette := NearLayer.new()
	silhouette.build(near_kind, view, _world_width, near_seed)
	near.add_child(silhouette)
	add_child(near)

	_view = view
	var floor_y := view.y * ground_y
	_rebuild_ground(view, floor_y)
	# Walls, so the character cannot walk out of the painting.
	_add_floor(Vector2(-24.0, floor_y * 0.5), Vector2(48.0, view.y * 2.0))
	_add_floor(Vector2(_world_width + 24.0, floor_y * 0.5), Vector2(48.0, view.y * 2.0))

	walker.position = Vector2(_world_width * 0.25, floor_y - 10.0)
	_camera.limit_left = 0
	_camera.limit_right = int(_world_width)
	_camera.limit_top = 0
	_camera.limit_bottom = int(view.y)


## Builds the obstacles a scene names: the things between the player and
## what they came for.
##
## Each one is a rectangle in fractions of the view, so a scene's layout
## survives every screen shape. Three kinds, and the game needs no more:
##
##  · LEDGE  something to stand on and climb.
##  · WALL   something that stops you until you find the way over it.
##  · GAP    a hole in the floor. It is cut OUT of the ground rather than
##    placed on it, so falling through is simply the floor not being there.
##
## A gap does not kill. This is a game for eight-year-olds and the rule in
## docs/GAMEPLAY.md is that no obstacle takes progress away: the player is
## set back on the near side of the gap and may try again at once.
func build_obstacles(list: Array, view: Vector2) -> void:
	var floor_y := view.y * ground_y
	for entry: Variant in list:
		if not entry is Dictionary:
			continue
		var it := entry as Dictionary
		var kind := String(it.get("kind", "ledge"))
		var r := Rect2(
			float(it.get("x", 0.0)) * _world_width,
			float(it.get("y", 0.0)) * view.y,
			float(it.get("w", 0.1)) * _world_width,
			float(it.get("h", 0.05)) * view.y)
		match kind:
			"gap":
				_gaps.append(Vector2(r.position.x, r.end.x))
			"wall":
				_add_floor(r.position + r.size * 0.5, r.size)
			_:
				_add_floor(Vector2(r.position.x + r.size.x * 0.5, r.position.y),
					Vector2(r.size.x, 24.0))
	_rebuild_ground(view, floor_y)


## The ground, minus whatever the gaps take out of it.
func _rebuild_ground(view: Vector2, floor_y: float) -> void:
	if _ground != null:
		_ground.queue_free()
	_ground = Node2D.new()
	add_child(_ground)
	var edges: Array[float] = [0.0]
	for g: Vector2 in _gaps:
		edges.append(g.x)
		edges.append(g.y)
	edges.append(_world_width)
	var i := 0
	while i + 1 < edges.size():
		var from := edges[i]
		var to := edges[i + 1]
		if to - from > 1.0:
			var body := StaticBody2D.new()
			body.position = Vector2((from + to) * 0.5, floor_y + 24.0)
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(to - from, 48.0)
			shape.shape = box
			body.add_child(shape)
			_ground.add_child(body)
		i += 2


## Puts the player back on the near side of a gap they fell into.
##
## Public, because whatever drives the field has to be able to call it. The
## harness in tools/ drives the walker itself and switches the field's own
## physics off, and with this private the character simply fell for ever.
func catch_fall(view: Vector2 = Vector2.ZERO) -> void:
	if view == Vector2.ZERO:
		view = _view
	if walker.position.y < view.y * 1.3:
		return
	var back := walker.position.x
	for g: Vector2 in _gaps:
		if back >= g.x - 60.0 and back <= g.y + 60.0:
			back = g.x - 70.0
			break
	walker.position = Vector2(maxf(40.0, back), view.y * ground_y - 40.0)
	walker.velocity = Vector2.ZERO
	AudioManager.play_sfx("SFX_UI_SOFT_NO")


## Something in the world worth walking to.
##
## This is what replaces a hotspot drawn over a painting. A hotspot is
## reached by pointing at it, which costs the player nothing and so means
## nothing; a marker has to be arrived at, and whatever is between the
## player and it — a ledge, a gap, a wall — is the game.
##
## `x` and `y` are fractions of the world and the view, matching the rects
## the content already uses for its interactions, so a scene's existing
## data places these without being rewritten.
func add_marker(marker_id: String, x: float, y: float) -> void:
	var area := Area2D.new()
	area.position = Vector2(x * _world_width, y * _view.y)
	area.monitoring = false       # the walker moves, not this
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	# Generous: a child aiming a thumb at a moving character should not
	# have to stop on an exact pixel to be allowed to look at something.
	circle.radius = 96.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	_markers[marker_id] = area


## The marker the player is standing closest to, within reach, or "".
func near_marker() -> String:
	return _near


func _update_markers() -> void:
	var best := ""
	var best_distance := 1.0e20
	for marker_id: String in _markers:
		var area: Area2D = _markers[marker_id]
		if not is_instance_valid(area):
			continue
		var d := area.position.distance_to(walker.position)
		if d < 110.0 and d < best_distance:
			best = marker_id
			best_distance = d
	if best == _near:
		return
	if not _near.is_empty():
		marker_left.emit(_near)
	_near = best
	if not _near.is_empty():
		marker_reached.emit(_near)


func clear_markers() -> void:
	for marker_id: String in _markers:
		var area: Area2D = _markers[marker_id]
		if is_instance_valid(area):
			area.queue_free()
	_markers.clear()
	_near = ""


func _add_floor(at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _physics_process(delta: float) -> void:
	var steer := Input.get_axis("ui_left", "ui_right")
	if steer == 0.0:
		steer = float(_touch_steer)
	walker.input_x = steer
	walker.jump_held = Input.is_action_pressed("ui_accept") \
		or Input.is_action_pressed("ui_up")
	if Input.is_action_just_pressed("ui_accept") \
			or Input.is_action_just_pressed("ui_up"):
		walker.request_jump()
	figure.drive(walker.velocity, walker.is_on_floor(), delta)
	catch_fall(_view)
	_update_markers()


func _unhandled_input(event: InputEvent) -> void:
	# Left half steers towards where the thumb is, right half jumps.
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var at: Vector2 = event.position
		var half := get_viewport().get_visible_rect().size.x * 0.5
		if at.x > half:
			if pressed:
				walker.request_jump()
			walker.jump_held = pressed
		else:
			_touch_steer = 0 if not pressed else (1 if at.x > half * 0.5 else -1)

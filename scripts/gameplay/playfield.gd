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
var figure: FigureSprite

var _backdrop: Sprite2D
var _camera: Camera2D
var _world_width: float = 2400.0
var _touch_steer: int = 0


func _ready() -> void:
	_build()
	set_process_unhandled_input(true)


func _build() -> void:
	_backdrop = Sprite2D.new()
	_backdrop.centered = false
	add_child(_backdrop)

	walker = Walker.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(44, 96)
	shape.shape = box
	shape.position = Vector2(0, -48)
	walker.add_child(shape)
	add_child(walker)

	figure = FigureSprite.new()
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
func setup(backdrop: Texture2D, character: Texture2D, view: Vector2,
		ground: float = -1.0) -> void:
	if ground > 0.0:
		ground_y = ground
	_backdrop.texture = backdrop
	if backdrop != null and backdrop.get_height() > 0:
		var scale := view.y / float(backdrop.get_height())
		_backdrop.scale = Vector2(scale, scale)
		_world_width = backdrop.get_width() * scale
	figure.figure = character
	figure.height = view.y * figure_height

	var floor_y := view.y * ground_y
	_add_floor(Vector2(_world_width * 0.5, floor_y + 24.0),
		Vector2(_world_width, 48.0))
	# Walls, so the character cannot walk out of the painting.
	_add_floor(Vector2(-24.0, floor_y * 0.5), Vector2(48.0, view.y * 2.0))
	_add_floor(Vector2(_world_width + 24.0, floor_y * 0.5), Vector2(48.0, view.y * 2.0))

	walker.position = Vector2(_world_width * 0.25, floor_y - 10.0)
	_camera.limit_left = 0
	_camera.limit_right = int(_world_width)
	_camera.limit_top = 0
	_camera.limit_bottom = int(view.y)


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

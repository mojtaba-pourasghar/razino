class_name RiggedFigure
extends Node2D
## A character cut into parts and walked by turning them at the joints.
##
## This is what FigureSprite could not do. Squash and stretch alone reads as
## sliding for a character with visible legs, and the first painted cast
## could not be cut because its arms were tucked against its body and there
## was no gap in the silhouette to cut along. This figure has one, so the
## legs come off cleanly and actually swing.
##
## The cycle is deliberately small: two legs and a little counter-swing in
## the body. A chibi character's arms barely move when it walks, and forcing
## them to reads as a march.
##
## Phase advances with distance travelled, never with time, so the stride
## matches the ground. A cycle on a timer slides whenever the character
## speeds up or slows down, which is the thing the eye catches first.

const DIR := "res://assets/art/cast_rigged/"

const SWING := 26.0          ## degrees a leg swings either way at full speed
const BODY_COUNTER := 3.0    ## degrees the body turns against the legs
const BOB := 0.020           ## of figure height, twice a stride
const STRIDE_PER_PIXEL := 0.018
const AIR_SPLIT := 14.0      ## legs part this much in the air
const LAND_SQUASH := 0.26
const SPRING := 17.0
const DAMP := 0.76

var height: float = 220.0:
	set(value):
		height = value
		_fit()

var facing: int = 1

var _parts: Dictionary = {}      ## name -> Sprite2D
var _meta: Dictionary = {}
var _root: Node2D
var _scale: float = 1.0
var _stride: float = 0.0
var _squash: float = 0.0
var _squash_vel: float = 0.0


func _init(name: String = "hero") -> void:
	_root = Node2D.new()
	add_child(_root)
	_load(name)


func _load(name: String) -> void:
	var f := FileAccess.open("%s%s.json" % [DIR, name], FileAccess.READ)
	if f == null:
		push_warning("no rig for %s" % name)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	_meta = parsed
	var figure: Array = _meta.get("figure", [0, 0, 1, 1])
	var fw := float(figure[2]) - float(figure[0])
	var fh := float(figure[3]) - float(figure[1])
	_meta["w"] = fw
	_meta["h"] = fh
	for part: String in _meta.get("order", []):
		var info: Dictionary = (_meta["parts"] as Dictionary).get(part, {})
		var path := "%s%s_%s.png" % [DIR, name, part]
		if not ResourceLoader.exists(path):
			continue
		var s := Sprite2D.new()
		s.texture = load(path)
		s.centered = false
		var joint: Array = info.get("joint", [0, 0])
		var at: Array = info.get("offset", [0, 0])
		# The sprite is offset so its JOINT sits on its own origin; the node
		# is then placed where that joint belongs on the figure. Rotating
		# the node now turns the part about the joint, with no arithmetic
		# anywhere else.
		s.offset = Vector2(-float(joint[0]), -float(joint[1]))
		s.position = Vector2(float(at[0]) + float(joint[0]),
			float(at[1]) + float(joint[1]) - fh)
		_root.add_child(s)
		_parts[part] = s
	_fit()


func _fit() -> void:
	var fh: float = float(_meta.get("h", 0.0))
	if fh <= 0.0:
		return
	_scale = height / fh
	_root.scale = Vector2(_scale * float(facing), _scale)


func _turn(part: String, degrees: float) -> void:
	var s: Sprite2D = _parts.get(part)
	if s != null:
		s.rotation_degrees = degrees


## Called every frame with the character's own velocity.
func drive(velocity: Vector2, on_floor: bool, delta: float) -> void:
	var speed := absf(velocity.x)
	if speed > 4.0:
		facing = 1 if velocity.x > 0.0 else -1
		_stride += speed * delta * STRIDE_PER_PIXEL
	else:
		# Walk the phase back to standing instead of freezing mid-step.
		_stride = move_toward(_stride, roundf(_stride / PI) * PI, delta * 7.0)

	_squash_vel += -_squash * SPRING
	_squash_vel *= DAMP
	_squash += _squash_vel * delta

	var bob := 0.0
	if on_floor:
		var run := clampf(speed / Walker.RUN_SPEED, 0.0, 1.0)
		var swing := sin(_stride) * SWING * run
		_turn("leg_front", swing)
		_turn("leg_back", -swing)
		_turn("body", -swing * BODY_COUNTER / SWING)
		_turn("head", swing * 0.08)
		bob = -absf(sin(_stride)) * BOB * height * run
	else:
		# In the air the legs hold a split rather than keep walking: a
		# character pedalling through a jump looks weightless.
		var rise := clampf(-velocity.y / 700.0, -1.0, 1.0)
		_turn("leg_front", AIR_SPLIT * rise)
		_turn("leg_back", -AIR_SPLIT * rise * 0.6)
		_turn("body", 0.0)
		_turn("head", 0.0)

	_root.scale = Vector2(
		_scale * (1.0 + _squash * 0.5) * float(facing),
		_scale * (1.0 - _squash))
	_root.position = Vector2(0.0, bob)


func land(fall_speed: float) -> void:
	_squash = LAND_SQUASH * clampf(fall_speed / Walker.MAX_FALL, 0.0, 1.0)
	_squash_vel = 0.0


func leap() -> void:
	_squash = -0.12
	_squash_vel = 0.0

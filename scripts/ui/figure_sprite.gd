class_name FigureSprite
extends Node2D
## A painted character, animated without a single extra frame of art.
##
## Super Meat Boy has no skeleton and almost no frames: the whole body
## squashes, stretches and leans, and that reads as weight. The same applies
## here, and for this cast it is not a compromise but the only honest
## technique — the figures are chibi with their arms tucked against the
## body, so there is no hip or shoulder in the silhouette to cut a limb at.
## A cut was tried and came out as rectangles sliced through the chest.
##
## Everything below is driven by velocity, so the character answers the
## player rather than playing a clip:
##
##  · RUNNING  leans into the direction of travel and bobs twice a stride,
##    with the bob falling to nothing as it slows, so a walk is not a jog.
##  · LEAVING THE GROUND  stretches tall and thin.
##  · FALLING  stretches further, the faster the thinner.
##  · LANDING  squashes hard and springs back, in proportion to the drop.
##
## The sprite's own pivot is at its feet, so squash settles the character
## onto the ground instead of sinking it through.

const LEAN_MAX := 0.16          ## radians at full speed
const BOB_HEIGHT := 0.045       ## of the figure's height, per step
const STRIDE_PER_PIXEL := 0.021 ## stride phase advanced per pixel travelled
const AIR_STRETCH := 0.16
const LAND_SQUASH := 0.34
const SPRING := 16.0            ## how fast a squash recovers
const DAMP := 0.78

var figure: Texture2D = null:
	set(value):
		figure = value
		_sprite.texture = value
		_fit()

## The height the character is drawn at, in pixels.
var height: float = 180.0:
	set(value):
		height = value
		_fit()

var facing: int = 1

var _sprite: Sprite2D
var _stride: float = 0.0
var _squash: float = 0.0        ## positive squashes, negative stretches
var _squash_vel: float = 0.0
var _base_scale: float = 1.0


func _init() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)


func _fit() -> void:
	if figure == null or figure.get_height() == 0:
		return
	_base_scale = height / float(figure.get_height())
	# Drawn from its feet: the origin of this node is where the character
	# stands, so squashing shortens it onto the ground rather than through it.
	_sprite.offset = Vector2(-figure.get_width() * 0.5, -figure.get_height())


## Called every frame with the character's own velocity and whether it is
## standing on something.
func drive(velocity: Vector2, on_floor: bool, delta: float) -> void:
	var speed := absf(velocity.x)
	if speed > 4.0:
		facing = 1 if velocity.x > 0.0 else -1
		_stride += speed * delta * STRIDE_PER_PIXEL
	else:
		# Settle to a standing pose rather than freezing mid-step.
		_stride = move_toward(_stride, roundf(_stride / PI) * PI, delta * 6.0)

	_squash_vel += -_squash * SPRING
	_squash_vel *= DAMP
	_squash += _squash_vel * delta

	var squash := _squash
	var lean := 0.0
	var bob := 0.0
	if on_floor:
		var run := clampf(speed / Walker.RUN_SPEED, 0.0, 1.0)
		lean = LEAN_MAX * run * float(facing)
		# Two bobs a stride, and none at all when standing still.
		bob = -absf(sin(_stride)) * BOB_HEIGHT * height * run
	else:
		# Thin and tall in the air, more so the faster it falls.
		squash -= AIR_STRETCH * clampf(absf(velocity.y) / 900.0, 0.2, 1.0)

	var sx := _base_scale * (1.0 + squash * 0.55) * float(facing)
	var sy := _base_scale * (1.0 - squash)
	_sprite.scale = Vector2(sx, sy)
	_sprite.rotation = lean
	_sprite.position = Vector2(0.0, bob)


## A landing, with the drop that caused it. A short fall barely registers;
## a long one folds the character almost in half.
func land(fall_speed: float) -> void:
	var force := clampf(fall_speed / Walker.MAX_FALL, 0.0, 1.0)
	_squash = LAND_SQUASH * force
	_squash_vel = 0.0


## A jump: the opposite, and smaller, because the stretch reads mostly from
## the rise itself.
func leap() -> void:
	_squash = -AIR_STRETCH * 0.8
	_squash_vel = 0.0
